# Downstream readiness: HYBRID, not self-hosting

Read-only inventory used `gates/hybrid.ts`, `gates/hybrid_gate.ts`, `bend2/selfhost/{hybrid_driver,loader,checker,template,js_emit,driver,core}.bend` and `tests/selfhost/{loader,checker,template}.bend`. Files are implementation evidence, not execution acceptance.

| Boundary | Existing implementation | Execution evidence |
|---|---|---|
| Resolver/loader | `loader.bend::load`, namespace/import work queue; host equivalent `gates/hybrid.ts::host_modules` | Existing host parser/load slice reports only; no retained selfhost-loader run establishes readiness. Loader still imports canonical parser; full compiler frontend not established. |
| Checker | `checker.bend::check` consumes loaded modules, expands Template then checks declarations | `tests/selfhost/checker.bend` has real positive/negative behavior fixtures; prior local execution not recorded. HYBRID completion absent. |
| Lowering | Host `book_load` and `term_lower` in `gates/hybrid.ts` form AST data | This is host lowering, not proof of Bend lowering readiness. `core.bend` exists; integrated compiler path unproven. |
| JS emitter | `js_emit.bend::emit` indexes module metadata and renders JS | No retained successful emitted-HYBRID execution. |
| Driver | `hybrid_driver.bend::compile`: Checker→JSEmit→write; `driver.bend` adds Loader and C path | Existing runner `bun gates/hybrid_gate.ts` compares exit/stdout/stderr with stage0 for two fixtures. No successful result yet. |

## Concrete boundary cutover

`LoadedModule{namespace,module}` lived in `loader.bend`; Checker/Template/JSEmit imported the Loader implementation only to name this data type. This dragged parser and loader IO/match-in-do into HYBRID runner closure. The brief authorizes this independent data-contract boundary work while P is blocked.

Moved the exact data declaration into pure `bend2/selfhost/loaded_module.bend`; updated Loader, driver, checker/template/JS/C emitters, foreign scanner, HYBRID input generator, and existing tests. No legacy re-export. Existing consumer-local `Loader` aliases now import the pure contract file; the actual Loader implementation imports it as `Modules`. Loader algorithm/grammar unchanged.

First guarded post-cutover real command:

```sh
bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun gates/hybrid_gate.ts
```

**RESOURCE_LIMIT**, sampled physical footprint3231108600 B /RSS2875195392 B,2.106s; no `HYBRID PASS`. The saved command currently lacks subphase progress, so this run does not attribute the new ceiling crossing to host AST conversion, runner compilation or execution. No stronger readiness claim follows. Guard report: `report-1791293984282-02fa6e0d50ac7230.json` (archived in the execution decision).

The bounded phase-attribution run completed host conversion and entered runner compilation, then exceeded 3GiB RSS (3226812416 B, footprint3144781256 B,1.702s, exit73). `hybrid-phases.jsonl` and `parser-execution-results.json::guardedEvidence.hybridPhases` retain the actual boundaries/command. Runner execution and parity never started.

Actual compiled shared-contract smoke returned `"module-contract-ok"` (exit0); passing an `Ast.Module` instead of `LoadedModule` was rejected with the expected nominal type mismatch (exit1). Sources and guardians are retained in `parser-execution-results.json::contractSmokes`; temporary smoke files were removed. These controls establish the shared data boundary, not full Checker/JSEmit readiness.

## Compiled-parser integration: first Checker-side blocker

The parser milestone is CLOSED. Frozen `parser-explicit-fuel-822e8460.js` SHA256: `0726b631b839b23f53d6c34bef99d3ff0c5f5889548ac4cdc9a4e6e1ad0ab0ec`.

Inventory confirms Checker/Template/JSEmit already import the pure `loaded_module.bend` boundary, not the Loader implementation. Existing `gates/hybrid.ts` reparses target source with TS and therefore cannot establish the requested compiled-parser pipeline.

Actual compiled-parser transport smoke passed: a self-contained typed `Flag` program parsed to a native `Ast.Module`; a compiled shared-contract wrapper returned `LoadedModule` with the exact same `.module` object. No serialization, target re-parsing or AST reconstruction. Guard peak footprint133039496 B /RSS231964672 B.

The reusable driver build used the accepted temporary direct-load/JS streaming path, exclusive8GiB limits and10ms sampling. It stopped during native source loading, before validation, codegen or Checker execution:

```text
bend2/selfhost/template.bend:134
case +Ast.TemplateBinder{ _,  _,  _,  _} <> rest: 1n + leading_template_count(rest)
expected: a quantified datatype after + (+D<..> sets D's leading quantities to &2)
observed: '<'
```

Classification: **B. CHECKER FIRST BLOCKER**, specifically an implementation dependency failing native driver loading; not a selfhost Checker diagnostic on the target. Not RESOURCE_LIMIT: peak footprint32899744 B /RSS66027520 B. Tiny Checker/JSEmit corpus, emitted runtime, real module, imports, stage1 and stage2 were not reached. The pure driver export proposal was reverted; parser and production compiler remain unchanged.

Evidence: `compiled-frontend-inventory.json`, `frontend-transport-smoke.json`, `compiled-frontend-integration-result.json`, both `*.guardian.json` records and `compiled-frontend-build.jsonl`. Repair the Checker dependency source against the frozen native grammar before retrying; no Template-expansion bypass or TS target-semantic substitution.

## Syntax repair retry: native validation reached, still HYBRID BLOCKED

Removed invalid constructor quantity prefixes; retained reusable fields where needed. Updated stale AST pattern arities to the shared `ast.bend` schema. Converted expression-position/computed matches to native body matches, kept scrutinees in binder order, and folded consumed-field matches into their outer patterns. Migrated value comparisons/negation to native Nat/Bool APIs. Repaired missing JSEmit expression parentheses without changing emitted string literals. Driver IO tuple continuation now delegates to a parameter match; pure `parsed_module`, `check_modules`, `emit_modules` exports retain the shared boundary.

Runtime smoke: **9 assertions PASS**, exact current Template function bodies (`leading_template_count`, `take_template_args`, `drop_args`, `wrapped_prefix`) compiled from a dependency-ordered independent smoke book with complete native validation. Covers leading-prefix termination, wrapped-argument extraction, non-template/missing arguments, zero count, drop exhaustion and prefix termination. This is not whole-Template/driver validation or target integration.

The repaired entire driver closure loaded successfully: **1353 declaration events**. Unchanged native validation, **zero exclusions**, then stopped at declaration535, `template.collect_templates`:

```text
bend2/selfhost/template.bend:65
List.append(&2, TemplateDef, collect_template_decls(namespace, imports, top_keys(declarations), declarations), collect_templates(rest))
expected: a defined name
observed: collect_template_decls
```

Current classification: **B. CHECKER FIRST BLOCKER**, dependency native-validation/name-resolution boundary, not a target selfhost Checker diagnostic. Guard peak footprint353108832 B /RSS391921664 B;47.160s; worker exit2. Not RESOURCE_LIMIT. Native validation did not complete; codegen, target Checker/JSEmit corpus, real/imported target, stage1 and stage2 were not reached. No TS target-semantic substitution and no new unsafe/check exclusions. Frozen parser/kernel/compiler unchanged.

Evidence: `compiled-frontend-syntax-repair-result.json`, `frontend-syntax-repair-smoke.json`, archived smoke harness and cumulative `compiled-frontend-build.jsonl`. The next prerequisite is the Template declaration-name ordering/reference contract, not parser syntax or memory productionization.

## CheckerCore diagnostic strategy: first ownership blocker, bootstrap census incomplete

Template remains deferred; no SCC rewrites. Exact `check_modules` source closure extracted:416/418 definitions, excluding only `check` and `check_template_result`; zero Template dependencies. Diagnostic entry is explicitly **CHECK ALREADY-TEMPLATE-EXPANDED MODULES**, not full `Checker.check`.

Native component load PASS918 events; full unchanged native validation with zero exclusions stops at index503, `checker_core_slice.fail`: `span (consumed more than once)`. Original body uses span both in `span_file(span)` and Diagnostic's span field. No quantities/semantics patched. JSEmit build and six-case runtime corpus not reached.

Actual bootstrap census uses the unchanged accepted compiled parser artifact. Ten modules discovered via parsed module/import prefixes;3 full parses PASS (19 declarations, zero template constructs there),7 full-source ParseFailures. Whole-bootstrap declaration/template totals unknown: **neither T0 nor T1 established**. First failure is the accepted generated parser implementation at byte26151/line298; other failures include Base, exact CheckerCore slice, JSEmit, Lexer, Core and Path. No regex census, host semantic substitution or parser repair.

Full report and exact evidence: `checker-core-integration.md`, `checker-core-integration-result.json`, `checker-core-build.result.json`, `checker-core-dependency.json`, complete `checker-core-ordering-audit.md/.json`, `bootstrap-template-census.json` and failure/guardian companions. Frozen parser/kernel/compiler/generator unchanged. **SELFHOST GREEN: NO.**
