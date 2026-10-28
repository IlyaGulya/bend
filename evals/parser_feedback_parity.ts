#!/usr/bin/env bun
/** Restricted differential runner. Stage-0 is bend2/bend.ts, not parser.bend.
 * PF1 rows contain JSON AST, preorder spans, and complete remaining Lexer.Token
 * arrays. Strings inside those values are Unicode scalar arrays, so printing
 * does not depend on either compiler's string-literal pretty printer.
 * --reference collects observations; --emit-fixture writes the executable main
 * include; --run <binary> executes and compares. Only --run can establish parity.
 */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { spawnSync } from "node:child_process";
import * as Stage0 from "../bend2/bend.ts";
import { js_lib } from "../bend2/comp.ts";

const parserPath = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");
const parserSha256 = "adfc9b40e7af3eb06e731a4276dcafd6b3f356ed6a042616d5fa1674db57a4b7";
const fixturePath = resolve(import.meta.dir, "../bend2/selfhost/parser_feedback_scenarios.bend.inc");
const scopeKeys = ["x", "T", "op", "action", "action2", "f", "g", "Unit"];
export const scenarios = [
  { id: "simple_return_header", source: "do M: return x" },
  { id: "action_then_return", source: "do M<>: action; return x" },
  { id: "untyped_bind_then_return", source: "do M<>: T <- op; return x" },
  { id: "typed_bind", source: "do M<>: x: T <- op; return x" },
  { id: "two_operations", source: "do M<>: action; action2; return x" },
  { id: "nested_expression", source: "do M<>: return f(g(x))" },
  { id: "malformed_body", source: "do M<>: return" },
  { id: "success_remainder", source: "do M<>: return x ) tail" },
  { id: "failure_remainder", source: "do M<>: x: T <- ) tail" },
] as const;

type Json = null | boolean | number | string | Json[];
type Span = [number[], number, number];
type Token = { $: "TokenInfo"; kind: { $: string }; text: string; beg: bigint; end: bigint; line: bigint; col: bigint };
type List<T> = { $: "Nil" } | { $: "Con"; head: T; tail: List<T> };
type Observation = { id: string; source: string; ok: boolean; ast: Json; spans: Span[]; remainder: Json[]; offset: number; rawRemainder: string; diagnostic?: { expected: string; observed: string } };
const codes = (s: string): number[] => Array.from(s, c => c.codePointAt(0)!);
const quantity = (q: Stage0.Quant): number => q.$ === "None" ? 0 : q.$ === "Lone" ? 1 : 2;
function normalize(term: Stage0.LTerm, file: string, spans: Span[]): Json {
  if (term.s) spans.push([codes(file), term.s.beg, term.s.end]);
  const child = (t: Stage0.LTerm) => normalize(t, file, spans);
  switch (term.$) {
    case "Var": return ["Var", codes(term.k), term.i];
    case "Ref": return ["Ref", codes(term.k)];
    case "App": return ["App", child(term.f), child(term.x)];
    case "Lam": return ["Lam", term.q ? quantity(term.q) : null, codes(term.k), term.i, child(term.f)];
    case "Ann": return ["Ann", child(term.x), child(term.T)];
    case "Typ": return ["Typ", child(term.g)];
    case "Qua": return ["Qua", quantity(term.q)];
    case "Qnt": return ["Qnt"];
    case "Hol": return ["Hol", codes(term.k)];
    case "Ctr": return ["Ctr", codes(term.k), term.x.map(child)];
    case "ADT": return ["ADT", codes(term.k), term.x.map(child), term.r.map(codes)];
    case "Let": return ["Let", term.k.map(codes), term.i, term.q.map(quantity), term.v.map(child), child(term.f)];
    default: throw Error("Scenario escaped restricted normalization: " + term.$);
  }
}
function flatten<T>(list: List<T>): T[] {
  const result: T[] = [];
  while (list.$ === "Con") { result.push(list.head); list = list.tail; }
  if (list.$ !== "Nil") throw Error("Unexpected real lexer list representation");
  return result;
}
async function lexer(): Promise<(source: string) => Token[]> {
  const book = Stage0.book_nil();
  await Stage0.book_load(book, resolve(import.meta.dir, "../bend2/selfhost/lexer.bend"), "", new Map());
  Stage0.book_valid(book);
  // This is the same public JS-library export path used by the stage-0 module
  // loader. Only Lexer.tokens is a root; production parser closure is absent.
  const source = js_lib(book, true, {roots: ["tokens"], exports: ["tokens"]});
  // The module bytes come from the current lexer book, not an author-time
  // module path; static import cannot load this runtime-generated library.
  const module = await import("data:text/javascript;base64," + Buffer.from(source).toString("base64"));
  return text => {
    const tokens = flatten<Token>(module.default.tokens(text));
    const normalized: Token[] = [];
    for (let index = 0; index < tokens.length; index++) {
      const token = tokens[index]!;
      const next = tokens[index + 1];
      // Mirror harness_tokens: grammar-level contiguous bind punctuation only.
      // In particular, '<' '>' must remain separate for selected do_atom.
      if (token.kind.$ === "SymbolToken" && token.text === "<" &&
          next?.kind.$ === "SymbolToken" && next.text === "-" && token.end === next.beg) {
        normalized.push({ ...token, text: "<-", end: next.end });
        index++;
      } else {
        normalized.push(token);
      }
    }
    return normalized;
  };
}
export async function collectReference(): Promise<Observation[]> {
  if (createHash("sha256").update(readFileSync(parserPath)).digest("hex") !== parserSha256) {
    throw Error("Canonical parser differs from checkpoint 89d5cdb7");
  }
  const tokenize = await lexer();
  return scenarios.map(({ id, source }) => {
    const file = id + ".bend";
    const parser: Stage0.Parse = {
      book: Stage0.book_nil(), dir: "", str: source, pos: 0,
      sc: { stk: scopeKeys.map((key, index) => [key, index]), frs: scopeKeys.length },
      ns: "", al: Object.create(null), os: [], inst: null, ts: [], lv: 0,
    };
    const spans: Span[] = [];
    let ast: Json = null, ok = false;
    let diagnostic: Observation["diagnostic"];
    try { ast = normalize(Stage0.parse_term(parser), file, spans); ok = true; }
    catch (error) {
      if ((error as Stage0.Err)?.$ !== "Err") throw error;
      const err = error as Stage0.Err;
      if (err.spn) spans.push([codes(file), err.spn.beg, err.spn.end]);
      diagnostic = { expected: String(err.exp), observed: String(err.obs) };
    }
    // Stage-0 stops in character space. Keep all real tokens beginning at or
    // after that exact position; record the cursor too, never silently skip it.
    const remaining = tokenize(source).filter(token => Number(token.beg) >= parser.pos);
    return { id, source, ok, ast, spans, remainder: remaining.map(t => [t.kind.$, codes(t.text), Number(t.beg), Number(t.end), Number(t.line), Number(t.col)]),
      offset: parser.pos, rawRemainder: source.slice(parser.pos), ...(diagnostic ? { diagnostic } : {}) };
  });
}

const printers = String.raw`
# PF1 canonical values encode strings as arrays of Unicode scalar numbers.
def parity_codes_tail(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{head, tail}:
      String.concat([",", U32.show(Char.to_u32(head)), parity_codes_tail(tail)])
def parity_codes(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{head, tail}:
      String.concat([U32.show(Char.to_u32(head)), parity_codes_tail(tail)])
def parity_string(s: String) -> String:
  String.concat(["[", parity_codes(s), "]"])
def parity_span(span: Ast.SourceSpan) -> String:
  match span:
    case Ast.SpanOf{file, beg, end}:
      String.concat(["[", parity_string(file), ",", Nat.show(beg), ",", Nat.show(end), "]"])
def parity_quantity(q: Ast.Quantity) -> String:
  match q:
    case Ast.QZero{}: "0"
    case Ast.QOne{}: "1"
    case Ast.QMany{}: "2"
def parity_optional_quantity(q: Maybe<&2, Ast.Quantity>) -> String:
  match q:
    case None{}: "null"
    case Some{value}: parity_quantity(value)
def parity_ast(term: Ast.SyntaxTerm) -> String:
  match term:
    case Ast.TermVar{key, index, _}:
      String.concat(["[\"Var\",", parity_string(key), ",", Nat.show(index), "]"])
    case Ast.TermRef{key, _}: String.concat(["[\"Ref\",", parity_string(key), "]"])
    case Ast.TermApp{fn, arg, _}:
      String.concat(["[\"App\",", parity_ast(fn), ",", parity_ast(arg), "]"])
    case Ast.TermLam{q, key, index, body, _}:
      String.concat(["[\"Lam\",", parity_optional_quantity(q), ",", parity_string(key), ",", Nat.show(index), ",", parity_ast(body), "]"])
    case Ast.TermAnn{term, ty, _}:
      String.concat(["[\"Ann\",", parity_ast(term), ",", parity_ast(ty), "]"])
    case Ast.TermType{kind, _}: String.concat(["[\"Typ\",", parity_ast(kind), "]"])
    case Ast.TermQuantity{q, _}: String.concat(["[\"Qua\",", parity_quantity(q), "]"])
    case Ast.TermQuant{}: "[\"Qnt\"]"
    case Ast.TermHole{key, _}: String.concat(["[\"Hol\",", parity_string(key), "]"])
    case _: "[\"UNSUPPORTED_AST\"]"
def parity_spans(term: Ast.SyntaxTerm) -> List<&2, String>:
  match term:
    case Ast.TermVar{_, _, span}: [parity_span(span)]
    case Ast.TermRef{_, span}: [parity_span(span)]
    case Ast.TermApp{fn, arg, span}:
      parity_span(span) <> List.append(&2, String, parity_spans(fn), parity_spans(arg))
    case Ast.TermLam{_, _, _, body, span}: parity_span(span) <> parity_spans(body)
    case Ast.TermAnn{term, ty, span}:
      parity_span(span) <> List.append(&2, String, parity_spans(term), parity_spans(ty))
    case Ast.TermType{kind, span}: parity_span(span) <> parity_spans(kind)
    case Ast.TermQuantity{_, span}: [parity_span(span)]
    case Ast.TermHole{_, span}: [parity_span(span)]
    case _: Nil{}
def parity_kind(kind: Lexer.TokenKind) -> String:
  match kind:
    case Lexer.NameToken{}: "NameToken"
    case Lexer.NumberToken{}: "NumberToken"
    case Lexer.StringToken{}: "StringToken"
    case Lexer.CharToken{}: "CharToken"
    case Lexer.SymbolToken{}: "SymbolToken"
    case Lexer.NewlineToken{}: "NewlineToken"
    case Lexer.EndToken{}: "EndToken"
    case Lexer.ErrorToken{}: "ErrorToken"
def parity_token(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{kind, text, beg, end, line, col}:
      String.concat(["[\"", parity_kind(kind), "\",", parity_string(text), ",", Nat.show(beg), ",", Nat.show(end), ",", Nat.show(line), ",", Nat.show(col), "]"])
def parity_tokens(tokens: List<&2, Lexer.Token>) -> List<&2, String>:
  match tokens:
    case Nil{}: Nil{}
    case head <> tail: parity_token(head) <> parity_tokens(tail)
def parity_row(id: String, result: FeedbackRun) -> IO(Unit):
  match result:
    case FeedbackComplete{+term, rest, +ok}:
      IO.print(String.concat(["PF1\t", id, "\t", Bool.pick(String, ok, "1", "0"), "\t", Bool.pick(String, ok, parity_ast(term), "null"), "\t[", String.join(parity_spans(term), ","), "]\t[", String.join(parity_tokens(rest), ","), "]"]))
    case FeedbackInvariantFailure{}:
      IO.print(String.append("PFINVARIANT\t", id))
`;
export function fixture(): string {
  const scope = "[" + scopeKeys.map((key, i) => `Scope{${JSON.stringify(key)}, ${i}n}`).join(", ") + "]";
  let body = "IO.pure(Unit, Unit{})";
  for (const { id, source } of [...scenarios].reverse()) {
    const call = `parity_row(${JSON.stringify(id)}, feedback_entry_parse_term(${JSON.stringify(id + ".bend")}, harness_tokens(${JSON.stringify(source)}), ${scope}, ${scopeKeys.length}n, 0n))`;
    body = `IO.bind(Unit, Unit, ${call}, _ => ${body})`;
  }
  return printers + "\ndef main() -> IO(Unit):\n  " + body + "\n";
}
function compare(reference: Observation[], stdout: string): { id: string; mismatches: string[] }[] {
  const rows = new Map<string, { ok: boolean; ast: Json; spans: Json; remainder: Json }>();
  for (const line of stdout.split(/\r?\n/)) {
    if (line.startsWith("PFINVARIANT\t")) throw Error("Generated driver invariant failure: " + line.slice(12));
    if (!line.startsWith("PF1\t")) continue;
    const parts = line.split("\t");
    if (parts.length !== 6 || !["0", "1"].includes(parts[2]!)) throw Error("Invalid PF1 row: " + line);
    const [, id, ok, ast, spans, remainder] = parts;
    if (rows.has(id!)) throw Error("Duplicate PF1 scenario " + id);
    rows.set(id!, { ok: ok === "1", ast: JSON.parse(ast!), spans: JSON.parse(spans!), remainder: JSON.parse(remainder!) });
  }
  const ids = new Set(reference.map(row => row.id));
  for (const id of rows.keys()) if (!ids.has(id)) throw Error("Unknown PF1 scenario " + id);
  return reference.map(expected => {
    const actual = rows.get(expected.id);
    if (!actual) return { id: expected.id, mismatches: ["missing executable observation"] };
    const mismatches: string[] = [];
    const first = Array.isArray(actual.remainder) ? actual.remainder[0] : null;
    const offset = Array.isArray(first) && typeof first[2] === "number" ? first[2] : expected.source.length;
    if (offset !== expected.offset || expected.source.slice(offset) !== expected.rawRemainder) {
      mismatches.push(`cursor/remainder: expected offset ${expected.offset} ${JSON.stringify(expected.rawRemainder)}, got offset ${offset} ${JSON.stringify(expected.source.slice(offset))}`);
    }
    for (const key of ["ok", "ast", "spans", "remainder"] as const) {
      if (JSON.stringify(expected[key]) !== JSON.stringify(actual[key])) {
        mismatches.push(`${key}: expected ${JSON.stringify(expected[key])}, got ${JSON.stringify(actual[key])}`);
      }
    }
    return { id: expected.id, mismatches };
  });
}
if (import.meta.main) {
  const args = process.argv.slice(2);
  if (args.length === 0 || (args.length === 1 && args[0] === "--reference")) {
    console.log(JSON.stringify({ parserSha256, reference: "bend2/bend.ts parse_term", parityExecuted: false, scenarios: await collectReference() }, null, 2));
  } else if (args.length === 1 && args[0] === "--emit-fixture") {
    writeFileSync(fixturePath, fixture());
    console.log(JSON.stringify({ fixturePath, scenarios: scenarios.length, parityExecuted: false }));
  } else if (args.length === 2 && args[0] === "--run") {
    const reference = await collectReference();
    const executable = resolve(args[1]!);
    const javascript = executable.endsWith(".js") || executable.endsWith(".mjs");
    const run = spawnSync(javascript ? process.execPath : executable, javascript ? [executable] : [], {
      encoding: "utf8", timeout: 120_000, maxBuffer: 16 * 1024 * 1024,
    });
    if (run.error) throw run.error;
    if (run.status !== 0) throw Error(`Generated executable exited ${run.status}: ${run.stderr}`);
    const results = compare(reference, run.stdout);
    const parity = results.every(result => result.mismatches.length === 0);
    console.log(JSON.stringify({ parserSha256, parityExecuted: true, parity, results }, null, 2));
    if (!parity) process.exitCode = 1;
  } else {
    throw Error("Usage: bun evals/parser_feedback_parity.ts [--reference | --emit-fixture | --run <executable>]");
  }
}
