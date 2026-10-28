# C backend library smoke: a real BIR.Library through the canonical C target.
#
# Exercises the export boundary end to end from checked facts only: a direct
# two-argument export, a function declaration exported as a symbol, a direct
# export with extra host arguments (the entry consumes its parameters and
# returns a closure), a zero-arity direct export, and two lazy symbol exports
# (a zero-arity value and a closure factory that must be fresh on every call).
import Base
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/c_backend.bend as CB
import ./c_backend_runtime.bend as Runtime

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

def u32_type() -> BIR.Descriptor:
  BIR.DescriptorRef{"U32", Nil{}}

def add_call(l: U32, r: U32) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(BIR.Local{l}), a(BIR.Local{r})], Nil{}}

# A lifted closure body reads a captured value by slot and its own parameter by
# id: BIR.Code.captures is the Capture slot list, never a local id.
def capture_add_call(slot: U32, local: U32) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(BIR.Capture{slot}), a(BIR.Local{local})], Nil{}}

def code_add() -> BIR.Code:
  BIR.Code{1, Nil{}, [p1(), p2()],
    BIR.Let{10, add_call(1, 2), BIR.Return{BIR.Local{10}}}}

# The same published signature reached through a symbol export, with the
# arguments swapped exactly as the source fixture writes it.
def code_symbol_add() -> BIR.Code:
  BIR.Code{5, Nil{}, [p1(), p2()],
    BIR.Let{14, add_call(2, 1), BIR.Return{BIR.Local{14}}}}

# One semantic parameter; the result is a closure over it, so the host may
# supply the remaining checked argument and have it applied in order.
def code_partial() -> BIR.Code:
  BIR.Code{2, Nil{}, [p1()],
    BIR.Let{12, BIR.Closure{4, [a(BIR.Local{1})], [p41()]}, BIR.Return{BIR.Local{12}}}}

# Exported as a zero-arity direct entry: mode 0 calls a parameterless code
# exactly, which is the ABI case this fixture keeps covered.
def code_zero() -> BIR.Code:
  BIR.Code{3, Nil{}, Nil{}, BIR.Return{w(9)}}

# The lifted closure behind both the partial result and the factory result: one
# capture plus the applied argument.
def code_cap() -> BIR.Code:
  BIR.Code{4, [BIR.Affine{}], [p41()],
    BIR.Let{11, capture_add_call(0, 41), BIR.Return{BIR.Local{11}}}}

def decl_zero() -> BIR.Declaration:
  BIR.LazyDeclaration{"zero", BIR.Return{w(9)}}

def decl_factory() -> BIR.Declaration:
  BIR.LazyDeclaration{"factory", BIR.Let{13, BIR.Closure{4, [a(w(5))], [p41()]}, BIR.Return{BIR.Local{13}}}}

# A symbol export names a declaration, so the export list below must name this
# one; a function declaration registers its code entry, which is the same call
# a direct export makes.
def decl_symbol_add() -> BIR.Declaration:
  BIR.FunctionDeclaration{"symbol_add", 5, [p1(), p2()]}

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
# after the type parameters. Header references resolve applied arguments;
# constructor-field references start at arity and remain abstract.
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
    arm("Tuple", [fld("fst", par(2n)), fld("snd", BIR.DescriptorApplication{par(3n), par(4n)})])
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

# Every export checks U32 values; this program never builds or projects the data
# constructor U32.U32, so its family carries no arm.
def u32_family() -> BIR.Family:
  BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, Nil{}}

def runtime_families() -> List<&2, BIR.Family>:
  [
    list_family(), sigma_family(), string_family(), word_con_family(),
    io_op_family(), result_family(), poll_family(), maybe_family(), u32_family()
  ]

# Export facts match lower_catalog.exports: parameter_types is the full
# published arrow domain list (live_arrow_types) and result is the codomain
# once every published arrow is consumed (live_arrow_result). A returned
# closure therefore does not turn the result into an arrow descriptor; the
# host-facing mode/arity comes from the entry and the domain count.
def export(key: String, entry: Maybe<&2, BIR.Entry>, types: List<&2, BIR.Descriptor>, result: BIR.Descriptor) -> BIR.Export:
  BIR.Export{key, entry, types, result}

def exports() -> List<&2, BIR.Export>:
  [
    export("add", Some{BIR.Entry{1, 2n}}, [u32_type(), u32_type()], u32_type()),
    export("symbol_add", None{}, [u32_type(), u32_type()], u32_type()),
    export("partial", Some{BIR.Entry{2, 1n}}, [u32_type(), u32_type()], u32_type()),
    export("zero", None{}, Nil{}, u32_type()),
    export("factory", None{}, [u32_type()], u32_type()),
    export("mk", Some{BIR.Entry{3, 0n}}, Nil{}, u32_type())
  ]

def program() -> BIR.Program:
  BIR.Program{[code_add(), code_symbol_add(), code_partial(), code_zero(), code_cap()], [decl_zero(), decl_factory(), decl_symbol_add()], runtime_ctors(), runtime_families(), Nil{}, BIR.Library{exports()}}

def rendered() -> String:
  match CB.emit(program(), Runtime.runtime_source(), Nil{}):
    case CB.EmitSuccess{source}: source
    case CB.EmitFailure{message}: String.concat(["ERROR: ", message])
