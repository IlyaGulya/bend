#!/usr/bin/env bun
/** Frozen full-parser graph: raw stage-0 HOAS references, lexical weights only. */
import { createHash, randomUUID } from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, posix, resolve } from "node:path";
import { book_load, book_nil, list_set, parse_body, parse_eat, parse_name, parse_open,
  parse_take, parse_tele, parse_term, parse_word, tele_bind, term_force, term_higher, term_lower, term_unapply, Var,
  type Body, type Book, type Env, type HTerm, type LTerm, type Parse, type Patt, type Quant, type Span } from "../bend2/bend.ts";

export const sourceCheckpoint = "0d0e204f";
export const sourceSha256 = "0009070688f8fffffbb8664e72bd4662bf1324675ba097297076d77939153df5";
const root = resolve(import.meta.dir, "..");
const parserPath = resolve(root, "bend2/selfhost/parser.bend");
export type ParserReference = {
  caller: string; callee: string; line: number; column: number;
  parsedOffset: number; sourceOffset: number;
};
export type ParserCall = {
  caller: string; callee: string; offset: number; line: number; column: number;
  args: LTerm[]; parent?: string;
};
export type ParserParameter = [quantity: Quant, name: string, index: number, type: LTerm, span: Span];
export type ParserSignature = { parameters: ParserParameter[]; result: LTerm };
export type ParserGraph = {
  source: string; definitions: string[]; edges: Record<string, string[]>;
  astReferences: ParserReference[]; unresolvedReferences: ParserReference[];
  parserBook: Book;
  bodies: Map<string, Body>;
  signatures: Map<string, ParserSignature>;
  calls: Map<string, ParserCall[]>;
};

/** Residual mutual recursion; singleton self recursion needs no feedback cut. */
export function mutualComponents(edges: Readonly<Record<string, readonly string[]>>, removed: ReadonlySet<string>): string[][] {
  let time = 0;
  const index = new Map<string, number>(), low = new Map<string, number>();
  const stack: string[] = [], active = new Set<string>(), components: string[][] = [];
  function visit(vertex: string): void {
    index.set(vertex, time); low.set(vertex, time++);
    stack.push(vertex); active.add(vertex);
    for (const target of [...(edges[vertex] ?? [])].sort()) {
      if (removed.has(target) || !Object.hasOwn(edges, target)) continue;
      if (!index.has(target)) {
        visit(target);
        low.set(vertex, Math.min(low.get(vertex)!, low.get(target)!));
      } else if (active.has(target)) {
        low.set(vertex, Math.min(low.get(vertex)!, index.get(target)!));
      }
    }
    if (low.get(vertex) === index.get(vertex)) {
      const component: string[] = [];
      let target: string;
      do {
        target = stack.pop()!;
        active.delete(target); component.push(target);
      } while (target !== vertex);
      if (component.length > 1) components.push(component.sort());
    }
  }
  for (const vertex of Object.keys(edges).sort()) if (!removed.has(vertex) && !index.has(vertex)) visit(vertex);
  return components.sort((a, b) => {
    const left = a.join('\0'), right = b.join('\0');
    return left < right ? -1 : left > right ? 1 : 0;
  });
}

/** Parse the real stage-0 source Body AST before match compilation. Each syntax
 * expression is traversed as raw HOAS with bound variables retained. This avoids
 * parse_def_body's flatten/lower replay of exhaustive match branches, not any
 * source syntax: every Match, Local and terminal source term is parsed by
 * the unchanged stage-0 parser. Datatypes/imports are loaded with book_load.
 */
export async function readParserGraph(source = readFileSync(parserPath, "utf8"), sourcePath = parserPath): Promise<ParserGraph> {
  const headers = [...source.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
  const names = new Set(headers.map(match => match[1]!));
  const declarations = [...source.matchAll(/^(type|def|law) \S+/gm)];
  const datatypeSource = source.slice(0, declarations[0]!.index) + declarations
    .filter(match => match[1] === "type" || match[1] === "law")
    .map(match => source.slice(match.index, declarations[declarations.indexOf(match) + 1]?.index ?? source.length))
    .join("\n");
  const aliases: Record<string, string> = {};
  for (const match of source.matchAll(/^import (\S+) as ([A-Za-z_]\w*)$/gm)) {
    aliases[match[2]!] = posix.normalize(match[1]!).replace(/\.bend$/, "");
  }
  const book = book_nil();
  const temporary = resolve(dirname(sourcePath), `parser_full_graph_datatypes_${randomUUID()}.bend`);
  try {
    writeFileSync(temporary, datatypeSource);
    await book_load(book, temporary, "", new Map());
  } finally {
    rmSync(temporary, { force: true });
  }
  const definitions = [...names].sort();
  const edges: Record<string, string[]> = {};
  const astReferences: ParserReference[] = [], unresolvedReferences: ParserReference[] = [];
  const sourceLines = source.split("\n");
  const starts = [0];
  for (let i = 0; i < sourceLines.length - 1; i++) starts.push(starts[i]! + sourceLines[i]!.length + 1);
  const siteKeys = new Set<string>();
  const bodies = new Map<string, Body>(), signatures = new Map<string, ParserSignature>();
  const calls = new Map<string, ParserCall[]>();
  for (const header of headers) {
    const caller = header[1]!;
    const parser: Parse = { book, dir: dirname(sourcePath) + "/", str: source,
      pos: header.index!, stk: [], frs: 0, ns: "", al: aliases };
    if (!parse_word(parser, "def") || parse_name(parser) !== caller) throw Error("Invalid definition: " + caller);
    parse_eat(parser, "(");
    let parameters: ParserParameter[], result: LTerm;
    const templateKeys: string[] = [];
    const declaration = book.tlds[caller];
    if (declaration?.$ === "Def" && declaration.v === null) {
      parameters = [];
      let type = declaration.T;
      while (!parse_take(parser, ")")) {
        const key = parse_name(parser), index = parse_open(parser, key);
        if (type.$ !== "All") throw Error("Law signature has fewer parameters than " + caller);
        parameters.push([type.q, key, index, term_lower(type.A), { file: parser, beg: parser.pos - key.length, end: parser.pos }]);
        type = type.B(Var(key, index));
        parse_take(parser, ",");
      }
      result = term_lower(type);
    } else {
      parameters = parse_tele(parser, ")", templateKeys);
      parse_eat(parser, "->");
      result = parse_term(parser);
    }
    parse_eat(parser, ":");
    const body = parse_body(parser);
    const callerCalls: ParserCall[] = [];
    calls.set(caller, callerCalls);
    let parameterEnv: Env = null;
    for (const parameter of parameters) {
      parameter[3] = term_lower(term_higher(parameter[3], parameterEnv), parser.frs);
      parameterEnv = list_set(parameterEnv, parameter[2], Var(parameter[1], parameter[2]));
    }
    result = term_lower(term_higher(result, parameterEnv), parser.frs);
    if (!declaration) {
      // Authentic parsed signature; the raw Body is kept separately until replay.
      book.tlds[caller] = {$: "Def", n: parameters.length, x: templateKeys.length,
        T: term_higher(tele_bind(parameters, result)), v: null, m: parser.ns};
    }
    signatures.set(caller, { parameters, result });
    const targets = new Set<string>();
    const seen = new WeakSet<object>();
    function visit(input: HTerm, depth = 0): void {
      if (seen.has(input)) return;
      seen.add(input);
      const term = term_force(input);
      if (term !== input) {
        if (seen.has(term)) return;
        seen.add(term);
      }
      if (term.$ === "Ref") {
        if (names.has(term.k)) targets.add(term.k);
        if (names.has(term.k) || book.tlds[term.k] === undefined) {
          if (!term.s) throw Error(`Missing reference coordinates: ${caller} -> ${term.k}`);
          const prefix = term.s.file.str.slice(0, term.s.beg);
          const line = prefix.split("\n").length;
          const column = term.s.beg - prefix.lastIndexOf("\n");
          const site = { caller, callee: term.k, line, column, parsedOffset: term.s.beg,
            sourceOffset: starts[line - 1]! + column - 1 };
          const key = `${caller}\0${term.k}\0${site.sourceOffset}`;
          if (!siteKeys.has(key)) {
            siteKeys.add(key);
            (names.has(term.k) ? astReferences : unresolvedReferences).push(site);
          }
        }
        return;
      }
      if (term.$ === "Lam") { visit(term.f(Var(term.k, depth)), depth + 1); return; }
      if (term.$ === "All") { visit(term.A, depth); visit(term.B(Var(term.k, depth)), depth + 1); return; }
      if (term.$ === "Let") {
        for (const value of term.v) visit(value, depth);
        visit(term.f(term.k.map((key, i) => Var(key, depth + i))), depth + term.k.length);
        return;
      }
      if (term.$ === "App") {
        const [head, args] = term_unapply(term);
        visit(head, depth);
        for (const arg of args) visit(arg, depth);
        return;
      }
      // Syntax children only: never normalize references or traverse source spans.
      for (const [key, child] of Object.entries(term)) {
        if (key === "s") continue;
        if (Array.isArray(child)) {
          for (const item of child) if (item && typeof item === "object" && "$" in item) visit(item as HTerm, depth);
        } else if (child && typeof child === "object" && "$" in child) visit(child as HTerm, depth);
      }
    }
    const callSeen = new WeakMap<object, Set<string | undefined>>();
    function visitCalls(term: LTerm, parent?: string): void {
      const contexts = callSeen.get(term) ?? new Set<string | undefined>();
      if (contexts.has(parent)) return;
      contexts.add(parent); callSeen.set(term, contexts);
      if (term.$ === "App") {
        const [head, args] = term_unapply(term);
        if (head.$ === "Ref" && names.has(head.k)) {
          if (!head.s) throw Error("Missing call coordinates: " + caller + " -> " + head.k);
          const prefix = source.slice(0, head.s.beg);
          callerCalls.push({ caller, callee: head.k, offset: head.s.beg,
            line: prefix.split("\n").length, column: head.s.beg - prefix.lastIndexOf("\n"), args, parent });
        }
        visitCalls(head, parent);
        const consumer = head.$ === "Ref" ? head.k : parent;
        for (const arg of args) visitCalls(arg, consumer);
        return;
      }
      if (term.$ === "Lam") { visitCalls(term.f); return; }
      for (const [key, child] of Object.entries(term)) {
        if (key === "s") continue;
        if (Array.isArray(child)) {
          for (const item of child) if (item && typeof item === "object" && "$" in item) visitCalls(item as LTerm, parent);
        } else if (child && typeof child === "object" && "$" in child) visitCalls(child as LTerm, parent);
      }
    }
    function extendEnv(patterns: Patt[], input: Env): Env {
      let env = input;
      function bind(pattern: Patt): void {
        if (pattern.$ === "PVar") env = list_set(env, pattern.i, Var(pattern.k, pattern.i));
        else for (const child of pattern.x) bind(child);
      }
      for (const pattern of patterns) bind(pattern);
      return env;
    }
    function visitBody(body: Body, env: Env): Body {
      switch (body.$) {
        case "Local":
          body.v = body.v.map(value => {
            const expression = term_higher(value, env);
            visit(expression);
            const sourceTerm = term_lower(expression, parser.frs);
            visitCalls(sourceTerm);
            return sourceTerm;
          });
          body.f = visitBody(body.f, extendEnv(body.k, env));
          return body;
        case "Match":
          body.e = body.e.map(scrutinee => {
            const expression = term_higher(scrutinee, env);
            visit(expression);
            const sourceTerm = term_lower(expression, parser.frs);
            visitCalls(sourceTerm);
            return sourceTerm;
          });
          for (const row of body.r) row.f = visitBody(row.f, extendEnv(row.p, env));
          return body;
        default: {
          const expression = term_higher(body, env);
          visit(expression);
          const sourceTerm = term_lower(expression, parser.frs);
          visitCalls(sourceTerm);
          return sourceTerm;
        }
      }
    }
    bodies.set(caller, visitBody(body, parameterEnv));
    callerCalls.sort((a, b) => a.offset - b.offset || (a.parent ?? "").localeCompare(b.parent ?? ""));
    edges[caller] = [...targets].sort();
  }
  const ordered = (a: ParserReference, b: ParserReference) =>
    a.sourceOffset - b.sourceOffset || a.caller.localeCompare(b.caller) || a.callee.localeCompare(b.callee);
  astReferences.sort(ordered); unresolvedReferences.sort(ordered);
  return { source, definitions, edges, astReferences, unresolvedReferences, parserBook: book, bodies, signatures, calls };
}

export async function frozenParserGraph() {
  const source = readFileSync(parserPath, "utf8");
  const actual = createHash("sha256").update(source).digest("hex");
  if (actual !== sourceSha256) throw Error(`Canonical parser differs from checkpoint ${sourceCheckpoint}: ${actual}`);
  const current = await readParserGraph(source);
  const currentEdges = new Set(Object.entries(current.edges).flatMap(
    ([caller, targets]) => targets.map(target => `${caller}\0${target}`)));
  const currentUnresolved = new Set(current.unresolvedReferences.map(site => `${site.caller}\0${site.callee}`));
  const currentCounts = new Map<string, number>();
  for (const site of current.astReferences) {
    const key = `${site.caller}\0${site.callee}`;
    currentCounts.set(key, (currentCounts.get(key) ?? 0) + 1);
  }
  const comparisons = [];
  const historicalGraphs = new Map<string, ParserGraph>();
  for (const checkpoint of ["f640d749", "57c97c06", "89d5cdb7"]) {
    const historicalSource = execFileSync("git", ["show", `${checkpoint}:bend2/selfhost/parser.bend`], { cwd: root, encoding: "utf8" });
    const historical = await readParserGraph(historicalSource);
    historicalGraphs.set(checkpoint, historical);
    const priorEdges = new Set(Object.entries(historical.edges).flatMap(
      ([caller, targets]) => targets.map(target => `${caller}\0${target}`)));
    const priorCounts = new Map<string, number>();
    for (const site of historical.astReferences) {
      const key = `${site.caller}\0${site.callee}`;
      priorCounts.set(key, (priorCounts.get(key) ?? 0) + 1);
    }
    const priorUnresolved = new Set(historical.unresolvedReferences.map(site => `${site.caller}\0${site.callee}`));
    comparisons.push({ sourceCheckpoint: checkpoint,
      sourceSha256: createHash("sha256").update(historicalSource).digest("hex"),
      addedDefinitions: current.definitions.filter(name => !historical.definitions.includes(name)),
      removedDefinitions: historical.definitions.filter(name => !current.definitions.includes(name)),
      addedEdges: [...currentEdges].filter(edge => !priorEdges.has(edge)).sort().map(edge => edge.split("\0")),
      removedEdges: [...priorEdges].filter(edge => !currentEdges.has(edge)).sort().map(edge => edge.split("\0")),
      referenceCountDeltas: [...new Set([...currentCounts.keys(), ...priorCounts.keys()])].sort()
        .map(key => ({ caller: key.split("\0")[0]!, callee: key.split("\0")[1]!,
          delta: (currentCounts.get(key) ?? 0) - (priorCounts.get(key) ?? 0) }))
        .filter(site => site.delta !== 0),
      resolvedReferences: [...priorUnresolved].filter(site => !currentUnresolved.has(site)).sort().map(site => site.split("\0")),
      newUnresolvedReferences: [...currentUnresolved].filter(site => !priorUnresolved.has(site)).sort().map(site => site.split("\0")),
      historicalUnresolvedReferences: historical.unresolvedReferences,
      currentUnresolvedReferences: current.unresolvedReferences,
      astReferenceCount: historical.astReferences.length, currentAstReferenceCount: current.astReferences.length });
  }
  // Preserve the old repair provenance between its own immutable snapshots,
  // not between those snapshots and the newly audited canonical source.
  function historicalDelta(from: string, to: string) {
    const before = historicalGraphs.get(from)!, after = historicalGraphs.get(to)!;
    const edges = (graph: ParserGraph) => new Set(Object.entries(graph.edges).flatMap(
      ([caller, targets]) => targets.map(target => `${caller}\0${target}`)));
    const refs = (graph: ParserGraph) => new Set(graph.unresolvedReferences.map(site => `${site.caller}\0${site.callee}`));
    const oldEdges = edges(before), newEdges = edges(after), oldRefs = refs(before), newRefs = refs(after);
    return {
      addedEdges: [...newEdges].filter(edge => !oldEdges.has(edge)).sort().map(edge => edge.split("\0")),
      removedEdges: [...oldEdges].filter(edge => !newEdges.has(edge)),
      changedDefinitions: before.definitions.some(name => !after.definitions.includes(name)) || after.definitions.some(name => !before.definitions.includes(name)),
      resolvedReferences: [...oldRefs].filter(ref => !newRefs.has(ref)).sort().map(ref => ref.split("\0")),
      newUnresolvedReferences: [...newRefs].filter(ref => !oldRefs.has(ref))
    };
  }
  const repaired = historicalDelta("57c97c06", "89d5cdb7");
  if (repaired.addedEdges.length || repaired.removedEdges.length || repaired.changedDefinitions ||
      repaired.resolvedReferences.length || repaired.newUnresolvedReferences.length) {
    throw Error("Historical SymbolToken default changed the parser call graph: " + JSON.stringify(repaired));
  }
  const baseline = historicalDelta("f640d749", "57c97c06");
  if (JSON.stringify(baseline.addedEdges) !== JSON.stringify([["parse_do_atom_colon", "do_first_col"]]) ||
      baseline.removedEdges.length || baseline.changedDefinitions || baseline.newUnresolvedReferences.length ||
      JSON.stringify(baseline.resolvedReferences) !== JSON.stringify([["parse_do_atom_colon", "do_first"]])) {
    throw Error("Historical baseline graph delta is not exactly the do_first repair: " + JSON.stringify(baseline));
  }
  return { sourceCheckpoint, sourceSha256, graphProvenance: "stage0-source-Body-AST/raw-HOAS-expressions",
    source: current.source, definitions: current.definitions, edges: current.edges,
    astReferences: current.astReferences, unresolvedReferences: current.unresolvedReferences, comparisons };
}

if (import.meta.main) {
  const raw = await frozenParserGraph();
  if (Bun.argv.includes("--raw-stdout")) {
    console.log(JSON.stringify(raw));
  } else {
    if (Bun.argv.slice(2).some(arg => arg !== "--stdout")) throw Error("Usage: bun evals/parser_full_graph.ts [--stdout | --raw-stdout]");
    const analyzed = spawnSync("python3", [resolve(import.meta.dir, "parser_feedback_vertices.py"), "--ast-stdin"],
      { cwd: root, input: JSON.stringify(raw), encoding: "utf8", maxBuffer: 32 * 1024 * 1024 });
    if (analyzed.status !== 0) throw Error(analyzed.stderr || "Weighted cut analysis failed");
    const result = JSON.parse(analyzed.stdout);
    if (Bun.argv.includes("--stdout")) console.log(JSON.stringify(result));
    else {
      const output = resolve(root, "bend2/selfhost/parser_full_cut.json");
      writeFileSync(output, JSON.stringify(result, null, 2) + "\n");
      console.log(JSON.stringify({ output, mainSCC: result.mainSCC.length, selected: result.selected,
        additionalSelected: result.additionalSelected, residualNonSingletonSCCs: result.residualNonSingletonSCCs,
        completeResidualNonSingletonSCCs: result.completeResidualNonSingletonSCCs }));
    }
  }
}
