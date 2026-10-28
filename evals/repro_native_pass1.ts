#!/usr/bin/env node
// Diagnostic-only reproducer for compile_book's fixed-point pass cost.
//
// It does NOT narrow acceptance and proves no compiler correctness claim. It
// loads, checks and compiles generated families of independently typed Bend
// sources through the real public path (book_nil/book_load/book_valid/
// compile_book) with the canonical worker limits (256 MiB stack, 3072 MiB old
// generation) under the shared heavy_gate lane. One fresh Worker per case, and
// the next case starts only after the previous worker has actually exited.
//
// Three diagnostic families:
//   chain/linear - same definition count, same arithmetic/IO.pure prefix and
//     same leaf; they differ only in where the identical call c_next(z) sits:
//     the do-block continuation (chain; one site and tail, so emit_body's once
//     path inlines it through emit_fuse) or a do binding followed by the unit
//     action (linear; a device jump, never inlined). This is a growth
//     comparison, not an isolated proof of one rule: the linear body still
//     carries one extra binding and unit action.
//   literal - one pure main whose body is a single wide List<Nat> literal, the
//     shape the merged diagnostic's generated fixture adds at scale (a 434 KiB
//     single-line term with 23,403 constructor nodes). `defs` is its element
//     count. It measures the load/check/reachability/pass cost per literal node.
// file_release clears FL.higher and every memo after each definition, so each
// definition rebuilds its own higher term and every inlined callee's.
//
// Evidence is phase-only: the worker posts every c-pass-N-before/after boundary
// and bounded progress to the parent as it goes, so a worker OOM or timeout
// loses neither the active pass nor the pinned input. The parent keeps those
// rows and composes the failure result.
//
// usage: node --experimental-strip-types evals/repro_native_pass1.ts
//   --out=FILE --receipt=FILE [--families=chain,linear[,literal]]
//   [--sizes=8,16,32,64] [--literal-sizes=1000,4000,16000]
//   [--max-defs=64] [--max-elements=16384] [--report-limit-units=67108864]
//   [--case-timeout-ms=60000]
//
// All heavyweight work is inside guardHeavyGate; the inherited lease is
// authenticated, never re-created, and the default lock path is used.
import {createHash} from 'node:crypto';
import {mkdirSync, mkdtempSync, writeFileSync, readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {isMainThread, parentPort, Worker, workerData} from 'node:worker_threads';
import {guardHeavyGate} from './heavy_gate.ts';
import * as v8 from 'node:v8';
import {performance} from 'node:perf_hooks';
import {setTimeout as delay} from 'node:timers/promises';
import type * as Bend from '../bend2/bend.ts';
import type * as Compiler from '../bend2/comp.ts';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const sha = (bytes: string | Uint8Array) => createHash('sha256').update(bytes).digest('hex');

type Options = {
  out: string; receipt: string; sizes: number[]; literalSizes: number[];
  families: string[]; maxDefs: number; maxElements: number;
  reportLimitUnits: number; caseTimeoutMs: number;
};
type Sample = {
  stage: string; name: string; ms: number; heapUsed: number; heapTotal: number;
  rss: number; segments?: number; spins?: number; ownFacts?: number;
  hotFacts?: number; staticFacts?: number; retainedHigher?: number; memos?: number;
};
type Progress = {
  stage: string; ms: number; releases: number; prepares: number;
  segments: number; heapUsed: number;
};
type CaseSpec = {
  family: string; defs: number; sourcePath: string; sourceSha256: string;
  sourceBytes: number; reportLimitUnits: number;
};
type CaseResult = {
  family: string; defs: number; status: string;
  sourcePath: string; sourceSha256: string; sourceBytes: number;
  compileWallMs: number; loadWallMs: number; validWallMs: number;
  emittedUnits: number; emittedLines: number; emittedSegments: number;
  emittedSpins: number; emittedSha256: string;
  passes: number; phaseBoundaries: Sample[]; lastProgress: Progress | null;
  prepareBefore: number; prepareAfter: number; definitions: number;
  releases: number; spinsEmitted: number; lastSegments: number; lastSpins: number;
  lastOwn: number; lastHot: number; lastStatic: number;
  sampledMaxHeapUsed: number; sampledMaxRss: number; baselineHeapUsed: number;
  heapSizeLimit: number; workerLimits: {stackSizeMb: number; maxOldGenerationSizeMb: number};
  samples?: Sample[]; error?: string;
};

function options(): Options {
  const values = new Map<string, string>();
  for (const argument of process.argv.slice(2)) {
    const at = argument.indexOf('=');
    const name = at < 0 ? argument : argument.slice(0, at);
    const value = at < 0 ? undefined : argument.slice(at + 1);
    if (!['--out', '--receipt', '--sizes', '--literal-sizes', '--families',
      '--max-defs', '--max-elements', '--report-limit-units',
      '--case-timeout-ms'].includes(name)
      || value === undefined || values.has(name))
      throw Error('expected a unique --out/--receipt/--sizes/--literal-sizes/--families/--max-defs/--max-elements/--report-limit-units/--case-timeout-ms option, observed ' + argument);
    values.set(name, value);
  }
  const integer = (text: string, name: string, min: number, max: number) => {
    const value = Number(text);
    if (!Number.isSafeInteger(value) || value < min || value > max)
      throw Error(name + ' must be an integer between ' + String(min) + ' and ' + String(max));
    return value;
  };
  const familyList = (text: string) => text.split(',').filter(Boolean).map((x) => {
    if (!/^[a-z]+$/.test(x)) throw Error('families has an unexpected entry ' + x);
    return x;
  });
  if (!values.has('--out') || !values.has('--receipt'))
    throw Error('both --out and --receipt are required');
  return {
    out: resolve(values.get('--out')!),
    receipt: resolve(values.get('--receipt')!),
    sizes: (values.get('--sizes') ?? '8,16,32,64').split(',').filter(Boolean)
      .map((x) => integer(x, 'sizes', 2, 64)),
    literalSizes: (values.get('--literal-sizes') ?? '1000,4000,16000').split(',')
      .filter(Boolean).map((x) => integer(x, 'literal-sizes', 16, 65536)),
    families: familyList(values.get('--families') ?? 'chain,linear'),
    maxDefs: integer(values.get('--max-defs') ?? '64', 'max-defs', 2, 64),
    maxElements: integer(values.get('--max-elements') ?? '16384', 'max-elements', 16, 65536),
    reportLimitUnits: integer(values.get('--report-limit-units') ?? '67108864',
      'report-limit-units', 1024, 268435456),
    caseTimeoutMs: integer(values.get('--case-timeout-ms') ?? '60000', 'case-timeout-ms', 1000, 120000),
  };
}

// Both families share the same arithmetic and IO.pure prefix in every non-leaf
// definition and the same leaf. The only structural difference is where the
// identical call c_next(z) sits: the do-block continuation (chain, one site and
// tail, so emit_body's once path inlines it) or a do binding followed by the
// unit action (linear, a device jump, never inlined). The linear body carries
// one extra trivial IO.pure(Unit, Unit{}) action; nothing prints per definition
// in either family, so emitted printing work is matched.
function familySource(family: string, defs: number): string {
  if (family === 'literal') {
    // One independently typed pure main whose body is a single wide literal.
    // `defs` is the element count here; the ADT is Base's List<Nat>, so the
    // checked body holds one constructor node per element and no calls.
    const items = Array.from({length: defs}, (_, i) => String(i) + 'n');
    return 'import Base\n\ndef main() -> List<Nat>:\n  [' + items.join(', ') + ']\n';
  }
  if (family !== 'chain' && family !== 'linear')
    throw Error('unknown family ' + family);
  const out = ['import Base', ''];
  for (let i = defs - 1; i >= 0; i -= 1) {
    out.push(`def c_${i}(x: U32) -> IO(Unit):`, '  do IO<Unit>:',
      '    y : U32 <- IO.pure(U32, U32.add(x, 1))',
      '    z : U32 <- IO.pure(U32, y)');
    if (i + 1 < defs) {
      if (family === 'chain') out.push(`    c_${i + 1}(z)`);
      else out.push('    Unit <- c_' + String(i + 1) + '(z)',
        '    IO.pure(Unit, Unit{})');
    } else {
      out.push('    IO.print(U32.show(z))');
    }
    out.push('');
  }
  out.push('def main() -> IO(Unit):', '  c_0(0)');
  return out.join('\n') + '\n';
}

// The compiler's own optional observe state, so the callback cannot drift.
type ObserveState = Parameters<NonNullable<Compiler.JSOptions['observe']>>[2];

function stateOf(state: ObserveState) {
  const memos = state.memos ? Object.values(state.memos)
    .reduce((a, b) => a + b, 0) : undefined;
  return {
    segments: state.segments, spins: state.spins, ownFacts: state.ownFacts,
    hotFacts: state.hotFacts, staticFacts: state.staticFacts,
    retainedHigher: state.retainedHigher, memos,
  };
}

async function runCase(spec: CaseSpec): Promise<CaseResult> {
  const result: CaseResult = {
    family: spec.family, defs: spec.defs, status: 'started',
    sourcePath: spec.sourcePath, sourceSha256: spec.sourceSha256,
    sourceBytes: spec.sourceBytes, compileWallMs: 0, loadWallMs: 0,
    validWallMs: 0, emittedUnits: 0, emittedLines: 0, emittedSegments: 0,
    emittedSpins: 0, emittedSha256: '', passes: 0, phaseBoundaries: [],
    lastProgress: null, prepareBefore: 0,
    prepareAfter: 0, definitions: 0, releases: 0, spinsEmitted: 0,
    lastSegments: 0, lastSpins: 0, lastOwn: 0, lastHot: 0, lastStatic: 0,
    sampledMaxHeapUsed: 0, sampledMaxRss: 0, baselineHeapUsed: 0,
    heapSizeLimit: v8.getHeapStatistics().heap_size_limit,
    workerLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072},
    samples: [],
  };
  const samples: Sample[] = [];
  let compileStarted = 0;
  let kernel: typeof Bend | undefined;
  const post = (message: unknown) => parentPort?.postMessage(message);
  const progress = (event: Progress) => {
    result.lastProgress = event;
    result.releases = Math.max(result.releases, event.releases);
    result.prepareBefore = Math.max(result.prepareBefore, event.prepares);
    result.lastSegments = Math.max(result.lastSegments, event.segments);
    post({type: 'case-progress', family: spec.family, defs: spec.defs, event});
  };
  try {
    // Dynamic on purpose: module evaluation and its heap must belong to this
    // supervised worker (the launcher also parses this file before the gate).
    kernel = await import('../bend2/bend.ts') as typeof Bend;
    const compiler = await import('../bend2/comp.ts') as typeof Compiler;
    result.baselineHeapUsed = process.memoryUsage().heapUsed;
    const book = kernel.book_nil();
    let started = performance.now();
    await kernel.book_load(book, spec.sourcePath, '', new Map());
    result.loadWallMs = performance.now() - started;
    started = performance.now();
    kernel.book_valid(book);
    result.validWallMs = performance.now() - started;
    for (const tld of Object.values(book.tlds))
      if (tld.$ === 'Def' && tld.v !== null) result.definitions += 1;

    compileStarted = performance.now();
    const t0 = compileStarted;
    let lastProgressAt = 0;
    const observe = (stage: string, name: string, state: ObserveState = {}) => {
      if (stage === 'prepare-before') result.prepareBefore += 1;
      else if (stage === 'prepare-after') result.prepareAfter += 1;
      else if (stage === 'release-after') result.releases += 1;
      else if (stage === 'c-spin-before') result.spinsEmitted += 1;
      const memory = process.memoryUsage();
      result.sampledMaxHeapUsed = Math.max(result.sampledMaxHeapUsed, memory.heapUsed);
      result.sampledMaxRss = Math.max(result.sampledMaxRss, memory.rss);
      const pass = /^(c-reachability|c-pass-(\d+))-(before|after)$/.exec(stage);
      const row: Sample = {
        stage, name, ms: performance.now() - t0, heapUsed: memory.heapUsed,
        heapTotal: memory.heapTotal, rss: memory.rss, ...stateOf(state),
      };
      if (pass === null) {
        if (stage === 'release-after') {
          samples.push(row);
          if (result.releases - lastProgressAt >= 8) {
            lastProgressAt = result.releases;
            progress({stage, ms: row.ms, releases: result.releases,
              prepares: result.prepareBefore, segments: state.segments ?? 0,
              heapUsed: memory.heapUsed});
          }
        }
        return;
      }
      samples.push(row);
      result.phaseBoundaries.push(row);
      if (pass[2] !== undefined && pass[3] === 'after') {
        result.passes = Math.max(result.passes, Number(pass[2]));
        result.lastSegments = state.segments ?? result.lastSegments;
        result.lastSpins = state.spins ?? result.lastSpins;
        result.lastOwn = state.ownFacts ?? result.lastOwn;
        result.lastHot = state.hotFacts ?? result.lastHot;
        result.lastStatic = state.staticFacts ?? result.lastStatic;
      }
      post({type: 'case-boundary', family: spec.family, defs: spec.defs, boundary: row});
    };
    const c = compiler.compile_book(book, {observe});
    result.compileWallMs = performance.now() - t0;
    result.emittedUnits = c.length;
    const lines = c.split('\n');
    result.emittedLines = lines.length;
    let cases = 0;
    for (const line of lines) {
      if (line.startsWith('  WL_CASE(')) cases += 1;
      else if (line.startsWith('INLINE Term spin_')
        || line.startsWith('DFAR Term spin_')) result.emittedSpins += 1;
    }
    // The runtime switch also fixes FID_ENTER, FID_IO_EMIT, FID_CLO_APPLY and
    // FID_EXIT as WL_CASE arms; only compile_book's own segments are counted.
    result.emittedSegments = Math.max(0, cases - 4);
    result.emittedSha256 = sha(c);
    result.samples = samples;
    // This is a report limit on the returned string, not an emit or allocation
    // bound: compile_book has already finished and the whole C already exists.
    result.status = c.length > spec.reportLimitUnits
      ? 'REPORT_LIMIT_EXCEEDED' : 'COMPLETED';
  } catch (error) {
    result.status = 'FAILED';
    result.error = kernel && error && typeof error === 'object' && '$' in error && error.$ === 'Err'
      ? kernel.err_show(error as Bend.Err)
      : error instanceof Error ? error.message : String(error);
    result.compileWallMs = compileStarted === 0 ? 0 : performance.now() - compileStarted;
    result.samples = samples;
  }
  return result;
}

function emptyCase(spec: CaseSpec, status: string, error: string,
  phaseBoundaries: Sample[] = [], lastProgress: Progress | null = null): CaseResult {
  return {
    family: spec.family, defs: spec.defs, status, sourcePath: spec.sourcePath,
    sourceSha256: spec.sourceSha256, sourceBytes: spec.sourceBytes,
    compileWallMs: 0, loadWallMs: 0, validWallMs: 0, emittedUnits: 0,
    emittedLines: 0, emittedSegments: 0, emittedSpins: 0, emittedSha256: '', passes: 0,
    phaseBoundaries, lastProgress, prepareBefore: 0, prepareAfter: 0,
    definitions: 0, releases: 0, spinsEmitted: 0, lastSegments: 0, lastSpins: 0,
    lastOwn: 0, lastHot: 0, lastStatic: 0, sampledMaxHeapUsed: 0,
    sampledMaxRss: 0, baselineHeapUsed: 0,
    heapSizeLimit: v8.getHeapStatistics().heap_size_limit,
    workerLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072}, error,
  };
}

function isCaseResult(value: unknown): value is CaseResult {
  return value !== null && typeof value === 'object'
    && 'status' in value && typeof value.status === 'string'
    && 'family' in value && typeof value.family === 'string'
    && 'defs' in value && typeof value.defs === 'number';
}

function isSample(value: unknown): value is Sample {
  return value !== null && typeof value === 'object'
    && 'stage' in value && typeof value.stage === 'string'
    && 'heapUsed' in value && typeof value.heapUsed === 'number';
}

function isProgress(value: unknown): value is Progress {
  return value !== null && typeof value === 'object'
    && 'ms' in value && typeof value.ms === 'number'
    && 'releases' in value && typeof value.releases === 'number';
}

function runCaseInWorker(spec: CaseSpec, timeoutMs: number): Promise<CaseResult> {
  const {promise, resolve: resolveCase} = Promise.withResolvers<CaseResult>();
  const worker = new Worker(new URL(import.meta.url), {
    workerData: {__reproNativePass1: true, spec},
    resourceLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072},
  });
  const boundaries: Sample[] = [];
  let lastProgress: Progress | null = null;
  let exited = false;
  let settled = false;
  const exitPromise = Promise.withResolvers<void>();
  worker.once('exit', () => {
    exited = true;
    exitPromise.resolve();
  });
  const finish = (build: () => CaseResult) => {
    if (settled) return;
    settled = true;
    clearTimeout(timer);
    // Never start the next case until this worker is really gone. A worker
    // that posted its result usually exits on its own; terminate only after a
    // short grace so a normal result is not turned into a forced kill.
    void (async () => {
      if (!exited) await Promise.race([exitPromise.promise, delay(2000)]);
      if (!exited) {
        await worker.terminate().catch(() => {});
        await exitPromise.promise;
      }
      resolveCase(build());
    })();
  };
  const timer = setTimeout(() => finish(() => emptyCase(spec, 'CASE_TIMEOUT',
    'case exceeded ' + String(timeoutMs) + ' ms; last ' + String(boundaries.length)
    + ' pass boundaries retained', boundaries.slice(-8), lastProgress)), timeoutMs);
  worker.on('message', (message: unknown) => {
    if (message === null || typeof message !== 'object' || !('type' in message)) return;
    if (message.type === 'case-boundary' && 'boundary' in message && isSample(message.boundary)) {
      boundaries.push(message.boundary);
      if (boundaries.length > 16) boundaries.shift();
      return;
    }
    if (message.type === 'case-progress' && 'event' in message && isProgress(message.event)) {
      lastProgress = message.event;
      return;
    }
    if (message.type === 'case-result' && 'result' in message && isCaseResult(message.result)) {
      const terminal = message.result;
      finish(() => terminal);
    }
  });
  worker.once('error', (error) => finish(() => emptyCase(spec, 'WORKER_FAILED',
    (error instanceof Error ? error.message : String(error)) + '; retained '
    + String(boundaries.length) + ' phase boundaries', boundaries.slice(-8), lastProgress)));
  worker.once('exit', (code) => finish(() => emptyCase(spec,
    'WORKER_EXIT_' + String(code), 'worker exited ' + String(code)
    + ' without a result; retained ' + String(boundaries.length)
    + ' pass boundaries', boundaries.slice(-8), lastProgress)));
  return promise;
}

function summarize(result: CaseResult) {
  return {
    family: result.family, defs: result.defs, status: result.status,
    compileWallMs: +result.compileWallMs.toFixed(1),
    loadWallMs: +result.loadWallMs.toFixed(1), validWallMs: +result.validWallMs.toFixed(1),
    emittedUnits: result.emittedUnits, emittedLines: result.emittedLines,
    emittedSegments: result.emittedSegments, emittedSpins: result.emittedSpins,
    emittedSha256: result.emittedSha256, passes: result.passes,
    definitions: result.definitions, prepares: result.prepareBefore,
    releases: result.releases, spinsEmitted: result.spinsEmitted,
    lastSegments: result.lastSegments, lastSpins: result.lastSpins,
    lastOwn: result.lastOwn, lastHot: result.lastHot, lastStatic: result.lastStatic,
    sizeUnit: result.family === 'literal' ? 'list elements' : 'definitions',
    baselineHeapUsed: result.baselineHeapUsed,
    sampledMaxHeapUsed: result.sampledMaxHeapUsed, sampledMaxRss: result.sampledMaxRss,
    heapSizeLimit: result.heapSizeLimit,
    lastProgress: result.lastProgress,
    phaseBoundaries: result.phaseBoundaries.map((row) => ({
      stage: row.stage, ms: +row.ms.toFixed(1), heapUsed: row.heapUsed,
      rss: row.rss, segments: row.segments, spins: row.spins,
      ownFacts: row.ownFacts, hotFacts: row.hotFacts, staticFacts: row.staticFacts,
      retainedHigher: row.retainedHigher,
    })),
    sourceSha256: result.sourceSha256, sourceBytes: result.sourceBytes,
    sourcePath: result.sourcePath, error: result.error ?? null,
  };
}

async function main() {
  const o = options();
  const specs: CaseSpec[] = [];
  const inputDirectory = mkdtempSync(join(tmpdir(), 'bend-repro-pass1-inputs-'));
  for (const family of o.families) {
    const sizes = family === 'literal' ? o.literalSizes : o.sizes;
    const limit = family === 'literal' ? o.maxElements : o.maxDefs;
    for (const defs of sizes) {
      if (defs > limit) throw Error('size ' + String(defs) + ' exceeds --max-defs/--max-elements');
      const source = familySource(family, defs);
      const sourcePath = join(inputDirectory, family + '-' + String(defs) + '.bend');
      writeFileSync(sourcePath, source);
      specs.push({family, defs, sourcePath, sourceSha256: sha(source),
        sourceBytes: Buffer.byteLength(source), reportLimitUnits: o.reportLimitUnits});
    }
  }
  mkdirSync(dirname(o.out), {recursive: true});
  mkdirSync(dirname(o.receipt), {recursive: true});
  const started = performance.now();
  const results: CaseResult[] = [];
  for (const spec of specs) {
    if (performance.now() - started > 480000) {
      results.push(emptyCase(spec, 'SKIPPED_GLOBAL_DEADLINE', 'global diagnostic deadline reached'));
      continue;
    }
    const result = await runCaseInWorker(spec, o.caseTimeoutMs);
    console.log('REPRO_PASS1_CASE ' + JSON.stringify(summarize(result)));
    results.push(result);
  }
  const summaries = results.map(summarize);
  const failed = results.filter((r) => r.status !== 'COMPLETED'
    && r.status !== 'REPORT_LIMIT_EXCEEDED');
  const receipt = {
    schemaVersion: 1,
    kind: 'native-pass1-diagnostic-repro-receipt',
    diagnosticOnly: true,
    acceptanceEvidence: false,
    status: results.some((r) => r.status === 'COMPLETED'
      || r.status === 'REPORT_LIMIT_EXCEEDED') ? 'DIAGNOSTIC_COMPLETE' : 'DIAGNOSTIC_FAILED',
    failureClass: failed.length === 0 ? null
      : failed.map((r) => r.status + ':' + r.family + ':' + String(r.defs)),
    reportLimit: {kind: 'POST_GENERATION_REPORT_LIMIT', units: o.reportLimitUnits,
      note: 'Checked on the returned C string after compile_book finished; it is not an '
        + 'emit bound, an allocation bound or a preventive memory guard.'},
    measurement: {
      heap: 'worker-isolate heapUsed sample at every observe event; sampledMaxHeapUsed is the '
        + 'maximum of those samples, not a continuous, live or retained peak',
      rss: 'process RSS at the same events; sampledMaxRss is a sample maximum, not a footprint peak',
      retained: 'boundary rows are samples; none is a retained-byte measurement',
      passBoundary: 'c-pass-N-before is sampled before compile_book resets the pass caches, so '
        + 'pass 1 shows the fresh state and later passes show the previous pass retained state; '
        + 'c-pass-N-after shows what pass N left behind.',
    },
    note: 'Generated minimal families through the real book_load/book_valid/compile_book path. '
      + 'Phase-only boundaries are posted to the parent before the next compile step, so an '
      + 'aborted worker still contributes its input pin and reached pass boundary. '
      + 'No acceptance corpus, export set or matrix case is replaced by these diagnostics.',
    guard: {
      entry: 'guardHeavyGate',
      memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000,
      workerLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072},
      internalBypass: false,
    },
    runtime: {
      name: process.release.name, node: process.versions.node, v8: process.versions.v8,
      execPath: process.execPath, execArgv: [...process.execArgv],
    },
    sourceBindings: {
      'evals/repro_native_pass1.ts': sha(readFileSync(fileURLToPath(import.meta.url))),
      'bend2/bend.ts': sha(readFileSync(join(root, 'bend2/bend.ts'))),
      'bend2/comp.ts': sha(readFileSync(join(root, 'bend2/comp.ts'))),
      'evals/heavy_gate.ts': sha(readFileSync(join(root, 'evals/heavy_gate.ts'))),
    },
    bounds: {sizes: o.sizes, literalSizes: o.literalSizes, families: o.families,
      maxDefs: o.maxDefs, maxElements: o.maxElements,
      caseTimeoutMs: o.caseTimeoutMs, inputDirectory,
      sizeUnits: {chain: 'definitions', linear: 'definitions', literal: 'list elements'}},
    cases: summaries,
    totalWallMs: performance.now() - started,
  };
  writeFileSync(o.out, JSON.stringify({...receipt,
    cases: results.map((r) => ({...summarize(r), samples: r.samples}))}, null, 2) + '\n');
  writeFileSync(o.receipt, JSON.stringify(receipt) + '\n');
  console.log('REPRO_PASS1_SUMMARY ' + JSON.stringify({
    status: receipt.status, cases: summaries.length, out: o.out, receipt: o.receipt,
    totalWallMs: +receipt.totalWallMs.toFixed(1),
  }));
}

// workerData is `any` in node:worker_threads; every field is validated below.
const workerInput = workerData as {__reproNativePass1?: unknown; spec?: unknown} | null;
const workerSpec = workerInput?.spec;
const isWorkerEntry = !isMainThread && workerInput?.__reproNativePass1 === true
  && workerSpec !== undefined && workerSpec !== null && typeof workerSpec === 'object'
  && 'family' in workerSpec && typeof workerSpec.family === 'string'
  && 'defs' in workerSpec && typeof workerSpec.defs === 'number'
  && 'sourcePath' in workerSpec && typeof workerSpec.sourcePath === 'string'
  && 'sourceSha256' in workerSpec && typeof workerSpec.sourceSha256 === 'string'
  && 'sourceBytes' in workerSpec && typeof workerSpec.sourceBytes === 'number'
  && 'reportLimitUnits' in workerSpec && typeof workerSpec.reportLimitUnits === 'number';
const isEntry = Boolean(process.argv[1]) && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMainThread && isEntry) {
  if (typeof process.versions.bun === 'string') {
    console.error('native pass-1 repro requires Node/V8 with --experimental-strip-types; Bun/JSC does not enforce Worker resourceLimits');
    process.exit(2);
  }
  if (!process.execArgv.includes('--experimental-strip-types'))
    process.env.NODE_OPTIONS = ('--experimental-strip-types ' + (process.env.NODE_OPTIONS ?? '')).trim();
  process.env.HEAVY_GATE_MEMORY_MIB = '8192';
  process.env.HEAVY_GATE_RSS_MIB = '8192';
  process.env.HEAVY_GATE_POLL_MS = '10';
  process.env.HEAVY_GATE_TIMEOUT_MS = '600000';
  await guardHeavyGate(fileURLToPath(import.meta.url), {label: 'Native c-pass-1 diagnostic repro'});
  await main();
} else if (isWorkerEntry && workerSpec) {
  // isWorkerEntry validated every field the worker consumes.
  const spec = workerSpec as CaseSpec;
  try {
    parentPort!.postMessage({type: 'case-result', result: await runCase(spec)});
  } catch (error) {
    parentPort!.postMessage({type: 'case-result', result: emptyCase(spec, 'FAILED',
      error instanceof Error ? error.message : String(error))});
  }
}
