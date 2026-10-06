#!/usr/bin/env bun
// HYBRID: host parser/loader -> typed selfhost AST -> selfhost checker/emitter.
// Stage 0 compiles only the generated integration runner, never the target.
import * as child from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import * as Bend from "../bend2/bend.ts";

const ROOT = path.resolve(import.meta.dir, "..");
const BASE = Bend.BASE_BEND;
const span = (file: string, beg = 0, end = 0) => `AST.SpanOf{${str(file)}, ${nat(beg)}, ${nat(end)}}`;
const str = (value: string) => JSON.stringify(value);
const nat = (value: number) => {
  if (!Number.isSafeInteger(value) || value < 0) throw Error("invalid AST index: " + value);
  return `${value}n`;
};
const array = <T>(items: T[], encode: (item: T) => string) =>
  `[${items.map(encode).join(", ")}]`;
const ctor = (name: string, ...args: string[]) => `AST.${name}{${args.join(", ")}}`;
const quant = (q: Bend.Quant) => ctor(({ None: "QZero", Lone: "QOne", Many: "QMany" })[q.$]);
const qmaybe = (q?: Bend.Quant) => q === undefined ? "None{}" : `Some{${quant(q)}}`;
// Stage-0 stores qualified references; the checker accepts local names and
// import aliases, and canonicalizes them against the loaded module graph.
const references = new Map<string, (key: string) => string>();
function ref(key: string, file: string): string {
  return references.get(file)?.(key) ?? key;
}

function term(t: Bend.LTerm, file: string, depth = 0): string {
  const s = span(file, t.s?.beg, t.s?.end);
  switch (t.$) {
    case "Var": return ctor("TermVar", str(t.k), nat(depth - t.i - 1), s);
    case "Ref": return ctor("TermRef", str(ref(t.k, file)), s);
    case "Sub": return ctor("TermSub", nat(t.i), pattern_term(t.v, file, depth), term(t.f, file, depth + 1), s);
    case "Let": return ctor("TermLet", array(t.k, str), array(t.i, nat), array(t.q, quant), array(t.v, x => term(x, file, depth)), term(t.f, file, depth + t.k.length), s);
    case "Ann": return ctor("TermAnn", term(t.x, file, depth), term(t.T, file, depth), s);
    case "Typ": return ctor("TermType", term(t.g, file, depth), s);
    case "Qnt": return ctor("TermQuant");
    case "Qua": return ctor("TermQuantity", quant(t.q), s);
    case "Min": return ctor("TermMin", term(t.a, file, depth), term(t.b, file, depth), s);
    case "All": return ctor("TermAll", quant(t.q), str(t.k), nat(t.i), term(t.A, file, depth), term(t.B, file, depth + 1), s);
    case "Lam": return ctor("TermLam", qmaybe(t.q), str(t.k), nat(t.i), term(t.f, file, depth + 1), s);
    case "App": return ctor("TermApp", term(t.f, file, depth), term(t.x, file, depth), s);
    case "ADT": return ctor("TermAdt", str(ref(t.k, file)), array(t.x, x => term(x, file, depth)), array(t.r, k => str(ref(k, file))), s);
    case "Ctr": return ctor("TermCtr", str(ref(t.k, file)), array(t.x, x => term(x, file, depth)), s);
    case "Mat": return ctor("TermMat", str(ref(t.k, file)), term(t.h, file, depth), term(t.m, file, depth), s);
    case "Efq": return ctor("TermAbsurd", s);
    case "Eql": return ctor("TermEqual", term(t.a, file, depth), term(t.b, file, depth), term(t.T, file, depth), s);
    case "Rfl": return ctor("TermRefl", s);
    case "Rwt": return ctor("TermRewrite", term(t.e, file, depth), term(t.p, file, depth), term(t.f, file, depth), s);
    case "Hol": return ctor("TermHole", str(t.k), s);
  }
}

function pattern_term(t: Bend.LTerm | Bend.Patt, file: string, depth: number): string {
  if (t.$ === "PVar") return ctor("TermVar", str(t.k), nat(depth - t.i - 1), span(file, t.s?.beg, t.s?.end));
  if (t.$ === "PCtr") return ctor("TermCtr", str(ref(t.k, file)), array(t.x, x => pattern_term(x, file, depth)), span(file, t.s?.beg, t.s?.end));
  return term(t, file, depth);
}

function telescope(t: Bend.LTerm, count: number, file: string, initialDepth = 0) {
  const binders: string[] = [];
  for (let i = 0; i < count; i++) {
    if (t.$ !== "All") throw Error(`missing host binder ${i} in ${file}`);
    binders.push(ctor("Binder", quant(t.q), str(t.k), nat(t.i), term(t.A, file, initialDepth + i), span(file, t.s?.beg, t.s?.end)));
    t = t.B;
  }
  return { binders: `[${binders.join(", ")}]`, result: t };
}

function declaration(book: Bend.Book, key: string, local: string, file: string, law: boolean): string {
  const item = book.tlds[key];
  if (item === undefined) throw Error(`missing host declaration ${key}`);
  if (item.$ === "ADT") {
    const type = telescope(Bend.term_lower(item.T), item.n, file);
    const constructors = item.c.map(c => {
      // Constructor types begin with the type parameters, already supplied by TypeDecl.
      const allFields = Bend.term_lower(c.T);
      let fieldStart = allFields;
      for (let i = 0; i < item.n; i++) {
        if (fieldStart.$ !== "All") throw Error(`invalid constructor telescope: ${c.k}`);
        fieldStart = fieldStart.B;
      }
      const localCtr = key === local ? c.k : c.k.slice(key.length - local.length);
      return ctor("Constructor", str(localCtr), telescope(fieldStart, c.n, file, item.n).binders, span(file));
    });
    return ctor("TypeTop", ctor("TypeDecl", str(local), type.binders, term(type.result, file, item.n), `[${constructors.join(", ")}]`, span(file)));
  }
  const fullType = Bend.term_lower(item.T);
  if (law || item.v === null && item.i === undefined) {
    return ctor("LawTop", ctor("LawDecl", str(local), "[]", term(fullType, file), span(file)));
  }
  if (item.i !== undefined) {
    const type = telescope(fullType, item.n, file);
    return ctor("DefTop", ctor("Definition", str(local), type.binders, ctor("SomeTerm", term(type.result, file, item.n)), ctor("DefImports", array(item.i, str)), item.u ? "True{}" : "False{}", span(file)));
  }
  if (item.v === null) throw Error(`host definition without body: ${key}`);
  // Stage-0 can flatten a binder to Mat/Let instead of Lam. Check the
  // entire dependent function against its entire telescope.
  return ctor("DefTop", ctor("Definition", str(local), "[]", ctor("SomeTerm", term(fullType, file)), ctor("DefTerm", term(Bend.term_lower(item.v), file)), item.u ? "True{}" : "False{}", span(file)));
}

type Module = { file: string; namespace: string; imports: { raw: string; alias: string; target: string; beg: number }[] };
function imports_of(file: string): Module["imports"] {
  const text = fs.readFileSync(file, "utf8");
  const out: Module["imports"] = [];
  let offset = 0;
  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    const m = /^import\s+(\S+)(?:\s+as\s+([A-Za-z_][A-Za-z0-9_]*))?\s*(?:#.*)?$/.exec(trimmed);
    if (m) {
      const raw = m[1];
      const target = raw === "Base" ? BASE : /^0x[0-9a-f]+\//.test(raw)
        ? path.join(process.env.BEND_LIB ?? path.join(os.homedir(), ".bend", "lib"), raw)
        : path.resolve(path.dirname(file), raw);
      out.push({ raw, alias: m[2] ?? "Base", target: fs.realpathSync(target), beg: offset + line.indexOf("import") });
    } else if (trimmed && !trimmed.startsWith("#")) break;
    offset += line.length + 1;
  }
  return out;
}

async function host_modules(root: string): Promise<string> {
  const book = Bend.book_nil();
  const seen = new Map<string, string | null>();
  await Bend.book_load(book, root, "", seen);
  // Stage 0's loader establishes dependency order. Recover boundaries from
  // its actual resolved realpaths and namespaces; retain repeated law/def keys.
  const metadata = new Map<string, Module>();
  for (const [file, namespace] of seen) {
    if (namespace === null) throw Error("host loader left a pending module: " + file);
    metadata.set(file, { file, namespace, imports: imports_of(file) });
  }
  const ordered: Module[] = [];
  const visited = new Set<string>();
  const visit = (file: string) => {
    if (visited.has(file)) return;
    const mod = metadata.get(file);
    if (!mod) throw Error("host loader omitted " + file);
    visited.add(file);
    mod.imports.forEach(x => visit(x.target));
    ordered.push(mod);
  };
  visit(fs.realpathSync(root));
  references.clear();
  for (const mod of ordered) {
    const aliases = mod.imports.flatMap(imp => {
      const target = metadata.get(imp.target)?.namespace;
      return target ? [{ namespace: target, alias: imp.alias }] : [];
    }).sort((a, b) => b.namespace.length - a.namespace.length);
    references.set(mod.file, key => {
      for (const { namespace, alias } of aliases) {
        if (key.startsWith(namespace + ".")) return alias + key.slice(namespace.length);
      }
      return mod.namespace && key.startsWith(mod.namespace + ".")
        ? key.slice(mod.namespace.length + 1) : key;
    });
  }
  const baseKeys = metadata.has(BASE) ? (() => {
    const baseBook = Bend.book_nil();
    Bend.parse_book(baseBook, path.dirname(BASE) + "/", fs.readFileSync(BASE, "utf8"));
    return new Set(baseBook.order);
  })() : new Set<string>();
  const namespaceOwners = ordered.filter(mod => mod.namespace !== "")
    .sort((a, b) => b.namespace.length - a.namespace.length);
  const moduleExprs = ordered.map(mod => {
    const keys = book.order.filter(key => {
      if (mod.file === BASE) return baseKeys.has(key);
      if (baseKeys.has(key)) return false;
      const owner = namespaceOwners.find(x => key.startsWith(x.namespace + "."));
      return owner === undefined ? mod.namespace === "" : owner.file === mod.file;
    });
    const defs = keys.map((key, i) => {
      const local = mod.namespace ? key.slice(mod.namespace.length + 1) : key;
      return declaration(book, key, local, mod.file, keys.lastIndexOf(key) !== i);
    });
    const imports = mod.imports.map(imp => ctor("ModuleImport", str(imp.raw), str(imp.alias), span(mod.file, imp.beg, imp.beg + imp.raw.length)));
    return `Loader.LoadedModule{${str(mod.namespace)}, ${ctor("Module", str(mod.file), `[${imports.join(", ")}]`, `[${defs.join(", ")}]`)}}`;
  });
  return `[${moduleExprs.join(", ")}]`;
}

function run(args: string[], cwd: string): void {
  const got = child.spawnSync(process.execPath, args, { cwd, encoding: "utf8", maxBuffer: 1 << 27,
    env: { ...process.env, BEND_NO_TELEMETRY: "1" } });
  if (got.error || got.status !== 0) throw Error(`${args.join(" ")}\n${got.stdout ?? ""}${got.stderr ?? ""}${got.error ?? ""}`);
}

export async function compile_hybrid(input: string, output: string): Promise<void> {
  const file = fs.realpathSync(input);
  const target = path.resolve(output);
  const tmp = fs.mkdtempSync(path.join(path.dirname(target), ".bend-hybrid-"));
  const trace = (stage: string) => {
    const file = process.env.BEND_HYBRID_TRACE_FILE;
    if (file) fs.appendFileSync(file, JSON.stringify({stage, input, elapsedMs: performance.now(), ...process.memoryUsage()}) + "\n");
  };
  try {
    trace("host-modules-before");
    const modules = await host_modules(file);
    trace("host-modules-after");
    const data = path.join(tmp, "input.bend");
    const runner = path.join(tmp, "runner.bend");
    const emitted = path.join(tmp, "emitted.js");
    fs.writeFileSync(data, `import ${path.join(ROOT, "bend2/selfhost/ast.bend")} as AST\nimport ${path.join(ROOT, "bend2/selfhost/loaded_module.bend")} as Loader\ndef modules() -> List<&2, Loader.LoadedModule>:\n  ${modules}\n`);
    fs.writeFileSync(runner, `import Base\nimport ./input.bend as Input\nimport ${path.join(ROOT, "bend2/selfhost/hybrid_driver.bend")} as Driver\ndef main() -> IO(U32):\n  Driver.compile(Input.modules(), ${str(emitted)})\n`);
    trace("runner-compile-before");
    run([path.join(ROOT, "bend2/main.ts"), runner, "-o", path.join(tmp, "runner.js")], tmp);
    trace("runner-compile-after");
    run([path.join(tmp, "runner.js")], tmp);
    trace("runner-execute-after");
    if (!fs.existsSync(emitted)) throw Error("selfhost JS emitter did not write " + emitted);
    fs.renameSync(emitted, target);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

if (import.meta.main) {
  const [input, option, output] = process.argv.slice(2);
  if (!input || option !== "-o" || !output || process.argv.length !== 5 || !output.endsWith(".js")) {
    console.error("usage: bun gates/hybrid.ts <source.bend> -o <output.js> (HYBRID, not PURE)");
    process.exit(2);
  }
  try { await compile_hybrid(input, output); }
  catch (error) { console.error("HYBRID: " + String(error)); process.exit(1); }
}
