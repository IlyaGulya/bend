#!/usr/bin/env bun
// Compare a candidate compiler with the current stage-0 compiler on runnable
// Bend tests. Compare behavior, not generated source text: the latter is not a
// stable contract.
//
// Every fixture is compiled by both stages for each target lane its foreign
// imports select (a `.c` import means the native lane, a `.js` import the JS
// lane, no foreign imports both), the emitted JS/native program is executed,
// and the observed exit/stdout/stderr must agree with the other stage and
// with the fixture's `#|` lines. The interpreter output is the reference for
// fixtures that have no per-lane diagnostics.
//
// A `#|!c <token>` or `#|!js <token>` line marks that lane as a diagnostic
// lane: the compile MUST fail with an Error naming <token>. This is how a
// missing foreign target is pinned to a real diagnostic instead of an
// undefined-symbol success. Targets are selected by the declared import
// extension, so each fixture also pins C/JS target selection.

import * as child from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const ROOT = path.resolve(import.meta.dir, "..");
const BUN = process.execPath;

type Lane = "js" | "native";
const LANES: Lane[] = ["js", "native"];
const TARGET_BY_LANE: Record<Lane, "c" | "js"> = { js: "js", native: "c" };
type Command = { bin: string; args: string[] };
type Stage = { name: string; command: Command };
type Result = { code: number; out: string; err: string };
type Diagnostic = { lane: Lane; token: string };
type Fixture = {
  file: string;
  want: string;
  lanes: Lane[];
  diagnostics: Diagnostic[];
};

function fail(message: string): never {
  console.error("selfhost: " + message);
  process.exit(1);
}

function run(bin: string, args: string[], cwd: string,
  env: Record<string, string> = {}): Result {
  const got = child.spawnSync(bin, args, {
    cwd,
    encoding: "utf8",
    maxBuffer: 1 << 28,
    // The stage-0 CLI performs a daily release check whose notice lands on
    // stderr once per host/day; it is not program behavior and would make
    // the comparison depend on the calendar. BEND_NO_TELEMETRY is the
    // documented switch that skips it.
    env: { ...process.env, BEND_NO_TELEMETRY: "1", ...env },
  });
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

// Fixture lines: `#|` is expected output; `#|!c`/`#|!js` is a required
// per-lane compile diagnostic naming the given token.
function fixture_read(file: string): Fixture {
  const source = fs.readFileSync(file, "utf8");
  const want: string[] = [];
  const diagnostics: Diagnostic[] = [];
  for (const line of source.split("\n")) {
    if (line.startsWith("#|!")) {
      const space = line.indexOf(" ");
      const lane = line.slice(3, space);
      if (space < 0 || (lane !== "c" && lane !== "js")) {
        fail(file + ": expected `#|!c <token>` or `#|!js <token>`, got: " + line);
      }
      const token = line.slice(space + 1).trim();
      if (token === "") fail(file + ": diagnostic marker names no token: " + line);
      diagnostics.push({ lane: lane === "js" ? "js" : "native", token });
    } else if (line.startsWith("#|")) {
      want.push(line.slice(2));
    }
  }
  if (new Set(diagnostics.map((d) => d.lane)).size !== diagnostics.length) {
    fail(file + ": duplicate diagnostic lane");
  }
  const declared = new Set<string>();
  for (const found of source.matchAll(/^\s*import\s+"\.\/[^"]+\.(c|js)"\s*$/gm)) {
    declared.add(found[1]);
  }
  const lanes: Lane[] = declared.size === 0
    ? ["js", "native"]
    : LANES.filter((lane) => declared.has(TARGET_BY_LANE[lane]));
  if (lanes.length === 0) fail(file + ": foreign imports select no target lane");
  for (const diagnostic of diagnostics) {
    if (!lanes.includes(diagnostic.lane)) {
      fail(file + ": #|!" + TARGET_BY_LANE[diagnostic.lane]
        + " names a lane its imports do not select");
    }
  }
  return { file, want: want.join("\n").trim(), lanes, diagnostics };
}

// The default suite covers the consumer-visible lowering boundaries the
// original five cases left open. Fixtures are real programs run by
// tests/gate conventions; add a new one only for a boundary no existing
// fixture exercises.
function default_files(): string[] {
  return [
    // The original cases: word semantics, bang/partial application, template
    // specialization, constructor matching, IO.
    "tests/run/word_arithmetic.bend",
    "tests/run/bang_call.bend",
    "tests/run/template_call.bend",
    "tests/run/selfhost_adt_match.bend",
    "tests/run/selfhost_io.bend",
    // Closure conversion: captured bindings, tail closures, per-iteration
    // captures, affine ownership of a captured value.
    "tests/run/closures_hof.bend",
    "tests/run/js_tail_closure.bend",
    "tests/run/js_loop_capture.bend",
    "tests/run/fn_capture_owns.bend",
    // Direct/partial/over-application and erased parameters.
    "tests/compile/over_application.bend",
    "tests/compile/closure_dynamic_apply.bend",
    "tests/compile/erased_apply.bend",
    "tests/compile/erased_partial_closure.bend",
    // Scalar and custom constructors, layout/projection, dependent family.
    "tests/run/nat_native.bend",
    "tests/run/ctr_dotted_field.bend",
    "tests/run/wide_record.bend",
    "tests/run/nested_tuples_records.bend",
    "tests/run/computed_match.bend",
    "tests/run/family_arg_hot.bend",
    "tests/run/list_rebox_sum.bend",
    // Reflection: canonical type descriptors display a dependent/erased value.
    "tests/run/descriptor_show.bend",
    // A failed nested pattern row falls through to the later rows.
    "tests/run/word_match_coverage.bend",
    "tests/run/state_machine.bend",
    // Lexical CID/FID linking: whole ids, comment/literal passthrough, LF+CRLF.
    "tests/run/c_backend_link.bend",
    // Current foreign ABI: native callback into a Bend closure, own-type
    // layout, shared sealed values, nullary constructors, and one shared .js
    // module whose stateful nullary effect is called twice and then read by a
    // second nullary def (real observation: 1,2,2).
    "tests/io/foreign_runtime_apply.bend",
    "tests/io/foreign_types.bend",
    "tests/io/foreign_shared.bend",
    "tests/io/marshal_imported_nullary.bend",
    "tests/io/shared_module_state.bend",
    // Host Nat at the export seam: the four fixtures whose effect builds an
    // inner library with the compiler under test (see HOST_EXPORT_FIXTURES).
    "tests/io/nat_host_export.bend",
    "tests/io/nat_alias_export.bend",
    "tests/io/shadowed_nat_export.bend",
    "tests/io/generic_export_identity.bend",
    // IO read failure and read-back through the real File surface.
    "tests/io/file_roundtrip.bend",
    // C target representation: scalars, wide/nested arrays, multi-arm tags,
    // dropped affine fields, string codepoints, and the storage witness.
    "evals/c_target_wide_record.bend",
    "evals/c_target_nested_adt.bend",
    "evals/c_target_array_u32.bend",
    "evals/c_target_array_wide.bend",
    "evals/c_target_array_nat.bend",
    "evals/c_target_array_nested.bend",
    "evals/c_target_multiarm.bend",
    "evals/c_target_drop_fields.bend",
    "evals/c_target_char_head.bend",
    "evals/c_target_char_to_list.bend",
    "evals/c_target_string_from_list.bend",
    "tests/reg/phys_storage_paths.bend",
    // Target selection: an absent C target must fail only the native lane, an
    // absent JS target only the JS lane, each with a real diagnostic.
    "gates/selfhost_cases/missing_c_target.bend",
    "gates/selfhost_cases/missing_js_target.bend",
  ].map((file) => path.join(ROOT, file));
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
  if (files.length === 0) files.push(...default_files());
  return { stage0, stage1, files };
}

function compile(stage: Stage, file: string, out: string, cwd: string): Result {
  const stage1Args = stage.name === "stage 1"
    ? ["--base", path.join(ROOT, "bend2/base.bend"),
      "--runtime-c", path.join(ROOT, "bend2/selfhost/c_runtime.c")]
    : [];
  return run(stage.command.bin,
    [...stage.command.args, file, "-o", out, ...stage1Args], cwd);
}

function compile_ok(stage: Stage, file: string, out: string, cwd: string): void {
  const got = compile(stage, file, out, cwd);
  if (got.code !== 0) {
    fail(stage.name + " failed compiling " + file + "\n" + got.out + got.err);
  }
}

// A missing foreign target is a compile-time diagnostic, never undefined
// success: the compile must fail and its output must name the missing target.
// The diagnostic wording itself is not a contract.
function compile_diagnostic(stage: Stage, file: string, token: string,
  got: Result): void {
  const text = got.out + got.err;
  if (got.code === 0) {
    fail(stage.name + " compiled " + file + " successfully although target "
      + token + " is absent; a missing target import must be a real diagnostic\n"
      + text);
  }
  if (!text.includes(token)) {
    fail(stage.name + " diagnostic for " + file + " does not name " + token + "\n"
      + text);
  }
}

function build_c(source: string, out: string, cwd: string): void {
  const cc = process.env.CC ?? "clang";
  const got = run(cc, ["-O2", "-pthread", source, "-lm", "-o", out], cwd);
  if (got.code !== 0) {
    fail(cc + " failed building " + source + "\n" + got.out + got.err);
  }
}

// These fixtures build an inner library from inside their effect. The inner
// library must be built by the compiler under test, not by a fixed path, so
// the gate supplies the exact command. Stage 0 is named explicitly for the
// official lane; the candidate lane names its library runner and has no
// fallback (the candidate image is a typed-step library, not a process).
const HOST_EXPORT_FIXTURES = new Set([
  "nat_host_export.bend",
  "nat_alias_export.bend",
  "shadowed_nat_export.bend",
  "generic_export_identity.bend",
]);

// The inner build takes the same command shape as the outer compile: the
// stage executable, its fixed arguments, then `<input> -o <output>`. Stage 1 is
// therefore whatever process drives the candidate image (for the JS target,
// `bun evals/candidate_host.ts --candidate=<component>`), never the image
// alone, and its library entry is selected by the `.mjs` output path.
function inner_compiler(stage: Stage): string[] {
  if (stage.command.bin === "") {
    fail("host-export fixture needs the stage " + (stage.name === "stage 0" ? 0 : 1) + " compiler");
  }
  return [stage.command.bin, ...stage.command.args];
}

function host_export_env(stage: Stage): Record<string, string> {
  return { BEND_INNER_LIBRARY_COMPILER: JSON.stringify(inner_compiler(stage)) };
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
      const fixture = fixture_read(file);
      const label = path.relative(ROOT, fixture.file);
      const cwd = path.dirname(fixture.file);
      // A diagnostic lane has no runnable program in that lane, so the
      // interpreter cannot be the reference; both compilers must report the
      // same missing target instead.
      let reference: Result | null = null;
      const hostExport = HOST_EXPORT_FIXTURES.has(path.basename(fixture.file));
      if (fixture.diagnostics.length === 0) {
        reference = run(config.stage0.bin,
          [...config.stage0.args, fixture.file], cwd,
          hostExport ? host_export_env(stages[0]) : {});
        if (reference.code !== 0 || reference.out.trim() !== fixture.want) {
          fail(label + " stage 0 interpreter output differs from #| expectation\n"
            + reference.out + reference.err);
        }
      }

      for (const lane of fixture.lanes) {
        const suffix = TARGET_BY_LANE[lane];
        const outputs = stages.map((_, i) => path.join(tmp,
          String(i) + "-" + path.basename(fixture.file) + "." + suffix));
        const diagnostic = fixture.diagnostics.find((d) => d.lane === lane);
        if (diagnostic !== undefined) {
          stages.forEach((stage, i) => {
            compile_diagnostic(stage, fixture.file, diagnostic.token,
              compile(stage, fixture.file, outputs[i], cwd));
          });
          console.log("PASS " + label + " " + lane + " (diagnostic " + diagnostic.token + ")");
          continue;
        }

        stages.forEach((stage, i) =>
          compile_ok(stage, fixture.file, outputs[i], cwd));
        const executables = lane === "native"
          ? outputs.map((source, i) => {
            const executable = path.join(tmp,
              String(i) + "-" + path.basename(fixture.file) + ".bin");
            build_c(source, executable, tmp);
            return executable;
          })
          : outputs;
        const runs = executables.map((out, i) => lane === "js"
          ? run(BUN, [out], tmp, hostExport ? host_export_env(stages[i]) : {})
          : run(out, [], tmp));
        same(label + " " + lane, runs[0], runs[1]);
        if (reference !== null) same(label + " stage 0 " + lane, reference, runs[0]);
        for (const got of runs) {
          if (got.code !== 0 || got.out.trim() !== fixture.want) {
            fail(label + " " + lane + " output differs from #| expectation\n"
              + got.out + got.err);
          }
        }
        console.log("PASS " + label + " " + lane);
      }
    }
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

main();
