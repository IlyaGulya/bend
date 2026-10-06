import * as B from "../bend2/bend.ts";
import { createHash, type Hash } from "node:crypto";
import { mkdtemp, rm, writeFile, open } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { canonicalSourceBook, installCompiledNatRead, canonicalCore, normalizeCoreBook, normalizeImports, syntaxPayload } from "./parser_full_semantic_normalize.ts";
import type { CorePayload, Value, Span, Import } from "./parser_full_semantic_normalize.ts";
import { spawnSync } from "node:child_process";
import { guardHeavyGate } from "./heavy_gate.ts";

// Usage: bun evals/parser_full_fuel_smoke.ts --fuel=1000 [--expanded | --literals]
//        [--streaming] [--instrument] [--gc] [--cases=name1,name2]
//        [--canonical-timeout-ms=60000]
// FS1 compares each complete syntax/core payload before releasing that case.
// Reports/JSONL retain compact evidence only; failing payloads live separately.
// Canonical load/evaluation is isolated and bounded, never replaced by a model.
// Executes the generated bodies in Bend's core evaluator; not a parser model.
// Fuel is an explicit test input, never a production budgeting policy.
await guardHeavyGate(import.meta.path, { label: "parser-differential" });
const streaming = process.argv.includes("--streaming");
const instrument = process.argv.includes("--instrument");
const collectGC = process.argv.includes("--gc");
const fuelArg = process.argv.slice(2).find(arg => arg.startsWith("--fuel="));
const fuel = Number(fuelArg?.slice(7) ?? 1000);
if (!Number.isSafeInteger(fuel) || fuel < 0) throw Error("--fuel must be a nonnegative safe integer");
const expanded = process.argv.includes("--expanded");
const literals = process.argv.includes("--literals");
if (literals && expanded) throw Error("--literals and --expanded select exclusive corpora");
const canonicalSource = process.argv.find(arg => arg.startsWith("--canonical-source="))?.slice(19);
const canonicalTimeout = Number(process.argv.find(arg => arg.startsWith("--canonical-timeout-ms="))?.slice(23) ?? 60000);
if (!Number.isSafeInteger(canonicalTimeout) || canonicalTimeout <= 0) throw Error("--canonical-timeout-ms must be a positive safe integer");
const canonicalPath = resolve("bend2/selfhost/parser.bend");
const canonicalText = await Bun.file(canonicalPath).text();
// Deliberately no canonical checker; reuse the existing source-AST audit seam.
const canonicalBook = canonicalSource === undefined ? B.book_nil() : await canonicalSourceBook(canonicalText);
const candidate = resolve("bend2/selfhost/parser_full_generated_fuel.bend");
const text = await Bun.file(candidate).text();
const book = canonicalSource !== undefined ? B.book_nil()
  : streaming ? await canonicalSourceBook(text) : B.book_nil();
if (canonicalSource === undefined && !streaming) {
  await B.book_load(book, candidate, "", new Map());
  await installCompiledNatRead(book);
}
function closed(text: string, runtime = book): B.HTerm {
  const p: B.Parse = { book: runtime, dir: resolve("bend2/selfhost") + "/", str: text, pos: 0,
    sc: { stk: [], frs: 0 }, ns: "", al: { Ast: "ast", Lexer: "lexer" },
    os: [], inst: null, ts: [], lv: 0 };
  return B.term_higher(B.parse_term(p));
}
function apply(name: string, args: B.HTerm[]): B.HTerm {
  return args.reduce((fn, arg) => B.App(fn, arg), B.Ref(name));
}
function ctor(term: B.HTerm, runtime = book): Extract<B.HTerm, { $: "Ctr" }> {
  const value = B.term_wnf(runtime, term);
  if (value.$ !== "Ctr") throw Error("Expected constructor, observed " + value.$);
  return value;
}
function cells(count: number): B.HTerm {
  let value: B.HTerm = B.Ctr("FeedbackFuelEnd", []);
  for (let i = 0; i < count; i++) value = B.Ctr("FeedbackFuelCell", [value]);
  return value;
}
function listLength(term: B.HTerm): number {
  let count = 0;
  for (;;) {
    const item = ctor(term);
    if (item.k === "Nil") return count;
    if (item.k !== "Con") throw Error("Invalid List");
    count++; term = item.x[1];
  }
}
type Tree = [string, Tree[]];
function payloadTree(term: B.HTerm, runtime: B.Book, hash: Hash): Tree {
  const value = ctor(term, runtime);
  // Exactly JSON.stringify([key, children]), without constructing its string.
  hash.update("[").update(JSON.stringify(value.k)).update(",[");
  const children: Tree[] = [];
  for (let i = 0; i < value.x.length; i++) {
    if (i) hash.update(",");
    children.push(payloadTree(value.x[i], runtime, hash));
  }
  hash.update("]]");
  return [value.k, children];
}
function decode(tree: Tree): Value {
  const [key, fields] = tree, tag = key.split(".").at(-1)!;
  if (tag === "Zero" || tag === "Succ") {
    let cursor = tree, n = 0;
    while (cursor[0] === "Succ") { n++; cursor = cursor[1][0]; }
    if (cursor[0] !== "Zero" || !Number.isSafeInteger(n)) throw Error("Invalid AST Nat");
    return n;
  }
  if (tag === "SNil" || tag === "SCon") {
    let cursor = tree, text = "";
    while (cursor[0] === "SCon") {
      let word = cursor[1][0][1][0][1][0], code = 0, bit = 1;
      while (word[0] === "WCon") {
        if (word[1][0][0] === "True") code += bit;
        else if (word[1][0][0] !== "False") throw Error("Invalid AST Word bit");
        bit *= 2; word = word[1][1];
      }
      if (word[0] !== "WNil") throw Error("Invalid AST Word");
      text += String.fromCodePoint(code); cursor = cursor[1][1];
    }
    if (cursor[0] !== "SNil") throw Error("Invalid AST String");
    return text;
  }
  if (tag === "Nil" || tag === "Con") {
    let cursor = tree; const values: Value[] = [];
    while (cursor[0] === "Con") { values.push(decode(cursor[1][0])); cursor = cursor[1][1]; }
    if (cursor[0] !== "Nil") throw Error("Invalid AST List");
    return values;
  }
  if (tag === "True" || tag === "False") return tag === "True";
  return { tag, fields: fields.map(decode) };
}
type Result = { run: string; accepted: boolean; payloadSha256?: string; semanticAst?: unknown;
  syntaxSpans?: Span[]; module?: Value; failure?: { message: string; expected: string; observed: string;
    span: { file: string; beg: number; end: number } } };
function parserPayload(payload: B.HTerm, runtime: B.Book, run: string): Result {
  const hash = createHash("sha256");
  const tree = payloadTree(payload, runtime, hash);
  const payloadSha256 = hash.digest("hex");
  const decoded = decode(tree);
  if (typeof decoded !== "object" || Array.isArray(decoded)) throw Error("Expected parser result");
  const syntaxSpans: Span[] = [];
  const semanticAst = syntaxPayload(decoded, syntaxSpans);
  if (decoded.tag === "ParseFailure") {
    const [message, expected, observed, sourceSpan] = decoded.fields;
    if (typeof sourceSpan !== "object" || Array.isArray(sourceSpan)) throw Error("Expected failure span");
    return { run, accepted: false, payloadSha256, semanticAst, syntaxSpans,
      failure: { message: message as string, expected: expected as string, observed: observed as string,
        span: { file: sourceSpan.fields[0] as string, beg: sourceSpan.fields[1] as number, end: sourceSpan.fields[2] as number } } };
  }
  if (decoded.tag !== "ParseSuccess") throw Error("Unexpected parser result " + decoded.tag);
  return { run, accepted: true, payloadSha256, semanticAst, syntaxSpans, module: decoded.fields[0] };
}
function result(count: number, source: string): Result {
  const run = ctor(apply("parse_with_fuel", [cells(count), closed('"smoke"'), closed(JSON.stringify(source))]));
  if (run.k !== "FeedbackComplete") return { run: run.k, accepted: false };
  return parserPayload(ctor(run.x[0]).x[0], book, run.k);
}
function canonical(source: string): Result {
  return parserPayload(apply("parse", [closed('"smoke"', canonicalBook),
    closed(JSON.stringify(source), canonicalBook)]), canonicalBook, "CanonicalComplete");
}
if (canonicalSource !== undefined) {
  console.log(JSON.stringify(canonical(Buffer.from(canonicalSource, "base64").toString("utf8"))));
  process.exit(0);
}
type CanonicalObservation = { status: "COMPLETE"; result: Result; elapsedMs: number }
  | { status: "TIMEOUT" | "ERROR" | "RESOURCE_LIMIT"; elapsedMs: number; error: string; stderr: string };
function observeCanonical(source: string): CanonicalObservation {
  const start = performance.now();
  const process = spawnSync(Bun.which("bun") ?? "bun", [import.meta.path,
    "--canonical-source=" + Buffer.from(source).toString("base64")],
    { encoding: "utf8", timeout: canonicalTimeout, maxBuffer: 16 * 1024 * 1024 });
  const elapsedMs = performance.now() - start;
  if (process.error || process.status !== 0) return {
    status: process.status === 73 ? "RESOURCE_LIMIT"
      : (process.error as NodeJS.ErrnoException)?.code === "ETIMEDOUT" ? "TIMEOUT" : "ERROR",
    elapsedMs, error: process.error ? String(process.error) : "exit=" + process.status + " signal=" + process.signal,
    stderr: process.stderr,
  };
  try { return { status: "COMPLETE", result: JSON.parse(process.stdout), elapsedMs }; }
  catch (error) { return { status: "ERROR", elapsedMs, error: String(error), stderr: process.stderr }; }
}
const originalCorpus = [
  { name: "empty", source: "" },
  { name: "base-import", source: "import Base\n" },
  { name: "data-constructors", source: "type Flag is Data:\n  Off{}\n  On{}\n" },
  { name: "constant-definition", source: "def value() -> Nat:\n  3n\n" },
  { name: "typed-definition", source: "def id(x: Nat) -> Nat:\n  x\n" },
  { name: "malformed-definition", source: "def broken(\n" },
];
const expandedCorpus = [
  { name: "word-constant", source: "def word() -> U32:\n  42\n" },
  { name: "string-constant", source: 'def text() -> String:\n  "hi λ"\n' },
  { name: "char-constant", source: "def character() -> Char:\n  'λ'\n" },
  { name: "multiple-arguments", source: "def first(x: Nat, y: Nat) -> Nat:\n  x\n" },
  { name: "explicit-quantities", source: "def reuse(-T: Type, +x: Nat) -> Nat:\n  x\n" },
  { name: "untyped-without-law", source: "def untyped(x: Nat):\n  x\n" },
  { name: "untyped-law-body", source: "law same:\n  for x: Nat\n  Nat\ndef same(x):\n  x\n" },
  { name: "lambda-body", source: "def identity() -> (Nat -> Nat):\n  x => x\n" },
  { name: "nested-application", source: "def nested(x: Nat) -> Nat:\n  f(g(x))\n" },
  { name: "lambda-application", source: "def apply(x: Nat) -> Nat:\n  (y => y)(x)\n" },
  { name: "local-body", source: "def local(x: Nat) -> Nat:\n  y = x\n  y\n" },
  { name: "nested-patterns", source: "def peel(x: Nat) -> Nat:\n  match x:\n    case Succ{Succ{n}}: n\n    case Succ{Zero{}}: 0n\n    case Zero{}: 0n\n" },
  { name: "match-cases", source: "def predecessor(x: Nat) -> Nat:\n  match x:\n    case Zero{}: 0n\n    case Succ{n}: n\n" },
  { name: "do-return", source: "def effect(x: Nat) -> Nat:\n  do M<>: return x\n" },
  { name: "do-typed-bind", source: "def bound(x: Nat) -> Nat:\n  do M<>: y: Nat <- f(x); return y\n" },
  { name: "parameterized-type", source: "type Box<q, A: Type> is Kind(q):\n  Boxed{value: A}\ndef boxed(x: Nat) -> Box<Nat>:\n  Boxed{x}\n" },
  { name: "reusable-type", source: "def reusable(x: +List<Nat>) -> +List<Nat>:\n  x\n" },
  { name: "relative-import", source: "import ./dependency.bend as Dep\ndef imported() -> Nat:\n  Dep.value()\n" },
  { name: "external-import-body", source: 'def external(x: Nat) -> Nat:\n  import "external.js"\n' },
  { name: "malformed-body", source: "def broken() -> Nat:\n  )\n" },
  { name: "malformed-type", source: "type Broken is Data\n  Bad{}\n" },
  { name: "malformed-do", source: "def broken() -> Nat:\n  do M<>: return\n" },
  { name: "orphan-case", source: "case Zero{}: 0n\n" },
];
const literalCorpus = [
  { name: "literal-number-0", source: "def value() -> U32:\n  0\n" },
  { name: "literal-number-1", source: "def value() -> U32:\n  1\n" },
  { name: "literal-number-2", source: "def value() -> U32:\n  2\n" },
  { name: "literal-number-42", source: "def value() -> U32:\n  42\n" },
  { name: "literal-number-255", source: "def value() -> U32:\n  255\n" },
  { name: "literal-char-A", source: "def value() -> Char:\n  'A'\n" },
  { name: "literal-char-b", source: "def value() -> Char:\n  'b'\n" },
  { name: "literal-char-space", source: "def value() -> Char:\n  ' '\n" },
  { name: "literal-string-empty", source: 'def value() -> String:\n  ""\n' },
  { name: "literal-string-A", source: 'def value() -> String:\n  "A"\n' },
  { name: "literal-string-Az", source: 'def value() -> String:\n  "Az"\n' },
  { name: "literal-string-unicode", source: 'def value() -> String:\n  "λ"\n' },
  { name: "literal-string-escaped-newline", source: 'def value() -> String:\n  "\\n"\n' },
];
const corpusSelection = literals ? "literals" : expanded ? "expanded" : "original";
const selectedCorpus = literals ? literalCorpus : expanded ? originalCorpus.concat(expandedCorpus) : originalCorpus;
const casesArg = process.argv.find(arg => arg.startsWith("--cases="))?.slice(8);
const selectedNames = casesArg === undefined ? null : casesArg.split(",");
if (selectedNames && (selectedNames.some(name => !selectedCorpus.some(item => item.name === name))
    || new Set(selectedNames).size !== selectedNames.length)) {
  throw Error("--cases must name distinct cases in the selected corpus");
}
const corpus = selectedNames ? selectedCorpus.filter(item => selectedNames.includes(item.name)) : selectedCorpus;
type Counters = { transitions: number; dispatches: number; resumptions: number; maxKont: number;
  observedTokenRewinds: number; tokenActivations: number; exhaustion: number; tokens: number };
const freshCounters = (): Counters => ({ transitions: 0, dispatches: 0, resumptions: 0, maxKont: 0,
  observedTokenRewinds: 0, tokenActivations: 0, exhaustion: 0, tokens: 0 });
let counters = freshCounters(), active = false, lastCursor = -1;
function wrap(name: string, arity: number, observe: (args: B.HTerm[]) => void) {
  const def = book.tlds[name];
  if (def?.$ !== "Def" || !def.v || def.n !== arity) throw Error("Unexpected runtime signature " + name);
  const original = def.v;
  function lambda(index: number, args: B.HTerm[]): B.HTerm {
    return B.Lam("observer_" + index, index, value => {
      const next = [...args, value];
      if (index + 1 < arity) return lambda(index + 1, next);
      observe(next);
      return next.reduce((fn, arg) => B.App(fn, arg), original);
    });
  }
  def.v = lambda(0, []);
  return () => { def.v = original; };
}
function installObservers() {
  // Original combined-token suffixes only; reconstructed lists are excluded.
  const undo: (() => void)[] = [];
  undo.push(wrap("step_parse_module_tokens", 2, args => {
    let cursor = args[0], index = 0;
    for (;;) {
      const item = ctor(cursor), tag = item.k, position = index++;
      Object.defineProperty(item, "k", { enumerable: true, configurable: true, get() {
        if (active) { counters.tokenActivations++;
          if (position < lastCursor) counters.observedTokenRewinds++;
          lastCursor = position; }
        return tag;
      } });
      if (tag === "Nil") { counters.tokens = position; break; }
      if (tag !== "Con") throw Error("Invalid combined-token list");
      cursor = item.x[1];
    }
  }));
  undo.push(wrap("feedback_drive", 3, args => {
    active = false;
    const budget = ctor(args[0]), control = ctor(args[1]), action = ctor(control.x[0]);
    const pending = listLength(control.x[1]), stack = listLength(args[2]);
    counters.maxKont = Math.max(counters.maxKont, pending + stack);
    const resumes = action.k === "FeedbackDone" && pending + stack > 0;
    if (budget.k === "FeedbackFuelEnd") {
      if (action.k === "FeedbackCall" || resumes) counters.exhaustion++;
    } else if (action.k === "FeedbackCall") {
      counters.transitions++; counters.dispatches++;
    } else if (resumes) { counters.transitions++; counters.resumptions++; }
    active = true;
  }));
  return () => { for (const restore of undo) restore(); };
}
function observed(count: number, source: string) {
  // Retain only a hash of this case's uninstrumented baseline, never its tree.
  const baselineSha256 = jsonHash(result(count, source));
  counters = freshCounters(); active = false; lastCursor = -1;
  const restore = installObservers();
  try {
    const value = result(count, source);
    if (jsonHash(value) !== baselineSha256) throw Error("Observer changed parser result");
    return { result: value, counters: { ...counters } };
  } finally { active = false; restore(); }
}
type CoreObservation = { status: "COMPLETE"; value: CorePayload } | { status: "UNSUPPORTED"; error: string };
function lowerPayload(value: Result, environment: B.Book, source: string): CoreObservation | null {
  if (!value.accepted || !value.module) return null;
  try { return { status: "COMPLETE", value: canonicalCore(value.module, environment, source) }; }
  catch (error) { return { status: "UNSUPPORTED", error: String(error) }; }
}
function preview(value: unknown): unknown {
  if (typeof value === "string") return value.length > 256 ? value.slice(0, 256) + "…" : value;
  if (Array.isArray(value)) return { kind: "array", length: value.length };
  if (value && typeof value === "object") {
    const fields = value as Record<string, unknown>;
    return { kind: "object", tag: typeof fields.tag === "string" ? fields.tag.slice(0, 80) : undefined,
      keys: Object.keys(fields).slice(0, 8) };
  }
  return value ?? null;
}
function firstDifference(expected: unknown, actual: unknown, path = "$"): unknown {
  if (Object.is(expected, actual)) return null;
  if (expected && actual && typeof expected === "object" && typeof actual === "object"
      && Array.isArray(expected) === Array.isArray(actual)) {
    if (Array.isArray(expected) && Array.isArray(actual) && expected.length !== actual.length) {
      return { path: path + "/length", expected: expected.length, actual: actual.length };
    }
    const left = expected as Record<string, unknown>, right = actual as Record<string, unknown>;
    for (const key of Object.keys(left)) {
      const mismatch = firstDifference(left[key], right[key], path + "/" + key);
      if (mismatch) return mismatch;
    }
    for (const key of Object.keys(right)) {
      if (!Object.hasOwn(left, key)) {
        const mismatch = firstDifference(undefined, right[key], path + "/" + key);
        if (mismatch) return mismatch;
      }
    }
    return null;
  }
  return { path, expected: preview(expected), actual: preview(actual) };
}
// Incremental JSON hash: omit undefined object fields, just like JSON.stringify.
function jsonHash(value: unknown): string {
  const hash = createHash("sha256");
  function visit(value: unknown) {
    if (Array.isArray(value)) {
      hash.update("[");
      for (let i = 0; i < value.length; i++) { if (i) hash.update(","); visit(value[i]); }
      hash.update("]");
    } else if (value && typeof value === "object") {
      hash.update("{"); let first = true;
      for (const [key, child] of Object.entries(value)) {
        if (child === undefined) continue;
        if (!first) hash.update(","); first = false;
        hash.update(JSON.stringify(key)).update(":"); visit(child);
      }
      hash.update("}");
    } else hash.update(JSON.stringify(value) ?? "null");
  }
  visit(value);
  return hash.digest("hex");
}
function compactResult(value: Result) {
  return { run: value.run, accepted: value.accepted, payloadSha256: value.payloadSha256,
    semanticSha256: value.semanticAst === undefined ? undefined : jsonHash(value.semanticAst),
    syntaxSpanCount: value.syntaxSpans?.length ?? 0,
    failure: value.failure ? { message: preview(value.failure.message), expected: preview(value.failure.expected),
      observed: preview(value.failure.observed), span: value.failure.span } : undefined };
}
function compactCore(core: CoreObservation | null) {
  return core?.status === "COMPLETE" ? { status: core.status, semanticSha256: jsonHash(core.value.semantic),
    declarationCount: core.value.semantic.declarations.length, importCount: core.value.semantic.imports.length,
    spanCount: core.value.spans.length } : core ? { status: core.status, error: preview(core.error) } : null;
}
function nativeImports(source: string): { imports: Import[]; spans: Span[] } {
  const imports: Import[] = [], spans: Span[] = [];
  let offset = 0;
  // book_load owns import validation/resolution. Its public return value has
  // no import metadata; retain the same accepted header spellings separately.
  for (const line of source.split("\n")) {
    const text = line.trim();
    if (text && !text.startsWith("#") && !/^import(?:\s|$)/.test(text)) break;
    const match = /^import\s+(\S+)(?:\s+as\s+([A-Za-z_][A-Za-z0-9_]*))?\s*(?:#.*)?$/.exec(text);
    if (match) {
      const path = "imports/" + imports.length;
      imports.push({ path: match[1], alias: match[2] ?? "Base" });
      spans.push({ path, file: "smoke", beg: offset + line.indexOf("import"), end: offset + line.trimEnd().length });
    }
    offset += line.length + 1;
  }
  return { imports: normalizeImports(imports), spans };
}
const candidateSha256 = createHash("sha256").update(text).digest("hex");
const canonicalSha256 = createHash("sha256").update(canonicalText).digest("hex");
const rowsPath = resolve("checkpoints/fuel-candidate-runtime-smoke.jsonl");
const rowsFile = await open(rowsPath, "w");
const directory = await mkdtemp(join(tmpdir(), "bend-fuel-smoke-"));
const rows = [];
async function compareCase(item: { name: string; source: string }) {
    const started = performance.now();
    const runtime = instrument ? observed(fuel, item.source) : { result: result(fuel, item.source), counters: null };
    const native = B.book_nil();
    const seen = new Map<string, string>();
    await B.book_load(native, B.BASE_BEND, "", seen);
    await B.book_load(native, join(directory, "dependency.bend"), "dependency", seen);
    const environment: B.Book = { ...B.book_nil(), tlds: { ...native.tlds }, ctrs: { ...native.ctrs } };
    const file = join(directory, "source.bend"); await writeFile(file, item.source);
    const importMetadata = nativeImports(item.source);
    let stage0: { accepted: boolean; core?: CorePayload; importSpans?: Span[];
      diagnostic?: { expected: string; observed: string | null; span: { file: string; beg: number; end: number } | null } };
    try {
      const start = await B.book_load(native, file, "", seen);
      stage0 = { accepted: true, core: normalizeCoreBook(native, native.order.slice(start),
        importMetadata.imports, "smoke", directory + "/"), importSpans: importMetadata.spans };
    } catch (error) {
      if ((error as B.Err)?.$ !== "Err") throw error;
      const e = error as B.Err;
      stage0 = { accepted: false, diagnostic: {
        expected: typeof e.exp === "string" ? e.exp : B.term_show(B.term_lower(e.exp)),
        observed: e.obs === undefined ? null : typeof e.obs === "string" ? e.obs : B.term_show(B.term_lower(e.obs)),
        span: e.spn ? { file: "smoke", beg: e.spn.beg, end: e.spn.end } : null,
      } };
    }
    const canonicalObservation = observeCanonical(item.source);
    const canonicalResult = canonicalObservation.status === "COMPLETE" ? canonicalObservation.result : null;
    const generatedCore = lowerPayload(runtime.result, environment, item.source);
    const canonicalCoreObservation = canonicalResult ? lowerPayload(canonicalResult, environment, item.source) : null;
    const generatorDifference = canonicalResult && runtime.result.run === "FeedbackComplete"
      ? firstDifference({ accepted: canonicalResult.accepted, ast: canonicalResult.accepted ? canonicalResult.semanticAst : null },
        { accepted: runtime.result.accepted, ast: runtime.result.accepted ? runtime.result.semanticAst : null }) : null;
    const generatorParity = !canonicalResult ? "UNOBSERVED"
      : runtime.result.run !== "FeedbackComplete" ? "EXHAUSTED_OR_INVARIANT" : generatorDifference ? "MISMATCH" : "PASS";
    function compareNative(value: Result | null, core: CoreObservation | null) {
      if (!value) return { parity: "UNOBSERVED", difference: null };
      if (value.run !== "FeedbackComplete" && value.run !== "CanonicalComplete") return { parity: "EXHAUSTED_OR_INVARIANT", difference: null };
      if (value.accepted !== stage0.accepted) return { parity: "MISMATCH",
        difference: { path: "$/accepted", expected: stage0.accepted, actual: value.accepted } };
      if (!value.accepted) return { parity: "PASS", difference: null };
      if (core?.status !== "COMPLETE") return { parity: "NORMALIZATION_UNSUPPORTED", difference: null };
      const difference = firstDifference(stage0.core?.semantic, core.value.semantic);
      return { parity: difference ? "MISMATCH" : "PASS", difference };
    }
    const nativeComparison = compareNative(runtime.result, generatedCore);
    const canonicalNativeComparison = compareNative(canonicalResult, canonicalCoreObservation);
    const debt: { comparison: string; field: string; difference: unknown }[] = [];
    if (canonicalResult && runtime.result.run === "FeedbackComplete") {
      for (const field of ["syntaxSpans", "failure"] as const) {
        const difference = firstDifference(canonicalResult[field], runtime.result[field]);
        if (difference) debt.push({ comparison: "canonical/generated", field, difference });
      }
    }
    for (const [label, value, core] of [
      ["generated/native", runtime.result, generatedCore],
      ["canonical/native", canonicalResult, canonicalCoreObservation],
    ] as const) {
      if (value?.accepted && stage0.accepted && core?.status === "COMPLETE") {
        const difference = firstDifference(stage0.core?.spans, core.value.spans);
        if (difference) debt.push({ comparison: label, field: "coreSpans", difference });
        const importSpans = value.syntaxSpans?.filter(span => /^\$\/0\/1\/\d+\/2$/.test(span.path))
          .map((span, i) => ({ ...span, path: "imports/" + i })) ?? [];
        const importDifference = firstDifference(stage0.importSpans, importSpans);
        if (importDifference) debt.push({ comparison: label, field: "importSpans", difference: importDifference });
      } else if (value && !value.accepted && !stage0.accepted && value.failure) {
        const difference = firstDifference(stage0.diagnostic, { expected: value.failure.expected,
          observed: value.failure.observed, span: value.failure.span });
        if (difference) debt.push({ comparison: label, field: "diagnostic", difference });
      }
    }
    const classification = runtime.result.run !== "FeedbackComplete" ? "EXHAUSTED_OR_INVARIANT"
      : canonicalObservation.status === "TIMEOUT" ? "CANONICAL_OBSERVATION_TIMEOUT"
      : canonicalObservation.status === "RESOURCE_LIMIT" ? "RESOURCE_LIMIT"
      : canonicalObservation.status === "ERROR" ? "CANONICAL_OBSERVATION_ERROR"
      : generatorParity === "MISMATCH" ? "GENERATOR_BUG"
      : canonicalNativeComparison.parity === "MISMATCH" ? "CANONICAL_BUG"
      : nativeComparison.parity === "NORMALIZATION_UNSUPPORTED" || canonicalNativeComparison.parity === "NORMALIZATION_UNSUPPORTED"
        ? "NORMALIZATION_UNSUPPORTED" : "PASS";
    const acceptanceParity = runtime.result.run !== "FeedbackComplete" ? "EXHAUSTED_OR_INVARIANT"
      : !canonicalResult ? "UNOBSERVED"
      : runtime.result.accepted === canonicalResult.accepted && canonicalResult.accepted === stage0.accepted ? "PASS" : "MISMATCH";
    const failing = classification !== "PASS" || nativeComparison.parity === "MISMATCH" || acceptanceParity === "MISMATCH";
    const failurePayloadPath = failing ? resolve("checkpoints/fuel-candidate-runtime-smoke-" + candidateSha256.slice(0, 12) + "-" + item.name + ".failure.json") : undefined;
    if (failurePayloadPath) {
      // At most this case's full decoded payload is alive while writing.
      await writeFile(failurePayloadPath, JSON.stringify({ candidateSha256, canonicalSha256,
        ...item, ...runtime, stage0, canonical: canonicalObservation, generatedCore, canonicalCore: canonicalCoreObservation }) + "\n");
    }
    return { name: item.name, sourceSha256: createHash("sha256").update(item.source).digest("hex"),
      sourceBytes: Buffer.byteLength(item.source), candidateSha256, canonicalSha256,
      elapsedMs: performance.now() - started, result: compactResult(runtime.result), counters: runtime.counters,
      observerPayloadEquality: instrument ? "PASS" : "NOT_INSTRUMENTED",
      stage0: { accepted: stage0.accepted,
        core: compactCore(stage0.core ? { status: "COMPLETE", value: stage0.core } : null),
        importSpanCount: stage0.importSpans?.length ?? 0,
        diagnostic: stage0.diagnostic ? { expected: preview(stage0.diagnostic.expected),
          observed: preview(stage0.diagnostic.observed), span: stage0.diagnostic.span } : undefined },
      canonical: canonicalObservation.status === "COMPLETE"
        ? { status: canonicalObservation.status, elapsedMs: canonicalObservation.elapsedMs, result: compactResult(canonicalObservation.result) }
        : { status: canonicalObservation.status, elapsedMs: canonicalObservation.elapsedMs,
          error: preview(canonicalObservation.error), stderr: preview(canonicalObservation.stderr) },
      generatedCore: compactCore(generatedCore), canonicalCore: compactCore(canonicalCoreObservation),
      generatorParity, generatorDifference, acceptanceParity,
      acceptanceComparisons: {
        generatedNative: runtime.result.run !== "FeedbackComplete" ? "EXHAUSTED_OR_INVARIANT" : runtime.result.accepted === stage0.accepted ? "PASS" : "MISMATCH",
        canonicalNative: canonicalResult ? canonicalResult.accepted === stage0.accepted ? "PASS" : "MISMATCH" : "UNOBSERVED",
        canonicalGenerated: !canonicalResult ? "UNOBSERVED" : runtime.result.run !== "FeedbackComplete" ? "EXHAUSTED_OR_INVARIANT"
          : canonicalResult.accepted === runtime.result.accepted ? "PASS" : "MISMATCH",
      },
      rawCanonicalGeneratedPayloadEquality: canonicalResult ? canonicalResult.payloadSha256 === runtime.result.payloadSha256 ? "PASS" : "DIFFERENT" : "UNOBSERVED",
      parity: nativeComparison.parity, nativeParity: nativeComparison.parity, nativeDifference: nativeComparison.difference,
      canonicalNativeParity: canonicalNativeComparison.parity, canonicalNativeDifference: canonicalNativeComparison.difference,
      classification, spanDiagnosticDebt: debt, failurePayloadPath };
}
try {
  await writeFile(join(directory, "dependency.bend"), "def value() -> Nat:\n  1n\n");
  for (const item of corpus) {
    // compareCase's trees and native books are unreachable before the next row.
    const row = await compareCase(item);
    await rowsFile.write(JSON.stringify(row) + "\n");
    rows.push(row);
    if (collectGC) Bun.gc(true);
  }
} finally {
  await rowsFile.close();
  await rm(directory, { recursive: true, force: true });
}
const exhaustionRuntime = instrument ? observed(0, originalCorpus[2].source)
  : { result: result(0, originalCorpus[2].source), counters: null };
if ((exhaustionRuntime.counters && exhaustionRuntime.counters.exhaustion !== 1)
    || exhaustionRuntime.result.run !== "FeedbackInvariantFailure") {
  throw Error("Zero-fuel nonterminal execution did not exhaust");
}
const exhaustion = { result: compactResult(exhaustionRuntime.result), counters: exhaustionRuntime.counters };
function parityCounts(values: string[]) {
  const counts: Record<string, number> = {};
  for (const value of values) counts[value] = (counts[value] ?? 0) + 1;
  return counts;
}
const report = { schema: "FS1", candidate, sha256: candidateSha256, candidateSha256, fuel, expanded, literals,
  streaming, instrument, collectGC, cases: selectedNames, rowsPath, corpusCount: corpus.length,
  corpusSelection, status: corpusSelection + "-corpus-observation",
  canonicalPath, canonicalSha256,
  stage0Path: resolve("bend2/bend.ts"),
  stage0Sha256: createHash("sha256").update(await Bun.file("bend2/bend.ts").text()).digest("hex"),
  command: "bun evals/parser_full_fuel_smoke.ts --fuel=" + fuel + (literals ? " --literals" : expanded ? " --expanded" : "")
    + (streaming ? " --streaming" : "") + (instrument ? " --instrument" : "") + (collectGC ? " --gc" : "")
    + (casesArg === undefined ? "" : " --cases=" + casesArg) + " --canonical-timeout-ms=" + canonicalTimeout,
  executionBackend: "Bend.term_wnf over exact generated and canonical Bodies; streaming reuses source-AST lazy body_flatten audit seam; checked compiled Base JS Nat.read ABI; no canonical book_valid",
  canonicalObservationPolicy: { timeoutMsPerCase: canonicalTimeout, maxBufferBytes: 16 * 1024 * 1024,
    isolation: "one Bun subprocess per case under inherited heavy-gate lease; timeouts/errors are unobserved parity, not canonical bugs" },
  memoryPolicy: "Heavy gate owns whole-process-tree memory peaks and RESOURCE_LIMIT outcome; this report retains compact per-case rows only",
  counterDefinitions: { transitions: "actual driver Call dispatches plus Done continuations resumed",
    maxKont: "maximum pending plus saved driver Kont list lengths at driver entry",
    observedTokenRewinds: "original combined-token suffix activation index decreases; reconstructed lists excluded",
    exhaustion: "zero fuel at nonterminal driver control, distinct from an invariant action" },
  automaticFuelPolicy: "DEFERRED",
  comparisonScope: "complete canonical/generated SyntaxTerm/module payloads excluding spans; full alpha-normalized stage0 core declaration types, bodies, quantities, constructors, imports and metadata; diagnostics/spans separate",
  schemaDefinitions: {
    syntax: "generic constructor tag/fields; Nat/String/List/Bool decoded losslessly; SpanOf replaced by null and retained by AST field path",
    core: "all trusted LTerm constructors/semantic fields; body_flatten then term_higher/term_lower resolve Body and Sub; term_lower alpha-renumbers binders, binder spelling omitted, free names retained; missing lambda quantity is native plain/default Lone",
    resolution: "import aliases and relative module/import paths normalized; datatype Fill/Plus uses Base/import and preceding canonical type declarations' leading Quant parameters",
    attribution: "canonical/generated semantic equality establishes generator parity; canonical/native semantic or acceptance mismatch is canonical bug; spans/diagnostics are debt",
  },
  limits: ["bounded representative corpus, not whole-parser equivalence", "no type checking of parsed fixture programs",
    "template specialization/binders are explicitly unsupported by the core bridge, never PASS",
    "core spans compare lowered-tree paths; canonical syntax spans remain separately recorded",
    "native book_load strips import header text, so its later offsets can differ",
    "canonical timeout/error prevents generator attribution for that case",
    "fuel is a fixed explicit administrative driver input, not an automatic sizing policy"],
  generatorParity: parityCounts(rows.map(row => row.generatorParity)),
  canonicalNativeParity: parityCounts(rows.map(row => row.canonicalNativeParity)),
  nativeParity: parityCounts(rows.map(row => row.nativeParity)),
  acceptanceParity: parityCounts(rows.map(row => row.acceptanceParity)),
  spanDiagnosticDebt: { cases: rows.filter(row => row.spanDiagnosticDebt.length > 0).length,
    differences: rows.reduce((count, row) => count + row.spanDiagnosticDebt.length, 0) },
  rows, exhaustion, parityPass: rows.filter(row => row.parity === "PASS").length,
  parityMismatches: rows.filter(row => row.parity === "MISMATCH").length,
  generatorParityPass: rows.filter(row => row.generatorParity === "PASS").length,
  generatorMismatches: rows.filter(row => row.generatorParity === "MISMATCH").length,
  canonicalBugs: rows.filter(row => row.classification === "CANONICAL_BUG").length,
  canonicalUnobserved: rows.filter(row => row.canonical.status !== "COMPLETE").length,
  normalizationUnsupported: rows.filter(row => row.classification === "NORMALIZATION_UNSUPPORTED").length };
const reportText = JSON.stringify(report, null, 2);
await Bun.write("checkpoints/fuel-candidate-runtime-smoke.json", reportText + "\n");
console.log(reportText);
