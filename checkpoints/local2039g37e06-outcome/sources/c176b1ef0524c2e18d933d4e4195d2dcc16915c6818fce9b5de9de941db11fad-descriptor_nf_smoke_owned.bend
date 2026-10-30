import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/index_lookup.bend as IndexLookup

type NfSmoke is Data:
  NfSmoke{bits: String}

type cps_provider_1_NfVal is Data:
  cps_provider_1_NfType{key: String, args: List<&2, cps_provider_1_NfVal>}
  cps_provider_1_NfCtor{key: String, args: List<&2, cps_provider_1_NfVal>}
  cps_provider_1_NfQuantity{quantity: BIR.Quantity}
  cps_provider_1_NfKind{quantity: cps_provider_1_NfVal}
  cps_provider_1_NfOther{source: BIR.Descriptor}
  cps_provider_1_NfMissing{source: BIR.Descriptor}
  cps_provider_1_NfBinder{level: Nat}
  cps_provider_1_NfArrow{quantity: BIR.Quantity, domain: cps_provider_1_NfVal, body: cps_provider_1_NfVal, level: Nat}
  cps_provider_1_NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, cps_provider_1_NfVal>}

type cps_provider_1_NfRenaming is Data:
  cps_provider_1_NfRenaming{source: Nat, target: Nat}

type cps_provider_1_NfBind is Data:
  cps_provider_1_NfBound{bindings: List<&2, cps_provider_1_NfVal>}
  cps_provider_1_NfMismatch{}
  cps_provider_1_NfUnknown{}

type cps_provider_1_NfStatus is Data:
  cps_provider_1_NfStatusOk{}
  cps_provider_1_NfStatusNo{}
  cps_provider_1_NfStatusMaybe{}

type cps_provider_1_Nf is Data:
  cps_provider_1_NfOk{val: cps_provider_1_NfVal}
  cps_provider_1_NfFail{message: String}

type cps_provider_1_NfList is Data:
  cps_provider_1_NfListOk{vals: List<&2, cps_provider_1_NfVal>}
  cps_provider_1_NfListFail{message: String}

type cps_provider_1_NfContext is Data:
  cps_provider_1_NfContext{families: Map<&2, BIR.Family>, type_functions: Map<&2, BIR.TypeFunction>}

type cps_provider_1_NfApp is Data:
  cps_provider_1_NfApp{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_1_NfArity is Data:
  cps_provider_1_NfArity{complete: Bool, exact: Bool, under: Bool}

def smoke_families() -> List<&2, BIR.Family>:
  [BIR.Family{"Nat", "Nat", Some{"Nat"}, 0n, 0n, []}, BIR.Family{"Bool", "Bool", Some{"Bool"}, 0n, 0n, []}, BIR.Family{"QM", "QM", Some{"QM"}, 1n, 1n, []}]

def smoke_functions() -> List<&2, BIR.TypeFunction>:
  [BIR.TypeFunction{"IO", Some{"IO"}, 0n, 1n, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"IO.OP", []}, BIR.DescriptorRef{"IO.OP", [BIR.DescriptorRef{"Nat", []}]}}}, BIR.TypeFunction{"MyNat", None{}, 0n, 0n, BIR.DescriptorRef{"Nat", []}}, BIR.TypeFunction{"MyNat2", None{}, 0n, 0n, BIR.DescriptorRef{"MyNat", []}}, BIR.TypeFunction{"MyIO", None{}, 0n, 0n, BIR.DescriptorRef{"IO", [BIR.DescriptorRef{"Nat", []}]}}, BIR.TypeFunction{"Id", None{}, 0n, 1n, BIR.DescriptorParameter{0n}}, BIR.TypeFunction{"K2", None{}, 0n, 1n, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.TypeFunction{"K3", None{}, 0n, 2n, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{2n}}}, BIR.TypeFunction{"SelfArrow", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{1n}}}, BIR.TypeFunction{"ArrowBound", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{0n}}}, BIR.TypeFunction{"ArrowNest", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{1n}}}}, BIR.TypeFunction{"AppTick", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"List", [BIR.DescriptorRef{"Event", []}]}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{1n}, BIR.DescriptorRef{"IO", [BIR.DescriptorRef{"Maybe", [BIR.DescriptorParameter{2n}]}]}}}}, BIR.TypeFunction{"AbsMatch", None{}, 0n, 1n, BIR.DescriptorMatch{[BIR.DescriptorParameter{0n}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", []}], BIR.DescriptorRef{"Nat", []}}]}}, BIR.TypeFunction{"K", None{}, 0n, 1n, BIR.DescriptorRef{"Bool", []}}, BIR.TypeFunction{"CycA", None{}, 0n, 0n, BIR.DescriptorRef{"CycB", []}}, BIR.TypeFunction{"CycB", None{}, 0n, 0n, BIR.DescriptorRef{"CycA", []}}]

def is_nat(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Nat", v_3}:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case _:
      False{}

def is_failure_with(v_0: BIR.Descriptor, v_2: String) -> Bool:
  match v_0:
    case BIR.DescriptorFailure{v_5}:
      String.eq(v_5, v_2)
    case _:
      False{}

def is_bool(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Bool", v_3}:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case _:
      False{}

def is_arrow_nat(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorRef{"Nat", []}}:
      True{}
    case _:
      False{}

def is_arrow_bound(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{0n}}:
      True{}
    case _:
      False{}

def is_arrow_nest(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}}:
      True{}
    case _:
      False{}

def is_scoped_let_arrow(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, _, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{1n}}}:
      True{}
    case _:
      False{}

def is_relocated_arrow(v_0: BIR.Descriptor, v_2: Nat) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, _, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{v_7}}}}:
      Nat.is_eq(v_7, v_2)
    case _:
      False{}

def is_nat_ref(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Nat", v_3}:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case _:
      False{}

def is_maybe_nat(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Maybe", v_3}:
      match v_3:
        case +v_6 <> v_7:
          match v_7:
            case []:
              is_nat_ref(v_6)
            case _:
              False{}
        case _:
          False{}
    case _:
      False{}

def is_io_maybe_nat(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"IO", v_3}:
      match v_3:
        case +v_6 <> v_7:
          match v_7:
            case []:
              is_maybe_nat(v_6)
            case _:
              False{}
        case _:
          False{}
    case _:
      False{}

def is_event_list(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"List", v_3}:
      match v_3:
        case BIR.DescriptorRef{"Event", []} <> v_5:
          match v_5:
            case []:
              True{}
            case _:
              False{}
        case _:
          False{}
    case _:
      False{}

def native_match_is_app_tick_0(v_23: Bool, v_24: Bool, v_9: BIR.Descriptor) -> Bool:
  match v_23, v_24:
    case True{}, True{}:
      is_io_maybe_nat(v_9)
    case _, _:
      False{}

def native_match_is_app_tick_1(v_5: BIR.Descriptor, v_4: BIR.Descriptor) -> Bool:
  match v_5:
    case BIR.DescriptorArrow{BIR.Erased{}, v_8, v_9}:
      native_match_is_app_tick_0(is_event_list(v_4), is_nat_ref(v_8), v_9)
    case _:
      False{}

def native_match_is_app_tick_2(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, v_4, v_5}:
      native_match_is_app_tick_1(v_5, v_4)
    case _:
      False{}

def is_app_tick(v_0: BIR.Descriptor) -> Bool:
  native_match_is_app_tick_2(v_0)

def is_match_source(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorMatch{_, _}:
      True{}
    case _:
      False{}

def is_failure(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorFailure{_}:
      True{}
    case _:
      False{}

def is_application(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorApplication{BIR.DescriptorParameter{0n}, BIR.DescriptorRef{"Nat", v_3}}:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case _:
      False{}

def is_quantity_head(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"QM", v_3}:
      match v_3:
        case BIR.DescriptorQuantity{BIR.Erased{}} <> v_5:
          match v_5:
            case []:
              True{}
            case _:
              False{}
        case _:
          False{}
    case _:
      False{}

def is_parameter(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorParameter{0n}:
      True{}
    case _:
      False{}

def is_chan(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Chan", v_3}:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case _:
      False{}

def is_under_applied_head(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"K", v_3}:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case _:
      False{}

def equal_args(v_1: List<&2, BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_1, v_3:
    case [], []:
      True{}
    case BIR.DescriptorRef{"Nat", []} <> v_7, BIR.DescriptorRef{"Nat", []} <> v_8:
      equal_args(v_7, v_8)
    case BIR.DescriptorRef{"Bool", []} <> v_12, BIR.DescriptorRef{"Bool", []} <> v_13:
      equal_args(v_12, v_13)
    case BIR.DescriptorRef{"A", []} <> v_17, BIR.DescriptorRef{"A", []} <> v_18:
      equal_args(v_17, v_18)
    case BIR.DescriptorRef{"B", []} <> v_22, BIR.DescriptorRef{"B", []} <> v_23:
      equal_args(v_22, v_23)
    case _, _:
      False{}

def outer_is(v_1: Maybe<&2, cps_provider_1_NfApp>, v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_1:
    case Some{v_6}:
      match v_6:
        case cps_provider_1_NfApp{v_9, v_10}:
          equal_args(v_10, v_3)
    case None{}:
      False{}

def bit(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "1"
    case False{}:
      "0"

def main(v_1: List<&2, Loader.LoadedModule>) -> NfSmoke:
  +v_5 = smoke_families
  +v_8 = smoke_functions
  v_10 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"MyNat", []})
  v_12 = cps_provider_1_answer_descriptor(BIR.DescriptorRef{"MyIO", []}, v_5, v_8)
  v_14 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Nat", []}]})
  v_16 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorParameter{0n}, BIR.DescriptorRef{"Nat", []}})
  v_18 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"CycA", []})
  v_20 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"QM", []})
  v_22 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"K", [BIR.DescriptorRef{"Nat", []}, BIR.DescriptorRef{"Bool", []}]})
  v_24 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Nat", []}]}]})
  v_26 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorConstructor{"C", [BIR.DescriptorRef{"Nat", []}]}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"C", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}]})
  v_28 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"K", []})
  v_30 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"Chan", []})
  v_32 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorParameter{0n})
  v_34 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"Nat", [BIR.DescriptorRef{"Bool", []}]})
  v_36 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"MyNat2", []})
  v_38 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", []}], [BIR.DescriptorFailure{"bend: malformed type match"}]})
  v_40 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", []}], [BIR.DescriptorNull{}]})
  v_42 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorConstructor{"C", [BIR.DescriptorRef{"Nat", []}]}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"D", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}, BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"C", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}]})
  v_44 = cps_provider_1_outer_application(BIR.DescriptorFill{BIR.DescriptorFill{BIR.DescriptorRef{"C", [BIR.DescriptorRef{"A", []}]}, [BIR.DescriptorRef{"B", []}]}, [BIR.DescriptorRef{"Nat", []}]})
  v_46 = cps_provider_1_outer_application(BIR.DescriptorApplication{BIR.DescriptorApplication{BIR.DescriptorRef{"C", [BIR.DescriptorRef{"A", []}]}, BIR.DescriptorRef{"B", []}}, BIR.DescriptorRef{"Nat", []}})
  v_58 = String.append(bit(is_nat(v_10)), String.append(bit(is_nat(v_12)), String.append(bit(is_nat(v_14)), String.append(bit(is_failure(v_18)), bit(is_application(v_16))))))
  v_74 = String.append(bit(is_quantity_head(v_20)), String.append(bit(is_failure(v_22)), String.append(bit(is_nat(v_24)), String.append(bit(is_nat(v_26)), String.append(bit(is_under_applied_head(v_28)), String.append(bit(is_chan(v_30)), bit(is_parameter(v_32))))))))
  v_80 = String.append(bit(outer_is(v_44, [BIR.DescriptorRef{"A", []}, BIR.DescriptorRef{"B", []}, BIR.DescriptorRef{"Nat", []}])), bit(outer_is(v_46, [BIR.DescriptorRef{"A", []}, BIR.DescriptorRef{"B", []}, BIR.DescriptorRef{"Nat", []}])))
  v_86 = String.append(bit(is_failure(v_34)), bit(is_nat(v_36)))
  v_94 = String.append(String.append(bit(is_failure_with(v_38, "bend: malformed type match")), bit(is_failure_with(v_40, "descriptor match case is not a case"))), bit(is_nat(v_42)))
  v_96 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{0n}}, BIR.DescriptorRef{"Nat", []}})
  v_98 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorRef{"K2", [BIR.DescriptorRef{"Nat", []}]}, BIR.DescriptorRef{"Bool", []}})
  v_100 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorRef{"Bool", []}})
  v_102 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.DescriptorRef{"Nat", []}})
  v_104 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{v_102, BIR.DescriptorRef{"Bool", []}})
  v_106 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorParameter{0n}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", []}], BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorCase{[BIR.DescriptorBinder{BIR.Erased{}}], BIR.DescriptorRef{"Bool", []}}]})
  v_108 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", []}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", []}], BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorCase{[BIR.DescriptorBinder{BIR.Erased{}}], BIR.DescriptorRef{"Bool", []}}]})
  v_110 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorConstructor{"C", []}, BIR.DescriptorRef{"Nat", []}})
  v_112 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorQuantity{BIR.Erased{}}, BIR.DescriptorRef{"Nat", []}})
  v_114 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorKind{BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorRef{"Bool", []}})
  v_116 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"K2", [BIR.DescriptorParameter{0n}]})
  v_118 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"K3", [BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{0n}]})
  v_120 = cps_provider_1_normalize(cps_provider_1_nf_context(v_5, v_8), BIR.DescriptorApplication{v_118, BIR.DescriptorRef{"U32", []}}, [cps_provider_1_NfType{"Nat", []}, cps_provider_1_NfType{"Bool", []}], 1024n)
  v_122 = cps_provider_1_normalize(cps_provider_1_nf_context(v_5, v_8), BIR.DescriptorApplication{v_116, BIR.DescriptorRef{"Nat", []}}, [cps_provider_1_NfType{"Bool", []}], 1024n)
  v_124 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"SelfArrow", [BIR.DescriptorRef{"Nat", []}]})
  v_126 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"AbsMatch", [BIR.DescriptorParameter{0n}]})
  v_128 = cps_provider_1_normalize(cps_provider_1_nf_context(v_5, v_8), v_126, [cps_provider_1_NfCtor{"True", []}], 1024n)
  v_138 = String.append(String.append(String.append(bit(is_bool(v_122)), bit(is_arrow_nat(v_124))), bit(is_nat(v_128))), bit(is_nat(v_120)))
  v_140 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"ArrowBound", [BIR.DescriptorRef{"Nat", []}]})
  v_142 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"ArrowNest", [BIR.DescriptorRef{"Nat", []}]})
  v_144 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorRef{"AppTick", [BIR.DescriptorRef{"Nat", []}]})
  v_152 = String.append(bit(is_arrow_bound(v_140)), String.append(bit(is_arrow_nest(v_142)), bit(is_app_tick(v_144))))
  v_172 = String.append(bit(is_nat(v_96)), String.append(bit(is_nat(v_98)), String.append(bit(is_nat(v_100)), String.append(bit(is_nat(v_104)), String.append(bit(is_match_source(v_106)), String.append(bit(is_bool(v_108)), String.append(bit(is_failure_with(v_110, "the constructor `C` is applied to an argument")), String.append(bit(is_failure_with(v_112, "a quantity is applied to an argument")), bit(is_failure_with(v_114, "a kind is applied to an argument"))))))))))
  v_174 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorRef{"Nat", []}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{2n}}}})
  v_176 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}}})
  v_178 = cps_provider_1_normalize_closed(v_5, v_8, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{0n}}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}}})
  v_186 = String.append(v_152, String.append(bit(is_scoped_let_arrow(v_174)), String.append(bit(is_relocated_arrow(v_176, 2n)), bit(is_relocated_arrow(v_178, 0n)))))
  NfSmoke{String.append(String.append(String.append(String.append(String.append(v_58, v_74), v_80), v_86), v_94), String.append(String.append(v_172, v_138), v_186))}

def cps_provider_1_family_index(v_1: List<&2, BIR.Family>) -> Map<&2, BIR.Family>:
  match v_1:
    case []:
      Map.new(&2, BIR.Family)
    case +v_5 <> v_6:
      match v_5:
        case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
          Map.set(&2, BIR.Family, cps_provider_1_family_index(v_6), v_13, v_5)

def cps_provider_1_function_index(v_1: List<&2, BIR.TypeFunction>) -> Map<&2, BIR.TypeFunction>:
  match v_1:
    case []:
      Map.new(&2, BIR.TypeFunction)
    case +v_5 <> v_6:
      match v_5:
        case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
          Map.set(&2, BIR.TypeFunction, cps_provider_1_function_index(v_6), v_12, v_5)

def cps_provider_1_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> cps_provider_1_NfContext:
  cps_provider_1_NfContext{cps_provider_1_family_index(v_1), cps_provider_1_function_index(v_3)}

def cps_provider_1_default_fuel() -> Nat:
  1024n

def cps_provider_1_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  IndexLookup.find(BIR.Family, v_3, v_1)

def cps_provider_1_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  IndexLookup.find(BIR.TypeFunction, v_3, v_1)

def native_match_cps_provider_1_native_of_0(v_10: BIR.Family) -> Maybe<&2, String>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      v_19

def native_match_cps_provider_1_native_of_1(v_25: BIR.TypeFunction) -> Maybe<&2, String>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      v_32

def native_match_cps_provider_1_native_of_2(v_37: Maybe<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_37:
    case Some{v_25}:
      native_match_cps_provider_1_native_of_1(v_25)
    case None{}:
      None{}

def native_match_cps_provider_1_native_of_3(v_36: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_36:
    case Some{v_10}:
      native_match_cps_provider_1_native_of_0(v_10)
    case None{}:
      native_match_cps_provider_1_native_of_2(cps_provider_1_function_of(v_1, v_5))

def cps_provider_1_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  native_match_cps_provider_1_native_of_3(cps_provider_1_family_of(v_1, v_3), v_1, v_5)

def cps_provider_1_val_nth(+v_2: List<&2, cps_provider_1_NfVal>, v_4: Nat) -> cps_provider_1_NfVal:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      v_8
    case +v_13 <> v_14, 1n+v_15:
      cps_provider_1_val_nth(v_14, v_15)
    case _, _:
      cps_provider_1_NfMissing{BIR.DescriptorNull{}}

def cps_provider_1_val_at(+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> cps_provider_1_NfVal:
  cps_provider_1_val_at_choose(Nat.is_lt(v_4, List.length(&2, cps_provider_1_NfVal, v_2)), v_2, v_4, v_5)

def cps_provider_1_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_1_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> cps_provider_1_NfVal:
  match v_1:
    case True{}:
      cps_provider_1_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_1_NfVal, v_4), 1n), v_6))
    case False{}:
      cps_provider_1_NfMissing{v_7}

def cps_provider_1_first_vals(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat) -> List<&2, cps_provider_1_NfVal>:
  match v_2, v_4:
    case _, 0n:
      []
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      v_14 <> cps_provider_1_first_vals(v_15, v_16)

def cps_provider_1_drop_vals(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat) -> List<&2, cps_provider_1_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_2
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      cps_provider_1_drop_vals(v_15, v_16)

def cps_provider_1_insert_before(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, v_6: cps_provider_1_NfVal) -> List<&2, cps_provider_1_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_6 <> v_2
    case [], 1n+v_12:
      cps_provider_1_insert_before([], v_12, v_6)
    case +v_17 <> v_18, 1n+v_19:
      v_17 <> cps_provider_1_insert_before(v_18, v_19, v_6)

def cps_provider_1_append_vals(v_2: List<&2, cps_provider_1_NfVal>, v_5: List<&2, cps_provider_1_NfVal>) -> List<&2, cps_provider_1_NfVal>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      v_10 <> cps_provider_1_append_vals(v_11, v_5)

def cps_provider_1_quantity_markers(v_1: Nat) -> List<&2, cps_provider_1_NfVal>:
  match v_1:
    case 0n:
      []
    case 1n+v_5:
      cps_provider_1_NfQuantity{BIR.Erased{}} <> cps_provider_1_quantity_markers(v_5)

def native_match_cps_provider_1_renamed_level_0(v_13: Bool, +v_4: Nat, v_10: Nat, v_11: List<&2, cps_provider_1_NfRenaming>) -> Nat:
  match v_13:
    case True{}:
      v_10
    case False{}:
      cps_provider_1_renamed_level(v_11, v_4)

def native_match_cps_provider_1_renamed_level_1(v_2: List<&2, cps_provider_1_NfRenaming>, +v_4: Nat) -> Nat:
  match v_2:
    case []:
      v_4
    case cps_provider_1_NfRenaming{v_9, v_10} <> v_11:
      native_match_cps_provider_1_renamed_level_0(Nat.is_eq(v_9, v_4), v_4, v_10, v_11)

def cps_provider_1_renamed_level(v_2: List<&2, cps_provider_1_NfRenaming>, +v_4: Nat) -> Nat:
  native_match_cps_provider_1_renamed_level_1(v_2, v_4)

def cps_provider_1_materialize_all_scoped(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_1_NfRenaming>) -> List<&2, BIR.Descriptor>:
  match v_2:
    case []:
      []
    case +v_11 <> v_12:
      cps_provider_1_materialize_scoped(v_11, v_4, v_7) <> cps_provider_1_materialize_all_scoped(v_12, v_4, v_7)

def cps_provider_1_materialize_all_at(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat) -> List<&2, BIR.Descriptor>:
  cps_provider_1_materialize_all_scoped(v_2, v_4, [])

def cps_provider_1_materialize_all(v_2: List<&2, cps_provider_1_NfVal>) -> List<&2, BIR.Descriptor>:
  cps_provider_1_materialize_all_at(v_2, 0n)

def cps_provider_1_materialize_scoped(v_1: cps_provider_1_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_1_NfRenaming>) -> BIR.Descriptor:
  match v_1:
    case cps_provider_1_NfType{v_9, v_10}:
      BIR.DescriptorRef{v_9, cps_provider_1_materialize_all_scoped(v_10, v_3, v_6)}
    case cps_provider_1_NfCtor{v_14, v_15}:
      BIR.DescriptorConstructor{v_14, cps_provider_1_materialize_all_scoped(v_15, v_3, v_6)}
    case cps_provider_1_NfQuantity{v_18}:
      BIR.DescriptorQuantity{v_18}
    case cps_provider_1_NfKind{v_20}:
      BIR.DescriptorKind{cps_provider_1_materialize_scoped(v_20, v_3, v_6)}
    case cps_provider_1_NfOther{v_23}:
      v_23
    case cps_provider_1_NfMissing{v_25}:
      v_25
    case cps_provider_1_NfBinder{v_27}:
      BIR.DescriptorParameter{Nat.sub(v_3, Nat.add(cps_provider_1_renamed_level(v_6, v_27), 1n))}
    case cps_provider_1_NfArrow{v_33, v_34, v_35, v_36}:
      BIR.DescriptorArrow{v_33, cps_provider_1_materialize_scoped(v_34, v_3, v_6), cps_provider_1_materialize_scoped(v_35, Nat.add(v_3, 1n), cps_provider_1_NfRenaming{v_36, v_3} <> v_6)}
    case cps_provider_1_NfClosure{v_42, v_43, v_44}:
      BIR.DescriptorLet{cps_provider_1_materialize_all_scoped(v_44, v_3, v_6), BIR.DescriptorLambda{v_42, v_43}}

def cps_provider_1_materialize_at(v_1: cps_provider_1_NfVal, +v_3: Nat) -> BIR.Descriptor:
  cps_provider_1_materialize_scoped(v_1, v_3, [])

def cps_provider_1_materialize(v_1: cps_provider_1_NfVal) -> BIR.Descriptor:
  cps_provider_1_materialize_at(v_1, 0n)

def cps_provider_1_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_1_NfVal>, +v_5: Nat) -> BIR.Descriptor:
  match v_3:
    case []:
      v_0
    case +v_8 <> v_9:
      BIR.DescriptorLet{cps_provider_1_materialize_all_at(v_3, v_5), v_0}

def cps_provider_1_status_combine(v_1: cps_provider_1_NfStatus, v_3: cps_provider_1_NfStatus) -> cps_provider_1_NfStatus:
  match v_1:
    case cps_provider_1_NfStatusNo{}:
      cps_provider_1_NfStatusNo{}
    case cps_provider_1_NfStatusMaybe{}:
      match v_3:
        case cps_provider_1_NfStatusNo{}:
          cps_provider_1_NfStatusNo{}
        case _:
          cps_provider_1_NfStatusMaybe{}
    case cps_provider_1_NfStatusOk{}:
      v_3

def native_match_cps_provider_1_bind_status_0(v_56: Bool, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_1_NfVal>, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_NfStatus:
  match v_56:
    case False{}:
      cps_provider_1_NfStatusNo{}
    case True{}:
      cps_provider_1_status_combine(cps_provider_1_bind_status(v_20, v_24), cps_provider_1_bind_status(v_11, v_13))

def native_match_cps_provider_1_bind_status_1(+v_12: cps_provider_1_NfVal, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_1_NfVal>, v_19: String, v_20: List<&2, BIR.DescriptorPattern>) -> cps_provider_1_NfStatus:
  match v_12:
    case cps_provider_1_NfCtor{v_23, v_24}:
      native_match_cps_provider_1_bind_status_0(String.eq(v_19, v_23), v_11, v_13, v_20, v_24)
    case cps_provider_1_NfMissing{v_29}:
      cps_provider_1_status_combine(cps_provider_1_NfStatusMaybe{}, cps_provider_1_bind_status(v_11, v_13))
    case cps_provider_1_NfOther{v_33}:
      cps_provider_1_status_combine(cps_provider_1_NfStatusMaybe{}, cps_provider_1_bind_status(v_11, v_13))
    case cps_provider_1_NfBinder{v_37}:
      cps_provider_1_status_combine(cps_provider_1_NfStatusMaybe{}, cps_provider_1_bind_status(v_11, v_13))
    case cps_provider_1_NfArrow{v_44, v_45, v_46, v_47}:
      cps_provider_1_status_combine(cps_provider_1_NfStatusMaybe{}, cps_provider_1_bind_status(v_11, v_13))
    case _:
      cps_provider_1_NfStatusNo{}

def native_match_cps_provider_1_bind_status_2(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, +v_12: cps_provider_1_NfVal, v_13: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_NfStatus:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      cps_provider_1_bind_status(v_11, v_13)
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      native_match_cps_provider_1_bind_status_1(v_12, v_11, v_13, v_19, v_20)

def native_match_cps_provider_1_bind_status_3(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_NfStatus:
  match v_1, v_4:
    case [], []:
      cps_provider_1_NfStatusOk{}
    case +v_10 <> v_11, +v_12 <> v_13:
      native_match_cps_provider_1_bind_status_2(v_10, v_11, v_12, v_13)
    case _, _:
      cps_provider_1_NfStatusNo{}

def cps_provider_1_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_NfStatus:
  native_match_cps_provider_1_bind_status_3(v_1, v_4)

def native_match_cps_provider_1_bind_values_0(+v_13: cps_provider_1_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_1_NfVal>, v_21: List<&2, BIR.DescriptorPattern>) -> List<&2, cps_provider_1_NfVal>:
  match v_13:
    case cps_provider_1_NfCtor{v_24, v_25}:
      cps_provider_1_append_vals(cps_provider_1_bind_values(v_21, v_25), cps_provider_1_bind_values(v_12, v_14))
    case _:
      cps_provider_1_bind_values(v_12, v_14)

def native_match_cps_provider_1_bind_values_1(+v_11: BIR.DescriptorPattern, v_12: List<&2, BIR.DescriptorPattern>, +v_13: cps_provider_1_NfVal, v_14: List<&2, cps_provider_1_NfVal>) -> List<&2, cps_provider_1_NfVal>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      v_13 <> cps_provider_1_bind_values(v_12, v_14)
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      native_match_cps_provider_1_bind_values_0(v_13, v_12, v_14, v_21)

def native_match_cps_provider_1_bind_values_2(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> List<&2, cps_provider_1_NfVal>:
  match v_1, v_4:
    case [], []:
      []
    case +v_11 <> v_12, +v_13 <> v_14:
      native_match_cps_provider_1_bind_values_1(v_11, v_12, v_13, v_14)
    case _, _:
      []

def cps_provider_1_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> List<&2, cps_provider_1_NfVal>:
  native_match_cps_provider_1_bind_values_2(v_1, v_4)

def native_match_cps_provider_1_bind_patterns_0(v_5: cps_provider_1_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_NfBind:
  match v_5:
    case cps_provider_1_NfStatusOk{}:
      cps_provider_1_NfBound{cps_provider_1_bind_values(v_1, v_4)}
    case cps_provider_1_NfStatusNo{}:
      cps_provider_1_NfMismatch{}
    case cps_provider_1_NfStatusMaybe{}:
      cps_provider_1_NfUnknown{}

def cps_provider_1_bind_patterns(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_NfBind:
  native_match_cps_provider_1_bind_patterns_0(cps_provider_1_bind_status(v_1, v_4), v_1, v_4)

def native_match_cps_provider_1_nf_0(v_10: Bool, +v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  match v_10:
    case True{}:
      cps_provider_1_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_1_nf_descriptor(v_1, v_2, v_5, v_7, Nat.sub(v_9, 1n))

def cps_provider_1_nf(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_cps_provider_1_nf_descriptor_0(v_10: Bool, +v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  match v_10:
    case True{}:
      cps_provider_1_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_1_nf_descriptor_step(v_1, v_2, v_5, v_7, v_9)

def cps_provider_1_nf_descriptor(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_descriptor_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_cps_provider_1_nf_arrow_0(v_25: cps_provider_1_Nf, v_2: BIR.Quantity, +v_9: Nat, v_17: cps_provider_1_NfVal) -> cps_provider_1_Nf:
  match v_25:
    case cps_provider_1_NfFail{v_21}:
      cps_provider_1_NfFail{v_21}
    case cps_provider_1_NfOk{v_23}:
      cps_provider_1_NfOk{cps_provider_1_NfArrow{v_2, v_17, v_23, v_9}}

def native_match_cps_provider_1_nf_arrow_1(v_24: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_2: BIR.Quantity, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_1_Nf:
  match v_24:
    case cps_provider_1_NfFail{v_15}:
      cps_provider_1_NfFail{v_15}
    case cps_provider_1_NfOk{v_17}:
      native_match_cps_provider_1_nf_arrow_0(cps_provider_1_nf(v_1, v_4, List.append(&2, cps_provider_1_NfVal, v_7, [cps_provider_1_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11), v_2, v_9, v_17)

def cps_provider_1_nf_arrow(+v_1: cps_provider_1_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_arrow_1(cps_provider_1_nf(v_1, v_3, v_7, v_9, v_11), v_1, v_2, v_4, v_7, v_9, v_11)

def native_match_cps_provider_1_nf_descriptor_step_0(v_191: cps_provider_1_Nf) -> cps_provider_1_Nf:
  match v_191:
    case cps_provider_1_NfOk{v_24}:
      cps_provider_1_NfOk{cps_provider_1_NfKind{v_24}}
    case cps_provider_1_NfFail{v_26}:
      cps_provider_1_NfFail{v_26}

def native_match_cps_provider_1_nf_descriptor_step_1(v_192: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, +v_7: Nat, +v_9: Nat, v_45: String) -> cps_provider_1_Nf:
  match v_192:
    case cps_provider_1_NfListOk{v_49}:
      cps_provider_1_nf_named(v_1, v_45, v_49, v_7, v_9)
    case cps_provider_1_NfListFail{v_52}:
      cps_provider_1_NfFail{v_52}

def native_match_cps_provider_1_nf_descriptor_step_2(v_193: cps_provider_1_NfList, v_55: String) -> cps_provider_1_Nf:
  match v_193:
    case cps_provider_1_NfListOk{v_59}:
      cps_provider_1_NfOk{cps_provider_1_NfCtor{v_55, v_59}}
    case cps_provider_1_NfListFail{v_61}:
      cps_provider_1_NfFail{v_61}

def native_match_cps_provider_1_nf_descriptor_step_3(v_195: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, +v_7: Nat, +v_9: Nat, v_68: cps_provider_1_NfVal) -> cps_provider_1_Nf:
  match v_195:
    case cps_provider_1_NfOk{v_71}:
      cps_provider_1_nf_apply(v_1, v_68, [v_71], v_7, v_9)
    case cps_provider_1_NfFail{v_74}:
      cps_provider_1_NfFail{v_74}

def native_match_cps_provider_1_nf_descriptor_step_4(v_194: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, v_65: BIR.Descriptor) -> cps_provider_1_Nf:
  match v_194:
    case cps_provider_1_NfOk{v_68}:
      native_match_cps_provider_1_nf_descriptor_step_3(cps_provider_1_nf(v_1, v_65, v_5, v_7, v_9), v_1, v_7, v_9, v_68)
    case cps_provider_1_NfFail{v_76}:
      cps_provider_1_NfFail{v_76}

def native_match_cps_provider_1_nf_descriptor_step_5(v_196: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, v_80: Nat, v_82: BIR.Descriptor) -> cps_provider_1_Nf:
  match v_196:
    case cps_provider_1_NfOk{v_85}:
      cps_provider_1_nf_descriptor(v_1, v_82, cps_provider_1_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_1_NfVal, v_5), v_80), v_85), v_7, Nat.sub(v_9, 1n))
    case cps_provider_1_NfFail{v_90}:
      cps_provider_1_NfFail{v_90}

def native_match_cps_provider_1_nf_descriptor_step_6(v_197: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, v_94: BIR.Descriptor) -> cps_provider_1_Nf:
  match v_197:
    case cps_provider_1_NfListOk{v_97}:
      cps_provider_1_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_1_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n))
    case cps_provider_1_NfListFail{v_101}:
      cps_provider_1_NfFail{v_101}

def native_match_cps_provider_1_nf_descriptor_step_7(v_199: cps_provider_1_NfBind, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_107: BIR.Descriptor) -> cps_provider_1_Nf:
  match v_199:
    case cps_provider_1_NfBound{v_113}:
      cps_provider_1_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_1_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n))
    case _:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_12, v_5, v_7)}}

def native_match_cps_provider_1_nf_descriptor_step_8(v_198: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_105: List<&2, BIR.DescriptorPattern>, v_107: BIR.Descriptor) -> cps_provider_1_Nf:
  match v_198:
    case cps_provider_1_NfListOk{v_110}:
      native_match_cps_provider_1_nf_descriptor_step_7(cps_provider_1_bind_patterns(v_105, v_110), v_1, v_5, v_7, v_9, v_12, v_107)
    case cps_provider_1_NfListFail{v_120}:
      cps_provider_1_NfFail{v_120}

def native_match_cps_provider_1_nf_descriptor_step_9(v_200: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_124: List<&2, BIR.Descriptor>) -> cps_provider_1_Nf:
  match v_200:
    case cps_provider_1_NfListOk{v_127}:
      cps_provider_1_nf_cases(v_1, v_124, v_127, v_5, v_12, v_7, v_9)
    case cps_provider_1_NfListFail{v_130}:
      cps_provider_1_NfFail{v_130}

def native_match_cps_provider_1_nf_descriptor_step_10(v_201: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, v_139: BIR.Descriptor) -> cps_provider_1_Nf:
  match v_201:
    case cps_provider_1_NfOk{v_142}:
      cps_provider_1_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_1_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_1_NfFail{v_146}:
      cps_provider_1_NfFail{v_146}

def native_match_cps_provider_1_nf_descriptor_step_11(v_202: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, +v_7: Nat, +v_9: Nat, v_170: String) -> cps_provider_1_Nf:
  match v_202:
    case cps_provider_1_NfListOk{v_175}:
      cps_provider_1_nf_named(v_1, v_170, v_175, v_7, v_9)
    case cps_provider_1_NfListFail{v_178}:
      cps_provider_1_NfFail{v_178}

def native_match_cps_provider_1_nf_descriptor_step_12(v_203: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, +v_7: Nat, +v_9: Nat, v_182: String) -> cps_provider_1_Nf:
  match v_203:
    case cps_provider_1_NfListOk{v_187}:
      cps_provider_1_nf_named(v_1, v_182, v_187, v_7, v_9)
    case cps_provider_1_NfListFail{v_190}:
      cps_provider_1_NfFail{v_190}

def native_match_cps_provider_1_nf_descriptor_step_13(+v_12: BIR.Descriptor, +v_1: cps_provider_1_NfContext, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  match v_12:
    case BIR.DescriptorNull{}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorParameter{v_15}:
      cps_provider_1_NfOk{cps_provider_1_val_at(v_5, v_15, v_12)}
    case BIR.DescriptorQuantityKind{}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorQuantity{v_19}:
      cps_provider_1_NfOk{cps_provider_1_NfQuantity{v_19}}
    case BIR.DescriptorKind{v_21}:
      native_match_cps_provider_1_nf_descriptor_step_0(cps_provider_1_nf(v_1, v_21, v_5, v_7, v_9))
    case BIR.DescriptorMinimum{v_29, v_30}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorArrow{v_35, v_36, v_37}:
      cps_provider_1_nf_arrow(v_1, v_35, v_36, v_37, v_5, v_7, v_9)
    case BIR.DescriptorLambda{v_41, v_42}:
      cps_provider_1_NfOk{cps_provider_1_NfClosure{v_41, v_42, v_5}}
    case BIR.DescriptorRef{v_45, v_46}:
      native_match_cps_provider_1_nf_descriptor_step_1(cps_provider_1_nf_all(v_1, v_46, v_5, v_7, v_9), v_1, v_7, v_9, v_45)
    case BIR.DescriptorConstructor{v_55, v_56}:
      native_match_cps_provider_1_nf_descriptor_step_2(cps_provider_1_nf_all(v_1, v_56, v_5, v_7, v_9), v_55)
    case BIR.DescriptorApplication{v_64, v_65}:
      native_match_cps_provider_1_nf_descriptor_step_4(cps_provider_1_nf(v_1, v_64, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_65)
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      native_match_cps_provider_1_nf_descriptor_step_5(cps_provider_1_nf(v_1, v_81, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_80, v_82)
    case BIR.DescriptorLet{v_93, v_94}:
      native_match_cps_provider_1_nf_descriptor_step_6(cps_provider_1_nf_all(v_1, v_93, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_94)
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      native_match_cps_provider_1_nf_descriptor_step_8(cps_provider_1_nf_all(v_1, v_106, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_105, v_107)
    case BIR.DescriptorMatch{v_123, v_124}:
      native_match_cps_provider_1_nf_descriptor_step_9(cps_provider_1_nf_all(v_1, v_123, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_124)
    case BIR.DescriptorCase{v_133, v_134}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorBind{v_138, v_139}:
      native_match_cps_provider_1_nf_descriptor_step_10(cps_provider_1_nf(v_1, v_138, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_139)
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorReflexivity{}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorFailure{v_156}:
      cps_provider_1_NfFail{v_156}
    case BIR.DescriptorFill{v_159, v_160}:
      cps_provider_1_nf_apply_args(v_1, v_159, v_160, v_5, v_12, v_7, v_9)
    case BIR.DescriptorPlus{v_164, v_165}:
      cps_provider_1_nf_apply_args(v_1, v_164, v_165, v_5, v_12, v_7, v_9)
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      native_match_cps_provider_1_nf_descriptor_step_11(cps_provider_1_nf_all(v_1, v_172, v_5, v_7, v_9), v_1, v_7, v_9, v_170)
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      native_match_cps_provider_1_nf_descriptor_step_12(cps_provider_1_nf_all(v_1, v_184, v_5, v_7, v_9), v_1, v_7, v_9, v_182)

def cps_provider_1_nf_descriptor_step(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  +v_12 = v_2
  native_match_cps_provider_1_nf_descriptor_step_13(v_12, v_1, v_5, v_7, v_9)

def native_match_cps_provider_1_nf_all_0(v_27: cps_provider_1_NfList, v_20: cps_provider_1_NfVal) -> cps_provider_1_NfList:
  match v_27:
    case cps_provider_1_NfListFail{v_23}:
      cps_provider_1_NfListFail{v_23}
    case cps_provider_1_NfListOk{v_25}:
      cps_provider_1_NfListOk{v_20 <> v_25}

def native_match_cps_provider_1_nf_all_1(v_26: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, +v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat, v_15: List<&2, BIR.Descriptor>) -> cps_provider_1_NfList:
  match v_26:
    case cps_provider_1_NfFail{v_18}:
      cps_provider_1_NfListFail{v_18}
    case cps_provider_1_NfOk{v_20}:
      native_match_cps_provider_1_nf_all_0(cps_provider_1_nf_all(v_1, v_15, v_6, v_8, v_10), v_20)

def native_match_cps_provider_1_nf_all_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_1_NfContext, +v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_1_NfList:
  match v_3:
    case []:
      cps_provider_1_NfListOk{[]}
    case +v_14 <> v_15:
      native_match_cps_provider_1_nf_all_1(cps_provider_1_nf(v_1, v_14, v_6, v_8, v_10), v_1, v_6, v_8, v_10, v_15)

def cps_provider_1_nf_all(+v_1: cps_provider_1_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_1_NfList:
  native_match_cps_provider_1_nf_all_2(v_3, v_1, v_6, v_8, v_10)

def native_match_cps_provider_1_nf_apply_args_0(v_25: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat, v_18: cps_provider_1_NfVal) -> cps_provider_1_Nf:
  match v_25:
    case cps_provider_1_NfListFail{v_21}:
      cps_provider_1_NfFail{v_21}
    case cps_provider_1_NfListOk{v_23}:
      cps_provider_1_nf_apply_source(v_1, v_18, v_23, v_8, v_10, v_12)

def native_match_cps_provider_1_nf_apply_args_1(v_24: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_1_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> cps_provider_1_Nf:
  match v_24:
    case cps_provider_1_NfFail{v_16}:
      cps_provider_1_NfFail{v_16}
    case cps_provider_1_NfOk{v_18}:
      native_match_cps_provider_1_nf_apply_args_0(cps_provider_1_nf_all(v_1, v_4, v_7, v_10, v_12), v_1, v_8, v_10, v_12, v_18)

def cps_provider_1_nf_apply_args(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_1_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_apply_args_1(cps_provider_1_nf(v_1, v_2, v_7, v_10, v_12), v_1, v_4, v_7, v_8, v_10, v_12)

def cps_provider_1_nf_apply_source(+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, v_6: List<&2, cps_provider_1_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat) -> cps_provider_1_Nf:
  match v_6:
    case []:
      cps_provider_1_NfOk{v_3}
    case _:
      cps_provider_1_nf_apply(v_1, v_3, v_6, v_9, v_11)

def native_match_cps_provider_1_nf_apply_0(v_21: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, +v_8: Nat, +v_10: Nat, v_15: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_Nf:
  match v_21:
    case cps_provider_1_NfFail{v_18}:
      cps_provider_1_NfFail{v_18}
    case cps_provider_1_NfOk{v_20}:
      cps_provider_1_nf_apply(v_1, v_20, v_15, v_8, Nat.sub(v_10, 1n))

def native_match_cps_provider_1_nf_apply_1(v_6: List<&2, cps_provider_1_NfVal>, +v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, +v_8: Nat, +v_10: Nat) -> cps_provider_1_Nf:
  match v_6:
    case []:
      cps_provider_1_NfOk{v_3}
    case +v_14 <> v_15:
      native_match_cps_provider_1_nf_apply_0(cps_provider_1_nf_apply_one(v_1, v_3, v_14, v_8, Nat.sub(v_10, 1n)), v_1, v_8, v_10, v_15)

def cps_provider_1_nf_apply(+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_apply_1(v_6, v_1, v_3, v_8, v_10)

def cps_provider_1_nf_apply_one(+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, v_5: cps_provider_1_NfVal, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  match v_3:
    case cps_provider_1_NfType{v_13, v_14}:
      cps_provider_1_nf_named(v_1, v_13, List.append(&2, cps_provider_1_NfVal, v_14, [v_5]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_1_NfClosure{v_20, v_21, v_22}:
      cps_provider_1_nf_descriptor(v_1, v_21, List.append(&2, cps_provider_1_NfVal, v_22, [v_5]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_1_NfCtor{v_27, v_28}:
      cps_provider_1_NfFail{String.append("the constructor `", String.append(v_27, "` is applied to an argument"))}
    case cps_provider_1_NfQuantity{v_30}:
      cps_provider_1_NfFail{"a quantity is applied to an argument"}
    case cps_provider_1_NfKind{v_32}:
      cps_provider_1_NfFail{"a kind is applied to an argument"}
    case cps_provider_1_NfOther{v_34}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{BIR.DescriptorApplication{v_34, cps_provider_1_materialize_at(v_5, v_7)}}}
    case cps_provider_1_NfArrow{v_40, v_41, v_42, v_43}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{BIR.DescriptorApplication{cps_provider_1_materialize_at(v_3, v_7), cps_provider_1_materialize_at(v_5, v_7)}}}
    case cps_provider_1_NfMissing{v_47}:
      cps_provider_1_NfOk{cps_provider_1_NfMissing{BIR.DescriptorApplication{v_47, cps_provider_1_materialize_at(v_5, v_7)}}}
    case cps_provider_1_NfBinder{v_50}:
      cps_provider_1_NfOk{cps_provider_1_NfMissing{BIR.DescriptorApplication{cps_provider_1_materialize_at(v_3, v_7), cps_provider_1_materialize_at(v_5, v_7)}}}

def cps_provider_1_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      match v_8:
        case Some{"IO"}:
          True{}
        case _:
          False{}

def cps_provider_1_nf_named_io(v_1: Bool, +v_3: cps_provider_1_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_1_Nf:
  match v_1:
    case True{}:
      match v_4:
        case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
          cps_provider_1_NfOk{cps_provider_1_NfType{v_18, v_7}}
    case False{}:
      cps_provider_1_nf_reduce(v_3, v_4, v_7, v_9, Nat.sub(v_11, 1n))

def native_match_cps_provider_1_nf_named_0(v_27: Maybe<&2, BIR.Family>, +v_3: String, v_6: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_Nf:
  match v_27:
    case Some{v_25}:
      cps_provider_1_nf_family(v_25, v_6)
    case None{}:
      cps_provider_1_NfOk{cps_provider_1_NfType{v_3, v_6}}

def native_match_cps_provider_1_nf_named_1(v_26: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_1_NfContext, +v_3: String, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat, v_14: Map<&2, BIR.Family>) -> cps_provider_1_Nf:
  match v_26:
    case Some{v_18}:
      +v_20 = v_18
      cps_provider_1_nf_named_io(cps_provider_1_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10)
    case None{}:
      native_match_cps_provider_1_nf_named_0(cps_provider_1_family_of(v_3, v_14), v_3, v_6)

def native_match_cps_provider_1_nf_named_2(+v_1: cps_provider_1_NfContext, +v_3: String, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_1_Nf:
  match v_1:
    case cps_provider_1_NfContext{v_14, v_15}:
      native_match_cps_provider_1_nf_named_1(cps_provider_1_function_of(v_3, v_15), v_1, v_3, v_6, v_8, v_10, v_14)

def cps_provider_1_nf_named(+v_1: cps_provider_1_NfContext, +v_3: String, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_named_2(v_1, v_3, v_6, v_8, v_10)

def cps_provider_1_nf_arity(+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, +v_6: Nat) -> cps_provider_1_NfArity:
  cps_provider_1_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_1_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_1_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_1_NfVal, v_2), v_6)}

def native_match_cps_provider_1_nf_family_0(v_0: BIR.Family, +v_6: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_Nf:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      cps_provider_1_nf_family_apply(cps_provider_1_nf_arity(v_6, v_20, v_17), v_13, v_20, v_6)

def cps_provider_1_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_Nf:
  +v_6 = v_3
  native_match_cps_provider_1_nf_family_0(v_0, v_6)

def cps_provider_1_nf_family_apply(v_1: cps_provider_1_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_Nf:
  match v_1:
    case cps_provider_1_NfArity{v_13, v_14, v_15}:
      match v_13:
        case True{}:
          cps_provider_1_NfOk{cps_provider_1_NfType{v_3, List.append(&2, cps_provider_1_NfVal, cps_provider_1_quantity_markers(v_5), v_8)}}
        case False{}:
          match v_14:
            case True{}:
              cps_provider_1_NfOk{cps_provider_1_NfType{v_3, v_8}}
            case False{}:
              match v_15:
                case True{}:
                  cps_provider_1_NfOk{cps_provider_1_NfType{v_3, v_8}}
                case False{}:
                  cps_provider_1_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}

def native_match_cps_provider_1_nf_reduce_0(v_2: BIR.TypeFunction, +v_1: cps_provider_1_NfContext, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NfVal>) -> cps_provider_1_Nf:
  match v_2:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      +v_24 = v_20
      +v_26 = v_21
      cps_provider_1_nf_reduce_apply(cps_provider_1_nf_arity(v_12, v_24, v_26), v_1, v_18, v_24, v_26, v_22, v_12, v_7, v_9)

def cps_provider_1_nf_reduce(+v_1: cps_provider_1_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_1_Nf:
  +v_12 = v_5
  native_match_cps_provider_1_nf_reduce_0(v_2, v_1, v_7, v_9, v_12)

def cps_provider_1_nf_reduce_apply(v_1: cps_provider_1_NfArity, +v_3: cps_provider_1_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_1_NfVal>, +v_15: Nat, +v_17: Nat) -> cps_provider_1_Nf:
  match v_1:
    case cps_provider_1_NfArity{v_22, v_23, v_24}:
      match v_22:
        case True{}:
          cps_provider_1_nf_reduce_body(v_3, v_10, List.append(&2, cps_provider_1_NfVal, cps_provider_1_quantity_markers(v_7), v_13), [], v_15, Nat.sub(v_17, 1n))
        case False{}:
          match v_23:
            case True{}:
              cps_provider_1_nf_reduce_body(v_3, v_10, cps_provider_1_first_vals(v_13, v_9), cps_provider_1_drop_vals(v_13, v_9), v_15, Nat.sub(v_17, 1n))
            case False{}:
              match v_24:
                case True{}:
                  cps_provider_1_NfOk{cps_provider_1_NfType{v_5, v_13}}
                case False{}:
                  cps_provider_1_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}

def native_match_cps_provider_1_nf_reduce_body_0(v_19: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_8: List<&2, cps_provider_1_NfVal>, +v_10: Nat, +v_12: Nat) -> cps_provider_1_Nf:
  match v_19:
    case cps_provider_1_NfFail{v_16}:
      cps_provider_1_NfFail{v_16}
    case cps_provider_1_NfOk{v_18}:
      cps_provider_1_nf_apply(v_1, v_18, v_8, v_10, v_12)

def cps_provider_1_nf_reduce_body(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, v_8: List<&2, cps_provider_1_NfVal>, +v_10: Nat, +v_12: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_reduce_body_0(cps_provider_1_nf_descriptor(v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)), v_1, v_8, v_10, v_12)

def native_match_cps_provider_1_nf_cases_0(v_36: cps_provider_1_NfBind, +v_1: cps_provider_1_NfContext, +v_6: List<&2, cps_provider_1_NfVal>, +v_9: List<&2, cps_provider_1_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, v_24: BIR.Descriptor) -> cps_provider_1_Nf:
  match v_36:
    case cps_provider_1_NfBound{v_27}:
      cps_provider_1_nf_descriptor(v_1, v_24, List.append(&2, cps_provider_1_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n))
    case cps_provider_1_NfMismatch{}:
      cps_provider_1_nf_cases(v_1, v_20, v_6, v_9, v_10, v_12, v_14)
    case cps_provider_1_NfUnknown{}:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_10, v_9, v_12)}}

def native_match_cps_provider_1_nf_cases_1(+v_19: BIR.Descriptor, +v_1: cps_provider_1_NfContext, +v_6: List<&2, cps_provider_1_NfVal>, +v_9: List<&2, cps_provider_1_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>) -> cps_provider_1_Nf:
  match v_19:
    case BIR.DescriptorCase{v_23, v_24}:
      native_match_cps_provider_1_nf_cases_0(cps_provider_1_bind_patterns(v_23, v_6), v_1, v_6, v_9, v_10, v_12, v_14, v_20, v_24)
    case BIR.DescriptorFailure{v_33}:
      cps_provider_1_NfFail{v_33}
    case _:
      cps_provider_1_NfFail{"descriptor match case is not a case"}

def native_match_cps_provider_1_nf_cases_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_1_NfContext, +v_6: List<&2, cps_provider_1_NfVal>, +v_9: List<&2, cps_provider_1_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> cps_provider_1_Nf:
  match v_3:
    case []:
      cps_provider_1_NfOk{cps_provider_1_NfOther{cps_provider_1_reify_env(v_10, v_9, v_12)}}
    case +v_19 <> v_20:
      native_match_cps_provider_1_nf_cases_1(v_19, v_1, v_6, v_9, v_10, v_12, v_14, v_20)

def cps_provider_1_nf_cases(+v_1: cps_provider_1_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, +v_9: List<&2, cps_provider_1_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> cps_provider_1_Nf:
  native_match_cps_provider_1_nf_cases_2(v_3, v_1, v_6, v_9, v_10, v_12, v_14)

def native_match_cps_provider_1_normalize_0(v_13: cps_provider_1_Nf) -> BIR.Descriptor:
  match v_13:
    case cps_provider_1_NfFail{v_10}:
      BIR.DescriptorFailure{v_10}
    case cps_provider_1_NfOk{v_12}:
      cps_provider_1_materialize_at(v_12, 0n)

def cps_provider_1_normalize(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat) -> BIR.Descriptor:
  native_match_cps_provider_1_normalize_0(cps_provider_1_nf(v_1, v_2, v_5, 0n, v_7))

def cps_provider_1_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_1_normalize(cps_provider_1_nf_context(v_1, v_3), v_4, [], 1024n)

def cps_provider_1_normalize_in(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_1_normalize(v_1, v_2, [], 1024n)

def cps_provider_1_outer_application(+v_0: BIR.Descriptor) -> Maybe<&2, cps_provider_1_NfApp>:
  cps_provider_1_outer_walk(v_0, [])

def cps_provider_1_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> Maybe<&2, cps_provider_1_NfApp>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      Some{cps_provider_1_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      Some{cps_provider_1_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      Some{cps_provider_1_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}
    case BIR.DescriptorFill{v_23, v_24}:
      cps_provider_1_outer_walk(v_23, List.append(&2, BIR.Descriptor, v_24, v_2))
    case BIR.DescriptorPlus{v_28, v_29}:
      cps_provider_1_outer_walk(v_28, List.append(&2, BIR.Descriptor, v_29, v_2))
    case BIR.DescriptorApplication{v_33, v_34}:
      cps_provider_1_outer_walk(v_33, List.append(&2, BIR.Descriptor, [v_34], v_2))
    case _:
      None{}

def native_match_cps_provider_1_answer_in_0(v_5: BIR.Descriptor, +v_1: cps_provider_1_NfContext) -> BIR.Descriptor:
  match v_5:
    case BIR.DescriptorFailure{_}:
      v_5
    case _:
      cps_provider_1_answer_normalized(v_1, v_5)

def cps_provider_1_answer_in(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  v_5 = cps_provider_1_normalize(v_1, v_2, [], 1024n)
  native_match_cps_provider_1_answer_in_0(v_5, v_1)

def cps_provider_1_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  cps_provider_1_answer_in(cps_provider_1_nf_context(v_2, v_4), v_0)

def native_match_cps_provider_1_answer_normalized_0(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_9:
    case []:
      v_2
    case +v_13 <> v_14:
      v_13

def native_match_cps_provider_1_answer_normalized_1(v_16: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  match v_16:
    case False{}:
      v_2
    case True{}:
      native_match_cps_provider_1_answer_normalized_0(v_9, v_2)

def native_match_cps_provider_1_answer_normalized_2(v_5: cps_provider_1_NfApp, +v_1: cps_provider_1_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_5:
    case cps_provider_1_NfApp{v_8, v_9}:
      native_match_cps_provider_1_answer_normalized_1(cps_provider_1_is_io_head_in(v_1, v_8), v_2, v_9)

def native_match_cps_provider_1_answer_normalized_3(v_15: Maybe<&2, cps_provider_1_NfApp>, +v_1: cps_provider_1_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_15:
    case None{}:
      v_2
    case Some{v_5}:
      native_match_cps_provider_1_answer_normalized_2(v_5, v_1, v_2)

def cps_provider_1_answer_normalized(+v_1: cps_provider_1_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  native_match_cps_provider_1_answer_normalized_3(cps_provider_1_outer_application(v_2), v_1, v_2)

def cps_provider_1_is_io_head_in(+v_1: cps_provider_1_NfContext, +v_3: String) -> Bool:
  match v_1:
    case cps_provider_1_NfContext{v_7, v_8}:
      cps_provider_1_is_io_head(v_3, v_7, v_8)

def native_match_cps_provider_1_is_io_head_0(v_10: Maybe<&2, String>) -> Bool:
  match v_10:
    case Some{v_9}:
      String.eq(v_9, "IO")
    case None{}:
      False{}

def cps_provider_1_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Bool:
  native_match_cps_provider_1_is_io_head_0(cps_provider_1_native_of(v_1, v_3, v_5))

