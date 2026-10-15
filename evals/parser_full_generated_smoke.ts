#!/usr/bin/env bun
/** Actual public parser/lexer smoke. No restricted harness, and no stage-0 parity claim. */
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, book_valid } from "../bend2/bend.ts";
import { js_lib } from "../bend2/comp.ts";

const path = resolve(process.argv[2] ?? resolve(import.meta.dir, "../bend2/selfhost/parser_full_generated.bend"));
const scorecard = JSON.parse(readFileSync(path + ".scorecard.json", "utf8"));
const generatedSha256 = createHash("sha256").update(readFileSync(path)).digest("hex");
assert.equal(scorecard.sourceCheckpoint, "0d0e204f");
assert.equal(scorecard.sourceSha256, "0009070688f8fffffbb8664e72bd4662bf1324675ba097297076d77939153df5");
assert.equal(scorecard.generatedSha256, generatedSha256);
const parseFamily = scorecard.resultFamilies.indexOf("ParseResult");
assert.ok(parseFamily >= 0, "Scorecard must name the original ParseResult family");
const book = book_nil();
await book_load(book, path, "", new Map());
book_valid(book);
const library = js_lib(book,true,{roots:["parse"],exports:["parse"]});
// Library bytes are generated from the runtime candidate; no static module exists.
const compiled = await import("data:text/javascript;base64," + Buffer.from(library).toString("base64"));
// Shape is the actual js_lib Data export convention, also used by the real lexer runner.
type Data = {
  $: string; head: Data; tail: Data; module: Data; declarations: Data;
  definition: Data; binders: Data; body: Data; term: Data; fn: Data; arg: Data;
  span: Data; key: string; path: string; file: string; message: string; index: bigint;
  value: Data; result: Data;
};
function list(value: Data): Data[] {
  const result: Data[] = [];
  while (value.$ === "Con") { result.push(value.head); value = value.tail; }
  assert.equal(value.$, "Nil");
  return result;
}
function parse(file: string, source: string): Data {
  const run: Data = compiled.default.parse(file, source);
  assert.equal(run.$, "FeedbackComplete", "Public parser must complete, not exhaust its administrative budget");
  assert.equal(run.value.$, "Value_" + parseFamily, "Completed parser must return its typed ParseResult family");
  return run.value.result;
}
const fixtures = [
  { id: "typed_identity", source: "def identity(x: Type) -> Type:\n  x\n", key: "identity", check(term: Data) { assert.equal(term.$, "TermVar"); assert.equal(term.key, "x"); assert.equal(term.index, 0n); } },
  { id: "nested_application", source: "def nested(x: Type):\n  f(g(x))\n", key: "nested", check(term: Data) { assert.equal(term.$, "TermApp"); assert.equal(term.fn.$, "TermRef"); assert.equal(term.fn.key, "f"); assert.equal(term.arg.$, "TermApp"); assert.equal(term.arg.fn.key, "g"); assert.equal(term.arg.arg.$, "TermVar"); assert.equal(term.arg.arg.key, "x"); } },
  { id: "real_do", source: "def effect(x: Type):\n  do M<>: return x\n", key: "effect", check(term: Data) { assert.equal(term.$, "TermApp"); assert.equal(term.fn.$, "TermRef"); assert.equal(term.fn.key, "M.pure"); assert.equal(term.arg.$, "TermVar"); assert.equal(term.arg.key, "x"); } },
];
const observations: object[] = [];
for (const fixture of fixtures) {
  const file = fixture.id + ".bend";
  const result = parse(file, fixture.source);
  assert.equal(result.$, "ParseSuccess", fixture.id);
  assert.equal(result.module.$, "Module");
  assert.equal(result.module.path, file);
  const declarations = list(result.module.declarations);
  assert.equal(declarations.length, 1);
  assert.equal(declarations[0]!.$, "DefTop");
  const definition = declarations[0]!.definition;
  assert.equal(definition.key, fixture.key);
  assert.equal(list(definition.binders).length, 1);
  assert.equal(definition.body.$, "DefTerm");
  fixture.check(definition.body.term);
  observations.push({ id: fixture.id, file, source: fixture.source, result });
}
const malformedSource = "def broken():\n  )\n";
const malformed = parse("malformed.bend", malformedSource);
assert.equal(malformed.$, "ParseFailure");
assert.equal(malformed.message, "invalid or unsupported top-level syntax");
assert.equal(malformed.span.$, "SpanOf");
assert.equal(malformed.span.file, "malformed.bend");
observations.push({ id: "malformed", source: malformedSource, result: malformed });
const report = { sourceCheckpoint: scorecard.sourceCheckpoint, sourceSha256: scorecard.sourceSha256, generatedSha256, publicAPI: "parse(file, source)", lexer: "real Lexer.tokens + production combine_symbols", semanticParityClaimed: false, observations };
writeFileSync(path + ".smoke.json", JSON.stringify(report, (_, value) => typeof value === "bigint" ? value.toString() : value, 2) + "\n");
console.log(JSON.stringify({ generatedSha256, publicParserSmoke: "PASS", cases: observations.length }));
