# REPRO_NATIVE_PASS1 — c-pass-1 cost witness (diagnostic only)

Status: **DIAGNOSTIC_ONLY**. Not acceptance evidence, not a C candidate result,
not benchmark data. The literal-family measurements below remain unchanged.
A later raw-detail observation of the same frozen03d0 workload is recorded at
the end; it changes only observer detail, not production compiler/source bytes.

Committed inputs: `evals/repro_native_pass1.ts` (driver, sha256
`ef42fa50f44558d8f00c8a8b5835504222c2c0a18b4a3c5c6328a0db116c5ac7`).
Compact receipt: `evals/receipts/repro_native_pass1_literal.json` (sha256
`62377cfa91b9efbb81da253ad5050b579ae0505633c8e05430912a1535287b33`).
The three exact generated sources the run loaded are committed at
`evals/repro_native_pass1/literal-{1000,4000,16000}.bend`
(sha256 `78685a5db42b00488755de0050c909bfe8735ee6ece482ffd6ea76da6d8f50a0`,
`edf4f5dc36c5c4f305eac76d852380dc798331bc33cd1adff1eeb717a1fc4763`,
`a33487cc6ded7730160cefae3827fada4c88212841e19626e384fb8f1e45d17e`; each
matches the receipt's `sourceSha256`/`sourceBytes` byte for byte and is exactly
what `familySource('literal', K)` produces). Full run JSON with per-release
samples stayed outside Git at `/tmp/repro-native-pass1-full.json`.

## Frozen execution facts

- Node `v23.11.0` / V8 `12.9.202.28-node.14`,
  `/Users/ilyagulya/Library/pnpm/nodejs/23.11.0/bin/node`.
- Compiler under test: `bend2/comp.ts` sha256
  `a84170d5a84f21386383ccd478a1dac687eb664d89c21b284cd1134513963b70`,
  `bend2/bend.ts` sha256 `6c1df3eb304fe085070aa4797928f70243b80d4635389e3d5d8a49fdfbb3051e`
  (same bytes as the failing 03d0 worktree).
- Worker per case: stack 256 MiB, `resourceLimits.maxOldGenerationSizeMb=3072`
  (an old-generation limit, not a cap on `heapUsed` across all V8 spaces). Guardian:
  `guardHeavyGate` 8192 MiB / 8192 MiB / 10 ms / 600000 ms, DEFAULT lock path,
  no nested or independent lock. Real worker `exit` is awaited before the next
  case starts.
- Invoked launcher command (cwd `/private/tmp/bend-repro-oom57ab`, branch
  `work/repro-oom57ab`, driver commit `ae63dc7d`), with launcher
  `execArgv = ["--experimental-strip-types"]`:

  ```
  /Users/ilyagulya/Library/pnpm/nodejs/23.11.0/bin/node --experimental-strip-types \
    evals/repro_native_pass1.ts --out=/tmp/repro-native-pass1-full.json \
    --receipt=/tmp/repro-native-pass1-receipt.json --families=literal \
    --literal-sizes=1000,4000,16000 --sizes=8,16,32,64 --max-defs=64 \
    --max-elements=16384 --report-limit-units=67108864 --case-timeout-ms=60000
  ```

- Guardian re-exec: `guardHeavyGate` runs `process.execPath` + the absolute script
  path + the case arguments, so the supervised child's `execArgv` is `[]` and the
  receipt's `runtime.execArgv=[]` is the child's, not the launcher's. Node 23
  strips TypeScript by default, so the dropped flag does not change loading.
  Both argv forms, both execArgv values, and the guardian's own recorded command
  are committed in the receipt under `invocation.launcher`,
  `invocation.supervisedChild` and `guardian.command`. `--sizes` and `--max-defs`
  are present in the invoked argv but unused under `--families=literal` (literal
  sizes come from `--literal-sizes`, the element bound from `--max-elements`).
- Guardian terminal record copied from the existing report (no rerun):
  `reportPath /var/folders/0r/pkz80d0154z37ybnv69pqclh0000gn/T/bend-heavy-gate-501/report-1792919199894-4da41f9aed3f3e02.json`,
  879 B, sha256 `a3fa23e25b3c69c652d0800d3410fd8810ff60a37a571f46ecf09e8598acd4fb`;
  status `PASS`, reason `command_exit`, commandExitCode 0, commandSignal 0,
  reportPhase `complete`, ownedTreeStopped `true`, supervisorExitCode 0,
  elapsed 11943 ms, peakRss 591642624 B, peakFootprint 588228664 B,
  memoryLimit 8589934592 B, rssLimit 8589934592 B, timeout 600000 ms.
  The peak values are 10 ms supervisor samples of the guarded tree. The receipt's
  `measurement.workerLimit`/`measurement.heapSizeLimit` scope notes record that
  `maxOldGenerationSizeMb=3072` is an old-space limit while `heapSizeLimit`
  (3271557120 B) is V8's isolate heap-size limit, and that neither turns the
  heapUsed samples into available headroom.
- `--report-limit-units` is a **post-generation report limit** checked on the
  returned C string after `compile_book` finished. It is not an emit,
  allocation or preventive memory bound.

## Reproducer: one pure main holding a wide List<Nat> literal

`literal(K)` generates `import Base` plus `def main() -> List<Nat>:` whose body is
one wide literal of K elements (`[0n, 1n, …, (K-1)n]`, roughly two constructor/literal
nodes per element after desugaring). `book_load` → `book_valid` → `compile_book` on the real
public path with an observer; `K` is an **element count**, never a definition
count. Counts below are labelled accordingly.

### [OBSERVED] measured phases (same pass, same caps)

| elements | source B | load ms | valid ms | reach ms | pass-1 ms | reach Δheap B | pass-1 Δheap B | C units | C lines | segments | spins | whole-run sampled max heap B | sampled max RSS B |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1000 | 5931 | 115.4 | 329.2 | 134.8 | 572.7 | 8100048 | 8477712 | 212343 | 5965 | 1 | 0 | 43906920 | 227688448 |
| 4000 | 26931 | 243.3 | 226.7 | 318.3 | 1044.3 | 40729392 | 46110792 | 641343 | 14965 | 1 | 0 | 119135416 | 301842432 |
| 16000 | 116931 | 303.0 | 1304.9 | 543.4 | 3312.6 | 154878744 | 178282800 | 2387343 | 50965 | 1 | 0 | 379509448 | 583024640 |

Every case: `status COMPLETED`, exactly 1 pass (`c-pass-1-before`/`-after`
observed), 346 checked definitions in the loaded book, 2 higher-term prepares,
13 releases, 0 spins, `heap_size_limit` 3271557120 B. `releases` is the count of
definitions the pass actually emitted (13: `main` plus 12 reachable), so these
runs measure literal-node cost, not per-definition cost over thousands of
definitions. Heap row semantics: `heapUsed` is a worker-isolate sample at an
observe event, not live or retained bytes.

### [OBSERVED] boundary heapUsed rows (B), in order

`c-reachability-before` → `c-reachability-after` → `c-pass-1-before` →
`c-pass-1-after`; the pass boundary is the exact `c-pass-1` boundary reached:

- 1000 elements: 27325976 → 35426024 → 35429208 → 43906920
- 4000 elements: 32291784 → 73021176 → 73024624 → 119135416
- 16000 elements: 46344456 → 201223200 → 201226648 → 379509448

### [OBSERVED] marginal coefficients (list-element basis)

- Emitted C: **145.5 UTF-16 units and 3.0 lines per element** (4000→16000);
  the 1k→4k marginal is 143.0 units/element, so the slope is stable.
- `c-pass-1` boundary heap delta: **10.9 KiB/element** at 16000 (11.3 at 4000,
  8.3 at 1000); `c-reachability` delta: **9.5 KiB/element**.
- Wall: `compile_book` marginal ≈ **0.19 ms/element** (pass-1 total 3.3 s at
  16000 elements); reachability marginal ≈ 0.019–0.06 ms/element.
- The literal is emitted inside exactly one segment with zero spins; the
  measured per-element boundary heap is not further attributed here (emitted
  code, image words and uncollected garbage are all possible owners).

### [INFERENCE] naive scale only: it neither explains nor refutes the merged OOM

The measured slope applies **only to this LIST family**: uniform `Nat` leaves in
one flat wide literal, emitted inside one segment with zero spins. The merged
fixture's terms have a different structure: `program()` is one 434812 B line of
23403 **heterogeneous, nested** `BIR.` constructor tokens (`Program` → `Code` →
`Region`/`Let`/`Branch`/…, with type-carrying fields), while `runtime()` is a
78513 B string literal and `files()` a 56-entry list of records holding source
strings. Constructor cost is therefore **not uniform**, and nesting, erased-type
instantiation, string/image handling and per-definition rebuilds are all absent
from the measured family.

Applying the list slope numerically to those tokens (bracketing 11.7k-23.4k
elements) gives pass-1 boundary growth ≈ 0.12-0.25 GiB, reachability
≈ 0.11-0.22 GiB, whole-run sampled max ≈ 0.26-0.52 GiB, C text ≈ 1.7-3.5 M
UTF-16 units, against a 1227813008 B numeric gap between that boundary heapUsed
sample and the same 3072 MiB old-generation limit (not proved available
headroom). That is a naive scale of a *different* structure: it does **not** explain
the actual OOM, does **not** prove the fixture literals are insufficient, and
does **not** refute them. The giant-fixture hypothesis is **not ruled out**; an
actual fixture-shaped nested input would be needed, and only if source profiling
points there. No OOM cause, upper bound or minimality claim is made.

## [OBSERVED] the frozen 03d0 failure (from its own receipt, not rerun)

`checkpoints/compiler-native-profile-merged-03d0-durable.json`:

- Six spans: module-import 0.704 s, book_load 15.274 s, book_valid 9.584 s,
  c-reachability 26.238 s; `compile_book` and `c-pass-1` still active.
- At the `c-pass-1-before` boundary (52.2 s): heapUsed **1993412464**, heapTotal
  2029076480, RSS 2185461760. Process CPU at that checkpoint: user 21433.1 ms,
  system 973.2 ms (process-wide).
- Worker OOM observed **101.3 s** after that boundary (153.6 s total); no
  `c-pass-1-after`, no artifact. Guardian peakRss **3472670720**, footprint
  **3627897496**. The worker limit is `maxOldGenerationSizeMb=3072`
  = 3221225472 B; the boundary heapUsed sample is 1227813008 B below that number
  and heapTotal 1192148992 B below it. Those are numeric differences to an
  old-space limit, **not** proved available heap headroom (the limit bounds old
  space while heapUsed/heapTotal cover all V8 spaces). The guardian peak RSS is
  1287208960 B above the boundary RSS.
- Fine observations were suppressed (`rawDetail: false`, `fineSpans: 0`), so
  this receipt has **no per-definition rows**: the pass's internal trajectory is
  unmeasured there. The 1.993 GB boundary sample is not a peak and not retained
  bytes.

## [OBSERVED] per-pass output scale of the same generated machines (older book)

An earlier successful compile of the same generated-unit family (its entry
comments name `../checkpoints/*_steps_v1`; byte identity to today's pinned units
is not proven) with the older 236-line driver produced `native-stage-profile.c` = 45996671 B, 1093354 lines,
14340 `WL_CASE` arms. The `WL_TABLE` lists 14339 entries = **14336 emitted
segments** + `FID_IO_EMIT` + `FID_CLO_APPLY` + `FID_EXIT`, and the 14338 table
comments are those 14336 segments plus IO_EMIT/CLO_APPLY. Of the comments:
**1341 plain names** (including IO_EMIT/CLO_APPLY), 10919 `$c` and 2078 `$k`
continuation entries, with continuation counters reaching **44548** — i.e. one
pass pushed at least ~44.5 k segments before the reachability filter kept 14.3 k.
All arms hold 783870 lines (median 38, mean 54.7; largest kept segments are
`emitter_step_one` 38995, `checker_step_one` 35243, `template_step_one` 7003);
5312 spins hold 275235 lines. That run's guardian peak was 6606716928 B over
217834 ms including clang and the native execution. It contains **zero**
generated-fixture entries, so it is not this merged workload's output; it is
evidence for the shape and magnitude of a pass over the generated machines.

## Source ownership of `c-pass-1` (primary code, `bend2/comp.ts`)

- `compile_book` 3110–3156: each pass clears `lend/spun/clos/tabs/lits/consts/brws`
  and resets `segs/spins/img`; then for every `done_defs()` definition
  (`done_defs` 1484, `FL.srcs` keys) it calls `emit_open(scope_new(), k)`, pushes
  that segment, emits `emit_body(dl, fun_of(k).h!, …)` and calls `file_release(k)`;
  the loop repeats while `own+hot+stat` changed (`facts()` 3122).
- `file_release` 1669–1682: **per definition**, it clears `FL.higher`, clears
  `FL.consts`, and `memo_gc()` clears all five memos. Higher terms are therefore
  rebuilt per definition, not cached per pass; `fun_of` 1415–1442 keeps only the
  `Fun` record and exposes `h` as a getter into `file_higher`/`term_higher`.
- `emit_fuse` 2476–2502: reads `{n, h, lays, ret} = fun_of(k)` eagerly; flat
  callees go to `emit_native` 2520–2548, which memoises a spin per
  (definition, erased-layout ids) inside the pass (`FL.spun` is reset each pass);
  non-flat callees that are tail-called, non-bang and referenced exactly once are
  inlined into the caller (`emit_body` once test 2846–2855).
- `seg_open` 1883–1896 pushes every fork/loop continuation into `FL.segs`, and
  `seg_name` 1879 names it from `FL.segs.length`; a pass therefore materialises
  more segments than it has definitions.
- `c-pass-N-after` (3154) is observed **before** the `live` filter (3162), so it
  reports the pre-filter working set.
- `file_observe` 1627–1643 reports cache sizes only (`retainedHigher`, `segments`,
  `spins`, fact sizes, memo sizes); the production adapter
  (`evals/compiler_profile.mjs` 661–690) drops fine stages unless `rawDetail`, so
  the 03d0 receipt cannot show per-definition state.

## Causal accounting (separated)

- [OBSERVED] Constant-literal emission is linear in nodes: ~145 C units and ~3
  lines per element, ~11 KiB boundary-heap per element, ~0.19 ms/element.
- [OBSERVED] The failing pass started from a 1993412464 B heapUsed sample,
  1227813008 B below the 3072 MiB old-generation limit (a numeric gap, not proved
  available headroom), and did not finish within 101 s.
- [INFERENCE] The list-family slope is a naive scale for the fixture's
  heterogeneous nested `BIR` tokens (≈0.12-0.25 GiB pass-1 boundary heap,
  ≈2-5 s if applied numerically). Because constructor cost is not uniform and
  the structures differ, that scale neither explains nor refutes the actual
  OOM: the giant-fixture hypothesis stays open. A second open hypothesis is
  per-definition work over the book (each definition emits a segment and rebuilds
  its higher term and memos after the previous definition's release), whose
  scale the older artifact shows as ~1.09 M lines and ≥44.5 k pushed segments per
  pass. Neither is measured for 03d0: no per-definition rows exist there, and the
  prepared chain/linear pair was **not** executed.
- Not claimed: exact OOM cause, globally minimal OOM witness, retained-byte
  figures, a pass result, or any acceptance/candidate behaviour.

## Prepared but unexecuted

`chain` and `linear` (4 sizes each, matched arithmetic/IO.pure prefix and leaf;
only the continuation placement of the identical call differs) remain in the
committed driver and were **not run** in this slot. They would add per-definition
`prepare`/`release` slopes and the once-tail-inlining growth term; they do not
shrink the frozen acceptance corpus, exports or matrix.

## Unknowns in the original literal/coarse runs (later controls below)

- No per-definition heap/prepare series exists for the 03d0 book.
- The fixture's nested non-list constructor term and its large string/list
  images were not compiled in isolation; only a wide `List<Nat>` proxy was, and
  its per-element slope is not a per-token cost for heterogeneous nested
  constructors.
- The giant-fixture hypothesis is untested and not ruled out; no fixture-shaped
  nested input was run.
- `book_load`/`book_valid` peaks are unsampled (no observer hooks inside them);
  only their boundary states are measured.
- CPU per phase was **not** instrumented in the executed driver; only wall times
  are measured here. The frozen 03d0 receipt's process CPU at its 52.2 s
  checkpoint was user 21433.1 ms + system 973.2 ms (process-wide, includes the
  worker), but that is a different run and book.
- Everything here is one machine, one Node/V8 build, one pass implementation.

## Later raw-detail attribution of the preserved03d0 workload

`evals/receipts/native03d0_fine_files_oom.json` records a new diagnostic with
the same frozen driver `dd1b86b4`, generated transport and step machines.
The existing observer's raw mode streams 397,986 events rather than suppressing
per-definition rows; its serialization/I/O overhead is included. This is not an
unchanged retry for acceptance or a timing comparison with the earlier run.

Unchanged Node23.11 / 3,072 MiB worker old generation / 256 MiB stack and
8 GiB footprint/RSS / 10 ms / 600 s guard: worker OOM, complete/stopped,
80,132 ms, max sampled RSS 3,489,955,840 B / footprint 3,619,656,368 B.
Load, full validation and reachability complete. After 9,551 completed
`c-definition` spans, the final open scope is:

`compile_book → c-pass-1 → native_stage_profile_generated_fixture:files`.

Its `prepare` completed. The final observed boundary has heapUsed
2,482,589,240 B, 43,351 segments, 5,298 spins, 21,238 own / 683 hot / 58 static
facts. These are boundary/count observations, not a continuous isolate-heap
peak or retained/live owner sizes. The raw 238,143,216 B event file stays
outside Git with its hash in the compact receipt.

This localizes **this diagnostic's open definition**, not the cause or owner of
all preceding memory. It does not establish that `files()` fails in isolation,
that the list is minimal, that `program()`/`runtime()` are harmless, or that a
different historical full-native-root OOM has the same cause. Isolating the
actual56-entry literal is now a source-backed experiment rather than scaling
the unrelated `List<Nat>` proxy.

### Exact files-body isolation: completes, but with large codegen heap

`evals/receipts/native03d0_files_isolated.json` preserves the next control:
the exact 279,909 B body of that56-entry `files()` list, byte-for-byte, becomes
one pure `main()` with only original Base/BIR-schema imports. No fabricated BIR
metadata or changes to the full acceptance corpus are involved.

The same Node23.11 / 3,072 MiB old generation / 256 MiB stack policy completes
load, full validation (543 events) and two `compile_book` passes. Returned C:
3,470,450 B; no clang/native execution was attempted. Guardian PASS,
complete/stopped, 10,320 ms, max sampled RSS 2,811,691,008 B / footprint
2,932,953,168 B.

Its first-pass heapUsed boundaries are 30,213,600 → 2,213,765,616 B. This is
large codegen working-set evidence for the actual transport structure, not
retained/live or allocated-byte attribution. It is also **not an isolated OOM**
or a minimal failing input. It does not prove that adding these samples to
the full run explains that OOM; overlapping lifetimes and GC remain unmeasured.

### User-approved4096MiB diagnostic: OOM moves, compilation still fails

`evals/receipts/native03d0_4096mib_oom.json` records the explicitly approved
heap-only diagnostic. All eight frozen input hashes and the observer source
match the3072MiB raw-detail baseline. Stack256MiB, guard8GiB footprint/RSS,
10ms sampling,600s deadline and automatic GC remain unchanged. The acceptance
policy is still3072MiB; this is not a new accepted native compiler version.

| Worker old generation MiB | Result | Guard wall ms | Peak RSS B | Peak footprint B | Open c-pass1 definition |
| --- | --- | --- | --- | --- | --- |
| 3072 | OOM | 80132 | 3489955840 | 3619656368 | transport `files` |
| 4096 | OOM | 150768 | 4502913024 | 4820992008 | `profile_emitter_pending` |

At4096MiB the transport `files`, `runtime` and `program` definition emissions
complete before the later failure. The additional heap therefore permits
observed progress but is insufficient for this workload; it neither produces
C nor proves that some still larger limit would suffice. These runs are not
a controlled speed benchmark. End-boundary heapUsed and memo counts remain
observations, not allocation or retained/live ownership.

### One-helper reduction does not reproduce the full OOM

`evals/receipts/native03d0_files_helper_control.json` records the same exact
56-entry literal in `files()` plus one pure `main()` call. All544 validation
events and two codegen passes complete under the original3072MiB/256MiB
worker policy and8GiB/10ms/600s guard. This rules out that simple wrapper as
a sufficient isolated reproducer; the full-workload interaction and a minimal
failing input remain open. No clang/native execution or acceptance is claimed.

### Temporary working8192MiB policy: two passes complete, deadline in pass3

The user's next instruction defers the3072MiB optimization target and permits
an8192MiB working heap. The outer tree guard is12288MiB to leave non-heap
headroom; stack256MiB,10ms sampling,one heavy child and600s deadline stay fixed.
`evals/receipts/native03d0_working8192_deadline.json` pins the same complete
frozen03d0 workload and unchanged compiler/kernel/observer bytes.

No OOM is observed. `c-pass-1` and `c-pass-2` complete; the guard stops pass3
with `profile_emitter_start` open and `profile_emitter_pending` in a spin.
No C output or native binary is produced. Guard complete/stopped,
600568ms, peak RSS7063502848B / footprint7568086144B.
The trace contains1060976events /646109345B; its overhead is not measured.
A subsequent no-per-definition-observer control is required before attributing
that deadline to the compiler or the observer. Passing under this working
policy would not close the deferred3072MiB target.

### No-per-definition-observer working8192MiB control also reaches the deadline

`evals/receipts/native03d0_working8192_unobserved_deadline.json` records the
same eight frozen source hashes with `C.compile_book(book)` and no installed
compile-book observer. Only module/load/validation/whole-codegen boundary
collection remains; this is not a zero-instrumentation timing claim.
Load and validation finish; compile-book starts at collector9412.820ms.
The guard stops the still-open whole-codegen span after600420ms, complete
and stopped, with RSS6999818240B / footprint7550635336B. No OOM is observed,
no C output exists, and the final pass/CPU location is unavailable.
Removing per-definition tracing is therefore not sufficient to complete this
working build inside the unchanged deadline. It does not measure overhead,
prove a compiler algorithmic cause, or attribute missing wall time.
