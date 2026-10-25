# Selfhost stage profiling: implemented coverage and its limits

**Status.** Opt-in diagnostic implementation in the current tree. Ordinary
compiler output and diagnostics are unchanged. This is not acceptance evidence
and not a benchmark: the collector marks every report
`diagnosticOnly: true, acceptanceEvidence: false`.

## Why this exists

The earlier audit (`RESEARCH_PROFILING`, commit `8ddfd9d2`) showed that the
retained profiles were coarse phase profiles with no per-stage attribution
inside `check` and `emit`. This implementation adds a real stage report to the
typed-step selfhost path without touching canonical algorithms, semantic fuel,
`default chunk 64`, or the public 13-name ABI.

## Entry points

Candidate (real typed-step library, JS or C target):

```sh
bun evals/candidate_host.ts --candidate=COMPONENT.js [--parser=PARSER.js] \
  --stage-profile=DIR [--stage-progress] \
  [--stage-manifest=MANIFEST.json ...] [--stage-receipt=RECEIPT.json ...] \
  INPUT.bend -o OUT.mjs
```

Bootstrap worker (full-root selfhost lane), environment-only:

```sh
SELFHOST_STAGE_PROFILE_DIR=DIR \
SELFHOST_STAGE_PROGRESS=1 \
SELFHOST_STAGE_MANIFEST=checker.json:template.json:js-emit.json \
  bun evals/selfhost_bootstrap_worker.mjs REQUEST.json
```

Preserved native stderr trace (coarse native rows only; no build, no rerun):

```sh
bun evals/compiler_stage_report.mjs --native-log=TRACE.stderr.log \
  --stage-profile=DIR [--expect-sha256=HEX]
```

`--stage-manifest` is optional. Without it, fully qualified request tags are
retained but remain `unclassified`. With it, grouping requires:

1. the observed Run namespace to equal a registered manifest output namespace;
2. the exact fully qualified request constructor to be registered; and
3. the declared canonical source path (not just a basename) to map to a group;
4. for exact (unprefixed) group names, the compiled component artifact must be
   bound to a build receipt: the receipt's `artifactSha256` must equal the
   candidate hash, and the manifest's required generated engine output pin must
   equal the receipt's `loadedInputs` hash. Receipts may be result or provenance
   documents; `provenancePath` is followed.

Without a verified artifact binding, groups are still reported but every key is
prefixed `declared:` and the attribution/report records
`artifactBinding: {status: 'unverified'|'mismatch', reason, checks}` with a
`+artifact-binding-...` basis. A stale artifact plus a fresh manifest therefore
cannot be presented as an exact canonical stage.

An unmatched tag stays `unclassified` with a reason (`namespace-mismatch`,
`unregistered-namespace`, `unmapped-request`, `manifest-conflict`). A
source-hash mismatch yields `unverified-source`; a basename fallback is used
only when the manifest has one unambiguous source for that basename, and the
report records that weaker basis. Manifests must match the component's
generation; a stale manifest produces unclassified samples, never a fabricated
group.

## Evidence classes (never added together)

| Class | Collector kind | Scope / units | What it is |
|---|---|---|---|
| Explicit span | span | monotonic wall; process-wide CPU boundary delta; boundary memory snapshot | Real host boundary: import, parse/fuel, expand, check, emit, output write |
| Exact counter | `typed-step-exact-counters`, `phase-exact-counters` | `host-step-calls`, file/cell/byte counts | Host orchestration counts. One host step may advance up to 64 native steps; this is not semantic work |
| Sampled attribution | `typed-progress-samples` | `attributed-boundary-samples` at host-visible chunk boundaries | The typed progress constructor pending after each bounded host step; operational attribution, not a duration, call count, or CPU share |
| Native coarse row | `native-phase-coarse-span`, `native-fuel-exact`, `native-begin`, `native-result` | ms/bytes, `RUSAGE_SELF` process-wide | Rows already emitted by `native_compiler_host.c`; read from a preserved trace |
| Coverage metadata | `stage-group-metadata`, `stage-attribution-table`, `trace-coverage` | — | What is measured, how, and what is explicitly unavailable |

A boundary `heapUsed` delta is not allocation or retained bytes. RSS is
process-wide. Nested span CPU overlaps and is never made exclusive.

Finish semantics are fail-closed. A normal `completed` finish leaves any open
wrapper stage to the collector: the report keeps `workloadStatus: completed`
but records `measurementStatus: incomplete`, `incompleteEvidence: true`, and the
unclosed span names with `closeStatus: aborted`. A known failure explicitly
closes open stages as `failed`, yielding a failed workload with complete
measurement and failed span names. Wrapper spans are popped only after the
collector accepts the close; a rejected close does not hide the stage.

## Stage coverage actually implemented

| Group | Granularity |
|---|---|
| parse / import / fuel | Explicit span; exact module/parse/fuel-cell/source-byte counters |
| template expansion | Explicit span; exact host-step counter; sampled canonical request tags |
| signature / body check | Explicit span around one `check_modules` Run; exact host-step counter; sampled canonical request tags |
| check publication | Included in the ordinary check Run before its transient rewind; no separate host boundary. Canonical publication helpers appear only in sampled request attribution when reached. `inspect_checked_start` is a separate readback entry, not the publication itself. |
| catalog | Sampled attribution, canonical `lower_catalog` |
| backend lowering | Sampled attribution, canonical `backend_lower` |
| descriptor NF | Sampled attribution, canonical `descriptor_nf` |
| layouts | Sampled attribution, canonical `c_backend_layout`; zero samples on a JS-only tiny workload |
| sharing | Sampled attribution, canonical `c_backend_sharing`; zero samples on a JS-only tiny workload |
| JS rendering | Sampled attribution, canonical `js_emit` / `js_backend` |
| C rendering | Sampled attribution on the final 4a916 component: `emit-render-c`, plus C-only layouts, link planning and sharing; source emission, not clang execution |
| C link planning | Sampled attribution, canonical `c_backend_link`; source planning only, not the external linker |
| emitter entry | Sampled attribution, canonical `emitter` |
| link | **Unreachable in `candidate_host`**: it emits source only; linking belongs to `native_compiler_experiment` |
| native chunk attribution | Diagnostic typed view counts the operational progress shape and outer request group. The current canonical BIR/runtime/56-source transport is source-integrated for group 18, but the actual Node worker hit its 3072 MiB heap cap before any native phase; no native workload/profile result is claimed. |

## Verification in this tree

Final artifact `4a91665c…` from `/private/tmp/bend-fir-root-aa9`
(16,912,082 bytes; provenance receipt `root-final-rep.result.json`), tiny valid
input `evals/c_target_multiarm.bend`:

- profile off/on emitted byte-identical JS (`291363` bytes,
  `sha256 1effbc8d…`);
- profile off/on emitted byte-identical C (`842696` bytes,
  `sha256 3005e365…`); clang was not run because that fresh component C is
  known to fail clang, so this proves emission, not execution;
- six explicit spans completed on both targets; exact host-step counts and
  sampled groups used all three manifests with zero unclassified samples;
- JS emit samples: 2691 (`backend-lowering` 710, `catalog` 355,
  `descriptor-nf` 90, `render-js` 1536);
- C emit samples: 394317 (`backend-lowering` 710, `catalog` 355,
  `descriptor-nf` 6122, `layouts` 5601, `link-planning` 242016,
  `render-c` 139513);
- template 12589 and check 30610 grouped samples on both targets.

Compact evidence: `checkpoints/compiler-profile-ab-4a916.json`.

## Current native diagnostic status

Current canonical route (source-integrated, not a native pass): frozen
`evals/native_stage_profile_emit_source.bend` → production candidate artifact
`4a91665c…` → canonical checked program → generated lower group 5 (4627
chunks) → canonical BIR → generated transport with the real `c_runtime.c` and
all 56 declared `.c` sources → driver request group 18
`cps_provider_6_render` (826307 chunks in the JS proof, `EMIT_SUCCESS`).

The one actual Node 23.11/V8 guarded run (8 GiB/10 ms/600 s; worker 3072/256;
no Bun, no internal bypass) completed transport generation and then exhausted
the worker old-generation heap after 101,984 ms:
`ERR_WORKER_OUT_OF_MEMORY`. Peak RSS was 3,394,748,416 B (3.395 GB / 3.162 GiB),
below the 8 GiB guard. No native phase row, artifact, or profile was produced.
No cap was raised and the run was not retried. This is **NOT PASS** and does not
claim full compiler host/FP/C execution. Details:
`checkpoints/compiler-native-profile-aa9-canonical-final.json`.

The OOM boundary is not fully proven for this old run: it predates
instrumentation; the log contains only transport output then the worker error.
A separate prior consumer smoke completed `book/load/valid`
(`TRANSPORT_CONSUMER_OK`), making `compile_book` probable, but this is not
proven. Only guardian peak RSS/footprint exists; there is no heap/CPU/allocation
profile. Raw logs remain outside Git.

The builder now has opt-in `--profile-dir=DIR` instrumentation using the
existing `evals/compiler_profile.mjs`: `module-import`, `book_load`,
`book_valid`, `compile_book` spans plus source/input/runtime hashes and
execArgv before phase work. The parent binds the exact profile run directory
with a worker `profile-ready` message, not mtime scanning; worker error/exit
without a summary writes an interrupted `worker-failure.json` in that exact
run, while a known throw aborts open spans as failed and finishes failed.

A throwaway harness imports the shared `compilePhases()` and compiles the real
`evals/c_target_array_nat.bend` (all four spans completed; 81,153 C bytes;
numeric validation/codegen timings) and a malformed real fixture (`book_load`
failed). Its emitted C was compiled by clang and run, producing exactly `7`.
`compilePhases()` returns only the C string and timings, so the book/K/C
objects are not retained through clang/run. The generated-fixture SHA-256 is
recorded immediately after transport, before compilePhases; command identity is
`[execPath, ...execArgv, ...argv.slice(1)]`.

The profile-on path uses the existing
`createCompileBookObserver(profile).observe` adapter passed to
`C.compile_book(book,{observe})`; profile-off is exactly `C.compile_book(book)`.
A real valid driver produced actual `c-pass-1`/`c-pass-2` spans, compiler-state,
retention and memo observations, and byte-identical C in both modes
(81,153 B, SHA-256 `94a57dbd…`). The invalid driver closes `book_load` failed;
any `compilePhases` throw is unwound by `abortOpen('failed')`, including nested
observer spans; a throwaway adapter check closed `c-reachability` and
`c-pass-1` failed. No post-c-pass compile-failure fixture was exercised.

A guarded tiny changed-path suite repeats the shared compile path and
supervisor cases under the existing guardian: 8192 MiB memory/RSS, 10 ms
sampling, 600 s deadline, Node 23.11, compile worker heap 3072 MiB and stack
256 MiB. It compiled profile-on and profile-off C (byte-identical 81,153 B),
ran the C (stdout `7`), exercised `c-pass-1`/`c-pass-2` and 9 observations,
failed the invalid fixture, closed nested `c-reachability`/`c-pass-1` failed,
and covered throwing, exit-137 and exit-0-without-result workers. The guardian
reported PASS with `reportPhase=complete`, `ownedTreeStopped=true`, peak RSS
274,579,456 B/footprint 201,587,688 B, elapsed 6,844 ms. Compact receipt:
`checkpoints/compiler-profile-tiny-suite-aa9.json`; raw stdout/stderr hashes
are in it and remain outside Git.

Earlier unguarded tiny checks are **observed only**; they are not admission
evidence and are not retroactively certified against guardian limits. The
removed `--profile-smoke` CLI branch was a bare begin/end/handmade-error check
and is not changed-path proof. The old OOM boundary remains unknown.

Native raw stdout and stderr are now written to the artifact directory with
`wx` before any error/status check, and returned with paths/bytes/SHA-256 and
exit/signal, so EmitFailure or successful output is preserved without patching
output. No post-fix native run exists.

### Native emitter label defect

The diagnostic host previously printed Template's shape mapping for every
stage: `shapePending=shapes[1]`, `shapeDirect=shapes[2]`,
`shapeBound=shapes[3]`. Emitter codes are `0 Finished, 1 Direct, 2 Bound,
100+N Pending`, so that report mislabeled Direct as Pending and Bound as Direct.
The host now maps emitter fields to `finished=shapes[0]`,
`pending=sum(requestGroups)`, `direct=shapes[1]`, `bound=shapes[2]`; Template
and Checker mappings are unchanged. No native rerun was performed. Any old
native emitter rows retain the known label defect and are historical.

The fixture must include the full prelude because the small source imports Base;
canonical lowering carries its global declarations, constructor/family
metadata, foreign declarations and exact C source alternatives. Omitting it is
not a smaller valid fixture (the observed `no family declares constructor Nil`
is the historical example). Transport sizes: BIR 1,639,178 B; source bundle
279,742 B; runtime 75,336 B; serialized fixture 793,517 B.

### Historical/rejected evidence (not current claims)

- Bun/JSC diagnostic run: `REJECTED_WRONG_RUNTIME_BUN`; worker limits were not
  established. Its call-stack failure is not a Node-cap result.
- Copied `c_backend_smoke` BIR had no authoritative runtime families; it is now
  `evals/native_stage_profile_rejected_smoke.bend`, referenced only by the
  public failure probe. That probe prints the exact original
  `no family declares constructor Nil`, but is diagnostic-only.
- A hand-built family-per-constructor patch was rejected as non-authoritative
  metadata; it is not a valid fixture and is not in the canonical driver path.
- The earlier Node `EmitFailure` status-2 run and its message probe are
  historical diagnostics, not terminal native evidence.
- Direct group-12 CImport assembly was not proven; group 18 is the approved
  canonical C render entry. C remains `C_EMISSION_EQUIVALENT_NOT_EXECUTED`.

Native coarse rows were read from the preserved diagnostic trace
`/tmp/signature-publish57z/evidence/comparison/A1.stderr.log`
(`sha256 34c8f79e…`), reproducing parse / expand / check wall and
`RUSAGE_SELF` user/system values. That trace is preserved diagnostic evidence,
not a certification of current source.

## Limits

- The verification workload is tiny; it does not establish full-root overhead,
  complete stage coverage, or a speedup.
- Sampled attribution observes only the request pending at a chunk boundary and
  cannot be converted into CPU milliseconds or an exact per-function count.
- `Direct` progress erases its scheduling request, so it is reported as a
  progress shape, not attributed to a stage.
- Native fine substage spans require a coordinated private typed view and a
  proven native build; they remain future work and are listed as unavailable,
  not approximated.


## Intake bundle and native OOM boundary

Linear commits after `aa9a39a7`, dependency order:
`a4192c5c`, `415251a9`, `651f6360`, `2a8bd57b`, `ca8d6fa0`, `76111410`,
`7d6177de`, `68ea898a`, `1b2f85e2`, `08a89e66`, `5ed71315`, `25450687`,
`3e68db78`, `c01e65a3`, `a52c0399`, `6eccb27b`, `17a2701e`, `46124798`,
`83296cab`, `f6d3f8d7`.

Keep as integrated diagnostic/source fixes: the guard cutover, A/B and failure
receipts, Node runtime gate, canonical checked → lower → group18 render harness
and source, hardened transport/provenance, single-consumption typed outcome,
nonempty-success gate, and the final OOM receipt. The old copied smoke fixture
is retained only as `evals/native_stage_profile_rejected_smoke.bend` for the
public failure probe; the invented-family commit `1b2f85e2` and its fixture data
are historical/rejected and must not be treated as canonical. Generated
CheckedProgram/BIR/fixture/images remain outside Git.

The actual canonical Node 23.11 run completed transport generation, then the
3072 MiB worker old-generation heap was exhausted during the build before the
builder returned phase timing, wrote C, or produced an artifact. Existing raw
output has no book_valid/compile_book progress marker, so the exact internal
allocation boundary cannot be proven from that log. A separate prior
`book_load`/`book_valid` consumer smoke completed (`TRANSPORT_CONSUMER_OK`), so
`compile_book` is the probable boundary, not a proven one. Only guardian peak
RSS/footprint was captured (3,394,748,416 / 3,631,272,288 B); there is no heap,
CPU, or allocation profile. The 8 GiB guard was not reached; the 3072 MiB worker
old-generation cap is the terminal limit. No retry, cap raise, GC, Bun worker,
or internal bypass was used.

The fixture must include the full prelude because the small checked source
imports Base and its canonical lowering carries all global declarations,
constructor/family metadata, foreign declarations and the exact 56 C source
alternatives required by CJoin. Omitting it is not a smaller valid fixture: the
missing `Nil` family is the observed example. The transport sizes are BIR
1,639,178 B, source bundle 279,742 B, runtime 75,336 B and serialized fixture
793,517 B; the driver then loads that closure plus the generated Emitter
prelude before code generation. Raw logs remain under `/tmp` and are ignored,
not Git.
