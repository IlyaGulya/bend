#!/usr/bin/env bun
/** Measurement only: the restored historical algorithm, with one entry observer.
 * Removing ENTRY from the temporary module reproduces the frozen source byte for
 * byte. The observer never changes m, vars, patterns, bodies or fresh identities;
 * its only control effect is throwing at the explicitly reported diagnostic cap.
 * Stack traces supply return-aware ancestry without adding exit/branch hooks.
 */
import * as B from '../bend2/bend.ts';
import {createHash, randomUUID} from 'node:crypto';
import {mkdirSync, rmSync, writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {guardHeavyGate} from './heavy_gate.ts';
import {readParserGraph} from './parser_full_graph.ts';
import type {ParserParameter} from './parser_full_graph.ts';

const frozen = {
  'bend2/bend.ts': '47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
  'bend2/selfhost/parser.bend': 'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend': 'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
  'evals/parser_full_generate.ts': '0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6',
};
const sha = (text: string) => createHash('sha256').update(text).digest('hex');
async function hashGuard() {
  const hashes: Record<string, string> = {};
  for (const [path, expected] of Object.entries(frozen)) {
    hashes[path] = sha(await Bun.file(path).text());
    if (hashes[path] !== expected) throw Error('Frozen input drift: ' + path);
  }
  return hashes;
}
const thresholds = [1024, 4096, 16384, 65536, 131072];
const FRESH_CAP = 131072, TIME_CAP_MS = 60000;
class Cutoff extends Error {
  constructor(readonly reason: string) { super(reason); }
}
const termKinds: Record<string, true> = {Var: true, Ref: true, Sub: true, Let: true, Typ: true, Qnt: true, Qua: true, Min: true, All: true, Lam: true, App: true, ADT: true, Ctr: true, Mat: true, Efq: true, Eql: true, Rfl: true, Rwt: true, Hol: true, Ann: true};
/** Counts identities, not expanded occurrences; arrays count, spans do not. */
function countGraph(root: unknown, check: () => void = () => {}) {
  const seen = new Set<object>(), pending = [root];
  const kinds: Record<string, number> = {};
  let arrays = 0, termNodes = 0, callbacks = 0, maxBinder = -1;
  while (pending.length) {
    if ((seen.size & 255) === 0) check();
    const value = pending.pop();
    if (typeof value === 'function') { callbacks++; continue; }
    if (!value || typeof value !== 'object' || seen.has(value)) continue;
    seen.add(value);
    if (Array.isArray(value)) arrays++;
    const node = value as Record<string, unknown>;
    if (typeof node.$ === 'string' && Object.hasOwn(termKinds, node.$)) {
      termNodes++; kinds[node.$] = (kinds[node.$] ?? 0) + 1;
    }
    for (const [key, child] of Object.entries(node)) {
      if (key === 's') continue;
      if (key === 'i' && typeof child === 'number') maxBinder = Math.max(maxBinder, child);
      if (key === 'i' && Array.isArray(child)) for (const i of child) if (typeof i === 'number') maxBinder = Math.max(maxBinder, i);
      pending.push(child);
    }
  }
  return {uniqueObjects: seen.size, arrays, termNodes, Sub: kinds.Sub ?? 0, Lam: kinds.Lam ?? 0, Mat: kinds.Mat ?? 0, kinds, callbacks, maxBinder};
}
function permute<T>(items: readonly T[], a: number, b: number): T[] {
  const out = [...items]; [out[a], out[b]] = [items[b], items[a]]; return out;
}
function assertPermutation<T>(original: readonly T[], changed: readonly T[], a: number, b: number) {
  if (original.length !== changed.length || changed.some((item, i) => item !== original[i === a ? b : i === b ? a : i])) throw Error('Permutation identity drift');
}
function swappedMatrix(body: B.Match): B.Match {
  if (body.e.length !== 2 || body.r.some(row => row.p.length !== 2)) throw Error('Expected exact two-column matrix');
  const matrix: B.Match = {...body, e: permute(body.e, 0, 1), r: body.r.map(row => ({p: permute(row.p, 0, 1), f: row.f}))};
  assertPermutation(body.e, matrix.e, 0, 1);
  for (let i = 0; i < body.r.length; i++) {
    assertPermutation(body.r[i].p, matrix.r[i].p, 0, 1);
    if (matrix.r[i].f !== body.r[i].f) throw Error('Row body identity drift');
  }
  if (matrix.s !== body.s) throw Error('Matrix span drift');
  return matrix;
}
type ColumnComposition = {
  column: number; scrutinee: {kind: string; i?: number | number[]; k?: string | string[]};
  Ctr: number; PVar: number; distinctConstructors: string[]; constructors: Record<string, number>;
};
function composition(m: B.Match): ColumnComposition[] {
  return m.e.map((scrutinee, column) => {
    const constructors: Record<string, number> = {};
    let Ctr = 0, PVar = 0;
    for (const row of m.r) {
      const p = row.p[column];
      if (p?.$ === 'PCtr') { Ctr++; constructors[p.k] = (constructors[p.k] ?? 0) + 1; }
      else if (p?.$ === 'PVar') PVar++;
      else throw Error('Malformed recursive matrix');
    }
    return {column, scrutinee: {kind: scrutinee.$, ...('i' in scrutinee ? {i: scrutinee.i} : {}), ...('k' in scrutinee ? {k: scrutinee.k} : {})}, Ctr, PVar, distinctConstructors: Object.keys(constructors).sort(), constructors};
  });
}
type State = {
  entry: number; depth: number; parent: number | null; freshBinders: number; elapsedMs: number;
  rows: number; columns: number; variables: number; firstColumn: ColumnComposition | null;
  perColumn: ColumnComposition[]; vars: {i: number; k: string; q: B.Quant}[];
  rowPatterns: {kind: 'PVar' | 'PCtr'; k: string; i?: number; q?: B.Quant; arity?: number}[][];
  recursionStack: string[]; path: number[]; edge: string;
};
type Occurrence = {key: string; occurrences: number; firstEntry: number; lastEntry: number; firstFresh: number; lastFresh: number; firstState: State};
class StateObserver {
  entries = 0;
  lastActive: State | null = null;
  firstRepeated: {state: State; previous: State} | null = null;
  firstGrowing: {state: State; previous: State; evidence: string} | null = null;
  firstRepeatedGrowing: {state: State; previous: State; evidence: string} | null = null;
  firstThresholdState: State | null = null;
  readonly histogram = new Map<string, Occurrence>();
  private currentM: B.Match | null = null;
  private currentVars: B.PVar[] | null = null;
  constructor(readonly freshCount: () => number, readonly elapsed: () => number, readonly check: () => void) {}
  enter = (m: B.Match, vars: B.PVar[]) => {
    this.entries++;
    this.currentM = m; this.currentVars = vars;
    this.check();
    // Full state/stack snapshots are sampled, never allocated for every call.
    if (this.entries === 1 || (this.entries & 1023) === 0) this.capture();
  };
  capture() {
    if (!this.currentM || !this.currentVars) return;
    const m = this.currentM, vars = this.currentVars;
    const frames = (new Error().stack ?? '').split('\n').filter(line => /\bmatch_flatten\b/.test(line));
    const perColumn = composition(m);
    const state: State = {entry: this.entries, depth: frames.length, parent: null, freshBinders: this.freshCount(), elapsedMs: this.elapsed(), rows: m.r.length, columns: m.e.length, variables: vars.length,
      firstColumn: perColumn[0] ?? null, perColumn, vars: vars.map(({i, k, q}) => ({i, k, q})),
      rowPatterns: m.r.map(row => row.p.map(p => p.$ === 'PVar' ? {kind: p.$, k: p.k, i: p.i, q: p.q} : {kind: p.$, k: p.k, arity: p.x.length})),
      recursionStack: frames, path: [], edge: frames[1] ?? 'root'};
    this.lastActive = state;
    const key = JSON.stringify([state.rows, state.columns, state.variables, perColumn.map(c => [c.Ctr, c.PVar, c.distinctConstructors.map(k => [k, c.constructors[k]])])]);
    const previous = this.histogram.get(key);
    if (previous) {
      previous.occurrences++; previous.lastEntry = state.entry; previous.lastFresh = state.freshBinders;
      this.firstRepeated ??= {state, previous: previous.firstState};
      if (state.freshBinders > previous.firstFresh) {
        const evidence = {state, previous: previous.firstState, evidence: 'Repeated sampled shallow composition after more fresh binders; not exact state equality or ancestor identity'};
        this.firstGrowing ??= evidence; this.firstRepeatedGrowing ??= evidence;
      }
    } else this.histogram.set(key, {key, occurrences: 1, firstEntry: state.entry, lastEntry: state.entry, firstFresh: state.freshBinders, lastFresh: state.freshBinders, firstState: state});
  }
  snapshot() {
    this.capture();
    return {entries: this.entries, lastActive: this.lastActive, activePath: [], firstRepeated: this.firstRepeated, firstGrowing: this.firstGrowing, firstRepeatedGrowing: this.firstRepeatedGrowing, sampling: 'Every 1024 entries plus thresholds/cutoff; native stack recorded, logical parent path deliberately not inferred'};
  }
  occurrences() { return [...this.histogram.values()].sort((a, b) => b.occurrences - a.occurrences); }
}
const ANCHOR = 'export function match_flatten(m: Match, vars: PVar[], fr: () => number): LTerm {\n';
const ENTRY = '  (globalThis as typeof globalThis & {__stage0_column_order_entry: (m: Match, vars: PVar[]) => void}).__stage0_column_order_entry(m, vars);\n';
function instrument(source: string) {
  if (source.split(ANCHOR).length !== 2) throw Error('Observer anchor is not unique');
  const observed = source.replace(ANCHOR, ANCHOR + ENTRY);
  if (observed.replace(ENTRY, '') !== source) throw Error('Observer changed historical algorithm');
  return observed;
}

await guardHeavyGate(import.meta.path, {label: 'stage0-column-order-real'});
const variant = process.argv[2];
if ((variant !== 'original' && variant !== 'swapped') || process.argv.length !== 3) throw Error('Usage: bun evals/stage0_column_order_real.ts original|swapped');
mkdirSync('checkpoints', {recursive: true});
const outputPath = `checkpoints/stage0-column-order-real-${variant}.json`;
const progressPath = `checkpoints/stage0-column-order-real-${variant}.progress.json`;
const checkpoints: object[] = [];
const progress = (phase: string, extra: object = {}) => writeFileSync(progressPath, JSON.stringify({variant, phase, ...extra}) + '\n');
let temporary: string | undefined;
let observer: StateObserver | undefined;
let temporaryKernelRemoved = true;
let result: Record<string, unknown> = {variant, complete: false, counts: 'UNKNOWN', frozenInputs: frozen, freshCeiling: FRESH_CAP, elapsedCeilingMs: TIME_CAP_MS};
const registry = globalThis as typeof globalThis & {__stage0_column_order_entry?: (m: B.Match, vars: B.PVar[]) => void};
const stackError = Error as ErrorConstructor & {stackTraceLimit: number};
const previousStackLimit = stackError.stackTraceLimit;
try {
  result.hashesBefore = await hashGuard();
  const source = await Bun.file('bend2/bend.ts').text();
  if (sha(source) !== frozen['bend2/bend.ts']) throw Error('Frozen production changed before instrumentation');
  progress('raw-graph-load');
  const graph = await readParserGraph(await Bun.file('bend2/selfhost/parser.bend').text());
  const body = graph.bodies.get('pattern_scan'), signature = graph.signatures.get('pattern_scan');
  if (!body || body.$ !== 'Match' || body.r.length !== 20 || !signature) throw Error('Missing frozen real twenty-row matrix');
  const originalVars: B.PVar[] = signature.parameters.map(([q, k, i, , s]) => ({$: 'PVar', q, k, i, s}));
  const rawCounts = countGraph(body);
  if (rawCounts.callbacks) throw Error('Raw graph contains HOAS');
  const swapped = swappedMatrix(body);
  const positions = body.e.map(e => {
    if (e.$ !== 'Var') throw Error('Expected parameter scrutinee identity');
    const position = originalVars.findIndex(v => v.i === e.i);
    if (position < 0) throw Error('Scrutinee has no signature binder');
    return position;
  });
  if (positions[0] === positions[1]) throw Error('Duplicate scrutinee');
  const [a, b] = positions;
  const vars = variant === 'swapped' ? permute(originalVars, a, b) : originalVars;
  const parameters: ParserParameter[] = variant === 'swapped' ? permute(signature.parameters, a, b) : signature.parameters;
  if (variant === 'swapped') { assertPermutation(originalVars, vars, a, b); assertPermutation(signature.parameters, parameters, a, b); }
  // Only the external diagnostic alias changes its calling convention. Raw
  // body references (including recursion) still target the ORIGINAL function.
  // No actual-call metadata or body App AST is rewritten or installed.
  const originalProbeArguments = originalVars.map(v => B.Var(v.k, v.i, v.s));
  const probeArguments = variant === 'swapped' ? permute(originalProbeArguments, a, b) : originalProbeArguments;
  if (variant === 'swapped') assertPermutation(originalProbeArguments, probeArguments, a, b);
  const initial = Math.max(rawCounts.maxBinder, ...originalVars.map(v => v.i)) + 1;
  let diagnosticFresh = 0;
  const diagnosticStart = performance.now();
  let columnOnly: object;
  try {
    const term = B.body_flatten(swapped, originalVars, () => {
      if (diagnosticFresh >= 256 || performance.now() - diagnosticStart >= 100) throw new Cutoff('cheap-column-only-budget');
      return initial + diagnosticFresh++;
    });
    columnOnly = {status: 'UNEXPECTED_COMPLETE', term: B.term_show(term), originalVars: originalVars.map(v => ({k: v.k, i: v.i})), freshBinders: diagnosticFresh};
  } catch (error) {
    const message = error && typeof error === 'object' && '$' in error && error.$ === 'Err' ? B.err_show(error as B.Err) : String(error);
    columnOnly = {status: message.includes('consumed binder') ? 'CONSUMED_BINDER_REJECTION' : error instanceof Cutoff ? 'BOUNDED_UNKNOWN' : 'OTHER_REJECTION', message, freshBinders: diagnosticFresh, elapsedMs: performance.now() - diagnosticStart, originalVars: originalVars.map(v => ({k: v.k, i: v.i}))};
  }
  console.log(JSON.stringify({event: 'column-only-original-vars', variant, ...columnOnly}));
  result = {...result, rawCounts, matrixRows: 20, permutation: {columnSwap: variant === 'swapped' ? [0, 1] : null, signaturePositions: positions, vars: vars.map(v => ({k: v.k, i: v.i, q: v.q})), parameters: parameters.map(([q, k, i]) => ({q, k, i})), probeArguments: probeArguments.map(x => ({kind: x.$, ...('i' in x ? {i: x.i} : {}), ...('k' in x ? {k: x.k} : {})})), rowBodiesAndPatternsIdentical: true, untouchedSignaturePositionsIdentical: true, externalProbeArgumentsIdentityChecked: true, originalInterfacePreserved: variant === 'original', diagnosticAlias: variant === 'swapped' ? 'pattern_scan_column_swapped' : 'pattern_scan_column_original', bodyReferences: 'Unchanged; all recursive pattern_scan references still target the original ABI/function', semanticScope: 'Function-lowering column-order diagnostic, not an installed swapped recursive parser or a claim of full recursive parser equivalence'}, columnOnly};
  temporary = resolve('bend2/.stage0-column-order-' + randomUUID() + '.ts');
  await Bun.write(temporary, instrument(source));
  // This module name is runtime-selected: a unique, temporary instrumented copy.
  const kernel: typeof B = await import(temporary);
  let freshBinders = 0, thresholdIndex = 0;
  const started = performance.now();
  const elapsed = () => performance.now() - started;
  const checkTime = () => { if (elapsed() >= TIME_CAP_MS) throw new Cutoff('elapsed-ceiling'); };
  observer = new StateObserver(() => freshBinders, elapsed, checkTime);
  stackError.stackTraceLimit = 16384;
  registry.__stage0_column_order_entry = observer.enter;
  const save = () => writeFileSync(outputPath, JSON.stringify({...result, checkpoints, observer: observer!.snapshot(), occurrenceHistogram: observer!.occurrences()}, null, 2) + '\n');
  const fresh = () => {
    checkTime();
    if (freshBinders >= FRESH_CAP) throw new Cutoff('fresh-ceiling');
    const i = initial + freshBinders++;
    if (freshBinders === thresholds[thresholdIndex]) {
      const checkpoint = {event: 'fresh-threshold', variant, threshold: thresholds[thresholdIndex++], freshBinders, elapsedMs: elapsed(), ...observer!.snapshot()};
      observer!.firstThresholdState ??= observer!.lastActive;
      checkpoints.push(checkpoint);
      console.log(JSON.stringify(checkpoint));
      progress('lowering', checkpoint); save();
      checkTime();
    }
    return i;
  };
  progress('lowering', {freshBinders: 0}); save();
  let loweringStage: 'lowering' | 'counting' = 'lowering';
  try {
    const term = kernel.body_flatten(variant === 'swapped' ? swapped : body, vars, fresh);
    const loweringMs = elapsed();
    loweringStage = 'counting';
    progress('counting', {freshBinders, loweringMs});
    const counts = countGraph(term, checkTime);
    if (counts.callbacks) throw Error('Lowered graph contains HOAS');
    result = {...result, complete: true, status: 'COMPLETE', counts, freshBinders, loweringMs, elapsedMs: elapsed(), noHOAS: true};
  } catch (error) {
    observer.capture();
    const message = error && typeof error === 'object' && '$' in error && error.$ === 'Err' ? B.err_show(error as B.Err) : String(error);
    result = {...result, status: error instanceof Cutoff ? 'CUTOFF' : 'ERROR', cutoff: error instanceof Cutoff ? error.reason : null, cutoffStage: loweringStage, error: message, freshBinders, elapsedMs: elapsed(), counts: 'UNKNOWN', noHOAS: 'UNKNOWN', lastActiveAtCutoff: loweringStage === 'lowering' ? observer.lastActive : null};
  }
  result = {...result, observerEquivalence: {
    onlyInsertion: ENTRY.trim(), removingInsertionReproducesFrozenBytes: true,
    algorithm: 'Exact temporary historical copy with only an observational entry hook; constructor/body_sub/branch/exit algorithms unchanged',
    countOnlyAndStateObserverSameRun: true, fullGraphWalksPerEntry: false,
    pathMethod: 'Native stacks sampled every 1024 entries and at fresh thresholds/cutoff. Logical ancestry is not reconstructed; parent=null and path=[]',
    histogramIdentity: 'Sampled shallow composition only, not exact semantic-state identity or total occurrence count',
    firstExplodingEvidence: {operationalTrigger: 'First 1024-fresh checkpoint; identifies an early expansion state, not a mathematically established first asymptotic explosion', state: observer.firstThresholdState},
    wallTimeIncludesObserverAndCheckpointIO: true,
    wallTimeCaveat: 'Synchronous body_sub intervals have no entry/fresh callback; external heavy_gate remains mandatory'
  }};
} catch (error) {
  result = {...result, status: 'ERROR', error: String(error), counts: 'UNKNOWN'};
} finally {
  delete registry.__stage0_column_order_entry;
  stackError.stackTraceLimit = previousStackLimit;
  if (temporary) {
    try { rmSync(temporary, {force: true}); }
    catch (error) { temporaryKernelRemoved = false; result = {...result, status: 'CLEANUP_FAILED', cleanupError: String(error)}; }
  }
  try { result.hashesAfter = await hashGuard(); }
  catch (error) { result = {...result, status: 'HASH_GUARD_FAILED', complete: false, counts: 'UNKNOWN', hashGuardError: String(error)}; }
  result = {...result, checkpoints, observer: observer?.snapshot() ?? null, occurrenceHistogram: observer?.occurrences() ?? [], temporaryKernelRemoved};
  writeFileSync(outputPath, JSON.stringify(result, null, 2) + '\n');
  progress(String(result.status ?? 'ERROR'), {freshBinders: result.freshBinders ?? 0, elapsedMs: result.elapsedMs ?? 0, counts: result.counts});
  console.log(JSON.stringify({event: 'result', ...result}));
}
if (result.status !== 'COMPLETE' && result.status !== 'CUTOFF') process.exitCode = 1;
