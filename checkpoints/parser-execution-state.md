# Bend: действительное состояние сборки

Integration owner: основной агент. Branch: `selfhost/parser-reproducible-20261006`.
Подтверждённый baseline: `a03f19f522de50f77615517803241ea61eabaa09`; актуальный snapshot source/callers/команд/отчётов: `a6bf6204`; промежуточные measured source-снимки: `7bfecdbd`, `ea43e348`. Исходный HEAD: `0d0e204f890fe1b125e72b47ca872f510219bb4d`. Чужой draft ARCHITECTURE и changelog entry не включены; собственные documentation changes staged отдельно.

| Источник | SHA256 |
|---|---|
| canonical `bend2/selfhost/parser.bend` | `f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df` |
| candidate `parser_full_generated_fuel.bend` | `b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e` |
| kernel `bend2/bend.ts` | `47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9` |
| generator `evals/parser_full_generate.ts` | `0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6` |
| compiler/runtime `bend2/comp.ts` | `0939b98d013ab58d82619e35c0d4900b72c9d8e5b478f0e1df7822fe713c9b48` |
| последний diagnostic canonical-copy `.pattern_scan_fields_source.bend` | `8eec93e0780cd25ac1c13f0d6965647b4644789e1b7371438c6563417d20a1ed` |
| его normally generated `_fuel.bend` | `7202d40d13388616430314faa81dd6d02c1d01c5b4bb8f896fb915078515af0c` |

## Последнее подтверждённое выполнение по этапам

| Этап | Сохранённая команда / результат | Toolchain и предел доказательства |
|---|---|---|
| Regeneration | `bun evals/parser_local_shape_build.ts`: preparation PASS, затем build RESOURCE_LIMIT; source8eec→candidate7202. | Обычная generator logic; четыре invertible input/path/hash/metadata redirects к canonical-copy. Protected sources не изменены. |
| Load | `bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun evals/parser_local_shape_build.ts --build-proposal`: load PASS1304. | Временный direct-load kernel, retaining native e; **не production acceptance**. Ordinary load и отдельный `--smol` run превышают3GiB. |
| Full validation | Тот же7202 candidate: RESOURCE_LIMIT index679 `step_parse_atom_scan`, footprint3240020848 B /RSS3019620352 B, exit73. | Полный `book_valid` с0, без исключения order events и без discard-E; не PASS. |
| Aligned target | `bun evals/pattern_scan_aligned_probe.ts`: complete load PASS1280; target FAIL decreasing-self-call после изменения mode перед shrinking tokens. | Единственная audited aligned-проба; source/helpers не выбраны как принятый fix. |
| Parser comparison | `bun evals/parser_full_fuel_smoke.ts --fuel=1000 --expanded --streaming --gc --canonical-timeout-ms=60000`: PASS29 acceptance/semantic/generated↔canonical; diagnostics/spans23cases/46differences. | `B.term_wnf` над lazy raw Bodies; **не выпущенный JS parser**. `canonical-ownership-family-d-streaming-expanded.json`. 29/29 — покрытый корпус, не полная эквивалентность языка. |
| Source-only swap | `bun evals/pattern_scan_source_controls.ts`: original6/6+38oracles PASS, swapped6/6 native-load consumed-binder errors. `bun evals/pattern_scan_swap_load.ts`: та же ошибка в real candidate. | Строго source-only permutation невалидна; target не достигнут. |
| JS codegen / released parser / compiled29 | **Результатов нет.** | Нет единого принятого пути regeneration→full check→codegen→execution. |
| Loader proposal controls | `bun evals/heavy_gate.ts --memory-mib=3072 --rss-mib=3072 --poll-ms=10 -- bun evals/proposed_loader_regressions.ts`: PASS; native whole453 + actual JS1233, одинаковый artifact hash; invalid type/decrease отвергнуты обоими kernels. | Три маленьких semantic regressions; отдельный `proposed-loader-patch.json`, **не применён**, не whole-parser proof. |
| HYBRID boundary | Существующий `gates/hybrid_gate.ts`: host AST conversion PASS boundary, runner compile RESOURCE_LIMIT RSS3226812416 B, exit73. Compiled pure-contract smoke returns `"module-contract-ok"`; invalid Ast.Module rejected. | `LoadedModule` вынесен; Checker/JSEmit runtime, parity, stage1/stage2 не достигнуты. |

## Blocker и следующий ограниченный шаг

Текущая граница P: обычный loader превышает3GiB; direct-load full retaining-e check последнего candidate также не завершается. `--smol` не снял load blocker (footprint3226176368 B, exit73). Accepted compilation-shape fix и JS parser artifact **отсутствуют**; command regeneration→check→codegen сохранён, но завершённого end-to-end command с execution/comparison нет. Старые29/29 не приписаны новым diagnostic copies. Все команды/guardians/hashes: `parser-execution-results.json`; source copies и отчёты в Git.

Следующий ограниченный шаг: отдельный review/authorization exact loader proposal владельцем human-written `bend2/bend.ts`; ассистент этот файл не редактирует. Proposal снимает replay только в диагностических опытах и **не решает** уже измеренный full-check ceiling. Для дальнейшей правки вне локального `pattern_scan` нужен отдельно согласованный scope; никакой временный kernel не установлен как production toolchain. Lane остаётся один heavy process,3072MiB physical+RSS,10ms; случайный2048MiB target run явно исключён из required-budget evidence и заменён recorded3072MiB run.

**Milestone P: не достигнут. SELFHOST GREEN: no.**
