#!/usr/bin/env bun
/** Full canonical native validation followed by streaming JS emission under V8.
 * bun evals/checker_core_component_build.ts --file=PATH
 *   --exports=main --artifact=PATH.js --report=checkpoints/REPORT_PREFIX
 * Canonical compiler/kernel/Base identities are captured before worker startup,
 * authenticated before import, and held fixed through artifact publication.
 * The unmodified native kernel retains actual checked e values in the book.
 * Canonical emission releases checked e after all JS definition folding completes.
 * Optional --allocation-profile-mib=N captures live sampled codegen allocations
 * without publishing a compiler artifact or acceptance. Automatic GC only.
 * Reports prove generation only; no artifact execution or selfhost-green claim.
 */
import {createHash} from 'node:crypto';
import {appendFileSync, closeSync, existsSync, openSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {Worker, isMainThread, workerData} from 'node:worker_threads';
import {getHeapStatistics} from 'node:v8';
import type * as Bend from '../bend2/bend.ts';
import type {Session as InspectorSession, HeapProfiler} from 'node:inspector';
import {guardHeavyGate, runHeavyGate} from './heavy_gate.ts';

type StorageState = {eExists?: boolean; hExists?: boolean; retainedHigher?: number; outputLines?: number; outputUTF16Units?: number};
interface CanonicalCompiler {
  js_lib(book: Bend.Book, mod?: boolean, options?: {
    releaseChecked?: boolean;
    roots?: Bend.Name[];
    exports?: Bend.Name[];
    observe?: (stage: string, name: string, state: StorageState & {memos?: Record<string, number>}) => void;
  }): string;
}
type Options = {file: string; exports: string[]; artifact: string; report: string; worker: boolean;
  allocationProfileMiB?: number; inputsSha256?: string};
const scriptPath = fileURLToPath(import.meta.url);
const root = resolve(dirname(scriptPath), '..');
const compilerPath = resolve(root, 'bend2/comp.ts');
const kernelPath = resolve(root, 'bend2/bend.ts');
const basePath = resolve(root, 'bend2/base.bend');
const gate = {memoryMiB: 8192, rssMiB: 8192, pollMs: 10};
const heapLimitMiB = 3072;
const sha = (bytes: string | Uint8Array) => createHash('sha256').update(bytes).digest('hex');
const hash = (path: string) => sha(readFileSync(path));
const json = (value: unknown) => JSON.stringify(value, null, 2) + '\n';
const create = (path: string, contents: string | Uint8Array) => writeFileSync(path, contents, {flag: 'wx'});

function options(): Options {
  const args = new Map<string, string>();
  let worker = false;
  for (const arg of process.argv.slice(2)) {
    if (arg === '--worker' && !worker) { worker = true; continue; }
    const at = arg.indexOf('=');
    const name = arg.slice(0, at), value = arg.slice(at + 1);
    if (at < 0 || !['--file', '--exports', '--artifact', '--report', '--allocation-profile-mib', '--inputs-sha256'].includes(name) || !value || args.has(name))
      throw Error('Expected unique --file=PATH --exports=NAME[,NAME] --artifact=PATH --report=PREFIX; optional --allocation-profile-mib=N');
    args.set(name, value);
  }
  for (const name of ['--file', '--exports', '--artifact', '--report'])
    if (!args.has(name)) throw Error('Missing required option ' + name);
  const exports = args.get('--exports')!.split(',');
  if (exports.some(name => !/^[A-Za-z_][A-Za-z0-9_.]*$/.test(name)) || new Set(exports).size !== exports.length)
    throw Error('Export names must be nonempty, unique Bend names');
  const file = resolve(args.get('--file')!), artifact = resolve(args.get('--artifact')!), report = resolve(args.get('--report')!);
  if (file === artifact || artifact.startsWith(report + '.')) throw Error('Artifact/source/report paths overlap');
  const profile = args.get('--allocation-profile-mib');
  const allocationProfileMiB = profile === undefined ? undefined : Number(profile);
  if (profile !== undefined && (!/^[1-9][0-9]*$/.test(profile) ||
      !Number.isSafeInteger(allocationProfileMiB) || allocationProfileMiB! > heapLimitMiB - 1024))
    throw Error('Allocation profile cutoff must be a positive integer at least 1024 MiB below the worker heap limit');
  const inputsSha256 = args.get('--inputs-sha256');
  if (worker !== (inputsSha256 !== undefined) || (inputsSha256 !== undefined && !/^[0-9a-f]{64}$/.test(inputsSha256)))
    throw Error('Worker requires an authenticated input manifest; --inputs-sha256 is worker-only');
  return {file, exports, artifact, report, worker, allocationProfileMiB, inputsSha256};
}
function pins(o: Options): Record<string, string> {
  // These are new run identities, not claims that changed sources match a
  // historical acceptance. The same manifest crosses the guardian boundary.
  const paths = [scriptPath, compilerPath, kernelPath, basePath, o.file,
    resolve(root, 'evals/heavy_gate.ts'), resolve(root, 'evals/heavy_gate_native.c')];
  const expected = Object.fromEntries(paths.map(path => [path, hash(path)]));
  verify({
    [resolve(root, 'evals/heavy_gate.ts')]: '47a12205abd374fd69d7dac30ee9fb45d7203cad2790870511387cd2efc22251',
    [resolve(root, 'evals/heavy_gate_native.c')]: 'f5aecf8308caebc72dccf8986733b37137d448021ee378302cfcd038381b7aa9',
  });
  verify(expected);
  return Object.fromEntries(Object.entries(expected).sort(([a], [b]) => a.localeCompare(b)));
}
function workerPins(o: Options): Record<string, string> {
  const bytes = readFileSync(o.report + '.inputs.json');
  if (sha(bytes) !== o.inputsSha256) throw Error('Worker input manifest drift');
  const expected: Record<string, string> = JSON.parse(bytes.toString('utf8'));
  for (const path of [scriptPath, compilerPath, kernelPath, basePath, o.file,
    resolve(root, 'evals/heavy_gate.ts'), resolve(root, 'evals/heavy_gate_native.c')])
    if (!/^[0-9a-f]{64}$/.test(expected[path] ?? '')) throw Error('Protected input missing: ' + path);
  verify(expected);
  return expected;
}
function verify(expected: Record<string, string>) {
  for (const [path, pin] of Object.entries(expected))
    if (hash(path) !== pin) throw Error('Protected input drift: ' + path);
}
function firstError(o: Options, stage: string, diagnostic: string) {
  const path = o.report + '.first-error.json';
  if (!existsSync(path)) create(path, json({status: 'FAIL', stage, diagnostic, checksExcluded: 0,
    outputPatches: 0, compiledExecution: 'NOT_RUN', selfhostGreen: false}));
}

async function worker(o: Options) {
  const start = performance.now();
  const cpuStart = process.cpuUsage();
  let phase = 'prerequisites';
  let kernel: typeof Bend | undefined;
  let comp: CanonicalCompiler | undefined;
  let protectedPins: Record<string, string> | undefined;
  const loadedInputs: Record<string, string> = {};
  let success: Record<string, unknown> | undefined, failure: {stage: string; diagnostic: string} | undefined;
  let allocationSession: InspectorSession | undefined;
  const allocationCutoff = new Error('Diagnostic allocation heap cutoff');
  create(o.report + '.events.jsonl', '');
  let eventsFD: number | undefined = openSync(o.report + '.events.jsonl', 'a');
  const event = (data: Record<string, unknown>) => {
    const row = {phase, elapsedMs: performance.now() - start, ...data};
    // Persist every event synchronously, including the last one before guardian termination.
    // Reuse the append descriptor and serialization, not an in-memory event batch.
    const serialized = JSON.stringify(row) + '\n';
    appendFileSync(eventsFD ?? o.report + '.events.jsonl', serialized);
    writeFileSync(o.report + '.progress.json', serialized);
  };
  const fail = (error: unknown, stage = phase) => {
    let diagnostic = String(error);
    if (kernel && error && typeof error === 'object' && '$' in error && error.$ === 'Err')
      diagnostic = kernel.err_show(error as Bend.Err);
    failure ??= {stage, diagnostic};
    firstError(o, stage, diagnostic);
    event({stage: 'error', failedStage: stage, diagnostic});
    console.error(diagnostic);
  };
  const stableInputs = async () => {
    if (protectedPins) verify(protectedPins);
    verify(loadedInputs);
    if (o.inputsSha256 && hash(o.report + '.inputs.json') !== o.inputsSha256)
      throw Error('Worker input manifest drift');
  };
  try {
    if (process.versions.bun || !process.versions.v8) throw Error('Native build worker requires Node/V8');
    protectedPins = workerPins(o);
    if (existsSync(o.artifact)) throw Error('Artifact path already used: ' + o.artifact);
    const runtime = {name: 'node', node: process.versions.node, v8: process.versions.v8,
      executable: process.execPath, heapLimitMiB, stackSizeMb: 256,
      heapSizeLimitBytes: getHeapStatistics().heap_size_limit, manualGC: false};
    const memory = () => {
      const usage = process.memoryUsage();
      return {rssBytes: usage.rss, heapUsed: usage.heapUsed};
    };
    // Import only after authenticating the exact canonical kernel/compiler.
    const nativeRetention = 'native checked e retained through all JS definition folding; scope-local higher caches released between definitions; no serialization or source-value fallback';
    kernel = await import(kernelPath) as typeof Bend;
    await stableInputs();
    comp = await import(compilerPath) as CanonicalCompiler;
    if (typeof comp.js_lib !== 'function') throw Error('Canonical compiler API missing: js_lib');
    const K = kernel, book = K.book_nil();
    // Observe the loader's existing seen-map seam, not its parser or algorithms.
    // Hash each module before its first read, including imports and Base.
    class Inputs extends Map<string, string | null> {
      override set(path: string, namespace: string | null) {
        if (namespace === null && !Object.hasOwn(loadedInputs, path)) loadedInputs[path] = hash(path);
        return super.set(path, namespace);
      }
    }
    phase = 'load';
    event({stage: 'load-start', sourcePath: o.file, compilerPath,
      compilerSha256: protectedPins[compilerPath], kernelSha256: protectedPins[kernelPath],
      loadMode: 'CANONICAL_NATIVE_UNMODIFIED', checkedOutputRetention: 'native e', nativeRetention});
    await K.book_load(book, o.file, '', new Inputs());
    // Foreign JS sources, if present, are compiler inputs too.
    for (const definition of Object.values(book.tlds))
      if (definition.$ === 'Def') for (const path of definition.i ?? [])
        if (path.endsWith('.js')) loadedInputs[realpathSync(path)] = hash(path);
    await stableInputs();
    for (const name of o.exports)
      if (book.tlds[name]?.$ !== 'Def') throw Error('Requested export is not a loaded definition: ' + name);
    event({stage: 'load-pass', events: book.order.length, ...memory()});
    phase = 'validation';
    const validationStart = performance.now(), validationCpu = process.cpuUsage();
    K.book_valid(book); // Complete canonical validation, with no prefix or observer.
    const usedValidationCpu = process.cpuUsage(validationCpu);
    const validationTimings = {status: 'FULL_VALIDATION_PASS', eventsChecked: book.order.length,
      totalEvents: book.order.length, manualGC: false, elapsedMs: performance.now() - validationStart,
      cpuMs: (usedValidationCpu.user + usedValidationCpu.system) / 1000};
    create(o.report + '.validation-timings.json', json(validationTimings));
    if (book.hols) throw Error('Unfilled book after complete native validation');
    let expectedSourceDefinitions = 0;
    const eNames = new Set<string>();
    for (const [name, definition] of Object.entries(book.tlds)) {
      if (definition.$ !== 'Def') continue;
      if (definition.v !== null) {
        expectedSourceDefinitions++;
        if (definition.e === undefined) throw Error('Native checked output missing: ' + name);
        eNames.add(name);
      }
    }
    const checkedDefinitions = eNames.size, nativeCheckedBodies = checkedDefinitions;
    if (checkedDefinitions !== expectedSourceDefinitions)
      throw Error('Native checked body count differs from source definitions');
    const liveBodies = expectedSourceDefinitions;
    const eventsFullyValidated = book.order.length;
    const provenance = {schemaVersion: 4, sourcePath: o.file, sourceSha256: hash(o.file), exports: o.exports,
      protectedPins,
      loadedInputs: Object.fromEntries(Object.entries(loadedInputs).sort(([a], [b]) => a.localeCompare(b))),
      compilerPath, compilerSha256: protectedPins[compilerPath],
      runnerPath: scriptPath, runnerSha256: protectedPins[scriptPath],
      kernelPath, kernelSha256: protectedPins[kernelPath], basePath, baseSha256: protectedPins[basePath],
      kernelObservation: {kernelUnmodified: true, sourceValueReplacement: false, parserSubstitutions: 0},
      loadMode: 'CANONICAL_NATIVE_UNMODIFIED',
      runtime, memoryObservation: 'external process-tree RSS/footprint guardian; worker RSS/heap snapshots', guard: gate,
      checkedOutputRetention: 'native e', nativeRetention,
      eventsFullyValidated, checkedDefinitions, nativeCheckedBodies, expectedSourceDefinitions,
      checksExcluded: 0, outputPatches: 0};
    const provenanceSha256 = sha(JSON.stringify(provenance));
    const provenancePath = o.report + '.provenance.json';
    create(provenancePath, json({...provenance, provenanceSha256}));
    event({stage: 'full-validation-pass', eventsFullyValidated, checkedDefinitions, liveBodies,
      nativeCheckedBodies, expectedSourceDefinitions, nativeRetention, checksExcluded: 0});
    const validationEndMs = performance.now() - start;
    let preparedCount = 0, releasedCount = 0, hLive = 0, eLive = eNames.size, maxE = eLive, maxH = 0;
    let memos: Record<string, number> = {};
    const preparationIndices = new Map<string, number>();
    const preparedNames = new Set<string>(), releasedNames = new Set<string>(), hNames = new Set<string>();
    const observe = (stage: string, name: string, state: StorageState & {memos?: Record<string, number>}) => {
      if (stage === 'prepare-before' && !preparationIndices.has(name))
        preparationIndices.set(name, preparationIndices.size);
      if (stage === 'prepare-after') { preparedNames.add(name); preparedCount = preparedNames.size; }
      if (stage === 'release-after') { releasedNames.add(name); releasedCount = releasedNames.size; }
      if (state.eExists !== undefined) {
        if (state.eExists) eNames.add(name); else eNames.delete(name);
        eLive = eNames.size;
        maxE = Math.max(maxE, eLive);
      }
      if (state.hExists !== undefined) {
        if (state.retainedHigher === 0) hNames.clear();
        if (state.hExists) hNames.add(name); else hNames.delete(name);
        hLive = hNames.size; maxH = Math.max(maxH, hLive);
      }
      if (state.memos) memos = state.memos;
      if (o.allocationProfileMiB !== undefined)
        event({stage, name, index: preparationIndices.get(name),
          preparedCount, releasedCount, eLive, hLive, maxSimultaneousE: maxE,
          maxSimultaneousH: maxH, ...state, ...memory(), memos});
      if (o.allocationProfileMiB !== undefined &&
          process.memoryUsage().heapUsed >= o.allocationProfileMiB * 1024 * 1024)
        throw allocationCutoff;
    };
    phase = 'codegen';
    const codegenBaseline = memory();
    if (o.allocationProfileMiB !== undefined) {
      // The Bun supervisor must not load Node/V8-only inspector implementations.
      const {Session} = await import('node:inspector');
      allocationSession = new Session();
      allocationSession.connect();
      await new Promise<void>((resolveSampling, reject) =>
        allocationSession!.post('HeapProfiler.startSampling', {samplingInterval: 524288},
          error => error ? reject(error) : resolveSampling()));
    }
    event({stage: 'codegen-start', exports: o.exports, ...codegenBaseline,
      allocationProfileMiB: o.allocationProfileMiB});
    let code: string | undefined;
    let allocationStopReason = 'emission_complete';
    try { code = comp.js_lib(book, true, {
      roots: o.exports, exports: o.exports, releaseChecked: true, observe}); }
    catch (error) {
      if (error !== allocationCutoff) throw error;
      allocationStopReason = 'heap_cutoff';
    }
    await stableInputs();
    if (allocationSession) {
      const sampled = await new Promise<HeapProfiler.StopSamplingReturnType>((resolveSampling, reject) =>
        allocationSession!.post('HeapProfiler.stopSampling',
          (error, result) => error ? reject(error) : resolveSampling(result)));
      const profilePath = o.report + '.allocation-profile.json';
      create(profilePath, json({schemaVersion: 1, diagnosticOnly: true,
        stage: 'codegen', stopReason: allocationStopReason,
        samplingIntervalBytes: 524288, cutoffMiB: o.allocationProfileMiB,
        codegenBaseline, captureMemory: memory(), memos,
        preparedCount, releasedCount, eLive, hLive,
        samplingCaveat: 'Sampled live allocations made after validation; not exact owner sizes or a heap snapshot.',
        provenancePath, provenanceSha256, ...sampled}));
      success = {status: 'ALLOCATION_PROFILE_ONLY', diagnosticOnly: true,
        profilePath, profileSha256: hash(profilePath), stopReason: allocationStopReason,
        provenancePath, provenanceSha256,
        eventsFullyValidated, checkedDefinitions, checksExcluded: 0, outputPatches: 0,
        nativeRetention, nativeCheckedBodies, expectedSourceDefinitions,
        artifactGenerated: false, runtime, compiledExecution: 'NOT_RUN', selfhostGreen: false};
      event({stage: 'allocation-profile-saved', ...success});
    } else {
    if (code === undefined) throw Error('Canonical compiler did not return code');
    create(o.artifact, code);
    const artifactSha256 = hash(o.artifact), bytes = Buffer.byteLength(code);
    if (artifactSha256 !== sha(code)) throw Error('Artifact bytes differ from canonical compiler output');
    event({stage: 'codegen-pass', artifactPath: o.artifact, artifactSha256, bytes});
    const cpuUsed = process.cpuUsage(cpuStart);
    const cpuMs = (cpuUsed.user + cpuUsed.system) / 1000;
    create(o.report + '.metrics.json', json({artifactPath: o.artifact, artifactSha256, provenanceSha256,
      validationEndMs, totalElapsedMs: performance.now() - start, cpuMs, runtime,
      pollMs: 10, validation: validationTimings,
      memoryObservation: 'external guardian samples aggregate RSS/footprint; per-phase footprint not sampled',
      selfhostGreen: false}));
    success = {status: 'JS_GENERATED_NOT_YET_EXECUTED', provenancePath, provenanceSha256, sourcePath: o.file,
      sourceSha256: provenance.sourceSha256, exports: o.exports, artifactPath: o.artifact, artifactSha256, bytes,
      eventsFullyValidated, checkedDefinitions, liveBodies, checksExcluded: 0, outputPatches: 0,
      checkedOutputRetention: 'native e', nativeRetention,
      nativeCheckedBodies, expectedSourceDefinitions,
      toolchain: 'CANONICAL NATIVE LOAD/CHECK; CANONICAL JS PREPARE/EMIT/RELEASE; Node/V8 automatic GC',
      preparedCount, releasedCount,
      maxSimultaneousE: maxE, maxSimultaneousH: maxH,
      countsCaveat: 'Definition slots, not unique term graphs; signature metadata does not prepare higher bodies',
      runtime, cpuMs,
      compiledExecution: 'NOT_RUN', selfhostGreen: false};
    }
  } catch (error) { fail(error); }
  finally {
    // Every independent cleanup is attempted even if a preceding cleanup fails.
    try { allocationSession?.disconnect(); } catch (error) { fail(error, 'cleanup-allocation-profiler'); }
    try { await stableInputs(); } catch (error) { fail(error, 'post-run-pins'); }
    try {
      const fd = eventsFD; eventsFD = undefined;
      if (fd !== undefined) closeSync(fd);
    } catch (error) { fail(error, 'cleanup-events'); }
  }
  create(o.report + '.worker-result.json', json(failure ? {status: 'FAIL', ...failure, checksExcluded: 0,
    outputPatches: 0, compiledExecution: 'NOT_RUN', selfhostGreen: false} : success));
  if (failure) process.exitCode = 2;
}

let parsed: Options | undefined;
let reportReserved = false;
try {
  if (resolve(process.cwd()) !== root) throw Error('Run from the repository root');
  parsed = isMainThread ? options() : workerData as Options;
  if (parsed.worker) {
    if (isMainThread) {
      // Authenticate before creating the large-stack compiler isolate.
      workerPins(parsed);
      process.argv.push('--memory-mib', '8192', '--rss-mib', '8192', '--poll-ms', '10');
      await guardHeavyGate(scriptPath, {label: 'Full-native CheckerCore component JS build worker'});
      const thread = new Worker(new URL(import.meta.url), {workerData: parsed,
        resourceLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: heapLimitMiB}});
      process.exitCode = await new Promise<number>((resolveExit, reject) => {
        thread.once('error', reject);
        thread.once('exit', resolveExit);
      });
    } else {
      await worker(parsed);
    }
  } else {
    const o = parsed;
    for (const suffix of ['.request.json', '.events.jsonl', '.result.json', '.worker-result.json', '.first-error.json',
      '.guardian.json', '.progress.json', '.provenance.json', '.metrics.json', '.inputs.json',
      '.validation-timings.json', '.allocation-profile.json'])
      if (existsSync(o.report + suffix)) throw Error('Report namespace already used: ' + o.report);
    if (existsSync(o.artifact)) throw Error('Artifact path already used: ' + o.artifact);
    const protectedPins = pins(o);
    create(o.report + '.request.json', json({sourcePath: o.file, exports: o.exports, artifactPath: o.artifact,
      guard: gate, compilerPath, compilerSha256: protectedPins[compilerPath],
      kernelPath, kernelSha256: protectedPins[kernelPath], basePath, baseSha256: protectedPins[basePath],
      runtime: {name: 'node', heapLimitMiB, stackSizeMb: 256, manualGC: false},
      allocationProfileMiB: o.allocationProfileMiB, diagnosticOnly: o.allocationProfileMiB !== undefined,
      compiledExecution: 'NOT_RUN', selfhostGreen: false}));
    reportReserved = true;
    create(o.report + '.inputs.json', json(protectedPins));
    const inputsSha256 = hash(o.report + '.inputs.json');
    let cleanupPassed = false;
    try {
      const result = await runHeavyGate(['node', '--experimental-strip-types', '--max-old-space-size=' + heapLimitMiB,
        scriptPath, '--worker', '--file=' + o.file, '--exports=' + o.exports.join(','),
        '--artifact=' + o.artifact, '--report=' + o.report, '--inputs-sha256=' + inputsSha256,
        ...(o.allocationProfileMiB === undefined ? [] : ['--allocation-profile-mib=' + o.allocationProfileMiB])],
        {...gate, label: 'Full-native CheckerCore component JS build'});
      create(o.report + '.guardian.json', json({...result, pollMs: 10}));
      verify(protectedPins);
      const workerResult = existsSync(o.report + '.worker-result.json')
        ? JSON.parse(readFileSync(o.report + '.worker-result.json', 'utf8')) : undefined;
      if (hash(o.report + '.inputs.json') !== inputsSha256) throw Error('Input manifest drift after worker');
      if (result.status === 'PASS' &&
          ['ALLOCATION_PROFILE_ONLY', 'JS_GENERATED_NOT_YET_EXECUTED'].includes(workerResult?.status)) {
        if (workerResult.provenancePath !== o.report + '.provenance.json') throw Error('Unexpected provenance path');
        const {provenanceSha256, ...provenance} = JSON.parse(readFileSync(workerResult.provenancePath, 'utf8'));
        if (sha(JSON.stringify(provenance)) !== provenanceSha256 || provenanceSha256 !== workerResult.provenanceSha256)
          throw Error('Provenance changed after capture');
        if (JSON.stringify(provenance.protectedPins) !== JSON.stringify(protectedPins))
          throw Error('Provenance input manifest differs from guarded inputs');
        verify(provenance.loadedInputs);
      }
      // Final success is published only after both the worker and guardian pass.
      if (result.status === 'PASS' && o.allocationProfileMiB !== undefined &&
          workerResult?.status === 'ALLOCATION_PROFILE_ONLY') {
        if (hash(o.report + '.allocation-profile.json') !== workerResult.profileSha256)
          throw Error('Allocation profile changed after capture');
        create(o.report + '.result.json', json({...workerResult, guardian: result}));
        process.exitCode = 0;
      } else if (result.status !== 'PASS' || workerResult?.status !== 'JS_GENERATED_NOT_YET_EXECUTED') {
        const progress = existsSync(o.report + '.progress.json') ? JSON.parse(readFileSync(o.report + '.progress.json', 'utf8')) : {};
        const stage = workerResult?.stage ?? progress.phase ?? 'guardian';
        const diagnostic = workerResult?.diagnostic ?? (result.status + ': ' + result.reason);
        firstError(o, stage, diagnostic);
        create(o.report + '.result.json', json({status: 'FAIL', stage, diagnostic, checksExcluded: 0,
          outputPatches: 0, compiledExecution: 'NOT_RUN', selfhostGreen: false, guardian: result}));
        process.exitCode = result.exitCode || 2;
      } else {
        if (workerResult.artifactPath !== o.artifact || hash(o.artifact) !== workerResult.artifactSha256)
          throw Error('Artifact changed after canonical emission');
        create(o.report + '.result.json', json({...workerResult, guardian: result}));
        process.exitCode = 0;
      }
    } finally {
      if (!cleanupPassed) verify(protectedPins);
    }
  }
} catch (error) {
  const diagnostic = String(error);
  if (parsed && reportReserved && !existsSync(parsed.report + '.result.json')) {
    firstError(parsed, 'runner', diagnostic);
    create(parsed.report + '.result.json', json({status: 'FAIL', stage: 'runner', diagnostic,
      checksExcluded: 0, outputPatches: 0, compiledExecution: 'NOT_RUN', selfhostGreen: false}));
  }
  console.error(diagnostic); process.exitCode = 2;
}
