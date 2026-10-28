/**
 * Diagnostic witness driver for the three inline-value boundaries:
 * projected unpacked Bool field, projected/array Char codepoint, and Bool
 * field Fill arm tags.
 *
 * This is NOT the acceptance matrix. It runs exactly the three reduced
 * `repro_inline57ab_*` sources through the real candidate host (parse /
 * expand / check / sharedEmitC), then clang, then the executable, and
 * compares stdout to the fixture's `#|` expectation lines.
 *
 * Every heavy child runs under the existing authenticated heavy_gate with the
 * default lane (8192 MiB footprint / 8192 MiB RSS, 10 ms sampling, 600 s
 * deadline). The host is driven by the explicit accepted Node 23.11 binary,
 * never by the runner's own interpreter. Each stage keeps complete raw
 * stdout/stderr plus the guardian JSON under a fresh --logs directory; the
 * emitted C and executable are retained and hashed. Nothing is overwritten,
 * piped, or truncated.
 *
 * Usage:
 *   bun evals/repro_inline57ab_run.ts \
 *     --host=<candidate_host.ts> --component=<artifact.js> \
 *     --parser=<parser.js> --tag=SourceFile \
 *     --node=/Users/ilyagulya/Library/pnpm/nodejs/23.11.0/bin/node \
 *     --logs=<fresh dir> --receipt=<path.json>
 *   Optional: --fixture=<path.bend> (repeatable; overrides the default three)
 */
import {existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync} from 'node:fs';
import {basename, resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {runHeavyGate} from './heavy_gate.ts';

const option = (name: string): string | undefined =>
  process.argv.find(arg => arg.startsWith('--' + name + '='))?.slice(name.length + 3);
const fixturesArg = process.argv.filter(arg => arg.startsWith('--fixture=')).map(arg => arg.slice('--fixture='.length));
const host = option('host');
const component = option('component');
const parser = option('parser');
const tag = option('tag');
const node = option('node');
const logs = option('logs');
const receiptPath = option('receipt');
// Opt-in checked-program capture: candidate_host writes CheckSuccess.program
// before runCEmitterSteps (checked frontend transport, not lowered code) and
// still writes it when emission fails. HOLD: no such emit unless Control asks
// for a fact that is otherwise unreachable.
const checkedOutDir = option('checked-out');
// Emit-only mode: stop after sharedEmitC. Used for one diagnostic read of a
// non-admitted artifact where only the emit failure text is wanted; no clang
// and no executable run are then authorized or performed.
const emitOnly = process.argv.includes('--emit-only');
if (host === undefined || component === undefined || parser === undefined || tag === undefined) {
  throw Error('usage: --host=<candidate_host.ts> --component=<artifact> --parser=<parser> --tag=<source tag> [--node=<node>] --logs=<fresh dir> [--receipt=<path>]');
}
if (logs === undefined) throw Error('--logs=<fresh dir> is required');
if (node === undefined) throw Error('--node=<accepted Node 23.11 binary> is required');
const fixtureNames = fixturesArg.length > 0 ? fixturesArg : [
  'evals/repro_inline57ab_bool_projection.bend',
  'evals/repro_inline57ab_char_codepoint.bend',
  'evals/repro_inline57ab_bool_fill_tags.bend',
];
if (existsSync(logs) && readdirSync(logs).length > 0) throw Error('refuse to overwrite non-empty log directory: ' + logs);
mkdirSync(logs, {recursive: true});
if (checkedOutDir !== undefined) mkdirSync(checkedOutDir, {recursive: true});

const fileSha = (path: string): string => createHash('sha256').update(readFileSync(path)).digest('hex');

const version = Bun.spawnSync([node, '--version'], {stdout: 'pipe', stderr: 'pipe'});
const nodeVersion = new TextDecoder().decode(version.stdout).trim();
if (version.exitCode !== 0 || !nodeVersion.startsWith('v23.11.0')) {
  throw Error('--node must be the accepted v23.11.0 V8 runtime, got: ' + nodeVersion);
}
const heapProbe = Bun.spawnSync([node, '--max-old-space-size=3072', '-e',
  'process.stdout.write(process.versions.v8 + "|" + process.execArgv.join(","))'], {stdout: 'pipe', stderr: 'pipe'});
const v8 = new TextDecoder().decode(heapProbe.stdout).trim();
if (heapProbe.exitCode !== 0 || !v8.includes('--max-old-space-size=3072')) {
  throw Error('--node does not honour --max-old-space-size=3072: ' + v8);
}

const base = resolve('bend2/base.bend');
const runtimeC = resolve('bend2/selfhost/c_runtime.c');
const gateCaps = {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000};

interface Stage {
  label: string;
  command: string[];
  status: string;
  reason: string;
  reportPhase: string;
  ownedTreeStopped: boolean | null;
  commandExitCode: number;
  commandSignal: number;
  effectiveExitCode: number;
  elapsedMs: number;
  peakRssBytes: number;
  peakFootprintBytes: number;
  stdoutPath: string;
  stderrPath: string;
  stdoutSha256: string;
  stderrSha256: string;
  stdoutBytes: number;
  stderrBytes: number;
  gatePath: string;
  stdout: string;
  stderr: string;
}

async function guarded(stem: string, label: string, command: string[]): Promise<Stage> {
  const outPath = logs + '/' + stem + '.' + label + '.stdout';
  const errPath = logs + '/' + stem + '.' + label + '.stderr';
  const wrapped = ['/bin/sh', '-c', 'out=$1; err=$2; shift 2; exec "$@" >"$out" 2>"$err"', 'sh', outPath, errPath, ...command];
  const gate = await runHeavyGate(wrapped, {label: stem + ':' + label, ...gateCaps});
  let gatePath = '';
  if (gate.reportPath.length > 0 && existsSync(gate.reportPath)) {
    gatePath = logs + '/' + stem + '.' + label + '.gate.report.json';
    writeFileSync(gatePath, readFileSync(gate.reportPath));
  }
  writeFileSync(logs + '/' + stem + '.' + label + '.gate.json',
    JSON.stringify({...gate, argv: command, stdoutPath: outPath, stderrPath: errPath}, null, 2) + '\n');
  const stdout = existsSync(outPath) ? readFileSync(outPath, 'utf8') : '';
  const stderr = existsSync(errPath) ? readFileSync(errPath, 'utf8') : '';
  return {
    label, command, status: gate.status, reason: gate.reason, reportPhase: gate.reportPhase,
    ownedTreeStopped: gate.ownedTreeStopped, commandExitCode: gate.commandExitCode,
    commandSignal: gate.commandSignal, effectiveExitCode: gate.exitCode, elapsedMs: gate.elapsedMs,
    peakRssBytes: gate.peakRssBytes, peakFootprintBytes: gate.peakFootprintBytes,
    stdoutPath: outPath, stderrPath: errPath, stdoutSha256: createHash('sha256').update(stdout).digest('hex'),
    stderrSha256: createHash('sha256').update(stderr).digest('hex'),
    stdoutBytes: Buffer.byteLength(stdout), stderrBytes: Buffer.byteLength(stderr), gatePath, stdout, stderr,
  };
}

const clean = (stage: Stage): Record<string, unknown> => ({
  command: stage.command, status: stage.status, reason: stage.reason, reportPhase: stage.reportPhase,
  ownedTreeStopped: stage.ownedTreeStopped, commandExitCode: stage.commandExitCode,
  commandSignal: stage.commandSignal, effectiveExitCode: stage.effectiveExitCode,
  elapsedMs: stage.elapsedMs, peakRssBytes: stage.peakRssBytes, peakFootprintBytes: stage.peakFootprintBytes,
  stdoutPath: stage.stdoutPath, stdoutSha256: stage.stdoutSha256, stdoutBytes: stage.stdoutBytes,
  stderrPath: stage.stderrPath, stderrSha256: stage.stderrSha256, stderrBytes: stage.stderrBytes,
  gatePath: stage.gatePath,
});
const passed = (stage: Stage): boolean =>
  stage.status === 'PASS' && stage.effectiveExitCode === 0 && stage.commandExitCode === 0 &&
  stage.reportPhase === 'complete' && stage.ownedTreeStopped === true;
const failureLine = (stage: Stage): string =>
  (stage.stderr.trim().split('\n').filter(line => line.trim().length > 0).pop() ?? '').slice(0, 400);

interface FixtureResult {
  fixture: string;
  sourceSha256: string;
  expected: string;
  status: string;
  observed?: string;
  detail?: string;
  artifacts?: Record<string, {path: string; bytes: number; sha256: string}>;
  checkedOut?: {path: string; bytes: number; sha256: string};
  stages: Record<string, Record<string, unknown>>;
  rawStdout?: string;
}

const results: FixtureResult[] = [];
for (const name of fixtureNames) {
  const source = resolve(name);
  if (!existsSync(source)) throw Error(name + ': fixture missing');
  const stem = basename(name, '.bend');
  const expected = [...readFileSync(source, 'utf8').matchAll(/^#\|(.+)$/gm)].map(match => match[1]).join('\n');
  if (expected.length === 0) throw Error(name + ': no #| expectation');
  const cFile = logs + '/' + stem + '.c';
  const exe = logs + '/' + stem;
  const result: FixtureResult = {fixture: source, sourceSha256: fileSha(source), expected, status: 'UNKNOWN', stages: {}};
  results.push(result);

  // Host argv matches the frozen acceptance runner exactly, plus the opt-in
  // checked-program dump that does not change emission.
  const checkedOutPath = checkedOutDir === undefined ? undefined : resolve(checkedOutDir) + '/' + stem + '.checked.json';
  const emit = await guarded(stem, 'emit', [node, '--experimental-strip-types', '--max-old-space-size=3072',
    resolve(host), '--candidate=' + resolve(component), '--source-tag=' + tag, '--parser=' + resolve(parser),
    source, '-o', cFile, '--base=' + base, '--runtime-c=' + runtimeC,
    ...(checkedOutPath === undefined ? [] : ['--checked-out=' + checkedOutPath])]);
  result.stages.emit = clean(emit);
  if (checkedOutPath !== undefined && existsSync(checkedOutPath)) {
    result.checkedOut = {path: checkedOutPath, bytes: readFileSync(checkedOutPath).length, sha256: fileSha(checkedOutPath)};
  }
  if (!passed(emit)) {
    result.status = 'EMIT_FAIL';
    result.detail = 'gate=' + emit.status + ' effective=' + emit.effectiveExitCode + ' command=' + emit.commandExitCode +
      ' phase=' + emit.reportPhase + ' stopped=' + String(emit.ownedTreeStopped) + '; ' + failureLine(emit);
    continue;
  }
  if (!existsSync(cFile)) {
    result.status = 'EMIT_FAIL';
    result.detail = 'emit exited 0 without writing ' + cFile;
    continue;
  }
  if (emitOnly) {
    result.status = 'EMIT_ONLY_PASS_UNCOMPILED';
    result.artifacts = {[basename(cFile)]: {path: cFile, bytes: readFileSync(cFile).length, sha256: fileSha(cFile)}};
    continue;
  }
  const clang = await guarded(stem, 'clang', ['clang', '-std=c11', '-O0', '-ferror-limit=0', '-pthread', '-lm', '-o', exe, cFile]);
  result.stages.clang = clean(clang);
  if (!passed(clang)) {
    result.status = 'CLANG_FAIL';
    result.detail = 'gate=' + clang.status + ' effective=' + clang.effectiveExitCode + ' command=' + clang.commandExitCode +
      ' phase=' + clang.reportPhase + ' stopped=' + String(clang.ownedTreeStopped) + '; ' + failureLine(clang);
    continue;
  }
  const run = await guarded(stem, 'run', [exe]);
  result.stages.run = clean(run);
  if (!passed(run)) {
    result.status = 'RUN_FAIL';
    result.detail = 'gate=' + run.status + ' effective=' + run.effectiveExitCode + ' command=' + run.commandExitCode +
      ' phase=' + run.reportPhase + ' stopped=' + String(run.ownedTreeStopped) + '; ' + failureLine(run);
    continue;
  }
  const observed = run.stdout.trim();
  result.observed = observed;
  result.artifacts = {};
  for (const path of [cFile, exe]) {
    if (existsSync(path)) result.artifacts[basename(path)] = {path, bytes: readFileSync(path).length, sha256: fileSha(path)};
  }
  if (observed !== expected) {
    result.status = 'OUTPUT_MISMATCH';
    result.detail = 'observed ' + JSON.stringify(observed) + ' expected ' + JSON.stringify(expected);
    continue;
  }
  result.status = 'PASS';
}

const overall = results.every(result => result.status === 'PASS') ? 'PASS' : 'FAIL';
const pins = {
  schemaVersion: 1,
  kind: 'C_INLINE_VALUE_REPRO',
  scope: 'DIAGNOSTIC_WITNESS_ONLY: three reduced inline-value sources; not the 13-export/24-case acceptance matrix and not a Root GO',
  status: overall,
  worktree: process.cwd(),
  logs,
  host: {path: resolve(host), sha256: fileSha(resolve(host))},
  component: {path: resolve(component), sha256: fileSha(resolve(component)), bytes: readFileSync(resolve(component)).length},
  parser: {path: resolve(parser), sha256: fileSha(resolve(parser))},
  tag,
  node: {path: node, sha256: fileSha(node), version: nodeVersion, v8},
  base: {path: base, sha256: fileSha(base)},
  runtimeC: {path: runtimeC, sha256: fileSha(runtimeC)},
  guardian: {
    ts: resolve('evals/heavy_gate.ts'), tsSha256: fileSha(resolve('evals/heavy_gate.ts')),
    nativeC: resolve('evals/heavy_gate_native.c'), nativeCSha256: fileSha(resolve('evals/heavy_gate_native.c')),
  },
  caps: {...gateCaps, hostHeapMiB: 3072},
  checkedOutDir,
  emitOnly,
  fixtures: results.map(result => ({
    fixture: result.fixture, sourceSha256: result.sourceSha256, expected: result.expected,
    status: result.status, observed: result.observed, detail: result.detail, artifacts: result.artifacts,
    checkedOut: result.checkedOut,
  })),
  stages: Object.fromEntries(results.map(result => [basename(result.fixture, '.bend'), result.stages])),
  committedSources: fixtureNames.filter(name => name.startsWith('evals/repro_inline57ab_')).map(name => ({
    path: resolve(name), sha256: fileSha(resolve(name)),
  })),
};
writeFileSync(logs + '/repro.receipt.json', JSON.stringify(pins, null, 2) + '\n');
if (receiptPath !== undefined) writeFileSync(resolve(receiptPath), JSON.stringify(pins, null, 2) + '\n');
for (const result of results) {
  console.log(JSON.stringify({
    fixture: basename(result.fixture), status: result.status,
    observed: result.observed, expected: result.expected, detail: result.detail,
  }));
}
console.log(JSON.stringify({status: overall, fixtures: results.length, logDir: logs, nodeVersion, v8}));
if (overall !== 'PASS') process.exitCode = 1;
