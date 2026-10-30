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


# Bounded typed request groups; every source declaration retains its checked signature.
type TemplateRequestGroup0 is Type:
  TemplateRequest_smoke_families{}
  TemplateRequest_smoke_functions{}
  TemplateRequest_is_nat{v_0: BIR.Descriptor}
  TemplateRequest_is_failure_with{v_0: BIR.Descriptor, v_2: String}
  TemplateRequest_is_bool{v_0: BIR.Descriptor}
  TemplateRequest_is_arrow_nat{v_0: BIR.Descriptor}
  TemplateRequest_is_arrow_bound{v_0: BIR.Descriptor}
  TemplateRequest_is_arrow_nest{v_0: BIR.Descriptor}
  TemplateRequest_is_scoped_let_arrow{v_0: BIR.Descriptor}
  TemplateRequest_is_relocated_arrow{v_0: BIR.Descriptor, v_2: Nat}
  TemplateRequest_is_nat_ref{v_0: BIR.Descriptor}
  TemplateRequest_is_maybe_nat{v_0: BIR.Descriptor}
  TemplateRequest_is_io_maybe_nat{v_0: BIR.Descriptor}
  TemplateRequest_is_event_list{v_0: BIR.Descriptor}
  TemplateRequest_is_app_tick{v_0: BIR.Descriptor}
  TemplateRequest_is_match_source{v_0: BIR.Descriptor}
  TemplateRequest_is_failure{v_0: BIR.Descriptor}
  TemplateRequest_is_application{v_0: BIR.Descriptor}
  TemplateRequest_is_quantity_head{v_0: BIR.Descriptor}
  TemplateRequest_is_parameter{v_0: BIR.Descriptor}
  TemplateRequest_is_chan{v_0: BIR.Descriptor}
  TemplateRequest_is_under_applied_head{v_0: BIR.Descriptor}
  TemplateRequest_equal_args{v_1: List<&2, BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>}
  TemplateRequest_outer_is{v_2: Maybe<&2, cps_provider_1_NfApp>, v_4: List<&2, BIR.Descriptor>}
  TemplateRequest_bit{v_1: Bool}
  TemplateRequest_main{v_1: List<&2, Loader.LoadedModule>}
  TemplateRequest_cps_provider_1_family_index{v_1: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_1_function_index{v_1: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_1_nf_context{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_1_default_fuel{}
  TemplateRequest_cps_provider_1_family_of{+v_1: String, +v_3: Map<&2, BIR.Family>}
  TemplateRequest_cps_provider_1_function_of{+v_1: String, +v_3: Map<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_1_native_of{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_1_val_nth{+v_2: List<&2, cps_provider_1_NfVal>, v_4: Nat}
  TemplateRequest_cps_provider_1_val_at{+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, v_5: BIR.Descriptor}
  TemplateRequest_cps_provider_1_val_at_choose{v_1: Bool, +v_4: List<&2, cps_provider_1_NfVal>, +v_6: Nat, v_7: BIR.Descriptor}
  TemplateRequest_cps_provider_1_first_vals{v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_1_drop_vals{v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_1_insert_before{v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, v_6: cps_provider_1_NfVal}
  TemplateRequest_cps_provider_1_append_vals{v_2: List<&2, cps_provider_1_NfVal>, v_5: List<&2, cps_provider_1_NfVal>}
  TemplateRequest_cps_provider_1_quantity_markers{v_1: Nat}
  TemplateRequest_cps_provider_1_renamed_level{v_2: List<&2, cps_provider_1_NfRenaming>, +v_4: Nat}
  TemplateRequest_cps_provider_1_materialize_all_scoped{v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_1_NfRenaming>}
  TemplateRequest_cps_provider_1_materialize_all_at{v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_1_materialize_all{v_2: List<&2, cps_provider_1_NfVal>}
  TemplateRequest_cps_provider_1_materialize_scoped{v_1: cps_provider_1_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_1_NfRenaming>}
  TemplateRequest_cps_provider_1_materialize_at{v_1: cps_provider_1_NfVal, +v_3: Nat}
  TemplateRequest_cps_provider_1_materialize{v_1: cps_provider_1_NfVal}
  TemplateRequest_cps_provider_1_reify_env{v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_1_NfVal>, +v_5: Nat}
  TemplateRequest_cps_provider_1_status_combine{v_1: cps_provider_1_NfStatus, v_3: cps_provider_1_NfStatus}
  TemplateRequest_cps_provider_1_bind_status{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>}
  TemplateRequest_cps_provider_1_bind_values{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>}
  TemplateRequest_cps_provider_1_bind_patterns{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>}
  TemplateRequest_cps_provider_1_nf{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_1_nf_descriptor{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_1_nf_arrow{+v_1: cps_provider_1_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_1_nf_descriptor_step{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_1_nf_all{+v_1: cps_provider_1_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_1_nf_apply_args{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_1_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat}
  TemplateRequest_cps_provider_1_nf_apply_source{+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, v_6: List<&2, cps_provider_1_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_1_nf_apply{+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_1_nf_apply_one{+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, v_5: cps_provider_1_NfVal, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_1_intrinsic_io{+v_0: BIR.TypeFunction}
  TemplateRequest_cps_provider_1_nf_named_io{v_1: Bool, +v_3: cps_provider_1_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat}

type TemplateRequestGroup1 is Type:
  TemplateRequest_cps_provider_1_nf_named{+v_1: cps_provider_1_NfContext, +v_3: String, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_1_nf_arity{+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, +v_6: Nat}
  TemplateRequest_cps_provider_1_nf_family{v_0: BIR.Family, v_3: List<&2, cps_provider_1_NfVal>}
  TemplateRequest_cps_provider_1_nf_family_apply{v_1: cps_provider_1_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_1_NfVal>}
  TemplateRequest_cps_provider_1_nf_reduce{+v_1: cps_provider_1_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_1_nf_reduce_apply{v_1: cps_provider_1_NfArity, +v_3: cps_provider_1_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_1_NfVal>, +v_15: Nat, +v_17: Nat}
  TemplateRequest_cps_provider_1_nf_reduce_body{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, v_8: List<&2, cps_provider_1_NfVal>, +v_10: Nat, +v_12: Nat}
  TemplateRequest_cps_provider_1_nf_cases{+v_1: cps_provider_1_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, +v_9: List<&2, cps_provider_1_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat}
  TemplateRequest_cps_provider_1_normalize{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_1_normalize_closed{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor}
  TemplateRequest_cps_provider_1_normalize_in{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_outer_application{+v_0: BIR.Descriptor}
  TemplateRequest_cps_provider_1_outer_walk{+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>}
  TemplateRequest_cps_provider_1_answer_in{+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_answer_descriptor{v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_1_answer_normalized{+v_1: cps_provider_1_NfContext, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_is_io_head_in{+v_1: cps_provider_1_NfContext, +v_3: String}
  TemplateRequest_cps_provider_1_is_io_head{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}

type TemplateRequest is Type:
  TemplateRequestGroup_0{request: TemplateRequestGroup0}
  TemplateRequestGroup_1{request: TemplateRequestGroup1}

def template_result_group_0(request: TemplateRequestGroup0) -> Data:
  match request:
    case TemplateRequest_smoke_families{}: List<&2, BIR.Family>
    case TemplateRequest_smoke_functions{}: List<&2, BIR.TypeFunction>
    case TemplateRequest_is_nat{_}: Bool
    case TemplateRequest_is_failure_with{_, _}: Bool
    case TemplateRequest_is_bool{_}: Bool
    case TemplateRequest_is_arrow_nat{_}: Bool
    case TemplateRequest_is_arrow_bound{_}: Bool
    case TemplateRequest_is_arrow_nest{_}: Bool
    case TemplateRequest_is_scoped_let_arrow{_}: Bool
    case TemplateRequest_is_relocated_arrow{_, _}: Bool
    case TemplateRequest_is_nat_ref{_}: Bool
    case TemplateRequest_is_maybe_nat{_}: Bool
    case TemplateRequest_is_io_maybe_nat{_}: Bool
    case TemplateRequest_is_event_list{_}: Bool
    case TemplateRequest_is_app_tick{_}: Bool
    case TemplateRequest_is_match_source{_}: Bool
    case TemplateRequest_is_failure{_}: Bool
    case TemplateRequest_is_application{_}: Bool
    case TemplateRequest_is_quantity_head{_}: Bool
    case TemplateRequest_is_parameter{_}: Bool
    case TemplateRequest_is_chan{_}: Bool
    case TemplateRequest_is_under_applied_head{_}: Bool
    case TemplateRequest_equal_args{_, _}: Bool
    case TemplateRequest_outer_is{_, _}: Bool
    case TemplateRequest_bit{_}: String
    case TemplateRequest_main{_}: NfSmoke
    case TemplateRequest_cps_provider_1_family_index{_}: Map<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_function_index{_}: Map<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_1_nf_context{_, _}: cps_provider_1_NfContext
    case TemplateRequest_cps_provider_1_default_fuel{}: Nat
    case TemplateRequest_cps_provider_1_family_of{_, _}: Maybe<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_function_of{_, _}: Maybe<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_1_native_of{_, _, _}: Maybe<&2, String>
    case TemplateRequest_cps_provider_1_val_nth{_, _}: cps_provider_1_NfVal
    case TemplateRequest_cps_provider_1_val_at{_, _, _}: cps_provider_1_NfVal
    case TemplateRequest_cps_provider_1_val_at_choose{_, _, _, _}: cps_provider_1_NfVal
    case TemplateRequest_cps_provider_1_first_vals{_, _}: List<&2, cps_provider_1_NfVal>
    case TemplateRequest_cps_provider_1_drop_vals{_, _}: List<&2, cps_provider_1_NfVal>
    case TemplateRequest_cps_provider_1_insert_before{_, _, _}: List<&2, cps_provider_1_NfVal>
    case TemplateRequest_cps_provider_1_append_vals{_, _}: List<&2, cps_provider_1_NfVal>
    case TemplateRequest_cps_provider_1_quantity_markers{_}: List<&2, cps_provider_1_NfVal>
    case TemplateRequest_cps_provider_1_renamed_level{_, _}: Nat
    case TemplateRequest_cps_provider_1_materialize_all_scoped{_, _, _}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_1_materialize_all_at{_, _}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_1_materialize_all{_}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_1_materialize_scoped{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_materialize_at{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_materialize{_}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_reify_env{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_status_combine{_, _}: cps_provider_1_NfStatus
    case TemplateRequest_cps_provider_1_bind_status{_, _}: cps_provider_1_NfStatus
    case TemplateRequest_cps_provider_1_bind_values{_, _}: List<&2, cps_provider_1_NfVal>
    case TemplateRequest_cps_provider_1_bind_patterns{_, _}: cps_provider_1_NfBind
    case TemplateRequest_cps_provider_1_nf{_, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_descriptor{_, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_arrow{_, _, _, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_descriptor_step{_, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_all{_, _, _, _, _}: cps_provider_1_NfList
    case TemplateRequest_cps_provider_1_nf_apply_args{_, _, _, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_apply_source{_, _, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_apply{_, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_apply_one{_, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_intrinsic_io{_}: Bool
    case TemplateRequest_cps_provider_1_nf_named_io{_, _, _, _, _, _}: cps_provider_1_Nf

def template_result_group_1(request: TemplateRequestGroup1) -> Data:
  match request:
    case TemplateRequest_cps_provider_1_nf_named{_, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_arity{_, _, _}: cps_provider_1_NfArity
    case TemplateRequest_cps_provider_1_nf_family{_, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_family_apply{_, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_reduce{_, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_reduce_apply{_, _, _, _, _, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_reduce_body{_, _, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_nf_cases{_, _, _, _, _, _, _}: cps_provider_1_Nf
    case TemplateRequest_cps_provider_1_normalize{_, _, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_normalize_closed{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_normalize_in{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_outer_application{_}: Maybe<&2, cps_provider_1_NfApp>
    case TemplateRequest_cps_provider_1_outer_walk{_, _}: Maybe<&2, cps_provider_1_NfApp>
    case TemplateRequest_cps_provider_1_answer_in{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_answer_descriptor{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_answer_normalized{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_1_is_io_head_in{_, _}: Bool
    case TemplateRequest_cps_provider_1_is_io_head{_, _, _}: Bool

def template_result(request: TemplateRequest) -> Data:
  match request:
    case TemplateRequestGroup_0{inner}: template_result_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_result_group_1(inner)

type TemplateValue<-A: Type> is Type:
  TemplateValue{value: A}

type TemplateProgress<-A: Type> is Type:
  TemplateFinished{box: TemplateValue<A>}
  TemplatePending{request: TemplateRequest, resume: (@box: TemplateValue<template_result(request)> -> TemplateProgress<A>)}
  TemplateDirect{-R: Type, -request: TemplateRequest, arguments: R, invoke: (@arguments: R -> TemplateProgress<template_result(request)>), resume: (@box: TemplateValue<template_result(request)> -> TemplateProgress<A>)}
  TemplateBound{-B: Type, inner: TemplateProgress<B>, resume: (@box: TemplateValue<B> -> TemplateProgress<A>)}


type TemplateStack<-A: Type, -R: Type> is Type:
  TemplateStackDone{equation: {A == R : Type}}
  TemplateStackMore{-B: Type, resume: (@box: TemplateValue<A> -> TemplateProgress<B>), rest: TemplateStack<B, R>}

type TemplateRun<-R: Type> is Type:
  TemplateRunFinished{box: TemplateValue<R>}
  TemplateRunState{-A: Type, progress: TemplateProgress<A>, stack: TemplateStack<A, R>}

def template_cast_box(-A: Type, -R: Type, equation: {A == R : Type}, box: TemplateValue<A>) -> TemplateValue<R>:
  %equation : TemplateValue<_>
  box

def template_unbox(-A: Type, box: TemplateValue<A>) -> A:
  match box:
    case TemplateValue{value}: value

def template_match_0(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case []:
      True{}
    case _:
      False{}

def template_pure_is_nat(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Nat", v_3}:
      template_match_0(v_3)
    case _:
      False{}

def template_match_2(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case []:
      True{}
    case _:
      False{}

def template_pure_is_bool(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Bool", v_3}:
      template_match_2(v_3)
    case _:
      False{}

def template_pure_is_arrow_nat(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorRef{"Nat", []}}:
      True{}
    case _:
      False{}

def template_pure_is_arrow_bound(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{0n}}:
      True{}
    case _:
      False{}

def template_pure_is_arrow_nest(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}}:
      True{}
    case _:
      False{}

def template_pure_is_scoped_let_arrow(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, _, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{1n}}}:
      True{}
    case _:
      False{}

def template_match_8(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case []:
      True{}
    case _:
      False{}

def template_pure_is_nat_ref(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Nat", v_3}:
      template_match_8(v_3)
    case _:
      False{}

def template_match_10(v_5: List<&2, BIR.Descriptor>) -> Bool:
  match v_5:
    case []:
      True{}
    case _:
      False{}

def template_match_11(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case BIR.DescriptorRef{"Event", []} <> v_5:
      template_match_10(v_5)
    case _:
      False{}

def template_pure_is_event_list(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"List", v_3}:
      template_match_11(v_3)
    case _:
      False{}

def template_pure_is_match_source(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorMatch{_, _}:
      True{}
    case _:
      False{}

def template_pure_is_failure(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorFailure{_}:
      True{}
    case _:
      False{}

def template_match_15(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case []:
      True{}
    case _:
      False{}

def template_pure_is_application(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorApplication{BIR.DescriptorParameter{0n}, BIR.DescriptorRef{"Nat", v_3}}:
      template_match_15(v_3)
    case _:
      False{}

def template_match_17(v_5: List<&2, BIR.Descriptor>) -> Bool:
  match v_5:
    case []:
      True{}
    case _:
      False{}

def template_match_18(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case BIR.DescriptorQuantity{BIR.Erased{}} <> v_5:
      template_match_17(v_5)
    case _:
      False{}

def template_pure_is_quantity_head(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"QM", v_3}:
      template_match_18(v_3)
    case _:
      False{}

def template_pure_is_parameter(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorParameter{0n}:
      True{}
    case _:
      False{}

def template_match_21(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case []:
      True{}
    case _:
      False{}

def template_pure_is_chan(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"Chan", v_3}:
      template_match_21(v_3)
    case _:
      False{}

def template_match_23(v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_3:
    case []:
      True{}
    case _:
      False{}

def template_pure_is_under_applied_head(v_0: BIR.Descriptor) -> Bool:
  match v_0:
    case BIR.DescriptorRef{"K", v_3}:
      template_match_23(v_3)
    case _:
      False{}

def template_match_25(v_3: cps_provider_1_NfStatus) -> cps_provider_1_NfStatus:
  match v_3:
    case cps_provider_1_NfStatusNo{}:
      cps_provider_1_NfStatusNo{}
    case _:
      cps_provider_1_NfStatusMaybe{}

def template_pure_cps_provider_1_status_combine(v_1: cps_provider_1_NfStatus, v_3: cps_provider_1_NfStatus) -> cps_provider_1_NfStatus:
  match v_1:
    case cps_provider_1_NfStatusNo{}:
      cps_provider_1_NfStatusNo{}
    case cps_provider_1_NfStatusMaybe{}:
      template_match_25(v_3)
    case cps_provider_1_NfStatusOk{}:
      v_3

def template_match_27(v_8: Maybe<&2, String>) -> Bool:
  match v_8:
    case Some{"IO"}:
      True{}
    case _:
      False{}

def template_pure_cps_provider_1_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      template_match_27(v_8)

def template_body_smoke_families() -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{[BIR.Family{"Nat", "Nat", Some{"Nat"}, 0n, 0n, []}, BIR.Family{"Bool", "Bool", Some{"Bool"}, 0n, 0n, []}, BIR.Family{"QM", "QM", Some{"QM"}, 1n, 1n, []}]}}

def template_body_smoke_functions() -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  TemplateFinished{TemplateValue{[BIR.TypeFunction{"IO", Some{"IO"}, 0n, 1n, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"IO.OP", []}, BIR.DescriptorRef{"IO.OP", [BIR.DescriptorRef{"Nat", []}]}}}, BIR.TypeFunction{"MyNat", None{}, 0n, 0n, BIR.DescriptorRef{"Nat", []}}, BIR.TypeFunction{"MyNat2", None{}, 0n, 0n, BIR.DescriptorRef{"MyNat", []}}, BIR.TypeFunction{"MyIO", None{}, 0n, 0n, BIR.DescriptorRef{"IO", [BIR.DescriptorRef{"Nat", []}]}}, BIR.TypeFunction{"Id", None{}, 0n, 1n, BIR.DescriptorParameter{0n}}, BIR.TypeFunction{"K2", None{}, 0n, 1n, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.TypeFunction{"K3", None{}, 0n, 2n, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{2n}}}, BIR.TypeFunction{"SelfArrow", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{1n}}}, BIR.TypeFunction{"ArrowBound", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorParameter{0n}}}, BIR.TypeFunction{"ArrowNest", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{0n}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{1n}}}}, BIR.TypeFunction{"AppTick", None{}, 0n, 1n, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"List", [BIR.DescriptorRef{"Event", []}]}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorParameter{1n}, BIR.DescriptorRef{"IO", [BIR.DescriptorRef{"Maybe", [BIR.DescriptorParameter{2n}]}]}}}}, BIR.TypeFunction{"AbsMatch", None{}, 0n, 1n, BIR.DescriptorMatch{[BIR.DescriptorParameter{0n}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", []}], BIR.DescriptorRef{"Nat", []}}]}}, BIR.TypeFunction{"K", None{}, 0n, 1n, BIR.DescriptorRef{"Bool", []}}, BIR.TypeFunction{"CycA", None{}, 0n, 0n, BIR.DescriptorRef{"CycB", []}}, BIR.TypeFunction{"CycB", None{}, 0n, 0n, BIR.DescriptorRef{"CycA", []}}]}}

def template_body_is_nat(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_nat(v_0)}}

def template_body_is_failure_with(v_0: BIR.Descriptor, v_2: String) -> TemplateProgress<Bool>:
  match v_0:
    case BIR.DescriptorFailure{v_5}:
      TemplateFinished{TemplateValue{String.eq(v_5, v_2)}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_is_bool(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_bool(v_0)}}

def template_body_is_arrow_nat(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_arrow_nat(v_0)}}

def template_body_is_arrow_bound(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_arrow_bound(v_0)}}

def template_body_is_arrow_nest(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_arrow_nest(v_0)}}

def template_body_is_scoped_let_arrow(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_scoped_let_arrow(v_0)}}

def template_body_is_relocated_arrow(v_0: BIR.Descriptor, v_2: Nat) -> TemplateProgress<Bool>:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, _, BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{v_7}}}}:
      TemplateFinished{TemplateValue{Nat.is_eq(v_7, v_2)}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_is_nat_ref(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_nat_ref(v_0)}}

def template_match_31(v_7: List<&2, BIR.Descriptor>, +v_6: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{template_pure_is_nat_ref(v_6)}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_32(v_3: List<&2, BIR.Descriptor>) -> TemplateProgress<Bool>:
  match v_3:
    case +v_6 <> v_7:
      template_match_31(v_7, v_6)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_is_maybe_nat(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_0:
    case BIR.DescriptorRef{"Maybe", v_3}:
      template_match_32(v_3)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_34(v_7: List<&2, BIR.Descriptor>, +v_6: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_7:
    case []:
      template_body_is_maybe_nat(v_6)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_35(v_3: List<&2, BIR.Descriptor>) -> TemplateProgress<Bool>:
  match v_3:
    case +v_6 <> v_7:
      template_match_34(v_7, v_6)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_is_io_maybe_nat(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_0:
    case BIR.DescriptorRef{"IO", v_3}:
      template_match_35(v_3)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_is_event_list(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_event_list(v_0)}}

def template_match_37(v_1000001: Bool, v_1000002: Bool, v_9: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_1000001, v_1000002:
    case True{}, True{}:
      template_body_is_io_maybe_nat(v_9)
    case _, _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_38(v_5: BIR.Descriptor, v_4: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_5:
    case BIR.DescriptorArrow{BIR.Erased{}, v_8, v_9}:
      v_1000001 = {template_pure_is_event_list(v_4) : Bool}
      v_1000002 = {template_pure_is_nat_ref(v_8) : Bool}
      template_match_37(v_1000001, v_1000002, v_9)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_is_app_tick(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_0:
    case BIR.DescriptorArrow{BIR.Erased{}, v_4, v_5}:
      template_match_38(v_5, v_4)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_is_match_source(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_match_source(v_0)}}

def template_body_is_failure(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_failure(v_0)}}

def template_body_is_application(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_application(v_0)}}

def template_body_is_quantity_head(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_quantity_head(v_0)}}

def template_body_is_parameter(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_parameter(v_0)}}

def template_body_is_chan(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_chan(v_0)}}

def template_body_is_under_applied_head(v_0: BIR.Descriptor) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_is_under_applied_head(v_0)}}

def template_body_equal_args(v_1: List<&2, BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>) -> TemplateProgress<Bool>:
  match v_1, v_3:
    case [], []:
      TemplateFinished{TemplateValue{True{}}}
    case BIR.DescriptorRef{"Nat", []} <> v_7, BIR.DescriptorRef{"Nat", []} <> v_8:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_equal_args{v_7, v_8}}, v_1000005 => +v_1000004 = template_unbox(Bool, v_1000005); TemplateFinished{TemplateValue{v_1000004}}}
    case BIR.DescriptorRef{"Bool", []} <> v_12, BIR.DescriptorRef{"Bool", []} <> v_13:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_equal_args{v_12, v_13}}, v_1000007 => +v_1000006 = template_unbox(Bool, v_1000007); TemplateFinished{TemplateValue{v_1000006}}}
    case BIR.DescriptorRef{"A", []} <> v_17, BIR.DescriptorRef{"A", []} <> v_18:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_equal_args{v_17, v_18}}, v_1000009 => +v_1000008 = template_unbox(Bool, v_1000009); TemplateFinished{TemplateValue{v_1000008}}}
    case BIR.DescriptorRef{"B", []} <> v_22, BIR.DescriptorRef{"B", []} <> v_23:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_equal_args{v_22, v_23}}, v_1000011 => +v_1000010 = template_unbox(Bool, v_1000011); TemplateFinished{TemplateValue{v_1000010}}}
    case _, _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_41(v_7: cps_provider_1_NfApp, v_4: List<&2, BIR.Descriptor>) -> TemplateProgress<Bool>:
  match v_7:
    case cps_provider_1_NfApp{v_10, v_11}:
      template_body_equal_args(v_11, v_4)

def template_body_outer_is(v_2: Maybe<&2, cps_provider_1_NfApp>, v_4: List<&2, BIR.Descriptor>) -> TemplateProgress<Bool>:
  match v_2:
    case Some{v_7}:
      template_match_41(v_7, v_4)
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_bit(v_1: Bool) -> TemplateProgress<String>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{"1"}}
    case False{}:
      TemplateFinished{TemplateValue{"0"}}

def template_continuation_44(v_1000103: String, +v_1000104: String, +v_1000106: String, +v_1000108: String, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_214: String, v_177: String) -> TemplateProgress<NfSmoke>:
  v_231 = String.append(v_1000103, String.append(v_1000104, String.append(v_1000106, v_1000108)))
  TemplateFinished{TemplateValue{NfSmoke{String.append(String.append(String.append(String.append(String.append(v_77, v_93), v_99), v_105), v_113), String.append(String.append(v_214, v_177), v_231))}}}

def template_continuation_45(+v_1000102: BIR.Descriptor, v_194: String, v_217: BIR.Descriptor, v_220: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_214: String, v_177: String) -> TemplateProgress<NfSmoke>:
  v_223 = v_1000102
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_scoped_let_arrow(v_217)}}, False{}, v_1000118 => template_body_bit(template_pure_is_scoped_let_arrow(v_217)), v_1000117 => +v_1000104 = template_unbox(String, v_1000117); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_relocated_arrow{v_220, 2n}}, False{}, v_1000116 => template_body_is_relocated_arrow(v_220, 2n), v_1000115 => +v_1000105 = template_unbox(Bool, v_1000115); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000105}}, False{}, v_1000114 => template_body_bit(v_1000105), v_1000113 => +v_1000106 = template_unbox(String, v_1000113); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_relocated_arrow{v_223, 0n}}, False{}, v_1000112 => template_body_is_relocated_arrow(v_223, 0n), v_1000111 => +v_1000107 = template_unbox(Bool, v_1000111); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000107}}, False{}, v_1000110 => template_body_bit(v_1000107), v_1000109 => +v_1000108 = template_unbox(String, v_1000109); template_continuation_44({v_194 : String}, v_1000104, v_1000106, v_1000108, v_77, v_93, v_99, v_105, v_113, v_214, v_177)}}}}}

def template_continuation_46(+v_1000101: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_194: String, v_217: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_214: String, v_177: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{0n}}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}}}}}, v_1000119 => +v_1000102 = template_unbox(BIR.Descriptor, v_1000119); template_continuation_45(v_1000102, v_194, v_217, v_1000101, v_77, v_93, v_99, v_105, v_113, v_214, v_177)}

def template_continuation_47(+v_1000100: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_194: String, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_214: String, v_177: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorRef{"Nat", []}, BIR.DescriptorParameter{1n}}}}}}, v_1000120 => +v_1000101 = template_unbox(BIR.Descriptor, v_1000120); template_continuation_46(v_1000101, v_5, v_8, v_194, v_1000100, v_77, v_93, v_99, v_105, v_113, v_214, v_177)}

def template_continuation_48(+v_1000088: String, +v_1000089: String, +v_1000090: String, +v_1000091: String, +v_1000092: String, +v_1000093: String, +v_1000095: String, +v_1000097: String, +v_1000099: String, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_194: String, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_177: String) -> TemplateProgress<NfSmoke>:
  v_214 = String.append(v_1000088, String.append(v_1000089, String.append(v_1000090, String.append(v_1000091, String.append(v_1000092, String.append(v_1000093, String.append(v_1000095, String.append(v_1000097, v_1000099))))))))
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorArrow{BIR.Erased{}, BIR.DescriptorKind{BIR.DescriptorQuantity{BIR.Unrestricted{}}}, BIR.DescriptorLet{[BIR.DescriptorRef{"Nat", []}], BIR.DescriptorArrow{BIR.Unrestricted{}, BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{2n}}}}}}, v_1000121 => +v_1000100 = template_unbox(BIR.Descriptor, v_1000121); template_continuation_47(v_1000100, v_5, v_8, v_194, v_77, v_93, v_99, v_105, v_113, v_214, v_177)}

def template_continuation_49(+v_1000084: String, +v_1000085: String, +v_1000087: String, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_177: String) -> TemplateProgress<NfSmoke>:
  v_194 = String.append(v_1000084, String.append(v_1000085, v_1000087))
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_116)}}, False{}, v_1000145 => template_body_bit(template_pure_is_nat(v_116)), v_1000144 => +v_1000088 = template_unbox(String, v_1000144); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_119)}}, False{}, v_1000143 => template_body_bit(template_pure_is_nat(v_119)), v_1000142 => +v_1000089 = template_unbox(String, v_1000142); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_122)}}, False{}, v_1000141 => template_body_bit(template_pure_is_nat(v_122)), v_1000140 => +v_1000090 = template_unbox(String, v_1000140); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_128)}}, False{}, v_1000139 => template_body_bit(template_pure_is_nat(v_128)), v_1000138 => +v_1000091 = template_unbox(String, v_1000138); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_match_source(v_131)}}, False{}, v_1000137 => template_body_bit(template_pure_is_match_source(v_131)), v_1000136 => +v_1000092 = template_unbox(String, v_1000136); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_bool(v_134)}}, False{}, v_1000135 => template_body_bit(template_pure_is_bool(v_134)), v_1000134 => +v_1000093 = template_unbox(String, v_1000134); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_failure_with{v_137, "the constructor `C` is applied to an argument"}}, False{}, v_1000133 => template_body_is_failure_with(v_137, "the constructor `C` is applied to an argument"), v_1000132 => +v_1000094 = template_unbox(Bool, v_1000132); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000094}}, False{}, v_1000131 => template_body_bit(v_1000094), v_1000130 => +v_1000095 = template_unbox(String, v_1000130); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_failure_with{v_140, "a quantity is applied to an argument"}}, False{}, v_1000129 => template_body_is_failure_with(v_140, "a quantity is applied to an argument"), v_1000128 => +v_1000096 = template_unbox(Bool, v_1000128); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000096}}, False{}, v_1000127 => template_body_bit(v_1000096), v_1000126 => +v_1000097 = template_unbox(String, v_1000126); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_failure_with{v_143, "a kind is applied to an argument"}}, False{}, v_1000125 => template_body_is_failure_with(v_143, "a kind is applied to an argument"), v_1000124 => +v_1000098 = template_unbox(Bool, v_1000124); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000098}}, False{}, v_1000123 => template_body_bit(v_1000098), v_1000122 => +v_1000099 = template_unbox(String, v_1000122); template_continuation_48(v_1000088, v_1000089, v_1000090, v_1000091, v_1000092, v_1000093, v_1000095, v_1000097, v_1000099, v_5, v_8, v_194, v_77, v_93, v_99, v_105, v_113, v_177)}}}}}}}}}}}}

def template_continuation_50(+v_1000083: BIR.Descriptor, v_180: BIR.Descriptor, v_183: BIR.Descriptor, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_177: String) -> TemplateProgress<NfSmoke>:
  v_186 = v_1000083
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_arrow_bound(v_180)}}, False{}, v_1000153 => template_body_bit(template_pure_is_arrow_bound(v_180)), v_1000152 => +v_1000084 = template_unbox(String, v_1000152); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_arrow_nest(v_183)}}, False{}, v_1000151 => template_body_bit(template_pure_is_arrow_nest(v_183)), v_1000150 => +v_1000085 = template_unbox(String, v_1000150); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_app_tick{v_186}}, False{}, v_1000149 => template_body_is_app_tick(v_186), v_1000148 => +v_1000086 = template_unbox(Bool, v_1000148); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000086}}, False{}, v_1000147 => template_body_bit(v_1000086), v_1000146 => +v_1000087 = template_unbox(String, v_1000146); template_continuation_49(v_1000084, v_1000085, v_1000087, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_5, v_8, v_77, v_93, v_99, v_105, v_113, v_177)}}}}

def template_continuation_51(+v_1000082: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_180: BIR.Descriptor, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_177: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"AppTick", [BIR.DescriptorRef{"Nat", []}]}}}, v_1000154 => +v_1000083 = template_unbox(BIR.Descriptor, v_1000154); template_continuation_50(v_1000083, v_180, v_1000082, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_5, v_8, v_77, v_93, v_99, v_105, v_113, v_177)}

def template_continuation_52(+v_1000081: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String, v_177: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"ArrowNest", [BIR.DescriptorRef{"Nat", []}]}}}, v_1000155 => +v_1000082 = template_unbox(BIR.Descriptor, v_1000155); template_continuation_51(v_1000082, v_5, v_8, v_1000081, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113, v_177)}

def template_continuation_53(+v_1000077: String, +v_1000078: String, +v_1000079: String, +v_1000080: String, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  v_177 = String.append(String.append(String.append(v_1000077, v_1000078), v_1000079), v_1000080)
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"ArrowBound", [BIR.DescriptorRef{"Nat", []}]}}}, v_1000156 => +v_1000081 = template_unbox(BIR.Descriptor, v_1000156); template_continuation_52(v_1000081, v_5, v_8, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113, v_177)}

def template_continuation_54(+v_1000076: BIR.Descriptor, v_157: BIR.Descriptor, v_160: BIR.Descriptor, v_153: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  v_167 = v_1000076
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_bool(v_157)}}, False{}, v_1000164 => template_body_bit(template_pure_is_bool(v_157)), v_1000163 => +v_1000077 = template_unbox(String, v_1000163); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_arrow_nat(v_160)}}, False{}, v_1000162 => template_body_bit(template_pure_is_arrow_nat(v_160)), v_1000161 => +v_1000078 = template_unbox(String, v_1000161); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_167)}}, False{}, v_1000160 => template_body_bit(template_pure_is_nat(v_167)), v_1000159 => +v_1000079 = template_unbox(String, v_1000159); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_153)}}, False{}, v_1000158 => template_body_bit(template_pure_is_nat(v_153)), v_1000157 => +v_1000080 = template_unbox(String, v_1000157); template_continuation_53(v_1000077, v_1000078, v_1000079, v_1000080, v_5, v_8, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113)}}}}

def template_continuation_55(+v_1000074: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_157: BIR.Descriptor, v_160: BIR.Descriptor, v_153: BIR.Descriptor, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_context{v_5, v_8}}, v_1000166 => +v_1000075 = template_unbox(cps_provider_1_NfContext, v_1000166); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize{v_1000075, v_1000074, [cps_provider_1_NfCtor{"True", []}], 1024n}}, v_1000165 => +v_1000076 = template_unbox(BIR.Descriptor, v_1000165); template_continuation_54(v_1000076, v_157, v_160, v_153, v_5, v_8, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113)}}

def template_continuation_56(+v_1000073: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_157: BIR.Descriptor, v_153: BIR.Descriptor, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"AbsMatch", [BIR.DescriptorParameter{0n}]}}}, v_1000167 => +v_1000074 = template_unbox(BIR.Descriptor, v_1000167); template_continuation_55(v_1000074, v_5, v_8, v_157, v_1000073, v_153, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_57(+v_1000072: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_153: BIR.Descriptor, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"SelfArrow", [BIR.DescriptorRef{"Nat", []}]}}}, v_1000168 => +v_1000073 = template_unbox(BIR.Descriptor, v_1000168); template_continuation_56(v_1000073, v_5, v_8, v_1000072, v_153, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_58(+v_1000070: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_146: BIR.Descriptor, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_context{v_5, v_8}}, v_1000170 => +v_1000071 = template_unbox(cps_provider_1_NfContext, v_1000170); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize{v_1000071, BIR.DescriptorApplication{v_146, BIR.DescriptorRef{"Nat", []}}, [cps_provider_1_NfType{"Bool", []}], 1024n}}, v_1000169 => +v_1000072 = template_unbox(BIR.Descriptor, v_1000169); template_continuation_57(v_1000072, v_5, v_8, v_1000070, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113)}}

def template_continuation_59(+v_1000068: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_146: BIR.Descriptor, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_context{v_5, v_8}}, v_1000172 => +v_1000069 = template_unbox(cps_provider_1_NfContext, v_1000172); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize{v_1000069, BIR.DescriptorApplication{v_1000068, BIR.DescriptorRef{"U32", []}}, [cps_provider_1_NfType{"Nat", []}, cps_provider_1_NfType{"Bool", []}], 1024n}}, v_1000171 => +v_1000070 = template_unbox(BIR.Descriptor, v_1000171); template_continuation_58(v_1000070, v_5, v_8, v_146, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113)}}

def template_continuation_60(+v_1000067: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_143: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"K3", [BIR.DescriptorParameter{1n}, BIR.DescriptorParameter{0n}]}}}, v_1000173 => +v_1000068 = template_unbox(BIR.Descriptor, v_1000173); template_continuation_59(v_1000068, v_5, v_8, v_1000067, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_143, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_61(+v_1000066: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_140: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"K2", [BIR.DescriptorParameter{0n}]}}}, v_1000174 => +v_1000067 = template_unbox(BIR.Descriptor, v_1000174); template_continuation_60(v_1000067, v_5, v_8, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_140, v_1000066, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_62(+v_1000065: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_137: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorKind{BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorRef{"Bool", []}}}}, v_1000175 => +v_1000066 = template_unbox(BIR.Descriptor, v_1000175); template_continuation_61(v_1000066, v_5, v_8, v_116, v_119, v_122, v_128, v_131, v_134, v_137, v_1000065, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_63(+v_1000064: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_134: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorQuantity{BIR.Erased{}}, BIR.DescriptorRef{"Nat", []}}}}, v_1000176 => +v_1000065 = template_unbox(BIR.Descriptor, v_1000176); template_continuation_62(v_1000065, v_5, v_8, v_116, v_119, v_122, v_128, v_131, v_134, v_1000064, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_64(+v_1000063: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_131: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorConstructor{"C", []}, BIR.DescriptorRef{"Nat", []}}}}, v_1000177 => +v_1000064 = template_unbox(BIR.Descriptor, v_1000177); template_continuation_63(v_1000064, v_5, v_8, v_116, v_119, v_122, v_128, v_131, v_1000063, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_65(+v_1000062: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_128: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", []}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", []}], BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorCase{[BIR.DescriptorBinder{BIR.Erased{}}], BIR.DescriptorRef{"Bool", []}}]}}}, v_1000178 => +v_1000063 = template_unbox(BIR.Descriptor, v_1000178); template_continuation_64(v_1000063, v_5, v_8, v_116, v_119, v_122, v_128, v_1000062, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_66(+v_1000061: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorParameter{0n}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"True", []}], BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorCase{[BIR.DescriptorBinder{BIR.Erased{}}], BIR.DescriptorRef{"Bool", []}}]}}}, v_1000179 => +v_1000062 = template_unbox(BIR.Descriptor, v_1000179); template_continuation_65(v_1000062, v_5, v_8, v_116, v_119, v_122, v_1000061, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_67(+v_1000060: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_122: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{v_1000060, BIR.DescriptorRef{"Bool", []}}}}, v_1000180 => +v_1000061 = template_unbox(BIR.Descriptor, v_1000180); template_continuation_66(v_1000061, v_5, v_8, v_116, v_119, v_122, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_68(+v_1000059: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_119: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.DescriptorRef{"Nat", []}}}}, v_1000181 => +v_1000060 = template_unbox(BIR.Descriptor, v_1000181); template_continuation_67(v_1000060, v_5, v_8, v_116, v_119, v_1000059, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_69(+v_1000058: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_116: BIR.Descriptor, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{1n}}}, BIR.DescriptorRef{"Nat", []}}, BIR.DescriptorRef{"Bool", []}}}}, v_1000182 => +v_1000059 = template_unbox(BIR.Descriptor, v_1000182); template_continuation_68(v_1000059, v_5, v_8, v_116, v_1000058, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_70(+v_1000057: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_77: String, v_93: String, v_99: String, v_105: String, v_113: String) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorRef{"K2", [BIR.DescriptorRef{"Nat", []}]}, BIR.DescriptorRef{"Bool", []}}}}, v_1000183 => +v_1000058 = template_unbox(BIR.Descriptor, v_1000183); template_continuation_69(v_1000058, v_5, v_8, v_1000057, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_71(+v_1000053: String, +v_1000055: String, +v_1000056: String, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_77: String, v_93: String, v_99: String, v_105: String) -> TemplateProgress<NfSmoke>:
  v_113 = String.append(String.append(v_1000053, v_1000055), v_1000056)
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorLambda{None{}, BIR.DescriptorParameter{0n}}, BIR.DescriptorRef{"Nat", []}}}}, v_1000184 => +v_1000057 = template_unbox(BIR.Descriptor, v_1000184); template_continuation_70(v_1000057, v_5, v_8, v_77, v_93, v_99, v_105, v_113)}

def template_continuation_72(+v_1000050: String, +v_1000051: String, v_53: BIR.Descriptor, v_56: BIR.Descriptor, v_59: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_77: String, v_93: String, v_99: String) -> TemplateProgress<NfSmoke>:
  v_105 = String.append(v_1000050, v_1000051)
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_failure_with{v_53, "bend: malformed type match"}}, False{}, v_1000194 => template_body_is_failure_with(v_53, "bend: malformed type match"), v_1000193 => +v_1000052 = template_unbox(Bool, v_1000193); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000052}}, False{}, v_1000192 => template_body_bit(v_1000052), v_1000191 => +v_1000053 = template_unbox(String, v_1000191); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_is_failure_with{v_56, "descriptor match case is not a case"}}, False{}, v_1000190 => template_body_is_failure_with(v_56, "descriptor match case is not a case"), v_1000189 => +v_1000054 = template_unbox(Bool, v_1000189); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000054}}, False{}, v_1000188 => template_body_bit(v_1000054), v_1000187 => +v_1000055 = template_unbox(String, v_1000187); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_59)}}, False{}, v_1000186 => template_body_bit(template_pure_is_nat(v_59)), v_1000185 => +v_1000056 = template_unbox(String, v_1000185); template_continuation_71(v_1000053, v_1000055, v_1000056, v_5, v_8, v_77, v_93, v_99, v_105)}}}}}

def template_continuation_73(+v_1000047: String, +v_1000049: String, v_47: BIR.Descriptor, v_50: BIR.Descriptor, v_53: BIR.Descriptor, v_56: BIR.Descriptor, v_59: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_77: String, v_93: String) -> TemplateProgress<NfSmoke>:
  v_99 = String.append(v_1000047, v_1000049)
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_failure(v_47)}}, False{}, v_1000198 => template_body_bit(template_pure_is_failure(v_47)), v_1000197 => +v_1000050 = template_unbox(String, v_1000197); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_50)}}, False{}, v_1000196 => template_body_bit(template_pure_is_nat(v_50)), v_1000195 => +v_1000051 = template_unbox(String, v_1000195); template_continuation_72(v_1000050, v_1000051, v_53, v_56, v_59, v_5, v_8, v_77, v_93, v_99)}}

def template_continuation_74(+v_1000039: String, +v_1000040: String, +v_1000041: String, +v_1000042: String, +v_1000043: String, +v_1000044: String, +v_1000045: String, v_62: Maybe<&2, cps_provider_1_NfApp>, v_65: Maybe<&2, cps_provider_1_NfApp>, v_47: BIR.Descriptor, v_50: BIR.Descriptor, v_53: BIR.Descriptor, v_56: BIR.Descriptor, v_59: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_77: String) -> TemplateProgress<NfSmoke>:
  v_93 = String.append(v_1000039, String.append(v_1000040, String.append(v_1000041, String.append(v_1000042, String.append(v_1000043, String.append(v_1000044, v_1000045))))))
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_outer_is{v_62, [BIR.DescriptorRef{"A", []}, BIR.DescriptorRef{"B", []}, BIR.DescriptorRef{"Nat", []}]}}, False{}, v_1000206 => template_body_outer_is(v_62, [BIR.DescriptorRef{"A", []}, BIR.DescriptorRef{"B", []}, BIR.DescriptorRef{"Nat", []}]), v_1000205 => +v_1000046 = template_unbox(Bool, v_1000205); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000046}}, False{}, v_1000204 => template_body_bit(v_1000046), v_1000203 => +v_1000047 = template_unbox(String, v_1000203); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_outer_is{v_65, [BIR.DescriptorRef{"A", []}, BIR.DescriptorRef{"B", []}, BIR.DescriptorRef{"Nat", []}]}}, False{}, v_1000202 => template_body_outer_is(v_65, [BIR.DescriptorRef{"A", []}, BIR.DescriptorRef{"B", []}, BIR.DescriptorRef{"Nat", []}]), v_1000201 => +v_1000048 = template_unbox(Bool, v_1000201); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{v_1000048}}, False{}, v_1000200 => template_body_bit(v_1000048), v_1000199 => +v_1000049 = template_unbox(String, v_1000199); template_continuation_73(v_1000047, v_1000049, v_47, v_50, v_53, v_56, v_59, v_5, v_8, v_77, v_93)}}}}

def template_continuation_75(+v_1000034: String, +v_1000035: String, +v_1000036: String, +v_1000037: String, +v_1000038: String, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor, v_62: Maybe<&2, cps_provider_1_NfApp>, v_65: Maybe<&2, cps_provider_1_NfApp>, v_47: BIR.Descriptor, v_50: BIR.Descriptor, v_53: BIR.Descriptor, v_56: BIR.Descriptor, v_59: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>) -> TemplateProgress<NfSmoke>:
  v_77 = String.append(v_1000034, String.append(v_1000035, String.append(v_1000036, String.append(v_1000037, v_1000038))))
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_quantity_head(v_26)}}, False{}, v_1000220 => template_body_bit(template_pure_is_quantity_head(v_26)), v_1000219 => +v_1000039 = template_unbox(String, v_1000219); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_failure(v_29)}}, False{}, v_1000218 => template_body_bit(template_pure_is_failure(v_29)), v_1000217 => +v_1000040 = template_unbox(String, v_1000217); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_32)}}, False{}, v_1000216 => template_body_bit(template_pure_is_nat(v_32)), v_1000215 => +v_1000041 = template_unbox(String, v_1000215); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_35)}}, False{}, v_1000214 => template_body_bit(template_pure_is_nat(v_35)), v_1000213 => +v_1000042 = template_unbox(String, v_1000213); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_under_applied_head(v_38)}}, False{}, v_1000212 => template_body_bit(template_pure_is_under_applied_head(v_38)), v_1000211 => +v_1000043 = template_unbox(String, v_1000211); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_chan(v_41)}}, False{}, v_1000210 => template_body_bit(template_pure_is_chan(v_41)), v_1000209 => +v_1000044 = template_unbox(String, v_1000209); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_parameter(v_44)}}, False{}, v_1000208 => template_body_bit(template_pure_is_parameter(v_44)), v_1000207 => +v_1000045 = template_unbox(String, v_1000207); template_continuation_74(v_1000039, v_1000040, v_1000041, v_1000042, v_1000043, v_1000044, v_1000045, v_62, v_65, v_47, v_50, v_53, v_56, v_59, v_5, v_8, v_77)}}}}}}}

def template_continuation_76(+v_1000033: Maybe<&2, cps_provider_1_NfApp>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor, v_62: Maybe<&2, cps_provider_1_NfApp>, v_47: BIR.Descriptor, v_50: BIR.Descriptor, v_53: BIR.Descriptor, v_56: BIR.Descriptor, v_59: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>) -> TemplateProgress<NfSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_11)}}, False{}, v_1000230 => template_body_bit(template_pure_is_nat(v_11)), v_1000229 => +v_1000034 = template_unbox(String, v_1000229); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_14)}}, False{}, v_1000228 => template_body_bit(template_pure_is_nat(v_14)), v_1000227 => +v_1000035 = template_unbox(String, v_1000227); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_nat(v_17)}}, False{}, v_1000226 => template_body_bit(template_pure_is_nat(v_17)), v_1000225 => +v_1000036 = template_unbox(String, v_1000225); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_failure(v_23)}}, False{}, v_1000224 => template_body_bit(template_pure_is_failure(v_23)), v_1000223 => +v_1000037 = template_unbox(String, v_1000223); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_bit{template_pure_is_application(v_20)}}, False{}, v_1000222 => template_body_bit(template_pure_is_application(v_20)), v_1000221 => +v_1000038 = template_unbox(String, v_1000221); template_continuation_75(v_1000034, v_1000035, v_1000036, v_1000037, v_1000038, v_26, v_29, v_32, v_35, v_38, v_41, v_44, v_62, v_1000033, v_47, v_50, v_53, v_56, v_59, v_5, v_8)}}}}}

def template_continuation_77(+v_1000032: Maybe<&2, cps_provider_1_NfApp>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor, v_47: BIR.Descriptor, v_50: BIR.Descriptor, v_53: BIR.Descriptor, v_56: BIR.Descriptor, v_59: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_outer_application{BIR.DescriptorApplication{BIR.DescriptorApplication{BIR.DescriptorRef{"C", [BIR.DescriptorRef{"A", []}]}, BIR.DescriptorRef{"B", []}}, BIR.DescriptorRef{"Nat", []}}}}, v_1000231 => +v_1000033 = template_unbox(Maybe<&2, cps_provider_1_NfApp>, v_1000231); template_continuation_76(v_1000033, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_41, v_44, v_1000032, v_47, v_50, v_53, v_56, v_59, v_5, v_8)}

def template_continuation_78(+v_1000031: BIR.Descriptor, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor, v_47: BIR.Descriptor, v_50: BIR.Descriptor, v_53: BIR.Descriptor, v_56: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_outer_application{BIR.DescriptorFill{BIR.DescriptorFill{BIR.DescriptorRef{"C", [BIR.DescriptorRef{"A", []}]}, [BIR.DescriptorRef{"B", []}]}, [BIR.DescriptorRef{"Nat", []}]}}}, v_1000232 => +v_1000032 = template_unbox(Maybe<&2, cps_provider_1_NfApp>, v_1000232); template_continuation_77(v_1000032, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_41, v_44, v_47, v_50, v_53, v_56, v_1000031, v_5, v_8)}

def template_continuation_79(+v_1000030: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor, v_47: BIR.Descriptor, v_50: BIR.Descriptor, v_53: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorConstructor{"C", [BIR.DescriptorRef{"Nat", []}]}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"D", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}, BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"C", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}]}}}, v_1000233 => +v_1000031 = template_unbox(BIR.Descriptor, v_1000233); template_continuation_78(v_1000031, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_41, v_44, v_47, v_50, v_53, v_1000030, v_5, v_8)}

def template_continuation_80(+v_1000029: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor, v_47: BIR.Descriptor, v_50: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", []}], [BIR.DescriptorNull{}]}}}, v_1000234 => +v_1000030 = template_unbox(BIR.Descriptor, v_1000234); template_continuation_79(v_1000030, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_41, v_44, v_47, v_50, v_1000029)}

def template_continuation_81(+v_1000028: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor, v_47: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorRef{"Nat", []}], [BIR.DescriptorFailure{"bend: malformed type match"}]}}}, v_1000235 => +v_1000029 = template_unbox(BIR.Descriptor, v_1000235); template_continuation_80(v_1000029, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_41, v_44, v_47, v_1000028)}

def template_continuation_82(+v_1000027: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor, v_44: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"MyNat2", []}}}, v_1000236 => +v_1000028 = template_unbox(BIR.Descriptor, v_1000236); template_continuation_81(v_1000028, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_41, v_44, v_1000027)}

def template_continuation_83(+v_1000026: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor, v_41: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"Nat", [BIR.DescriptorRef{"Bool", []}]}}}, v_1000237 => +v_1000027 = template_unbox(BIR.Descriptor, v_1000237); template_continuation_82(v_1000027, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_41, v_1000026)}

def template_continuation_84(+v_1000025: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor, v_38: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorParameter{0n}}}, v_1000238 => +v_1000026 = template_unbox(BIR.Descriptor, v_1000238); template_continuation_83(v_1000026, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_38, v_1000025)}

def template_continuation_85(+v_1000024: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor, v_35: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"Chan", []}}}, v_1000239 => +v_1000025 = template_unbox(BIR.Descriptor, v_1000239); template_continuation_84(v_1000025, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_35, v_1000024)}

def template_continuation_86(+v_1000023: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor, v_32: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"K", []}}}, v_1000240 => +v_1000024 = template_unbox(BIR.Descriptor, v_1000240); template_continuation_85(v_1000024, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_32, v_1000023)}

def template_continuation_87(+v_1000022: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor, v_29: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorMatch{[BIR.DescriptorConstructor{"C", [BIR.DescriptorRef{"Nat", []}]}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"C", [BIR.DescriptorBinder{BIR.Erased{}}]}], BIR.DescriptorParameter{0n}}]}}}, v_1000241 => +v_1000023 = template_unbox(BIR.Descriptor, v_1000241); template_continuation_86(v_1000023, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_29, v_1000022)}

def template_continuation_88(+v_1000021: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor, v_26: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Nat", []}]}]}}}, v_1000242 => +v_1000022 = template_unbox(BIR.Descriptor, v_1000242); template_continuation_87(v_1000022, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_26, v_1000021)}

def template_continuation_89(+v_1000020: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_23: BIR.Descriptor, v_20: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"K", [BIR.DescriptorRef{"Nat", []}, BIR.DescriptorRef{"Bool", []}]}}}, v_1000243 => +v_1000021 = template_unbox(BIR.Descriptor, v_1000243); template_continuation_88(v_1000021, v_5, v_8, v_11, v_14, v_17, v_23, v_20, v_1000020)}

def template_continuation_90(+v_1000019: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor, v_20: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"QM", []}}}, v_1000244 => +v_1000020 = template_unbox(BIR.Descriptor, v_1000244); template_continuation_89(v_1000020, v_5, v_8, v_11, v_14, v_17, v_1000019, v_20)}

def template_continuation_91(+v_1000018: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor, v_17: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"CycA", []}}}, v_1000245 => +v_1000019 = template_unbox(BIR.Descriptor, v_1000245); template_continuation_90(v_1000019, v_5, v_8, v_11, v_14, v_17, v_1000018)}

def template_continuation_92(+v_1000017: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor, v_14: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorApplication{BIR.DescriptorParameter{0n}, BIR.DescriptorRef{"Nat", []}}}}, v_1000246 => +v_1000018 = template_unbox(BIR.Descriptor, v_1000246); template_continuation_91(v_1000018, v_5, v_8, v_11, v_14, v_1000017)}

def template_continuation_93(+v_1000016: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>, v_11: BIR.Descriptor) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_8, BIR.DescriptorRef{"Id", [BIR.DescriptorRef{"Nat", []}]}}}, v_1000247 => +v_1000017 = template_unbox(BIR.Descriptor, v_1000247); template_continuation_92(v_1000017, v_5, v_8, v_11, v_1000016)}

def template_continuation_94(+v_1000015: BIR.Descriptor, +v_5: List<&2, BIR.Family>, +v_8: List<&2, BIR.TypeFunction>) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_answer_descriptor{BIR.DescriptorRef{"MyIO", []}, v_5, v_8}}, v_1000248 => +v_1000016 = template_unbox(BIR.Descriptor, v_1000248); template_continuation_93(v_1000016, v_5, v_8, v_1000015)}

def template_continuation_95(+v_1000014: List<&2, BIR.TypeFunction>, +v_5: List<&2, BIR.Family>) -> TemplateProgress<NfSmoke>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize_closed{v_5, v_1000014, BIR.DescriptorRef{"MyNat", []}}}, v_1000249 => +v_1000015 = template_unbox(BIR.Descriptor, v_1000249); template_continuation_94(v_1000015, v_5, v_1000014)}

def template_continuation_96(+v_1000013: List<&2, BIR.Family>) -> TemplateProgress<NfSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_smoke_functions{}}, False{}, v_1000251 => template_body_smoke_functions, v_1000250 => +v_1000014 = template_unbox(List<&2, BIR.TypeFunction>, v_1000250); template_continuation_95(v_1000014, v_1000013)}

def template_body_main(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<NfSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_smoke_families{}}, False{}, v_1000253 => template_body_smoke_families, v_1000252 => +v_1000013 = template_unbox(List<&2, BIR.Family>, v_1000252); template_continuation_96(v_1000013)}

def template_match_97(+v_5: BIR.Family, v_6: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.Family>>:
  match v_5:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_index{v_6}}, v_1000255 => +v_1000254 = template_unbox(Map<&2, BIR.Family>, v_1000255); TemplateFinished{TemplateValue{Map.set(&2, BIR.Family, v_1000254, v_13, v_5)}}}

def template_body_cps_provider_1_family_index(v_1: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.Family>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.Family)}}
    case +v_5 <> v_6:
      template_match_97(v_5, v_6)

def template_match_99(+v_5: BIR.TypeFunction, v_6: List<&2, BIR.TypeFunction>) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  match v_5:
    case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_function_index{v_6}}, v_1000257 => +v_1000256 = template_unbox(Map<&2, BIR.TypeFunction>, v_1000257); TemplateFinished{TemplateValue{Map.set(&2, BIR.TypeFunction, v_1000256, v_12, v_5)}}}

def template_body_cps_provider_1_function_index(v_1: List<&2, BIR.TypeFunction>) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.TypeFunction)}}
    case +v_5 <> v_6:
      template_match_99(v_5, v_6)

def template_body_cps_provider_1_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> TemplateProgress<cps_provider_1_NfContext>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_index{v_1}}, False{}, v_1000263 => template_body_cps_provider_1_family_index(v_1), v_1000262 => +v_1000258 = template_unbox(Map<&2, BIR.Family>, v_1000262); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_function_index{v_3}}, False{}, v_1000261 => template_body_cps_provider_1_function_index(v_3), v_1000260 => +v_1000259 = template_unbox(Map<&2, BIR.TypeFunction>, v_1000260); TemplateFinished{TemplateValue{cps_provider_1_NfContext{v_1000258, v_1000259}}}}}

def template_body_cps_provider_1_default_fuel() -> TemplateProgress<Nat>:
  TemplateFinished{TemplateValue{1024n}}

def template_body_cps_provider_1_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{IndexLookup.find(BIR.Family, v_3, v_1)}}

def template_body_cps_provider_1_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, BIR.TypeFunction>>:
  TemplateFinished{TemplateValue{IndexLookup.find(BIR.TypeFunction, v_3, v_1)}}

def template_match_101(v_10: BIR.Family) -> TemplateProgress<Maybe<&2, String>>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      TemplateFinished{TemplateValue{v_19}}

def template_match_102(v_25: BIR.TypeFunction) -> TemplateProgress<Maybe<&2, String>>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      TemplateFinished{TemplateValue{v_32}}

def template_match_103(+v_1000265: Maybe<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  match v_1000265:
    case Some{v_25}:
      template_match_102(v_25)
    case None{}:
      TemplateFinished{TemplateValue{None{}}}

def template_match_104(+v_1000264: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  match v_1000264:
    case Some{v_10}:
      template_match_101(v_10)
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_function_of{v_1, v_5}}, False{}, v_1000267 => template_body_cps_provider_1_function_of(v_1, v_5), v_1000266 => +v_1000265 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1000266); template_match_103(v_1000265)}

def template_body_cps_provider_1_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_of{v_1, v_3}}, False{}, v_1000269 => template_body_cps_provider_1_family_of(v_1, v_3), v_1000268 => +v_1000264 = template_unbox(Maybe<&2, BIR.Family>, v_1000268); template_match_104(v_1000264, v_1, v_5)}

def template_body_cps_provider_1_val_nth(+v_2: List<&2, cps_provider_1_NfVal>, v_4: Nat) -> TemplateProgress<cps_provider_1_NfVal>:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      TemplateFinished{TemplateValue{v_8}}
    case +v_13 <> v_14, 1n+v_15:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_val_nth{v_14, v_15}}, v_1000271 => +v_1000270 = template_unbox(cps_provider_1_NfVal, v_1000271); TemplateFinished{TemplateValue{v_1000270}}}
    case _, _:
      TemplateFinished{TemplateValue{cps_provider_1_NfMissing{BIR.DescriptorNull{}}}}

def template_body_cps_provider_1_val_at(+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> TemplateProgress<cps_provider_1_NfVal>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_val_at_choose{Nat.is_lt(v_4, List.length(&2, cps_provider_1_NfVal, v_2)), v_2, v_4, v_5}}, v_1000273 => +v_1000272 = template_unbox(cps_provider_1_NfVal, v_1000273); TemplateFinished{TemplateValue{v_1000272}}}

def template_body_cps_provider_1_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_1_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> TemplateProgress<cps_provider_1_NfVal>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_val_nth{v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_1_NfVal, v_4), 1n), v_6)}}, False{}, v_1000276 => template_body_cps_provider_1_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_1_NfVal, v_4), 1n), v_6)), v_1000275 => +v_1000274 = template_unbox(cps_provider_1_NfVal, v_1000275); TemplateFinished{TemplateValue{v_1000274}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfMissing{v_7}}}

def template_body_cps_provider_1_first_vals(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_2, v_4:
    case _, 0n:
      TemplateFinished{TemplateValue{[]}}
    case [], _:
      TemplateFinished{TemplateValue{[]}}
    case +v_14 <> v_15, 1n+v_16:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_first_vals{v_15, v_16}}, v_1000279 => +v_1000278 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000279); TemplateFinished{TemplateValue{{v_14 : cps_provider_1_NfVal} <> v_1000278}}}

def template_body_cps_provider_1_drop_vals(+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_2, v_4:
    case v_1000610, 0n:
      TemplateFinished{TemplateValue{v_2}}
    case [], v_1000611:
      TemplateFinished{TemplateValue{[]}}
    case +v_1000612 <> v_1000613, 1n+v_1000614:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_drop_vals{v_1000613, v_1000614}}, v_1000615 => +v_1000616 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000615); TemplateFinished{TemplateValue{v_1000616}}}

def template_body_cps_provider_1_insert_before(+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, v_6: cps_provider_1_NfVal) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_2, v_4:
    case v_1000617, 0n:
      TemplateFinished{TemplateValue{v_6 <> v_2}}
    case [], 1n+v_1000618:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_insert_before{[], v_1000618, v_6}}, v_1000619 => +v_1000620 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000619); TemplateFinished{TemplateValue{v_1000620}}}
    case +v_1000621 <> v_1000622, 1n+v_1000623:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_insert_before{v_1000622, v_1000623, v_6}}, v_1000625 => +v_1000626 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000625); TemplateFinished{TemplateValue{{v_1000621 : cps_provider_1_NfVal} <> v_1000626}}}

def template_body_cps_provider_1_append_vals(v_2: List<&2, cps_provider_1_NfVal>, v_5: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_5}}
    case +v_10 <> v_11:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_append_vals{v_11, v_5}}, v_1000289 => +v_1000288 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000289); TemplateFinished{TemplateValue{{v_10 : cps_provider_1_NfVal} <> v_1000288}}}

def template_body_cps_provider_1_quantity_markers(v_1: Nat) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case 1n+v_5:
      v_1000290 = {cps_provider_1_NfQuantity{BIR.Erased{}} : cps_provider_1_NfVal}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_quantity_markers{v_5}}, v_1000292 => +v_1000291 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000292); TemplateFinished{TemplateValue{v_1000290 <> v_1000291}}}

def template_match_112(v_1000293: Bool, v_10: Nat, v_11: List<&2, cps_provider_1_NfRenaming>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_1000293:
    case True{}:
      TemplateFinished{TemplateValue{v_10}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_renamed_level{v_11, v_4}}, v_1000295 => +v_1000294 = template_unbox(Nat, v_1000295); TemplateFinished{TemplateValue{v_1000294}}}

def template_body_cps_provider_1_renamed_level(v_2: List<&2, cps_provider_1_NfRenaming>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case cps_provider_1_NfRenaming{v_9, v_10} <> v_11:
      v_1000293 = {Nat.is_eq(v_9, v_4) : Bool}
      template_match_112(v_1000293, v_10, v_11, v_4)

def template_body_cps_provider_1_materialize_all_scoped(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_1_NfRenaming>) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_11 <> v_12:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_scoped{v_11, v_4, v_7}}, v_1000299 => +v_1000296 = template_unbox(BIR.Descriptor, v_1000299); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_all_scoped{v_12, v_4, v_7}}, v_1000298 => +v_1000297 = template_unbox(List<&2, BIR.Descriptor>, v_1000298); TemplateFinished{TemplateValue{v_1000296 <> v_1000297}}}}

def template_body_cps_provider_1_materialize_all_at(v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  template_body_cps_provider_1_materialize_all_scoped(v_2, v_4, [])

def template_body_cps_provider_1_materialize_all(v_2: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  template_body_cps_provider_1_materialize_all_at(v_2, 0n)

def template_body_cps_provider_1_materialize_scoped(v_1: cps_provider_1_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_1_NfRenaming>) -> TemplateProgress<BIR.Descriptor>:
  match v_1:
    case cps_provider_1_NfType{v_9, v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_all_scoped{v_10, v_3, v_6}}, False{}, v_1000305 => template_body_cps_provider_1_materialize_all_scoped(v_10, v_3, v_6), v_1000304 => +v_1000303 = template_unbox(List<&2, BIR.Descriptor>, v_1000304); TemplateFinished{TemplateValue{BIR.DescriptorRef{{v_9 : String}, v_1000303}}}}
    case cps_provider_1_NfCtor{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_all_scoped{v_15, v_3, v_6}}, False{}, v_1000309 => template_body_cps_provider_1_materialize_all_scoped(v_15, v_3, v_6), v_1000308 => +v_1000307 = template_unbox(List<&2, BIR.Descriptor>, v_1000308); TemplateFinished{TemplateValue{BIR.DescriptorConstructor{{v_14 : String}, v_1000307}}}}
    case cps_provider_1_NfQuantity{v_18}:
      TemplateFinished{TemplateValue{BIR.DescriptorQuantity{v_18}}}
    case cps_provider_1_NfKind{v_20}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_scoped{v_20, v_3, v_6}}, v_1000311 => +v_1000310 = template_unbox(BIR.Descriptor, v_1000311); TemplateFinished{TemplateValue{BIR.DescriptorKind{v_1000310}}}}
    case cps_provider_1_NfOther{v_23}:
      TemplateFinished{TemplateValue{v_23}}
    case cps_provider_1_NfMissing{v_25}:
      TemplateFinished{TemplateValue{v_25}}
    case cps_provider_1_NfBinder{v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_renamed_level{v_6, v_27}}, False{}, v_1000315 => template_body_cps_provider_1_renamed_level(v_6, v_27), v_1000314 => +v_1000313 = template_unbox(Nat, v_1000314); TemplateFinished{TemplateValue{BIR.DescriptorParameter{Nat.sub({v_3 : Nat}, Nat.add(v_1000313, 1n))}}}}
    case cps_provider_1_NfArrow{v_33, v_34, v_35, v_36}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_scoped{v_34, v_3, v_6}}, v_1000320 => +v_1000317 = template_unbox(BIR.Descriptor, v_1000320); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_scoped{v_35, Nat.add(v_3, 1n), cps_provider_1_NfRenaming{v_36, v_3} <> v_6}}, v_1000319 => +v_1000318 = template_unbox(BIR.Descriptor, v_1000319); TemplateFinished{TemplateValue{BIR.DescriptorArrow{{v_33 : BIR.Quantity}, v_1000317, v_1000318}}}}}
    case cps_provider_1_NfClosure{v_42, v_43, v_44}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_all_scoped{v_44, v_3, v_6}}, False{}, v_1000323 => template_body_cps_provider_1_materialize_all_scoped(v_44, v_3, v_6), v_1000322 => +v_1000321 = template_unbox(List<&2, BIR.Descriptor>, v_1000322); TemplateFinished{TemplateValue{BIR.DescriptorLet{v_1000321, BIR.DescriptorLambda{v_42, v_43}}}}}

def template_body_cps_provider_1_materialize_at(v_1: cps_provider_1_NfVal, +v_3: Nat) -> TemplateProgress<BIR.Descriptor>:
  template_body_cps_provider_1_materialize_scoped(v_1, v_3, [])

def template_body_cps_provider_1_materialize(v_1: cps_provider_1_NfVal) -> TemplateProgress<BIR.Descriptor>:
  template_body_cps_provider_1_materialize_at(v_1, 0n)

def template_body_cps_provider_1_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_1_NfVal>, +v_5: Nat) -> TemplateProgress<BIR.Descriptor>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{v_0}}
    case +v_1000627 <> v_1000628:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_all_at{v_3, v_5}}, False{}, v_1000629 => template_body_cps_provider_1_materialize_all_at(v_3, v_5), v_1000630 => +v_1000631 = template_unbox(List<&2, BIR.Descriptor>, v_1000630); TemplateFinished{TemplateValue{BIR.DescriptorLet{v_1000631, v_0}}}}

def template_body_cps_provider_1_status_combine(v_1: cps_provider_1_NfStatus, v_3: cps_provider_1_NfStatus) -> TemplateProgress<cps_provider_1_NfStatus>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_status_combine(v_1, v_3)}}

def template_match_117(v_1000331: Bool, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_1_NfVal>, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_NfStatus>:
  match v_1000331:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfStatusNo{}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_20, v_24}}, v_1000335 => +v_1000332 = template_unbox(cps_provider_1_NfStatus, v_1000335); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_11, v_13}}, v_1000334 => +v_1000333 = template_unbox(cps_provider_1_NfStatus, v_1000334); TemplateFinished{TemplateValue{template_pure_cps_provider_1_status_combine(v_1000332, v_1000333)}}}}

def template_match_118(+v_12: cps_provider_1_NfVal, v_19: String, v_20: List<&2, BIR.DescriptorPattern>, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_NfStatus>:
  match v_12:
    case cps_provider_1_NfCtor{v_23, v_24}:
      v_1000331 = {String.eq(v_19, v_23) : Bool}
      template_match_117(v_1000331, v_20, v_24, v_11, v_13)
    case cps_provider_1_NfMissing{v_29}:
      v_1000336 = {cps_provider_1_NfStatusMaybe{} : cps_provider_1_NfStatus}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_11, v_13}}, v_1000338 => +v_1000337 = template_unbox(cps_provider_1_NfStatus, v_1000338); TemplateFinished{TemplateValue{template_pure_cps_provider_1_status_combine(v_1000336, v_1000337)}}}
    case cps_provider_1_NfOther{v_33}:
      v_1000339 = {cps_provider_1_NfStatusMaybe{} : cps_provider_1_NfStatus}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_11, v_13}}, v_1000341 => +v_1000340 = template_unbox(cps_provider_1_NfStatus, v_1000341); TemplateFinished{TemplateValue{template_pure_cps_provider_1_status_combine(v_1000339, v_1000340)}}}
    case cps_provider_1_NfBinder{v_37}:
      v_1000342 = {cps_provider_1_NfStatusMaybe{} : cps_provider_1_NfStatus}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_11, v_13}}, v_1000344 => +v_1000343 = template_unbox(cps_provider_1_NfStatus, v_1000344); TemplateFinished{TemplateValue{template_pure_cps_provider_1_status_combine(v_1000342, v_1000343)}}}
    case cps_provider_1_NfArrow{v_44, v_45, v_46, v_47}:
      v_1000345 = {cps_provider_1_NfStatusMaybe{} : cps_provider_1_NfStatus}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_11, v_13}}, v_1000347 => +v_1000346 = template_unbox(cps_provider_1_NfStatus, v_1000347); TemplateFinished{TemplateValue{template_pure_cps_provider_1_status_combine(v_1000345, v_1000346)}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_NfStatusNo{}}}

def template_match_119(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_1_NfVal>, +v_12: cps_provider_1_NfVal) -> TemplateProgress<cps_provider_1_NfStatus>:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_11, v_13}}, v_1000330 => +v_1000329 = template_unbox(cps_provider_1_NfStatus, v_1000330); TemplateFinished{TemplateValue{v_1000329}}}
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      template_match_118(v_12, v_19, v_20, v_11, v_13)

def template_body_cps_provider_1_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_NfStatus>:
  match v_1, v_4:
    case [], []:
      TemplateFinished{TemplateValue{cps_provider_1_NfStatusOk{}}}
    case +v_10 <> v_11, +v_12 <> v_13:
      template_match_119(v_10, v_11, v_13, v_12)
    case _, _:
      TemplateFinished{TemplateValue{cps_provider_1_NfStatusNo{}}}

def template_match_121(+v_13: cps_provider_1_NfVal, v_21: List<&2, BIR.DescriptorPattern>, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_13:
    case cps_provider_1_NfCtor{v_24, v_25}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_values{v_21, v_25}}, v_1000355 => +v_1000351 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000355); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_values{v_12, v_14}}, v_1000354 => +v_1000352 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000354); template_body_cps_provider_1_append_vals(v_1000351, v_1000352)}}
    case _:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_values{v_12, v_14}}, v_1000357 => +v_1000356 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000357); TemplateFinished{TemplateValue{v_1000356}}}

def template_match_122(+v_11: BIR.DescriptorPattern, +v_13: cps_provider_1_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_values{v_12, v_14}}, v_1000350 => +v_1000349 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000350); TemplateFinished{TemplateValue{{v_13 : cps_provider_1_NfVal} <> v_1000349}}}
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      template_match_121(v_13, v_21, v_12, v_14)

def template_body_cps_provider_1_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<List<&2, cps_provider_1_NfVal>>:
  match v_1, v_4:
    case [], []:
      TemplateFinished{TemplateValue{[]}}
    case +v_11 <> v_12, +v_13 <> v_14:
      template_match_122(v_11, v_13, v_12, v_14)
    case _, _:
      TemplateFinished{TemplateValue{[]}}

def template_match_124(+v_1000358: cps_provider_1_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_NfBind>:
  match v_1000358:
    case cps_provider_1_NfStatusOk{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_values{v_1, v_4}}, False{}, v_1000361 => template_body_cps_provider_1_bind_values(v_1, v_4), v_1000360 => +v_1000359 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000360); TemplateFinished{TemplateValue{cps_provider_1_NfBound{v_1000359}}}}
    case cps_provider_1_NfStatusNo{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfMismatch{}}}
    case cps_provider_1_NfStatusMaybe{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfUnknown{}}}

def template_body_cps_provider_1_bind_patterns(+v_1: List<&2, BIR.DescriptorPattern>, +v_4: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_NfBind>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_status{v_1, v_4}}, False{}, v_1000363 => template_body_cps_provider_1_bind_status(v_1, v_4), v_1000362 => +v_1000358 = template_unbox(cps_provider_1_NfStatus, v_1000362); template_match_124(v_1000358, v_1, v_4)}

def template_match_125(v_1000364: Bool, +v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000364:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{"the type expression did not normalize within its reduction budget"}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1, v_2, v_5, v_7, Nat.sub(v_9, 1n)}}, v_1000366 => +v_1000365 = template_unbox(cps_provider_1_Nf, v_1000366); TemplateFinished{TemplateValue{v_1000365}}}

def template_body_cps_provider_1_nf(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  v_1000364 = {Nat.is_eq(v_9, 0n) : Bool}
  template_match_125(v_1000364, v_1, v_2, v_5, v_7, v_9)

def template_match_126(v_1000367: Bool, +v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000367:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{"the type expression did not normalize within its reduction budget"}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor_step{v_1, v_2, v_5, v_7, v_9}}, v_1000369 => +v_1000368 = template_unbox(cps_provider_1_Nf, v_1000369); TemplateFinished{TemplateValue{v_1000368}}}

def template_body_cps_provider_1_nf_descriptor(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  v_1000367 = {Nat.is_eq(v_9, 0n) : Bool}
  template_match_126(v_1000367, v_1, v_2, v_5, v_7, v_9)

def template_match_127(+v_1000371: cps_provider_1_Nf, v_2: BIR.Quantity, v_17: cps_provider_1_NfVal, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000371:
    case cps_provider_1_NfFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_21}}}
    case cps_provider_1_NfOk{v_23}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfArrow{v_2, v_17, v_23, v_9}}}}

def template_match_128(+v_1000370: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat, v_2: BIR.Quantity) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000370:
    case cps_provider_1_NfFail{v_15}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_15}}}
    case cps_provider_1_NfOk{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_4, List.append(&2, cps_provider_1_NfVal, v_7, [cps_provider_1_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11}}, False{}, v_1000373 => template_body_cps_provider_1_nf(v_1, v_4, List.append(&2, cps_provider_1_NfVal, v_7, [cps_provider_1_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11), v_1000372 => +v_1000371 = template_unbox(cps_provider_1_Nf, v_1000372); template_match_127(v_1000371, v_2, v_17, v_9)}

def template_body_cps_provider_1_nf_arrow(+v_1: cps_provider_1_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_3, v_7, v_9, v_11}}, False{}, v_1000375 => template_body_cps_provider_1_nf(v_1, v_3, v_7, v_9, v_11), v_1000374 => +v_1000370 = template_unbox(cps_provider_1_Nf, v_1000374); template_match_128(v_1000370, v_1, v_4, v_7, v_9, v_11, v_2)}

def template_match_129(+v_1000385: cps_provider_1_Nf) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000385:
    case cps_provider_1_NfOk{v_24}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfKind{v_24}}}}
    case cps_provider_1_NfFail{v_26}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_26}}}

def template_match_130(+v_1000392: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, v_45: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000392:
    case cps_provider_1_NfListOk{v_49}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_named{v_1, v_45, v_49, v_7, v_9}}, v_1000394 => +v_1000393 = template_unbox(cps_provider_1_Nf, v_1000394); TemplateFinished{TemplateValue{v_1000393}}}
    case cps_provider_1_NfListFail{v_52}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_52}}}

def template_match_131(+v_1000396: cps_provider_1_NfList, v_55: String) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000396:
    case cps_provider_1_NfListOk{v_59}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfCtor{v_55, v_59}}}}
    case cps_provider_1_NfListFail{v_61}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_61}}}

def template_match_132(+v_1000399: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_68: cps_provider_1_NfVal, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000399:
    case cps_provider_1_NfOk{v_71}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_apply{v_1, v_68, [v_71], v_7, v_9}}, v_1000401 => +v_1000400 = template_unbox(cps_provider_1_Nf, v_1000401); TemplateFinished{TemplateValue{v_1000400}}}
    case cps_provider_1_NfFail{v_74}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_74}}}

def template_match_133(+v_1000398: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_65: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000398:
    case cps_provider_1_NfOk{v_68}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_65, v_5, v_7, v_9}}, False{}, v_1000403 => template_body_cps_provider_1_nf(v_1, v_65, v_5, v_7, v_9), v_1000402 => +v_1000399 = template_unbox(cps_provider_1_Nf, v_1000402); template_match_132(v_1000399, v_1, v_68, v_7, v_9)}
    case cps_provider_1_NfFail{v_76}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_76}}}

def template_match_134(+v_1000406: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_82: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, v_80: Nat, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000406:
    case cps_provider_1_NfOk{v_85}:
      +v_1000407 = {v_1 : cps_provider_1_NfContext}
      v_1000408 = {v_82 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_insert_before{v_5, Nat.sub(List.length(&2, cps_provider_1_NfVal, v_5), v_80), v_85}}, False{}, v_1000414 => template_body_cps_provider_1_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_1_NfVal, v_5), v_80), v_85), v_1000413 => +v_1000409 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000413); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1000407, v_1000408, v_1000409, v_7, Nat.sub(v_9, 1n)}}, False{}, v_1000412 => template_body_cps_provider_1_nf_descriptor(v_1000407, v_1000408, v_1000409, v_7, Nat.sub(v_9, 1n)), v_1000411 => +v_1000410 = template_unbox(cps_provider_1_Nf, v_1000411); TemplateFinished{TemplateValue{v_1000410}}}}
    case cps_provider_1_NfFail{v_90}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_90}}}

def template_match_135(+v_1000417: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, v_94: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000417:
    case cps_provider_1_NfListOk{v_97}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1, v_94, List.append(&2, cps_provider_1_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1000420 => template_body_cps_provider_1_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_1_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n)), v_1000419 => +v_1000418 = template_unbox(cps_provider_1_Nf, v_1000419); TemplateFinished{TemplateValue{v_1000418}}}
    case cps_provider_1_NfListFail{v_101}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_101}}}

def template_match_136(+v_1000423: cps_provider_1_NfBind, +v_1: cps_provider_1_NfContext, v_107: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000423:
    case cps_provider_1_NfBound{v_113}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1, v_107, List.append(&2, cps_provider_1_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1000426 => template_body_cps_provider_1_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_1_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n)), v_1000425 => +v_1000424 = template_unbox(cps_provider_1_Nf, v_1000425); TemplateFinished{TemplateValue{v_1000424}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_12, v_5, v_7}}, False{}, v_1000429 => template_body_cps_provider_1_reify_env(v_12, v_5, v_7), v_1000428 => +v_1000427 = template_unbox(BIR.Descriptor, v_1000428); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000427}}}}}

def template_match_137(+v_1000422: cps_provider_1_NfList, v_105: List<&2, BIR.DescriptorPattern>, +v_1: cps_provider_1_NfContext, v_107: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000422:
    case cps_provider_1_NfListOk{v_110}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_patterns{v_105, v_110}}, False{}, v_1000431 => template_body_cps_provider_1_bind_patterns(v_105, v_110), v_1000430 => +v_1000423 = template_unbox(cps_provider_1_NfBind, v_1000430); template_match_136(v_1000423, v_1, v_107, v_5, v_7, v_9, v_12)}
    case cps_provider_1_NfListFail{v_120}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_120}}}

def template_match_138(+v_1000433: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, v_124: List<&2, BIR.Descriptor>, +v_5: List<&2, cps_provider_1_NfVal>, +v_12: BIR.Descriptor, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000433:
    case cps_provider_1_NfListOk{v_127}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_cases{v_1, v_124, v_127, v_5, v_12, v_7, v_9}}, v_1000435 => +v_1000434 = template_unbox(cps_provider_1_Nf, v_1000435); TemplateFinished{TemplateValue{v_1000434}}}
    case cps_provider_1_NfListFail{v_130}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_130}}}

def template_match_139(+v_1000440: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_139: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000440:
    case cps_provider_1_NfOk{v_142}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1, v_139, List.append(&2, cps_provider_1_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1000443 => template_body_cps_provider_1_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_1_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n)), v_1000442 => +v_1000441 = template_unbox(cps_provider_1_Nf, v_1000442); TemplateFinished{TemplateValue{v_1000441}}}
    case cps_provider_1_NfFail{v_146}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_146}}}

def template_match_140(+v_1000456: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, v_170: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000456:
    case cps_provider_1_NfListOk{v_175}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_named{v_1, v_170, v_175, v_7, v_9}}, v_1000458 => +v_1000457 = template_unbox(cps_provider_1_Nf, v_1000458); TemplateFinished{TemplateValue{v_1000457}}}
    case cps_provider_1_NfListFail{v_178}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_178}}}

def template_match_141(+v_1000460: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, v_182: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000460:
    case cps_provider_1_NfListOk{v_187}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_named{v_1, v_182, v_187, v_7, v_9}}, v_1000462 => +v_1000461 = template_unbox(cps_provider_1_Nf, v_1000462); TemplateFinished{TemplateValue{v_1000461}}}
    case cps_provider_1_NfListFail{v_190}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_190}}}

def template_match_142(+v_12: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_1: cps_provider_1_NfContext, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_12:
    case BIR.DescriptorNull{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_12, v_5, v_7}}, False{}, v_1000378 => template_body_cps_provider_1_reify_env(v_12, v_5, v_7), v_1000377 => +v_1000376 = template_unbox(BIR.Descriptor, v_1000377); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000376}}}}}
    case BIR.DescriptorParameter{v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_val_at{v_5, v_15, v_12}}, False{}, v_1000381 => template_body_cps_provider_1_val_at(v_5, v_15, v_12), v_1000380 => +v_1000379 = template_unbox(cps_provider_1_NfVal, v_1000380); TemplateFinished{TemplateValue{cps_provider_1_NfOk{v_1000379}}}}
    case BIR.DescriptorQuantityKind{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_12, v_5, v_7}}, False{}, v_1000384 => template_body_cps_provider_1_reify_env(v_12, v_5, v_7), v_1000383 => +v_1000382 = template_unbox(BIR.Descriptor, v_1000383); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000382}}}}}
    case BIR.DescriptorQuantity{v_19}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfQuantity{v_19}}}}
    case BIR.DescriptorKind{v_21}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_21, v_5, v_7, v_9}}, False{}, v_1000387 => template_body_cps_provider_1_nf(v_1, v_21, v_5, v_7, v_9), v_1000386 => +v_1000385 = template_unbox(cps_provider_1_Nf, v_1000386); template_match_129(v_1000385)}
    case BIR.DescriptorMinimum{v_29, v_30}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_12, v_5, v_7}}, False{}, v_1000390 => template_body_cps_provider_1_reify_env(v_12, v_5, v_7), v_1000389 => +v_1000388 = template_unbox(BIR.Descriptor, v_1000389); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000388}}}}}
    case BIR.DescriptorArrow{v_35, v_36, v_37}:
      template_body_cps_provider_1_nf_arrow(v_1, v_35, v_36, v_37, v_5, v_7, v_9)
    case BIR.DescriptorLambda{v_41, v_42}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfClosure{v_41, v_42, v_5}}}}
    case BIR.DescriptorRef{v_45, v_46}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_46, v_5, v_7, v_9}}, v_1000395 => +v_1000392 = template_unbox(cps_provider_1_NfList, v_1000395); template_match_130(v_1000392, v_1, v_45, v_7, v_9)}
    case BIR.DescriptorConstructor{v_55, v_56}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_56, v_5, v_7, v_9}}, v_1000397 => +v_1000396 = template_unbox(cps_provider_1_NfList, v_1000397); template_match_131(v_1000396, v_55)}
    case BIR.DescriptorApplication{v_64, v_65}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_64, v_5, v_7, v_9}}, False{}, v_1000405 => template_body_cps_provider_1_nf(v_1, v_64, v_5, v_7, v_9), v_1000404 => +v_1000398 = template_unbox(cps_provider_1_Nf, v_1000404); template_match_133(v_1000398, v_1, v_65, v_5, v_7, v_9)}
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_81, v_5, v_7, v_9}}, False{}, v_1000416 => template_body_cps_provider_1_nf(v_1, v_81, v_5, v_7, v_9), v_1000415 => +v_1000406 = template_unbox(cps_provider_1_Nf, v_1000415); template_match_134(v_1000406, v_1, v_82, v_5, v_80, v_7, v_9)}
    case BIR.DescriptorLet{v_93, v_94}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_93, v_5, v_7, v_9}}, v_1000421 => +v_1000417 = template_unbox(cps_provider_1_NfList, v_1000421); template_match_135(v_1000417, v_1, v_94, v_5, v_7, v_9)}
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_106, v_5, v_7, v_9}}, v_1000432 => +v_1000422 = template_unbox(cps_provider_1_NfList, v_1000432); template_match_137(v_1000422, v_105, v_1, v_107, v_5, v_7, v_9, v_12)}
    case BIR.DescriptorMatch{v_123, v_124}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_123, v_5, v_7, v_9}}, v_1000436 => +v_1000433 = template_unbox(cps_provider_1_NfList, v_1000436); template_match_138(v_1000433, v_1, v_124, v_5, v_12, v_7, v_9)}
    case BIR.DescriptorCase{v_133, v_134}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_12, v_5, v_7}}, False{}, v_1000439 => template_body_cps_provider_1_reify_env(v_12, v_5, v_7), v_1000438 => +v_1000437 = template_unbox(BIR.Descriptor, v_1000438); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000437}}}}}
    case BIR.DescriptorBind{v_138, v_139}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_138, v_5, v_7, v_9}}, False{}, v_1000445 => template_body_cps_provider_1_nf(v_1, v_138, v_5, v_7, v_9), v_1000444 => +v_1000440 = template_unbox(cps_provider_1_Nf, v_1000444); template_match_139(v_1000440, v_1, v_139, v_5, v_7, v_9)}
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_12, v_5, v_7}}, False{}, v_1000448 => template_body_cps_provider_1_reify_env(v_12, v_5, v_7), v_1000447 => +v_1000446 = template_unbox(BIR.Descriptor, v_1000447); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000446}}}}}
    case BIR.DescriptorReflexivity{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_12, v_5, v_7}}, False{}, v_1000451 => template_body_cps_provider_1_reify_env(v_12, v_5, v_7), v_1000450 => +v_1000449 = template_unbox(BIR.Descriptor, v_1000450); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000449}}}}}
    case BIR.DescriptorFailure{v_156}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_156}}}
    case BIR.DescriptorFill{v_159, v_160}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_apply_args{v_1, v_159, v_160, v_5, v_12, v_7, v_9}}, v_1000453 => +v_1000452 = template_unbox(cps_provider_1_Nf, v_1000453); TemplateFinished{TemplateValue{v_1000452}}}
    case BIR.DescriptorPlus{v_164, v_165}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_apply_args{v_1, v_164, v_165, v_5, v_12, v_7, v_9}}, v_1000455 => +v_1000454 = template_unbox(cps_provider_1_Nf, v_1000455); TemplateFinished{TemplateValue{v_1000454}}}
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_172, v_5, v_7, v_9}}, v_1000459 => +v_1000456 = template_unbox(cps_provider_1_NfList, v_1000459); template_match_140(v_1000456, v_1, v_170, v_7, v_9)}
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_184, v_5, v_7, v_9}}, v_1000463 => +v_1000460 = template_unbox(cps_provider_1_NfList, v_1000463); template_match_141(v_1000460, v_1, v_182, v_7, v_9)}

def template_body_cps_provider_1_nf_descriptor_step(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  template_match_142(v_2, v_5, v_7, v_1, v_9)

def template_match_143(+v_1000465: cps_provider_1_NfList, v_20: cps_provider_1_NfVal) -> TemplateProgress<cps_provider_1_NfList>:
  match v_1000465:
    case cps_provider_1_NfListFail{v_23}:
      TemplateFinished{TemplateValue{cps_provider_1_NfListFail{v_23}}}
    case cps_provider_1_NfListOk{v_25}:
      TemplateFinished{TemplateValue{cps_provider_1_NfListOk{v_20 <> v_25}}}

def template_match_144(+v_1000464: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_15: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_1_NfList>:
  match v_1000464:
    case cps_provider_1_NfFail{v_18}:
      TemplateFinished{TemplateValue{cps_provider_1_NfListFail{v_18}}}
    case cps_provider_1_NfOk{v_20}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_15, v_6, v_8, v_10}}, v_1000466 => +v_1000465 = template_unbox(cps_provider_1_NfList, v_1000466); template_match_143(v_1000465, v_20)}

def template_body_cps_provider_1_nf_all(+v_1: cps_provider_1_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_1_NfList>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_NfListOk{[]}}}
    case +v_1000632 <> v_1000633:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_1000632, v_6, v_8, v_10}}, False{}, v_1000634 => template_body_cps_provider_1_nf(v_1, v_1000632, v_6, v_8, v_10), v_1000635 => +v_1000636 = template_unbox(cps_provider_1_Nf, v_1000635); template_match_144(v_1000636, v_1, v_1000633, v_6, v_8, v_10)}

def template_match_146(+v_1000470: cps_provider_1_NfList, +v_1: cps_provider_1_NfContext, v_18: cps_provider_1_NfVal, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000470:
    case cps_provider_1_NfListFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_21}}}
    case cps_provider_1_NfListOk{v_23}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_apply_source{v_1, v_18, v_23, v_8, v_10, v_12}}, v_1000472 => +v_1000471 = template_unbox(cps_provider_1_Nf, v_1000472); TemplateFinished{TemplateValue{v_1000471}}}

def template_match_147(+v_1000469: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_1_NfVal>, +v_10: Nat, +v_12: Nat, v_8: BIR.Descriptor) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000469:
    case cps_provider_1_NfFail{v_16}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_16}}}
    case cps_provider_1_NfOk{v_18}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_all{v_1, v_4, v_7, v_10, v_12}}, False{}, v_1000474 => template_body_cps_provider_1_nf_all(v_1, v_4, v_7, v_10, v_12), v_1000473 => +v_1000470 = template_unbox(cps_provider_1_NfList, v_1000473); template_match_146(v_1000470, v_1, v_18, v_8, v_10, v_12)}

def template_body_cps_provider_1_nf_apply_args(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_1_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_2, v_7, v_10, v_12}}, False{}, v_1000476 => template_body_cps_provider_1_nf(v_1, v_2, v_7, v_10, v_12), v_1000475 => +v_1000469 = template_unbox(cps_provider_1_Nf, v_1000475); template_match_147(v_1000469, v_1, v_4, v_7, v_10, v_12, v_8)}

def template_body_cps_provider_1_nf_apply_source(+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, +v_6: List<&2, cps_provider_1_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{v_3}}}
    case v_1000637:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_apply{v_1, v_3, v_6, v_9, v_11}}, v_1000638 => +v_1000639 = template_unbox(cps_provider_1_Nf, v_1000638); TemplateFinished{TemplateValue{v_1000639}}}

def template_match_149(+v_1000479: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_15: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000479:
    case cps_provider_1_NfFail{v_18}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_18}}}
    case cps_provider_1_NfOk{v_20}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_apply{v_1, v_20, v_15, v_8, Nat.sub(v_10, 1n)}}, v_1000481 => +v_1000480 = template_unbox(cps_provider_1_Nf, v_1000481); TemplateFinished{TemplateValue{v_1000480}}}

def template_body_cps_provider_1_nf_apply(+v_1: cps_provider_1_NfContext, v_3: cps_provider_1_NfVal, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{v_3}}}
    case +v_1000640 <> v_1000641:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_apply_one{v_1, v_3, v_1000640, v_8, Nat.sub(v_10, 1n)}}, v_1000642 => +v_1000643 = template_unbox(cps_provider_1_Nf, v_1000642); template_match_149(v_1000643, v_1, v_1000641, v_8, v_10)}

def template_body_cps_provider_1_nf_apply_one(+v_1: cps_provider_1_NfContext, +v_3: cps_provider_1_NfVal, +v_5: cps_provider_1_NfVal, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_3:
    case cps_provider_1_NfType{v_1000644, v_1000645}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_named{v_1, v_1000644, List.append(&2, cps_provider_1_NfVal, v_1000645, [v_5]), v_7, Nat.sub(v_9, 1n)}}, v_1000646 => +v_1000647 = template_unbox(cps_provider_1_Nf, v_1000646); TemplateFinished{TemplateValue{v_1000647}}}
    case cps_provider_1_NfClosure{v_1000648, v_1000649, v_1000650}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1, v_1000649, List.append(&2, cps_provider_1_NfVal, v_1000650, [v_5]), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1000651 => template_body_cps_provider_1_nf_descriptor(v_1, v_1000649, List.append(&2, cps_provider_1_NfVal, v_1000650, [v_5]), v_7, Nat.sub(v_9, 1n)), v_1000652 => +v_1000653 = template_unbox(cps_provider_1_Nf, v_1000652); TemplateFinished{TemplateValue{v_1000653}}}
    case cps_provider_1_NfCtor{v_1000654, v_1000655}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{String.append("the constructor `", String.append(v_1000654, "` is applied to an argument"))}}}
    case cps_provider_1_NfQuantity{v_1000656}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{"a quantity is applied to an argument"}}}
    case cps_provider_1_NfKind{v_1000657}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{"a kind is applied to an argument"}}}
    case cps_provider_1_NfOther{v_1000658}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_at{v_5, v_7}}, False{}, v_1000660 => template_body_cps_provider_1_materialize_at(v_5, v_7), v_1000661 => +v_1000662 = template_unbox(BIR.Descriptor, v_1000661); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{BIR.DescriptorApplication{{v_1000658 : BIR.Descriptor}, v_1000662}}}}}}
    case cps_provider_1_NfArrow{v_1000663, v_1000664, v_1000665, v_1000666}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_at{v_3, v_7}}, False{}, v_1000667 => template_body_cps_provider_1_materialize_at(v_3, v_7), v_1000668 => +v_1000669 = template_unbox(BIR.Descriptor, v_1000668); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_at{v_5, v_7}}, False{}, v_1000670 => template_body_cps_provider_1_materialize_at(v_5, v_7), v_1000671 => +v_1000672 = template_unbox(BIR.Descriptor, v_1000671); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{BIR.DescriptorApplication{v_1000669, v_1000672}}}}}}}
    case cps_provider_1_NfMissing{v_1000673}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_at{v_5, v_7}}, False{}, v_1000675 => template_body_cps_provider_1_materialize_at(v_5, v_7), v_1000676 => +v_1000677 = template_unbox(BIR.Descriptor, v_1000676); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfMissing{BIR.DescriptorApplication{{v_1000673 : BIR.Descriptor}, v_1000677}}}}}}
    case cps_provider_1_NfBinder{v_1000678}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_at{v_3, v_7}}, False{}, v_1000679 => template_body_cps_provider_1_materialize_at(v_3, v_7), v_1000680 => +v_1000681 = template_unbox(BIR.Descriptor, v_1000680); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_materialize_at{v_5, v_7}}, False{}, v_1000682 => template_body_cps_provider_1_materialize_at(v_5, v_7), v_1000683 => +v_1000684 = template_unbox(BIR.Descriptor, v_1000683); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfMissing{BIR.DescriptorApplication{v_1000681, v_1000684}}}}}}}

def template_body_cps_provider_1_intrinsic_io(+v_0: BIR.TypeFunction) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_intrinsic_io(v_0)}}

def template_match_152(v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_Nf>:
  match v_4:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfType{v_18, v_7}}}}

def template_body_cps_provider_1_nf_named_io(v_1: Bool, +v_3: cps_provider_1_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1:
    case True{}:
      template_match_152(v_4, v_7)
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_reduce{v_3, v_4, v_7, v_9, Nat.sub(v_11, 1n)}}, v_1000685 => +v_1000686 = template_unbox(cps_provider_1_Nf, v_1000685); TemplateFinished{TemplateValue{v_1000686}}}

def template_match_154(+v_1000514: Maybe<&2, BIR.Family>, v_6: List<&2, cps_provider_1_NfVal>, +v_3: String) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000514:
    case Some{v_25}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_family{v_25, v_6}}, v_1000516 => +v_1000515 = template_unbox(cps_provider_1_Nf, v_1000516); TemplateFinished{TemplateValue{v_1000515}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfType{v_3, v_6}}}}

def template_match_155(+v_1000510: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_1_NfContext, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat, +v_3: String, v_14: Map<&2, BIR.Family>) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000510:
    case Some{v_18}:
      +v_20 = v_18
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_named_io{template_pure_cps_provider_1_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10}}, False{}, v_1000513 => template_body_cps_provider_1_nf_named_io(template_pure_cps_provider_1_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10), v_1000512 => +v_1000511 = template_unbox(cps_provider_1_Nf, v_1000512); TemplateFinished{TemplateValue{v_1000511}}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_of{v_3, v_14}}, False{}, v_1000518 => template_body_cps_provider_1_family_of(v_3, v_14), v_1000517 => +v_1000514 = template_unbox(Maybe<&2, BIR.Family>, v_1000517); template_match_154(v_1000514, v_6, v_3)}

def template_body_cps_provider_1_nf_named(+v_1: cps_provider_1_NfContext, +v_3: String, v_6: List<&2, cps_provider_1_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1:
    case cps_provider_1_NfContext{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_function_of{v_3, v_15}}, False{}, v_1000520 => template_body_cps_provider_1_function_of(v_3, v_15), v_1000519 => +v_1000510 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1000519); template_match_155(v_1000510, v_1, v_6, v_8, v_10, v_3, v_14)}

def template_body_cps_provider_1_nf_arity(+v_2: List<&2, cps_provider_1_NfVal>, +v_4: Nat, +v_6: Nat) -> TemplateProgress<cps_provider_1_NfArity>:
  TemplateFinished{TemplateValue{cps_provider_1_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_1_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_1_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_1_NfVal, v_2), v_6)}}}

def template_match_157(v_0: BIR.Family, +v_6: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_Nf>:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_arity{v_6, v_20, v_17}}, False{}, v_1000525 => template_body_cps_provider_1_nf_arity(v_6, v_20, v_17), v_1000524 => +v_1000521 = template_unbox(cps_provider_1_NfArity, v_1000524); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_family_apply{v_1000521, v_13, v_20, v_6}}, v_1000523 => +v_1000522 = template_unbox(cps_provider_1_Nf, v_1000523); TemplateFinished{TemplateValue{v_1000522}}}}

def template_body_cps_provider_1_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_Nf>:
  template_match_157(v_0, v_3)

def template_match_158(v_15: Bool, v_3: String, v_8: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_Nf>:
  match v_15:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfType{v_3, v_8}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}}}

def template_match_159(v_14: Bool, v_3: String, v_8: List<&2, cps_provider_1_NfVal>, v_15: Bool) -> TemplateProgress<cps_provider_1_Nf>:
  match v_14:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfType{v_3, v_8}}}}
    case False{}:
      template_match_158(v_15, v_3, v_8)

def template_match_160(v_13: Bool, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_1_NfVal>, v_14: Bool, v_15: Bool) -> TemplateProgress<cps_provider_1_Nf>:
  match v_13:
    case True{}:
      v_1000526 = {v_3 : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_quantity_markers{v_5}}, False{}, v_1000529 => template_body_cps_provider_1_quantity_markers(v_5), v_1000528 => +v_1000527 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000528); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfType{v_1000526, List.append(&2, cps_provider_1_NfVal, v_1000527, v_8)}}}}}
    case False{}:
      template_match_159(v_14, v_3, v_8, v_15)

def template_body_cps_provider_1_nf_family_apply(v_1: cps_provider_1_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1:
    case cps_provider_1_NfArity{v_13, v_14, v_15}:
      template_match_160(v_13, v_3, v_5, v_8, v_14, v_15)

def template_match_162(v_2: BIR.TypeFunction, +v_12: List<&2, cps_provider_1_NfVal>, +v_1: cps_provider_1_NfContext, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_2:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      +v_24 = v_20
      +v_26 = v_21
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_arity{v_12, v_24, v_26}}, False{}, v_1000534 => template_body_cps_provider_1_nf_arity(v_12, v_24, v_26), v_1000533 => +v_1000530 = template_unbox(cps_provider_1_NfArity, v_1000533); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_reduce_apply{v_1000530, v_1, v_18, v_24, v_26, v_22, v_12, v_7, v_9}}, v_1000532 => +v_1000531 = template_unbox(cps_provider_1_Nf, v_1000532); TemplateFinished{TemplateValue{v_1000531}}}}

def template_body_cps_provider_1_nf_reduce(+v_1: cps_provider_1_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  template_match_162(v_2, v_5, v_1, v_7, v_9)

def template_match_163(v_24: Bool, v_5: String, +v_13: List<&2, cps_provider_1_NfVal>) -> TemplateProgress<cps_provider_1_Nf>:
  match v_24:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfType{v_5, v_13}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}}}

def template_match_164(v_23: Bool, +v_3: cps_provider_1_NfContext, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_1_NfVal>, +v_9: Nat, +v_15: Nat, +v_17: Nat, v_24: Bool, v_5: String) -> TemplateProgress<cps_provider_1_Nf>:
  match v_23:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_first_vals{v_13, v_9}}, False{}, v_1000551 => template_body_cps_provider_1_first_vals(v_13, v_9), v_1000550 => +v_1000544 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000550); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_drop_vals{v_13, v_9}}, False{}, v_1000549 => template_body_cps_provider_1_drop_vals(v_13, v_9), v_1000548 => +v_1000545 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000548); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_reduce_body{{v_3 : cps_provider_1_NfContext}, {v_10 : BIR.Descriptor}, v_1000544, v_1000545, v_15, Nat.sub(v_17, 1n)}}, v_1000547 => +v_1000546 = template_unbox(cps_provider_1_Nf, v_1000547); TemplateFinished{TemplateValue{v_1000546}}}}}
    case False{}:
      template_match_163(v_24, v_5, v_13)

def template_match_165(v_22: Bool, +v_3: cps_provider_1_NfContext, v_10: BIR.Descriptor, v_7: Nat, +v_13: List<&2, cps_provider_1_NfVal>, +v_15: Nat, +v_17: Nat, v_23: Bool, +v_9: Nat, v_24: Bool, v_5: String) -> TemplateProgress<cps_provider_1_Nf>:
  match v_22:
    case True{}:
      v_1000536 = {v_10 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_quantity_markers{v_7}}, False{}, v_1000541 => template_body_cps_provider_1_quantity_markers(v_7), v_1000540 => +v_1000537 = template_unbox(List<&2, cps_provider_1_NfVal>, v_1000540); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_reduce_body{{v_3 : cps_provider_1_NfContext}, v_1000536, List.append(&2, cps_provider_1_NfVal, v_1000537, v_13), [], v_15, Nat.sub(v_17, 1n)}}, v_1000539 => +v_1000538 = template_unbox(cps_provider_1_Nf, v_1000539); TemplateFinished{TemplateValue{v_1000538}}}}
    case False{}:
      template_match_164(v_23, v_3, v_10, v_13, v_9, v_15, v_17, v_24, v_5)

def template_body_cps_provider_1_nf_reduce_apply(v_1: cps_provider_1_NfArity, +v_3: cps_provider_1_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_1_NfVal>, +v_15: Nat, +v_17: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1:
    case cps_provider_1_NfArity{v_1000687, v_1000688, v_1000689}:
      template_match_165(v_1000687, v_3, v_10, v_7, v_13, v_15, v_17, v_1000688, v_9, v_1000689, v_5)

def template_match_167(+v_1000552: cps_provider_1_Nf, +v_1: cps_provider_1_NfContext, v_8: List<&2, cps_provider_1_NfVal>, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000552:
    case cps_provider_1_NfFail{v_16}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_16}}}
    case cps_provider_1_NfOk{v_18}:
      template_body_cps_provider_1_nf_apply(v_1, v_18, v_8, v_10, v_12)

def template_body_cps_provider_1_nf_reduce_body(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, v_8: List<&2, cps_provider_1_NfVal>, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)}}, False{}, v_1000555 => template_body_cps_provider_1_nf_descriptor(v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)), v_1000554 => +v_1000552 = template_unbox(cps_provider_1_Nf, v_1000554); template_match_167(v_1000552, v_1, v_8, v_10, v_12)}

def template_match_168(+v_1000559: cps_provider_1_NfBind, +v_1: cps_provider_1_NfContext, v_24: BIR.Descriptor, +v_9: List<&2, cps_provider_1_NfVal>, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, v_10: BIR.Descriptor) -> TemplateProgress<cps_provider_1_Nf>:
  match v_1000559:
    case cps_provider_1_NfBound{v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_descriptor{v_1, v_24, List.append(&2, cps_provider_1_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n)}}, False{}, v_1000562 => template_body_cps_provider_1_nf_descriptor(v_1, v_24, List.append(&2, cps_provider_1_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n)), v_1000561 => +v_1000560 = template_unbox(cps_provider_1_Nf, v_1000561); TemplateFinished{TemplateValue{v_1000560}}}
    case cps_provider_1_NfMismatch{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nf_cases{v_1, v_20, v_6, v_9, v_10, v_12, v_14}}, v_1000564 => +v_1000563 = template_unbox(cps_provider_1_Nf, v_1000564); TemplateFinished{TemplateValue{v_1000563}}}
    case cps_provider_1_NfUnknown{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_10, v_9, v_12}}, False{}, v_1000567 => template_body_cps_provider_1_reify_env(v_10, v_9, v_12), v_1000566 => +v_1000565 = template_unbox(BIR.Descriptor, v_1000566); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000565}}}}}

def template_match_169(+v_19: BIR.Descriptor, +v_6: List<&2, cps_provider_1_NfVal>, +v_1: cps_provider_1_NfContext, +v_9: List<&2, cps_provider_1_NfVal>, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, v_10: BIR.Descriptor) -> TemplateProgress<cps_provider_1_Nf>:
  match v_19:
    case BIR.DescriptorCase{v_23, v_24}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_bind_patterns{v_23, v_6}}, False{}, v_1000569 => template_body_cps_provider_1_bind_patterns(v_23, v_6), v_1000568 => +v_1000559 = template_unbox(cps_provider_1_NfBind, v_1000568); template_match_168(v_1000559, v_1, v_24, v_9, v_12, v_14, v_20, v_6, v_10)}
    case BIR.DescriptorFailure{v_33}:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{v_33}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_NfFail{"descriptor match case is not a case"}}}

def template_body_cps_provider_1_nf_cases(+v_1: cps_provider_1_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_1_NfVal>, +v_9: List<&2, cps_provider_1_NfVal>, +v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> TemplateProgress<cps_provider_1_Nf>:
  match v_3:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_reify_env{v_10, v_9, v_12}}, False{}, v_1000690 => template_body_cps_provider_1_reify_env(v_10, v_9, v_12), v_1000691 => +v_1000692 = template_unbox(BIR.Descriptor, v_1000691); TemplateFinished{TemplateValue{cps_provider_1_NfOk{cps_provider_1_NfOther{v_1000692}}}}}
    case +v_1000693 <> v_1000694:
      template_match_169(v_1000693, v_6, v_1, v_9, v_12, v_14, v_1000694, v_10)

def template_match_171(+v_1000570: cps_provider_1_Nf) -> TemplateProgress<BIR.Descriptor>:
  match v_1000570:
    case cps_provider_1_NfFail{v_10}:
      TemplateFinished{TemplateValue{BIR.DescriptorFailure{v_10}}}
    case cps_provider_1_NfOk{v_12}:
      template_body_cps_provider_1_materialize_at(v_12, 0n)

def template_body_cps_provider_1_normalize(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_1_NfVal>, +v_7: Nat) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf{v_1, v_2, v_5, 0n, v_7}}, False{}, v_1000573 => template_body_cps_provider_1_nf(v_1, v_2, v_5, 0n, v_7), v_1000572 => +v_1000570 = template_unbox(cps_provider_1_Nf, v_1000572); template_match_171(v_1000570)}

def template_body_cps_provider_1_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_context{v_1, v_3}}, False{}, v_1000579 => template_body_cps_provider_1_nf_context(v_1, v_3), v_1000578 => +v_1000574 = template_unbox(cps_provider_1_NfContext, v_1000578); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize{v_1000574, v_4, [], 1024n}}, False{}, v_1000577 => template_body_cps_provider_1_normalize(v_1000574, v_4, [], 1024n), v_1000576 => +v_1000575 = template_unbox(BIR.Descriptor, v_1000576); TemplateFinished{TemplateValue{v_1000575}}}}

def template_body_cps_provider_1_normalize_in(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize{v_1, v_2, [], 1024n}}, False{}, v_1000582 => template_body_cps_provider_1_normalize(v_1, v_2, [], 1024n), v_1000581 => +v_1000580 = template_unbox(BIR.Descriptor, v_1000581); TemplateFinished{TemplateValue{v_1000580}}}

def template_body_cps_provider_1_outer_application(+v_0: BIR.Descriptor) -> TemplateProgress<Maybe<&2, cps_provider_1_NfApp>>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_outer_walk{v_0, []}}, v_1000584 => +v_1000583 = template_unbox(Maybe<&2, cps_provider_1_NfApp>, v_1000584); TemplateFinished{TemplateValue{v_1000583}}}

def template_body_cps_provider_1_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> TemplateProgress<Maybe<&2, cps_provider_1_NfApp>>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      TemplateFinished{TemplateValue{Some{cps_provider_1_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{Some{cps_provider_1_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      TemplateFinished{TemplateValue{Some{cps_provider_1_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}}}
    case BIR.DescriptorFill{v_23, v_24}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_outer_walk{v_23, List.append(&2, BIR.Descriptor, v_24, v_2)}}, v_1000586 => +v_1000585 = template_unbox(Maybe<&2, cps_provider_1_NfApp>, v_1000586); TemplateFinished{TemplateValue{v_1000585}}}
    case BIR.DescriptorPlus{v_28, v_29}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_outer_walk{v_28, List.append(&2, BIR.Descriptor, v_29, v_2)}}, v_1000588 => +v_1000587 = template_unbox(Maybe<&2, cps_provider_1_NfApp>, v_1000588); TemplateFinished{TemplateValue{v_1000587}}}
    case BIR.DescriptorApplication{v_33, v_34}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_outer_walk{v_33, List.append(&2, BIR.Descriptor, [v_34], v_2)}}, v_1000590 => +v_1000589 = template_unbox(Maybe<&2, cps_provider_1_NfApp>, v_1000590); TemplateFinished{TemplateValue{v_1000589}}}
    case _:
      TemplateFinished{TemplateValue{None{}}}

def template_match_173(+v_5: BIR.Descriptor, +v_1: cps_provider_1_NfContext) -> TemplateProgress<BIR.Descriptor>:
  match v_5:
    case BIR.DescriptorFailure{_}:
      TemplateFinished{TemplateValue{v_5}}
    case _:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_answer_normalized{v_1, v_5}}, v_1000593 => +v_1000592 = template_unbox(BIR.Descriptor, v_1000593); TemplateFinished{TemplateValue{v_1000592}}}

def template_continuation_174(+v_1000591: BIR.Descriptor, +v_1: cps_provider_1_NfContext) -> TemplateProgress<BIR.Descriptor>:
  template_match_173(v_1000591, v_1)

def template_body_cps_provider_1_answer_in(+v_1: cps_provider_1_NfContext, v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_normalize{v_1, v_2, [], 1024n}}, False{}, v_1000595 => template_body_cps_provider_1_normalize(v_1, v_2, [], 1024n), v_1000594 => +v_1000591 = template_unbox(BIR.Descriptor, v_1000594); template_continuation_174(v_1000591, v_1)}

def template_body_cps_provider_1_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_context{v_2, v_4}}, False{}, v_1000599 => template_body_cps_provider_1_nf_context(v_2, v_4), v_1000598 => +v_1000596 = template_unbox(cps_provider_1_NfContext, v_1000598); template_body_cps_provider_1_answer_in(v_1000596, v_0)}

def template_match_175(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  match v_9:
    case []:
      TemplateFinished{TemplateValue{v_2}}
    case +v_13 <> v_14:
      TemplateFinished{TemplateValue{v_13}}

def template_match_176(+v_1000601: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> TemplateProgress<BIR.Descriptor>:
  match v_1000601:
    case False{}:
      TemplateFinished{TemplateValue{v_2}}
    case True{}:
      template_match_175(v_9, v_2)

def template_match_177(v_5: cps_provider_1_NfApp, +v_1: cps_provider_1_NfContext, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  match v_5:
    case cps_provider_1_NfApp{v_8, v_9}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_is_io_head_in{v_1, v_8}}, v_1000602 => +v_1000601 = template_unbox(Bool, v_1000602); template_match_176(v_1000601, v_2, v_9)}

def template_match_178(+v_1000600: Maybe<&2, cps_provider_1_NfApp>, +v_2: BIR.Descriptor, +v_1: cps_provider_1_NfContext) -> TemplateProgress<BIR.Descriptor>:
  match v_1000600:
    case None{}:
      TemplateFinished{TemplateValue{v_2}}
    case Some{v_5}:
      template_match_177(v_5, v_1, v_2)

def template_body_cps_provider_1_answer_normalized(+v_1: cps_provider_1_NfContext, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_outer_application{v_2}}, False{}, v_1000604 => template_body_cps_provider_1_outer_application(v_2), v_1000603 => +v_1000600 = template_unbox(Maybe<&2, cps_provider_1_NfApp>, v_1000603); template_match_178(v_1000600, v_2, v_1)}

def template_body_cps_provider_1_is_io_head_in(+v_1: cps_provider_1_NfContext, +v_3: String) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NfContext{v_7, v_8}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_is_io_head{v_3, v_7, v_8}}, v_1000606 => +v_1000605 = template_unbox(Bool, v_1000606); TemplateFinished{TemplateValue{v_1000605}}}

def template_match_180(+v_1000607: Maybe<&2, String>) -> TemplateProgress<Bool>:
  match v_1000607:
    case Some{v_9}:
      TemplateFinished{TemplateValue{String.eq(v_9, "IO")}}
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_cps_provider_1_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_native_of{v_1, v_3, v_5}}, False{}, v_1000609 => template_body_cps_provider_1_native_of(v_1, v_3, v_5), v_1000608 => +v_1000607 = template_unbox(Maybe<&2, String>, v_1000608); template_match_180(v_1000607)}

def template_step_group_0(request: TemplateRequestGroup0) -> TemplateProgress<template_result_group_0(request)>:
  match request:
    case TemplateRequest_smoke_families{}: template_body_smoke_families()
    case TemplateRequest_smoke_functions{}: template_body_smoke_functions()
    case TemplateRequest_is_nat{arg_0}: template_body_is_nat(arg_0)
    case TemplateRequest_is_failure_with{arg_0, arg_1}: template_body_is_failure_with(arg_0, arg_1)
    case TemplateRequest_is_bool{arg_0}: template_body_is_bool(arg_0)
    case TemplateRequest_is_arrow_nat{arg_0}: template_body_is_arrow_nat(arg_0)
    case TemplateRequest_is_arrow_bound{arg_0}: template_body_is_arrow_bound(arg_0)
    case TemplateRequest_is_arrow_nest{arg_0}: template_body_is_arrow_nest(arg_0)
    case TemplateRequest_is_scoped_let_arrow{arg_0}: template_body_is_scoped_let_arrow(arg_0)
    case TemplateRequest_is_relocated_arrow{arg_0, arg_1}: template_body_is_relocated_arrow(arg_0, arg_1)
    case TemplateRequest_is_nat_ref{arg_0}: template_body_is_nat_ref(arg_0)
    case TemplateRequest_is_maybe_nat{arg_0}: template_body_is_maybe_nat(arg_0)
    case TemplateRequest_is_io_maybe_nat{arg_0}: template_body_is_io_maybe_nat(arg_0)
    case TemplateRequest_is_event_list{arg_0}: template_body_is_event_list(arg_0)
    case TemplateRequest_is_app_tick{arg_0}: template_body_is_app_tick(arg_0)
    case TemplateRequest_is_match_source{arg_0}: template_body_is_match_source(arg_0)
    case TemplateRequest_is_failure{arg_0}: template_body_is_failure(arg_0)
    case TemplateRequest_is_application{arg_0}: template_body_is_application(arg_0)
    case TemplateRequest_is_quantity_head{arg_0}: template_body_is_quantity_head(arg_0)
    case TemplateRequest_is_parameter{arg_0}: template_body_is_parameter(arg_0)
    case TemplateRequest_is_chan{arg_0}: template_body_is_chan(arg_0)
    case TemplateRequest_is_under_applied_head{arg_0}: template_body_is_under_applied_head(arg_0)
    case TemplateRequest_equal_args{arg_0, arg_1}: template_body_equal_args(arg_0, arg_1)
    case TemplateRequest_outer_is{arg_0, arg_1}: template_body_outer_is(arg_0, arg_1)
    case TemplateRequest_bit{arg_0}: template_body_bit(arg_0)
    case TemplateRequest_main{arg_0}: template_body_main(arg_0)
    case TemplateRequest_cps_provider_1_family_index{arg_0}: template_body_cps_provider_1_family_index(arg_0)
    case TemplateRequest_cps_provider_1_function_index{arg_0}: template_body_cps_provider_1_function_index(arg_0)
    case TemplateRequest_cps_provider_1_nf_context{arg_0, arg_1}: template_body_cps_provider_1_nf_context(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_default_fuel{}: template_body_cps_provider_1_default_fuel()
    case TemplateRequest_cps_provider_1_family_of{arg_0, arg_1}: template_body_cps_provider_1_family_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_function_of{arg_0, arg_1}: template_body_cps_provider_1_function_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_native_of{arg_0, arg_1, arg_2}: template_body_cps_provider_1_native_of(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_val_nth{arg_0, arg_1}: template_body_cps_provider_1_val_nth(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_val_at{arg_0, arg_1, arg_2}: template_body_cps_provider_1_val_at(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_val_at_choose{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_val_at_choose(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_first_vals{arg_0, arg_1}: template_body_cps_provider_1_first_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_drop_vals{arg_0, arg_1}: template_body_cps_provider_1_drop_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_insert_before{arg_0, arg_1, arg_2}: template_body_cps_provider_1_insert_before(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_append_vals{arg_0, arg_1}: template_body_cps_provider_1_append_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_quantity_markers{arg_0}: template_body_cps_provider_1_quantity_markers(arg_0)
    case TemplateRequest_cps_provider_1_renamed_level{arg_0, arg_1}: template_body_cps_provider_1_renamed_level(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_materialize_all_scoped{arg_0, arg_1, arg_2}: template_body_cps_provider_1_materialize_all_scoped(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_materialize_all_at{arg_0, arg_1}: template_body_cps_provider_1_materialize_all_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_materialize_all{arg_0}: template_body_cps_provider_1_materialize_all(arg_0)
    case TemplateRequest_cps_provider_1_materialize_scoped{arg_0, arg_1, arg_2}: template_body_cps_provider_1_materialize_scoped(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_materialize_at{arg_0, arg_1}: template_body_cps_provider_1_materialize_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_materialize{arg_0}: template_body_cps_provider_1_materialize(arg_0)
    case TemplateRequest_cps_provider_1_reify_env{arg_0, arg_1, arg_2}: template_body_cps_provider_1_reify_env(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_status_combine{arg_0, arg_1}: template_body_cps_provider_1_status_combine(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_bind_status{arg_0, arg_1}: template_body_cps_provider_1_bind_status(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_bind_values{arg_0, arg_1}: template_body_cps_provider_1_bind_values(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_bind_patterns{arg_0, arg_1}: template_body_cps_provider_1_bind_patterns(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_nf{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_nf_descriptor{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf_descriptor(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_nf_arrow{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_1_nf_arrow(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_1_nf_descriptor_step{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf_descriptor_step(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_nf_all{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf_all(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_nf_apply_args{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_1_nf_apply_args(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_1_nf_apply_source{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_nf_apply_source(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_nf_apply{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf_apply(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_nf_apply_one{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf_apply_one(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_intrinsic_io{arg_0}: template_body_cps_provider_1_intrinsic_io(arg_0)
    case TemplateRequest_cps_provider_1_nf_named_io{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_nf_named_io(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)

def template_step_group_1(request: TemplateRequestGroup1) -> TemplateProgress<template_result_group_1(request)>:
  match request:
    case TemplateRequest_cps_provider_1_nf_named{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf_named(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_nf_arity{arg_0, arg_1, arg_2}: template_body_cps_provider_1_nf_arity(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_nf_family{arg_0, arg_1}: template_body_cps_provider_1_nf_family(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_nf_family_apply{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_nf_family_apply(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_nf_reduce{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_nf_reduce(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_nf_reduce_apply{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_1_nf_reduce_apply(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_1_nf_reduce_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_nf_reduce_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_nf_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_1_nf_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_1_normalize{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_normalize(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_normalize_closed{arg_0, arg_1, arg_2}: template_body_cps_provider_1_normalize_closed(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_normalize_in{arg_0, arg_1}: template_body_cps_provider_1_normalize_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_outer_application{arg_0}: template_body_cps_provider_1_outer_application(arg_0)
    case TemplateRequest_cps_provider_1_outer_walk{arg_0, arg_1}: template_body_cps_provider_1_outer_walk(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_answer_in{arg_0, arg_1}: template_body_cps_provider_1_answer_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_answer_descriptor{arg_0, arg_1, arg_2}: template_body_cps_provider_1_answer_descriptor(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_answer_normalized{arg_0, arg_1}: template_body_cps_provider_1_answer_normalized(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_is_io_head_in{arg_0, arg_1}: template_body_cps_provider_1_is_io_head_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_is_io_head{arg_0, arg_1, arg_2}: template_body_cps_provider_1_is_io_head(arg_0, arg_1, arg_2)

def template_step_one(request: TemplateRequest) -> TemplateProgress<template_result(request)>:
  match request:
    case TemplateRequestGroup_0{inner}: template_step_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_step_group_1(inner)

def template_pop(-A: Type, -R: Type, stack: TemplateStack<A, R>, box: TemplateValue<A>) -> TemplateRun<R>:
  match stack:
    case TemplateStackDone{equation}: TemplateRunFinished{template_cast_box(A, R, equation, box)}
    case TemplateStackMore{B, resume, rest}: TemplateRunState{B, resume(box), rest}

def template_advance(-A: Type, -R: Type, progress: TemplateProgress<A>, stack: TemplateStack<A, R>) -> TemplateRun<R>:
  match progress:
    case TemplateFinished{box}: template_pop(A, R, stack, box)
    case TemplatePending{request, resume}:
      TemplateRunState{template_result(request), template_step_one(request), TemplateStackMore{A, resume, stack}}
    case TemplateDirect{T, request, arguments, invoke, resume}:
      TemplateRunState{template_result(request), invoke(arguments), TemplateStackMore{A, resume, stack}}
    case TemplateBound{B, inner, resume}:
      TemplateRunState{B, inner, TemplateStackMore{A, resume, stack}}

def template_chunk(-R: Type, fuel: Nat, run: TemplateRun<R>) -> TemplateRun<R>:
  match fuel run:
    case 0n state: state
    case 1n+rest TemplateRunFinished{box}: TemplateRunFinished{box}
    case 1n+rest TemplateRunState{A, progress, stack}:
      template_chunk(R, rest, template_advance(A, R, progress, stack))

def template_step(-R: Type, run: TemplateRun<R>) -> TemplateRun<R>:
  template_chunk(R, 64n, run)

def template_start(modules: List<&2, Loader.LoadedModule>) -> TemplateRun<NfSmoke>:
  template_chunk(NfSmoke, 64n, TemplateRunState{NfSmoke, TemplatePending{TemplateRequestGroup_0{TemplateRequest_main{modules}}, box => TemplateFinished{box}}, TemplateStackDone{{==}}})
