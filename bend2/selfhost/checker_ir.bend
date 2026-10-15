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
type Definition is Data:
  Definition{key: String, binders: Words, result: OptionalTerm, body: DefBody, unsafe: Bool, span: Ast.SourceSpan}
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
