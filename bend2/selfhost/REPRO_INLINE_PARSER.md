# Inline parser differential: quantity-annotated body locals and do binders

Status: **EMBEDDED_PARSER_CUTOVER_PUBLIC_PARITY_PASS**. The historical reduced
differential below is preserved. Current `db147cba` resolves all five cases;
this does not narrow or replace the compiler corpus or complete C matrix.

## Historical artifacts

- Inline image: `/private/tmp/bend-root57ab-go/checkpoints/root57ab-go-art.js`
  sha256 `9941352b639d1f31e381640f77e015e252d601b3815d9f36ea8614496bf50cb4`,
  17,846,510 bytes. Its own build receipt pins root source `b0b92b67` with
  11,814 admitted bodies and no parser-regeneration claim.
- External image: `/private/tmp/bend-fir-root-aa9/checkpoints/bootstrap-parser-rebuild-qp57a-4.js`
  sha256 `0e7b3c4295d5fc3e64cad4cb23eeb01c7c6051ae7df15893dd18622b226ca33b`,
  canonical source `7389188a68a205bfccdd6a3457ba0f11e689967751e31fa6d35eaec3b09e3e37`.
  It was authenticated by the already-completed 600s qp57a-4 gate; that gate
  was not rerun here.
- Driver: `evals/parser_inline_root_differential.ts` sha256
  `b34873a7b26001be07d1c309d6263022492324382e02d62097f90b703b9c2c64`.
- Sources: `evals/parser_quantity_binder_fixtures.ts` sha256
  `32cbbef722c11e2e6f2008b6c93947a39ddb3bcfd35d7199676b4a6f3bac1927`.
- Receipt: `evals/receipts/parser_inline_root_differential.json`.
- Raw report: `/private/tmp/bend-repro-parser57ab/checkpoints/parser-inline-root-differential.json`
  sha256 `300e903a7c848b80995d344cf43dc9b0dd8f86bd12038f0c9dcfb382d70e0225`.
- Run 1 (superseded control, preserved): `checkpoints/parser-inline-root-differential.run1-nonisolating.*`.

## Exact command

```
bun evals/heavy_gate.ts --memory-mib 8192 --rss-mib 8192 --poll-ms 10 --timeout-ms 600000 -- \
  bun evals/parser_inline_root_differential.ts \
  --inline=/private/tmp/bend-root57ab-go/checkpoints/root57ab-go-art.js \
  --external=/private/tmp/bend-fir-root-aa9/checkpoints/bootstrap-parser-rebuild-qp57a-4.js \
  --report=/private/tmp/bend-repro-parser57ab/checkpoints/parser-inline-root-differential.json \
  --receipt=/private/tmp/bend-repro-parser57ab/evals/receipts/parser_inline_root_differential.json
```

Both images are driven only through their exported public `parse_with_fuel`
(three arguments: fuel list, file, source) by the existing
`evals/bootstrap_parser_artifact_worker.mjs` Node worker. Fuel is 2,000,000
`FeedbackFuelCell` terms. Node v23.11.0, worker `--max-old-space-size=3072`,
top isolate `--stack-size=262144`, worker stack 256 MiB, no manual GC.
Terminal guardian record: PASS, reason command_exit, command exit 0,
reportPhase complete, ownedTreeStopped true, 870 ms, peak RSS 282,918,912 B,
peak footprint 222,219,632 B, limits 8,589,934,592 B memory/RSS, 600 s.

## [OBSERVED] parsed values

Each row is a real `ParseSuccess`/`ParseFailure` payload from the named image.
Spans use the same synthetic file name in both runs, so byte offsets are directly
comparable. `BodyLocal.quantity` and `TermLam.quantity` are the parsed AST fields.

| source | inline 9941352b | external 0e7b3c42 |
| --- | --- | --- |
| `def f(x: Nat) -> Nat:\n  +l : Nat = x\n  l\n` | ParseFailure; message `invalid or unsupported top-level syntax`, expected `a supported declaration`, observed `:`, span 27..28 | ParseSuccess; `BodyLocal` quantity `QMany`, span 24..41; `PatternVar l` `QMany` span 24..26; value `TermAnn` span 24..36 |
| `def f(x: Nat) -> Nat:\n  l : Nat = x\n  l\n` | ParseFailure; same message/expected/observed `:`, span 26..27 | ParseSuccess; `BodyLocal` quantity `QOne`, span 24..40; `PatternVar l` `QOne` span 24..25; value `TermAnn` span 24..35 |
| `def f(x: Nat) -> Nat:\n  do M<>: +y : Nat <- x; return y\n` | ParseFailure; same message/expected/observed `:`, span 35..36 | ParseSuccess; `TermLam` key `y`, quantity `Some(QMany)`, span 33..56 |
| `def f(x: Nat) -> Nat:\n  do M<>: y : Nat <- x; return y\n` | ParseSuccess; `TermLam` key `y`, quantity `None`, span 32..55; AST hash equal to external | ParseSuccess; `TermLam` key `y`, quantity `None`, span 32..55 |
| `def f(x: Nat) -> Nat:\n  l = x\n  do M<>: y <- x; return y\n` | ParseSuccess; `BodyLocal` `QOne` span 24..57, `PatternVar l` `QOne`, `TermLam` key `_` `None` span 32..57; AST hash equal to external | identical parsed AST: `BodyLocal` `QOne`, `TermLam` `_` `None` |

No `WorkerError` or `UnexpectedResult` occurred; the external image accepted
all five sources, so no oracle rejection invalidates the rows.

## [INFERENCE] minimal boundaries

- Body annotated local: the smallest distinguishing input is the plain typed
  local `l : Nat = x`. The inline image rejects it at the annotation colon;
  adding `+` changes neither the failure site nor the class (27..28 versus
  26..27, both `:`). The body-local observation therefore distinguishes typed
  locals, not quantities: `QMany` is not isolated for body locals.
- Do binder: the plain typed bind `y : Nat <- x` parses identically in both
  images with quantity `None`, so it is not a discriminator. Adding `+` is the
  sole change that flips the inline result to failure, while the external image
  records `Some(QMany)`. The `+` do binder/action is a genuine quantity-specific
  gap in the inline image.
- The fully unannotated control agrees exactly (same AST digest, `QOne`/`None`),
  so the three failures are not a general body/do parse breakdown.

Run 1 used a control that was itself typed; it failed in the inline image at
the local annotation colon. Its status is preserved as
`OBSERVED_TYPED_LOCAL_DIFFERENTIAL_QUANTITY_NOT_ISOLATED`, not as a semantic
"no difference": it observed a real typed-local differential while showing that
the `+` was not the discriminator for body locals.

## Current authenticated cutover: `db147cba`

Receipt: `evals/receipts/inline_parser_cutover_db147cba.json`.
Worktree: `/private/tmp/bend-parser-cutover667`, base `34c64741`.

The same canonical parser `7389188a` was honestly re-accepted in this tree:
all 71 preparation cases, all 75 compiled semantic cases, and both public
15-test/264-assertion gates passed. The new standalone image is byte-identical
to the prior accepted `0e7b3c42`; that is regeneration identity, not a
stage-one/stage-two fixedpoint.

Owned source and all three typed-step manifests were regenerated with parser
pin `7389188a`, quantum 64. The unchanged composer authenticated the tree-local
acceptance and inlined its exact declarations; no manual root edit, copied
absolute-path proof or validation shortcut was used.

New root: 653,895 B, sha256 `402011f5…`. New image:
`db147cba480109443fe8cfbd0efa2f1c167af7f6b9f7e2d623a0b1032c677dbe`,
18,039,083 B. Native admission checks all 11,889 expected/live bodies and
12,450 events, 0 exclusions/patches, all 13 exports unchanged. Guard:
61,954 ms, peak RSS 3,209,117,696 B / footprint 3,296,361,632 B,
complete/stopped/exit 0 under the same 8192/8192 MiB, 10 ms, 600 s limits.

The unchanged five-source public differential now observes ParseSuccess on
both sides and identical complete projected ASTs for every row: typed local,
`+` typed local, typed do, `+` typed do and untyped control. No ABI failures
or oracle rejections. Its guard completes/stops/exit 0 in 811 ms, RSS
279,642,112 B / footprint 219,843,520 B. Fuel stays 2,000,000, Node23.11.0,
old-generation cap3072 MiB, worker stack256 MiB.

This closes the inline-parser cutover, not current-image C/JS corpus,
compiler byte fixedpoint or native HOST acceptance. The C26 and foreign/library
passes on predecessor `667e7f33` remain version-scoped evidence.


## Does not establish

- Historical external-parser acceptance alone was not authority for the old
  root. The current root has its own full native admission and actual public
  parity evidence above.
- A successful parse is not C emission, execution or compiler fixedpoint.
- Canonical parser, kernel, compiler and generator source are unchanged by
  this cutover; the generated root is composed from the authenticated parser.
- These five sources remain diagnostic witnesses. Acceptance still requires
  every public export, the full agreed corpus and complete current C matrix.
