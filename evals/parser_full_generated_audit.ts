#!/usr/bin/env bun
/** Full emitted parser graph: raw stage-0 syntax references, not reductions or typecheck evidence. */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, term_lower } from "../bend2/bend.ts";
import type { LTerm } from "../bend2/bend.ts";
import { guardHeavyGate } from "./heavy_gate.ts";
import { readParserGraph } from "./parser_full_graph.ts";

await guardHeavyGate(import.meta.path, { label: process.argv.includes("--source-ast") ? "parser-source-ast-graph" : "parser-eager-ast-audit" });

const path = resolve(process.argv[2] ?? resolve(import.meta.dir, "../bend2/selfhost/parser_full_generated.bend"));
const canonical = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");
const expected = "f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df";
const sha = (bytes: string | Buffer) => createHash("sha256").update(bytes).digest("hex");
const source = readFileSync(path, "utf8");
const scorecardBytes = readFileSync(path + ".scorecard.json");
const scorecard = JSON.parse(scorecardBytes.toString());
if (sha(readFileSync(canonical)) !== expected || scorecard.sourceSha256 !== expected || scorecard.sourceCheckpoint !== expected.slice(0, 8)) {
  throw Error("Full audit requires canonical semantic checkpoint " + expected.slice(0, 8));
}
const generatedSha256 = sha(source);
if (generatedSha256 !== scorecard.generatedSha256) throw Error("Full candidate differs from scorecard emission hash");
const names = [...source.matchAll(/^def ([A-Za-z_]\w*)\(/gm)].map(match => match[1]!).sort();
if (new Set(names).size !== names.length) throw Error("Duplicate emitted definition");
const local = new Set(names);
const sourceAST = process.argv.includes("--source-ast");
const edges = new Map<string, string[]>();
const references: Record<string, string[]> = {};
const unresolved: { caller: string; target: string }[] = [];
if (sourceAST) {
  const graph = await readParserGraph(source);
  if (JSON.stringify([...graph.definitions].sort()) !== JSON.stringify(names)) throw Error("Source AST definition inventory differs");
  for (const name of names) {
    references[name] = graph.edges[name]!;
    edges.set(name, graph.edges[name]!);
  }
  unresolved.push(...graph.unresolvedReferences.map(site => ({ caller: site.caller, target: site.callee })));
} else {
  const book = book_nil();
  await book_load(book, path, "", new Map());
  for (const name of names) {
    const definition = book.tlds[name];
    if (definition?.$ !== "Def" || definition.v === null) throw Error("Missing emitted AST: " + name);
    const targets = new Set<string>();
    const seen = new WeakSet<object>();
    function visit(node: LTerm): void {
      if (seen.has(node)) return;
      seen.add(node);
      if (node.$ === "Ref") targets.add(node.k);
      // term_lower opens binders without evaluating referenced definitions.
      for (const [key, child] of Object.entries(node)) {
        if (key === "s") continue;
        if (Array.isArray(child)) {
          for (const item of child) if (item && typeof item === "object" && "$" in item) visit(item as LTerm);
        } else if (child && typeof child === "object" && "$" in child) visit(child as LTerm);
      }
    }
    visit(term_lower(definition.v));
    references[name] = [...targets].sort();
    edges.set(name, references[name]!.filter(target => local.has(target)));
    for (const target of references[name]!) if (book.tlds[target] === undefined) unresolved.push({ caller: name, target });
  }
}
const index = new Map<string, number>(), low = new Map<string, number>();
const stack: string[] = [], active = new Set<string>(), components: string[][] = [];
function connect(name: string): void {
  index.set(name, index.size); low.set(name, index.get(name)!); stack.push(name); active.add(name);
  for (const target of edges.get(name)!) {
    if (!index.has(target)) { connect(target); low.set(name, Math.min(low.get(name)!, low.get(target)!)); }
    else if (active.has(target)) low.set(name, Math.min(low.get(name)!, index.get(target)!));
  }
  if (low.get(name) === index.get(name)) {
    const component: string[] = [];
    let current: string;
    do { current = stack.pop()!; active.delete(current); component.push(current); } while (current !== name);
    components.push(component.sort());
  }
}
for (const name of names) if (!index.has(name)) connect(name);
components.sort((a, b) => b.length - a.length || a[0]!.localeCompare(b[0]!));
const nonSingletonSCCs = components.filter(component => component.length > 1);
const selfRecursive = names.filter(name => edges.get(name)!.includes(name));
const result = {
  sourceCheckpoint: scorecard.sourceCheckpoint, sourceSha256: expected, generatedSha256,
  scorecardSha256: sha(scorecardBytes), generatedUnit: path,
  graphBasis: sourceAST
    ? "unchanged stage-0 source Body AST/raw HOAS Ref nodes; local references and all unresolved targets; before match compilation; NOT checker or lowered-AST evidence"
    : "stage-0 term_lower syntax Ref nodes; all references, not only application heads; imported targets excluded from local SCCs",
  definitions: names.length, definitionNames: names, rawASTReferences: references,
  unresolved, edges: Object.fromEntries(edges), components, nonSingletonSCCs, selfRecursive,
};
writeFileSync(path + (sourceAST ? ".source-ast-graph.json" : ".graph.json"), JSON.stringify(result, null, 2) + "\n");
console.log(JSON.stringify({ sourceSha256: expected, generatedSha256, definitions: names.length, unresolved: unresolved.length, nonSingletonSCCs, selfRecursive }));
if (unresolved.length || nonSingletonSCCs.length) process.exitCode = 1;
