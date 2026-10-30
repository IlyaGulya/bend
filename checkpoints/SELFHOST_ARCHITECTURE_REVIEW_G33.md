# После G33: архитектура FIR/BIR/lowering и программа экспериментов

## 1. Решение и статус

Это запрошенная архитектурная консультация, не реализация G34, не новая версия компилятора и не acceptance. Два независимых `thorough-task-executor` исследовали архитектуру и программу опытов; родитель сверил ключевые контракты по текущему коду, оспорил первоначальный приоритет fusion и объединил результаты. Production sources, fixtures, runtime и существующие receipts не изменялись. Новые compiler runs, профили и fixedpoint здесь не выполнялись.

**Решение: не начинать общий G34 fusion pass по умолчанию.** Сначала различить три конкретные возможности: уменьшить реально выполняемую checker metadata-work; убрать повторную работу под неизменным контекстом; найти дополнительное безопасное BIR-покрытие поверх уже существующего fusion. Затем выбрать **одну** реализацию, а не пакет улучшений. R12 остаётся принятой базой.

Метки: **ФАКТ** — наблюдение source/receipt; **ВЫВОД** — интерпретация; **ПРЕДЛОЖЕНИЕ** — ещё не выполненный опыт/контракт; **НЕИЗВЕСТНО** — не измерено или не доказано. Законы FIR/BIR — спецификация с открытыми proof obligations, не сертификат любого преобразования. Их внутренние номера строк местами исторические; при реализации проверять актуальные символы.

### Поправка к прежнему G34

**ФАКТ:** producer → shared-continuation deforestation уже реализована в [checker_core_step_lower.ts](../evals/checker_core_step_lower.ts):13–32,1230–1266,2635–2641. Tail-конструирование записи превращается в вызов общего continuation helper; есть alpha-freshening, pure-DAG/single-use/single-constructor/capture ограничения. Рядом существует bounded private-helper inlining/scalarization:1690–2074,2319–2339. Поэтому «добавить fusion» само по себе не новая идея.

**ФАКТ:** scheduler `pop/advance/chunk` генерируется текстом **после** этих passes (:2432–2454). Это конкретная фазовая щель. **Но** его sum returns, рекурсия, opaque `resume/invoke` и chunk boundary не входят автоматически в прежний pure-helper контракт. Перенести pass позже — проверяемая гипотеза, не готовое исправление.

**ФАКТ:** generated JS `$k` continuation — это BIR suffix после `Let`, а не потерянное для BIR тело: [js_backend.bend](../bend2/selfhost/js_backend.bend):1332–1349,1387–1416. Непрозрачный `Apply` скрывает callee, но не код, выполняемый после его возврата.

**ВЫВОД:** осмысленный G34 должен назвать добавочное покрытие, отличие от existing deforestation, цену анализа и место materialization. Нельзя заранее обещать устранение `StackMore` или одинаковый выигрыш native/JS.

## 2. Что уже доказали предыдущие версии

Основные источники: [G31 backend asymmetry](../evals/receipts/producer2039g31_throughput.json), [G32 full-root/fixedpoint](../evals/receipts/producer2039g32_core_fixedpoint.json), [G32 throughput/rejection](../evals/receipts/producer2039g32_throughput.json), [G33 disposition](../evals/receipts/producer2039g33_disposition.json), [worker frequency](../evals/receipts/producer2039g33_worker_frequency.json), [checker profiles](../evals/receipts/producer2039g33_checker_profiles.json), [emit intervals](../evals/receipts/producer2039g33_stage_intervals.json).

- **ФАКТ:** R12 принят по собственной полной цепочке; G32 прошёл native validation 12 991 definitions / 13 617 events без exclusions/patches и реальный stage0 → stage1 → stage2 byte fixedpoint, но **отклонён** по заявленному performance gate. G32 consumer matrices после этого не запускались. Fixedpoint не равен полной приёмке.
- **ФАКТ:** G33 насчитал 19 258 235 вызовов одного vector producer `metadata_write`, все в checker. Пять из шести consumer workers активны. Один статический producer оказался горячим, хотя tiny workers не видны в выбранных CPU samples.
- **ФАКТ:** G32 снимает промежуточный двухполевый `MetadataTables`, но оставляет `Arena`, внешний `Tuple` и sampled scheduler allocations `RunState`/`StackMore`. Три mailbox writes, три clears и две secondary loads на возврат — операции source protocol, не измеренные hardware instructions.
- **ФАКТ:** G33 allocation estimates уменьшились в двух checker windows и выросли в третьем. Причина clean timing variation, retained-heap выигрыш и роль GC **не установлены**. Равные protocol steps/word-tape не доказывают равную физическую работу.
- **ФАКТ:** в одной marked emit pair добавились transport/lower-handoff и link/validation интервалы; строительство BIR и сборка JS почти не изменились. `result_widths` вошёл до и после transform. Это разные версии IR: два входа не доказывают ненужность второй проверки. Полный source-assembly interval включает scalarization/planning и не равен стоимости конкатенации строк.
- **ФАКТ:** у native seed горячий RunState уже передавался через несколько регистров canonical compiler, а у selfhost JS материализовался объектом. G31 убирал последний, но не завершил C consumer qualification: `scheduler_chunk_smoke` превысил прежний 600-секундный cap. Причина timeout и регрессия относительно R12 не установлены.

### Три разных тракта

| Тракт | Кто его строит | Что нельзя переносить между трактами |
|---|---|---|
| Native seed compiler | canonical `comp.ts`, `C.compile_book` | BIR pass не снимает объекты уже скомпилированного checker seed; он добавляет seed работу при emit |
| Selfhost-generated JS compiler | собственный lowering/BIR/JS renderer предыдущего stage | Новые object shapes могут изменить JIT, dispatch и retention; counts не дают автоматического времени |
| Selfhost C target и его consumers | собственный BIR/C renderer | Native seed не проверяет этот private ABI, C sharing/frame cleanup и время C emission |

Источники: [native_compiler_experiment.ts](../evals/native_compiler_experiment.ts):351–386; [comp.ts](../bend2/comp.ts):2795–2802; [c_backend.bend](../bend2/selfhost/c_backend.bend):9–41,3175–3179; `producer2039g31_throughput.json.backendAsymmetry`.

### Не повторять прежние попытки под новыми названиями

G25 range fusion, G27 dense tapes, G28 compact node rows, G29 Map tail-walk, G30/G31 fuel-threaded scheduler и G32 vector transport уже были реализациями с отрицательными результатами, а не неисполненными планами. G26 объединял несколько изменений; его общий отказ не устанавливает знак каждого slice. Возвращение к отдельной идее допустимо только с явно названной новой причиной или как изолированный historical replay. Уменьшение allocations/bytes/visits само по себе не performance acceptance. Первичные receipts перечислены в [SELFHOST_HANDOFF.md](SELFHOST_HANDOFF.md) и [ROADMAP.md](../bend2/selfhost/ROADMAP.md):103–198; их исторические статусы не перекрашивать.

## 3. Текущие границы и где развивать архитектуру

| Граница | Что уже есть | Следствие для развития |
|---|---|---|
| Arena → checked FIR | Flat tapes, generation/rewind/publication, selected declaration identity, occurrence-specific type/quantity/bindings | Нельзя заменить occurrence cache ключом одного semantic handle; физический storage и contextual meaning — разные задачи |
| CheckedProgram → catalog | Один affine source owner; descriptors, registry, needed roots и constructor/family metadata | Не изобретать заново demand discovery; измерять повторные обращения, гранулярность и lifetime |
| Catalog → lowering → BIR | Erasure, strict operands, capture/application shape, descriptor provenance решаются один раз; source owner не переносится в итоговый BIR | Полезны узкие semantic summaries, но не сохранение всего dependent checker graph |
| Semantic BIR → target planning | `Use`, ctor/field identity, Direct/Apply, structured control; нет return/escape/effect summaries или block parameters | Сначала локальные/pass-scoped facts; новый IR carrier только при доказанной необходимости |
| Target planning → физическое исполнение | JS suffix/capture plans и trampoline; C sharing, canonical Term и storage layouts; seed — отдельный layout-aware compiler | Private ABI, layout и lifetime планируются по target; generic register width не должен становиться свойством FIR |

Опора: [checker_ir.bend](../bend2/selfhost/checker_ir.bend):4–58; [checked_frontend.bend](../bend2/selfhost/checked_frontend.bend):13–22; [checker_arena.bend](../bend2/selfhost/checker_arena.bend):47–103; [lower_catalog.bend](../bend2/selfhost/lower_catalog.bend):12–39,1470–1485; [backend_lower.bend](../bend2/selfhost/backend_lower.bend):11–46,1970–1992; [backend_ir.bend](../bend2/selfhost/backend_ir.bend):6–29,188–244.

### 3.1 Что следует сохранять в FIR

**ФАКТ:** FIR содержит контекстные occurrence facts, выбранные declaration identities, checked quantities и instantiated pattern layouts. `LocalReferenceOccurrence.value` — substitution metadata, не runtime expression. Успешный handoff передаёт единственный source owner; publication должна замкнуть reachable handles до rewind. Source publication fast paths и transient memo уже существуют; «добавить publication memo» не новая идея.

**ПРЕДЛОЖЕНИЕ:** логическую FIR пока не переписывать. Исследовать work/lifetime отдельно от storage: лишние publication walks; повторное преобразование selected identity обратно в строку; точные повторные запросы под неизменным scope. Любая compression key должна учитывать контекст, а не только term handle. Physical field-view storage — более поздняя отдельная ветвь E13.

### 3.2 Чего BIR действительно не хватает — и чего пока не надо добавлять

**ФАКТ:** `Code` несёт параметры/capture uses и дерево body, но не полные типы locals или interprocedural result/escape/effect summaries. C sharing заново выводит head/callee/unknown flow; JS scalar replacement локальна и отказывает при escaping result. Источники: `backend_ir:188–244`; [c_backend_sharing.bend](../bend2/selfhost/c_backend_sharing.bend):15–62; `js_backend:1196–1244`.

**ПРЕДЛОЖЕНИЕ:** сначала exact-IR-version pass-local summaries: known target, return alternatives/Unknown, field uses/provenance, whole-value escape/identity, live captures, SCC/size и region exits. Это не физический result window и не полные dependent types. Разделить discovery, transform и validation; reuse facts после rewrite требует явной invalidation или доказанного witness.

Существующих `Code/Direct/Let/Branch/TailDirect` достаточно для ограниченного acyclic producer→continuation specialization. Локальный join с параметрами нужен лишь если E05 упирается в измеренное клонирование или свободные lexical exits. Сразу arbitrary CFG/SSA/backedges не требуются.

### 3.3 Два слоя continuations и живые frames

**ФАКТ:** typed scheduler `StackMore` хранит `resume/rest` до `pop`; между push/pop возможны другие transitions и выходы chunk. JS renderer отдельно создаёт `$stArgs/$k` frames из BIR suffix. Нельзя считать их одной и той же «лишней коробкой».

`RunState` внутри chunk может быть промежуточным, но внешняя state-форма нужна при fuel=0/yield. `advance` возвращает сумму State/Finished и делегирует `pop`; record-only specialization это не покрывает. Устранение wrapper не устраняет необходимую continuation information. Источник: `checker_core_step_lower.ts:2424–2455`; `js_backend:1332–1416`.

**ПРЕДЛОЖЕНИЕ:** прежде frame layout/pooling — E04 retaining-path/lifetime evidence. Даже affine value нельзя переиспользовать при reentry/escaping alias. Dead capture можно убрать; live frame нужно хранить, возможно иначе, но не игнорировать.

### 3.4 Lowering, NF и планы: уменьшать работу до новой ABI

**ФАКТ:** NF indexes строятся в `lower_catalog:1475`, заново для lower state в `backend_lower:1982`, отдельно для C layout context в [c_backend_layout.bend](../bend2/selfhost/c_backend_layout.bend):290–300. [descriptor_nf.bend](../bend2/selfhost/descriptor_nf.bend):133–168 хранит family/type-function maps, без общего result cache; default fuel 1024. Это потенциальное повторение, **не измеренная дороговизна**.

**ПРЕДЛОЖЕНИЕ:** lifetime-bound reuse индекса либо точного closed-normalization результата, если cost census это оправдает. Не глобальный cache, удерживающий FIR/descriptor graphs; ключ обязан учитывать context/version/env/levels/fuel, а abstract/unknown/failure — не превращаться в успешный default.

**ФАКТ:** `metadata_write` выполняет два U32 Array.set и один Nat Array.set (`checker_arena:427–428`). `reserve_words` уже amortizes metadata publication через pool (`1099–1120`). Поэтому первая новая гипотеза — конкретные лишние updates на обычном append, не обещание впервые «batch metadata».

## 4. Пакет из 13 экспериментов

Все E01–E13 ниже — **предложения**, не выполненные изменения. Один опыт меняет одну причинную ось. Наблюдательные counters можно собирать совместно, если они не меняют алгоритм; их времена не становятся acceptance samples. Host-side census допустим для выбора формы, но не доказывает стоимость будущего Bend pass: её измерять в настоящем compiler executor.

Общая semantic батарея **S**: strict argument evaluation ровно один раз и в прежнем порядке; erased/dependent позиции не оживают; affine values не копируются/не теряются; identity/public/foreign boundaries сохраняются; callback/reentry, errors и cleanup; reachable Region fallback; trace/fuel/quantum. Equal stdout недостаточно. Общая квалификация — §7.

### E01. Добавочное fusion coverage и lifetime-классы

- **Гипотеза:** после existing generator fusion/scalarizer остаются горячие безопасные Direct→known-consumer BIR sites.
- **Место:** `backend_lower.lower_complete`; `backend_ir.Code/Let/Direct/Return`; `js_backend.plan_of/cont_of`, до генерации `$k`; reports существующего generator deforestation.
- **Control/candidate:** R12 без rewrite против analysis-only отчёта: каждый site, exits, field uses, captures, escape/Apply, SCC, Region leaves, уже снятая работа, причина отказа и clone estimate. Различать phase invisibility и contract rejection. Для runtime relevance использовать известные G33 anchors и counters лишь для новых неизвестных sites.
- **Сценарий/измерения:** ordinary private-result consumer с branch/affine field и отрицательными foreign/identity/opaque примерами; затем BIR полного frozen workload из реального compiler path. Dynamic calls, capture sizes, внутри/через chunk/public boundary; не сохранять весь graph ради counters.
- **GO/STOP:** конкретный дополнительный hot admissible site открывает E05. Нет добавочного покрытия, нужен unknown Apply или удаление live frame — остановить G34 как ближайшую реализацию, не расширять safety predicate ради успеха.
- **Объём/решение:** малый census, без schema change; определяет, есть ли вообще задача для BIR fusion.

### E02. Цена analysis/rewrite/validation

- **Гипотеза:** emit tax G32 вызван анализом/перестройкой и новой validation, а не главным образом размером печатаемого JS.
- **Место:** архивные `backend_transport.optimize/result_widths/optimize_program`; `js_backend.emit_linked/program_source`. G33 logical markers — образец завершённых CPS intervals.
- **Control/candidate:** отдельный G32 sandbox: unchanged; discovery/analysis-on с rewrite-off и прежним IR; полный rewrite; лишь после нового корректного контракта — reuse/incremental validation. Rewrite-off — diagnostic ablation, не production no-op. Renderer comparison получает **тот же** аутентифицированный BIR.
- **Сценарий/измерения:** ordinary eligible/ineligible calls и complete emission в native и JS executors. Visited codes/blocks, IR identities, candidates/workers, analysis allocations, scalar/planning/source intervals, bytes. Оба width invocation имеют собственные inputs/outputs; malformed cases остаются rejected.
- **GO/STOP:** если analysis-only объясняет tax — удешевить анализ до расширения охвата. Если tax в assembly — E10. Различие входов/обязательность проверки запрещает просто выбросить вторую validation. Не атрибутировать неизвестные samples догадкой.
- **Объём/решение:** малый/средний isolated diagnostic; нужен при выборе новой whole-program analysis ветви, не воскрешает accepted G32.

### E03. Mailbox, captures и JIT — раздельные причины

- **Гипотеза:** экономию горячего result wrapper могут съедать transport/captures, generated code size или JIT work.
- **Место:** `metadata_write`, G32 workers из `producer2039g33_worker_frequency.json.participants`; соответствующий E05 consumer.
- **Control/candidate:** R12 boxed, исторический G32 mailbox и direct-field continuation на **одной допустимой паре**. Fresh-process cold и bounded warm scenarios отдельны. V8 compilation/inlining/deopt evidence — только поддерживаемые закреплённой версией возможности; не менять caps/jitless режим ради acceptance.
- **Сценарий/измерения:** реальный affine Array consumer, не пустой tuple loop; actual JS checker обязательно для переноса вывода. Source operations, actual emitted shapes, code/bytecode/compile events, allocation/GC и clean pipeline отдельно; S. Source stores не равны machine stores.
- **GO/STOP:** aggregate/transport исчезает без новой сопоставимой frame/closure и code explosion — основание продолжить. Только warm microbench win или отсутствующие JIT evidence не устанавливают compiler win/причину.
- **Объём/решение:** targeted diagnostic после применимого E05; выбирает transport, не требует native-check выигрыша от JS mailbox.

### E04. Retaining paths и live continuation/source owners

- **Гипотеза:** часть memory pressure — владельцы/captures, удерживаемые дольше логического использования, а не короткоживущие wrapper allocations.
- **Место:** scheduler pop/advance/chunk; `checker_core_step_runtime.runSteps`; arena publication/rewind/release и CheckedProgram→lower handoff.
- **Control/candidate:** R12 с read-only lifetime accounting; затем только одна доказанная release/capture correction. Никакого forced GC или хранения полного графа в acceptance instrumentation.
- **Сценарий/измерения:** nested Pending, branches, callback/reentry, failure, 63/64/65 transitions; реальные check/handoff boundaries. Birth/pop/max live frames, captures/retaining paths, пересечение yields, owner reachability; used/reserved/external, guardian RSS/footprint отдельно. Ограниченный snapshot — лишь если входит в прежние caps и с явной perturbation оговоркой.
- **GO/STOP:** найден dead capture/owner без будущего resume — можно исправлять. Live resume/rest остаются. Нет retaining-path proof — нет live-heap claim, pooling/reuse или обещания убрать StackMore.
- **Объём/решение:** ограниченная lifetime instrumentation; prerequisite E12 и memory claims, не повтор allocation sampling G33.

### E05. Bounded BIR producer→known-continuation specialization

- **Гипотеза:** E01 нашёл дополнительный hot class; передачу результата можно заменить field arguments общего continuation без mailbox.
- **Место:** existing `Code/Direct/TailDirect/Let/Construct/Project/Return/Branch`, target-neutral boundary до renderer. Первый scope — acyclic known producer, без произвольных recursive/opaque callee преобразований.
- **Control/candidate:** R12 против только pass; analysis/rewrite-off — отдельный cost control. Producer исполняется один раз, каждый успешный exit вызывает один общий `K_fields`; suffix не копируется на каждый exit. Boxed originals остаются только для реально оставшихся callers; мёртвые workers удаляются.
- **Сценарий/измерения:** ordinary source consumer, branch exits, nested strict calls, affine captures, erased/dependent fields, ID/name collisions, escaping negatives; actual compiler site из E01. S, fresh code/local/region IDs с учётом JS `$k`, capture words, code growth, RC/drop, реальное удаление aggregate и появление новых frames, pass cost. Candidate stage1 bytes могут быть новыми, но stage1=stage2.
- **GO/STOP:** transform реально применён на compiler path и снимает materialization без равноценной замены — полный маршрут §7. Только toy win — stop compiler-acceleration claim. Нужны sum/recursive joins/свободный Region exit — отдельный E11, не скрытое расширение этого опыта.
- **Объём/решение:** средний bounded pass; зависит от E01 и cost contract E02. **Не безусловный первый implementation.**

### E06. Точное повторение NF и lifetime-bound reuse

- **Гипотеза:** descriptor normalization повторяет те же запросы под тем же immutable context и budget.
- **Место:** `descriptor_nf.NfContext/nf/normalize/normalize_in/answer_in`; catalog/lower и C layouts. Shared context внутри lowering уже есть.
- **Control/candidate:** сначала census точного `(descriptor identity/structure, context version, env, binder level, fuel)` на public NF entry; затем один pass-local reuse closed results. Предпочесть стабильное callsite reuse общему дорогому structural hash. Отдельная более узкая гипотеза — переиспользовать уже построенный NF index между catalog/lower, не весь result cache.
- **Сценарий/измерения:** dependent aliases/open vars, erased types, failures, IO/export descriptors и actual compiler. Exact hits, reductions, key/index cost, table size/lifetime, failure class/budget, no transient handles retained; output/IR bytes для preserving варианта и S.
- **GO/STOP:** нет точных повторов или lookup/retention съедает работу — reject cache. Повторы есть и reuse корректен — bounded proof и §7. Не наследовать пользу G26 one-entry reuse; это изолированная проверка.
- **Объём/решение:** малый census → ограниченное reuse; определяет context/version ownership без переноса normalization в FIR.

### E07. Canonical query один раз на неизменный обход

- **Гипотеза:** `has_canonical_name` повторно нормализует один query под тем же scope на каждом Names row; локальный carry дешевле повторной работы.
- **Место:** [checker.bend](../bend2/selfhost/checker.bend):3872–3884 — наблюдаемый факт, full-root значимость неизвестна. `scalar_schema_nat`:7148–7163 — отдельная похожая кандидатура, не включать обе правки в одну версию.
- **Control/candidate:** сначала query/list-length/early-exit census; затем только hoist query в private loop. Сохранить пустой список без лишнего вычисления, short-circuit, canonicalization элементов и authoritative module scope. Не менять Map.bit/G29 и не добавлять global IDs.
- **Сценарий/измерения:** empty/early-hit/miss, aliases/shadowing, same local spelling в разных modules/kinds, Unicode/NUL; actual check. Query computations на lookup, rows, extra captures/CPS work, diagnostics, S; native/JS отдельно.
- **GO/STOP:** удалена существенная actual work с прежним поведением — §7. Повторы редки или carry/frame дороже — закрыть ветвь, не переходить автоматически к глобальной identity migration.
- **Объём/решение:** малый source refinement; последующее selected-symbol→key→lookup reuse в catalog — отдельная явно изолированная ветвь прежнего G26, только по своим counts.

### E08. Изолированная проверка повторного publication walk

- **Гипотеза:** в текущем R12 сохранился второй ненужный occurrence publication/reconstruction walk; его можно убрать отдельно от пакета G26.
- **Место:** `checker.arena_publish_occurrence/arena_publish_occurrences/arena_release`; `CheckedProgram`; `producer2039g26_occurrence_census.json.analysis`. Сначала сверить текущие fast paths/memo: не предполагать, что отсутствует уже сделанное улучшение.
- **Control/candidate:** R12 против только removal доказанного повторного обхода; первая publication и closure binder/result handles сохраняются. Не вырезать type/proof occurrences по синтаксической классификации.
- **Сценарий/измерения:** dependent body, partial failure, inspection/handoff, несколько modules и rewind/reuse; actual check→lower. Visits/copies, final source/checked facts, no dangling transient refs, S; peak и retained отдельно.
- **GO/STOP:** второго walk нет либо он необходим для closure — stop. Убраны visits, но не улучшилась полная pipeline — не объявлять performance acceptance. Доля синтаксических nodes не является byte-saving bound.
- **Объём/решение:** средняя historical decomposition; memory attribution требует E04; не новая FIR representation сама по себе.

### E09. Уменьшить metadata updates, а не только коробку

- **Гипотеза:** на обычном append capacity/depth неизменны, но `metadata_write` каждый раз выполняет их Array.set; можно уменьшить реальную работу в обеих compiler lanes.
- **Место:** `checker_arena.metadata_read/write`:406–428 и pool callers. G33 доказывает частоту вызова, **не** количество неизменных значений. `reserve_words`:1099–1120 уже amortizes publication — его не изобретать заново.
- **Control/candidate:** count growth/ordinary/rewind classes; затем один внутренний update на source branch, где неизменность уже доказана. Не добавлять read/compare на каждый append вместо убранной операции. Public Array, packed storage и foreign ABI не менять.
- **Сценарий/измерения:** capacity boundary, append/read/rewind/append, name cleanup, zero counts; actual metadata callers. Actual set calls/emitted work, capacity/depth/generation invariants, Array ownership/drop, final tape/counts, wrapper costs отдельно и S.
- **GO/STOP:** no-op updates подтверждены и сняты без иной работы/нарушения intermediate-observation contract — bounded proof и §7. Counters опровергли предпосылку или экономия съедена новым control — закрыть. Source Array.set ещё не доказанная machine write.
- **Объём/решение:** малая operation-level правка, не зависит от нового IR; наиболее прямой известный горячий source-work кандидат, но выигрыш пока не измерен.

### E10. Reuse scalar/capture/assembly analyses

- **Гипотеза:** внутри source assembly есть повторные scans/facts, которые можно убрать при прежних output bytes.
- **Место:** `js_scalar_block_ok/js_scalar_program`, `plan_of/plan_block`, `program_source`. `cat([...])` уже существует; «внедрить builder» без нового evidence не предложение.
- **Control/candidate:** реальные CPS boundaries scalar/plans/codes/declarations/families/final assembly; затем только один reuse suffix/read facts или removal повторного scan на **той же версии BIR после scalar rewrite**. Scalar-off — diagnostic ablation, не preserving golden.
- **Сценарий/измерения:** existing scalar local/region/capture consumers и actual full emission. Visits, fact lifetime, coverage, transitions, bytes/hash, clean pipeline, allocation/GC, S. Не подменять реальный output повторением пустых строк.
- **GO/STOP:** повторная работа доказана и снята с прежним результатом — §7. Цена unavoidable output/runtime — не переписывать string layer. Не обещать убрать весь 13-секундный interval.
- **Объём/решение:** средний local emitter improvement; уточняет потребность shared analysis, не языка BIR.

### E11. Явные result shapes и локальные joins

- **Гипотеза:** E01/E05 нашли hot shape, для которой existing BIR вызывает недопустимое клонирование/captures либо не выражает нужный локальный переход.
- **Место:** `backend_ir.Block/Code`, `backend_lower.Frame/State`, все traversals и C/JS planning/physical emission.
- **Control/candidate:** existing-BIR specialization против одной ограниченной новой формы: finite return-shape metadata либо nonescaping parameterized local join. Не одновременно SSA, backward edges и multi-result public ABI.
- **Контракт/сценарий:** lexical scope/dominance, parallel parameter binding, branch-specific ownership, deterministic numbering, failures и Region leaves. Ordinary diamond, nested pattern fallback, multiple returns, affine field и opaque negative; конкретный compiler blocker E05.
- **GO/STOP:** нет доказанного выразительного/code-size blocker — нет schema change. Новый узел только переименовывает G32 mailbox либо renderer не имеет полного ownership implementation — reject. При GO нужны complete implementations обоих targets и §7, не scaffold.
- **Объём/решение:** архитектурная cross-backend migration; открывает joins только по evidence. Первый scope — forward/acyclic; loops/backedges отдельны.

### E12. Layout/lifetime живых continuation frames

- **Гипотеза:** E04 обнаружил дорогой live frame с лишними/dead captures или неоптимальным storage, не «ненужную continuation» целиком.
- **Место:** typed heterogeneous Stack/Run, JS split/runtime, C sharing/frame release и source resume.
- **Control/candidate:** одна liveness/capture-layout коррекция. Не повторять G30 `chunk_state`, не flatten-ить dependent stack в giant dispatcher. Pooling/reuse лишь при exclusive ownership и доказанном отсутствии alias/reentry.
- **Сценарий/измерения:** nested/reentrant callbacks, Pending, mutually nested calls, failure, 63/64/65 boundaries; actual checker/emitter, seed и selfhost C отдельно. Retaining paths, live depth, capture slots, owner transfer/drop/clear, new dispatch/JIT work, S и full pipeline.
- **GO/STOP:** measurable retaining-path reduction без переноса owner в другую frame — основание продолжить. Потеря continuation behavior — дефект; новый dispatcher/изменённый trace или fuel требует отдельного контракта. Сохранение необходимой live depth не failure layout optimization.
- **Объём/решение:** архитектурная runtime работа после E04; не автоматическая defunctionalization.

### E13. Arena field views до очередного packing

- **Гипотеза:** storage compression окупится лишь если hot users читают нужные поля без полной декодировки Node.
- **Место:** Arena/node/pattern accessors, FIR handle/publication boundary, catalog/State.source; не общий public Array ABI.
- **Control/candidate:** R12 boxed access, исторический G28 packed+decode и новый ограниченный field-view accessor для подтверждённо горячего kind. Неподдерживаемые формы сохраняют реальные старые semantics; никакого фиктивного результата и второго полного boxed Node tree рядом с tapes.
- **Сценарий/измерения:** source parser→check→inspect→lower dependent consumer, несколько node kinds, marks/rewind/publication; actual compiler обеих lanes и C consumers. Decode calls/fields per access, storage/capacity, temporary wrappers, lookup/metadata tax, handle closure/generation, diagnostics и S. Nat/reference не объявляются U32 без representability proof.
- **GO/STOP:** снова полный decode/массовая материализация прежнего дерева — это повтор G28, stop. GO только при новом access contract и actual-path evidence. Выигрыш памяти с проигрышем времени — явный tradeoff, не автоматическое принятие.
- **Объём/решение:** архитектурная representation migration после access/lifetime census; logical occurrence/context semantics остаются отдельным уровнем.

## 5. Что выполнять первым и как выбирать

Это интеграционное решение родителя после обоих разборов и дополнительного уточнения архитектурного эксперта; не голосование за наиболее широкий pass.

1. **E09: классификация metadata updates.** Частота уже доказана G33; теперь нужен конкретный ответ, сколько операций можно не выполнять. Это не повторное измерение того же worker count.
2. **E07: повторная canonical query work.** Дешёвая source-backed развилка с потенциальной пользой обеим compiler lanes; если место холодное — сразу закрыть.
3. **E01: добавочное BIR coverage.** Честно определить, что новая фаза/контракт даёт поверх имеющихся passes. Не строить generic optimizer ради census.

Из них выбирается **одна** bounded implementation с лучшим причинным свидетельством. Не запускать 13 full qualifications и не объединять три правки в «G34». E02 добавляется перед новой interprocedural analysis ветвью; E06/E10 — альтернативы по evidence повторной работы. E04 нужен до любых retained-memory/frame claims.

Архитектурный эксперт первоначально предложил A/E05 как минимальный implementation slice, затем уточнил: **только условно после census**; для цели compiler-throughput source-work/index discrimination может идти раньше. Эксперт по экспериментам предпочёл E01→E02→условный E05. Общий вывод одинаков: fusion не безусловный следующий шаг; выбор зависит от дополнительного охвата и экономики, не от названия IR.

### Условия смены направления

- Нет hot safe incremental coverage E01 → закрыть текущую fusion ветвь; не снимать escape/Apply/Region ограничения ради положительного результата.
- Analysis tax E02 съедает пользу → уменьшить work/scope самого анализа, а не расширять whole-program inference.
- Wrapper снят, но transport/capture/JIT заменил его цену → E03 только если ответ изменит design decision; иначе rejected checkpoint и R12.
- Existing BIR действительно упёрся в выразимость/clone size → E11 с новым контрактом, не общий CFG заранее.
- Allocation уменьшилась, peak вырос → E04; не объявлять причиной GC или live heap без retaining evidence.
- Live frames — E12; source storage — E13; collector reservation не лечить выдуманным ownership fix.

## 6. Рекомендуемая эволюция архитектуры

**Шаг A — меньше source work, прежние логические IR.** Уточнить внутренние pool/lookup/normalization interfaces там, где exact census показал повтор. Сохранить FIR occurrence identity, publication closure и public ABI. Цель — уменьшить исполняемую работу, а не только переупаковать результат.

**Шаг B — bounded analysis capsule на конкретной версии BIR.** Known call/return/escape/field-use/region summaries с ограниченным lifetime; discovery, rewrite и validation различимы. Lowering при возможности сохраняет узкую authoritative provenance, а не заставляет targets выводить всё заново. Не тянуть source arena в итоговый BIR и не добавлять global caches по умолчанию.

**Шаг C — conditional producer/continuation specialization.** Только дополнительный доказанный class; shared continuation, strict fields/captures, deterministic fresh IDs, bounded specialization graph. Unknown/identity/public edges остаются semantic boxed boundary, не молчаливым несовместимым ABI.

**Шаг D — explicit local joins при доказанном blocker.** Формализовать scope/dominance/ownership/fallback/termination отдельно. `Region.next` — pattern fallback и не принимает arguments; `LeaveRegion` нельзя переносить со свободным label в другой Code. Сначала forward local joins, произвольные loops — другой объём работы.

**Шаг E — target-specific physical call/return plan.** Если selfhost C нуждается в multiword private returns, это решение physical lowering с явно boxed public edges. Для JS статический continuation transfer может оказаться выгоднее mailbox; для canonical seed layout-aware returns уже существуют. Семантическая shape и число машинных регистров не должны сливаться в один FIR/BIR контракт.

Это ветвящийся roadmap, не обязательная цепь переписываний. Положительный E09/E07 не создаёт обязанности делать joins; отрицательный E05 не оправдывает бесконечное расширение ABI.

### Неприкосновенные инварианты

- Один source owner; никакого transient handle после rewind; contextual occurrences не схлопываются по term id.
- Erasure, selected declaration identity, descriptor abstract/unknown/failure и fuel semantics сохраняются.
- Strict computations исполняются один раз до transfer; повторное вычисление Symbol/lazy value не подменяется «той же формой atom».
- Affine fields/captures не повышаются до Many; branch alternatives имеют отдельное ownership состояние; borrowed projection не означает владение child.
- Reachable fallback может удерживать ancestor/sibling; cleanup, exceptions, callbacks/reentry и continuation rooting сохраняются.
- Trace events, один fuel-unit per transition, quantum64 и внешняя Run-state boundary не меняются ради benchmark.
- Новая версия получает собственный deterministic byte fixedpoint. Её bytes не обязаны совпадать с R12, но stage1 и stage2 обязаны совпасть точно.

Нормативная опора: [FIR_LAWS.md](../bend2/selfhost/FIR_LAWS.md); [BIR_LAWS.md](../bend2/selfhost/BIR_LAWS.md):118–217,377–413,792–842,1547–1576,1648–1690,1782–1827. Эти obligations не объявляются доказанными этой консультацией.

## 7. Квалификация жизнеспособной реализации

### До большого запуска

1. Зафиксировать один scope, гипотезу, exact source/runtime/tool hashes, R12 control и **неизменный workload**, отдельно candidate root. Сохранить failed/rejected versions и требуемые frozen source inputs. Коммит каждой версии до следующей; images/ASTs/profiles/bulk logs не добавлять в Git.
2. Реальный ordinary source consumer на изменённом пути и S на C/JS. Canonical-only smoke не доказывает selfhost renderer; hand-built BIR negatives не заменяют source→check→lower→emit.
3. Bounded actual-stage proof reachability и predicted effect. Для scheduler/frame/capture изменения включить существующий C scheduler case **до** дорогой общей qualification. Старый timeout не повторять ради подтверждения; проверять изменённого кандидата.

### Основной runner

Текущий интерфейс — `evals/g24_qualification.mjs --phase=all --fail-fast-performance=true`, новый уникальный run-id/out, pinned tools, R12 bindings/control-native/control-image и прежний frozen repository. Точные опции взять из runner/сохранённых команд G32 после проверки доступности tool paths. Не оборачивать orchestrator ещё одним heavy_gate: он уже защищает heavy stages.

Фактическая последовательность `runCorrectness`:1250–1428:

1. Аутентифицированная регенерация owned source и трёх typed CPS step modules.
2. Fresh parser prepare/source/native semantic gates и accept.
3. Полный compiler root+manifest; component JS build.
4. Полный native build через llvm-split; полная body/event coverage, zero exclusions/output patches.
5. Настоящий native stage0 → stage1 → stage2 bootstrap и **raw byte equality**, с исходными fixtures/fuel/quantum.
6. Все 12 unprofiled serial interleaved full-pipeline measurements. Candidate native/JS outputs согласованы; control output совпадает с authenticated baseline. Никаких profiler/marker timings в этой серии.
7. Declared performance rejection публикуется до throw. Отказ останавливает дорогие consumers; это корректно сохранённый rejected candidate, не принятая частичная реализация.
8. При проходе — emitted seed/stage-one/stage-two suites; все текущие C matrix cases, затем все JS cases. Authority числа cases — runner/pins, не старое зафиксированное число.
9. Native/library/foreign → admission → nested host/alias/export consumers; повторная authentication root/image и отдельное parent acceptance.

Источники: [g24_qualification.mjs](../evals/g24_qualification.mjs):76–85,1119–1243,1250–1428; [native_seed_runtime.mjs](../evals/native_seed_runtime.mjs):113–170; [selfhost_throughput.mjs](../evals/selfhost_throughput.mjs).

### Policy не смешивать с семантикой

Для G32 был явно выбран strict G29 policy: по каждой native/JS lane candidate mean **и** median pipeline строго ниже control; медианы peak RSS/footprint не выше; 3+3 rows на lane, все 12 samples сохранены. Это opt-in fail-fast rejection policy, не универсальный закон архитектуры. Флаг false отключает только эту ветку, не correctness/consumers/hard caps. Не менять policy молча или задним числом; сознательный backend tradeoff требует отдельного решения до результатов. Отозванный assistant-invented +5% threshold не возвращать.

Hard caps сохраняются: RSS/footprint 8192 MiB, timeout600000 ms, poll10 ms; Node worker stack256 MiB, old6144 MiB, young128 MiB; ABI13, parser fuel8M, quantum64. Все оригинальные samples/failed attempts остаются, дополнительная серия не заменяет неудобные rows. `--phase=throughput --from-receipt` требует passing authenticated correctness; частичный performance rejection с `correctnessPassed:false` нельзя выдать за завершённую correctness.

## 8. Что реально проверено в этой консультации

Родитель перечитал актуальные BIR forms, lower handoff, existing source fusion и scheduler generation order, JS continuation synthesis, metadata operations, NF index construction, C return/storage и canonical return emitter. Доступных language servers нет; read-only session searches не дали нужных hits, поэтому первичными оставались source/receipts.

Дополнительно **исполнен offline replay** текущей экспортированной `performanceDecision` на неизменённом `.throughput` из G32 receipt, Node23.11.0 с `--experimental-strip-types`:

- `PRESERVED_G32_POLICY_REPLAY_PASS`;
- исходные 12 rows: native3+3, JS3+3;
- rejected=true, measurements unchanged, heavyRunsExecuted=0;
- SHA256 исходного receipt: `e36f074255802f21d5ae79da99b722dd40cf3c620a628bde9dd90680e433af4f`.

Это проверка воспроизводимости прежнего policy, не новые timings, не новый fixedpoint и не принятие E01–E13. Все эксперименты, архитектурные формы и ожидаемые механизмы выше остаются явно помеченными предложениями.

Проверка отчёта: `ARCHITECTURE_REPORT_REFERENCE_AND_BASELINE_CHECK_PASS` —
29 относительных ссылок ведут к существующим primary sources, каталог содержит
13 уникальных E01–E13, 21 уникальный source input совпал с G33/R12 authority
по SHA-256. Это проверка ссылок и неизменности базы, не runtime-проверка
предложенных оптимизаций.

## 9. Исполненные результаты после консультации

### E08 — G35: fixedpoint пройден, кандидат отклонён по памяти

Реальный census R12 выявил 12 102 уже опубликованных checked-definition roots
и 528 012 повторных occurrence visits на успешном declaration-closure edge.
Изолированная реализация сохранила общие publisher'ы, закрытие binder/result/body
и все обходы на неуспешных/непроверенных путях.

Свежий полный native root проверил **12 452 определения / 13 046 событий**
без exclusions/output patches. Настоящий native-stage0 → stage1 → stage2
byte fixedpoint прошёл: оба образа по **31 751 678 байт**, SHA-256
`105247a5fb11ba9a8318b59c7bf30882e473c7f08109b89fad0e276411adae5b`.
Actual stage1 отдельно прошёл source-handle closure, inspection, dependent /
erased / affine consumers, strict order и success → failure → success.

Все двенадцать исходных unprofiled paired samples сохранены. Pipeline mean
и median улучшились в обеих lanes, но native median RSS и JS median RSS /
footprint выросли. Прежний строгий memory gate отклонил G35; поздние consumers
намеренно не запускались после fail-fast. Сбои двух canonical-smoke preparation
попыток на legacy IO syntax сохранены как failures, не semantic PASS.
Rejected source/frozen inputs: **914b218c**. R12 восстановлен, совпали исходный
checker, 21 baseline check, три regenerated sources и accepted artifact hashes;
шесть canonical C/JS consumers прошли. Это не новый R12 fixedpoint.
Primary evidence:
[qualification](../evals/receipts/producer2039g35e08_qualification.json),
[restoration](../evals/receipts/producer2039g35e08_restored_r12.json).

### E13 — проверен одно-полевой доступ, новая decode-обёртка не оправдана

На настоящем R12 checked program два чтения каждого из **464** nodes вернули
тот же stored object: **928** чтений, **464** identity matches. Для **99**
`TermAll` прочитан `body_id` с сохранением полного tagged handle; source closure
и последующая inspection прошли. Это проверка существующего доступа, не
доказательство выигрыша новой field-view реализации.

Generated C аутентифицирован через SHA-256 принятого native build: getter
передаёт один уже хранимый Node `Term` и два ArenaStore words, не декодирует
packed Node. Arena reconstruction, RC и result/scheduler wrappers остаются;
native allocation/timing saving не заявляется. `get_node` плюс projection
не устраняет Node materialization, которой здесь нет. Новые columns/storage
не вводятся без отдельного доказанного ограничения; G28 packing не возвращён.
Primary evidence:
[field access](../evals/receipts/experiments_e13_field_access.json).

### E01 / E11 — измерен реальный coverage; новая форма IR не нужна для найденного случая

Полный R12 census завершён с исходным output SHA-256. В фактическом BIR:
24 025 codes, 13 871 Direct sites; 343 codes входят в 87 recursive SCC.
Все шесть `metadata_write → *.tables` sites допускают ограниченную
специализацию: два Affine fields, известный consumer, 13 retained parameters,
без free Region exits. Это статические свойства настоящего compiler BIR,
не новые динамические частоты каждого site.

**E01 завершён; E11 — STOP расширению schema.** Для этого случая достаточно
существующих Code/Let/Direct/TailDirect и shared field continuation.
Отсутствующий optimizer не является representational blocker. Это не
доказательство для произвольных finite sums, recursive producers или free
Region exits; исполнение и квалификация самой специализации относятся к E05.
Primary evidence:
[coverage](../evals/receipts/producer2039e01e13_coverage.json),
[discovery / frozen corpus](../evals/receipts/experiments_e01_e04_e07_e11_discovery.json).

### E02 — исполнены три source cuts на native и JS

Для unchanged / discovery-and-plan / full-rewrite собраны три полных native
compiler roots с нулевыми exclusions/output patches; все три реально
скомпилировали неизменный frozen workload. Выходы каждой native/JS пары
побайтно совпали. Unchanged и analysis передают renderer один исходный BIR:
SHA-256 `86a411147b9b455fa9af59cdf32d9eddccb1fa6befc68096411bbea9f9f2b287`.
Full передаёт переписанный BIR; его выход совпал с историческим G32.

| Source cut | Native emit, с | JS initial validation, мс | JS validation-exit → plan-complete, мс | JS plan-complete → backend-entry, мс |
|---|---:|---:|---:|---:|
| unchanged | 14.376 | 729.49 | — | — |
| analysis | 14.501 | 818.82 | 971.60 | 0.44 |
| full | 14.797 | 755.08 | 761.42 | 180.13 |

Это по одному диагностическому execution на mode/lane, не paired acceptance.
JS intervals включают instrumentation / fingerprint / completion overhead;
analysis строит worker bodies и не изолирует «чистый abstract analysis».
Native subintervals и native BIR object identities не измерялись.
**E02 завершён; обе width validations сохранены.** Допущен только дальнейший
ограниченный E05 с обязательными semantic / full-root / fixedpoint /
performance / consumer gates. G32 не принят повторно.
Primary evidence: [ablation, commands, guards and required source inputs](../evals/receipts/experiments_e02_ablation.json).

### E04 — живые continuation frames и конкретный устаревший argument root

Полный compiler execution прошёл; birth/pop/capture lifetimes наблюдались
только в объявленных четырёх окнах. Resume/rest/capture state реально живёт
через yields: удаление всех StackMore или defunctionalization этим не
обоснованы. Между окнами lifetime не экстраполируется.

После check runtime quiescent (`sp=0`, `ksp=0`), но argument array длины
154 206 сохраняет `$stArgs[8].transient` из `check-result-drop-transient`.
Boundary scan ограничен; положительный retaining path конкретен, отсутствие
других roots и retained bytes не доказаны. **E04 завершён.** Только этот
retired suffix передан в E12; native/GPU frame claims не делаются.
Primary evidence: [lifetimes and declared coverage](../evals/receipts/experiments_e01_e04_e07_e11_discovery.json).

### E07 — STOP hoist: все реальные lookup'и пустые

Все 628 584 измеренных `has_canonical_name` lookup'а завершились на пустом
списке: ни query, ни element canonicalization в этих walks не вызывались.
Hoist добавил бы работу вместо её удаления. Empty-list short circuit сохранён;
это решение для неизменного workload, не утверждение обо всех программах.
Primary evidence: [queries and exact histogram](../evals/receipts/experiments_e01_e04_e07_e11_discovery.json).

### E05 — G36: actual transform и source S пройдены, native build отклонён

Compiled Bend pass прошёл всю матрицу: **13 modes / 52 C/JS executions**,
включая сохранение strict allocation failure, captures, collision/overflow
refusals, shared continuation и живые public originals. На настоящем полном
compiler BIR применены все шесть metadata sites. Word worker принимает
19 parameters, общий field continuation — 15: два Affine fields плюс
13 retained values. Все три `Array.set` и их operands/descriptors/order
сохранены; MetadataTables temporary отсутствует, Arena/Tuple остаются.

Отдельный ordinary source S проходит настоящий parser/expander/checker,
compiled Bend pass и C/JS renderer'ы. Все четыре original/optimized executions
печатают 0; original JS побайтно совпадает с настоящей selfhost emission.
Сохранены failures ранних diagnostic setups, а не переименованы в PASS.

Полный маршрут остановлен на неизменном hard cap. Book validation проверила
12 648 definitions / 13 263 events без exclusions/output patches, но native
`compile_book` превысил 8 GiB footprint: **9 093 225 672 B** при RSS
**9 085 878 272 B**, guardian **24 079 ms**. Native executable,
bootstrap/fixedpoint, performance series и поздние consumers не получены.
**E05 завершён: G36 rejected.** Compiler-acceleration claim — STOP.
Причина роста внутри codegen не измерена; успешный маленький pass не заменяет
полную native qualification и не разрешает повысить cap.
Primary evidence: [G36 rejected source / frozen inputs / preflight](../evals/receipts/producer2039g36e05_rejected.json).
Rejected source/frozen inputs: `ce28d3c0`. R12 восстановлен с 21 baseline source
check, тремя regenerated source hashes, удалённым rejected module, прежними
accepted artifacts и шестью canonical C/JS source executions. Это не новая
full qualification: [restoration proof](../evals/receipts/producer2039g36e05_restored_r12.json).

### E03 — исполнен: microprobe/JIT PASS, mandatory whole checker STOP

До измерений выбран один canonical полный compiler producer **во всех трёх
lanes**. Source/build/nominal-schema authority аутентифицированы; новый fixture
зафиксирован на восстановленном R12 source `b2192313`, а не ошибочно приписан
более раннему R12 checkpoint. Все три исходных BIR дерева побайтно-структурно
эквивалентны после настоящего typed nominal transport. Direct post-pass BIR
полностью равен результату compiled Bend E05 pass на том же input. Доказан
реальный Word edge с 19 worker / 15 shared continuation parameters,
двумя Affine fields, 13 retained values, тремя ordered `Array.set`,
нулём новых captures, свежими IDs и сохранёнными Arena/Tuple.

Каждая real emitted library исполняет один cold и пять warm `probe(1)` вызовов;
clean, scalar-counter и supported-JIT lanes — в отдельных процессах.
Все **54** actual results — 0. Ни synthetic tuple loop, ни host parser/checker
не заменяют compiler/consumer:

| Transport | Consumer bytes | Cold, ms | Warm 5 calls, ms | Registered frames / cold | Registered capture slots / cold |
|---|---:|---:|---:|---:|---:|
| R12 boxed | 1 058 366 | 12.344 | 7.464 | 3 223 | 19 210 |
| G32 mailbox | 1 063 794 | 13.401 | 7.858 | 3 223 | 19 210 |
| G36 direct-field | 1 060 088 | 12.203 | 6.854 | 2 882 | 14 777 |

Счётчики — logical registrations/slots всего probe, **не** machine stores,
allocation bytes или retained bytes. Generic original producer обслуживает
также другие metadata edges; его общий entry count не равен Word-only count.
JIT traces содержат по два matched optimization-text events на наблюдаемую
функцию; matching inlining/deoptimization events нет. Это не доказательство
успешного конкретного tier, inline или отсутствия deopt вне окна.
Single cold/five warm observations не являются paired production acceptance.

Независимый настоящий renderer сначала воспроизвёл полный frozen R12 output,
затем авторизовал direct-field output SHA-256
`bfcbde9922b8e431d7126951f383da12ef87008a209e830e8fad19a029543242`.
Но **все три обязательных actual whole-checker запуска исполнены и FAIL**:
canonical `$String_to_list` исчерпывает прежний 256-MiB worker stack
(`RangeError: Maximum call stack size exceeded`). Остальные исходные guards
сохранены. Unchanged retry, повышение stack и подмена parser не применялись.
`--summary` реально отказал в PASS из-за failed checker lane.

**E03 завершён: STOP whole-checker comparison / transport promotion.**
Ограничение canonical executor не скрыто успехом маленького consumer;
G36 native hard rejection остаётся отдельным FAIL. Canonical component —
не native-stage1/fixedpoint и не accepted compiler.
Primary evidence: [all actual lanes, source inputs, counters and JIT](../evals/receipts/experiments_e03_transport.json).

### E10 / E12 — измеренные GO, source qualification ещё впереди

E10 подтвердил два разных Program wrapper'а с одной и той же точной парой
immutable family/type-function lists: повторён один marker-index build.
Допущен только emission-local reuse этой карты, не Program-identity cache
или широкая memoization.

E12 actual image correction отслеживает все **пять** capture registration
paths, включая `$split_enter`. Пропуск пятого hook реально воспроизведён:
direct capture остаётся; исправленный вариант удаляет его. Nested prefix,
lexical capture, exact error/reentry и region protocol сохранены. Два настоящих
source consumers исполнены во всех original/truncated/owned вариантах, а не
только импортированы.

Полный compiler census сохранил прежние output bytes. Полный scan argument
array на всех пяти quiescent phase boundaries нашёл 0 nonundefined slots при
сохранённой длине 154 206; конкретный retired transient path E04 отсутствует.
Это не retained-byte / engine-allocation / performance proof и не утверждение
о любых других roots или pre-entry throws. Обе source версии ещё не приняты.
Primary evidence: [measured admission and limits](../evals/receipts/experiments_e10_e12_admission.json).
