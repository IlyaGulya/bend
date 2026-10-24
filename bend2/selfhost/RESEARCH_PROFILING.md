# Profiling coverage: enough for the next step, not for every stage

**Current question.** Do the existing profiles cover every compiler stage well
enough to understand CPU and memory, and how hard will incremental compilation
be later?

**Short answer (source tree `f46ad0f6`, 2026-10-24).** They are enough to choose
the *next* diagnostic and to reject several unjustified optimizations. They are
not enough to optimize every stage, and not enough to estimate or commit to
incremental compilation. The strongest retained evidence is coarse-grained:
phase wall time, process CPU, sampled JS CPU stacks, statistical allocation,
and one private exact-allocation diagnostic for the *native target*, not for the
official TypeScript producer. There is no retained live/retained-memory
measurement, no per-definition CPU, no per-module allocation, and no source map
from generated JS/C back to Bend. The immediate producer OOM is a different
failure from a target-runtime failure and must stay separate.

**Decision boundary.**

- *Enough for the next step:* localize and measure the producer's
  `compile_book` pass memory, and separate it from target-runtime behavior.
- *Not enough for every stage:* no per-definition/per-module CPU, no live or
  retained memory, no C render/link stage detail, no source maps.
- *Not enough for incremental compilation:* no production cache, no serialized
  `CheckedProgram`/catalog, and no measured dependency fan-out or reuse ratio.

This note is documentation only. No run, benchmark, build, test, heap dump, or
live-process sample was performed for it.

---

## 1. Evidence identities and freshness labels

| Label | Meaning in this note |
|---|---|
| `[CURRENT-SOURCE]` | File identity is the current integration tree `f46ad0f6`; instrumentation code is present now. |
| `[CURRENT-RECEIPT]` | Receipt was produced from the current source hashes and is in this tree. |
| `[STALE]` | Receipt is real, but its pinned source/image predates the current tree or is an ancestor. It describes mechanisms and old magnitudes, not current certification. |
| `[PRIVATE-DIAG]` | Source-patched diagnostic; not production, not current, and not a performance claim. |
| `[CAPABILITY]` | Code exists, but the corresponding measurement was not exercised or retained. |

Current source identities used below:

- Tree: `f46ad0f6d363753229c52350eaec1474875c6623`
  (`evals: remove the array fact dump instead of faking its private hook`).
- `bend2/comp.ts` `a84170d5a84f21386383ccd478a1dac687eb664d89c21b284cd1134513963b70`
  (also the `compilerSha256` in the current C-only checkpoint
  `checkpoints/compiler-ir-checkpoint-v57aa.json`).
- `bend2/bend.ts` `6c1df3eb304fe085070aa4797928f70243b80d4635389e3d5d8a49fdfbb3051e`.
- `evals/native_compiler_experiment.ts`
  `17edfa3b448ed8f3115828006241e304b2deb76caeed6c5d6c49f7af210930a5`.
- `evals/native_compiler_host.c`
  `c9893207b2e8911b7bdf3608de7e99271d6fab0a9dbc2a0f5e3933157cb97e2e`.
- `evals/selfhost_cpu_profile.mjs`
  `09682b3127c7b8e5a2b857b6a4d1ae44d67406b80094fe6fd5c8b5f1f2819c7a`
  (unchanged since the v51-era helper; its retained evidence is still stale).
- `checkpoints/.bootstrap_compiler_root_v1.bend`
  `b0b92b67225c1b67972c9fe2a1096962a14926633508936c86d8b93b73cbd36b`.
- `evals/native_compiler_driver.bend`
  `768203e900f53cdf8d90b50966631ca3a3964dd50003658b07a28b39395f3ec3`.

The important distinction is between four different execution identities:

1. **Official TypeScript producer** building a native C selfhost binary
   (Node/V8 `book_load` → `book_valid` → `compile_book` → clang/link).
2. **Official TypeScript component builder** building a JS selfhost component
   (Node/V8 load/check → JS prepare/emit).
3. **Emitted native C selfhost binary** running its own parser/checker/emitter
   (native C allocator, `NATIVE_PHASE` records).
4. **Emitted JS selfhost compiler** running in Node/Bun
   (selfhost bootstrap worker, V8 inspector profiles).

A profile from one identity does not certify another. In particular, the v57aa
exact-allocation accounting is a diagnostic run of identity 3, not of the
identity-1 producer; the v51 phase profile is identity 4, not identity 1; the
57ab phase profile is identity 4 on an ancestor source.

---

## 2. Coverage matrix

Legend:

- **W/C** = wall and CPU. CPU may be process-wide or isolate-scoped; see notes.
- **S** = sampled CPU/function attribution (sampling interval, source mapping).
- **EA** = exact allocation-event counters.
- **SA** = statistical allocation sampling.
- **M** = live/retained/peak memory. `heapUsed` at a boundary is not automatically
  retained memory; `RSS`/`footprint` are process/whole-tree high-water unless a
  timeline is retained.
- **O/F** = observer/control and freshness.

### A. Building selfhost with the official TypeScript producer

| Stage | W/C | S | EA | SA | M | O/F |
|---|---|---|---|---|---|---|
| A0 prerequisites, protected pins, module import | Boundary timestamps and cumulative `process.cpuUsage` in `progress()` rows | none | none | none | `rssBytes`, `heapUsedBytes` at boundaries | Progress observer only; current source |
| A1 `book_load` root + bridge (parse/import) | `start`/`complete` rows and per-module rows; wall derivable from `unixMs`; cumulative process CPU | none | none | none | Boundary `rss`/`heapUsed`; no per-module peak | Low-volume synchronous event writes; current source |
| A2 `book_valid` (canonical checking: types, liveness/usage, declarations) | One `start` and one `complete` row with `elapsedMs`; cumulative process CPU at boundaries | none; `book_valid` calls `term_check` without an observer | none | none | Boundary `rss`/`heapUsed` only; no per-definition memory | No per-definition progress; current source |
| A3 `compile_book` preparation/reachability/fixedpoint | Pass start/end rows; wall derivable from `unixMs`; cumulative process CPU at boundaries; no recorded per-pass `elapsedMs` except whole `compile_book` complete | none (no CPU sampler) | none in production | none in production | `heapUsedBytes` per pass/definition/spin from `--trace-c`; not post-GC live; no peak between events | `--trace-c` observer is off by default, changes the run, and has no A/B overhead measurement; current source, but no committed completed trace receipt |
| A4 C emission per definition/spin | Same trace-c boundaries; no per-definition timer | none | none | none | `heapUsedBytes` and cache/fact sizes; no allocation sites | Same as A3; observer overhead unquantified |
| A5 C source publication/write/hash | `c-publication` start/complete timestamps; cumulative CPU | none | none | none | Boundary `rss`/`heapUsed` | Current source |
| A6 `clang` direct compile and link | `progress` start/complete; wall derivable; boundary process RSS/heap/cumulative CPU, but **no clang-specific CPU/RSS** | none | none | none | Boundary `rss`/`heapUsed`; guardian peak for the whole tree | Direct path has no `/usr/bin/time` per stage; current source |
| A7 `llvm-split` frontend/passes/codegen/link | Per-stage `wallMs`; `/usr/bin/time -lp` user/system/maxRSS; pipeline `elapsedMs` | none | none | none | Per-stage `maxRssBytes` (Darwin wait4) plus whole-tree guardian peak | Explicit diagnostic tradeoff; per-stage data exists only in this path; current source |
| A8 guardian | Whole-tree elapsed; 10 ms sampling in producer/build | none | none | none | Peak RSS + peak physical footprint for the whole process tree; no timeline. Darwin footprint charges compressed pages; Linux uses RSS+swap | Periodic safety monitor, not a hard quota; current source |

Consequences for A:

- The producer has **boundary wall/CPU and boundary heap/RSS**, plus optional
  per-definition heap/cache state during `compile_book`. It has no sampled CPU,
  no function attribution, no allocation counters, and no retained-memory
  measurement.
- `book_valid` is a black box between two progress rows. There is no
  per-definition check observation, no liveness/ownership counter, and no
  memory sample inside checking. The only definition count is the final
  `checkedDefinitions`.
- `compile_book` traces `prepare-before/after`, `release-after`,
  `c-reachability-before/after`, `c-pass-N-before/after`,
  `c-definition-before/after`, and `c-spin-before/after`; each row carries
  `heapUsedBytes` and cache/fact sizes, not a duration or CPU delta. See
  `bend2/comp.ts:1627-1648` and `bend2/comp.ts:3110-3155`.
- The guardian's peak is whole-tree and monotonic. A peak difference between
  two producer runs is **not** a live-byte difference for a stage.

### B. Running selfhost

| Stage | W/C | S | EA | SA | M | O/F |
|---|---|---|---|---|---|---|
| B0 bootstrap worker import | `mark()` boundaries; phase event has absolute start timestamp, `rss`, `heapUsed`, heap limit | only with `SELFHOST_CPU_PROFILE_DIR` | none | none | Boundary `rss`/`heapUsed` | Current source |
| B1 parse/import/fuel/oracle | Worker `stage-one-parse`/`stage-two-parse` marks; per-file oracle summaries have wall and process CPU | Oracle child is a separate Bun process with `--cpu-prof`; 1 ms sampling; whole-process profile incl. startup | none | none | Oracle boundary memory and maxima; the worker uses a lazy 8M-cell feedback chain, while the native target builds an eager chain and reports per-source RSS high-water separately | Profiling adds a separate oracle process; diagnostics only; current source |
| B2 template expand | `...-expand` mark; optional per-second step heartbeat with `chunkAdvances` and memory | optional 1 ms CPU profile; generated JS names, no Bend source map | none | optional 4 MiB heap sampling (if profiler enabled) | Boundary `rss`/`heapUsed`; sampled allocation includes collected objects | `profileRoot` wrapper adds step counters/heartbeat; no A/B |
| B3 signatures/body checking | `...-check` mark; same step heartbeat | optional 1 ms CPU; CPS continuations are partly anonymous | none | optional 4 MiB sampling | Boundary memory only; no per-definition or retained memory | `profileRoot` only; 57ab is stale |
| B4 FIR publication/rewind | No own mark; inside B3 or B7 depending on path | only as part of check/emit samples | none | optional only | no isolated measurement | `[CAPABILITY]`; the mechanisms exist but no stage boundary is observed |
| B5 lowering/catalog | No own mark; inside `emit_modules_start`/library emitter | only whole-emit samples | none | optional only | no isolated measurement | `[CAPABILITY]` |
| B6 NF/layout/sharing | No own mark; inside lowering/emission | only whole-emit samples | none | optional only | no isolated measurement | `[CAPABILITY]` |
| B7 JS render | `...-emit` mark; step heartbeat | optional 1 ms CPU | none | optional 4 MiB sampling | boundary memory only | current source, stale latest profile |
| B8 C render | Native C `emit-c` phase: wall, process user/system CPU, chunk advances | none (C target has no sampler) | none in production | none | no per-definition memory; guardian peak | current source; bootstrap lane does not exercise C emission |
| B9 link | `clang` command or `llvm-split` link stage | none | none | none | `llvm-split` maxRSS; direct path boundary process RSS/heap only | current source |
| B10 execution/bootstrap/fixedpoint/fixtures | stage-one/stage-two execute and fixedpoint marks; fixture child wall/CPU summaries | fixture child gets a separate CLI CPU profile; whole child process, no inner-phase attribution | none | none | boundary memory; guardian peak | Child profiling only when enabled; current source; latest full bootstrap is stale and timed out |

Consequences for B:

- In the bootstrap lane, expand/check/emit are the only coarse stages. FIR
  publication/rewind, lowering/catalog, NF, layouts/sharing, and render are all
  inside check/emit and have no individual timers. The step heartbeat counts
  opaque run chunks, not semantic operations or allocation.
- The C render/link path is not exercised by the bootstrap gate at all. The
  gate's own `cSurface` says `emissionExercised: false` and states that C
  behavior comes only from separate authenticated C fixture rows
  (`evals/selfhost_bootstrap_gate.ts:80-90`).
- The native target has a separate phase trace (`parse`, `expand`, `check`,
  `emit`, `emit-c`) with process `getrusage` CPU and chunk counts, but no
  per-definition or allocation attribution. CPU is `RUSAGE_SELF` process-wide
  (all compute threads), and the chunk count is an opaque 64-step advance, not
  a semantic operation count. See
  `evals/native_compiler_host.c:43,46-53,88-118,398-421`.

---

## 3. What the retained reports actually establish

### 3.1 v51: `checkpoints/compiler-profiling-quality-v51.json` `[STALE]`

Internal receipt hashes verify against the files in this tree:

- `compiler-phase-profile49-quality.json`
  `ebeef793fbffcc882a4d14b1b18eccfa03b02c69ffb395ebe78252c9a513e715`;
- `compiler-counter-profile49-quality.json`
  `cc72072c6f0e3b2097909c12288d0104ee83babe59cc08c671dfb697ddf5344b`;
- `compiler-counter-profile49-quality-final.json`
  `4f714f99696631712af9a419b59bb51b714c21b5034ada47c58f0d4da381ab6e`.

It is honest about scope, but its measured identities are old:

- compiler image `28061d5e…` from source `7c33172b`/`0441c4dd`;
- Linux x64, Node `23.11.0`, V8 `12.9.202.28-node.14`;
- full 50-file/15-module/7720-export workload, actual output import and semantic
  smoke, byte comparison PASS.

What it measures:

- **Phase wall and process CPU** for startup, load-parse, expand, check, emit,
  write/hash, output import, and output smoke.
- **Worker-isolate CPU profiles** at 1 ms, with per-phase denominators. The
  old whole-worker profile covers startup+parse+expand+check, not check only;
  the later phase-isolated receipt does separate the phases. This is why both
  facts can be true at once: the old audit is whole-worker, the phase receipt
  is phase-marked.
- **Statistical allocation** with a 4 MiB sampling interval, including
  objects collected by minor and major GC. The receipt explicitly says this is
  an estimate, not exact bytes/counts, and not live/RSS/retained memory.

Representative phase values in `compiler-phase-profile49-quality.json`:

| Phase | Instrumented wall | Process CPU | Worker sampled | GC sampled | Estimated allocated |
|---|---:|---:|---:|---:|---:|
| load-parse | 5,821.7 ms | 8,968.0 ms | 5,844.0 ms | 913.7 ms | 10.72 GB |
| expand | 3,915.6 ms | 5,039.9 ms | 4,067.5 ms | 199.6 ms | 10.07 GB |
| check | 100,887.3 ms | 118,503.0 ms | 101,047.5 ms | 3,431.2 ms | 172.14 GB |
| emit | 13,278.0 ms | 17,606.8 ms | 13,667.7 ms | 697.7 ms | 21.95 GB |

Process CPU can exceed wall time because it covers the whole process, including
helper/concurrent V8 threads. Read the 172.14 GB as **cumulative sampled
allocation**, not live memory and not a source-byte proportion. The check allocation findings estimate 22.1% of
sampled check bytes at Map-family sites, and individual heap stacks at Map,
`checker_arena.get_node.result`, and substitution wrappers; those are
allocation-site estimates, not CPU ownership. The report itself says allocation
percentages are not CPU percentages (`architectureAssessment`).

Observer quality and limits:

- A/observer/A overhead applies to the `90be889d` observer, **not** to the
  final `18cc49be` persistence guard. For the measured observer: compile
  +11.66% vs before and +6.23% vs after; check CPU +9.53%/+2.53%; baseline drift
  between normal runs was already 5.1%. The report says the ratios are
  descriptive, not a confidence interval or a noise-corrected causal estimate.
- Small phases are observer-dominated: write-and-hash sampled 636.7 ms against
  a 221.9 ms helper wall.
- CPU self attribution can fold inlined work into callers; allocation sites and
  real call stacks are complementary, not proof of isolated causal cost.
- Exact CPS counters are exact event counts with balanced denominators, but
  sampled callback attribution covers 99.9% direct and only 46.4% resume; the
  unattributed 53.6% of resume samples is a logical-attribution gap.
- `process.cpuUsage` is whole-process; inspector CPU is worker-isolate; cgroup
  CPU is the guarded tree. These are three scopes and cannot be added.

**Verdict for v51:** high-quality *for phase ranking on that old image*, not for
per-stage optimization and not for current source. Its explicit limitations are
consistent with its fields, so the report is trustworthy within its scope.

### 3.2 v57aa: `checkpoints/compiler-ir-profile-v57aa-allocations.json` `[PRIVATE-DIAG]`

This is the only retained *exact allocation-event* evidence, and it is not a
current producer profile.

What is actually measured:

- A private source-generated diagnostic patching `bend2/comp.ts` and
  `evals/native_compiler_host.c`; base compiler `9704b4bb…`, diagnostic
  compiler `477ddb81…`, host `09586c43…`.
- Scope: `W/noCursor + approved9704 compiler, private source-generated
  cumulative actual native allocator accounting; NOT latestY`.
- `allocationTotals.checker`: 8,108,942,647 requests; 4,982,047,519
  constructor-tagged and 3,126,895,128 untagged; 8,097,573,071 frees; 366,452,577
  spare reuses; 413,617 misses. The identities reconcile
  (`local freelist hits + misses = all requests`;
  `constructor + untagged = all requests`).
- Phase split: `other`, body-inference, termination, affine-usage, and
  publish-and-type-finishing; phase markers are source-entry-delimited.
- Exact events are **cumulative requests/frees**, not OS malloc, not live nodes,
  not lifetimes, not peak payload, and not CPU. The report says all of this in
  `limits`.
- The last field `retention` says no generated assets were committed; the
  private namespace is `/private/tmp/native-alloc57z...`, so the raw evidence is
  not in this tree.

What is not established:

- There is no explicit `valid`/`overflow` boolean in the packet, only the
  instrumentation policy that counters are checked `u64` and overflow invalidates
  the report. Validity therefore rests on the reconciliation and absence of an
  overflow failure, not on a separate field.
- The 60.4% "Pending + ArenaResult class word share" is a share of rounded
  request words. It is **not** 60% of CPU, RSS, or achievable memory saving.
  The report's `decision` says exactly this and calls the source fix a proposal,
  not an implemented or timed optimization.
- It is not the current compiler: `performanceWinClaim:false`,
  `nativeBinaryFixedpointClaim:false`, and it is derived from the `9704b4bb`
  base, not from `a84170d5`.

**Verdict for v57aa:** credible *cumulative allocator accounting for that private
native target run*, with unusually explicit limits. It does not measure live
memory, does not measure the TS producer, and does not justify an RSS/CPU
optimization by class-word share.

### 3.3 57ab root phase profile: `evals/selfhost-root-phase-profile-57ab.json` `[STALE]`

This is the most useful retained *running selfhost* phase profile, but it is
source-pinned before the current tree:

- branch `work/fir-nf-combined57ab`, head `d47f859b`;
- current integration is `f46ad0f6`; `d47f859b` is an ancestor, 130 commits
  behind; the `d47f..f46` diff for the compiler/selfhost/native files is
  +10,751/−1,596 lines (including a 2,857-line root rewrite and C backend
  additions);
- component `8935d503…`; no current root hash; raw worker profiles were under
  `/tmp/prof57ab/...` and are not committed.

Its measured phases (profileRoot mode, no fixture suites, no stage two):

| Phase | Wall | Process CPU | Notes |
|---|---:|---:|---|
| root parse (oracle) | 45,055 ms | — | includes the separate parser-oracle child |
| expand | 6,265 ms | 6,737 ms | |
| check | 162,580 ms | 174,625 ms (user 170,441 / sys 4,184) | dominant phase, 72.4% of total wall |
| emit | 7,069 ms | 8,835 ms | |
| stage-one execute | 450 ms | — | |
| total | 224,652 ms | — | |

The receipt explicitly corrects an earlier mistake: phase marks are **starts**,
so the interval said to be emit (167.9 s) was actually check+expand; emit is
about 7 s. Any reuse of this receipt must preserve that correction.

Check self-time shares from the derived summary: anonymous continuation
closures 25.9%, `checker_chunk` 9.5%, `checker_step_one` 8.3%,
`checker_step` 8.1%, GC 7.1%, `index_lookup` four frames 6.8%, `Map.get` 3.1%,
`f` 2.6%; CPS step machinery 54.5%. These are sampled self-time shares, not
logical CPU ownership; generic CPS attribution cannot by itself prove
duplicated producer work or a source regression. There is no matched current
baseline; the companion aggregate was `FAIL/deadline_exceeded` at 600 s.

**Verdict for 57ab:** good directional evidence that check is the cost center
and CPS dispatch/continuations are the largest sampled block *on that source*.
It does not certify current `f46ad0f6` and does not give per-definition costs.

### 3.4 Current receipts that bound the picture

- **Current component build** `checkpoints/root-sharedem-rep.result.json`
  `[CURRENT-RECEIPT]`: source root `b0b92b…`, compiler `a84170d5…`, artifact
  `fcd8cca2…`, 11,134 checked definitions, 11,682 validated events, 16,789,267
  bytes, total elapsed 38.6 s, CPU 53.85 s, guardian peak 3,193,372,672 B RSS /
  3,275,034,072 B physical footprint. The `metrics.json` explicitly says
  aggregate RSS/footprint is externally sampled and per-phase footprint is not.
  This proves the current root can be loaded, fully checked, and emitted to JS
  under the 3,072 MiB configured V8 heap limit in that lane; the 3.19 GB peak
  RSS is not a heap measurement. It is not the native C producer and it
  does not include the bridge closure.
- **Current-ish C producer on an older root** `checkpoints/compiler-ir-checkpoint-v57aa.json`
  `[STALE for root: efab3bf8…]`: compiler `a84170d5…`, 8,408 checked
  definitions, 8,810 validated events, C codegen 83.26 s, build elapsed 86.78 s,
  guardian 159.03 s, peak 4,933,943,296 B RSS / 4,817,213,200 B footprint,
  artifact `53a56203…`. This shows the current compiler can produce a native C
  artifact for a smaller root under the 8 GiB guardian. It does not certify the
  current 11k-body root.
- **Latest full bootstrap receipt in the tree** `checkpoints/root13-gate-b.json`
  `[STALE for root: 8dea7504…]`: FAIL, `deadline_exceeded` at 600,039 ms, peak
  2,838,380,544 B RSS / 3,658,664,416 B physical footprint, 4,101 events, 168
  parse rows, 95 fixture rows, stage-one artifact 21,026,704 bytes; stage two
  did not complete and there is no fixedpoint comparison. C emission was not
  exercised (`cSurface.emissionExercised:false`). This is a time failure, not
  the producer OOM.
- **Current producer OOM facts** `[CURRENT-RUN TRACE, /tmp, NOT COMMITTED]`:
  the deduplicated `f46` run has 11,164 checked native-bridge definitions and a
  887,221-row trace at
  `/tmp/n13-emit-run/native13-build-b.json.c-events.jsonl`. A read-only sibling
  analysis of that trace reports:
  - book after `book_valid`: **1,592.5 MiB** (`1,669,811,048 B`) for 11,164
    checked definitions;
  - `FL` analysis adds **401.7 MiB** over the book right after reachability;
  - per-pass maximum sampled `heapUsed`: **2,856.2 / 2,894.6 / 2,941.6 /
    2,987.6 / 3,027.9 / 3,033.7 MiB** for passes 1–6;
  - lowest sampled `heapUsed` within each pass: **1,993.5 / 2,044.3 / 2,096.9 /
    2,140.6 / 2,191.1 / 2,240.3 MiB**; 95 rows show drops greater than 20 MiB,
    with a maximum intra-pass drop of about **778 MiB**;
  - `segments` 47,534, stable from pass 1 after; 42,393 at the death row;
    `spins` 5,806; death-row memos: opens 339, uses 2,128, folds 100, spines 592,
    steps 95,441;
  - harness pre-book retained state: 13.27 MiB.

  The run reaches `compile_book` pass 6 and ends OOM with no native artifact.
  These values are not a retained receipt in this tree and must not be cited as
  one. The body count is not a duration, a per-pass maximum is not post-GC live
  memory, and the event count is not a CPU sample count.

---

## 4. The producer OOM: what is and is not proven

**What is proven:**

- The current failure is in the official TypeScript producer path
  (`book_load`/`book_valid`/`compile_book`), before a native artifact exists.
  It is not evidence that the emitted C target fails semantics.
- The C target path itself has successful independent receipts: v57aa's native
  C cycle built, ran the frozen corpus, and passed an unchanged consumer
  (build 174.4 s, run 87.1 s, consumer 0.85 s in `currentYNativeCycle`; peak
  build RSS 4.75 GB in that receipt). That does not certify the selfhost
  bootstrap target, but it contradicts a blanket "the C target is broken"
  reading.
- The producer has a 3,072 MiB V8 old-space limit and an 8 GiB whole-tree
  guardian. These are different limits. A V8 heap OOM is not a guardian
  `RESOURCE_LIMIT`. The current run facts say OOM, not which limit, so the
  binding limit is unresolved.
- The sibling read-only analysis of the current trace gives a real, but
  sample-based, pass trend:

| Pass | Max sampled `heapUsed` | Lowest sampled `heapUsed` |
|---|---:|---:|
| after `book_valid` | 1,592.5 MiB | — |
| right after reachability | +401.7 MiB over book | — |
| 1 | 2,856.2 MiB | 1,993.5 MiB |
| 2 | 2,894.6 MiB | 2,044.3 MiB |
| 3 | 2,941.6 MiB | 2,096.9 MiB |
| 4 | 2,987.6 MiB | 2,140.6 MiB |
| 5 | 3,027.9 MiB | 2,191.1 MiB |
| 6 | 3,033.7 MiB | 2,240.3 MiB |

  The maxima rise monotonically toward the 3,072 MiB configured heap; 95 rows
  show drops greater than 20 MiB, with a maximum intra-pass drop of about
  778 MiB. The
  book-plus-reachability numbers are internally consistent
  (1,592.5 + 401.7 ≈ 1,994.2 MiB vs. pass-1 lowest 1,993.5 MiB), which supports
  the trace's scale but not causality. This is enough to say the run is under
  sustained near-limit heap pressure across passes. It is **not** enough to say
  which pass or allocation caused OOM: the observed maximum is a sampled
  `heapUsed`, not a post-GC live set, and the sample can miss the actual peak.

**What is not proven:**

- There is no post-major-GC live heap and no measured true peak for the OOM
  run. The rising lowest-observed floor (1,993.5 → 2,240.3 MiB) could be live
  growth, uncollected garbage, or both; the trace does not distinguish them.
- There is no proof that adding 86.3 MiB (the configured space unused at
  failure), or any other small amount, would let the build complete. That
  number is **headroom at failure**, not a measured deficit and not a minimum
  saving. The failing allocation size and old-space layout are unknown, so the
  required reduction is unknown.
- Do not add per-pass increments from a floor plus a total peak: that
  double-counts shared high-water and observer/GC state. Do not subtract peaks
  to obtain live bytes, and do not turn a `heapUsed` drop into proof of a major
  GC.
- Heap drops between trace rows are not proof of a major GC or of reclamation;
  `heapUsed` can fall after minor collections, allocator behavior, or observer
  serialization, and no GC trace/GC callback is recorded.
- The old peer hypothesis that `FL.funs[d].h` retains a third body copy is
  wrong. `FL.funs` retains `Fun` metadata (`n`, `live`, lazy `lays`/`ret`) and
  a getter; `get h()` calls `file_higher` on demand
  (`bend2/comp.ts:1416-1441`), while `file_higher` uses `FL.higher`, which is
  cleared per definition and by `file_release` (`bend2/comp.ts:1645-1682`).
  `hExists`/`retainedHigher` in trace rows therefore describe the current cache,
  not a retained body triple.
- Residual `ownFacts` after pass 3 are reported by the current investigation to
  be largely the handwritten `c_backend_sharing` surface (about 441
  definitions). That is a **hypothesis about an ownership/dependency wave**, not
  a measured per-fact cause. Do not claim per-fact causality from the trace.
- Source bytes are not a causal memory model. The native `sourceBytes` field is
  input metadata; the trace's per-definition state is not proportional to source
  bytes. Neither v51 nor v57aa supports a source-byte-proportion causal claim.
- A high-water difference between the JS component build (3.19 GB) and the C
  build (4.93 GB on an older root) is not a live-byte difference and is not a
  per-pass budget.
- No per-module or per-object retained bytes are measured. "Cost per pass"
  cannot be derived by adding the floor rise to the total peak rise; that
  double-counts.

**What would settle byte attribution (advisory; no code change now):**

- Observe-point byte sizes for `FL.segs` lines, `FL.spins`, `FL.funs` metadata,
  `FL.higher`, `FL.ids`/`taken`, `FL.nodes`/`lays`/`paks`, per-definition memo
  map sizes, and `PROBES.length`.
- An explicit post-major-GC marker (V8 GC callback or heap-snapshot count) so
  "floor" means post-full-GC rather than "smallest value seen since the last
  trace row".

Without those, only aggregate `heapUsed` and its trend are defensible. This is
especially important because `comp.ts` is immutable under the current freeze;
these are future measurement proposals, not an authorization to edit it.

**What the evidence supports now:**

1. Treat the producer's `compile_book` whole-book pass/definition allocation and
   retention as the immediate investigation target, not the target runtime.
2. Compare variants that isolate the bridge and the C-emission path from the
   root-only check/JS path, because the current root-only component build passes
   at 11,134 definitions while the bridge producer OOMs.
3. Use a bounded pass-boundary diagnostic that separates post-GC live heap from
   cumulative allocation and records the true peak; do not add more counters
   until that distinction exists.
4. Do not choose a source optimization from the v57aa class-word share, the
   v51 allocation percentages, or the 57ab stale CPS shares.

**What the evidence does not support:** raising the heap by an arbitrary small
amount, switching to LLVM/MLIR, attributing the OOM to GC, attributing it to a
single pass/definition, or concluding that checking the root is impossible.

---

## 5. Running selfhost: confidence by stage

| Area | Confidence | Why |
|---|---|---|
| Check dominates the profiled 57ab mode | Medium-high for `d47f859b`; low for current | 162.6 s of 224.7 s, 54.5% CPS sampled machinery; stale source, derived summary only |
| CPS dispatch/continuations are the top sampled block | Medium | 25.9% anonymous continuations + step/chunk shares; sampling folds inlines, no source map, no matched baseline |
| Expand/emit are small in that mode | Medium | 6.3 s / 7.1 s; phase marks and corrected labels |
| FIR publication/rewind cost | Low/none | no stage boundary; only inside coarse check/emit |
| Lowering/catalog cost | Low/none | no stage boundary; only inside emit |
| NF/layout/sharing cost | Low/none | no stage boundary; only inside emit |
| JS render cost | Low | coarse emit only |
| C render cost | Low | native `emit-c` phase only; bootstrap lane does not run it |
| Link cost | Low/medium | direct path has no stage receipt; `llvm-split` has per-stage time/RSS |
| Bootstrap end-to-end time | Medium for old roots | `root13-gate-b` timed out at 600 s; current root not run to completion |
| Fixture execution | Medium | per-child whole-process CPU profile; no inner-phase attribution |
| Memory by stage | Low/none | boundary `heapUsed`, whole-tree peak; no live/retained per stage |

The root13 timeout and the 57ab profile are not contradictory: 57ab is a
diagnostic root-only profile that stops before stage two/fixtures; root13 is a
full bootstrap attempt that ran out of time. Neither is a current full-green
measurement.

---

## 6. Incremental compilation: how hard, from the actual data structures

The current system has no production incremental compiler. It has one
development-only prefix checker and one diagnostic parse cache.

### 6.1 What exists

- `book_valid(book, done)` skips `term_check` for declarations before `done`
  but still reloads the whole book and reconstructs `book.tlds` with
  `v:null`; it assumes the prefix is valid (`bend2/bend.ts:3804-3860`).
  `evals/parser_full_target_check.ts:1-38` uses it for prefix/slice development
  validation, not for a persistent cache.
- The only parse cache is `diagnosticCache` for `--fixture` seed-parser runs; it
  is explicitly disabled for every full bootstrap boundary
  (`evals/selfhost_bootstrap_gate.ts:64,190`).
- `CheckedProgram` is an affine owner of `source:Arena`, modules, signatures, and
  metadata (`bend2/selfhost/checked_frontend.bend:13-25`). There is no
  serialization/deserialization path; the component build's own boundary says
  `nativeRetention: ... no serialization or source-value fallback`.
- Semantic handles are arena-local `U32`s. `Scope.ArenaGlobal` stores both
  `ty:U32` and `value:IR.OptionalTerm`, so a signature is not the only
  cross-module fact that can affect normalization
  (`bend2/selfhost/scope_lookup.bend:17`).
- `ModuleMetadata.scope` is constructed from accumulated globals
  (`bend2/selfhost/checked_frontend.bend:14`), and lowering consumes those
  metadata/globals (`lower_catalog.bend:1192-1464`).
- Lowering assigns sequential `next_code`/`next_constructor`
  (`lower_catalog.bend:28,39,1202,1251,1342`). Descriptor NF builds whole-family
  and type-function indexes (`descriptor_nf.bend:117,147`) and is used by both
  lowering and C layout (`descriptor_nf.bend:1-11`).
- The C producer's fixedpoint is whole-book: `compile_book` loops until
  `own + hot + stat` stops changing, clears per-pass segment/spin caches, and
  emits definitions in reverse order (`bend2/comp.ts:3110-3155`). `FL.higher`
  and memo caches are released per definition
  (`bend2/comp.ts:1645-1682`).

### 6.2 Difficulty by layer

| Layer | Difficulty | Why |
|---|---|---|
| Parse cache | Low, low payoff | A diagnostic cache already exists; parse is substantial in 57ab but the cache is fixture-only and does not address checking/emission |
| In-process re-check of unchanged modules | Medium | Requires a module dependency graph, stable per-module signature/metadata fingerprints, and a valid prefix; `book_valid(done)` is only a prefix skip, not a cache |
| In-process re-emit / lowering reuse | Medium-hard | Lowering numbers and NF/layout/sharing facts are global; a small edit can renumber constructors/codes and change abstract normalization of unchanged descriptors |
| C emission reuse | Hard | `compile_book` fixedpoint, reachability, FID/symbol numbering, and C output are whole-book; producer OOM is in this path |
| Cross-process/persistent incremental build | Very hard | Requires serializable checked IR, stable IDs across arenas, deterministic layout/catalog/render, and invalidation that includes signatures, metadata values, NF families, and layouts |

There is no evidence in the reports for a reuse ratio, a cache-hit rate, or a
compile-time saving. The only defensible statement is: **incremental
compilation is a design problem in semantic invalidation and deterministic
numbering, not just file-hash caching.** In difficulty terms, parse caching is
low/medium, in-process re-check/re-emit is medium to medium-hard, and a
persistent incremental build is hard to very hard. "How hard" in schedule or
payoff cannot be estimated responsibly until per-module/definition cost and
dependency fan-out are measured.

### 6.3 What would change the incremental decision

- Per-definition/per-module check and emit cost on the current tree.
- Count of downstream signatures/metadata/NF/layout facts changed by a
  one-module edit.
- Whether a module's bodies can affect type normalization through
  `ArenaGlobal.value` even when its signature is unchanged.
- Whether a stable output can be produced without renumbering all C IDs.
- The cost of the full parse/check versus the reusable prefix.

Until those exist, the correct next step is a measurement/design probe, not a
cache implementation.

---

## 7. Minimum useful follow-up tasks

These are deliberately bounded. Each is one diagnostic run or one offline
analysis; none is a new telemetry platform.

### T0 — Independently re-derive the existing 887,221-row trace (no run)

- **Input:** `/tmp/n13-emit-run/native13-build-b.json.c-events.jsonl` and its
  `REPORT.events.jsonl`/report, if Main can retain them.
- **Do:** independently reproduce the sibling table: per-pass max/min
  `heapUsed`, event counts, 95 rows over 20 MiB, maximum drop about 778 MiB,
  pass/definition counts, and whether `c-pass-6` is the death row. Derive wall
  only from first/last `unixMs`; do not compute CPU from event counts.
- **Output:** one table per pass with sample count, first/last/max/min heap,
  wall, and explicit "unknown: true peak, post-GC live, allocation site, CPU"
  columns. State whether the trace ends inside a pass.
- **Stop rule:** if the trace lacks pass boundaries or the final rows, report
  that and do not infer a pass cause. If the sibling table cannot be reproduced,
  treat all per-pass numbers as unverified.

### T1 — One pass-boundary producer memory diagnostic

- **Purpose:** distinguish post-GC live heap, cumulative allocation, and true
  peak at `compile_book` pass boundaries, and identify whether the failure is
  old-space exhaustion, fragmentation/large-object failure, or something else.
- **Shape:** a private diagnostic copy of the producer only; one bounded run
  under the existing guardian. At each `c-pass-N-before/after`, at the end of
  `book_valid`, and immediately before/after `compile_book`, force one full GC
  (only if the diagnostic is authorized to do so) and record `heapUsed`,
  `heapTotal`, `external`, `arrayBuffers`, RSS, `performance.now()`, process CPU,
  and the configured heap limit. Keep the regular run's artifacts untouched.
- **Optional byte attribution, if authorized:** observe-point byte sizes for
  `FL.segs` lines, `FL.spins`, `FL.funs` metadata, `FL.higher`, `FL.ids`/`taken`,
  `FL.nodes`/`lays`/`paks`, per-definition memo map sizes, and `PROBES.length`;
  plus an explicit post-major-GC marker (V8 GC callback or heap-snapshot count).
  This is the minimum that makes "floor" mean post-full-GC rather than
  smallest-observed-since-last-row.
- **Acceptance:** a per-pass table that answers whether the run is at the V8
  heap limit before the guardian, whether the true peak is between events, and
  which of the observed byte owners changed across passes. If the diagnostic
  cannot distinguish those, stop; do not add more counters.
- **Do not:** add per-definition event streams, repeat runs, or use the result
  as a normal benchmark. Do not edit `comp.ts` under the current freeze; this
  task requires explicit authorization and a private diagnostic copy.

### T2 — One current-tree selfhost profile with the existing helper (no new code)

- **Shape:** `SELFHOST_CPU_PROFILE_DIR=<fresh> bun --smol
  evals/selfhost_bootstrap_gate.ts ... --profile-root=true --report=<fresh>`
  with the current accepted component/parser/root inputs. This uses the
  existing 1 ms CPU + 4 MiB allocation helper and the existing phase marks.
- **Acceptance:** retain raw `*.cpuprofile`/`*.heapprofile` plus phase summaries;
  report per-phase wall/process CPU/worker CPU/GC/allocation and top self-time
  functions; state phase sample coverage and whether check still dominates.
- **Stop rule:** if raw profiles are not retained or source pins do not match
  the report, do not use the result for current claims.

### T3 — Conditional stage marks around the missing B stages

Only if T2 leaves FIR/rewind, lowering/catalog, NF/layout/sharing, or render
ambiguous. Add diagnostic-only marks at those boundaries in the existing
component/worker path, one run, then remove them. Do not add production
telemetry or per-definition event streams.

- **Acceptance:** non-overlapping wall/process CPU for each marked stage, with
  the same source pins and guardian. If a mark cannot be placed without changing
  semantics or ownership, report that and stop.

### T4 — Incremental boundary probe (design measurement, not a cache)

- **Shape:** one small harness over the current book: record module hashes,
  declaration order, signatures, metadata, and the lowering/NF/layout facts for
  a full build; change one module; record which of those facts change and which
  definitions would need rechecking/reemission. Use the existing prefix API only
  as a comparison, not as a cache.
- **Acceptance:** dependency fan-out counts and a changed-fact set for at least
  one real edit. No compile-time saving claim.

### T5 — Optional C backend stage profile

Only if the C build (not the target runtime) is the chosen optimization target.
Use the existing `llvm-split` path, which already records per-stage `/usr/bin/time`
user/system/maxRSS and wall. Do not add C function sampling or source maps for
this decision.

---

## 8. Confidence, limits, and what would change the answer

**High confidence**

- The producer and target runtime are different identities; a producer OOM is
  not target-runtime evidence.
- The producer's `book_valid` has no per-definition observation; `compile_book`
  has optional per-definition heap/cache state but no per-definition CPU or
  allocation counters.
- The running selfhost path has coarse expand/check/emit stages only; FIR,
  lowering, NF, layouts, sharing, and C render/link are not separately measured.
- The retained v51/v57aa reports are internally honest and explicitly bounded;
  their evidence is stale or private-diagnostic relative to `f46ad0f6`.
- Incremental compilation is not supported by any current cache/serialization
  path; `book_valid(done)` is a prefix skip, not a cache.

**Medium confidence**

- Check is the dominant cost in the profiled 57ab mode (stale source).
- CPS dispatch/continuations are the top sampled block in that mode.
- The current producer's OOM is in `compile_book`/C emission rather than
  `book_valid`, because the run reaches `c-pass-6`; this is based on current run
  facts, not a committed receipt.
- The current trace's sampled pass maxima rise from 2,856.2 to 3,033.7 MiB
  toward the 3,072 MiB configured heap, with a rising lowest-observed floor
  from 1,993.5 to 2,240.3 MiB; this establishes near-limit pressure, not a
  cause or a required saving.

**Low confidence / unknown**

- True peak and post-GC live memory of the OOM run.
- Which limit failed (V8 old-space vs guardian vs fragmentation/large object).
- The failing allocation size and old-space layout at OOM.
- Per-pass, per-definition, per-module CPU or allocation.
- Whether the 86.3 MiB headroom at failure means any particular small increase
  or decrease would alter the outcome.
- Whether incremental checking/emission would pay off, and how much.

**What would change the conclusion**

- A committed/retained current producer trace with pass-boundary post-GC live
  heap, true peak, and allocation sites would turn the OOM from a localization
  into a cause.
- A current-tree profile with raw CPU/heap profiles and retained phase summaries
  would replace the stale 57ab shares.
- A per-module/definition dependency measurement would make an incremental
  estimate possible.
- A successful current 11k-body C build receipt would move the producer out of
  the "blocked" category; no such receipt is in this tree.

---

## 9. Source and receipt index

Local source anchors (current `f46ad0f6`):

- `bend2/comp.ts:134-147` observer state shape; `:1627-1648` `file_observe`;
  `:3110-3155` `compile_book` observe/pass loop; `:1416-1441` `fun_of`/`h`
  getter; `:1645-1682` `file_higher`/release.
- `evals/native_compiler_experiment.ts:149-155` progress row (RSS, heapUsed,
  cumulative CPU); `:181-223` book load/valid/compile; `:224-238` publication;
  `:258-277` clang/llvm-split; `:370-395` guardian.
- `evals/native_compiler_host.c:43,46-53` phase CPU/RSS helpers;
  `:88-118` `NATIVE_PHASE`; `:267-280` fuel RSS high-water;
  `:398-421` begin/parse phases.
- `evals/selfhost_cpu_profile.mjs:33-70` profiler creation, 1 ms CPU, 4 MiB
  allocation, collected objects, worker/process scopes.
- `evals/selfhost_bootstrap_worker.mjs:34-37` `mark()`; `:193-205`
  `profileSteps` heartbeat; `:219-225` expand/check/emit; `:334-349`,
  `:378-417` bootstrap phases.
- `evals/selfhost_bootstrap_gate.ts:64,190` diagnostic cache scope;
  `:408-454` phase/event handling; `:80-90` C surface not exercised.
- `evals/selfhost_parser_parity.ts:86-170` profiled oracle child, boundary
  memory, 1 ms CPU, whole-process scope.
- `bend2/selfhost/checked_frontend.bend:13-25` affine `CheckedProgram`;
  `bend2/selfhost/scope_lookup.bend:17` `ArenaGlobal` type+value;
  `bend2/selfhost/lower_catalog.bend:28,39,1192-1464` catalog/preparation and
  sequential IDs; `bend2/selfhost/descriptor_nf.bend:1-11,117,147` global
  NF context; `bend2/selfhost/checker_arena.bend:77-91,1297-1302` rewind.
- `bend2/bend.ts:3804-3860` `book_valid(book, done)`;
  `evals/parser_full_target_check.ts:1-38` prefix development use.

Retained reports and hashes:

- `checkpoints/compiler-profiling-quality-v51.json`
  `543a574734d9c1e0c26f4150a19f4ab8e18175812dedee0c9631789a67655e2b`
  `[STALE]`; phase receipt `ebeef793…`, counter controls `cc72072c…`, final
  observer `4f714f99…`.
- `checkpoints/compiler-ir-profile-v57aa-allocations.json`
  `d666f542500f0056762b08e135718a596dc9d504a9c322a70b4d68f1e43efce6`
  `[PRIVATE-DIAG]`.
- `evals/selfhost-root-phase-profile-57ab.json`
  `7a74bcee2a4e1fc28dd89a62a2c25f5d3d722806c3b3823cc3fef25ba38036cd`
  `[STALE: d47f859b]`.
- `checkpoints/compiler-ir-checkpoint-v57aa.json` `[STALE root, current
  compiler]`; `checkpoints/root-sharedem-rep.result.json`
  `[CURRENT-RECEIPT, component JS]`; `checkpoints/root13-gate-b.json`
  `[STALE root, full bootstrap timeout]`; `checkpoints/native43-phase-profile.json`
  `[STALE, trace-c off/old]`.
- Current producer trace (not committed):
  `/tmp/n13-emit-run/native13-build-b.json.c-events.jsonl`, 887,221 rows,
  plus its `REPORT.events.jsonl`; the per-pass table above is a read-only
  sibling analysis of that trace and must be re-derived before being treated
  as a receipt.

No claim in this note treats a source file or observer option as a completed
measurement. In particular:

- `--trace-c` exists, but it is off by default, the last committed trace-c
  receipt (`native43-phase-profile.json`) timed out at 90 s before completion,
  and the current 887,221-row trace is not a committed receipt.
- `SELFHOST_CPU_PROFILE_DIR` exists, but no current raw profiles are retained in
  this tree.
- `checker_core_component_build.ts` has an optional allocation-profiling path,
  but the current `root-sharedem` receipt did not exercise it (no
  `.allocation-profile.json`).
- v57aa's exact allocator counters exist only in a private diagnostic patch, not
  in current production source.
