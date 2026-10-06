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

Next bounded step: the separately recorded production-loader proposal requires human-owner review/authorization. Small compiled priority/type/decrease regressions pass for that proposal, but whole retained-e parser validation still hits3GiB; the proposal alone does not establish P or bootstrap. No new frontend or permanent temporary kernel was introduced.
