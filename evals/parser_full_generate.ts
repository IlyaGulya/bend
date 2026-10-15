#!/usr/bin/env bun
/** Complete source-anchored parser control lowering.
 * Unsupported control contexts fail before emission; generated output is never
 * patched by hand. --fuel-parametric emits the whole experimental machine with
 * caller-supplied structural fuel before ownership instrumentation or automatic
 * production-bound analysis. The automatic certificate path remains separate.
 */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { posix, resolve } from "node:path";
import { err_show, name_show, term_compare, term_higher, term_show, term_unapply, type Body, type Err, type LTerm, type Quant } from "../bend2/bend.ts";
import { readParserGraph, type ParserParameter } from "./parser_full_graph.ts";
import { freeBinderIds, LexicalTypes, MissingType } from "./parser_full_type_env.ts";
import { CaptureTypeDependencyError, planCaptures, renderCaptureCallbacks, type CapturePlan } from "./parser_full_capture.ts";
import { specializeConsumer, type QuantityOrigin } from "./parser_full_consumer.ts";
import { renderBody } from "./parser_full_body_render.ts";
import { optimizeCursorRestitution } from "./parser_full_restitution.ts";
import { containsTokenCursor, instrumentExplicitProgress, type ExplicitPrimitiveOperation, type ExplicitProgressProgram } from "./parser_full_explicit_progress.ts";
import { buildExplicitProgressCertificate } from "./parser_full_explicit_certificate.ts";
import { renderExplicitControlRuntime, renderStructuralFeedbackFuel, type StructuralFeedbackFuelProgram } from "./parser_full_control_runtime.ts";
import { ProductTypes, productFields, productValue } from "./parser_full_product.ts";
import { SourceDeclarations } from "./parser_full_declarations.ts";
import { hasPatternQuantityBoundary, liftPatternQuantities } from "./parser_full_pattern_quantity.ts";

const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");
const output = resolve(import.meta.dir, "../bend2/selfhost/parser_full_generated.bend");
const source = readFileSync(input, "utf8");
const sourceDeclarations = new SourceDeclarations(source);
const expected = "f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df";
if (createHash("sha256").update(source).digest("hex") !== expected) {
  throw Error("Parser source differs from canonical semantic checkpoint " + expected.slice(0, 8));
}
const parserAST = await readParserGraph(source, input);
const book = parserAST.parserBook;
const headers = [...source.matchAll(/^def ([A-Za-z_]\w*)\((.*)\)(?: -> (.*))?:$/gm)];
const aliases = [...source.matchAll(/^import (\S+) as (\w+)$/gm)];
const surfaceFile = {str: source, ns: "", al: Object.fromEntries(
  aliases.map(alias => [alias[2]!, posix.normalize(alias[1]!).replace(/\.bend$/, "")]))};
const tokenElement = surfaceFile.al.Lexer + ".Token";
function showTypeLeaf(term: LTerm): string {
  return term_show(term, -1, [], surfaceFile);
}
const productTypes = new ProductTypes(book, surfaceFile.al, showTypeLeaf);
function surfaceType(term: LTerm): string { return productTypes.fromTerm(term).type; }
for (const header of headers) {
  const signature = parserAST.signatures.get(header[1]!);
  if (!signature) throw Error("Missing production signature: " + header[1]);
  if (header[3] === undefined) {
    header[2] = signature.parameters.map(([quantity, name, , type]) =>
      (quantity.$ === "Many" ? "+" : "") + name + ": " + surfaceType(type)).join(", ");
  }
  header[3] = surfaceType(signature.result);
}
const defs = new Map(headers.map(match => [match[1]!, match]));
const lexicalTypes = new LexicalTypes(book, parserAST.signatures);
const indexedBodies = new Set<string>();
function indexLexicalBody(name: string): void {
  if (indexedBodies.has(name)) return;
  const body = parserAST.bodies.get(name);
  const signature = parserAST.signatures.get(name);
  if (!body || !signature) throw Error("Missing production body/signature: " + name);
  lexicalTypes.indexBody(body, signature.parameters, signature.result);
  indexedBodies.add(name);
}
function surfaceExpression(term: LTerm, boundNames: string[], precedence = -1): string {
  return term_show(term, precedence, boundNames, surfaceFile);
}
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
  return sourceDeclarations.body(name);
}
function params(name: string): { name: string; type: string }[] {
  if (!declaration(name)[2]!.trim()) return [];
  return split(declaration(name)[2]!).map(part => {
    const colon = part.indexOf(":");
    if (colon < 0) throw Error("Missing parameter type in " + part);
    return { name: part.slice(0, colon).trim().replace(/^\+/, ""), type: part.slice(colon + 1).trim() };
  });
}
type Site = { caller: string; callee: string; offset: number; parent: string | null; args: LTerm[] };
function calls(name: string): Site[] {
  return (parserAST.calls.get(name) ?? []).map(site => ({...site, parent: site.parent ?? null}));
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

function product(type: string) { return productTypes.parse(type); }

function bindFallbackScrutinees(text: string, owner: string): string {
  const lines = text.split("\n");
  indexLexicalBody(owner);
  const firstLine = source.slice(0, declaration(owner).index!).split("\n").length;
  const originalLines = lines.map((_, index) => firstLine + index);
  const matchTypes = new Map<number, LTerm>();
  function indexMatches(body: Body): void {
    if (body.$ === "Local") { indexMatches(body.f); return; }
    if (body.$ !== "Match") return;
    if (body.e.length === 1 && body.e[0]!.$ === "Var" && body.e[0]!.s) {
      const expression = body.e[0]!;
      matchTypes.set(source.slice(0, expression.s!.beg).split("\n").length, lexicalTypes.typeOf(expression));
    }
    body.r.forEach(row => indexMatches(row.f));
  }
  indexMatches(parserAST.bodies.get(owner)!);
  const identifiers = /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[A-Za-z_]\w*/g;
  function surfaceSymbol(name: string): string {
    return name_show(surfaceFile, name);
  }
  const stack: {indent: number; name: string; type: string; datatype: LTerm}[] = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i]!;
    const indent = line.length - line.trimStart().length;
    if (!line.trim()) continue;
    while (stack.length && stack.at(-1)!.indent >= indent) stack.pop();
    const scrutinized = /^match ([A-Za-z_]\w*):$/.exec(line.trim());
    if (scrutinized) {
      const name = scrutinized[1]!;
      const datatype = matchTypes.get(originalLines[i]!);
      if (!datatype) throw Error(`Missing indexed scrutinee AST: ${owner}:${originalLines[i]}`);
      stack.push({indent, name, type:surfaceType(datatype), datatype});
      continue;
    }
    if (!line.trimStart().startsWith("case ") || !stack.length) continue;
    const context = stack.at(-1)!;
    const pattern = line.trim().slice(5, -1).trim();
    if (pattern !== "_") continue;
    let end = i + 1;
    while (end < lines.length && (!lines[end]!.trim() ||
      lines[end]!.length - lines[end]!.trimStart().length > indent)) end++;
    const body = lines.slice(i + 1, end);
    const used = body.some(row => [...row.matchAll(identifiers)].some(match => match[0] === context.name));
    if (!used) continue;
    const instance = context.datatype;
    const datatype = instance.$ === "ADT" ? book.tlds[instance.k] : undefined;
    if (instance.$ !== "ADT" || datatype?.$ !== "ADT" || instance.x.length !== datatype.n) {
      throw Error(`Wildcard requires an instantiated datatype: ${context.type}`);
    }
    const replacement: string[] = [];
    const replacementOrigins: number[] = [];
    const uses = body.reduce((sum, row) => sum + [...row.matchAll(identifiers)].filter(match => match[0] === context.name).length, 0);
    for (const constructor of datatype.c) {
      const fields = Array.from({ length: constructor.n }, (_, field) => `feedback_field_${i}_${field}`);
      const name = surfaceSymbol(constructor.k);
      const value = `(${name}{${fields.join(", ")}} : ${context.type})`;
      replacement.push(`${" ".repeat(indent)}case ${name}{${fields.map(field => (uses > 1 ? "+" : "") + field).join(", ")}}:`,
        ...body.map(row => row.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\+?[A-Za-z_]\w*/g,
          token => token === context.name || token === "+" + context.name ? value : token)));
      replacementOrigins.push(originalLines[i]!, ...originalLines.slice(i + 1, end));
    }
    lines.splice(i, end - i, ...replacement);
    originalLines.splice(i, end - i, ...replacementOrigins);
    i += replacement.length - 1;
  }
  return lines.join("\n");
}



const cutPath = resolve(import.meta.dir, "../bend2/selfhost/parser_full_cut.json");
const cut = JSON.parse(readFileSync(cutPath, "utf8"));
if (cut.sourceSha256 !== "0009070688f8fffffbb8664e72bd4662bf1324675ba097297076d77939153df5" || cut.sourceCheckpoint !== "0d0e204f") throw Error("Stale feedback cut");
const currentGraphPath = resolve(import.meta.dir, "../bend2/selfhost/parser_full_current_graph.json");
const currentGraphBytes = readFileSync(currentGraphPath);
const currentGraph = JSON.parse(currentGraphBytes.toString());
if (currentGraph.sourceSha256 !== expected || currentGraph.sourceCheckpoint !== expected.slice(0,8) ||
    JSON.stringify([...currentGraph.definitions].sort()) !== JSON.stringify([...parserAST.definitions].sort())) {
  throw Error("Current dependency metadata differs from the pinned canonical source");
}
const selected = new Set<string>(cut.completeSelected ?? cut.selected);
const graph = new Map<string, Set<string>>(Object.entries(currentGraph.edges).map(([name, targets]) => [name, new Set(targets as string[])]));
function normalizedEdges(edges: Record<string, string[]>): string {
  return JSON.stringify(Object.keys(edges).sort().map(name => [name, [...edges[name]!].sort()]));
}
if (normalizedEdges(currentGraph.edges) !== normalizedEdges(parserAST.edges)) {
  throw Error("Current dependency facts differ from the freshly parsed production Body AST");
}
const lifted = new Set(selected);
for (let changed = true; changed;) {
  changed = false;
  for (const [name, targets] of graph) {
    if (!lifted.has(name) && [...targets].some(target => lifted.has(target))) { lifted.add(name); changed = true; }
  }
}
const sourceOwners = new Map([...defs.keys()].map(name => [lifted.has(name) ? "step_"+name : name, name]));
function sourceDefinition(name:string,text:string):string {
  const owner=sourceOwners.get(name);
  return owner===undefined?text:sourceDeclarations.emit(owner,text);
}
const families = [...new Set([...lifted].map(name => declaration(name)[3]!.trim()))].sort();
const family = (name: string) => families.indexOf(declaration(name)[3]!.trim());
const steps = new Map<string, string>();
type LoweredCall = {caller: string; callee: string; offset: number; kind: string; machineSource?: string};
const classifications: LoweredCall[] = [];
type FrameField = {name: string; type: string; value: string; binderId?: number; quantity?: Quant; resumeQuantity?: Quant};
type FrameWitness = {argumentIndex:number;parameterIndex:number;frameFieldIndex:number;witnessName:string};
type Frame = {name: string; owner: string; pushOffset: number; inputFamily: number; fields: FrameField[]; resume: string; witnesses?:FrameWitness[]};
function resumePrefix(frame: Frame, field: FrameField): string {
  if (field.resumeQuantity) return {None:"-", Lone:"", Many:"+"}[field.resumeQuantity.$];
  return [...frame.resume.matchAll(new RegExp("\\b" + field.name + "\\b", "g"))].length > 1 ? "+" : "";
}
const frames: Frame[] = [];
const consumerHelpers = new Map<string, string>();
const consumerQuantityOrigins = new Map<string,Map<string,QuantityOrigin>>();
const callbackOffsets = new Set<number>();
let syntheticBinder = 0;
function collectBinderIds(value: unknown): void {
  if (!value || typeof value !== "object") return;
  if (Array.isArray(value)) { value.forEach(collectBinderIds); return; }
  for (const [key, child] of Object.entries(value)) {
    if (key === "s" || key === "src" || key === "q") continue;
    if (key === "i") {
      for (const id of Array.isArray(child) ? child : [child]) {
        if (typeof id === "number") syntheticBinder = Math.max(syntheticBinder, id + 1);
      }
    } else collectBinderIds(child);
  }
}
for (const body of parserAST.bodies.values()) collectBinderIds(body);
for (const signature of parserAST.signatures.values()) collectBinderIds(signature);
function effectfulCalls(term: LTerm): {name: string; offset: number}[] {
  const found: {name: string; offset: number}[] = [];
  function visit(node: LTerm): void {
    if (node.$ === "App") {
      const [head, args] = term_unapply(node);
      if (head.$ === "Ref" && lifted.has(head.k)) found.push({name:head.k, offset:head.s?.beg ?? -1});
      visit(head); args.forEach(visit);
      return;
    }
    for (const [key, child] of Object.entries(node)) {
      if (key === "s" || key === "q") continue;
      if (Array.isArray(child)) child.forEach(value => { if (value?.$) visit(value); });
      else if (child && typeof child === "object" && "$" in child) visit(child as LTerm);
    }
  }
  visit(term);
  return found;
}
function controlConsumer(owner: string, site: Site, plan: CapturePlan, argumentValues: string[], capturesFromSource = false, machineSource?: string): string {
  const signature = parserAST.signatures.get(site.callee)!;
  const body = parserAST.bodies.get(site.callee)!;
  if (!signature || !body) stop(owner, site, "Consumer body/signature unavailable");
  const callbacks = new Map<number, LTerm>();
  const arguments_ = new Map<number, Extract<LTerm, {$:"Var"}>>();
  const callValues = new Map<number, string>();
  let callback = 0;
  site.args.forEach((argument, index) => {
    const formal = signature.parameters[index]!;
    if (argument.$ === "Lam") callbacks.set(formal[2], plan.callbacks[callback++]!);
    else {
      const value: Extract<LTerm, {$:"Var"}> = {$:"Var", k:"argument_" + index, i:syntheticBinder++};
      arguments_.set(formal[2], value);
      callValues.set(value.i, argumentValues[index]!);
    }
  });
  const captures: ParserParameter[] = plan.fields.map(field => {
    callValues.set(field.id, capturesFromSource ? field.sourceName : field.name);
    return [field.resumeQuantity, field.name, field.id, field.type, signature.parameters[0]![4]];
  });
  const specialized = specializeConsumer(body, signature, callbacks, arguments_, captures);
  lexicalTypes.indexBody(specialized.body, specialized.parameters, specialized.result);
  const helper = "feedback_consumer_" + site.offset;
  const rendered = renderBody(specialized.body, specialized.parameters, {
    book, showTerm:surfaceExpression, types:lexicalTypes,
    emitTerminal(term, context) {
      const [head, args] = term_unapply(term);
      if (head.$ === "Ref" && lifted.has(head.k)) {
        classifications.push({caller:owner, callee:head.k, offset:head.s?.beg ?? site.offset,
          kind:selected.has(head.k) ? "callback-tail-request" : "callback-tail-dag", machineSource});
        return controlCall(head.k, args.map(argument => context.renderTerm(argument)));
      }
      if (effectfulCalls(term).length) stop(owner, site, "Nested effectful consumer body requires an AST evaluation continuation",
        {specializedExpression:astShape(term)});
      return "feedback_pack_" + family(owner) + "(" + context.renderTerm(term) + ")";
    },
  });
  consumerQuantityOrigins.set(helper,new Map([...specialized.quantityOrigins].flatMap(([id,origin])=>{
    const printed=rendered.printedBinders.get(id);
    return printed===undefined?[]:[[printed,origin] as [string,QuantityOrigin]];
  })));
  consumerHelpers.set(helper, "def " + helper + "(" + rendered.parameters + ") -> FeedbackControl:\n" + rendered.body);
  return helper + "(" + specialized.parameters.map(parameter => callValues.get(parameter[2])!).join(", ") + ")";
}
let tailRules = 0, leafRules = 0;
class GenericLimitation extends Error {
  constructor(message: string, readonly evidence: Record<string, unknown>) { super(message); }
}
function astShape(value: unknown): unknown {
  if (typeof value === "bigint") return { bigint: value.toString() };
  if (!value || typeof value !== "object") return value;
  if (Array.isArray(value)) return value.map(astShape);
  return Object.fromEntries(Object.entries(value).filter(([key]) => key !== "s").map(([key, child]) => [key, astShape(child)]));
}
function stop(owner: string, site: Site, reason: string, extra: Record<string, unknown> = {}): never {
  const call = invocation(source, site.offset, site.callee);
  const line = source.slice(0, site.offset).split("\n").length;
  throw new GenericLimitation(reason, {owner, callee:site.callee, line, offset:site.offset,
    productionExpression:source.slice(site.offset, call.end),
    productionAST:{tag:"App",head:{tag:"Ref",name:site.callee},arguments:site.args.map(astShape)}, ...extra});
}
function requestFields(name: string) {
  return params(name).flatMap(field => productFields(field.name, product(field.type)));
}
function maker(name: string, fields: {name: string;type: string}[], resultType: string, constructor: string): string {
  const products = fields.filter(field => product(field.type).left);
  return "def " + name + "(" + fields.map(field => field.name + ": " + field.type).join(", ") + ") -> " + resultType + ":\n" +
    (products.length ? "  match " + products.map(field => field.name).join(" ") + ":\n    case " + products.map(field => productValue(field.name, product(field.type))).join(" ") + ":\n      " + constructor
      : "  " + constructor);
}
function requestMaker(name: string) {
  return maker("feedback_make_" + name, params(name), "FeedbackRequest", "Request_" + name + "{" + requestFields(name).map(field => field.name).join(", ") + "}");
}
function controlCall(callee: string, arguments_: string[]): string {
  const call = (selected.has(callee) ? "feedback_make_" : "step_") + callee + "(" + arguments_.join(", ") + ")";
  return selected.has(callee) ? "FeedbackControl{FeedbackCall{" + call + "}, Nil{}, NoProgress{}, NoProgress{}}" : call;
}
function lowerNested(owner: string, site: Site, text: string, local: number, end: number): string {
  const lineStart = text.lastIndexOf("\n", local) + 1;
  const lineEnd = text.indexOf("\n", end) < 0 ? text.length : text.indexOf("\n", end);
  const line = text.slice(lineStart, lineEnd);
  const consumer = /^\s*([A-Za-z_]\w*)\(/.exec(line);
  if (!consumer || consumer[1] !== site.parent) stop(owner, site, "Effectful App is not a complete argument of a terminal named consumer", {sourceContext:line.trim()});
  const outerOffset = line.indexOf(consumer[1]!);
  const outer = invocation(line, outerOffset, consumer[1]!);
  if (line.slice(outer.end).trim()) stop(owner, site, "Nonterminal App continuation", {sourceContext:line.trim()});
  const inner = text.slice(local, end);
  const hole = outer.args.findIndex(arg => arg === inner);
  if (hole < 0) stop(owner, site, "Suspended App does not occupy a complete consumer argument", {sourceContext:line.trim()});
  const signature = params(consumer[1]!);
  const consumerType = parserAST.signatures.get(consumer[1]!)?.parameters[hole]?.[3];
  const producerType = parserAST.signatures.get(site.callee)?.result;
  if (signature.length !== outer.args.length || !consumerType || !producerType ||
      freeBinderIds(consumerType).length || freeBinderIds(producerType).length ||
      !term_compare("EQ", book, term_higher(consumerType), term_higher(producerType), 0)) {
    stop(owner, site, "Dependent consumer argument shape", {sourceContext:line.trim(),signature});
  }
  const consumerSite = calls(owner).find(candidate => candidate.offset === declaration(owner).index! + lineStart + outerOffset);
  const fields: Frame["fields"] = [];
  const callbackIndices = outer.args.flatMap((_, index) =>
    index !== hole && consumerSite?.args[index]?.$ === "Lam" ? [index] : []);
  let callbackTexts: string[];
  let capturePlan: CapturePlan;
  try {
    indexLexicalBody(owner);
    capturePlan = planCaptures(callbackIndices.map(index => consumerSite!.args[index]!), lexicalTypes,
      {prefix:"lexical_capture"});
    for (const field of capturePlan.fields) fields.push({
      name:field.name, type:surfaceType(field.type), value:field.sourceName, binderId:field.id,
      quantity:field.quantity, resumeQuantity:field.resumeQuantity,
    });
    callbackTexts = renderCaptureCallbacks(capturePlan, surfaceExpression);
  } catch (error) {
    if (error instanceof MissingType || error instanceof CaptureTypeDependencyError) {
      stop(owner, site, error.message, {typingEvidence:astShape(error instanceof MissingType ?
        {code:error.code, reason:error.reason, binderId:error.binderId, expression:error.expression} : error.evidence),
        productionBodyAST:astShape(parserAST.bodies.get(owner))});
    }
    throw error;
  }
  const args = outer.args.map((arg, i) => {
    if (i === hole) return "result";
    const argumentAST = consumerSite?.args[i];
    if (argumentAST?.$ !== "Lam") {
      if (consumerSite && calls(owner).some(candidate => candidate.offset >= consumerSite.offset && candidate.offset < consumerSite.offset + line.length && lifted.has(candidate.callee) && candidate.offset !== site.offset && candidate.parent === consumerSite.callee)) {
        stop(owner, site, "Multiple effectful sibling arguments need sequenced evaluation contexts", {sourceContext:line.trim()});
      }
      const name = "capture_" + i;
      fields.push({name,type:signature[i]!.type,value:arg,binderId:argumentAST?.$==="Var"?argumentAST.i:undefined});
      return name;
    }
    return callbackTexts[callbackIndices.indexOf(i)]!;
  });
  const specialized = consumerSite && callbackIndices.some(index => effectfulCalls(consumerSite.args[index]!).length);
  const frame: Frame = {name:"Kont_" + site.offset,owner,pushOffset:site.offset,inputFamily:family(site.callee),fields,
    resume:specialized ? controlConsumer(owner, consumerSite!, capturePlan!, args, false, "Kont_" + site.offset) :
      lifted.has(consumer[1]!) ? controlCall(consumer[1]!,args) : "feedback_pack_" + family(owner) + "(" + consumer[1] + "(" + args.join(", ") + "))"};
  frames.push(frame);
  const request = invocation(text,local,site.callee);
  const replacement = "feedback_attach(" + controlCall(site.callee,request.args) + ", feedback_make_" + frame.name + "(" + fields.map(field => field.value).join(", ") + "))";
  classifications.push({caller:owner,callee:site.callee,offset:site.offset,kind:"non-tail"});
  if (consumerSite && lifted.has(consumerSite.callee)) {
    classifications.push({caller:owner,callee:consumerSite.callee,offset:consumerSite.offset,
      kind:selected.has(consumerSite.callee) ? "resume-tail-request" : "resume-tail-dag", machineSource:frame.name});
    tailRules++;
  }
  return text.slice(0,lineStart) + line.slice(0,outerOffset) + replacement + text.slice(lineEnd);
}
function promote(text: string, owner: string): string {
  const body = text.slice(text.indexOf("\n") + 1).replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/g,"");
  for (const field of params(owner)) if ([...body.matchAll(new RegExp("\\b" + field.name + "\\b","g"))].length > 1) {
    text = text.replace(new RegExp("^(.*?)(?<![+\\w])" + field.name + ":"),"$1+" + field.name + ":");
  }
  const lines = text.split("\n");
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i]!;
    if (!line.trimStart().startsWith("case ")) continue;
    const indent = line.length - line.trimStart().length;
    let end = i+1;
    while (end < lines.length && (!lines[end]!.trim() || lines[end]!.length-lines[end]!.trimStart().length > indent)) end++;
    const branch = lines.slice(i+1,end).join("\n").replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/g,"");
    lines[i] = line.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[A-Za-z_]\w*/g,(token,offset) => {
      if (token === "case" || token === "_" || token.startsWith('"') || token.startsWith("'") || /[+.\w]/.test(line[offset-1] ?? " ") || /[.{]/.test(line[offset+token.length] ?? " ")) return token;
      return [...branch.matchAll(new RegExp("\\b"+token+"\\b","g"))].length>1 ? "+"+token : token;
    });
  }
  return lines.join("\n");
}
const genericRules = ["AST-anchored callsite classification", "reverse-reachability Control propagation", "weighted feedback Request forwarding", "dependency-DAG step forwarding", "multi-family typed Value flattening", "typed consumer Kont splitting", "AST free-variable lambda capture", "product Request/Kont flattening", "affine binder promotion", "typed wildcard constructor reification", "dependency-layered emission", "administrative-DAG/token-progress bound"];
genericRules.push("binder-ID lexical TypeEnv", "structural product/constructor type projection",
  "identity-safe callback alpha-renaming", "affine capture transfer and resume-local use promotion");
genericRules.push("binder-safe higher-order consumer beta specialization", "typed Control callback consumer helpers");
genericRules.push("closed type-level Match normalization", "declared constructor payload goal instantiation",
  "source-AST scoped wildcard typing", "callback-only Control consumer specialization");
genericRules.push("native closed consumer type equivalence independent of surface parentheses");
const progressRules = ["source-Body emitted explicit NoProgress/Consumed effects", "OR-monoid child effect composition",
  "invocation-owned progress capture and resume", "explicit-effect NoProgress graph and globally smallest finite cycle"];
let progressSummary: Record<string, unknown> | null = null;
function metadata() {
  return {sourceCheckpoint:expected.slice(0,8),sourceSha256:expected,currentGraphSha256:createHash("sha256").update(currentGraphBytes).digest("hex"),cutSourceCheckpoint:cut.sourceCheckpoint,cutSourceSha256:cut.sourceSha256,selected:cut.selected,completeSelected:[...selected],
    controlPropagationRequiredFunctions:[...lifted].filter(name=>!selected.has(name)),
    mechanicallyLiftedFunctions:[...steps.keys()].map(name=>name.slice("step_".length)).filter(name=>!selected.has(name)),
    plannedRequestVariants:[...selected],requestVariants:[...selected],
    kontVariants:frames, controlConsumerHelpers:[...consumerHelpers.keys()],
    resultFamilies:families,genericRules,progressRules,classifications,progressSummary,sourceSpecificTransformerExceptions:0};
}
try {
  for (const name of defs.keys()) {
    if (!lifted.has(name)) continue;
    const sites = calls(name);
    for (const site of sites) for (const argument of site.args) {
      if (argument.$ === "Lam") for (const call of effectfulCalls(argument)) callbackOffsets.add(call.offset);
    }
    let text = block(name);
    const consumedRows = new Set<number>();
    for (const site of sites.filter(site=>(lifted.has(site.callee) ||
      site.args.some(argument=>argument.$==="Lam" && effectfulCalls(argument).length)) &&
      !callbackOffsets.has(site.offset)).reverse()) {
      const row = source.lastIndexOf("\n", site.offset);
      if (consumedRows.has(row)) continue;
      const local = site.offset - declaration(name).index!;
      const call = invocation(text,local,site.callee);
      const prefix = text.slice(text.lastIndexOf("\n",local)+1,local);
      const suffix = text.slice(call.end).split("\n",1)[0]!.trim();
      if (!lifted.has(site.callee)) {
        if (prefix.trim() || suffix || site.parent !== null) stop(name, site, "Nonterminal callback-only consumer requires AST continuation lowering");
        indexLexicalBody(name);
        const plan = planCaptures(site.args.filter(argument => argument.$ === "Lam"), lexicalTypes,
          {prefix:"lexical_capture"});
        const replacement = controlConsumer(name, site, plan, call.args, true);
        text = text.slice(0,local) + replacement + text.slice(call.end);
        consumedRows.add(row);
      } else if (prefix.trim() || suffix || site.parent !== null) {
        text = lowerNested(name,site,text,local,call.end);
        consumedRows.add(row);
      }
      else { text = text.slice(0,local)+controlCall(site.callee,call.args)+text.slice(call.end); classifications.push({caller:name,callee:site.callee,offset:site.offset,kind:selected.has(site.callee)?"tail-request":"tail-dag"}); tailRules++; }
    }
    text = text.split("\n").map((line,index)=>{
      if (!index || !line.trim() || line.trimStart().startsWith("#")) return line;
      const inline = /^\s*case .*?:\s+(.+)$/.exec(line);
      const expression = inline?.[1] ?? line.trim();
      if (/^(match |case |def |type )/.test(expression) || /^(?:[+-]?[A-Za-z_]\w*)\s*=/.test(expression)) return line;
      if (/^(?:FeedbackControl\{|step_|feedback_attach\(|feedback_consumer_)/.test(expression)) return line;
      leafRules++;
      return line.slice(0,line.length-expression.length)+"feedback_pack_"+family(name)+"("+expression+")";
    }).join("\n");
    text = "def step_" + name + "(" + declaration(name)[2] + ") -> FeedbackControl:" +
      text.slice(text.indexOf("\n"));
    try { text = promote(bindFallbackScrutinees(text,name),name); }
    catch (error) {
      if (!(error instanceof MissingType)) throw error;
      throw new GenericLimitation(error.message, {owner:name, typingEvidence:astShape({
        code:error.code, reason:error.reason, binderId:error.binderId, expression:error.expression}),
        productionBodyAST:astShape(parserAST.bodies.get(name))});
    }
    steps.set("step_"+name,sourceDefinition("step_"+name,text));
  }
  const valueFields = families.map(type=>productFields("result",product(type)));
  const valueType = ["type FeedbackValue is Data:",...valueFields.map((fields,index)=>"  Value_"+index+"{"+fields.map(field=>field.name+": "+field.type).join(", ")+"}")].join("\n");
  const chunks = new Map<string,string>();
  let effectDefinitions: string[] = [];
  for(const name of defs.keys())if(!lifted.has(name)){
    chunks.set(name,sourceDefinition(name,block(name)));
    effectDefinitions.push(name);
  }
  for(const [name,text] of steps){chunks.set(name,text);effectDefinitions.push(name);}
  for(const [name,text] of consumerHelpers){chunks.set(name,text);effectDefinitions.push(name);}
  for(const name of selected)chunks.set("feedback_make_"+name,requestMaker(name));
  families.forEach((type,index)=>chunks.set("feedback_pack_"+index,maker("feedback_pack_"+index,[{name:"result",type}],"FeedbackControl","FeedbackControl{FeedbackDone{Value_"+index+"{"+valueFields[index]!.map(field=>field.name).join(", ")+"}}, Nil{}, NoProgress{}, NoProgress{}}")));
  for(const frame of frames){
    const fields=frame.fields.flatMap(field=>productFields(field.name,product(field.type)));
    chunks.set("feedback_make_"+frame.name,maker("feedback_make_"+frame.name,frame.fields,"FeedbackFrame",frame.name+"{"+fields.map(field=>field.name).join(", ")+"}"));
    const resumeName = "feedback_resume_"+frame.name;
    chunks.set(resumeName,"def "+resumeName+"("+frame.fields.map(field=>resumePrefix(frame,field)+field.name+": "+field.type).concat("result: "+families[frame.inputFamily]).join(", ")+") -> FeedbackControl:\n  "+frame.resume);
    effectDefinitions.push(resumeName);
  }
  const dispatchWitnesses = new Map<string, string[]>();
  function renderRuntime() { return renderExplicitControlRuntime({
    frameVariants:frames.map(frame=>"  "+frame.name+"{"+frame.fields.flatMap(field=>productFields(field.name,product(field.type))).map(field=>field.name+": "+field.type).concat((frame.witnesses??[]).map(witness=>witness.witnessName+": FeedbackCursorWitness")).join(", ")+"}"),
    requestVariants:[...selected].map(name=>"  Request_"+name+"{"+requestFields(name).map(field=>field.name+": "+field.type).join(", ")+"}"),
    dispatchCases:[...selected].map(name=>"    case Request_"+name+"{"+requestFields(name).map(field=>field.name).join(", ")+"}:\n      step_"+name+"("+params(name).map(field=>productValue(field.name,product(field.type))).concat(dispatchWitnesses.get(name)??[]).join(", ")+")"),
    resumeCases:frames.map(frame=>"    case "+frame.name+"{"+frame.fields.flatMap(field=>productFields(field.name,product(field.type)).map(flat=>({field,flat}))).map(({field,flat})=>(resumePrefix(frame,field)==="+"?"+":"")+flat.name).concat((frame.witnesses??[]).map(witness=>"+"+witness.witnessName)).join(", ")+"}:\n      match value:\n        case Value_"+frame.inputFamily+"{"+valueFields[frame.inputFamily]!.map(field=>field.name).join(", ")+"}:\n          feedback_resume_"+frame.name+"("+frame.fields.map(field=>productValue(field.name,product(field.type))).concat(productValue("result",product(families[frame.inputFamily]!))).concat((frame.witnesses??[]).map(witness=>witness.witnessName)).join(", ")+")\n        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}"),
  }); }
  let runtime = renderRuntime();
  for(const [name,text] of runtime.declarations)chunks.set(name,text);
  const typeBlocks = [...sourceDeclarations.declarations.values()].filter(row=>row.kind==="type").map(row=>sourceDeclarations.emit(row.name));
  let preamble = [source.slice(0,source.indexOf("type ")).trimEnd(),...typeBlocks,valueType,...runtime.typeDeclarations];
  const rawChunks = new Map(chunks);
  let loweredSource = [...preamble,...rawChunks.values()].join("\n\n")+"\n";
  if(process.argv.includes("--quantity-audit")){
    const origins=Object.fromEntries([...consumerQuantityOrigins].map(([name,bindings])=>[name,
      Object.fromEntries([...bindings].map(([binding,origin])=>[binding,{...origin,
        sourceSpan:origin.sourceSpan?{beg:origin.sourceSpan.beg,end:origin.sourceSpan.end,
          line:origin.sourceSpan.file.str.slice(0,origin.sourceSpan.beg).split("\n").length,
          text:origin.sourceSpan.file.str.slice(origin.sourceSpan.beg,origin.sourceSpan.end)}:undefined}]))]));
    const diagnosticPath=resolve(import.meta.dir,"../checkpoints/fuel-candidate-consumer-quantity-origins.json");
    writeFileSync(diagnosticPath,JSON.stringify({sourceSha256:expected,sourceSpecificTransformerExceptions:0,origins},null,2)+"\n");
    console.log(JSON.stringify({diagnosticPath,consumers:consumerQuantityOrigins.size,candidateWritten:false}));
    process.exit(0);
  }
  if (process.argv.includes("--fuel-parametric")) {
    const candidateOutput = output.replace(".bend", "_fuel.bend");
    const candidateChunks = new Map(rawChunks);
    candidateChunks.set("parse_with_fuel", `def parse_with_fuel(fuel: FeedbackFuel, file: String, source: String) -> FeedbackRun:
  feedback_drive(fuel, step_parse(file, source), Nil{})`);
    let candidateGraph = await readParserGraph([...preamble,...candidateChunks.values()].join("\n\n")+"\n", output);
    const quantityTypes = new LexicalTypes(candidateGraph.parserBook,candidateGraph.signatures);
    const patternQuantityLifting:Record<string,unknown>[]=[];
    for(const name of candidateGraph.definitions){
      const body=candidateGraph.bodies.get(name)!,signature=candidateGraph.signatures.get(name)!;
      if(!hasPatternQuantityBoundary(body))continue;
      quantityTypes.indexBody(body,signature.parameters,signature.result);
      const lowered=liftPatternQuantities(body,signature.parameters,signature.result,quantityTypes,name+"_quantity");
      for(const helper of lowered.helpers){
        const rendered=renderBody(helper.body,helper.parameters,{book:candidateGraph.parserBook,showTerm:surfaceExpression});
        const owner=sourceOwners.get(name);
        if(owner!==undefined)sourceOwners.set(helper.name,owner);
        candidateChunks.set(helper.name,sourceDefinition(helper.name,
          `def ${helper.name}(${rendered.parameters}) -> ${rendered.renderTerm(helper.result)}:\n${rendered.body}`));
      }
      const rendered=renderBody(lowered.body,signature.parameters,{book:candidateGraph.parserBook,showTerm:surfaceExpression});
      candidateChunks.set(name,sourceDefinition(name,
        `def ${name}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:\n${rendered.body}`));
      for(const field of lowered.lifted){
        const origin=consumerQuantityOrigins.get(name)?.get(field.name);
        patternQuantityLifting.push({definition:name,binderId:field.binderId,printedBinder:field.name,
          helper:field.helper,runtimeUses:field.runtimeUses,type:surfaceType(field.type),
          reason:origin?.reason??"synthesized-reuse",
          sourceBinder:origin?{id:origin.sourceBinderId,name:origin.sourceBinderName,
            span:origin.sourceSpan?{beg:origin.sourceSpan.beg,end:origin.sourceSpan.end,
              line:origin.sourceSpan.file.str.slice(0,origin.sourceSpan.beg).split("\n").length,
              text:origin.sourceSpan.file.str.slice(origin.sourceSpan.beg,origin.sourceSpan.end)}:undefined}:undefined});
      }
    }
    if(patternQuantityLifting.length)
      candidateGraph=await readParserGraph([...preamble,...candidateChunks.values()].join("\n\n")+"\n", output);
    const reachable = new Set<string>();
    const work = ["parse_with_fuel"];
    for (let index = 0; index < work.length; index++) {
      const name = work[index]!;
      if (reachable.has(name) || !candidateChunks.has(name)) continue;
      reachable.add(name);
      work.push(...(candidateGraph.edges[name] ?? []));
    }
    const ordered: string[] = [];
    const visited = new Set<string>(), visiting = new Set<string>();
    function orderCandidate(name: string): void {
      if (visited.has(name) || !reachable.has(name)) return;
      if (visiting.has(name)) throw new GenericLimitation("Fuel-parametric generated graph contains mutual recursion", {name,component:[...visiting]});
      visiting.add(name);
      for (const target of candidateGraph.edges[name] ?? []) if (target !== name) orderCandidate(target);
      visiting.delete(name);
      visited.add(name);
      ordered.push(candidateChunks.get(name)!);
    }
    for (const name of reachable) orderCandidate(name);
    const generated = ["# EXPERIMENTAL / FUEL-PARAMETRIC / NOT SELFHOST GREEN",...preamble,...ordered].join("\n\n")+"\n";
    const declarationMetadata = sourceDeclarations.audit(generated,sourceOwners);
    if(declarationMetadata.missing.length||declarationMetadata.spurious.length)
      throw new GenericLimitation("Generated declaration metadata differs from source ownership",declarationMetadata);
    writeFileSync(candidateOutput, generated);
    const scorecard = {...metadata(),status:"EXPERIMENTAL / FUEL-PARAMETRIC / NOT SELFHOST GREEN",automaticProductionFuelProof:"DEFERRED",candidateEmitted:true,completedLiftedBodies:steps.size,generatedBytes:Buffer.byteLength(generated),generatedLines:generated.split("\n").length-1,generatedSha256:createHash("sha256").update(generated).digest("hex"),publicEntry:"parse_with_fuel",fuel:{source:"explicit caller supplied FeedbackFuel",driver:"feedback_drive",recursiveArgument:"directly matched remaining cell tail",automaticBound:null},emittedDefinitions:ordered.length,declarationMetadata,patternQuantityLifting,harness:false};
    writeFileSync(candidateOutput+".scorecard.json",JSON.stringify(scorecard,null,2)+"\n");
    console.log(JSON.stringify({output:candidateOutput,...scorecard}));
    process.exit(0);
  }
  if (process.argv.includes("--frontier-model-input")) {
    writeFileSync(output+".frontier-source.bend", loweredSource);
    writeFileSync(output+".frontier-input.json", JSON.stringify({
      ...metadata(), authority:"semantic-input-only-not-a-certificate",
      completedLiftedBodies:steps.size,
    }, null, 2)+"\n");
    console.log(JSON.stringify({source:output+".frontier-source.bend",bodies:steps.size}));
    process.exit(0);
  }
  let loweredAST = await readParserGraph(loweredSource, output);
  const restitution = optimizeCursorRestitution(loweredAST, tokenElement);
  for (const name of restitution.changed) {
    const signature = restitution.signatures.get(name)!;
    const rendered = renderBody(restitution.bodies.get(name)!, signature.parameters, {
      book: loweredAST.parserBook, showTerm: surfaceExpression,
    });
    const declaration = sourceDefinition(name,`def ${name}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:\n${rendered.body}`);
    chunks.set(name, declaration);
    rawChunks.set(name, declaration);
  }
  if (restitution.changed.size) {
    loweredSource = [...preamble,...rawChunks.values()].join("\n\n")+"\n";
    loweredAST = await readParserGraph(loweredSource, output);
  }
  // Consumer specialization makes some original wrappers obsolete. Keep every
  // lowered facade target and every runtime entry; prune only AST-unreferenced
  // semantic declarations, never a source-name exception.
  const liveDefinitions = new Set([...steps.keys(), ...runtime.declarations.keys()]);
  const liveWork = [...liveDefinitions];
  for (let index = 0; index < liveWork.length; index++) {
    for (const dependency of loweredAST.edges[liveWork[index]!] ?? []) if (!liveDefinitions.has(dependency)) {
      liveDefinitions.add(dependency);
      liveWork.push(dependency);
    }
  }
  for (const name of effectDefinitions) if (!liveDefinitions.has(name)) {
    chunks.delete(name);
    rawChunks.delete(name);
  }
  effectDefinitions = effectDefinitions.filter(name => liveDefinitions.has(name));
  const primitiveOperations = new Map<string, ExplicitPrimitiveOperation>();
  for(const name of runtime.declarations.keys())primitiveOperations.set(name, {kind:"call"});
  primitiveOperations.set("feedback_prefix", {kind:"call", carriesControl:true});
  primitiveOperations.set("feedback_prefix_inherited", {kind:"call", carriesControl:true});
  primitiveOperations.set("feedback_attach", {kind:"suspend", carriesControl:true, frameArgument:1, captureName:"feedback_attach_with_progress"});
  primitiveOperations.set("feedback_attach_with_progress", {kind:"suspend", carriesControl:true, frameArgument:2});
  primitiveOperations.set("feedback_dispatch", {kind:"call", carriesControl:true});
  primitiveOperations.set("feedback_resume", {kind:"resume", carriesControl:true});
  primitiveOperations.set("feedback_resume_frame", {kind:"resume", carriesControl:true});
  primitiveOperations.set("feedback_pack_resume", {kind:"resume", carriesControl:true});
  for(const name of selected)primitiveOperations.set("feedback_make_"+name, {
    kind:"request", activeArguments:params(name).map((_,index)=>index),
  });
  const parameterWitnesses = new Map<string, {parameterIndex:number;witnessName:string}[]>();
  for(const frame of frames){
    const factoryName="feedback_make_"+frame.name;
    const signature=loweredAST.signatures.get(factoryName);
    if(!signature)throw new GenericLimitation("Missing generated frame factory signature", {factoryName});
    const semanticFieldCount=frame.fields.flatMap(field=>productFields(field.name,product(field.type))).length;
    frame.witnesses=frame.fields.flatMap((_,index)=>containsTokenCursor(loweredAST,signature.parameters[index]![3],tokenElement)?
      [{argumentIndex:index,parameterIndex:index,frameFieldIndex:0,witnessName:"feedback_witness_"+index}]:[]);
    frame.witnesses.forEach((witness,index)=>witness.frameFieldIndex=semanticFieldCount+index);
    primitiveOperations.set(factoryName, {
      kind:"suspend", captureArguments:frame.witnesses.map(witness=>({index:witness.argumentIndex,witnessName:witness.witnessName})),
    });
    parameterWitnesses.set("feedback_resume_"+frame.name, frame.witnesses.map(witness=>({
      parameterIndex:witness.parameterIndex,witnessName:witness.witnessName,
    })));
  }
  families.forEach((_,index)=>primitiveOperations.set("feedback_pack_"+index, {kind:"return", activeArguments:[0], carriesControl:true}));
  let explicitProgram: ExplicitProgressProgram;
  try {
    explicitProgram = instrumentExplicitProgress(loweredAST, {
      definitions:effectDefinitions, nameOf:name=>name, controlType:"FeedbackControl", tokenElement,
      progressType:"Progress", composeName:"feedback_compose_progress", prefixName:"feedback_prefix",
      primitiveOperations, parameterWitnesses, emitPrelude:false,
      driverEntryPoints:[...[...selected].map(name=>"step_"+name),...frames.map(frame=>"feedback_resume_"+frame.name)],
    });
  } catch(error) {
    throw new GenericLimitation("Unsupported explicit-effect instrumentation", {
      reason:error instanceof Error ? error.message : String(error),
      instrumentationEvidence:astShape(error), effectDefinitions,
    });
  }
  for(const [name,text] of explicitProgram.declarationMap)chunks.set(name,sourceDefinition(name,text));
  for(const [name,text] of explicitProgram.supportDeclarations)chunks.set(name,text);
  for (const name of selected) {
    const witnesses = explicitProgram.parameterWitnesses.get("step_"+name) ?? [];
    const request = primitiveOperations.get("feedback_make_"+name);
    // Request construction activates and retires every semantic cursor input.
    // A dispatched step therefore has no outstanding input-head credit.
    if (request?.kind !== "request" || witnesses.some(witness =>
      !request.activeArguments?.includes(witness.parameterIndex))) {
      throw new GenericLimitation("Unsettled cursor witness at request dispatch", {name, witnesses});
    }
    dispatchWitnesses.set(name, witnesses.map(() => "WitnessNone{}"));
  }
  for(const frame of frames){
    const witnesses=frame.witnesses??[];
    const semanticFields=frame.fields.flatMap(field=>productFields(field.name,product(field.type)));
    chunks.set("feedback_make_"+frame.name,maker("feedback_make_"+frame.name,
      [...frame.fields,...witnesses.map(witness=>({name:witness.witnessName,type:"FeedbackCursorWitness"}))],
      "FeedbackFrame",frame.name+"{"+semanticFields.map(field=>field.name).concat(witnesses.map(witness=>witness.witnessName)).join(", ")+"}"));
  }
  runtime=renderRuntime();
  for(const [name,text] of runtime.declarations)chunks.set(name,text);
  preamble=[source.slice(0,source.indexOf("type ")).trimEnd(),...typeBlocks,valueType,...runtime.typeDeclarations];
  const finalABIgraph=await readParserGraph([...preamble,...chunks.values()].join("\n\n")+"\n", output);
  // The sole termination decision is made after the real effect writer has
  // instrumented every semantic body. Historical provenance is not consulted.
  const progress = await buildExplicitProgressCertificate(explicitProgram, {
    graph:finalABIgraph, sourceGraph:parserAST, lifted, selected, classifications, frames,
    steps, consumerHelpers, runtimeBlocks:runtime.declarations, rawChunks,
  });
  const progressPath = output + ".progress.json";
  writeFileSync(progressPath, JSON.stringify({sourceCheckpoint:"0d0e204f", sourceSha256:expected,
    authority:"explicit-generated-Progress", ...progress}, null, 2) + "\n");
  progressSummary = {path:progressPath, authority:"explicit-generated-Progress", status:progress.status,
    counts:progress.counts, machineCycle:progress.smallestRemainingCycle, bound:progress.bound};
  if (!progress.certified) throw new GenericLimitation("NoProgress machine cycle prevents finite termination certification", {
    progress:progressSummary, evidenceType:"B",
    reusableRule:"Explicit generated NoProgress transitions retain a finite cycle; emission stopped without a second analysis",
  });
  if(process.argv.includes("--certificate-only")){
    console.log(JSON.stringify({sourceCheckpoint:"0d0e204f",sourceSha256:expected,certificate:progress.status,counts:progress.counts,H:progress.bound.H}));
    process.exit(0);
  }
  const rank = progress.administrativeRanks;
  const transitionFactor = progress.bound.transitionFactor!;
  let structuralFuel: StructuralFeedbackFuelProgram;
  try {
    structuralFuel = renderStructuralFeedbackFuel(finalABIgraph, progress.bound.H!);
  } catch(error) {
    throw new GenericLimitation("Unsupported structural initial-cursor fuel projection", {
      reason:error instanceof Error ? error.message : String(error),
    });
  }
  for(const [name,text] of structuralFuel.declarations)chunks.set(name,text);
  for (const name of lifted) {
    const fields = params(name);
    const flat = fields.flatMap(field => productFields(field.name, product(field.type)));
    const arguments_ = fields.map(field => productValue(field.name, product(field.type)));
    const enter = "feedback_enter_" + name;
    chunks.set(enter, "def " + enter + "(" + flat.map(field => "+" + field.name + ": " + field.type).join(", ") +
      ") -> FeedbackRun:\n  feedback_start(" + controlCall(name, arguments_) + ")");
    sourceOwners.set(name,name);
    chunks.set(name, sourceDefinition(name,maker(name, fields, "FeedbackRun", enter + "(" + flat.map(field => field.name).join(", ") + ")")));
  }
  const ordered:string[]=[]; const visited=new Set<string>();const visiting=new Set<string>();
  function order(name:string):void {if(visited.has(name))return;if(visiting.has(name))throw new GenericLimitation("Emitted dependency graph still contains mutual recursion",{component:[...visiting],name});visiting.add(name);const text=chunks.get(name)!;for(const match of text.matchAll(/\b([A-Za-z_]\w*)\(/g)){const target=match[1]!;if(target!==name&&chunks.has(target))order(target);}visiting.delete(name);visited.add(name);ordered.push(text);}
  for(const name of chunks.keys())order(name);
  const generated=["# Mechanically generated complete parser; no restricted harness",...preamble,...ordered].join("\n\n")+"\n";
  writeFileSync(output,generated);
  const scorecard={...metadata(),generatedSha256:createHash("sha256").update(generated).digest("hex"),genericTailSites:tailRules,genericNonTailSites:frames.length,genericTerminalSites:leafRules,progress,administrativeRanks:rank,transitionFactor,fuel:{representation:"direct matched FeedbackFuel cell spine",chunkCells:structuralFuel.chunkCells,tokenCellDefinition:structuralFuel.tokenCellDefinition},generatedBytes:Buffer.byteLength(generated),generatedLines:generated.split("\n").length-1,harness:false};
  writeFileSync(output+".scorecard.json",JSON.stringify(scorecard,null,2)+"\n");
  console.log(JSON.stringify({output,...scorecard}));
}catch(error){
  if (!(error instanceof GenericLimitation)) {
    if (error && typeof error === "object" && "$" in error && error.$ === "Err")
      throw Error(err_show(error as Err));
    throw error;
  }
  const limitation = {message: error.message, ...error.evidence};
  const evidence={...metadata(),status:progressSummary?"FULL GENERATION STOPPED AT TERMINATION CERTIFICATE":"FULL GENERATION STOPPED AT GENERIC CONTROL SHAPE",candidateEmitted:false,completedLiftedBodies:[...steps.keys()],limitation};
  writeFileSync(output+".limitation.json",JSON.stringify(evidence,null,2)+"\n");
  console.error(JSON.stringify(evidence,null,2));
  process.exitCode=1;
}
