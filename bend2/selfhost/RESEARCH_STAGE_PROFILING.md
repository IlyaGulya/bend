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

`--stage-manifest` is optional. Without it, request tags are still exact but
remain `unclassified`. With it, grouping uses the generator manifest's exact
request constructors and `canonicalComposition` declaration names/source
modules. An unmatched tag stays `unclassified`; no suffix or source-text
guess is made. Manifests must match the component's generation; a stale
manifest produces unclassified samples, never a fabricated group.

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
| check publication | **Unreachable on this path**: neither host invokes `inspect_checked_start` |
| catalog / lowering | Sampled attribution, grouped from canonical `backend_lower` / `lower_catalog` modules |
| descriptor NF | Sampled attribution, canonical `descriptor_nf` |
| layouts | Sampled attribution, canonical `c_backend_layout`; zero samples on a JS-only tiny workload |
| sharing | Sampled attribution, canonical `c_backend_sharing`; zero samples on a JS-only tiny workload |
| JS rendering | Sampled attribution, canonical `js_emit` / `js_backend` |
| C rendering | Same mechanism; **not executed here**: the available C-capable component predates the unified `Emitter` Run protocol |
| C link planning | Sampled attribution, canonical `c_backend_link`; source planning only, not the external linker |
| emitter entry | Sampled attribution, canonical `emitter` |
| link | **Unreachable in `candidate_host`**: it emits source only; linking belongs to `native_compiler_experiment` |
| native fine substages | **Explicit prerequisite**: typed views hide progress and the generator is frozen; no fine native CPU is claimed |

## Verification in this tree

Real typed component `/private/tmp/croot-proof/root.js`
(`sha256 7d98ea60…`, built from source `c60df5a7…` with canonical compiler
`a84170d5…` and kernel `6c1df3eb…`), tiny valid input:

- profile off/on emitted byte-identical JS (`289409` bytes,
  `sha256 5db9119d…`);
- six explicit spans completed; exact step counts and sampled groups present;
  with matching manifests: template 12433 samples, check 30573,
  emit 2605 (`catalog-lowering` 995, `descriptor-nf` 91, `render-js` 1519),
  zero unclassified;
- invalid input kept the identical diagnostic and finalized the profile
  `failed` with a failed `check-signature-body` span;
- a parser rejection kept the identical diagnostic and closed the open
  `parse-import-fuel` span `failed` with `closeReason: candidate host terminated`.

Compact evidence: `checkpoints/compiler-stage-profile-v1.json`.
Raw profiles stay outside Git.

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
