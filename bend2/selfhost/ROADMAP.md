# Bend selfhost roadmap

Persistent backlog for the current integration line (`work/fir-ir-integrated57ab`,
actual HEAD `2fcdbaea`; source analysis baseline `f46ad0f6`). This file is
the short index of work; detailed evidence and reasoning live in the linked
notes. It does not replace a receipt.

**Status legend**

- `[ ]` pending; not done.
- `[x]` done for the named deliverable only. A written, reviewed and committed
  doc/research note may close a **writing/research** deliverable. It never
  closes a behavior, proof, acceptance, or implementation deliverable; those
  need their own receipt. A prose note alone closes nothing behavioral.
- `[ ] **in progress**` actively being coded or in review; no completion claim.
- `[M]` measured receipt; `[P]` procedure/fixture without a matching read
  receipt; `[O]` open obligation; `[N]` normative requirement.

Rules: no timing promises before a measurement; no green mark based only on a
document; a clean full build remains the reference; profiling must never change
roots, retention, codegen, or output; no heavy run is implied by this file.

User-approved scope recorded here: **profiling implementation is the active
priority**; **future incrementality work is approved only as tasks, not as cache
implementation**; **WASM/WASI, GPU, LLVM, MLIR and Zig remain research only**. The
checklists below are the backlog, not a commitment to a particular cache,
query framework, arena redesign, or backend cutover.

---

## 1. Current recorded state (status, not acceptance)

Some rows are real receipts with exact paths; some are commit-message or
Main-scoped facts. A receipt's existence is not acceptance: its recorded status
is named. Where this note did not verify a record, it says "scope not verified
by note". A JS-generated report is not a native artifact receipt.

| Workstream | Recorded state | Evidence | Remaining |
|---|---|---|---|
| Parser acceptance | `PARSER_ACCEPTED_NATIVE_SEMANTICS`; source gate 71 rows, candidate gate 75 rows; 13 export names | `/private/tmp/bend-fir-integrated57ab/checkpoints/bootstrap-parser-rebuild-ir57ab-sharedem-a.result.json`; gate config `...candidate-gates-v1.json` | keep the receipt current; no parser change without a new run |
| FIR check / root + body report | body facts are the same report's `checkedDefinitions` / `liveBodies` / `nativeCheckedBodies`; 11,134 checked definitions, 11,134 live/native checked bodies, 0 excluded, 0 output patches; source `b0b92b67225c1b67972c9fe2a1096962a14926633508936c86d8b93b73cbd36b`, artifact 16,789,267 B, artifact sha `fcd8cca2d566ad80591a74d0000d60eb14c5e82e2427bd28917ea07ecc4cb4d6`; status `JS_GENERATED_NOT_YET_EXECUTED`, `compiledExecution: NOT_RUN`, `selfhostGreen: false`; guardian PASS, peak RSS 3,193,372,672 B / footprint 3,275,034,072 B | `/private/tmp/bend-fir-integrated57ab/checkpoints/root-sharedem-rep.result.json`, `.worker-result.json`, `.guardian.json`, `.metrics.json` | native artifact + execution, not another JS-generation rerun of unchanged source |
| Full-body component build | 11,134 checked definitions; artifact 16,789,267 B; `checksExcluded 0`; `outputPatches 0`; root `b0b92b67`, manifest `13088d4c` | same `root-sharedem-rep.result.json`; commit `943de390` | native codegen/run; the report already records the JS component build |
| Shared emitter composition | one generated `emitter_steps_v1.bend`; 2,652,534 B / 3,283 top-level defs (was 3,615,353 B / 4,394 across two modules); module `book_valid` 4,848 events / 4,516 defs / 4,408 checked bodies, 0 holes | commit `9db035a9` | full-root native receipt after the cutover |
| BIR lowering / native bridge | bridge drives the one `Emit` engine; 13 public names/arities unchanged; `book_load` + `book_valid`: 11,721 events, 11,164 definitions, 11,164 checked bodies, 0 holes; no codegen run | commit `7dc1ab92` | full 13-root BIR→C emission and run |
| C lane | C steps tag gate passes and reaches emission; stops in the known `Base String.split` non-tail recursion at artifact line 221913 | commit `6700988b` | resolution inside the checked linear subset; full C artifact and run |
| JS lane | `candidate_host` over the frozen root-sharedem artifact: 291,402 bytes / sha256 `43d9e28e` for `tests/run/bang_call.bend` | commit `6700988b` | broader JS acceptance receipt for the agreed corpus |
| Full native build, NO_TRACE joint control | `ABORTED_NO_TERMINAL_REPORT` — **not** an OOM: dead PIDs, guardian report 0 bytes, last recorded `compile_book` start; exact kill cause unobserved; launcher had a 1200 cap but no exit record | Main-scoped control; no terminal report path available to this note | guardian lifecycle fix before interpreting this control |
| Guardian lifecycle | fix written at `328cac5d` + `317b38a6` (detached supervisor, overwriting terminal receipt, no timer-based lease release; the reviewed 5 s release branch was removed as unsafe and the lease is held until owned children are confirmed gone); evidence `524aca64`; reviewed; awaiting intake. `heavy_gate.test.ts` 12 pass / 0 fail. One transient deadline-test failure was observed once and not reproduced in 9 later runs; it remains an unlocalized risk and is not outvoted. | commits `328cac5d`, `317b38a6`, `524aca64` (branch; not in integration) | intake; flake disposition; re-run `NO_TRACE` under the fixed lifecycle |
| Official TS producer / full native build, traced | 11,164 native-bridge bodies; book heap 1,669,811,048 B; reaches pass 6; OOM; no native artifact | Main-scoped traced run; scope not verified by note | per-structure decomposition; native artifact within the guard |
| Profiling (actual code) | **ProducerProfilingImpl** wrote opt-in scoped compiler profiling at `60f20a` (plan/report/smoke) with tiny smoke; **StageProfilingImpl** wrote opt-in stage profiling at `72ed7ab0` (candidate host + bootstrap worker + report) with tiny smoke. Both are in review, **not in integration**. | commits `60f20a`, `72ed7ab0`; smoke receipts on those branches | review/intake; A/B no-output-change; per-module bytes; full-root overhead remains OPEN |
| Law documents | `FIR_LAWS.md` and `BIR_LAWS.md` are written, reviewed, integrated at `2fcdbaea`, and linked from `ARCHITECTURE.md`; seven written law tasks CLOSED; proof/behavior obligations remain OPEN | `6a7cfc59`/`4417d18a` (FIR), `0695e763`/`8311d6a4`/`2f0e8d3b`/`2fcdbaea` (BIR) | obligation triage; no behavior/proof acceptance |

Table entries are status, not acceptance checkboxes. The current full root
remains pending; a doc-only change to this tree does not justify rerunning an
unchanged source.

---

## 2. P0 — active implementation

Owners: **NativeSeedBootstrap** (guardian lifecycle), **ProducerProfilingImpl**
(official TS producer), and **StageProfilingImpl** (selfhost pipeline). These
are implementation workstreams, not research notes. None is complete.

### 2.0 Guardian lifecycle — NativeSeedBootstrap

The `NO_TRACE` joint control returned `ABORTED_NO_TERMINAL_REPORT`: dead PIDs, a
0-byte guardian report, and the last recorded `compile_book` start. That is not
an OOM result; the exact kill cause is unobserved, and the launcher's 1200 cap
left no exit record. Long acceptance runs must not be interpreted until the
guardian lifecycle is fixed.

Files owned by NativeSeedBootstrap:
`evals/heavy_gate.ts`, `evals/heavy_gate_native.c`,
`evals/heavy_gate.test.ts`.

Status: code written and reviewed at `328cac5d` + `317b38a6`, with evidence at
`524aca64`; **awaiting intake, not in integration**. The review removed the
unsafe 5 s timer-based lease release; the lease is held until owned children are
confirmed gone. The launcher-group-kill regression passes, and the full suite
reported 12 pass / 0 fail. One transient deadline-test failure was seen once
(its assertion detail was not retained) and not reproduced in 9 later runs;
that unlocalized flake remains a risk and is not outvoted by repeated passes.

- [ ] Always write a terminal report on normal exit, signal, launcher cap, and
  forced kill; a 0-byte report is a defect. (Implemented at `328cac5d`; pending
  intake and a fresh control receipt.)
- [ ] Record the launcher cap event and the child exit/signal in the same
  receipt, so timeout vs kill vs OOM vs abort is distinguishable.
- [ ] Ensure no dead PIDs are left after a control returns; reap every child and
  record its status.
- [ ] Make `ABORTED_NO_TERMINAL_REPORT` either impossible or an explicit
  non-success with a terminal report and the observed cause.
- [ ] Add tests in `evals/heavy_gate.test.ts` that simulate a cap hit, a killed
  child, and a 0-byte report path, and assert the terminal receipt.
- [ ] Do not release the lease on a timer while an owned descendant may still
  be alive; a stuck descendant keeps the lease and a receipt. (Implemented at
  `317b38a6`; pending intake.)
- [ ] Re-run the `NO_TRACE` joint control only after the lifecycle tests pass;
  record it as a control, not as an OOM or a green build.
- [ ] Resolve or explicitly disposition the unlocalized deadline-test flake;
  repeated passes do not outvote the observed failure.
- [ ] Intake `328cac5d` + `317b38a6` and `524aca64`, then mark this section
  green. No long acceptance run is attempted before that.

### 2.1 ProducerProfilingImpl — official TS producer

Goal: explain the official producer's cost and memory composition well enough
to distinguish Book retention, stable fact-store growth, current-pass segments,
and per-definition scratch, without changing what the producer emits.

Status: code written at `60f20a`, tiny smoked; **in review, not in
integration**. Includes
`bend2/selfhost/COMPILER_PROFILING.md`, `evals/compiler_profile.mjs`,
`evals/compiler_profile_smoke.ts`, and
`checkpoints/compiler-profile-smoke-v1.json`. The checkboxes below are
acceptance, not writing.

Deliverables:
- [ ] Stage receipts for `module-import`, `book_load:root`, `book_load:bridge`,
  `book_valid`, `compile_book`, `c-publication`, with wall/CPU and process heap
  at each boundary; reuse `progress()` and the existing `--trace-c` event names
  rather than inventing a parallel logger.
- [ ] Per-pass rows for facts (`own`/`hot`/`stat` sizes), `lend`/`spun`/`clos`/
  `tabs`/`lits`/`consts`/`brws` sizes, `segs`/`spins`/`img` sizes, memo sizes,
  and `retainedHigher`; identify the structure that grows at pass 6.
- [ ] Byte accounting for Book, stable FL facts, current-pass segments, and
  one-definition scratch, with the method stated (exact counters vs sampled
  snapshots vs `heapUsed` minima). If only `heapUsed` minima exist, label them
  "lowest observed process heap after reported drops; GC type and retained-byte
  provenance unobserved".
- [ ] A pinned report under `checkpoints/` naming source/compiler hashes, the
  corpus, the guard, and the exact OOM boundary.
- [ ] Negative control: profiling off vs on produces byte-identical C output
  and the same roots/retention/codegen behavior.

Acceptance:
- [ ] The pass-6 OOM report names which component grew by how much, or states
  explicitly that it cannot attribute retained bytes and why.
- [ ] No guard is relaxed, no heap limit raised, no roots/checked-body retention
  changed to make attribution easier.
- [ ] The report separates "Book already retained at `book_valid` completion"
  from "codegen pass working set".
- [ ] A reader can tell why frontend caching would or would not change the OOM
  composition, without a causal claim the data does not support.

### 2.2 StageProfilingImpl — selfhost pipeline

Goal: per-stage and per-module CPU/memory facts for load → parse → expand →
check → catalog → BIR → render → link, sufficient to size (or reject) the
incremental workstreams in §6.

Status: code written at `72ed7ab0`, tiny smoked; **in review, not in
integration**. Includes `bend2/selfhost/RESEARCH_STAGE_PROFILING.md`,
`evals/compiler_stage_profile.mjs`, `evals/compiler_stage_report.mjs`,
candidate-host and bootstrap-worker entry points, and
`checkpoints/compiler-stage-profile-v1.json`. The checkboxes below are
acceptance, not writing.

Deliverables:
- [ ] One optional stage/profile mode with phase boundaries matching
  `Loader.load`, `Template.expand`, `Checker.check`, `Catalog.build`,
  `BackendLower.lower`, JS/C render, and foreign/link reads.
- [ ] Per-module rows: source bytes, declaration count, parse wall/CPU, expand
  wall/CPU, check wall/CPU, arena watermarks (nodes/patterns/binders/words/
  naturals/names at module start/end), and generated-instance counts.
- [ ] Per-definition timing only where it is trustworthy; label GC-polluted
  deltas as such instead of attributing retained bytes.
- [ ] Catalog/BIR/render sizes and times; descriptor-NF call counts; type-
  function/family/constructor table sizes; `next_code`/`next_constructor`
  finals.
- [ ] Cache-relevant counters: modules/definitions checked vs reused,
  invalidation reasons, arena growth per recheck (once an incremental mode
  exists; zero before that).
- [ ] A pinned report under `checkpoints/` for the current integration tree,
  naming source/compiler/image hashes and the exact corpus.

Acceptance:
- [ ] Clean target output is byte-identical with profiling on and off (JS and C
  where both lanes run).
- [ ] Phase totals reconcile to the guarded process wall; no hidden child work.
- [ ] Memory rows state scope (process RSS vs isolate heap vs arena counts) and
  never present process heap as per-module retention.
- [ ] The report answers: which stage dominates, which module(s) dominate, and
  whether module-sized cache units are economically plausible.
- [ ] No production output, parser, kernel, or admission change.

### 2.3 Profiling cross-cuts

Native fine/stage current-component followups are active; **full-root overhead
attribution remains OPEN**.

- [ ] Review `60f20a` and `72ed7ab0`; intake only after review and an A/B
  no-output-change check.
- [ ] Every receipt distinguishes `[M]` measured, `[P]` procedure, `[O]` open.
- [ ] Every number names its pin; stale pins are marked stale, not reused.
- [ ] No new timing constant or performance claim enters docs without a receipt.
- [ ] All active workstreams keep the clean build runnable with profiling and
diagnostic hooks disabled.

---

## 3. FIR / BIR / C acceptance backlog

Detailed contracts: `FIR_LAWS.md`, `BIR_LAWS.md` (pending integration), and
`RESEARCH_INCREMENTAL.md` for the reuse implications.

### 3.1 FIR

- [ ] Use the existing pinned root/body report
  `/private/tmp/bend-fir-integrated57ab/checkpoints/root-sharedem-rep.result.json`
  (source `b0b92b67225c1b67972c9fe2a1096962a14926633508936c86d8b93b73cbd36b`, 11,134 checked/live bodies, 0 excluded, 0 patches)
  and the parser receipt
  `.../bootstrap-parser-rebuild-ir57ab-sharedem-a.result.json`. Re-run only if
  the source or compiler pin changes; a doc-only change does not justify a new
  run. Record any new receipt under `checkpoints/` with the same pin detail.
- [ ] State that the existing root report is `JS_GENERATED_NOT_YET_EXECUTED`,
  not a native execution; do not upgrade its status from the report's fields.
- [ ] Every term-bodied definition has `checked = Some{occurrence}` on success;
  missing-body failure is exercised by a negative test.
- [ ] Failure path: a diagnostic is emitted in a defined order and no partial
  publication escapes; test a failure after some declarations were published.
- [ ] Readback is non-authoritative: a test proves readback cannot feed
  lowering or change semantics.
- [ ] Module/metadata pairing and dependency-order input are checked or
  explicitly documented as an obligation (FIR_LAWS O-7).
- [ ] No transient-derived handle escapes through the memo/case-prefix/
  `node_closed`/`node_bounds` lanes (FIR_LAWS O-2); at minimum, an audit plus a
  targeted test.
- [ ] Signature completeness/uniqueness for every reachable declaration
  (FIR_LAWS O-3).
- [ ] Occurrence adequacy for every current consumer (FIR_LAWS O-4), including
  child order and the deliberate absence of usage facts.
- [ ] FIR_LAWS reviewed, integrated, and linked from `ARCHITECTURE.md`.

### 3.2 BIR

- [ ] Full 13-root BIR lowering produces all expected declarations/codes/
  constructors/families/type functions with no `Preparation.failure`.
- [ ] A BIR well-formedness validator or an explicit receipt that WF-1..WF-n
  were audited; no claim of mechanized WF preservation.
- [ ] Descriptor-NF agreement fixture(s) under the current NF revision: a
  matching read receipt, not a receipt pinned to a different revision.
- [ ] Evaluation-order obligation (BIR_LAWS O-3) is either decided for the
  current effect surface or listed as an explicit open risk.
- [ ] C sharing soundness (O-5) and C layout Fill/Unfill (O-4) have either a
  proof argument recorded per case or a fixture receipt.
- [ ] BIR_LAWS reviewed, integrated, and linked from `ARCHITECTURE.md`; no
  semantic-preservation proof claimed.

### 3.3 C target

- [ ] Resolve the `Base String.split` non-tail recursion that stops C emission
  at artifact line 221913, using the checked linear subset (no bypass, no
  special case in the emitter).
- [ ] Full 13-root C artifact is emitted, compiled, and run under the existing
  guard; record the artifact hash, C source hash, and runtime receipt.
- [ ] C tag gate and shared-emitter `Emit` kind remain valid after the fix.
- [ ] Primitive agreement (BIR_LAWS O-9) at least for every primitive used by
  the accepted corpus, not only `U32.add`.
- [ ] Cross-target observation differential (O-6) over a bounded but
  representative corpus; a show-text differential alone is insufficient.
- [ ] Native artifact produced within the fixed 3072 MiB heap and the guarded
  envelope; pass count and peak recorded.
- [ ] Official producer pass-6 OOM is resolved or explicitly re-scoped with a
  receipt; no claim that frontend caching fixed it.

### 3.4 JS and shared lanes

- [ ] JS lane acceptance receipt for the agreed corpus, beyond the recorded
  `bang_call` smoke (291,402 B / sha256 `43d9e28e`).
- [ ] Both targets select foreign files only by declared extension and read
  exactly those bytes; missing target is a compile diagnostic.
- [ ] One checked program can drive both targets without silently sharing
  stale bytes; output/order determinism recorded.
- [ ] No AST/checked-body serialization or cache is introduced by acceptance
  work.

### 3.5 Evidence discipline

- [ ] `gates/selfhost.ts` two-lane fixture comparison (stage-0 vs candidate,
  `js` and `native`) is green for the agreed file set; the native lane actually
  builds and runs its C, not only emits it.
- [ ] The `NO_TRACE` joint control is re-run after the guardian lifecycle fix
  and produces a terminal report with a recorded exit cause; it is not treated
  as an OOM result.
- [ ] No long acceptance run is started before the guardian lifecycle tests in
  §2.0 pass.
- [ ] Every acceptance claim has a `checkpoints/*.json` (or equivalent) receipt
  with source, compiler, corpus, guard, and command.
- [ ] Commit messages may summarize but do not substitute for the receipt.
- [ ] A failed/partial run is recorded as `RESOURCE_LIMIT` or `FAIL`, never
  inferred as PASS from prose.

---

## 4. Law writing / review status

Both law documents are written, reviewed, integrated at actual HEAD
`2fcdbaea`, and linked from `ARCHITECTURE.md`. The **seven written law tasks
are CLOSED**. Proof and behavior obligations remain **OPEN**; a committed law
document closes the writing/research deliverable, never the behavior/proof
acceptance it describes.

### 4.1 FIR_LAWS.md

Status:
- [x] Written, reviewed, and integrated at `2fcdbaea` (intake commits
  `6a7cfc59`, `4417d18a`); linked from `ARCHITECTURE.md`.
- [x] Seven written law tasks closed.
- [ ] Proof/behavior obligations remain OPEN (below); no semantic-preservation
  proof is claimed.
- [ ] Triage O-1..O-9 into implementation checks, test obligations, or accepted
  risks with owners.

Recorded content: checked-FIR boundary, ownership/lifetime, arena publication
and handle identity, signatures/scopes/metadata, occurrences, failure and
inspection contracts, tags `[T]`/`[C]`/`[V]`/`[N]`. Open obligations O-1..O-9:
region closure; no escape through caches; signature completeness/uniqueness;
occurrence adequacy; type discipline; termination claim; module/metadata
pairing and input order; inspection non-authoritative; failure completeness.

### 4.2 BIR_LAWS.md

Status:
- [x] Written, reviewed, and integrated at `2fcdbaea` (intake commits
  `0695e763`, `8311d6a4`, `2f0e8d3b`, `2fcdbaea`); linked from
  `ARCHITECTURE.md`.
- [x] Seven written law tasks closed.
- [ ] Proof/behavior obligations remain OPEN (below); no mechanized
  semantic-preservation proof is claimed.
- [ ] Triage O-1..O-10 into implementation checks, test obligations, or
  accepted risks with owners.

Recorded content: BIR well-formedness, lowering laws, descriptor-NF laws,
target laws (JS/C), observation relation, tags `[N]`/`[C]`/`[P]`/`[M]`/`[O]`.
Open obligations O-1..O-10 include WF preservation, descriptor-NF agreement,
evaluation order, C layout, C sharing soundness, JS/C observation agreement,
source observation semantics, chunked-driver equivalence, primitive agreement,
and the value-representation relation. One NF receipt pins a different
revision and is marked stale.

### 4.3 Obligation work after the writing tasks

- [ ] For every `[N]`, decide: implement a check, add a test obligation, or
  record an accepted risk with an owner.
- [ ] For every `[P]`, either produce a matching read receipt or mark it
  explicitly unexercised.
- [ ] For every `[O]`, keep it open until a proof, a validator, or a named
  bounded differential discharges it; a document edit does not.
- [ ] Keep the documents out of the acceptance path: a law document is not a
  green gate, even when integrated.
- [ ] Update line pins and tags when the source moves; stale citations are
  defects of the document, not of the pipeline.

---

## 5. Backend research only (Zig, WASM/WASI, GPU, LLVM, MLIR)

These are research workstreams. A completed note is a research result, not a
backend cutover. No production target switch is authorized by this roadmap.

- [ ] `RESEARCH_ZIG_BACKENDS.md` reviewed: records the user-added comparison of
  an own Zig backend against the LLVM route; research only, no Zig dependency,
  target switch, or automatic cutover.
- [ ] `RESEARCH_WASM_WASI.md` reviewed: records one whole-program wasm module,
  not wasm object linking; identifies the stable-ID/table-ABI blocker for
  multi-module packaging.
- [ ] `RESEARCH_GPU.md` reviewed: distinguishes the legacy Metal/CUDA runtime
  feature from a new-pipeline GPU path; no new-pipeline GPU execution claim.
- [ ] `RESEARCH_LLVM.md` reviewed: whole-program BIR and one output module;
  numeric export ABI (`BEND_EXPORT_ENTRY[]`, `bend_export_call(i, ...)`) and
  per-program `CID`/`FID` rewriting documented as separate-compilation
  blockers.
- [ ] `RESEARCH_MLIR.md` reviewed: MLIR symbol tables are name-based, IR
  versioning is bytecode-only/opt-in; no id stability inherited from MLIR; no
  dialect or architecture commitment.
- [ ] Each note labels `[S]`/`[M]`/`[I]`, cites exact sources, and states what
  it does not prove.
- [ ] A backend cutover requires a separate design note, a stable-ID/table-ABI
  plan, and an acceptance suite; research review alone never triggers it.

---

## 6. Future incrementality backlog

Reasons, soundness traps, and acceptance scenarios are in
`RESEARCH_INCREMENTAL.md`; do not duplicate them here. Every item is future
work unless explicitly authorized later. All items are off by default and must
be byte-comparable to a clean build.

### 6.1 Parse / version cache

- [ ] Define the key: real path + exact source SHA-256 + parser/compiler/schema
  version + import-resolution inputs.
- [ ] Add a schema/compiler version constant; a missing or mismatched key is a
  miss, never a repair.
- [ ] Implement in-process reuse first; disk persistence only with an
  encoder/decoder round-trip.
- [ ] Equality tests: parsed module value equality, span equality, import list
  equality, diagnostic equality.
- [ ] Loader error paths (missing file, cycle, namespace conflict, package hash
  mismatch) still run and produce identical diagnostics.
- [ ] Cache off/on produces byte-identical targets and identical diagnostics.
- [ ] Stale-schema, wrong-compiler, renamed-path, and edited-file poison tests
  all miss.

### 6.2 Expansion / template dependencies

- [ ] Record per module: referenced template canonical keys, generated
  identities, and the module key list used for collision suffixes.
- [ ] Invalidate on: raw module change, any used template body/signature/import
  change, module key-set change, expander version change.
- [ ] Cover generated-generated instances and repeated rounds; no assumption
  that one round is enough.
- [ ] Generated key collision behavior matches clean; a collision remains a
  failure, never a silent rename.
- [ ] Cached vs clean expanded AST equality and target equality.
- [ ] Unused templates do not invalidate a module; a negative test proves the
  dependency set, not a global template hash.

### 6.3 Module checked-arena snapshots, lifetime, conservative reverse imports

- [ ] Add a resumable check entry; the existing clean `check_modules` path is
  unchanged.
- [ ] Snapshot unit: expanded module, checked module, that module's published
  globals, `ModuleMetadata`, and arena watermarks. No transient handle may
  escape.
- [ ] One source owner per session; no mixing of two arenas; no relocation by
  assumption.
- [ ] Conservative invalidation: changed module + transitive importers; Base
  dirties all; a public-surface change rechecks the whole module; a body change
  also rechecks the whole module in the first cut.
- [ ] Preserve loader/declaration order through catalog/BIR assembly.
- [ ] Failed checks are never green; retain only the last good prefix.
- [ ] Compaction/rebuild threshold so dead publications cannot grow without
  bound; a rebuild equals clean.
- [ ] Acceptance scenarios 1–10 from `RESEARCH_INCREMENTAL.md` §7 all pass,
  including body-used-in-type, datatype/quantity, aliases, spans, deletion,
  error→fix, foreign bytes, target/runtime change, and determinism.
- [ ] Admission checks (duplicate, signature, affine/quantity, termination,
  foreign signature) still run for every accepted artifact.
- [ ] Measured hit rate, recheck cost, and retained bytes are recorded before
  any finer granularity is attempted.

### 6.4 Fine semantic dependency keys (including bodies unfolded into types)

- [ ] Design a read-set journal covering every `Scope.lookup`/`lookup_kind`,
  global candidate enumeration, and every `whnf` unfold/beta of a global.
- [ ] Attribute reads to the definition being checked; store the set with the
  cached result.
- [ ] Stable result fingerprint across arena positions/sessions (structure +
  symbol keys/kinds + normalized facts; no raw handles).
- [ ] Red/green propagation: an unchanged signature with a changed body that is
  unfolded in a type must recheck dependents, including indirect alias chains.
- [ ] Occurrence symbols are not accepted as a complete read set; a test where
  normalization reads a global absent from the occurrence children must
  invalidate.
- [ ] No green without complete dependency evidence; audit every scope-read
  site and record exemptions.
- [ ] A negative test proves a signature-only key is rejected by the design.

### 6.5 BIR / render / separate compilation / runtime-foreign cache keys

- [ ] Design stable symbolic identities for code/constructor/family and
  link-time numeric assignment; no per-definition fragment cache before this.
- [ ] BIR key includes reachability, type-function set, descriptor-NF inputs,
  and normalized descriptor facts.
- [ ] Render key includes target, runtime bytes, foreign bytes, and the
  whole-program sharing/physical facts (or a proven frozen subset).
- [ ] C/JS clean-vs-incremental byte equality for the agreed corpus.
- [ ] Separate-compilation design note covers the runtime-table ABI split,
  numeric export indices, foreign objects, liveness/`Ending`, and deterministic
  link order; no implementation before review.
- [ ] A build-artifact cache (full fingerprint → final text) may be considered
  separately; it is not incremental compilation and must not be described as
  such.

### 6.6 Clean-rebuild equivalence gate (cross-cutting)

- [ ] Every cache mode has an off switch and defaults off.
- [ ] A clean build run twice produces identical target SHA-256 and diagnostics.
- [ ] Incremental after an edit sequence equals clean at every step (target
  bytes, diagnostics, exit status).
- [ ] Poison tests: stale schema, wrong compiler, missing dependency key,
  edited file, renamed path, target/runtime change, foreign byte change.
- [ ] No admission bypass: the cached path runs the same duplicate, signature,
  affine, termination, and foreign checks.
- [ ] Instrumentation/receipt records hit rate, recheck cost, and retained bytes
  with method and scope; no causal claim from `heapUsed` minima alone.

---

## 7. Non-negotiables

- A document, a plan, or a commit message is not an acceptance receipt.
- No false green: `RESOURCE_LIMIT`/`FAIL` stay visible; a narrowed corpus is not
  a pass.
- No cache may skip duplicate, signature, affine/quantity, termination, or
  foreign-signature admission.
- The clean full build remains the reference; incremental modes are opt-in and
  byte-comparable.
- Profiling must not change roots, checked-body retention, scheduling, or
  generated code.
- Backend research does not authorize a WASM/GPU/LLVM/MLIR cutover.
- No LLVM/MLIR switch, query framework, `Arena`/`CheckedProgram` redesign, or
  cache-format commitment is made here.
- Parser/kernel/original `comp.ts` changes require explicit scope; none is
  implied by this roadmap.

---

## 8. Links

- `ARCHITECTURE.md` — current selfhost parser/checker architecture and historical
  boundaries.
- `RESEARCH_INCREMENTAL.md` — incremental-compilation analysis, dependencies,
  invalidation, cache-memory limits, acceptance scenarios.
- `FIR_LAWS.md` — checked FIR boundary and obligations; integrated at
  `2fcdbaea`; proof/behavior obligations open.
- `BIR_LAWS.md` — BIR well-formedness/lowering/target laws; integrated at
  `2fcdbaea`; proof/behavior obligations open.
- `COMPILER_PROFILING.md`, `RESEARCH_STAGE_PROFILING.md` — profiling
  implementation docs on the `60f20a`/`72ed7ab0` review branches, not yet
  integration.
- `RESEARCH_WASM_WASI.md`, `RESEARCH_GPU.md`, `RESEARCH_LLVM.md`,
  `RESEARCH_MLIR.md`, `RESEARCH_ZIG_BACKENDS.md` — backend research only
  (drafts on sibling branches; integrate before treating these links as live).
- `RESEARCH_PROFILING.md` — profiling coverage research (sibling branch;
  integrate with the profiling implementation receipts).
- `checkpoints/SELFHOST_IR_ARCHITECTURE.md` — earlier F/L/B/G/K law
  obligations and IR architecture.
- `checkpoints/SELFHOST_HANDOFF.md` — historical implementation handoff;
  treat provenance accordingly.
- Profiling artifacts: `evals/selfhost-root-phase-profile-57ab.json` (pin
  `d47f859b`, diagnostic only), `checkpoints/compiler-profiling-quality-v51.json`
  (pin `7c33172b`), `checkpoints/book-phase-attribution.json` (older pins).
