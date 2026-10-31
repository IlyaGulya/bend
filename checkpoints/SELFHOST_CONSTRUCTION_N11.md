# N11: complete construction localizes the operational memory failure

**Executed, not an early prefix.** With the accepted-control Bun RAM hint,
R12 and G39 sources complete all four C fact passes, convergence, final C
translation-unit assembly and publication under the original guard. Without
the hint, both sources fail in pass 2, before final C assembly.

| Source | Hint | Result | Peak RSS, GiB | Peak footprint, GiB |
| --- | --- | --- | ---: | ---: |
| R12 | 4 GiB | complete C | 4.534 | 4.363 |
| G39 | 4 GiB | complete C | 4.394 | 4.003 |
| R12 | explicitly unset | footprint cap, pass 2 | 7.675 | 8.010 |
| G39 | explicitly unset | RSS cap, pass 2 | 8.012 | 7.948 |

Each cell performs complete original book validation: 12,456 definitions /
13,050 events, no exclusions or output patches. Guardian remains RSS **and**
physical footprint 8,192 MiB, 10-ms sampling, 600,000-ms deadline. No diagnostic
pass/event/120-second cutoff remains. All distinct cells execute once, serially;
failed cells are failures, never full-stage passes.

## Complete C construction

The successful cells each produce 589,974 observer events and settle in pass 4.
Both have identical ownership/hot/static fact-count progression; no new
semantic IR or production compiler change is involved. Observed final stages
cover graph filtering, metadata, tables, static image/spins, segments, runtime
assembly, identifier rewriting, cache reset and publication.

R12 output is **62,113,627 bytes**, SHA-256
`2290a096f114201665d4b943db3470889ca700ec205b875612178ea263e27ffb`:
**exactly the accepted original R12 C artifact**, not just a matching fixture.
G39 output is **62,125,028 bytes**, SHA-256
`9d696b111b5790eab0d8e7be98b5da694e87e2479467013cd1fcef8cc2011f8f`.
This G39 diagnostic C result does not retroactively accept the rejected source
version or prove native bootstrap/performance gates.

The final C assembly is measured separately from per-definition emission.
For the successful cells, segment text assembly takes about 188 ms and runtime
assembly about 14 ms. Identifier rewriting is separately recorded. These are
instrumented boundary durations, **not benchmark/throughput claims**. Full
boundary RSS/CPU/elapsed measurements and guardian peaks are in the ledger;
no live/retained-byte attribution is inferred.

## Failed cells and causal limit

- R12 unset: last streamed operation is pass-2 `prepare-before` for
  `emitter_steps_v1:emitter_match_1945`; original physical-footprint guard stops
  the tree after 39,320 ms.
- G39 unset: last streamed operation is pass-2 `prepare-before` for
  `emitter_steps_v1:emitter_match_1174`; original RSS guard stops the tree after
  28,235 ms.

A last progress marker identifies the latest entered operation, not a specific
engine allocation or a completed unrecorded stage. Neither failed cell reaches
final C rendering. Both successful cells use a 4-GiB **GC heuristic hint**, not
a hard quota; the original 8-GiB guardian is unchanged.

This reproduces operational hint dependence **in this pinned instrumented
protocol**, including failure of the otherwise accepted R12 source. Historical
G36–G39 child environments remain UNKNOWN; their cause is not reconstructed
from this new matrix. Observation can affect GC and temporary lifetimes.

## Launcher source audit

The canonical constructor currently inherits the caller's hint but never
supplies a default:

- `evals/native_compiler_experiment.ts:152–153,456–463`: codegen child inherits
  the process environment; ordinary Bun child does not inherit parent argv.
- `evals/heavy_gate.ts:202–210`: supervisor copies `process.env` plus lease vars.
- `evals/native_compiler_experiment.ts:419–423`: successful Bun child records the
  actual hint; Node profiling uses a different explicit heap/stack protocol.
- `bend2/selfhost/COMPILER_PROFILING.md:22–27`: the accepted-control hint is an
  operator-side environment prefix, not a launcher guarantee.

No stripping/propagation bug is claimed. The concrete operational gap is the
missing reproducible default. A conservative next fix is to use the accepted
hint for ordinary Bun construction when the caller supplies none, preserve
explicit overrides, and leave Node profiling policy unchanged. This checkpoint
is committed **before** applying that launcher change.

## Executed verification and source preservation

Before full construction, the measurement-only shadow compiler emits exactly
the same C bytes as the untouched compiler on the existing scalar-local-record
fixture; clang compiles it and the actual C consumer prints the expected five
values. Production `bend2/comp.ts` is untouched. Additional final-assembly
seams exist only in two isolated source copies; splitting the nested
`runtime_c`/`c_ids` expression changes observation/lifetimes, not output bytes.

The first post-run verifier incorrectly hashed six paths marked expected-absent
in the baseline receipt. Its source and EVIDENCE_INVALID result are preserved.
The corrected verifier checks actual absence and returns
**VERIFIED_DIAGNOSTIC_EVIDENCE**, zero errors. It preserves both resource
failures and warns that killed workers have no terminal log digest. All 21
baseline source checks, three generated hashes and two accepted artifact hashes
match. No new native executable or fixedpoint is claimed by N11.

Exact parent/child commands, source authorities, initial verifier failure,
corrected verification, phase measurements and results:
[`construction_n11_completed.json`](../evals/receipts/construction_n11_completed.json).
New required source/protocol snapshots are in `checkpoints/n11-source-inputs/`;
generated C, binaries and raw progress streams remain outside Git.

Accepted compiler remains **G24R12**; production compiler and launcher are
unchanged at this diagnostic checkpoint.
