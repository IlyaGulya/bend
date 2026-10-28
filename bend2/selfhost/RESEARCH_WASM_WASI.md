# Research: WebAssembly and WASI as targets for current Bend BIR

Status: research only, 2026-10-24. Baseline commit `f46ad0f6`
(`work/wasm-wasi-research57ab`, worktree `/private/tmp/bend-wasm-research`).
Nothing in this note is an implementation, an acceptance result, or a target
cutover; no build, test, benchmark, or repo source was changed.

Label convention:

- **[S]** a claim read in a primary source (official spec/docs, upstream repo
  source, this repository's source).
- **[M]** a measurement made locally on 2026-10-24 (Apple clang 21.0.0,
  `wasm32`/`wasm64` backends); no repo program was built or run.
- **[I]** engineering inference from [S]/[M]; not measured, not accepted.

Related notes (do not duplicate):

- LLVM path and BIR→LLVM mapping: `bend2/selfhost/RESEARCH_LLVM.md`
  (branch `work/llvm-research`). That note owns `musttail`/`tailcc`, the
  BIR→LLVM instruction mapping, and the native-word-addressing obstacle.
- MLIR/`wasmssa` path: `bend2/selfhost/RESEARCH_MLIR.md`. That note owns the
  MLIR dialect fit, region/`LeaveRegion` mismatch, and the
  LLVM-IR-to-wasm route.
- GPU status: `bend2/selfhost/RESEARCH_GPU.md`. It records that no BIR→GPU
  lowering exists, that lowering erases `Bang` (`backend_lower.bend:1353-1354`),
  and that only legacy `c_runtime.c` GPU text exists. This note therefore does
  not treat GPU as reachable from BIR; see §6.6 for the wasm-specific GPU
  statement only.

## 0. Bottom line

1. **WebAssembly and WASI are different questions.** Core wasm is an
   instruction/memory/trap sandbox with no I/O; WASI is a host ABI that supplies
   files, clocks, randomness, args, and (in later previews) networking. A pure
   wasm module can have zero imports; an executable that prints must import
   something (WASI, JS, or a custom host).
2. **Current BIR is semantically single-threaded.** `BIR.Op` has no parallel or
   fork operation (`backend_ir.bend:178-192`), and lowering erases `Bang`.
   Runtime worker threads and the GPU lane are implementation strategies, not a
   BIR semantics requirement. A single-threaded wasm target is therefore
   semantically plausible before any threads work, subject to the channel/IO
   scheduler and effect-timing questions in §11.
3. **The existing C runtime cannot be compiled to `wasm32` as-is.** It reserves
   an 8 GiB corpus by default (`c_runtime.c:2108`), maps it with
   `MAP_NORESERVE` (`:1522-1525`), guards 2 GiB worker stacks with
   `mprotect(PROT_NONE)` and `SIGSEGV` (`:1535-1545`), and spawns
   `pthread_create` workers (`:1607-1618`). `wasm32` memory tops out at 4 GiB,
   wasi-libc's `<sys/mman.h>` requires an explicit emulation opt-in and ignores
   requested addresses, and its `mmap`/`mprotect` cannot express those calls
   (see §5). This is a runtime/ABI blocker, not an instruction-selection blocker.
4. **All candidate routes converge on one missing artifact: a wasm runtime
   profile of the Term ABI.** Direct wasm emission, C→wasm, BIR→LLVM→wasm, and
   BIR→MLIR→LLVM→wasm all still need a linear-memory heap, the ~100 primitive
   operations, closure/apply, descriptors/show, foreign effects, and bounded
   stack behavior. The LLVM and MLIR routes do not remove this work.
5. **Recommended first target:** a single-threaded `wasm32-wasip1` *command*
   built through the existing C emitter (`c_emit_core`/`c_backend`) with a new
   wasm runtime profile, covering **all BIR ops/primitives** and the WASI-p1
   subset of effects; unsupported effects must fail at target selection, not at
   runtime. Not browser first, not threads, not wasm64, not WASI p2/components.
6. **The C emitter is not accepted yet.** Its source exists
   (`c_backend.bend`, `c_emit_core.bend`, `c_emit.bend`), but the handoff records
   that no self-generated C backend / native-binary fixedpoint proof exists
   (`checkpoints/SELFHOST_HANDOFF.md:1009-1010`), and the current common
   generated emitter/root13 has body validation but no successful full
   native13/FP/C acceptance. A wasm acceptance can never be stronger than that
   base; wasm needs its own differential evidence (§9), not "C compiled".

### 0.1 WASM vs WASI at a glance

| Question | Core WebAssembly | WASI |
|---|---|---|
| What is it | instruction set, linear memory, tables, traps | a host ABI (Preview 1 syscalls; p2/p3 components) |
| Needed for a pure module with no I/O? | yes | **no** — a module can have zero imports |
| Needed for print/args/env/clock/random/files? | no by itself | **yes, or an equivalent host import set** (JS in a browser, custom host) |
| Available in a browser? | yes (JS API) | **no built-in WASI**; the page must supply imports |
| Available standalone? | needs a runtime (Wasmtime, Node, etc.) | Wasmtime supports p1/p2; Node supports p1 only |
| Covers all Bend effects? | n/a | **no** — p1 lacks socket creation, process spawn, audio/window; GPU is absent |
| Capability model | sandboxed memory/table access | preopens/args/env are explicit; host defines security (Node warns it is not a sandbox) |

So the useful formulation is: **"wasm for the code and sandbox; WASI (or a host
adapter) only for the effects that a particular deployment needs."**

## 1. What a target must preserve from current BIR

BIR is a closed structured ANF (`bend2/selfhost/backend_ir.bend`):

| Construct | Shape | Target obligation |
|---|---|---|
| `Atom` (`:13-25`) | Local/Capture/Symbol/Word/Natural/FloatBits/Text/Boolean/Null/Undefined | No hidden computation; a symbol/lazy read is a separate op, never a cached value |
| `Op` (`:178-192`) | Copy, PrimitiveCall, Closure, Direct, Apply, LoadSymbol, Construct, Project, HasTag | Strict, ordered `Let`; partial application is a Closure to a lifted adapter; over-application is an ordered sequence |
| `Block` (`:194-202`) | Return, Let, Branch, Region, LeaveRegion, TailDirect, TailApply, Failure | Structured control; `Region`/`LeaveRegion` are lexical forward exits; tail calls only as terminators |
| `Code` (`:203-208`) | captures prefix, parameters, body | Captures precede live parameters; erased operands do not exist |
| `Declaration` (`:209-232`) | Function, Lazy, Native, Foreign | Lazy declarations are re-read/re-evaluated; foreign declarations keep all declared source alternatives |
| `Program` (`:233-240`) | codes, declarations, constructors, families, type functions, ending | One closed program; IDs are program-global; `Executable` carries `main_type`, `Library` carries exports |

Important consequences for any wasm target:

- **Boxed `Term` vs target-specific layouts is an existing, intentional split.**
  The C backend's runtime ABI comment says Nat/U32/F32 are unboxed words, Bool is
  0/1, Data is `term_ctr`, Char is a packed scalar, String is the runtime `SCon`
  codepoint list, Array is `TAG_ARR`, and a callable is a one-short closure
  (`c_backend.bend:27-42`). The JS target instead exposes JS objects (`{$: ...}`),
  JS numbers/strings, and JS functions (`bend2/main.ts:1-10`). A wasm target
  chooses one; it does not need to match both.
- **Physical layout is a target instance of BIR laws L5/L7.** The C layout is
  specified in `c_backend_layout.bend:1-50`: nested fields expand, a node with
  zero or one 32-bit field is packed into the term payload, values inline up to
  eight words then box, Arrays/IO.OP/abstract types box, and the show descriptor
  is written in those same word offsets. Any wasm runtime that runs C-emitted
  code inherits this exactly; a direct wasm emitter that invents another layout
  must also re-implement the show descriptor interpretation.
- **Descriptors are data, not executable ops.** `Descriptor` (`:152-176`) is
  interpreted by `show`; the C runtime carries `SHOW_DESC`/`SHOW_NAMES` and a
  `show_val` interpreter (`c_runtime.c:2632-2735`). A wasm target must ship the
  descriptor table and the same text output.
- **`PrimitiveCall` is a large closed set (~100 names, `:33-150`).** C lowers it
  to operators, libm calls, and runtime helpers such as `U32_BIN`, `nat_chk`,
  `f32_unbox/rewrap`, `bend_array_*`, `bend_str_*` (`c_backend.bend:1460-1576`).
  Direct wasm emission must provide every one or report it unsupported; the C
  route gets them from the C runtime plus libm.
- **`Failure{message}` is not a wasm trap in the current C meaning.** C renders
  it as `err_post(ERR_TAGS)` → `err_fail("runtime fail-stop")` → stderr + exit 1
  (`c_backend.bend:2229-2230`, `c_runtime.c:476-484`). The message text itself is
  not surfaced by the C runtime. A wasm target must decide the observable mapping
  (trap vs message+exit) and test it; silently using `unreachable` changes the
  observation.

Law inventory used below (source: `checkpoints/SELFHOST_IR_ARCHITECTURE.md:202-234`):
F1-F3, L1-L7, B1-B2, G1-G2, K1-K5. Target-specific instances are in §9.

## 2. The runtime ABI any C-based wasm route inherits

`bend2/selfhost/c_runtime.c` is a generated snapshot of the official compiler's
runtime: "Generated by `evals/gen_c_runtime.ts` from `bend2/comp.ts` runtime_c." and
"Do not hand-edit: regenerate." (`c_runtime.c:1-5`; generator pins both hashes and
says `comp.ts`/`bend.ts` are never modified, `evals/gen_c_runtime.ts:1-30`). The
C emitter takes the runtime as a *path* and fills marker sections
(`c_emit.bend:71-102`, `c_backend.bend:9-26`), so a different runtime source is
possible at the tooling level, but it must satisfy the whole ABI.

### 2.1 Representation (all [S])

- `typedef u64 Term` (`:191`); tags `TAG_PAK/CTR/CLO/BUF/TSK/ARR` (`:214-219`).
- Low 40 bits hold a **word offset** (`LOC_MASK`, `:222`), not a byte address;
  `term_loc` is used as `H[loc]`. 40 bits of 8-byte words is up to 8 TiB of
  addressable heap [I], but the actual span is the corpus mapping.
- 48-bit immediate Naturals (`NAT_IMM`, `:225`); Nat past that is an error
  (`ERR_NATS`). Reference counts are 24-bit (`RFC_CNT`, `:225`); more than
  2^24-1 live copies is an error (`ERR_CNTS`, `:465-475`).
- `Env {u64* mem; u64* alc}`, banks per class, and a work-stealing ring/task
  protocol. The dispatch is a threaded switch of `preserve_none` segments
  entered with `musttail` (`:130-167`), with an indirect `wl_tab` (`:1161-1166`).

### 2.2 Address space, heap, threads, signals (all [S])

- CPU corpus default `size = 1ull << 33` = **8 GiB** (`:2108`), laid out as
  rings/stacks/heap (`corpus_lay`, `:2072-2101`). Growth doubles the mapping up
  to `1ull << 43` bytes (`corpus_grow`, `:2090-2103`) when the next range can be
  mapped contiguously.
- Static lane arrays: with `CUBE_T=128`, `RING_LEN=1<<(17-CUBE_LOG)` and
  `RING_WORDS=(1<<10)+2` (`:240-258`), the ring is `16384*1026` words ≈ 128.3
  MiB and the stack arena is `16384*2048` words = 256 MiB; plus ALC and stats,
  roughly **0.4 GiB of static arena before the heap** [I, computed from
  `:240-273`].
- Each worker maps a 2 GiB stack plus guard and installs `sigaltstack` +
  `SIGSEGV/SIGBUS` handlers (`:1522-1545`), then `pthread_create` for workers
  (`:1607-1618`) and an IO helper (`:2500-2501`).
- `MAP_NORESERVE` is used for every pool mapping (`:1522-1525`); corpus growth
  relies on mapping a larger contiguous range and copying banks
  (`corpus_lay`, `:2072-2101`), i.e. virtual-address reservation semantics.

### 2.3 IO model and foreign handles (all [S])

- IO is an activation queue: `IoWork` carries a host handle, continuation, item,
  deadline, and pack/call functions; effects register in `io_eff_rows` by
  `CID(<key>)` (`c_runtime.c:2159-2210`; effect sources in `bend2/effs/*.c`).
- A host handle is packed into a `TAG_PAK` Term: high bits go to `aux`
  (`(u64)v >> 40`) and low 40 to `loc` (`:2180-2181`). On wasm32, `intptr_t` is
  32-bit, so pointer/fd values fit `loc` exactly; the packing remains meaningful
  [I].
- Effect code receives `Env` and `Term*` and returns a Term
  (`IoWork`/`io_work`/`io_res`, `bend2/effs/*.c`). It may read, keep, or drop
  through runtime helpers, but retaining a Term past the call without
  `term_keep` would violate sharing. Returning a fresh Term is the only
  ownership transfer. A wasm import adapter must preserve this discipline
  exactly; this is the foreign-ABI instance of B1/B2.
- Channels and `IO.spawn` are **cooperative activations**, not OS threads
  (`bend2/effs/chan.c:1-120`, `spawn.c`), so their semantics do not inherently
  require pthreads; the event loop does.
- Native `IO.now` is `clock_gettime(CLOCK_MONOTONIC)/1e6` (`c_runtime.c:1481-1485`),
  i.e. monotonic milliseconds, not wall-clock time. `IO.sleep` parks on a
  monotonic deadline (`bend2/effs/sleep.c`).

### 2.4 Show, floats, and error text (all [S])

- `show_val` interprets `SHOW_DESC` and writes via `printf`/`fwrite`
  (`c_runtime.c:2632-2735`). `f32_text` builds the shortest round-tripping text
  using `snprintf("%.*e")` + `strtof` in a loop (`:2573-2601`); this depends on
  libc float formatting/parsing.
- `Failure` and runtime errors exit with `bend: <text>` to stderr (`:476-484`);
  error codes include heap, nat, refcount, array depth, and fault (`:465-475`).

### 2.5 Acceptance status

Source presence is not execution proof. The handoff says "Neither emitted-JS
proof establishes a self-generated C backend or a native-binary fixedpoint"
(`checkpoints/SELFHOST_HANDOFF.md:1009-1010`), and the current brief records
body validation for the common emitter/root13 without a successful full
native13/FP/C acceptance. No claim in this note may be read as a C or wasm PASS.

## 3. Local toolchain measurements (clang 21.0.0, Apple, 2026-10-24)

| Probe | Result |
|---|---|
| `clang -print-targets` | includes `wasm32` and `wasm64` [M] |
| `__attribute__((musttail)) return f(x)` on wasm32 with `-mtail-call` (`-O0`, `noinline`) | compiles; `-S` emits `return_call f` [M] |
| same **without** `-mtail-call` | warning `unknown attribute 'musttail' ignored`; ordinary call, no tail-call feature [M] |
| signature-matched indirect musttail (`u64(*)(u64)` table) with `-mtail-call` (`-O0`) | emits `return_call_indirect __indirect_function_table, (i64)->(i64)` [M] |
| mismatched indirect musttail | hard error: "signature is incompatible with the calling function" [M] |
| `preserve_none` / `preserve_most` on wasm | warning, attribute ignored [M] |
| `--target=wasm32-wasip1` with `#include <stdio.h>` and no sysroot | `fatal error: 'stdio.h' file not found` [M] |
| default target features emitted for a wasm32 object | bulk-memory, bulk-memory-opt, call-indirect-overlong, multivalue, mutable-globals, nontrapping-fptoint, reference-types, sign-ext; `tail-call` added by `-mtail-call` [M] |
| wasi-sdk installed locally | no (`/opt/wasi-sdk` absent); wasmtime/wasmer absent; Node and Bun present [M] |

Implications:

- The runtime's `WL_JMP`/`WL_DYN` macros (`c_runtime.c:140-141`) have the uniform
  `WL_SIG` signature, so signature-matched indirect `musttail` is exactly the
  supported case. Without `-mtail-call` the attribute is silently dropped:
  deep tail-recursive Bend programs would then grow the wasm shadow stack and
  trap. This is an L6 target obligation, not an optimization.
- Compiling the C pipeline for wasm needs a wasi sysroot (wasi-sdk or an
  equivalent sysroot + `libclang_rt.builtins-wasm32.a`, as the wasi-libc README
  documents); a host clang alone is not enough.

## 4. WebAssembly platform facts that bound the design

### 4.1 Is "core wasm 3.0" enough, and where is it standardized?

- The current spec is **WebAssembly 3.0** (change history page dated
  2026-10-23) and is backwards-compatible with prior versions
  ([spec change history](https://webassembly.github.io/spec/core/appendix/changes.html)).
- Finished proposals (spec version 3.0) include **tail calls, memory64,
  exception handling, GC, multiple memories, extended const, typed function
  references, relaxed SIMD**
  ([finished proposals](https://raw.githubusercontent.com/WebAssembly/proposals/main/finished-proposals.md)).
- **Threads is not finished**: it is Phase 4 ("Standardize the Feature") in the
  active list, so atomics/shared memory are widely implemented but not merged
  into the latest draft. **Component model** is Phase 1 there; **shared-everything
  threads** Phase 1 ([active proposals](https://raw.githubusercontent.com/WebAssembly/proposals/main/README.md)).
- Consequence: use of tail calls/memory64/EH/GC is feature-gated per engine, and
  "standardized" is not "universally available". Do not assume availability from
  the spec version alone [I].

### 4.2 Memory width and limits

- wasm32 (32-bit indices) has a hard maximum of 4 GiB of linear memory; the V8
  post explains the 2 GiB→4 GiB history and that the toolchain must opt in with
  `ALLOW_MEMORY_GROWTH`/`MAXIMUM_MEMORY=4GB` in Emscripten's case
  ([V8, 2020-05-14](https://v8.dev/blog/4gb-wasm-memory)). Initial/max memory is
  a linker/host setting, not a language default [S/I].
- memory64 exists and is Phase 5/spec 3.0, but availability is uneven:
  Chrome 133 (2025-02-04) shipped it
  ([Chrome 133 release notes](https://developer.chrome.com/release-notes/133));
  WebKit's implementation bug is still **NEW** when checked on 2026-10-24
  (reported 2025-10-10, last modified 2026-06-05), and its text explicitly
  describes reaching "parity with Chromium and Firefox on all Phase 5
  standardised WebAssembly features"
  ([WebKit bug 300538](https://bugs.webkit.org/show_bug.cgi?id=300538)).
  So Chromium and Firefox expose memory64, while WebKit did not at that date [S].
- Toolchain gap: wasi-sdk does **not** support wasm64 targets; its README says
  64-bit linear memories "are not supported at this time", requires resolving
  component-model#22, and there are no plans for `wasm64-wasi{,-threads,p1,p1-threads}`
  ([wasi-sdk README](https://github.com/WebAssembly/wasi-sdk)).
- Wasmtime supports memory64 for core modules at Tier 1, but the component-model
  memory64 feature gate is work-in-progress and off by default
  ([Wasmtime proposal matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html)).
- Consequence: >4 GiB heap requires wasm64 *and* a toolchain/host that supports
  it; the current Bend C runtime's 8 GiB default is outside wasm32, and wasi-sdk
  cannot produce a wasm64 build today [S/I].

### 4.3 Tail calls and stack

- Tail calls are Baseline Newly available across major browser engines
  (web.dev, 2025-01-29:
  [WasmGC and tail calls Baseline](https://web.dev/blog/wasmgc-wasm-tail-call-optimizations-baseline)),
  and Wasmtime lists tail-call at Tier 1 ([matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html)).
- On the toolchain side, `musttail` requires the `-mtail-call` feature; without
  it clang ignores the attribute [M]. With it, direct and signature-matched
  indirect tail calls become `return_call`/`return_call_indirect` [M].
- Wasm runtimes impose a finite call-stack limit (host-configurable); there is no
  portable `SIGSEGV`-style stack-overflow handler inside the module [I]. The
  native runtime reports stack overflow via an alternate signal stack
  (`c_runtime.c:1535-1545`); wasm can only trap or use an explicit stack-depth
  check. This is an observable difference that needs a defined behavior (§9).

### 4.4 NaN and floating point determinism

The spec says numeric operators are non-deterministic where they may return
different NaN values: "Following the recommendation that operators propagate NaN
payloads from their operands is permitted but not required"
([WebAssembly numerics](https://webassembly.github.io/spec/core/exec/numerics.html)).
Rounding is round-to-nearest ties-to-even; directed rounding and status flags are
not supported [S].

Bend exposes raw float bits (`PrimF32Bits`, `PrimF32FromBits`, `PrimF32ToWord`)
and bit equality (`PrimFloatBitsEqual`). If a program computes a NaN and observes
its bits, wasm allows a different payload from native hardware, and different
engines may pick different allowed NaNs. `show` prints "nan" for `v != v`
(`c_runtime.c:2576-2578`), so text output is stable, but bit-level observations
are not portable. This is a B1/B2 target instance, not a bug to "fix" by
inventing one NaN.

### 4.5 JS interop (browser or Node embedding)

- The JS API maps wasm `i64` to JS `BigInt` and rejects a non-BigInt for an i64
  import/global (LinkError); `i32/f32/f64` map to `Number`
  ([JS API spec, ToWebAssemblyValue](https://webassembly.github.io/spec/js-api/)).
  A `Term` is 64-bit, so every wasm library export taking/returning a Term is an
  i64/BigInt boundary in JS. The current JS target instead exposes Nat as a JS
  number and constructors as objects (`bend2/main.ts:1-10`), so a wasm library
  ABI is a new public ABI, not a drop-in replacement.
- Closures/functions become table entries (`funcref`) and indices, not JS
  functions. Strings/constructors live in linear memory, not JS strings/objects;
  conversion requires a descriptor-driven encoder/decoder or a string/number-only
  boundary.
- Imported JS functions are synchronous; asynchronous host work needs the JS
  Promise Integration proposal (Phase 5 active but not merged; see proposals
  list) or an explicit async wrapper/Asyncify-style transform. The current Bend
  effects are written in a synchronous style over an event loop, which fits a
  synchronous host better than a promise-based one [I].
- Browser threads require `SharedArrayBuffer`, which browsers gate behind COOP
  and COEP headers; `Atomics.wait` is not allowed on the browser main thread, so
  blocking pthread primitives cannot run there. Emscripten documents these
  restrictions and also that it does not support POSIX signals or
  `fork()`/`join()`
  ([Emscripten pthreads docs](https://emscripten.org/docs/porting/pthreads.html)).
- `memory.grow` detaches/replaces the JS `ArrayBuffer` view; glue code must
  refresh views (documented in the V8 post above and Emscripten docs). Any wasm
  host adapter must not cache a stale view.

### 4.6 Feature availability, stated conservatively

| Feature | Standard | Browser/JS | Standalone (Wasmtime) | Needed here? |
|---|---|---|---|---|
| tail calls | 3.0 (finished) | Baseline newly available (2025) | Tier 1 | yes, for bounded tail recursion |
| memory64 | 3.0 (finished) | Chrome 133+, Firefox; WebKit bug still NEW on 2026-10-24 [S] | core Tier 1; component gate WIP | only if >4 GiB |
| threads/atomics | Phase 4 (not merged) | widely shipped; needs COOP/COEP in browsers | Tier 2, WIP/not fuzzed, shared-memory caveats | not for first target |
| GC | 3.0 (finished) | Baseline newly available | Tier 1 | not for Term-in-linear-memory design |
| exception handling | 3.0 (finished) | engine-dependent | Tier 1 | not needed; `Failure` is fail-stop |
| multi-memory | 3.0 (finished) | engine-dependent | Tier 1 | not needed (one memory) |
| component model | Phase 1 in CG; shipped in Wasmtime | not in Node's WASI (p1 only) | enabled by default in Wasmtime, not Phase 4 [S] | only for p2/p3 route |

## 5. WASI: what it is, which preview, what it provides

### 5.1 Previews and ABIs

- WASI started with **Preview 1** (`wasi_snapshot_preview1`, witx, widely used);
  **WASI 0.2** is a modular WIT collection on the Component Model; **WASI 0.3**
  is the current preview, adding component-model `async`, `stream`, and `future`
  ([WASI README](https://raw.githubusercontent.com/WebAssembly/WASI/main/README.md)).
- Component model releases: 0.2.0 (first component-model release, resources,
  WIT, linking), 0.3.0 (async/futures/streams), 0.3.1 (`map<K,V>`, annotations);
  cooperative threads remain a future gated feature
  ([component-model README](https://raw.githubusercontent.com/WebAssembly/component-model/main/README.md)).
- **Core-module ABI vs canonical ABI.** Preview 1 is a core-module ABI: imports
  are functions with i32/i64 parameters and pointers into linear memory. Preview
  2/3 are *components*: the Canonical ABI maps component-level values to core
  function signatures and reads/writes linear memory (strings/lists are memory
  ranges; resources are handles) ([Canonical ABI explainer](https://raw.githubusercontent.com/WebAssembly/component-model/main/design/mvp/CanonicalABI.md)).
  wasi-libc's startup makes the split concrete: `wasm32-wasip1` exports
  `_start(void)`, while `wasm32-wasip2`/`p3` export
  `wasi:cli/run@0.2.12#run` / `wasi:cli/run@0.3.2#run`
  ([crt1-command.c](https://raw.githubusercontent.com/WebAssembly/wasi-libc/main/libc-bottom-half/crt/crt1-command.c)).
  Wasmtime's book likewise says core modules receive arguments via WASIp1 APIs
  and components via WASIp2+ ([WASIp1](https://docs.wasmtime.dev/examples-wasip1.html),
  [WASIp2](https://docs.wasmtime.dev/examples-wasip2.html)).
  For Bend this means a p2/p3 target would either import WIT interfaces through
  generated bindings or wrap a core module as a component; in both cases
  `Term`-shaped Bend values must be lowered to WIT values/resources (or stay
  inside the core module behind a thin binding). That is a new ABI layer, not a
  flag flip from p1.

### 5.2 Preview 1 surface (the practical first ABI)

The Preview 1 WITX surface ([docs](https://raw.githubusercontent.com/WebAssembly/WASI/wasi-0.1/preview1/docs.md))
includes: `args_get/sizes`, `environ_get/sizes`, `clock_res_get/time_get`,
`fd_*` (read/write/pread/pwrite/seek/tell/close/sync/datasync/advise/allocate/
fdstat/filestat/readdir/renumber/prestat), `path_*` (open/create_directory/
filestat/link/readlink/remove_directory/rename/symlink/unlink_file),
`poll_oneoff`, `proc_exit`, `proc_raise`, `random_get`, `sched_yield`, and
`sock_accept/recv/send/shutdown`.

What that means, precisely:

- **No socket creation.** `sock_accept` accepts on a listening socket
  (`docs: sock_accept`), but Preview 1 has no `sock_open`/`connect`/`listen`/
  `bind`, so a WASI p1 guest cannot initiate networking. wasi-sdk states WASIp1
  targets do not support networking; p2/p3 do
  ([wasi-sdk README](https://github.com/WebAssembly/wasi-sdk)).
- **No process creation.** There is `proc_exit`/`proc_raise` but no fork/exec/
  posix_spawn syscall; `process_run` cannot be ported to p1.
- **No signal handling.** p1 has `proc_raise` but no sigaction/sigaltstack/kill,
  so a guest cannot install or recover from signal handlers; wasm itself has
  traps, not POSIX signals. Emscripten also documents no POSIX signal support in
  wasm ([Emscripten pthreads](https://emscripten.org/docs/porting/pthreads.html)).
- **No memory mapping.** p1 has no mmap. In wasi-libc, `<sys/mman.h>` is a hard
  `#error` unless the build opts in with `-D_WASI_EMULATED_MMAN` and links
  `-lwasi-emulated-mman` ([sys/mman.h](https://raw.githubusercontent.com/WebAssembly/wasi-libc/main/libc-top-half/musl/include/sys/mman.h)).
  The emulation allocates with malloc/pread, **ignores the requested address**,
  and explicitly rejects `MAP_FIXED`, `MAP_NORESERVE`, `PROT_NONE`/`PROT_EXEC`,
  and partial `munmap` ([mman.c](https://raw.githubusercontent.com/WebAssembly/wasi-libc/main/libc-bottom-half/mman/mman.c)).
  `mprotect` only accepts `PROT_READ|PROT_WRITE` and is a no-op [S].
- **Files are capability-gated.** p1 exposes preopened directories
  (`fd_prestat_get`, `prestattype::dir`) and `path_open` relative to a dirfd;
  there is no ambient root filesystem. Args/env are explicit host inputs.
  Node's docs describe the same capabilities-based model and warn that Node's
  implementation is not a security sandbox
  ([Node WASI](https://nodejs.org/api/wasi.html)). "WASI" by itself is therefore
  not a security guarantee: the host implementation defines the boundary, and
  capability failures must surface as the effect contract's `Fail`, not as a
  host-specific exception.

### 5.3 Threads in WASI/libc

- `wasi-threads` is a legacy Phase 1 proposal, retained for preview1-only
  engines; the future direction is shared-everything-threads, and wasi-libc has
  an implementation used by `wasm32-wasip1-threads`
  ([wasi-threads README](https://raw.githubusercontent.com/WebAssembly/wasi-threads/main/README.md)).
- wasi-libc defines `pthread_*` on **all** targets, but behavior differs:
  `wasm32-wasip{1,2}` return errors or trap (e.g. spawning fails, condvar blocking
  traps); `wasm32-wasip1-threads` really spawns via wasi-threads and blocks with
  `memory.atomic.*`; `wasm32-wasip3` with `-DENABLE_COOP_THREADS=ON` uses
  cooperative component-model threading
  ([wasi-libc README](https://github.com/WebAssembly/wasi-libc)).
- Cooperative threading is experimental and off by default in wasi-sdk; Wasmtime
  supports it behind `-Wcomponent-model-threading`, with an intent to make it
  default before the end of 2026, subject to a WASI vote
  ([CoopThreading.md](https://raw.githubusercontent.com/WebAssembly/wasi-sdk/main/CoopThreading.md)).
- Wasmtime lists core threads at Tier 2 with a work-in-progress "Finished"
  column, no fuzzing, and known shared-memory/resource-limiting issues
  ([matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html)).

### 5.4 wasi-sdk target and limitation matrix (as of the fetched README)

| Target | Meaning | Limitation relevant here |
|---|---|---|
| `wasm32-wasip1` | Preview 1, default | no networking, pthread stubs (spawn fails) |
| `wasm32-wasip2` | Preview 2 + component model | no default thread spawning; networking available |
| `wasm32-wasip3` | Preview 3 + async component model | pthreads only with experimental coop sysroot |
| `wasm32-wasip1-threads` | Preview 1 + experimental thread spawning | wasi-threads; experimental |
| `wasm32-wasi` / `wasm32-wasi-threads` | removed as of wasi-sdk 34 | use wasip1 names |
| wasm64 targets | **not supported** | blocks >4 GiB wasm route |

Other stated limitations: C++ exceptions are off by default and require
`-fwasm-exceptions -mllvm -wasm-use-legacy-eh=false -lunwind`; `setjmp`/`longjmp`
need extra configuration; dynamic linking is less complete than static; the
default sysroot is built with `-mcpu=lime1`
([wasi-sdk README](https://github.com/WebAssembly/wasi-sdk),
[CppExceptions.md](https://raw.githubusercontent.com/WebAssembly/wasi-sdk/main/CppExceptions.md)).

### 5.5 Host runtimes

- **Wasmtime** supports WASIp1 core modules and WASIp2 components, and lists
  tail-call/memory64/GC/EH/multi-memory at Tier 1, threads at Tier 2, component
  model enabled by default though not Phase 4
  ([proposal matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html),
  [WASIp1](https://docs.wasmtime.dev/examples-wasip1.html),
  [WASIp2](https://docs.wasmtime.dev/examples-wasip2.html)).
- **Node.js** `node:wasi` is Stability 1 (Experimental), supports only
  `preview1`/`unstable` (no components), and explicitly does not provide the
  filesystem sandboxing of some WASI runtimes
  ([Node WASI](https://nodejs.org/api/wasi.html)).
- **Browsers** expose the JS WebAssembly API, not WASI; a browser deployment must
  supply imports from JS. No WASI preview is part of the browser API [S/I].
- wasi-sdk documents that `pthread_create`-style spawning is not available on
  most targets, and that networking is p2/p3-only (above).

## 6. Feasibility against THIS BIR

### 6.1 The blocker table for "compile the emitted C with wasi-sdk as-is"

| Runtime requirement | Evidence | wasm32-wasip1 result | Verdict |
|---|---|---|---|
| 8 GiB default corpus | `c_runtime.c:2108` | wasm32 max 4 GiB [S] | impossible |
| contiguous grow via relocation/lay | `corpus_lay/grow`, `:2072-2103` | linear memory grows at end; no remap/copy of banks as designed; wasi-libc `mmap` is malloc emulation | incompatible |
| `mmap(..., MAP_NORESERVE)` | `:1522-1525` | `<sys/mman.h>` is a hard `#error` without `-D_WASI_EMULATED_MMAN`; the emulation ignores the hint and rejects `MAP_NORESERVE` with EINVAL [S] | immediate `reservation failed` |
| `mmap` hinted addresses + partial `munmap` | `corpus_at`, `:2054-2066` | wasi-libc emulation always mallocs and ignores the address; no partial munmap [S] | corpus layout/growth incompatible |
| 2 GiB worker stacks + `mprotect(PROT_NONE)` guard | `:1535-1545` | wasi-libc `mprotect` only RW, `PROT_NONE` ENOTSUP [S] | impossible |
| `sigaltstack`/`sigaction(SIGSEGV)` error reporting | `:1541-1545` | no POSIX signals in wasm/p1 [S] | impossible |
| `pthread_create` worker pool + IO helper | `:1607-1618`, `:2500-2501` | p1/p2 stubs; only experimental `wasip1-threads`; single-thread has no spawn [S] | incompatible for p1/p2 |
| `musttail` dispatch | `:140-141` | needs `-mtail-call`; otherwise ignored [M] | fixable with flags, must be verified |
| `preserve_none`/`preserve_most` | `:107-141` | ignored on wasm (warning) [M] | harmless but no register guarantee |
| `_Atomic`/`__atomic` u64 ops | `:417`, `a32_*` | compiles with/without `-matomics`; atomics need thread feature to be meaningful [M] | fixable; not needed single-thread |
| Objective-C/Metal/CUDA/`#embed` | `:296-316`, `:1668-1970` | not applicable/no sysroot; guarded by GPU macros | exclude in profile |
| sockets/process/audio/window effects | `bend2/effs/*.c` | absent/insufficient in p1 [S] | unsupported subset |

Conclusion: **compiling `c_runtime.c` unchanged for wasm is not possible.** The
problem is the runtime's virtual-memory/thread/signal model plus its corpus size,
not clang's wasm backend.

### 6.2 What is portable without change

- The 64-bit `Term` word and its tag/loc/RC/Nat layout: wasm has i64 and the C
  ABI passes `u64` as `i64` [M]. On wasm32 all pointers/fds fit the 40-bit loc
  field [I].
- The closure/callable convention (a one-short closure plus a code entry) is
  representable as linear-memory words plus a wasm funcref/table index [I].
- The show descriptor format is plain data; the interpreter is ordinary C [S].
- Strict `Let` order, pattern/tag/field operations, and primitives are expressible
  in wasm instructions/C [I].
- The C emitter's output is one translation unit; one wasm module is the natural
  packaging (consistent with BIR's program-global IDs and one generated table
  set) [I]. Multi-module wasm object linking is not required and would collide
  with the global-ID/table design.

### 6.3 Primitives: the real surface area

`BIR.Primitive` has about 100 constructors (`backend_ir.bend:33-150`). C maps
most to operators/libm and the rest to runtime helpers
(`c_backend.bend:1460-1576`), including: U32 arithmetic/shift semantics with
divide-by-zero→0 and shift≥32→0; Nat checked arithmetic with a 2^48-1 immediate
limit; F32 libm (`asin/acos/atan/sinh/cosh/tanh/exp/log/log2/log10/pow/atan2/
floor/ceil/trunc/sqrt/fabs/fmod`); F32 bits and show/read; strings (`SCon`
codepoint list, append, eq, cmp, head/tail, length, list conversion, Unicode
show); arrays (TAG_ARR tree: new/get/set/swap/size/clone/leaf/node/left/right);
Map bit; Word; Char packing/code; Bool predicates; `SameValue` and
`FloatBitsEqual`. A direct wasm emitter must implement all of these; the C route
reuses them. This is the main reason to prefer the C route for a first target.

### 6.4 Effect coverage matrix for a WASI-p1 first target

| Bend foreign key (source) | Host operation today | WASI p1 mapping | Status |
|---|---|---|---|
| `IO.print`, `IO.print_err` (`print.c`, `print_err.c`) | `io_out(stdout/stderr)` | `fd_write` 1/2 | portable, byte-exact |
| `IO.args` (`args.c`) | `io_argv[1..]` | `args_get` (must skip argv[0]) | portable with argv0 rule |
| `IO.get_env` (`get_env.c`) | `getenv` | `environ_get` | capability-provided env |
| `IO.now` (`now.c`) | monotonic ms (`io_tick`) | `clock_time_get(monotonic)` | portable if monotonic id used |
| `IO.sleep` (`sleep.c`) | monotonic park | `poll_oneoff` clock subscription | portable |
| `IO.random_u32` (`random_u32.c`) | `getrandom`/`arc4random` | `random_get` | portable |
| `IO.thread_count` (`thread_count.c`) | pool size | constant 1 in single-thread profile | must be truthful, not faked as CPU count |
| `File.open/read/write/size/close` (`file_*.c`) | `open/read/write/fstat/close` | `path_open/fd_read/fd_write/fd_filestat_get/fd_close` | portable inside preopens; paths/rights policy needed |
| `IO.spawn`, `Chan.*` (`spawn.c`, `chan.c`) | runtime activation queue | internal, no host syscall | portable only if the event loop is preserved |
| `Socket.*`, `TCP.*`, `UDP.*` (`socket_*.c`, `tcp_*.c`, `udp_*.c`) | BSD sockets | p1 has only accept/recv/send/shutdown on inherited fds | unsupported in p1 |
| `Process.*` (`process_run.c`) | spawn/wait/pipes | no process creation | unsupported |
| `Audio.*`, `Window.*` (`audio*.c`, `window*.c`) | platform audio/X11/Metal | no WASI interface | unsupported (host-specific imports only) |

This is the honest boundary: a p1 target is **not** a complete Bend deployment,
and must reject unsupported foreign declarations at compile/link time (the
existing target pattern already does this: C picks the first `.c` alternative,
JS the first `.js` alternative, `c_emit_core.bend:33-40`, `js_backend.bend:26-33`;
a miss is a diagnostic, never undefined success). Adding wasm alternatives (for
example a distinct extension) is the mechanism that keeps B2/G2 honest.

One extra p1 policy decision is unavoidable: native `File.open` takes a host
path and calls `open(path, ...)`, while p1 `path_open` is relative to a preopened
directory fd. A wasm profile must either (a) require every Bend path to be
preopen-relative and split it into `(dirfd, relative)` with a documented error
for an un-preopened path, or (b) interpose a host shim that exposes a synthetic
root. Both change observable error codes/paths relative to native; the chosen
rule belongs in the effect contract, not in ad-hoc string rewriting.

### 6.5 Show and observable text

The C `show` path writes to `stdout` with `printf`/`fwrite`; a wasm p1 profile
would write to fd 1. Equality of output is the L7/B1 obligation. The risky part
is float text: `f32_text` loops `snprintf("%.*e")` until `strtof` round-trips
(`c_runtime.c:2573-2601`). wasi-libc is musl-derived and typically correctly
rounded, but "typically" is not a proof; this needs differential tests on the
actual sysroot/runtime, including subnormals, signed zero, exponents at the
`>=21`/`<=-7` thresholds, and NaN/infinity. If the text differs, that is an L7
failure even if the numeric value is right.

### 6.6 GPU in a wasm world

There is no BIR→GPU lowering today (GPU note: BIR has no bang/parallel op,
`backend_lower.bend:1353-1354` erases `Bang`, and `c_backend` emits `BANGS 0`),
and no GPU in WASI p1. WASI's WebGPU proposal is Phase 2
([proposals](https://raw.githubusercontent.com/WebAssembly/WASI/main/docs/Proposals.md)),
not a shipping ABI. In a browser, `navigator.gpu` would be a JS import, not
wasm; in standalone WASI there is no GPU path. A wasm target must therefore
compile `!`-erased BIR exactly like the CPU path; claiming GPU parity is out of
scope. The legacy `c_runtime.c` Metal/CUDA text does not change this: it is
device code for the old runtime lane, not a BIR backend.

## 7. Options compared

Scoring is for *this* BIR and this repository, not for wasm in general.

| Option | How it works | Reuse of existing semantics | Runtime work | Toolchain / shipping | Main risks |
|---|---|---|---|---|---|
| **A. Direct wasm emitter** (BIR→binary/wat) | New renderer writes wasm instructions; own runtime library | None of C layout/primitives; must re-implement all ~100 primitives, heap, show, effects | Full runtime in wasm (or link a C runtime library) | no clang needed at build time; but need wasm-ld or object linking for libm/libc, or no libc at all | L5/L7/B1 divergence; sizeable new runtime; no libm; hard to debug |
| **B. C emitter + wasm runtime profile** (C→wasm via clang/wasi-sdk) | Reuse `c_backend`/`c_emit_core` output, supply a wasm-specific runtime source and effect set, compile with `--target=wasm32-wasip1` | Highest: same Term ABI, primitive C code, show interpreter, layout rules | New runtime profile: linear-memory heap/corpus, no mmap/signals/pthread, single-thread event loop, WASI effects | needs wasi-sdk sysroot; `-mtail-call`; wasm-ld; CLI compile step | runtime profile is substantial; C emitter itself unaccepted; toolchain pin; p1 effect gaps |
| **C. BIR→LLVM IR→wasm** | Peer note owns mapping; LLVM wasm backend emits, runtime C links via wasm-ld | Emitter reuse limited to runtime C; codegen re-done in LLVM IR | same wasm runtime profile as B | LLVM/clang; tailcc/musttail discipline | same runtime blocker; new LLVM emitter; longer path to first run |
| **D. BIR→MLIR→LLVM→wasm** | MLIR `wasmssa` is a target-level dialect (docs: "represent WebAssembly modules in SSA form"); the dialect docs do not document a wasm binary emitter, and the standard route remains LLVM IR→LLVM wasm backend | none extra; MLIR is infrastructure, not deployment | same runtime profile | LLVM toolchain, more IR layers | no wasm binary emitter in the `wasmssa` docs; `LeaveRegion`/`Failure` modeling mismatch (MLIR note); laws for a new IR |
| **E. Browser core module + JS imports (no WASI)** | wasm32 module imports JS functions; JS builds/decodes values | would share BIR but not the existing Node-oriented JS effects | needs browser host adapter + value ABI | bundler/JS glue; no WASI | async/sync mismatch; i64/BigInt; strings/objects conversion; COOP/COEP for threads; no existing browser effect library |
| **F. Status quo: JS target** | Checks→BIR→JS, runs on Node/Bun | already the accepted path | none | existing | not wasm (sandbox/portability absent); Node-oriented effects |

Why B is the recommended first target:

- It keeps the only currently encoded physical layout (`c_backend_layout.bend`)
  and the only full primitive mapping (`c_backend.bend:1460-1576`) as the
  semantic reference, so L5/L7/B1 do not get a second, silently diverging
  implementation.
- The C emitter already takes the runtime as a parameter
  (`c_emit.bend:71-102`, `driver.bend:20,132-160`), so the integration point is
  explicit and does not require touching BIR or the parser.
- wasm tail calls and i64 map cleanly to the existing dispatch and `Term` [M].
- Its cost is concentrated in one place (the runtime profile), which is also the
  place every other option needs work, so it is not duplicated effort.

Why not A/C/D first:

- A is the largest semantic risk and still needs a runtime/library.
- C/D do not remove the runtime profile; they add a new IR layer before the same
  blocker is solved. They become attractive if the project wants a durable
  multi-target IR/optimizer (MLIR) or to stop depending on C source as the codegen
  surface (LLVM). That is a separate architectural decision, not a wasm shortcut.
- E is the right *second* target if browser distribution is the product goal, but
  it needs a browser effect layer and a value ABI that do not exist today. The
  current JS runtime is Node/Bun-oriented (`bend2/comp.ts:1-10`, `:6566+` uses
  `fs`; `bend2/effs/*.js` use `process`, worker threads, `bun:ffi`).

### 7.1 Is MLIR (or LLVM IR) a better fit?

For the *deployment* question, no route through MLIR or LLVM changes the wasm
runtime/ABI work described in §6; both still need the wasm runtime profile, so
neither is a shortcut to a wasm target. Their value is different:

- **LLVM IR** is the direct route if the project wants to stop using C as the
  codegen surface, get optimizer passes, and target native + wasm from one IR.
  It still needs an emitter from BIR and the same runtime; the peer note owns the
  mapping and `tailcc`/`musttail` constraints.
- **MLIR** is a better fit if the goal is a long-lived multi-target compiler
  infrastructure with reusable analyses/transformations, not "ship wasm". BIR is
  already a small structured ANF with laws; adding MLIR means a second IR layer
  and new obligations. The in-tree `wasmssa` dialect is a *target-level* model
  ("intended to represent WebAssembly modules in SSA form"), and its docs do not
  document a binary emitter; the standard path is still LLVM IR → LLVM wasm
  backend. For this BIR, `LeaveRegion` (non-local lexical exit) and `Failure`
  have no clean MLIR region equivalent (MLIR note), so an MLIR route would have
  to model those explicitly before it could be called semantics-preserving.
- **Verdict for this task:** wasm deployment favors the C pipeline plus a wasm
  runtime profile; MLIR/LLVM are architecture investments to evaluate separately
  and are not required to answer "can this BIR run as wasm".

## 8. Recommended first target (concrete profile)

**Target name (research label):** `wasm32-wasip1` **command**, single-threaded,
one whole-program core module, one linear memory, no components.

Profile requirements (implementation later; none of this is implemented here):

1. **Code generation:** reuse `CBackend.render(program, runtime, files)` via
   `CEmitCore`/`CEmit`; no BIR/op/parser changes. The emitted C is the same
   program, with `BANGS 0` (no `!` device segments).
2. **Runtime source:** a separate, provenance-tracked wasm runtime profile that
   implements the same marker ABI (`Tables`, `Spins`, `Segments`, `Requests`,
   `WL_*`, `term_*`, `Env`, `show`, `main`/`_start`) but:
   - uses a bounded corpus (host/linker-configurable) with `memory.grow` and a
     defined out-of-memory failure. If the lane arrays keep `CUBE_T=128`, the
     static ring/stack arenas alone are ~0.4 GiB before any heap (see §2.2), so
     the profile must either budget for that inside 4 GiB or re-size the lane
     layout for one lane;
   - has no `mmap`, `mprotect`, `sigaltstack`, `sigaction`, `SIGPIPE`, or real
     `pthread_create` path. The existing file-scope pthread mutex/cond used by
     `pool_turn`/`POOL_WAIT` (`c_runtime.c:1651-1663`) must compile to no-ops or
     atomics in the single-thread profile; the `pool_size=1` `cube_run` path
     (`:2013-2046`) must be validated, not assumed;
   - maps `Term` words exactly as the C ABI, including boxed values and show
     descriptors;
   - preserves the IO activation/channel scheduler in one thread.
   The existing generated `c_runtime.c` must not be hand-edited
   (`c_runtime.c:1-5`, `evals/gen_c_runtime.ts:1-30`); the profile is a distinct
   artifact with its own review/provenance, or a new generator output.
3. **Effects:** WASI-p1 implementations for the supported rows of §6.4, with
   explicit new foreign alternatives so unsupported keys fail at selection. No
   silent stub that returns success.
4. **Compile/ship:** `bend file.bend -o out.wasm` (official CLI `cli_emit` has no
   `.wasm` branch today, `bend2/main.ts:374-394`) would emit C then invoke a
   wasi-sdk clang with `--target=wasm32-wasip1`, `-mtail-call`, the sysroot, and
   `wasm-ld` memory flags. Running requires a host (`wasmtime out.wasm`); `bend
   file.bend` should remain native unless the CLI grows a runner dependency.
   Pinning the SDK version and flags is required for any reproducibility claim.
5. **ABI/ending:** first target supports `Ending.Executable` only (a command
   that shows the main value). `Ending.Library` needs a separate, documented
   Term/i64 export ABI (plus `bend_library_init` equivalent, as in
   `c_backend.bend:602-637`) and is deferred.
6. **Explicit non-goals for the first target:** threads, wasm64, WASI p2/p3
   components, sockets/process/audio/window, browser, GPU, multi-module wasm
   object linking, byte-identical wasm binaries across toolchains.

Why this profile and not a "subset of the language": the backend must implement
**every BIR op and every primitive** or reject the program with a diagnostic.
The staged part is *effects and deployment*, not source-language coverage. A
"hello world subset" backend would be a fake complete backend and is not the
proposed deliverable.

## 9. Law instances and behavioral acceptance

The C backend has no accepted full native run at this baseline, so wasm
acceptance must be differential and independent, not transitive from C.

| Instance | Derived from | Concrete obligation | Acceptance idea (not run here) |
|---|---|---|---|
| W-OWN | F3, L4 | wasm runtime must keep/drop Terms exactly; host imports borrow, never steal; affine captures not duplicated | program exercising closure capture and array sharing; no double free/use-after-free under a checking allocator; >2^24 refs gives the defined error |
| W-ORDER | L2, B2 | strict `Let` and foreign effects keep order; nullary factories re-evaluate per read; `LoadSymbol` never memoized | effect trace program (print sequence, mutable factory read twice) equals JS/native order |
| W-APPLY | L3, B2 | Direct/partial/over-application, saturated export fast path, extra application, zero-live arity | differential outputs for partial/over-applied exports, including effects at the saturation boundary |
| W-LAYOUT | L5 | same constructor layout: packed one-word, ≤8-word inline, nested expansion, erased fields, arrays, `__proto__` key | show/fixture corpus on constructors at the 8-word boundary, nested datatypes, erased slots |
| W-SHOW | L7 | descriptor interpreter produces identical text, including Char escaping, Unicode, U32/Nat/F32, dependent fields | byte-identical stdout for a show corpus; f32 subnormal/signed-zero/round-trip cases |
| W-CTRL | L6 | Region/LeaveRegion lexical exits; tail calls use `return_call*`; deep tail recursion O(1) stack; non-tail recursion fails with a defined result | 10^7 tail-recursive steps complete; target_features contains `tail-call`; deep non-tail recursion maps to the documented trap/failure, not silent corruption |
| W-PRIM | B1 | U32 div0=0, shift≥32=0, Nat overflow error, Unicode/empty strings, array bounds, float bits | differential primitive corpus; NaN-bit observations explicitly allowed per spec or excluded from equality |
| W-DET | G1 | BIR ID/serialization determinism already exists; wasm *binary bytes* are a new claim only if made | if claimed: two builds with a pinned SDK/flags compare equal; otherwise state G1 does not extend to wasm bytes |
| W-NARROW | G2 | unsupported foreign key → compile/link diagnostic naming the declared path; no undefined import, no silent stub | a program using `Process.run`/`TCP` in the p1 target fails at selection with the path named |
| W-CAP | B2 | args skip argv[0]; env absent → `Fail ENOENT`; preopen escape → the same `Fail{code,message}` shape; thread_count truthful | WASI host stubs for args/env/preopens; compare error codes with native; no path traversal success |
| W-ERR | B2 | `Failure` and runtime fail-stop produce a single documented host-visible result (message/exit vs trap) | fault program; compare exit/status/message policy, not just "nonzero" |
| W-OOM | B2/B1 | heap exhaustion is a defined failure, not a `memory.grow` mid-write trap or an unbounded hang | allocate beyond the profile cap repeatedly; defined error and clean exit |
| W-IO | B2 | print bytes, `IO.now` monotonic semantics, `IO.sleep` ≥ requested, `random_get` real entropy, channel park/wake without pthreads | deterministic stubs for clock/random; channel ping-pong exceeds the queue and still makes progress |

Note on K1-K5: they govern the native CPS resumer of the compiler, not ordinary
Bend programs. They become relevant only if the *compiler itself* is built for
wasm (self-hosting in wasm), which this note does not propose; the current
compiler's memory/scale facts make that a separate, later question.

## 10. Integration boundaries (exact, for an implementer)

- **Target adapter pattern:** `c_emit_core.emit(checked, runtime, files)` is the
  pure seam (`c_emit_core.bend:106`); `c_emit.render(program, runtime, files)`
  takes the runtime text (`c_emit.bend:71`); `driver.compile_c` reads
  `--runtime-c` and writes the C output (`driver.bend:20,132-160`). A wasm target
  should copy this shape, not add a second lowering.
- **Foreign selection:** C picks the first `.c` alternative
  (`c_emit_core.bend:33-40`); JS picks `.js` (`js_backend.bend:26-33`); the
  alternatives are BIR data (`ForeignDeclaration.sources`), so a wasm target
  must select its own declared alternative rather than deriving one.
- **CLI:** official `cli_emit` handles `.mjs`/`.js`/`.c`/`.bendtt`, else builds a
  native binary (`bend2/main.ts:374-394`); self-host CLI accepts `.js`/`.c` only
  (`driver.bend:155-160,199`). `-o out.wasm` presently falls into the native
  branch, so it is not a target. `cli_build` is where clang flags live
  (`bend2/main.ts:398-460`); a wasm build step needs a separate toolchain
  discovery path (wasi-sdk), not reuse of the native `-O3 -lpthread -lm` line
  blindly.
- **Runtime provenance:** `c_runtime.c` is generated/pinned; a wasm runtime must
  not be a hand edit of it. The generator pins `comp.ts`/`bend.ts` and never
  modifies them (`evals/gen_c_runtime.ts:1-30`), so a profile is either a new
  generated artifact or a separately reviewed source.
- **No cutover:** the JS target remains the accepted path; adding a wasm emitter
  must not change `Ending`, IDs, snapshot formats, or the parser. No new IR is
  introduced by this research.

## 11. Unresolved questions

1. **Deployment goal.** Is the first consumer a standalone CLI (p1 is enough for
   print/args/env/clock/random/files) or a browser page (no WASI; needs a JS host
   adapter and an async policy)? The recommendation assumes standalone CLI.
2. **Heap budget.** Do real programs (let alone the self-hosted compiler) need
   more than 4 GiB? If yes, wasm32 is out and wasm64 is blocked by wasi-sdk; that
   is a product decision, not a backend detail.
3. **C base acceptance.** How much of the C emitter must be accepted before wasm
   work starts? Building wasm on an unaccepted emitter risks inheriting defects;
   the alternative is direct wasm emission, which has larger semantic risk.
4. **Runtime profile ownership.** Who owns the wasm runtime profile, and how is
   it kept in ABI lockstep with `c_runtime.c` given the generator pin? A drift
   here is a silent L5/L7/B1 failure.
5. **Show/float parity.** Does wasi-libc's printf/strtof reproduce `f32_text`
   for all edge cases? Needs measurement, not assumption.
6. **Single-thread IO semantics.** Are the observable timings/order of
   channels/`IO.spawn`/blocking effects preserved when the IO helper thread is
   replaced by a single event loop? Which orderings are part of the B2 contract?
7. **NaN-bit observations.** Should `PrimF32Bits`/`PrimFloatBitsEqual` be
   documented as spec-nondeterministic on wasm, or should a canonical-NaN policy
   be imposed (and if so, is that a B1 change)? Imposing one would be a semantic
   change, not a port.
8. **Library ABI.** What is the wasm public ABI for `Ending.Library`: raw
   `i64 Term` exports plus an init function (C-like), or a descriptor-driven
   encode/decode layer that gives JS natural values? The JS target's ABI cannot
   be reproduced directly.
9. **WASI p2/p3 value.** Is component-model distribution (supported by Wasmtime;
    not in Node's WASI and not in browsers) worth the canonical-ABI and toolchain
    cost, or is the value only in p1 + sandboxing?
10. **Threads.** Is single-thread performance acceptable for the target
    workloads, or is experimental `wasip1-threads` required? The latter is
    Phase 1/legacy and is being replaced by shared-everything threads.
11. **Wasm object linking.** Whole-program one module is assumed. If incremental
    or multi-package wasm linking is ever wanted, it collides with program-global
    IDs/tables and needs a separate stable-ID design (IncrementalCompilerResearch
    is documenting that boundary).

## 12. Next tasks and acceptance ideas (research/implementation later)

1. **`wasm-primitive-and-op inventory` (read-only).** Tabulate every
   `BIR.Op` and every `BIR.Primitive` against its C rendering/runtime helper and
   the wasm obligation. Acceptance: no constructor left without either a mapping
   or an explicit "unsupported, diagnostic" row; reviewer can diff against
   `backend_ir.bend:33-192` and `c_backend.bend:1460-1576`.
2. **`wasm-runtime-profile design` (doc + review, no code).** Fix corpus bounds,
   arena sizing, allocator/grow policy, single-thread IO loop, trap/OOM mapping,
   handle packing, show/descriptor tables, runtime provenance. Acceptance: every
   marker/ABI item in §2 and §10 is addressed, and the design states which
   `c_runtime.c` assumptions are removed.
3. **`wasi-sdk toolchain pin` (probe).** Pin a wasi-sdk version and exact flags
   (`--target=wasm32-wasip1`, sysroot, `-mtail-call`, memory flags); compile and
   run a tiny C program with a 64-bit `Term`-shaped ABI under Wasmtime.
   Acceptance: recorded command, version, `target_features` (tail-call present),
   and actual run output; explicitly not a Bend acceptance.
4. **`p1 effect mapping spec` (doc).** For each `bend2/effs/*.c`, specify the
   p1 mapping, errno translation, argv0/env/preopen policy, and unsupported
   list. Acceptance: link-time matrix with a named diagnostic per unsupported
   key.
5. **`wasm differential gate` (later).** Choose a frozen corpus subset that uses
   only supported effects; compare wasm stdout/exit against the accepted JS
   target. Acceptance: byte-identical stdout and same exit for every case;
   failures record the first difference, not a pass count.
6. **`wasm64 decision` (measurement, later).** Measure the heap high-water mark
   for representative programs and the compiler root; decide whether >4 GiB is a
   requirement. Acceptance: a documented budget; no wasm64 target until wasi-sdk
   (or an alternative sysroot) supports it.
7. **`browser host adapter design` (after p1).** Specify the JS import set, value
   encode/decode for Term/strings/constructors, sync/async policy, COOP/COEP for
   threads, and memory-view refresh. Acceptance: design only; no claim that the
   existing Node-oriented JS effects are browser-ready.
8. **`C base acceptance check` (before any wasm claim).** Confirm what full
   native C acceptance exists at the chosen base commit; if none, wasm acceptance
   must include its own end-to-end evidence and must not cite C.

## 13. Sources (fetched 2026-10-24; repository paths at `f46ad0f6`)

WebAssembly / WASI / toolchains:

- WebAssembly 3.0 change history (dated 2026-10-23):
  https://webassembly.github.io/spec/core/appendix/changes.html
- WebAssembly proposals (active): https://github.com/WebAssembly/proposals
  (raw README and `finished-proposals.md` fetched)
- WebAssembly numerics (NaN nondeterminism):
  https://webassembly.github.io/spec/core/exec/numerics.html
- WebAssembly JS API (`i64`/BigInt, imports):
  https://webassembly.github.io/spec/js-api/
- WASI README (Preview 1/0.2/0.3):
  https://raw.githubusercontent.com/WebAssembly/WASI/main/README.md
- WASI proposals (sockets Phase 3, threads Phase 1, WebGPU Phase 2):
  https://raw.githubusercontent.com/WebAssembly/WASI/main/docs/Proposals.md
- WASI Preview 1 API docs (wasi-0.1 branch):
  https://raw.githubusercontent.com/WebAssembly/WASI/wasi-0.1/preview1/docs.md
- wasi-threads (legacy Phase 1, hosts):
  https://raw.githubusercontent.com/WebAssembly/wasi-threads/main/README.md
- Component model README (0.2.0/0.3.0/0.3.1, gated features):
  https://raw.githubusercontent.com/WebAssembly/component-model/main/README.md
- Canonical ABI explainer:
  https://raw.githubusercontent.com/WebAssembly/component-model/main/design/mvp/CanonicalABI.md
- wasi-sdk README (targets, limitations, no wasm64, networking):
  https://github.com/WebAssembly/wasi-sdk
- wasi-sdk cooperative threading:
  https://raw.githubusercontent.com/WebAssembly/wasi-sdk/main/CoopThreading.md
- wasi-sdk C++ exceptions:
  https://raw.githubusercontent.com/WebAssembly/wasi-sdk/main/CppExceptions.md
- wasi-libc README (pthread behavior per target):
  https://github.com/WebAssembly/wasi-libc
- wasi-libc mmap/mprotect emulation:
  https://raw.githubusercontent.com/WebAssembly/wasi-libc/main/libc-bottom-half/mman/mman.c
- wasi-libc command startup/export names:
  https://raw.githubusercontent.com/WebAssembly/wasi-libc/main/libc-bottom-half/crt/crt1-command.c
- Wasmtime proposal support matrix:
  https://docs.wasmtime.dev/stability-wasm-proposals.html
- Wasmtime WASIp1/WASIp2 examples:
  https://docs.wasmtime.dev/examples-wasip1.html ,
  https://docs.wasmtime.dev/examples-wasip2.html
- Node.js WASI (experimental, preview1 only, security caveat):
  https://nodejs.org/api/wasi.html (Node v26.12.1 docs)
- Chrome 133 release notes (Memory64, 2025-02-04):
  https://developer.chrome.com/release-notes/133
- WebKit bug 300538 (Memory64 still NEW; parity text):
  https://bugs.webkit.org/show_bug.cgi?id=300538
- web.dev Baseline (tail calls + WasmGC, 2025-01-29):
  https://web.dev/blog/wasmgc-wasm-tail-call-optimizations-baseline
- V8 4 GB wasm32 memory / toolchain opt-in:
  https://v8.dev/blog/4gb-wasm-memory
- Emscripten pthreads (COOP/COEP, `Atomics.wait` main thread, no signals/fork):
  https://emscripten.org/docs/porting/pthreads.html
- MLIR `wasmssa` dialect (target-level, SSA form of wasm modules):
  https://mlir.llvm.org/docs/Dialects/WasmSSAOps/

Repository (exact anchors used above):

- `bend2/selfhost/backend_ir.bend:13-25, 33-150, 152-176, 178-192, 194-208, 209-240`
- `bend2/selfhost/backend_lower.bend:1353-1354` (`Bang` erased)
- `checkpoints/SELFHOST_IR_ARCHITECTURE.md:176-200` (BIR contract),
  `:202-234` (F/L/B/G/K laws), `:286+` (acceptance criteria)
- `checkpoints/SELFHOST_HANDOFF.md:1009-1010` (no C/native fixedpoint proof)
- `bend2/selfhost/c_runtime.c:1-5, 130-167, 191-273, 283-294, 417, 465-484,
  1481-1485, 1522-1545, 1607-1618, 2105-2126, 2159-2210, 2500-2501,
  2573-2601, 2632-2735, 2837-2893`
- `bend2/selfhost/c_backend.bend:9-42, 602-637, 1370-1576, 2229-2230, 2954+`
- `bend2/selfhost/c_backend_layout.bend:1-50`
- `bend2/selfhost/c_emit.bend:71-102`; `c_emit_core.bend:33-40, 106`
- `bend2/selfhost/js_backend.bend:26-33`; `bend2/selfhost/driver.bend:20, 132-160, 199`
- `bend2/main.ts:1-10, 374-394, 398-460`
- `bend2/comp.ts:1-10, 3623, 6566+` (Node-oriented JS runtime)
- `bend2/effs/*.c` and `bend2/effs/*.js` (effect sources; mappings in §6.4)
- `evals/gen_c_runtime.ts:1-30` (runtime snapshot provenance/pins)
