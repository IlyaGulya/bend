import {spawn, spawnSync} from 'node:child_process';
import {closeSync, existsSync, mkdirSync, openSync, readFileSync, readdirSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
const [configuration, report] = process.argv.slice(2);
const config = JSON.parse(readFileSync(configuration, 'utf8'));
if (existsSync(report) || existsSync(config.out)) throw Error('cancellation smoke requires fresh outputs');
mkdirSync(dirname(report), {recursive: true});
const log = openSync(report + '.stdout', 'wx'), err = openSync(report + '.stderr', 'wx');
const state = {schemaVersion: 1, status: 'FAIL', diagnosticOnly: true,
  qualificationAccepted: false, command: config.command, cwd: config.cwd,
  originalGuardianUnchanged: true, started: Date.now(), observedNative: null};
let child, timer, cancelledAt, detectedAt, problem;
function processes() {
  const r = spawnSync('/usr/bin/ssh', ['-o', 'BatchMode=yes', '-o', 'ConnectTimeout=8', config.remoteTarget, '/bin/ps -axo pid=,ppid=,lstart=,comm='], {encoding: 'utf8', timeout: 5000});
  if (r.status !== 0) throw Error('process observation failed: ' + r.stderr);
  return r.stdout.split('\n').map(line => {
    const m = line.trim().match(/^(\d+)\s+(\d+)\s+(\S+\s+\S+\s+\d+\s+\S+\s+\d+)\s+(.+)$/);
    return m && {pid: +m[1], ppid: +m[2], identity: m[3] + ' ' + m[4], name: m[4]};
  }).filter(Boolean);
}
function cancel(reason) {
  if (cancelledAt) return;
  cancelledAt = Date.now(); state.cancelReason = reason;
  child.kill('SIGTERM');
}
try {
  child = spawn(config.command[0], config.command.slice(1), {cwd: config.cwd, stdio: ['ignore', log, err]});
  closeSync(log); closeSync(err);
  timer = setInterval(() => {
    try {
      if (!existsSync(config.out)) return;
      const envelopes = readdirSync(config.out).filter(name => /^dispatch-[a-f0-9]+\.json$/.test(name));
      if (!envelopes.length) return;
      if (envelopes.length !== 1) throw Error('one actual native job is required');
      const envelope = JSON.parse(readFileSync(resolve(config.out, envelopes[0]), 'utf8'));
      state.observedNonce = envelope.nonce;
      const rows = processes();
      const suffix = '/bend-g24-' + envelope.nonce + '/snapshot/artifacts/binary';
      const active = rows.find(p => p.name.endsWith(suffix));
      if (active && !detectedAt) { detectedAt = Date.now(); state.observedNative = active; }
      if (active && detectedAt && Date.now() - detectedAt >= 300) cancel('actual owned full-root native sample observed running');
      if (Date.now() - state.started > 180000 && !cancelledAt) { problem = 'native sample was not observed'; cancel(problem); }
      if (cancelledAt && Date.now() - cancelledAt > 120000) { problem = 'coordinator did not finish cancellation'; child.kill('SIGKILL'); }
    } catch (e) { problem = String(e); cancel(problem); }
  }, 150);
  state.exit = await new Promise((done, reject) => { child.once('error', reject); child.once('close', (code, signal) => done({code, signal})); });
  clearInterval(timer);
  state.cancelledAt = cancelledAt;
  state.results = readdirSync(config.out).filter(name => /^result-[a-f0-9]+\.json$/.test(name))
    .map(name => ({path: resolve(config.out, name), value: JSON.parse(readFileSync(resolve(config.out, name), 'utf8'))}));
  const rows = processes();
  state.nativeStillPresent = !!state.observedNative && rows.some(p => p.pid === state.observedNative.pid && p.identity === state.observedNative.identity);
  if (problem) throw Error(problem);
  if (!state.observedNative || !cancelledAt || state.exit.code === 0) throw Error('actual running native interruption was not exercised');
  if (state.results.length !== 1 || state.results[0].value.status !== 'FAIL'
    || state.results[0].value.reaped !== true || state.results[0].value.nonce !== state.observedNonce || state.nativeStillPresent) throw Error('owned-tree cancellation/reaping was not confirmed');
  if (!/cancel|interrupt/i.test(state.results[0].value.error ?? '')) throw Error('failure was not an authenticated cancellation result');
  state.status = 'PASS';
} catch (e) { state.error = String(e?.stack ?? e); process.exitCode = 1; }
finally { clearInterval(timer); state.finished = Date.now(); writeFileSync(report, JSON.stringify(state, null, 2) + '\n', {flag: 'wx'}); }
console.log(JSON.stringify({status: state.status, observedNative: state.observedNative?.pid, results: state.results?.length, report}));
