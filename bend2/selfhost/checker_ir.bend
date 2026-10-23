import Base
import ./ast.bend as Ast

# List cursors are transient views of flat arena tapes. Stored descriptors keep
# start/count scalars inline; no recursive syntax graph is retained here.
type Words is Data:
  Words{start: U32, count: U32}
type Names is Data:
  Names{start: U32, count: U32}
type Naturals is Data:
  Naturals{start: U32, count: U32}
type Quantities is Data:
  Quantities{start: U32, count: U32}
type WordView is Data:
  WordNil{}
  WordCons{head: U32, tail: Words}
type NameView is Data:
  NameNil{}
  NameCons{head: String, tail: Names}
type NaturalView is Data:
  NaturalNil{}
  NaturalCons{head: Nat, tail: Naturals}
type QuantityView is Data:
  QuantityNil{}
  QuantityCons{head: Ast.Quantity, tail: Quantities}

# Symbols identify a selected declaration, not an interned spelling or alias.
type SymbolKind is Data:
  FamilySymbol{}
  ConstructorSymbol{}
  DefinitionSymbol{}
type Symbol is Data:
  Symbol{owner: String, local: String, kind: SymbolKind, signature: U32}
type CheckedBinding is Data:
  CheckedBinding{quantity: Ast.Quantity, ty: U32, type_depth: Nat}
type CheckedPattern is Data:
  CheckedVariable{pattern: U32, binding: CheckedBinding}
  CheckedConstructor{pattern: U32, symbol: Symbol, fields: List<&2, CheckedPattern>, layout: List<&2, CheckedBinding>}

# This is an occurrence graph, not a cache keyed by semantic node identity.
# Children belong to this checking invocation even when term handles are shared.
# Typed children: App(fn,arg), Lam(body), Bang(reference), Ann(value,type),
# Type(kind), Min(left,right), All(domain,codomain), Equal(left,right,type),
# Rewrite(equation,proof,body), Mat(hit,default), Ctr/Adt(arguments),
# Let(values...,body), BodyMatch(scrutinees...,checked cases...); atoms have none.
# App/Lam/All/Mat/Absurd have resolved formal quantities. Constructor bindings
# are instantiated field layouts, separately from pattern-variable use demands.
# Sub/Fill/Reply are elaborated away. LocalReference.term preserves the lexical
# variable; its value is semantic substitution metadata, never a runtime operand.
# Scalar symbols are [WNil,WCon,False,True] in the certified root's owner.
# Structural certification alone never grants native numeric representation.
type Occurrence is Data:
  TypedOccurrence{term: U32, ty: U32, formal: Maybe<&2, Ast.Quantity>, symbol: Maybe<&2, Symbol>, bindings: List<&2, CheckedBinding>, children: List<&2, Occurrence>}
  LocalReferenceOccurrence{term: U32, ty: U32, binding: CheckedBinding, value: U32}
  ScalarOccurrence{term: U32, ty: U32, symbol: Symbol, bits: U32, symbols: List<&2, Symbol>}
  StringOccurrence{term: U32, ty: U32, symbols: List<&2, Symbol>, chars: List<&2, U32>}
  CaseOccurrence{term: U32, ty: U32, patterns: List<&2, CheckedPattern>, body: Occurrence}
  LocalOccurrence{term: U32, ty: U32, patterns: List<&2, CheckedPattern>, values: List<&2, Occurrence>, body: Occurrence}

type Clause is Data:
  ClauseFor{universal: Bool, quantity: Ast.Quantity, key: String, ty: U32, condition: Maybe<&2, U32>, span: Ast.SourceSpan}
type ConstructorDecl is Data:
  Constructor{key: String, fields: Words, span: Ast.SourceSpan}
type DefBody is Data:
  DefTerm{term: U32}
  DefImports{paths: Names}
type OptionalTerm is Data:
  NoTerm{}
  SomeTerm{term: U32}
type DefinitionFacts is Data:
  DefinitionFacts{type_only: Bool, fixed_signature: Bool, quantity_prefix: Nat}
type Definition is Data:
  Definition{key: String, binders: Words, result: OptionalTerm, body: DefBody, unsafe: Bool, span: Ast.SourceSpan, checked: Maybe<&2, Occurrence>, facts: Maybe<&2, DefinitionFacts>}
type TypeDecl is Data:
  TypeDecl{key: String, params: Words, kind: U32, constructors: List<&2, ConstructorDecl>, span: Ast.SourceSpan}
type LawDecl is Data:
  LawDecl{key: String, clauses: List<&2, Clause>, body: U32, span: Ast.SourceSpan}
type TopLevel is Data:
  DefTop{definition: Definition}
  TypeTop{declaration: TypeDecl}
  LawTop{declaration: LawDecl}
type Module is Data:
  Module{path: String, imports: List<&2, Ast.ModuleImport>, declarations: List<&2, TopLevel>}
type LoadedModule is Data:
  LoadedModule{namespace: String, module: Module}

# Shared tagged-handle convention. Bit 31 selects the transient owner; bit 30
# reverses a tape cursor. Descriptor counts are logical element counts.
def arena_is_transient(+id: U32) -> Bool:
  U32.is_ne(U32.and(id, 2147483648), 0)

def arena_is_reverse(+start: U32) -> Bool:
  U32.is_ne(U32.and(start, 1073741824), 0)

def arena_node_offset(id: U32) -> U32:
  U32.and(id, 2147483647)

def arena_tape_offset(id: U32) -> U32:
  U32.and(id, 1073741823)

def arena_range_index_direction(start: U32, offset: U32, reverse: Bool) -> U32:
  match reverse:
    case False{}: U32.add(start, offset)
    case True{}: U32.sub(start, offset)

def arena_range_index(+start: U32, offset: U32) -> U32:
  arena_range_index_direction(start, offset, arena_is_reverse(start))

def arena_range_flip_empty(start: U32, count: U32, empty: Bool) -> U32:
  match empty:
    case True{}: start
    case False{}: U32.xor(arena_range_index(start, U32.sub(count, 1)), 1073741824)

def arena_range_flip(start: U32, +count: U32) -> U32:
  arena_range_flip_empty(start, count, U32.is_eq(count, 0))
