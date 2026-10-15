import { beforeAll, describe, expect, test } from "bun:test";
import { randomUUID } from "node:crypto";
import { writeFileSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, book_valid, err_show, type Err } from "../bend2/bend.ts";
import { js_lib } from "../bend2/comp.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { constructorValue, instrumentExplicitProgress, UnsupportedInstrumentation } from "./parser_full_explicit_progress.ts";
import type { ExplicitProgressProgram, RuntimeValue } from "./parser_full_explicit_progress.ts";
import { renderExplicitControlRuntime } from "./parser_full_control_runtime.ts";

const preamble = `import Base
type Pebble is Data:
  Grain{code: Nat}
`;
const c = constructorValue;
const empty = () => c("Nil");
const grain = (code: number) => c("Grain", code);
const cons = (head: RuntimeValue, tail: RuntimeValue) => c("Con", head, tail);
async function fixture(source: string) {
  return instrumentExplicitProgress(await readParserGraph(preamble + source), { tokenElement: "Pebble" });
}

test("a direct token-tail result consumes only the matched nonempty branch", async () => {
  const program = await fixture(`
def peel(cursor: List<&2, Pebble>) -> Maybe<&2, List<&2, Pebble>>:
  match cursor:
    case head <> rest:
      Some{rest}
    case Nil{}:
      None{}
`);
  const remainder = cons(grain(29), empty());
  const input = cons(grain(11), remainder);
  const success = program.execute("peel", [input]);
  expect(success).toEqual({ value: c("Some", remainder), progress: "Consumed" });
  if (success.value === null || typeof success.value !== "object" || !("fields" in success.value)) throw Error("Expected Some");
  expect(success.value.fields[0]).toBe(remainder);
  expect(program.execute("peel", [empty()])).toEqual({ value: c("None"), progress: "NoProgress" });
});

test("inspecting a token head or passing its unused tail to a read-only observer is NoProgress", async () => {
  const program = await fixture(`
def untouched(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      cursor
    case Nil{}:
      cursor
def inspect_head(cursor: List<&2, Pebble>) -> Nat:
  match cursor:
    case Grain{code} <> rest:
      code
    case Nil{}:
      0n
def observe(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      True{}
    case Nil{}:
      False{}
def inspect_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      observe(rest)
    case Nil{}:
      False{}
`);
  const input = cons(grain(11), cons(grain(29), empty()));
  const untouched = program.execute("untouched", [input]);
  expect(untouched.value).toBe(input);
  expect(untouched.progress).toBe("NoProgress");
  expect(program.execute("inspect_head", [input])).toEqual({ value: 11, progress: "NoProgress" });
  expect(program.execute("inspect_tail", [input])).toEqual({ value: c("True"), progress: "NoProgress" });
  expect(program.execute("inspect_tail", [cons(grain(11), empty())]))
    .toEqual({ value: c("False"), progress: "NoProgress" });
});

test("an unexecuted consuming branch cannot credit an unchanged runtime result", async () => {
  const program = await fixture(`
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      rest
    case Nil{}:
      cursor
def choose(cursor: List<&2, Pebble>, flag: Bool) -> List<&2, Pebble>:
  match flag:
    case True{}:
      peel(cursor)
    case False{}:
      cursor
`);
  const remainder = cons(grain(29), empty());
  const input = cons(grain(11), remainder);
  const unchanged = program.execute("choose", [input, c("False")]);
  expect(unchanged.value).toBe(input);
  expect(unchanged.progress).toBe("NoProgress");
  const changed = program.execute("choose", [input, c("True")]);
  expect(changed.value).toBe(remainder);
  expect(changed.progress).toBe("Consumed");
});

test("nested ordinary calls and tuple/result wrapping preserve child progress and semantic payloads", async () => {
  const program = await fixture(`
type Syntax is Data:
  Node{code: Nat, span: Sigma<&2, &2, Nat, _ => Nat>}
type Parcel is Data:
  Packed{payload: Sigma<&2, &2, Syntax, _ => List<&2, Pebble>>}
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      rest
    case Nil{}:
      cursor
def relay(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  peel(cursor)
def wrap(cursor: List<&2, Pebble>, node: Syntax) -> Parcel:
  advanced = relay(cursor)
  Packed{(node, advanced)}
def outer(cursor: List<&2, Pebble>, node: Syntax) -> Maybe<&2, Parcel>:
  Some{wrap(cursor, node)}
`);
  const remainder = cons(grain(29), empty());
  const input = cons(grain(11), remainder);
  const node = c("Node", 73, c("Tuple", 101, 109));
  expect(program.execute("outer", [input, node])).toEqual({
    value: c("Some", c("Packed", c("Tuple", node, remainder))), progress: "Consumed",
  });
  const vacant = empty();
  expect(program.execute("outer", [vacant, node])).toEqual({
    value: c("Some", c("Packed", c("Tuple", node, vacant))), progress: "NoProgress",
  });
});

test("a child failure returning its input unchanged retains the parent's prior consumption", async () => {
  const program = await fixture(`
type Rejection is Data:
  Rejected{cursor: List<&2, Pebble>, diagnostic: Nat, span: Sigma<&2, &2, Nat, _ => Nat>}
def reject(cursor: List<&2, Pebble>, diagnostic: Nat, span: Sigma<&2, &2, Nat, _ => Nat>) -> Rejection:
  Rejected{cursor, diagnostic, span}
def advance_reject(cursor: List<&2, Pebble>, diagnostic: Nat, span: Sigma<&2, &2, Nat, _ => Nat>) -> Rejection:
  match cursor:
    case head <> rest:
      reject(rest, diagnostic, span)
    case Nil{}:
      reject(cursor, diagnostic, span)
`);
  const remainder = cons(grain(29), empty());
  const span = c("Tuple", 101, 109);
  expect(program.execute("reject", [remainder, 409, span])).toEqual({
    value: c("Rejected", remainder, 409, span), progress: "NoProgress",
  });
  expect(program.execute("advance_reject", [cons(grain(11), remainder), 409, span])).toEqual({
    value: c("Rejected", remainder, 409, span), progress: "Consumed",
  });
  const vacant = empty();
  expect(program.execute("advance_reject", [vacant, 409, span])).toEqual({
    value: c("Rejected", vacant, 409, span), progress: "NoProgress",
  });
});

test("child consumption survives an unrelated opaque remainder instead of being inferred from the final cursor", async () => {
  const program = await fixture(`
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      rest
    case Nil{}:
      cursor
def replace(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>) -> List<&2, Pebble>:
  unrelated
def opaque(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>) -> List<&2, Pebble>:
  child = peel(cursor)
  replace(child, unrelated)
def relay(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>) -> Maybe<&2, List<&2, Pebble>>:
  Some{opaque(cursor, unrelated)}
`);
  const unrelated = cons(grain(503), cons(grain(509), cons(grain(521), empty())));
  const input = cons(grain(11), empty());
  const consumed = program.execute("opaque", [input, unrelated]);
  expect(consumed.value).toBe(unrelated);
  expect(consumed.progress).toBe("Consumed");
  expect(program.execute("relay", [input, unrelated])).toEqual({
    value: c("Some", unrelated), progress: "Consumed",
  });
  expect(program.execute("relay", [empty(), unrelated])).toEqual({
    value: c("Some", unrelated), progress: "NoProgress",
  });
});

test("a consuming helper cannot rewind to its preserved input and replay the same head credit", async () => {
  await expect(fixture(`
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest: rest
    case Nil{}: cursor
def replay(+cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  discarded = peel(cursor)
  cursor
`)).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

test("a helper-returned cursor keeps ownership when another helper peels it", async () => {
  await expect(fixture(`
def identity(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  cursor
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest: rest
    case Nil{}: cursor
def replay(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  +alias = identity(cursor)
  discarded = peel(alias)
  alias
`)).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

test("token-producing imports cannot manufacture a new driver cursor", async () => {
  const graph = await readParserGraph(preamble + `
def manufacture(head: Pebble) -> List<&2, Pebble>:
  head <> Nil{}
def step(head: Pebble) -> List<&2, Pebble>:
  manufacture(head)
`);
  await expect(Promise.resolve().then(() => instrumentExplicitProgress(graph, {
    tokenElement: "Pebble", definitions: ["step"],
  }))).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

test("zero-argument writer helpers preserve semantic results instead of nesting their effect packet", async () => {
  const program = await fixture(`
def constant() -> Bool:
  True{}
def wrapped() -> Maybe<&2, Bool>:
  Some{constant()}
`);
  expect(program.execute("wrapped", [])).toEqual({ value: c("Some", c("True")), progress: "NoProgress" });
});

test("zero-argument imported cursor producers are rejected inside the driver", async () => {
  const graph = await readParserGraph(preamble + `
def manufacture() -> List<&2, Pebble>:
  Grain{11n} <> Nil{}
def step() -> List<&2, Pebble>:
  manufacture()
`);
  expect(() => instrumentExplicitProgress(graph, { tokenElement: "Pebble", definitions: ["step"] }))
    .toThrow(UnsupportedInstrumentation);
});

test("an initializer shared with a driver is not an initial-only cursor production boundary", async () => {
  const graph = await readParserGraph(preamble + `
def manufacture(head: Pebble) -> List<&2, Pebble>:
  head <> Nil{}
def setup(head: Pebble) -> List<&2, Pebble>:
  manufacture(head)
def driver(head: Pebble) -> List<&2, Pebble>:
  setup(head)
`);
  expect(() => instrumentExplicitProgress(graph, {
    tokenElement: "Pebble", definitions: ["setup", "driver"], driverEntryPoints: ["driver"],
  })).toThrow(UnsupportedInstrumentation);
});

test("fresh token construction is allowed only before the driver input boundary", async () => {
  const graph = await readParserGraph(preamble + `
def initialize(head: Pebble, cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  head <> cursor
def driver(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest: rest
    case Nil{}: Nil{}
`);
  const program = instrumentExplicitProgress(graph, {
    tokenElement: "Pebble", definitions: ["initialize", "driver"], driverEntryPoints: ["driver"],
  });
  const head = grain(11), tail = cons(grain(29), empty());
  const initialized = program.execute("initialize", [head, tail]);
  expect(initialized).toEqual({ value: cons(head, tail), progress: "NoProgress" });
  expect(program.execute("driver", [initialized.value])).toEqual({ value: tail, progress: "Consumed" });
  expect(() => instrumentExplicitProgress(graph, {
    tokenElement: "Pebble", definitions: ["initialize", "driver"], driverEntryPoints: ["initialize"],
  })).toThrow(UnsupportedInstrumentation);
});

describe("token-cursor callbacks with non-cursor semantic results", () => {
  let program: ExplicitProgressProgram;
  let compiled: Record<string, (...args: unknown[]) => unknown>;
  const vacant = { $: "Nil" };
  const singleton = { $: "Con", head: { $: "Grain", code: 11 }, tail: vacant };
  const input = { $: "Con", head: { $: "Grain", code: 11 }, tail: {
    $: "Con", head: { $: "Grain", code: 29 }, tail: vacant,
  } };
  const semanticInput = () => cons(grain(11), cons(grain(29), empty()));
  const roots = [
    "ignored", "head_only", "active", "ignored_tail", "head_tail", "active_tail",
    "nested_ignored_tail", "nested_active_tail", "named_ignored_tail", "named_active_tail",
    "deferred_ignored_tail", "deferred_head_tail", "deferred_active_tail",
    "curried_ignored_tail", "curried_active_tail", "partial_ignored_tail", "partial_active_tail",
    "azalea", "birch", "cedar", "dogwood",
  ];

  beforeAll(async () => {
    const source = preamble + `
def ignore(cursor: List<&2, Pebble>) -> Bool:
  True{}
def head_code(cursor: List<&2, Pebble>) -> Nat:
  match cursor:
    case Grain{code} <> rest:
      code
    case Nil{}:
      0n
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      rest
    case Nil{}:
      cursor
def consume(cursor: List<&2, Pebble>) -> Bool:
  advanced = peel(cursor)
  False{}
def invoke(cursor: List<&2, Pebble>, callback: List<&2, Pebble> -> Bool) -> Bool:
  callback(cursor)
def invoke_code(cursor: List<&2, Pebble>, callback: List<&2, Pebble> -> Nat) -> Nat:
  callback(cursor)
def relay(cursor: List<&2, Pebble>, callback: List<&2, Pebble> -> Bool) -> Bool:
  invoke(cursor, callback)
def relay_outer(cursor: List<&2, Pebble>, callback: List<&2, Pebble> -> Bool) -> Bool:
  relay(cursor, callback)
def ignored(cursor: List<&2, Pebble>) -> Bool:
  invoke(cursor, cursor => True{})
def head_only(cursor: List<&2, Pebble>) -> Nat:
  invoke_code(cursor, cursor => head_code(cursor))
def active(cursor: List<&2, Pebble>) -> Bool:
  invoke(cursor, cursor => consume(cursor))
def ignored_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke(rest, cursor => True{})
    case Nil{}:
      False{}
def head_tail(cursor: List<&2, Pebble>) -> Nat:
  match cursor:
    case head <> rest:
      invoke_code(rest, cursor => head_code(cursor))
    case Nil{}:
      0n
def active_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke(rest, cursor => consume(cursor))
    case Nil{}:
      True{}
def nested_ignored_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      relay_outer(rest, cursor => True{})
    case Nil{}:
      False{}
def nested_active_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      relay_outer(rest, cursor => consume(cursor))
    case Nil{}:
      True{}
def named_ignored_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke(rest, ignore)
    case Nil{}:
      False{}
def named_active_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke(rest, consume)
    case Nil{}:
      True{}
def resume_ignored(cursor: List<&2, Pebble>) -> Bool:
  invoke(cursor, cursor => True{})
def resume_head(cursor: List<&2, Pebble>) -> Nat:
  invoke_code(cursor, cursor => head_code(cursor))
def resume_active(cursor: List<&2, Pebble>) -> Bool:
  invoke(cursor, cursor => consume(cursor))
def deferred_ignored_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      resume_ignored(rest)
    case Nil{}:
      False{}
def deferred_head_tail(cursor: List<&2, Pebble>) -> Nat:
  match cursor:
    case head <> rest:
      resume_head(rest)
    case Nil{}:
      0n
def deferred_active_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      resume_active(rest)
    case Nil{}:
      True{}
def invoke_curried(cursor: List<&2, Pebble>, flag: Bool, callback: List<&2, Pebble> -> Bool -> Bool) -> Bool:
  callback(cursor, flag)
def invoke_partial(cursor: List<&2, Pebble>, flag: Bool, callback: List<&2, Pebble> -> Bool -> Bool) -> Bool:
  pending = callback(cursor)
  pending(flag)
def keep_flag(cursor: List<&2, Pebble>, flag: Bool) -> Bool:
  flag
def consume_flag(cursor: List<&2, Pebble>, flag: Bool) -> Bool:
  advanced = peel(cursor)
  flag
def curried_ignored_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke_curried(rest, False{}, cursor => flag => flag)
    case Nil{}:
      True{}
def curried_active_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke_curried(rest, True{}, cursor => flag => consume_flag(cursor, flag))
    case Nil{}:
      False{}
def partial_ignored_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke_partial(rest, False{}, keep_flag)
    case Nil{}:
      True{}
def partial_active_tail(cursor: List<&2, Pebble>) -> Bool:
  match cursor:
    case head <> rest:
      invoke_partial(rest, True{}, consume_flag)
    case Nil{}:
      False{}
def finch(ash: List<&2, Pebble>) -> List<&2, Pebble>:
  match ash:
    case seed <> twig: twig
    case Nil{}: ash
def vireo(alder: List<&2, Pebble>, willow: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match choice:
    case True{}: alder
    case False{}: willow
def oriole(alder: List<&2, Pebble>, willow: List<&2, Pebble>, choice: Bool) -> Bool:
  match choice:
    case True{}: True{}
    case False{}:
      moved = finch(willow)
      False{}
def marten(alder: List<&2, Pebble>, willow: List<&2, Pebble>, choice: Bool) -> Nat:
  match choice:
    case True{}: head_code(alder)
    case False{}: head_code(willow)
def azalea(+spruce: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match spruce:
    case seed <> twig: vireo(spruce, twig, choice)
    case Nil{}: vireo(spruce, spruce, choice)
def birch(+spruce: List<&2, Pebble>, choice: Bool) -> Bool:
  match spruce:
    case seed <> twig: oriole(spruce, twig, choice)
    case Nil{}: oriole(spruce, spruce, choice)
def cedar(+spruce: List<&2, Pebble>, choice: Bool) -> Nat:
  match spruce:
    case seed <> twig: marten(spruce, twig, choice)
    case Nil{}: marten(spruce, spruce, choice)
def dogwood(spruce: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match spruce:
    case seed <> +twig: vireo(twig, twig, choice)
    case Nil{}: spruce
`;
    program = instrumentExplicitProgress(await readParserGraph(source), {
      tokenElement: "Pebble",
      parameterWitnesses: new Map(["resume_ignored", "resume_head", "resume_active"].map(name => [
        name, [{ parameterIndex: 0, witnessName: "witness" }],
      ])),
    });
    const path = resolve(import.meta.dir, "../bend2/selfhost", `callback_progress_test_${randomUUID()}.bend`);
    try {
      const complete = source + "\n" + program.declarations;
      const graph = await readParserGraph(complete);
      const headers = [...complete.matchAll(/^(type|def|law) (\S+)/gm)];
      const chunks = new Map(headers.filter(header => header[1] === "def").map(header => [
        header[2]!.split("(")[0]!, complete.slice(header.index, headers[headers.indexOf(header) + 1]?.index ?? complete.length),
      ]));
      for (const name of program.functions.keys()) chunks.delete(name);
      const ordered: string[] = [], visited = new Set<string>(), visiting = new Set<string>();
      function order(name: string): void {
        if (visited.has(name)) return;
        if (visiting.has(name)) throw new Error("Mutual native callback fixture recursion: " + name);
        visiting.add(name);
        for (const dependency of graph.edges[name] ?? []) if (dependency !== name && chunks.has(dependency)) order(dependency);
        visiting.delete(name); visited.add(name); ordered.push(chunks.get(name)!);
      }
      for (const name of chunks.keys()) order(name);
      const types = headers.filter(header => header[1] !== "def").map(header =>
        complete.slice(header.index, headers[headers.indexOf(header) + 1]?.index ?? complete.length));
      writeFileSync(path, ["import Base", ...types, ...ordered].join("\n\n"));
      const book = book_nil();
      try {
        await book_load(book, path, "", new Map());
        book_valid(book);
      } catch (error) {
        if (error && typeof error === "object" && "$" in error && error.$ === "Err") throw new Error(err_show(error as Err));
        throw error;
      }
      const entries = roots.map(name => "ep_" + name);
      const javascript = js_lib(book,true,{roots:entries,exports:entries});
      // This module is freshly generated compiler output, not a static dependency.
      compiled = (await import("data:text/javascript;base64," + Buffer.from(javascript).toString("base64"))).default;
    } finally {
      rmSync(path, { force: true });
    }
  });

  function check(name: string, semantic: RuntimeValue, native: unknown, value: RuntimeValue, nativeValue: unknown, progress: "NoProgress" | "Consumed"): void {
    expect(program.execute(name, [semantic])).toEqual({ value, progress });
    expect(compiled["ep_" + name]!(native)).toEqual({
      $: "Tuple", fst: nativeValue, snd: { $: progress },
    });
  }

  function checkChoice(name: string, flag: boolean, semantic: RuntimeValue, native: unknown, value: RuntimeValue, nativeValue: unknown, progress: "NoProgress" | "Consumed"): void {
    expect(program.execute(name, [semantic, c(flag ? "True" : "False")])).toEqual({ value, progress });
    expect(compiled["ep_" + name]!(native, flag)).toEqual({
      $: "Tuple", fst: nativeValue, snd: { $: progress },
    });
  }

  test("an ignored cursor or head-only callback preserves exact Bool/Nat payloads without consumption", () => {
    check("ignored", semanticInput(), input, c("True"), true, "NoProgress");
    check("ignored", empty(), vacant, c("True"), true, "NoProgress");
    check("head_only", semanticInput(), input, 11, 11, "NoProgress");
    check("head_only", empty(), vacant, 0, 0, "NoProgress");
    check("active", semanticInput(), input, c("False"), false, "Consumed");
    check("active", empty(), vacant, c("False"), false, "NoProgress");
  });

  test("passing a matched tail into an opaque callback is not consumption until that callback actively uses it", () => {
    check("ignored_tail", semanticInput(), input, c("True"), true, "NoProgress");
    check("ignored_tail", cons(grain(11), empty()), singleton, c("True"), true, "NoProgress");
    check("ignored_tail", empty(), vacant, c("False"), false, "NoProgress");
    check("head_tail", semanticInput(), input, 29, 29, "NoProgress");
    check("head_tail", cons(grain(11), empty()), singleton, 0, 0, "NoProgress");
    check("active_tail", semanticInput(), input, c("False"), false, "Consumed");
    check("active_tail", cons(grain(11), empty()), singleton, c("False"), false, "Consumed");
    check("active_tail", empty(), vacant, c("True"), true, "NoProgress");
  });

  test("nested ordinary forwarding preserves ignored versus activated callback input ownership", () => {
    check("nested_ignored_tail", semanticInput(), input, c("True"), true, "NoProgress");
    check("nested_ignored_tail", empty(), vacant, c("False"), false, "NoProgress");
    check("nested_active_tail", semanticInput(), input, c("False"), false, "Consumed");
    check("nested_active_tail", cons(grain(11), empty()), singleton, c("False"), false, "Consumed");
    check("nested_active_tail", empty(), vacant, c("True"), true, "NoProgress");
  });

  test("named ordinary helpers adapt to callback inputs without changing semantic values or crediting ignored tails", () => {
    check("named_ignored_tail", semanticInput(), input, c("True"), true, "NoProgress");
    check("named_active_tail", semanticInput(), input, c("False"), false, "Consumed");
    check("named_active_tail", cons(grain(11), empty()), singleton, c("False"), false, "Consumed");
    check("named_active_tail", empty(), vacant, c("True"), true, "NoProgress");
  });

  test("a deferred resumer passes its real input witness into opaque callbacks without eager activation", () => {
    check("deferred_ignored_tail", semanticInput(), input, c("True"), true, "NoProgress");
    check("deferred_head_tail", semanticInput(), input, 29, 29, "NoProgress");
    check("deferred_head_tail", cons(grain(11), empty()), singleton, 0, 0, "NoProgress");
    check("deferred_active_tail", semanticInput(), input, c("False"), false, "Consumed");
    check("deferred_active_tail", cons(grain(11), empty()), singleton, c("False"), false, "Consumed");
    check("deferred_active_tail", empty(), vacant, c("True"), true, "NoProgress");
  });

  test("curried lambdas defer input witness credit until active terminal-body use", () => {
    check("curried_ignored_tail", semanticInput(), input, c("False"), false, "NoProgress");
    check("curried_active_tail", semanticInput(), input, c("True"), true, "Consumed");
    check("curried_active_tail", cons(grain(11), empty()), singleton, c("True"), true, "Consumed");
    check("curried_active_tail", empty(), vacant, c("False"), false, "NoProgress");
  });

  test("partial named callbacks retain witnesses until their terminal semantic argument arrives", () => {
    check("partial_ignored_tail", semanticInput(), input, c("False"), false, "NoProgress");
    check("partial_active_tail", semanticInput(), input, c("True"), true, "Consumed");
    check("partial_active_tail", cons(grain(11), empty()), singleton, c("True"), true, "Consumed");
    check("partial_active_tail", empty(), vacant, c("False"), false, "NoProgress");
  });

  test("ordinary branch selectors activate only the chosen aliased cursor and preserve its exact remainder", () => {
    checkChoice("azalea", true, semanticInput(), input, semanticInput(), input, "NoProgress");
    checkChoice("azalea", false, semanticInput(), input, cons(grain(29), empty()), input.tail, "Consumed");
    checkChoice("azalea", true, cons(grain(11), empty()), singleton, cons(grain(11), empty()), singleton, "NoProgress");
    checkChoice("azalea", false, cons(grain(11), empty()), singleton, empty(), vacant, "Consumed");
    checkChoice("azalea", true, empty(), vacant, empty(), vacant, "NoProgress");
    checkChoice("azalea", false, empty(), vacant, empty(), vacant, "NoProgress");
  });

  test("an ordinary selector leaves dormant aliased inputs uncredited but activates a matched tail when used", () => {
    checkChoice("birch", true, semanticInput(), input, c("True"), true, "NoProgress");
    checkChoice("birch", false, semanticInput(), input, c("False"), false, "Consumed");
    checkChoice("birch", true, cons(grain(11), empty()), singleton, c("True"), true, "NoProgress");
    checkChoice("birch", false, cons(grain(11), empty()), singleton, c("False"), false, "Consumed");
    checkChoice("birch", true, empty(), vacant, c("True"), true, "NoProgress");
    checkChoice("birch", false, empty(), vacant, c("False"), false, "NoProgress");
  });

  test("head-only observation of either aliased selector input does not consume its matched-tail witness", () => {
    checkChoice("cedar", true, semanticInput(), input, 11, 11, "NoProgress");
    checkChoice("cedar", false, semanticInput(), input, 29, 29, "NoProgress");
    checkChoice("cedar", false, cons(grain(11), empty()), singleton, 0, 0, "NoProgress");
    checkChoice("cedar", true, empty(), vacant, 0, 0, "NoProgress");
    checkChoice("cedar", false, empty(), vacant, 0, 0, "NoProgress");
  });

  test("two slots holding the same matched tail retain one branch-selected activation", () => {
    checkChoice("dogwood", true, semanticInput(), input, cons(grain(29), empty()), input.tail, "Consumed");
    checkChoice("dogwood", false, semanticInput(), input, cons(grain(29), empty()), input.tail, "Consumed");
    checkChoice("dogwood", true, empty(), vacant, empty(), vacant, "NoProgress");
  });
});

test("mutually exclusive selectors do not authorize simultaneous activation of related ordinary inputs", async () => {
  await expect(fixture(`
def wren(ash: List<&2, Pebble>) -> List<&2, Pebble>:
  match ash:
    case seed <> twig: twig
    case Nil{}: ash
def juniper(alder: List<&2, Pebble>, willow: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match choice:
    case True{}:
      discarded = wren(alder)
      wren(willow)
    case False{}: willow
def hazel(+spruce: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match spruce:
    case seed <> twig: juniper(spruce, twig, choice)
    case Nil{}: spruce
`)).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

test("a branch-selected cursor cannot be consumed and then replayed through its preserved alias", async () => {
  await expect(fixture(`
def larch(alder: List<&2, Pebble>, willow: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match choice:
    case True{}: alder
    case False{}: willow
def robin(ash: List<&2, Pebble>) -> List<&2, Pebble>:
  match ash:
    case seed <> twig: twig
    case Nil{}: ash
def elm(+spruce: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match spruce:
    case seed <> twig:
      selected = larch(spruce, twig, choice)
      discarded = robin(selected)
      spruce
    case Nil{}: spruce
`)).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

test("separate selector invocations cannot reuse one branch-exclusivity proof for aliased inputs", async () => {
  await expect(fixture(`
def sycamore(alder: List<&2, Pebble>, willow: List<&2, Pebble>, choice: Bool) -> List<&2, Pebble>:
  match choice:
    case True{}: alder
    case False{}: willow
def poppy(+alder: List<&2, Pebble>, +willow: List<&2, Pebble>, first: Bool, second: Bool) -> List<&2, Pebble>:
  discarded = sycamore(alder, willow, first)
  sycamore(alder, willow, second)
def maple(+spruce: List<&2, Pebble>, first: Bool, second: Bool) -> List<&2, Pebble>:
  match spruce:
    case seed <> twig: poppy(spruce, twig, first, second)
    case Nil{}: spruce
`)).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

describe("generated Control runtime with an instrumented semantic child", () => {
  let compiled: Record<string, (...args: unknown[]) => unknown>;
  const vacant = { $: "Nil" };
  const input = { $: "Con", head: { $: "Grain", code: 11 }, tail: vacant };
  const unrelated = {
    $: "Con", head: { $: "Grain", code: 503 },
    tail: { $: "Con", head: { $: "Grain", code: 509 }, tail: vacant },
  };
  const node = { $: "Node", code: 73, span: { $: "Tuple", fst: 101, snd: 109 } };

  beforeAll(async () => {
    const runtime = renderExplicitControlRuntime({
      frameVariants: ["  KontWrap{tag: Nat}", "  KontWatch{captured: List<&2, Pebble>}", "  KontDeferred{captured: List<&2, Pebble>, node: Syntax, witness: FeedbackCursorWitness}"],
      requestVariants: [
        "  RequestChild{state: EntryState, unrelated: List<&2, Pebble>, node: Syntax}",
        "  RequestIdle{state: EntryState, node: Syntax}",
      ],
      dispatchCases: [
        "    case RequestChild{state, unrelated, node}:",
        "      dispatch_packet(ep_child(state, unrelated, node))",
        "    case RequestIdle{state, node}:",
        "      FeedbackControl{FeedbackDone{ValueIdle{state, node}}, Nil{}, NoProgress{}, NoProgress{}}",
      ],
      resumeCases: [
        "    case KontWrap{tag}:",
        "      match value:",
        "        case ValueShift{Shifted{cursor}, node}:",
        "          FeedbackControl{FeedbackDone{ValueFinal{cursor, node, tag <> Nil{}}}, Nil{}, NoProgress{}, NoProgress{}}",
        "        case ValueIdle{Waiting{cursor}, node}:",
        "          FeedbackControl{FeedbackDone{ValueFinal{cursor, node, tag <> Nil{}}}, Nil{}, NoProgress{}, NoProgress{}}",
        "        case ValueFinal{cursor, node, trail}:",
        "          FeedbackControl{FeedbackDone{ValueFinal{cursor, node, tag <> trail}}, Nil{}, NoProgress{}, NoProgress{}}",
        "    case KontWatch{captured}:",
        "      FeedbackControl{FeedbackDone{value}, Nil{}, NoProgress{}, NoProgress{}}",
        "    case KontDeferred{captured, node, +witness}:",
        "      ep_resume_deferred(captured, node, witness)",
      ],
    });
    const source = preamble + `
type Syntax is Data:
  Node{code: Nat, span: Sigma<&2, &2, Nat, _ => Nat>}
type EntryState is Data:
  Waiting{cursor: List<&2, Pebble>}
type ExitState is Data:
  Shifted{cursor: List<&2, Pebble>}
type FeedbackValue is Data:
  ValueIdle{state: EntryState, node: Syntax}
  ValueShift{state: ExitState, node: Syntax}
  ValueFinal{cursor: List<&2, Pebble>, node: Syntax, trail: List<&2, Nat>}
` + runtime.typeDeclarations.join("\n\n") + "\n\n" + [...runtime.declarations.values()].join("\n\n") + `

def fixture_fuel() -> FeedbackFuel:
  FeedbackFuelCell{FeedbackFuelCell{FeedbackFuelCell{FeedbackFuelCell{FeedbackFuelCell{FeedbackFuelCell{FeedbackFuelCell{FeedbackFuelCell{FeedbackFuelEnd{}}}}}}}}}
def pass(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  cursor
def opaque(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>) -> List<&2, Pebble>:
  unrelated
def before(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      rest
    case Nil{}:
      cursor
def child(state: EntryState, unrelated: List<&2, Pebble>, node: Syntax) -> FeedbackValue:
  match state:
    case Waiting{cursor}:
      match cursor:
        case head <> rest:
          active = pass(rest)
          ValueShift{Shifted{opaque(active, unrelated)}, node}
        case Nil{}:
          ValueIdle{Waiting{cursor}, node}
def dispatch_packet(packet: FeedbackValue & Progress) -> FeedbackControl:
  match packet:
    case (value, +progress):
      FeedbackControl{FeedbackDone{value}, Nil{}, progress, progress}
def resume_packet(packet: FeedbackValue & Progress) -> FeedbackResume:
  match packet:
    case (value, progress):
      feedback_resume(FeedbackKont{KontWrap{109n}, NoProgress{}}, value, progress)
def saved_packet(packet: List<&2, Pebble> & Progress, node: Syntax) -> FeedbackResume:
  match packet:
    case (cursor, progress):
      feedback_resume(FeedbackKont{KontWrap{109n}, progress}, ValueIdle{Waiting{cursor}, node}, NoProgress{})
def saved_probe(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackResume:
  saved_packet(ep_before(cursor), node)
def paused(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>, node: Syntax) -> FeedbackControl:
  FeedbackControl{FeedbackCall{RequestChild{Waiting{cursor}, unrelated, node}}, Nil{}, NoProgress{}, NoProgress{}}
def dispatch_probe(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>, node: Syntax) -> FeedbackControl:
  feedback_dispatch(RequestChild{Waiting{cursor}, unrelated, node})
def child_probe(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>, node: Syntax) -> FeedbackRun:
  feedback_drive(fixture_fuel(), paused(cursor, unrelated, node), Nil{})
def resume_probe(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>, node: Syntax) -> FeedbackResume:
  resume_packet(ep_child(Waiting{cursor}, unrelated, node))
def parent_probe(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>, node: Syntax) -> FeedbackRun:
  feedback_drive(fixture_fuel(), feedback_attach(paused(cursor, unrelated, node), KontWrap{109n}), Nil{})
def nested_probe(cursor: List<&2, Pebble>, unrelated: List<&2, Pebble>, node: Syntax) -> FeedbackRun:
  inner = feedback_attach(paused(cursor, unrelated, node), KontWrap{109n})
  outer = feedback_attach(inner, KontWrap{101n})
  feedback_drive(fixture_fuel(), outer, Nil{})
def prior(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackControl:
  active = before(cursor)
  child = FeedbackControl{FeedbackCall{RequestIdle{Waiting{active}, node}}, Nil{}, NoProgress{}, NoProgress{}}
  feedback_attach(child, KontWrap{109n})
def prior_probe(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackControl:
  ep_prior(cursor, node)
def failure_probe(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackRun:
  feedback_drive(fixture_fuel(), prior_probe(cursor, node), Nil{})
def make_capture(cursor: List<&2, Pebble>) -> FeedbackFrame:
  KontWatch{cursor}
def capture(+cursor: List<&2, Pebble>, node: Syntax) -> FeedbackControl:
  match cursor:
    case Con{head, +rest}:
      child = FeedbackControl{FeedbackCall{RequestIdle{Waiting{cursor}, node}}, Nil{}, NoProgress{}, NoProgress{}}
      feedback_attach(child, make_capture(rest))
    case Nil{}:
      child = FeedbackControl{FeedbackCall{RequestIdle{Waiting{cursor}, node}}, Nil{}, NoProgress{}, NoProgress{}}
      feedback_attach(child, make_capture(cursor))
def capture_probe(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackRun:
  feedback_drive(fixture_fuel(), ep_capture(cursor, node), Nil{})
def make_deferred(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackFrame:
  KontDeferred{cursor, node, WitnessNone{}}
def park(cursor: List<&2, Pebble>, +node: Syntax) -> FeedbackControl:
  match cursor:
    case head <> rest:
      child = FeedbackControl{FeedbackCall{RequestIdle{Waiting{Nil{}}, node}}, Nil{}, NoProgress{}, NoProgress{}}
      feedback_attach(child, make_deferred(rest, node))
    case Nil{}:
      child = FeedbackControl{FeedbackCall{RequestIdle{Waiting{Nil{}}, node}}, Nil{}, NoProgress{}, NoProgress{}}
      feedback_attach(child, make_deferred(cursor, node))
def finish_deferred(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackControl:
  FeedbackControl{FeedbackDone{ValueIdle{Waiting{cursor}, node}}, Nil{}, NoProgress{}, NoProgress{}}
def resume_deferred(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackControl:
  finish_deferred(cursor, node)
def deferred_probe(cursor: List<&2, Pebble>, node: Syntax) -> FeedbackRun:
  feedback_drive(fixture_fuel(), ep_park(cursor, node), Nil{})
def witness_probe(witness: FeedbackCursorWitness) -> Progress:
  feedback_witness_progress(witness)
def witness_clear_probe(path: List<&2, Nat>, witness: FeedbackCursorWitness) -> FeedbackCursorWitness:
  feedback_witness_clear(path, witness)
`;
    const program = instrumentExplicitProgress(await readParserGraph(source), {
      tokenElement: "Pebble", definitions: ["child", "pass", "opaque", "before", "prior", "capture", "park", "resume_deferred"],
      nameOf: name => "ep_" + name, emitPrelude: false,
      primitiveOperations: new Map([["feedback_attach", {
        kind: "suspend", carriesControl: true, frameArgument: 1,
        captureName: "feedback_attach_with_progress",
      } as const], ["make_capture", { kind: "suspend" } as const],
        ["make_deferred", { kind: "suspend", captureArguments: [{ index: 0, witnessName: "witness" }] } as const],
        ["finish_deferred", { kind: "return", activeArguments: [0], carriesControl: true } as const]]),
      parameterWitnesses: new Map([["resume_deferred", [{ parameterIndex: 0, witnessName: "witness" }]]]),
    });
    const path = resolve(import.meta.dir, "../bend2/selfhost", `explicit_progress_test_${randomUUID()}.bend`);
    try {
      const complete = source + "\n" + program.declarations;
      const graph = await readParserGraph(complete);
      const headers = [...complete.matchAll(/^(type|def|law) (\S+)/gm)];
      const chunks = new Map(headers.filter(header => header[1] === "def").map(header => [
        header[2]!.split("(")[0]!, complete.slice(header.index, headers[headers.indexOf(header) + 1]?.index ?? complete.length),
      ]));
      // The native candidate contains replacements, not the obsolete source bodies.
      for (const name of program.functions.keys()) chunks.delete(name);
      chunks.set("make_deferred", "def make_deferred(cursor: List<&2, Pebble>, node: Syntax, witness: FeedbackCursorWitness) -> FeedbackFrame:\n  KontDeferred{cursor, node, witness}");
      const ordered: string[] = [], visited = new Set<string>(), visiting = new Set<string>();
      function order(name: string): void {
        if (visited.has(name)) return;
        if (visiting.has(name)) throw new Error("Mutual native fixture recursion: " + name);
        visiting.add(name);
        for (const dependency of graph.edges[name] ?? []) if (dependency !== name && chunks.has(dependency)) order(dependency);
        visiting.delete(name); visited.add(name); ordered.push(chunks.get(name)!);
      }
      for (const name of chunks.keys()) order(name);
      const types = headers.filter(header => header[1] !== "def").map(header =>
        complete.slice(header.index, headers[headers.indexOf(header) + 1]?.index ?? complete.length));
      writeFileSync(path, ["import Base", ...types, ...ordered].join("\n\n"));
      const book = book_nil();
      try {
        await book_load(book, path, "", new Map());
        book_valid(book);
      } catch (error) {
        if (error && typeof error === "object" && "$" in error && error.$ === "Err") throw new Error(err_show(error as Err));
        throw error;
      }
      const entries = ["dispatch_probe", "child_probe", "resume_probe", "saved_probe", "parent_probe", "nested_probe", "prior_probe", "failure_probe", "capture_probe", "deferred_probe", "witness_probe", "witness_clear_probe"];
      const javascript = js_lib(book,true,{roots:entries,exports:entries});
      // The module is compiler output for this fixture; no static module exists.
      compiled = (await import("data:text/javascript;base64," + Buffer.from(javascript).toString("base64"))).default;
    } finally {
      rmSync(path, { force: true });
    }
  });

  test("Request dispatch and Outcome preserve direct-tail child consumption despite a different result/state and opaque remainder", () => {
    const shifted = { $: "ValueShift", state: { $: "Shifted", cursor: unrelated }, node };
    expect(compiled.dispatch_probe!(input, unrelated, node)).toEqual({
      $: "FeedbackControl", action: { $: "FeedbackDone", value: shifted },
      pending: vacant, progress: { $: "Consumed" }, own_progress: { $: "Consumed" },
    });
    expect(compiled.child_probe!(input, unrelated, node)).toEqual({
      $: "FeedbackComplete", value: shifted, progress: { $: "Consumed" },
    });
    expect(compiled.child_probe!(vacant, unrelated, node)).toEqual({
      $: "FeedbackComplete", value: { $: "ValueIdle", state: { $: "Waiting", cursor: vacant }, node },
      progress: { $: "NoProgress" },
    });
  });

  test("the resumed segment explicitly reports child consumption before the outer continuation returns", () => {
    const trail = { $: "Con", head: 109, tail: vacant };
    expect(compiled.resume_probe!(input, unrelated, node)).toEqual({
      $: "FeedbackResume",
      control: {
        $: "FeedbackControl",
        action: { $: "FeedbackDone", value: { $: "ValueFinal", cursor: unrelated, node, trail } },
        pending: vacant, progress: { $: "Consumed" }, own_progress: { $: "NoProgress" },
      },
      progress: { $: "Consumed" }, own_progress: { $: "NoProgress" },
    });
    expect(compiled.resume_probe!(vacant, unrelated, node)).toEqual({
      $: "FeedbackResume",
      control: {
        $: "FeedbackControl",
        action: { $: "FeedbackDone", value: { $: "ValueFinal", cursor: vacant, node, trail } },
        pending: vacant, progress: { $: "NoProgress" }, own_progress: { $: "NoProgress" },
      },
      progress: { $: "NoProgress" }, own_progress: { $: "NoProgress" },
    });
  });

  test("a previously consuming saved frame cannot credit a neutral resumed handler with fresh consumption", () => {
    const trail = { $: "Con", head: 109, tail: vacant };
    expect(compiled.saved_probe!(input, node)).toEqual({
      $: "FeedbackResume",
      control: {
        $: "FeedbackControl",
        action: { $: "FeedbackDone", value: { $: "ValueFinal", cursor: vacant, node, trail } },
        pending: vacant, progress: { $: "Consumed" }, own_progress: { $: "NoProgress" },
      },
      progress: { $: "Consumed" }, own_progress: { $: "NoProgress" },
    });
    expect(compiled.saved_probe!(vacant, node)).toEqual({
      $: "FeedbackResume",
      control: {
        $: "FeedbackControl",
        action: { $: "FeedbackDone", value: { $: "ValueFinal", cursor: vacant, node, trail } },
        pending: vacant, progress: { $: "NoProgress" }, own_progress: { $: "NoProgress" },
      },
      progress: { $: "NoProgress" }, own_progress: { $: "NoProgress" },
    });
  });

  test("parent suspension resumes the outer continuation after child consumption with untouched semantic data", () => {
    expect(compiled.parent_probe!(input, unrelated, node)).toEqual({
      $: "FeedbackComplete",
      value: { $: "ValueFinal", cursor: unrelated, node, trail: { $: "Con", head: 109, tail: vacant } },
      progress: { $: "Consumed" },
    });
    expect(compiled.parent_probe!(vacant, unrelated, node)).toEqual({
      $: "FeedbackComplete",
      value: { $: "ValueFinal", cursor: vacant, node, trail: { $: "Con", head: 109, tail: vacant } },
      progress: { $: "NoProgress" },
    });
  });

  test("nested frames of the same Kont constructor both resume and retain the child's effect", () => {
    const trail = { $: "Con", head: 101, tail: { $: "Con", head: 109, tail: vacant } };
    expect(compiled.nested_probe!(input, unrelated, node)).toEqual({
      $: "FeedbackComplete", value: { $: "ValueFinal", cursor: unrelated, node, trail },
      progress: { $: "Consumed" },
    });
    expect(compiled.nested_probe!(vacant, unrelated, node)).toEqual({
      $: "FeedbackComplete", value: { $: "ValueFinal", cursor: vacant, node, trail },
      progress: { $: "NoProgress" },
    });
  });

  test("prior caller consumption survives an unchanged child failure without crediting that child on entry", () => {
    expect(compiled.prior_probe!(input, node)).toEqual({
      $: "FeedbackControl",
      action: { $: "FeedbackCall", request: { $: "RequestIdle", state: { $: "Waiting", cursor: vacant }, node } },
      pending: {
        $: "Con", head: { $: "FeedbackKont", frame: { $: "KontWrap", tag: 109 }, progress: { $: "Consumed" } },
        tail: vacant,
      },
      progress: { $: "NoProgress" }, own_progress: { $: "Consumed" },
    });
    expect(compiled.failure_probe!(input, node)).toEqual({
      $: "FeedbackComplete",
      value: { $: "ValueFinal", cursor: vacant, node, trail: { $: "Con", head: 109, tail: vacant } },
      progress: { $: "Consumed" },
    });
    expect(compiled.failure_probe!(vacant, node)).toEqual({
      $: "FeedbackComplete",
      value: { $: "ValueFinal", cursor: vacant, node, trail: { $: "Con", head: 109, tail: vacant } },
      progress: { $: "NoProgress" },
    });
  });

  test("a matched tail captured on a frame and ignored on resume is not consumption", () => {
    expect(compiled.capture_probe!(input, node)).toEqual({
      $: "FeedbackComplete",
      value: { $: "ValueIdle", state: { $: "Waiting", cursor: input }, node },
      progress: { $: "NoProgress" },
    });
    expect(compiled.capture_probe!(vacant, node)).toEqual({
      $: "FeedbackComplete",
      value: { $: "ValueIdle", state: { $: "Waiting", cursor: vacant }, node },
      progress: { $: "NoProgress" },
    });
  });
  test("a captured structural tail reports consumption only when its resumer activates it", () => {
    expect(compiled.deferred_probe!(input, node)).toEqual({
      $: "FeedbackComplete", value: { $: "ValueIdle", state: { $: "Waiting", cursor: vacant }, node }, progress: { $: "Consumed" },
    });
    expect(compiled.deferred_probe!(vacant, node)).toEqual({
      $: "FeedbackComplete", value: { $: "ValueIdle", state: { $: "Waiting", cursor: vacant }, node }, progress: { $: "NoProgress" },
    });
  });

  test("nested captured cursor fields compose only their explicit Progress", () => {
    const tail = (progress: string) => ({ $: "WitnessTail", progress: { $: progress } });
    const fields = (head: unknown, rest: unknown = vacant) => ({ $: "WitnessFields", fields: { $: "Con", head, tail: rest } });
    expect(compiled.witness_probe!(fields(fields(tail("Consumed"))))).toEqual({ $: "Consumed" });
    expect(compiled.witness_probe!(fields(fields(tail("NoProgress"))))).toEqual({ $: "NoProgress" });
  });
  test("retiring a nested witness field preserves sibling credits and cannot replay the retired credit", () => {
    const cons = (head: unknown, tail: unknown = vacant) => ({ $: "Con", head, tail });
    const consumed = { $: "WitnessTail", progress: { $: "Consumed" } };
    const neutral = { $: "WitnessTail", progress: { $: "NoProgress" } };
    const nested = { $: "WitnessFields", fields: cons(consumed, cons(neutral)) };
    const tree = { $: "WitnessFields", fields: cons(nested, cons(consumed)) };
    const first = compiled.witness_clear_probe!(cons(0, cons(0)), tree);
    expect(first).toEqual({
      $: "WitnessFields", fields: cons({ $: "WitnessFields", fields: cons({ $: "WitnessNone" }, cons(neutral)) }, cons(consumed)),
    });
    expect(compiled.witness_probe!(first)).toEqual({ $: "Consumed" });
    const second = compiled.witness_clear_probe!(cons(1), first);
    expect(compiled.witness_probe!(second)).toEqual({ $: "NoProgress" });
    expect(compiled.witness_probe!(tree)).toEqual({ $: "Consumed" });
  });
});
