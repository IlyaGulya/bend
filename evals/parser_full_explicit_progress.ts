/** Explicit source-body writer instrumentation. Effects are produced by the same
 * AST that is rendered and executed: no cursor relation or returned-remainder
 * comparison participates in this module. Typed matcher expressions are closed
 * into native function-head matches after rewriting; their captures retain the
 * original values and consumption marker span identities. */
import { body_flatten, f32_from_bits, f32_to_bits, list_set, Lit, lit_step, patt_term, term_higher, term_lower, term_show, term_unapply, term_wnf, Var, type Body, type Env, type LTerm, type Patt, type PVar, type Quant } from "../bend2/bend.ts";
import type { ParserGraph, ParserParameter, ParserSignature } from "./parser_full_graph.ts";
import { renderBody } from "./parser_full_body_render.ts";
import { freeBinderIds, LexicalTypes, MissingType, termChildren } from "./parser_full_type_env.ts";
import { createCursorWitnessRuntime, type WitnessCaptureArgument, type WitnessParameter, type WitnessRuntime, type WitnessRuntimeFunction } from "./parser_full_cursor_witness.ts";

export type Progress = "NoProgress" | "Consumed";
export const composeProgress = (a: Progress, b: Progress): Progress => a === "Consumed" || b === "Consumed" ? "Consumed" : "NoProgress";
export type EffectExpression = { kind: "literal"; value: Progress } | { kind: "call"; callee: string; sourceOffset: number; variable: number } | { kind: "or"; effects: EffectExpression[] } | { kind: "branch"; branches: { guards: EffectGuard[]; branchPath: number[]; effect: EffectExpression }[] } | { kind: "witness"; term: LTerm };
export type EffectGuard = { scrutinee: string; constructor: string; branch: number; pattern: string; scrutineeTerm?: LTerm; patternTerm?: Patt; excludedConstructors?: string[]; earlierRows?: { scrutinees: LTerm[]; patterns: Patt[] }[] };
export type ExplicitEffectOperation = {
  kind: "consume" | "call" | "return" | "suspend" | "resume" | "request";
  owner: string; sourceOffset: number; branchPath: number[]; guards: EffectGuard[];
  progress: EffectExpression; callee?: string; frame?: string; outcome?: string; binderId?: number;
  args?: LTerm[]; result?: LTerm; emitted?: LTerm;
};
export type ExplicitFunctionIR = { owner: string; emittedName: string; body: Body; signature: ParserSignature; operations: ExplicitEffectOperation[]; resultKind: "writer" | "control" };
export type ExplicitClosureIR = { owner: string; source: LTerm; emitted: LTerm; type?: LTerm; resultKind: "writer" | "control" | "plain"; parameters: { binderId: number; type: LTerm }[]; activeParameters: number[]; captures: { binderId: number; type: LTerm }[]; operations: ExplicitEffectOperation[] };
export class UnsupportedInstrumentation extends Error {
  readonly code = "UnsupportedInstrumentation";
  constructor(readonly owner: string, readonly sourceOffset: number, readonly reason: string) {
    super(`Unsupported explicit progress instrumentation in ${owner} at ${sourceOffset}: ${reason}`);
    this.name = this.code;
  }
}
export type ExplicitPrimitiveOperation = { kind: "call" | "request" | "suspend" | "resume" | "return"; activeArguments?: readonly number[]; carriesControl?: boolean; frameArgument?: number; captureName?: string; captureArguments?: readonly WitnessCaptureArgument[]; deferredResumes?: readonly { argumentIndex: number; callee: string; parameterIndex: number }[] };
export type ExplicitProgressOptions = {
  tokenElement?: string; controlType?: string; definitions?: Iterable<string>;
  nameOf?: (name: string) => string; progressType?: string; composeName?: string;
  prefixName?: string; emitPrelude?: boolean;
  primitiveOperations?: ReadonlyMap<string, ExplicitPrimitiveOperation>;
  parameterWitnesses?: ReadonlyMap<string, readonly WitnessParameter[]>;
  witnessType?: string;
  /** Actual dispatch/resume targets; omitted means every definition is driver-reachable. */
  driverEntryPoints?: Iterable<string>;
};
export type ConstructorValue = { kind: "constructor"; name: string; fields: RuntimeValue[] };
export type RuntimeClosure = { kind: "function"; invoke: (arg: RuntimeValue) => RuntimeValue };
export type RuntimeValue = ConstructorValue | RuntimeClosure | ((...args: RuntimeValue[]) => RuntimeValue | { value: RuntimeValue; progress: Progress }) | number | bigint | string;
export const constructorValue = (name: string, ...fields: RuntimeValue[]): ConstructorValue => ({ kind: "constructor", name, fields });
export type ExplicitProgressProgram = {
  declarations: string; source: string; declarationMap: Map<string, string>; supportDeclarations: Map<string, string>;
  operations: Map<string, ExplicitEffectOperation[]>; functions: Map<string, ExplicitFunctionIR>; closures: Map<string, ExplicitClosureIR>;
  consumptionLiterals: Map<LTerm, ExplicitEffectOperation>; consumptionExpressions: Map<LTerm, ExplicitEffectOperation>;
  supportFunctions: Map<string, WitnessRuntimeFunction>; typeDeclarations: string[];
  /** Exact appended input-witness slots, including inferred ordinary helpers. */
  parameterWitnesses: ReadonlyMap<string, readonly WitnessParameter[]>;
  execute: (name: string, args: RuntimeValue[], options?: { imports?: Record<string, (...args: RuntimeValue[]) => RuntimeValue>; maxSteps?: number }) => { value: RuntimeValue; progress: Progress };
};
const lone = { $: "Lone" } as const;
const ref = (k: string): LTerm => ({ $: "Ref", k });
const variable = (i: number): LTerm => ({ $: "Var", i, k: `effect_${-i}` });
const ctr = (k: string, ...x: LTerm[]): LTerm => ({ $: "Ctr", k, x });
const apply = (f: LTerm, xs: LTerm[]): LTerm => xs.reduce((f, x) => ({ $: "App", f, x }), f);
const pair = (a: LTerm, b: LTerm): LTerm => ctr("Tuple", a, b);
const literal = (value: Progress): EffectExpression => ({ kind: "literal", value });
const joinEffect = (...effects: EffectExpression[]): EffectExpression => {
  const kept = effects.flatMap(effect => effect.kind === "or" ? effect.effects : [effect]).filter(effect => effect.kind !== "literal" || effect.value !== "NoProgress");
  return kept.length === 0 ? literal("NoProgress") : kept.length === 1 ? kept[0]! : { kind: "or", effects: kept };
};
type WitnessUse = { owner: string; guards: EffectGuard[]; path: number[]; headSpent?: boolean; cause?: WitnessOrigin };
type WitnessOrigin = { owner: string; base: LTerm; uses: WitnessUse[] };
type WitnessSpec = { kind: "origin"; origin: WitnessOrigin; path: number[]; ancestors?: WitnessSpec[] } | { kind: "fields"; fields: WitnessSpec[] } | { kind: "none" };
type WitnessSnapshot = { context: Context; source: LTerm; spec: WitnessSpec; placeholder: LTerm; activationOrigin?: WitnessOrigin };
type Context = { owner: string; path: number[]; guards: EffectGuard[]; tails: ReadonlySet<number>; bindings?: ReadonlyMap<number, LTerm>; matchable?: ReadonlySet<number>; witnesses?: ReadonlyMap<number, WitnessSpec>; singleCallClosures?: ReadonlySet<LTerm>; calleeHeads?: ReadonlySet<LTerm> };
type Writer = { term: LTerm; effect: EffectExpression };
function substituteBinder(term: LTerm, binder: number, value: LTerm): LTerm {
  if (term.$ === "Var") return term.i === binder ? value : term;
  if ((term.$ === "Lam" || term.$ === "All" || term.$ === "Sub") && term.i === binder) return term;
  if (term.$ === "Let" && term.i.includes(binder)) return { ...term, v: term.v.map(child => substituteBinder(child, binder, value)) };
  const children = termChildren(term);
  if (!children.length) return term;
  const copy = { ...term } as unknown as Record<string, unknown>;
  for (const [key, child] of Object.entries(term)) {
    if (key === "s") continue;
    if (Array.isArray(child)) copy[key] = child.map(item => children.includes(item as LTerm) ? substituteBinder(item as LTerm, binder, value) : item);
    else if (child && typeof child === "object" && children.includes(child as LTerm)) copy[key] = substituteBinder(child as LTerm, binder, value);
  }
  return copy as LTerm;
}
export function containsTokenCursor(graph: ParserGraph, type: LTerm, tokenElement = "lexer.Token", seen = new Set<string>()): boolean {
  const [head, args] = term_unapply(type);
  const elements = head.$ === "ADT" && head.k === "List" ? head.x : head.$ === "Ref" && head.k === "List" ? args : [];
  if (elements.some(element => (element.$ === "Ref" || element.$ === "ADT") && element.k === tokenElement)) return true;
  if (type.$ === "All") return containsTokenCursor(graph, type.B, tokenElement, seen);
  if (type.$ === "Ref" && graph.parserBook.tlds[type.k]?.$ === "ADT") return containsTokenCursor(graph, { $: "ADT", k: type.k, x: [], r: [] }, tokenElement, seen);
  if (type.$ === "ADT") {
    if (type.x.some(child => containsTokenCursor(graph, child, tokenElement, seen))) return true;
    if (seen.has(type.k)) return false;
    const declaration = graph.parserBook.tlds[type.k];
    if (declaration?.$ === "ADT") {
      const next = new Set([...seen, type.k]);
      for (const constructor of declaration.c) {
        let telescope = term_lower(constructor.T);
        while (telescope.$ === "All") {
          if (containsTokenCursor(graph, telescope.A, tokenElement, next)) return true;
          telescope = telescope.B;
        }
      }
    }
  }
  return type.$ === "App" && termChildren(type).some(child => containsTokenCursor(graph, child, tokenElement, seen));
}

export function instrumentExplicitProgress(graph: ParserGraph, options: ExplicitProgressOptions = {}): ExplicitProgressProgram {
  const selected = new Set(options.definitions ?? graph.definitions);
  const nameOf = options.nameOf ?? ((name: string) => `ep_${name}`);
  const progressType = options.progressType ?? "Progress";
  const composeName = options.composeName ?? "feedback_compose_progress";
  const prefixName = options.prefixName ?? "feedback_prefix";
  const tokenElement = options.tokenElement ?? "lexer.Token";
  const controlType = options.controlType ?? "FeedbackControl";
  const types = new LexicalTypes(graph.parserBook, graph.signatures);
  for (const name of selected) {
    const body = graph.bodies.get(name), signature = graph.signatures.get(name);
    if (!body || !signature) throw new UnsupportedInstrumentation(name, 0, "selected declaration has no source Body/signature");
    types.indexBody(body, signature.parameters, signature.result);
  }
  const driverReachable = new Set(options.driverEntryPoints ?? selected);
  const driverWork = [...driverReachable];
  for (let index = 0; index < driverWork.length; index++) {
    for (const dependency of graph.edges[driverWork[index]!] ?? []) if (!driverReachable.has(dependency)) {
      driverReachable.add(dependency); driverWork.push(dependency);
    }
  }
  const initializationOnly = new Set([...selected].filter(name => !driverReachable.has(name)));
  let fresh = -1;
  const id = () => fresh--;
  const offset = (term: LTerm | Patt | Body) => term.s?.beg ?? 0;
  const fail = (context: Context, node: LTerm | Patt | Body, reason: string): never => { throw new UnsupportedInstrumentation(context.owner, offset(node), reason); };
  const isNamed = (type: LTerm, name: string) => (type.$ === "ADT" || type.$ === "Ref") && type.k === name;
  const tokenList = (type: LTerm): boolean => {
    const [head, args] = term_unapply(type);
    return (head.$ === "ADT" && head.k === "List" ? head.x : head.$ === "Ref" && head.k === "List" ? args : []).some(x => isNamed(x, tokenElement));
  };
  const containsCursor = (type: LTerm) => containsTokenCursor(graph, type, tokenElement);
  const controlResult = (name: string) => isNamed(graph.signatures.get(name)!.result, controlType);
  const active = new Set([...selected].filter(name => containsCursor(graph.signatures.get(name)!.result) || controlResult(name)));
  function cursorCallbackCalls(value: LTerm | Body): boolean {
    if (value.$ === "Local") return (value.q.$ !== "None" && value.v.some(cursorCallbackCalls)) || cursorCallbackCalls(value.f);
    if (value.$ === "Match") return value.e.some(cursorCallbackCalls) || value.r.some(row => cursorCallbackCalls(row.f));
    if (value.$ === "App") {
      const [head, arguments_] = term_unapply(value);
      if (head.$ === "Var") {
        try {
          let result = types.typeOf(head), arity = 0;
          while (result.$ === "All") { arity++; result = result.B; }
          if (arguments_.length === arity && (containsCursor(result) || isNamed(result, controlType))) return true;
        } catch (error) { if (!(error instanceof MissingType)) throw error; }
      }
    }
    return termChildren(value as LTerm).some(cursorCallbackCalls);
  }
  for (const owner of selected) if (cursorCallbackCalls(graph.bodies.get(owner)!)) active.add(owner);
  let changed = true;
  while (changed) {
    changed = false;
    for (const name of selected) if (!active.has(name) && (graph.calls.get(name) ?? []).some(call => active.has(call.callee))) { active.add(name); changed = true; }
  }
  function typeOf(term: LTerm, context: Context): LTerm {
    if (term.$ === "Var" && context.bindings?.has(term.i)) return context.bindings.get(term.i)!;
    try { return types.typeOf(term); }
    catch (error) { if (error instanceof MissingType) return fail(context, term, error.message); throw error; }
  }
  function writerType(type: LTerm): LTerm {
    if (!graph.parserBook.ctrs.Tuple || !graph.parserBook.tlds.Pair) throw new UnsupportedInstrumentation("<ABI>", 0, "Base Pair/Tuple is unavailable");
    return apply(ref("Pair"), [callbackType(type), ref(progressType)]);
  }
  function callbackType(type: LTerm): LTerm {
    if (type.$ === "All") {
      const parameters: Extract<LTerm, { $: "All" }>[] = [];
      let result: LTerm = type;
      while (result.$ === "All") { parameters.push(result); result = result.B; }
      let transformed = isNamed(result, controlType) ? result : writerType(result);
      for (const parameter of parameters.filter(parameter => parameter.q.$ !== "None" && containsCursor(parameter.A)).reverse()) {
        witnessLibrary();
        const binder = id();
        transformed = { $: "All", q: { $: "Many" }, k: `callback_witness_${-binder}`, i: binder, A: ref(witnessType), B: transformed };
      }
      return parameters.reduceRight<LTerm>((B, parameter) => ({ ...parameter, A: parameter.q.$ === "None" ? parameter.A : callbackType(parameter.A), B }), transformed);
    }
    if (type.$ === "App") return { ...type, f: callbackType(type.f), x: callbackType(type.x) };
    if (type.$ === "Lam") return { ...type, f: callbackType(type.f) };
    if (type.$ === "ADT" || type.$ === "Ref") {
      const declaration = graph.parserBook.tlds[type.k];
      if (declaration?.$ === "ADT") for (const constructor of declaration.c) {
        let field = term_lower(constructor.T);
        for (let i = 0; i < declaration.n && field.$ === "All"; i++) field = field.B;
        while (field.$ === "All") {
          if (field.q.$ !== "None" && field.A.$ === "All") throw new UnsupportedInstrumentation("<ABI>", offset(type), `datatype ${type.k} has a concrete function field; its callback ABI cannot be transported without datatype rewriting`);
          field = field.B;
        }
      }
      if (type.$ === "ADT") return { ...type, x: type.x.map(callbackType) };
    }
    return type;
  }
  function nextTypeBinder(terms: LTerm[]): number {
    let next = 0;
    const visit = (node: LTerm) => {
      if ("i" in node) for (const binder of Array.isArray(node.i) ? node.i : [node.i]) next = Math.max(next, binder + 1);
      termChildren(node).forEach(visit);
    };
    terms.forEach(visit);
    return next;
  }
  function normalizeType(type: LTerm): LTerm {
    let environment: Env = null;
    for (const binder of freeBinderIds(type)) environment = list_set(environment, binder, Var(`type_${binder}`, binder));
    return term_lower(term_wnf(graph.parserBook, term_higher(type, environment)), nextTypeBinder([type]));
  }
  function constructorGoals(term: Extract<LTerm, { $: "Ctr" }>, expected: LTerm): LTerm[] {
    const instance = normalizeType(expected);
    if (instance.$ !== "ADT") throw new UnsupportedInstrumentation(emittingOwner, offset(term), "constructor has no declared datatype instance");
    const declaration = graph.parserBook.tlds[instance.k], constructor = graph.parserBook.ctrs[term.k];
    if (declaration?.$ !== "ADT" || !constructor || !declaration.c.some(field => field.k === term.k)) throw new UnsupportedInstrumentation(emittingOwner, offset(term), "constructor does not belong to its declared result type");
    let field = term_lower(constructor.T, nextTypeBinder([instance, ...term.x]));
    for (const argument of instance.x) {
      if (field.$ !== "All") throw new UnsupportedInstrumentation(emittingOwner, offset(term), "constructor type-argument arity mismatch");
      field = substituteBinder(field.B, field.i, argument);
    }
    const goals: LTerm[] = [];
    for (const value of term.x) {
      const head = normalizeType(field);
      if (head.$ !== "All") throw new UnsupportedInstrumentation(emittingOwner, offset(term), "constructor field-argument arity mismatch");
      goals.push(head.A);
      field = substituteBinder(head.B, head.i, value);
    }
    return goals;
  }
  const operations = new Map<string, ExplicitEffectOperation[]>();
  for (const name of selected) operations.set(name, []);
  const consumptionLiterals = new Map<LTerm, ExplicitEffectOperation>(), consumptionExpressions = new Map<LTerm, ExplicitEffectOperation>();
  const consumptionBySpan = new WeakMap<object, ExplicitEffectOperation>();
  function emit(context: Context, node: LTerm | Body, operation: Omit<ExplicitEffectOperation, "owner" | "sourceOffset" | "branchPath" | "guards">): ExplicitEffectOperation {
    const emitted = { ...operation, owner: context.owner, sourceOffset: offset(node), branchPath: [...context.path], guards: [...context.guards] };
    operations.get(context.owner)!.push(emitted);
    return emitted;
  }
  const neutral = ctr("NoProgress");
  const witnessType = options.witnessType ?? "FeedbackCursorWitness";
  const witnessesEnabled = !!options.parameterWitnesses?.size || [...(options.primitiveOperations?.values() ?? [])].some(operation => operation.captureArguments?.length);
  let witnessRuntime: WitnessRuntime | undefined;
  const witnessLibrary = () => witnessRuntime ??= createCursorWitnessRuntime(graph.parserBook, id, { typeName: witnessType, progressType, composeName });
  if (witnessesEnabled) witnessLibrary();
  // Ordinary helpers may defer cursor-input credit only when their typed binder
  // uses are confined to mutually exclusive runtime branches. This proof is an
  // overapproximation of activation: observing a cursor counts as a use too.
  type InputRegion = ReadonlyMap<object, number>;
  type InputRegions = Map<number, InputRegion[]>;
  const exclusiveHelpers = new Map<string, InputRegions>();
  const cursorParameters = (signature: ParserSignature) => signature.parameters.flatMap((parameter, index) => parameter[0].$ !== "None" && containsCursor(parameter[3]) ? [index] : []);
  const disjointRegions = (left: InputRegion, right: InputRegion) => [...left].some(([branch, row]) => right.has(branch) && right.get(branch) !== row);
  function inputRegions(owner: string): InputRegions | undefined {
    const signature = graph.signatures.get(owner)!;
    const indices = cursorParameters(signature), regions: InputRegions = new Map(indices.map(index => [index, []]));
    type Inputs = ReadonlyMap<number, ReadonlySet<number>>;
    const inputs = new Map<number, ReadonlySet<number>>(indices.map(index => [signature.parameters[index]![2], new Set([index])]));
    let suspendedInput = false;
    const alias = (term: LTerm, scope: Inputs): ReadonlySet<number> | undefined => term.$ === "Var" ? scope.get(term.i) ?? new Set() : term.$ === "Ann" ? alias(term.x, scope) : undefined;
    const record = (dependencies: ReadonlySet<number>, region: InputRegion, suspended: boolean) => {
      if (suspended && dependencies.size) suspendedInput = true;
      for (const index of dependencies) regions.get(index)!.push(region);
    };
    const branch = (region: InputRegion, node: object, row: number) => new Map([...region, [node, row] as const]);
    function bind(pattern: Patt, dependencies: ReadonlySet<number>, scope: Map<number, ReadonlySet<number>>) {
      if (pattern.$ === "PVar") scope.set(pattern.i, dependencies);
      else pattern.x.forEach(field => bind(field, dependencies, scope));
    }
    function visitMatcher(node: LTerm, dependencies: ReadonlySet<number>, scope: Inputs, region: InputRegion, key: object, row: number, suspended: boolean) {
      if (node.$ === "Efq") return;
      if (node.$ === "Lam") {
        const inner = new Map(scope); inner.set(node.i, dependencies);
        visit(node.f, inner, branch(region, key, row), suspended); return;
      }
      if (node.$ !== "Mat") { visit(node, scope, region, suspended); return; }
      const inner = new Map(scope);
      let leaf = node.h;
      while (leaf.$ === "Lam") { inner.set(leaf.i, dependencies); leaf = leaf.f; }
      visit(leaf, inner, branch(region, key, row), suspended);
      visitMatcher(node.m, dependencies, scope, region, key, row + 1, suspended);
    }
    function visit(node: LTerm, scope: Inputs, region: InputRegion, suspended = false) {
      if (node.$ === "Var") { record(scope.get(node.i) ?? new Set(), region, suspended); return; }
      if (node.$ === "Ann") { visit(node.x, scope, region, suspended); return; }
      if (node.$ === "All" || node.$ === "ADT" || node.$ === "Typ" || node.$ === "Qnt" || node.$ === "Qua") return;
      if (node.$ === "Lam") { visit(node.f, scope, region, true); return; }
      if (node.$ === "Let") {
        const inner = new Map(scope);
        node.v.forEach((value, index) => {
          const dependencies = alias(value, scope);
          if (dependencies) inner.set(node.i[index]!, dependencies);
          else visit(value, scope, region, suspended);
        });
        visit(node.f, inner, region, suspended); return;
      }
      if (node.$ === "Sub") {
        const value = patt_term(node.v);
        const dependencies = alias(value, scope), inner = new Map(scope);
        if (dependencies) inner.set(node.i, dependencies); else visit(value, scope, region, suspended);
        visit(node.f, inner, region, suspended); return;
      }
      if (node.$ === "App") {
        const [rawHead, arguments_] = term_unapply(node);
        let head = rawHead;
        while (head.$ === "Ann") head = head.x;
        if ((head.$ === "Mat" || head.$ === "Efq") && arguments_.length === 1) {
          visit(arguments_[0]!, scope, region, suspended);
          visitMatcher(head, alias(arguments_[0]!, scope) ?? new Set(), scope, region, node, 0, suspended); return;
        }
        const callee = head.$ === "Ref" ? exclusiveHelpers.get(head.k) : undefined;
        const calleeSignature = head.$ === "Ref" ? graph.signatures.get(head.k) : undefined;
        if (callee && calleeSignature && arguments_.length === calleeSignature.parameters.length) {
          // Each invocation gets fresh choice identities: two calls to one
          // selector must not be mistaken for one shared branch decision.
          const choices = new Map<object, object>();
          arguments_.forEach((argument, index) => {
            const dependencies = alias(argument, scope), uses = callee.get(index);
            if (!dependencies || !uses) { visit(argument, scope, region, suspended); return; }
            for (const use of uses) {
              const inner = new Map(region);
              for (const [choice, row] of use) {
                let local = choices.get(choice);
                if (!local) { local = {}; choices.set(choice, local); }
                inner.set(local, row);
              }
              record(dependencies, inner, suspended);
            }
          });
          return;
        }
      }
      termChildren(node).forEach(child => visit(child, scope, region, suspended));
    }
    function visitBody(node: Body, scope: Inputs, region: InputRegion) {
      if (node.$ !== "Local" && node.$ !== "Match") { visit(node, scope, region); return; }
      if (node.$ === "Local") {
        if (node.q.$ === "None") { visitBody(node.f, scope, region); return; }
        const inner = new Map(scope);
        node.v.forEach((value, index) => {
          const dependencies = alias(value, scope);
          if (dependencies) bind(node.k[index]!, dependencies, inner); else visit(value, scope, region);
        });
        visitBody(node.f, inner, region); return;
      }
      node.e.forEach(value => visit(value, scope, region));
      node.r.forEach((row, index) => {
        const inner = new Map(scope);
        row.p.forEach((pattern, column) => bind(pattern, alias(node.e[column]!, scope) ?? new Set(), inner));
        visitBody(row.f, inner, branch(region, node, index));
      });
    }
    visitBody(graph.bodies.get(owner)!, inputs, new Map());
    if (suspendedInput) return undefined;
    for (let i = 0; i < indices.length; i++) for (let j = i + 1; j < indices.length; j++) {
      if (regions.get(indices[i]!)!.some(left => regions.get(indices[j]!)!.some(right => !disjointRegions(left, right)))) return undefined;
    }
    return regions;
  }
  // Bottom-up discovery also proves ordinary wrappers forwarding inputs into a
  // known selector. Unknown/recursive simultaneous forwarding stays unproved.
  for (let added = true; added;) {
    added = false;
    for (const owner of selected) {
      if (exclusiveHelpers.has(owner) || options.parameterWitnesses?.has(owner) || cursorParameters(graph.signatures.get(owner)!).length < 2) continue;
      const proof = inputRegions(owner);
      if (proof) { exclusiveHelpers.set(owner, proof); added = true; }
    }
  }
  function semanticCursorCallback(type: LTerm): boolean {
    if (type.$ !== "All") return false;
    let cursorInput = false;
    while (type.$ === "All") {
      cursorInput ||= type.q.$ !== "None" && containsCursor(type.A);
      type = type.B;
    }
    return cursorInput && !containsCursor(type) && !isNamed(type, controlType);
  }
  const parameterWitnesses = new Map(options.parameterWitnesses);
  for (const owner of exclusiveHelpers.keys()) parameterWitnesses.set(owner, cursorParameters(graph.signatures.get(owner)!).map(parameterIndex => ({ parameterIndex, witnessName: `input_witness_${parameterIndex}` })));
  for (const owner of selected) {
    const signature = graph.signatures.get(owner)!;
    if (!signature.parameters.some(parameter => parameter[0].$ !== "None" && semanticCursorCallback(parameter[3]))) continue;
    const parameters = [...(parameterWitnesses.get(owner) ?? [])];
    signature.parameters.forEach((parameter, parameterIndex) => {
      if (parameter[0].$ !== "None" && containsCursor(parameter[3]) && !parameters.some(witness => witness.parameterIndex === parameterIndex)) parameters.push({ parameterIndex, witnessName: `callback_input_witness_${parameterIndex}` });
    });
    if (parameters.length) parameterWitnesses.set(owner, parameters);
  }
  const noWitness: WitnessSpec = { kind: "none" };
  const snapshots: WitnessSnapshot[] = [];
  const resultOwnership = new WeakMap<LTerm, Map<string, WitnessSpec>>();
  const generatedBinderTypes = new Map<number, LTerm>();
  const knownNoWitness = (term: LTerm) => term.$ === "Ctr" && term.k === "WitnessNone" && !snapshots.some(snapshot => snapshot.placeholder === term || snapshot.placeholder.s === term.s);
  const activeSnapshot = (snapshot: WitnessSnapshot) => !snapshot.activationOrigin || snapshot.activationOrigin.uses.length > 0 || snapshots.some(other => other.context.owner === snapshot.activationOrigin!.owner && refs(other.spec).some(reference => reference.origin === snapshot.activationOrigin));
  const nat = (n: number): LTerm => n === 0 ? ctr("Zero") : ctr("Succ", nat(n - 1));
  const list = (items: LTerm[]): LTerm => items.reduceRight((tail, head) => ctr("Con", head, tail), ctr("Nil"));
  const pathTerm = (path: number[]) => list(path.map(nat));
  const dominates = (guards: EffectGuard[], context: Context) => guards.every(guard => context.guards.includes(guard));
  const incompatible = (a: EffectGuard[], b: EffectGuard[]) => a.some(x => b.some(y => x.scrutineeTerm === y.scrutineeTerm && x.constructor !== "*" && y.constructor !== "*" && x.constructor !== y.constructor));
  const overlaps = (a: number[], b: number[]) => a.slice(0, Math.min(a.length, b.length)).every((part, index) => part === b[index]);
  function refs(spec: WitnessSpec): Extract<WitnessSpec, { kind: "origin" }>[] {
    return spec.kind === "origin" ? [spec] : spec.kind === "fields" ? spec.fields.flatMap(refs) : [];
  }
  function related(a: Extract<WitnessSpec, { kind: "origin" }>, b: Extract<WitnessSpec, { kind: "origin" }>): boolean {
    if (a.origin === b.origin && overlaps(a.path, b.path)) return true;
    return !!a.ancestors?.some(ancestor => refs(ancestor).some(parent => related(parent, b))) || !!b.ancestors?.some(ancestor => refs(ancestor).some(parent => related(a, parent)));
  }
  function assertHeadOwnership(spec: WitnessSpec, context: Context, source: LTerm, final = false) {
    for (const reference of refs(spec)) {
      const checks = [reference, ...(reference.ancestors ?? []).flatMap(refs)];
      if (checks.some(parent => parent.origin.uses.some(use => use.headSpent && use.cause !== reference.origin && use.owner === context.owner && overlaps(use.path, parent.path) && !incompatible(use.guards, context.guards) && (final || dominates(use.guards, context))))) return fail(context, source, "preserving or reactivating an ancestor cursor after its matched tail advances requires unsupported shared-head ownership");
    }
  }
  function assertDistinctCursors(terms: LTerm[], context: Context, exclusive = false) {
    const references = terms.flatMap((term, slot) => refs(witnessOf(term, context)).map(reference => ({ slot, reference })));
    for (let i = 0; i < references.length; i++) for (let j = i + 1; j < references.length; j++) {
      const a = references[i]!, b = references[j]!;
      if (exclusive && a.slot !== b.slot) continue;
      if (related(a.reference, b.reference)) return fail(context, terms[0]!, "aliased active cursor arguments/results require unsupported shared-head ownership");
    }
  }
  function witnessOf(term: LTerm, context: Context): WitnessSpec {
    if (term.$ === "Var") return context.witnesses?.get(term.i) ?? noWitness;
    if (term.$ === "Ann") return witnessOf(term.x, context);
    if (term.$ === "Ctr") return { kind: "fields", fields: term.x.map(child => witnessOf(child, context)) };
    if (term.$ === "Let") {
      const witnesses = new Map(context.witnesses);
      term.v.forEach((value, index) => witnesses.set(term.i[index]!, witnessOf(value, context)));
      return witnessOf(term.f, { ...context, witnesses });
    }
    if (term.$ === "Sub") {
      const value = patt_term(term.v);
      const witnesses = new Map(context.witnesses); witnesses.set(term.i, witnessOf(value, context));
      return witnessOf(term.f, { ...context, witnesses });
    }
    if (term.$ === "App") {
      const projection = structuralProjection(term, context);
      if (projection) return projection;
    }
    if ((term.$ === "App" || term.$ === "Ref") && typeOf(term, context).$ !== "All" && containsCursor(typeOf(term, context))) {
      let owners = resultOwnership.get(term);
      if (!owners) { owners = new Map(); resultOwnership.set(term, owners); }
      let spec = owners.get(context.owner);
      if (!spec) {
        // A call transfers its result's ownership. This is not a new consumption
        // witness and does not infer which input cursor the result aliases.
        spec = { kind: "origin", origin: { owner: context.owner, base: ctr("WitnessNone"), uses: [] }, path: [] };
        owners.set(context.owner, spec);
      }
      return spec;
    }
    return noWitness;
  }
  function structuralProjection(term: LTerm, context: Context): WitnessSpec | undefined {
    const [rawHead, args] = term_unapply(term);
    let head = rawHead;
    while (head.$ === "Ann") head = head.x;
    if (head.$ !== "Mat" || args.length !== 1 || head.m.$ !== "Efq") return undefined;
    const witnesses = new Map(context.witnesses), bindings = new Map(context.bindings), source = witnessOf(args[0]!, context);
    const constructor = graph.parserBook.ctrs[head.k];
    if (!constructor) return fail(context, head, "structural projection constructor has no declaration");
    const binders: Extract<LTerm, { $: "Lam" }>[] = [];
    let handler = head.h;
    for (let index = 0; index < constructor.n; index++) {
      while (handler.$ === "Ann") handler = handler.x;
      if (handler.$ !== "Lam") return fail(context, handler, "structural projection field has no explicit binder");
      binders.push(handler); handler = handler.f;
    }
    const fields = constructorGoals({ $: "Ctr", k: head.k, x: binders.map(binder => ({ $: "Var", k: binder.k, i: binder.i })) }, typeOf(args[0]!, context));
    binders.forEach((binder, index) => {
      const field = fields[index]!;
      bindings.set(binder.i, field);
      witnesses.set(binder.i, containsCursor(field) ? project(source, index) : noWitness);
    });
    while (handler.$ === "Ann") handler = handler.x;
    if (handler.$ === "Var") return witnesses.get(handler.i);
    return handler.$ === "App" ? structuralProjection(handler, { ...context, bindings, witnesses }) : undefined;
  }
  function project(spec: WitnessSpec, field: number): WitnessSpec {
    return spec.kind === "origin" ? { ...spec, path: [...spec.path, field] } : spec.kind === "fields" ? spec.fields[field] ?? noWitness : noWitness;
  }
  function bindWitness(pattern: Patt, spec: WitnessSpec, context: Context, target: Map<number, WitnessSpec>, tails: ReadonlySet<number>, type: LTerm) {
    if (pattern.$ === "PVar") { target.set(pattern.i, containsCursor(type) ? spec : noWitness); return; }
    const fields = constructorGoals({ $: "Ctr", k: pattern.k, x: pattern.x.map(child => patt_term(child)) }, type);
    pattern.x.forEach((child, index) => {
      let field = project(spec, index);
      if (pattern.k === "Con" && index === 1 && child.$ === "PVar" && tails.has(child.i)) {
        field = { kind: "origin", origin: { owner: context.owner, base: ctr("WitnessTail", ctr("Consumed")), uses: [] }, path: [], ancestors: [spec] };
      }
      bindWitness(child, field, context, target, tails, fields[index]!);
    });
  }
  function witnessValue(spec: WitnessSpec, context: Context, final = false): LTerm {
    if (spec.kind === "none") return ctr("WitnessNone");
    if (spec.kind === "fields") return ctr("WitnessFields", list(spec.fields.map(field => witnessValue(field, context, final))));
    let base = spec.origin.base;
    for (const use of spec.origin.uses) {
      if (use.owner !== context.owner || incompatible(use.guards, context.guards)) continue;
      if (dominates(use.guards, context)) base = use.path.length === 0 ? ctr("WitnessNone") : apply(ref("feedback_witness_clear"), [pathTerm(use.path), base]);
      else if (final && !knownNoWitness(base) && overlaps(use.path, spec.path)) return fail(context, base, "conditional deferred-witness retirement cannot be represented at this earlier capture");
    }
    if (knownNoWitness(base)) return base;
    return spec.path.length ? apply(ref("feedback_witness_get"), [pathTerm(spec.path), base]) : base;
  }
  function retire(spec: WitnessSpec, context: Context, headSpent = false, cause?: WitnessOrigin) {
    for (const reference of refs(spec)) {
      reference.origin.uses.push({ owner: context.owner, guards: [...context.guards], path: reference.path, headSpent, cause });
      reference.ancestors?.forEach(ancestor => retire(ancestor, context, true, cause ?? reference.origin));
    }
  }
  function captureWitness(spec: WitnessSpec, context: Context, source: LTerm, activationOrigin?: WitnessOrigin): LTerm {
    if (refs(spec).length) witnessLibrary();
    const placeholder: LTerm = { ...ctr("WitnessNone"), s: {file:{str:"",ns:'',al:{}},beg:0,end:0} };
    snapshots.push({ context, source, spec, placeholder, activationOrigin });
    return placeholder;
  }
  function finalizeWitnesses(owner: string) {
    const owned = snapshots.filter(snapshot => snapshot.context.owner === owner && activeSnapshot(snapshot));
    for (const snapshot of snapshots) if (snapshot.context.owner === owner && !activeSnapshot(snapshot)) Object.assign(snapshot.placeholder, ctr("WitnessNone"));
    for (const snapshot of owned) assertHeadOwnership(snapshot.spec, snapshot.context, snapshot.source, true);
    const pending = owned.map(snapshot => ({ snapshot, references: refs(snapshot.spec).filter(reference => !reference.origin.uses.some(use => use.owner === owner && dominates(use.guards, snapshot.context) && use.path.length <= reference.path.length && overlaps(use.path, reference.path))) }));
    for (const { snapshot, references } of pending) for (let i = 0; i < references.length; i++) for (let j = i + 1; j < references.length; j++) if (related(references[i]!, references[j]!)) return fail(snapshot.context, snapshot.source, "aliased cursor fields in one capture duplicate deferred ownership");
    for (let i = 0; i < pending.length; i++) for (let j = i + 1; j < pending.length; j++) {
      const a = pending[i]!, b = pending[j]!;
      if (incompatible(a.snapshot.context.guards, b.snapshot.context.guards)) continue;
      if (a.references.some(x => b.references.some(y => related(x, y)))) return fail(a.snapshot.context, a.snapshot.source, "overlapping live deferred-witness captures would duplicate one-shot consumption credit");
    }
    for (const { snapshot } of pending) Object.assign(snapshot.placeholder, witnessValue(snapshot.spec, snapshot.context, true));
  }
  function refreshSnapshots(value: unknown, visited = new Set<object>()) {
    if (!value || typeof value !== "object" || visited.has(value as object)) return;
    visited.add(value as object);
    const node = value as LTerm;
    const snapshot = node.s && snapshots.find(snapshot => snapshot.placeholder.s === node.s);
    if (snapshot && node !== snapshot.placeholder) Object.assign(node, snapshot.placeholder);
    for (const [key, child] of Object.entries(value)) if (key !== "s") { if (Array.isArray(child)) child.forEach(item => refreshSnapshots(item, visited)); else refreshSnapshots(child, visited); }
  }
  const compose = (a: LTerm, b: LTerm): LTerm => a.$ === "Ctr" && a.k === "NoProgress" ? b : b.$ === "Ctr" && b.k === "NoProgress" ? a : apply(ref(composeName), [a, b]);
  const withEffectName = "feedback_with_effect";
  const writerValues = new WeakMap<LTerm, LTerm>();
  const semanticGoals = new WeakMap<LTerm, LTerm>();
  const generatedTermTypes = new WeakMap<LTerm, LTerm>();
  const matcherApplications = new WeakMap<LTerm, { input: LTerm; result: LTerm }>();
  let continuationGoal: LTerm | undefined;
  let emittingOwner = "<ABI>";
  const withEffect = (writer: LTerm, valueType: LTerm, resultType: LTerm, next: LTerm): LTerm =>
    apply(ref(withEffectName), [valueType, resultType, writer, next]);
  function unpack(writer: LTerm, continuation: (value: LTerm, progress: LTerm) => LTerm): LTerm {
    if (writer.$ === "Ctr" && writer.k === "Tuple" && writer.x.length === 2) return continuation(writer.x[0]!, writer.x[1]!);
    const valueType = writerValues.get(writer);
    if (!valueType || !continuationGoal) throw new UnsupportedInstrumentation(emittingOwner, writer.s?.beg ?? 0, "writer elimination lacks explicit value/continuation types");
    const resultType = continuationGoal;
    const a = id(), b = id();
    const handler: LTerm = { $: "Lam", k: `effect_${-a}`, i: a, f: { $: "Lam", k: `effect_${-b}`, i: b, f: continuation(variable(a), variable(b)) } };
    return withEffect(writer, valueType, resultType, handler);
  }
  function directUse(term: LTerm, context: Context, activePosition: boolean): LTerm | undefined {
    if (!activePosition || term.$ !== "Var") return undefined;
    const spec = witnessOf(term, context);
    assertHeadOwnership(spec, context, term);
    if (!context.tails.has(term.i) && !refs(spec).length) return undefined;
    const value = witnessValue(spec, context);
    if (knownNoWitness(value)) { retire(spec, context, true); return undefined; }
    const structural = value.$ === "Ctr" && value.k === "WitnessTail" && value.x[0]?.$ === "Ctr" && value.x[0].k === "Consumed";
    if (!structural) witnessLibrary();
    const marker: LTerm = { ...(structural ? ctr("Consumed") : apply(ref("feedback_witness_progress"), [value])), s: {file:{str:"",ns:'',al:{}},beg:0,end:0} };
    const effect: EffectExpression = structural ? literal("Consumed") : { kind: "witness", term: marker };
    const operation = emit(context, term, { kind: "consume", progress: effect, binderId: term.i, emitted: marker });
    consumptionBySpan.set(marker.s!, operation);
    retire(spec, context, true);
    return marker;
  }
  function cursorFreeCallable(type: LTerm): boolean {
    while (type.$ === "All") {
      if (type.q.$ !== "None" && containsCursor(type.A)) return false;
      type = type.B;
    }
    return !containsCursor(type) && !isNamed(type, controlType);
  }
  function pureCallback(term: LTerm, expected: LTerm, seen = new Set<string>()): boolean {
    if (!cursorFreeCallable(expected)) return false;
    const root = term.$ === "Ann" ? term.x : term;
    if (root.$ === "Var") return false; // An opaque callback has no body proof.
    if (root.$ === "Lam") {
      try { if (types.captures(root).some(binding => !cursorFreeCallable(binding.type))) return false; }
      catch (error) { if (error instanceof MissingType) return false; throw error; }
    }
    function bodyFree(node: Body): boolean {
      if (node.$ !== "Local" && node.$ !== "Match") return visit(node);
      if (node.$ === "Local") return (node.q.$ === "None" || node.v.every(visit)) && bodyFree(node.f);
      return node.e.every(visit) && node.r.every(row => bodyFree(row.f));
    }
    function visit(node: LTerm): boolean {
      if (node.$ === "All" || node.$ === "ADT" || node.$ === "Typ" || node.$ === "Qnt" || node.$ === "Qua") return true;
      if (node.$ === "Ann") return visit(node.x);
      if (node.$ === "Ref") {
        const signature = graph.signatures.get(node.k);
        if (signature) {
          if (signature.parameters.some(parameter => parameter[0].$ !== "None" && !cursorFreeCallable(parameter[3])) || !cursorFreeCallable(signature.result)) return false;
          if (selected.has(node.k)) {
            if (seen.has(node.k)) return true;
            seen.add(node.k);
            return bodyFree(graph.bodies.get(node.k)!);
          }
        }
        return true;
      }
      if (node.$ === "Var") {
        try {
          const binding = types.environmentAt(node).get(node.i);
          if (binding && !cursorFreeCallable(binding.type)) return false;
        } catch (error) {
          // Mat's field lambdas have no standalone inference goal. Their values
          // originate only in the cursor-free inputs/constructions checked here.
          if (!(error instanceof MissingType)) throw error;
        }
        return true;
      }
      if (node.$ === "App" || node.$ === "Ctr" && node.k === "Con") {
        const [head] = term_unapply(node);
        if (head.$ === "Var") return false; // Unknown child effects cannot be erased.
        if (head.$ !== "Mat" && head.$ !== "Efq") {
          try { if (!cursorFreeCallable(types.typeOf(node))) return false; }
          catch (error) { if (error instanceof MissingType) return false; throw error; }
        }
      }
      return termChildren(node).every(visit);
    }
    return visit(term);
  }
  function calledOnce(value: Body | LTerm, binder: number): boolean {
    let calls = 0, invalid = false;
    function visit(node: Body | LTerm, suspended = false) {
      if (node.$ === "Local") { node.v.forEach(child => visit(child, suspended)); visit(node.f, suspended); return; }
      if (node.$ === "Match") { node.e.forEach(child => visit(child, suspended)); node.r.forEach(row => visit(row.f, suspended)); return; }
      if (node.$ === "App") {
        const [head, arguments_] = term_unapply(node);
        if (head.$ === "Var" && head.i === binder) {
          let type = types.typeOf(head), arity = 0;
          while (type.$ === "All") { arity++; type = type.B; }
          if (suspended || arguments_.length !== arity) invalid = true;
          calls++;
          arguments_.forEach(child => visit(child, suspended));
          return;
        }
      }
      if (node.$ === "Var" && node.i === binder) invalid = true;
      termChildren(node).forEach(child => visit(child, suspended || node.$ === "Lam"));
    }
    visit(value);
    return !invalid && calls === 1;
  }
  function sequence(terms: LTerm[], context: Context, positions: boolean[], done: (values: LTerm[], progress: LTerm) => LTerm, goals: (LTerm | undefined)[] = [], erased: boolean[] = [], plainCallbacks: boolean[] = [], afterChild?: (index: number) => void): Writer {
    const effects: EffectExpression[] = [];
    function go(index: number, values: LTerm[], progress: LTerm): LTerm {
      if (index === terms.length) return done(values, progress);
      const child = erased[index] ? { term: pair(terms[index]!, neutral), effect: literal("NoProgress") } : expression(terms[index]!, context, positions[index] ?? false, undefined, goals[index], undefined, plainCallbacks[index]);
      afterChild?.(index);
      effects.push(child.effect);
      return unpack(child.term, (value, effect) => go(index + 1, [...values, value], compose(progress, effect)));
    }
    const term = go(0, [], neutral);
    return { term, effect: joinEffect(...effects) };
  }
  const closures = new Map<string, ExplicitClosureIR>();
  const closureOwners = new WeakMap<LTerm, string>();
  let closureIndex = 0;
  function lambda(term: Extract<LTerm, { $: "Lam" }>, context: Context, expected?: LTerm, plain = false): LTerm {
    const closureOwner = `${context.owner}$closure_${closureIndex++}`;
    closureOwners.set(term, closureOwner);
    if (!operations.has(closureOwner)) operations.set(closureOwner, []);
    const capturedWitnesses = new Map(context.witnesses);
    const shadowOrigins = new Map<WitnessOrigin, WitnessOrigin>();
    function shadow(spec: WitnessSpec): WitnessSpec {
      if (spec.kind === "fields") return { kind: "fields", fields: spec.fields.map(shadow) };
      if (spec.kind !== "origin") return spec;
      let origin = shadowOrigins.get(spec.origin);
      if (!origin) {
        origin = { owner: closureOwner, base: ctr("WitnessNone"), uses: [] };
        origin.base = captureWitness({ kind: "origin", origin: spec.origin, path: [], ancestors: spec.ancestors }, context, term, origin);
        shadowOrigins.set(spec.origin, origin);
      }
      return { kind: "origin", origin, path: spec.path };
    }
    for (const binder of freeBinderIds(term)) capturedWitnesses.set(binder, shadow(capturedWitnesses.get(binder) ?? noWitness));
    const inner: Context = { ...context, owner: closureOwner, path: [], guards: [], tails: new Set(), witnesses: capturedWitnesses, bindings: new Map(context.bindings) };
    const parameters: { binderId: number; type: LTerm }[] = [];
    const parameterOrigins = new Map<number, WitnessOrigin>();
    const inputWitnessBinders: number[] = [];
    function descend(node: LTerm, goal?: LTerm, scope = inner): LTerm {
      if (node.$ === "Lam") {
        if (goal?.$ !== "All") return fail(context, node, "closure parameter has no declared function domain");
        parameters.push({ binderId: node.i, type: goal.A });
        const bindings = new Map(scope.bindings); bindings.set(node.i, goal.A);
        const matchable = new Set(scope.matchable); matchable.add(node.i);
        const witnesses = new Map(scope.witnesses);
        if (!plain && goal.q.$ !== "None" && containsCursor(goal.A)) {
          witnessLibrary();
          const binder = id();
          generatedBinderTypes.set(binder, ref(witnessType));
          inputWitnessBinders.push(binder);
          const origin: WitnessOrigin = { owner: closureOwner, base: variable(binder), uses: [] };
          witnesses.set(node.i, { kind: "origin", origin, path: [] }); parameterOrigins.set(node.i, origin);
        }
        return { ...node, f: descend(node.f, substituteBinder(goal.B, goal.i, { $: "Var", k: node.k, i: node.i }), { ...scope, bindings, matchable, witnesses }) };
      }
      const child = expression(node, scope, goal ? containsCursor(goal) || isNamed(goal, controlType) : true, undefined, goal);
      const previousGoal = continuationGoal;
      if (goal) continuationGoal = plain || isNamed(goal, controlType) ? callbackType(goal) : writerType(goal);
      const result = plain ? unpack(child.term, value => value) : goal && isNamed(goal, controlType) ? unpack(child.term, (value, progress) => apply(ref(prefixName), [progress, value])) : child.term;
      continuationGoal = previousGoal;
      emit(inner, node, { kind: "return", progress: child.effect, result: node, emitted: result });
      return inputWitnessBinders.reduceRight<LTerm>((f, binder) => ({ $: "Lam", q: { $: "Many" }, k: `effect_${-binder}`, i: binder, f }), result);
    }
    const emitted = descend(term, expected);
    if ([...shadowOrigins.values()].some(origin => origin.uses.length || snapshots.some(snapshot => snapshot.context.owner === closureOwner && refs(snapshot.spec).some(reference => reference.origin === origin))) && !context.singleCallClosures?.has(term)) return fail(context, term, "active deferred-witness closure may escape or be invoked repeatedly without one-shot ownership");
    finalizeWitnesses(closureOwner);
    const environment = types.environmentAt(term);
    const captures = freeBinderIds(term).map(binderId => {
      const type = context.bindings?.get(binderId) ?? environment.get(binderId)?.type;
      if (!type) return fail(context, term, `closure capture ${binderId} has no declared type`);
      return { binderId, type };
    });
    let resultType = expected;
    while (resultType?.$ === "All") resultType = resultType.B;
    closures.set(closureOwner, { owner: closureOwner, source: term, emitted, type: expected, resultKind: plain ? "plain" : resultType && isNamed(resultType, controlType) ? "control" : "writer", parameters, activeParameters: parameters.filter(parameter => parameterOrigins.get(parameter.binderId)?.uses.length).map(parameter => parameter.binderId), captures, operations: operations.get(closureOwner)! });
    return emitted;
  }
  function matcher(term: LTerm, context: Context, cursor: boolean, activePosition: boolean, branches: { guards: EffectGuard[]; branchPath: number[]; effect: EffectExpression }[], expected: LTerm, inputType: LTerm, scrutinee: LTerm, excludedConstructors: string[] = [], branch = 0): LTerm {
    if (term.$ === "Efq") return term;
    if (term.$ === "Lam") {
      const bindings = new Map(context.bindings); bindings.set(term.i, inputType);
      const matchable = new Set(context.matchable); matchable.add(term.i);
      const guard: EffectGuard = { scrutinee: term_show(scrutinee), constructor: "*", branch, pattern: term.k, scrutineeTerm: scrutinee, patternTerm: { $: "PVar", k: term.k, i: term.i, q: term.q ?? lone }, excludedConstructors };
      const witnesses = new Map(context.witnesses); witnesses.set(term.i, witnessOf(scrutinee, context));
      const inner = { ...context, path: [...context.path, branch], guards: [...context.guards, guard], bindings, matchable, witnesses };
      const child = expression(term.f, inner, activePosition, undefined, expected);
      branches.push({ guards: inner.guards, branchPath: inner.path, effect: child.effect });
      return { ...term, f: child.term };
    }
    if (term.$ !== "Mat") return fail(context, term, "nonstructural match fallback");
    const tails = new Set(context.tails);
    const binders: Extract<LTerm, { $: "Lam" }>[] = [];
    let leaf = term.h;
    while (leaf.$ === "Lam") { binders.push(leaf); leaf = leaf.f; }
    const pattern: Patt = { $: "PCtr", k: term.k, x: binders.map(binder => ({ $: "PVar", k: binder.k, i: binder.i, q: binder.q ?? lone })) };
    const guards = [...context.guards, { scrutinee: term_show(scrutinee), constructor: term.k, branch, pattern: term_show(patt_term(pattern)), scrutineeTerm: scrutinee, patternTerm: pattern, excludedConstructors }];
    if (cursor && term.k === "Con" && binders.length === 2) tails.add(binders[1]!.i);
    const fields = constructorGoals({ $: "Ctr", k: term.k, x: binders.map(binder => ({ $: "Var", k: binder.k, i: binder.i })) }, inputType);
    const bindings = new Map(context.bindings);
    binders.forEach((binder, index) => bindings.set(binder.i, fields[index]!));
    const matchable = new Set(context.matchable); binders.forEach(binder => matchable.add(binder.i));
    const witnesses = new Map(context.witnesses);
    const branchContext = { ...context, path: [...context.path, branch], guards, tails, bindings, matchable, witnesses };
    bindWitness(pattern, witnessOf(scrutinee, context), branchContext, witnesses, tails, inputType);
    const inner = branchContext;
    const child = expression(leaf, inner, activePosition, undefined, expected);
    branches.push({ guards, branchPath: inner.path, effect: child.effect });
    let handler = child.term;
    for (const binder of [...binders].reverse()) handler = { ...binder, f: handler };
    return { ...term, h: handler, m: matcher(term.m, context, cursor, activePosition, branches, expected, inputType, scrutinee, [...excludedConstructors, term.k], branch + 1) };
  }
  function expression(term: LTerm, context: Context, activePosition = false, captureBefore?: LTerm, expected?: LTerm, captureEffect?: EffectExpression, plainCallback = false): Writer {
    const semanticType = expected ?? typeOf(term, context);
    semanticGoals.set(term, semanticType);
    let valueType = plainCallback ? semanticType : callbackType(semanticType);
    if (term.$ === "Ref") {
      if (selected.has(term.k) && !plainCallback && context.calleeHeads?.has(term)) {
        const signature = graph.signatures.get(term.k)!;
        let result = controlResult(term.k) ? signature.result : writerType(signature.result);
        for (const witness of [...(parameterWitnesses.get(term.k) ?? [])].reverse()) result = { $: "All", q: { $: "Many" }, k: witness.witnessName, i: id(), A: ref(witnessType), B: result };
        valueType = signature.parameters.reduceRight<LTerm>((B, [q, k, i, A]) => ({ $: "All", q, k, i, A: q.$ === "None" ? A : callbackType(A), B }), result);
      } else if (!expected) valueType = semanticType;
    }
    const previousGoal = continuationGoal;
    continuationGoal = apply(ref("Pair"), [valueType, ref(progressType)]);
    try {
      const result = expressionInner(term, context, activePosition, captureBefore, term.$ === "Ref" && !context.calleeHeads?.has(term) ? semanticType : expected, captureEffect, plainCallback);
      writerValues.set(result.term, valueType);
      if (result.term.$ === "Ctr" && result.term.k === "Tuple" && result.term.x.length === 2) generatedTermTypes.set(result.term.x[0]!, valueType);
      return result;
    } finally { continuationGoal = previousGoal; }
  }
  function expressionInner(term: LTerm, context: Context, activePosition = false, captureBefore?: LTerm, expected?: LTerm, captureEffect?: EffectExpression, plainCallback = false): Writer {
    const used = directUse(term, context, activePosition);
    switch (term.$) {
      case "Var": return { term: pair(term, used ?? neutral), effect: used ? used.$ === "Ctr" && used.k === "Consumed" ? literal("Consumed") : { kind: "witness", term: used } : literal("NoProgress") };
      case "Ref": {
        if (parameterWitnesses.get(term.k)?.length && !selected.has(term.k) && !context.calleeHeads?.has(term)) return fail(context, term, "first-class deferred-resumer reference has no one-shot hidden-witness adapter");
        const signature = graph.signatures.get(term.k);
        if (selected.has(term.k) && signature?.parameters.length === 0 && !controlResult(term.k) && !plainCallback) {
          const call = { ...term, k: nameOf(term.k) };
          writerValues.set(call, callbackType(signature.result));
          const effect: EffectExpression = { kind: "call", callee: term.k, sourceOffset: offset(term), variable: id() };
          emit(context, term, { kind: "call", callee: term.k, progress: effect, args: [] });
          return { term: call, effect };
        }
        if (!selected.has(term.k) && !options.primitiveOperations?.has(term.k) && !context.calleeHeads?.has(term) && typeOf(term, context).$ !== "All" && containsCursor(typeOf(term, context)) && !initializationOnly.has(context.owner)) return fail(context, term, `imported cursor producer ${term.k} is driver-reachable and has no initial-input ownership ABI`);
        if (selected.has(term.k) && !plainCallback && context.calleeHeads?.has(term)) return { term: pair({ ...term, k: nameOf(term.k) }, neutral), effect: literal("NoProgress") };
        if (expected?.$ === "All") {
          const primitive = options.primitiveOperations?.get(term.k);
          const parameters: { binder: number; type: Extract<LTerm, { $: "All" }> }[] = [];
          let result: LTerm = expected;
          while (result.$ === "All") {
            if (!primitive && !selected.has(term.k) && result.q.$ !== "None" && containsCursor(result.A)) return fail(context, term, `imported callback ${term.k} has token-cursor access without an explicit effect ABI`);
            parameters.push({ binder: id(), type: result }); result = result.B;
          }
          if (!primitive && !selected.has(term.k) && containsCursor(result) && !context.calleeHeads?.has(term)) return fail(context, term, `first-class imported cursor producer ${term.k} has no initial-input ownership ABI`);
          const actual = selected.has(term.k) ? { ...term, k: nameOf(term.k) } : term;
          const arguments_ = parameters.map(parameter => variable(parameter.binder));
          const declared = graph.signatures.get(term.k)?.parameters.length ?? arguments_.length;
          if ((selected.has(term.k) || primitive) && declared === arguments_.length) {
            let source = apply(term, arguments_);
            for (const parameter of [...parameters].reverse()) source = { $: "Lam", k: `effect_${-parameter.binder}`, i: parameter.binder, q: parameter.type.q, f: source };
            types.indexBody(source, [...(context.bindings ?? [])].map(([binder, type]) => [{ $: "Many" }, `effect_${-binder}`, binder, type, {file:{str:"",ns:'',al:{}},beg:0,end:0}] as ParserParameter), expected);
            return { term: pair(lambda(source as Extract<LTerm, { $: "Lam" }>, context, expected, plainCallback), neutral), effect: literal("NoProgress") };
          }
          const first = apply(actual, arguments_.slice(0, declared));
          if (selected.has(term.k)) writerValues.set(first, callbackType(graph.signatures.get(term.k)!.result));
          const previousGoal = continuationGoal;
          continuationGoal = writerType(result);
          const call = selected.has(term.k) && declared < arguments_.length ? unpack(first, value => apply(value, arguments_.slice(declared))) : first;
          if (selected.has(term.k)) writerValues.set(call, callbackType(result));
          if (plainCallback) continuationGoal = result;
          let wrapped = plainCallback ? selected.has(term.k) ? unpack(call, value => value) : call : isNamed(result, controlType) ? call : pair(call, neutral);
          continuationGoal = previousGoal;
          for (const parameter of parameters.reverse()) wrapped = { $: "Lam", k: `effect_${-parameter.binder}`, i: parameter.binder, q: parameter.type.q, f: wrapped };
          return { term: pair(wrapped, neutral), effect: literal("NoProgress") };
        }
        return { term: pair(term, neutral), effect: literal("NoProgress") };
      }
      case "Ctr": {
        if (term.x.length && tokenList(normalizeType(expected ?? semanticGoals.get(term)!)) && !initializationOnly.has(context.owner)) return fail(context, term, "constructing a nonempty Lexer.Token cursor can recreate an already matched head; unique input-head budget ownership is unsupported");
        const positions = term.x.map(() => activePosition);
        if (activePosition) assertDistinctCursors(term.x, context);
        const goals = constructorGoals(term, expected ?? semanticGoals.get(term)!);
        const result = sequence(term.x, context, positions, (values, progress) => pair({ ...term, x: values }, progress), goals);
        if (term.k === "FeedbackCall") emit(context, term, { kind: "request", progress: result.effect, outcome: term.k });
        return result;
      }
      case "Lam": return { term: pair(lambda(term, context, expected, plainCallback), neutral), effect: literal("NoProgress") };
      case "Ann": return expression(term.x, context, activePosition, captureBefore, term.T, captureEffect, plainCallback);
      case "App": {
        const [rawHead, args] = term_unapply(term);
        let head = rawHead;
        while (head.$ === "Ann") head = head.x;
        if (head.$ === "Mat" || head.$ === "Efq") {
          if (args.length !== 1) return fail(context, term, "structural matcher overapplication");
          const argument = expression(args[0]!, context, false);
          const branches: { guards: EffectGuard[]; branchPath: number[]; effect: EffectExpression }[] = [];
          const argumentIsCursor = args[0]!.$ === "Var" && context.tails.has(args[0]!.i) || tokenList(typeOf(args[0]!, context));
          const matched = matcher(head, context, argumentIsCursor, activePosition, branches, semanticGoals.get(term)!, typeOf(args[0]!, context), args[0]!);
          return { term: unpack(argument.term, (value, progress) => {
            const application = apply(matched, [value]);
            writerValues.set(application, callbackType(semanticGoals.get(term)!));
            matcherApplications.set(application, { input: typeOf(args[0]!, context), result: writerType(semanticGoals.get(term)!) });
            return unpack(application, (result, childProgress) => pair(result, compose(progress, childProgress)));
          }), effect: joinEffect(argument.effect, { kind: "branch", branches }) };
        }
        let signature: ParserSignature | undefined;
        if (head.$ === "Ref") signature = graph.signatures.get(head.k);
        const selectedCall = head.$ === "Ref" && selected.has(head.k);
        const callback = head.$ !== "Ref";
        const primitive = head.$ === "Ref" ? options.primitiveOperations?.get(head.k) : undefined;
        let functionType = typeOf(rawHead, context), arity = 0;
        const domains: LTerm[] = [];
        const erased: boolean[] = [];
        const declaredArity = signature?.parameters.length;
        while (functionType.$ === "All" && (declaredArity === undefined || arity < declaredArity)) {
          domains.push(functionType.A);
          erased.push(functionType.q.$ === "None");
          functionType = args[arity] ? substituteBinder(functionType.B, functionType.i, args[arity]!) : functionType.B;
          arity++;
        }
        if (selectedCall && signature) domains.forEach((domain, index) => {
          if (domain.$ !== "All") return;
          let declared: LTerm = normalizeType(signature.parameters[index]![3]), instantiated: LTerm = domain;
          while (declared.$ === "All") declared = declared.B;
          while (instantiated.$ === "All") instantiated = instantiated.B;
          if (isNamed(instantiated, controlType) !== isNamed(declared, controlType)) return fail(context, term, "dependent callback instantiation changes the writer/Control effect ABI");
        });
        if (args.length > arity) return fail(context, term, "function overapplication");
        const plainCallbacks = args.map(() => false);
        if (!selectedCall && !callback && !primitive) {
          const hasCursor = domains.slice(0, args.length).some((domain, index) => !erased[index] && containsCursor(domain));
          if (hasCursor) return fail(context, term, `imported operation ${head.k} has token-cursor access but no explicit effect ABI`);
          if (containsCursor(functionType) && !initializationOnly.has(context.owner)) return fail(context, term, `imported cursor producer ${head.k} is driver-reachable and has no initial-input ownership ABI`);
          for (let index = 0; index < args.length; index++) if (!erased[index] && domains[index]?.$ === "All") {
            if (!pureCallback(args[index]!, domains[index]!)) return fail(context, term, `imported operation ${head.k} accepts a callback whose token-cursor freedom is not proved`);
            plainCallbacks[index] = true;
          }
        }
        const deferredParameters = selectedCall ? parameterWitnesses.get(head.k) ?? [] : [];
        const activeCallee = selectedCall && (active.has(head.k) || containsCursor(functionType) || isNamed(functionType, controlType));
        const positions = args.map((_, index) => primitive ? (primitive.activeArguments ?? []).includes(index) : !!activeCallee && containsCursor(domains[index]!) && !deferredParameters.some(parameter => parameter.parameterIndex === index));
        if (args.length < arity && args.some((argument, index) => positions[index] && refs(witnessOf(argument, context)).length)) return fail(context, term, "partial active-cursor application requires an unsupported activation-time witness adapter");
        const transferredIndices = callback ? domains.flatMap((domain, index) => !erased[index] && containsCursor(domain) ? [index] : []) : deferredParameters.map(parameter => parameter.parameterIndex);
        assertDistinctCursors(args.filter((_, index) => positions[index] || transferredIndices.includes(index)), context, selectedCall && exclusiveHelpers.has(head.k));
        let effectVariable = 0;
        const witnessArguments = [...(primitive?.captureArguments ?? [])];
        if (deferredParameters.length && args.length !== arity) return fail(context, term, "partial deferred-resumer application cannot preserve hidden-witness ownership");
        witnessArguments.push(...deferredParameters.map(parameter => ({ index: parameter.parameterIndex, witnessName: parameter.witnessName })));
        if (callback) witnessArguments.push(...transferredIndices.filter(index => index < args.length).map(index => ({ index, witnessName: `callback_witness_${index}` })));
        const ghostArgs = witnessArguments.map(capture => {
          const argument = args[capture.index];
          if (!argument) return fail(context, term, "deferred-witness capture slot has no semantic argument");
          const spec = witnessOf(argument, context);
          if (primitive) return captureWitness(spec, context, argument);
          assertHeadOwnership(spec, context, argument);
          const value = witnessValue(spec, context);
          if (args.length < arity && !knownNoWitness(value) && !context.singleCallClosures?.has(term)) return fail(context, term, "partial callback captures live deferred ownership without a proved one-shot activation");
          witnessLibrary();
          return value;
        });
        const singleCallClosures = new Set(context.singleCallClosures);
        if (head.$ === "Lam") singleCallClosures.add(head);
        if (selectedCall) args.forEach((argument, index) => {
          if (argument.$ === "Lam" && signature?.parameters[index]?.[0].$ === "Lone") singleCallClosures.add(argument);
        });
        const calleeHeads = new Set(context.calleeHeads); calleeHeads.add(head);
        const sequencePositions = [false, ...positions];
        const result = sequence([head, ...args], { ...context, singleCallClosures, calleeHeads }, sequencePositions, (values, before) => {
          if (callback && args.length < arity) {
            const remaining: { binder: number; type: LTerm; q: Extract<LTerm, { $: "All" }>["q"] }[] = [];
            let rest = semanticGoals.get(term)!;
            while (rest.$ === "All") {
              const binder = id();
              remaining.push({ binder, type: rest.A, q: rest.q });
              rest = substituteBinder(rest.B, rest.i, variable(binder));
            }
            const remainingGhosts = remaining.filter(parameter => parameter.q.$ !== "None" && containsCursor(parameter.type)).map(() => id());
            let adapted = apply(values[0]!, [...values.slice(1), ...remaining.map(parameter => variable(parameter.binder)), ...ghostArgs, ...remainingGhosts.map(variable)]);
            for (const binder of [...remainingGhosts].reverse()) adapted = { $: "Lam", q: { $: "Many" }, k: `effect_${-binder}`, i: binder, f: adapted };
            for (const parameter of [...remaining].reverse()) adapted = { $: "Lam", q: parameter.q, k: `effect_${-parameter.binder}`, i: parameter.binder, f: adapted };
            return pair(adapted, before);
          }
          const call = apply(values[0]!, [...values.slice(1), ...ghostArgs]);
          writerValues.set(call, callbackType(functionType));
          if (primitive?.captureName && captureBefore) return pair(apply(ref(primitive.captureName), [compose(captureBefore, before), ...values.slice(1), ...ghostArgs]), neutral);
          if ((!selectedCall && !callback) || args.length < arity) return pair(call, before);
          if (selectedCall ? controlResult(head.k) : callback && isNamed(functionType, controlType)) return pair(call, before);
          return unpack(call, (value, child) => { if (child.$ === "Var") effectVariable = child.i; return pair(value, compose(before, child)); });
        }, [rawHead.$ === "Ann" ? rawHead.T : undefined, ...domains], [false, ...erased], [false, ...plainCallbacks], index => {
          if (index > 0 && transferredIndices.includes(index - 1)) retire(witnessOf(args[index - 1]!, context), context, true);
        });
        if ((selectedCall || callback) && args.length === arity) {
          const callee = head.$ === "Ref" ? head.k : head.$ === "Var" ? `$callback:${head.i}` : closureOwners.get(head);
          if (!callee) return fail(context, head, "callable expression has no emitted closure/function effect symbol");
          const effect: EffectExpression = { kind: "call", callee, sourceOffset: offset(term), variable: effectVariable };
          emit(context, term, { kind: "call", callee, progress: effect, args: [...args, ...ghostArgs], emitted: result.term, ...(head.$ === "Var" ? { binderId: head.i } : {}) });
          return { term: result.term, effect: joinEffect(result.effect, effect) };
        }
        if (primitive) emit(context, term, { kind: primitive.kind, callee: head.$ === "Ref" ? head.k : undefined, progress: joinEffect(captureEffect ?? literal("NoProgress"), result.effect), args: [...args, ...ghostArgs], emitted: result.term, ...(primitive.frameArgument === undefined ? {} : { frame: term_show(args[primitive.frameArgument]!) }) });
        return result;
      }
      case "Let": {
        const tails = new Set(context.tails);
        term.v.forEach((value, index) => { if (value.$ === "Var" && tails.has(value.i)) tails.add(term.i[index]!); });
        const witnesses = new Map(context.witnesses); term.v.forEach((value, index) => witnesses.set(term.i[index]!, witnessOf(value, context)));
        const child = expression(term.f, { ...context, tails, witnesses }, activePosition, undefined, expected ?? semanticGoals.get(term));
        const values = sequence(term.v, context, term.v.map(() => false), (values, progress) => ({ ...term, v: values, f: unpack(child.term, (value, childProgress) => pair(value, compose(progress, childProgress))) }));
        return { term: values.term, effect: joinEffect(values.effect, child.effect) };
      }
      case "Sub": {
        const value = patt_term(term.v);
        return expression({ $: "Let", k: [`effect_alias_${term.i}`], i: [term.i], q: [lone], v: [value], f: term.f, s: term.s }, context, activePosition, undefined, expected ?? semanticGoals.get(term));
      }
      case "Mat": return fail(context, term, "unapplied matcher requires an explicit callback domain");
      case "Rwt": return fail(context, term, "dependent rewrite effect transport is unsupported");
      case "Hol": return fail(context, term, "unresolved hole");
      default: return { term: pair(term, neutral), effect: literal("NoProgress") };
    }
  }
  function tailsIn(pattern: Patt, tails: Set<number>, environment: ReadonlyMap<number, { type: LTerm }>) {
    if (pattern.$ !== "PCtr") return;
    const tail = pattern.x[1];
    if (pattern.k === "Con" && pattern.x.length === 2 && tail?.$ === "PVar" && tail.k !== "_") {
      const binding = environment.get(tail.i);
      if (!binding) throw new MissingType("structural list tail has no declared lexical type", pattern, tail.i);
      if (tokenList(binding.type)) tails.add(tail.i);
    }
    for (const child of pattern.x) tailsIn(child, tails, environment);
  }
  function body(node: Body, context: Context, accumulated: LTerm, accumulatedEffect: EffectExpression, control: boolean): Body {
    if (node.$ !== "Local" && node.$ !== "Match") {
      const [head] = term_unapply(node);
      const captures = control && head.$ === "Ref" && !!options.primitiveOperations?.get(head.k)?.captureName;
      const child = expression(node, context, control || containsCursor(graph.signatures.get(context.owner)!.result), captures ? accumulated : undefined, graph.signatures.get(context.owner)!.result, captures ? accumulatedEffect : undefined);
      const effect = joinEffect(accumulatedEffect, child.effect);
      const value = unpack(child.term, (value, progress) => control ? captures ? value : apply(ref(prefixName), [compose(accumulated, progress), value]) : pair(value, compose(accumulated, progress)));
      const terminal = node.$ === "Ctr" ? node.k : undefined;
      emit(context, node, { kind: "return", progress: effect, result: node, emitted: value, ...(terminal ? { outcome: terminal } : {}) });
      return value;
    }
    if (node.$ === "Local") {
      if (node.q.$ === "None") return { ...node, f: body(node.f, context, accumulated, accumulatedEffect, control) };
      let effect = accumulatedEffect, progress = accumulated;
      const children: Writer[] = [], values: PVar[] = [], flags: PVar[] = [];
      for (let index = 0; index < node.v.length; index++) {
        const input = node.v[index]!, pattern = node.k[index]!;
        const singleCallClosures = new Set(context.singleCallClosures);
        if (pattern.$ === "PVar" && calledOnce(node.f, pattern.i)) singleCallClosures.add(input);
        const child = expression(input, { ...context, singleCallClosures }, false), valueId = id(), progressId = id();
        children.push(child);
        values.push({ $: "PVar", k: `effect_${-valueId}`, i: valueId, q: lone });
        flags.push({ $: "PVar", k: `effect_${-progressId}`, i: progressId, q: lone });
        progress = compose(progress, variable(progressId)); effect = joinEffect(effect, child.effect);
      }
      const tails = new Set(context.tails);
      node.v.forEach((value, index) => { const pattern = node.k[index]!; if (value.$ === "Var" && tails.has(value.i) && pattern.$ === "PVar") tails.add(pattern.i); });
      if (node.k.some(pattern => pattern.$ === "PCtr")) {
        let leaf = node.f;
        while (leaf.$ === "Local" && !leaf.v.length) leaf = leaf.f;
        const next = leaf.$ === "Local" ? leaf.v[0] : leaf.$ === "Match" ? leaf.e[0] : leaf;
        if (!next) return fail(context, node, "local constructor pattern has no indexable lexical continuation");
        const environment = types.environmentAt(next);
        for (const pattern of node.k) try { tailsIn(pattern, tails, environment); } catch (error) { if (error instanceof MissingType) return fail(context, pattern, error.message); throw error; }
      }
      const witnesses = new Map(context.witnesses); node.k.forEach((pattern, index) => bindWitness(pattern, witnessOf(node.v[index]!, context), context, witnesses, tails, typeOf(node.v[index]!, context)));
      let rest = body(node.f, { ...context, tails, witnesses }, progress, effect, control);
      for (let index = node.k.length - 1; index >= 0; index--) rest = { ...node, k: [node.k[index]!], v: [variable(values[index]!.i)], f: rest };
      return eliminateBodyWriters(children, values, flags, rest);
    }
    const children: Writer[] = [], values: PVar[] = [], flags: PVar[] = [];
    let progress = accumulated, effect = accumulatedEffect;
    for (const input of node.e) {
      const child = expression(input, context, false), valueId = id(), progressId = id();
      children.push(child);
      values.push({ $: "PVar", k: `effect_${-valueId}`, i: valueId, q: lone });
      flags.push({ $: "PVar", k: `effect_${-progressId}`, i: progressId, q: lone });
      progress = compose(progress, variable(progressId)); effect = joinEffect(effect, child.effect);
    }
    const directMatch = children.every(child => child.term.$ === "Ctr" && child.term.k === "Tuple" && child.term.x[0]?.$ === "Var" && context.matchable?.has(child.term.x[0].i) && child.term.x[1]?.$ === "Ctr" && child.term.x[1].k === "NoProgress");
    if (directMatch) progress = accumulated;
    const rows = node.r.map((row, index) => {
      const tails = new Set(context.tails), guards = [...context.guards];
      const witnesses = new Map(context.witnesses);
      const matchable = new Set(context.matchable);
      const addPattern = (pattern: Patt) => { if (pattern.$ === "PVar") matchable.add(pattern.i); else pattern.x.forEach(addPattern); };
      row.p.forEach(addPattern);
      let leaf = row.f;
      while (leaf.$ === "Local" && !leaf.v.length) leaf = leaf.f;
      const expression = leaf.$ === "Local" ? leaf.v[0] : leaf.$ === "Match" ? leaf.e[0] : leaf;
      if (!expression) return fail(context, node, "branch has no indexable lexical expression");
      const environment = types.environmentAt(expression);
      for (let column = 0; column < row.p.length; column++) {
        const pattern = row.p[column]!;
        try { tailsIn(pattern, tails, environment); } catch (error) { if (error instanceof MissingType) return fail(context, pattern, error.message); throw error; }
        guards.push({ scrutinee: term_show(node.e[column]!), constructor: pattern.$ === "PCtr" ? pattern.k : "*", branch: index, pattern: term_show(patt_term(pattern)), scrutineeTerm: node.e[column], patternTerm: pattern, ...(column === 0 ? { earlierRows: node.r.slice(0, index).map(row => ({ scrutinees: node.e, patterns: row.p })) } : {}) });
        bindWitness(pattern, witnessOf(node.e[column]!, context), { ...context, guards, tails }, witnesses, tails, typeOf(node.e[column]!, context));
      }
      return { ...row, f: body(row.f, { ...context, tails, guards, matchable, witnesses, path: [...context.path, index] }, progress, effect, control) };
    });
    if (directMatch) return { ...node, e: children.map(child => (child.term as Extract<LTerm, { $: "Ctr" }>).x[0]!), r: rows };
    const match: Body = { ...node, e: values.map(value => variable(value.i)), r: rows };
    return eliminateBodyWriters(children, values, flags, match);
  }
  function eliminateBodyWriters(children: Writer[], values: PVar[], flags: PVar[], continuation: Body): LTerm {
    if (!continuationGoal) throw new UnsupportedInstrumentation(emittingOwner, 0, "body continuation has no declared result type");
    const parameters = values.flatMap((value, index) => [value, flags[index]!]);
    let handler = body_flatten(continuation, parameters, id);
    const remainingTypes: LTerm[] = [];
    let type = continuationGoal;
    for (let index = children.length - 1; index >= 0; index--) {
      remainingTypes[index] = type;
      const valueType = writerValues.get(children[index]!.term);
      if (!valueType) throw new UnsupportedInstrumentation(emittingOwner, 0, "body writer has no declared semantic value type");
      type = { $: "All", q: lone, k: values[index]!.k, i: values[index]!.i, A: valueType, B: { $: "All", q: lone, k: flags[index]!.k, i: flags[index]!.i, A: ref(progressType), B: type } };
    }
    for (let index = 0; index < children.length; index++) handler = withEffect(children[index]!.term, writerValues.get(children[index]!.term)!, remainingTypes[index]!, handler);
    return handler;
  }
  // Mat application spines are legal in the checker but not native expression
  // codegen. Keep their match at a declaration head, with the original value
  // passed separately from captures so flattening never reconstructs an alias.
  type LiftBinding = { type: LTerm; quantity: Quant };
  type LiftScope = ReadonlyMap<number, LiftBinding>;
  const matcherFunctions = new Map<string, WitnessRuntimeFunction>();
  let matcherSerial = 0;
  function liftType(term: LTerm, scope: LiftScope): LTerm {
    if (term.$ === "Ann") return term.T;
    if (term.$ === "Var") {
      const binding = scope.get(term.i);
      if (binding) return binding.type;
    }
    const declared = generatedTermTypes.get(term);
    if (declared) return declared;
    const value = writerValues.get(term);
    if (value) return apply(ref("Pair"), [value, ref(progressType)]);
    if (term.$ === "Ref") {
      const support = matcherFunctions.get(term.k) ?? witnessRuntime?.functions.get(term.k);
      if (support) return support.signature.parameters.reduceRight<LTerm>((B, [q, k, i, A]) => ({ $: "All", q, k, i, A, B }), support.signature.result);
      for (const owner of selected) if (nameOf(owner) === term.k) {
        const original = graph.signatures.get(owner)!;
        let result = controlResult(owner) ? original.result : writerType(original.result);
        for (const parameter of [...(parameterWitnesses.get(owner) ?? [])].reverse()) result = { $: "All", q: { $: "Many" }, k: parameter.witnessName, i: id(), A: ref(witnessType), B: result };
        return original.parameters.reduceRight<LTerm>((B, [q, k, i, A]) => ({ $: "All", q, k, i, A: q.$ === "None" ? A : callbackType(A), B }), result);
      }
      const signature = graph.signatures.get(term.k);
      if (signature) return signature.parameters.reduceRight<LTerm>((B, [q, k, i, A]) => ({ $: "All", q, k, i, A, B }), signature.result);
      const declaration = graph.parserBook.tlds[term.k];
      if (declaration) return term_lower(declaration.T, nextTypeBinder([...scope.values()].map(binding => binding.type)));
    }
    if (term.$ === "App") {
      const metadata = matcherApplications.get(term);
      if (metadata) return metadata.result;
      const [head, args] = term_unapply(term);
      if (head.$ === "Ref" && head.k === withEffectName && args.length === 4) return args[1]!;
      let type = liftType(head, scope);
      for (const argument of args) {
        type = normalizeType(type);
        if (type.$ !== "All") throw new UnsupportedInstrumentation(emittingOwner, offset(term), "generated application has no declared function domain");
        type = substituteBinder(type.B, type.i, argument);
      }
      return type;
    }
    if (term.$ === "Ctr" && (term.k === "NoProgress" || term.k === "Consumed")) return ref(progressType);
    if (term.$ === "Ctr" && term.k === "Tuple" && term.x.length === 2) return apply(ref("Pair"), term.x.map(child => liftType(child, scope)));
    if (term.$ === "All" || term.$ === "Typ") return { $: "Typ", g: { $: "Qua", q: lone } };
    if (term.$ === "Qua" || term.$ === "Min") return { $: "Qnt" };
    // Re-index only the expression whose type is demanded. This uses the same
    // constructor telescope inference as source typing, not a cursor relation.
    const lexical = new LexicalTypes(graph.parserBook, graph.signatures);
    const parameters = [...scope].map(([binder, binding]) => [binding.quantity, `capture_${binder}`, binder, binding.type, {file:{str:"",ns:'',al:{}},beg:0,end:0}] as ParserParameter);
    try {
      lexical.indexBody(term, parameters);
      return lexical.typeOf(term);
    } catch (error) {
      if (error instanceof MissingType) throw new UnsupportedInstrumentation(emittingOwner, offset(term), error.message);
      throw error;
    }
  }
  function liftPattern(pattern: Patt, type: LTerm, scope: Map<number, LiftBinding>): void {
    if (pattern.$ === "PVar") { scope.set(pattern.i, { type, quantity: pattern.q }); return; }
    const goals = constructorGoals({ $: "Ctr", k: pattern.k, x: pattern.x.map(field => patt_term(field)) }, type);
    pattern.x.forEach((field, index) => liftPattern(field, goals[index]!, scope));
  }
  function liftMatcher(matcher: Extract<LTerm, { $: "Mat" }>, input: LTerm, result: LTerm, scope: LiftScope, resultBinder?: number, inputQuantity: Quant = lone): LTerm {
    const inputId = id(), inputVar = variable(inputId);
    if (resultBinder !== undefined) result = substituteBinder(result, resultBinder, inputVar);
    let name: string;
    do { name = `feedback_matcher_${++matcherSerial}`; }
    while (graph.parserBook.tlds[name] || [...selected].some(owner => nameOf(owner) === name));
    const rows: Extract<Body, { $: "Match" }>["r"] = [];
    let remainder: LTerm = matcher;
    while (remainder.$ === "Mat") {
      const fields: PVar[] = [];
      let handler = remainder.h;
      const constructor = graph.parserBook.ctrs[remainder.k];
      if (!constructor) throw new UnsupportedInstrumentation(emittingOwner, offset(remainder), "generated matcher constructor has no declaration");
      for (let index = 0; index < constructor.n; index++) {
        if (handler.$ !== "Lam") throw new UnsupportedInstrumentation(emittingOwner, offset(remainder), "generated matcher handler has no explicit field binder");
        fields.push({ $: "PVar", k: handler.k, i: handler.i, q: handler.q ?? lone, s: handler.s });
        handler = handler.f;
      }
      const pattern: Patt = { $: "PCtr", k: remainder.k, x: fields, s: remainder.s };
      const inner = new Map(scope); liftPattern(pattern, input, inner);
      const branchResult = substituteBinder(result, inputId, patt_term(pattern));
      rows.push({ p: [pattern], f: liftTerm(handler, branchResult, inner) });
      remainder = remainder.m;
    }
    if (remainder.$ !== "Efq") {
      if (remainder.$ !== "Lam") throw new UnsupportedInstrumentation(emittingOwner, offset(remainder), "generated matcher fallback has no explicit input binder");
      const fallback: PVar = { $: "PVar", k: remainder.k, i: remainder.i, q: remainder.q ?? lone, s: remainder.s };
      const fallbackScope = new Map(scope); fallbackScope.set(fallback.i, { type: input, quantity: fallback.q });
      const fallbackValue = liftTerm(remainder.f, substituteBinder(result, inputId, patt_term(fallback)), fallbackScope);
      rows.push({ p: [fallback], f: fallbackValue });
    }
    let body: Body = { $: "Match", e: [inputVar], r: rows, s: matcher.s };
    const free = new Set(rows.flatMap(row => freeBinderIds(body_flatten(row.f, row.p.flatMap(pattern => {
      const variables: PVar[] = [];
      const collect = (pattern: Patt) => { if (pattern.$ === "PVar") variables.push(pattern); else pattern.x.forEach(collect); };
      collect(pattern); return variables;
    }), id))));
    freeBinderIds(input).forEach(binder => free.add(binder));
    freeBinderIds(result).forEach(binder => free.add(binder));
    free.delete(inputId);
    const captures: number[] = [];
    const visitCapture = (binder: number) => {
      if (captures.includes(binder)) return;
      const binding = scope.get(binder);
      if (!binding) throw new UnsupportedInstrumentation(emittingOwner, offset(matcher), `generated matcher capture ${binder} has no declared type`);
      // Telescope dependencies must be declared before their dependent capture.
      captures.push(binder);
      for (const dependency of freeBinderIds(binding.type)) if (dependency !== binder) visitCapture(dependency);
      captures.splice(captures.indexOf(binder), 1); captures.push(binder);
    };
    free.forEach(visitCapture);
    const parameters: ParserParameter[] = [], replacements = new Map<number, LTerm>();
    const rename = (term: LTerm) => {
      for (const [binder, value] of replacements) term = substituteBinder(term, binder, value);
      return term;
    };
    const renameBody = (node: Body): Body => node.$ === "Local" ? { ...node, v: node.v.map(rename), f: renameBody(node.f) }
      : node.$ === "Match" ? { ...node, e: node.e.map(rename), r: node.r.map(row => ({ ...row, f: renameBody(row.f) })) }
      : rename(node);
    for (const binder of captures) {
      const binding = scope.get(binder)!, captureId = id();
      parameters.push([binding.quantity, `capture_${-captureId}`, captureId, rename(binding.type), matcher.s ?? {file:{str:"",ns:'',al:{}},beg:0,end:0}]);
      replacements.set(binder, variable(captureId));
    }
    parameters.push([inputQuantity, inputVar.k, inputId, rename(input), matcher.s ?? {file:{str:"",ns:'',al:{}},beg:0,end:0}]);
    body = renameBody(body);
    matcherFunctions.set(name, { signature: { parameters, result: rename(result) }, body });
    return apply(ref(name), captures.map(variable));
  }
  function liftTerm(term: LTerm, goal: LTerm | undefined, scope: LiftScope): LTerm {
    const containsMatcher = (node: LTerm): boolean => node.$ === "Mat" || termChildren(node).some(containsMatcher);
    if (!containsMatcher(term)) return term;
    if (term.$ === "Ann") return { ...term, x: liftTerm(term.x, term.T, scope) };
    if (term.$ === "App") {
      const [rawHead, args] = term_unapply(term);
      let head = rawHead;
      while (head.$ === "Ann") head = head.x;
      if (head.$ === "Mat") {
        if (args.length !== 1) throw new UnsupportedInstrumentation(emittingOwner, offset(term), "generated matcher overapplication");
        const metadata = matcherApplications.get(term);
        const annotated = rawHead.$ === "Ann" ? normalizeType(rawHead.T) : undefined;
        const input = metadata?.input ?? (annotated?.$ === "All" ? annotated.A : liftType(args[0]!, scope));
        const result = metadata?.result ?? goal ?? liftType(term, scope);
        return { ...apply(liftMatcher(head, input, result, scope), [liftTerm(args[0]!, input, scope)]), s: term.s };
      }
      if (head.$ === "Ref" && head.k === withEffectName && args.length === 4) {
        const a = id(), b = id();
        const nextGoal: LTerm = { $: "All", q: lone, k: "semantic", i: a, A: args[0]!, B: { $: "All", q: lone, k: "progress", i: b, A: ref(progressType), B: args[1]! } };
        return { ...apply(head, [args[0]!, args[1]!, liftTerm(args[2]!, apply(ref("Pair"), [args[0]!, ref(progressType)]), scope), liftTerm(args[3]!, nextGoal, scope)]), s: term.s };
      }
      const headGoal = liftType(rawHead, scope);
      let functionGoal = headGoal;
      const arguments_: LTerm[] = [];
      for (const argument of args) {
        functionGoal = normalizeType(functionGoal);
        if (functionGoal.$ !== "All") throw new UnsupportedInstrumentation(emittingOwner, offset(term), "generated call has no declared argument type");
        arguments_.push(functionGoal.q.$ === "None" ? argument : liftTerm(argument, functionGoal.A, scope));
        functionGoal = substituteBinder(functionGoal.B, functionGoal.i, argument);
      }
      return { ...apply(liftTerm(rawHead, headGoal, scope), arguments_), s: term.s };
    }
    if (term.$ === "Lam") {
      const type = goal && normalizeType(goal);
      if (type?.$ !== "All") throw new UnsupportedInstrumentation(emittingOwner, offset(term), "generated lambda has no declared domain");
      const inner = new Map(scope); inner.set(term.i, { type: type.A, quantity: term.q ?? type.q });
      return { ...term, f: liftTerm(term.f, substituteBinder(type.B, type.i, { $: "Var", i: term.i, k: term.k }), inner) };
    }
    if (term.$ === "Mat") {
      const type = goal && normalizeType(goal);
      if (type?.$ !== "All") throw new UnsupportedInstrumentation(emittingOwner, offset(term), "generated matcher closure has no declared domain");
      return liftMatcher(term, type.A, type.B, scope, type.i, type.q);
    }
    if (term.$ === "Ctr" && term.x.length) {
      const goals = constructorGoals(term, goal ?? liftType(term, scope));
      return { ...term, x: term.x.map((field, index) => liftTerm(field, goals[index]!, scope)) };
    }
    if (term.$ === "Let") {
      const inner = new Map(scope);
      const values = term.v.map((value, index) => {
        const type = generatedBinderTypes.get(term.i[index]!) ?? liftType(value, scope);
        inner.set(term.i[index]!, { type, quantity: term.q[index]! });
        return liftTerm(value, type, scope);
      });
      return { ...term, v: values, f: liftTerm(term.f, goal, inner) };
    }
    if (term.$ === "Sub") {
      const value = patt_term(term.v);
      return liftTerm(substituteBinder(term.f, term.i, value), goal, scope);
    }
    return term;
  }
  function liftBody(node: Body, goal: LTerm, scope: LiftScope): Body {
    if (node.$ !== "Local" && node.$ !== "Match") return liftTerm(node, goal, scope);
    if (node.$ === "Local") {
      const inner = new Map(scope);
      const values = node.v.map((value, index) => {
        const type = liftType(value, scope);
        liftPattern(node.k[index]!, type, inner);
        return node.q.$ === "None" ? value : liftTerm(value, type, scope);
      });
      return { ...node, v: values, f: liftBody(node.f, goal, inner) };
    }
    const types = node.e.map(value => liftType(value, scope));
    return { ...node, e: node.e.map((value, index) => liftTerm(value, types[index]!, scope)), r: node.r.map(row => {
      const inner = new Map(scope); row.p.forEach((pattern, index) => liftPattern(pattern, types[index]!, inner));
      return { ...row, f: liftBody(row.f, goal, inner) };
    }) };
  }
  const functions = new Map<string, ExplicitFunctionIR>(), declarationMap = new Map<string, string>();
  for (const owner of selected) {
    const original = graph.signatures.get(owner)!, control = controlResult(owner);
    const signature: ParserSignature = { parameters: original.parameters.map(parameter => [parameter[0], parameter[1], parameter[2], parameter[0].$ === "None" ? parameter[3] : callbackType(parameter[3]), parameter[4]] as ParserParameter), result: control ? original.result : writerType(original.result) };
    const witnesses = new Map<number, WitnessSpec>();
    for (const parameter of original.parameters) if (parameter[0].$ !== "None" && containsCursor(parameter[3])) witnesses.set(parameter[2], { kind: "origin", origin: { owner, base: ctr("WitnessNone"), uses: [] }, path: [] });
    for (const parameter of parameterWitnesses.get(owner) ?? []) {
      witnessLibrary();
      const originalParameter = original.parameters[parameter.parameterIndex];
      if (!originalParameter) throw new UnsupportedInstrumentation(owner, 0, "witness parameter has no corresponding semantic capture");
      const binder = id();
      generatedBinderTypes.set(binder, ref(witnessType));
      signature.parameters.push([{ $: "Many" }, parameter.witnessName, binder, ref(witnessType), {file:{str:"",ns:'',al:{}},beg:0,end:0}] as ParserParameter);
      witnesses.set(originalParameter[2], { kind: "origin", origin: { owner, base: { $: "Var", i: binder, k: parameter.witnessName }, uses: [] }, path: [] });
    }
    emittingOwner = owner;
    continuationGoal = signature.result;
    const bindings = new Map(original.parameters.map(parameter => [parameter[2], parameter[3]] as const));
    for (const parameter of signature.parameters.slice(original.parameters.length)) bindings.set(parameter[2], parameter[3]);
    let transformed = body(graph.bodies.get(owner)!, { owner, path: [], guards: [], tails: new Set(), witnesses, bindings, matchable: new Set(original.parameters.map(parameter => parameter[2])) }, neutral, literal("NoProgress"), control);
    finalizeWitnesses(owner);
    refreshSnapshots(transformed);
    for (const closure of closures.values()) {
      refreshSnapshots(closure.emitted);
      const known = new Map(closure.captures.map(capture => [capture.binderId, capture.type] as const));
      const environment = types.environmentAt(closure.source);
      closure.captures = freeBinderIds(closure.emitted).map(binderId => {
        const type = known.get(binderId) ?? generatedBinderTypes.get(binderId) ?? environment.get(binderId)?.type;
        if (!type) throw new UnsupportedInstrumentation(closure.owner, offset(closure.source), `emitted closure capture ${binderId} has no declared type`);
        return { binderId, type };
      });
    }
    const liftScope = new Map<number, LiftBinding>(signature.parameters.map(([quantity, , binder, type]) => [binder, { type, quantity }]));
    transformed = liftBody(transformed, signature.result, liftScope);
    const rendered = renderBody(transformed, signature.parameters, { book: graph.parserBook });
    const declaration = `def ${nameOf(owner)}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:\n${rendered.body}`;
    declarationMap.set(owner, declaration);
    functions.set(owner, { owner, emittedName: nameOf(owner), body: transformed, signature, operations: operations.get(owner)!, resultKind: control ? "control" : "writer" });
  }
  const supportDeclarations = new Map([[withEffectName, `def ${withEffectName}(-A: Type, -B: Type, value: A & ${progressType}, next: @v: A -> @p: ${progressType} -> B) -> B:\n  match value:\n    case Tuple{semantic, progress}:\n      next(semantic, progress)`]]);
  for (const [name, declaration] of witnessRuntime?.declarations ?? []) supportDeclarations.set(name, declaration);
  const supportFunctions = witnessRuntime?.functions ?? new Map<string, WitnessRuntimeFunction>(), typeDeclarations = witnessRuntime?.typeDeclarations ?? [];
  for (const [name, fn] of matcherFunctions) {
    const rendered = renderBody(fn.body, fn.signature.parameters, { book: graph.parserBook });
    supportDeclarations.set(name, `def ${name}(${rendered.parameters}) -> ${rendered.renderTerm(fn.signature.result)}:\n${rendered.body}`);
    supportFunctions.set(name, fn);
  }
  const visited = new Set<object>();
  function collectConsumption(value: unknown) {
    if (!value || typeof value !== "object" || visited.has(value as object)) return;
    visited.add(value as object);
    const node = value as LTerm;
    const operation = node.s && consumptionBySpan.get(node.s);
    if (operation && node.$) {
      consumptionExpressions.set(node, operation);
      if (node.$ === "Ctr" && node.k === "Consumed") consumptionLiterals.set(node, operation);
    }
    for (const [key, child] of Object.entries(value)) if (key !== "s") { if (Array.isArray(child)) child.forEach(collectConsumption); else collectConsumption(child); }
  }
  for (const fn of functions.values()) collectConsumption(fn.body);
  for (const closure of closures.values()) collectConsumption(closure.emitted);
  for (const fn of supportFunctions.values()) collectConsumption(fn.body);
  const prelude = options.emitPrelude === false || options.emitPrelude === undefined && !!graph.parserBook.tlds[progressType] ? "" : `type ${progressType} is Data:\n  NoProgress{}\n  Consumed{}\n\ndef ${composeName}(a: ${progressType}, b: ${progressType}) -> ${progressType}:\n  match a:\n    case NoProgress{}:\n      b\n    case Consumed{}:\n      Consumed{}\n\n`;
  const declarations = prelude + [...typeDeclarations, ...supportDeclarations.values(), ...declarationMap.values()].join("\n\n") + "\n";
  const headers = [...graph.source.matchAll(/^(?:def|type|law) (\S+?)(?=[(<:\s])/gm)];
  const retained = headers.map((header, index) => {
    const owner = header[1]!;
    return selected.has(owner) && nameOf(owner) === owner ? "" : graph.source.slice(header.index, headers[index + 1]?.index ?? graph.source.length);
  }).join("");
  const source = graph.source.slice(0, headers[0]?.index ?? graph.source.length) + retained + "\n" + declarations;
  return { declarations, source, declarationMap, supportDeclarations, supportFunctions, typeDeclarations, parameterWitnesses, consumptionLiterals, consumptionExpressions, operations, functions, closures, execute: (name, args, runtimeOptions = {}) => executeGenerated(graph, functions, name, args, runtimeOptions, composeName, prefixName, supportFunctions) };
}

/** Small semantic evaluator of the actual generated writer AST. The production
 * path is the rendered Bend declarations above; this seam executes precisely
 * those declarations, not a second progress classifier. */
function executeGenerated(graph: ParserGraph, functions: Map<string, ExplicitFunctionIR>, name: string, args: RuntimeValue[], options: { imports?: Record<string, (...args: RuntimeValue[]) => RuntimeValue>; maxSteps?: number }, composeName: string, prefixName: string, supportFunctions: Map<string, WitnessRuntimeFunction>): { value: RuntimeValue; progress: Progress } {
  type Value = RuntimeValue;
  type Environment = Map<number, Value>;
  let steps = 0;
  const tick = () => { if (++steps > (options.maxSteps ?? 100_000)) throw Error("Explicit progress runtime step limit exceeded"); };
  const isConstructor = (value: Value): value is ConstructorValue => typeof value === "object" && value !== null && "kind" in value && value.kind === "constructor";
  const fn = (invoke: (arg: Value) => Value): Value => ({ kind: "function", invoke });
  function call(value: Value, argument: Value): Value {
    tick();
    if (typeof value === "object" && value !== null && "kind" in value && value.kind === "function") return value.invoke(argument);
    if (typeof value === "function") {
      const result = value(argument as RuntimeValue);
      if (typeof result === "object" && result !== null && "progress" in result && "value" in result) return constructorValue("Tuple", result.value, constructorValue(result.progress));
      return result;
    }
    throw Error("Generated runtime applied a non-function");
  }
  function constructorView(value: Value, constructor: string): Value {
    if (typeof value === "number") {
      if (constructor === "Zero" || constructor === "Succ")
        return value === 0 ? constructorValue("Zero") : constructorValue("Succ", value - 1);
      if (constructor === "U32" || constructor === "F32") {
        const step = lit_step(Lit<[LTerm]>(constructor, constructor === "F32" ? f32_to_bits(value) : value));
        return evaluate(step, new Map());
      }
    }
    if (typeof value === "string" && (constructor === "SNil" || constructor === "SCon")) {
      const code = value.codePointAt(0);
      return code === undefined ? constructorValue("SNil")
        : constructorValue("SCon", constructorValue("Chr", code), value.slice(code > 0xffff ? 2 : 1));
    }
    return value;
  }
  function bind(pattern: Patt, value: Value, environment: Environment): boolean {
    if (pattern.$ === "PVar") { if (pattern.k !== "_") environment.set(pattern.i, value); return true; }
    value = constructorView(value, pattern.k);
    if (!isConstructor(value) || value.name !== pattern.k || value.fields.length !== pattern.x.length) return false;
    return pattern.x.every((child, index) => bind(child, value.fields[index]!, environment));
  }
  function evaluateBody(body: Body, environment: Environment): Value {
    tick();
    if (body.$ !== "Local" && body.$ !== "Match") return evaluate(body, environment);
    if (body.$ === "Local") {
      if (body.q.$ === "None") {
        const inner = new Map(environment);
        const erase = (pattern: Patt) => { if (pattern.$ === "PVar") inner.set(pattern.i, constructorValue("Erased")); else pattern.x.forEach(erase); };
        body.k.forEach(erase);
        return evaluateBody(body.f, inner);
      }
      const values = body.v.map(value => evaluate(value, environment)), inner = new Map(environment);
      for (let i = 0; i < body.k.length; i++) if (!bind(body.k[i]!, values[i]!, inner)) throw Error("Generated local pattern did not match");
      return evaluateBody(body.f, inner);
    }
    const values = body.e.map(value => evaluate(value, environment));
    for (const row of body.r) {
      const inner = new Map(environment);
      if (row.p.every((pattern, i) => bind(pattern, values[i]!, inner))) return evaluateBody(row.f, inner);
    }
    throw Error("Generated runtime match is non-exhaustive");
  }
  function declaration(name: string): Value {
    if (name === composeName) return fn(a => fn(b => constructorValue(isConstructor(a) && a.name === "Consumed" || isConstructor(b) && b.name === "Consumed" ? "Consumed" : "NoProgress")));
    if (name === prefixName) throw Error("Control execution requires the explicit control runtime seam");
    const generated = [...functions.values()].find(item => item.emittedName === name) ?? supportFunctions.get(name);
    if (generated) {
      function curry(index: number, environment: Environment): Value {
        if (index === generated!.signature.parameters.length) return evaluateBody(generated!.body, environment);
        return fn(value => { const inner = new Map(environment); inner.set(generated!.signature.parameters[index]![2], value); return curry(index + 1, inner); });
      }
      return curry(0, new Map());
    }
    const imported = options.imports?.[name];
    if (imported) {
      const signature = graph.signatures.get(name);
      const declaration = graph.parserBook.tlds[name];
      let type = signature?.result ?? (declaration?.$ === "Def" ? term_lower(declaration.T) : undefined), arity = signature?.parameters.length ?? 0;
      if (!signature) while (type?.$ === "All") { arity++; type = type.B; }
      const curry = (values: RuntimeValue[]): Value => values.length === arity ? imported(...values) : fn(value => curry([...values, value as RuntimeValue]));
      return curry([]);
    }
    const original = graph.parserBook.tlds[name];
    if (original?.$ === "Def" && original.v) return evaluate(term_lower(original.v), new Map());
    throw Error(`Generated runtime cannot resolve ${name}`);
  }
  function evaluate(term: LTerm, environment: Environment): Value {
    tick();
    switch (term.$) {
      case "Var": { if (!environment.has(term.i)) throw Error(`Unbound generated runtime binder ${term.i}`); return environment.get(term.i)!; }
      case "Ref": return declaration(term.k);
      case "Lit": return term.k === "F32" ? f32_from_bits(term.v) : term.v;
      case "Ctr": return constructorValue(term.k, ...term.x.map(value => evaluate(value, environment) as RuntimeValue));
      case "Lam": return fn(value => { const inner = new Map(environment); inner.set(term.i, value); return evaluate(term.f, inner); });
      case "App": {
        const [head, args] = term_unapply(term);
        if (head.$ === "Ref" && head.k === "feedback_with_effect" && args.length === 4) {
          const writer = evaluate(args[2]!, environment), continuation = evaluate(args[3]!, environment);
          if (!isConstructor(writer) || writer.name !== "Tuple" || writer.fields.length !== 2) throw Error("Generated elimination expected the writer Tuple ABI");
          return call(call(continuation, writer.fields[0]!), writer.fields[1]!);
        }
        return call(evaluate(term.f, environment), evaluate(term.x, environment));
      }
      case "Mat": return fn(value => {
        const inspected = constructorView(value, term.k);
        if (!isConstructor(inspected)) throw Error("Generated matcher expected a constructor");
        if (inspected.name !== term.k) return call(evaluate(term.m, environment), value);
        let handler = evaluate(term.h, environment);
        for (const field of inspected.fields) handler = call(handler, field);
        return handler;
      });
      case "Let": {
        const values = term.v.map(value => evaluate(value, environment)), inner = new Map(environment);
        term.i.forEach((id, index) => inner.set(id, values[index]!));
        return evaluate(term.f, inner);
      }
      case "Sub": {
        const inner = new Map(environment);
        inner.set(term.i, evaluate(patt_term(term.v), environment));
        return evaluate(term.f, inner);
      }
      case "Ann": return evaluate(term.x, environment);
      case "Qua": return term.q.$;
      case "ADT": case "All": case "Typ": case "Qnt": case "Eql": case "Rfl": return constructorValue("Erased");
      case "Min": return evaluate(term.a, environment);
      default: throw Error(`Unsupported generated runtime term ${term.$}`);
    }
  }
  const info = functions.get(name);
  if (!info) throw Error(`No instrumented operation ${name}`);
  if (info.resultKind === "control") throw Error("Control execution requires the explicit control runtime seam");
  let result = declaration(info.emittedName);
  for (const argument of args) result = call(result, argument);
  if (!isConstructor(result) || result.name !== "Tuple" || result.fields.length !== 2) throw Error("Generated writer ABI did not return Tuple");
  const progress = result.fields[1];
  if (!isConstructor(progress) || (progress.name !== "NoProgress" && progress.name !== "Consumed")) throw Error("Generated writer ABI returned invalid Progress");
  return { value: result.fields[0]!, progress: progress.name };
}
