import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/descriptor_nf.bend as NF

type NfSmoke is Data:
  NfSmoke{bits: String}

def smoke_families() -> List<&2, BIR.Family>:
  [BIR.Family{"Nat", "Nat", Some{"Nat"}, 0n, 0n, Nil{}},
   BIR.Family{"Bool", "Bool", Some{"Bool"}, 0n, 0n, Nil{}},
   BIR.Family{"QM", "QM", Some{"QM"}, 1n, 1n, Nil{}}]

# The arrow fixtures are the published de Bruijn convention, not a guess: the
# parser parses an arrow's codomain at `depth + 1` and the checker binds the
# arrow (`infer_all_domain`), so a body names the arrow's own argument at 0 and
# an enclosing binder one index further out than the domain names it.
#
#   SelfArrow<A>   = A -> A              domain names A at 0, body at 1
#   ArrowBound<A>  = A -> <arrow arg>    body names the arrow's own argument
#   ArrowNest<A>   = A -> (A -> <outer arrow arg>)
#   AppTick<A>     = List<Event> -> A -> IO(Maybe<A>)
#                  the canonical App field `tick`, whose A is two arrows in
def smoke_functions() -> List<&2, BIR.TypeFunction>:
  [BIR.TypeFunction{"IO", Some{"IO"}, 0n, 1n, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"IO.OP", Nil{}}, BIR.DescriptorRef{"IO.OP", [BIR.DescriptorRef{"Nat", Nil{}}]}}},
   BIR.TypeFunction{"MyNat", None{}, 0n, 0n, BIR.DescriptorRef{"Nat", Nil{}}},
   BIR.TypeFunction{"MyNat2", None{}, 0n, 0n, BIR.DescriptorRef{"MyNat", Nil{}}},
   BIR.TypeFunction{"MyIO", None{}, 0n, 0n, BIR.DescriptorRef{"IO", [BIR.DescriptorRef{"Nat", Nil{}}]}},
   BIR.TypeFunction{"Id", None{}, 0n, 1n, BIR.DescriptorParameter{0n}},
   BIR.TypeFunction{"K2", None{}, 0n, 1n, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}},
   BIR.TypeFunction{"K3", None{}, 0n, 2n, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{2n}}},
   BIR.TypeFunction{"SelfArrow", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{1n}}},
   BIR.TypeFunction{"ArrowBound", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{0n}}},
   BIR.TypeFunction{"ArrowNest", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{1n}}}},
   BIR.TypeFunction{"AppTick", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"List", [BIR.DescriptorRef{"Event", Nil{}}]}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{1n}, BIR.DescriptorRef{"IO", [BIR.DescriptorRef{"Maybe", [BIR.DescriptorParameter{2n}]}]}}}},
   BIR.TypeFunction{"AbsMatch", None{}, 0n, 1n, BIR.DescriptorMatch{[BIR.DescriptorParameter{0n}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", Nil{}}], BIR.DescriptorRef{"Nat", Nil{}}}]}},
   BIR.TypeFunction{"K", None{}, 0n, 1n, BIR.DescriptorRef{"Bool", Nil{}}},
   BIR.TypeFunction{"CycA", None{}, 0n, 0n, BIR.DescriptorRef{"CycB", Nil{}}},
   BIR.TypeFunction{"CycB", None{}, 0n, 0n, BIR.DescriptorRef{"CycA", Nil{}}}]

def is_nat(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"Nat", args}:
      match args:
        case Nil{}: True{}
        case _: False{}
    case _: False{}

def is_failure_with(value: BIR.Descriptor, expected: String) -> Bool:
  match value:
    case BIR.DescriptorFailure{message}: String.eq(message, expected)
    case _: False{}

def is_bool(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"Bool", args}:
      match args:
        case Nil{}: True{}
        case _: False{}
    case _: False{}

def is_arrow_nat(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorRef{"Nat", Nil{}}}: True{}
    case _: False{}

# The arrow fixtures' expected normal forms, written out structurally and
# derived from the convention above, not from the module's output: a body's
# reference to the arrow's own argument stays a parameter at 0, a reference to
# an enclosing arrow's argument is one further out, and a reference to the
# enclosing type function's argument becomes that argument.
def is_arrow_bound(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorParameter{0n}}: True{}
    case _: False{}

def is_arrow_nest(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorParameter{1n}}}: True{}
    case _: False{}

def is_scoped_let_arrow(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorArrow{BIR.Erased{}, _, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{1n}}}: True{}
    case _: False{}

# Moving a saved dependent arrow under another arrow must keep the captured
# outer type, not accidentally bind the new intervening argument.
def is_relocated_arrow(value: BIR.Descriptor, expected: Nat) -> Bool:
  match value:
    case BIR.DescriptorArrow{BIR.Erased{}, _, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorParameter{index}}}}: Nat.is_eq(index, expected)
    case _: False{}

def is_nat_ref(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"Nat", args}:
      match args:
        case Nil{}: True{}
        case _: False{}
    case _: False{}

def is_maybe_nat(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"Maybe", args}:
      match args:
        case +only <> rest:
          match rest:
            case Nil{}: is_nat_ref(only)
            case _: False{}
        case _: False{}
    case _: False{}

def is_io_maybe_nat(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"IO", args}:
      match args:
        case +only <> rest:
          match rest:
            case Nil{}: is_maybe_nat(only)
            case _: False{}
        case _: False{}
    case _: False{}

def is_event_list(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"List", args}:
      match args:
        case BIR.DescriptorRef{"Event", Nil{}} <> rest:
          match rest:
            case Nil{}: True{}
            case _: False{}
        case _: False{}
    case _: False{}

def is_app_tick(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorArrow{BIR.Erased{}, domain, body}:
      match body:
        case BIR.DescriptorArrow{BIR.Erased{}, inner_domain, inner_body}:
          match is_event_list(domain), is_nat_ref(inner_domain):
            case True{}, True{}: is_io_maybe_nat(inner_body)
            case _, _: False{}
        case _: False{}
    case _: False{}

def is_match_source(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorMatch{_, _}: True{}
    case _: False{}

def is_failure(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorFailure{_}: True{}
    case _: False{}

def is_application(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorApplication{BIR.DescriptorParameter{0n}, BIR.DescriptorRef{"Nat", args}}:
      match args:
        case Nil{}: True{}
        case _: False{}
    case _: False{}

def is_quantity_head(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"QM", args}:
      match args:
        case BIR.DescriptorQuantity{BIR.Erased{}} <> tail:
          match tail:
            case Nil{}: True{}
            case _: False{}
        case _: False{}
    case _: False{}

def is_parameter(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorParameter{0n}: True{}
    case _: False{}

def is_chan(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"Chan", args}:
      match args:
        case Nil{}: True{}
        case _: False{}
    case _: False{}

def is_under_applied_head(value: BIR.Descriptor) -> Bool:
  match value:
    case BIR.DescriptorRef{"K", args}:
      match args:
        case Nil{}: True{}
        case _: False{}
    case _: False{}

def equal_args(values: List<&2, BIR.Descriptor>, expected: List<&2, BIR.Descriptor>) -> Bool:
  match values, expected:
    case Nil{}, Nil{}: True{}
    case BIR.DescriptorRef{"Nat", Nil{}} <> rest, BIR.DescriptorRef{"Nat", Nil{}} <> wanted: equal_args(rest, wanted)
    case BIR.DescriptorRef{"Bool", Nil{}} <> rest, BIR.DescriptorRef{"Bool", Nil{}} <> wanted: equal_args(rest, wanted)
    case BIR.DescriptorRef{"A", Nil{}} <> rest, BIR.DescriptorRef{"A", Nil{}} <> wanted: equal_args(rest, wanted)
    case BIR.DescriptorRef{"B", Nil{}} <> rest, BIR.DescriptorRef{"B", Nil{}} <> wanted: equal_args(rest, wanted)
    case _, _: False{}

def outer_is(value: Maybe<&2, NF.NfApp>, expected: List<&2, BIR.Descriptor>) -> Bool:
  match value:
    case Some{app}:
      match app:
        case NF.NfApp{key, args}: equal_args(args, expected)
    case None{}: False{}

def bit(value: Bool) -> String:
  match value:
    case True{}: "1"
    case False{}: "0"

def main(modules: List<&2, Loader.LoadedModule>) -> NfSmoke:
  +f = smoke_families()
  +t = smoke_functions()
  nat_alias = NF.normalize_closed(f, t, BIR.DescriptorRef{"MyNat", Nil{}})
  io_answer = NF.answer_descriptor(BIR.DescriptorRef{"MyIO", Nil{}}, f, t)
  id_sub = NF.normalize_closed(f, t, BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Nat", Nil{}}]})
  abstract = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorParameter{0n}, BIR.DescriptorRef{"Nat", Nil{}}})
  cycle = NF.normalize_closed(f, t, BIR.DescriptorRef{"CycA", Nil{}})
  prefix = NF.normalize_closed(f, t, BIR.DescriptorRef{"QM", Nil{}})
  over = NF.normalize_closed(f, t, BIR.DescriptorRef{"K", [BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorRef{"Bool", Nil{}}]})
  nested_id = NF.normalize_closed(f, t, BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Nat", Nil{}}]}]})
  matched = NF.normalize_closed(f, t, BIR.DescriptorMatch{[BIR.DescriptorConstructor{"C", [BIR.DescriptorRef{"Nat", Nil{}}]}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"C", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}]})
  under = NF.normalize_closed(f, t, BIR.DescriptorRef{"K", Nil{}})
  chan = NF.normalize_closed(f, t, BIR.DescriptorRef{"Chan", Nil{}})
  parameter = NF.normalize_closed(f, t, BIR.DescriptorParameter{0n})
  family_over = NF.normalize_closed(f, t, BIR.DescriptorRef{"Nat", [BIR.DescriptorRef{"Bool", Nil{}}]})
  chained = NF.normalize_closed(f, t, BIR.DescriptorRef{"MyNat2", Nil{}})
  malformed_case = NF.normalize_closed(f, t, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", Nil{}}], [BIR.DescriptorFailure{"bend: malformed type match"}]})
  noncase = NF.normalize_closed(f, t, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", Nil{}}], [BIR.DescriptorNull{}]})
  second_match = NF.normalize_closed(f, t, BIR.DescriptorMatch{[BIR.DescriptorConstructor{"C", [BIR.DescriptorRef{"Nat", Nil{}}]}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"D", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}, BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"C", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}]})
  fill = NF.outer_application(BIR.DescriptorFill{BIR.DescriptorFill{BIR.DescriptorRef{"C", [BIR.DescriptorRef{"A", Nil{}}]}, [BIR.DescriptorRef{"B", Nil{}}]}, [BIR.DescriptorRef{"Nat", Nil{}}]})
  applied = NF.outer_application(BIR.DescriptorApplication{BIR.DescriptorApplication{BIR.DescriptorRef{"C", [BIR.DescriptorRef{"A", Nil{}}]}, BIR.DescriptorRef{"B", Nil{}}}, BIR.DescriptorRef{"Nat", Nil{}}})
  five = String.append(bit(is_nat(nat_alias)), String.append(bit(is_nat(io_answer)), String.append(bit(is_nat(id_sub)), String.append(bit(is_failure(cycle)), bit(is_application(abstract))))))
  rest = String.append(bit(is_quantity_head(prefix)), String.append(bit(is_failure(over)), String.append(bit(is_nat(nested_id)), String.append(bit(is_nat(matched)), String.append(bit(is_under_applied_head(under)), String.append(bit(is_chan(chan)), bit(is_parameter(parameter))))))))
  both = String.append(bit(outer_is(fill, [BIR.DescriptorRef{"A", Nil{}}, BIR.DescriptorRef{"B", Nil{}}, BIR.DescriptorRef{"Nat", Nil{}}])), bit(outer_is(applied, [BIR.DescriptorRef{"A", Nil{}}, BIR.DescriptorRef{"B", Nil{}}, BIR.DescriptorRef{"Nat", Nil{}}])))
  extra = String.append(bit(is_failure(family_over)), bit(is_nat(chained)))
  cases_bits = String.append(String.append(bit(is_failure_with(malformed_case, "bend: malformed type match")), bit(is_failure_with(noncase, "descriptor match case is not a case"))), bit(is_nat(second_match)))
  lambda_beta = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{0n}}, BIR.DescriptorRef{"Nat", Nil{}}})
  higher_order = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorRef{"K2", [BIR.DescriptorRef{"Nat", Nil{}}]}, BIR.DescriptorRef{"Bool", Nil{}}})
  captured = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.DescriptorRef{"Nat", Nil{}}}, BIR.DescriptorRef{"Bool", Nil{}}})
  partial = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.DescriptorRef{"Nat", Nil{}}})
  reapplied = NF.normalize_closed(f, t, BIR.DescriptorApplication{partial, BIR.DescriptorRef{"Bool", Nil{}}})
  abstract_match = NF.normalize_closed(f, t, BIR.DescriptorMatch{[BIR.DescriptorParameter{0n}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", Nil{}}], BIR.DescriptorRef{"Nat", Nil{}}}, BIR.DescriptorCase{[BIR.DescriptorBinder{BIR.Erased{}}], BIR.DescriptorRef{"Bool", Nil{}}}]})
  known_mismatch = NF.normalize_closed(f, t, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", Nil{}}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", Nil{}}], BIR.DescriptorRef{"Nat", Nil{}}}, BIR.DescriptorCase{[BIR.DescriptorBinder{BIR.Erased{}}], BIR.DescriptorRef{"Bool", Nil{}}}]})
  ctor_app = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorConstructor{"C", Nil{}}, BIR.DescriptorRef{"Nat", Nil{}}})
  quantity_app = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorQuantity{BIR.Erased{}}, BIR.DescriptorRef{"Nat", Nil{}}})
  kind_app = NF.normalize_closed(f, t, BIR.DescriptorApplication{BIR.DescriptorKind{BIR.DescriptorRef{"Nat", Nil{}}}, BIR.DescriptorRef{"Bool", Nil{}}})
  free_partial = NF.normalize_closed(f, t, BIR.DescriptorRef{"K2", [BIR.DescriptorParameter{0n}]})
  k3_partial = NF.normalize_closed(f, t, BIR.DescriptorRef{"K3", [BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{0n}]})
  k3_applied = NF.normalize(NF.nf_context(f, t), BIR.DescriptorApplication{k3_partial, BIR.DescriptorRef{"U32", Nil{}}}, [NF.NfType{"Nat", Nil{}}, NF.NfType{"Bool", Nil{}}], 1024n)
  free_reapplied = NF.normalize(NF.nf_context(f, t), BIR.DescriptorApplication{free_partial, BIR.DescriptorRef{"Nat", Nil{}}}, [NF.NfType{"Bool", Nil{}}], 1024n)
  arrow_alias = NF.normalize_closed(f, t, BIR.DescriptorRef{"SelfArrow", [BIR.DescriptorRef{"Nat", Nil{}}]})
  match_alias = NF.normalize_closed(f, t, BIR.DescriptorRef{"AbsMatch", [BIR.DescriptorParameter{0n}]})
  match_reapplied = NF.normalize(NF.nf_context(f, t), match_alias, [NF.NfCtor{"True", Nil{}}], 1024n)
  boundary_bits = String.append(String.append(String.append(bit(is_bool(free_reapplied)), bit(is_arrow_nat(arrow_alias))), bit(is_nat(match_reapplied))), bit(is_nat(k3_applied)))
  arrow_bound = NF.normalize_closed(f, t, BIR.DescriptorRef{"ArrowBound", [BIR.DescriptorRef{"Nat", Nil{}}]})
  arrow_nest = NF.normalize_closed(f, t, BIR.DescriptorRef{"ArrowNest", [BIR.DescriptorRef{"Nat", Nil{}}]})
  app_tick = NF.normalize_closed(f, t, BIR.DescriptorRef{"AppTick", [BIR.DescriptorRef{"Nat", Nil{}}]})
  arrow_bits = String.append(bit(is_arrow_bound(arrow_bound)), String.append(bit(is_arrow_nest(arrow_nest)), bit(is_app_tick(app_tick))))
  new_bits = String.append(bit(is_nat(lambda_beta)), String.append(bit(is_nat(higher_order)), String.append(bit(is_nat(captured)), String.append(bit(is_nat(reapplied)), String.append(bit(is_match_source(abstract_match)), String.append(bit(is_bool(known_mismatch)), String.append(bit(is_failure_with(ctor_app, "the constructor `C` is applied to an argument")), String.append(bit(is_failure_with(quantity_app, "a quantity is applied to an argument")), bit(is_failure_with(kind_app, "a kind is applied to an argument"))))))))))
  let_arrow = NF.normalize_closed(f, t, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorRef{"Nat", Nil{}}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{2n}}}})
  relocated_arrow = NF.normalize_closed(f, t, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorParameter{1n}}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorParameter{1n}}}})
  relocated_self = NF.normalize_closed(f, t, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorParameter{0n}}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", Nil{}}, BIR.DescriptorParameter{1n}}}})
  scope_bits = String.append(arrow_bits, String.append(bit(is_scoped_let_arrow(let_arrow)), String.append(bit(is_relocated_arrow(relocated_arrow, 2n)), bit(is_relocated_arrow(relocated_self, 0n)))))
  NfSmoke{String.append(String.append(String.append(String.append(String.append(five, rest), both), extra), cases_bits), String.append(String.append(new_bits, boundary_bits), scope_bits))}
