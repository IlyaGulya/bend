# Bend: действительное состояние сборки

Integration owner: основной агент. Branch: `selfhost/parser-reproducible-20261006`.
Подтверждённый baseline: `a03f19f522de50f77615517803241ea61eabaa09`; data-contract snapshot: `a6bf6204`; актуальный diagnostic source/callers/команды/отчёты: `f6070aa2`. Авторизованный atom scope: `f16d4db3`, `2c839b0d`; source-shape refinements: `82fa42e2`, `2f498f3d`. Чужой draft ARCHITECTURE/changelog entry не включён; собственные docs сохранены отдельно.

| Источник | SHA256 |
|---|---|
| canonical `bend2/selfhost/parser.bend` | `f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df` |
| candidate `parser_full_generated_fuel.bend` | `b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e` |
| kernel `bend2/bend.ts` | `47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9` |
| generator `evals/parser_full_generate.ts` | `0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6` |
| compiler/runtime `bend2/comp.ts` | `0939b98d013ab58d82619e35c0d4900b72c9d8e5b478f0e1df7822fe713c9b48` |
| последний diagnostic canonical-copy `.parser_atom_action_shape_source.bend` | `de160e70450fa83658665163c254a414dae75b8dd023ebb0282d08db2347b3cc` |
| его normally generated `_fuel.bend` | `a2a13e3293ebc91c473a4580ead59cb472ebc328fb2c6587a0fce9ae44129b4e` |

## Последнее подтверждённое выполнение по этапам

| Этап | Сохранённая команда / результат | Toolchain и предел доказательства |
|---|---|---|
| Regeneration | `bun evals/parser_local_shape_build.ts`: preparation PASS; source de160→candidate a2a13; затем ordinary build RESOURCE_LIMIT. | Два atom dispatch helpers + symbol rows; typed scanner selectors/control. Обычная generator logic, четыре invertible input/path/hash/metadata redirects; protected sources неизменны. |
| Load | `BEND_PARSER_REPORT_PREFIX=checkpoints/parser-atom-action-smol-proposal bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun --smol evals/parser_local_shape_build.ts --build-proposal`: load PASS1322. | Temporary direct loader proposal, native e retained; **не production acceptance**. Ordinary load по-прежнему RESOURCE_LIMIT. |
| Full validation | Тот же a2a13 candidate, `book_valid` с0: `step_parse_atom_scan` index694 и recursive `pattern_scan` index747 вернулись; остановка index758 `step_parse_body_scan`, footprint3222801264 B /RSS2856026112 B, exit73. | Полная проверка начата без исключения order events и без discard-E, но **не завершена**. Fresh atomic row9 native target PASS, footprint686163048 B; trusted prefix только диагностический. |
| Aligned target | `bun evals/pattern_scan_aligned_probe.ts`: complete load PASS1280; target FAIL decreasing-self-call после изменения mode перед shrinking tokens. | Единственная audited aligned-проба; source/helpers не выбраны как принятый fix. |
| Parser comparison | `bun evals/parser_full_fuel_smoke.ts --fuel=1000 --expanded --streaming --gc --canonical-timeout-ms=60000`: PASS29 acceptance/semantic/generated↔canonical; diagnostics/spans23cases/46differences. | `B.term_wnf` над lazy raw Bodies; **не выпущенный JS parser**. `canonical-ownership-family-d-streaming-expanded.json`. 29/29 — покрытый корпус, не полная эквивалентность языка. |
| Source-only swap | `bun evals/pattern_scan_source_controls.ts`: original6/6+38oracles PASS, swapped6/6 native-load consumed-binder errors. `bun evals/pattern_scan_swap_load.ts`: та же ошибка в real candidate. | Строго source-only permutation невалидна; target не достигнут. |
| JS codegen / released parser / compiled29 | **Результатов нет.** | Нет единого принятого пути regeneration→full check→codegen→execution. |
| Loader proposal controls | `bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun evals/proposed_loader_regressions.ts`: PASS; native whole453 + actual JS1233, одинаковый artifact hash; invalid type/decrease отвергнуты обоими kernels. | Три маленьких semantic regressions; отдельный `proposed-loader-patch.json`, **не применён**, не whole-parser proof. |
| HYBRID boundary | Существующий `gates/hybrid_gate.ts`: host AST conversion PASS boundary, runner compile RESOURCE_LIMIT RSS3226812416 B, exit73. Compiled pure-contract smoke returns `"module-contract-ok"`; invalid Ast.Module rejected. | `LoadedModule` вынесен; Checker/JSEmit runtime, parity, stage1/stage2 не достигнуты. |

## Blocker и следующий ограниченный шаг

Текущая граница P: ordinary load всё ещё превышает3GiB; последний direct-load retained-e whole-check проходит atom/scanner declarations, но останавливается на **`step_parse_body_scan` index758**. Перенос исходной логики в typed helpers снимает прежние stopping declarations, но accepted end-to-end fix и JS parser artifact **отсутствуют**. Старые29/29 не приписаны новым copies. Actual commands/guardians/hashes: `parser-execution-results.json`, `atom-source-shape-results.json`; все source snapshots в Git.

Авторизованный пользователем diagnostic `parse_atom_scan` scope выполнен: source-copy, normal regeneration, actual whole-check без exclusions, exact branch/capture audit; success не предполагался. Следующий source-only bounded шаг — аналогичный local factoring **`parse_body_scan`**, вне этого explicit atom scope; нужно новое scope decision. Отдельный loader proposal остаётся неприменённым и требует human-owner review; ассистент не редактирует `bend2/bend.ts`. Ни temporary kernel, ни discard-E не стали production toolchain. Один heavy process,3072MiB physical+RSS,10ms; runtime flags и случайный2048MiB target run раскрыты в evidence.

**Milestone P: не достигнут. SELFHOST GREEN: no.**
