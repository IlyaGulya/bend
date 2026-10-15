import * as B from "../bend2/bend.ts";
import { posix, resolve } from "node:path";
import { readParserGraph } from "./parser_full_graph.ts";
import { js_lib } from "../bend2/comp.ts";
import {mkdtempSync, writeFileSync, rmSync} from "node:fs";
import {join} from "node:path";
import {tmpdir} from "node:os";
import {createHash} from "node:crypto";
import {writeSemanticJSON} from "./bootstrap_ast_transport.ts";

const nativeNatRoots = ["Nat.read", "Nat.double", "Nat.add", "Nat.sub", "Nat.mul", "Nat.divmod",
  "Nat.is_lt", "Nat.is_eq", "Nat.is_ne", "Nat.is_le", "Nat.is_gt", "Nat.is_ge", "Nat.div", "Nat.mod", "Nat.pow"];
let compiledNatAPI: Promise<Record<string, Function>> | undefined;
export async function installCompiledNatRead(book: B.Book): Promise<void> {
  compiledNatAPI ??= (async () => {
    const base = B.book_nil(), directory = mkdtempSync(join(tmpdir(), "bend-numeric-abi-"));
    const file = join(directory, "primitives.bend");
    const names = nativeNatRoots.map((_, i) => "observe_nat_" + i);
    const wrappers = nativeNatRoots.map((name, i) => name === "Nat.read"
      ? `def ${names[i]}(source: String) -> Maybe<&2, Nat>:\n  ${name}(source)\n`
      : name === "Nat.double" ? `def ${names[i]}(a: Nat) -> Nat:\n  ${name}(a)\n`
      : `def ${names[i]}(a: Nat, b: Nat) -> ${name === "Nat.divmod" ? "Nat & Nat" : name.startsWith("Nat.is_") ? "Bool" : "Nat"}:\n  ${name}(a, b)\n`);
    try {
      writeFileSync(file, "import Base\n" + wrappers.join("\n"));
      await B.book_load(base, file, "", new Map());
      B.book_valid(base);
      const code = js_lib(base, true, {roots: names, exports: names});
      const native = (await import("data:text/javascript;base64," + Buffer.from(code).toString("base64"))).default;
      return Object.fromEntries(nativeNatRoots.map((name, i) => [name, native[names[i]!]]));
    } finally {
      rmSync(directory, {recursive: true, force: true});
    }
  })();
  const api = await compiledNatAPI;
  // Observation only: call checked Base code using the release's native number
  // ABI. Compact core literals preserve the exact value without a Peano host
  // allocation; they are never supplied as bootstrap compiler inputs.
  function nat(value: number): B.HTerm {
    if (!Number.isInteger(value) || value < 0 || value > 2 ** 53) throw Error("Invalid native Nat ABI value");
    return B.Lit("Nat", value);
  }
  function nativeNat(term: B.HTerm): number {
    let result = 0;
    for (;;) {
      const raw = B.term_wnf(book, term);
      if (raw.$ === "Ann") { term = raw.x; continue; }
      if (raw.$ === "Lit" && raw.k === "Nat") {
        const value = result + raw.v;
        if (!Number.isInteger(value) || value < 0 || value > 2 ** 53) throw Error("Invalid native Nat ABI value");
        return value;
      }
      if (raw.$ !== "Ctr" || raw.k !== "Zero" && raw.k !== "Succ") throw Error("Invalid native Nat ABI constructor");
      if (raw.k === "Zero" && raw.x.length === 0) return result;
      if (raw.k !== "Succ" || raw.x.length !== 1 || result >= 2 ** 53) throw Error("Invalid native Nat ABI constructor");
      result++; term = raw.x[0]!;
    }
  }
  function ctor(term: B.HTerm) {
    const value = B.term_wnf(book, term);
    const head = value.$ === "Lit" ? B.lit_step(value) : value;
    if (head.$ !== "Ctr") throw Error("Expected numeric ABI constructor");
    return head;
  }
  const definition = book.tlds["Nat.read"];
  if (definition?.$ !== "Def") throw Error("Missing Base Nat.read");
  // Execute the checked Base implementation, not a host substitute for Nat.read.
  definition.v = B.Lam("source", 0, source => {
    let text = "";
    for (;;) {
      const item = ctor(source);
      if (item.k === "SNil") break;
      if (item.k !== "SCon") throw Error("Invalid numeric ABI String");
      let word = ctor(ctor(item.x[0]).x[0]).x[0], code = 0, bit = 1;
      for (;;) {
        const cell = ctor(word);
        if (cell.k === "WNil") break;
        if (cell.k !== "WCon") throw Error("Invalid numeric ABI Word");
        if (ctor(cell.x[0]).k === "True") code += bit;
        bit *= 2; word = cell.x[1];
      }
      text += String.fromCodePoint(code); source = item.x[1];
    }
    const result = api["Nat.read"]!(text);
    if (result.$ === "None") return B.Ctr("None", []);
    return B.Ctr("Some", [nat(result.value)]);
  });
  for (const name of nativeNatRoots.slice(1)) {
    const primitive = book.tlds[name];
    if (primitive?.$ !== "Def") throw Error("Missing checked Base primitive " + name);
    if (name === "Nat.double") {
      primitive.v = B.Lam("a", 0, a => nat(api[name]!(nativeNat(a))));
      continue;
    }
    primitive.v = B.Lam("a", 0, a => B.Lam("b", 1, b => {
      const result = api[name]!(nativeNat(a), nativeNat(b));
      if (typeof result === "number") return nat(result);
      if (typeof result === "boolean") return B.Ctr(result ? "True" : "False", []);
      if (result?.$ === "Tuple") return B.Ctr("Tuple", [nat(result.fst), nat(result.snd)]);
      throw Error("Invalid checked Base primitive result " + name);
    }));
  }
}

// Reuse the source-AST audit seam for canonical OR exact generated source.
// Eager native loading flattens unrelated large patterns; flatten the original
// Body only on reference, without changing the implementation or evaluator.
export async function canonicalSourceBook(source: string, sourcePath = resolve("bend2/selfhost/parser.bend")): Promise<B.Book> {
  const { parserBook: book, bodies: exactBodies, signatures } = await readParserGraph(source, sourcePath);
  function highest(node: unknown): number {
    if (!node || typeof node !== "object") return -1;
    let result = -1;
    for (const [key, child] of Object.entries(node)) {
      if (key === "s") continue;
      result = Math.max(result, key === "i" && typeof child === "number" ? child : highest(child));
    }
    return result;
  }
  for (const [name, signature] of signatures) {
    // parse_def starts Body formals at Lone; signature quantities belong to T.
    // Match pattern marks, not the telescope, determine the emitted lambda q.
    const vars = signature.parameters.map(([, k, i, , s]) => ({ $: "PVar" as const, q: B.Lone(), k, i, s }));
    let body: B.Body | undefined = exactBodies.get(name);
    if (!body) throw Error("Missing source Body " + name);
    let value: B.HTerm | undefined;
    const prior = book.tlds[name];
    if (prior?.$ !== "Def") throw Error("Missing source definition metadata " + name);
    const def: B.Def = { ...prior, n: vars.length,
      T: B.term_higher(B.tele_bind(signature.parameters, signature.result)), v: null };
    Object.defineProperty(def, "v", { configurable: true, get() {
      if (value === undefined) {
        let fresh = highest([vars, signature.result, body]) + 1;
        try { value = B.term_higher(B.body_flatten(body!, vars, () => fresh++)); }
        catch(error) { if(error&&typeof error==='object'&&'$'in error&&error.$==='Err')throw Error('Source body replay '+name+': '+B.err_show(error as B.Err)); throw error; }
        body = undefined;
      }
      return value;
    }, set(next: B.HTerm) { value = next; body = undefined; } });
    book.tlds[name] = def;
  }
  await installCompiledNatRead(book);
  return book;
}

// FS1 retains every core constructor/field, except source spans and alpha names.
// It uses the trusted parser's own Body -> core and HOAS -> indexed bridges.
export type Value = string | number | boolean | bigint | Value[] | Node;
export type Node = { tag: string; fields: Value[] };
export type Import = { path: string; alias: string };
export type Span = { path: string; file: string; beg: number; end: number; context?: B.File };
export type CorePayload = { semantic: { imports: Import[]; declarations: unknown[] }; spans: Span[] };
const node = (value: Value): Node => {
  if (typeof value !== "object" || Array.isArray(value)) throw Error("Expected AST constructor");
  return value;
};
const array = (value: Value): Value[] => {
  if (!Array.isArray(value)) throw Error("Expected AST list");
  return value;
};
const str = (value: Value): string => {
  if (typeof value !== "string") throw Error("Expected AST string");
  return value;
};
const num = (value: Value): number => {
  if (typeof value !== "number") throw Error("Expected AST index");
  if (!Number.isSafeInteger(value) || value < 0) throw Error("Expected safe nonnegative AST index");
  return value;
};
const quant = (value: Value): B.Quant => {
  switch (node(value).tag) {
    case "QZero": return B.None();
    case "QOne": return B.Lone();
    case "QMany": return B.Many();
    default: throw Error("Unknown AST quantity");
  }
};
export const normalizeImports = (imports: Import[]) => imports.map(item => ({
  path: posix.normalize(item.path), alias: item.alias,
}));
export function syntaxPayload(value: Value, spans: Span[], path = "$", file = "smoke"): unknown {
  const result: unknown[] = [];
  type Task = { value: Value; path: string; out: unknown[]; index: number };
  const tasks: Task[] = [{ value, path, out: result, index: 0 }];
  while (tasks.length) {
    const task = tasks.pop()!, current = task.value;
    if (typeof current !== "object") task.out[task.index] = current;
    else if (!Array.isArray(current) && current.tag === "SpanOf") {
      spans.push({ path: task.path, file: str(current.fields[0]), beg: num(current.fields[1]), end: num(current.fields[2]) });
      task.out[task.index] = null;
    } else {
      const children = Array.isArray(current) ? current : current.fields;
      const fields: unknown[] = new Array(children.length);
      task.out[task.index] = Array.isArray(current) ? fields : { tag: current.tag, fields };
      for (let i = children.length - 1; i >= 0; i--) {
        if (i in children) tasks.push({ value: children[i], path: task.path + "/" + i, out: fields, index: i });
      }
    }
  }
  return result[0];
}
function visitCoreBook(book: B.Book, names: string[], file: string, directory: string,
  consume: (declaration: unknown, spans: Span[], index: number) => void,
  collectSpans = true, releaseBodies = false, streamSpans = false, compactChildSpans = true): Span[] {
  const spans: Span[] = [];
  const contexts = new WeakMap<B.File, B.File>();
  // Compact native Nat and the source parser's closed constructor/U32.to_nat
  // views denote the same literal. This is observation only: open tails, other
  // calls, annotations and payload kinds remain structural compiler input.
  function literal(t: B.LTerm): {k: "Nat" | "U32" | "F32" | "String"; v: number | string} | undefined {
    if (t.$ === "Lit") return {k: t.k, v: t.v};
    function natural(t: B.LTerm): number | undefined {
      let prefix = 0;
      while (t.$ === "Ctr" && t.k === "Succ" && t.x.length === 1) {
        prefix++; t = t.x[0];
      }
      let value: number | undefined;
      if (t.$ === "Ctr" && t.k === "Zero" && t.x.length === 0) value = 0;
      else if (t.$ === "Lit" && t.k === "Nat") value = t.v;
      else if (t.$ === "App" && t.f.$ === "Ref" && t.f.k === "U32.to_nat" && !t.f.b
        && (t.x.$ === "Lit" || t.x.$ === "Ctr") && t.x.k === "U32") value = word(t.x);
      if (value !== undefined && Number.isSafeInteger(value) && value >= 0
        && prefix + value <= 0xffffffff) return prefix + value;
    }
    const n = natural(t);
    if (n !== undefined) return {k: "Nat", v: n};
    if (t.$ !== "Ctr") return;
    function word(t: B.LTerm): number | undefined {
      if (t.$ === "Lit" && t.k === "U32") return t.v;
      if (t.$ !== "Ctr" || t.k !== "U32" && t.k !== "F32" || t.x.length !== 1) return;
      let cell = t.x[0], value = 0, bits = 0;
      while (cell.$ === "Ctr" && cell.k === "WCon" && cell.x.length === 2) {
        const bit = cell.x[0];
        if (bit.$ !== "Ctr" || bit.x.length !== 0 || bit.k !== "True" && bit.k !== "False" || bits >= 32) return;
        if (bit.k === "True") value += 2 ** bits;
        bits++; cell = cell.x[1];
      }
      if (bits === 32 && cell.$ === "Ctr" && cell.k === "WNil" && cell.x.length === 0) return value;
    }
    if (t.k === "U32" || t.k === "F32") {
      const value = word(t);
      if (value !== undefined) return {k: t.k, v: value};
    }
    if (t.k === "SNil" || t.k === "SCon") {
      const characters: string[] = [];
      let cell: B.LTerm = t;
      while (cell.$ === "Ctr" && cell.k === "SCon" && cell.x.length === 2) {
        const char = cell.x[0];
        if (char.$ !== "Ctr" || char.k !== "Chr" || char.x.length !== 1) return;
        const payload = char.x[0];
        if (payload.$ !== "Ctr" && payload.$ !== "Lit" || payload.k !== "U32") return;
        const code = word(payload);
        if (code === undefined || code > 0x10ffff || code >= 0xd800 && code <= 0xdfff) return;
        characters.push(String.fromCodePoint(code)); cell = cell.x[1];
      }
      if (cell.$ === "Lit" && cell.k === "String") characters.push(cell.v);
      else if (cell.$ !== "Ctr" || cell.k !== "SNil" || cell.x.length !== 0) return;
      return {k: "String", v: characters.join("")};
    }
  }
  function term(t: B.LTerm, path: string): unknown {
    type Task = { term: B.LTerm; path: string; out: unknown[] };
    const result: unknown[] = [], tasks: Task[] = [{ term: t, path, out: result }];
    while (tasks.length) {
      const task = tasks.pop()!, t = task.term;
      if (collectSpans && t.s) {
        let context = contexts.get(t.s.file);
        if (!context) {
          context = {str: t.s.file.str, ns: t.s.file.ns, al: t.s.file.al};
          contexts.set(t.s.file, context);
        }
        spans.push({ path: task.path, file, beg: t.s.beg, end: t.s.end, context });
      }
      const pending: Task[] = [];
      const child = (x: B.LTerm, key: string) => {
        const out: unknown[] = [];
        pending.push({ term: x, path: collectSpans ? task.path + "/" + key : "", out });
        return out;
      };
      const children = (xs: B.LTerm[], key: string) => xs.map((x, i) => child(x, collectSpans ? key + "/" + i : ""));
      // term_lower alpha-renumbers every binder. Binder spelling is not semantic;
      // free references, constructor keys, holes and ADT refs remain significant.
      let fields: unknown[];
      const compact = literal(t);
      if (compact) {
        if (compact.k === "Nat" && typeof compact.v === "number" && compact.v > B.NAT_LITERAL_MAX) {
          task.out.push("App", ["Ref", "U32.to_nat", false], ["Lit", "U32", compact.v]);
        } else task.out.push("Lit", compact.k, compact.v);
        // Retain every original child's span, even when the equivalent value is
        // compact. Neither native Lit nor the comparison tree invents spans.
        if (collectSpans && compactChildSpans) {
          if (t.$ === "Ctr") children(t.x, "x");
          else if (t.$ === "App") { child(t.f, "f"); child(t.x, "x"); }
        }
        for (let i = pending.length - 1; i >= 0; i--) tasks.push(pending[i]);
        continue;
      }
      switch (t.$) {
        case "Var": fields = ["Var", t.i, t.i < 0 ? t.k : null]; break;
        case "Ref": fields = ["Ref", t.k, t.b ?? false]; break;
        case "All": fields = ["All", t.q.$, t.i, child(t.A, "A"), child(t.B, "B")]; break;
        case "Lam": fields = ["Lam", t.q?.$ ?? "Lone", t.i, child(t.f, "f")]; break;
        case "Let": fields = ["Let", t.i, t.q.map(q => q.$), children(t.v, "v"), child(t.f, "f")]; break;
        case "Typ": fields = ["Typ", child(t.g, "g")]; break;
        case "Qnt": fields = ["Qnt"]; break;
        case "Qua": fields = ["Qua", t.q.$]; break;
        case "Min": fields = ["Min", child(t.a, "a"), child(t.b, "b")]; break;
        case "App": fields = ["App", child(t.f, "f"), child(t.x, "x")]; break;
        case "ADT": fields = ["ADT", t.k, children(t.x, "x"), t.r]; break;
        case "Ctr": fields = ["Ctr", t.k, children(t.x, "x")]; break;
        case "Lit": fields = ["Lit", t.k, t.v]; break;
        case "Mat": fields = ["Mat", t.k, child(t.h, "h"), child(t.m, "m")]; break;
        case "Efq": fields = ["Efq"]; break;
        case "Eql": fields = ["Eql", child(t.a, "a"), child(t.b, "b"), child(t.T, "T")]; break;
        case "Rfl": fields = ["Rfl"]; break;
        case "Rwt": fields = ["Rwt", child(t.e, "e"), child(t.p, "p"), child(t.f, "f")]; break;
        case "Hol": fields = ["Hol", t.k]; break;
        case "Ann": fields = ["Ann", child(t.x, "x"), child(t.T, "T")]; break;
        case "Sub": throw Error("Sub survived term_higher/term_lower");
      }
      task.out.push(...fields);
      // Reversed scheduling retains the original preorder span ledger.
      for (let i = pending.length - 1; i >= 0; i--) tasks.push(pending[i]);
    }
    return result;
  }
  function declaration(name: string, i: number): unknown {
    const d = book.tlds[name], path = collectSpans ? "declarations/" + i : "";
    if (!d) throw Error("Missing declaration " + name);
    const T = term(B.term_lower(d.T), collectSpans ? path + "/T" : "");
    if (d.$ === "ADT") return { kind: "type", name, n: d.n, g: d.g, T,
      constructors: d.c.map((c, j) => ({ name: c.k, n: c.n, T: term(B.term_lower(c.T), collectSpans ? path + "/constructors/" + j + "/T" : "") })) };
    const body = d.v;
    return { kind: d.x > 0 ? "template" : "def", name, n: d.n, x: d.x, namespace: d.m ?? "",
      unsafe: d.u ?? false, builtin: d.b ?? false, T,
      imports: d.i?.map(path => posix.normalize(directory && path.startsWith(directory) ? path.slice(directory.length) : path)) ?? null,
      body: body ? term(B.term_lower(body), collectSpans ? path + "/body" : "") : null };
  }
  names.forEach((name, i) => {
    consume(declaration(name, i), spans, i);
    if (streamSpans) spans.length = 0;
    const definition = book.tlds[name];
    if (releaseBodies && definition?.$ === "Def") definition.v = null;
  });
  return spans;
}

export function normalizeCoreBook(book: B.Book, names: string[], imports: Import[], file = "smoke", directory = ""): CorePayload {
  const declarations: unknown[] = [];
  const spans = visitCoreBook(book, names, file, directory, declaration => { declarations.push(declaration); });
  return {semantic: {imports: normalizeImports(imports), declarations}, spans};
}

/** Hash the same complete normal form one declaration at a time. */
export function coreBookHash(book: B.Book, names: string[], imports: Import[], file = "smoke", directory = ""): string {
  const hash = createHash("sha256");
  const consume = (text: string) => { hash.update(text); };
  consume('{"imports":');
  writeSemanticJSON(normalizeImports(imports), consume);
  consume(',"declarations":[');
  let first = true;
  visitCoreBook(book, names, file, directory, declaration => {
    if (!first) consume(",");
    first = false;
    writeSemanticJSON(declaration, consume);
  }, false);
  consume("]}");
  return hash.digest("hex");
}

export type CoreDeclarationObserver = (declaration: unknown, spans: Span[], index: number) => void;

/** Complete semantic hashing and spans of represented normalized nodes, with
 * one normalized body live. Full constructor-child spans remain available from
 * normalizeCoreBook; traversing unused string suffixes here would be quadratic.
 * The observer must consume the borrowed span array before returning. */
export function observeCoreBook(book: B.Book, names: string[], imports: Import[],
  observer: CoreDeclarationObserver, file = "smoke", directory = ""): string {
  const hash = createHash("sha256"), consume = (text: string) => {hash.update(text);};
  consume('{"imports":');
  writeSemanticJSON(normalizeImports(imports), consume);
  consume(',"declarations":[');
  let first = true;
  visitCoreBook(book, names, file, directory, (declaration, spans, index) => {
    if (!first) consume(",");
    first = false;
    writeSemanticJSON(declaration, consume);
    observer(declaration, spans, index);
  }, true, true, true, false);
  consume("]}");
  return hash.digest("hex");
}

function moduleDeclarations(module: Value): {imports: Import[]; tops: Value[]} {
  const m = node(module);
  if (m.tag !== "Module") throw Error("Expected AST Module");
  const imports = array(m.fields[1]).map(value => {
    const i = node(value); return { path: str(i.fields[0]), alias: str(i.fields[1]) };
  });
  return {imports, tops: array(m.fields[2])};
}

const stringLiteralDefaults = ["SNil", "SCon", "Chr", "U32", "WNil", "WCon", "False", "True"];

/** Observation of the exact constructor sugar; never a compiler input rewrite. */
export function stringLiteralTerm(value: Value, sourceSpan: B.Span,
  resolveName: (name: string) => string = name => name, compact = false): B.LTerm {
  const literal = node(value);
  if (literal.tag !== "TermString" || literal.fields.length !== 3) throw Error("Expected AST TermString");
  const names = node(literal.fields[1]);
  if (names.tag !== "StringLiteralNames" || names.fields.length !== 8) throw Error("Expected eight string literal constructor names");
  const keys = names.fields.map(str).map(resolveName);
  const chars = array(literal.fields[0]).map(value => {
    if (typeof value !== "number" || !Number.isInteger(value) || value < 0 || value > 0xffffffff)
      throw Error("Expected integer U32 string literal codepoint");
    return value;
  });
  if (compact && keys.every((key, i) => key === stringLiteralDefaults[i])
    && chars.every(code => code <= 0x10ffff && (code < 0xd800 || code > 0xdfff))) {
    return B.Lit("String", chars.map(code => String.fromCodePoint(code)).join(""), sourceSpan);
  }
  let tail: B.LTerm = B.Ctr(keys[0], [], sourceSpan);
  for (let i = chars.length - 1; i >= 0; i--) {
    const value = chars[i];
    let word: B.LTerm = B.Ctr(keys[4], [], sourceSpan);
    for (let bit = 31; bit >= 0; bit--) {
      word = B.Ctr(keys[5], [B.Ctr(keys[(value >>> bit) & 1 ? 7 : 6], [], sourceSpan), word], sourceSpan);
    }
    tail = B.Ctr(keys[1], [B.Ctr(keys[2], [B.Ctr(keys[3], [word], sourceSpan)], sourceSpan), tail], sourceSpan);
  }
  return tail;
}

function canonicalBook(imports: Import[], tops: Iterable<Value>, environment: B.Book, source: string, compactStrings = false) {
  const aliases = new Map(normalizeImports(imports).filter(i => i.path !== "Base")
    .map(i => [i.alias, i.path.replace(/\.bend$/, "")]));
  const sourceFile: B.File = {str: source, ns: "", al: Object.fromEntries(aliases)};
  const resolve = (key: string) => {
    const dot = key.indexOf("."), prefix = key.slice(0, dot);
    return dot >= 0 && aliases.has(prefix) ? aliases.get(prefix) + ":" + key.slice(dot + 1) : key;
  };
  // Only declaration/type environment is shared. No native parsed body is used.
  const book: B.Book = { ...B.book_nil(), tlds: { ...environment.tlds }, ctrs: { ...environment.ctrs } };
  let fresh = 0;
  let scope: number[] = [];
  const sourceIds = new Map<number, number>();
  function scoped<T>(ids: number[], run: () => T): T {
    const outer = scope;
    scope = [...scope, ...ids];
    try { return run(); } finally { scope = outer; }
  }
  function patternIds(patterns: B.Patt[]): number[] {
    return patterns.flatMap(pattern => pattern.$ === "PVar" ? [pattern.i] : patternIds(pattern.x));
  }
  function span(value: Value): B.Span {
    const s = node(value); if (s.tag !== "SpanOf") throw Error("Expected AST span");
    return { file: sourceFile, beg: num(s.fields[1]), end: num(s.fields[2]) };
  }
  // Syntax binder indexes are lexical depths, reused by sibling cases. Core
  // identities must be fresh across all rows before match_flatten substitutes.
  function index(value: Value) { const original = num(value), id = fresh++; sourceIds.set(id, original); return id; }
  function pattern(value: Value): B.Patt {
    const p = node(value), f = p.fields;
    if (p.tag === "PatternVar") return { $: "PVar", k: str(f[0]), i: index(f[1]), q: quant(f[2]), s: span(f[3]) };
    if (p.tag === "PatternCtr") return { $: "PCtr", k: resolve(str(f[0])), x: array(f[1]).map(pattern), s: span(f[2]) };
    throw Error("Unknown AST pattern " + p.tag);
  }
  function body(value: Value): B.Body {
    const b = node(value), f = b.fields;
    switch (b.tag) {
      case "BodyReply": return term(f[0]);
      case "BodyLocal": {
        const patterns = array(f[0]).map(pattern), values = array(f[2]).map(term);
        return { $: "Local", k: patterns, q: quant(f[1]), v: values,
          f: scoped(patternIds(patterns), () => body(f[3])) };
      }
      case "BodyMatch": return { $: "Match", e: array(f[0]).map(term), r: array(f[1]).map(value => {
        const c = node(value); if (c.tag !== "BodyCase") throw Error("Expected AST BodyCase");
        const patterns = array(c.fields[0]).map(pattern);
        return { p: patterns, f: scoped(patternIds(patterns), () => body(c.fields[1])) };
      }), s: span(f[2]) };
      default: return term(value);
    }
  }
  function term(value: Value): B.LTerm {
    const t = node(value), f = t.fields;
    const s = t.tag === "TermQuant" ? undefined : span(f[f.length - 1]);
    switch (t.tag) {
      case "TermVar": {
        const depth = num(f[1]), binder = scope[scope.length - depth - 1];
        if (binder === undefined) throw Error("Unbound canonical de Bruijn variable " + str(f[0]) + " at " + depth);
        return B.Var(str(f[0]), binder, s);
      }
      case "TermRef": return B.Ref(resolve(str(f[0])), s);
      case "TermBang": {
        const x = term(f[0]); if (x.$ !== "Ref") throw Error("Offload head is not a reference");
        return { ...x, b: true, s };
      }
      case "TermSub": {
        const original = num(f[0]), target = scope.findLast(id => sourceIds.get(id) === original);
        if (target === undefined) throw Error("Unbound canonical substitution target " + original);
        const replacement = term(f[1]);
        if (replacement.$ !== "Var" && replacement.$ !== "Ctr") throw Error("Substitution requires a native pattern term");
        const toPattern = (term: B.LTerm): B.Patt => {
          if (term.$ === "Var") return {$: "PVar", k: term.k, i: term.i, q: B.Lone(), s: term.s};
          if (term.$ === "Ctr") return {$: "PCtr", k: term.k, x: term.x.map(toPattern), s: term.s};
          throw Error("Substitution requires a native pattern term");
        };
        return B.Sub(target, toPattern(replacement), term(f[2]), s);
      }
      case "TermLet": {
        const ids = array(f[1]).map(index), values = array(f[3]).map(term);
        return B.Let(array(f[0]).map(str), ids, values, scoped(ids, () => term(f[4])), s, array(f[2]).map(quant));
      }
      case "TermAnn": return B.Ann(term(f[0]), term(f[1]), s);
      case "TermType": return B.Typ(term(f[0]), s);
      case "TermQuant": return B.Qnt();
      case "TermQuantity": return B.Qua(quant(f[0]), s);
      case "TermMin": return B.Min(term(f[0]), term(f[1]), s);
      case "TermAll": {
        const i = index(f[2]), type = term(f[3]);
        return B.All(quant(f[0]), str(f[1]), i, type, scoped([i], () => term(f[4])), s);
      }
      case "TermLam": {
        const q = node(f[0]);
        const i = index(f[2]);
        return B.Lam(str(f[1]), i, scoped([i], () => term(f[3])), s, q.tag === "Some" ? quant(q.fields[0]) : B.Lone());
      }
      case "TermApp": {
        const applications: Node[] = [];
        let head = t;
        while (head.tag === "TermApp") { applications.push(head); head = node(head.fields[0]); }
        applications.reverse();
        let out = term(head);
        let explicit = false;
        for (const application of applications) {
          const argument = node(application.fields[1]);
          const marked = argument.tag === "TermTemplate";
          if (marked && explicit) throw Error("Template argument after an explicit argument");
          if (!marked) explicit = true;
          out = B.App(out, term(marked ? argument.fields[0] : argument), span(application.fields[2]));
        }
        return out;
      }
      case "TermAdt": return B.ADT(resolve(str(f[0])), array(f[1]).map(term), s, array(f[2]).map(str).map(resolve));
      case "TermFill": case "TermPlus": {
        const h = term(f[0]);
        if (h.$ !== "Ref" && h.$ !== "Var" && h.$ !== "ADT") throw Error("Invalid datatype sugar head");
        const k = resolve(h.k), d = book.tlds[k];
        const args = array(f[1]).map(term);
        if (t.tag === "TermPlus" && h.$ === "Var" && d?.$ !== "ADT") return B.Var(h.k, -1, s);
        if (d?.$ === "ADT" && args.length + d.g === d.n) args.unshift(...Array.from({ length: d.g }, (): B.LTerm => B.Qua(B.Lone(), s)));
        if (t.tag === "TermPlus") {
          if (d?.$ !== "ADT" || d.g === 0) throw Error("Unresolved quantified datatype " + k);
          if (args.length === 0 && d.g === d.n) args.push(...Array.from({ length: d.n }, (): B.LTerm => B.Qua(B.Lone(), s)));
          for (let i = 0; i < d.g; i++) args[i] = B.Qua(B.Many(), s);
        }
        return B.ADT(k, args, s);
      }
      case "TermCtr": return B.Ctr(resolve(str(f[0])), array(f[1]).map(term), s);
      case "TermString": return stringLiteralTerm(value, s!, resolve, compactStrings);
      case "TermMat": return B.Mat(resolve(str(f[0])), term(f[1]), term(f[2]), s);
      case "TermAbsurd": return B.Efq(s);
      case "TermEqual": return B.Eql(term(f[0]), term(f[1]), term(f[2]), s);
      case "TermRefl": return B.Rfl(s);
      case "TermRewrite": return B.Rwt(term(f[0]), term(f[1]), term(f[2]), s);
      case "TermHole": return B.Hol(str(f[0]), s);
      case "BodyMatch": case "BodyLocal": case "BodyReply": return B.body_flatten(body(value), [], () => fresh++);
      case "TermTemplate": throw Error("Template marker outside an application");
      default: throw Error("Unknown AST term " + t.tag);
    }
  }
  type Binder = [B.Quant, string, number, B.LTerm, B.Span];
  function telescope(value: Value): Binder[] {
    return array(value).map(value => {
      const b = node(value), template = b.tag === "TemplateBinder";
      if (!template && b.tag !== "Binder") throw Error("Unknown telescope item " + b.tag);
      const f = template ? [{tag:"QZero", fields:[]} as Node, ...b.fields] : b.fields;
      const i = index(f[2]), type = term(f[3]);
      scope.push(i);
      return [quant(f[0]), str(f[1]), i, type, span(f[4])];
    });
  }
  function bind(bs: Binder[], tip: B.LTerm): B.LTerm {
    return bs.reduceRight((out, [q, k, i, T, s]) => B.All(q, k, i, T, out, s), tip);
  }
  const names: string[] = [];
  for (const top of tops) {
    fresh = 0;
    scope = [];
    sourceIds.clear();
    const t = node(top), d = node(t.fields[0]), f = d.fields, key = resolve(str(f[0]));
    if (t.tag === "TypeTop") {
      const bs = telescope(f[1]), kind = term(f[2]);
      const g = bs.findIndex(b => b[3].$ !== "Qnt");
      const adt: B.ADT = { $: "ADT", n: bs.length, g: g < 0 ? bs.length : g, T: B.term_higher(bind(bs, kind)), c: [] };
      book.tlds[key] = adt;
      for (const value of array(f[3])) {
        scope = bs.map(b => b[2]);
        const c = node(value), fs = telescope(c.fields[1]);
        const ctr = { k: resolve(str(c.fields[0])), n: fs.length,
          T: B.term_higher(bind(bs.concat(fs), B.ADT(key, bs.map(b => B.Var(b[1], b[2]))))) };
        adt.c.push(ctr); book.ctrs[ctr.k] = ctr;
      }
    } else if (t.tag === "DefTop") {
      const bs = telescope(f[1]), ret = node(f[2]), db = node(f[3]);
      const prior = book.tlds[key];
      const T = ret.tag === "SomeTerm" ? B.term_higher(bind(bs, term(ret.fields[0])))
        : prior?.$ === "Def" ? prior.T : null;
      if (!T) throw Error("Untyped definition without a prior law has no native core type: " + key);
      const x = array(f[1]).findIndex(value => node(value).tag !== "TemplateBinder");
      const def: B.Def = { $: "Def", n: bs.length, x: ret.tag === "SomeTerm" ? x < 0 ? bs.length : x : prior?.$ === "Def" ? prior.x : 0,
        m: "", T, v: null, ...(f[4] === true ? { u: true } : {}) };
      if (db.tag === "DefImports") def.i = array(db.fields[0]).map(str);
      else if (db.tag === "DefTerm") {
        let b: B.Body | undefined = body(db.fields[0]);
        const vars: B.PVar[] = bs.map(b => ({ $: "PVar", k: b[1], i: b[2], q: B.Lone(), s: b[4] }));
        const freshStart = fresh;
        let value: B.HTerm | null | undefined;
        Object.defineProperty(def, "v", {configurable: true, enumerable: true,
          get() {
            if (value === undefined) {
              let bodyFresh = freshStart;
              value = B.term_higher(B.body_flatten(b!, vars, () => bodyFresh++));
              b = undefined;
            }
            return value;
          },
          set(next: B.HTerm | null) {value = next; b = undefined;}});
      } else throw Error("Unknown AST definition body " + db.tag);
      book.tlds[key] = def;
    } else if (t.tag === "LawTop") {
      const clauses = array(f[1]).map(value => {
        const c = node(value), a = c.fields;
        const condition = node(a[4]);
        let T = term(a[3]);
        if (condition.tag === "Some") {
          const witness = index(scope.length);
          T = B.App(B.App(B.Ref("Exists"), T), B.Lam(str(a[2]), witness, scoped([witness], () => term(condition.fields[0]))));
        }
        const i = index(scope.length);
        scope.push(i);
        const clauseSpan = span(a[5]);
        let before = clauseSpan.beg - 1;
        while (before >= 0 && /\s/.test(source[before]!)) before--;
        return { all: a[0] === true, q: quant(a[1]), k: str(a[2]), i, T, s: clauseSpan, template: source[before] === "~" };
      });
      const T = clauses.reduceRight((out, c) => c.all ? B.All(c.q, c.k, c.i, c.T, out, c.s)
        : B.App(B.App(B.Ref("Exists", c.s), c.T, c.s), B.Lam(c.k, c.i, out, c.s), c.s), term(f[2]));
      const n = clauses.findIndex(c => !c.all);
      const templateEnd = clauses.findIndex(clause => !clause.template);
      book.tlds[key] = { $: "Def", n: n < 0 ? clauses.length : n, T: B.term_higher(T), v: null,
        x: templateEnd < 0 ? clauses.length : templateEnd, m: "" };
    } else throw Error("Unknown AST top level " + t.tag);
    // book_load assigns b after parsing; it is loader
    // metadata, not a SyntaxTerm/Declaration field. Retain the same declaration
    // environment's policy without borrowing any native parsed type or body.
    const loaded = environment.tlds[key], reconstructed = book.tlds[key];
    if (loaded && reconstructed) reconstructed.b = loaded.b;
    names.push(key);
  }
  return {book, names, imports};
}

export function canonicalCore(module: Value, environment: B.Book, source: string): CorePayload {
  const input = moduleDeclarations(module);
  const {book, names, imports} = canonicalBook(input.imports, input.tops, environment, source);
  return normalizeCoreBook(book, names, imports);
}

export function canonicalCoreHash(module: Value, environment: B.Book, source: string, semanticImports: Import[]): string {
  const input = moduleDeclarations(module);
  const {book, names} = canonicalBook(input.imports, input.tops, environment, source, true);
  return coreBookHash(book, names, semanticImports);
}

export function observeCanonicalCore(module: Value, environment: B.Book, source: string,
  semanticImports: Import[], observer: CoreDeclarationObserver): string {
  const input = moduleDeclarations(module);
  const {book, names} = canonicalBook(input.imports, input.tops, environment, source, true);
  return observeCoreBook(book, names, semanticImports, observer);
}

/** Same full reconstruction and final declaration ordering, with original
 * transported declarations supplied one at a time rather than as a second AST. */
export function canonicalDeclarationsHash(imports: Import[], declarations: Iterable<Value>, environment: B.Book, source: string, semanticImports: Import[]): string {
  const {book, names} = canonicalBook(imports, declarations, environment, source, true);
  return coreBookHash(book, names, semanticImports);
}
