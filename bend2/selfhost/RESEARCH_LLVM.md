# Direct Backend IR → LLVM IR: mapping, ABI and target boundaries

**Status:** research note only. No renderer, runtime, dependency, IR, parser,
stack/heap/fuel or benchmark change is implemented or accepted here. The
existing C and JS targets remain source-present BIR renderers; C is the only
source-present native renderer. This note does not promote their presence to an
end-to-end native acceptance. No target cutover follows from this research. No
repository build, test, dependency or smoke run was performed; the only commands
run were read-only source inspection and small local clang target probes.

**Repository baseline:** `f46ad0f6d363753229c52350eaec1474875c6623`
(`work/fir-ir-integrated57ab`), own branch `work/llvm-research`, worktree
`/private/tmp/bend-llvm-research`.

**Sources:** LLVM documentation from `main` fetched 2026-10-24 (no pinned
release claim), plus the repository at the baseline above. Each claim is
tagged **SOURCE** (official document/spec or actual repository code),
**MEASURED** (command run on this Darwin arm64 host on 2026-10-24), or
**INFERENCE** (engineering judgment). Unless a row or sentence is marked
MEASURED or INFERENCE, it is SOURCE. Recommendations and trade-off judgments in
§1 and §12-§14 are INFERENCE. External links are cited per claim; local claims
cite exact files/symbols at the baseline. Companion notes own adjacent scope:
`RESEARCH_WASM_WASI.md` (WASI/toolchain specifics), `RESEARCH_GPU.md` (GPU
runtime/legacy lanes) and `RESEARCH_MLIR.md` (dialect comparison). This note owns
the LLVM baseline only.

## 1. Verdict

The **recommended initial design** is a native x86-64/AArch64 second renderer
that reuses the existing runtime and its physical layout. That is the
lowest-risk path, not a feasibility boundary: a standalone or portable LLVM
runtime (design B below) is possible, but it is a new runtime project. Direct
LLVM is not a drop-in replacement for the C target:

* The hard parts of the C target are not C syntax. They are physical layout
  (`c_backend_layout.bend`), ownership/refcount destinations
  (`c_backend_physical.bend`), sharing/hotness (`c_backend_sharing.bend`), the
  closure/stage ABI, exports/foreigns and the runtime. LLVM changes the text
  target and exposes SSA/UB/inline IR, but every one of those facts still has
  to be reproduced.
* The C runtime is not a stable library ABI. Its segment entry signature,
  register count, result width and function table are generated per program
  (`WL_SIG`, `WL_RESW`, `FID_T`, `preserve_none`, `musttail`). Reusing it from
  LLVM requires either an exact generated ABI or a hand-written C shim; a
  standalone LLVM runtime is a new runtime project, not a renderer.
* Textual LLVM IR is explicitly not backwards compatible. The C API does not
  *name* `preserve_nonecc`/`tailcc` in its enum, but
  `LLVMSetFunctionCallConv(Fn, unsigned CC)` accepts the numeric conventions
  (`Tail = 18`, `PreserveNone = 21` in `llvm/IR/CallingConv.h`); a library route
  is therefore possible with a pinned LLVM version or a small shim, not
  categorically excluded. A textual emitter pinned to a tested toolchain is the
  lower-risk integration; libLLVM is a larger, version-coupled choice.
* In the current runtime's form, wasm and GPU are separate runtime/toolchain
  projects: wasm needs a runtime port plus a tail-call strategy, and GPU direct
  LLVM means NVPTX/AMDGPU only (no upstream Metal target). Neither shares the
  host runtime with native without that work.

**Recommendation:** keep C as the shipping path. If LLVM is pursued, run one
native runtime-compatible spike (uniform `i64` ABI, CLay layout, textual `.ll`,
pinned clang) before any broader claim. For a multi-target IR investment, MLIR
is the better vehicle; direct LLVM is the smaller native-only step. These are
engineering trade-offs, not measured comparative performance: no LLVM-vs-C
runtime benchmark was run, and clang already runs the LLVM middle-end on the
current C output.

## 2. What "direct LLVM" would replace, and what it would not

Today the CLI selects a C compiler and builds a C translation unit:

* `bend2/main.ts:398-460` finds `clang` (minimum 14 for CPU, 19/Apple clang 17
  for GPU `#embed`) and invokes it with `-std=c11 -O3`; GPU adds
  `-DBEND_METAL=1` or `-DBEND_CUDA=1` plus `-lcuda -lnvrtc` (**SOURCE**).
* The self-host C target is a BIR renderer: `c_backend.bend:17-40` documents the
  runtime ABI and the calling convention; `c_backend.bend:3173` is `emit`.
  Its **presence is not execution proof**; no new full native13/FP/C acceptance
  is claimed here.
* There is already an LLVM *build* pipeline, but it is C→LLVM, not BIR→LLVM:
  `evals/native_compiler_llvm.ts:73-100` pins Apple clang 21, requires `opt` and
  `llvm-split` 21, emits `.bc` with `clang -emit-llvm -c`, runs
  `mem2reg,always-inline`, `llvm-split -j4`, and compiles four partitions. This
  proves the repo already accepts LLVM tooling/version pinning; it does not
  prove a BIR→LLVM renderer (**SOURCE**; measured timings in
  `checkpoints/SELFHOST_HANDOFF.md:178-184` are existing receipts, not
  reproduced here).

In design A, a direct LLVM target would replace the **C text renderer only**.
It would still need the BIR → physical-layout facts, the runtime heap/refcount/
IO machine, and the same public entry points. Design B would also replace the
runtime, which is a different project with its own feasibility and acceptance
questions.

## 3. BIR surface that must be mapped

`bend2/selfhost/backend_ir.bend` is the contract. The relevant shapes at the
baseline are:

| BIR construct | Fields / meaning | Notes |
|---|---|---|
| `Program` (233) | `codes`, `declarations`, `constructors`, `families`, `type_functions`, `ending` | Closed program; no arena handles (**SOURCE**). |
| `Code` (203) | `id`, `captures: List<Use>`, `parameters: List<Parameter>`, `body: Block` | Capture parameters precede live parameters at private entries (206). |
| `Block` (194) | `Return`, `Let{id,op,next}`, `Branch{condition,yes,no}`, `Region{label,body,next}`, `LeaveRegion{label}`, `TailDirect{code,args}`, `TailApply{fn,arg}`, `Failure{message}` | Structured ANF; tail calls only as terminators (192). |
| `Op` (178) | `Copy`, `PrimitiveCall`, `Closure`, `Direct`, `Apply`, `LoadSymbol`, `Construct`, `Project`, `HasTag` | Closed catalog; no source aliases. |
| `Atom` (11-23) | `Local`, `Capture`, `Symbol`, `Word`, `Natural`, `FloatBits`, `Text`, `Boolean`, `Null`, `Undefined` | Atoms contain no hidden computation. |
| `Declaration` (209) | `FunctionDeclaration`, `LazyDeclaration`, `NativeDeclaration`, `ForeignDeclaration` | Foreign retains all declared source alternatives and its span. |
| `Ending` (230) | `Executable{main_type}`, `Library{exports}` | Public ABI differs per ending. |
| `Export` (228) | `key`, `entry: Maybe<Entry>`, `parameter_types` | Export may name a code entry or a declaration. |
| `Entry` (226) | `code`, `arity` | Arity is semantic, not the C struct layout. |

Key semantic facts established by the C and JS renderers:

* **Atoms are values, symbols are callables.** A `Symbol` atom is a first-class
  closure, not a memory load. Nullary/lazy reads are `LoadSymbol` control
  operations so a mutable factory is reevaluated on each read
  (`c_backend.bend:1199-1243`; `js_backend.bend:950-985`). Implementers must not
  lower a symbol to a cached function pointer or a `load` of a global.
* **Calls are staged.** A `Closure{code, captures, parameters}` has
  `captured + remaining == code arity`; the runtime keeps a one-argument
  closure (`term_clo(fid, captures)`) and stages k-argument partials as their
  own entries (`c_backend.bend:2480-2525`). Over-application is sequential
  after saturation (`backend_lower.bend:951-983`; `c_backend.bend:2347-2370`).
* **Region is lexical forward control.** `LeaveRegion` exits one case/region;
  it is not a general graph jump. The C backend lifts `next` to a separate
  segment because its execution model is CPS; the JS backend lowers the same
  construct to JavaScript labelled blocks (`js_backend.bend:643-654`;
  `c_backend.bend:2274-2315`). A direct LLVM CFG is therefore legal inside one
  `Code` body, provided values flowing to the join block are handled.
* **`Copy` is currently vacuous.** `backend_ir.bend:179` declares it and both
  renderers treat it as identity (`c_backend.bend:1251`,
  `js_backend.bend:574`), but `backend_lower.bend` does not construct
  `BIR.Copy` anywhere. It is not a refcount `keep`; ownership is expressed by
  `Use`/`Field.use` and by construct/array operations. An LLVM backend must
  either implement it as identity for BIR completeness or the IR contract
  should delete it. Do not invent sharing semantics for it (**SOURCE** +
  **INFERENCE**).
* **Ownership is in the physical layer.** A `Many` operand becomes
  `term_keep(e,w,1)`; an `Affine` stored field becomes `rfc_seal(e,w)`; a read
  of a sealed node uses `ctr_take`; arrays take elements through Fill/Unfill
  (`c_backend_physical.bend:13-17,495-560,671-780`). These calls/atomics are
  observable; LLVM must not optimize them as pure.

## 4. Mapping BIR to LLVM IR

### 4.1 Two designs, one recommendation

| Design | Values / calls | Runtime | Assessment |
|---|---|---|---|
| **A. Runtime-compatible LLVM** | uniform `i64` `Term` words; closures carry runtime FID/captures; calls use the runtime's uniform entry signature | reuse `c_runtime.c`/C shim; keep CLay layout and Sharing facts | Lowest semantic risk; native-only first; tightly coupled to generated runtime tables. **Recommended spike.** |
| **B. Native typed SSA** | `i32`/`i64`/`float`/`ptr` per BIR type; own closure objects; native calls/tail calls | new allocator/refcount/IO/task runtime | Better optimization/debug surface; largest option, but not impossible. It needs a new runtime and a new ABI for exports/foreigns; justified only if portability or IR-level control is the goal. |
| **C. Hybrid** | typed scalars inside functions, `i64` Term at every callable/foreign/capture boundary | reuse runtime | Matches the C target's actual contract ("one Term per value at every callable, closure, foreign and capture boundary", `c_backend_layout.bend:29-32`); more conversion code. |

The C target's own boundary rule makes **A/C** the lowest-risk options. B is a
separate compiler/runtime project, not a logical impossibility; this note does
not measure whether its extra control pays for its runtime work.

### 4.2 Values and operations

| BIR | LLVM (runtime-compatible) | Obstacle / note |
|---|---|---|
| `Local{id}`, `Capture{slot}` | SSA value or entry-block `alloca`; capture is the prefix of the private entry parameters | Captures are not a free `env` pointer in the C runtime; they are leading words. |
| `Symbol{id,key}` | closure Term (`term_clo(fid,0)` or a stage entry) | Nullary/parameterised symbols are not loadable atoms; fail closed. |
| `Word{u32}` | `i64` zero-extended; `trunc` to `i32` at primitive use | U32 arithmetic wraps. |
| `Natural{nat}` | `i64`, checked against `NAT_IMM`/overflow | C traps; LLVM has no implicit trap. |
| `FloatBits{bits}` | `i32` bit pattern or `float` via `bitcast`; boundary is low 32 bits of a Term | Preserve NaN payload and signed zero. |
| `Text{value}` | global bytes + call to the runtime string builder (`bend_text`) | Allocation/ownership; do not use `ptr` to a temporary stack buffer across a tail call. |
| `Boolean{value}` | tagged True/False Term in runtime ABI (C uses `term_pak`), or `i1` only if every boundary agrees | Branch decode must match the runtime. |
| `Null{}`, `Undefined{}` | `i64 0` in C ABI | JS uses `null`/`undefined`; target-specific. |
| `Copy{value}` | identity | Currently unused by lowering; see above. |
| `PrimitiveCall` | inline LLVM ops or calls to the existing helper | See §5 for every edge case. |
| `Closure` | heap allocate capture node; store captures; `term_clo(stage_fid,node)` | Captures are evaluated strictly before the closure; stage selection depends on captured+remaining. |
| `Direct` | call the entry with saturated args; if under-applied, build a stage closure | Non-tail vs tail is explicit in BIR. |
| `Apply` | call the runtime `FID_CLO_APPLY` equivalent (or an indirect uniform entry) | Dynamic dispatch must preserve unary public ABI. |
| `LoadSymbol` | call the nullary/lazy/foreign entry; never memoize | Mutable factory must re-evaluate. |
| `Construct` | CLay node layout stores, then `term_ctr`/`term_pak` | Packed vs node, tags, field order, Many/Affine sealing. |
| `Project` | `ctr_take` for sealed nodes; load field at CLay offset | Erased fields have no storage. |
| `HasTag` | compare canonical CID / `term_aux` | Must use the program's CID, not a source tag string. |
| `Return` | `ret i64` | One result word per the entry's result width. |
| `Branch` | `br i1` on the decoded condition | Do not branch directly on an arbitrary Term. |
| `Region` / `LeaveRegion` | basic blocks + phi/`alloca` join; or a lifted continuation if CPS is chosen | `next` is only reachable via `LeaveRegion`; values defined in `body` and read in `next` need explicit flow. |
| `TailDirect` | `musttail call` (uniform signature) | Must be a true tail position; signature/convention must match. |
| `TailApply` | `musttail` indirect call through the closure's uniform entry | Wasm needs `+tail-call`; otherwise a trampoline. |
| `Failure` | call a defined runtime fail-stop (`err_post`/`err_fail`) and return; do not emit bare `unreachable` | `unreachable` has no defined semantics (**SOURCE** LangRef). |

### 4.3 Shape sketch (illustrative only)

The following is not an accepted ABI or generated output; it shows the two
run-time-sensitive choices an implementer must make explicit: a guarded
division (never a bare `udiv` on a possibly-zero divisor) and a true tail call.

```llvm
; all entries use one uniform signature; %cap and %p are Term words.
define private tailcc i64 @code_7(ptr %env, i64 %cap0, i64 %p0, i64 %p1) {
entry:
  %zero = icmp eq i64 %p1, 0
  br i1 %zero, label %div_zero, label %div
div:
  %q = udiv i64 %p0, %p1           ; reached only when %p1 != 0
  br label %join
div_zero:
  br label %join
join:
  %r0 = phi i64 [ %q, %div ], [ 0, %div_zero ]
  %r = musttail call tailcc i64 @code_9(ptr %env, i64 %r0)
  ret i64 %r
}
```

`tailcc` and one uniform prototype make `musttail`/indirect dispatch tractable;
`preserve_nonecc` is an alternative only if the runtime build uses the same
convention. The exact result width, `Env` passing, and signature are decisions
for task 1 in §13, not implied by this sketch.

### 4.4 Code, declarations and endings

* `Code` → one private LLVM function per code **and one per partial-application
  stage**, with captures first. The public unary wrapper, saturated export fast
  path and non-memoizing nullary factory are observable contract
  (`checkpoints/SELFHOST_IR_ARCHITECTURE.md:176-200`). A raw function pointer is
  not a Bend value unless the target's closure representation says so.
* `FunctionDeclaration` → entry for its code; `LazyDeclaration` → a nullary
  thunk entry that is called on every read; `NativeDeclaration` → helper/primitive;
  `ForeignDeclaration` → the target's foreign ABI (see §6).
* `Ending.Executable` → main entry plus the runtime's IO/show loop. In C,
  `main` is a segment that jumps to the root (`c_backend.bend:2626-2650`), and
  `c_runtime.c:2720-2860` owns argv, `--threads`, `--gpu`, IO parking and
  `show_val`. An LLVM target reusing the runtime must call that loop, not invent
  a second `main`.
* `Ending.Library` → the existing C export ABI: `bend_export_count/name/arity`,
  `bend_export_call(i,args,n)` with `Term` arguments and modes exact/curried/
  lazy (`c_backend.bend:596-637`). This is the consumer ABI already exercised by
  frozen consumers; a new target either preserves it or provides an adapter.
* `ConstructorLayout`, `Family`, `TypeFunction`, `Descriptor` are metadata, not
  executable IR. The renderer needs them for layout and type/show tables.
  CLay canonicalizes descriptors; do not duplicate descriptor normalization in
  an LLVM renderer (`c_backend_layout.bend:52-70`).

## 5. Correctness matrix: LLVM UB/poison vs Bend semantics

This is the concrete target-specific instance of law **B1** in
`checkpoints/SELFHOST_IR_ARCHITECTURE.md:226`. Bend's C runtime defines behavior
where LLVM would return poison or invoke undefined behavior. The renderer must
lower the guard explicitly; it must not rely on C's or LLVM's defaults.

| Source operation | LLVM rule (SOURCE LangRef) | Bend/C behavior (`comp.ts`, `c_runtime.c`) | Required lowering |
|---|---|---|---|
| `U32` division by zero | `udiv`/`urem` by zero is undefined behavior | `U32_QUO` guarded: div0 → 0 | branch/phi or call a helper; a `select` placed after an executed `udiv` is still UB |
| `U32` remainder by zero | same | mod0 → dividend | branch/phi or helper; same reason |
| `U32` shifts | shift count ≥ bit width → poison | `shln/shrn` return 0 when `n >= 32` | branch/phi or call a helper; a `select` can mask poison but is easy to get wrong |
| `U32` add/sub/mul | `nsw`/`nuw` overflow → poison | C casts to `u32`, wraps | no `nsw`/`nuw`; `add`/`sub`/`mul` on `i32` then zero-extend |
| `U32` inc | same | wraps | plain add; no flags |
| `Nat` add/mul/double | LLVM integer ops have no traps | `nat_chk` posts `ERR_NATS` above `2^48-1`; `nat_mul` guards overflow | explicit check + runtime error/fail-stop |
| `Nat` sub | no trap | 0 when `a < b` (`PrimNatSub`) | clamp with compare/select; do not trap |
| `F32` add/sub/mul/div | IEEE unless fast-math flags; flags can introduce poison (`nnan`, `ninf`) | C float, `#pragma clang fp contract(off)` | no fast-math flags; preserve IEEE semantics |
| `F32` to `U32` | `fptoui` out of range/NaN → poison | `f32_to_u32` returns 0 outside `[0,2^32)` | explicit compare + branch/`select` (or call the helper), never bare `fptoui` |
| `F32` comparisons | `fcmp` has ordered/unordered predicates | C `==`,`<`,`<=`,`>` are ordered; `!=` is unordered (NaN true) | `oeq/olt/ole/ogt/oge` for the first group, `une` for `!=` |
| `F32` remainder | `frem` defined; NaN behavior follows IEEE | `fmodf` | verify NaN/sign parity; otherwise call `fmodf` |
| `F32` bits | `bitcast` between `float` and `i32` is defined | union punning in C | `bitcast`; preserve low 32 bits |
| `Bool` branch | branch condition must be a well-defined `i1`; poison/undef condition is UB | decoded from tagged Term | decode, then `icmp`; do not branch on raw Term |
| `Failure` | `unreachable` has no defined semantics | `err_post(ERR_TAGS)` then return 0 | call a defined fail-stop; optionally `unreachable` only after a proven `noreturn` call |

Other legality points:

* **No `inbounds` without proof.** BIR offsets/heap terms can be arbitrary
  indices into a runtime heap. Use non-`inbounds` GEP or integer address
  arithmetic; `inbounds` overflow yields poison.
* **Do not use `sret`/`byval`/aggregate ABI by accident.** The runtime boundary
  is words; uniform `i64` arguments avoid target ABI differences. If a struct
  `Env{mem,alc}` is passed by value, its LLVM lowering must match the C runtime's
  ABI on each target; passing `ptr` to `Env` is simpler but changes the C ABI.
* **No `llvm.assume` for refcounts or liveness.** The optimizer may exploit an
  assumption that becomes false under sharing; refcount positivity is not a
  proven program invariant.
* **`noalias`/TBAA are a conservative baseline, not an intrinsic limit.** Proven
  fresh allocations, disjoint constructor fields or immutable regions may
  justify scoped alias metadata later. The note starts without them because the
  current runtime heap is deliberately viewed through several representations;
  enabling them requires proof, not optimism.

## 6. Runtime and ABI obstacles

### 6.1 The runtime is a whole machine, not a helper library

`bend2/selfhost/c_runtime.c` (generated from `bend2/comp.ts` `runtime_c`) is:

* a packed `u64 Term` encoding: tag bits 56-62, aux 40-55, loc 0-39, RFC bit
  63 (`c_runtime.c:173-230`);
* a tagged heap with hot/cold class banks, generations, a bump corpus and
  refcount redirect cells (`c_runtime.c:601-700`);
* `term_keep`/`rfc_seal`/`ctr_take`/`term_drop` ownership
  (`c_runtime.c:692-860`);
* an explicit continuation/task stack and `work_loop`/`WL_*` segment machinery
  (`c_runtime.c:1127-1275`);
* pthreads, `mmap`, signal handlers, `sched_getaffinity`, POSIX file IO, a
  thread pool, and a GPU device path (`c_runtime.c:34,1520-1660,2720-2860`);
* `main`/`io_loop`/`corpus_eval` with argv, `--threads`, `--gpu`, IO effects
  and `show_val`.

An LLVM target that reimplements closures/ADTs without this runtime must also
reimplement allocator/refcount/task/IO/foreign/export behavior. That is a new
runtime project and is outside a renderer change.

### 6.2 The segment ABI is generated, not stable

`comp.ts:3209-3221` generates:

```c
#define WL_RESW <max result words>
#define WL_SIG  Env e, DEV Term* sp, u32 seq, u32 rn, Term r0, ..., Term rN
#define WL_ALL  e, sp, seq, rn, r0, ..., rN
```

`WL_FN` is `preserve_none` and noinline; `WL_JMP`/`WL_DYN` are `musttail`
(`c_runtime.c:130-170`). The table `wl_tab[]` is built from `WL_TABLE`; the
number of registers/locals, `FID_T`, `CID_T`, `BANGs` and `SHOW_DESC` are
program-specific. The C backend fills textual `// Tables`, `// Spins`,
`// Segments` and `// Requests` slots (`c_backend.bend:3074-3090`).

Consequences for LLVM:

1. You cannot `declare` one stable `bend_apply` and tail-call arbitrary BIR
   code. The callee prototype must be the generated one, or all entries must
   use one self-consistent uniform prototype.
2. `preserve_none` is only enabled when the C runtime is compiled with a clang
   that has the attribute and `__OPTIMIZE__` (`c_runtime.c:57-70,101-110`). A
   musttail call from IR using `preserve_nonecc` into a runtime compiled
   without it is an ABI mismatch. Coordinate the runtime build and the IR.
3. `musttail` requires matching calling conventions and, for non-tailcc,
   matching prototypes and ABI attributes (LangRef call section). Use one
   uniform prototype or `tailcc` deliberately; do not bitcast ad hoc.
4. The C backend's CPS segments are not required by BIR. A direct-style target
   can use ordinary calls for `Let Direct` and `musttail` for `TailDirect`, but
   it then changes the stack-growth behavior of non-tail recursion. Existing
   K1-K5 obligations describe the compiler's CPS/resumer; they do not
   automatically transfer to a direct-style target. Document the chosen stack
   policy and test it.

A pragmatic native spike therefore needs a small generated C shim that
instantiates the runtime template and exposes the table, while the LLVM module
implements the segments with the exact `WL_SIG`. This keeps the runtime's
refcount/IO semantics and confines ABI coupling to one generated file. It is
still a target-specific instance of L1-L6/B1-B2, not a new general runtime.

### 6.3 Refcounts and LLVM optimization

`term_keep`, `rfc_seal`, `ctr_take` and `term_drop` read/write heap state and
use atomics (`c_runtime.c:342-454`). They are not pure:

* Do not mark helper declarations `readnone`, `readonly`, `writeonly` or
  `willreturn`.
* Do not let CSE/GVN merge two keeps, or DCE a keep/drop, by giving the calls
  no memory effects. A call with unknown memory effects is a barrier; that is
  the conservative and correct default.
* Do not sink a keep past a branch that can drop the value.
* The redirect cell is updated by 32-bit atomic RMW while a host path reads a
  64-bit atomic (`c_runtime.c:763-775`). LLVM's atomic rules discuss
  *perfectly overlapping* atomic accesses; a 64-bit load and a 32-bit RMW are
  not perfectly overlapping. Do not naively model this as `load atomic i64` +
  `atomicrmw i32` in IR and assume the C runtime's hardware argument. Keeping
  the access behind an opaque call prevents the generated module from making
  new optimizer assumptions, but it does **not** by itself establish that the
  C runtime's mixed-width access is well-defined or race-free. The alignment,
  stable-loc invariant and target memory model must be verified separately.
* Match orderings: `relaxed` for `a32_add/store`, `release`/`acquire` for
  lifetime transitions, `acq_rel` CAS (`c_runtime.c:342-454`). Atomics are not
  removable; `volatile` is not a substitute for the runtime's ordering.
* Avoid `!tbaa`/`noalias` on the homogeneous heap. The same `u64` storage is
  viewed as words, node fields, tags and refcount cells; a type-based alias
  claim would be unsound.
* `Failure`/runtime errors are observable behavior, not `unreachable`
  opportunities.

### 6.4 Foreign and export boundary

`ForeignDeclaration` keeps the declared import alternatives, arity, parameter
types, result descriptor and quantities (`backend_ir.bend:215`). Selection is
per target, not inferred: the C target takes the first `.c` source
(`c_emit_core.bend:33-40`); the JS target takes the first `.js` source
(`js_backend.bend:26-32`). There is **no `.ll` alternative today**.

The C foreign ABI is generated by `comp.ts` as `name(Env e, Term* out, ...)`
returning a status and writing result words; the JS path passes a continuation
as the last argument. These are already two different foreign contracts. An
LLVM target must choose explicitly:

1. **Reuse `.c` foreigns.** Compile the declared `.c` sources with clang and
   link them; the LLVM module calls the existing C foreign ABI. This preserves
   existing foreign behavior and quantities, but requires the C runtime's
   `Env`/`Term` types and cannot be used by a standalone runtime without
   wrappers.
2. **Add a `.ll` alternative.** This is a BIR/source-selection change, not a
   renderer detail. It needs a documented LLVM foreign ABI (argument/result
   words, ownership, continuation) and must preserve the same evaluation order
   and quantity rules.
3. **Generate shims.** Keep `.c` foreigns and synthesize C/LLVM adapters to the
   target's ABI. This is the least invasive for a spike, but every foreign call
   crosses a generated boundary and must be included in the ABI/ownership tests.

The same applies to the library ABI: `bend_export_*` exposes `Term` arguments
and modes exact/curried/lazy (`c_backend.bend:596-637`). A direct LLVM target
that does not reproduce it needs an adapter and a new consumer contract; the
existing frozen consumers must not be silently redefined.

## 7. Textual LLVM IR vs C API integration

| Aspect | Textual `.ll` (recommended spike) | LLVM C API / libLLVM |
|---|---|---|
| Fit to selfhost | Renderer returns a `String`; BIR is pure; no FFI | Needs FFI/linking, ownership of contexts/modules, error handling |
| ABI/attributes | Full syntax: `preserve_nonecc`, `tailcc`, `musttail`, address spaces, metadata | C API enum names `PreserveMost`/`PreserveAll` but not `PreserveNone`/`Tail`; `LLVMSetFunctionCallConv(Fn, unsigned CC)` can pass numeric `Tail = 18`/`PreserveNone = 21`, and `LLVMSetTailCallKind` handles musttail (**SOURCE** `llvm-c/Core.h`, `llvm/IR/CallingConv.h`). Version-coupled, shim-able. |
| Toolchain | `clang -x ir`/`llc`/`opt -passes=verify`; already external | `libLLVM` shared/static library, version-coupled; larger artifact |
| Versioning | Textual format "not backwards compatible"; pin and regenerate | C API is "best effort" stable, less stable for debug-info/instruction construction (**SOURCE** DeveloperPolicy) |
| Determinism | Emitter controls bytes; compare `.ll` for G1 | Module printing after passes/version changes is not a byte-stability contract |
| Debug info | Full metadata syntax | C API debug-info builders exist but are explicit and version-sensitive |
| JIT | Not needed for CLI | ORC/LLJIT C API is available (`llvm-c/LLJIT.h`) but not needed for shipping a CLI |

The C API path is only attractive if the compiler needs in-process JIT or
programmatic module construction. For a compiler that already emits text (C or
JS), text is the natural boundary. The C API's missing *named* enum values are
not a blocker: numeric `LLVMSetFunctionCallConv` accepts the conventions, but
the numeric IDs are LLVM-version-coupled, so a library route needs a pin or a
small compatibility shim. Text remains simpler than that.

## 8. Target matrix (not one runtime)

| Target | LLVM backend status (SOURCE) | Runtime status | Main obstacles |
|---|---|---|---|
| Native x86-64/AArch64 | In-tree; `preserve_nonecc` is documented for x86-64/AArch64/LoongArch; `musttail`/`tailcc` available | Reuse C runtime + shim (INFERENCE) | Generated segment ABI, C shim, refcount atomics, stack policy; a local tiny noinline musttail test compiled to `b _callee` on arm64 (MEASURED, not a Bend test) |
| wasm32/wasm64 | Both targets are registered in the host clang (MEASURED); upstream wasm tail-call test uses `-mattr=+tail-call`; clang's wasm `musttail` test requires `-target-feature +tail-call`; host Apple clang warns "unknown attribute 'musttail'" without it (MEASURED) | The current C runtime cannot be reused as-is without a port: POSIX/pthreads/mmap/signals/stdio are not wasm-wasi | Runtime port; indirect-call table; tail call feature or a BIR-level trampoline; memory/IO; wasi specifics are owned by `RESEARCH_WASM_WASI.md` |
| NVPTX (CUDA) | In-tree; `nvptx64-nvidia-cuda`; address spaces 0-7; `libdevice` for math; CUDA Driver API | Host runtime cannot run on device; device runtime is a separate C/PTX program (INFERENCE); see `RESEARCH_GPU.md` | Address spaces, kernel launch, no host pthreads/mmap/stdio; no evidence here that `musttail`/`preserve_none` apply; existing C route uses NVRTC, not LLVM IR |
| AMDGPU (ROCm) | In-tree `amdgpu`/`amdgcn`, HSA triples; documented unsupported constructs (e.g., sub-natural-alignment atomics); no generic address space on some subarchs | Same split | HSA runtime, address spaces, calling conventions, separate device runtime; not currently a Bend target in `comp.ts` |
| Metal | **No in-tree LLVM target**; `clang -print-targets` on this host lists no Metal target (MEASURED); Apple's Metal compiler/AIR is outside upstream LLVM | Existing C runtime compiled with Metal (`BEND_METAL`) | Direct LLVM cannot target Metal; keep the C/Metal path |
| SPIR-V | No SPIR-V target appears in the host clang target list (MEASURED); MLIR has a SPIR-V dialect | Separate | MLIR/SPIR-V, not direct LLVM; see MLIR note |

**MEASURED host facts (2026-10-24, Darwin arm64):**

* `clang --version` is Apple clang 21.0.0 (clang-2100.3.34.2), target
  `arm64-apple-darwin25.6.0`.
* `clang -print-targets` lists `aarch64`, `wasm32`, `wasm64`, `x86-64` (and
  other native targets), with no `metal` or `spirv` target.
* A noinline `musttail` caller compiled with
  `clang --target=arm64-apple-darwin -O2 -S` emitted `b _callee`.
* The same source with `--target=wasm32-unknown-unknown` emitted
  `warning: unknown attribute 'musttail' ignored` (no `+tail-call`).
* `which wasm-ld` found no `wasm-ld` on `PATH`.

Important consequence: **native, wasm and GPU do not share one runtime**. No
GPU lane is executed or accepted in this note; `RESEARCH_GPU.md` owns that
evidence. Native
can reuse the C runtime; wasm needs a portable runtime; GPU needs a device
runtime. "LLVM supports the target" is not evidence that Bend's runtime can run
there.

## 9. Debug info and source locations

BIR currently carries **no source span on `Code`, `Block`, `Op` or `Atom`**.
The only span in the backend IR is `ForeignDeclaration.span`
(`backend_ir.bend:215`). Therefore:

* Source-line debug info is **blocked on the current BIR contract**, not
  intrinsically impossible. An LLVM target can emit name-based/subprogram-level
  info and coarse declaration info now; it cannot map BIR operations to Bend
  source lines without inventing locations. A future BIR `SourceLoc` side table
  or span extension would unblock line mapping.
* Emitting `!dbg` with line 0 or a synthetic line is worse than no debug info:
  it misleads debuggers and can affect optimization decisions.
* LLVM debug info is explicitly optimized and dropped in some IR upgrades
  (**SOURCE** `SourceLevelDebugging.md`, DeveloperPolicy). It must not be part
  of G1 byte-equality; a deterministic producer string and no timestamps are
  required if it is ever added. This is a current-contract limitation, not a
  claim that LLVM cannot represent the eventual spans.
* If debug info is a goal, the prerequisite is a BIR span extension (Code/op/
  block or a side table), plus a rule that spans do not change IDs/serialization.
  This note does not add one.

The C target today has the same limitation; LLVM does not create it. The MLIR
note reaches the same current-source-span conclusion.

## 10. Toolchain, licensing and shipping

* **License:** LLVM is Apache-2.0 **WITH LLVM Exceptions**
  (`llvm/LICENSE.TXT:1-2`). The exception permits redistributing embedded
  object-form portions without Apache §§4(a)/(b)/(d); ordinary Apache notice
  obligations still apply to distributed toolchain bits. Generated `.ll` is
  Bend's output, not a copy of LLVM source. Bundling `libLLVM`/clang binaries is
  a distribution and size decision; linking the existing external clang keeps
  today's model.
* **Version pinning:** textual IR is not backwards compatible; LLVM supports
  loading bitcode since 3.0 but makes no textual-format promise
  (`llvm/DeveloperPolicy.md`, IR Backwards Compatibility). The repo already
  pins Apple clang 21/LLVM 21 for its `llvm-split` C build
  (`evals/native_compiler_llvm.ts:73-100`). A direct emitter must pin a
  toolchain and test generated `.ll` with it; `preserve_nonecc` needs a
  sufficiently recent clang (the runtime comment names clang 19+), and wasm
  tail calls need the feature enabled.
* **Shipping native:** `clang` is already required and version-checked
  (`main.ts:398-460`). Textual IR adds `clang -x ir` or `llc`, no new native
  linker; `opt -passes=verify` is a natural gate.
* **Shipping wasm:** the host has no `wasm-ld` (MEASURED); a wasm lane needs
  wasi-sdk/LLVM's wasm linker and a portable runtime. This is a separate
  toolchain dependency, not covered by the native clang check.
* **Shipping GPU:** CUDA requires `nvcc`/NVRTC and the CUDA driver; Metal
  requires Apple's toolchain. LLVM's NVPTX/AMDGPU backends do not remove those
  runtime/driver requirements. No performance claim is made.

## 11. Laws: existing obligations and target-specific instances

The authoritative existing laws are `checkpoints/SELFHOST_IR_ARCHITECTURE.md`
§4 (F1-F3, L1-L7, B1-B2, G1-G2, K1-K5). They are obligations, not proven
theorems. Direct LLVM needs target-specific instances:

| Existing law | LLVM-specific instance |
|---|---|
| F1 publication | BIR input is already arena-free; LLVM must not retain handles or mutate the BIR program while rendering. |
| F2 occurrences | Descriptor/native authority is resolved before rendering; LLVM must not re-infer a native constructor/type from a source name. |
| F3 affine owner | The renderer owns no CheckedProgram; native handoff must not copy/drop the affine owner. |
| L1 erased | Erased parameters/fields have no LLVM slot; do not leave a gap or shift indices. |
| L2 ANF/strict Let | Preserve evaluation order of callee/args/fields and effects; helper calls are barriers. |
| L3 application | Direct/stage/over-application must match C/JS, including capture of already-evaluated args and zero-live arity. |
| L4 closure | Captures precede params; each live capture stored once; `Many`/`Affine` keep/seal exactly once. |
| L5 layout | One CLay-consistent node/array/descriptor layout for Construct/Project/HasTag; native vs boxed markers authoritative. |
| L6 branch/join/tail | Region/LeaveRegion joins without copying continuations per path; `TailDirect`/`TailApply` must not grow the stack. |
| L7 descriptors | Show/type/IO descriptor tables preserve erased/dependent slots and native authority. |
| B1 primitives | §5 matrix: all defined C/JS edge cases, no reachable LLVM poison. |
| B2 public ABI | Exports remain unary/curried/zero-arity as declared; foreign callbacks/order; nullary factories not memoized. |
| G1 determinism | Byte-stable `.ll` for a canonical BIR input; no paths/timestamps; compare emitted text, not optimized objects. |
| G2 admission | No exclusion of bodies/exports and no weakening of native checks to make LLVM pass. |
| K1-K5 | Apply only if the target keeps the CPS/resumer runtime. A direct-style target must state its own stack/fuel contract; it cannot inherit K claims. |

Proposed extra obligations (target-specific, not yet checked in):

* **T1 entry ABI:** every generated function's signature/convention/arity
  matches the runtime's generated tables and tail-call rules.
* **T2 poison-free primitives:** for every B1 input class, the emitted IR's
  result is defined (no poison/UB) and matches C/JS.
* **T3 ownership preservation:** refcount/sharing calls occur exactly once,
  in order, and are not removed/duplicated/hoisted by LLVM.
* **T4 tail/resource:** `TailDirect`/`TailApply` are guaranteed tail calls, or
  a documented trampoline is used; non-tail recursion limits are explicit.
* **T5 foreign/export parity:** `.c`/`.js` foreign behavior, IO request order,
  export arity/modes and nullary rereads match.
* **T6 runtime split:** native/wasm/GPU each name their runtime and toolchain;
  no target imports host-only facilities.
* **T7 reproducibility/debug:** emitted text is deterministic; debug locations
  only where BIR has spans.
* **T8 failure:** `Failure` is a defined runtime fail-stop, never bare
  `unreachable`.

## 12. Direct LLVM vs C vs MLIR: maintainability

| Criterion | C (current) | Direct LLVM | MLIR |
|---|---|---|---|
| Renderer complexity | ~8.9k lines of BIR→C emitter (`c_backend` + layout + physical + sharing) + 2.9k runtime; physical layout/sharing already solved | Reuses CLay/Sharing facts if runtime-compatible; adds LLVM type/CFG/attribute emission; hard parts remain | Adds dialect definitions/lowerings/passes; highest upfront, best reuse for multi-level optimization |
| ABI/UB handling | C compiler implements the abstract machine; emitter still must guard div0/shifts/floats | Emitter must explicitly encode guards, poison, poison-free atomics, custom conventions | Same as LLVM at the LLVM dialect, plus dialect-level invariants |
| Debug info | Limited by BIR spans | Same limitation; richer metadata if spans exist | Dedicated debuginfo dialect is possible (as in Mojo), but still needs source spans |
| Target reach | Host C, Metal/CUDA source, wasm via C toolchain (runtime permitting) | Native x86-64/AArch64, wasm32/64, NVPTX/AMDGPU; no Metal | LLVM + GPU/SPIR-V dialects; broadest if invested |
| Determinism | C text deterministic; object depends on clang | `.ll` deterministic if emitter is; optimized object not | Depends on pass pipeline/version |
| Dependency | external clang (already required) | external clang/llc/opt, or libLLVM | MLIR libraries/tools, larger |
| Fit to current BIR | Direct: BIR is already ANF and target-neutral | Direct: SSA from Let is natural; Region joins need flow | Needs a BIR/MLIR mapping; no BIR dialect today |
| Recommendation | Keep as shipping/default | Native-only spike, second renderer, no cutover | Investigate if multi-target/GPU is the goal; compare in `RESEARCH_MLIR.md` |

The C target's size is dominated by layout/ownership, not by C printing. An
LLVM renderer can reuse the neutral parts of CLay/Sharing, but it still needs
the same analyses plus LLVM-specific ABI/poison work. It is not obviously
smaller than C; it is smaller than MLIR. This is a maintainability judgment,
not a measured performance result. Clang already runs LLVM's middle-end on the
current C output, so direct LLVM's distinctive value is representation/control
(typed SSA, attributes, debug metadata, verification), not a proven speed win.

## 13. Recommended next tasks and acceptance boundaries

No implementation is authorized by this note. If the project proceeds, the
smallest defensible sequence is:

1. **Write an ABI note first.** Choose runtime-compatible (A) vs standalone (B);
   define the exact LLVM entry signature, `Env` passing, table/shim ownership,
   `preserve_none`/`tailcc` policy, and how native/wasm/GPU differ. Acceptance:
   the note names every runtime symbol the LLVM module calls and every symbol
   the runtime needs from the module.
2. **Native scalar spike.** One frozen program, no closures/ADTs/foreigns:
   `Word`/`Natural`/`FloatBits`, `Let`, `Branch`, `Return`, `TailDirect`.
   Emit `.ll`, run `opt -passes=verify`, compile with the pinned clang, link the
   runtime shim, compare result/exit/IO with C and JS. No timing claim.
3. **Primitive conformance.** Implement the §5 table as a property suite
   (`div0`, `mod0`, shifts 0/31/32/64, U32 wrap, Nat boundary, NaN, ±0,
   out-of-range `fptoui`, `fmod`, ordered/unordered comparisons). Acceptance:
   no LLVM poison/UB for any defined Bend input.
4. **Layout/ownership.** Reuse CLay + Sharing; test packed vs node constructors,
   erased fields, arrays, `Many` keep, `Affine` seal/take, project/ctr_take.
   Acceptance: a differential trace of allocations/refcounts and values against
   the C target for the same BIR.
5. **Closures/tails.** Add captures/stages, public unary wrapper, over-apply,
   `TailApply`; verify constant stack for tail recursion. For wasm, first
   decide `+tail-call` vs a BIR-level trampoline; do not assume `musttail`.
6. **Exports/foreign/IO.** Preserve `bend_export_*` modes; decide whether a new
   `.ll` foreign alternative is added or existing `.c` foreign sources are
   compiled to LLVM and linked. Keep IO request CIDs/order and nullary rereads.
   Acceptance: the existing consumer-facing ABI still runs unchanged.
7. **Determinism/debug.** Emit canonical `.ll`; test byte equality across two
   runs and independent of cwd/temp paths. Do not add `!dbg` until BIR spans
   exist; if added later, exclude debug metadata from G1 comparison.
8. **Target expansion only after native.** wasm is gated on a portable runtime
   and tail-call/trampoline proof; GPU direct LLVM (NVPTX/AMDGPU) is a separate
   spike and cannot cover Metal. MLIR/SPIR-V is the recommended GPU/multi-target
   path.

**Acceptance boundary:** a green small-program native run with the real runtime
is the first meaningful proof. A `.ll` file that passes `opt`/`clang` but has no
execution is not a backend acceptance. No target cutover, no new benchmark
claim, and no promotion of C backend source presence follows from this note.

## 14. Unresolved questions

1. Can `preserve_nonecc` be emitted and matched reliably for the runtime's
   generated `WL_SIG` on AArch64, including programs whose word arity exceeds
   the six register words (`comp.ts:190,3201`), and what happens at `-O0` where
   the C runtime disables the attribute (`c_runtime.c:101-110`)?
2. Does `musttail` remain guaranteed for the exact generated signatures on
   every claimed target (native, wasm with `+tail-call`, NVPTX/AMDGPU), or is a
   trampoline mandatory outside native?
3. Is the redirect-cell mixed-size atomic access sound when expressed directly
   in LLVM IR, or must it stay behind the C runtime helper?
4. Does LLVM's optimizer preserve the runtime's refcount calls if they are
   declared with unknown memory effects, and what is the minimal attribute set
   that is both correct and useful?
5. Is `BIR.Copy` dead (no lowerer emits it) and should the IR contract delete
   it, or does a future lowering need it as a sharing marker?
6. Where do source spans for debug info come from, and can they be added without
   changing BIR IDs/serialization?
7. Should the LLVM target accept `.ll` foreign sources, or compile existing
   `.c` foreign sources and keep the C foreign ABI? The current target selection
   is `.c` for C (`c_emit_core.bend:33-40`) and `.js` for JS
   (`js_backend.bend:26-32`); there is no `.ll` alternative today.
8. What is the exact public ABI contract for a standalone (non-runtime) LLVM
   target, and must it preserve `bend_export_*` or is a new consumer adapter
   acceptable?

## References

External (fetched 2026-10-24):

* [L1] LLVM Language Reference: <https://llvm.org/docs/LangRef.html> — call
  `musttail`/`tailcc`, poison, `udiv`/`shl`/`fptoui`, fast-math, atomics,
  address spaces, `unreachable`.
* [L2] Opaque pointers: <https://llvm.org/docs/OpaquePointers.html>.
* [L3] Developer Policy, IR backwards compatibility and C API stability:
  <https://llvm.org/docs/DeveloperPolicy.html#ir-backwards-compatibility>.
* [L4] LLVM license (Apache-2.0 WITH LLVM Exceptions):
  <https://llvm.org/LICENSE.txt>.
* [L5] NVPTX usage (address spaces, triples, `libdevice`):
  <https://llvm.org/docs/NVPTXUsage.html>.
* [L6] AMDGPU usage (triples, address spaces, unsupported constructs):
  <https://llvm.org/docs/AMDGPUUsage.html>.
* [L7] Upstream wasm tail-call test requiring `-mattr=+tail-call`:
  <https://github.com/llvm/llvm-project/blob/main/llvm/test/CodeGen/WebAssembly/tailcall.ll>.
* [L8] Upstream clang wasm `musttail` availability test:
  <https://github.com/llvm/llvm-project/blob/main/clang/test/CodeGen/WebAssembly/musttail.c>.
* [L9] WebAssembly target features (tail-call, exception-handling, etc.):
  <https://github.com/llvm/llvm-project/blob/main/llvm/lib/Target/WebAssembly/WebAssembly.td>.
* [L10] WebAssembly target README:
  <https://github.com/llvm/llvm-project/blob/main/llvm/lib/Target/WebAssembly/README.txt>.
* [L11] LLVM C API core (calling-convention enum; tail-call kind;
  `LLVMSetFunctionCallConv`):
  <https://github.com/llvm/llvm-project/blob/main/llvm/include/llvm-c/Core.h>.
* [L11b] LLVM `CallingConv::ID` numeric values (`Tail = 18`,
  `PreserveNone = 21`):
  <https://github.com/llvm/llvm-project/blob/main/llvm/include/llvm/IR/CallingConv.h>.
* [L12] LLVM C API LLJIT/ORC:
  <https://github.com/llvm/llvm-project/blob/main/llvm/include/llvm-c/LLJIT.h>.
* [L13] Source-level debug info:
  <https://llvm.org/docs/SourceLevelDebugging.html>.
* [L14] Statepoints/GC (not required for refcounting, relevant if a moving GC
  is ever introduced): <https://llvm.org/docs/Statepoints.html>.
* [M1] Modular Mojo compiler walkthrough (MLIR LIT→KGEN→POP→LLVM dialect,
  debuginfo dialect): <https://github.com/modular/modular/blob/main/Mojo/docs/compiler/MojoCompilerWalkthrough.md>.

Repository (baseline `f46ad0f6`):

* `bend2/selfhost/backend_ir.bend` — BIR contract.
* `bend2/selfhost/backend_lower.bend` — lowering; `finish` (131-141), match
  `Region` (1190-1225), applications (686-900).
* `bend2/selfhost/c_backend.bend` — C renderer and runtime ABI (17-40,
  2480-2525, 2626-2650, 3074-3090, 3173).
* `bend2/selfhost/c_backend_layout.bend` — CLay physical rules (11-42,
  87-110, 187-209).
* `bend2/selfhost/c_backend_physical.bend` — construct/project/tag and
  ownership (13-17, 495-560, 671-780).
* `bend2/selfhost/c_backend_sharing.bend` — sharing/hotness fixed point
  (1-60).
* `bend2/selfhost/c_runtime.c` — generated runtime: macros (57-170), encoding
  (173-230), atomics (342-454), term/refcount (692-860), work loop
  (1127-1275), `corpus_eval` (2100-2145), main/IO (2720-2860).
* `bend2/selfhost/c_emit_core.bend` — `.c` foreign selection (33-40).
* `bend2/selfhost/js_backend.bend` — direct-style blocks (643-654), symbol
  read (950-985), `.js` foreign selection (26-32).
* `checkpoints/SELFHOST_IR_ARCHITECTURE.md` — FIR/BIR boundary and laws §4.
* `evals/native_compiler_llvm.ts` — existing C→LLVM split pipeline and version
  pins (73-100).
* `bend2/main.ts` — clang discovery and native/GPU build (398-460).
* `bend2/comp.ts` — generated runtime signature (3209-3221), float contract
  pragma (3645).
