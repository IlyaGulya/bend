# C backend smoke: one real BIR program through the canonical C target.
#
# The program exercises a direct call, a first-class closure applied through
# the runtime, a lazy zero-arity read, and a non-tail continuation chain:
#   add(2, 3) + (add(5))(7) + zero()  ==  5 + 12 + 9  ==  26
#
# The renderer is the canonical c_backend module (with CLay and the physical
# emitter), not a copy: the generated C comes from the same source the
# self-host build admits.
import Base
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/c_backend.bend as CB
import ./c_backend_runtime.bend as Runtime

type CBackendSmoke is Data:
  CBackendSmoke{source: String}
  CBackendSmokeFail{message: String}

def w(v: U32) -> BIR.Atom:
  BIR.Word{v}

def a(v: BIR.Atom) -> BIR.Arg:
  BIR.Arg{BIR.Affine{}, v}

def p1() -> BIR.Parameter:
  BIR.Parameter{1, BIR.Affine{}}

def p2() -> BIR.Parameter:
  BIR.Parameter{2, BIR.Affine{}}

def p41() -> BIR.Parameter:
  BIR.Parameter{41, BIR.Affine{}}

def add_call(l: U32, r: U32) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(BIR.Local{l}), a(BIR.Local{r})], Nil{}}

def main_body() -> BIR.Block:
  BIR.Let{30, BIR.Direct{1, [a(w(2)), a(w(3))]},
    BIR.Let{31, BIR.Closure{2, [a(w(5))], [p41()]},
      BIR.Let{32, BIR.Apply{BIR.Local{31}, a(w(7))},
        BIR.Let{33, BIR.LoadSymbol{0, "zero"},
          BIR.Let{34, add_call(30, 32),
            BIR.Let{35, add_call(34, 33),
              BIR.Return{BIR.Local{35}}}}}}}}

def code_add() -> BIR.Code:
  BIR.Code{1, Nil{}, [p1(), p2()],
    BIR.Let{10, BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(BIR.Local{1}), a(BIR.Local{2})], Nil{}},
      BIR.Return{BIR.Local{10}}}}

def code_cap() -> BIR.Code:
  BIR.Code{2, [BIR.Affine{}], [p41()],
    BIR.Let{11, BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(BIR.Capture{0}), a(BIR.Local{41})], Nil{}},
      BIR.Return{BIR.Local{11}}}}

# A definition with no binders is a lazy declaration in the canonical lowering
# (backend_lower.definition_closed: a nullary closed body is LazyDeclaration),
# so main and zero carry their blocks directly and own no Code row.
def decl_main() -> BIR.Declaration:
  BIR.LazyDeclaration{"main", main_body()}

def decl_add() -> BIR.Declaration:
  BIR.FunctionDeclaration{"add", 1, [p1(), p2()]}

def decl_zero() -> BIR.Declaration:
  BIR.LazyDeclaration{"zero", BIR.Return{w(9)}}

# The runtime's constructor rows, in the canonical id order the C prelude names
# them (Nil..Some). Each row keeps the live field names and the native marker
# Base's own declaration gives it: lower_catalog.prepare_constructors marks a
# native constructor "<family>.<short key>", never a bare tag, and its field
# list is the declared field order. The C prelude resolves these keys by name,
# so the program must carry real rows for them, not synthetic placeholders.
def named(key: String) -> Maybe<&2, String>:
  Some{key}

def ctor(id: U32, key: String, native: String, fields: List<&2, Maybe<&2, String>>) -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{id, key, Some{native}, fields}

def runtime_ctors() -> List<&2, BIR.ConstructorLayout>:
  [
    ctor(0, "Nil", "List.Nil", Nil{}),
    ctor(1, "Con", "List.Con", [named("head"), named("tail")]),
    ctor(2, "Tuple", "Sigma.Tuple", [named("fst"), named("snd")]),
    ctor(3, "SNil", "String.SNil", Nil{}),
    ctor(4, "SCon", "String.SCon", [named("head"), named("tail")]),
    ctor(5, "WCon", "Word.Con.WCon", [named("head"), named("tail")]),
    ctor(6, "Emit", "IO.OP.Emit", [named("value")]),
    ctor(7, "Halt", "IO.OP.Halt", [named("code"), named("message")]),
    ctor(8, "Exit", "IO.OP.Exit", [named("code")]),
    ctor(9, "Fail", "Result.Fail", [named("error")]),
    ctor(10, "Done", "Result.Done", [named("value")]),
    ctor(11, "Ready", "Poll.Ready", [named("value")]),
    ctor(12, "Wait", "Poll.Wait", [named("rest")]),
    ctor(13, "None", "Maybe.None", Nil{}),
    ctor(14, "Some", "Maybe.Some", [named("value")])
  ]

# The families that declare those constructors. base.bend declares each arm;
# lower_catalog derives a native family's geometry from the checked telescope
# (metadata_prefix counts the leading kind binders, words_count the declared
# parameters) and marks the family with its own name. Field descriptors are the
# declared types in the constructor telescope, whose binder indices continue
# after the type parameters, so a field naming a parameter reads the applied
# argument at that index.
def par(index: Nat) -> BIR.Descriptor:
  BIR.DescriptorParameter{index}

def ref(key: String) -> BIR.Descriptor:
  BIR.DescriptorRef{key, Nil{}}

def applied(key: String, args: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  BIR.DescriptorRef{key, args}

def fld(key: String, ty: BIR.Descriptor) -> BIR.DescriptorField:
  BIR.DescriptorField{Some{key}, BIR.Once{}, ty}

def arm(key: String, fields: List<&2, BIR.DescriptorField>) -> BIR.DescriptorArm:
  BIR.DescriptorArm{key, fields}

def family(key: String, quantity_prefix: Nat, arity: Nat, arms: List<&2, BIR.DescriptorArm>) -> BIR.Family:
  BIR.Family{key, key, Some{key}, quantity_prefix, arity, arms}

def list_family() -> BIR.Family:
  family("List", 1n, 2n, [
    arm("Nil", Nil{}),
    arm("Con", [fld("head", par(1n)), fld("tail", applied("List", [par(0n), par(1n)]))])
  ])

def sigma_family() -> BIR.Family:
  family("Sigma", 2n, 4n, [
    arm("Tuple", [fld("fst", par(2n)), fld("snd", BIR.DescriptorApplication{par(3n), par(2n)})])
  ])

def string_family() -> BIR.Family:
  family("String", 0n, 0n, [
    arm("SNil", Nil{}),
    arm("SCon", [fld("head", ref("Char")), fld("tail", ref("String"))])
  ])

def word_con_family() -> BIR.Family:
  family("Word.Con", 0n, 1n, [
    arm("WCon", [fld("head", ref("Bool")), fld("tail", applied("Word", [par(0n)]))])
  ])

def io_op_family() -> BIR.Family:
  family("IO.OP", 0n, 1n, [
    arm("Emit", [fld("value", par(0n))]),
    arm("Halt", [fld("code", ref("U32")), fld("message", ref("String"))]),
    arm("Exit", [fld("code", ref("U32"))])
  ])

def result_family() -> BIR.Family:
  family("Result", 2n, 4n, [
    arm("Fail", [fld("error", par(2n))]),
    arm("Done", [fld("value", par(3n))])
  ])

def poll_family() -> BIR.Family:
  family("Poll", 2n, 4n, [
    arm("Ready", [fld("value", par(2n))]),
    arm("Wait", [fld("rest", par(3n))])
  ])

def maybe_family() -> BIR.Family:
  family("Maybe", 1n, 2n, [
    arm("None", Nil{}),
    arm("Some", [fld("value", par(1n))])
  ])

# Main's type is U32: the family's native marker is what the SHOW builder reads
# for the unboxed U32 kind. No arm is declared because this program never builds
# or projects the data constructor U32.U32.
def u32_family() -> BIR.Family:
  BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, Nil{}}

def runtime_families() -> List<&2, BIR.Family>:
  [
    list_family(), sigma_family(), string_family(), word_con_family(),
    io_op_family(), result_family(), poll_family(), maybe_family(), u32_family()
  ]

def program() -> BIR.Program:
  BIR.Program{[code_add(), code_cap()], [decl_main(), decl_add(), decl_zero()], runtime_ctors(), runtime_families(), Nil{}, BIR.Executable{BIR.DescriptorRef{"U32", Nil{}}}}

def main() -> CBackendSmoke:
  match CB.emit(program(), Runtime.runtime_source(), Nil{}):
    case CB.EmitSuccess{source}: CBackendSmoke{source}
    case CB.EmitFailure{message}: CBackendSmokeFail{message}
