# GPU backend research: the Metal/CUDA lane vs. the new FIR/BIR → C/JS pipeline

Status: research note, no implementation. Baseline `f46ad0f6` (integration branch
`work/fir-ir-integrated57ab`), sources read 2026-10-24. External primary sources
were read the same day; every substantive claim is labelled
**[S]** source-read, **[M]** measured here, or **[I]** inference/derived.
Nothing in this note is a claim that the new pipeline executes a GPU.

Scope: what GPU support already exists in the official compiler
(`bend2/comp.ts`, `bend2/main.ts`, generated runtime, `bend2/effs`), what of it is
reachable from the new checked-frontend → BIR → C/JS pipeline
(`bend2/selfhost/*`), and what a GPU target would have to satisfy. MLIR and
WASM/WASI and LLVM routes are cross-referenced, not duplicated; see
`RESEARCH_MLIR.md`, `RESEARCH_LLVM.md` and `RESEARCH_WASM_WASI.md` beside this
note.

---

## 1. Direct answer: does GPU support already exist?

**Yes for the official C lane; no for the new BIR pipeline.** Precisely:

1. **[S]** In the legacy/official compiler (`bend2/comp.ts` → `bend2/main.ts`
   `cli_build`), a `!` call is a real GPU lane on macOS (Metal) and on
   Linux/NVIDIA (CUDA via NVRTC). The same generated C file is compiled twice:
   by clang for the host, and by Metal or NVRTC for the device; a single kernel
   `bend_dev` schedules the program's own segments over one shared corpus.
   `--gpu on|off|4GB` and `--gpu-build` are runtime flags, and `bend -o` emits
   `<binary>.gpu` beside the binary.
2. **[S]** Through the new pipeline there is **no** GPU path: BIR has no
   bang/fork node (`Arena.TermBang` is lowered to its child), the C backend
   hardcodes `#define BANGS 0` and writes a zero bang flag for every entry, and
   the JS backend is sequential by documented design. The GPU text that does
   exist in the new tree is a hand-maintained copy of the legacy runtime
   (`bend2/selfhost/c_runtime.c`), unreachable because nothing marks a device
   segment and no new-pipeline build path defines `BEND_METAL`/`BEND_CUDA`.
3. **[S]/[I]** Therefore "GPU is available through FIR/BIR → C/JS" is **false
   today**. `--gpu on` is parsed by the new binary, but with `BANGS == 0`
   `main` takes the `why = ""` branch, so `corpus_setup(false, ...)` keeps
   `io_gpu` false and no device is probed **[I from those branches; not
   executed]**.
4. **[M]** This host (macOS 26.6.2 arm64) has Apple clang 21.0.0 and a Metal
   toolchain (`xcrun -f metal` resolves), and has no CUDA (`/usr/local/cuda`
   absent, no `nvcc`). So Metal is the only locally testable device; CUDA
   cannot be exercised here at all.
5. **[S]** No test in `tests/` requires a GPU. The only GPU-executing lane in
   the repo is the benchmark gate (`gates/perf.ts`, mode `PAR-GPU`), and it
   builds only the legacy compiler's C. No run of anything was performed in
   this research slice, so this note makes **no** Metal execution claim.

Short form: **GPU support exists as a runtime + emitter feature of the legacy C
backend, not as a property of BIR.** Anything that presents `c_runtime.c`, the
`DEVICE` macros, or `bend_dev` as new-pipeline GPU execution is measuring file
presence, not a reachable path.

---

## 2. What exists in the official compiler (inventory)

### 2.1 `!` semantics and lowering

- **[S]** `bend2/comp.ts:2395-2415` (`emit_jump`): a bang call emits
  `if (!seq) { return term_tsk(fid, task_node(...)); }` instead of a direct
  `WL_JMP`. A non-bang call to a callee that does not fork itself
  (`!DEVICE && !seq && fid_nofk(fid)`) also returns a task instead of jumping,
  which is how such a call becomes an independent unit for the CPU pool (host,
  multi-threaded `seq == 0`).
- **[S]** `comp.ts:2873-2945` (`emit_fork`): a parallel let
  `a b = f(x) g(y)` becomes one task per call plus a join task under
  `if (!seq)`; in `seq` (device lane, nested case) it degenerates to the
  sequential chain.
- **[S]** `comp.ts:1725`: a call site with the bang bit adds the *callee* to
  `FL.bangs`. `comp.ts:3202-3207` writes `FID_T[fid] = {arity, resw, flags}`
  with `flags` bit 0 = "some site bangs this def", bit 1 = "not forkable".
  `comp.ts:3209` writes `#define BANGS <count>`.
- **[S]** Checker rules (new pipeline, same language): a bang is only valid on a
  named application head — `checker.bend:3532,3617`. `tests/parse/gpu_mark_order.bend`
  pins that `pick<U32>!(1,2)` dies earlier for unrelated generic syntax.
- **[S]** `!` has zero CPU semantics: `tests/run/gpu_mark.bend` asserts
  interpreter and CPU-only compiled code treat `f!(x)` exactly as `f(x)`
  (expected `1212`), and `README.md:241` / `guide/SHADERS.md:14-26` describe the
  runtime meaning (one bang = one launch; parallel let = task + join).

### 2.2 Whole-program analysis: what the device must hold

- **[S]** `comp.ts:3099-3110` states the model: "A segment may fork if one it
  reaches does; `Clo~apply` reaches every closure. The device holds what the
  bangs reach, and every closure when a bang's parameter may hold one."
- **[S]** `comp.ts:3156-3165`:
  `wide = some bang's parameter type is a closure`;
  `dev = graph_close(reach(bang segments) ∪ (wide ? all closures : ∅))`.
  `comp.ts:3235` then emits every segment **not** in `dev` inside
  `#if !DEVICE`, so the device translation unit physically excludes them.
- **[S]** The failure mode if the analysis is wrong is a *runtime* error, not a
  compile error: the device `work_loop` default case posts `ERR_FIDS`
  (`comp.ts:4816-4820`), whose text is "a function the device does not hold"
  (`comp.ts:193`, `ERR_FIDS = 4` at `comp.ts:3862`).
- **[S]** Two primitives are deliberately host-only on device:
  `f32_show` / `f32_read` become `err_post(e.mem, ERR_FIDS)`
  (`bend2/selfhost/c_runtime.c:552-555`, identical in `comp.ts`). A device
  segment that shows or parses a float therefore fails at runtime with the same
  message as a missing function.

### 2.3 One program, two compilations

- **[S]** `comp.ts:3930-3933`:
  `static const char BEND_SRC[] = { #embed __FILE__, 0 };` under
  `#if BEND_METAL || BEND_CUDA` (with `-Wc23-extensions` disabled). The device
  program *is* the executable's own C text, embedded at compile time.
- **[S]** `comp.ts:3636-3660` (runtime template): `__CUDACC_RTC__` → `BEND_RTC`;
  `__METAL_VERSION__` → `<metal_stdlib>`; otherwise host headers and
  `<Metal/Metal.h>` under `__OBJC__`.
- **[S]** `comp.ts:3712-3740` defines `DEVICE` 1 for MSL and for NVRTC, 0
  otherwise; `DEV` is `coherent(device) device` on MSL ≥ 3.2, `device` on older
  MSL, empty on the host.
- **[S]** The device half ends before the host half: in the new runtime copy the
  `#if !DEVICE` block opens at `c_runtime.c:1476` and runs to EOF (`:2893`),
  covering the host GPU API, the pthread pool, IO, the inserted effect request
  sources, and `main`. The legacy template has the same shape: the guard opens at
  `comp.ts:5027` and is still the only open guard at `// Requests` and `// Main`
  (`comp.ts:6335-6340`). Effect C sources are therefore excluded from the device
  compile; a device segment can build `IO`/request *terms*, but no effect code
  runs on the device.

### 2.4 The device scheduler and kernel

- **[S]** `comp.ts:4880-4996` / `c_runtime.c:1331-1442`: one kernel
  `bend_dev`, two signatures (`kernel void bend_dev(DEV u64*, constant u32& pass,
  threadgroup u32* vote, ...)` for MSL; `extern "C" __global__ void bend_dev(DEV
  u64* H, u32 pass)` for CUDA), four passes:
  - pass 0: grow the frontier breadth-first (one group = 128 lanes, vote words);
  - pass 1: each lane runs the `c`-th deal of the task bag to completion;
  - pass 2: pack the allocation banks (`bank_pack`);
  - pass 3: pass 1 after a grow from under the cube, on the lane's own ring.
- **[S]** `gpu_run` (`comp.ts:5249-5258`) chooses `1` group when the frontier is
  smaller than `CUBE_T`, else `CUBE_G` groups, and always ends with pass 2.
- **[S]** Task representation is the runtime's: rings per lane
  (`RING_WORDS = 1024+2`, `RING_OFF`, `ring_push`/`ring_pick/ring_put`),
  per-lane device stacks of `STAK_LEN = 2048` words (`STAK_OFF`), allocation
  banks `ALC[CUBE_T+1][3*NCLS_ALL]`, and `monk_step` / `task_deal` / `dev_cut`
  (`c_runtime.c:1108,1281,1333`). The device runs the *same* `WL_CASE` segment
  bodies as the CPU, dispatched by `switch (fid)` (`c_runtime.c:1174-1273`).
- **[S]** Constants (`c_runtime.c:240-266`): `CUBE_T 128`, `CUBE 16384`,
  `CUBE_G = 1<<CUBE_LOG`, `CUBE_LOG = 7` on Metal; on CUDA `gpu_probe`
  (`comp.ts:5399-5401`) sets `CUBE_LOG` from L2 size in 16..128 groups.
  Fixed corpus overhead is therefore large **[I, arithmetic from the
  constants]**: stacks 16384×2048 words = 256 MiB, rings 16384×1026 ≈ 128 MiB,
  banks 16384×64 = 8 MiB — ~392 MiB before the heap. Metal's default span is
  capped at 2 GiB (`comp.ts:5312-5317`: min(recommended, maxBufferLength, 2 GiB)).
- **[S]** Memory: Metal maps the corpus with
  `newBufferWithBytesNoCopy:CORPUS ... MTLResourceStorageModeShared |
  MTLResourceHazardTrackingModeUntracked` (`comp.ts:5319-5329`); CUDA uses
  `cuMemAllocManaged` + `cuMemAdvise(SET_PREFERRED_LOCATION)` (`comp.ts:5421-5433`)
  and requires `CU_DEVICE_ATTRIBUTE_CONCURRENT_MANAGED_ACCESS` (`comp.ts:5392-5398`).
  One corpus, no device-side `malloc`; `corpus_grow` refuses to grow while
  `io_gpu` (`c_runtime.c:2096-2104`), and device allocation is a bump inside the
  fixed capacity (`heap_alloc_miss`, `c_runtime.c:635-671`, `#define
  corpus_grow(H,n) false` on device). Device stack overflow is `ERR_DEEP`
  (`WL_ROOM`, `c_runtime.c:167-171`); errors are published once in
  `H_ERROR_CODE` (`err_post`, `c_runtime.c:459-462`; `err_seen`, `:492`).
- **[S]** GPU mode recycles only small chunks (`KEEP_WORDS = CHUNK = 256` on
  device, `c_runtime.c:251-256`), i.e. the host's larger retention policy is
  switched off because the arena cannot grow.

### 2.5 Host plumbing, numerics, and build

- **[S]** `gpu_probe` (Metal: `MTLCreateSystemDefaultDevice`; CUDA: `cuInit`,
  managed-access check, primary context), `gpu_load` (Metal: binary archive or
  source compile; CUDA: cubin from `<bin>.gpu` keyed by an FNV hash of
  `BEND_SRC`), `gpu_make` (`--gpu-build`), `gpu_pass`, `gpu_note`
  (`comp.ts:5218-5525`, `c_runtime.c:1667-1980`). `.gpu` path is
  `executable + ".gpu"` (`comp.ts:5225-5234`).
- **[S]** `corpus_eval` (`c_runtime.c:2128-2158`) is the host/device boundary:
  when a surfaced task's callee has the bang bit and `io_gpu`, the task is
  pushed into ring 0, `H_CURSOR` is reset, the cube runs, and the host continues
  by delivering the continuation from `root_take` — values cross in the corpus,
  not through a host ABI.
- **[S]** Numerics are target-declared: on MSL `sin/cos/tan` are `fast::`,
  `sqrt/exp/log/log2/log10/pow/fmod` are `precise::`, `atan2` is a C99-corrected
  wrapper, and integer division is emulated (`c_runtime.c:501-522`;
  `comp.ts:363-366`). `tests/run/gpu_trig.bend` pins only that the three lanes
  agree on a three-decimal-digit sum — a declared tolerance, not bit equality.
- **[S]** `bend2/main.ts:398-427` (`cc_find(gpu)`): a GPU build needs clang 19
  (Apple clang 17) because of `#embed`; a CPU build needs 14.
  `main.ts:433-465` (`cli_build`) detects `#define BANGS 0` in the generated C;
  with bangs on macOS it compiles `-x objective-c -fobjc-arc -fmodules
  -DBEND_METAL=1` and then runs `<bin> --gpu-build`; on Linux it adds
  `-DBEND_CUDA=1 -I$CUDA/include -L$CUDA/lib64 -L$CUDA/lib -lcuda -lnvrtc` when
  `$CUDA_HOME`, `$CUDA_PATH`, `/usr/local/cuda` or `/opt/cuda` has `nvrtc.h`,
  otherwise the bangs stay on the CPU pool. Frameworks are not named on the
  command line; ObjC modules autolink them **[I]** (the perf gate's own cc line
  does pass `-framework Metal -framework Foundation`, `gates/perf.ts:66-68`).
- **[S]** `gates/perf.ts:62-74` defines `MODES = ["SEQ-CPU","PAR-CPU","PAR-GPU"]`
  and `FLAGS` ending in `--gpu $gm`; the GPU cells measure the legacy binary.
  `gates/hybrid_gate.ts:3` explicitly says the hybrid gate never exercises
  C/native/GPU.

### 2.6 What the legacy lane does *not* do (bounds a reader must keep)

- **[S]** One device, one program, one kernel, one queue/stream; no multi-GPU, no
  device-side foreign calls, no device-side allocation beyond the corpus, no
  growth after the device buffer exists, no per-program kernel codegen.
- **[S]** Divergent work is slower on device than on the CPU pool (documented in
  `guide/GUIDE.md:160-166`, `guide/SHADERS.md:14-26`); bangs are a coarse
  fork-join unit, not an arbitrary parallel-loop mapping.
- **[S]** The GPU program is compiled from the *whole file text*, so any
  host-only symbol reachable in the device translation unit breaks the device
  compile; the reach analysis plus `#if !DEVICE` is what keeps it compiling.

---

## 3. What the new pipeline has (FIR/BIR → C/JS)

### 3.1 BIR has no parallelism

- **[S]** `backend_ir.bend:178-208`: closed `Op` catalog
  (`Copy`, `PrimitiveCall`, `Closure`, `Direct`, `Apply`, `LoadSymbol`,
  `Construct`, `Project`, `HasTag`), `Block` (`Return`, `Let`, `Branch`,
  `Region`, `LeaveRegion`, `TailDirect`, `TailApply`, `Failure`), `Code`; `Program` at `:233`.
  There is no fork, spawn, bang, or launch node.
- **[S]** `backend_lower.bend:1415-1418` (`only_child`) and
  `backend_lower.bend:1353`: `Arena.TermBang{_, child}` lowers to
  `lower_occurrence(child)` — the bang is erased, not marked. The spine flattener
  does the same (`backend_lower.bend:679`). A parallel let lowers to strict
  sequential `Direct`/`Apply` lets.
- **[S]** Consequence: *every* downstream target (C, JS, and any future MLIR
  export) receives a program with no parallel structure at all. This is the
  single most important finding for GPU work: the new pipeline cannot even
  express "run this call on the device", because the information is gone before
  the backend sees it.

### 3.2 The C backend declares the device lane off

- **[S]** `c_backend.bend:2848`: `#define WL_RESW 1\n#define BANGS 0`.
- **[S]** `c_backend.bend:2769-2775` (`fid_table`): every `FID_T` row is
  `{ arity, resw, 2 }` — bit 1 (`nofk`) is set for every entry, bit 0 (bang) is
  never set. There is no fork-closure analysis behind that constant.
- **[S]** `c_backend.bend:2882-2883`: `FID_T` is emitted, `STAT_LEN 0`.
- **[S]** `c_backend.bend:2407` already contains the *host* call-lowering shape
  `if (!DEVICE && !seq && fid_nofk(target))`, copied from the legacy emitter,
  but with `nofk` true everywhere it denotes nothing.
- **[S]** The C header contract (`c_backend.bend:11-43`) lists `BANGS` and the
  `!DEVICE`-guarded tables `SHOW_DESC/SHOW_NAMES` as ABI facts it must fill;
  today it fills `BANGS` with a literal and never emits per-code `#if !DEVICE`
  (the legacy emitter does, `comp.ts:3235`).
- **[S]** Library mode is explicitly CPU-only: `bend_library_init` runs
  `corpus_setup(false, 1, 0)` (`c_backend.bend:618`) — the first argument is
  "gpu", so the export ABI cannot even be called on a device corpus today.

### 3.3 The runtime text is a legacy copy, guarded off

- **[S]** `bend2/selfhost/c_runtime.c` is 2893 lines and contains the whole
  legacy device machinery: `DEVICE`/`DEV` (`:60-108`), device `WL_CASE`/`WL_DYN`
  (`:121-142`), corpus layout (`:240-272`), `bend_dev` (`:1331-1442`), the host
  API (`:1694-1980`), `corpus_eval` (`:2128`) and the CLI (`:2837-2893`).
  `driver.bend:31-40` reads it as text (`--runtime-c`, default
  `bend2/selfhost/c_runtime.c`) and `c_emit.bend` passes the bytes to
  `c_backend.emit(program, runtime)`.
- **[S]** It is inert: `#if BEND_METAL || BEND_CUDA` guards the GPU API, and
  `main.ts` only passes those defines when the generated C does *not* say
  `#define BANGS 0`. The new backend always says 0, so a new-pipeline binary
  compiles the CPU half only; a hand-built `-DBEND_METAL=1` binary would still
  reach `main` with `BANGS == 0`, never call `gpu_probe`, keep `io_gpu` false,
  and launch nothing (the fallback stubs at `c_runtime.c:1970-1974` apply only
  when neither `BEND_METAL` nor `BEND_CUDA` is defined).
- **[S]** Drift risk: this file is a hand-maintained copy of the `comp.ts`
  runtime template, not generated from it; there is no equality test between
  them in `bend2/selfhost` (no reference to `comp.ts` or a golden runtime).
- **[S]** Host-parity of the new C lane itself is not established: the
  architecture contract says the new root/native acceptance for the current ABI
  is a separate proof and cannot be borrowed
  (`checkpoints/SELFHOST_IR_ARCHITECTURE.md:3-86`). No GPU claim can precede a
  passing host binary.

### 3.4 JS target

- **[S]** `js_backend.bend` has no parallel construct to lower (BIR has none);
  `guide/GUIDE.md:166` states the JavaScript target runs sequentially. Nothing
  to reuse for GPU; a JS-side device would be a different project.

### 3.5 Answer matrix

| Surface | Legacy `comp.ts` + `main.ts` | New BIR → C | New BIR → JS |
|---|---|---|---|
| `!` reaches a backend | yes, as FID bang bit + task | no, erased in lowering | no, erased |
| parallel let | task + join | no, strict lets | no |
| device program artifact | `<bin>.gpu` (Metal archive / CUDA cubin) | none | none |
| device kernel | `bend_dev`, 4 passes | dead text in `c_runtime.c` | n/a |
| GPU memory | unified corpus / managed | same text, never entered | n/a |
| flags | `--gpu on/off/SIZE`, `--gpu-build` | parsed; `BANGS 0` keeps `io_gpu` false **[I from code, not executed]** | n/a |
| build integration | `main.ts cli_build` (clang 19, ObjC/NVRTC) | `driver.bend` writes `.c` only | writes `.js` |
| test/gate evidence | `gates/perf.ts` `PAR-GPU`; docs | none | none |

---

## 4. Comparison contract: what a GPU target must preserve

The comparison is from **BIR**, not from the AST: BIR already fixes evaluation
order, quantities (`Erased`/`Once`/`Unrestricted`), captures, constructor
layouts, code identity, and the boxed `Term` ABI. A GPU instance of the existing
laws therefore constrains the *runtime and emitter*, not the frontend.

### 4.1 Which existing laws need a target-specific instance

From `checkpoints/SELFHOST_IR_ARCHITECTURE.md:202-266` (obligations, not proved
theorems):

| Law | GPU instance required |
|---|---|
| F3 (affine owner not copied) | the device corpus holds the same owning values; no host copy is made to "send" a term — the legacy lane only ever moves a `Term` word and a task record into the shared arena. |
| L2 (strict ANF order, once) | bang arguments are evaluated on the host before the launch; the launched body may only reorder independent pure work. A GPU target must not turn a strict `Let` into an unordered device kernel argument. |
| L4 (closure conversion/uses) | if a bang's parameter may hold a closure, every closure becomes device-reachable (legacy `wide`); a new backend must compute that set or refuse. |
| L6 (branch/join/tail, no continuation copies) | the device grow/work passes are a scheduler for the same blocks; a device lowering may not clone continuations per lane. |
| B1 (primitive semantics per declaration) | device numerics differ by declaration: `fast::` trig on MSL, host-only `f32_show`/`f32_read`, emulated integer division. These are *declared* target primitives, not accidental differences; where the declaration differs, GPU2's tolerance/open-policy rule applies instead of bit equality. |
| B2 (public ABI, effect order) | no foreign/effect call may execute on device; a device-reachable foreign call must be a compile-time refusal, never a silent host call from kernel code. |
| G2 (no weakened admission) | a GPU target must not drop bodies, add `unsafe`, or special-case inputs to make the device compile. |

### 4.2 New GPU laws to add (proposed; none exist in the tree)

- **GPU1 Device partition is exact.** `device(BIR) = reach(bang roots) ∪ (all
  closures if a bang parameter type may hold one)`. Every code outside that set
  is host-only; every code inside it is either device-compilable or a compile
  diagnostic. (Legacy evidence: `comp.ts:3156-3165`, `:3235`; runtime backstop
  `ERR_FIDS`.)
- **GPU2 Device/host observation equality under the declared numeric policy.**
  For accepted programs and inputs, `--gpu off` (CPU pool), `--gpu on` (device),
  and the interpreter agree on termination, effect order, and value **as
  declared per primitive**: bit-exact only for primitives whose device
  declaration is the same operation; for primitives with a different device
  declaration (MSL `fast::sin/cos/tan`, `atan2_c99`, `precise::` for the rest —
  `comp.ts:363-366`, `c_runtime.c:501-522`) agreement is within that
  declaration's documented tolerance, or it is an **open policy** that must not
  be asserted. Do not promise universal bitwise F32 agreement: the legacy
  comment "the same pixels" (`comp.ts:363`) is an intent, not a proof, and
  `tests/run/gpu_trig.bend:2-4` deliberately quantizes each leaf to three
  decimal digits rather than comparing bits. Effects still run only on the
  host. (Legacy evidence: `tests/run/gpu_mark.bend` for the bang-erased case,
  `tests/run/gpu_trig.bend` for the tolerance form.)
- **GPU3 Shared-ownership discipline.** A device lane may read a shared term only
  under the same quantity rules as the host; `+` values update reference counts
  atomically (`a32_*`, `c_runtime.c:345-425`); affine values are never touched
  by two lanes; a published device error stops every lane and is read once by
  the host.
- **GPU4 Arena invariant.** One corpus; device allocation is a bump inside fixed
  capacity; no growth while the device buffer exists; the device stack bound is
  a real limit (`ERR_DEEP`), not an assumption. The partition constants
  (`CUBE_T`, `CUBE_LOG`, `STAK_LEN`, `RING_WORDS`, `KEEP_WORDS`) are part of the
  ABI shared by both compilations.
- **GPU5 Effect/foreign boundary.** No effect request source and no foreign C
  source is compiled into the device unit; a device segment may construct
  request terms only.

---

## 5. Options and tradeoffs

### A. Complete shared-C runtime reuse in the new pipeline (one feasible design)

Extend BIR + C emitter so the new lane emits exactly what the legacy emitter
emits, and let the already-vendored runtime do the work.

Required changes (no new IR dialect, no new dependencies):
1. BIR node/attribute for "this application is bang-marked" and for the parallel
   let's fork structure (today both are erased in `backend_lower`).
2. A BIR-level device partition and device-safety analysis (pure primitives,
   no foreign, no `f32_show/f32_read`, closures when `wide`), producing per-code
   "device" facts.
3. `c_backend`: emit `BANGS`, per-entry flags (bang/nofk), and per-code
   `#if !DEVICE`; keep `WL_RESW`/register ABI consistent with the device path.
4. Build/CLI: a real `-o binary` path for the selfhost driver, clang 19/ObjC/
   Metal or NVRTC selection, `--gpu-build`, `.gpu` placement, and flag
   forwarding — the logic already exists in `main.ts:433-465` but is wired to
   the legacy `Comp.compile_book`.
5. Only then: a GPU acceptance lane.

Why: of the four options it is the only one that can be built on the current
host and platform (Metal on this Mac) without a new compiler dependency, and it
reuses the corpus/term/ownership ABI the new pipeline is trying to preserve.
This is a design recommendation, not a proven win: no GPU performance claim
follows, and item 5 below is a prerequisite, not a formality. Cost: the device unit is compiled from the whole
file, so device-safety must be an analysis, and debugging is a single opaque
kernel. Risk: the new C emitter's segment ABI (`WL_RESW 1`, all-`nofk`) is not
yet known to be device-compatible; that must be proved on a host-first basis.

### B. LLVM IR → NVPTX / AMDGPU

- **[S]** LLVM ships the NVPTX backend (PTX) and the AMDGPU backend
  ("User Guide for NVPTX Back-end", "User Guide for AMDGPU Backend",
  `https://llvm.org/docs/NVPTXUsage.html`, `https://llvm.org/docs/AMDGPUUsage.html`,
  read 2026-10-24) and a SPIR-V target ("User Guide for SPIR-V Target",
  `https://llvm.org/docs/SPIRVUsage.html`).
- **[S]** (cross-checked with the LLVM note, 2026-10-24) LLVM has no in-tree
  Metal target; `RESEARCH_LLVM.md` covers the target boundary and the address
  spaces/libdevice/HSA surface.
- **[I]** Neither backend targets Apple GPUs; macOS would still need MSL. The
  new pipeline has no LLVM dependency and would have to gain one (library or
  subprocess), plus a BIR→LLVM lowering that re-expresses closures, the corpus,
  and the task machine. On Linux/NVIDIA this duplicates what NVRTC already does
  for the legacy lane (NVRTC compiles CUDA C, not PTX we generate).

### C. MLIR `gpu` + `nvvm`/`rocdl` (+ SPIR-V)

- **[S]** The `gpu` dialect provides kernel-launch abstractions and four
  address spaces (four: `global`/`workgroup`/`private`/`constant`), plus a documented
  pipeline `gpu-kernel-outlining → nvvm-attach-target → convert-gpu-to-nvvm →
  gpu-to-llvm → gpu-module-to-binary`; the page itself warns the dialect "is
  more likely to change than others in the near future", and
  `gpu-lower-to-nvvm-pipeline` "requires explicitly parallel IR and doesn't do
  GPU parallelization" (`https://mlir.llvm.org/docs/Dialects/GPU/`, read
  2026-10-24).
- **[S]** `nvvm` is NVIDIA-specific and sits below `gpu`/`nvgpu`; `rocdl` wraps
  AMD intrinsics 1:1; the SPIR-V dialect models the Khronos binary for
  Vulkan/OpenCL consumers (`https://mlir.llvm.org/docs/Dialects/NVVMDialect/`,
  `.../ROCDLDialect/`, `.../SPIR-V/`, read 2026-10-24). See `RESEARCH_MLIR.md`
  for the route in full.
- **[I]** There is no MSL target in upstream MLIR (cross-checked with the MLIR
  note's author, 2026-10-24), so on this Mac MLIR cannot replace the executor;
  at best it is a second device programming model for NVIDIA/AMD, and it would
  still need a Bend-specific partitioning pass because BIR is not explicitly
  parallel. Mojo is the instructive precedent: its compiler is MLIR-based and
  uses upstream `nvvm`/`rocdl`, yet still owns a GPU kernel-annotation pass
  (`Mojo/lib/MOGGPreElab/`, "GPU kernel annotation passes") — MLIR does not
  supply the language-level partition
  (`https://github.com/modular/modular/blob/main/Mojo/docs/compiler/MojoCompilerWalkthrough.md`,
  §11 dialect table and §13 pass summary, read 2026-10-24).

### D. Dedicated device-source codegen (MSL/WGSL per region)

Highest ceiling and highest cost: it needs a real parallel IR (thread mapping,
not a task interpreter), a second runtime (allocation, sharing, closures,
dynamic dispatch), and per-target backends. It contradicts the "one program,
one corpus" invariant that makes the current CPU/GPU equality cheap. Not a
first step; only justified if the interpreter-style scheduler is measured to be
the bottleneck on a real workload, which no new-pipeline evidence supports.

### Choice

**A** is the one feasible design here: it preserves the BIR ownership/ABI
contract and is the only option that can be built on the current host without a
new toolchain. It does not by itself make GPU available — a passing host binary,
the BIR partition analysis, the emitter flags, and the build/CLI path are all
prerequisites — and it is not proven to be faster than the CPU pool. **B** and
**C** are Linux/NVIDIA-only for execution and add toolchain/semantic layers;
**D** is a research bet. No target cutover follows from this note.

---

## 6. Implementation boundary and acceptance ideas (future work)

Ordered; each step is independently verifiable, and no step may claim the next.

1. **BIR carries parallel structure.** Add a bang marker on `Direct`/`Apply`
   (and a fork form for the parallel let) and preserve it in `backend_lower`
   instead of `only_child`. Acceptance: a fixture lowers `gpu_mark.bend`-style
   code and a dump shows the marker at exactly the source bang sites; a
   bang-erased control lowering is observationally identical on the C lane with
   `BANGS == 0` (GPU2 with the device disabled).
2. **Device partition as a BIR analysis.** Compute the reach set and the
   `wide` case; report a diagnostic when a device-reachable code contains a
   foreign declaration or a host-only primitive. Acceptance: positive fixture
   (`tests/compile/gpu_reach.bend` shape) yields `BANGS 1` and a device set;
   negative fixture (bang root calling a foreign/`f32_show`) fails to compile
   with a named diagnostic, not at runtime.
3. **C emitter parity.** Emit `BANGS`, per-entry flags, and per-code
   `#if !DEVICE`; keep `WL_RESW`/bank/ring constants consistent. Acceptance: the
   emitted C for a bang program contains the same ABI facts the legacy emitter
   writes (`FID_T` bit 0 at the bang root, non-zero `BANGS`, guarded segments),
   and the same file still builds and runs on the CPU lane with identical
   output.
4. **Host-first end-to-end.** Build the new C output with the new CLI and run a
   bang-free program, then a bang program with `--gpu off`, comparing value and
   effect order with the interpreter. Acceptance: real executions, not file
   text; this is the gate the whole research depends on.
5. **Device build path.** Add `-o binary` to the selfhost driver and reuse
   `main.ts`'s clang-19/ObjC-Metal and NVRTC selection; write `<bin>.gpu`.
   Acceptance: on this Mac, a Metal build succeeds and `--gpu-build` writes a
   `.gpu`; a missing/stale `.gpu` recompiles with the documented note.
6. **GPU equality on Metal.** Run the bang fixture with `--gpu on` and compare
   against `--gpu off`; include a `wide` closure case and a deep fork spine
   (`tests/compile/fork_spine_unroll.bend` is the existing regression for the
   grow-pass limit). Acceptance: GPU2 equality under the declared numeric
   policy — bit-exact for primitives declared identical on both lanes, and the
   `fast::` trig case compared at the declared tolerance with that policy
   written down (the existing 3-decimal quantization is the precedent) — plus an
   explicit device-executed observation (e.g. `gpu_probe` succeeded and the run
   did not take the CPU fallback); no timing claim.
7. **Lane policy.** Keep `!` out of the JS target and keep `--gpu off` as the
   portable path; document the device-only exclusions (`f32_show/f32_read`,
   foreign, effects). Acceptance: documentation and a negative fixture; no new
   benchmark numbers.

Explicit non-goals for this line of work: new IR dialect, new parser surface,
per-program kernel codegen, multi-GPU, device-side IO, or any target cutover.

---

## 7. Unresolved questions

1. Can the new C emitter's single-register result ABI (`WL_RESW 1`,
   `c_backend.bend:2848,1725`) express every BIR code that the device scheduler
   must enter, given the legacy lane relies on `resw` from layouts
   (`comp.ts:3202`)? Unverified without a device compile.
2. Is `nofk` = 2-for-every-entry a deliberate simplification or an unfinished
   fidelity gap? It changes CPU task stealing as well as device eligibility.
3. Can a BIR-only device partition be sound when closures flow through foreign
   or host-only values? The legacy `wide` heuristic keys on the bang parameter's
   type; BIR erases types at this point but keeps descriptors, so a keyed
   variant is plausible — unproven.
4. Will the vendored `c_runtime.c` stay in sync with `comp.ts`'s template? There
   is no equality test; the GPU text is duplicated today.
5. Metal binary-archive portability across OS/toolchain updates is undocumented
   in-repo; the legacy lane simply falls back to source compilation on a miss.
6. Does `c_backend`'s library ABI (`corpus_setup(false,1,0)`) need a GPU
   variant, or is a library always host-only by contract?
7. No CUDA hardware exists on this host, so nothing CUDA-shaped can be accepted
   here; the Linux/NVIDIA lane needs its own machine and its own evidence.
8. The F32 policy across lanes is undeclared: which primitives are expected to
   be bit-identical (integer ops, `precise::` math, `sqrt`) versus tolerance-only
   (`fast::sin/cos/tan`, `atan2_c99`) has never been written down as a target
   contract or tested across libm/Metal/Math in one fixture.

---

## 8. Sources

Local (all at `f46ad0f6`; line numbers as read on 2026-10-24):

- `bend2/comp.ts`: bang marking 1725; `emit_jump` 2395-2415; `emit_fork`
  2873-2945; device reach 3099-3110, 3156-3165; `FID_T`/`BANGS` 3202-3210;
  `#if !DEVICE` segment gate 3235; runtime template 3636-3660; `DEVICE`/`DEV`
  3712-3740; static image/spins/segs 3222-3238; error codes 3859-3867;
  `BEND_SRC`/`#embed` 3930-3933; device scheduler 4880-4996; GPU section
  5218-5525; default GPU decision and `--gpu` parsing 6343-6415.
- `bend2/main.ts`: `cc_find` 398-427; `cli_build` 433-465.
- `bend2/selfhost/backend_ir.bend`: `Op`/`Block`/`Code` 178-208, `Program` 233-239.
- `bend2/selfhost/backend_lower.bend`: bang in spine 679; bang to child 1353,
  1415-1418.
- `bend2/selfhost/c_backend.bend`: ABI contract 11-43; library init 618;
  `fid_nofk` call shape 2407; `fid_table` 2769-2775; `wl_macros` 2848;
  `FID_T`/`STAT_LEN` 2882-2883.
- `bend2/selfhost/c_runtime.c`: device macros 60-142; constants/layout 232-300;
  banks/alloc 600-700; `task_deal`/`monk_step`/`dev_cut`/`bank_pack`/kernel
  1108-1442; host block 1476+; GPU API 1694-1980; `corpus_eval` 2128-2158;
  `main` 2837-2893.
- `bend2/selfhost/driver.bend`: runtime/CLI 20-40, 201-204.
- `bend2/comp.ts:5027` and `6335-6340`: the `#if !DEVICE` region that owns the
  effect request sources and `main`.
- `bend2/selfhost/c_emit.bend`: runtime read and render 84-102.
- `tests/parse/gpu_mark_order.bend`; `tests/run/gpu_mark.bend`;
  `tests/run/gpu_trig.bend`; `tests/compile/gpu_reach.bend`;
  `tests/compile/gpu_reach_apply.bend`; `tests/compile/fork_spine_unroll.bend`.
- `guide/GUIDE.md` 140-166, 550-565, 638-652; `guide/SHADERS.md` 14-26;
  `README.md` 15-21, 173, 241.
- `gates/perf.ts` 62-74; `gates/hybrid_gate.ts` 3.
- `checkpoints/SELFHOST_IR_ARCHITECTURE.md` 3-86 (status), 202-266 (§4 laws).

External primary (read 2026-10-24):

- MLIR `gpu` dialect: https://mlir.llvm.org/docs/Dialects/GPU/
- MLIR `nvvm` dialect: https://mlir.llvm.org/docs/Dialects/NVVMDialect/
- MLIR `rocdl` dialect: https://mlir.llvm.org/docs/Dialects/ROCDLDialect/
- MLIR SPIR-V dialect: https://mlir.llvm.org/docs/Dialects/SPIR-V/
- LLVM NVPTX back end: https://llvm.org/docs/NVPTXUsage.html
- LLVM AMDGPU back end: https://llvm.org/docs/AMDGPUUsage.html
- LLVM SPIR-V target: https://llvm.org/docs/SPIRVUsage.html
- Mojo compiler walkthrough (MLIR dialects reference, GPU annotation passes):
  https://github.com/modular/modular/blob/main/Mojo/docs/compiler/MojoCompilerWalkthrough.md

Cross-references: `RESEARCH_MLIR.md` (MLIR execution targets and why they are
NVIDIA/AMD-only), `RESEARCH_LLVM.md` (LLVM NVPTX/AMDGPU target boundary and why
a direct BIR→LLVM device lane needs a device runtime distinct from the corpus
runtime), `RESEARCH_WASM_WASI.md` (WASM/WASI; no GPU surface in WASI).
