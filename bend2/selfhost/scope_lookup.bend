import Base
import ./ast.bend as Ast
import ./checker_ir.bend as IR
import ./index_lookup.bend as IndexLookup

type GlobalKind is Data:
  GlobalFamily{}
  GlobalConstructor{}
  GlobalDefinition{}

# The public check_modules input accepts the original declaration convention.
# These AST values are consumed by the entry adapter, never retained as fallback.
type Global is Data:
  Global{key: String, namespace: String, local_key: String, ty: Ast.SyntaxTerm, value: Ast.OptionalTerm, kind: GlobalKind}

type ArenaGlobal is Data:
  ArenaGlobal{key: String, namespace: String, local_key: String, ty: U32, value: IR.OptionalTerm, kind: GlobalKind}

# One reference resolved against one immutable global scope. Consumers reuse its
# declared text and selected declaration, without another name read or scope
# lookup. Canonical text is derived only when requested, from that declaration.
# The fact lives within one checking invocation, never in a global name or type
# cache: another scope may select a different declaration for the same text.
# `canonical` retains the interned identity of that canonical text once a
# consumer asks for a name-pool id. It is a name id, not a declaration handle:
# two spellings that select one declaration share it, while `name` keeps the
# source spelling every diagnostic reports.
type ResolvedName is Data:
  ResolvedName{name: String, global: Maybe<&2, ArenaGlobal>, canonical: Maybe<&2, U32>}

# Segments retain alias/candidate/completeness semantics. The immutable lookup
# snapshot has first-entry/family/kind precedence across the ordered segments.
# Read-only queries are native-checked here, outside request/continuation lowering.
type ArenaGlobalBucket is Data:
  ArenaGlobalBucket{first: ArenaGlobal, family: Maybe<&2, ArenaGlobal>, constructor: Maybe<&2, ArenaGlobal>, definition: Maybe<&2, ArenaGlobal>}
type ArenaGlobalIndex is Data:
  ArenaGlobalIndex{values: Map<&2, ArenaGlobalBucket>, constructors: Map<&2, List<&2, ArenaGlobal>>, canonical_aliases: Map<&2, IR.Names>, complete: Bool}
type ArenaGlobalSegment is Data:
  ArenaGlobalSegment{current: Bool, owner: String, alias: String, entries: List<&2, ArenaGlobal>, index: ArenaGlobalIndex}
type ArenaGlobalScope is Data:
  ArenaGlobalScope{entries: List<&2, ArenaGlobal>, index: ArenaGlobalIndex, size: Nat}
  ArenaVisibleScope{segments: List<&2, ArenaGlobalSegment>, lookup: Map<&2, ArenaGlobalBucket>}
  ArenaUnsafeScope{scope: ArenaGlobalScope}

def bucket(+value: ArenaGlobalBucket) -> Maybe<&2, ArenaGlobal>:
  match value:
    case ArenaGlobalBucket{first, +family, _, _}:
      match family:
        case Some{_}: family
        case None{}: Some{first}

def bucket_kind(value: ArenaGlobalBucket, kind: GlobalKind) -> Maybe<&2, ArenaGlobal>:
  match value kind:
    case ArenaGlobalBucket{_, family, _, _} GlobalFamily{}: family
    case ArenaGlobalBucket{_, _, constructor, _} GlobalConstructor{}: constructor
    case ArenaGlobalBucket{_, _, _, definition} GlobalDefinition{}: definition

def index_result(value: Maybe<&2, ArenaGlobalBucket>) -> Maybe<&2, ArenaGlobal>:
  match value:
    case None{}: None{}
    case Some{entry}: bucket(entry)

def index_kind_result(value: Maybe<&2, ArenaGlobalBucket>, kind: GlobalKind) -> Maybe<&2, ArenaGlobal>:
  match value:
    case None{}: None{}
    case Some{entry}: bucket_kind(entry, kind)

def index(+name: String, value: ArenaGlobalIndex) -> Maybe<&2, ArenaGlobal>:
  match value:
    case ArenaGlobalIndex{values, _, _, _}:
      index_result(IndexLookup.find(ArenaGlobalBucket, values, name))

def index_kind(+name: String, kind: GlobalKind, value: ArenaGlobalIndex) -> Maybe<&2, ArenaGlobal>:
  match value:
    case ArenaGlobalIndex{values, _, _, _}:
      index_kind_result(IndexLookup.find(ArenaGlobalBucket, values, name), kind)

def lookup(+name: String, scope: ArenaGlobalScope) -> Maybe<&2, ArenaGlobal>:
  match scope:
    case ArenaGlobalScope{_, values, _}: index(name, values)
    case ArenaVisibleScope{_, values}: index_result(IndexLookup.find(ArenaGlobalBucket, values, name))
    case ArenaUnsafeScope{inner}: lookup(name, inner)

def lookup_kind(+name: String, +kind: GlobalKind, scope: ArenaGlobalScope) -> Maybe<&2, ArenaGlobal>:
  match scope:
    case ArenaGlobalScope{_, values, _}: index_kind(name, kind, values)
    case ArenaVisibleScope{_, values}: index_kind_result(IndexLookup.find(ArenaGlobalBucket, values, name), kind)
    case ArenaUnsafeScope{inner}: lookup_kind(name, kind, inner)

def canonical_key(+namespace: String, local: String, empty: Bool) -> String:
  match empty:
    case True{}: local
    case False{}: String.append(namespace, String.append(".", local))

def canonical_of(+global: ArenaGlobal) -> String:
  match global:
    case ArenaGlobal{_, +namespace, local, _, _, _}:
      canonical_key(namespace, local, String.eq(namespace, ""))

def canonical_name_result(name: String, value: Maybe<&2, ArenaGlobal>) -> String:
  match value:
    case None{}: name
    case Some{global}: canonical_of(global)

def canonical_name(+name: String, scope: ArenaGlobalScope) -> String:
  canonical_name_result(name, lookup(name, scope))

def equal_names_result(left: String, right: String, +scope: ArenaGlobalScope, same: Bool) -> Bool:
  match same:
    case True{}: True{}
    case False{}: String.eq(canonical_name(left, scope), canonical_name(right, scope))

def equal_names(+left: String, +right: String, scope: ArenaGlobalScope) -> Bool:
  equal_names_result(left, right, scope, String.eq(left, right))

def resolved_result(+name: String, +result: Maybe<&2, ArenaGlobal>) -> ResolvedName:
  ResolvedName{name, result, None{}}

def resolved(+name: String, scope: ArenaGlobalScope) -> ResolvedName:
  resolved_result(name, lookup(name, scope))

def resolved_kind(+name: String, +kind: GlobalKind, scope: ArenaGlobalScope) -> ResolvedName:
  resolved_result(name, lookup_kind(name, kind, scope))

def resolved_text(value: ResolvedName) -> String:
  match value:
    case ResolvedName{name, _, _}: name

def resolved_canonical(value: ResolvedName) -> String:
  match value:
    case ResolvedName{name, global, _}: canonical_name_result(name, global)

def resolved_global(value: ResolvedName) -> Maybe<&2, ArenaGlobal>:
  match value:
    case ResolvedName{_, global, _}: global

def resolved_canonical_id(value: ResolvedName) -> Maybe<&2, U32>:
  match value:
    case ResolvedName{_, _, canonical}: canonical

def resolved_with_canonical(value: ResolvedName, +canonical: U32) -> ResolvedName:
  match value:
    case ResolvedName{name, global, _}: ResolvedName{name, global, Some{canonical}}
