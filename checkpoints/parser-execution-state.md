# Bend: действительное состояние сборки

Integration owner: основной агент. Branch: `selfhost/parser-reproducible-20261006`.
Подтверждённый baseline: `a03f19f522de50f77615517803241ea61eabaa09`; data-contract snapshot: `a6bf6204`; atom/pattern snapshot: `f6070aa2`. Новый scanner scope: body `51a5d01a`, case `7db368a9`, typed-do `b7bdb575`, array/current commands/results `3d5bde55`. Чужой draft ARCHITECTURE/changelog entry не включён; собственные docs сохранены отдельно.

| Источник | SHA256 |
|---|---|
| canonical `bend2/selfhost/parser.bend` | `f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df` |
| candidate `parser_full_generated_fuel.bend` | `b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e` |
| kernel `bend2/bend.ts` | `47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9` |
| generator `evals/parser_full_generate.ts` | `0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6` |
| compiler/runtime `bend2/comp.ts` | `0939b98d013ab58d82619e35c0d4900b72c9d8e5b478f0e1df7822fe713c9b48` |
| последний diagnostic canonical-copy `.parser_array_shape_source.bend` | `b5a5ca3a2efd3328790eb6da5620ebd77f6fa34ae1ff05fa66e43117d584762d` |
| его normally generated `_fuel.bend` | `70c4ac9d2d35d181318443508395cd40dffa4aecc14c86952621389047d13fa6` |

## Последнее подтверждённое выполнение по этапам

| Этап | Сохранённая команда / результат | Toolchain и предел доказательства |
|---|---|---|
| Regeneration | `bun evals/parser_local_shape_build.ts`: preparation PASS; source b5a5→candidate70c4; ordinary build RESOURCE_LIMIT, footprint3221457800 B, exit73. | Typed atom/pattern/body/case/do/array scanner helpers; original branches/priority/captures, exact source inverses. Generator logic и protected sources неизменны. |
| Load | `BEND_PARSER_DECL_GC=1 BEND_PARSER_REPORT_PREFIX=checkpoints/parser-array-gc-proposal bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun --smol evals/parser_local_shape_build.ts --build-proposal`: complete load returned. | Temporary direct loader proposal, native e retained; **не production acceptance**. Ordinary load всё ещё RESOURCE_LIMIT. |
| Full validation | Тот же70c4 candidate, native `book_valid` с0 без exclusions: body/case/do/array stopping declarations вернулись; новая остановка index1040 **`map_operator_key`**, footprint3226372976 B /RSS3112255488 B,394.621s, exit73. | Полная проверка начата, но **не завершена**. Disclosed runtime policy: `--smol` + явный `Bun.gc(true)` между декларациями; checked e не удалён. GC-only probe ранее достиг array scanner index997; это не JS execution. |
| Aligned target | `bun evals/pattern_scan_aligned_probe.ts`: complete load PASS1280; target FAIL decreasing-self-call после изменения mode перед shrinking tokens. | Единственная audited aligned-проба; source/helpers не выбраны как принятый fix. |
| Parser comparison | `bun evals/parser_full_fuel_smoke.ts --fuel=1000 --expanded --streaming --gc --canonical-timeout-ms=60000`: PASS29 acceptance/semantic/generated↔canonical; diagnostics/spans23cases/46differences. | `B.term_wnf` над lazy raw Bodies; **не выпущенный JS parser**. `canonical-ownership-family-d-streaming-expanded.json`. 29/29 — покрытый корпус, не полная эквивалентность языка. |
| Source-only swap | `bun evals/pattern_scan_source_controls.ts`: original6/6+38oracles PASS, swapped6/6 native-load consumed-binder errors. `bun evals/pattern_scan_swap_load.ts`: та же ошибка в real candidate. | Строго source-only permutation невалидна; target не достигнут. |
| JS codegen / released parser / compiled29 | **Результатов нет.** | Нет единого принятого пути regeneration→full check→codegen→execution. |
| Loader proposal controls | `bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun evals/proposed_loader_regressions.ts`: PASS; native whole453 + actual JS1233, одинаковый artifact hash; invalid type/decrease отвергнуты обоими kernels. | Три маленьких semantic regressions; отдельный `proposed-loader-patch.json`, **не применён**, не whole-parser proof. |
| HYBRID boundary | Существующий `gates/hybrid_gate.ts`: host AST conversion PASS boundary, runner compile RESOURCE_LIMIT RSS3226812416 B, exit73. Compiled pure-contract smoke returns `"module-contract-ok"`; invalid Ast.Module rejected. | `LoadedModule` вынесен; Checker/JSEmit runtime, parity, stage1/stage2 не достигнуты. |

## Blocker и следующий ограниченный шаг

Текущая граница P: ordinary load всё ещё превышает3GiB; последний direct-load retained-e whole-check проходит прежние scanner frontiers, но останавливается на **`map_operator_key` index1040**. Это string/operator mapping, не token scanner. Accepted end-to-end fix и JS parser artifact **отсутствуют**. Старые29/29 не приписаны новым copies. Actual commands/guardians/hashes: `parser-execution-results.json`, `atom-source-shape-results.json`, `body-case-source-shape-guardians.json`; source snapshots и команды в Git.

Пользователь авторизовал remaining actual scanner blockers после `parse_body_scan`: выполнены source-only factoring body→case→typed-do→array, normal generation и actual whole native checks. Следующий stopping helper `map_operator_key` вне scanner-only scope: нужен новый scope decision. Loader proposal остаётся неприменённым и требует human-owner review; ассистент не редактирует `bend2/bend.ts`. Ни temporary kernel, ни discard-E не стали production toolchain. Один heavy process,3072MiB physical+RSS,10ms; runtime flags/GC раскрыты в evidence.

**Milestone P: не достигнут. SELFHOST GREEN: no.**
