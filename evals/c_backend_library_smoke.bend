# C backend library smoke: a real BIR.Library through the canonical C target.
#
# Exercises the export boundary end to end from checked facts only: a direct
# two-argument export, a direct export with extra host arguments (the entry
# consumes its parameters and returns a closure), a zero-arity direct export,
# and two symbol exports (lazy zero-arity and a lazy closure factory that must
# be fresh on every call).
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

def code_add() -> BIR.Code:
  BIR.Code{1, Nil{}, [p1(), p2()],
    BIR.Let{10, add_call(1, 2), BIR.Return{BIR.Local{10}}}}

# One semantic parameter; the result is a closure over it, so the host may
# supply the remaining checked argument and have it applied in order.
def code_partial() -> BIR.Code:
  BIR.Code{2, Nil{}, [p1()],
    BIR.Let{12, BIR.Closure{4, [a(BIR.Local{1})], [p41()]}, BIR.Return{BIR.Local{12}}}}

def code_zero() -> BIR.Code:
  BIR.Code{3, Nil{}, Nil{}, BIR.Return{w(9)}}

def code_cap() -> BIR.Code:
  BIR.Code{4, [BIR.Affine{}], [p41()],
    BIR.Let{11, add_call(0, 41), BIR.Return{BIR.Local{11}}}}

def decl_zero() -> BIR.Declaration:
  BIR.LazyDeclaration{"zero", BIR.Return{w(9)}}

def decl_factory() -> BIR.Declaration:
  BIR.LazyDeclaration{"factory", BIR.Let{13, BIR.Closure{4, [a(w(5))], [p41()]}, BIR.Return{BIR.Local{13}}}}

def ctor(id: U32, key: String, arity: Nat) -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{id, key, None{}, List.replicate(Maybe<&2, String>, arity, None{})}

def runtime_ctors() -> List<&2, BIR.ConstructorLayout>:
  [
    ctor(0, "Nil", 0n),
    ctor(1, "Con", 2n),
    ctor(2, "Tuple", 2n),
    ctor(3, "SNil", 0n),
    ctor(4, "SCon", 2n),
    ctor(5, "WCon", 2n),
    ctor(6, "Emit", 0n),
    ctor(7, "Halt", 0n),
    ctor(8, "Exit", 0n),
    ctor(9, "Fail", 0n),
    ctor(10, "Done", 1n),
    ctor(11, "Ready", 1n),
    ctor(12, "Wait", 1n),
    ctor(13, "None", 0n),
    ctor(14, "Some", 1n)
  ]

def u32_family() -> BIR.Family:
  BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, Nil{}}

# The declared codomain travels with every export. This target has no host text
# seam and ignores it, so it names the real result type only for coherence.
def arrow(result: BIR.Descriptor) -> BIR.Descriptor:
  BIR.DescriptorArrow{BIR.Once{}, u32_type(), result}

def export(key: String, entry: Maybe<&2, BIR.Entry>, types: List<&2, BIR.Descriptor>, result: BIR.Descriptor) -> BIR.Export:
  BIR.Export{key, entry, types, result}

def exports() -> List<&2, BIR.Export>:
  [
    export("add", Some{BIR.Entry{1, 2n}}, [u32_type(), u32_type()], u32_type()),
    export("symbol_add", None{}, [u32_type(), u32_type()], u32_type()),
    export("partial", Some{BIR.Entry{2, 1n}}, [u32_type(), u32_type()], arrow(u32_type())),
    export("zero", None{}, Nil{}, u32_type()),
    export("factory", None{}, Nil{}, arrow(u32_type())),
    export("mk", Some{BIR.Entry{3, 0n}}, Nil{}, u32_type())
  ]

def program() -> BIR.Program:
  BIR.Program{[code_add(), code_partial(), code_zero(), code_cap()], [decl_zero(), decl_factory()], runtime_ctors(), [u32_family()], Nil{}, BIR.Library{exports()}}

def rendered() -> String:
  match CB.emit(program(), Runtime.runtime_source(), Nil{}):
    case CB.EmitSuccess{source}: source
    case CB.EmitFailure{message}: String.concat(["ERROR: ", message])
