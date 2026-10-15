import { beforeAll, describe, expect, test } from "bun:test";
import { randomUUID } from "node:crypto";
import { rmSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, book_valid, err_show } from "../bend2/bend.ts";
import type { Err, LTerm, Quant } from "../bend2/bend.ts";
import { js_lib } from "../bend2/comp.ts";
import { constructorValue, instrumentExplicitProgress, UnsupportedInstrumentation } from "./parser_full_explicit_progress.ts";
import type { ConstructorValue, ExplicitProgressProgram, Progress, RuntimeValue } from "./parser_full_explicit_progress.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import type { ParserGraph } from "./parser_full_graph.ts";
import { optimizeCursorRestitution } from "./parser_full_restitution.ts";

const preamble = `import Base
type Pebble is Data:
  Grain{code: Nat}
  Mark{ready: Bool, start: Nat, finish: Nat}
`;
const c = constructorValue;
const lone: Quant = { $: "Lone" };
const v = (i: number): LTerm => ({ $: "Var", k: `projection_${i}`, i });
const app = (f: LTerm, x: LTerm): LTerm => ({ $: "App", f, x });
type NativeWriter = { $: "Tuple"; fst: { $: "Tuple"; fst: number; snd: unknown }; snd: { $: Progress } };
type NativeProgram = Record<string, (...args: unknown[]) => NativeWriter>;

// These are actual generated typed Mat expressions, not source matches. In
// particular, the inner matcher is the argument of the outer projection and
// the resulting cursor is nested in the writer's semantic result constructor.
function second(input: LTerm, domain: LTerm, result: LTerm, firstId: number): LTerm {
  return app({
    $: "Ann",
    T: { $: "All", q: lone, k: "projection_input", i: firstId + 2, A: domain, B: result },
    x: {
      $: "Mat", k: "Tuple",
      h: { $: "Lam", q: lone, k: `projection_${firstId}`, i: firstId,
        f: { $: "Lam", q: lone, k: `projection_${firstId + 1}`, i: firstId + 1, f: v(firstId + 1) } },
      m: { $: "Efq" },
    },
  }, input);
}

function nestedProjection(graph: ParserGraph, owner: string): LTerm {
  const signature = graph.signatures.get(owner)!;
  const parameter = signature.parameters[0]!;
  const inner = graph.signatures.get("projection")!.result;
  const cursor = graph.signatures.get("peel")!.parameters[0]![3];
  return second(second(v(parameter[2]), parameter[3], inner, 1000), inner, cursor, 1010);
}

async function compile(program: ExplicitProgressProgram, source: string, roots: string[]): Promise<NativeProgram> {
  const complete = preamble + source + "\n" + program.declarations;
  const graph = await readParserGraph(complete);
  const headers = [...complete.matchAll(/^(type|def|law) (\S+)/gm)];
  const chunks = new Map(headers.filter(header => header[1] === "def").map(header => [
    header[2]!.split("(")[0]!, complete.slice(header.index, headers[headers.indexOf(header) + 1]?.index ?? complete.length),
  ]));
  for (const name of program.functions.keys()) chunks.delete(name);
  const ordered: string[] = [], visited = new Set<string>(), visiting = new Set<string>();
  function order(name: string): void {
    if (visited.has(name)) return;
    if (visiting.has(name)) throw Error("Mutual native matcher fixture recursion: " + name);
    visiting.add(name);
    for (const dependency of graph.edges[name] ?? []) if (dependency !== name && chunks.has(dependency)) order(dependency);
    visiting.delete(name); visited.add(name); ordered.push(chunks.get(name)!);
  }
  const entries = roots.map(name => "ep_" + name);
  entries.forEach(order);
  const types = headers.filter(header => header[1] !== "def").map(header =>
    complete.slice(header.index, headers[headers.indexOf(header) + 1]?.index ?? complete.length));
  const path = resolve(import.meta.dir, "../bend2/selfhost", `matcher_lift_test_${randomUUID()}.bend`);
  try {
    writeFileSync(path, ["import Base", ...types, ...ordered].join("\n\n"));
    const book = book_nil();
    try {
      await book_load(book, path, "", new Map());
      book_valid(book);
    } catch (error) {
      if (error && typeof error === "object" && "$" in error && error.$ === "Err") throw Error(err_show(error as Err));
      throw error;
    }
    const javascript = js_lib(book,true,{roots:entries,exports:entries});
    // The generated compiler output is only available at runtime, not as a static module.
    return (await import("data:text/javascript;base64," + Buffer.from(javascript).toString("base64"))).default as NativeProgram;
  } finally {
    rmSync(path, { force: true });
  }
}

const source = `
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      rest
    case Nil{}:
      cursor

def projection(envelope: Nat & (Nat & List<&2, Pebble>)) -> Nat & List<&2, Pebble>:
  (701n, Nil{})

def aggregate(result: Sigma<&1, &1, List<&1, Nat>, _ => Nat & List<&2, Pebble>>) -> Nat & List<&2, Pebble>:
  match result:
    case (scratch, (payload, head <> rest)):
      (payload, head <> rest)
    case (scratch, (payload, Nil{})):
      (payload, Nil{})

def literal(+cursor: List<&2, Pebble>) -> Nat & List<&2, Pebble>:
  match cursor:
    case Mark{True{}, start, finish} <> rest:
      (start, Mark{True{}, start, finish} <> rest)
    case Mark{False{}, start, finish} <> rest:
      (finish, rest)
    case head <> rest:
      (709n, head <> rest)
    case Nil{}:
      (719n, cursor)
`;
const roots = ["projection", "aggregate", "literal"];

describe("native closure lifting of generated expression matchers", () => {
  let program: ExplicitProgressProgram;
  let native: NativeProgram;
  beforeAll(async () => {
    const graph = await readParserGraph(preamble + source);
    const normalized = optimizeCursorRestitution(graph, "Pebble");
    const original = graph.bodies.get("projection")!;
    if (original.$ !== "Ctr" || original.k !== "Tuple") throw Error("Expected a tuple projection fixture");
    normalized.bodies.set("projection", { ...original,
      x: [original.x[0]!, nestedProjection(graph, "projection")],
    });
    program = instrumentExplicitProgress({ ...graph, bodies: normalized.bodies, signatures: normalized.signatures }, {
      tokenElement: "Pebble", definitions: graph.definitions, driverEntryPoints: roots,
    });
    native = await compile(program, source, roots);
  });

  function check(name: string, input: RuntimeValue, nativeInput: unknown, payload: number, cursor: RuntimeValue, nativeCursor: unknown, progress: Progress): void {
    const semantic = program.execute(name, [input]);
    expect(semantic).toEqual({ value: c("Tuple", payload, cursor), progress });
    expect((semantic.value as ConstructorValue).fields[1]).toBe(cursor);
    const compiled = native["ep_" + name]!(nativeInput);
    expect(compiled).toEqual({ $: "Tuple", fst: { $: "Tuple", fst: payload, snd: nativeCursor }, snd: { $: progress } });
    expect(compiled.fst.snd).toBe(nativeCursor);
  }

  test("nested typed field projections inside a writer preserve the exact embedded cursor", () => {
    const cursor = c("Con", c("Grain", 727), c("Nil"));
    const nativeCursor = { $: "Con", head: { $: "Grain", code: 727 }, tail: { $: "Nil" } };
    check("projection", c("Tuple", 733, c("Tuple", 739, cursor)),
      { $: "Tuple", fst: 733, snd: { $: "Tuple", fst: 739, snd: nativeCursor } }, 701, cursor, nativeCursor, "NoProgress");
    const vacant = c("Nil"), nativeVacant = { $: "Nil" };
    check("projection", c("Tuple", 733, c("Tuple", 739, vacant)),
      { $: "Tuple", fst: 733, snd: { $: "Tuple", fst: 739, snd: nativeVacant } }, 701, vacant, nativeVacant, "NoProgress");
  });

  test("an affine aggregate can restitute its shareable cursor field without sharing the aggregate", () => {
    const cursor = c("Con", c("Grain", 743), c("Nil"));
    const nativeCursor = { $: "Con", head: { $: "Grain", code: 743 }, tail: { $: "Nil" } };
    const scratch = c("Con", 751, c("Nil"));
    const nativeScratch = { $: "Con", head: 751, tail: { $: "Nil" } };
    check("aggregate", c("Tuple", scratch, c("Tuple", 757, cursor)),
      { $: "Tuple", fst: nativeScratch, snd: { $: "Tuple", fst: 757, snd: nativeCursor } }, 757, cursor, nativeCursor, "NoProgress");
    const vacant = c("Nil"), nativeVacant = { $: "Nil" };
    check("aggregate", c("Tuple", c("Nil"), c("Tuple", 761, vacant)),
      { $: "Tuple", fst: { $: "Nil" }, snd: { $: "Tuple", fst: 761, snd: nativeVacant } }, 761, vacant, nativeVacant, "NoProgress");
  });

  test("literal nested branches and constructor/default fallback retain payloads and cursor aliases", () => {
    const tail = c("Con", c("Grain", 769), c("Nil"));
    const nativeTail = { $: "Con", head: { $: "Grain", code: 769 }, tail: { $: "Nil" } };
    const marked = c("Con", c("Mark", c("True"), 773, 787), tail);
    const nativeMarked = { $: "Con", head: { $: "Mark", ready: true, start: 773, finish: 787 }, tail: nativeTail };
    check("literal", marked, nativeMarked, 773, marked, nativeMarked, "NoProgress");
    const fallback = c("Con", c("Grain", 797n), tail);
    const nativeFallback = { $: "Con", head: { $: "Grain", code: 797n }, tail: nativeTail };
    check("literal", fallback, nativeFallback, 709n, fallback, nativeFallback, "NoProgress");
    const vacant = c("Nil"), nativeVacant = { $: "Nil" };
    check("literal", vacant, nativeVacant, 719n, vacant, nativeVacant, "NoProgress");
  });

  test("consumption in a lifted nested handler survives hoisting and composes into the writer", () => {
    const tail = c("Con", c("Grain", 809n), c("Nil"));
    const nativeTail = { $: "Con", head: { $: "Grain", code: 809n }, tail: { $: "Nil" } };
    check("literal", c("Con", c("Mark", c("False"), 811n, 821n), tail),
      { $: "Con", head: { $: "Mark", ready: false, start: 811n, finish: 821n }, tail: nativeTail }, 821n, tail, nativeTail, "Consumed");
    const vacant = c("Nil"), nativeVacant = { $: "Nil" };
    check("literal", c("Con", c("Mark", c("False"), 823n, 827n), vacant),
      { $: "Con", head: { $: "Mark", ready: false, start: 823n, finish: 827n }, tail: nativeVacant }, 827n, vacant, nativeVacant, "Consumed");
  });
});

test("typed field projection cannot replay an owned cursor after an active call", async () => {
  const graph = await readParserGraph(preamble + source + `
def replay(+envelope: Nat & (Nat & List<&2, Pebble>)) -> List<&2, Pebble>:
  peel(Nil{})
`);
  graph.bodies.set("replay", {
    $: "Let", q: [lone], k: ["advanced"], i: [1100],
    v: [app({ $: "Ref", k: "peel" }, nestedProjection(graph, "replay"))],
    f: nestedProjection(graph, "replay"),
  });
  expect(() => instrumentExplicitProgress(graph, {
    tokenElement: "Pebble", definitions: ["peel", "replay"], driverEntryPoints: ["replay"],
  })).toThrow(UnsupportedInstrumentation);
});
