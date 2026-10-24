# Diagnostic-only data fixture: the canonical C backend smoke program as
# passive BIR facts, without importing c_backend.bend's computed emit check.
# Copied from evals/c_backend_smoke.bend; it contains program/constructor data,
# not a second renderer or checker implementation.
import Base
import ../bend2/selfhost/backend_ir.bend as BIR
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

def runtime_field() -> BIR.DescriptorField:
  BIR.DescriptorField{None{}, BIR.Unrestricted{}, BIR.DescriptorNull{}}

def runtime_arm(key: String, arity: Nat) -> BIR.DescriptorArm:
  BIR.DescriptorArm{key, List.replicate(BIR.DescriptorField, arity, runtime_field())}

def runtime_family(key: String, name: String, arm_key: String, arity: Nat) -> BIR.Family:
  BIR.Family{key, name, None{}, 0n, 0n, [runtime_arm(arm_key, arity)]}

def u32_family() -> BIR.Family:
  BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, Nil{}}

def runtime_families() -> List<&2, BIR.Family>:
  [runtime_family("Nil", "Nil", "Nil", 0n),
   runtime_family("Con", "Con", "Con", 2n),
   runtime_family("Tuple", "Tuple", "Tuple", 2n),
   runtime_family("SNil", "SNil", "SNil", 0n),
   runtime_family("SCon", "SCon", "SCon", 2n),
   runtime_family("WCon", "WCon", "WCon", 2n),
   runtime_family("Emit", "Emit", "Emit", 0n),
   runtime_family("Halt", "Halt", "Halt", 0n),
   runtime_family("Exit", "Exit", "Exit", 0n),
   runtime_family("Fail", "Fail", "Fail", 0n),
   runtime_family("Done", "Done", "Done", 1n),
   runtime_family("Ready", "Ready", "Ready", 1n),
   runtime_family("Wait", "Wait", "Wait", 1n),
   runtime_family("None", "None", "None", 0n),
   runtime_family("Some", "Some", "Some", 1n),
   u32_family()]

def program() -> BIR.Program:
  BIR.Program{[code_main(), code_add(), code_cap(), code_zero()], [decl_main(), decl_add(), decl_zero()], runtime_ctors(), runtime_families(), Nil{}, BIR.Executable{BIR.DescriptorRef{"U32", Nil{}}}}

def runtime() -> String:
  Runtime.runtime_source()
