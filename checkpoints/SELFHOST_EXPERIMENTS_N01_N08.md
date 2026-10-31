# N01–N08: исполненные архитектурные эксперименты после E13

Статус: **все восемь опытов завершены; production-кандидат не допущен**.
Accepted compiler остаётся **G24R12**, исходный checkpoint `9beb95e4`.
Production source не менялся. Нового native image, fixedpoint или performance
acceptance нет. План консультации не переписан задним числом:
[`SELFHOST_ARCHITECTURE_AFTER_E13.md`](SELFHOST_ARCHITECTURE_AFTER_E13.md),
SHA-256 `57ab5d34a822199eb92e27bf21bd6824e8bc397f52062ca35bcb194853826862`.

Полный машинный ledger, exact commands, версии runtime, исходные hashes,
step counts, limits, guard outcomes, target output и сохранённые отказы:
[`experiments_n01_n08_completed.json`](../evals/receipts/experiments_n01_n08_completed.json).

## Результат каждого опыта

| Опыт | Наблюдение | Disposition |
| --- | --- | --- |
| N01 — construction provenance | Аутентифицированы 13 исходных receipts, 1 661 source-inventory entries и шесть constructor corpora. У успешных R12/G35 наблюдается `BUN_JSC_forceRAMSize=4294967296`; у исторических G36–G39 значение child environment неизвестно. | Audit complete. Нельзя называть этот hint hard cap или приписывать historical failures отсутствию hint. |
| N02 — execution authority | Genuine R12 native/bootstrap/stage bytes и source closure аутентифицированы; actual own frontend/emitter и C/JS split-capture consumers исполнились с ожидаемым output. | PASS. Canonical RootJS не подставляется вместо native-produced stage1. |
| N03 — source/target reentry | Семь реальных target executions, включая нормальный C/JS callback reentry с live affine owner на границах 63/64/65; отдельный JS exception fixture также проходит. | PASS для исполненных traces. Recoverable C exception equivalence не существует в этом API и не заявляется. |
| N04 — construction source shape | В двух matched source lanes полная validation проверяет 12 456 defs / 13 050 events. Первые 50 000 observer events на lane совпадают; обе изменённые origins встречаются, последнее состояние — prepare-after pass 1. | STOP: structural divergence в наблюдённом префиксе не обнаружена. Это не полный construction и не доказательство GC cause. |
| N05 — capture lookup | 37 068 requests, 108 051 slot comparisons; 2 451 hits против 34 617 misses. Hit traversal beyond first — 7 124 cells, old hits — 833. Collision comparisons — 0. | STOP_PRODUCTION_INDEX: map добавляла бы много новых entries ради небольшого повторного поиска. Producer-collision coverage и native lane не доказаны. |
| N06 — descriptor application | 702 Ref applications; скопировано 285 prefix cells, максимальный префикс — 1, длинных префиксов нет. Контролируемый fixture действительно достигает длинного пути. | STOP_PRODUCTION_SPINE_REWRITE: статический повторный append не означает значимой стоимости в реальном workload. |
| N07 — contextual FIR | В реальном producer найдены два shared term IDs с четырьмя occurrence paths и разными raw type handles. Все focal paths прямо наблюдаются как discarded annotations; в root/lower они не поступают. | STOP_NO_CONSUMER_RELEVANT_SHARED_CONTEXT в ограниченном корпусе. Raw handle inequality не является semantic context inequality. |
| N08 — descriptor strings | В полном workload 31 840 descriptor-node calls, но 0 TermString routes. Положительный source control достигает 4 routes / 5 chars, включая astral и NUL, и 344 constructors; C/JS consumers исполняются. | STOP_NO_ACTUAL_DESCRIPTOR_STRING_RELEVANCE: observer живой, но migration не имеет измеренной relevance в основном workload. |

## Что действительно запускалось

Full lowering census использует оригинальные 53 frozen source inputs и genuine
R12 stage1, без подмены frontend или вырезания definitions. Полученный library JS
байт-в-байт совпадает с прежним control:
`c33227e028d767df9a9fff75663e42eb7374919dcf8e7dff14936a98d20008fb`,
29 948 466 bytes. Template/Checker/Emitter counts —
1 004 927 / 10 078 835 / 1 225 480.

| Исполненный диагностический run | Elapsed ms | Peak RSS, bytes | Peak footprint, bytes |
| --- | ---: | ---: | ---: |
| Full lowering census | 316 680 guard wall time | 2 092 204 032 | 2 929 007 624 |
| N04 accepted-source bounded prefix | 11 256 | 4 500 832 256 | 4 485 091 144 |
| N04 G39-source bounded prefix | 11 017 | 3 948 920 832 | 3 821 473 176 |

Это instrumented diagnostics, **не benchmark**. Из этих timings/RSS не следует
ускорение или уменьшение retained bytes. N04 child environment и producer argv
сопоставлены внутри нового опыта; historical failed environment не выдуман.

Все heavy children исполнялись последовательно с исходным guardian:
RSS **и** physical footprint 8 192 MiB, timeout 600 000 ms, poll 10 ms.
Обычные Node workers: stack 256 MiB, old 6 144 MiB, young 128 MiB.
Canonical component builder сохраняет собственные исходные limits/guard;
внешний второй guard не добавлялся. Parser fuel 8M, ABI13 и quantum64 неизменны.

Совокупно исполнены **30 успешных target programs** через genuine own
parse → expand → check → C/JS emit, затем actual clang/execute или JS execute.
Repeated runs с разными passive probes учтены как executions, не как разные
semantic cases. Full census и bounded construction не выдаются за consumer runs.

Ключевые исполненные входные точки (литеральные child argv сохранены в ledger):

```sh
NODE=/Users/ilyagulya/bend-g12-borrow-7782b78a-1e88-4ffd-9889-14cb52c6a5b9/.tools/node
BUN=/Users/ilyagulya/bend-g12-borrow-7782b78a-1e88-4ffd-9889-14cb52c6a5b9/.tools/bun
W=/private/tmp/bend-n01-n08-HL7Pt3
D=/private/tmp/bend-e01-e13-jbsb4I
"$NODE" --experimental-strip-types "$W/authenticate.mjs" "$W/authority-01.json"
"$NODE" --experimental-strip-types "$D/census-runner.mjs" "$W/lowering-census/config.json" "$W/lowering-census/census-01.json"
"$BUN" --smol "$W/construction/run-probe.mjs" "$W/construction/run-01"
"$NODE" --experimental-strip-types "$W/source-suite.mjs" "$W/source-witness/n03-suite.json" "$W/n03-source-01"
"$NODE" --experimental-strip-types "$W/source-suite.mjs" "$W/source-witness/n07-reachability-suite-05.json" "$W/n07-reachability-05"
```

Исполненные runtime: Node 23.11.0, Bun 1.4.3, `/usr/bin/clang`;
точные tool hashes/version output находятся в receipts.

## Отказы и границы доказательства

- Первый application fixture нарушал erased Type quantity. Он сохранён как
  отказ; новый `application-v2.bend` использует существующий допустимый pattern
  и исполняется в обоих targets. Compiler ради fixture не менялся.
- Исходный string fixture дошёл до реального C emitter error
  `constructor Labels has inconsistent packed node`. Следующий `string-v2`
  исполнился, но не достиг string path: это coverage-unmet negative control,
  не положительное доказательство. Только новый `string-v3` закрывает intended
  path и target executions.
- Прямой source wrapper для `capture_found` отвергнут genuine checker:
  `match scrutinees must be parameters or bound fields`. Нет фиктивного
  producer-collision proof через другой executor.
- `dependent_pair_destructure` и `group_returned_dependent` rejected самим
  genuine producer. Duplicate JS checker rejection не запускался. Inspection
  source имеет отдельный C emitter refusal — erased field в printable main;
  JS variant исполняется. Эти отказы не стали PASS после изменения oracle.
- N07 reachability revision 04 оставлена с
  `STOP_OBSERVER_OR_BASELINE_MISMATCH`: пять consumer projections не имеют
  source-path identity. Новая revision 05 задаёт более узкий явный вопрос и
  сохраняет все эти projections: они принадлежат другим term IDs в `::main`,
  ни один не focal. Глобальная полнота consumer identity **не заявляется**.
  Обе версии сохраняют exact emitted bytes и Emitter steps; mutation oracle
  не поймал чувствительную ошибку, потому что focal shared annotations стираются.
- Новый N03 C callback fixture не создаёт задним числом missing candidate-stage1
  proof для отклонённого G39. JS recoverable throw не эмулируется C abort.

## Архитектурное следствие

Сохранить нынешнюю границу **checked contextual FIR → lowering → существующий
BIR → emitters**. Эти измерения не дают оснований стирать occurrence context,
заводить глобальную term-ID table, вводить второй semantic BIR, compact string
representation или frame-local map в production. Отрицательный N07 — отказ
конкретного witness, не разрешение на контекстно-независимый cutover.

Главный открытый вопрос остаётся **native construction working set**, а не
consumer runtime или доказанная quadratic lowering path. Следующее допустимое
исследование должно локализовать divergence на более поздней конкретной
prepare boundary при matched source/runtime/environment. Нынешний bounded
prefix не отвечает на этот вопрос. Повтор unchanged failed full build,
увеличение caps или смена producer engine не являются исправлением.

Ни одна performance hypothesis не прошла diagnostic admission filter, поэтому
новая production source version не создавалась. Исходная qualification chain
(native build → genuine bootstrap/fixedpoint → все 12 paired gates → consumers)
не ослаблена и не объявлена пройденной несуществующим кандидатом.

## Frozen inputs и итоговый checkpoint

Ledger перечисляет **377 source-input rows**: новые diagnostics/fixtures,
обе construction lanes, исходный full-census corpus и весь actual parsed/foreign
source closure. Проверено **3 170 actual source references**. Existing source
bytes ссылаются на проверенные immutable Git blobs; **52 новых source payloads**
сохранены content-addressed в `checkpoints/n01-n08-source-inputs/`.
Generated compiler images, AST transports, raw event streams, bulk stdout,
profiles и caches в Git не добавлены.

В конце повторно проверены все **21 baseline source checks** и **3 generated
source hashes**. Accepted artifact authority аутентифицирована; старый stage1/
stage2 byte fixedpoint не переименован в новый build. Restore не требовался:
production compiler не менялся. Исторические G34–G39 остаются rejected.
