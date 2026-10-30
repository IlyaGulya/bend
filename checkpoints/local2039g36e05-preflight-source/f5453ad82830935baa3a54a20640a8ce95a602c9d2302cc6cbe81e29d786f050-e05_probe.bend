import Base
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/backend_continuation.bend as Pass
import ../bend2/selfhost/c_backend.bend as C
import ../bend2/selfhost/js_backend.bend as JS
import ../bend2/selfhost/loaded_module.bend as Loader
import ../evals/c_backend_smoke.bend as Fixture
import ../evals/c_backend_runtime.bend as Runtime
import ../evals/e05_c_render_seam.bend as CRender
import ./e05_schema.bend as Wire

# Diagnostic source only. All rendering and specialization are canonical Bend.
type ProofRow is Data:
  ProofRow{owner: U32, binding: U32, producer: U32, consumer: U32, record: U32, constructor: U32, continuation: U32, worker: U32}
type RefusalRow is Data:
  RefusalRow{owner: U32, binding: U32, reason: String}
type Inspection is Data:
  Inspection{original: BIR.Program, optimized: BIR.Program, proofs: List<&2, ProofRow>, refusals: List<&2, RefusalRow>}
type ProbeSource is Data:
  ProbeSource{optimized: Bool, target: Bool, source: String}
type ProbeCase is Data:
  ProbeCase{mode: U32, inspection: Inspection, sources: List<&2, ProbeSource>}
type SchemaBundle is Data:
  SchemaBundle{witnesses: List<&2, Wire.NominalWitness>, base: Wire.BaseWitness}
type ProbeBatch is Data:
  ProbeBatch{schema: SchemaBundle, cases: List<&2, ProbeCase>}

def proofs(items: List<&2, Pass.Proof>) -> List<&2, ProofRow>:
  match items:
    case Nil{}: Nil{}
    case Pass.Proof{a, b, c, d, e, f, g, h} <> rest: ProofRow{a, b, c, d, e, f, g, h} <> proofs(rest)
def refusals(items: List<&2, Pass.Refusal>) -> List<&2, RefusalRow>:
  match items:
    case Nil{}: Nil{}
    case Pass.Refusal{a, b, reason} <> rest: RefusalRow{a, b, reason} <> refusals(rest)
def inspect(+program: BIR.Program) -> Inspection:
  match Pass.plan(program):
    case Pass.Plan{optimized, accepted, rejected}: Inspection{program, optimized, proofs(accepted), refusals(rejected)}
def schema() -> SchemaBundle:
  SchemaBundle{Wire.samples(), Wire.base()}
def w(value: U32) -> BIR.Atom:
  BIR.Word{value}
def l(id: U32) -> BIR.Atom:
  BIR.Local{id}
def a(value: BIR.Atom) -> BIR.Arg:
  BIR.Arg{BIR.Affine{}, value}
def p(id: U32) -> BIR.Parameter:
  BIR.Parameter{id, BIR.Affine{}}
def u32() -> BIR.Descriptor:
  BIR.DescriptorRef{"U32", Nil{}}
def array() -> BIR.Descriptor:
  BIR.DescriptorRef{"Array", [u32()]}
def set(value: BIR.Atom, number: U32) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimArraySet{}, [a(value), a(w(0)), a(w(number))], [u32()]}
def leaf(value: U32) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimArrayLeaf{}, [a(w(value))], [u32()]}
def get(value: BIR.Atom) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimArrayLeafValue{}, [a(value)], [u32()]}
def add(left: BIR.Atom, right: BIR.Atom) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimU32Add{}, [a(left), a(right)], Nil{}}
def payload() -> BIR.Block:
  BIR.Let{105, BIR.Construct{15, "ProbeTables", [BIR.Field{0, "counts", BIR.Affine{}, l(101)}, BIR.Field{1, "depths", BIR.Affine{}, l(102)}]}, BIR.Return{l(105)}}
def producer_end(mode: U32) -> BIR.Block:
  match mode:
    case 2:
      BIR.Let{103, BIR.PrimitiveCall{BIR.PrimArrayNew{}, [a(BIR.Natural{32n}), a(w(0))], [u32()]}, payload()}
    case _: payload()
def producer_body(mode: U32) -> BIR.Block:
  BIR.Let{100, set(l(0), 11), BIR.Let{101, set(l(100), 22), BIR.Let{102, set(l(1), 33), producer_end(mode)}}}
def producer(mode: U32) -> BIR.Code:
  match mode:
    case 5: BIR.Code{10, [BIR.Affine{}], [p(0), p(1)], producer_body(mode)}
    case 12: BIR.Code{10, Nil{}, [p(0), p(1)], BIR.Let{99, BIR.Copy{BIR.Symbol{0, "seed"}}, producer_body(mode)}}
    case _: BIR.Code{10, Nil{}, [p(0), p(1)], producer_body(mode)}
def retained_parameters(id: U32) -> List<&2, BIR.Parameter>:
  match id:
    case 13: Nil{}
    case _: p(id) <> retained_parameters(U32.inc(id))
def sum_retained(id: U32, value: U32) -> BIR.Block:
  match id:
    case 13: BIR.Return{l(value)}
    case _:
      BIR.Let{U32.add(220, id), add(l(value), l(id)), sum_retained(U32.inc(id), U32.add(220, id))}
def consumer_sum(mode: U32) -> BIR.Block:
  match mode:
    case 3:
      BIR.Let{212, BIR.Apply{l(0), a(w(0))},
        BIR.Let{213, add(l(204), l(212)), sum_retained(1, 213)}}
    case 8:
      BIR.Let{210, BIR.Project{l(13), 15, 0, "counts"},
        BIR.Let{211, get(l(210)), BIR.Let{212, add(l(204), l(211)), sum_retained(0, 212)}}}
    case 14: BIR.Region{290, sum_retained(0, 204), BIR.Failure{"unreachable"}}
    case _: sum_retained(0, 204)
def consumer_success(mode: U32) -> BIR.Block:
  BIR.Let{200, BIR.Project{l(13), 15, 0, "counts"},
    BIR.Let{201, BIR.Project{l(13), 15, 1, "depths"},
      BIR.Let{202, get(l(200)), BIR.Let{203, get(l(201)),
        BIR.Let{204, add(l(202), l(203)), consumer_sum(mode)}}}}}
def consumer_body(mode: U32) -> BIR.Block:
  match mode:
    case 4:
      BIR.Let{200, BIR.PrimitiveCall{BIR.PrimSameValue{}, [a(l(13)), a(l(13))], Nil{}}, BIR.Branch{l(200), BIR.Return{w(1)}, BIR.Return{w(0)}}}
    case _:
      BIR.Region{298, BIR.Let{299, BIR.HasTag{l(13), 15, "ProbeTables"}, BIR.Branch{l(299), consumer_success(mode), BIR.LeaveRegion{298}}}, BIR.Failure{"bad record"}}
def consumer(mode: U32) -> BIR.Code:
  BIR.Code{20, Nil{}, List.append(&2, BIR.Parameter, retained_parameters(0), [p(13)]), consumer_body(mode)}
def retained_values(mode: U32, id: U32) -> List<&2, BIR.Arg>:
  match id:
    case 13: Nil{}
    case _:
      match mode id:
        case 1 _: a(BIR.Capture{id}) <> retained_values(mode, U32.inc(id))
        case 3 0: a(BIR.Symbol{0, "seed"}) <> retained_values(mode, U32.inc(id))
        case _ _: a(w(U32.inc(id))) <> retained_values(mode, U32.inc(id))
def captures(id: U32) -> List<&2, BIR.Use>:
  match id:
    case 13: Nil{}
    case _: BIR.Affine{} <> captures(U32.inc(id))
def producer_args(mode: U32) -> List<&2, BIR.Arg>:
  match mode:
    case 5: [a(w(9)), a(l(300)), a(l(301))]
    case _: [a(l(300)), a(l(301))]
def owner_body(mode: U32, binding: U32) -> BIR.Block:
  BIR.Let{300, leaf(0), BIR.Let{301, leaf(0),
    BIR.Let{binding, BIR.Direct{10, producer_args(mode)}, BIR.TailDirect{20, List.append(&2, BIR.Arg, retained_values(mode, 0), [a(l(binding))])}}}}
def owner(mode: U32, code: U32, binding: U32) -> BIR.Code:
  match mode:
    case 1: BIR.Code{code, captures(0), Nil{}, owner_body(mode, binding)}
    case _: BIR.Code{code, Nil{}, Nil{}, owner_body(mode, binding)}
def main_body(mode: U32) -> BIR.Block:
  match mode:
    case 1: BIR.TailDirect{30, retained_values(0, 0)}
    case 10:
      BIR.Let{500, BIR.Direct{30, Nil{}},
        BIR.Let{501, leaf(0), BIR.Let{502, leaf(0),
          BIR.Let{503, BIR.Direct{10, [a(l(501)), a(l(502))]},
            BIR.Let{504, BIR.Copy{w(0)},
              BIR.Let{505, BIR.Direct{20, List.append(&2, BIR.Arg, retained_values(0, 0), [a(l(503))])},
                BIR.Let{506, add(l(500), l(505)), BIR.Return{l(506)}}}}}}}}
    case 11:
      BIR.Let{500, BIR.Direct{30, Nil{}}, BIR.Let{501, BIR.Direct{31, Nil{}}, BIR.Let{502, add(l(500), l(501)), BIR.Return{l(502)}}}}
    case _: BIR.TailDirect{30, Nil{}}
def extra_codes(mode: U32) -> List<&2, BIR.Code>:
  match mode:
    case 11: [owner(mode, 31, 401)]
    case _: Nil{}
def extra_declarations(mode: U32) -> List<&2, BIR.Declaration>:
  match mode:
    case 6: [BIR.LazyDeclaration{"high", BIR.Let{9000000, BIR.Copy{w(0)}, BIR.Return{w(0)}}}]
    case 7: [BIR.LazyDeclaration{"high", BIR.Let{4294966783, BIR.Copy{w(0)}, BIR.Return{w(0)}}}]
    case 10: [BIR.FunctionDeclaration{"producer_public", 10, [p(0), p(1)]}, BIR.FunctionDeclaration{"consumer_public", 20, List.append(&2, BIR.Parameter, retained_parameters(0), [p(13)])}]
    case _: Nil{}
def tables_family() -> BIR.Family:
  BIR.Family{"ProbeTables", "ProbeTables", None{}, 0n, 0n, [BIR.DescriptorArm{"ProbeTables", [BIR.DescriptorField{Some{"counts"}, BIR.Once{}, array()}, BIR.DescriptorField{Some{"depths"}, BIR.Once{}, array()}]}]}
def bool_family() -> BIR.Family:
  BIR.Family{"Bool", "Bool", None{}, 0n, 0n, [BIR.DescriptorArm{"False", Nil{}}, BIR.DescriptorArm{"True", Nil{}}]}
def program(mode: U32) -> BIR.Program:
  BIR.Program{
    List.append(&2, BIR.Code, [producer(mode), consumer(mode), owner(mode, 30, 400), BIR.Code{40, Nil{}, [p(600)], BIR.Return{w(7)}}], extra_codes(mode)),
    List.append(&2, BIR.Declaration, [BIR.LazyDeclaration{"main", main_body(mode)}, BIR.FunctionDeclaration{"seed", 40, [p(600)]}], extra_declarations(mode)),
    List.append(&2, BIR.ConstructorLayout, Fixture.runtime_ctors(), [BIR.ConstructorLayout{15, "ProbeTables", None{}, [Some{"counts"}, Some{"depths"}]}, BIR.ConstructorLayout{16, "False", None{}, Nil{}}, BIR.ConstructorLayout{17, "True", None{}, Nil{}}]),
    List.append(&2, BIR.Family, Fixture.runtime_families(), [tables_family(), bool_family(), BIR.Family{"Array", "Array", Some{"Array"}, 0n, 1n, Nil{}}]),
    Nil{}, BIR.Executable{u32()}}
def render(program: BIR.Program, target: Bool) -> String:
  match target:
    case True{}:
      match JS.emit_linked(program, Nil{}):
        case JS.EmitSuccess{source}: source
        case JS.EmitFailure{message, _}: String.append("ERROR: ", message)
    case False{}:
      match C.emit(program, Runtime.runtime_source(), Nil{}):
        case C.EmitSuccess{source}: source
        case C.EmitFailure{message}: String.append("ERROR: ", message)
def render_case(program: BIR.Program, target: Bool, files: List<&2, BIR.SourceFile>) -> ProbeSource:
  match target:
    case True{}:
      match JS.emit_linked(program, files):
        case JS.EmitSuccess{source}: ProbeSource{False{}, True{}, source}
        case JS.EmitFailure{message, _}: ProbeSource{False{}, True{}, String.append("ERROR: ", message)}
    case False{}:
      match CRender.render(program, Runtime.runtime_source(), files):
        case CRender.EmitSuccess{source}: ProbeSource{False{}, False{}, source}
        case CRender.EmitFailure{message, _}: ProbeSource{False{}, False{}, String.append("ERROR: ", message)}
def sources(+program: BIR.Program, +optimized: Bool) -> List<&2, ProbeSource>:
  [ProbeSource{optimized, False{}, render(program, False{})}, ProbeSource{optimized, True{}, render(program, True{})}]
def probe(mode: U32) -> ProbeCase:
  probe_inspection(mode, inspect(program(mode)))
def probe_inspection(mode: U32, +inspection: Inspection) -> ProbeCase:
  match inspection:
    case Inspection{original, optimized, _, _}:
      ProbeCase{mode, inspection, List.append(&2, ProbeSource, sources(original, False{}), sources(optimized, True{}))}
def cases(modes: List<&2, U32>) -> List<&2, ProbeCase>:
  match modes:
    case Nil{}: Nil{}
    case mode <> rest: probe(mode) <> cases(rest)
def main(modules: List<&2, Loader.LoadedModule>) -> ProbeBatch:
  ProbeBatch{schema(), cases([0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 14])}
