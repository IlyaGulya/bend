// Builds a library with a generic exported identity and checks that abstract
// parameters pass unchanged: no Nat bound error for a negative or fractional
// number, no conversion for strings, and no refusal of the export itself.
function generic_host_export() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-generic-export-"));
  try {
    const input = path.join(dir, "lib.bend");
    const output = path.join(dir, "lib.mjs");
    fs.writeFileSync(input, `import Base

def id(-A: Type, x: A) -> A:
  x
`);
    const given = process.env.BEND_INNER_LIBRARY_COMPILER;
    // The ordinary-lane default locates stage 0 by file, never by the
    // caller's cwd (the emitted program may run from anywhere); the gate
    // supplies the compiler under test explicitly.
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
    const err = "bend: a Nat past the largest immediate 2^48-1";
    try {
      if (lib.id(5) !== 5) return 2;
      if (lib.id(-1) !== -1) return 3;
      if (lib.id(0.5) !== 0.5) return 4;
      if (lib.id("z") !== "z") return 5;
    } catch (e) {
      return e === err ? 6 : 7;
    }
    return 0;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Generic.host_export), generic_host_export);
