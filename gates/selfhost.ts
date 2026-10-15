#!/usr/bin/env bun
// Compare a candidate compiler with the current stage-0 compiler on runnable
// Bend tests. Compare behavior, not generated source text: the latter is not a
// stable contract.

import * as child from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const ROOT = path.resolve(import.meta.dir, "..");
const BUN = process.execPath;

type Command = { bin: string; args: string[] };
type Stage = { name: string; command: Command };
type Result = { code: number; out: string; err: string };

function fail(message: string): never {
  console.error("selfhost: " + message);
  process.exit(1);
}

function run(bin: string, args: string[], cwd: string): Result {
  const got = child.spawnSync(bin, args, { cwd, encoding: "utf8", maxBuffer: 1 << 28 });
  if (got.error !== undefined) {
    return { code: 127, out: got.stdout ?? "", err: String(got.error) };
  }
  return { code: got.status ?? 1, out: got.stdout, err: got.stderr };
}

function same(label: string, a: Result, b: Result): void {
  if (a.code !== b.code || a.out !== b.out || a.err !== b.err) {
    fail(label + " differs\n--- stage 0 (exit " + a.code + ") ---\n"
      + a.out + a.err + "\n--- stage 1 (exit " + b.code + ") ---\n"
      + b.out + b.err);
  }
}

function expected(file: string): string {
  return fs.readFileSync(file, "utf8").split("\n")
    .filter((line) => line.startsWith("#|"))
    .map((line) => line.slice(2)).join("\n").trim();
}

function args_parse(): { stage0: Command; stage1: Command; files: string[] } {
  const args = process.argv.slice(2);
  const stage0: Command = { bin: BUN, args: [path.join(ROOT, "bend2/main.ts")] };
  const stage1: Command = { bin: "", args: [] };
  const files: string[] = [];
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === "--stage0" || arg === "--stage1") {
      const bin = args[++i];
      if (bin === undefined) fail(arg + " needs an executable");
      (arg === "--stage0" ? stage0 : stage1).bin = bin;
    } else if (arg === "--stage0-arg" || arg === "--stage1-arg") {
      const value = args[++i];
      if (value === undefined) fail(arg + " needs a value");
      (arg === "--stage0-arg" ? stage0 : stage1).args.push(value);
    } else if (arg.startsWith("-")) {
      fail("unknown option " + arg);
    } else {
      files.push(path.resolve(arg));
    }
  }
  if (stage1.bin === "") {
    fail("usage: bun gates/selfhost.ts --stage1 <compiler> [--stage1-arg <arg>] <test.bend>...");
  }
  if (files.length === 0) {
    files.push(
      path.join(ROOT, "tests/run/word_arithmetic.bend"),
      path.join(ROOT, "tests/run/bang_call.bend"),
      path.join(ROOT, "tests/run/template_call.bend"),
      path.join(ROOT, "tests/run/selfhost_adt_match.bend"),
      path.join(ROOT, "tests/run/selfhost_io.bend"),
    );
  }
  return { stage0, stage1, files };
}

function compile(stage: Stage, file: string, out: string, cwd: string): void {
  const stage1Args = stage.name === "stage 1"
    ? ["--base", path.join(ROOT, "bend2/base.bend"),
      "--runtime-c", path.join(ROOT, "bend2/selfhost/c_runtime.c")]
    : [];
  const got = run(stage.command.bin,
    [...stage.command.args, file, "-o", out, ...stage1Args], cwd);
  if (got.code !== 0) {
    fail(stage.name + " failed compiling " + file + "\n" + got.out + got.err);
  }
}

function build_c(source: string, out: string, cwd: string): void {
  const cc = process.env.CC ?? "clang";
  const got = run(cc, ["-O2", "-pthread", source, "-lm", "-o", out], cwd);
  if (got.code !== 0) {
    fail(cc + " failed building " + source + "\n" + got.out + got.err);
  }
}

function main(): void {
  const config = args_parse();
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "bend-selfhost-"));
  const stages: Stage[] = [
    { name: "stage 0", command: config.stage0 },
    { name: "stage 1", command: config.stage1 },
  ];
  try {
    for (const file of config.files) {
      const want = expected(file);
      const reference = run(config.stage0.bin,
        [...config.stage0.args, file], path.dirname(file));
      if (reference.code !== 0 || reference.out.trim() !== want) {
        fail(file + " stage 0 interpreter output differs from #| expectation\n"
          + reference.out + reference.err);
      }

      for (const kind of ["js", "native"] as const) {
        const outputs = stages.map((_, i) => path.join(tmp,
          String(i) + "-" + path.basename(file)
            + (kind === "js" ? ".js" : ".c")));
        stages.forEach((stage, i) =>
          compile(stage, file, outputs[i], path.dirname(file)));
        const executables = kind === "native"
          ? outputs.map((source, i) => {
            const executable = path.join(tmp,
              String(i) + "-" + path.basename(file) + ".bin");
            build_c(source, executable, tmp);
            return executable;
          })
          : outputs;
        const runs = executables.map((out) => kind === "js"
          ? run(BUN, [out], tmp) : run(out, [], tmp));
        same(file + " " + kind, runs[0], runs[1]);
        same(file + " stage 0 " + kind, reference, runs[0]);
        if (runs[0].code !== 0 || runs[0].out.trim() !== want) {
          fail(file + " " + kind + " output differs from #| expectation\n"
            + runs[0].out + runs[0].err);
        }
      }
      console.log("PASS " + path.relative(ROOT, file));
    }
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

main();
