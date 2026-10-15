#!/usr/bin/env bun
/** Audits the generated restricted unit, never the whole production closure. */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, term_force, term_unapply, Var, type HTerm } from "../bend2/bend.ts";
const path = resolve(import.meta.dir, "../bend2/selfhost/parser_feedback_generated.bend");
const source = readFileSync(path, "utf8");
const expected = "adfc9b40e7af3eb06e731a4276dcafd6b3f356ed6a042616d5fa1674db57a4b7";
const scorecard = JSON.parse(readFileSync(path + ".scorecard.json", "utf8"));
if (createHash("sha256").update(readFileSync(resolve(import.meta.dir, "../bend2/selfhost/parser.bend"))).digest("hex") !== expected ||
  scorecard.sourceSha256 !== expected) throw Error("Generated audit differs from baseline checkpoint 89d5cdb7");
if (createHash("sha256").update(source).digest("hex") !== scorecard.generatedSha256) {
  throw Error("Generated Bend differs from recorded emission");
}
const names = new Set([...source.matchAll(/^def ([A-Za-z_]\w*)\(/gm)].map(match => match[1]!));
const book = book_nil();
await book_load(book, path, "", new Map());
const edges = new Map<string, Set<string>>();
for (const name of names) {
  const definition = book.tlds[name];
  if (definition?.$ !== "Def" || definition.v === null) throw Error("Missing emitted AST: " + name);
  const targets = new Set<string>();
  const seen = new WeakSet<object>();
  function visit(input: HTerm, depth = 0): void {
    const term = term_force(input);
    if (seen.has(term)) return;
    seen.add(term);
    if (term.$ === "Ref" && names.has(term.k)) targets.add(term.k);
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
    // This is an AST graph audit, independent of typecheck success. Force only
    // syntax children; source locations and reductions are not call edges.
    for (const [key, child] of Object.entries(term)) {
      if (key === "s") continue;
      if (Array.isArray(child)) {
        for (const item of child) if (item && typeof item === "object" && "$" in item) visit(item as HTerm, depth);
      } else if (child && typeof child === "object" && "$" in child) visit(child as HTerm, depth);
    }
  }
  visit(definition.v);
  edges.set(name, targets);
}
const index = new Map<string, number>(), low = new Map<string, number>();
const stack: string[] = [], active = new Set<string>(), components: string[][] = [];
function connect(name: string): void {
  index.set(name, index.size); low.set(name, index.get(name)!); stack.push(name); active.add(name);
  for (const target of edges.get(name) ?? []) {
    if (!index.has(target)) { connect(target); low.set(name, Math.min(low.get(name)!, low.get(target)!)); }
    else if (active.has(target)) low.set(name, Math.min(low.get(name)!, index.get(target)!));
  }
  if (low.get(name) === index.get(name)) {
    const component: string[] = [];
    let current: string;
    do { current = stack.pop()!; active.delete(current); component.push(current); } while (current !== name);
    components.push(component);
  }
}
for (const name of names) if (!index.has(name)) connect(name);
const mutual = components.filter(component => component.length > 1);
const selected = [...names].filter(name => name.startsWith("step_parse_"));
const result = { generatedUnit: path, definitions: names.size, selectedSteps: selected, mutualSCCs: mutual, selfRecursive: [...names].filter(name => edges.get(name)?.has(name)), edges: Object.fromEntries([...edges].map(([name, targets]) => [name, [...targets]])) };
writeFileSync(path + ".graph.json", JSON.stringify(result, null, 2));
console.log(JSON.stringify({ definitions: names.size, selectedSteps: selected.length, mutualSCCs: mutual, selfRecursive: result.selfRecursive }));
if (mutual.length) process.exitCode = 1;
