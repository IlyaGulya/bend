# Changelog

Each release names what changed for a user. `bend update` installs the
latest one; the GitHub release carries the same notes.

## Unreleased

- Native and JavaScript word-pattern coverage compares the required lowered
  structure lazily, avoiding complete temporary trees for discarded annotations
  and unequal suffixes while preserving binder identities and coverage behavior.

- JavaScript source quoting no longer repeatedly copies a growing string prefix
  on native backends. Each bounded escape is prepended to the escaped suffix;
  escape bytes and character order are unchanged.

- Native compiler builds can explicitly select `--cc-pipeline=llvm-split` on
  Darwin arm64 with Apple clang21 and matching LLVM21 tools. Four bitcode
  partitions use at most three backend children under the unchanged whole-build
  memory/deadline guard. Each stage records real CPU, wall time, maximum RSS and
  tool/ABI provenance; direct compilation remains the default, without fallback.

- Native heterogeneous continuation stacks run inside checked Bend chunks.
  Node and C consume opaque Run states or one-use native view thunks; public
  export names/count remain ten (nine for subsets). Phase trace version3
  counts chunk advances, not historical request/resume boundaries. Frozen-v41
  remains an explicit historical input. Emitted-stage suites require independent
  SHA256/byte-count pins and retain full native/source/parser/span authentication.
- The owning FIR → Backend IR compiler cutover has a complete native-validated
  root, a new unchanged stage1/stage2 byte fixedpoint and all285 required
  seed/stage1/stage2 behavior executions. The aggregate 600s gate remains an
  honest deadline failure; separate complete behavior evidence does not waive it.
- Explicit constructor eliminators in that pipeline produce callable matchers
  instead of eagerly evaluating the fallback. A program rejected at runtime
  by the unchanged previous stage-one output now executes as `BitOne{}`.
- The selfhost parser accepts unsigned and finite F32 literal patterns through
  the shared expression-literal decoder, including nested and multi-scrutinee
  patterns. Natural-prefix adjacency rules are unchanged. Full parser semantic
  and literal-span parity passes all75 current cases.
- Compiler diagnostics compare the complete frozen source closure and the actual
  unmodified official public export set, with phase timing, resource limits and
  emitted-compiler smoke recorded separately from genuine bootstrap acceptance.
- Native C compilation compares canonical shared layouts by identity and releases
  rebuildable body caches between top-level definitions, retaining checked terms.
  Weak telescope caching reuses live signatures without retaining temporary types.
- Selfhost syntax shifting, substitution and operator-name rewriting use direct
  list traversals instead of copying an unsafe capture-bearing affine callback.
- Parser continuation preparation discovers newly mutual-recursive components
  from the current source graph and sequences multiple nested calls while
  preserving typed lexical captures and affine rejection.
- Checker application-type views retain unchanged application and annotation
  nodes, and reuse referenced nodes beneath bangs instead of copying them.
  Fresh remote acceptance checks the complete root and all273 fixture executions;
  unchanged emitted stage-one/stage-two JavaScript bytes match exactly.
- Selfhost scope lookups and canonical-name queries execute as native-checked
  Bend provider functions instead of request/continuation chains, preserving
  family/kind precedence, alias fallback and nested unsafe-scope behavior.
  Name equality shares one implementation and skips canonicalization for
  identical names while preserving alias and shadowing behavior for distinct ones.
- Exact-arity named JavaScript library exports enter their checked uncurried
  bodies directly; partial/over-applied calls keep the curried fallback and
  internal calls retain their existing bounded trampoline protocol.
- Diagnostic step counters recognize the selfhost emitter's callback names and
  preserve each checker pass in a separate write-once file, so output smokes
  cannot overwrite full-workload measurements.
- Selfhost lambda bodies use the existing block grammar, including local
  definitions and matches. Local-name lookahead no longer treats an equals
  inside a lambda as an outer assignment; quantity and lexical scope are retained.
- Selfhost compiler steps execute bounded checked-Bend chunks with an affine
  result carrier and explicit continuation stack, preserving semantic reduction
  fuel. The updated JS compiler reaches a full stage-one/stage-two byte fixedpoint;
  this does not certify the separate native C orchestration path.
- Native selfhost orchestration reconstructs flattened result carriers before
  resuming continuations or entering final typed adapters, fixing invalid memory
  access across the C boundary. Full-corpus native compile and output execution
  now pass; runtime experiments stop at the five-minute target.
- Native progress reflection executes another bounded checked chunk before
  returning work to the C continuation driver. Full-corpus native output and
  actual emitted exports/parser/checker execution remain identical.

- The complete selfhost parser/Template/Checker/JavaScript compiler root now
  reaches an exact stage-one/stage-two byte fixedpoint using its own emitted
  parser and compiler steps. Original semantic/error fixtures and additional
  Unicode, escape, custom-constructor and dependent string cases pass on the
  seed and both emitted stages; this does not certify the legacy full-IO/C driver.
- Selfhost string literals retain compact UInt32 codepoints and their constructor
  identities instead of eagerly allocating a 32-bit syntax tree per character.
  Compact checking proves the actual constructor schema; unsupported schemas
  keep ordinary constructor checking and emission, including unused-constructor
  behavior for empty strings. Semantic/span transport validation remains complete.
- Saturated named JavaScript tail calls batch a bounded number of direct calls
  before yielding to the trampoline, avoiding intermediate argument arrays.
  The private depth parameter preserves function arity; curried calls and foreign
  callbacks retain their existing interface. The complete compiler root still
  reaches an unmodified byte fixedpoint on both emitted stages.
- JavaScript function and case bodies emit local bindings and nested matches
  directly in lexical blocks instead of immediately invoked wrapper functions.
  Evaluation order, erased operands and branch-binding snapshots are preserved.
- Typed compiler steps use an authenticated scalar Bool scheduling token instead
  of a fresh Unit record; the dependent Direct invocation interface is unchanged.
- Checker arena word reservation initializes the same zeroed range while
  publishing pool metadata once, rather than rebuilding the arena per word;
  discarded capacity is still zeroed before reuse.
- Saturated native-law calls reuse the checked uncurried primitive entry, with
  the same erasure and arity rules as its declaration; partial applications keep
  the existing callable interface.
- Emitted closures use one callable for strict calls and private-symbol
  trampoline entry, instead of allocating an additional forwarding closure.
  Foreign callbacks may still receive ordinary extra arguments.
- Bootstrap loading reuses the original immutable parser tree after complete
  native semantic/span approval, instead of rebuilding it from transport.
  Both transport-validation passes and the pre-use transport hash check remain.
  Fresh parsing may run one module ahead of the serial native oracle; every
  admission completes before any parsed module enters expansion or checking.
- Source parser symbol combination uses a tail-recursive reversed prefix, avoiding
  JavaScript stack growth with the number of tokens while preserving merged
  symbols, source order and spans.
- Source template expansion reuses immutable constructor-only syntax subtrees
  whose leaves are unchanged by expansion, instead of copying each Word bit and
  string character. References and transforming syntax retain ordinary expansion.
- Native compilation shares immutable datatype layouts within each book; field
  offsets no longer mutate when a layout is packed. Signature arity is independent
  of demand-driven C ABI layouts, and saturated declarations need no body scan
  to discover promoted binders.
- JavaScript dependency analysis and emission each prepare one reachable checked
  body at a time and release transient body data between declarations.
  Mutually recursive entrypoints retain checked inputs until their last emission
  when no out-of-core reader is installed. C ABI layout construction stays lazy.
  The native selfhost builder uses authenticated canonical compiler bytes,
  with fresh input-closure provenance and unchanged automatic-GC resource gates.
  Bootstrap source authentication includes foreign JS paths from original parsed
  definition bodies, not just module imports.
- Source JavaScript emission shares resolved import aliases and pre-rendered alias
  metadata per module. A first-owner normalized-path index replaces repeated path
  normalization and module scans; declaration type lookup and visited type
  dependencies use immutable indexes while preserving source ordering.
  Value and constructor ownership use one flat immutable catalog; type owners
  retain ordered fallback for laws, foreign declarations and duplicate names.
- Source JavaScript emission folds exactly closed native U32/F32 Word literals
  into scalar expressions instead of rebuilding 32 runtime Word constructors.
  Open, malformed and shadowed constructors retain ordinary emission; explicit
  Word values and F32 bit patterns keep their existing semantics.
- Closed native U32/F32 Word patterns compare scalar bits instead of repeatedly
  expanding runtime Words. F32 patterns distinguish signed zero and NaN bits;
  open, binding and explicit Word patterns retain structural matching.
- Source JavaScript tail calls use private requests and a generic loop. Exactly
  saturated ordinary calls share uncurried bodies with their first-class curried
  facades; supported saturated native primitives call the same primitive body
  directly. Partial, inferred, template and unsupported calls retain ordinary
  emission. Strict operands, erasure and dependent metadata are preserved.
  Strict saturated calls invoke the same uncurried entry directly and force its
  result; only tail positions allocate requests.
- Source JavaScript's statically resolved uncurried entries use injectively escaped
  lexical identifiers instead of dictionary lookups. Module-local environments,
  forward references, definition overwrite order and curried public APIs remain
  unchanged.
- Source JavaScript shares native-operation identities and Base authority per
  module. Emitter scopes no longer retain or forward source paths and complete
  module lists through symbol lookup; declaration ordering and alias resolution
  are unchanged.
- Native selfhost seed builds retain original checked bodies through all JS
  constant folding, then release them after definition emission completes.
  Higher-body and scope memo caches are cleared between definitions. This fixes
  late word-match folding of an already-emitted callee; a runtime regression
  covers both released and retained builds. The canonical checker and complete
  body coverage remain unchanged; there are no disk snapshots or source fallbacks.
- The native selfhost bridge parenthesizes function-valued result type arguments,
  admitting the owning Checked FIR handoff to the native checker and emitter.
  Full native root validation and a real emitted-library consumer pass; current
  full-corpus performance and bootstrap acceptance are tracked separately.
- Scalar and string typing certificates recognize checked Word equations after
  reply-wrapper elimination and family-sugar elaboration. The same canonical
  constructor identities, arities, quantities and indexes remain mandatory;
  checked literals no longer fall back to full Word trees solely because of
  the FIR representation change.
- Native selfhost builds run code generation in a separate Node process that exits
  before clang starts, releasing its retained heap instead of overlapping both
  compiler working sets. Native phase receipts include explicit start markers
  and process user/system CPU, persisted synchronously by the runner. The full
  frozen corpus and unchanged 7720-export consumer pass; this is not a bootstrap
  fixedpoint or a five-minute build claim.
- Definition-root matches lower directly into their owning Backend IR code when
  every scrutinee is an already-evaluated header local and the frame has no
  instructions or captures. Nonempty ordered subsets preserve all original
  header parameters and operand order; effects and lazy symbols retain ordinary
  closure lowering. The JavaScript renderer groups distinct-tag
  tests on the same stable local or capture into a switch, preserving lexical
  failure labels, later duplicate-tag cases and wildcard fallthrough.
- Complete emitted compiler suites authenticate an existing full-root byte
  fixedpoint and independently execute every source fixture on both unchanged
  stage images with fresh parsing and full native AST/span parity. Separate
  behavior receipts do not waive or relabel the original aggregate deadline.
- Native word-match coverage comparison stops at the first structural mismatch
  instead of materializing whole JSON keys. It retains the same lowered binder
  representation, annotation/span omission, property order and literal behavior.
  Overlapping/default word arms and returned bound-variable identity have a
  runtime regression; original checked-body lifetime remains unchanged.
- Native private function IDs use compact internal symbols while preserving
  numeric ID order, constructor IDs and foreign placeholder lookup. Escaped
  declaration comments retain source ownership for profiling without hot tracing.
  The complete current compiler builds at `-O1` within the existing 8 GiB guard;
  its full frozen compilation and unchanged 7,720-export consumer pass.
- Source map lookup selects the same Patricia branch through a structurally
  decreasing worker instead of allocating two recursive branch closures per
  node. Unicode keys, misses and arbitrary public map shapes retain Map.bit
  semantics.
- Source JavaScript tail dispatch reuses private scheduling registers. Unary and
  fixed-arity calls no longer allocate request records or argument arrays;
  dispatch captures and clears arguments before invoking a target, including
  nested callbacks. Curried facades reuse the fixed-arity scheduler, and the
  unary hot loop is separate from the larger named-arity dispatcher. Public
  currying, strict evaluation and the finite named-call budget are unchanged.
- The trusted selfhost continuation driver reuses authenticated progress kinds
  instead of retrying another kind's constructor suffix. Per-value shape,
  callable-field and result validation remain.
- Source JavaScript generic constructors and tuples use the native backend's
  ordinary named-field objects and canonical qualified tags. Known constructors
  emit object literals directly, preserving field erasure and argument order;
  native AST transport is unchanged. Qualified tags also appear in value output.
- Source JavaScript lowers the standard native `Nat.min` and `Nat.max` operations
  to scalar comparisons, including zero, equal operands and 48-bit results.
- Source JavaScript evaluates deferred nullary definitions on each reference
  instead of caching affine mutable results. Independent array factories no
  longer share storage; unused definitions remain demand-deferred.
- Source constructor fields are writable/configurable data properties; obsolete
  positional Symbols and per-instance getters are removed. FFI consumers should
  read named fields, not mutate old vectors or borrow getter functions.
- Selfhost scalar-literal checking prepares immutable declaration schemas within
  one definition and memoizes validated name IDs only within each closed Word.
  Every bit, tail and constructor shape remains validated; aliases, shadowed
  declarations and uncertain shapes retain the ordinary checker.
- Typed selfhost steps invoke earlier source bodies through checked single-argument
  closures and continuations; recursive and forward edges retain request dispatch.
  Native JavaScript shares closed named-function curried wrappers, without
  caching partial captures, foreign functions or nullary results.
- Typed selfhost lowering removes single-use ordered-match forwarding helpers
  only when owner, binding identities, quantities and result type agree.
- Read-only selfhost map lookup uses the standard native-backed `Map.bit` encoding,
  including arbitrary non-monotone public maps, without borrowed-cursor division
  and nested continuations. Native and source JavaScript emitters lower builtin
  string equality directly; C retains its checked source implementation.
- Selfhost path normalization scans characters and completed components once;
  dirname preserves original slash spelling and Unicode character positions.
  Resolve and namespace composition avoid concatenating their intermediate paths.
- Selfhost tooling now targets the authentic Bend 2.0.37 kernel, native File
  contexts and compact literal/Nat ABI. Fresh parser generation preserves explicit
  operator annotations and native import aliases; source parity includes grouped
  closed Nat prefixes without folding open tails or explicit constructors.
- Selfhost decimal F32 parsing uses exact 24-bit limbs, so long mantissas and
  decimal scales no longer overflow the native Nat immediate before rounding.
  Normal and subnormal results use round-to-nearest, ties-to-even; native Nat
  limits remain unchanged.
- Selfhost parsing recognizes numeric-headed local assignments through the same
  marker-gated pattern path as destructuring locals, preserving natural-prefix
  tail quantities without changing expression concatenation or prefix adjacency.
- Parser parity observation equates closed native Nat literals with constructor
  and `U32.to_nat` literal views while retaining open calls, payload kinds and
  original span ledgers. Operator regression sources use native `: Nat` syntax,
  and native parser diagnostics keep their structured error messages.
- Selfhost parsing preserves the native result-type annotation on the final
  `do IO<...>` action, including continuations after typed binds.
- Typed and template binder spans end at consumed type tokens, including spanless
  `Quant` terms, so native AST transport retains valid UTF-16 source ranges.
- Full native parser parity isolates every case and streams literal observations
  without repeatedly traversing folded String suffixes. Long embedded JS strings
  keep the same semantic hash and literal-span ledger under the existing limits.
- Selfhost checking publishes typed definition signatures before validating module
  declarations, so forward family references resolve without exposing unchecked
  bodies. Signature, body, duplicate-declaration and affine checks remain in place.
- Selfhost term equality recognizes identical immutable arena handles before
  recursive structural comparison, terminating reflexivity checks on neutral
  recursive applications without changing distinct-handle conversion.
- Both JS emitters use balanced tag comparisons for large eligible constructor
  matches. Constructor names and fields are unchanged; tags are read once, and
  the existing fallback is emitted once after the tree.
- Native JS converts String values to Char lists iteratively, preserving Unicode
  code-point order without consuming one call-stack frame per character.
- Lossless native AST restoration interns repeated scalar strings, including
  source filenames, without changing fields, references, spans or transport bytes.
- Selfhost CPS request protocols use bounded typed groups for result, continuation
  and runtime dispatch, avoiding a single thousands-case dependent match while
  retaining every source signature and native body check.
- Selfhost CPS lowers each authenticated canonical declaration directly and factors
  its matches once, avoiding duplicate preparation-generated helper layers while
  retaining the separately normalized native-provider sources and body validation.
- Selfhost CPS fuses typed identity tail calls along strictly acyclic source-order
  edges. Record roundtrips collapse only for authenticated single-constructor
  datatypes; annotations and promoted-field Data checks remain validated.
  Recursive/back edges, nontrivial continuations and closed computations retain
  the original request protocol and every typed request handler.
- Opt-in selfhost profiling records actual compiler phases, parser-oracle and
  emitted fixture processes, with CPU samples, allocation samples and resource
  receipts. Full-root profiling is explicitly diagnostic and cannot establish
  bootstrap or byte-fixedpoint acceptance.
- Both JS emitters inspect map-key bits and compare strings directly by Unicode
  code point, retaining the original input strings rather than rebuilding their
  prefixes through recursive tuple adapters.
- Selfhost preliminary usage analysis reuses the existing dependent type projection
  for named/annotated local values and applications instead of rechecking their
  arguments. Unsupported shapes retain full inference; body validation still
  checks annotations, argument types and affine consumption.
- Selfhost arenas track conservative free-variable bounds across binders and
  certify mixed-region transient nodes at publication. Shifting and substitution
  preserve handles for subtrees below their cutoff; unknown bounds retain traversal.
- Selfhost match capture-type refinement also reuses conservative arena certificates
  before substitution. Closed and irrelevant types retain their full immutable
  handles; unknown bounds retain the original traversal without extra index math.
- Selfhost name lookup uses the existing native-aware String equality, and emitted
  type metadata reuses already resolved named-type keys without a second lookup.
- Source arena packing shares childless constructors only when their interned
  name handle and complete source span agree. The source-only memo stores no
  typing facts and is invalidated on rewind; all constructor checks remain.
- Selfhost substitution reuses exact published-node results in a bounded,
  declaration-local memo. Full IDs and arbitrary Nat keys distinguish entries;
  every arena rewind invalidates cached handles before slot reuse.
- Selfhost constructor equality reuses positive, source-owned constructor-tree
  witnesses when both complete tagged argument ranges are identical. Unsupported
  terms keep the original comparison; source rewinds clear witnesses before reuse.
- Selfhost visible scopes share immutable lookup snapshots instead of rescanning
  import segments for every name. Incremental declaration updates preserve family
  and per-kind precedence; alias, candidate and unsafe-scope rules retain segments.
- Native JavaScript compilation dispatches tagged constructors with lexical
  switch arms instead of linear condition chains; primitive representations and
  the original fallback-arm semantics remain unchanged.
- Selfhost JavaScript emission uses tagged switches for unique, resolved
  constructor heads; nested, wildcard, duplicate and native-representation cases
  retain ordered matching. Constructor telescope quantities determine packed
  field offsets, so default erased bindings never consume a runtime slot.
- Selfhost checking accepts default bindings for erased constructor fields while
  keeping their binding quantity erased. Pattern emission selects a representation
  before recursing and evaluates string-tail projections once, avoiding discarded
  exponential pattern work and generated-expression growth.
- Selfhost beta normalization selects a decisive match branch before substituting
  its body, avoiding copies of unrelated dependent-family branches. Constructor
  aliases, pattern binders, captured variables and fuel boundaries retain the
  original semantics; inconclusive matches use the original normalization path.
- Selfhost match selection indexes immutable source constructor prefixes in a
  bounded cache, avoiding repeated scans of large dependent-family dispatches.
  Aliases resolve against the current scope; duplicate heads and earlier wildcard
  or uncertain rows retain ordered matching. Arena rewinds invalidate the index.
  Transient raw-head indexes reuse a bounded declaration-local cache. Rewind
  discards the owning cache; source generations invalidate mixed-owner entries
  after source rewind and ID reuse. Append-only growth preserves valid entries.
- Selfhost match usefulness and exhaustiveness reuse local indexes of prior
  constructor-headed pattern rows instead of rescanning unrelated branches.
  Original-order candidates retain wildcard, malformed and uncertain rows;
  aliases resolve per query, and incomplete or unsafe scopes keep full matching.
- Native JavaScript tail calls use a bounded direct-call fast path before falling
  back to the trampoline, preserving stack safety for unbounded recursion.
- Arena-backed selfhost checking publishes the open-law name tape before each
  declaration rewind, preserving law completion across intervening datatypes
  without weakening duplicate-declaration checks.
- Native selfhost builds store authenticated, lossless checked-body graphs between
  validation and emission instead of retaining every checked output in the heap.
  Source values remain available for native normalization; original native
  annotation/cache closures retain their identity. Lower memory trades additional
  snapshot CPU and temporary storage; generated JS bytes are unchanged.
- Typed-step lowering calls bounded nonrecursive arena storage helpers directly.
  Computed record results receive dependency-first typed match helpers; recursive
  and general computations retain their request/continuation protocol.
- Generated successor patterns separate the arithmetic plus from a following
  quantity marker (`1n+ +tail`), preserving reuse quantities while remaining
  readable by both native and selfhost parsers.
- Arena quantity decoding compares its affine word once and matches constructors,
  preserving zero/one/default semantics in both native and selfhost source grammar.
- Selfhost Template captures resolve caller aliases before entering the template
  owner's scope. Substituted values retain their declared binder type, allowing
  closed lambda callbacks to be checked bidirectionally instead of inferred.
- Full parser parity gives implicit lambda quantities the unchanged source
  parser's affine default before looking up structural template instance keys.
- Typed-step lowering keeps nonconstructing live-argument projections direct;
  other source calls retain checked request/continuation boundaries.
- Full selfhost AST approval streams exact native envelopes and complete
  declaration normal forms, releasing transient oracle heaps between compiler
  imports without relaxing RSS, footprint, parser or field-coverage gates.
- Canonical selfhost expansion gives leading single-dot operator references
  the unchanged native core's implicit Nat namespace; qualified names and
  leading double dots retain their original meaning.
- Selfhost checking honors existing unsafe-definition domain-kind semantics
  without leaking that context to subsequent safe definitions. Match branches
  substitute checked pattern values for their original scrutinees before use
  accounting and nested recursive-order comparison. Local bindings preserve
  the incoming checking goal through parallel substitution.
- Selfhost ordered matches accept shadowed fallback rows, matching the native
  first-row-wins lowering; exhaustiveness checks remain enforced.
- Template specialization catalogs application sites once per generation round,
  preserving caller captures, alias order and rescanning newly generated code.
- Selfhost use checking shares each scope-local usage map across its binders.
  Global indexes use persistent Base maps with native-validated readonly lookup,
  avoiding per-tree-node continuation dispatch and lookup-time reconstruction.
- Selfhost scope lookup keeps ordered segment and family/kind precedence inside
  a native-validated readonly module. Constructor coverage deduplicates with a
  fresh query-local map, preserving canonical-name normalization and row order.
  Readonly row specialization and subsumption use the same fully checked module,
  retaining complete patterns, source spans and ordered coverage decisions.
  Inverse declaration aliases avoid repeated whole-scope normalization per row;
  candidate aliases are rechecked against the current scope before use.
- Selfhost structural equality stops after the first unequal component instead
  of reducing unrelated arguments and branches; conversion fuel is unchanged.
  WHNF case selection skips only definitely different outer constructor names;
  aliased names and potentially matching nested patterns retain ordered checking.
  Constructor result conversion reuses its already reduced goal with identical
  fuel and scope, retaining the raw equality gate and original inferred type.
- Selfhost usage analysis skips variable-free constructor trees and unnecessary
  unrestricted-lambda usage queries without skipping body or domain checking.
  Constructor-tree equality retains ordinary conversion for other syntax forms.
  Local validation reuses inferred types for its usage environment, checking
  parallel values in the incoming scope rather than rechecking each value.
  After successful body validation, usage environments reuse closed constructor
  values with nominal annotations while retaining annotation checking and the
  full-inference fallback for preliminary queries and all other value forms.
- Guarded runs have finite monotonic deadlines, including helper setup and
  authenticated descendants; timeout cancels the process tree and never passes.
  Configure milliseconds with `--timeout-ms` or `HEAVY_GATE_TIMEOUT_MS`.
- Native AST transports drain shallow records synchronously within bounded
  chunks, preserving complete two-pass field and byte-integrity checks.
- Selfhost typed-step source generation reuses authenticated manifests only when
  configuration, runtime/resolver context, all imported inputs and output hashes
  match exactly. Drift regenerates; full native validation remains mandatory.
- Selfhost law completions inherit the declared dependent parameter and result
  types. Checked modules retain the elaborated signature for emission, and
  definition values are lambda-closed for bounded definitional equality.
- Selfhost JavaScript emission indexes original definition and constructor
  owners once per module. Module order, alias resolution, first-owner precedence
  and foreign-definition fallback are unchanged; dependent types and closures
  are still computed on demand. Native-name predicates short-circuit without
  changing exact, dot-suffix or slash-suffix matching.
- Selfhost bootstrap parks each complete current-run native AST transport before
  oracle approval, restores all fields only after approval, and releases consumed
  phase inputs. Full bootstrap still reparses every source with its own parser.
- Full semantic AST hashing skips unused span-ledger allocations; payload
  normalization still retains its complete span ledger. Isolated oracle workers
  have an explicit five-minute deadline in addition to the guarded run deadline.
- Bootstrap and native validation/build orchestration leave collection to the
  runtime; explicit phase, pressure and emergency GC calls are removed. External
  aggregate-memory limits and finite deadlines remain enforced.
- Native component builds run the unchanged accepted compiler under Node/V8
  automatic GC, with a 6-GiB old-generation limit and 256-MiB worker stack.
  The external process-tree RSS/footprint guardian and finite deadlines remain;
  no Bun-only in-process FFI sampler or manual collector is required.
- Native build diagnostics support `--allocation-profile-mib=N`: sample live
  code-generation allocations and stop at a bounded heap threshold without
  publishing a compiler artifact or claiming acceptance. Full native validation,
  accepted compiler hashes, automatic GC and the external guardian are retained.
- Accepted native build snapshots live in the persistent user cache instead of
  `/tmp`; restored source bytes remain authenticated against the accepted pins.
- Bootstrap parity stores complete native AST transports in a typed-array arena
  with record IDs and interned field keys/string values. It decodes one original
  declaration at a time, flattening native argument/telescope lists directly,
  without rebuilding an intermediate native object graph. Compiler AST inputs
  retain their existing ABI and every field; no persistent parse cache is used.
- Compiler-private AST storage uses concrete growable arrays, U32 node/name IDs
  and contiguous argument/telescope tapes; descriptors retain arbitrary Nat
  indexes, quantities and source spans. Native growth, large-index preservation
  and reference-clearing rewind are exercised; full checker cutover and speedup
  remain unproved.
- Private arena counters/capacities and allocation depths use flat U32/Nat
  metadata arrays rather than six nested pool records in threaded state.
  Native growth across all pools, rollback, clearing and name-map restoration
  are exercised; whole-root emission remains bounded by retained layouts.
- A zero scope shift reuses its unchanged immutable syntax term.
- The selfhost JavaScript emitter preserves source order in application spines.
- Selfhost JavaScript application erasure follows formal signature quantities
  and lexical types, including ordinary named type arguments. Erased expressions
  are not evaluated; lambda and constructor arities use the same typed context.
- Selfhost JavaScript constructors keep positional fields in collision-free
  symbol metadata, preserving source fields named `args`. AST transport validates
  positional/named aliases without dropping or duplicating semantic fields.
- Selfhost structural recursion shifts outer columns into a match branch once,
  recognizing predecessor calls while rejecting unchanged and growing inputs.
- Imported datatype constructor results retain their already-qualified family
  identity instead of prefixing the owner namespace twice.
- Selfhost checker scopes use an immutable ordered index for visible and canonical
  names, retaining family/kind precedence. Typed request envelopes derive their
  kind from authenticated parameter domains instead of promoting affine fields.
- Selfhost match coverage removes entirely variable columns before splitting
  recursive datatypes, terminating on complete and incomplete multi-column cases.
- Selfhost constructor-pattern use checks follow the typed scrutinee/field
  multiplicity: copied fields remain reusable, affine and erased fields do not.
- Selfhost conversion recognizes equal original neutral family applications before
  WHNF fallback. Pattern vectors refine their goals and remaining scrutinee types.
- Selfhost local bindings record their type's context depth; dependent match
  branches refine inherited binding types without shifting newly bound indices.
- Selfhost conversion compares stuck match eliminators structurally after beta
  reduction, preserving ordered patterns, binder quantities and branch bodies.
- Selfhost matches admit disjoint nested patterns sharing an outer constructor;
  ordered fallback remains valid and rows covered by earlier rows still reject.
- Selfhost equality annotations check both endpoints against the checked
  annotated type, including constructors whose parameters require that context.
- Selfhost JavaScript emission supports constructor-destructuring local bindings
  and snapshots pattern fields before nested matches. Erased fields remain
  unevaluated; simultaneous RHS expressions retain their original environment.
- Selfhost JavaScript globals with no live binders initialize on demand.
  Authenticated Base definitions/native laws use the existing guarded operation
  table; user function names alone no longer select native implementations.
- Native diagnostic builds reuse event-log descriptors, JSON rows and FFI memory
  buffers. Scheduled collections require measured memory growth; full validation,
  checked-body retention, pressure protection and hard resource limits remain.
- The parser parity oracle reuses exact instrumented module instances with
  serialized observer ownership and fresh per-call books/provenance; concurrent
  calls and deferred normalization remain isolated.
- Template fixture diagnostics reuse authenticated compiled-parser results only
  when source, parser, runtime, import closure and complete AST parity proofs
  match. Invalid entries reparse; full bootstrap never uses this cache.
- The JavaScript emitter's type descriptor helpers now use valid Bend syntax.
- Selfhost checker/emitter consumers share `loaded_module.bend` instead of
  importing the loader's parser and IO implementation for its module type.
- The isolated compiled-parser corpus harness accepts `--module=ID --declarations=N`
  for an exact frozen declaration prefix, preserving import context and both source
  hashes. Prefix parity is reported separately from full-file/corpus success.
  Complete semantic comparison hashes and releases the expected normalized tree
  before building the actual tree; mismatches retain both hashes in a bounded
  report with the compiled AST sidecar.
- The selfhost parser preserves the rewrite motive's underscore scope with an
  explicit type annotation and parses square-list match patterns as Con/Nil,
  including nested affine fields and empty/multiline lists. Mismatched closes
  remain errors. Scanner factoring derives text classes from source clauses
  instead of assuming a fixed grammar-specific class count.
- Bootstrap scanner factoring preserves ordered expectation rules in separate
  selectors, avoiding the stock Node Maglev allocation spike on complete modules.
  The rebuilt parser passes full AST parity for all ten frozen modules under
  isolated 8 GiB workers. Stage1 closure census validates actual imports to a
  fixedpoint and counts Template syntax only from complete, hash-proven ASTs.
- CheckerCore and JSEmit diagnostic integration now uses native-validated typed
  steps with one explicit trusted Node continuation loop, outside the native
  termination proof. Frozen inputs remain unchanged; emission is checked and
  unpatched. The compiled pipeline passes 21 actual runtime scenarios.
- The selfhost checker handles partial datatype-family application, distinguishes
  families, constructors and definitions, and preserves constructor coverage
  and affine lambda diagnostics. The selfhost JS emitter fixes constructor names,
  generated delimiters and the main IO thunk contract.
- The shared selfhost Core provides single-pattern binder depth directly,
  without building a singleton pattern list.
## 2.0.37 (2026-10-13)

- **A Nat crosses to a JS host as a plain number** (PR #1506 by
  nicolas-abril). **Breaking for JS callers:** an effect's `.js` and a
  caller of an exported def pass and get `5`, not `5n`. A `Nat` answer or
  argument that isn't a whole number from 0 to 2^53 stops the run with the
  Nat error, as in C. Calls into exported defs are about 3.5x faster.
- **`IO.exit(code)` ends a program quietly** with a status from 0 to 255
  (#1465, PR #1492 by oxura). A code above 255, in `IO.exit` or `IO.die`,
  exits 1 instead of wrapping.
- **`F32.show` takes a plain parameter**, so `~F32.show` fits `List.show`
  and `Maybe.show` (#1511, PR #1518 by vicmcorrea). A caller passing it as
  `+` now wraps it: `(x => F32.show(x))`.
- **bend-lint**, a standalone linter with rules written in TS or Bend, in
  `tools/bend-lint` (PR #1389 by MattCozendey).
- **Faster**:
  - The CPU hands a slow grow's forks to idle threads, so a wide late fork
    runs 2.6x faster at 14 threads (#1475, PR #1479 by viridale).
  - BendTT's parser reads the text's bytes, so `--verdict` parses twice as
    fast in a quarter of the memory (PR #1380 by nicolas-abril); safe.ts
    walks each term once (PR #1384 by nicolas-abril).
  - A bang over a pair no longer sends every closure to the device (PR
    #1336 by chaserelock); a spin is a device call by its C's length in
    characters, and always inline on the host (PR #1413 by nicolas-abril).
  - A native build frees the compiler's memory before clang runs (PR #1385
    by Iann29).
  - On Linux a window paces at the display's refresh rate, not 60 Hz (PR
    #1379 by igorhasse).
- **CLI**:
  - `bend update` fails when the installer download fails (#1481, PR #1485
    by vicmcorrea).
  - `--checkup` reads only the import header, and imports with a trailing
    `# comment` (#1501, #1497, PRs #1502 by oxura and #1517).
  - `bend a.bend --verdict b.bend` is refused: extra arguments go only to a
    plain run (#1503, PR #1516).
  - Inline HTML module scripts are bundled (#1400, PR #1412 by oxura), keep
    their diagnostic positions (PR #1454 by Osraka), and a bundler failure
    is a formatted error (#1399, PR #1406 by oxura).
  - An unreachable hub is a formatted error, not a TypeError (PR #1428 by
    HamedShams); a native build that fails before clang removes its
    `/tmp/bend-*` dir (#1402, PR #1405 by Yi-111-a).
  - A `!` build finds CUDA at `$CUDA_PATH` and `/opt/cuda` (PR #1373 by
    igorhasse).
- **Fixes**:
  - Linux audio keeps a partially written chunk until ALSA takes it, and
    stops on a dead device instead of spinning (PR #1508 by
    sebastian-griego).
  - `F32.hypot` keeps lengths past 1.8e19 and below 1e-19 (PR #1515 by
    sebastian-griego).
  - A closed stdout or stderr reader ends a program by SIGPIPE (#1467, PR
    #1470 by viridale); `Process.run` reads until stdout and stderr close
    (#1343, PR #1392 by nicolas-abril); `get_env` rejects a name with a NUL
    (#1449, PR #1450 by Yi-111-a).
  - An erased last argument no longer cuts its call (#1374, PR #1377 by
    nuxyel); the effect table is sized to the program's constructor ids
    (#1163, PR #1378 by vicmcorrea); arrays of concrete functions compile
    (#1404, PR #1410 by oxura); `lay_el` takes only datatypes and type
    formers (PR #1426 by nicolas-abril); a `__proto__` export survives in
    JS (PR #1458 by vicmcorrea).
  - Match-refined Data views stay in copyable lets (#1349, PR #1369 by
    oxura); Array-wrapped JS marshalling is stack-safe (#1346, PR #1370 by
    oxura).
  - `--verdict` builds inlined recursive let arguments at each use (#1326,
    PR #1368 by oxura), keeps Base-free large Nat literals (#1330, PR #1337
    by oxura), and parses both rewrite motive binders in its diagnostics
    (#1315, PR #1407 by oxura).
  - The formatter keeps module import paths (PR #1325) and separated brace
    arguments (PR #1505), by vicmcorrea; the linter keeps quoted foreign
    import paths (PR #1422) and module headers (PR #1460), by vicmcorrea.
- **Docs**: README Limitations names backend divergence and the unproven
  translation (#1423, PR #1424); the formatter README installs
  `bend2-fmt-lsp` on PATH (PR #1486 by Osraka); IO forks vs CPU parallel
  calls (#1375, PR #1415 by oxura); BendRT's opening program checks again
  (#1308, PR #1382 by oxura).

## 2.0.36 (2026-10-07)

- **HOC's proving agent is now named BendAI**: `bend login` logs in to
  BendAI at bend-lang.com/bendai and writes its key to
  `~/.bend/bendai.json`; a key an older bend wrote moves there at the next
  `--publish <name>@…`, so it keeps working. The publish notice links
  https://bend-lang.com/bendai/terms#s18, and the installer's card ends
  "You're now a Bend developer." The old addresses redirect.
- **Every channel and socket wait has a `try_` twin** with a limit in ms
  that answers `Poll` (PR #1259 by nicolas-abril), and UDP gets the byte
  twins TCP and File already have: `send_bytes_to`, `recv_bytes_from` and
  their `try_` twins (PR #1359 by kbrianps).
- **BendTT's kinds are quantity terms**, with meets, Σ at any kind and
  subsumption under ∀, and `--verdict` emits a generic def once (PR #1203
  by nicolas-abril); a λ+ converts as a λ (#1189, PR #1224 by
  nicolas-abril).
- **Faster checks**: a name lookup is one map read, not a scan of the book
  (PR #1372); types never read, or already reduced, are not reduced again
  (PR #1362); roots share their `~` constants, so a template goes to the
  kernel once (PR #1358 by chelokot); n instances of a def take O(n log n)
  characters of names, not O(n²) (PR #1350 by chelokot); a graph closure
  is linear in the graph (PR #1298 by moorbrook).
- **Fixes**:
  - A value past 2^24-1 live copies fail-stops with its own message, and
    WONTFIX names the cap (PR #1366 by nicolas-abril).
  - A type under a rewrite stuck on an open proof is read as its body, and
    a type the C facts can't read is a compile error (#1273, PR #1276 by
    nicolas-abril).
  - A constructor's fields compile with their declared types, so a Word
    folded out of a U32 literal emits (#1100, PR #1361 by nicolas-abril);
    datatypes of boxed constructors are registered (PR #1351 by
    vicmcorrea); spare nodes stay apart across sum arms (PR #1279 by
    jasisz); C emits right when a native effect calls back into Bend (PR
    #1286 by mizchi).
  - The work pass after a grow runs each lane's own ring (#925, PR #1132),
    and on MSL 3.2+ `heap_free` reads the error flag with a coherent
    volatile load (#1143, PR #1299 by nicolas-abril).
  - `--verdict` checks what bend checks for a match carrying a later
    variable (#1292, PR #1293 by aaaxn), respects Unit provenance and word
    constructor families (PR #1338 by oxura), verifies the Lean version and
    drops unversioned kernel caches (PR #1339 by oxura), and cleans up its
    temporary input when the kernel build fails (PR #1327 by Osraka).
  - Unsafe dependencies are tracked in datatype kinds (#1205, PR #1220 by
    oxura).
  - A nested match on a split value is refused with its name and where to
    match it (#1125, PR #1290 by nicolas-abril); only a statement
    `a[i] <- v` is the write let, so `Array.set(..);` in an inline match
    keeps the next row (#1126, PR #1289 by nicolas-abril).
  - `F32.read` skips leading whitespace (PR #1335 by vicmcorrea); the
    formatter keeps unsafe declaration suffixes (PR #1296 by vicmcorrea).
  - A CUDA probe failure names its stage and the Driver API error (PR
    #1341 by oxura).

## 2.0.35 (2026-10-03)

- **M1 and M2 run the GPU again** (#1154, PR #1274 by nicolas-abril): since
  2.0.29 Apple's compiler died building the GPU program of any program with
  a `!` on M1 and M2 chips; M3 and M4 were never affected.
- **A library's names stay its own** (#1045, #1124, #1184, PR #1156 by
  nicolas-abril): a name the entry file declares as `lib.None` no longer
  takes the key of `lib.bend`'s own `None`, so its foreign `CID(None)`
  means the constructor its Bend code means, and C no longer takes the
  wrong arm or frees into the wrong size class.
- **Less memory on the CPU** (PRs #1171, #1269 by nicolas-abril): the host
  grows fewer tasks up front and splits a drain into finer units, so
  parallel tree-matmul peaks at 14.5 MB instead of 68.5 MB and kmeans at
  10.8 MB instead of 22.9 MB, with every bench as fast or faster. A spin
  called in a jump's argument frees the variable it was lent, so a loop
  over a list no longer keeps the old list's cells (81.6 MB to 1.6 MB, PR
  #1243 by mizchi). U32 `/` and `%` divide directly on the host and CUDA;
  only Metal keeps its workaround (PR #1277 by nicolas-abril).
- **Arrays of equality proofs** build in JS and C (#1130, PR #1219 by oxura).
- **A deadline or a timer fires while computations keep the loop busy**
  (#1122, PR #1245 by nicolas-abril): `IO.within` and `IO.sleep` no longer
  wait for a channel pipeline to end.
- **Fixes**:
  - A chain of more than about 86 U32 or 130 F32 operators builds in C
    (#1123, PR #1239 by nicolas-abril).
  - `bend f.bend -o f.c` builds at `-O0` with clang 19 and later, for a
    debug build (PR #1074 by aldeni).
  - A type with deeply nested sums compiles without hundreds of MB (#1270,
    PRs #1196 and #1244 by vicmcorrea).
  - A template with many instances names them in linear time, not
    quadratic (#1271, PR #1275 by nicolas-abril).
  - `IO.random_u32` answers `Fail` on the JS lane, as on C, instead of
    ending the run (#1146, PR #1198 by Yi-111-a).
  - A match on a binder a constructor column closed says so and lists the
    causes (#1134, PR #1226 by nicolas-abril).
  - `bend ... | head` keeps the command's exit status when the reader
    closes early (#1211, PR #1214 by oxura).
  - `--verdict --publish` is refused instead of publishing unchecked
    (#1191, PR #1199 by vicmcorrea).
  - `--publish` drops a leading byte order mark, so a package whose LICENSE
    was saved with one imports (PR #1188).
  - `--verdict`: model search is bounded (#1181, PR #1218 by oxura);
    recursive groups follow live references only (#1212, PR #1215 by
    oxura); a dead fallback past the last constructor checks (#1204); an
    empty datatype goes out with `D.efq : D -> <>` (#1183); a specialized
    argument is elaborated at each use (#1168, #1178); a match inside a type
    goes at the goals bend2 checked it at (#1157).

## 2.0.34 (2026-09-28)

- **A shared graph is compared once** (#1071, PR #1151 by Giulio2002):
  when conversion proves two share cells equal, the second points at the
  first, so a value used twice on each side is compared once, not walked
  as a tree. Two Merkle roots of depth 32 over a symbolic leaf, proven
  equal by `{==}`, check in 0.07 s (they took 2^32 steps). `--verdict`'s
  kernel does not share yet and runs out of fuel on such a proof.

## 2.0.33 (2026-09-28)

- **Two copies of one term are equal before either unfolds** (#1071, PR
  #1151 by Giulio2002): a conversion first compares both sides with no def
  unfolded, then as before. A law proven by induction and used at a fixed
  size, like `agree(32n, x)` against its written type, checks at once
  instead of walking a shared chain as a tree of 2^32 steps.
- **Base opens a value before it copies it**: `U32.min`/`max`, the `F32`
  helpers, `Char.to_upper`/`to_lower`, `U32.div`/`mod` and `List.sort` match
  their argument first, so a stuck argument stays one call (#1075).
- **Base is smaller** (PR #1153 by nicolas-abril, from #1059 by
  jnadeau207-collab), and `U32.log2` takes five native shifts instead of
  thirty-two.
- **Fixes**:
  - `U32.to_nat` widens to u64 in C, so Nat arithmetic on a u32 local no
    longer wraps at 2^32 (PR #1142 by Giulio2002).
  - A shared Array's redirect is read without a race and without a device
    atomic (PR #1155 by nicolas-abril).
  - `TCP.recv`, `TCP.recv_bytes` and `TCP.poll` with a max of 0 fail with
    EINVAL, not a closed peer's `""` (#1121, by aldeni).
  - Emission does less work per word type and nullary constructor (#1056,
    by jnadeau207-collab).
  - `--verdict`: the kernel puts a λ argument into a type annotated with
    its domain, so a `+` let of `Equal.cong` over a function checks (#1158).
  - A pure main shows an Array element and a flat value of one type each
    by its own layout (#1166).
  - A `CID(k)` in an effect source's comment or string is left alone
    (#1161, by aldeni).

## 2.0.32 (2026-09-27)

- **One verdict: `ALL PROOFS CHECK` or `SOME PROOFS FAIL`**: `bend f.bend`
  on a file with no main (or `--check-only`) prints one of the two. A proof
  holds when bend checks it and it uses no `@unsafe` def and no user foreign
  code, imports included. `--verdict` (was `--safe`) also rechecks every
  def with the proven BendTT kernel; it no longer writes `f.bendtt`, and
  `-o f.bendtt` does. Function-typed terms go to the kernel η-long.
- **Breaking: `TCP.listen` and `UDP.bind` take the address to bind** (#1088,
  PR #1098 by oxura): a server no longer listens on every interface.
- **Breaking: `IO.args()` starts with the program as invoked** (#935), as C's
  argv does; the arguments start at index 1.
- **`IO.within` races an action against a deadline** (#1034).
- **`TCP.send_bytes` and `TCP.recv_bytes`** carry bytes as they are (#846).
- **`-o f.mjs` writes an ES module** of a Bend file (#1029).
- **Windows**: `Window.grab` holds the cursor for a first-person camera, and
  the mouse's motion comes as `Look{dx, dy}` (#921, PR #1073 by
  nicolas-abril); `Scroll{x, y, dx, dy}` events come from the wheel and the
  trackpad (#1020, PR #1114 by oxura); macOS input no longer lags (#842);
  Shift+Tab on X11 gives the Mac's back tab; the Linux window fills a frame
  by squares, about 6x faster (PR #1115 by costamatheus97).
- **Fixes**:
  - A native intrinsic on a nullary def keeps its result layout (#1093,
    PR #1094 by chiliec).
  - One file is one module however an import spells its path (#1087,
    PR #1103 by MattCozendey), and an alias that matches the file name
    works (#1082).
  - F32 text rounds once to the nearest f32 on every lane and in literals
    (#1055); `F32.pow(±1, y)` is 1 on JS as on C (#1060).
  - A pure main that prints a datatype through a family field builds (#1067).
  - Two defs with the same body are equal (#1028).
  - A fallback arm past a datatype's last constructor is dead code (#1091).
  - An error names a hub def the way you write it (#965), and a `+` binder's
    error names the right binder (#980).
  - A compound type argument without parens is a clean parse error (#1110).
  - A shared Array's redirect reads cannot race its count (#975).
  - Timers wake in deadline order; clang's version probe no longer fails
    under load.
  - `--gpu on` names the reason a CUDA GPU is unusable (#1064).
  - A JS host tag the type lacks is a clean error (#1105).

## 2.0.31 (2026-09-27)

- **`bend` help: one aligned line per command**: a table builds the list,
  so every description starts in one column; `--publish [<name>@<version>]`
  is one line, and `bend guide` is the last command.

## 2.0.30 (2026-09-27)

- **`bend f.bend --safe` rechecks a file with a proven kernel**: after
  bend's own checker, it translates the file to BendTT (`f.bendtt`) and
  checks that with `bend2/bendtt.lean`, a small kernel with a Lean proof
  that no def it accepts has type `Empty` and that live code halts. The
  first run builds the kernel with Lean v4.34.0 (elan's toolchain, or
  `$BENDTT` names a built one). `@unsafe` defs stay out of scope, and
  `--safe` lists them. `-o f.bendtt` only writes the translation.
- **The kernel has full J**: a rewrite's motive can name the evidence.
- **base.bend**: the `Array.get`, `Array.swap` and `Map` helpers recurse on
  their own pieces, so the kernel checks them; a few `.if`/`.bit`/`.deep`
  helpers and five laws are gone.
- **The BendTT paper** (`paper/BendTT.pdf`) is rewritten for the new kernel;
  `bend2/bend.lean` is gone, and `bend2/bendtt.lean` is the only Lean file.

## 2.0.29 (2026-09-26)

- **The JS lane runs about 2.3x faster** (PR #1061 by nicolas-abril, and a
  Nat that is a JS number): a Nat is a double, exact below the 2^48 - 1 cap
  the C lane shares, and BigInt only where a value crosses to the host; a
  tail cycle is a loop, and a def calls another directly unless the callee
  can bounce. The JS lane recurses at least as deep as before. A Nat that a
  host passes in (negative, past 2^53 or not an integer) now fails with the
  C lane's Nat message instead of printing garbage.
- **Errors underline their span** (PR #1063 by nicolas-abril): a location
  marks the exact text, and a non-inferrable term is no longer echoed.
- **A checked recursion on a Nat literal is linear** (#983): the descent
  check no longer takes 2^n steps on a literal like `30n`.
- **A constructor of any width builds on C** (#991, PR #1068 by
  nicolas-abril).
- **Compiled binaries pass `--help` to `IO.args`** (#934, PR #988 by
  YidaWeng); the runtime's own help is `--bend-help`.
- **Fixes**: a boxed Bool from a generic pick reaches `Bool.or` as a flat tag
  on C (#1026, PR #1038 by vicmcorrea); `Process.run` stops at the child's
  exit even when a descendant holds its pipes (#1051, PR #1054 by
  Yi-111-a); `TCP.listen`'s backlog is 512, so a burst of 10k connections is
  answered in full (PR #977 by aldeni).
- **Simpler compiler and checker, same output**: the compiler's types go
  from 31 to 16 and the C runtime's type names from 26 to 14, with one
  atomic family for the host, Metal and CUDA; the parser reads operators
  from one table (parsing 7-22% faster, checking 2-6% faster). A file that
  ends in `<` now says "expected a term". Tested on macOS (Metal), Linux
  x86-64, and CUDA from Pascal to Blackwell.

## 2.0.28 (2026-09-25)

- **The macOS `bend` has a valid signature** (#1025): `bun build --compile`
  left the hash of the binary's last page stale, so every macOS release since
  2.0.8 failed `codesign --verify`, and a Mac that checks that page killed
  `bend` at launch with SIGKILL. The release now signs the macOS binaries
  again, ad hoc, and verifies them before publishing.
- **A package name is 1 to 64 characters** (#1053): the CLI asks the hub
  about a short name instead of refusing it, so `--publish json@…` prints the
  hub's answer (a name under 12 characters is won at auction on
  hub.bend-lang.com) and `import std@1.0.0.0/…` resolves once the name has a
  version.
- **Names and namespaces cannot collide** (#1042; closes #994, #989, #1002,
  #1005): a declared name is words joined by dots; a file's namespace is its
  real path, so a local file cannot take a hub package's `0x<hash>`
  namespace nor register names in another file's; only a `0x<hash>/` or
  `name@version/` import goes to the hub. A name declared twice, a
  redeclared Base name, a clashing alias and an effect registered twice are
  refused. **A JS effect registers with `io_eff(CID(Name), run, need)`, as a
  C effect does**: effect files written for 2.0.27 need that change (see
  `bend guide effects`).
- **An unsafe fill in an imported file is listed** (#1001, PR #1033 by
  costamatheus97): the verdict walks from every law, wherever it is filled,
  so a law filled by `@unsafe` code in a helper file no longer passes as a
  clean `All terms check.`. Exit codes are unchanged.
- **`Process.run`** (PR #1030 by oxura) runs a program directly, without a
  shell: literal arguments, UTF-8 input, bounded output and a timeout, and it
  answers the status, stdout and stderr, on every lane.
- **`IO.thread_count()`** (#971, PR #1048 by aldeni) answers the native worker
  pool's size (`--threads`, or the CPUs the process may use, up to 128), and 1
  on the JS lanes.
- **A checked `Nat.read` finishes** (#1008, PR #1009 by jkbennitt): a law like
  `{Nat.read("7") == Some{7n}}` no longer compares each digit against a unary
  2^48 - 1.
- **Fixes**: the `.bend` loader registers in Node worker threads (PR #992 by
  vicmcorrea); an empty `UDP.send_to` sends on Bun (PR #998 by vicmcorrea); a
  signal that interrupts the event loop's `select` wakes nothing, on both
  lanes (PR #1036 by aldeni); rebuilding a list in C no longer leaks 16 bytes
  (#970, PR #987 by YidaWeng); an effect `.c` that says `undefined` in a
  comment builds (PR #1049 by aldeni); Metal names the device's limit when
  `--gpu` asks for more (PR #1047 by MattCozendey); the effects guide gives
  the JS park its deadline (PR #1050 by aldeni).
- **Simpler checker and effects, same output**: every literal is one node
  that carries its Base type (PR #1004 by MattCozendey), three one-use C
  helpers go (PR #981 by tachytelicdetonation), `Nat.read` checks its bound
  with three helpers instead of eight, and the JS show escapes a surrogate as
  C does (PR #943 by This-Is-NPC).

## 2.0.27 (2026-09-23)

- **`bend` reads no `bunfig.toml` or `.env` from the directory it runs in**
  (#1018): the executable was a Bun program built with Bun's defaults, so a
  project it checked could preload its own code before bend's (and print a
  forged `All terms check.`), or set `BEND_HUB`, `BEND_ORIGIN` or `BEND_LIB`
  for you: your BendAI key went to its server on `--publish <name>@…` and
  `bend link`, `bend update` ran its script, and its own copies of hub
  packages, named ones included, were checked in place of the real ones. The
  release is now built with that loading off (`package.json` and
  `tsconfig.json` too), and the ping gate runs the installed `bend` in such a
  project (#1023). `bun bend2/main.ts` from a checkout still reads both, as
  any Bun program does: check a project you did not write with `bend`.
- **A package can carry a license** (#1013): `--publish` takes every file
  named exactly `LICENSE` beside a published file, at the same path, and the
  hash covers it. A package without one is MIT-0 under BendHub's terms, and
  the publish warns so. Every publish first prints, on stderr, that the hub is
  public and permanent under https://bend-lang.com/bendai/terms#s18, and the
  license the hub will show: the `SPDX-License-Identifier` of the shallowest
  `LICENSE`, else `see <path>`. A directory named `license` in any case is
  refused before mining, since it clashes with a `LICENSE` on a disk that
  ignores case. A `LICENSE` added to a published package changes its hash:
  publish it as a new version (bend-tensors@0.0.0.2 is 0.0.0.1 plus MIT).
- **Requests to the hub and bend-lang.com carry `User-Agent: bend/<version>`**
  (#1013): publish, publish-check, link, name lookups, package reads, the
  login and the daily check, so the hub's log shows which bend sent each.
- **Datatypes name each other in any order**: every datatype is declared up
  front, so two datatypes (a `Tree` and a `Forest`), or a def above the
  datatypes it returns, need no forward law. A forward `D<..>` spells every
  parameter. Base's `Word`, `Pair` and `IO` lose their laws.
- **An `@unsafe` def may call a def written below it**, and `def f?(..)` is
  sugar for `@unsafe def f(..)`, so two mutually recursive unsafe defs need no
  law. Safe code is as strict as before: a live call to a def below, or a
  mutual pair, is refused as an unfilled law, which is how a forward
  reference is now reported (it was an undefined name).

## 2.0.26 (2026-09-23)

- **A package has a name on the hub** (#996): `import <name>@<version>/file.bend
  as P` asks hub.bend-lang.com once what the name and version name, keeps the
  answer under `~/.bend/lib/names`, and loads the package by that hash as
  before, so a version never moves and a cached name works offline. `bend
  <file> --publish <name>@<version>` publishes and names in one run, after
  the hub confirms the name is yours or free and the version goes up; `bend
  link <name>@<version> 0x<hash>` names a package already published; `bend
  login` logs in to BendAI for both. A name is a-z, 0-9 and -, 12 to 64
  characters; a version is four numbers like 1.0.0.0. The first:
  `import bend-tensors@0.0.0.1/bend_tensors.bend as T`.
- **The effects guide calls `io_node` and `io_wait_on` as the runtime
  declares them** (#947): `io_node` takes four arguments and `io_wait_on`
  five, the fourth an absolute `io_tick()` deadline, 0 for none, so an
  effect written from the guide compiles.
- **A second book compiled in one process starts from a fresh probe list**
  (#976): the bun loader and `io_run` no longer retain the binder variables
  of every previous compilation.
- **Simpler compiler, same output**: the channel runtime lives in
  `effs/chan.c` and `effs/chan.js` beside `Chan.new`, `send`, `recv` and
  `close`, so a program carries it only when it uses a channel, and both
  match emitters share their table and arms; emitted C and JS are
  byte-identical except the channel programs' requests.
- The README links the standalone `bend2-lsp` (#953, by don2e4).

## 2.0.25 (2026-09-21)

- **A literal is a `Nat` or `String` by name only where the datatype is
  Base's**: a file that declares its own `Nat` checks a literal
  structurally again, so `type Nat: Succ{e: Empty}` no longer admits `1n`
  and a closed `Empty` (#941). An array count past the nat cap is refused
  instead of making a fractional literal that defeats termination (#954).
- **A wide record compiles**: any field list past 255 words has its
  multi-word fields boxed, for constructor layouts, nodes and def
  signatures alike, so a 512-word record no longer dies "an arity over
  255" (#944). A recursive datatype hidden behind a type family is boxed
  instead of overflowing the compiler (#959). A datatype named
  `__proto__`, `constructor` or `toString` compiles (#948). Still open: a
  join holding several wide results, or a wide value held across a
  non-tail call, is refused with the same message.
- **An annotated lambda or match applied where it stands compiles** on both
  lanes, as its let-bound form did (#956).
- **A read parked on a FIFO sees its end on macOS** (#928, PR #932 by
  PedroVIOliv): both IO loops wait with `select`, since Darwin's `poll`
  never reports a named pipe's close.
- **A foreign effect's scheduling helper cannot be overwritten** by an
  effect named `X_need`, in either discovery order (#946, PR #951 by
  tachytelicdetonation).
- **A generated C local carries a `_` prefix** (PR #926 by nood-co1), so a
  host macro such as macOS's `ts_32` cannot capture it; emitted C grows by
  1 to 5 %.
- **The Node and Bun loaders report unsafe and foreign dependencies** on
  stderr, as the CLI does (PR #933 by vicmcorrea), and two books compiled in
  one process no longer share layout memos (PR #961 by vicmcorrea).
- **Simpler compiler and effects, same output**: the layout packer assigns
  offsets once (PR #945 by tachytelicdetonation), the array intrinsics share
  one cell path (PR #955 by PedroVIOliv), the facts fixpoint compares set
  sizes (PR #960 by byronbenharris), the JS emitter keeps one descriptor per
  native constructor (PR #952 by ramonzx6), one `BEND_RTC` macro serves the
  device compilers (PR #963 by costamatheus97), and the file and audio
  effects share one source each (PRs #950 and #939 by tachytelicdetonation
  and tontontimiro).

## 2.0.24 (2026-09-21)

- **A string or nat literal is one `Lit` node in the checker** (PRs #907 and
  #924 by MattCozendey): a literal unfolds one constructor at a time when it
  is compared, matched or checked, so 50 defs of 1000-char strings check in
  0.14 s and 74 MB instead of 4 s and 2.6 GB, a 200k-char literal checks
  instead of overflowing the stack, 2000 defs of `200n` check in 0.18 s
  instead of 1.06 s, a self-call on a nat literal past 256 passes the
  termination check, and `1n+0n` is `1n`. The compiled output is unchanged.
- **The device hands no leaf off**: a fork-free leaf reached from a forking
  def inside a bang runs on heap continuations on the GPU again, as in
  2.0.21, so a `do Result` loop of hundreds of turns under a parallel tree no
  longer dies with "memory fault". The host keeps PR #876's handoff and its
  gains; symreg on Metal stays at 0.32 s (#930).

## 2.0.23 (2026-09-20)

- **`Array.map` walks the block**: Base's map reads each cell and writes the
  result into a fresh array instead of splitting and rebuilding the tree, so
  16M U32 map in 15 ms instead of 176 ms at a fifth of the memory. Its
  elements are `Data` now; a map over affine elements is written from the
  tree by hand (#911, #913).
- A template refuses a second `~` binder of one name, in a def or a law's
  `for ~T` clauses; the two became one opaque constant in the generic check
  and let a closed `Empty` through (#905).
- The C lane heats a stuck family's type argument at every instantiation, so
  a record carried through `F(n, RT)` is opened as the record it is (#916).
- Inside an imported module, a local named like one of the module's own defs
  binds, in a let, a `+` let, a pattern, a `+` pattern and a lambda (#915).
- A right spine of forks under `!` runs on the GPU at any depth the cores
  take: the device grow pass no longer stops after 128 turns (#918).
- The JS lane names a def from a hyphenated or absolute import path legally,
  `--checkup` opens an absolute import as the run does, and `-o out.cjs`
  emits the CommonJS program (#904, #906, #908, #910).

## 2.0.22 (2026-09-20)

- **An `@unsafe` def forks an array**: `Array.fork` gives two handles to one
  block, `Array.join` merges them back, and `Array.atomic.*` (add, sub, and,
  or, xor, min, max, cas, fadd) act on the shared block from the cores and the
  GPU. A match on a shared handle copies its part, as a clone does (#885).
- Two `@unsafe` defs recurse into each other through their laws: an unsafe
  body may call a law that is not yet filled, as it may call itself without
  descent.
- A typed let, `x : T = v`, binds `x` to `{v : T}`; a let with a pattern
  takes no type (destructure in the body).
- A `do` block of one statement is typed by its header, and the header's
  leading quantities are filled once for `bind`, `pure` and the annotation:
  `do Result<String, U32>:` with a bind now checks (#900).
- A word match compares the whole word: a string, char, U32 or F32 literal
  pattern is one equality and its default one else, so three string arms
  compile to 291 KB of C, not 16.7 MB (#892).
- An Array cell is its element datatype's open layout, so a generic body over
  `Array<Boxed<A>>` and its callers agree on the block class; the C lane no
  longer takes the ANode arm for a leaf (#893).
- A node shared through a family with two or more indices is opened with
  `ctr_take` on the C lane, instead of read and freed as owned (#901).
- A C table's F32 row is the constant's own bits: a signalling NaN keeps its
  payload (#897).
- A constructor refuses a repeated field name; the JS lane keyed both fields
  on one property (#899).
- A module imported through `../` or a dot directory works inside an annotated
  operator: an operator is the name whose only dot leads it (#903).
- A GPU out-of-heap reports at once instead of after seconds of aliased
  allocation, a `--gpu` span under the fixed region fails with its message
  instead of a segfault, and a lane's stack ends at the static image: its
  2049th word no longer overwrites a constant (#889).
- Fork-free leaves run sequentially and CPU ring work is dealt across workers
  (PR #876 by nicolas-abril): binarytrees 0.31 → 0.20 s and symreg on the GPU
  0.56 → 0.32 s on an M4 Max. On the GPU a fork-free leaf reached from a
  forking def now runs on its lane's 2048-word stack, as a fork kid does.

## 2.0.21 (2026-09-20)

- A template instance that calls back into an instance whose body is
  still being checked is refused as a self-call that does not decrease:
  `loop(~k, u) = bounce(~loop(~k), u)` with `bounce(~f, u) = f(u)` once
  checked, and inhabited `Empty` (#902).

## 2.0.20 (2026-09-20)

- A `U32` match whose arm is a hand-written bit pattern answers that arm:
  since 2.0.19 the lookup table filled its gaps with the last default, so
  `case U32{WCon{True{}, r}}` (every odd word) between literal cases read
  the `_` case on every lane (#867).
- An erased let binds erased names only: `-y +z = a b` is a parse error at
  the `+`, not a let that erases the `+z` it was told to keep.
- The arena's page cap is published with a release store and read with an
  acquire load, so a core that sees the new cap also sees the banks at
  their new place (#881).

## 2.0.19 (2026-09-19)

- A Bend binary starts in 2 ms, not 12: the runtime reserves 8 GiB and
  grows it in place when a program needs more, instead of mapping the whole
  8 TiB address space at every run (#881).
- A record of records compiles: a datatype past 256 machine words is a heap
  node, the way a recursive type already was, and a constant the compiler
  folds emits once. Seven levels of an eight-field record took 50 s, 19 GB
  and 97 MB of C; it now takes 0.06 s, 122 MB and 82 KB (#843).
- A `match` on dense `U32` literals compiles to a lookup table, as one on
  `Nat` already did: 256 cases took 1.46 MB of C and 3.5 GB, and now take
  80 KB and 1.6 GB (#867).
- The Metal lane computes `sin`, `cos` and `tan` with the GPU's fast trig
  (#887).
- A `-` local is erased again: its name is dead in the body, and its value
  is checked dead, so it may spend a variable twice. Since 2.0.16 the mark
  was lost on both counts.

## 2.0.18 (2026-09-19)

- A dot inside a field name is a character on the JS lane too: `Outer{a:
  Inner, a.b: U32}` read its `Inner`'s field, not its own (#868).
- A value sent through a channel is never read as a parked receiver on the
  JS lane: sending an erased proof reported a deadlock (#871).
- A name the compiler encodes itself is refused, not miscompiled: no file
  may define `Clo.apply`, and a file without `import Base` that declares
  its own `Nat`, `Bool`, `Array` or another of base.bend's types checks and
  runs, but does not compile (#870, #875).
- The verdict names the defs that rely on a foreign def, as it names the
  ones that rely on `@unsafe`: the checker reads a foreign def's type,
  never its code (#874).
- A datatype whose arguments are written in `{}` says to write them in
  `<>` (#864).

## 2.0.17 (2026-09-19)

- **Breaking: an operator takes its type from the `( .. : T)` around its own
  expression, and from nothing else.** The annotation no longer reaches an
  operator inside a call argument, a lambda body, a constructor field, a list
  element, a match arm or a `~` argument, and a bare operator is no longer
  read as `Nat`: write `(a + b : Nat)`. The error names the repair.
- **A `~` template is a definition, and an instance of it is that definition
  at its `~` arguments.** Nothing re-reads the template's text, so the checker
  and the compiled binary cannot mean different things by one call. The body
  is checked once, at its definition, against opaque parameters, so a template
  is a theorem: a `law` may take `~` parameters, a proof may use a hypothesis
  as often as it needs, and an instance no longer counts as unsafe (#848).
- A template that instantiates itself without end stops at the 64th level and
  says so, instead of running the checker out of stack.
- An annotated lambda applied, `{(x => x) : Nat -> Nat}(1)`, is checked at its
  annotation.
- The verdict names the defs that rely on `@unsafe`, following the calls and
  the types, instead of counting the marks. Importing a module that holds an
  `@unsafe` def no longer marks a file that never calls it (#848).
- A nat literal in a pattern is checked against its constructor's arity: it
  was a closed proof of `Empty` (#852).
- A def with no return type that fills no law says which law is missing (#850).
- The C lane seals the fields a hot constructor holds at its own
  instantiation (#853), with five emitter fixes found by a fuzzer (#855).
- `TCP.poll(sock, max, ms)`, a receive with a deadline: a server can drop an
  idle connection (#858).
- `Nat.min` and `Nat.max` are structural, with order laws (#860).
- macOS: the click that brings a window forward reaches the program (#857).
- `bend <file.bend> --check-only` checks a file and its imports, and runs
  nothing (#856).
- `bend version` replaces `bend --version`.

## 2.0.16 (2026-09-19)

- The template memo and the compiler's show table key on the syntax tree
  (`term_key`), not on a printed term: two `~` arguments share an instance
  only when they are the same term (#838).
- A template instance is picked after the enclosing `( .. : T)` closes, so
  its operators carry that namespace (#841).
- A def that is a template instance counts as unsafe: a file with a
  template prints "All terms check, with N unsafe annotations." until the
  checker verifies template expansion itself.
- A template instance is the template's body at its `~` arguments, minted
  and checked by the call, never re-parsed from its text: the checker and
  the compiled program mean the same thing, so a lemma about `M.F(~1n, 2n)`
  is a lemma about what the binary runs. A `~` binder after a plain one, a
  `~` argument past the template's, and a foreign template are refused
  where they are written; a call may omit `~`. `(x = v; x + 1n : Nat)`
  annotates its body's operator again (#848).

## 2.0.15 (2026-09-19)

- `U32` literals as `~` arguments instantiate again (2.0.14 broke them).

## 2.0.14 (2026-09-19)

- Template keys carry no sugar, so NaN payloads that print alike no longer
  share an instance (#838).
- `bend guide shaders` states at the top that AIs wrote it.

## 2.0.13 (2026-09-18)

- `IO.random_u32`, a CSPRNG (#837).
- `File.read_at`, `File.size`, `File.write_bytes` (#823).
- A UTF-8 byte order mark survives on the JS lane (#833).
- A forky continuation that becomes ready during a grow turn runs in place
  (#831).
- A Nix flake: `nix profile install github:bendlang/bend` (#830).
- `bend guide effects` prints a note on the C and JS side of custom
  effects (#825).

## 2.0.12 (2026-09-18)

- Metal: `U32` division and remainder near 2^32 are exact (#824).
- Closure applies allocate no tasks in fork-free code (#832).
- The publisher refuses a file with no name before mining (#835).

## 2.0.11 (2026-09-18)

- Two `Array` shapes with the same leaves no longer share a template
  instance or a show descriptor (#834).

## 2.0.10 (2026-09-18)

- `bend guide shaders` prints "Shaders in Bend"; the guide's Extra section
  points to it.

## 2.0.9 (2026-09-18)

- `--help` is as before 2.0.8.

## 2.0.8 (2026-09-18)

- The installer downloads one executable per platform from a GitHub
  release, verified against a sha256 in the script, and installs nothing
  else. Bend never updates itself: `bend update` reruns the installer.
  Once a day `bend` asks bend-lang.com for the latest version, sending its
  version, OS and CPU type; `BEND_NO_TELEMETRY=1` turns that off.
- `+` on a pattern field is a quantity mark (#810).
- The hub client checks a file against the manifest's hash prefix again
  (2.0.6 refused every package).
- WONTFIX.txt gains a RUNTIME section.

## 2.0.7 (2026-09-18)

- `IO.args` answers the command line (#821).
- A `Nat` literal past `256n` is `U32.to_nat(n)` underneath (#779).
- The C runtime decodes UTF-8 as WHATWG does (#809).
- `String.length` is an intrinsic on JS (#798).
- An unbalanced `Array` traps on JS (#808).
- The verdict reads "All terms check, with N unsafe annotations."
- WONTFIX.txt lists what we will not change, and why.

## 2.0.6 (2026-09-18)

- Hub installs are atomic and pinned (#794, #787).
- The JS lane refuses names it cannot mangle apart (#790, #799) and scopes
  FFI to its file (#800); emit is linear in program size (#785).
- Nullary imported constructors (#815); `Char.to_upper`/`to_lower` on
  control chars (#803); `F32.read` follows one grammar on C and JS (#801).

## 2.0.5 (2026-09-17)

- `CUDA_HOME` names the CUDA install; `lib` and `lib64` both link (#771).
- `$CC` is tried first, then `clang` and `clang-NN` (#773).
- The runtime's reservation halves until it fits, down to 8 GiB (#774).
- comp.ts passes strict TypeScript (#778).

## 2.0.4 (2026-09-17)

- A `!`-free program on macOS builds as plain C (#769).
- The descent error states its left-to-right rule; the guide says it too
  (#770).

## 2.0.3 (2026-09-17)

- A plain parallel call forks on the CPU pool (#767).
- Hub paths are validated before any directory is made (#768).

## 2.0.2 (2026-09-17)

- The Metal bag stays at 128 groups; only CUDA sizes it to the L2.

## 2.0.1 (2026-09-17)

- The guide as revised on launch day.

## 2.0.0 (2026-09-17)

- Bend 2: a new type checker (an affine dependent type theory), a new
  compiler to C, Metal, CUDA and JavaScript, and a new runtime.
