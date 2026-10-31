# N12: исправлен startup RAM default канонического конструктора

**Исправление применено и проверено обычной полной сборкой.**
В `evals/native_compiler_experiment.ts` ordinary Bun build получает
`BUN_JSC_forceRAMSize=4294967296`, только если caller не задал переменную.
Значение устанавливается **до** запуска guardian/build/codegen child, а не
после инициализации JSC. Explicit overrides сохраняются; Node sampling policy
и native run mode не меняются. Это GC heuristic, не новый memory quota.

Исходный guard сохранён: RSS **и** physical footprint 8 192 MiB, poll 10 ms,
whole-build deadline 600 000 ms. Manual GC, parser fuel, quantum, ABI и
compiler algorithms не менялись. Production `bend2/comp.ts` остаётся исходным,
без диагностических seams N11.

## Почему именно это исправление

[N11](SELFHOST_CONSTRUCTION_N11.md), checkpoint **`56dcb468`**, зафиксирован
до изменения launcher. В controlled matrix оба исходника — R12 и G39 — без
hint превышают прежний guard внутри второго прохода. С accepted-control hint
оба завершают все четыре прохода и финальную сборку C. Launcher ничего не
терял при передаче environment: он просто не имел воспроизводимого default.

Это operational fix воспроизведённой зависимости от startup policy, не повод
переписывать contextual FIR/BIR. Historical G36–G39 environments остаются
UNKNOWN, а сами версии — rejected; их старые отказы не переименованы в passes.

## Что действительно исполнено после исправления

Caller hint **явно удалён** через `env -u`. Ordinary canonical constructor,
без profiler/trace/measurement-only compiler copy, выполнил полный build:
исходные 12 456 definitions / 13 050 events, C construction, затем тот же
explicit LLVM-split O1 backend, что у accepted R12. Это не заявление об
официальных default O3 flags и не timing benchmark.

Свежий native executable затем сам прочитал весь frozen corpus и выполнил
parse → expand → check → library JS emit: 18 source modules, 35 externals,
18 eager-fuel rows по 8M cells, quantum64 и все 13 public exports.

| Исполненный run | Guardian wall, ms | Peak RSS, bytes | Peak footprint, bytes |
| --- | ---: | ---: | ---: |
| Полный C/LLVM/native build с unset caller hint | 297 044 | 4 924 751 872 | 5 311 699 016 |
| Свежий native compiler: полный source corpus → JS | 90 754 | 1 766 637 568 | 1 759 201 800 |

Оба guardian PASS и подтверждённый owned-tree shutdown. Новый codegen child
реально записал hint `4294967296`, Bun 1.4.3, empty `execArgv`, automatic GC,
no profiling. Source-only ожидание не подменяет эти runtime observations.

**Все три артефакта байт-в-байт совпадают с accepted R12:**

| Артефакт | Bytes | SHA-256 |
| --- | ---: | --- |
| C translation unit | 62 113 627 | `2290a096f114201665d4b943db3470889ca700ec205b875612178ea263e27ffb` |
| Native executable | 18 808 824 | `b3459184f37d3159f44e9b7f67642ad6c3850dc806ae5f7837f348fc842b3f71` |
| Native-produced compiler JS | 31 758 507 | `85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e` |

Verifier действительно вернул
`PASS_CANONICAL_UNSET_CALLER_BUILD_AND_NATIVE_COMPILER_CONSUMER`.
Он проверяет fresh source pins, guards, entire C/native/JS hashes, source
coverage, ABI/fuel/quantum и неизменность 21 baseline source checks,
трёх generated hashes и обоих accepted artifacts.

## Точные команды и authority

```sh
BUN=/Users/ilyagulya/bend-g12-borrow-7782b78a-1e88-4ffd-9889-14cb52c6a5b9/.tools/bun
W=/private/tmp/bend-n12-launcher-J3JWO7
/usr/bin/env -u BUN_JSC_forceRAMSize "$BUN" --smol evals/native_compiler_experiment.ts --mode=build --corpus=checkpoints/local2039g24r12/root.native.corpus.json --artifact="$W/native" --report="$W/build.json" --cc-pipeline=llvm-split --cc-opt=1 --llvm-bin=/opt/homebrew/opt/llvm@21/bin
/usr/bin/env -u BUN_JSC_forceRAMSize "$BUN" --smol evals/native_compiler_experiment.ts --mode=run --corpus=checkpoints/local2039g24r12/root.native.corpus.json --build="$W/build.json" --report="$W/native-consume.json" --phase=compile --threads=1
/Library/Frameworks/Python.framework/Versions/3.12/bin/python3 "$W/verify.py" /Users/ilyagulya/Projects/My/bend "$W" "$W/verified.json"
```

В ledger сохранены literal absolute argv, actual runtime/limits, backend
commands, parsed timings/memory, tool facts, source authorities и все output
hashes. Bulk backend stdout/stderr заменены hash/length references, а raw build
report сохранён вне Git. Generated C, executable, JS images и raw logs не
добавлены в Git.

Native-build receipts хешируют и launcher source. Поэтому для нового запуска
создана **fresh build authority** с новым launcher hash. Старые source-bound
receipts не переписаны и их validation не ослаблена; они остаются привязанными
к своему исходному checkout. Новый native при этом имеет прежние accepted
bytes. Required new protocol/verifier sources сохранены в
`checkpoints/n12-source-inputs/`.

Это не новый алгоритмический speedup, не fresh stage1→stage2 fixedpoint и не
новая 12-pair performance qualification. Explicit overrides и Node profiling
сохранены узким условием в source, но отдельной runtime matrix здесь не
перепроверялись. Accepted compiler остаётся **G24R12**; изменился только
воспроизводимый запуск его native constructor.

Полный compact receipt:
[`construction_n12_launcher_fixed.json`](../evals/receipts/construction_n12_launcher_fixed.json).
