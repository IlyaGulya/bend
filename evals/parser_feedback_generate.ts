#!/usr/bin/env bun
/** Development-only, source-anchored parser lowering experiment.
 * The selected calls come from the stage-0 AST. Unsupported control contexts
 * fail before emission; no emitted branch is fixed by hand.
 */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, term_lower, term_unapply, type LTerm } from "../bend2/bend.ts";

const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");
const output = resolve(import.meta.dir, "../bend2/selfhost/parser_feedback_generated.bend");
const source = readFileSync(input, "utf8");
const expected = "adfc9b40e7af3eb06e731a4276dcafd6b3f356ed6a042616d5fa1674db57a4b7";
if (createHash("sha256").update(source).digest("hex") !== expected) {
  throw Error("Parser source differs from checkpoint 89d5cdb7");
}
const book = book_nil();
await book_load(book, input, "", new Map());
const headers = [...source.matchAll(/^def ([A-Za-z_]\w*)\((.*)\) -> (.*):$/gm)];
const defs = new Map(headers.map(match => [match[1]!, match]));
const firstDefinition = headers.map(header => book.tlds[header[1]!]).find(definition =>
  definition?.$ === "Def" && definition.v !== null);
const declarationAnchor = /^(?:type|def|law) [^\n]+/m.exec(source)?.[0];
const astSource = firstDefinition?.$ === "Def" ? firstDefinition.v?.s?.src : undefined;
if (!declarationAnchor || !astSource) throw Error("Stage-0 AST source coordinates unavailable");
const sourceOffset = source.indexOf(declarationAnchor) - astSource.indexOf(declarationAnchor);
if (astSource.indexOf(declarationAnchor) < 0 || sourceOffset < 0) throw Error("Stage-0 AST/source anchor mismatch");
function split(input: string): string[] {
  const parts: string[] = [];
  let depth = 0, start = 0, quote = "", escape = false;
  for (let i = 0; i < input.length; i++) {
    const c = input[i]!;
    if (quote) {
      if (escape) escape = false;
      else if (c === "\\") escape = true;
      else if (c === quote) quote = "";
    } else if (c === "'" || c === '"') quote = c;
    else if (input.startsWith("<>", i) || input.startsWith("=>", i) || input.startsWith("->", i)) i++;
    else if ("([{<".includes(c)) depth++;
    else if (")}]>".includes(c)) depth--;
    else if (c === "," && depth === 0) { parts.push(input.slice(start, i).trim()); start = i + 1; }
  }
  if (depth !== 0 || quote) throw Error("Unbalanced source expression: " + input);
  parts.push(input.slice(start).trim());
  return parts;
}
function declaration(name: string) {
  const match = defs.get(name);
  if (!match) throw Error("Missing source definition " + name);
  return match;
}
function block(name: string): string {
  const begin = declaration(name).index!;
  const after = source.slice(begin + 1);
  const next = /^(?:def|law|type) [A-Za-z_]/gm.exec(after);
  return source.slice(begin, next ? begin + 1 + next.index : source.length).trimEnd();
}
function params(name: string): { name: string; type: string }[] {
  return split(declaration(name)[2]!).map(part => {
    const colon = part.indexOf(":");
    if (colon < 0) throw Error("Missing parameter type in " + part);
    return { name: part.slice(0, colon).trim().replace(/^\+/, ""), type: part.slice(colon + 1).trim() };
  });
}
type Site = { caller: string; callee: string; offset: number; parent: string | null; args: LTerm[] };
const callCache = new Map<string, Site[]>();
function calls(name: string): Site[] {
  const cached = callCache.get(name);
  if (cached) return cached;
  const definition = book.tlds[name];
  if (definition?.$ !== "Def" || definition.v === null) throw Error("Missing AST definition " + name);
  const found = new Map<string, Site>();
  const visited = new WeakMap<object, Set<string>>();
  function visit(tm: LTerm, parent: string | null): void {
    const context = parent ?? "";
    const contexts = visited.get(tm);
    if (contexts?.has(context)) return;
    if (contexts) contexts.add(context);
    else visited.set(tm, new Set([context]));
    if (tm.$ === "App") {
      const [head, args] = term_unapply(tm);
      const callee = head.$ === "Ref" && defs.has(head.k) ? head.k : null;
      if (callee !== null) {
        if (head.s?.beg === undefined) throw Error("Missing source span " + name + " -> " + callee);
        const offset = head.s.beg + sourceOffset;
        if (!source.startsWith(callee + "(", offset)) throw Error("AST/source drift " + name + " -> " + callee);
        found.set(`${offset}:${callee}:${parent ?? ""}`, { caller: name, callee, offset, parent, args });
      }
      visit(head, parent);
      for (const arg of args) visit(arg, callee ?? parent);
      return;
    }
    switch (tm.$) {
      case "Lam": visit(tm.f, null); break;
      case "All": visit(tm.A, parent); visit(tm.B, parent); break;
      case "Let": tm.v.forEach(x => visit(x, parent)); visit(tm.f, parent); break;
      case "Sub": if (tm.v.$ !== "PVar" && tm.v.$ !== "PCtr") visit(tm.v as LTerm, parent); visit(tm.f, parent); break;
      case "Mat": visit(tm.h, parent); visit(tm.m, parent); break;
      case "ADT": case "Ctr": tm.x.forEach(x => visit(x, parent)); break;
      case "Typ": visit(tm.g, parent); break;
      case "Min": visit(tm.a, parent); visit(tm.b, parent); break;
      case "Eql": visit(tm.a, parent); visit(tm.b, parent); visit(tm.T, parent); break;
      case "Rwt": visit(tm.e, parent); visit(tm.p, parent); visit(tm.f, parent); break;
      case "Ann": visit(tm.x, parent); visit(tm.T, parent); break;
    }
  }
  visit(term_lower(definition.v), null);
  const result = [...found.values()].sort((a, b) => a.offset - b.offset);
  callCache.set(name, result);
  return result;
}
function invocation(text: string, offset: number, callee: string): { args: string[]; end: number } {
  if (!text.startsWith(callee + "(", offset)) throw Error("Source call mismatch " + callee);
  let depth = 0, quote = "", escaped = false;
  for (let i = offset + callee.length; i < text.length; i++) {
    const c = text[i]!;
    if (quote) {
      if (escaped) escaped = false;
      else if (c === "\\") escaped = true;
      else if (c === quote) quote = "";
    } else if (c === "'" || c === '"') quote = c;
    else if (c === "(") depth++;
    else if (c === ")" && --depth === 0) {
      return { args: split(text.slice(offset + callee.length + 1, i)), end: i + 1 };
    }
  }
  throw Error("Unclosed source call " + callee);
}
function resultLeaf(line: string): string | null {
  const trimmed = line.trim();
  if (!trimmed.startsWith("((") || !trimmed.endsWith(")")) return null;
  const outer = split(trimmed.slice(1, -1));
  if (outer.length !== 2 || !outer[0]!.startsWith("(") || !outer[0]!.endsWith(")")) return null;
  const pair = split(outer[0]!.slice(1, -1));
  return pair.length === 2 ? `FeedbackTerm{${pair[0]}, ${pair[1]}, ${outer[1]}}` : null;
}
const selected = new Set([
  "parse_do_return", "parse_do_return_scan", "parse_term", "parse_atom",
  "parse_atom_scan", "parse_do_atom", "parse_do_atom_args_result", "parse_do_atom_colon",
]);
const gateways = selected;
const ordinary = new Set<string>();
const requests = new Set<string>();
const transformed: string[] = [];
let tailRules = 0, leafRules = 0;
type Frame = { name: string; fields: { name: string; type: string; value: string }[]; resume: string };
const frames: Frame[] = [];
type Product = { type: string; left?: Product; right?: Product };
function product(type: string): Product {
  type = type.trim();
  if (type.startsWith("(")) {
    let depth = 0, closes = -1;
    for (let i = 0; i < type.length; i++) {
      if (type[i] === "(") depth++;
      if (type[i] === ")" && --depth === 0) { closes = i; break; }
    }
    if (closes === type.length - 1) return product(type.slice(1, -1));
  }
  let depth = 0;
  for (let i = type.length - 1; i >= 0; i--) {
    if (")}>".includes(type[i]!)) depth++;
    else if ("({<".includes(type[i]!)) depth--;
    else if (type[i] === "&" && depth === 0) {
      return { type, left: product(type.slice(0, i)), right: product(type.slice(i + 1)) };
    }
  }
  return { type };
}
function productFields(name: string, tree: Product): { name: string; type: string }[] {
  return tree.left && tree.right
    ? [...productFields(name + "_0", tree.left), ...productFields(name + "_1", tree.right)]
    : [{ name, type: tree.type }];
}
function productValue(name: string, tree: Product): string {
  return tree.left && tree.right
    ? `(${productValue(name + "_0", tree.left)}, ${productValue(name + "_1", tree.right)})`
    : name;
}
function requestFields(name: string) {
  return params(name).flatMap(field => productFields(field.name, product(field.type)));
}
function requestMaker(name: string): string {
  const fields = params(name);
  const products = fields.filter(field => product(field.type).left);
  const constructor = `Request_${name}{${requestFields(name).map(field => field.name).join(", ")}}`;
  return `def feedback_make_${name}(${fields.map(field => `${field.name}: ${field.type}`).join(", ")}) -> FeedbackRequest:\n` +
    (products.length ? `  match ${products.map(field => field.name).join(" ")}:\n    case ${products.map(field => productValue(field.name, product(field.type))).join(" ")}:\n      ${constructor}\n`
      : `  ${constructor}\n`);
}
const classifications: { caller: string; callee: string; offset: number; kind: string }[] = [];
const resultType = "(Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool";
function lowerNested(owner: string, site: Site, text: string, local: number, end: number): string {
  const lineStart = text.lastIndexOf("\n", local) + 1;
  const lineEnd = text.indexOf("\n", end) < 0 ? text.length : text.indexOf("\n", end);
  const line = text.slice(lineStart, lineEnd);
  const consumer = /^\s*([A-Za-z_]\w*)\(/.exec(line);
  if (!consumer || consumer[1] !== site.parent) {
    throw Error(`Unsupported AST evaluation context: gateway App under ${site.parent ?? "lexical binding"}; source=${line.trim()}`);
  }
  const outerOffset = line.indexOf(consumer[1]!);
  const outer = invocation(line, outerOffset, consumer[1]!);
  if (line.slice(outer.end).trim()) throw Error("Unsupported nonterminal App continuation: " + line.trim());
  const inner = text.slice(local, end);
  const hole = outer.args.findIndex(arg => arg === inner);
  if (hole < 0) throw Error("Unsupported nested App not occupying a complete consumer argument: " + line.trim());
  const signature = params(consumer[1]!);
  if (signature.length !== outer.args.length || signature[hole]!.type !== resultType) {
    throw Error("Unsupported dependent or different-family consumer argument: " + line.trim());
  }
  const fields: Frame["fields"] = [];
  const args = outer.args.map((arg, i) => {
    if (i === hole) return "result";
    if (!arg.includes("=>")) {
      const name = `capture_${i}`;
      fields.push({ name, type: signature[i]!.type, value: arg });
      return name;
    }
    // Lambda closures are re-created in resume code, never stored as machine payloads.
    const consumerSite = calls(owner).find(candidate =>
      candidate.offset === declaration(owner).index! + lineStart + outerOffset);
    const lambda = consumerSite?.args[i];
    if (!lambda || lambda.$ !== "Lam") throw Error("Missing AST lambda continuation: " + line.trim());
    const free = new Map<number, string>();
    function collect(value: unknown, bound: Set<number>): void {
      if (!value || typeof value !== "object") return;
      const tm = value as LTerm;
      if (tm.$ === "Var") {
        if (!bound.has(tm.i)) free.set(tm.i, tm.k);
        return;
      }
      if (tm.$ === "Lam") {
        collect(tm.f, new Set([...bound, tm.i]));
        return;
      }
      for (const [key, child] of Object.entries(value)) {
        if (key === "s") continue;
        if (Array.isArray(child)) child.forEach(item => collect(item, bound));
        else collect(child, bound);
      }
    }
    collect(lambda, new Set());
    const captured = [...free.values()].map(name => {
      const field = params(owner).find(field => field.name === name);
      if (!field) throw Error(`Unsupported free local with no inferred type in lambda AST: ${name}; ${line.trim()}`);
      return field;
    });
    for (const field of captured) {
      if (!fields.some(existing => existing.name === field.name)) fields.push({ ...field, value: field.name });
    }
    return arg;
  });
  const name = `Kont_${site.offset}`;
  frames.push({ name, fields, resume: `feedback_pack(${consumer[1]}(${args.join(", ")}))` });
  const request = invocation(text, local, site.callee);
  const replacement = `FeedbackRequest{feedback_make_${site.callee}(${request.args.join(", ")}), [${name}{${fields.map(field => field.value).join(", ")}}]}`;
  classifications.push({ caller: owner, callee: site.callee, offset: site.offset, kind: "non-tail" });
  return text.slice(0, lineStart) + line.slice(0, outerOffset) + replacement + text.slice(lineEnd);
}
function bindFallbackScrutinees(text: string, owner: string): string {
  const lines = text.split("\n");
  const identifiers = /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[A-Za-z_]\w*/g;
  const imported = new Map([...source.matchAll(/^import .*\/(\w+)\.bend as (\w+)$/gm)]
    .map(match => [match[2]!, match[1]!]));
  function resolveSymbol(name: string): string {
    const parts = name.split(".");
    if (parts.length > 1 && imported.has(parts[0]!)) parts[0] = imported.get(parts[0]!)!;
    return parts.join(".");
  }
  function surfaceSymbol(name: string): string {
    const parts = name.split(".");
    const alias = [...imported].find(([, namespace]) => namespace === parts[0])?.[0];
    if (alias) parts[0] = alias;
    return parts.join(".");
  }
  function bind(pattern: string, type: string, env: Map<string, string>): void {
    pattern = pattern.trim().replace(/^\+/, "");
    if (/^[A-Za-z_]\w*$/.test(pattern)) {
      if (pattern !== "_") env.set(pattern, type);
      return;
    }
    const cons = /^(.*?)<>\s*(.*)$/.exec(pattern);
    if (cons && /^List</.test(type)) {
      const arguments_ = split(type.slice(type.indexOf("<") + 1, -1));
      bind(cons[1]!, arguments_.at(-1)!, env);
      bind(cons[2]!, type, env);
      return;
    }
    const tree = product(type);
    if (pattern.startsWith("(") && pattern.endsWith(")") && tree.left && tree.right) {
      const pair = split(pattern.slice(1, -1));
      if (pair.length === 2) {
        bind(pair[0]!, tree.left.type, env);
        bind(pair[1]!, tree.right.type, env);
        return;
      }
    }
    const constructor = /^([\w.]+)\{(.*)\}$/.exec(pattern);
    if (!constructor) return;
    const info = book.ctrs[resolveSymbol(constructor[1]!)];
    if (!info) throw Error("Missing AST constructor type: " + constructor[1]);
    let signature = term_lower(info.T);
    const fields = constructor[2]!.trim() ? split(constructor[2]!) : [];
    for (const field of fields) {
      if (signature.$ !== "All") throw Error("Constructor pattern arity mismatch: " + pattern);
      if (signature.A.$ === "Ref") bind(field, surfaceSymbol(signature.A.k), env);
      signature = signature.B;
    }
  }
  const stack: { indent: number; name: string; type: string; env: Map<string, string> }[] = [];
  let env = new Map(params(owner).map(field => [field.name, field.type]));
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i]!;
    const indent = line.length - line.trimStart().length;
    if (!line.trim()) continue;
    while (stack.length && stack.at(-1)!.indent >= indent) {
      env = stack.pop()!.env;
    }
    const scrutinized = /^match ([A-Za-z_]\w*):$/.exec(line.trim());
    if (scrutinized) {
      const name = scrutinized[1]!;
      const type = env.get(name);
      if (!type) throw Error(`Unsupported lexical scrutinee type inference: ${owner}.${name}`);
      stack.push({ indent, name, type, env: new Map(env) });
      continue;
    }
    if (!line.trimStart().startsWith("case ") || !stack.length) continue;
    const context = stack.at(-1)!;
    env = new Map(context.env);
    const pattern = line.trim().slice(5, -1).trim();
    bind(pattern, context.type, env);
    if (pattern !== "_") continue;
    let end = i + 1;
    while (end < lines.length && (!lines[end]!.trim() ||
      lines[end]!.length - lines[end]!.trimStart().length > indent)) end++;
    const body = lines.slice(i + 1, end);
    const used = body.some(row => [...row.matchAll(identifiers)].some(match => match[0] === context.name));
    if (!used) continue;
    const datatype = book.tlds[resolveSymbol(context.type)];
    if (datatype?.$ !== "ADT" || datatype.n !== 0) {
      throw Error(`Unsupported wildcard reification of parameterized/dependent type: ${context.type}`);
    }
    const replacement: string[] = [];
    for (const constructor of datatype.c) {
      const fields = Array.from({ length: constructor.n }, (_, field) => `feedback_field_${i}_${field}`);
      const name = surfaceSymbol(constructor.k);
      const value = `(${name}{${fields.join(", ")}} : ${context.type})`;
      replacement.push(`${" ".repeat(indent)}case ${name}{${fields.map(field => "+" + field).join(", ")}}:`,
        ...body.map(row => row.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\+?[A-Za-z_]\w*/g,
          token => token === context.name || token === "+" + context.name ? value : token)));
    }
    lines.splice(i, end - i, ...replacement);
    i += replacement.length - 1;
  }
  return lines.join("\n");
}

for (const name of selected) {
  const header = declaration(name);
  if (header[3] !== "(Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool") throw Error("Unsupported result family: " + name);
  let text = block(name);
  const start = header.index!;
  const sites = calls(name);
  for (const site of sites) {
    if (site.callee !== name && !gateways.has(site.callee)) ordinary.add(site.callee);
  }
  for (const site of sites.filter(site => gateways.has(site.callee)).reverse()) {
    const local = site.offset - start;
    const call = invocation(text, local, site.callee);
    const prefix = text.slice(text.lastIndexOf("\n", local) + 1, local);
    const suffix = text.slice(call.end).split("\n", 1)[0]!.trim();
    const args = call.args;
    if (args.length !== params(site.callee).length) throw Error("Gateway arity mismatch " + site.callee);
    requests.add(site.callee);
    if (prefix.trim() || suffix || site.parent !== null) {
      text = lowerNested(name, site, text, local, call.end);
    } else {
      text = text.slice(0, local) + `FeedbackRequest{feedback_make_${site.callee}(${args.join(", ")}), Nil{}}` + text.slice(call.end);
      classifications.push({ caller: name, callee: site.callee, offset: site.offset, kind: "tail" });
      tailRules++;
    }
  }
  text = text.split("\n").map(line => {
    const value = resultLeaf(line);
    if (value === null) {
      const callee = /^\s*([A-Za-z_]\w*)\(/.exec(line)?.[1];
      if (callee && ordinary.has(callee) && declaration(callee)[3] === resultType) {
        leafRules++;
        return line.slice(0, line.length - line.trimStart().length) + `feedback_pack(${line.trim()})`;
      }
      return line;
    }
    leafRules++;
    return line.slice(0, line.length - line.trimStart().length) + value;
  }).join("\n");
  text = text.replace(`def ${name}(`, `def step_${name}(`).replace(` -> ${header[3]}:`, " -> FeedbackStep:");
  text = bindFallbackScrutinees(text, name);
  const body = text.slice(text.indexOf("\n") + 1);
  for (const field of params(name)) {
    const uses = [...body.matchAll(new RegExp(`\\b${field.name}\\b`, "g"))].length;
    if (uses > 1) {
      text = text.replace(new RegExp(`(?<![+\\w])${field.name}:`), `+${field.name}:`);
    }
  }
  const lines = text.split("\n");
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i]!;
    if (!line.trimStart().startsWith("case ")) continue;
    const indent = line.length - line.trimStart().length;
    let end = i + 1;
    while (end < lines.length && (!lines[end]!.trim() ||
      lines[end]!.length - lines[end]!.trimStart().length > indent)) end++;
    const branch = lines.slice(i + 1, end).join("\n").replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/g, "");
    lines[i] = line.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[A-Za-z_]\w*/g, (token, offset) => {
      if (token === "case" || token === "_" || token.startsWith('"') || token.startsWith("'") ||
        /[+.\w]/.test(line[offset - 1] ?? " ") || /[.{]/.test(line[offset + token.length] ?? " ")) return token;
      return [...branch.matchAll(new RegExp(`\\b${token}\\b`, "g"))].length > 1 ? "+" + token : token;
    });
  }
  text = lines.join("\n");
  transformed.push(text);
}
// A token-tail match is a structural progress certificate. Removing these
// transfers must leave an administrative DAG; harness remainder adapters are
// required to return suffixes, never manufacture additional input.
const progress = classifications.map(site => {
  const prefix = source.slice(declaration(site.caller).index!, site.offset);
  const lines = prefix.split("\n");
  const indentation = lines.at(-1)!.length - lines.at(-1)!.trimStart().length;
  const tails = new Set<string>();
  let scopeIndent = indentation;
  for (let i = lines.length - 2; i >= 0; i--) {
    const line = lines[i]!;
    const indent = line.length - line.trimStart().length;
    if (!line.trim() || indent >= scopeIndent) continue;
    scopeIndent = indent;
    if (line.trimStart().startsWith("case ")) {
      for (const match of line.matchAll(/<>\s*\+?([A-Za-z_]\w*)/g)) tails.add(match[1]!);
    }
  }
  const ast = calls(site.caller).find(call => call.offset === site.offset && call.callee === site.callee)!;
  const consumes = ast.args.some((arg, i) => params(site.callee)[i]?.type === "List<&2, Lexer.Token>" &&
    arg.$ === "Var" && tails.has(arg.k));
  return { ...site, consumes, matchedTails: [...tails] };
});
const rank = new Map<string, number>();
const ranking = new Set<string>();
function administrativeRank(name: string): number {
  if (rank.has(name)) return rank.get(name)!;
  if (ranking.has(name)) throw Error("Uncertified no-progress gateway cycle at " + name);
  ranking.add(name);
  const value = 1 + Math.max(0, ...progress.filter(edge => edge.caller === name && !edge.consumes)
    .map(edge => administrativeRank(edge.callee)));
  ranking.delete(name);
  rank.set(name, value);
  return value;
}
for (const name of selected) administrativeRank(name);
const transitionFactor = 2 * Math.max(...rank.values()) + 2;
const scope = /^type Scope is Data:\n  Scope\{[^\n]+\}/m.exec(source)?.[0];
if (!scope) throw Error("Missing source Scope type");
const generated = [
  "# Generated from repaired parser source by evals/parser_feedback_generate.ts",
  "import Base", "import ./ast.bend as Ast", "import ./lexer.bend as Lexer", "import ./core.bend as Core", "",
  scope, "", "type FeedbackKont is Data:",
  ...frames.map(frame => `  ${frame.name}{${frame.fields.map(field => `${field.name}: ${field.type}`).join(", ")}}`),
  "", "type FeedbackRequest is Data:",
  ...[...requests].map(name => `  Request_${name}{${requestFields(name).map(p => `${p.name}: ${p.type}`).join(", ")}}`),
  "", "type FeedbackStep is Data:", "  FeedbackRequest{request: FeedbackRequest, kont: List<&2, FeedbackKont>}",
  "  FeedbackTerm{term: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, ok: Bool}",
  "", "type FeedbackRun is Data:",
  "  FeedbackComplete{term: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, ok: Bool}",
  "  FeedbackInvariantFailure{}", "",
  ...[...requests].map(requestMaker), "",
  "", `def feedback_pack(result: ${resultType}) -> FeedbackStep:`,
  "  match result:", "    case ((term, rest), ok): FeedbackTerm{term, rest, ok}", "",
  readFileSync(resolve(import.meta.dir, "../bend2/selfhost/parser_feedback_harness.bend.inc"), "utf8"),
  ...transformed, "",
  `def feedback_resume(frame: FeedbackKont, result: ${resultType}) -> FeedbackStep:`,
  "  match frame:",
  ...frames.map(frame => `    case ${frame.name}{${frame.fields.map(field => "+" + field.name).join(", ")}}:\n      ${frame.resume}`), "",
  "def feedback_dispatch(request: FeedbackRequest) -> FeedbackStep:",
  "  match request:",
  ...[...requests].map(name => `    case Request_${name}{${requestFields(name).map(field => field.name).join(", ")}}:\n      step_${name}(${params(name).map(field => productValue(field.name, product(field.type))).join(", ")})`), "",
  "def feedback_drive(ticks: Nat, step: FeedbackStep, stack: List<&2, FeedbackKont>) -> FeedbackRun:",
  "  match ticks:",
  "    case 0n: FeedbackInvariantFailure{}",
  "    case 1n+remaining:",
  "      match step:",
  "        case FeedbackRequest{request, pending}:",
  "          feedback_drive(remaining, feedback_dispatch(request), List.append(&2, FeedbackKont, pending, stack))",
  "        case FeedbackTerm{term, rest, ok}:",
  "          match stack:",
  "            case Nil{}: FeedbackComplete{term, rest, ok}",
  "            case frame <> tail:",
  "              feedback_drive(remaining, feedback_resume(frame, ((term, rest), ok)), tail)", "",
  ...[...requests].map(name => {
    const fields = params(name);
    const lengths = fields.filter(field => field.type === "List<&2, Lexer.Token>")
      .map(field => `List.length(&2, Lexer.Token, ${field.name})`);
    const size = lengths.reduce((acc, value) => `Nat.add(${acc}, ${value})`, "1n");
    return `def feedback_entry_${name}(${fields.map(field => `${field.type === "List<&2, Lexer.Token>" ? "+" : ""}${field.name}: ${field.type}`).join(", ")}) -> FeedbackRun:\n  feedback_drive(Nat.mul(${transitionFactor}n, ${size}), FeedbackRequest{feedback_make_${name}(${fields.map(field => field.name).join(", ")}), Nil{}}, Nil{})\n`;
  }),
  readFileSync(resolve(import.meta.dir, "../bend2/selfhost/parser_feedback_scenarios.bend.inc"), "utf8"),
].join("\n");
writeFileSync(output, generated);
writeFileSync(output + ".scorecard.json", JSON.stringify({
  sourceCheckpoint: "89d5cdb7", sourceSha256: expected,
  generatedSha256: createHash("sha256").update(generated).digest("hex"),
  selected: [...selected], classifications, frames, progress,
  administrativeRanks: Object.fromEntries(rank), transitionFactor,
  genericRules: [
    "AST-anchored callsite classification", "tail Request lowering",
    "typed non-tail consumer Kont splitting", "AST free-variable lambda capture",
    "terminal Outcome lowering", "product-valued Request field flattening",
    "affine parameter and pattern binder promotion", "typed wildcard constructor reification",
    "dependency-layered emission", "administrative-DAG/token-progress bounded driver",
  ],
  genericTailSites: tailRules, genericNonTailSites: frames.length, genericTerminalSites: leafRules,
  sourceSpecificTransformerExceptions: 0, outboundDependencies: [...ordinary],
  harness: { source: "parser_feedback_harness.bend.inc", grammarSpecific: true, transitiveProductionClosureImported: false },
}, null, 2));
console.log(JSON.stringify({ output, sourceSha256: expected, selected: [...selected], requests: [...requests], genericTailRules: tailRules, genericNonTailSites: frames.length, genericValueRules: leafRules, sourceExceptions: 0 }));
