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
  [--stage-manifest=MANIFEST.json ...] INPUT.bend -o OUT.mjs
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
3. the declared canonical source path (not just a basename) to map to a group.

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
| C rendering | Same mechanism; **not executed here**: the available C-capable component predates the unified `Emitter` Run protocol |
| C link planning | Sampled attribution, canonical `c_backend_link`; source planning only, not the external linker |
| emitter entry | Sampled attribution, canonical `emitter` |
| link | **Unreachable in `candidate_host`**: it emits source only; linking belongs to `native_compiler_experiment` |
| native chunk attribution | Diagnostic typed view counts, per native phase, the operational progress shape code (0 Finished, 1 Pending, 2 Direct, 3 Bound) after each bounded chunk; verified on a bounded native fixture over the real generated Template/Checker Run machines. No source substage and no exact CPU share is claimed. |

## Verification in this tree

Current unified typed component
`/private/tmp/bend-fir-integrated57ab/checkpoints/root-sharedem-art.js`
(`sha256 fcd8cca2…`, 16,789,267 bytes, built from root `b0b92b67…` with
canonical compiler `a84170d5…` and kernel `6c1df3eb…`), tiny valid input:

- profile off/on emitted byte-identical JS (`289409` bytes,
  `sha256 5db9119d…`);
- six explicit spans completed; exact step counts and sampled groups present;
  with the matching manifests: template 12433 samples, check 30573, emit 2616
  (`backend-lowering` 657, `catalog` 343, `descriptor-nf` 113, `render-js`
  1503), zero unclassified;
- the C entry ran through the same component and reached `catalog` 343,
  `backend-lowering` 629, `descriptor-nf` 6138, `layouts` 5529,
  `link-planning` 1238 and `render-c` 134813 samples before the component's
  `Base String.split` recursion overflow; the `emit` span and report finalize
  `failed`, and the stderr diagnostic is identical to the unprofiled run;
- invalid input kept the identical diagnostic and finalized the profile
  `failed` with a failed `check-signature-body` span;
- a parser rejection kept the identical diagnostic and closed the open
  `parse-import-fuel` span `failed` with `closeReason: candidate host terminated`.

Bounded diagnostic native component
(`evals/native_stage_profile_build.ts`, driver `08244caf…`, host `f77b0231…`,
kernel `6c1df3eb…`, compiler `a84170d5…`): three phases ran within the tool
deadline, with real generated Template/Checker Run machines and a finite seeded
Run. Observed chunk transitions: template 2 (`Finished` 1, `Bound` 1), checker
3 (`Finished` 3), template-pending 2 (`Finished` 1, `Pending` 1). Shape codes
0, 1 and 3 were therefore exercised natively; code 2 (`Direct`) is exercised by
real JS Run samples, not by this bounded fixture. This is operational chunk
attribution only: no source substage, compiler workload, acceptance or exclusive
CPU claim.

Compact evidence: `checkpoints/compiler-stage-profile-v1.json`.
Raw profiles stay outside Git.

### Native chunk attribution (diagnostic component)

`evals/native_stage_profile_driver.bend` is a separate profile-only native
driver with a diagnostic C host (`evals/native_stage_profile_host.c`). It is not
the production `native_experiment`: the 14 callback positions, 13 public names,
quantum 64 and ordinary hot path are untouched. The driver advances one chunk
per view call, reconstructs the affine Run state once (never inspecting request
payloads), and reports a numeric progress-shape code (0 Finished, 1 Pending,
2 Direct, 3 Bound) plus wall and `RUSAGE_SELF` CPU for the phase.

`node --experimental-strip-types --max-old-space-size=4096
evals/native_stage_profile_build.ts --artifact-dir=DIR --timeout-ms=180000`
builds only the diagnostic driver (real generated Template/Checker Run machines,
not the full compiler root) and runs a finite seeded Run under a tool deadline.
It is operational chunk attribution, not a source substage span and not a
compiler-workload CPU measurement.

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
