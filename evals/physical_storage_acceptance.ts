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
if (!logsArg) throw Error('usage: bun evals/physical_storage_acceptance.ts --logs=<fresh dir>');
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
  harness: sha(resolve(root, 'evals/physical_path_smoke.c')),
  fixture: sha(resolve(root, 'evals/physical_view_smoke.bend')),
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
// 4. The C harness must embed every expression the admitted component emitted.
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
      if (depth === 0) {
        i += 1;
        if (hostResult.text[i] === ')') i += 1;
        break;
      }
    }
  }
  blocks.push(hostResult.text.slice(start, i));
  at = i;
}
write('host.expressions.json', JSON.stringify(blocks, null, 2) + '\n');
const harness = readFileSync(resolve(root, 'evals/physical_path_smoke.c'), 'utf8');
if (blocks.length !== 34) throw Error('expected 33 emitted statement expressions, got ' + blocks.length);
for (const block of blocks) if (!harness.includes(block)) throw Error('C harness is missing a component-emitted expression');
if (!hostResult.text.includes('FAIL a packed projection names an erased field')) throw Error('erased ordinal did not fail loudly');
if (!harness.includes('Term r25 = blk_node(e, leafv, leafw);')) throw Error('C harness lost the array_node expression');
// 5. Emit the C with the fixture compiler, under the guard.
const cPath = resolve(logs, 'physical_path_smoke.c');
await stage('harness-emit', ['bun', '--smol', 'bend2/main.ts', 'evals/physical_path_smoke.bend', '-o', cPath]);
// 6. Compile it, under the guard.
const exe = resolve(logs, 'physical_path_smoke');
await stage('clang', ['clang', '-std=c11', '-O0', '-g', '-o', exe, cPath, '-lpthread', '-lm']);
// 7. Execute it, under the guard.
const run = await stage('run', [exe]);
const observed = run.stdout.trim();
if (observed !== 'ok') throw Error('C run observed ' + JSON.stringify(observed) + ', expected "ok"');
write('result.json', JSON.stringify({status: 'PASS', pins, blocks: blocks.length, observed, stages: results}, null, 2) + '\n');
console.log(JSON.stringify({status: 'PASS', logs, pins, blocks: blocks.length, observed}));
