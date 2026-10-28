# Research: is an MLIR-based path a better fit for the Bend backend?

Research note. **No implementation, no new IR, no new dependency, no benchmark claim.**
Baseline: `f46ad0f6` (the integration branch `work/fir-ir-integrated57ab` is at the same
commit, so every BIR line number below is current, not historical).
All external material was read on **2026-10-24** at the URLs in §12; upstream claims were
re-checked against the actual files where a documented path could have been stale (§2.2).

Revision 2 (2026-10-24, after review): the verdict was rebalanced so that MLIR's
fact-preserving/custom-pass benefit is stated as plausible-but-unmeasured rather than
redundant; the affine section is now a terminology warning instead of a claim about the
hypothesis; the opaque-value row no longer says arithmetic is impossible; the affinity
analysis now requires carried use facts + verifier + explicit consume/type distinction
instead of relying on non-speculatability; the Metal route is qualified (SPIR-V→MSL) instead
of declared unavailable; debug info is separated into line-accurate (blocked by missing
spans) and name-based (possible today); M1 acceptance now requires valid-program semantics,
not only malformed-IR rejection; and descriptor encoding is presented as a design choice
between attributes and ops.

Labels used throughout:

| Label | Meaning |
|---|---|
| `[READ]` | Stated by a primary source I opened (doc, spec, upstream source, this repo at `f46ad0f6`). |
| `[COUNT]` | Static count I computed from `bend2/selfhost/*.bend` at `f46ad0f6`. |
| `[INFERENCE]` | My reasoning from `[READ]`/`[COUNT]` facts; not measured, not executed. |

Nothing here is `[MEASURED]`: this note ran no compiler, no build, no benchmark, and no
MLIR tool. The single heavy native-acceptance lane stays with its owner.

Companion notes (same directory, written in parallel; cross-referenced, not restated):
`RESEARCH_WASM_WASI.md` (WASM/WASI), `RESEARCH_GPU.md` (GPU/Metal/CUDA),
`RESEARCH_LLVM.md` (direct LLVM comparison — this file did not exist in the tree when I
read it, so §7 compares against the *C/clang* lane that does exist rather than against
that note's conclusions).

---

## 0. The question

The user's hypothesis: **MLIR may fit Bend's backend better than the current direct
lowering**, on the evidence of Modular's own compiler, which is built entirely on MLIR
([MojoCompilerWalkthrough.md](https://github.com/modular/modular/blob/main/Mojo/docs/compiler/MojoCompilerWalkthrough.md#mlir-dialects-reference),
read 2026-10-24: "The Mojo compiler (KGEN …) is built entirely on top of MLIR").

The hypothesis has four separable parts. **None of them is closed by argument alone**; each
is marked with what would settle it:

1. **"An IR with regions, dominance, verifiers and interfaces would help."** Plausible, and
   cheap to test: the backend's structural obligations are currently unvalidated (§4.6).
   Settled by M1 (§9).
2. **"A higher-level IR keeps facts that C lowering destroys, so custom passes and diagnostics
   get better."** Plausible and *untested*. This is the strongest pro-MLIR argument and it is
   **not** refuted by "clang also runs LLVM": clang receives C, in which Bend's descriptors,
   closure structure, region/case structure and affinity facts no longer exist. Whether
   passes over those preserved facts pay for themselves is an experiment (M2/M3), not a
   conclusion (§7).
3. **"Generated code would be faster."** Open. The known optimization blockers are the
   boxed-Term representation and the runtime ABI, which no IR choice removes (§4.3); but
   nothing here measures either route, and no comparative performance claim is made.
4. **Naming.** Bend's `Affine`/`Many` and MLIR's `affine` dialect are unrelated concepts (§5).
   This is a terminology warning so a design decision is not made on the shared word — it is
   **not** a finding about the user's hypothesis, which was about pipeline fit and pointed at
   the walkthrough's dialect list, not at the affine dialect.

---

## 1. Answer in one screen

| Claim | Verdict | Evidence |
|---|---|---|
| MLIR can express BIR's lexical `Region`/`LeaveRegion` control flow | **Yes, but not natively.** MLIR's scoping rule matches BIR exactly; its *branching* rule forbids the exit. Three encodings exist, all with a cost (§4.1). | LangRef §Value Scoping, §Blocks; BIR `Block` at `bend2/selfhost/backend_ir.bend:194-202` |
| BIR maps to MLIR SSA directly | **No.** BIR atoms carry no type; MLIR requires a static type per value. Two workable routes, neither free: an opaque `!bend.value` (keeps `arith` usable at primitive boundaries via the closed catalog's fixed representations, but blocks whole-value reasoning) or a type-recovery pass that must agree with the descriptors `BL-2` retained. | `Atom` `backend_ir.bend:13-23`, erasure law `BIR_LAWS.md` §4.2, §4.2 above |
| MLIR's verifier would buy something real | **Yes — the clearest win.** `WF-1…WF-11` are currently `[N]/[O]` — specification-only, no validator (`BIR_LAWS.md` §3, §3.7). An ODS'd dialect turns most of them into mechanical checks. | DefiningDialects/ODS `hasVerifier`/`hasRegionVerifier` |
| MLIR's affine dialect models Bend's `Affine`/`Many` | **No, but this is terminology, not a verdict on the user's idea** (the request never claimed the two match). MLIR affine is polyhedral index algebra; Bend affine is a linear-use *resource* discipline. | Affine dialect doc; `Use`/`Quantity` `backend_ir.bend:6-11`; `BL-3` |
| Reaching LLVM's optimizer/targets is an argument for MLIR | **No.** clang already runs the LLVM middle-end over the emitted C; MLIR is one front half among several. | §7 |
| MLIR keeps facts C erases, enabling custom passes/diagnostics | **Plausible, unmeasured.** These facts exist only in BIR today and are destroyed by C emission; whether passes over them pay is an experiment. | §4.4, §7, M2/M3 |
| MLIR would give us Metal | **No direct target**; `#nvvm.target` (NVPTX) and `#rocdl.target` (AMDGPU) are the only GPU object targets, and no MSL/Metal attribute exists. An indirect route (serialize SPIR-V, translate with SPIRV-Cross to MSL) exists with third-party/coverage cost and is evaluated in §6.1. | GPU dialect doc §Module serialization; NVVM/ROCDL docs; SPIRV-Cross README |
| MLIR would parallelize the fork tree | **No.** `gpu-lower-to-nvvm-pipeline` "specifically requires explicitly parallel IR and doesn't do GPU parallelization". | GPU dialect doc §Default NVVM Compilation Pipeline |
| Adopting MLIR is a small dependency bump | **No.** MLIR has no stable C++ API, the C API is "under development, API unstable" with "no stability guarantees", and the project publishes an active deprecation list. A Bend-side integration can only be a pinned subprocess or an unstable FFI. | MLIR C API page; Deprecations page; LLVM developer policy |
| Mojo's dialects are reusable | **Not as code — as readable prior art under a usable license.** They are real, public and Apache-2.0-with-LLVM-exceptions, but `LIT` is a *source-level* IR (Bend has AST+FIR), `KGEN` carries parametric elaboration Mojo-only machinery, and all of them are glued to Mojo's type system. `HLCF`→`scf` is the only transferable *idea*, and it is an idea, not code (§2.3). | `Mojo/lib/*` listing, `LowerHLCFToSCF.cpp` |

**Recommendation (research conclusion, not a target decision):** do not *cut over* to MLIR
now — the comparative question (preserved facts vs added layer) is open. The cheapest
informative step is **M1: emit standard-dialect MLIR from BIR and check both verification and
valid-program semantics** (§9), because verification is the one benefit that is separable
from the open codegen question. No custom `bend` dialect, no selfhost cutover, and no GPU
work follows from this note.

---

## 2. What Mojo actually does — verified against the sources, not the diagram

### 2.1 Pipeline as documented

`[READ]` MojoCompilerWalkthrough.md (read 2026-10-24):

- Parser emits MLIR directly, in the **`lit`** dialect; there is no traditional AST — only
  lightweight "expression nodes" for deferred parsing.
- `lit` → **`kgen`** (`LowerLIT`), with `LowerSemanticCF` and `CheckLifetimes` (borrow
  checker, destructor insertion) in between.
- Pre-elaboration optimization, then `ElaborateGenerators` (monomorphization, compile-time
  interpretation), then post-elaboration lowering (`LowerArgConventions`,
  `LowerCallingConventions`) and optimization (`SROA`, `Mem2Reg`, `SCCP`, inlining, unrolling).
- Phase 6: `LowerKGENToLLVM` / `LowerPOPToLLVM` / `LowerControlFlow` → `llvm` dialect →
  LLVM IR → machine code.
- Its stated dialect hierarchy: `lit` (source) / `kgen` (canonical, parametric then concrete)
  / `pop` (SIMD+memory) / `hlcf` (structured control flow) / `co` (coroutines) /
  `debuginfo` / `interp`, with **upstream** `index`, `llvm`, `nvvm`, `rocdl` appearing "at
  any stage"; `hlcf`/`co`/`debuginfo` are lowered to LLVM.

Two things matter for Bend:

- **`lit` is not a model for Bend.** Bend's pipeline keeps a parsed AST, an arena, and a
  checked FIR with occurrences and dependent types; Mojo avoided an AST entirely and put
  source semantics into IR ops. Borrowing `lit` would mean re-doing Bend's frontend — out
  of scope by construction ("assess from current BIR", not from source AST).
- **`hlcf` is the reusable idea**: a *custom* structured-control-flow dialect that is
  converted into upstream `scf`, not hand-rolled LLVM branches.

### 2.2 The documented paths are actually readable and licensed

`[READ]`, verified via the GitHub contents API on 2026-10-24 rather than trusting the doc's
file table:

- `Mojo/lib/` contains `LITDialect`, `KGENDialect`, `POPDialect`, `HLCFDialect`,
  `CODialect`, `LowerLIT`, `Elaborator`, `KGENToLLVM`, `Interpreter`, `Transforms`,
  `Compiler`, `ExecutionEngine`, `Target`, `DepGraphDialect`, `DialectChecksum`, `Support`.
- `Mojo/include/Mojo/{LIT,KGEN,POP,HLCF}Dialect/` contain real TableGen: `LITOps.td`,
  `LITDialectBytecode.td`, `KGENOps.td`, `KGENInterfaces.td`, `POPTypes.td`, `HLCFOps.td`, …
- The implementations are substantive, not stubs: `LITOps.cpp` is 98 KB, `LITTypes.cpp`
  64 KB, `LITAttrs.cpp` 40 KB; `LowerHLCFToSCF.cpp` includes `mlir/Dialect/SCF/IR/SCF.h`,
  `mlir/Dialect/Arith/IR/Arith.h`, `mlir/Dialect/Index/IR/IndexOps.h`,
  `mlir/Dialect/UB/IR/UBOps.h` and uses `mlir/Transforms/DialectConversion.h`; `KGENToLLVM`
  contains hand-written ABI lowering (`CABIAAPCS.cpp`, `CABISystemV.cpp`,
  `CABICallHelpers.cpp`).
- **License:** the repository states "Mojo and its contributions are licensed under the
  Apache License v2.0 with LLVM Exceptions", and each dialect file carries the
  `Apache License v2.0 with LLVM Exceptions` header. So the *design and code are legally
  reusable*; the obstacle is technical coupling, not licensing.
- **Build model:** `Mojo/BUILD.bazel` compiles the dialects as out-of-tree MLIR consumers
  against an external `@llvm-project` (Bazel, `mlir-tblgen`, `BuiltinDialectTdFiles`,
  `ControlFlowInterfacesTdFiles`, …). That is the shape any "Bend dialect" would have to
  take: a C++ Bazel/CMake project pinned to an LLVM checkout.

Observed documentation/source difference `[READ]`: the walkthrough's Phase 6 lists
`LowerControlFlow` (HLCF → branches) while the current tree has `LowerHLCFToSCF.cpp`
(HLCF → `scf`). The doc is a simplified narrative; trust the source when they disagree.
This is itself a small lesson about the maintenance surface.

### 2.3 Mojo-specific vs transferable

| Mojo piece | What it is | Transferable to Bend? |
|---|---|---|
| `lit` | Source-level IR emitted instead of an AST; owns name/overload resolution, parametric types, borrow checking | **No.** Bend has AST + owning checked FIR + occurrences; `lit` would replace FIR, which is explicitly out of scope. |
| `kgen` (parametric) | Canonical IR + generator elaboration + compile-time interpreter + argument/calling-convention lowering | **No.** Elaboration exists because Mojo monomorphizes generics in-IR; Bend's checker already instantiated. Call-convention *ideas* apply, code does not. |
| `pop` | SIMD/memory ops (`!pop.array`, `!kgen.simd`) | **Partly (idea).** Relevant if a numeric lane is ever vectorized; Bend's BIR has no vector node at all today. |
| `hlcf` | Structured control flow dialect converted to `scf` by `DialectConversion` | **Idea only.** The transferable lesson: express structured exits in a custom dialect, convert to `scf`, don't hand-roll. Bend's `Region`/`LeaveRegion` is the same shape (§4.1). |
| `co` | Coroutines | **No.** Bend's control protocol is a compiler-internal CPS (`SELFHOST_IR_ARCHITECTURE.md` §4 K1–K5), not user coroutines. |
| `debuginfo` | A whole dialect + `DIBuilder` + DI-expression tracking through SROA/mem2reg, then `DebugInfoToLLVM` | **No, and it is a cost warning.** BIR has no source spans (`Failure{message}` only), so line-accurate DI would require *adding* locations to BIR first; name-based locations need no BIR change (§10.6). |
| `DepGraphDialect`, `DialectChecksum`, `*Bytecode.td` | Module dependency graph, dialect checksums, custom bytecode format for precompiled packages | **No, but instructive**: three separate pieces of infrastructure exist only to make MLIR artifacts stable/addressable for packaging. |
| Upstream `index`/`llvm`/`nvvm`/`rocdl`/`scf`/`arith`/`ub` used by Mojo | Standard dialects | **Yes** — that is the point of §3. |

### 2.4 What it cost them (facts) and what that implies (inference)

`[READ]` artifacts: ~20 in-tree dialect/compiler libraries, hand-written C ABI lowering,
a debug-info dialect, bytecode + checksum infrastructure, a dependency-graph dialect,
their own CFG passes (`SimplifyCF.cpp`, `SROA.cpp`, `Mem2Reg.cpp`, `SCCP.cpp`,
`LoopUnrolling.cpp`, `InferFunctionAttrs.cpp`), and a Bazel pin on `@llvm-project`.

`[INFERENCE]` This is the honest benchmark for "Mojo uses MLIR, so we should": Mojo did not
get a language by adopting MLIR. It got a *framework* and then built a compiler on it,
including several subsystems MLIR does not provide (non-local exits in structured form,
debug info through aggregates, C ABI, packaging). A Bend adoption that stops at "emit
`func`/`arith`/`cf`" is a very different, much smaller thing — and it must be judged on
that smaller thing, not on Mojo's outcome.

---

## 3. Upstream inventory: what exists and what does not

`[READ]` from the dialect index (https://mlir.llvm.org/docs/Dialects/) and the individual
pages, 2026-10-24.

| Need | Upstream dialect | What it actually gives | Fit for BIR |
|---|---|---|---|
| Functions, modules, symbols | [`func`](https://mlir.llvm.org/docs/Dialects/Func/), `builtin.module` | `func.func` with multi-block region, `func.return` in any block (SEME), symbol visibility | Good: `Code` → `func.func` (captures as leading args) |
| Integer/float arithmetic | [`arith`](https://mlir.llvm.org/docs/Dialects/ArithOps/) | Typed scalar ops, `arith.select`, `arith.cmpi`; **"Division by zero is undefined behavior"** | Partial: ~half of Bend's primitives; see §4.7 for where UB ≠ Bend semantics |
| Unstructured CFG | [`cf`](https://mlir.llvm.org/docs/Dialects/ControlFlowDialect/) | "low-level, i.e. non-region based" `cf.br`/`cf.cond_br`/`cf.switch`; branches stay inside one region | Good for `Branch`; **not** for `LeaveRegion` |
| Structured control flow | [`scf`](https://mlir.llvm.org/docs/Dialects/SCFDialect/) | `scf.if`/`scf.for` (single block + `scf.yield`), `scf.while`, `scf.forall`, and **`scf.execute_region`: "multiple blocks and the blocks can have multiple distinct terminators"** | `execute_region` is the only clean home for `Region`+`LeaveRegion` |
| Index arithmetic | `index` | `index`-typed add/cmp/select | Used only if descriptors/array indices are modelled |
| Poison/UB | [`ub`](https://mlir.llvm.org/docs/Dialects/UBOps/) | `ub.poison`, `ub.unreachable` | `Failure{message}` → call to runtime abort, not `ub.unreachable` (message must survive) |
| Memory/pointers | `memref`, [`ptr`](https://mlir.llvm.org/docs/Dialects/PtrOps/) | Shaped buffers; opaque `ptr` with memory space | Bend's arrays/strings are runtime objects, not memrefs; `ptr` is only useful at the LLVM boundary |
| LLVM bridge | [`llvm`](https://mlir.llvm.org/docs/Dialects/LLVM/) | 1:1 LLVM IR ops, `llvm.data_layout`/`llvm.triple`, no LLVMContext-dependent objects | The only sane exit door |
| GPU | [`gpu`](https://mlir.llvm.org/docs/Dialects/GPU/) + [`nvvm`](https://mlir.llvm.org/docs/Dialects/NVVMDialect/), [`rocdl`](https://mlir.llvm.org/docs/Dialects/ROCDLDialect/), `nvgpu`/`amdgpu`, [`spirv`](https://mlir.llvm.org/docs/Dialects/SPIR-V/) | Kernel/launch model, target attributes, cubin/hsaco/SPIR-V serialization | NVIDIA/AMD only; see §6.1 |
| C/C++ emission | [`emitc`](https://mlir.llvm.org/docs/Dialects/EmitC/) | `mlir-translate -mlir-to-cpp`, C99-compatible by default | Interesting *alternative* to `c_backend`, but it cannot express Bend's runtime ABI (§7) |
| "Program" model | [`ml_program`](https://mlir.llvm.org/docs/Dialects/MLProgramOps/) | Globals/functions for ML graphs, but: "under active development … stability is not guaranteed" | Not a foundation |
| WebAssembly | [`wasmssa`](https://mlir.llvm.org/docs/Dialects/WasmSSAOps/) | "represent WebAssembly modules in SSA form": `wasmssa.func/memory`, `wasmssa.block` with `branch_if … to level N`, `block_return` | A *target-level* model, not a wasm codegen path; see §6.2 |

**Absent from upstream, and load-bearing for Bend** `[READ]` (absence in the full dialect
index is the evidence):

- **No closure dialect.** No op models "code pointer + captured environment" as a language
  concept; `func.func` has no closures, and `llvm` needs a hand-built
  `{ptr, ptr}` + indirect call.
- **No ownership/reference-counting dialect.** `memref`/`bufferization` model buffer
  lifetimes and aliasing, not at-most-once consumption of a value. There is nothing to hang
  `Affine`/`Many` (`backend_ir.bend:6-11`, `BL-3`) on.
- **No dependent/runtime-descriptor language.** `dlti` is a *data layout* type interface,
  not Bend's runtime type-expression language (`Descriptor` `backend_ir.bend:152-176`,
  normal form `descriptor_nf.bend:1-20`).
- **No dynamic boxing.** MLIR SSA requires a static type per value; nothing models "a
  runtime-tagged term whose type is known only to the descriptor interpreter".
- **No modelled non-local control flow** — stated outright:
  "We don't have proper modeling yet to fully capture non-local control flow"
  ([SideEffectsAndSpeculation](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/)).
  BIR's `Failure{message}` is exactly that (an abort/throw terminator), and `LeaveRegion`
  is a *bounded* non-local exit.

---

## 4. BIR → MLIR, concretely

### 4.1 Control flow: the one real structural mismatch

BIR at `f46ad0f6` (`bend2/selfhost/backend_ir.bend:189-203`):

```
# Region/LeaveRegion are lexical forward control flow, not graph jumps.
# A failed nested pattern exits one case; the remaining cases are emitted once.
type Block is Data:
  Return{value: Atom}
  Let{id: U32, op: Op, next: Block}
  Branch{condition: Atom, yes: Block, no: Block}
  Region{label: U32, body: Block, next: Block}
  LeaveRegion{label: U32}
  TailDirect{code: U32, args: List<&2, Arg>}
  TailApply{fn: Atom, arg: Arg}
  Failure{message: String}
```

What `Region`/`LeaveRegion` *is* — `[READ]` the producer and both renderers:

- Producer: each checked match row becomes `Region{label, body, next}`, and every failing
  guard/pattern in that row ends in `LeaveRegion{label}`
  (`backend_lower.bend:1200`, `:1220`; `WF-4`/`WF-5` in `BIR_LAWS.md` §3.2).
- JS: `Region` emits a **labelled block**, `LeaveRegion` emits `break $caseN`
  (`js_backend.bend:627-628`, `:643`, `:645-652`), and tagged regions become a `switch`
  (`:593-642`).
- C: `region_ctl`/`leave_ctl` compile the case body to segments and resolve the label to the
  nearest enclosing region (`c_backend.bend:2275`, `:2303`).

So `Region` is a **lexically scoped block with a single forward exit** — in MLIR terms, a
region with a terminator that transfers to a point after the region.

The MLIR rules `[READ]` ([LangRef](https://mlir.llvm.org/docs/LangRef/)):

- **Scoping matches BIR exactly:** "values defined in a region don't escape to the enclosing
  region", and "A value defined in a region can never be used outside of the region".
  JS's block-scoped `const` already relies on the same rule, so BIR needs no change here.
- **Branching does not match:** "it is impossible to reference, i.e. branch to, a block
  which is not in the same region as the source of the reference". `LeaveRegion` *is* such a
  cross-region transfer, so it can never be spelled as a branch out of a region.
- Blocks in an `SSACFG` region must end in a terminator; a terminator describes
  "branches to other blocks in the same region, returns/yields to the containing
  operation, or no continuation at all".

Three legal encodings, with their costs:

| Encoding | How | Cost |
|---|---|---|
| **(a) `scf.execute_region`** | `Region` → `scf.execute_region` whose region has a CFG: `LeaveRegion` → `cf.br ^exit`, `Return`-like ends → `scf.yield`; results are the case result | Needs a static result type for the region (§4.2); `execute_region` is an escape hatch that blocks canonicalization/inlining until lowered; the SCF doc explicitly introduces it for exactly this "multiple blocks inside SCF" case |
| **(b) flag-yield** | Each case region yields `(flag, value?)`; `next` becomes a chain of `scf.if` on the flag under `scf.while` | No CFG, but every arm materializes a union value; with boxed terms that means a tag word plus register traffic on every case, and it changes the value-flow shape that `L4`/`L5` talk about |
| **(c) full CFG** | `Branch`→`cf.cond_br`, `Region`→plain blocks + `cf.br` to a join block, `LeaveRegion`→`cf.br ^join` | Simplest to get *right*, and what "lower structured CF to branches" means anyway (`LowerControlFlow` in Mojo). Cost: gives up SCF-level structure, so any SCF-based pass (e.g. loop transforms) is unavailable later — irrelevant for Bend, which has no loops in BIR |

**Recommendation for the experiment:** (a) if the goal is to keep the IR structured for
verification/analysis, (c) if the goal is codegen. Do not invent a `bend.leave` terminator
without also implementing `RegionBranchTerminatorOpInterface`/`RegionBranchOpInterface` and
its verifier `[INFERENCE]` — an op that silently exits a region otherwise breaks region
branch analysis, inlining and canonicalization, i.e. it becomes a new correctness hole
instead of a check.

`Branch`: BIR conditions are *runtime* Bool terms (a `Construct`-ed `True`/`False`), not an
`i1`. `cf.cond_br` needs a 1-bit integer, and `cf.cond_br` "is not allowed to target the
entry block for a region". So a conversion pass must introduce the tag test explicitly — the
same test `c_backend.bend:2258` already emits (`term_aux(...) == True`). This is a *semantic*
decision that must be pinned by law, because JS currently branches on truthiness while C
compares a tag word (`BIR_LAWS.md` `WF-6`); a third target must pick one, and the C choice
is the safe one.

`TailDirect`/`TailApply`: BIR guarantees tail position only at block terminators
(`backend_ir.bend:188-190`), and both current targets implement it: JS through a trampoline
(`js_backend.bend:1165`), C through a generated tail trampoline (`c_backend.bend:28-31`).
MLIR/SCF has **no tail call**: only `llvm.call` with a tail-call attribute exists (`[READ]`
LLVM dialect `llvm.call`; the doc's tail-call kind is an LLVM concept). A conversion
therefore either emits `llvm.call … tail` and *hopes* the backend honours it (no guarantee
`[INFERENCE]`), keeps the trampoline (correct, unchanged cost), or turns self-tail-calls
into loops with `scf.while`. This is a case where MLIR offers nothing: the invariant already
lives in BIR and must be re-established per target regardless.

`Failure{message}`: there is no exception op. Emission is a call to the runtime's abort with
the message (as C/JS do today). Do **not** map it to `ub.unreachable`: the message is an
observable part of `Obs` (`SELFHOST_IR_ARCHITECTURE.md` §4: "завершение/ошибку"), and `ub`
deliberately licenses the compiler to assume it does not happen.

### 4.2 Types: the second, deeper mismatch

BIR's runtime values are *untyped in the IR*:

- `Atom` is `Local{id}`/`Capture{slot}`/`Symbol{id,key}`/`Word`/`Natural`/`FloatBits`/
  `Text`/`Boolean`/`Null`/`Undefined` (`backend_ir.bend:13-23`) — a *syntactic* class, not a
  type. A `Local` that holds a `Natural` looks exactly like one holding a boxed constructor.
- Types exist, deliberately, elsewhere: `PrimitiveCall{primitive, args, types:
  List<&2, Descriptor>}` (`backend_ir.bend:180`), constructor layouts
  (`ConstructorLayout{id,key,native,fields}`, `:216`), families/type functions (`:219-226`),
  and `Export.parameter_types` (`:228`). And `BL-2` states that erased source types are
  *not* lost — they are in descriptors.

MLIR requires "a type for every SSA value" (`[READ]` LangRef §SSA). Therefore a BIR → MLIR
conversion must choose:

| Choice | Consequence |
|---|---|
| One opaque type, e.g. `!bend.value` | Faithful to BIR and `BL-2`, trivially legal. It does **not** force all 112 primitives into runtime calls: the catalog is closed, so each `PrimitiveCall` has fixed operand/result representation rules, and a representation analysis can unbox at the call, use `arith`, and rebox — that is reading the catalog, not re-running the dependent checker `[INFERENCE]`. What is lost is *whole-value* typing: values flowing through `Construct`/`Project`/`Apply`/`Return` stay opaque, so passes cannot reason about them, and every box/unbox has a cost that is unmeasured. |
| Recover concrete types per value | Requires a new analysis mapping each `Local` to a descriptor (from primitive call sites, constructor layouts, and parameter descriptors). This is **not** a second type checker — the checker already finished and `PrimitiveCall.types`/descriptors are the authority — but it is a new pass that must be proven to agree with them, and any disagreement is a hard failure rather than a guess. It widens what `arith`/`math`/`vector` can fold *beyond* primitive boundaries; it is not the condition for using `arith` at all. |
| Hybrid | Typed for the primitive/array/float paths (`PrimitiveCall.types` already carries descriptors), opaque for `Construct`/`Project`/`Apply`/`Return` | Probably the practical shape, but it is a *new* mixed-type discipline that must be justified per law (`L5`, `B1`), not a translation. |

Nothing about this is hard to *prototype*; everything about it is hard to *prove*. And it is
the reason I do not recommend making MLIR the target IR: the IR is not where Bend's
correctness risk lives.

### 4.3 Boxed `Term` vs physical layout

BIR's object model is already target-negotiated:

- `Closure{code,captures,parameters}` / `Direct` / `Apply` (`backend_ir.bend:181-183`).
- `Construct`/`Project`/`HasTag` with *both* numeric ids and canonical string keys
  (`:184-186`), "two encodings … deliberately duplicated and must agree" (`BIR_LAWS.md` §2).
- `Declarations` include `LazyDeclaration` whose note says "Nullary declarations are
  reevaluated on every read, including mutable factories" (`:205-208`), and the JS
  renderer emits a getter that re-runs the body per read (`js_backend.bend:951`).
- The C target's whole header is a runtime-ABI contract: FID/CID tables, register-args
  segments, `STAT_IMG`, exported entries, and "a function value is always a one-short
  closure `term_clo(fid, block of arity-1 values)`, so the runtime's own
  `FID_CLO_APPLY`, IO loop and effect callbacks can apply it"
  (`c_backend.bend:9-42`); representation is the runtime's (`term_ctr`, `SCon`, `WCon`,
  `TAG_ARR`).

Consequences for an MLIR path `[INFERENCE]` from the above `[READ]`:

- There is **no closure op in MLIR**, so `Closure` must be a data structure (LLVM struct or
  runtime handle) and `Apply` an indirect call *through the runtime*. LLVM can then not
  devirtualize or inline it, because the callee is a runtime FID applied by
  `FID_CLO_APPLY`, not a function pointer. So the closure work that MLIR/LLVM would
  otherwise do for free is unavailable until the runtime representation changes — a change
  to the *runtime*, not to the IR.
- `Project`/`HasTag` are runtime layout operations; `Construct` allocates and touches a
  refcount. These are effectful calls, not `llvm.extractvalue` of a known struct, unless a
  constructor is `native` (`ConstructorLayout.native`) and its layout is fully known —
  which is exactly what the C backend already exploits (`c_backend_physical.bend`
  sealing/`term_keep`/`rfc_seal`, per `BIR_LAWS.md` §4.3).
- Therefore MLIR's middle-end sees: opaque values, calls, loads/stores. That is not a
  criticism of MLIR; it is a statement that Bend's optimization problems are representation
  problems.

### 4.4 Descriptors and NF metadata are not program IR

`Descriptor` (`backend_ir.bend:152-176`) is a *runtime type-expression language* with
substitution, equality, filling, `Min`, arrows, quantities; `descriptor_nf.bend:1-20`
normalizes it once for both targets and names the reference evaluator
(`comp.ts RUNTIME: $type, $type_apply, $type_named, $type_sugar`).

In MLIR this can be encoded as **attributes or as ops** — the choice is a design decision,
not a prohibition. The two shapes have different costs:

- **Attributes** (`DictionaryAttr`/`ArrayAttr` blob on the module, or a custom attribute with
  a verifier if the WF checks of §4.6 are wanted): metadata stays out of the program IR and
  needs no lowering, but MLIR verifies nothing about its *content* unless a custom verifier
  is written.
- **Ops** (a `bend.descriptor` data op per descriptor node, or constants/globals holding the
  built structure, cf. the C target's static image `STAT_IMG`/`SHOW_DESC`,
  `c_backend.bend:9-42`): descriptors become first-class, can be verified structurally and
  traversed by passes, at the price of pulling a compile-time data language into the program
  IR and giving it a lowering.

What is *not* available either way is a ready-made upstream dialect for a dependent,
runtime-interpreted type-expression language; `dlti` is data layout, not this. The honest
limit stands regardless of shape: **descriptor/NF agreement with the codes is a Bend law
(`BL-7`), not something MLIR checks for free**.

The honest limit: **MLIR cannot verify descriptor/NF agreement** (that `SHOW_DESC` describes
the same program as the codes, that a family's quantity prefix matches its arity, etc.).
Those are `BL-7`-class obligations (`BIR_LAWS.md` §4.7). MLIR would carry the data; Bend
would still own the law. `dlti` is not applicable — it describes *data layout*, not
dependent type expressions (`[READ]` Data Layout Modeling doc).

### 4.5 Effects and optimization legality — where a naive mapping breaks laws

`[READ]` [SideEffectsAndSpeculation](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/):
ops without implicit behaviour "can be reordered … can be eliminated or even introduced
(e.g. for rematerialization)"; effects are modelled with `MemoryEffectsOpInterface`, and
speculatability/UB/infinite loops with `ConditionallySpeculatable`.

Required classification of BIR ops in any MLIR mapping:

| BIR op | Correct MLIR effect model | Failure mode if marked `Pure` |
|---|---|---|
| `Copy`, `PrimitiveCall` (pure primitives) | `NoMemoryEffect` + speculatable | none (safe) |
| `LoadSymbol{id,key}` | **Must read** the symbol; nullary lazy declarations re-evaluate per read (`backend_ir.bend:205-208`, `js_backend.bend:951`) | CSE/DCE collapses a mutable factory's repeated reads into one — violates `L2`/`B2` |
| `Foreign{…}` / `ForeignDeclaration` (`backend_ir.bend:215`) | Opaque call, unknown effects, not speculatable | reordering across a `failure` or an IO write |
| `Construct`/`Project`/`HasTag` | Pure *iff* constructor layout is native and sealed; otherwise allocation effects | CSE of a constructor allocation changes identity/refcounts (`L5`, `B2`) |
| `Closure`/`Direct`/`Apply` | Call-like; `CallOpInterface` if you want inlining to see through | rematerializing a closure or duplicating a consumer changes consumption counts; inlining is legal only if the capture's use budget is preserved (`L4`, `BL-3`) |
| `Failure` | Abort; not speculatable, no return | adding a "may not happen" assumption is wrong: it *does* happen and is observable |
| `Region`/`LeaveRegion` | Must implement region-branch interfaces (§4.1) | a verifier-blind exit silently miscompiles |

**The `Affine`-use hazard is the sharpest one, and it cannot be solved by a trait.** `BL-3`
says every `Arg.use`/`Parameter.use`/`Field.use`/`Code.captures` entry is an upper bound on
consumption: `Affine` = at most once, `Many` = zero or more. MLIR's SSA form allows a value
to have arbitrarily many users — that is not an "implicit behaviour" in the sense of
[SideEffectsAndSpeculation](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/),
which covers memory effects, UB and non-termination. So:

- `MemoryEffectsOpInterface` cannot express "this operand may be consumed once". Effects
  describe what an op does to the world, not how many users a value has.
- Marking every affine-consuming op non-speculatable prevents the compiler from *inventing*
  executions of that op. It does **not** prevent a second, independently legal use of the same
  SSA value, nor DCE of a value whose consumption was supposed to be observable, nor the
  duplication that inlining/branch-folding performs on the *users*. "Mark it non-speculatable
  and it is safe" is therefore a blanket claim this note must not make.

A real story needs at least (i) the use fact carried in the IR (an attribute/type, since user
lists record *actual* uses, not *permitted* ones), (ii) a verifier that walks users and rejects
more consumptions than the fact permits — an ODS `hasVerifier` can do this, but only if (i)
exists — (iii) distinct value types or an explicit transfer/consume op so that an illegal copy
is syntactically a different program rather than a rewrite of the same one, and (iv) a per-pass
legality argument for the passes actually run. Mojo is the precedent for how much this is:
quantities live in its type system and a dedicated `KGENVerifier.cpp` pass exists in
`Mojo/lib/Transforms`. That is engineering, not a trait annotation. `[INFERENCE]` for the
recommendation; `[READ]` for the docs and the `KGENVerifier.cpp` existence.

### 4.6 What a dialect + verifier would actually buy (the honest win)

`BIR_LAWS.md` §3 says it plainly: "There is **no `validate` function** in this tree; `WF` is a
specification on producers and hand-built programs". The clauses are `[N]` (producer) with at
most `[C]` checks (C target's label lookup, referenced-code existence) and `[O]` for the
rest. `BL-1` ("WF is preserved by lowering") is `[N],[O]`.

Additionally, the readback is already known to be weak against exactly these mistakes: BIR_LAWS
lists duplicate code ids (last-writer-wins `Map.set`), unknown locals becoming undeclared C
identifiers / JS reference errors, out-of-range capture slots becoming out-of-bounds reads,
duplicate region labels silently changing the exit target, and non-Boolean branch conditions
diverging between targets.

An ODS dialect gives, mechanically `[READ]`
([Defining Dialects / ODS](https://mlir.llvm.org/docs/DefiningDialects/Operations/)):

- `hasVerifier` / `hasRegionVerifier` hooks and a defined verification order;
- trait-level verification (`verifyTrait`/`verifyRegionTrait`) for things like "terminator
  is last", "successor types match block arguments" (BIR's `Direct` arity, `WF-7`);
- automatic structural checks from operand/result/region/successor declarations;
- `mlir-opt --verify-each`-style habitual verification after every pass.

What it would **not** check: `BL-2` erasure, `BL-3` affinity, `BL-7` descriptor agreement,
`L2` order of effects, `B2` ABI, `G1` determinism. Those stay Bend-side laws. So the win is
real but bounded: it converts "no validator at all" into "structural WF is enforced", which
is the difference between the current state and a *checkable* backend — and it is available
**without** generating machine code through MLIR (§9, experiment M1).

### 4.7 Primitives: what actually maps to `arith`/`math`, and where UB would leak

`[COUNT f46ad0f6]` `Primitive` has **112** constructors (`backend_ir.bend:33-150`):

| Family | Count | Maps to `arith`/`math`? |
|---|---|---|
| `U32*` | 26 | Mostly yes (typed i32), **but**: `PrimU32Div`/`PrimU32Mod` must stay defined |
| `F32*` | 40 | Yes for `add/sub/mul/div/neg/sqrt/abs/cmp`; transcendentals via `math`; `PrimF32Pow`/`Atan2`/`Log*` need `math`'s specific ops |
| `Nat*` | 11 | **No** as machine ints — see the 2^48 guard below |
| `Array*` | 11 | No: runtime objects (`TAG_ARR`) |
| `String*`/`Char*` | 9 | No: `SCon` codepoint lists |
| `Word*`/`Bool*`/`Is*`/`SameValue` | 15 | Mixed: `Bool`/`Is*` are tag tests on runtime terms; `Word` is a runtime chain |

Three concrete places where a naive `arith` mapping would violate `B1` `[READ]`
`js_backend.bend:894` and `:1165`:

1. `$p_u32_div=(a,b)=>(b===0?0:…)` — Bend defines `x/0 = 0`. MLIR `arith.divui`:
   **"Division by zero is undefined behavior"**. Same for `PrimU32Mod` (`b===0?a:a%b`) vs
   `arith.remui`. Mapping either to `arith` without a guard is a silent law break.
2. `nat_chk(x)` throws past `281474976710655` (2^48−1): `Nat` is a guarded immediate, so
   `PrimNatAdd` is *not* `arith.addi i64` — it is `add` + compare + conditional abort
   (a runtime call), and `PrimNatSub` saturates at 0 (`a<b?0:a-b`).
3. `F32` ops are `Math.fround`-wrapped, i.e. float32 rounding at every step. `math` ops
   carry fast-math flags; none may be set (`[INFERENCE]`: setting them changes NaN/sign-of-zero
   observations that `B1` names explicitly).

None of this is a reason to avoid MLIR; it is a reason to be precise that a "primitive →
`arith`" table is a *semantic translation with UB obligations*, not a renaming.

---

## 5. `affine`: a terminology warning (not a finding about the hypothesis)

Bend's affine is a **quantity/resource discipline**: `QZero/QOne/QMany` at the source
(`SELFHOST_IR_ARCHITECTURE.md` §4 `L1`, `L4`), lowered to `Erased/Once/Unrestricted` and then
to `Use = Affine|Many` (`backend_ir.bend:6-11`, `catalog` mapping in `lower_catalog.bend`
per `BIR_LAWS.md` §4.3). It means *how many times a value may be consumed*, and it is what
licenses C's `term_keep` vs `rfc_seal` sealing and forbids duplication.

MLIR's affine is **polyhedral index algebra** `[READ]`:

- "Dimensions and symbols … are always of `index` type"; symbols must be region arguments,
  values defined at the top level of an `AffineScope` op, dominating values, constants, or
  results of `Pure` ops over valid symbols.
- `affine.for`'s "lower and upper bounds … are represented as an application of an affine
  mapping to a list of SSA values", with `step` "a positive constant integer".
- The whole dialect exists to make "loop transformations efficient and reliable" over
  regular loop nests.

There is **no overlap** with ownership, with drop/copy, with closures, or with
dependent descriptors. A Bend program's control flow is data-dependent (a parser walking
tokens, a match on a runtime tag); nothing in it is an affine loop nest. Applying the affine
dialect would require first proving that some kernel is an index-space nest with
affine-map bounds — a *different* optimization project, and one that would also have to
answer how boxed terms become `memref`s.

So: **`affine` is a naming coincidence, and that is all this section claims.** The request
pointed at the walkthrough's *dialect list*; it did not claim that MLIR's affine dialect
implements Bend's quantities. The warning is practical: a future design decision must not be
justified by the shared word, and if Bend ever wants polyhedral loop work, that is a different
project requiring an index-space kernel first. What Bend's affine needs is §4.5: carried use
facts, a use-count verifier, and per-pass legality — MLIR has no built-in facility for that.

---

## 6. GPU and WASM routes

### 6.1 GPU: real, but NVIDIA/AMD-only, and not a scheduler

`[READ]` GPU dialect doc:

- "Note: this dialect is more likely to change than others in the near future; use with
  caution."
- Compilation: `gpu-kernel-outlining` → `nvvm-attach-target` (or `rocdl`) →
  `convert-gpu-to-nvvm` → `gpu-to-llvm` → `gpu-module-to-binary` → `mlir-translate
  --mlir-to-llvmir`; binaries become `gpu.binary`/`#gpu.object` with an offloading attribute
  that emits the host-side launch.
- `gpu-lower-to-nvvm-pipeline` "operates by lowering primary dialects (arith, memref, scf,
  vector, gpu, and nvgpu) to NVVM" and **"specifically requires explicitly parallel IR and
  doesn't do GPU parallelization. To enable parallelism, necessary transformations must be
  applied before"**.
- NVVM doc: "NVVM sits below target-agnostic dialects like `gpu` … then translate into LLVM
  for final code generation via NVPTX backend"; ROCDL is "wrappers around the AMD-specific
  intrinsics" and participates in "the built-in compilation/offloading framework".
- Toolchain: the official build recipe builds LLVM with
  `-DLLVM_TARGETS_TO_BUILD="Native;NVPTX;AMDGPU"`
  ([Getting Started](https://mlir.llvm.org/getting_started/)); cubin/hsaco serialization is
  done in-process by those LLVM backends, and a driver/runtime is still required to launch
  (CUDA driver / ROCm). `[READ]` for the pieces; `[INFERENCE]` for "still need a runtime".

Bend's actual GPU story, for contrast `[READ]`:

- The legacy compiler writes C that is compiled twice — host clang and device
  `__METAL_VERSION__`/`BEND_CUDA` — and `#define BANGS ${FL.bangs.size}` reflects the real
  number of dispatches (`comp.ts:3209`, `:3651`, `:3681`, `:3928`).
- The BIR-based C target hardcodes `#define BANGS 0` (`c_backend.bend:2848`), and BIR has no
  bang/dispatch node at all (`backend_ir.bend:178-203`). So "GPU in the new pipeline" is not
  a dialect question; there is no node to lower.

Implication `[INFERENCE]`: MLIR's `gpu`/`nvvm`/`rocdl` can be a *direct* executor only for an
NVIDIA/AMD device path, and only after BIR gains an explicit parallel construct.

**Metal is a qualification, not a flat "impossible".** No upstream dialect has a Metal/MSL
target attribute, so there is no direct route. An indirect one has tooling behind it:
the `spirv` dialect serializes SPIR-V (Vulkan/OpenCL consumers), and SPIRV-Cross converts
SPIR-V to MSL — "Convert SPIR-V to readable, usable and efficient Metal Shading Language
(MSL)" ([KhronosGroup/SPIRV-Cross README](https://github.com/KhronosGroup/SPIRV-Cross),
read 2026-10-24). The same README states the real constraint: "Individual features are
expected to be mostly complete, but it is possible that certain obscure GLSL features are not
yet supported." So a Metal route through MLIR would be *SPIR-V → third-party translator →
MSL*, carrying: a third-party dependency at a pinned version, SPIR-V feature coverage risk,
a second device programming model (gpu/SPIR-V) beside the existing one, and still the Bend
device-model mapping (shared heap, runtime dispatch, lane semantics) that no dialect
provides. That is materially more work and risk than the existing second clang invocation
over MSL, but it is a trade to be evaluated, not a prohibition. Cross-reference
`RESEARCH_GPU.md` for the executor evidence; I am not restating it.

### 6.2 WASM: LLVM already is the route; `wasmssa` is not a codegen backend

- The standard path is LLVM's WebAssembly backend: wasm object emission with the wasm32
  target, linked by `wasm-ld` — "The WebAssembly version of lld takes WebAssembly binaries as
  inputs and produces a WebAssembly binary as its output. This is object format that llvm
  will produce when run with the wasm32 target"
  ([lld WebAssembly docs](https://releases.llvm.org/8.0.0/tools/lld/docs/WebAssembly.html),
  `[READ]`).
- MLIR's in-tree `wasmssa` dialect is "intended to represent WebAssembly modules in SSA form
  for easier manipulation" — a *target-level* model with `wasmssa.func`, `wasmssa.memory`,
  and wasm's structured levels (`wasmssa.block`, `wasmssa.branch_if … to level N`,
  `wasmssa.block_return`). It is not a source-level wasm dialect, and the doc I read
  documents no wasm-binary emitter.
- Consequence: adding MLIR to reach WASM adds a layer that still ends in the LLVM wasm
  backend. Cross-reference `RESEARCH_WASM_WASI.md`; my contribution there was the `wasmssa`
  existence/shape and the BIR boundary facts, which that note owns.

One genuinely interesting detail for §4.1: `wasmssa` models exactly the construct BIR needs —
a labeled nesting level with `branch_if … to level N` and a `block_return` to the level's
successor. So *if* Bend ever needed a structured-exit IR with explicit levels, wasm's shape
(and `wasmssa`'s) is closer to `Region`/`LeaveRegion` than `scf` is. That does not make it a
Bend IR; it confirms that BIR's construct is a standard one (structured labeled exit), just
not one MLIR's SCF provides.

---

## 7. Four architectures, compared honestly

| # | Architecture | What is new | Gets us | Costs | Verdict |
|---|---|---|---|---|---|
| **A** | BIR → standard dialects (`func`/`arith`/`cf`/`scf`/`llvm`) → LLVM IR → object | a BIR→MLIR emitter + type discipline (§4.2) | MLIR verifier; BIR-level facts stay addressable for custom passes; LLVM backends (x86/arm64/NVPTX/AMDGPU/wasm); debug info limited by the absence of spans | box/unbox or a new type-recovery pass; C ABI + refcount still hand-written; LLVM/MLIR toolchain pinned; a second native lane beside `c_backend`; the pass benefit is unproven until M2/M3 | Only if a native lane is wanted *and* direct LLVM IR (D) is rejected |
| **B** | A custom `bend` dialect kept as the real backend IR, converted to A | ODS dialect + verifiers + conversion + versioning | structural WF checks (§4.6); dialect-level info survives | everything in A, plus a second source of truth next to `backend_ir.bend`; upstream churn (§7.1); a C++ build in a Bend-only toolchain | **Not now.** This is the "become Mojo" option and the cost is the reason to refuse it |
| **C** | stay: BIR → C (segmented runtime ABI) → clang; BIR → JS | nothing | already exists (`c_backend.bend`, `js_backend.bend`); clang already runs the LLVM optimizer over the emitted C | no IR-level verification; no structured-analysis passes; BIR-level facts (descriptors, case/region structure, affinity) are destroyed at emission | **Keep as the baseline**, but not because A is redundant: C gives up facts and verification that A/B preserve. It is the incumbent to beat, not a proof that nothing better exists |
| **D** | BIR → LLVM IR text directly (no MLIR) | an LLVM-IR printer | same backends as A, one less layer and one less toolchain | hand-writing LLVM IR text (attributes, ABI, DILocation) is its own maintenance; no verifier benefits; text is version-unstable (see `RESEARCH_LLVM.md`) | Compare against `RESEARCH_LLVM.md`; on the evidence I have, **C currently beats D** because clang already is the LLVM frontend+driver, but D would preserve control; it is a maintenance trade, not a proof |

Where the options genuinely differ, stated without overclaiming `[INFERENCE]`:

- **Reaching LLVM's optimizer and target breadth is not, by itself, an argument for MLIR.**
  clang compiles the emitted C to LLVM IR already, so the LLVM middle-end and the LLVM
  targets are available on the current lane. MLIR is then *one possible front half*, not the
  only route. This does **not** mean MLIR's other benefits are redundant — only that "we get
  LLVM" is not one of them.
- **Preserving backend facts before C is a real, distinct benefit.** C emission erases
  descriptors/NF, the `Region`/case structure, the closure/capture structure, and the
  `Affine`/`Many` facts. An MLIR layer keeps them addressable, which enables (i) a verifier,
  (ii) custom passes over BIR-shaped structure, and (iii) diagnostics that name a
  constructor/family rather than a C identifier. Whether such passes *pay* is unmeasured
  here and is exactly what M2/M3 would test. This benefit is independent of codegen speed
  and is the reason a custom dialect (option B) is a coherent design even though I do not
  recommend starting there.
- **Verification and structural analysis** (the `WF`/`BL-1` gap) is the cheapest benefit to
  obtain: the *front half* only (A's emitter + verifier, no LLVM translation). That is M1.
- **GPU or WASM** are not arguments for MLIR on their own: wasm already goes through
  clang/LLVM; GPU has no direct Metal route (§6.1) and needs an explicit parallel construct
  that BIR does not have.

### 7.1 Maintenance cost of any MLIR link, with evidence

- **No stable C++ API.** The C API page says: "Current status: Under development, API
  unstable, built by default", and "while the C API is expected to be more stable than C++
  API, it currently offers no stability guarantees"
  ([MLIR C API](https://mlir.llvm.org/docs/CAPI/)). Its scope is "core IR components …,
  Passes and some fundamental type and attribute kinds" — dialect-specific semantics are
  explicitly left to dialect-specific wrappers, i.e. C++.
- **Active churn.** MLIR publishes a deprecation/refactoring list naming, for example,
  `matchAndRewrite` replacing `match`/`rewrite`, `OpTy::create` replacing
  `OpBuilder::create`, the `Properties` generic-printing change, and the deprecation of
  `gpu-to-(cubin|hsaco)` in favour of GPU compilation attributes
  ([Deprecations](https://mlir.llvm.org/deprecation/)).
- **LLVM's own policy** is C-API-oriented stability only, with "Release stability" limited to
  not breaking the C API on a release branch; LLVM IR *text* has "no specific promises"
  ([Developer Policy](https://llvm.org/docs/DeveloperPolicy.html)).
- **Bytecode/versioning**: a dialect may opt into versioning "through the
  `BytecodeDialectInterface`", and "Currently, versioning is supported only for bytecode
  formats" ([LangRef §IR Versioning](https://mlir.llvm.org/docs/LangRef/)). So an MLIR
  artifact is not a stable interchange format by default; Mojo needed explicit
  `*Bytecode.td` and a `DialectChecksum` library to package precompiled modules.
- **Toolchain weight** `[INFERENCE]`: an MLIR link means shipping `mlir-opt`/`mlir-translate`
  (or libMLIR + LLVM) at a pinned commit, a C++ build (Getting Started requires CMake/Ninja/
  C++ and `LLVM_ENABLE_PROJECTS=mlir`), and pick-version alignment between the pinned MLIR and
  the system clang used for the C lane. Today's C lane needs clang only.

---

## 8. Laws a target must instantiate (proposals, not claimed theorems)

Per `SELFHOST_IR_ARCHITECTURE.md` §4 and `BIR_LAWS.md` §4, an MLIR target does *not* inherit
any law. The following are **new obligations a future MLIR lane would have to state and
prove** — they are listed so the FIR/BIR law owners can reject or adopt them, not as
achieved results.

| Law | Obligation for an MLIR lane | Why it is not free |
|---|---|---|
| M-A (structure) | The emitted module is legal under MLIR's region/dominance/branch rules, and every BIR `Region` has exactly one exit path reachable only through its `LeaveRegion` | `WF-4`/`WF-5` are producer obligations today; MLIR will happily verify a *differently* shaped CFG |
| M-B (types) | Every opaque `!bend.value` corresponds to exactly one BIR `Atom` use, and every typed value's descriptor equals the descriptor the checker established (no guessing) | `BL-2` says erasure dropped types; recovery must agree with descriptors, not with inference convenience |
| M-C (erasure) | No erased position becomes an operand, a result, or an ABI slot | `BL-2`, `L1` |
| M-D (affinity) | Consumption counts observed in the IR never exceed the carried use fact, and a copy is an explicit, checkable program construct | `BL-3`, `L4`. Requires: the use fact carried as an attribute/type, a use-walk verifier, explicit consume/transfer ops or distinct affine types, and per-pass legality. **Effects/speculatability alone do not express or enforce linearity** (§4.5) |
| M-E (order/effects) | `LoadSymbol`, `Foreign`, `Failure` carry effects that forbid reordering/elimination; lazy symbol reads are per-read | `L2`, `B2`; `js_backend.bend:951` |
| M-F (primitives) | Each of the 112 primitives maps to an MLIR op or runtime call whose *defined* behaviour equals `B1`'s, including `div/0`, `mod 0`, Nat's 2^48 guard, and float32 rounding without fast-math | §4.7; `arith` div/rem are UB on zero |
| M-G (descriptors) | Descriptor/NF data attached to the module denotes the same program the codes implement | `BL-7`; MLIR cannot check it (§4.4) |
| M-H (determinism) | Emitted text is byte-identical for one canonical input *at a pinned MLIR version*, or the law is restated as semantic equality | `G1` currently assumes no external tool; MLIR printing/versioning is an added variable |

If any of M-D/M-F/M-H is left unstated, an MLIR lane can be *more* dangerous than the C
lane: it introduces an optimizer whose defaults assume things Bend's laws deny.

---

## 9. Bounded experiments and acceptance (if this is pursued)

All of these are research-scoped: no cutover, no new dependency in the shipping build, no
heavy lane. M1 is the only one I recommend running.

**M1 — emission with verification *and* valid-program semantics (recommended, research-scoped).**
Emit `func`/`arith`/`cf` from a *fixed, small* BIR corpus, restricted so semantics are
executable without the Bend runtime: programs whose observations depend only on `U32`/`F32`
primitives, constructors and matches — no foreign, no lazy symbol, no closures. The corpus
must contain one program per structural feature: nested match, an early `LeaveRegion` exit,
a tail-recursive code, and a `Failure` path. Acceptance (all four, in this order):

1. **Valid-program semantics — the primary criterion, not malformed rejection.** Every valid
   corpus program's module executes (via `mlir-runner`/`mlir-cpu-runner` JIT in the
   *experiment*, never in the shipping build) and its observations equal the recorded
   observations of the existing JS lane for the same program: result value, exit status,
   stdout bytes, and for the `Failure` case the same message. A program that verifies but
   produces a different observation is a failure, not a warning.
2. **Structural fidelity.** Reading the module back and walking the documented §4.1 encoding
   reproduces BIR's case order and exit targets for every corpus program — this catches an
   encoding that is legal MLIR but a *different program*, which (1) can miss when the wrong
   branch happens not to change the result.
3. **Malformed rejection (necessary, not sufficient).** Hand-built *invalid* BIR programs
   that are legal Bend data — duplicate code id, duplicate region label, `Local` referring
   to no enclosing `Let`/`Parameter`, capture slot out of range, `Direct` arity ≠
   captures+parameters, constructor field id not in the layout, non-Boolean
   `Branch.condition` — each produce a **diagnostic** from the emitted module's verifier.
   This maps to `BIR_LAWS.md` §3.7's `[O]` column.
4. No change to `backend_ir.bend`, `backend_lower.bend`, either renderer, or any law text;
   and explicitly **no performance claim** — M1 is not a backend and must not be scored as
   one.

If (3) cannot be achieved without adding information to BIR, that is a **result**: the
verifier win then requires an IR change, which is out of scope, and the hypothesis fails
cheaply. If (1) holds but (2) does not, the encoding is wrong; if (2) holds but (1) does not,
the value/primitive mapping is wrong — the split keeps the failure legible.

**M2 — typed-value feasibility (only if M1 passes and someone wants `arith`).**
Take one BIR code that is all `U32`/`F32` primitives plus one constructor, and recover types
per `Local`. Acceptance: every recovered type equals the descriptor at the corresponding
primitive call site (`PrimitiveCall.types`) and constructor field, with zero mismatches on
the corpus; any mismatch is a hard failure (not "fixed by inference"). This measures whether
M-B is achievable, not whether it is fast.

**M3 — one end-to-end native comparison (explicitly not a performance claim).**
One program through §7 option A or D, compared against the existing C lane on *observations*:
exit code, stdout bytes, thrown `Failure` message, and the order of IO effects. Acceptance is
behavioural equality plus a recorded compile-time/binary-size *number*, with the hardware,
compiler versions and flags recorded and **no** claim that MLIR is faster or slower.

**M4 — GPU: do not run.** Acceptance for this note is the *decision record*: BIR has no
bang node (`c_backend.bend:2848` emits `BANGS 0`; `backend_ir.bend:178-203` has no dispatch
op), MLIR has no *direct* Metal target (§6.1), and `gpu-lower-to-nvvm-pipeline` needs IR that is
already parallel. Cross-reference `RESEARCH_GPU.md` for what the legacy Metal/CUDA path does.

Explicit non-goals for all four: no custom `bend` dialect, no `scf`-based loop work (BIR has
no loops), no bytecode/packaging work (Mojo's `*Bytecode.td` is the counter-example), no
change to stack/heap/fuel caps, no new benchmark, no native-acceptance run.

---

## 10. Open questions

1. **Does the selfhost constraint forbid the useful boundary?** The compiler must run as Bend;
   MLIR is C++. The only Bend-embeddable boundaries are (a) subprocess `mlir-opt`/`mlir-translate`
   over textual IR and (b) the C API (unstable, §7.1). If a compile-time budget of ~5 minutes
   for a full working cycle (`SELFHOST_IR_ARCHITECTURE.md` §5) is to be defended, a subprocess
   round-trip per compilation is a measurable cost — **unmeasured here**, and the first thing a
   real M1 would have to record.
2. **Is the WF gap really the bottleneck?** `BIR_LAWS.md` §3.7 says checks are almost all
   `[N]`. If the team's actual failure mode is "BIR producer bugs", then a *Bend-side*
   `validate` function (pure Bend, no dependency) delivers the same verification as M1 without
   MLIR. That is a legitimate competing answer and I would not object to it; M1's value is
   that it makes the checks declarative, not that it is the only way.
3. **Does preserving BIR-level facts actually buy anything measurable?** No experiment exists
   yet. A custom pass over descriptors/case structure/affinity (option B) or over a typed
   subset (A) has to be shown to produce a better decision than the C lane makes today — e.g.
   fewer allocations, fewer trampolines, fewer tag tests. Until then, "preserved facts" is a
   plausible benefit, not a demonstrated one, and it is the strongest remaining case for MLIR.
4. **Where would types come from for `arith`?** M2 answers feasibility, not desirability:
   `PrimitiveCall.types` is descriptor-level, and descriptors are canonical *keys* plus
   structure, so a mapping descriptor→MLIR type must be defined (U32→i32, F32→f32,
   Nat→i64+guard, Array→runtime handle, …). Any mapping that is not total is a hole.
5. **What would a `bend` dialect actually hold** that `func`/`cf` cannot? My list is: (i)
   `bend.region_exit`, (ii) `bend.lazy_symbol` with read-effects, (iii) `bend.foreign` with
   declared sources/quantities, (iv) `bend.construct/project/has_tag` with layout,
   (v) descriptor attributes. Items (i)–(iv) are exactly what §4.1/§4.5 show can be
   expressed with standard ops + calls today, at the price of losing the source-level
   meaning. That is the trade: a custom dialect buys *diagnostics*, not codegen.
6. **Debug info.** BIR drops spans, so *line-accurate* DI is blocked today and would need new
   BIR metadata — out of scope. That is a limitation, not an impossibility: MLIR can carry
   locations that are not spans — the builtin dialect defines `NameLoc` ("A named source
   location"), `CallSiteLoc`, and `FusedLoc`
   ([Builtin dialect](https://mlir.llvm.org/docs/Dialects/Builtin/)) — so subprogram/variable
   names without lines are representable now. That is enough for symbol-level stack frames,
   not for stepping, so debug info is a weak argument for MLIR today, not a blocked one.
7. **Reproducibility.** `G1` demands byte-identical stages for one canonical input. Pinning
   MLIR makes output depend on a second compiler version; is that acceptable to the
   reproducibility law, or does it need an amendment? Unresolved and owner-dependent.

---

## 11. What would change this verdict

- **BIR grows an explicit parallel/dispatch node** (a bang) — then MLIR's `gpu` path becomes
  relevant for NVIDIA/AMD, and a device lane would be evaluated on its own terms (§6.1).
- **BIR grows source locations** — then line-accurate MLIR→LLVM debug info becomes available;
  even without spans, name-based DI (`NameLoc`) is already representable (§10.6).
- **The runtime's value representation becomes static** (real closure structs, real
  constructor layouts, refcounts modelled as ownership) — then LLVM/MLIR optimizations start
  to fire and the C-vs-MLIR comparison changes (§4.3).
- **A Bend-side `validate` proves impractical or drifts from the spec** — then M1's
  declarative verification gains a concrete counter-argument (§10.2).
- **A second native target with nontrivial ABI (e.g. a GPU target we must support) has to
  ship from the selfhost compiler** — then the "clang already gives us LLVM" argument (§7)
  weakens for that target, because clang cannot produce device binaries for Metal.

Until one of those happens, the defensible position is **keeping the C/JS lanes as the
shipping backend and BIR as the IR**, while treating MLIR as (i) an optional verification
harness and (ii) a candidate place to preserve facts for future passes — both to be settled
by the bounded experiments above. Nothing here closes the comparative question: **no
experiment, no measurement and no performance comparison between the MILR-shaped options and
the current C lane exists yet**, and this note deliberately does not manufacture one.

---

## 12. Sources

Upstream specs/docs (**read 2026-10-24**; all are primary — official docs or upstream source):

- MLIR LangRef — regions, value scoping, blocks/terminators, dominance, IR versioning:
  https://mlir.llvm.org/docs/LangRef/
- MLIR dialect index: https://mlir.llvm.org/docs/Dialects/
- `scf`: https://mlir.llvm.org/docs/Dialects/SCFDialect/
  (`scf.for` single block + `scf.yield`; `scf.execute_region` multiple blocks/terminators)
- `cf`: https://mlir.llvm.org/docs/Dialects/ControlFlowDialect/
- `arith` (division by zero is UB): https://mlir.llvm.org/docs/Dialects/ArithOps/
- `affine` (index-typed dims/symbols, restrictions, affine-map bounds, constant step):
  https://mlir.llvm.org/docs/Dialects/Affine/
- `func`: https://mlir.llvm.org/docs/Dialects/Func/
- `llvm` (data layout/triple, dependency on LLVM IR objects):
  https://mlir.llvm.org/docs/Dialects/LLVM/
- `gpu` (caution note; compilation overview; "requires explicitly parallel IR and doesn't do
  GPU parallelization"; module serialization/offloading): https://mlir.llvm.org/docs/Dialects/GPU/
- `nvvm` ("sits below … gpu", `#nvvm.target`, NVPTX codegen):
  https://mlir.llvm.org/docs/Dialects/NVVMDialect/
- `rocdl`: https://mlir.llvm.org/docs/Dialects/ROCDLDialect/
- `spirv`: https://mlir.llvm.org/docs/Dialects/SPIR-V/
- `wasmssa` (wasm modules in SSA form; `block`/`branch_if`/`block_return`):
  https://mlir.llvm.org/docs/Dialects/WasmSSAOps/
- `emitc` (`-mlir-to-cpp`, C99 by default): https://mlir.llvm.org/docs/Dialects/EmitC/
- `ml_program` ("under active development … stability is not guaranteed"):
  https://mlir.llvm.org/docs/Dialects/MLProgramOps/
- `ub` (`ub.poison`, `ub.unreachable`): https://mlir.llvm.org/docs/Dialects/UBOps/
- `ptr`: https://mlir.llvm.org/docs/Dialects/PtrOps/
- Builtin dialect — location attributes `NameLoc` ("A named source location"), `CallSiteLoc`,
  `FusedLoc`: https://mlir.llvm.org/docs/Dialects/Builtin/
- Dialect Conversion (partial/full/analysis, legality, target): https://mlir.llvm.org/docs/DialectConversion/
- Side effects & speculatability ("no proper modeling yet … non-local control flow";
  rematerialization; graph-region effects TBD):
  https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/
- ODS / Defining Dialects (custom verifiers `hasVerifier`/`hasRegionVerifier`, traits):
  https://mlir.llvm.org/docs/DefiningDialects/Operations/
- MLIR C API ("Under development, API unstable"; "no stability guarantees"):
  https://mlir.llvm.org/docs/CAPI/
- MLIR deprecations/refactorings: https://mlir.llvm.org/deprecation/
- MLIR getting started (CMake/Ninja/C++, `LLVM_ENABLE_PROJECTS=mlir`,
  `LLVM_TARGETS_TO_BUILD="Native;NVPTX;AMDGPU"`): https://mlir.llvm.org/getting_started/
- LLVM developer policy (C API release stability; LLVM IR text "no specific promises"):
  https://llvm.org/docs/DeveloperPolicy.html
- lld WebAssembly (wasm object output for the wasm32 target):
  https://releases.llvm.org/8.0.0/tools/lld/docs/WebAssembly.html
- SPIRV-Cross (third-party SPIR-V → MSL/GLSL/HLSL translator; README states the MSL
  capability and the feature-coverage caveat): https://github.com/KhronosGroup/SPIRV-Cross
- Mojo compiler walkthrough (phases, dialect hierarchy, pass list):
  https://github.com/modular/modular/blob/main/Mojo/docs/compiler/MojoCompilerWalkthrough.md
- Mojo source availability/license — verified via the GitHub contents API and raw files:
  - dirs: `Mojo/lib/{LIT,KGEN,POP,HLCF,CO}Dialect`, `LowerLIT`, `Elaborator`, `KGENToLLVM`,
    `Interpreter`, `Transforms`, `Compiler/Pipeline`, `Target`, `ExecutionEngine`,
    `DepGraphDialect`, `DialectChecksum`
  - `Mojo/include/Mojo/{LIT,KGEN,POP,HLCF}Dialect/*.td`
  - `Mojo/lib/LITDialect/LITOps.cpp` (98,442 bytes, Apache-2.0-with-LLVM-exceptions header)
  - `Mojo/lib/Transforms/LowerHLCFToSCF.cpp` (includes `mlir/Dialect/SCF/IR/SCF.h`,
    `Arith.h`, `IndexOps.h`, `UBOps.h`; uses `DialectConversion`)
  - `Mojo/lib/KGENToLLVM/CABI{AAPCS,SystemV,CallHelpers}.cpp` (hand-written C ABI lowering)
  - `Mojo/BUILD.bazel` (`@llvm-project//mlir:mlir-tblgen`, `gentbl_mlir_dialect`)
  - `LICENSE` ("Apache License v2.0 with LLVM Exceptions")

This repository at `f46ad0f6` (baseline == `work/fir-ir-integrated57ab`):

- `bend2/selfhost/backend_ir.bend:6-11` `Use`/`Quantity`; `:13-23` `Atom`; `:33-150`
  `Primitive` (112 constructors); `:152-176` `Descriptor`; `:178-187` `Op`; `:189-203` `Block`
  (+ the "lexical forward control flow" comment); `:203-204` `Code`; `:205-208` declaration
  note ("Nullary declarations are reevaluated on every read"); `:209-215` `Declaration`
  (incl. `ForeignDeclaration` with `sources`, `quantities`, `parameter_types`, `result`);
  `:216` `ConstructorLayout`; `:219-226` `Family`/`TypeFunction`; `:228` `Export`;
  `:233` `Program`; `:236-239` `SourceFile`
- `bend2/selfhost/backend_lower.bend:1200`, `:1220` — match rows as `Region`/`LeaveRegion`
- `bend2/selfhost/js_backend.bend:577-578` (Direct/Apply → `run_loop`), `:593-642`
  (tagged regions → `switch`), `:627-628` labelled case block, `:643-652` `Region`/`LeaveRegion`
  → `$caseN`/`break`, `:655-660` `Code`, `:894` primitive runtime table
  (`$p_u32_div=(a,b)=>(b===0?0:…)`), `:951` lazy getter re-evaluated per read,
  `:1090` export arity dispatch, `:1165` tail trampoline **and** `nat_chk` (the 2^48−1 guard)
- `bend2/selfhost/c_backend.bend:9-42` runtime-ABI contract header, `:2258` `branch_ctl`,
  `:2275` `region_ctl`, `:2303` `leave_ctl`, `:2314` `tail_direct_ctl`, `:2434`
  `load_symbol_ctl`, `:2848` `#define BANGS 0`, `:3173` `emit`
- `bend2/selfhost/descriptor_nf.bend:1-20` (one normalizer for both targets; names the
  reference `$type*` evaluator in `comp.ts`)
- `bend2/selfhost/emitter.bend:1-14` (one lowering, both target entry paths)
- `bend2/comp.ts` at `f46ad0f6`: `:3209` `#define BANGS ${FL.bangs.size}`,
  `:3651`/`:3681`/`:3928` `__METAL_VERSION__` / `BEND_CUDA` device compilation
- `checkpoints/SELFHOST_IR_ARCHITECTURE.md` §2 (lowering boundary), §3 (what BIR executes),
  §4 (laws F1–F3, L1–L7, B1–B2, G1–G2, K1–K5), §5 (acceptance and the ~5-minute budget)
- `bend2/selfhost/BIR_LAWS.md` (peer branch `bir-laws-doc`; WF-1…WF-6, §3.7 status table,
  §4.1–§4.11 including BL-1/BL-2/BL-3 and the "no `validate` function" statement)
