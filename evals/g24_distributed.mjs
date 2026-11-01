#!/usr/bin/env bun
/** Explicit G24 snapshot/SSH protocol (not a replacement for any gate).
 *
 * CLI:
 *   bun evals/g24_distributed.mjs probe TOOLS.json > host-pin.json
 *   bun evals/g24_distributed.mjs consumers PLAN.json RECEIPT.json FRESH_OUT
 *   bun evals/g24_distributed.mjs verify SNAPSHOT MANIFEST_SHA256
 * Full runner: add --distributed-plan=PLAN.json to g24_qualification.mjs.
 * TOOLS.json: {"bun":"/absolute/bun","node":"/absolute/node",
 *   "clang":"/usr/bin/clang","llvmBin":"/absolute/llvm/bin"}.
 * PLAN.json: {"schemaVersion":1,"mode":"local-single-host"|"ssh",
 *   "hosts":[{"id":"mini2","node":2,"pin":<probe JSON>}],
 *   "placement":{"matrix-c":"mini2","matrix-js":"mini2","native":"mini2",
 *     "admission":"mini2","host":"mini2","performance-native":"mini2",
 *     "performance-js":"mini2"}}.
 * Local mode has exactly ONE host, with neither node nor ssh; never parallel machines.
 * SSH hosts select exactly one of node (integer 0..255) or ssh, for example
 * {"id":"remote","ssh":"misakaindrive","pin":<probe JSON>}.
 * The ssh selector is an SSH config alias/hostname: ASCII alphanumeric first,
 * then ASCII alphanumeric, dot, underscore or hyphen; no user/port/option syntax.
 * Numeric nodes retain gates/_lib.ts ssh (cluster-NN or BEND_HOC / sudo hoc-ssh)
 * and its existing host-key policy. Direct selectors use /usr/bin/ssh argv with
 * BatchMode=yes, ConnectTimeout=8, normal host-key policy and no added retries.
 * Both selectors share streaming input/capture/deadlines and the worker protocol;
 * distinct aliases for the same pinned physical host are rejected.
 * Obtain pins over an independently trusted SSH session; an unreviewed
 * first-contact pin is not host authentication.
 *
 * Snapshot uses g24_snapshot.mjs's explicit closed inventory, never a repository,
 * output, checkpoint or frozen-tree walk: operational module imports; complete
 * actual consumer/matrix Bend+foreign closures; selected producer source pins,
 * original bounded evidence documents; selected stage/native artifacts; exact
 * authenticated frozen inputs. Ambient secrets/caches/logs/history are excluded.
 * Producer-only opaque inputs remain coordinator-verified digest commitments,
 * not claims of transported files or remote producer reauthentication.
 * No provenance JSON is rewritten. Unknown literal imports/includes, unsupported
 * matrix inventory syntax and relocation-unsafe absolute Bend imports fail closed.
 * Streaming descriptor hashing/copying pins file and ancestor identities.
 * Sources remain read-only in the immutable snapshot; a separate declared-input
 * execution tree puts generated admission/host sources beneath its private
 * checkpoint namespace. Source bytes are checked again after execution.
 * Extra/missing snapshot files, source symlinks and drift fail closed.
 * Consumers CLI reauthenticates the original prior correctness receipt first;
 * it does not manufacture a new complete qualification or skip emitted suites.
 *
 * Each host owns one scheduler lease plus the unchanged per-step heavy guardian.
 * Existing processes are not classified by executable name. Host leases serialize
 * our jobs; the guardian bounds each step. No HEAVY_GATE overrides are allowed.
 * Six rows of a lane stay in one worker/host lease. Native completes/authenticates
 * before JS is dispatched. Correctness jobs serialize on a shared physical host.
 * SSH workers have a 45s renewable lease; lost control cancels, reaps descendants,
 * retains failure evidence and poisons the host lock if reaping is uncertain.
 * No retries of a completed job and no imported receipts. Results are bound to
 * a random job nonce, snapshot/plan digest, physical host and exact tool pins.
 * Host/operator trust remains required: this is SSH authentication, not hardware
 * remote attestation. Remote execution requires configured reachable hosts,
 * accepted runtimes/LLVM and sufficient disk. Operators must avoid competing
 * heavy workloads during measurements; process names do not prove CPU activity
 * or host idleness. The protocol does not claim to detect arbitrary external work.
 * Transfer uses bounded 4MiB positional chunks through the selected SSH transport.
 * Keep /tmp/bend-g24-<nonce> evidence until the parent archives it; a poisoned
 * /tmp/bend-g24-dedicated-host.lock requires operator investigation, never unlink
 * it to bypass an unconfirmed tree stop.
 */
import {createHash, randomBytes} from 'node:crypto';
import {chmodSync, closeSync, existsSync, lstatSync, mkdirSync, openSync, readFileSync, readSync,
  readdirSync, realpathSync, rmSync, statSync, writeFileSync} from 'node:fs';
import {dirname, isAbsolute, relative, resolve} from 'node:path';
import {spawn, spawnSync} from 'node:child_process';
import os from 'node:os';
import {fileURLToPath} from 'node:url';
import {exec, ssh} from '../gates/_lib.ts';
import {copyPinnedInput, hashFile, pinFile, snapshotInventory} from './g24_snapshot.mjs';

const SCRIPT = fileURLToPath(import.meta.url);
const JOBS = ['matrix-c', 'matrix-js', 'native', 'admission', 'host'];
const ORDER = [['control', 1], ['candidate', 1], ['candidate', 2], ['control', 2], ['control', 3], ['candidate', 3]];
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const sha = hashFile;
const json = path => JSON.parse(readFileSync(path, 'utf8'));
const quote = text => "'" + String(text).replaceAll("'", "'\\''") + "'";
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function need(ok, message) { if (!ok) throw Error(message); }
function fresh(path, value) { writeFileSync(path, JSON.stringify(value, null, 2) + '\n', {flag: 'wx', mode: 0o600}); }
function command(bin, args) {
  const r = spawnSync(bin, args, {encoding: 'utf8', timeout: 10000});
  need(r.status === 0, bin + ' failed: ' + r.stderr);
  return r.stdout.trim();
}
export function hostPin(tools) {
  let machine;
  if (os.platform() === 'darwin') {
    machine = command('/usr/sbin/ioreg', ['-rd1', '-c', 'IOPlatformExpertDevice']).match(/"IOPlatformUUID"\s*=\s*"([^"]+)"/)?.[1];
  } else if (os.platform() === 'linux') machine = readFileSync('/etc/machine-id', 'utf8').trim();
  need(machine, 'physical machine identity unavailable');
  const pins = {};
  for (const [name, path] of Object.entries({bun: tools.bun, node: tools.node, clang: tools.clang,
    opt: resolve(tools.llvmBin, 'opt'), split: resolve(tools.llvmBin, 'llvm-split')})) {
    need(isAbsolute(path), 'tool path must be absolute: ' + name);
    const real = realpathSync(path);
    pins[name] = {path: real, sha256: sha(real)};
  }
  const environment = Object.fromEntries(Object.entries(process.env).filter(([key]) =>
    /^BUN_JSC_/.test(key) || ['NODE_OPTIONS', 'NODE_PATH', 'NODE_V8_COVERAGE', 'BUN_OPTIONS',
      'DYLD_LIBRARY_PATH', 'DYLD_INSERT_LIBRARIES', 'LD_LIBRARY_PATH', 'LD_PRELOAD',
      'CC', 'CFLAGS', 'CPPFLAGS', 'SDKROOT', 'MACOSX_DEPLOYMENT_TARGET'].includes(key)).sort());
  return {physical: digest(machine), platform: os.platform(), arch: os.arch(), release: os.release(),
    cpu: os.cpus()[0]?.model, memoryBytes: os.totalmem(),
    tools: {...Object.fromEntries(['bun', 'node', 'clang'].map(name => [name, pins[name].path])),
      llvmBin: realpathSync(tools.llvmBin)}, pins, environment};
}
function cleanEnvironment() {
  for (const key of Object.keys(process.env))
    if (/^HEAVY_GATE_(?:LOCK_PATH|LEASE_)/.test(key)) throw Error('distributed mode forbids guardian override: ' + key);
}
export function loadPlan(path) {
  cleanEnvironment();
  const plan = json(path);
  need(plan.schemaVersion === 1 && ['local-single-host', 'ssh'].includes(plan.mode), 'invalid distributed plan');
  need(Array.isArray(plan.hosts) && plan.hosts.length > 0, 'no hosts');
  const ids = new Set(), machines = new Set();
  for (const host of plan.hosts) {
    need(/^[A-Za-z0-9_-]+$/.test(host.id) && !ids.has(host.id), 'duplicate/invalid host id');
    need(/^[a-f0-9]{64}$/.test(host.pin?.physical) && !machines.has(host.pin.physical), 'duplicate physical host or missing pin');
    const hasNode = Object.hasOwn(host, 'node'), hasSsh = Object.hasOwn(host, 'ssh');
    if (plan.mode === 'ssh') {
      need(hasNode !== hasSsh, 'SSH host requires exactly one of node or ssh');
      if (hasNode) need(Number.isInteger(host.node) && host.node >= 0 && host.node < 256, 'invalid cluster node');
      else need(typeof host.ssh === 'string' && /^[A-Za-z0-9]/.test(host.ssh)
        && !/[^A-Za-z0-9._-]/.test(host.ssh), 'invalid SSH selector');
    } else need(plan.hosts.length === 1 && !hasNode && !hasSsh, 'local mode is exactly one physical host without node or ssh');
    ids.add(host.id); machines.add(host.pin.physical);
  }
  for (const job of [...JOBS, 'performance-native', 'performance-js']) need(ids.has(plan.placement?.[job]), 'missing placement: ' + job);
  return {...plan, planSha256: sha(path)};
}
function filesAt(root, skip = () => false) {
  const files = [], directories = [];
  function visit(dir) {
    for (const name of readdirSync(dir).sort()) {
      const path = resolve(dir, name);
      if (skip(path)) continue;
      const st = lstatSync(path);
      need(!st.isSymbolicLink(), 'snapshot refuses symlink: ' + path);
      if (st.isDirectory()) { directories.push(relative(root, path)); visit(path); }
      else { need(st.isFile(), 'snapshot refuses special file: ' + path); files.push(path); }
    }
  }
  visit(root); return {files, directories};
}
export function makeSnapshot(context, destination) {
  return freezeSnapshot(snapshotInventory(context), destination);
}
export function freezeSnapshot(inventory, destination) {
  need(!existsSync(destination), 'snapshot already exists');
  mkdirSync(destination, {recursive: true, mode: 0o700});
  destination = realpathSync(destination);
  const entries = [], directories = new Set();
  for (const entry of inventory.files) {
    need(!isAbsolute(entry.path) && !relative(destination, resolve(destination, entry.path)).startsWith('..'), 'snapshot path escape');
    const target = resolve(destination, entry.path);
    for (let parent = dirname(target); parent !== destination; parent = dirname(parent))
      directories.add(relative(destination, parent));
    mkdirSync(dirname(target), {recursive: true});
    copyPinnedInput(entry, target);
    const mode = entry.identity[2] & 0o111 ? 0o555 : 0o444;
    chmodSync(target, mode);
    entries.push({path: entry.path, original: entry.original, sha256: entry.sha256,
      bytes: entry.identity[3], mode, role: entry.role});
  }
  for (const entry of inventory.files) {
    const current = pinFile(entry.original);
    need(current.sha256 === entry.sha256 && equal(current.identity, entry.identity)
      && equal(current.ancestors, entry.ancestors), 'source changed while freezing: ' + entry.original);
  }
  const manifest = {schemaVersion: 1, entries: entries.sort((a,b) => a.path.localeCompare(b.path)),
    directories: [...directories].sort(), mappings: inventory.mappings, producerAuthority: inventory.authority};
  fresh(resolve(destination, 'manifest.json'), manifest); chmodSync(resolve(destination, 'manifest.json'), 0o444);
  for (const dir of [...directories].sort((a,b) => b.length - a.length)) chmodSync(resolve(destination, dir), 0o555);
  chmodSync(destination, 0o555);
  return {path: destination, sha256: sha(resolve(destination, 'manifest.json')), manifest};
}
export function verifySnapshot(root, expected) {
  need(sha(resolve(root, 'manifest.json')) === expected, 'snapshot manifest changed');
  const m = json(resolve(root, 'manifest.json'));
  need(m.schemaVersion === 1, 'invalid snapshot schema');
  const inventory = filesAt(root), names = inventory.files.map(p => relative(root, p)).filter(p => p !== 'manifest.json').sort();
  need(equal(names, m.entries.map(e => e.path).sort()) && equal(inventory.directories.sort(), m.directories), 'snapshot incomplete/extra paths');
  for (const directory of ['', ...m.directories])
    need((lstatSync(resolve(root, directory)).mode & 0o777) === 0o555, 'snapshot directory is writable');
  for (const e of m.entries) {
    need(!isAbsolute(e.path) && !relative(root, resolve(root, e.path)).startsWith('..'), 'snapshot path escape');
    const path = resolve(root, e.path), st = lstatSync(path);
    need(st.size === e.bytes && (st.mode & 0o777) === e.mode && sha(path) === e.sha256, 'snapshot mutation: ' + e.path);
  }
  return m;
}
export function validateLane(result, mode, physical) {
  need(result?.runs?.length === 6, 'lane requires all six rows');
  for (let i = 0; i < ORDER.length; i++) {
    const e = result.runs[i];
    need(e.mode === mode && e.role === ORDER[i][0] && e.repetition === ORDER[i][1], 'lost/duplicate/reordered lane row');
    need(e.physical === physical, 'lane host substitution');
    need(e.report?.status === 'PASS' && e.report?.guardian?.ownedTreeStopped === true, 'unauthenticated lane row');
  }
}
export function claimHost(lock, owner) {
  mkdirSync(lock, {mode: 0o700});
  fresh(resolve(lock, 'owner.json'), owner);
  return () => {
    need(equal(json(resolve(lock, 'owner.json')), owner), 'host lease ownership changed');
    rmSync(lock, {recursive: true});
  };
}
function processes() {
  return command('/bin/ps', ['-axo', 'pid=,ppid=,lstart=,comm=']).split('\n').map(line => {
    const m = line.trim().match(/^(\d+)\s+(\d+)\s+(\S+\s+\S+\s+\d+\s+\S+\s+\d+)\s+(.+)$/);
    return m && {pid: +m[1], ppid: +m[2], identity: m[3] + ' ' + m[4], name: m[4]};
  }).filter(Boolean);
}
function descendants(rows, pid) {
  const ids = new Set([pid]); let changed = true;
  while (changed) { changed = false; for (const p of rows) if (ids.has(p.ppid) && !ids.has(p.pid)) { ids.add(p.pid); changed = true; } }
  return ids;
}
async function transport(plan, host, script, input, timeout = 60000) {
  if (plan.mode === 'ssh') {
    if (host.ssh !== undefined) return exec('/usr/bin/ssh',
      ['-o', 'BatchMode=yes', '-o', 'ConnectTimeout=8', '--', host.ssh, script], input, timeout);
    return ssh(host.node, script, input, timeout);
  }
  return new Promise(resolveResult => {
    const child = spawn('/bin/sh', ['-c', script], {stdio: ['pipe', 'pipe', 'pipe']});
    const out = [], err = []; const timer = setTimeout(() => child.kill('SIGTERM'), timeout);
    child.stdout.on('data', b => out.push(b)); child.stderr.on('data', b => err.push(b)); child.stdin.on('error', () => {});
    child.on('error', e => err.push(Buffer.from(String(e))));
    child.on('close', code => { clearTimeout(timer); resolveResult({code: code ?? 255, out: Buffer.concat(out).toString(), err: Buffer.concat(err).toString()}); });
    child.stdin.end(input);
  });
}
function response(result) {
  need(result.code === 0, 'worker transport failed: ' + result.err + '\n' + result.out);
  return JSON.parse(result.out.trim());
}
export function readEnvelope(path, expectedSha256) {
  const bytes = readFileSync(path);
  need(digest(bytes) === expectedSha256, 'job envelope mutation');
  return JSON.parse(bytes.toString('utf8'));
}
export async function dispatch(context, snapshot, job, extra = {}) {
  const plan = context.distributed, host = plan.hosts.find(h => h.id === plan.placement[job]);
  const nonce = randomBytes(24).toString('hex');
  const remote = '/tmp/bend-g24-' + nonce, root = resolve(remote, 'snapshot');
  const envelope = {schemaVersion: 1, nonce, job, snapshotSha256: snapshot.sha256, planSha256: plan.planSha256,
    pin: host.pin, mode: plan.mode, context: {runId: context.runId, candidate: context.candidate, bindings: context.bindings}, extra};
  const localEnvelope = resolve(context.out, 'dispatch-' + nonce + '.json'); fresh(localEnvelope, envelope);
  const jobSha256 = sha(localEnvelope);
  if (!snapshot.archive) {
    snapshot.archive = resolve(context.out, 'snapshot-' + snapshot.sha256 + '.tar.gz');
    const packed = spawnSync('/usr/bin/tar', ['-czf', snapshot.archive, '-C', snapshot.path, '.']);
    need(packed.status === 0, 'snapshot archive failed');
  }
  let r = await transport(plan, host, 'umask 077; mkdir ' + quote(remote) + ' && mkdir ' + quote(root));
  need(r.code === 0, 'remote namespace creation failed: ' + r.err);
  const fd = openSync(snapshot.archive, 'r'), chunk = Buffer.alloc(4 * 1024 * 1024);
  try {
    let bytes, offset = 0;
    while ((bytes = readSync(fd, chunk, 0, chunk.length, offset)) > 0) {
      need(!context.distributionCancelled, 'distribution cancelled before execution');
      // Positional writes remain idempotent under the numeric adapter's existing reconnect policy.
      r = await transport(plan, host, 'dd of=' + quote(resolve(remote, 'snapshot.tar.gz'))
        + ' bs=4194304 seek=' + (offset / chunk.length) + ' conv=notrunc 2>/dev/null', chunk.subarray(0, bytes), 600000);
      need(r.code === 0, 'snapshot chunk upload failed: ' + r.err); offset += bytes;
    }
  } finally { closeSync(fd); }
  r = await transport(plan, host, 'umask 022; tar -xzf ' + quote(resolve(remote, 'snapshot.tar.gz')) + ' -C ' + quote(root)
    + ' && /bin/chmod 0555 ' + quote(root), undefined, 600000);
  need(r.code === 0, 'snapshot extraction failed: ' + r.err);
  r = await transport(plan, host, 'cat > ' + quote(resolve(remote, 'job.json')), readFileSync(localEnvelope));
  need(r.code === 0, 'job upload failed: ' + r.err);
  // Check transported code/data with the OS tool BEFORE loading any snapshot JS.
  // The digest list comes directly from the coordinator, not the transported tree.
  const sums = [...snapshot.manifest.entries, {path: 'manifest.json', sha256: snapshot.sha256}].map(e => {
    need(!/[\r\n\\]/.test(e.path), 'unrepresentable checksum path');
    return e.sha256 + '  ' + resolve(root, e.path);
  }).join('\n') + '\n';
  const toolChecks = Object.values(host.pin.pins).map(pin => {
    need(isAbsolute(pin.path) && !/[\r\n\\]/.test(pin.path), 'invalid pinned tool path');
    return '(cd -P ' + quote(dirname(pin.path)) + ' && test \"$PWD\" = ' + quote(dirname(pin.path))
      + ' && test ! -L ' + quote(pin.path) + ')';
  }).join(' && ');
  const toolSums = Object.values(host.pin.pins).map(pin => pin.sha256 + '  ' + pin.path).join('\n') + '\n';
  r = await transport(plan, host, toolChecks + ' && /usr/bin/shasum -a 256 -c - >/dev/null', sums + toolSums, 600000);
  need(r.code === 0, 'pre-runtime snapshot/tool authentication failure: ' + r.err);
  need(host.pin.tools.bun === host.pin.pins.bun.path, 'Bun command must use its pinned canonical path');
  const cli = [host.pin.pins.bun.path, resolve(root, 'repository/evals/g24_distributed.mjs')].map(quote).join(' ');
  // Control never starts a second runtime on the dedicated measurement host.
  const control = action => transport(plan, host, action === 'result'
    ? 'cat ' + quote(resolve(remote, 'result.json'))
    : 'printf %s ' + quote(nonce) + ' > ' + quote(resolve(remote, action === 'renew' ? 'lease' : 'cancel')) + " && printf '{}\\n'");
  const started = Date.now(); let controlFailure, cancelled = false, renewing = false;
  const cancel = () => { cancelled = true; void control('cancel').catch(() => {}); };
  process.on('SIGINT', cancel); process.on('SIGTERM', cancel); process.on('SIGHUP', cancel);
  const beat = setInterval(async () => {
    if (renewing || cancelled) return; renewing = true;
    try { const got = await control('renew'); need(got.code === 0, got.err); }
    catch (e) { controlFailure = String(e); cancel(); }
    finally { renewing = false; }
  }, 5000);
  try {
    need(!context.distributionCancelled, 'distribution cancelled before execution');
    response(await control('renew'));
    const result = await transport(plan, host, cli + ' supervise ' + quote(remote) + ' ' + quote(nonce)
      + ' ' + quote(jobSha256), undefined, 48 * 3600000);
    fresh(resolve(context.out, 'transport-' + nonce + '.json'), result);
    if (result.code !== 0) cancel();
    // Always fetch the durable result through the authenticated transport, even
    // after a lost long-running connection. Never accept a preexisting receipt.
    let final;
    for (let attempt = 0; attempt < 70; attempt++) {
      const got = await control('result');
      if (got.code === 0) { final = response(got); break; }
      if (result.code !== 0) cancel();
      await new Promise(r => setTimeout(r, 1000));
    }
    need(final, 'reaping unconfirmed; host lease remains poisoned at ' + remote);
    fresh(resolve(context.out, 'result-' + nonce + '.json'), final);
    need(!cancelled && !controlFailure && result.code === 0, 'dispatch cancelled/transport failed: ' + (controlFailure ?? result.err));
    need(final.status === 'PASS' && final.reaped === true, 'worker failed: ' + JSON.stringify(final));
    need(final.nonce === nonce && final.job === job && final.jobSha256 === jobSha256 && final.snapshotSha256 === snapshot.sha256
      && final.planSha256 === plan.planSha256 && equal(final.pin, host.pin), 'worker result authentication mismatch');
    return {...final.value, transport: {nonce, job, physical: host.pin.physical, planSha256: plan.planSha256,
      snapshotSha256: snapshot.sha256, remote, started, finished: Date.now(), mode: plan.mode}};
  } finally {
    clearInterval(beat); process.off('SIGINT', cancel); process.off('SIGTERM', cancel); process.off('SIGHUP', cancel);
  }
}
export async function distributedConsumers(run, context, state, fixtures) {
  context.candidate = {repository: context.repository, binary: {path: state.native.binary, sha256: state.native.binarySha256}, stageOne: state.fixedpoint.stageOne};
  context.evidence = state;
  need(Array.isArray(fixtures) && fixtures.length > 0, 'consumer fixture inventory is required');
  context.snapshotFixtures = fixtures;
  const snapshot = makeSnapshot(context, resolve(context.out, 'consumer-snapshot'));
  const results = {}, failures = [];
  // One sequential queue per pinned physical host; independent hosts run real SSH workers concurrently.
  await Promise.all(context.distributed.hosts.map(async host => {
    for (const job of JOBS.filter(j => context.distributed.placement[j] === host.id)) {
      if (failures.length) break;
      try { results[job] = await dispatch(context, snapshot, job); }
      catch (e) { failures.push(e); context.distributionCancelled = true; process.emit('SIGTERM'); break; }
    }
  }));
  need(failures.length === 0, failures.map(String).join('\n'));
  need(equal(Object.keys(results).sort(), [...JOBS].sort()), 'incomplete distributed consumer results');
  state.matrix = {c: results['matrix-c'].matrix, js: results['matrix-js'].matrix};
  for (const job of ['native', 'admission', 'host']) state.consumers[job] = results[job].consumer;
  state.distributed = {protocol: 1, planSha256: context.distributed.planSha256, snapshotSha256: snapshot.sha256,
    jobs: JOBS.map(job => results[job].transport)};
  run.publish();
}
export async function distributedMeasurements(context) {
  const snapshot = makeSnapshot(context, resolve(context.out, 'performance-snapshot'));
  const native = await dispatch(context, snapshot, 'performance-native');
  validateLane(native, 'native', native.transport.physical);
  const expected = native.candidateExpected;
  need(/^[a-f0-9]{64}$/.test(expected), 'native output authentication missing');
  const js = await dispatch(context, snapshot, 'performance-js', {candidateExpected: expected, nativeTransport: native.transport});
  validateLane(js, 'js', js.transport.physical);
  need(js.candidateExpected === expected, 'cross-lane output mismatch');
  return {runs: [...native.runs, ...js.runs], candidateExpected: expected,
    placement: {protocol: 1, mode: context.distributed.mode, native: native.transport, js: js.transport}};
}
async function supervise(directory, nonce, jobSha256) {
  const job = readEnvelope(resolve(directory, 'job.json'), jobSha256);
  need(job.nonce === nonce, 'nonce mismatch'); cleanEnvironment();
  // gates/_lib may reconnect a dropped SSH command. Never execute it twice or
  // publish a second supervisor's failure over the first supervisor's evidence.
  mkdirSync(resolve(directory, 'supervisor-started'), {mode: 0o700});
  const result = {nonce, jobSha256, job: job.job, snapshotSha256: job.snapshotSha256, planSha256: job.planSha256,
    status: 'FAIL', reaped: false, pin: null};
  const lock = '/tmp/bend-g24-dedicated-host.lock';
  let release, child, monitor, stopping = false, stoppedAt, reason, known = new Map();
  const refreshOwned = () => {
    const rows = processes(), owned = child?.pid ? descendants(rows, child.pid) : new Set();
    const live = rows.filter(p => owned.has(p.pid) || known.get(p.pid) === p.identity);
    known = new Map(live.map(p => [p.pid, p.identity]));
    return live;
  };
  const stop = why => {
    reason ??= why; stopping = true; stoppedAt ??= Date.now();
    if (child?.pid) {
      refreshOwned();
      try { process.kill(-child.pid, 'SIGTERM'); } catch (e) { if (e.code !== 'ESRCH') reason += ': ' + e; }
    }
  };
  const signal = () => stop('supervisor interrupted');
  process.on('SIGTERM', signal); process.on('SIGINT', signal); process.on('SIGHUP', signal);
  try {
    result.pin = hostPin(job.pin.tools); need(equal(result.pin, job.pin), 'host/runtime/tool substitution');
    verifySnapshot(resolve(directory, 'snapshot'), job.snapshotSha256);
    release = claimHost(lock, {nonce, directory, pid: process.pid});
    need(!stopping && !existsSync(resolve(directory, 'cancel'))
      && Date.now() - statSync(resolve(directory, 'lease')).mtimeMs <= 45000, 'cancelled/expired before execution');
    need(!existsSync(resolve(directory, 'execution')), 'job already executed');
    mkdirSync(resolve(directory, 'execution'));
    const log = await import('node:fs');
    const out = log.openSync(resolve(directory, 'worker.stdout'), 'wx'), err = log.openSync(resolve(directory, 'worker.stderr'), 'wx');
    // Independent OS watchdog survives supervisor death even while Bun is in a
    // synchronous gate call. Its group termination closes guardian owner pipes.
    const sentinel = 'owner=$1; shift; '
      + '(while kill -0 \"$owner\" 2>/dev/null; do sleep 1; done; /bin/kill -TERM -$$) & watch=$!; '
      + '\"$@\"; code=$?; kill \"$watch\" 2>/dev/null; wait \"$watch\" 2>/dev/null; exit \"$code\"';
    child = spawn('/bin/sh', ['-c', sentinel, 'g24-owner-watch', String(process.pid),
      job.pin.tools.bun, SCRIPT, 'execute', directory, nonce, jobSha256], {detached: true, stdio: ['ignore', out, err]});
    log.closeSync(out); log.closeSync(err);
    monitor = setInterval(() => {
      try {
        refreshOwned();
        if (existsSync(resolve(directory, 'cancel')) || Date.now() - statSync(resolve(directory, 'lease')).mtimeMs > 45000) stop('cancelled or coordinator lease expired');
        if (stopping) for (const pid of known.keys()) {
          try { process.kill(pid, Date.now() - stoppedAt > 10000 ? 'SIGKILL' : 'SIGTERM'); } catch {}
        }
      } catch (e) { stop(String(e)); }
    }, 1000);
    const code = await new Promise((done, reject) => { child.once('error', reject); child.once('close', code => done(code)); });
    clearInterval(monitor);
    // Guardian children may detach their process groups. Track descendants while
    // alive, wait for their own guardian cleanup, then refuse a clean lease release
    // unless every observed process is gone. Never treat SSH exit as tree reaping.
    if (code !== 0 || stopping) stop(reason ?? 'worker exit ' + code);
    for (let n = 0; n < 15; n++) {
      const live = refreshOwned();
      if (live.length === 0) { result.reaped = true; break; }
      for (const p of live) { try { process.kill(p.pid, n < 10 ? 'SIGTERM' : 'SIGKILL'); } catch {} }
      await new Promise(r => setTimeout(r, 1000));
    }
    need(result.reaped, 'owned process reaping unconfirmed');
    need(code === 0 && !stopping, reason ?? 'worker failed');
    verifySnapshot(resolve(directory, 'snapshot'), job.snapshotSha256);
    need(equal(hostPin(job.pin.tools), job.pin), 'host/tool changed during job');
    result.value = json(resolve(directory, 'execution/value.json'));
    result.status = 'PASS';
  } catch (e) { result.error = String(e?.stack ?? e); if (!child) result.reaped = true; }
  finally {
    clearInterval(monitor); process.off('SIGTERM', signal); process.off('SIGINT', signal); process.off('SIGHUP', signal);
    fresh(resolve(directory, 'result.json'), result);
    if (release && result.reaped) release();
  }
  console.log(JSON.stringify({status: result.status, reaped: result.reaped}));
  if (result.status !== 'PASS') process.exitCode = 1;
}
async function execute(directory, nonce, jobSha256) {
  const job = readEnvelope(resolve(directory, 'job.json'), jobSha256);
  need(job.nonce === nonce, 'nonce mismatch');
  const root = resolve(directory, 'snapshot'), manifest = verifySnapshot(root, job.snapshotSha256);
  need(equal(hostPin(job.pin.tools), job.pin), 'host substitution before execution');
  // Existing admission/host consumers create sources beneath their repository
  // cwd. Materialize ONLY declared repository inputs into a private execution
  // tree, leaving the immutable transport snapshot untouched.
  const repository = resolve(directory, 'execution/repository');
  mkdirSync(repository);
  const inputs = manifest.entries.filter(entry => entry.path.startsWith('repository/'));
  for (const entry of inputs) {
    const source = resolve(root, entry.path), target = resolve(repository, entry.path.slice('repository/'.length));
    mkdirSync(dirname(target), {recursive: true});
    copyPinnedInput({original: source, ...pinFile(source), sha256: entry.sha256}, target);
    chmodSync(target, entry.mode);
  }
  const out = resolve(repository, 'checkpoints/.g24-' + nonce);
  mkdirSync(out, {recursive: true});
  const {runDistributedWorker} = await import('./g24_qualification.mjs');
  let value;
  try { value = await runDistributedWorker(job, root, out, repository); }
  finally {
    for (const entry of inputs) {
      const path = resolve(repository, entry.path.slice('repository/'.length));
      need(!lstatSync(path).isSymbolicLink() && sha(path) === entry.sha256
        && (lstatSync(path).mode & 0o777) === entry.mode, 'execution source mutation: ' + path);
    }
    const expected = new Set(inputs.map(entry => entry.path.slice('repository/'.length)));
    for (const path of filesAt(repository).files) if (!path.startsWith(out + '/'))
      need(expected.has(relative(repository, path)), 'unlisted execution input/output: ' + path);
  }
  fresh(resolve(directory, 'execution/value.json'), {...value, execution: {repository, out,
    sourceMapping: 'byte-identical declared repository files; producer provenance unchanged'}});
}
if (import.meta.main) {
  const [action, path, argument, output] = process.argv.slice(2);
  if (action === 'probe') console.log(JSON.stringify(hostPin(json(path)), null, 2));
  else if (action === 'verify') { verifySnapshot(path, argument); console.log('SNAPSHOT_VERIFIED'); }
  else if (action === 'consumers') {
    const {runDistributedConsumersFromReceipt} = await import('./g24_qualification.mjs');
    await runDistributedConsumersFromReceipt(loadPlan(path), argument, output);
  } else if (['renew', 'cancel', 'result', 'supervise', 'execute'].includes(action)) {
    const job = json(resolve(path, 'job.json')); need(job.nonce === argument, 'control nonce mismatch');
    if (action === 'renew') { writeFileSync(resolve(path, 'lease'), argument); console.log('{}'); }
    else if (action === 'cancel') { writeFileSync(resolve(path, 'cancel'), argument); console.log('{}'); }
    else if (action === 'result') console.log(readFileSync(resolve(path, 'result.json'), 'utf8'));
    else if (action === 'supervise') await supervise(path, argument, output);
    else await execute(path, argument, output);
  } else throw Error('usage: probe TOOLS.json | consumers PLAN.json RECEIPT.json FRESH_OUT | verify SNAPSHOT SHA256');
}
