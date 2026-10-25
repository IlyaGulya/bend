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
| native chunk attribution | Diagnostic typed view counts, per native phase, the operational progress shape code and, for Emitter, only the outer request-group variant. The current 27-group real-emit fixture is source-validated but its guarded code generation failed terminally with a compiler call-stack overflow; no native workload result is claimed. No source substage, per-function or exact CPU share is claimed. |

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

Bounded diagnostic native component
(`evals/native_stage_profile_build.ts`, driver/host in this tree): the builder
now calls the existing `guardHeavyGate(import.meta.url, …)` before creating its
3072 MiB/256 MiB worker, so a direct CLI run re-execs and authenticates the
supervisor lease; the old `--internal` bypass and manual `runHeavyGate` path are
gone. The guarded policy is 8 GiB RSS/memory, 10 ms sampling and 600 s, with
fixed 300 s clang and 120 s fixture-child deadlines.

The fixture matches all 27 current Emitter request groups and requests the real
canonical `c_backend.emit` group (group 12, label
`mixed:layouts+render-c`). Its program is the complete canonical smoke BIR from
`evals/c_backend_smoke.bend` (main/add/cap/zero codes, declarations,
constructors, U32 family; known result 26), factored as passive data in
`evals/native_stage_profile_rejected_smoke.bend` (explicit rejected diagnostic input); its runtime is the real
`evals/c_backend_runtime.bend` source. It does not import `c_backend.bend`'s
computed emit check, and it is not a scalar number-formatter or empty-program
fixture. The driver source passes `book_valid`; a JS generated-Emit probe over the same data/runtime returns `EMIT_SUCCESS` with the added runtime families.

The typed resume forwards the actual `EmitterValue<cps_provider_2_EmitResult>`
to completion, and the host calls the typed classifier: non-empty `EmitSuccess`
(1), empty `EmitSuccess` (0), `EmitFailure` (2); a non-1 status fails the phase.
This removes the prior failure-to-Unit drop.

A stopped Node 23.11 attempt is preserved but is not counted: it used the
placeholder fixture and was interrupted on instruction after 102 s, peak RSS
3,029,139,456 B, with `ownedTreeStopped: true` and no result. Its command ran
Node through `guardHeavyGate`, but it establishes neither workload success nor
a Node cap result.

**The prior native attempt was rejected as wrong runtime, not classified as a
Node-caps blocker.** The actual guarded attempt invoked
`/opt/homebrew/.../bun`; that was Bun/JSC, not the required Node/V8 worker. It
failed after 12.4 s with `RangeError: Maximum call stack size exceeded` in
`comp.ts`, at `peakRssBytes 5,091,704,832` (5.092 GB / 4.742 GiB), with
`ownedTreeStopped: true`; no artifact or native phase row was produced. Because
Bun declares but does not establish enforcement of `resourceLimits`, the
3072/256 limits were not established and this run is recorded as
`REJECTED_WRONG_RUNTIME_BUN`. No retroactive Node-cap claim is made and no
compiler/generator/source-output patch was applied. The old Bun raw logs are
preserved with runtime explicit in
`checkpoints/compiler-native-profile-aa9-failure.json`.

The builder now requires Node/V8 and fails fast under Bun/JSC before the guard.
Its required invocation is `node --experimental-strip-types
evals/native_stage_profile_build.ts --artifact-dir=DIR`; the whole build still
uses `guardHeavyGate` with the inherited lease, 8 GiB/10 ms/600 s policy and no
`--internal` bypass. The compliant Node 23.11/V8 run is complete and is the terminal native evidence:
codegen and native execution succeeded, the typed witness saw
`fixtureResultStatus 2` (`EmitFailure`) for the canonical smoke program/runtime
through Emitter group 12, and the host failed the phase instead of dropping it.
The run took 217.8 s, peak RSS 6,606,716,928 B (6.607 GB / 6.153 GiB), below
the 8 GiB guard, with four phase rows (template 2, checker 3, template-pending 2,
emitter 3 advances; group 12 observed once). This is a real canonical
`EmitFailure`, not an OOM/stack-cap failure and not a profiling PASS. The exact failure message is recovered on the public diagnostic surface
`evals/native_stage_profile_emit_probe.ts` (source
`evals/native_stage_profile_emit_probe.bend`): it prints
`no family declares constructor Nil` for the copied canonical smoke BIR data
and real runtime. Run it with
`node --stack-size=65536 --experimental-strip-types evals/native_stage_profile_emit_probe.ts`;
the 64 MiB stack is within the approved 256 MiB source cap and no native cap is
changed.

A hand-built family-per-constructor patch was attempted and then rejected:
its `DescriptorNull` fields, `None`-native constructor layouts and separate
families named after each constructor are not authoritative typed BIR metadata,
even though they made the renderer return success. That metadata has been
removed. The fixture is **BLOCKED ON AUTHORITATIVE BIR**: it needs a small real
checked source driven through canonical FIR/lowering to a BIR/Emitter request,
or another canonical generated fixture with complete semantically correct
runtime family/constructor metadata. The copied smoke data is retained only as
the failing public diagnostic input.

A canonical replacement path is now proven separately: a frozen real source
(`evals/native_stage_profile_emit_source.bend`, closed arithmetic/closure) is
checked by the production candidate artifact, lowered by generated
`EmitterRequest_cps_provider_1_lower` (group 5, 4627 chunks), and rendered by the
generated canonical C render request `cps_provider_6_render` (group 18, 826307
chunks) with the 56 real `.c` source alternatives, returning `EMIT_SUCCESS`.
CheckedProgram/BIR/source bundles are generated under `/tmp` and not committed;
only the source input and thin diagnostic components are source. The JS codegen
stack is 256 MiB, the approved source cap; no native worker/guard limit changed.
The diagnostic driver now consumes this canonical BIR, real runtime and 56-file
C source bundle through `EmitterRequestGroup_18` /
`EmitterRequest_cps_provider_6_render`. The native host passes the owned
result to one typed outcome callback and does not drop it again; the callback
carries EmitSuccess source or EmitFailure message/span, and the driver prints
`EMIT_SUCCESS` or `EMIT_FAILURE: <message>` and exits nonzero on failure. the builder's transport step writes the
generated fixture under `checkpoints/` (not Git) from `--canonical-bir`,
`--canonical-sources`, `--canonical-runtime`, and optional checked/component
provenance. The transport computes real hashes, includes nullary constructors,
rejects unknown constructors, non-canonical nominal tags, and extra/missing
fields, and validates source bundles as exactly `{path, source}`. A consumer
smoke passed (`TRANSPORT_CONSUMER_OK`). It does not use the copied
smoke fixture or a scalar request. This is not yet a native fixture run, and
direct group-12 CImport assembly is not claimed. The performed Node native run remains the pre-fix
`EmitFailure` evidence; no native rerun or cap change was made.

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
