#!/usr/bin/env bun
/**
 * Regenerate bend2/selfhost/c_runtime.c from the host compiler's C runtime.
 *
 *   bun evals/gen_c_runtime.ts          # write the runtime snapshot
 *   bun evals/gen_c_runtime.ts --check  # verify the checked-in snapshot
 *
 * The snapshot is runtime_c("", "", "", "") from bend2/comp.ts: the four
 * generated slots (tables, spins, segments, requests) stay empty, and the
 * self-host C backend fills the same `// Tables`, `// Spins`, `// Segments`,
 * `// Requests` markers. Hand-written CID(...)/FID(...) names are mapped to the
 * symbolic macros the tables define (CID_FOO / FID_FOO); no numeric ids and no
 * old-ABI compatibility are introduced. comp.ts and bend.ts are never modified.
 */
import {createHash} from "node:crypto";
import {readFileSync, rmSync, writeFileSync} from "node:fs";
import {dirname, join, resolve} from "node:path";
import {officialKernelSha256} from "./release_identity.ts";

const ROOT = resolve(import.meta.dir, "..");
const COMP = join(ROOT, "bend2/comp.ts");
const KERNEL = join(ROOT, "bend2/bend.ts");
const TARGET = join(ROOT, "bend2/selfhost/c_runtime.c");
const FIXTURE = join(ROOT, "evals/c_backend_runtime.bend");

// Pinned authority. A mismatch means the runtime source changed: review the
// ABI and update these pins deliberately, never silently.
// COMP_SHA is the reviewed v2.0.39 merge of bend2/comp.ts (JSOptions js_lib,
// v39 JS Char encoding, four runtime slots). The merged runtime_c was audited
// on that exact file: no raw CID()/FID() call survives symbolicIds, the four
// Tables/Spins/Segments/Requests markers exist, io_eff/io_node keep their
// 2-arg/4-arg ABI, SIGSEGV/SIGBUS trapping and --RTS parsing are present, and
// C Chars stay native u32 words (the packed JS encoding is JS-only).
// The producer's layout/lifetime/literal/naming/publication/usage changes leave RuntimeC
// byte-identical to checkpoint 02e011d7 (previous source pin132ce4c7);
// re-pinning the complete source does not substitute a different runtime ABI.
// KERNEL_SHA always names the current official release, so a stale working
// kernel fails closed.
const COMP_SHA = "1034505b49c7cd80ff415be14e581f4cd5bfcd4e622006329d358bd3995594cb";
const KERNEL_SHA = officialKernelSha256(ROOT);

const sha = (bytes: string | Buffer): string =>
  createHash("sha256").update(bytes).digest("hex");

function pin(path: string, expected: string): void {
  const got = sha(readFileSync(path));
  if (got !== expected) {
    throw new Error(`${path} sha ${got} != pinned ${expected}; review the C ABI before updating the pin`);
  }
}

// Hand-written C and JS name ids as CID(k)/FID(k): k in the source's
// namespace, else as is. Mirrors comp.ts c_ids' lexical exclusion so comments
// and string literals are never rewritten.
function symbolicIds(src: string): string {
  const macro = (pre: string, key: string): string =>
    pre + "_" + key.replace(/[^A-Za-z0-9_]/g, "_").toUpperCase();
  return src.replace(
    /\/\/(?:\\\n|.)*|\/\*[^]*?\*\/|"(?:\\[^]|[^"\\\n])*"|'(?:\\[^]|[^'\\\n])*'|`(?:\\[^]|[^`\\])*`|\b([CF]ID)\(([\w./~-]+)\)/g,
    (text, pre, key) => pre ? macro(pre, key) : text);
}

async function generate(): Promise<string> {
  pin(KERNEL, KERNEL_SHA);
  pin(COMP, COMP_SHA);
  // Importing comp.ts directly cannot reach its private runtime_c, and editing
  // it is forbidden. Evaluate an appended-export copy beside it so relative
  // imports resolve; the copy is removed even on failure.
  const copy = join(ROOT, "bend2", `.gen_c_runtime_${process.pid}_${Date.now()}.ts`);
  const source = readFileSync(COMP, "utf8")
    + "\nexport {runtime_c};\n";
  writeFileSync(copy, source, {flag: "wx"});
  try {
    // The specifier is genuinely runtime-selected: it is a temporary
    // appended-export copy of comp.ts, which cannot be imported statically
    // without editing the pinned source.
    const mod = await import(copy + "?v=" + process.pid) as {
      runtime_c: (tabs: string, spins: string, segs: string, reqs: string) => string;
    };
    if (typeof mod.runtime_c !== "function") {
      throw new Error("comp.ts does not export runtime_c");
    }
    const slots = ["Tables", "Spins", "Segments", "Requests"];
    const tags = slots.map(name => `/*__BEND_RUNTIME_${name}_SLOT__*/`);
    let raw = mod.runtime_c(tags[0]!, tags[1]!, tags[2]!, tags[3]!);
    // Authored section headings can precede declarations needed by a slot.
    // Only runtime_c's actual argument positions are insertion authority.
    raw = raw.replace(/^\/\/ (Tables|Spins|Segments|Requests)$/gm, "// Runtime $1");
    for (let i = 0; i < slots.length; i += 1) {
      const tag = tags[i]!, at = raw.indexOf(tag);
      if (at < 0 || raw.indexOf(tag, at + tag.length) >= 0) {
        throw new Error("runtime template must contain exactly one " + slots[i] + " slot");
      }
      raw = raw.replace(tag, `// ${slots[i]}\n// ========\n`);
    }
    const runtime = symbolicIds(raw);
    const leftover = symbolicIds(runtime) !== runtime;
    if (leftover || /\b[CF]ID\(/.test(runtime.replace(
      /\/\/(?:\\\n|.)*|\/\*[^]*?\*\/|"(?:\\[^]|[^"\\\n])*"|'(?:\\[^]|[^'\\\n])*'|`(?:\\[^]|[^`\\])*`/g, ""))) {
      throw new Error("runtime still contains a direct CID()/FID() call after mapping");
    }
    for (const marker of ["// Tables", "// Spins", "// Segments", "// Requests"]) {
      if (!runtime.includes(marker)) {
        throw new Error("runtime template lacks marker " + marker);
      }
    }
    if (!runtime.includes("static void io_eff(u32 cid, Effect run)")
      || !runtime.includes("static Term io_node(Env e, u64 cid, Term a, Term b)")) {
      throw new Error("runtime does not expose the current 2-arg io_eff / 4-arg io_node ABI");
    }
    const header = [
      "// Generated by evals/gen_c_runtime.ts from bend2/comp.ts runtime_c.",
      `// comp.ts ${COMP_SHA}`,
      `// bend.ts ${KERNEL_SHA}`,
      "// Do not hand-edit: regenerate. The four generated slots stay empty for",
      "// the self-host C backend to fill at the Tables/Spins/Segments/Requests markers.",
      "",
    ].join("\n");
    return header + runtime;
  } finally {
    rmSync(copy, {force: true});
  }
}

const runtime = await generate();
const fixture = [
  "# Generated by evals/gen_c_runtime.ts; the raw BIR smoke uses this runtime.",
  "# No compiler logic is duplicated here. Regenerate together with c_runtime.c.",
  "import Base",
  "",
  "def runtime_source() -> String:",
  "  String.concat([",
  runtime.split(/(?<=\n)/).filter(Boolean).map(line => "    " + JSON.stringify(line)).join(",\n"),
  "  ])",
  "",
].join("\n");
for (const [path, source] of [[TARGET, runtime], [FIXTURE, fixture]]) {
  const output = sha(source);
  if (process.argv.includes("--check")) {
    const existing = readFileSync(path);
    if (sha(existing) !== output) {
      throw new Error(`${path} is stale: expected sha ${output}, found ${sha(existing)}; run bun evals/gen_c_runtime.ts`);
    }
    console.log(path + " current: sha256 " + output + ", " + Buffer.byteLength(source) + " bytes");
  } else {
    writeFileSync(path, source);
    console.log("wrote " + path + ": sha256 " + output + ", " + Buffer.byteLength(source) + " bytes");
  }
}
