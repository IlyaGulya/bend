# Bend: действительное состояние сборки

Integration owner: основной агент. Branch: `selfhost/parser-reproducible-20261006`.
Подтверждённый baseline: `a03f19f522de50f77615517803241ea61eabaa09`; data-contract: `a6bf6204`; atom/pattern: `f6070aa2`; scanner/source-blocker history сохранён отдельными snapshots. Последний **полностью native-checked** source/candidate/commands/results: `d746e7cc`. Compiled helper proofs: operator `e3bd5070`, import worker `fdde79f5`, pair `1c977f67`, triple `7c1758cd`. Чужой ARCHITECTURE/changelog draft не включён.

| Источник | SHA256 |
|---|---|
| canonical `bend2/selfhost/parser.bend` | `f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df` |
| candidate `parser_full_generated_fuel.bend` | `b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e` |
| kernel `bend2/bend.ts` | `47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9` |
| generator `evals/parser_full_generate.ts` | `0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6` |
| compiler/runtime `bend2/comp.ts` | `0939b98d013ab58d82619e35c0d4900b72c9d8e5b478f0e1df7822fe713c9b48` |
| последний diagnostic canonical-copy `.parser_definition_body_shape_source.bend` | `1e22bf833759ee476a70883b728fb6d374e9da014b2839f2713a15f17bb28c5a` |
| его normally generated `_fuel.bend` | `822e8460ff94ff3f00695e27f5b4fe4dbd3515ae4d6d5c3b3c5eb7c1867b840e` |

## Последнее подтверждённое выполнение по этапам

| Этап | Сохранённая команда / результат | Toolchain и предел доказательства |
|---|---|---|
| Regeneration | `bun evals/parser_local_shape_build.ts`: preparation PASS; source1e22→candidate822e; ordinary build RESOURCE_LIMIT, footprint3229469576 B, exit73. | Diagnostic source helpers + unchanged grammar/priority/ABI; native ownership corrections, exact inverse audits. Generator logic и protected sources неизменны. |
| Load | `BEND_PARSER_DECL_GC=1 BEND_PARSER_REPORT_PREFIX=checkpoints/parser-definition-body-gc-proposal bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun --smol evals/parser_local_shape_build.ts --build-proposal`: complete load PASS1478. | Temporary direct loader proposal; **не production acceptance**. Ordinary load всё ещё RESOURCE_LIMIT. |
| Full validation / codegen | Fixed822e: whole native validation **PASS1478/1478**, retained e, excluded0; temporary JS per-definition emit/release produced artifact30521142 B, SHA0726b631… under8GiB. Validation footprint3246754672 B /RSS3064528896 B; codegen sampled footprint4892119192 B /RSS4710875136 B; whole process-tree peak4924035248 B. | J2: h retains backing e. Exact preparation and existing js_def reused; e/h released after per-definition emission, diagnostic GC disclosed. Production comp.ts unchanged; normal8GiB failure retained as separate evidence. |
| Aligned target | `bun evals/pattern_scan_aligned_probe.ts`: complete load PASS1280; target FAIL decreasing-self-call после изменения mode перед shrinking tokens. | Единственная audited aligned-проба; source/helpers не выбраны как принятый fix. |
| Parser comparison | `bun evals/parser_full_fuel_smoke.ts --fuel=1000 --expanded --streaming --gc --canonical-timeout-ms=60000`: PASS29 acceptance/semantic/generated↔canonical; diagnostics/spans23cases/46differences. | `B.term_wnf` над lazy raw Bodies; **не выпущенный JS parser**. `canonical-ownership-family-d-streaming-expanded.json`. 29/29 — покрытый корпус, не полная эквивалентность языка. |
| Source-only swap | `bun evals/pattern_scan_source_controls.ts`: original6/6+38oracles PASS, swapped6/6 native-load consumed-binder errors. `bun evals/pattern_scan_swap_load.ts`: та же ошибка в real candidate. | Строго source-only permutation невалидна; target не достигнут. |
| JS parser / compiled29 | **COMPILED EXPLICIT-FUEL SELFHOST PARSER**: `checkpoints/parser-explicit-fuel-822e8460.js`; tiny6/6, new compiled-JS acceptance29/29, normalized semantics29/29, real `bend2/selfhost/ast.bend` accepted at explicit fuel200000. Execution guardian PASS, peak footprint294110648 B /RSS351158272 B,9.842s. | Actual emitted JS executed in isolated workers, no parser evaluator seam. `parser-compiled-whole29.json`; accepted cases normalized, rejected cases matched rejection. Production loader not cut over; automatic fuel and bootstrap remain unproved. |
| Loader proposal controls | `bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun evals/proposed_loader_regressions.ts`: PASS; native whole453 + actual JS1233, одинаковый artifact hash; invalid type/decrease отвергнуты обоими kernels. | Три маленьких semantic regressions; отдельный `proposed-loader-patch.json`, **не применён**, не whole-parser proof. |
| HYBRID boundary | Существующий `gates/hybrid_gate.ts`: host AST conversion PASS boundary, runner compile RESOURCE_LIMIT RSS3226812416 B, exit73. Compiled pure-contract smoke returns `"module-contract-ok"`; invalid Ast.Module rejected. | `LoadedModule` вынесен; Checker/JSEmit runtime, parity, stage1/stage2 не достигнуты. |

## Compiled parser checkpoint и следующий этап

Active baseline remains `d746e7cc` / candidate822e8460. **COMPILED EXPLICIT-FUEL SELFHOST PARSER reached** through diagnostic direct load and JS-only consuming lifetime prototype. Original codegen growth occurred inside carb_book reachable traversal, before emission/assembly. Clearing e alone left backing WeakRefs alive with h; clearing h removed them and lowered live heap123839769/160007592 B, though committed footprint did not immediately fall. Five fixture books had byte-identical JS/runtime parity for existing per-definition emit/release, including recursive calls, raised arity and global tables.

Full build guardian PASS: total2538.792s, peak footprint4924035248 B /RSS4710875136 B. Maximum stored definition slots e1288/h197 (not unique live term graph counts). Final source assembly added33783832 B in26.523ms; existing join unchanged. `js-storage-decision.json` records J2 and artifact/compiled29 proof. Temporary compiler/build/fixture/execution sources and guards preserved; production kernel/compiler, parser, generator, checker, quantities, match compilation and fuel unchanged. No more parser optimization. Next subsystem is compiled parser → selfhost checker → selfhost JS emitter; no new bootstrap claim. **SELFHOST GREEN: no.**

**Compiled explicit-fuel parser milestone: reached, diagnostic direct-load JS lifetime build. SELFHOST GREEN: no.**
