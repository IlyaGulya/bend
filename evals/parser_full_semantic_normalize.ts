import * as B from "../bend2/bend.ts";
import { posix } from "node:path";
import { readParserGraph } from "./parser_full_graph.ts";
import { js_lib } from "../bend2/comp.ts";

let compiledNatRead: Promise<(source: string) => { $: "None" } | { $: "Some"; value: bigint }> | undefined;
export async function installCompiledNatRead(book: B.Book): Promise<void> {
  compiledNatRead ??= (async () => {
    const base = B.book_nil();
    await B.book_load(base, B.BASE_BEND, "", new Map());
    B.book_valid(base);
    const code = js_lib(base, ["Nat.read"], ["Nat.read"]);
    return (await import("data:text/javascript;base64," + Buffer.from(code).toString("base64"))).default["Nat.read"];
  })();
  const read = await compiledNatRead;
  function ctor(term: B.HTerm) {
    const value = B.term_wnf(book, term);
    if (value.$ !== "Ctr") throw Error("Expected numeric ABI constructor");
    return value;
  }
  const definition = book.tlds["Nat.read"];
  if (definition?.$ !== "Def") throw Error("Missing Base Nat.read");
  // Execute the checked Base implementation in the existing JS backend:
  // its overflow guard's huge Peano bound is impractical in the core reducer.
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
    const result = read(text);
    if (result.$ === "None") return B.Ctr("None", []);
    let value: B.HTerm = B.Ctr("Zero", []);
    for (let n = result.value; n > 0n; n--) value = B.Ctr("Succ", [value]);
    return B.Ctr("Some", [value]);
  });
}

// Reuse the source-AST audit seam for canonical OR exact generated source.
// Eager native loading flattens unrelated large patterns; flatten the original
// Body only on reference, without changing the implementation or evaluator.
export async function canonicalSourceBook(source: string): Promise<B.Book> {
  const { parserBook: book, bodies: exactBodies, signatures } = await readParserGraph(source);
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
    const vars = signature.parameters.map(([q, k, i, , s]) => ({ $: "PVar" as const, q, k, i, s }));
    let body: B.Body | undefined = exactBodies.get(name);
    if (!body) throw Error("Missing source Body " + name);
    let value: B.HTerm | undefined;
    const def: B.Def = { $: "Def", n: vars.length,
      T: B.term_higher(B.tele_bind(signature.parameters, signature.result)), v: null };
    Object.defineProperty(def, "v", { configurable: true, get() {
      if (value === undefined) {
        let fresh = highest([vars, signature.result, body]) + 1;
        value = B.term_higher(B.body_flatten(body!, vars, () => fresh++));
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
export type Value = string | number | boolean | Value[] | Node;
export type Node = { tag: string; fields: Value[] };
export type Import = { path: string; alias: string };
export type Span = { path: string; file: string; beg: number; end: number };
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
  if (Array.isArray(value)) return value.map((child, i) => syntaxPayload(child, spans, path + "/" + i, file));
  if (typeof value !== "object") return value;
  if (value.tag === "SpanOf") {
    spans.push({ path, file: str(value.fields[0]), beg: num(value.fields[1]), end: num(value.fields[2]) });
    return null;
  }
  return { tag: value.tag, fields: value.fields.map((child, i) => syntaxPayload(child, spans, path + "/" + i, file)) };
}
export function normalizeCoreBook(book: B.Book, names: string[], imports: Import[], file = "smoke", directory = ""): CorePayload {
  const spans: Span[] = [];
  function term(t: B.LTerm, path: string): unknown {
    if (t.s) spans.push({ path, file, beg: t.s.beg, end: t.s.end });
    const child = (x: B.LTerm, key: string) => term(x, path + "/" + key);
    const children = (xs: B.LTerm[], key: string) => xs.map((x, i) => child(x, key + "/" + i));
    // term_lower alpha-renumbers every binder. Binder spelling is not semantic;
    // free references, constructor keys, holes and ADT refs remain significant.
    switch (t.$) {
      case "Var": return ["Var", t.i, t.i < 0 ? t.k : null];
      case "Ref": return ["Ref", t.k, t.b ?? false];
      case "All": return ["All", t.q.$, t.i, child(t.A, "A"), child(t.B, "B")];
      case "Lam": return ["Lam", t.q?.$ ?? "Lone", t.i, child(t.f, "f")];
      case "Let": return ["Let", t.i, t.q.map(q => q.$), children(t.v, "v"), child(t.f, "f")];
      case "Typ": return ["Typ", child(t.g, "g")];
      case "Qnt": return ["Qnt"];
      case "Qua": return ["Qua", t.q.$];
      case "Min": return ["Min", child(t.a, "a"), child(t.b, "b")];
      case "App": return ["App", child(t.f, "f"), child(t.x, "x")];
      case "ADT": return ["ADT", t.k, children(t.x, "x"), t.r];
      case "Ctr": return ["Ctr", t.k, children(t.x, "x")];
      case "Mat": return ["Mat", t.k, child(t.h, "h"), child(t.m, "m")];
      case "Efq": return ["Efq"];
      case "Eql": return ["Eql", child(t.a, "a"), child(t.b, "b"), child(t.T, "T")];
      case "Rfl": return ["Rfl"];
      case "Rwt": return ["Rwt", child(t.e, "e"), child(t.p, "p"), child(t.f, "f")];
      case "Hol": return ["Hol", t.k];
      case "Ann": return ["Ann", child(t.x, "x"), child(t.T, "T")];
      case "Sub": throw Error("Sub survived term_higher/term_lower");
    }
  }
  const declarations = names.map((name, i) => {
    const d = book.tlds[name], path = "declarations/" + i;
    if (!d) throw Error("Missing declaration " + name);
    const T = term(B.term_lower(d.T), path + "/T");
    if (d.$ === "ADT") return { kind: "type", name, n: d.n, g: d.g, T,
      constructors: d.c.map((c, j) => ({ name: c.k, n: c.n, T: term(B.term_lower(c.T), path + "/constructors/" + j + "/T") })) };
    return { kind: "def", name, n: d.n, unsafe: d.u ?? false, builtin: d.b ?? false, T,
      imports: d.i?.map(path => posix.normalize(directory && path.startsWith(directory) ? path.slice(directory.length) : path)) ?? null,
      body: d.v ? term(B.term_lower(d.v), path + "/body") : null };
  });
  return { semantic: { imports: normalizeImports(imports), declarations }, spans };
}

export function canonicalCore(module: Value, environment: B.Book, source: string) {
  const m = node(module);
  if (m.tag !== "Module") throw Error("Expected AST Module");
  const imports = array(m.fields[1]).map(value => {
    const i = node(value); return { path: str(i.fields[0]), alias: str(i.fields[1]) };
  });
  const aliases = new Map(normalizeImports(imports).filter(i => i.path !== "Base")
    .map(i => [i.alias, i.path.replace(/\.bend$/, "")]));
  const resolve = (key: string) => {
    const dot = key.indexOf("."), prefix = key.slice(0, dot);
    return dot >= 0 && aliases.has(prefix) ? aliases.get(prefix) + key.slice(dot) : key;
  };
  // Only declaration/type environment is shared. No native parsed body is used.
  const book: B.Book = { ...B.book_nil(), tlds: { ...environment.tlds }, ctrs: { ...environment.ctrs } };
  const tops = array(m.fields[2]);
  let fresh = 0;
  let scope: number[] = [];
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
    return { src: source, beg: num(s.fields[1]), end: num(s.fields[2]) };
  }
  function index(value: Value) { const i = num(value); fresh = Math.max(fresh, i + 1); return i; }
  function pattern(value: Value): B.Patt {
    const p = node(value), f = p.fields;
    if (p.tag === "PatternVar") return { $: "PVar", k: str(f[0]), i: index(f[1]), q: quant(f[2]), s: span(f[3]) };
    if (p.tag === "PatternCtr") return { $: "PCtr", k: resolve(str(f[0])), x: array(f[1]).map(pattern), s: span(f[2]) };
    throw Error("Unknown AST pattern " + p.tag);
  }
  function body(value: Value): B.Body {
    const b = node(value), f = b.fields;
    switch (b.tag) {
      case "BodyReply": return { $: "Reply", x: term(f[0]), s: span(f[1]) };
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
      default: return { $: "Reply", x: term(value) };
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
      case "TermSub": return B.Sub(index(f[0]), term(f[1]), term(f[2]), s);
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
        return B.Lam(str(f[1]), i, scoped([i], () => term(f[3])), s, q.tag === "Some" ? quant(q.fields[0]) : undefined);
      }
      case "TermApp": return B.App(term(f[0]), term(f[1]), s);
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
      case "TermMat": return B.Mat(resolve(str(f[0])), term(f[1]), term(f[2]), s);
      case "TermAbsurd": return B.Efq(s);
      case "TermEqual": return B.Eql(term(f[0]), term(f[1]), term(f[2]), s);
      case "TermRefl": return B.Rfl(s);
      case "TermRewrite": return B.Rwt(term(f[0]), term(f[1]), term(f[2]), s);
      case "TermHole": return B.Hol(str(f[0]), s);
      case "BodyMatch": case "BodyLocal": case "BodyReply": return B.body_flatten(body(value), [], () => fresh++);
      case "TermTemplate": throw Error("Template instantiation is outside FS1 core bridge");
      default: throw Error("Unknown AST term " + t.tag);
    }
  }
  type Binder = [B.Quant, string, number, B.LTerm, B.Span];
  function telescope(value: Value): Binder[] {
    return array(value).map(value => {
      const b = node(value), f = b.fields;
      if (b.tag !== "Binder") throw Error("Template binder is outside FS1 core bridge");
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
        : prior?.$ === "Def" && prior.v === null ? prior.T : null;
      if (!T) throw Error("Untyped definition without a prior law has no native core type: " + key);
      const def: B.Def = { $: "Def", n: bs.length, T, v: null, ...(f[4] === true ? { u: true } : {}) };
      if (db.tag === "DefImports") def.i = array(db.fields[0]).map(str);
      else if (db.tag === "DefTerm") {
        const b = body(db.fields[0]);
        const vars: B.PVar[] = bs.map(b => ({ $: "PVar", k: b[1], i: b[2], q: B.Lone(), s: b[4] }));
        def.v = B.term_higher(B.term_lower(B.term_higher(B.body_flatten(b, vars, () => fresh++))));
      } else throw Error("Unknown AST definition body " + db.tag);
      book.tlds[key] = def;
    } else if (t.tag === "LawTop") {
      const clauses = array(f[1]).map(value => {
        const c = node(value), a = c.fields;
        const condition = node(a[4]);
        let T = term(a[3]);
        if (condition.tag === "Some") {
          const witness = fresh++;
          T = B.App(B.App(B.Ref("Exists"), T), B.Lam(str(a[2]), witness, term(condition.fields[0])));
        }
        return { all: a[0] === true, q: quant(a[1]), k: str(a[2]), i: fresh++, T, s: span(a[5]) };
      });
      const T = clauses.reduceRight((out, c) => c.all ? B.All(c.q, c.k, c.i, c.T, out, c.s)
        : B.App(B.App(B.Ref("Exists", c.s), c.T, c.s), B.Lam(c.k, c.i, out, c.s), c.s), term(f[2]));
      const n = clauses.findIndex(c => !c.all);
      book.tlds[key] = { $: "Def", n: n < 0 ? clauses.length : n, T: B.term_higher(T), v: null };
    } else throw Error("Unknown AST top level " + t.tag);
    names.push(key);
  }
  return normalizeCoreBook(book, names, imports);
}
