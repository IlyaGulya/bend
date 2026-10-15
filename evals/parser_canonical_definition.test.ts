import { expect, test } from "bun:test";
import { resolve } from "node:path";
import * as B from "../bend2/bend.ts";
import { canonicalSourceBook } from "./parser_full_semantic_normalize.ts";

const book = await canonicalSourceBook(await Bun.file(resolve("bend2/selfhost/parser.bend")).text());
const file = "canonical-definition";
function closed(text: string): B.HTerm {
  const p: B.Parse = { book, dir: resolve("bend2/selfhost") + "/", str: text, pos: 0,
    sc: { stk: [], frs: 0 }, ns: "", al: { Ast: "ast", Lexer: "lexer" },
    os: [], inst: null, ts: [], lv: 0 };
  return B.term_higher(B.parse_term(p));
}
function ctor(term: B.HTerm, kind?: string): Extract<B.HTerm, { $: "Ctr" }> {
  const value = B.term_wnf(book, term);
  if (value.$ !== "Ctr") throw Error("Expected constructor, observed " + value.$);
  if (kind && value.k.split(".").at(-1) !== kind) throw Error("Expected " + kind + ", observed " + value.k);
  return value;
}
function nat(term: B.HTerm): number {
  let result = 0;
  for (;;) {
    const item = ctor(term);
    if (item.k === "Zero") return result;
    if (item.k !== "Succ") throw Error("Invalid Nat"); result++; term = item.x[0];
  }
}
function u32(term: B.HTerm): number {
  let word = ctor(term, "U32").x[0], value = 0, bit = 1;
  for (;;) {
    const item = ctor(word);
    if (item.k === "WNil") return value;
    if (item.k !== "WCon") throw Error("Invalid Word");
    if (ctor(item.x[0]).k === "True") value += bit;
    bit *= 2; word = item.x[1];
  }
}
function string(term: B.HTerm): string {
  let value = "";
  for (;;) {
    const item = ctor(term);
    if (item.k === "SNil") return value;
    if (item.k !== "SCon") throw Error("Invalid String");
    value += String.fromCodePoint(u32(ctor(item.x[0], "Chr").x[0])); term = item.x[1];
  }
}
function list(term: B.HTerm): B.HTerm[] {
  const result: B.HTerm[] = [];
  for (;;) {
    const item = ctor(term);
    if (item.k === "Nil") return result;
    if (item.k !== "Con") throw Error("Invalid List"); result.push(item.x[0]); term = item.x[1];
  }
}
function span(term: B.HTerm) {
  const item = ctor(term, "SpanOf");
  return { file: string(item.x[0]), beg: nat(item.x[1]), end: nat(item.x[2]) };
}
function parse(source: string) {
  return ctor(B.App(B.App(B.Ref("parse"), closed(JSON.stringify(file))), closed(JSON.stringify(source))));
}
function definition(source: string, name: string) {
  const module = ctor(ctor(parse(source), "ParseSuccess").x[0], "Module");
  expect(string(module.x[0])).toBe(file);
  expect(list(module.x[1])).toHaveLength(0);
  const tops = list(module.x[2]); expect(tops).toHaveLength(1);
  const item = ctor(ctor(tops[0], "DefTop").x[0], "Definition");
  expect(string(item.x[0])).toBe(name);
  const result = ctor(ctor(item.x[2], "SomeTerm").x[0], "TermRef");
  expect(string(result.x[0])).toBe("Nat");
  ctor(item.x[4], "False");
  expect(span(item.x[5]).file).toBe(file);
  expect(span(item.x[5]).beg).toBe(source.indexOf("def"));
  return { binders: list(item.x[1]), body: ctor(ctor(item.x[3], "DefTerm").x[0], "BodyReply").x[0] };
}
function syntaxNat(term: B.HTerm): number {
  const item = ctor(term, "TermCtr"), key = string(item.x[0]), args = list(item.x[1]);
  if (key === "Zero") { expect(args).toHaveLength(0); return 0; }
  expect(key).toBe("Succ"); expect(args).toHaveLength(1);
  return 1 + syntaxNat(args[0]);
}

for (const prefix of ["", "\n\n"]) {
  test(`canonical constant definition preserves keyword span (${prefix.length} leading newlines)`, () => {
    const item = definition(prefix + "def value() -> Nat:\n  3n\n", "value");
    expect(item.binders).toHaveLength(0);
    expect(syntaxNat(item.body)).toBe(3);
  });
  test(`canonical typed definition resolves its binder (${prefix.length} leading newlines)`, () => {
    const item = definition(prefix + "def id(x: Nat) -> Nat:\n  x\n", "id");
    expect(item.binders).toHaveLength(1);
    const binder = ctor(item.binders[0], "Binder");
    ctor(binder.x[0], "QOne"); expect(string(binder.x[1])).toBe("x");
    expect(nat(binder.x[2])).toBe(0);
    expect(string(ctor(binder.x[3], "TermRef").x[0])).toBe("Nat");
    const body = ctor(item.body, "TermVar");
    expect(string(body.x[0])).toBe("x"); expect(nat(body.x[1])).toBe(0);
  });
  test(`canonical malformed definition retains failure remainder (${prefix.length} leading newlines)`, () => {
    const source = prefix + "def broken(\n";
    const failure = ctor(parse(source), "ParseFailure");
    // Binder scanning skips the newline to discover EOF but returns the
    // original suffix on failure. The diagnostic must therefore point here.
    expect(string(failure.x[2])).toBe("\n");
    expect(span(failure.x[3])).toEqual({ file, beg: source.length - 1, end: source.length });
  });
}

const pendingLaw = "law same:\n  for x: Nat\n  Nat\n";
const lawFill = "def same(x):\n  x\n";
for (const [name, source, accepted] of [
  ["unowned colon definition", "def same(x: Nat):\n  x\n", false],
  ["pending law fill", pendingLaw + lawFill, true],
  ["typed law binder", pendingLaw + "def same(x: Nat):\n  x\n", false],
  ["erased Quant law binder", "law same:\n  for -x: Quant\n  Quant\ndef same(-x: Quant):\n  x\n", false],
  ["arrow after pending law", pendingLaw + "def same(x) -> Nat:\n  x\n", false],
  ["second law fill", pendingLaw + lawFill + lawFill, false],
  ["fresh bare binder with arrow", "def same(x) -> Nat:\n  x\n", true],
  ["fresh typed binder with arrow", "def same(x: Nat) -> Nat:\n  x\n", true],
  ["duplicate law", pendingLaw + pendingLaw, false],
] as const) {
  test(`canonical declaration ownership: ${name}`, () => {
    expect(parse(source).k).toBe(accepted ? "ParseSuccess" : "ParseFailure");
  });
}
