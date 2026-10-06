/** Exact constructor restitution before cursor-effect instrumentation.
 * Proofs are branch-local structural equalities, never source names or spans.
 * Small acyclic helpers are instantiated only at saturated tail-call sites.
 * Unsupported unshareable origins, opaque expressions, embedded helper calls and
 * escaped cursor origins stay unchanged for the instrumentation's rejection.
 */
import { patt_term, quant_join, term_lower, term_unapply, type Body, type LTerm, type Patt, type Quant } from "../bend2/bend.ts";
import type { ParserGraph, ParserParameter, ParserSignature } from "./parser_full_graph.ts";
import { betaReduceTerm, runtimeUses, substituteBody, substituteTerm } from "./parser_full_consumer.ts";
import { freeBinderIds, LexicalTypes, MissingType, termChildren } from "./parser_full_type_env.ts";

type Fact = { pattern: LTerm; origin: LTerm; source: LTerm; dependencies: Set<number>; cursor: boolean; escaped?: true };
type Input = { value: LTerm; type: LTerm; quantity: Quant };
type Row = { patterns: Patt[]; body: Body };
const originalCursor = Symbol("structurally matched original");
type OriginPattern = Extract<Patt, { $: "PCtr" }> & { [originalCursor]?: number };
const many: Quant = { $: "Many" };
const lone: Quant = { $: "Lone" };
const variable = (i: number, k = `restitution_${i}`): LTerm => ({ $: "Var", i, k });
const application = (f: LTerm, x: LTerm): LTerm => ({ $: "App", f, x });
function patternIds(pattern: Patt): number[] {
  return pattern.$ === "PVar" ? [pattern.i] : pattern.x.flatMap(patternIds);
}
function exact(a: LTerm, b: LTerm): boolean {
  if (a.$ === "Ann") return exact(a.x, b);
  if (b.$ === "Ann") return exact(a, b.x);
  if (a.$ === "Var" && b.$ === "Var") return a.i === b.i;
  return a.$ === "Ctr" && b.$ === "Ctr" && a.k === b.k && a.x.length === b.x.length && a.x.every((field, i) => exact(field, b.x[i]!));
}
function visitBody(body: Body, term: (value: LTerm) => void, pattern: (value: Patt) => void = () => {}): void {
  if (body.$ === "Reply") term(body.x);
  else if (body.$ === "Local") { body.k.forEach(pattern); body.v.forEach(term); visitBody(body.f, term, pattern); }
  else { body.e.forEach(term); for (const row of body.r) { row.p.forEach(pattern); visitBody(row.f, term, pattern); } }
}

/** No mutation of graph maps or source ASTs; erased quantities remain erased. */
export function optimizeCursorRestitution(graph: ParserGraph, tokenElement: string): {
  bodies: Map<string, Body>; signatures: Map<string, ParserSignature>; changed: Set<string>;
} {
  const bodies = new Map(graph.bodies), signatures = new Map(graph.signatures), changed = new Set<string>();
  let next = 0;
  function reserve(term: LTerm): void {
    if ("i" in term) for (const id of Array.isArray(term.i) ? term.i : [term.i]) next = Math.max(next, id + 1);
    termChildren(term).forEach(reserve);
  }
  for (const body of graph.bodies.values()) visitBody(body, reserve, pattern => patternIds(pattern).forEach(id => { next = Math.max(next, id + 1); }));
  for (const signature of graph.signatures.values()) {
    signature.parameters.forEach(([, , id, type]) => { next = Math.max(next, id + 1); reserve(type); }); reserve(signature.result);
  }
  const fresh = () => next++;
  function substitution(body: Body, values: ReadonlyMap<number, LTerm>): Body {
    const result = substituteBody(body, values, [next]);
    visitBody(result, reserve, pattern => patternIds(pattern).forEach(id => { next = Math.max(next, id + 1); }));
    return result;
  }
  const types = new LexicalTypes(graph.parserBook, graph.signatures);
  function normalize(type: LTerm, seen = new Set<string>()): LTerm {
    if (type.$ === "Ann") return normalize(type.x, seen);
    if (type.$ === "Sub") return normalize(substituteTerm(type.f, new Map([[type.i,
      type.v.$ === "PVar" || type.v.$ === "PCtr" ? patt_term(type.v) : type.v]])), seen);
    if (type.$ === "Ref") {
      const declaration = graph.parserBook.tlds[type.k];
      if (declaration?.$ === "ADT" && declaration.n === 0) return { $: "ADT", k: type.k, x: [], r: [] };
      if (declaration?.$ === "Def" && declaration.v && !seen.has(type.k)) return normalize(term_lower(declaration.v, fresh()), new Set([...seen, type.k]));
    }
    if (type.$ === "App") {
      const fn = normalize(type.f, seen);
      if (fn.$ === "Lam") return normalize(substituteTerm(fn.f, new Map([[fn.i, type.x]])), seen);
      if (fn.$ === "Mat") {
        const argument = normalize(type.x, seen);
        if (argument.$ === "Ctr") {
          if (argument.k !== fn.k) return normalize(application(fn.m, argument), seen);
          let branch = fn.h;
          for (const field of argument.x) branch = application(branch, field);
          return normalize(branch, seen);
        }
      }
      return { ...type, f: fn };
    }
    return type;
  }
  function tokenList(type: LTerm): boolean {
    const normalized = normalize(type);
    if (normalized.$ !== "ADT" || normalized.k !== "List") return false;
    const element = normalized.x[1] && normalize(normalized.x[1]);
    return !!element && (element.$ === "ADT" || element.$ === "Ref") && element.k === tokenElement;
  }
  function containsCursor(type: LTerm): boolean {
    const normalized = normalize(type);
    return tokenList(normalized) || termChildren(normalized).some(containsCursor);
  }
  function shareable(type: LTerm): boolean {
    const expected = normalize(type);
    if (expected.$ !== "ADT") return false;
    const declaration = graph.parserBook.tlds[expected.k];
    if (declaration?.$ !== "ADT") return false;
    let telescope = term_lower(declaration.T, fresh()); reserve(telescope);
    for (const argument of expected.x) {
      const head = normalize(telescope);
      if (head.$ !== "All") return false;
      telescope = substituteTerm(head.B, new Map([[head.i, argument]])); reserve(telescope);
    }
    const kind = normalize(telescope);
    if (kind.$ !== "Typ") return false;
    function dataGrade(grade: LTerm): boolean {
      const value = normalize(grade);
      if (value.$ === "Qua") return value.q.$ === "Many";
      return value.$ === "Min" && dataGrade(value.a) && dataGrade(value.b);
    }
    return dataGrade(kind.g);
  }
  function fields(constructor: string, type: LTerm, values: readonly LTerm[]): { type: LTerm; quantity: Quant }[] {
    const expected = normalize(type), declaration = graph.parserBook.ctrs[constructor];
    if (!declaration || expected.$ !== "ADT") throw new MissingType("restitution projection needs a declared datatype", type);
    const datatype = graph.parserBook.tlds[expected.k];
    if (datatype?.$ !== "ADT" || !datatype.c.some(ctr => ctr.k === constructor)) throw new MissingType("restitution constructor does not belong to matched datatype", type);
    let telescope = term_lower(declaration.T, fresh()); reserve(telescope);
    for (const argument of expected.x) {
      const head = normalize(telescope);
      if (head.$ !== "All") throw new MissingType("restitution datatype parameter arity mismatch", type);
      telescope = substituteTerm(head.B, new Map([[head.i, argument]])); reserve(telescope);
    }
    const result: { type: LTerm; quantity: Quant }[] = [];
    for (const value of values) {
      const head = normalize(telescope);
      if (head.$ !== "All") throw new MissingType("restitution constructor field arity mismatch", type);
      result.push({ type: normalize(head.A), quantity: head.q });
      telescope = substituteTerm(head.B, new Map([[head.i, value]])); reserve(telescope);
    }
    if (normalize(telescope).$ === "All") throw new MissingType("restitution constructor has unmatched fields", type);
    return result;
  }
  function annotatedMatcher(k: string, handler: LTerm, fallback: LTerm, input: Input, result: LTerm): LTerm {
    return { $: "Ann", x: { $: "Mat", k, h: handler, m: fallback },
      T: { $: "All", q: input.quantity, k: "restitution_input", i: fresh(), A: input.type, B: result } };
  }

  // Only helpers with real cursor construction need exposure. A cyclic helper
  // is never eligible, even if the particular call site appears nonrecursive.
  const recursive = new Set<string>();
  function reaches(start: string, current: string, seen: Set<string>): boolean {
    for (const target of graph.edges[current] ?? []) {
      if (target === start) return true;
      if (!seen.has(target)) { seen.add(target); if (reaches(start, target, seen)) return true; }
    }
    return false;
  }
  for (const name of graph.bodies.keys()) if (reaches(name, name, new Set([name]))) recursive.add(name);
  const helpers = new Set<string>();
  const smallHelpers = new Set<string>();
  const listDeclaration = graph.parserBook.tlds.List;
  const nonemptyListConstructors = new Set(listDeclaration?.$ === "ADT"
    ? listDeclaration.c.filter(constructor => constructor.n > 0).map(constructor => constructor.k) : []);
  for (const [name, body] of graph.bodies) {
    if (recursive.has(name)) continue;
    const signature = graph.signatures.get(name)!;
    if (!containsCursor(signature.result)) continue;
    let size = 0;
    const candidates: LTerm[] = [];
    function literal(node: LTerm): boolean {
      return node.$ === "Ctr" && node.x.every(literal);
    }
    const scan = (node: LTerm) => {
      size++;
      if (literal(node)) return; // Encoded string/number literals are one source expression.
      if (node.$ === "Ctr" && nonemptyListConstructors.has(node.k)) candidates.push(node);
      termChildren(node).forEach(scan);
    };
    visitBody(body, scan, pattern => { size += patternIds(pattern).length; });
    if (size > 1024) continue;
    smallHelpers.add(name);
    if (!candidates.length) continue;
    try {
      types.indexBody(body, signature.parameters, signature.result);
      if (candidates.some(node => tokenList(types.typeOf(node)))) helpers.add(name);
    } catch (error) { if (!(error instanceof MissingType)) throw error; }
  }
  let discovered = true;
  while (discovered) {
    discovered = false;
    for (const name of smallHelpers) {
      if (!helpers.has(name) && (graph.edges[name] ?? []).some(target => helpers.has(target))) {
        helpers.add(name);
        discovered = true;
      }
    }
  }
  function expand(body: Body, stack: ReadonlySet<string>): Body {
    if (body.$ === "Reply") {
      const [head, arguments_] = term_unapply(body.x);
      if (head.$ !== "Ref" || !helpers.has(head.k) || stack.has(head.k)) return body;
      const signature = graph.signatures.get(head.k)!;
      // Nontrivial arguments require call-by-value bindings and additional
      // quantity proofs; leave those sites to the strict downstream guard.
      if (arguments_.length !== signature.parameters.length || arguments_.some(arg => arg.$ !== "Var")) return body;
      const instance = substitution(graph.bodies.get(head.k)!, new Map(signature.parameters.map((parameter, i) => [parameter[2], arguments_[i]!])));
      return expand(instance, new Set([...stack, head.k]));
    }
    if (body.$ === "Local") return { ...body, f: expand(body.f, stack) };
    return { ...body, r: body.r.map(row => ({ ...row, f: expand(row.f, stack) })) };
  }

  // Lower changed source matches directly to typed Mat expressions. Stage-0's
  // Body compiler substitutes a matched original binder with its constructor;
  // doing that here would silently allocate the cursor we just restituted.
  let compileParameters = new Map<number, ParserParameter>();
  function compile(body: Body, result: LTerm): LTerm {
    types.indexBody(body, [...compileParameters.values()], result);
    if (body.$ === "Reply") return body.x;
    if (body.$ === "Local") {
      if (body.k.every(pattern => pattern.$ === "PVar")) {
        const patterns = body.k as Extract<Patt, { $: "PVar" }>[];
        patterns.forEach((pattern, i) => compileParameters.set(pattern.i,
          [quant_join(body.q, pattern.q), pattern.k, pattern.i, types.typeOf(body.v[i]!), pattern.s ?? { beg: 0, end: 0 }]));
        return { $: "Let", k: patterns.map(pattern => pattern.k), i: patterns.map(pattern => pattern.i),
          q: patterns.map(pattern => quant_join(body.q, pattern.q)), v: body.v, f: compile(body.f, result) };
      }
      return matrix(body.v.map(value => ({ value, type: types.typeOf(value), quantity: lone })), [{ patterns: body.k, body: body.f }], result);
    }
    return matrix(body.e.map(value => ({ value, type: types.typeOf(value), quantity: value.$ === "Var" ? types.environmentAt(value).get(value.i)?.quantity ?? lone : lone })),
      body.r.map(row => ({ patterns: row.p, body: row.f })), result);
  }
  function matrix(inputs: Input[], rows: Row[], result: LTerm): LTerm {
    if (!inputs.length) {
      if (!rows.length) throw new MissingType("empty restitution match matrix");
      return compile(rows[0]!.body, result);
    }
    const input = inputs[0]!, constructor = rows.find(row => row.patterns[0]?.$ === "PCtr")?.patterns[0] as Extract<Patt, { $: "PCtr" }> | undefined;
    if (!constructor) {
      if (!rows.length) return application({ $: "Ann", x: { $: "Efq" }, T: { $: "All", q: input.quantity, k: "restitution_absurd", i: fresh(), A: input.type, B: result } }, input.value);
      return matrix(inputs.slice(1), rows.map(row => {
        const pattern = row.patterns[0]!;
        if (pattern.$ !== "PVar") throw Error("Nonvariable restitution matrix column");
        return { patterns: row.patterns.slice(1), body: substitution(row.body, new Map([[pattern.i, input.value]])) };
      }), result);
    }
    const quantity = rows.reduce((q, row) => row.patterns[0]?.$ === "PVar" ? quant_join(q, row.patterns[0].q) : q, input.quantity);
    const ids = constructor.x.map(() => fresh()), values = ids.map(id => variable(id));
    const goals = fields(constructor.k, input.type, values);
    const childInputs = values.map((value, i): Input => ({ value, type: goals[i]!.type,
      quantity: quant_join(quantity, constructor.x[i]!.$ === "PVar" ? (constructor.x[i] as Extract<Patt, { $: "PVar" }>).q : lone) }));
    ids.forEach((id, i) => compileParameters.set(id,
      [childInputs[i]!.quantity, `restitution_${id}`, id, goals[i]!.type, { beg: 0, end: 0 }]));
    const selected: Row[] = [];
    for (const row of rows) {
      const pattern = row.patterns[0]!;
      if (pattern.$ === "PCtr") {
        if (pattern.k === constructor.k) {
          const origin = (pattern as OriginPattern)[originalCursor];
          selected.push({ patterns: [...pattern.x, ...row.patterns.slice(1)],
            body: origin === undefined ? row.body : substitution(row.body, new Map([[origin, input.value]])) });
        }
      } else selected.push({ patterns: [...ids.map((id, i): Patt => ({ $: "PVar", i: id, k: `restitution_${id}`, q: childInputs[i]!.quantity })), ...row.patterns.slice(1)],
        body: substitution(row.body, new Map([[pattern.i, input.value]])) });
    }
    let handler = matrix([...childInputs, ...inputs.slice(1)], selected, result);
    for (let i = ids.length - 1; i >= 0; i--) handler = { $: "Lam", i: ids[i]!, k: `restitution_${ids[i]}`, q: childInputs[i]!.quantity, f: handler };
    const fallbackId = fresh(), fallbackValue = variable(fallbackId);
    const datatype = normalize(input.type);
    if (datatype.$ !== "ADT") throw new MissingType("restitution fallback needs a datatype", input.type);
    const fallbackType: LTerm = { ...datatype, r: [...datatype.r, constructor.k] };
    compileParameters.set(fallbackId, [quantity, `restitution_${fallbackId}`, fallbackId, fallbackType, { beg: 0, end: 0 }]);
    const fallbackBody = matrix([{ ...input, type: fallbackType, value: fallbackValue }, ...inputs.slice(1)],
      rows.filter(row => row.patterns[0]!.$ === "PVar" || (row.patterns[0] as Extract<Patt, { $: "PCtr" }>).k !== constructor.k), result);
    // A structural fallback inherits the checker's constructor exclusions.
    // Reannotating it with the unrestricted datatype would lose that proof;
    // restriction types themselves are not stage-0 source syntax.
    const fallback: LTerm = fallbackBody.$ === "App" && exact(fallbackBody.x, fallbackValue)
      && fallbackBody.f.$ === "Ann" && (fallbackBody.f.x.$ === "Mat" || fallbackBody.f.x.$ === "Efq")
      ? fallbackBody.f.x
      : { $: "Lam", i: fallbackId, k: `restitution_${fallbackId}`, q: quantity, f: fallbackBody };
    return application(annotatedMatcher(constructor.k, handler, fallback, { ...input, quantity }, result), input.value);
  }

  for (const [name, original] of graph.bodies) {
    const signature = graph.signatures.get(name)!;
    if (!containsCursor(signature.result) && !signature.parameters.some(parameter => containsCursor(parameter[3]))) continue;
    let cancellations = 0;
    try {
      const expanded = expand(original, new Set([name]));
      types.indexBody(expanded, signature.parameters, signature.result);
      function factsFor(pattern: Patt, input: Input, facts: Fact[], dependencies: Set<number>): Patt {
        if (pattern.$ === "PVar" || !patternIds(pattern).length) return pattern;
        const datatype = normalize(input.type);
        const element = (datatype.$ === "ADT" || datatype.$ === "Ref") && datatype.k === tokenElement;
        if (!element && !containsCursor(datatype)) return pattern;
        const ownDependencies = new Set([...dependencies, ...patternIds(pattern)]);
        const origin = fresh();
        if (shareable(input.type)) facts.push({ pattern: patt_term(pattern), origin: variable(origin), source: input.value,
          dependencies: ownDependencies, cursor: tokenList(input.type) });
        const goals = fields(pattern.k, input.type, pattern.x.map(child => patt_term(child)));
        return { ...pattern, [originalCursor]: origin, x: pattern.x.map((child, i) =>
          factsFor(child, { value: patt_term(child), type: goals[i]!.type, quantity: input.quantity }, facts, ownDependencies)) } as OriginPattern;
      }
      function rewrite(term: LTerm, facts: Fact[]): LTerm {
        function original(value: LTerm, seen = new Set<Fact>()): LTerm {
          if (value.$ === "Var") {
            const fact = facts.find(fact => fact.pattern.$ === "Ctr" && exact(value, fact.origin));
            if (fact && !seen.has(fact)) return original(fact.source, new Set([...seen, fact]));
          }
          return value.$ === "Ctr" ? { ...value, x: value.x.map(child => original(child, seen)) } : value;
        }
        function replacement(value: LTerm): LTerm | undefined {
          if (value.$ !== "Ctr" && value.$ !== "Var") return;
          for (let i = facts.length - 1; i >= 0; i--) {
            const fact = facts[i]!;
            if (exact(value, fact.pattern)) { if (fact.cursor) cancellations++; return fact.origin; }
          }
        }
        const direct = replacement(term);
        if (direct) return direct;
        // Runtime constructor fields and ordinary applications are the only
        // expression contexts normalized here. Suspended lambdas, dependent
        // transports and term-local matches retain their original guards.
        if (term.$ === "Ctr") {
          const value = { ...term, x: term.x.map(child => rewrite(child, facts)) };
          // Token restitution may expose the head binder of a list pattern.
          for (const fact of facts) {
            if (!fact.cursor) continue;
            const canonical = canonicalPattern(fact.pattern, fact);
            if (exact(original(value), original(canonical))) { cancellations++; return fact.origin; }
          }
          return replacement(value) ?? value;
        }
        if (term.$ === "Ann") return { ...term, x: rewrite(term.x, facts) };
        if (term.$ === "App") {
          const [head, arguments_] = term_unapply(term);
          let result = head;
          for (const argument of arguments_) result = application(result, rewrite(argument, facts));
          // A cursor passed to an opaque or ordinary call is escaped. Facts
          // are invalid for following expressions, not for its own arguments.
          const escaped = new Set<number>();
          arguments_.forEach(argument => {
            let cursor = false;
            try { cursor = containsCursor(types.typeOf(argument)); } catch (error) { if (!(error instanceof MissingType)) throw error; cursor = true; }
            if (cursor) freeBinderIds(argument).forEach(id => escaped.add(id));
          });
          const blocked = new Set(escaped);
          for (let i = facts.length - 1; i >= 0; i--) {
            if ([...facts[i]!.dependencies].some(id => escaped.has(id))) {
              facts[i]!.dependencies.forEach(id => blocked.add(id));
              facts.splice(i, 1);
            }
          }
          if (blocked.size) {
            const marker: LTerm = { $: "Hol", k: "escaped_restitution_origin" };
            facts.push({ pattern: marker, origin: marker, source: marker, dependencies: blocked, cursor: false, escaped: true });
          }
          return result;
        }
        return term;
        function canonicalPattern(value: LTerm, excluded: Fact): LTerm {
          if (value.$ !== "Ctr") return value;
          const children = { ...value, x: value.x.map(child => canonicalPattern(child, excluded)) };
          for (let i = facts.length - 1; i >= 0; i--) if (facts[i] !== excluded && exact(children, facts[i]!.pattern)) return facts[i]!.origin;
          return children;
        }
      }
      function normalizeBody(body: Body, inherited: readonly Fact[]): Body {
        const facts = [...inherited];
        if (body.$ === "Reply") return { ...body, x: rewrite(body.x, facts) };
        if (body.$ === "Local") {
          const v = body.v.map(value => rewrite(value, facts));
          if (body.q.$ !== "None") body.k.forEach((pattern, i) => {
            const value = v[i]!;
            if (pattern.$ === "PVar" && value.$ === "Var") {
              facts.push({ pattern: patt_term(pattern), origin: value, source: value,
                dependencies: new Set([pattern.i, value.i]), cursor: false });
            }
          });
          return { ...body, v, f: normalizeBody(body.f, facts) };
        }
        const e = body.e.map(value => rewrite(value, facts));
        return { ...body, e, r: body.r.map(row => {
          const branch = [...facts];
          const p = row.p.map((pattern, i) => {
            const source = body.e[i]!;
            if (source.$ !== "Var") return pattern;
            if (facts.some(fact => fact.escaped && fact.dependencies.has(source.i))) return pattern;
            return factsFor(pattern, { value: e[i]!, type: types.typeOf(source), quantity: lone }, branch, new Set(freeBinderIds(source)));
          });
          return { ...row, p, f: normalizeBody(row.f, branch) };
        }) };
      }
      const normalized = normalizeBody(expanded, []);
      if (!cancellations) continue;
      compileParameters = new Map(signature.parameters.map(parameter => [parameter[2], parameter]));
      const term = betaReduceTerm(compile(normalized, signature.result));
      const uses = runtimeUses(term);
      const parameters = signature.parameters.map(([q, k, i, type, span]): ParserParameter => {
        if (q.$ !== "Lone" || (uses.get(i) ?? 0) <= 1) return [q, k, i, type, span];
        if (!shareable(type)) throw new MissingType("restitution cannot share an affine non-Data original", type, i);
        return [many, k, i, type, span];
      });
      signatures.set(name, { parameters, result: signature.result });
      bodies.set(name, { $: "Reply", x: term, s: original.s });
      changed.add(name);
    } catch (error) {
      // Unknown dependent projection types do not constitute a restitution
      // proof. In particular no fallback invents a relation to an opaque call.
      if (!(error instanceof MissingType)) throw error;
    }
  }
  return { bodies, signatures, changed };
}
