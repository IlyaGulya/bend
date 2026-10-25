# Bend selfhost roadmap

Persistent backlog for the current integration line (`work/fir-ir-integrated57ab`).
Integration snapshot through `2faa3c77`; last candidate component `433aadb5`
contains the prior C producer and physical paths. Its source admission passes;
all 23 C cases fail emission. Detailed evidence and reasoning live in the linked notes. This index
does not replace a receipt.

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

Latest candidate: **`667e7f33`**, source-only Boolean fix integrated at
`8aefa052` (`c_backend 346f5b53`, physical unchanged `daf8a137`).
Fresh generation still checks all 11,860 bodies, with 0 exclusions/patches,
the same 13 exports and quantum 64. Both previously failing literal/projected
Bool.xor witnesses and all four truth-table rows now pass real emit/clang/run.
Receipt: `evals/receipts/bool_xor_fix_667e7f33.json`.
The full matrix is expanded, never narrowed, to 26 inputs by adding
`c_target_bool_xor`: **26/26 PASS**, all 78 emit/clang/run stages
complete/stopped/exit 0. Receipt: `evals/receipts/c_matrix_667e7f33_26.json`.
The same image also passes all three C/JS foreign fixture pairs and the real
six-export C-library route: 7 rows / 18 stages, all complete/stopped/exit 0.
Receipt: `evals/receipts/foreign_667e7f33.json`. Full compiler corpus, embedded
parser cutover, byte fixedpoint, native HOST and general laws remain open.

### Preceding `971e0986` checkpoint (historical)


The preceding all-body candidate was `971e0986`: 11,860 checked/live bodies,
0 excluded checks and 0 output patches. Its regenerated shared Emit includes
Control `83680e53` and physical renderer `daf8a137`. A real public-path
two-print program now passes emission, clang and execution (`a`, `b`).
The frozen **25-case C matrix completed with 23 PASS / 2 FAIL**. The rejected
tail-capture input separately passed after a syntax-only correction. The later
`667e7f33` Boolean fix does not reclassify this batch. These runs used accepted
external parser `0e7b3c42`; a measured public parse differential confirms that
the root's inline parser is still stale.
No current full-root fixedpoint or native HOST artifact is claimed.

| Workstream | Recorded state | Evidence | Remaining |
|---|---|---|---|
| Parser acceptance | Canonical quantity-binding repair integrated at `2a20074e`..`b2753368`; parser image `0e7b3c42`, canonical source `7389188a`. Full 600 s gate: 75 cases, 0 exclusions/patches; public regressions 15/15, 264 assertions. Actual public root parses still reject typed locals and `+` do binders accepted by the external parser; ordinary do and untyped controls agree | `checkpoints/parser-quantity-binder-qp57a-4-600s.receipt.json`, final gate `f9eb738b`; `REPRO_INLINE_PARSER.md`, intake `bcd6f171` | tree-local authenticated parser acceptance, typed-step regeneration and root composition; run the same public differential after cutover; no parser byte-fixedpoint claim |
| FIR check / full-body candidate | 11,860 checked/live/expected bodies from 12,421 validated events, 0 excluded / 0 output patches. Artifact `971e0986`, 17,918,636 B; guardian complete/stopped, 50,896 ms, peak RSS 3,050,291,200 B / footprint 3,177,616,080 B. Build admission and later C execution are separate receipts | `checkpoints/verify-836.receipt.json`, intake `6fa30d28`; Control `83680e53`, physical `daf8a137`; `evals/receipts/repro_inline57ab_verify_daf8.json` | complete frozen C/foreign/JS coverage, full 13-export fixedpoint, frozen corpus and native HOST |
| Shared emitter composition | Regenerated one Emit engine `46e6f749`, manifest `c14da6e5`; 2,020 canonical declarations. Generator code, public 13 exports and quantum 64 unchanged; no stale generated engine or output patch | `checkpoints/verify-836.receipt.json`; generated images/manifests retained outside Main Git | regenerate only after a coherent source change; root text equality alone does not authenticate composed providers |
| BIR lowering / native bridge | Bridge source drives the one Emit engine; no split JS/C lowering. Earlier native `book_valid` checked 11,164 bodies with 0 holes; that historical admission is not current C execution or a native HOST artifact | `evals/native_compiler_driver.bend`; `7dc1ab92` | complete current-root BIR/C and ownership admission |
| C lane | Frozen `971e0986` matrix: 23/25 pass emit/clang/run/output. `c_target_bool_fields` prints `True` then fails at runtime; original tail-capture input is parser-rejected. Parenthesizing its local function type preserves the intended test and separately passes with `11`, `12`. Literal `Bool.xor(True{}, True{})` also fails without fields or preceding IO: not merely a borrowed-view bug | `evals/receipts/c_matrix_971e0986_25.json`; `repro_inline57ab_971_public.json`; `repro_bool_xor_971.json` | correct canonical CID selection in `bend_bool_xor`, regenerate and run the complete unchanged-or-expanded matrix; do not reclassify the original failed batch |
| Physical path slice | `daf8a137` retains non-allocating packed reads and authoritative `FormArm.tag` writes; failure paths use real `err_fail`, no fixture-only helper. Authentic fixed6 runs all 46 expressions. The three original public Bool projection/Char/Fill sources now also pass actual emit/clang/run; Char stdout does not establish canonical CID or a borrowed StCell by itself | fixed6 intake `0987900a`, helper audit `10eaeb62`; `evals/receipts/repro_inline57ab_971_public.json` | general physical/ownership laws, full-root/native admission and remaining primitive failure stay open; finite checks are not whole-backend acceptance |
| Foreign / lifetime regression | Current `971e0986`: `list_rebox_sum`, `family_field_hot`, `c_backend_link` pass real C and JS emission/execution; the original frontier bound is unchanged. Two minimized ownership controls also pass, frontier 129→129 pages, and whole-parent alias prints `9`. Historical `5205478f` failures remain preserved; frontier pages are not retained/live bytes | `evals/receipts/foreign_971e0986.json`, `repro_ownership_971.json`; `REPRO_OWNERSHIP.md` | general lifetime/alias proof and full corpus remain open; no removed frees, relaxed thresholds or inference of retained bytes |
| JS / library lanes | The three current foreign/IO fixtures pass both targets. Actual sharedEmitC library emission, clang linking to the unchanged C caller and execution pass (`export ok`): six named exports including partial/lazy/factory application, not the legacy template-only smoke | `evals/receipts/foreign_971e0986.json`: seven rows, eighteen guarded stages, all complete/stopped/exit 0 | full agreed JS corpus and current-root byte fixedpoint; these bounded ABI cases do not accept every foreign/library program |
| Full native build, NO_TRACE joint control | `ABORTED_NO_TERMINAL_REPORT` — **not** an OOM: dead PIDs, guardian report 0 bytes, last recorded `compile_book` start; exact kill cause unobserved; launcher had a 1200 cap but no exit record | Main-scoped control; no terminal report path available to this note | guardian lifecycle fix before interpreting this control |
| Guardian lifecycle | Integrated: detached supervisor, early decision receipt, final `complete`/`ownedTreeStopped` contract; lease held until owned descendants are confirmed stopped, never released by timer. Merged focused run: 3 pass / 0 fail / 57 assertions. Earlier unlocalized deadline-test failure remains UNKNOWN; this is not a full-suite green claim. | `a72e87d6`..`1c82c2c5`; receipt `747a42a2`, `evals/heavy_gate_lifecycle.receipt.json` | fresh full-root control; diagnose the preserved deadline risk if encountered |
| Guarded target-matrix runner | Completed unfiltered 25-case batch on source `6fa30d28`, candidate `971e0986`, Node 23.11.0, external parser `0e7b3c42`, `--keep`. All 73 started stages have complete/stopped reports; batch exit 1. Raw 462-file manifest, commands, hashes, per-stage times/peaks and exact failure diagnostics are preserved | `evals/receipts/c_matrix_971e0986_25.json`; `/tmp/bend-accept25-971-6fa30d28-run1/evidence.manifest.json` | repeat the complete batch after the actual producer fix, including corrected affine-tail input; no narrowed aggregate acceptance |
| Official TS producer / full native build, traced | 11,164 native-bridge bodies; book heap 1,669,811,048 B; reaches pass 6; OOM; no native artifact | Main-scoped traced run; scope not verified by note | per-structure decomposition; native artifact within the guard |
| Profiling (actual code) | Producer and stage adapters integrated: scoped wall/CPU/memory, optional statistical samples, crash checkpoints, failure unwind and artifact-bound attribution. Producer smoke 10/10; merged stage behavioral tests 15/15, 49 assertions. Typed request/chunk attribution is sampling, not exact substage time; retained bytes and full-root overhead remain OPEN | producer `3cd1adcd` / `0b0b9c9f` / `d1bbca4e`; stage `68cde43a`..`754ff301`, behavioral receipt `13db7c2c` after deleting the incidental static test | finish canonical-input native Emitter profiling and fresh full-input A/B; do not treat output generation or fabricated BIR metadata as workload acceptance |
| Native profiling followup | Preserved `OLDPINNED_DIAGNOSTIC` OOM localizes the open boundary to `compile_book / c-pass-1` after load/validation/reachability; no native artifact. A separate guarded literal diagnostic with 1k/4k/16k elements passes and measures reachability/pass-1 growth. It does not reproduce the heterogeneous full-root OOM, identify its cause or measure retained bytes. Observed samples are boundary/event samples, not continuous heap peaks | original `checkpoints/compiler-native-profile-merged-03d0-durable.json`, `51c09c2a`; `REPRO_NATIVE_PASS1.md`, `evals/receipts/repro_native_pass1_literal.json`, intakes `d3f02ed2` / exact provenance `a46f948b` | minimize the actual failing structure; native artifact within 3072 MiB worker old-generation limit, retained/live attribution and current-image full-input overhead remain OPEN |
| Law documents | `FIR_LAWS.md` and `BIR_LAWS.md` are written, reviewed and linked from `ARCHITECTURE.md`; seven written law tasks CLOSED. C-1 now explicitly requires real runtime/helper resolution; C-6 distinguishes reachable region fallback obligations from successful return/tail paths. General proofs/behavior obligations remain OPEN | original intake `2fcdbaea`; current source/smoke evidence is finite, not a proof of every C-1/C-6 path | obligation triage and missing edge checks; no general semantic-preservation, ownership or whole-backend acceptance |

Table entries are status, not acceptance checkboxes. The current full-root
acceptance remains pending. A doc-only change does not justify rerunning
unchanged source; an imported physical/parser source change does.

---

## 2. P0 — active implementation

Owners: **NativeSeedBootstrap** (guardian lifecycle), **ProducerProfilingImpl**
(official TS producer), and **StageProfilingImpl** (selfhost pipeline). These
are implementation workstreams, not research notes. Guardian's changed path and
producer's tiny smoke are verified; complete pipeline coverage remains open.

### 2.0 Guardian lifecycle — NativeSeedBootstrap

The `NO_TRACE` joint control returned `ABORTED_NO_TERMINAL_REPORT`: dead PIDs, a
0-byte guardian report, and the last recorded `compile_book` start. That is not
an OOM result; the exact kill cause is unobserved, and the launcher's 1200 cap
left no exit record. Long acceptance runs must not be interpreted until the
guardian lifecycle is fixed.

Files owned by NativeSeedBootstrap:
`evals/heavy_gate.ts`, `evals/heavy_gate_native.c`,
`evals/heavy_gate.test.ts`.

Status: integrated at `a72e87d6`..`1c82c2c5`; merged focused evidence at
`747a42a2`, in `evals/heavy_gate_lifecycle.receipt.json`. One merged command
exercised normal/failed commands, launcher process-group death and receipt
classification: **3 pass / 0 fail / 57 assertions**. The earlier unlocalized
deadline-test failure is still UNKNOWN, not erased by these passes.

- [x] Keep the supervisor independent of the launcher's process group; publish a
  decision receipt before cleanup and a complete receipt after confirmed stop.
- [x] Accept PASS only with `reportPhase: complete` and `ownedTreeStopped: true`;
  a rejected PASS has a nonzero effective exit while preserving the raw exit.
- [x] Hold the exclusive lease until `exited && !live`; no timer releases it
  while an owned descendant may remain.
- [x] Exercise launcher-group kill and lease reuse with an isolated report
  directory; preserve unfiltered output from the merged verification.
- [x] Preserve the unlocalized deadline failure explicitly as UNKNOWN; no
  polling assertion or repeated-run voting hides it.
- [ ] Obtain a new full-root control receipt. The old
  `ABORTED_NO_TERMINAL_REPORT` remains historical, not retroactively diagnosed.
- [ ] Attribute an external launcher cap to its exact cause when observable;
  lifeline EOF alone proves launcher loss, not its signal or caller's reason.

An untrappable SIGKILL of the supervisor before any decision can still leave no
receipt. Missing/provisional evidence is non-success, never inferred OOM/PASS.
The focused repair verification does not certify the previously failing
deadline scenario or a complete compiler build.

### 2.1 ProducerProfilingImpl — official TS producer

Goal: explain the official producer's cost and memory composition well enough
to distinguish Book retention, stable fact-store growth, current-pass segments,
and per-definition scratch, without changing what the producer emits.

Status: integrated at `3cd1adcd` + `0b0b9c9f`; merged smoke and guardian-pin
update at `d1bbca4e`. The first merged attempt failed before any profile case
because its guardian pins were stale; after that two-pin fix, one run passed
all 10 cases. Includes `bend2/selfhost/COMPILER_PROFILING.md`,
`evals/compiler_profile.mjs`, `evals/compiler_profile_smoke.ts`, and the compact
`checkpoints/compiler-profile-smoke-receipt-0b0b9c9f.json`. Full-root acceptance
and observer overhead are not established by these tiny cases.

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

Status: integrated at `68cde43a`, `dce884f1`, `ffee21ea`, `754ff301`. Includes
`bend2/selfhost/RESEARCH_STAGE_PROFILING.md`, `evals/compiler_stage_profile.mjs`,
`evals/compiler_stage_report.mjs`, candidate-host/bootstrap-worker entry points
and `checkpoints/compiler-stage-profile-v1.json`. The old-component A/B receipt
is historical after the C renderer update. Followup canonical-input native
build `46124798` ran under Node 23.11 with the fixed 3072 MiB worker heap,
8 GiB RSS/footprint guard, 10 ms sampling and 600 s deadline: worker heap OOM,
no native phase or artifact. The raw log does not distinguish load, validation
and codegen; no exact boundary is inferred. Earlier scalar and invented-metadata
inputs are diagnostic/rejected, not Emitter workload acceptance. Followup
source is integrated through `8a108208`; merged tiny verification is recorded
at `fe027d57`. The producer's optional observer uses the existing
`compile_book` seam, without kernel/compiler changes. The checkboxes below
are acceptance, not writing.

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
- [x] Reuse the existing producer profiler in the native diagnostic builder:
  durable load/validation/codegen and codegen-pass boundaries, exact
  worker-run binding, failed/aborted distinction, and fail-closed exit without
  a terminal result. Merged guarded tiny suite at `fe027d57` passes; peak RSS
  276,316,160 B / footprint 202,980,448 B, elapsed 6,521 ms. This neither
  retroactively attributes the old OOM nor proves the full native workload.
  A subsequent full diagnostic attempt with these merged checkpoints
  (`51c09c2a`) now localizes **that run** to `compile_book/c-pass-1`.
  `book_load`, `book_valid` and `c-reachability` completed; the worker reached
  its 3072 MiB heap limit before clang or native execution. The workload is
  explicitly `OLDPINNED_DIAGNOSTIC`, with the prior canonical inputs and
  generated machines authenticated by hash; it is not the new C candidate.
  Boundary heap deltas are not allocation or retained bytes, and the open
  pass has no completed wall/CPU measurement. No unchanged retry is planned.

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

- [x] Review and intake producer and stage adapters with honest evidence limits.
- [ ] Verify the fresh-component A/B and native guarded/workload paths; old
  component generation or scalar group-tag evidence cannot satisfy them.
- [ ] Every receipt distinguishes `[M]` measured, `[P]` procedure, `[O]` open.
- [ ] Every number names its pin; stale pins are marked stale, not reused.
- [ ] No new timing constant or performance claim enters docs without a receipt.
- [ ] All active workstreams keep the clean build runnable with profiling and
diagnostic hooks disabled.

---

## 3. FIR / BIR / C acceptance backlog

Detailed contracts: integrated `FIR_LAWS.md` and `BIR_LAWS.md`, and
`RESEARCH_INCREMENTAL.md` for the reuse implications.

### 3.1 FIR

- [ ] Authenticate the next source batch against the latest pinned predecessor:
  `/private/tmp/bend-fir-root-aa9/checkpoints/root-final4-rep.result.json`,
  source `b0b92b67`, emitter `156a7475`, component `5205478f`,
  11,191 checked/live bodies, 0 excluded / 0 patches.
  Root text equality is not dependency equality. A changed parser pin requires
  fresh parser acceptance, not reuse of the prior 45-pin receipt.
- [x] Repair the canonical quantity-binding parser in the authorized scope:
  typed `+name: T = value` in body/do and typed `+name: T <- action` in do
  preserve quantity. Existing body-untyped behavior is unchanged; untyped do
  quantity binding is not stage0-valid. Three affected JS fixtures and the
  full parser gate pass; no corpus/exports/limit changes.
- [ ] Preserve the build report's `JS_GENERATED_NOT_YET_EXECUTED` status;
  record subsequent actual component/C execution in its own receipt, not by
  retroactively rewriting the build.
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
- [x] FIR_LAWS reviewed, integrated, and linked from `ARCHITECTURE.md`.

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
- [x] BIR_LAWS reviewed, integrated, and linked from `ARCHITECTURE.md`; no
  semantic-preservation proof claimed.

### 3.3 C target

- [x] Replace the non-tail Base String.split/join path with linear stack-safe
  text assembly; complete emitted translation units now reach clang and run
  (`c_probe_5205478f_pass.json`). This does not close full C acceptance.
- [ ] Finish ownership-correct projection: non-consuming payload reads must
  preserve the parent through nested-pattern failure. Distinguish borrowed
  field views from owned transfers; detach an affine field at its actual move
  rather than keep it and later drop both owners. The runtime rejects sharing
  heap closures (`rfc_wrap`, `ERR_RFCS`), so unconditional field `term_keep`
  is not a solution. Preserve callable-field return/application as well as
  repeated legal data projections; no blanket input rejection or type table.
  The rejected destructive-view patch and raw-read/no-free patch are not fixes.
  Regression `evals/c_target_clo_field.bend` returns and applies a captured
  function field. Its current guarded `971e0986` matrix run prints `7`.
  Earlier Official 2.0.36 / `5205478f` unguarded runs remain explicitly
  `REJECTED_UNGUARDED` in `c_target_clo_field.receipt.json` (`10182f34`);
  the later pass does not legitimize them. Output alone is not a release proof.
- [ ] Carry ownership state through continuations and nested pattern failure;
  prove values and allocation/release behavior for ordinary, sealed/shared,
  nested, unused-field and fallback cases before the full fresh C matrix.
  Caller liveness is separate from formal `Arg.use`/`Field.use`: an
  unrestricted caller can supply the same value to two affine consumers.
  Cover repeated data parameters/captures, duplicate operands in one call or
  constructor, already-bound aliases of the same projected path, and a
  projected field followed by use of its whole parent. Branch/region analysis
  must follow `LeaveRegion` successors without treating terminal alternatives
  as sequential uses of an affine callable. Current guarded caller/alias,
  disjoint-cell and corrected tail controls pass; the general proof stays open.
  Array pattern halves/leaf cells follow the same borrowed-path law:
  consuming a selected slice must leave disjoint sibling owners available,
  including across continuations. Verify packed u32 buffers, boxed/inline
  cells, mixed ADT/array nesting and static/shared roots without eagerly
  freeing the whole array or copying a heap callable.
- [ ] Implement moves, keeps and sinks under the existing universal one-Term
  ABI: admitted Nat values are 48-bit immediates, U32/F32 payloads are 32-bit,
  and runtime `term_triv` handles them without a heap operation. Preserve
  generic/open inputs; ownership origin and path liveness, not speculative
  duplicated type tables, determine release placement.
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

- [x] Correct the `bend_bool_xor` C conditional at `c_backend.bend:3942`.
  Source-only `8aefa052` selects canonical `t`/`f` after comparing truth values.
  Both reduced failures and the complete truth table now pass on `667e7f33`;
  the unfiltered expanded C matrix passes 26/26. Old `971e0986` failures remain
  immutable in `repro_bool_xor_971.json` / `c_matrix_971e0986_25.json`.
  New proofs: `bool_xor_fix_667e7f33.json`, `c_matrix_667e7f33_26.json`.
  No generated-C patch, new helper, allocation or fallback value was added.

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

### 3.6 Parallel minimal reproducers

Requested by the user; four independent workers started from `5328869a` in
isolated `work/repro-*57ab` worktrees. They own diagnostic inputs and evidence,
not production changes:

- [x] **ReproInlineValues:** original three Bool/Char/Fill witnesses and both
  isolation controls pass on `971e0986`; limitations on CID/StCell evidence
  remain explicit. The newly isolated literal/projected Bool.xor failure is a
  separate open C primitive bug. See `REPRO_INLINE_VALUES.md` and receipts.
- [x] **ReproOwnership:** historical minimal failures preserved; current
  constructor, rebox and whole-parent value controls pass with the unchanged
  frontier bound. See `REPRO_OWNERSHIP.md` and `repro_ownership_971.json`.
- [ ] **ReproNativePass1:** three frozen literal inputs pass within the existing
  guard and quantify growth. They do not reproduce/minimize the heterogeneous
  full-root OOM. See `REPRO_NATIVE_PASS1.md`, intake `d3f02ed2` / `a46f948b`.
- [x] **ReproInlineParser:** actual public parsed results isolate stale inline
  typed-local and quantity-binding behavior from the accepted external parser;
  untyped and ordinary-do controls agree. No ABI/oracle failure or parser
  cutover claimed. See `REPRO_INLINE_PARSER.md`, intake `bcd6f171`.

Each handoff requires the source, exact command, source/artifact hashes,
expected/observed behavior, runtime/heap/stack/caps and a complete/stopped
guardian receipt. A reduced diagnostic witness is not a narrowed acceptance
corpus. One Root build is shared; workers prepare independently and execute
only in assigned slots on the same default guarded lane. Generated artifacts
and raw bulk logs stay out of Git.

The four baseline handoffs are preserved. New matrix/foreign executors could
not start: their model provider returned `401 api_key_expired` before tools.
Main executed the existing guarded commands in isolated worktrees and records
their actual results above. Worker access is not restored; implementation
handoffs must not be described as running while that prerequisite is absent.

Parser cutover preparation is recorded at commit `d68df586` in
`/private/tmp/bend-root57ab-go/checkpoints/inline-parser-cutover.preparation.json`.
It is **PREPARATION_ONLY_NOT_EXECUTED**. The composer requires tree-local
authenticated parser acceptance, then fresh owned/template/checker/emitter
manifests before root composition; copying accepted absolute paths or patching
root text is not a cutover. The recipe's `6c1df3eb` runtime pin names the kernel
`bend2/bend.ts`, not generated C runtime `478c1ba7`; there is no pin mismatch.
Public parse behavior, not source-hash equality, decides inline-parser repair.


---

## 4. Law writing / review status

Both law documents are written, reviewed, integrated by `2fcdbaea`, and linked
from `ARCHITECTURE.md`. The **seven written law tasks are CLOSED**. Proof and
behavior obligations remain **OPEN**; a committed law
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
- `COMPILER_PROFILING.md` and `RESEARCH_STAGE_PROFILING.md` — integrated
  profiling implementation, operational scopes and explicit remaining coverage.
- `RESEARCH_WASM_WASI.md`, `RESEARCH_GPU.md`, `RESEARCH_LLVM.md`,
  `RESEARCH_MLIR.md`, `RESEARCH_ZIG_BACKENDS.md` — integrated backend research
  only, not implemented targets or an approved backend cutover.
- `RESEARCH_PROFILING.md` — integrated coverage research; implementation
  receipts above distinguish the measured subset from open coverage.
- `checkpoints/SELFHOST_IR_ARCHITECTURE.md` — earlier F/L/B/G/K law
  obligations and IR architecture.
- `checkpoints/SELFHOST_HANDOFF.md` — historical implementation handoff;
  treat provenance accordingly.
- Profiling artifacts: `evals/selfhost-root-phase-profile-57ab.json` (pin
  `d47f859b`, diagnostic only), `checkpoints/compiler-profiling-quality-v51.json`
  (pin `7c33172b`), `checkpoints/book-phase-attribution.json` (older pins).
