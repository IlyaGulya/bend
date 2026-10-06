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
| Full validation / codegen |822e candidate: native `book_valid` с0 **PASS1478/1478**, `e` retained, checks excluded0; затем normal `Comp.js_lib` RESOURCE_LIMIT, footprint3228928880 B /RSS3075424256 B,427.395s, exit73, artifact не записан. Повтор с phase-boundary GC остановился раньше: validation index1347 `step_parse_definition_typed_colon`, footprint3221752760 B,363.229s. | Disclosed runtime policy: `--smol` + `Bun.gc(true)` между декларациями. GC на validation→codegen границе в повторе **не достигнут**; его эффект неизвестен. Полный native PASS относится только к сохранённому запуску822e. |
| Aligned target | `bun evals/pattern_scan_aligned_probe.ts`: complete load PASS1280; target FAIL decreasing-self-call после изменения mode перед shrinking tokens. | Единственная audited aligned-проба; source/helpers не выбраны как принятый fix. |
| Parser comparison | `bun evals/parser_full_fuel_smoke.ts --fuel=1000 --expanded --streaming --gc --canonical-timeout-ms=60000`: PASS29 acceptance/semantic/generated↔canonical; diagnostics/spans23cases/46differences. | `B.term_wnf` над lazy raw Bodies; **не выпущенный JS parser**. `canonical-ownership-family-d-streaming-expanded.json`. 29/29 — покрытый корпус, не полная эквивалентность языка. |
| Source-only swap | `bun evals/pattern_scan_source_controls.ts`: original6/6+38oracles PASS, swapped6/6 native-load consumed-binder errors. `bun evals/pattern_scan_swap_load.ts`: та же ошибка в real candidate. | Строго source-only permutation невалидна; target не достигнут. |
| JS parser / compiled29 | **Parser artifact и результатов нет.** Isolated actual compiled helpers: operator66, imports16, pair27, triple18 cases PASS. | Маленькие helper programs прошли whole native check + JS execution; **не весь parser**, не новая атрибуция старых29/29. |
| Loader proposal controls | `bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun evals/proposed_loader_regressions.ts`: PASS; native whole453 + actual JS1233, одинаковый artifact hash; invalid type/decrease отвергнуты обоими kernels. | Три маленьких semantic regressions; отдельный `proposed-loader-patch.json`, **не применён**, не whole-parser proof. |
| HYBRID boundary | Существующий `gates/hybrid_gate.ts`: host AST conversion PASS boundary, runner compile RESOURCE_LIMIT RSS3226812416 B, exit73. Compiled pure-contract smoke returns `"module-contract-ok"`; invalid Ast.Module rejected. | `LoadedModule` вынесен; Checker/JSEmit runtime, parity, stage1/stage2 не достигнуты. |

## Blocker и следующий ограниченный шаг

Текущая граница P: ordinary load всё ещё превышает3GiB. Diagnostic direct-load pipeline впервые завершил **whole native check1478/1478 с сохранённым e**, но остановился в **normal JS codegen** до записи artifact. Старые29/29 не приписаны новым copies. Sources/commands/traces/guardians в Git; consolidated guards: `body-case-source-shape-guardians.json`. Native shape fixes выбраны лишь как diagnostic candidate, не end-to-end production fix.

Первый whole native PASS не дал устойчивого fresh-run pipeline: повтор остановился в validation раньше codegen. Source-only typed-colon Bool probe: normal regeneration PASS, candidate3feffbdb; ordinary load RESOURCE_LIMIT; diagnostic direct load PASS1482, retained-e validation RESOURCE_LIMIT на index1228 `step_parse_operator_right_named`, footprint3221457776 B /RSS3043803136 B,288.433s, exit73. Phase GC и codegen не достигнуты; эффект phase GC неизвестен. Новый candidate не наследует PASS822e или старые29/29. Protected hashes совпали; owned temporary kernel удалён. Дальнейшее speculative source factoring остановлено: остановочная декларация сама по себе не доказывает причину process growth; отдельный storage-investigation scope требуется до compiler/storage изменений. Loader proposal неприменён; `bend2/bend.ts` не редактируется. Один heavy process,3072MiB physical+RSS,10ms. **SELFHOST GREEN: no.**

**Milestone P: не достигнут. SELFHOST GREEN: no.**
