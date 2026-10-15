/** Binder-ID lexical typing over resolved, low-order source ASTs.
 * Terminal LTerms, Local and Match retain expression identities; scopes never mutate.
 * Term traversal covers every LTerm form, including Lam/All/Let/Sub boundaries
 * and constructor patterns in Sub. No source names participate in type lookup.
 * Types come from signatures/Book declarations, App/Ann goals and structural
 * Local RHS inference. Constructor telescopes instantiate datatype parameters;
 * closed type-level lambda/match applications normalize before projection.
 * Patterns with no named binders need no projection: source validation remains
 * the stage-0 checker's responsibility, not this capture environment's.
 */
import { lit_step, patt_term, term_lower, type Body, type Book, type HTerm, type LTerm, type Patt, type Quant } from "../bend2/bend.ts";
import type { ParserParameter, ParserSignature } from "./parser_full_graph.ts";

export type Binding = Readonly<{ id: number; name: string; type: LTerm; quantity: Quant }>;
export class MissingType extends Error {
  readonly code = "MissingType";
  constructor(readonly reason: string, readonly expression?: LTerm | Patt, readonly binderId?: number) {
    super(`Missing lexical type: ${reason}${binderId === undefined ? "" : ` (binder ${binderId})`}`);
    this.name = "MissingType";
  }
  toJSON() { return { code: this.code, reason: this.reason, binderId: this.binderId, span: this.expression?.s }; }
}

/** A persistent scope. Its public interface cannot mutate an earlier snapshot. */
class Scope implements ReadonlyMap<number, Binding> {
  constructor(private readonly parent?: Scope, private readonly binding?: Binding) {}
  get(id: number): Binding | undefined { return this.binding?.id === id ? this.binding : this.parent?.get(id); }
  has(id: number): boolean { return this.get(id) !== undefined; }
  *entries(): MapIterator<[number, Binding]> {
    const seen = new Set<number>();
    for (let scope: Scope | undefined = this; scope; scope = scope.parent) {
      const binding = scope.binding;
      if (binding && !seen.has(binding.id)) { seen.add(binding.id); yield [binding.id, binding]; }
    }
  }
  *keys(): MapIterator<number> { for (const [id] of this) yield id; }
  *values(): MapIterator<Binding> { for (const [, binding] of this) yield binding; }
  [Symbol.iterator](): MapIterator<[number, Binding]> { return this.entries(); }
  get size(): number { let size = 0; for (const _ of this) size++; return size; }
  forEach(callback: (value: Binding, key: number, map: ReadonlyMap<number, Binding>) => void, thisArg?: unknown) {
    for (const [id, binding] of this) callback.call(thisArg, binding, id, this);
  }
  extend(id: number, name: string, type: LTerm | MissingType, quantity: Quant): Scope {
    if (name === "_") return this;
    const binding: Binding = Object.freeze({
      id, name, quantity,
      get type(): LTerm { if (type instanceof MissingType) throw type; return type; },
    });
    return new Scope(this, binding);
  }
}

function patternChildren(pattern: Patt, visit: (term: LTerm) => void): void {
  if (pattern.$ === "PVar") { if (pattern.k !== "_") visit({ $: "Var", k: pattern.k, i: pattern.i, s: pattern.s }); }
  else for (const child of pattern.x) patternChildren(child, visit);
}

function patternHasBindings(pattern: Patt): boolean {
  if (pattern.$ === "PVar") return pattern.k !== "_";
  for (const child of pattern.x) if (patternHasBindings(child)) return true;
  return false;
}

/** Explicit syntax children, never source-span objects or inferred types. */
export function termChildren(term: LTerm): LTerm[] {
  switch (term.$) {
    case "Var": case "Ref": case "Lit": case "Qnt": case "Qua": case "Efq": case "Rfl": case "Hol": return [];
    case "Typ": return [term.g];
    case "Min": return [term.a, term.b];
    case "All": return [term.A, term.B];
    case "Lam": return [term.f];
    case "Let": return [...term.v, term.f];
    case "Sub": { const children: LTerm[] = []; patternChildren(term.v, value => children.push(value)); children.push(term.f); return children; }
    case "App": return [term.f, term.x];
    case "ADT": case "Ctr": return term.x;
    case "Mat": return [term.h, term.m];
    case "Eql": return [term.a, term.b, term.T];
    case "Rwt": return [term.e, term.p, term.f];
    case "Ann": return [term.x, term.T];
    default: return unreachable(term);
  }
}
function unreachable(term: never): never { throw Error(`Unsupported lexical AST node: ${(term as LTerm).$}`); }

export function freeBinderIds(term: LTerm): number[] {
  const free = new Set<number>();
  function visit(node: LTerm, bound: ReadonlySet<number>) {
    if (node.$ === "Var") { if (!bound.has(node.i)) free.add(node.i); return; }
    if (node.$ === "Lam") { visit(node.f, new Set([...bound, node.i])); return; }
    if (node.$ === "All") { visit(node.A, bound); visit(node.B, new Set([...bound, node.i])); return; }
    if (node.$ === "Let") { for (const value of node.v) visit(value, bound); visit(node.f, new Set([...bound, ...node.i])); return; }
    if (node.$ === "Sub") {
      patternChildren(node.v, value => visit(value, bound));
      visit(node.f, new Set([...bound, node.i])); return;
    }
    for (const child of termChildren(node)) visit(child, bound);
  }
  visit(term, new Set());
  return [...free];
}

/** Capture-avoiding substitution uses IDs, including anonymous binder IDs. */
function substitute(term: LTerm, id: number, value: LTerm): LTerm {
  if (term.$ === "Var") return term.i === id ? value : term;
  switch (term.$) {
    case "Lam": return term.i === id ? term : { ...term, f: substitute(term.f, id, value) };
    case "All": return { ...term, A: substitute(term.A, id, value), B: term.i === id ? term.B : substitute(term.B, id, value) };
    case "Let": return { ...term, v: term.v.map(x => substitute(x, id, value)), f: term.i.includes(id) ? term.f : substitute(term.f, id, value) };
    case "Sub": return substitute(substitute(term.f, term.i, patt_term(term.v)), id, value);
    default: {
      const children = termChildren(term);
      if (!children.length) return term;
      const copy = { ...term } as unknown as Record<string, unknown>;
      for (const [key, child] of Object.entries(term)) {
        if (key === "s") continue;
        if (Array.isArray(child)) copy[key] = child.map(x => x && typeof x === "object" && "$" in x ? substitute(x as LTerm, id, value) : x);
        else if (child && typeof child === "object" && "$" in child && children.includes(child as LTerm)) copy[key] = substitute(child as LTerm, id, value);
      }
      return copy as LTerm;
    }
  }
}


export class LexicalTypes {
  private readonly environments = new WeakMap<LTerm, Scope>();
  private nextId = 0;
  constructor(readonly book: Book, readonly signatures: ReadonlyMap<string, ParserSignature>) {}
  indexBody(body: Body, parameters: readonly ParserParameter[], result?: LTerm): void {
    const reserve = (term: LTerm) => {
      const visit = (node: LTerm) => {
        if ("i" in node) for (const id of Array.isArray(node.i) ? node.i : [node.i]) this.nextId = Math.max(this.nextId, id + 1);
        for (const child of termChildren(node)) visit(child);
      };
      visit(term);
    };
    const reservePattern = (pattern: Patt) => {
      if (pattern.$ === "PVar") this.nextId = Math.max(this.nextId, pattern.i + 1);
      else for (const child of pattern.x) reservePattern(child);
    };
    const reserveBody = (node: Body) => {
      if (node.$ === "Local") { for (const pattern of node.k) reservePattern(pattern); for (const value of node.v) reserve(value); reserveBody(node.f); }
      else if (node.$ === "Match") { for (const value of node.e) reserve(value); for (const row of node.r) { for (const pattern of row.p) reservePattern(pattern); reserveBody(row.f); } }
      else reserve(node);
    };
    for (const [, , id, type] of parameters) { this.nextId = Math.max(this.nextId, id + 1); reserve(type); }
    if (result) reserve(result);
    reserveBody(body);
    let scope = new Scope();
    for (const [quantity, name, id, type] of parameters) scope = scope.extend(id, name, type, quantity);
    this.visitBody(body, scope, result);
  }
  environmentAt(expression: LTerm): ReadonlyMap<number, Binding> {
    const scope = this.environments.get(expression);
    if (!scope) throw Error("Expression has not been indexed in its lexical body");
    return scope;
  }
  /** Infer an indexed expression in its actual lexical scope, including aliases. */
  typeOf(expression: LTerm): LTerm {
    const scope = this.environments.get(expression);
    if (!scope) throw Error("Expression has not been indexed in its lexical body");
    return this.normalize(this.infer(expression, scope));
  }
  captures(lambda: LTerm): Binding[] {
    if (lambda.$ !== "Lam") throw Error("Capture analysis requires a lambda");
    const scope = this.environmentAt(lambda);
    return freeBinderIds(lambda).map(id => {
      const binding = scope.get(id);
      if (!binding) throw new MissingType("free variable is not bound in this scope", lambda, id);
      void binding.type; // Deferred unknown domains fail only when actually captured.
      return binding;
    });
  }
  private visitBody(body: Body, scope: Scope, result?: LTerm): void {
    switch (body.$) {
      case "Local": {
        let inner = scope;
        for (let i = 0; i < body.v.length; i++) {
          const value = body.v[i]!, pattern = body.k[i]!;
          this.visitExpression(value, scope);
          inner = this.bindPattern(pattern, this.infer(value, scope), inner, body.q.$ === "None" ? body.q : undefined);
        }
        this.visitBody(body.f, inner, result); return;
      }
      case "Match": {
        const types = body.e.map(value => { this.visitExpression(value, scope); return this.infer(value, scope); });
        for (const row of body.r) {
          let inner = scope;
          for (let i = 0; i < row.p.length; i++) inner = this.bindPattern(row.p[i]!, types[i]!, inner);
          this.visitBody(row.f, inner, result);
        }
        return;
      }
      default: this.visitExpression(body, scope, result); return;
    }
  }
  private constructorFields(constructor: string, expected: LTerm): LTerm {
    const type = this.normalize(expected), declaration = this.book.ctrs[constructor];
    if (!declaration) throw new MissingType("constructor has no declaration");
    if (type.$ !== "ADT") throw new MissingType(`constructor ${constructor} requires a known datatype instance`, expected);
    const datatype = this.book.tlds[type.k];
    if (datatype?.$ !== "ADT" || !datatype.c.some(ctr => ctr.k === constructor)) throw new MissingType("constructor does not belong to scrutinee datatype", expected);
    let telescope = this.lowerFresh(declaration.T);
    for (const argument of type.x) {
      const head = this.normalize(telescope);
      if (head.$ !== "All") throw new MissingType("constructor datatype parameter arity mismatch", expected);
      telescope = substitute(head.B, head.i, argument);
    }
    return telescope;
  }
  private bindPattern(pattern: Patt, type: LTerm, scope: Scope, erased?: Quant): Scope {
    if (!patternHasBindings(pattern)) return scope;
    if (pattern.$ === "PVar") return scope.extend(pattern.i, pattern.k, this.normalize(type), erased ?? pattern.q);
    let telescope = this.constructorFields(pattern.k, type), inner = scope;
    for (const child of pattern.x) {
      const head = this.normalize(telescope);
      if (head.$ !== "All") throw new MissingType("constructor pattern field arity mismatch", pattern);
      inner = this.bindPattern(child, head.A, inner, erased);
      telescope = substitute(head.B, head.i, patt_term(child));
    }
    if (this.normalize(telescope).$ === "All") throw new MissingType("constructor pattern has too few fields", pattern);
    return inner;
  }
  private visitExpression(term: LTerm, scope: Scope, expected?: LTerm): void {
    this.environments.set(term, scope);
    switch (term.$) {
      case "Ann": this.visitExpression(term.T, scope); this.visitExpression(term.x, scope, term.T); return;
      case "Lam": {
        const goal = expected && this.normalize(expected);
        const type = goal?.$ === "All" ? goal.A : new MissingType("lambda parameter has no declared domain", term, term.i);
        const inner = scope.extend(term.i, term.k, type, term.q ?? (goal?.$ === "All" ? goal.q : { $: "Lone" }));
        this.visitExpression(term.f, inner, goal?.$ === "All" ? substitute(goal.B, goal.i, { $: "Var", k: term.k, i: term.i }) : undefined);
        return;
      }
      case "All":
        this.visitExpression(term.A, scope);
        this.visitExpression(term.B, scope.extend(term.i, term.k, term.A, term.q)); return;
      case "App": {
        this.visitExpression(term.f, scope);
        let goal: LTerm | undefined;
        try { const type = this.normalize(this.infer(term.f, scope)); if (type.$ === "All") goal = type.A; }
        catch (error) { if (!(error instanceof MissingType)) throw error; }
        this.visitExpression(term.x, scope, goal); return;
      }
      case "Let": {
        let inner = scope;
        for (let i = 0; i < term.v.length; i++) {
          this.visitExpression(term.v[i]!, scope);
          inner = inner.extend(term.i[i]!, term.k[i]!, this.infer(term.v[i]!, scope), term.q[i]!);
        }
        this.visitExpression(term.f, inner, expected); return;
      }
      case "Sub": {
        const value = patt_term(term.v);
        this.visitExpression(value, scope, scope.get(term.i)?.type);
        let type: LTerm | MissingType;
        try { type = this.infer(value, scope); }
        catch (error) { if (!(error instanceof MissingType)) throw error; type = error; }
        this.visitExpression(term.f, scope.extend(term.i, "", type, scope.get(term.i)?.quantity ?? { $: "Lone" }), expected); return;
      }
      case "Mat": {
        const goal = expected && this.normalize(expected);
        if (goal?.$ !== "All") {
          this.visitExpression(term.h, scope);
          this.visitExpression(term.m, scope);
          return;
        }
        const fields: LTerm[] = [];
        const handlerGoal = (telescope: LTerm): LTerm => {
          const field = this.normalize(telescope);
          if (field.$ !== "All") return substitute(goal.B, goal.i, { $: "Ctr", k: term.k, x: fields });
          fields.push({ $: "Var", k: field.k, i: field.i });
          return { ...field, B: handlerGoal(field.B) };
        };
        this.visitExpression(term.h, scope, handlerGoal(this.constructorFields(term.k, goal.A)));
        this.visitExpression(term.m, scope, goal);
        return;
      }
      case "Ctr": {
        if (expected) {
          let telescope = this.constructorFields(term.k, expected);
          for (const value of term.x) {
            const head = this.normalize(telescope);
            if (head.$ !== "All") throw new MissingType("constructor value field arity mismatch", term);
            this.visitExpression(value, scope, head.A);
            telescope = substitute(head.B, head.i, value);
          }
        } else for (const child of term.x) this.visitExpression(child, scope);
        return;
      }
      default: for (const child of termChildren(term)) this.visitExpression(child, scope); return;
    }
  }
  private lowerFresh(type: HTerm): LTerm {
    const result = term_lower(type, this.nextId);
    const reserve = (term: LTerm) => {
      if ("i" in term) for (const id of Array.isArray(term.i) ? term.i : [term.i]) this.nextId = Math.max(this.nextId, id + 1);
      for (const child of termChildren(term)) reserve(child);
    };
    reserve(result);
    return result;
  }
  private normalize(type: LTerm, unfolding = new Set<string>()): LTerm {
    switch (type.$) {
      case "Ann": return this.normalize(type.x, unfolding);
      case "Sub": return this.normalize(substitute(type.f, type.i, patt_term(type.v)), unfolding);
      case "Ref": {
        const definition = this.book.tlds[type.k];
        if (definition?.$ === "Def" && definition.v && !unfolding.has(type.k)) return this.normalize(this.lowerFresh(definition.v), new Set([...unfolding, type.k]));
        if (definition?.$ === "ADT" && definition.n === 0) return { $: "ADT", k: type.k, x: [], r: [] };
        return type;
      }
      case "App": {
        const fn = this.normalize(type.f, unfolding);
        if (fn.$ === "Lam") return this.normalize(substitute(fn.f, fn.i, type.x), unfolding);
        if (fn.$ === "Mat") {
          const normalized = this.normalize(type.x, unfolding);
          const argument = normalized.$ === "Lit" ? lit_step(normalized) : normalized;
          if (argument.$ === "Ctr") {
            if (argument.k !== fn.k) return this.normalize({ $: "App", f: fn.m, x: argument }, unfolding);
            let branch = fn.h;
            for (const field of argument.x) branch = { $: "App", f: branch, x: field };
            return this.normalize(branch, unfolding);
          }
        }
        return { ...type, f: fn };
      }
      default: return type;
    }
  }
  private inferConstructor(term: Extract<LTerm, { $: "Ctr" }>, scope: Scope, expected?: LTerm): LTerm {
    const constructor = this.book.ctrs[term.k];
    const declaration = Object.entries(this.book.tlds).find(([, tld]) => tld.$ === "ADT" && tld.c.some(ctr => ctr.k === term.k));
    const datatype = declaration?.[1];
    if (!constructor || datatype?.$ !== "ADT") throw new MissingType("constructor has no datatype declaration", term);
    let telescope = this.lowerFresh(constructor.T);
    const parameters = new Map<number, Extract<LTerm, { $: "All" }>>();
    const solutions = new Map<number, LTerm>();
    for (let i = 0; i < datatype.n; i++) {
      if (telescope.$ !== "All") throw new MissingType("constructor parameter telescope is incomplete", term);
      parameters.set(telescope.i, telescope);
      telescope = telescope.B;
    }
    const resolved = (type: LTerm): LTerm => {
      for (const [id, value] of solutions) type = substitute(type, id, value);
      return this.normalize(type);
    };
    if (expected) {
      const goal = this.normalize(expected);
      if (goal.$ === "ADT" && goal.k === declaration![0] && goal.x.length === datatype.n) {
        [...parameters.keys()].forEach((id, index) => solutions.set(id, goal.x[index]!));
      }
    }
    const unify = (template: LTerm, actual: LTerm, kindFit = false): void => {
      const left = resolved(template), right = resolved(actual);
      if (left.$ === "Lit" && right.$ === "Ctr") return unify(lit_step(left), right, kindFit);
      if (right.$ === "Lit" && left.$ === "Ctr") return unify(left, lit_step(right), kindFit);
      if (left.$ === "Var" && parameters.has(left.i)) {
        if (freeBinderIds(right).includes(left.i)) throw new MissingType("recursive constructor type argument", term);
        solutions.set(left.i, right); return;
      }
      // A function-valued datatype argument can be inferred from its payload
      // application by abstracting a constant codomain. It never inspects names.
      if (left.$ === "App" && left.f.$ === "Var" && parameters.has(left.f.i)) {
        const domain = resolved(parameters.get(left.f.i)!.A);
        if (domain.$ !== "All") throw new MissingType("payload type argument has no function domain", term);
        solutions.set(left.f.i, { $: "Lam", k: domain.k, i: domain.i, f: right, q: domain.q }); return;
      }
      if (left.$ !== right.$) throw new MissingType("constructor payload types do not determine compatible arguments", term);
      switch (left.$) {
        case "Var": if (right.$ !== "Var" || left.i !== right.i) throw new MissingType("constructor payload type variable mismatch", term); return;
        case "Ref": if (right.$ !== "Ref" || left.k !== right.k) throw new MissingType("constructor payload type reference mismatch", term); return;
        case "ADT": {
          if (right.$ !== "ADT" || left.k !== right.k || left.x.length !== right.x.length) throw new MissingType("constructor payload datatype mismatch", term);
          for (let i = 0; i < left.x.length; i++) unify(left.x[i]!, right.x[i]!, kindFit);
          return;
        }
        case "All": {
          if (right.$ !== "All" || left.q.$ !== right.q.$) throw new MissingType("constructor payload function quantity mismatch", term);
          unify(left.A, right.A, kindFit);
          unify(left.B, substitute(right.B, right.i, { $: "Var", k: left.k, i: left.i }), kindFit); return;
        }
        case "Qua": if (right.$ !== "Qua" || (left.q.$ !== right.q.$ && !(kindFit && (right.q.$ === "Many" || left.q.$ !== "Many")))) throw new MissingType("constructor payload kind mismatch", term); return;
        case "Lit": if (right.$ !== "Lit" || left.k !== right.k || left.v !== right.v) throw new MissingType("constructor payload literal mismatch", term); return;
        default: {
          const a = termChildren(left), b = termChildren(right);
          if (a.length !== b.length) throw new MissingType("constructor payload type shape mismatch", term);
          for (let i = 0; i < a.length; i++) unify(a[i]!, b[i]!, kindFit);
        }
      }
    };
    for (const value of term.x) {
      const head = resolved(telescope);
      if (head.$ !== "All") throw new MissingType("constructor value field arity mismatch", term);
      unify(head.A, this.infer(value, scope, head.A));
      telescope = substitute(head.B, head.i, value);
    }
    // Inferred type parameters also determine their kind/quantity parameters.
    for (let pass = 0; pass < parameters.size; pass++) {
      const before = solutions.size;
      for (const [id, parameter] of parameters) {
        const value = solutions.get(id);
        if (!value) continue;
        const domain = resolved(parameter.A);
        let kind: LTerm;
        if (value.$ === "Lam" && domain.$ === "All") {
          const inner = scope.extend(value.i, value.k, domain.A, domain.q);
          kind = { ...domain, i: value.i, k: value.k, B: this.infer(value.f, inner) };
        } else kind = this.infer(value, scope);
        unify(domain, kind, true);
      }
      if (before === solutions.size) break;
    }
    const result = resolved(telescope);
    if (result.$ === "All") throw new MissingType("constructor value has too few fields", term);
    if (freeBinderIds(result).some(id => parameters.has(id) && !solutions.has(id))) throw new MissingType("constructor has undetermined datatype arguments; annotate its RHS", term);
    return result;
  }
  private infer(term: LTerm, scope: Scope, expected?: LTerm): LTerm {
    switch (term.$) {
      case "Var": {
        const binding = scope.get(term.i);
        if (!binding) throw new MissingType("variable is not bound", term, term.i);
        return binding.type;
      }
      case "Ref": {
        const signature = this.signatures.get(term.k);
        if (signature) return signature.parameters.reduceRight<LTerm>((B, [q, k, i, A]) => ({ $: "All", q, k, i, A, B }), signature.result);
        const definition = this.book.tlds[term.k];
        if (!definition) throw new MissingType("reference has no declaration", term);
        return this.lowerFresh(definition.T);
      }
      case "Ann": return term.T;
      case "Lit": return { $: "ADT", k: term.k, x: [], r: [], s: term.s };
      case "Ctr": return this.inferConstructor(term, scope, expected);
      case "App": {
        if (term.f.$ === "Lam") return this.infer(substitute(term.f.f, term.f.i, term.x), scope);
        const fn = this.normalize(this.infer(term.f, scope));
        if (fn.$ !== "All") throw new MissingType("application has no function type", term);
        return this.normalize(substitute(fn.B, fn.i, term.x));
      }
      case "Typ": case "All": return { $: "Typ", g: { $: "Qua", q: { $: "Lone" } } };
      case "Qnt": return { $: "Typ", g: { $: "Qua", q: { $: "Lone" } } };
      case "Qua": case "Min": return { $: "Qnt" };
      case "Eql": return { $: "Typ", g: { $: "Qua", q: { $: "Many" } } };
      case "ADT": {
        const declaration = this.book.tlds[term.k];
        if (declaration?.$ !== "ADT") throw new MissingType("datatype has no declaration", term);
        let type = this.lowerFresh(declaration.T);
        for (const value of term.x) {
          const head = this.normalize(type);
          if (head.$ !== "All") throw new MissingType("datatype parameter arity mismatch", term);
          type = substitute(head.B, head.i, value);
        }
        return this.normalize(type);
      }
      case "Sub": return this.infer(substitute(term.f, term.i, patt_term(term.v)), scope);
      case "Let": {
        let inner = scope;
        for (let i = 0; i < term.v.length; i++) inner = inner.extend(term.i[i]!, term.k[i]!, this.infer(term.v[i]!, scope), term.q[i]!);
        return this.infer(term.f, inner);
      }
      case "Rwt": return this.infer(term.f, scope);
      case "Lam": case "Mat": case "Efq": case "Rfl": case "Hol":
        throw new MissingType("term requires an expected type or annotation", term);
      default: return unreachable(term);
    }
  }
}
