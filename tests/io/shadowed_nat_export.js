// A module's own Nat is a user ADT, not the host Nat. Its genuine constructor
// value must cross the export boundary unchanged and still match.
function shadow_nat_host_export() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-shadow-nat-"));
  try {
    fs.writeFileSync(path.join(dir, "shadow_nat_type.bend"), `type Shadow.Nat is Data:
  ShadowOff{}
  ShadowOn{pred: Shadow.Nat}
`);
    const input = path.join(dir, "lib.bend");
    const output = path.join(dir, "lib.mjs");
    fs.writeFileSync(input, `import Base
import ./shadow_nat_type.bend as S

def tag(x: S.Shadow.Nat) -> U32:
  match x:
    case S.ShadowOff{}:
      0
    case S.ShadowOn{p}:
      1

def off() -> S.Shadow.Nat:
  S.ShadowOff{}

def on() -> S.Shadow.Nat:
  S.ShadowOn{S.ShadowOff{}}
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
    try {
      // The canonical key ends in Nat, but its BIR native is None.
      // Library-produced values avoid depending on backend constructor tags.
      return lib.tag(lib.off()) === 0 && lib.tag(lib.on()) === 1 ? 0 : 3;
    } catch {
      return 6;
    }
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(ShadowNat.host_export), shadow_nat_host_export);
