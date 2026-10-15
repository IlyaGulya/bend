#!/usr/bin/env bun
/** Incremental exact-source candidate checking, never a whole-parser verdict.
 * Native loading is restricted to the dependency slice; raw Body graph parsing
 * does not flatten or eagerly load any unrelated candidate function.
 */
import { createHash, randomUUID } from "node:crypto";
import { existsSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { dirname, posix, resolve } from "node:path";
import * as B from "../bend2/bend.ts";
import { guardHeavyGate } from "./heavy_gate.ts";
import { readParserGraph, type ParserGraph } from "./parser_full_graph.ts";
import { SourceDeclarations } from "./parser_full_declarations.ts";

const selfhost = resolve(import.meta.dir, "../bend2/selfhost");
const defaultRoots = ["u32_bit", "u32_bits", "u32_literal", "syntax_word_value_go"];
const sha256 = (source: string) => createHash("sha256").update(source).digest("hex");
type Declaration = { name: string; kind: string; start: number; end: number; text: string };
type ParsedSource = { graph: ParserGraph; symbol: (name: string) => string };
export type SliceOptions = {
  candidate: string;
  source?: string;
  definitions?: string[];
  baselineSource?: string;
  includeDependents?: boolean;
};
export type ParserSlice = {
  text: string;
  roots: string[];
  requestedRoots: string[];
  rootMapping: Record<string, string[]>;
  closure: string[];
  retainedDeclarations: { name: string; kind: string; start: number; end: number; sha256: string }[];
  dependencyEdges: Record<string, string[]>;
  sourceSha256: string;
  generatedSha256: string;
  exactTextSliceSha256: string;
  baselineSourceSha256: string | null;
  changedCanonicalDefinitions: string[];
  removedCanonicalDefinitions: string[];
  candidatePath: string;
  sourcePath: string;
  baselineSourcePath: string | null;
  retainedImports: string[];
  importedDeclarations: string[];
};

/** Reuse SourceDeclarations' metadata association, retaining repeated law/def
 * names as separate original blocks instead of collapsing them in its map. */
function declarations(source: string): Declaration[] {
  const headers = [...source.matchAll(/^(def|type|law)\s+([A-Za-z_]\w*)\b/gm)];
  const metadata = new SourceDeclarations(source);
  const starts = headers.map(header => {
    const start = header.index!, row = metadata.declarations.get(header[2]!);
    if (row?.start === start) return start - row.prefix.length;
    // A law followed by a same-name implementation is legal native syntax.
    // Ask the existing association helper about that original prefix only.
    const prefix = source.slice(0, start + header[0].length);
    const own = new SourceDeclarations(prefix).declarations.get(header[2]!);
    if (!own) throw Error("Missing declaration metadata: " + header[2]);
    return start - own.prefix.length;
  });
  return headers.map((header, index) => {
    const start = starts[index]!, end = starts[index + 1] ?? source.length;
    return { name: header[2]!, kind: header[1]!, start, end, text: source.slice(start, end) };
  });
}

/** readParserGraph's existing API anchors imports in selfhost. Only for a
 * candidate elsewhere, point analysis imports at the SAME real module files.
 * Restore surface namespaces when reading its AST; emitted bytes are untouched.
 * Hash-package and originally absolute imports retain their native namespaces.
 */
async function parseSource(source: string, directory: string): Promise<ParsedSource> {
  const namespaces: [string, string][] = [];
  const analysis = source.replace(/^import\s+(\S+)\s+as\s+([A-Za-z_]\w*)\s*(?:#.*)?$/gm,
    (line, path: string, alias: string) => {
      const relative = posix.normalize(path);
      if (directory === selfhost && !line.includes("#")) return line;
      if (relative.startsWith("/") || /^0x[0-9a-f]+\//.test(relative)) {
        return `import ${relative} as ${alias}`;
      }
      const absolute = resolve(directory, relative);
      // A graph-analysis rewrite must never silently point at another module.
      realpathSync(absolute);
      namespaces.push([posix.dirname(absolute), posix.dirname(relative)]);
      return `import ${absolute} as ${alias}`;
    });
  // Imported modules can themselves import siblings. Native namespaces follow
  // their normalized path, so rebasing the whole module directory preserves it.
  namespaces.sort((a, b) => b[0].length - a[0].length);
  const symbol = (name: string): string => {
    for (const [absolute, relative] of namespaces) {
      if (name.startsWith(absolute + "/")) return posix.normalize(relative + "/" + name.slice(absolute.length + 1));
    }
    return name;
  };
  return { graph: await readParserGraph(analysis), symbol };
}

/** All first-order AST children, including signatures and constructor patterns.
 * There is no normalization, reference unfolding, body_flatten, or substitution.
 */
function references(value: unknown, symbol: (name: string) => string): Set<string> {
  const result = new Set<string>(), seen = new WeakSet<object>(), pending = [value];
  while (pending.length) {
    const node = pending.pop();
    if (!node || typeof node !== "object" || seen.has(node)) continue;
    seen.add(node);
    if (Array.isArray(node)) { pending.push(...node); continue; }
    const object = node as Record<string, unknown>;
    if (["Ref", "ADT", "Ctr", "PCtr", "Mat"].includes(String(object.$)) && typeof object.k === "string") {
      result.add(symbol(object.k));
    }
    for (const [key, child] of Object.entries(object)) if (key !== "s") pending.push(child);
  }
  return result;
}

function parsedFingerprint(parsed: ParsedSource, name: string): string {
  const signature = parsed.graph.signatures.get(name), body = parsed.graph.bodies.get(name);
  if (!signature || !body) throw Error("Missing parsed canonical definition: " + name);
  // Parameter spans are tuple elements rather than `s` properties. Exclude
  // those explicitly; keep quantities, binder order, indices, types and body.
  return JSON.stringify({
    parameters: signature.parameters.map(([quantity, key, index, type]) => [quantity, key, index, type]),
    result: signature.result, body,
  }, (key, value) => {
    if (key === "s") return undefined;
    if (key === "k" && typeof value === "string") return parsed.symbol(value);
    return value;
  });
}

export async function emitParserSlice(options: SliceOptions): Promise<ParserSlice> {
  const candidatePath = resolve(options.candidate);
  const sourcePath = resolve(options.source ?? resolve(selfhost, "parser.bend"));
  const source = readFileSync(sourcePath, "utf8"), candidate = readFileSync(candidatePath, "utf8");
  const rows = declarations(candidate);
  if (!rows.length) throw Error("Candidate has no source declarations");
  const parsed = await parseSource(candidate, dirname(candidatePath)), graph = parsed.graph;
  const localNames = new Set(rows.map(row => row.name));
  const functionNames = new Set(graph.definitions);
  const constructorOwners = new Map<string, string>();
  const originalNames = new Map<string, string>();
  for (const [name, declaration] of Object.entries(graph.parserBook.tlds)) {
    const normalized = parsed.symbol(name);
    originalNames.set(normalized, name);
    if (declaration.$ === "ADT") {
      for (const constructor of declaration.c) constructorOwners.set(parsed.symbol(constructor.k), normalized);
    }
  }
  const dependencies = new Map<string, Set<string>>();
  const externalDependencies = new Map<string, Set<string>>();
  const unresolved = new Map<string, string[]>();
  for (const name of localNames) {
    const symbols = new Set<string>();
    const add = (value: unknown) => { for (const reference of references(value, parsed.symbol)) symbols.add(reference); };
    const body = graph.bodies.get(name), signature = graph.signatures.get(name);
    if (body) add(body);
    if (signature) {
      for (const parameter of signature.parameters) add(parameter[3]);
      add(signature.result);
    }
    // The graph's body edges alone omit signature references and constructor
    // owners. Include the real parsed type/law declaration AST as well.
    const native = graph.parserBook.tlds[originalNames.get(name) ?? name];
    if (native) {
      add(B.term_lower(native.T));
      if (native.$ === "ADT") for (const constructor of native.c) add(B.term_lower(constructor.T));
    }
    for (const edge of graph.edges[name] ?? []) symbols.add(edge);
    const targets = new Set<string>(), external = new Set<string>(), unknown: string[] = [];
    for (const reference of symbols) {
      const target = constructorOwners.get(reference) ?? reference;
      if (localNames.has(target)) targets.add(target);
      else if (!originalNames.has(target) && !graph.parserBook.tmps[reference]) unknown.push(reference);
      else external.add(target);
    }
    dependencies.set(name, targets);
    externalDependencies.set(name, external);
    unresolved.set(name, unknown);
  }

  const changedCanonicalDefinitions: string[] = [], removedCanonicalDefinitions: string[] = [];
  const baselineSourcePath = options.baselineSource ? resolve(options.baselineSource) : null;
  let baselineSourceSha256: string | null = null;
  if (baselineSourcePath) {
    const baselineSource = readFileSync(baselineSourcePath, "utf8");
    baselineSourceSha256 = sha256(baselineSource);
    // Baselines are source snapshots, often archived outside the project.
    // Resolve their unchanged relative imports in the current source directory.
    const current = await parseSource(source, dirname(sourcePath));
    const baseline = await parseSource(baselineSource, dirname(sourcePath));
    const oldNames = new Set(baseline.graph.definitions);
    for (const name of current.graph.definitions) {
      if (!oldNames.has(name) || parsedFingerprint(current, name) !== parsedFingerprint(baseline, name)) {
        changedCanonicalDefinitions.push(name);
      }
    }
    for (const name of baseline.graph.definitions) if (!current.graph.bodies.has(name)) removedCanonicalDefinitions.push(name);
  }
  const requestedRoots = [...new Set(options.definitions ?? (baselineSourcePath ? [] : defaultRoots))];
  const rootMapping: Record<string, string[]> = {};
  const roots = new Set<string>();
  for (const name of new Set([...requestedRoots, ...changedCanonicalDefinitions])) {
    const mapped = [name, "step_" + name].filter(candidateName => functionNames.has(candidateName));
    if (!mapped.length) throw Error("No generated definition or step_ mapping for root: " + name);
    rootMapping[name] = mapped;
    for (const target of mapped) roots.add(target);
  }
  if (options.includeDependents && baselineSourcePath && changedCanonicalDefinitions.length) {
    // AST reverse reachability can intentionally broaden baseline-driven scope
    // to generated step functions/continuations that consume a changed helper.
    const reverse = new Map<string, string[]>();
    for (const [caller, targets] of dependencies) for (const target of targets) {
      const callers = reverse.get(target) ?? [];
      callers.push(caller); reverse.set(target, callers);
    }
    for (const name of changedCanonicalDefinitions) {
      const reached = new Set(rootMapping[name]), queue = [...reached];
      for (let index = 0; index < queue.length; index++) for (const caller of reverse.get(queue[index]!) ?? []) {
        if (!reached.has(caller)) { reached.add(caller); queue.push(caller); }
      }
      for (const reachedName of reached) if (reachedName.startsWith("step_") || reachedName.startsWith("feedback_resume_") || reachedName.startsWith("feedback_consumer_")) {
        roots.add(reachedName);
        if (!rootMapping[name]!.includes(reachedName)) rootMapping[name]!.push(reachedName);
      }
    }
  }
  if (!roots.size) throw Error("No candidate roots selected; provide --definitions (baseline has no changed current definitions)");

  const closure = new Set<string>(), pending = [...roots];
  while (pending.length) {
    const name = pending.pop()!;
    if (closure.has(name)) continue;
    closure.add(name);
    const missing = unresolved.get(name);
    if (missing?.length) throw Error(`Unresolved AST dependency in ${name}: ${missing.join(", ")}`);
    for (const target of dependencies.get(name) ?? []) pending.push(target);
  }
  // Retain exactly the original source ordering, including law/implementation
  // pairs and leading @unsafe metadata. Never topologically reorder a slice.
  const retained = rows.filter(row => closure.has(row.name));
  const firstStart = rows[0]!.start;
  const external = new Set([...closure].flatMap(name => [...externalDependencies.get(name) ?? []]));
  const retainedImports: string[] = [];
  const prelude = candidate.slice(0, firstStart).replace(/^import\s+(\S+)(?:\s+as\s+\S+)?[^\n]*(?:\n|$)/gm, (line, path: string) => {
    const namespace = posix.normalize(path).replace(/\.bend$/, "");
    const needed = path === "Base" || [...external].some(name => name === namespace || name.startsWith(namespace + "."));
    if (needed) retainedImports.push(line.trimEnd());
    return needed ? line : "";
  });
  const text = prelude + retained.map(row => row.text).join("");
  const importedNamespaces = [...candidate.slice(0, firstStart).matchAll(/^import\s+(\S+)/gm)]
    .map(match => posix.normalize(match[1]!).replace(/\.bend$/, "")).filter(namespace => namespace !== "Base");
  return {
    text, roots: [...roots].sort(), requestedRoots, rootMapping,
    closure: [...new Set(retained.map(row => row.name))],
    retainedDeclarations: retained.map(({ name, kind, start, end, text }) => ({ name, kind, start, end, sha256: sha256(text) })),
    dependencyEdges: Object.fromEntries([...dependencies].filter(([name]) => closure.has(name)).map(([name, targets]) => [name, [...targets].sort()])),
    sourceSha256: sha256(source), generatedSha256: sha256(candidate), exactTextSliceSha256: sha256(text),
    baselineSourceSha256, changedCanonicalDefinitions, removedCanonicalDefinitions,
    candidatePath, sourcePath, baselineSourcePath,
    retainedImports,
    importedDeclarations: graph.parserBook.order.filter(name => {
      const normalized = parsed.symbol(name);
      if (localNames.has(normalized)) return false;
      const namespace = importedNamespaces.find(namespace => normalized.startsWith(namespace + "."));
      return namespace === undefined || retainedImports.some(line =>
        posix.normalize(/^import\s+(\S+)/.exec(line)![1]!).replace(/\.bend$/, "") === namespace);
    }).map(parsed.symbol),
  };
}

const usage = `Usage: bun evals/parser_full_slice_check.ts [candidate.bend] [options]
  --candidate PATH       Generated source (default parser_full_generated_fuel.bend)
  --source PATH          Canonical source (default selfhost/parser.bend)
  --definitions A,B,...  Exact generated/canonical root names (default literal family A)
  --baseline-source PATH  Add changed canonical Body/signature roots
  --emit PATH            Keep exact slice beside candidate (same directory required)
  --include-dependents   Also check reverse-reachable generated consumers
  --report PATH          Write full JSON result; compact summary goes to stdout
  --memory-mib N, --rss-mib N  Heavy-gate limits, not slice/root arguments
Imports and declarations are byte-identical to the candidate. Baseline imports
resolve beside --source. PASS is incremental dependency-slice checking only,
NOT whole-book checking, generation validation, or parser semantic equivalence.`;

function argumentsOf(args: string[]): { options: SliceOptions; emit?: string; report?: string } {
  let candidate: string | undefined, source: string | undefined, definitions: string[] | undefined;
  let baselineSource: string | undefined, emit: string | undefined, report: string | undefined;
  let includeDependents = false;
  for (let index = 0; index < args.length; index++) {
    const argument = args[index]!;
    if (argument === "--") continue;
    if (argument === "--include-dependents") { includeDependents = true; continue; }
    if (!argument.startsWith("--")) {
      if (candidate) throw Error("Unexpected positional argument: " + argument);
      candidate = argument; continue;
    }
    const equals = argument.indexOf("="), key = equals < 0 ? argument : argument.slice(0, equals);
    const value = equals < 0 ? args[++index] : argument.slice(equals + 1);
    if (!value || value.startsWith("--")) throw Error("Missing value for " + key);
    switch (key) {
      case "--candidate": candidate = value; break;
      case "--source": source = value; break;
      case "--definitions":
        definitions = value.split(",").map(name => name.trim());
        if (definitions.some(name => !/^[A-Za-z_]\w*$/.test(name))) throw Error("Invalid root list: " + value);
        break;
      case "--baseline-source": baselineSource = value; break;
      case "--emit": emit = value; break;
      case "--report": report = value; break;
      case "--memory-mib": case "--rss-mib": break;
      default: throw Error("Unknown option: " + key);
    }
  }
  return { options: { candidate: candidate ?? resolve(selfhost, "parser_full_generated_fuel.bend"), source, definitions, baselineSource, includeDependents }, emit, report };
}

async function main(): Promise<void> {
  if (process.argv.slice(2).some(argument => argument === "--help" || argument === "-h")) {
    console.log(usage); return;
  }
  await guardHeavyGate(import.meta.path, { label: "parser-slice" });
  const started = performance.now();
  let reportPath: string | undefined, temporary: string | undefined;
  let slice: ParserSlice | undefined, attemptedDeclarations: string[] = [];
  try {
    const cli = argumentsOf(process.argv.slice(2));
    const inputPaths = [cli.options.candidate, cli.options.source ?? resolve(selfhost, "parser.bend"), cli.options.baselineSource]
      .filter((path): path is string => path !== undefined).map(path => realpathSync(resolve(path)));
    const outputs = [cli.emit, cli.report].filter((path): path is string => path !== undefined)
      .map(path => existsSync(resolve(path)) ? realpathSync(resolve(path)) : resolve(path));
    if (outputs.some(path => inputPaths.includes(path))) throw Error("Refusing to overwrite input source with slice/report output");
    if (new Set(outputs).size !== outputs.length) throw Error("--emit and --report must be different files");
    reportPath = cli.report ? resolve(cli.report) : undefined;
    if (cli.emit && dirname(resolve(cli.emit)) !== dirname(resolve(cli.options.candidate))) {
      throw Error("--emit must be beside the candidate to preserve relative import namespaces");
    }
    slice = await emitParserSlice(cli.options);
    if (cli.emit) {
      const emitted = resolve(cli.emit);
      writeFileSync(emitted, slice.text);
    }
    temporary = resolve(dirname(slice.candidatePath), `parser_full_slice_${randomUUID()}.bend`);
    writeFileSync(temporary, slice.text);
    const book = B.book_nil();
    await B.book_load(book, temporary, "", new Map());
    slice.importedDeclarations = book.order.filter(name => !slice!.closure.includes(name));
    attemptedDeclarations = [...book.order];
    B.book_valid(book);
    result("PASS", undefined, attemptedDeclarations);
  } catch (error) {
    const message = error && typeof error === "object" && "$" in error && error.$ === "Err"
      ? B.err_show(error as B.Err) : String(error);
    result("FAIL", message, []);
    process.exitCode = 1;
  } finally {
    if (temporary) rmSync(temporary, { force: true });
  }
  function result(status: "PASS" | "FAIL", error: string | undefined, checkedDeclarations: string[]): void {
    const { text: _text, ...metadata } = slice ?? { text: "" };
    const report = { ...metadata, status, scope: "incremental dependency slice; NOT whole-book",
      wholeBook: false, checker: "unchanged B.book_load + B.book_valid(book), complete emitted slice and native imports",
      exactOriginalDeclarationText: slice !== undefined, originalCandidateOrder: slice !== undefined,
      checkedDeclarations, attemptedDeclarations, checkedDeclarationCount: checkedDeclarations.length,
      elapsedSeconds: (performance.now() - started) / 1000, error };
    const json = JSON.stringify(report, null, 2) + "\n";
    if (reportPath) writeFileSync(reportPath, json);
    console.log(JSON.stringify({status,scope:report.scope,wholeBook:false,roots:slice?.roots,closure:slice?.closure,
      changedCanonicalDefinitions:slice?.changedCanonicalDefinitions,sourceSha256:slice?.sourceSha256,
      generatedSha256:slice?.generatedSha256,checkedDeclarationCount:report.checkedDeclarationCount,
      elapsedSeconds:report.elapsedSeconds,reportPath,error}));
  }
}

if (import.meta.main) await main();
