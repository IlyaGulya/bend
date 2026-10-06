# Bend: действительное состояние сборки

Integration owner: основной агент. Branch: `selfhost/parser-reproducible-20261006`.
Подтверждённый Git-снимок источников/зависимостей/evidence: `a03f19f522de50f77615517803241ea61eabaa09`; исходный HEAD: `0d0e204f890fe1b125e72b47ca872f510219bb4d`. Не относящиеся к этому снимку изменения рабочего дерева не включены. Manifest: `parser-execution-baseline.json`.

| Источник | SHA256 |
|---|---|
| canonical `bend2/selfhost/parser.bend` | `f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df` |
| candidate `parser_full_generated_fuel.bend` | `b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e` |
| kernel `bend2/bend.ts` | `47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9` |
| generator `evals/parser_full_generate.ts` | `0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6` |
| compiler/runtime `bend2/comp.ts` | `0939b98d013ab58d82619e35c0d4900b72c9d8e5b478f0e1df7822fe713c9b48` |

## Последнее подтверждённое выполнение по этапам

| Этап | Сохранённая команда / результат | Toolchain и предел доказательства |
|---|---|---|
| Regeneration | `parser_full_generated_fuel.bend.scorecard.json`: emitted215 bodies,760defs, exceptions0; hash candidate совпадает. Историческое argv в scorecard отсутствует; восстановимая команда `bun evals/parser_full_generate.ts --fuel-parametric` **не выдаётся за сохранённый execution log**. | Обычный generator/source AST; не полный check. |
| Load | `bun evals/load_replay_probe.ts load`: PASS1280; peak935740688 B footprint /958332928 B RSS. | Временный direct-load kernel; не обычный loader. `load-replay-guardians.json`. |
| Full validation | **PASS отсутствует для текущего candidate.** `bun evals/load_replay_probe.ts validation`: RESOURCE_LIMIT index678 `step_parse_atom_scan`; discard-E diagnostic reaches705 `pattern_scan`. | Direct load, native checker; discard-E не содержит необходимого backend checked output. |
| Target validation | `bun evals/pattern_scan_memory_probe.ts`: RESOURCE_LIMIT; fresh native done705; target peak3223096152 B. | Trusted prefix только диагностический; не whole validation. |
| Parser comparison | `bun evals/parser_full_fuel_smoke.ts --fuel=1000 --expanded --streaming --gc --canonical-timeout-ms=60000`: PASS29 acceptance/semantic/generated↔canonical; diagnostics/spans23cases/46differences. | `B.term_wnf` над lazy raw Bodies; **не выпущенный JS parser**. `canonical-ownership-family-d-streaming-expanded.json`. 29/29 — покрытый корпус, не полная эквивалентность языка. |
| Source-only swap | `bun evals/pattern_scan_source_controls.ts`: original6/6+38oracles PASS, swapped6/6 native-load consumed-binder errors. `bun evals/pattern_scan_swap_load.ts`: та же ошибка в real candidate. | Строго source-only permutation невалидна; target не достигнут. |
| JS codegen / released parser / compiled29 | **Результатов нет.** | Нет единого принятого пути regeneration→full check→codegen→execution. |

## Blocker и следующий ограниченный шаг

Единственный текущий parser blocker: размер проверки реального `pattern_scan` в3GiB lane; ordinary load также требует ранее выявленного replay обхода P1, который **не production toolchain**. Full aligned formals/actuals/columns target ещё не измерен; разрешён ровно один диагностический прогон через нормальную генерацию из временного source, с аудитом всех вызовов/quantities/приоритета. PASS target не считается Milestone P. Если проба не снимает blocker, следующий разрешённый source-подход — локальные типизированные scanner helpers; generic match/compiler/checker не меняются. Production loader patch требует отдельного согласования.

**Milestone P: не достигнут. SELFHOST GREEN: no.**
