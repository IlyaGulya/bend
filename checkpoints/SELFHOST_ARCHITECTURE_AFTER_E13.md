# После E01–E13: направление FIR/BIR/lowering и следующий пакет проверок

## 1. Решение

**Не расширять FIR/BIR следующим общим optimizer pass. Сначала сделать измеримой стоимость построения самого компилятора; первую новую локальную optimization hypothesis проверить в lowering, не в runtime transport.** Это архитектурная рекомендация, не установленная причина OOM и не новый compiler candidate.

Запрошены и получены две независимые консультации `thorough-task-executor`: архитектурные границы/эволюция и причинная программа экспериментов. Родитель сверил основные source paths, предложенные новые механизмы, ограничения и provenance. Ни сборки, ни compiler runs, ни benchmarks, ни генераторы в этой консультации не запускались. Ниже **план**, не результаты N01–N08.

Принятым остаётся **G24R12**, восстановление — `9beb95e4`. [Итог E01–E13](../evals/receipts/experiments_e01_e13_completed.json) и [restoration proof](local2039g39e12-restored/restored.json) — первичные authority. G34–G39 остаются rejected. E03 canonical full-checker stack failures не означают неработоспособность genuine R12 stage1; G36–G39 native cap failures не доказывают causal regression относительно новой matched R12 construction.

**Метки:** ФАКТ — current source/исполненный receipt; ВЫВОД — интерпретация; ГИПОТЕЗА/ПРЕДЛОЖЕНИЕ — ещё не проверенный механизм; НЕИЗВЕСТНО — отсутствующая authority/measurement. Законы FIR/BIR нормативны, а не mechanized preservation proof.

### Что изменилось относительно G33

- Удаление логических операций оказалось недостаточным: G35 прошёл genuine fixedpoint и ускорил обе lanes, но нарушил memory gate; source-semantic успехи G36–G39 не прошли native construction prerequisite. Причина memory effects не установлена.
- Для шести найденных specialization sites existing BIR достаточен. Новая join/result-shape schema не оправдана; broad NF memoization, empty-query hoist и decode-elimination wrapper получили отрицательные результаты.
- Поэтому root generation/canonical construction и точная experimental authority поднимаются в приоритете; IR-schema и physical ABI расширения опускаются. Это не отказ от lowering optimization, а смена единицы выбора: **цена исполнения плюс цена построения компилятора, retention и семантические obligations**.

Источники: [закрытый каталог, §10](SELFHOST_ARCHITECTURE_REVIEW_G33.md#10-e01e13-окончательный-исполненный-каталог), [G35](../evals/receipts/producer2039g35e08_qualification.json), [G36](../evals/receipts/producer2039g36e05_rejected.json), [G37](local2039g37e06-outcome/outcome.json), [G38](local2039g38e10-outcome/outcome.json), [G39](local2039g39e12-outcome/outcome.json).

## 2. Архитектура: что сохранять и куда развивать

| Граница | Текущий контракт | Рекомендуемое развитие |
|---|---|---|
| Arena → checked FIR | Affine source owner, typed semantic handles/tapes, occurrence-specific quantities/types/selected symbols | Сохранить logical FIR; contextual witness до любой representation migration, не dedup по term id |
| CheckedProgram → Catalog | Registry/needed roots/descriptors; source owner ещё нужен | Не делать второй checker или global NF cache. Измерять конкретную работу построения descriptors |
| Catalog → lowering → BIR | Strict operands, erasure, evaluated captures, structured control; source state не входит в итоговый BIR | Первые новые вопросы: frame-local capture lookup и построение application spine, без новой BIR schema |
| Semantic BIR → JS planning | Scalar rewrite до bottom-up suffix/capture plan | Facts только для текущего body; не переиспользовать по одному Code.id после rewrite |
| Semantic BIR → C planning | Context/layout, sharing fixedpoint, entries и renderer | C sharing hot set не является move/keep/lifetime proof. Physical plan остаётся target-specific |
| Source → generated compiler → native seed | Generic typed-step generator, canonical checked bodies, canonical C fixedpoint, затем cc | Измерять helper/definition/pass/code-text tax прежде ещё одного transform; не создавать второй generator/profiler |

Опоры текущего кода: [FIR carriers](../bend2/selfhost/checker_ir.bend#L27-L58), [lowering handoff](../bend2/selfhost/backend_lower.bend#L1970-L1992), [BIR forms](../bend2/selfhost/backend_ir.bend#L188-L244), [JS plans](../bend2/selfhost/js_backend.bend#L1110-L1179), [rewrite before plans](../bend2/selfhost/js_backend.bend#L1313-L1345), [C plan](../bend2/selfhost/c_backend.bend#L466-L488), [sharing scope](../bend2/selfhost/c_backend_sharing.bend#L8-L73), [generic generator](../evals/checker_core_step_lower.ts), [emitter composition](../evals/emitter_step_lower.ts).

### Три compiler tracks не смешивать

1. **Canonical-built native seed:** `bend.ts` проверяет composed/generated source; `comp.ts.compile_book` строит C; лишь затем запускается native cc. G36–G39 остановились внутри `compile_book`, не в наблюдённом LLVM codegen. [Source](../evals/native_compiler_experiment.ts#L351-L430).
2. **Genuine selfhost JS stage1/stage2:** происходит из native bootstrap, проверяется собственный deterministic byte fixedpoint. Canonical `root.js` не является таким stage1. [Authentication](../evals/native_seed_runtime.mjs), [qualification](../evals/g24_qualification.mjs).
3. **Selfhost-emitted C target:** его layouts/refcount/rooting проверяются source→own emitter→C execution. Canonical native seed success не заменяет эти consumers.

Для нового observational вопроса можно выбрать authenticated genuine R12 stage1, если это его полномочная lane. Это новый diagnostic, не ретроактивный PASS E03. Stack-safe canonical correction — отдельная условная ветвь, а не обязательный ремонт всех compiler tracks.

### Направление cutover после новых фактов

**Ближний срок:** сохранить FIR/BIR/ABI и проверить N05/N06. Construction fix выбирать только после N01/N04, одной причинной осью; не смешивать его с возвратом G35/G37/G38/G39.

**Средний срок:** локальные facts/plans с перечисленными зависимостями, без source arena и global analysis cache. Body rewrite заканчивает lifetime старого use/escape/liveness/return analysis; parameter/capture order/Use и lexical-region изменения требуют нового call/control plan. Для малого slice безопаснее пересчитать локальный результат, чем строить incremental pass manager. Descriptor facts зависят от exact ordered family/type-function inputs, descriptor/env/level/fuel; unknown/abstract/failure сохраняются. [NF context](../bend2/selfhost/descriptor_nf.bend#L133-L168).

**Дальний срок, только после census:** compact descriptor representation (N08) или иной physical layout. Не общая SSA/CFG/schema migration «на вырост». Сокращение intermediate nodes должно окупить новые variants, materialization, fuel accounting, captures, consumers и canonical construction tax.

## 3. Новая конкретная причинная развилка: исполняемый codegen child

**ФАКТ source:** ordinary codegen argv строится как `[process.execPath, script, ...process.argv.slice(2), '--internal=codegen']`, без явного `--smol`. Outer guardian argv включает `--smol`. Sampling/V8 mode выбирает Node producer вместо ordinary Bun. [Codegen spawning](../evals/native_compiler_experiment.ts#L449-L460), [outer command](../evals/native_compiler_experiment.ts#L672-L685).

**ФАКТ существующих исполнений:** parent разобрал `codegen-process/start` и `guardian/start` в логах G37/G38/G39: outer содержит `--smol`, child не содержит его явно. Точные source/corpus/artifact/report argv присутствуют в соответствующих `logs/native-build.stderr`; pinned executable — Bun из сохранённых original commands. Это не новый запуск.

**НЕИЗВЕСТНО:** фактический JSC mode/environment и влияние на allocator/GC/RSS. Различие argv не объявляется «найденной причиной OOM». Нельзя молча добавить флаг, сменить engine или назвать sampling profile like-for-like Bun measurement. Controlled runtime-mode diagnostic — отдельная ось N01, прежняя qualification остаётся неизменной до явного решения о contract.

Уже существующие механизмы, которые **не надо реализовывать заново**: `compile_book` observer с pass/fact/cache/text counters; per-definition higher/names/native-constant release; публикация settled pass без дополнительного финального обхода; indexed reachability. [Observer/release](../bend2/comp.ts#L1935-L2010), [fixedpoint](../bend2/comp.ts#L3751-L3838), [bounded probe lifecycle](../evals/receipts/compiler_codegen_probe_verified.json). Разделение facts discovery/text emission пока гипотеза: оно может добавить второй обход, план и retention, поэтому не является первым cutover.

## 4. Порядок действий и неизменный протокол

**Моя интеграционная поправка:** N01/N02 и read-only gap inventory N03 — readiness, не три доказанных оптимизации. N03 не блокирует observational N05/N06 на accepted genuine R12; он обязателен перед новой runtime/ownership cutover, которой нужны отсутствующие C-reentry/candidate-stage1 cells. N04 запускается только ради конкретного construction question, а не как обязательный ещё один профиль.

Первый порядок: закончить source/runtime comparability N01 → выбрать authority N02 → **N05 census**, независимо рядом N06 census. Если N01 обнаружил неразрешённое canonical construction расхождение — адресный N04. N07 нужен перед FIR/identity migration; N08 — только после actual descriptor-string relevance. Не запускать все ветви последовательно ради галочек.

**Diagnostic D:** exact source/artifact/corpus/tool hashes, commands/cwd/env/runtime/guard, actual output и provenance; bounded scalar observation без дублирования affine owner. Instrumented counts/timings не становятся acceptance samples. Новый diagnostic над rejected source должен иметь новый вопрос/наблюдение и заранее объявленный bounded cutoff; это не повтор прежнего failed full build и не image publication.

**Production version V:** freeze/commit source, regression/required frozen SOURCE и compact evidence до restoration/следующей версии. Исходная цепочка: full native → genuine native/stage1/stage2 byte fixedpoint → все 12 original serial unprofiled paired samples (native3+3/JS3+3) → applicable consumers. Mandatory failure останавливает later gates честно. Обе pipeline mean/median строго лучше; median RSS/footprint не больше в каждой lane. Никакого нового процентного tolerance. Изменение canonical producer/runtime — новая authority, не незаметное сохранение старого pin.

**Limits:** RSS и physical footprint8192MiB, deadline600000ms, poll10ms; serial heavy lanes; worker stack256/old6144/young128MiB; canonical component builder old3072/stack256MiB со своим guard; ABI13, parser fuel8M, quantum64. Не doubleguard. Контракты: one source owner/no transient handles after rewind; selected identity/erasure/quantities; strict order/once/errors/allocation failures; descriptor unknown/fuel; lexical regions; alias/foreign/reentry/rooting. [FIR laws](../bend2/selfhost/FIR_LAWS.md), [BIR laws](../bend2/selfhost/BIR_LAWS.md), [original policy and runner](../evals/g24_qualification.mjs).

## 5. Пакет N01–N08

Каждая строка ниже — самостоятельная falsifiable проверка. Переход от census к source change условен; для нулевой/малой реальной работы допустимый окончательный результат — STOP.

### N01 — Матрица сопоставимости construction failures, не «четыре регрессии»

**Tier P0 / measurement infrastructure; зависимостей нет. Сначала исключительно read-only.**

**Гипотеза / отсутствующий факт.** У нас есть четыре hard-cap failures, но нет установленного paired source-to-construction counterfactual. Различие может лежать в source shape, generated helper graph, tool/env, retention внутри canonical compilation либо общей current construction pressure. N01 не выбирает причину заранее.

**Текущие entry points.** `g24_qualification.runCorrectness` (1280–1335), `native_compiler_experiment.compileBody` (310–364: input pins/load/validation; 366–403: compile_book; 404–430: C publication), `native_seed_runtime.authenticateNativeSeedBuild`; immutable G35–G39 receipts и R12 restoration. Generator identities: `checker_core_step_lower.ts`, `template_step_lower.ts`, `emitter_step_lower.ts` и их manifests.

**Отличие от прежнего.** Не повторять candidate qualification и не сравнивать failed candidate build с RSS *работающего старого native compiler*. Сопоставляется один и тот же construction этап с construction этапом. Не называть результат G39 очистки JS runtime причиной роста native heap без такой связи.

**Минимальная процедура.** Из существующих receipts составить таблицу для R12/G35/G36/G37/G38/G39: root/source closure hashes, composed declarations/helper hashes, kernel/comp/base/runtime/flags/env, full load/validation counts, последнее завершённое событие, guardian reason, presence C/native/stage1. Root names/run-id/path differences отделить от semantic-source differences, сохранив raw hashes. Отдельно указать отсутствующий control. Ничего не регенерировать для заполнения дыр. Только если нужного matched observation нет и отдельно запланировано новое diagnostic execution — N04 с новым источником информации, не unchanged retry.

**Конкретный новый discriminator: child argv.** Текущий `native_compiler_experiment.ts:449–460` строит default codegen child как `[process.execPath, script, ...process.argv.slice(2), '--internal=codegen']`, тогда как outer guarded command на строке677 явно содержит `--smol`. В existing G37/G38/G39 `native-build.stderr` записано именно это различие: outer с `--smol`, child без явного `--smol`; parent authenticated log hashes и argv сохранены в §3 этого отчёта (parent audit существующих логов). Это уже наблюдавшийся факт о командах, **не доказательство фактического JSC GC mode, наследования mode через environment или причины RSS**. Первый N01 action — связать child PID/argv/env/runtime с memory events, а не добавлять флаг.

`--profile-sampling`/`--v8-log-dir` на строках456–459 одновременно выбирают Node producer/3072 worker: такой профиль не является like-for-like Bun memory observation. Если после read-only audit понадобится проверить именно влияние mode, отдельный разрешённый diagnostic сравнивает неизменные source/root/corpus/tool/guard с original child invocation и явно выбранным mode; разница ровно одна, все результаты помечены non-acceptance. Сначала маленький settled construction fixture с exact C output, затем только обоснованный bounded full-root prefix. Не менять production runner и не объявлять изменённую lane исходной qualification. Даже положительный результат потребует явного решения о construction contract и новой version/gates, а не молчаливого «починили забытый --smol».

**Измерения / authentication.** Число реально сравнимых rows, точные differing inputs, common completed phase, доступность исходных output pins. При последующем matched build — process-tree RSS/footprint и progress отдельно; не выводить retained bytes из RSS. Все старые failures и peaks остаются.

**GO / STOP.** GO к N04 только с конкретным неразрешённым вопросом и pinned control/candidate, различающимися ровно заявленным source change. Несопоставимые manifests/недоступный frozen source — STOP причинной атрибуции, а не «общая проблема GC». Если будущий matched R12 тоже упирается в cap, это отдельный construction-blocker, не отменяющий историческую R12 acceptance и не оправдывающий кандидата.

**Налог / риск / версия.** Offline hashing/table join не меняет execution; будущее логирование создаёт I/O и observer tax. Source-version не нужна для read-only matrix; diagnostic harness фиксируется отдельно. Любой production construction fix — V, без ослабления исходных gates.

### N02 — Authority routing после E03 вместо ремонта не той lane

**Tier P0 / measurement infrastructure + canonical JS boundary; после N01 identity ledger, не зависит от нового build.**

**Гипотеза / недостающий факт.** Новый вопрос о source/lowering можно проверить через accepted genuine R12 stage1 без canonical full-RootJS parsing bottleneck. Неизвестно, какой именно новый вопрос действительно требует canonical authority; E03 этого за нас не решает.

**Entry points.** E03 `commandScope` и failure stacks; `base.bend:2164–2169`; `lexer.tokens`; `comp.ts:3949–3978,4097–4106`; сохранённый canonical `root.js:7256–7263`. Противоположная authority: `g24_qualification.validateFixedpoint` (546–564), `buildStageDriver`/consumer invocation (1364–1424); composition `emitter_step_lower.ts:35–55`.

**Точное отличие.** Не ещё один boxed/mailbox/direct tournament, не увеличение stack, host parser, patched generated JS или новый parser. E03 остаётся STOP. Новый diagnostic имеет **собственный** вопрос и genuine stage1 pin; нельзя назвать его недостающей строкой E03 либо переносить JIT данные canonical RootJS на selfhost JS.

**Минимум.** Read-only authority ledger связывает каждый предполагаемый следующий probe с source compiler, parser, emitted target, runtime. На одном ordinary affine/capture fixture новой N05/N06 ветви: authenticated accepted stage1 parse/check/emit → фактический C/JS consumer; затем только если требуется — frozen-workload observation с тем же stage1. Для canonical-stack ветви достаточно уже имеющейся source→generated-call→stack цепочки; повтор падения не нужен. Граница необходимости: если требуемый эксперимент невозможно выразить через genuine artifact, отдельно обосновать source-version canonical stack-safe lowering, а не делать его автоматическим первым шагом.

**Измерения / authentication.** Authority class на каждом row, artifact hash и build/fixedpoint chain, source file/carrier identity, вызванный export, parser fuel, semantic output/trace. Числа constructor depth/строк, если будут собраны, — diagnostic, не performance acceptance. Не объявлять canonical artifact genuine stage1 даже при равных probe outputs.

**GO / STOP.** GO, когда новый вопрос имеет полномочную lane и matching provenance. Если доступна только canonical lane, падающая до измеряемой части, STOP этому whole-compiler выводу. Не платить за canonical stack redesign только ради повторения закрытого E03. Для будущего stack fix сохранение char slicing/Unicode/constructor evaluation order и allocation failures должно быть доказано; reverse-accumulator с дополнительной копией списка не является бесплатной заменой.

**Налог / риск / версия.** Ledger read-only. При future diagnostic — startup/parse/observer overhead отдельно; смена authority не оптимизация. Production changes нет, V не нужен; любой canonical compiler/parser/runtime cutover требует собственной source version и полных исходных applicable gates, а не «тест E03 наконец прошёл».

### N03 — Source-to-consumer coverage: genuine stage1 и настоящий C reentry

**Tier P0/P1 / qualification infrastructure и target semantics; после N02. Read-only gap inventory первым, исполнение новых fixtures — только отдельным разрешённым этапом.**

**Гипотеза / отсутствующий факт.** Некоторые runtime invariants имеют actual source-emitted JS evidence, но не actual candidate stage1 evidence и не C foreign equivalent. Новая пара реально выполненных foreign consumers может обнаружить различие ownership/reentry, которое scalar/protocol proof не видит.

**Entry points.** `g24_qualification.runCorrectness:1357–1424`; `c_target_fixtures_run.ts:60–91,128–165`; `tests/compile/js_multi_reentrant.{bend,js}`; `js_backend.bend:1344–1389,2065–2070`; C `exit_releases`, `direct_ctl`, `call_head` (`c_backend.bend:2390–2391,3427–3500`). G39 `evidence[3]` — exact source/emission/execution pins и missing cells, не просто итоговый PASS.

**Отличие.** Не повтор E12 retired-suffix cleanup и не попытка принять G39 после rejection. Никакой JS mock, названный C fallback. Проверяется ранее отсутствовавшая **C foreign implementation** и происхождение stage1 runtime. G31 уже показал: fixedpoint и throughput не завершают C qualification — [failure](../evals/receipts/producer2039g31_qualification_failure.json):63.

**Минимум.** Сначала таблица cells `source revision × compiler authority × emitted target × scenario × observed execution`. Для новой qualification-fixture version: общий семантический trace callback-before / nested-call / callback-after, два настоящих `.c/.js` foreign implementations, live affine capture, nested continuation и обычное завершение; boundary cases 63/64/65. Exceptional paths сравнивать лишь в общем определённом контракте: JS throw не подменять произвольной C имитацией. Existing split-chain и arena tests остаются controls. Если общий C ABI не позволяет эквивалентный reentry, зафиксировать конкретную недоступность, не выдумывать PASS.

**Измерения / authentication.** Compiler/parser/stage1 hashes; исходные `.bend/.c/.js`; actually emitted target source; compiled C binary; execution command/exit/stdout expected trace; source-owned runtime code origin. Логические transfer/drop/clear события при наблюдении отделить от retained-byte claim. Не достаточно хеша runtime template или запуска вручную выделенной JS функции.

**GO / STOP.** GO — реальный C foreign consumer и реальный JS consumer дают один объявленный semantic trace, не теряют живой owner и не читают retired slot; обе output-provenance цепочки полны. STOP — missing source, иной ABI/semantics, synthetic runtime либо недоступный candidate stage1. Последнее остаётся missing, пока обычная V-цепочка не разрешит поздние gates.

**Налог / риск / версия.** Новая fixture/bridge добавляет сопровождение и instrumentation; foreign reentry — высокий ownership риск. Только тестовая версия не меняет compiler acceptance и не требует выдавать full compiler win; production fix потребует V. Нельзя переставить этот диагностический smoke на место обязательной полной matrix или выполнить пропущенные G35/G39 consumer gates для ретроактивной приёмки.

### N04 — Найти первый расходящийся canonical pass/definition, не собирать ещё один CPU profile

**Tier P1 / canonical compiler construction; зависит от конкретного unresolved comparison N01.**

**Гипотеза / недостающий факт.** Малый selfhost source change может изменить canonical own/hot/stat propagation, число native spins либо transient pending-sibling work одного generated declaration; полное число строк source этого не объясняет. Нужна локализация **первого структурного расхождения**, а не ещё один общий flamegraph.

**Entry points.** Уже существующие `comp.ts.file_observe:1935–1970`, `file_higher/file_release:1973–2010`, `compile_book:3754–3823`; `native_compiler_experiment.ts:369–403`; `evals/compiler_codegen_probe.ts` и [его verified lifecycle](../evals/receipts/compiler_codegen_probe_verified.json):1–8,42–122. Generated-origin manifest: `emitter-steps-v1.json.canonicalComposition/normalizedSourceDeclarationHashes` и `emitter_step_lower.ts:35–55`.

**Отличие.** Эти observer, per-definition cache releases, settled-pass publication и adjacency reuse **уже существуют**. Не предлагать их реализовать заново. Не generic cache-clear, не broad memoization E06, не повтор E02 selfhost BIR ablation. Сравнение происходит *до native artifact*, на canonical construction.

**Минимум.** На новых разрешённых diagnostic launches взять exact R12 и один конкретный rejected source (сначала самый узкий source delta, выбранный по N01), одинаковый original builder/runtime/corpus/bridge/guard. Reuse existing bounded probe для prefix до первого расходящегося pass/definition. Корпус сначала полный authenticated input, но output status честно `PROBE_STOPPED`, если cutoff; extracted dependency-cone fixture допустим лишь вторым, после established origin, и не выдаётся за полный root. Не запускать последовательно все G36–G39 без новой информации.

**Измерения / authentication.** По одному aligned canonical declaration/pass: own/hot/stat/lend deltas; spins/segments/output UTF16 units; `restMax`; higher/memo/layout/constant sizes; phase boundary and memory samples. Shape hash до native preparation и generated-origin связь. Observer events не равны retained-size; profile overhead не включать в clean acceptance. На small settled fixture — complete generated C digest как контроль ненарушения observer.

**GO / STOP.** GO к узкому construction change только если найдено устойчивое объяснимое source→declaration→structural delta и конкретная lifetime/algorithm boundary. Если changed region не исполнен до cap, гипотеза «этот runtime cleanup логически съел память» опровергнута для этого прогона. Если совпадают structural prefixes, нельзя объявлять GC причиной: результат — причинность не установлена. Если сам control не проходит, остановить source optimizations до разбора construction blocker; caps не трогать.

**Налог / риск / версия.** Existing observer выполняет счётчики/обходы/serialization, поэтому bounded diagnostic заметно не бесплатный. Production compiler source пока не меняется; speculative deletion of checked `e`, pass facts либо active emission roots запрещена. Любой найденный construction fix — отдельная V, включая canonical validation/output semantics; не маскировать как infrastructure-only.

### N05 — Frame-local capture lookup по `(owner, identity)`

**Tier P1/P2 / FIR→BIR lowering; census после N02, source cutover только после подтверждения.**

**Гипотеза / недостающий факт.** `capture_found` линейно сканирует уже накопленные captures при каждом external lexical reference. Если реальные frames имеют много повторных обращений к старым captures, стоимость lookup может быть существенной независимо от runtime transport. Распределения количества сравнений/размеров frames сейчас нет.

**Current source.** [backend_lower](../bend2/selfhost/backend_lower.bend):141–185 — `slot_at`, `capture_found`, `resolve_owner`, `resolve_capture`; 210–223 — `enter/leave`, deterministic first-use capture numbering и final reverse. Ключ **оба** owner и identity, не term handle; `LocalReference.value` не runtime operand: [checker_ir](../bend2/selfhost/checker_ir.bend):27–58.

**Отличие.** Не E04/E12 очистка живых/retired runtime captures, не G30 scheduler wrapper и не G29 изменение public Map tail walk. Изменяется только локальный builder lookup, а последовательность captures/ABI/ownership и generated BIR должна остаться прежней. Не переименовывать существующий closure specialization.

**Минимум.** Counters на actual `capture_found`: comparisons/hits/misses/frame length, плюс distinct `(owner,id)`, без удержания полного графа. Fixture: nested lambdas, repeated use одного capture в разрешённой quantity, разные owners с одинаковыми local identities, affine branch capture и nested region exits. Затем current full frozen lowering через authenticated genuine stage1, native lane отдельно. Только при GO сравнить list control с emission-local index внутри Frame; сохранить authoritative ordered list/first-use indices и выбросить index при `leave`. Не применять global term-id cache.

**Измерения / authentication.** Exact same FIR input/origin, BIR structural identity/numbering, source-emitted C/JS outputs/traces; lookup comparisons, index entries/inserts/finds/key construction, peak live frame auxiliary entries, generated source/helpers/size; clean lower/full pipeline и RSS/footprint после отдельной qualification. Инструментация не дублирует affine source owner.

**GO / STOP.** Если почти вся реальная работа empty/singleton/first-hit, STOP: индекс добавляет работу, как ошибочный E07 hoist. GO лишь при реально устранённой chain traversal и bounded index lifetime; несовпадение capture ordering/erasure/drop/region behavior — STOP. Даже хороший census не заменяет strict V acceptance.

**Налог / риск / версия.** Дополнительные Map nodes, conversions U32→key, hash/trie lookup, поле Frame и CPS threading/generated helper growth; source constructor tax может съесть выигрыш ещё до runtime. Нельзя считать Map бесплатно быстрее списка. Diagnostic clone — D; production Frame change — отдельная V со всеми consumers.

### N06 — Один descriptor application spine без повторного append prefix

**Tier P2 / catalog/lowering, без BIR schema change; после N02, независимо от N05.**

**Гипотеза / недостающий факт.** `descriptor_apply(DescriptorRef{args}, arg)` каждый раз вызывает `List.append(args,[arg])`; для длинной левой цепочки applications это повторное копирование растущего prefix. Неизвестно, встречается ли длинная цепочка на actual compiler workload, и не преобладают ли arity 0/1.

**Source.** [lower_catalog](../bend2/selfhost/lower_catalog.bend):168–171,301–309,424–425; отдельный существующий `descriptor_sugar:197–218` уже собирает arguments, но имеет свой порядок traversal и **не является автоматически правильной заменой**. [descriptor_nf](../bend2/selfhost/descriptor_nf.bend):407–417,469–472,741–742 сохраняет fuel/normalization contract.

**Отличие.** Это не E06 repeated NF memo/index handoff и не E10 shared marker map. Устраняется prefix-copy при **построении одного** descriptor; cache между вызовами, новый NF result либо arena packing не предлагаются.

**Минимум.** Count actual `descriptor_apply` Ref/non-Ref branch, длины args и суммарно traversed append cells. Fixtures: `F(a)(b)(c)` с разными dependent argument forms; non-Ref head; aliases/shadowed names; erased аргументы; malformed/failing descriptor и исходный fuel boundary. Candidate — локальная сборка одного application spine с однократным материализованием прежнего `DescriptorRef{key,args}`. Head/arguments должны вычисляться в исходном порядке; reverse traversal existing sugar нельзя копировать без доказательства. Нельзя добавить второй полный descriptor tree рядом с первым.

**Измерения / authentication.** До NF — exact descriptor tree equality, order/diagnostic trace; после NF — same result/unknown/failure и fuel behavior, BIR/output equality; prefix cells removed vs new spine nodes/second walks/frames. Actual stage-origin hashes и clean C/JS consumer output, не только синтетический большой arity benchmark.

**GO / STOP.** Нет actual long prefixes — STOP production rewrite. GO только при доказанном удалении actual work без изменения descriptor shape, selected names, strict order/errors/allocation-failure behavior. Если экономия достигается только reordered traversal либо иной NF fuel accounting, это не допустимый локальный fix; STOP, а не скрытое расширение задачи.

**Налог / риск / версия.** Pending-spine storage, reversal/second traversal, extra CPS carries и canonical codegen tax; failure order особенно чувствителен. Ownership source остаётся один, contextual occurrences не merge. Production candidate — V; no schema/ABI change не освобождает от original gates.

### N07 — Контекстуальная FIR differential witness, а не ещё один closure walk

**Tier P2 / FIR semantic qualification; после N02; prerequisite для будущих occurrence/identity migrations.**

**Гипотеза / недостающий факт.** Closure validity и одинаковый output обычного fixture не различают корректную occurrence-sensitive lowering и неверную схему `term-id → facts`. Нужен воспроизводимый witness, где contextual facts действительно различны и влияют на результат/отказ.

**Source.** [checker_ir](../bend2/selfhost/checker_ir.bend):27–58; [checked_frontend](../bend2/selfhost/checked_frontend.bend):16–34; [FIR laws](../bend2/selfhost/FIR_LAWS.md):379–440; `backend_lower.variable/resolve:156–191`, `lower` dispatch:1321–1356; publication exit `checker.bend:15063–15076`.

**Отличие.** G35 уже имеет source-handle closure proof (receipt:2641–2705) и publication revisit counts (2920–2935). Не строить их ещё раз и не удалять publication walk повторно. Новая obligation — **не схлопнуть contexts**, не вывести native representation из структурного вида и не читать semantic substitution как runtime operand. Broad combined G26 rejected; это не реабилитация его компонентов.

**Минимум.** Через actual checker подобрать исходный bounded dependent/lexical fixture с recorded shared term handle и различными occurrence paths/bindings/type_depth; отдельно aliases с одинаковым spelling, erased/runtime field positions и ScalarOccurrence high-bit payload. Если producer не создаёт shared-handle witness, честно отметить это; вручную assembled carrier не называть producer proof. Использовать trace/digest диагностических occurrence paths, затем ordinary lowering и C/JS consumers. Test-only negative mutation: collapse **только диагностическое представление** facts по term-id; oracle должен отличить это от control по конкретному invariant/expected trace, не вводя malformed FIR в production как будто он admissible.

**Измерения / authentication.** Source→checker→occurrence identity map, variant/role-aware edges (payload bits не handles), selected symbols и binding depth, exact failure diagnostics или executed semantic trace, target origin. Доказательство только для witness; не обещать theorem/type equivalence.

**GO / STOP.** GO для будущей архитектурной миграции только если witness реально различает контексты и catches intended collapse. Нет shared identity, mutation inert или тест лишь сравнивает сериализованные поля — это **не** доказательство consumer preservation; STOP заявлению о покрытии и уточнить fixture. Нельзя чинить тест объединением контекстов.

**Налог / риск / версия.** Diagnostic trace и bounded witness storage, без permanent global handle map/дубликата arena. Test-only source/version receipts нужны; исходный compiler не переквалифицируется как оптимизация. Любая последующая production FIR/layout migration — отдельная V и эти witnesses в дополнение, не вместо полного набора.

### N08 — Стоит ли вообще вводить compact string descriptor?

**Tier P3 / BIR descriptor representation cutover; только после N02/N07 и отдельного actual-path census. Не первый production эксперимент.**

**Гипотеза / недостающий факт.** Catalog раскрывает каждый `TermString` в constructor tree, включая рекурсивный 32-bit word для каждого char. Это source-visible expansion, отличный от уже compact runtime `StringOccurrence`. Если такие строки реально попадают в dependent descriptors, compact literal может убрать промежуточное дерево. Их runtime frequency/retention не установлены.

**Source.** [lower_catalog](../bend2/selfhost/lower_catalog.bend):228–245,434–435; [backend_ir](../bend2/selfhost/backend_ir.bend):162–186 — текущий descriptor sum; [descriptor_nf](../bend2/selfhost/descriptor_nf.bend):95–100,296–297,469–472; `backend_lower:1353–1354` показывает, что обычные checked string literals уже идут своим runtime путём. Layout consumer types: `c_backend_layout.bend:138–172`. Не обещать экономию всего source string corpus: большая его часть может не достигать этого пути.

**Отличие.** Не E13 arena packed/decode access, не E06 memoization, не «сделать String native» — runtime representation уже отдельно сертифицирована. Предмет только descriptor constructor expansion, сохраняющий selected constructor names и dependent interpretation.

**Минимум.** Сначала read-only/static origin inventory и bounded counters для `descriptor_node.TermString`: calls, chars, созданные descriptor constructors, parent use (family args/type function/show). Fixtures: empty/ASCII/astral/NUL строка в dependent descriptor, alias/не-native constructor names, match/type-function, fuel-exhaustion edge. Только при actual relevance — отдельная schema version с compact descriptor и полными NF/materialization/layout/JS metadata/C consumer implementations. Никогда не сохранять ещё и старое раскрытое дерево постоянно.

**Измерения / authentication.** Exact old-tree materialization для fixture; selected names, normalized results, unknown/failure/fuel semantics, reflection/show/IO results на C и JS; peak live descriptor nodes и new representation overhead отдельно от heap bytes; actual source→BIR→target provenance. Census-zero на full workload — окончательный STOP performance ветви.

**GO / STOP.** GO лишь если раскрытие реально достигается, измерено и compact representation может воспроизвести прежние fuel boundaries и ошибки без скрытого допрасхода/сдвига порядка. Если все consumers немедленно раскрывают всё обратно, либо сохранение fuel требует той же работы, STOP. По одному source-visible рекурсивному constructor нельзя выдавать оправданную schema migration.

**Налог / риск / версия.** Новый variant во всех descriptor consumers, code size, explicit fuel accounting, lazy state lifetime, риск selected identity/native-certification; высокий cross-backend regression risk. Это **V/full original gates обязательно**, не schema scaffold и не infrastructure-only change.


## 6. Что не возвращать под новым названием

G25 range fusion, G27 dense tapes, G28 packed rows, G29 public Map tail walk, G30/G31 scheduler wrappers, G32 mailbox transport; G34 metadata-update reduction, G35 publication-walk removal, G36 прежние six specialization sites, G37 NF-index handoff, G38 marker-map reuse и G39 retired-suffix cleanup остаются исторически rejected. Новый diagnostic может установить новую причинную разницу, но не заменить старый verdict. [История и итог](SELFHOST_ARCHITECTURE_REVIEW_G33.md).

Не предлагать broad NF cache без repeats, hoist до empty-list short circuit, joins ради выразимого existing-BIR target, decode wrapper над уже хранимым Node. Не удалять live continuations, не путать absence одного slot reference с owner death/retained bytes, не выдавать fixedpoint или скорость за полную memory/consumer acceptance.

## 7. Проверка этой консультации и границы

Parent offline authentication: **13/13 primary receipt SHA-256** совпали с завершённым индексом; **21 R12 baseline checks** (включая ожидаемое отсутствие removed files) и **три generated-source hashes** совпали с текущим деревом. Дополнительно прочитаны и pinned текущие G37/G38/G39 native-build logs для argv observation; runtime mode/RSS cause из этого не выводились. Основные новые source hypotheses N05/N06/N08 и canonical fixedpoint/JS/C planning boundaries проверены по текущим source symbols, а не только по старому отчёту.

Исторический поиск `ctx` по архитектуре/E01–E13 и G35 не дал hits; отсутствие hits не считается доказательством отсутствия прошлых работ. LSP сообщает `No language servers configured`; source navigation выполнена text tools. Offline проверка завершилась `POST_E13_ARCHITECTURE_REPORT_REFERENCES_AND_UNCHANGED_BASELINE_PASS`: все 42 относительные ссылки разрешаются, source line ranges допустимы, N01–N08 присутствуют ровно по одному, production/generated baseline checks сохранены.

**Новые heavy/compiler runs: 0. Новые compiler/performance/fixedpoint acceptance claims: 0.** Две консультации не являются двумя экспериментальными результатами. Все N — предложенный следующий план; текущая рабочая база — G24R12.
