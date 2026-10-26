// Host text seam for exported Char and String: the inner library is built by the
// compiler under test, and every call below crosses the public export ABI. A
// factory's result is a function, so its declared result is not text.
function text_host_export() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-text-export-"));
  try {
    const input = path.join(dir, "lib.bend");
    const output = path.join(dir, "lib.mjs");
    fs.writeFileSync(input, `import Base

def echo(c: Char) -> Char:
  c

def greet(name: String, c: Char) -> String:
  SCon{c, name}

def code(c: Char) -> U32:
  Char.to_u32(c)

def lone() -> Char:
  Char.from_u32(55296)

def text() -> String:
  SCon{Char.from_u32(1114112), SNil{}}

def factory() -> (Char -> Char):
  c => c
`);
    const given = process.env.BEND_INNER_LIBRARY_COMPILER;
    const mainTs = given === undefined
      ? [process.env.BEND_MAIN_TS, path.resolve("bend2/main.ts"),
        path.resolve("..", "..", "bend2/main.ts"),
        path.resolve(typeof __dirname === "string" ? __dirname : ".", "..", "..", "bend2/main.ts")]
        .find((p) => typeof p === "string" && fs.existsSync(p))
      : undefined;
    if (given === undefined && mainTs === undefined) {
      return 1;
    }
    const compiler = given === undefined
      ? [process.execPath, mainTs]
      : JSON.parse(given);
    const built = child.spawnSync(compiler[0],
      [...compiler.slice(1), input, "-o", output], {
        encoding: "utf8",
        env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9" },
      });
    if (built.status !== 0) {
      return 1;
    }
    const lib = require(output).default;
    const replacement = "\uFFFD";
    const good = [
      // an argument is host text: a scalar passes, a lone surrogate does not
      lib.echo("a") === "a",
      lib.echo("\uD800") === replacement,
      lib.code("\uD800") === 65533,
      // a completed Char or String result is published as text
      lib.lone() === replacement,
      lib.text() === replacement,
      // partial application carries the same per-parameter conversion
      lib.greet("x")("y") === "yx",
      lib.greet("x", "y") === "yx",
      typeof lib.greet("\uD800") === "function",
      lib.greet("\uD800")("z") === "z" + replacement,
      // a factory's published signature is one arrow, so no arguments is a
      // partial closure and one argument completes it as text
      typeof lib.factory() === "function",
      lib.factory("y") === "y",
      lib.factory("\uD800") === replacement,
      // excess host arguments are ignored once the published arity is met
      lib.greet("x", "y", "extra") === "yx",
      lib.factory("y", "extra") === "y",
    ];
    return good.every((pass) => pass) ? 0 : 3;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Text.host_export), text_host_export);
