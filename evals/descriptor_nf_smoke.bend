import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/descriptor_nf.bend as NF

type NfSmoke is Data:
  NfSmoke{bits: String}

def smoke_families() -> List<&2, BIR.Family>:
  [BIR.Family{"Nat", "Nat", Some{"Nat"}, 0n, 0n, Nil{}},
   BIR.Family{"Bool", "Bool", Some{"Bool"}, 0n, 0n, Nil{}},
   BIR.Family{"QM", "QM", Some{"QM"}, 1n, 1n, Nil{}}]

def smoke_functions() -> List<&2, BIR.TypeFunction>:
  [BIR.TypeFunction{"IO", Some{"IO"}, 0n, 1n, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"IO.OP", Nil{}}, BIR.DescriptorRef{"IO.OP", [BIR.DescriptorRef{"Nat", Nil{}}]}}},
   BIR.TypeFunction{"MyNat", None{}, 0n, 0n, BIR.DescriptorRef{"Nat", Nil{}}},
   BIR.TypeFunction{"MyNat2", None{}, 0n, 0n, BIR.DescriptorRef{"MyNat", Nil{}}},
   BIR.TypeFunction{"MyIO", None{}, 0n, 0n, BIR.DescriptorRef{"IO", [BIR.DescriptorRef{"Nat", Nil{}}]}},
   BIR.TypeFunction{"Id", None{}, 0n, 1n, BIR.DescriptorParameter{0n}},
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
  NfSmoke{String.append(String.append(String.append(String.append(five, rest), both), extra), cases_bits)}
