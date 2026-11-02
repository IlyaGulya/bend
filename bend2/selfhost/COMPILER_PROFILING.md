# Opt-in compiler profiling

This is a diagnostic collector for the official TypeScript compiler producers.
It is not an acceptance signal, a benchmark, a fixedpoint proof, or a claim
that every stage is covered. Disabled runs do not create a collector or write
profile files.

`evals/selfhost_throughput.mjs` also accepts the existing
`SELFHOST_CPU_PROFILE_DIR=/absolute/outside-Git` collector opt-in. It profiles
the actual public typed-Run pipeline, with separate startup, load/parse,
expansion, checker and emitter windows; no private Run decoding is involved.
CPU samples belong to the worker isolate, whereas phase process-CPU counters
include other process threads. Allocation samples are statistical estimates,
not exact allocated or live bytes. Profiling runs are not throughput results.

G51 exercised this path against G50's frozen complete source and genuine
native-produced image: 244,594 checker samples over 310,644 sampled ms, with
1.97% GC samples. Typed scheduler/chunk continuations and borrowed `Map.get`
tree rebuilding are measured hotspots. The profiled 353,384-ms pipeline
reproduced the unprofiled output's 31,906,405 bytes and SHA-256
`273b0022813e17908020c0ee58fd4e02da4f3dc756ce58e3389093440863c3fe`
under the unchanged 8-GiB RSS/footprint gate. Neither profiling overhead nor
overlapping inclusive sample totals establish an optimization win.
`checkpoints/local2039g51-profile-measured.json`.

### Fast actual-checker iteration

The pinned request accepts `"stopAfter": "check"` in JS-component mode.
It still requires ABI13, freshly runs the image's own parser with 8M fuel per
module, expands and checks the complete declared source closure, and retains
the original 8192-MiB RSS/footprint, 10-ms poll and 600-s hard guard. It skips
only emission; output files and emitted-byte equality claims are prohibited.
Default requests still compile. This is not native/bootstrap acceptance.

`checkpoints/local2039g51-checker-mini.corpus.json` freezes the existing real
`template_steps_component_v1.bend` closure: eight Bend modules and 35 unique
declared JS alternatives, not generated ASTs or synthetic typechecking work.
The measured canonical development image freshly parsed/expanded/checked it in
11,597 ms (checker 10,599 ms; RSS 746,602,496 bytes). This is a quick falsifier,
not a substitute for the full-root final measurement, and its timing must not
be compared as a compiler speedup against a differently produced image.

```bash
bun --smol evals/selfhost_throughput.mjs js \
  /absolute/pinned-check-only-request.json /absolute/fresh-report.json
```

Use the same image's own parser: canonical `comp.ts` and selfhost-produced
images have different runtime constructor layouts. Mixing their parser values
failed before checking and is a harness error, not a compiler regression.
The full-mode template compilation reproduced the exact 1,903,750-byte JS;
the resulting real template component specialized a consumer that returned 42.
The clean driver omits per-step stage attribution, whose CPU probes are
measurable overhead on this small workload. Phase CPU/heap profiling remains
available through the opt-in above and is never throughput evidence.

The same canonical development control is **not eligible for the complete
compiler-root workload** under this worker policy: its recursive `String.to_list`
overflowed during own parsing, before expansion/checking. This was a control
failure, not a G53 regression. Do not hide it with a larger stack, host parsing
or replayed ASTs. Full comparisons use genuine native-produced images from
the same authenticated C seed; the quick corpus only rejects hypotheses early.

G52 descriptor elision was rejected after three samples per variant: checker
median 10,432.685 versus control 10,481.490 ms (0.47%, inside variability).
Its all-body source admission and 27 actual positive/negative checker/emitter
consumers passed. G53's read-only name/prefix lookup reached 9,793.580 ms
(6.56% on this quick source), with the same 466,660 public checker chunks;
27 consumers and the Arena boundary fixture's emitted JS and compiled C passed.
These are isolated source experiments, not accepted compiler changes.

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

The canonical native constructor (`native_compiler_experiment.ts --mode=build`)
defaults an unset `BUN_JSC_forceRAMSize` to `4294967296` for ordinary Bun
codegen, before spawning the guarded process. This matches the accepted-control
startup policy; it is a GC heuristic, not a 4-GiB quota. Explicit caller values
are preserved. The 8-GiB RSS/footprint guardian and Node profiling's
3072-MiB heap / 256-MiB stack policy are unchanged. The bounded probe above is a
different entrypoint and still needs its explicit environment prefix.

Native-build receipts pin the constructor source as well as the compiler.
After changing the constructor, create fresh build authority for new runs;
never rewrite historical receipts or relax their protected source pins.

The LLVM constructor additionally accepts `--cc-partitions=4|8` only with
`--cc-pipeline=llvm-split`; default four and maximum three concurrent backend
children are unchanged. The full qualifier forwards it only when constructing
a new native compiler, never for throughput-only build reuse. Bitcode identity
and each partition's bytes, hash, object and stage are recorded using bounded
streaming hashing. A deliberately failing real clang partition demonstrated
child draining, no replacement dispatch after observed failure, and no link.

G41 exercised both complete builds and the eight-way genuine fixedpoint plus
all twelve strict paired samples. Faster observed backend construction did not
earn runtime promotion: default four remains. Do not rerun that failed target
unchanged or describe the stopped later correctness suites as PASS.
`checkpoints/local2039g41llvm-outcome/outcome.json`.

G42 is an isolated facts/final-C-materialization diagnostic, not a production
option. Its 17 actual C/JS cases and two unprofiled full-root modes execute
under the original 8192-MiB RSS/footprint, 10-ms poll, 600-s protocol with the
explicit accepted Bun hint. Both modes reproduce independent accepted C bytes,
but primitive recipes are slower in the observed pair and are rejected.
Full C byte equality is not a native-seeded fixedpoint or runtime claim.
The canonical second `book_load` root uses the same source coordinate via its
sixth argument; structured Bend errors must be rendered with `err_show`, never
dumped with the shared book. Earlier harness-coordinate/default-guard failures
remain separate setup evidence, not compiler failures or cap relaxation.
`checkpoints/local2039g42defer-outcome/outcome.json`.

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

## Measured build latency and safe parallelism

Do not call a complete qualification a build. The completed N12 R12 native
build takes 297.044 s: C generation 183.800 s, LLVM 106.283 s, the remaining
time is validation/startup/publication. Its LLVM backend already has four
partitions and at most three concurrent compilers. The longest partition
finishes after all others, so a fourth worker alone cannot shorten that
observed critical path. Evidence: `construction_n12_launcher_fixed.json`.

G40's settled phase=all takes 3326.131 s to performance rejection; 2366.819 s
is the 12 serial measurements. Native build and genuine byte fixedpoint pass,
but this is neither compiler acceptance nor a completed all-consumer run.
Evidence: `checkpoints/local2039g40e05r2-outcome/outcome.json`.

Keep heavy execution and paired measurements exclusive on their host.
The existing guardian lock rejects contention; do not bypass it with another
lock path. A unique run ID does not isolate the shared generated source files.
Distributed correctness branches require an immutable full source/tool closure
and isolated outputs, not just a copied root file or rewritten provenance.
Stage1 must precede stage2; root.js never substitutes for native stage1.
Changing scheduling, partitioning or measurement placement needs a separate
declared experiment, not a mid-run change to the original gate.

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

## Immutable qualification placement (experimental, not yet qualified)

`evals/g24_qualification.mjs --distributed-plan=PATH` selects the explicit
protocol described at the top of `evals/g24_distributed.mjs`. Omit it to retain
the original serial path. The plan pins actual physical hosts, runtimes/tools,
environment and job placement. Obtain SSH pins through independently trusted
access; a first-contact probe is not authentication. SSH hosts select exactly
one of `node: 2` (existing cluster/BEND_HOC route) or `ssh: "misakaindrive"`
(direct SSH config alias/hostname). Direct targets are ASCII alphanumeric-first
aliases with only alphanumeric/dot/underscore/hyphen, not user/port/option syntax.
They use argv-based `/usr/bin/ssh`, BatchMode, an 8-second connect timeout and
normal host-key checks. Local mode rejects either selector. The plan rejects
two aliases for one physical host; they cannot count as independent machines.

The snapshot inventory follows operational modules, actual consumer/matrix
closures, selected real producer evidence/artifacts and frozen workload inputs.
It never walks an entire checkout/output/history tree. Unsupported dependencies
and relocation-unsafe absolute Bend imports fail before transport. Bun's scanner
receives source after its ignored first-line hashbang; the captured source/hash
is unchanged. Extraction seals its precreated root to 0555 before OS checks and
snapshot JS loading; exact nested modes/content remain independently checked.

`local-single-host` serializes on exactly one machine. Independent SSH hosts may
run independent correctness queues. R5 removes the incorrect process-name idle
heuristic: an ordinary Node/Bun service is not proof of competing heavy work.
Host leases, watchdog/tree reaping and the original heavy guardian remain;
never unlink a poisoned reservation or override the guardian to force a run.

Each performance lane owns one host lease for all six original interleaved rows.
Native output is authenticated before JS dispatch. No row exclusions, imported
receipts, relaxed means/medians, tolerance or parallel samples are introduced.
Do not run producer builds alongside measurement hosts.

The protocol does not prove arbitrary external work is idle. Avoid known
competing heavy workloads operationally; do not replace that responsibility
with executable-name scans or an arbitrary CPU threshold.

The actual R5 worker now executes the 62-case C matrix with background services
untouched. Its single reported failure is scheduler_chunk_smoke emission at
the unchanged 600-second deadline, with ownedTreeStopped and supervisor
reaped=true. No test is excluded and no producer substituted. Nine invariant
tests and real authenticated packaging/transport pass; complete consumers,
cancellation, twelve-row lanes and final qualification are not yet PASS.
`checkpoints/local2039g43r5-outcome/outcome.json`.

The direct-SSH path has executed all 33 native/foreign/library rows on the
authorized remote Mac with byte-identical accepted private Bun/Node tools,
without stopping bb-app. Twelve selector/lease/snapshot/row safety tests pass.
Native execution, source/host/tool authentication and owned-tree reaping are
observed; other branches, matrices, cancellation and full performance
qualification are not inferred from that selected-branch proof.
`checkpoints/local2039g43r6-outcome/outcome.json`.


### Scheduler fixture phase attribution (G43R7)

The full original scheduler fixture/import closure and genuine accepted image
were observed through the existing Node consumer worker, with unchanged 8/8-GiB,
10-ms, 600-s rails, ABI13, fuel8M and quantum64. These instrumented timings are
diagnostic observations, not uninstrumented performance evidence:

| Phase | Observed wall seconds | Completion |
| --- | ---: | --- |
| Image startup | 0.959 | Completed |
| Parse/import/fuel | 6.152 | Completed |
| Template expansion | 5.455 | Completed |
| Signatures/bodies/publication | 111.034 | Completed |
| C emission | — | Still open at the total 600-second deadline |

The last observed emit boundary reports host-step34,005,165 and raw NF,
descriptor and reach requests. The producer kept crossing observable boundaries;
this is not proof of a deadlock. Once-per-second request-tag samples are not
exclusive CPU shares or per-request invocation counts. Parser/fuel spans now
rule out attributing the entire timeout to input parsing, but do not identify
the precise NF descriptor/key algorithm that needs changing.

Independent actual SSH runs pass all12 datatype/admission and all5 nested-host
rows. A genuine owned native compiler PID was interrupted through its coordinator;
the authenticated same-nonce supervisor reports FAIL/reaped=true and that native
identity is absent afterward. The cancellation is an intentional diagnostic PASS,
not a completed workload. Its legacy “full-root” label must not be interpreted
as full frozen-corpus throughput. Source, commands and compact actual evidence:
`checkpoints/local2039g43r7-outcome/outcome.json`.


### Complete direct-SSH paired lanes (G43R8)

The canonical `phase=all` run freshly constructs the accepted native bytes,
proves genuine stage-one/stage-two equality, then executes every original paired
sample on the pinned M3 Pro host. Both authenticated supervisors PASS/reaped=true;
all12 original guards PASS with owned trees stopped. No background service is
stopped, paused or restarted.

| Lane | Control mean s | Candidate mean s | Control median s | Candidate median s | Strict decision |
| --- | ---: | ---: | ---: | ---: | --- |
| Native | 60.833 | 60.973 | 60.795 | 60.972 | Reject time and median RSS |
| JS | 190.242 | 186.074 | 189.183 | 186.678 | Pass this lane only |

The two native executables and the two genuine JS images are byte-identical.
These differences are measured variation, not a compiler optimization. The
original strict decision is still rejection: no tolerance or row exclusion is
introduced. Canonical fail-fast stops before emitted suites and correctness
matrices; a successful transport does not manufacture full qualification.
All exact rows, commands, memory figures, producer proofs and the rejection:
`checkpoints/local2039g43r8-outcome/outcome.json` and `throughput.json`.

### Full JS matrix and bounded NF arguments (G43R9)

The complete accepted JS-target matrix passes all67 fixtures on the pinned SSH
host, including scheduler_chunk_smoke; the actual supervisor PASS/reaped=true.
In parallel on the separately owned local host, the original full C input remains
inside emission at600s with owned tree stopped. Neither input nor guard is reduced.

| Argument-probe boundary observation | Count |
| --- | ---: |
| All samples | 3836 |
| Selected NF/reach samples | 622 |
| Complete argument tuples | 484 |
| Complete nonempty tuples | 329 |
| Distinct complete nonempty keys | 255 |
| Recurrent nonempty tuple observations | 74 |

These are samples, not invocation counts or exclusive CPU shares. Context map
identity is not a structural map-content fingerprint; depth-limited walks do not
yield comparable keys. Equal descriptors with different fuel remain distinct.
All48 sampled reach_arms targets identify CheckerProgress. Its original
Finished/Pending/Direct arms precede Bound, whose live inner field directly
references CheckerProgress. The existing depth-first search explores those
earlier graphs before visiting this direct witness. A direct-witness-first
ordering with the same normalizer/environment/fuel is evidence-directed; it is
not yet implemented, measured or qualified. No cache keyed only by family name
is justified. Compact actual evidence and exact probe source:
`checkpoints/local2039g43r9-outcome/outcome.json`.

### Rejected ordering candidate and actual closed-family search (G43R10)

The isolated arm-ordering hint preserves the original normalizer, environment,
arity/failure/fuel and path-sensitive seen rules. It reaches genuine native-seeded
byte fixedpoint and all95 seed plus190 emitted-fixture checks, but is not a
demonstrated C-emission fix: the complete remote C62 matrix and the same original
full input on the original M1 both still reach the unchanged600s deadline.
No compiler promotion or candidate paired-throughput acceptance follows.

Real report/qualification-root coordinate fixes separately eliminate mixed
symlink spellings before relative fixture imports and downstream proof paths.
The exact identity/hash guards remain unchanged; the actual full bootstrap and
both emitted suites cross those formerly failing boundaries.

One new bounded readonly actual-BIR observation, followed by intentional abort
without C output, identifies zero-arity CheckerRequest with19 group-wrapper
arms. Its sampled walk is in Char/U32 through String/Scope maps/Arena with an
empty environment. This directs investigation toward repeated negative graph
search, not a claim of exclusive CPU share or complete graph cost.
A conservative closed-family negative named-reference fact must first prove
that every possible normalized family name is in the collected closed dependency
set. Unknown forms prevent a negative proof; generic root arguments and
fuel/env/seen-sensitive positive queries retain the original semantics.
`checkpoints/local2039g43r10r3-outcome/outcome.json`.
`checkpoints/local2039g43r10d1-outcome/outcome.json`.

### Conservative closed-family candidate: semantic smoke only (G43R11)

The isolated candidate builds one syntactic dependency graph per CLay context
and retains proved negative facts only for authoritative zero-arity families.
Edges union all family fields and indexed function bodies, including nested
arguments and unevaluated descriptor children. Unknown forms prevent a proof;
opaque names are terminal with arguments still collected. Applied/generic
environments and every positive/maybe case keep the original normalizer,
path-local seen set and fuel. No normal form or failed reduction is cached.

The existing composed/normalized/owned CLay fixture actually executed through
the canonical Bend module loader: zero failures,7144 chunks,1143ms,
RSS438992896B, footprint379782080B; guardian PASS and owned tree stopped.
Its artifact hash identifies generated Bend source, not a selfhost JS image.
This exercises semantic boundaries, not native-seeded byte fixedpoint,
C62/JS67 completeness, scheduler deadline improvement or strict throughput.
Source `b7c49cf0`, private contract `42d1735d`, frozen generated inputs
`53fb6bd3`; `checkpoints/local2039g43r11-semantic-outcome/outcome.json`.

The full G43R11 qualification is now rejected, not pending. Native build passes
with12502 checked definitions and produces a genuine31894945-byte stage-one
image (`146b191b…`); all95 native seed fixtures pass. The unchanged600-s
bootstrap guardian stops during stage-two-check, with no stage-two artifact
or byte-fixedpoint result. C62, JS67 and new strict paired rows are unreached.
The complete53-file source corpus and compact failed outcome are retained.

| Native check, single run | Wall seconds | User + system CPU seconds |
| --- | ---: | ---: |
| R10R3 | 67.516898 | 65.708095 |
| R11 | 167.470081 | 80.770741 |

Source differs and these are not paired acceptance rows. The observed time
outside CPU does not identify scheduling, I/O or another cause; no process-name
heuristic, utilization admission rule or retry of the unchanged failure follows.
`checkpoints/local2039g43r11-outcome/outcome.json`.

The genuine R11 stage-one image also fails the unchanged original full scheduler
C-emission diagnostic at600238ms, RSS2587623424B, footprint2636219720B,
owned tree stopped. No C/clang/runtime result or acceptance-matrix claim.
The closed-family implementation is therefore rejected as a demonstrated
deadline fix. A new bounded actual-state sample must distinguish dependency
fact construction from remaining semantic reachability before another change.
`checkpoints/local2039g43r11-local-outcome/outcome.json`.

### Remaining generic goal at the semantic boundary (G43R11D2)

The actual60–80-emit-second readonly window has132 boundary samples. Captured
reach_arms/family_reach/fields_reach/reaches requests all target Sigma, with
String/U32/Word through Scope/Arena. The context's closed table is nonempty
and its node table still empty: this is consistent with node-plan construction
after the eager fact pass. No dependency-builder request is sampled in that
window; no whole-run or exclusiveCPU attribution follows.

EmitterFinished samples here are completed inner continuations under Bound,
not a whole-program EmitSuccess or emitted C. The probe deliberately stops
at80039 emit milliseconds (213880ms guarded command), owned tree stopped.
The next isolated candidate retains the graph and asks whether an eligible
closed named family can reach the actual arbitrary target at the semantic
boundary. It must not confuse absence of a self-cycle with absence of a path
to a generic parent's target. No native/fixedpoint/C acceptance is claimed.
`checkpoints/local2039g43r11d2-outcome/outcome.json`.

### Strict source-lowering prerequisite corrected (G43R12L1)

The meaningful explicit-declaration fixture exposes an independent host defect:
a standalone constructor list passes an unresolved outer quantity to its empty
tail, and the old lexical indexer mistakes it for an unbound source variable.
Eagerly committing the Data head's quantity is also incorrect: a later explicit
List<&1,Nat> tail must retain that compatible quantity.

Direct nested constructors now share inference constraints; all payload
equalities precede fixed-point kind fitting. Genuine lexical/type errors,
recursive solutions and undetermined parameters still fail. The old helper
actually fails the new real-source singleton regression; the corrected helper
passes all50 affected type/capture/product/quantity tests.

The original full composed CLay step pipeline now also executes, with the same
fixture and host helper: old private R11 reports one behavioral failure, R12
reports zero failures/7181 chunks. The canonical loader smoke is real program
execution, not only unit tests. Only the host-lowering correction is integrated
in main. Subsequent private R12 genuine fixedpoint passes, but full C62 rejects
the candidate at the original scheduler deadline; strict throughput is not
authorized. See the complete-attempt evidence below.
`checkpoints/local2039g43r12l1-unit-outcome/outcome.json`.
`checkpoints/local2039g43r12-semantic-outcome/outcome.json`.

### Producer source portability prerequisite exercised (G43R12)

A fresh146ec560 source capsule includes2872 tracked code files plus all14
protected prerequisites,2884 distinct regular paths, without links or
conflicting overlaps. Reconstructing it in a fresh real-path repository and
importing four original Git objects actually passes the production release
identity helper and all14 prerequisite byte checks. Archives/full manifests
remain outside Git; only the compact executed-command receipt is checkpointed.
This is local source/input portability, not a remote producer or compiler
qualification. Coordinator tree ownership/lease/cancellation/reap proof still
blocks an ordinary foreground SSH launch.
`checkpoints/local2039g43-producer-portability/r12-source-capsule-proof.json`.

### Build wall time is not one compiler phase

Actual R11 single-run M1 accounting; rejected candidate, not an accepted
baseline or paired performance result:

| Boundary | Wall seconds | Meaning |
| --- | ---: | --- |
| Native construction before CC | 155.311 | Includes validation2.118 and TS-seeded C generation150.345 |
| LLVM/clang construction | 156.718 | Separate from native-build.json elapsedMs |
| Guarded native build | 312.779 | Complete construction, including orchestration |
| Genuine bootstrap attempt | 600.015 | Timed out in stage-two-check; not fixedpoint |

LLVM already runs up to three backend children. Its critical path here includes
frontend40.628s, preparation24.868s, split14.515s, the slowest backend72.755s,
then link0.197s. Adding those to a total that already includes CC double-counts.
Independent host consumer suites can overlap across physical M1/M3; genuine
native→stage1→stage2 ordering cannot.

The observed native check wall167.470s versus process CPU80.771s does not
identify a culprit. Existing source audit rules out an interactive parent
handshake inside that check drive, not scheduling/page-fault/memory effects.
No idle predicate, process-name exclusion or daemon intervention follows.

Concrete Mac integration faults were software coordinates/tool selection:
symlink-parent imports/proof paths now use real coordinates; private accepted
Bun/Node avoid changing M3 system installs; `/usr/bin/git` bypasses a broken
Homebrew wrapper. Full C deadlines occurred on both physical Macs. Those facts
do not establish a defective Mac or prove that bb-app caused the delay.
`checkpoints/local2039g43r11-outcome/outcome.json`.

### G43R12: actual fixedpoint, original full C deadline still rejects

One actual original correctness attempt from source146ec560, not a sum of
different versions or paired performance evidence:

| Boundary | Wall seconds | Outcome |
| --- | ---: | --- |
| Canonical JS build | 39.190 | PASS; not the native stage1 image |
| Native build | 244.748 | PASS,12509 checked definitions |
| Genuine native bootstrap | 528.152 | PASS, exact native-stage1/stage2 bytes |
| Emitted suites | 255.534 | PASS,190 fresh;95 seed already passed in bootstrap |
| Full remote C62 worker | 1648.074 | FAIL, scheduler emit alone exceeds600s |
| Complete CLI attempt | 2854.480 | Rejected; later consumers not reached |

Stage1/stage2 are31918288 bytes, SHA256
`066e40c85d26237f4f6c5b3579938b0df7cb4e6df384d322ee498e2cc4b85d3e`.
The original scheduler guard fails at600066ms with RSS2707767296 and
footprint2521147592 bytes; `ownedTreeStopped=true`, remote `reaped=true`.
The wrapper's generic “dispatch cancelled/transport failed” is not evidence of
an SSH loss: durable result/worker stderr show ordinary worker exit1 and the
actual C deadline. Emitted suites are PASS despite the receipt's stale
last-published failure-step label.

Native check in this run is66.885s wall/65.609s process CPU. The earlier R11
off-CPU gap is not reproduced under this changed source; causation remains
unknown. All53 native-execution sources and84 seed-loaded sources are frozen
as84 unique source files/8057977 bytes; no images, ASTs or bulk logs in Git.
Separate fresh nonces actually complete JS67/native33/admission12/host5 in
1030.780s. Every durable remote result is PASS/reaped=true. Failed C is not
retried; the original FAIL receipt is unchanged and strict12 remains
unauthorized. The owned one-off controller is removed after proof.
`checkpoints/local2039g43r12-outcome/outcome.json`.
`checkpoints/local2039g43r12-remaining-outcome/outcome.json`.

### G43R13: request-local SHOW NF reuse is insufficient

Source`af6f7466`, run-head`457305e2`, starts from accepted-source`f2e8358a`
without the rejected G43R12 graph. One original descriptor/context/empty-env/
output-level0/fuel1024 query feeds the data-arm traversal's existing
`head_value`/`arm_fields_value`. Field instantiation, layout/native rules,
SHOW-kind classification and independent key normalization stay unchanged.
This is local semantic-value reuse, not a global cache or idempotence claim.

The new captured-alias/mixed-instance/recursive/shifted-field consumer executes
the same literal stdout in genuine G24R12 C/JS and actual candidate full C62.
The original owned-step physical program also really finishes844700 chunks;
its printed desc/names alone are not treated as full compiler equivalence.

| Original correctness boundary | Wall seconds | Outcome |
| --- | ---: | --- |
| Canonical JS build | 35.092 | PASS, not native stage1 |
| Native build | 284.447 | PASS,12457 checked definitions |
| Genuine native bootstrap | 487.209 | PASS, exact native-stage1/stage2 bytes |
| Fresh emitted suites | 241.593 | PASS,190 fresh plus prior95 native seed |
| Full remote C62 worker | 2442.098 | FAIL, only scheduler emit exceeds600s |
| Complete CLI attempt | 3632.870 | Rejected; later targets initially unreached |

Stage1/stage2 are31762498 bytes, SHA256
`59feaa3a527a304f8bdeed849ee7274badb3d92db98700528a8938e1a27d0f4b`.
Native binary SHA256
`fc08bd801b665726e0ec0750581ff11b165d85821ca4395beeecca3e6566b078`.
The scheduler guard fails at600092ms, RSS2709798912/
footprint2643039688 bytes, owned tree stopped and remote reaped.
The generic dispatch error does not establish an SSH loss. Neither the
cross-version C-worker durations nor this semantic success prove speedup or
slowdown. The original full correctness failure forbids strict12/promotion.

All53 native-execution and84 seed-loaded inputs are frozen as84 unique
source files/8014587 bytes; images/ASTs/caches/bulk logs stay outside Git.
All originally unreached JS67/native33/admission12/host5 actually complete in
910.850s under fresh authenticated nonces, each durable result PASS/reaped=true.
The candidate C/JS mixed-instance witness matches its literal output.
Original C FAIL is byte-unchanged and not retried; strict12 remains unauthorized.
The owned one-off remaining-target controller is removed after proof.
`checkpoints/local2039g43r13-outcome/outcome.json`.
`checkpoints/local2039g43r13-remaining-outcome/outcome.json`.

### После G43R13: радикальные архитектурные варианты, а не ещё один NF-патч

**Статус:** только исследование; компилятор/runtime/генераторы/тесты не изменены, новых запусков и acceptance нет.
`[ФАКТ]` — исходник/receipt; проекты и ожидаемый выигрыш — гипотезы. Baseline — принятый G24R12, не R10–R13.
Короткие `.bend` — `bend2/selfhost/`; `FrozenChecker` — исключительно
`checkpoints/local2039g43r13-inputs/repository/checkpoints/checker_core_steps_v1.bend`.

#### Диагноз и граница наблюдения

- `[ФАКТ]` R13: `scheduler_chunk_smoke`, stage=`emit`, 600092 ms, RSS 2709798912 B
  (`checkpoints/local2039g43r13-outcome/outcome.json:246-258`): незавершённое время, не полная стоимость.
- `[ФАКТ]` matrix-driver запускает Node Worker с **native-produced stage-one** как candidate и parser,
  не TS/root.js (`evals/g24_qualification.mjs:684-698,1385-1401`; `evals/candidate_consumer_worker.mjs:10-13`).
  `emit` включает загрузку/parse/expand/check/emit; clang лишь после успеха
  (`evals/candidate_host.ts:223-258,283-292`; `evals/c_target_fixtures_run.ts:136-149`).
- `[ФАКТ]` `main()->IO(Unit)`, 15 печатей (`evals/scheduler_chunk_smoke.bend:50-82`):
  `plan_executable_io` обходит SHOW, но sharing/CID нужны раньше (`c_backend.bend:466-478,518-544`).
- `[ФАКТ]` `CLay.context:290-300` передаёт bare-context с пустой node-map в `plan_node_index:903-919`;
  тот проходит весь inventory без лимита числа конструкторов. Fuel1024 — на выражение (`layout_fuel:410-418`).
  Независимо от строгости map, `c_backend.cid_ctor_rows:1042-1051` требует layout **каждой** строки
  ради WORD-arity: отложить построение без устранения потребителя — не устранить работу.
- `[ФАКТ]` erased-поля уже пропускаются, сохраняя сдвиг env (`c_backend_layout.bend:543-561,606-622`).
  Это не liveness конструкторов. План только при своём fuel, instantiated layout отдельно (`node_at:847-886`).
- `[ФАКТ]` R11D2 видело Sigma/String/U32/Word через Scope/Arena при пустой node-map (выше:597-612).
  Это поддерживает node-planning гипотезу, но не даёт CPU-долей, call-count или нового профиля R13.
  Слишком широкие/повторные обязательства — рабочий диагноз; их относительная стоимость неизвестна.

#### Ранжирование: пять разных механизмов

Ранг учитывает критический путь, возможность опровержения и риск контракта, не обещанную скорость.

| Ранг | Изменение | Какой класс работы исчезает / меняет масштаб | C62 IO / unchanged strict12 | Цена |
| --- | --- | --- | --- | --- |
| 1 / A | Проекция исполняемого спроса + специализация request-dispatch по потоку тегов | Недостижимые тела и физические обязательства; зависимость от востребованного замыкания, не всего импорта | Прямо C; общий BIR может помочь JS, но неизвестно сколько останется в полном compiler-root | Высокая: liveness, foreign roots, внутренние specialised sums |
| 2 / B | Типизированная first-order машина продолжений | Внутренние closure/Value/Run промежуточные объекты на переходах | Весь настоящий stage1 emit и оба strict12 runtime-lane | Высокая: генератор трёх компонентов, ownership и точная семантика шага |
| 3 / C | Один владелец семантического descriptor-DAG между фазами | Quote→дерево→повторная интерпретация и повторная материализация окружений | NF/layout на C; общий Catalog/Lower даёт возможный JS-эффект | Высокая: BIR schema, scope/fuel simulation; без смены C value ABI |
| 4 / D | Delta-worklist вместо полных rounds sharing | Повторные обходы неизменившихся facts: обработка зависимых изменений | Прямо C `plan_make`; само по себе не доказывает ускорение JS-target | Средняя: solver, обратные зависимости, диагностический порядок |
| 5 / E | Нерекурсивное хранение полей: один Term на live-field | Flatten/reentry/Fill-Unfill для вложенных data перестают определять storage | Прямо C; strict12 JS не следует | Очень высокая: C representation/FFI/runtime/heap, отдельное разрешение |

`strict12` компилирует **JS-library в обоих runtime-lane**: `evals/g24_qualification.mjs:1031-1061`
выбирает `workloadRows(...,'js')`; native `phase:'compile'` и JS `emit_library_start` —
`evals/selfhost_throughput.mjs:44-51,97-99`. C-only части A и варианты D/E не доказывают strict12.

#### A — спрос должен принадлежать исполняемой проекции, не всему каталогу

`[ФАКТ]` Catalog сохраняет конструкторы/семейства (`lower_catalog.bend:1269-1309,1470-1480`);
Lower передаёт их в BIR (`backend_lower.bend:1978-1992`), а `scan_program` не доказывает liveness (`c_backend.bend:892-920`).
В authentic `FrozenChecker:2565-2578,35912-35927` Pending содержит общий Request и вызывает общий dispatcher.
Прямая DCE оставит все handlers (`FrozenChecker:35885-35905`), хотя fixture создаёт один pending-request.

**Дизайн.** После полного checking сохранить исходную семантическую таблицу first-declaration,
но отдельно вычислить demand от main/exports, closure-значений, callback/foreign/runtime roots.
Для известных конечных множеств тегов специализировать private dispatch и его result-index;
unknown-call/escaping request сохраняет общий dispatcher, а не трактуется как пустой поток.
Сначала удалять только недостижимые runtime bodies/constructor rows, сохраняя исходные family arms
для семантики layout. Если этого мало, следующий, явно отдельный шаг — private specialised sum
с доказанным множеством обитателей и согласованными construct/project/conversion consumers.
Обрезать arms исходного семейства нельзя: это меняет tag/packing/reentry даже у оставшихся значений.
CID/FID foreign-ссылки и runtime-конструкторы — обязательные roots, не только BIR.Construct
(`c_backend.bend:1088-1091,4220-4238`); numbering/remapping должен быть детерминированным.

**Решающий дешёвый опыт:** на новом диагностическом stage1 вычислить demand-census для неизменённого
frozen scheduler: inventory, reachable bodies, request-tag sets и обязательные node/layout roots;
затем один общий finite-tag dispatch transform, без hardcode имени fixture, и тот же census.
Если общий Pending/foreign closure оставляет почти все дорогие roots, A опровергнут как следующий ход.
**Consumer-фальсификатор:** request, пришедший через неизвестное higher-order resume/FFI callback,
плюс duplicate-first declaration и erased→dependent field; поведение/ошибка обязаны сохраниться.
**Контракт/heap:** проверять весь исходник по-прежнему; не скрывать ошибки в «мёртвых» декларациях.
Если сохранение существующих layout diagnostics требует прежнего полного анализа, это реальный
предел A, не разрешение ослабить admission. Private sum specialization меняет внутреннюю representation;
нужны relation/conversion proof и решение о допустимости, а не незаметная смена ABI.
**Масштаб правок:** BIR demand pass, Catalog/Lower boundary, оба renderer, C layout/sharing/link;
генератору нужна provenance-aware специализация result-index, не просто новая разбивка на группы.
Выигрыш возможен только при существенно меньшем востребованном замыкании; cloning может увеличить heap/code.

#### B — исполнять продолжения как типизированные кадры, а не заново строить башню closure-объектов

`[ФАКТ]` генератор создаёт зависимые Request→result, Value, Progress, Stack и Run
(`evals/checker_core_step_lower.ts:2347-2393,2424-2461`); Template использует тот же lowerer
(`evals/template_step_lower.ts:6-19`), Emitter объединяет JS/C и общие providers
(`evals/emitter_step_lower.ts:35-55`). Это путь исполнения самого компилятора, не только сборка.
Существующие private-helper fusion/deforestation уже описаны в lowerer:13-32,584-595;
предложение **не** расширить очередной whitelist inline.

**Дизайн.** Генерировать instruction/control labels и first-order continuation frames,
типизированные входным/выходным результатом и конкретными affine captures; один owner машины
несёт control, environment и stack. Внутренние returns передают результат следующему кадру
без обязательных промежуточных Value+Run; публичная граница сохраняет существующие наблюдения.
Общий engine не должен превращать dependent frame в unchecked `(tag, Any[])`.
Публичный host считает Run непрозрачным, но проверяет state/finished/value tags
(`evals/checker_core_step_runtime.mjs:175-192`); экспортов13 недостаточно для ABI-совместимости.
Исходные typed closures, в том числе пользовательские callbacks, сохраняют обычную семантику;
заменяется представление конечного множества **генерируемых** продолжений.

**Решающий дешёвый опыт:** сначала измерить реально создаваемые administrative objects/переходы
в bounded новом diagnostic stage1; затем один замкнутый typed control-region Emitter выполнить
кадровым engine с покадровой симуляцией прежних Pending/Direct/Bound/Finished переходов.
Нельзя просто считать один frame-инструктаж одним старым переходом: сохранить промежуточные
состояния и точки остановки при любом fuel, особенно 0/1/63/64/65.
**Consumer-фальсификатор:** все 15 строк scheduler, особенно heterogeneous U32→Bool и
Pending/Direct при 31 Bound (`evals/scheduler_chunk_smoke.bend:23-43,50-82`); дополнительно
affine capture, два шага с паузой и callback должны не дублировать и не терять owner.
**Контракт/heap:** новые внутренние frame carriers требуют миграции генераторов/bridges/provenance;
public result/tag/quantum64 остаются. Если без изменения наблюдаемого Run это невозможно —
нужно явное разрешение, не «совместимый» cast. Семантический fuel checker/NF не пересчитывается.
**Риск:** frame-union может стать шире и сделать C layout ещё дороже; меньший source wrapper count
не является доказательством меньшего allocation. При малой admin-доле B отвергается.

#### C — семантический descriptor как IR-объект с владельцем и областью

`[ФАКТ]` `backend_lower.describe:293-306` создаёт descriptor и нормализует его;
`descriptor_nf.normalize:729-742` материализует NfVal обратно в дерево;
`CLay.layout_of_desc:417-432` снова вызывает NF. Closure сохраняет body/env, а quotation
создаёт DescriptorLet и переносит уровни binder (`descriptor_nf.bend:95-104,292-328`).
Это настоящий межфазный round-trip, но его доля в deadline пока неизвестна.
**Дизайн.** Разделить raw descriptor code и scoped semantic value: immutable DAG handles,
persistent environment frames и явная quotation на границе, где действительно нужен descriptor.
Catalog/Lower/NF/physical consumers работают с одним отдельным backend-owner, не с FIR Arena;
source handles/Scope туда не уходят (`checked_frontend.bend:16-19`; `BIR_LAWS.md:65-87`).
Construction sharing сохраняет общие подвыражения; это смена IR/lifetime, не blanket query cache.
**Главный proof-cost:** `nf(materialize(v))` нельзя объявить бесплатным/idempotent.
Нужна scoped simulation прежнего запроса, включая расход **его** fuel, failure/opaque и
quantity-prefix insertion (`descriptor_nf.bend:407-438,648-703`); при невозможности доказать
shortcut остаётся обычное вычисление над новым IR, а не выдуманный «уже нормализован» флаг.
**Дешёвый опыт:** один путь `PrimitiveCall.types` от describe до array-cell, с подсчётом
materialize/reparse/NF work и differential result/fuel на малой таблице исходных запросов.
**Consumer-фальсификатор:** captured alias под дополнительным arrow binder, два generic-instance,
under/over-application и fuel0/1/1024; сравнить C/JS array get/project и реальные ошибки.
**Цена:** backend_ir/NF/Catalog/Lower/JS/C physical и hand-built BIR fixtures; норматив дерева
`backend_ir.bend:4-5` меняется на well-founded DAG. C value ABI не меняется, но arena retention
может увеличить peak heap; нужен срок жизни до последнего consumer, не глобальная таблица.

#### D и E — независимые альтернативы, не запасные объяснения старого профиля

**D, delta sharing.** `s_analysis_round` перечитывает девять наборов, затем повторяет round
(`c_backend_sharing.bend:2726-2753`); bound выводится из lattice-size (`2787-2811`).
Обратные зависимости value/pay/callee/hot позволяют запускать transfer только после изменения:
вместо `R × полный facts-scan` — сумма затронутых edges по lattice deltas, плюс построение индекса.
Это улучшение алгоритма при разреженном распространении, не гарантированное O(V+E) для всех inputs.
**Опыт/фальсификатор:** сравнить полные SharingPlan и transfer-count на длинной call/capture цепи,
цикле Apply и IO.bind с поздно известным payload; потеря hot/array_shared либо иной failure отвергает D.
`forced/note` сбрасываются между rounds (`2753`): нельзя монотонно «зафиксировать unknown»;
нужны финальная стабилизация diagnostics и прежняя authority ошибок. Схема результата/ABI прежняя,
но reverse-edge heap новый. Правки в sharing/facts и fixtures; сначала доказать, что sharing заметен.

**E, shallow storage.** Нынешняя ABI разворачивает поля, пакует 0/1-w32 node и inline ≤8 words
(`c_backend_layout.bend:15-42,563-578`), поэтому и нужны recursive layout/conversion obligations.
Один Term на live-field устраняет целый класс flatten/reentry для storage, но не NF для SHOW/IO/types.
**Опыт/фальсификатор:** отдельно разрешённый alternate-representation compiler, nested record/array,
foreign C round-trip и shared projection/drop; несовпадение payload/keep/drop либо рост памяти против
исходных ограничений отвергает вариант. Измерять и compile, и runtime, не только более быстрый emitter.
Меняются Cid arity, packed nodes, arrays, foreign sources и runtime walkers; C/JS relation и ownership
нужно доказать заново. **Не рекомендован без отдельного решения пользователя об ABI/representation.**

#### Общие инварианты и следующий эксперимент

Для A–E сохраняются first-declaration authority, generic args/closure env, quantity prefixes,
dependent/erased ordinals, unknown/missing/failure, target+path-sensitive seen. `reaches` при fuel0/NfFail
возвращает False (`c_backend_layout.bend:624-654`), **не** сертификат отсутствия пути для другого бюджета.
FIR-факты per-invocation, publication до rewind: backend-owner не разрешает term-handle-only memo (`FIR_LAWS.md:148-183,208-215`; `BIR_LAWS.md:68-87`).

1. **Лучший следующий опыт — discriminating demand-census A**, предварённый bounded diagnostic
   нового аутентичного stage1: parent получает phase entry/exit parse/expand/check/lower/catalog/
   context/cid/render и счётчики node_declared/NF/reentry плюс machine transitions/allocations.
   SHOW=0 — проверяемое ожидание из IO-ветки. Хранить вложенность; inclusive spans не складывать
   как exclusive CPU, heap snapshots не выдавать за allocations. Не повторять неизменённый failed target.
2. Если A действительно сокращает дорогой demand, реализовывать coherent projection/dispatch cutover,
   затем неизменённый original consumer. Если union не сужается, **fallback B** допускается только
   при заметной измеренной admin-стоимости; иначе рассматривать C по его собственному round-trip census.
   D имеет смысл при подтверждённом sharing-bottleneck. E не является автоматическим fallback.
3. Любой кандидат проходит исходные native build + настоящий native fixedpoint +95 seed/190 fresh,
   C62/JS67/native33/admission12/host5; только затем все original strict12: mean и median времени
   строго ниже в каждом lane, оба memory median не выше. 8/8 GiB, 600000 ms, poll10 ms,
   ABI13, parser fuel8M/module и quantum64 не меняются; diagnostic subset не заменяет acceptance.

`RadicalCostReviewer` независимо подтвердил IO/CID-path, приоритет protocol specialization и fallback typed frames.
Его ограничения включены: общий Pending может сохранить весь demand, frame-union — ухудшить layout.
«Достаточно lazy context» отвергнуто по двум consumers; semantic-work против CPS-admin остаётся неизвестным.
Общий rewrite «всё boxed / новый runtime» требует ABI/heap-решения; ещё больше LLVM partitions — не лечение stage1 emit.
Рекомендация: сначала убрать **обязательство обрабатывать ненужное**, а не ускорять ещё один NF-вызов; кратный выигрыш не обещан.

### G44D1–D3: выполненный work/demand census и пересмотр приоритета

**Статус:** диагностический эксперимент выполнен; ускорение компилятора и новая
acceptance **не заявлены**. Принятый compiler остаётся G24R12. Реализация:
`evals/compiler_work_census.mjs`, `compiler_demand_census.mjs`,
`compiler_demand_diagnostic.mjs`; opt-in интеграция в `candidate_host.ts`.
Компактный результат: `checkpoints/local2039g44d3-outcome/outcome.json`.

#### Настоящий producer и наблюдаемый carrier

Свежий ordinary native producer построен с LLVM split4/max3 children:
252515 ms, RSS5665619968 B, footprint5654124016 B, 12456 checked definitions.
Он действительно parse/expand/check/emit диагностический compiler-root:
95292 ms, 33752735 B, SHA256
`b49b2633c30e59e3372d302e2aa39dbb8779750ca235311fc62ba5a4c6d47202`.
Это native-produced stage1, **не** TS/root.js; stage2/fixedpoint/95+190 не запускались.
Native run использует прежний CLI300000 ms; scheduler — исходный guard600000 ms.
Оба сохраняют RSS/footprint8192 MiB, parser8M/module и quantum64.

`emitter_step_lower.ts --trace-census` генерирует отдельные source/manifest paths
и24 canonically authenticated sites. Обычные no-flag и `--trace` пути не
получают Program payload. Свежая ordinary-генерация после исправлений сохранила
точные байты `emitter_steps_v1.bend`: SHA256
`7f7c8d2e57a3fcd3925b4286a8300668ae91b7e11a26317cea6da2df5c9ea425`.

Passive samples не гарантируют BIR: Direct прячет arguments в invoke, а
RunSpan.next — request; quantum может проскочить Pending. Поэтому census-only
TraceSite/RunSpan передаёт настоящий immutable `BIR.Program` на Begin
`c_backend.plan_make`. Никакой observer не вызывает next/invoke/resume,
не обходит FIR Arena и не сохраняет native Run/Program в отчёте.
Derived binding проверяет исходные native build/run receipts и runtime source
corpus; это не поддельный `JS_GENERATED` receipt. Public exports остаются13.

#### Реально упражнённые проверки и отвергнутые версии

- G44D1 **отвергнут**: native checking нашёл пропущенный payload в двух
  RunSpan patterns; образ не произведён. Source+inputs+failure:
  `selfhost/g44d1-rejected`, checkpoint `eb9c2d72`.
- G44D2 произвёл настоящий образ. Existing `c_target_show_data.bend` прошёл
  stage1→C→clang→execution с буквальным ожидаемым stdout; реальный BIR захвачен,
  SHOW Begin положителен. Семантический контроль включает captured alias,
  recursive sum, два generic instances и shifted field scope.
- Длинный scheduler census G44D2 сохранил валидный120-second prefix, но команда
  **отвергнута**: caller передал collector неподдерживаемый status
  `diagnostic-stopped`. Failure не переписан в PASS:
  `selfhost/g44d2-rejected`, checkpoint `5485d2fe`.
- G44D3 использует поддерживаемый `aborted` только для tagged diagnostic stop;
  прочие ошибки пробрасываются. Actual short-stop smoke подтвердил exit0,
  reaping, непродвинутую stop-boundary и отсутствие частичного C.
- Затем исходный scheduler, полный импорт checker, genuine image и original
  Node Worker прошли новый20-second observation: `DIAGNOSTIC_OBSERVED`,
  guardian PASS149781 ms, RSS2507538432 B, footprint2685647296 B, tree stopped.
  Это **намеренная остановка**, не завершённая C-компиляция.
- Existing stage/native contracts:19 PASS; throwaway demand consumer smoke:
  7 PASS — roots/exports, first declaration, unresolved Apply/reference,
  cyclic input и getter non-execution. Это не замена compiler acceptance.

#### Где действительно тратится работа

В G44D3 host-phase spans: import577.819 ms, parse6119.344 ms,
expand5886.220 ms, check113400.198 ms, emit22830.677 ms до abort.
В20-second emit observation `lower` завершён за3387.469 ms (inclusive).
Затем context вошёл в первый `node_declared` и до cutoff его не закончил.
Последняя constructor row — `CheckerRunState`; generated CPS сначала
вычисляет tail (`emitter_continuation_1464`/`emitter_match_1465`), поэтому
именно её canonical layout — первый узел планирования, не догадка по имени fixture.

| Marked boundary | G44D3 Begin, 20 s | G44D2 Begin, 120 s (finalizer rejected) |
| --- | ---: | ---: |
| descriptor `nf` | 2496106 | 19222273 |
| `family_reach` | 273853 | 2113374 |
| `reach_arms` | 677560 | 5224234 |
| `reaches` | 363935 | 2806392 |
| `node_declared` | 1, End0 | 1, End0 |
| `cid_rows` | 0 | 0 |
| `CBackend.render` | 0 | 0 |
| `show_build` | 0 | 0 |

Это counts движка данной instrumented composition, не CPU-доли и не времена
обычного compiler. Begin предшествует callee; открытые вызовы не получают
выдуманный End. NF End2496094/19222264 соответственно. Observer callback wall
6483.633/39395.938 ms перекрывает spans; trace/inspector имеют и другие расходы,
поэтому вычитать эти числа и «восстанавливать baseline» нельзя. Нельзя
складывать recursive inclusive spans. Host samples не считают все internal64
transitions или allocations. Новый census не читает reach-target: Sigma
известна из старого R11D2, не объявляется заново измеренной целью G44.

#### Решение по архитектуре

Actual BIR полностью структурно проверен: 1339502 visited nodes, 10469 code
rows, 6442 declaration rows (один duplicate), 1445 constructors,145 families.
Conservative analysis оставляет все10469 bodies и1445 layout roots из-за
Apply/foreign unknown flow. Manifest точно сопоставляет1161 request tags;
общий dispatcher статически достигает1159 handlers и4132 code bodies.
370 tags конструируются в may-reach code; отсутствие конструкции остальных
**не** сертификат невозможности, ветви не удалены.

**Обычная DCE/lazy-context не принимается как следующий cutover.** Нужный
runtime `CheckerRunState` нельзя просто удалить, а его type closure всё ещё
содержит общий протокол. Полная private-protocol specialization не опровергнута,
но требует constructor-tag/closure-flow proof и согласованной representation,
а не обрезания исходных family arms. Existing sharing Flow хранит family heads,
не точные constructor tags (`c_backend_sharing.bend:2218-2224`); он не готовый
сертификат для такого pruning.

Следующее приоритетное направление — **backend-owned semantic descriptor/query
DAG для layout/reentry**, вместо разворачивания повторных instantiated обходов.
Первый falsifier: число различных полностью scoped запросов против всех
вычислений. NF identity включает context/descriptor/env/output level/fuel;
reach также target и seen. Если повторов мало, мотивация sharing отвергается
до большого IR rewrite. Никаких term-handle-only/pretty-name caches,
свидетельств отсутствия из NfFail/fuel0 или предположений NF-idempotence.
Storage-directed projection должна отдельно доказать прежние Bool/error
результаты; полная нормализация для других consumers остаётся обязательной.
First-order continuation rewrite остаётся условным: эта трасса меняет CPS/yields
и не доказывает administrative share обычного образа.

Все original native fixedpoint,95+190, C62/JS67/native33/admission12/host5 и
strict12 сохраняются. C-only улучшение всё ещё не означает ускорения JS-library
throughput в обоих strict12 runtime-lane.

### G45D1–D3: точные scoped запросы NF/reach

G45 — диагностический carrier и измерение, **не ускоренный компилятор**.
Accepted compiler остаётся G24R12; stage2/fixedpoint и strict12 здесь не заявлены.
Исходники carrier — `ad77692a`, regression tests — `2400219d`, итоговый host
budget — `faad7519`. Frozen Bend/foreign input corpus — `3623bddf`;
G45D3 contract — `1dc90599`.

#### Реализация и проверка carrier

- `emitter_step_lower.ts --trace-queries` создаёт отдельный typed emitter engine,
  сохраняя 24 census roots. На Begin NF передаётся Data
  `context/descriptor/env/level/fuel`, reach —
  `context/descriptor/env/target/seen/fuel`. Типы и количества берутся из
  canonical source declarations; non-variable arguments получают typed ANF
  bindings без повторного вычисления. End сохраняет пустой payload.
- `compiler_query_census.mjs` интернирует полную структуру аргументов без hash
  collisions: qualified tags, quantity prefixes, binders, closure bodies/env,
  порядок списков, дубликаты и дерево Base.Map участвуют в ключе. Контекст
  дополнительно разделён по object identity: это консервативное пере-разбиение,
  а не критерий семантической эквивалентности. Getters/proxies/closures не
  исполняются. Неполный ключ никогда не увеличивает число distinct queries.
- Host аутентифицирует raw native producer receipts, artifact, generation
  manifest, canonical sites и обе полные argument schemas. Immutable Data
  carrier позволяет bounded weak identity memoization; нативные аргументы
  не сохраняются в отчёте.
- Ordinary, `--trace` и `--trace-census` engine + component outputs совпали
  с предыдущими байтами: **6/6**. **35 tests PASS**: 16 новых consumer-visible
  identity/censor regressions и 19 прежних stage/native contract tests.

Genuine native producer `e014f680…` с неизменённым ordinary compiler corpus
собрал новый stage1, не TS/root.js: **95.329 s**, RSS **1851424768 B**,
footprint **1847167520 B**, guardian PASS, owned tree stopped.
Image **33811672 B**, SHA-256
`35f3ff8662664a7961aecf46fa8bf1d2dff26450521b1778ade158bc3c4ed1ec`.
Parse/expand/check/emit прошли полностью. ABI13, parser8M/module, quantum64,
native threads1 сохранены. D2/D3 меняли только внешний observer, поэтому
переиспользовали этот же образ с повторной аутентификацией всех raw pins.

Этот stage1 через Node Worker действительно скомпилировал
`c_target_show_data.bend` в C; clang `-O0` собрал C, executable напечатал прежний
`ShowReport`. Emitted C побайтово совпал с G44D2:
`8c9e0eebd03aeaa4036a8556376d9ee2d5a3de9287738a397b126815aaaeb8f5`.
Actual BIR capture и positive SHOW-entry control сработали. Все 4781 query
observations этого маленького consumer классифицированы, без unsupported
или censored observations.

#### Отклонённые измерения не переименованы в успешные

| Версия | Результат | Причина |
|---|---|---|
| G45D1 | Rejected scoped census | Per-query observer work2M оборвал первый полный NF context; classified prefix0. Command/guardian PASS не означают ответ на вопрос об уникальности |
| G45D2 | Rejected command | Host передал work32M выше разрешённого module ceiling16M; initialization завершилась ошибкой, query report отсутствует |
| G45D3 | Observed bounded prefix | Поддерживаемый work16M; prefix завершился на cumulative weak-entry cap1M, не на ошибке компилятора |

D1 checkpoint `81ba8747 / selfhost/g45d1-rejected`, D2 —
`0e12fd6b / selfhost/g45d2-rejected`. Перед D3 отдельный synthetic observer
smoke выполнил cold query с **6977964** work units: старый work2M censor,
work16M дал точные distinct/repeat/fuel различия. Это проверка измерителя,
не дополнительный compiler workload и не performance evidence.

#### Исходный scheduler: полностью классифицированный префикс

Тот же `scheduler_chunk_smoke.bend`, исходный checker engine, полный source
closure, `IO(Unit)` и Node Worker. Guard **8192 MiB RSS + 8192 MiB footprint**,
poll10ms, timeout600000ms; bounded emitter window20000ms. Whole command
**156556 ms**, RSS **2408398848 B**, footprint **2744527456 B**;
guardian PASS, owned tree stopped, finalizer `aborted` по intentional stop.
Startup659.537ms, parse/import/fuel10940.752ms, expand5871.434ms,
check115378.441ms, emit22705.635ms до остановки. Это не завершённая C build.

| Query | Classified calls | Exact distinct keys | Exact repeats | Repeats / classified |
|---|---:|---:|---:|---:|
| NF | 306286 | 28769 | 277517 | 90.607% |
| Reach | 44360 | 2996 | 41364 | 93.246% |

Это **весь последовательный префикс350646**, не sampled estimate.
После cap оставшиеся **822676** observations censored; весь Run-window
содержит1173322 queries. Их нельзя приписывать ни новым, ни повторным ключам
или экстраполировать на них проценты таблицы. Unsupported0.

NF: descriptor239, env75, level1, fuel51; **13642 context objects имеют одну
полную структурную форму**. У reach: context1, descriptor62, env43, target1,
ordered seen1402, fuel18. Дополнительное разделение NF по object identity
намеренно завышает distinct count. Projection без context даёт1559 ключей,
без seen у reach —516, но эти projections **не разрешение удалять поля ключа**
и не доказательство безопасности кэша.

Observer retained accounting **75435672 B**, interned nodes21526, weak
insertions1000000; peak work/query3778190 объясняет D1 failure.
Weak count — cumulative insertions, не live heap. Callback wall11565.721ms
перекрывается с phase spans и включает census: его нельзя вычитать и объявлять
остаток baseline CPU или speedup.

Actual BIR снова прошёл полный validator:1339502 nodes,10469 code rows,
6442 declaration rows,1445 constructors,145 families,26 type functions.
`node_declared`1 Begin/0 End; `CBackend.render`, `cid_rows`, SHOW и link rewrite
не вошли. Первый layout всё ещё не завершён; wrapper `CEmit.render` уже вошёл.

#### Решение: sharing мотивирован; большой IR rewrite ещё не оправдан

Первый falsifier пройден: точные повторные NF и reach запросы существуют
массово **даже с полным env/fuel/seen и консервативным context identity**.
Следующий кандидат — bounded backend-owned semantic query store/DAG, а не
ещё один plain DCE, глобальный pretty-name cache или запуск всех обходов
одновременно.

1. Оставить FIR/checker binding semantics неизменными. На границе
   lowering/catalog/layout дать immutable scoped context, descriptors и env
   spines стабильные IDs; canonical declaration authority и quantity/erasure
   metadata не теряются. Не начинать с полной смены FIR/BIR representation.
2. Первый exact-query прототип сохраняет ключи
   `NF(contextId, descriptorId, envId, level, fuel)` и
   `reach(layoutContextId, descriptorId, envId, targetId, seenId, fuel)`.
   Store принадлежит одной compilation; результаты сохраняют прежние Nf/Bool,
   errors и budget behavior. NfFail/fuel0 не становятся отрицательными
   сертификатами при другом budget. Никакой NF-idempotence не предполагается.
3. Только после устранения повторов планировать независимые ready DAG nodes
   параллельно; финальные node/Cid rows сохраняют исходный порядок. Сам этот
   census не доказал ни экономию wall time, ни weighted стоимость повторов,
   ни допустимость такого scheduler cutover.

Риск: measurement локализует C layout/reentry, но не устраняет измеренные
115.378s frontend checking и не доказывает ускорение JS-library. Любой кандидат
всё ещё обязан пройти genuine fixedpoint,95+190,C62/JS67/native33/admission12/
host5 и исходный strict12 в обоих native+JS runtime lanes. Без этого accepted
compiler не меняется. Exact commands, guards, image/source hashes и scope
ограничения сохранены в `checkpoints/local2039g45d{1,2,3}-outcome/`.

### G46R1: реальный exact-query memo — semantic probes PASS, cutover REJECTED

**Результат:** исходный полный scheduler не завершил C emission за прежние
600000ms. G46R1 отклонён, не принят как ускорение. Candidate source —
`57f4643a`, frozen compiler inputs — `ca64b654`, полный rejected checkpoint —
`592d5170 / selfhost/g46r1-rejected`. Main canonical NF/layout, generator и host
возвращены к принятому исходнику коммитом `307dba84`; G24R12 остаётся accepted.
Исходники, обязательный frozen corpus и regression inputs кандидата сохранены
в ветке, не в виде patched image. Новый `--memo-queries` CLI остался только там.

#### Что действительно было реализовано

Две независимые implementation slices: pure Bend structural codec/Store и
dependent typed CPS scheduler integration. Это не host JS Map:

- `descriptor_key.bend` кодировал все Descriptor/DescriptorPattern и полные
  family/type-function metadata без hash collisions. `semantic_query.bend`
  сохранял полные Nf/Bool в typed persistent maps; descriptor/env encodings
  интернировались в IDs. Scope factory вычисляла реальный полный ключ один раз;
  native scheduler заменял только metadata scope на disjoint local token.
- Ключ NF сохранял scope/descriptor/env/output level/fuel; reach —
  scope/descriptor/env/target/ordered seen/fuel. Closure body/capture, arrow/
  binder levels, quantities, declaration order/duplicates и весь layout Plan
  участвовали. False и NfFail оставались результатами ровно своего ключа.
- Один bounded Store жил внутри одного Run. Combined result limit100000,
  каждый scope/descriptor/env interner limit100000; при capacity результат
  вычислялся прежним evaluator без вставки, не угадывался.
- Lookup/save/scope intern сами исполнялись source CPS. Miss return получал
  latest Store после вложенных запросов; affine continuation передавалось
  ровно один раз. Никаких host resume calls, closure/getter peeking или unsafe
  Bend casts. Final Run возвращал только Data Report, не удерживая Store.
- Public exports13 и quantum64 сохранены. Source Run representation изменилась
  явно: отдельный protocol `typed-native-stack-v58m`, собственные output paths,
  memo slot в RunState и report в RunFinished. Это **не** заявление о source
  constructor ABI compatibility со старым v57t.

Generation PASS7.844s; все35 прежних contract tests PASS,103 assertions.
Genuine unchanged native producer собрал оба образа с полными parse/expand/
check/emit, parser8M/module, threads1, без TS compiler image или output patches:

| Native-produced image | Whole producer guard | JS bytes |
|---|---:|---:|
| Frozen ordinary baseline | 89.858s | 31758507 |
| G46R1 memo | 93.609s | 33945054 |

Это стоимость производства разных compiler images, **не throughput comparison**.
Memo SHA-256:
`3e10258078cf5d16cba3ba7f727d35408ed42ba3a279cddea8151adcf2cb0a46`.

#### Реальный consumer и полные semantic regressions

Memo image через Node Worker выдал C для `c_target_show_data.bend`; clang
`-O0` собрал C, executable напечатал правильный ShowReport. C побайтово
сохранил SHA-256
`8c9e0eebd03aeaa4036a8556376d9ee2d5a3de9287738a397b126815aaaeb8f5`.
Native Report: NF586 hits/664 misses, reach60 hits/150 misses,814 result entries,
254 descriptor/env IDs,3 scopes, disabled0. Это реальные source lookups, не
observer-derived estimates. Emit guard30.465s, clang1.370s, executable0.014s.
Скорость малого consumer не объявлена улучшенной.

Отдельные frozen typed Bend probes построили native Pending requests внутри
source; host продвигал только публичный opaque start/step. Оба probe artifacts
полностью собраны прежним native producer. **24 NF +15 reach cases**, каждый
с normal Store и capacity1, дали те же полные Nf tagged values/Bool, что
неизменённый evaluator. Проверены fuel0/1/default, reducer/cycle errors,
разные contexts/env, captured closure body/env, binder/arrow levels, quantities,
target/ordered seen, сохранение False и capacity fallback.

Normal probe: NF10 hits/35 misses, reach4 hits/12 misses, scopes4, disabled0.
Capacity1: ровно1 result entry,2 descriptor/env IDs,1 scope, disabled65;
семантические результаты не изменились. Сопоставление constructor namespaces
в comparison использовало pinned source type declarations, не меняло keys
или declaration authority.

Probe harness v1 был отдельно отклонён: native checker правильно запретил
неструктурную рекурсию `finish(run)`. В v2 loop перенесён в trusted host,
как в production runtime; native termination/fuel не ослаблялись.
Исполнен JS-runtime lane компилятора и C executable контрольной программы;
native-runtime compiler lane и fixedpoint этим не доказаны.

#### Исходный scheduler: отрицательный performance result

Никакой замены fixture, checker engine, source closure, IO branch или rows.
Guard:8192MiB RSS/8192MiB footprint, poll10ms, timeout600000ms.
**FAIL deadline_exceeded**, elapsed600159ms, peak RSS2423259136B,
footprint2536932888B, signal15, complete guardian report, owned tree stopped.
C не был выдан; clang/runtime stages исходного scheduler не запускались.
Memory cap не был причиной остановки.

Последний checkpoint: startup615.804ms, parse/import/fuel5778.325ms,
expand5946.415ms, check106387.175ms completed; emit оставался active.
На elapsed599136ms наблюдалось27350386 host-step calls, quantum64.
Последний once-per-second Pending sample:
`descriptor_key.bend:strings_chunks`. Это **не exclusive CPU attribution**,
не доказательство единственной причины timeout и не live status после kill.
Final memo report отсутствует: Run не закончен; счётчики малого consumer
нельзя экстраполировать на этот scheduler.

#### Решение и следующий falsifier

Exact sharing семантически реализован и выдержал boundary probes, но G46R1
не удовлетворил обязательному consumer gate. Повторы G45 не превращаются
автоматически в выигрыш: повторная сериализация descriptor/env/seen, source
lookup/save и дополнительные CPS transitions тоже стоят работы.
Данных для принятия этого cutover нет; неизменённый failed target не повторялся.

Следующий обоснованный вариант — **construction-time backend-owned handles**:
descriptor/env/scope IDs должны приходить из владельца при построении, а не
создаваться повторным tree-to-string обходом на каждом запросе. До нового
большого rewrite отделить measured key preparation/intern/lookup/save work
от evaluator work; не выдавать sparse Pending samples за CPU профиль.
Это не разрешает убрать context/env/fuel/seen, использовать FIR term-handle
или cached NfFail как отрицательный сертификат другого budget.

Full fixedpoint,95+190, C62/JS67/native33/admission12/host5 и strict12 после
necessary consumer failure не объявлялись пройденными и не заменялись probes.
Failed source/input/outcome checkpoints сохранены до rollback. Exact commands,
runtime/resource receipts, scalar counters и failure boundary —
`checkpoints/local2039g46r1-outcome/outcome.json`; source restoration smoke
сохраняется отдельным receipt рядом с ним.

Rollback проверен реальным restored-main host и authenticated ordinary image:
C emission20.688s, clang1.217s, executable0.015s — все три process guards PASS,
ShowReport правильный. Raw restoration controller сохранил FAIL у избыточного
cross-checkout byte-hash assertion: полный diff показал ровно29 absolute
`effect source` comment paths, все остальные строки C одинаковы. Артефакты не
правились; assertion не перепинён и не повторён. Это функциональный smoke,
не byte-fixedpoint proof. Предыдущий auth-only harness failure из неверного
cwd также сохранён; проверка pins не ослаблялась. Полный raw result и этот
разбор находятся в `checkpoints/local2039g46r1-outcome/restoration.json`.

Итог: rejected candidate сохранён, production source восстановлен, незавершённых
stub/alias paths от G46R1 в main не оставлено.

### G47R1: construction-owned IDs — semantic/C controls PASS, cutover REJECTED

Кандидат находится в отдельном worktree и ветке
`selfhost/g47r1-rejected`; принятый G24R12 в main не менялся.
Source checkpoint — `6cea14ae`, исправленный construction-owner closure —
`17a1a7cd`, frozen generated inputs — `59c48e63`, semantic proof —
`cc7dd127`, полный native-produced image — `862617eb`, C control —
`c5d73e60`. Это эксперимент, не новый accepted compiler.

#### Что изменилось относительно отклонённого G46R1

Все 24 `BIR.Descriptor`, 2 `DescriptorPattern` и 9 `NF.NfVal`
constructors получили служебный `Maybe<Nat>` identity. Semantic environments
теперь несут `NF.Env`, ordered reach histories — `CLay.Seen`. Изменённые
env/seen создаются заново; исходные argument/binding lists остаются списками.
Contexts получают свежий scope при настоящем создании, без сериализации
families/type-functions/Plan. Эквивалентность разных contexts не предполагается.

Typed CPS сначала вычисляет semantic fields в исходном порядке, затем запускает
source key/allocation continuation и один раз строит окончательное значение.
37 node-key helpers читают только scalar fields и уже назначенные child IDs;
списки непосредственных детей обходятся при construction, не в query lookup.
NF/reach lookup читает существующие IDs и fixed-arity scalar key, сохраняя
полные scope/env/level/fuel/target/ordered-seen inputs. Старый recursive
`descriptor_key.bend` удалён из кандидата.

39 constructor schemas, helper types, owned native BIR declarations,
construction sites и no-bypass/root-input проверки аутентифицированы.
Protocol — `typed-native-stack-v59i`, memo v2, quantum64; public ABI13 прежний.
BIR не переносился в composition: `Program`/`SourceFile` сохраняют владельца.
Graph cap500000 и combined NF+reach result cap100000 отдельные; IDs монотонны
и не переиспользуются. Отсутствующий ID или достигнутый cap означает обычное
вычисление, не выдуманный результат. Store принадлежит одному root Run.

Первый source attempt был отклонён настоящим ownership guard:
native `c_backend_sharing.s_decl_build` создавал descriptor вне allocation.
Исправление — включить canonical sharing provider в CPS, не ослабить guard.
Source generation после исправления PASS:2671 definitions,104 construction
sites; это статические количества, не execution counts.

#### Native producer и runtime proof

Неизменённый native producer `e014f680…` действительно выпустил compiler image
из17 source+35 foreign inputs. Parser fuel8M/module, threads1, GPUoff,
native Run quantum64; guardian8192MiB RSS/footprint, poll10ms, CLI300000ms.
Whole producer guard102.401s, peak RSS1863532544B/footprint1946438296B;
это производство другого artifact, **не paired throughput comparison**.
JS image36066688B, SHA256
`70510fbfbce975d24d5608b32e945b371a8035727ceafc4e2ab05291f787d41b`.

Две ошибки transport harness сохранены отдельно: неправильный workload cwd
был остановлен repository-containment guard; клонированный corpus с лишним
уже composed sharing module был остановлен полным fuel/module accounting.
Вторая попытка напечатала EmitSuccess, но её image не использовался как PASS.
Исправлены cwd и exact corpus через существующий `workloadRows/corpusFile`;
pins, containment, fuel coverage и resource limits не ослаблялись.

Отдельный native-produced typed probe library прошёл все12 source+35 foreign
inputs за58.364s. Host продвигал только публичные opaque start/step.
24 NF+15 reach outcomes совпали с неизменённым evaluator во всех четырёх
парах `(result cap,node cap)`: `(100000,500000)`, `(1,500000)`,
`(100000,1)`, `(1,1)`. Comparison удаляет только зарегистрированное identity
metadata и разворачивает `NF.Env`; полные semantic fields, NfFail и Bool
сохраняются. Проверены разные contexts/env, closures, binder levels,
fuel0/1/default, quantity, target, ordered seen, errors/False и обе ёмкости.
Node runtime guard592ms, RSS300498944B/footprint235835928B.

Normal probe: NF10 hits/36 misses, reach4/12,50 nodes,5 scopes,
191 allocations/136 constructor-key hits. Ровно1 unowned query — намеренно
внесённый сырой descriptor с None; его обычный результат также совпал.
Пять contexts различны, включая два с одинаковыми metadata; seen order и
duplicates не смешались; одинаковые построенные empty env делят node ID.
При graph cap1 ни один query result не вставлен, полные ответы те же.

#### Настоящий C control

Тот же исходный `c_target_show_data.bend` из неизменённого producer checkout,
Node Worker и новый native-produced image действительно прошли все стадии:

| Стадия | Single-run guard, s |
| --- | ---: |
| Emit C | 32.621 |
| clang `-O0` | 1.555 |
| Executable | 0.014 |

Правильный ShowReport; все C bytes сохранили SHA256
`8c9e0eebd03aeaa4036a8556376d9ee2d5a3de9287738a397b126815aaaeb8f5`.
NF573 hits/679 misses, reach60/150,699 nodes,5 scopes,
4902 allocations/4198 node hits, disabled0/unowned_queries0.
Это доказательство работающего construction-owner path, **не ускорение**.
Оба независимых read-only reviews не нашли ошибок в своих source/CPS срезах;
runtime evidence они не заменяют.

#### Исходный scheduler: cutover REJECTED

Один неизменённый original source/import closure, тот же Node Worker,
8192MiB RSS/footprint, poll10ms, timeout600000ms:
**FAIL deadline_exceeded**, whole guard600.284s, peak RSS2470150144B,
footprint2613680392B, signal15, ownedTreeStopped=true. Это не memory-limit
failure. C не выдан, clang/executable не запускались; final memo Report
также отсутствует, поскольку Run не закончен. Failed target не повторялся.

Последний pre-kill checkpoint599124.054ms: startup720.168ms,
parse5921.359ms, expand5877.830ms и check114262.038ms completed; emit active,
23622487 host-step calls. Последний sampled boundary — Direct; предыдущий
Pending на598124.009ms — `semantic_query.bend:vals_chunks`.
Это once-per-second observation, **не exclusive CPU attribution** и не
доказательство единственной причины timeout; persisted `running` не является
live status после guardian reap.

Construction IDs реализованы, но нужный consumer gate по-прежнему не пройден.
Текущий `Env{values:List<NfVal>,identity}` всё ещё обходит immediate value
list при construction; IDs не превращают raw descriptor payload в физически
канонический DAG. Следующий falsifier — отдельно измерить construction-key,
lookup/save, evaluator и CPS-admin work; persistent env/seen spine IDs имеют
смысл проверять при подтверждённой construction-стоимости. Sparse sample
сам по себе такой приоритет не доказывает.

Full native-runtime lane, stage2/byte-fixedpoint,95+190,
C62/JS67/native33/admission12/host5 и strict12 после necessary consumer
failure не запускались и не объявлены пройденными. Promotion не разрешён.

Полный rejected source и regression inputs — ветка `selfhost/g47r1-rejected`;
компактный итог — `checkpoints/local2039g47r1-outcome/outcome.json`.
Exact commands, runtime/limits, source/image hashes, неудачные harness attempts,
semantic proof и original deadline сохранены. Принятые compiler sources не
требовали rollback: G47 работал в отдельном worktree. Throwaway controllers
удалены; executable/JS images, runtime payloads и bulk logs остаются вне Git.


### G48D1: representative fast development fixture — not compiler promotion

`evals/semantic_scheduler_perf.bend` is a 273-line, 10337-byte runnable
development surrogate, not a flat Show workload and not the original gate.
It retains the four generic Value/Progress/Stack/Run families and all nine
constructors, erased type parameters, `result(request)`, heterogeneous
continuations, equality cast, Pending/Direct/Bound, owned Array capture and
the original chunk/advance/pop algorithm with quantum64. All retained request
arms execute; literal stdout covers the scheduler boundaries and checksums.

`semantic_scheduler_perf_shape.ts` compares actual parser ASTs, binder-ID
scopes and quantities, not source spelling. All11 core schema/body/signature
comparisons matched in small, medium and large. Request widths intentionally
differ: the frozen original has19 groups/1161 constructors; the development
presets have1x4,2x8 and4x16. This is not a proof of termination, native
equivalence, matching cost distribution or original-source qualification.

`evals/semantic_scheduler_perf/bend2/base.bend` keeps62 of511 original Base
declarations. `semantic_scheduler_perf_base.ts` computes their source-reference
closure **plus implicit runtime constructor roots from the actual
`c_backend.runtime_cid_aliases` AST**. Bodies stay original; foreign paths
resolve to the original print.c/print.js bytes. Keep the `/bend2/base.bend`
suffix: `lower_catalog.base_source` uses that module identity for scalar/IO
native markers. An arbitrarily renamed prelude loses those markers and is
not an equivalent source-compiler workload.

Earlier source-only closure attempts are explicitly rejected in receipts:
one lost native IO identity, another omitted the runtime's mandatory Fail
constructor. Neither error was bypassed. The final prelude SHA256 is
`67ab606499009c2e8ac5020133acfa0616174635b791853e1410403dd998d648`.
Original qualification still uses full Base and the original frozen corpus.

#### Measured inner loops

Bun1.4.3 `c6da4a4d3`, Node23.11.0 Worker, Apple clang21.0.0
`clang-2100.4.1.1`, darwin25.6/arm64. Runs serialized per physical host.
The benchmark retains8192MiB RSS **and footprint**, poll10ms, and a separate
20000ms development-stage budget; it does not lower a qualification deadline.
Canonical real-C oracle uses clang `-O0` and verifies every literal stdout line.

| Preset | Requests | Canonical source→C→clang→run, s | Source-compiler baseline source→C guard, s |
| --- | ---: | ---: | ---: |
| small | 4 | 0.498 median of3 | 7.339 single run |
| medium | 16 | 0.780 single run | 11.560 single run |
| large | 64 | 1.804 single run | not run |

These are different workloads/toolchains, not a compiler throughput speedup
claim. Final integrated small oracle samples also passed at0.534s/0.426s.
Fresh all-body checking with `selfhost_fast.ts` passed391 definitions in
2 modules:0.096s guard in the final warm-cache run,0.299s in the earlier run.
No checked AST replay, cached book, body exclusions, compiler/native rebuild
or changes to parser fuel/quantum are involved.

Small baseline phase wall: import596.363ms, parse391.421ms,
expand83.205ms, check2098.168ms, emit3833.248ms. The same reduced source with
the full prelude had already spent12–15s in checking alone. The small source
therefore needs the real prelude dependency slice, not only a smaller root.

The authenticated G45 query-trace image exercised the final source and
correctly identified prelude:1.000013s emitter window,6.355s whole guard,
40902 observed boundaries,6237 NF and619 reach calls, all classified with
zero unsupported/censored queries. All43 node_declared brackets closed,
matching the43 unique captured constructor rows, including PerfRunState;
show_build was never entered. The captured BIR has87 code rows,71 declarations,
23 families and8 type functions. This establishes actual generic NF/layout
work, not just similar syntax. Window timings include observer work and are
censored; they are not exclusive NF CPU or completed compilation times.

#### Commands and evidence boundaries

```sh
bun --smol evals/selfhost_fast.ts --repository=. \
  --source=evals/semantic_scheduler_perf.bend --check-only \
  --out=/tmp/bend-perf-check-01
bun evals/semantic_scheduler_perf.ts --mode=oracle \
  --source=evals/semantic_scheduler_perf.bend --samples=3 \
  --out=/tmp/bend-perf-oracle-01
bun evals/semantic_scheduler_perf.ts --mode=emit \
  --image="$IMAGE" --node="$NODE" \
  --source=evals/semantic_scheduler_perf.bend \
  --base=evals/semantic_scheduler_perf/bend2/base.bend \
  --out=/tmp/bend-perf-emit-01
bun evals/semantic_scheduler_perf_source.ts --preset medium \
  --out /tmp/bend-perf-medium.bend
```

Use a fresh output directory every run. `oracle` uses canonical TS and full
Base, then real C execution. `emit` deliberately reports
`REPRESENTATIVE_C_EMITTED_EXECUTION_UNVERIFIED`; `window` observes an
authenticated bounded prefix. Only `complete` runs the source-compiler C
artifact and checks its stdout. Emission/window success cannot turn a failed
runtime into a pass. Each sample starts a fresh source frontend/emitter and
keeps phases, hashes, guard receipts, partial progress and failed artifacts.

For the authenticated trace window, supply `--mode=window --binding=...`
`--manifest=... --window-ms=1000`, absolute source/base paths, and
`--repository` pointing at the controller checkout. Raw native producer
authentication still uses its immutable producer cwd; canonical manifest
sources are now resolved against the controller's explicitly recorded
sourceRoot, with every original hash/tamper check intact. A fail-before/
pass-after regression and all18 stage-profile tests passed.

#### New real runtime failure — deliberately still red

G47 emitted the small C artifact in9.407s guard (emit phase5573.193ms);
clang passed in0.476s. Its executable hit the unchanged8GiB physical-footprint
cap after10.973s: peak footprint8597592424B, RSS2235793408B, empty stdout,
owned tree stopped. The failed binary was not retried and no limit was raised.
Cause is unresolved; canonical C runs every expected line correctly.

Baseline and G47 source-compiler C outputs are byte-identical:
391044 bytes, SHA256
`f05909d1ee076a786487907ed74f37f056ab7d1abca04340e6e243c1273a376e`.
This does **not** establish a G47-specific regression, baseline runtime pass
or compiler byte-fixedpoint. It is a smaller useful failing consumer, not a
reason to relax the runtime gate. G47 remains rejected; G24R12 remains accepted.

Frozen small/medium/large source inputs, exact commands, toolchain/limits,
compact AST/prelude proofs, all failed harness/source attempts and runtime
rejection are under `checkpoints/local2039g48d1-fast-loop/`.
Compiler images, C/binary outputs, bulk AST/profile payloads stay outside Git.
Original scheduler, full native production, stage2/byte-fixedpoint,95+190,
C62/JS67/native33/admission12/host5 and strict12 remain separate qualification
gates. This fast-loop change does not claim that any of them passed.

### G49: five isolated source experiments, measured before any promotion

Five thorough-task-executor agents used separate `selfhost/g49-{env,reach,cps,
parts,runtime}` branches/worktrees from `dfc6f252`. Source work ran in parallel;
one guarded heavy lane serialized actual generation, full canonical JS image
admission, fixture emission and runtime work on this Mac. Source checkpoints
preceded execution. No native compiler image or bulk generated transport was
added to Git. The shared frozen ABI13 compiler input is
`checkpoints/local2039g49-compiler-root.bend`.

#### Explicit canonical-image authentication

`semantic_scheduler_perf.ts --oracle-receipt=... --source-tag=SourceFile`
forwards a distinct `candidate_host.ts --candidate-oracle=...` proof. It
requires the actual successful fully checked `selfhost-fast-ts-oracle` receipt,
current image hash and every loaded-source pin. It is mutually exclusive with
native build proof and refuses native/acceptance/fixedpoint labels or check-only
receipts. An actual tampered native-labelled receipt was rejected before output.
The canonical carrier is derived from the authenticated root, not guessed as
the native `.compiled.SourceFile` carrier. Native authentication is unchanged.
This admits a development image; it does not relabel TS production as native
bootstrap or compiler qualification.

All five full images admitted roughly12400 definitions in18 modules. The
baseline image guard took25592ms; generation/image time is separate from
the measured source-fixture pipeline. The original fixture, reduced Base,
ABI13, parser fuel8M/module, quantum64,8GiB RSS/footprint caps and10ms polling
were unchanged. Emit stages retain their20s limit.

#### Decisions from actual execution

* **Environment spine:** existing38 normalizer assertions and identical18
  scope/fuel controls passed on candidate and baseline. Three-sample pipeline
  medians small6756ms versus6747ms, medium11341ms versus11852ms.
  Not selected: mixed small effects, no general acceleration claim.
* **Visited-key map:** complete composed layout probe, including42 new reach
  assertions, ran to failures0. Three-sample medians small6588ms,
  medium11701ms against the same baseline. Not selected for these small effects.
* **Typed-sum fusion:** actual candidate and record-only baseline both returned
  `47/33/8/0/91/7/16`; one new Some/None fusion occurred in that fixture.
  Production had zero multi-constructor sites, so no production speedup is
  attributed to the new rule. Final proof infrastructure also regenerated
  byte-identical production checker/emitter sources.
* **C fragments:** all16 unchanged consumer assertions passed via the existing
  owned/CPS backend boundary. All sampled small/medium C retained baseline
  hashes. An order-balanced baseline/parts/parts/baseline discriminator found:

| Source | Baseline pipeline ms | Fragments pipeline ms | Reduction |
| --- | ---: | ---: | ---: |
| small | 6822.5 | 5730 | 16.01% |
| medium | 11768.5 | 10178 | 13.51% |

Each value is the median of two fresh processes in that order-balanced cohort.
Pipeline includes frontend/check/emit, not compiler-image building, clang or
program runtime. The fragment image build itself was28378ms versus25592ms
baseline; this is **not** a demonstrated whole-rebuild speedup.

#### The runtime failure was generated out-of-bounds code

The new diagnostic retained the original failure: the instrumented control
printed all21 expected lines, while the candidate repeated `FID_CLO_APPLY` and
`FID_0` until the unchanged8GiB footprint cap at16998ms. Sixteen print handlers
had completed; buffered empty stdout did not mean failure at the first U32.

`c_backend_physical.bend` had padded inline forms using canonical boxed-node
width instead of actual directional nested `Nest.take`/`Nest.make` widths.
Generated code wrote a four-word request's bias at5 instead of3 and a six-word
pending node's resume at7 instead of5. The observed invalid continuation loop
is consistent with those proved out-of-bounds writes; it is not a Mac-specific
performance explanation.

The isolated correction uses actual nested widths for all three conversion
directions while preserving boxed allocation/free sizes and real short-arm
padding. Fresh changed-source C then ran the **entire unchanged21-line fixture**
successfully: emit7220ms, clang779ms, runtime14ms. The focused
`tests/reg/nested_form_padding.bend` regression printed40/39/28 through both
canonical and changed-source C. The source correction remains separately
checkpointed on `selfhost/g49-runtime`; fragment/correctness combination and
native/full qualification are not silently claimed.

All experiment source revisions, exact executed commands, input/image/C hashes,
timings, sampled memory, failed harness attempts and explicit decisions are in
`checkpoints/local2039g49-batch-measured.json` and the per-branch
`checkpoints/local2039g49-parent-measured.json` receipts. Raw-module wrappers
and rejected replacement runners were removed after the correct controls.
Compiler images, generated step sources, C/binaries and bulk logs remain
outside Git. G24R12 remains the accepted image; native production, original
scheduler, byte-fixedpoint and the broader qualification gates were not run.

### G50: combined candidate passes native root bootstrap and95+190

`selfhost/g50-combined` combines only the measured C fragments and directional
nested-padding correction, without the rejected NF-spine/map/sum experiments.
The full canonical development image admitted12473 definitions/18 modules.
Actual C execution passed unchanged small21-line and medium33-line surrogates,
the40/39/28 regression and all16 fragment edge assertions. The genuine
native-produced compiler image also emitted byte-identical corrected C and
passed all three runtime inputs.

Order-balanced comparison against the **corrected padding baseline**, not the
old invalid-code baseline, retained exact C bytes:

| Source | Corrected baseline pipeline ms | Combined pipeline ms | Reduction |
| --- | ---: | ---: | ---: |
| small | 6494.5 | 5590.5 | 13.92% |
| medium | 11144.5 | 9521.5 | 14.56% |

Pipeline is frontend/check/emit-C, excluding compiler-image generation and
clang/runtime. This is not a whole-native-build or strict12 speedup claim.

The candidate then passed the supported full native chain, not a relabelled
canonical TS image: fresh in-worktree parser FULL_75 acceptance; fresh exact-root
native seed with the explicit LLVM21 split/O1 four-partition policy; native
stage1, complete semantic AST parity for all18 source modules, all95 seed
fixtures, and own-parser stage2 with byte-identical output. Both images are
31906405B, SHA256
`273b0022813e17908020c0ee58fd4e02da4f3dc756ce58e3389093440863c3fe`.
The separate existing emitted-image suite then passed all190 fresh fixtures
(95 per unchanged image). Original8GiB RSS/footprint,10ms polling,
600000ms gate, parser8M/module, ABI13 and quantum64 remain unchanged.

| Completed operation | Whole guardian ms | Sampled peak footprint B |
| --- | ---: | ---: |
| Fresh exact-root native seed build | 271420 | 5222619040 |
| Canonical full native bootstrap/fixedpoint | 512756 | 3452677072 |
| Both emitted-image semantic suites | 240605 | 2044691016 |

The source, regression tests, required frozen input corpus and compact exact
evidence are committed on the isolated branch. No images, AST transports,
C/binaries or bulk logs enter Git. Caller coordinate failures are retained,
not rewritten as passes; all successful consumer proofs use canonical
realpaths and unchanged authentication. Main's bounded pointer is
`checkpoints/local2039g50-summary.json`; the branch's full compact receipt is
`checkpoints/local2039g50-final-measured.json`.

**Native compiler-root correctness confirmed, product promotion withheld.**
Original scheduler/full C62, JS67/native33/admission12/host5 and strict12
accepted-baseline throughput remain separate gates. Accepted G24R12 is unchanged.
The own-JS-book run spends88.81% in checking (291167.482ms of327871.230ms);
that is the observed larger build bottleneck, not fragment assembly.

