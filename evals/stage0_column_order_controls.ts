#!/usr/bin/env bun
/** Measurement only: the function interface is permuted, not preserved. */
import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {mkdir, mkdtemp, rm, writeFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {guardHeavyGate} from './heavy_gate.ts';
import {readParserGraph} from './parser_full_graph.ts';
import type {ParserParameter, ParserGraph} from './parser_full_graph.ts';

const checkpoint = 'checkpoints/stage0-column-order-controls.json';
const frozen = {
  'bend2/bend.ts': '47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
  'bend2/selfhost/parser.bend': 'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend': 'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
  'evals/parser_full_generate.ts': '0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6',
};
const sha = (text: string) => createHash('sha256').update(text).digest('hex');
const errorText = (error: unknown) => (error as B.Err)?.$ === 'Err' ? B.err_show(error as B.Err) : String(error);
function requireThat(condition: unknown, message: string): asserts condition {
  if (!condition) throw Error(message);
}
async function checkFrozen() {
  for (const [path, expected] of Object.entries(frozen))
    requireThat(sha(await Bun.file(path).text()) === expected, 'Frozen input drift: ' + path);
}
type Bounds = {freshLimit: number; timeMs: number};
class Bound extends Error { constructor(readonly status: 'FRESH_LIMIT' | 'TIME_LIMIT') { super(status); } }
function walk(root: unknown, callback: (node: Record<string, unknown>) => void) {
  const seen = new Set<object>(), pending: unknown[] = [root];
  while (pending.length) {
    const node = pending.pop();
    if (!node || typeof node !== 'object' || seen.has(node)) continue;
    seen.add(node);
    callback(node as Record<string, unknown>);
    for (const [key, value] of Object.entries(node)) if (key !== 's') pending.push(value);
  }
  return seen;
}
function counts(root: unknown) {
  const kinds = {Sub: 0, Lam: 0, Mat: 0, Let: 0, App: 0};
  let termNodes = 0, patternNodes = 0;
  const objects = walk(root, node => {
    if (typeof node.$ !== 'string') return;
    if (node.$ === 'PVar' || node.$ === 'PCtr') patternNodes++;
    else if (!['Match', 'Reply', 'Local', 'None', 'Lone', 'Many'].includes(node.$)) termNodes++;
    if (Object.hasOwn(kinds, node.$)) kinds[node.$ as keyof typeof kinds]++;
  });
  return {objects: objects.size, termNodes, patternNodes, ...kinds, spanObjectsExcluded: true};
}
function vars(parameters: ParserParameter[]): B.PVar[] {
  return parameters.map(([q, k, i, , s]) => ({$: 'PVar', q, k, i, s}));
}
function swap<T>(xs: readonly T[]): T[] {
  requireThat(xs.length === 2, 'Exactly two columns/parameters required');
  return [xs[1], xs[0]];
}
function transpose(body: B.Match): B.Match {
  return {...body, e: swap(body.e), r: body.r.map(row => ({p: swap(row.p), f: row.f}))};
}
function rawContract(body: B.Match, parameters: ParserParameter[]) {
  requireThat(parameters.length === 2 && body.e.length === 2, 'Two-column raw fixture');
  requireThat(body.e.every((e, i) => e.$ === 'Var' && e.i === parameters[i][2]), 'Raw scrutinees must follow the telescope');
  const changed = transpose(body), back = transpose(changed);
  requireThat(back.e.every((e, i) => e === body.e[i]), 'Swap-back scrutinee identity');
  body.r.forEach((row, r) => {
    requireThat(changed.r[r].f === row.f && back.r[r].f === row.f, 'Row-body identity/order changed');
    row.p.forEach((p, c) => requireThat(changed.r[r].p[1-c] === p && back.r[r].p[c] === p, 'Pattern/ID/quantity identity changed'));
  });
  const binders: {id: number; name: string; quantity: string}[] = [];
  walk(body, node => {if (node.$ === 'PVar') binders.push({id: node.i as number, name: node.k as string, quantity: (node.q as B.Quant).$});});
  requireThat(new Set(binders.map(binder => binder.id)).size === binders.length, 'Distinct raw pattern binders must have distinct IDs');
  return {patternAndBodyObjectIdentity: true, rowOrderPreserved: true, swapBackIdentity: true,
    binderIdsDistinct: true, parameters: parameters.map(([q, k, i]) => ({id: i, name: k, quantity: q.$})), patternBinders: binders};
}
function lower(body: B.Body, parameters: ParserParameter[], bounds: Bounds) {
  let next = 0;
  walk([body, parameters], node => {if (typeof node.i === 'number') next = Math.max(next, node.i + 1);});
  // Telescope tuples carry indices as elements, not named properties.
  for (const parameter of parameters) next = Math.max(next, parameter[2] + 1);
  const initial = next, started = performance.now();
  const fresh = () => {
    if (performance.now() - started >= bounds.timeMs) throw new Bound('TIME_LIMIT');
    if (next - initial >= bounds.freshLimit) throw new Bound('FRESH_LIMIT');
    return next++;
  };
  try {
    const term = B.body_flatten(body, vars(parameters), fresh);
    const loweringMs = performance.now() - started;
    if (loweringMs >= bounds.timeMs) throw new Bound('TIME_LIMIT');
    return {status: 'PASS' as const, term, measurement: {...counts(term), freshBinders: next - initial, loweringMs}};
  } catch (error) {
    if (error instanceof Bound) return {status: error.status, measurement: {freshBinders: next - initial, loweringMs: performance.now() - started}};
    throw error;
  }
}
function expectLower(body: B.Body, parameters: ParserParameter[], bounds: Bounds): B.LTerm {
  const result = lower(body, parameters, bounds);
  requireThat(result.status === 'PASS' && 'term' in result, 'Small semantic fixture exceeded bound: ' + result.status);
  return result.term;
}
function columnOnly(body: B.Match, parameters: ParserParameter[], bounds: Bounds) {
  try {
    const result = lower(transpose(body), parameters, bounds);
    return {status: 'UNEXPECTED_' + result.status, expected: 'legacy consumed-binder Err', ...result.measurement};
  } catch (error) {
    const err = error as B.Err;
    const text = errorText(error);
    requireThat(err?.$ === 'Err' && text.includes('consumed binder'), 'Column-only swap did not produce expected legacy consumed-binder Err: ' + text);
    return {status: 'EXPECTED_LEGACY_ERR', expected: 'legacy consumed-binder Err', error: text,
      interpretation: 'Invalid original binder/interface order, NOT a semantic output difference'};
  }
}

type Fixture = {name: string; source: string; inputs: {args: [string, string]; expected: number}[]; covers: string[]};
const prelude = `import Base
type Cell is Data:
  Leaf{value: Nat}
  Nest{cell: Cell}
type Tag is Data:
  C{cell: Cell, mark: Bool}
  D{cell: Cell, mark: Bool}
  E{cell: Cell, mark: Bool}
type Choice is Data:
  X{flag: Bool}
  Y{flag: Bool}
`;
function priorityFixture(position: 'before' | 'between' | 'after'): Fixture {
  const rows = [
    ['C{Nest{Leaf{value}}, True{}} X{True{}}', '11n'],
    ['D{Nest{Leaf{value}}, True{}} X{True{}}', '22n'],
  ];
  rows.splice(position === 'before' ? 0 : position === 'between' ? 1 : 2, 0, ['_ X{True{}}', '33n']);
  rows.push(['_ _', '44n']);
  return {name: 'wildcard-' + position, source: prelude + `def matrix(tag: Tag, choice: Choice) -> Nat:
  match tag choice:
` + rows.map(([p, f]) => `    case ${p}:\n      ${f}\n`).join(''),
    inputs: [
      {args: ['C{Nest{Leaf{7n}}, True{}}', 'X{True{}}'], expected: position === 'before' ? 33 : 11},
      {args: ['D{Nest{Leaf{8n}}, True{}}', 'X{True{}}'], expected: position === 'after' ? 22 : 33},
      {args: ['E{Nest{Leaf{9n}}, True{}}', 'X{True{}}'], expected: 33},
      {args: ['C{Nest{Leaf{7n}}, False{}}', 'X{True{}}'], expected: 33},
      {args: ['C{Leaf{7n}, True{}}', 'X{True{}}'], expected: 33},
      {args: ['C{Nest{Leaf{7n}}, True{}}', 'X{False{}}'], expected: 44},
      {args: ['C{Nest{Leaf{7n}}, True{}}', 'Y{True{}}'], expected: 44},
    ], covers: ['literal-priority-oracle', 'wildcard-' + position, 'nested-constructor-failure', 'later-column-failure']};
}
const fixtures: Fixture[] = [
  ...(['before', 'between', 'after'] as const).map(priorityFixture),
  {name: 'nested-binder-ids-and-copied-whole', source: prelude + `def sum_cell(cell: Cell) -> Nat:
  match cell:
    case Leaf{value}: value
    case Nest{inner}: sum_cell(inner)
def sum_tag(tag: Tag) -> Nat:
  match tag:
    case C{cell, mark}: sum_cell(cell)
    case D{cell, mark}: Nat.add(sum_cell(cell), 10n)
    case E{cell, mark}: Nat.add(sum_cell(cell), 20n)
def matrix(+tag: Tag, choice: Choice) -> Nat:
  match tag choice:
    case C{Nest{Leaf{+value}}, True{}} X{True{}}:
      Nat.add(value, value)
    case +whole X{False{}}:
      Nat.add(sum_tag(whole), sum_tag(whole))
    case whole _:
      sum_tag(whole)
`, inputs: [
    {args: ['C{Nest{Leaf{7n}}, True{}}', 'X{True{}}'], expected: 14},
    {args: ['C{Nest{Leaf{7n}}, False{}}', 'X{True{}}'], expected: 7},
    {args: ['C{Nest{Leaf{7n}}, True{}}', 'X{False{}}'], expected: 14},
    {args: ['D{Nest{Leaf{8n}}, True{}}', 'X{False{}}'], expected: 36},
    {args: ['E{Leaf{9n}, False{}}', 'Y{True{}}'], expected: 29},
  ], covers: ['Many-parameter', 'nested-Many-field', 'whole-scrutinee-reconstruction', 'same-spelling-different-row-binder-IDs']},
  {name: 'mixed-affine-and-many-nested-fields', source: `import Base
type Resource is Type:
  Resource{value: Nat}
type Bundle is Type:
  Bundle{resource: Resource, data: (Nat & Nat)}
type Packet is Type:
  C{bundle: Bundle}
  D{bundle: Bundle}
def consume_resource(resource: Resource) -> Nat:
  match resource:
    case Resource{value}: value
def consume_packet(packet: Packet) -> Nat:
  match packet:
    case C{Bundle{resource, (left, right)}}:
      Nat.add(consume_resource(resource), Nat.add(left, right))
    case D{Bundle{resource, (left, right)}}:
      Nat.add(consume_resource(resource), Nat.add(left, right))
def matrix(packet: Packet, flag: Bool) -> Nat:
  match packet flag:
    case C{Bundle{resource, (+left, right)}} True{}:
      Nat.add(consume_resource(resource), Nat.add(Nat.add(left, left), right))
    case whole _:
      consume_packet(whole)
`, inputs: [
    {args: ['C{Bundle{Resource{7n}, (3n, 4n)}}', 'True{}'], expected: 17},
    {args: ['C{Bundle{Resource{7n}, (3n, 4n)}}', 'False{}'], expected: 14},
    {args: ['D{Bundle{Resource{8n}, (5n, 6n)}}', 'True{}'], expected: 19},
    {args: ['D{Bundle{Resource{8n}, (5n, 6n)}}', 'False{}'], expected: 19},
  ], covers: ['Type-affine-parameter', 'mixed-nested-Lone-and-Many-fields', 'whole-affine-reconstruction-after-later-failure', 'same-spelling-different-row-binder-IDs']},
];

function copyBook(book: B.Book): B.Book {
  return {...book, tlds: Object.fromEntries(Object.entries(book.tlds).map(([k, v]) => [k, {...v}])),
    ctrs: {...book.ctrs}, order: book.order.slice(), tmps: {...book.tmps}};
}
function parseTerm(book: B.Book, source: string): B.LTerm {
  const parser: B.Parse = {book, dir: tmpdir() + '/', str: source, pos: 0, sc: {stk: [], frs: 0},
    ns: '', al: {}, os: [], inst: null, ts: [], lv: 0};
  return B.parse_term(parser);
}
function install(book: B.Book, name: string, term: B.LTerm, parameters: ParserParameter[], result: B.LTerm) {
  const def: B.Def = {$: 'Def', n: parameters.length, T: B.term_higher(B.tele_bind(parameters, result)), v: B.term_higher(term)};
  book.tlds[name] = def;
  book.order.push(name);
}
function tuple(items: string[]): string {
  requireThat(items.length > 0, 'Nonempty tuple');
  return items.slice(0, -1).reduceRight((tail, item) => `(${item} ${'&'} ${tail})`, items.at(-1)!);
}
function valuesTuple(items: string[]): string {
  return items.slice(0, -1).reduceRight((tail, item) => `(${item}, ${tail})`, items.at(-1)!);
}
function nativeNat(book: B.Book, term: B.HTerm): number {
  const value = B.term_snf(book, term), number = B.nat_from_term(B.term_lower(value));
  requireThat(number !== null, 'Native result is not Nat');
  return number;
}
function quantityAudit(term: B.LTerm, ids: Set<number>) {
  const marks = new Map<number, Set<string>>();
  walk(term, node => {
    if ((node.$ === 'Lam' || node.$ === 'PVar') && typeof node.i === 'number' && ids.has(node.i)) {
      const seen = marks.get(node.i) ?? new Set<string>();
      seen.add((node.q as B.Quant).$); marks.set(node.i, seen);
    }
  });
  return [...marks].sort(([a], [b]) => a - b).map(([id, quantities]) => ({id, quantities: [...quantities].sort()}));
}
function run(command: string, args: string[], timeout: number) {
  const result = spawnSync(command, args, {encoding: 'utf8', timeout, killSignal: 'SIGKILL', maxBuffer: 16 * 1024 * 1024});
  requireThat(!result.error && result.status === 0, `${command} failed: ${result.error ?? result.signal ?? result.status}\n${result.stderr}`);
  return {stdout: result.stdout.trim(), stderr: result.stderr.trim()};
}
type CommandOutput = {stdout: string; stderr: string};
type BinderQuantity = {id: number; quantities: string[]};
type TelescopeBinder = {id: number; name: string; quantity: string};
type SemanticPassed = {
  typecheck: {status: string}; native: number[]; jsLibrary: number[]; nativeMain: string;
  literalMain: string; jsRuntime: CommandOutput; cRuntime: CommandOutput;
  sourceHashes: {jsLibrary: string; jsRuntime: string; cRuntime: string};
  quantities: BinderQuantity[]; arguments: string[][]; telescope: TelescopeBinder[];
  matrixCounts: object;
};
type SemanticOutcome = SemanticPassed | {typecheck: {status: string; error?: string}; runtimeError?: string};
async function semanticVariant(graph: ParserGraph, fixture: Fixture, alignedSwap: boolean, bounds: Bounds): Promise<SemanticOutcome> {
  const book = copyBook(graph.parserBook), lowered = new Map<string, B.LTerm>();
  for (const [name, original] of graph.bodies) {
    const signature = graph.signatures.get(name)!;
    const parameters = name === 'matrix' && alignedSwap ? swap(signature.parameters) : signature.parameters;
    const body = name === 'matrix' && alignedSwap ? transpose(original as B.Match) : original;
    const term = expectLower(body, parameters, bounds);
    install(book, name, term, parameters, signature.result); lowered.set(name, term);
  }
  const entries = fixture.inputs.map((_, index) => 'probe' + index);
  fixture.inputs.forEach((input, index) => {
    const args = alignedSwap ? swap(input.args) : input.args;
    install(book, entries[index], parseTerm(book, `matrix(${args.join(', ')})`), [], B.Ref('Nat'));
  });
  install(book, 'main', parseTerm(book, valuesTuple(entries.map(name => `${name}()`))), [], parseTerm(book, tuple(entries.map(() => 'Nat'))));
  let typecheck: {status: string; error?: string};
  try {B.book_valid(book); typecheck = {status: 'PASS'};} catch (error) {return {typecheck: {status: 'FAIL', error: errorText(error)}};}
  const native = entries.map(name => nativeNat(book, (book.tlds[name] as B.Def).v!));
  const nativeMain = B.term_show(B.term_lower(B.term_snf(book, (book.tlds.main as B.Def).v!)));
  const literalMain = B.term_show(B.term_lower(B.term_snf(book, B.term_higher(parseTerm(book, valuesTuple(fixture.inputs.map(input => input.expected + 'n')))))));
  const librarySource = Comp.js_lib(book, entries, entries);
  // Library bytes are compiler output generated from this runtime book, not an author-time module.
  const compiled = (await import('data:text/javascript;base64,' + Buffer.from(librarySource).toString('base64'))).default;
  const jsLibrary = entries.map(name => Number(compiled[name]()));
  const directory = await mkdtemp(join(tmpdir(), 'bend-column-order-'));
  let jsRuntime: CommandOutput, cRuntime: CommandOutput;
  let jsSource: string, cSource: string;
  try {
    jsSource = Comp.js_book(book); cSource = Comp.compile_book(book);
    const jsPath = join(directory, 'main.js'), cPath = join(directory, 'main.c'), executable = join(directory, 'main');
    await writeFile(jsPath, jsSource); await writeFile(cPath, cSource);
    jsRuntime = run(process.execPath, [jsPath], bounds.timeMs);
    run(process.env.CC ?? 'cc', ['-std=c11', '-O1', cPath, '-lpthread', '-lm', '-o', executable], bounds.timeMs);
    cRuntime = run(executable, ['--threads', '1', '--gpu', 'off'], bounds.timeMs);
  } finally {await rm(directory, {recursive: true, force: true});}
  const signature = graph.signatures.get('matrix')!;
  const original = graph.bodies.get('matrix')!;
  const ids = new Set(signature.parameters.map(p => p[2]));
  walk(original, node => {if (node.$ === 'PVar') ids.add(node.i as number);});
  return {typecheck, native, jsLibrary, nativeMain, literalMain, jsRuntime, cRuntime,
    sourceHashes: {jsLibrary: sha(librarySource), jsRuntime: sha(jsSource!), cRuntime: sha(cSource!)},
    quantities: quantityAudit(lowered.get('matrix')!, ids),
    arguments: fixture.inputs.map(input => alignedSwap ? swap(input.args) : input.args),
    telescope: (alignedSwap ? swap(signature.parameters) : signature.parameters).map(([q, k, i]) => ({id: i, name: k, quantity: q.$})),
    matrixCounts: counts(lowered.get('matrix'))};
}
function semanticDifference(a: SemanticOutcome, b: SemanticOutcome, fixture: Fixture): string[] {
  const differences: string[] = [];
  if (a.typecheck.status === 'FAIL' || b.typecheck.status === 'FAIL') return ['native-typecheck-failure'];
  if (!('native' in a) || !('native' in b)) return ['semantic-runtime-failure'];
  const expected = fixture.inputs.map(input => input.expected);
  for (const [label, values] of [['A-native', a.native], ['B-native', b.native], ['A-js_lib', a.jsLibrary], ['B-js_lib', b.jsLibrary]] as const)
    if (JSON.stringify(values) !== JSON.stringify(expected)) differences.push(label + '-literal-oracle');
  for (const [label, variant] of [['A', a], ['B', b]] as const) {
    for (const [runtime, actual] of [['native', variant.nativeMain], ['js_book', variant.jsRuntime.stdout], ['compile_book', variant.cRuntime.stdout]])
      if (actual.replace(/\s+/g, '') !== variant.literalMain.replace(/\s+/g, '')) differences.push(label + '-' + runtime + '-literal-oracle');
  }
  if (JSON.stringify(a.quantities) !== JSON.stringify(b.quantities)) differences.push('original-binder-quantity-difference');
  if (JSON.stringify(a.telescope) !== JSON.stringify(swap(b.telescope))) differences.push('telescope-identity-or-quantity-difference');
  return differences;
}

function synthetic(width: number, partitions: number, depth: number): string {
  const nested = (inside: string) => Array.from({length: depth}).reduce<string>(out => `Nest{${out}}`, `Leaf{${inside}}`);
  let source = `import Base\ntype Cell is Data:\n  Leaf{flag: Bool}\n  Nest{cell: Cell}\ntype Wide is Data:\n`;
  for (let c = 0; c < width; c++) source += `  C${c}{cell: Cell, flag: Bool}\n`;
  source += 'type Partition is Data:\n';
  for (let p = 0; p < partitions; p++) source += `  P${p}{cell: Cell}\n`;
  source += 'def matrix(wide: Wide, partition: Partition) -> Nat:\n  match wide partition:\n';
  for (let p = 0; p < partitions; p++) {
    for (let c = 0; c < width; c++) source += `    case C${c}{${nested('True{}')}, True{}} P${p}{${nested('True{}')}}:\n      ${1 + (p * width + c) % 31}n\n`;
    // Small literals keep raw-body size from dominating the column-order measurement.
    source += `    case _ P${p}{${nested('False{}')}}:\n      32n\n    case _ P${p}{_}:\n      33n\n`;
  }
  return source + '    case _ _:\n      34n\n';
}
fixtures.push({name: 'synthetic-small-full-compile', source: synthetic(2, 2, 2), inputs: [
  {args: ['C0{Nest{Nest{Leaf{True{}}}}, True{}}', 'P0{Nest{Nest{Leaf{True{}}}}}'], expected: 1},
  {args: ['C1{Nest{Nest{Leaf{True{}}}}, True{}}', 'P0{Nest{Nest{Leaf{True{}}}}}'], expected: 2},
  {args: ['C0{Nest{Nest{Leaf{True{}}}}, True{}}', 'P1{Nest{Nest{Leaf{True{}}}}}'], expected: 3},
  {args: ['C1{Nest{Nest{Leaf{True{}}}}, True{}}', 'P1{Nest{Nest{Leaf{True{}}}}}'], expected: 4},
  {args: ['C0{Nest{Nest{Leaf{True{}}}}, False{}}', 'P0{Nest{Nest{Leaf{True{}}}}}'], expected: 33},
  {args: ['C0{Nest{Nest{Leaf{False{}}}}, True{}}', 'P1{Nest{Nest{Leaf{True{}}}}}'], expected: 33},
  {args: ['C1{Nest{Nest{Leaf{True{}}}}, True{}}', 'P0{Nest{Nest{Leaf{False{}}}}}'], expected: 32},
  {args: ['C1{Nest{Nest{Leaf{True{}}}}, True{}}', 'P1{Leaf{True{}}}'], expected: 33},
], covers: ['same-generator-as-growth', 'nested-first-column-overlap', 'strong-second-column-partition', 'literal-oracles']});
type GrowthRecord = {
  width: number; partitions: number; depth: number; transposed: boolean;
  mode: 'original' | 'aligned-swap' | 'column-only'; sourceSha256: string;
  status?: unknown; lowered?: Record<string, number>; [key: string]: unknown;
};
type Job = {source: string; transposed: boolean; mode: 'original' | 'aligned-swap' | 'column-only'; bounds: Bounds};
async function lowerJob(job: Job) {
  const graph = await readParserGraph(job.source), original = graph.bodies.get('matrix');
  const signature = graph.signatures.get('matrix');
  requireThat(original?.$ === 'Match' && signature, 'Synthetic raw matrix missing');
  const body = job.transposed ? transpose(original) : original;
  const parameters = job.transposed ? swap(signature.parameters) : signature.parameters;
  const contract = rawContract(body, parameters);
  if (job.mode === 'column-only') return {raw: counts(body), contract, ...columnOnly(body, parameters, job.bounds)};
  const actualBody = job.mode === 'aligned-swap' ? transpose(body) : body;
  const actualParameters = job.mode === 'aligned-swap' ? swap(parameters) : parameters;
  const goal = B.tele_bind(actualParameters, signature.result);
  const result = lower(actualBody, actualParameters, job.bounds);
  return {status: result.status, raw: counts(actualBody), lowered: result.measurement, contract,
    telescope: actualParameters.map(([q, k, i]) => ({id: i, name: k, quantity: q.$})), goal: counts(goal),
    interface: job.mode === 'aligned-swap' ? 'argument-permuted function; caller must swap the same input pair' : 'original function'};
}
function numberOption(args: string[], key: string, fallback: number, maximum: number) {
  const option = args.find(arg => arg.startsWith('--' + key + '='));
  const value = option ? Number(option.split('=')[1]) : fallback;
  requireThat(Number.isSafeInteger(value) && value >= 1 && value <= maximum, key + ' must be in 1..' + maximum);
  return value;
}
await guardHeavyGate(import.meta.path, {label: 'stage0-column-order-controls'});
await checkFrozen();
if (process.argv[2] === '--lower-job') {
  try {console.log(JSON.stringify(await lowerJob(JSON.parse(process.argv[3]) as Job)));}
  catch (error) {console.log(JSON.stringify({status: 'ERROR', error: errorText(error)})); process.exitCode = 1;}
} else {
  const args = process.argv.slice(2);
  const known = /^(--sizes=|--partitions=|--depth=|--fresh-limit=|--time-ms=)/;
  requireThat(args.every(arg => known.test(arg)), 'Options: --sizes=2,4,6 --partitions=N --depth=2 --fresh-limit=131072 --time-ms=30000');
  const sizes = (args.find(arg => arg.startsWith('--sizes='))?.slice(8) ?? '2,4,6').split(',').map(Number);
  requireThat(sizes.length > 0 && sizes.every(n => Number.isSafeInteger(n) && n >= 2 && n <= 64), 'sizes must be integers in 2..64');
  const bounds: Bounds = {freshLimit: numberOption(args, 'fresh-limit', 131072, 131072), timeMs: numberOption(args, 'time-ms', 30000, 30000)};
  const depth = numberOption(args, 'depth', 2, 8);
  const partitions = args.some(arg => arg.startsWith('--partitions=')) ? numberOption(args, 'partitions', 2, 64) : undefined;
  const result: {status: string; frozenInputs: typeof frozen; bounds: Bounds; contract: object; semantic: unknown[]; growth: GrowthRecord[]; comparisons: unknown[]; error?: string} = {
    status: 'RUNNING', frozenInputs: frozen, bounds,
    contract: {productionFunctionsUnchanged: true, productionAndHistoricalKernelIdentical: true,
      A: 'original raw function', B: 'column-swapped AST + aligned vars + permuted All telescope + swapped actual arguments',
      originalInterfacePreserved: false, columnOnly: 'negative consumed-binder rejection, not an output difference',
      counting: 'unique raw/lowered objects excluding spans; arrays and quantity metadata included; no HOAS materialization',
      limits: 'fresh callback bound plus hard 30s-or-lower child wall deadline per growth job; small semantics use callback/deadline bounds and timed emitted commands',
      noHeuristic: true, noIRorLetSharing: true, selfhostGreen: false}, semantic: [], growth: [], comparisons: [],
  };
  await mkdir('checkpoints', {recursive: true});
  const save = async () => {await Bun.write(checkpoint, JSON.stringify(result, null, 2) + '\n');};
  await save();
  try {
    for (const fixture of fixtures) {
      const graph = await readParserGraph(fixture.source), body = graph.bodies.get('matrix'), signature = graph.signatures.get('matrix');
      requireThat(body?.$ === 'Match' && signature, 'Missing semantic raw matrix');
      const contract = rawContract(body, signature.parameters);
      const negative = columnOnly(body, signature.parameters, bounds);
      requireThat(negative.status === 'EXPECTED_LEGACY_ERR', 'Semantic column-only negative failed');
      const outcomes: SemanticOutcome[] = [];
      for (const alignedSwap of [false, true]) {
        try {outcomes.push(await semanticVariant(graph, fixture, alignedSwap, bounds));}
        catch (error) {outcomes.push({typecheck: {status: 'NOT_COMPLETED'}, runtimeError: errorText(error)});}
      }
      const [a, b] = outcomes;
      const differences = semanticDifference(a, b, fixture);
      result.semantic.push({fixture: fixture.name, source: fixture.source, sourceSha256: sha(fixture.source), covers: fixture.covers,
        inputs: fixture.inputs, raw: counts(body), contract, columnOnly: negative, A: a, B: b, differences});
      if (a.typecheck.status === 'NOT_COMPLETED' && b.typecheck.status === 'NOT_COMPLETED') {
        result.status = 'ERROR'; result.error = 'Both semantic variants failed to execute; see saved runtimeError records';
        await save(); console.log(JSON.stringify(result)); process.exit(1);
      }
      if (differences.length) {
        result.status = 'SEMANTIC_DIFFERENCE'; await save(); console.log(JSON.stringify(result)); process.exit(2);
      }
      await save(); Bun.gc(true);
    }
    for (const width of sizes) {
      const source = synthetic(width, partitions ?? width, depth);
      for (const transposed of [false, true]) for (const mode of ['original', 'aligned-swap', 'column-only'] as const) {
        const job: Job = {source, transposed, mode, bounds};
        const started = performance.now();
        const child = spawnSync(process.execPath, [import.meta.path, '--lower-job', JSON.stringify(job)],
          {encoding: 'utf8', timeout: bounds.timeMs, killSignal: 'SIGKILL', maxBuffer: 16 * 1024 * 1024});
        let measurement: Record<string, unknown>;
        if ((child.error as NodeJS.ErrnoException)?.code === 'ETIMEDOUT') measurement = {status: 'TIME_LIMIT', wallMs: performance.now() - started};
        else {
          requireThat(!child.error && child.status === 0, 'Growth child failed: ' + child.stdout + '\n' + child.stderr);
          measurement = JSON.parse(child.stdout.trim());
          requireThat(measurement.status !== 'ERROR', 'Growth lowering failed: ' + measurement.error);
        }
        if (mode === 'column-only') requireThat(measurement.status === 'EXPECTED_LEGACY_ERR' || measurement.status === 'TIME_LIMIT', 'Expected column-only legacy rejection');
        result.growth.push({width, partitions: partitions ?? width, depth, transposed, mode, sourceSha256: sha(source), ...measurement});
        await save(); console.log(JSON.stringify(result.growth.at(-1))); Bun.gc(true);
      }
      for (const transposed of [false, true]) {
        const a = result.growth.find(row => row.width === width && row.transposed === transposed && row.mode === 'original')!;
        const b = result.growth.find(row => row.width === width && row.transposed === transposed && row.mode === 'aligned-swap')!;
        const metrics: Record<string, object> = {};
        if (a.status === 'PASS' && b.status === 'PASS') {
          for (const metric of ['objects', 'Sub', 'Lam', 'Mat', 'freshBinders', 'loweringMs']) {
            const original = a.lowered![metric], swapped = b.lowered![metric];
            metrics[metric] = {original, swapped, swappedMinusOriginal: swapped - original,
              swappedOverOriginal: original === 0 ? null : swapped / original};
          }
        }
        result.comparisons.push({width, partitions: partitions ?? width, depth, transposed,
          A: a.status, B: b.status, metrics, interpretation: 'Measurement only; argument-permuted interface, no heuristic recommendation'});
      }
      await save();
    }
    await checkFrozen(); result.status = 'PASS'; await save(); console.log(JSON.stringify(result));
  } catch (error) {result.status = 'ERROR'; result.error = errorText(error); await save(); console.error(JSON.stringify(result)); process.exitCode = 1;}
}
