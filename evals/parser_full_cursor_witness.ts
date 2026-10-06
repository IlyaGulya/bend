/** Control-only structural tail witnesses. Helpers inspect metadata, never tokens. */
import { type Body, type Book, type LTerm, type Patt, type PVar } from "../bend2/bend.ts";
import { renderBody } from "./parser_full_body_render.ts";
import type { ParserParameter, ParserSignature } from "./parser_full_graph.ts";

export type WitnessCaptureArgument = { index: number; witnessName: string };
export type WitnessParameter = { parameterIndex: number; witnessName: string };
export type WitnessRuntimeFunction = { body: Body; signature: ParserSignature };
export type WitnessRuntime = { declarations: Map<string, string>; functions: Map<string, WitnessRuntimeFunction>; typeDeclarations: string[] };
export function createCursorWitnessRuntime(book: Book, fresh: () => number, config: { typeName: string; progressType: string; composeName: string }): WitnessRuntime {
  const many = { $: "Many" } as const;
  const lone = { $: "Lone" } as const;
  const reference = (k: string): LTerm => ({ $: "Ref", k });
  const constructor = (k: string, ...x: LTerm[]): LTerm => ({ $: "Ctr", k, x });
  const call = (k: string, ...args: LTerm[]): LTerm => args.reduce<LTerm>((f, x) => ({ $: "App", f, x }), reference(k));
  const variable = (pattern: PVar): LTerm => ({ $: "Var", k: pattern.k, i: pattern.i });
  const pattern = (k: string): PVar => ({ $: "PVar", k, i: fresh(), q: many });
  const wildcard = (): PVar => ({ $: "PVar", k: "_", i: fresh(), q: lone });
  const cp = (k: string, ...x: Patt[]): Patt => ({ $: "PCtr", k, x });
  const reply = (x: LTerm): Body => ({ $: "Reply", x });
  const witness = reference(config.typeName), progress = reference(config.progressType), nat = reference("Nat");
  const list = (type: LTerm): LTerm => ({ $: "ADT", k: "List", x: [{ $: "Qua", q: many }, type], r: [] });
  const pathType = list(nat), fieldsType = list(witness);
  const declarations = new Map<string, string>(), functions = new Map<string, WitnessRuntimeFunction>();
  function add(name: string, parameters: [PVar, LTerm][], result: LTerm, body: Body): void {
    const signature: ParserSignature = { parameters: parameters.map(([p, type]) => [p.q, p.k, p.i, type, { src: "", beg: 0, end: 0 }] as ParserParameter), result };
    const rendered = renderBody(body, signature.parameters, { book });
    declarations.set(name, `def ${name}(${rendered.parameters}) -> ${rendered.renderTerm(result)}:\n${rendered.body}`);
    functions.set(name, { signature, body });
  }
  {
    const fields = pattern("fields"), tail = pattern("tail"), p = pattern("progress"), children = pattern("children");
    add("feedback_witness_list_progress", [[fields, fieldsType]], progress, { $: "Match", e: [variable(fields)], r: [
      { p: [cp("Nil")], f: reply(constructor("NoProgress")) },
      { p: [cp("Con", cp("WitnessNone"), tail)], f: reply(call("feedback_witness_list_progress", variable(tail))) },
      { p: [cp("Con", cp("WitnessTail", p), tail)], f: reply(call(config.composeName, variable(p), call("feedback_witness_list_progress", variable(tail)))) },
      { p: [cp("Con", cp("WitnessFields", children), tail)], f: reply(call(config.composeName, call("feedback_witness_list_progress", variable(children)), call("feedback_witness_list_progress", variable(tail)))) },
    ] });
  }
  {
    const w = pattern("w"), p = pattern("progress"), fields = pattern("fields");
    add("feedback_witness_progress", [[w, witness]], progress, { $: "Match", e: [variable(w)], r: [
      { p: [cp("WitnessNone")], f: reply(constructor("NoProgress")) },
      { p: [cp("WitnessTail", p)], f: reply(variable(p)) },
      { p: [cp("WitnessFields", fields)], f: reply(call("feedback_witness_list_progress", variable(fields))) },
    ] });
  }
  {
    const index = pattern("index"), fields = pattern("fields"), head = pattern("head"), tail = pattern("tail"), rest = pattern("rest");
    add("feedback_witness_nth", [[index, nat], [fields, fieldsType]], witness, { $: "Match", e: [variable(index), variable(fields)], r: [
      { p: [cp("Zero"), cp("Nil")], f: reply(constructor("WitnessNone")) },
      { p: [cp("Zero"), cp("Con", head, wildcard())], f: reply(variable(head)) },
      { p: [cp("Succ", rest), cp("Nil")], f: reply(constructor("WitnessNone")) },
      { p: [cp("Succ", rest), cp("Con", wildcard(), tail)], f: reply(call("feedback_witness_nth", variable(rest), variable(tail))) },
    ] });
  }
  {
    const path = pattern("path"), w = pattern("w"), index = pattern("index"), rest = pattern("rest"), fields = pattern("fields"), whole = pattern("whole");
    add("feedback_witness_get", [[path, pathType], [w, witness]], witness, { $: "Match", e: [variable(path), variable(w)], r: [
      { p: [cp("Nil"), whole], f: reply(variable(whole)) },
      { p: [cp("Con", index, rest), cp("WitnessFields", fields)], f: reply(call("feedback_witness_get", variable(rest), call("feedback_witness_nth", variable(index), variable(fields)))) },
      { p: [cp("Con", wildcard(), wildcard()), cp("WitnessNone")], f: reply(constructor("WitnessNone")) },
      { p: [cp("Con", wildcard(), wildcard()), cp("WitnessTail", wildcard())], f: reply(constructor("WitnessNone")) },
    ] });
  }
  {
    const path = pattern("path"), w = pattern("w"), index = pattern("index"), rest = pattern("rest"), fields = pattern("fields"), p = pattern("progress");
    add("feedback_witness_clear", [[path, pathType], [w, witness]], witness, { $: "Match", e: [variable(path), variable(w)], r: [
      { p: [cp("Nil"), wildcard()], f: reply(constructor("WitnessNone")) },
      { p: [cp("Con", index, rest), cp("WitnessFields", fields)], f: reply(constructor("WitnessFields", call("feedback_witness_clear_fields", variable(fields), variable(index), variable(rest)))) },
      { p: [cp("Con", wildcard(), wildcard()), cp("WitnessNone")], f: reply(constructor("WitnessNone")) },
      { p: [cp("Con", wildcard(), wildcard()), cp("WitnessTail", p)], f: reply(constructor("WitnessTail", variable(p))) },
    ] });
  }
  {
    const index = pattern("index"), path = pattern("path"), fields = pattern("fields"), head = pattern("head"), tail = pattern("tail"), rest = pattern("rest"), childIndex = pattern("child_index"), childPath = pattern("child_path"), children = pattern("children"), p = pattern("progress");
    add("feedback_witness_clear_fields", [[fields, fieldsType], [index, nat], [path, pathType]], fieldsType, { $: "Match", e: [variable(fields), variable(index), variable(path)], r: [
      { p: [cp("Nil"), cp("Zero"), wildcard()], f: reply(constructor("Nil")) },
      { p: [cp("Con", wildcard(), tail), cp("Zero"), cp("Nil")], f: reply(constructor("Con", constructor("WitnessNone"), variable(tail))) },
      { p: [cp("Con", cp("WitnessNone"), tail), cp("Zero"), cp("Con", wildcard(), wildcard())], f: reply(constructor("Con", constructor("WitnessNone"), variable(tail))) },
      { p: [cp("Con", cp("WitnessTail", p), tail), cp("Zero"), cp("Con", wildcard(), wildcard())], f: reply(constructor("Con", constructor("WitnessTail", variable(p)), variable(tail))) },
      { p: [cp("Con", cp("WitnessFields", children), tail), cp("Zero"), cp("Con", childIndex, childPath)], f: reply(constructor("Con", constructor("WitnessFields", call("feedback_witness_clear_fields", variable(children), variable(childIndex), variable(childPath))), variable(tail))) },
      { p: [cp("Nil"), cp("Succ", rest), path], f: reply(constructor("Nil")) },
      { p: [cp("Con", head, tail), cp("Succ", rest), path], f: reply(constructor("Con", variable(head), call("feedback_witness_clear_fields", variable(tail), variable(rest), variable(path)))) },
    ] });
  }
  return { declarations, functions, typeDeclarations: book.tlds[config.typeName] ? [] : [`type ${config.typeName} is Data:\n  WitnessNone{}\n  WitnessTail{progress: ${config.progressType}}\n  WitnessFields{fields: List<&2, ${config.typeName}>}`] };
}
