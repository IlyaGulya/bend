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

def code_main() -> BIR.Code:
  BIR.Code{0, Nil{}, Nil{}, main_body()}

def code_add() -> BIR.Code:
  BIR.Code{1, Nil{}, [p1(), p2()],
    BIR.Let{10, BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(BIR.Local{1}), a(BIR.Local{2})], Nil{}},
      BIR.Return{BIR.Local{10}}}}

def code_cap() -> BIR.Code:
  BIR.Code{2, [BIR.Affine{}], [p41()],
    BIR.Let{11, BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(BIR.Capture{0}), a(BIR.Local{41})], Nil{}},
      BIR.Return{BIR.Local{11}}}}

def code_zero() -> BIR.Code:
  BIR.Code{3, Nil{}, Nil{}, BIR.Return{w(9)}}

def decl_main() -> BIR.Declaration:
  BIR.FunctionDeclaration{"main", 0, Nil{}}

def decl_add() -> BIR.Declaration:
  BIR.FunctionDeclaration{"add", 1, [p1(), p2()]}

def decl_zero() -> BIR.Declaration:
  BIR.FunctionDeclaration{"zero", 3, Nil{}}

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

def program() -> BIR.Program:
  BIR.Program{[code_main(), code_add(), code_cap(), code_zero()], [decl_main(), decl_add(), decl_zero()], runtime_ctors(), [u32_family()], Nil{}, BIR.Executable{BIR.DescriptorRef{"U32", Nil{}}}}

def main() -> CBackendSmoke:
  match CB.emit(program(), Runtime.runtime_source(), Nil{}):
    case CB.EmitSuccess{source}: CBackendSmoke{source}
    case CB.EmitFailure{message}: CBackendSmokeFail{message}
