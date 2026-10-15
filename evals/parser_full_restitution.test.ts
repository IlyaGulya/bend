import { beforeAll, describe, expect, test } from "bun:test";
import { randomUUID } from "node:crypto";
import { rmSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { book_load, book_nil, book_valid, err_show } from "../bend2/bend.ts";
import type { Err } from "../bend2/bend.ts";
import { js_lib } from "../bend2/comp.ts";
import { renderBody } from "./parser_full_body_render.ts";
import { constructorValue, instrumentExplicitProgress, UnsupportedInstrumentation } from "./parser_full_explicit_progress.ts";
import type { ExplicitProgressProgram, RuntimeValue } from "./parser_full_explicit_progress.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { optimizeCursorRestitution } from "./parser_full_restitution.ts";

const preamble = `import Base
type Pebble is Data:
  Grain{code: Nat}
  Mark{ready: Bool, start: Nat, finish: Nat}
`;
const c = constructorValue;
const empty = () => c("Nil");
const grain = (code: number) => c("Grain", code);
const cons = (head: RuntimeValue, tail: RuntimeValue) => c("Con", head, tail);
type NativeProgram = Record<string, (...args: unknown[]) => { $: string; fst: unknown; snd: { $: string } }>;

async function fixture(source: string, roots: string[]) {
  const graph = await readParserGraph(preamble + source);
  const normalized = optimizeCursorRestitution(graph, "Pebble");
  const definitions = graph.definitions.map(name => {
    const signature = normalized.signatures.get(name) ?? graph.signatures.get(name)!;
    const body = normalized.bodies.get(name) ?? graph.bodies.get(name)!;
    const rendered = renderBody(body, signature.parameters, { book: graph.parserBook });
    return `def ${name}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:\n${rendered.body}`;
  });
  const reparsed = await readParserGraph(preamble + definitions.join("\n\n"));
  const reachable = new Set(roots);
  const work = [...roots];
  for (let i = 0; i < work.length; i++) {
    for (const dependency of reparsed.edges[work[i]!] ?? []) {
      if (!reachable.has(dependency)) { reachable.add(dependency); work.push(dependency); }
    }
  }
  const program = instrumentExplicitProgress(reparsed, {
    tokenElement: "Pebble", definitions: reachable, driverEntryPoints: roots,
  });
  return { program, source: preamble + definitions.join("\n\n") };
}

async function compile(program: ExplicitProgressProgram, source: string, roots: string[]): Promise<NativeProgram> {
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
    if (visiting.has(name)) throw Error("Mutual native restitution fixture recursion: " + name);
    visiting.add(name);
    for (const dependency of graph.edges[name] ?? []) if (dependency !== name && chunks.has(dependency)) order(dependency);
    visiting.delete(name); visited.add(name); ordered.push(chunks.get(name)!);
  }
  for (const name of roots.map(root => "ep_" + root)) order(name);
  const types = headers.filter(header => header[1] !== "def").map(header =>
    complete.slice(header.index, headers[headers.indexOf(header) + 1]?.index ?? complete.length));
  const path = resolve(import.meta.dir, "../bend2/selfhost", `restitution_test_${randomUUID()}.bend`);
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
    const entries = roots.map(name => "ep_" + name);
    const javascript = js_lib(book,true,{roots:entries,exports:entries});
    // This fixture's freshly generated compiler output has no static module.
    return (await import("data:text/javascript;base64," + Buffer.from(javascript).toString("base64"))).default as NativeProgram;
  } finally {
    rmSync(path, { force: true });
  }
}

const accepted = `
def rebuild(+cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      head <> rest
    case Nil{}:
      cursor

def choose(+cursor: List<&2, Pebble>, flag: Bool) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      match flag:
        case True{}:
          head <> rest
        case False{}:
          rest
    case Nil{}:
      cursor

def nested(result: (Nat & List<&2, Pebble>) & Bool) -> List<&2, Pebble>:
  match result:
    case ((payload, head <> rest), True{}):
      head <> rest
    case ((payload, head <> rest), False{}):
      rest
    case ((payload, Nil{}), flag):
      Nil{}

def restore_mark(start: Nat, finish: Nat, tail: List<&2, Pebble>) -> List<&2, Pebble>:
  Mark{True{}, start, finish} <> tail

def restore_token(head: Pebble, rest: List<&2, Pebble>) -> List<&2, Pebble>:
  match head:
    case Grain{code}:
      Grain{code} <> rest
    case Mark{ready, start, finish}:
      Mark{ready, start, finish} <> rest

def literal_match(+cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case Mark{True{}, start, finish} <> rest:
      restore_mark(start, finish, rest)
    case head <> rest:
      head <> rest
    case Nil{}:
      cursor

def renamed(+spruce: List<&2, Pebble>) -> List<&2, Pebble>:
  match spruce:
    case seed <> twig:
      restore_token(seed, twig)
    case Nil{}:
      spruce

def shadowed(+head: List<&2, Pebble>) -> List<&2, Pebble>:
  match head:
    case seed <> rest:
      head = seed
      restore_token(head, rest)
    case Nil{}:
      head
`;
const roots = ["rebuild", "choose", "nested", "literal_match", "renamed", "shadowed"];

describe("matched cursor restitution through the actual effect and native compilers", () => {
  let program: ExplicitProgressProgram;
  let compiled: NativeProgram;
  beforeAll(async () => {
    const normalized = await fixture(accepted, roots);
    program = normalized.program;
    compiled = await compile(program, normalized.source, roots);
  });

  function check(name: string, semanticArgs: RuntimeValue[], nativeArgs: unknown[], value: RuntimeValue, nativeValue: unknown, progress: "NoProgress" | "Consumed") {
    const result = program.execute(name, semanticArgs);
    expect(result).toEqual({ value, progress });
    expect(result.value).toBe(value);
    const native = compiled["ep_" + name]!(...nativeArgs);
    expect(native).toEqual({ $: "Tuple", fst: nativeValue, snd: { $: progress } });
    expect(native.fst).toBe(nativeValue);
  }

  test("generic nonempty head and tail reconstruction returns the original cursor without consumption", () => {
    const tail = cons(grain(29), empty());
    const input = cons(grain(11), tail);
    const nativeTail = { $: "Con", head: { $: "Grain", code: 29 }, tail: { $: "Nil" } };
    const nativeInput = { $: "Con", head: { $: "Grain", code: 11 }, tail: nativeTail };
    check("rebuild", [input], [nativeInput], input, nativeInput, "NoProgress");
    const vacant = empty(), nativeVacant = { $: "Nil" };
    check("rebuild", [vacant], [nativeVacant], vacant, nativeVacant, "NoProgress");
  });

  test("only the executed branch choosing the tail is Consumed", () => {
    const tail = cons(grain(29), empty()), input = cons(grain(11), tail);
    const nativeTail = { $: "Con", head: { $: "Grain", code: 29 }, tail: { $: "Nil" } };
    const nativeInput = { $: "Con", head: { $: "Grain", code: 11 }, tail: nativeTail };
    check("choose", [input, c("True")], [nativeInput, true], input, nativeInput, "NoProgress");
    check("choose", [input, c("False")], [nativeInput, false], tail, nativeTail, "Consumed");
    const vacant = empty(), nativeVacant = { $: "Nil" };
    for (const flag of [true, false]) {
      check("choose", [vacant, c(flag ? "True" : "False")], [nativeVacant, flag], vacant, nativeVacant, "NoProgress");
    }
  });

  test("a nested result-product match preserves its exact embedded cursor or consumes its chosen tail", () => {
    const tail = cons(grain(29), empty()), input = cons(grain(11), tail);
    const nativeTail = { $: "Con", head: { $: "Grain", code: 29 }, tail: { $: "Nil" } };
    const nativeInput = { $: "Con", head: { $: "Grain", code: 11 }, tail: nativeTail };
    for (const flag of [true, false]) {
      const result = c("Tuple", c("Tuple", 73, input), c(flag ? "True" : "False"));
      const nativeResult = { $: "Tuple", fst: { $: "Tuple", fst: 73, snd: nativeInput }, snd: flag };
      check("nested", [result], [nativeResult], flag ? input : tail, flag ? nativeInput : nativeTail, flag ? "NoProgress" : "Consumed");
    }
  });

  test("exact literal fields survive helper instantiation without allocating a new cursor", () => {
    const tail = cons(grain(29), empty());
    const input = cons(c("Mark", c("True"), 101, 109), tail);
    const nativeInput = { $: "Con", head: { $: "Mark", ready: true, start: 101, finish: 109 }, tail: { $: "Con", head: { $: "Grain", code: 29 }, tail: { $: "Nil" } } };
    check("literal_match", [input], [nativeInput], input, nativeInput, "NoProgress");
    const fallback = cons(grain(11), tail);
    const nativeFallback = { $: "Con", head: { $: "Grain", code: 11 }, tail: nativeInput.tail };
    check("literal_match", [fallback], [nativeFallback], fallback, nativeFallback, "NoProgress");
  });

  test("renamed and shadowed binders retain the matched token rather than a colliding helper binder", () => {
    for (const name of ["renamed", "shadowed"]) {
      const input = cons(grain(503), cons(grain(509), empty()));
      const nativeInput = { $: "Con", head: { $: "Grain", code: 503 }, tail: { $: "Con", head: { $: "Grain", code: 509 }, tail: { $: "Nil" } } };
      check(name, [input], [nativeInput], input, nativeInput, "NoProgress");
      const marked = cons(c("Mark", c("False"), 101, 109), empty());
      const nativeMarked = { $: "Con", head: { $: "Mark", ready: false, start: 101, finish: 109 }, tail: { $: "Nil" } };
      check(name, [marked], [nativeMarked], marked, nativeMarked, "NoProgress");
    }
  });
});

test("changing an exact matched literal remains unsupported", async () => {
  await expect(fixture(`
def altered(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case Mark{True{}, start, finish} <> rest:
      Mark{False{}, start, finish} <> rest
    case head <> rest:
      head <> rest
    case Nil{}:
      cursor
`, ["altered"])).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

test("a freshly synthesized head is not mistaken for matched restitution", async () => {
  await expect(fixture(`
def synthesized(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      Grain{509n} <> rest
    case Nil{}:
      cursor
`, ["synthesized"])).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});

test("rebuilding a matched cursor after real advancement cannot rewind or replay its head", async () => {
  await expect(fixture(`
def peel(cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> rest:
      rest
    case Nil{}:
      cursor

def replay(+cursor: List<&2, Pebble>) -> List<&2, Pebble>:
  match cursor:
    case head <> +rest:
      advanced = peel(rest)
      head <> rest
    case Nil{}:
      cursor
`, ["replay"])).rejects.toBeInstanceOf(UnsupportedInstrumentation);
});
