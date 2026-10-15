import { expect, test } from "bun:test";
import type { Body, LTerm, Patt } from "../bend2/bend.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { LexicalTypes, freeBinderIds } from "./parser_full_type_env.ts";
import { planCaptures } from "./parser_full_capture.ts";
import { specializeConsumer } from "./parser_full_consumer.ts";

type Value = { kind: "constructor"; name: string; fields: Value[] }
  | { kind: "call"; name: string; args: Value[] }
  | { kind: "lambda"; id: number; body: LTerm; env: ReadonlyMap<number, Value> };
const token = (name: string): Value => ({ kind: "constructor", name, fields: [] });
function evaluate(term: LTerm, env: ReadonlyMap<number, Value>): Value {
  switch (term.$) {
    case "Var": { const value = env.get(term.i); if (!value) throw Error("Unbound ID " + term.i); return value; }
    case "Ctr": return { kind: "constructor", name: term.k, fields: term.x.map(child => evaluate(child, env)) };
    case "Ref": return { kind: "call", name: term.k, args: [] };
    case "Lam": return { kind: "lambda", id: term.i, body: term.f, env };
    case "App": {
      const fn = evaluate(term.f, env), arg = evaluate(term.x, env);
      if (fn.kind === "lambda") return evaluate(fn.body, new Map([...fn.env, [fn.id, arg]]));
      if (fn.kind === "call") return { ...fn, args: [...fn.args, arg] };
      throw Error("Applied constructor");
    }
    case "Ann": return evaluate(term.x, env);
    default: throw Error("Fixture evaluator does not implement " + term.$);
  }
}
function bind(pattern: Patt, value: Value, env: Map<number, Value>): boolean {
  if (pattern.$ === "PVar") { if (pattern.k !== "_") env.set(pattern.i, value); return true; }
  return value.kind === "constructor" && pattern.k === value.name && pattern.x.length === value.fields.length
    && pattern.x.every((child, index) => bind(child, value.fields[index]!, env));
}
function resume(body: Body, env: ReadonlyMap<number, Value>): Value {
  if (body.$ !== "Local" && body.$ !== "Match") return evaluate(body, env);
  if (body.$ === "Local") {
    const local = new Map(env), values = body.v.map(term => evaluate(term, env));
    if (!body.k.every((pattern, index) => bind(pattern, values[index]!, local))) throw Error("Local pattern failed");
    return resume(body.f, local);
  }
  const values = body.e.map(term => evaluate(term, env));
  for (const row of body.r) {
    const local = new Map(env);
    if (row.p.every((pattern, index) => bind(pattern, values[index]!, local))) return resume(row.f, local);
  }
  throw Error("No matching consumer branch");
}
async function fixture(consumer: string, callback: string, ownerParameters = "seed: Token", ownerArguments = "seed") {
  const graph = await readParserGraph(`import Base
type Token is Data:
  Red{}
  Blue{}

def request(a: Token, b: Token) -> Token:
  a
${consumer}
def owner(${ownerParameters}) -> Token:
  consume(${ownerArguments}, ${callback})
`);
  const signature = graph.signatures.get("consume")!, source = graph.bodies.get("consume")!;
  const lexical = new LexicalTypes(graph.parserBook, graph.signatures), owner = graph.signatures.get("owner")!;
  lexical.indexBody(graph.bodies.get("owner")!, owner.parameters, owner.result);
  const site = graph.calls.get("owner")!.find(call => call.callee === "consume")!;
  const callbackAST = site.args.at(-1)!;
  const plan = planCaptures([callbackAST], lexical);
  const argument = { $: "Var", i: 10000, k: "result" } as const;
  const captures = plan.fields.map((field): typeof signature.parameters[number] =>
    [field.quantity, field.name, field.id, field.type, signature.parameters[0]![4]]);
  const specialized = specializeConsumer(source, signature,
    new Map([[signature.parameters.at(-1)![2], plan.callbacks[0]!]]),
    new Map([[signature.parameters[0]![2], argument]]), captures);
  const env = new Map<number, Value>(plan.fields.map(field => [field.id, token("Blue")]));
  return { source, signature, specialized, env, argument, plan };
}
function tupleValue(pattern: Patt, values: Value[]): Value {
  if (pattern.$ === "PVar") { const value = values.shift(); if (!value) throw Error("Missing tuple payload"); return value; }
  return { kind: "constructor", name: pattern.k, fields: pattern.x.map(child => tupleValue(child, values)) };
}

test("source tuple Match resumes an effectful callback with result payloads and typed captures", async () => {
  const f = await fixture(`def consume(result: (Token & Token) & Bool, callback: Token -> Token -> Bool -> Token) -> Token:
  match result:
    case ((term, after), ok):
      callback(term, after, ok)
`, "next_head => after_head => ok_head => request(next_head, seed)", "seed: Token, pair: (Token & Token) & Bool", "pair");
  if (f.source.$ !== "Match" || f.specialized.body.$ !== "Match") throw Error("Expected source Match");
  f.env.set(f.argument.i, tupleValue(f.source.r[0]!.p[0]!, [token("Red"), token("Blue"), token("True")]));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Red"), token("Blue")] });
  expect(f.specialized.parameters.map(parameter => parameter[2])).toEqual([f.argument.i, ...f.plan.fields.map(field => field.id)]);
  expect(f.specialized.result).toEqual(f.signature.result);
});

test("a pure constructor branch stays pure while the callback branch emits its request", async () => {
  const f = await fixture(`def consume(result: Token, callback: Token -> Token) -> Token:
  match result:
    case Red{}:
      Blue{}
    case Blue{}:
      callback(Red{})
`, "next_head => request(next_head, seed)");
  f.env.set(f.argument.i, token("Red"));
  expect(resume(f.specialized.body, f.env)).toEqual(token("Blue"));
  f.env.set(f.argument.i, token("Blue"));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Red"), token("Blue")] });
});

test("nested Local and Match scopes preserve the captured field despite shadowed names and IDs", async () => {
  const f = await fixture(`def consume(result: Token, callback: Token -> Token) -> Token:
  seed = result
  match seed:
    case Red{}:
      seed = Blue{}
      callback(seed)
    case Blue{}:
      callback(Red{})
`, "next_head => request(next_head, seed)");
  f.env.set(f.argument.i, token("Red"));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Blue"), token("Blue")] });
  f.env.set(f.argument.i, token("Blue"));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Red"), token("Blue")] });
  expect(f.specialized.parameters.find(parameter => parameter[2] === f.plan.fields[0]!.id)![0].$).toBe("Lone");
});

test("curried beta reduction respects a shadowing lambda without substituting its free capture", async () => {
  const f = await fixture(`def consume(result: Token, callback: Token -> Token -> Token) -> Token:
  callback(result)(Blue{})
`, "next_head => next_head => request(seed, next_head)");
  f.env.set(f.argument.i, token("Red"));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Blue"), token("Blue")] });
  if (f.specialized.body.$ === "Local" || f.specialized.body.$ === "Match") throw Error("Expected a terminal term");
  expect(freeBinderIds(f.specialized.body)).toEqual(f.plan.fields.map(field => field.id));
});

test("callback expansion under a nested lambda keeps its parameter distinct from captured IDs", async () => {
  const f = await fixture(`def consume(result: Token, callback: Token -> Token) -> Token:
  (seed => callback(seed))(result)
`, "next_head => request(next_head, seed)");
  f.env.set(f.argument.i, token("Red"));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Red"), token("Blue")] });
});

test("beta duplication promotes the payload binder but not the one-use result parameter", async () => {
  const f = await fixture(`def consume(result: Token & Bool, callback: Token -> Token) -> Token:
  match result:
    case (head, ok):
      callback(head)
`, "next_head => request(next_head, next_head)", "pair: Token & Bool", "pair");
  if (f.source.$ !== "Match" || f.specialized.body.$ !== "Match") throw Error("Expected Match");
  const payload = f.specialized.body.r[0]!.p[0]!;
  if (payload.$ !== "PCtr" || payload.x[0]!.$ !== "PVar") throw Error("Expected tuple payload binder");
  expect(payload.x[0]!.q.$).toBe("Many");
  expect(f.specialized.parameters[0]![0].$).toBe("Lone");
  f.env.set(f.argument.i, tupleValue(f.source.r[0]!.p[0]!, [token("Red"), token("True")]));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Red"), token("Red")] });
});

test("duplicated callback captures become unrestricted only in the resume telescope", async () => {
  const f = await fixture(`def consume(result: Token, callback: Token -> Token) -> Token:
  callback(result)
`, "next_head => request(seed, seed)");
  expect(f.specialized.parameters.find(parameter => parameter[2] === f.plan.fields[0]!.id)![0].$).toBe("Many");
  expect(f.plan.fields[0]!.quantity.$).toBe("Lone");
  f.env.set(f.argument.i, token("Red"));
  expect(resume(f.specialized.body, f.env)).toEqual({ kind: "call", name: "request", args: [token("Blue"), token("Blue")] });
});
