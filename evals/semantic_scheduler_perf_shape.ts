import { createHash } from 'node:crypto';
import { readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type { Body, LTerm, Patt, Quant } from '../bend2/bend.ts';
import { sourceOracle, type Parameter, type RawDeclaration, type SourceOracleResult } from './bootstrap_source_oracle.ts';
import { SourceDeclarations } from './parser_full_declarations.ts';
import { termChildren } from './parser_full_type_env.ts';

/** A source-schema witness, never a compiler, termination, layout or runtime gate. */
type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
type Scope = readonly number[];
const sha = (value: string | Uint8Array) => createHash('sha256').update(value).digest('hex');
const encoded = (value: Json) => JSON.stringify(value);
const defaultOriginal = resolve(import.meta.dir, '../checkpoints/checker_core_steps_v1.bend');
const familyNames = ['Value', 'Progress', 'Stack', 'Run'] as const;
const constructorNames = ['Value', 'Finished', 'Pending', 'Direct', 'Bound', 'StackDone', 'StackMore', 'RunFinished', 'RunState'] as const;
const functionNames = [
  ['checker_cast_box', 'Perf.cast'], ['checker_pop', 'Perf.pop'],
  ['checker_advance', 'Perf.advance'], ['checker_chunk', 'Perf.chunk'],
  ['checker_step', 'Perf.step'], ['checker_result', 'Perf.result'],
  ['checker_step_one', 'Perf.step_one'],
] as const;
const symbolPairs: readonly (readonly [string, string])[] = [
  ...[...new Set([...familyNames, ...constructorNames, 'Request'])].map(name => [`Checker${name}`, `Perf${name}`] as const),
  ...functionNames,
];

export type DeclarationProvenance = {
  key: string; kind: string; begin: number; end: number; spanUnits: string; sha256: string;
  associatedSource: { begin: number; end: number; annotations: string[] } | null;
};
export type RequestWidth = {
  groups: number; requests: number; armsPerGroup: number[];
  groupDetails: {
    family: string; wrapper: string; requests: number;
    resultFunction: DeclarationProvenance; dispatcher: DeclarationProvenance;
    resultShapeSha256: string; resultShape: Json;
    requestFields: { constructor: string; fields: Json[] }[];
    dispatcherSignature: Json; dispatcherRows: number;
  }[];
  outerResultShape: Json; outerDispatcherSignature: Json; outerDispatcher: DeclarationProvenance;
};
export type LoopFacts = {
  stepQuantum: number; recursiveFuel: string; sourceRows: Json;
  equalityRewriteNodes: number; terminationOrNativeAcceptance: string;
};

class UnsupportedShape extends Error {
  constructor(readonly location: string, readonly reason: string) {
    super(`${location}: ${reason}`);
    this.name = 'UnsupportedShape';
  }
}
function requireShape(condition: unknown, location: string, reason: string): asserts condition {
  if (!condition) throw new UnsupportedShape(location, reason);
}
function bind(scope: Scope, id: number, location: string): Scope {
  requireShape(Number.isInteger(id) && !scope.includes(id), location, `duplicate/invalid active binder ID ${id}`);
  return [...scope, id];
}

/** Only actual binder IDs establish scope. Names and spans are not equality keys.
 * De Bruijn distance is local to each branch/telescope, not a global ID rewrite.
 * Unknown tags, fields, substitutions and holes fail closed. */
class Canonical {
  constructor(readonly symbols: ReadonlyMap<string, string>, readonly location: string) {}
  name(name: string) { return this.symbols.get(name) ?? name; }
  keys(node: object, allowed: string[]) {
    for (const key of Object.keys(node))
      requireShape(key === 's' || allowed.includes(key), this.location, `unsupported AST field ${key}`);
  }
  quantity(q: Quant): string {
    this.keys(q, ['$']);
    requireShape(['None', 'Lone', 'Many'].includes(q.$), this.location, `unknown quantity ${q.$}`);
    return q.$;
  }
  term(t: LTerm, scope: Scope): Json {
    switch (t.$) {
      case 'Var': {
        this.keys(t, ['$', 'k', 'i', 'v']);
        if (t.v !== undefined) {
          requireShape(!scope.includes(t.i) && t.v.$ === 'Ref', this.location, 'only unbound parser name-resolution links to Ref are supported');
          return this.term(t.v, scope);
        }
        const index = scope.lastIndexOf(t.i);
        requireShape(index >= 0, this.location, `unbound variable ${t.k} (ID ${t.i})`);
        return { tag: 'Var', distance: scope.length - index - 1 };
      }
      case 'Ref': this.keys(t, ['$', 'k', 'b']); return { tag: 'Ref', name: this.name(t.k), template: t.b ?? false };
      case 'Typ': this.keys(t, ['$', 'g']); return { tag: 'Typ', grade: this.term(t.g, scope) };
      case 'Qnt': case 'Efq': case 'Rfl': this.keys(t, ['$']); return { tag: t.$ };
      case 'Qua': this.keys(t, ['$', 'q']); return { tag: 'Qua', quantity: this.quantity(t.q) };
      case 'Min': this.keys(t, ['$', 'a', 'b']); return { tag: 'Min', left: this.term(t.a, scope), right: this.term(t.b, scope) };
      case 'All':
        this.keys(t, ['$', 'q', 'k', 'i', 'A', 'B']);
        return { tag: 'All', quantity: this.quantity(t.q), domain: this.term(t.A, scope), codomain: this.term(t.B, bind(scope, t.i, this.location)) };
      case 'Lam':
        this.keys(t, ['$', 'q', 'k', 'i', 'f']);
        return { tag: 'Lam', quantity: t.q ? this.quantity(t.q) : null, body: this.term(t.f, bind(scope, t.i, this.location)) };
      case 'App': this.keys(t, ['$', 'f', 'x']); return { tag: 'App', fn: this.term(t.f, scope), arg: this.term(t.x, scope) };
      case 'ADT':
        this.keys(t, ['$', 'k', 'x', 'r']);
        return { tag: 'ADT', name: this.name(t.k), args: t.x.map(x => this.term(x, scope)), recursive: t.r.map(k => this.name(k)) };
      case 'Ctr': this.keys(t, ['$', 'k', 'x']); return { tag: 'Ctr', name: this.name(t.k), args: t.x.map(x => this.term(x, scope)) };
      case 'Lit':
        this.keys(t, ['$', 'k', 'v']);
        requireShape(typeof t.v === 'string' || Number.isFinite(t.v), this.location, 'non-JSON literal');
        return { tag: 'Lit', kind: t.k, value: t.v };
      case 'Mat': this.keys(t, ['$', 'k', 'h', 'm']); return { tag: 'Mat', constructor: this.name(t.k), hit: this.term(t.h, scope), miss: this.term(t.m, scope) };
      case 'Eql': this.keys(t, ['$', 'a', 'b', 'T']); return { tag: 'Eql', left: this.term(t.a, scope), right: this.term(t.b, scope), type: this.term(t.T, scope) };
      case 'Rwt': this.keys(t, ['$', 'e', 'p', 'f']); return { tag: 'Rwt', equation: this.term(t.e, scope), motive: this.term(t.p, scope), body: this.term(t.f, scope) };
      case 'Ann': this.keys(t, ['$', 'x', 'T']); return { tag: 'Ann', value: this.term(t.x, scope), type: this.term(t.T, scope) };
      case 'Let': {
        this.keys(t, ['$', 'k', 'i', 'q', 'v', 'f']);
        requireShape(t.k.length === t.i.length && t.i.length === t.q.length && t.q.length === t.v.length, this.location, 'parallel Let arity');
        let inner = scope;
        for (const id of t.i) inner = bind(inner, id, this.location);
        return { tag: 'Let', quantities: t.q.map(q => this.quantity(q)), values: t.v.map(v => this.term(v, scope)), body: this.term(t.f, inner) };
      }
      case 'Sub': case 'Hol': throw new UnsupportedShape(this.location, `unsupported ${t.$} (not flattened or treated as a wildcard)`);
      default: throw new UnsupportedShape(this.location, 'unknown term tag');
    }
  }
  pattern(p: Patt, scope: Scope): { value: Json; scope: Scope } {
    if (p.$ === 'PVar') {
      this.keys(p, ['$', 'k', 'i', 'q']);
      return { value: { tag: 'PVar', wildcard: p.k === '_', quantity: this.quantity(p.q) }, scope: p.k === '_' ? scope : bind(scope, p.i, this.location) };
    }
    requireShape(p.$ === 'PCtr', this.location, 'unknown pattern tag');
    this.keys(p, ['$', 'k', 'x']);
    const children: Json[] = [];
    for (const child of p.x) { const next = this.pattern(child, scope); children.push(next.value); scope = next.scope; }
    return { value: { tag: 'PCtr', name: this.name(p.k), fields: children }, scope };
  }
  body(b: Body, scope: Scope): Json {
    if (b.$ === 'Match') {
      this.keys(b, ['$', 'e', 'r']);
      return { tag: 'Match', scrutinees: b.e.map(e => this.term(e, scope)), rows: b.r.map(row => {
        this.keys(row, ['p', 'f']);
        requireShape(row.p.length === b.e.length, this.location, 'match row arity');
        let inner = scope;
        const patterns = row.p.map(p => { const next = this.pattern(p, inner); inner = next.scope; return next.value; });
        return { patterns, body: this.body(row.f, inner) };
      }) };
    }
    if (b.$ === 'Local') {
      this.keys(b, ['$', 'k', 'q', 'v', 'f']);
      requireShape(b.k.length === b.v.length, this.location, 'parallel Local arity');
      let inner = scope;
      const patterns = b.k.map(p => { const next = this.pattern(p, inner); inner = next.scope; return next.value; });
      return { tag: 'Local', quantity: this.quantity(b.q), patterns, values: b.v.map(v => this.term(v, scope)), body: this.body(b.f, inner) };
    }
    return this.term(b, scope);
  }
  telescope(parameters: Parameter[], scope: Scope = []): { value: Json[]; scope: Scope } {
    const value: Json[] = [];
    for (const [quantity, , id, type] of parameters) {
      value.push({ quantity: this.quantity(quantity), type: this.term(type, scope) });
      scope = bind(scope, id, this.location);
    }
    return { value, scope };
  }
  declaration(d: RawDeclaration, includeBody = true): Json {
    if (d.kind === 'type') {
      requireShape(d.parameters && d.kindTerm && d.constructors, this.location, 'missing datatype metadata');
      const parameters = this.telescope(d.parameters);
      return { tag: 'Family', parameters: parameters.value, kind: this.term(d.kindTerm, parameters.scope), constructors: d.constructors.map(c => ({
        name: this.name(c.key), fields: this.telescope(c.fields, parameters.scope).value,
      })) };
    }
    requireShape(d.kind === 'def' && d.signature?.parameters && d.signature.result && !d.completesLaw, this.location, 'requires explicit definition signature');
    requireShape(!d.nativeImports?.length && !d.template, this.location, 'foreign/template definition outside supported subset');
    const parameters = this.telescope(d.signature.parameters);
    requireShape(!includeBody || d.body, this.location, 'missing body');
    return { tag: 'Definition', unsafe: d.unsafe ?? false, templateCount: d.templateCount ?? 0,
      parameters: parameters.value, result: this.term(d.signature.result, parameters.scope),
      ...(includeBody ? { body: this.body(d.body!, parameters.scope) } : {}) };
  }
}

type Unit = { source: string; oracle: SourceOracleResult; declarations: Map<string, RawDeclaration>; association: SourceDeclarations; symbols: Map<string, string> };
function declaration(unit: Unit, key: string): RawDeclaration {
  const found = unit.declarations.get(key);
  requireShape(found, key, 'declaration missing');
  return found;
}
function canonical(unit: Unit, key: string, body = true) {
  return new Canonical(unit.symbols, key).declaration(declaration(unit, key), body);
}
function provenance(unit: Unit, key: string): DeclarationProvenance {
  const d = declaration(unit, key), association = unit.association.declarations.get(key);
  return { key, kind: d.kind, begin: d.beg, end: d.end, spanUnits: 'UTF-16 code units',
    sha256: sha(unit.source.slice(d.beg, d.end)),
    // SourceDeclarations associates trivia only; parser metadata supplies the proof.
    associatedSource: association ? { begin: association.start, end: association.end, annotations: association.annotations } : null };
}
async function load(path: string, side: 0 | 1): Promise<Unit> {
  const file = realpathSync(resolve(path)), source = readFileSync(file, 'utf8');
  const oracle = await sourceOracle(file, source, { recordInputs: true });
  requireShape(oracle.accepted, file, `parser/loader failed: ${JSON.stringify(oracle.failure ?? null)}`);
  requireShape(oracle.inputFiles.some(input => input.file === file && input.sourceSha256 === sha(source)), file, 'root provenance mismatch');
  const declarations = new Map<string, RawDeclaration>();
  for (const d of oracle.declarations) {
    requireShape(!declarations.has(d.key), d.key, 'duplicate root declaration');
    declarations.set(d.key, d);
  }
  return { source, oracle, declarations, association: new SourceDeclarations(source), symbols: new Map(symbolPairs.map(pair => [pair[side], pair[0]])) };
}
function unitProvenance(unit: Unit) {
  return { path: unit.oracle.file, sourceSha256: sha(unit.source), bytes: Buffer.byteLength(unit.source),
    declarations: unit.declarations.size, imports: unit.oracle.imports, inputs: unit.oracle.inputFiles,
    parserObservation: unit.oracle.observation, loadContexts: unit.oracle.loadContexts };
}

/** Validate dispatch by its parameter, scrutinee and pattern identity, not its name. */
function dispatch(unit: Unit, key: string, family: string) {
  const d = declaration(unit, key), parameters = d.signature?.parameters;
  const parameter = parameters?.length === 1 ? unapply(parameters[0]![3]) : null;
  requireShape(parameter?.head.$ === 'Ref' && parameter.head.k === family && parameter.args.length === 0 && declaration(unit, family).kind === 'type', key, 'expected one request-family parameter');
  requireShape(d.body?.$ === 'Match' && d.body.e.length === 1 && d.body.e[0]!.$ === 'Var' && d.body.e[0]!.i === parameters[0]![2], key, 'must directly match its request binder');
  const constructors = declaration(unit, family).constructors;
  requireShape(constructors, family, 'missing constructors');
  const rows = new Map<string, (typeof d.body.r)[number]>();
  for (const row of d.body.r) {
    requireShape(row.p.length === 1 && row.p[0]!.$ === 'PCtr', key, 'dispatch requires constructor rows, no default');
    const pattern = row.p[0]!;
    const ctor = constructors.find(c => c.key === pattern.k);
    requireShape(ctor && pattern.x.length === ctor.fields.length && !rows.has(pattern.k), key, 'unknown, repeated or wrong-arity dispatch constructor');
    rows.set(pattern.k, row);
  }
  requireShape(rows.size === constructors.length, key, 'incomplete dispatch coverage');
  return { d, rows, constructors };
}
function forwardedCall(row: { p: Patt[]; f: Body }, key: string): string {
  const p = row.p[0]!;
  requireShape(p.$ === 'PCtr' && p.x.length === 1 && p.x[0]!.$ === 'PVar' && p.x[0]!.k !== '_', key, 'wrapper must bind its one group payload');
  const call = row.f.$ !== 'Match' && row.f.$ !== 'Local' ? unapply(row.f) : null;
  requireShape(call?.head.$ === 'Ref' && !call.head.b && call.args.length === 1 && call.args[0]!.$ === 'Var' && call.args[0]!.i === p.x[0]!.i, key, 'must forward the same payload binder to its group function');
  return call.head.k;
}
function requestWidth(unit: Unit, side: 0 | 1): RequestWidth {
  const request = side === 0 ? 'CheckerRequest' : 'PerfRequest';
  const result = functionNames[5][side], stepOne = functionNames[6][side];
  const resultDispatch = dispatch(unit, result, request), stepDispatch = dispatch(unit, stepOne, request);
  const canonicalizer = new Canonical(unit.symbols, result);
  const isType = (term: LTerm | undefined) => term?.$ === 'Typ' && term.g.$ === 'Qua' && term.g.q.$ === 'Lone';
  requireShape(isType(resultDispatch.d.signature?.result), result, 'result function must return Type');
  const groups = resultDispatch.constructors.map(wrapper => {
    requireShape(wrapper.fields.length === 1 && wrapper.fields[0]![0].$ === 'Lone', wrapper.key, 'wrapper must own one affine group payload');
    const type = unapply(wrapper.fields[0]![3]);
    requireShape(type.head.$ === 'Ref' && type.args.length === 0 && declaration(unit, type.head.k).kind === 'type', wrapper.key, 'group payload must be a closed datatype');
    const resultKey = forwardedCall(resultDispatch.rows.get(wrapper.key)!, result);
    const stepKey = forwardedCall(stepDispatch.rows.get(wrapper.key)!, stepOne);
    const groupResult = dispatch(unit, resultKey, type.head.k), groupStep = dispatch(unit, stepKey, type.head.k);
    requireShape(isType(groupResult.d.signature?.result), resultKey, 'group result must return Type');
    // Signatures must retain the dependent result of this exact request binder.
    const stepParameter = groupStep.d.signature!.parameters![0]!;
    const stepResult = unapply(groupStep.d.signature!.result!);
    requireShape(stepResult.head.$ === 'Ref' && stepResult.head.k === (side === 0 ? 'CheckerProgress' : 'PerfProgress') && stepResult.args.length === 1, stepKey, 'group dispatcher must return generic Progress');
    const dependency = unapply(stepResult.args[0]!);
    requireShape(dependency.head.$ === 'Ref' && dependency.head.k === resultKey && dependency.args.length === 1 && dependency.args[0]!.$ === 'Var' && dependency.args[0]!.i === stepParameter[2], stepKey, 'missing group result(request) dependency');
    const fields = groupResult.constructors.map(c => ({ constructor: c.key, fields: canonicalizer.telescope(c.fields).value }));
    const resultShape = canonical(unit, resultKey);
    return { family: type.head.k, wrapper: wrapper.key, requests: groupResult.constructors.length,
      resultFunction: provenance(unit, resultKey), dispatcher: provenance(unit, stepKey),
      resultShapeSha256: sha(encoded(resultShape)), resultShape, requestFields: fields,
      dispatcherSignature: canonical(unit, stepKey, false),
      dispatcherRows: groupStep.rows.size };
  });
  requireShape(new Set(groups.map(g => g.family)).size === groups.length, request, 'repeated group family');
  return { groups: groups.length, requests: groups.reduce((n, g) => n + g.requests, 0),
    armsPerGroup: groups.map(g => g.requests), groupDetails: groups,
    outerResultShape: canonical(unit, result), outerDispatcherSignature: canonical(unit, stepOne, false),
    outerDispatcher: provenance(unit, stepOne) };
}

function collectTerms(body: Body): LTerm[] {
  if (body.$ === 'Match') return [...body.e.flatMap(collectTerms), ...body.r.flatMap(r => collectTerms(r.f))];
  if (body.$ === 'Local') return [...body.v.flatMap(collectTerms), ...collectTerms(body.f)];
  return [body, ...termChildren(body).flatMap(collectTerms)];
}
function unapply(term: LTerm): { head: LTerm; args: LTerm[] } {
  const args: LTerm[] = [];
  while (true) {
    if (term.$ === 'Var' && term.v !== undefined) {
      requireShape(term.v.$ === 'Ref', 'application', 'unsupported parser substitution');
      term = term.v;
    } else if (term.$ === 'App') { args.unshift(term.x); term = term.f; }
    else break;
  }
  if (term.$ === 'ADT') return { head: { $: 'Ref', k: term.k }, args: [...term.x, ...args] };
  return { head: term, args };
}
function loopFacts(unit: Unit, side: 0 | 1): LoopFacts {
  const chunkKey = functionNames[3][side], stepKey = functionNames[4][side];
  const chunk = declaration(unit, chunkKey), step = declaration(unit, stepKey), cast = declaration(unit, functionNames[0][side]);
  requireShape(step.body && chunk.body && cast.body, chunkKey, 'missing loop/cast bodies');
  const call = step.body.$ !== 'Match' && step.body.$ !== 'Local' ? unapply(step.body) : null;
  requireShape(call?.head.$ === 'Ref' && call.head.k === chunkKey && call.args.length === 3 && call.args[1]!.$ === 'Lit' && call.args[1]!.k === 'Nat' && call.args[1]!.v === 64, stepKey, 'step must call chunk with literal Nat fuel 64');
  requireShape(chunk.body.$ === 'Match' && chunk.body.e.length === 2 && chunk.body.r.length === 3, chunkKey, 'expected three-row fuel/run match');
  const recursiveRow = chunk.body.r[2]!;
  requireShape(recursiveRow.p[0]!.$ === 'PCtr' && recursiveRow.p[0]!.x.length === 1 && recursiveRow.p[0]!.x[0]!.$ === 'PVar', chunkKey, 'recursive row must bind fuel predecessor');
  const predecessor = recursiveRow.p[0]!.x[0]!;
  requireShape(recursiveRow.f.$ !== 'Match' && recursiveRow.f.$ !== 'Local', chunkKey, 'recursive row must directly tail-call chunk');
  const recursive = unapply(recursiveRow.f);
  requireShape(recursive.head.$ === 'Ref' && recursive.head.k === chunkKey && recursive.args.length === 3 && recursive.args[1]!.$ === 'Var' && recursive.args[1]!.i === predecessor.i, chunkKey, 'tail call must consume exact predecessor binder');
  requireShape(collectTerms(cast.body).some(t => t.$ === 'Rwt'), cast.key, 'cast must contain actual equality rewrite AST');
  return { stepQuantum: 64, recursiveFuel: 'exact predecessor-pattern binder',
    sourceRows: new Canonical(unit.symbols, chunkKey).body(chunk.body, chunk.signature!.parameters!.map(p => p[2])),
    equalityRewriteNodes: collectTerms(cast.body).filter(t => t.$ === 'Rwt').length,
    terminationOrNativeAcceptance: 'not checked' };
}

export async function inspectSemanticSchedulerShape(sourcePath: string, originalPath = defaultOriginal) {
  const unknowns: { location: string; reason: string }[] = [];
  let original: Unit | undefined, benchmark: Unit | undefined;
  const comparisons: { original: DeclarationProvenance; benchmark: DeclarationProvenance; equal: boolean; originalShapeSha256: string; benchmarkShapeSha256: string; originalShape: Json; benchmarkShape: Json }[] = [];
  let widths: { original: RequestWidth; benchmark: RequestWidth; equalityRequired: false } | undefined;
  let loops: { original: LoopFacts; benchmark: LoopFacts } | undefined;
  try {
    original = await load(originalPath, 0);
    benchmark = await load(sourcePath, 1);
    requireShape(original.oracle.observation.stage0Sha256 === benchmark.oracle.observation.stage0Sha256, 'provenance', 'parser changed between observations');
    requireShape(benchmark.oracle.imports.length === 1 && benchmark.oracle.imports[0]!.path === 'Base' && benchmark.oracle.imports[0]!.alias === 'Base', 'benchmark imports', 'self-contained surrogate must import only Base');
    const selections: (readonly [string, string, boolean])[] = [
      ...familyNames.map(name => [`Checker${name}`, `Perf${name}`, true] as const),
      ...functionNames.map((pair, i) => [pair[0], pair[1], i < 5] as const),
    ];
    for (const [left, right, body] of selections) {
      const originalShape = canonical(original, left, body), benchmarkShape = canonical(benchmark, right, body);
      comparisons.push({ original: provenance(original, left), benchmark: provenance(benchmark, right),
        equal: encoded(originalShape) === encoded(benchmarkShape), originalShapeSha256: sha(encoded(originalShape)),
        benchmarkShapeSha256: sha(encoded(benchmarkShape)), originalShape, benchmarkShape });
    }
    widths = { original: requestWidth(original, 0), benchmark: requestWidth(benchmark, 1), equalityRequired: false };
    loops = { original: loopFacts(original, 0), benchmark: loopFacts(benchmark, 1) };
  } catch (error) {
    if (!(error instanceof UnsupportedShape)) throw error;
    unknowns.push({ location: error.location, reason: error.reason });
  }
  const witness = {
    schemaVersion: 1, purpose: 'development-surrogate source schema only',
    status: unknowns.length ? 'unsupported' : comparisons.every(row => row.equal) ? 'matched' : 'mismatch',
    passed: unknowns.length === 0 && comparisons.length === 11 && comparisons.every(row => row.equal) && !!widths && !!loops,
    original: original ? unitProvenance(original) : null, benchmark: benchmark ? unitProvenance(benchmark) : null,
    implementation: { path: import.meta.path, sha256: sha(readFileSync(import.meta.path)),
      oracleSha256: sha(readFileSync(resolve(import.meta.dir, 'bootstrap_source_oracle.ts'))),
      typeToolsSha256: sha(readFileSync(resolve(import.meta.dir, 'parser_full_type_env.ts'))),
      declarationAssociationSha256: sha(readFileSync(resolve(import.meta.dir, 'parser_full_declarations.ts'))) },
    symbolMapping: symbolPairs.map(([original, benchmark]) => ({ original, benchmark })),
    coreCoverage: { families: 4, constructors: 9, constructorNames: [...constructorNames],
      note: 'Frozen anchors contain nine constructors, not seven; all nine are compared.',
      equality: 'ordered AST alpha-equivalence; exact quantities, binder dependencies, recursive families, equality rewrite and five loop/cast bodies; result/step_one signatures only' },
    comparisons, requestWidths: widths ?? null, loopModel: loops ?? null, unknowns,
    limitations: [
      'Parser acceptance is not book_valid, native totality/equality validation, compilation or execution.',
      'Request/group widths and handler computations intentionally differ; group dispatch coverage and dependent signatures are structural, not behavioral equivalence.',
      'No type-function evaluation: aliases remain explicit AST references/applications; only parser-resolved unbound Var.v -> Ref links are followed.',
      'No claim about main workload reachability, stdout/checksum correctness, handler execution, owned payload lifetime or IO behavior.',
      'No dynamic first NF/layout query provenance, BIR size, performance measurement or evidence that the expensive original path is reached.',
      'A matching witness licenses only a development surrogate; it never replaces original-source qualification.',
    ],
  };
  return { ...witness, witnessSha256: sha(JSON.stringify(witness)) };
}

if (import.meta.main) {
  const options = new Map<string, string>();
  for (const arg of process.argv.slice(2)) {
    const separator = arg.indexOf('=');
    const key = arg.slice(0, separator), value = arg.slice(separator + 1);
    if (separator < 0 || !['--source', '--original', '--out'].includes(key) || !value || options.has(key))
      throw Error('Usage: bun evals/semantic_scheduler_perf_shape.ts --source=BENCH --out=FRESH_JSON [--original=CHECKER]');
    options.set(key, value);
  }
  const source = options.get('--source'), out = options.get('--out');
  if (!source || !out) throw Error('--source and --out are required');
  const result = await inspectSemanticSchedulerShape(source, options.get('--original'));
  writeFileSync(resolve(out), JSON.stringify(result, null, 2) + '\n', { flag: 'wx' });
  console.log(JSON.stringify({ out: resolve(out), status: result.status, passed: result.passed, witnessSha256: result.witnessSha256 }));
  if (!result.passed) process.exitCode = 1;
}
