#!/usr/bin/env bun
/**
 * Focused behavioral smoke for the opt-in compiler profiler.
 *
 *   node --experimental-strip-types evals/compiler_profile_smoke.ts
 *
 * This is a bounded diagnostic, not an acceptance, benchmark or fixedpoint
 * run. It exercises the real component-build CLI (valid/invalid source, with
 * and without profiling), the real native-experiment CLI on a bounded negative
 * load, and one direct tiny canonical book_load/book_valid/compile_book/clang
 * path through the shared observer adapter. It asserts unchanged artifacts on
 * the no-profile path, finalized profile statuses, failed spans on rejection,
 * nested coarse spans, exact counters, and real inspector CPU/allocation files.
 * Bulk profiles stay in a temporary directory; only a compact evidence JSON is
 * written under checkpoints/.
 */
import {createHash} from 'node:crypto';
import {existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {createCompileBookObserver, createCompilerProfile, compilerProfileLimits} from './compiler_profile.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const sha = (bytes: string | Uint8Array) => createHash('sha256').update(bytes).digest('hex');
const hash = (path: string) => sha(readFileSync(path));
const json = (path: string) => JSON.parse(readFileSync(path, 'utf8'));
const need = (condition: unknown, message: string): asserts condition => {
  if (!condition) throw Error(message);
};
const run = (command: string, args: string[], timeout = 180000) => {
  const result = spawnSync(command, args, {cwd: root, encoding: 'utf8', timeout,
    maxBuffer: 32 * 1024 * 1024, env: {...process.env, LC_ALL: 'C'}});
  return {status: result.status, signal: result.signal, stdout: result.stdout ?? '', stderr: result.stderr ?? ''};
};
const profileSummary = (path: string) => {
  need(existsSync(path), 'Missing profile summary: ' + path);
  return json(path);
};
const work = mkdtempSync(join(tmpdir(), 'bend-compiler-profile-smoke-'));
const evidence: Record<string, unknown> = {
  schemaVersion: 1,
  kind: 'compiler-profile-smoke',
  diagnosticOnly: true,
  acceptanceEvidence: false,
  fullrootOrOverheadMeasured: false,
  limits: [...compilerProfileLimits],
  source: {},
  cases: {},
};
let completed = false;
try {
  const valid = join(work, 'valid.bend');
  const invalid = join(work, 'invalid.bend');
  writeFileSync(valid, 'import Base\ndef main() -> Nat:\n  17n\n');
  writeFileSync(invalid, 'import Base\ndef main() -> Nat:\n  True\n');

  // 1. Component-build CLI: no-profile artifact must equal profiled artifact.
  const plain = join(work, 'plain');
  const profiled = join(work, 'profiled');
  mkdirSync(plain);
  mkdirSync(profiled);
  const plainBuild = run(process.execPath, ['--experimental-strip-types', 'evals/checker_core_component_build.ts',
    '--file=' + valid, '--exports=main', '--artifact=' + join(plain, 'main.mjs'),
    '--report=' + join(plain, 'report')]);
  need(plainBuild.status === 0, 'Plain component build failed: ' + plainBuild.stderr.slice(-1500));
  const profiledBuild = run(process.execPath, ['--experimental-strip-types', 'evals/checker_core_component_build.ts',
    '--file=' + valid, '--exports=main', '--artifact=' + join(profiled, 'main.mjs'),
    '--report=' + join(profiled, 'report'), '--profile-dir=' + join(profiled, 'profile'),
    '--profile-sampling=true']);
  need(profiledBuild.status === 0, 'Profiled component build failed: ' + profiledBuild.stderr.slice(-1500));
  const plainResult = json(join(plain, 'report.result.json'));
  const profiledResult = json(join(profiled, 'report.result.json'));
  need(plainResult.status === 'JS_GENERATED_NOT_YET_EXECUTED', 'Unexpected plain component status');
  need(profiledResult.status === plainResult.status, 'Profiling changed component result status');
  need(hash(join(plain, 'main.mjs')) === hash(join(profiled, 'main.mjs')), 'Profiling changed emitted component bytes');
  const componentSummary = profileSummary(profiledResult.compilerProfile.path);
  need(componentSummary.status === 'completed', 'Component profile did not complete');
  need(componentSummary.measurementStatus === 'complete', 'Component profile measurement is incomplete');
  need(componentSummary.summary.sampledSpans === 3, 'Expected three sampled component spans');
  for (const span of componentSummary.sampling.spans) {
    need(existsSync(span.cpuProfilePath) && existsSync(span.allocationProfilePath),
      'Missing sampled profile file for ' + span.name);
    need(readFileSync(span.cpuProfilePath).length > 0, 'Empty CPU profile for ' + span.name);
  }
  const componentSpanNames = componentSummary.spans.map((span: {name: string}) => span.name);
  need(['load', 'book-validation', 'codegen'].every(name => componentSpanNames.includes(name)),
    'Component profile missing a phase span: ' + componentSpanNames.join(','));
  evidence.cases.componentValid = {status: profiledResult.status, identicalArtifact: true,
    profileStatus: componentSummary.status, spans: componentSpanNames,
    sampledSpans: componentSummary.summary.sampledSpans,
    observationKinds: componentSummary.summary.observationKinds};

  // 2. Component-build CLI: a rejected source is a failed span, not a fake pass.
  const rejected = join(work, 'rejected');
  mkdirSync(rejected);
  const rejectedBuild = run(process.execPath, ['--experimental-strip-types', 'evals/checker_core_component_build.ts',
    '--file=' + invalid, '--exports=main', '--artifact=' + join(rejected, 'main.mjs'),
    '--report=' + join(rejected, 'report'), '--profile-dir=' + join(rejected, 'profile')]);
  need(rejectedBuild.status !== 0, 'Invalid component source unexpectedly succeeded');
  const rejectedResult = json(join(rejected, 'report.result.json'));
  need(rejectedResult.status === 'FAIL', 'Rejected component did not report FAIL');
  need(rejectedResult.compilerProfile.status === 'failed', 'Rejected component profile did not fail');
  const rejectedSummary = profileSummary(rejectedResult.compilerProfile.path);
  need(rejectedSummary.summary.failedSpans.includes('book-validation'),
    'Rejected component profile lacks a failed validation span');
  evidence.cases.componentRejected = {status: rejectedResult.status, stage: rejectedResult.stage,
    profileStatus: rejectedSummary.status, failedSpans: rejectedSummary.summary.failedSpans};

  // 2b. Component CLI: the supported allocation cutoff opens a raw prepare
  // span and throws inside the observer; the codegen root must stay the only
  // open span, then be closed aborted without an out-of-order failure.
  const cutoff = join(work, 'cutoff');
  mkdirSync(cutoff);
  const cutoffBuild = run(process.execPath, ['--experimental-strip-types',
    'evals/checker_core_component_build.ts', '--file=' + valid, '--exports=main',
    '--artifact=' + join(cutoff, 'main.mjs'), '--report=' + join(cutoff, 'report'),
    '--profile-dir=' + join(cutoff, 'profile'), '--profile-raw=true',
    '--allocation-profile-mib=1']);
  need(cutoffBuild.status === 0, 'Component allocation cutoff failed: ' + cutoffBuild.stderr.slice(-1500));
  const cutoffResult = json(join(cutoff, 'report.result.json'));
  need(cutoffResult.status === 'ALLOCATION_PROFILE_ONLY', 'Cutoff did not produce the supported diagnostic result');
  const cutoffSummary = profileSummary(cutoffResult.compilerProfile.path);
  const cutoffCodegen = cutoffSummary.spans.find((span: {name: string}) => span.name === 'codegen');
  need(cutoffCodegen?.status === 'aborted' &&
    cutoffCodegen.details.stopReason === 'heap_cutoff', 'Cutoff codegen span was not closed aborted');
  need(cutoffSummary.measurementStatus === 'complete' && cutoffSummary.summary.abortedSpans.includes('codegen'),
    'Cutoff profile did not unwind cleanly');
  evidence.cases.componentCutoff = {status: cutoffResult.status,
    profileStatus: cutoffSummary.status, measurementStatus: cutoffSummary.measurementStatus,
    codegenStatus: cutoffCodegen.status, abortedSpans: cutoffSummary.summary.abortedSpans,
    fineObservations: cutoffSummary.fineGrain.observations.count};

  // 3. Native-experiment CLI: bounded negative load must finalize both the
  // report and the codegen/build profiles, with the same diagnostic without
  // profiling. This does not reach compile_book/clang.
  const native = join(work, 'native');
  const nativePlain = join(work, 'native-plain');
  mkdirSync(native);
  mkdirSync(nativePlain);
  const abi = ['parsed_module', 'parse_with_fuel', 'expand_modules_start', 'template_step',
    'check_expanded_start', 'inspect_checked_start', 'checker_step', 'emit_modules_start',
    'emit_library_start', 'emitter_step', 'emit_c_modules_start', 'emit_c_library_start', 'c_emitter_step'];
  const manifest = (directory: string) => {
    const badRoot = join(directory, 'bad.bend');
    writeFileSync(badRoot, 'import Base\ndef main() -> Nat:\n  True\n');
    const path = join(directory, 'corpus.json');
    writeFileSync(path, JSON.stringify({directory, root: badRoot, exports: abi,
      files: [{path: badRoot, sha256: hash(badRoot), namespace: ''}]}, null, 2) + '\n');
    return path;
  };
  const nativeArgs = (directory: string, profile: boolean) => ['--smol', 'evals/native_compiler_experiment.ts',
    '--mode=build', '--corpus=' + manifest(directory), '--artifact=' + join(directory, 'artifact'),
    '--report=' + join(directory, 'report'),
    ...(profile ? ['--profile-dir=' + join(directory, 'profile'), '--profile-raw=true'] : [])];
  const nativeProfile = run('bun', nativeArgs(native, true));
  const nativeDefault = run('bun', nativeArgs(nativePlain, false));
  need(nativeProfile.status !== 0 && nativeDefault.status !== 0, 'Negative native load unexpectedly succeeded');
  const nativeReport = json(join(native, 'report'));
  const nativeDefaultReport = json(join(nativePlain, 'report'));
  need(nativeReport.status === 'FAIL' && nativeDefaultReport.status === 'FAIL', 'Native failure report is not terminal');
  need(nativeReport.failure.phase === nativeDefaultReport.failure.phase &&
    nativeReport.failure.diagnostic === nativeDefaultReport.failure.diagnostic,
    'Profiling changed the native failure diagnostic');
  need(!('compilerProfile' in nativeDefaultReport), 'No-profile native report contains profile state');
  const codegenProfile = nativeReport.compilerProfile.runs.codegen;
  const buildProfile = nativeReport.compilerProfile.runs.build;
  need(codegenProfile.status === 'failed' && buildProfile.status === 'failed',
    'Native profiles did not finalize as failed');
  const codegenSummary = profileSummary(codegenProfile.path);
  need(codegenSummary.summary.failedSpans.includes('book-load'),
    'Native codegen profile lacks a failed load span');
  evidence.cases.nativeRejected = {status: nativeReport.status, phase: nativeReport.failure.phase,
    codegenProfileStatus: codegenProfile.status, buildProfileStatus: buildProfile.status,
    codegenFailedSpans: codegenSummary.summary.failedSpans,
    defaultUnchanged: true};

  // 4. Direct tiny canonical C path: nested compile_book spans, exact counters,
  // C publication, clang, and execution. This is not the native experiment's
  // full bridge path; it isolates the collector and shared observer adapter.
  const direct = join(work, 'direct');
  mkdirSync(direct);
  const directProfile = await createCompilerProfile({directory: join(direct, 'profile'),
    execution: {stage: 'compiler-profile-smoke', target: 'c', sourceSha256: hash(valid)},
    rawDetail: true, sampling: {cpuIntervalUs: 1000, allocationIntervalBytes: 4194304}});
  const book = B.book_nil();
  const loadSpan = directProfile.begin('book-load', {source: valid}, {sample: true});
  await B.book_load(book, valid, '', new Map());
  directProfile.end(loadSpan, 'completed', {events: book.order.length});
  const validationSpan = directProfile.begin('book-validation', {events: book.order.length}, {sample: true});
  B.book_valid(book);
  let definitions = 0;
  for (const definition of Object.values(book.tlds))
    if (definition.$ === 'Def' && definition.v !== null) definitions++;
  directProfile.end(validationSpan, 'completed', {checkedDefinitions: definitions});
  const observer = createCompileBookObserver(directProfile, {rawDetail: true});
  const codegenSpan = directProfile.begin('compile-book', {checkedDefinitions: definitions}, {sample: true});
  const c = Comp.compile_book(book, {observe: observer.observe});
  directProfile.end(codegenSpan, 'completed', {passes: observer.passes, cUnits: c.length});
  directProfile.record({kind: 'exact-counter', name: 'compile_book',
    scope: 'canonical C code generation result', units: 'UTF-16 code units', value: c.length,
    details: {passes: observer.passes, checkedDefinitions: definitions}});
  const publicationSpan = directProfile.begin('c-publication', {});
  const cPath = join(direct, 'main.c');
  writeFileSync(cPath, c);
  directProfile.end(publicationSpan, 'completed', {cSha256: sha(c)});
  const clangSpan = directProfile.begin('clang', {combinedCompileAndLink: true});
  const executable = join(direct, 'main');
  const clang = run(process.env.CC ?? 'clang', ['-std=c11', '-O1', cPath, '-lpthread', '-lm', '-o', executable]);
  need(clang.status === 0, 'Tiny C compile failed: ' + clang.stderr.slice(-1500));
  directProfile.end(clangSpan, 'completed', {artifact: executable});
  const executeSpan = directProfile.begin('native-executable', {});
  const executed = run(executable, ['--threads', '1', '--gpu', 'off']);
  need(executed.status === 0 && executed.stdout.trim() === '17n',
    'Tiny C program output changed: ' + JSON.stringify(executed.stdout.trim()));
  directProfile.end(executeSpan, 'completed', {stdout: executed.stdout.trim()});
  const directSummary = directProfile.finish('completed');
  need(directSummary.status === 'completed', 'Direct profile did not complete');
  need(directSummary.measurementStatus === 'complete', 'Direct profile measurement is incomplete');
  const directNames = directSummary.spans.map((span: {name: string}) => span.name);
  for (const name of ['book-load', 'book-validation', 'compile-book', 'c-publication', 'clang', 'native-executable'])
    need(directNames.includes(name), 'Direct profile missing span ' + name);
  const passSpans = directNames.filter(name => /^c-pass-\d+$/.test(name));
  need(passSpans.length > 0 && directNames.includes('c-reachability'), 'Direct profile missing reachability/pass spans');
  need(directSummary.spans.find((span: {name: string}) => span.name === 'compile-book')?.parentId === null,
    'compile-book span is not top level');
  need(passSpans.every(name => directSummary.spans.find((span: {name: string}) => span.name === name)?.parentId !== null),
    'Pass spans are not nested under compile-book');
  need(directSummary.sampling.spans.length === 3, 'Direct profile expected three sampled spans');
  need(directSummary.observations.some((row: {kind: string}) => row.kind === 'compiler-state'),
    'Direct profile missing compiler-state observations');
  need(directSummary.observations.some((row: {kind: string, name: string}) =>
    row.kind === 'exact-counter' && row.name === 'compile_book'), 'Direct profile missing exact compile_book counter');
  evidence.cases.directC = {status: directSummary.status, output: executed.stdout.trim(),
    spans: directNames, sampledSpans: directSummary.summary.sampledSpans,
    observationKinds: directSummary.summary.observationKinds, passes: observer.passes};

  // 5. Direct negative validation: the same collector reports a failed span.
  const negative = await createCompilerProfile({directory: join(direct, 'profile-negative'),
    execution: {stage: 'compiler-profile-smoke-negative', target: 'c'}, rawDetail: false, sampling: false});
  const badBook = B.book_nil();
  await B.book_load(badBook, invalid, '', new Map());
  const badValidation = negative.begin('book-validation', {});
  let rejectedByValidation = false;
  try { B.book_valid(badBook); } catch (error) {
    rejectedByValidation = true;
    const text = error && typeof error === 'object' && '$' in error && error.$ === 'Err'
      ? B.err_show(error as B.Err) : String(error);
    negative.end(badValidation, 'failed', {error: text});
  }
  need(rejectedByValidation, 'Direct invalid source unexpectedly validated');
  const negativeSummary = negative.finish('failed', 'canonical validation rejected the source');
  need(negativeSummary.status === 'failed' && negativeSummary.measurementStatus === 'complete' &&
    negativeSummary.summary.failedSpans.includes('book-validation'),
    'Direct negative profile did not record a failed validation span');
  evidence.cases.directRejected = {status: negativeSummary.status, failedSpans: negativeSummary.summary.failedSpans};

  // Actual canonical C codegen failure (committed regression fixture): the
  // observer opens pass/fine spans, compile_book throws, and unwind must keep
  // the canonical diagnostic while closing descendants LIFO.
  const codegenFailureSource = join(root, 'tests/reg/array_open_element.bend');
  const failureBook = B.book_nil();
  await B.book_load(failureBook, codegenFailureSource, '', new Map());
  B.book_valid(failureBook);
  const failureProfile = await createCompilerProfile({directory: join(direct, 'profile-codegen-failure'),
    execution: {stage: 'compiler-profile-smoke-codegen-failure', sourceSha256: hash(codegenFailureSource)},
    rawDetail: true, sampling: false});
  const failureAdapter = createCompileBookObserver(failureProfile, {rawDetail: true});
  const failureRoot = failureProfile.begin('compile-book', {});
  let codegenError: unknown;
  try { Comp.compile_book(failureBook, {observe: failureAdapter.observe}); }
  catch (error) { codegenError = error; }
  need(codegenError !== undefined, 'Open-array fixture unexpectedly compiled');
  const codegenText = codegenError && typeof codegenError === 'object' && '$' in codegenError &&
    codegenError.$ === 'Err' ? B.err_show(codegenError as B.Err) : String(codegenError);
  need(/open Array element type/.test(codegenText), 'Canonical codegen diagnostic was not preserved');
  failureProfile.abortOpen('aborted', {error: codegenText, closeReason: 'codegen-failure'}, {keep: failureRoot});
  failureProfile.end(failureRoot, 'failed', {error: codegenText, passes: failureAdapter.passes,
    releases: failureAdapter.releases});
  const failureSummary = failureProfile.finish('failed', codegenText);
  const failureRootSpan = failureSummary.spans.find((span: {name: string}) => span.name === 'compile-book');
  need(failureRootSpan?.status === 'failed' && String(failureRootSpan.details.error).includes('open Array element type'),
    'Codegen failure root span did not preserve the diagnostic');
  need(failureSummary.summary.failedSpans.includes('compile-book'), 'Codegen failure root span is not failed');
  need(failureSummary.summary.abortedSpans.some((name: string) => name.startsWith('c-pass-') ||
    name.startsWith('c-reachability')), 'Codegen unwind left open coarse observer spans');
  need(failureSummary.measurementStatus === 'complete', 'Codegen failure profile measurement is incomplete');
  evidence.cases.directCodegenFailure = {status: failureSummary.status,
    measurementStatus: failureSummary.measurementStatus,
    failedSpans: failureSummary.summary.failedSpans,
    abortedSpans: failureSummary.summary.abortedSpans,
    passesObserved: failureAdapter.passes, diagnostic: codegenText.split('\n')[0]};

  // Measurement lifecycle is fail-closed: an open span on finish(completed)
  // must not look like clean evidence.
  const measurementProfile = await createCompilerProfile({directory: join(direct, 'profile-open-span'),
    execution: {stage: 'compiler-profile-smoke-open-span'}, rawDetail: false, sampling: false});
  measurementProfile.begin('left-open');
  const measurementSummary = measurementProfile.finish('completed');
  need(measurementSummary.status === 'completed' && measurementSummary.measurementStatus === 'incomplete' &&
    measurementSummary.incompleteEvidence === true && measurementSummary.summary.unclosedSpans.count === 1,
    'Open-span finish was not marked as incomplete measurement');
  evidence.cases.measurementIncomplete = {status: measurementSummary.status,
    measurementStatus: measurementSummary.measurementStatus,
    incompleteEvidence: measurementSummary.incompleteEvidence,
    unclosedSpans: measurementSummary.summary.unclosedSpans};

  // A terminated tiny worker must leave a durable coarse checkpoint even
  // without a summary. No forced GC, no fullroot run.
  const terminatedDir = join(direct, 'profile-terminated');
  const childScript = `import {createCompilerProfile} from ${JSON.stringify(join(root, 'evals/compiler_profile.mjs'))};
const p=await createCompilerProfile({directory:${JSON.stringify(terminatedDir)},execution:{stage:'terminated-worker'},rawDetail:false});
p.begin('compile-book',{pass:1});
p.record({kind:'exact-counter',name:'pass',scope:'terminated worker progress',units:'events',value:1});
process.exit(9);`;
  const terminated = spawnSync(process.execPath, ['--input-type=module', '-e', childScript],
    {cwd: root, encoding: 'utf8'});
  need(terminated.status === 9, 'Terminated worker did not exit with its requested status');
  const terminatedRuns = existsSync(terminatedDir) ? readdirSync(terminatedDir).filter(name => name.startsWith('profile-')) : [];
  need(terminatedRuns.length === 1, 'Terminated worker did not publish one profile run');
  const terminatedRun = join(terminatedDir, terminatedRuns[0]);
  need(!existsSync(join(terminatedRun, 'summary.json')), 'Terminated worker unexpectedly wrote a summary');
  const terminatedCheckpoint = json(join(terminatedRun, 'checkpoint.json'));
  need(terminatedCheckpoint.status === 'running' && terminatedCheckpoint.activeSpans.some((span: {name: string}) =>
    span.name === 'compile-book'), 'Checkpoint lacks the active coarse phase');
  need(terminatedCheckpoint.counts.observations >= 1 && terminatedCheckpoint.recentObservations.length >= 1,
    'Checkpoint lacks the coarse progress observation');
  need(terminatedCheckpoint.execution.stage === 'terminated-worker', 'Checkpoint lacks provenance');
  evidence.cases.terminatedWorkerCheckpoint = {status: terminated.status, summary: false,
    checkpointStatus: terminatedCheckpoint.status,
    activeSpans: terminatedCheckpoint.activeSpans.map((span: {name: string}) => span.name),
    observations: terminatedCheckpoint.counts.observations,
    recentObservationKinds: terminatedCheckpoint.recentObservations.map((row: {kind: string}) => row.kind)};

  // Collector input contract: cyclic arrays are rejected, not a stack overflow.
  const contract = await createCompilerProfile({directory: join(direct, 'profile-contract'),
    execution: {stage: 'collector-input-contract'}, rawDetail: false, sampling: false});
  const cyclicArray: unknown[] = [];
  cyclicArray.push(cyclicArray);
  let cyclicRejected = false;
  try {
    contract.record({kind: 'contract', scope: 'collector input validation',
      values: {cyclicArray}});
  } catch (error) {
    cyclicRejected = /contains a cycle/.test(String(error));
  }
  need(cyclicRejected, 'Collector accepted a cyclic array instead of rejecting it');
  contract.finish('completed');

  // Adapter contract: release-after is counted/observed, never a coarse span;
  // mixed state is split into observations with honest units.
  const adapterRecords: Array<{kind: string; units?: string; values?: Record<string, unknown>}> = [];
  const adapterSpans: string[] = [];
  const adapterProfile = {
    rawDetail: false,
    begin(name: string) { adapterSpans.push(name); return {id: adapterSpans.length, name}; },
    end() {},
    record(row: {kind: string; units?: string; values?: Record<string, unknown>}) { adapterRecords.push(row); },
    finish() { return {}; },
  };
  const adapter = createCompileBookObserver(adapterProfile, {rawDetail: false});
  adapter.observe('release-after', 'a', {eExists: true, hExists: false, outputLines: 2,
    outputUTF16Units: 10, memos: {steps: 3}, segments: 1});
  adapter.observe('release-after', 'b', {eExists: true, hExists: false, outputLines: 3,
    outputUTF16Units: 12, memos: {steps: 4}, segments: 1});
  need(adapter.releases === 2 && adapterRecords.length === 0,
    'Non-raw adapter emitted release rows or release spans');
  adapter.observe('c-pass-1-before', 'main', {});
  adapter.observe('c-pass-1-after', 'main', {eExists: true, hExists: false, segments: 2, spins: 1,
    ownFacts: 4, hotFacts: 5, staticFacts: 6, retainedHigher: 2, outputLines: 3,
    outputUTF16Units: 12, memos: {steps: 2}});
  adapter.observe('prepare-before', 'c', {});
  adapter.observe('prepare-after', 'c', {eExists: true, hExists: false});
  need(adapterSpans.join(',') === 'c-pass-1', 'Non-raw adapter opened unexpected spans: ' + adapterSpans.join(','));
  const adapterUnits = new Set(adapterRecords.map(row => row.units));
  need(['entries', 'lines', 'UTF-16 code units', 'boolean'].every(unit => adapterUnits.has(unit)),
    'Adapter state observations do not use split units: ' + [...adapterUnits].join(','));
  need(adapterRecords.filter(row => row.kind === 'compiler-state' && row.units === 'entries').every(row =>
    Object.keys(row.values ?? {}).every(key => ['segments', 'spins', 'ownFacts', 'hotFacts',
      'staticFacts', 'retainedHigher'].includes(key))),
    'Adapter labelled non-entry compiler state as entries');
  need(adapterRecords.filter(row => row.kind === 'compiler-memo-sizes').every(row =>
    row.units === 'entries' && Object.keys(row.values ?? {}).length > 0),
    'Adapter memo sizes are not nonempty entry counts');
  evidence.cases.collectorContract = {cyclicArrayRejected: true, nonRawReleaseRows: 0,
    adapterReleaseEvents: 2, adapterSpanNames: adapterSpans, adapterUnits: [...adapterUnits]};

  for (const path of ['evals/compiler_profile.mjs', 'evals/selfhost_cpu_profile.mjs',
    'evals/native_compiler_experiment.ts', 'evals/checker_core_component_build.ts',
    'bend2/bend.ts', 'bend2/comp.ts']) {
    evidence.source[path] = hash(join(root, path));
  }
  evidence.status = 'PASS';
  evidence.temporaryDirectoryRemoved = true;
  writeFileSync(join(root, 'checkpoints/compiler-profile-smoke-v1.json'), JSON.stringify(evidence, null, 2) + '\n');
  completed = true;
  console.log(JSON.stringify({status: 'PASS', cases: Object.keys(evidence.cases),
    temporaryDirectory: work}, null, 2));
} finally {
  if (completed) rmSync(work, {recursive: true, force: true});
  else console.error('Smoke evidence and profiles retained at ' + work);
}
