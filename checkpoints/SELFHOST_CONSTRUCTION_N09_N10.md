# N09–N10: construction boundary и изолированный Bun RAM hint

**Оба опыта исполнены. Accepted compiler остаётся G24R12.**
Production source, compiler acceptance и исходные qualification limits не
менялись. Предыдущий checkpoint — `f021f2ae`; исторические rejected G34–G39
не переименованы в accepted. Source-кандидат не допущен.

Exact commands, runtime versions/hashes, guards, исходные source authorities,
первое расхождение и проверка baseline:
[`construction_n09_n10_completed.json`](../evals/receipts/construction_n09_n10_completed.json).

## N09 — первое расхождение локализовано, не объявлено причиной OOM

Вместо прежнего раннего префикса каждый source lane наблюдался до
**250 000 событий**. Оба полных book validations проверили **12 456 definitions /
13 050 events** без exclusions/patches. Первый C fact pass завершён; второй
пройден только до `String.is_empty`. **Второй pass не завершён**: сработал
заранее заданный event budget, раньше целевой pass-2 boundary.

Первые **129 878** structural events совпадают. Следующее событие:

- stage `c-definition-after`, pass 1;
- native declaration `emitter_steps_v1:emitter_body_cps_provider_8_js_runtime`;
- canonical source origin `bend2/selfhost/js_backend.bend::js_runtime`.

| Поле на первом расхождении | R12 | G39 | Delta |
| --- | ---: | ---: | ---: |
| literalFacts | 85 622 | 85 843 | +221 |
| imageWords | 170 771 | 171 213 | +442 |
| constantKeys | 77 087 | 77 529 | +442 |

Source-only проверка декодированных ASCII literals объясняет эти deltas
добавленным содержимым строки. После второй изменённой runtime declaration
pass-1 boundary содержит суммарно **+245 literal entries / +490 image words**.
`ctr_build` (`bend2/comp.ts:1387–1396`) интернирует static fields через
`FL.lits` и добавляет их в `FL.img`; `constantKeys` считает записи per-layout
maps, а не bytes (`1927–1932`). Scope release очищает эти maps (`1997–2010`).

Streaming verifier сравнил оба полных префикса: отличаются только эти три
state fields; все прочие наблюдаемые scalar/nested state fields равны.
Соотношение image delta и literal-entry delta проверено на каждом событии.
Числа segments/spins/facts/layouts и pass-1 segment line/text totals не
расходятся. Это **равенство наблюдаемых размеров**, не графов, AST, semantic
behavior, allocations или retained bytes.

Disposition: первое расхождение объясняется literal image growth;
**основания для production IR/retention fix не получено**.

### Protocol erratum

Неизменённый исполненный N09 plan унаследовал поле `cutoff` с prose от N04
(first pass / ранний event cutoff). Новые числовые `prefix` fields и pinned
worker callback до запуска задавали другой, фактически исполненный бюджет:
pass 2 либо early convergence, event/time cutoff. Исполненный plan не исправлен
задним числом. Оба текста и их precedence сохранены в ledger как явный erratum.

## N10 — гипотеза обязательного раннего OOM без hint не подтвердилась

Четыре distinct cells исполнены по одному разу, последовательно, до одного
source-mapped события N09. Только `BUN_JSC_forceRAMSize` изменялся между
условиями: установлен в `4294967296` либо **явно удалён** из child environment.
Bun executable, child argv, sources, numeric event/time budgets и guardian
одинаковы. Это новый изолированный intervention, не реконструкция неизвестного
historical child environment.

| Source | RAM hint | Target reached | Peak RSS, GiB | Peak footprint, GiB |
| --- | --- | --- | ---: | ---: |
| R12 | 4 GiB | да | 4.033 | 3.939 |
| G39 | 4 GiB | да | 4.078 | 3.922 |
| R12 | явно unset | да | 5.680 | 5.952 |
| G39 | явно unset | да | 5.800 | 5.765 |

У каждого source-варианта все **129 879** structural events совпадают между
hint/unset: проверены canonical stream SHA-256. Они также совпадают с тем же
source-префиксом N09. Проверены actual child environment и empty `execArgv`;
различие RSS не объясняется достижением другой compiler phase или другими
наблюдаемыми state counts.

Disposition: **STOP_HINT_NOT_NECESSARY_AT_OBSERVED_BOUNDARY**. В этой матрице
sampled peak RSS с hint ниже, но его отсутствие не вызывает обязательный
cap failure до выбранной границы. Это single fixed-order matrix, не benchmark
или statistical replication. Нельзя экстраполировать её на полный build,
объявлять hint hard heap quota или приписывать historical G36–G39 failures
явно unset environment: оно остаётся **UNKNOWN**.

## Исполнение и проверка

Все **шесть** Bun construction children завершились с guardian PASS, без
финальной сборки и публикации C translation unit. Per-definition C segment text
действительно строится; protocol shorthand «before C render» означает только
финальную сборку translation unit. Каждый child выполнил полный book validation.
Общий guard сохранён: RSS и physical footprint **8 192 MiB**, poll **10 ms**,
timeout **600 000 ms**. Дополнительный diagnostic codegen budget — **120 000 ms**
на существующем observer seam; он не заменяет внешний guard и не может
прервать definition изнутри. Manual GC, profiler, code patches, output patches,
parser/stack/ABI изменения не применялись. Parent `--smol` не выдаётся за
child flag: actual child `execArgv` пуст.

Исполненные входные точки:

```sh
BUN=/Users/ilyagulya/bend-g12-borrow-7782b78a-1e88-4ffd-9889-14cb52c6a5b9/.tools/bun
W9=/private/tmp/bend-n09-construction-D6asDJ
W10=/private/tmp/bend-n10-hint-LVnOUZ
"$BUN" --smol "$W9/runner.mjs" "$W9/plan.json" "$W9/run-01"
"$BUN" --smol "$W10/runner.mjs" "$W10/plan.json" "$W10/run-01"
/Library/Frameworks/Python.framework/Versions/3.12/bin/python3 "$W9/verify.py" /Users/ilyagulya/Projects/My/bend "$W9" "$W10" "$W9/verified.json"
```

Verifier действительно исполнен: **PASS_EXECUTED_EVIDENCE_INTEGRITY**.
Он проверил все event log hashes, source/environment scalar stream equality,
360 source references, 21 baseline source checks, три generated-source hashes
и оба accepted artifact hashes. Это не новый fixedpoint: native executable,
bootstrap и 12 paired gates не запускались и не объявляются пройденными.

Восемь новых source/protocol payloads сохранены content-addressed в
`checkpoints/n09-n10-source-inputs/`; обе frozen construction lanes используют
проверенные immutable source authorities предыдущего checkpoint. Raw logs,
AST transports, images, caches и bulk evidence не добавлены в Git.

## Архитектурное решение

Сохранить contextual FIR → lowering → существующий BIR. Наблюдённый logical
literal delta не обосновывает semantic IR rewrite, а RSS без phase/state
alignment не является доказательством такого роста. Причина historical native
OOM **не установлена**. Следующий допустимый вопрос — более поздняя конкретная
pass-2/rendering working-set boundary при сопоставимом producer/environment,
а не повтор unchanged failed full build и не увеличение caps.
