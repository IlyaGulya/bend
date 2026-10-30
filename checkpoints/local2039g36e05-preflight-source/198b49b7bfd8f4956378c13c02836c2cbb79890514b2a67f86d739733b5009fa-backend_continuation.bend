import Base
import ./backend_ir.bend as BIR
import ./index_lookup.bend as Index

# Existing-BIR, single-return producer/known-consumer specialization. This pass
# never changes public entries, runtime representations, or the call ABI.
# All admission is transactional. Bounds and refusal reasons are inspectable
# through plan; optimize is the sole production entry at lower_complete.
type Shape is Data:
  Shape{constructor: U32, tag: String, fields: List<&2, BIR.Field>}
type Site is Data:
  Site{owner: U32, binding: U32, producer: U32, inputs: List<&2, BIR.Arg>, consumer: U32, outputs: List<&2, BIR.Arg>}
type Scan is Data:
  Scan{high: U32, fuel: U32, site_room: U32, codes: Map<&2, BIR.Code>, sites: List<&2, Site>, refs: Map<&2, U32>}
type Binding is Data:
  Binding{old: U32, value: BIR.Atom}
type Bound is Data:
  Bound{parameters: List<&2, BIR.Parameter>, arguments: List<&2, BIR.Arg>, env: List<&2, Binding>, next: U32}
type Fields is Data:
  Fields{parameters: List<&2, BIR.Parameter>, fields: List<&2, BIR.Field>, next: U32}
type Selected is Data:
  Selected{record: U32, parameters: List<&2, BIR.Parameter>, arguments: List<&2, BIR.Arg>}
type Cloned is Data:
  Cloned{body: BIR.Block, next: U32}
type Consumer is Data:
  Consumer{code: U32, fields: List<&2, BIR.Field>}
type Proof is Data:
  Proof{owner: U32, binding: U32, producer: U32, consumer: U32, record: U32, constructor: U32, continuation: U32, worker: U32}
type Refusal is Data:
  Refusal{owner: U32, binding: U32, reason: String}
type State is Data:
  State{next: U32, room: U32, consumers: Map<&2, Consumer>, pairs: Map<&2, U32>, workers: List<&2, BIR.Code>, replacements: Map<&2, BIR.Block>, proofs: List<&2, Proof>, refusals: List<&2, Refusal>, refs: Map<&2, U32>, dead: Map<&2, Bool>, owners: Map<&2, Bool>, detail: Bool}
type Plan is Data:
  Plan{program: BIR.Program, proofs: List<&2, Proof>, refusals: List<&2, Refusal>}
type Prepared is Data:
  Prepared{producer: BIR.Code, shape: Shape, consumer: BIR.Code, selected: Selected, body: BIR.Block}
type Admission is Data:
  Admit{prepared: Prepared}
  Refuse{reason: String}

# These keys encode numeric labels, not source names. Capture slots are never
# confused with Local IDs. No caller atom is rewritten with a callee frame.
def key(id: U32) -> String:
  U32.show(id)
def pair_key(a: U32, b: U32) -> String:
  String.append(key(a), String.append("/", key(b)))
def shape_key(consumer: U32, record: U32, constructor: U32) -> String:
  String.append(pair_key(consumer, record), String.append("/", key(constructor)))
def worker_key(producer: U32, consumer: U32, record: U32) -> String:
  String.append(pair_key(producer, consumer), String.append("/", key(record)))
def same_use(a: BIR.Use, b: BIR.Use) -> Bool:
  match a b:
    case BIR.Affine{} BIR.Affine{}: True{}
    case BIR.Many{} BIR.Many{}: True{}
    case _ _: False{}
def affine(use: BIR.Use) -> Bool:
  match use:
    case BIR.Affine{}: True{}
    case _: False{}
def local_is(atom: BIR.Atom, id: U32) -> Bool:
  match atom:
    case BIR.Local{other}: U32.is_eq(other, id)
    case _: False{}
def stable(atom: BIR.Atom) -> Bool:
  match atom:
    case BIR.Symbol{_, _}: False{}
    case BIR.FloatBits{_}: False{}
    case _: True{}
def same_owner(a: BIR.Atom, b: BIR.Atom) -> Bool:
  match a b:
    case BIR.Local{x} BIR.Local{y}: U32.is_eq(x, y)
    case BIR.Capture{x} BIR.Capture{y}: U32.is_eq(x, y)
    case _ _: False{}
def env_find(env: List<&2, Binding>, id: U32) -> Maybe<&2, BIR.Atom>:
  match env:
    case Nil{}: None{}
    case Binding{old, value} <> rest:
      match U32.is_eq(old, id):
        case True{}: Some{value}
        case False{}: env_find(rest, id)
def rename(atom: BIR.Atom, env: List<&2, Binding>) -> Maybe<&2, BIR.Atom>:
  match atom:
    case BIR.Local{id}: env_find(env, id)
    case BIR.Capture{_}: None{}
    case BIR.Symbol{_, _}: None{}
    case BIR.FloatBits{_}: None{}
    case _: Some{atom}
def rename_args(args: List<&2, BIR.Arg>, +env: List<&2, Binding>) -> Maybe<&2, List<&2, BIR.Arg>>:
  match args:
    case Nil{}: Some{Nil{}}
    case BIR.Arg{use, value} <> rest:
      match rename(value, env) rename_args(rest, env):
        case Some{atom} Some{tail}: Some{BIR.Arg{use, atom} <> tail}
        case _ _: None{}
def rename_fields(fields: List<&2, BIR.Field>, +env: List<&2, Binding>) -> Maybe<&2, List<&2, BIR.Field>>:
  match fields:
    case Nil{}: Some{Nil{}}
    case BIR.Field{id, name, use, value} <> rest:
      match rename(value, env) rename_fields(rest, env):
        case Some{atom} Some{tail}: Some{BIR.Field{id, name, use, atom} <> tail}
        case _ _: None{}
def bind(parameters: List<&2, BIR.Parameter>, next: U32, env: List<&2, Binding>) -> Bound:
  match parameters:
    case Nil{}: Bound{Nil{}, Nil{}, env, next}
    case BIR.Parameter{old, use} <> rest:
      bind_more(bind(rest, U32.inc(next), Binding{old, BIR.Local{next}} <> env), next, use)
def bind_more(bound: Bound, +id: U32, +use: BIR.Use) -> Bound:
  match bound:
    case Bound{parameters, arguments, env, next}:
      Bound{BIR.Parameter{id, use} <> parameters, BIR.Arg{use, BIR.Local{id}} <> arguments, env, next}
def bind_fields(fields: List<&2, BIR.Field>, next: U32) -> Fields:
  match fields:
    case Nil{}: Fields{Nil{}, Nil{}, next}
    case BIR.Field{id, name, use, _} <> rest:
      bind_field_more(bind_fields(rest, U32.inc(next)), id, name, use, next)
def bind_field_more(result: Fields, id: U32, name: String, +use: BIR.Use, +fresh: U32) -> Fields:
  match result:
    case Fields{parameters, fields, next}:
      Fields{BIR.Parameter{fresh, use} <> parameters, BIR.Field{id, name, use, BIR.Local{fresh}} <> fields, next}
def field_args(fields: List<&2, BIR.Field>) -> List<&2, BIR.Arg>:
  match fields:
    case Nil{}: Nil{}
    case BIR.Field{_, _, use, value} <> rest: BIR.Arg{use, value} <> field_args(rest)

# One bounded inventory visits every executable identity, including lazy
# declarations and unreachable Region fallbacks. Let IDs also name JS $k
# continuations. Saturation/overflow refuses the whole pass before cloning.
def scan_id(scan: Scan, id: U32) -> Scan:
  match scan:
    case Scan{high, fuel, room, codes, sites, refs}: Scan{U32.max(high, id), fuel, room, codes, sites, refs}
def tick(scan: Scan) -> Scan:
  match scan:
    case Scan{_, 0, _, _, _, _}: scan
    case Scan{high, fuel, room, codes, sites, refs}: Scan{high, U32.sub(fuel, 1), room, codes, sites, refs}
def scan_count_id(scan: Scan, id: U32) -> Scan:
  match scan:
    case Scan{_, 0, _, _, _, _}: scan
    case Scan{high, fuel, room, codes, sites, refs}: Scan{U32.max(high, id), U32.sub(fuel, 1), room, codes, sites, refs}
def ref_count(refs: Map<&2, U32>, id: U32) -> U32:
  match Index.find(U32, refs, key(id)):
    case Some{count}: count
    case None{}: 0
def scan_ref(scan: Scan, +id: U32) -> Scan:
  match scan:
    case Scan{high, fuel, room, codes, sites, +refs}:
      Scan{U32.max(high, id), fuel, room, codes, sites, Map.set(&2, U32, refs, key(id), U32.inc(ref_count(refs, id)))}
def scan_atom(atom: BIR.Atom, scan: Scan) -> Scan:
  match atom:
    case BIR.Local{id}: scan_count_id(scan, id)
    case BIR.Capture{slot}: scan_count_id(scan, slot)
    case BIR.Symbol{id, _}: scan_count_id(scan, id)
    case _: tick(scan)
def scan_args(args: List<&2, BIR.Arg>, scan: Scan) -> Scan:
  match scan args:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ BIR.Arg{_, value} <> rest: scan_args(rest, scan_atom(value, scan))
def scan_fields(fields: List<&2, BIR.Field>, scan: Scan) -> Scan:
  match scan fields:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ BIR.Field{id, _, _, value} <> rest: scan_fields(rest, scan_atom(value, scan_id(scan, id)))
def scan_parameters(parameters: List<&2, BIR.Parameter>, scan: Scan) -> Scan:
  match scan parameters:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ BIR.Parameter{id, _} <> rest: scan_parameters(rest, scan_count_id(scan, id))
def scan_op(op: BIR.Op, scan: Scan) -> Scan:
  match op:
    case BIR.Copy{value}: scan_atom(value, scan)
    case BIR.PrimitiveCall{_, args, _}: scan_args(args, scan)
    case BIR.Closure{code, captures, parameters}: scan_parameters(parameters, scan_args(captures, scan_ref(scan, code)))
    case BIR.Direct{code, args}: scan_args(args, scan_ref(scan, code))
    case BIR.Apply{fn, BIR.Arg{_, value}}: scan_atom(value, scan_atom(fn, scan))
    case BIR.LoadSymbol{id, _}: scan_id(scan, id)
    case BIR.Construct{constructor, _, fields}: scan_fields(fields, scan_id(scan, constructor))
    case BIR.Project{value, constructor, field, _}: scan_atom(value, scan_id(scan_id(scan, constructor), field))
    case BIR.HasTag{value, constructor, _}: scan_atom(value, scan_id(scan, constructor))
def collect(owner: Maybe<&2, U32>, body: BIR.Block, scan: Scan) -> Scan:
  match owner body scan:
    case Some{owner_id} BIR.Let{id, BIR.Direct{producer, inputs}, BIR.TailDirect{consumer, outputs}} Scan{high, fuel, room, codes, sites, refs}:
      match room:
        case 0: scan
        case _: Scan{high, fuel, U32.sub(room, 1), codes, Site{owner_id, id, producer, inputs, consumer, outputs} <> sites, refs}
    case _ _ _: scan
def scan_blocks(todo: List<&2, BIR.Block>, +owner: Maybe<&2, U32>, scan: Scan) -> Scan:
  match scan todo:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ body <> rest: scan_block(body, rest, owner, tick(collect(owner, body, scan)))
def scan_block(body: BIR.Block, rest: List<&2, BIR.Block>, +owner: Maybe<&2, U32>, scan: Scan) -> Scan:
  match body:
    case BIR.Return{value}: scan_blocks(rest, owner, scan_atom(value, scan))
    case BIR.Let{id, op, next}: scan_blocks(next <> rest, owner, scan_op(op, scan_id(scan, id)))
    case BIR.Branch{condition, yes, no}: scan_blocks(yes <> no <> rest, owner, scan_atom(condition, scan))
    case BIR.Region{label, body, next}: scan_blocks(body <> next <> rest, owner, scan_id(scan, label))
    case BIR.LeaveRegion{label}: scan_blocks(rest, owner, scan_id(scan, label))
    case BIR.TailDirect{code, args}: scan_blocks(rest, owner, scan_args(args, scan_ref(scan, code)))
    case BIR.TailApply{fn, BIR.Arg{_, value}}: scan_blocks(rest, owner, scan_atom(value, scan_atom(fn, scan)))
    case BIR.Failure{_}: scan_blocks(rest, owner, scan)
def scan_codes(items: List<&2, BIR.Code>, scan: Scan) -> Scan:
  match scan items:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ item <> rest: scan_code(item, rest, scan)
def scan_code(+item: BIR.Code, rest: List<&2, BIR.Code>, scan: Scan) -> Scan:
  match item scan:
    case BIR.Code{id, _, parameters, body} Scan{high, fuel, room, +codes, sites, refs}:
      match Index.find(BIR.Code, codes, key(id)):
        case Some{_}: Scan{high, 0, room, codes, sites, refs}
        case None{}:
          scan_codes(rest, scan_blocks(body <> Nil{}, Some{id}, scan_parameters(parameters, scan_id(tick(Scan{high, fuel, room, Map.set(&2, BIR.Code, codes, key(id), item), sites, refs}), id))))
def scan_declarations(items: List<&2, BIR.Declaration>, scan: Scan) -> Scan:
  match scan items:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ declaration <> rest: scan_declaration(declaration, rest, tick(scan))
def scan_declaration(declaration: BIR.Declaration, rest: List<&2, BIR.Declaration>, scan: Scan) -> Scan:
  match declaration:
    case BIR.FunctionDeclaration{_, code, parameters}: scan_declarations(rest, scan_parameters(parameters, scan_ref(scan, code)))
    case BIR.LazyDeclaration{_, body}: scan_declarations(rest, scan_blocks(body <> Nil{}, None{}, scan))
    case _: scan_declarations(rest, scan)
def scan_layouts(items: List<&2, BIR.ConstructorLayout>, scan: Scan) -> Scan:
  match scan items:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ BIR.ConstructorLayout{id, _, _, _} <> rest: scan_layouts(rest, scan_id(tick(scan), id))
def scan_exports(items: List<&2, BIR.Export>, scan: Scan) -> Scan:
  match scan items:
    case Scan{_, 0, _, _, _, _} _: scan
    case _ Nil{}: scan
    case _ BIR.Export{_, Some{BIR.Entry{code, _}}, _, _} <> rest: scan_exports(rest, scan_ref(tick(scan), code))
    case _ _ <> rest: scan_exports(rest, tick(scan))
def scan_ending(ending: BIR.Ending, scan: Scan) -> Scan:
  match ending:
    case BIR.Library{exports}: scan_exports(exports, scan)
    case _: scan
def inventory(program: BIR.Program) -> Scan:
  match program:
    case BIR.Program{codes, declarations, layouts, _, _, ending}:
      scan_ending(ending, scan_layouts(layouts, scan_declarations(declarations, scan_codes(codes, Scan{0, 4000000, 8192, Map.new(&2, BIR.Code), Nil{}, Map.new(&2, U32)}))))

# Admission has no mutation. The input is fully checked BIR; these additional
# checks establish exactly the facts lost by moving a record across a call.
# Per code: <=32 parameters, <=32 producer lets, <=64 consumer lets; <=8
# returned fields. No user calls, closures, dynamic application, or recursive
# edges occur in a cloned body.
def parameters_within(items: List<&2, BIR.Parameter>, room: U32) -> Bool:
  match items room:
    case Nil{} _: True{}
    case _ 0: False{}
    case _ <> rest _: parameters_within(rest, U32.sub(room, 1))
def args_within(items: List<&2, BIR.Arg>, room: U32) -> Bool:
  match items room:
    case Nil{} _: True{}
    case _ 0: False{}
    case _ <> rest _: args_within(rest, U32.sub(room, 1))
def fields_within(items: List<&2, BIR.Field>, room: U32) -> Bool:
  match items room:
    case Nil{} _: True{}
    case _ 0: False{}
    case _ <> rest _: fields_within(rest, U32.sub(room, 1))
def signature(parameters: List<&2, BIR.Parameter>, args: List<&2, BIR.Arg>) -> Bool:
  match parameters args:
    case Nil{} Nil{}: True{}
    case BIR.Parameter{_, expected} <> ps BIR.Arg{actual, _} <> xs:
      Bool.and(same_use(expected, actual), signature(ps, xs))
    case _ _: False{}
def args_avoid(args: List<&2, BIR.Arg>, +id: U32) -> Bool:
  match args:
    case Nil{}: True{}
    case BIR.Arg{_, value} <> rest: Bool.and(Bool.not(local_is(value, id)), args_avoid(rest, id))
def no_alias(value: BIR.Atom, use: BIR.Use, rest: List<&2, BIR.Arg>) -> Bool:
  match rest:
    case Nil{}: True{}
    case BIR.Arg{other_use, other} <> tail:
      match Bool.and(same_owner(value, other), Bool.or(affine(use), affine(other_use))):
        case True{}: False{}
        case False{}: no_alias(value, use, tail)
def affine_args(args: List<&2, BIR.Arg>) -> Bool:
  match args:
    case Nil{}: True{}
    case BIR.Arg{use, value} <> rest: Bool.and(no_alias(value, use, rest), affine_args(rest))
def field_distinct(id: U32, name: String, fields: List<&2, BIR.Field>) -> Bool:
  match fields:
    case Nil{}: True{}
    case BIR.Field{other_id, other_name, _, _} <> rest:
      Bool.and(Bool.not(Bool.or(U32.is_eq(id, other_id), String.eq(name, other_name))), field_distinct(id, name, rest))
def fields_ok(fields: List<&2, BIR.Field>) -> Bool:
  match fields:
    case Nil{}: True{}
    case BIR.Field{id, name, _, value} <> rest:
      Bool.and(stable(value), Bool.and(field_distinct(id, name, rest), fields_ok(rest)))
def producer_shape(body: BIR.Block, room: U32) -> Maybe<&2, Shape>:
  match room body:
    case 0 _: None{}
    case _ BIR.Let{id, BIR.Construct{constructor, tag, fields}, BIR.Return{BIR.Local{returned}}}:
      match Bool.and(U32.is_eq(id, returned), fields_within(fields, 8)):
        case False{}: None{}
        case True{}:
          match fields:
            case Nil{}: None{}
            case _:
              match Bool.and(fields_ok(fields), affine_args(field_args(fields))):
                case True{}: Some{Shape{constructor, tag, fields}}
                case False{}: None{}
    case _ BIR.Let{_, BIR.Copy{_}, next}: producer_shape(next, U32.sub(room, 1))
    case _ BIR.Let{_, BIR.PrimitiveCall{_, args, _}, next}:
      match args_within(args, 32):
        case True{}: producer_shape(next, U32.sub(room, 1))
        case False{}: None{}
    case _ _: None{}

type Retained is Data:
  Retained{parameters: List<&2, BIR.Parameter>, arguments: List<&2, BIR.Arg>}
def retain(parameters: List<&2, BIR.Parameter>, args: List<&2, BIR.Arg>, +binding: U32) -> Maybe<&2, Retained>:
  match parameters args:
    case Nil{} Nil{}: Some{Retained{Nil{}, Nil{}}}
    case BIR.Parameter{id, use} <> ps BIR.Arg{actual, value} <> xs:
      match Bool.and(same_use(use, actual), Bool.and(stable(value), Bool.not(local_is(value, binding)))):
        case False{}: None{}
        case True{}:
          match retain(ps, xs, binding):
            case Some{Retained{tail_ps, tail_xs}}: Some{Retained{BIR.Parameter{id, use} <> tail_ps, BIR.Arg{actual, value} <> tail_xs}}
            case None{}: None{}
    case _ _: None{}
def select(parameters: List<&2, BIR.Parameter>, args: List<&2, BIR.Arg>, +binding: U32) -> Maybe<&2, Selected>:
  match parameters args:
    case BIR.Parameter{id, use} <> ps BIR.Arg{actual, value} <> xs:
      match local_is(value, binding):
        case True{}:
          match Bool.and(affine(use), same_use(use, actual)) retain(ps, xs, binding):
            case True{} Some{Retained{tail_ps, tail_xs}}: Some{Selected{id, tail_ps, tail_xs}}
            case _ _: None{}
        case False{}:
          match Bool.and(same_use(use, actual), stable(value)):
            case False{}: None{}
            case True{}:
              match select(ps, xs, binding):
                case Some{Selected{record, tail_ps, tail_xs}}: Some{Selected{record, BIR.Parameter{id, use} <> tail_ps, BIR.Arg{actual, value} <> tail_xs}}
                case None{}: None{}
    case _ _: None{}

# A source pattern match lowers to this guarded lexical Region. The constructor
# identity AND spelling and guard/result IDs must agree. Its successful body
# is admitted separately and cannot leave a region, so the failure arm and
# fallback are provably unreachable, not silently discarded reachable control.
def consumer_body(body: BIR.Block, record: U32, shape: Shape) -> Maybe<&2, BIR.Block>:
  match body shape:
    case BIR.Region{label, BIR.Let{test, BIR.HasTag{BIR.Local{value}, actual, name}, BIR.Branch{BIR.Local{condition}, yes, BIR.LeaveRegion{exit}}}, BIR.Failure{_}} Shape{expected, tag, _}:
      match Bool.and(U32.is_eq(label, exit), Bool.and(U32.is_eq(test, condition), Bool.and(U32.is_eq(value, record), Bool.and(U32.is_eq(actual, expected), String.eq(name, tag))))):
        case True{}: Some{yes}
        case False{}: None{}
    case BIR.Region{_, _, _} _: None{}
    case _ _: Some{body}

def prepare(site: Site, +codes: Map<&2, BIR.Code>) -> Admission:
  match site:
    case Site{_, binding, producer, inputs, consumer, outputs}:
      match Index.find(BIR.Code, codes, key(producer)) Index.find(BIR.Code, codes, key(consumer)):
        case Some{p} Some{k}: prepare_codes(p, k, binding, inputs, outputs)
        case _ _: Refuse{"missing-code"}
def prepare_codes(+p: BIR.Code, +k: BIR.Code, binding: U32, +inputs: List<&2, BIR.Arg>, outputs: List<&2, BIR.Arg>) -> Admission:
  match p k:
    case BIR.Code{_, Nil{}, ps, producer_body} BIR.Code{_, Nil{}, ks, body}:
      match Bool.and(parameters_within(ps, 32), Bool.and(parameters_within(ks, 32), Bool.and(args_within(inputs, 32), args_within(outputs, 32)))):
        case False{}: Refuse{"arity-budget"}
        case True{}:
          match Bool.and(signature(ps, inputs), args_avoid(inputs, binding)):
            case False{}: Refuse{"producer-signature"}
            case True{}: prepare_shape(producer_shape(producer_body, 32), select(ks, outputs, binding), p, k, body, inputs)
    case _ _: Refuse{"captured-callee"}
def prepare_shape(shape: Maybe<&2, Shape>, selected: Maybe<&2, Selected>, p: BIR.Code, k: BIR.Code, body: BIR.Block, inputs: List<&2, BIR.Arg>) -> Admission:
  match shape selected:
    case Some{shape} Some{Selected{record, parameters, arguments}}:
      match affine_args(List.append(&2, BIR.Arg, inputs, arguments)):
        case False{}: Refuse{"duplicate-affine-argument"}
        case True{}:
          match consumer_body(body, record, shape):
            case None{}: Refuse{"reachable-region"}
            case Some{selected_body}: Admit{Prepared{p, shape, k, Selected{record, parameters, arguments}, selected_body}}
    case None{} _: Refuse{"producer-shape"}
    case _ None{}: Refuse{"consumer-arguments"}

# These are the only ordinary operations a clone may contain. Calls, closure
# creation, LoadSymbol, foreign/dynamic control and every Region are rejected.
# Symbol/FloatBits evaluation inside a cloned body is conservatively refused.
def clone_op(op: BIR.Op, +env: List<&2, Binding>) -> Maybe<&2, BIR.Op>:
  match op:
    case BIR.Copy{value}:
      match rename(value, env):
        case Some{atom}: Some{BIR.Copy{atom}}
        case None{}: None{}
    case BIR.PrimitiveCall{primitive, args, types}:
      match args_within(args, 32):
        case False{}: None{}
        case True{}:
          match rename_args(args, env):
            case Some{values}: Some{BIR.PrimitiveCall{primitive, values, types}}
            case None{}: None{}
    case BIR.Construct{constructor, tag, fields}:
      match fields_within(fields, 32):
        case False{}: None{}
        case True{}:
          match rename_fields(fields, env):
            case Some{values}: Some{BIR.Construct{constructor, tag, values}}
            case None{}: None{}
    case BIR.Project{value, constructor, field, name}:
      match rename(value, env):
        case Some{atom}: Some{BIR.Project{atom, constructor, field, name}}
        case None{}: None{}
    case BIR.HasTag{value, constructor, tag}:
      match rename(value, env):
        case Some{atom}: Some{BIR.HasTag{atom, constructor, tag}}
        case None{}: None{}
    case _: None{}

type Projection is Data:
  Projection{value: BIR.Atom, remaining: List<&2, BIR.Field>}
type Edited is Data:
  Edited{op: BIR.Op, remaining: List<&2, BIR.Field>}
def project(fields: List<&2, BIR.Field>, id: U32, name: String) -> Maybe<&2, Projection>:
  match fields:
    case Nil{}: None{}
    case BIR.Field{known, key, use, value} <> rest:
      match Bool.and(U32.is_eq(known, id), String.eq(key, name)):
        case True{}:
          match use:
            case BIR.Affine{}: Some{Projection{value, rest}}
            case BIR.Many{}: Some{Projection{value, fields}}
        case False{}:
          match project(rest, id, name):
            case Some{Projection{atom, remaining}}: Some{Projection{atom, BIR.Field{known, key, use, value} <> remaining}}
            case None{}: None{}
def edit_op(op: BIR.Op, record: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, env: List<&2, Binding>) -> Maybe<&2, Edited>:
  match op:
    case BIR.Project{BIR.Local{id}, actual, field, name}:
      match U32.is_eq(id, record):
        case False{}: edit_ordinary(clone_op(op, env), fields)
        case True{}:
          match U32.is_eq(actual, constructor):
            case False{}: None{}
            case True{}:
              match project(fields, field, name):
                case Some{Projection{value, remaining}}: Some{Edited{BIR.Copy{value}, remaining}}
                case None{}: None{}
    case BIR.HasTag{BIR.Local{id}, actual, name}:
      match U32.is_eq(id, record):
        case False{}: edit_ordinary(clone_op(op, env), fields)
        case True{}:
          match Bool.and(U32.is_eq(actual, constructor), String.eq(name, tag)):
            case True{}: Some{Edited{BIR.Copy{BIR.Boolean{True{}}}, fields}}
            case False{}: None{}
    case _: edit_ordinary(clone_op(op, env), fields)
def edit_ordinary(op: Maybe<&2, BIR.Op>, fields: List<&2, BIR.Field>) -> Maybe<&2, Edited>:
  match op:
    case Some{value}: Some{Edited{value, fields}}
    case None{}: None{}
def clone_consumer(body: BIR.Block, record: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, env: List<&2, Binding>, next: U32, room: U32) -> Maybe<&2, Cloned>:
  match room body:
    case 0 _: None{}
    case _ BIR.Return{value}:
      match rename(value, env):
        case Some{atom}: Some{Cloned{BIR.Return{atom}, next}}
        case None{}: None{}
    case _ BIR.Let{id, op, tail}:
      match U32.is_eq(id, record) env_find(env, id):
        case True{} _: None{}
        case _ Some{_}: None{}
        case False{} None{}:
          match edit_op(op, record, constructor, tag, fields, env):
            case None{}: None{}
            case Some{Edited{fresh_op, remaining}}:
              prepend_clone(clone_consumer(tail, record, constructor, tag, remaining, Binding{id, BIR.Local{next}} <> env, U32.inc(next), U32.sub(room, 1)), next, fresh_op)
    case _ _: None{}
def prepend_clone(result: Maybe<&2, Cloned>, id: U32, op: BIR.Op) -> Maybe<&2, Cloned>:
  match result:
    case Some{Cloned{body, next}}: Some{Cloned{BIR.Let{id, op, body}, next}}
    case None{}: None{}

# Only the terminal record construction is removed. Every original strict let
# is copied once, in order, then fields and retained evaluated operands enter K.
def clone_producer(body: BIR.Block, env: List<&2, Binding>, next: U32, continuation: U32, retained: List<&2, BIR.Arg>, room: U32) -> Maybe<&2, Cloned>:
  match room body:
    case 0 _: None{}
    case _ BIR.Let{id, BIR.Construct{_, _, fields}, BIR.Return{BIR.Local{returned}}}:
      match U32.is_eq(id, returned) rename_fields(fields, env):
        case True{} Some{values}: Some{Cloned{BIR.TailDirect{continuation, List.append(&2, BIR.Arg, field_args(values), retained)}, next}}
        case _ _: None{}
    case _ BIR.Let{id, op, tail}:
      match env_find(env, id) clone_op(op, env):
        case None{} Some{fresh_op}:
          prepend_clone(clone_producer(tail, Binding{id, BIR.Local{next}} <> env, U32.inc(next), continuation, retained, U32.sub(room, 1)), next, fresh_op)
        case _ _: None{}
    case _ _: None{}

type BuiltK is Data:
  BuiltK{consumer: Consumer, added: List<&2, BIR.Code>, next: U32}
type BuiltPair is Data:
  BuiltPair{worker: U32, consumer: Consumer, added: List<&2, BIR.Code>, next: U32}
def compatible(a: List<&2, BIR.Field>, b: List<&2, BIR.Field>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case BIR.Field{ai, ak, au, _} <> ar BIR.Field{bi, bk, bu, _} <> br:
      Bool.and(U32.is_eq(ai, bi), Bool.and(String.eq(ak, bk), Bool.and(same_use(au, bu), compatible(ar, br))))
    case _ _: False{}
def continuation(prepared: Prepared, cached: Maybe<&2, Consumer>, next: U32) -> Maybe<&2, BuiltK>:
  match prepared:
    case Prepared{_, Shape{constructor, tag, fields}, _, Selected{record, parameters, _}, body}:
      match cached:
        case Some{Consumer{code, cached_fields}}:
          match compatible(fields, cached_fields):
            case True{}: Some{BuiltK{Consumer{code, cached_fields}, Nil{}, next}}
            case False{}: None{}
        case None{}: continuation_bound(bind(parameters, U32.inc(next), Nil{}), fields, body, record, constructor, tag, next)
def continuation_bound(bound: Bound, fields: List<&2, BIR.Field>, body: BIR.Block, record: U32, constructor: U32, tag: String, code: U32) -> Maybe<&2, BuiltK>:
  match bound:
    case Bound{parameters, _, env, next}:
      continuation_fields(bind_fields(fields, next), parameters, env, body, record, constructor, tag, code)
def continuation_fields(fields: Fields, parameters: List<&2, BIR.Parameter>, env: List<&2, Binding>, body: BIR.Block, record: U32, constructor: U32, tag: String, code: U32) -> Maybe<&2, BuiltK>:
  match fields:
    case Fields{field_parameters, values, next}:
      match clone_consumer(body, record, constructor, tag, values, env, next, 64):
        case None{}: None{}
        case Some{Cloned{cloned, fresh}}:
          Some{BuiltK{Consumer{code, values}, BIR.Code{code, Nil{}, List.append(&2, BIR.Parameter, field_parameters, parameters), cloned} <> Nil{}, fresh}}
def producer_worker(prepared: Prepared, built: BuiltK) -> Maybe<&2, BuiltPair>:
  match prepared built:
    case Prepared{BIR.Code{_, _, parameters, body}, _, _, Selected{_, retained, _}, _} BuiltK{consumer, added, next}:
      producer_bound(bind(parameters, U32.inc(next), Nil{}), retained, body, consumer, added, next)
def producer_bound(bound: Bound, retained: List<&2, BIR.Parameter>, body: BIR.Block, consumer: Consumer, added: List<&2, BIR.Code>, code: U32) -> Maybe<&2, BuiltPair>:
  match bound:
    case Bound{parameters, _, env, next}:
      # Separate environments are essential: original producer parameter 0
      # and original consumer parameter 0 are different bindings.
      producer_retained(bind(retained, next, Nil{}), parameters, env, body, consumer, added, code)
def producer_retained(bound: Bound, parameters: List<&2, BIR.Parameter>, env: List<&2, Binding>, body: BIR.Block, +consumer: Consumer, added: List<&2, BIR.Code>, +code: U32) -> Maybe<&2, BuiltPair>:
  match bound consumer:
    case Bound{extra_parameters, arguments, _, next} Consumer{continuation, _}:
      match clone_producer(body, env, next, continuation, arguments, 32):
        case None{}: None{}
        case Some{Cloned{cloned, fresh}}:
          Some{BuiltPair{code, consumer, BIR.Code{code, Nil{}, List.append(&2, BIR.Parameter, parameters, extra_parameters), cloned} <> added, fresh}}

# Diagnostics are built only by plan. The production entry does not allocate
# per-site proof/refusal records. Both entries run the identical admission and
# publication code, and no rejected attempt changes counters, IDs or caches.
def reject(site: Site, reason: String, state: State) -> State:
  match site state:
    case Site{owner, binding, _, _, _, _} State{next, room, consumers, pairs, workers, replacements, proofs, refusals, refs, dead, owners, detail}:
      match detail:
        case False{}: state
        case True{}: State{next, room, consumers, pairs, workers, replacements, proofs, Refusal{owner, binding, reason} <> refusals, refs, dead, owners, detail}
def decrease(state: State, +id: U32) -> State:
  match state:
    case State{next, room, consumers, pairs, workers, replacements, proofs, refusals, +refs, dead, owners, detail}:
      match ref_count(refs, id):
        case 0: state
        case 1: State{next, room, consumers, pairs, workers, replacements, proofs, refusals, Map.set(&2, U32, refs, key(id), 0), Map.set(&2, Bool, dead, key(id), True{}), owners, detail}
        case count: State{next, room, consumers, pairs, workers, replacements, proofs, refusals, Map.set(&2, U32, refs, key(id), U32.sub(count, 1)), dead, owners, detail}
def install(site: Site, prepared: Prepared, worker: U32, continuation: U32, state: State) -> State:
  match site prepared state:
    case Site{owner, binding, producer, inputs, consumer, _} Prepared{_, Shape{constructor, _, _}, _, Selected{record, _, arguments}, _} State{_, _, _, _, _, _, _, _, _, _, _, detail}:
      install_detail(detail, owner, binding, producer, consumer, record, constructor, worker, continuation, inputs, arguments, state)
def install_detail(detail: Bool, owner: U32, binding: U32, producer: U32, consumer: U32, record: U32, constructor: U32, worker: U32, continuation: U32, inputs: List<&2, BIR.Arg>, arguments: List<&2, BIR.Arg>, state: State) -> State:
  match state:
    case State{next, room, consumers, pairs, workers, replacements, proofs, refusals, refs, dead, owners, _}:
      install_proof(detail, owner, binding, producer, consumer, record, constructor, worker, continuation,
        decrease(decrease(State{next, room, consumers, pairs, workers, Map.set(&2, BIR.Block, replacements, pair_key(owner, binding), BIR.TailDirect{worker, List.append(&2, BIR.Arg, inputs, arguments)}), proofs, refusals, refs, dead, Map.set(&2, Bool, owners, key(owner), True{}), detail}, producer), consumer))
def install_proof(detail: Bool, owner: U32, binding: U32, producer: U32, consumer: U32, record: U32, constructor: U32, continuation_worker: U32, continuation: U32, state: State) -> State:
  match detail:
    case False{}: state
    case True{}:
      match state:
        case State{next, room, consumers, pairs, workers, replacements, proofs, refusals, refs, dead, owners, detail}:
          State{next, room, consumers, pairs, workers, replacements, Proof{owner, binding, producer, consumer, record, constructor, continuation, continuation_worker} <> proofs, refusals, refs, dead, owners, detail}
def publish(site: Site, prepared: Prepared, built: BuiltPair, state: State) -> State:
  match site prepared built state:
    case Site{_, _, producer, _, consumer, _} Prepared{_, Shape{constructor, _, _}, _, Selected{record, _, _}, _} BuiltPair{worker, value, added, fresh} State{_, room, consumers, pairs, workers, replacements, proofs, refusals, refs, dead, owners, detail}:
      match value:
        case Consumer{continuation, _}:
          install(site, prepared, worker, continuation, State{fresh, U32.sub(room, 1), Map.set(&2, Consumer, consumers, shape_key(consumer, record, constructor), value), Map.set(&2, U32, pairs, worker_key(producer, consumer, record), worker), List.append(&2, BIR.Code, added, workers), replacements, proofs, refusals, refs, dead, owners, detail})
def specialize(site: Site, prepared: Prepared, state: State) -> State:
  match site prepared state:
    case Site{_, _, producer, _, consumer, _} Prepared{_, Shape{constructor, _, _}, _, Selected{record, _, _}, _} State{next, room, +consumers, +pairs, _, _, _, _, _, _, _, _}:
      specialize_cached(Index.find(U32, pairs, worker_key(producer, consumer, record)), Index.find(Consumer, consumers, shape_key(consumer, record, constructor)), next, room, site, prepared, state)
def specialize_cached(pair: Maybe<&2, U32>, cached: Maybe<&2, Consumer>, next: U32, room: U32, site: Site, prepared: Prepared, state: State) -> State:
  match pair cached:
    case Some{worker} Some{Consumer{continuation, _}}: install(site, prepared, worker, continuation, state)
    case Some{_} None{}: reject(site, "inconsistent-cache", state)
    case None{} _:
      match room:
        case 0: reject(site, "pair-budget", state)
        case _:
          # 512 covers both bounded bodies, parameters and code IDs with room
          # to spare. No U32.inc in a clone can cross the checked reservation.
          match U32.is_le(next, 4294966783):
            case False{}: reject(site, "fresh-id-overflow", state)
            case True{}:
              match continuation(prepared, cached, next):
                case None{}: reject(site, "consumer-escape-or-budget", state)
                case Some{built_k}:
                  match producer_worker(prepared, built_k):
                    case None{}: reject(site, "producer-frame", state)
                    case Some{built}: publish(site, prepared, built, state)
def plan_sites(sites: List<&2, Site>, +codes: Map<&2, BIR.Code>, state: State) -> State:
  match sites:
    case Nil{}: state
    case site <> rest: plan_sites(rest, codes, plan_site(site, codes, state))
def plan_site(site: Site, codes: Map<&2, BIR.Code>, state: State) -> State:
  match site state:
    case Site{owner, _, _, _, _, _} State{_, _, _, _, _, _, _, _, refs, _, _, _}:
      match ref_count(refs, owner):
        case 0: reject(site, "unreferenced-owner", state)
        case _:
          match prepare(site, codes):
            case Refuse{reason}: reject(site, reason, state)
            case Admit{prepared}: specialize(site, prepared, state)

# Only owners with admitted sites are visited again. Unchanged subtrees are
# returned by identity; no second giant complete BIR rebuild or width solver.
def rewrite(body: BIR.Block, +owner: U32, +replacements: Map<&2, BIR.Block>) -> Maybe<&2, BIR.Block>:
  match body:
    case BIR.Let{id, op, next}:
      match Index.find(BIR.Block, replacements, pair_key(owner, id)):
        case Some{replacement}: Some{replacement}
        case None{}:
          match rewrite(next, owner, replacements):
            case Some{tail}: Some{BIR.Let{id, op, tail}}
            case None{}: None{}
    case BIR.Branch{condition, yes, no}:
      rewrite_branch(condition, yes, no, rewrite(yes, owner, replacements), rewrite(no, owner, replacements))
    case BIR.Region{label, nested, next}:
      rewrite_region(label, nested, next, rewrite(nested, owner, replacements), rewrite(next, owner, replacements))
    case _: None{}
def rewrite_branch(condition: BIR.Atom, yes: BIR.Block, no: BIR.Block, a: Maybe<&2, BIR.Block>, b: Maybe<&2, BIR.Block>) -> Maybe<&2, BIR.Block>:
  match a b:
    case None{} None{}: None{}
    case Some{left} None{}: Some{BIR.Branch{condition, left, no}}
    case None{} Some{right}: Some{BIR.Branch{condition, yes, right}}
    case Some{left} Some{right}: Some{BIR.Branch{condition, left, right}}
def rewrite_region(label: U32, body: BIR.Block, next: BIR.Block, a: Maybe<&2, BIR.Block>, b: Maybe<&2, BIR.Block>) -> Maybe<&2, BIR.Block>:
  match a b:
    case None{} None{}: None{}
    case Some{left} None{}: Some{BIR.Region{label, left, next}}
    case None{} Some{right}: Some{BIR.Region{label, body, right}}
    case Some{left} Some{right}: Some{BIR.Region{label, left, right}}
def rewritten_code(code: BIR.Code, +owners: Map<&2, Bool>, replacements: Map<&2, BIR.Block>) -> BIR.Code:
  match code:
    case BIR.Code{id, captures, parameters, body}:
      match Index.find(Bool, owners, key(id)):
        case None{}: code
        case Some{_}:
          match rewrite(body, id, replacements):
            case None{}: code
            case Some{fresh}: BIR.Code{id, captures, parameters, fresh}
def rewrite_codes(codes: List<&2, BIR.Code>, +dead: Map<&2, Bool>, +owners: Map<&2, Bool>, +replacements: Map<&2, BIR.Block>, acc: List<&2, BIR.Code>) -> List<&2, BIR.Code>:
  match codes:
    case Nil{}: List.reverse(&2, BIR.Code, acc)
    case code <> rest:
      match code:
        case BIR.Code{id, _, _, _}:
          match Index.find(Bool, dead, key(id)):
            case Some{_}: rewrite_codes(rest, dead, owners, replacements, acc)
            case None{}: rewrite_codes(rest, dead, owners, replacements, rewritten_code(code, owners, replacements) <> acc)
def finish(program: BIR.Program, state: State) -> Plan:
  match state:
    case State{_, _, _, _, Nil{}, _, proofs, refusals, _, _, _, _}: Plan{program, List.reverse(&2, Proof, proofs), List.reverse(&2, Refusal, refusals)}
    case State{_, _, _, _, workers, replacements, proofs, refusals, _, dead, owners, _}:
      match program:
        case BIR.Program{codes, declarations, layouts, families, functions, ending}:
          Plan{BIR.Program{List.append(&2, BIR.Code, rewrite_codes(codes, dead, owners, replacements, Nil{}), List.reverse(&2, BIR.Code, workers)), declarations, layouts, families, functions, ending}, List.reverse(&2, Proof, proofs), List.reverse(&2, Refusal, refusals)}
def plan_inventory(program: BIR.Program, scan: Scan, detail: Bool) -> Plan:
  match scan:
    case Scan{_, 0, _, _, _, _}: Plan{program, Nil{}, global_refusal(detail, "inventory-budget-or-duplicate-code")}
    case Scan{high, _, site_room, codes, sites, refs}:
      match U32.is_le(high, 4294966782):
        case False{}: Plan{program, Nil{}, global_refusal(detail, "fresh-id-overflow")}
        case True{}:
          finish(program, plan_sites(List.reverse(&2, Site, sites), codes, State{U32.inc(high), 256, Map.new(&2, Consumer), Map.new(&2, U32), Nil{}, Map.new(&2, BIR.Block), Nil{}, site_refusal(detail, site_room), refs, Map.new(&2, Bool), Map.new(&2, Bool), detail}))
def global_refusal(detail: Bool, reason: String) -> List<&2, Refusal>:
  match detail:
    case True{}: Refusal{0, 0, reason} <> Nil{}
    case False{}: Nil{}
def site_refusal(detail: Bool, room: U32) -> List<&2, Refusal>:
  match room:
    case 0: global_refusal(detail, "site-limit-reached")
    case _: Nil{}
def plan(+program: BIR.Program) -> Plan:
  plan_inventory(program, inventory(program), True{})
def optimize(+program: BIR.Program) -> BIR.Program:
  match plan_inventory(program, inventory(program), False{}):
    case Plan{optimized, _, _}: optimized
