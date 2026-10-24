# Self-hosting: полный handoff следующему сеансу

## 1. Цель и первый шаг

Цель пользователя — кардинально уменьшить память и время компиляции и довести **реальный self-hosting** до завершённого stage1/stage2 byte fixedpoint. Не считать количеством функций до OOM, scaffolding или одними диагностическими fixtures выполненную задачу.

СЕЙЧАС canonical57t typed-native-stack принят по functional correctness:
fresh parser75, public native root8391/8391 bodies8787events, frozen15modules/
7720exports и НОВЫЙ настоящий unchanged stage1/stage2 byte fixedpoint прошли.
Stage images13739548bytes, SHA256c26cebdcf555b03605df7ae88e22c1a6a76ec9bc2ce712fbb487dfbe4ce6d832;
actual cmp/shasum выполнены, stage2 использует stage1 parser+compiler, source/AST patches0.
ВСЕ обязательные285 behavior executions завершены:95seed +95freshstage1+
95freshstage2, каждый emitted image64positive/31negative/130fresh fullAST/span
approvals, cachehits0. Отдельный emitted-suite guardPASS237847ms/1009990040physicalbytes.
Original monolithic600s остаётсяFAIL: byte comparison уже прошёл на507222ms,
95seed+62stage1 rows успели, это не перекрашено в aggregate acceptance.
Source Run/Stack введён без изменения leaf resume closures/Direct.invoke;
Bound association/host LIFO удалены, имена10/9 exports прежние.3helper bodies/mode,
не3000 frame-site helpers. Все generated wrappers регенерированы, не патчились.
Native C ТАКЖЕ выполнен: тот же root SHAefab3bf81dd52f597645b20ddda482e11b961d342115ab62152535de55c26d26,
bridge8409/8811, prototype fresh C+binary+fullfrozen+7720 consumer занял292.887708s.
В57u интегрирован ПОСТОЯННЫЙ public `--cc-pipeline=llvm-split` и отдельный pinned
Bun backend worker, без/tmp/Python-wrapper dependency. Новый полный smokePASS:
build276744ms/6193748688physicalbytes, frozen93329ms/1300793432bytes,
7720 actual consumerPASS; whole measured cycle370.743257s, НЕ stable300s.
Backend97628.932ms близок prototype96612.559ms; fresh TS→C producer174086.786ms
против prototype97891.856ms при ТОЧНО том же C22e60fac…; причина НЕ установлена.
Guard8GiB/poll10ms/исходные deadlines прежние. LLVM defaults/requiresO1, four-way
split/max3 backend children; source/tool/ABI и real Darwin time CPU/maxRSS receipts
в compiler-ir-checkpoint-v57u.json. Direct default сохранён, отдельно не пересобирался.
Строго same-host official наM3Pro/Node26.3 теперь8619.362542ms, НЕ старые32s
другого окружения. Native93s пока намного медленнее; official НЕ обогнан.
Local JS frozen119083.967ms против старогоK142821.056ms, но native JS seed producer
51114ms противQ25347ms: path-specific regression не скрыта. Основной receipt:
compiler-ir-checkpoint-v57t.json. Все source/semantic/native proof pins в нём.

57v: новый currentT native CPU profile завершён на unchanged binary/C и полном
frozen/7720 consumer: checker9394 и emit4708 exclusive-leaf samples, physical
tail calls не выдумываются в inclusive attribution. Checker: sharing/drop28.178%,
Clo.apply16.085%, Map.bit.go12.444%; emit String.append/reconstruction58.815%,
в late emit80.136%. Это sample fractions в явно ограниченных windows, не полный
CPU coverage и не allocation counters. Receipt compiler-ir-profile-v57v.json.
Private register-threaded Run loop нативно проверен8406/8808 и полностью верен,
но actual native93326ms противT93329ms: НЕ продвинут, native speedup отсутствует.
Его JS frozen110506ms не переносится на C; full native cycle375.463s.
Private12 nativeSELF bodies дали controlled positive~5% wall/~10.3% CPU gain;
geometry-only rejection отозван. Однако affine workerPASS/guardian sampler_error
сохранён как failed guarded scenario; canonical cutover/FP для него не заявлен.
Удалены только172 obsolete ownK parse-*.ast.json,793186008bytes; текущиеT
proof transports/исходники/stage images/receipts сохранены, T dependency count0.
После удаления checkpoints10605172KiB (~10.11GiB), включая новыеT proofs.

### Предыдущий correctness checkpoint57q/K (история)

В57q: production FIR→BIR compiler root нативно проверен8382/8382,
полный frozen corpus/7720 exports прошёл, настоящий unchanged stage1/stage2
byte fixedpoint есть. ВСЕ285 behavior executions также завершены:95 seed,
95 stage1,95 stage2; на каждом emitted image64 positive/31 negative и130
свежих full AST/span approvals, cache hits0. Отдельный full emitted-suite run
прошёл270081ms /836957800physicalbytes; исходный monolithic600s gate остаётся
честно FAIL по deadline. Functional IR cutover выполнен; цель по скорости ещё не достигнута.
Предыдущий correctness checkpoint2fabd354/d7e9b9ee и receipt57k/57n. Исторический
performance baseline55 —2b3efa80, не automatic winner новыхT runs. Native O0 отвергнут:clang37.22s,
но whole frozen runtime не закончил check за300s. В57p coverage JSON keys
заменены allocation-tight structural comparison. В57q интегрированы короткие
private FID symbols без изменения numeric IDs, CID и foreign resolver keys;
canonical comp.ts SHA5b934b694b873c9b2e44a6d99b920181cc72e660b30996566bfaee38a7ba0fda.
В57p свежая parser75/75 chain и native8382/8772 seed прошли; actual cmp подтвердил
тот же executable SHA c27cead..., поэтому establishedK fixedpoint/285 behavior
относится к тому же программному образу, не новому timed gate. Kernel2.0.37 прежний.
Private currentK C build57p проверил8400/8796 и выдал C за~101.6s, но clangO1
пересёк8GiB RSS (8590409728bytes); лимит не повышен, binary не заявлен.
57q реально собрал currentK8400/8796 O1 под прежним8GiB guard:
242981ms, RSS8342945792, physical8165500744. Затем полный frozen compile
прошёл104823ms /1301612680physicalbytes, output SHAeb3d374..., actual7720 consumerPASS.
PhaseCPU/wall подробно в compiler-ir-checkpoint-v57q.json; wall parse3644.196,
expand6081.754, check79895.09, emit13014.165ms. Official total32002.610417ms.
Build+run347804ms измерены двумя командами: <=300s пока НЕ достигнуто;
запас RSS всего~247MB, повторяемый memory win не заявлен.
Private successful producer и canonical различаются только comments:
stripped executable TS-transpile bytes совпали SHA90c3ef4f58ba4b7b9e2414c293828ded3ffa1797e4751e4c9897f313f669beb3.
Свежий canonical native seed8382/8772 прошёл25347ms и actual cmp сK подтвердил
тот же root source SHAe404aea... и JS c27cead...; foreign C consumers actual42/77.
Отключение LLVM passes в отдельном57q experiment упёрлось в physical8GiB после306856ms:
отвергнуто, output/binary отсутствует. O0 тоже отвергнут, guard не повышать.
57s shorteningCID тоже отвергнут: current8400/8796 native bodies/C emission прошли,
codegen92780.613ms, но clangO1 превысил RSS8GiB за151850ms
(8590475264RSS/7125802760physical). Binary/runtime/consumer не получены;
source delta НЕ интегрирован, process_run.c остался прежним. Receipt57s сохраняет failure.
Удалены completed own rawM/P/S namespaces после compact evidence; успешные
self-contained57q/57h snapshots и finalK/N proof transports сохранены.
Последний измеренный checkpoints10014448KiB (~9.55GiB), не прежние100GiB.
57r first-order resume experiment завершён и ОБА implementations отвергнуты дляJS:
полные checker/emitter/template bodies проверены, Base/type/affine consumers верны,
но same-host untraced Node22.22.1 rounds дают canonical4.686s, Frame+Leaf15.243s,
flat40.861s; CPU7.522/17.140/42.692s. Шесть actual123 executions и все semantic hashes
совпали. Результат: compiler-ir-checkpoint-v57r-rejected.json; canonical edits0.
Separate CPU samples:57.9% FrameApply /81.6% flatResume selftime, GC ниже baseline.
Dispatchers3.24/4.65MB; JIT-mechanism лишь INFERENCE, deopt evidence отсутствует.
Это rejection данных implementations, НЕ доказательство против defunctionalization вообще:
existing request dispatchers уже группируются, новый giant dispatcher нарушил этот pattern.
Small indexed model и native wrong-witness/reuse proofs сохранены отдельно в
compiler-ir-frame-model-v57r.json; они не дают performance acceptance.
После rejected57r принят57t: native heterogeneous LIFO Stack<A,R> + opaque Run<R>,
старые leaf resume closures сохранены, Bound association и host LIFO удалены.
Нет per-site3000 helpers/giant dispatcher; functional proof в начале этого handoff.
57u добавляет supported matching LLVM bitcode split ДО machine backend без
C/JS patches/ослабления guard. Old partition57g sampler_error и noLLVM-machine
physical failure не доказывали невозможность этого отдельного pipeline.
Parent интегрирует только проверенные изменения; memory/functional acceptance
НЕ означают speed acceptance. Следующая оптимизация внутреннего Run loop остаётся
private experiment до full native/frozen и нового неизменённого byte fixedpoint/285.

## Compiler57 — принятый functional FIR/BIR cutover, performance ещё не принят

Нормативный контракт: [SELFHOST_IR_ARCHITECTURE.md](SELFHOST_IR_ARCHITECTURE.md).
Он фиксирует Checked FIR → lowering → structured Backend IR → JS renderer,
владение/publish/rewind, occurrence identity отдельно от semantic node identity,
освобождение тел после lowering, границы runtime descriptors и native ABI.
Законы F1–F3, L1–L7, B1–B2, G1–G2 имеют явные обязательства и способы проверки.
Неподтверждённый Bend `law` не считается доказательством: нужны связанные с
production functions проверяемые `def` либо честно обозначенное runtime evidence.

Checkpoint реализации57a сохранён отдельно от принятого baseline:
`compiler-ir-checkpoint-v57a.json` содержит хеши исходников и реальные первые
native-ошибки. Frontend, catalog, runtime lowering, BIR renderer и consumer
migration написаны; полный root/corpus/fixedpoint нового пути ещё не приняты.
Checkpoint57a: `3728d396`;57b: `1a366baf`. В57c устранён фиктивный binder -1
при CPS lowering generic constructor domains: реальные типы полей теперь
инстанцируются из datatype context, без ослабления capture checks.
Генерация checker/emitter/template прошла. Настоящий native build pipeline
без parser проверил6910/6910 тел и создал JS-компонент без исключений/патчей.
Receipt: `compiler-ir-checkpoint-v57c.json`; это не full-root acceptance.

Явный readback исправлен: runtime body восстанавливается из occurrence children,
а LocalReference — из lexical term, не подстановленного semantic value.
`Inspection`/`InspectionFailure` сохраняют владельца программы. Реальный
compiled smoke провёл explicit matcher через check → inspection → lowering →
JS execution и получил `BitOne{}`. Live locals/ordering затем прошли fixture ниже.
Legacy standalone C использует явный inspection/readback и не является BIR
backend; обычный JS compile path не должен делать readback.

Полный frozen corpus57 прошёл native check, но compile не уложился в300s.
Рабочий baseline остаётся55; fixedpoint53 не доказывает новую архитектуру57.

Отдельно реально воспроизведён дефект старого explicit constructor eliminator:
неизменённый stage1 образ53 проходит parse/expand/check/emit, но его программа
падает с `bend: runtime fail-stop`; reference CLI с kernel2.0.37 и текущим
shared-layout backend печатает `BitOne{}`. Точные исходники/хеши/наблюдения
сохранены в receipt57b; успешный новый pipeline — в receipt57c. Реально исполнен
15-export library fixture:28 assertions, включая live/unused locals, порядок
over-application и обе ветви eliminator. Использован native pipeline, не старый
compiler; stage53 работал только parser. Это ещё не formal full-root acceptance.
В57d canonical parser получил общий expression/pattern scalar decoder;
U32 patterns больше не попадают в ошибочный PatternNoNat. Сам старый state
и ветка partition generator удалены. Реальный compiled probe прошёл U32
0/1/max, F32 bits, nested/multi patterns и две границы отказа.
В canonical js_emit/lower_catalog computed constructor locals и nested matches
переведены существующим typed native_match_source extractor в parameter-owned
helper defs: это исправление исходников, не ослабление native kernel/AST oracle.
Полный parser semantic gate прошёл75/75 acceptance/semantic/literal-span parity
(`ir57-scalars-b.candidate-semantic-b.json`). Старый preparation proof был
отклонён после source cutover; свежий `ir57-admit-c` прошёл и final parser
acceptance. Receipt57d: `compiler-ir-checkpoint-v57d.json`.

В57e полный ten-export root нативно проверен:8339/8339 bodies,8726 events,
без exclusions/patches; JS seed artifact `.ir57-full-b.js` —12668854 bytes,
SHA256 `4c95b16946f3431555cdeec9fd74c171142f602e2d7400c03f939c4846993af4`.
Build101717ms, peak footprint2972922672bytes, max simultaneous higher bodies2.
Это JS seed build через native checker, не native C executable/fixedpoint.

Первый full-root codegen выявил прежний backend lifetime bug: поздний word-match
constant folding читает уже emitted callee. В `comp.ts` checked e теперь живут
до конца всего JS definition folding, а higher caches очищаются между defs.
Минимальный `[1,4]` пример и regression прошли в retained/released режимах;
официальный CLI fixture реально выполнился с выводом1. Никакого fallback на
unchecked source нет. Builder retention wording/accounting также обновлены;
из-за изменения producer hashes новый final proof требует свежего parser build.

Первый полный JS component benchmark57 достиг600s timeout.
Прежние async phase logs не доказывают, в какой фазе процесс был остановлен.
Не приписывать timeout parser по последней строке stdout. Отдельный exact-input
probe разобрал largest2.45MB source за3.809s; whole loader прошёл все50 files /
15 modules за6.691s. Записаны bounded V8 profiles. Benchmark теперь синхронно
сохраняет active/completed phase и сохраняет partial status при guardian failure.
Bounded90s attribution подтвердил: load/parse5.159528333s, expand8.300180208s,
active phase при timeout — check (`compiler-benchmark-ir57-attribution-a.json`).
Настоящий checker V8 profile содержит56433ticks,70unaccounted,0excluded;
6.3% GC — mixed-window sample share, не allocation attribution. Native nearest
symbol StatWatcher не считать реальным filesystem hotspot. Canonical CPS-owner
aggregation завершена:34180 ticks в checker-only окне30–80s,683 source owners.
Это physical self attribution с inlining, не inclusive logical CPS family cost;
8853 runtime-code ticks остаются неразрешёнными. Старый вывод «не publication /
не WHNF» отозван: из малых self shares он не следует.

В57f нативный C root на misakaindrive собран с O1:8357/8357 bodies
(8339 compiler +18 bridge),8750 validated events,227457ms; peak physical
6796724232bytes. Это регрессия к55:157171ms /4902139784bytes, а не снижение памяти.
Bridge function-type arguments исправлены скобками в трёх местах; kernel прежний.
Полный frozen check прошёл:parse3434.679ms,expand5434.206ms,check264839.309ms,
80468975 calls/resumes. У55 на том же host/corpus/O1/одном потоке check47591.305ms
и6328943 calls. В обеих версиях checker_chunk64; batching не удалялся.
Full compile остановлен guardian на300017ms после завершённой check265120.214ms;
emit/post-check handoff — только INFERENCE, native phase-start markers отсутствуют.
Нет полного output/7720-export consumer и нового stage1/stage2 fixedpoint.

Реальный native owner → emitter → unchanged ESM consumer прошёл BitOne{}.
Полный JS seed57 также прошёл own parser → check → FIR → BIR → library execution:
28 assertions /15 exports,63560bytes, SHA499da2251b920e3ce4fa6d17340603a1ac0dad3291a6891d1782541b78298024.
Это reachable-path proof, не замена полного corpus/fixedpoint.
Новый Base+main123 probe прошёл execution123, но обнаружил полный Word32 occurrence
tree вместо ScalarOccurrence. Diagnostic inspection показывает checked Word.Con<p>
как TermAdt и прямые reply terms; scalar schema ещё требует старые TermFill /
BodyReply. Это конкретный кандидат причины регрессии, пока не measured fix.
Receipt57e: `compiler-ir-checkpoint-v57e.json`;57f: `compiler-ir-checkpoint-v57f.json`.
Сначала восстановить точное распознавание checked schema, затем измерить полный
corpus; свежую immutable parser/producer chain собирать после стабилизации source.

В57g найден и исправлен конкретный scalar/string fast-path regression:
checked Word equation после materialization содержит прямые reply terms и
TermAdt вместо source TermFill. Старые scalar_schema_25/_29/_30 отвергали её.
Теперь checked form распознаётся теми же canonical identity/arity/index guards,
без unchecked fallback или ослабления schema. Native checker-only build прошёл
5629/5629 тел за7579ms, physical774348008bytes.
Base+main123 до исправления:66 TypedOccurrence, depth33; после:один
ScalarOccurrence{bits:123}; реальный unchanged emitted output печатает123.
Это measured diagnostic composition: новый checker + прежний full parser/emitter,
не новый unified full-root/fixedpoint. Исходная scope label throwaway probe
«full8339-body compiler» неточна для after-run; использованы именно два images.

На полном frozen50-file /15-module /8403-declaration corpus такой composition
реально выполнил compile и unchanged7720-export consumer:156371.383708ms,
parse5233.600042,expand6914.034667,check137592.649375,emit6264.322958ms;
peak physical1707392848bytes. Output14928486bytes,
SHAe3a0dfc85a863e3883cd54fa5afb4b67cb049f0572234dc5126ae4caeb6f59de.
Это PASS полного corpus, но не final root admission или stage1/stage2 proof.
Baseline55 пока остаётся selected; official same-corpus total32002.610417ms
по-прежнему быстрее. Новая fresh parser chain `ir57g-admit-a` принята75/75,
unified seed нативно проверил8339 тел за37603ms /2978084712physicalbytes,
artifact12670329bytes SHA9e1201a3e63d09679795fd4e252ecea847da64e71f7ef1e3c57843ee5b526cf3.

В57h phaseTraceVersion2 реально проверен полным native build/run: explicit
phase-start и getrusage user/system CPU присутствуют для всех четырёх фаз.
Whole-process isolation завершает Node codegen до запуска clang; exit Worker
внутри живого Node раньше оставлял около2.34GB RSS перед clang. Новая сборка
8357/8357 bodies прошла319550ms, peak physical6734390896bytes; actual isolated
clang maxRSS8485109760bytes, wall119.73s. Generated C byte-identical неудачному57g.
Это всё ещё больше native55 по памяти и само по себе дольше пяти минут.

Полный native frozen compile теперь PASS: elapsed96048.315959ms,
parse3472.393,expand5686.564,check73155.822,emit11671.854ms;
check14472521 calls,emit664537. Реальный unchanged7720-export consumer прошёл,
output SHAe3a0dfc85a863e3883cd54fa5afb4b67cb049f0572234dc5126ae4caeb6f59de
совпадает с57g JS composition. Check→emit handoff около3ms, не прежняя гипотеза
о долгом handoff. Это frozen-v41 output consumer, не новый bootstrap fixedpoint.
Remote Bun1.2.5/Node26.3.0 отличаются от57e; source-only build ratio не заявлен.
Первый isolated build без SDKROOT упал math.h; второй использовал verified Xcode
SDKROOT. NHS LLVM partition/control оба остановлены sampler_error без binary;
эксперимент не принят, лимиты/монитор не ослаблены.

Actual native CPU sampling: три6s checker окна и одно6s emit окно,2ms interval,
все внутри phase boundaries;7032 checker observations. Physical self shares:
sharing/drop25.697%,closure/work dispatch23.692%,checker dispatch14.903%,
Map11.960%. Это не inclusive semantic attribution: musttail стирает caller history;
306 spin/outlined samples остаются unresolved. Не выводить «WHNF/publication
не стоят времени» из их малых leaf shares. Receipt57h сохраняет tool identity,
точные source/C hashes, owner mapping, sample accounting и ограничения.

Occurrence-only affine usage cutover отвергнут реальным counterexample:
проверка покрытой третьей source case ещё нужна, хотя CheckedFIR содержит только
две runtime cases. Повторное affine use и erased use в покрытой строке правильно
отклоняются нынешним checker. Без explicit omitted-row usage witness удалять
original-case validation нельзя. Receipt: compiler-ir-checkpoint-v57h.json.

В57j объединены две source-level оптимизации без нового BIR/schema/runtime ABI:
definition-root BodyMatch использует свой code вместо административной forwarding
функции только при exact positional header locals и пустом instruction/capture
frame; renderer группирует >=3 distinct-tag Region на том же Local/Capture
в switch. Symbol/lazy getters не группируются. Duplicate tag останавливает группу;
failed nested pattern продолжает исходный остаток cases, labels сохранены.
Combined complete emitter нативно проверен1716/1716 bodies,2002 events,
11647ms /2233269432physicalbytes, без exclusions/output patches.
Actual unchanged15-export library:28 assertions; recursion/mutual/returned/
erased/nonidentity:6; полный Base+native primitive:2; ordered nested failure/
duplicate-tag/wildcard:5. Реальный output содержит switch с тремя первыми tags
и исходный следующий ChoiceA fallback. Постоянный fixture добавлен в полный gate,
теперь94 на image. Ещё нет нового full-root fixedpoint или runtime-speed claim.

Параллельный bounded-metadata native-island кандидат нативно проверен полностью,
но не интегрирован: actual positive consumer уменьшил resumes только0.83%
и wall0.17% в одной seed-first паре. Девять допущенных helpers и cost-analysis
не оправданы measured whole-stage результатом; existing128-node guard сохранён.
Private evidence/patch записаны отдельно, не подменяют production classifier.

Полный57j root затем прошёл8379/8379 native bodies,8769 events,
25531ms /3015699280physicalbytes. Все94 seed fixtures PASS. Настоящий stage1:
14370680bytes, SHAeaed045d38ac27213ddbc071d48c75aac094839922306a2a8ff295b1aada971a.
Stage-one check154055.762834ms; stage-two-check начат329921.296834ms.
Guardian600040ms снова остановил именно stage-two-check: нет stage2 output/
byte comparison/emitted fixtures. Profiled unchanged stage1 Base123 check
12031.690458ms; все2680654 host resumes,1017155 pending,838376 direct совпадают
с57g. Малое уменьшение числа обёрток не устранило emitted-runtime overhead.

В57k оспорено собственное слишком узкое57j eligibility: полный positional
header не нужен. Nonempty ordered subsets header locals используют тот же
code; membership проверяется явно, старый header/Use/env/order не меняются.
Frame всё ещё без instructions/captures, Symbol/effectful operands сохраняют
прежний путь. Complete emitter native1719 bodies; actual15-export28 assertions
плюс13 native-compatible behavior assertions прошли. Полный Base output:
504→315 code functions,221→31 identity forwarders; structural, не speed proof.
Первоначальный новый fixture ошибочно включал reversed/repeated match binders:
native2.0.37 отверг его ещё при parse, oracle правильно остановил полный gate.
Три старых diagnostic assertions на этом input не считать native compatibility.
Fixture исправлен на first/last/gapped ordered subsets;95/image сохранены.
Все прежние cases остались, semantic oracle не ослаблен.

Свежий full root57k нативно проверен8382/8382 bodies,8772 events,26241ms,
physical2989784400bytes; SHA c27cead81e2171be74d19061c5307c216c2c840e66dc422e3007ae03537f068a.
Полный frozen compile и unchanged7720-export consumer PASS142821.056083ms,
check124914.923208ms,emit5654.536208ms,physical2299572496bytes.
Output14101164bytes SHAeb3d374abac9f7e45067174e75c1074966d933467402866eece29556f307559a.
Первый bootstrap-a остановлен на invalid новом fixture; bootstrap-b запускает
исправленный полный corpus с неизменёнными admitted seed/parser artifacts.

В57k bootstrap-b настоящий byte fixedpoint ПОЛУЧЕН: оба неизменённых emitted
image13733899bytes, SHA8aacace8d17a5a8d79e909733d03ccd4b82a5c42d9b269a96276925215d02c0b.
И worker Buffer.equals, и отдельный actual cmp прошли. Stage2 использовал только
stage1 parser/compiler. Stage-one-check154286.482583ms; stage-two-check
251386.003375ms; comparison588140.157375ms, stage-two-execute588159.743084ms.
Полный monolithic gate всё ещё FAIL:600028ms deadline,95 seed +5 stage1 fixtures,
остальные185 не исполнены. Green acceptance не объявлена;285 обязательны.
Отдельная проверка ВСЕХ95 случаев на КАЖДОМ unchanged image запущена с тем же
worker, native AST/span oracle и guard600s; это отдельное behavioral evidence,
не задним числом PASS исходного monolithic gate и не speed claim.

Отдельный first-order typed-frame эксперимент на NHS действительно нативно
проверен и исполнен:359 bodies,523 events; affine Type owner проходит три
конкретных site-indexed Frame/Input/Output семейства. Duplicate owner и reuse
frame отклонены kernel. Наивный Frame<I,O> enum не уточняет I/O при constructor
match и правильно отклонён. Это НЕ доказательство произвольного heterogeneous
continuation stack или drop-in Progress<A>; production CPS не изменён.

57l: два независимых typed chunk эксперимента на NHS не интегрированы.
Yield nonfinished Bound в host LIFO сохранил результаты, но callbacks выросли
2680226→7867755; positive wall5070.927→5080.884ms, negative type3.95% хуже.
Eager bind(Finished, resume) нативно проверил5630 bodies, сократил callbacks4.55%,
но все paired wall хуже: positive4.473%, negatives1.741/1.975%.
Оба прошли actual Base123 execution и идентичные negative diagnostics,
однако «меньше transitions» не равно ускорению. Production chunk64,
semantic WHNF fuel64, classifier и host driver неизменны.
Linux RSS shared-process/maxRSS не является accepted Mac physical-memory proof.
Compact evidence: compiler-ir-checkpoint-v57l.json.

57m: codegen profile переснят БЕЗ per-definition trace. Предыдущие795962
synchronous observer writes доминировали diagnostic profile; их IO не является
стоимостью обычного компилятора. Новый whole Node/Worker guarded run:
8357 bodies8750events, sameC e4890de...,codegen123321.674875ms,
physical3492435872bytes; всего50 progress records, observer chains не найдены.
81188 worker ticks,69unaccounted;44324 nearest node::CreateEnvironment остаются
unresolved, не называются initialization/IO. Visible mat_lits ancestry —
1165/11599 bounded ticks (lower bound, не полная inclusive стоимость).

Private replacement JSON coverage keys на structural lowered-term comparison
прошёл sameC bytes и12 actual retained/released word/default/binder/late-fold/
NaN consumers;codegen101613.215ms в одной diagnostic pair, без speed attribution.
Canonical comp.ts НЕ изменён. Parent57p убрал дополнительные filtered key arrays
в private variant; native full CURRENT K/O1 build с этой версией запущен.
Первый codegen-only57p вызов не имел требуемого inputs.json и завершился до
native validation; затем использован обычный public build, генерирующий proof.
Старый завершённый raw profile directory951580KiB на misaka удалён после
сохранения compact archive/hash. Receipt: compiler-ir-checkpoint-v57m.json.

Первый настоящий gate57g остановлен600103ms во время stage-two-check:
seed93 fixtures прошли; stage-one реально emitted14562034bytes,
SHA3d7b43c127d2ab4f81dc5c38104dc90c83db3c7554bf6ee729ef27107b8a4c5d.
Stage-one check занял202934.488791ms; stage-two-check начат459289.589458ms.
Stage-two output/byte comparison/186 emitted-stage fixtures ещё отсутствуют.
Лимит не повышать и не объявлять fixedpoint. Actual unchanged stage-one Base123
probe прошёл ScalarOccurrence{123} и execution123; host resumes2680654 совпадают
с seed, но profiled check14673.486416ms против seed4382.948584ms.
Это локализует emitted-runtime cost, а не дополнительные semantic steps.
Receipt57g: `compiler-ir-checkpoint-v57g.json`.

Четыре CheckedProgram patterns в tests/selfhost/checker.bend обновлены на metadata
field. Прямой raw CLI check этого теста не прошёл прежний computed match в
template.bend:327; passing direct-test claim нет. Production CPS closure
по-прежнему нативно проверена полностью; transitive raw Template не нормализован
в рамках этой scalar fix.

## Compiler56 — FIR/BIR architecture preflight, not production acceptance

Selected working compiler55 is committed as2b3efa80. User explicitly redirects
work from further micro-optimization toward separate Frontend IR / Backend IR
and substantive refactoring. No production IR cutover or acceleration is claimed.
compiler-ir-contract-v56.json embeds exact native-checked ownership/ANF models,
all first failures, commands, sources, limits and an actual accepted-stage1 probe.

Ownership model checks661 bodies, transfers real Arena/IR/signature handles
through an affine Type result, and preserves source nodes after transient rewind
and slot reuse. Place owning CheckedProgram above Arena/Scope/IR, never IR->Arena:
Arena already imports Scope->IR. Capture final published signatures currently
discarded by check_modules_private's empty case. Source publication fast paths
assume the entire reachable closure is already source-owned; keep that invariant.

Structured backend model uses owned acyclic blocks and atom-only operations;
explicit live args, captures, constructor fields and guarded projections.
Native producer and rendered JS execute result17/noncommuting order and trace
1,2,9,3; erased/partial/over-application behavior is covered in the small model.
This is not generic lowering or a complete primitive/runtime descriptor catalog.

Critical actual observation: accepted emitted stage1 checks a real Bit/id/choose
program successfully, but returned TermLam quantity is None and TermApp has no
resolved argument quantity. Checker2802-2828 discards formal quantity and returns
original application ID;3008-3015 discards checked function;10539-10544 publishes
original elaborated declaration after checking. Thus retaining today's arena
alone is NOT metadata-complete CheckedFIR. Persist per-checked-occurrence facts,
not a raw NodeId-only type cache across contexts. Then cut over full lowering and
JS renderer without Syntax AST readback, migrate callers/oracles explicitly and
require full corpus plus new genuine stage1/stage2 fixedpoint before selection.

## Compiler55 — complete native full workload in81.24s

54 is committed as f5d87361.55 applies existing checked chunk64 before EVERY
native progress reflection, with filled ready helpers preceding public wrappers.
Only evals/native_compiler_driver.bend changes; C carrier ABI, kernel/backend,
source algorithms, semantic fuel and JS53 fixedpoint sources stay unchanged.

Full native build checks8169/8169 bodies, zero exclusions/patches,157171ms;
physical4902139784/RSS7005519872 under8GiB600s. Full frozen50files/15modules/
7720exports compile81244.655ms under8GiB300s; physical1425213576/RSS1180401664.
Parse3430.548ms; expand5131.384ms/950796 host calls; check47591.305ms/6328943;
emit23521.598ms/1897488. All20281365 output bytes retain SHAa1033733…06d29;
actual ordered exports/parser/checker smoke passes. Full recipe240.87s.
Ordinary54→55 times improve11.26% in this pair, not a randomized speed proof.
Physical peak is essentially unchanged despite lower RSS. Official historical
identical-corpus10099.880ms remains much faster. Native binary fixedpoint unproved.

CPU54 instrumented early check/emit10s windows find direct host/evaluator self
only1.381%/1.071%; check refcount/drop/share32.087%, Map22.551%, dispatch17.392%.
Do not turn boundary counts into CPU claims. Next concrete target: native C
Map.bit/string comparison still execute generic structural code, whereas JS
already has canonical primitives. Preserve checked source semantics and borrowed
ownership; test empty/Unicode/U32/presence-bit boundaries before full acceptance.

Evidence: compiler-native-boundary-v55.json includes42-row typed model, failed
forward-declaration preflight, full source/input pins and ordinary run/output
proof. compiler-native-cpu-v54.json records sampling attribution and limitations.
Redundant output removed only after byte verification and actual execution;
native executable/C and JS fixedpoint images retained; no bulk artifacts in Git.

## Compiler54 — full native compile and exact output pass

Version53 is committed as cc5e4b6c.54 changes only native_compiler_host.c and the
native experiment's runtime deadline: the C boundary reconstructs exactly one
flattened TemplateValue/CheckerValue/EmitterValue box before resume AND final
typed adapter. Generated symbolic constructor IDs are required because CID(...)
does not resolve imported colon-qualified constructors. No backend, source
algorithm, semantic fuel or JS image changes.

Fresh full native build validates8166 bodies, zero exclusions/patches; explicit
clang-O1,184972ms, physical5327681440/RSS6840827904 bytes under8GiB600s. Actual
full frozen50files/15modules/7720exports compile passes91557.188ms (guardian91707ms)
under tightened300s runtime deadline, physical1424902328/RSS1523810304 bytes.
Phases: parse3462.637ms, expand7791.109ms, check54306.764ms, emit24498.527ms.
Native host-boundary calls/resumes:21810643/61979047/16875247 respectively for
expand/check/emit; these are not all compiler operations or CPU attribution.

All20281365 output bytes match historical Mac SHA
`a1033733403dddb6214b6433ec55cd385fc210ce0d985871259a25487bd06d29`.
Actual import checks all7720 exports; emitted parser accepts real source with
main declaration and emitted checker executes empty-module semantics. Frozen
output ABI2cad is explicitly pinned. Build/run/smoke recipe278.97s on this run.
This is not an official-O3 benchmark or native binary fixedpoint. The genuine
JS53 stage1/stage2 proof remains unchanged; no redundant JS gate was run.

Exact commands, sources, hashes, resource limits and before/after fault evidence:
`compiler-native-carrier-v54.json`. Historical official identical-corpus total
10099.880ms is still much faster; do not claim it beaten. Primary remaining cost
is checking, then emission. Preserve54 before another architecture experiment.

## Compiler53 — complete JS fixedpoint; native C fault; speed unestablished

Current worktree is candidate53D, not source52: Arena is restored to selected49
to isolate scheduling. The Checker algorithms remain exact selected49. A boxed
affine result carrier and explicit Bound progress move up to64 operational
transitions into checked Bend; this does NOT alter the independent64WHNF fuel.
Production JS/diagnostic/native-C consumers use the new carrier ABI. Frozen v41
output smoke explicitly uses its recorded old ABI, not a production dual decoder.

`compiler-native-chunk-v53.json` records exact attempted lowerers/commands/hashes.
The unpatched native chunk model checks358 loaded bodies and passes17 actual
execution cases, including affine array transport and100000-deep work. This is
only a prerequisite, not compiler acceptance or a speed result.

53A checks12583/12583 bodies and emits two equal19176975-byte images, SHA
`34af7cdd109c5249a02dd41906021f7efc90918c95702e471666b75414edd981`.
The full gate FAILS the original600s deadline at218/273 passing fixtures, so byte
equality alone is NOT accepted. Per-resume helpers add4410 bodies. A separate
unpaired actual-image Linux run takes229364.384ms on a noisy host; no speed claim.
53B reduces this to8149 bodies but exposes a real parser gap at stage-one parse:
canonical inline local definitions under lambdas.53C's two generic callback
helpers check8152/8152 bodies but native JS codegen fails with
`RangeError: Invalid string length`; the expansion cause is not established.
Both workarounds are rejected, not bypassed with unsafe or increased limits.

53D restores exact53B's compact single-getter/Let lowerer and fixes lambda blocks
through the existing parse_body grammar. Parallel-name marker lookahead now
recognizes only a name sequence before equals, not an equals nested in a lambda.
New public regression covers One/Many/Zero locals under affine/reusable lambdas,
RHS outer scope before shadowing and the new body binding. Actual public suite
passes15/15,264 assertions; all admission consumers migrate to the larger suite.
Fresh parser80 passes all75 native semantic/span cases. Full root8151/8151 bodies,
8492 events, zero exclusions/patches; library16/16. All273 fixtures pass,91 on
each of seed/stage1/stage2. Both emitted images16703923 bytes, SHA
`14dd1f829459c7bca9f519d6813612e9a7d847dca8d1e942c24a641b25610348`;
downloaded cmp0. Stage1 root83569.406ms, stage2 root134579.066ms, stage2 checking
98105.959ms. Full gate578861ms, physical2595123256/RSS2638233600 bytes under
original8GiB600s. These root timings include the gate's semantic AST oracle;
they are not an identical-corpus speed comparison against official.

Native-seed frozen50file/15module/7720export compile97942.507ms/check70629.820ms
passes actual import/smoke and exact historical Mac outputa1033733. This is NOT
actual emitted-image timing. One actual53D Linux run hit its unchanged290s inner
deadline: no full compile/output smoke,1960329216-byte peak, no OOM. Host load
22.85→44.82 (max44.87) is high/unstable; no causal speed comparison or rerun loop.
49 remains the performance-selected baseline.

Full C build also completes:8166 checked bodies,199660ms, explicit clang-O1
(diagnostic flags, not official-O3 parity), physical4841764840/RSS5904302080.
Its actual full input parses15modules in3653.813ms, then fails with memory fault
before expansion completes; total4575ms, not OOM/deadline. Bounded LLDB establishes
the cause: C field flattening removes TemplateValue inside NativeTemplateFinished,
but native_drive passes that raw payload to a continuation expecting the box.
The first resumed argument is CID_CON21, expected TemplateValue31;10-frame fault
is not stack overflow. Reconstruct the appropriate family's box with io_box at
the C boundary, including the final return; all three callsites must supply its
CID. Proposal NOT yet implemented. Evidence: native-compiler-v53d-fault-cause.json.
Broader selfhostGreen remains false; do not modify backend or increase stack.

Failed A/B raw ASTs are archived and verified before deletion: A removes341
files1043094329 bytes; B removes132 files210724614 bytes. Archives are local
ignored artifacts, not Git content. Complete D archive71215868 bytes, SHA
`b3c2db6518c0f189f821d54f6d8f6a3f2c3a743a70a744bf92bd991f3918a4e9`,
verified locally/remotely before removing408 raw ASTs1029236281 bytes. Images
remain; completed remote launchers are removed. Compact acceptance:
`selfhost-acceptance-release237-misaka-v53.json`. Commit53 before changing source
for the next version. Do not rerun failed variants or noisy timing loops.

## Compiler52 — full fixedpoint and lower allocation; speed unestablished

Source52 restores selected49 Checker algorithms (rejected50 hoist removed), then
replaces Arena.name's rebuilding Map.get with existing read-only IndexLookup.find.
The original name_ids root is retained. ID0, MAX missing marker and names rewind/
reuse semantics are unchanged. This is not a claim of allocation-free lookup:
Map.bit/Maybe/record adaptation can still allocate.

`compiler-name-read-v52.json` and
`selfhost-acceptance-release237-misaka-v52.json` preserve the full proof/recipe.
Canonical unmodified release2.0.37 kernel6c1df3eb checks8173/8173 bodies and8511
events, zero exclusions/patches. The native build uses the recorded backend
8c33864a67f0fd08; do not conflate it with unmodified official-emitter performance.
Fresh parser76 passes75 semantic/span cases; library consumer16/16; name boundary
regression passes on the actual native CLI. The fixture's first preflight failed
because a local binder was matched; it was factored into ordered parameter
helpers, not bypassed by unsafe.

Actual273/273 seed/stage-one/stage-two fixtures pass. Both unpatched emitted
images18341638 bytes, SHA
`958ff8b8dd80d2c3cbfb36edb4e76bcc87ab7ee73b8be7942fc7fbcf5e7b47bd`;
downloaded cmp0. Stage-one75633.414ms, stage-two90268.889ms (check57448.326ms).
Full gate366678ms, physical2490795592/RSS3799187456 bytes under unchanged8GiB/
600s guard. This is still over5min for the entire gate including fixtures.

Native-seed frozen compile63827.886ms/check45596.202ms passes50files/15modules/
7720exports and actual output smoke, exact historical Mac outputa1033733.
This is NOT actual emitted52 timing. Genuine actual-image normal controls pass
on both hosts. Linux49→52→52→49 observes52+17.695% mean compile time, but middle
runs overlap aggregate load1.28→7.60; cause unresolved. Mac52→49→49→52 observes
52-13.576% mean compile time, but load3.62→23.04 and large time drift also confound
that comparison. Do not call either intrinsic speedup/regression established.
49 remains the last performance-selected baseline; no more repeated timing
loops are planned on these uncontrolled hosts for this version.

Separate sampled cumulative check allocation falls172138113888→147078030184
bytes (14.558%); strict recorded name-read Map rebuilding26550528752→0 and the
replacement find path estimates4009781272 bytes. This is not live RAM or CPU.
Exact sources, load qualification, both normal series and separate raw-profile
hashes are in the receipts. String.eq is native=== in both images: the conjecture
that52 introduced a Unicode equality loop was falsified by actual declarations.

Historical same-input/same-Node23 Mac official baseline:10099.880ms total;
load/parse/expand1094.375ms,check993.196ms,emit7947.939ms. Main unresolved gap is
checking execution/representation, not quoting or final JS assembly alone.
The next architectural experiment must reduce per-operation CPS boundaries;
do not confuse a fast isolated quote island with solving that gap.

Full evidence archive69641552 bytes, SHA
`f707583bd124493e50fe587e24b8bfeec5684107f6dc80faeec6396c86dfa96b`,
copied and hash-verified locally.408 verified raw ASTs1008182658 bytes removed;
images and compact evidence retained, completed remote launchers removed.

## Profiling revision51 — actual49, compiler unchanged

User challenged profiling quality and requested fundamental architecture review.
Do not start another optimization from generic V8 self samples alone. Revision51
changes diagnostic tooling only; source50 remains a rejected snapshot and49 is
the last selected compiler.

`compiler-profiling-quality-v51.json` preserves exact runnable measurement
sources, hashes and scope limitations. Separate phase CPU/heap evidence:
`compiler-phase-profile49-quality.json`. Actual full50-file/15-module checking,
7720 exports, output import/smoke and exact frozen output bytes pass in every run.
The unchanged helper samples worker CPU at1ms and allocations at4MiB, including
objects collected by minor/major GC. Whole-process CPU is a different metric.

Checking estimates172138113888 cumulative allocated bytes, NOT live RAM or exact
bytes/object counts; Map-family sites estimate38072476888 bytes. Canonical
Map.get rebuilds paths through Map.lo/hi; Arena.name still calls it. Existing
IndexLookup.find is already read-only. Arena get_node.result also rebuilds
Tuple/Arena records. These are allocation findings, not isolated CPU shares.

`evals/checker_core_step_counts.mjs` recognizes own$46 and seed$058 symbols.
Final actual49 full-run counts remain324586413 balanced iterations. Sampled
named target coverage is99.92375% Direct and46.407% Resume; inline unnamed work
remains unattributed. This does not reconstruct complete logical CPS CPU stacks.
A/observer/A controls measure6.23–11.66% compile overhead for the prior90be889d
observer; do not assign that estimate to final18cc49be persistence changes.
`compiler-counter-profile49-quality-final.json` proves the final observer on
the full workload and real collision input: smoke gets a separate pass-2 file;
exclusive writes preserve earlier main counts and fail EEXIST on collisions.

Architecture assessment: whole Checker direct style is blocked by forward/
mutual references and nonstructural recursion over U32 arena IDs under current
official rules. Do not add unsafe to bypass it. Prefer coarse semantic machine/
worklist boundaries and structurally checked direct helpers, with unchanged64
WHNF semantic fuel. Usage fusion is an atomic infer/check-result migration plus
five close sites, with level/erasure/error-precedence obligations, not another
small application-query patch. Do not combine it with a closure representation
rewrite. First pursue measured zero-cost read paths/ownership-aware lowering;
no architecture rewrite or acceleration is claimed by profiling revision51.

## Latest experiment — Main50/parser75: rejected as acceleration

Version50 removes duplicate callee-type derivation from affine usage; source
parent `7c33172b`. Correctness is green:8155/8155 native bodies,8493 events,
75 compiled parser cases,16 real library consumer cases and273/273 fixtures.
Actual remote/downloaded byte comparison passes. Both images18297014 bytes,
SHA256 `0d2bdf9a378d973f4da497d34e3a580cc878f3d4ca0abcc5e91418e3663478f0`.
Stage2 self-compilation164289ms; full gate552466ms, physical2604952224 bytes.

Same nhs runtime/corpus, genuine emitted compilers, all7720 exports and actual
output import/semantic smoke; all emitted frozen program bytes remain identical:

| Consecutive order |49 compile(ms)|50 compile(ms)|
|---|---:|---:|
|49 then50|106869|133379|
|50 then49|112587|115380|

Both orderings favor49; magnitude varies, and unchanged emission also varies.
Do not claim an isolated cause or stable24.8% penalty. Exact balanced scheduler
iterations fall324586413 ->320313853, only1.316%. Removed365k substitution
requests remove just72 deep core_subst_open visits and165 arena_put_node
requests; the presumed large algorithmic gain is disproved. Canonical target
counts are Pending only, not all calls including Direct.

Receipts: `compiler-usage-head-v50.json`, `selfhost-acceptance-release237-misaka-v50.json`,
`compiler-emitted-linux-v50.json`, `compiler-emitted-linux-v50-reverse.json`,
`compiler-counts-v49.json`, `compiler-counts-v50.json`. Raw1GB transports were
verified/archived to66853244 bytes, copied locally and removed.
**50 is not selected as an acceleration. Restore49checker before the next
candidate;49remains the last selected compiler.** Never drop the50failure record.

## Latest acceptance — Main49/parser74 on misakaindrive

Version49, source parent `bc86f3a1`, specializes only exact-arity eligible named
public ESM calls to the existing uncurried body at fresh depth0. Internal
curried facades/depth bounds are unchanged. Partial/over-applied, erased,
returned-function and nullary behavior passes16 actual consumer cases.
The old manual library probe now supplies the required outer request group.

Fresh parser74 passes75 compiled semantic/span cases. Complete compiler root
checks8173/8173 bodies and8511 events, zero exclusions/output patches. Seed
and both actual emitted stages pass273/273 fixtures. Remote and downloaded
`cmp` pass: both images18330720 bytes, SHA256
`28061d5eab72b2a0bc560c6963b8f22cd863d7572f102cb627d483606f412e81`.
Stage1 self-compilation124593ms; stage2 self-compilation151113ms. Full gate
577612ms, physical2528125240/RSS3721707520 bytes, unchanged8GiB/600s limits.
Stage2 is below five minutes; the full acceptance suite is not.

`compiler-emitted-linux-v49.json` measures genuine emitted48 then emitted49
consecutively on nhs:111478 ->101230ms compile, checker86646 ->79821ms.
Summed compilation-phase CPU132706 ->120623ms. This single pair favors49
but does not establish a repeated causal speedup. All50 fresh files/15 modules,
7720 exports and actual output import/semantic smoke pass in each run.
Version49 seed84375ms is a separate runtime, not the emitted49 timing.
49seed and49emitted output bytes compare equal;49vs48 intentionally differs.
Prior official13572ms remains much faster; the official-speed goal is unmet.

Exact executed recipes and source hashes: `compiler-export-entry-v49.json`;
complete proof: `selfhost-acceptance-release237-misaka-v49.json`. Verified raw
AST transport1008234098 bytes was archived to66915824 bytes, copied locally,
then removed. Actual images remain; no generated payload enters Git.

## Previous acceptance — Main48/parser73 on misakaindrive

Version48, source parent `70b80cb4`, unifies the three checker name-equality
implementations in native-checked Scope.equal_names. Identical strings avoid
canonicalization; distinct names preserve alias/shadowing resolution. Actual
CPU1/4 regression covers aliases and non-idempotent canonicalization.

Fresh parser73 passes75 compiled semantic/span cases. The complete compiler
root checks8160/8160 bodies and8498 events, zero exclusions/output patches.
Seed plus both emitted stages pass273/273 fixture executions. Actual remote
and downloaded `cmp` pass: both images18306878 bytes, SHA256
`1e906fb1139f2930befb41395b046d9183a722eb55459b41c27a0f915ce3074c`.

Stage1 self-compilation77150ms; stage2 self-compilation98995ms. Complete gate
388077ms, physical2102435528/RSS3433709568 bytes, unchanged8GiB/600s limits.
Full frozen50-file/7720-export seed benchmark64738ms: check46997ms, emit10473ms.
Output bytes remain unchanged and actual output import/semantic smoke passes.
These are observations, not isolated causal speedup or an official-speed win.
Exact source/recipes: `compiler-equality-v48.json`; complete compact acceptance:
`selfhost-acceptance-release237-misaka-v48.json`. Each1GB raw AST transport set
was hash-verified, archived to67MB, copied locally and removed; real images remain.

`compiler-emitted-profile47.json` separately profiles the actual emitted47
compiler on nhs, not the official-generated seed. It shows a public checker-step
entry through run_named1/tail_dispatch with initial$td=64; a raw public entry is
an evidenced next target, but preserving internal closure stack bounds is mandatory.
No such runtime change is implemented in48; do not alter the accepted image.

## Previous acceptance — Main47/parser72 on misakaindrive

Main47 moves pure scope queries into the native-checked `scope_lookup.bend`
provider, migrates all consumers, and removes the old11 CPS definitions.
The family/kind/alias/missing/nested-unsafe regression executes successfully
with1 and4 CPU threads. All8178 current compiler-root bodies/8516 events are
validated, with zero excluded checks or output patches.

Fresh parser72 passes75 compiled semantic/span cases. Complete seed/stage1/
stage2 acceptance passes273/273. Both emitted images are18335893 bytes, SHA256
`e6fcff2cc279971cc55200f6666435b1cd7041c93d15b087dc85487bf6349edf`;
actual remote `cmp` passes. Stage1 takes97094ms; stage2 takes118980ms. Full gate
477618ms, physical2650814912/RSS2344435712 bytes, unchanged8GiB/600s guard.
Compact proof: `selfhost-acceptance-release237-misaka-v47.json`.
Exact recipes/source hashes: `compiler-scope-v47.json`.

The initial seed benchmark was85885ms versus the earlier46 run70001ms, with
unchanged parse/expand/emit also slower. Fresh consecutive46/47 controls instead
measure136943/107474ms compilation and105845/92043ms checker CPU. This single
pair is not a median or isolated21.5% causal speedup; unchanged phases vary too.
Both controls preserve all7720 exports, output bytes and actual semantic smoke.
Exact balanced full-workload counters prove378277435 ->327412751 CPS iterations,
50864684 fewer (13.45%); this is not a wall-time speedup claim.
Do not conflate seed performance with the actual emitted runtime:
`compiler-emitted-linux-v46.json` measures the genuine46 stage1 on nhs at122301ms,
versus85558ms seed and13572ms official on the same frozen input/runtime.
All7720 exports, complete checking, output import/smoke and byte parity pass.
Actual emitted47 also passes the identical nhs workload and output byte comparison:
`compiler-emitted-linux-v47.json`,127458ms versus122301ms emitted46. That one
observation shows no speedup, with unchanged phases slower too. The official
speed target is still unmet; retain this distinction in every performance claim.

## Previous acceptance — Main46/parser71 on misakaindrive

Source version46 (`106c7efd`) now has genuine fresh emitted-JS acceptance:
273/273 executions,91 fixtures on the seed and each emitted stage. Both actual
images are18400923 bytes, SHA256
`9565582817b74796fe5357fdffb6205124e24cccab52e2aca2d2b277f2adfd42`;
`cmp` passed remotely and again on downloaded copies. Stage2 uses stage1's
emitted parser/compiler, with fresh source parsing and complete oracle admission.
Parser71 passes all75 compiled semantic/span cases. Full seed build validates
8192 bodies/8530 events in13700ms, physical2700807136 bytes.

Stage1 compilation takes82760ms; stage2 takes117070ms, including parse/admission,
expansion, checking and emission. The complete273-fixture gate takes414330ms
and peaks at2219395776 physical bytes/3505111040 RSS. It passed a600000ms deadline
(stricter than the former local1800000ms), with unchanged8GiB limits and10ms sampling.
Thus stage2 is below five minutes; the whole acceptance suite is not.

Same frozen50-file/7720-export comparison on this host: official10099.880ms,
source compiler70000.533ms. Check993.196 versus52240.701ms; emit7947.939 versus
10449.514ms. Physical peaks4456974872 versus1815060048 bytes. Both unchanged
outputs and their compiler smokes pass. Source compiler is still6.93x slower
overall; do not call the host migration an algorithmic speedup.

Use `ssh misakaindrive`, checkout `/Users/ilyagulya/Projects/My/bend`, and prepend
`/Users/ilyagulya/.cache/bend-selfhost-106c7efd/bin` to PATH. Isolated Bun1.4.2 and
Node23.11.0 have authenticated binary hashes; system installations were untouched.
`ssh nhs` also works but is Linux without Bun; no guardian port was needed.
Only109592601 bytes of tracked source inputs were deployed, not local bulk caches.
Exact recipes/deployment/archive hashes: `compiler-remote-misaka-v46.json`.
Compact final proof: `selfhost-acceptance-release237-misaka-v46.json`.
Full reports and actual images remain ignored evidence, not Git payloads.
The local parser70 failure below is historical and superseded, not a current blocker.
`compiler-v45-research.md` records an unimplemented repeated-validation candidate.

## Historical speed experiments — v41 through local v46

`compiler-timing-comparison237-v41.json` records a new source-only frozen workload
from commit `0b31f1c`:50 files,15 Bend modules,8403 declarations. Unmodified official
2.0.37 chooses7720 public exports; the source compiler emits that exact ordered
list through its typed emitter API. The nine root ABI exports are not substituted
for the all-public benchmark. Both emitted outputs pass actual parser/checker smoke.

Fresh no-oracle compile timings: official15094.574ms, native-built Bend JS
109234.749ms. Checker1581.197 versus84259.446ms; emit11926.576 versus14873.526ms.
Whole-tree physical peaks4492006528 versus1675468512 bytes. These are single
serialized diagnostic samples, not medians or a new fixedpoint acceptance.
`evals/compiler_benchmark.ts` owns source/pin authentication and exact closure/
export matching under the unchanged8GiB guardian and actual256MiB Worker stack.
The initial main-thread official attempt SIGSEGV'd; its timing is rejected.

Measured v41 experiments:
- Scheduled typed identity tails: full compile109626.741ms; no demonstrated win.
  Rejected branch commit `9313891f`; native8065 bodies and exact output parity pass.
- Batched arena copies:112567.747ms; no demonstrated win. Rejected `706aaff8`;
  native8079 bodies, exact output parity and ten overlap/ownership cases pass.
- Source-pattern binder certificates:106356.703ms. Two checker pairs favor the
  candidate:84259/79839→81445/77459ms wall,91890/87545→87062/82687ms CPU.
  Source candidate `ea361e39`, integrated provisionally as `274ec050`; fresh full
  fixedpoint/fixtures still required. Both full outputs equal baseline19154334
  bytes, SHA3546e1cdb5104feaef7613ee8f0ea66ae70ad2410e150648f26b43accc22f0bd.
- Native C build completed under unchanged8GiB limits:8077 checked bodies,
  241209ms total, peak physical5038945920 bytes, explicit clang-O0.
  C generation128904.628ms; clang106080ms. The-O3 attempt hit8GiB during clang.
  Canonical shared layouts remove JSON DAG serialization; bounded higher-body
  cache release retains every original checked e. Wide257/deep-boxed C cases pass.
  Full execution then failed in Core.map_syntax_terms: ERR_RFCS rejects copying
  its captured affine callback, not reference-count overflow. See
  `compiler-native-v41-decision.json`; no native full-run speed claim.
  v42 replaces all24 live callback sites with first-order traversals, without
  new unsafe annotations or runtime guard changes. Actual C1/C4 and JS
  shift/substitution regressions print capture-ok (`7d9a851d`).
  Fresh parser68 source semantics passed71/71, but generation failed because
  historical effect seeds missed the new mapper SCC; v42 is UNACCEPTED (`10af8abc`).
  v43 derives new effect roots from the current residual mutual SCCs and sequences
  sibling effects; the cut solver shares the same SCC algorithm. All15 context
  semantic/affine tests pass, including the failing-before sibling case.
  Fresh parser69 now passes75/75 compiled semantic/span cases. The assembled
  full root checks8192 bodies/8530 events and builds JS in23120ms, physical
  2651767400 bytes. Native bridge migrated to this parser's Value_17 result ABI
  after the old Value_15 contract was rejected by the unchanged checker.
  Full C build then hit the unchanged600s deadline in clang after completed
  428780.808ms C generation,8204 checked bodies, physical4046369568 bytes.
  No native execution or speed claim. Genuine JS fixedpoint passes below.
  On resumption the temporary v41 directories contained no files; committed
  receipts survived. Mapper changes are restored in main; the frozen50-file
  workload was recovered from0b31f1c and every original SHA reauthenticated.

Current Main43/parser69 has a fresh accepted emitted-JS byte fixedpoint267/267.
It is accepted for semantics, NOT speed: stage2 takes369993.542ms, above five
minutes. Main40 remains the faster historical measurement. Neither emitted-JS
proof establishes a self-generated C backend or a native-binary fixedpoint.

v44's closed template callback with an explicit runtime environment is rejected:
specialization checks the recursive target before it is filled. The tiny native
build fails canonical checking; no additional unsafe annotation was introduced.
`compiler-native-v44-decision.json` preserves the reproducer and actual failure.
The short native43 profile samples25.3% GC. Instrumented higher preparation is
5619ms out of63011ms reachability; it does not justify blaming body-cache misses
alone. No accepted43 source or generated image changed in this experiment.

v45 keeps a weak telescope cache: live book signatures are reused, while temporary
type keys remain collectible. Eight C1/C4 mapper/record/dependent-family runs pass.
Full8204-body C build passes524886ms, physical4047794976 bytes, clang-O0;
C bytes exactly match43. Full8192-body JS seed passes28578ms and is byte-identical
to accepted43's seed SHA b9eb88ab7c4025ddf2a6593aad5186d16b10a0e2670b7a678e307913dfbec0fc.
This is backend byte parity, not a fresh stage1/stage2 gate.
The actual native-O0 full workload is REJECTED FOR SPEED: parse31948.469ms,
expand101927.657ms/31910111 calls, then checker fails to finish before the
unchanged1800000ms guardian deadline; no emission/result. Fuel construction is
only839.573ms for all120M cells, disproving it as the dominant cost.
Do not raise the limit or repeat this O0 run. Preserve `compiler-native-v45-decision.json`;
the next path is source-checker sharing on JS, not more unoptimized C experiments.
`compiler-v45-research.md` records source-cited candidates and uncertainty.
Fresh same-frozen-corpus JS baseline45 passes7720 exports and output semantic
smoke; bytes19154334 still equal baseline SHA3546e1cd… . Whole compile337101ms,
checker283962ms wall/123175ms CPU; substantial wall/CPU divergence precludes
attributing the historical wall difference solely to compiler changes.

v46 reuses immutable application/annotation nodes when their viewed function
is unchanged, and the existing reference beneath a bang. The same frozen corpus
passes7720 exports, unchanged19154334 output bytes and emitted-compiler smoke.
Observed compile281954ms; checker246641ms wall/120262ms CPU versus45's
283962/123175ms. This single CPU pair is only a2.36% improvement, not the apparent
16% wall improvement: the host was heavily contended. Physical peak1480505840.
Two new semantic boundaries pass the native and source checkers: annotated
banged partial application returnsBitOne{}, and an incompatible result annotation
is rejected by both. They are permanent full-bootstrap fixtures.
The local v46 attempt was **UNACCEPTED**: parser70 passed14 public tests and71/71 source
semantic/span cases, but its generation phase hit the unchanged600000ms
deadline (actual600477ms, physical217253280 bytes). Native parser70 and the
full v46 stage1/stage2 gate did not start. At that point the last accepted fixedpoint was43.
At failure the Mac's load averages were556.82/400.56/314.68 on10 physical cores;
a process snapshot found1215 processes and no remaining selfhost heavy jobs.
The contemporaneous official comparison took322949ms wall but36576ms CPU;
v46 took281954ms wall but156317ms CPU, so it has NOT outperformed official.
No unrelated processes were killed and no limit was raised. There are no
configured tool SSH hosts; BEND_HOC is unset and `ssh ... cluster true` fails
to resolve that cluster alias. The user subsequently supplied `misakaindrive`
and `nhs`; the complete remote acceptance above resolves this resource blocker.
`compiler-sharing-v46.json` records exact recipes, measured results and failure.
Do not substitute frozen-corpus output parity for a genuine new fixedpoint.

## Completed acceleration — Main40 full stage2 below five minutes

Latest user priority: accelerate the checker and the complete bootstrap, not more
diagnostic-only runs. `compiler-timing-comparison237-v37.json` records the same-root
official2.0.37 baseline: Node23 full JS compilation11527ms, checker1573ms, no spill,
physical3541671088 bytes. The earlier claim that this root requires disk is false.

The canonical native builder now uses the unmodified kernel, retains original
checked `e` until final SCC emission, and publishes schema4 provenance. Parser,
driver, bootstrap and library-smoke consumers require that new contract. Removed
the obsolete snapshot store and emitter restoration callback.
`selfhost-steps-native-canonical-release237-v38a-nospill.result.json` PASS8064/8402,
guardian18434ms, physical2566300176. Its10551359-byte output is byte-identical to
accepted native37, SHA1517d42978725f4f4b2c6f2f6688df999b92135d167bb164dda65595d0ca1efb.
Mutual-SCC checked-body release regression PASS. This is not a new bootstrap proof.

Fresh37 own-parser/expander/checker CPU profile completed:
`current37-fresh-source-checker.{json,cpuprofile}`, CheckSuccess15 modules,
324041ms wall/235900ms CPU. Scheduling variance is substantial; sampled self:
run_loop12.06%, runSteps7.20%, index_lookup.find3.98%, Map.get.go3.10%, GC2.85%.

Shared named/unary closure depth candidate38 passed real264/264 byte fixedpoint,
SHA14ae26498085e5e648eb39fa1feb488e2988d1e39368e6b56232af82aac6eb04,
20547903 bytes; API/mixed120001/foreign-argument smoke passed. REJECTED FOR SPEED:
whole stage2=525602.628ms, checker371406.484ms. The closure-body/depth edits are
fully reverted; do not reintroduce them as an optimization.

Source index_lookup now descends structurally with parameter-matched Map.bit
results, without allocating either recursive branch closure. Actual emitted JS
Unicode/miss/arbitrary-map semantics passed; 1024-key A/B188.5/190.6→169.7/168.1ms.
This is local lookup evidence, not a whole-stage speed claim.

Candidate39 instead replaces private tail request objects/argument arrays with
a module-local register bank and private pending token. The dispatcher captures
and clears registers before any target call; ordinary Data/progress is unchanged.
Both dispatcher and nonescape static reviews found no blocker. Source-emitted
consumer A/B covers arities1/32/40, depth64/65/130, strict recursion, partial
callbacks, reentry, caught exceptions and deep120001 calls. Dynamic500k tails
19.2/19.4→14.5/15.6ms. Native full root39 passed8065 bodies under original guard.
Fresh parser66 + genuine Main39 completed267/267, but missed the five-minute
target. The accepted successor is Main40/parser67 below; all ten real stage
API/mixed120001/foreign-argument smoke rows passed for both versions.

Main40 reuses the existing fixedarity scheduler for curried facades and splits
unary hot dispatch from the large named-arity switch. Closure bodies, public
arity and the64-call budget stay unchanged. The host continuation driver also
skips another kind's suffix checks after authenticating its tag. No further
optimization is pending integration; preserve this accepted baseline.
The attempted faster diagnostic without source checking produced an invalid
compiler image (`source40-diagnostic.js`, Lexer.tokens getter called with null).
Its emission is NOT acceptance or usable performance evidence; keep the complete
source checker in every compiler-generation path. The cause is not established.

## Storage cleanup — complete

User-requested cleanup completed after cancelling Main34 gates bg622 and bg625.
`checkpoints/storage-cleanup237.json` is the exact removal/archive/safety receipt.
Measured checkpoints123194684→6316988KiB (117.49→6.02GiB); this includes
2068344KiB of compressed evidence archives. Last measured disk availability:
221951872KiB (211.67GiB). Do not sum apparent APFS tree sizes as physical savings.

All32 confirmed selfhost temporary roots were removed: the first8 in
`experiment-archive237/manifest.json`, then24 in the cleanup receipt. Every source
and selected-evidence archive passed gzip integrity verification before deletion.
The23 unrelated/unknown user paths remain untouched; the bend2-lint/release/perf
worktrees belong to the separate bend2-lsp-rs project, not this selfhost task.

Removed352 historical case/module sidecar directories, the obsolete1.4GiB
expanded-AST diagnostic cache, and the stale3.6GiB native checked-body store.
813 old large top-level logs/artifacts are preserved in
`experiment-archive237/historical-large-checkpoints.tar.gz`; the adjacent members
list maps their original paths. Old sidecar paths in historical sections below
are no longer runnable artifacts. Small receipts remain in place.

Earlier retention kept genuine37 and its authenticated native37/parser64 inputs live.
After gzip verification, complete31/32/34-clean case directories and nine retired
recipes/smokes were moved into `experiment-archive237/superseded-proofs-through-v34.tar.gz`.
That cleanup ended at5922560KiB (5.65GiB), including2311244KiB compressed archives.
Disk availability then was280519016KiB (267.52GiB). The completed35 case directory
is archived in `experiment-archive237/superseded-proofs-v35.tar.gz`; completed36/37
recipes and the small owned operation-index experiment were archived and removed.
At that point, both37 image hashes matched and parser64 authentication passed
all291 protected inputs; no compiler/benchmark or cleanup jobs remained.
The original genuine32 root source SHA c9f18f75…
also survives as `checkpoints/.bootstrap_compiler_root_v1.bend` inside
`compact-string-frontend237.FW3I9Q.evidence.tar.gz`; verified against genuine32.
Post-cleanup smoke PASS: both unchanged stage images hash-verified and exercised
with bare/foreign-extra-argument callbacks (four CheckSuccess/Nil rows); current
parser61 authentication and driver assembly PASS, parser declarations unchanged.
This is retention verification, NOT a new Main34 bootstrap acceptance.

During Main40 integration, retired37 and rejected38 sidecars were gzip-verified
and archived in `experiment-archive237/superseded-proof-v37.tar.gz` and
`experiment-archive237/superseded-proof-v38.tar.gz` before removal. Their allocated
sizes went from955668/1010028KiB to60432/63464KiB. Historic37 image paths below now
refer to archive members, not live files. The latest accepted40 case tree stays live.

Final40 retention measured5319340KiB (5.07GiB), including2616216KiB archives;
available disk331150576KiB (315.81GiB). Retired39, earlier phase-profile trees
and throwaway experiments/recipes are in the gzip-verified
`experiment-archive237/superseded-experiments-through-v39.tar.gz`.
The118-file accepted source snapshot is1512KiB, archive SHA
`52143079d5f6e767a52600458f7914b378d7e7e4732d8b2ca0ed91e56d566f52`.
Post-cleanup retention smoke PASS:399 genuine-proof inputs and289 accepted-parser
inputs reauthenticated; raw stage images still equal; eight real exported/
curried-callback CheckSuccess/Nil runs passed. See
`selfhost-retention-release237-v40.json` and `storage-cleanup237-v40.json`.

NEVER recursively copy the repository, `checkpoints/`, or `*.checked.bin` into an
experiment. Isolate only required source and explicitly selected immutable inputs.
Keep the latest accepted proof, the active candidate and needed profile inputs;
archive unique patches/receipts and remove superseded experiment copies.
The old accumulation was a parent cleanup failure. Recent disk-full wall times
do not establish causal compiler/runtime performance regressions.

## LATEST GENUINE FIXEDPOINT — Main release237-v43, parser69

`selfhost-acceptance-release237-v43.json` is the compact receipt; the complete
local report is `selfhost-steps-bootstrap-release237-v43.json`. All267/267 fixture
executions pass. Both unpatched UTF-8 images are18400386 bytes, SHA
`0803217475d839c4aaaf48104e8c7d91852dac19433d5b433f2ffc219ddea0cf`.
Stage1=213877.554ms; stage2=369993.542ms. Stage2 parse/admission51562.812,
expand14396.287, check258266.531, emit/write/hash45767.912ms.
Whole gate1252553ms, physical2125450592/RSS2220638208 bytes, unchanged8GiB/10ms.
No source checker omission, cached AST, output normalization or output patch.
The full root's native JS seed checked8192 bodies and8530 events in23120ms,
physical2651767400 bytes. Parser69 passed75/75 semantic/span comparisons.
The current cut includes the formerly unsafe operator traversal's new mutual
recursion. v43 is a correctness repair, not a measured performance improvement:
the five-minute stage2 target and faster-than-official target remain unmet.
Exact parser/root preparation commands are in `compiler-context-v43.json`;
the complete gate command is in this acceptance receipt. Generated images and
bulk oracle/phase sidecars are local, not Git inputs.

## Previous genuine fixedpoint — Main release237-v40, parser67

`selfhost-steps-bootstrap-release237-v40.json` PASS267/267; both raw images
18244928 bytes, SHA `84b19ce89aad6da90b1aedb7b8fff2ed8ef659636754801c91290424c19a7da2`.
Whole compiler-generation stage1=155527.422ms; stage2=285168.610ms (4:45.169).
Stage2 parse+admission43637.237/expand11481.872/check208501.929/
emit+write+hash21547.572ms. This includes fresh canonical semantic/span admission,
not only the source checker. The300000ms per-full-stage goal is met in this run.
Full bootstrap gate, including all267 fixture executions, took913457ms (15:13.457);
it is NOT a five-minute whole bootstrap. Physical2136842832/RSS2080915456 bytes;
unchanged8GiB/10ms guard and existing heap/stack/time limits.
Native seed40-final checked all8065/8065 bodies in20842ms, physical2651833584;
checksExcluded=0, outputPatches=0, original checked bodies retained without spill.
Both emitted stages imported and passed ten API/deep120001/callback smoke rows
(`selfhost-api-smoke-release237-v40.json`, guardian14516ms, physical619229152).
Raw bytes are compared without normalization or patching; stage2 uses stage1's
actual parser. No cached AST is accepted and no own-checking phase is omitted.
Relative to old stable37, this sequential full-stage measurement is14.83% lower;
it is19.46% lower than39. These are measured run differences, not isolated causal
attributions to individual changes. Pure parser/template/checker/JS compiler-root
bootstrap is green; C/Metal/CUDA and the legacy IO driver remain outside this proof.
Exact selected sources and completed generation/fixedpoint/API recipes are kept
in `experiment-archive237/accepted-release237-v40-source.tar.gz`.

Remaining measured costs: the source checker is still208.5s; admission transport
decoding performs two JSON/validation passes and dominated63% of earlier oracle
profiles. No transport change was integrated. Sharing identity resume closures
was only suggested, not measured; a named helper can add scheduling work and
does not by itself make the still-polymorphic host call site monomorphic.

## Previous genuine fixedpoint — Main release237-v39, parser66

`selfhost-steps-bootstrap-release237-v39.json` PASS267/267; both raw images
18213012 bytes, SHA `bf8da96f787e34048dddb5b73a8b6b319edf83864b4ed0a72492159a9beac15c`.
Whole stage1=226290.576ms; whole stage2=354073.114ms (5:54.073).
Stage2 parse55489.188/expand15663.922/check257456.900/emit25463.104ms.
Guardian1026963ms, physical2019589296/RSS1801093120; unchanged8GiB/10ms.
No output patches, normalization, AST-replay substitution or increased limits.
Ten stage API/mixed120001/callback smoke rows PASS; guardian11912ms,
physical498563536. Native seed39-final fully checked8065 bodies in19490ms,
physical2686519304. No disk checked-body store remains.
The five-minute full-stage target remains OPEN. Old37 was334825ms; sequential
timings do not establish a whole-stage gain despite lower measured memory.

## Previous genuine fixedpoint — Main release237-v37, parser64

`selfhost-steps-bootstrap-release237-v37.json` PASS258/258; both raw images
18158465 bytes, SHA `710a98a6d027012b757b1f42cb078a1d8f089040a0153f96bb17ac213629b278`.
Whole stage1=190998.841ms; whole stage2=334825.354ms (5:34.825).
Stage2 parse69584.519/expand24699.547/check216341.313/emit24199.975ms.
Guardian850399ms, physical2412396832/RSS2118680576; unchanged8GiB/10ms.
No output patches, normalization, AST-replay substitution or increased limits.
Six real stage API smoke rows PASS; guardian1010ms, physical333749568.
The five-minute full-stage goal remains OPEN; checker-only time is not that goal.
Native-operation caching and slim scopes are semantically accepted. These
sequential timings do not establish an isolated whole-stage speed improvement.
Source snapshot and completed reproduction/smoke recipes:
`experiment-archive237/accepted-release237-v37-source.tar.gz`.
Storage cleanup is complete; current acceleration work is described at the top.

## Previous genuine fixedpoint — Main release237-v35, parser62

`selfhost-steps-bootstrap-release237-v35.json` PASS258/258; both raw images
18150195 bytes, SHA `77a588b329d919a5522845471652ab1fe3ecff350b38b80ba3adc3f167ad9911`.
Whole stage1=198909.310ms; whole stage2=324706.722ms. Five-minute target OPEN.
Stage2 parse44896.535/expand24789.229/check227485.362/emit27535.597ms.
Guardian862332ms, physical2593253904/RSS2707472384; unchanged8GiB/10ms.
Bounded direct-tail depth64 is semantically accepted, not an isolated speed win:
whole stage is essentially unchanged from34; physical peak is higher.
Six actual stage callback/export smoke rows PASS, guardian1060ms.
Source snapshot: `experiment-archive237/accepted-release237-v35-source.tar.gz`.
Main37 caches native authority and exact operation identities
in module-shared EmitAliases. Removed obsolete path/full-module payloads from
EmitScope, the path slot from EmitModuleIndex, and forwarding through23 helpers.
Main36 parser63/native admission PASS:8063 checked,CPU119934.234ms,
guardian164599ms,physical2814495416/RSS2558869504. No full gate yet.
Before full acceptance, Main37 also skips duplicate classification/map insertion
when the namespace is empty (local and qualified keys are then identical).
Main36 source preserved in `experiment-archive237/candidate-release237-v36-source.tar.gz`.
bg645 parser64/native37 COMPLETE:8064/8064,0exclusions/patches; native
SHA1517d42978725f4f4b2c6f2f6688df999b92135d167bb164dda65595d0ca1efb.
Native CPU87378.190ms, guardian72204ms, physical2841403552/RSS2792308736.
Parser64 status PARSER_ACCEPTED_NATIVE_SEMANTICS, FULL_75_SEMANTIC_GATE.
bg646 full gate and bg647 actual stage API smoke COMPLETE PASS.
JSEM F1EC remains the accepted source; no compiler jobs are running.
Completed recipes are archived rather than left as live throwaway scripts.
One pre-run machine snapshot: loadavg14.87/18.17/23.84; RAM68719476736 bytes.

## Previous genuine fixedpoint — Main release237-v34-clean, parser61

`checkpoints/selfhost-steps-bootstrap-release237-v34-clean.json` PASS258/258.
Both raw stage images18150195 bytes, SHA
`312d18ecf160447262a7c13f2bee137a93162211825300303c74a141362f4fb7`.
Whole source-root stage1=161375.539ms; stage2=325131.795ms (5:25), target OPEN.
Stage2 parse39303.970/expand9677.659/check242995.455/emit33154.712ms.
Guardian846408ms, physical2005363768/RSS2040758272; unchanged8GiB/10ms and
Node23.11.0 young128/old6144/stack256. Native8052/8052,0exclusions/patches.
All75 parser semantic/span and public14/207 admission checks passed.
Six strict/bare/foreign-extra-argument callback smoke rows PASS, guardian1028ms,
physical333913672. This is genuine source parse/expand/check/emit, not AST replay.
Lexically named entries and source-name separator collision fixture accepted.
Comparison with32 is observational: disk cleanup changed the environment too.
Compact immutable source snapshot: `experiment-archive237/accepted-release237-v34-source.tar.gz`.

## Previous genuine MAIN fixedpoint — release237-v32, parser59

`checkpoints/selfhost-steps-bootstrap-release237-v32.json` PASS255/255 genuine
byte fixedpoint; both18094680 bytes SHA
`3771875fe6a6faa42e813d505803bcfd5c13a8c585b50d559f6e916967b8466c`.
Native8046/8046,0exclusions/patches; parser59 all75 semantic/span/public14/207.
Guardian1000450ms,physical2173015664/RSS2103885824.
Node23.11.0 with young128MiB/old6144/stack256 and original8GiB/10ms guardian.
Fullstage1=167487.083ms; FULLstage2=344107.087ms, so five-minute target OPEN.
Stage2 parse41941.645/expand11069.248/check262161.253/emit28934.942ms.
Compared31 whole-stage -21.5%, but this COMBINES statement blocks, scalar Direct
token, bounded parser overlap and young-generation setting; no isolated attribution.

## Previous genuine MAIN fixedpoint — release237-v31, parser58

`checkpoints/selfhost-steps-bootstrap-release237-v31.json` PASS genuine raw
stage1/stage2 byte fixedpoint,255/255 fixture executions; both18072183 bytes,
SHA `83b48b35cad381488fa41cbb53933fa42c396f05a48cf640405d63c8bbee25a7`.
Guardian1029973ms, physical2893244896/RSS2797273088; original8GiB/10ms limits,
Node oldheap6144MiB/stack256MiB, native2.0.37/kernel6c1df3 unchanged.
Main nativeRoot31 all8037 bodies checked,0exclusions/patches;60054ms,
physical3241095848. Parser58 actual current source all75 semantic/span and
public14/207 PASS, no historical JSEM substitution.

COMPLETE source-root stage1=163187.244ms, stage2=438367.540ms.
Stage2 parse59909.073 / expand11800.897 / check333075.276 / emit33582.294ms.
Five-minute target STILL OPEN. Controlled restored-AST + NATIVE expansion
checker261544ms was NOT representative of complete own-source stage2;
do not extrapolate microbenchmarks or confuse fixture-suite with root time.

## Previous genuine private fixedpoint — compact string v5

Private immutable baseline `/tmp/compact-string-frontend237.FW3I9Q`.
`checkpoints/selfhost-steps-bootstrap-compact-string237-v5b.json` PASS genuine
rawbytefixedpoint,255/255 executions=alloriginal228+27new; both17957832bytes,
SHA `87cf76429d09f4b5417a0d7741a53c4b778a4744404b2ee487a6d8897b535c03`.
Guardian1207468ms,physical2308855368, unchanged8GiB/10ms/heaps/stacks/kernel.
Native full9API rootv5:8033/8033checkedbodies,0exclusions/patches,53572ms,
physical3081144704,artifactSHA
`e934bfff2e9868c69f1a3c67ef02037bfed78e262fc60b1464a114d97ac9b2e1`.
Finalparserv5 all75fullsemantic+literal-span andpublic14/207 PASS,0exclusions.
Exactcanonicalcoverage Checker1077/Template196/JSEM505,0omitted/residualcalls.
Private agent `CompactStringFrontend` result contains exact receipt paths.

Previous private stage1 total144313.227ms; stage2 total416618.537ms,
parse45343.557/expand15239.859/check318092.771/emit37942.351ms.
These are not the timings of current Main31 above.
Fixture-suite walltime is NOT compiler-root stage time.

Parent integrated all14 implementation/consumer/observation/fixture files via
hashlinepatch; shared Ast52FA,ParserC92E,Checker3214,JSEmit34C1. New compact
String behavior includes explicit8names, rawUInt32payload/spans, actualcomplete
schema proof+oldconstructor fallback, capturepreorder preservingunusednames.
Parent-review equality repair is POSITIVEONLY: matchingnames+samecodepoints
canproveTrue; ANYmismatch unfoldsordinaryconstructors (bitTrue/False mayalias).
Inference is intentionallyUNCHANGED: infer(TermCtr)cannotinfer, so inferString
fallsbackandsamefailure. DoNOTnewlyacceptunannotatedstrings forperformance.
Tests dropped incidental encoder-call/137-span-count and message-wording pins,
retained semantic/native-value/full-span comparisons. Main literal suite PASS:
49 tests / 389 assertions; guardian3140ms, physical2113063048 bytes.
Legacy C fallback migration is not independently native-checked.
Main parser59/nativeRoot32/defaultBootstrap32 is previous genuine acceptance.

Main34 native/parser AND full default bootstrap are now genuinely accepted.
bg637 completed after cleanup; earlier bg622/bg625 cancellations are not passes.
Main35/JSEM2937 bounded ordinary tail-call budget16→64 is genuinely accepted.
bg640 parser62/native35 admission COMPLETE:8052/8052,0exclusions/patches;
native SHA e7f3fc46c1ed856a15c34da614009bb190369c69fcd5b49fb6413005d10bab9c,
guardian81460ms,CPU92472.114ms,physical3238687088/RSS3094675456.
bg641 full gate PASS258/raw equality; bg642 actual six-row API smoke PASS.
Main36 native-operation metadata cache is now the only additional source change.
Main34 reverted the unaccepted Main33 export experiment and emits module
lexical `var` entries instead of `$U[name]` dictionary lookups. Module scopes and
aliases remain block-local; var hoisting preserves forward references and
duplicate-write order. Curried/public exports and bounded-tail ABI unchanged.
Main JSEM914A; gate9565 adds a real separator-collision execution fixture.
Native8052/8052,0exclusions/patches,physical2749350184,wall462690ms/CPU114561ms.
Parser61 and all258 executions/raw byte fixedpoint PASS (see latest receipt).
Existing65536-call and120001-call callback fixtures cover deep tail recursion.

Main33 full gate FAILED at1800000ms; it did produce equal stage images18115476B,
SHA e78d58fd9288b2ec8f352d7eada2dad7d6dd2388f4554d1bec997222d46085c0,
but remaining fixtures did not complete. It is NOT genuine acceptance.
Source archived in `saturated-export-release237-v33.source.json`; edit reverted.
Slowdown affected unchanged native-seed stages too: native33 wall247257ms versus
native32 wall77870ms, CPU107246ms versus86427ms. No isolated causal attribution.
AC power/lowpowermode0, no recorded thermal warning; swap used12839.75MiB.
Do not just increase the timeout or claim an optimization from partial evidence.

Node26 experiment COMPLETED and REJECTED for speed:
`selfhost-steps-bootstrap-release237-v32-node26.json` PASS255, exact same Main32
SHA and bytes; complete source stage2=382379.266ms versus344107.087ms on Node23.
Stage2 parse46077.802/expand13101.684/check293866.571/emit29333.208ms.
Guardian1186882ms. Same inputs/young128/old6144/stack256/8GiB/10ms.
Global PATH/settings unchanged; native Bend remains2.0.37.
Actual Main32 strict/foreign-extra-arguments callback smoke PASS on both stages,
four CheckSuccess/Nil results, guardian1255ms,physical332504504.

Main32 JSEM E8FF emits function/case locals and matches in existing lexical
blocks; simultaneous RHS environments, erasure, expected types and constructor
fallbacks unchanged. Native8046/8046,77870ms,physical2962601576, nativeSHA
e77a1de4d2e92626fa4a89777863e1350dc517cc38569adbd7f416ce77062c2e.
Whole build541380ms was variable; Main33 native247257ms also much slower.
After completion, vm_stat showed ~25GiB compressed pages; a process snapshot
found unrelated memory consumers, not a leftover own compiler. No causal proof;
do not kill user processes or attribute timing variance to the tiny source diff.
Disk last observed99%full/31GiBfree; do not rewrite evidence during timing.

Static-rank private candidate REJECTED: full native8037 PASS90595ms, but actual
whole-root source check389705.300ms vsMain333075ms; fullstage about499626ms.
bg615 cancelled during remaining fixtures: its parser-admission corpus still
referenced Main JSEM, then Main changed. NEVER claim this run as genuinefixedpoint.
Receipt`/tmp/static-ranked-tail237.v1/checkpoints/selfhost-steps-bootstrap-static-ranked-tail237-v1.json`
is interrupted IN_PROGRESS, not acceptance. Do not rerun this slower candidate.
Future private experiments MUST migrate real-source corpus paths to isolated
actual candidate files before admission, not just owned/parser generated roles.

Main32 changes AFTER genuine31, now covered by genuine Main32 acceptance:
- lowerer8063 uses authenticated Base False scalar scheduling token rather than
  fresh Unit{} per Direct; generic Direct<R>, affine invoke and witness unchanged.
- workerC9CE bounded FIFO2 parser admissions, all proofs drained before consume;
  agent actual fresh15 A/B48305.982→43520.047ms, full semantic/span/transports/
  order equal; actual cycle+namespace errors with0modules consumed. Receipt:
  `/Users/ilyagulya/Projects/My/bend-parser-overlap237-v1/parser-overlap-receipts/receipt.json`.
- worker + gate9303 explicit young128MiB, old6144/stack256/8GiB unchanged.
  CurrentRoot replay own-source expansion+checker CheckSuccess306295.869ms,
  GC11999ms3.9%, run_loop29175/runSteps23314ms, guardian326436ms,physical2285866088.
  `checkpoints/current-root-source-checker-young128237-v1.{json,cpuprofile}`.
  Restored approved ASTs, NOT original parser hidden classes/fresh stage/fixedpoint.

StructuralPureIslands REJECTED after generation:35new scalar/selector islands,
only606bytes saved(-0.0247%), helpers4686→4711, pending1143→1141. No native build.
Receipt`/tmp/bend-structural-pure237/checkpoints/structural-pure237-rejection.json`.
No agents running. Parent exclusive guardian reserved to bg617.
NativeRoot31 all8037 bodies checked,0exclusions/patches;60054ms, physical
3241095848. NativeSHA835c2e73c62723d13150129aee7afbeb6c258549904b2b41f3db013c54bfc7fe.
Main's accepted JSEM F8F3 (before pending E8FF) adds run_named1..32 and private last default `$td=0` to ordinary
named functions, preserving function.length; at most16 calls before yielding
the original trampoline record. Dynamic/curried/native-law paths unchanged.
Main runtime96B4 reads progress shape/tag once per transition; request-tag and
all own-field/callability checks remain. Genuine31 exercises all three runtimes.

Private experiments `/tmp/bounded-named-tail237.zcrXL3` ALL COMPLETE:
v1 genericspread: CheckSuccess409306.649ms; rejected.
v2 fixedarity1..32: CheckSuccess261544.396ms vs baseline315198.811ms
(-17.02% observed), physical2048514816. Integrated; genuine31 confirmed semantics
but DID NOT establish a whole-root speedup over privateStringv5.
v3 inline callsite conditional: CheckSuccess292764.587ms; not selected.
v4 saturated export fastpath: CheckSuccess363115.670ms; rejected.
v5 per-callee monomorphic tail entries: CheckSuccess402072.378ms; rejected.
Each had native all-body admission, final parser75/public207 and actual source
root emission/import/check success. None had a new genuine byte fixedpoint.
Controlled source checks use EXACT SAME15 baseline transports + unchanged seed
expansion, but sequential single timings do not establish variance bounds.
Do NOT claim whole-stage speed from checker-only timings.
v2 source archive `checkpoints/js_emit_bounded_tail_v2_source.bend` PRIVATE.
v2 candidateNativeSHA31a8ac53b99a942a01c211f44fd0a3cbddd60522b0bd87c27e14214258474f75;
sourceLibrary8e41bd433fdaa018e40463908104638bb6b68e5c7da24ba847b7c3a22e67ce9a.
All experiment receipts/libraries/CPU profiles are in immutable baseline
`/tmp/compact-string-frontend237.FW3I9Q/checkpoints/`, bounded-tail-* filenames.
Build script `evals/.canonical_root_build237_v31.sh` complete. Previous root30/
parser57 pipeline FAILED current-JSEM semantic admission: computed Bool.and
match scrutinee. Repaired by ordinary parameter-matching helper, not an oracle
exception. Full parser58 fresh admission passed; genuine31 complete. Continue
with actual whole-root profiling/optimization: stage2 still438367ms >300000ms.

Complete currentSourceChecker CPU PASS CheckSuccess315198.811ms,15modules,
nativeverifiedv5 transports+authenticnativeexpand, UNWRAPPEDrealSourceChecker.
`/tmp/compact-string-frontend237.FW3I9Q/checkpoints/compact-string-source-
checker-cpu237-v1.{json,cpuprofile}`; guardian329565ms,physical1477963896.
CPU315.38s:run_loopself52626ms16.7%,GC32177ms10.2%,runSteps28388ms9%.
Initial direct-name attribution schema279.502ms andpattern17346ms wereNOT
safeupperbounds: CPShelpers erasesemanticcallers. Correctedbothagentreceipts.
RecoveredprivateHelpers.owner→nativeMatchNormalizationOwners +actualJSline
ownership maps: pattern/case/matrixSELF23842.707ms7.56%,visible-stackunion
49677.618ms15.75%; bothLOWERBOUNDS,notcap. Patterntyping4.47sself/7.4svisible,
core_pattern_list_depth3.77sself/10.96svisible. Runtime+GC cannotbe reassigned
fromthisCPUprofilealone. `/tmp/compact-pattern-checker237.b6fFIa/pattern-source-owner-profile.json`.
Framecache `/tmp/compact-string-infer237.1sWRtd` HELDUNVERIFIED; no nativeproof.
Pattern shortcut `/tmp/compact-pattern-checker237.b6fFIa` REJECTED:
all8085 native bodies, parser75/public207, seven semantic/quantity probes PASS,
but same-input source check341667.088ms vs315198.811ms (+8.4% observed).
Affine constructor-record reuse REJECTED before edits: no proven exclusive,
writable, nonescaping owner for foreign/public values; quantity alone is not
that certificate. No agents or private heavy jobs remain.

Previous stable MAIN receipts: release237-v29 rawfixedpoint all228/228,
both18252867bytes SHA
`c897c8f002ec7a9b81949e0a7c4ef514e9231ae4600cebeccbe02351f0d16a22`.
Guardian1585502ms,physical5488273448/RSS7422935040. NativeRoot29 all7918,
52040ms,physical2989603648. Stage1 375256.766/stage2 866492.137ms.
Original sourceCallback extraindex/arrayargs smoke PASS bothv29 images;
recipe`selfhost-closure-callback-release237-v1.source.json`. BroaderIO/C notgreen.

Whole-pipeline profiling DONE: fresh actual v29 source parser all15 AST hashes
EXACTLY match genuinev29 stage-two admissions. `selfhost-root-source-parser-
profile-release237-v1.json`, CPU+4MiBcollectedallocationprofiles perfile/transport,
guardian70510ms,physical1545393320/RSS1820884992. Parser itself52293.268ms.
4191364sourcebytes →1754806081 ASTtransportbytes; emitter838723151,
checker603078214,parserdriver261139271. Eager per-character Chr/U32/32Word
trees (parser922-936/989-1027) are concrete bulk to remove.
Source emitter CPU v2 COMPLETE EmitSuccess143814.786ms +RAWoutputSHA=v29;
nativecheck169737.876ms,guardian380638ms. CPU145s:GC23%,run_loop12.9%self,
runSteps10.4%,index_lookup.find4%,nativeop suffix/starts/ends path9.1%.
Both profiler scripts archived `.source.json` and runnable scaffolds removed.

Shared worker original-approved-AST retention tag66C3 /gateboundarytag72A1
SMOKE PASS all15 complete native semantic/span parity: report
`selfhost-root-retained-parser-release237-v1.json`,ROOT_PARSE_DIAGNOSTIC_PASS,
67806ms,physical2833690984/RSS4745003008. No caches/ASTrewrites/validation
removed: nativeoracle stillallfield+slot+hash TWOpasses; streamrehashbeforeuse.
That report is parser-loading smoke only; latest PRIVATE Stringv5 genuine
fixedpoint above NOWexercises retainedAST onboth stages. Main defaultrefresh
stillrequired after finalperformancecandidatecutover.

Rejected private Ready protocol: safety7918native/17fixtures/120001tailPASS
but checkerwall+0.262%/allocation+0.043%;doNOTintegrate.
`/tmp/bounded-ready-progress237/final_receipt.json`. Lazy NodeSlot alsoREJECT:
complete real5modules +32.4%wall/+46.8%allocation despitecheapinitialpacking,
`/tmp/lazy-source-arena237/final_receipt.json`. Broad pure23helper candidate
unverifiedadds13defs/removes3619bytes;held,nointegration. Nativeoperation
index `/tmp/emitter-native-operation-index` readyUNVERIFIED;held,nointegration.
Simple native signature-law predeclarations cannot replace CPS: actual2.0.37
probe rejects liveforwardcall as "an unfilled law is a dead claim"; no kernel
change attempted. Source/error recipe `local://native-forward-predecl237.json`.

Full emitted-checker CPU diagnostic v3 COMPLETE PASS CheckSuccess569770.996ms;
guardian636660ms, physical4539719880/RSS4639457280. All15 accepted root modules,
authentic native seed expansion, unchanged emitted checker, no step wrappers.
CPU wall570.29s: GC126056ms22.1%, run_loop93977ms16.5%self,
runSteps38756ms6.8%, run_clo-generated f21161ms3.7%. Arena.name only~19885ms
3.5%inclusive WHOLE check; reserve_words~8942ms1.6%. Early20s v2 packing
percentages are NOT whole-checker percentages. Both exact profiler sources
archived as corresponding `.source.json`; completed throwaways removed.
Complete current emitter replayv2 usesv29; initialv1 onlyLOCK_BUSY, noCPUproof.

Verified private batch reservation integrated, arena tag1EF7:907/907 native
bodies,zero exclusions/patches,158 exact boundaryops pervariant,48 benchmark
checks,poisoned discarded capacity+rewind/append parityPASS.
12000reservation subsets0..3/0..16/0..63: CPU18.84→11.30/26.98→13.48/
45.99→32.52ms; sampledallocation16.0→11.27/60.54→27.29/237.70→88.84MB.
Not root speed claims. `/tmp/bend-selfhost-BatchArenaWordReservation-d7Adq0/receipt.json`.
Two-entry owning exact-name MRU candidate REJECTED, NOT integrated:
7929/7936 native bodies and semantic/runtimePASS, but real AST packing wall
regressed19.84% and arena module wall1.66%. Synthetic78.66% does not justify it.
`/tmp/arena-name-intern237/final_receipt.json`; rejected, no shared changes.

### Earlier accepted v28 baseline

`selfhost-steps-bootstrap-release237-v28.json`:
status PURE_STEP_BOOTSTRAP_FIXEDPOINT, passed/compilerBootstrapGreen/
bootstrapAcceptance true, diagnosticOnly false. All228 fixture executions PASS:
76 each on seed, genuine stage1 and genuine stage2. BOTH unmodified JS files
17024439 bytes, raw SHA256
`cc5aa822d48c50d13983b5cb90be7545716505f55b1514000336fa71b3904c15`.
Artifacts: report's `.cases/stage-one.js` / `.cases/stage-two.js`.
Source stage1's OWN parser and steps compiled the complete identical source root;
raw Buffer.equals comparison passed, no normalization/patches/unchecked fallback.
Guardian PASS1639756ms, physical5340229040 / RSS7365492736 under8GiB/10ms;
Node worker heap6144MiB/stack256 unchanged. Broader selfhostGreen remainsfalse:
this is complete parser/Template/Checker/JSEmit compiler-root bootstrap, not
legacy fullIO/C-backend product certification.

Earlier v28 root times: stage1 total379917.854ms; stage2 total910552.251ms.
Stage2 parse145231.109,expand32554.808,check573791.864,emit158974.471ms.

Accepted v28 baseline includes canonical named-object/full-qualified-tag cutover and
strict direct calls. SourceJSEM SHA5555e4c429b6320bfad0de7a594c0ff7a05f226dddbea22cbf5f4fc1405042a0.
Earlier parser55 admittedall75; native root28 checks7914bodies zeroexclusions/
patches,52554ms, physical2972515352/RSS2946629632, SHA
`ac1662398afe181e9622383933176249296979d88153ccdf2fa16c8d6aaa80dd`.
Parent also conservatively excludes astral-qualified tags from UTF-16 binary
dispatch (BMP certificate), preserving original ordered cases. Both source
consumer workers and host list/fuel builders migrated off obsolete fieldSymbols.
Gate v27 failed only imported fixture expectedshorttag vs canonicalqualifiedtag;
v28 validates canonical constructor owner identities for all5 import fixtures,
not stripped/normalized actualvalues. No fixtures removed.
Private 16field subset named-payload gain20.2x/83.93%lesssampledallocation;
NOT fullrootgain. Strictcall subset CPU-5.69%/alloc-7.79%. Both fullcombined
defaultstage tests and rawfixedpoint exercised before the latest v29 proof above.

### Historical failures and superseded experiments

Full v26 completed RESOURCE_LIMIT/rss_limit at1498713ms: peakRSS8592687104,
physical8176602960. Genuine SOURCE expansion now PASSED319637.304ms;
last phase stage-two-check at1085762.300ms, no stage2/fixedpoint.
Unchanged stage1 SHA
`c3c80bead8bb4971646c62ed3e1e64875dc7fa36b0c5cee06fbf60d0472ef6a9`,
17153254bytes. Template sharing is exercised; checker memory remains open.
New private slices: canonical native named-record payload/full constructor-tag
cutover (no produced positional arrays/getters), and strict-position ordinary
calls directly invoke existing uncurried entries while retaining result forcing.
Strict candidate proven all478canonicalemitterdefs,1540/1541nativebodies,
sourceconsumer+120001tails; controlled16fieldloop CPU-5.69%/allocation-7.79%.
Neither new candidate is integrated yet; ctor suite active, parent no heavy job.
Failed diagnostic replay `selfhost-root-source-checker-profile-release237-v1.*`
is NOT valid CPU evidence: native-tag root expansion followed by source checker
fails after2transitions. Native backend uses qualified tags, current source
produces/matches short tags; inverse source-parser→native-expander replay also
fails. Actual bootstrap uses homogeneous stages and reached checker: do not
reinterpret diagnostic ABI failure as its RSS cause. Source snapshot archived;
runnable replay removed. Native ABI authority comp.ts3198-3206/bend.tsname_key.

Current full default run: bootstrap v26, admitted parser54/native root27.
Root27 checks7900 bodies, zero exclusions/output patches,44170 ms,
physical2594045472 / RSS2510192640, SHA
`638897bdbf538fedafadc2c26e2efde8cd384aebb20ddb93c0d390699cf77ec5`.
v25 proved emitted stage1 parser can parse the ENTIRE compiler root, then failed
heap OOM during stage-two-expand; elapsed1144085ms, physical7330415104 /
RSS8458092544. Full source parser stack fix is exercised; no stage2 yet.
Parent added conservative immutable constructor-only subtree reuse to Template
expand_term: constructors and unchanged leaves reuse input; references/apps and
all uncertain syntax retain original expansion. Predicate short-circuits.
Four new source defs/5 generated helpers; Template192defs/726calls/503pending.
This is native-validated, not yet a source-stage memory/fixedpoint proof.
Both private experiments stay UNINTEGRATED: owned vector requests regress
one-argument CPU5.07% and barely change16-field metadata allocation(-0.33%);
AST restore saves3.068s in one pair but raises endpoint/peak heap~60MiB.
No heavy jobs except complete v26; all private experiments finished.

Current: full bootstrap v25 running with freshly admitted parser53/root26.
v24 stack identifies ordinary `combine_symbols` constructor-tail recursion:
`run_loop` -> combine_symbols -> strict recursive list tail. Parent changed
canonical parser's combiner to a reversed-prefix tail pass, preserving scanner
states and token spans. This deliberately changes canonical parser source, not
the official2.0.37 kernel or transport. Parser53 all75 semantic/span admission
cases pass; native root26 checks7895 bodies, zero exclusions/output patches,
44178 ms / physical2585196552 bytes; SHA
`32ae6d92a68706839efba196cec8a8578b9d8025631514e04fb6f08d1d799845`.
Actual emitted stage2 stack fix still awaits v25 proof; no fixedpoint yet.
Independent private experiments: owned argument-vector tail requests and bounded
native AST restoration cost. Neither is integrated; no heavy-lane competition.

Latest full default bootstrap v23 failed after 602449 ms at genuine
`stage-two-parse`, with `RangeError: Maximum call stack size exceeded` while
stage1 parsed `checker_core_steps_v1.bend`. No deadline/OOM or stage2 artifact:
physical 5482896856 / RSS 6300696576 bytes. Fresh parser52 admitted all75;
native root25 checked all7894 bodies, zero exclusions/output patches, 44270 ms,
physical2580478464 / RSS2497937408, SHA
`7c520889bbddb4880b09090b00527eef83d6144d74fe1c368be8ba4788eabf75`.
Unchanged stage1:17136490 bytes, SHA
`b199f1cb6018fb3544fd028e268d474a42373037e532197ffbd6c5a75842798b`.
Root phases: parse119977.958 ms, expand15412.191, check170338.405,
emit71278.894; total377007.448 ms, still above300000. All76 seed fixtures
passed before stage1. Stage2 comparison now precedes emitted-stage fixture suites.
Next: capture actual emitted-parser stack, remove its real recursion cause,
then rerun the complete gate. Fixedpoint and five-minute target remain OPEN.
Isolated unchanged stage1 parsing of the same checker source returned
`FeedbackComplete` after158309 ms without reproducing the stack exception;
the probe did not inspect the inner ParseResult and is not an acceptance proof.
Its exact source is archived in
`selfhost-stage2-parser-stack-release237-v1.source.json`; runnable probe removed.
Full default bootstrap v24 now runs with identical root25/parser52 and additional
failure stack reporting only. Do not infer a parser fix from the isolated result.

Full default bootstrap v22 completed with `deadline_exceeded` at 1800018 ms,
not OOM: physical 4831464816 / RSS 4691427328 bytes. All 76 seed fixtures and
four genuine stage1 fixtures passed (specialization, Nat extrema, deep tails,
nullary arrays); deadline hit next aliased-specialization checker. Stage1 is
18870783 unchanged bytes, SHA
`f857c74f93ca28c336fc8f54e72aa0d97ff4d369b52e31f405f0e4e01352348c`.
Full root phases: parse 123163.568 ms, expand 17623.573, check 238500.266,
emit 76847.314; total 456134.721 ms, not <=300000 and no stage2.
Actual bounded emitted-checker profile now exists under
`selfhost-stage1-checker-profile-release237-v1.*`: fresh Base parse 11173.606 ms,
expansion 13985.971, first 20 s checker still Arena packing; self $ctr 18.9%,
GC 13.7%, run_loop 12.1%, $resolve 5.9%. Diagnostic sources archived in
`selfhost-stage1-checker-and-ctor-layout-release237-v1.source.json`.
Parent integrated exact graded root-match contractions, static constructor
tag/field metadata (original captured-vector getters retained), definition-scoped
scalar schema preparation, and fixed-signature uncurried source calls. Constructor
consumer v2 proves own/erased fields, native named-only inputs, positional mutation,
vector replacement and borrowed-getter semantics; unchanged before/after outputs.
Fresh parser51/root25 native admission is running. Full gate now performs genuine
stage2/raw byte comparison before both complete emitted-stage fixture suites:
no fixture or final acceptance criterion removed. Private experiments continue
on native saturated operators, redundant strict forcing and repeated word-key
resolution; do not apply private results without actual checking/consumer proof.

Fresh parser `release237-v50` now fully admitted; corrected owned checker bytes
SHA `291fc06c1571bdb5826c633fbc3db6388f6d148998d051dbbbd3309ea21a7693`
match the private grammar proof. Full native root `canonical-release237-v24`
checks all 8155 bodies, zero exclusions/patches: 48410 ms, physical 2606530800 /
RSS 2523381760 bytes; artifact SHA
`ace0dccca8d1fce63f138f5894ac874a63577dfba805e8e094a354593e22f60d`.
Default full 76-fixture bootstrap v22 is running unprofiled, with real stage
boundaries and raw byte comparison; no acceptance yet. Two independent private
agents investigate eager native builtin dispatch and redundant CPS helper shapes.

Latest actual proof: nullary affine-array memoization regression fixed in source
`js_emit.bend`, without emitted-byte or AST-transport patches. Before:
`selfhost-nullary-array-release237-v4.json`, `BitZero{}` instead of `BitOne{}`.
After: `selfhost-nullary-array-fixed-release237-v1.json`, unchanged emitted JS
prints `BitOne{}`. Fresh actual emitter native-checks all 1447 selected bodies:
6110 ms / physical 798173824 bytes. Consumer parse/expand/check/new-emit/run:
5170 ms / physical 406751384 bytes. Exact diagnostic sources archived separately.
This proves array-factory ownership, not the stage1 checker OOM cause or fixedpoint.
Parser `release237-v49` FAILED semantic admission (74/75): generated scalar-schema
patterns embed unsupported nested U32 numeric fields. Private ClosedScalarTyping
agent replaces constants with bound fields and typed guards before child reads.
Root v24 has not been built; next fresh parser must be v50. No stage2 yet.

**Shared immutable layouts и разделение signature/body preparation реализованы и перенесены на Bend 2.0.37. Полный compiler root native-validated.** После CPU-профилирования CPS request/result/resume/step dispatch разделён на типизированные группы по 64 исходных declarations. Новый root `canonical-release237-v13`: 57,126 ms, physical 2,587,277,080 / RSS 2,505,965,568 bytes (ранее v11: 77,819 ms, physical 3,216,420,352 / RSS 3,162,963,968). Реальный fixture `type-specialization` parse/expand/check/emit/run: 28,951 ms, physical 562,488,520 / RSS 782,647,296, с CPU и allocation sampling; baseline 120,645 ms / RSS 1,827,700,736. **Это не full-root self compilation и не fixedpoint.** Stage1/stage2 ещё не получены. Checkout — release `4ff8545f19b09b7d2b8ca2303668100eac8efd66`, CLI `bend 2.0.37`; старые plain v13/v34 reports и разделы 3–10 — история 2.0.16.

Пользователь обновил `AGENTS.md`: при последнем чтении из файла удалены запреты на изменение компилятора, языка и архитектуры генератора. Старый сеанс содержал отдельно загруженную прежнюю редакцию ограничений, поэтому эти изменения не были сделаны. Новый агент должен читать актуальные проектные инструкции и свой загруженный контекст; этот handoff сам по себе не отменяет инструкции более высокого приоритета. Старые запреты в исторических документах/todos не являются описанием текущего содержимого `AGENTS.md`.

Рабочий каталог: `/Users/ilyagulya/Projects/My/bend`; Darwin 25.6 arm64, Bun 1.4.2, Node 23.11.0. Parser/root находятся в общем `checkpoints/`, namespace conflict устранён. Fresh parser `release237-v39` admitted 75/75; canonical parser SHA неизменен. Native root v15 после single match factoring: 88,764 ms, physical 2,582,222,392 / RSS 2,382,692,352 bytes. Actual `type-specialization` fixture PASS 13,681 ms; `specialized-type-error` PASS 10,040 ms с ожидаемой ошибкой. CPS использует original authenticated canonical declaration blocks под owned native-provider header: Checker 4356 -> 966 definitions, pending sites 6070 -> 2506, helpers 8463 -> 5087; Template 218 -> 188. Full root profile v3 достиг `checker_match_2990`, ~333M requests, но checker превысил 300000 ms; artifacts пусты. Его checker CPU samples: GC 21.0%, `runSteps` self 17.4%, top dispatcher self 10.2%. Порог 5 минут и fixedpoint **не доказаны**.

Три независимых sandbox эксперимента завершены и точечные кандидаты внесены parent в production: `index_lookup.find.walk` использует существующий `String.eq` вместо собственного recursive string comparator; `replace_free_term` сохраняет immutable tagged handle при conservative bound certificate и оставляет unknown-bound traversal; source JS emitter переиспользует resolved type key вместо промежуточного descriptor и повторного namespace lookup. Parent дополнительно убрал index/depth arithmetic для closed/unknown bounds. Изолированные результаты: lookup median 503.19 -> 206.71 ms (2.43x); capture-type refinement 6173.75 -> 992.89 ms (6.22x), arena nodes 104 -> 14; type metadata median 652.01 -> 484.28 ms (-25.7%). **Не выдавать эти подсеты за ускорение полной сборки.** Private evidence находится в `/tmp/bend-selfhost-ScopeLookupSubset-z90fUk`, `/tmp/bend-selfhost-CheckerMatchSubset-uGuCp2`, `/tmp/bend-selfhost-EmitterApplySubset-lg1noq01`; production writes принадлежат parent.

Fresh parser `release237-v40` admitted 75/75, both public gates 14 PASS / 207 assertions; canonical parser SHA unchanged. Native root `canonical-release237-v16` PASS 50,441 ms, physical 2,648,556,584 / RSS 2,625,290,240 bytes. Parent actual integration fixtures PASS: type-specialization 11,104 ms; specialized-type-error 8,234 ms; readonly-index-boundaries 13,393 ms; dependent-nested-binding-refinement 952 ms; affine-constructor-field-quantity 771 ms с ожидаемым diagnostic/spans; alias-dependent-conversion 912 ms. Это проверенные подсеты, не fixedpoint.

Full root profile v4 опять превысил 300000 ms checker target, но достиг `emitter_body_js_ref_strings` (~422M requests); stage artifacts отсутствуют. Sampled CPU: runSteps self 19.1%, GC 17.1%, top checker_step self 11.6%. По heartbeat наблюдениям `emitter_body_js_ref_f32_3` оставался current definition на 12-second window / 19.3M requests; это не точный full definition timer. Два новых private эксперимента: literal-heavy source checking и CPS scalar admission. Scalar subset подтвердил exact request reduction для `core_bound_unaffected`, dependent fingerprints и affine/type diagnostics; parent интегрирует только этот exact predicate под существующим live/bounded/nonrecursive policy, не generalized composition-analysis abstraction. Native root v17 build выполняется. Driver tag-cache candidate пока в same-work реальном checker smoke; не считать выигрыш доказанным до receipt.

Native CPU профилирование тоже выполнено: `selfhost-profile-native-release237-v2/selfhost-54960-thread-1-AMELE0/000001-seed-native-load-check-emit.cpuprofile`; actual compiler isolate thread 1, automatic GC и прежний 8GiB/10ms guard. Raw artifact bytes совпадают с unprofiled v16 (`cmp -s` PASS). CPU sampled self: GC 19.4%, checked storage restoration anonymous frame 14.2%, `writeFileUtf8` 13.2%, `NativeCheckedStorage.get` 12.5% self / 32.5% inclusive. v1 captured idle supervisor isolate и **не является native compiler CPU evidence**. Observational preload snapshot archived as `checkpoints/selfhost-native-cpu-preload-release237-v2.mjs`; его original relative import отражает original execution location in `evals/`, это source snapshot, не runnable entrypoint.

После интеграции остаются полный root check/emit/run в пределах пяти минут и настоящий stage1/stage2 byte fixedpoint. Не менять production источники во время authenticated runs, не обходить общий heavy lease и не восстанавливать Eval globals по именам из handoff.

Latest integration: fresh parser `release237-v41` admitted 75/75; native root `canonical-release237-v18` PASS 191,519 ms, physical 2,326,736,448 / RSS 2,109,603,840 bytes. Exact-span childless constructor interning uses source-only memo lane, no typing shortcut/public AST change. Isolated actual 582-codepoint literal subset: source nodes 79,369 -> 60,169 (-24.19%), runtime 3250.98 -> 3242.69 ms (effectively flat); all17 valid/invalid outcomes equivalent. Private evidence `/tmp/bend-selfhost-LiteralCheckSubset-lfUI4D/report.json`.

CPS generator now directly calls earlier typed step bodies for identity continuations with projection-only live arguments, retaining all recursive/back edges and public request handlers. Authenticated single-constructor record roundtrips are folded before lexical indexing; ascriptions preserved, promotions require native closed-Data proof, dependent/unsupported promotions stay unchanged. Checker pending sites 2508 -> 2137, helpers 5094 -> 4445; Template pending714 -> 670; Emitter pending1303 -> 1140. Actual full-native root validated; Unicode-string-pattern fixture PASS 25,942 ms, dependent nested refinement PASS 2,299 ms, affine-negative fixture PASS 1,704 ms with expected diagnostic.

Root profile v5 remained FAIL at 300000 ms checker target: ~280.7M requests, `checker_match_2989`, no stage artifacts; 300001 ms wall / 220539 ms process CPU. Timing varies substantially: native v17 was 259124 ms wall / 80573 ms CPU; do not infer code speedups from unrelated partial progress or endpoint RSS. Driver tag-cache smoke executed actual dependent/affine checker paths and emitted identical program bytes, but alternating timing samples had large warm-up/load drift, so no controlled whole-root speedup claim.

Real full acceptance gate v17 timed out at its existing 3600-second command deadline (no fixture/profile-root/parse-only flag): all73 seed fixtures PASS, source root checker completed, but stage-one emitter produced no artifact in the remaining ~2443 seconds. Report `selfhost-steps-bootstrap-release237-v17.json` retains interrupted IN_PROGRESS with empty artifacts; it is **not acceptance**. Five-minute complete stage target and stage1/stage2 byte fixedpoint remain **unproven**. Do not repeat or extend this unchanged full run. Existing 8GiB/10ms resource guards remain unchanged.

Full acceptance v17 checker receipt `selfhost-profile-full-release237-v1/selfhost-66773-thread-1-O96BTT/001145-stage-one-check.json`: 450,987 ms wall / 455,672 ms process CPU, endpoint heap 2,854,943,936 bytes (not peak). Whole-root checker CPU samples: GC23.5%, top dispatcher11.8%, generic driver8.0% self. SIGKILL lost the uncompleted emitter phase profile. Bounded replay of authenticated original parser transports reproduced actual Bend expansion and saved exact expanded modules `selfhost-emitter-expanded-release237-v1.ast.json` plus provenance receipt; this diagnostic-only transport is not a stage input/checking shortcut. First in-worker 120-second observer did not interrupt a synchronous source helper and itself hit 300 seconds. Follow-up external NodeWorker inspector profiling captures the genuine emitter even inside synchronous helper calls.

Emitter reachability subset candidate replaces linear visited-definition lists with a persistent resolved-key map while preserving emitted-definition order. Native-checked baseline1385/candidate1383 definitions; 1024-definition graph median1996.38 ->470.37 ms, actual512-definition library874.34 ->419.29 ms with identical120828 raw JS bytes and execution outputs. Small cases can regress; no whole-root claim. Evidence `/tmp/bend-selfhost-EmitterReachability-870d76/report.json`; parent integrated narrow reachability hunks, integrated verification pending independent declaration-index candidate. Do not overwrite emitter with a child snapshot.

Actual interruptible full-root emitter CPU evidence now saved: `selfhost-emitter-remote-release237-v1.cpuprofile`, SHA `f9826f5ef40b6bbeb9733ee2e0092116b6422265242fa86383e2fd52d792892d`. External NodeWorker inspector stops sampling even within synchronous helpers; 60,685 sampled ms, Path.normalize54.4% inclusive, String.split33.8% self, find_namespace53.2% inclusive, GC16.6%. These percentages overlap; this is the initial60-second actual emitter window, not its complete40-minute run. Diagnostic command guardian PASS275917ms, peak physical1132215672/RSS1079328768 bytes, no stage artifact/checking shortcut.

Parent integrated three emitter subsets narrowly: visited-key map; immutable first-owner path index and shared resolved alias layouts (including metadata/CLI); ordered same-key type-declaration index. Namespace private same-work49-module/432-import library29295.60 ->1185.69ms,67187 raw bytes identical, namespace resolutions58328 ->432; type-index private64-module library5387.55 ->3569.70ms,333986 raw bytes identical. Small catalog construction can regress. Sources/evidence remain `/tmp/bend-selfhost-EmitterNamespaces-b760ad/report.json` and `/tmp/bend-selfhost-EmitterTypeLookup-Cy8X1g/report.json`; their native compiler snapshots precede parent string-equality primitive. Integrated root acceptance still required.

Complete checker allocation sample estimates total1.288TB cumulative collected allocations (4MiB sampling; NOT live memory); IndexLookup.find.walk and its continuation sites account for49.7%. Parent replaced cursor/division/five continuations with standard native-backed Map.bit and two branch continuations; native-checked363 definitions,214 Unicode/prefix/NUL/missing/nonmonotone cases PASS.50k-call sampled allocations1153851536 ->427219928 bytes; medians825.66 ->481.04ms, substantial warm-up/load variation. Receipt `selfhost-index-intrinsic-release237-v1.json`. Direct builtin String.eq JavaScript lowering added to both emitters; actual JS and C `tests/base/map_prefix_keys.bend` produce all7 expected lines, including equality edge cases.

Single-pass Path candidate integrated from `/tmp/bend-selfhost-SourcePathNormalize-816309/handoff.json`:4043 paths/84903 private native comparisons, raw/execution parity on3 libraries; realistic normalize48.74 ->13.57ms, dirname16.10 ->16.88ms (small regression). Parser42 preparation rejected new numeric `Chr{46}` patterns; equivalent character-literal source spelling preserves the algorithm and passes native AST/literal-span parity. Parser43 completed all75 rows but JSEmit's newly computed-match scrutinee failed native syntax normalization; parent extracted typed `js_type_modules_needed` parameter helper. No parser/kernel/AST edits. Failed42/43 evidence retained, not admission.

Latest integrated proof: fresh parser44 admitted75/75, both public gates14PASS/207assertions; complete optimized native root19 generated9,268,978 JS bytes, all7772 bodies genuinely checked, zero excluded/patches. Guardian PASS52,730ms, processCPU61,847ms, peak physical2,608,269,856/RSS2,523,938,816 bytes; generated artifact NOT_YET_EXECUTED receipt is not bootstrap acceptance. Entire fresh proof/root pipeline257.26s. Real complete default bootstrap gate is now running as `selfhost-steps-bootstrap-release237-v18.json` with native root19/parser44 and CPU/allocation profiles `selfhost-profile-full-release237-v2`; all73 fixtures at every stage plus actual stage1/stage2 root emission/import and raw-byte equality required. Freeze protected source inputs. Standalone sequential `main.ts js_emit.bend --check-only` stops at a forward reference (`js_value_indices_at`); the existing forward-helper source style is handled by authenticated typed CPS generation, whose complete native root validates all bodies. Do not count that standalone command as a passing source check.

Owned diagnostic scripts/Bend fixtures removed after exact source snapshots were archived in `selfhost-index-intrinsic-release237-v1.source.json`, `selfhost-emitter-expanded-release237-v1.source.json`, and `selfhost-emitter-remote-release237-v1.source.json`. Archived native index subset artifact `selfhost-index-intrinsic-release237-v1.mjs` is unchanged measured output, not a stage artifact. Old receipt pins refer to original source paths; snapshots retain those exact bytes.

First genuine complete stage1 artifact now exists: default acceptance v18/native root19 emitted `selfhost-steps-bootstrap-release237-v18.json.cases/stage-one.js`,84,299,486 raw bytes, SHA `ac33f47644abfedac5f1068235e558ee7b217656e20a029102dc625d2d6fef60`, imported full ABI and parsed first stage1 fixture's tiny root. All73 seed fixtures PASS. Gate then FAILED existing1800s deadline while stage1 parser processed original Base for first fixture; no stage1 fixture completion, stage2 or byte fixedpoint. Guardian peak physical6,987,940,672/RSS5,280,284,672 bytes; no memory limit raised. Do not extend/repeat unchanged gate.

Complete source root timings now measured rather than partial: expand~16.4s; checker387,128ms wall/378,662ms CPU; emitter373,427ms wall/349,647ms CPU. Both complete profiles in `selfhost-profile-full-release237-v2/selfhost-64077-thread-1-yT1dGK/001145-stage-one-check.*` and `001146-stage-one-emit.*`; source stage remains~13min, NOT<=5min. Checker selfCPU: dispatcher16.0%,generic driver10.1%,driver wrapper6.9%,GC20.7%; emitter16.7%,12.8%,8.3%,GC22.5%. Namespace normalization bottleneck removed, current dominant overhead is dispatch/protocol allocations. Parent launched bounded external inspector profiling of genuine unmodified stage1 Base parser, and two private slices: typed source direct invocation on Pending (host remains generic LIFO) and shared staged constructor layout/accessor descriptors (own fields and vector coherence preserved).

Actual unmodified stage1 Base-parser CPU window is archived as `selfhost-stage1-parser-profile-release237-v2.cpuprofile`, SHA `a2547f4a36d1dc5cedcaa8a65244b13f0aa0a9a06744e9f84e5cef92e8757234`:20,300 sampled ms; GC53.89% self and `$ctr`33.51% self. Emitted lexer predicates rebuild32 Word constructors for each closed U32 character constant. Parent integrated source-only closed native U32/F32 Word-literal folding, preserving actual Base ownership and falling back for open/malformed/shadowed constructors. Private native-checked1398-definition candidate passed execution/boundary fixtures; actual emitted digit scanner30k calls improved9942.12 ->70.11ms, sampled cumulative allocation16.35GB ->248.75MB. This is subset evidence, not full-stage timing or bootstrap acceptance. Parent added early rejection before traversing an open/noncanonical bit's tail.

Parent also integrated one immutable flat value/constructor owner catalog and ordered type-owner indexes from `EmitterGlobalCatalog`; private27 raw-byte/execution parity cases PASS,49-module subset170.706 ->74.791ms including construction. Small catalogs can regress and retained catalog graph grows; do not claim a memory reduction from this index alone. Fresh parser45 admission is running against both integrated changes; full-root validation and stage1/stage2 remain pending. Source CPS regeneration completed under unchanged guards.

Generic shared-constructor getters remain a retained private candidate, NOT integrated: their receiver-based fields differ from existing original-vector capture for vector replacement and borrowed getters. Do not attribute that candidate's allocation results to production. `CpsDirectDispatch` independently investigates typed earlier-body direct invocations and generic native sharing of closed named function wrappers; no production change from that slice has been integrated yet.

Integrated source admission completed: parser45 all75 acceptance/semantic/literal-span parity rows PASS. Complete native root20 validates all7818 bodies with zero excluded checks/output patches; guardian PASS44,901ms, peak physical2,524,439,616/RSS2,446,540,800 bytes. Artifact SHA `ba5fca2a9918aaa7b62d21e5fd8424d881b2bfac57076bc1250e5ff3aaeb7a3d`; native receipt remains NOT_YET_EXECUTED, not acceptance. Actual default full bootstrap v19 is now running with root20/parser45, all fixture stages and raw stage1/stage2 equality enabled; profiles `selfhost-profile-full-release237-v3`. Source inputs/runtime are frozen until this run completes. Five-minute target and fixedpoint remain unproven.

Default v19 completed seed73 fixtures and genuine full root emission: checker339,610ms/emitter67,296ms (previous387,128/373,427ms); stage1 is31,771,111 rawbytes SHA `999efd7815c27ba5d9d609c89bd56c1c795a1cc6ff0cffabbb06c734da175352`. No five-minute claim: check alone remains>300s. First stage1 tiny-root parser semantic parity PASS, but original Base parse hit unchanged8GiB RSS guard after1,600,402ms; peak physical8,539,076,336/RSS8,617,820,160 bytes. No completed stage1 fixture, stage2 or fixedpoint. Do not replay this unchanged full gate.

New bounded20-second actual stage1 Base profile v3 guardian PASS26,613ms, peak physical5,501,628,648/RSS6,143,131,648 bytes. Raw profile has one negative time delta; the existing strict summarizer rejects it, so preserve raw evidence and explicitly exclude that single invalid sample for diagnostic aggregation. Valid sampled20,193ms:GC57.14%,`u32_to_word`18.52%,`$ctr`6.19%,`$resolve`3.88% self; recursive call-frame identities aggregated, not single profiler-node percentages. Exact throwaway source archived as `selfhost-stage1-parser-profile-release237-v3.source.json`; runnable probe removed. Two private source-emitter slices investigate unused native Word projection and generic tail-call retention, not parser/host shortcuts.

Parent integrated CpsDirectDispatch's typed earlier-body invocation/argument records, generic LIFO Direct boundary and generic native sharing of closed named-function wrappers; future/self/backedges and all public request handlers remain. Actual regenerated checker969 canonical definitions has1105 pending sites (previous2137), template499 (previous670), emitter606 (previous1188); all-body root proof still pending. Source emitter also adds already-canonical Nat.min/max intrinsic lowering. Fresh parser46/native root21 pipeline is running; no current bootstrap run. Preserve production inputs until proof completes.

Fresh parser46/native root21 proof completed: all8431 bodies checked, zero exclusions/output patches; guardian45,951ms, peak physical2,445,675,392/RSS2,371,813,376 bytes. Actual integrated type-specialization consumer PASS5,828ms, physical371,143,312/RSS612,859,904; diagnostic subset, not fixedpoint. New permanent bootstrap fixture `native-nat-extrema-boundaries` executes unchanged source-emitted min/max across zero/equality/order and computed2^48-1; PASS5,661ms, physical342,042,088/RSS579,158,016. First attempted direct decimal48-bit spelling was rejected by existing parser and retained failed receipt; fixture computes the same largest native Nat from supported smaller operands without overflowing intermediates. Full default gate now contains74 fixtures, never silently drops old73.

Private pattern slice confirmed another concrete staged parser cause: one closed U32 character pattern evaluates `u32_to_word` repeatedly at structural Word tests (about97 static conversion occurrences for one pattern). Exactclosed native U32/F32 pattern scalar lowering is being verified; no source integration yet. Private generic source-tail slice also has an authentic native-checked candidate, consumer verification pending. Avoid another full gate until both retained-all-body candidates are resolved.

Both staged source fixes are now integrated narrowly: exactclosed native U32/F32 Word pattern tests (F32 compares bits, not numeric equality) and generic symbol-tagged source unary tail requests/closures. Open/binding/explicit Word patterns remain structural. Tail closures force strict operands/intermediate currying; final tail requests carry `{f,x}`, no thunk/argument array. Private pattern225 paritycases passed; actual closednativepattern CPU603,316 ->2,396µs, Base-prefix parser pipelines2,310,037 ->1,360,232µs. Private source-tail120001-call consumer passed at300,482,560 RSSbytes; recursion profiling max128frames ->25frames, but sampled allocation127.1 ->175.2MB increased, so no blanket allocation reduction claim. Existing foreign-object IO-main failure is unchanged, outside compiler-root acceptance.

Fresh parser47 admission/native root22 completed: all8449 bodies checked, zeroexcluded/outputpatches; guardian46,929ms, peak physical2,464,208,120/RSS2,388,803,584 bytes. Artifact SHA `33acecbf80fa6db2f7bb643766d0a1fef7df755aefb5aef963114df89bb1227e`. Clean production native suite147PASS/901assertions after moving an agent-owned copied-test sandbox outside repo; an earlier run's only failure was that private copied test's missing fixture, retained, not a production pass claim. Full default bootstrap v20/root22/parser47 is now running with profiles `selfhost-profile-full-release237-v4`, unchanged8GiB/10ms/1800s guards; source inputs/runtime are frozen. Full suite now75fixtures: original73 plus real48-bit Nat extrema and65536-step source-tail execution regressions. No current five-minute/fixedpoint claim before actual result.

Full v20/root22 finished all75seed fixtures PASS and emitted genuine19,611,142-byte stage1 SHA `197c49f73d7698ff20401aed8b85b93bd256acab6bdbd1c165dd426f0c226292`. Original Base stage1 parsing now completes12,155ms with full semantic oracle parity, no memory guard raised; previous OOM bottleneck resolved. Gate fails at first stage1 expansion with `TypeError: Cannot read properties of undefined (reading '0')`, not parser OOM; guardian1,110,773ms, peak physical4,535,693,224/RSS4,620,812,288 bytes. No stage1 completed fixture/stage2/fixedpoint. Root source checker378,177ms: record/invoker Direct increases generated check work versus prior339,610ms, despite modest isolated dispatch savings. Do not replay unchanged v20.

Exact bounded repro established ABI cause: original fresh stage1 parser ASTs expand successfully; the unchanged native transport roundtrip drops optional `Symbol.for("bend.fields")` metadata by its documented contract, preserving complete named payloads. Source-emitted pattern projections incorrectly required that optional symbol; native seed projections use named fields. Repro with original Base and genuine unchanged stage1 now fails in8,894ms atstage-one.js:9217; direct fresh AST expansion PASS16,082ms. Wrong main-thread stack diagnostic attempt SIGSEGV is retained, not acceptance; actual repro uses existing256MiB worker stack. Parent source emitter fix generates `$field(v,i,k)` from authentic constructor binder names, using an existing positional vector when present and canonical named payload when absent. Thus vector replacement/borrowed getter semantics stay unchanged; no transport/AST/artifact patch.

Fresh parser48/native root23 proof for named-payload fix is running. Parent prepares genuine source-emitted canonical Template dependency library to exercise unchanged native AST roundtrips before another full gate; this bounded smoke is diagnostic, not a substitute stage. Two private performance slices now target compact typed Direct thunks without per-target derived record/invoker declarations, and exactclosed scalar constructor typing certificates; no production changes from them yet. Five-minute source-root target remains open. Runnable owned probes must be removed after exact source evidence snapshots; do not alter archived failed stage artifacts.

Named-payload integration proof: parser48/native root23 all8453 bodies checked, zeroexclusions/patches;45,955ms, physical2,434,601,392/RSS2,361,098,240 bytes, SHA `b5f6079b40608aee1c494c211e6eec116843cf83ff8e5a774b33008dfe9c17bd`. Real source Template smoke freshly parses/expands/checks/emits the complete canonical Template dependency closure, imports its unchanged1,838,019-byte JS library (SHA `96f73c2a2f140471a4fbee73fdbcc65fb7a39bd20159ec6ee04994a2ea4755eb`) and expands original Base plus tiny root ASTs from genuine stage1 parsing after unchanged native transport roundtrip. PASS49,769ms, physical1,328,386,896/RSS1,337,671,680; no stage/fixedpoint claim from this diagnostic. Exact3 owned probe/root sources archived and hash-checked in `selfhost-template-native-abi-release237-v1.source.json`; runnable probes and throwaway root removed.

Actual complete default bootstrap v21/root23/parser48 is running WITHOUT CPU/allocation instrumentation to separate compiler time from profiler overhead. It retains all75fixtures, fresh parses/checks, real stage1/stage2 raw bytes, unchanged8GiB/10ms and1800s deadline. Prior complete CPU/allocation profiles and actual staged parser evidence remain archived; stage2 profiling still pending. No source/generator/runtime changes while run active. Five-minute target and byte fixedpoint remain unproven until result.

Unprofiled full v21/root23 completed all75seed fixtures and emitted genuine19,641,770-byte stage1 SHA `6fc2611cd161114499b9ba510be711184fde2d6d104d32695fdcf952fa2a183a`. First stage1 fixture original Base parsing and expansion now PASS; checker worker then reaches its existing6144MiB heap limit. No stage1 completed fixture/stage2/fixedpoint. Guardian903,341ms, peak physical7,339,866,896/RSS6,742,458,368 bytes; guards unchanged. Actual unprofiled source-root timings from phase boundaries: parse140,783ms, expansion19,896ms, checker451,862ms, emitter81,039ms; load/profiling drift prevents a simple before/after CPU claim. Five-minute root target still NOT met.

A concrete semantic ownership bug is now reproduced: source nullary definition memoization makes independent `fresh() -> Array<U32>` calls alias. Permanent fixture `nullary-array-freshness` parses/checks/emits successfully but unchanged emitted execution printsBitZero instead of expectedBitOne (`selfhost-nullary-array-release237-v4.json`). Earlier attempted fixture spellings failed canonical grammar (computed/local scrutinee restrictions); failed receipts retained, final fixture uses typed parameter helpers. Source emitter now demand-evaluates each nullary reference without caching its result; functions remain directly registered, foreign initialization remains deferred. Native AST/kernel/parser/transports/artifacts unchanged. This can explain source/transient `Arena.empty()` array aliasing in stage1 checker, but full-stage OOM causality still requires confirmation.

Parent also integrated compact typed Direct Unit-token closures and the closed scalar typing certificate. Parent compressed33 separately unrolled Nat schema validators into one bounded decreasing loop and removed38 redundant boolean-true operations;68 checker functions added instead of100. Compact thunk private sourcechecking cost fell~15% at largest scaling case but runtime allocated bytes rose~9.7%; do not claim unconditional runtime memory savings. Exactclosed scalar private582-literal sourcechecking3457 ->1639ms, unchanged source nodes, transientpeak42934 ->21218; original helpers/aliases/uncertain cases still use general checking. Regeneration now checker1037 canonicaldefs/4741helpers, template188/457, emitter437/1043. Fresh parser49/native root24 full proof is running; no current bootstrap run.

## 2. Состояние: что работает, что не доказано

Работает:
- Профилирование включается `SELFHOST_CPU_PROFILE_DIR=/absolute/directory`.
  `selfhost_cpu_profile.mjs` сохраняет по фазам inspector `.cpuprofile`,
  `.heapprofile` (4MiB statistical allocation sampling, включая collected
  objects; первоначальный baseline использовал 64KiB), wall/process CPU/memory summaries. Oracle — отдельный Bun child;
  emitted fixtures — отдельные Node child profiles и resource receipts.
  При unset env прежний путь исполнения сохраняется. Root profile mode
  `--profile-root=true` не публикует compilerBootstrapGreen/fixedpoint.
  `node evals/summarize_cpu_profile.mjs FILE...` считает self/inclusive sampled
  milliseconds, не дублирует recursive frames; не выдавать samples за точный
  CPU accounting. Сам native compiler seed build надо отличать от selfhost stage.
- Baseline actual root CPU: `selfhost-profile-release237-v1-{restore,expand,check}.cpuprofile`.
  Restore 70.66 s: `scan` 65.9% active sampled self time; expansion 44.20 s:
  driver/tag decoding 39%, GC 11%; bounded checker 180.58 s:
  giant `checker_step` 63.8% self time, GC 5.6%. Не утверждать V8 deoptimization:
  profile не содержит подтверждённого deoptReason. Именно размер typed dispatch
  стал первым измеренным исправлением, не kernel/AST/output patch.
  Successful profiled fixture evidence: `selfhost-profile-fixture-release237-v1.json`
  (baseline), `...-v3.json` (grouped CPS). Intermediate `...-v2.json` проверил и
  исполнил fixture, но **FAIL** final input guard: producer изменён во время run;
  не использовать этот report как acceptance или доказательство ускорения.
- Root v1 checker CPU/heap остановлен на 300000 ms, а не оставлен на часы.
  Cumulative allocation estimate 310,215,406,104 bytes / 4,719,752 samples;
  это **не RSS/live heap**. `Map.bit.go` + reconstruction ~69.5GB estimates,
  continuation driver ~18GB. Summary:
  `selfhost-root-profile-release237-v1-allocation-summary.json`.
  Прямые native JS map/string primitives прошли 1598 bit cases, 196 Unicode
  comparisons, 16 actual map lookups и миллион bit calls; permanent
  `tests/base/map_prefix_keys.bend` прошёл actual JS и C executions.
  Both emitter implementations обновлены; source-stage execution ещё нужен.
  Driver использует grow-only continuation buffer и очищает consumed slots.
  Root v2 throughput ~368M/300s против ~189M/300s v1, но input/helper sampling
  различались, поэтому это не same-work speedup и не успешная полная проверка.
  Allocation interval увеличен до 4MiB: ранний 64KiB sampler сам сохранил
  377MB profile; sparse sampling снижает observer overhead, сохраняя estimates.
- `equal_raw` сравнивает полные immutable U32 handles через `U32.is_eq` до
  структурной проверки. Реальная трасса выявила повторный вход с `(89, 89)`.
  Minimal `recursive-neutral-application-equality`: до исправления 600-second
  timeout, после — actual native compiled parse/expand/check/emit/run PASS
  за 2,262 ms. Полный v8 подтвердил все 73 seed fixtures, включая distinct
  neutral indices, distinct branches, affine failures и imported family identity.
  Повторная проверка `base.bend` стоит около 95 секунд на fixture; aggregate
  600-second deadline был исчерпан на седьмом fixture, не в equality loop.
  Longer full v8 завершил seed fixtures и обнаружил именно namespace conflict;
  memory/RSS limits остаются 8192 MiB, 10 ms, без manual GC.
- Full bootstrap v15: 73 seed fixtures PASS; full source root parsed/restored
  без AST patches, expansion завершён. Stage-one checking остановлено aggregate
  RSS 8,590,065,664 bytes (physical 4,859,442,968), 9,022,068 ms.
  Не повышать guard и не повторять долгий run без lifetime proof.
  Root checker bounded probe использует реальные authenticated v15 transports,
  затем actual compiled Template/Checker; это диагностика, не acceptance.
  Scalar string interning сохраняет все values/fields/sharing/cycles: restored
  worker heap 1,665,505,288 -> 1,019,200,240 bytes; guarded 180-second checker
  probe peak RSS 4,547,985,408 -> 3,707,895,808 bytes.
  Проверено actual restored full source input, не synthetic storage benchmark.
  Все 8-GiB/10-ms limits и official kernel остаются неизменными.
- Текущий переход на 2.0.37: actual JS/C arena-generation regression печатает `7`;
  девять native JS executions проверили retained/released/stored checked-body
  режимы, byte equality, mutual recursion, 200,000 tail steps, callback exception
  identity и восстановление depth после exception. В основном checkout permanent
  `native_checked_storage.test.ts`: 2 PASS / 8 assertions; semantic factoring,
  capture, affine и progress suites: 70 PASS / 296 assertions.
- Новый source syntax требует собственных `: Nat` аннотаций операторов; обновлены
  реальные source inputs, не исторические generated snapshots. Cursor-call
  renderer сохраняет лексические границы аргументов и аннотации; evaluation-context
  renderer использует native File aliases вместо старого dot-only remapping.
- Fresh parser preparation `release237-v9` PASS: 18,834 ms,
  peak RSS 569,212,928 / physical 289,293,296 bytes. Это закрытый source graph
  и factoring, не accepted parser build. Public grammar: 14 PASS / 207 assertions.
  Native literal/oracle/storage boundary regressions: 33 PASS / 248 assertions,
  включая parenthesized closed Nat tails, explicit U32 decoder и symlink root.
- Full source-evaluator semantic run v9-v2 остановлен physical guard через
  232,978 ms на 506,411-byte generated parser: physical 8,605,552,824 bytes.
  Native oracle отдельно обработал тот же файл: 985 declarations / 788 ms,
  physical 61,620,896 bytes. Ограничение — source evaluator, не native loader.
  До root нельзя допускать этот failure или partial diagnostic.
- Путь разделён на preparation proof (исходная явно ограниченная политика source
  evaluator, 71 cases) и final acceptance (все 75 cases на реально собранном
  parser artifact). Native codegen до final gate даёт только provisional receipt;
  полный compiler root должен требовать отдельный final acceptance wrapper.
  Исторический generated-parser corpus заменяется текущим candidate selfparse,
  Checker slice/driver — текущими owned sources; прошлые reports/pins неизменны.
  Final admission теперь опубликован для v26: PARSER_ACCEPTED_NATIVE_SEMANTICS,
  FULL_75_SEMANTIC_GATE, admitted=true, 75/75 semantic/literalSpan rows,
  checksExcluded=0, outputPatches=0. Full native root build 2.0.37 также PASS.
- Native parser v14 действительно собран и исполнен: 1,439 checked bodies,
  wall 46,197 ms, peak physical 2,284,130,704 bytes. Это provisional artifact,
  не final admission. Native semantic v15 завершил все 75 cases за 39,995 ms:
  peak physical 2,327,298,624 / RSS 4,263,346,176 bytes; admitted=false.
  Streaming declaration normalization убрала прежний OOM при selfparse.
  SNil span, multiline Process.run, adjacent Nat +/Many и computed JSEmit matches
  исправлены. v19 current selfparse и normalized owned checker
  (1,474,547 bytes / 4,350 definitions) дают semantic/literalSpan parity.
  У Base в v19 только acceptance=true: semantic/literalSpan parity=false.
  Прежнее утверждение о Base parity было ошибочным; исторический report неизменён.
  v16 native validation выявила missing List annotation в split-token binding;
  аннотация исправлена в исходном parser.bend, исторический v16 report сохранён.
- Точный limb F32 encoder реально скомпилирован native 2.0.37 и исполнен:
  `float-native-release237-limbs-v5.json`, 48 bit comparisons / 11 rounding
  comparisons PASS, включая длинную мантиссу Base.hypot и subnormal boundary.
  Native boundary regressions v27: 147 PASS / 901 assertions.
- Owned checker сохраняет исходный полный reachable `check_modules` closure;
  с новым signature-predeclaration helper это 964 определения / 4,354 normalized
  defs. Plain variable lets остаются на месте. Ast/Loader/Core identities общие.
  Только видимый scope заранее получает опубликованные typed signatures, без
  непроверенных values; duplicate/signature/body/affine checks остаются прежними.
  Native `forward-family-definition`: before FAIL unknown Word, after PASS WNil.
  Typed steps пересозданы после parser hash change. Полный root v1 2.0.37:
  `selfhost-steps-native-canonical-release237-v1.result.json`,
  11,694 actual checked bodies / 11,992 events; все 9 ABI exports.
  Guardian PASS: physical 3,213,600,672 / RSS 3,162,177,536 bytes, 79,340 ms.
  Artifact SHA256 `4a6fcfad03934372f41c93a6293dc12b5940433fe4d7654b7b7dc4f85868ec13`.
  Это полный native build, не stage1 и не fixedpoint. Fresh полный bootstrap
  `selfhost-bootstrap-canonical-release237-v1.json` FAIL на строгом span validation:
  18 Quant binder spans в Base имели end=0, потому что TermQuant не имеет span.
  Typed/template binder ends теперь берутся из consumed lexical tokens.
  Regression против v26: 2 FAIL; corrected source: 2 PASS / 10 assertions.
  Parser candidate и root находятся в общем `checkpoints/`:
  `checkpoints/.bootstrap_compiler_root_v1.bend`. Идентичный import header
  сохраняет native AST tags и одинаковые namespaces всех shared imports.
  Полный root v4: 11,709 checked bodies / 12,007 events; physical 3,226,202,608 /
  RSS 3,172,990,976 bytes, 80,141 ms. Full bootstrap v5 достиг Base checking,
  но истёк 600,000-ms deadline; stage artifacts отсутствуют.
  V8 profile `/tmp/checker-release237-v1.cpuprofile`: 56.3% + 33.9% self time
  в двух checker dispatch frames, GC 0.7%; проблема — giant string dispatch.
  Balanced dispatch внедрён в обоих JS emitters. Actual native 64-constructor
  smoke: 140 cases PASS, single tag/payload reads, named/wildcard и nonstring
  fallback сохранены. Свежий v30 admission/root/bootstrap проходит provenance.
  v18/v19 full 75 gate остановлен RSS на JSEmit после owned checker;
  final admission не опубликован. В v24 все 75 cases завершены под лимитами:
  physical 3,536,879,360 / RSS 4,096,851,968 bytes, 83,368 ms.
  Осталось одно semantic/literalSpan расхождение Base.App.run: пропущена Ann
  на последнем action в do; подтверждено прямым сравнением деревьев.
  Полный isolated owned semantic execution сохраняет parity:
  `bootstrap-parser-release237-isolated-owned-v1.json`, physical 2,481,974,416 /
  RSS 2,955,542,528 bytes. Это partial diagnostic (exit 2), не admission.
  Новый full gate исполняет каждый из всех 75 cases в отдельном Bun/Node process,
  объединяет реальные rows и аутентифицирует child reports/raw outputs.
  Streaming observer не перечитывает каждый закрытый SCon suffix ради
  неиспользуемых folded-child spans; semantic hash и literal ledger сохранены.
  Это убирает квадратичное чтение длинных embedded JS strings в JSEmit.
  Limits и native AST/oracle coverage не меняются, manual GC отсутствует.
- Cutover сохранил исходное tracked состояние в
  `refs/omp/bend237-source-backup` (`47656e63f347be3654ccea370a5f604379420124`),
  изменённые private sources — в `/tmp/bend-237-private-backup-47656e63`.
  Snapshot не включает untracked файлы; private backup не заменять stash/reset.


- Pure step bootstrap harness, соединяющий parser → Template → CheckerCore → JSEmit.
- Canonical Node/V8 orchestration с автоматическим GC, **3,072 MiB** old-generation limit, 256 MiB worker stack и lossless storage фактически проверенных тел между validation/emission.
- Внешний process-tree guardian: **8,192 MiB физической памяти и RSS, период 10 ms**; конечные deadlines.
- Compiler-private AST arena: U32 child/name IDs, flat argument/telescope tapes, исходные arbitrary Nat indexes, quantities и spans сохранены.
- Разделение source/transient arena и реализация clearing rewind в исходниках.
- Flat metadata последней арены; реальные нативные проверки роста/rollback прошли.
- Typed request handlers сохранены; bounded nonrecursive native storage islands убирают измеренный dispatch bottleneck, general computation/recursion остаются CPS.
- Полная нативная проверка **и JS-сборка** текущего compiler root: `selfhost-steps-native-canonical-v13.result.json`, 7,841 events / 7,568 определений, 30,472,921-byte artifact; RSS 4,757,766,144, physical 4,517,665,880 bytes, wall 230,457 ms, CPU 407,637.498 ms.
- Same-work v10/v11: идентичные входы и JS bytes; peak physical footprint 6,280,901,264 → 4,157,197,032 bytes. Цена — 3.81-GB временное checked storage и 309,581 вместо 55,607 ms wall; не full-build speedup. Доказательство: `selfhost-memory-same-work-canonical-v11.json`.
- 14 actual JS/C layout/signature executions: `shared-layout-backends-v110.json`; actual restored-checked-output codec execution/byte equality: `native-checked-storage-smoke-v1.json`.
- Все 64 seed-fixtures прошли в fresh bootstrap v11/v12, включая private-arena Checker и positive/negative law/type/affine cases.
- Fresh stage-one parsing v11 выявил слитное `1n++tail`, v12 — U32 numeric patterns в arena decoder. Оба source-level ограничения исправлены без изменения quantities/decoder semantics. Все 15 текущих root .bend inputs проходят actual accepted parser: `parser-root-closure-compat-v1.json` (диагностика, не bootstrap acceptance). Boundary decoder regression реально исполняется на JS/C: `arena-quantity-codec-backends-v1.json`.
- Последняя завершённая полная native-сборка — `selfhost-steps-native-canonical-v34.result.json`,
  artifact `selfhost-steps-canonical-v34.js`: 8,495 events / 8,216 definitions,
  45,804,032 bytes, SHA-256 `9b89658c930e245dec137cdbca37172478fd0cd859b51378eeb1ec2c6dee2b11`;
  guardian RSS 5,520,310,272 bytes, physical footprint 5,309,812,368 bytes,
  wall 300,078 ms; одновременно e/h максимум 1/1. Не same-work v10/v11.
- В bootstrap v18/v20 прошли все 67 seed fixtures. v18 исчерпал deadline
  на stage-one-check; v20 остановлен вручную после длительного stage-one-check.
  Отчёт v20 остаётся IN_PROGRESS, не является PASS или завершённым failure.
  Stage1/stage2 артефактов ещё нет; fixedpoint не доказан.
- В v21 arena closed certificates учитывали binder depth и arbitrary Nat
  free-variable bounds; неизвестные и смешанные регионы не получали сертификат.
  Actual JS/C regressions: `checker_arena_closed.bend`, `checker_arena_bound.bend`.
  Реальная typed-step подстановка в 1,000 вложенных binders: 2 requests,
  8.58 ms после загрузки, исходный handle сохранён
  (`substitution-bound-micro-v21.json`, diagnosticOnly; загрузка заняла 57.63 s).
- Fresh parser/source-closure diagnostic v21 завершён:
  `selfhost-root-parse-canonical-v21.json`, guardian 125,326 ms.
  Это baseline для ограниченного root checker measurement, не bootstrap acceptance.
  Не повторять 55-минутный полный gate без измеренного улучшения root checker.
- V22 сертифицирует mixed-region transient bounds при публикации по полным IDs.
  Guard сохраняет subtree при bound <= target/cut; unknown идёт прежним путём.
  Реальное typed-step исполнение: 18 assertions / 44 requests
  (`arena-typed-bound-smoke-v22.json`); fresh parser diagnostic v22 —
  121,875 ms (`selfhost-root-parse-canonical-v22.json`).
  Проверены 100 отказов array depth, затем 200,000 tail-шагов
  (`native-tail-exception-smoke-v21.json`).
- Но ограниченный root trace v22 всё ещё останавливается на `template_match_43`
  после 175,455 ms / 46,987,592 requests: существенного root speedup пока нет.
  Не запускать новый длинный bootstrap на основании microbenchmark.
- V24 exact memo использует полные source/transient IDs и Nat index/depth.
  Таблица ограничена 4,096 slots и очищается при любом rewind. Actual typed-step
  stale-key/value-ID reuse smoke: 9 assertions / 79 requests
  (`arena-transient-exact-memo-smoke-v24.json`); previous full-key/large-Nat/no-op
  rewind smoke — `arena-exact-substitution-memo-smoke-v23.json`.
  JS/C binder regression теперь печатает 10101 (Lam/All/Sub capture boundaries).
- Ограниченный full-root checker v24 прошёл прежний hotspot и за 240,005 ms
  достиг 897 definition checks / 858 stored definitions без stable-hotspot stop.
  Затем полный `selfhost-bootstrap-canonical-v24.json` прошёл все 67 seed fixtures,
  full-source parser parity и expansion, но исчерпал 3,300,000-ms deadline
  на stage-one-check. Stage1/stage2 artifacts отсутствуют; это failure, не acceptance.
- V25/v26 selective beta подставляет аргумент только в выбранную ветвь
  decisive single-Var0 BodyMatch; неизвестные формы сохраняют прежний путь.
  Реальные 137 assertions (aliases, binder captures, pattern precedence, fuel)
  прошли в `selective-beta-smoke-v25.json`. First-row normalization 1/1,000
  unrelated rows: 116/116 requests вместо прежних 236/53,183; это microbenchmark,
  не полный root. V25 source parse обнаружил bare U32 pattern; Bool helper исправил
  источник, fresh v26 parse прошёл (`selfhost-root-parse-canonical-v26.json`).
- Полный plain root checker v26 всё ещё исчерпал 900,000-ms deadline.
  Causal v26 за 234,669 ms / 66,030,387 requests достиг `template_match_239`,
  847 definition checks / 807 stored; hotspot — последовательный проход
  `whnf_beta_cases` с повторными scope/canonical-name lookups.
  Не запускать ещё один длинный bootstrap по результату first-row microbenchmark:
  сначала доказать завершение всего root checker и стоимость LAST-row selection.
- V27 source constructor-prefix index проходит 250 actual typed assertions
  (`beta-index-v27.smoke.json`): warmed FIRST/LAST/reverse-LAST среди 100/1,000
  unrelated heads — одинаковые 82 requests с новыми argument handles.
  Source alias changes и source rewind/reused ranges проверены; transient lists
  сохраняют прежний matcher. Fresh v27 parse прошёл за 111,877 ms.
- Но весь root checker v27 за 900,004 ms / 345,969,184 requests не завершён:
  2,545 definition checks / 2,505 stored, `checker_continuation_1084`.
  Causal v27 выявил другой quadratic scan: `checker_result` body checking
  повторно просматривает все предыдущие pattern rows в
  `scope_pattern_rows_subsume_named` / `scope_specialize_pattern_rows_named`.
  Следующая работа — локальные индексы raw constructor heads для usefulness
  и полной matrix exhaustiveness, без отключения проверок. Новый длинный
  bootstrap до завершения всего root checker не запускать.
- V28 indexed usefulness/exhaustiveness проходит 1,225 actual assertions
  (`coverage-index-live-v28-smoke.json`): full matrix check 100/1,000 unique
  constructors — 56,146/561,946 requests, линейно; invalid useful branch,
  arity и nonexhaustive cases по-прежнему отвергаются.
- Но whole-root v28 не завершён за 900,002 ms / 285,397,035 requests.
  Точная диагностика `selfhost-checker-index-paths-canonical-v28.json` обнаружила
  источник промаха: реальные reversed TRANSIENT 188-row dispatch tables
  возвращали `CasePrefixEmpty` из source-only eligibility.
- V29b строит ephemeral prefix index для transient tables с проверкой реальных
  owners; persistent transient cache не добавлен. Names остаются source-interned.
  Actual `transient-case-live-v29c.json`: 34 eager-parity cases, 30 probes,
  2 release/rewind ID-reuse cases PASS; FIRST/LAST 100/1,000 unrelated heads
  385/3,085 requests и по одному whnf_pattern/equal_names. Это линейное построение
  каждый раз, не constant warm cache. Affine native arenas в reference branches
  независимы; shared-store начальный driver давал некорректный eager reference.
  Temporary fixtures удалены после исполнения.
  Проверка всего root v29b не завершена: 900,003 ms / 254,044,530 requests,
  2,405 checked definitions (`selfhost-checker-complete-canonical-v29b.json`).
- Late causal v29b обнаружил 179,150 одинаковых полных source ranges среди
  189,983 constructor comparisons. V30 повторно использует положительный bit-16
  witness только для проверенных source constructor trees; рекурсия остаётся typed
  CPS, native helpers bounded. Unsupported terms сохраняют исходный comparator.
  Actual `ctor-reflexivity-live-v30j-smoke.json`: 53 parity/safety/lifecycle cases,
  9 depth/range profiles, 72 warm repetitions PASS. Source Succ depth 1/31/1,000:
  cold 26/356/11,015 requests, warm всегда 13; это не whole-root acceptance.
  Fresh native v30 завершён; fresh parse, полный check и настоящий bootstrap
  stage1/stage2 остаются обязательными. Ни одного stage artifact пока нет.
- V30 whole check остаётся unfinished: 900,124 ms / 211,159,921 requests,
  2,277 завершённых definition checks. Точный per-definition journal обнаружил
  повторные scope segment/index scans, а не новую проблему ctor witness.
- V31 хранит persistent lookup snapshot в ArenaVisibleScope; family-first и
  per-kind precedence сохранены, aliases/candidates/unsafe остаются segment-based.
  Actual `visible-lookup-live-v31d-smoke.json`: 63 full-field parity queries,
  6 update transitions PASS; 192 warm queries стоят всегда 416 requests при
  1/10/100/1,000 segments. Cold 4/43/403/4,003. Temporary fixtures удалены.
  Полный native root v31 PASS; реальный `selfhost-bootstrap-canonical-v31.json`
  не завершён: deadline 3,300,019 ms, все 67 seed fixtures PASS, полный parse и
  expansion PASS; stage-one-check начался на 668,987 ms и не вернулся.
  RSS 5,766,316,032 / physical 4,288,504,360 bytes. Артефакты `{}`: ни stage1,
  ни stage2, ни fixedpoint. Следующий запуск требует данных о текущем definition,
  не повторного слепого 55-minute gate; profiler v31 получает только эти данные.
- V32 actual worker CPU profile (`selfhost-checker-worker-cpu-canonical-v31.json.Checker.cpuprofile`)
  обнаружил 2,496-arm linear tagged dispatcher: wrapper + dispatch занимают
  47% self CPU. Native JS emitter переведён на tagged switch; четыре существующих
  runtime fixtures PASS. Fresh native root v32 PASS: 8,166 definitions,
  45,765,245 bytes, physical 4,120,423,024 bytes; это другой input, не memory A/B.
  Full actual native/selfhost consumer smoke теперь PASS:
  `tagged-dispatch-live-v32h-smoke.json`, 148 observable rows, неизменённые artifacts.
  Помимо wide enum проверены nested/captured matches, aliases, erased offsets/
  callbacks и exception identity. Checker default erased binder остаётся QZero;
  emitter использует constructor telescope quantities для packed offsets.
  Eager representation-choice recursion и повторение string-tail expression
  устранены после реального RangeError. Literal dispatch варианты дали native
  OOM и заменены Boolean helpers без увеличения heap cap. Native regression
  `tests/reg/match_erased_default_binding.bend` реально печатает `48`.
  Fresh полный `selfhost-bootstrap-canonical-v33.json` завершился deadline FAIL
  на 3,300,012 ms: все 69 seed fixtures PASS, полный parse/expand PASS;
  stage-one-check начался на 305,378 ms и не вернулся. Physical 4,769,064,656 /
  RSS 6,467,092,480 bytes. Артефакты `{}`; stage1/stage2 byte fixedpoint нет.
  Counter на тех же frozen v33 inputs измеряет оставшийся whole-root bottleneck;
  ни 148-row consumer smoke, ни исправленные 69 fixtures не заменяют fixedpoint.
- V34 late causal измерение v33 выявило повторное индексирование одной reverse
  transient таблицы из 958 cases. Cache теперь использует существующие 64 slots
  transient Arena до declaration rewind. Source generation в depths[6] защищает
  mixed-owner entries от source rewind/ID reuse; immutable publication остаётся
  обязательным. В tagged IDs bit 31 = transient, bit 30 = reverse.
  Actual `transient-prefix-cache-live-v34e.json`: 180 native probes PASS;
  cold 64/100/1,000 rows = 199/307/3,007 requests, warm всегда 6.
  Проверены source/transient rewind/reuse и forward/reverse mixed owners.
  `checker_arena_generation.bend` JS/C печатает 7; affected bound/closed/quantity
  regressions JS/C сохраняют 10101/1001/2102210.
  Fresh полный `selfhost-bootstrap-canonical-v34.json` запущен с finite
  10,800,000 ms acceptance deadline и прежними 8 GiB memory/RSS guards.
  Увеличенный deadline не является speedup. Stage1/stage2 byte fixedpoint
  ещё не доказан; не останавливаться на cache smoke.
  V34 full gate остановился через 969,892 ms на worker heap OOM, до finite
  deadline и до 8 GiB physical guard: peak physical 5,223,975,240 /
  RSS 5,577,179,136 bytes. Все 69 fixtures, root parse/expand PASS;
  stage-one-check начался на 257,894 ms, artifacts `{}`.
  V34b перенёс parser/checked inputs в реальные native start requests и освободил
  obsolete host roots, но полный запуск тоже FAIL: 3,015,315 ms,
  physical 5,524,695,744 / RSS 4,669,571,072 bytes, artifacts `{}`.
  Это lifetime correction, не доказанное завершение stage-one-check.

НЕ доказано:

- Stage-one/stage-two byte fixedpoint текущего compiler root. Ни native byte equality, ни полный source parse, ни seed fixtures не заменяют этого доказательства.
- Product-wide selfhost green, C/Metal/CUDA/legacy IO acceptance.

Не откатывать уже работающий private arena cutover вслепую. Сначала устранить измеренный bottleneck генерации.

## 3. Исторический полный прогон до архитектурного исправления: v106

Доказательства:

- `checkpoints/selfhost-steps-native-v106.result.json`
- `checkpoints/selfhost-steps-native-v106.guardian.json`
- `checkpoints/selfhost-steps-native-v106.progress.json`
- `checkpoints/selfhost-steps-native-v106.events.jsonl`
- `checkpoints/selfhost-steps-native-v106.validation-timings.json`
- `checkpoints/selfhost-steps-native-v106.provenance.json`
- `checkpoints/selfhost-steps-native-v106.inputs.json`

Нативная проверка: **7,774 / 7,774 events**, 9,347.638542 ms wall / 18,103.32 ms CPU, manualGC=false. Начальное количество checked definition slots: 7,501.

Затем codegen упал с `ERR_WORKER_OUT_OF_MEMORY`; guardian recorded command exit, а не превышение внешнего 8-GiB cap. Полного `checkpoints/selfhost-steps-v106.js` нет.

| Полный root codegen | v99, nominal result | v106, flat metadata |
| --- | ---: | ---: |
| Old-generation limit, MiB | 6,144 | 6,144 |
| Guardian wall time, ms | 27,843 | 27,083 |
| Peak process-tree RSS, bytes | 6,776,553,472 | 6,771,359,744 |
| Peak physical footprint, bytes | 7,138,657,248 | 7,095,842,088 |
| Prepared definitions at last event | 435 | 782 |
| Completed releases | 14 | 14 |
| Retained higher-body slots | 421 | 768 |

Последний v106 prepare: `checker_core_steps_v1.checker_body_arena_set_word_region`, index=781, eLive=6,719, hLive=768, heapUsed=6,416,166,888; memo counts: opens=5,992, spines=15,372, teles=239,652, sigs=781, probes=12,514.

782 вместо 435 — продвижение до того же heap limit, **не завершённая сборка и не same-work speedup**.

## 4. Измеренный источник новых аллокаций

Основной профиль: `checkpoints/selfhost-allocation-v100.allocation-profile.json`; результат/guardian — `checkpoints/selfhost-allocation-v100.result.json` и `.guardian.json`.

Profiler запускается **после полной нативной проверки**, только на codegen. Sampling interval=524,288 bytes. При heap cutoff=4,608 MiB существующий accepted probe останавливает эмиссию исключением наблюдателя. Результат — `ALLOCATION_PROFILE_ONLY`, `artifactGenerated=false`, не compiler acceptance. Полный heap snapshot и ручной GC не использовались.

v100: 17,061 ms; peak footprint=5,433,925,032 bytes; 247 preparations / 14 releases. Sampled live bytes=380,074,624:

| Site | Sampled live bytes |
| --- | ---: |
| `lay_fields` | 158,349,304 |
| `lay_pack` | 128,479,104 |
| Callback constructing constructor arms inside `lay_of` | 64,496,760 |
| Other sites | 28,749,456 |

Эти три layout sites дают **около 92.4% новых sampled live allocations на codegen**. Это НЕ доля всей памяти процесса: allocations предыдущих фаз не профилированы. `heapUsed` до codegen также не является точным размером retained AST — включает ещё не собранный мусор.

Крупнейший sampled stack достигает layout builders через `sig_def`. В принятой копии компилятора `Sig = { live, lays, ret }`, `sig_def` хранит `lays` и `ret` в `SIGS`. `lay_of` рекурсивно строит layout нециклического ADT; `Array` и `IO.OP` получают BOX. `memo_gc` в этой копии очищает OPENS/USES/FOLDS/SPINES/CONSTS, но не TELES/SIGS/PROBES. Проверить актуальные места сброса и потребителей перед изменением; не выводить exact retained-owner sizes только из allocation stacks.

После flat metadata: `checkpoints/selfhost-allocation-v105.allocation-profile.json`, тот же cutoff/interval/guardian. 12,665 ms, peak footprint=5,451,014,360 bytes, 294 preparations / 14 releases. Стоп произошёл на другом объёме работы; wall-time ratio не считать speedup.

## 5. Исходный архитектурный план — A/B теперь выполнены

### A. Переиспользовать неизменяемые layout'ы

Исследовать `Lay`, `Field`, `Arm`, `lay_of`, `lay_fields`, `lay_pack`, `lay_cyclic`, `ctr_doms`, `sig_def`, `SIGS` в `bend2/comp.ts`. В historical accepted copy это примерно строки 944–1001 и 1130–1154, но canonical offsets могут отличаться.

- Один граф layout'а на конкретное семантическое instantiation типа; signatures ссылаются на него вместо копирования arms/fields/ks.
- Не ключевать только по имени ADT: параметры, quantities, зависимости, cyclic/boxed cases и область действия важны.
- Сначала доказать допустимость sharing: `lay_pack` мутирует parent field offsets (`f.at += tag`). Не разделять между родителями изменяемые Field records и проверить остальных consumers.
- Cache/interning должен быть compile/book-local с явным жизненным циклом; никаких stale layouts между разными books/stages. Не подменять этим результаты typechecking/normalization.
- Не вводить лишнюю сериализацию/копирование ради cache key; выбрать ключ после чтения существующего type representation.
- Проверить C и JS consumers layout'ов; canonical `comp.ts` — общий compiler/runtime source, не JS-only fork.

### B. Отделить signature metadata от подготовки тела

В historical accepted compiler `sig_def` начинал с `def_body(cb, k)`; текущий canonical compiler отделяет declaration metadata от on-demand body preparation.

- Найти, какие сведения для ABI действительно требуют body preparation, а какие доступны из полностью нативно проверенной декларации.
- Не считать замену на raw declaration lookup автоматически корректной: зависимые типы, promoted binders, erasure, quantities, foreign calls и borrowing требуют проверки.
- Сделать запрос сигнатуры по возможности не вызывающим eager body preparation.
- Готовить body непосредственно для emission и освобождать данные после последнего реального потребителя; не удалять поля нужного AST и не заменять checked `e` непроверенным `v`.
- Для cycles/SCC выбрать корректный bounded plan; порядок деклараций сам по себе не является доказанным исправлением.

### C. Request protocol — если A/B недостаточно

`checkpoints/checker_core_steps_v1.bend` содержит большой `CheckerRequest` sum и `CheckerProgress<A>` с `CheckerPending{request, resume}`. Множество helper signatures возвращает этот progress. Повторяемое разворачивание такого layout'а — кандидат; конкретные размеры каждого типа пока не измерены.

При актуальном разрешении можно исследовать компактный boxed/handle payload или frames. Это отдельная архитектурная работа с доказательством resume/result dependent types, quantities, evaluation order и ABI. Не выдавать существующие closures за уже выполненный frame cutover.

**A/B выполнены; детали и completed same-work evidence — в последних sections `checker-core-integration.md`.** Непроверенные product-wide acceptance остаются отдельной задачей.

## 6. Историческая ловушка cached compiler — clean cutover выполнен

v106 импортировал `~/.cache/bend/accepted-native-d746e7cc/bend2/.comp_js_stream_probe.ts`.
Текущий `evals/checker_core_component_build.ts` выполняет authenticated canonical
`bend2/comp.ts` и exact-inverse lifetime seam над `bend2/bend.ts`. Историческая
копия `checkpoints/js-storage-stream-compiler.ts` — только baseline, не executor.
Schema-three proof pins фактически исполненные compiler/kernel/storage-producer
bytes, полный input closure и lossless actual checked graphs с original native
closures. Source `v` никогда не используется вместо checked `e`. Новые artifacts
и reports создаются под новыми именами; старые pins/results не перезаписываются.

`checkpoints/js-storage-stream-build.ts` — **исторический, НЕ текущий runner/producer**: содержит Bun FFI, `/tmp` dependencies, manual GC и ссылки на отсутствующие старые sibling helpers. Не запускать его как новый путь acceptance. Современный host — `evals/checker_core_component_build.ts`.

## 7. Текущие source identities и cache

SHA-256, измеренные при подготовке handoff:

```text
0939b98d013ab58d82619e35c0d4900b72c9d8e5b478f0e1df7822fe713c9b48  bend2/comp.ts
47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9  bend2/bend.ts
279d837edbf2e13bddca0604eb864eb0ee832d1cec40e16df1ded71281c122e8  bend2/selfhost/checker_arena.bend
28193812d643cd5e626952fb445b69dfbcad19680b9f608ea46d73d2fc612bf2  evals/checker_core_component_build.ts
3d8c4e2a14f1f5e7f1833b8c7492c640481a31dd03544bff7378b360a56d19ae  checkpoints/js-storage-stream-compiler.ts
0ada35959c5a4542096e0becd64230995807779899e3285c48fdddbfb712ee8d  checkpoints/selfhost_steps_driver_v1.bend
```

Snapshot `/tmp/bend-artifact-d746e7cc` дважды потерял необходимые файлы. Современный host теперь использует persistent user cache выше. Там восстановлены шесть оригинальных pinned files: stream compiler, bend.ts, comp.ts, base.bend, historical heavy_gate.ts, historical heavy_gate_native.c. Проверки новых v104–v106 реально использовали persistent path.

Ключевые historical pins дополнительно:

- Base: `e149828ca05581f61d1b06cf2a7d1a744e394d29a4c8e1942e5062ecbf30f5b8`.
- Historical guardian TS: `db386e3d8d92409fd29ac0483e9c2a8b985a16ee459091336954e000e9ccfe94`.
- Historical guardian C: `32a823b59ff5fa6d129b01aa32ff2e5be735309c6f8b59f3e239c94562c531b1`.
- Active guardian TS: `47a12205abd374fd69d7dac30ee9fb45d7203cad2790870511387cd2efc22251`.
- Active guardian C: `f5aecf8308caebc72dccf8986733b37137d448021ee378302cfcd038381b7aa9`.

Если cache отсутствует, восстанавливать bytes по pins, а не менять ожидания на случайный текущий файл. Original guardian TS есть в Git object `d746e7cc:evals/heavy_gate.ts`; original C не был в этом commit. Его точные source lines ранее восстановлены из записанных чтений в истории и verified по SHA. Не утверждать, что весь snapshot восстанавливается одной `git archive`. Прочие legacy runners ещё могут ссылаться на `/tmp`; перенос современного host не мигрировал все исторические scripts.

## 8. Карта исходников и существующих изменений

- `bend2/comp.ts`: canonical compiler, текущий основной объект следующего исправления.
- `bend2/bend.ts`: canonical parser/theory/checker. Сейчас исходный kernel restored; rejected A1 не установлен.
- `bend2/selfhost/checker_arena.bend`: lossless descriptors, six data arrays, flat metadata, names map, growth/clear/rewind.
- `bend2/selfhost/checker_ir.bend`: word/name/Nat/quantity range and reverse-range views, OptionalTerm IDs, private declarations.
- `bend2/selfhost/checker.bend`: private ArenaStore (source/transient), nominal ArenaResult<T>, ID-based Core/Checker, local pack/decode, private lookup, promotion/publication, transient rewind. Parser-facing `check_modules` / CheckResult original AST ABI preserved in source. Full actual Checker semantic proof pending new artifact.
- `bend2/selfhost/scope_lookup.bend`: original public globals plus private ID-based arena global/scope descriptors.
- `bend2/selfhost/core.bend`: retained zero-shift reuse optimization.
- `bend2/selfhost/js_emit.bend`: earlier ordered spine traversal, erasure/name/owner lookup optimizations; do not overwrite them as cleanup.
- `evals/checker_core_owned_source.ts`, `evals/checker_core_step_lower.ts`: source ownership and step generation.
- `evals/checker_core_step_runtime.mjs`: host LIFO continuation driver; not a substitute checker or emitter.
- `evals/selfhost_driver_source.ts`: exact accepted parser declarations in root namespace plus compiler ABI wrappers. Root-scope parser embedding matters: importing it under a different namespace previously changed promoted-binder resolution.
- `evals/selfhost_bootstrap_gate.ts`, `evals/selfhost_bootstrap_worker.mjs`: real pure-step acceptance.
- `evals/bootstrap_ast_transport.ts`: typed-array oracle transport, complete fields and interning; no intermediate materialize API.
- `evals/selfhost_parser_parity.ts`, `evals/parser_full_semantic_normalize.ts`, `evals/bootstrap_source_oracle.ts`: complete native semantic parity and isolated oracle workers.
- `evals/heavy_gate.ts`, `evals/heavy_gate_native.c`: external guardian; do not lose aggregate footprint accounting, locks, descendant cleanup or deadlines.
- `evals/validation_profile.ts`: observed full native validation timings.

Do not confuse private arena descriptors with parser/root input AST: representation cutover stays behind existing entry/exit boundaries. Do not feed host AST as compiler inputs or patch emitted JS.

Flat metadata specifics: pool order nodes/patterns/binders/words/naturals/names; `counts[2*p]`=used, `[2*p+1]`=capacity; `depths[p]`=Array allocation depth. Rewind clears appended entries and preserves capacity/depth. Arbitrary Nat values above 32 bits must be **constructed**, not expressed as unsupported parser literals above `4294967295n`.

## 9. Что уже проверено отдельно

- v104: complete native boundary fixture 701 events / 540 checked definitions; JS=115,312 bytes, SHA `3ad72d390ecbd5a12b5942d93dcc90c30d87bc6d6c89455292eb2e6064f9b370`. Emitted execution: 17 assertions, 68 ms, 10-second deadline. Evidence: `checkpoints/arena-metadata-native-v104-execution.json` and `checkpoints/arena-metadata-native-v104-build.result.json`. Throwaway Bend fixture and JS assertion script removed after proof; do not try to launch their deleted paths.
- Regeneration after flat metadata: 786 source defs, 3,346 calls, 3,063 pending sites, no lazy choices, 4,537 total bodies/helpers. Owned source 1,985 ms; step lowering 140,855 ms. Generator logic unchanged.
- v101 ordinary non-profiling host build: `tests/base/u32_divmod_zero.bend`, output export `main.out`; build 470 ms, real exported **thunk call** returned `6n`. JS hash `ba821dbe0f98ee4b05e92566c6337eca18102d7e588ac84b1f272e119ffbe2d1`, equal to v86. `generated['main.out']` is a function, not the result.
- Older storage v92/v93 separately exercised growth, arbitrary Nat and clearing name-map rollback. These are not proof of current complete Checker semantics.

## 10. Не повторять отвергнутые эксперименты / не завышать evidence

- Nominal ArenaStore/result product реализован; v99 full native checking passed, codegen still OOM. Он не доказал сокращения пика memory. Не повторять этот эксперимент как новое открытие.
- Rejected A1: `checkpoints/stage0-a1-result.json`, status `A1_INSUFFICIENT_STOPPED`. Historical body_sub occurrence/COW candidate reduced node count but diagnostic ~90.9 ms → ~1580.6 ms; canonical kernel restored. `evals/stage0_a1_replay.ts` retains experiment only. Не ставить rejected kernel обратно.
- Old `checkpoints/selfhost-steps-v78.js` is a diagnostic seed, NOT current private-arena root. Historical build used 288 explicit GC calls; its build numbers do not prove automatic-GC success.
- Older path emission produced 325,161 bytes with SHA `dfde577896e6d15f0c793639ab1a4134e7aed30441f914781ec5e2c263e84835`; useful historical evidence only, not current golden without matching authenticated sources.
- v84 fresh parsing/parity diagnostic passed but did not check/emit/bootstrap. v85 acceptance was cancelled, not passed. No current complete stage1/stage2 artifact exists.
- A compile attempt returning OOM is FAIL, even if complete native validation passed. `ALLOCATION_PROFILE_ONLY` is diagnostic success only.
- Do not re-run known OOM merely to confirm it; instrument or change a measured cause first.

## 11. Commands and safe execution contract

Все commands запускаются из repository root через **Bash**, не Eval/codemode. Eval допустим для короткого анализа JSON/данных, не для acceptance. Один heavy child за раз; freeze actual source inputs на весь прогон. Outer Bash timeout плюс finite inner guardian deadline. Fresh artifact/report namespaces: существующие результаты не перезаписываются, даже после ранней неудачи.

### Unchanged source regeneration, если менялся Checker/generator input

Outer Bash timeout 1,230 s:

```bash
node --experimental-strip-types evals/heavy_gate.ts --memory-mib=8192 --rss-mib=8192 --poll-ms=10 --timeout-ms=300000 -- bun --smol evals/checker_core_owned_source.ts &&
node --experimental-strip-types evals/heavy_gate.ts --memory-mib=8192 --rss-mib=8192 --poll-ms=10 --timeout-ms=900000 -- bun --smol evals/checker_core_step_lower.ts
```

Если нужно пересобрать root composition, `evals/selfhost_driver_source.ts` читает accepted parser proof и записывает root/manifest. Запускать под тем же external guardian с разумным finite deadline; не ломать exact parser declaration embedding.

### Codegen allocation diagnostic

Optional diagnostic, не acceptance. Heap cutoff не должен превышать текущие `3072 - 1024` MiB. Outer Bash timeout 150 s:

```bash
HEAVY_GATE_TIMEOUT_MS=120000 bun --smol evals/checker_core_component_build.ts --file=checkpoints/selfhost_steps_driver_v1.bend --exports=parsed_module,parse_with_fuel,expand_modules_start,template_step,check_expanded_start,checker_step,emit_modules_start,emit_library_start,emitter_step --artifact=checkpoints/selfhost-allocation-canonical-v15-unused.js --report=checkpoints/selfhost-allocation-canonical-v15 --allocation-profile-mib=2048
```

`canonical-v15` здесь лишь proposed namespace; проверить, что он свободен. Artifact намеренно не создаётся. Для same-work acceptance использовать законченные сравнения, не cutoff ratios.

### Full native component build

Outer Bash timeout 960 s, inner deadline 900,000 ms:

```bash
HEAVY_GATE_TIMEOUT_MS=900000 bun --smol evals/checker_core_component_build.ts --file=checkpoints/selfhost_steps_driver_v1.bend --exports=parsed_module,parse_with_fuel,expand_modules_start,template_step,check_expanded_start,checker_step,emit_modules_start,emit_library_start,emitter_step --artifact=checkpoints/selfhost-steps-canonical-v13.js --report=checkpoints/selfhost-steps-native-canonical-v13
```

Это фактически завершённая v13 command, а не свободный output namespace: для повторения выбрать новое имя, не перезаписывать evidence. Нет profiling option; `JS_GENERATED_NOT_YET_EXECUTED` не означает bootstrap.

### Semantic fixture после успешной component build

Outer Bash timeout 180 s, inner deadline 120,000 ms:

```bash
HEAVY_GATE_TIMEOUT_MS=120000 bun --smol evals/selfhost_bootstrap_gate.ts --component=checkpoints/selfhost-steps-canonical-v13.js --component-build=checkpoints/selfhost-steps-native-canonical-v13.result.json --root=checkpoints/selfhost_steps_driver_v1.bend --fixture=law-completion-binding --report=checkpoints/selfhost-law-canonical-v15.json
```

Verified cases включают `law-completion-binding` (`WNil{}`), `type-specialization` (`BitOne{}`), `specialized-type-error` и `affine-duplicate` (должны быть отвергнуты), `same-module-alias-constructor-rows`, `neutral-family-distinct-branches`. Все 64 seed cases уже исполнялись в full v11/v12/v13; fixture diagnostic не заменяет full gate.

### Final fresh full bootstrap

Outer Bash timeout 3,600 s, inner deadline 3,300,000 ms:

```bash
HEAVY_GATE_TIMEOUT_MS=3300000 bun --smol evals/selfhost_bootstrap_gate.ts --component=checkpoints/selfhost-steps-canonical-v13.js --component-build=checkpoints/selfhost-steps-native-canonical-v13.result.json --root=checkpoints/selfhost_steps_driver_v1.bend --root-manifest=checkpoints/selfhost-steps-driver-source-v1.json --report=checkpoints/selfhost-bootstrap-canonical-v14.json
```

Эта команда запущена как fresh v14 после исправления host input-closure accounting: original parsed `DefImports.paths`, а не только `Module.imports`, должны аутентифицировать foreign JS bytes. Native component inputs не менялись; native v13 proof остаётся валиден. Для следующего запуска выбрать новый report namespace.

Default accepted parser proof is separate:

- `checkpoints/bootstrap-parser-rebuild-compat-three-list-linear-v1.js`
- `checkpoints/bootstrap-parser-rebuild-compat-three-list-linear-v1.result.json`
- `checkpoints/bootstrap-parser-rebuild-compat-three-list-linear-v1.build.guardian.json`
- Source `bend2/selfhost/.bootstrap_parser_rebuild_compat-three-list-linear-v1_generated_fuel.bend`, SHA `3f548a6f73acac8f4f089819f2bc522eddd2358b2b62be536260c8d8260447bb`.
- Parser JS SHA `7f86f11dbd3c56c35003ee1eba61adff827b976382d5117bcc9e718d1d5aa37d`.

Если parser меняется, пересобрать его proof/root embedding coherently; старые artifacts/pins не подменять. Gate hashes source candidate, component, manifests, code and guardians. Host parser используется только как complete semantic oracle, не как compiler inputs.

Full bootstrap всегда fresh: fixture diagnostic cache допустим только в его явно ограниченном diagnostic mode, не для этапов полного bootstrap. `--parse-only=true` даёт лишь fresh parse/parity diagnostic, НЕ acceptance.

### CPU/request profiling

`evals/.checker_profile_gate.ts` drives `evals/.checker_cpu_profile.mjs` under 8-GiB guardian. Arguments: component, native proof, report, seconds, input root, mode, optional authenticated baseline. Modes include plain/causal/counter/emitter.

**Ловушка:** default baseline is historical `checkpoints/selfhost-full-bootstrap-v16.json`; profiler requires exact source hashes and parser-authenticated native transports from its parseRows. Changed sources can legitimately fail authentication. Generate a fresh appropriate baseline or use a genuinely matching one; don't bypass it or feed host AST. Inspect current interface before launching. These profiles are diagnostic only and cannot replace final fresh bootstrap.

## 12. Что считать Done

1. Изменённый фактически исполняемый compiler собирает полный текущий root under unchanged guardian and finite deadlines; report records full native validation, correct new compiler/source identities, zero skipped checks and zero output patches.
2. Same-work A/B evidence demonstrates reduced layout allocations/retained memory, not just a later cutoff. Peak memory and wall/CPU recorded for a completed build.
3. New component actually executes positive/negative Template/Checker/JSEmit fixtures with original AST semantics and quantities, including arena-backed Checker.
4. Full fresh root parser imports every current source; complete semantic oracle parity covers all fields, not hashes of a projection.
5. Stage one is emitted by Bend JSEmit, actually executed; its own parser/checker/emitter emit stage two from identical Bend sources.
6. Stage1 JS bytes equal stage2 JS bytes, hashes persisted; stage2 semantic fixtures execute with expected successes/failures.
7. Report `PURE_STEP_BOOTSTRAP_FIXEDPOINT` / `compilerBootstrapGreen` only if actual complete gate passes. Existing gate deliberately leaves broader `selfhostGreen=false`; do not relabel it product-wide success.
8. Update existing changelog/evidence, remove throwaway scaffolds, migrate callers/provenance coherently. No hidden host checker/emitter, patched emitted JS, fake fallback, manual GC or unchecked emission.

## 13. Первые действия нового агента

1. Прочитать актуальный `AGENTS.md`, этот файл и последние canonical sections `checker-core-integration.md`; A/B и cutover не начинать заново.
2. После любых source changes выполнить обычную authenticated regeneration, затем fresh native component build (полный root, девять экспортов, unchanged 8-GiB guardian).
3. Исполнить полный `selfhost_bootstrap_gate.ts` с fresh source/AST oracle parity, stage1 execution, stage2 emission, byte comparison и stage2 fixtures. Актуальный root — `checkpoints/.bootstrap_compiler_root_v1.bend`; reports используют свежий `release237-vN`, а не исторический canonical-v13. Не переиспользовать admission после изменения любого pinned producer/input.
4. Исправлять реальные source/compiler причины, найденные полным gate, и повторять fresh authenticated proof. Не останавливаться на диагностическом parse/profiling/fixture pass.
5. Только после actual fixedpoint обновить статус и evidence; broader `selfhostGreen=false` не переименовывать в product-wide success.

Основная подробная история: `checkpoints/checker-core-integration.md`. Изменения перечислены в `CHANGELOG.md`. Этот handoff — стартовая карта, не утверждение, что self-hosting уже завершён.

## 14. Проверка самого handoff

При подготовке проверены существование основных source/runtime/parser/evidence
paths, соответствие шести SHA-256 записей фактически измеренным исходникам и
полный ABI из девяти экспортов обеих native-build commands. Числа v106
сверены с сохранёнными результатами: full native validation PASS, codegen FAIL.
Доля layout sites пересчитана из v100 profile: 92.435839% sampled live bytes.
Интерфейсы bootstrap и CPU diagnostics прочитаны из текущих runners.
Новые heavy runs ради написания документа не запускались.
