import { expect, test } from "bun:test";
import { resolve } from "node:path";
import * as B from "../bend2/bend.ts";
import { canonicalCore, canonicalSourceBook, normalizeCoreBook, observeCoreBook, stringLiteralTerm,
  type CorePayload, type Node, type Span, type Value } from "./parser_full_semantic_normalize.ts";
import { installCompiledLexerABI } from "./bootstrap_parser_eval_abi.ts";

// canonicalCore's existing FS1 bridge uses this filename for native spans.
const file = "smoke";
const name = "literal_value";
const parserPath = process.env.BOOTSTRAP_PARSER_SOURCE ?? "bend2/selfhost/parser.bend";
let runtime: Promise<B.Book> | undefined;
const canonicalBook = () => runtime ??= Bun.file(resolve(parserPath)).text().then(canonicalSourceBook).then(async book => {
  await installCompiledLexerABI(book);
  return book;
});

function parser(book: B.Book, str: string): B.Parse {
  return { book, dir: resolve("bend2/selfhost") + "/", str, pos: 0,
    stk: [], frs: 0, ns: "", al: {} };
}
function nativeParse(book: B.Book, text: string): B.LTerm {
  const p = parser(book, text), term = B.parse_term(p);
  B.parse_skip(p);
  if (p.pos !== text.length) throw Error("Stage0 left unparsed literal input");
  return term;
}
const closed = (book: B.Book, text: string) => B.term_higher(nativeParse(book, text));
const apply = (key: string, args: B.HTerm[]) => args.reduce((f, x) => B.App(f, x), B.Ref(key));
function ctor(book: B.Book, term: B.HTerm, kind?: string): Extract<B.HTerm, { $: "Ctr" }> {
  const raw = B.term_wnf(book, term);
  // Demand one authentic literal layer, never eagerly expand a compact tree.
  const value = raw.$ === "Lit" ? B.lit_step(raw) : raw;
  if (value.$ !== "Ctr" || (kind && B.name_key(value.k).split(".").at(-1) !== kind)) {
    throw Error("Expected " + (kind ?? "constructor") + ", observed " + (value.$ === "Ctr" ? value.k : value.$));
  }
  return value;
}
function nat(book: B.Book, term: B.HTerm): number {
  let n = 0;
  for (;;) {
    const raw = B.term_wnf(book, term);
    if (raw.$ === "Lit" && raw.k === "Nat") return n + raw.v;
    const item = ctor(book, term);
    if (item.k === "Zero" && item.x.length === 0) return n;
    if (item.k !== "Succ" || item.x.length !== 1) throw Error("Invalid runtime Nat");
    n++; term = item.x[0];
  }
}
function data(book: B.Book, term: B.HTerm): B.LTerm {
  const item = ctor(book, term);
  return B.Ctr(item.k, item.x.map(child => data(book, child)));
}
function text(book: B.Book, term: B.HTerm): string {
  let result = "";
  for (;;) {
    const raw = B.term_wnf(book, term);
    if (raw.$ === "Lit" && raw.k === "String") return result + raw.v;
    const item = ctor(book, term);
    if (item.k === "SNil" && item.x.length === 0) return result;
    if (item.k !== "SCon" || item.x.length !== 2) throw Error("Invalid runtime String");
    const char = ctor(book, item.x[0], "Chr");
    const payload = B.term_wnf(book, char.x[0]);
    const code = B.u32_from_term(payload.$ === "Lit" ? payload : data(book, payload));
    if (code === null) throw Error("Invalid runtime character Word");
    result += String.fromCodePoint(code); term = item.x[1];
  }
}
function list(book: B.Book, term: B.HTerm): B.HTerm[] {
  const result: B.HTerm[] = [];
  for (;;) {
    const item = ctor(book, term);
    if (item.k === "Nil" && item.x.length === 0) return result;
    if (item.k !== "Con" || item.x.length !== 2) throw Error("Invalid runtime List");
    result.push(item.x[0]); term = item.x[1];
  }
}
// Same Value ABI as FS1: AST fields stay intact; runtime String/Nat/U32/List/Bool
// containers are decoded. String codepoints are checked independently below.
function decode(book: B.Book, term: B.HTerm): Value {
  const raw = B.term_wnf(book, term);
  if (raw.$ === "Lit" && (raw.k === "Nat" || raw.k === "String" || raw.k === "U32")) return raw.v;
  const item = ctor(book, raw), tag = B.name_key(item.k).split(".").at(-1)!;
  if (tag === "Zero" || tag === "Succ") return nat(book, term);
  if (tag === "SNil" || tag === "SCon") return text(book, term);
  if (tag === "U32") return nat(book, B.App(B.Ref("U32.to_nat"), raw));
  if (tag === "Nil" || tag === "Con") return list(book, term).map(child => decode(book, child));
  if (tag === "True" || tag === "False") return tag === "True";
  return { tag, fields: item.x.map(child => decode(book, child)) };
}
function node(value: Value, tag?: string): Node {
  if (typeof value !== "object" || Array.isArray(value) || (tag && value.tag !== tag)) {
    throw Error("Expected AST " + (tag ?? "node"));
  }
  return value;
}
function array(value: Value): Value[] {
  if (!Array.isArray(value)) throw Error("Expected AST array");
  return value;
}
function str(value: Value): string {
  if (typeof value !== "string") throw Error("Expected AST text");
  return value;
}
function num(value: Value): number {
  if (typeof value !== "number") throw Error("Expected AST number");
  return value;
}
function sourceSpan(value: Value, source: string): B.Span {
  const s = node(value, "SpanOf");
  if (str(s.fields[0]) !== file) throw Error("Unexpected literal source file");
  return { file: { str: source, ns: "", al: {} }, beg: num(s.fields[1]), end: num(s.fields[2]) };
}
// Literal-only native tree projection. The full module uses the existing FS1
// canonicalCore bridge below, independently of this diagnostic projection.
function literalTerm(value: Value, source: string): B.LTerm {
  const item = node(value), f = item.fields, s = sourceSpan(f.at(-1)!, source);
  switch (item.tag) {
    case "TermCtr": return B.Ctr(str(f[0]), array(f[1]).map(child => literalTerm(child, source)), s);
    case "TermString": return stringLiteralTerm(value, s);
    case "TermRef": return B.Ref(str(f[0]), s);
    case "TermApp": return B.App(literalTerm(f[0], source), literalTerm(f[1], source), s);
    default: throw Error("Unexpected literal AST term " + item.tag);
  }
}
function termPayload(term: B.LTerm): { tree: unknown; spans: Span[] } {
  const book = B.book_nil();
  book.tlds[name] = { $: "Def", n: 0, T: B.Typ(B.Qnt()), v: B.term_higher(term) };
  const payload = normalizeCoreBook(book, [name], [], file);
  const declaration = payload.semantic.declarations[0] as { body: unknown };
  return { tree: declaration.body, spans: payload.spans.filter(s => s.path.startsWith("declarations/0/body")) };
}
export type LiteralWord = { path: string; bits: number[]; value: number };
function words(term: B.LTerm, path = "$", out: LiteralWord[] = []): LiteralWord[] {
  if (term.$ === "Lit") {
    // Nat contains no Words; String/U32 demand their real constructor view.
    if (term.k !== "Nat") words(B.lit_step(term), path, out);
    return out;
  }
  if (term.$ === "Ctr") {
    if (term.k === "U32") {
      const value = B.u32_from_term(term);
      if (value === null) throw Error("Malformed literal U32");
      let word = term.x[0]; const bits: number[] = [];
      while (word.$ === "Ctr" && word.k === "WCon") {
        const bit = word.x[0];
        if (bit.$ !== "Ctr" || (bit.k !== "True" && bit.k !== "False")) throw Error("Malformed literal bit");
        bits.push(bit.k === "True" ? 1 : 0); word = word.x[1];
      }
      out.push({ path, bits, value });
    } else term.x.forEach((child, i) => words(child, path + "/x/" + i, out));
  } else if (term.$ === "App") {
    words(term.f, path + "/f", out); words(term.x, path + "/x", out);
  }
  return out;
}
export type LiteralObservation = { tree: unknown; spans: Span[]; words: LiteralWord[] };
function observe(term: B.LTerm): LiteralObservation { return { ...termPayload(term), words: words(term) }; }
function environment(book: B.Book): B.Book {
  return { ...B.book_nil(), tlds: { ...book.tlds }, ctrs: { ...book.ctrs } };
}

export type LiteralTrace = {
  literal: string; source: string;
  lexerTokens: { kind: string; text: string; beg: number; end: number; line: number; col: number }[];
  u32LiteralInputs: number[];
  emittedAst: LiteralObservation;
  bodyHoas: LiteralObservation;
  stage0: LiteralObservation;
  fullCore: { canonical: CorePayload; stage0: CorePayload };
  firstDivergence: "u32_literal input" | "emittedAst bits" | "Body/HOAS bridge bits" | null;
};

function literalBodies(book: B.Book, source: string) {
  const parsed = node(decode(book, apply("parse", [closed(book, JSON.stringify(file)), closed(book, JSON.stringify(source))])), "ParseSuccess");
  const module = node(parsed.fields[0], "Module"), tops = array(module.fields[2]);
  if (tops.length !== 1) throw Error("Expected one literal definition");
  const d = node(node(tops[0], "DefTop").fields[0], "Definition");
  const body = node(node(d.fields[3], "DefTerm").fields[0], "BodyReply");
  const emitted = literalTerm(body.fields[0], source);
  // Release237 Body replies are native terms, not a synthetic Reply wrapper.
  const bridged = B.term_lower(B.term_higher(B.body_flatten(emitted, [], () => 0)));
  const nativeBook = environment(book), p = parser(nativeBook, source);
  B.parse_eat(p, "def"); B.parse_def(p, false); B.parse_skip(p);
  if (p.pos !== source.length) throw Error("Stage0 left unparsed definition input");
  const nativeDef = nativeBook.tlds[name];
  if (nativeDef?.$ !== "Def" || !nativeDef.v) throw Error("Missing stage0 literal body");
  return { module, emitted, bridged, nativeBook, native: B.term_lower(nativeDef.v) };
}

for (const bind of ["", "    value : U32 <- IO.pure(U32, 1)\n"]) {
  test(`do final action preserves native result-type annotation ${bind ? "after bind" : "at entry"}`, async () => {
    const base = await canonicalBook();
    const source = `def ${name}() -> IO(U32):\n  do IO<U32>:\n${bind}    IO.pure(U32, 4294967295)\n`;
    const book = environment(base);
    const parsed = node(decode(book, apply("parse", [closed(book, JSON.stringify(file)), closed(book, JSON.stringify(source))])), "ParseSuccess");
    const nativeBook = environment(base), p = parser(nativeBook, source);
    B.parse_eat(p, "def"); B.parse_def(p, false); B.parse_skip(p);
    expect(p.pos).toBe(source.length);
    const actual = canonicalCore(parsed.fields[0], book, source);
    const expected = normalizeCoreBook(nativeBook, [name], [], file);
    expect(actual.semantic).toEqual(expected.semantic);
  });
}

for (const binder of ["~a", "-a"]) {
  test(`Quant binder ${binder} spans its consumed type despite spanless TermQuant`, async () => {
    const book = environment(await canonicalBook());
    const source = `def ${name}(${binder}: Quant) -> Type:\n  Type\n`;
    const parsed = node(decode(book, apply("parse", [closed(book, JSON.stringify(file)), closed(book, JSON.stringify(source))])), "ParseSuccess");
    const module = node(parsed.fields[0], "Module"), definition = node(node(array(module.fields[2])[0], "DefTop").fields[0], "Definition");
    const item = node(array(definition.fields[1])[0]);
    const s = node(item.fields.at(-1)!, "SpanOf"), [at, beg, end] = s.fields;
    expect(at).toBe(file);
    expect(num(beg)).toBeGreaterThanOrEqual(0);
    expect(num(end)).toBeGreaterThanOrEqual(num(beg));
    expect(num(end)).toBeLessThanOrEqual(source.length);
    expect(source.slice(num(beg), num(end))).toEndWith("Quant");
  });
}

/** Executes actual Lexer.tokens and canonical parse, tracing the real encoder
 * boundary. Stage0 parse_def is the independent semantic/tree/span reference.
 * No test assertions or source changes are needed to collect a before-fix trace.
 */
export async function collectCanonicalLiteralTrace(literal: string, type = "U32"): Promise<LiteralTrace> {
  const base = await canonicalBook(), book = environment(base);
  const source = `def ${name}() -> ${type}:\n  ${literal}\n`;
  const tokens = list(book, apply("lexer:tokens", [closed(book, JSON.stringify(source))]));
  const lexerTokens = tokens.map(token => {
    const t = ctor(book, token, "TokenInfo");
    return { kind: B.name_key(ctor(book, t.x[0]).k).split(".").at(-1)!, text: text(book, t.x[1]),
      beg: nat(book, t.x[2]), end: nat(book, t.x[3]), line: nat(book, t.x[4]), col: nat(book, t.x[5]) };
  });
  const definition = book.tlds.u32_literal;
  if (definition?.$ !== "Def" || !definition.v) throw Error("Missing canonical u32_literal");
  const original = definition.v, u32LiteralInputs: number[] = [];
  book.tlds.u32_literal = { ...definition, v:
    B.Lam("file", 0, file => B.Lam("value", 1, value => B.Lam("beg", 2, beg => B.Lam("end", 3, end => {
      u32LiteralInputs.push(nat(book, value));
      return [file, value, beg, end].reduce((f, x) => B.App(f, x), original);
    })))) };
  const { module, emitted, bridged, nativeBook, native } = literalBodies(book, source);
  const emittedAst = observe(emitted), bodyHoas = observe(bridged), stage0 = observe(native);
  const bitKey = (value: LiteralObservation) => JSON.stringify(value.words);
  const firstDivergence = bitKey(emittedAst) !== bitKey(stage0) ? "emittedAst bits"
    : bitKey(bodyHoas) !== bitKey(stage0) ? "Body/HOAS bridge bits" : null;
  return { literal, source, lexerTokens, u32LiteralInputs, emittedAst, bodyHoas, stage0,
    fullCore: { canonical: canonicalCore(module, base, source),
      stage0: normalizeCoreBook(nativeBook, [name], [], file) }, firstDivergence };
}

// Structural quotation of stage0's actual native AST. It does not construct or
// reorder bits and never calls the canonical encoder to supply a decoder test.
function quoteNative(book: B.Book, term: B.LTerm): B.HTerm {
  if (term.$ === "Lit") return quoteNative(book, B.lit_step(term));
  const span = term.s;
  if (!span) throw Error("Native literal has no source span");
  const source = B.Ctr("ast:SpanOf", [closed(book, JSON.stringify(file)),
    B.Lit("Nat", span.beg), B.Lit("Nat", span.end)]);
  switch (term.$) {
    case "Ref": return B.Ctr("ast:TermRef", [closed(book, JSON.stringify(term.k)), source]);
    case "App": return B.Ctr("ast:TermApp", [quoteNative(book, term.f), quoteNative(book, term.x), source]);
    case "Ctr": {
      const args = term.x.reduceRight<B.HTerm>((tail, child) => B.Ctr("Con", [quoteNative(book, child), tail]), B.Ctr("Nil", []));
      return B.Ctr("ast:TermCtr", [closed(book, JSON.stringify(term.k)), args, source]);
    }
    default: throw Error("Unsupported native literal quotation " + term.$);
  }
}
export type NatDecodeTrace = {
  literal: string; native: LiteralObservation; stage0: number;
  canonical: number | null | { atLeast: number };
};
export async function collectCanonicalNatDecodeTrace(literal: string): Promise<NatDecodeTrace> {
  const book = await canonicalBook(), native = nativeParse(book, literal);
  const stage0 = nat(book, B.term_higher(native));
  const result = ctor(book, apply("nat_from_syntax", [quoteNative(book, native)]));
  let canonical: NatDecodeTrace["canonical"] = null;
  if (result.k === "Some") {
    let cursor = result.x[0], count = 0;
    for (;;) {
      const item = ctor(book, cursor);
      if (item.k === "Zero" && item.x.length === 0) { canonical = count; break; }
      if (item.k !== "Succ" || item.x.length !== 1) throw Error("Invalid decoded Nat");
      count++;
      // A reversed native Word can decode to billions. Observe only enough
      // real Succ constructors to disprove equality; never drain that Nat.
      if (count > stage0) { canonical = { atLeast: count }; break; }
      cursor = item.x[0];
    }
  } else if (result.k !== "None") throw Error("Invalid nat_from_syntax result");
  return { literal, native: observe(native), stage0, canonical };
}

export const canonicalLiteralCases = [
  ...["0", "1", "2", "42", "255"].map(literal => ({ literal, type: "U32" })),
  ...["'A'", "'b'", "' '", "'λ'", "'\\n'"].map(literal => ({ literal, type: "Char" })),
  ...['""', '"A"', '"Az"', '"λ"', '"\\n"'].map(literal => ({ literal, type: "String" })),
  ...['"😀"', '"\\u{1f600}"', '"\\0"', '"\\u{d800}"', '"\\u{110000}"', '"a\\n\\t\\r\\\\\\\"z"', JSON.stringify("long λ😀 literal ".repeat(24))]
    .map(literal => ({ literal, type: "String" })),
];

// CLI keeps the diagnostic usable before a fix, without running the suite:
// bun evals/parser_canonical_literals.test.ts --trace=42 --type=U32
// bun evals/parser_canonical_literals.test.ts --decode=257n
const traceArg = process.argv.find(value => value.startsWith("--trace="))?.slice(8);
const decodeArg = process.argv.find(value => value.startsWith("--decode="))?.slice(9);
if (import.meta.main && (traceArg !== undefined || decodeArg !== undefined)) {
  const type = process.argv.find(value => value.startsWith("--type="))?.slice(7) ?? "U32";
  if (traceArg !== undefined) console.log(JSON.stringify(await collectCanonicalLiteralTrace(traceArg, type), null, 2));
  else console.log(JSON.stringify(await collectCanonicalNatDecodeTrace(decodeArg!), null, 2));
} else {
  for (const { literal, type } of canonicalLiteralCases) {
    let observation: Promise<LiteralTrace> | undefined;
    test(`canonical ${type} literal ${literal} matches stage0 bits and full core tree`, async () => {
      const trace = await (observation ??= collectCanonicalLiteralTrace(literal, type));
      const kind = type === "U32" ? "NumberToken" : type === "Char" ? "CharToken" : "StringToken";
      expect(trace.lexerTokens.filter(token => token.kind === kind).map(token => token.text)).toEqual([literal]);
      const beg = trace.source.length - literal.length - 1, end = beg + literal.length;
      expect(trace.lexerTokens.filter(token => token.kind === kind).map(({ beg, end, line, col }) =>
        ({ beg, end, line, col }))).toEqual([{ beg, end, line: 2, col: 3 }]);
      expect(trace.emittedAst.words).toEqual(trace.stage0.words);
      expect(trace.bodyHoas.words).toEqual(trace.stage0.words);
      expect(trace.emittedAst.tree).toEqual(trace.stage0.tree);
      expect(trace.bodyHoas.tree).toEqual(trace.stage0.tree);
      // Compact native Lit has no invented child spans. Compare the real root
      // and retain/validate every constructor span emitted by the source parser.
      expect(trace.emittedAst.spans[0]).toEqual(trace.stage0.spans[0]);
      expect(trace.bodyHoas.spans).toEqual(trace.emittedAst.spans);
      expect(trace.emittedAst.spans.map(({ beg, end, context }) => ({ beg, end, context }))).toEqual(
        trace.emittedAst.spans.map(() => ({ beg, end, context: { str: trace.source, ns: "", al: {} } })));
      expect(trace.fullCore.canonical.semantic).toEqual(trace.fullCore.stage0.semantic);
      expect(trace.firstDivergence).toBeNull();
    });
  }
  for (const expression of ["1n+2n", "1n+(2n)", "257n+1n", "257n+(1n)",
    "1n+tail", "257n+tail", "1n+Succ{Zero{}}", "257n+Succ{Zero{}}"]) {
    test(`canonical Nat prefix ${expression} preserves literal tree and source spans`, async () => {
      const base = await canonicalBook(), source = `def ${name}() -> Nat:\n  ${expression}\n`;
      const { module, emitted, bridged, nativeBook, native } = literalBodies(environment(base), source);
      const canonical = observe(emitted), nativeObservation = observe(native);
      expect(canonical.tree).toEqual(nativeObservation.tree);
      expect(observe(bridged)).toEqual(canonical);
      expect(canonical.spans[0]).toEqual(nativeObservation.spans[0]);
      if (expression.endsWith("tail") || expression.includes("Succ{")) {
        const tail = (term: B.LTerm) => {
          if (expression.startsWith("1n+") && term.$ === "Ctr" && term.k === "Succ") return term.x[0];
          if (expression.startsWith("257n+") && term.$ === "App" && term.f.$ === "App"
            && term.f.f.$ === "Ref" && term.f.f.k === "Nat.add") return term.x;
          throw Error("Nat prefix changed its open/explicit tail structure");
        };
        expect(observe(tail(emitted))).toEqual(observe(tail(native)));
      }
      expect(canonicalCore(module, base, source).semantic).toEqual(
        normalizeCoreBook(nativeBook, [name], [], file).semantic);
    });
  }
  function nativeSourceSpan(span: B.Span | undefined): B.Span {
    if (!span) throw Error("Native syntax has no source span");
    return { file: { str: span.file.str, ns: span.file.ns, al: span.file.al }, beg: span.beg, end: span.end };
  }
  for (const expression of ["SNil{} ", "SCon{Chr{65}, SNil{} }"]) {
    test(`explicit empty String constructor in ${expression} ends at its closing brace`, async () => {
      const base = await canonicalBook(), source = `def ${name}() -> String:\n  ${expression}\n`;
      const { emitted, bridged, native } = literalBodies(environment(base), source);
      function emptySpans(term: B.LTerm, out: B.Span[] = []): B.Span[] {
        if (term.$ === "Ctr") {
          if (term.k === "SNil") {
            if (!term.s) throw Error("Explicit String tail has no span");
            out.push(nativeSourceSpan(term.s));
          }
          term.x.forEach(child => emptySpans(child, out));
        } else if (term.$ === "App") {
          emptySpans(term.f, out); emptySpans(term.x, out);
        }
        return out;
      }
      const expected = emptySpans(native), beg = source.indexOf("SNil{}");
      expect(expected).toEqual([{ file: { str: source, ns: "", al: {} }, beg, end: beg + 6 }]);
      expect(emptySpans(emitted)).toEqual(expected);
      expect(emptySpans(bridged)).toEqual(expected);
      expect(observe(emitted).tree).toEqual(observe(native).tree);
    });
  }
  for (const prefix of ["0n++tail", "1n++tail", "2n++tail", "2n+ +tail"]) {
    test(`natural pattern ${prefix} preserves Many tail quantity and native spans`, async () => {
      const base = await canonicalBook(), source = `def ${name}(x: Nat) -> Nat:\n  match x:\n    case ${prefix}: tail\n`;
      const parsed = node(decode(base, apply("parse", [closed(base, JSON.stringify(file)), closed(base, JSON.stringify(source))])), "ParseSuccess");
      const module = node(parsed.fields[0], "Module"), definition = node(node(array(module.fields[2])[0], "DefTop").fields[0], "Definition");
      const match = node(node(definition.fields[3], "DefTerm").fields[0], "BodyMatch");
      const branch = node(array(match.fields[1])[0], "BodyCase"), actual = array(branch.fields[0])[0];
      const p = parser(environment(base), source); p.pos = source.indexOf(prefix);
      const expected = B.parse_patt(p, B.parse_term(p));
      function compare(value: Value, pattern: B.Patt): void {
        const item = node(value);
        expect(sourceSpan(item.fields.at(-1)!, source)).toEqual(nativeSourceSpan(pattern.s));
        if (pattern.$ === "PVar") {
          expect(item.tag).toBe("PatternVar");
          expect(item.fields[0]).toBe("tail");
          expect(node(item.fields[2]).tag).toBe("QMany");
          expect(pattern.q.$).toBe("Many");
        } else {
          expect(item.tag).toBe("PatternCtr");
          expect(item.fields[0]).toBe(pattern.k);
          const children = array(item.fields[1]);
          expect(children.length).toBe(pattern.x.length);
          pattern.x.forEach((child, index) => compare(children[index], child));
        }
      }
      compare(actual, expected);
    });
  }
  // Compact Nat has no Word children, even above256. Explicit native
  // U32.to_nat applications independently exercise the Word decoder boundary.
  for (const literal of ["256n", "257n", "273n", "U32.to_nat(256)", "U32.to_nat(257)", "U32.to_nat(273)"]) {
    test(`canonical nat_from_syntax decodes stage0 AST ${literal}`, async () => {
      const trace = await collectCanonicalNatDecodeTrace(literal);
      if (literal.endsWith("n")) expect(trace.native.words).toHaveLength(0);
      else {
        expect(trace.native.words).toHaveLength(1);
        expect(trace.native.words[0].bits).toHaveLength(32);
      }
      expect(trace.canonical).toBe(trace.stage0);
    });
  }
  test('String normalization preserves character payload kinds and accepts compact U32', () => {
    function projected(payload: B.HTerm) {
      const book = B.book_nil();
      book.tlds.value = {$: 'Def', n: 0, x: 0, T: B.Ref('String'),
        v: B.Ctr('SCon', [B.Ctr('Chr', [payload]), B.Lit('String', '')])};
      const declaration = normalizeCoreBook(book, ['value'], [], file)
        .semantic.declarations[0] as {body: unknown[]};
      return declaration.body;
    }
    expect(projected(B.Lit('U32', 65))).toEqual(['Lit', 'String', 'A']);
    const floatPayload = B.lit_step(B.Lit('F32', 65));
    const tree = projected(floatPayload);
    expect(tree[0]).toBe('Ctr');
    expect(tree).not.toEqual(['Lit', 'String', 'A']);
  });
  test('streamed literal spans preserve roots and open constructor payloads', () => {
    const context = {str: 'SCon{Chr{65}, tail}', ns: '', al: {}};
    const root = {file: context, beg: 0, end: context.str.length};
    const payload = {file: context, beg: 9, end: 11};
    const book = B.book_nil();
    const character = B.Ctr('Chr', [B.Lit('U32', 65, payload)], root);
    book.tlds.closed = {$: 'Def', n: 0, x: 0, T: B.Ref('String'),
      v: B.Ctr('SCon', [character, B.Ctr('SNil', [], root)], root)};
    book.tlds.open = {$: 'Def', n: 0, x: 0, T: B.Ref('String'),
      v: B.Ctr('SCon', [character, B.Ref('tail', root)], root)};
    const observed: {body: unknown; spans: {path: string; beg: number; end: number}[]}[] = [];
    observeCoreBook(book, ['closed', 'open'], [], (declaration, spans) => {
      observed.push({body: (declaration as {body: unknown}).body,
        spans: spans.map(({path, beg, end}) => ({path, beg, end}))});
    });
    expect(observed[0].body).toEqual(['Lit', 'String', 'A']);
    expect(observed[0].spans).toEqual([{path: 'declarations/0/body', beg: root.beg, end: root.end}]);
    expect(observed[1].body).toEqual(['Ctr', 'SCon', [
      ['Ctr', 'Chr', [['Lit', 'U32', 65]]], ['Ref', 'tail', false]]]);
    expect(observed[1].spans.find(span => span.path === 'declarations/1/body/x/0/x/0'))
      .toEqual({path: 'declarations/1/body/x/0/x/0', beg: payload.beg, end: payload.end});
  });
  test('compact string observation validates every U32 and all eight names', () => {
    const sourceSpan: B.Span = {file: {str: '"\\u{1f600}\\0"', ns: '', al: {}}, beg: 0, end: 13};
    const names: Node = {tag: 'StringLiteralNames', fields: ['SNil', 'SCon', 'Chr', 'U32', 'WNil', 'WCon', 'False', 'True']};
    const literal: Node = {tag: 'TermString', fields: [[0x1f600, 0], names, {tag: 'SpanOf', fields: ['smoke', 0, 13]}]};
    const full = stringLiteralTerm(literal, sourceSpan);
    expect(words(full).map(word => word.value)).toEqual([0x1f600, 0]);
    expect(stringLiteralTerm(literal, sourceSpan, name => name, true)).toEqual(B.Lit('String', '😀\0', sourceSpan));
    expect(termPayload(full).spans.every(span => span.beg === 0 && span.end === 13)).toBe(true);
    const qualified = stringLiteralTerm(literal, sourceSpan, name => 'custom:' + name, true);
    expect(qualified.$).toBe('Ctr');
    if (qualified.$ !== 'Ctr') throw Error('Qualified literal unexpectedly compacted');
    expect(qualified.k).toBe('custom:SCon');
    const observed = JSON.stringify(termPayload(qualified).tree);
    for (const name of names.fields) expect(observed).toContain('custom:' + name);
    for (const invalid of [-1, 1.5, 0x100000000, NaN, Infinity, '65', 65n]) {
      expect(() => stringLiteralTerm({...literal, fields: [[invalid], names, literal.fields[2]]}, sourceSpan)).toThrow();
    }
    expect(() => stringLiteralTerm({...literal, fields: [[], {...names, fields: names.fields.slice(1)}, literal.fields[2]]}, sourceSpan))
      .toThrow();
    for (const invalidScalar of [0xd800, 0x110000, 0xffffffff]) {
      const fallback = stringLiteralTerm({...literal, fields: [[invalidScalar], names, literal.fields[2]]}, sourceSpan, name => name, true);
      expect(fallback.$).toBe('Ctr');
      expect(words(fallback).map(word => word.value)).toEqual([invalidScalar]);
    }
  });
}
