/** Source-Body instantiation for higher-order consumers. Formal substitutions
 * are simultaneous: a callback's free IDs belong to its caller, even when they
 * coincide with a consumer formal. Every bound ID is freshly allocated before
 * beta reduction, so captured Kont fields cannot become pattern/lambda locals.
 * This operates on syntax only; Ref callees remain available to Control lowering.
 */
import { patt_term, type Body, type LTerm, type Patt, type Quant } from "../bend2/bend.ts";
import type { ParserParameter, ParserSignature } from "./parser_full_graph.ts";
import { termChildren } from "./parser_full_type_env.ts";

export type QuantityOrigin = Readonly<{
  reason: "source-explicit" | "synthesized-reuse";
  sourceBinderId?: number;
  sourceBinderName?: string;
  sourceSpan?: LTerm["s"];
  boundary?: "pattern" | "callback";
}>;
type Variable = Extract<LTerm, { $: "Var" }>;
export type SpecializedConsumer = {
  body: Body;
  parameters: ParserParameter[];
  result: LTerm;
  bindings: ReadonlyMap<number, string>;
  quantityOrigins: ReadonlyMap<number, QuantityOrigin>;
};

type Uses = Map<number, number>;
function combine(target: Uses, source: Uses, maximum = false, scale = 1): Uses {
  for (const [id, count] of source) {
    target.set(id, maximum ? Math.max(target.get(id) ?? 0, count) : (target.get(id) ?? 0) + count * scale);
  }
  return target;
}
function patternIds(pattern: Patt): number[] {
  return pattern.$ === "PVar" ? [pattern.i] : pattern.x.flatMap(patternIds);
}
/** Counts runtime uses on one path, excluding erased type annotations and
 * locally bound IDs. Alternative Match/Mat branches share the same resources.
 */
export function runtimeUses(node: Body | LTerm): Uses {
  switch (node.$) {
    case "Var": return new Map([[node.i, 1]]);
    case "Typ": case "All": case "ADT": case "Eql": return new Map();
    case "Ann": return runtimeUses(node.x);
    case "Rwt": return runtimeUses(node.f);
    case "Lam": { const uses = runtimeUses(node.f); uses.delete(node.i); return uses; }
    case "Let": {
      const uses = runtimeUses(node.f);
      node.i.forEach(id => uses.delete(id));
      node.v.forEach((value, index) => { if (node.q[index]!.$ !== "None") combine(uses, runtimeUses(value)); });
      return uses;
    }
    case "Sub": {
      const uses = runtimeUses(node.f), count = uses.get(node.i) ?? 0;
      uses.delete(node.i);
      const value = node.v.$ === "PVar" || node.v.$ === "PCtr" ? patt_term(node.v) : node.v;
      return combine(uses, runtimeUses(value), false, count);
    }
    case "Mat": return combine(runtimeUses(node.h), runtimeUses(node.m), true);
    case "Reply": return runtimeUses(node.x);
    case "Local": {
      const uses = runtimeUses(node.f);
      node.k.flatMap(patternIds).forEach(id => uses.delete(id));
      if (node.q.$ !== "None") node.v.forEach(value => combine(uses, runtimeUses(value)));
      return uses;
    }
    case "Match": {
      const branches: Uses = new Map();
      for (const row of node.r) {
        const uses = runtimeUses(row.f);
        row.p.flatMap(patternIds).forEach(id => uses.delete(id));
        combine(branches, uses, true);
      }
      node.e.forEach(value => combine(branches, runtimeUses(value)));
      return branches;
    }
    default: {
      const uses: Uses = new Map();
      termChildren(node).forEach(child => combine(uses, runtimeUses(child)));
      return uses;
    }
  }
}
function quantityForUses(quantity: Quant, id: number, uses: ReadonlyMap<number, number>): Quant {
  return quantity.$ !== "None" && (uses.get(id) ?? 0) > 1 ? { $: "Many" } : quantity;
}
function promotePattern(pattern: Patt, uses: ReadonlyMap<number, number>): Patt {
  return pattern.$ === "PVar" ? { ...pattern, q: quantityForUses(pattern.q, pattern.i, uses) }
    : { ...pattern, x: pattern.x.map(child => promotePattern(child, uses)) };
}

class Instantiation {
  constructor(private readonly preserveQuantities = false) {}
  private nextId = 0;
  readonly quantityOrigins = new Map<number, QuantityOrigin>();
  private readonly lambdaOrigins = new Map<number, QuantityOrigin>();
  reserveId(id: number): void { this.nextId = Math.max(this.nextId, id + 1); }
  reserve(term: LTerm): void {
    if ("i" in term) {
      if (Array.isArray(term.i)) term.i.forEach(id => this.reserveId(id));
      else this.reserveId(term.i);
    }
    termChildren(term).forEach(child => this.reserve(child));
  }
  reservePattern(pattern: Patt): void {
    if (pattern.$ === "PVar") this.reserveId(pattern.i);
    else pattern.x.forEach(child => this.reservePattern(child));
  }
  reserveBody(body: Body): void {
    switch (body.$) {
      case "Reply": this.reserve(body.x); break;
      case "Local":
        body.k.forEach(pattern => this.reservePattern(pattern));
        body.v.forEach(value => this.reserve(value));
        this.reserveBody(body.f); break;
      case "Match":
        body.e.forEach(value => this.reserve(value));
        for (const row of body.r) {
          row.p.forEach(pattern => this.reservePattern(pattern));
          this.reserveBody(row.f);
        }
    }
  }
  bind(id: number, name: string, environment: Map<number, LTerm>): number {
    const fresh = this.nextId++;
    environment.set(id, { $: "Var", i: fresh, k: name });
    return fresh;
  }
  private pattern(pattern: Patt, environment: Map<number, LTerm>): Patt {
    if (pattern.$ === "PVar") {
      const i = this.bind(pattern.i, pattern.k, environment);
      if (pattern.q.$ === "Many") this.quantityOrigins.set(i, {
        reason:"source-explicit", sourceBinderId:pattern.i, sourceBinderName:pattern.k,
        sourceSpan:pattern.s, boundary:"pattern",
      });
      return { ...pattern, i };
    }
    return { ...pattern, x: pattern.x.map(child => this.pattern(child, environment)) };
  }
  term(term: LTerm, environment: ReadonlyMap<number, LTerm>): LTerm {
    const child = (value: LTerm) => this.term(value, environment);
    switch (term.$) {
      case "Var": {
        const replacement = environment.get(term.i);
        // Never substitute caller IDs using the consumer's substitution map.
        return replacement ? this.term(replacement, new Map()) : term;
      }
      case "Ref": case "Qnt": case "Qua": case "Efq": case "Rfl": case "Hol": return term;
      case "Typ": return { ...term, g: child(term.g) };
      case "Min": return { ...term, a: child(term.a), b: child(term.b) };
      case "Lam": {
        const local = new Map(environment), i = this.bind(term.i, term.k, local);
        const f = this.term(term.f, local);
        const q: Quant | undefined = this.preserveQuantities || term.q?.$ === "None" || (runtimeUses(f).get(i) ?? 0) <= 1 ? term.q : { $: "Many" };
        if (q?.$ === "Many") this.lambdaOrigins.set(i, this.lambdaOrigins.get(term.i) ?? {
          reason:term.q?.$ === "Many" ? "source-explicit" : "synthesized-reuse",
          sourceBinderId:term.i, sourceBinderName:term.k, sourceSpan:term.s, boundary:"callback",
        });
        return { ...term, i, f, ...(q ? { q } : {}) };
      }
      case "All": {
        const local = new Map(environment), i = this.bind(term.i, term.k, local);
        return { ...term, i, A: child(term.A), B: this.term(term.B, local) };
      }
      case "Let": {
        const local = new Map(environment);
        const i = term.i.map((id, index) => this.bind(id, term.k[index]!, local));
        const f = this.term(term.f, local), uses = runtimeUses(f);
        return { ...term, i, v: term.v.map(child), f,
          q: this.preserveQuantities ? term.q : term.q.map((quantity, index) => quantityForUses(quantity, i[index]!, uses)) };
      }
      case "Sub": {
        const local = new Map(environment), i = this.bind(term.i, "_", local);
        const value = term.v.$ === "PVar" || term.v.$ === "PCtr" ? patt_term(term.v) : term.v;
        return { ...term, i, v: child(value), f: this.term(term.f, local) };
      }
      case "App": {
        const f = child(term.f), x = child(term.x);
        if (f.$ === "Lam") {
          const origin = this.lambdaOrigins.get(f.i);
          if (origin && x.$ === "Var") {
            const previous = this.quantityOrigins.get(x.i);
            if (previous?.reason !== "source-explicit") this.quantityOrigins.set(x.i, origin);
          }
          return this.term(f.f, new Map([[f.i, x]]));
        }
        return { ...term, f, x };
      }
      case "ADT": case "Ctr": return { ...term, x: term.x.map(child) };
      case "Mat": return { ...term, h: child(term.h), m: child(term.m) };
      case "Eql": return { ...term, a: child(term.a), b: child(term.b), T: child(term.T) };
      case "Rwt": return { ...term, e: child(term.e), p: child(term.p), f: child(term.f) };
      case "Ann": return { ...term, x: child(term.x), T: child(term.T) };
    }
  }
  body(body: Body, environment: ReadonlyMap<number, LTerm>): Body {
    switch (body.$) {
      case "Reply": return { ...body, x: this.term(body.x, environment) };
      case "Local": {
        const local = new Map(environment), k = body.k.map(pattern => this.pattern(pattern, local));
        const f = this.body(body.f, local), uses = runtimeUses(f);
        return { ...body, k: this.preserveQuantities ? k : k.map(pattern => promotePattern(pattern, uses)),
          v: body.v.map(value => this.term(value, environment)), f };
      }
      case "Match": return { ...body, e: body.e.map(value => this.term(value, environment)),
        r: body.r.map(row => {
          const local = new Map(environment), p = row.p.map(pattern => this.pattern(pattern, local));
          const f = this.body(row.f, local), uses = runtimeUses(f);
          return { ...row, p: this.preserveQuantities ? p : p.map(pattern => promotePattern(pattern, uses)), f };
        }) };
    }
  }
}

/** Capture-avoiding simultaneous substitution and literal-lambda beta reduction.
 * Free IDs survive unchanged; all local binders receive fresh, disjoint IDs.
 */
export function substituteTerm(term: LTerm, substitutions: ReadonlyMap<number, LTerm>): LTerm {
  const instance = new Instantiation();
  instance.reserve(term);
  for (const [id, value] of substitutions) { instance.reserveId(id); instance.reserve(value); }
  return instance.term(term, substitutions);
}
export function betaReduceTerm(term: LTerm): LTerm { return substituteTerm(term, new Map()); }

/** Simultaneous Body substitution for semantics-preserving source rewrites.
 * Unlike consumer specialization it never widens affine source quantities.
 * Reserve the caller's IDs as well as the substitutions to avoid capturing an
 * otherwise-unused caller local when inserting fresh helper binders.
 */
export function substituteBody(body: Body, substitutions: ReadonlyMap<number, LTerm>,
  reservedIds: Iterable<number> = []): Body {
  const instance = new Instantiation(true);
  instance.reserveBody(body);
  for (const id of reservedIds) instance.reserveId(id);
  for (const [id, value] of substitutions) { instance.reserveId(id); instance.reserve(value); }
  return instance.body(body, substitutions);
}

/** The optional capture telescope supplies the already-typed Kont fields, not
 * function-valued fields. Returned parameters exclude the substituted callbacks
 * and rebind ordinary formals to their replacement field/result-placeholder IDs.
 * A Body renderer must seed lexical printing with these parameter IDs.
 */
export function specializeConsumer(body: Body, signature: ParserSignature,
  callbacks: ReadonlyMap<number, LTerm>, arguments_: ReadonlyMap<number, Variable>,
  captureParameters: readonly ParserParameter[] = []): SpecializedConsumer {
  const instance = new Instantiation();
  instance.reserveBody(body);
  instance.reserve(signature.result);
  for (const parameter of [...signature.parameters, ...captureParameters]) {
    instance.reserveId(parameter[2]); instance.reserve(parameter[3]);
  }
  const substitutions = new Map<number, LTerm>([...arguments_, ...callbacks]);
  for (const [id, value] of substitutions) { instance.reserveId(id); instance.reserve(value); }
  const parameterArguments = new Map(arguments_);
  for (const [, name, id] of signature.parameters) {
    if (!callbacks.has(id) && !parameterArguments.has(id)) {
      const fresh = instance.bind(id, name, substitutions);
      parameterArguments.set(id, { $: "Var", i: fresh, k: name });
    }
  }
  const parameters: ParserParameter[] = [];
  const bindings = new Map<number, string>();
  for (const [quantity, name, id, type, span] of signature.parameters) {
    if (callbacks.has(id)) continue;
    const argument = parameterArguments.get(id)!;
    const bindingId = argument.i, bindingName = argument.k;
    if (!bindings.has(bindingId)) {
      parameters.push([quantity, bindingName, bindingId, instance.term(type, substitutions), span]);
      bindings.set(bindingId, bindingName);
    }
  }
  for (const parameter of captureParameters) {
    if (!bindings.has(parameter[2])) {
      parameters.push(parameter);
      bindings.set(parameter[2], parameter[1]);
    }
  }
  const specialized = instance.body(body, substitutions), uses = runtimeUses(specialized);
  function collect(body:Body):void {
    function pattern(value:Patt):void {
      if(value.$==="PCtr"){value.x.forEach(pattern);return;}
      if(value.q.$==="Many"&&!instance.quantityOrigins.has(value.i))
        instance.quantityOrigins.set(value.i,{reason:"synthesized-reuse",boundary:"pattern"});
    }
    if(body.$==="Match")for(const row of body.r){row.p.forEach(pattern);collect(row.f);}
    else if(body.$==="Local"){body.k.forEach(pattern);collect(body.f);}
  }
  collect(specialized);
  return { body: specialized,
    parameters: parameters.map(([quantity, name, id, type, span]) =>
      [quantityForUses(quantity, id, uses), name, id, type, span]),
    result: instance.term(signature.result, substitutions), bindings, quantityOrigins:instance.quantityOrigins };
}
