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
// usage: node --experimental-strip-types evals/native_stage_profile_build.ts
//   [--artifact-dir=DIR]
//
// Node/V8 is required: Worker resourceLimits (256 MiB stack, 3072 MiB old
// generation) must be enforced. Bun/JSC fails fast before the guard because it
// does not enforce those limits.
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
type Options = {artifactDir?: string; canonicalBir?: string; canonicalSources?: string; canonicalRuntime?: string; canonicalChecked?: string; canonicalComponent?: string; profileDir?: string};
const clangTimeoutMs = 300000, runTimeoutMs = 120000;

function options(): Options {
  const values = new Map();
  for (const argument of process.argv.slice(2)) {
    const at = argument.indexOf('=');
    const name = at < 0 ? argument : argument.slice(0, at), value = at < 0 ? undefined : argument.slice(at + 1);
    if (!['--artifact-dir', '--canonical-bir', '--canonical-sources', '--canonical-runtime', '--canonical-checked', '--canonical-component', '--profile-dir'].includes(name) || value === undefined || values.has(name))
      throw Error('expected unique --artifact-dir=DIR or canonical transport paths, observed ' + argument);
    values.set(name, value);
  }
  return {
    artifactDir: values.has('--artifact-dir') ? resolve(values.get('--artifact-dir')) : undefined,
    canonicalBir: values.has('--canonical-bir') ? resolve(values.get('--canonical-bir')) : undefined,
    canonicalSources: values.has('--canonical-sources') ? resolve(values.get('--canonical-sources')) : undefined,
    canonicalRuntime: values.has('--canonical-runtime') ? resolve(values.get('--canonical-runtime')) : undefined,
    canonicalChecked: values.has('--canonical-checked') ? resolve(values.get('--canonical-checked')) : undefined,
    canonicalComponent: values.has('--canonical-component') ? resolve(values.get('--canonical-component')) : undefined,
    profileDir: values.has('--profile-dir') ? resolve(values.get('--profile-dir')) : undefined,
  };
}

function labels(o: Options) {
  const emitterManifestPath = join(root, 'checkpoints/emitter-steps-v1.json');
  const emitterManifest = JSON.parse(readFileSync(emitterManifestPath, 'utf8'));
  const requestGroups = emitterManifest.requestGroups;
  if (!Array.isArray(requestGroups) || requestGroups.length === 0)
    throw Error('Emitter manifest has no request groups; the diagnostic group view needs a composed engine');
  // The C render request is located by canonical source identity, never by a
  // generated helper name or a group count: the manifest records which
  // canonical declaration each composed definition came from, and
  // canonicalComposition.inputs pins that source's bytes. Adding canonical
  // emitter entries therefore changes the group layout without invalidating
  // this view.
  const renderDeclarations = (emitterManifest.canonicalComposition?.declarations ?? []).filter(
    (declaration: any) => declaration?.kind === 'def' &&
      declaration.source === 'bend2/selfhost/c_emit_core.bend' && declaration.canonicalName === 'render');
  if (renderDeclarations.length !== 1)
    throw Error('Emitter manifest must record exactly one canonical c_emit_core render declaration, observed '
      + JSON.stringify(renderDeclarations.map((declaration: any) => declaration.name)));
  const renderRequest = renderDeclarations[0].name;
  if (typeof renderRequest !== 'string') throw Error('Emitter manifest render declaration has no composed definition name');
  const pinnedRenderSource = emitterManifest.canonicalComposition?.inputs?.['bend2/selfhost/c_emit_core.bend'];
  if (typeof pinnedRenderSource !== 'string' || !/^[0-9a-f]{64}$/.test(pinnedRenderSource))
    throw Error('Emitter manifest does not pin the canonical c_emit_core source bytes');
  const emitGroups = requestGroups.flatMap((group: any, index: number) =>
    group.definitions?.includes(renderRequest) ? [index] : []);
  if (emitGroups.length !== 1)
    throw Error('Emitter manifest must place the canonical c_emit_core render declaration in exactly one request group, observed ' + JSON.stringify(emitGroups));
  const emitGroup = emitGroups[0];
  // The typed diagnostic driver names the generated request, envelope and
  // result once. Those names are the manifest's own coverage identity, so the
  // driver is authenticated against them instead of being trusted: a stale
  // driver is reported with the values the engine actually produced.
  const renderRow = (emitterManifest.coverage ?? []).find((row: any) => row?.name === renderRequest);
  if (renderRow === undefined || typeof renderRow.request !== 'string'
      || typeof renderRow.requestEnvelope !== 'string' || typeof renderRow.result !== 'string')
    throw Error('Emitter manifest coverage has no request/envelope/result row for ' + renderRequest);
  const driverPath = join(root, 'evals/native_stage_profile_driver.bend');
  const driverSource = readFileSync(driverPath, 'utf8');
  const driverNames: [string, string][] = [
    ['Emit.' + renderRow.request + '{', 'request constructor'],
    ['Emit.' + renderRow.requestEnvelope + '{', 'fixture envelope'],
    ['Emit.' + renderRow.result, 'result type'],
  ];
  for (const [needle, what] of driverNames)
    if (!driverSource.includes(needle))
      throw Error(driverPath + ' does not name the manifest-derived ' + what + ' ' + needle + '; the typed diagnostic driver is stale for this engine');
  const envelopeIndices = requestGroups.map((_: any, index: number) => index);
  const coveredIndices = [...new Set([...driverSource.matchAll(/EmitterRequestGroup_(\d+)/g)].map(match => Number(match[1])))].sort((a, b) => a - b);
  if (JSON.stringify(coveredIndices) !== JSON.stringify(envelopeIndices))
    throw Error('Typed diagnostic driver covers request groups ' + JSON.stringify(coveredIndices)
      + ' but the engine has ' + JSON.stringify(envelopeIndices) + '; regenerate the group view, never repin a count');
  const driverBinding = {
    path: driverPath, sha256: sha(readFileSync(driverPath)),
    request: renderRow.request, envelope: renderRow.requestEnvelope, result: renderRow.result,
    groups: coveredIndices.length,
    basis: 'manifest coverage row joined to canonicalComposition declaration for c_emit_core.render',
  };
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
    ['c_emit_core.bend', 'render-c'],
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
  if (!emitLabel.label.split('+').includes('render-c') || !emitLabel.sources.includes('bend2/selfhost/c_emit_core.bend'))
    throw Error('Emitter canonical c_emit_core render group no longer contains the c_backend render-c request: ' + JSON.stringify(emitLabel));
  const requiredOutput = emitterManifest.generationConfig?.output;
  const expectedOutputSha256 = requiredOutput === undefined ? undefined : emitterManifest.outputs?.[requiredOutput];
  if (requiredOutput === undefined || expectedOutputSha256 === undefined)
    throw Error('Emitter manifest has no generated output pin for the loaded engine');
  const actualOutputSha256 = sha(readFileSync(join(root, requiredOutput)));
  if (actualOutputSha256 !== expectedOutputSha256)
    throw Error('Emitter generated output pin differs from the file loaded by the builder: ' + requiredOutput);
  return {emitterManifestPath, emitterManifest, groupLabels, emitGroup, renderRequest, renderSourceSha256: pinnedRenderSource, driverBinding,
    artifactBinding: {status: 'verified-by-builder', requiredOutput,
      expectedOutputSha256, actualOutputSha256}};
}

let workerProfile: any;
function inputHash(path: string | undefined) {
  return path && existsSync(path) ? sha(readFileSync(path)) : null;
}
function profileExecution(o: Options) {
  const sourcePath = join(root, 'evals/native_stage_profile_emit_source.bend');
  const kernelPath = join(root, 'bend2/bend.ts');
  const compilerPath = join(root, 'bend2/comp.ts');
  const driverPath = join(root, 'evals/native_stage_profile_driver.bend');
  const hostPath = join(root, 'evals/native_stage_profile_host.c');
  const manifestPath = join(root, 'checkpoints/emitter-steps-v1.json');
  return {
    stage: 'native-diagnostic', mode: 'canonical-transport',
    sourcePath, sourceSha256: inputHash(sourcePath),
    kernelPath, kernelSha256: inputHash(kernelPath),
    compilerPath, compilerSha256: inputHash(compilerPath),
    driverPath, driverSha256: inputHash(driverPath),
    hostPath, hostSha256: inputHash(hostPath),
    manifestPath, manifestSha256: inputHash(manifestPath),
    canonicalBirPath: o.canonicalBir ?? null, canonicalBirSha256: inputHash(o.canonicalBir),
    canonicalSourcesPath: o.canonicalSources ?? null, canonicalSourcesSha256: inputHash(o.canonicalSources),
    canonicalRuntimePath: o.canonicalRuntime ?? null, canonicalRuntimeSha256: inputHash(o.canonicalRuntime),
    canonicalCheckedPath: o.canonicalChecked ?? null, canonicalCheckedSha256: inputHash(o.canonicalChecked),
    canonicalComponentPath: o.canonicalComponent ?? null, canonicalComponentSha256: inputHash(o.canonicalComponent),
    artifactDir: o.artifactDir ?? null,
    runtime: {name: process.release.name, node: process.versions.node, v8: process.versions.v8,
      execPath: process.execPath, execArgv: [...process.execArgv], workerLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072}},
    command: [process.execPath, ...process.execArgv, ...process.argv.slice(1)],
    scope: 'native diagnostic builder; worker 3072/256; no compiler-root/HOST/FP/C-execution claim',
  };
}
export async function compilePhases(profile: any, driverPath: string) {
  const kernelPath = join(root, 'bend2/bend.ts'), compilerPath = join(root, 'bend2/comp.ts');
  const importSpan = profile?.begin('module-import', {kernelPath, compilerPath});
  const K = await import(kernelPath) as typeof Bend;
  const C = await import(compilerPath) as typeof Compiler;
  if (importSpan) profile.end(importSpan, 'completed', {});
  const started = performance.now();
  const book = K.book_nil();
  const loadSpan = profile?.begin('book_load', {driverPath});
  await K.book_load(book, driverPath, '', new Map());
  if (loadSpan) profile.end(loadSpan, 'completed', {});
  const validSpan = profile?.begin('book_valid', {driverPath});
  K.book_valid(book);
  if (validSpan) profile.end(validSpan, 'completed', {});
  const validationMs = performance.now() - started;
  const codegenStart = performance.now();
  const compileSpan = profile?.begin('compile_book', {driverPath});
  let c: string;
  if (profile) {
    const {createCompileBookObserver} = await import('./compiler_profile.mjs');
    const observer = createCompileBookObserver(profile);
    c = C.compile_book(book, {observe: observer.observe});
  } else {
    c = C.compile_book(book);
  }
  if (compileSpan) profile.end(compileSpan, 'completed', {outputBytes: Buffer.byteLength(c)});
  const codegenMs = performance.now() - codegenStart;
  return {c, validationMs, codegenMs};
}
function recordWorkerFailure(runDirectory: string, error: unknown, status: 'interrupted' | 'failed', allowExistingSummary = false) {
  if (!allowExistingSummary && existsSync(join(runDirectory, 'summary.json'))) return false;
  writeFileSync(join(runDirectory, 'worker-failure.json'), JSON.stringify({schemaVersion: 1,
    kind: 'compiler-profile-worker-failure', diagnosticOnly: true, status,
    reason: status === 'interrupted' ? 'worker terminated before the collector could finish' : 'worker failed before finish',
    error: error instanceof Error ? error.message : String(error),
    profileRunDirectory: runDirectory, checkpointPath: join(runDirectory, 'checkpoint.json'),
    reportPath: join(runDirectory, 'summary.json'), observedAt: new Date().toISOString()}, null, 2) + '\n', {flag: 'wx'});
  return true;
}
export function superviseProfileWorker(worker: Worker) {
  let profileRunDirectory: string | undefined;
  let terminalMessage = false;
  let receiptWritten = false;
  const writeInterrupted = (error: unknown) => {
    if (!profileRunDirectory || terminalMessage || receiptWritten) return;
    try { receiptWritten = recordWorkerFailure(profileRunDirectory, error, 'interrupted'); }
    catch (receiptError) { console.error('worker failure receipt failed: ' + String(receiptError)); }
  };
  return new Promise<void>(resolve => {
    let settled = false;
    const settle = () => { if (!settled) { settled = true; resolve(); } };
    worker.on('message', message => {
      if (message?.type === 'profile-ready') { profileRunDirectory = message.runDirectory; return; }
      terminalMessage = true;
      console.log(JSON.stringify(message));
    });
    worker.once('error', error => {
      writeInterrupted(error);
      console.error('native stage profile worker failed: ' + String(error));
      process.exitCode = 1;
      settle();
    });
    worker.once('exit', code => {
      if (!terminalMessage) {
        const status = code === 0 ? 'failed' : 'interrupted';
        const reason = 'worker exited ' + String(code) + ' without a terminal result';
        console.error('native stage profile ' + reason);
        process.exitCode = code === 0 ? 1 : code;
        if (profileRunDirectory && !receiptWritten) {
          try { receiptWritten = recordWorkerFailure(profileRunDirectory, reason, status, code === 0); }
          catch (receiptError) { console.error('worker failure receipt failed: ' + String(receiptError)); }
        }
      } else if (code !== 0) {
        process.exitCode = code;
      }
      settle();
    });
  });
}
async function build(o: Options) {
  const buildStarted = performance.now();
  const directory = o.artifactDir ?? mkdtempSync(join(tmpdir(), 'bend-native-stage-profile-'));
  mkdirSync(directory, {recursive: true});
  let profile: any;
  if (o.profileDir) {
    const {createCompilerProfile} = await import('./compiler_profile.mjs');
    profile = await createCompilerProfile({directory: o.profileDir, execution: profileExecution(o)});
    workerProfile = profile;
    parentPort?.postMessage({type: 'profile-ready', runDirectory: profile.runDirectory, reportPath: profile.reportPath});
  }
  if (!o.canonicalBir || !o.canonicalSources || !o.canonicalRuntime)
    throw Error('diagnostic transport requires --canonical-bir=FILE --canonical-sources=FILE --canonical-runtime=FILE');
  const generatedFixture = join(root, 'checkpoints/native_stage_profile_generated_fixture.bend');
  const transportArgs = [join(root, 'evals/native_stage_profile_fixture_transport.mjs'),
    o.canonicalBir, o.canonicalSources, o.canonicalRuntime, generatedFixture,
    '--source=' + join(root, 'evals/native_stage_profile_emit_source.bend')];
  if (o.canonicalChecked) transportArgs.push('--checked=' + o.canonicalChecked);
  if (o.canonicalComponent) transportArgs.push('--component=' + o.canonicalComponent);
  execFileSync(process.execPath, transportArgs, {stdio: 'inherit'});
  if (profile) profile.record({kind: 'input-hash', scope: 'generated canonical transport', name: 'generated-fixture',
    details: {path: generatedFixture, sha256: sha(readFileSync(generatedFixture))}});
  const kernelPath = join(root, 'bend2/bend.ts'), compilerPath = join(root, 'bend2/comp.ts');
  const driverPath = join(root, 'evals/native_stage_profile_driver.bend');
  const hostPath = join(root, 'evals/native_stage_profile_host.c');
  const {emitterManifestPath, emitterManifest, groupLabels, emitGroup, renderRequest, renderSourceSha256, driverBinding, artifactBinding} = labels(o);
  const {c, validationMs, codegenMs} = await compilePhases(profile, driverPath);
  const cPath = join(directory, 'native-stage-profile.c');
  const artifact = join(directory, 'native-stage-profile');
  if (existsSync(cPath) || existsSync(artifact)) throw Error('artifact directory already holds a previous component: ' + directory);
  writeFileSync(cPath, c, {flag: 'wx'});
  const cc = process.env.CC ?? 'clang';
  const flags = ['-std=c11', '-O0', '-pthread', cPath, '-lpthread', '-lm', '-o', artifact];
  execFileSync(cc, flags, {stdio: 'inherit', timeout: clangTimeoutMs});
  const run = spawnSync(artifact, [], {encoding: 'utf8', timeout: runTimeoutMs});
  const stdoutPath = join(directory, 'native-stage-profile.stdout.log');
  const stderrPath = join(directory, 'native-stage-profile.stderr.log');
  const stdout = run.stdout ?? '', stderr = run.stderr ?? '';
  writeFileSync(stdoutPath, stdout, {flag: 'wx'});
  writeFileSync(stderrPath, stderr, {flag: 'wx'});
  const nativeExecution = {exitStatus: run.status, signal: run.signal,
    error: run.error ? String(run.error) : null,
    stdout: {path: stdoutPath, bytes: Buffer.byteLength(stdout), sha256: sha(stdout)},
    stderr: {path: stderrPath, bytes: Buffer.byteLength(stderr), sha256: sha(stderr)}};
  if (run.error) throw Error('native stage profile spawn failed: ' + String(run.error) + '; raw stdout=' + stdoutPath + ' stderr=' + stderrPath);
  if (run.status !== 0) throw Error('native stage profile exited ' + String(run.status) + '; raw stdout=' + stdoutPath + ' stderr=' + stderrPath);
  const observations = nativeTraceObservations(stderr);
  const phases = observations.filter(row => row.kind === 'native-chunk-profile');
  if (phases.length === 0) throw Error('native stage profile emitted no NATIVE_CHUNK_PROFILE rows; raw stdout=' + stdoutPath + ' stderr=' + stderrPath);
  if (phases.some(row => row.values.chunkAdvances === 0))
    throw Error('native stage profile observed no chunk transitions; the fixture is not exercising the Run machine');
  const emitterPhase = phases.find(row => row.name === 'emitter-chunks');
  const observedEmitterGroups = Object.keys(emitterPhase?.values.requestGroups ?? {}).map(Number);
  const engineGroups = emitterManifest.requestGroups.length;
  if (observedEmitterGroups.some(index => index < 0 || index >= engineGroups))
    throw Error('native emitter fixture observed request groups outside the manifest engine: '
      + JSON.stringify(observedEmitterGroups) + ' with ' + engineGroups + ' groups');
  if (!observedEmitterGroups.includes(emitGroup))
    throw Error('native emitter fixture did not exercise the manifest emit group ' + emitGroup + '; observed ' + JSON.stringify(observedEmitterGroups));
  const profileSummary = profile?.finish('completed');
  workerProfile = undefined;
  return {
    diagnosticOnly: true, acceptanceEvidence: false,
    profile: profile ? {runDirectory: profile.runDirectory, reportPath: profile.reportPath, status: profileSummary?.status} : null,
    directory, driverPath, driverSha256: sha(readFileSync(driverPath)), hostPath, hostSha256: sha(readFileSync(hostPath)),
    kernelPath, kernelSha256: sha(readFileSync(kernelPath)), compilerPath, compilerSha256: sha(readFileSync(compilerPath)),
    emitterManifestPath, emitterManifestSha256: sha(readFileSync(emitterManifestPath)), groupLabels,
    canonicalTransport: {bir: {path: o.canonicalBir, sha256: sha(readFileSync(o.canonicalBir))},
      sources: {path: o.canonicalSources, sha256: sha(readFileSync(o.canonicalSources))},
      runtime: {path: o.canonicalRuntime, sha256: sha(readFileSync(o.canonicalRuntime))},
      generatedFixture: {path: generatedFixture, sha256: sha(readFileSync(generatedFixture))}},
    artifactBinding,
    fixtureRequest: {group: emitGroup, canonicalName: renderRequest,
      canonicalSource: 'bend2/selfhost/c_emit_core.bend', canonicalSourceSha256: renderSourceSha256,
      label: groupLabels[emitGroup].label, driver: driverBinding},
    cPath, cSha256: sha(c), artifact, artifactSha256: sha(readFileSync(artifact)),
    buildCommand: [cc, ...flags], nativeExecution, validationMs, codegenMs, totalMs: performance.now() - buildStarted,
    runtime: {name: 'node', node: process.versions.node, v8: process.versions.v8, bun: (process.versions as {bun?: string}).bun ?? null,
      execPath: process.execPath, execArgv: process.execArgv, platform: process.platform, arch: process.arch,
      workerLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072}},
    phases: phases.map(row => ({name: row.name, values: row.values, unitsByField: row.unitsByField, details: row.details})),
    note: 'profile-only native driver over the real generated Template/Checker/Emitter Run machines; the Emitter fixture consumes canonical BIR lowered from a frozen real checked source plus the real runtime and exact C source files through the generated c_emit_core render request; this is not a compiler-root workload, a source-substage span, a source-call CPU claim or a C execution claim',
  };
}

const isEntry = Boolean(process.argv[1]) && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMainThread && isEntry) {
  if (typeof (process.versions as {bun?: string}).bun === 'string') {
    console.error('native stage profile requires Node/V8 with --experimental-strip-types; Bun/JSC does not enforce Worker resourceLimits');
    process.exit(2);
  }
  if (process.release.name !== 'node') {
    console.error('native stage profile requires Node/V8; observed runtime ' + process.release.name);
    process.exit(2);
  }
  if (!process.execArgv.includes('--experimental-strip-types'))
    process.env.NODE_OPTIONS = ('--experimental-strip-types ' + (process.env.NODE_OPTIONS ?? '')).trim();
  process.env.HEAVY_GATE_MEMORY_MIB = '8192';
  process.env.HEAVY_GATE_RSS_MIB = '8192';
  process.env.HEAVY_GATE_POLL_MS = '10';
  process.env.HEAVY_GATE_TIMEOUT_MS = '600000';
  // Existing guard: re-execs with the authenticated lease and the fixed policy.
  await guardHeavyGate(fileURLToPath(import.meta.url), {label: 'Bounded native stage profile build'});
  const o = options();
  const worker = new Worker(new URL(import.meta.url), {
    workerData: {...o, __nativeStageProfileWorker: true},
    resourceLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072},
  });
  await superviseProfileWorker(worker);

} else if (!isMainThread && (workerData as any)?.__nativeStageProfileWorker === true) {
  try {
    parentPort!.postMessage(await build(workerData as Options));
  } catch (error) {
    try { workerProfile?.abortOpen('failed', {error: String(error instanceof Error ? error.message : error)}); } catch {}
    try { workerProfile?.finish('failed', error); } catch {}
    console.error('native stage profile build failed: ' + String(error instanceof Error ? error.stack ?? error.message : error));
    process.exitCode = 1;
  }
}
