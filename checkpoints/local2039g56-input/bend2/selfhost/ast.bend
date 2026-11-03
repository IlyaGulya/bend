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

type StringLiteralNames is Data:
  StringLiteralNames{nil: String, cons: String, char: String, uint: String, word_nil: String, word_cons: String, bit_false: String, bit_true: String}

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
  TermString{chars: List<&2, U32>, names: StringLiteralNames, span: SourceSpan}
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

def string_literal_names() -> StringLiteralNames:
  StringLiteralNames{"SNil", "SCon", "Chr", "U32", "WNil", "WCon", "False", "True"}

def string_bit(value: Nat, names: StringLiteralNames, span: SourceSpan) -> SyntaxTerm:
  match value names:
    case 0n StringLiteralNames{_, _, _, _, _, _, bit_false, _}: TermCtr{bit_false, Nil{}, span}
    case _ StringLiteralNames{_, _, _, _, _, _, _, bit_true}: TermCtr{bit_true, Nil{}, span}

def string_word(remaining: Nat, +value: Nat, +names: StringLiteralNames, +span: SourceSpan) -> SyntaxTerm:
  match remaining names:
    case 0n StringLiteralNames{_, _, _, _, word_nil, _, _, _}: TermCtr{word_nil, Nil{}, span}
    case 1n+rest StringLiteralNames{_, _, _, _, _, word_cons, _, _}:
      TermCtr{word_cons, [string_bit(Nat.mod(value, 2n), names, span), string_word(rest, Nat.div(value, 2n), names, span)], span}

def string_character(value: U32, +names: StringLiteralNames, +span: SourceSpan) -> SyntaxTerm:
  match names:
    case StringLiteralNames{_, _, char, uint, _, _, _, _}:
      TermCtr{char, [TermCtr{uint, [string_word(32n, U32.to_nat(value), names, span)], span}], span}

def string_unfold(chars: List<&2, U32>, +names: StringLiteralNames, +span: SourceSpan) -> SyntaxTerm:
  match chars names:
    case Nil{} StringLiteralNames{nil, _, _, _, _, _, _, _}: TermCtr{nil, Nil{}, span}
    case value <> rest StringLiteralNames{_, cons, _, _, _, _, _, _}:
      TermCtr{cons, [string_character(value, names, span), TermString{rest, names, span}], span}

def string_desugar(chars: List<&2, U32>, +names: StringLiteralNames, +span: SourceSpan) -> SyntaxTerm:
  match chars names:
    case Nil{} StringLiteralNames{nil, _, _, _, _, _, _, _}: TermCtr{nil, Nil{}, span}
    case value <> rest StringLiteralNames{_, cons, _, _, _, _, _, _}:
      TermCtr{cons, [string_character(value, names, span), string_desugar(rest, names, span)], span}
