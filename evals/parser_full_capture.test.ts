import { expect, test } from "bun:test";
import { term_show, type LTerm } from "../bend2/bend.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { LexicalTypes } from "./parser_full_type_env.ts";
import { planCaptures, renderCaptureFields, renderCaptureParameters,
  renderCapturePattern, renderCaptureArguments, renderCaptureCallbacks } from "./parser_full_capture.ts";

async function callbacks(source: string, owner: string, consumer: string) {
  const graph = await readParserGraph("import Base\n\n" + source);
  const lexical = new LexicalTypes(graph.parserBook, graph.signatures);
  lexical.indexBody(graph.bodies.get(owner)!, graph.signatures.get(owner)!.parameters);
  const args = graph.calls.get(owner)!.filter(call => call.callee === consumer)
    .flatMap(call => call.args.filter(arg => arg.$ === "Lam"));
  return { lexical, args };
}

function variables(term: LTerm): Extract<LTerm, { $: "Var" }>[] {
  if (term.$ === "Var") return [term];
  return Object.entries(term).filter(([key]) => key !== "s").flatMap(([, value]) => {
    if (Array.isArray(value)) return value.flatMap(child => child && typeof child === "object" && "$" in child ? variables(child) : []);
    return value && typeof value === "object" && "$" in value ? variables(value as LTerm) : [];
  });
}

test("a match-local affine capture is transferred once into a typed Kont and resume binder", async () => {
  const { lexical, args } = await callbacks(`
def apply(callback: @x:Nat -> Nat) -> Nat:
  callback(0n)
def owner(pair: Nat & Bool) -> Nat:
  match pair:
    case (value, ok):
      apply(x => value)
`, "owner", "apply");
  const plan = planCaptures(args, lexical);
  expect(plan.fields.map(field => [field.sourceName, term_show(field.type), field.quantity.$, field.resumeQuantity.$]))
    .toEqual([["value", "Nat", "Lone", "Lone"]]);
  const name = plan.fields[0]!.name;
  expect(renderCaptureFields(plan, term_show)).toBe(name + ": Nat");
  expect(renderCaptureParameters(plan, "transfer", term_show)).toBe(name + ": Nat");
  expect(renderCaptureParameters(plan, "resume", term_show)).toBe(name + ": Nat");
  expect(renderCapturePattern(plan)).toBe(name);
  expect(renderCaptureArguments(plan, "source")).toBe("value");
  expect(renderCaptureArguments(plan, "local")).toBe(name);
  expect(renderCaptureCallbacks(plan)).toEqual(["x => " + name]);
});

test("binder identity preserves nested shadowing without mutating the source callback", async () => {
  const { lexical, args } = await callbacks(`
def apply(callback: @x:Nat -> Nat & (@y:Nat -> Nat)) -> Nat:
  0n
def owner(value: Nat) -> Nat:
  apply(x => (value, value => value))
`, "owner", "apply");
  const plan = planCaptures(args, lexical, { prefix: "value" });
  const field = plan.fields[0]!;
  expect(plan.fields.map(item => item.sourceName)).toEqual(["value"]);
  const original = variables(args[0]!);
  const renamed = variables(plan.callbacks[0]!);
  expect(renamed.filter(variable => variable.i === field.id).map(variable => variable.k)).toEqual([field.name]);
  expect(renamed.filter(variable => variable.i !== field.id).map(variable => variable.k)).toEqual(["value"]);
  expect(original.map(variable => variable.k)).toEqual(["value", "value"]);
  expect(renderCaptureCallbacks(plan)).toEqual(["x => (" + field.name + ", value => value)"]);
});

test("duplicate callbacks share one transfer but only their local resume copy is unrestricted", async () => {
  const { lexical, args } = await callbacks(`
def apply(left: @x:Nat -> Nat, right: @x:Nat -> Nat) -> Nat:
  0n
def owner(value: Nat) -> Nat:
  apply(x => value, y => value)
`, "owner", "apply");
  const plan = planCaptures(args, lexical);
  expect(plan.fields.map(field => [field.sourceName, field.uses, field.quantity.$, field.resumeQuantity.$]))
    .toEqual([["value", 2, "Lone", "Many"]]);
  const name = plan.fields[0]!.name;
  expect(renderCaptureParameters(plan, "transfer", term_show)).toBe(name + ": Nat");
  expect(renderCapturePattern(plan)).toBe(name);
  expect(renderCaptureParameters(plan, "resume", term_show)).toBe("+" + name + ": Nat");
  expect(renderCaptureCallbacks(plan)).toEqual(["x => " + name, "y => " + name]);
  expect(lexical.captures(args[0]!)[0]!.quantity.$).toBe("Lone");
});

test("a dependent capture type reports its binder dependencies instead of emitting an unbound Kont field", async () => {
  const { lexical, args } = await callbacks(`
def apply(callback: @x:Nat -> Nat) -> Nat:
  0n
def owner(A: Type, value: A) -> Nat:
  apply(x => value)
`, "owner", "apply");
  const binding = lexical.captures(args[0]!)[0]!;
  const dependency = [...lexical.environmentAt(args[0]!).values()].find(item => item.name === "A")!;
  let failure: unknown;
  try { planCaptures(args, lexical); } catch (error) { failure = error; }
  expect(failure).toMatchObject({
    code: "dependent-capture-type",
    capturedBinderId: binding.id,
    dependencyBinderIds: [dependency.id],
  });
});
