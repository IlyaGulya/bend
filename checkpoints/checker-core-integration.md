# CheckerCore diagnostic integration

The attempts below are chronological checkpoints, not the current status.
Current accepted native/runtime evidence is in the final section.

## Exact Template-independent component

`checker_core_slice.bend` mechanically copies the current dependency closure of `Checker.check_modules`:416/418 defs, excluding only `check` and `check_template_result`. All416 definition blocks independently compared byte-for-byte with the original Checker. Bodies, signatures, quantities and source-relative order unchanged; required type declarations retained; relative import paths adjusted to the checkpoint location. Template import and references absent. Dependency report: `checker-core-dependency.json`.

`checker_core_driver.bend` imports shared LoadedModule, this exact slice and normal JSEmit; exports `parsed_module`, `check_expanded`, `emit_modules`. **CHECK ALREADY-TEMPLATE-EXPANDED MODULES**; not full `Checker.check`. No target was fed to it, so the template-free precondition has not been exercised as an integration gate. JSEmit source and its unexpanded-template rejection remain unchanged.

## First CheckerCore component blocker

Normal library-import entry `checker_core_component.bend` loaded **918 native declaration events**. Full unchanged native validation began with retained e and **zero exclusions**; stopped at index503, `checker_core_slice.fail`:

```bend
def fail(span: Ast.SourceSpan, message: String, expected: String, observed: String) -> Inference:
  InferenceFailure{ Diagnostic{ span_file(span), span, message, expected, observed}}
```

```text
expected: span
observed: span (consumed more than once)
```

This is a native ownership failure in exact Checker implementation source, not a selfhost Checker rejection of a target and not a Template dependency. Same failure observed when loading the slice directly; final evidence uses the intended library-import context. No quantities or semantics patched. Peak footprint104874656 B /RSS140558336 B;20.635s;8 GiB footprint/RSS limits,10ms guardian. Full validation incomplete; component codegen, JSEmit component build, target Checker/JSEmit runtime, six-case corpus and stage1/stage2 NOT REACHED.

Complete bounded CheckerCore order audit: **416 live defs,161 forward edges (55 inter-SCC/106 within-SCC),75 defs with self calls,29 non-singleton SCCs**. All reachable from check_modules. `checker-core-ordering-audit.md/.json` lists every SCC and per-definition order/direct/earlier/later/self/SCC constraints. No SCC/order migration applied; ownership fails before these ordering constraints can be exercised fully.

## Actual bootstrap compiled-parser census: incomplete, neither T0 nor T1

Roots: actual `checker_core_driver.bend` plus the accepted generated parser implementation `bend2/selfhost/.parser_definition_body_shape_generated_fuel.bend` (SHA822e8460ff94ff3f00695e27f5b4fe4dbd3515ae4d6d5c3b3c5eb7c1867b840e). Imports were discovered from the **accepted compiled parser artifact's AST**, not regex or a host parser. No Template implementation dependency is rooted by this new driver.

The artifact ran unchanged with the existing explicit200000-cell fuel input. Bun/default Node hit native String.to_list recursion stack limits on the506411-byte parser source; final census used Node worker threads with an explicit256 MiB stack, still under the same exclusive8 GiB/10ms process-tree guardian. No artifact, parser code, generator, fuel policy or runtime emitter changed.

Full-source parsing **succeeds for3 of10 header-discovered modules**:

| Module | Full parse | Declarations | First full-source rejection |
|---|---|---:|---|
| checkpoints/checker_core_driver.bend | PASS |3| — |
| bend2/selfhost/.parser_definition_body_shape_generated_fuel.bend | FAIL |unknown| byte26151, line298, feedback_pack_4 |
| bend2/base.bend | FAIL |unknown| byte723, line51, Word.Con: observed `<-` |
| bend2/selfhost/loaded_module.bend | PASS |1| — |
| bend2/selfhost/ast.bend | PASS |15| — |
| checkpoints/checker_core_slice.bend | FAIL |unknown| byte3090, line78, same_quantity |
| bend2/selfhost/js_emit.bend | FAIL |unknown| byte253, line10, js_escape_char |
| bend2/selfhost/lexer.bend | FAIL |unknown| byte1714, line61, token |
| bend2/selfhost/core.bend | FAIL |unknown| byte108, line5, pattern_list_depth |
| bend2/selfhost/path.bend | FAIL |unknown| byte203, line10, finish_relative |

All failures are FeedbackComplete containing ParseFailure, message `invalid or unsupported top-level syntax`, expected `a supported declaration`. Except Base (`<-`), observed token is newline. These are concrete compiled-artifact failures on real bootstrap inputs; parser was not repaired.

The3 fully parsed modules contain **19 declarations, zero TemplateBinder, zero TermTemplate, zero template definitions, zero template application sites**. **These are partial counts, not bootstrap T0.** Whole-bootstrap declaration/template counts remain unknown for7 rejected modules. No expected values invented from source text.

For failed modules, an exact initial import prefix was parsed with the SAME compiled artifact solely to discover header imports; prefix declarations were not counted. This does not prove a complete module AST/closure or absence of imports/template constructs later in rejected source. Structured report marks whole-closure completeness false and full totals null. That is the exact unreachable prerequisite for a T0/T1 census under the required parser-only restriction.

Census evidence: `bootstrap-template-census.json`, `bootstrap-template-census-failures.json`, `bootstrap-template-census.guardian.json`. Final census footprint416834016 B /RSS459456512 B;18.666s. All7 failures retain exact file/span and source contexts.

## Reproduction and boundary

Archived runners/workers: `checker_core_build.ts`, `checker_core_census.ts`, `checker_core_census_node.mjs`, `checker_core_census_worker.mjs`. Restore these unchanged to `/tmp/bend-artifact-d746e7cc/evals/`, retaining existing heavy_gate/load_replay_kernel prerequisites; run sequentially there:

```sh
bun evals/heavy_gate.ts --memory-mib=8192 --rss-mib=8192 --poll-ms=10 -- bun --smol evals/checker_core_census.ts
bun evals/heavy_gate.ts --memory-mib=8192 --rss-mib=8192 --poll-ms=10 -- bun --smol evals/checker_core_build.ts
```

First failing bootstrap stage: **compiled parser**. Independently, first component-build stage: **CheckerCore native build / ownership**. No later stage patched around either error. No Template refactoring, host target checking/emission or expansion bridge applied. Frozen parser artifact, parser.bend, parser generator, bend.ts and production comp.ts unchanged. **SELFHOST GREEN: NO.**

## Parser prerequisite cleared; actual stage1 census is T1

The new artifact SHA
`7f86f11dbd3c56c35003ee1eba61adff827b976382d5117bcc9e718d1d5aa37d`
passes complete normalized AST parity for10/10 frozen modules in stock Node
workers under exclusive8 GiB footprint/RSS guards. The source-evaluator157/158
waiver remains; compiled97/128/157/158 prefixes pass independently.

The actual stage1 closure replaces the historical parser root with
`.bootstrap_parser_rebuild_compat-three-list-linear-v1_generated_fuel.bend`
(SHA `3f548a6f73acac8f4f089819f2bc522eddd2358b2b62be536260c8d8260447bb`).
All10 closure modules have complete source/compiled AST parity:2278 declarations,
22 template definitions,54 TemplateBinder and59 TermTemplate constructors.
This is complete **T1**, not the historical partial19-declaration lower bound.
Report: `compat-three-list-linear-v1-stage1-closure.json`.

First current blocker is now **CheckerCore native ownership**, not parsing.
The exact original `checker.bend:76-77` still has the same linear-span duplication
as the extracted slice. Its already observed index503 failure was not rerun to
confirm it. Native component emission and target CheckerCore/JSEmit execution
remain blocked; no exclusions, changed checker quantities, semantic repairs or
Template expansion bridge were applied. **SELFHOST GREEN: NO.**

## Authorized ownership annotations; next boundary is mutual SCCs

After explicit authorization, canonical Checker parameters `fail.span` and
`constructor_field_demand.scrutinee` were marked reusable. Function algorithms
and runtime bodies are unchanged. `checker_core_owned_v1.bend` mechanically
copies the same416-definition closure from the updated canonical source;
the frozen slice, driver and corpus snapshots remain unchanged.

Native validation now reaches `lookup_binding` and rejects its forward reference
to `lookup_binding_head` (918 loaded events,zero exclusions). This is the first
mutual SCC in the existing29-SCC audit. GUIDE states that mutual recursion is
not allowed; quantities/type annotations alone cannot resolve this boundary.
No unchecked component emission, unsafe annotation or SCC lowering was applied.
Evidence: `checker-core-owned-validation-v1.json`.

The affected actual closure, rooted at `checker_core_owned_driver_v1.bend`,
passed complete compiled/stage0 AST parity to a10-module fixedpoint in27.31s.
New driver, new slice and actual generated parser were checked in fresh guarded
stock workers. Report: `checker-core-owned-stage1-closure-v1.json`.
Component runtime verification remains blocked pending SCC-lowering scope.

## Authorized SCC lowering; native structural-recursion boundary

Mechanical lowering is now authorized. Canonical ownership annotations cover
the existing repeated uses in lookup, scope and family helpers; the local
`import_scope_base.prefixed` constructor also has an explicit `Global` type.
The algorithms, frozen slice/driver/corpus and production compiler are unchanged.

`checker_core_scc_lower.ts` covers all416 original definitions and all29 mutual
SCCs, with zero residual mutual SCCs or forward DAG references in its emitted
graph. The two lookup SCCs use identity-argument tail-helper fusion; the others
use dependent-result dispatchers. Constructor-call braces are authenticated by
the stage0 constructor table. Existing underapplications retain their supplied
argument positions; no missing inference argument is inserted.

The actual lowered-driver closure passes complete compiled/stage0 AST parity
for all10 modules in26.56s:2360 declarations,22 template definitions,
54 TemplateBinder and59 TermTemplate constructors (**T1**). The lowered source
SHA is `f1dd8e8c50a67b5af2922a028b21b48576af53a58f9f90fa0f647f6472c3980c`.
Fresh stock workers peaked at6,908,788,736 RSS bytes and4,663,598,352 footprint
bytes. Report: `checker-core-lowered-stage1-closure-v1.json`.

Full native validation still fails, now outside a mutual SCC:
`application_type_view` calls itself on `Core.subst(index, value, body)`
(`checker.bend:2124`). The native checker rejects the computed argument as
non-decreasing. This failure is observed in
`checker-core-lowered-component-v17.result.json`:556ms,zero exclusions,
zero output patches; no CheckerCore artifact or target execution.

Read-only reviews identify additional independent boundaries, not executed
runtime observations: the16-member whnf/family SCC resets normalization fuel
and permits a same-argument family cycle in its unrefined Global input type;
the110-member inference SCC recurses on substitution/lowering results and has
two pre-existing ten-argument calls to the eleven-argument
`check_lambda_body_result`. Helper fusion alone does not establish native
structural decreases or repair those argument positions.

The component builder has separate native/compiled smoke proof for a small
dependent-result dispatcher with decreasing same-constructor recursion. That
proof is not CheckerCore acceptance. The six-case CheckerCore/JSEmit target
gate remains unexecuted because no validated component exists.
Further progress requires algorithmic migration scope, not more quantity
annotations or a claim that the generated call graph proves termination.
**SELFHOST GREEN: NO.**

## Authorized algorithm migration and explicit Node orchestration

Algorithmic migration is now authorized. The selected execution boundary is
native-validated Bend steps/continuations plus an explicit trusted Node LIFO
driver, without FFI or arbitrary new fuel/step limits. The driver is outside
the native termination proof; it is not described as a total native checker.

A dependent-progress prototype passes complete stock native validation and
unpatched JS emission. Actual emitted execution returns4096n and both native
Bool values across4097 continuations, including a Bool-to-Nat resumption.
Reports: `checker-core-step-shape-component-v1.result.json` and
`checker-core-step-shape-component-v2.result.json`.

Canonical source now supplies the omitted lambda-body inference, selects the
valid domain branch correctly, validates a datatype kind before inserting its
own family, imports the real Core dependency, and uses the existing
FamilyLowering type rather than an undefined FamilySugar. Missing case-row
extraction returns an explicit Maybe and propagates malformed-case failure;
it does not synthesize empty coverage. The owned generator derives a fresh
raw-AST root closure:419 definitions, with exact names/block hashes and
unchanged protected historical inputs.

The new shared `Core.pattern_depth` passes full native/compiled smoke:
variable1n, underscore1n, empty constructor0n, nested constructor3n.
Existing Core bodies/unsafe annotations are unchanged; none was added.

The first complete419-function checker-step generation represents1204 source
calls with1206 pending sites and65 lazy Bool choices. Its initial native build
fails on doubled erased-binder syntax (`--v_...`), recorded in
`checker-core-steps-native-v1.result.json`; repair belongs in the generator,
not the emitted source.

An independent emitter-only native check also fails at the existing
`js_term_args` forward call to `js_term`
(`checker-core-emit-prerequisite-build-v1.result.json`). A separate derived
emitter will reuse the same step lowering; canonical JSEmit and its frozen
snapshot remained unchanged at this checkpoint. Runtime proof was pending.

## Accepted typed-step integration: v16

The regenerated current closure contains428 checker definitions and215 emitter
definitions. The shared generator authenticates source calls and dependent
continuations; no missing arguments, fabricated results or new unsafe
annotations are introduced. Administrative erased arguments remain original
source expressions. Continuations are hoisted into typed acyclic helpers so the
complete parser AST oracle needs no exclusions or normalization changes.

`checker-core-steps-combined-native-v16.result.json` records1978 fully validated
native events and1811 checked/live bodies, zero excluded checks and zero output
patches. The stock unpatched compiler emitted `checker-core-steps-driver-v16.js`
(1,461,429 bytes), SHA-256:
`3da1542624a81983536578cc841a0831c75d47ce16634bd8f1d69941e37e8408`.
The guarded build took42,782ms; peak RSS3,461,529,600 bytes and footprint
3,423,390,744 bytes, below the8GiB limits.

`checker-core-target-gate-v16.json` independently proves actual compiled parsing,
Bend checking, Bend JS emission and execution of the returned source unchanged:
21/21 cases pass. Ten accepted programs execute; nine invalid programs return
actual checker failures; two direct emitter guards reject parsed Template
binders/terms at their actual source spans. The partial-family regression first
failed with v15 (`checker-core-partial-family-before-v15.json`) and passes with
v16. Residual family lambdas use the original function signature for application
inference, rather than attempting unsupported inference on an unannotated lambda.

Canonical Checker now distinguishes families, constructors and definitions,
normalizes family applications to actual eta values, and checks residual
constructor coverage without enumerating ordinary function predeclarations.
Canonical JSEmit fixes generated delimiters, qualified constructor suffixes,
the main IO thunk, tuple syntax and explicit malformed/template term failures.
These repairs are in Bend source, not generated-output patches.

Both backends use `checker_core_step_runtime.mjs`'s one trusted Node LIFO loop,
without FFI or added arbitrary fuel. Native validation covers the Bend steps
and exact dependent resumptions, **not termination of the Node orchestration**.
Protected production `bend2/bend.ts` and `bend2/comp.ts`, parser Request/Kont and
the original frozen slice, driver and corpus remain unchanged.
**SELFHOST GREEN: NO.** Template expansion and actual full self-bootstrap are
not established by these template-free targets or direct rejection guards.

Final actual stage1 fixedpoint: `checker-core-steps-stage1-closure-v4.json`,
10/10 complete modules with full normalized semantic AST parity,3111
declarations,22 template definitions,54 TemplateBinder and59 TermTemplate
constructors: **T1**. The generated checker source is610,443 characters and
the emitter249,374; neither uses a prefix fallback. Parser artifact SHA remains
`7f86f11dbd3c56c35003ee1eba61adff827b976382d5117bcc9e718d1d5aa37d`.
This syntax census does not establish Template expansion.

`checker-core-integration-v16-result.json` links the exact parser, native,
runtime and closure proofs with artifact/source/semantic hashes and explicit
remaining acceptance boundaries. Historical failed checkpoints are retained;
temporary AST-difference and partial-family request probes were removed.

## Generation reuse and fail-fast bootstrap diagnostics

The shared typed-step generator now authenticates unchanged generation through
its existing manifest: complete configuration, runtime/resolver context, input
realpaths, transitive import bytes and exact output hashes. Reuse preserves the
generated files and manifest byte-for-byte; it does **not** reuse or skip native
checking. Missing or changed inputs/outputs trigger normal generation.

`step-generation-cache-proof-v1.json` records an isolated, disposable Template
source/import probe. Cold generation took14,871ms; its identical repeat took
127ms. Import drift, configuration drift, missing output and canonical source
drift each forced regeneration. Subsequent unchanged repeats reused the
authenticated manifest. Those are source-generation measurements, not a claim
of equivalent acceleration for native checking or complete bootstrap.

`selfhost_bootstrap_gate.ts --fixture=NAME` runs one actual parsed Template /
Checker / JSEmit consumer against a fully native-validated diagnostic root.
It requires the accepted parser's separate guardian report and compares every
compiled parse with the complete semantic source oracle. The oracle's
informational normalization ledger is not treated as omitted AST fields.
Diagnostic success cannot set `compilerBootstrapGreen` or `selfhostGreen`.
Full mode still requires the parser-containing root, its lossless composition
manifest, all nine compiler exports and actual stage-one/stage-two JS equality.

An observed failure formerly left the worker waiting for IPC. The gate now
terminates the child on failure; worker completion closes its parent port and
stdin/readline orchestration. Failed real consumer runs now finish promptly
(`selfhost-template-first-v1.json` and
`selfhost-application-order-after-v3.json`), rather than remaining alive after
the failed report has been written. Full self-bootstrap remains unestablished.

## Observed law and application regressions: diagnostic v4

`template-checker-native-v4.result.json` validates all2275 live bodies,
2453 events, zero exclusions and zero output patches. Its artifact is
`template-checker-steps-v4.js` (1,800,419 bytes), SHA-256
`4956d04aa995c4de270f6f917d02696ab0b5dfe2b27f9cb6c9e3ab7543f917d0`.
This is an eight-export diagnostic snapshot, not the full compiler root.

Actual accepted-parser / Template / Checker / JSEmit / execution proofs:

- `selfhost-application-order-before-v1.json` returned the two `Duo` fields in
  reverse order. `selfhost-application-order-after-v4.json` passes with
  `Duo{BitOne{}, BitZero{}}`; application-spine accumulation was already in
  source order and must not be reversed again.
- `selfhost-law-completion-before-v1.json` rejected a valid `Word(n)` completion.
  `selfhost-law-completion-after-v4.json` passes and executes `WNil{}` against
  `Word(0n)`. The completion inherits the law's real dependent telescope and
  result; its original source body is checked, not replaced. Checked modules
  retain those inherited parameters for emission.
- `selfhost-law-negative-v4.json` rejects an incompatible completion body at
  its actual source span, rather than accepting any body under an inherited law.

All three passing reports include complete semantic AST parity and PASS
resource guardians. The application regression exposed a second checker issue:
after lambda-closing definition values, application inference must use the
original authenticated function signature, not infer an unannotated reduced
body. Bounded beta/constructor-match reduction remains available for actual
definitional equality such as `Word(0n)`.

The full-Base Template consumer still fails at the constructor local in
`Pair.fst` in `selfhost-template-first-v4.json`. Further canonical repairs and
their generated/native/runtime proofs are pending; v4 is not a proof of later
signature-aware emitter changes or full self-bootstrap.

## Actual typed-erasure/library consumer proof: diagnostic v6

`template-checker-native-v6.result.json` validates all2458 live bodies and
2642 events with zero exclusions/patches. The native build took50,707ms,
peak RSS4,309,237,760 bytes and footprint4,245,999,312 bytes under the unchanged
8GiB/10ms guardian. Artifact `template-checker-steps-v6.js` is2,893,452 bytes,
SHA-256 `24db065a06198990bed07404ffd1d278d73634433909049b3490d3365b9ec439`.

JSEmit now traverses formal quantities in declaration/import-scoped lexical
type closures, rather than classifying erasure by argument syntax. Captures
share immutable list tails; the closure datatype is genuinely self-recursive,
not a forward/mutually recursive datatype group unsupported by the native
linear parser. Original application order and positional library wrappers
remain intact. Checked law-completion signatures are inputs, not re-inferred
by the emitter.

`checker-library-smoke-v6.json` records complete compiled-parser semantic AST
parity, actual Template expansion and checking, and execution of the returned
ESM source unchanged. Its15 consumer observations pass: nullary values,
noncommutative positional calls, partial saturation, returned higher-order
functions, a live callback invoked once, effective arity after erased kind/type
parameters, an ordinary named `Bit` type argument, actual Template
specialization, and a poison callback inside an erased argument invoked zero
times. This is a consumer-only library probe, **not** a counterfeit compiler
root or bootstrap fixedpoint.

`selfhost-dependent-kind-v6.json` and `selfhost-renamed-law-v6.json` independently
execute `BitOne{}` through ordinary polymorphism and a dependent law completion
whose source binder names differ from the law. Their guardians and complete
semantic AST parity pass.

The full-Base consumer advances to typed constructor matching but still rejects
the `Pair.fst` tuple's datatype parameters (`selfhost-template-first-v6.json`).
That remaining real checker error blocks full bootstrap; no selfhost-green
claim follows from these successful isolated consumers.

## Observed dependent checking and constructor ABI: diagnostic v7–v12

The later genuine consumers advance beyond the v6 block above:
`selfhost-dependent-field-v7.json` executes `BitOne{}` from a generic constructor
field, while `selfhost-indexed-negative-v7.json` rejects a mismatched datatype
index. `selfhost-equality-congruence-v9.json` accepts and executes the actual
rewrite-motive congruence shape; `selfhost-rewrite-negative-v9.json` rejects a
motive whose result does not fit the goal. No reflexivity bypass was introduced.

Empty matching is accepted only for a visible datatype with an actually empty
constructor universe. `selfhost-empty-positive-v11.json` passes;
`selfhost-empty-nonempty-negative-v11.json` and
`selfhost-empty-abstract-negative-v11.json` reject the nonempty and abstract cases.

`template-checker-native-v12.result.json` validates all2469 live bodies and
2653 events, zero exclusions/patches, under the unchanged8GiB/10ms guardian.
Native elapsed78,564ms, peak RSS4,196,057,088 bytes, footprint4,297,690,760 bytes.
Artifact `template-checker-steps-v12.js`:2,900,154 bytes, SHA-256
`fb34c43d65588b81243eebc9e3772708a210fdb50b9ece2678ff2b233ad4aa4a`.

The source field name `args` was a real emitted-constructor collision, not an
AST field that could be excluded. `selfhost-constructor-args-before-v11.json`
records wrong execution; `selfhost-constructor-args-after-v12.json` executes
`BitOne{}` through that field. Positional storage now uses
`Symbol.for("bend.fields")`; source names remain enumerable and unchanged.
Transport validates every positional/named alias before serializing the entire
named payload. A throwaway smoke over the actual118-constructor parsed AST
preserved its complete semantic hash, including three semantic `args` fields,
and rejected mismatched values and field counts.

`selfhost-alias-constructor-after-v12.json` executes an imported constructor as
`BitOne{}`. Constructor result families are qualified once at the declaration
boundary, not heuristically stripped or made idempotent.

Branch order columns now enter a match's scope once. The old artifact rejected
valid predecessor recursion (`selfhost-structural-predecessor-before-v11.json`)
and incorrectly accepted unchanged original input
(`selfhost-structural-original-before-v11.json`).
`selfhost-structural-predecessor-after-v12.json` executes four successors;
`selfhost-structural-original-after-v12.json`, `selfhost-structural-equal-v12.json`
and `selfhost-structural-growing-v12.json` reject unchanged, reconstructed-equal
and growing recursive inputs.

`checker-library-smoke-v12.json` passes all15 actual unchanged-ESM consumer
observations. The noncommutative constructor now includes erased fields before
and between its live fields, so partial/higher-order calls also exercise live
slot compaction and named-field aliases without pinning printer whitespace.

Full bootstrap is still **not established**. The actual-Base diagnostic trace
`checker-trace-v12.json` reached `Nat.sub` but hit the external300-second command
deadline with246,500,000 observed requests;211,987,666 were linear
`lookup_global_preferred` requests. It records no final `CheckResult` and is not
a passing gate. A pure indexed visible-scope cutover is being implemented;
native validation and actual full-root fixedpoint remain required afterward.

## Actual indexed-scope proof: diagnostic v15

The checker now carries a pure Bend immutable AVL index alongside ordered scope
entries. Each name bucket retains the first visible entry and first entry of
each kind. Visible and owner-qualified identities are indexed; generic lookup
still prefers the first family over any earlier nonfamily, while kind lookup
selects the first requested kind. Constructor enumeration retains original
entry order and resolves against the full original visible scope, not a shrinking
suffix or the unfiltered declaration catalog.

The declaration catalog is persistent. Ordinary module scopes update
incrementally; dynamic Base/self-import scopes currently rebuild per changed
declaration to preserve exact priority, never per query. This remaining cost
must be measured rather than assumed away.

Native v13/v14 rejected a computed tuple scrutinee and then its affine `Pair`
field in a hardcoded `Data` request envelope. `String.cmp` projection now occurs
through a typed parameter; request kind follows real source-domain kinds and
records them in `authenticatedRequestParameterKinds`. No affine field is
promoted, omitted or relabelled.

`template-checker-native-v15.result.json` validates all2515 live bodies and2703
events with zero exclusions/patches. Guardian PASS:217,775ms,
peak RSS4,351,115,264 bytes, footprint4,573,925,216 bytes.
Artifact2,931,055 bytes, SHA-256
`988fb7672e70c528992d7769c4415447eb6a80d1018159faaa2ea77f15d108bb`.

The same four consumer scope cases pass both before and after the cutover:
distinct imported families remain incompatible; two aliases of the same owner
convert; current-module and imported families remain distinct; a datatype and
its own constructor may share a name. After reports:
`selfhost-distinct-family-index-v15.json`, `selfhost-same-alias-index-v15.json`,
`selfhost-local-family-index-v15.json`, `selfhost-family-ctor-index-v15.json`.
`checker-library-smoke-v15.json` also passes all15 actual ESM observations.
These prove native/consumer correctness, not full bootstrap or a measured
whole-prelude speedup.

## Recursive coverage termination: diagnostic v16

The v15 index did not eliminate the actual algorithmic loop:
`checker-trace-v15.json` again reached `Nat.sub` but timed out with128 million
observed requests. Specializing a successor in an entirely variable column
recreated that same column indefinitely. Such a column now drops directly,
including when the remaining matrix is incomplete; no new fuel/step bound or
acceptance shortcut was added.

Native `template-checker-native-v16.result.json`:2520 bodies,2708 events,
zero exclusions/patches, guardian PASS105,141ms;
artifact SHA-256 `c175aef1344b209851ba5b661d848a21f9873221e1845a2d7113a61ec7c61922`.
`selfhost-matrix-complete-v16.json` executes `BitOne{}`;
`selfhost-matrix-incomplete-v16.json` rejects the incomplete matrix.

The same complete, previously parity-validated actual Base AST now advances
past `Nat.sub`, division, comparison and list operations to `List.range.go`:
`checker-trace-v16.json` observes9,210,134 requests in76,088ms before a genuine
pattern-multiplicity rejection at span18470–18474. Its copied `+n` scrutinee's
predecessor is validly used twice; that remaining canonical quantity rule is
being repaired. This diagnostic still records `CheckFailure`, not bootstrap
acceptance. The native guardian's PASS is a resource proof, not checker success.

## Persistent priority segments and typed multiplicity: diagnostic v17

Visible indexes now have a current-module segment, one separate segment per
import in original order, then implicit Base. Checked declaration prefixes
update only matching owners, including Base/self-import aliases, without
rebuilding complete indexes. Family preference is resolved across all segments
before a nonfamily fallback; kind lookup retains first-segment precedence.
Public `Global`, `State`, `Declarations`, result and module records are unchanged.

Pattern use limits now come from the genuinely typed branch bindings:
requested quantity is bounded by available demand, then multiplied by that
demand. Copied scrutinee fields inherit reusable capacity; affine and erased
fields remain bounded. Vector uses are checked after all binders are typed.
`selfhost-copied-field-v17.json` executes `CZero{}`; `selfhost-affine-field-v17.json`
and `selfhost-erased-field-v17.json` reject excessive live use. Distinct-family
and same-owner-alias regressions also pass on the segmented implementation.

Native `template-checker-native-v17.result.json`:2555 bodies,2744 events,
zero exclusions/patches; guardian PASS117,297ms,
peak RSS4,352,835,584 bytes, footprint4,577,185,632 bytes.
Artifact2,953,336 bytes, SHA-256
`be88601a58ebeda0505a480ee872978efb5c7defda146b5dc146d23f4df9b97e`.

The actual same Base diagnostic advances past `List.range.go` to `Word.zero` in
24,487ms/6,861,747 requests (`checker-trace-v17.json`). This is not a final speed
ratio: v16 stopped earlier at a different rejection. V17 rejects the recursive
`Word.zero(p)` expression at22762–22773, not the `WNil{}` branch. Investigation
found equal original neutral family applications being normalized to stuck
matches lacking a structural comparison case. A sound structural-equality
fastpath and branch-scope invariants remain under repair; full bootstrap is
still unproved.

## Neutral family equality and nested-context regression: diagnostic v18

The checker compares genuine original structural equality before its unchanged
WHNF fallback. Sequential pattern vectors refine their expected goal and
remaining scrutinee types using the checked pattern value at current depth.
Native `template-checker-native-v18.result.json` validates2554 bodies and2743
events, with zero exclusions/patches. Guardian PASS58,941ms; peak RSS
4,759,470,080 bytes, footprint4,744,384,472 bytes. Artifact SHA-256
`d7516de60805b74e438cfba6de63a306402ff6b1d2a86d044b5df8f1f3364a74`.

`checker-trace-v18.json` now passes actual Base `Word.zero`, then rejects
`Word.not` at22880–22959: its nested `match w` still sees the unrefined local
binding type `Word(n)` after the outer `match n`. This cached, fully
parity-validated Base diagnostic observes6,835,200 requests in20,212ms; it is
not a bootstrap acceptance proof. `selfhost-dependent-nested-before-v18.json`
independently reproduces the same failure on a freshly parsed generic indexed
family at407–454, with complete semantic AST parity.

The generic Bits fixtures declare their type-family law as returning `Data`,
matching the actual constructor field kind. The earlier `Type` declaration
was invalid for a `Data` field and is not evidence for neutral equality.
With the corrected declaration, v18 accepts the generic family but its
unchanged emitted program fails during execution
(`selfhost-dependent-data-goal-v18.json`): custom `BCons` was misclassified as
native list `Cons`, and genuine type-family applications lacked executable
type descriptors. These remain separate checker-context and emitter issues;
stage1/stage2 fixedpoint is still unproved.

## Explicit binding type contexts: independent checker v19

Internal `Binding` now stores the depth at which its type is expressed.
Inference lifts by current depth minus saved depth, including parallel local
RHS contexts. Match branches lift inherited binding types into the complete
branch context and refine them using the checked pattern value. Public
`Global`, `State`, result/module records and parser protocols are unchanged.

`checker-context-native-v19.result.json` validates all1529 live checker bodies
with zero exclusions/patches, guardian PASS27,854ms, peak RSS2,058,371,072
bytes and footprint2,010,335,296 bytes. This independent two-export component
lets checker execution proceed while the canonical emitter repair is separate.
The temporary diagnostic combines it with authenticated native Template v18,
never host expansion/checking. Cached AST inputs must retain full semantic
parity and exact source/transport hashes.

`checker-context-nested-v19.json` accepts the previously rejected nested
indexed-family consumer in40,302 requests/198ms. Quantity negatives still
reject (`checker-context-affine-v19.json`, `checker-context-erased-v19.json`).
The actual Base trace now passes `Word.not` and subsequent bit operations,
stopping at `Word.shl.out.con` in7,571,718 requests/47,173ms. Its tuple-tail
type is correctly scoped, but beta conversion produces identical neutral
matches without a structural equality case. The generic Sigma/Pair fixture
also reproduces that preexisting rejection in
`selfhost-dependent-tuple-before-v18.json`, span592–596. None of these
diagnostics establishes emitted execution or the stage1/stage2 fixedpoint.

## Neutral match conversion: independent checker v20

Beta-equivalent dependent tuple fields now compare exact stuck matches:
ordered scrutinees and cases, constructor identities, field structure,
quantities and de Bruijn references remain significant. Source spans and
alpha-bound names are not semantic identity.
`checker-context-native-v20.result.json` validates1535 bodies/1707 events
with zero exclusions/patches; guardian PASS22,736ms. The genuine Sigma/Pair
consumer is accepted (`checker-context-tuple-v20.json`,40,240 requests/169ms).
Distinct neutral indices and distinct branch results still reject at the
actual tuple-tail expression (`checker-neutral-index-v20.json`,
`checker-neutral-branches-v20.json`).

The actual Base trace advances through shifts to `Word.inc`, then rejects
its two disjoint nested patterns `WCon{False{},t}` and `WCon{True{},t}` as a
repeated outer constructor (`checker-context-trace-v20.json`,
8,158,759 requests/18,509ms,25241–25256). The isolated Box/Bit consumer
reproduces that rejection with fresh full-parity parsing in
`selfhost-nested-cases-before-v18.json`. Nested row coverage, including
ordered fallback and unreachable-row rejection, remains under repair.
Full bootstrap is still unproved.

## Ordered nested pattern coverage: independent checker v21

Single-scrutinee matches now use the same typed vector/row pipeline as joint
matches. The obsolete outer-constructor ledger is removed. Earlier rows
reject a candidate only when they wholly cover it; nested subsumption and
constructor-specialized matrix coverage include coverage by a union of rows.
Partial overlap remains a valid ordered fallback. Final full-matrix
exhaustiveness, residual constructor exclusions, field identity/arity and
typed quantities remain enforced.

`checker-context-native-v21.result.json` validates1526 bodies/1698 events
with zero exclusions/patches; guardian PASS33,787ms, peak RSS1,923,317,760
bytes and footprint1,903,380,400 bytes. Actual diagnostics accept disjoint
Box/Bit cases and ordered fallback, reject the second duplicate nested case,
and reject a wildcard row only after both preceding disjoint rows cover it:
`checker-nested-cases-v21.json`, `checker-nested-fallback-v21.json`,
`checker-nested-duplicate-v21.json`, `checker-nested-union-v21.json`.

The Base trace passes `Word.inc`, addition and subtraction, then stops on
the annotated constructor endpoints of `Word.add_comm.arm`:
`checker-context-trace-v21.json`,6,596,843 requests/21,381ms,
26189–26229, “term form cannot infer”. Equation inference had not used its
explicit checked type to check those constructors bidirectionally. This
remaining rejection is separate from pattern coverage; emitted execution
and the fixedpoint remain unproved.

## Guarded run acceleration

The checker-only v26 growth-aware build retains the baseline artifact SHA256
`1136ffa1c62d52d5a874f6324ea6753e987a507d18788a15f26f2e7b14fda873`,
1701 validated events and 1529 checked bodies, with zero exclusions/patches.
`checker-context-native-v26-growth.result.json` records guardian PASS18,550ms,
versus21,373ms for `checker-context-native-v26.result.json`: a single paired
observation, not a stable benchmark. Peak footprint rises from1,965,000,744
to2,663,975,408 bytes, remaining below the unchanged8GiB limit.
Code-generation GC falls from19 collections/5609.87ms to5/2248.119ms;
validation GC falls from54/1981.57ms to3/160.30ms. Scheduled GC requires
256MiB growth; initial collection and existing pressure/emergency protection
remain. Event-log/FFI overhead reduction alone did not demonstrate a speedup.

Diagnostic compiled-parser caching is limited to `--fixture`. Full bootstrap
still executes each stage's own parser. Exact source/parser/code/runtime,
ordered load context, observed import closure, complete semantic AST parity
and native transport hashes authenticate reuse. The unchanged emitted program
prints `CSucc{CZero{}}` in all three actual guarded runs:
`diagnostic-cache-parallel-cold-v28.json` (miss,7105ms),
`diagnostic-cache-parallel-warm-v28.json` (hit,6184ms), and
`diagnostic-cache-parallel-corrupt-v28.json` (malformed manifest rejected,
fresh parser and full parity,1865ms). Timing variance precludes a stable
cache speedup claim; the warm run demonstrably skips parsing/oracle work.

These checks do not establish the full compiler fixedpoint. The first actual
Base/Template fixture reaches emitted execution in
`diagnostic-cache-cold-v28.json`, then fails in `Word.to_nat`; its generated
JavaScript remains unpatched. Backend constructor representation is under
repair.

## Base checking and Template ownership: v28

The v26 checker trace completes all Base definitions and then rejects the
fixture's missing generated specialization name, rather than a Base term:
`checker-context-trace-v26.json`,22,000,233 requests/42,785ms.
Intervening repairs use checked equality annotations, genuine Data-domain
promotion, invariant recursive-call quantities, and simultaneous capture-safe
substitution for parallel bindings. They do not waive native checking.

Template generation now locates a specialization's actual defining module by
module path and original definition span, not namespace alone. Base and the
diagnostic root both legitimately have empty namespaces; namespace-only
ownership misplaced the fixture's generated identity in Base. The v28 actual
type-specialization fixture passes expansion, checking and emission; the
separate emitted Base runtime failure recorded above remains unresolved.

`template-checker-native-v28.result.json` accepts2695 bodies/2885 events,
zero exclusions/patches, guardian PASS96,332ms. Its unchanged compiled library
passes15 ESM consumer observations in `checker-library-smoke-v28.json`.
`selfhost-dependent-nested-binding-v28.json` additionally passes actual nested
dependent matching and emitted execution; the printed `BitOne{}` is compared
as a constructor value, not pinned to incidental nullary brace formatting.
The comparator's throwaway smoke rejects malformed/trailing values and
distinguishes constructor tags, arity and ordered nested fields.

Actual v28 consumers also accept nested structural recursion
(`selfhost-nested-recursion-v28.json`) and reject a fresh, non-ancestral inner
recursive argument (`selfhost-nested-recursion-negative-v28.json`), affine
tuple promotion (`selfhost-affine-tuple-negative-v28.json`), and references to
a sibling simultaneous RHS (`selfhost-parallel-rhs-negative-v28.json`).
`selfhost-law-completion-v28.json` passes emitted dependent-law execution.
The authentic tuple-local consumer reaches emission but fails at runtime with
“malformed local bindings” (`selfhost-dependent-tuple-v28.json`); canonical
emission handles variable local patterns but needs constructor destructuring.

## Constructor-pattern local emission: v29

`template-checker-native-v29.result.json` accepts2732 bodies/2922 events,
zero exclusions/patches; guardian PASS38,344ms and peak footprint
5,540,139,544 bytes. Actual `selfhost-dependent-tuple-v29.json` passes the
previously failing constructor-destructuring local consumer, including
unchanged emitted execution,2044ms.

The canonical emitter also derives primitive constructors from their
authenticated Base family and snapshots pattern fields with fresh lexical
scrutinee names. The actual Base/Template fixture now passes the previous
`Word.to_nat` fail-stop, but fails in recursive `Nat.double` with a JavaScript
stack overflow: `selfhost-template-first-v29.json`,52,240ms. Parsing genuinely
reuses authenticated complete-parity diagnostic cache entries; expansion,
checking and emission are still executed. Eager top-level definition
evaluation is under investigation; no arithmetic special case or emitted
output patch has been applied. Full fixedpoint remains unproved.

The v29 unchanged component's15 ESM observations also pass
(`checker-library-smoke-v29.json`,1743ms). Actual Base-backed rejection
boundaries pass with their required phase and source span:
`selfhost-template-capture-negative-v29.json` rejects runtime capture during
expansion, and `selfhost-template-type-negative-v29.json` rejects the
specialized result type during checking. Runtime matrix/copy observations
and erased-field rejection pass in `selfhost-recursive-matrix-v29.json`,
`selfhost-copied-field-v29.json`, and `selfhost-erased-field-negative-v29.json`.
Shared-module alias identity and dependent field matching pass actual
execution in `selfhost-same-module-alias-v29.json` and
`selfhost-dependent-field-v29.json`.

The eager initializer is confirmed as `Nat.read.max`, not fixture `main`.
The frozen parser also genuinely calls `Nat.read`, so laziness alone is
insufficient for full bootstrap: production `comp.ts` already selects guarded
native Nat arithmetic and other operations for approved Base definitions.
Canonical emission needs that same origin-aware declaration mapping; a
function-name-only arithmetic shortcut would incorrectly change user code.

## Actual Base/Template emitted execution: v31

`template-checker-native-v31.result.json` accepts2764 bodies/2954 events,
zero exclusions/patches, artifact SHA256
`93b46112b8137e299f24d3eb61261d69f35edde57f27f94cab23f130b545125e`.
Guardian PASS79,070ms, peak footprint5,406,691,744 bytes.
The actual Base-backed specialization now passes every diagnostic boundary,
including unchanged emitted execution:
`selfhost-template-first-v31.json`,208,937ms. The15 ESM observations also
pass in `checker-library-smoke-v31.json`,1726ms.

Global values with no live binders are demand-registered and memoized;
resolution tests declaration presence without forcing unused globals.
Approved Base definitions and bodyless native laws use the existing guarded
native-operation contract under their actual declared names. User suffixes
do not trigger intrinsic dispatch. Native metadata retains formal quantities
and does not evaluate erased arguments.

The first v30 native attempt failed on `js_runtime_type`'s single large
literal, not a semantic-check exemption. Partitioning that exact runtime JS
payload into three pure checked String helpers preserves ordering; v31
validates every helper. Production/frozen sources, stack/fuel/resource limits
and generated output remain unpatched. Fresh full9 root validation and
own-parser stage1/stage2 fixedpoint are still required.

## Full9 v3 and measured acceleration work

`selfhost-steps-native-v3.result.json` accepts3833 bodies/4065 events,
zero exclusions/patches, artifact SHA256
`d34c4fccbf19821633224924de68ab8f9540d879f351383e19e71761a01d86e8`,
28,851,886 bytes. Guardian PASS251,725ms, peak footprint8,162,613,680 bytes,
below the unchanged8GiB limit.

`selfhost-full-bootstrap-v3.json` passes the first seed specialization but
fails the second during checking with “unknown name Lib.Bit”, before stage1.
The authentically scoped expansion in
`template-expanded-alias-scoped-v31.json.expanded.json` retains library Bit.
Its generated identity belongs to namespace specialization-lib but captures
the caller's Lib.Bit reference in its binder/result; the library imports only
Base. A native imported-segment probe independently returns the correct
target specialization-lib and alias Lib. This is captured-expression hygiene,
not permission to invent a checker global or change loader namespaces.

Oracle module reuse passes the throwaway sequential/concurrent/deferred
normalization/error-recovery smoke with complete semantic/spans/ledger/import
provenance comparisons, guardian4671ms. Actual compiled parsing, full parity,
checking, emission and unchanged program execution also pass in
`selfhost-oracle-reuse-parallel-v31.json`,22,738ms. Only the exact instrumented
module is reused; books and observations remain fresh and exclusively owned.
No full-bootstrap parsed AST cache is enabled.

The first broad pure-helper optimization is not accepted: v32 reaches full
validation but native codegen stalls on runtime-show emission and the external
600s command deadline fires. Direct-helper composition also regresses several
record-producing emissions/preparations from milliseconds to seconds.
Eligibility is being narrowed to live-argument structural projections, keeping
all other source functions on the existing checked CPS path. Runtime speedup
and complete native build acceptance must still be measured.

## Narrow projection lowering and Template hygiene v33

The narrowed structural-projection lowering and caller-capture hygiene pass
the complete native eight-export build in
`template-checker-native-v33.result.json`, guardian86,074ms, peak
footprint5,375,349,152 bytes. Actual type and aliased specialization both pass
in `selfhost-template-first-v33.json` and `selfhost-template-alias-v33.json`;
the existing fifteen library observations pass in
`checker-library-smoke-v33.json`. This does not establish full bootstrap.

Paired authentic-AST checker traces use the same v33 expansion and input
transport with either v31 or v33 checked native checker artifacts. Both return
CheckSuccess. `checker-projection-baseline-v31.json` records22,002,604 requests
and282,790.166ms; `checker-projection-trace-v33.json` records14,961,876 requests
and195,290.348ms:32.0% fewer requests and30.9% lower elapsed time in this pair.
Global-index lookup counts remain exactly4,871,667 in both. The removed
projection boundaries do not remove semantic lookup/checking work.

This is one instrumented pair, not a stable end-to-end benchmark. The complete
first-fixture guardian is slower than the older v31 receipt:
461,173ms versus208,937ms. The cause of the across-run slowdown remains
unestablished; no end-to-end speedup or stage1/stage2 fixedpoint is claimed.

Callback specialization then exposed two separate failures. The complete
source oracle's unchanged parser selects an implicit lambda's instance using
quantity Lone; canonical Syntax reconstruction previously left that quantity
undefined while its final semantic projection already defaulted it to Lone.
Defaulting at reconstruction preserves the same full semantic fields and
selects the existing observed instance, without expanding a template in parity.

Once full AST parity passed, the native checker rejected the substituted
unannotated callback at an application head: “term form cannot infer”.
Template specialization now substitutes `TermAnn{value, declared_type, span}`
through the remaining telescope, result and body. This retains the actual
template binder contract for bidirectional checking; it does not add lambda
inference or an unchecked callback fallback. Instance identity still hashes
the original caller-canonicalized actual values.

`template-checker-native-v34.result.json` passes the complete native build,
guardian144,727ms and peak footprint5,142,057,184 bytes.
`selfhost-template-callback-v34.json` passes actual parsing/full AST parity,
expansion, checking, emission and execution, guardian267,571ms and peak
footprint908,814,328 bytes. Stage1/stage2 remain unestablished.

The v34 specialized-type-error and runtime-template-capture scenarios pass
their required rejection phases in `selfhost-template-type-error-v34.json`
and `selfhost-template-runtime-capture-v34.json`, guardian158,353ms and
11,010ms respectively.

`selfhost-steps-native-v4.result.json` validates3905 bodies/4138 events with
zero exclusions/output patches and emits28,908,583 bytes, artifact SHA256
`10ba50624b232d2ba985174d1e94cfeba6041284d8547b203fcba82b3938a54a`.
Guardian PASS3,352,492ms, peak footprint8,444,189,344 bytes under8GiB.
This full-root build is much slower than v3. Its existing pressure-triggered
GC runs527 times and consumes1,866,617.754ms, versus16 collections and
96,315.833ms in v3. This establishes GC as a major observed build cost;
it does not establish the cause of retained pressure or permit relaxing guards.
The actual full bootstrap is running against this accepted artifact with
diagnostic parser caches disabled at every stage boundary.

Full v4/v5 runs pass all56 seed fixtures before the aggregate RSS guard stops
stage-one root parity. v5 parser-boundary markers prove the root's native
parser completes in3008ms (RSS2,884,288,512), and transport writing completes
with worker RSS3,854,352,384. The later aggregate breach is8,597,323,776 bytes;
no root parity row or stage-one artifact is accepted.

The native envelope writer now streams identical breadth-first records and
bounded JSON buffers instead of retaining a second records graph and one giant
JSON string. A throwaway smoke re-encodes the real236,650,071-byte root transport
with exactly the original SHA256
`1aff22944a2e413b872b6d5bac146f982595d22accbaf3c905fecc80b2cf976b`;
guardian PASS2959ms, RSS2,040,086,528, footprint1,742,260,072. Existing complete
transport/hash smoke also passes, including sharing, cycles, sparse arrays,
constructor aliases, malformed envelopes and40000-deep constructors.

Streaming transport alone is insufficient: full v6 again passes the56 seed
fixtures, then hits the unchanged aggregate RSS guard during root parity.
The redundant higher/lower/higher copies in deferred oracle and canonical
body reconstruction have been removed; the existing final lowering still
performs complete alpha-normalized semantic comparison. Full v7 is exercising
that change with explicit parent-oracle memory boundaries. No memory guard,
parser artifact, field coverage or stage parser provenance is relaxed.

V7/v8 retain all56 seed passes and the unchanged previously approved semantic
hashes, but still exceed aggregate physical footprint during root parity.
The oracle no longer caches normalized body graphs; each requested body is
reconstructed from the retained genuine source Body and read once per visit.
Core normal-form hashing now shares the exact JSON cursor and visits one
complete declaration at a time instead of retaining the whole normal form.

Full v9 approves the actual1099-declaration root, transport SHA256 as above,
with equal complete expected/compiled hashes
`0effb2c7aff7d0dcf6ad9741d5578027ad6837cd35a5786772fbcdcdf76d9c57`.
68 comparable previous approved rows retain their original expected hashes.
It then hits the unchanged footprint limit while decoding the larger emitted-
step source: parent high-water pages accumulate across compiler imports.

Compiler-root parse phases now use disposable Bun oracle threads; the exact
shared parity routine serves both the existing fixture parent path and the
isolated root path. The unchanged Node compiler worker and its parser inputs
remain independent; no additional compiler process is spawned. A throwaway
real-input smoke compares all hash/ledger/declaration fields with previous
approved small-fixture and full-root rows, then waits for each oracle thread
to exit. PASS9443ms, RSS3,713,859,584, footprint1,955,744,168. Full v10 is
exercising this lifetime cutover; stage-one/stage-two are not yet accepted.

V10 still reaches the native footprint ceiling while materializing the emitted-
step JSON envelope. File replay now makes two bounded record passes, sharing
the existing complete slot/record validation: allocate exact object/array
identities, then link every named field and forward/cyclic reference. Both
passes must have identical SHA256 bytes. No envelope records or complete JSON
string are retained beside the native graph. Behavioral smoke covers split
UTF-8/escaped strings, sharing, cycles, sparse arrays, scalar boundaries,
unreachable malformed records, invalid references and incomplete syntax.

Full v11 passes all56 seed fixtures and all78 full AST parity rows, including
all11 compiler-root closure files. Aggregate peaks stay within the unchanged
guards: RSS6,534,234,112 and footprint4,636,136,816 bytes. It proceeds through
real root expansion, then checking fails in the frozen lexer at1424–1447:
“unknown name .add”. The unchanged native `term_higher` gives a leading single
dot reference the Nat namespace; only leading double dots are exempt. This
core-lowering rule was missing from the canonical pre-check expansion.

The canonical expansion now applies that exact rule to references, including
closed captured values, without modifying the frozen parser/lexer or inventing
a checker global. Complete native v35 eight-export build passes in24,498ms;
the authentic previously-parsed Base+lexer closure returns CheckSuccess in
`lexer-check-v35.json`, guardian28,210ms, RSS365,232,128 and footprint334,297,376.
This is a bounded semantic regression diagnostic, not a bootstrap success.
Full v12 passes the seed fixtures and compiler-closure AST parity, then rejects
Core's existing unsafe copied callback domain. The checker now implements the
unchanged native `lhs_kind` rule: only an authentic definition's unsafe context
reduces a Many domain-kind requirement to One; ordinary definitions remain safe.

Full v13 reaches Path and rejects `finish_relative`'s original scrutinee reuse.
Native constructor splitting substitutes the pattern value for that parameter
before counting uses. The canonical checker now performs the same substitution
in branch checking and use accounting. Full v14 then reaches `dirname_parts`;
the same substitution is also required in nested recursive-order comparisons.
Full v15 proceeds beyond Path and rejects a generated Template continuation:
ordinary local bindings lose the incoming goal and attempt to infer a lambda-
containing constructor. Goal-directed local checking now preserves that goal
through the existing checked parallel substitution.

Native nine-export builds v6, v7 and v8 all pass complete validation under the
unchanged 8GiB guards. Full runs v13–v15 still fail at stage-one checking; no
stage-one artifact or fixedpoint acceptance has been established.

Native v9 passes full validation in739,484ms, peak RSS8,234,958,848 and footprint
8,125,356,536 bytes. Full v16 passes the seeds and AST parity, checks the Template
steps, then rejects an ordered fallback in JSEmit steps at103924–104062:
“constructor appears twice in match” (`Con`). The full run takes3,337,465ms,
peak RSS7,572,029,440 and footprint3,892,396,232 bytes. Native generated-source
validation accepts that fallback; the canonical ordered-pattern coverage
contract is being compared with the unchanged native lowering before editing.

The reference ordered-match contract accepts shadowed rows: native
`match_flatten` returns the first complete row, and existing
`tests/flatten/pure_tail_ineligible_before.bend` / `between.bend` exercise
wildcards before later constructor rows. The selfhost-only duplicate and
union-covered-row rejection was stricter than that contract. Covered rows now
continue to the remaining row checks; exhaustiveness remains independent.
The two mistaken rejection fixtures now execute their first-row result instead
of asserting the invented error.

Complete native eight-export v37 validation passes in19,909ms. An authenticated
v16-parsed JSEmit closure diagnostic returns CheckSuccess in
`emit-closure-check-v37b.json`; it reuses only approved diagnostic transports,
checks source/transport/component hashes, and runs native expansion/checking.
Guardian time13,967,829ms, RSS3,000,254,464 and footprint3,248,555,200 bytes.
This diagnostic proves the closure checks, not bootstrap acceptance. The first
diagnostic process exited1 without a saved result; its receipt is not success.
The throwaway diagnostic has been removed. Full v17 was subsequently cancelled
to prioritize the requested acceleration. No stage-one/stage-two fixedpoint
artifacts or successful full-bootstrap acceptance resulted from that run.

## Measured acceleration and bounded diagnostics v38–v43

Template application sites are catalogued once per generation round, including
newly generated applications on subsequent rounds. Binder groups share a single
scope-local usage-map traversal. Native-validated readonly Base-map lookup
replaces recursive AVL request dispatch; imported lookup code is checked as
part of the complete native component closure, not emitted through a bypass.

Identical authenticated Base + Path inputs, unchanged uninstrumented typed-step
runtime, complete output hashes:

| Native component | Template ms | Checker ms | Guardian ms |
| --- | ---: | ---: | ---: |
| v37 | 18,457.069 | 85,653.926 | 108,297 |
| v38 | 2,326.726 | 69,919.283 | 74,725 |
| v43 | 1,325.170 | 15,799.226 | 18,018 |

Reports: `checker-path-plain-before-v37.json`,
`checker-path-plain-after-v38.json`, `checker-path-plain-after-v43.json`.
Expanded modules SHA-256:
`4deba29de95f4b540fb787b9f2d940a9b0466312a05606367e03e00ed890c61c`.
Checked modules SHA-256:
`1ac746179e12819df799a5c5cf143d7f07b3f8b6e9e04e31dfdabc04dafd3d57`.
This is a roughly sixfold small-closure improvement, not proof that the full
compiler closure or bootstrap has acceptable latency.

`template-checker-native-v43.result.json` records full native validation with
zero excluded checks and zero output patches. The actual v43 specialization,
multi-round generation, readonly-index boundary, affine-use and imported-family
diagnostics pass; expected semantic errors remain rejected.

The large uninstrumented v43 JSEmit diagnostic expanded successfully but was
interrupted before checking returned. `checker-jsemit-plain-after-v43.json` is
partial diagnostic evidence, never acceptance. Subsequent CPU diagnostics hit
explicit outer timeouts; an absent Checker result is neither a semantic failure
nor a successful check.

Guarded commands now have a finite monotonic deadline, default 600,000 ms,
overridable by `--timeout-ms` / `HEAVY_GATE_TIMEOUT_MS`. Authenticated children
inherit the original parent deadline; expiry fails with `deadline_exceeded`,
terminates managed descendants and releases the exclusive lease only after
cleanup. Helper compilation and authentication are separately bounded.
Actual CLI smoke: a TERM-resistant Node process with a 2,000-ms deadline failed
with signal 9 after 3,108 ms, including TERM grace and cleanup. The existing
guardian suite passes 11 tests, including detached-descendant cleanup and lease
reuse after expiry.

Large diagnostic sampling uses a 240,000-ms native deadline plus a 300-second
outer Bash timeout. Intermediate diagnostic boundaries retain decoding,
execution and profiler-save state; all remain `diagnosticOnly: true` and
`bootstrapAcceptance: false`. Acceptance commands are not launched via Eval.

### Constructor ownership index v45

The retained bounded profile `checker-jsemit-profile-v43d.json` completes
Template expansion, then samples 90 seconds of checking without claiming a
completed check. More than half its typed requests traverse global lookup;
the CPU sample records about 19 seconds in garbage collection. The diagnostic
process exits normally in 178,957 ms under its explicit native deadline.

Checked constructor return types now populate an immutable declaration-only
family index. Candidate buckets retain original entry and segment order.
Unknown type shapes, noncanonical owners and cross-segment alias collisions
retain the original complete scan. Existing canonical-name resolution,
reference exclusion and deduplication still execute against the full scope.
No substitutions, match bindings or typing results are memoized.

Native v45 validates 3,090 events and 2,896 definitions with zero excluded checks
and output patches. Guardian time 30,244 ms, RSS 5,506,203,648 and footprint
4,986,360,248 bytes. The unchanged uninstrumented Path diagnostic returns
`CheckSuccess` in `checker-path-plain-after-v45.json`: Template 967.495 ms,
Checker 10,402.221 ms, guardian 12,050 ms. Both complete semantic hashes match
the v37/v38/v43 hashes above.

The large v45 CPU diagnostic still does not complete checking in its 90-second
sample. It progresses through 33,882,352 requests; lookup chains remain the
largest category. This is incomplete performance evidence, not a large-closure
speedup measurement or bootstrap acceptance.

The native builder preserves the original accepted-snapshot supervisor bytes,
Base equality and compiler/parser pins. Its live supervisor inputs are pinned
explicitly to the audited finite-deadline revision; arbitrary live drift still
fails. An initial v44 build was rejected by the old live-supervisor equality
pin before native validation; it produced no accepted component.


### Native ordered scope lookup v56

`scope_lookup.bend` owns the unchanged global metadata shapes and readonly
lookup. Ordinary lookup preserves earliest-family precedence across segments,
otherwise the first nonfamily; kind-specific lookup retains first-match order.
Unsafe scopes unwrap without rebuilding entries. Canonical names normalize
exactly once. The imported module is fully checked by the stock native compiler,
not admitted through a new pure-call lowering exception.

Constructor coverage uses a fresh per-query membership map rather than repeatedly
scanning accumulated references. Membership retains the original second
canonical-name normalization; output order and unknown-owner fallback remain.
There is no cache across queries, match states or substitutions.

`template-checker-native-v56.result.json` validates 3,059 events and 2,866
definitions, with zero excluded checks and output patches. Artifact SHA-256:
`e8678ca4b79462fa5fd85901d612a5053de8cb188d4b06e2e18df7f4777525eb`.
Guardian: 29,916 ms, deadline 240,000 ms, peak RSS 5,287,460,864 bytes and
footprint 4,937,650,496 bytes.

The actual uninstrumented Path run in `checker-path-plain-after-v56.json`
returns `ExpandSuccess` and `CheckSuccess`: Template 927.595 ms, Checker
8,867.456 ms, guardian 10,539 ms. Both complete semantic hashes match v37
above. This is roughly tenfold end-to-end improvement on Path; it does not
establish full compiler-closure latency or bootstrap fixedpoint.

The large stock-runtime attempt `checker-jsemit-plain-after-v56b.json`
finishes expansion in 22,292.043 ms, retaining the complete expanded hash
`6727f4a1d9ba10a0e759fb978db8e1489d47a0277582c138c5884a6329957d86`.
Checking does not return before the 240,000-ms native deadline. The guardian
fails with `deadline_exceeded` after 240,100 ms; there is no successful large
check or bootstrap claim.

The bounded v56 CPU sample records 6,248,556 checking requests in 90,107.872 ms,
still incomplete. Leading readonly row requests are `pattern_row_subsumes`
(582,706) and `specialize_pattern_rows` (370,988). Its saved V8 profile places
23,428.2 ms under canonical-name lookup in row specialization; GC consumes
23,632.8 ms of self time. Request totals across revisions are not comparable
throughput measurements because the native lookup cutover removes requests.

### Readonly row loops v58

Wildcard construction, row specialization and subsumption now reside in the
fully native-validated scope module. Every pattern field, wildcard span and
row order is retained. Specialization computes its tail once; subsumption
stops at the first unequal name or uncovered field. These are pure local
traversals, with no retained match state, substitution result or matrix cache.
Owned coverage and type-checking decisions still use the unchanged typed
request/LIFO interface; the pure-call admission policy is unchanged.

Native v58 validates 3,049 events and 2,856 definitions with zero excluded
checks and output patches. Artifact SHA-256:
`ff4c883f77cf69d14f41aebb0bc0ead5e402c8d8489fa360daf9e2df7e537ec5`.
Guardian: 44,115 ms, deadline 240,000 ms, RSS 5,418,631,168 and footprint
5,191,225,712 bytes.

`checker-path-plain-after-v58.json` returns both success tags and the exact
v37 complete hashes. Template 1,621.580 ms, Checker 14,015.859 ms and guardian
16,836 ms: this small-case run is slower than v56, not an acceleration claim.
Large-closure timing and semantic fixtures remain required.

### Canonical declaration aliases v59

The v58 large stock-runtime diagnostic also hits its 240,000-ms deadline;
checking is incomplete. Its bounded 90-second profile still attributes major
native row-specialization and subsumption time to repeated scope lookups.

`GlobalIndex.canonical_aliases` now records inverse names for every declaration,
not just families. It remains immutable declaration metadata, including when
constructor-owner indexing is incomplete. Alias queries filter candidates
through ordinary whole-scope lookup and deduplicate names; this preserves
shadowing, family precedence and non-idempotent normalization. Unbound names
retain the original identity fallback.

Row specialization resolves the declaration-name equivalence set once per
call, then compares raw row names. First-column subsumption uses the same
declaration relation; nested fields and remaining columns still execute their
original comparison. No pattern matrix, normalized AST, substitution or match
result is cached or retained across calls.

Native v59 validates 3,065 events and 2,872 definitions, excluding zero checks
and applying zero output patches. Artifact SHA-256:
`00357ccd6786a11c94351e70ec25b46e9b8534d84194505d6b067fc87ec21158`.
Guardian: 56,147 ms, deadline 240,000 ms, RSS 5,083,480,064 and footprint
5,012,443,312 bytes.

The Path smoke preserves both complete baseline hashes and success tags;
observed Template 2,053.184 ms, Checker 16,292.735 ms, guardian 19,533 ms.
These small-case timings do not establish a v59 speedup.

The new `same-module-alias-constructor-rows` regression passes actual parsing,
full AST parity, expansion, checking, emission and execution in
`selfhost-alias-constructor-rows-v59.json`: output `BitOne{}`, guardian 9,886 ms.
It covers both constructors through two aliases of one module and skips a
shadowed duplicate row with an otherwise-invalid body. The gate now contains
60 fixtures. This diagnostic is not compiler bootstrap acceptance.

Additional actual v59 diagnostics pass: aliased constructor conversion, complete
recursive matrices and nested ordered unions execute as `BitOne{}`; distinct
imported families, incomplete recursive matrices and duplicated affine pattern
fields reject at checking. Evidence:
`selfhost-alias-conversion-v59.json`, `selfhost-distinct-families-v59.json`,
`selfhost-matrix-complete-v59.json`, `selfhost-matrix-incomplete-v59.json`,
`selfhost-nested-union-v59.json`, `selfhost-affine-field-v59.json`.
Each retains accepted own-parser/full-AST approval and an explicit 150,000-ms
native deadline. These are diagnostic fixtures, not fixedpoint evidence.

### Demand-aware equality v60

The large v59 stock-runtime run still exceeds its 240,000-ms deadline. Its
bounded CPU sample reaches 36,301,249 requests without completing checking:
5,797,696 WHNF requests, 2,267,563 list equalities and 1,239,312 raw equalities.
This exposes work beyond the removed readonly row lookup loops; it is not a
completed throughput comparison.

Structural term and neutral-match equality now short-circuit conjunctions
through existing lazy `Bool.pick` lowering. The first false component returns
false without reducing unrelated components. All original comparison predicates,
quantities, ordered cases and 64-step conversion budgets are unchanged.
Empty readonly row queries also return before building declaration aliases.
No substitution or match-state cache is introduced.

Native v60 validates 3,089 events and 2,896 definitions with zero excluded
checks and output patches. Artifact SHA-256:
`32839f24d5ac84c03255ffe5f0eb17b5cb3b8d46a65e4e75e5a5dec33b2d86b2`.
Guardian 24,630 ms, deadline 240,000 ms, RSS 5,322,113,024 and footprint
5,203,513,712 bytes.

The actual Path smoke retains both complete baseline hashes: Template
1,251.183 ms, Checker 16,223.015 ms, guardian 18,705 ms.
`selfhost-equality-good-v60.json` and
`selfhost-alias-constructor-rows-v60.json` execute as `BitOne{}`.
`selfhost-equality-constructor-bad-v60.json` and
`selfhost-equality-type-bad-v60.json` observe the required checking failures.

The large v60 stock-runtime measurement fails with `deadline_exceeded` after
600,184 ms against its finite 600,000-ms native deadline and 660-second outer
Bash timeout. Peak RSS is 2,826,108,928 bytes; footprint 3,013,188,200 bytes.
No completed Checker result or large-input acceleration proof is available.
The next bounded CPU sample records current and last stored definition names
alongside request counters to locate the long-tail checking cost. These are
diagnostics, not bootstrap acceptance.

### Usage demand pruning v63–v64

The 240-second v60 Checker CPU sample remains inside
`emitter_body_js_ref_f32_extra`, entered at request 50,706,252; it stops at
91,714,066 requests. The preceding stored definition is
`emitter_body_js_reference_more`. This isolates a long-tail definition rather
than establishing completed throughput.

A native readonly predicate now recognizes constructor-only argument trees.
Such trees cannot contain local-variable uses. Their usage contribution is
empty regardless of field quantities; full constructor type checking is
unchanged. Every other syntax form retains the original usage traversal.
The predicate short-circuits recursively without constructing a worklist,
storing AST results or adding a substitution/match-state cache.

The v63 Path stock-runtime smoke completes: Template 941.729 ms, Checker
6,795.960 ms, guardian 8,430 ms. Both complete semantic hashes equal the
baseline. `selfhost-affine-duplicate-v63.json` still observes checking failure.

The lambda usage predicate also recognizes the existing invariant that
`quantity_fits(actual, QMany)` is true for every actual quantity. It skips only
that redundant query after body checking and promoted-domain validation.
Affine and erased lambda binders retain the original usage query.

Native v64 validates 3,093 events and 2,900 definitions, zero excluded checks
or output patches, guardian 26,297 ms against a 240,000-ms deadline.
Artifact SHA-256:
`f2e61f65bd4969cb0bda5dec52155f82ee03ec32b30ae515c680a5dbe9b0740d`.
The large stock-runtime v64 diagnostic still fails its 240,000-ms deadline
after 240,133 ms. There is still no completed large-input acceleration proof,
stage-one/stage-two fixedpoint or bootstrap acceptance.

### Causal checker diagnostics

The diagnostic profiler accepts `causal` as its final argument. Template runs
through the unchanged stock runtime; Checker keeps the exact typed request/
continuation LIFO boundary. No V8 CPU profile is collected in this mode.
It records per-definition request counts, inherited usage/termination ancestry,
sampled phase time, the active request tail and phase-entry ancestry.
Selected request arguments have weak identity counters and scalar source
locations; no AST payload is serialized or retained by the diagnostic tables.

Argument-signature and repeated-argument tables are capped at 4,096 entries.
Reports distinguish exact selected-object revisit counts from sampled argument
signatures and estimated phase time. Recursive inclusive request costs overlap
and must not be added as independent work. Snapshots are sampled at 250 ms;
the durable journal is written at one-second boundaries and definition changes.
A definition hotspot automatically stops after ten seconds, at least 100,000
requests and sixteen samples. Guardian and outer shell deadlines remain finite.
Diagnostic command exit PASS never means completed checking or acceptance.

`checker-path-causal-v66c.json` completes both phases with the two exact baseline
semantic hashes. This proves traced execution preserves the complete result;
its instrumented timing is not an acceleration measurement.
The initial large capture `checker-jsemit-causal-v66.json` stops automatically
inside `emitter_body_js_reference_3`: 1,122,999 definition requests in a
10,014.881-ms capture. Sampled time attributes 5,313.119 ms to usage and
3,952.718 ms to conversion; the active stack repeatedly checks constructor
fields. The subsequent identity trace observes repeated checks of the same
string-literal `SCon`, `Chr`, `U32`, `WCon` and Boolean syntax objects.
Its guardian deadline expires; only durable partial diagnostic data is valid.

The independent parent-thread resource journal records process CPU microseconds
and RSS once per second, even while the worker is inside a synchronous decoder,
Template run or native helper. Phase boundaries also record cumulative process
CPU. This separates wall-clock delays from computation; it does not change
guardian deadlines or schedule other processes.

The final large trace attempt does not reach Checker: decoding/setup consumes
167,683.927 ms, then Template is still running when the 300,000-ms guardian
deadline expires. No Checker hotspot data exists for that attempt.
The short resource smoke records only 2,645,390 CPU microseconds by wall
28,091.990 ms. A separate direct-thread busy-loop calibration reports
1,207.782 ms wall against 60,389 CPU microseconds; `/usr/bin/time -l` also
reports only 0.09 user and 0.01 system seconds for 2.44 real seconds.
The discrepancy is not specific to the checker or Worker CPU accounting.
The exact scheduling/throttling cause is not established. Low-power mode is
disabled; removing background policy on the calibration process succeeds
but does not remove the discrepancy. No unrelated process or machine setting
is changed. Instrumented wall times must not be presented as speed evidence.

During the resource investigation the workstation reports ten CPU cores and
load averages 65.57, 92.61 and 100.10. This establishes substantial scheduler
pressure at that observation, not a stable performance baseline. The repository
cluster requires the OpenSSH alias `cluster`; it is unresolved here, no SSH
capability hosts are configured, and the documented sibling site checkout is
absent. No cluster execution is claimed.

### Single-pass local validation v67

Causal source tracing finds an exact duplicate inference: successful
`validate_terms(values, env, globals)` is followed by `usage_local_env`, which
infers those same values again in the same environment. Local validation now
constructs its usage environment from the successful inference result.
Every parallel value still checks against the original incoming environment;
earlier local bindings never become visible to subsequent parallel values.
Length, pattern quantity, use quantity, substitution, fuel and body checking
remain unchanged. The environment is transient validation state, not a
substitution/match-state cache.

Native v67 validates 3,102 events and 2,908 definitions, zero excluded checks
or output patches, guardian 34,544 ms against a 240,000-ms deadline.
Artifact SHA-256:
`1bb754f9a4ee0d93186d5d8396dc7980bcced7b2a5bfaad8d1deb6bd14505df1`.
The stock Path smoke completes: Template 1,244.948 ms, Checker 8,298.110 ms;
both complete baseline hashes are unchanged.
`selfhost-parallel-local-v67.json` executes `parallel-local-outer-scope` as
`CSucc{CZero{}}` through the actual parser/checker/emitter boundary.

The preceding v66 constructor-only equality query returns `None` for other
syntax forms, preserving ordinary conversion instead of guessing equality.
The v66 Path causal run retains both complete baseline hashes;
`selfhost-affine-duplicate-v66b.json` and
`selfhost-indexed-mismatch-v66b.json` observe the required checking failures.
The callback specialization v66 attempt reaches emission but expires its
150,000-ms deadline before execution; it is not a passing fixture.

### WHNF candidate and bounded build failures v68–v69

The v67 JSEmit causal capture stops in `emitter_body_js_native_u32_1`.
Its last sampled definition window has 569,661 requests: 498,076 conversion
requests and 81,157 body-checking requests. Conversion accounts for 8,306.826 ms
of the sampled 9,871.030-ms window; these are sampled wall-time estimates,
not independently measured CPU times. The capture is diagnostic, not a
completed large-module checking result.

The candidate skips only definitely different first-column constructor names
before ordinary WHNF pattern checking. It retains the original case tail and
stops at a possible constructor match or non-constructor pattern. Fuel,
ordered nested-pattern checking and stuck handling remain unchanged.
The new alias-dependent and stuck-first-row conversion fixtures pass against
v67 as behavioral baselines; candidate runtime verification is still pending.

The combined v68 preparation/build command expires its 600-second outer
deadline without an accepted artifact. Native validation itself passes all
3,106 events in 37,327.152 ms; the last recorded phase is code generation.
The isolated v69 build also produces no accepted artifact: its guardian
reports `FAIL/deadline_exceeded` after 240,223 ms, with a 240,000-ms deadline.
Native validation passes all 3,106 events in 34,017.232 ms (8,690.675 ms CPU).
The last progress record is `prepare-before` at definition 2,108 of 2,138,
not the v68 last recorded emission location. Thus neither receipt proves a
single-function hang, nor does either prove candidate acceleration.

The prepared-input v70 build completes in 68,838 ms under its 360,000-ms
guardian deadline, validating 3,106 events and 2,912 definitions with zero
excluded checks or output patches. Artifact SHA-256:
`9bb3a7ba536bc98b0ddb3aaaf27e289a3a4ce5fb9e1cd84030aabe732e1d63a6`.
This large wall-time variation prevents treating the previous build failures
as proof of a deterministic compiler hang.

The stock v70 Path run completes in 14,950 ms guardian time:
Template 2,834.441 ms, Checker 11,074.252 ms. Both complete semantic-module
hashes match the v37/v67 baselines exactly. The actual bootstrap fixture
boundary passes `alias-dependent-conversion` (3,292 ms guardian) and
`stuck-first-row-dependent-conversion` (2,425 ms guardian), preserving the
expected accepted conversion and expected rejected stuck conversion.
These smokes validate the candidate's exercised behavior, not a completed
large-module speedup or bootstrap fixedpoint.

The v70 causal diagnostic runs for 226,018 ms guardian time and stops at its
150-second Checker sampling budget, not at successful checking completion.
It reaches `emitter_body_js_ref_f32_extra`, after storing
`emitter_body_js_reference_more`; the earlier native-u32 definition is passed.
The final sampled definition window attributes 1,638,363 requests and
7,568.236 ms to usage, versus 39,786 requests and 250.119 ms to conversion.
Its ancestry is `binder_usage_map -> term_usage_map -> usage_local_env ->
infer -> infer_term_annotation_result -> check_term`, identifying repeated
local-value validation inside usage analysis as the next measured cost.
No annotation validation or inference-failure behavior has been bypassed.
The completed Template hash remains the full baseline JSEmit expanded hash.
This diagnostic does not establish a full checked-module hash or speed ratio.

### Post-validation closed annotation reuse v71

The stock v70 large-module run fails its 600,000-ms guardian deadline after
600,174 ms without a completed Checker result or checked-module hash.

Usage analysis now threads an explicit validation flag through its typed
requests. Only successful definition-body inference enables it; local and
pattern pre-checks, and general usage-count queries, pass `False`.
For an annotated constructor-only value with a nominal `TermRef` annotation,
post-validation usage inference rechecks the annotation with the exact
original `check_term(..., Type(QOne))` call and reuses the fact that the closed
value has already checked. Both the value and annotation are independent of
approximated local usage environments. All other forms keep ordinary inference
and its unknown-type fallback. Parallel values still use the incoming scope.
There is no retained substitution, pattern state or inferred-value cache.

Native v71 completes in 35,956 ms, validates 3,111 events and 2,917 definitions,
and excludes no checks or output patches. Artifact SHA-256:
`7090958a3e98b829bf4999d70a8210aa585f3f09b3cbee758703c882f84d6171`.
The stock Path smoke completes in 11,863 ms guardian time
(Template 1,125.616 ms, Checker 9,622.775 ms), with both complete semantic
hashes equal to the original baseline.

The real parser/checker/emitter fixture boundary preserves the accepted
`closed-local-annotation-usage` output `BitOne{}` before and after the fix,
and preserves checking rejection of `closed-local-annotation-type-error`.
The final receipts are the four `selfhost-closed-local-*-v71c.json` files.
Earlier fixture attempts used unannotated strings or parentheses instead of
the guide's `{value : Type}` annotation syntax and failed on v70; they are
not passing baselines. The permanent fixtures use explicit curly annotations.
These behavior smokes are not yet a completed large-module speed comparison.

The stock v71 large-module run also expires at 600,169 ms. Its last resource
sample records 535,645,759 us user CPU and 12,078,691 us system CPU over
599,016 ms wall time. This run received about 91% of one core; its failure
cannot be attributed to the earlier observed near-zero CPU allocation.

The corrected bounded shape diagnostic v71c observes actual String annotations
in both pre-validation (`False`) and post-validation (`True`) queries.
It stops after a sampled 91,636-ms Checker window, with 8,980,897 requests.
The final definition is `emitter_body_js_native_f32_2`: sampled conversion
8,012.964 ms versus usage 298.563 ms. Periodic stacks show constructor-field
result fitting repeatedly normalizing its target through application, match
and family-quantity lowering. The first v71b shape diagnostic failed by
serializing an environment slot with BigInts; corrected request-field mapping
uses the generated `usage_value_type.v_6` Bool, and stores only bounded shapes.

### Constructor goal view reuse v72

Constructor checking already obtains `whnf(64, expected, globals)` to establish
that its goal is a datatype. It now threads that immutable result through
field checking and reuses it at final constructor-result conversion.
The raw equality gate remains first; source normalization still uses fuel 64,
and inferred results retain the original expected type. Scope, field checks,
substitutions and quantity rules are unchanged. This is one operation's
already-computed result, not a keyed normalization/substitution/match cache.

Native v72 validates 3,113 events and 2,919 definitions, with no excluded checks
or output patches, in 41,016 ms guardian time. Artifact SHA-256:
`2ef0d8d86ef5c4d6a8968a4773890785f4b452201671da3fcc8eaa7c1065b47f`.
The stock Path run completes in 11,403 ms guardian time
(Template 1,659.082 ms; Checker 8,640.660 ms), retaining both complete baseline
semantic hashes. Actual fixture runs pass the expected indexed-parameter
rejection, affine-field rejection, copied-field execution and dependent-goal
execution, with receipts `selfhost-{indexed-mismatch,affine-field,copied-field,
dependent-goal}-v72.json`. No large-module completion is inferred from these.

### Stock timeout and bounded request counters v72

The stock large-module receipt `checker-jsemit-plain-after-v72.json` ends in
guardian timeout at 1,800,408 ms, without a Checker result or checked-module
hash. Its Template phase completes in 29,820.519 ms with the unchanged expanded
module hash. The final resource sample records 400,376,169 us user CPU plus
18,946,683 us system CPU over 1,799,271 ms wall time: about 23% of one core.
This timeout is not a measured completed checking duration.

The diagnostic helper now has a bounded `counter` mode: the original typed
request/LIFO execution, scalar request counts and definition progress, without
inspector sampling or causal argument/revisit tracking. It preserves complete
semantic hashing on completion, finite deadlines and the existing memory cap.
Counter timings are instrumented diagnostics, not stock acceptance timings.

`checker-path-counter-v72.json` completes with both full baseline semantic
hashes and 1,969,848 Checker requests. Checker wall time is 90,013.102 ms;
the final resource sample is only 16.834 CPU seconds over 112.670 wall seconds.
Its wall-time ratio to the stock Path run does not isolate instrumentation cost.

The 300-second large counter window records 64,897,539 requests and reaches
`emitter_body_js_ref_f32_2`, but does not complete checking. The longer
`checker-jsemit-counter-v72b.json` records 265,887,245 requests in
900,001.790 ms and reaches `emitter_body_js_runtime_type_patterns`; the last
stored definition is `emitter_body_js_runtime_type_names`. It likewise has no
complete Checker result or checked-module hash. Guardian PASS here means a
bounded diagnostic exited normally, not that full checking passed.

The longer counter's worker-exit sample records 897,075,849 us user CPU plus
18,085,388 us system CPU over 960,591.541 ms wall time: about 95% of one core.
Together with the v71 stock sample, this confirms substantial checker work
even when CPU is available; contention alone does not explain the total cost.
The historical completed large baseline `emit-closure-check-v37b.json`
records `CheckSuccess` in 13,940,600.283 ms, but stores no checked-module hash.
A new large completion must not be described as hash-equal to that receipt.

### Completed stock large checking v72b

After the observed recovery in CPU allocation, the bounded stock run
`checker-jsemit-plain-after-v72b.json` completes. Its guardian records
975,874 ms total wall time, deadline 1,800,000 ms, peak RSS 3,295,838,208 bytes
and peak physical footprint 3,593,603,704 bytes, below the unchanged 8-GiB cap.
It uses `plain` mode without request counters or inspector instrumentation.

Template completes in 20,750.867 ms with `ExpandSuccess` and full semantic hash
`6727f4a1d9ba10a0e759fb978db8e1489d47a0277582c138c5884a6329957d86`.
Checker completes in 917,623.495 ms with `CheckSuccess` and full semantic hash
`f68db11979f99ae676da09698de104bf36839eef911d6de5cbb49ad60dc93476`.
Both phases explicitly record completed execution. This is approximately
15.2 times less checker wall time than the historical 13,940,600-ms completed
v37b diagnostic; different CPU allocation prevents attributing the whole
ratio to source changes. The old receipt has no checked-module hash to compare.
The complete Path hashes and exercised semantic regressions remain the
before/after behavior evidence; the new large checked hash is now recorded.

This receipt still sets `diagnosticOnly: true` and `bootstrapAcceptance: false`.
It reuses authenticated parsed native inputs. It is not fresh parsing,
stage1/stage2 production, or fixedpoint acceptance.

The completed stock worker records 979,911,588 us user CPU plus 17,861,027 us
system CPU over 975,767.490 ms wall time, approximately one full core overall.
The result is therefore a completed measurement under recovered CPU
availability, not a reinterpretation of the earlier 30-minute timeout.

### Complete nine-export native build v72

`selfhost-steps-native-v72.result.json` records complete validation of
4,224 events and 3,988 definitions, zero excluded checks and zero output patches.
It exports the full nine-entry parser/Template/Checker/JSEmit ABI and validates
the unchanged root SHA-256
`0ada35959c5a4542096e0becd64230995807779899e3285c48fdddbfb712ee8d`.
Artifact `selfhost-steps-v72.js` has SHA-256
`bbf892553b9127cddcec7e93cd30efc1ba8d5b8180ff40f88f2eb23c4eb39223`.
Guardian PASS records 104,773 ms, deadline 900,000 ms, peak RSS
8,061,976,576 bytes and peak physical footprint 8,167,856,560 bytes, both below
the unchanged 8-GiB cap. This native proof establishes generation, not stage
execution or fixedpoint. The initial invocation rejected overlapping artifact
and report-prefix paths before building; the accepted invocation separates them.

### Fresh full acceptance v72 and measured emission bottleneck

`selfhost-bootstrap-v72.json` runs through Bash with guardian deadline
3,300,000 ms and outer timeout 3,600 seconds, without diagnostic parse reuse.
All 64 seed fixtures pass, including the closed-annotation regressions.
All 97 complete parser/oracle parity rows pass: 84 fixture rows and all
13 stage-one compiler-root source files. Expansion starts at 332,841.939 ms,
stage-one checking starts at 376,207.424 ms, and the subsequent stage-one
emission starts at 1,818,453.842 ms. Whole-stage-one checking therefore
finishes in approximately 1,442,246 ms; the remaining 1,481,561-ms emission
window ends at the guardian deadline. The final verdict is FAIL,
`deadline_exceeded`, at 3,300,015 ms, with no stage artifacts or fixedpoint.

A diagnostic-only emitter mode runs original stock Template and Checker first,
then counts typed library-emitter requests over their complete checked output.
It does not reuse checked ASTs, skip checking, project inputs, or patch output.
`emitter-path-counter-v72.json` completes actual library emission in
39,579.040 ms with 41,132,139 requests. Its Template and Checker hashes retain
both complete Path baselines. Emitted source is 325,161 bytes, SHA-256
`dfde577896e6d15f0c793639ab1a4134e7aed30441f914781ec5e2c263e84835`.
The guardian completes at 47,921 ms below the unchanged resource caps.

Counts attribute 9,880,848 requests to `js_global_decls`,
8,338,770 each to `qualify` and `qualify_result`, and 7,775,152 to
`js_global_decl_match`: about 83% of all requests are repeated declaration
scanning and name qualification. This is the observed reason for targeting
an immutable original-declaration catalog, not a computed-type or match cache.

### Immutable emitter definition owners v73

The emitter now builds one original-definition name index per module, once per
emission. Tail-first insertion followed by head overwrite retains the first
definition, including foreign definitions that block later same-module values.
Lookup still visits modules in their original order, retains scoped-name then
raw-name fallback, and constructs dependent closures in the owner's environment.
The shared catalog is threaded through all emitter scope creation. No computed
type, reduction, substitution or match state is cached. Constructor and type
lookup rules, emitted runtime source and generator pure-call policy are unchanged.
The obsolete linear value-declaration scanner is removed.

Full native v73 validates 4,229 events and 3,992 definitions, with zero excluded
checks or output patches, exporting the unchanged complete nine-entry ABI.
Artifact SHA-256:
`e895abfab57c2308d18fe9905a30a1e76a40017e27b865ac9328b6dab53e9e8e`.
Guardian PASS records 850,886 ms at the 900,000-ms deadline; peak RSS
8,321,712,128 bytes and footprint 8,411,962,016 bytes remain below 8 GiB.
This slower build duration is observed, not silently replaced by the earlier
104,773-ms build timing.

The same bounded Path library-emitter diagnostic now completes in
12,334.071 ms with 7,972,867 requests: 3.2 times less wall time and 5.2 times
fewer typed requests than v72. Its complete expanded and checked Path hashes
remain identical to the baselines. All 325,161 emitted bytes retain SHA-256
`dfde577896e6d15f0c793639ab1a4134e7aed30441f914781ec5e2c263e84835`.
This is completed diagnostic emission, not yet a full-root emission speed
measurement or stage1/stage2 fixedpoint.

Actual v73 parser/oracle/Template/Checker/emitter/execution diagnostics also pass
same-module aliased constructor rows (2,018 ms), callback specialization
(19,868 ms), closed nominal local annotation use (2,121 ms), and parallel-local
outer-scope use (2,173 ms). Their receipts are `selfhost-{module-alias,callback,
closed-annotation,parallel-scope}-v73.json`. These exercise emitted program
behavior in addition to the complete byte fingerprint comparison.

### Fresh v73 acceptance RSS boundary

`selfhost-bootstrap-v73.json` passes all 64 seed scenarios and records 96
complete semantic parity approvals before stopping during the final compiler
source's oracle normalization, `js_emit_steps_v1.bend`. The last accepted
compiler-source row is `scope_lookup.bend`. There are no stage artifacts.
Guardian verdict is RESOURCE_LIMIT, `rss_limit`, at 219,154 ms, with peak RSS
8,593,244,160 bytes above the unchanged 8,589,934,592-byte cap; footprint is
5,025,126,496 bytes. The 55-minute deadline is not reached.

The native parser's last transport-complete boundary reports Node RSS
3,124,445,184 bytes. The oracle's transport-decoded boundary reports host/oracle
RSS 3,788,357,632 bytes before the limit is crossed. The loader retains complete
native modules while the parent performs complete oracle approval; isolated
oracle Workers have separate heaps but share their host's process RSS.
No parsing, oracle field coverage, memory cap or acceptance verdict is weakened
to hide this failure. The completed small-emitter speed/equivalence proof does
not establish full-root memory safety or a fixedpoint.

### Fresh compiler-root memory diagnostic v74

`selfhost-root-memory-v74.json` exercises the new `--parse-only=true` diagnostic
through the ordinary guarded bootstrap loader. It freshly runs the accepted
native parser on all 13 compiler-root sources, receives 13 complete semantic
oracle approvals, and restores all 13 complete current-run native AST
transports. No persistent parse cache is enabled. SHA256 receipts authenticate
restoration; source bytes are checked again before restoring each module.

The loader parks the full native graph before waiting for the oracle, retaining
only import-loader information and transport receipts during approvals.
Phase compilation consumes its loaded-module holder and releases previous
input/expanded/checked references after their consuming call. Positive
`selfhost-memory-annotation-v74.json` and negative
`selfhost-memory-neutral-v74.json` exercise that consuming pipeline.

Hash-only semantic normalization no longer allocates unused span-ledger entries
or their recursive path strings. Full payload normalization retains its spans;
the canonical semantic hash and field coverage are unchanged.

Guardian PASS: 128,601 ms, RSS 6,455,656,448 bytes, physical footprint
2,651,974,704 bytes, deadline 600,000 ms, unchanged 8-GiB cap. This diagnostic
skips seed fixture execution and does not check or emit the compiler root.
It is not a controlled memory comparison against the previous full bootstrap,
and does not establish stage artifacts or a fixedpoint. Its report deliberately
keeps `passed:false`, `bootstrapAcceptance:false`, and
`compilerBootstrapGreen:false`.

The full-root diagnostic profiler can take an explicit fresh parsing receipt
as its eighth positional argument; every reused diagnostic source and transport
still undergoes the existing exact byte/hash/full-parity authentication.
Isolated oracle workers have their own 300,000-ms timeout as well as the
outer guardian deadline. Fixture execution has a 120,000-ms subprocess timeout.

### Constructor/name acceleration v78 and manual-GC removal v79

The v78 full native compiler build passes in 382,259 ms with aggregate RSS
8,252,555,264 bytes and footprint 8,136,825,336 bytes, under the unchanged
8-GiB cap and 900,000-ms deadline. This build still used the previous manual-GC
policy; it is not evidence that the full native build fits without manual GC.

Constructor lookup now indexes original family/constructor owners per module,
preserving module and declaration order, scoped/raw fallback and fresh owner
environments. Name membership and exact/dot/slash matching use the existing
generator's lazy Bool.pick lowering, without changing its pure-call policy.

`emitter-path-counter-v78.json` completes expansion, checking and library
emission. Emitter requests fall from v73's 7,972,867 to 5,155,113; emitted
source remains all 325,161 bytes with SHA256
`dfde577896e6d15f0c793639ab1a4134e7aed30441f914781ec5e2c263e84835`.
Full expanded/checked hashes remain the established Path baseline hashes.
Measured emitter wall time is 16,278.800 ms; request reduction is not a claim
of equal wall-time improvement under varying CPU allocation.

A fused checker rebasing/refinement experiment was removed after a paired
Path measurement increased checker CPU cost. No fused walker or cache remains.
The retained Core.shift change returns the unchanged immutable term for zero
shift; nonzero shifting retains the existing traversal.

At the user's request, explicit GC calls and the collection-policy machinery
are removed from active bootstrap, isolated parity, native component builds,
parser rebuilds and the validation diagnostic. Runtime automatic GC remains;
aggregate memory limits, deadlines, complete checks and exact transports do
not change. Old diagnostic reports retain their historical GC measurements.

`selfhost-no-manual-gc-alias-v79.json` exercises same-module alias constructor
rows through fresh parsing/parity, expansion, checking, emission and actual
execution: PASS 2,281 ms, RSS 895,107,072 bytes. The negative neutral-family
scenario in `selfhost-no-manual-gc-neutral-v79.json` passes its expected check
rejection: 2,250 ms, RSS 872,464,384 bytes. Both use 120,000-ms deadlines.
These small scenarios do not establish full-root memory safety without manual
GC, stage artifacts or a byte fixedpoint.

### Complete transport arena and direct flat decoding v83–v84

The isolated semantic oracle now reads the complete current-run transport into
typed-array columns: original record IDs, field offsets, field-key IDs, value
kinds and scalar/reference payloads. Field keys and scalar strings, including
names, share an interned dictionary. Both stream passes validate every record
and reference and must agree on the complete transport SHA256.

Normalization consumes one original declaration at a time. Native Con/Nil
argument and telescope lists decode directly into semantic vectors, without
first allocating the corresponding native object graph. Original declaration
order, duplicate-name/law completion behavior, binder rules and complete
canonical hashes are unchanged. The final canonical book is still retained
where its semantics require it; this is not a computed-term/type cache.

Each source's arena belongs to its isolated oracle worker, which terminates
after approval. The compiler receives the complete original transport restored
to the existing native AST ABI only after approval. Earlier phase inputs are
released after their consumer finishes. No persistent parse reuse or host AST
compiler input is introduced.

`selfhost-root-arena-v83.json` passed all 13 fresh root-source semantic approvals
and native restores without manual GC: 111,881 ms, RSS 5,029,117,952 bytes,
footprint 3,482,777,328 bytes. The direct flat-decoding version in
`selfhost-root-flat-arena-v84.json` also passes all 13 approvals and restores:
106,461 ms, RSS 5,544,919,040 bytes, footprint 2,723,655,352 bytes. Both have
600,000-ms deadlines and the unchanged aggregate 8-GiB cap. These single-run
observations are not a controlled speedup claim; direct decoding's observed
RSS is higher even though its footprint is lower.

Real alias-constructor execution and law completion passed in the v83 arena
fixtures. The v84 neutral-family fixture passes its expected check rejection.
Root diagnostics explicitly report `passed:false`, `diagnosticOnly:true` and
`bootstrapAcceptance:false`: they do not prove stage artifacts or fixedpoint.

The fresh automatic-GC native build in
`selfhost-steps-native-v79.result.json` passes full native validation but is
stopped during code generation at the physical-footprint limit: 13,803 ms,
8,602,737,312 bytes. Command-local engine tuning attempts v80/v81 also exceed
the unchanged RSS limit. No manual GC was reinstated and no memory cap was
raised. The accepted v78 seed remains a historical build with manual GC;
the new oracle arena does not change native compiler code-generation storage.

This verified arena/flat-vector/name-ID cutover is confined to transport and
parity, not the compiler runtime. Further interface investigation established
that a private Core/Checker arena can preserve the parser/root ABI using existing
Base.Array operations and normal regeneration by the unchanged step generator.
No runtime-wide arena or native resolver name-ID migration is proved here yet.
Changing the generator algorithm to replace closure continuations remains
forbidden; user permission alone does not override that restriction.

### Portable native Node/V8 build host v86

`checker_core_component_build.ts` now executes the same authenticated replay
kernel and accepted streaming JS compiler in a real Node worker. Full native
book validation, retained checked bodies, source pins, prepare/emit/release
semantics and exact output provenance remain unchanged. The host uses ordinary
fs APIs and no Bun-only FFI phase sampler. The existing external native guardian
still samples the complete process tree's RSS/footprint every 10 ms.

The worker has a 5,120-MiB old-generation limit and a 256-MiB stack; the observed
V8 heap-size limit is 5,419,040,768 bytes, not a hard RSS quota. The external
8,589,934,592-byte RSS/footprint limits remain authoritative. Worker snapshots
record RSS/heap only; per-phase physical-footprint peaks are explicitly no
longer sampled. Guardian deadlines still cover the worker and its descendants.

`native-node-arithmetic-v86-build.result.json` records complete native validation
of all 456 book events, zero excluded checks/output patches, and native JS
generation: PASS 524 ms, RSS 205,357,056 bytes, footprint 164,851,640 bytes,
120,000-ms deadline. The emitted 3,499-byte library SHA256 is
`ba821dbe0f98ee4b05e92566c6337eca18102d7e588ac84b1f272e119ffbe2d1`.
Actual Node execution of its `main.out` export returns exactly `6n`, matching
the existing total-division-by-zero fixture. This proves the real host path;
it does not yet prove full compiler-root code-generation memory or fixedpoint.

The pre-private-arena v85 full acceptance was deliberately cancelled after
interface investigation established that a compatible internal arena migration
was possible. Cancellation is not a passed acceptance or a deadline failure.
The complete final proof must use the resulting private checker implementation.

### Native private storage boundaries v92–v93

`checker_arena.bend` supplies concrete growable `Array` pools, complete boxed
descriptors, U32 handles/name interning, flat word/Nat tapes and reference-clearing
rewind. These are ordinary boxed descriptor arrays, not typed-array SoA storage.
Recursive pack/decode adapters belong to the checker-local source lowered by the
unchanged step generator; imported storage primitives use native-supported
decreasing-first self-recursion and binder-order parameter matches.

The temporary native storage scenario exercised a real pool capacity change from
one to two, retained the old node, and stored a second node with index
`4294967296n`. `arena-storage-native-v92-build.result.json` records complete native
validation of 601 events and 442 definitions, zero excluded checks/output patches:
PASS 666 ms, peak RSS 227,803,136 bytes, footprint 188,593,592 bytes, 120,000-ms
deadline. The emitted library has 24,694 bytes and SHA256
`d6b41761ce0af3d67eff8f604fef78b713cdf4aa19d0f6764057dcf2fa5a78bb`.

Actual generated-library execution passed assertions for both exact nodes,
the large Nat index, original spans and the interned name ID. Its guardian used
a 10,000-ms deadline, 10-ms sampling and 8,589,934,592-byte aggregate RSS/footprint
limits: PASS 52 ms, peak RSS 46,366,720 bytes, footprint 13,747,832 bytes.
The separate `arena-rewind-native-v93-build.result.json` scenario fully validates
604 events and 445 definitions, with zero excluded checks/output patches:
PASS 796 ms, peak RSS 228,868,096 bytes, footprint 187,413,944 bytes.
Its 43,770-byte emitted library SHA256 is
`086d9e02568422883afc870085ef620ea6c1f286075203bb64ee15a7065d692b`.
Actual execution asserts that rewind retains the pre-mark node/name, clears
the appended node/name array slots and removes the appended name from the map:
PASS 67 ms, peak RSS 45,072,384 bytes, footprint 12,977,736 bytes, under the same
10-second/8-GiB/10-ms execution limits. Both temporary smoke sources are removed.

These prove native storage growth and rollback boundaries only, not recursive
packing, per-definition checker lifetimes, complete checker semantics, speedup
or bootstrap fixedpoint.

Owned-source generation accepts 722 definitions after source-only removal of
84 semantic-free terminal joins at all 161 caller sites. Generic local List/Maybe
results now carry closed source goals where required by the unchanged generator.
Typed-step generation is under finite 300-second/8-GiB/10-ms guardian limits;
complete checker semantics, runtime measurements and full stage acceptance
remain pending. Fewer source requests are not yet a measured speedup.

### Full native validation and bounded codegen heap failures v96–v97

After source-only typed continuations for 69 imported pair destructures and
removal of five proved-unreachable partial-match branches, unchanged generation
accepts 786 checker definitions and emits 4,537 total checker bodies/helpers.
The v96 generation took 186,444 ms, peak RSS 1,155,235,840 bytes and footprint
1,087,817,072 bytes, under the 900-second/8-GiB/10-ms guardian.

The complete compiler root now passes native book validation. In v97 all 7,753
book events passed in 13,697.488 ms wall / 18,555.501 ms CPU, retaining 7,483 checked
outputs with manual GC disabled. This is native type validation, not a completed
native JS artifact, executed checker semantics or bootstrap acceptance.

Code generation exhausts the bounded V8 heap with either host setting:

| Run | Old-generation limit | Guarded elapsed | Peak RSS bytes | Peak footprint bytes |
| --- | --- | --- | --- | --- |
| v96 | 5 GiB | 70,814 ms | 5,590,859,776 | 5,973,462,552 |
| v97 | 6 GiB | 47,021 ms | 6,706,266,112 | 7,141,541,768 |

Neither run exceeded the unchanged 8,589,934,592-byte physical/RSS cap or created
a component artifact. At v97's last event, 435 definitions were prepared but only
14 emitted/released: 421 live raised outputs, 7,048 checked outputs, and 104,417
memoized telescopes. The accepted compiler eagerly prepares callees during a
current definition's traversal; its release callback runs after that definition
finishes. Existing host APIs do not provide an earlier release for those outputs
or the retained telescope/signature memo tables.

The source-only nominal-product experiment replaced private
`Pair(ArenaStore, result)` signatures. The Base pair alias expands to dependent
`Sigma` with a type lambda; the experiment targeted its repeated expansion.
Both fields and their affine quantities were retained, with parser/root ASTs,
fuel and generator algorithms unchanged. The real v99 build below did not
confirm the hypothesized reduction in peak code-generation memory.

### Nominal state/result product: bounded native build v99

The private nominal product is implemented; parser/root entry/exit ASTs and
generator algorithms remain unchanged. Regeneration passed in 135,220 ms.
The real full native book passed all 7,754 validation events in 9,365.271334 ms
(15,102.909 ms CPU), with no manual GC.

JS generation still exhausted the 6,144-MiB Node worker heap. The external
guardian recorded 27,843 ms, 6,776,553,472 bytes peak process-tree RSS and
7,138,657,248 bytes peak physical footprint, below the unchanged 8-GiB cap.
The final prepare event again retained 421 higher bodies after 435 preparations
and only 14 releases, with 104,418 telescope and 434 signature memo entries.
The nominal product did **not** remove the measured code-generation bottleneck;
this run produced no compiler artifact and proves no bootstrap speedup or
stage-one/stage-two fixedpoint.

An earlier v98 attempt stopped before heavy work because accepted snapshot
files were missing from `/tmp`. Before v99, all six pinned snapshot inputs were
restored byte-identically against the v97 SHA-256 records. Accepted kernel and
compiler bytes, active guardian limits and finite deadlines were not changed.

### Bounded live allocation sampling v100; ordinary build smoke v101

`checker_core_component_build.ts --allocation-profile-mib=4608` starts Node
allocation sampling after complete native validation, at a 524,288-byte interval.
An existing accepted compiler observation callback stops emission at the heap
cutoff; no compiler source or algorithm changes. The worker records
`ALLOCATION_PROFILE_ONLY`, never a generated-compiler or acceptance result.
No manual GC or full heap snapshot is requested.

The real compiler-root diagnostic passed the external guardian in 17,061 ms,
with 5,131,862,016 bytes peak RSS and 5,433,925,032 bytes peak physical footprint.
Its deadline was 120,000 ms; both memory caps remained 8,589,934,592 bytes with
10-ms sampling. Full native validation precedes the diagnostic cutoff.
`selfhost-allocation-v100.allocation-profile.json` records 247 preparations,
14 releases, 233 retained higher bodies, 31,656 telescope memo entries and
247 signature memo entries. No compiler artifact was published.

The profile accounts for 380,074,624 sampled live allocation bytes made during
codegen. It excludes allocations made before sampling; it does not measure
exact heap-owner sizes or identify a retaining path by itself.

| Allocation site | Sampled live bytes |
| --- | ---: |
| `lay_fields` | 158,349,304 |
| `lay_pack` | 128,479,104 |
| Constructor-arm callback inside `lay_of` | 64,496,760 |
| All remaining sites | 28,749,456 |

The three layout sites account for approximately 92.4% of sampled live bytes.
The largest sampled stack reaches them through `sig_def`; accepted compiler
source retains `lays` and `ret` inside `SIGS`. `lay_of` recursively constructs
non-cyclic ADT layouts; `Array` is instead a boxed layout. The generated
`CheckerProgress` embeds the large `CheckerRequest` sum, while each private
`ArenaStore` embeds two multi-field arenas. These are source-level candidates
for reducing repeated layout expansion, not proven memory fixes.
The earlier hypothesis that telescope entries or higher bodies alone dominate
allocation is not supported by this codegen-only profile. Direct compiler
layout reuse would require changing protected compiler implementation; it was
not attempted.

The ordinary, non-profiling build was also exercised on
`tests/base/u32_divmod_zero.bend`: compilation passed in 470 ms and the emitted
`main.out` thunk returned `6n` under a separate 10-second guardian. Its JS SHA-256
remained `ba821dbe0f98ee4b05e92566c6337eca18102d7e588ac84b1f272e119ffbe2d1`,
identical to v86. The first execution assertion incorrectly compared the thunk
itself with `6n`; invoking the actual exported thunk corrected the smoke script.

### Flat arena metadata: native boundary proof v104 and root diagnostics v105–v106

`Arena` now holds its six data arrays directly, with one U32 array for used
counts/capacities and one Nat array for allocation depths. Pool order is nodes,
patterns, binders, words, naturals, names. Used/capacity slots are `2*p` / `2*p+1`;
depth slot is `p`. Public arena APIs and original AST descriptors are unchanged.
Local pool records remain only where the existing growth algorithm needs them.
Seventeen obsolete pool getter/rewind/set definitions were removed.

The native v104 boundary artifact passed all 701 book events and 540 checked
definitions, then compiled in 805 ms. Its 115,312-byte JS SHA-256 is
`3ad72d390ecbd5a12b5942d93dcc90c30d87bc6d6c89455292eb2e6064f9b370`.
Actual emitted execution passed 17 assertions in 68 ms under a 10-second
guardian: all six pools grow through capacities 1→2→4, independently retain
counts/depths, preserve large Nat values/spans/quantities, rewind to a retained
prefix, retain grown capacity/depth for reuse, clear removed slots, and remove
only appended names from the intern map. Evidence is
`arena-metadata-native-v104-execution.json`. The throwaway fixture and execution
script were removed after proof. An initial fixture used an unsupported Nat
literal above 32 bits; constructing that same arbitrary Nat by addition fixed
the fixture without changing parser policy.

Unchanged checker regeneration passed: 786 source definitions, 3,346 source
calls, 3,063 pending sites and 4,537 total bodies/helpers. Owned extraction took
1,985 ms; step lowering took 140,855 ms. No generator architecture changed.

At the same 4,608-MiB diagnostic cutoff, v105 reached 294 preparations/14
releases versus v100's 247/14. This is a different stopping point, not a
same-work speedup comparison. Full native root v106 then passed every one of
7,774 book events in 9,347.638542 ms, with automatic GC only.

| Full-root codegen outcome | v99 nominal state | v106 flat metadata |
| --- | ---: | ---: |
| Worker old-generation limit, MiB | 6,144 | 6,144 |
| Guardian elapsed time, ms | 27,843 | 27,083 |
| Peak process-tree RSS, bytes | 6,776,553,472 | 6,771,359,744 |
| Peak physical footprint, bytes | 7,138,657,248 | 7,095,842,088 |
| Preparations before heap failure | 435 | 782 |
| Completed releases | 14 | 14 |
| Retained higher bodies at last event | 421 | 768 |

The flat representation gets substantially farther before the same heap limit
but still produces no full compiler artifact. It proves neither complete
bootstrap nor stage-one/stage-two byte fixedpoint. Root emission remains
blocked; the accepted compiler and 8-GiB external caps were not changed.

The `/tmp` accepted snapshot again disappeared before the v102 smoke could
start. The native builder now reads `~/.cache/bend/accepted-native-d746e7cc`.
All six snapshot files were restored against v100's original SHA-256 pins.
The accepted compiler/kernel/Base bytes and both current and legacy guardian
pins remain unchanged; only the host snapshot location changed. The successful
v104–v106 native runs exercised that persistent-cache path.


### Canonical shared layouts, streamed checked outputs and complete roots

The active builder now executes canonical `bend2/comp.ts`/`bend.ts`, not the
historical cached compiler. Layouts are immutable book-local graphs with
conservative semantic instantiation keys; unknown/open binders retain identity.
Field offsets are assigned once. Signature arity is independent of demand-driven
C layouts; saturated signatures do not inspect bodies. Reachability uses a
deduplicated insertion-ordered queue. JS analyses/emits/releases one checked body
at a time, clearing transient telescope caches at definition boundaries.

`shared-layout-backends-v110.json` records 14 actual JS/C executions, including
dependent array borrowing, erasure, nested records, sharing and the permanent
`signature_promoted_arms.bend` regression (common erased binders and an eta-short
arm). The new arena checker exposed an open-law tape escaping transient rewind:
the common declaration boundary now publishes that tape. The executable
`law-completion-binding` fixture passes; duplicate/type/affine rejection remains
covered by the final v11 positive/negative fixture reports.

Actual runtime profiling of the new private checker found storage requests
dominating dispatch. Lowering now admits dependency-ordered nonrecursive arena
wrappers over authenticated native storage/scalar calls, retaining their exact
signatures and typed external request handlers. General computation, recursion,
indirect calls and large closed constructor trees remain CPS. Computed record
destructures receive typed root-match helpers rather than unsupported native
local scrutinees. Final regeneration: 786 source definitions, 3,347 source calls,
2,113 pending sites and 4,603 bodies/helpers. No generated JS is patched.

Native validation still retained every checked output `e`; reducing the heap
alone failed during validation. `native_checked_storage.ts` now snapshots each
actual native checked graph after its successful check, then releases its heap
slot. Emission restores verified bytes on demand; it never substitutes source
`v`. All fields, graph sharing, sparse arrays, undefined, numbers, BigInt, span
texts and original native annotation/cache closures are retained. Source `v/T`
remain available to subsequent native checks. Schema-three provenance identifies
the actual producer, receipts, string table, bytes and retained native closures.
The 321-definition storage smoke also executes restored emitted code, requires
identical JS bytes and rejects a corrupted snapshot.

Both completed full-root runs below validate the same 7,840 events and 7,567
definitions, with identical complete Bend/foreign source closures and identical
30,495,807-byte JS SHA-256
`2709f0bda72cee8a186c7d41a0bce37d49fb0cd682267815cef8218d865203cd`.

| Completed current root | v10 retained outputs | v11 checked storage |
| --- | ---: | ---: |
| Peak process-tree RSS, bytes | 5,969,281,024 | 4,737,744,896 |
| Peak physical footprint, bytes | 6,280,901,264 | 4,157,197,032 |
| Guardian elapsed, ms | 55,607 | 309,581 |
| V8 old-generation budget, MiB | 6,144 | 3,072 |

This is a memory/time/temporary-storage tradeoff, not a full-build speedup.
Temporary checked graphs use 3,812,837,886 bytes and are removed after publication;
441,420 original native closures remain compile-local. Emission retains at most
one checked slot and one higher-body slot. Validation wall/CPU is recorded in the
v11 timings; automatic GC, external 8-GiB RSS/physical caps, finite deadlines,
zero excluded checks and zero output patches remain enforced.

The separate same-input layout comparison emits identical 4,576-byte libraries:
sampled live codegen allocations fall from 5,361,440 to 497,184 bytes, with
`lay_fields`/`lay_pack` samples 1,935,512 versus zero. These are codegen-only live
samples, not whole-process heap/owner sizes. Exact evidence and caveats:
`selfhost-memory-same-work-canonical-v11.json`.

Fresh bootstrap v11/v12 passed all 64 seed fixtures but stopped during real
stage-one parsing: first at a successor/reuse-marker spelling, then at bare U32
literal patterns in the native arena source. The renderer now separates the
tokens; the arena quantity decoder compares its affine word once and matches
`Cmp` constructors, preserving exact 0/1/default semantics. Both changes are
source fixes, not parser-output repairs. `parser-root-closure-compat-v1.json`
records actual accepted-parser success for all 15 current Bend inputs; it is
explicitly diagnostic, not bootstrap acceptance. The permanent quantity decoder
boundary regression executes on JS and C (`arena-quantity-codec-backends-v1.json`).

The complete refreshed native v13 build validates 7,841 events / 7,568 definitions
and emits 30,472,921 bytes, SHA-256
`a560b171201ae023b75d5eefb5c7b909faf0c14972fbc47eb2965a403f8a8a13`.
Its guardian records 4,757,766,144-byte peak RSS, 4,517,665,880-byte physical
footprint and 230,457-ms wall; CPU is 407,637.498 ms. Max checked/higher slots
remain one, zero checks excluded and zero output patches. This source revision
is not a same-input timing comparison against v10/v11. The fresh full v13
bootstrap's final report, not any native/parser/fixture result above, determines
stage1/stage2 fixedpoint and `compilerBootstrapGreen`.

Full fresh v14 passed source-closure authentication, all seed fixtures, complete
AST approval/restoration and expansion, but hit the 3,300,000-ms deadline in
stage-one checking. No stage artifact exists. The full-root v15 CPU profile shows
trampoline/dispatch overhead; v16/v17 causal traces identify repeated inference
inside preliminary usage analysis of `lexer.scan`. Correct arena request fields
prove these costly local projections are in `validated=false` mode, so merely
trusting post-validation annotations would not solve this path.

Usage local-environment construction now reuses the existing `function_type_of`
projection for preliminary named/annotated/application values. It preserves
dependent result substitution and binder depth; unsupported forms retain the
existing full inference fallback. Actual body/argument/annotation validation
remains unchanged. Fresh v18 native full-root build passes under the same gates;
fresh v18 bootstrap passes all 67 fixtures, including erased returned-function
domains, affine returned-function rejection and invalid annotation rejection.
It still hits the deadline during stage-one checking. Fixedpoint remains
unproved; the late declaration counter run investigates the remaining real path.


### Cutoff-aware source/transient bounds and native root v22

The prolonged full v20 bootstrap was explicitly cancelled during stage-one
checking; its report remains IN_PROGRESS and is not acceptance. No stage artifact
was produced. The bounded causal v21 trace reached `template_match_43` after
171,340 ms of checking: its 10-second hotspot spent 5,578 sampled ms in conversion
and 3,417 in usage, with repeated eager `core_subst_terms` traversals.

Source metadata now encodes conservative arbitrary-Nat free-variable bounds.
Transient publication resolves original full-tagged children and tapes through
their actual owners before certifying a bound; local-ID collisions cannot supply
source metadata to a transient child. Unknown bounds remain unknown across
binders. Separate trusted-bound/closed flags are cleared with the existing
rewind lanes. Shift/substitution preserve a handle when the known bound lies
below the actual cutoff/target, not only when the subtree is closed.

Actual typed-step execution passed 18 semantic assertions in 44 requests,
covering mixed-region collisions, lambda/All/Sub capture boundaries, unknown
children, exact/below/above substitution and shift targets, and indexes above
U32 (`arena-typed-bound-smoke-v22.json`). This is diagnostic smoke, not bootstrap
acceptance. Native bounded-tail exception recovery also passed: 100 original
array-depth refusals followed by a 200,000-step call returning 200007
(`native-tail-exception-smoke-v21.json`). Existing foreign callback/currying
execution printed 123, 42, 107.

The complete native v22 root validates 8,008 events / 7,735 definitions, emits
44,603,198 bytes with SHA-256
`f62770736295a1729d1cac43645847c88084cc1e00e988a89f7c573bb3b3204a`,
and retains at most one checked/higher body. Guardian RSS is 5,436,047,360 bytes,
physical footprint 4,911,822,856 bytes, wall 293,028 ms, CPU 428,502.787 ms;
zero checks excluded and zero output patches. Temporary lossless checked storage
is 3,818,199,031 bytes. These revised sources are not the v10/v11 same-work pair.
Fresh v22 parser/complete-source-closure diagnostic finished in 121,875 ms.
Stage1/stage2 fixedpoint still requires the final full bootstrap.

### Exact declaration-local substitution reuse v23/v24

A 4,096-slot direct-mapped memo stores full input/value handles, arbitrary Nat
index/depth and the completed output handle. Hits retain the current store;
collisions miss. Every arena rewind, including a no-op mark, clears the table
before any transient handle can be reused. Actual v23 typed-step smoke passes
changed-key, cross-U32, release/reused-slot and no-op-rewind cases
(`arena-exact-substitution-memo-smoke-v23.json`, 403 requests).

The v23 root causal trace exposed the remaining exclusion: 131,054 of 133,232
open substitutions repeated only 2,178 exact signatures in the hotspot, with a
transient value handle. V24 removes the source-only eligibility shim; immutable
published nodes of either region remain valid for the same rewind-bounded epoch.
Actual v24 execution passes 9 assertions / 79 requests, including reuse of the
old value ID for a different variable after release
(`arena-transient-exact-memo-smoke-v24.json`). Source/transient repetitions take
22/7 requests, transient/transient repetitions 18/7; these are micro results,
not whole-root speedup.

Complete native v24 validates 8,030 events / 7,756 definitions and emits
44,622,776 bytes, SHA-256
`252e9fc5c3f65d50c6ad6be1937d75c77565c16396627b48a9970c61c339614a`.
Guardian RSS 5,594,120,192 bytes, physical 4,893,348,920 bytes,
wall 230,080 ms; CPU 408,207.53 ms. Max checked/higher bodies remain one;
zero excluded checks and output patches. Expanded permanent binder regression
executes lambda/All/Sub closed/capture boundaries on JS and C, printing 10101.

The fresh full v24 bootstrap passed all 67 seed fixtures, complete source closure,
parser parity/restoration and expansion, but exhausted its 3,300,000-ms deadline
in stage-one checking. No stage artifacts were emitted. Its last checking boundary
was at 357,916.871 ms; this is not fixedpoint acceptance. The bounded prefix
improvement did not establish complete-root throughput. The next change targets
eager beta substitution of every dependent result-family case before selecting
the actual constructor branch, rather than launching the same long gate again.

### Selective beta and source constructor-prefix indexing v25–v27

Selective beta substitutes only the decisive branch of a single-Var0 match.
Unknown shapes, neutral or inconclusive patterns retain the original whole-body
normalization path. Actual `selective-beta-smoke-v25.json` passes 137 assertions
covering constructor aliases, ordered patterns, captures and exact fuel boundaries.
Selecting the FIRST branch with 1/1,000 unrelated rows takes 116/116 requests,
versus eager baseline 236/53,183. This did not establish root throughput:
plain v26 root checking still exhausted a 900,000-ms deadline, and causal v26
stopped at `template_match_239`, dominated by sequential `whnf_beta_cases`.

V27 adds 64 source-owned direct-mapped index slots for immutable case lists
of at least 64 rows. Exact tagged range start/count keys distinguish entries.
Raw constructor names map to their FIRST logical row; the first uncertain or
nonconstructor row is an ordered-matcher barrier. Scope aliases resolve fresh,
not from the cache. Forward/reverse suffixes preserve full tape tags, transient
lists retain sequential matching, and every source rewind clears the index.
Transient release does not discard source indexes.

Actual native factories and original typed LIFO resumes pass 250 assertions
(`beta-index-v27.smoke.json`): FIRST/LAST selection, duplicate heads with nested
field mismatch, earlier wildcard/unknown barriers, changed alias scope, reversed
source tapes, transient fallback, captures, exact fuel, source rewind/range reuse
and source-cache persistence through transient release. Warm selection with fresh
argument handles costs 82 requests for both 100 and 1,000 unrelated raw heads,
including LAST and reverse-LAST. Small LAST costs 80 requests; cold 1,000-row
index construction costs 3,090. No substitution-memo signature reuse contributes.
The temporary native fixture and driver were removed after execution.

Complete native v27 validates 8,166 events / 7,889 definitions and emits
44,719,942 bytes, SHA-256
`0f5faa6d1b75c60ca6c76060291cdf3777015b78b8c2bc20645c0c9b25f2a128`.
Guardian RSS 4,283,416,576 bytes, physical 4,085,918,176 bytes, wall 228,896 ms;
maximum checked/higher bodies remain one. This is not same-work v10/v11 and
does not establish stage1/stage2 fixedpoint.

### Indexed pattern usefulness and exhaustiveness v28

The v27 whole-root checker still stopped unfinished after 900,004 ms and
345,969,184 requests (2,545 definitions checked / 2,505 stored). Causal v27
identified quadratic prior-row scans inside `checker_result` body checking:
`scope_pattern_rows_subsume_named` and `scope_specialize_pattern_rows_named`.

V28 threads explicit local `PatternRowIndex` histories through useful-branch
checking and reuses an index across each matrix constructor loop. Raw first-head
buckets and conservative rows carry logical ordinals; selected buckets merge in
original order without scanning unrelated rows. Fresh alias names and a fresh
visited map prevent stale scope conclusions or duplicate bucket work. Variable,
malformed and uncertain heads remain conservative; unsafe or incomplete scopes
use all original rows. Existing exact matchers still check selected patterns,
field arity, nested union coverage and final exhaustiveness.

Both index/selection records are `Data`; repeated index parameters explicitly
declare unrestricted quantities. The first lowering failed on an unmarked reused
index, and the first native build rejected the original `Type` universe.
Both source-level errors were corrected without weakening quantity authentication.
Native fixture factories also corrected affine Scope keys and used actual
generated ABI names. Failed reports remain separate from the passing v28d build.

Actual typed LIFO execution passes 1,225 assertions
(`coverage-index-live-v28-smoke.json`), including useful wrong-type/arity rejection,
nonexhaustive rejection, native-compatible shadowed rows, multi-column/nested
union coverage, aliases after Scope changes, source/transient/reversed tapes,
conservative barriers and exact quantity/span metadata. FIRST/LAST coverage
queries among 100/1,000 unrelated heads each take 53 requests; ABSENT each takes
140. Full branch checking plus exhaustiveness grows 56,146 → 561,946 requests
for 100 → 1,000 unique constructors, rather than quadratic scanning. Actual
index construction grows 1,601 → 16,001. These are matrix measurements,
not completed-root or fixedpoint acceptance. Temporary fixture/driver removed.

### Actual transient dispatch prefix path v29b

Whole-root v28 remained unfinished at 900,002 ms / 285,397,035 requests.
The index-path causal run (`selfhost-checker-index-paths-canonical-v28.json`)
showed the real excluded input: reversed TRANSIENT 188-row tables, such as
start 3,221,228,502, returned `CasePrefixEmpty` and were revisited ten times.
Coverage queries used the indexed path; the source-only whnf prefix benchmark
had not established acceleration of this actual transient dispatch path.

Transient ranges now build an ephemeral raw-head prefix map per normalization,
validating case, pattern/tape and name owners independently. First uncertain rows
remain barriers. No transient map is stored in either Arena; source caches retain
their original lifetime. Names retain the production source-interning contract.

Actual native `transient-case-live-v29c.json` passes 34 eager parity scenarios,
30 index/eligibility/scaling probes and two real release/rewind ID-reuse scenarios.
It executes the reversed transient 188-row shape, source/transient mixed nodes
and patterns, duplicate/wildcard/unknown rows, aliases, captures and fuel 0–4.
Native ArenaStore is affine: parity branches use independent copies of native
fixture data, not two aliases of one mutable arena/memo backing. The initial
driver shared those stores and corrupted its eager reference; passing evidence
uses independent stores and retains all semantic parity cases.

FIRST/LAST among 100/1,000 unrelated heads costs 385/3,085 requests; exactly one
`whnf_pattern` and one `equal_names` call each. The local build costs 306/3,006
requests and repeats on every normalization; this is linear ephemeral work,
not a persistent warm-cache claim. Temporary fixture and driver removed.

Complete frozen native v29b validates 8,332 events / 8,053 definitions and emits
44,829,628 bytes, SHA-256
`7fb3185829fabbf16b1964848fbb73bb042b26534027dd89676289e8415f8807`.
Guardian RSS 4,956,782,592 bytes, physical 4,776,070,544 bytes, wall 233,721 ms;
maximum checked/higher bodies one. A prior v29 build was canceled after a
post-generation source edit; v29b regenerated and authenticated frozen inputs.
No completed-root or stage1/stage2 fixedpoint claim follows from the micro proof.

### Source-only constructor reflexivity witness v30

Complete-root v29b remained unfinished at 900,003 ms / 254,044,530 requests,
with 2,405 checked definitions. The late causal run
(`selfhost-checker-late-causal-canonical-v29b.json`) executed every preceding check
and found 179,150 identical complete source-range comparisons among 189,983 calls.
Repeated source `Succ` trees, not empty-list equality, dominated this late path.

Positive bit 16 in the existing source node flags certifies constructor-only
trees with live names, validated complete source argument ranges, and strictly
older source children. Recursive proof remains typed Checker requests; native
helpers only inspect bounded descriptors/ranges or publish metadata. Exact
tagged-range identity plus this witness permits `SomeTrue`; unsupported terms,
mixed/transient ranges and different ranges retain the original comparator.
Bound recertification preserves the bit; source rewind clears it before reuse.

Actual native `ctor-reflexivity-live-v30j-smoke.json` passes 53 parity/safety and
lifecycle cases plus nine depth/range profiles and 72 warm repetitions. Singleton
cold depth 1/31/1,000 costs 26/356/11,015 requests; every warmed depth costs 13.
Three-cell forward/reverse ranges cost 23 warm requests at every depth. Independent
native factories preserve unsupported `None`, aliases and region-ID separation;
actual rewind/reuse, growth and recertification are exercised. This is not a
completed-root or bytefixedpoint claim. Temporary fixture/lifting utility removed.

Complete frozen native v30 validates 8,401 events / 8,122 definitions and emits
44,874,680 bytes, SHA-256
`755da1272f13f0bed58497c0b786170c46b62a01f438e18a85984bce3c564342`.
Guardian RSS 4,943,577,088 bytes, physical 4,780,704,256 bytes, wall 235,617 ms;
maximum checked/higher bodies one. Fresh full-root parser/source-oracle run
passes at 114,063 ms (`selfhost-root-parse-canonical-v30.json`). Complete checking
and actual stage1/stage2 byte fixedpoint remain unproved.

V30 complete-root checker is still unfinished at 900,124 ms / 211,159,921
requests; 2,277 definition-leave events, current `checker_match_818`. The actual
per-definition journal identifies `checker_match_720` at 20,623 ms / 7,218,162
requests, including 898,312 segment walks, 837,022 index lookups, 837,022 index
result dispatches and 234,427 bucket dispatches. Constructor-tree micro success
did not establish completed-root throughput. Next cutover is immutable visible
lookup snapshots preserving ordered family/kind precedence and original segments.
Existing actual JS/C lane regressions pass: bound `10101`, closed `1001`,
quantities `2102210`; no stage artifact or fixedpoint is inferred.

### Immutable visible lookup snapshots v31

`ArenaVisibleScope` now retains original semantic segments plus a persistent
merged lookup map. Cold construction traverses actual `MLeaf` string keys,
sharing empty-side maps. General queries preserve the first family across segments
or first ordinary candidate; per-kind queries preserve first matching kind.
Prepend/fill updates refresh only affected raw/canonical/import-alias key paths
against updated segment heads, not entire imported dictionaries. Alias/candidate,
completeness and unsafe operations keep their original segment semantics.

Actual `visible-lookup-live-v31d-smoke.json` passes 63 full-declaration parity
queries and six update transitions, including filled values, divergent alias/raw
keys, persistent older snapshots, incomplete indexes and unsafe wrappers.
For 1/10/100/1,000 segments, cold construction costs 4/43/403/4,003 requests;
192 warm queries always cost 416 requests with identical request histograms.
All typed resumes execute once. The initial fixture used `Map.put` (existing-key
replacement) to add distinct keys and assumed tagged native Bool; corrected
evidence uses persistent `Map.set` insertion and actual boolean values. Neither
semantic parity nor independent expected declarations were suppressed.

Complete frozen native v31 validates 8,422 events / 8,143 definitions and emits
44,893,466 bytes, SHA-256
`0709ff47b4d016076b70f7aa239d949c7862039f39c2efc4145c12a62a4f0e0c`.
Guardian RSS 4,972,052,480 bytes, physical 4,712,547,904 bytes, wall 272,020 ms;
maximum checked/higher bodies one, zero excluded checks/output patches.
Actual full bootstrap `selfhost-bootstrap-canonical-v31.json` is running after
the native/semantic proofs. No stage artifact, completed-root check or bytefixedpoint
is yet claimed; this is not another bounded counter-only diagnostic.

Temporary native fixture/reference driver removed after the observed pass.

Actual full bootstrap v31 ended at its 3,300,019-ms deadline: all 67 seed
fixtures pass, whole-root parsing and expansion pass, stage-one-check starts
at 668,987 ms and does not return. Peak RSS 5,766,316,032 bytes, physical
4,288,504,360 bytes; `artifacts` remains `{}`. No stage1/stage2 output exists.
A frozen-input per-definition v31 run now diagnoses that actual checker boundary;
no second blind long bootstrap and no fixedpoint claim is warranted.

### Measured dispatch bottleneck and tagged switch cutover v32

V31 frozen counter remains unfinished at 900,004 ms / 103,814,765 requests:
1,945 completed definitions, current `checker_continuation_522`. Fewer requests
did not establish completed-root throughput. The isolated actual native scope
lookup investigation (`scope-lookup-native-cpu-v32.json`) performs 30,000 queries
on 100/1,000/10,000-key maps and does not reproduce a merged-scope lookup slowdown.

The actual checker-thread V8 profile
(`selfhost-checker-worker-cpu-canonical-v31.json.Checker.cpuprofile`) captures
361 seconds on CPU: 29.8% self time in the native checker wrapper, 17.2% in its
internal dispatcher, 14.5% GC. Generated `checker_step` contains 2,496 ordered
string-tag conditions. The first external CLI profile sampled the idle supervisor,
not the checker thread; it is not evidence about compiler runtime costs.

Canonical `comp.ts` now emits tagged matches as lexical switch blocks, preserving
the original unconditional final/fallback body; optimized primitive representations
retain their existing conditions. Actual compiled Node regressions pass:
shared constructor `10`, default `0n`, erased arm `11`, closure match `103`.
Corresponding conservative selfhost-emitter dispatch is being integrated so that
stage-one execution cannot retain the same linear bottleneck. No cache epochs,
unchecked shortcuts, output patches or bytefixedpoint claim are introduced.

V32 full real consumer proof is now PASS:
`tagged-dispatch-live-v32h-smoke.json`, 148 native/selfhost observable rows,
complete parser semantic parity, authentic ExpandSuccess/CheckSuccess modules,
unchanged emitted artifacts, zero unchecked definitions or output patches.
Wide enums cover first/middle/last among 8/100/1,000 heads; behavior covers ordered
duplicates, nested shadowing/captures, wildcards, multi-column matches, native
Bool/Nat/String representations, erased field offsets/callbacks, live exception
identity, empty elimination and qualified aliases with identical short tags.

The behavior path exposed two pre-existing erased-binding inconsistencies:
the checker rejected a default binder for an erased field, and the emitter used
pattern spelling instead of constructor telescope quantities for packed offsets.
Canonical native probes accept an unused erased Type binding and reject a live
erased Bit reference. The checker keeps the binding QZero; generic pattern tests
and projections now walk actual constructor binders, retaining null lexical slots
without consuming erased runtime slots. The seed negative fixture previously
rejected a native-valid program; it now tests the actual forbidden live reference.
A positive erased-default-binding seed and long Unicode string-tail seed were added.
Native runtime `tests/reg/match_erased_default_binding.bend` prints exactly `48`.

Authenticated behavior emission also reproduced `RangeError: Invalid string length`:
4,196,920 actual emitter requests built a discarded 486,539,237-character field
expression. Eager representation-choice arguments recursively explored unrelated
native representations. Boolean branch helpers now select before recursive work;
the emitted `$string_tail` helper evaluates its input once. Full literal-string
dispatch attempted during this correction exhausted the unchanged 3,072 MiB native
heap; both long and compact literal dispatch were rejected rather than raising
the memory limit. Those failed receipts remain preserved.

The corrected full-root native build is `selfhost-steps-native-canonical-v33`;
real fresh stage1/stage2 byte comparison remains the acceptance criterion.
The 148-row consumer proof is not a fixedpoint claim.

Full native corrected root v33 PASS: 8,476 events / 8,197 definitions,
45,789,338-byte artifact, SHA-256
`09c89ca81b5a3220810b58b54f27e39e256151cb91edbd472a58588c01861ea3`.
Guardian physical 4,989,240,016 / RSS 4,773,298,176 bytes, wall 615,923 ms,
unchanged 3,072 MiB heap and 8 GiB process-tree limits, checked/prepared e/h max 1/1.
This is a changed workload, not the same-input v10/v11 memory comparison.
The fresh real full gate is `selfhost-bootstrap-canonical-v33.json`.
The erased-default-binding regression also runs as an actual compiled C binary
and prints exactly `48`, matching its previously executed JS backend.


### Declaration-local transient prefix reuse v34

The actual full v33 bootstrap still reaches its 3,300,012 ms deadline in
stage-one-check. All 69 seed fixtures pass, including default erased bindings,
forbidden live erased references and the long Unicode literal pattern; full
root parse/expand pass. Artifacts remain `{}`. Physical 4,769,064,656 /
RSS 6,467,092,480 bytes. Tagged dispatch improved early execution, not completed
whole-root acceptance.

Frozen late causal v33 observes `checker_match_1334`: the same full-tagged reverse
transient case range `3221226479:958` is indexed eight times in one definition.
Repeated local-build recursion dominates its index work. In tagged IDs, bit 31 is
the **transient** owner flag; bit 30 is the reverse word-tape direction flag.

V34 reuses the existing 64-slot raw-head cache in the transient arena. Immutable
published descriptors/tapes remain the prerequisite; append-only growth retains
entries. Every owning rewind discards the cache. The previously unused metadata
depth lane 6 counts rewinds; each mixed-owner entry also authenticates the source
generation before reuse, so source rewind/reuse cannot retain stale raw heads.
Aliases, semantic normalization and the original ordered matcher remain uncached.
`CasePrefixSaved` and every real caller migrate together; no compatibility shape.

Actual `transient-prefix-cache-live-v34e.json` PASS: 180 native consumer probes,
12 cold tables, 96 warm repetitions, source and transient rewind/ID reuse,
forward/reverse ranges and source/transient descriptor mixtures. Table lengths
64/100/1,000 cost 199/307/3,007 requests cold, **6 requests warm** for every mode.
Stores come from actual checked native factories and are consumed linearly;
no shared-store reference branches or host-created compiler ASTs.
Permanent `tests/reg/checker_arena_generation.bend` runs on actual JS and C and
prints `7`: growth preserves the generation, even a count-preserving rewind
advances it, and subsequent growth preserves the advanced generation.

Fresh full native root v34 PASS: 8,495 events / 8,216 definitions,
45,804,032 bytes, SHA-256
`9b89658c930e245dec137cdbca37172478fd0cd859b51378eeb1ec2c6dee2b11`;
physical 5,309,812,368 / RSS 5,520,310,272 bytes, wall 300,078 ms, e/h max 1/1.
The fresh full real gate is `selfhost-bootstrap-canonical-v34.json`. Its finite
acceptance deadline is 10,800,000 ms, so the first emitted stage is not killed by
the previous 55-minute total limit. The unchanged 8 GiB memory/RSS gates remain;
the longer deadline is not a claimed speedup. Whole-root checking and actual
stage1/stage2 raw byte equality remain unproven.

Full v34 gate returns a real worker heap OOM after 969,892 ms, not its deadline
and not the 8 GiB physical/RSS guard. All 69 fixtures and full parse/expand pass;
stage-one-check starts at 257,894 ms. Peak physical 5,223,975,240 /
RSS 5,577,179,136 bytes, artifacts `{}`. No stage-one output was emitted.
The worker driver retained its expanded parser graph until checking returned,
while the native checker packed a private arena. The shared step driver also
retained its initial module argument. The v34b acceptance run moves each input
to the actual native start request and immediately drops those obsolete host
roots, without manual GC, host checking or changes to compiler output.
The effect of that lifetime correction is not yet proven.


V34b also ends in worker heap OOM, after 3,015,315 ms: all 69 fixtures and
full parse/expand pass; artifacts `{}`. Physical 5,524,695,744 /
RSS 4,669,571,072 bytes. The default Node heap ceiling measured separately is
4,345,298,944 bytes, below the existing 8 GiB aggregate resource envelope.
V34c explicitly budgets the bootstrap worker at 6,144 MiB old generation;
actual worker ceiling smoke reports 6,492,782,592 bytes. The native builder
remains at 3,072 MiB; aggregate physical/RSS guards remain 8 GiB at 10 ms.
Heap used/limit now accompany real phase receipts. This is capacity accounting,
not a memory-reduction claim; fresh complete v34c acceptance is still running.

