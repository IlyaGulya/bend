import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {readFileSync, writeFileSync, mkdirSync, existsSync, openSync, closeSync, realpathSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';

// Parent-only launcher. One child suite, one source, one target, strictly serial.
// source-suite owns the heavy guards; this wrapper never adds another guard.
const NODE = '/Users/ilyagulya/bend-g12-borrow-7782b78a-1e88-4ffd-9889-14cb52c6a5b9/.tools/node';
const SUITE = '/private/tmp/bend-n01-n08-HL7Pt3/source-suite.mjs';
const [input, outputArg] = process.argv.slice(2);
if (!input || !outputArg) throw Error('usage: remaining-runner.mjs REMAINING_SUITE FRESH_DIRECTORY');
const out = resolve(outputArg);
if (existsSync(out)) throw Error('fresh output directory required');
mkdirSync(out, {recursive: true});
const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');
const report = {schemaVersion: 1, status: 'STARTING', diagnosticOnly: true, compilerAccepted: false, rows: [], failures: [], skipped: []};
const save = () => writeFileSync(out + '/receipt.json', JSON.stringify(report, null, 2) + '\n');
save();
function readRecord(path, failures) {
  if (!existsSync(path)) return null;
  try { return JSON.parse(readFileSync(path, 'utf8')); }
  catch (error) { failures.push({path, error: String(error)}); return null; }
}
async function launch(command, stdout, stderr) {
  let fdOut, fdErr;
  try {
    fdOut = openSync(stdout, 'wx'); fdErr = openSync(stderr, 'wx');
    return await new Promise(resolveResult => {
      const child = spawn(command[0], command.slice(1), {stdio: ['ignore', fdOut, fdErr]});
      child.once('error', error => resolveResult({exit: null, signal: null, setupError: String(error)}));
      child.once('close', (exit, signal) => resolveResult({exit, signal}));
    });
  } catch (error) { return {exit: null, signal: null, setupError: String(error)}; }
  finally { if (fdOut !== undefined) closeSync(fdOut); if (fdErr !== undefined) closeSync(fdErr); }
}
try {
  assert.equal(realpathSync(process.execPath), realpathSync(NODE), 'use pinned Node');
  report.input = {path: resolve(input), sha256: hash(input)};
  report.launcher = {path: SUITE, sha256: hash(SUITE)};
  const suite = JSON.parse(readFileSync(input, 'utf8'));
  report.preservedPriorFailure = suite.preservedPriorFailure;
  const names = new Set();
  for (const test of suite.rows) {
    assert.match(test.name, /^[a-z0-9-]+$/); assert.ok(!names.has(test.name)); names.add(test.name);
    assert.notEqual(test.source, suite.preservedPriorFailure?.source, 'unchanged prior producer failure must remain excluded');
    let producerRejection = null;
    for (const target of test.targets ?? ['c', 'js']) {
      assert.ok(target === 'c' || target === 'js');
      const name = test.name + '-' + target;
      if (producerRejection) {
        report.skipped.push({name, source: test.source, target, status: 'SKIPPED_DUPLICATE_CHECKER_REJECTION', evidence: producerRejection, executionClaim: false});
        save(); continue;
      }
      const one = out + '/' + name + '.suite.json', directory = out + '/' + name;
      const row = {name, source: test.source, target, status: 'STARTING', directory, evidenceErrors: []};
      report.rows.push(row); save();
      try {
        assert.equal(hash(SUITE), report.launcher.sha256, 'launcher drift');
        assert.equal(hash(input), report.input.sha256, 'suite drift');
        row.sourceSha256 = hash(test.source);
        writeFileSync(one, JSON.stringify({schemaVersion: 1, rows: [{...test, targets: [target]}]}, null, 2) + '\n', {flag: 'wx'});
        row.request = {path: one, sha256: hash(one)};
        row.command = [NODE, '--experimental-strip-types', SUITE, one, directory];
        row.stdout = out + '/' + name + '.launcher.stdout'; row.stderr = out + '/' + name + '.launcher.stderr';
        row.status = 'RUNNING'; save();
        row.launch = await launch(row.command, row.stdout, row.stderr);
        row.stdoutSha256 = existsSync(row.stdout) ? hash(row.stdout) : null;
        row.stderrSha256 = existsSync(row.stderr) ? hash(row.stderr) : null;
        const childReceipt = directory + '/receipt.json', compilePath = directory + '/' + name + '.compile.json';
        row.childReceipt = {path: childReceipt, sha256: existsSync(childReceipt) ? hash(childReceipt) : null};
        row.compilation = {path: compilePath, sha256: existsSync(compilePath) ? hash(compilePath) : null};
        const child = readRecord(childReceipt, row.evidenceErrors), compiled = readRecord(compilePath, row.evidenceErrors);
        if (compiled) {
          row.steps = compiled.steps; row.phases = compiled.phases; row.compilerError = compiled.error;
          row.probeStatuses = (compiled.snapshots ?? []).map(x => ({path: x.path, status: x.snapshot?.status, mutation: x.snapshot?.diagnosticMutation?.verdict}));
        }
        const rejected = compiled?.status === 'FAIL'
          && compiled.phases?.some(p => p.name === 'check')
          && String(compiled.error).includes('own checker:')
          && row.probeStatuses?.some(p => p.status === 'PRODUCER_REJECTED');
        if (rejected) {
          row.status = 'PRODUCER_REJECTED';
          producerRejection = {path: compilePath, sha256: row.compilation.sha256, error: compiled.error, steps: compiled.steps};
        } else if (row.launch.exit === 0 && !row.launch.signal && child?.status === 'PASS' && child.rows?.length === 1 && child.rows[0].status === 'PASS' && !row.evidenceErrors.length) {
          row.status = 'TARGET_EXECUTION_PASS'; row.actual = child.rows[0].actual;
          assert.equal(row.actual, test.expected);
        } else {
          row.status = compiled?.phases?.some(p => p.name === 'check') ? 'POST_CHECK_OR_OBSERVER_FAILURE' : 'SETUP_OR_FRONTEND_FAILURE';
          row.childError = child?.error ?? null;
        }
      } catch (error) { row.status = 'SETUP_FAILURE'; row.evidenceErrors.push({error: String(error), stack: error?.stack}); }
      if (row.status !== 'TARGET_EXECUTION_PASS') report.failures.push({name, status: row.status, directory});
      save();
      // A C emission/clang/execution failure is not a checker rejection: JS is
      // still a different target question and gets its own fresh child suite.
    }
  }
  report.status = report.failures.length ? 'COMPLETE_WITH_FAILURES' : 'ALL_REQUESTED_TARGETS_EXECUTED';
  report.contextualProof = 'NOT_ESTABLISHED_BY_LAUNCHER';
  if (report.failures.length) process.exitCode = 1;
} catch (error) { report.status = 'SETUP_FAILED'; report.failures.push({error: String(error), stack: error?.stack}); process.exitCode = 1; }
save();
console.log(JSON.stringify({status: report.status, report: out + '/receipt.json', rows: report.rows.map(r => ({name: r.name, status: r.status})), skipped: report.skipped}));
