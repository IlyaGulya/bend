# Checked FIR laws

Normative specification of the checked frontend IR (FIR) boundary of the self-hosted
compiler. Source of truth for symbols and line numbers: commit `943de390`. Companion
document: [`BIR_LAWS.md`](./BIR_LAWS.md). This file describes obligations and what
currently enforces them. It is **not** a proof, a soundness theorem, or a claim that
successful checking establishes semantic preservation. No mechanized model or proof of
this selfhost FIR (its carrier, publication invariants, checker or checker→BIR
lowering) exists. That statement is about this pipeline only: `bend2/bendtt.lean` is a
separate Lean development of the Bend kernel, with its own mechanized claims about
that kernel; it mentions neither `CheckedProgram` nor the selfhost checker, and it
does not formalize lowering.

## 0. Notation

* `F` — a value of `Checked.CheckedProgram` (`checked_frontend.bend:18`).
* `B` — a value of `BIR.Program` (`backend_ir.bend:233`).
* `lower(F)` — `BackendLower.lower` (`backend_lower.bend:1943`), returning
  `Lowered{program: B}` or `LowerFailure{message, span}` (`backend_lower.bend:14-16`).
* `success(B)` — the `Lowered` alternative; it exists only if `lower` found no
  `Problem` while preparing and lowering.
* `diag` — `Checked.Diagnostic{file, span, message, expected, observed}`
  (`checked_frontend.bend:8-9`).
* Producer — `Checker.check` (`checker.bend:15590`). No other module constructs a
  `CheckedProgram` except by re-wrapping the producer's fields
  (`backend_lower.bend:1937-1941`, `lower_catalog.bend:1444,1451`).
* Consumer — a function that accepts `F`, currently `BackendLower.lower` /
  `lower_library`, `CEmit.emit` / `Emitter.emit_c` (`c_emit.bend:97`,
  `c_emit_core.bend:106,111`), `JS.emit` / `Emitter.emit`, and
  `Checker.inspect_checked`.

Status tags used per law:

| tag | meaning |
| --- | --- |
| `[T]` | encoded by Bend's type/carrier shape (affine `Type`, field types) |
| `[C]` | enforced by the producer's construction path; no post-hoc validator |
| `[V]` | partly checked by an executable consumer/decoder, not by the producer |
| `[N]` | normative requirement; **not** established by code or proof |

## 0.1 Relation to the earlier checkpoint contract

`checkpoints/SELFHOST_IR_ARCHITECTURE.md` §4 already listed law IDs F1–F3, L1–L7,
B1–B2, G1–G2 and K1–K5 as implementation obligations. That document is a historical
architecture record pinned to the compiler57y/57t sources it discusses; its
acceptance results are not reclassified here. For the current source `943de390`, this
file **refines and supersedes** its FIR-side obligations:

| earlier ID | current specification |
| --- | --- |
| F1 (publication preserves reachable handles) | FIR-R1–R5 and §13 obligations 1–2 |
| F2 (occurrence preserves the contextual judgement) | FIR-Q1–Q8 |
| F3 (affine owner; success/failure/inspection/handoff) | FIR-O1–O4, FIR-I1–I5 |

The lowering/BIR obligations (L1–L7, B1–B2, G1–G2 and the current part of K) are
owned by `BIR_LAWS.md`; K1–K4 remain historical obligations of the rejected 57r
design, not the current ABI. The checkpoint file now points here rather than being
the sole contract.

## 1. What a successful check grants

`Checker.check(modules)` first expands templates
(`check_template_result`, `checker.bend:15584-15591`) and then folds every module
through `check_modules_private` (`checker.bend:11208`) with an empty global
signature list. `CheckSuccess{program}` is produced only by `arena_check_exit`
(`checker.bend:15070-15074`).

On success, `F` carries, at most, the following facts:

1. **Ownership** of a single source arena containing every retained term, pattern,
   binder, tape and signature (`[T]` + `[C]`; §4).
2. **A checked body occurrence for every term-bodied definition**: each
   `IR.Definition` whose body is `DefTerm{term}` has `checked = Some{occurrence}`;
   `require_checked_definition` turns the missing case into a failure
   (`checker.bend:331-335`, called at `checker.bend:11050-11057`).
3. **A signature/body fitting decision**: the wrapped body
   (`binders_lambda`, `checker.bend:10611-10627`) was accepted by `fits_term` at the
   declared type, or the inferred type of the body was accepted as a `TermType`
   (`check_definition_declared_type`, `checker.bend:10565`; `..._inferred_type`,
   `checker.bend:10594`). `check_term` did the same check while inferring
   (`definition_term_inference_uncached`, `checker.bend:10690-10699`).
4. **Name resolution and visibility** under the checker's scope discipline,
   including predeclared forward signatures and datatype headers
   (`predeclare_definition_signatures`, `checker.bend:11159`;
   `predeclare_datatype_headers`, `checker.bend:11185`).
5. **Affine/erasure quantity acceptance** over the *source* body
   (`validate_definition_termination`, `checker.bend:10485-10496`) and inside
   inference (`quantity_fits`, `checker.bend:740`).
6. **Structural termination acceptance**, unless the definition is marked `unsafe`
   (`check_termination`, `checker.bend:10470-10483`; `unsafe` short-circuits it).
   `unsafe` also changes quantity meaning: inside its scope `QMany` domains are
   treated as `QOne` (`definition_scope`/`domain_quantity`,
   `checker.bend:1195-1212`). So a success for an unsafe definition is weaker than
   for a safe one.
7. **Template expansion**: FIR modules contain no `TermTemplate` that survived
   `Template.expand` (`checker.bend:15584`).
8. **No retained datatype template parameter**: `check_datatype_parameters`
   rejects `Arena.TemplateBinder` at its original parameter span before
   `check_type_decl_ir` publishes the declaration's value. Ordinary erased
   datatype parameters and function templates remain accepted. The typed-step
   public checker regression is `tests/selfhost/datatype_parameters.bend`;
   observed before/after evidence is
   `evals/receipts/root2039g10_checker_entry.json`.

It grants **none** of the following: semantic soundness of the checker, preservation
of source behavior, strong normalization for `unsafe` definitions, uniqueness of
signature entries, machine-checked handle closure, or correctness of any BIR
translation. "The checker accepted it" is an implementation fact, not a semantic
proof. In particular, running the repository's native `term_check`/`book_valid`
gates on a source file is ordinary checking by this implementation; a PASS there is
not evidence about the meta-theory and does not transfer to a modified checker,
lowering or runtime.

## 2. The carrier does not prove itself

`CheckedProgram` is a plain constructor. Bend has no private constructors or smart
constructors here, so any caller can write

```
Checked.CheckedProgram{Arena.empty(), Nil{}, Nil{}, Nil{}}
```

and every consumer will accept it. `[T]` guarantees only that the four fields have
the right *types*: an `Arena`, a list of loaded modules, a list of published
signatures, a list of module metadata. It does not guarantee:

* that any `U32` handle is in bounds or belongs to the source region;
* that `modules` and `metadata` have equal length or matching namespaces;
* that every declaration has a signature entry;
* that an occurrence's `term` really has the type in `ty`;
* that definitions were reachable from the producer at all.

`WF(F)` below is therefore a **presumed producer contract**, not a predicate encoded
in the carrier and not a proven invariant. A consumer that needs more than the shape
must re-check it (`[V]`), and no consumer currently re-checks all of it. The API-level
requirement to accept only producer output is consequently `[N]`, not `[T]`
(FIR-C1). Even `read_node`
(`checked_frontend.bend:31-34`) is an unchecked accessor: it calls
`Arena.get_node(source, id)` with the raw id and no masking or bounds test.

## 3. Well-formedness predicate `WF(F)`

`WF(F)` is the intended invariant of `CheckSuccess`. Every clause is normative; the
tag says how much is actually established.

* **WF0 — carrier.** `F = CheckedProgram{source, modules, signatures, metadata}`.
  `[T]`
* **WF1 — region closure.** Every handle reachable from `modules`, `signatures` and
  `metadata` is a *source* handle: `IR.arena_is_transient(h) = False`
  (`checker_ir.bend:89`) and `arena_node_offset(h)`/`arena_tape_offset(h)` lies
  inside the corresponding source pool (`[N]` in general; `[C]` for the paths that
  publication traverses). No code scans `F` and proves this.
* **WF2 — published-only reachability.** No reachable descriptor contains a handle
  into the transient arena, and the published program does not depend on the
  transient memo, case-prefix, scalar-frame or certified `node_closed`/`node_bounds`
  lanes (those describe transient nodes). `[C]` by `arena_release` and the
  `publish_*` functions; `[N]` as a universal statement.
* **WF3 — declaration/occurrence pairing.** For every `IR.Definition` with
  `body = DefTerm{term}`, `checked = Some{occ}` and `facts = Some{...}`;
  `DefImports` definitions carry a signature and no checked term body.
  `[C]` (`require_checked_definition`; `definition_classify`, `checker.bend:323`).
* **WF4 — signature agreement.** For each definition entry in `signatures`, `ty`
  denotes a type and, when `value = SomeTerm{v}`, `v` is the checked wrapped body.
  For each family/constructor, `ty` denotes its declared telescope. `[C]`;
  no independent audit (`[N]`).
* **WF5 — module/metadata pairing.** `modules` and `metadata` have the same length,
  are in the same input order, and item *i* has the same namespace and path. `[C]`
  by `check_modules_result` (`checker.bend:11133-11142`) and `[V]` by
  `lower_catalog.bend:1400-1430`, which fails on mismatch. The producer also
  assumes the input list is dependency-ordered (imports before importers); see
  FIR-S7.
* **WF6 — canonical provenance.** Every `IR.Symbol` in an occurrence names a
  declaration by `{owner, local, kind, signature}`; the `signature` field is the
  published type handle of that declaration. `[C]` at occurrence construction
  (`checked_symbol`, `checker.bend:537-541`).
* **WF7 — source immutability after success.** No consumer mutates published
  descriptors, appends to the source pool, or rewinds it; `readback` and
  `read_node` are reads. `[N]` (no capability is removed from the consumer; the
  discipline is by convention and by `F` being affine).
* **WF8 — semantic facts are the checker's decisions.** The quantities, symbols,
  pattern layouts and types recorded in occurrences are the ones this checker
  produced; they are not re-derived, normalized to a canonical form, or proved
  equal to any external specification. `[C]`; their semantic adequacy is `[N]` (§13).

## 4. Ownership and lifetime

**FIR-O1 `[T]`.** `CheckedProgram` is declared `is Type` (affine). `CheckSuccess`
transfers the sole owner of the source arena and of every handle reachable from the
program. There is no shared reference and no implicit copy: consuming the record by
value moves its owning fields, and an owning field cannot legitimately be duplicated.
A `+` binder annotation does not turn an owning field into a copyable one merely by
being written; quantities must already permit the use. A consumer that needs the
program after a read must have it returned (as inspection does, FIR-I1), not copied.

**FIR-O2 `[T]` + `[C]`.** `CheckFailure{diagnostic}`
(`checked_frontend.bend:20-22`) carries no program: that is the `[T]` part, and it is
why no partial result can be returned. `arena_check_exit` also discards the arena on
failure (`checker.bend:15070-15072`), which is the `[C]` part. A failed check
therefore yields **no partial signatures, no partial module list and no arena
owner**. Consumers cannot inspect a partially checked prefix.

**FIR-O3 `[T]`.** Consumers consume `F`. `lower(program)`, `CEmit.emit(checked, ...)`,
`JS.emit(program, ...)` take the program by value and return a result that does not
contain it (`backend_lower.bend:1943-1946`; `c_emit.bend:97-105`). Reusing `F` after
such a call is an affine violation, not a supported operation. The only consumer
that returns the owner is inspection (§11).

**FIR-O4 `[C]/[N]`.** The producer hands out a program containing transient
handles nowhere on the publication paths it traverses. Per declaration, `check_declarations_step` publishes the elaborated
top-level, the open-law tape and the new scope entries, *then* calls `arena_release`
(`checker.bend:11031-11048`); `arena_release` rewinds the transient arena to
`Mark{0,0,0,0,0,0}` (`checker.bend:13031-13034`; `Arena.rewind`,
`checker_arena.bend:1297-1308`). A declaration that fails before publication fails
the whole check rather than escaping half-published state. The universal statement
— that no publication path was missed — is not proved (FIR-R4, §13.1).

## 5. Arena regions, publication and handle identity

The checker holds `ArenaStore{source: Arena.Arena, transient: Arena.Arena}`
(`checker.bend:15-16`). Both are the same `Arena` record type; the region is chosen
by each accessor's `temporary` flag or by the high bit of the handle
(`arena_is_transient`, `checker_ir.bend:89-92`; bit 31, bit 30 marks a reversed
tape cursor, `checker_ir.bend:94-101`).

**FIR-R1 `[C]/[N]` — two lifetimes.** The source region is the only region whose
contents may outlive a declaration. The transient region is declaration-local
scratch; `Arena` carries the memo tables, case-prefix cache and the rewind
generation on its transient instance (`checker_arena.bend:84-94`). `Arena.rewind`
resets counts, overwrites every discarded pool slot with that pool's default
descriptor (`node_pool.clear` → `TermQuant{}`, `binder_pool.clear` →
`TemplateBinder{...}`, `name_pool.clear` → `SNil{}`, etc.), clears the substitution
memo and case-prefix slots, and increments the generation
(`checker_arena.bend:1274-1308`). Appends always write a complete slot
(`checker_arena.bend:1088-1091`).

**FIR-R2 `[C]` — publication is a recursive copy into source.**
`arena_publish_term` (`checker.bend:13927`) and `arena_publish_term_view`
(`checker.bend:13930-14060`) walk every child of every `Arena.Node` variant and call
`arena_put_source_node`; `arena_publish_pattern`/`_binder` and the tape publishers
do the same for patterns, binders, word/natural/name/quantity tapes
(`checker.bend:13784-13915,14061-14091`). `arena_publish_occurrence`
(`checker.bend:14502-14540`) covers every occurrence constructor and its children.
`arena_publish_global` (`checker.bend:15017`) publishes signature types and values.
`arena_publish_top_level` (`checker.bend:14600-14639`) publishes definitions, type
declarations and law declarations.

**FIR-R3 `[C]` — source handles are stable, transient handles are not.** Publishing a
source handle is the identity (`arena_publish_term_region`, `temporary = False`,
`checker.bend:13919-13925`). Publishing a transient handle allocates a fresh source
slot (and memoizes it in the transient `PublishedTerm` lane,
`arena_publication_lookup`, `checker.bend:14557-14575`). Consequently the handle in
`occ.term` is a *published* handle, not necessarily the parse-time handle:
`finish_materialized` rebuilds a node when an elaborated child changed
(`checker.bend:444-452`), and `materialize_node` reports `unchanged` by comparing
child handles (`checker.bend:377-443`).

**FIR-R4 `[N]` — stale handles are not detected.** Nothing validates that a handle
in `F` is source-owned or even in bounds. Two silent failure modes follow from the
region tags:

* `Checked.read_node` passes the raw id to `Arena.get_node(source, id)`
  (`checked_frontend.bend:31-34`); lowering and readback do the same
  (`backend_lower.bend:82`, `checker.bend:15008-15015`). An untagged source offset is
  used directly; a transient-tagged id (bit 31 set) is a huge out-of-bounds index
  whose result is not specified by this contract.
* The checker's own accessors choose the region from the tag and mask the offset
  (`arena_get_node_region`, `checker.bend:13051-13059`). A publication that misses
  a recursive field therefore reads a *default* descriptor from the transient arena
  while the declaration is live, and the same handle reads cleared scratch or the
  next declaration's data after `rewind`. No diagnostic is produced.

The closure property is maintained by matching each constructor variant by hand in
the `publish_*` family; there is no generated case analysis and no invariant check.

**FIR-R5 `[C]` — source is append-only during checking.** The only writers to the
source region are `arena_put_source_node/pattern/binder`
(`checker.bend:13089-13135`), reached from the `publish_*` family, and `arena_name`
(`checker.bend:13036-13039`), which interns a name into the source name table even
before publication. No code rewrites or removes a published slot. This keeps
already-published handles valid while later declarations are checked, but it is
again a construction discipline, not a checked capability.

## 6. Signatures, scopes and module metadata

A signature entry is

```
Scope.ArenaGlobal{key: String, namespace: String, local_key: String,
                  ty: U32, value: IR.OptionalTerm, kind: GlobalKind}
```

(`scope_lookup.bend:16-17`), with `GlobalKind` one of
`GlobalFamily`, `GlobalConstructor`, `GlobalDefinition`.

**FIR-S1 `[C]` — what is stored.** `ty` is a published handle to the declaration's
canonical type. For a definition, `value` is `SomeTerm{lambda-wrapped body}` after a
successful check, or `NoTerm` for a predeclared header/foreign declaration
(`store_definition`, `checker.bend:10557-10559`; `store_definition_declared`,
`checker.bend:10503-10528`). Families store their telescope type; constructors are
added by `check_constructors` (`checker.bend:9194-9218`). Foreign/import-only
definitions store `NoTerm` after `check_import_definition`
(`checker.bend:9335-9348`).

**FIR-S2 `[C]` — declarations become visible in two waves.** Within a module,
`predeclare_definition_signatures` publishes every definition's *signature* before
bodies are checked (forward references use the published type, never an unchecked
value), and `predeclare_datatype_headers` publishes family headers before fields or
bodies. Those entries go into the *visible* scope used for checking. The final
signature list is the evolving declaration scope, not that predeclaration scope
(`check_declarations` returns `global_scope_entries(v_8)`,
`checker.bend:11088-11131`; `store_definition` prepends into the evolving scope
passed as its `v_12`). So `signatures` contains the checked value entries, not the
`NoTerm` predeclaration entries of the same module.

**FIR-S3 `[C]` — canonical keys versus local aliases.** Entries added by this
checker are keyed by `canonical_key(namespace, local)` (`checker.bend:1357-1365`;
separator `.`, empty namespace means the local name). `definition_visible_self` and
`predeclare_datatype_header` additionally publish a local-name alias *into the
visible checking scope* (`checker.bend:10675-10688`, `11177-11183`), but that alias
is not guaranteed to appear in `signatures`. Consumers that resolve by local name
must use `ModuleMetadata.scope`; consumers that search `signatures` must use the
canonical key.

**FIR-S4 `[C]` — accumulation and order.** `check_modules_private` folds the input
list head-first, descending into the remaining modules before prepending the current
one, so `modules` and `metadata` end up in **input order**
(`checker.bend:11208-11221`, `11133-11142`). `signatures` is threaded from module
to module and grows with each module's new global entries. Within one module,
`global_scope_prepend` puts newer entries first, so entry order is reverse
declaration order; across modules the groups are reverse module order (the last
module's entries are nearest the front). No code asserts or establishes uniqueness
of `key` in `signatures`. `Scope.lookup` resolves through the scope index bucket
with first-entry/family/kind precedence (`scope_lookup.bend:33-78`), and
`export_signature` is a first-match linear search (`lower_catalog.bend:791-799`).
Uniqueness is therefore not a consumer guarantee.

**FIR-S5 `[C]` — `ModuleMetadata.scope` is the authoritative resolution snapshot.**
`ModuleMetadata{namespace, path, scope, families}`
(`checked_frontend.bend:13-14`) is built by `check_modules_result` after the whole
fold completed, from `visible_globals(store, signatures, namespace, imports)` over
the **final** accumulated signature list, then passed through `metadata_scope_value`
(`checker.bend:301-305,11133-11142`). That filter keeps only the module's own
namespace, explicitly imported segments and `Base` (`visible_globals`,
`checker.bend:1448-1455`), so later modules' unrelated entries do not become
visible. The snapshot preserves ordered segments, alias lookup and the `unsafe`
wrapper, but deliberately drops the `canonical_aliases` cache (`metadata_index`,
`checker.bend:290-293`). This scope is what lowering uses for per-module resolution
(`lower_catalog.bend:1192-1198,1400-1430`). It **cannot be reconstructed** from
`modules` alone: import aliases, visibility ordering, canonicalization and
relaxation decisions are consumed during checking and only the resulting lookup
survives.

**FIR-S6 `[C]` — `ModuleMetadata.families`.** One `FamilyMetadata{key,
quantity_prefix}` per datatype declaration, in declaration order
(`metadata_families`, `checker.bend:11124-11131`; prefix counts leading binders
whose normalized type is `TermQuant`, `checker.bend:273-288`). Lowering rejects
missing, unmatched or extra family metadata (`lower_catalog.bend:1347-1390`); this
is a consumer-side structural check, not a producer proof.

**FIR-S7 `[C]/[N]` — dependency-ordered input is a precondition, not a checked
property.** `check_modules_module` builds the visible scope from `signatures`
accumulated from *earlier* modules only (`checker.bend:11195-11206`), so an imported
name resolves only if its module precedes the importer. Public `Loader.load` produces
that order: an importer's `FinishItem` is queued after `ImportsItem`, whose imports
are themselves expanded first, and dependency cycles are rejected
(`loader.bend:314-395`). `Checker.check` itself accepts any list and does not verify
the order; passing an importer before its dependency is a producer-contract
violation that surfaces as an ordinary unresolved-name diagnostic, not as a
precondition error.

## 7. Occurrences and checked facts

`IR.Occurrence` (`checker_ir.bend:52-58`) is a per-invocation result record, not a
cache keyed by term identity. The in-source contract is at
`checker_ir.bend:40-51`: children belong to this checking invocation even when term
handles are shared; the child order per constructor is documented there and **only**
there.

**FIR-Q1 `[C]` — one term, many occurrences.** The same term handle may be checked
in different environments and receive different occurrences and types. The carrier
has no `term → type` map either, but that absence is not a proof that the producer
never collapsed contexts; the construction is. Consumers must not build such a map.

**FIR-Q2 `[C]` — fields and their child order.** `TypedOccurrence{term, ty, formal, symbol, bindings,
children}`: `term` is the materialized/published term of this occurrence, `ty` its
inferred type handle, `formal` the resolved binder quantity for
`App/Lam/All/Mat/Absurd` only, `symbol` the selected global for named heads only,
`bindings` the pattern/constructor field bindings. `LocalReferenceOccurrence`
additionally carries `binding` and `value`; `value` is semantic substitution
metadata, explicitly *not* a runtime operand (`checker_ir.bend:49-50`).
`ScalarOccurrence`/`StringOccurrence` carry literal symbols and bit/char payloads.
`CaseOccurrence`/`LocalOccurrence` carry checked patterns. The record does not tag
which child is which; a consumer that gets the arity or order wrong has no runtime
guard.

**FIR-Q3 `[C]` — bindings.** `CheckedBinding{quantity, ty, type_depth}`
(`checker_ir.bend:34-35`) records the lexical type and the resolved declared
quantity of a pattern variable or constructor field. `CheckedPattern` separates a
variable's `binding` from a constructor's instantiated field `layout`
(`checker_ir.bend:36-38`). These are instantiated facts, not a substitution
environment: substitution and `Sub/Fill/Reply` elaboration are gone from the checked
graph (`checker_ir.bend:50-51`).

**FIR-Q4 `[C]` — quantity validation is a side condition, not a stored proof.**
Affine/erasure admissibility is `quantity_fits(used, allowed)` over the lattice
`QZero < QOne < QMany` (`checker.bend:740-761`) with branch merging via
`usage_merge`/`quantity_alternative` (`checker.bend:719-738,7696-7712`). It is
validated inside inference for lets/patterns/lambdas
(`check_local_quantity_map`, `checker.bend:2825`; `check_local_pattern_usage_map`,
`checker.bend:2871`; `lambda_usage_valid`, `checker.bend:6531`) and, for the whole
definition, by `validate_definition_termination` building
`binder_usage_map(..., term, ...)` over the *source* body and calling
`check_binder_usage_map` (`checker.bend:8823-8871,10485-10496`). The usage map is
discarded. **`Occurrence` is therefore not a complete usage witness**: a consumer
cannot reconstruct which source cases or binders demanded which quantity, and the
repository records an explicit counterexample where an occurrence-only affine pass
would be unsound (`checkpoints/compiler-ir-checkpoint-v57h.json`,
`affineUsageSafety`; insert/omitted-row usage witnesses are not in FIR).

**FIR-Q5 `[C]` — pattern coverage.** Exhaustiveness is decided during checking and
rejections are observable (`check_exhaustiveness_result`, `tests/selfhost/checker.bend:107-110`;
nested variant at `:430-458`). The accepted coverage decision is not stored as a
proof object in `F`; occurrences record the materialized cases, not the derivation
that they suffice.

**FIR-Q6 `[C]` — canonical provenance.** `IR.Symbol{owner, local, kind,
signature}` (`checker_ir.bend:28-33`) is the resolution result. It is produced from
the selected `ArenaGlobal` (`checked_symbol`, `checker.bend:537-541`) and uses the
declaration kind and published type handle. It is not an interned spelling and does
not carry the alias by which the name was found. Alpha-renaming or alias equality
must not be inferred from string equality of `local`.

**FIR-Q7 `[C]` — occurrence terms are elaborated.** `Sub`, `Fill` and `Reply` are
elaborated away; `App/Lam/All/Mat/Absurd` carry resolved quantities; `LocalReference`
preserves the lexical variable but not a runtime operand. A consumer must read the
occurrence/term graph as the checker's normal form, not as source syntax.

**FIR-Q8 `[N]` — literal facts are descriptive.** `ScalarOccurrence.bits` and
`StringOccurrence.chars` are the bits the checker used for the certified schema.
The in-source note is explicit: structural certification never grants native numeric
representation (`checker_ir.bend:51`). Nothing in FIR proves a correspondence between
these bits and runtime numeric semantics.

## 8. Checked types and descriptors

**FIR-T1 `[T]`.** In `F`, a checked type is a `U32` handle to a term in the source
arena. There is no type-expression record, no normalized type form and no descriptor
in FIR. `ty`/`signature` fields are simply handles.

**FIR-T2 `[C]`.** At the definition boundary the checker inspects the inferred
*kind* of the declared or inferred signature and requires the node itself to be
`TermType` (`arena_get_node` + `Arena.TermType` in `check_definition_declared_type`,
`checker.bend:10565-10592`, and `check_definition_inferred_type`,
`checker.bend:10594-10609`). This is a direct constructor test, not a
normalization-based judgment. Subterm occurrences carry no such certificate; their
`ty` is whatever inference produced. `metadata_sort` (`checker.bend:255-261`) is a
different, `whnf`-based query used only for the `type_only` fact.

**FIR-T3 `[N]`.** `fits_term`, `equal_term`, `whnf` and the descriptor predicates are
this implementation's decision procedures (`fits_term`, `checker.bend:2176`;
`whnf`, `checker.bend:1892`). No claim is made that they are complete or sound with
respect to an independent type theory. A rejection may be over-eager; an acceptance
is not a semantic derivation.

**FIR-T4 `[N]`.** FIR does not promise that a type handle is in weak-head normal
form, minimal, canonically spelled, or syntactically stable across runs. Lowering
normalizes the descriptor language itself (`DescriptorNf.nf_context`,
`backend_lower.bend:1960`); that is BIR's obligation, not an FIR theorem.

## 9. Failure semantics

**FIR-F1 `[T]` + `[C]`.** Failure is `CheckFailure{diagnostic}`, with no program
(`[T]`; §4, FIR-O2) and no arena handed on (`[C]`). The diagnostic fields are
`file`, `span`, `message`, `expected`, `observed`; only `span`/`file` are source
locations.

**FIR-F2 `[C]`.** Checking is short-circuiting and reports **one** diagnostic. The
first failing declaration in source order wins within a module
(`check_declarations` recursion, `checker.bend:11088-11131`), and the first failing
module wins across modules (`check_modules_private`, `checker.bend:11208-11222`).
There is no guarantee that later independent errors are absent, nor a specified
global priority among checks inside one definition beyond the code's evaluation
order.

**FIR-F3 `[C]`.** Some diagnostics report *internal invariant* violations rather than
user errors, for example `require_checked_definition`'s "missing checked definition
occurrence" with observed `"an invalid internal publication state"`
(`checker.bend:331-335`), or lowering's "missing checked application
quantity/operands" (`backend_lower.bend:1437`). A `LowerFailure` is normally a
producer-contract violation or an unsupported FIR shape, not a source type error;
the CLI nevertheless prints it as a source diagnostic (`driver.bend:130-138`).

**FIR-F4 `[C]`.** Template expansion failure is reported as a check failure with
expected `"a valid template application"` and observed `"template expansion failed"`
(`checker.bend:15584-15588`); it precedes all typing.

**FIR-F5 `[N]`.** Resource exhaustion is not a semantic verdict. The repository's
heavy gate reports `RESOURCE_LIMIT`/exit 73 and `LOCK_BUSY`/exit 75 without
launching or completing semantic work (see `ARCHITECTURE.md`, heavy-gate section).
A killed or timed-out check produces neither `CheckSuccess` nor a diagnostic; do not
read it as rejection.

## 10. Consumer contract

A consumer of `F` may assume only the following, and should re-check anything it
cannot tolerate being wrong.

**FIR-C1 `[N]` — API provenance, not a type check.** Accept `F` only from
`CheckSuccess`, and do not accept a caller-fabricated record as checked. This is a
trust boundary, not something the type enforces: §2 shows that a value with the right
shape is type-legal. There is no supported way to obtain a partially checked program;
that part is `[T]` via the distinct result constructors.

**FIR-C2 `[C], [V]`; ordering premise `[N]`.** Treat `modules` and `metadata` as
positionally paired in input order (FIR-S4); verify namespace/path before use, as
lowering does. Do not assume source order, uniqueness, or that `signatures` mirrors
`modules`, and do not re-feed a module list that is not dependency-ordered (FIR-S7).

**FIR-C3 `[C]`.** Resolve module-local names through `ModuleMetadata.scope`, not by
searching `modules` or the final signature list. Treat `signatures` as an
accumulated, not necessarily unique, canonical-key list.

**FIR-C4 `[C]`.** Read occurrences as the only source of per-invocation facts:
declared/inferred type, resolved quantity, selected symbol, pattern layouts. Do not
re-infer, do not rebuild a `term → type` cache, do not infer usage/quantities from
occurrences (FIR-Q4), and obey the documented child order per constructor (FIR-Q2).

**FIR-C5 `[N]` (discipline).** Do not mutate published descriptors, do not append to
the source arena, do not call `Arena.rewind` on it, and do not treat a transient
tagged handle as meaningful. Consumers receive the same arena they must read, and
the language does not prevent abuse.

**FIR-C6 `[T]`.** Consuming `F` destroys the caller's ability to use it. Lowering's
`LowerFailure` also consumes `F`; there is no "try lowering, then inspect" path.
Inspection (§11) is the only operation that returns the owner.

**FIR-C7 `[T]` (shape) + `[C]`.** `lower(F)` returns `Lowered{program: B}`. The
field types of `BIR.Program{codes, declarations, constructors, families,
type_functions, ending}` (`backend_ir.bend:233-234`) contain no `Arena`,
`Occurrence` or `Scope` objects; atoms carry ids, keys, literals and spans
(`backend_ir.bend:11-22`). The fields are therefore not arena handles in the type
sense, and `lower` constructs them from FIR values (`[C]`). This is the boundary to
`BIR_LAWS.md`: everything FIR-specific ends here.

## 11. Inspection and readback

`Checker.inspect_checked` (`checker.bend:188-189`) is `readback`
(`checker.bend:15093-15101`), which decodes `modules` back to
`Loader.LoadedModule` values and returns

```
Inspection{program: F, modules: List<Loader.LoadedModule>}
InspectionFailure{program: F, diagnostic: diag}
```

**FIR-I1 `[T]`.** Inspection consumes `F` and returns a program with the *same*
arena, modules, signatures and metadata, plus a decoded AST. It is the only
owner-preserving consumer.

**FIR-I2 `[C]`.** Decoding is a read: `arena_decode_*` uses `Arena.get_node`,
`Arena.get_pattern`, `Arena.get_binder` and `Arena.name_text`, and returns the arena
unchanged (`checker.bend:14909-14976,15008-15009`). It neither publishes nor creates
new semantic handles.

**FIR-I3 `[V]`.** Decoding performs partial structural validation. It checks
descriptor/list arities and constructor shapes and reports
`ReadbackFailure{arena, diagnostic}` when a term/pattern does not have the expected
shape (`readback_invalid`, `checker.bend:14671-14676`, called e.g. at
`14777-14800`). This is **not** a type check and does not establish WF.

**FIR-I4 `[C]` (current wiring).** Inspection has **no production consumer**.
`driver.bend` and `hybrid_driver.bend` send `CheckSuccess` straight to lowering
(`driver.bend:160-167`, `hybrid_driver.bend:78-83`); the C path also lowers directly
(`c_emit.bend:97-105`). The historical claim that `dispatch_c → inspect_checked →
c_emit.bend` is the live legacy boundary is stale at this commit: `c_emit.bend` no
longer calls readback. `inspect_checked` is used only by
`tests/selfhost/checker.bend` and by the compiled library smoke (via its exported
steps). Treat inspection as a semantic-oracle view, never as an input to lowering or
a source of new authority.

**FIR-I5 `[N]`.** `read_node(program, id)` (`checked_frontend.bend:31-34`) is an
unchecked raw accessor. It does not validate the region bit, bounds, or node shape.
It is a debugging/oracle seam, not part of the production contract.

## 12. Enforcement summary

| law group | carrier/type | construction | validator | proof |
| --- | --- | --- | --- | --- |
| ownership and failure (O1–O4) | affine `Type`, distinct result constructors | producer maps failure to diagnostic only | none needed | no formal ownership model in repo |
| region closure and publication (R1–R5) | tagged `U32` handles only | recursive `publish_*`, `arena_release` | none; lower assumes it | **no** closure proof; hand-maintained recursion |
| signatures and scopes (S1–S7) | record/list shapes | predeclare + store + scope threading | lower checks module/metadata pairing only | **no** uniqueness/completeness proof |
| occurrences and facts (Q1–Q8) | record constructors | inference emits them | partial: decode shape checks; lower arity checks | **no** semantic adequacy proof |
| types/descriptors (T1–T4) | `U32` handles | boundary `TermType` check | `fits_term` etc. at check time | **no** soundness/completeness proof |
| failure (F1–F5) | result type | short-circuit recursion | none | no exhaustiveness claim |
| inspection (I1–I5) | owner-preserving result | pure decode | partial structural | no semantic guarantee |
| lowering boundary (C7) | `BIR.Program` has no handles | `lower` rebuilds into BIR | see `BIR_LAWS.md` | **no** preservation proof |

## 13. Open proof obligations

These are the concrete gaps behind the `[N]` tags. None is closed by an existing
test, fixture or type declaration.

1. **Region closure.** Prove that for every successful run, every handle reachable
   from `F` is source-owned and in bounds. Today this depends on hand-written
   recursion in `arena_publish_term_view`, `arena_publish_occurrence`,
   `arena_publish_global` and `arena_publish_top_level`. A missed field is a silent
   bug: tagged reads return a default descriptor from the transient region, untagged
   reads index the source array with a transient-tagged id, and neither path
   diagnoses it (FIR-R4).
2. **No escape through caches.** Prove that no handle derived from the transient
   memo/case-prefix/`node_closed`/`node_bounds` lanes escapes into a published
   descriptor. `Arena.rewind` clears those tables on every declaration boundary, but
   no invariant check establishes that a cache entry could not have been published
   first.
3. **Signature completeness/uniqueness.** Prove that every declaration reachable
   from `modules` has exactly the intended canonical entry in `signatures`, and that
   no consumer can observe two conflicting entries with one key. Only
   definition-time insertion is enforced.
4. **Occurrence adequacy.** Prove that the recorded `term`, `ty`, `formal`, `symbol`,
   `bindings` and child order are sufficient for every intended consumer and
   semantically consistent with the checker's judgments. The child-order contract is
   a comment; usage facts are deliberately absent (FIR-Q4).
5. **Type discipline.** Prove that `ty` always denotes a type, not merely a term that
   the checker accepted in type position, and that `fits_term`/`equal_term` are
   sound and complete for the intended type theory. Neither direction is established.
6. **Termination claim.** Prove that `check_termination` accepts only structurally
   decreasing recursion, and that `unsafe` is the only bypass. The code shows the
   bypass and the `QMany → QOne` relaxation (`domain_quantity`,
   `checker.bend:1202-1212`) but not a theorem.
7. **Module/metadata pairing and input order.** Prove producer-side pairing for all
   inputs, and either check or document that a module list not in dependency order
   cannot silently resolve a name against the wrong previous module. Lowering
   detects pairing mismatch only for the paths it traverses.
8. **Inspection is non-authoritative.** Prove that readback cannot change semantics
   or become a lowering input. This is currently a wiring/comment convention
   (FIR-I4).
9. **Failure completeness.** Prove that the single reported diagnostic is the first
   error in a defined order and that no failure path escapes after partial
   publication. The latter is plausible because publication is followed by rewind
   and failure discards the arena, but it is not modelled.

No proof of semantic preservation belongs to this list; it is the BIR lowering
obligation, and `BIR_LAWS.md` records its own status.

## 14. Existing executable evidence (read, not re-run)

The following artifacts exist and were inspected for this specification. None of them
is a semantic-preservation proof, and none was executed while writing this file.

* **`tests/selfhost/checker.bend`.** A real check suite over constructed
  `Loader.LoadedModule` values calling `Checker.check`; it declares **36** expected
  output tokens in trailing `#|` lines. It covers acceptance and rejection of
  dependent application, import aliasing, constructor/multi-column/field/parameter
  patterns, erased and affine quantities, computed matches, nested matrices,
  exhaustiveness, affine duplication, structural termination, `unsafe` recursion,
  and forward declaration order. Its 36 expectations assert observable behavior:
  acceptance (e.g. `checker-dependent-application-ok`,
  `checker-unsafe-recursion-ok`) and rejection (e.g.
  `checker-affine-duplicate-rejected`, `checker-termination-rejected`,
  `checker-exhaustiveness-error`, `checker-nested-exhaustiveness-rejected`,
  `checker-declaration-order-rejected`). They demonstrate the checker's decisions,
  not that those decisions are sound.
* **`evals/checker_library_smoke.ts`.** A documented consumer smoke over a compiled
  library component: real parsed input, actual template expansion, an actual
  `Checked.CheckSuccess.program`, owner-preserving inspection, then JS library
  emission and execution through the public ABI. It is explicitly `smokeOnly` with
  `compilerBootstrapGreen: false`, `selfhostGreen: false`, and a boundary that
  excludes a compiler fixedpoint claim. It requires a matching native component build
  and a fresh parser build before it can run.
* **`checkpoints/selfhost-acceptance-release237-misaka-v53.json`.** Historical
  `LIBRARY_CONSUMER_SMOKE_PASS` record for that smoke, including the exported
  runtime rows produced by the checked program. Its `sourceParentCommit` is `f99b22db`, **not**
  `943de390`; treat it as evidence for the procedure and for the FIR consumer shape
  at that revision only.
* **`checkpoints/compiler-ir-checkpoint-v57h.json`** (`affineUsageSafety`). An
  actual executed seed-checker investigation showing that occurrence-only affine
  validation misses uses present only in source cases covered by earlier patterns.
  This is the direct evidence for FIR-Q4: FIR does not contain omitted-row usage
  witnesses.
* **`checkpoints/compiler-ir-contract-v56.json`.** Small verified ownership and
  backend-operation models. The repository's own IR architecture document states
  that this is **not** a proof of the full FIR/BIR compiler; it should not be cited
  as one.
* **`checkpoints/SELFHOST_IR_ARCHITECTURE.md`** carries the earlier prose contract
  for the same boundary (in Russian, law IDs F1–F3/L/B/G/K) and the explicit caveats
  that a `CheckedProgram` value is not by itself a validity proof and that resource
  limits are not semantic verdicts. Its FIR-side laws are refined/superseded here
  (§0.1); its historical acceptance receipts remain pinned to their sources. The
  stale live-`inspect_checked`-C-path claim and the "single source of contract"
  claim are corrected in that file itself.

No passing native build, fixture, or typecheck of `F` is asserted here. The
acceptance question "did the compiler accept this source?" is answered only by an
actual `CheckSuccess`, and even that answer is relative to this implementation.

## 15. Boundary to the backend IR

FIR obligations end at `lower`. `BIR_LAWS.md` owns:

* what `lower` may assume about `F` (the preconditions FIR-C1–C7 and WF);
* the translation of occurrences into strict operands, erasure, closures and
  descriptor provenance;
* BIR well-formedness (code labels, captures, arities, blocks) and its own
  unproved-obligation list.

FIR makes no claim about BIR validity, renderer correctness, or runtime behavior.
Conversely, BIR must not assume that FIR closure, signature uniqueness or occurrence
adequacy has been proved merely because `CheckSuccess` was returned; it may rely on
them only as producer invariants, re-checking locally where a violation would be
silent or unsound.
