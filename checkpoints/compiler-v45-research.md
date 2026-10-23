# v45 acceleration investigation

Read-only source investigations by `CheckerCostTargets45` and `NativeExecutionReview45`; parent checked the candidate seams. No timings were measured by those agents. Current measured acceptance remains Main43/parser69,267/267 byte fixedpoint. Native45 build and execution have separate receipts.

## Checker candidates, not integrated

1. **Avoid re-interning unchanged name IDs.** `checker.bend:11942-11955,11982-11990` reads an existing variable name from the arena and interns that string again during substitution. `core_shift_at` and other copy paths have the same pattern. `arena_name` and `arena_name_text` both address the source region (`12628-12641`); `arena_release` rewinds only transient storage (`12623-12626`). `checker_arena.bend:1075-1087` returns an existing ID on an intern hit. Thread the original ID directly through copy operations; do not introduce an identity forwarding helper. Leave actual canonicalization/renaming operations unchanged. Validate nested binders, aliases and declaration-to-declaration rewind boundaries. Frequency and whole-checker benefit are unmeasured.

2. **Reuse unchanged application views.** `checker.bend:9054-9092` always allocates a new App/Ann after recursively viewing its head, even if the returned head ID is unchanged; Bang(Ref) also reconstructs the same inner Ref. A candidate can return the existing handle on identity and retain ordinary reconstruction on change. This requires checking immutable-handle lifetime, span preservation, bang rejection and substitution semantics. It removes arena writes and calls, but the measured share of this path is unknown.

3. **Short-circuit identical family names.** `checker.bend:972-973` canonicalizes both names even when their strings are equal. `equal_names:1711-1719` already has the safe textual-equality fast path. The scope lookup is read-only (`10774-10775`); different strings must retain canonical alias resolution. Expected benefit is limited to this caller, not all index-lookup time.

The historical profile's self samples were run_loop12.06%,runSteps7.20%,index_lookup.find3.98%,Map.get.go3.10%,GC2.85%. They do not prove which source operation owns GC or a wall-time floor. Name interning's share of Map.get is a hypothesis, not a measurement. Any checker-source edit changes the compiler being bootstrapped: neither stable arena IDs nor preserved semantics justify claiming the new compiler image equals the old one. A fixed frozen input may emit the same output; every new compiler version still needs its genuine stage1/stage2 proof.

## Native orchestration

No concrete continuation/ownership bug found in `evals/native_compiler_host.c:56-106`, `evals/native_compiler_driver.bend:79-105` versus `evals/checker_core_step_runtime.mjs:20-62`. The C host uses a LIFO stack and consumes each next/resume once. Runtime constructor extraction uses `ctr_take`; `term_drop` is iterative (`bend2/comp.ts`, ctr_take/term_drop), so a fuel-tail C-stack overflow is not established.

The host allocates exactly8M fuel cells per source (`native_compiler_host.c:190-204`), plus progress and transition applications in `56-106`. Existing `NATIVE_FUEL` and `NATIVE_PHASE` records can measure these costs on a full run; source inspection cannot supply their timing.

**Do not share a cold fuel chain merely by sealing its root in foreign C.** `comp.ts`'s `emit_fields` selects `ctr_take` only for hot/static constructors; cold fields use raw `term_loc`. `ctr_take`'s shared path requires already-sealed children (`span_fade`); `io_box` seals its child only for a hot CID. A shared-root-only change can violate both invariants. A legitimate checked duplication callback could make ownership visible to `facts_hot` and allow one chain to be retained and reused, but adds RFC work and needs an actual generated ABI/ownership check and runtime comparison. A compact fuel-type replacement instead requires a checked representation and migration of every consumer with identical finite-budget exhaustion semantics. No shorter/reset budget, bypassed ownership, or omitted reflection checks is acceptable.

## Parent's native cache experiment

`comp.ts` now uses a WeakMap for telescope results: checked-book signature keys stay live and reusable; temporary instantiated type keys are collectible. Body-cache release still retains original checked terms and clears transient body/constant memos. Native45 generated C is byte-identical to native43 C (SHAf72b84f4c59937b077e56386ed5a3115b106cbb78b090f55bd2d5eef49171cc2). Eight C1/C4 executions pass for mapper captures, wide records, deep boxed records and dependent two-index families. Full8204-body build completes in524886ms under the unchanged8GiB/600s guardian. Sequential codegen observations391844 vs428781ms are not an isolated causal speedup or a median; native execution speed is a separate result.

The subsequent actual native-O0 run completed parse31948.469ms and expand101927.657ms (31910111 calls and resumes), but did not finish checking before the unchanged1800000ms deadline. Peak footprint936855568 bytes; no emitted output. All120M fuel cells cost839.573ms total: fuel construction is not the dominant bottleneck. Reject this unoptimized native execution strategy; this is not evidence about optimized native code. The full JS seed regenerated through the weak-cache backend is raw-byte-identical to accepted43's seed (SHAb9eb88ab7c4025ddf2a6593aad5186d16b10a0e2670b7a678e307913dfbec0fc).

## Read-only follow-up while remote46 acceptance runs

The v46 view-sharing edit removes rebuilding, not repeated spine traversal.
`infer` at `checker.bend:3202-3204` validates the function spine and argument;
`infer_application_valid:3039-3041` then views that spine and recursively infers
the function prefix. On ordinary nested applications this repeats prefix walks.
`application_args` is not a general inference cost: its only nonrecursive
consumer is the self-recursion termination branch at9633-9655. Likewise
`recursion_terminates:9685-9689` finds the head and, for a different name,
recursively visits the function prefix again at9652-9655.

A candidate to measure next is positive immutable-node certification for the two
bang-validation contexts, rather than skipping validation or caching inferred
types/affine usage. These validators have no environment/global-scope argument.
The arena already stores independent certificate bits in `node_closed`, with
range-checked `node_has_flag` and a positive constructor-tree certificate:
`checker_arena.bend:532-612`. Reusing this metadata avoids adding an arena array.
Each new/reused node slot overwrites its flags at959-980. A future certificate
must keep source/transient region handling and both contexts distinct, and must
update the existing preservation mask19 at702 without clobbering bound or
constructor certificates. TermSub normalization and rewind/reuse need semantic
regressions. No such cache is implemented or timed in46; source inspection does
not establish its full-workload speedup.

## Measured v46 costs after remote acceptance

`compiler-profile-v46.json` records the current CPU profile and balanced exact
continuation counters:89069047 pending,100069670 direct,189138718 finished,
189138717 resumes,378277435 host iterations for a complete CheckSuccess.
The largest request is scope_canonical_name5027639, followed by arena_put_node
and arena_bound_node4764907 each. Bang validation requests are256983 head/
416700 argument/298057 argument-list, not the leading source candidate.
Synchronous owner sampling cannot recover the logical CPS call stack.

Native46 C generation completed in74034ms with8204 bodies/8548 events checked.
Apple clang21-O1 then exceeded8GiB physical memory; a separate unchanged-C
-O1-fno-inline-functions experiment also exceeded8GiB after70707ms. Do not
blame the176MB parent or call disabled inlining a solution.

`compiler-native-linux-v46.json` records actual clang18-O1 success under real
Linux8GiB/no-swap cgroups, followed by complete native parse/expand/check/emit,
7720 exports, output import/semantic smoke, and exact native/source-JS output
parity. Native165222ms core phases versus source-JS85203ms and official13486ms,
all on the same relocated50-file corpus. Native is1.94x slower than JS, not an
acceleration. cgroup charged memory is not macOS physical footprint.


## Follow-up source slices, not implemented in47

The native-island scout recommends a narrower arena extraction than moving the
mutually recursive bound cluster: thread an `Arena & Arena` pair through a
native-checked word-range copy loop in `checker_arena.bend`. Source/transient
tag decoding and reverse range direction must remain exact; declaration rewind
and overlapping copy order must retain original behavior. Checker adapters can
retain ArenaStore/ArenaResult and become eligible for the existing bounded
storage classifier, with no new layout or admission convention. Targeted v46
requests are arena_copy_word_range2688318, arena_publish_names_copy387760,
arena_words_append1509177 and arena_names_append1971272. These are measured
baseline counts, not a proven complete delta or speedup.

The constructor-query scout found an existing index invariant: only the
complete/collision-False family bucket guarantees every entry has the same
literal owner. Re-deriving that owner through every constructor telescope is
unnecessary. A corrected one-loop design would carry `Maybe<Bool>`: compute
`family_equal(bucket_key, requested_name, scope)` once for a nonempty certified
bucket; use None for incomplete or alias-collision full scans. Some(valid)
bypasses owner derivation and the per-entry family comparison. Preserve
canonicalization and seen-map lookup for every emitted constructor name.
`Maybe<String>` alone does not hoist family_equal; the scout's initial claimed
seen-map savings were incorrect. Canonicalization is not idempotent under
shadowing, so the hoisted predicate cannot be replaced with True. Empty families
must avoid evaluating it eagerly. No scope identity or memo invalidation scheme
is invented. The estimated401k eligible entries is sampling-derived, not an
exact count; actual deltas still need measurement.

Actual emitted46 runtime was also measured independently on nhs:
`compiler-emitted-linux-v46.json`,122301ms full compilation, all7720 exports,
output import/smoke and native/seed byte parity. The original seed measured
85558ms and official13572ms there. Do not describe seed timing as emitted-stage
timing, and do not compare these Linux numbers to Mac wall times.


## Actual emitted47 profile, collected during48 acceptance

`compiler-emitted-profile47.json` records the byte-pinned real emitted compiler,
all50 fresh files/15 checked modules under actual8GiB/no-swap Linux cgroups.
Statistical worker profile SHA8c418841ff208b56fe02c61f7820366752a6e8e9746d17f35df3a7f79e0cc431.
Checking completed in93773ms; emitted output/smoke was intentionally not rerun.
The concrete public checker dispatch stack includes $run -> exported curried
wrapper -> run_force/run_loop -> tail_dispatch -> checker_step -> run_named1.
The global facade starts with$td=64, forcing a tail frame even on a fresh
public entry. Generated runtime self samples total15750ms, but inlining means
generic helper attribution is not exact removable overhead. A future public
entry fast path must not reset depth for ordinary internal higher-order calls:
those must keep the existing stack-safety protocol. No emitted image was patched.

## Version49 public entry and challenged theory conclusions

The source emitter now specializes eligible exact-arity public entries only.
Native root8173/8173, parser75 semantic/span cases, library16 consumer cases,
and full273-fixture genuine stage1/stage2 byte fixedpoint pass. No internal
closure depth reset or emitted-output patch. Complete proof/recipe are in
`selfhost-acceptance-release237-misaka-v49.json` and `compiler-export-entry-v49.json`.
Actual nhs consecutive48/49 compilation111478/101230ms, phaseCPU132706/120623ms;
one pair favors49, not a repeated causal result.49seed84375ms is not emitted49.
Both49runtimes emit identical bytes;48format differs intentionally.

Reading official2.0.37 and the current arena checker disproves repeated
application-prefix inference: both infer each App once, with one whnf, argument
check and codomain instantiation per level. Bang/type-view prefix walks repeat,
but measured request volumes do not justify calling them the main bottleneck.
Official uses HOAS codomain closures and integrates affine usage with checking;
selfhost eagerly substitutes affected arena subtrees and separately projects usage.

Existing TermSub is not a safe lazy-substitution acceleration: first force still
runs full core_subst, charges an extra whnf fuel step, breaks raw inferred-type
inspectors, and loses structural/identity fast paths. Do not implement this
deferral or reset64fuel. Head-only substitution needs lazy fields/closures and a
representation-wide consumer migration, not a one-line substitution change.

A separate local duplication is real: non-erased term_usage_map applications
derive/whnf the same callee type for quantity, then derive/whnf it again for the
argument domain. function_type_of has732845 v46 requests, all in usage accounting,
versus220871 infer calls. Hoisting a single normalized head inside that same
application can remove recomputation without a cache or weakened check. Preserve
erased skipping, missing-type fallback, f-before-arg merge, Lambda beta branch,
arena lifetime and diagnostics. Benefit is unmeasured and bounded; not an8x claim.

## Version50: less duplication, rejected acceleration

The proposed single callee head was implemented without a cache: seven query
helpers become three local traversal helpers. Complete native root8155 bodies/
8493 events,273 fixtures,75 parser cases,16 ESM consumer cases and actual
stage1/stage2 byte fixedpoint pass. Frozen program output stays byte-identical.
`selfhost-acceptance-release237-misaka-v50.json` records the genuine proof.

Actual nhs emitted compiler controls, not seed or instrumented timings:

|Order|49 compile(ms)|50 compile(ms)|49 check(ms)|50 check(ms)|
|---|---:|---:|---:|---:|
|49 then50|106869|133379|83820|100238|
|50 then49|112587|115380|90216|91836|

Both orderings favor49, but varying emission and penalty magnitude prevent an
isolated checker/JIT/GC/host cause claim. Reject50 as acceleration; restore49
checker for the next candidate, retaining50 source/proof in its checkpoint.

Balanced exact iterations324586413 ->320313853, a4272560/1.316% reduction.
Pending function_type_of732845 ->367957 and core_subst2002584 ->1637691 look
large, but deep core_subst_open drops only72 and arena_put_node only165.
arena_names_cons and arena_copy_word_range are unchanged. This challenges the
estimated benefit: mostly cheap root bound/memo work was removed, not tree walks.
Pending whnf−35 is NOT a total whnf-call delta. Direct/Resume totals are exact,
but the retained seed$058callback regex cannot attribute own49/50 callback targets.
The full observer source is preserved in compiler-profile-v46.json; absence of
the cleaned throwaway script is not a missing prerequisite.

Actual emitted49 checking profile: `compiler-emitted-profile49.json`, worker
SHA958d3f69fb4b656f8e5a0f0cd557ffbf50fe63c0ea704365aaac61e0787e6321,
17636237 bytes. Same full50-file input; checking-only, not emission/smoke.
Synchronous named leaves expose Map-family8146ms, scope/index5289ms, native
primitive-like1430ms; host scheduling19235ms and generated runtime helpers13380ms.
Inlining and severed CPS ancestry mean none is exact removable logical time.
Concrete hot consumers include arena_names_cons -> Arena.name -> Map.get.go,
and whnf_pattern_constructor -> Scope.equal_names -> canonical_name/index lookup.

Next hypothesis, not implemented here: eliminate immediate-Finished Direct
scheduling using a fully native-checked, nonrecursive source helper. Preserve
the exact request/result/continuation grades, fallback and single evaluation;
restrict eager targets so they cannot nest earlier nonpure source body calls.
Do not turn the host driver into the checker or reset internal closure depth.

## Profiling revision51 and architecture re-evaluation

`compiler-profiling-quality-v51.json` records immutable accepted49 as the subject,
not the rejected50 source snapshot. Exact measurement runner/guard sources are
embedded for reproduction; raw profiles/images remain outside Git.

The existing inspector helper was reused unchanged for separate phase CPU and
heap sampling. Check:101047.529ms worker samples,3431.161ms isolate GC samples;
whole-process checkCPU118503.008ms has a different scope. Estimated cumulative
check allocations172138113888 bytes include collected objects; not live heap or
an exact object/byte count. Map-family estimate38072476888 bytes connects to
Arena.name; actual Map.get source reconstructs MNode/Tuple along the path.
Arena.get_node.result estimates6031552896 bytes and reconstructs Tuple/Arena.
Do not turn allocation percentages into CPU percentages.

The old full-worker profile includes startup/parse/expand/check. Its median
sample interval1097us,99th percentile1265us; seven gaps exceed5ms and contribute
0.0639% of elapsed sample weight. Missing duration0.092ms. This validates sample
coverage, not causal attribution or hardware cycles. Hardware perf counters are
unsupported on nhs. Inspector setup/materialization contaminates tiny phases;
phase-profile times are instrumented, never normal benchmark timings.

Corrected observer actual callback coverage:

|Kind|Samples|Named own targets|Unattributed|
|---|---:|---:|---:|
|Direct|80005|79944|61|
|Resume|158558|73582|84976|

These are sampled generated target volumes. Unnamed inline continuations are
not assigned invented logical owners. All exact totals and Pending target maps
match the earlier49 observer. A/observer/A compile113842/127116/119665ms exposes
6.23–11.66% overhead against drifting controls, not a compiler speedup or CI.
Final observer persistence now writes each pass once; the original benchmark
runner needs no redirect clone. Full7720-export/output-byte/smoke run passes.
Real49 empty-input collision throwsEEXIST and preserves the existing main file.

The architecture review challenges treating all historical blockers as current.
Match factoring, memory fixes and the parser source stack fix are separate from
the remaining language constraints: forward bodiless references and structural
descent over constructor fields do not prove recursion through U32 arena IDs.
Native46 was clang18-O1 of the SAME CPS representation; it does not establish
that direct-style native code is slower. Template/JSEmit structural islands are
plausible direct-style candidates; Checker needs semantic worklists/machine
states or a representation proof, not unsafe annotations.

Official usage fusion is a real larger change, but the complete boundary is
Inference/check_term plus all five close sites. Env-relative usage indices
cannot silently become absolute levels. Constructor/erased/scalar/source-syntax
usage must be preserved; Let/local/case error precedence and conservative missing
type fallback can change acceptance. Treat this as an atomic differential
migration, separate from closure/environment normalization. No such rewrite has
been implemented or advertised as accepted.


## Compiler52: measured read-path target, full new fixedpoint

Exact retained49 heap-tree ancestry, summing each node's selfSize once, narrows
the broad Map claim: Map.get.go/Map.lo/Map.hi total28781971216 estimated bytes;
26550528752 are definitely name reads (15.424% whole-check allocation estimate),
not writes.121640400 bytes of seek remain unresolved. Full raw ancestry and
reproducible partition source are preserved in compiler-name-read-v52.json and
compiler-name-map-partition49.json. These are estimates, not CPU or promised
removable-byte totals.

Source52 first restores49 algorithms, then retains the name_ids root across
IndexLookup.find instead of Map.get's reconstructed map. Some{MAX} still takes
the historical missing branch; ID0 is valid. The new native regression exercises
empty/prefix/non-BMP keys, repeat hits without count growth, discarded-name
removal and ID reuse after rewind, and the maximum-ID marker.

Fresh canonical native root8173/8173 bodies8511events, parser75 and library16
pass. Real273/273 fixture executions and byte fixedpoint pass. Stage-one
75633.414ms; stage-two90268.889ms/check57448.326ms; guardian366678ms, physical
2490795592/RSS3799187456 bytes under8GiB/600s. Bytes18341638, SHA958ff8b8dd80d2c3cbfb36edb4e76bcc87ab7ee73b8be7942fc7fbcf5e7b47bd.
Native seed63827.886ms/check45596.202ms on frozen50/15/7720 is not an actual
emitted-runtime comparison. Both actual-image normal series now pass. LinuxABBA
observes52+17.695% compile time; MacBAAB observes52-13.576%. Both have severe
run-correlated load changes; opposite signs are not a stable cross-host speed
result. Keep49 as conservative selected baseline, retain52 as a correct measured
allocation improvement, and stop repeating these uncontrolled timing loops.

The independent quote island experiment shows the exact three existing quote
helpers need no CPS: official kernel checks all348 loaded bodies and unpatched
native JS passes13 exact cases through200000codepoints. This is a subset proof,
not production integration or a compiler speedup. Growing-prefix String.append
and codepoint wrapper allocation remain; do not claim linear source work.

Separate cumulative check allocation estimate decreases172138113888→147078030184
bytes (-14.558%); strict name-read reconstruction sites26550528752→0, replacement
find-with-name ancestor4009781272. No object-count/live-memory/CPU claim. CPU
profiles at different times are instrumented and cannot override normal runs.
The String.eq-slow-Unicode hypothesis is explicitly rejected: both actual images
use byte-identical native===; find.position adds a real dispatch but its isolated
normal-time effect remains unmeasured.

The record-elision scout's initial source-inlining proposal was also rejected.
Both kernel and selfhost forbid matching computed/local binders. Any single-arm
splice must happen AFTER frontend checking, bind actual arguments once in order,
preserve intrinsic index evaluation/traps, and eta-collapse only an established
same constructor with all live field projections and a non-vacuous shape.
No blanket JS-host identity/getter/proxy guarantee follows from Bend extensional
equality; those assumptions must be explicit. No such backend pass is implemented.

Historical identical-corpus official Mac phase times explain prioritization:
load/parse/expand1094.375ms, check993.196ms, emit7947.939ms, total10099.880ms.
The check gap demands coarse native execution rather than continuing to optimize
quoting alone. A bounded operational chunk must preserve the independent64WHNF
semantic fuel and yield without rejecting work; typed affine result/continuation
transport must be proved, not replaced by host checker logic or unsafe casts.
