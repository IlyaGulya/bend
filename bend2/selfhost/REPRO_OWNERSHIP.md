# REPRO_OWNERSHIP: minimal retained-ownership witness

Status: **measured on the accepted historical `5205478f` image** (diagnostic
only, not acceptance): both reduced valid-affine shapes emit, compile and run,
and both trip the unchanged retained-frontier bound. The fresh `9941352b` C
path still stops before clang at a common emit failure (`BIR continuation
reads a value that is not in scope`) that also hits a plain matrix fixture, so
no fresh-image behaviour is claimed. Every claim is labelled **[OBSERVED]** (a
saved artifact, receipt, measured log or source line) or **[INFERENCE]**
(derived, not executed). The historical failure is preserved unchanged.

## 1. The invariant in the foreign fixture is a frontier bound, not live bytes

The foreign C of `tests/run/list_rebox_sum.bend` (`heap.check`) reads the
runtime arena frontier and compares two readings:

```c
u32 pages = a32_load(a32_at(e.mem, H_BUMP));
if (f[2] && pages > f[2] + (QUANTUM >> PAGE_BITS)) { err_fail(...); }
```

`PAGE_BITS` is 7 and `PAGE_LEN` is 128 `u64` words (1 KiB per page);
`QUANTUM` is `min(CAP_WORDS 32768, 32 * PAGE_LEN 4096)` = 4096 words = 32
pages = 32 KiB in `bend2/selfhost/c_runtime.c`. The first call passes
`before = 0`, so it only records a warm-up frontier.

Consequences that matter for reading the result:

- `H_BUMP` is a high-water frontier. It never decreases, and a free that
  recycles a cell does not lower it. The check bounds **frontier growth**,
  not live bytes, RSS or a retained-object count.
- The allocator parks one `KEEP_WORDS` generation per class in HOT/COLD and
  banks others; that retention is invisible to `H_BUMP`.
- One whole quantum of slack is allowed between readings, so first-touch
  class quanta and parking do not fail the check. A failure means the frontier
  advanced by more than 32 pages (4096 words) across the window.

## 2. The historical failure and its exact emitted shape

**[OBSERVED]** `evals/receipts/foreign_qp57a4_5205478f.json`: component
`5205478f`; emitted `list_rebox_sum.c` `1d59847a…`; clang `0` (no stderr);
run exit 1, stdout `7\n3`, stderr `bend: list reboxing retains heap pages`.
The raw artifact is still at `/tmp/foreign-qp57a-4/list_rebox_sum.c`
(sha256 `1d59847a3227e2381316cd009c37446b8e2360547ba6113036368fc98534ed71`).

**[OBSERVED]** in that emitted C:

- `FID_320` is `cycle` (3 args, `n == 0` returns `acc`); `FID_314` is `wrap`;
  `FID_315` is `rebox` and its Cons arm is `FID_1007`; `FID_1011` is the
  `head_u32` Cons arm; `FID_1015` is the `head_nat` Cons arm.
- Each arm projects with
  `u64 s = term_rfc(t) ? ctr_take(e,t,n,f) : term_loc(t)`. `FID_1007` then
  allocates a *new* Cons (`heap_alloc(cls_fit(2))`) and seals both fields,
  `FID_1011` and `FID_1015` read fields, and none of them releases `s`.
- Across the whole feature region (lines 11750-30560 of the emitted C) there
  are three `heap_alloc` call sites in the cycle chain and **zero**
  `heap_free`, `spare_free` or `term_drop`. The matched cell is dropped as a
  term without returning its storage.

**[INFERENCE]** with `CID_T`: Nil 17 `{0,hot}`, Cons 18 `{2,hot}`, Scalar 43
`{1,hot}`, Pair 44 `{2,hot}`. With the fixture's `seed = 0`, one successor
iteration allocates cons(2w) + rebox cons(2w) + Pair(2w) + cons(2w) + rebox
cons(2w) + one Pair seal redirect(1w) = 11 words in six allocations, and frees
none. The measured window (10000 → 200000 iterations) therefore grows the
frontier by roughly 2.09M words ≈ 16.7 MB ≈ 16.3k pages of 1 KiB against an
allowed 32 pages. The exact bump value was not recorded; the recorded fact is
that the bound tripped after `7` and `3`.

Root cause in source history, **[OBSERVED]** but not yet proven causal for the
fresh image: commit `59b3c490` adds `arm_release`, emitted as
`if (tag_s != 0) { spare_free(e, cls_fit(n), tag_s); }` after the arm has
copied its fields. The `5205478f` image predates it; fresh image `9941352b`
has it as an ancestor. Whether that is the whole difference is exactly what
the fresh C run decides; this note does not assume it.

**[OBSERVED]** the emitter-side gap is not specific to list reboxing, so the
minimum shape does not need the sum, `&2`, rebox or closures. Across the seven
surviving `5205478f` matrix artifacts (`c_target_nested_adt.c` `bebca56d…`,
`c_target_array_nested.c`, `c_target_array_u32.c`, `c_target_array_wide.c`,
`c_target_char_head.c`, `c_target_string_from_list.c`, and
`phys_storage_paths.c`), every `spare_free` call site is one of the same five
runtime helpers (FID_ENTER, audio write, marshal request, array node, audio
buffer); none is a user match arm. In `c_target_nested_adt.c`, the user
`sum(Pt{x,y})` body (FID_316, lines 11826-11864) is a two-word, two-`U32`
constructor matched once and reduced with `U32.add` — exactly the `own_cons`
shape — and it never releases the taken `b0s`/`lv0`; its user feature region
(lines 11700-12000) contains zero `spare_free`/`heap_free`/`term_drop`. That
fixture's clang stopped on unrelated duplicate names, so it never ran; the
dynamic page failure remains the `list_rebox_sum` receipt. Repeated
consumption of such a node is therefore the minimum causal control shape;
`own_cons` is its smallest runnable form. **[INFERENCE]** on `5205478f` it
would add 2 words per iteration.

## 3. Causal graph

Valid affine source → BIR match on a Lone constructor parameter → the
physical arm takes the node (`ctr_take`/`term_loc`) and copies its fields into
locals → the arm projects or rebuilds a node and returns → **[bug]** the taken
payload is never released → unreachable class-sized cells that the free lists
never see → each fresh class quantum advances `H_BUMP` → the foreign
`heap.check` growth bound trips.

Not part of the cause: the sum, the `&2` Many element, sealing, closures, and
caller residual use. They add allocations (seal redirects) or belong to
different ownership contracts; they are excluded from the minimal witnesses.

## 4. Minimal runnable witnesses

`evals/repro_ownership/own_cons.bend` (with `.c`/`.js` twins)

- Data: one 2-word `Box{one: U32, two: U32}` built fresh each iteration.
- Control: tail-recursive `cycle`; `take(b: Box)` matches once and returns one
  field. No sum, no Many field, no closure, no caller residual use.
- Measurement: warm at 1000 iterations, compare at 20000, seed 3.
- Correct output: `3`, then the warm frontier, then the after frontier with
  `after <= before + 32`, then `bounded`.
- **[INFERENCE]**, not a promised outcome: on the historical missing-release
  emitter one 2-word cell per iteration predicts ~297 pages of growth over the
  window, well past 32. Only the run measures the actual reading.

`evals/repro_ownership/own_rebox.bend` (with `.c`/`.js` twins)

- Data: `List<&2, Value>` with packed `Scalar{U32}` and 2-word `Pair{Nat,Nat}`.
- Control: `rebox(values)` matches a Cons and rebuilds `value <> tail`; the
  result feeds `head_u32`. No second rebox, no `head_nat`, no closure, no
  residual caller use.
- Measurement: warm at 1000 iterations, compare at 20000, seed 0.
- Correct output: `7`, warm frontier, after frontier with
  `after <= before + 32`, then `bounded`.
- **[INFERENCE]**, not a promised outcome: on the historical missing-release
  emitter 4 words per iteration predicts ~593 pages, past 32; the run measures
  the actual reading.

Both foreign `.c` files use the same `H_BUMP`, the same
`pages > before + (QUANTUM >> PAGE_BITS)` threshold and the same
`before = 0` warm-up convention as `tests/run/list_rebox_sum.c`. Only the
diagnostic string differs. The `.js` twins check values only and return 0, as
the historical twin does.

### Measured on `5205478f` (guardian released, 8192/8192/10 ms/600 s)

Both cases: emit exit 0, clang exit 0, run exit 1; gate report `complete`,
`ownedTreeStopped: true`, command exit 1, 42.743 s, peak RSS 1,369,505,792 B,
peak footprint 1,411,545,616 B. Raw logs in `/tmp/ownership-520-go2`; the gate
report is `report-1792919554434-c4b686d1a9641b6a.json` (`553fd89d…`).

| Case | emit | clang | run | stdout | stderr | warm pages | ceiling | failure means |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `own_cons` | 0 | 0 | 1 | `3`, `97` | `bend: minimal ownership retains heap pages` | 97 | 129 | second reading ≥ 130 |
| `own_rebox` | 0 | 0 | 1 | `7`, `97` | `bend: rebox rebuild retains heap pages` | 97 | 129 | second reading ≥ 130 |

Emitted C and binaries: `own_cons.c` `7be9471f…` (863,882 B), binary
`56453865…`; `own_rebox.c` `3cf69a8c…` (870,581 B), binary `38b0b5d1…`.
The failing reading itself is not printed: the foreign check aborts before it
returns the value, and it was not guessed. **[OBSERVED]** in these exact
artifacts: `own_cons.c` `FID_315` (lines 11814-11840) takes the two-word Box
through `ctr_take`/`term_loc`, projects both fields and returns, never
releasing `b0s`; `own_rebox.c` `FID_490` does the same for a Cons and
`FID_492` rebuilds with `heap_alloc(cls_fit(2))` + `rfc_seal`. Both user
feature regions contain zero `spare_free`/`heap_free`/`term_drop`; all six
`spare_free` occurrences per artifact are the five runtime helpers.

This is diagnostic evidence, not acceptance: it shows the one-node-per-
iteration and four-word-Cons shapes are sufficient on the historical image.
It does not prove which source change causes the fresh image's behaviour.

## 5. Why a page diagnostic cannot judge alias / whole-parent witnesses

A page bound is sensitive to extra allocation, recycling and any sharing
copy, so it cannot distinguish "correctly shared" from "leaked" or "moved
too early". These stay value-observable witnesses, unchanged:

| Witness | Contract | Observable |
| --- | --- | --- |
| `evals/c_target_repeat_data.bend` | caller `measure(+s: String)` is Many and stays live across two calls of Lone `ident`; each callee formal may move, the caller's residual must be shared per call | `8` |
| `evals/c_target_alias_paths.bend` | two bound aliases of the same projected Many `a` path; the second read shares the path root | `8` |
| `evals/c_target_region_leave_repeat.bend` | taken arm vs unreachable sibling `LeaveRegion`; the residual use follows the taken arm | `7`, `6` |
| `evals/c_target_disjoint_type_cells.bend` | disjoint array halves own heap closures capturing their own `k`; consuming one half must not copy the other's Type cell | `5` |
| `evals/c_target_clo_field.bend` | a callable constructor field is moved out and applied, not blanket-kept | `7` (historical run was `REJECTED_UNGUARDED`) |

A move-at-first-call defect in any of these can corrupt a value or double
free while *leaving the frontier flat or smaller*; conversely, a correct
sharing copy legitimately allocates. So pages are the wrong instrument there.
Conversely, both memory witnesses above use only a fresh temporary and a
single Lone consumption, so a page failure there cannot be excused as invalid
affine input.

Prepared minimal public-path witness for the whole-parent corner (opt-in in
the driver: `CASES=alias_whole_parent`, expected `9`):
`evals/repro_ownership/alias_whole_parent.bend` has one Many caller `+p` and
two Lone consumers: `first_field` projects one Many `String` field, and
`whole_length` consumes the whole parent. A correct emitter may share/copy;
the observable is the value `9` and no double free, never a page count. This
is the same caller-residual-liveness contract as `c_target_repeat_data` with
the whole-parent consumption added, so it needs no BIR fixture: Control's
candidate BIR `1dfad82a` is not present in this worktree and is not used as
proof.

## 6. Runs

### Executed: `5205478f`, diagnostic (not acceptance)

One exclusive lane, unchanged bound, one outer guardian; the driver refuses
without the guardian lease:

```
env CANDIDATE=/private/tmp/bend-fir-root-aa9/checkpoints/root-final4-art.js \
    CANDIDATE_HOST=/private/tmp/bend-fir-root-aa9/evals/candidate_host.ts \
    PARSER=/private/tmp/bend-fir-root-aa9/checkpoints/bootstrap-parser-rebuild-qp57a-4.js \
    BASE=/private/tmp/bend-fir-croot57ab/bend2/base.bend \
    RUNTIME_C=/private/tmp/bend-fir-root-aa9/bend2/selfhost/c_runtime.c \
    NODE=/Users/ilyagulya/Library/pnpm/nodejs/23.11.0/bin/node \
    OUT=/tmp/ownership-520-go2 TARGET=c \
  bun /private/tmp/bend-repro-ownership57ab/evals/heavy_gate.ts \
    --memory-mib 8192 --rss-mib 8192 --poll-ms 10 --timeout-ms 600000 \
    -- /bin/sh /private/tmp/bend-repro-ownership57ab/evals/repro_ownership/run_ownership_repro.sh
```

Terminal: gate `FAIL`/`command_exit` — the expected witness failure, not a
harness failure — with `reportPhase: complete`, `ownedTreeStopped: true`,
command exit 1, 42.743 s, peak RSS 1,369,505,792 B, peak footprint
1,411,545,616 B. Both cases emitted (exit 0), clang compiled (exit 0) and the
runs exited 1; page values and artifact hashes are in §4. Raw logs:
`/tmp/ownership-520-go2`; gate report `report-1792919554434-c4b686d1a9641b6a.json`
(`553fd89d…`).

The first attempt `/tmp/ownership-520-go1` is rejected before measurement, not
an ownership result: both stopped at checking with `invalid use quantity for n`
and `invalid use quantity for before`. The fix is input-only (`mk(+n: U32)`,
`+before : U32`); shapes, threshold and frees are unchanged. Raw stderr
`fb96a755…` / `ec9fb8b7…`.

One deadline mechanism only: the outer 600 s `heavy_gate.ts` guardian of the
whole owned tree; the driver adds no timeout wrapper, lock or process-group
engine. Stage exits, literal commands and sha256 of every input and output are
written under `$OUT`; raw stdout/stderr stay whole.

### Pending: `9941352b` fresh image

The fresh command is the same with the fresh pins
(`root57ab-go-art.js 9941352b…`, `candidate_host 2596997a…`,
`base/root57ab-go/bend2/base.bend 323827…`,
`runtime_c/root57ab-go/bend2/selfhost/c_runtime.c 478c1b…`,
`OUT=/tmp/ownership-57ab`). The whole-parent alias witness likewise waits for
that fixed image. No production file was edited.

**[OBSERVED]** why the fresh run is pending: the common failure already hits a
plain fixture on `9941352b`, so it is not an ownership-shape result.
`evals/c_target_array_nat.bend` (`1f5d1ebc…`, Base+IO only, no inline-value
syntax) fails before clang with `candidate: emission failed: BIR continuation
reads a value that is not in scope` in
`/private/tmp/bend-repro-inline57ab/checkpoints/repro-inline-values57ab-v3/c_target_array_nat.emit.stderr`
(`cb9876aa…`); its gate report (`4fc69da5…`) is phase `complete`,
`ownedTreeStopped: true`, `commandExitCode: 1`, 19.1 s, recorded in
`repro_inline57ab_ladder.json` (`b3445add…`).
