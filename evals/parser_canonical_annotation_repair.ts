#!/usr/bin/env bun
/** Source-preserving, native-proved proposals only; never writes parser.bend. */
import * as B from "../bend2/bend.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

type Scope = { ctx: B.Ctx; env: B.Env; next: number };
type Site = {
  function: string; path: string; line: number; beg: number; end: number;
  constructor: string; owningDatatype: string; sourceType: string;
  before: string; after: string; status: "PROVEN" | "BLOCKED";
  inferenceDiagnostic?: string; typingDiagnostic?: string;
  ownershipDiagnostics: string[]; contextDiagnostic?: string;
  uses?: { index: number; name: string; available: string; used: string }[];
};
const diagnostic = (error: unknown) => (error as B.Err)?.$ === "Err" ? B.err_show(error as B.Err) : String(error);
// Spans change on reparse; no semantic field (including quantities) is ignored.
const shape = (node: unknown) => JSON.stringify(node, (key, value) => key === "s" || (value && typeof value === "object" && "src" in value && "beg" in value && "end" in value) ? undefined : value);

/** Applies an already-proved plan in memory; rejects stale source and spans. */
export function applyAnnotationRepairs(source: string, plan: { sourceSha256: string; repairs: Pick<Site, "beg" | "end" | "before" | "after">[] }): string {
  if (createHash("sha256").update(source).digest("hex") !== plan.sourceSha256) throw Error("Stale annotation plan: regenerate against current source");
  const repairs = [...plan.repairs].sort((a, b) => a.beg - b.beg);
  let previousEnd = 0;
  for (const repair of repairs) {
    if (!Number.isInteger(repair.beg) || !Number.isInteger(repair.end) || repair.beg < previousEnd || repair.end <= repair.beg || repair.end > source.length) throw Error("Invalid or overlapping annotation repair spans");
    if (source.slice(repair.beg, repair.end) !== repair.before) throw Error("Annotation RHS span drift");
    previousEnd = repair.end;
  }
  let candidate = source;
  for (const repair of repairs.reverse()) candidate = candidate.slice(0, repair.beg) + repair.after + candidate.slice(repair.end);
  return candidate;
}

export async function planAnnotationRepairs(source: string) {
  const graph = await readParserGraph(source);
  const book: B.Book = { ...graph.parserBook, tlds: { ...graph.parserBook.tlds } };
  for (const [name, sig] of graph.signatures) {
    book.tlds[name] = { $: "Def", n: sig.parameters.length, T: B.term_higher(B.tele_bind(sig.parameters, sig.result)), v: null, b: true };
  }
  const lhs: B.LHS = { t: B.Ref("canonical_annotation_repair"), n: 0, def: "canonical_annotation_repair", qs: [] };
  const aliases = [...source.matchAll(/^import (\S+) as (\w+)$/gm)].map(m => [m[1]!.replace(/^.*\//, "").replace(/\.bend$/, ""), m[2]!] as const);
  const sourceType = (name: string) => {
    for (const [namespace, alias] of aliases) if (name.startsWith(namespace + ".")) return alias + name.slice(namespace.length);
    if (name.includes(".")) throw Error("No source alias for datatype " + name);
    return name;
  };
  function owner(t: B.LTerm): string | undefined {
    if (t.$ !== "Ctr" || !book.ctrs[t.k]) return;
    const name = B.book_fam(book, t.k), datatype = book.tlds[name];
    if (datatype?.$ === "ADT" && datatype.n === 0 && datatype.c.some(c => c.k === t.k)) return name;
  }
  const sites: Site[] = [], byPath = new Map<string, Site>();
  const excluded: { function: string; path: string; constructor: string; reason: string }[] = [];
  function inventory(name: string, body: B.Body, path: string) {
    if (body.$ === "Local") {
      body.v.forEach((value, i) => {
        if (value.$ !== "Ctr") return;
        const datatype = owner(value), key = `${name}:${path}.v.${i}`;
        if (!datatype) { excluded.push({ function: name, path: key, constructor: value.k, reason: "No unique owning monomorphic datatype" }); return; }
        if (!value.s) throw Error("Missing RHS span at " + key);
        const { beg, end } = value.s, before = source.slice(beg, end), T = sourceType(datatype);
        const site: Site = { function: name, path: key, line: source.slice(0, beg).split("\n").length, beg, end,
          constructor: value.k, owningDatatype: datatype, sourceType: T, before, after: `{ ${before} : ${T} }`, status: "BLOCKED", ownershipDiagnostics: [] };
        sites.push(site); byPath.set(key, site);
      });
      inventory(name, body.f, path + ".f");
    } else if (body.$ === "Match") body.r.forEach((row, i) => inventory(name, row.f, `${path}.r.${i}.f`));
  }
  for (const [name, body] of graph.bodies) inventory(name, body, "body");

  // This is the native check-mat field demand rule, not a freely duplicable
  // hypothesis. A source + binder upgrades only after native kind checking.
  function bind(pattern: B.Patt, T: B.HTerm, quantity: B.Quant, scope: Scope): { scope: Scope; value: B.HTerm } {
    if (pattern.$ === "PVar") {
      let q = quantity;
      if (pattern.q.$ === "Many" && q.$ === "Lone") { B.term_check_kind(book, lhs, T, pattern.q, scope.ctx, scope.next, pattern.s); q = pattern.q; }
      if (pattern.k === "_") return { scope: { ...scope, next: scope.next + 1 }, value: B.Var("annotation_wild", scope.next) };
      const value = B.Var(pattern.k, pattern.i, pattern.s);
      return { scope: { ctx: B.ctx_bind(scope.ctx, pattern.i, q, pattern.k, T), env: B.list_set(scope.env, pattern.i, value), next: Math.max(scope.next, pattern.i + 1) }, value };
    }
    const type = B.term_wnf(book, T), constructor = book.ctrs[pattern.k];
    if (type.$ !== "ADT" || !constructor || book.tlds[type.k]?.$ !== "ADT" || !(book.tlds[type.k] as B.ADT).c.some(c => c.k === pattern.k)) throw Error("Native pattern datatype mismatch: " + pattern.k);
    if (pattern.x.length !== constructor.n) throw Error("Native pattern constructor arity mismatch: " + pattern.k);
    let tel = B.tele_fill(book, constructor.T, type.x, scope.ctx), current = scope;
    const values: B.HTerm[] = [];
    for (const child of pattern.x) {
      const head = B.tele_head(book, tel, current.ctx);
      const q = head.q.$ === "None" ? B.None() : head.q.$ === "Lone" ? quantity : B.quant_add(quantity, quantity);
      const bound = bind(child, head.A, q, current); current = bound.scope; values.push(bound.value); tel = head.B(bound.value);
    }
    return { scope: current, value: B.Ctr(pattern.k, values) };
  }
  function infer(value: B.LTerm, scope: Scope, q: B.Quant): B.Infer {
    const term = B.term_higher(value, scope.env);
    try { return B.term_infer(book, lhs, term, q, scope.ctx, scope.next); }
    catch (error) {
      const datatype = owner(value);
      if (!datatype) throw error;
      const type = B.ADT<B.HBody>(datatype, []);
      const checked = B.term_check(book, lhs, term, q, type, scope.ctx, scope.next);
      return { ...checked, ty: type };
    }
  }
  function markContext(name: string, body: B.Body, path: string, error: unknown): void {
    if (body.$ === "Local") {
      body.v.forEach((_, i) => { const site = byPath.get(`${name}:${path}.v.${i}`); if (site && !site.inferenceDiagnostic && !site.typingDiagnostic) site.contextDiagnostic = diagnostic(error); });
      markContext(name, body.f, path + ".f", error);
    } else if (body.$ === "Match") body.r.forEach((row, i) => markContext(name, row.f, `${path}.r.${i}.f`, error));
  }
  function walk(name: string, body: B.Body, scope: Scope, path: string): void {
    if (body.$ !== "Local" && body.$ !== "Match") return;
    if (body.$ === "Local") {
      let inner = scope;
      for (let i = 0; i < body.v.length; i++) {
        const value = body.v[i]!, site = byPath.get(`${name}:${path}.v.${i}`);
        const pattern = body.k[i]!, binderQuantity = pattern.$ === "PVar" ? B.quant_join(body.q, pattern.q) : body.q;
        const q = B.quant_dem(binderQuantity, B.Lone());
        let inferred: B.Infer;
        try {
          if (site) {
            try { B.term_infer(book, lhs, B.term_higher(value, scope.env), q, scope.ctx, scope.next); throw Error("Bare constructor unexpectedly inferred"); }
            catch (error) { site.inferenceDiagnostic = diagnostic(error); if (!site.inferenceDiagnostic.includes("cannot infer")) throw error; }
          }
          inferred = infer(value, scope, q);
          if (site) {
            // Ann must itself infer the original datatype, not just check the RHS.
            const annotated = B.Ann(B.term_higher(value, scope.env), B.ADT<B.HBody>(site.owningDatatype, []));
            const proof = B.term_infer(book, lhs, annotated, q, scope.ctx, scope.next);
            if (!B.term_compare("EQ", book, proof.ty, inferred.ty, scope.next)) throw Error("Annotation changed inferred datatype");
            if (JSON.stringify(B.pmap_to_array(proof.us)) !== JSON.stringify(B.pmap_to_array(inferred.us))) throw Error("Annotation changed native resource demands");
            site.uses = B.pmap_to_array(proof.us).map(([index, used]) => { const a = B.pmap_get(scope.ctx, index); return { index, name: a?.k ?? "unbound", available: a?.q.$ ?? "unbound", used: used.$ }; });
            for (const [index, used] of B.pmap_to_array(proof.us)) {
              const a = B.pmap_get(scope.ctx, index);
              if (!a) throw Error("Native usage escaped context");
              try { B.quant_used(book, scope.ctx, a.k, a.q, used, value.s, name); } catch (error) { site.ownershipDiagnostics.push(diagnostic(error)); }
            }
            site.status = site.ownershipDiagnostics.length ? "BLOCKED" : "PROVEN";
          }
        } catch (error) {
          if (site) site.typingDiagnostic = diagnostic(error);
          markContext(name, body.f, path + ".f", error); return;
        }
        try {
          if (pattern.$ === "PVar") B.term_check_kind(book, lhs, inferred.ty, binderQuantity, scope.ctx, scope.next, pattern.s);
          inner = bind(pattern, inferred.ty, binderQuantity, inner).scope;
        }
        catch (error) { markContext(name, body.f, path + ".f", error); return; }
      }
      walk(name, body.f, inner, path + ".f"); return;
    }
    let types: B.HTerm[];
    try { types = body.e.map(value => infer(value, scope, B.Lone()).ty); }
    catch (error) { markContext(name, body, path, error); return; }
    body.r.forEach((row, i) => {
      let inner = scope;
      try {
        row.p.forEach((pattern, j) => {
          const scrutinee = body.e[j]!;
          if (scrutinee.$ !== "Var") throw Error("Native scope requires parameter/field scrutinee");
          const ann = B.pmap_get(scope.ctx, scrutinee.i);
          if (!ann) throw Error("Scrutinee absent from native scope");
          inner = bind(pattern, types[j]!, ann.q, inner).scope;
        });
        walk(name, row.f, inner, `${path}.r.${i}.f`);
      } catch (error) { markContext(name, row.f, `${path}.r.${i}.f`, error); }
    });
  }
  for (const [name, sig] of graph.signatures) {
    // Do not evaluate unrelated expression bodies; this family is bounded by its inventory.
    if (!sites.some(site => site.function === name)) continue;
    let scope: Scope = { ctx: B.ctx_nil(), env: null, next: 0 };
    try {
      for (const [q, k, i, T, s] of sig.parameters) scope = bind({ $: "PVar", q, k, i, s }, B.term_higher(T, scope.env), q, scope).scope;
      walk(name, graph.bodies.get(name)!, scope, "body");
    } catch (error) { markContext(name, graph.bodies.get(name)!, "body", error); }
  }
  sites.sort((a, b) => a.beg - b.beg);
  async function verifyCandidate(selected: Site[]) {
    const candidate = applyAnnotationRepairs(source, { sourceSha256: createHash("sha256").update(source).digest("hex"), repairs: selected });
    const reparsed = await readParserGraph(candidate), selectedPaths = new Map(selected.map(site => [site.path, site]));
    let wraps = 0;
    function unwrap(name: string, body: B.Body, path: string): B.Body {
      if (body.$ === "Local") return { ...body, v: body.v.map((value, i) => {
        const site = selectedPaths.get(`${name}:${path}.v.${i}`);
        if (!site) return value;
        if (value.$ !== "Ann" || value.T.$ !== "Ref" || value.T.k !== site.owningDatatype) throw Error("Reparse did not add exactly the owning-type Ann at " + site.path);
        wraps++; return value.x;
      }), f: unwrap(name, body.f, path + ".f") };
      if (body.$ === "Match") return { ...body, r: body.r.map((row, i) => ({ ...row, f: unwrap(name, row.f, `${path}.r.${i}.f`) })) };
      return body;
    }
    if (shape(graph.definitions) !== shape(reparsed.definitions)) throw Error("Candidate changed definition inventory");
    for (const [name, body] of graph.bodies) {
      if (shape(graph.signatures.get(name)) !== shape(reparsed.signatures.get(name))) throw Error("Candidate changed signature " + name);
      if (shape(body) !== shape(unwrap(name, reparsed.bodies.get(name)!, "body"))) throw Error("Candidate changed original value, binder, or body structure in " + name);
    }
    if (wraps !== selected.length) throw Error("Annotation count mismatch");
    return { sourceSha256: createHash("sha256").update(candidate).digest("hex"), annotations: wraps, definitionsCompared: graph.bodies.size, signaturesUnchanged: true, originalValuesBindersAndBodiesUnchanged: true };
  }
  const repairs = sites.filter(site => site.status === "PROVEN");
  const typedProposals = sites.filter(site => site.inferenceDiagnostic && !site.typingDiagnostic && !site.contextDiagnostic);
  return {
    sourceSha256: createHash("sha256").update(source).digest("hex"), method: "Native signature-only book, monomorphic constructor ownership, native constructor telescope pattern quantities, original parameter/local quantities, term_check RHS + term_infer Ann + quant_used for free-context usage.",
    limits: ["No canonical source writes.", "Per-RHS proof does not establish whole-body ownership, coverage, recursion, or signature validity.", "Ownership-blocked proposals are not accepted repairs; no quantity hypothesis is invented.", "Typing-only diagnostic candidate is reparse evidence, not source validity.", "Polymorphic constructor locals are excluded."],
    inventory: sites.length, proven: repairs.length, blocked: sites.length - repairs.length, excluded,
    repairs, blockers: sites.filter(site => site.status === "BLOCKED"),
    candidateVerification: await verifyCandidate(repairs),
    typingOnlyProposals: typedProposals,
    typingOnlyCandidateVerification: await verifyCandidate(typedProposals),
  };
}

if (import.meta.main) {
  const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");
  const source = readFileSync(input, "utf8"), report = await planAnnotationRepairs(source);
  const output = resolve(import.meta.dir, "../bend2/selfhost/parser.bend.canonical-annotation-repair.json");
  writeFileSync(output, JSON.stringify(report, null, 2) + "\n");
  console.log(JSON.stringify({ output, sourceSha256: report.sourceSha256, inventory: report.inventory, proven: report.proven, blocked: report.blocked, candidateVerification: report.candidateVerification, typingOnlyCandidateVerification: report.typingOnlyCandidateVerification }));
}
