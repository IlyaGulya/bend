function nat_host_export() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-nat-export-"));
  try {
    const input = path.join(dir, "lib.bend");
    const output = path.join(dir, "lib.mjs");
    fs.writeFileSync(input, `import Base

def identity(n: Nat) -> Nat:
  n

def inc(n: Nat) -> Nat:
  Nat.add(n, 1n)

def add(a: Nat, b: Nat) -> Nat:
  Nat.add(a, b)
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
    const bad = [() => lib.inc(-1), () => lib.inc(1.5), () => lib.inc(1n),
      () => lib.inc(2 ** 53 + 2), () => lib.add(1)(-1),
      () => lib.identity(Infinity), () => lib.identity(NaN)];
    if (bad.some((f) => { try { f(); } catch { return false; }
      return true; })) {
      return 2;
    }
    return lib.inc(41) === 42 && lib.add(2)(3) === 5
      && [0, 2 ** 48, 2 ** 53].every((n) => lib.identity(n) === n) ? 0 : 3;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Nat.host_export), nat_host_export);
