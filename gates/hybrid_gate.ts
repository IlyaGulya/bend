#!/usr/bin/env bun
// HYBRID only: host parses target; selfhost checker/JS emitter produce its JS.
// This gate never exercises C/native/GPU and must not be called SELFHOST GREEN.
import * as child from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { compile_hybrid } from "./hybrid.ts";

const ROOT = path.resolve(import.meta.dir, "..");
const DEFAULTS = [
  "bend2/selfhost/architecture_probe_affine_nat.bend",
  "tests/run/word_arithmetic.bend",
];

type Result = { code: number; out: string; err: string };
function run(args: string[], cwd: string): Result {
  const got = child.spawnSync(process.execPath, args, { cwd, encoding: "utf8", maxBuffer: 1 << 27,
    env: { ...process.env, BEND_NO_TELEMETRY: "1" } });
  if (got.error) throw got.error;
  return { code: got.status ?? 1, out: got.stdout, err: got.stderr };
}

async function main(): Promise<void> {
  const files = process.argv.slice(2).length ? process.argv.slice(2) : DEFAULTS;
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "bend-hybrid-gate-"));
  try {
    for (const filename of files) {
      const file = fs.realpathSync(filename);
      const cwd = path.dirname(file);
      const expected = fs.readFileSync(file, "utf8").split("\n")
        .filter(line => line.startsWith("#|"))
        .map(line => line.slice(2)).join("\n").trim();
      const reference = run([path.join(ROOT, "bend2/main.ts"), file], cwd);
      if (reference.code !== 0 || reference.out.trim() !== expected) {
        throw Error(`stage-0 interpreter failed fixture ${filename}\n${reference.out}${reference.err}`);
      }
      const out = path.join(tmp, `${files.indexOf(filename)}.js`);
      await compile_hybrid(file, out);
      const hybrid = run([out], cwd);
      if (hybrid.code !== reference.code || hybrid.out !== reference.out || hybrid.err !== reference.err) {
        throw Error(`HYBRID JS runtime differs for ${filename}\n` +
          `stage-0 (${reference.code}): ${reference.out}${reference.err}\n` +
          `hybrid (${hybrid.code}): ${hybrid.out}${hybrid.err}`);
      }
      console.log("HYBRID PASS " + path.relative(ROOT, file));
    }
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

try { await main(); }
catch (error) { console.error("HYBRID FAILED: " + String(error)); process.exitCode = 1; }
