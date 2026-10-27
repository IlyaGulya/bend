/**
 * Full target matrix: emit each fixture with the real typed-step host, then
 * clang (C) or run the emitted JS (JS) and compare stdout to its `#|` lines.
 *
 * Every heavy child runs under the existing authenticated heavy_gate:
 * 8192 MiB physical footprint / 8192 MiB RSS, 10 ms sampling, 600 s deadline.
 * The matrix runner itself may be Bun, but the host and JS lane always use the
 * explicit Node/V8 binary given by --node (validated), never process.execPath.
 * Each stage writes complete stdout, stderr, exit, and guardian JSON under a
 * fresh, caller-owned --logs directory; nothing is overwritten.
 *
 * Usage:
 *   bun evals/c_target_fixtures_run.ts --driver=<driver> --logs=<fresh dir>
 *   bun evals/c_target_fixtures_run.ts --host=<candidate_host.ts>
 *     --component=<artifact> --parser=<parser artifact> --tag=<tag>
 *     --node=<node binary> --target=c|js --logs=<fresh dir> [--keep]
 */
import {existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, writeFileSync} from 'node:fs';
import {basename, resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {runHeavyGate} from './heavy_gate.ts';

const option = (name: string): string | undefined =>
  process.argv.find(arg => arg.startsWith('--' + name + '='))?.slice(name.length + 3);
const target = option('target') ?? 'c';
if (target !== 'c' && target !== 'js') throw Error('--target must be c or js');
const host = option('host');
const component = option('component');
const parser = option('parser');
const tag = option('tag');
const driver = option('driver');
const node = option('node') ?? process.env.NODE ?? 'node';
const keep = process.argv.includes('--keep');
// Development-only smoke selector. The acceptance matrix never passes this and
// always runs every case; it exists so a one-fixture guardian/runtime check can
// be executed without rerunning the recorded full matrix.
const smokeCase = option('smoke-case');
if (host === undefined && driver === undefined) {
  throw Error('usage: --driver=<driver> or --host=<candidate_host.ts> --component=<artifact> --parser=<parser> --tag=<tag>');
}
if (host !== undefined && (component === undefined || parser === undefined || tag === undefined)) {
  throw Error('--host requires --component, --parser and --tag');
}
const logs = option('logs') ?? mkdtempSync('/tmp/c-target-matrix-' + target + '-');
if (existsSync(logs) && readdirSync(logs).length > 0) throw Error('refuse to overwrite non-empty log directory: ' + logs);
mkdirSync(logs, {recursive: true});

const version = Bun.spawnSync([node, '--version'], {stdout: 'pipe', stderr: 'pipe'});
const nodeVersion = new TextDecoder().decode(version.stdout).trim();
if (version.exitCode !== 0 || !nodeVersion.startsWith('v23.11.0')) {
  throw Error('--node must be the accepted Node v23.11.0 V8 runtime, got: ' + nodeVersion);
}
const heapProbe = Bun.spawnSync([node, '--max-old-space-size=3072', '-e',
  'process.stdout.write(process.versions.v8 + "|" + process.execArgv.join(","))'], {stdout: 'pipe', stderr: 'pipe'});
const v8 = new TextDecoder().decode(heapProbe.stdout).trim();
if (heapProbe.exitCode !== 0 || !v8.includes('--max-old-space-size=3072')) {
  throw Error('--node does not honour --max-old-space-size=3072: ' + v8);
}

const fixtures = ['evals/c_target_wide_record', 'evals/c_target_nested_adt',
  'evals/c_target_array_u32', 'evals/c_target_array_wide', 'evals/c_target_multiarm',
  'evals/c_target_char_head', 'evals/c_target_char_to_list', 'evals/c_target_string_from_list',
  'evals/c_target_array_nat', 'evals/c_target_array_nested', 'evals/c_target_drop_fields',
  'evals/c_target_utf8_literal', 'evals/c_target_utf8_astral', 'evals/c_target_trigraph_literal',
  'tests/reg/phys_storage_paths', 'tests/reg/generic_ctor_domains',
  'evals/c_target_bool_prims', 'evals/c_target_clo_field',
  'evals/c_target_repeat_data', 'evals/c_target_disjoint_type_cells', 'evals/c_target_repeat_capture',
  'evals/c_target_alias_paths', 'evals/c_target_branch_arms', 'evals/c_target_region_leave_repeat',
  'evals/c_target_bool_fields', 'evals/c_target_region_tail_capture',
  'evals/c_target_bool_xor', 'evals/c_target_show_data',
  'evals/c_target_user_ctor_show', 'evals/c_target_wide_node',
  'tests/io/args', 'tests/io/args_bytes', 'evals/repro_js_non_tail_reclaim',
  'tests/run/array_fork', 'tests/run/array_atomic_fadd', 'tests/run/array_atomic_edges',
  'tests/run/f32_read_round_once', 'tests/run/f32_read_whitespace',
  'tests/run/f32_pow_unit_base'];
const selected = smokeCase === undefined ? fixtures : fixtures.filter(name => name.endsWith('/' + smokeCase) || name === smokeCase);
if (selected.length === 0) throw Error('--smoke-case matches no fixture: ' + smokeCase);
const base = resolve('bend2/base.bend');
const runtime = resolve('bend2/selfhost/c_runtime.c');
const failures: {fixture: string; stage: string; detail: string}[] = [];

const record = (stem: string, stage: string, suffix: string, bytes: Uint8Array | string): void => {
  writeFileSync(logs + '/' + stem + '.' + stage + '.' + suffix, bytes);
};

async function guarded(stem: string, stage: string, command: string[]): Promise<{exit: number; commandExit: number; stdout: string; stderr: string; status: string; reason: string; reportPhase: string; ownedTreeStopped: boolean | null; supervisorExit: number; gatePath: string}> {
  const outPath = logs + '/' + stem + '.' + stage + '.stdout';
  const errPath = logs + '/' + stem + '.' + stage + '.stderr';
  // exec keeps the monitored child's pid/exit status; redirection preserves the
  // complete raw streams without any pipe or truncation.
  const wrapped = ['/bin/sh', '-c', 'out=$1; err=$2; shift 2; exec "$@" >"$out" 2>"$err"', 'sh', outPath, errPath, ...command];
  const gate = await runHeavyGate(wrapped, {
    label: stem + ':' + stage,
    memoryMiB: 8192,
    rssMiB: 8192,
    pollMs: 10,
    timeoutMs: 600000,
  });
  record(stem, stage, 'exit', String(gate.commandExitCode) + '\n');
  record(stem, stage, 'gate.json', JSON.stringify({...gate, argv: command, stdoutPath: outPath, stderrPath: errPath}, null, 2) + '\n');
  let gatePath = '';
  if (gate.reportPath.length > 0 && existsSync(gate.reportPath)) {
    const copy = logs + '/' + stem + '.' + stage + '.gate.report.json';
    writeFileSync(copy, readFileSync(gate.reportPath));
    gatePath = copy;
  }
  const stdout = existsSync(outPath) ? readFileSync(outPath, 'utf8') : '';
  const stderr = existsSync(errPath) ? readFileSync(errPath, 'utf8') : '';
  return {exit: gate.exitCode, commandExit: gate.commandExitCode, stdout, stderr, status: gate.status, reason: gate.reason, reportPhase: gate.reportPhase, ownedTreeStopped: gate.ownedTreeStopped, supervisorExit: gate.supervisorExitCode, gatePath};
}

for (const name of selected) {
  const source = resolve(name + '.bend');
  if (!existsSync(source)) throw Error(name + ': fixture missing');
  const expected = [...readFileSync(source, 'utf8').matchAll(/^#\|(.+)$/gm)].map(match => match[1]).join('\n');
  if (expected.length === 0) throw Error(name + ': no #| expectation');
  const stem = basename(name);
  const sourceSha = createHash('sha256').update(readFileSync(source)).digest('hex');
  const outFile = logs + '/' + stem + '.' + target;
  const exe = logs + '/' + stem + (target === 'c' ? '' : '.js');
  const command = host === undefined
    ? [driver!, source, '-o', outFile, '--base', base, '--runtime-c', runtime]
    : [node, '--experimental-strip-types', '--max-old-space-size=3072', host,
      '--candidate=' + component!, '--source-tag=' + tag!, '--parser=' + parser!, source, '-o', outFile,
      '--base', base, '--runtime-c', runtime];
  record(stem, 'pins', 'json', JSON.stringify({fixture: source, sourceSha256: sourceSha, expected, target, outFile, parser, parserSha256: parser === undefined ? undefined : createHash('sha256').update(readFileSync(parser)).digest('hex'), tag, component, componentSha256: component === undefined ? undefined : createHash('sha256').update(readFileSync(component)).digest('hex'), host, hostSha256: host === undefined ? undefined : createHash('sha256').update(readFileSync(host)).digest('hex'), node, nodeSha256: existsSync(node) ? createHash('sha256').update(readFileSync(node)).digest('hex') : undefined, nodeVersion, v8}, null, 2) + '\n');
  const emit = await guarded(stem, 'emit', command);
  if (emit.status !== 'PASS' || emit.exit !== 0 || emit.commandExit !== 0 || emit.reportPhase !== 'complete' || emit.ownedTreeStopped !== true) {
    failures.push({fixture: stem, stage: 'emit', detail: 'gate=' + emit.status + ' effective=' + emit.exit + ' command=' + emit.commandExit + ' phase=' + emit.reportPhase + ' stopped=' + String(emit.ownedTreeStopped) + ': ' + emit.reason + '; raw in ' + logs});
    continue;
  }
  if (target === 'c') {
    const cc = await guarded(stem, 'clang', ['clang', '-std=c11', '-O0', '-ferror-limit=0', '-pthread', '-lm', '-o', exe, outFile]);
    if (cc.status !== 'PASS' || cc.exit !== 0 || cc.commandExit !== 0 || cc.reportPhase !== 'complete' || cc.ownedTreeStopped !== true) {
      failures.push({fixture: stem, stage: 'clang', detail: 'gate=' + cc.status + ' effective=' + cc.exit + ' command=' + cc.commandExit + ' phase=' + cc.reportPhase + ' stopped=' + String(cc.ownedTreeStopped) + ': ' + cc.reason + '; raw in ' + logs});
      continue;
    }
  }
  const run = await guarded(stem, 'run', target === 'c' ? [exe] : [node, '--max-old-space-size=3072', exe]);
  if (run.status !== 'PASS' || run.exit !== 0 || run.commandExit !== 0 || run.reportPhase !== 'complete' || run.ownedTreeStopped !== true) {
    failures.push({fixture: stem, stage: 'run', detail: 'gate=' + run.status + ' effective=' + run.exit + ' command=' + run.commandExit + ' phase=' + run.reportPhase + ' stopped=' + String(run.ownedTreeStopped) + ': ' + run.reason + '; raw in ' + logs});
    continue;
  }
  const out = run.stdout.trim();
  if (out !== expected) {
    failures.push({fixture: stem, stage: 'output', detail: 'observed ' + JSON.stringify(out) + ' expected ' + JSON.stringify(expected)});
    continue;
  }
  const artifacts: Record<string, {bytes: number; sha256: string}> = {};
  for (const path of [outFile, exe]) {
    if (existsSync(path)) artifacts[path] = {bytes: readFileSync(path).length, sha256: createHash('sha256').update(readFileSync(path)).digest('hex')};
  }
  record(stem, 'artifact', 'json', JSON.stringify(artifacts, null, 2) + '\n');
  if (!keep) {
    for (const path of [outFile, exe]) {
      try { Bun.spawnSync(['rm', '-f', path]); } catch { /* transient artifact */ }
    }
  }
  console.log(JSON.stringify({fixture: basename(source), target, observed: out}));
}

const sha = (path: string): string => createHash('sha256').update(readFileSync(path)).digest('hex');
const mode = smokeCase === undefined ? 'acceptance-matrix' : 'diagnostic-smoke';
const pins = {
  mode, target, node, nodeVersion, v8, host, component, parser, tag, driver,
  hostSha256: host === undefined ? undefined : createHash('sha256').update(readFileSync(host)).digest('hex'),
  componentSha256: component === undefined ? undefined : createHash('sha256').update(readFileSync(component)).digest('hex'),
  parserSha256: parser === undefined ? undefined : createHash('sha256').update(readFileSync(parser)).digest('hex'),
  guardianTs: resolve('evals/heavy_gate.ts'), guardianTsSha256: sha(resolve('evals/heavy_gate.ts')),
  guardianNativeC: resolve('evals/heavy_gate_native.c'), guardianNativeCSha256: sha(resolve('evals/heavy_gate_native.c')),
  cwd: process.cwd(),
  base, baseSha256: sha(base), runtime, runtimeSha256: sha(runtime), logs,
  gate: {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000},
  fixtures: selected.length, smokeCase,
};
const cleanPins = Object.fromEntries(Object.entries(pins).filter(([, value]) => value !== undefined));
record('matrix', 'pins', 'json', JSON.stringify(cleanPins, null, 2) + '\n');
if (failures.length > 0) {
  for (const failure of failures) console.error(failure.fixture + ': ' + failure.stage + ': ' + failure.detail);
  console.error(JSON.stringify({status: 'FAIL', mode, target, fixtures: selected.length, smokeCase, failures, logDir: logs, nodeVersion, v8}));
  process.exitCode = 1;
} else {
  console.log(JSON.stringify({status: 'PASS', mode, target, fixtures: selected.length, smokeCase, logDir: logs, nodeVersion, v8}));
}
