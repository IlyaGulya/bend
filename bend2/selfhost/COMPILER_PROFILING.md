# Opt-in compiler profiling

This is a diagnostic collector for the official TypeScript compiler producers.
It is not an acceptance signal, a benchmark, a fixedpoint proof, or a claim
that every stage is covered. Ordinary runs do not import it and do not write
profile files.

## Fast development checks

Do not run parser admission, LLVM and the complete fixture matrices for every
producer hypothesis. Use three levels, without narrowing final acceptance:

1. Run the changed-path consumer first: emitted JS must load and execute;
   changed C paths must compile with clang and execute. Keep dependent fields,
   ownership/capture and foreign/export cases relevant to the change.
2. Probe the same frozen full root, with complete canonical loading and
   validation, but stop after a small number of C passes. Compare pass time and
   ownership/hot/static fact progression before paying for convergence or LLVM.
3. Only promising candidates run fresh complete parser/root admission, native
   build, both full backend matrices and stage1/stage2 byte comparison.

```bash
BUN_JSC_forceRAMSize=4294967296 bun evals/compiler_codegen_probe.ts \
  --memory-mib 8192 --rss-mib 8192 --poll-ms 10 --timeout-ms 180000 \
  --root=checkpoints/.bootstrap_compiler_root_release2039g8r3.bend \
  --bridge=evals/native_compiler_driver.bend \
  --report=/tmp/codegen-probe.json --passes=2 --max-codegen-ms=120000
```

The report must be fresh. `CODEGEN_PROBE` events and atomic checkpoints update
at phase/pass boundaries and at most once per second between boundaries.
Stopping uses the existing compiler observer, at the next observable boundary,
not repeated external status polling. It uses the shared observer adapter
without creating a full collector: no inspector, per-definition serialization
or heap-statistics snapshots. The report records cumulative process CPU
(all threads, excluding child processes), host CPU count/load and input hashes.
The external guardian remains the hard memory/deadline boundary. `--bridge`
explicitly adds a second validated root; omit it for a standalone program.

`PROBE_STOPPED` is a deliberate diagnostic cutoff, never a semantic failure,
completed compilation or PASS. `CODEGEN_SETTLED` means codegen returned within
the probe budget, not compiler acceptance. Neither status publishes an image,
runs LLVM or establishes a byte fixedpoint. An unchanged or slower progression
can reject a performance hypothesis early; a better progression only earns the
full gates. Do not reuse old proofs after their authenticated inputs change.

Compare performance only on an uncontended host; the report flags load
above the logical CPU count rather than silently attributing host contention
to the candidate. Load is context, not a CPU-utilization or slowdown estimate.
The codegen budget is cooperative: long work between observer callbacks can
overrun it; the guardian's total deadline still terminates the owned tree.

`evals/receipts/compiler_codegen_probe_verified.json` records the exercised
failure, first-pass cutoff and settled-codegen CLI paths, plus a real full-root
time cutoff after validating all 12,071 bodies / 12,651 events. That full-root
run stopped cooperatively after 65.5 s of codegen (73.8 s guarded total), with
no compiler image. These are diagnostic observations, not acceptance or a
controlled performance comparison.

## Collector

`evals/compiler_profile.mjs` exports:

- `createCompilerProfile({directory, execution, rawDetail?, sampling?})` — async
  factory; creates a fresh `profile-*` run directory under `directory`.
- `profile.begin(name, details?, {sample?})` — returns an opaque token.
- `profile.end(token, status?, details?)` — strict nesting; statuses
  `completed`, `failed`, `aborted`.
- `profile.record({kind, scope, units?, unitsByField?, name?, value?, values?, source?, details?})`.
  Mixed fields use `unitsByField` instead of one misleading `units` label.
- `profile.abortOpen(status?, details?, {keep?})` closes open descendants
  innermost-first for explicit producer failure unwinds; strict `end` nesting
  remains mandatory.
- `profile.finish(status?, error?)` — closes any open span as `aborted`,
  writes `summary.json`, returns the report object.
- `createCompileBookObserver(profile, {rawDetail?, onEvent?})` — shared adapter
  for the canonical `observe(stage,name,state)` seam; coarse
  pass/reachability spans, fine definition/spin/prepare spans only in raw mode.
- `compilerObserverState(state)` and `compilerProfileLimits`.

`rawDetail:false` keeps only coarse spans and observations in `summary.json`.
`rawDetail:true` streams every begin/end/observation to `events.jsonl`. Fine
spans marked `details.summary:false` and fine observations marked
`summary:false` are streamed but not retained in `summary.spans`/`observations`;
the summary keeps bounded aggregate counts, statuses, failed samples and
`fineGrain` metadata instead, so a fullroot trace does not keep one object per
event on the codegen heap. Raw mode still pays per-event serialization and I/O;
its overhead is not zero and is not measured. `sampling:{cpuIntervalUs,allocationIntervalBytes}` loads
the existing inspector implementation lazily and samples only spans begun with
`{sample:true}`. If inspector callbacks are not synchronous (for example under
Bun), the span still runs and records `sample.status:'unavailable'` with a
reason; profiling never fails the build for that.

## CLI

Native experiment (`evals/native_compiler_experiment.ts`):

```
bun --smol evals/native_compiler_experiment.ts --mode=build \
  --corpus=... --artifact=... --report=... \
  [--profile-dir=FRESH_DIR] [--profile-raw=true] [--profile-sampling=true]
```

- codegen worker profile: `FRESH_DIR/codegen/`
- build supervisor profile: `FRESH_DIR/build/` (codegen process, clang or
  llvm-split stages)
- run mode: `FRESH_DIR/run/` (native child phases, fuel and result rows)
- `--profile-dir` must be fresh; no run is appended or mixed.
- `--profile-sampling` is Node/V8 only; the Bun supervisor records sampling as
  unavailable rather than guessing.
- Existing `--trace-c`, `--v8-log-dir` and guardian semantics are unchanged.

Component build (`evals/checker_core_component_build.ts`):

```
node --experimental-strip-types evals/checker_core_component_build.ts \
  --file=... --exports=... --artifact=... --report=... \
  [--profile-dir=FRESH_DIR] [--profile-raw=true] [--profile-sampling=true]
```

The profile lives in `FRESH_DIR/component/`. `--profile-sampling` cannot be
combined with `--allocation-profile-mib` because both own the inspector
sampler.

## Evidence types and scopes

- **Explicit spans:** monotonic wall (`performance.now`), process CPU boundary
  delta (`process.cpuUsage`, covering every thread in this process; child
  processes have separate accounting and are excluded), and boundary memory
  snapshots (`process.memoryUsage`). Nested spans overlap; no exclusive CPU is
  derived.
  Boundary `heapUsed` deltas are not allocation, live, or retained bytes; RSS is
  process-wide.
- **Exact counters:** producer-supplied values such as events,
  checked definitions, segments/spins/facts, prepared/released bodies, C code
  units, and native phase counts. They are labelled `kind`, `scope` and
  `units`; they are never converted into CPU.
- **Raw storage:** fine spans/observations are aggregated in memory while the
  full rows go to `events.jsonl`; `summary.rawEventsWritten`,
  `summary.spanCount`, `observationCount`, `fineGrain.spans` and
  `fineGrain.observations` preserve accurate totals without unbounded retention.
The collector writes `checkpoint.json` atomically at coarse span boundaries
and coarse observations (not fine raw events), including the active coarse
phase, process CPU/memory boundary, counts, last completed spans, recent coarse
observations and full execution pins. Profile provenance records report path,
corpus/report/input-manifest hashes, script and collector/inspector-helper
hashes, source pins, kernel/compiler/Base/bridge hashes, and artifact/build
paths/hashes when available; a later file change cannot rewrite the recorded
identity.

`fineGrain.spans.summedWallMsNotExclusive` is a sum over nested fine spans and
is not exclusive CPU or wall attribution. The collector and producers never
force or manually invoke GC. Raw boundedness is structural (bounded aggregates,
active frames only, full rows streamed to `events.jsonl`), not a measured heap
saving; unforced `heapUsed` samples remain GC-polluted and are not retained/live
or deficit proof.
- **Sampled attribution:** statistical V8 CPU stacks (1 ms) and allocation
  samples (4 MiB, including collected objects). These have no Bend source map
  and are not exact owner sizes.
- **Child-process rows:** `NATIVE_PHASE`, `NATIVE_FUEL`, `NATIVE_BEGIN`,
  `NATIVE_RESULT` are recorded with scope
  `native child process RUSAGE_SELF across all compute threads`, explicitly
  distinct from the parent producer's process CPU. The direct `clang` path has
  no wait4 receipt, so child CPU is `null` with a reason; `llvm-split` stages
  carry `/usr/bin/time -lp` user/system CPU and maxRSS.
- **Unavailable metrics:** retained/live bytes, exact allocation sites, direct
  clang child rusage, and per-definition CPU stay absent rather than guessed.

## Lifecycle

Every producer closes its phase spans with `failed` on a caught error and calls
`finish('failed', diagnostic)`. A codegen failure first unwinds observer
descendants with `abortOpen(..., {keep: root})`, then closes the root as
`failed`, so the original canonical diagnostic is never replaced by an
out-of-order close error. Successful producers close their root span
`completed` before `finish('completed')`.

Open spans at `finish` are still closed `aborted` with a `closeReason`, but the
summary is fail-closed: `measurementStatus` becomes `incomplete`,
`incompleteEvidence` is true, and `unclosedSpans` records the count/names. The
workload `status` and `workloadStatus` remain separate, so a completed compiler
workload with a programmer lifecycle bug is not silently presented as clean
measurement evidence. A terminated worker without a summary leaves a durable
coarse `checkpoint.json` (active coarse spans, counts, last completed spans,
recent coarse observations, process boundary, provenance); readers report
INCOMPLETE from that checkpoint. Worker signal handlers write a terminal report when the process
can still run JavaScript. If a worker or guardian is killed before finalization,
the parent reports `compilerProfile.runs[*].status = 'INCOMPLETE'`, preserves
the run record's pid/status, and reports `live:false` only with
`reportPhase=complete` and `ownedTreeStopped:true`; otherwise liveness is
`null`/unknown. A stale `IN_PROGRESS`/`running` record is never presented as
live or completed.

## Guardian lifecycle limits

The guardian receipt and the experiment/profile report are separate evidence.
The detached-supervisor lifecycle is guardian-owned (follow-up source plus the
exact final contract from NativeSeed/that owner), and the following limits must
be preserved by any reader:

- Guardian records carry `reportPhase:"decision"|"complete"` and
  `ownedTreeStopped:true|false|null`. `decision` is provisional and may be the
  last record after a supervisor SIGKILL; only `complete` with
  `ownedTreeStopped:true` proves the owned tree is gone.
- A detached guardian supervisor survives death of the launcher process group.
- A terminal decision receipt is provisional until final cleanup and is
  overwritten by one final record. A stuck or unconfirmable descendant keeps
  the lease (exclusivity preserved) and the provisional receipt remains with
  reason `deadline_exceeded`, `interrupted`, or a resource limit; there is no
  timer-based release and no `cleanup_incomplete` status.
- A profile summary, even a finalized `completed` one, is not process-liveness
  proof. `live:false` is reported only with `reportPhase=complete` and
  `ownedTreeStopped:true`; `decision`, false, or missing tree evidence yields
  `live:null` and explicit unknown liveness, never PASS or an observed OOM.
- The heavy-gate lease is released only after the owned tree is confirmed gone
  (`exited && !live`, after SIGTERM then SIGKILL), never merely because a
  deadline or signal was observed.
- If the guardian supervisor itself is SIGKILLed before any terminal decision,
  no receipt is guaranteed. That run must be classified INCOMPLETE with unknown
  liveness, never PASS and never as an observed OOM.
- The experiment report can only be finalized by a live parent. A dead-parent
  `IN_PROGRESS` report is not live evidence; profile runs whose summaries were
  not finalized are `INCOMPLETE` with the same liveness rule.

## Unfinished typed-stage progress

`candidate_host` and the bootstrap worker optionally pass their collector to
`createStepAttribution`. The first bounded-step boundary, then at most one
boundary per second, records `typed-step-progress` in the atomic checkpoint.
It retains the exact observed host-step count, protocol, fully qualified Run
namespace and pending request tag when visible. No callback runs on the normal
unprofiled path. Final phase attribution remains separate.

These are **last observed boundaries**, not continuous samples or evidence that
the process is still alive. A `Finished` progress shape is not whole-phase
completion: its Run may still carry a continuation stack. CPU/memory in the
checkpoint have the collector's existing process/isolate boundary scopes, not
per-request duration, allocation or retained-byte ownership.

`evals/receipts/durable_stage_progress_db147.json` records the regression
red/green, actual C emit/clang/run with byte-identical output against the
unprofiled image-bound control, and controlled termination of the real
full-root checker after a durable progress update. That interruption is not
compiler acceptance or full-input overhead evidence.

Trace event decoding preserves nominal identity: a Begin/End constructor must
belong to its Run's module and match the manifest's fully qualified constructor.
Canonical `comp.ts` strips source namespaces from emitted JS constructor tags;
that encoding is accepted only through a native build receipt bound to the exact
image. Without that binding, equal short names never establish provenance.
Decoding never advances the native continuation.

## Verified coverage and explicit gaps

`evals/compiler_profile_smoke.ts` is the focused bounded smoke. It runs:

- component build on a tiny valid source with profiling off and on: identical
  artifact bytes, three sampled spans (`load`, `book-validation`, `codegen`),
  real cpuprofile/heapprofile files;
- component build on a tiny invalid source: profile `failed` with a failed
  `book-validation` span;
- the native experiment CLI on a bounded negative load: terminal `FAIL`,
  codegen and build profiles `failed`, same diagnostic without profiling;
- a direct tiny canonical `book_load`/`book_valid`/`compile_book`/clang/run
  path: nested `c-reachability` and `c-pass-N` spans, exact counters, C
  publication, clang, and output `17n`; plus a failed direct validation;
- the committed `tests/reg/array_open_element.bend` real C codegen failure:
  observer pass spans are open, `compile_book` throws `an open Array element
  type`, descendants are aborted, the root is failed, and the canonical
  diagnostic is preserved;
- an open-span `finish('completed')` case proving `measurementStatus:
  incomplete`/`incompleteEvidence:true`; and a terminated tiny worker that
  leaves only a coarse checkpoint.
- Profiling (`--profile-dir`, `--profile-sampling`) marks codegen timing
  `diagnosticOnlyCodegenTiming` and runtime profile metadata; its duration is
  not a normal benchmark or profiled-build acceptance timing.

Current evidence: `evals/receipts/profiler2039_entrypoints.json` records the
ten producer smoke scenarios plus real candidate-host and bootstrap-worker
entrypoints, including verified parent links, collector IDs and source pins.
`checkpoints/compiler-profile-smoke-v1.json` is the raw bounded producer receipt.
Bulk producer profiles are removed after a passing smoke.

`evals/receipts/emitter2039_trace_spans.json` records native validation and actual
checked-FIR execution of both ordinary and diagnostic trace emitters. Ordinary
generation remains byte-identical to g7. For each JS/C target, ordinary,
trace-without-collector and trace-with-collector emit identical bytes; Node and
clang/native consumers both print `7`. The JS run closes 1199 brackets, the C
run 71069, with no rejected, unmatched, unknown or terminal-open frames.

The combined run observes all nine declared stage groups: emitter entry,
catalog, lowering, descriptor NF, layouts, sharing, JS/C rendering and
link planning. Coverage remains per-root: executable entrypoints are exercised,
library trace entrypoints are not. C retains 2048 individual brackets and
explicitly counts the other 69021 as omitted. Aggregate bracket counts remain
complete. Native validation checks 5680 definitions and 6152 events in the trace
component, with zero excluded checks or output patches.

These are scheduler-boundary brackets, not exclusive per-provider CPU or
allocation measurements. Child/interleaved work and observer overhead remain
inside elapsed intervals. Link planning is not external linker execution.
Retained/live bytes, exclusive per-definition CPU and full-root trace coverage
are not established by this probe. Historical producer/LLVM diagnostic evidence
remains separate in `evals/receipts/full_profile2039_complete.json`.

## Full-root selfhost profiling overhead

`evals/receipts/profile2039g8_full_root_overhead.json` records two alternating
pairs, ordered off/on then on/off, on the accepted g8 stage1 image and the same
complete compiler-root closure. Each leg uses the original 8192-MiB
RSS/footprint and 600000-ms guardian limits, Node 23.11.0, and a 256-MiB worker
stack. Only `--stage-profile` differs; no output is patched or normalized.
All four legs pass and emit the same 28,334,920 bytes, SHA-256
`0ff9027452d2b2bffb54f010d271a66aa5828eedfada41a391f359cb8e6de885`.
Both profiled collectors finish with complete measurements.

| Median, two observations per mode | Off | On | Change |
| --- | ---: | ---: | ---: |
| Child wall, seconds | 322.900 | 373.885 | +15.79% |
| Child user + system CPU, seconds | 345.270 | 400.995 | +16.14% |
| Guardian sampled peak RSS, bytes | 2,845,417,472 | 2,910,920,704 | +2.30% |
| Guardian sampled peak footprint, bytes | 2,676,183,580 | 2,734,981,548 | +2.20% |

These are operational on/off differences, including collector observation and
checkpoint I/O, not isolated instrumentation cost, exclusive stage CPU or
retained/live bytes. The compiler image and source closure are hash-pinned
before and after every leg; runtime paths/versions are recorded, but binaries
are not hashed. This is diagnostic evidence, not a new compiler acceptance or
a producer `compile_book` overhead measurement. The unprofiled native build
and stage1/stage2 acceptance remain in their separate g8 receipt.
