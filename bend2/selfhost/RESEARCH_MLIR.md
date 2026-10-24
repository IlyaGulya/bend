# Research: is an MLIR-based path a better fit for the Bend backend?

Research note. **No implementation, no new IR, no new dependency, no benchmark claim.**
Baseline: `f46ad0f6` (the integration branch `work/fir-ir-integrated57ab` is at the same
commit, so every BIR line number below is current, not historical).
All external material was read on **2026-10-24** at the URLs in §12; upstream claims were
re-checked against the actual files where a documented path could have been stale (§2.2).

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

The hypothesis has three separable parts, and they do not have the same answer:

1. **"An IR with regions, dominance, verifiers and interfaces would help."** Largely true —
   but only for the part of the backend that is currently *unchecked* (§4.6), not for
   codegen.
2. **"MLIR's dialects/optimizations would make generated code better than what we emit
   today."** Mostly false for the boxed-Term runtime: the optimization blockers are the
   value representation and the runtime ABI, not the IR (§4.3, §7). Whatever LLVM-level
   optimization is available through MLIR is already available by compiling the emitted C
   with clang (§7, option C).
3. **"MLIR's affine dialect matches Bend's affine quantities."** Falsified: same word,
   unrelated concepts (§5).

---

## 1. Answer in one screen

| Claim | Verdict | Evidence |
|---|---|---|
| MLIR can express BIR's lexical `Region`/`LeaveRegion` control flow | **Yes, but not natively.** MLIR's scoping rule matches BIR exactly; its *branching* rule forbids the exit. Three encodings exist, all with a cost (§4.1). | LangRef §Value Scoping, §Blocks; BIR `Block` at `bend2/selfhost/backend_ir.bend:194-202` |
| BIR maps to MLIR SSA directly | **No.** BIR atoms carry no type; MLIR requires a static type per value. Either an opaque `!bend.value` (kills `arith`/`math`) or a new type-recovery analysis that re-does work `BL-2` says was deliberately erased. | `Atom` `backend_ir.bend:13-23`, erasure law `BIR_LAWS.md` §4.2 |
| MLIR's verifier would buy something real | **Yes, the single clearest win.** `WF-1…WF-11` are currently `[N]/[O]` — specification-only, no validator (`BIR_LAWS.md` §3, §3.7). An ODS'd dialect turns most of them into mechanical checks. | DefiningDialects/ODS `hasVerifier`/`hasRegionVerifier` |
| MLIR's affine dialect models Bend's `Affine`/`Many` | **No.** MLIR affine is polyhedral index algebra (index-typed, affine maps, constant positive step). Bend affine is a linear-use *resource* discipline. | Affine dialect doc; `Use`/`Quantity` `backend_ir.bend:6-11`; `BL-3` |
| MLIR would give us Metal | **No.** Upstream GPU object targets are `#nvvm.target` (NVPTX) and `#rocdl.target` (AMDGPU) only; there is no MSL/Metal target attribute. | GPU dialect doc §Module serialization; NVVM/ROCDL docs |
| MLIR would parallelize the fork tree | **No.** `gpu-lower-to-nvvm-pipeline` "specifically requires explicitly parallel IR and doesn't do GPU parallelization". | GPU dialect doc §Default NVVM Compilation Pipeline |
| Adopting MLIR is a small dependency bump | **No.** MLIR has no stable C++ API, the C API is "under development, API unstable" with "no stability guarantees", and the project publishes an active deprecation list. A Bend-side integration can only be a pinned subprocess or an unstable FFI. | MLIR C API page; Deprecations page; LLVM developer policy |
| Mojo's dialects are reusable | **No, and that is fine.** They are real, public and Apache-2.0-with-LLVM-exceptions, but `LIT` is a *source-level* IR (Bend has AST+FIR), `KGEN` carries parametric elaboration Mojo-only machinery, and all of them are glued to Mojo's type system. `HLCF`→`scf` is the only transferable *idea*, and it is an idea, not code (§2.3). | `Mojo/lib/*` listing, `LowerHLCFToSCF.cpp` |

**Recommendation (research conclusion, not a target decision):** do not adopt MLIR as a
Bend backend target now. If it is pursued, pursue exactly one bounded experiment —
**M1: emit standard-dialect MLIR from BIR for verification only** (§9) — because that is the
only benefit that does not duplicate something the C+clang lane already delivers. No
custom `bend` dialect, no selfhost cutover, and no GPU work follows from this note.

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
| `debuginfo` | A whole dialect + `DIBuilder` + DI-expression tracking through SROA/mem2reg, then `DebugInfoToLLVM` | **No, and it is a warning.** BIR has no source spans at all (`Failure{message}` only), so a debug-info story would require *adding* spans to BIR first. |
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
| One opaque type, e.g. `!bend.value` | Faithful to BIR and to `BL-2`, trivially legal, but every `arith`/`math` op is unavailable: all 112 primitives become calls into the runtime, and MLIR's middle-end has nothing typed to fold. This is *not worse* than the current C output — the runtime already owns arithmetic (`js_backend.bend:894`) — but it means MLIR adds no arithmetic optimization. |
| Recover concrete types per value | Requires a new analysis mapping each `Local` to a descriptor (from primitive call sites, constructor layouts, and parameter descriptors). Real work, and it re-derives information that the checker had and that erasure (law `BL-2`, `L1`) deliberately dropped — so it must be proven against the descriptors, not guessed. This is the only route on which `arith`/`math`/`vector` passes can fire. |
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

In MLIR this is **not** expressible as ops, and should not be: nothing executes descriptors
at compile time in a way the IR must serialize. It would be:

- a `DictionaryAttr`/`ArrayAttr` blob on the module,
- or a custom attribute with a verifier (if the WF checks of §4.6 are wanted),
- or the static image the C target already emits (`STAT_IMG`, `SHOW_DESC`).

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
| `Closure`/`Direct`/`Apply` | Call-like; `CallOpInterface` if you want inlining to see through | inlining across an affinely used capture duplicates a use (`L4`, `BL-3`) |
| `Failure` | Abort; not speculatable, no return | adding a "may not happen" assumption is wrong: it *does* happen and is observable |
| `Region`/`LeaveRegion` | Must implement region-branch interfaces (§4.1) | a verifier-blind exit silently miscompiles |

**The `Affine`-use hazard is the sharpest one.** `BL-3` says every `Arg.use`/`Parameter.use`/
`Field.use`/`Code.captures` entry is an upper bound on consumption: `Affine` = at most once,
`Many` = zero or more. MLIR has no notion of this, and its *default* optimization posture
(rematerialize pure computation, duplicate into branches, sink/hoist) is exactly what
duplicating an at-most-once value would break. A conversion therefore has two options:
(a) mark any op whose operands are affine as *effectful and non-speculatable* (loses
optimization, keeps `BL-3`), or (b) carry affine-ness in the type system and prove no pass
duplicates it (a research project, not a port). Option (a) is the only one I would accept
without a new law.

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

## 5. `affine`: the homonym, falsified

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

So: **`affine` is a naming coincidence.** The user's instinct that "Bend is affine, MLIR has
affine" does not survive contact with either definition. What Bend's affine needs is what §4.5
describes: a target-side legality rule that no pass duplicates an at-most-once value — and
MLIR has no facility for that beyond marking ops effectful.

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

Implication `[INFERENCE]`: MLIR's `gpu`/`nvvm`/`rocdl` could only ever be an executor for an
*NVIDIA/AMD* device path, and only after BIR gains an explicit parallel construct. There is
no MSL/Metal target in upstream MLIR, so **on macOS MLIR cannot replace the existing
MSL-via-clang design** — it would add a second device programming model with no Metal
output. Cross-reference `RESEARCH_GPU.md` for the runtime/executor evidence; I am not
restating it.

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
| **A** | BIR → standard dialects (`func`/`arith`/`cf`/`scf`/`llvm`) → LLVM IR → object | a BIR→MLIR emitter + type discipline (§4.2) | MLIR verifier; LLVM backends (x86/arm64/NVPTX/AMDGPU/wasm) for free; debug info *if* spans existed | type recovery or opaque values; C ABI + refcount still hand-written; LLVM/MLIR toolchain pinned; a second native lane beside `c_backend` | Only if a native lane is wanted *and* direct LLVM IR (D) is rejected |
| **B** | A custom `bend` dialect kept as the real backend IR, converted to A | ODS dialect + verifiers + conversion + versioning | structural WF checks (§4.6); dialect-level info survives | everything in A, plus a second source of truth next to `backend_ir.bend`; upstream churn (§7.1); a C++ build in a Bend-only toolchain | **Not now.** This is the "become Mojo" option and the cost is the reason to refuse it |
| **C** | stay: BIR → C (segmented runtime ABI) → clang; BIR → JS | nothing | already exists (`c_backend.bend`, `js_backend.bend`); clang already runs the LLVM optimizer over the emitted C | no IR-level verification; no structured-analysis passes | **Keep as the baseline.** Note: `-O2` on the emitted C already gives LLVM's middle-end and all LLVM targets, which is most of what A promises |
| **D** | BIR → LLVM IR text directly (no MLIR) | an LLVM-IR printer | same backends as A, one less layer and one less toolchain | hand-writing LLVM IR text (attributes, ABI, DILocation) is its own maintenance; no verifier benefits | Compare against `RESEARCH_LLVM.md`; on the evidence I have, **C beats D** because clang *is* the LLVM frontend+driver, and D would re-implement a small clang for no target gain |

The redundancy argument, stated plainly `[INFERENCE]`:

- If the goal is **LLVM optimization and target breadth**, the C lane already has it: clang
  compiles the emitted C to LLVM IR. MLIR in the middle adds a toolchain and a type
  discipline, and changes nothing about the runtime ABI that actually limits optimization.
- If the goal is **IR verification and structural analysis** (the `WF`/`BL-1` gap), MLIR is a
  good fit — but then you only need the *front half* (A's emitter + verifier) and never
  LLVM translation. That is experiment M1.
- If the goal is **GPU or WASM**, MLIR is neither necessary (wasm: clang/LLVM already;
  Metal: unavailable) nor sufficient (no scheduler, no Metal).

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
| M-D (affinity) | No pass may duplicate a value whose `Arg.use`/`Parameter.use`/`Field.use`/`Code.captures` entry is `Affine`; ops consuming such values are effectful/non-speculatable, or the value model proves no duplication | `BL-3`, `L4`; MLIR's default rematerialization (§4.5) actively conflicts |
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

**M1 — verifier-only MLIR emission (recommended).**
Emit `func`/`arith`/`cf` (no `llvm`, no `mlir-opt` compilation pipeline, no LLVM translation)
from a *fixed, small* BIR corpus that already has JS/C golden behaviour, and feed it to
`mlir-opt --verify-each`. Acceptance:

1. Every valid corpus program verifies; each corpus program's `Region`/`LeaveRegion` is
   encoded with a documented scheme from §4.1, and a hand-written negative test per scheme
   shows the scheme's own invariant is what fails, not the MLIR core verifier.
2. Hand-built *invalid* BIR programs that are legal Bend data — duplicate code id, duplicate
   region label, `Local` referring to no enclosing `Let`/`Parameter`, capture slot out of
   range, `Direct` arity ≠ captures+parameters, constructor field id not in the layout,
   non-Boolean `Branch.condition` — each produce a **diagnostic** from the emitted module's
   verifier. This is the acceptance criterion that maps directly to `BIR_LAWS.md` §3.7's
   `[O]` column, and it is the only measured benefit I would trust.
3. No change to `backend_ir.bend`, `backend_lower.bend`, either renderer, or any law text.
4. If (2) cannot be achieved without adding information to BIR, that is a **result**: it
   proves the verifier win requires an IR change, which is out of scope, and the hypothesis
   fails cheaply.

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
op), MLIR has no Metal target, and `gpu-lower-to-nvvm-pipeline` needs IR that is already
parallel. Cross-reference `RESEARCH_GPU.md` for what the legacy Metal/CUDA path does.

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
3. **Where would types come from for `arith`?** M2 answers feasibility, not desirability:
   `PrimitiveCall.types` is descriptor-level, and descriptors are canonical *keys* plus
   structure, so a mapping descriptor→MLIR type must be defined (U32→i32, F32→f32,
   Nat→i64+guard, Array→runtime handle, …). Any mapping that is not total is a hole.
4. **What would a `bend` dialect actually hold** that `func`/`cf` cannot? My list is: (i)
   `bend.region_exit`, (ii) `bend.lazy_symbol` with read-effects, (iii) `bend.foreign` with
   declared sources/quantities, (iv) `bend.construct/project/has_tag` with layout,
   (v) descriptor attributes. Items (i)–(iv) are exactly what §4.1/§4.5 show can be
   expressed with standard ops + calls today, at the price of losing the source-level
   meaning. That is the trade: a custom dialect buys *diagnostics*, not codegen.
5. **Debug info.** BIR drops spans. MLIR→LLVM debug info is available, but only if BIR carries
   locations, which would be new IR — out of scope. So debug info cannot be a justification
   for MLIR today.
6. **Reproducibility.** `G1` demands byte-identical stages for one canonical input. Pinning
   MLIR makes output depend on a second compiler version; is that acceptable to the
   reproducibility law, or does it need an amendment? Unresolved and owner-dependent.

---

## 11. What would change this verdict

- **BIR grows an explicit parallel/dispatch node** (a bang) — then MLIR's `gpu` path becomes
  relevant for NVIDIA/AMD, and a device lane would be evaluated on its own terms (§6.1).
- **BIR grows source locations** — then MLIR→LLVM debug info becomes a real argument instead
  of an impossibility (§10.5).
- **The runtime's value representation becomes static** (real closure structs, real
  constructor layouts, refcounts modelled as ownership) — then LLVM/MLIR optimizations start
  to fire and the C-vs-MLIR comparison changes (§4.3).
- **A Bend-side `validate` proves impractical or drifts from the spec** — then M1's
  declarative verification gains a concrete counter-argument (§10.2).
- **A second native target with nontrivial ABI (e.g. a GPU target we must support) has to
  ship from the selfhost compiler** — then the "clang already gives us LLVM" argument (§7)
  weakens for that target, because clang cannot produce device binaries for Metal.

Until one of those happens, the evidence supports **keeping the C/JS lanes as the backend,
keeping BIR as the IR, and treating MLIR as an optional verification harness** (M1) rather
than a target.

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
