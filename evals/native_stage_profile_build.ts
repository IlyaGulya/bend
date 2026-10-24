#!/usr/bin/env bun
// Build and run the bounded diagnostic native chunk-profile component.
//
// This compiles only evals/native_stage_profile_driver.bend (the generated
// Template/Checker/Emitter Run machines plus the profile-only views), not the
// full compiler root, and runs finite seeded Runs under a tool deadline. It is
// diagnostic only: the output is operational chunk attribution, not acceptance,
// benchmark, source-substage or source-call evidence.
//
// The code generator runs in a worker with the canonical 256 MiB stack and a
// 3072 MiB old-generation cap, matching the native build's limits without
// raising either. If that bound is insufficient the worker fails and this tool
// reports the failure instead of claiming a profile.
//
// usage: bun evals/native_stage_profile_build.ts [--artifact-dir=DIR]
//
// The whole load/validation/compile_book/clang/run build runs under the existing
// heavy_gate supervisor (8 GiB memory/RSS, 10 ms sampling, 600 s hard deadline)
// via guardHeavyGate, which re-execs and authenticates the inherited lease.
// Clang and the emitted fixture run additionally get fixed internal 300 s/120 s
// child deadlines. There is no caller-supplied whole-build timeout and no
// --internal bypass mode.
import {createHash} from 'node:crypto';
import {execFileSync, spawnSync} from 'node:child_process';
import {existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {tmpdir} from 'node:os';
import {fileURLToPath} from 'node:url';
import {isMainThread, parentPort, Worker, workerData} from 'node:worker_threads';
import {nativeTraceObservations} from './compiler_stage_profile.mjs';
import {guardHeavyGate} from './heavy_gate.ts';
import type * as Bend from '../bend2/bend.ts';
import type * as Compiler from '../bend2/comp.ts';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
type Options = {artifactDir?: string};
const clangTimeoutMs = 300000, runTimeoutMs = 120000;

function options(): Options {
  const values = new Map();
  for (const argument of process.argv.slice(2)) {
    const at = argument.indexOf('=');
    const name = at < 0 ? argument : argument.slice(0, at), value = at < 0 ? undefined : argument.slice(at + 1);
    if (!['--artifact-dir'].includes(name) || value === undefined || values.has(name))
      throw Error('expected unique --artifact-dir=DIR, observed ' + argument);
    values.set(name, value);
  }
  return {artifactDir: values.has('--artifact-dir') ? resolve(values.get('--artifact-dir')) : undefined};
}

function labels(o: Options) {
  const emitterManifestPath = join(root, 'checkpoints/emitter-steps-v1.json');
  const emitterManifest = JSON.parse(readFileSync(emitterManifestPath, 'utf8'));
  const requestGroups = emitterManifest.requestGroups;
  if (!Array.isArray(requestGroups) || requestGroups.length !== 27)
    throw Error('Emitter manifest no longer has 27 request groups; update the diagnostic group view before profiling');
  const emitGroups = requestGroups.flatMap((group, index) =>
    group.definitions?.includes('cps_provider_2_emit') ? [index] : []);
  if (emitGroups.length !== 1)
    throw Error('Emitter manifest must place cps_provider_2_emit in exactly one request group, observed ' + JSON.stringify(emitGroups));
  const emitGroup = emitGroups[0];
  const sourceOf = new Map<string, string>();
  for (const declaration of emitterManifest.canonicalComposition?.declarations ?? [])
    if (declaration?.kind === 'def') {
      if (typeof declaration.name === 'string') sourceOf.set(declaration.name, declaration.source);
      if (typeof declaration.canonicalName === 'string') sourceOf.set(declaration.canonicalName, declaration.source);
    }
  const moduleLabel = new Map([
    ['backend_lower.bend', 'backend-lowering'], ['lower_catalog.bend', 'catalog'],
    ['descriptor_nf.bend', 'descriptor-nf'], ['c_backend_layout.bend', 'layouts'],
    ['c_backend_sharing.bend', 'sharing'], ['c_backend_link.bend', 'link-planning'],
    ['c_backend.bend', 'render-c'], ['c_backend_physical.bend', 'render-c'],
    ['c_emit.bend', 'render-c'], ['c_emit_core.bend', 'render-c'],
    ['js_backend.bend', 'render-js'], ['js_emit.bend', 'render-js'],
    ['emitter.bend', 'emitter-entry'],
  ]);
  const groupLabels = requestGroups.map((group, index) => {
    const sources = [...new Set((group.definitions ?? []).map(name => sourceOf.get(name)).filter(Boolean))];
    const names = [...new Set(sources.map(source => moduleLabel.get(source.split('/').at(-1)) ?? 'module:' + source))].sort();
    if (sources.length === 0) return {index, label: 'unknown', sources: []};
    return {index, label: names.length === 1 ? names[0] : 'mixed:' + names.join('+'), sources: sources.sort()};
  });
  const emitLabel = groupLabels[emitGroup];
  if (!emitLabel.label.split('+').includes('render-c') || !emitLabel.sources.includes('bend2/selfhost/c_backend.bend'))
    throw Error('Emitter cps_provider_2_emit group no longer contains the c_backend render-c request: ' + JSON.stringify(emitLabel));
  const requiredOutput = emitterManifest.generationConfig?.output;
  const expectedOutputSha256 = requiredOutput === undefined ? undefined : emitterManifest.outputs?.[requiredOutput];
  if (requiredOutput === undefined || expectedOutputSha256 === undefined)
    throw Error('Emitter manifest has no generated output pin for the loaded engine');
  const actualOutputSha256 = sha(readFileSync(join(root, requiredOutput)));
  if (actualOutputSha256 !== expectedOutputSha256)
    throw Error('Emitter generated output pin differs from the file loaded by the builder: ' + requiredOutput);
  return {emitterManifestPath, emitterManifest, groupLabels, emitGroup,
    artifactBinding: {status: 'verified-by-builder', requiredOutput,
      expectedOutputSha256, actualOutputSha256}};
}

async function build(o: Options) {
  const directory = o.artifactDir ?? mkdtempSync(join(tmpdir(), 'bend-native-stage-profile-'));
  mkdirSync(directory, {recursive: true});
  const kernelPath = join(root, 'bend2/bend.ts'), compilerPath = join(root, 'bend2/comp.ts');
  const driverPath = join(root, 'evals/native_stage_profile_driver.bend');
  const hostPath = join(root, 'evals/native_stage_profile_host.c');
  const {emitterManifestPath, emitterManifest, groupLabels, emitGroup, artifactBinding} = labels(o);
  const K = await import(kernelPath) as typeof Bend;
  const C = await import(compilerPath) as typeof Compiler;
  const started = performance.now();
  const book = K.book_nil();
  await K.book_load(book, driverPath, '', new Map());
  K.book_valid(book);
  const validationMs = performance.now() - started;
  const codegenStart = performance.now();
  const c = C.compile_book(book);
  const codegenMs = performance.now() - codegenStart;
  const cPath = join(directory, 'native-stage-profile.c');
  const artifact = join(directory, 'native-stage-profile');
  if (existsSync(cPath) || existsSync(artifact)) throw Error('artifact directory already holds a previous component: ' + directory);
  writeFileSync(cPath, c, {flag: 'wx'});
  const cc = process.env.CC ?? 'clang';
  const flags = ['-std=c11', '-O0', '-pthread', cPath, '-lpthread', '-lm', '-o', artifact];
  execFileSync(cc, flags, {stdio: 'inherit', timeout: clangTimeoutMs});
  const run = spawnSync(artifact, [], {encoding: 'utf8', timeout: runTimeoutMs});
  if (run.error) throw run.error;
  if (run.status !== 0) throw Error('native stage profile exited ' + String(run.status) + ': ' + (run.stderr ?? ''));
  const observations = nativeTraceObservations(run.stderr ?? '');
  const phases = observations.filter(row => row.kind === 'native-chunk-profile');
  if (phases.length === 0) throw Error('native stage profile emitted no NATIVE_CHUNK_PROFILE rows: ' + (run.stderr ?? ''));
  if (phases.some(row => row.values.chunkAdvances === 0))
    throw Error('native stage profile observed no chunk transitions; the fixture is not exercising the Run machine');
  const emitterPhase = phases.find(row => row.name === 'emitter-chunks');
  const observedEmitterGroups = Object.keys(emitterPhase?.values.requestGroups ?? {}).map(Number);
  if (!observedEmitterGroups.includes(emitGroup))
    throw Error('native emitter fixture did not exercise the manifest emit group ' + emitGroup + '; observed ' + JSON.stringify(observedEmitterGroups));
  return {
    diagnosticOnly: true, acceptanceEvidence: false,
    directory, driverPath, driverSha256: sha(readFileSync(driverPath)), hostPath, hostSha256: sha(readFileSync(hostPath)),
    kernelPath, kernelSha256: sha(readFileSync(kernelPath)), compilerPath, compilerSha256: sha(readFileSync(compilerPath)),
    emitterManifestPath, emitterManifestSha256: sha(readFileSync(emitterManifestPath)), groupLabels,
    artifactBinding,
    fixtureRequest: {group: emitGroup, canonicalName: 'cps_provider_2_emit', label: groupLabels[emitGroup].label},
    cPath, cSha256: sha(c), artifact, artifactSha256: sha(readFileSync(artifact)),
    buildCommand: [cc, ...flags], validationMs, codegenMs, totalMs: performance.now() - started,
    runtime: {node: process.versions.node, v8: process.versions.v8, platform: process.platform, arch: process.arch,
      workerLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072}},
    phases: phases.map(row => ({name: row.name, values: row.values, unitsByField: row.unitsByField, details: row.details})),
    note: 'profile-only native driver over the real generated Template/Checker/Emitter Run machines; the Emitter fixture invokes the canonical c_backend.emit request on a well-formed empty BIR.Program and a minimal runtime, requires a non-empty EmitSuccess C result, and classifies only its outer request group; this is not a compiler workload, a source-substage span or a source-call CPU claim',
  };
}

if (isMainThread) {
  process.env.HEAVY_GATE_MEMORY_MIB = '8192';
  process.env.HEAVY_GATE_RSS_MIB = '8192';
  process.env.HEAVY_GATE_POLL_MS = '10';
  process.env.HEAVY_GATE_TIMEOUT_MS = '600000';
  // Existing guard: re-execs with the authenticated lease and the fixed policy.
  await guardHeavyGate(fileURLToPath(import.meta.url), {label: 'Bounded native stage profile build'});
  const o = options();
  const worker = new Worker(new URL(import.meta.url), {
    workerData: o,
    resourceLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072},
  });
  worker.once('message', result => {console.log(JSON.stringify(result));});
  worker.once('error', error => {console.error('native stage profile worker failed: ' + String(error)); process.exitCode = 1;});
  worker.once('exit', code => {if (code !== 0) process.exitCode = code;});
} else {
  try {
    parentPort!.postMessage(await build(workerData as Options));
  } catch (error) {
    console.error('native stage profile build failed: ' + String(error instanceof Error ? error.stack ?? error.message : error));
    process.exitCode = 1;
  }
}
