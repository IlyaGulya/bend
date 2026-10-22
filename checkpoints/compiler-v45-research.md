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
