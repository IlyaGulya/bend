import { expect, test } from "bun:test";
import type { Body, LTerm, Patt } from "../bend2/bend.ts";
import { readParserGraph, type ParserParameter } from "./parser_full_graph.ts";
import { renderBody } from "./parser_full_body_render.ts";

// Compare bindings by declaration order rather than generated names or parser IDs.
function topology(body: Body, parameters: readonly ParserParameter[]): unknown {
  let fresh = 0;
  const initial = new Map(parameters.map(parameter => [parameter[2], fresh++]));
  function term(node: LTerm, scope: ReadonlyMap<number, number>): unknown {
    if (node.$ === "Var") {
      if (!scope.has(node.i)) throw Error(`Unbound variable ${node.i}`);
      return ["Var", scope.get(node.i)];
    }
    if (node.$ === "Lam" || node.$ === "All") {
      const inner = new Map(scope); inner.set(node.i, fresh++);
      return node.$ === "Lam" ? ["Lam", node.q?.$ ?? "Lone", term(node.f, inner)]
        : ["All", node.q.$, term(node.A, scope), term(node.B, inner)];
    }
    if (node.$ === "Let") {
      const values = node.v.map(value => term(value, scope));
      const inner = new Map(scope); for (const id of node.i) inner.set(id, fresh++);
      return ["Let", node.q.map(quantity => quantity.$), values, term(node.f, inner)];
    }
    return Object.fromEntries(Object.entries(node).filter(([key]) => key !== "s").map(([key, value]) =>
      [key, Array.isArray(value) ? value.map(child => child?.$ ? term(child, scope) : child)
        : value && typeof value === "object" && "$" in value ? term(value as LTerm, scope) : value]));
  }
  function pattern(node: Patt, scope: Map<number, number>): unknown {
    if (node.$ === "PCtr") return [node.k, node.x.map(child => pattern(child, scope))];
    const id = fresh++; scope.set(node.i, id); return ["PVar", node.k === "_", node.q.$, id];
  }
  function visit(node: Body, scope: ReadonlyMap<number, number>): unknown {
    if (node.$ !== "Local" && node.$ !== "Match") return ["Terminal", term(node, scope)];
    if (node.$ === "Local") {
      const values = node.v.map(value => term(value, scope));
      const inner = new Map(scope);
      return ["Local", node.q.$, node.k.map(child => pattern(child, inner)), values, visit(node.f, inner)];
    }
    return ["Match", node.e.map(value => term(value, scope)), node.r.map(row => {
      const inner = new Map(scope); return [row.p.map(child => pattern(child, inner)), visit(row.f, inner)];
    })];
  }
  return visit(body, initial);
}

const declarations = `import Base
type Box is Data:
  Packed{pair: Nat & ((Bool & Nat) & Nat)}
  Vacant{}
def identity(value: Nat) -> Nat:
  value
def apply(k: Nat -> Nat, value: Nat) -> Nat:
  k(value)
`;

test("real Match/Local source roundtrips nested patterns, quantities and shadowed lambda references", async () => {
  const graph = await readParserGraph(declarations + `
def example(+value: Nat, box: Box) -> Nat:
  -erased = Nat
  match box:
    case Packed{(value, ((+flag, _), _))}:
      +saved = value
      value = identity(saved)
      apply(value => saved, value)
    case Vacant{}:
      value
`);
  const signature = graph.signatures.get("example")!;
  const body = graph.bodies.get("example")!;
  const rendered = renderBody(body, signature.parameters);
  const roundtrip = await readParserGraph(declarations + `\ndef example(${rendered.parameters}) -> Nat:\n${rendered.body}\n`);
  expect(topology(roundtrip.bodies.get("example")!, roundtrip.signatures.get("example")!.parameters))
    .toEqual(topology(body, signature.parameters));
  expect(roundtrip.signatures.get("example")!.parameters.map(parameter => parameter[0].$)).toEqual(["Many", "Lone"]);
});

test("a terminal Control constructor keeps the local binder and avoids book constructor names", async () => {
  const prefix = declarations + `
type Control is Data:
  Saved{value: Nat}
type Reserved is Data:
  v_0{}
  v_1{}
  v_4{}
`;
  const graph = await readParserGraph(prefix + `
def example(value: Nat) -> Nat:
  value = identity(value)
  value
`);
  const signature = graph.signatures.get("example")!;
  const rendered = renderBody(graph.bodies.get("example")!, signature.parameters, {
    book: graph.parserBook,
    emitTerminal: (term, context) => `Saved{${context.renderTerm(term)}}`,
  });
  const roundtrip = await readParserGraph(prefix + `\ndef example(${rendered.parameters}) -> Control:\n${rendered.body}\n`);
  const body = roundtrip.bodies.get("example")!;
  if (body.$ !== "Local" || body.k[0]!.$ !== "PVar" || body.f.$ !== "Ctr") {
    throw Error("Expected a local followed by a saved terminal");
  }
  const payload = body.f.x[0]!;
  expect(body.f.k).toBe("Saved");
  expect(payload.$).toBe("Var");
  if (payload.$ !== "Var") throw Error("Expected the saved local");
  expect(payload.i).toBe(body.k[0]!.i);
  expect(payload.i).not.toBe(roundtrip.signatures.get("example")!.parameters[0]![2]);
});

test("synthetic Control leaves resolve fresh result IDs in an extended reply scope", async () => {
  const prefix = declarations + `
type Control is Data:
  Saved{value: Nat}
`;
  const graph = await readParserGraph(prefix + `
def example(value: Nat) -> Nat:
  identity(value)
`);
  const signature = graph.signatures.get("example")!;
  const rendered = renderBody(graph.bodies.get("example")!, signature.parameters, {
    emitTerminal: (term, context) => {
      const result: LTerm = { $: "Ctr", k: "Saved", x: [{ $: "Var", k: "ignored_source_name", i: 10000 }] };
      return `terminal_value = ${context.renderTerm(term)}\n`
        + context.renderTerm(result, new Map([[10000, "terminal_value"]]));
    },
  });
  const roundtrip = await readParserGraph(prefix + `\ndef example(${rendered.parameters}) -> Control:\n${rendered.body}\n`);
  const body = roundtrip.bodies.get("example")!;
  if (body.$ !== "Local" || body.k[0]!.$ !== "PVar" || body.f.$ !== "Ctr") {
    throw Error("Expected a terminal result binding followed by Control");
  }
  const payload = body.f.x[0]!;
  if (payload.$ !== "Var") throw Error("Expected a bound result payload");
  expect(payload.i).toBe(body.k[0]!.i);
  expect(payload.i).not.toBe(roundtrip.signatures.get("example")!.parameters[0]![2]);
});
