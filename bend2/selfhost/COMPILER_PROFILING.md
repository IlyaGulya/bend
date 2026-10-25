# Opt-in compiler profiling

This is a diagnostic collector for the official TypeScript compiler producers.
It is not an acceptance signal, a benchmark, a fixedpoint proof, or a claim
that every stage is covered. Ordinary runs do not import it and do not write
profile files.

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

Evidence: `checkpoints/compiler-profile-smoke-v1.json`. Bulk profiles stay in
the temporary directory and are removed after a passing smoke.

Not verified here: fullroot producer profiling, overhead/control measurements,
native `llvm-split` link execution, per-definition/per-module CPU, retained or
live bytes, and fine native substage spans (the typed views hide progress and
the generator is frozen). Those need a guarded, separately authorized run.
