import * as B from '../bend2/bend.ts';
import type {ParserParameter} from './parser_full_graph.ts';

export type PureTailStats = {
  rootEligible: boolean;
  constructorSplits: number;
  eligibleSplits: number;
  optimizedWildcardMemberships: number;
  unoptimizedWildcardMemberships: number;
  freshBinders: number;
  residualBindings: number;
  residualParameters: number;
  explicitFreeParameters: number;
  capturedManyParameters: number;
};
export type PureTailCompilation = {
  term: B.LTerm;
  stats: PureTailStats;
  residualNames: string[];
};

type Row = B.Case & {source: boolean};
type Matrix = {e: B.LTerm[]; r: Row[]; s?: B.Span};
type Binding = {p: B.PVar; T: B.HTerm};
type FreeUses = {all: Set<number>; live: Set<number>};

// Unlike the earlier pointer-sharing witness, every residual here has one
// syntax definition and ordinary, separately allocated Var/App call sites.
// Affine free values are explicit parameters: constructing a closure cannot
// consume an affine value also used by a successful prefix branch. Unchanged
// Many values may remain lexical captures at their existing source quantity.
export function compilePureTail(
  body: B.Body,
  parameters: ParserParameter[],
  result: B.LTerm,
  book: B.Book,
): PureTailCompilation {
  const stats: PureTailStats = {
    rootEligible: false, constructorSplits: 0, eligibleSplits: 0,
    optimizedWildcardMemberships: 0, unoptimizedWildcardMemberships: 0,
    freshBinders: 0, residualBindings: 0, residualParameters: 0,
    explicitFreeParameters: 0, capturedManyParameters: 0,
  };
  const residualNames: string[] = [];
  const names = new Set<string>();
  let identity: B.Env = null;
  let next = 0;

  function reserve(i: number, k: string): void {
    if (i >= 0) {
      next = Math.max(next, i + 1);
      identity = B.list_set(identity, i, B.Var(k, i));
    }
    names.add(k);
  }
  function scanPattern(p: B.Patt): void {
    if (p.$ === 'PVar') reserve(p.i, p.k);
    else p.x.forEach(scanPattern);
  }
  function scanTerm(t: B.LTerm): void {
    switch (t.$) {
      case 'Var': reserve(t.i, t.k); return;
      case 'Ref': case 'Qnt': case 'Qua': case 'Efq': case 'Rfl': case 'Hol': return;
      case 'Sub':
        if (t.v.$ === 'PVar' || t.v.$ === 'PCtr') scanPattern(t.v);
        else scanTerm(t.v);
        scanTerm(t.f); return;
      case 'Let':
        t.i.forEach((i, j) => reserve(i, t.k[j]));
        t.v.forEach(scanTerm); scanTerm(t.f); return;
      case 'All': reserve(t.i, t.k); scanTerm(t.A); scanTerm(t.B); return;
      case 'Lam': reserve(t.i, t.k); scanTerm(t.f); return;
      case 'Typ': scanTerm(t.g); return;
      case 'Min': scanTerm(t.a); scanTerm(t.b); return;
      case 'App': scanTerm(t.f); scanTerm(t.x); return;
      case 'ADT': case 'Ctr': t.x.forEach(scanTerm); return;
      case 'Mat': scanTerm(t.h); scanTerm(t.m); return;
      case 'Eql': scanTerm(t.a); scanTerm(t.b); scanTerm(t.T); return;
      case 'Rwt': scanTerm(t.e); scanTerm(t.p); scanTerm(t.f); return;
      case 'Ann': scanTerm(t.x); scanTerm(t.T); return;
    }
  }
  function scanBody(b: B.Body): void {
    switch (b.$) {
      case 'Reply': scanTerm(b.x); return;
      case 'Local': b.k.forEach(scanPattern); b.v.forEach(scanTerm); scanBody(b.f); return;
      case 'Match':
        b.e.forEach(scanTerm);
        for (const row of b.r) { row.p.forEach(scanPattern); scanBody(row.f); }
        return;
    }
  }
  scanBody(body);
  for (const [, k, i, T] of parameters) { reserve(i, k); scanTerm(T); }
  scanTerm(result);
  const initialFresh = next;
  function fresh(): number {
    const i = next++;
    identity = B.list_set(identity, i, B.Var('_' + i, i));
    return i;
  }
  // Lowering types opens their own binders above every existing source ID.
  // Reserve those IDs too, so later generated term binders cannot capture them.
  function lowerType(T: B.HTerm): B.LTerm {
    const t = B.term_lower(T, next);
    scanTerm(t);
    return t;
  }

  // Opening HOAS with negative, analysis-only IDs separates lexical binders
  // from the nonnegative source identities. No observation cache or opened
  // body is ever handed to a converter or reused in generated syntax.
  function freeUses(t: B.HTerm): FreeUses {
    const uses: FreeUses = {all: new Set(), live: new Set()};
    let opened = -2;
    function visit(x: B.HTerm, live: boolean): void {
      switch (x.$) {
        case 'Var':
          if (x.i >= 0) {
            uses.all.add(x.i);
            if (live) uses.live.add(x.i);
          } else if (x.v !== undefined) {
            // Runtime cells are transparent to dependency analysis; only our
            // analysis-opened negative Vars (which have no value) are bound.
            visit(B.term_force(x), live);
          }
          return;
        case 'Ref': case 'Qnt': case 'Qua': case 'Efq': case 'Rfl': case 'Hol': return;
        case 'Sub':
          // term_higher resolves lower Sub environments before this traversal.
          throw Error('Pure-tail analysis requires a materialized substitution');
        case 'Let':
          x.v.forEach((v, j) => visit(v, live && x.q[j].$ !== 'None'));
          visit(x.f(x.k.map(k => B.Var(k, opened--))), live); return;
        case 'Lam': visit(x.f(B.Var(x.k, opened--)), live); return;
        case 'All': visit(x.A, false); visit(x.B(B.Var(x.k, opened--)), false); return;
        case 'Typ': visit(x.g, false); return;
        case 'Min': visit(x.a, live); visit(x.b, live); return;
        case 'App': visit(x.f, live); visit(x.x, live); return;
        case 'ADT': case 'Ctr': x.x.forEach(v => visit(v, live)); return;
        case 'Mat': visit(x.h, live); visit(x.m, live); return;
        case 'Eql': visit(x.a, false); visit(x.b, false); visit(x.T, false); return;
        case 'Rwt': visit(x.e, live); visit(x.p, false); visit(x.f, live); return;
        case 'Ann': visit(x.x, live); visit(x.T, false); return;
      }
    }
    visit(t, true);
    return uses;
  }

  function matrix(m: B.Match): Matrix {
    return {e: m.e, r: m.r.map(row => ({...row, source: true})), s: m.s};
  }
  function tailStart(m: Matrix): number {
    let last = -1;
    for (let j = 0; j < m.r.length; j++) if (m.r[j].p[0]?.$ === 'PCtr') last = j;
    if (last < 0 || last === m.r.length - 1) return -1;
    // The constructor prefix must contain no before/between wildcard, of ANY
    // constructor identity. This is intentionally stricter than a per-C tail.
    if (m.r.slice(0, last + 1).some(row => row.p[0]?.$ !== 'PCtr')) return -1;
    if (m.r.slice(last + 1).some(row => row.p[0]?.$ !== 'PVar')) return -1;
    return last + 1;
  }

  function flattenBody(b: B.Body, vars: B.PVar[], goal: B.HTerm, bound: Binding[], allowFactor: boolean): B.LTerm {
    switch (b.$) {
      case 'Reply': return B.body_flatten(b, vars, fresh);
      case 'Local': {
        if (b.k.length === 1 && b.k[0].$ === 'PCtr') {
          return flattenMatch({e: [b.v[0]], r: [{p: [b.k[0]], f: b.f, source: true}], s: b.v[0].s}, vars, goal, bound, allowFactor);
        }
        // Native body_flatten deliberately compiles local bodies with ONLY
        // their local binders, then requires every one to remain a Lam. Thus
        // a statement match after a variable Local is forbidden, rather than
        // a place where this compiler may invent types or broaden factoring.
        return B.body_flatten(b, vars, fresh);
      }
      case 'Match': return flattenMatch(matrix(b), vars, goal, bound, allowFactor);
    }
  }

  function factor(m: Matrix, vars: B.PVar[], goal: B.HTerm, bound: Binding[], start: number): B.LTerm {
    const suffix: Matrix = {...m, r: m.r.slice(start)};
    // Compile the ordered suffix exactly once with normal baseline lowering.
    // The opt-out propagates through every recursive match/body descendant:
    // the residual's internal decision tree is not transformed.
    let value = flattenMatch(suffix, vars, goal, bound, false);
    const valueUses = freeUses(B.term_higher(value, identity));
    const needed = new Set(valueUses.all);
    const goalUses = freeUses(goal);
    goalUses.all.forEach(i => needed.add(i));
    const byId = new Map(bound.map(b => [b.p.i, b]));
    const dependencies = new Map<number, Set<number>>();
    const queue = [...needed];
    for (let j = 0; j < queue.length; j++) {
      const i = queue[j];
      const binding = byId.get(i);
      if (!binding) throw Error('Pure-tail residual has no bound type for source identity ' + i);
      const refs = freeUses(binding.T).all;
      dependencies.set(i, refs);
      for (const dependency of refs) {
        if (!needed.has(dependency)) { needed.add(dependency); queue.push(dependency); }
      }
    }
    // Retain genuinely reusable, already-bound values without introducing
    // extra parameter Lambdas (which would advance the native recursive LHS).
    // A retained value's type must not depend on an abstracted parameter:
    // otherwise its lexical type refers to the old identity, not that
    // parameter's arbitrary value. Propagate that requirement to a fixed point.
    const explicitIds = new Set(bound.filter(b => needed.has(b.p.i) && b.p.q.$ !== 'Many').map(b => b.p.i));
    let changed = true;
    while (changed) {
      changed = false;
      for (const b of bound) {
        if (!needed.has(b.p.i) || explicitIds.has(b.p.i)) continue;
        if ([...(dependencies.get(b.p.i) ?? [])].some(i => explicitIds.has(i))) {
          explicitIds.add(b.p.i);
          changed = true;
        }
      }
    }
    stats.capturedManyParameters += bound.filter(b => needed.has(b.p.i) && !explicitIds.has(b.p.i)).length;
    // Bound-context order is telescope order: domain dependencies precede
    // their users. Type-only explicit dependencies are erased parameters.
    const explicit = bound.filter(b => explicitIds.has(b.p.i)).map(b => ({
      ...b, p: {...b.p, q: valueUses.live.has(b.p.i) ? b.p.q : B.None()},
    }));
    let type = lowerType(goal);
    for (let j = explicit.length - 1; j >= 0; j--) {
      const {p, T} = explicit[j];
      value = B.Lam(p.k, p.i, value, p.s, p.q);
      type = B.All(p.q, p.k, p.i, lowerType(T), type, p.s);
    }
    const i = fresh();
    let name = '__pure_tail_' + i;
    while (names.has(name)) name += '_';
    reserve(i, name);
    residualNames.push(name);
    stats.residualBindings++;
    stats.residualParameters += explicit.length + vars.length;
    stats.explicitFreeParameters += explicit.length;
    const alternatives = new Set(m.r.slice(0, start).map(row => {
      const p = row.p[0];
      if (p.$ !== 'PCtr') throw Error('Pure-tail constructor prefix changed');
      return p.k;
    })).size;
    stats.eligibleSplits += alternatives;
    stats.optimizedWildcardMemberships += suffix.r.filter(row => row.source).length * alternatives;

    let call: B.LTerm = B.Var(name, i, m.s);
    for (const {p} of explicit) call = B.App(call, B.patt_term(p), m.s);
    for (const p of vars) call = B.App(call, B.patt_term(p), m.s);
    const terminal: Row = {
      // Aggregate the suffix's explicit copy marks, without granting Many to
      // the function. These are the same column joins the baseline performs.
      p: m.e.map((_, column): B.PVar => {
        const id = fresh();
        const q = suffix.r.reduce((q, row) => {
          const p = row.p[column];
          return p?.$ === 'PVar' ? B.quant_join(q, p.q) : q;
        }, B.Lone());
        return {$: 'PVar', k: '_' + id, i: id, q, s: m.s};
      }),
      f: {$: 'Reply', x: call, s: m.s}, source: false,
    };
    const residual: Binding = {
      p: {$: 'PVar', k: name, i, q: B.Lone(), s: m.s},
      T: B.term_higher(type, identity),
    };
    const prefix = flattenMatch({...m, r: [...m.r.slice(0, start), terminal]}, vars, goal, [...bound, residual], true);
    return B.Let([name], [i], [B.Ann(value, type, m.s)], prefix, m.s, [B.Lone()]);
  }

  function flattenMatch(m: Matrix, vars: B.PVar[], goal: B.HTerm, bound: Binding[], allowFactor: boolean): B.LTerm {
    if (m.e.length === 0 && m.r.length > 0) {
      return flattenBody(m.r[0].f, vars, goal, bound, allowFactor);
    } else if (m.e.length === 0 || vars.length === 0) {
      // Preserve all legacy missing-row/consumed/computed-scrutinee errors.
      return B.match_flatten({$: 'Match', ...m}, vars, fresh);
    }
    const x = vars[0];
    const scu = m.e[0];
    const c = m.r.map(row => row.p[0]).find((p): p is B.PCtr => p.$ === 'PCtr') ?? null;
    const v = vars.find(w => scu.$ === 'Var' && w.i === scu.i);
    if (v !== undefined && c === null && m.r.length > 0) {
      const w = {...v, q: B.patt_mark(v, m.r)};
      const rows = m.r.map((row): Row => {
        const p0 = row.p[0];
        if (p0.$ !== 'PVar') {
          throw B.Err(B.book_nil(), B.ctx_nil(), 'a variable pattern (this column has no constructor row)', undefined, p0.s);
        }
        return {...row, p: row.p.slice(1), f: B.body_sub(row.f, p0.i, w)};
      });
      return flattenMatch({...m, e: m.e.slice(1), r: rows}, vars.map(u => u === v ? w : u), goal, bound, allowFactor);
    } else if (v === x) {
      if (c === null) return B.Efq(m.s);
      const start = allowFactor ? tailStart(m) : -1;
      // A synthetic terminal already denotes an ancestor's one compiled
      // residual; factoring that singleton again would only add forwarding
      // closures, not eliminate any source wildcard duplication.
      if (start >= 0 && m.r.slice(start).some(row => row.source)) return factor(m, vars, goal, bound, start);
      stats.constructorSplits++;
      stats.unoptimizedWildcardMemberships += m.r.filter(row => row.source && row.p[0].$ === 'PVar').length;
      const xq = B.patt_mark(x, m.r);
      const xs = c.x.map((p): B.PVar => {
        if (p.$ === 'PVar') return {...p, q: B.quant_join(p.q, xq)};
        const i = fresh();
        return {$: 'PVar', k: '_' + i, i, q: xq, s: p.s};
      });
      const kx: B.PCtr = {$: 'PCtr', k: c.k, x: xs, s: x.s};
      const rows = m.r.flatMap((row): Row[] => {
        const p0 = row.p[0];
        if (p0.$ === 'PCtr') {
          if (p0.k !== c.k) return [];
          if (p0.x.length !== xs.length) {
            throw B.Err(B.book_nil(), B.ctx_nil(), 'a ' + c.k + ' pattern with ' + xs.length + ' fields', undefined, p0.s);
          }
          return [{...row, p: [...p0.x, ...row.p.slice(1)], f: B.body_sub(row.f, x.i, kx)}];
        }
        const g = B.body_sub(row.f, p0.i, x);
        return [{...row, p: [...xs, ...row.p.slice(1)], f: B.body_sub(g, x.i, kx)}];
      });
      // Mirror check-mat's dependent goal construction, rather than guessing
      // field types from names or annotating the continuation with a hole.
      const all = B.tele_head(book, goal, B.ctx_nil(), undefined, m.s);
      const domain = B.term_wnf(book, all.A);
      if (domain.$ !== 'ADT') throw B.Err(book, B.ctx_nil(), 'a datatype', all.A, m.s);
      const adt = B.book_adt(book, domain, B.ctx_nil());
      const ctr = B.ctrs_find(adt.c, c.k);
      if (ctr === null) throw B.Err(book, B.ctx_nil(), 'a constructor of ' + domain.k, B.Ref(c.k), c.s);
      const tel = B.tele_fill(book, ctr.T, domain.x, B.ctx_nil(), undefined, c.s);
      function fieldGoal(cur: B.HTerm, n: number, fields: B.HTerm[]): B.HTerm {
        if (n === 0) return all.B(B.Ctr(c!.k, fields, c!.s));
        const head = B.tele_head(book, cur, B.ctx_nil(), undefined, c!.s);
        const q = head.q.$ === 'None' ? B.None() : head.q.$ === 'Lone' ? all.q : B.quant_add(all.q, all.q);
        return B.All(q, head.k, head.i, head.A, (field: B.HTerm) => fieldGoal(head.B(field), n - 1, [...fields, field]), c!.s);
      }
      const pt = flattenMatch({e: xs.map(p => B.patt_term(p)).concat(m.e.slice(1)), r: rows, s: m.s}, xs.concat(vars.slice(1)), fieldGoal(tel, ctr.n, []), bound, allowFactor);
      const defaults = m.r.filter(row => row.p[0].$ !== 'PCtr' || row.p[0].k !== c.k);
      const defaultGoal: B.HTerm = B.All(all.q, all.k, all.i, B.ADT(domain.k, domain.x, m.s, domain.r.concat([ctr.k])), all.B, m.s);
      const dt = flattenMatch({...m, r: defaults}, vars, defaultGoal, bound, allowFactor);
      return B.Mat(c.k, pt, dt, c.s);
    } else {
      const all = B.tele_head(book, goal, B.ctx_nil(), undefined, x.s);
      const p = {...x, q: all.q.$ === 'Lone' && x.q.$ === 'Many' ? x.q : all.q};
      const t = flattenMatch(m, vars.slice(1), all.B(B.Var(x.k, x.i)), [...bound, {p, T: all.A}], allowFactor);
      return B.Lam(x.k, x.i, t, x.s, x.q);
    }
  }

  const vars: B.PVar[] = parameters.map(([q, k, i, , s]) => ({$: 'PVar', q, k, i, s}));
  if (body.$ === 'Match') {
    stats.rootEligible = tailStart(matrix(body)) >= 0
      && body.e[0]?.$ === 'Var' && vars.some(p => body.e[0].$ === 'Var' && p.i === body.e[0].i);
  }
  const goal = B.term_higher(B.tele_bind(parameters, result), identity);
  const term = flattenBody(body, vars, goal, [], true);
  stats.freshBinders = next - initialFresh;
  return {term, stats, residualNames};
}
