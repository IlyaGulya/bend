# Incremental compilation for the current Bend FIR/BIR pipeline

Status: research note, documentation only. Source analysis baseline `f46ad0f6`
(integration branch `work/fir-ir-integrated57ab`; root 943 + native bridge 7dc
+ the common-emitter consumer cutover), sources read 2026-10-24. The docs
commit is rebased onto actual HEAD `2fcdbaea`; the code files analyzed here are
unchanged between those commits (the intake adds law documents only). Every substantive
claim is labelled **[S]** source-read here, **[M]** measured in a scoped
artifact or trace named beside it, or **[I]** inference. Nothing in this note
was implemented, and no build, test, benchmark, heap dump, or live-process
sample was run by this agent.

Scope: how hard real incremental compilation is for the *new* pipeline
(`bend2/selfhost`: loader → parser/template expansion → checked FIR → catalog
→ BIR → JS/C render), not generic caching, and not the official TS compiler
(`bend2/bend.ts`, `bend2/comp.ts`) except where the official producer is the
actual build blocker. No architecture is committed: no query framework, no
`Arena`/`CheckedProgram` redesign, no new cache format, no LLVM/MLIR switch.

---

## 1. Direct answers

### 1.1 Do we have enough profiling information to continue, at every stage, for CPU and memory?

**CPU: partly, at phase granularity, on an older source pin. Memory: no, not
per stage.** The distinction matters because the incremental design below
turns on two numbers we do not have: retained bytes per cached module and the
cost of rechecking one dirty module.

What actually exists:

| Stage | CPU evidence | Memory evidence | Missing for an incremental decision |
|---|---|---|---|
| load + parse | **[M]** root parse 45,055 ms wall in `evals/selfhost-root-phase-profile-57ab.json`; **[S]** `native_compiler_host.c` emits `NATIVE_PHASE` wall/user/system around `parse`, and reports `ru_maxrss` high-water, not isolated bytes | process high-water RSS only | per-module parse time; retained AST bytes; hit cost of a parse cache |
| template expansion | **[M]** 6,265 ms wall / 6,737 ms CPU in the same profile | none separated | per-module expansion time; generated-instance counts/bytes; dependency set size per module |
| check | **[M]** 162,580 ms wall / 174,625 ms CPU; self-time shares: CPS continuation closures 25.9 %, `checker_chunk` 9.5 %, `checker_step_one` 8.3 %, `checker_step` 8.1 %, GC 7.1 %, `index_lookup` 6.8 % | process/aggregate only; 4.59–5.14 GiB peak RSS for the aggregate gate | per-module and per-definition retained bytes; recheck cost of one module; cache hit rate |
| catalog / BIR lowering | no phase receipt for the new pipeline | none | time and bytes for `Catalog.build` and `BackendLower.lower` |
| JS/C render | **[M]** emit 7,069 ms wall / 8,835 ms CPU in the pinned profile | none separated | per-definition render time/size; sharing-plan pass cost |
| official producer (TS) | **[M]** `--trace-c` rows per pass/definition/spin with process `heapUsed` in `evals/native_compiler_experiment.ts:207-223`; peer measurement of pass-level heap minima | **[M-peer: NativeCodegenMemory]** lowest observed `heapUsed` after reported drops rose 1,993.5 → 2,240.3 MiB over passes 1–6; at death checked book 1,592.5 MiB of 3,033.7 MiB; stable FL facts +401.7 MiB. GC type and retained-byte provenance are unobserved | isolated retained bytes per structure; per-definition attribution (GC-polluted) |

Pins and limits that forbid using the numbers as current certification:

- **[S]** `evals/selfhost-root-phase-profile-57ab.json` records `source.branch = work/fir-nf-combined57ab`, `head = d47f859b`, `claims.diagnosticOnly = true`, `aggregatePass = false`, and an explicit correction that phase marks are *starts*. It is not a receipt for `f46ad0f6`.
- **[S]** `checkpoints/compiler-profiling-quality-v51.json` pins `sourceCommit 7c33172b`, compiler version 49, and states that the old V8 worker profile covers startup+parse+expand+check, not checking-only CPU; process `cpuUsage` is broader than the worker isolate; allocation sampling is statistical.
- **[S]** `evals/selfhost_cpu_profile.mjs:39-46` uses 1,000 µs CPU sampling and 4 MiB allocation sampling; its own `memoryScope` says RSS is process-wide and allocation samples are estimates including collected objects.
- **[S]** `checkpoints/book-phase-attribution.json` pins older `bend2/bend.ts` and `parser.bend` hashes and a 3 GiB load ceiling; it is a load-blocker receipt, not a current pipeline profile.
- **[M-scoped, Main]** the current dedup traced build has 11,164 native-bridge bodies, book heap 1,669,811,048 B, reaches pass 6 and OOMs with no native artifact; this agent did not rerun it.

**Consequence.** We have enough CPU evidence to say *where* incremental effort
should start (check, then parse; not render), and enough memory evidence to
reject a per-definition render cache as premature. We do **not** have enough
to size an on-disk checked-artifact cache, to promise a speedup, or to claim
that module-level reuse will amortize its own bookkeeping. Those are open
measurements, listed in §11.

### 1.2 How hard is incremental compilation later?

Qualitative difficulty, in the order the pipeline makes things possible:

| Incrementality unit | Difficulty | Main reason |
|---|---|---|
| parse / file-content cache | **low** | parser output is a self-contained `Ast.Module` tree; content hash is natural; no arena handles |
| resolved-import cache | **low–medium** | resolution is IO + path/namespace rules; package sources already verify SHA-256 |
| template-expansion cache | **medium** | expansion is a global fixed point; needs a per-module template dependency set and generated-key stability |
| module-level checked-artifact reuse (in one process) | **medium–high** | append-only source arena helps; but signatures/metadata hold raw handles, `Arena` is affine, and invalidation must follow imports and body values |
| module-level checked-artifact reuse (across processes) | **high** | no production serializer; positional semantic-arena handles; needs relocation or stable IDs |
| dependency-tracked per-definition checking | **very high** | no read set or result fingerprints; bodies unfold into types; `ArenaStore` is destructured everywhere |
| BIR/declaration fragment caching | **high** | whole-program sequential code/constructor ids; normality and reachability are global; C sharing/physical facts are whole-program |
| true separate compilation / linking | **very high, architectural** | BIR and C have no module boundary or table ABI split; one C translation unit is explicit |

The single most important structural fact is both good and bad:

- **Good [S]:** the checked representation already separates a single immutable
  `source` owner from a declaration-local `transient`, and only handles
  published into `source` may escape rewind (`checked_frontend.bend:16-34`,
  `checker.bend:12722-12725`). Per-declaration scratch caches are already
  scoped and invalidated correctly (`checker_arena.bend:82-97`,
  `checker.bend:12792-12798`, `checker.bend:13031-13034`).
- **Bad [S]:** semantic references inside checked artifacts are positional
  `U32` arena handles, and the same arena index means something else after an
  insertion. This is narrower than "everything is a number": canonical keys,
  owner/local names, and import paths are `String`s, and BIR declaration/
  constructor/family labels are string keys with separate numeric
  code/constructor ids. The missing pieces are a stable identity layer for the
  semantic handles, a serialization format, and a dependency journal. That is
  exactly the distance between "cache a prefix in one live process" and
  "incremental compiler".

---

## 2. What the current pipeline actually does

### 2.1 One-shot, no reusable state

**[S]** `driver.bend:190-204` loads, checks, and emits once. `Loader.load`
walks the import graph, reads and parses every file, and returns modules in
DFS finish order (`loader.bend:300-404`). `Checker.check` calls
`Template.expand(modules)` and then builds an empty arena
(`checker.bend:15080-15091`, `15085-15091`). `arena_check_entry` starts from
`Arena.empty()`; `arena_pack_modules` copies every parsed module into checker
IR; `check_modules_private` walks modules in order and accumulates
signatures (`checker.bend:11195-11220`, `15059-15084`).

There is no cache directory, no compiler version key, no module hash, and no
session API. The only hash use is package verification: **[S]**
`loader.bend:148-166` hashes package source bytes and compares a manifest
prefix; `sha256.bend:164` provides the primitive.

**[S]** The official producer is also one-shot and explicitly says so:
`evals/native_compiler_experiment.ts:34` — "No ASTs are serialized or
cached." `Bend.book_load` recursively parses every imported file into one
`Book` (`bend2/bend.ts:319`, `952-1017`); `book_valid` rechecks the whole order
in place (`bend2/bend.ts:3804-3810`); `compile_book` builds/runs a whole-program
fact fixed point over every definition (`bend2/comp.ts:3110-3155`).

### 2.2 Ownership and lifetime (what makes reuse safe or unsafe)

**[S]** `CheckedProgram` is an affine owner:

```
CheckedProgram{source: Arena.Arena, modules: List<IR.LoadedModule>, signatures, metadata}
```

(`checked_frontend.bend:16-34`). `source` is the single arena owner. The module
list and occurrence trees reference published source handles. `Arena` itself
is a `Type` holding arrays for nodes, patterns, binders, words, naturals,
names, plus indexes and scratch tables (`checker_arena.bend:82-97`).

**[S]** Two tagged handle spaces are distinguished by bit 31
(`checker_ir.bend:88-96`): source handles are stable within a run, transient
handles are declaration-local. `arena_publish_*` copies a transient tree into
the source arena and rewrites children (`checker.bend:13919-14000`).
`arena_release` rewinds the transient to an all-zero mark after each
declaration (`checker.bend:13031-13034`); source is never rewound today.

**[S]** `Arena.mark` records the high-water of each pool
(`checker_arena.bend:1154-1184`). `Arena.rewind` truncates pools, deletes name
ids for discarded names, clears the case-prefix cache and the entire
substitution memo, and bumps a rewind generation (`checker_arena.bend:1270-1305`,
`checker_arena.bend:82-85`). This is a correct primitive for *truncating a
suffix*, not for deleting a middle module.

**Incremental consequence [I].** An in-process cache can safely retain the
`source` owner plus the immutable module/signature/metadata lists. It cannot
retain a *second* arena and mix handles. It cannot move a cached artifact to a
different arena without rewriting every handle, because `ArenaGlobal.ty`,
`ArenaGlobal.value`, `Symbol.signature`, `CheckedBinding.ty`, every
`Occurrence` term/type, and every node child are raw indices.

### 2.3 Where the checker's dependencies actually come from

**[S]** Module visibility is local, not global: `visible_globals` builds a
current-namespace segment, one segment per import, and a Base segment
(`checker.bend:1448-1455`); `current_scope`/`import_scope` filter the
accumulated signature list by owner and alias (`checker.bend:1367-1425`). A
module does not see an unrelated module's declarations.

**[S]** Within a module, checking is deliberately ordered:

1. `predeclare_definition_signatures` publishes each definition's declared
   result type with `IR.NoTerm` so forward references see a signature
   (`checker.bend:11159-11175`, `10675-10688`).
2. `predeclare_datatype_headers` publishes family headers with no value
   (`checker.bend:11177-11195`).
3. `check_declarations` checks declarations in source order. After a
   declaration is checked it is published with `IR.SomeTerm{value}`
   (`checker.bend:10509-10529`, `10538-10552`), names are published, and the
   transient is rewound before the next declaration
   (`checker.bend:11031-11045`).

**[S]** `declaration_visible_scope` and `global_scope_size` make each
declaration's scope a delta over the predeclared header scope
(`checker.bend:1448-1462`, `11088-11131`). That means a reusable checkpoint is
not just "the modules checked so far"; it also has to preserve the exact
predeclared header set and the scope boundary at the resume point.

### 2.4 Why a textual signature is not a sufficient cache key

This is the central soundness point. A signature fingerprint cannot represent
what checking actually read.

1. **[S]** A published definition carries both its type and its checked body
   value: `Scope.ArenaGlobal{key, namespace, local_key, ty, value, kind}`
   (`scope_lookup.bend:13-21`); `store_definition` publishes
   `IR.SomeTerm{value}` for the checked term (`checker.bend:10521-10525`,
   `10547-10551`).
2. **[S]** `whnf_ref_global` unfolds a global's value for *any*
   `GlobalDefinition`/family when the reference is normalized, and
   `whnf_application_global` beta-applies a definition's value when the
   reference is applied (`checker.bend:1481-1540`). So a definition used in a
   type can be reduced by its body.
3. **[S]** Type-derived definition facts also unfold: `metadata_sort` and
   `metadata_prefix` call `whnf(..., 64n, ty, scope)`
   (`checker.bend:255-290`), and those facts become
   `DefinitionFacts{type_only, fixed_signature, quantity_prefix}`
   (`checker.bend:302-329`).
4. **[S]** At BIR construction, reachable definitions with a term body and no
   primitive/foreign become `BIR.TypeFunction{..., body: descriptor(body)}`
   (`lower_catalog.bend:844-861`). The type-function *body is the definition
   body term*, not its declared result type. `DescriptorNf` then reduces type
   expressions with the whole family and type-function tables.
5. **[S]** `Needed`/`needed_roots` compute that reachable set from roots
   (`lower_catalog.bend:1017-1042`, `840-869`), and `build_finish` normalizes
   foreign definitions and the ending through `DescriptorNf.nf_context`
   (`lower_catalog.bend:1430-1466`).

Therefore: **if `F`'s body changes while `F`'s declared text does not, a
downstream type expression mentioning `F` may normalize differently, a
`type_only`/quantity fact may change, and BIR's normalized descriptors and C
layout may change.** Any accepted reuse must have a validated dependency on
the body (or on the exact set of globals actually unfolded) and on the
family/type-function tables. An unchanged textual signature is not evidence
of unchanged checking.

### 2.5 Global IDs and the catalog/BIR boundary

**[S]** `Catalog.build` consumes the `CheckedProgram` and returns it alongside
the catalog (`lower_catalog.bend:1467-1470`). `Preparation.next_code`
increments for every prepared definition; `next_constructor` increments per
constructor (`lower_catalog.bend:1192-1235`, `1274-1324`). `BIR.Code{id}` and
`BIR.ConstructorLayout{id}` carry those numbers
(`backend_ir.bend:203-238`); `lower_catalog` seeds `State.next_code` from
`Catalog.next_code` (`backend_lower.bend:1951-1957`). `lower_definitions`
walks *all* catalog definitions and emits every declaration
(`backend_lower.bend:1737-1758`); there is no module boundary and no liveness
filter in BIR.

**Incremental consequence [S/I].** Inserting or deleting a definition
renumbers code ids after it; inserting a datatype renumbers constructor ids
after it. JS emits code names from ids (`js_backend.bend:657-660`); C tables
and segments are built from those ids. Any BIR/render fragment cache is
therefore blocked on either (a) stable symbolic ids plus link-time assignment,
or (b) full-program renumbering that invalidates the fragments anyway.

### 2.6 Render is explicitly whole-program

**[S]** `c_backend.bend:11-14`: `emit(program, runtime)` "renders a
BIR.Program into one C translation unit: the Bend C runtime template with its
four marker sections filled by this program's tables, segments, static image
and effect sources." `render_assemble` takes all tables/spins/segments/requests
together (`c_backend.bend:3201-3206`). The C target computes a whole-program
`SharingPlan` fixed point for hot constructors, `BLK_SHR`, and sealing
(`c_backend_sharing.bend:1-45`, `sharing_plan(program)` at `:2799`), plus
physical/layout facts from the same whole-program descriptors
(`c_backend_physical.bend:1-30`). JS concatenates runtime + layouts + families
+ type functions + effects + codes + declarations + ending in one source
(`js_backend.bend:1157-1160`).

**[M-peer: SharedEmitterSteps]** generated emitter fragments are small: 1,645
handler definitions total 536,019 B with a 298 B median; only 30 definitions
exceed 8 KB. Per-definition rendering would mostly be bookkeeping, and the
fragments are not independent (sharing/physical facts).

### 2.7 Template expansion is a global fixed point

**[S]** `Template.expand` collects templates from every module, then
`generate_until_stable` runs rounds and appends generated declarations
(`template.bend:1147-1479`). A generated key is
`"T~" + SHA256(template key + serialized arguments)` with an `attempt` suffix
only if the key already exists in that module's top-level key list
(`template.bend:176-205`). Generation is therefore content-addressed (good)
but collision avoidance depends on the module's declaration key set (so
deleting/adding a declaration can rename a generated key in that module).
Expansion depends on referenced template definitions across modules; there is
no per-module "templates used" record today.

### 2.8 Foreign and runtime bytes

**[S]** A foreign definition's checked obligation is its declared signature;
the body is `DefImports{paths}` and `check_import_definition` only infers the
declared type (`checker.bend:10660-10673`, `9335-9348`). Catalog stores
`Foreign{sources, parameter_types, result}` and the target chooses by declared
extension at emit time (`lower_catalog.bend:1143-1154`,
`c_emit_core.bend:35-52`, `js_backend.bend` `js_source`). The bytes are read by
the CLI adapter (`c_emit.bend:64-85`, `js_link.bend`), not by checking.

**Incremental consequence [S/I].** Foreign `.js`/`.c` bytes need not invalidate
check or BIR; they must be part of the link/render key. Declared paths,
arities, quantities, and parameter/result types are BIR facts and do
invalidate BIR if changed. The C runtime template bytes are an emit input;
they need not invalidate check/BIR either, but are part of the render key.

---

## 3. Stage-by-stage incremental options

Each option names its key, invalidation, what it saves, and its constraints.
"Green" below means "reuse accepted, dependencies validated"; nothing is
green because it looks unchanged.

### 3.1 Parse / file-content cache — low difficulty

**Unit.** One file: real path + exact source bytes.

**Key [I].** `(realpath, SHA256(source bytes), parser version/compiler build
id, import-resolution inputs for package paths)`. `SHA256.hash` already exists
(`sha256.bend:164`). The loader already resolves and reads each file once
(`loader.bend:300-404`); it would consult the cache after resolution and before
`Parser.parse`.

**Invalidation.** Any byte change, path change, parser/compiler version change,
package-manifest or package-source hash change (already checked at
`loader.bend:148-166`).

**Saves.** Parse CPU/wall for unchanged files and avoids retaining a second
copy of parsed ASTs across runs (if persisted). The pinned root profile
attributes 45 s to parse, but that includes the parser oracle; the current tree
must be re-measured.

**Constraints.**
- Spans are absolute `(file, beg, end)` byte offsets (`ast.bend:3-4`). A
  whole-file content key makes cached spans valid; a definition-level cache
  after an in-file edit does not.
- Cross-process caching needs an AST encoder/decoder. There is no production
  one. The eval-side `bend-native-ast-v1` envelope
  (`evals/bootstrap_ast_transport.ts:12-18`) is an existence proof for a
  tagged, sharing-preserving JSON encoding of AST-like values, not a compiler
  API. A Bend-side encoder/decoder is new work.
- Import cycles, namespace conflicts, and missing-file errors must still be
  produced by the live loader, not skipped because a file was cached
  (`loader.bend:335-390`).
- In-process parse caching is much cheaper than on-disk: retain the
  `LoadedModule` values, no serialization.

**Verdict.** Best first increment. It is isolated from checking, cannot accept
a wrong semantic artifact, and directly removes repeated work for unchanged
import closures. It does not help a one-shot CLI invocation at all; it needs a
session/watch mode or a persistent cache directory to pay off.

### 3.2 Resolved-import cache — low–medium difficulty

**Unit.** `(source_file, import path, parent namespace, BEND_LIB/HOME,
package manifest hash)` → `(resolved realpath, child namespace)`.

**Why separate from parse.** Resolution performs path normalization, package
hash verification, namespace derivation, and cycle detection
(`loader.bend:195-275`, `300-404`). It is IO-heavy and answer-stable under
unrelated edits.

**Constraints.** The namespace-assignment conflict rule (one file must not be
imported under two namespaces, `loader.bend:342-355`) is a graph-level
property; a cached single resolution cannot waive it. Cycle detection is
per-load-path and must still run.

### 3.3 Template-expansion cache — medium difficulty

**Unit.** One module after expansion.

**Key [I].** `(raw module content hash, module top-level key list ordered,
used template canonical keys + each template's source content hash/signature,
expander version, Base interface version)`. Generated keys are content-hashed
(`template.bend:176-205`), which makes instance identity stable across
unrelated edits.

**Invalidation.** Raw module change; any used template's body/signature/imports
change; module key-set change (collision suffix); expander version change. A
template that is never referenced by the module cannot affect its expansion
(**[S]** templates are keyed by canonical key, and generated identity includes
only the template key and values).

**What is missing.** A per-module used-template set. Today expansion is a
whole-module fixed point (`generate_until_stable`) and does not record which
templates a module consumed. Recording this is a small expander change, but it
is new production code and must be audited for generated-generated instances.

**Saves.** Expansion CPU and the retained expanded AST for unchanged modules.
It is a prerequisite for a useful module-level check cache (checking consumes
expanded modules, not raw ones).

### 3.4 Module-level checked-artifact reuse, in one process — medium–high

This is the first option that would reduce *check* time, which is the dominant
stage. It is also where the architecture starts to bite.

**Proposed unit.** A module artifact:

```
expanded_module : IR/expanded Ast value
checked_module  : IR.LoadedModule (occurrences included)
globals         : List<Scope.ArenaGlobal> published by this module
metadata        : ModuleMetadata (namespace, path, scope, families)
arena watermarks: node/pattern/binder/word/natural/name counts at module end
```

plus the retained `source` owner and the accumulated `signatures`/`modules`/
`metadata` lists.

**Why it can work at all [S/I].**
- Source is append-only (`checker.bend:12722-12725`); no source rewind happens
  today. Published handles remain valid for the life of the owner.
- Modules are checked in loader finish order, dependencies first; each module's
  visibility is its own namespace + imports + Base (`checker.bend:1448-1455`).
- Only published source handles escape (`checked_frontend.bend:16-34`), so a
  cached module cannot contain transient garbage.
- `ModuleMetadata.scope` is a snapshot of the module's visible scope built
  from accumulated globals (`checker.bend:11133-11143`, `301-305`), so an
  unchanged module's metadata remains internally consistent if none of its
  dependencies changed.

**Conservative sound invalidation [I].**
- Dirty set := changed modules ∪ all modules transitively importing a changed
  module (reverse import closure).
- Any change to a module's *public surface* (declared signatures, datatype
  headers, quantity prefixes, aliases that change resolution) dirties the
  whole module and its reverse-import closure. Reason: predeclaration makes
  every signature in a module visible to every declaration in that module
  (`checker.bend:11195-11207`), so a later signature edit can invalidate an
  earlier declaration.
- A body-only change dirties the edited module and its reverse-import closure
  too, in the conservative initial cut. Reason: the body value is published and
  unfoldable (§2.4); a signature-only key is unsound. Later, a read-set
  refinement may narrow this to the definitions that actually unfolded it.
- Base changes dirty everything that imports Base (which is effectively all
  modules).
- Missing or unvalidated dependency evidence means dirty, never green.

**What must be built.**
1. A resumable check entry, e.g. `check_modules_from(prefix, dirty_modules)`,
   that accepts the existing owner + cached module artifacts and continues
   without calling `Arena.empty()` or re-packing the prefix. This is a new
   public API in `checker.bend`; the clean `check_modules` path stays exactly
   as it is.
2. Preservation of the predeclared header set and the `global_scope_size`
   boundary at the resume point (`checker.bend:11031-11045`,
   `1448-1462`, `1252-1258`). Reusing just "modules so far" is not enough.
3. A module dependency record (imports) and an invalidation engine.
4. Output-order preservation: keep the exact loader/declaration order for
   catalog and BIR assembly; do not topologically reorder for convenience.
5. A session owner for the arena. Because `CheckedProgram` is affine, the
   session must be the sole holder of `source`; diagnostics and failed checks
   must not consume it.

**The handle problem, and why append-only helps.** If an earlier module is
rechecked, its old publications remain in the arena and new publications are
appended. Cached *later* modules are not rechecked in the conservative scheme
(they are dirty if they import the changed module; unrelated modules do not
reference it), so their handles still point at valid, immutable, semantically
equal nodes. The stale copies are dead but unread. This avoids relocation at
the price of dead arena data for every recheck. A session that edits and
rechecks many times needs a compaction policy: after a threshold, rebuild the
whole program cleanly (the reference path) or start a new session.

**What it does not solve.** Cross-process reuse (needs serialization and
relocation), per-definition reuse inside a huge module, and all of catalog/BIR/
render. For the actual selfhost root, module sizes are coarse: `checker.bend`
has 1,208 top-level declarations, `checker_core_steps_v1.bend` has 5,050, and
`emitter_steps_v1.bend` has 3,442 (**[S]** static counts in this tree). An edit
that regenerates one of those modules dirties 3,000–5,000 definitions at once;
module granularity may not be enough for the compiler's real edit loop.

### 3.5 Dependency-tracked per-definition typechecking — very high

**What it needs.**
- A journal of what each definition actually read: every `Scope.lookup`,
  `lookup_kind`, global candidate enumeration, and every global unfolded by
  `whnf_ref_global`/`whnf_application_global`/`metadata_*`. The last group is
  what makes signature-only keys unsound.
- A stable fingerprint of each definition's checked result so red/green can
  distinguish "input changed but result identical" (the standard red-green
  false-positive problem; rustc's guide describes this and the try-mark-green
  algorithm).
- A way to compare results across arenas/sessions without positional handles:
  hash occurrence structure + symbol keys/kinds + normalized descriptor facts,
  not raw `U32`s.
- Preservation of predeclaration semantics and error behavior. A green
  definition must have had every dependency validated, including bodies it
  unfolded indirectly.

**Why it is not a small change.**
- `ArenaStore` is destructured explicitly throughout 15,792 lines of
  `checker.bend` (and the generated `checker_core_steps_v1.bend`); adding a
  read-set field is a cross-cutting mechanical change to the pipeline, not a
  wrapper. [I]
- The occurrence graph is *not* a read set: `checker_ir.bend:40-45` says it is
  "an occurrence graph, not a cache keyed by semantic node identity", and
  normalization can consult globals that do not appear as occurrence children.
  Using `Occurrence.symbol` as a dependency list would over-approximate some
  reads and miss indirect unfolds. [S/I]
- A transitive "symbols mentioned in the tree" closure still needs dynamic
  edges to be sound: if `A` mentions alias `B`, `B`'s body unfolds `C`, and
  only `C` changes, `A`'s cached result can be wrong unless `B` is red and
  redness propagates to `A`. That propagation is exactly the dependency DAG
  and per-result hashes that do not exist. [I]

**Verdict.** This is the rustc-query-system class of work, not a cache in front
of the checker. It should not be started before module-level reuse has
measured hit rates and shown that module granularity is the bottleneck.

### 3.6 BIR / render caching — high, and low value first

**Why BIR cannot be reused per definition today [S].**
- `Catalog.next_code` and `next_constructor` are sequential over all
  definitions/constructors; BIR ids follow them
  (`lower_catalog.bend:1192-1235`, `1274-1324`).
- `Needed` type functions are derived from reachability from main/exports
  (`lower_catalog.bend:844-869`, `1017-1042`), so adding an unused definition
  need not change type functions, but adding a reachable one can.
- `DescriptorNf.nf_context` receives the whole family/type-function tables
  (`lower_catalog.bend:1430-1466`); normalized descriptors are embedded in BIR
  declarations, constructors, families, and the ending.
- C emit computes a whole-program `SharingPlan` fixed point and physical
  facts; JS emits numeric code names. A per-definition fragment is not a
  function of that definition alone.
- `BIR.Program` includes every catalog definition; there is no module field or
  liveness split (`backend_ir.bend:233-238`, `backend_lower.bend:1737-1758`).

**Sound options, in increasing ambition.**
1. **Build-artifact cache.** Key on a full semantic/build fingerprint (source
   closure + compiler/target/runtime + foreign bytes) and store the final
   C/JS text. Sound and simple; only helps identical rebuilds/branch switches,
   not edits. This is not incremental compilation.
2. **Stable symbolic IDs.** Give every code/constructor/family a stable key
   (the canonical string keys already exist in `DefinitionHeader.key`,
   `ConstructorLayout.key`, `Family.key`) and assign numeric ids only at
   assembly. Then per-definition BIR text fragments can be cached and
   relocated, provided the sharing/physical facts are either frozen per
   fragment (conservative, changes output) or recomputed globally (then the
   cache only saves text generation, which peer measurements say is small).
3. **Separate compilation/linking.** See §3.7.

**MLIR/LLVM/WASM cross-check.** [M-peer: MLIRBackendResearch] MLIR symbol
tables provide name-based identity, not stable numeric ids, and MLIR IR
versioning is bytecode-only/opt-in; a separate-compilation route cannot inherit
id stability from MLIR. [M-peer: WasmWasiResearch] the WASM note assumes one
whole-program wasm module with program-global U32 ids and one table/segment/
static image, matching current BIR; linking multiple Bend modules is a
compile-time join, not wasm object linking. [M-peer: LLVMBackendResearch] the
LLVM note likewise assumes whole-program BIR and one output module, and adds a
concrete ABI fact: `c_backend_link.bend` resolves `CID(<key>)`/`FID(<key>)`
effect-source spellings against whole-program maps into per-program numeric
macro ids, and the export ABI (`BEND_EXPORT_NAMES` strings but
`BEND_EXPORT_ENTRY[]` numeric, `bend_export_call(i, ...)` by index) already
depends on one program's numbering. So no backend switch removes the
stable-ID/table-ABI prerequisite.

### 3.7 True separate compilation / linking — very high, architectural

Minimum requirements, all absent today [S]:

1. **A module boundary in BIR.** `Program` has no module identity; declarations
   are a flat list keyed by string.
2. **Stable exported/imported symbol identity and calling convention.** String
   keys are a good start, but BIR values/codes use numeric ids and C/JS
   references use `FID_*`/`CID_*` or numeric code names.
3. **A runtime-table ABI split.** The C runtime template has four marker
   sections filled as one unit: Tables (`CID_T`, `FID_T`, `STAT_LEN`, `WL_*`,
   `MAIN_FID`, …), Spins (`STAT_IMG`), Segments (`WL_CASE`), Requests
   (`c_backend.bend:11-49`, `3201-3206`). Separate objects need agreed extern
   declarations/sections and a link step that merges/renumbers them. The
   export ABI is already numeric (`BEND_EXPORT_ENTRY[]` and
   `bend_export_call(i, ...)` by index), so external consumers would either
   freeze those indices or move to string-key indirection/global allocation
   (**[M-peer: LLVMBackendResearch]**).
4. **Whole-program facts resolved at link.** Sharing/hotness, constructor
   layouts, family/type-function tables, reachability/liveness, `Ending`
   (executable vs library) (`backend_ir.bend:226-238`).
5. **Foreign object linkage.** Foreign sources are currently spliced as text
   with id rewriting, not compiled as independent objects (`c_emit_core.bend:
   93-114`, `js_backend` link).
6. **Deterministic link order and diagnostics.**

This is a multi-quarter architecture, and it still needs a modular checking
story: dependent types, body unfolding, datatype kinds/quantities, and type
functions mean a module interface is not just a signature list. It should not
be justified only by build time; it changes the language implementation's
admission model. The brief's constraint stands: no new architecture commitment
here.

---

## 4. Conservative initial design (recommended if/when authorized)

This is a design sequence, not an implementation. It keeps the clean full build
as the reference and never makes an unvalidated artifact green.

### 4.1 Version and content keys

Every cache entry, in every phase, carries:

- `cache_schema` (format version; a stale entry is rejected, never repaired),
- compiler build/version key (the selfhost steps/compiler image hash, not just
  a branch name),
- parser version, expander version, checker version, catalog/BIR version,
  target (`js`/`c`), runtime template hash,
- relevant source content hashes and package manifest hashes,
- for render entries, foreign bytes hashes.

There is no such version constant in the current driver
(`driver.bend:1-204`); adding one is a prerequisite even for a parse cache.

### 4.2 Invalidation rules (initial, deliberately coarse)

1. Parse entry valid iff path + exact bytes + parser/version keys match.
2. Import-resolution entry valid iff source file/import path/parent namespace/
   `BEND_LIB`/manifest hash match; graph-level cycle/conflict rules always run.
3. Expansion entry valid iff raw module bytes, module key list, used-template
   set, each used template's full content/signature, and expander/version keys
   match. Changing a module's key set can change a generated key suffix, so it
   is a miss.
4. Check entry valid iff expanded module bytes/value, all imported modules'
   accepted check keys, Base accepted key, template dependency set, checker/
   version keys match, and the module's public surface did not change. In the
   first cut, *any* body or signature change also dirties the module and its
   reverse-import closure, because body values can unfold into types.
5. Catalog/BIR/render entries: key on the full accepted upstream key plus
   target/runtime/foreign bytes; no per-definition green in the first cut.
6. A failed check produces no green entry. Retain the last good prefix and the
   failing module's identity; on a fix, dirty the module and its reverse-import
   closure.
7. Missing dependency/version evidence = dirty.

### 4.3 Order preservation

**[S]** Catalog prepends definitions and reverses at build finish
(`lower_catalog.bend:1453-1466`); constructors/families are built in
declaration order; template generated keys use an attempt order
(`template.bend:176-205`). Any incremental assembly must reproduce the clean
build's module list and declaration order exactly. Do not use map iteration to
order output, and do not re-sort modules topologically if the clean loader
would have emitted a different order. If a dirty subset is rechecked, splice it
back into the original module positions before catalog construction.

### 4.4 Reference and acceptance

The clean build remains the reference for every acceptance test. Incremental
mode is opt-in, can always be disabled, and must produce byte-identical
targets and identical diagnostics for the same effective inputs. A cache hit is
never evidence of correctness; it is an optimization that must be followed by
the same output comparison a clean build gets.

---

## 5. Cache memory trade-offs

**[I, grounded in the types]** The checked artifact is large per unit: source
arena arrays of nodes/patterns/binders (each node carries a tag, children,
`Nat` index, name id, and a `SourceSpan` with a file `String` and two `Nat`s),
plus occurrence trees, signature lists, scope indexes (persistent maps of
buckets), and metadata scopes. There is no measured retained-byte number for
any of it in the new pipeline. The only measured memory facts are the official
producer's Book/FL numbers (§1.1).

Consequences:

- **In-process prefix reuse:** extra memory is the retained prefix (already
  live in a normal build until emission) plus dead publications from rechecks.
  No serialization cost; the cost is unbounded session growth unless compacted.
  For a one-shot CLI this buys nothing; it needs a watch/server/LSP lifecycle.
- **On-disk checked artifacts:** likely the largest and most complex cache.
  Without a per-module retained-byte measurement, budgeting is guesswork. The
  serialization cost may exceed the recheck cost for small or frequently dirty
  modules. Every entry needs a schema/version reject path and a size/LRU policy.
- **Parse/expansion artifacts:** much smaller and self-contained; a better
  first on-disk investment. Still need an encoder/decoder and version key.
- **Final text cache:** large but simple; keyed by a full build fingerprint; LRU
  by target. Only exact rebuilds hit.
- **GC interaction:** large retained Data trees increase GC pressure; the
  pinned check profile already shows 7.1 % GC self-time. A cache that retains
  more than it saves can lose. This must be measured, not assumed.

**[M-peer: NativeCodegenMemory]** the official codegen's lowest observed process
`heapUsed` after its reported drops rose ≈50 MiB per pass (1,993.5 → 2,240.3
MiB over passes 1–6) before the pass peak. That is a heap-accounting
observation, not proof that ≈50 MiB is retained: the GC type and the
retained-byte provenance were not observed, and per-definition deltas are
GC-polluted. A frontend cache does not address this growth.

---

## 6. Why frontend incrementality does not fix the official whole-program C OOM

The current build blocker is the **official TS producer** checking/emitting the
native selfhost binary, not a selfhost C-target semantic failure
([M-scoped, Main]: 11,164 native-bridge bodies, book heap 1,669,811,048 B,
reaches pass 6, OOM, no native artifact). The scoped `--trace-c` row naming
`c-pass-6` places the failure in `compile_book`, after `book_valid`.

Why a selfhost FIR/BIR cache cannot fix it:

1. **Different input and different compiler.** `compile_book` consumes a
   `Bend.Book` of lowered/checked bodies (`bend2/bend.ts:319`, `2484`,
   `3804`), not `CheckedProgram` or `BIR.Program`. A cached FIR/BIR artifact
   from `bend2/selfhost` is not accepted by `bend2/comp.ts`.
2. **Whole-program emission is structural.** `compile_book` clears its fact
   caches and re-emits every definition on every fixed-point pass
   (`bend2/comp.ts:3121-3155`); segments, spins, reachability, `FID`/`CID`
   tables, and the single C translation unit are program-global. The Book
   itself retains every lowered body (`bend2/bend.ts:2484`) and `book_valid`
   walks the whole order (`:3804-3810`).
3. **Measured heap minima move in codegen, retention unproven.** **[M-peer:
   NativeCodegenMemory]** the lowest observed process `heapUsed` after reported
   drops rises ≈50 MiB/pass; the checked book alone is 1,592.5 MiB of a
   3,033.7 MiB death footprint. GC type and retained-byte provenance were not
   observed, so this is not an attribution of retained bytes. Avoiding
   reparsing or rechecking does not cap the per-pass working set or the
   retained Book.
4. **Single-TU requirement.** Even with a perfect incremental frontend, the
   official C producer must assemble all segments/tables into one C file; a
   frontend cache does not create separate objects or a link step.

What *would* address it is orthogonal: reduce the official Book/codegen
working set (stream/dispose per-definition lowered bodies, stop re-emitting
unchanged definitions across passes), split codegen into objects with a stable
table/link ABI, or move the producer to a pipeline that can compile the root
within the guarded envelope. None of those is a frontend cache. This note takes
no position on which to do.

---

## 7. Behavioral acceptance scenarios

These are the tests any future incremental implementation must pass. "Clean"
means a fresh full build in a new process/session; "incremental" means the
sequence of cached runs. Every case compares target bytes and diagnostics, not
just exit status. All expected invalidations below are conservative and
grounded in §2.

| # | Edit | Must invalidate | May stay green | Observable acceptance |
|---|---|---|---|---|
| 1 | Body of `F` changes; `F` is mentioned in a type in module `N`; signatures unchanged | `F`'s module and all transitive importers, including `N`; catalog/BIR/render from the first affected definition | parse/expand of unrelated modules; modules not in the reverse-import closure | incremental output == clean output (possibly different from the old output); same diagnostics; a test where the old signature-only key would wrongly pass must fail to reuse |
| 2 | Public datatype changes: parameters, kind, fields, quantity of a field/parameter | defining module (all declarations, because headers are predeclared), reverse-import closure, catalog families/constructors/layouts, BIR, render | unrelated modules' parse/expand | same family/constructor/layout behavior as clean; no cached C fragment with the old layout; quantity/affinity diagnostics identical |
| 3 | Import alias changes, or an import resolution changes (same local syntax) | module and importers if resolution target or canonical mapping changes | only modules with identical resolved mapping and no alias-sensitive syntax | references resolve to the same canonical symbol as clean; readback/diagnostics use the same source names; a test where alias change alters shadowing fails reuse |
| 4 | Only source offsets shift (insert a comment/blank lines above code) | parse (byte hash), expansion/check artifacts carrying spans, diagnostics | no artifact whose spans are stale may be reused | diagnostics/reporting point at the new offsets; inserting a comment cannot change target bytes other than via nothing; if a semantic-only cache is used, span rebasing must be proven, otherwise it is a bug |
| 5 | Definition deleted | its module (key set, predeclared headers, published globals), reverse-import closure; catalog/BIR | unrelated modules | clean and incremental agree on the "unknown name"/missing-definition diagnostic and on the new target; no stale global is resurrected; generated-key suffix behavior matches clean |
| 6 | Error → fix: first run fails in module `M`; fix `M` | `M` and its importers; no green entry for the failed run | prefix before `M` if retained and validated | first-run diagnostics identical to clean; after fix, output identical to clean; a still-broken edit produces the same diagnostic, not a stale one |
| 7 | Foreign `.js`/`.c` bytes change, declaration unchanged | link/render key (bytes hash); not check/BIR | check and BIR, if declared paths/signature unchanged | new bytes appear in output; target selection by declared extension unchanged; missing-target error identical; a JS and a C run from one check must not silently share stale bytes |
| 8 | Target/runtime version changes (`--runtime-c`, JS runtime, target extension) | render key for that target; BIR only if the compiler ABI/primitive/layout semantics changed | check; BIR if ABI unchanged | clean output for the new target/runtime == incremental output; no cross-target cache bleed; version mismatch is a miss |
| 9 | Unrelated module changes (no import path to/from the edited module) | that module and its reverse-import closure; catalog/BIR/render, because they are whole-program and include all definitions | check of the unrelated module | no recheck of the unrelated module (hit), but target bytes are compared against clean for the *new* program; do not assert the old target is unchanged |
| 10 | Clean vs incremental determinism | nothing (test) | — | clean run twice yields identical target SHA-256 and diagnostics; incremental after an edit sequence matches clean at every step; module/declaration order, generated keys, code/constructor numbering, and map-derived lookups are stable |

Additional admission checks:
- A cache hit with a missing/unknown dependency or version key must be a miss
  (inject a missing key in a test).
- A cached artifact must never bypass duplicate detection, signature/body
  validation, affine/quantity checks, termination checks, or foreign
  signature checks (`checker.bend:11088-11131`, `10710-10758`,
  `10469-10560`).
- `book_valid`-style whole-book admission remains the reference for the
  official producer; an incremental selfhost build does not certify the
  official Book.

---

## 8. What existing FIR/BIR helps with, precisely

### FIR helps

- Ownership/lifetime is already incremental-friendly: one `source` owner, a
  per-declaration transient, and a documented rule that only published handles
  escape (`checked_frontend.bend:16-34`, `checker.bend:12722-12725`). An
  in-process cache cannot be poisoned by transient state.
- `Arena.mark`/`rewind` give exact truncation semantics for the transient, and
  a generation counter that invalidates mixed-owner indexes
  (`checker_arena.bend:82-97`, `1154-1305`).
- Module metadata and per-module signature lists are explicit values
  (`checker.bend:11133-11143`), so a module-level cache unit already has a
  natural shape.
- Symbols carry `(owner, local, kind)` strings (`checker_ir.bend:32-39`), which
  are a plausible basis for stable dependency keys; the `signature: U32` field
  is the part that is not stable.
- Declaration order and predeclaration rules are documented in the code
  (`checker.bend:11159-11207`, `11031-11045`), so a resumable entry can be
  specified against real semantics rather than guessed.

### FIR hurts

- Positional `U32` semantic-arena handles inside checked artifacts; no stable
  ID for those handles, no relocation table, no arena serialization. Canonical
  keys, owner/local names, and import paths are `String`s; BIR declaration/
  constructor/family labels are string keys with separate numeric code and
  constructor ids, so the stable-ID problem is specific to the semantic arena
  and to the BIR numeric references, not to every identifier in the system.
- No dependency journal; `ArenaStore` has no read-set slot, and normalization
  unfolds bodies.
- Occurrence trees are explicitly not cache keys (`checker_ir.bend:40-45`).
- Spans are absolute byte offsets embedded in nodes; in-file edits make cached
  spans stale.
- One affine owner means a cache session must be designed around ownership, not
  bolted on as a side table.

### BIR helps

- It is a clean, target-neutral seam with explicit tables (`families`,
  `type_functions`, `constructors`, `codes`, `declarations`, `ending`) and
  string keys for declarations/constructors/families
  (`backend_ir.bend:203-238`).
- Foreign declarations retain all declared alternatives, so target selection is
  a link/render concern, not a semantic one (`backend_ir.bend:209-215`).
- Descriptor normalization is centralized in `descriptor_nf.bend` rather than
  duplicated per target, so a future dependency design has one place to
  instrument.

### BIR hurts

- Whole-program sequential ids (`next_code`, `next_constructor`), no module
  boundary, no liveness split, one C translation unit, whole-program sharing
  and physical facts.
- BIR embeds already-normalized descriptors and type-function bodies derived
  from reachable definitions; a cached fragment is not independent.
- Numeric code names in JS and `FID`/`CID` tables in C make text fragments
  non-relocatable without a new stable-ID/link layer.

---

## 9. Soundness traps to write into any future design review

1. **Signature-only keys are unsound** for the reasons in §2.4. Do not let an
   API named `signature_hash` become a cache key for checking.
2. **Occurrence symbols are not a read set.** They are a useful over-
   approximation seed, but normalization can read globals not represented as
   occurrence children; indirect alias/type-function chains need dynamic
   propagation.
3. **A definition's checked result can depend on a body via normalization**
   even if the definition's own text and signature are unchanged. Red-green
   must propagate through the actual read edges, not through declared imports
   only.
4. **A module's own later signature can invalidate its earlier declarations**
   because all signatures are predeclared before checking
   (`checker.bend:11195-11207`). "Suffix from the edited declaration" is valid
   for body-only edits only if the predeclared header set is unchanged, and
   only for the new checker (see trap 6).
5. **Generated template keys depend on the module key set** for collision
   suffixes (`template.bend:176-205`); adding/deleting an unrelated declaration
   can rename a generated key. Treat key-set changes as expansion dirt.
6. **`unsafe` is not a body-visibility mechanism in the new checker.** The
   official Book says `@unsafe` permits a live forward reference to a bodiless
   def (`bend2/bend.ts:3779-3804` comment). The new checker publishes
   predeclared signatures with `IR.NoTerm` (`checker.bend:10675-10688`) and
   uses `unsafe` only to bypass structural termination and to relax `QMany` to
   `QOne` (`check_termination`, `checker.bend:10470-10483`;
   `domain_quantity`, `checker.bend:1199-1209`). So *in this checker* an earlier
   declaration cannot read a later body, and a body-only edit may one day use a
   suffix rule. Do not transfer that claim to the official Book or to a future
   `@unsafe` change without re-reading the semantics. Conservative module
   invalidation avoids the question entirely.
7. **Diagnostics are part of the output.** A cached semantic artifact with stale
   spans is a correctness regression even if the target bytes match.
8. **Failure is not green.** A failed check has no `CheckedProgram`
   (`checked_frontend.bend:22-28`); never cache a failure as a reusable
   artifact or assume the prefix after the failure was validated.
9. **No source rewind in the middle.** Source is append-only; rewinding it
   would delete cached handles and invalidate later modules. Use a new arena
   (clean rebuild) or append.
10. **Order is part of determinism.** The catalog reverses prepend lists and
    preserves declaration order; template attempts are order-sensitive; do not
    reorder modules or definitions for incremental convenience.

---

## 10. Recommended safe order of work

No step here is authorized by this note; it is a dependency order for later
decisions.

1. **Decide the unit and the contract (documentation only).** Choose parse →
   expansion → module check as the first chain; write down keys, invalidation,
   order preservation, and the clean-vs-incremental acceptance suite from §7.
   Keep "clean full build is the reference" as a hard rule.
2. **Measure on the current tree (separately authorized).** On `f46ad0f6`,
   record: per-module parse/expansion/check wall and CPU; retained heap of a
   `CheckedProgram` and of one module artifact; catalog/BIR/render time and
   bytes; one clean output SHA-256. Without these, do not size or promise a
   cache. The existing profiles are source-pinned and diagnostic-only.
3. **Parse cache (in-process, then optional disk).** Lowest risk. Add a
   version key and an AST encoder/decoder only if disk persistence is chosen.
   Do not add a cache directory without a schema/reject path.
4. **Expansion cache.** Record per-module used-template dependencies; treat
   module key-set changes as dirt. This unlocks module-level check reuse.
5. **Session-scoped module check reuse.** New resumable entry; append-only
   arena; conservative reverse-import invalidation; whole-module recheck on any
   signature or body change in the first cut; preserve order; compare output
   against clean for every scenario. Stop and measure hit rate, recheck cost,
   and memory before going finer.
6. **Only if module granularity is insufficient:** per-definition read-set
   journal + result fingerprints (major checker work), then stable BIR ids and
   fragment caching, then separate compilation. Each needs its own design note
   and acceptance suite; none is justified by the current measurements alone.

Things not to do yet, for the record: a generic query framework; an `Arena`/
`CheckedProgram` redesign; an on-disk checked-artifact cache; per-definition
C/JS fragment caching; an LLVM/MLIR switch as a way to get incrementality;
changing `bend2/comp.ts` or the official Book semantics; using cached artifacts
to skip duplicate/signature/affine/termination/foreign admission.

---

## 11. Next tasks (bounded, evidence-producing)

1. **Current-tree phase receipt (heavy-gate authorized separately).** Reuse
   the existing RootABI root/parser/body reports when their source/compiler pin
   still matches; do not rerun unchanged source for a docs-only change. Run a
   fresh selfhost root build only when the pin changes, with the existing
   `NATIVE_PHASE`/profile hooks; record parse/expand/check/emit wall+CPU and
   peak footprint/RSS. Acceptance: a receipt that names the exact source and
   compiler image hashes, not a branch. This baseline is still missing for any
   incremental claim.
2. **Per-module cost census.** For each module in the root import closure,
   record source bytes, declaration count, expand time, check time, and
   retained bytes (if a non-invasive observer exists). No production
   instrumentation is required for counts/bytes; retained bytes may need a
   separate authorization. Acceptance: a table that shows whether module-sized
   units are economically useful for the compiler's real edit patterns (huge
   generated step modules are the risk).
3. **Official producer memory decomposition (read-only trace reuse).** Reuse
   the existing `--trace-c` rows and peer pass-level facts to separate Book,
   stable FL facts, current-pass segments, and one-definition memo. No new run
   if the trace is sufficient. Acceptance: a table that says which component
   must shrink for the pass-6 OOM, and explicitly confirms frontend caching is
   not that component.
4. **Cache-key design review (doc only).** Produce the key/invalidation table
   for parse, expansion, and module check, including version/schema and
   determinism rules; review against §7. No code.
5. **`@unsafe` forward-reference semantics (read-only record).** The new
   checker does not publish a later body value to an earlier declaration;
   `unsafe` bypasses termination and relaxes `QMany` only
   (`checker.bend:10470-10483`, `1199-1209`). Record the official Book's
   different wording (`bend2/bend.ts:3779-3804`) and the rule that the two
   pipelines cannot share an invalidation assumption. No code.
6. **Template dependency recording design (doc only).** Specify what the
   expander would have to record per module to make expansion caching sound;
   include generated-generated instances and key-set collision behavior. No
   code.
7. **A "green means validated" audit checklist.** Enumerate every admission
   check in the checker and the catalog, and state which cached artifact could
   bypass it. This is the safety net for any future implementation.

If only one follow-up is funded, fund #1. Every incremental decision in this
note is currently limited by the absence of a current-tree, per-stage
CPU+memory baseline, not by a lack of architectural options.

---

## 12. Sources and pins

Local, read in this worktree at `f46ad0f6` (unless a different pin is named):

- `bend2/selfhost/checked_frontend.bend:16-34` — `CheckedProgram`, owner
  transfer, diagnostics.
- `bend2/selfhost/checker_ir.bend:32-77`, `:88-96` — `Symbol`,
  `Occurrence` comment, `Definition`, `DefinitionFacts`, handle tags.
- `bend2/selfhost/checker_arena.bend:82-97`, `:1154-1305` — `Arena`, pools,
  mark/rewind, cache invalidation, rewind generation.
- `bend2/selfhost/checker.bend:255-329` — `metadata_sort`/`metadata_prefix`/
  `definition_classify`; `:9335-9348` foreign check; `:1036-1037`,
  `:1327-1425` scope segments; `:1448-1462` `visible_globals`/
  `declaration_visible_scope`; `:1481-1540` global unfolding/beta;
  `:10469-10560` definition publication with `SomeTerm`; `:10660-10708`
  body check; `:11031-11145` per-declaration rewind/publication;
  `:11159-11220` predeclare/check modules; `:12690-12725` source-immutable
  comment; `:12792-12798` case-prefix rewind; `:13031-13034` `arena_release`;
  `:15059-15091` entry/`check`.
- `bend2/selfhost/scope_lookup.bend:13-31` — `ArenaGlobal`, scopes.
- `bend2/selfhost/lower_catalog.bend:12-39` — catalog/preparation types;
  `:844-869` type functions from definition bodies; `:1017-1042` roots;
  `:1143-1163` foreign/fast/primitive; `:1192-1324` id assignment;
  `:1394-1466` module prep and build.
- `bend2/selfhost/backend_lower.bend:1737-1758` all-definition lowering;
  `:1951-1965` lowering entry.
- `bend2/selfhost/backend_ir.bend:203-238` — code/declaration/program.
- `bend2/selfhost/c_backend.bend:11-49`, `:3173-3206` — one C TU and ABI;
  `c_backend_sharing.bend:1-45`, `:2799` — whole-program sharing plan;
  `c_backend_physical.bend:1-30` — physical/layout facts.
- `bend2/selfhost/js_backend.bend:657-660`, `:1157-1160` — numeric code names,
  one concatenated program; `js_emit.bend:1-40`.
- `bend2/selfhost/template.bend:20-26`, `:73-105`, `:176-205`, `:1147-1479`
  — template definitions, collection, content-hashed keys, global fixed point.
- `bend2/selfhost/loader.bend:148-166`, `:195-275`, `:300-404` — package hash,
  resolution, DFS work loop; `sha256.bend:164`.
- `bend2/selfhost/ast.bend:3-97` — spans and AST; `path.bend:1-60` —
  normalization.
- `bend2/selfhost/driver.bend:1-204` — one-shot pipeline; `hybrid_driver.bend`
  — already-parsed JS-only path.
- `bend2/selfhost/c_emit.bend:64-85`, `c_emit_core.bend:35-114` — foreign
  path selection and passive bytes; `js_link.bend` — JS link.
- Official producer: `bend2/bend.ts:319` Book; `:952-1017` `book_load`;
  `:2484` eager `body_flatten`/lower; `:3779-3810` `book_valid`;
  `bend2/comp.ts:3110-3155` `compile_book` whole-program fixed point;
  `evals/native_compiler_experiment.ts:34`, `:59`, `:149-224` — no AST
  serialization/cache, guard, progress/trace; `evals/native_compiler_host.c:
  43-53,113` — `NATIVE_PHASE`, `ru_maxrss`, chunk 64.
- Profiles: `evals/selfhost-root-phase-profile-57ab.json` (pin `d47f859b`,
  diagnostic only); `checkpoints/compiler-profiling-quality-v51.json` (pin
  `7c33172b`, v49); `evals/selfhost_cpu_profile.mjs:39-46` (1 ms CPU, 4 MiB
  allocation); `checkpoints/book-phase-attribution.json` (load blocker, older
  pins).
- Peer measurements cited with attribution: NativeCodegenMemory (lowest
  observed process-heap `heapUsed` after reported drops, Book/FL byte values;
  GC type/retention provenance unobserved; no isolated per-module bytes);
  SharedEmitterSteps (fragment sizes, non-independence); MLIRBackendResearch
  (name-based MLIR symbols, versioning); WasmWasiResearch (whole-program wasm
  module, no per-module objects); LLVMBackendResearch (whole-program, numeric
  export ABI).

External primary background, used only for the standard red-green vocabulary:
the rustc-dev-guide chapters "Incremental compilation" and "Incremental
compilation in detail" describe query DAGs, try-mark-green, result hashing, and
the stable-ID problem for persisted caches; they are the reference for why a
signature-only or direct-edge-only invalidation is insufficient, not a design
template for this codebase.

---

## 13. Bottom line

- **Incremental compilation is feasible first at the parse/expansion boundary
  and then at module granularity in one live process.** The ownership model
  already supports this: only source-published handles escape, and source is
  append-only.
- **The hard parts are identity and dependency precision, not caching
  machinery.** Positional semantic-arena handles, no stable IDs for them, no
  serializer, and no read set are the blockers. Cross-process reuse and
  per-definition checking are separate, much larger projects.
- **BIR/render caching is not the first move.** Sequential global ids,
  whole-program sharing/layout facts, and tiny non-independent emitter
  fragments make it low-value until stable IDs and separate compilation exist.
- **Do not use textual signatures as the key.** Bodies unfold into types, and
  reachable definition bodies become BIR type functions; a signature-only key
  is unsound.
- **Frontend incrementality does not fix the official pass-6 C OOM.** The OOM
  is in the official whole-program Book/`compile_book` path, which consumes a
  different representation and emits one C translation unit; its measured live
  floor grows ≈50 MiB per pass and the checked Book is already ≈1.59 GiB.
- **We do not yet have the per-stage memory numbers to size a cache.** Get the
  current-tree phase/per-module receipt first; keep the clean full build as the
  reference and every cache opt-in, validated, and byte-comparable.
