import * as B from "../bend2/bend.ts";
import { createHash } from "node:crypto";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { sourceOracle } from "./bootstrap_source_oracle.ts";
import { canonicalCore, canonicalSourceBook, normalizeCoreBook, normalizeImports,
  type Node, type Value } from "./parser_full_semantic_normalize.ts";
import { guardHeavyGate } from "./heavy_gate.ts";

// Diagnostic only: no checker, generated parser, host tokenizer or semantic
// exclusions. Run under heavy_gate.ts; --case=name1,name2 limits the work.
// --report=path writes full native/canonical normalized semantics on each row.
// Ordinary expression Empty<> is deliberately a REJECTION control: stage0
// supports empty angles in type headers and do syntax, not empty ADT terms.
type Fixture = { name: string; source: string; stage0Expected: boolean;
  expression?: string; scope?: string[] };
const locals = ["sign", "marker", "rev"];
function cons(name: string, expression: string, scope = locals): Fixture {
  return { name, expression, scope, stage0Expected: true,
    source: `import Base\ndef value(sign: Char, marker: Char, rev: List<&2, Char>) -> List<&2, Char>:\n  ${expression}\n` };
}
export const consExpressionFixtures: Fixture[] = [
  cons("spaced-parenthesized-cons", "sign <> (marker <> rev)"),
  { name: "lexer-dot-cons", stage0Expected: true,
    source: "import Base\ndef value(d: Char, dot: Char, rev: List<&2, Char>) -> List<&2, Char>:\n  d <> (dot <> rev)\n",
    expression: "d <> (dot <> rev)", scope: ["d", "dot", "rev"] },
  { name: "lexer-nested-sign-cons", stage0Expected: true,
    source: "import Base\ndef value(d: Char, sign: Char, marker: Char, rev: List<&2, Char>) -> List<&2, Char>:\n  d <> (sign <> (marker <> rev))\n",
    expression: "d <> (sign <> (marker <> rev))", scope: ["d", "sign", "marker", "rev"] },
  cons("spaced-list-cons", "sign <> [marker]"),
  cons("right-associated-cons", "sign <> marker <> rev"),
  cons("adjacent-parenthesized-cons", "sign<>(marker <> rev)"),
  cons("shadowed-name-cons", "sign => sign <> (marker <> rev)"),
  cons("qualified-reference-cons", "Char.from_u32 <> (marker <> rev)"),
  { name: "nonempty-datatype-arguments", stage0Expected: true,
    source: "import Base\ntype Box<A: Data> is Data:\n  Boxed{value: A}\ndef family() -> Data:\n  Box<Char>\n", expression: "Box<Char>", scope: [] },
  { name: "adjacent-empty-type-header", stage0Expected: true,
    source: "import Base\ntype ConsDiagnosticEmpty<> is Data:\n  ConsDiagnosticEmptyValue{}\n" },
  { name: "adjacent-empty-do-arguments", stage0Expected: true,
    source: "import Base\ndef effect(x: Nat) -> Nat:\n  do M<>: return x\n",
    expression: "do M<>: return x", scope: ["x"] },
  { name: "ordinary-empty-datatype-rejected", stage0Expected: false,
    source: "import Base\ntype ConsDiagnosticEmpty<> is Data:\n  ConsDiagnosticEmptyValue{}\ndef family() -> Data:\n  ConsDiagnosticEmpty<>\n",
    expression: "ConsDiagnosticEmpty<>", scope: [] },
];

const apply = (key: string, args: B.HTerm[]) => args.reduce((f, x) => B.App(f, x), B.Ref(key));
const natTerm = (n: number): B.HTerm => B.term_higher(B.nat_to_term(n));
function stringTerm(value: string): B.HTerm {
  let tail: B.HTerm = B.Ctr("SNil", []);
  const points = Array.from(value);
  for (let i = points.length - 1; i >= 0; i--) {
    tail = B.Ctr("SCon", [B.Ctr("Chr", [B.term_higher(B.u32_to_term(points[i].codePointAt(0)!))]), tail]);
  }
  return tail;
}
const listTerm = (items: B.HTerm[]) => items.reduceRight<B.HTerm>((tail, head) => B.Ctr("Con", [head, tail]), B.Ctr("Nil", []));

function observers(book: B.Book) {
  function ctor(term: B.HTerm): Extract<B.HTerm, { $: "Ctr" }> {
    const value = B.term_wnf(book, term);
    if (value.$ !== "Ctr") throw Error("Expected runtime constructor, observed " + value.$);
    return value;
  }
  function nat(term: B.HTerm): number {
    let n = 0;
    for (;;) {
      const value = ctor(term);
      if (value.k === "Zero" && value.x.length === 0) return n;
      if (value.k !== "Succ" || value.x.length !== 1) throw Error("Invalid runtime Nat");
      n++; term = value.x[0];
    }
  }
  function data(term: B.HTerm): B.LTerm {
    const value = ctor(term);
    return B.Ctr(value.k, value.x.map(data));
  }
  function text(term: B.HTerm): string {
    let result = "";
    for (;;) {
      const value = ctor(term);
      if (value.k === "SNil" && value.x.length === 0) return result;
      if (value.k !== "SCon" || value.x.length !== 2) throw Error("Invalid runtime String");
      const char = ctor(value.x[0]);
      if (char.k !== "Chr") throw Error("Invalid runtime Char");
      const code = B.u32_from_term(data(char.x[0]));
      if (code === null) throw Error("Invalid character Word");
      result += String.fromCodePoint(code); term = value.x[1];
    }
  }
  function list(term: B.HTerm): B.HTerm[] {
    const items: B.HTerm[] = [];
    for (;;) {
      const value = ctor(term);
      if (value.k === "Nil" && value.x.length === 0) return items;
      if (value.k !== "Con" || value.x.length !== 2) throw Error("Invalid runtime List");
      items.push(value.x[0]); term = value.x[1];
    }
  }
  function decode(term: B.HTerm): Value {
    const value = ctor(term), tag = value.k.split(".").at(-1)!;
    if (tag === "Zero" || tag === "Succ") return nat(term);
    if (tag === "SNil" || tag === "SCon") return text(term);
    if (tag === "Nil" || tag === "Con") return list(term).map(decode);
    if (tag === "True" || tag === "False") return tag === "True";
    return { tag, fields: value.x.map(decode) };
  }
  function tokens(term: B.HTerm) {
    return list(term).map(token => {
      const value = ctor(token);
      if (value.k.split(".").at(-1) !== "TokenInfo") throw Error("Invalid runtime Token");
      return { kind: ctor(value.x[0]).k.split(".").at(-1), text: text(value.x[1]),
        beg: nat(value.x[2]), end: nat(value.x[3]), line: nat(value.x[4]), col: nat(value.x[5]) };
    });
  }
  function termResult(term: B.HTerm) {
    const result = ctor(term), pair = ctor(result.x[0]);
    return { ok: decode(result.x[1]), term: decode(pair.x[0]), remainder: tokens(pair.x[1]) };
  }
  return { ctor, list, decode, tokens, termResult };
}
function node(value: Value): Node {
  if (typeof value !== "object" || Array.isArray(value)) throw Error("Expected AST node");
  return value;
}
function values(value: Value): Value[] {
  if (!Array.isArray(value)) throw Error("Expected AST list");
  return value;
}
function firstDifference(expected: unknown, actual: unknown, path = "$"): unknown {
  if (JSON.stringify(expected) === JSON.stringify(actual)) return null;
  if (!expected || !actual || typeof expected !== "object" || typeof actual !== "object"
    || Array.isArray(expected) !== Array.isArray(actual)) return { path, expected, actual };
  const a = expected as Record<string, unknown>, b = actual as Record<string, unknown>;
  if (Object.keys(a).join() !== Object.keys(b).join()) return { path, expectedKeys: Object.keys(a), actualKeys: Object.keys(b) };
  for (const key of Object.keys(a)) {
    const difference = firstDifference(a[key], b[key], path + "/" + key);
    if (difference) return difference;
  }
  return { path, expected, actual };
}

export async function collectConsExpressionDiagnostics(selected?: string[]) {
  const canonicalSource = await Bun.file("bend2/selfhost/parser.bend").text();
  const book = await canonicalSourceBook(canonicalSource), observe = observers(book);
  const directory = mkdtempSync(join(tmpdir(), "bend-cons-expression-")), file = join(directory, "source.bend");
  writeFileSync(file, ""); // sourceOracle requires a real root file; it supplies exact source bytes.
  const rows: Record<string, unknown>[] = [];
  try {
    for (const fixture of consExpressionFixtures.filter(item => !selected || selected.includes(item.name))) {
      const oracle = await sourceOracle(file, fixture.source, { preloadBase: true });
      const row: Record<string, unknown> = { name: fixture.name, source: fixture.source,
        stage0Expected: fixture.stage0Expected, stage0Accepted: oracle.accepted,
        stage0ExpectationMatches: oracle.accepted === fixture.stage0Expected,
        stage0Observation: oracle.observation, boundaries: oracle.boundaries };
      if (!oracle.accepted) row.stage0Failure = { failure: oracle.failure, error: String(oracle.error) };
      try {
        // Both producer and symbol combining are the actual current Bend code.
        const raw = apply("lexer.tokens", [stringTerm(fixture.source)]);
        const combined = apply("combine_symbols", [raw, B.Ctr("SymbolCombineScan", [])]);
        row.lexerTokens = observe.tokens(raw); row.combinedTokens = observe.tokens(combined);
        const result = node(observe.decode(apply("parse_module_tokens", [combined, stringTerm(file)])));
        row.canonicalAccepted = result.tag === "ParseSuccess";
        row.acceptanceParity = row.canonicalAccepted === oracle.accepted;
        if (result.tag === "ParseSuccess" && oracle.accepted) {
          const module = node(result.fields[0]), imports = values(module.fields[1]);
          const adjusted: Node = { ...module, fields: [module.fields[0], imports.map(value => {
            const imported = node(value), original = oracle.imports.find(item => item.alias === imported.fields[1]);
            return { ...imported, fields: [original?.namespace || imported.fields[0], ...imported.fields.slice(1)] };
          }), module.fields[2]] };
          const environment = oracle.normalizationBook();
          const expected = normalizeCoreBook(environment, oracle.declarations.map(item => item.key),
            oracle.imports.map(item => ({ path: item.path, alias: item.alias })), file, dirname(file) + "/").semantic;
          const actual = canonicalCore(adjusted, environment, fixture.source).semantic;
          // The canonicalCore alias adjustment is internal to core resolution;
          // import payload itself retains the independently observed spelling.
          actual.imports = normalizeImports(imports.map(value => { const item = node(value);
            return { path: String(item.fields[0]), alias: String(item.fields[1]) }; }));
          row.expected = expected; row.actual = actual;
          row.stage0ASTHash = createHash("sha256").update(JSON.stringify(expected)).digest("hex");
          row.canonicalASTHash = createHash("sha256").update(JSON.stringify(actual)).digest("hex");
          row.firstDifference = firstDifference(expected, actual);
          row.semanticParity = row.firstDifference === null;
        } else {
          row.canonicalResult = result;
          row.semanticParity = result.tag === "ParseFailure" && !oracle.accepted;
        }
        if (fixture.expression !== undefined) {
          const scope = listTerm((fixture.scope ?? []).map((name, index) => B.Ctr("Scope", [stringTerm(name), natTerm(index)])));
          const depth = natTerm(fixture.scope?.length ?? 0), fileTerm = stringTerm(file);
          const rawExpr = apply("lexer.tokens", [stringTerm(fixture.expression)]);
          const input = apply("combine_symbols", [rawExpr, B.Ctr("SymbolCombineScan", [])]);
          const atom = apply("parse_atom", [fileTerm, input, scope, depth]);
          const atomResult = observe.ctor(atom), atomPair = observe.ctor(atomResult.x[0]);
          const trace: Record<string, unknown> = { expression: fixture.expression, scope: fixture.scope ?? [],
            lexerTokens: observe.tokens(rawExpr), combinedTokens: observe.tokens(input),
            parseAtom: observe.termResult(atom),
            parseTerm: observe.termResult(apply("parse_term", [fileTerm, input, scope, depth, natTerm(0)])) };
          if (observe.decode(atomResult.x[1]) === true) {
            trace.parseTermTail = observe.termResult(apply("parse_term_tail", [fileTerm, atomPair.x[0], atomPair.x[1], scope, depth, natTerm(0)]));
            const remaining = observe.list(atomPair.x[1]), remainingTokens = observe.tokens(atomPair.x[1]);
            if (remainingTokens[0]?.text === "<>") {
              trace.leftNameEnd = observe.decode(apply("token_end_first", [atomPair.x[0]]));
              trace.operatorBeg = remainingTokens[0].beg;
              trace.followingToken = remainingTokens[1];
              // Repair may delete this obsolete branch. Never require it or
              // replace it with a guessed predicate when collecting after-fix evidence.
              if (book.tlds.empty_generic_follow) trace.emptyGenericFollow = observe.decode(apply("empty_generic_follow", [listTerm(remaining.slice(1))]));
            }
          }
          row.trace = trace;
        }
      } catch (error) {
        row.error = error && typeof error === "object" && "$" in error && error.$ === "Err"
          ? B.err_show(error as Parameters<typeof B.err_show>[0]) : String(error);
        row.semanticParity = false;
      }
      rows.push(row);
      console.log(JSON.stringify({ name: fixture.name, stage0Accepted: row.stage0Accepted,
        canonicalAccepted: row.canonicalAccepted, semanticParity: row.semanticParity, error: row.error }));
      Bun.gc(true);
    }
    return { canonicalSha256: createHash("sha256").update(canonicalSource).digest("hex"),
      comparison: "Full existing FS1 normalized module semantics; spans and alpha spelling follow the shared normalizer; no semantic exclusions", rows };
  } finally { rmSync(directory, { recursive: true, force: true }); }
}

if (import.meta.main) {
  await guardHeavyGate(import.meta.path, { label: "Focused canonical cons expression full-AST and helper diagnostics" });
  const selected = process.argv.find(arg => arg.startsWith("--case="))?.slice(7).split(",");
  if (selected?.some(name => !consExpressionFixtures.some(fixture => fixture.name === name))) throw Error("Unknown cons fixture");
  const result = await collectConsExpressionDiagnostics(selected);
  const report = process.argv.find(arg => arg.startsWith("--report="))?.slice(9)
    ?? "checkpoints/bootstrap-cons-expression-diagnostics.json";
  writeFileSync(report, JSON.stringify(result, null, 2) + "\n");
  if (result.rows.some(row => !row.stage0ExpectationMatches || !row.acceptanceParity || !row.semanticParity)) process.exitCode = 1;
}
