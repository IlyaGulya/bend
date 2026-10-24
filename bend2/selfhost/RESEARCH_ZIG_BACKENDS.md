# Zig's self-hosted backends: what actually changed, and what Bend can reuse

**Status:** research note only. No implementation, no new IR, no dependency, no
backend cutover, no benchmark run, no build. This note does not propose a
committed backend architecture and does not treat a native backend as accepted.

**Repository baseline:** `f46ad0f6d363753229c52350eaec1474875c6623`
(`work/fir-ir-integrated57ab`), own branch `work/zig-backend-research`, worktree
`/private/tmp/bend-zig-research`.

**Sources read on 2026-10-24:** Zig release notes 0.11.0–0.17.0, Zig devlog
2025, the 2026-07-28 incremental-compilation post by a Zig core-team member,
and the actual `ziglang/zig` source at tag `0.17.0`
(`7647adab80d…`, 2026-10-01), plus tags `0.15.1` and `0.16.0` where the
default-selection code changed. Upstream moved from GitHub to Codeberg; tags
`0.16.0`/`0.17.0` exist there. Every external claim is linked; every local
claim names the file and symbol at the baseline above.

Labels used below:

* **[S]** — stated by a primary source I opened (release notes, devlog,
  upstream source, or this repository at `f46ad0f6`).
* **[P]** — project-reported state supplied with this task; no receipt was
  reproduced in this slice.
* **[I]** — my inference from **[S]**/**[P]** facts. Not measured, not accepted.

Nothing here is a benchmark measurement. Where upstream reports timings, the
workload, mode and stated hardware limits are repeated exactly; no Bend speedup
is extrapolated from them.

---

## 0. The short answer

1. **Zig did not remove LLVM.** It added a second code-generation path. As of
   Zig 0.17.0 (2026-10-01), the self-hosted x86_64 backend is the default only
   in **Debug** builds, and only for **x86_64 ELF targets that pass a
   robustness gate**; release builds explicitly prefer LLVM
   (`src/Compilation/Config.zig:316-369`). The distributed compiler still links
   LLVM; source builds can disable the LLVM backend (`-Denable-llvm=false`) and
   `-fno-libllvm` avoids the library API, but then the LLVM backend can only
   emit bitcode/IR, and `zig cc` is still Clang. The roadmap goal is “a process
   dependency on Clang”, not deletion
   ([0.17.0 roadmap](https://ziglang.org/download/0.17.0/release-notes.html#Roadmap)).
2. **Two transitions are routinely conflated.** The *frontend/bootstrap*
   transition finished in 0.11.0 (C++ implementation deleted; compiler written
   in Zig, still using LLVM for codegen)
   ([0.11.0 Bootstrapping](https://ziglang.org/download/0.11.0/release-notes.html#Bootstrapping)).
   The *backend replacement* transition is still in progress: 0.14 brought the
   x86 backend to 98% of behavior tests and recommended `-fno-llvm`; 0.15 made
   it the Debug default on x86_64 with OS exceptions; 0.17 narrowed that default
   again on x86_64-macOS because the self-hosted output is not robust there.
3. **The reusable part is the pipeline, not the instruction encoder.** Zig's
   gains come from per-function ownership, bounded in-flight work, a
   per-architecture MIR, typed relocations patched by a tightly integrated
   linker, and a semantic dependency graph. Writing an opcode emitter would
   reproduce the least reusable part.
4. **On Bend's Apple arm64 host, Zig still uses LLVM by default.** The
   aarch64 self-hosted backend is “in development”; 0.17 says progress is
   blocked on linker work
   ([0.17.0 aarch64](https://ziglang.org/download/0.17.0/release-notes.html#aarch64-Backend)).
   Zig is not a precedent for “Apple-arm64 native without LLVM”.
5. **Bend's current producer OOM is upstream of clang/LLVM.** The traced
   official-TS `compile_book` run hit pass 6 at the 3072 MiB guard **[P]**;
   `compile_book` is a whole-program fixed point that clears its tables and
   re-emits every definition on every pass
   (`bend2/comp.ts:3110-3155`). Removing or replacing LLVM cannot fix that
   loop. The new self-hosted C lane also materializes whole-program `String`
   values after lowering (`bend2/selfhost/c_backend.bend:3173-3209`), but that
   is downstream of the official producer and is a separate, measurable cost.
6. **Reuse now:** phase instrumentation and bounded measurement; removal of
   redundant whole-output materializations and the whole-source `CID/FID`
   rewrite for Bend-generated code; a fast development C tier alongside the
   `-O3` release tier. Per-`BIR.Code` boundaries are a later step: the catalog and descriptor
   normalizer are whole-program, so a dependency split must come first.
   **Future work:** a definition-level dependency graph and cache keys, stable
   IDs across edits, compiler-side release/ownership, and a separate-compilation
   ABI. **Do not transfer:** Zig's lazy analysis as a way to check fewer Bend
   roots/exports, Zig's acyclic-dependency assumption, or a native backend as a
   presumed fix.

---

## 1. Timeline: frontend vs backend

| Date / release | Frontend and bootstrap | Code generation | LLVM status | Incremental |
|---|---|---|---|---|
| 2023-08-03, **0.11.0** | C++ implementation deleted; `-fstage1` removed; bootstrap is a 2.4 MiB WebAssembly file plus a C compiler; compiler is “100% Zig code, except for LLVM libraries” **[S]** ([notes](https://ziglang.org/download/0.11.0/release-notes.html#Bootstrapping)) | LLVM is still the machine-code path | LLVM libraries still required | Not yet |
| 2025-03-04, **0.14.0** | Self-hosted frontend already shipping | Self-hosted x86 backend passes 1884/1923 (98%) behavior tests vs LLVM, but is **not default**; opt in with `-fno-llvm` or `use_llvm = false` **[S]** ([x86](https://ziglang.org/download/0.14.0/release-notes.html#x86-Backend)) | LLVM is default; “LLVM Builder API” work is described as effort toward eliminating the LLVM dependency **[S]** ([builder](https://ziglang.org/download/0.14.0/release-notes.html#LLVM-Builder-API)) | `-fincremental`, opt-in, best with `-fno-emit-bin` **[S]** ([incremental](https://ziglang.org/download/0.14.0/release-notes.html#Incremental-Compilation)) |
| 2025-06-08, master before 0.15 | — | x86_64 backend default **in Debug** when targeting x86_64; Windows not yet because COFF linker work remains **[S]** ([devlog](https://ziglang.org/devlog/2025/#2025-06-08)) | `-fllvm` still available | Still opt-in |
| 2025-08-19, **0.15.1** | — | x86_64 backend default in Debug **except NetBSD, OpenBSD, Windows**; “around a 5x decrease compared to LLVM in most cases”; “known to emit slower machine code” **[S]** ([x86](https://ziglang.org/download/0.15.1/release-notes.html#x86-Backend)) | LLVM remains for release, exceptions, and fallback | Still experimental; `--watch -fincremental` with `-fno-emit-bin` **[S]** ([incremental](https://ziglang.org/download/0.15.1/release-notes.html#Incremental-Compilation)) |
| 2026-04-13, **0.16.0** | Type resolution reworked; dependency graph made acyclic except genuine loops **[S]** ([type resolution](https://ziglang.org/download/0.16.0/release-notes.html#Reworked-Type-Resolution)) | x86 backend remains Debug default; “more behavior tests, significantly faster compilation, superior debug information, inferior machine code quality” **[S]** ([x86](https://ziglang.org/download/0.16.0/release-notes.html#x86-Backend)); aarch64 progress paused and behavior tests crash **[S]** ([aarch64](https://ziglang.org/download/0.16.0/release-notes.html#aarch64-Backend)) | **LLVM backend gains incremental support** for bitcode building, but not for “LLVM Emit Object” **[S]** ([LLVM](https://ziglang.org/download/0.16.0/release-notes.html#LLVM-Backend), [incremental](https://ziglang.org/download/0.16.0/release-notes.html#Incremental-Compilation)) | Still opt-in; new ELF linker default only with a self-hosted backend on ELF |
| 2026-10-01, **0.17.0** | — | x86_64 Debug default still on x86_64 **ELF** targets; x86_64-macOS default is LLVM again because self-hosted Mach-O output is not robust ([source gate](https://codeberg.org/ziglang/zig/src/tag/0.17.0/src/target.zig#L311-L335); [issue 35267](https://codeberg.org/ziglang/zig/issues/35267)); aarch64 blocked on linker **[S]** ([aarch64](https://ziglang.org/download/0.17.0/release-notes.html#aarch64-Backend)) | LLVM still required in the distribution; release builds prefer it; roadmap is process dependency on Clang **[S]** ([roadmap](https://ziglang.org/download/0.17.0/release-notes.html#Roadmap)) | Incremental viable for most x86_64-linux projects with `-fincremental --watch` **[S]** ([incremental](https://ziglang.org/download/0.17.0/release-notes.html#Incremental-Compilation)) |

Two consequences:

* “Zig is self-hosted” has been true since 0.11 for the frontend and only
  partially true for codegen since 0.15.
* “Zig replaced LLVM” is false at every point in the table. The current
  direction is *optional* LLVM plus a process dependency on Clang
  ([0.15.1 aarch64](https://ziglang.org/download/0.15.1/release-notes.html#aarch64-Backend);
  [0.17.0 roadmap](https://ziglang.org/download/0.17.0/release-notes.html#Roadmap)).

---

## 2. Current status at Zig 0.17.0 (2026-10-01)

The default decision is code, not a slogan. In
`src/Compilation/Config.zig:316-369`:

* explicit `-fllvm` / `-fno-llvm` wins;
* `.ll` / `.bc` output and ThreadSanitizer force LLVM;
* a target LLVM cannot serve falls back to a self-hosted backend if one exists;
* a target Zig cannot serve falls back to LLVM;
* “If we cannot use LLVM libraries … our own backends will be a better
  default” because the LLVM backend cannot emit an object without libLLVM;
* **“Prefer LLVM for release builds. if (root_optimize_mode != .debug) break :b true;”**;
* Darwin dynamic libraries stay on LLVM;
* otherwise the self-hosted backend is used only if
  `target_util.selfHostedBackendIsAsRobustAsLlvm(target)`.

That gate is decisive (`src/target.zig:311-335`):

* x86_64 with 64-bit pointers and **ELF**, excluding BSDs and illumos;
* SPIR-V (special case);
* everything else → LLVM.

So the accurate matrix is:

| Target / object format | Build mode | Default codegen at 0.17.0 | Evidence |
|---|---|---|---|
| `x86_64-linux` (ELF) | Debug | self-hosted x86_64 | `Config.zig:316-369`, `target.zig:311-335` |
| `x86_64-{freebsd,netbsd,openbsd,dragonfly}` | Debug | LLVM (self-hosted linker/gate exclusion) | `target.zig:319-327` |
| `x86_64-illumos` | Debug | LLVM | `target.zig:315-318` |
| `x86_64-macos` (Mach-O) | Debug | **LLVM**; self-hosted backend is present and marked ⚡ in the support table, but the default gate excludes Mach-O | `target.zig:328-331`; [issue 35267](https://codeberg.org/ziglang/zig/issues/35267) |
| `x86_64-windows` (COFF) | Debug | LLVM; self-hosted marked “in development” | `target.zig:328-332`; [0.17 target table](https://ziglang.org/download/0.17.0/release-notes.html#Support-Table) |
| `aarch64-*` (including `aarch64-macos`) | any | LLVM; self-hosted in development | `target.zig:334`; [0.17 aarch64](https://ziglang.org/download/0.17.0/release-notes.html#aarch64-Backend) |
| `wasm32/64` | Debug | LLVM; self-hosted backend passes 100% of behavior tests in 0.17 but is not default because debug-info support is missing | [0.17 WebAssembly](https://ziglang.org/download/0.17.0/release-notes.html#WebAssembly-Backend) |
| `spirv32/64` | Debug | self-hosted SPIR-V backend exists and is multi-threaded in 0.17; the default gate special-cases SPIR-V. This is codegen, not a GPU runtime | `target.zig:313`; [0.17 SPIR-V](https://ziglang.org/download/0.17.0/release-notes.html#SPIR-V-Backend) |
| any target | ReleaseSafe/Fast/Small | LLVM by default in a normal libLLVM build; explicit `-fno-llvm` can force a self-hosted backend | `Config.zig:359-360` |
| any target | `.ll`/`.bc`, TSan | LLVM forced | `Config.zig:322-355` |
| any target | no libLLVM, emitting a binary | LLVM backend unusable; self-hosted required | `Config.zig:353-358` |

Two details that are easy to miss:

* **The support table's ⚡ means “self-hosted backend available”, not
  “self-hosted is the default”.** That is why x86_64-macOS can show ⚡ while
  its Debug default is LLVM. The table's hover titles mark ⚡ as “Self-Hosted”
  and 🛠️ as “Self-Hosted In Development”
  ([0.17 target table](https://ziglang.org/download/0.17.0/release-notes.html#Support-Table)).
* **The 0.15→0.17 change on macOS is a regression, not a removal.** The gate
  in [0.15.1](https://codeberg.org/ziglang/zig/src/tag/0.15.1/src/target.zig#L236-L249)
  returned true for `.macho`;
  [0.16.0](https://codeberg.org/ziglang/zig/src/tag/0.16.0/src/target.zig#L278-L296)
  still did;
  [0.17.0](https://codeberg.org/ziglang/zig/src/tag/0.17.0/src/target.zig#L311-L335)
  returns false with issue 35267 as the reason. The backend still exists and can
  be forced, but its output is not robust enough to be the default.

The non-x86_64 backends are real but not “done”: aarch64 has its own MIR,
encoder and selector (`src/codegen/aarch64/`), yet 0.17 says progress is
blocked on linker enhancements. That is the central lesson for Bend: **a
backend is a codegen *and* object/link/debug story, and the second half can
block the first.**

---

## 3. The pipeline that actually exists in Zig 0.17.0

The names below are upstream paths, not assumptions.

### 3.1 File → ZIR (per-file, cached)

`src/Zcu/PerThread.zig` has one update loop: detect changed files, run AstGen,
load or rebuild per-file ZIR, and then enter semantic analysis. ZIR is cached
on disk and validated against file size, mtime and inode
(`loadZirZoirCache`, `src/Zcu/PerThread.zig:730-783`). The cache is per source
file, not per declaration.

The design property is stated plainly by the core-team post: parse + AstGen is
a pure function of one file, so it is embarrassingly parallel and cacheable;
`updateZirRefs` re-maps references into the new ZIR after an edit
([incremental post, “Processing Source Files”](https://mlugg.co.uk/posts/incremental-compilation-internals/)).

### 3.2 Semantic analysis → AIR (per function/declaration)

Semantic analysis produces AIR at the granularity of a *function body* and
tracks dependencies at the granularity of four analysis units: type layout,
declaration type, declaration value, function body
([incremental post, “Semantic Analysis”](https://mlugg.co.uk/posts/incremental-compilation-internals/)).
The dependency maps live in `InternPool` (`src/InternPool.zig:47-64`): source
hash dependencies, nav value/type dependencies, function inferred-error-set
dependencies, type layout dependencies, struct default dependencies, file and
embed-file dependencies.

Crucially, the dependency graph is made acyclic by language/type-resolution
design, except for genuine dependency loops; the 0.16 release notes describe
that rework as the fix for “over-analysis” and incremental/non-incremental
inconsistency ([0.16 type resolution](https://ziglang.org/download/0.16.0/release-notes.html#Reworked-Type-Resolution)).

### 3.3 AIR lifetime and handoff (the part worth copying)

`analyzeFuncBody` owns the AIR, then optionally transfers ownership to the
codegen pool:

* `var air = try pt.analyzeFuncBodyInner(...); var air_owned = true; defer if (air_owned) air.deinit(gpa);`
* `const disown_air = zcu.backendSupportsFeature(.separate_thread);`
* `const codegen_task = try zcu.codegen_task_pool.start(zcu, func_index, &air, disown_air);`
* `if (disown_air) air_owned = false;`
* then it enqueues the task on the linker queue (`src/Zcu/PerThread.zig:2271-2325`).

The pool owns and frees the AIR after codegen when `move_air` is true
(`workerCodegenOwnedAir`, `src/Zcu.zig:5509-5520`). The returned MIR is owned by
the caller of `Index.wait` (`src/Zcu.zig:5482-5504`), and `AnyMir.deinit`
disposes it after the linker consumes it (`src/codegen.zig:104-143`).

The core-team post states the resulting policy directly: AIR is thrown away as
soon as codegen is done, MIR is thrown away right after the linker consumes it,
and **there is no need to cache AIR or MIR at all** because both already exist at
function granularity
([incremental post, “Code Generation”](https://mlugg.co.uk/posts/incremental-compilation-internals/)).

### 3.4 Bounded in-flight work (the part that prevents an OOM)

The codegen pool caps AIR bytes in flight at 10 MiB:

```
const max_air_bytes_in_flight = 10 * 1024 * 1024;
```

and the comment explains the budget: worst observed MIR is ~50× AIR, typically
~20×, so 10 MiB of in-flight AIR corresponds to roughly 500 MiB of AIR+MIR
(`src/Zcu.zig:5358-5366`). `start` blocks on a condition variable when the
freelist is empty or the byte budget is exhausted, providing real backpressure
from codegen/link back to semantic analysis (`src/Zcu.zig:5421-5470`).

This is **not** a total-memory cap and not a claim that 10 MiB is the right
number for Bend. It is a bounded-work design: one stage cannot run arbitrarily
far ahead of the stage that consumes its output.

### 3.5 AIR → MIR → machine code

`src/Air/Liveness.zig` computes per-AIR-instruction liveness in 4 bits per
instruction plus a sparse special table (`src/Air/Liveness.zig:1-35`).
`src/Air/Legalize.zig` holds the legalization pass; `codegen.zig` dispatches
`legalizeFeatures` and `wantsLiveness` per backend (`src/codegen.zig:69-101`).
Notably, aarch64 and loongarch do **not** request the shared liveness pass
(`wantsLiveness` returns false for them).

Each backend has its own MIR:

* x86_64 MIR is “1:1 correspondence with machine code instructions”; its stated
  purpose is to postpone offset assignment until instruction selection so
  smaller jump encodings can be chosen (`src/codegen/x86_64/Mir.zig:1-10`).
* The x86_64 emitter lowers MIR to machine code, applies relocations, and
  writes DWARF/CFI (`src/codegen/x86_64/Emit.zig:1-25`).
* The aarch64 backend uses the actual machine instruction encoding as its MIR
  and does encoding on the N codegen threads rather than the single linker
  thread; its bespoke two-pass liveness generates MIR in reverse during the
  second pass, avoiding the x86 backend's deferred-value tracking
  ([2025-07-23 devlog](https://ziglang.org/devlog/2025/#2025-07-23)).

There is no single shared, backend-neutral register-allocation pass in the files
read; a generic `RegisterManager` template exists (`src/register_manager.zig`),
but the x86_64 and aarch64 value/register tracking is architecture-specific:
aarch64 embeds `LiveRegisters`/`live_values`/`values` in `Select.zig`
(`src/codegen/aarch64/Select.zig:36-60`), while x86_64 has its own
deferred-value state machine in `CodeGen.zig` (same devlog). Do not read this as
“Zig has no register allocation”; read it as “allocation is not a reusable
shared layer”.

### 3.6 Linker and incremental object update

`link.zig` exposes an opaque `AtomId` for a function being emitted and
`updateFunc` takes an `AnyMir` whose active tag is the backend; the callee may
mutate the MIR but must leave `mir.deinit` legal (`src/link.zig:776-875`).
LLVM codegen never calls these functions; they are the self-hosted path.

The new ELF linker (`src/link/Elf2.zig`) writes a function into a
`MappedFile` node, marks it moved, regenerates its DWARF FDE/CIE, and defers
address assignment and relocation fixups to `flush` when the linker thread is
idle:

* `updateFuncInner` obtains the nav's symbol/node, calls `ni.moved(...)`, then
  writes machine code and debug info into the node
  (`src/link/Elf2.zig:9954-10060`).
* `MappedFile` is a memory-mapped output file with a tree of nodes; growing or
  moving a node sets a dirty flag so fixups can be re-applied. Growth factor 4
  amortizes moves (`src/link/MappedFile.zig:1-45`, and
  [incremental post, “Linking”](https://mlugg.co.uk/posts/incremental-compilation-internals/)).

This is the piece that makes “near-instant rebuild” possible: the compiler does
not rewrite the whole object file, it patches a node and lets the linker fix
up what moved. The post is explicit that incremental linking is hard, and that
Zig's shortcut is to tightly integrate the linker with the compiler rather than
diff arbitrary input objects.

### 3.7 Parallelism and its cost

`src/Zcu/PerThread.zig:127-300` starts parallel AstGen workers, then enters the
semantic-analysis loop; `codegen_task_pool` runs codegen on arbitrary threads;
the linker consumes MIR on its own thread. The June 2025 devlog states the
trade-off: the LLVM backend uses much more shared state and remains limited to
one thread, while self-hosted machine-code generation is isolated enough to run
on many threads, with the linker gluing the result
([2025-06-14 devlog](https://ziglang.org/devlog/2025/#2025-06-14)).

The same devlog reports that parallel codegen raised peak RSS by 25.7% on the
“build the Zig compiler” benchmark (1.08 GB → 1.35 GB) while reducing wall
time 13.8 s → 10.0 s. Parallelism is not free memory.

### 3.8 Interned globals vs ephemeral IR

`InternPool` is a long-lived, sharded, per-thread-local interning store for all
values/types (`src/InternPool.zig:1-40`). It is not freed per function. The
memory story is the *separation*: long-lived interned facts stay; per-function
AIR/MIR are released as soon as their consumer is done. Interning alone does not
bound memory, and “AIR was freed” is not evidence that the process's retained
set shrank.

### 3.9 ABIs and debug info are per-target modules

Each self-hosted backend has its own `abi.zig` (x86_64: SysV, Win64, `zigcc`;
aarch64: its own `abi.zig`), and target/calling-convention facts are shared
through `std.lang` (`CompilerBackend`, calling conventions). Debug info is
generated in the emitter/linker, not in the frontend: x86 `Emit.zig` writes CFI
and DWARF; `Elf2.updateFunc` builds FDE/CIE records. This is a reminder that
“emit machine code” is the small part; ABI, unwind and debug are separate
contracts.

---

## 4. Why Zig chose this path, and what the benchmarks actually say

The stated reasons, in upstream's own words:

* **Compile speed.** “Why compete with LLVM on code generation? … mainly,
  because we can dramatically outperform LLVM at compilation speed.”
  ([2025-06-08 devlog](https://ziglang.org/devlog/2025/#2025-06-08)).
  The 0.15.1 notes say “around a 5x decrease compared to LLVM in most cases”
  ([x86](https://ziglang.org/download/0.15.1/release-notes.html#x86-Backend)).
* **Correctness/coverage of the language.** 0.15.1 reports 1984/2008 behavior
  tests for the self-hosted x86 backend vs 1977/2008 for LLVM, and lists 60+
  tracked upstream LLVM bugs as a reason to reduce exposure
  ([x86](https://ziglang.org/download/0.15.1/release-notes.html#x86-Backend)).
* **Incremental compilation and parallel codegen** are easier when the
  compiler owns machine-code generation and can isolate it from a large shared
  LLVM state ([2025-06-14 devlog](https://ziglang.org/devlog/2025/#2025-06-14)).
* **Dependency/distribution cost.** The LLVM Builder API work is described as
  “efforts toward entirely eliminating the LLVM dependency” because libLLVM is
  large and has an unstable API
  ([0.14.0 LLVM Builder API](https://ziglang.org/download/0.14.0/release-notes.html#LLVM-Builder-API)).
  By 0.15 the goal is “transition LLVM to an optional dependency”
  ([aarch64](https://ziglang.org/download/0.15.1/release-notes.html#aarch64-Backend)).
  By 0.17 it is “a process dependency on Clang”
  ([roadmap](https://ziglang.org/download/0.17.0/release-notes.html#Roadmap)).
* **Optimization quality is explicitly *not* the reason.** The self-hosted
  backend “is also currently known to emit slower machine code than the LLVM
  backend” (0.15.1), and 0.16 says “inferior machine code quality” while
  remaining the Debug default
  ([0.16 x86](https://ziglang.org/download/0.16.0/release-notes.html#x86-Backend)).
  Release builds therefore stay on LLVM.

### Upstream numbers (repeat exactly; do not extrapolate to Bend)

| Workload | Command / mode | Result | Peak RSS | Host stated? | Source |
|---|---|---|---|---|---|
| `hello.zig` | `zig build-exe hello.zig` default (Debug, x86_64) vs `-fllvm` | 918 ms → 275 ms | 214 MB → 137 MB | No | [2025-06-08](https://ziglang.org/devlog/2025/#2025-06-08) |
| Build the Zig compiler | self-hosted x86_64 backend, parallel codegen change | 13.8 s → 10.0 s (−27.4%) | 1.08 GB → 1.35 GB (+25.7%) | No | [2025-06-14](https://ziglang.org/devlog/2025/#2025-06-14) |
| `hello.zig` | same parallel-codegen change | 355 ms → 244 ms (−31.5%) | 138 MB → 148 MB (+7.3%) | No | [2025-06-14](https://ziglang.org/devlog/2025/#2025-06-14) |
| `hello.zig` | `-fno-llvm -OReleaseSmall -target x86_64-linux` vs `-target aarch64-linux` | 42.7 ms vs 32.1 ms | 110 MB vs 103 MB | No | [2025-07-23](https://ziglang.org/devlog/2025/#2025-07-23) |

Caveats:

* Upstream does not state the machine for the first three rows. The 0.15.1
  “27% faster” note repeats the 13.8→10.0 s datapoint without naming hardware
  ([threaded codegen](https://ziglang.org/download/0.15.1/release-notes.html#Threaded-Codegen)).
* The last row compares **two different targets/backends** in
  `ReleaseSmall`; it is not a code-quality comparison and does not say aarch64
  is faster overall.
* The 5× claim is a range-free “most cases” statement in release notes, not a
  controlled benchmark.
* None of these measure Bend, and Bend's frontend/semantics differ enough that
  no ratio transfers.

---

## 5. Does LLVM participate in current Zig incrementality?

**Yes, at the bitcode/analysis level.** The 0.16 notes say the LLVM backend now
supports incremental compilation, but explicitly: “This does not speed up the
‘LLVM Emit Object’ phase of compilation: that step is entirely LLVM's
responsibility and there is little we can do to speed it up. However, it does
speed up the building of LLVM bitcode in the Zig compiler.”
([0.16 incremental](https://ziglang.org/download/0.16.0/release-notes.html#Incremental-Compilation)).
The same section says incremental is usable with both the self-hosted ELF
linker and the LLVM backend.

So:

* **[I]** Own backend is **not a prerequisite** for incremental semantic
  analysis: the LLVM backend already participates at the bitcode/build level.
* **[I]** Own backend **is** what enables the current “patch the output binary
  without invoking an external object emitter” model on x86_64-linux; LLVM Emit
  Object remains an opaque, non-incremental step in that path.
* Zig still does not serialize its incremental state across invocations; the
  post says the eventual goal is to cache compiler state to disk and reload it
  automatically, but today the workflow is `--watch` plus an in-process update
  ([incremental post, “Using Incremental Compilation”](https://mlugg.co.uk/posts/incremental-compilation-internals/)).
  `incremental` defaults to `false` in `Compilation.Config.Options`
  (`src/Compilation/Config.zig:110`).

For Bend, this means: **do not argue “we need our own backend for incremental
compilation.”** Zig's own evidence is that LLVM can participate in the
frontend/incremental loop, and that the hard parts are the dependency graph and
the linker/object update.

---

## 6. Bend baseline: where the current pipeline actually is

### 6.1 The new self-hosted lane

* Owning checked program:
  `CheckedProgram{source: Arena.Arena, modules, signatures, metadata}`
  (`bend2/selfhost/checked_frontend.bend:17-18`).
  The arena uses dense `U32` node handles and flat tapes
  (`bend2/selfhost/checker_arena.bend:5-31`), so “dense representations” is
  already partly present.
* Target-neutral BIR: `BIR.Program{codes, declarations, constructors,
  families, type_functions, ending}`; `BIR.Code` is one function body, keyed by
  `U32` id (`bend2/selfhost/backend_ir.bend:216-234`). Declarations point at
  code ids (`bend2/selfhost/backend_ir.bend:221-231`).
* Lowering is whole-program: `lower` → `prepare` → `Catalog.build` →
  `definitions` → `lower_complete`, returning one `BIR.Program`
  (`bend2/selfhost/backend_lower.bend:1943-1965`;
  `bend2/selfhost/lower_catalog.bend:1467`). The catalog and descriptor
  normalizer are global, even though `Code` itself is per body.
* C emission is one translation unit built from whole char lists:
  `c_emit.emit` lowers once, reads the runtime and foreign sources into
  `String`s, then `c_backend.emit` → `plan_make` → `render` → `render_parts` →
  `render_assemble` (fills the runtime template) → `render_rewrite` (whole-source
  lexical `CID`/`FID` rewrite) → `Link.rewrite`
  (`bend2/selfhost/c_emit.bend:97-102`;
  `bend2/selfhost/c_backend.bend:3173-3209`;
  `bend2/selfhost/c_backend_link.bend:1-12`). Bend's `String` is `SNil`/`SCon`
  (`bend2/base.bend:73-75`), and `String.append` walks its first operand
  (`bend2/base.bend:1901-1906`), so each whole-program concatenation/rewrite
  allocates a cons per character; this is a character-list materialization,
  not a flat buffer copy.
* The C header itself documents that this is a single C translation unit with a
  per-program runtime ABI: `WL_SIG`, `WL_RESW`, `FID_T`, `CID_T`, `BANGS`,
  segment entry conventions, closure/trampoline ABI
  (`bend2/selfhost/c_backend.bend:11-41`).
* JS is also a whole-program char-list renderer: `js_backend` concatenates the
  JS runtime and all program parts into one `String` (a `SCon` list)
  (`bend2/selfhost/js_backend.bend:1160`; `bend2/selfhost/js_emit.bend:20-33`).

### 6.2 The official producer and the OOM locus

The official compiler's C path is `bend2/comp.ts:compile_book`. It is a
fixed-point loop over `FL.own.size + FL.hot.size + FL.stat.size`: each pass
clears `FL.lend/spun/clos/tabs/lits/consts/brws`, clears segments/spins/image,
re-emits every definition, then repeats until the fact count stops changing
(`bend2/comp.ts:3110-3155`). Only after that does `bend2/main.ts` invoke clang
with `-std=c11 -O3` (`bend2/main.ts:451`).

Project state **[P]**: the traced `compile_book` run hit pass 6 at the
3072 MiB guard; one no-trace control ended `ABORTED_NO_TERMINAL_REPORT`
(dead PIDs, empty guardian receipt; exact kill cause unobserved). No receipt
for that trace was reproduced in this worktree. This note does not attribute
the OOM to a particular allocation, and does not treat a `process.heapUsed`
minimum as retained bytes. The native guardian lifecycle repair is a separate
active priority; nothing in this note substitutes for it.

**Consequence:** the producer is upstream of clang. A different LLVM mode,
`-O0`, a direct LLVM renderer, a native backend, or “removing LLVM” cannot fix
an OOM that occurs while `compile_book` is still building its C program.
Likewise, the self-hosted C lane's whole-program char-list materializations are
downstream of the official producer and are a separate cost.

---

## 7. What can be reused now, while keeping C → clang

The table separates (a) changes that are local to the current C/JS renderers,
(b) changes that need BIR/runtime/ABI work, and (c) things that do not transfer.

### 7.1 Reusable now (no semantic change)

| Zig mechanism | Bend anchor | Concrete use now | Acceptance signal |
|---|---|---|---|
| Per-function AIR/MIR lifetime; release after consumer | `BIR.Code` is per body (`backend_ir.bend:216-218`), but `Program` is whole (`:233-234`) | Avoid retaining per-`Code` render intermediates after their part is emitted; do not build one whole-program char list first | Peak physical footprint falls on a fixed corpus with identical output bytes |
| Bounded in-flight work + backpressure | No producer/consumer split yet; `compile_book` is a whole-program fixed point | Add a bounded phase queue only after a real split; first measure the current per-pass retained set | Queue depth and peak never exceed declared caps; no dropped diagnostics |
| Typed relocations instead of whole-source textual fixup | `render_assemble` produces the whole source, then `Link.rewrite` scans it once (`c_backend.bend:3201-3209`; `c_backend_link.bend:1-12`) | Emit final `CID`/`FID` spellings directly for Bend-generated code; restrict rewrite to foreign effect sources | Byte-identical `.c` output for the corpus; one fewer full-source traversal/materialization |
| Late/streamed lowering | `render_assemble` concatenates runtime + tables + spins + segments + requests (`c_backend.bend:3201-3204`) | Stream parts to the output file/buffer in order; avoid holding several whole-program char lists | Byte-identical `.c`; lower peak; clang result unchanged |
| Debug vs release tiering | The CPU C path uses `-O3` by default (`main.ts:451`); the JS lane exists and does not invoke clang (relative performance unmeasured here) | Add an explicit dev tier (`-O0`/`-O1 -g`) beside release `-O3` | Same program outputs on the test corpus; measure wall/peak; no OOM claim |
| Phase instrumentation (Tracy/progress) | `evals/heavy_gate.ts` guard; `BEND_*_TRACE_FILE` hooks | Add phase timers and peak sampling at catalog/lower/render/rewrite/clang/link | Per-phase wall and peak for a fixed input, recorded with the existing guard |
| Dense IR + flat tapes | Already present in `checker_arena.bend` and BIR `U32` ids | Keep; do not port Zig's liveness bits or register allocation—C owns those | No change required |

Why the C-renderer changes are legitimate “reuse”: the analogous Zig design is
to carry typed relocations and patch known locations instead of re-scanning a
textual output (`src/codegen/x86_64/Emit.zig:16-17`,
`src/link/Elf2.zig:9954-9987`). Bend's equivalent is not “write an x86 encoder”;
it is “stop materializing the same C program several times and stop doing a
second lexical pass over the result”.

### 7.2 Needs future BIR/runtime/ID/ownership/ABI work

| Zig mechanism | Why Bend cannot copy it directly | Prerequisite |
|---|---|---|
| Four analysis-unit kinds + source-hash dependency graph | Bend's units are not Zig's: dependent types, laws, quantities, family/type-function normalization, and descriptors are additional fact kinds | Definition-level dependency facts in `CheckedProgram`/BIR: source range → declaration/code, plus type/layout/descriptor/quantity dependencies |
| Stable IDs for incremental invalidation | `Catalog.next_code` assigns code ids during whole-program catalog construction; no cache key or cross-edit stability contract is documented | Stable code/declaration IDs and an explicit key (source hash + dependency fingerprint) |
| Per-function release | Bend's arena publishes immutable nodes and exposes no compiler-side `deinit` in the files read; in the C runtime, memory is handled by generated `term_drop`/`heap_free` | Ownership/release support in the compiler (or a GC/host-managed arena with a measurable retained-set policy) |
| Incremental linker patching | No Bend linker exists; clang/lld is external and not an incremental patcher in Zig's sense | Either a stable separate-compilation ABI plus object-level caching, or a Bend-owned patchable output format |
| Separate compilation | The runtime ABI is per program (`WL_SIG`, `WL_RESW`, `FID_T`, `CID_T`, `BANGS`; `c_backend.bend:11-41`) | A stable ABI or a link-time table/fixup format; otherwise each program is one TU |
| Debug info/unwind fidelity | BIR retains spans, but the C lane emits no `#line` mapping; unwind/debug sections come from clang, not from Bend's emitter | `#line` emission for the C lane (cheap); for a native backend, full DWARF/CFI ownership |
| Target-specific ABIs | Zig has per-arch `abi.zig`; Bend has a generated runtime ABI, not a platform C ABI | Any native backend must implement the generated entry/closure/register ABI exactly, not a generic SysV ABI |

Two warnings from Zig's own history:

* **Do not copy the 10 MiB number.** It is derived from Zig's AIR/MIR ratio and
  a 500 MiB budget (`src/Zcu.zig:5361-5364`). Bend's ratio and budget are
  unmeasured.
* **Do not copy “lazy analysis”.** Zig analyzes only referenced declarations
  and then traverses the reference graph during flush to decide what is live
  ([incremental post, “Flush”](https://mlugg.co.uk/posts/incremental-compilation-internals/)).
  Bend's roots/checks/exports are acceptance obligations; using Zig-style
  laziness to analyze fewer of them would reduce the specification, not improve
  the implementation.

### 7.3 What cannot transfer

| Zig property | Why it does not fit Bend |
|---|---|
| LLVM optionality/removal | Zig still uses LLVM for release builds and many targets; Bend's C→clang lane is the shipping path and the OOM is before clang. “Remove LLVM” is neither Zig's current state nor a Bend fix. |
| Acyclic semantic dependencies | Bend has dependent types, laws, quantities and global family/type-function normalization; genuine cycles and whole-program fixpoints are part of the language, not over-analysis to be eliminated. |
| Zig's four analysis units | They do not model affine ownership, dependent elimination, law checking, descriptor normalization or the runtime's parallel graph. |
| Lazy “only referenced” analysis | Conflicts with checking all roots/exports; explicitly rejected as a scope reduction. |
| Affine/quantity semantics | Zig has no affine values; its backend assumes ordinary single-owner SSA values. Bend's quantities and runtime `term_drop` are extra contracts. |
| Parallel graph runtime / GPU scheduling | Zig's SPIR-V backend is codegen, not a scheduler; Zig has no Bend-style `!`/fork runtime. GPU remains a runtime/emitter project (see `RESEARCH_GPU.md`). |
| Zig's register allocator / encoder / linker code | Coupled to `Zcu`, `InternPool`, `Air`, `std.Io`, per-arch ABI and Zig's object model; not a standalone library. |

---

## 8. Direct code reuse vs learning the design

**License.** Zig is MIT/Expat (`ziglang/zig/LICENSE` at 0.17.0). Bend is
Apache-2.0. MIT code can be included in an Apache-2.0 project with the copyright
and permission notice; the licenses are compatible. That is a legal answer, not
an engineering one.

**Coupling.** The backend files are not standalone:

* `src/codegen.zig` imports `Compilation`, `Zcu`, `InternPool`, `Air`, `Type`,
  `Value`, `link`, `std.lang` and dispatches into per-arch modules
  (`src/codegen.zig:1-143`).
* `src/Zcu.zig` owns the codegen pool, analysis units, intern pool and linker
  queue; a backend cannot be lifted without that runtime.
* `src/codegen/x86_64/CodeGen.zig` is 11,060,217 bytes at 0.17.0;
  `src/codegen/aarch64/Select.zig` is 651,522 bytes and
  `encoding.zig` is 666,675 bytes; `src/link/Elf2.zig` is 571,324 bytes.
  These sizes are scale indicators, **not** effort attribution or a claim that
  porting is proportional to bytes.
* The x86 encoder depends on `encodings.zon`, instruction tables, ABI modules,
  relocation kinds and the linker's `AnyMir`/`AtomId` protocol. Reusing the
  encoder without the MIR/relocation/linker contract would be a rewrite with
  extra steps.

**Maintenance.** Zig's backend internals move between releases: 0.15→0.16
changed type resolution and incremental semantics; 0.16→0.17 changed the
default gate, added the new ELF linker and moved SPIR-V/WASM status. Vendoring
backend code would import that churn into Bend and couple Bend's release cadence
to Zig's compiler internals.

**Verdict.** Learn the design; do not vendor the backend. The transferable
artifacts are: the lifetime/ownership protocol, the bounded-queue discipline,
the “MIR before encoding” separation, the typed-relocation/linker model, the
dependency-unit vocabulary, and the two-tier build policy. The non-transferable
artifacts are the architecture-specific encoders, ABI tables, register
allocation and linker implementation.

---

## 9. Cross-reference to the existing Bend research notes

* `RESEARCH_LLVM.md` (worktree `/private/tmp/bend-llvm-research`) concludes:
  keep C as the shipping path; a direct LLVM renderer is a second renderer, not
  a replacement; the hard parts are physical layout, ownership/refcount
  destinations, the generated runtime ABI and the runtime. **This note agrees**
  and adds the Zig lesson that the pipeline/linker/incremental work is the
  larger win. Zig's own backend still uses LLVM for optimized builds, which
  weakens any “LLVM replacement” reading of Zig.
* `RESEARCH_MLIR.md` (worktree `/private/tmp/bend-mlir-research`) proposes a
  bounded M1: emit standard-dialect MLIR from BIR and check verification plus
  valid-program semantics, with no codegen cutover. **This note does not
  duplicate or contradict that**; MLIR is an IR/verification experiment, while
  Zig's lesson is about lifetime, queues, dependency tracking and linking. A
  future definition-level dependency graph is a prerequisite for either.
* `RESEARCH_GPU.md` (worktree `/private/tmp/bend-gpu-research57ab`) finds that
  GPU exists in the official C lane but not in BIR: `TermBang` lowers to its
  child, `BANGS` is zero, and the JS backend is sequential. Zig's self-hosted
  SPIR-V backend does not change that; it is codegen, not a parallel graph
  runtime. **Do not cite Zig as evidence that a GPU path is close.**
* No `RESEARCH_WASM_WASI.md` was present in the peer worktrees I read, so this
  note does not rely on one. Zig's WASM data is limited to the 0.17 statement
  that the self-hosted WASM backend passes 100% of behavior tests but is not
  the Debug default because debug info is missing; that is not an argument
  about Bend's WASM lane.

---

## 10. Ranked lessons for Bend

Ranked by expected value per unit of risk, not by implementation size.

1. **Measure and bound the producer before touching a backend.** The known OOM
   is in `compile_book`'s fixed-point, before clang. Zig's first wins were
   pipeline changes (per-function ownership, queue caps, linker integration),
   not a new encoder. Any backend work now would be aimed at the wrong stage.
2. **Separate ephemeral per-definition IR from long-lived facts, and release
   the ephemeral part.** Zig's AIR/MIR are per function and are not cached;
   only interned/persistent facts survive. Bend has per-`Code` BIR but a
   whole-program `Program` and whole-program char-list renderers. The first
   implementation-level win is eliminating redundant whole-program `String`
   (char-cons) materializations in `c_backend` (and, if measured, JS), not
   adding passes.
3. **Use structured emission instead of whole-source rewriting.** Replace the
   full-source `CID`/`FID` pass for generated code with final IDs at emission
   time; keep the lexical rewrite only for foreign effect sources that actually
   contain those spellings. This is the Bend analogue of Zig's typed
   relocations.
4. **Two tiers: fast development and optimized release.** Keep `-O3` for
   release; add a measured `-O0/-O1 -g` development tier. Zig's own backend is
   a Debug-tier tool with inferior machine code; it is not evidence that a
   fast tier can replace the optimized one.
5. **Bound in-flight work only after a producer/consumer split.** Zig's 10 MiB
   AIR cap is a model of backpressure, not a number to copy. Without a split,
   a queue is cosmetic; with a split, it is the difference between bounded and
   unbounded retention.
6. **Make invalidation definition-granular only with dependency facts.**
   `BIR.Code` is already per body, but `Catalog.build` and the descriptor
   normalizer are global. Per-`Code` caching without type/layout/descriptor
   dependencies would be unsound. Zig needed four unit kinds and an acyclic
   graph; Bend's fact kinds are larger.
7. **Incrementality is a frontend + linker project, not a backend swap.**
   Zig's LLVM backend participates in incremental bitcode building; the
   remaining non-incremental step is LLVM Emit Object. The Zig-specific enabler
   is the self-hosted linker's `MappedFile` patching. Bend has neither the
   dependency graph nor the linker, so “own backend” would not by itself produce
   incremental builds.
8. **Do not build a native backend to fix memory.** Zig's backend still needs
   LLVM for release quality and still fights linker/debug/ABI issues on macOS,
   Windows and aarch64. A Bend native backend would inherit the generated
   runtime ABI, closure/trampoline conventions, tables, unwind and debug work
   before it saved a byte on the current OOM.

---

## 11. Conservative recommendation

**Do not start a native backend, do not remove clang/LLVM, and do not cut over
the C lane.** Keep C → clang as the shipping path and JS as the no-clang lane.
The Zig evidence supports the following order:

1. **Now:** instrument the official producer and the self-hosted renderer;
   record per-pass/per-phase wall, peak physical footprint and retained facts
   on a fixed input. No semantic change, no new dependency. This is the only
   way to distinguish “the fixed point retains too much” from “one phase peaks
   too high”; the current project state lacks that attribution.
2. **Now:** remove redundant whole-program copies and the whole-source rewrite
   in `c_backend` for generated code. Byte-identical C output is the acceptance
   gate; lower peak is the expected, measured effect.
3. **Now:** add a development C tier (`-O0`/`-O1 -g`) beside release `-O3`.
   This is a user-facing latency/memory experiment, not an OOM fix and not a
   code-quality claim.
4. **Only after 1–3:** prototype definition-level invalidation at the BIR
   boundary, with explicit dependency facts and stable IDs. Do not call it
   “incremental compilation” until invalidation is sound on a type/layout change,
   not only on a body edit.
5. **Only if a measured bottleneck remains that C/clang cannot serve:** evaluate
   a native backend as a separate project with its own ABI, unwind, debug and
   linker budget. Zig's history shows the work spans multiple release cycles and
   that the linker can block the backend.

Guardrails for any follow-up:

* Do not reduce roots, checks or exports as a “lazy Zig-style analysis”
  optimization. That changes the specification.
* Do not treat an LLVM/backend change as a fix for a producer OOM that occurs
  before clang.
* Do not treat parallelism as free: Zig's own parallel-codegen benchmark raised
  peak RSS 25.7%.
* Do not claim native acceptance from a source-present renderer or from a
  partial test slice; the current full native13 is not accepted. No further
  full heavy build and no target cutover follow from this note.

---

## 12. Small scoped experiments and acceptance

All are research-scoped; none commits an architecture. Each must preserve the
public13 ABI and the existing test corpus.

### E1 — Producer phase accounting (recommended first)

* **Change:** use `compile_book`'s existing `file_observe` pass markers and the
  existing `evals/heavy_gate.ts` sampler; record per-pass `FL.own/hot/stat`
  sizes, `FL.segs/spins/img` sizes, wall time, peak physical footprint, and
  exit reason. Optionally add the same for `c_backend` render phases.
* **Acceptance:** a fixed input produces a complete per-pass table; the sum of
  observed phases is consistent with total wall; no semantic output change;
  no claim about allocation cause beyond what is sampled. If the guard trips,
  report `RESOURCE_LIMIT`, not FAIL.
* **Why:** the current OOM is known by pass number, not by retained set.

### E2 — C emission without whole-source copies (recommended second)

* **Change:** emit final `CID`/`FID` spellings for Bend-generated code; apply
  `Link.rewrite` only to foreign effect sources; stream the runtime/tables/
  segments/requests parts in order instead of concatenating several whole
  strings.
* **Acceptance:** byte-identical `.c` for a fixed corpus (hash comparison);
  same compiled program behavior; lower or equal peak physical footprint;
  no new dependency. If hashes differ, stop and explain the spelling delta.
* **Why:** this is the Zig “typed relocation instead of textual rewrite” lesson
  at the scale Bend can test now.

### E3 — Development C tier

* **Change:** add an explicit `-O0`/`-O1 -g` mode for development builds,
  selected by a flag; keep `-O3` for release.
* **Acceptance:** identical program outputs on the test corpus; record wall
  and peak for both modes on fixed inputs; no claim that it fixes the producer
  OOM and no claim about release code quality.
* **Why:** Zig's own backend is a Debug-tier tool; the lesson is tiering, not
  “fast compiler replaces optimizing compiler”.

### E4 — Definition-level invalidation prototype (future, only after E1–E3)

* **Change:** hash each `BIR.Code` and declaration; on a one-body edit, show
  that unchanged codes are not re-lowered/re-rendered; on a type/layout edit,
  show that dependents are invalidated.
* **Acceptance:** unchanged-code hashes identical; dependent codes change;
  no missed invalidation on a crafted type/layout/descriptor case; no claim of
  incremental linking. This is a dependency-graph experiment, not a linker.
* **Why:** Zig's incrementality is per analysis unit; Bend cannot copy it
  without naming its units.

### E5 — Separate C translation units (future, only if E1–E3 show backend-bound cost)

* **Change:** emit one C TU per `Code` (or per declaration group) and link with
  the generated table/fixup layer.
* **Acceptance:** link succeeds with the same runtime ABI; identical program
  outputs; measured wall/peak; no ABI change without a separate design review.
* **Why:** Zig's per-function codegen is glued by a linker thread; Bend's
  tables are program-wide, so this is an ABI experiment, not a flag.

---

## 13. Future tasks (explicitly not started)

1. **Producer retained-set attribution.** Extend the E1 sampler to distinguish
   live JS heap, external/native memory, and code/strings where the runtime
   permits; do not infer attribution from `heapUsed` minima.
2. **Bend analysis-unit vocabulary.** Define dependency kinds for: declaration
   type/value, function body, type layout, constructor layout, family/type
   function, descriptor normalization, quantity/ownership facts, and foreign
   source. This is the analogue of Zig's four units, but with Bend's semantics.
3. **Stable IDs and cache keys.** Document whether `Catalog.next_code` is
   deterministic across runs and edits; define the key for a cached `BIR.Code`.
4. **Compiler-side release/ownership.** Determine whether the self-hosted
   compiler can free per-definition intermediates without changing the arena
   contract; if not, keep the measurement-only approach.
5. **Separate-compilation ABI.** Specify how `WL_SIG`/`FID_T`/`CID_T`/`BANGS`
   become link-time fixups rather than one-TU constants.
6. **Debug mapping for the C lane.** Add `#line`/span mapping if measurement
   shows diagnostics or debugger use is a real cost; this does not require BIR
   changes.
7. **Re-check Zig 0.18.** The aarch64 default, macOS gate and incremental state
   are moving; do not freeze this note's status matrix as permanent.

---

## 14. Open questions and limits

* **Exact cause of the pass-6 OOM is unobserved.** The project has a pass number
  and a guard breach, not a retained-set attribution. The no-trace control's
  `ABORTED_NO_TERMINAL_REPORT` is not evidence of a semantic failure; its kill
  cause is unknown.
* **Whether `compile_book`'s fixed point is monotone/terminating on the failing
  input is not established here.** The loop condition is fact-set equality, not
  a bound. A pass-count/retained-set curve is the first measurement.
* **Bend's BIR code IDs are not documented as stable across edits.** Do not
  assume they are a cache key.
* **Bend has no compiler-side ownership/release for its arena.** Any “release
  per function” proposal needs a language/runtime answer, not just a refactor.
* **A native backend's ABI/unwind/debug/linker cost is not estimated here.**
  Zig's own experience says these can block a backend; no Bend estimate is
  implied.
* **Zig status is version-qualified.** Every “default” statement above is for
  the named tag/target/mode; 0.18 may change the macOS/aarch64 gates.

---

## 15. Sources

Primary Zig sources (all read 2026-10-24):

* 0.11.0 release notes — <https://ziglang.org/download/0.11.0/release-notes.html>
* 0.14.0 release notes — <https://ziglang.org/download/0.14.0/release-notes.html>
* 0.15.1 release notes — <https://ziglang.org/download/0.15.1/release-notes.html>
* 0.16.0 release notes — <https://ziglang.org/download/0.16.0/release-notes.html>
* 0.17.0 release notes — <https://ziglang.org/download/0.17.0/release-notes.html>
* Zig download page (latest stable 0.17.0, 2026-10-01) —
  <https://ziglang.org/download/>
* Zig devlog 2025 — <https://ziglang.org/devlog/2025/>
* “Inside Zig's Incremental Compilation”, 2026-07-28 —
  <https://mlugg.co.uk/posts/incremental-compilation-internals/>
* Zig source at tag `0.17.0` —
  <https://codeberg.org/ziglang/zig/src/tag/0.17.0>
  (specifically `src/Compilation/Config.zig`, `src/target.zig`,
  `src/Zcu.zig`, `src/Zcu/PerThread.zig`, `src/Air/Liveness.zig`,
  `src/Air/Legalize.zig`, `src/codegen.zig`,
  `src/codegen/x86_64/{CodeGen,Mir,Emit,Lower,abi}.zig`,
  `src/codegen/aarch64/{Select,Assemble,Mir,abi}.zig`,
  `src/codegen/llvm.zig`, `src/link.zig`, `src/link/Elf2.zig`,
  `src/link/MappedFile.zig`, `src/InternPool.zig`)
* Git tags/commit dates —
  <https://codeberg.org/ziglang/zig/tags>
* Mach-O default gate issue —
  <https://codeberg.org/ziglang/zig/issues/35267>

Bend sources at `f46ad0f6`:

* `bend2/comp.ts:3110-3155` (`compile_book` fixed point)
* `bend2/main.ts:398-460` (clang selection/`-O3`)
* `bend2/selfhost/checked_frontend.bend:17-18` (`CheckedProgram`)
* `bend2/selfhost/checker_arena.bend:5-31` (dense arena)
* `bend2/selfhost/backend_ir.bend:216-234` (`Code`/`Program`)
* `bend2/selfhost/backend_lower.bend:1943-1965` (`lower`)
* `bend2/selfhost/lower_catalog.bend:27-28,1467` (`Catalog.build`)
* `bend2/selfhost/c_emit.bend:71-102`
* `bend2/selfhost/c_emit_core.bend:93-114`
* `bend2/selfhost/c_backend.bend:11-41,3173-3209`
* `bend2/selfhost/c_backend_link.bend:1-12`
* `bend2/selfhost/js_emit.bend:20-33`; `bend2/selfhost/js_backend.bend:1139-1160`
* `evals/native_compiler_llvm.ts:73-100` (existing C→LLVM split lane)
* `evals/heavy_gate.ts` (resource guard)

Peer notes (read, not edited): `RESEARCH_LLVM.md` in
`/private/tmp/bend-llvm-research`, `RESEARCH_MLIR.md` in
`/private/tmp/bend-mlir-research`, `RESEARCH_GPU.md` in
`/private/tmp/bend-gpu-research57ab`.
