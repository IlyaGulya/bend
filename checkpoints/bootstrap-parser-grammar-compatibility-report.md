# Bootstrap parser grammar compatibility — in progress

Compiled artifact EXISTS. Historical compiled whole29: 29/29 PASS. Historical compiled bootstrap corpus: 3/10 PASS — BLOCKED. Full Template census UNKNOWN. Checker extraction COMPLETE; native ownership independently BLOCKED and deferred. JSEmit runtime NOT REACHED. SELFHOST GREEN: NO.

## Current continuation

The user approved one ordering exception: complete bounded grammar gates under the unchanged 8 GiB cap, then perform one accepted-lifetime-path rebuild and require full compiled ten-module AST parity. Generated parser source, CoreSlice and JSEmit exceed the evaluator cap; this authorizes no parser memory or architecture changes.

Additional canonical repairs cover natural-prefix patterns, unsafe annotations, expression cons disambiguation, natural-expression adjacency, local tuple bindings, nested generic closing angles, empty-match elimination and right-associated pair type chains. Complete Lexer and Core normalized AST parity is now proven; the previous Lexer mismatch was partly a diagnostic binder-ID collision, corrected without semantic exclusions.

Pair-chain minimized fixtures fail before and match complete native AST hashes after the precedence repair (`bootstrap-pair-chain-before.json`, `bootstrap-pair-chain-after.json`, 2/2). Newline-before-cons now matches native ASTs while preserving newline-before-parenthesis boundaries (`bootstrap-newline-after-base.json`, focused 2/2); Base then exceeds the 8 GiB cap before a result. Correct consumed generic-token spans also restore rejection parity for the spaced nested-angle diagnostic.

Current scanner proof (`cursors-v2`): synthetic scanner callbacks are replaced with first-order token cursors. All 24 current rows (including the historical 20) are accounted for; 15 recursive calls retain AST-equivalent arguments; original quantities and external scanner ABI are preserved; no selected scanner call remains under a lambda. Native scanner/context/capture fixtures pass 33/33 tests / 165 assertions. The existing context normalizer still factors the one `parse_less_many_result` continuation; feedback-generator logic, canonical parser, kernel and production compiler remain unchanged.

The recomputed cut is historical 14 plus minimum four additions: `consumed_token_end_before`, `literal_pattern_fields`, `parse_pattern_tuple`, `pattern_scan`; six ties, zero residual non-singleton SCCs. The unchanged generator emits a 541,785-byte candidate / 1,026 definitions / 18 consistent Request variants. Structural audit: zero unresolved references, zero non-singleton SCCs, zero selected calls under lambdas. Generated candidate gates pass focused 23/23, whole29 29/29, bounded real-module normalized-AST parity 6/6 and public regressions 14/14 / 207 assertions. These evaluator gates use the documented compiled Lexer ABI; they are not compiled whole-parser proof. Diagnostic result transport now unwraps the typed `FeedbackComplete.value` envelope.

Historical `cursors-v2` native attempt: direct load passed 1,555 declaration events, then unchanged native validation stopped at index 880 (`step_parse_type_decl`), generated line 2904, with `expected: an annotated term (cannot infer)` on the new `Lexer.TokenInfo` Local initializer. Peak footprint 2,293,319,864 bytes; RSS 2,332,196,864 bytes; no resource limit reached and no artifact emitted. Exact historical evidence remains in `bootstrap-parser-rebuild-c90c06a262b3af6d-cursors-v2.result.json` and its build journal/guardian.

Current authorized annotation repair (`annotation-v1`): verified `Lexer.TokenInfo` belongs to `Lexer.Token`. A native fixture reproduces the unannotated Local failure; the identical initializer annotated as `Lexer.Token` fully validates and executes with identical fields to the direct-constructor reference. Canonical line 4089 now supplies only that annotation. Bounded audit of all three new/modified Local initializers since the frozen checkpoint found one other omission: line 1981, `pattern_cons_result`'s `combined`, now annotated as `Ast.SyntaxPattern`; native RHS/inference/resource-demand proof passes with unchanged quantities and bodies. Existing `parse_less_many_result.fill` was already annotated and remains unchanged. Evidence: `parser-token-annotation-smoke.json`, `parser-canonical-annotation-hygiene.json`.

Canonical SHA `a16bd71391493c8363ed99e88852f331d265fbe3589508c1332a01c548153075`; mechanically generated candidate SHA `f98ba83239aec0a5fec2d3f2ee0e0917127b277b629357fe68fdf078144c36e4`, 541,827 bytes. Structural invariants remain zero unresolved references, zero mutual SCCs, zero selected lambda calls, zero source-specific transformer exceptions and zero output patches; cut remains historical 14 plus the same minimum four. Exact edge delta is only the context helper's source-offset suffix rename `234329` → `234353`, with identical incoming/outgoing edges. Fresh direct-load target check of `step_parse_type_decl` passes at index 880, retained native e, `done=880`; the prefix was trusted, not validated.

Complete native validation then passed all 1,555 declaration events / 1,365 checked definitions, zero exclusions. Artifact `bootstrap-parser-rebuild-annotation-v1.js`: 33,688,479 bytes, SHA `e419a3387202dbd8e54ddfffbe79211b445aab03dee449687f7534f5a6372095`. Validation peak footprint/RSS: 3,836,071,200 / 3,748,610,048 bytes; codegen: 7,185,995,632 / 7,042,449,408 bytes. The accepted per-definition prepare/emit/release path completed under the exclusive 8 GiB guard. No canonical source change or cleanup followed full validation.

Actual NEW compiled artifact: tiny6 acceptance/semantic parity 6/6; whole29 29/29. Decisive real corpus is NOT GREEN: three modules have proven acceptance/AST parity out of ten required; only six real rows were persisted before transport failed. First disagreement is the frozen parser module at byte 73673, line 1099: `ParseFailure`, `invalid or unsupported top-level syntax`, expected `a supported declaration`, observed newline. Minimized to `def f(x: Nat, y: Nat) -> Nat: x * 1n + y` (body on its own indented line): stage0 accepts, compiled parser rejects, observed `y`, span 41–42. Controls `x * 1n`, `x + 1n * y`, and `(x * 1n) + y` parse successfully; `x + 1n + y` also fails. This is an arithmetic-chain acceptance disagreement, NOT a missing annotation. Stop without grammar/compiler/generator changes. Minimized probe peak footprint/RSS: 350,084,352 / 412,008,448 bytes.

Other corpus observations, not substitutes for the first blocker: Base raised `bend: a Nat past the largest immediate 2^48-1`; CheckerCore slice returned ParseFailure; JSEmit JSON decoding hit `RangeError: Maximum call stack size exceeded` in the host reviver. The corpus command ultimately timed out at 1,800 seconds. Import closure, Template census and CheckerCore/JSEmit target integration remain blocked behind compiled 10/10. Evidence: `bootstrap-parser-rebuild-annotation-v1.result.json`, `.metrics.json`, `bootstrap-annotation-v1-compiled-parity.json`, `parser-compiled-first-mismatch.json`, `parser-compiled-first-mismatch-v2.json`. SELFHOST GREEN: NO.

Current operator-chain investigation (`operator-v1`) establishes Case A, superseding the previously unestablished origin: stage0 accepts every matrix source; canonical, factored, generated and frozen compiled parsers have the same six chain failures and five complete AST-parity passes. The first loss occurs in canonical `parse_operator_precedence`: at binding level 12, `parse_term_tail` sees `+ y`, but the helper receives only `y` after the operator has been consumed. Its priority-10 stop branch returns that cursor, losing `+`. Equal-precedence left-associative chains fail for the same reason. Evidence: `operator-canonical.json`, `operator-factored.json`, `operator-generated.json`, `operator-compiled.json`, and `operator-cursor-before.json`.

The minimal general repair retains `all_tokens` alongside the RHS cursor in generic `parse_operator`/`parse_operator_precedence`; when an operator is below the current binding threshold, return the original operator-containing cursor. Every affected arithmetic/Boolean/bitwise caller forwards its existing original cursor. Prior type annotations and quantities remain unchanged. Permanent `parser_operator_chain.test.ts` is red-before (5 pass / 6 fail), then green (11/11 full stage0 AST comparisons) in canonical, factored and generated evaluators. Focused23, whole29, public14 and bounded real evaluator6 all pass. Canonical SHA `2a920ef1f95ffcd9c824265491cefcde78a552018daee3039d29136813932bb8`; generated SHA `0bc3d4054c08ffcea2a90cb9177d9c918258b4eef0de1227e89ceecc3266ac93`. Structural invariants remain zero unresolved references, mutual SCCs, selected lambda calls and exceptions; cut stays historical 14 plus the same minimum four. One guarded native rebuild is in progress; its first compiled gate will be the operator matrix.

Real-source harness now runs one fresh guarded process per module, sequentially, with a configurable 120-second default deadline. Flat iterative AST graph transport replaces the recursive JSON reviver; semantic hashes stream every normalized field in exact JSON order. Existing diagnostic serializers are iterative; protected native normalization bridges remain unchanged and failures are classified rather than omitted. Transport depth/hash smoke and independent module smoke remain to be exercised after the exclusive build. No full ten-module success is claimed. SELFHOST GREEN: NO.

Rebuild terminal outcome: TIMEOUT at the 3,600-second command deadline, still in native validation. Last recorded declaration-begin index 1374 of 1555 events, `feedback_make_parse_terms_until_colon_result`, elapsed 3,582,809.916416 ms. This is not a validation PASS, type diagnostic or observed resource-limit failure. No new artifact or compiled operator/corpus proof was produced. The preceding 51-minute build is historical timing, not a prediction for this candidate. No automatic second full build is launched. Evidence: `operator-v1-build-timeout.json`, `bootstrap-parser-rebuild-operator-v1.build.jsonl`, `.progress.json`.

Independent harness verification after timeout: transport/hash smoke PASS, five exact-JSON hash cases and depth-40,000 constructor round-trip preserving all fields; peak RSS 180,633,600 bytes. A frozen-artifact module-1 harness smoke deliberately bounded to 30 seconds terminated with `timeout`, `finished=true`, `complete=false`, `parseCompleted=false`, and no parity success counted; guarded command exit 124, peak RSS 483,704,832 bytes. This verifies bounded failure handling, not module acceptance or the rebuilt parser. Evidence: `bootstrap-ast-transport-smoke.json`, `operator-isolated-harness-smoke.json` and its per-module result.

Validation timing follow-up: diagnostic build orchestration now uses `evals/validation_profile.ts`: explicit GC every 32 declarations, or before a declaration when footprint/RSS reaches 6 GiB; the external 8 GiB/10 ms guardian, native checker, retained-e contract and codegen release/GC policy remain unchanged. Incremental events separate declaration elapsed/body/CPU time and GC elapsed/CPU time; completed builds also write `.validation-timings.json`. Real-prefix smoke 128/128 PASS with retained checked bodies, four GC calls, 3.371 s validation, peak RSS 326,483,968 bytes. A larger requested prefix timed out at 300 seconds: 647 declarations completed, 193.999 s declaration time plus 74.936 s explicit GC, but only 11.048 s combined CPU. This is not whole validation or a demonstrated full-build speedup.

Runtime-independent control confirms current host CPU availability is a separate bottleneck: a 1 MiB C integer loop used 0.503 s CPU / 13.469 s wall with the guardian, and 0.513 s CPU / 15.078 s wall without it; major faults zero in both. Host reports 10 CPUs and load averages 115.27 / 163.89 / 194.06. A fresh trusted-window Bend diagnostic likewise used 2.344 s CPU / 25.614 s wall, with 17,384 involuntary context switches and zero major faults. This supports scheduling contention on the current host, not disk-swap causality or a measured attribution of the older hour-long run. No unrelated processes were stopped.

Historical accepted annotation-v1 codegen attribution: 2,083.116 s total, 2,040.901 s (97.97%) between release and release-GC completion across 1,120 definitions; emission intervals total 7.463 s, final assembly 57.957 ms. Preparation intervals may nest and must not be summed as exclusive categories. Evidence: `codegen-time-attribution-annotation-v1.json`, `validation-profile-batched32-smoke.json`, `validation-profile-batched32.json.jsonl`, `validation-runtime-waits.json`, and `validation-runtime-stack.txt`. Next clean measurement requires an adequately available CPU host; do not infer compiler complexity from current wall time. SELFHOST GREEN: NO.

Available-host retry (`operator-batched32`): CPU control recovered to 0.417840 s wall / 0.414621 s CPU. Full native validation now PASS 1555/1555 with retained e: 21.173 s, 16.333 s explicit GC, 4.529 s observed body checks. A separate artifact-producing run again passed all 1555 declarations (20.416 s), then used the byte-pinned accepted diagnostic compiler with unchanged prepare/emit/release semantics and batched codegen GC. New artifact `checkpoints/bootstrap-parser-operator-batched32.js`, 33,689,968 bytes, SHA-256 `70c0d412e7ff51e3151de8039aebcd41b9e4369bc7b843d7e1c4c40db9b3f8f0`. Codegen 445.434 s, GC 431.650 s (96.9%); guardian PASS with peak footprint 7,359,403,816 / RSS 7,311,851,520 bytes. Of 625 GC calls, 610 occurred above the 6 GiB pressure threshold; 613 reduced footprint by less than 1 MiB. The pressure rule repeatedly collects without bringing footprint below threshold; this remains diagnostic orchestration overhead, not demonstrated emitter computation.

Actual new compiled parser: operator matrix 11/11 complete normalized AST parity; tiny6 6/6 and whole29 29/29 acceptance/semantic parity. Isolated frozen real corpus: attempted/finished 10/10, parse-completed 9/10, full-file ParseSuccess and complete normalized AST parity 8/10; no timeouts. CheckerCore slice and JSEmit source now pass. Remaining module 2 rejection is before `encode_float_normal_rounding_limit`, span 73544–73578; module 3 Base separately fails at runtime with `bend: a Nat past the largest immediate 2^48-1`. Do not classify Base as grammar rejection or count it as a completed parse.

Remaining parser rejection minimized to `def f(x: Nat, y: Nat) -> Nat & Bool:` with body `bits = x + y` followed by `(bits, True{})` on the next indented line. Stage0 accepts; canonical, factored, generated evaluators and the new compiled artifact reject. Controls: direct tuple body and `bits = x` followed by the tuple both parse. A second declaration is unnecessary. First divergence is canonical parsing of an operator-valued local binding before a parenthesized continuation; exact token/line-boundary cause is not yet established. No source repair follows this new blocker in this retry. Evidence: `operator-batched32-performance.json`, `operator-batched32-build.json.artifact.json`, `operator-batched32-compiled-matrix.json`, `operator-batched32-real-corpus.json`, `operator-batched32-first-real-boundary.json`, `operator-batched32-boundary-layers.json`. Full 10/10 remains unmet; import closure, Template census and downstream Checker/JSEmit target execution remain gated. SELFHOST GREEN: NO.

Selected diagnostic codegen GC policy: shared `codegenGCProfile` in `evals/validation_profile.ts`, used by both `bootstrap_parser_rebuild.ts` and `validation_profile_smoke.ts`. Collect after 32 releases since the last GC; above 6 GiB collect only after another 256 MiB footprint/RSS growth relative to the last post-GC observation and at least four releases; emergency GC at 7.5 GiB. External 8 GiB/10 ms guardian and accepted compiler prepare/emit/release semantics are unchanged. Validation GC policy remains unchanged.

Controlled unchanged-candidate experiment: codegen fell from 445.434 s / 625 GC calls to 30.243 s / 35 calls (34 batch, one growth), GC time 431.650 -> 18.943 s; guarded build 50.353 s. After moving the same policy into the shared helper, actual full-validation/emission smoke again passed: validation 1555/1555 in 15.133 s, codegen 28.098 s / 35 GC calls / 17.272 s GC, total guarded build 43.728 s. Guardian peak footprint 7,244,584,840 and RSS 7,649,476,608 bytes, below both 8 GiB limits. Emergency branch was not exercised. `cmp` succeeds against the previous artifact; all three artifacts have SHA-256 `70c0d412e7ff51e3151de8039aebcd41b9e4369bc7b843d7e1c4c40db9b3f8f0`. Compiled operator matrix 11/11, tiny6 6/6, whole29 29/29 parity passed. Evidence: `operator-growth-gc-comparison.json`, `operator-growth-gc-shared-build.json.artifact.json` and referenced guardian/regression reports. Public regeneration entrypoint was not rerun; shared policy was exercised end-to-end through the full profile harness. Existing real-source 8/10 blockers remain unchanged; no new parser semantics or automatic fuel policy. SELFHOST GREEN: NO.

Continuation repair (`continuation-v1`): `parse_term_tail_after_line` now preserves the original token cursor, including the newline, when RHS precedence stops at `(` or `[`. The enclosing local-body parser therefore sees the statement boundary instead of treating the parenthesized next statement as RHS application. Canonical, factored and generated layers passed 19 continuation/operator AST regressions each; public14, focused23, whole29 and bounded real6 gates passed. Full native validation passed 1555/1555. Compiled artifact `bootstrap-parser-rebuild-continuation-v1.js`, SHA-256 `be842e9da5df970e608cd6f3d6171d9f01cbab32d3da63b282934be2d7432483`, 33,689,874 bytes, passed all 19 compiled regressions and tiny6/whole29 parity. Build time 52.290 s; sampled codegen footprint 7,449,646,984 / RSS 7,546,699,776 bytes. Kernel and production compiler hashes remain unchanged.

Current ten-module result supersedes the historical 8/10 result: all ten attempted and finished; seven complete normalized AST parity results; eight full-file parser successes. Generated parser implementation source now terminates with `RangeError: Maximum call stack size exceeded` before parse completion. Base terminates with the known Nat immediate overflow. JSEmit parses successfully but its corpus worker then hits the RSS guardian: 8,594,587,648 sampled bytes against the 8,589,934,592-byte limit; no semantic parity result is counted for that module. No timeouts. These are runtime/resource blockers, not a repeated continuation grammar rejection. Evidence: `continuation-v1-real-corpus.json`, `continuation-v1-integration-result.json`, and per-module guardian reports.

Base overflow is independently minimized to `def f() -> F32:` with body `3.14159265`, the literal in `base.bend`'s `F32.pi`. Stage0 accepts all four controls; compiled parser succeeds for `0.5`, `3.14`, `3.1415926` and throws `bend: a Nat past the largest immediate 2^48-1` for `3.14159265`. `round_float_scaled` at `parser.bend:604-606` constructs `314159265 * 2^22 = 1317679461826560`, beyond maximum immediate Nat `281474976710655`. A future repair must use generic bounded numeric conversion with the frozen compiler, not special-case pi, suppress the exception, or alter grammar. Probe source and arithmetic evidence retained in `continuation-v1-base-float-min.json`. No float-conversion repair or stack/resource workaround was applied in this continuation. SELFHOST GREEN: NO.

### Bounded F32 and isolated runtime/transport iteration

`round_float_scaled` now starts with `Nat.divmod`, emits quotient bits with a structurally decreasing shift counter, and keeps `remainder < denominator`. Crossing and final ties-to-even comparisons use `remainder` versus `denominator - remainder`; doubled remainder is formed only when below the denominator. Positive exponent lookahead divides the numerator by 2/4 instead of multiplying the denominator; negative exponent crossing is recognized before doubling. F32 callers bound the scaled quotient below 2^24 before rounding. Scaled-denominator powers remain bounded by the correct exponent invariant. Raw decimal mantissa/power representation remains limited to 48-bit Nat; long significant literals and nonzero subnormal ratios are not claimed supported.

Numerical proof: exact canonical Bend numeric helpers were fully native-validated and compiled into an isolated small library, with 40 stage0 F32 bit-pattern comparisons and 11 independent scaled ties-to-even/arbitrary-denominator checks passing (`f32-bounded-v1-native-float.json`). This gate executes Bend arithmetic, not a host replacement, but does not claim public-parser/scanner parity. Direct source-evaluator pi hit the 8 GiB guardian before a result; Base's interpreted Nat.divmod is unary. Canonical/factored/generated operator19, public14, focused23, whole29 and bounded real6 gates passed. Generated source has zero unresolved references, zero mutual SCCs, zero selected calls under lambda and zero source-specific evaluation-context exceptions.

One full parser rebuild: `bootstrap-parser-rebuild-f32-bounded-v1.js`, SHA-256 `5c71f62b18a4b75036205c533d28ceb91c696bf3fe2487a10138860678974ece`, 33,692,056 bytes. Full native validation 1559/1559; worker build 75.706 s, guardian 76.035 s; guardian peaks footprint 7,418,369,880 / RSS 7,574,634,496 bytes. Growth-aware codegen GC policy retained: 35 collections, no per-definition forced GC. New artifact passes compiled operator/continuation19 and tiny6/whole29 parity; permanent native numeric regressions37 also pass.

First compiled pi regression returns ParseSuccess and its numeric payload is exactly `0x40490fdb`, but public AST parity fails: `parse_number_float_result` at `parser.bend:1069` constructs `F32(U32(Word32))`, while stage0 and Base's F32 datatype require `F32(Word32)`. No observer normalization hides that wrapper (`f32-bounded-v1-compiled-ast-boundary.json`). Full Base no longer raises Nat overflow, but rejects at frozen-source line2272, observed `ANode`, after `l r = Array.map(...) Array.map(...)` (`f32-bounded-v1-base.json`). No full Base AST parity or general float compatibility is claimed; no second rebuild or nonnumeric grammar repair was applied.

Generated-source stack diagnosis is inside `compiled-parse-call`, before parse completion, serialization, normalization or host transport. Captured frames repeatedly name `$nat_pattern$` at frozen continuation artifact236898/236903. Canonical `nat_pattern` expands one recursive call and Succ node per numeric predecessor: O(N) depth/output in literal value N. Prefix157 declarations / 74,314 chars accepts; adding only `encode_float_subnormal_limit`, prefix158 / 74,507 chars, fails. Its expression tuple `(8388608n, True{})` enters speculative natural-pattern construction. This is not token-combination recursion. Evidence: `generated-stack-diagnosis.json`, `generated-stack-prefix157.json`, `generated-stack-prefix158.json`. No Request/Kont or parser rewrite was made.

JSEmit's first dominant host memory increase was transport decoding: parent RSS 595 MB -> 4,637 MB; native-to-Value materialization then reached 6,106 MB. Normalization reached 6,970 MB; the initial diagnostic stopped at physical footprint 8,598,971,008 bytes during actual-semantic-hash. Decoder now validates the parsed envelope in place, avoiding a second record/slot graph, releases consumed records, and retains iterative identity/cycle resolution. The corpus uses two host-only reclamation boundaries after decoding and native materialization; no per-definition GC or semantic field omission. Transport depth40,000/sharing/cycles/sparse-array/scalar/error smoke passes. Targeted JSEmit complete ParseSuccess and normalized AST parity now PASS under 8 GiB: guardian footprint 5,272,902,976 / RSS 5,466,570,752 bytes, 12.703 s (`f32-bounded-v1-module7-memory-repair.json`).

Phase sidecars are persisted next to per-module result/worker JSON. Compare `timestampMs` across processes; worker and parent elapsed/heap counters have separate origins. Error reports retain `failureStage` and the first 32 stack frames. Final full-corpus counts are recorded separately after the targeted host repair. SELFHOST GREEN: NO.

Final full ten-module run (`f32-bounded-v1-real-corpus.json`): all10 attempted/finished,9 completed parses,8 full ParseSuccess,8 acceptance parity and8 complete normalized AST parity. JSEmit is now a full parity pass. Remaining real-module failures are generated-source compiled `nat_pattern` recursion and Base's `Array.map` parse rejection; zero resource-limit terminations, timeouts or fuel exhaustion in this final run. The separately exercised pi AST-shape defect still prevents a full float-compatibility claim. Consolidated six-part report: `f32-bounded-v1-integration-result.json`. Frozen continuation artifact, production `bend.ts` and `comp.ts` hashes are unchanged. Stage1 closure and CheckerCore/JSEmit integration were not advanced because the required10/10 prerequisite is unmet. SELFHOST GREEN: NO.

The stage0-only input-limit probe also exercised14 excluded classes (`f32-bounded-v1-input-limits.json`):8 unsupported notations, including `-3.14159265`, `-0.5`, and `-0.0`, were rejected;6 long-mantissa/large-power/subnormal literals were accepted and their reference F32 words observed, but compiled comparison is not claimed for these out-of-model inputs. The temporary probe was removed; its source is preserved in the evidence JSON.

The sections below retain the earlier fifth-family checkpoint rather than claiming current completion.

## Current residual feedback-cut result — STOP before implementation

**CURRENT MINIMAL CUT REQUIRES 4 NEW VERTICES.** Historical 14 seeds remain fixed and `parser_full_cut.json` remains byte-identical (`dafe1bdbc61510d2bed36b85d782dfaaf4c1975a7aa32b52ebf3e0ee5afdfd0f`). No cut expansion has been applied and no new compiled artifact has been built.

`evals/bootstrap_parser_current_cut.ts` solves the exact directed cycle-hitting problem, ignores permitted singleton self recursion, restricts selectable vertices to original canonical source functions, and exhausts all equal-cardinality minima. Both freshly parsed native canonical and factored Body-AST graphs produce the same six minimum solutions in 109 search states. Lexicographic function-name-vector tie-break proposes:

```
historical seeds + {
  consumed_token_end_before,
  literal_pattern_fields,
  parse_pattern_tuple,
  pattern_scan
}
```

There are three residual SCCs. The generic consumed-token-end component needs one of `{consumed_token_end_before, consumed_token_end_step}`. Literal conversion uniquely needs `literal_pattern_fields` at cardinality one. The pattern-scanner/tuple component needs `pattern_scan` plus one of `{parse_pattern_tuple, pattern_tuple_delimiter, pattern_tuple_head_result}`. Independent-component lower bounds sum to `1 + 1 + 2 = 4`; every reported minimum removes all non-singleton SCCs. Selecting only `pattern_scan` leaves the other two SCCs and the independent tuple cycle.

Direct native source-AST cycle witnesses:

```
consumed_token_end_before <-> consumed_token_end_step
literal_pattern <-> literal_pattern_fields <-> literal_pattern_field
pattern_scan <-> pattern_finish
pattern_scan <-> parse_pattern_atom
parse_pattern_tuple -> pattern_tuple_head_result
  -> pattern_tuple_delimiter -> parse_pattern_tuple
```

The complete residual vertex/edge lists, candidates, all six minima, component minima and remaining SCCs after the single-vertex hypothesis are preserved in:

- `bootstrap-parser-current-cut-c90c06a262b3af6d-canonical-source-vertices.json`
- `bootstrap-parser-current-cut-c90c06a262b3af6d-factored-source-vertices.json`

These are versioned **PROPOSED_NOT_APPLIED** overlays, not historical rewrites. Canonical SHA: `c90c06a262b3af6d411211f564771fd248e2b639d7ece1ebe7392bb5338c5457`. Factored SHA: `0a30e28c270e4772e6c74efcdd91646359ae79af5866084d6e58599fccf14b48`. The original factored generation graph SHA is `75d5defdb77425e401231ced0edfa0915eced9cd738a5f3f0dd67c8eee5188cc`; fresh native graph dumps and their hashes are recorded in the overlays.

Additional pre-generation blocker: canonical graph has zero unresolved references; accepted factoring of the repaired grammar leaves six unresolved references: `rest` in `pattern_scan_row_{0,1,2,9,14}` and `left` in `pattern_scan_completed_fields`. Fresh native graph extraction reproduces these facts and exactly matches the saved factored dependency edges. No unresolved reference was suppressed. This is a factoring capture-coverage issue; it is not evidence of a grammar mismatch or a Request/Kont lowering escape.

Per the user's stop condition, the four-vertex minimum crossing pattern parsing and generic type-span parsing is reported before applying the overlay or rerunning generation. Generated-candidate semantic gates, structural Request/Kont deltas, expensive rebuild, compiled ten-module proof, parsed closure and Template census are not reached. Production `bend.ts`, `comp.ts`, canonical pattern scanner, CheckerCore, Checker/Template SCCs and JSEmit semantics were not changed in this cut-analysis step.


## Frozen acceptance corpus and baseline

`bootstrap-real-source-corpus.json` records ten immutable byte snapshots under `bootstrap-real-source/`. Unchanged stage0 syntax oracle accepts all ten. The historical compiled parser accepts the driver, LoadedModule and Ast; their complete normalized module AST hashes match stage0 (3/3). See `bootstrap-real-source-parser-baseline.json`, `bootstrap-stage0-boundaries.json` and `bootstrap-compiled-prefix-candidates.json`.

All seven initial transitions were validated against actual stage0 top-level boundaries. Canonical raw lexer tokens, combined tokens, called helpers and returned remainders are in `bootstrap-parser-minimized-traces.json`. A typed-body failure restores the remainder to `after_colon`; the reported newline is not the deepest failing token.

## Generic canonical repairs applied

Only `bend2/selfhost/parser.bend` was changed in production source.

1. Indexed erased parameter headers: contextually split the combined `<-` token into the opening delimiter and erased-binder marker; global IO arrow tokenization is unchanged.
2. Cons patterns: parse the right-hand pattern recursively and retain existing scanner frames, quantity scopes and right association.
3. Tuple patterns: support nested tuples, right association, grouping and strict closing delimiters through ordinary pattern helpers. No pattern frame/schema rewrite.
4. Character/string patterns: reuse existing literal decoding and convert only constructor-only literal syntax into patterns; reject non-constructor conversion results.
5. Multiple-match syntax: accept whitespace-separated scrutinees and patterns as well as existing commas, retaining case-arity checking.

Focused normalized semantic parity: 5/5. Secondary whole29 acceptance and semantic parity: 29/29 (23 accepted and six jointly rejected). Public regressions: `bun test evals/parser_bootstrap_compatibility.test.ts`, 5 PASS, 146 assertions, guarded physical-footprint peak 1,974,028,304 bytes.

Per-family reports are `bootstrap-parser-family2-fast-shared-abi.json`, `bootstrap-parser-family3-corrected-fast.json`, `bootstrap-parser-family4-fast.json` and `bootstrap-parser-family5-fast.json`. Raw-source hash corrections for earlier JSON-encoded source fingerprints are explicitly recorded in `bootstrap-parser-family-source-hashes.json`; historical reports were not silently repinned.

## Current full-source evidence

At the fifth family, nine real modules completed full canonical evaluation across the main and remaining-module runs. Five accept: driver, LoadedModule, Ast, Lexer and Path. Four accepted modules match full normalized stage0 ASTs; Lexer does not. The Lexer mismatch is retained without semantic exclusions in `bootstrap-parser-family5-remaining-real.json.lexer.bend.mismatch.json` and `bootstrap-parser-lexer-semantic-differences.json` (38 structural differences; cons expressions involving `sign`/`d` were interpreted as datatype application).

The generated source now reaches `u32_bits` (offset 26653), Base reaches `Word` (offset 2043), and CoreSlice reaches `lookup_binding_head` (offset 4744). Natural-prefix patterns such as `1n+rest` are still unsupported. Core reaches `@unsafe`/`map_syntax_terms` (offset 646); unsafe dispatch mishandles the declaration token/newline. Stage0 accepts the minimized natural-prefix and both unsafe forms; canonical rejects them. Actual token/helper/remainder evidence: `bootstrap-parser-newly-exposed-traces.json`; native oracle: `bootstrap-new-minimized-stage0-oracle.json`.

## Blocking prerequisite; no optimization or premature rebuild

The required full fast JSEmit parse exceeds the unchanged 8192 MiB physical-footprint guard before a decoded canonical result, including an isolated single-module run (peak 8,611,888,392 bytes, 202,788 ms). The combined fifth-family run also stopped there (peak 8,593,796,416 bytes). No acceptance or semantic hash is claimed for that run.

The diagnostic token path uses actual unchanged Bend Lexer.tokens plus the exact canonical combine_symbols component, generated by unchanged stage0 with full native validation and zero exclusions. The evaluator receives ordinary exact String/Token/Nat constructors; shared unary input Nat constructors avoid redundant ABI encoding. No host tokenizer or host parser, parser architecture/memory changes, generated-output patches or production compiler changes were introduced.

A direct ordinary native canonical-parser build was also guarded and exceeded the cap during loading (8,611,027,592 bytes). The accepted lifetime path remains preserved, but running the final artifact rebuild before all fast gates are green would violate the requested ordering. No final parser artifact regeneration/build was performed. Remaining grammar repairs, full compiled ten-module proof, closure fixed point and Template census are not complete.

The old compiled artifact, old generated sources, whole29 evidence, Checker extraction, Template audits and earlier reports remain preserved. Further work needs a decision on the fast-gate prerequisite, not a claim that parser compatibility is closed.

## Three-defect repair iteration: compat-three-v1

Canonical SHA-256: `92c30e06803ff5aba858b443188aa58911e8dc392a814272ba62155f7ce7fbe3`.

- F32 now wraps `u32_bits`, not `u32_literal`; five complete-AST/binary32 regressions pass. Bounded arithmetic is unchanged.
- The minimized local failure is `l r = x y` followed by `(l, r)`. Stage0 accepts; pre-repair canonical, frozen factored/generated sources and frozen F32-bounded-v1 artifact reject at byte47–48 (newline), leaving the return tuple. The first divergence is canonical ordinary-local dispatch incorrectly entering array-write parsing. No `Array.map`/`ANode` special case was added.
- Parallel locals consume exactly one RHS per binder, including multiline RHS lists. Seven local syntax fixtures match complete stage0 ASTs.
- Newly reachable Base AST comparison exposed captured-variable depth under nondependent arrows, unmarked dependent-arrow quantity (`Lone`, not `Many`) and the rewrite motive's addressable `_` binder. All eight focused declaration observations pass.
- Pattern speculation now balances delimiters and recognizes a depth-zero `=` before constructing pattern ASTs. The 8,388,608 tuple expression makes zero `nat_pattern` calls; legitimate small Nat cases still construct exact stage0 patterns. All22 acceptance/pattern/complete-AST fixtures pass. No legitimate Nat pattern is truncated.

Full canonical Base: complete ParseSuccess and exact normalized AST parity, hash `b411ec203d9e3ecb0f1bba60c1763c34f18e8ceaf8d7c36f9f395e6607de56c6`;17.785s, footprint5,342,892,400 B/RSS5,355,651,072 B. The read-only semantic observation additionally handles native dry template definitions/existing instance keys, sequential law scopes and post-parse loader builtin policy; it does not borrow native parsed bodies or change template expansion. Numeric observation executes checked unchanged Base primitive exports with exact lazy Peano views.

Canonical, factored and regenerated sources each pass61/61 (F32 five, operator/continuation19, locals seven, declaration observations eight, Nat commitment22), public14/14, focused23/23, whole29/29 and bounded real6/6. Fresh Request/Kont candidate: `619db893175af5801c4723edb9af5924cbe10273670d99464e713c45c2bcd34f`,542947 bytes/1029 definitions. Structural gate: zero unresolved references, non-singleton SCCs, selected calls under synthetic lambdas and source-specific generator exceptions. The recomputed additional cut is still four: `consumed_token_end_before`, `literal_pattern_fields`, `parse_pattern_tuple`, `pattern_scan`; no cut-cardinality assumption or architecture change.

**First remaining blocker: source-evaluator execution of the exact pre-build generated-input prefix.** Canonical, factored and regenerated evaluators all exceed the unchanged8 GiB physical-footprint guard on157 declarations; no completed parser result or AST parity is claimed. Factored:255.784s, footprint8,655,297,184 B/RSS4,459,347,968 B. Generated:334.220s, footprint8,629,639,840 B/RSS6,451,707,904 B. Canonical158 reached source parsing but the external180s command deadline stopped it; no stack/fuel/success classification is invented.
 
Reduced reproducer: `compat-three-v1-prefix-resource-repro.bend` (128 declarations,62018 characters, SHA `a8206599d83a7cd057629366555009f31bc90476c65117684ac38ed2916f3990`). Stage0 accepts; canonical evaluation terminates at the footprint cap after27.236s (8,590,711,408 B footprint/8,568,291,328 B RSS). Smaller64,96 and97 prefixes complete with exact AST parity;97 passes at45,715 characters. This is a reduced failing input, not a proved globally minimal resource boundary. Bounded probing observed no committed Nat pattern above1024 before termination. GC/span observation experiments did not remove the evaluator limit and were reverted. No semantic rejection justifies another grammar repair; truncating the AST/input would violate parity, and raising limits or changing evaluator architecture is outside scope.

The required157/158 pre-build gate is not green. Consequently **zero new artifact builds**, no complete500 KB generated-input attempt, no new compiled ten-module count, and no conditional stage1 closure/Template census or CheckerCore/JSEmit continuation. Production kernel/compiler, checker/template/JSEmit semantics, automatic fuel policy and accepted worker stack policy remain unchanged.

Evidence: `compat-three-v1-result.json`, `compat-three-v1-canonical-repair-evidence.json`, `compat-three-v1-local-four-layer-evidence.json`, `compat-three-v1-base-canonical.json`, `compat-three-v1-nat-canonical.json`, `compat-three-v1-nat-commitment-trace.json`, the three public/fast gate report pairs, prefix reports, `bootstrap-parser-rebuild-compat-three-v1.prepare.json` and `bootstrap-parser-rebuild-compat-three-v1.current-cut-v1.json`. The accepted F32-bounded-v1 artifact and repaired JSEmit transport remain unchanged. **SELFHOST GREEN: NO.**

## Compiled-authoritative continuation: native validation blocker

The user explicitly waived the157/158 source-evaluator pre-build gate. No source-evaluator attempts were repeated. The accepted canonical (`92c30e06…`), factored/normalized (`2f8b4475…`), graph (`6cb5d3c8…`) and generated (`619db893…`) hashes were confirmed unchanged. The existing accepted regeneration and small semantic/structural gates were reused; no grammar or generated output was edited.

One exclusive established artifact-builder attempt ran with8 GiB physical/RSS limits,10ms sampling, zero native-check exclusions, retained native checked output and the accepted bounded GC policy. Loading completed1558 declaration events. Validation completed events0–1214, then failed at event1215, `step_rewrite_motive_branch_0`:

```text
expected: an annotated term (cannot infer)
observed: Scope{"_", depth} <> scope
generated line5046: base_scope = Scope{"_", depth} <> scope
```

This is an actual native bidirectional-inference failure during candidate validation, not the old source-evaluator resource limitation and not a codegen resource breach. Full native validation is incomplete:1215/1558 events completed, zero exclusions.

Elapsed16.369s. Phase sampler peaks: loading261,669,848 B footprint/559,382,528 B RSS; validation3,950,267,776 B footprint/3,965,190,144 B RSS. Process-tree guardian peaks:3,979,627,952 B footprint/3,999,367,168 B RSS. Codegen was not reached; no JS artifact, byte count or SHA exists for this attempt. Compiled targeted gates, ten-module corpus and conditional closure/Template/CheckerCore/JSEmit continuation were not reached. Production kernel/compiler and semantics remain unchanged.

Exact evidence: `bootstrap-parser-rebuild-compat-three-v1.native-blocker.json`, `.build.jsonl`, `.progress.json`, `.phase-memory.bin`, `.build.guardian.json`. **NATIVE VALIDATION BLOCKER; SELFHOST GREEN: NO.**

## Annotated native build: compat-three-typed-v1

Canonical `parse_rewrite_motive` now annotates the forced underscore scope as
`{ Scope{"_", depth} <> scope : List<&2, Scope> }`. The eight declaration
observations retain complete AST parity. Canonical SHA:
`58876c5eb17f3c461044a0f01f6a14d8bc39014984e676117e041fac2c563adc`.
The unchanged regeneration pipeline recomputed the same four additional cut
seeds; factored and generated public14 and fast58 gates pass.

Full native validation completed1558/1558 declaration events,1368 checked
definitions, zero exclusions. Codegen completed using accepted emit/release
and bounded GC. Artifact: `bootstrap-parser-rebuild-compat-three-typed-v1.js`,
34,549,645 bytes, SHA
`4e2c0413ebd2083d4a4494e73e6d1213fa5c76a4e23bb3282237cc369439fbd9`.
Generated candidate SHA:
`4ea6bf0edf0e3dd0b28b8313061cc1a8b50ee0b182daa6436f254ffb8401214e`.

Exclusive8 GiB guardian,10ms polling:63.356s, peak footprint7,354,374,144 B,
RSS7,370,014,720 B. Phase validation peaks:4,038,774,240 B footprint,
4,043,735,040 B RSS; codegen:7,354,357,760 B footprint,7,370,014,720 B RSS.
Evidence: the typed build `.result.json`, `.metrics.json` and
`.build.guardian.json`. Production kernel/compiler hashes remain pinned.

Compiled F32 five: complete AST parity and exact bits pass. Full compiled Base:
472 declarations, complete normalized AST parity with hash
`b411ec203d9e3ecb0f1bba60c1763c34f18e8ceaf8d7c36f9f395e6607de56c6`;
3.088s,900,429,848 B footprint/998,014,976 B RSS.
Compiled Nat commitment22 passes, including the8,388,608 tuple expression and
both jointly rejected inputs. Evidence: `compat-three-typed-v1-compiled-f32.json`,
`compat-three-typed-v1-compiled-base.json`, `compat-three-typed-v1-compiled-nat.json`.
Fresh isolated compiled prefixes97/128/157/158 all complete with exact normalized
AST parity. They explicitly report prefix success, not full-file/corpus success.
Elapsed27.197/23.764/107.421/42.127s; respective footprint peaks
956,206,224/2,428,080,448/2,629,554,520/3,229,307,680 B. Tiny6 and whole29
also retain acceptance and complete normalized parity. The complete ten-module
corpus is being exercised with unchanged8 GiB/10ms guards and a900s per-module
wall deadline; no closure or selfhost-green claim follows from partial results.

## Typed artifact full corpus: real list-pattern grammar failure

The typed artifact completed every one of the ten isolated full-file attempts.
Nine have ParseSuccess and exact complete normalized AST parity, including Base,
CheckerCore slice and JSEmit. Only the frozen506,411-character generated parser
is rejected. Its complete ParseFailure reports `invalid or unsupported top-level
syntax`, observed newline, span271589–271590 (the `syntax_word_step` header's
newline at line3852). Its match contains `Ast.TermCtr{"WCon", [bit, _], _}`.
This is a real grammar rejection, not timeout, fuel, stack, transport or memory
failure. Its guardian passed at3,526,620,112 B footprint/3,184,574,464 B RSS.
JSEmit complete parity passed at5,286,059,928 B footprint/4,702,027,776 B RSS.
Evidence: `compat-three-typed-v1-compiled-corpus10.json` and per-module sidecars.

The minimized public case `case [bit, _]: bit` is accepted by stage0 and rejected
by the typed compiled artifact (`compat-three-typed-v1-list-pattern-red.json`).
Canonical pattern scanning now uses its existing frame schema for square lists,
desugaring to exact Con/Nil patterns and retaining element quantity/scope.
An accumulator consumes the existing reverse field list without allocating a
reversal. Mismatched/missing closes reject. Bare fixed lists, constructor-nested
affine fields, empty/multiline/trailing-comma lists and both invalid boundaries
match stage0 acceptance, patterns and complete ASTs. Canonical regressions66/66
passed; the final accumulator path passed all five focused observations.
Evidence: `compat-three-list-v1-canonical-list-final.json`.

Fresh namespace `compat-three-list-v1` is regenerating this generic repair.
No stage1 closure/census or CheckerCore/JSEmit integration executes before the
required complete10/10 parity. Source-evaluator large prefixes remain waived.

## List repair regeneration and codegen boundary

The original factoring script assumed four completed-token text classes, while
the rebuild runner redirected that constant to five. Square-list closing adds
a sixth. The classes were already generated exhaustively from actual clauses;
the obsolete count guard and its redirect were removed, not repinned.
Two failed preparation namespaces preserve this incidental configuration drift.
`compat-three-list-v3` successfully regenerated; factored/generated each passed
66 regressions, public14 and fast58. The fresh minimum additional cut remains
the same four seeds with zero residual mutual SCCs.

The candidate completed full native validation1563/1563 events. Codegen then
breached the physical-footprint guard:8,598,805,128 B footprint,
7,229,800,448 B RSS,38.049s. The last durable boundary was
`traversal-before` for `pattern_expect_action`, at6,129,128,488 B footprint,
510 releases/680 preparations. No completed JS artifact is claimed.
Evidence: the list-v3 `.validation-timings.json`, `.progress.json`,
`.build.guardian.json` and `.phase-memory.bin`.

The diagnostic GC profile now observes the already-existing prepare/traversal/
emit/assembly boundaries as well as release. A4 GiB pre-allocation pressure
threshold still requires256 MiB growth since the last collection; this avoids
repeated collection of unreclaimed committed pages. Release batches and native
checking remain unchanged. Both profile consumers migrate to `observe`.
`compat-three-list-boundary-gc-v1` regenerates identical grammar under the
unchanged8 GiB/10ms guard. Its build and compiled corpus are not yet claimed.

## Compiled VM optimizer boundary; not parser AST growth

Boundary-GC build passed: artifact SHA
`6577629c81a76b16cae04272466c94f194355287f96755b3672e0d500e8ba1ad`,
41,247,252 bytes,1563 fully validated events, zero exclusions. Guardian peaks:
8,279,644,664 B footprint/8,083,210,240 B RSS. Build1,376.038s;2,348 GC
collections consumed1,337.924s. Emergency collection repeated on committed
pages; it now requires fresh growth or four releases before another collection.

The stock-Node full corpus completed7/10 with complete normalized parity;
generated parser, CheckerCore slice and JSEmit hit resource guards. Generated
input stopped during the actual compiled call, before ParseSuccess/serialization:
8,615,116,800 B RSS/8,190,522,584 B footprint. Its stage0 oracle used about150 MB.
An unchanged-artifact VM trace observed only315.2 MB live JS heap/349 MB total
heap while the process footprint crossed8 GiB. Optimization tracing ended
while `$pattern_completed_text$` compiled to Maglev.

A controlled diagnostic disabling only Maglev parsed the same506,411-character
source completely with FeedbackComplete/ParseSuccess:3.726s,
775,604,840 B footprint/794,345,472 B RSS. Fuel2,000,000 and worker stack256 MiB
were unchanged. This isolated VM-optimizer allocation from parser AST growth,
but did not compare the AST and is explicitly NOT the required stock-worker
10/10 gate. Evidence: `compat-three-list-boundary-gc-v1-result.json` and its
corpus/phase reports; captured VM traces are artifacts3209/3210/3211.

Stock worker policy remains unchanged. `compat-three-list-eq-v1` factors the
completed-token classifier into sequential existing `String.eq`/Bool branches,
preserving all source-derived classes and fallback, instead of one large
multi-string constructor match. Canonical grammar is unchanged. New semantic
gates, full validation/build and stock-worker corpus remain to be exercised.

## Sequential classifier build and isolated expectation diagnosis

`compat-three-list-eq-v1` rejected a computed match scrutinee during body replay;
`eq-v2` passes that Bool as a helper parameter instead. Factored and generated
layers passed 66 regressions, public14 and fast58. Full native build validated
1569 events / 1379 definitions with zero exclusions. Artifact SHA
`87093c91a7b371b6b82ec809e1c85e53d57c5738ca3d86a9798267766baa33ba`,
41,115,458 bytes. Build127.062s; guardian peaks8,267,684,320 B footprint /
8,279,638,016 B RSS. The bounded-GC refinement removed the previous repeated
emergency-collection stall.

Stock corpus still finished10/10 attempts with only7 complete accepted/parity
results. Module2 hit RSS8,595,865,600 B before parse completion. A controlled
Maglev filter selecting only `$pattern_expect_action$` also crossed the8 GiB
guard:8,603,369,472 B RSS /8,582,512,568 B footprint in3.595s (trace3227).
This diagnostic does not count as acceptance. The earlier final trace entry
for `$pattern_completed_text$` did not establish that function as the culprit.

`compat-three-list-linear-v1` now emits one expectation selector per ordered
source row, forwarding unmatched inputs to the next selector. Canonical grammar,
action tags, quantities, lookahead and default stock-worker policy are unchanged.
Factored66/public14/fast58 and regeneration passed; generated/full native and
stock-worker acceptance remain to be exercised. No stage1 closure census or
CheckerCore integration is claimed.

## Final stock-worker parser acceptance and actual stage1 closure

`compat-three-list-linear-v1` passed factored/generated/compiled66 (294 assertions
per layer), public14 and fast58 for both source layers. Full native validation:
1584 events,1394 checked definitions,zero exclusions,zero output patches.
Artifact `bootstrap-parser-rebuild-compat-three-list-linear-v1.js` is25,984,627 B,
SHA `7f86f11dbd3c56c35003ee1eba61adff827b976382d5117bcc9e718d1d5aa37d`.
Build41.487s; guardian peak4,664,610,872 B footprint /4,817,698,816 B RSS.
Accepted emit/release profile collected36 times (14.246s).

On that exact artifact, compiled F32five passed full AST/bits parity; all27
Nat/list-pattern fixtures passed, including `(8388608n, True{})`. Fresh default
Node workers passed complete normalized AST parity for97/128/157/158 declaration
prefixes. Compiled tiny6/whole29 passed. Frozen corpus10 passed10 complete full-file
parses and10 normalized AST comparisons; peak5,203,107,856 B footprint /
5,460,312,064 B RSS. No Maglev flags, stack/fuel policy changes, source-prefix
waiver reversal or AST-field exclusions were used.

Only after10/10, `bootstrap_parser_closure_census.ts` computed the actual stage1
fixedpoint rooted at the driver and the NEW551,935-character generated parser.
Existing complete corpus proofs are reused only with identical artifact/source
hashes; every newly discovered source uses the same isolated full-file gate.
The new generated source passed full AST parity in18.880s with5,479,487,824 B
footprint /5,983,420,416 B RSS. No failed-prefix discovery/counting fallback.

Closure:10 modules,2278 declarations,22 template definitions,54 TemplateBinder
constructors,59 TermTemplate constructors. **T1**, complete closure/all-source
parity. Counts distinguish real syntax constructors from implementation patterns.
Evidence: `compat-three-list-linear-v1-stage1-closure.json`; aggregate
`compat-three-list-linear-v1-result.json` links all gates.

CheckerCore continuation reaches its unchanged native ownership boundary:
`fail(span: Ast.SourceSpan, ...)` uses span in both `span_file(span)` and the
diagnostic. Prior index503 failure remains ground truth; no unchanged confirmation
run, checker/Template/JSEmit semantic patch or unchecked build was substituted.
SELFHOST GREEN remains NO. Temporary VM diagnostic probes were removed.

The ownership boundary above is historical. Current authorized typed-step
CheckerCore/JSEmit integration passes full native validation and21 actual runtime
scenarios; see `checker-core-integration.md` for the explicit Node trust boundary,
current closure evidence and the remaining full self-bootstrap/Template scope.
