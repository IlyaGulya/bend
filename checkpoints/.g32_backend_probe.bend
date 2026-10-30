import Base
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/backend_transport.bend as Transport
import ../bend2/selfhost/c_backend.bend as C
import ../bend2/selfhost/js_backend.bend as JS
import ../evals/c_backend_smoke.bend as Fixture
import ../evals/c_backend_runtime.bend as Runtime
import ../bend2/selfhost/loaded_module.bend as Loader

type ProbeSource is Data:
  ProbeSource{mode: U32, target: Bool, source: String}
type ProbeBatch is Data:
  ProbeBatch{sources: List<&2, ProbeSource>, optimized: BIR.Program, validation: List<&2, String>}

def arg(value: BIR.Atom) -> BIR.Arg:
  BIR.Arg{BIR.Affine{}, value}
def word(value: U32) -> BIR.Atom:
  BIR.Word{value}
def param(id: U32) -> BIR.Parameter:
  BIR.Parameter{id, BIR.Many{}}
def add(left: U32, right: U32) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimU32Add{}, [arg(BIR.Local{left}), arg(BIR.Local{right})], Nil{}}
def vector() -> BIR.Code:
  BIR.Code{10, Nil{}, [param(1)], BIR.ReturnValues{[word(777), BIR.TextValue{"safe"}, BIR.Local{1}]}}
def scalar() -> BIR.Code:
  BIR.Code{12, Nil{}, Nil{}, BIR.Return{word(7)}}
def recursor() -> BIR.Code:
  BIR.Code{20, Nil{}, [param(21)],
    BIR.Let{22, BIR.PrimitiveCall{BIR.PrimU32IsEq{}, [arg(BIR.Local{21}), arg(word(0))], Nil{}},
      BIR.Branch{BIR.Local{22}, BIR.TailDirect{10, [arg(word(9))]},
        BIR.Let{23, BIR.PrimitiveCall{BIR.PrimU32Sub{}, [arg(BIR.Local{21}), arg(word(1))], Nil{}},
          BIR.TailDirect{20, [arg(BIR.Local{23})]}}}}}
def vector_main(depth: U32) -> BIR.Block:
  BIR.LetValues{[110, 111, 112], 20, [arg(word(depth))],
    BIR.Let{113, BIR.Direct{12, Nil{}},
      BIR.Let{114, BIR.PrimitiveCall{BIR.PrimStringLength{}, [arg(BIR.Local{111})], Nil{}},
        BIR.Let{117, BIR.PrimitiveCall{BIR.PrimU32FromNat{}, [arg(BIR.Local{114})], Nil{}},
          BIR.Let{115, add(112, 113),
            BIR.Let{116, add(115, 117), BIR.Return{BIR.Local{116}}}}}}}}
def producer() -> BIR.Code:
  BIR.Code{30, Nil{}, [param(31)],
    BIR.Let{32, BIR.PrimitiveCall{BIR.PrimU32Add{}, [arg(BIR.Local{31}), arg(word(1))], Nil{}},
      BIR.Let{33, BIR.Construct{15, "Pair", [BIR.Field{0, "left", BIR.Affine{}, BIR.Local{31}}, BIR.Field{1, "right", BIR.Affine{}, BIR.Local{32}}]},
        BIR.Return{BIR.Local{33}}}}}
def consumer() -> BIR.Code:
  BIR.Code{40, Nil{}, [param(41)],
    BIR.Let{42, BIR.Project{BIR.Local{41}, 15, 0, "left"},
      BIR.Let{43, BIR.Project{BIR.Local{41}, 15, 1, "right"},
        BIR.Let{44, add(42, 43), BIR.Return{BIR.Local{44}}}}}}
def aggregate_main() -> BIR.Block:
  BIR.Let{50, BIR.Direct{30, [arg(word(17))]},
    BIR.Let{51, BIR.Direct{40, [arg(BIR.Local{50})]}, BIR.Return{BIR.Local{51}}}}
def pair_layout() -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{15, "Pair", None{}, [Some{"left"}, Some{"right"}]}
def pair_family() -> BIR.Family:
  BIR.Family{"Pair", "Pair", None{}, 0n, 0n,
    [BIR.DescriptorArm{"Pair", [BIR.DescriptorField{Some{"left"}, BIR.Once{}, BIR.DescriptorRef{"U32", Nil{}}}, BIR.DescriptorField{Some{"right"}, BIR.Once{}, BIR.DescriptorRef{"U32", Nil{}}}]}]}
def duplicate() -> BIR.Code:
  BIR.Code{70, Nil{}, [param(71)], BIR.ReturnValues{[BIR.Local{71}, BIR.Local{71}]}}
def duplicate_main() -> BIR.Block:
  BIR.Let{72, BIR.Construct{0, "Nil", Nil{}},
    BIR.Let{73, BIR.Construct{1, "Con", [BIR.Field{0, "head", BIR.Affine{}, word(7)}, BIR.Field{1, "tail", BIR.Affine{}, BIR.Local{72}}]},
      BIR.LetValues{[74, 75], 70, [arg(BIR.Local{73})],
        BIR.Let{76, BIR.Project{BIR.Local{74}, 1, 0, "head"},
          BIR.Let{77, BIR.Project{BIR.Local{75}, 1, 0, "head"},
            BIR.Let{78, add(76, 77), BIR.Return{BIR.Local{78}}}}}}}}
def wide() -> BIR.Code:
  BIR.Code{80, Nil{}, Nil{}, BIR.ReturnValues{[word(1), word(2), word(3), word(4), word(5), word(6), word(7), word(8), word(9), word(10)]}}
def wide_main() -> BIR.Block:
  BIR.Let{190, BIR.Copy{word(50)},
    BIR.LetValues{[200, 201, 202, 203, 204, 205, 206, 207, 208, 209], 80, Nil{},
      BIR.Let{210, BIR.Direct{12, Nil{}},
        BIR.Let{211, add(200, 209),
          BIR.Let{212, add(211, 190),
            BIR.Let{213, add(212, 210), BIR.Return{BIR.Local{213}}}}}}}}
def runtime_ctors() -> List<&2, BIR.ConstructorLayout>:
  List.append(&2, BIR.ConstructorLayout, Fixture.runtime_ctors(), [pair_layout(), BIR.ConstructorLayout{16, "True", Some{"Bool.True"}, Nil{}}, BIR.ConstructorLayout{17, "False", Some{"Bool.False"}, Nil{}}])
def runtime_families() -> List<&2, BIR.Family>:
  List.append(&2, BIR.Family, Fixture.runtime_families(), [pair_family(), BIR.Family{"Bool", "Bool", Some{"Bool"}, 0n, 0n, [BIR.DescriptorArm{"True", Nil{}}, BIR.DescriptorArm{"False", Nil{}}]}])
def simple_program(codes: List<&2, BIR.Code>, body: BIR.Block) -> BIR.Program:
  BIR.Program{codes, [BIR.LazyDeclaration{"main", body}], runtime_ctors(), runtime_families(), Nil{}, BIR.Executable{BIR.DescriptorRef{"U32", Nil{}}}}
def program(mode: U32) -> BIR.Program:
  match mode:
    case 2:
      simple_program([producer(), consumer()], aggregate_main())
    case 3: simple_program([duplicate()], duplicate_main())
    case 9: simple_program([wide(), scalar()], wide_main())
    case _:
      BIR.Program{[vector(), scalar(), recursor()], [BIR.LazyDeclaration{"main", vector_main(mode)}], runtime_ctors(), runtime_families(), Nil{}, BIR.Executable{BIR.DescriptorRef{"U32", Nil{}}}}
def render_c(mode: U32) -> String:
  match C.emit(Transport.optimize(program(mode)), Runtime.runtime_source(), Nil{}):
    case C.EmitSuccess{source}: source
    case C.EmitFailure{message}: String.append("ERROR: ", message)
def render_js(mode: U32) -> String:
  match JS.emit_linked(Transport.optimize(program(mode)), Nil{}):
    case JS.EmitSuccess{source}: source
    case JS.EmitFailure{message, _}: String.append("ERROR: ", message)
def optimized(mode: U32) -> BIR.Program:
  Transport.optimize(program(mode))
def broken_vector(values: List<&2, BIR.Atom>) -> BIR.Code:
  BIR.Code{90, Nil{}, Nil{}, BIR.ReturnValues{values}}
def broken_public() -> BIR.Program:
  BIR.Program{[vector()], [BIR.FunctionDeclaration{"wide_public", 10, [param(1)]}, BIR.LazyDeclaration{"main", BIR.Return{word(0)}}], Fixture.runtime_ctors(), Fixture.runtime_families(), Nil{}, BIR.Executable{BIR.DescriptorRef{"U32", Nil{}}}}
def invalid(mode: U32) -> BIR.Program:
  match mode:
    case 0: simple_program([broken_vector(Nil{})], BIR.Return{word(0)})
    case 1: simple_program([broken_vector([word(1)])], BIR.Return{word(0)})
    case 2: simple_program([vector()], BIR.LetValues{[4, 5], 10, [arg(word(1))], BIR.Return{word(0)}})
    case 3: simple_program([vector()], BIR.Let{4, BIR.Direct{10, [arg(word(1))]}, BIR.Return{word(0)}})
    case 4: broken_public()
    case 5: simple_program(Nil{}, BIR.ReturnValues{[word(1), word(2)]})
    case 6: simple_program([vector()], BIR.Let{4, BIR.Closure{10, Nil{}, [param(1)]}, BIR.Return{word(0)}})
    case 7: simple_program([BIR.Code{90, Nil{}, Nil{}, BIR.Branch{BIR.Boolean{True{}}, BIR.ReturnValues{[word(1), word(2)]}, BIR.ReturnValues{[word(1), word(2), word(3)]}}}], BIR.Return{word(0)})
    case 8: simple_program(Nil{}, BIR.LetValues{[4, 5], 999, Nil{}, BIR.Return{word(0)}})
    case 9: simple_program([vector(), BIR.Code{91, Nil{}, Nil{}, BIR.Branch{BIR.Boolean{True{}}, BIR.TailDirect{10, [arg(word(1))]}, BIR.Return{word(0)}}}], BIR.Return{word(0)})
    case 10: simple_program([BIR.Code{90, Nil{}, Nil{}, BIR.Failure{"expected"}}], BIR.LetValues{[4, 5], 90, Nil{}, BIR.Return{word(0)}})
    case _: simple_program([vector()], BIR.LetValues{[4, 4, 5], 10, [arg(word(1))], BIR.Return{word(0)}})
def width_status(mode: U32) -> String:
  match Transport.result_widths(invalid(mode)):
    case Transport.WidthsOk{_}: "accepted"
    case Transport.WidthsFail{_}: "rejected"
def render_pair(+mode: U32) -> List<&2, ProbeSource>:
  [ProbeSource{mode, False{}, render_c(mode)}, ProbeSource{mode, True{}, render_js(mode)}]
def render_modes(modes: List<&2, U32>) -> List<&2, ProbeSource>:
  match modes:
    case Nil{}: Nil{}
    case mode <> rest: List.append(&2, ProbeSource, render_pair(mode), render_modes(rest))
def validate_modes(modes: List<&2, U32>) -> List<&2, String>:
  match modes:
    case Nil{}: Nil{}
    case mode <> rest: width_status(mode) <> validate_modes(rest)
def main(modules: List<&2, Loader.LoadedModule>) -> ProbeBatch:
  ProbeBatch{render_modes([0, 1000, 2, 3, 9]), optimized(2), validate_modes([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])}
