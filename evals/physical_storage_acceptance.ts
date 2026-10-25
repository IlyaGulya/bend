#!/usr/bin/env bun
/** Changed-path acceptance suite for the physical storage/path module.
 *
 * Every heavyweight child is authenticated by the existing heavy_gate:
 * component build (its Node worker uses --max-old-space-size=3072 and the
 * accepted stack), component host run, harness C emission, clang, and the
 * native execution. Complete stdout/stderr/argv/cwd/gate JSON are kept under
 * a fresh --logs directory. The suite refuses to claim PASS unless every
 * stage reports status PASS, reportPhase complete, ownedTreeStopped true and
 * exit 0.
 *
 *   bun evals/physical_storage_acceptance.ts --logs=<fresh dir>
 */
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {existsSync, mkdirSync, readFileSync, writeFileSync, cpSync} from 'node:fs';
import {basename, dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {runHeavyGate} from './heavy_gate.ts';
import type {HeavyGateResult} from './heavy_gate.ts';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const logsArg = process.argv.find(a => a.startsWith('--logs='))?.slice('--logs='.length);
const receiptArg = process.argv.find(a => a.startsWith('--receipt='))?.slice('--receipt='.length);
if (!logsArg) throw Error('usage: bun evals/physical_storage_acceptance.ts --logs=<fresh dir> [--receipt=<path>]');
const logs = resolve(logsArg);
if (existsSync(logs)) throw Error('refuse to reuse a log directory: ' + logs);
mkdirSync(logs, {recursive: true});
const sha = (path: string) => createHash('sha256').update(readFileSync(path)).digest('hex');
const write = (name: string, text: string | Uint8Array) => writeFileSync(resolve(logs, name), text);
const results: Record<string, unknown>[] = [];
function checkGate(label: string, gate: HeavyGateResult): void {
  if (gate.status !== 'PASS' || gate.reportPhase !== 'complete' || gate.ownedTreeStopped !== true ||
      gate.exitCode !== 0 || gate.commandExitCode !== 0)
    throw Error(`${label}: gate=${gate.status} phase=${gate.reportPhase} stopped=${String(gate.ownedTreeStopped)} effective=${gate.exitCode} command=${gate.commandExitCode}`);
}
async function stage(label: string, argv: string[]): Promise<{gate: HeavyGateResult; stdout: string; stderr: string}> {
  const outPath = resolve(logs, label + '.stdout');
  const errPath = resolve(logs, label + '.stderr');
  const wrapped = ['/bin/sh', '-c', 'out=$1; err=$2; shift 2; exec "$@" >"$out" 2>"$err"', 'sh', outPath, errPath, ...argv];
  const gate = await runHeavyGate(wrapped, {label, memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000});
  write(label + '.gate.json', JSON.stringify({...gate, argv, cwd: root}, null, 2) + '\n');
  write(label + '.argv.json', JSON.stringify({argv, cwd: root}, null, 2) + '\n');
  const stdout = existsSync(outPath) ? readFileSync(outPath, 'utf8') : '';
  const stderr = existsSync(errPath) ? readFileSync(errPath, 'utf8') : '';
  results.push({stage: label, status: gate.status, reportPhase: gate.reportPhase, ownedTreeStopped: gate.ownedTreeStopped, exit: gate.exitCode, commandExit: gate.commandExitCode, argv});
  checkGate(label, gate);
  return {gate, stdout, stderr};
}
// Pins. The providers are the current Main integration inputs.
const physical = resolve(root, 'bend2/selfhost/c_backend_physical.bend');
const clay = resolve(root, 'bend2/selfhost/c_backend_layout.bend');
const nf = resolve(root, 'bend2/selfhost/descriptor_nf.bend');
const pins = {
  physical: sha(physical), clay: sha(clay), descriptorNf: sha(nf),
  harnessTemplate: sha(resolve(root, 'evals/physical_path_smoke_template.c')),
  fixture: sha(resolve(root, 'evals/physical_view_smoke.bend')),
  cFixture: sha(resolve(root, 'evals/physical_path_smoke.bend')),
  heavyGate: sha(resolve(root, 'evals/heavy_gate.ts')),
  heavyGateNative: sha(resolve(root, 'evals/heavy_gate_native.c')),
};
if (pins.clay !== 'a9f2d5d7d101665f390fb88cd6901947773fbf2444fc6b76504f9537213cdc77') throw Error('CLay is not the current Main pin');
if (pins.descriptorNf !== '747dc747fcb1a6b6c1fcbf31a3e164f998fd5fa502f87a8ad3a1facd13859973') throw Error('NF is not the current Main pin');
if (pins.heavyGate !== '204f3529704435455d20a9d5a126a8e9c62e002b6fed9044c8319da8a3c26ff2') throw Error('heavy_gate is not the current Main pin');
if (pins.heavyGateNative !== '1ff233edacdbf13c6ffd4a8bf38cbf153629e8c76be4860deec8a5b591d3fa8b') throw Error('heavy_gate_native is not the current Main pin');
write('pins.json', JSON.stringify(pins, null, 2) + '\n');
// 1. Compose and lower the physical provider chain.
const steps = await stage('steps', ['bun', '--smol', 'evals/physical_view_step_smoke.ts']);
const component = resolve(root, 'checkpoints/physical_view_steps_component_v1.bend');
if (!existsSync(component)) throw Error('steps produced no component');
// 2. The admitted component build, through its own Node worker gate.
const artifact = resolve(logs, 'physical_view_component.js');
const report = resolve(logs, 'component-report');
const buildArgv = ['bun', '--smol', 'evals/checker_core_component_build.ts', '--file=' + component,
  '--exports=expand_modules_start,template_step', '--artifact=' + artifact, '--report=' + report];
const build = spawnSync(buildArgv[0], buildArgv.slice(1), {cwd: root, encoding: 'utf8', maxBuffer: 1 << 28});
write('component.stdout', build.stdout ?? '');
write('component.stderr', build.stderr ?? '');
write('component.argv.json', JSON.stringify({argv: buildArgv, cwd: root}, null, 2) + '\n');
if (build.status !== 0) throw Error('component build failed with ' + String(build.status));
const gateLine = (build.stderr ?? '').split('\n').filter(line => line.startsWith('HEAVY_GATE ')).pop();
if (!gateLine) throw Error('component build produced no HEAVY_GATE record');
const componentGate = JSON.parse(gateLine.slice('HEAVY_GATE '.length));
if (componentGate.status !== 'PASS' || componentGate.reportPhase !== 'complete' || componentGate.ownedTreeStopped !== true ||
    componentGate.exitCode !== 0 || componentGate.commandExitCode !== 0)
  throw Error('component build gate did not complete: ' + gateLine);
write('component.gate.json', JSON.stringify(componentGate, null, 2) + '\n');
results.push({stage: 'component', ...componentGate});
// 3. Drive the admitted component to read the fixture result.
const host = await stage('host', ['bun', '--smol', 'evals/physical_view_step_smoke.ts', '--run=' + artifact]);
const hostResult = JSON.parse(host.stdout.trim());
if (hostResult.status !== 'PASS' || typeof hostResult.text !== 'string') throw Error('host run did not return PASS text');
write('host.result.json', JSON.stringify(hostResult, null, 2) + '\n');
// 4. Generate the foreign C input from the admitted component expressions.
const blocks: string[] = [];
let at = 0;
for (;;) {
  const start = hostResult.text.indexOf('({\n', at);
  if (start < 0) break;
  let depth = 0, i = start, quote = '', escaped = false;
  for (; i < hostResult.text.length; i += 1) {
    const c = hostResult.text[i]!;
    if (quote !== '') {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = '';
    } else if (c === '"' || c === "'") quote = c;
    else if (c === '{') depth += 1;
    else if (c === '}') {
      depth -= 1;
      if (depth === 0) { i += 1; if (hostResult.text[i] === ')') i += 1; break; }
    }
  }
  blocks.push(hostResult.text.slice(start, i));
  at = i;
}
write('host.expressions.json', JSON.stringify(blocks, null, 2) + '\n');
if (!hostResult.text.endsWith('F')) throw Error('erased-ordinal result kind was not the expected failure kind');
const template = readFileSync(resolve(root, 'evals/physical_path_smoke_template.c'), 'utf8');
const holePattern = /\/\*@@r(\d+)@@\*\//g;
const holes = [...template.matchAll(holePattern)].map(match => Number(match[1]));
if (new Set(holes).size !== holes.length) throw Error('duplicate expression hole');
if (holes.length !== blocks.length) throw Error('template holes and emitted expressions disagree');
let probe = template;
for (let i = 0; i < holes.length; i += 1) {
  const marker = `/*@@r${i}@@*/`;
  if (!probe.includes(marker)) throw Error('missing expression hole ' + i);
  probe = probe.replace(marker, blocks[i]!);
}
if (/@@r\d+@@/.test(probe)) throw Error('unfilled expression hole');
const probePath = resolve(logs, 'physical_path_probe.c');
write('physical_path_probe.c', probe);
const fixtureCopy = resolve(logs, 'physical_path_smoke.bend');
cpSync(resolve(root, 'evals/physical_path_smoke.bend'), fixtureCopy);
// 5. Emit the C through the real Node compilePhases API, under the guard.
const cPath = resolve(logs, 'physical_path_smoke.c');
const node = '/Users/ilyagulya/Library/pnpm/nodejs/23.11.0/bin/node';
await stage('harness-emit', [node, '--experimental-transform-types', '--max-old-space-size=3072',
  '--stack-size=262144', 'evals/physical_storage_emit.ts', fixtureCopy, cPath]);
// 6. Compile it, under the guard.
const exe = resolve(logs, 'physical_path_smoke');
await stage('clang', ['clang', '-std=c11', '-O0', '-g', '-o', exe, cPath, '-lpthread', '-lm']);
// 7. Execute it, under the guard.
const run = await stage('run', [exe]);
const observed = run.stdout.trim();
if (observed !== 'ok') throw Error('C run observed ' + JSON.stringify(observed) + ', expected "ok"');
write('result.json', JSON.stringify({status: 'PASS', pins, expressions: blocks.length, observed, stages: results}, null, 2) + '\n');
if (receiptArg) {
  const receiptPath = resolve(receiptArg);
  const stageReceipts: Record<string, unknown> = {};
  for (const label of ['steps', 'host', 'harness-emit', 'clang', 'run']) {
    const gatePath = resolve(logs, label + '.gate.json');
    if (existsSync(gatePath)) stageReceipts[label] = JSON.parse(readFileSync(gatePath, 'utf8'));
  }
  stageReceipts['component'] = componentGate;
  const artifacts = Object.fromEntries([artifact, cPath, exe, probePath].map(path => [basename(path), {bytes: readFileSync(path).length, sha256: sha(path)}]));
  writeFileSync(receiptPath, JSON.stringify({
    schemaVersion: 1, status: 'PASS', acceptance: 'guarded physical storage slice; not a Root GO',
    worktree: root, logs, commitSourceHashes: pins, runtime: {node, nodeVersion: 'v23.11.0', componentWorker: {heapLimitMiB: 3072, stackSizeMb: 256}},
    caps: {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000},
    stages: stageReceipts, artifacts, expressions: blocks.length, terminal: {observed, erasedOrdinalKind: hostResult.text.slice(-1)},
    command: process.argv.slice(0), cwd: root, note: '19207e04 runtime evidence is REJECTED_UNGUARDED and is not part of this receipt.'
  }, null, 2) + '\n');
}
console.log(JSON.stringify({status: 'PASS', logs, pins, expressions: blocks.length, observed}));
