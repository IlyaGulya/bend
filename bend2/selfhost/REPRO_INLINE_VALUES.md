# Reduced C witnesses and continuation-scope diagnosis

Status: **BOOL_XOR_FIXED_IN_SOURCE_AND_SCOPED_RUNTIME; FULL_MATRIX_PENDING**.
Successor `667e7f33` fixes the Boolean defect; both reduced failures and the
complete truth table now pass real emit/clang/run. On predecessor `971e0986`,
all five original reduced inputs below pass, but its frozen C matrix remains
failed. These finite diagnostics do not replace the full corpus or matrix.

## First executable proof

Artifact: `/private/tmp/bend-verify-836/checkpoints/verify-836-art.js`, sha256
`971e0986800a7d331cf5f528bb71dfb4400e4b9177b90224ce33054da48e0422`,
17,918,636 B. Build receipt: `checkpoints/verify-836.receipt.json` (original
commit `457dcad4`). Authoritative providers are Control `22a73266`,
`c_backend 83680e53`, Physical `573244d7`, `c_backend_physical daf8a137`,
layout `a9f2d5d7`, descriptor NF `747dc747`. Whole-component validation checked
11,860 bodies from 12,421 events, 0 excluded checks and 0 output patches.
The generator, public 13 exports and quantum 64 are unchanged.

Under a literal Main runtime GO, exactly one
`evals/repro_inline57ab_iso_do_chain.bend` ran through the real host's
parse → expand → check → sharedEmitC → clang → executable path:

| stage | result | elapsed ms | peak RSS B | output |
| --- | --- | ---: | ---: | --- |
| emit | PASS | 19593 | 1748746240 | 1,122,032 B C, sha `7b167797…` |
| clang | PASS | 1429 | 134578176 | 0 errors, 54 unused-result warnings |
| run | PASS | 15 | 671744 | exactly `a\nb`, stderr empty |

Every stage has guardian `reportPhase complete`, `ownedTreeStopped true`,
command/effective exit 0. Executable sha256:
`05fe3684119402d3d3ab23132d1534c0dd990d3624df0ed08cc797744f49d76c`.
The stdout is 4 B, sha `911169dd…`, and agrees with the source's expected
`a` then `b`. No fail-closed physical guard was reached.

Primary receipt: `evals/receipts/repro_inline57ab_verify_daf8.json` (original
commit `64a894ef`, sha `1f169d76…`). Full stage streams, C and executable are
outside Git at
`/private/tmp/bend-repro-inline57ab/checkpoints/verify-daf8-v1/`.
This do-chain has no Bool/Char field, projection or array cell, so it does not
prove any of the three inline-value boundaries.

## Current bounded public results

`evals/receipts/repro_inline57ab_971_public.json` records the three original
Bool/Char/Fill sources and the isolated Bool-read control. All their emit,
clang and execution guards are complete/stopped/exit 0. Expected values in
the table below equal the observed stdout; Char/CID and borrowed-cell limits
remain exactly as stated below.

The same receipt separately records the corrected affine tail-capture
fixture: parenthesizing the local function type preserves the closure and
both match arms, and the real C executable prints the expected `11`, `12`.
The original parser-rejected `dbee4099` row stays unchanged in
`c_matrix_971e0986_25.json`; this targeted correction is not a new aggregate
matrix PASS. Its projected-Bool failure is preserved as historical evidence.

The `971e0986` failure was reduced to
`repro_inline57ab_bool_xor_literal.bend`: expected `False`, observed empty
stdout and `runtime fail-stop` after successful emission/clang. The projected
version fails identically. Receipt: `repro_bool_xor_971.json`. Source inspection
finds a C conditional-precedence defect in `bend_bool_xor`
(`c_backend.bend:3942`): the true-input arm returns 0/1 as the CID, not canonical
True/False CIDs.

Source correction `8aefa052` computes inequality of the two Boolean comparisons,
then selects canonical `t`/`f` exactly once. Only the C helper expression changes;
no runtime, generator, allocation or generated-output patch is added.
Fresh image `667e7f33` retains all 11,860 checked bodies and passes both reduced
programs with `False`, plus all four truth-table observations
(`False`, `True`, `True`, `False`). All nine smoke stages complete/stopped/exit 0.
Receipt: `evals/receipts/bool_xor_fix_667e7f33.json`. This is failing-before /
passing-after evidence; the full 26-input matrix remains pending.

## Reduced inputs and independent expected results

| input under `evals/` | source sha prefix | expected (= observed on `971e0986`) |
| --- | --- | --- |
| `repro_inline57ab_bool_projection.bend` | `c9a71566` | `1`, `True` |
| `repro_inline57ab_char_codepoint.bend` | `53f12eff` | `955`, `955` |
| `repro_inline57ab_bool_fill_tags.bend` | `e5c11935` | `False`, `True`, `True`, `False` |
| `repro_inline57ab_iso_do_chain.bend` | `83b82b37` | `a`, `b` |
| `repro_inline57ab_iso_bool_read.bend` | `9fdf0db1` | `True` |

The projected-Bool record has an extra U32 field to avoid the packed one-word
parent path. Only True is constructed, separating the read from the old
constant-Fill-tag defect. The Fill witness constructs both Bool arm orders;
constant tag 1 cannot produce its expected sequence. These are source-based
expectations, not values copied from a compiler run.

The Char witness involves a field and `Array.get`, but its scope is narrower:
`U32.add(953, 2)` is a constant pure expression, not proof of runtime-dependent
data. `PrimCharCode` emits `term_loc`, so raw 955 would also print 955;
non-ASCII stdout alone cannot prove the canonical Chr tag. Nor does
`Array.get` alone prove a borrowed `StCell` path rather than owned unfill.
Canonical CID/payload assertions belong to the authentic physical fixture in
`evals/physical_storage_acceptance_receipt_fixed6.json`: real FlagsS and
Array<Char> arguments, real constructor metadata, 46 generated expressions,
clang/run PASS. That scoped fixture is not public-source coverage.

## Historical failures that isolated the common blocker

On `9941352b` (`c_backend f17c157b`, physical `f4fdfcc9`), parser/checker
accepted all three corrected boundary inputs. All stopped at emission:

```
candidate: emission failed: BIR continuation reads a value that is not in scope
```

No clang or executable ran for them. The same error occurred on the corpus
control `evals/c_target_array_nat.bend` and on the do-chain, showing it was not
specific to inline-value syntax. The corpus control had emitted, compiled and
printed `7` on historical `5205478f`; that earlier result is not current-image
coverage. Receipts: `repro_inline57ab_attempt2_continuation.json`,
`repro_inline57ab_ladder.json`, and `repro_inline57ab_boundaries.json`.

One diagnostic-only emit on `65b01fd4` (Control `2dd339b2`, source `b0e1f691`)
identified the concrete prelude site:

```
BIR continuation of call to `entry 115 code `Word.inc`` (continuation 578) reads a value that is not in scope: ref capture slot 0 is not capturable from the caller frame; active slots -; continuation slots -; continuation locals 853,852; inherited L838 S0 L838 S0
```

The guard completed/stopped with exit 1, 7317 ms, RSS 1,041,825,792 B.
The build and emit were guarded but lacked a new Main slot authorization;
`65b01fd4` remains unapproved diagnostic raw evidence, never an acceptance
artifact. Rejected diagnostic sources and their generation errors are retained
in the child history, not integrated as working compiler checkpoints.

The observed slot was absent from the continuation's own references and
present only in inherited region obligations. Source inspection of Word.inc
and `backend_lower.bend` established that Region.next is the later-case
fallback, entered via LeaveRegion on a failed pattern. The successful recursive
arm constructs its result and returns; that fallback is not reachable from
its continuation. A proposal to keep every Region.refs value was withdrawn:
it could copy an affine heap closure on a successful/tail path. The integrated
`83680e53` instead follows reachable leaves for ownership and inherited
captures; actual references still fail loudly if missing. The do-chain PASS
above is finite evidence for this correction, not a general proof.

## Historical clang blocker and real runtime cutover

`a1c4a657` combined Control `83680e53` with older physical `f4fdfcc9`.
Its do-chain emitted 1,124,832 B of C, then clang failed with 700 undeclared
`bend_fail` errors; no executable ran. The physical unit's local helper had
masked the missing production-runtime dependency. This was a compilation
contract failure, not a value-level runtime failure.

Physical `573244d7` / `daf8a137` replaced all 16 void guard calls over 13 source
lines with the real runtime's `err_fail`. No new helper, zero fallback,
protected runtime edit or generated-C patch was introduced. The unit-only
`bend_fail` definition was removed. The authentic 46-expression suite then
compiled and ran against the real helper surface; other emitted helpers
`bend_bool`, `bend_hastag` and `bend_tuple` already resolve in the candidate.
The rebuilt `971e0986` is the executable proof above. The old artifact and raw
clang diagnostics are preserved and were not rerun to reconfirm the failure.

## Rejected input attempts

- Attempt 1: local Pair collided with Base.Pair; Char bindings were placed in
  a do block using unsupported statement syntax. Both sources were corrected;
  this run supports no backend conclusion.
- The ladder's first projected-Bool-only version (`55421bfd`) used an
  unannotated constructor local and failed checking with `term form cannot
  infer`. Corrected `9fdf0db1` passes the constructor directly and now executes
  successfully on `971e0986`. The original invalid input was never evidence
  for the common emitter failure.

Original streams and guardians remain outside Git, with immutable hashes in
`evals/receipts/repro_inline57ab_raw_manifest.json` and the attempt receipts.
`candidate_host --checked-out` captures CheckSuccess.program before lowering:
it is checked FIR, not BIR and cannot identify C continuations. The unused
heuristic scanner was removed rather than presented as a BIR inspection tool.

## Runtime and reproduction contract

The public host is `2596997a`, external parser `0e7b3c42`, Node v23.11.0.
Host argv uses `--experimental-strip-types --max-old-space-size=3072` and no
explicit stack-size flag. Every emit/clang/run stage uses the existing default
guardian: 8192 MiB footprint and RSS, 10 ms sampling, 600 s deadline.
The build's 256 MiB worker stack is not attributed to the host process.

The driver `evals/repro_inline57ab_run.ts` records the literal commands,
source/artifact/runtime hashes, raw streams and terminal guardians. Use fresh
logs and the named artifact; do not patch generated output, alter expectations,
reuse a rejected image as acceptance, or substitute these inputs for the full
matrix/corpus. The named finite public boundaries and corrected Boolean helper
now pass. Full-matrix, general ownership/ABI laws, frozen corpus and current
root byte fixedpoint acceptance remain open.
