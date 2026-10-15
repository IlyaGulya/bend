import type * as B from "../bend2/bend.ts";
import { createHash, randomUUID } from "node:crypto";
import { readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

export type Boundary = { beg: number; end: number; kind: string; key: string };
export type Parameter = [B.Quant, string, number, B.LTerm, B.Span];
export type LawClause = [boolean, B.Quant, string, number, B.LTerm, B.Span];
export type RawDeclaration = Boundary & {
  unsafe?: boolean;
  template?: boolean;
  templateCount?: number;
  completesLaw?: boolean;
  signature?: { parameters?: Parameter[]; result?: B.LTerm; declaredType?: B.HTerm };
  vars?: B.PVar[];
  body?: B.Body;
  nativeImports?: string[];
  parameters?: Parameter[];
  kindTerm?: B.LTerm;
  constructors?: { key: string; fields: Parameter[]; type: B.HTerm }[];
  clauses?: LawClause[];
  lawBody?: B.Body;
  lawType?: B.LTerm;
  // Includes parenthesized terms and lambda/rewrite blocks, even Reply bodies.
  blocks: B.Body[];
};
export type SourceImport = Boundary & {
  path: string; alias: string; namespace: string; resolved?: string;
};
export type SourceOracleInput = { requested: string; file: string; sha256: string; sourceSha256: string };
export type SourceOracleResult = {
  accepted: boolean;
  file: string;
  source: string;
  boundaries: Boundary[];
  declarations: RawDeclaration[];
  imports: SourceImport[];
  error?: unknown;
  failure?: { category: "parser-or-loader" | "observation-seam"; file?: string; pos?: number };
  observation: { stage0Sha256: string; edits: { label: string; occurrences: number }[] };
  exclusions: string[];
  /** Exact loader inputs, including repeated loads through distinct paths. */
  inputFiles: SourceOracleInput[];
  loadContexts: { file: string; namespace: string; aliases: Record<string,string>; sourceSha256: string }[];
  /** Opt-in normalization only. Accessing a resulting Def.v replays precisely
   * stage0's Body -> core -> HOAS/indexed bridge, never checker/evaluation. */
  normalizationBook(): B.Book;
};

type Stage0 = typeof B & { __setSourceOracleObserver(observer: SourceOracleObserver): void };
type Context = { file: string; source: string; parsed: string; namespace: string; aliases: Record<string,string> };
type Draft = Omit<RawDeclaration, "end"> & { end?: number };
export type SourceOracleObserver = {
  source(file: string, original: string): string;
  enter(file: string, source: string, parsed: string, namespace: string, aliases: Record<string, string>): void;
  load(file: string, span?: B.Span): void;
  header(text: string, line: string, index: number, lines: string[], match: RegExpMatchArray,
    namespace: string, aliases: Record<string, string>): void;
  begin(p: B.Parse): void;
  finish(p: B.Parse, kind: string): void;
  signature(p: B.Parse, key: string, parameters: Parameter[], result: B.LTerm, unsafe: boolean, templates: number): void;
  completion(p: B.Parse, key: string, def: B.Def, vars: B.PVar[], unsafe: boolean): void;
  body(p: B.Parse, book: B.Book, key: string, def: B.Def, vars: B.PVar[], body: B.Body): B.HTerm;
  native(p: B.Parse, key: string, def: B.Def): void;
  block(p: B.Parse, body: B.Body): B.LTerm;
  constructor(p: B.Parse, key: string, fields: Parameter[], type: B.HTerm): void;
  datatype(p: B.Parse, key: string, parameters: Parameter[], kind: B.LTerm): void;
  law(p: B.Parse, key: string, clauses: LawClause[], type: B.LTerm, templates: number): void;
};

class ObservationSeamError extends Error {
  constructor(readonly file: string | undefined, readonly pos: number, message: string) {
    super(message);
    this.name = "ObservationSeamError";
  }
}

type InstrumentedStage0 = { module: Promise<Stage0>; observationTail: Promise<void> };
const instrumentedStage0Modules = new Map<string, InstrumentedStage0>();

function detachedObservation(): never {
  throw new ObservationSeamError(undefined, 0, "Stage0 observation hook invoked outside its sourceOracle window");
}
const detachedObserver: SourceOracleObserver = {
  source: detachedObservation, enter: detachedObservation, load: detachedObservation,
  header: detachedObservation, begin: detachedObservation, finish: detachedObservation,
  signature: detachedObservation, completion: detachedObservation, body: detachedObservation,
  native: detachedObservation, block: detachedObservation, constructor: detachedObservation,
  datatype: detachedObservation, law: detachedObservation,
};

async function loadInstrumentedStage0(file: string, source: string): Promise<Stage0> {
  // A unique specifier is needed only for a new source/instrumentation instance.
  // Keeping it beside stage0 preserves BASE_BEND and all relative import paths.
  const temporary = resolve(dirname(file), `.bootstrap_source_oracle_${randomUUID()}.ts`);
  try {
    writeFileSync(temporary, source, { flag: "wx" });
    const module = await import(temporary) as Stage0;
    module.__setSourceOracleObserver(detachedObserver);
    return module;
  } finally {
    rmSync(temporary, { force: true });
  }
}

function instrumentedStage0(file: string, source: string, provenance: string): InstrumentedStage0 {
  const cached = instrumentedStage0Modules.get(provenance);
  if (cached) return cached;
  const entry: InstrumentedStage0 = {
    module: loadInstrumentedStage0(file, source).catch(error => {
      if (instrumentedStage0Modules.get(provenance) === entry) instrumentedStage0Modules.delete(provenance);
      throw error;
    }),
    observationTail: Promise.resolve(),
  };
  instrumentedStage0Modules.set(provenance, entry);
  return entry;
}

async function acquireObservation(entry: InstrumentedStage0): Promise<() => void> {
  const preceding = entry.observationTail;
  let release!: () => void;
  entry.observationTail = new Promise<void>(resolve => { release = resolve; });
  await preceding;
  return release;
}

/** Syntax inventory, not native/checker acceptance. The only parser is a
 * temporary, invertibly instrumented copy of the actual stage0 module, beside
 * that module so BASE_BEND is unchanged. book_load handles the actual headers
 * and dependency namespaces, from file's directory; no declaration regex is
 * used. Import lines become equal-width whitespace, preserving source offsets.
 *
 * Top-level bodies are observed before flattening; normalization replays the
 * exact native flatten/lower/higher bridge lazily. Nested blocks run that same
 * native bridge at their original parser seam, without excluding any Body kind.
 *
 * Nothing calls book_valid, term_wnf, the compiler, or a target definition.
 */
export async function sourceOracle(file: string, source: string, options: { preloadBase?: boolean; recordInputs?: boolean } = {}): Promise<SourceOracleResult> {
  const rootFile = realpathSync(resolve(file));
  const stage0File = resolve(import.meta.dir, "../bend2/bend.ts");
  const original = readFileSync(stage0File, "utf8");
  const changes: { label: string; before: string; after: string; occurrences: number }[] = [];
  let observed = original;
  function replace(label: string, before: string, after: string, occurrences = 1): void {
    const parts = observed.split(before);
    if (parts.length - 1 !== occurrences) {
      throw new ObservationSeamError(stage0File, 0, `Stage0 observation anchor changed: ${label}`);
    }
    observed = parts.join(after);
    changes.push({ label, before, after, occurrences });
  }
  const declarationHook = "      __sourceOracleObserver.finish(p, ";
  // These are observation additions to exact existing statements, not a copied
  // declaration grammar. Anchor drift is an infrastructure failure, never PASS.
  replace("load-source", '  const text  = fs.readFileSync(real, "utf8");',
    '  const text  = __sourceOracleObserver.source(real, fs.readFileSync(real, "utf8"));');
  replace("load-file", '  const real = await book_file(book, file, spn);',
    '  const real = await book_file(book, file, spn);\n  __sourceOracleObserver.load(real, spn);');
  replace("header-offsets", '    body[i] = "";',
    '    __sourceOracleObserver.header(text, line, i, lines, m, ns, al);\n    body[i] = " ".repeat(lines[i].length);');
  replace("load-context", '  parse_book(book, dir, body.join("\\n"), ns, al);',
    '  __sourceOracleObserver.enter(real, text, body.join("\\n"), ns, al);\n  parse_book(book, dir, body.join("\\n"), ns, al);');
  replace("declaration-start", '    p.frs = 0;',
    '    p.frs = 0;\n    __sourceOracleObserver.begin(p);');
  replace("unsafe-boundary", '      parse_def(p, true);\n      continue;',
    '      parse_def(p, true);\n' + declarationHook + '"def");\n      continue;');
  replace("definition-boundary", '      parse_def(p, false);\n      continue;',
    '      parse_def(p, false);\n' + declarationHook + '"def");\n      continue;');
  replace("definition-signature", '    def = book.tlds[k] = { $: "Def", n: tele.length, x: tk.length, T: term_higher(tele_bind(tele, parse_term(p))), v: null, m: p.ns };',
    '    const ret = parse_term(p);\n    __sourceOracleObserver.signature(p, k, tele, ret, un, tk.length);\n    def = book.tlds[k] = { $: "Def", n: tele.length, x: tk.length, T: term_higher(tele_bind(tele, ret)), v: null, m: p.ns };');
  replace("law-completion-signature", '    def.n = tele.length;',
    '    def.n = tele.length;\n    __sourceOracleObserver.completion(p, k, def, tele.map((cell): PVar => ({ $: "PVar", k: cell[1], i: cell[2], q: Lone(), s: cell[4] })), un);');
  replace("definition-body-normalization", '    def.v = term_higher(term_lower(term_higher(body_flatten(parse_body(p), vars, () => p.frs++))));',
    '    def.v = __sourceOracleObserver.body(p, book, k, def, vars, parse_body(p));');
  replace("native-body", '  book.order.push(k);\n}\n\nexport function parse_book',
    '  if (def.i) __sourceOracleObserver.native(p, k, def);\n  book.order.push(k);\n}\n\nexport function parse_book');
  replace("inner-block-normalization", '  return body_flatten(b, [], () => p.frs++);',
    '  return __sourceOracleObserver.block(p, b);');
  replace("parenthesized-body-normalization", '  const out = body_flatten(b, [], () => p.frs++);',
    '  const out = __sourceOracleObserver.block(p, b);');
  replace("constructor-fields", '        cs.push(ctr);',
    '        __sourceOracleObserver.constructor(p, c, fs, ctr.T);\n        cs.push(ctr);');
  replace("datatype-boundary", '      book.order.push(k);\n      continue;\n    }\n    if (parse_word(p, "law"))',
    '      __sourceOracleObserver.datatype(p, k, params, K);\n      book.order.push(k);\n' + declarationHook + '"type");\n      continue;\n    }\n    if (parse_word(p, "law"))');
  replace("law-ast", '      const n = cls.findIndex((c) => !c[0]);',
    '      __sourceOracleObserver.law(p, k, cls, T, tc);\n      const n = cls.findIndex((c) => !c[0]);');
  replace("law-boundary", '      book.tlds[k] = { $: "Def", n: n < 0 ? cls.length : n, T: term_higher(T), v: null, x: tc, m: p.ns };\n      book.order.push(k);\n      continue;',
    '      book.tlds[k] = { $: "Def", n: n < 0 ? cls.length : n, T: term_higher(T), v: null, x: tc, m: p.ns };\n      book.order.push(k);\n' + declarationHook + '"law");\n      continue;');
  // Mechanical inverse proof: retain neither a patched production module nor a
  // guessed equivalent parser if any observation edit is not reversible.
  let restored = observed;
  for (const change of [...changes].reverse()) restored = restored.split(change.after).join(change.before);
  if (restored !== original) throw new ObservationSeamError(stage0File, 0, "Non-invertible stage0 observation edits");
  observed += '\nimport type { SourceOracleObserver } from "../evals/bootstrap_source_oracle.ts";\nlet __sourceOracleObserver: SourceOracleObserver;\nexport function __setSourceOracleObserver(observer: SourceOracleObserver): void { __sourceOracleObserver = observer; }\n';
  // Original bytes, instrumented bytes and the complete reversible edit ledger
  // all participate: changing either source or observation provenance creates
  // a new runtime module, never a cached parsed book or AST.
  const provenance = createHash("sha256").update(JSON.stringify([stage0File, original, observed, changes])).digest("hex");

  const contexts: Context[] = [];
  const drafts = new WeakMap<B.Parse, Draft>();
  const declarations: RawDeclaration[] = [];
  const imports: SourceImport[] = [];
  const boundaries: Boundary[] = [];
  const loadedImports = new Map<string, string>();
  const inputFiles: SourceOracleInput[] = [];
  const deferred = new Map<B.Def, () => B.HTerm>();
  let activeFile: string | undefined = rootFile, activePos: number | undefined;
  let module: Stage0;
  let book: B.Book;
  let rootReal: string;
  let normalized = false;
  const context = (p: B.Parse) => contexts.findLast(c => c.parsed === p.str && c.namespace === p.ns);
  const observer: SourceOracleObserver = {
    source(at, text) {
      if (options.recordInputs) {
        const input = inputFiles.findLast(input => input.requested === resolve(at));
        if (!input || input.sourceSha256 !== createHash("sha256").update(text).digest("hex"))
          throw new ObservationSeamError(at, 0, "Loader source changed after provenance observation");
      }
      return realpathSync(at) === rootReal ? source : text;
    },
    enter(at, text, parsed, namespace, aliases) {
      activeFile = resolve(at);
      contexts.push({ file: activeFile, source: text, parsed, namespace, aliases });
      if (activeFile === rootFile && namespace === "") for (const item of imports) {
        item.namespace = item.alias === "Base" ? "" : aliases[item.alias] ?? "";
        item.resolved = loadedImports.get(String(source.indexOf(item.path, item.beg)));
      }
    },
    load(at, span) {
      activeFile = resolve(at);
      if (options.recordInputs) {
        const bytes = readFileSync(at);
        inputFiles.push({ requested: activeFile, file: realpathSync(at),
          sha256: createHash("sha256").update(bytes).digest("hex"),
          sourceSha256: createHash("sha256").update(bytes.toString("utf8")).digest("hex") });
      }
      if (span?.file.str === source) loadedImports.set(String(span.beg), activeFile);
    },
    header(text, line, index, lines, match, namespace, aliases) {
      if (text !== source || namespace !== "") return;
      // Same positions/captures as book_load. Earlier lines have equal width.
      const lineStart = lines.slice(0, index).join("\n").length + (index ? 1 : 0);
      const pathBeg = lineStart + lines[index]!.indexOf(match[1]!);
      const beg = lineStart + lines[index]!.indexOf(line);
      const item: SourceImport = { beg, end: beg + line.length, kind: "import", key: match[2] ?? "Base",
        path: match[1]!, alias: match[2] ?? "Base", namespace: match[2] ? aliases[match[2]] ?? "" : "",
        resolved: loadedImports.get(String(pathBeg)) };
      imports.push(item);
      boundaries.push({ beg: item.beg, end: item.end, kind: item.kind, key: item.key });
    },
    begin(p) {
      activeFile = context(p)?.file;
      activePos = p.pos;
      drafts.set(p, { beg: p.pos, kind: "", key: "", blocks: [] });
    },
    finish(p, kind) {
      activeFile = context(p)?.file;
      activePos = p.pos;
      const draft = drafts.get(p);
      if (!draft || !draft.key) throw new ObservationSeamError(activeFile, p.pos, "Missing complete declaration observation");
      if (context(p)?.file !== rootFile) return;
      const declaration = { ...draft, kind, end: p.pos } as RawDeclaration;
      declarations.push(declaration);
      boundaries.push({ beg: declaration.beg, end: declaration.end, kind, key: declaration.key });
    },
    signature(p, key, parameters, result, unsafe, templates) {
      const draft = drafts.get(p);
      if (draft) Object.assign(draft, { key, unsafe, template: templates > 0, templateCount: templates,
        signature: { parameters, result } });
    },
    completion(p, key, def, vars, unsafe) {
      const draft = drafts.get(p);
      if (draft) Object.assign(draft, { key, unsafe, completesLaw: true, vars, template: def.x > 0, templateCount: def.x,
        signature: { declaredType: def.T } });
    },
    body(p, _book, key, def, vars, body) {
      const draft = drafts.get(p);
      if (draft) Object.assign(draft, { key, vars, body });
      const freshStart = p.frs;
      deferred.set(def, () => {
        let fresh = freshStart;
        return module.term_higher(module.term_lower(module.term_higher(module.body_flatten(body, vars, () => fresh++))));
      });
      // Only occupancy matters to parse_def; no evaluator sees this marker.
      return module.Hol("\0source-oracle-unflattened");
    },
    native(p, key, def) {
      const draft = drafts.get(p);
      if (draft) Object.assign(draft, { key, nativeImports: def.i?.slice() });
    },
    block(p, body) {
      drafts.get(p)?.blocks.push(body);
      return module.body_flatten(body, [], () => p.frs++);
    },
    constructor(p, key, fields, type) {
      const draft = drafts.get(p);
      if (draft) (draft.constructors ??= []).push({ key, fields, type });
    },
    datatype(p, key, parameters, kindTerm) {
      const draft = drafts.get(p);
      if (draft) Object.assign(draft, { key, parameters, kindTerm });
    },
    law(p, key, clauses, lawType, templates) {
      const draft = drafts.get(p);
      if (draft) Object.assign(draft, { key, clauses, lawType, lawBody: draft.blocks.at(-1), template: templates > 0, templateCount: templates });
    },
  };
  let accepted = false;
  let error: unknown;
  let failure: SourceOracleResult["failure"];
  try {
    rootReal = realpathSync(rootFile);
    const instance = instrumentedStage0(stage0File, observed, provenance);
    module = await instance.module;
    const release = await acquireObservation(instance);
    try {
      // book_load may suspend during dependency loading. Keep exclusive hook
      // ownership until both loads settle, queuing overlapping API calls.
      module.__setSourceOracleObserver(observer);
      book = module.book_nil();
      const seen = new Map<string, string>();
      if (options.preloadBase) await module.book_load(book, module.BASE_BEND, "", seen);
      await module.book_load(book, rootFile, "", seen);
      accepted = true;
    } finally {
      try {
        module.__setSourceOracleObserver(detachedObserver);
      } finally {
        release();
      }
    }
  } catch (caught) {
    error = caught;
    const span = (caught as { spn?: B.Span } | null)?.spn;
    const location = span && contexts.findLast(c => c.parsed === span.file.str || c.source === span.file.str);
    failure = { category: caught instanceof ObservationSeamError ? "observation-seam" : "parser-or-loader",
      file: caught instanceof ObservationSeamError ? caught.file : location?.file ?? activeFile,
      pos: caught instanceof ObservationSeamError ? caught.pos : span?.beg ?? activePos };
  }
  return {
    accepted, file: rootFile, source, boundaries, declarations, imports,
    ...(accepted ? {} : { error, failure }),
    observation: { stage0Sha256: createHash("sha256").update(original).digest("hex"),
      edits: changes.map(({ label, occurrences }) => ({ label, occurrences })) },
    inputFiles,
    loadContexts: options.recordInputs ? contexts.map(({ file, namespace, aliases, source }) => ({ file, namespace, aliases,
      sourceSha256: createHash("sha256").update(source).digest("hex") })) : [],
    exclusions: [
      "Syntax acceptance includes unchanged stage0 parser name/pattern checks and actual recursive import loading, not book_valid/native-file validation or target evaluation.",
      "Only root-file source declarations/imports enter boundaries; dependency declarations do not create root boundaries.",
      "Top-level definition Body flattening, match compilation and HOAS/indexed replay are deferred until an explicit normalizationBook().Def.v read; their errors are not parser failures.",
      "Nested term, Match and Local blocks use unchanged stage0 body_flatten at the original parser seam; none are replaced by placeholders or omitted from semantic coverage.",
      "Import-header whitespace is equal-width, so boundaries and AST spans index the supplied source in UTF-16 code units; declaration ends may include trivia up to the next token.",
      "The real file must exist. source overrides only that file's contents; dependencies are read from their real paths, and unchanged book_load retains its cycle/namespace/Hub behavior.",
      "Templates retain native declaration x/m metadata and marked application nodes; no template checker or semantic evaluator is installed.",
    ],
    normalizationBook() {
      if (!accepted) throw error;
      if (!normalized) {
        for (const [def, normalize] of deferred) {
          Object.defineProperty(def, "v", { configurable: true, enumerable: true,
            get() { return normalize(); }, set(next: B.HTerm | null) {
              deferred.delete(def);
              Object.defineProperty(def, "v", { configurable: true, enumerable: true, writable: true, value: next });
            } });
        }
        normalized = true;
      }
      return book;
    },
  };
}
