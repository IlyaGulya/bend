import Base
import ./ast.bend as Ast
import ./checker_ir.bend as IR

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

# Segments retain alias/candidate/completeness semantics. The immutable lookup
# snapshot has first-entry/family/kind precedence across the ordered segments.
# Algorithms live in checker.bend for ordinary typed checker-request lowering.
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
