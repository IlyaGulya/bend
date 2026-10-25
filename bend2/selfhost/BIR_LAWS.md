# BIR laws: checked FIR → Backend IR → JavaScript and C

This document specifies the Backend IR (`bend2/selfhost/backend_ir.bend`, BIR)
and the transformation obligations that connect it to its input and its two
targets. It is a normative contract plus an honest statement of what is
mechanically enforced, what a named fixture or harness defines but was not
exercised here, and what remains an open proof obligation.

It does not describe parser architecture; for that see `ARCHITECTURE.md`. The
input side (what a checked program is, and why the checked domain is what it is)
is specified in `FIR_LAWS.md`; this document only names the preconditions it
consumes.

Throughout:

- **F** is a value of `Checked.CheckedProgram{source, modules, signatures,
  metadata}` (`checked_frontend.bend:18`) produced by the success path of
  `Checker.check` (see `FIR_LAWS.md`).
- **B** is a value of `BIR.Program` (`backend_ir.bend:233`).
- **lower** is `BackendLower.lower` (`backend_lower.bend:1943`) and
  **lower_library** is `BackendLower.lower_library` (`backend_lower.bend:1945`);
  both return `ProgramResult = Lowered{program} | LowerFailure{message, span}`
  (`backend_lower.bend:13-15`).
- **J(B, files)** is `JSEmit.emit_linked` reached through `js_emit.emit`
  (`js_emit.bend:21-30`, `js_backend.bend:1139`).
- **C(B, runtime, files)** is `CEmit.render` reached through
  `c_emit_core.emit` (`c_emit_core.bend:93`), which calls `CBackend.emit`
  (`c_backend.bend:3173`).

## 0. How to read the law status tags

Each normative statement carries one or more tags. They are not
interchangeable.

| Tag | Meaning |
| --- | --- |
| **[N]** | Normative: a producer or consumer of BIR MUST satisfy this. Violating it is a compiler defect even when no current test notices. |
| **[C]** | Checked by target code, which returns a failure instead of emitting. The cited function is the check. |
| **[P]** | Procedure: a named fixture and/or harness defines how to run a check and what it must observe, but this document did not find a matching read receipt at the current base. It is not evidence that the run happened. |
| **[M]** | Measured: a read receipt whose pinned source hashes match the current base. None of the fixture entries in §6.5 reaches this bar; the one receipt found pins a different NF revision. |
| **[O]** | Open: no mechanized proof and no exhaustive test exists in this tree. |

"Compiled" does not mean "proved". In particular:

- Passing Bend typecheck for the compiler sources only says the compiler source
  is well-typed; it says nothing about BIR input at run time.
- A code-review argument ("the builder cannot produce anything else") is
  identified as such where used.
- Nothing here claims a mechanized semantic-preservation proof for the
  selfhost FIR → BIR → target pipeline, and none is established in this tree.
  This does **not** deny the separate core theory developed in
  `bend2/bendtt.lean`; the gap is specifically the connection from checked FIR
  and BIR to the two production targets. No Lean development is in scope for
  this document.
- The laws in `checkpoints/SELFHOST_IR_ARCHITECTURE.md` §4 (F1-F3, L1-L7,
  B1-B2, G1-G2, K1-K5) already exist as implementation obligations. This
  document refines and instantiates the BIR-side ones (L1-L7, B1-B2, and the
  BIR boundary of G1/G2/K5); it does not invent a new law system and does not
  claim those obligations were absent. §1.4 gives the exact mapping.

## 1. Domains, inputs, and the observation boundary

### 1.1 Input domain

`lower(F)` consumes an F produced by the checker success path. It relies on the
FIR obligations listed in `FIR_LAWS.md`, in particular:

- every **designated semantic handle field** reachable from `modules`,
  `signatures`, and `metadata` points to an in-bounds arena object of the role
  that field expects. The pinned source spells these handles as, for example,
  `IR.Symbol.signature`, `IR.Occurrence.ty`, `IR.CheckedBinding.ty`,
  `IR.CheckedVariable.pattern`, `IR.CheckedConstructor.pattern/symbol`,
  `IR.Definition.binders/result/body`, `IR.TypeDecl.kind`, and
  `Scope.ArenaGlobal.ty/value`. Record-valued fields such as
  `ModuleMetadata.scope` must themselves satisfy their structural invariants.
  A `U32` is a handle only when its named field has that role; plain payloads —
  literal words, source offsets, lengths, field ordinals, code ids, flags — are
  **not** handles and carry no in-bounds claim. The arena is not released
  before lowering;
- `modules` and `metadata` are paired and ordered consistently;
- per-module name resolution must use the module's `ModuleMetadata.scope`;
  `signatures` is the accumulated global signature list with canonical keys;
- checked occurrences are per-invocation facts; the checker has already
  validated lexical scope, quantities and coverage on the source body, and
  `unsafe` definitions were accepted without a termination proof;
- FIR contains no type descriptors; descriptor construction and normalization
  are BIR responsibilities (`lower_catalog.descriptor`, `DescriptorNf`).

Lowering re-checks only the facts it needs (for example namespace/path identity
in `Catalog.prepare_modules`, `lower_catalog.bend:1400-1430`); it is not a
second checker.

An F that violates a FIR obligation is outside this contract. Nothing in BIR
prevents building a `BIR.Program` by hand (the C and JS smoke fixtures do), so
the laws below are about both **produced** and **admissible** programs: a
hand-built B must satisfy the same well-formedness conditions.

### 1.2 Result law for lowering

**[N]** `lower(F)` and `lower_library(F, exports)` are pure functions of their
arguments. For every F in the input domain they return, operationally, exactly
one of:

- `Lowered{B}` satisfying §3 and the laws in §4; or
- `LowerFailure{message, span}`, in which case no BIR program exists and no
  target may be invoked.

Mechanism: the entry builds a `State` and walks `Catalog.Definition`s with
explicit failure accumulation (`problem_first`, `fail`, `lower_complete`,
`backend_lower.bend:58-70, 1935-1963`). Every recursion is structural over the
checked tree; there is no fuel in lowering itself.

Status: **[N]**, **[O]** for the stronger claim "it always returns". The
implementation is structurally recursive and every failure path has an explicit
branch; a divergence or stack exhaustion is not modelled by the type. The
single-return-value claim is a reading of the code, not a theorem.

### 1.3 Observation domain and representation relation

The central law is relational and trace-based. It is **not** a function from a
program to a printed string, and it does not narrow the checkpoint's `Obs`
(`checkpoints/SELFHOST_IR_ARCHITECTURE.md` §4) to terminating `show` output.

Fix:

- F, its ending E, and the target T ∈ {JS, C};
- an environment ξ that fixes the foreign oracle, host calls/arguments,
  scheduler order where the source leaves it open, and any other external
  nondeterminism. Two runs with unrelated ξ are not comparable; see (7).

Define `SRun(F, ξ)` and `TRun(T(lower(F)), ξ')` as sets of **complete
behaviors**. A behavior is a finite-or-infinite sequence of observable events
with one of these outcomes:

- `Value(v, τ, w)` — events `w`, then a returned value of type τ;
- `Error(class, payload?, w)` — events `w`, then a runtime failure/error
  outcome;
- `Diverge(w)` — events `w`, then no termination. `w` may be finite (including
  the empty visible trace when execution is silent forever) or infinite; the
  `Diverge` tag keeps a silent infinite execution distinct from "no behavior
  yet" and from a finite empty trace. There is no "infinite empty sequence":
  a silent divergence is `Diverge(ε)`.

Visible events are standard-stream writes, effect requests/answers under ξ,
host calls/callbacks, and returned values, in order. Compile-time diagnostics
are not runtime behaviors: if lowering or a target fails, no program and no
behavior set exists, and the diagnostic is the outcome.

**Normative observation relation `≈_obs`.** For the same ξ (or related oracles,
see 7):

1. **Value relation `≈_τ`.** For each checked type τ, source values are related
   to target values (a JS value or a C `Term` after ABI conversion) by a
   representation relation derived from τ, the target ABI, and the constructor
   layouts. It is not defined as "same `show` text".
2. **Complete-behavior correspondence (includes infinite behaviors).** Every
   source complete behavior has a target complete behavior of the same kind,
   and conversely:
   - `Value(v, τ, w)` corresponds to `Value(t, τ, w')` when `w` and `w'` are
     event-wise related (same visible operations/arguments under `≈`) and
     `v ≈_τ t`;
   - `Error(...)` corresponds to `Error(...)` under the error relation of (6);
   - `Diverge(w)` corresponds to `Diverge(w')` only when `w` and `w'` are
     event-wise related. In particular an infinite visible output stream must
     correspond event-by-event; it is not enough that both sides diverge.
   For a deterministic ξ this is equality of complete-behavior sets; otherwise
   it is the allowed-set relation of (7).
3. **Finite prefixes.** Every finite prefix of a source complete behavior is a
   prefix of some target complete behavior, and conversely, when both sides are
   observed under related ξ. This is what constrains mixed finite/infinite
   nondeterminism: a target may not omit an observable prefix that the source
   can produce, nor produce one the source cannot. Divergence itself is not
   refuted: `Diverge` is a legitimate complete behavior, and no termination is
   asserted. A compiler may preserve divergence, but may not replace a
   divergent behavior with a finite Value/Error (or the reverse), nor with a
   divergence whose visible event trace differs.
4. **Executable top-level observation.** For a closed executable, the complete
   behavior may be projected to what the runtime actually exposes: for a
   terminating pure main, the final `show` bytes plus exit status; for an IO
   main, the effect-event trace plus final value/exit; for divergence, the
   visible output/effect stream plus nontermination (`Diverge`). This
   projection is an explicit weakening for the top-level result only; it does
   not define `≈_τ` and does not apply to library calls. If `show` is
   undefined/abstract for the main type, a target that refuses to print is a
   compile/admission outcome, not a value relation.
5. **Library observation.** `show` text is insufficient: two different
   closures may print identically. A library observation is a finite or
   infinite, well-typed host interaction sequence: calls of exported keys with
   arguments related by `≈_τ`, callback invocations supplied by the host, and
   returned callable values (including closures) compared by their behavior
   under further well-typed calls. If a host interaction diverges, it is
   `Diverge(w)` with a corresponding visible event trace. Every finite prefix
   must correspond, and a pair of returned callables is distinguished if any
   well-typed continuation distinguishes them.
6. **Errors.** The contract must distinguish three things, and this document
   states which it does and does not fix:
   - **error class** — success vs runtime failure vs admission/compile failure;
   - **error payload** — a message/span/location;
   - **exact stderr bytes** — formatting, ordering, and text.
   The preservation law fixes the class: the same ξ and the same input yield
   the same class on source and target. It does **not** silently require exact
   text. Whether payload or exact bytes are part of `Obs` is a decision for the
   source-observation definition (O-7); R-9 records the current C/JS text
   difference as that open decision, not as an assumed equality.
7. **Foreign nondeterminism and host effects.** Compare under a fixed oracle
   relation or as sets of allowed traces, never by equating two unrelated runs.
   If a host effect can return different values for the same request, the
   requirement is that the source and target allowed-trace sets correspond for
   the same oracle relation (pointwise equality only when the oracle is
   deterministic).
8. **Resource state.** Logical ownership is part of the correctness contract,
   not a trace event: a use-after-free, double consume, lost sharing, or wrong
   refcount policy is a defect (BL-3, C-6, checkpoint F3/B2). Concrete
   allocation addresses, allocation counts, RSS, stack depth, timing, and GC
   schedule are **not** observable and need not match. A host resource-limit
   abort (`RESOURCE_LIMIT`, exit 73 in the guarded lanes) is a tooling outcome,
   never a semantic PASS/FAIL verdict and never a substitute for a trace.

The current target entry points realize the top-level part as follows (this is
mechanism, not the definition of `Obs`):

- JS: `io_exit` (defined in `js_runtime_io`, `js_backend.bend:1176`; emitted
  into `js_main`, `1193`) either runs `io_run` when the resolved main type is
  `IO`, or prints `$show_value(type, run_loop(main()), 0)` and a newline.
  Errors print to stderr and set exit code 1.
- C: for a native `IO` head, `MAIN_PURE` is 0 and the runtime drives the effect
  task (`c_runtime.c:2791-2810`); otherwise `MAIN_PURE` is 1, `SHOW_DESC` is
  built by `Phys.show_build` and `show_val` prints it (`c_runtime.c:2620-2680`).
  `plan_executable`/`plan_executable_io`/`plan_executable_show`
  (`c_backend.bend:473-503`) select the branch from the normalized head; a
  head failure is a compile failure.

**[N]** The preservation laws in §4 and §6 are statements about `≈_obs` under
the same ξ. They do not assert termination, productivity, or a step bound for
arbitrary source programs. `unsafe` definitions were accepted without a
termination proof (FIR), and lowering, JS, and C all preserve that possibility
of divergence. The full trace/representation relation of this section is **[O]**;
what exists is a mixture of mechanism-level arguments, partial fixture
procedures, and named open obligations. Nothing in this document upgrades a
partial finite observation into the full relation.

**Not observable.** Allocation addresses, RSS, allocation counts, stack depth,
timing, generated identifier spellings, evaluation order of independent
*effect-free* operands, and textual shape of the emitted program are outside the
relation. They may change between implementations. When an operand's evaluation
performs an effect, its order can be observable; that case is deliberately left
open in BL-8/O-3 rather than assumed.

### 1.4 Relation to the existing checkpoint laws

`checkpoints/SELFHOST_IR_ARCHITECTURE.md` §4 defines implementation obligations
for this pipeline. That table is the authority for the obligation set; the
present document refines it against the current source revision and adds the
premises, mechanisms, target checks, and proof-status split it does not spell
out. Mapping:

| Checkpoint law | Where this document instantiates it |
| --- | --- |
| Central law: `Obs(source) = Obs(render(lower(CheckedFIR)))` | TL-1 and TL-3, with the trace/representation relation `≈_obs` of §1.3. This is not string equality, not termination, and not equality of unrelated foreign runs; it is conditional on WF and the foreign oracle relation. |
| F1 (publication preserves reachable handles) | `FIR_LAWS.md` (input precondition), not restated here. |
| F2 (occurrence preserves judgement/context) | `FIR_LAWS.md` (input precondition). |
| F3 (affine owner not copied across handoff) | `FIR_LAWS.md`; BIR consumes the already-checked facts in BL-3. |
| L1 (erased QZero not executed; live mapping unchanged) | BL-2, and WF-10's declared-ordinal rule. |
| L2 (ANF/strict Let preserves order and single evaluation) | WF-9, BL-8. |
| L3 (direct/partial/over-application equivalent to curried application) | BL-4, BL-5, BL-6, BL-7, BL-18. |
| L4 (closure conversion preserves bindings/uses) | BL-9, WF-2, WF-3. |
| L5 (construct/project/match share one layout; quantities match the instantiated constructor) | WF-10, WF-11, BL-16, C-4. |
| L6 (branch/join/tail lowering preserves control and termination) | WF-4, WF-5, C-1, JS-4. |
| L7 (canonical descriptors preserve type/show/IO interpretation and native authority) | BL-11, BL-12, §5, C-7. |
| B1 (each native primitive matches its allowed declaration) | BL-17. |
| B2 (rendered entries/foreign callbacks preserve the public ABI and effect order; nullary factories are not memoized) | BL-18, BL-7, JS-3, JS-5, JS-6, C-1, C-8. |
| G1 (determinism of ids/serialization) | §6.6: deterministic BIR for a fixed F and deterministic target renderers. Stage-to-stage byte identity remains a stage-receipt property, not a BIR theorem. |
| G2 (acceleration does not weaken admission/coverage) | §6.6: no BIR-level loss of checked bodies; chunked generation must preserve the same BIR and renderer (TL-2). Gate coverage policy stays with the gates. |
| K1-K4 (historical 57r defunctionalization obligations) | Historical; not a current ABI. Not instantiated here. |
| K5 (current `Run`/`Stack` step protocol) | §6.6: the protocol is generated driver control, not BIR; its BIR-side interface is that the chunked function is the same `lower` and produces the same BIR. The typed Stack obligations themselves remain in the checkpoint/step receipts and are not re-proved here. |

Where the checkpoint's §3 description of `Block` lists only
`Return/TailDirect/TailApply/Failure`, the current source also has `Region` and
`LeaveRegion`; §3.2 of this document is the current-revision statement.

## 2. BIR at a glance

`BIR.Program{codes, declarations, constructors, families, type_functions,
ending}` (`backend_ir.bend:233`) is the whole target-neutral program. It has no
source syntax, no checker environment, no target name, and no separate
"normalized IR".

- **Code** (`backend_ir.bend:203-204`): a numbered body with capture-use
  metadata and live parameters.
- **Block** (`194-202`): `Return`, `Let`, `Branch`, `Region`, `LeaveRegion`,
  `TailDirect`, `TailApply`, `Failure`. There is no unit block.
- **Op** (`178-187`): `Copy`, `PrimitiveCall`, `Closure`, `Direct`, `Apply`,
  `LoadSymbol`, `Construct`, `Project`, `HasTag`.
- **Atom** (`13-23`): `Local`, `Capture`, `Symbol`, `Word`, `Natural`,
  `FloatBits`, `Text`, `Boolean`, `Null`, `Undefined`.
- **Primitive** (`32-144`): the closed target-operation catalog.
- **Descriptor** (`149-176`): the runtime type-expression language, built from
  checked type terms and canonicalized keys.
- **Metadata** (`209-232`): declarations, constructor layouts, families, type
  functions, and the `Executable`/`Library` ending.

Two encodings are deliberately duplicated and must agree: numeric ids used by
C (`constructor`, `code`, `label`) and canonical string keys used by JS
(`tag`, `key`). §3.5 makes agreement a well-formedness condition because the
targets use different halves of each pair.

## 3. Well-formedness of BIR

Write `WF(B)` for the conjunction of the clauses below. There is **no
`validate` function** in this tree; `WF` is a specification on producers and
hand-built programs, not a runtime check. The table at the end of this section
says which clauses any code checks at all.

### 3.1 Codes and identifiers

**WF-1 (code identity).** `Program.codes` contains at most one `Code` per `id`.
Every code id mentioned by `Direct.code`, `TailDirect.code`, `Closure.code`,
`FunctionDeclaration.code`, `Entry.code`, or `Export.entry` resolves to exactly
one `Code` in `Program.codes`.

- Mechanism: `lower_catalog` allocates code numbers from a monotonically
  increasing `Preparation.next_code` (`prepare_definition`, `prepare_law`, and
  `prepare_family`), and `lower_catalog.bend:1467` hands that counter to the
  lowering state; `backend_lower.enter` increments it per nested code
  (`backend_lower.bend:210-213`). `definitions` never reuses one.
- C checks only that a referenced code has an entry (`IndexLookup.find` in
  `direct_ctl`/`tail_direct_ctl`/`closure_ctl`/`load_symbol_ctl`,
  `c_backend.bend:2314-2530`). It does **not** check duplicate code ids:
  `build_with_code` stores `by_code[show(id)]` with `Map.set`
  (`c_backend.bend:291-295`), last writer wins.
- JS checks nothing; duplicate `function $bN` declarations would be a JS
  parse/overwrite situation.
- Status: **[N]** for the producer, **[C]** only for "referenced code exists",
  **[O]** for duplicate detection.

**WF-2 (local and parameter scopes).** Within one `Code`:

1. `Code.parameters` ids are distinct and describe only *live* parameters, in
   source order. Erased parameters are absent (§4.2).
2. Every `Atom.Local{id}` is either the id of a `Code.parameters` entry or the
   `id` of a `Let` that structurally encloses the atom in the same code body.
3. Every `Let.id` is distinct from every other `Let.id` in the program and from
   every `Parameter.id`. (Freshness is global in practice; only non-aliasing
   within a code is required semantically.)
4. `Atom.Capture{slot}` is in `[0, length(Code.captures))` for the innermost
   enclosing code.

- Mechanism: `fresh` never decrements (`backend_lower.bend:100-103`);
  `reserve` only raises the counter to avoid header-parameter collisions
  (`104-107`); `bind_slot` allocates the `Let.id` before the op is pushed
  (`192-208`); capture slots are assigned in `resolve_capture` from
  `Frame.capture_count` (`182-185`) and `Code.captures` is `List.reverse` of
  the same list (`leave`, `219-223`).
- C checks `Local` naming only indirectly: `atom_part` emits `lv<id>`, and
  `params_env` binds parameters (`c_backend.bend:2061-2067, 1149`); an unknown
  local becomes an undeclared C identifier (a C compile error, not a BIR
  diagnostic). `Capture` emits `x[slot]`; an out-of-range slot is a C
  out-of-bounds read, not a diagnostic.
- JS likewise emits `$v<id>` / `$c<slot>`; unknown names are JS reference
  errors.
- Status: **[N]**, no target-level validation. A violation is undefined target
  behavior. **[O]** for any static guarantee.

**WF-3 (capture list ordering).** For a `Code`, `captures[i]` is the `Use` of
the value passed as capture argument `i` at every `Closure`/`Direct` site that
targets this code.

- Mechanism: `Capture{slot,index}` list is built in first-use order and
  reversed once at `leave`; `capture_uses` extracts uses in that same order
  (`backend_lower.bend:214-223`); `capture_arguments` evaluates the same list
  (`228-252`); `call_reference` prepends capture args to direct args
  (`266-278`).
- Status: **[N]**. Targets only use the `Use` list for C node sealing; JS
  ignores `Code.captures` values and emits positional parameters
  (`js_backend.bend:447-460, 655-658`).

### 3.2 Block structure and terminators

**WF-4 (totality of control).** Every control path of a `Block` ends in exactly
one of:

- `Return{value}`;
- `Failure{message}`;
- `TailDirect{code,args}` or `TailApply{fn,arg}`;
- `LeaveRegion{label}` naming a `Region.label` that lexically encloses it.

`Let`, `Branch` arms, and `Region.body`/`Region.next` are themselves total
blocks under this definition. No block "falls off the end". `Region.body` may
only reach `Region.next` through `LeaveRegion{label}`.

- Mechanism: `prefix` maps the pending instruction list onto nested `Let` or
  `Branch{condition, next, failure}` and ends in the supplied continuation
  (`backend_lower.bend:125-130`); `finish`/`finish_last` turn the final bind of
  a returned local into `TailDirect`/`TailApply` when it is the last
  instruction (`131-140`). Every match row is
  `Region{label, body, next}` where the failure block of every guard is
  `LeaveRegion{label}` (`checked_cases`, `1197-1233`).
- The JS renderer relies on the invariant: `Region` emits
  `$caseL:{<body>}<next>` and `LeaveRegion` emits `break $caseL`
  (`js_backend.bend:627-644`). Fallthrough would silently execute `next`.
- C compiles `Region.next` as a separate entry reached only by `LeaveRegion`
  (`region_ctl`/`leave_ctl`, `c_backend.bend:2275-2313`); `leave_ctl` fails on
  an unknown label (`find_region`).
- JS does not validate the label; a label outside an enclosing `$case` is a JS
  syntax error.
- Status: **[N]**, **[C]** for the C label lookup, **[O]** for the producer
  invariant as a whole.

**WF-5 (region labels).** `Region.label` values are unique within a code (and
distinct across nested regions). C resolves the *nearest* enclosing region by
prepending entries (`find_region`, `2291-2301`); JS's labelled-`break` resolves
the nearest enclosing label. Duplicated labels therefore silently change the
control target.

- Mechanism: `fresh` per checked case (`checked_cases`, line 1225).
- Status: **[N]**, unvalidated.

**WF-6 (branch condition).** `Branch.condition` denotes a Boolean value: a
`Boolean` atom, or an op result whose runtime representation is the Bool
`True`/`False` term.

- JS lowers a branch to `if(<atom>)` and therefore depends on JS truthiness
  (`js_backend.bend:645-654`); C lowers it to
  `term_aux(<atom>) == <True cid>` (`branch_ctl`/`cond_part`,
  `c_backend.bend:2248-2274`).
- Mechanism: `guard` erases constant `Boolean` conditions, pushing `Stop` for
  `False` (`backend_lower.bend:120-124`); remaining conditions come from
  `HasTag`, primitive comparisons, or pattern tests, all of which produce Bool.
- Status: **[N]**. A non-Boolean condition would diverge between the targets
  (e.g. a non-zero `Word` is JS-truthy; C compares a tag word).

### 3.3 Call and application shapes

**WF-7 (call arity).** For every call site:

- `Direct{code,args}`: `length(args) = length(Code.captures) +
  length(Code.parameters)` for the target code (`args` are captures first,
  then live arguments).
- `TailDirect{code,args}`: the same equality.
- `Closure{code,captures,parameters}`: `length(captures) + length(parameters) =
  length(Code.captures) + length(Code.parameters)`; `parameters` is a suffix of
  the code's live parameter list after the captures already supplied, and is
  **non-empty**. A closure with no remaining parameter is ill-formed: C rejects
  it ("BIR closure has no remaining parameter", `closure_ctl`,
  `c_backend.bend:2480-2496`), and JS would evaluate the code immediately and
  return its result instead of a function (`closure` with an empty parameter
  list renders `tail_call(...)`, which is a value, not an arrow;
  `js_backend.bend:468-481`). Lowering never produces one: an erased-only
  lambda is lowered inline (`lambda_checked`, `backend_lower.bend:1482-1492`),
  `absurd_checked` always supplies one live parameter (`1494-1519`), and
  `partial` only emits a closure when parameters remain (`954-987`).
- `Entry{code,arity}`: `arity` is the register count of the target entry for
  that code, i.e. captures + live parameters. For an `Export`, `Catalog.export_entry`
  stores only the definition's live parameter count
  (`lower_catalog.bend:775-779`); the equality with the entry arity holds
  because a top-level definition is closed (zero captures).

- Mechanism: `direct_arity` fails on a quantity/entry arity mismatch
  (`backend_lower.bend:899-902`); `partial` builds the adapter code and only
  emits `Closure` when parameters remain (`954-987`); `call_reference` builds
  `Direct` args as captures followed by supplied args (`266-278`).
- C checks these at emission: `tail_direct_ctl` ("BIR tail call arity
  disagrees with its entry", `2314-2333`), `call_ctl` ("BIR call passes ...
  arguments to an entry of arity ...", `2365-2376`), `closure_ctl` ("capture
  count disagrees", `2480-2496`), `entry_code` ("code arity disagrees",
  `2570-2578`). Status: **[C]**.
- JS does not check; a mismatch is a wrong-arity JS call at run time. Status:
  **[N]**, **[O]** for JS.

**WF-8 (declaration vs atom form).** The following are ill-formed:

- `Atom.Symbol{_, key}` whose declaration is `LazyDeclaration`;
- `Atom.Symbol{_, key}` whose declaration is a `FunctionDeclaration` with zero
  live parameters;
- `Op.LoadSymbol{_, key}` whose declaration is a `FunctionDeclaration` with
  non-zero live parameters, or a foreign/native declaration.

Rationale: `Symbol` is a first-class callable value; `LoadSymbol` is the strict
read of a nullary definition. The current lowering respects this exactly:
`reference_kind` emits `Symbol` for a native or foreign declaration of any
arity, or for an ordinary definition with live parameters; it emits
`LoadSymbol` for an ordinary definition with no live parameters, and `Null`
for a type-only definition (`backend_lower.bend:548-560`). A zero-live-parameter
definition is a `LazyDeclaration` (`definition_closed`, `1833-1855`). A
native/foreign value is a `Symbol` because it is callable; in the current closed
catalog every native primitive takes at least one live argument, and a foreign
entry always includes the continuation, so such a `Symbol` names an entry of
arity at least 1, as C's `symbol_value` requires (`c_backend.bend:1216-1230`).

- C enforces the split: `symbol_part_item` rejects a lazy as a value
  ("evaluated by LoadSymbol, never a first-class value") and
  `symbol_value` rejects a nullary entry (`c_backend.bend:1194-1230`);
  `load_symbol_ctl` rejects a parameterised function read (`2434-2459`).
  Status: **[C]** for C.
- JS does not enforce it: `$D[key]` is a getter for a lazy declaration and a
  function for a parameterised declaration, so JS would happily treat each as a
  value. Status: **[N]**, JS permissive.

**WF-9 (strict operand form).** `Let.op` is a strict operation: its value is
computed before `next` runs. `Direct`, `Apply`, `PrimitiveCall`, `Construct`,
`Project`, and `HasTag` all denote computations of the bound local. `Copy` and
`Closure` denote values.

- JS emits `const $v<id> = <op>; <next>` (`js_backend.bend:645-654`); a
  `Direct` op renders as an immediate call `run_loop($bN(...))` (`572-582`).
- C emits an immediate statement (or a continuation segment for a call)
  before the next block; `let_ctl`/`pure_let` (`c_backend.bend:2232-2247`).
- `Copy` is admitted by the type but is **not produced by the current lowering**
  (no `BIR.Copy{...}` constructor appears outside matchers in the tree). Its
  only defined behavior is "bind this atom"; JS and C both render it as the
  atom (`js_backend.bend:574`, `c_backend.bend:1251`).
- Status: **[N]** for the forms `lower` produces; **[O]** for `Copy` as an
  independently produced op.

### 3.4 Constructor, projection, and tag metadata

**WF-10 (constructor metadata agreement).** For every `Construct{constructor,
tag, fields}`, `Project{..., constructor, field, key}`, and
`HasTag{..., constructor, tag}`:

1. `constructor` is the `id` of exactly one `ConstructorLayout L` in
   `Program.constructors`.
2. For `Construct` and `HasTag`, `tag = L.key` (the constructor's key). This is
   the only place a constructor-level key is compared.
3. For `Project`, `L.fields[field]` exists and is `Some key'` (a live field),
   and `Project.key = key'`. `Project.field` is the field's **declared ordinal
   including erased positions**; it is never an erased slot (`L.fields[field] =
   None`), because an erased projection is already `Null` before this point.
4. `Construct.fields` lists only live fields, in declaration order. For each
   entry, `Field.identity` is the field's declared ordinal including erased
   positions, and `Field.key` is the declared key of that ordinal.
5. `ConstructorLayout.fields` has one entry per declared field including erased
   positions; `None` marks an erased field and `Some key` marks a live one.

- Mechanism: `field_values` skips a declared erased field and otherwise emits
  `Field{identity, key, bir_use(q), value}` via
  `Catalog.constructor_field(constructor, identity)`
  (`backend_lower.bend:449-469`; `lower_catalog.bend:1617-1625`).
  `constructor_operands` inserts a placeholder `BIR.Null{}` for an erased
  checked binding so positions line up (`backend_lower.bend:514-543`).
  `constructor_native` gives every constructor a marker: `Family.ShortName`
  for a native family, `"Data." + key` otherwise (`lower_catalog.bend:591-593`);
  `ConstructorLayout` is built with `field_names(v_32)`
  (`lower_catalog.bend:1258-1267`).
- Why agreement matters: JS uses the **string** half (`tag`/`key`) and emits a
  record keyed by `Field.key`; it ignores the numeric field ordinal
  (`js_backend.bend:482-490, 572-582`). C uses the **numeric** half: it looks
  up the layout by `constructor` and the slot by `Project.field`
  (`construct_part`/`project_part`, `c_backend_physical.bend:671-760`). A
  disagreement silently produces different programs with no diagnostic.
- C failures that do exist: "BIR constructs a constructor with no layout row",
  "the projection of X names an erased field", "the constructor has a different
  live field count than its value arguments"
  (`c_backend_physical.bend:659-760`).
- Status: **[N]**; **[C]** only for the listed C checks.

**WF-11 (constructor ids and keys).** `ConstructorLayout.id` values are
distinct. `ConstructorLayout.key` values are distinct. Every arm of every
`Family` names exactly one constructor key, and each key appears in exactly one
family arm (`CLay.arm_of` returns the first match and does not detect a second).

- Mechanism: `Preparation.next_constructor` allocates ids
  (`lower_catalog.bend:1249-1266`); `insert_constructor` keeps the first
  definition (`733-748`). Duplicate keys are rejected by `sharing_plan`:
  "constructor key appears twice" (`c_backend_sharing.bend:944`).
- Status: **[N]**; **[C]** in C sharing analysis; JS does not check
  (last assignment to `$FIELDS` wins).

**WF-12 (family/type-function metadata).** For each `Family`:

- `arity` is the family's total binder count, and `quantity_prefix` counts the
  implicit quantity binders among them. `nf_arity` implements
  "supplied + prefix = arity" (`descriptor_nf.bend:598-600`).
- `arms` are the constructors in declaration order; each `DescriptorArm.fields`
  mirrors the constructor's declared fields, including erased ones
  (`DescriptorField{key=None, quantity=Erased, ty}`).
- `native` is the authoritative representation marker; nothing may infer a
  representation from `key` or `name`.

For each `TypeFunction`, `arity` and `quantity_prefix` have the same meaning and
`body` is a closed descriptor (except that it may contain
`DescriptorParameter` references bound by its own arity).

- Mechanism: `prepare_family` builds `Family{key, name, native_marker(native,
  name), prefix, words_count(params), arms}` (`lower_catalog.bend:1249-1290`);
  `telescope_binder` emits erased/template fields explicitly
  (`535-558`); `prepare_definition_symbol` builds
  `TypeFunction{key, native_marker, prefix, length(quantities), body}`
  (`850-860`).
- Status: **[N]**; no target validates arity/prefix consistency, though both
  consume them (`descriptor_nf.bend:598`, `c_backend_layout.bend:394-410`,
  `js_backend.bend:1010-1024`).

### 3.5 Descriptors

**WF-13 (descriptor scoping).** `DescriptorParameter{index}` is a de Bruijn
index counted from the **end** of the applied argument list: index 0 is the last
available argument. An index with no available argument is **abstract**, not
ill-formed and not a failure. `DescriptorFailure{message}` denotes a failure,
not a type: either normalization could not reduce, or a required checked
descriptor fact was absent when the catalog was built
(`Catalog.foreign_result_type`, `Catalog.export_facts`,
`lower_catalog.bend:1100-1107, 815-826`). A target must not lay it out or print
it as ordinary metadata.

- Mechanism and exact rule: `val_at`/`val_nth` in `descriptor_nf.bend:182-199`
  index `env` from its end; out-of-range yields `NfMissing{source}`.
- Consumers: `CLay.layout_of_desc` maps `NfFail` to `LayoutFailed` and every
  abstract form to `LayoutBox` (`c_backend_layout.bend:336-390`); JS passes
  descriptors to the runtime `$type` evaluator, which throws for `fail`
  (`js_backend.bend:923-948, 1189-1190`).
- Status: **[N]**; **[O]** for agreement between the two normalization
  implementations (§5.4).

**WF-14 (canonical keys).** Every key in `DescriptorRef`,
`DescriptorConstructor`, `DescriptorNamedFill`, `DescriptorNamedPlus`,
`Family.key`, `TypeFunction.key`, `ConstructorLayout.key`, and declaration
`key` is the canonical qualified key produced by `Catalog.qualify` /
`Scope.canonical_name` (`lower_catalog.bend:49-52, 72-75`). No consumer may
resolve a suffix, a last segment, an alias, or a case variant.

- C: `IndexLookup.find` with the key exactly as written
  (`c_backend_link.bend` header; `c_backend.bend:983-1006`).
- JS: exact `$FIELDS`/`$TYPE`/`$TYPEF` maps; the only qualified fallback is the
  single declared `namespace.key` then bare key used for `CID(...)` in effect
  sources (`js_backend.bend:127-149`), which is a source-rewrite rule, not
  descriptor resolution.
- Status: **[N]**, **[C]** in the C link pass for `CID`/`FID` keys.

### 3.6 Declarations, foreign sources, and endings

**WF-15 (declaration keys).** Declaration keys are distinct. `find_declaration`
returns the first match in C; JS `$D[key] = ...` assignment is last-wins. A
duplicate key is therefore ill-formed by contract even though the checker
rejects duplicates in source.

- Status: **[N]**, **[O]** (no BIR-level check).

**WF-16 (foreign declaration).** `ForeignDeclaration` satisfies:

1. `arity = length(parameters)` (live parameters only).
2. `length(parameter_types) = arity`; each type is one descriptor per live
   parameter in live order.
3. `sources` is the list of **declared** import alternatives in source order,
   non-empty, and each entry is the exact declared path string.
4. `namespace` and `imported` are the canonical module namespace and the
   imported path as written (`Catalog.foreign_namespace`,
   `lower_catalog.bend:1094-1099`).
5. `result` is a descriptor (possibly `DescriptorFailure` only when the checked
   source had no result type; the emitter must then fail).

- Mechanism: `definition_foreign` builds the `Foreign` record, with
  `live_parameter_types` dropping erased binders exactly as `BIR.Parameter`
  drops them (`lower_catalog.bend:1088-1155`); `definition_kind` copies it into
  `ForeignDeclaration` with `arity = length(parameters)`
  (`backend_lower.bend:1746-1750`).
- Status: **[N]**, **[C]** for some arity facts: C's `entry_foreign` requires
  `arity = args + 1` (`c_backend.bend:2611-2625`); JS's `link` requires a
  declared `.js` alternative to exist (`js_backend.bend:55-70`).

**WF-17 (ending and exports).** `Executable{main_type}` means a definition
named `main` exists with no live parameters. `Library{exports}` means every
export key names a declaration; `Export.entry` is `Some` only for a fast
ordinary function with live parameters (`Catalog.export_entry`,
`lower_catalog.bend:775-779`), and `length(parameter_types)` is the number of
live arrows of the published signature (`live_arrow_types`,
`lower_catalog.bend:800-813`).

- C validates export shapes at render time and fails closed on a mismatch
  (`export_rows`, `export_direct`, `export_symbol_item`,
  `c_backend.bend:514-567`). A direct export whose entry arity is below the
  checked parameter count becomes mode 2 (consume parameters, return a closure);
  a declared arity above the checked count fails.
- JS validates that no export parameter has an unresolved canonical type
  (`ending_check`/`export_check`, `js_backend.bend:1126-1137`) and converts a
  native-`Nat` parameter with `nat_in` (`js_backend.bend:1028-1078`).
- Status: **[N]**, **[C]** for both targets, with the exact failures above.

### 3.7 Who checks what

| Clause | Producer obligation | C | JS |
| --- | --- | --- | --- |
| WF-1 code ids | **[N]** | referenced code exists **[C]**; duplicates unchecked | unchecked |
| WF-2 scopes | **[N]** | undeclared C names at C compile | undeclared JS names at run time |
| WF-3 capture uses | **[N]** | arity **[C]**; uses only influence sealing | ignored |
| WF-4 block totality | **[N]** | label lookup **[C]**; fallthrough unchecked | JS fallthrough / syntax |
| WF-5 label uniqueness | **[N]** | nearest label; unchecked | nearest `break`; unchecked |
| WF-6 Bool condition | **[N]** | compares True cid | JS truthiness |
| WF-7 call arity | **[N]** | **[C]** | unchecked |
| WF-8 Symbol/LoadSymbol split | **[N]** | **[C]** | unchecked |
| WF-9 strict operand form | **[N]** | renders strict statements/continuations | renders `const` statements |
| WF-10 ctor metadata agreement | **[N]** | layout/slot lookups **[C]**, agreement with `tag`/`key` unchecked | uses strings only |
| WF-11 ctor uniqueness | **[N]** | duplicate key **[C]** in sharing | last wins |
| WF-12 family metadata | **[N]** | no check | no check |
| WF-13 descriptor scope | **[N]** | abstract/failure distinction preserved | abstract/failure preserved |
| WF-14 canonical keys | **[N]** | exact lookup **[C]** for foreign ids | exact maps |
| WF-15 declaration uniqueness | **[N]** | first wins | last wins |
| WF-16 foreign metadata | **[N]** | arity **[C]** | path presence **[C]** |
| WF-17 ending/exports | **[N]** | **[C]** | **[C]** |

## 4. Lowering laws

Each law gives a precondition, a postcondition, the mechanism, and its status.

### 4.1 Well-formedness preservation

**BL-1.** *Pre:* F is in the input domain and `lower(F) = Lowered(B)`.
*Post:* `WF(B)` holds.

Mechanism: code and local freshness (`fresh`), capture ordering (`leave`),
exclusive conversion of zero-live-parameter definitions into lazy declarations
(`definition_closed`), arity selection in `application_direct` / `partial`,
erased-field skipping in `field_values`, and descriptor construction from
canonical scopes (`Catalog.descriptor`, `lower_catalog.bend:77-115`).

Status: **[N]**, **[O]**. This is the central unproved obligation. There is no
validator and no proof; the claim rests on reading the producer. The clauses
with target checks in §3.7 are the only parts an implementation actually
enforces.

### 4.2 Erasure

**BL-2.** Lowering erases exactly the erased source positions, and an erased
position is never evaluated, never stored, and never observed.

Precisely:

1. An erased source parameter is absent from `Code.parameters`,
   `FunctionDeclaration.parameters`, `BIR.Parameter`, and counts toward no
   entry arity (`Catalog.parameter`, `lower_catalog.bend:63-66`).
2. An erased source argument is skipped, not lowered: `argument_prefix` and
   `apply_rest` advance over `SourceArgument{Ast.QZero{}, _}` without calling
   `lower_occurrence` (`backend_lower.bend:918-950`).
3. An erased let binding binds `ErasedSlot` and does not lower the occurrence
   (`let_bindings`, `1565-1585`); resolving an `ErasedSlot` yields `BIR.Null{}`
   (`resolve`, `156-160`).
4. An erased constructor operand is a `BIR.Null{}` placeholder and is dropped
   from `Construct.fields`; only live fields are stored
   (`field_values`, `449-469`).
5. An erased pattern position binds `ErasedSlot`; erased constructor fields are
   not projected (`pattern_fields`, `1143-1150`; `erase_pattern`, `1058-1064`).
6. An erased projection is `BIR.Null{}` before it can reach a target
   (`project_field`, `1018-1022`).

Erased **type** information is not lost: descriptors are built from checked
type terms independently of runtime arguments, and an erased argument's checked
term is the instantiated element type used by array primitives
(`erased_type_term`, `backend_lower.bend:358-363`).

Status: **[N]**. Mechanism is direct; **[P]** `evals/c_backend_smoke.bend` and
`evals/clay_layout_smoke.bend` contain erased fields/positions and their
harnesses define how to run them, but no matching receipt was read and this
document ran nothing. No test enumerates all erased shapes.

### 4.3 Affinity and ownership facts

**BL-3.** `Arg.use`, `Parameter.use`, `Field.use`, and `Code.captures`
translate checked quantity contracts. `Affine` bounds a consumer to at most
one logical use; `Many` permits repeated use. They do **not** prove that the
caller's reference is dead after supplying that consumer. Lowering derives
these contracts from checked source quantities, never from target liveness:

- `use(Ast.QMany) = Many`, every other source quantity maps to `Affine`
  (`backend_lower.bend:48-51`); `bir_use(Unrestricted) = Many`, else `Affine`
  (`52-55`).
- A constructor field's use is `Many` when the declared field quantity is
  `Unrestricted`, otherwise the input use (`matcher_field_use`,
  `backend_lower.bend:1696-1699`).
- `Catalog.quantity` maps `QZero/QOne/QMany` to `Erased/Once/Unrestricted`
  (`lower_catalog.bend:54-57`); `Catalog.parameter` maps `Once -> Affine`,
  `Unrestricted -> Many`, drops `Erased` (`63-66`).

In particular, `TypedOccurrence.formal` (`checker_ir.bend:53`) becomes
`SourceArgument.quantity` and then `Arg.use`
(`backend_lower.bend:674-677,903-926`). `Field.use` comes from the constructor's
declared field quantity (`449-464`). Local resolution reuses its existing
`Atom`; it does not insert a `Copy` for each reference (`156-208`).
Consequently, two calls to an affine `id(s: String)` may both carry
`Arg{Affine, Local{s}}` when the caller's `s` is unrestricted. This is a source
trace, not an executed regression receipt. Moving that local on the first
`Affine` argument is not licensed by BL-3.

This is a *translation of checked facts*, not a new analysis. The source
checker already validated uses on the checked body (FIR). Consequently:

- **No re-evaluation is introduced.** A `Many` local is still bound once; later
  references are `Atom.Local{id}` and read the bound value. The use fact only
  licenses a target to keep or share it.
- **C sealing must be conservative.** `c_backend_sharing.sharing_plan`
  (`c_backend_sharing.bend:2799`) computes the hot set from these facts plus
  producer facts. When a demanded value's facts are unknown, it sets `forced`
  and seals every constructor (header, `c_backend_sharing.bend:8-74`). This is
  a semantic-safety fallback: over-sealing loses performance, never sharing.
  Under-reporting a use in BIR would not be rescued by `forced` if the fact is
  stated as `Affine` and believed, so BL-3 is a real obligation.
- C `seal_box` implements the policy: `Many` emits `term_keep`, `Affine` emits
  `rfc_seal` (`c_backend_physical.bend:540-566`). JS has no such pass; JS value
  semantics are uniform references and do not encode affinity.

Status: **[N]** for quantity translation. Quantities alone are not a caller
move/keep plan: C also needs path-sensitive liveness and alias handling (C-6).
The source sharing analysis documents conservative departures from the
reference emitter, but its hot-set result does not supply those lifetimes.
The corrected C ownership implementation and its behavioral regressions remain
**[O]**; neither the mapping nor sealing proves them.

### 4.4 Strict operands, order, and application shape

**BL-4 (exact application).** A checked application that supplies exactly the
callee's live parameter count lowers to one `Direct{code, captureArgs ++
liveArgs}` bound by a `Let` (or to `TailDirect` when it is the tail of the
current code). Lowering does not fuse or reorder the callee's parameters.

- Mechanism: `application_direct_values` checks
  `length(parameters) = length(args)` and calls `direct_arity`, else falls to
  `partial` (`backend_lower.bend:884-898`); `finish_last` promotes a final
  `Direct` bind of the returned local to `TailDirect` (`131-140`).
- Status: **[N]**, **[C]** in C arity checks.

**BL-5 (partial application).** An application that supplies fewer live
arguments than the callee's live parameters lowers to a first-class closure:

- a fresh adapter `Code{id, captures = uses(args), parameters = remaining,
  body = TailDirect{callee, indexedCaptures(args) ++ parameters}}`, then
- `Closure{adapterId, args, remaining}` (`partial`,
  `backend_lower.bend:954-987`).

*Post:* applying the resulting value to the remaining arguments in order
behaves as the exact application to all arguments. The adapter's captures are
evaluated once, at closure creation (`capture_arguments`, `228-252`).

Status: **[N]**; **[P]** `evals/c_backend_smoke.bend` (`code_cap`) and
`evals/c_backend_library_smoke.bend` (`code_partial`) are fixtures;
`evals/c_backend_step_smoke.ts:37,150-156` and
`evals/c_backend_library_run.ts` are **procedures** that would compile and run
them, expecting `26` and `export ok` respectively. No matching read receipt
exists at 943de390, and this document's preparation ran neither procedure.
**[O]** for a general proof.

**BL-6 (over-application).** Extra live arguments after an exact application
are applied one at a time, in source order, by successive strict `Apply` lets;
never as one argument list (`apply_rest`, `backend_lower.bend:932-952`).

Status: **[N]**; **[P]** the C executable smoke fixture contains an
`(add(5))(7)` path, and `evals/c_backend_step_smoke.ts` is the procedure that
would observe it as part of `26`; no receipt was read. **[O]** for order
equality with the reference evaluator when the extra arguments have effects
(see O-3).

**BL-7 (nullary and lazy declarations).** A definition with zero live
parameters lowers to `LazyDeclaration{key, body}`; each `LoadSymbol` reevaluates
the body. It is never cached and never a first-class value. A definition with
one or more live parameters lowers to `FunctionDeclaration{key, code,
parameters}`.

- Mechanism: `definition_closed` selects lazy iff the capture list is empty and
  `parameters` is `Nil` (`backend_lower.bend:1844-1855`).
- Targets: C calls the nullary entry per read (`load_symbol_ctl`,
  `c_backend.bend:2434-2459`); JS installs a getter that calls the body per
  property read (`deferred`, `js_backend.bend:950-962`).
- Status: **[N]**, **[C]** in C (nullary read of a parameterised function is an
  error), **[P]** the smoke fixtures contain `LoadSymbol "zero"` and a lazy
  `factory`; their harnesses define the check, but no matching receipt was
  read.

**BL-8 (evaluation order).** The order among independent strict operations is
whatever the block sequence says; targets emit the sequence exactly:

- JS: `const` statements and nested `if`/labelled blocks, left to right.
- C: statements in the containing segment, with non-tail calls resuming in a
  continuation segment.

Lowering's own ordering is fixed by how the pending instruction list is folded:
`push` conses the newest instruction at the head (`backend_lower.bend:108-111`),
while `prefix` builds `Let{head, prefix(rest, next)}` (`125-130`), so the head
ends up **innermost**, i.e. executed last. The net effect is that instructions
execute in the order they were created, even though the list is consed:
lowering arguments in source order (`argument_prefix`, `918-930`) yields
argument evaluation in source order, and guards created in pattern order are
tested in that order. This specification **does not claim** that this order is
the reference evaluator's order for operands whose evaluation performs an
observable effect. The claim asserted is only: whatever order lowering chooses,
both targets execute exactly that order.

Status: **[N]** for target fidelity; **[O]** for "lowering's order equals the
source semantics" (O-3). Do not strengthen this section without evidence.

### 4.5 Captures and closures

**BL-9.** A closure captures exactly the locals it needs, by value, at creation
time, and a nested code never reads a local of an enclosing code except through
a capture.

- Mechanism: `resolve` looks up the current frame; if the slot's owner is an
  enclosing frame, it allocates or reuses a capture slot
  (`resolve_capture`, `backend_lower.bend:182-185`); `leave` records
  `Code.captures` and rejects free captures at top level (`leave`/`leave_value`,
  `219-227`; `definition_closed`, `1844-1847`).
- Capture arguments are evaluated at the closure site: `capture_arguments`
  calls `resolve` for each captured slot, then `close` emits
  `Closure{code, args, parameters}` (`228-264`).
- JS closes over the evaluated arguments as an immediately applied arrow
  (`closure`/`closure_captures`, `js_backend.bend:473-481`); C stores them in a
  fresh closure node (`closure_ctl`/`closure_text`,
  `c_backend.bend:2480-2523`).
- Status: **[N]**; **[P]** the smoke fixtures contain `code_cap` and a closure
  factory; their harnesses define the checks, but no receipt was read.
  **[O]** generally.

### 4.6 Values that are not runtime data

Some checked positions denote no runtime value and lowering must not invent one:

- a reference to a type-only definition lowers to `BIR.Null{}`
  (`reference_kind`, `backend_lower.bend:548-560`);
- a family symbol lowers to `BIR.Null{}` (`symbol_value`, `562-565`);
- an erased projection is `BIR.Null{}` (`project_field`, `1018-1022`);
- an unsolved checked hole pushes `Stop{BIR.Failure{"bend: unsolved hole ..."}}`
  (`lower_node`, `1345`), so the emitted program fails at that point rather than
  fabricating a value.

**BL-10.** A `Null` produced from a type-only/erased position is never observed:
it appears only where no live field, argument, or result is read. `Null` is
rendered as `null` (JS) / `0` (C), and both targets rely on it never escaping
into a live position.

Status: **[N]**; **[O]** (the "never observed" property is a producer
invariant, not checked).

### 4.7 Descriptor provenance and metadata authority

**BL-11 (descriptors are built, canonicalized, and normalized).**

1. A checked type term is converted by `Catalog.descriptor` into a
   `BIR.Descriptor` with canonical keys (`lower_catalog.bend:77-115`,
   `descriptor_node`, `396-457`). Sugar is preserved as `DescriptorFill`/
   `DescriptorPlus`/named variants; the runtime evaluator decides.
2. Foreign parameter/result descriptors and export parameter descriptors are
   normalized once with `DescriptorNf.normalize_in` in the program's family/
   type-function context (`normalize_foreign_definitions`,
   `lower_catalog.bend:757-773`; `exports`, `828-840`). Normalization runs with
   an empty value environment, so free `DescriptorParameter`s remain abstract
   rather than being invented.
3. The main type is stored as constructed (`ending`, `1425-1433`) and is
   normalized by each consumer: C through `CLay.head_native` →
   `NF.nf` (`c_backend_layout.bend:1008-1046`), JS through the runtime `$type`
   evaluator (`js_main`, `js_backend.bend:1193`).
4. Family arms and type-function bodies are stored as constructed; consumers
   normalize at layout/shape time (`CLay.layout_of_desc`, JS `$type`).

**BL-12 (native authority).** A target MUST decide representation from the
declared `native` marker and the declared family/arm structure, never from a
key's spelling, a suffix, or a "looks like Nat" test.

- `Catalog.native_marker(native, key)` is `Some key` only for the native base
  library; user datatypes get `None` in `Family.native`
  (`lower_catalog.bend:579-583`).
- `Catalog.constructor_native` gives `Family.ShortName` for native families and
  `"Data." + key` otherwise (`591-593`). The C physical emitter treats only a
  fixed intrinsic list as intrinsic and fails if such a constructor reaches
  emission unlowered (`intrinsic_marker`, `c_backend_physical.bend:179-192`;
  `construct_marker`/`project_marker`, `656-760`).
- `CLay.layout_native` recognizes exactly `Nat`, `U32`, `F32`, `Array`,
  `IO.OP`; every other marker falls through to the declared data layout
  (`409-433`).
- JS records the marker in `$PRIMITIVES` (`constructor_layout_source`,
  `js_backend.bend:980-986`) and in `$TYPE.native`, and classifies export
  parameters by the *declared* marker map (`js_native_markers`,
  `196-200`; `js_parameter`, `1028-1065`). A user type function with no native
  marker is `"TF"` and is refused as an unresolved export parameter rather than
  guessed to be Nat.
- Status: **[N]**, **[C]** for C's intrinsic refusal and JS's export refusal.
  **[O]** for a general statement that marker sets are complete for all Base
  types.

### 4.8 Foreign sources: exact declared paths

**BL-13.** The word "foreign source" in BIR means a list of *declared*
alternatives. A target selects one alternative by extension and joins bytes by
exact path string equality. It never derives, normalizes, or rewrites a path.

- BIR: `ForeignDeclaration.sources` retains every alternative in source order
  (`lower_catalog.foreign_sources`, `1088-1108`; `definition_foreign`,
  `1143-1155`). Empty is ill-formed for a foreign declaration (WF-16).
- C: `c_emit_core.foreign_c_source` takes the **first** entry ending in `.c`
  in source order (`c_emit_core.bend:33-38`); no `.c` is a compile error
  (`plan_declaration`, `67-81`). `join_imports` finds the host-supplied
  `BIR.SourceFile` by `String.eq(path, known)` exactly; missing is
  `"bend: missing declared C target: <path>"` (`83-91`).
- JS: `js_backend.js_source` takes the first entry ending in `.js`
  (`js_backend.bend:26-33`); missing is
  `"bend: foreign definition has no .js import: <imported>"`
  (`link_declaration_source`, `63-69`). `js_source_text` joins by exact path
  (`356-367`); missing is a link failure naming the path (`377-394`).
- Duplicate path semantics: one path must have one namespace. JS rejects the
  same path under two namespaces (`link_add_namespace`, `47-54`); C rejects it
  in `plan_add` (`c_emit_core.bend:42-58`).
- Status: **[N]**, **[C]** in both targets. **[P]**
  `gates/selfhost_cases/missing_c_target.bend` and
  `gates/selfhost_cases/missing_js_target.bend` define the diagnostic lanes
  through `gates/selfhost.ts`; no receipt was read.

**BL-14 (foreign id spelling).** A target that spells program-owned ids inside
foreign source (C `CID(<key>)`, `FID(<key>)`; JS `CID(<key>)`) resolves the key
by exact lookup in the program's own maps; a miss is a compile failure naming
the spelling, never a guessed id.

- C: `c_backend_link.rewrite` is lexical (comments and literals copied through,
  block comments and quotes entered only if they close, backslash line
  splicing); exact `IndexLookup.find` over `cid_map`/`fid_map`; a miss is a
  `LinkFailure` (header and `link_complete`, `c_backend_link.bend:13-45`).
  The maps contain only declared constructor/def spellings, plus the
  namespace-qualified alias `namespace:key` when the namespace is non-empty
  (`c_backend.bend:3097-3127`); two keys that sanitize to the same C macro are
  rejected (`macro_collision_cids`, `3151-3171`).
- JS: `js_scan` reads `CID(<key>)` only in code mode; comments, strings, and
  template literals are copied through; the key resolves to
  `namespace.key` if declared, else the bare key if declared, else the scan
  fails naming the path (`js_backend.bend:127-149, 257-354`).
- A foreign request key must not equal a constructor key; JS rejects it
  (`foreign_name_check`, `82-97`). C does not run that check, but both spaces
  are present in the CID table and a collision would assign one CID row twice.
  This is a **reported asymmetry** (§8 R-2).
- Status: **[N]**, **[C]** in both targets (**[C]** for the collision check in
  JS only). **[P]** the JS/C link fixtures named in §6.5 would exercise the
  rewrite; no receipt was read.

### 4.9 Pattern matching and case layout (checkpoint law L5)

**BL-16.** A checked match lowers to an ordered chain of one `Region` per row.
For a row `i` with label `l`:

- the row body is `Region{l, body_i, next_i}`, where `next_i` is the lowering
  of row `i+1` (or `Failure{"bend: runtime fail-stop"}` after the last row);
- every pattern test that can fail is a `Guard{condition, failure =
  LeaveRegion{l}}`, so a failed test leaves this row and runs `next_i`;
- tests are emitted in pattern order: constructor identity via `HasTag` (or a
  native scalar test for `U32`/`F32`/`Char`/`Nat`/`Bool`/`String`/`Array`),
  then live fields projected by declared ordinal;
- each live pattern binder becomes a fresh `Let`/local holding the projected
  value, and the row body is lowered in the extended environment;
- an erased pattern position binds `ErasedSlot` and is neither tested nor
  projected;
- no row body is duplicated: `next_i` is shared by every failing guard of the
  row, and later rows exist once.

Mechanism: `checked_cases` (`backend_lower.bend:1197-1233`) creates the label
with `fresh`, builds the row with `patterns` and a `LeaveRegion`, and appends
the remaining rows as `next`; `patterns`/`pattern`/`pattern_constructor`
(`1066-1123`) emit `tag`, `scalar_test`, and `Project`; `pattern_fields`
(`1129-1150`) walks declared ordinals and uses `erase_pattern` for `QZero`;
`scalar_test` chooses `PrimSameValue` or `PrimFloatBitsEqual`
(`1125-1128`).

Status: **[N]**; **[P]** `gates/selfhost.ts` defines stage-0/stage-1 lanes that
compile and execute match-heavy sources, but no receipt was read for this base
and no BIR-level match fixture enumerates erased/nested/multi-scrutinee rows.
**[O]** for the equivalence with the reference matcher (first-match order,
coverage, native scalar comparisons) as a general theorem.

### 4.10 Primitive operations (checkpoint law B1)

**BL-17.** `PrimitiveCall{primitive, args, types}` denotes exactly the
operation named by `primitive` in the closed `Primitive` catalog, applied to
`args` in order, with `types` as the element-type fact required by array
operations. `Primitive` constructors name target operations, never source
aliases (`backend_ir.bend:32-144`).

- Lowering produces a primitive only from an authoritative source fact:
  a native constructor/law lowered by `construct_native`/`tag_native`/
  `project_native` (`backend_lower.bend:479-505, 988-1022`), or a checked
  application of a native declaration whose key `Catalog.primitive` resolves
  through the native marker (`lower_catalog.bend:603-694`). A user definition
  cannot become a primitive by name.
- `types` is non-empty only for array primitives and holds exactly one element
  descriptor (`primitive_element`/`primitive_types`/`element_fact`,
  `backend_lower.bend:327-448`). WF-3/BL-11 require it to be the actual
  element type; C's cell plan consumes it (`CLay.array_cell`), JS ignores it
  (R-3).
- The two targets implement each catalog entry separately: JS maps the
  constructor to a runtime helper (`primitive_name`/`primitive_public`,
  `js_backend.bend:665-892`), C maps it to a runtime expression
  (`prim_part`/`prim_call_part`, `c_backend.bend:1368-1710`). Agreement with
  the declared semantics and with each other is TL-3's obligation, not a
  consequence of sharing BIR.
- Status: **[N]**; **[C]** only that each constructor has a renderer (a missing
  case is a compiler-source type/match error); **[O]** for B1 per primitive
  (overflow, shift counts, float bits/NaN/signed zero, Unicode and empty
  strings, array ownership and index bounds). The C executable smoke covers
  exactly `U32.add`; the C library smoke covers `U32.add` only.

### 4.11 Rendered entries and foreign callbacks (checkpoint law B2)

**BL-18.** The public ABI and its sequencing are part of the contract:

1. **JS public value.** A public function value is a unary JS function wrapped
   with `public_closure`: each argument is passed through `run_force(..., $raw)`
   so the trampoline marker convention is respected
   (`public_closure`, `js_backend.bend:468-472`). An export with a direct entry
   calls the code when the host supplies exactly `arity` arguments and curries
   the remainder otherwise (`export_field`, `1085-1097`).
2. **C public value.** Every callable/foreign/continuation boundary carries
   exactly one `Term`; an export is a table row `(fid, mode, arity)` and is
   driven by `bend_export_call`/`bend_export_apply` (C-8). A function value is
   one `term_clo`; a wide function's arity-one wrapper closes the first stage
   (C-1).
3. **Foreign callback.** A foreign declaration is a request constructor of its
   `args + 1` fields (arguments plus continuation). C's entry allocates the
   node and the effect source owns the protocol (`entry_foreign`,
   `c_backend.bend:2611-2625`; `CID`/`FID` rewrite BL-14). JS builds
   `{$:key, args, kont}` and wraps the continuation for a native-`Nat` answer
   exactly when the declared result says so (JS-5).
4. **Effect order at an entry.** Checked arguments are evaluated before the
   call/foreign request; the continuation runs only when the runtime supplies
   the answer. A foreign call itself returns a request value; it does not
   perform the effect during argument evaluation. This is the observable
   meaning of "strict arguments, deferred effect".
5. **Nullary factories are not memoized.** A zero-live-parameter definition is
   a `LazyDeclaration` and re-evaluates on each `LoadSymbol`; an export of such
   a definition re-evaluates per host call (BL-7, C-8 mode 1). JS and C both
   implement this (`deferred`; `entry_lazy`).

Status: **[N]**; **[P]** the C library/executable smoke fixtures define export
modes and a lazy factory, and `gates/selfhost.ts` defines the JS/native lanes;
no receipt was read. **[O]** for a general cross-target ABI/effect-order proof. The existing checkpoint law B2 is exactly
this obligation.

## 5. Descriptor normal forms (Nf)

### 5.1 What Nf is

`descriptor_nf.bend` defines `NfVal`, `Nf`, `NfList`, `NfContext`, `NfBind`,
`NfStatus`, `NfArity`, `NfApp` (`descriptor_nf.bend:58-135`). `NfVal` is an
**internal evaluator value** for the runtime's type-expression language. It is
not a third program IR, is not stored in `BIR.Program`, and is not a public
result type of lowering.

- `nf(context, descriptor, env, fuel) : Nf` is the evaluator
  (`descriptor_nf.bend:371-377`).
- `materialize(val) : BIR.Descriptor` is the total conversion back to BIR
  (`271-290`); `materialize_all` does the same for lists (`250-269`).
- `normalize(context, descriptor, env, fuel) : BIR.Descriptor` is
  `materialize (nf ...)` except that `NfFail` becomes
  `BIR.DescriptorFailure{message}` (`679-684`).
- `normalize_closed` and `normalize_in` are the two closed-environment entry
  points with a 1024-step budget (`686-696`; `default_fuel`, `150-151`).

The reason Nf exists is ownership of the evaluator's intermediate closure
environment: `NfClosure{quantity, body, env, sources}` is the runtime's
`{k:"L", body, env}` and `sources` is the environment already materialized
(`58-72`). Materializing an unapplied closure becomes
`DescriptorLet{sources, DescriptorLambda{quantity, body}}` (`288-290`),
preserving where the lambda was written.

### 5.2 Normalization meaning

The rules implemented by `nf_descriptor_step` and its helpers are:

- **Parameter**: index from the applied end; out of scope is `NfMissing`
  (abstract), never a failure (`182-199`).
- **Family application**: a family whose supplied count plus its implicit
  quantity prefix reaches its arity receives the quantity arguments before the
  supplied ones; no consumer reads them (`nf_arity`/`nf_family`,
  `598-624`).
- **Type function**: beta-reduced at its arity; further arguments apply to the
  result (curried over-application). `native` is metadata, not a reason to
  refuse reduction, with the one exception of the base IO intrinsic, whose head
  and arguments are preserved (`nf_reduce`, `625-649`; `intrinsic_io`,
  `568-573`; `nf_named_io`, `575-583`).
- **Lambda**: a closure over the environment where it appears; positive beta
  appends the argument; an unapplied closure materializes as a let of its
  captured environment around the lambda (`nf_apply`, `537-567`;
  `materialize`, `288-290`).
- **Arrow**: domain and body normalize under the current environment and the
  arrow keeps its shape (`nf_arrow`, `389-398`).
- **Match/local/substitution/let/bind**: the descriptor language's scoping
  forms. A definite mismatch in a pattern list lets the next case run; an
  undecidable scrutinee (not yet a constructor value) makes the whole match
  abstract, so a later binder cannot mask an unknown earlier case
  (`nf_cases`, `657-677`; tri-state `NfStatus`, `82-91`).
- **Name**: a name that is neither a family nor a type function is an abstract
  type expression (an opaque law), kept as it is. Checking already accepted it;
  it is not a failure.

### 5.3 Abstract versus failure

This distinction is normative:

- **Abstract** has two distinct kinds, and they must not be conflated:
  - `NfOther`: the evaluator cannot or should not reduce further, and the
    expression is a legitimate type expression (an opaque name/law, an
    under-applied family/type function, a lambda/arrow, a stuck match, an
    equality form). It materializes to its (normalized) source descriptor.
    Consumers preserve it: C boxes it (`CLay.layout_val`, `376-390`), JS
    leaves it to the runtime evaluator.
  - `NfMissing`: a `DescriptorParameter{index}` had no value in the
    environment (`val_at`/`val_nth`, `descriptor_nf.bend:182-199`). The
    evaluator keeps the source descriptor; it does not invent a type. This is
    an **unresolved binder**, not a known opaque type. It is not `NfFail`, but
    consumers must not treat it as a concrete type either: C boxes it
    (`BoxOpen`, one Term), and JS's `$type` throws "bend: unavailable
    type-expression binder" when it must force the binder
    (`js_backend.bend:1189`). Whether a free index is admissible is WF-13
    (scoping), not a reduction result.
- **Failure** (`NfFail` → `BIR.DescriptorFailure{message}`): a reduction was
  attempted and is invalid (over-application of a family/type function,
  application of a non-function constructor/quantity/kind value, a malformed
  match case, or exhausted fuel). Consumers must report it, not guess:
  `normalize` converts it to `DescriptorFailure`; `CLay.layout_of_desc` maps
  `NfFail` to `LayoutFailed` (`343-351`); the JS runtime throws for `{fail:...}`
  (`$type`, `1189`).
- Exhaustion is a failure, not an abstract form: `nf` returns
  `NfFail{"the type expression did not normalize within its reduction budget"}`
  at fuel 0 (`371-375`). `layout_fuel` is also 1024 (`c_backend_layout.bend:
  332-334`).
- A family applied to more arguments than its arity is `DescriptorFailure` via
  `NfArity` (`nf_family_apply`, `608-624`); a family applied to too few is
  abstract (`NfType` with partial args).
- An unbound `DescriptorParameter` is `NfMissing` (unresolved binder), not
  `NfFail`; it is not thereby a valid opaque type (see above).

Status: **[N]**; **[P]** `evals/descriptor_nf_smoke.bend` lists expected
outcomes: `MyNat` alias → `Nat`; `MyIO` → IO answer `Nat`; `Id(Nat)` → `Nat`;
`CycA` → `DescriptorFailure`; `K` under → abstract `DescriptorRef "K"`;
`K(Nat,Bool)` → `DescriptorFailure`; `QM` → quantity head with inserted
`Erased`; opaque `Chan` → unchanged; malformed case → failure message; known
mismatch falls through; an unbound parameter stays `DescriptorParameter 0`;
budget-independent items via `normalize_closed`.
`evals/descriptor_nf_step_smoke.ts` defines the run.

The one receipt read, `evals/descriptor-nf-step-smoke-receipt.json`, pins
`descriptor_nf.bend` sha256 `79591089ede2107d84c803a76c2e415ad35a0c358563d76aec7af46ee7b4ba98`,
while the current base file hashes `747dc747fcb1a6b6c1fcbf31a3e164f998fd5fa502f87a8ad3a1facd13859973`.
The receipt therefore measures an **older NF revision** (it corresponds to
commit `0e0f1fe4`) and does not authenticate the current module. No matching
receipt for 943de390 was found; this document's preparation ran nothing.

### 5.4 What is not claimed

- **No idempotence claim.** The code has no test that
  `normalize(normalize(d)) = normalize(d)`, and the implementation does not
  state it. Pre-normalizing foreign/export descriptors and normalizing again in
  a target is therefore assumed harmless, not proved.
- **No equivalence theorem** between `descriptor_nf` and the JavaScript runtime
  evaluator (`$type`, `$type_apply`, `$type_named`, `$type_sugar`). The module
  header explicitly says the rules are the reference runtime's rules; that is a
  code-review claim. The smoke fixture would test specific expected outcomes if
  run; no matching receipt exists for this base.
- **No completeness claim** for type-expression forms not listed by the
  smoke fixture (which itself was not run for this base).
- **Nf is not exported to targets**: `CLay` consumes `NF.NfVal` directly as a
  library API (`c_backend_layout.bend:246-265, 336-390`) and `Phys` consumes
  `CLay` values. This is an intra-compiler API, not a program representation.
  Do not describe Nf as a stricter encapsulation than the source provides: the
  layout module really does pattern-match `NfType`, `NfCtor`, `NfOther`,
  `NfMissing`, `NfQuantity`, `NfKind`, and it is the actual C layout API.

## 6. Target laws

Both targets are pure renderers of an admissible BIR plus passive bytes. They
must not re-infer source facts.

### 6.1 Common target obligation

**TL-1.** For an admissible B and the target's declared foreign alternatives:

- `J(B, files)` and `C(B, runtime, files)` return either one emitted program or
  a diagnostic; they never emit a program that used a guessed name, path, type,
  representation, or id.
- When they emit, the emitted program's set of complete behaviors and finite
  prefixes stands in `≈_obs` (§1.3) to the source set for the same ξ: matching
  events and values under `≈_τ`, the same error class, and `Diverge` behaviors
  with corresponding visible event traces (including infinite outputs). No
  termination is required or implied.

Status: **[N]**; the first half has many concrete **[C]** checks cited below.
The second half is the unproved semantic law (`≈_obs` is **[O]**). No
mechanized proof exists.

**TL-2 (targets do not lower).** Both targets consume `BIR.Program` only.
`js_emit.emit` calls `BackendLower.lower` once and then `Backend.emit_linked`
(`js_emit.bend:21-30`); `c_emit_core.emit` does the same
(`c_emit_core.bend:93-105`). `emitter.bend` composes these two paths. The
emitter reads no syntax tree, no checker environment, and no source alias. The
shared generated composition (one copy of the lowering in a generated module)
is a build-size/dedup property; it is **not** evidence that different canonical
programs preserve semantics. Status: **[N]** for the structure. **[P]** the generated step sources define
provenance checks (e.g. `evals/checker_core_step_lower.ts` requires the
authenticated `backend_ir` import); no receipt for those checks was read.

### 6.2 JavaScript target

**JS-1 (program assembly).** `program_source` concatenates, in order: runtime
constants/helpers, SHOW, CLI, IO, array, foreign, namespace, primitive runtime,
constructor layouts, families, type functions, spliced effect sources, code
bodies, declarations, ending (`js_backend.bend:1157-1163`). Every BIR section
has exactly one renderer; there is no fallback path that reparses the program.

**JS-2 (atoms and constructors).**

- `Local id` → `$v<id>`; `Capture slot` → `$c<slot>`; `Symbol` → `$D[key]`;
  `Word`/`Natural`/`FloatBits`/`Text`/`Boolean`/`Null` map to JS literals or
  the runtime's `f32_from_bits` (`atom`, `431-443`).
- `Construct{_, tag, fields}` → an object literal `{$:<tag>, <key>:<value>...}`
  for live fields only (`record_fields`, `482-490`; `operation`, `572-582`).
- `Project` → `value[key]`; `HasTag` → `value && value.$ === tag`
  (`tag_test`, `583-586`).
- Erased fields are absent from the object. `$show_fields` and the type
  evaluator know declared field quantities from the emitted arm descriptors and
  skip `q === 0` entries (`js_backend.bend:1006-1009, 1178`).
- Status: **[N]**; **[P]** the fixtures named in BL-5..BL-9 define the shapes;
  no receipt was read. **[O]** for JS/C agreement on packed and native shapes.

**JS-3 (calls and closures).**

- `Direct` is a strict call `run_loop($bN(args))`; `TailDirect` is a tail call
  through `run_named`/`run_many` with a depth budget `$td`
  (`call`/`tail_call`, `459-467`).
- `Apply` is `run_loop(run_tail(fn,arg))`; `TailApply` returns
  `run_tail(fn,arg)` (`operation`, `576-579`; `block`, `645-654`).
- `Closure{code, captures, parameters}` is an immediately applied arrow over
  the captured arguments, yielding a JS function over the remaining parameters
  that tail-calls the code with `captures ++ parameters`
  (`closure`/`closure_captures`, `468-481`).
- `Code` renders with capture parameters first, then live parameters, then an
  optional `$td` (`code`, `655-658`).
- Every emitted code has at least one live parameter or is a nullary lazy
  entry. A code with zero live parameters and non-zero captures would render
  as an immediately evaluated expression rather than a function, which is why
  such a `Closure` is excluded by WF-7. A fully nullary definition is a lazy
  getter (§BL-7), not a zero-argument call site.
- Status: **[N]**; **[P]** the C smoke and the JS selfhost gate define these
  shapes per lane; no receipt was read and neither compares the targets.

**JS-4 (branch/region).** `Branch` is JS `if`; `Region` is
`$case<label>:{<body>}<next>`; `LeaveRegion` is `break $case<label>`. The
renderer groups consecutive tag guards with the same immutable subject into a
`switch` only when at least three distinct tags are present
(`tag_group`/`tag_render_group`, `597-644`). This is an emission optimization;
it must preserve every case label and condition bind, and it does because the
arm bodies are rendered unchanged. Status: **[N]**; **[P]** the C/JS smoke fixture sources do not include the
grouped `switch`; the source comment states the intent, and no run was made.

**JS-5 (foreign request).** A foreign declaration becomes a curried function of
its live parameters ending in `$k`, returning
`{$:<key>, args:[...], kont:<k>}`. If the declared result's IO answer type is
native `Nat`, the continuation is wrapped with `nat_in`; otherwise it is `$k`
(`foreign_request`, `497-512`; `js_nat_answer`/`js_io_answer`, `532-558`). The
answer is determined by the declared result descriptor and the program's
declared native markers, never by source spelling.

- Missing `.js` alternative is rejected by `link` before emission
  (`js_backend.bend:55-70`).
- Effect sources are spliced once each, in their own function scope
  (`js_effect_chunk`/`js_effect_sources`, `368-394`); `CID(k)` is rewritten
  lexically (§BL-14).
- Status: **[N]**, **[C]** for path/name resolution; **[P]**
  `gates/selfhost_cases` defines the missing-target lanes; no receipt. **[O]**
  for cross-target protocol equality.

**JS-6 (ending).** `Executable` emits `js_main(descriptor(main_type))`;
`Library` emits an `export default` object
(`ending`, `1120-1125`). A direct export calls the entry when the host supplies
exactly `arity` arguments, else curries the remaining arguments; a symbol
export curries from the first argument (`export_field`/`export_curried`,
`1085-1115`). `JSParameterUnresolved` (a `DescriptorFailure` published by
lowering, or a user type function with no native marker) is a compile failure
(`ending_check`, `1126-1137`). Status: **[N]**, **[C]**.

### 6.3 C target

The C target is not one renderer but a composition:
`c_backend.emit` → `plan_make` → (sharing plan, CIDs, entries, control) →
`render`/`render_assemble` → `c_backend_link` rewrite. Layout, physical storage,
and sharing facts are computed by separate modules and consumed as data.

**C-1 (calling convention).** `c_backend.bend:9-42` states the convention, and
the code implements it:

- Every code, lazy declaration, foreign request, native definition, main value,
  and library export is one entry. `entry_kind_arity` gives the register count
  (`c_backend.bend:272-285`).
- A `FunctionDeclaration` code entry's arity is
  `captures + live parameters` (`entry_code`, `2570-2578`).
- A first-class function value is one `Term`: `term_clo(fid, block)` where the
  block holds captured values; arity-1 entry uses `0` as the block
  (`value_closure`, `2468-2478`; `symbol_value`, `1216-1230`).
- A k-argument partial application is its own stage entry: stage k takes k+1
  registers, closes stage k+1 over them, and the last stage is the real code
  (`build_staged`, `263-271`; `entry_stage`, `2580-2589`).
- Tail calls `WL_JMP` to the target entry; self tail calls use `WL_AGAIN`
  (`tail_direct_ctl`/`self_tail`, `2314-2335`). Tail recursion therefore does
  not grow the C stack *within the trampoline's model*. This is a runtime
  property, not a BIR theorem.
- Non-tail calls push a continuation segment carrying the values the
  continuation reads; the continuation result is bound to the call's local
  (`call_ctl`/`call_next`/`call_done`, `2365-2414`).
- Status: **[N]**, **[C]** for arity and label checks. **[P]**
  `evals/c_backend_smoke.bend` and `evals/c_backend_library_smoke.bend` are
  fixtures whose harnesses would render, compile, and run them; the selfhost
  gate defines the execution lane. No receipt for this base was read.

**C-2 (boxed callable value versus physical storage).** Two forms exist and
must not be confused:

- **Callable/canonical value** `V(τ)`: exactly one `Term` at every callable,
  closure, foreign and capture boundary. `Nat`, `U32`, `F32` are raw word
  payloads; every other ADT is a tagged `Term` (`term_ctr` or `term_pak`). This
  is why foreign parameters/results and continuations need no conversion
  (`c_backend.bend:9-42`).
- **Storage form** `S(τ)`: the laid-out words of a node field or array cell.
  `CLay.Layout` describes it: `LayoutWord` (one word), `LayoutBox` (one Term),
  `LayoutData{words, arms}` (`c_backend_layout.bend:88-104`). `Node` describes
  one constructor's physical words and packedness (`125-142`).
- `Fill`: `V(τ) -> S(τ)`; `Unfill`: `S(τ) -> V(τ)`
  (`c_backend_layout.bend:839-869`). They are built independently from the same
  `Layout`; a `Nest` carries `take : Unfill`, `make : Fill`, and the two word
  counts (`931-996`).

**Borrowed observations [N], [O].** A storage span of one word is not
necessarily a canonical `Term`. In particular, a declared inline `Bool` stores
an arm tag, while a declared inline `Char` stores the `Chr` payload; a consumer
expecting `V(τ)` must not interpret either as a raw `LayoutWord` or a boxed
pointer. Its typed view must use the authoritative arm/layout and canonical
runtime CID. A predicate may inspect the path directly; a packed scalar may
be reconstructed as a non-allocating `term_pak`. Neither operation consumes
the path, clears source slots, changes refcounts, or duplicates an affine
child. Do not replace an unsupported generic borrowed read with a blanket
copy/unfill of an arbitrary form. Full ownership transfer remains governed by
C-6. Behavioral acceptance must include Bool predicates/branches and Char
payload reads through both constructor fields and array-cell provenance;
source admission alone does not establish this boundary.

**C-3 (fill/unfill round-trip obligation).** For every `Layout L` built by
`value_layout`/`node_layout`:

1. `layout_fill(L)` and `layout_unfill(L)` pair each field in the same order,
   with `take` and `make` swapped between directions
   (`form_nests`, `931-973`).
2. `nest_fits` enforces that the target run fits the value's word count and the
   source run fits the node's word count in both directions (`979-1005`).
3. Consequently, for a canonical value whose tag matches the arm and whose
   fields match the declared layouts, `unfill (fill v) = v` and
   `fill (unfill s) = s` are the intended identities on the represented
   domains.

Status: **[N]** for (1)-(2) (they are direct consequences of the builder);
**[O]** for (3). There is no mechanized proof and no exhaustive test. The
executable consumers are `Phys.fill_plan_jobs`, `Phys.unfill_result_jobs`,
`operand_code`, and `project_words` (`c_backend_physical.bend:447-472,
495-529, 677-760`); `evals/clay_layout_smoke.bend` and
`evals/physical_show_smoke.bend` exercise specific layouts, not the identity.
A strict reading: the builder guarantees the *plans* are mutually inverse in
structure; it does not guarantee that the emitted C implements them correctly
for every runtime value.

**C-4 (construct/project).** `Construct` with a layout whose live field count
equals the operand count: packed nodes (zero or one `w32` word) become
`term_pak(cid, payload)`; other nodes allocate one block and fill every live
slot. Sealing distinguishes the field's storage kind: a `Many` field whose
layout is one box is `term_keep`-ed, a `Many` field with inline data advances
the word cursor (its nested boxed children are handled by the unbox's
`ctr_take`), and an `Affine` box is `rfc_seal`-ed
(`seal_box`/`seal_kind`/`seal_slots_jobs`, `c_backend_physical.bend:540-587`;
`construct_*`, `593-671`). `Project` looks up the
declared slot by ordinal, rejects an erased slot, and unfills the stored words
into a canonical `Term` (`project_*`, `677-760`).

- A packed node's field storage is the payload word, not a node offset.
- An intrinsic constructor marker reaching emission unlowered is a failure
  (`construct_marker`/`project_marker`), because a primitive must appear as a
  `PrimitiveCall` by then.
- Status: **[N]**, **[C]** for the listed checks.

**C-5 (arrays).** Array primitives consume `PrimitiveCall.types`, which holds
exactly one element descriptor for the arrayed primitives. `CLay.array_cell`
derives `arr`/`words`/`lgs` from the element layout
(`c_backend_layout.bend:1098-1116`); `Phys.array_part` emits element
Fill/Unfill (`c_backend_physical.bend:1081-1096`). `types` is produced by
`primitive_call_element`/`array_element_handle` (`backend_lower.bend:386-448`).
JS ignores `types` entirely (`operation` drops the field). Therefore a wrong or
missing element descriptor is a C-target failure (`array_cell` returns
`CellFail`) but is invisible to JS; this asymmetry is reported as R-3.

- Status: **[N]** for the C precondition, **[O]** for a complete C array cell
  proof.

**C-6 (sharing and ownership).** `sharing_plan` (`c_backend_sharing.bend:2799`)
consumes only BIR facts. Its output `SharingPlan{hot, array_shared, forced,
note}` drives `CID_T` hot bits, `BLK_SHR`, and sealing. Obligations:

1. The plan must be a superset of the set of values whose runtime duplication
   is possible; under-approximation is unsound.
2. When facts are unknown, `forced` seals every constructor; this is the sound
   fallback and never a guess (`c_backend_sharing.bend:43-50`).
3. Fact inconsistencies (duplicate constructor key, constructor in no family,
   out-of-range projection, non-convergent fixed point, `DescriptorFailure`
   where the hot closure must read) are failures, not defaults
   (`c_backend_sharing.bend:68-74`).
4. Every semantic argument, stored field and returned value crosses its
   runtime boundary as one owned reference. The caller chooses move versus
   counted share from residual uses, not from the callee's formal quantity.
   Arguments are prepared once, in source order, before frame release or
   continuation transfer. Physical storage must not keep an already prepared
   owned argument a second time.
5. Branch alternatives have independent ownership states. A value used once
   in each mutually exclusive branch does not require a runtime copy.
   Synthesized continuations transfer owning roots and preserve projection
   provenance; they do not semantically consume the projected fields.
6. `Project` and the native array pattern projections
   (`PrimArrayLeft`, `PrimArrayRight`, `PrimArrayLeafValue`) are borrowed paths
   until a semantic consuming use. Observations and failed nested patterns
   leave the scrutinee intact. An affine field argument is not enough to
   justify detachment if a whole ancestor or overlapping path remains live.
7. At a permitted transfer, only selected boxed slots may be cleared, and
   only when every ownership ancestor is unique and non-static. Shared/static
   owners require counted sharing with source-wrapper writeback; raw words
   copy. Untouched siblings remain owned by the root until their own use or
   frame cleanup. Array halves may be consumed separately across continuations;
   taking one must not free the other prematurely.
8. Heap callables are affine runtime objects: `rfc_wrap` rejects `TAG_CLO`
   and `TAG_TSK` in `c_runtime.c`. A blanket `term_keep`, including one hidden
   in a tag-test temporary or an array-element copy, is not an ownership
   solution for a `Type` field. The sharing module's contrary closure comment
   is not runtime authority.

Sharing-plan mechanism: a monotone fixed point over demand/flow/closure facts
(`Fact`/`AState`, `1920-1960`; `s_plan_from_facts`, `2796-2800`). The header
documents deliberate conservative departures from the reference emitter
(`c_backend_sharing.bend:51-67`).

Status: **[N]** for the superset direction; **[O]** for a soundness proof and
for "superset" in the presence of foreign values (the plan keeps foreign
declaration cids cold and relies on the twin's constructor hot bit; that is a
documented assumption; `tests/io/foreign_shared.c` is cited by the module as
the measured case, but no matching receipt was read here).
The frame/path obligations in items 4–8 are normative requirements, not a claim
that this fixed point implements them. Their C implementation and guarded
behavioral acceptance remain **[O]**.

**C-7 (SHOW).** For a pure executable, `Phys.show_build` derives a flat
`SHOW_DESC` word array and `SHOW_NAMES` from the normalized main type and the
declared families/layouts (`c_backend_physical.bend:1118-1130, 1727`). The
descriptor uses the same word offsets as storage; a boxed Data reads its arm
from a `Term`, an inline Data reads a leading tag word, and field offsets
advance by the field's laid-out word count. An erased field refuses the build.

Status: **[N]**, **[C]** for the refusal. **[P]**
  `evals/physical_show_smoke.bend` defines a descriptor/names fixture and the C
  smoke defines a pure `U32` main; no receipt was read. **[O]** for
  byte-for-byte equality with the JS `$show_value` over the whole language.

**C-8 (library ABI).** A `Library` ending publishes a renderer-owned export
table. Every export runs through the ordinary task/segment path, one BOX `Term`
per argument and result. Modes (documented at `plan_library`,
`c_backend.bend:506-515`; constructed at `export_direct`/`export_symbol_item`,
`531-567`):

- mode 0: call the entry exactly;
- mode 1: evaluate the declaration and apply every argument (zero-arity or lazy
  factory re-evaluates on each call);
- mode 2: call the entry's parameters, then apply the remaining host arguments
  in order.

A declared arity above the checked parameter count fails closed. Status: **[N]**,
**[C]**. **[P]** `evals/c_backend_library_smoke.bend` defines direct,
extra-argument, zero-arity, lazy, and lazy-closure-factory exports; its harness
would run them, but no receipt was read.

### 6.4 JavaScript/C correspondence

**TL-3.** J and C are two renderings of one BIR semantics. The normative
statement is: for an admissible B, target-appropriate foreign sources, and
related ξ, the JS and C sets of complete behaviors and finite prefixes
correspond under `≈_obs` (§1.3) — matching finite events and values, matching
error class, and `Diverge` with corresponding infinite visible traces.
Termination of either side is not required, and `show` text alone is not the
relation (especially for library callables).

This is **not** established:

- JS and C share lowering and BIR, but not an evaluator: JS is a direct
  big-step/trampoline interpreter over the emitted closures; C stages calls into
  segments with explicit continuation nodes and reference counting. Agreement
  is an implementation claim, not a consequence of sharing BIR.
- There is no cross-target differential gate in this tree. `gates/selfhost.ts`
  compares stage-0 vs stage-1 on runnable tests per lane (JS lane vs native
  lane) and against `#|` lines; it does not compare the JS and C outputs of the
  same BIR program against each other. The C and JS smoke fixtures build
  similar but not identical hand-written BIR programs.
- The representation gap is real: JS has one uniform value representation; C
  has canonical `Term` versus laid-out storage with Fill/Unfill, reference
  counted sharing, and numeric CIDs. Agreement therefore depends on C-2/C-3
  and C-6, each with open proof obligations.

Status: **[N]** as an obligation; **[O]** as evidence. Do not cite the shared
generated engine, the shared lowering, or the stage-0/stage-1 gate as proof of
TL-3.

### 6.5 Evidence ledger

This document's preparation ran **no** build, emitter, gate, or fixture. A row
is therefore marked **procedure** when the source only defines a check, and
**receipt** when a read artifact records an actual run with pinned hashes.

| Evidence | Kind | What it defines or records | What it does not establish |
| --- | --- | --- | --- |
| `evals/c_backend_smoke.bend` + `evals/c_backend_step_smoke.ts` | procedure | The fixture is a hand-written BIR executable (direct call, capture closure, runtime-applied closure, lazy nullary read, non-tail continuation); the harness writes the rendered C to `/tmp`, invokes clang, runs it, and requires `26` (`:37,150-156`). | That the procedure was run at 943de390; lowering preservation, other constructors, arrays, effects, overflow, ownership. |
| `evals/c_backend_library_smoke.bend` + `evals/c_backend_library_run.ts` | procedure | A hand-written `BIR.Library` with direct, extra-argument, zero-arity, lazy, and lazy-factory exports; the harness links the C caller and requires `export ok`. | A receipt for this base; JS export parity; general host argument types. |
| `evals/clay_layout_smoke.bend` + `evals/clay_layout_step_smoke.ts` | procedure | Specific value/node layouts, packedness, offsets, and Fill/Unfill plans. | Fill/Unfill identity for all layouts; a run at this base. |
| `evals/physical_show_smoke.bend` + `evals/physical_step_smoke.ts` | procedure | A SHOW descriptor and names for the fixture's types. | Byte equality with JS `$show_value`; a run at this base. |
| `evals/descriptor_nf_smoke.bend` + `evals/descriptor_nf_step_smoke.ts` | procedure | The expected NF outcomes listed in §5.3 and the run procedure. | NF/JS-evaluator equivalence, idempotence, completeness; a run at this base. |
| `evals/descriptor-nf-step-smoke-receipt.json` | receipt (stale) | Records 33 assertions and all-ones observed bits for `descriptor_nf.bend` sha256 `79591089...` (commit `0e0f1fe4`). | The current module: 943de390 hashes `747dc747...`; the receipt does not authenticate this revision. |
| `gates/selfhost.ts` | procedure | Stage-0 vs stage-1 comparison per lane (JS lane, native lane), `#|` expectations, and `#|!c`/`#|!js` missing-target diagnostics. | A run at this base; JS-vs-C agreement for one program; semantic preservation of lowering. |
| `tests/io/foreign_shared.c` (cited by `c_backend_sharing.bend`) | source fixture | The sharing module cites it as the foreign-sharing measured case. | A run receipt; general foreign sharing safety. |

### 6.6 Determinism, coverage, and the chunked driver (G1, G2, K5)

These three checkpoint laws are not semantic laws about BIR values; they
constrain how the pipeline is produced and driven. Their BIR-side content is:

**G1 (determinism).** For a fixed F and fixed foreign bytes, `lower(F)` is a
deterministic function: it allocates ids from a monotonically increasing
counter, accumulates definitions and codes in source order and reverses each
list once at the end (`definitions`, `lower_complete`), and uses `Map` only for
lookup, never for output order. Both target renderers likewise derive output
order from BIR lists (`entries_ascending`, `cid_rows` over the constructor
list, JS `codes`/`declarations`/`families`/`type_functions` in BIR order); maps
(`by_code`, `by_key`, `fid_macros`, sharing `hot`) are consulted by key only.
Stage1/stage2 byte identity is a property of the whole compiler and its
receipts, not something this document proves.

**G2 (acceleration does not weaken admission/coverage).** Every
`Catalog.Definition` yields exactly one `BIR.Declaration`; an ordinary
definition with a checked term body also yields exactly one `Code`. A type-only
definition yields no runtime declaration by design
(`definition_local`, `backend_lower.bend:1752-1760`); native, foreign, and law
definitions yield their corresponding declaration without a code.
No other checked definition may be dropped. Any lowering failure produces
`LowerFailure` and no program; it must not be papered over by a stub. The
targets render every code and declaration or return a diagnostic. The gates'
admission policy (which fixtures must pass, span debt, resource limits) remains
in the gates and receipts, not in BIR.

**K5 (chunked `Run`/`Stack` driver).** The current optimizer/driver executes
emission in generated chunks with an owning `Run`/`Stack` protocol. That
protocol is compiler control, not a BIR form: `Run`, `Stack`, `Progress` do not
appear in `BIR.Program` and must not be observable by a target. The BIR-side
obligation is interface preservation:

1. a chunked entry computes the same `BIR.Program` as the direct
   `BackendLower.lower` call for the same F and foreign inputs;
2. a chunk boundary must not change any BIR field (it may only suspend and
   resume the computation);
3. the rendered target is the same as rendering that program directly
   (TL-2).

The typed Stack invariant, its one-unit-per-transition fuel, and the
`Pending`/`Direct`/`Bound` behavior are obligations of the generated driver;
they are stated in `checkpoints/SELFHOST_IR_ARCHITECTURE.md` §4 (K5) and
recorded in the step receipts, and are **not** re-proved or re-measured here. K5's fuel
accounting is also not a substitute for O-1..O-6.

Status: **[N]** for the BIR-side statements; **[O]** for a proof that the
generated chunked driver realizes them. The step receipts
(`checkpoints/emitter-steps-v1.json`, `checkpoints/template-steps-v1.json`,
`checkpoints/checker-core-steps-v1.json`) are driver artifacts, not BIR proofs;
the descriptor-NF receipt is listed separately in §5.3 and pins a different NF
revision.

## 7. Open proof obligations

Ordered by what they block. None is discharged here.

- **O-1 (WF preservation).** BL-1: prove that every `Lowered(B)` satisfies §3.
  Sub-obligations: code/local/capture freshness, block totality, constructor
  metadata agreement, foreign metadata. No validator exists to check it at
  build time.
- **O-2 (descriptor normalization agreement).** §5.4: prove
  `descriptor_nf`'s reduction relation agrees with the JS runtime's `$type`
  evaluator for all descriptors BIR can contain, and characterize when
  normalization is idempotent. Current evidence is one fixture and a receipt
  that pins a different NF revision; no matching receipt exists for this base.
- **O-3 (evaluation order).** BL-8: determine the reference semantics' order for
  independent strict operands, then prove lowering preserves it. Today the
  target-fidelity half is true by construction; the source-fidelity half is
  unproved. This matters only for operands whose evaluation performs an effect
  (mostly foreign requests and IO construction), so the practical exposure is
  narrower than "all expressions".
- **O-4 (C layout/fill-unfill).** C-2/C-3: prove the Fill/Unfill identities for
  all layouts, including packed nodes, nested datatypes, arrays, `Bool` tag
  words, and abstract types boxed as one Term. Separately exercise borrowed
  Bool/Char views through fields and array cells: the scalar result must agree
  with the canonical value without consuming or changing its stored source.
  The law-document base has structural inspection and fixture procedures,
  not a general identity or borrowed-view proof.
- **O-5 (C sharing soundness).** C-6: prove `sharing_plan` never under-approximates
  duplication, including through foreign values and the `forced` fallback. The
  module documents where it intentionally differs from the reference emitter.
- **O-6 (JS/C observation agreement).** TL-3: a real cross-target differential
  over a bounded but representative corpus under `≈_obs`, including divergence,
  error class, effect traces, and library callable behavior. A show-text
  differential (or unrelated nondeterministic runs) is insufficient. No such
  gate exists today.
- **O-7 (source observation semantics).** §1.3 defines the *shape* of the
  relation (finite/infinite traces, error class vs payload vs exact text,
  library interactions, oracle-relative foreign effects) from the reference
  runtime's behavior (`io_exit`, `show_val`, `MAIN_PURE`). The precise
  source-semantics definition — including which error payload/text is
  observable, partial output before a failure, `unsafe`/divergent behavior,
  and host resource-limit outcomes — belongs to the source-semantics document
  and is not fixed here. This document does not claim the full relation.
- **O-8 (chunked driver equivalence).** §6.6/K5: prove that each generated
  chunked entry computes the same `BIR.Program` as the direct `lower` call for
  every F, including suspension at code-closure and declaration boundaries, and
  that no BIR field depends on chunk boundaries. The step receipts record driver
  runs; they are not this proof.
- **O-9 (primitive agreement).** BL-17/B1: a per-primitive differential between
  the JS runtime helper and the C implementation/runtime, covering overflow,
  shifts, float bits/NaN/signed zero, Unicode and empty strings, and array
  bounds/ownership. The only primitive value scenario defined by the C smoke
  fixture read here is `U32.add`; the layout/show fixtures and any pending
  FIRAcceptance matrix are separate evidence and are not claimed to fill this
  gap.
- **O-10 (value representation relation).** §1.3/`≈_τ`: define and justify the
  per-type relation between source values and JS values/C `Term`s, including
  closures, arrays, foreign values, erased/dependent positions, and the C
  Fill/Unfill storage boundary. This relation underpins TL-1/TL-3 and is not
  proved by sharing BIR.


## 8. Reported discrepancies and asymmetries

These are observed by reading the code, not invented resolutions. None is
fixed here.

- **R-1 (`Undefined` has two renders).** `BIR.Atom.Undefined` renders as
  `undefined` in JS (`js_backend.bend:442`) and `0` in C
  (`c_backend.bend:1160`). The current lowering never produces it (the only
  producer in the tree is the sharing analysis's internal default,
  `c_backend_sharing.bend:2228`), so no program is affected today. If it ever
  becomes a canonical atom, §WF/§TL-3 would be violated. Treat it as an
  internal sentinel, not a program value.
- **R-2 (foreign/constructor key collision check is JS-only).** JS's `link`
  rejects a foreign request key equal to a constructor key
  (`js_backend.bend:82-97`). C has no equivalent check; a collision would produce
  two `CidRow`s with the same key, and `cid_lookup` resolves to the first
  (constructor) row (`cid_rows`/`cid_lookup`, `c_backend.bend:958-1006`).
  This is reachable only with hand-built/malformed BIR or a producer bug:
  canonical definition and constructor keys are distinct namespaces in accepted
  source. It is a missing defense-in-depth check, **not** a demonstrated
  consumer bug on valid input.
- **R-3 (`PrimitiveCall.types` is C-only).** Array primitives require one
  element descriptor for the C cell plan (`CLay.array_cell`,
  `c_backend_layout.bend:1098-1116`); JS ignores `types`. A hand-built BIR with
  a wrong element descriptor can therefore render successfully in JS and fail
  only in C. This is WF-3/BL-11's "descriptor fact must be exact" obligation,
  enforced on one target only.
- **R-4 (duplicate declaration keys).** C takes the first declaration
  (`find_declaration`, `c_backend.bend:1178-1191`); JS assignment is last-wins
  (`declarations`, `js_backend.bend:972-975`). Checked source rejects duplicate
  definitions, and WF-15 makes duplicates ill-formed, so this is outside the
  producer domain. It is a divergence only for hand-built/malformed BIR, not a
  consumer bug on valid input.
- **R-5 (main-type provenance differs from foreign/export descriptors).**
  Foreign and export descriptors are normalized at catalog build; the main type
  is stored unnormalized and normalized by each target. Both targets normalize
  before use, so this is not a semantic mismatch today, but it means "every
  stored descriptor is already normal" is false and must not be assumed by a
  future consumer.
- **R-6 (no BIR validator).** Several well-formedness clauses are enforced by
  neither the types nor the targets (WF-1 duplicates, WF-2/3 scopes, WF-5 label
  uniqueness, WF-10 agreement between numeric and string metadata, WF-15). A
  hand-built program or a producer regression can reach code generation. This
  is a structural gap, not a known miscompile.
- **R-7 (primitives are implemented twice).** B1 is discharged by two
  independent implementations: JS runtime helpers selected by
  `primitive_name`/`primitive_public`, and C expressions/runtime helpers built
  by `prim_part`. No gate read here compares them primitive by primitive, and
  the C executable smoke fixture's only primitive value scenario is `U32.add`.
  This is an open coverage gap under TL-3/BL-17, not an observed mismatch.
- **R-8 (executable-mode admission of a source without `main`) — boundary gap,
  not an established bug.** `Catalog.ending` returns
  `Executable{DescriptorNull}` when no `main` descriptor was found
  (`lower_catalog.bend:1425-1433`). The driver always calls `lower`
  (executable mode, `driver.bend:126`), so a module compiled in executable mode
  without `main` reaches this state. JS's `js_main` guards on
  `Object.hasOwn($D,"main")` and, when absent, emits a program that produces no
  output and exits 0 (`js_backend.bend:1193`). C's `entry_main` fails with
  "the C target has no root main definition" (`c_backend.bend:2626-2637`).
  This is **not** a demonstrated counterexample on an accepted executable
  input: whether a module without `main` is a valid executable is a
  source-language/CLI contract question, and no check exists at the FIR/BIR
  boundary. If executable mode requires `main`, the missing check belongs to
  the CLI/FIR boundary; if a mainless module is a valid executable, the two
  targets disagree under TL-3. Reported for admission review, not as a
  confirmed consumer bug.
- **R-9 (`Failure.message` dropped in C) — possible mismatch only under
  exact-text observation.** JS renders `BIR.Failure{message}` as
  `throw "<message>"`, so the text can reach stderr
  (`js_backend.bend:645-654`). C's `block_ctl` passes only the context to
  `failure_ctl`, which emits `err_post(e.mem, ERR_TAGS); return 0;` and never
  reads `message` (`c_backend.bend:2212-2231`). Control behavior (fail-stop)
  agrees. If the observation of an error is its class (success vs failure),
  this is not a violation; if exact stderr bytes are observable for a checked
  program that reaches `BIR.Failure`, it is. The checkpoint's `Obs` includes
  error but does not fix text granularity; O-7 must decide. Not claimed as a
  bug here.

## 9. What this document does not claim

- No mechanized proof of any law stated here, and no Lean development in this
  work. The scope of that statement is the selfhost FIR → BIR → JS/C pipeline;
  the separate core theory in `bend2/bendtt.lean` is neither used as evidence for
  these laws nor denied by this document.
- No universal termination, productivity, or effect-order result. Divergence
  preservation is stated as a trace-set obligation, not as a termination
  theorem.
- No full definition or proof of the observation/representation relation
  `≈_obs`/`≈_τ`; §1.3 fixes its shape (complete behaviors, finite-prefix
  closure, `Diverge` with visible traces), and O-7/O-10 leave the full relation
  open. Finite fixture observations are partial evidence, not the relation.
- No equality of allocation addresses, allocation counts, RSS, stack depth,
  timing, or GC schedule; those are not observable. Logical ownership is a
  separate obligation.
- No semantic PASS/FAIL verdict from a host resource-limit abort; it is a
  tooling outcome outside the trace relation.
- No equality of unrelated nondeterministic foreign runs, and no reduction of
  library behavior to `show` text. The relation is oracle-relative and
  callable-behavioral.
- No completeness of the `Primitive` catalog, native marker sets, or the
  descriptor evaluator over the whole language.
- No equivalence between `descriptor_nf` and the JS runtime evaluator beyond
  the cases listed in §5.3 (which are not a matching receipt for this base).
- No claim that passing typecheck, the smoke fixtures, the selfhost gate, or
  the generated-composition dedup proves semantic preservation. Each is
  evidence of a specific mechanism only.
