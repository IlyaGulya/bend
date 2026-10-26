import Base
import ./ast.bend as Ast

# Runtime operands contain no source syntax or effects. IDs are labels only;
# code bodies and descriptor programs own structurally decreasing trees.
type Use is Data:
  Affine{}
  Many{}
type Quantity is Data:
  Erased{}
  Once{}
  Unrestricted{}
type Atom is Data:
  Local{id: U32}
  Capture{slot: U32}
  Symbol{id: U32, key: String}
  Word{value: U32}
  Natural{value: Nat}
  FloatBits{bits: U32}
  TextValue{value: String}
  Boolean{value: Bool}
  Null{}
  Undefined{}
type Arg is Data:
  Arg{use: Use, value: Atom}
type Parameter is Data:
  Parameter{id: U32, use: Use}
type Field is Data:
  Field{identity: U32, key: String, use: Use, value: Atom}

# The catalog is closed. Its constructors name target operations, never source
# aliases; only lowering may certify an authoritative native declaration.
type Primitive is Data:
  PrimU32Add{}
  PrimU32Sub{}
  PrimU32Mul{}
  PrimU32Div{}
  PrimNatAdd{}
  PrimNatSub{}
  PrimNatMul{}
  PrimNatCmp{}
  PrimNatMin{}
  PrimNatMax{}
  PrimStringAppend{}
  PrimBoolOr{}
  PrimBoolXor{}
  PrimU32IsZero{}
  PrimF32Asin{}
  PrimF32Acos{}
  PrimF32Atan{}
  PrimF32Sinh{}
  PrimF32Cosh{}
  PrimF32Tanh{}
  PrimU32Mod{}
  PrimU32And{}
  PrimU32Or{}
  PrimU32Xor{}
  PrimU32IsEq{}
  PrimU32IsNe{}
  PrimU32IsLt{}
  PrimU32IsLe{}
  PrimU32IsGt{}
  PrimU32IsGe{}
  PrimU32Inc{}
  PrimU32Not{}
  PrimU32Shl{}
  PrimU32Shr{}
  PrimU32Shln{}
  PrimU32Shrn{}
  PrimU32Cmp{}
  PrimU32ToNat{}
  PrimU32FromNat{}
  PrimF32Add{}
  PrimF32Sub{}
  PrimF32Mul{}
  PrimF32Div{}
  PrimF32Mod{}
  PrimF32Neg{}
  PrimF32Sqrt{}
  PrimF32Abs{}
  PrimF32ToU32{}
  PrimF32Bits{}
  PrimF32Show{}
  PrimF32Read{}
  PrimF32IsEq{}
  PrimF32IsNe{}
  PrimF32IsLt{}
  PrimF32IsLe{}
  PrimF32IsGt{}
  PrimF32IsGe{}
  PrimF32Pow{}
  PrimF32Atan2{}
  PrimF32Exp{}
  PrimF32Log{}
  PrimF32Log2{}
  PrimF32Log10{}
  PrimF32Sin{}
  PrimF32Cos{}
  PrimF32Tan{}
  PrimF32Floor{}
  PrimF32Ceil{}
  PrimF32Trunc{}
  PrimF32ToNat{}
  PrimU32ToF32{}
  PrimNatDouble{}
  PrimNatIsLt{}
  PrimNatDivmod{}
  PrimStringEq{}
  PrimMapBit{}
  PrimStringCmp{}
  PrimStringToList{}
  PrimStringLength{}
  PrimArrayNew{}
  PrimArraySet{}
  PrimArrayGet{}
  PrimArraySwap{}
  PrimArraySize{}
  PrimArrayClone{}
  PrimNatPredecessor{}
  PrimNatSuccessor{}
  PrimCharNew{}
  PrimCharCode{}
  PrimStringHead{}
  PrimStringTail{}
  PrimWordToU32{}
  PrimU32ToWord{}
  PrimF32FromBits{}
  PrimF32FromWord{}
  PrimF32ToWord{}
  PrimArrayLeaf{}
  PrimArrayNode{}
  PrimArrayLeafValue{}
  PrimArrayLeft{}
  PrimArrayRight{}
  PrimIsArrayLeaf{}
  PrimIsArrayNode{}
  PrimIsNatZero{}
  PrimIsNatSuccessor{}
  PrimIsStringEmpty{}
  PrimIsStringNonempty{}
  PrimIsTrue{}
  PrimIsFalse{}
  PrimSameValue{}
  PrimFloatBitsEqual{}

# Runtime reflection is a separate descriptor language, not executable source
# syntax. Keys are canonical before reaching this boundary. Metadata retains
# erased formal slots, because dependent show/IO must still interpret them.
type DescriptorPattern is Data:
  DescriptorBinder{quantity: Quantity}
  DescriptorConstructorPattern{key: String, fields: List<&2, DescriptorPattern>}
type Descriptor is Data:
  DescriptorNull{}
  DescriptorRef{key: String, args: List<&2, Descriptor>}
  DescriptorParameter{index: Nat}
  DescriptorQuantityKind{}
  DescriptorQuantity{quantity: Quantity}
  DescriptorKind{quantity: Descriptor}
  DescriptorMinimum{left: Descriptor, right: Descriptor}
  DescriptorArrow{quantity: Quantity, domain: Descriptor, body: Descriptor}
  DescriptorLambda{quantity: Maybe<&2, Quantity>, body: Descriptor}
  DescriptorConstructor{key: String, args: List<&2, Descriptor>}
  DescriptorApplication{fn: Descriptor, arg: Descriptor}
  DescriptorSubstitution{index: Nat, value: Descriptor, body: Descriptor}
  DescriptorLet{values: List<&2, Descriptor>, body: Descriptor}
  DescriptorLocal{patterns: List<&2, DescriptorPattern>, values: List<&2, Descriptor>, body: Descriptor}
  DescriptorMatch{values: List<&2, Descriptor>, cases: List<&2, Descriptor>}
  DescriptorCase{patterns: List<&2, DescriptorPattern>, body: Descriptor}
  DescriptorBind{value: Descriptor, body: Descriptor}
  DescriptorEquality{left: Descriptor, right: Descriptor, ty: Descriptor}
  DescriptorReflexivity{}
  DescriptorFailure{message: String}
  DescriptorFill{head: Descriptor, args: List<&2, Descriptor>}
  DescriptorPlus{head: Descriptor, args: List<&2, Descriptor>}
  DescriptorNamedFill{key: String, head: Descriptor, args: List<&2, Descriptor>}
  DescriptorNamedPlus{key: String, head: Descriptor, args: List<&2, Descriptor>}

type Op is Data:
  Copy{value: Atom}
  PrimitiveCall{primitive: Primitive, args: List<&2, Arg>, types: List<&2, Descriptor>}
  Closure{code: U32, captures: List<&2, Arg>, parameters: List<&2, Parameter>}
  Direct{code: U32, args: List<&2, Arg>}
  Apply{fn: Atom, arg: Arg}
  LoadSymbol{id: U32, key: String}
  Construct{constructor: U32, tag: String, fields: List<&2, Field>}
  Project{value: Atom, constructor: U32, field: U32, key: String}
  HasTag{value: Atom, constructor: U32, tag: String}

# Let operands are strict. Tail calls only appear as block terminators. Ordered
# over-application is a sequence of strict Direct/Apply lets, never one arg list.
# Partial application is Closure to a lifted adapter with evaluated captures.
# Region/LeaveRegion are lexical forward control flow, not graph jumps.
# A failed nested pattern exits one case; the remaining cases are emitted once.
type Block is Data:
  Return{value: Atom}
  Let{id: U32, op: Op, next: Block}
  Branch{condition: Atom, yes: Block, no: Block}
  Region{label: U32, body: Block, next: Block}
  LeaveRegion{label: U32}
  TailDirect{code: U32, args: List<&2, Arg>}
  TailApply{fn: Atom, arg: Arg}
  Failure{message: String}
type Code is Data:
  Code{id: U32, captures: List<&2, Use>, parameters: List<&2, Parameter>, body: Block}

# Capture parameters precede live parameters at private entries. Public values
# remain unary JS functions with the private raw trampoline marker convention.
# Nullary declarations are reevaluated on every read, including mutable factories.
type Declaration is Data:
  FunctionDeclaration{key: String, code: U32, parameters: List<&2, Parameter>}
  LazyDeclaration{key: String, body: Block}
  NativeDeclaration{key: String, primitive: Primitive, quantities: List<&2, Quantity>}
  # Foreign declarations retain every declared import alternative, so each
  # target selects by extension from authoritative paths and never derives one.
  ForeignDeclaration{key: String, namespace: String, imported: String, arity: Nat, sources: List<&2, String>, quantities: List<&2, Quantity>, span: Ast.SourceSpan, parameter_types: List<&2, Descriptor>, result: Descriptor}
type ConstructorLayout is Data:
  ConstructorLayout{id: U32, key: String, native: Maybe<&2, String>, fields: List<&2, Maybe<&2, String>>}
type DescriptorField is Data:
  DescriptorField{key: Maybe<&2, String>, quantity: Quantity, ty: Descriptor}
type DescriptorArm is Data:
  DescriptorArm{key: String, fields: List<&2, DescriptorField>}
type Family is Data:
  Family{key: String, name: String, native: Maybe<&2, String>, quantity_prefix: Nat, arity: Nat, arms: List<&2, DescriptorArm>}
type TypeFunction is Data:
  TypeFunction{key: String, native: Maybe<&2, String>, quantity_prefix: Nat, arity: Nat, body: Descriptor}
type Entry is Data:
  Entry{code: U32, arity: Nat}
type Export is Data:
  Export{key: String, entry: Maybe<&2, Entry>, parameter_types: List<&2, Descriptor>}
type Ending is Data:
  Executable{main_type: Descriptor}
  Library{exports: List<&2, Export>}
type Program is Data:
  Program{codes: List<&2, Code>, declarations: List<&2, Declaration>, constructors: List<&2, ConstructorLayout>, families: List<&2, Family>, type_functions: List<&2, TypeFunction>, ending: Ending}

# A passive target source carried from an IO adapter to a renderer: the bytes
# and the exact declared path, never a target guess or a rewritten specifier.
type SourceFile is Data:
  SourceFile{path: String, source: String}
