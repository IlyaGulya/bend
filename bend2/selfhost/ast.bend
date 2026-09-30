import Base

type SourceSpan is Data:
  SpanOf{file: String, beg: Nat, end: Nat}

type Quantity is Data:
  QZero{}
  QOne{}
  QMany{}

type SyntaxPattern is Data:
  PatternVar{key: String, index: Nat, quantity: Quantity, span: SourceSpan}
  PatternCtr{key: String, fields: List<&2, SyntaxPattern>, span: SourceSpan}

type SyntaxTerm is Data:
  TermVar{key: String, index: Nat, span: SourceSpan}
  TermRef{key: String, span: SourceSpan}
  TermBang{term: SyntaxTerm, span: SourceSpan}
  TermSub{index: Nat, value: SyntaxTerm, body: SyntaxTerm, span: SourceSpan}
  TermLet{keys: List<&2, String>, indexes: List<&2, Nat>, quantities: List<&2, Quantity>, values: List<&2, SyntaxTerm>, body: SyntaxTerm, span: SourceSpan}
  TermAnn{term: SyntaxTerm, ty: SyntaxTerm, span: SourceSpan}
  TermTemplate{term: SyntaxTerm, span: SourceSpan}
  TermType{kind: SyntaxTerm, span: SourceSpan}
  TermQuant{}
  TermQuantity{quantity: Quantity, span: SourceSpan}
  TermMin{left: SyntaxTerm, right: SyntaxTerm, span: SourceSpan}
  TermAll{quantity: Quantity, key: String, index: Nat, ty: SyntaxTerm, body: SyntaxTerm, span: SourceSpan}
  TermLam{quantity: Maybe<&2, Quantity>, key: String, index: Nat, body: SyntaxTerm, span: SourceSpan}
  TermApp{fn: SyntaxTerm, arg: SyntaxTerm, span: SourceSpan}
  TermAdt{key: String, args: List<&2, SyntaxTerm>, refs: List<&2, String>, span: SourceSpan}
  TermFill{head: SyntaxTerm, args: List<&2, SyntaxTerm>, span: SourceSpan}
  TermPlus{head: SyntaxTerm, args: List<&2, SyntaxTerm>, span: SourceSpan}
  TermCtr{key: String, args: List<&2, SyntaxTerm>, span: SourceSpan}
  TermMat{key: String, head: SyntaxTerm, matched: SyntaxTerm, span: SourceSpan}
  TermAbsurd{span: SourceSpan}
  TermEqual{left: SyntaxTerm, right: SyntaxTerm, ty: SyntaxTerm, span: SourceSpan}
  TermRefl{span: SourceSpan}
  TermRewrite{equation: SyntaxTerm, proof: SyntaxTerm, body: SyntaxTerm, span: SourceSpan}
  TermHole{key: String, span: SourceSpan}
  BodyMatch{scrutinees: List<&2, SyntaxTerm>, cases: List<&2, SyntaxTerm>, span: SourceSpan}
  BodyCase{patterns: List<&2, SyntaxPattern>, body: SyntaxTerm, span: SourceSpan}
  BodyLocal{patterns: List<&2, SyntaxPattern>, quantity: Quantity, values: List<&2, SyntaxTerm>, body: SyntaxTerm, span: SourceSpan}
  BodyReply{term: SyntaxTerm, span: SourceSpan}

type TelescopeItem is Data:
  Binder{quantity: Quantity, key: String, index: Nat, ty: SyntaxTerm, span: SourceSpan}
  TemplateBinder{key: String, index: Nat, ty: SyntaxTerm, span: SourceSpan}

type Clause is Data:
  ClauseFor{universal: Bool, quantity: Quantity, key: String, ty: SyntaxTerm, condition: Maybe<&2, SyntaxTerm>, span: SourceSpan}

type ConstructorDecl is Data:
  Constructor{key: String, fields: List<&2, TelescopeItem>, span: SourceSpan}

type DefBody is Data:
  DefTerm{term: SyntaxTerm}
  DefImports{paths: List<&2, String>}

type OptionalTerm is Data:
  NoTerm{}
  SomeTerm{term: SyntaxTerm}

type Definition is Data:
  Definition{key: String, binders: List<&2, TelescopeItem>, result: OptionalTerm, body: DefBody, unsafe: Bool, span: SourceSpan}

type TypeDecl is Data:
  TypeDecl{key: String, params: List<&2, TelescopeItem>, kind: SyntaxTerm, constructors: List<&2, ConstructorDecl>, span: SourceSpan}

type LawDecl is Data:
  LawDecl{key: String, clauses: List<&2, Clause>, body: SyntaxTerm, span: SourceSpan}

type TopLevel is Data:
  DefTop{definition: Definition}
  TypeTop{declaration: TypeDecl}
  LawTop{declaration: LawDecl}

type ModuleImport is Data:
  ModuleImport{path: String, alias: String, span: SourceSpan}

type Module is Data:
  Module{path: String, imports: List<&2, ModuleImport>, declarations: List<&2, TopLevel>}
