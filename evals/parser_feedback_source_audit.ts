#!/usr/bin/env bun
/** Audit the real shortest do-expression cycle in the repaired parser AST.
 *
 * bun evals/parser_feedback_source_audit.ts
 *
 * This is an AST audit, not a generated parser or a proof of semantic parity.
 */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, term_lower, term_unapply, type LTerm } from "../bend2/bend.ts";

const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");
const expected = "adfc9b40e7af3eb06e731a4276dcafd6b3f356ed6a042616d5fa1674db57a4b7";
const source = readFileSync(input, "utf8");
const actual = createHash("sha256").update(source).digest("hex");
if (actual !== expected) {
  throw Error(`Expected repaired checkpoint 89d5cdb7 parser SHA-256 ${expected}; found ${actual}. Refusing a changed canonical input.`);
}

const cycle = [
  "parse_do_return", "parse_do_return_scan", "parse_term", "parse_atom",
  "parse_atom_scan", "parse_do_atom", "parse_do_atom_args_result",
  "parse_do_atom_colon", "parse_do_return",
];
const members = new Set(cycle);
const book = book_nil();
await book_load(book, input, "", new Map());
const lines = source.split("\n");
function lineAt(text: string, offset: number): number {
  // book_load removes import lines while preserving newlines. Offsets refer
  // to the parsed source, not the original byte stream.
  let line = 1;
  for (let i = 0; i < offset; i++) if (text.charCodeAt(i) === 10) line++;
  return line;
}

type Call = { caller: string; callee: string; line: number; position: number; parent?: string };
const calls: Call[] = [];
const unresolved: Call[] = [];
// term_lower replays higher-order match branches for multiple constructors.
// One source span is one lexical callsite regardless of lowered duplication.
const siteKeys = new Set<string>();
const allDefs = new Set([...source.matchAll(/^def ([A-Za-z_]\w*)\(/gm)].map((match) => match[1]!));
const efqMatches = new Map<string, { caller: string; line: number }>();
function visit(node: LTerm, caller: string, parent?: string): void {
  if (node.$ === "App") {
    const [head, args] = term_unapply(node);
    if (head.$ === "Ref") {
      const position = head.s?.beg;
      if (position === undefined) throw Error(`No source span for ${caller} -> ${head.k}`);
      const key = `${caller}\0${head.k}\0${position}\0${parent ?? ""}`;
      if (!siteKeys.has(key)) {
        siteKeys.add(key);
        const site = { caller, callee: head.k, line: lineAt(head.s!.src, position), position, parent };
        if (allDefs.has(head.k)) calls.push(site);
        else if (book.tlds[head.k] === undefined) unresolved.push(site);
      }
    }
    visit(head, caller, parent);
    const owner = head.$ === "Ref" && allDefs.has(head.k) ? head.k : parent;
    for (const arg of args) visit(arg, caller, owner);
    return;
  }
  switch (node.$) {
    case "Efq":
      if (node.s) {
        const line = lineAt(node.s.src, node.s.beg);
        efqMatches.set(`${caller}:${line}`, { caller, line });
      }
      break;
    case "Lam": visit(node.f, caller); break;
    case "All": visit(node.A, caller, parent); visit(node.B, caller, parent); break;
    case "Let":
      node.v.forEach((item) => visit(item, caller, parent));
      visit(node.f, caller, parent);
      break;
    case "Sub": visit(node.v as LTerm, caller, parent); visit(node.f, caller, parent); break;
    case "Mat": visit(node.h, caller, parent); visit(node.m, caller, parent); break;
    case "ADT": case "Ctr": node.x.forEach((item) => visit(item, caller, parent)); break;
    case "Typ": visit(node.g, caller, parent); break;
    case "Min": visit(node.a, caller, parent); visit(node.b, caller, parent); break;
    case "Eql": visit(node.a, caller, parent); visit(node.b, caller, parent); visit(node.T, caller, parent); break;
    case "Rwt": visit(node.e, caller, parent); visit(node.p, caller, parent); visit(node.f, caller, parent); break;
    case "Ann": visit(node.x, caller, parent); visit(node.T, caller, parent); break;
  }
}
for (const name of members) {
  const definition = book.tlds[name];
  if (definition?.$ !== "Def" || definition.v === null) throw Error(`Missing real definition ${name}`);
  visit(term_lower(definition.v), name);
}
for (let i = 0; i < cycle.length - 1; i++) {
  if (!calls.some((site) => site.caller === cycle[i] && site.callee === cycle[i + 1])) {
    throw Error(`Actual AST does not contain the documented cycle edge ${cycle[i]} -> ${cycle[i + 1]}`);
  }
}
if (unresolved.length !== 0) {
  throw Error("Unresolved callees in selected slice: " +
    unresolved.map(({ caller, callee, line }) => `${caller}:${line} -> ${callee}`).join("; "));
}

// Bounded source audit: all match bodies in the eight selected definitions.
// Explicit wildcards cover their residual domain. The only no-wildcard shape
// accepted here is the complete Nil/Con list split; new shapes require review.
const partialMatchAudit: { caller: string; line: number; scrutinee: string; patterns: string[]; classification: string }[] = [];
for (const caller of members) {
  const start = lines.findIndex(line => line.startsWith(`def ${caller}(`));
  let end = start + 1;
  while (end < lines.length && !/^(?:def|type|law) /.test(lines[end]!)) end++;
  for (let index = start + 1; index < end; index++) {
    const match = /^(\s*)match (.+):$/.exec(lines[index]!);
    if (!match) continue;
    const indentation = match[1]!.length;
    const patterns: string[] = [];
    for (let row = index + 1; row < end; row++) {
      const line = lines[row]!;
      const indent = line.length - line.trimStart().length;
      if (line.trim() && indent <= indentation) break;
      if (indent === indentation + 2 && line.trimStart().startsWith("case ")) {
        patterns.push(line.trim().slice(5, -1));
      }
    }
    const wildcard = patterns.includes("_");
    const listSplit = patterns.some(pattern => /^Nil\{\}$/.test(pattern)) &&
      patterns.some(pattern => /^[+]?[A-Za-z_]\w*\s*<>\s*[+]?[A-Za-z_]\w*$/.test(pattern));
    partialMatchAudit.push({
      caller, line: index + 1, scrutinee: match[2]!, patterns,
      classification: wildcard ? "exhaustive-explicit-default" : listSplit ? "exhaustive-Nil-Con" : "requires-source-review",
    });
  }
}
const unreviewed = partialMatchAudit.filter(match => match.classification === "requires-source-review");
const residues = [...efqMatches.values()].map(residue => {
  const match = partialMatchAudit.find(match => match.caller === residue.caller && match.line === residue.line);
  return { ...residue, classification: match ? "intentionally-empty-residual-of-exhaustive-match" : "requires-source-review" };
});
const partialAudit = {
  checkpoint: "89d5cdb7", sourceSha256: actual, selectedDefinitions: [...members],
  matches: partialMatchAudit, efqResidueSourceLocations: residues,
  liveSyntacticallyNonExhaustiveMatches: unreviewed,
  unclassifiedEfqLocations: residues.filter(residue => residue.classification === "requires-source-review"),
  baselineSemanticRepairs: ["missing SymbolToken default corresponding to stage-0 parse_term_base default"],
};
writeFileSync(input + ".partial-match-audit.json", JSON.stringify(partialAudit, null, 2));
if (unreviewed.length || partialAudit.unclassifiedEfqLocations.length) {
  throw Error("Selected source has match shapes requiring review: " + JSON.stringify(partialAudit));
}
const nested = calls.filter((site) =>
  site.parent !== undefined && site.callee.startsWith("parse_"))
  .sort((a, b) => a.position - b.position)
  .map(({ caller, callee, parent, line }) => ({
    caller, callee, parent, line, source: lines[line - 1]?.trim() ?? "",
  }));
const cycleEdges = cycle.slice(0, -1).map((caller, i) => ({
  caller, callee: cycle[i + 1],
  lines: [...new Set(calls.filter((call) =>
    call.caller === caller && call.callee === cycle[i + 1]).map((call) => call.line))],
}));
console.log(JSON.stringify({
  sourceSha256: actual, cycleEdges, nested, partialMatchAudit: partialAudit,
  unresolved: unresolved.map(({ caller, callee, line }) => ({ caller, callee, line })),
  outbound: calls.filter((call) => !members.has(call.callee))
    .map(({ caller, callee, line }) => ({ caller, callee, line })),
}, null, 2));
