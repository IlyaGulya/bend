import { describe, expect, test } from "bun:test";
import { term_show, type LTerm } from "../bend2/bend.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { freeBinderIds, LexicalTypes, termChildren } from "./parser_full_type_env.ts";
import { planCaptures, renderCaptureFields, renderCaptureParameters } from "./parser_full_capture.ts";

async function fixture(source: string, owner = "example") {
  const graph = await readParserGraph(source);
  const types = new LexicalTypes(graph.parserBook, graph.signatures);
  const signature = graph.signatures.get(owner)!;
  types.indexBody(graph.bodies.get(owner)!, signature.parameters, signature.result);
  const callbacks = graph.calls.get(owner)!.flatMap(call => call.args).filter(
    (term): term is Extract<LTerm, { $: "Lam" }> => term.$ === "Lam");
  return { graph, types, callbacks };
}

function fields(types: LexicalTypes, callback: Extract<LTerm, { $: "Lam" }>) {
  return types.captures(callback).map(binding => ({
    name: binding.name, type: term_show(binding.type), quantity: binding.quantity.$,
  }));
}

describe("lexical callback captures", () => {
  test("a formal is captured with its declared type and quantity", async () => {
    const { types, callbacks } = await fixture(`
type Token is Data:
  Token{}
def invoke(k: Token -> Token) -> Token:
  k(Token{})
def example(+seed: Token) -> Token:
  invoke(ignored => seed)
`);
    expect(fields(types, callbacks[0]!)).toEqual([
      { name: "seed", type: "Token", quantity: "Many" },
    ]);
    const plan = planCaptures([callbacks[0]!], types);
    expect(renderCaptureFields(plan, term_show)).toContain(": Token");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Token");
  });

  test("a local derives its type from its RHS, not its name or callback use", async () => {
    const { types, callbacks } = await fixture(`
type Token is Data:
  Token{}
def identity(x: Token) -> Token:
  x
def invoke(k: Token -> Token) -> Token:
  k(Token{})
def example(seed: Token) -> Token:
  value = identity(seed)
  invoke(ignored => value)
`);
    const plan = planCaptures([callbacks[0]!], types);
    expect(fields(types, callbacks[0]!)).toEqual([
      { name: "value", type: "Token", quantity: "Lone" },
    ]);
    expect(renderCaptureFields(plan, term_show)).toContain(": Token");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Token");
  });

  test("product payloads project through the instantiated Sigma telescope", async () => {
    const { types, callbacks } = await fixture(`
import Base
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(pair: Nat & Bool) -> Nat:
  match pair:
    case (value, _):
      invoke(ignored => value)
`);
    const plan = planCaptures([callbacks[0]!], types);
    expect(fields(types, callbacks[0]!)).toEqual([
      { name: "value", type: "Nat", quantity: "Lone" },
    ]);
    expect(renderCaptureFields(plan, term_show)).toContain(": Nat");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Nat");
  });

  test("nested product patterns retain the projected payload type", async () => {
    const { types, callbacks } = await fixture(`
import Base
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(pair: (Nat & Bool) & Bool) -> Nat:
  match pair:
    case ((value, _), True{}):
      invoke(ignored => value)
    case _:
      0n
`);
    const plan = planCaptures([callbacks[0]!], types);
    expect(fields(types, callbacks[0]!)).toEqual([{ name: "value", type: "Nat", quantity: "Lone" }]);
    expect(renderCaptureFields(plan, term_show)).toContain(": Nat");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Nat");
  });

  test("constructor payload types instantiate datatype parameters", async () => {
    const { types, callbacks } = await fixture(`
import Base
type Box<-A: Type> is Type:
  Packed{value: A}
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(box: Box<Nat>) -> Nat:
  match box:
    case Packed{value}:
      invoke(ignored => value)
`);
    const plan = planCaptures([callbacks[0]!], types);
    expect(fields(types, callbacks[0]!)).toEqual([{ name: "value", type: "Nat", quantity: "Lone" }]);
    expect(renderCaptureFields(plan, term_show)).toContain(": Nat");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Nat");
  });

  test("one continuation captures a formal and a nested pattern payload", async () => {
    const { types, callbacks } = await fixture(`
import Base
def add(a: Nat, b: Nat) -> Nat:
  a
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(+seed: Nat, pair: Nat & Bool) -> Nat:
  match pair:
    case (value, _):
      invoke(ignored => add(seed, value))
`);
    const plan = planCaptures([callbacks[0]!], types);
    expect(fields(types, callbacks[0]!)).toEqual([
      { name: "seed", type: "Nat", quantity: "Many" },
      { name: "value", type: "Nat", quantity: "Lone" },
    ]);
    expect(renderCaptureFields(plan, term_show)).toMatch(/Nat.*Nat/);
    expect(renderCaptureParameters(plan, "resume", term_show)).toMatch(/Nat.*Nat/);
  });

  test("a nested continuation captures its outer lambda parameter by ID", async () => {
    const { types, callbacks } = await fixture(`
import Base
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(seed: Nat) -> Nat:
  invoke(outer => invoke(inner => outer))
`);
    const nested = callbacks.find(callback => callback.k === "inner")!;
    const plan = planCaptures([nested], types);
    expect(fields(types, nested)).toEqual([{ name: "outer", type: "Nat", quantity: "Lone" }]);
    expect(renderCaptureFields(plan, term_show)).toContain(": Nat");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Nat");
  });

  test("shadowed names resolve by ID and branch-local binders leave scope", async () => {
    const { graph, types, callbacks } = await fixture(`
import Base
type Box is Data:
  Packed{value: Nat}
  Vacant{}
def invoke_nat(k: Nat -> Nat) -> Nat:
  k(0n)
def invoke_bool(k: Bool -> Bool) -> Nat:
  0n
def example(+value: Bool, box: Box) -> Nat:
  match box:
    case Packed{value}:
      invoke_nat(ignored => value)
    case Vacant{}:
      invoke_bool(ignored => value)
`);
    const [inner, outer] = callbacks;
    const formalId = graph.signatures.get("example")!.parameters[0]![2];
    const payloadId = types.captures(inner!)[0]!.id;
    expect(payloadId).not.toBe(formalId);
    expect(fields(types, inner!)).toEqual([{ name: "value", type: "Nat", quantity: "Lone" }]);
    expect(fields(types, outer!)).toEqual([{ name: "value", type: "Bool", quantity: "Many" }]);
    expect(types.environmentAt(inner!).has(payloadId)).toBe(true);
    expect(types.environmentAt(outer!).has(payloadId)).toBe(false);
    expect(types.environmentAt(inner!).get(formalId)!.quantity.$).toBe("Many");
    expect(renderCaptureParameters(planCaptures([inner!], types), "resume", term_show)).not.toMatch(/\+capture_/);
  });

  test("wildcard positions do not bind and pattern ownership is retained", async () => {
    const { types, callbacks } = await fixture(`
import Base
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(pair: Bool & Nat) -> Nat:
  match pair:
    case (_, +value):
      invoke(ignored => value)
`);
    expect([...types.environmentAt(callbacks[0]!).values()].some(binding => binding.name === "_")).toBe(false);
    expect(fields(types, callbacks[0]!)).toEqual([{ name: "value", type: "Nat", quantity: "Many" }]);
  });

  test("let and lambda boundaries exclude internal binders from outer captures", async () => {
    const { types, callbacks } = await fixture(`
import Base
def choose(a: Nat, b: Nat) -> Nat:
  a
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(seed: Nat) -> Nat:
  invoke(argument => invoke(argument => (local = argument; choose(local, seed))))
`);
    const outer = callbacks[0]!;
    expect(fields(types, outer)).toEqual([{ name: "seed", type: "Nat", quantity: "Lone" }]);
    expect(types.captures(outer).map(binding => binding.name)).not.toContain("argument");
    const plan = planCaptures([outer], types);
    expect(renderCaptureParameters(plan, "resume", term_show)).not.toMatch(/\+capture_/);
  });

  test("a missing lambda domain is a structured error rather than a name guess", async () => {
    const { graph, types } = await fixture(`
import Base
def example(seed: Nat) -> Nat -> Nat -> Nat:
  outer => inner => outer
`);
    // An intentionally untyped isolated lambda has no goal to establish outer's
    // domain. The identical parsed AST is indexable, but cannot safely capture it.
    const body = graph.bodies.get("example")!;
    expect(body.$).toBe("Lam");
    if (body.$ !== "Lam" || body.f.$ !== "Lam") throw Error("Expected parsed lambdas");
    const untyped = new LexicalTypes(graph.parserBook, graph.signatures);
    untyped.indexBody(body, graph.signatures.get("example")!.parameters);
    expect(() => planCaptures([body.f], untyped)).toThrow("lambda parameter has no declared domain");
    expect(types.captures(body.f).map(binding => term_show(binding.type))).toEqual(["Nat"]);
  });

  test("constructor-valued locals infer datatype arguments from typed payloads", async () => {
    const { types, callbacks } = await fixture(`
import Base
type Box<-A: Type> is Type:
  Packed{value: A}
def invoke(k: Nat -> Box<Nat>) -> Box<Nat>:
  k(0n)
def example(seed: Nat) -> Box<Nat>:
  payload = Packed{seed}
  invoke(ignored => payload)
`);
    const plan = planCaptures([callbacks[0]!], types);
    expect(fields(types, callbacks[0]!)).toEqual([{ name: "payload", type: "Box<Nat>", quantity: "Lone" }]);
    expect(renderCaptureFields(plan, term_show)).toContain(": Box<Nat>");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Box<Nat>");
  });

  test("compact literals remain native leaves with their declared lexical types", async () => {
    const source = `import Base
def example() -> String:
  "λ𝄞"
`;
    const graph = await readParserGraph(source), term = graph.bodies.get("example")!;
    if (term.$ !== "Lit" || term.k !== "String") throw Error("Expected authentic compact String literal");
    const types = new LexicalTypes(graph.parserBook, graph.signatures);
    types.indexBody(term, [], graph.signatures.get("example")!.result);
    expect(term.v).toBe("λ𝄞");
    expect(term.s!.file.str).toBe(source);
    expect(termChildren(term)).toEqual([]);
    expect(freeBinderIds(term)).toEqual([]);
    expect(term_show(types.typeOf(term))).toBe("String");
  });

  test("locals containing compact Nat literals capture their actual native type", async () => {
    const {types, callbacks} = await fixture(`import Base
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example() -> Nat:
  number = 23n
  invoke(ignored => number)
`);
    expect(fields(types, callbacks[0]!)).toEqual([{name: "number", type: "Nat", quantity: "Lone"}]);
  });

  test("product-valued locals infer both fields structurally", async () => {
    const { types, callbacks } = await fixture(`
import Base
def invoke(k: Nat -> Nat) -> Nat:
  k(0n)
def example(seed: Nat, flag: Bool) -> Nat:
  (value, _) = (seed, flag)
  invoke(ignored => value)
`);
    expect(fields(types, callbacks[0]!)).toEqual([{ name: "value", type: "Nat", quantity: "Lone" }]);
    expect(renderCaptureParameters(planCaptures([callbacks[0]!], types), "resume", term_show)).toContain(": Nat");
  });

  test("constructor payload types normalize applied type-level matches", async () => {
    const { types, callbacks } = await fixture(`
import Base
def invoke(k: Bool -> Bool) -> Bool:
  k(True{})
def example(code: U32) -> Bool:
  match code:
    case U32{WCon{bit, _}}:
      invoke(ignored => bit)
`);
    const plan = planCaptures([callbacks[0]!], types);
    expect(fields(types, callbacks[0]!)).toEqual([{ name: "bit", type: "Bool", quantity: "Lone" }]);
    expect(renderCaptureFields(plan, term_show)).toContain(": Bool");
    expect(renderCaptureParameters(plan, "resume", term_show)).toContain(": Bool");
  });
});

test("indexed scrutinees retain instantiated payload types across shadowing", async () => {
  const { graph, types } = await fixture(`
import Base
type Envelope is Data:
  Envelope{items: List<&2, U32>}
def example(items: Bool, envelope: Envelope) -> U32:
  match envelope:
    case Envelope{items}:
      match items:
        case head <> _: head
        case Nil{}: 0
`);
  const body = graph.bodies.get("example")!;
  if (body.$ !== "Match" || body.r[0]!.f.$ !== "Match") throw Error("Expected nested matches");
  const scrutinee = body.r[0]!.f.e[0]!;
  const type = types.typeOf(scrutinee);
  expect(type.$).toBe("ADT");
  expect(term_show(type)).toBe("List<&2, U32>");
});

test("a declared constructor payload supplies the goal for a polymorphic empty value", async () => {
  const { types, callbacks } = await fixture(`
import Base
type Carrier is Data:
  Carrier{payload: Maybe<&2, Nat>}
def invoke(k: Nat -> Carrier) -> Carrier:
  k(0n)
def example() -> Carrier:
  holder = Carrier{None{}}
  invoke(ignored => holder)
`);
  const plan = planCaptures([callbacks[0]!], types);
  expect(fields(types, callbacks[0]!)).toEqual([
    {name:"holder", type:"Carrier", quantity:"Lone"},
  ]);
  expect(renderCaptureFields(plan, term_show)).toContain(": Carrier");
});
