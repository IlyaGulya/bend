import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/index_lookup.bend as IndexLookup

type ClaySmoke is Data:
  ClaySmoke{failures: U32}

type cps_provider_1_CWord is Data:
  cps_provider_1_CWord32{}
  cps_provider_1_CWord64{}
  cps_provider_1_CWordBox{}

type cps_provider_1_BoxReason is Data:
  cps_provider_1_BoxOpen{}
  cps_provider_1_BoxUnresolved{key: String}
  cps_provider_1_BoxArray{}
  cps_provider_1_BoxIo{}
  cps_provider_1_BoxRecursive{key: String}
  cps_provider_1_BoxWide{words: Nat}

type cps_provider_1_Layout is Data:
  cps_provider_1_LayoutWord{word: cps_provider_1_CWord}
  cps_provider_1_LayoutBox{reason: cps_provider_1_BoxReason}
  cps_provider_1_LayoutData{words: List<&2, cps_provider_1_CWord>, arms: List<&2, cps_provider_1_LayArm>}

type cps_provider_1_LayArm is Data:
  cps_provider_1_LayArm{key: String, fields: List<&2, cps_provider_1_Layout>}

type cps_provider_1_LayoutResult is Data:
  cps_provider_1_LayoutFound{layout: cps_provider_1_Layout}
  cps_provider_1_LayoutFailed{message: String}

type cps_provider_1_HeadResult is Data:
  cps_provider_1_HeadFound{key: String, native: Maybe<&2, String>}
  cps_provider_1_HeadEquality{}
  cps_provider_1_HeadBoxed{reason: cps_provider_1_BoxReason}
  cps_provider_1_HeadFailed{message: String}

type cps_provider_1_FieldsResult is Data:
  cps_provider_1_FieldsFound{fields: List<&2, BIR.DescriptorField>}
  cps_provider_1_FieldsFailed{message: String}

type cps_provider_1_NormResult is Data:
  cps_provider_1_NormOk{descriptor: BIR.Descriptor}
  cps_provider_1_NormFailed{message: String}

type cps_provider_1_ArgsResult is Data:
  cps_provider_1_ArgsOk{args: List<&2, BIR.Descriptor>}
  cps_provider_1_ArgsFailed{message: String}

type cps_provider_1_Nest is Data:
  cps_provider_1_Nest{at: Nat, offset: Nat, take: cps_provider_1_Unfill, make: cps_provider_1_Fill}

type cps_provider_1_Fill is Data:
  cps_provider_1_FillWord{}
  cps_provider_1_FillForm{words: Nat, arms: List<&2, cps_provider_1_FormArm>}

type cps_provider_1_Unfill is Data:
  cps_provider_1_UnfillWord{}
  cps_provider_1_UnfillForm{words: Nat, arms: List<&2, cps_provider_1_FormArm>}

type cps_provider_1_FormArm is Data:
  cps_provider_1_FormArm{key: String, tag: Nat, packed: Bool, node_words: Nat, fields: List<&2, cps_provider_1_Nest>}

type cps_provider_1_FillResult is Data:
  cps_provider_1_FillFound{fill: cps_provider_1_Fill}
  cps_provider_1_FillFailed{message: String}

type cps_provider_1_UnfillResult is Data:
  cps_provider_1_UnfillFound{unfill: cps_provider_1_Unfill}
  cps_provider_1_UnfillFailed{message: String}

type cps_provider_1_NodeSlot is Data:
  cps_provider_1_NodeSlot{ordinal: U32, offset: Nat, layout: cps_provider_1_Layout}

type cps_provider_1_Node is Data:
  cps_provider_1_Node{words: List<&2, cps_provider_1_CWord>, slots: List<&2, cps_provider_1_NodeSlot>, packed: Bool}

type cps_provider_1_NodeResult is Data:
  cps_provider_1_NodeFound{node: cps_provider_1_Node}
  cps_provider_1_NodeFailed{message: String}

type cps_provider_1_SlotResult is Data:
  cps_provider_1_SlotFound{slot: cps_provider_1_NodeSlot}
  cps_provider_1_SlotErased{}
  cps_provider_1_SlotFailed{message: String}

type cps_provider_1_Cell is Data:
  cps_provider_1_Cell{layout: cps_provider_1_Layout, arr: Bool, words: Nat, lgs: Nat}

type cps_provider_1_CellResult is Data:
  cps_provider_1_CellFound{cell: cps_provider_1_Cell}
  cps_provider_1_CellFailed{message: String}

type cps_provider_2_NfContext is Data:
  cps_provider_2_NfContext{families: Map<&2, BIR.Family>, type_functions: Map<&2, BIR.TypeFunction>}

type cps_provider_1_Plan is Data:
  cps_provider_1_Plan{nodes: Map<&2, cps_provider_1_NodeResult>, arms: Map<&2, BIR.DescriptorArm>, closed: Map<&2, Bool>}

type cps_provider_1_Context is Data:
  cps_provider_1_Context{context: cps_provider_2_NfContext, families: List<&2, BIR.Family>, plan: cps_provider_1_Plan}

type cps_provider_1_Dependencies is Data:
  cps_provider_1_Dependencies{names: List<&2, String>}
  cps_provider_1_DependenciesUnknown{}

type cps_provider_1_Plans is Data:
  cps_provider_1_PlansOk{plans: List<&2, cps_provider_1_LayArm>}
  cps_provider_1_PlansFail{message: String}

type cps_provider_1_Layouts is Data:
  cps_provider_1_LayoutsOk{layouts: List<&2, cps_provider_1_Layout>}
  cps_provider_1_LayoutsFail{message: String}

type cps_provider_1_Slots is Data:
  cps_provider_1_SlotsOk{slots: List<&2, cps_provider_1_NodeSlot>}
  cps_provider_1_SlotsFail{message: String}

type cps_provider_1_Arms is Data:
  cps_provider_1_ArmsOk{arms: List<&2, cps_provider_1_FormArm>}
  cps_provider_1_ArmsFail{message: String}

type cps_provider_1_Nests is Data:
  cps_provider_1_NestsOk{nests: List<&2, cps_provider_1_Nest>}
  cps_provider_1_NestsFail{message: String}

type cps_provider_1_FormArmResult is Data:
  cps_provider_1_FormArmOk{plan: cps_provider_1_FormArm}
  cps_provider_1_FormArmFail{message: String}

type cps_provider_2_NfVal is Data:
  cps_provider_2_NfType{key: String, args: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfCtor{key: String, args: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfQuantity{quantity: BIR.Quantity}
  cps_provider_2_NfKind{quantity: cps_provider_2_NfVal}
  cps_provider_2_NfOther{source: BIR.Descriptor}
  cps_provider_2_NfMissing{source: BIR.Descriptor}
  cps_provider_2_NfBinder{level: Nat}
  cps_provider_2_NfArrow{quantity: BIR.Quantity, domain: cps_provider_2_NfVal, body: cps_provider_2_NfVal, level: Nat}
  cps_provider_2_NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, cps_provider_2_NfVal>}

type cps_provider_2_NfRenaming is Data:
  cps_provider_2_NfRenaming{source: Nat, target: Nat}

type cps_provider_2_NfBind is Data:
  cps_provider_2_NfBound{bindings: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfMismatch{}
  cps_provider_2_NfUnknown{}

type cps_provider_2_NfStatus is Data:
  cps_provider_2_NfStatusOk{}
  cps_provider_2_NfStatusNo{}
  cps_provider_2_NfStatusMaybe{}

type cps_provider_2_Nf is Data:
  cps_provider_2_NfOk{val: cps_provider_2_NfVal}
  cps_provider_2_NfFail{message: String}

type cps_provider_2_NfList is Data:
  cps_provider_2_NfListOk{vals: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfListFail{message: String}

type cps_provider_2_NfApp is Data:
  cps_provider_2_NfApp{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_2_NfArity is Data:
  cps_provider_2_NfArity{complete: Bool, exact: Bool, under: Bool}


# Bounded typed request groups; every source declaration retains its checked signature.
type TemplateRequestGroup0 is Type:
  TemplateRequest_fld{+v_0: BIR.Descriptor}
  TemplateRequest_arm{+v_1: String, +v_3: List<&2, BIR.DescriptorField>}
  TemplateRequest_fam{+v_1: String, +v_4: Maybe<&2, String>, +v_6: Nat, +v_8: List<&2, BIR.DescriptorArm>}
  TemplateRequest_ref{+v_1: String, +v_3: List<&2, BIR.Descriptor>}
  TemplateRequest_par{+v_1: Nat}
  TemplateRequest_fam_nat{}
  TemplateRequest_fam_u32{}
  TemplateRequest_fam_f32{}
  TemplateRequest_fam_array{}
  TemplateRequest_fam_io{}
  TemplateRequest_fam_pt{}
  TemplateRequest_fam_fl{}
  TemplateRequest_fam_seg{}
  TemplateRequest_fam_w32{}
  TemplateRequest_fam_onenat{}
  TemplateRequest_fam_empty{}
  TemplateRequest_fam_box{}
  TemplateRequest_fam_pair{}
  TemplateRequest_fam_opt{}
  TemplateRequest_fam_list{}
  TemplateRequest_families{}
  TemplateRequest_type_functions{}
  TemplateRequest_program{}
  TemplateRequest_both{+v_1: Bool, +v_3: Bool}
  TemplateRequest_bool_eq{+v_1: Bool, +v_3: Bool}
  TemplateRequest_fail{+v_1: Bool}
  TemplateRequest_first_word_32{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_first_word_64{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_first_word_box{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_check_pt_value{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_check_pt_node{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_slot_offsets{+v_2: List<&2, cps_provider_1_NodeSlot>}
  TemplateRequest_check_seg_node{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_opt_tag{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_check_w32_packed{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_nat_not_packed{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_empty_packed{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_box_declared_node{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_box_value{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_check_u32_cell{+v_1: cps_provider_1_CellResult}
  TemplateRequest_check_nat_cell{+v_1: cps_provider_1_CellResult}
  TemplateRequest_check_pt_cell{+v_1: cps_provider_1_CellResult}
  TemplateRequest_check_seg_cell{+v_1: cps_provider_1_CellResult}
  TemplateRequest_check_open_cell{+v_1: cps_provider_1_CellResult}
  TemplateRequest_check_abstract_cell{+v_1: cps_provider_1_CellResult}
  TemplateRequest_check_recursive{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_check_open_box{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_check_failure{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_nests_agree{+v_2: List<&2, cps_provider_1_Nest>, +v_5: List<&2, cps_provider_1_Nest>}
  TemplateRequest_forms_agree{+v_2: List<&2, cps_provider_1_FormArm>, +v_5: List<&2, cps_provider_1_FormArm>}
  TemplateRequest_check_fill{+v_1: cps_provider_1_FillResult, +v_3: cps_provider_1_UnfillResult, +v_5: cps_provider_1_LayoutResult}
  TemplateRequest_extract{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_check_head_nat_alias{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_check_head_array{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_check_head_plain{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_check_head_open{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_check_head_failure{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_descriptor_is_ref{+v_0: BIR.Descriptor, +v_2: String}
  TemplateRequest_check_box_fields{+v_1: cps_provider_1_FieldsResult}
  TemplateRequest_check_pair_fields{+v_1: cps_provider_1_FieldsResult}
  TemplateRequest_check_fields_failure{+v_1: cps_provider_1_FieldsResult}
  TemplateRequest_mk_words{+v_1: Nat}
  TemplateRequest_mk_fields{+v_1: Nat}
  TemplateRequest_wide_program{}

type TemplateRequestGroup1 is Type:
  TemplateRequest_mk_miss{+v_1: Nat}
  TemplateRequest_check_ceil{}
  TemplateRequest_check_pow2{}
  TemplateRequest_check_pad{+v_1: Nat, +v_3: Nat}
  TemplateRequest_check_wide{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_long_arm{+v_1: Maybe<&2, BIR.DescriptorArm>}
  TemplateRequest_check_norm_alias{+v_1: cps_provider_1_NormResult}
  TemplateRequest_first_arg_is{+v_0: BIR.Descriptor, +v_2: String}
  TemplateRequest_check_norm_distinct{+v_1: cps_provider_1_NormResult, +v_3: cps_provider_1_NormResult}
  TemplateRequest_check_norm_failure{+v_1: cps_provider_1_NormResult}
  TemplateRequest_args_first_is{+v_1: cps_provider_1_ArgsResult, +v_3: String}
  TemplateRequest_check_args_pair{+v_1: cps_provider_1_ArgsResult}
  TemplateRequest_check_args_failure{+v_1: cps_provider_1_ArgsResult}
  TemplateRequest_chain_key{+v_1: Nat}
  TemplateRequest_next_key{+v_1: Nat}
  TemplateRequest_fam_chain{+v_1: Nat}
  TemplateRequest_program_shadow{}
  TemplateRequest_check_io_native{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_check_io_under{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_check_shadow_io{+v_1: cps_provider_1_HeadResult}
  TemplateRequest_program_deep{}
  TemplateRequest_classify{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_deep_chain_check{}
  TemplateRequest_erased_fld{}
  TemplateRequest_fam_erased{}
  TemplateRequest_families_plan{}
  TemplateRequest_row_pt{}
  TemplateRequest_row_er{}
  TemplateRequest_row_w32{}
  TemplateRequest_program_rows{}
  TemplateRequest_fam_pt3{}
  TemplateRequest_program_scope{}
  TemplateRequest_fam_same_one{}
  TemplateRequest_fam_same_two{}
  TemplateRequest_program_first{}
  TemplateRequest_erased_slot_ordinals{+v_2: List<&2, cps_provider_1_NodeSlot>}
  TemplateRequest_check_erased_node{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_three_word_node{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_packed_one{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_node_failed{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_check_declared_count{+v_1: Maybe<&2, BIR.DescriptorArm>, +v_3: Nat}
  TemplateRequest_check_declared_none{+v_1: Maybe<&2, BIR.DescriptorArm>}
  TemplateRequest_recursion_layout{+v_1: List<&2, BIR.DescriptorField>, +v_3: List<&2, BIR.Family>, +v_5: List<&2, BIR.TypeFunction>}
  TemplateRequest_recursion_functions{}
  TemplateRequest_recursive_descriptors{}
  TemplateRequest_recursive_descriptor_failures{+v_1: List<&2, BIR.Descriptor>, +v_3: List<&2, BIR.TypeFunction>}
  TemplateRequest_check_single_box_field{+v_1: cps_provider_1_LayoutResult}
  TemplateRequest_check_recursive_key{+v_1: cps_provider_1_LayoutResult, +v_3: String}
  TemplateRequest_generic_recursion_check{}
  TemplateRequest_duplicate_recursion_check{}
  TemplateRequest_target_exclusion_boundaries{}
  TemplateRequest_target_closure_authority_check{}
  TemplateRequest_explicit_recursion_check{}
  TemplateRequest_recursion_boundaries{}
  TemplateRequest_main{v_1: List<&2, Loader.LoadedModule>}
  TemplateRequest_cps_provider_1_context{+v_0: BIR.Program}
  TemplateRequest_cps_provider_1_context_nf{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_families{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_plan{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_nodes{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_arms{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_closed{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_nf_families{+v_1: cps_provider_2_NfContext}
  TemplateRequest_cps_provider_1_nf_functions{+v_1: cps_provider_2_NfContext}

type TemplateRequestGroup2 is Type:
  TemplateRequest_cps_provider_1_family_lookup{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_function_lookup{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_arm_of{+v_1: String, +v_3: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_1_arm_in{+v_1: String, +v_3: List<&2, BIR.DescriptorArm>}
  TemplateRequest_cps_provider_1_plan_arm_index{+v_1: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_1_plan_family_arms{+v_1: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>}
  TemplateRequest_cps_provider_1_arm_declared{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_live_field{+v_0: BIR.Quantity}
  TemplateRequest_cps_provider_1_dependency_seed{+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String}
  TemplateRequest_cps_provider_1_dependency_name{+v_1: String, +v_3: cps_provider_1_Dependencies}
  TemplateRequest_cps_provider_1_dependency_descriptors{+v_1: List<&2, BIR.Descriptor>, +v_3: cps_provider_1_Dependencies}
  TemplateRequest_cps_provider_1_dependency_patterns{+v_1: List<&2, BIR.DescriptorPattern>, +v_3: cps_provider_1_Dependencies}
  TemplateRequest_cps_provider_1_dependency_descriptor{+v_0: BIR.Descriptor, +v_2: cps_provider_1_Dependencies}
  TemplateRequest_cps_provider_1_dependency_fields{+v_1: List<&2, BIR.DescriptorField>, +v_3: cps_provider_1_Dependencies}
  TemplateRequest_cps_provider_1_dependency_arms{+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Dependencies}
  TemplateRequest_cps_provider_1_dependency_families{+v_1: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>}
  TemplateRequest_cps_provider_1_dependency_functions{+v_1: List<&2, BIR.TypeFunction>, +v_4: Map<&2, cps_provider_1_Dependencies>}
  TemplateRequest_cps_provider_1_dependency_maybe_reaches{+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_8: List<&2, List<&2, String>>, +v_11: Map<&2, Bool>}
  TemplateRequest_cps_provider_1_dependency_closed{+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String}
  TemplateRequest_cps_provider_1_plan_closed_facts{+v_1: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_7: Map<&2, Bool>, +v_10: Map<&2, Bool>}
  TemplateRequest_cps_provider_1_layout_fuel{}
  TemplateRequest_cps_provider_1_nf_of{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_1_value_layout{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_layout_of_desc{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_1_layout_of_val{+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat}
  TemplateRequest_cps_provider_1_layout_val{+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat}
  TemplateRequest_cps_provider_1_layout_unresolved{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_layout_family{+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_1_layout_native{+v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat}
  TemplateRequest_cps_provider_1_field_scope{+v_2: List<&2, cps_provider_2_NfVal>}
  TemplateRequest_cps_provider_1_arm_layouts{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>}
  TemplateRequest_cps_provider_1_field_layouts{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>}
  TemplateRequest_cps_provider_1_layout_data{+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat}
  TemplateRequest_cps_provider_1_data_reenters{+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat}
  TemplateRequest_cps_provider_1_arms_tagged{+v_2: List<&2, cps_provider_1_LayArm>}
  TemplateRequest_cps_provider_1_reenters{+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat}
  TemplateRequest_cps_provider_1_fields_self_reference{+v_1: List<&2, BIR.DescriptorField>, +v_3: String}
  TemplateRequest_cps_provider_1_fields_reach{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat}
  TemplateRequest_cps_provider_1_reaches{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat}
  TemplateRequest_cps_provider_1_reaches_val{+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: String, +v_8: List<&2, String>, +v_10: Nat}
  TemplateRequest_cps_provider_1_family_reach{+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat}
  TemplateRequest_cps_provider_1_reach_arms{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat}
  TemplateRequest_cps_provider_1_args_reach{+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat}
  TemplateRequest_cps_provider_1_str_member{+v_2: List<&2, String>, +v_4: String}
  TemplateRequest_cps_provider_1_layout_kinds{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_layout_words{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_canonical_word{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_pack_arms{+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Bool}
  TemplateRequest_cps_provider_1_pack_arm_list{+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_1_pack_field_list{+v_2: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_1_pack_kinds{+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_1_set_kind{+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_6: cps_provider_1_CWord}
  TemplateRequest_cps_provider_1_merge_kind{+v_1: cps_provider_1_CWord, +v_3: cps_provider_1_CWord}
  TemplateRequest_cps_provider_1_word_32{+v_1: cps_provider_1_CWord}
  TemplateRequest_cps_provider_1_pad_words{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_1_pad_to{+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat}
  TemplateRequest_cps_provider_1_pow2_upto{+v_1: Nat, +v_3: Nat}
  TemplateRequest_cps_provider_1_ceil_log2{+v_1: Nat}
  TemplateRequest_cps_provider_1_ceil_log2_go{+v_1: Nat, +v_3: Nat, +v_5: Nat}
  TemplateRequest_cps_provider_1_node_layout{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_node_layout_fuel{+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat}
  TemplateRequest_cps_provider_1_node_at{+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat}
  TemplateRequest_cps_provider_1_plan_node{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_node_compute{+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat}

type TemplateRequestGroup3 is Type:
  TemplateRequest_cps_provider_1_unresolved_message{+v_1: String}
  TemplateRequest_cps_provider_1_node_arm{+v_1: cps_provider_1_Context, +v_2: BIR.DescriptorArm, +v_4: Nat}
  TemplateRequest_cps_provider_1_plan_node_index{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>}
  TemplateRequest_cps_provider_1_node_declared{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_node_slots{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>}
  TemplateRequest_cps_provider_1_node_finish{+v_2: List<&2, cps_provider_1_NodeSlot>}
  TemplateRequest_cps_provider_1_slot_words{+v_2: List<&2, cps_provider_1_NodeSlot>}
  TemplateRequest_cps_provider_1_packed_words{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_1_node_slot{+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32}
  TemplateRequest_cps_provider_1_slot_find{+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: U32}
  TemplateRequest_cps_provider_1_layout_fill{+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_layout_fill_fuel{+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat}
  TemplateRequest_cps_provider_1_layout_unfill{+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_layout_unfill_fuel{+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat}
  TemplateRequest_cps_provider_1_slot_fill{+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32}
  TemplateRequest_cps_provider_1_slot_unfill{+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32}
  TemplateRequest_cps_provider_1_form_arms{+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_LayArm>, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool}
  TemplateRequest_cps_provider_1_form_arm{+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_7: Bool, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: Nat, +v_16: Bool}
  TemplateRequest_cps_provider_1_tag_word{+v_1: Bool}
  TemplateRequest_cps_provider_1_form_nests{+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_Layout>, +v_7: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool}
  TemplateRequest_cps_provider_1_nest{+v_1: Nat, +v_3: Nat, +v_5: cps_provider_1_Unfill, +v_7: cps_provider_1_Fill}
  TemplateRequest_cps_provider_1_nest_fits{+v_1: Nat, +v_3: Nat, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_1_Unfill, +v_11: cps_provider_1_Fill}
  TemplateRequest_cps_provider_1_fill_words{+v_1: cps_provider_1_Fill}
  TemplateRequest_cps_provider_1_unfill_words{+v_1: cps_provider_1_Unfill}
  TemplateRequest_cps_provider_1_head_native{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_head_other{+v_0: BIR.Descriptor}
  TemplateRequest_cps_provider_1_head_value{+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal}
  TemplateRequest_cps_provider_1_norm{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_head_args{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_arm_fields{+v_1: cps_provider_1_Context, +v_3: String, +v_4: BIR.Descriptor}
  TemplateRequest_cps_provider_1_arm_fields_value{+v_1: cps_provider_1_Context, +v_3: String, +v_5: cps_provider_2_NfVal}
  TemplateRequest_cps_provider_1_instantiate_fields{+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>}
  TemplateRequest_cps_provider_1_array_cell{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_cell_of{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_cell_boxed{+v_1: cps_provider_1_BoxReason}
  TemplateRequest_cps_provider_1_max_one{+v_1: Nat}
  TemplateRequest_cps_provider_1_layout_has_term{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_word_has_term{+v_1: cps_provider_1_CWord}
  TemplateRequest_cps_provider_1_any_word_has_term{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_2_family_index{v_1: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_2_function_index{v_1: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_2_nf_context{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_2_default_fuel{}
  TemplateRequest_cps_provider_2_family_of{+v_1: String, +v_3: Map<&2, BIR.Family>}
  TemplateRequest_cps_provider_2_function_of{+v_1: String, +v_3: Map<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_2_native_of{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_2_val_nth{+v_2: List<&2, cps_provider_2_NfVal>, v_4: Nat}
  TemplateRequest_cps_provider_2_val_at{+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_5: BIR.Descriptor}
  TemplateRequest_cps_provider_2_val_at_choose{v_1: Bool, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: Nat, v_7: BIR.Descriptor}
  TemplateRequest_cps_provider_2_first_vals{v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_2_drop_vals{v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_2_insert_before{v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_6: cps_provider_2_NfVal}
  TemplateRequest_cps_provider_2_append_vals{v_2: List<&2, cps_provider_2_NfVal>, v_5: List<&2, cps_provider_2_NfVal>}
  TemplateRequest_cps_provider_2_quantity_markers{v_1: Nat}
  TemplateRequest_cps_provider_2_renamed_level{v_2: List<&2, cps_provider_2_NfRenaming>, +v_4: Nat}
  TemplateRequest_cps_provider_2_materialize_all_scoped{v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_2_NfRenaming>}
  TemplateRequest_cps_provider_2_materialize_all_at{v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_2_materialize_all{v_2: List<&2, cps_provider_2_NfVal>}
  TemplateRequest_cps_provider_2_materialize_scoped{v_1: cps_provider_2_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_2_NfRenaming>}
  TemplateRequest_cps_provider_2_materialize_at{v_1: cps_provider_2_NfVal, +v_3: Nat}
  TemplateRequest_cps_provider_2_materialize{v_1: cps_provider_2_NfVal}
  TemplateRequest_cps_provider_2_reify_env{v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_2_NfVal>, +v_5: Nat}
  TemplateRequest_cps_provider_2_status_combine{v_1: cps_provider_2_NfStatus, v_3: cps_provider_2_NfStatus}
  TemplateRequest_cps_provider_2_bind_status{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>}

type TemplateRequestGroup4 is Type:
  TemplateRequest_cps_provider_2_bind_values{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>}
  TemplateRequest_cps_provider_2_bind_patterns{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>}
  TemplateRequest_cps_provider_2_nf{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_2_nf_descriptor{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_2_nf_arrow{+v_1: cps_provider_2_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_2_nf_descriptor_step{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_2_nf_all{+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_2_nf_apply_args{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_2_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat}
  TemplateRequest_cps_provider_2_nf_apply_source{+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_6: List<&2, cps_provider_2_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_2_nf_apply{+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_2_nf_apply_one{+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_5: cps_provider_2_NfVal, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_2_intrinsic_io{+v_0: BIR.TypeFunction}
  TemplateRequest_cps_provider_2_nf_named_io{v_1: Bool, +v_3: cps_provider_2_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_2_nf_named{+v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_2_nf_arity{+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, +v_6: Nat}
  TemplateRequest_cps_provider_2_nf_family{v_0: BIR.Family, v_3: List<&2, cps_provider_2_NfVal>}
  TemplateRequest_cps_provider_2_nf_family_apply{v_1: cps_provider_2_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_2_NfVal>}
  TemplateRequest_cps_provider_2_nf_reduce{+v_1: cps_provider_2_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_2_nf_reduce_apply{v_1: cps_provider_2_NfArity, +v_3: cps_provider_2_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_2_NfVal>, +v_15: Nat, +v_17: Nat}
  TemplateRequest_cps_provider_2_nf_reduce_body{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Nat}
  TemplateRequest_cps_provider_2_nf_cases{+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat}
  TemplateRequest_cps_provider_2_normalize{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_2_normalize_closed{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor}
  TemplateRequest_cps_provider_2_normalize_in{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_2_outer_application{+v_0: BIR.Descriptor}
  TemplateRequest_cps_provider_2_outer_walk{+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>}
  TemplateRequest_cps_provider_2_answer_in{+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_2_answer_descriptor{v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_2_answer_normalized{+v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_2_is_io_head_in{+v_1: cps_provider_2_NfContext, +v_3: String}
  TemplateRequest_cps_provider_2_is_io_head{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}

type TemplateRequest is Type:
  TemplateRequestGroup_0{request: TemplateRequestGroup0}
  TemplateRequestGroup_1{request: TemplateRequestGroup1}
  TemplateRequestGroup_2{request: TemplateRequestGroup2}
  TemplateRequestGroup_3{request: TemplateRequestGroup3}
  TemplateRequestGroup_4{request: TemplateRequestGroup4}

def template_result_group_0(request: TemplateRequestGroup0) -> Data:
  match request:
    case TemplateRequest_fld{_}: BIR.DescriptorField
    case TemplateRequest_arm{_, _}: BIR.DescriptorArm
    case TemplateRequest_fam{_, _, _, _}: BIR.Family
    case TemplateRequest_ref{_, _}: BIR.Descriptor
    case TemplateRequest_par{_}: BIR.Descriptor
    case TemplateRequest_fam_nat{}: BIR.Family
    case TemplateRequest_fam_u32{}: BIR.Family
    case TemplateRequest_fam_f32{}: BIR.Family
    case TemplateRequest_fam_array{}: BIR.Family
    case TemplateRequest_fam_io{}: BIR.Family
    case TemplateRequest_fam_pt{}: BIR.Family
    case TemplateRequest_fam_fl{}: BIR.Family
    case TemplateRequest_fam_seg{}: BIR.Family
    case TemplateRequest_fam_w32{}: BIR.Family
    case TemplateRequest_fam_onenat{}: BIR.Family
    case TemplateRequest_fam_empty{}: BIR.Family
    case TemplateRequest_fam_box{}: BIR.Family
    case TemplateRequest_fam_pair{}: BIR.Family
    case TemplateRequest_fam_opt{}: BIR.Family
    case TemplateRequest_fam_list{}: BIR.Family
    case TemplateRequest_families{}: List<&2, BIR.Family>
    case TemplateRequest_type_functions{}: List<&2, BIR.TypeFunction>
    case TemplateRequest_program{}: BIR.Program
    case TemplateRequest_both{_, _}: Bool
    case TemplateRequest_bool_eq{_, _}: Bool
    case TemplateRequest_fail{_}: U32
    case TemplateRequest_first_word_32{_}: Bool
    case TemplateRequest_first_word_64{_}: Bool
    case TemplateRequest_first_word_box{_}: Bool
    case TemplateRequest_check_pt_value{_}: Bool
    case TemplateRequest_check_pt_node{_}: Bool
    case TemplateRequest_slot_offsets{_}: Bool
    case TemplateRequest_check_seg_node{_}: Bool
    case TemplateRequest_check_opt_tag{_}: Bool
    case TemplateRequest_check_w32_packed{_}: Bool
    case TemplateRequest_check_nat_not_packed{_}: Bool
    case TemplateRequest_check_empty_packed{_}: Bool
    case TemplateRequest_check_box_declared_node{_}: Bool
    case TemplateRequest_check_box_value{_}: Bool
    case TemplateRequest_check_u32_cell{_}: Bool
    case TemplateRequest_check_nat_cell{_}: Bool
    case TemplateRequest_check_pt_cell{_}: Bool
    case TemplateRequest_check_seg_cell{_}: Bool
    case TemplateRequest_check_open_cell{_}: Bool
    case TemplateRequest_check_abstract_cell{_}: Bool
    case TemplateRequest_check_recursive{_}: Bool
    case TemplateRequest_check_open_box{_}: Bool
    case TemplateRequest_check_failure{_}: Bool
    case TemplateRequest_nests_agree{_, _}: Bool
    case TemplateRequest_forms_agree{_, _}: Bool
    case TemplateRequest_check_fill{_, _, _}: Bool
    case TemplateRequest_extract{_}: cps_provider_1_Layout
    case TemplateRequest_check_head_nat_alias{_}: Bool
    case TemplateRequest_check_head_array{_}: Bool
    case TemplateRequest_check_head_plain{_}: Bool
    case TemplateRequest_check_head_open{_}: Bool
    case TemplateRequest_check_head_failure{_}: Bool
    case TemplateRequest_descriptor_is_ref{_, _}: Bool
    case TemplateRequest_check_box_fields{_}: Bool
    case TemplateRequest_check_pair_fields{_}: Bool
    case TemplateRequest_check_fields_failure{_}: Bool
    case TemplateRequest_mk_words{_}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_mk_fields{_}: List<&2, BIR.DescriptorField>
    case TemplateRequest_wide_program{}: BIR.Program

def template_result_group_1(request: TemplateRequestGroup1) -> Data:
  match request:
    case TemplateRequest_mk_miss{_}: List<&2, BIR.DescriptorArm>
    case TemplateRequest_check_ceil{}: Bool
    case TemplateRequest_check_pow2{}: Bool
    case TemplateRequest_check_pad{_, _}: Bool
    case TemplateRequest_check_wide{_}: Bool
    case TemplateRequest_check_long_arm{_}: Bool
    case TemplateRequest_check_norm_alias{_}: Bool
    case TemplateRequest_first_arg_is{_, _}: Bool
    case TemplateRequest_check_norm_distinct{_, _}: Bool
    case TemplateRequest_check_norm_failure{_}: Bool
    case TemplateRequest_args_first_is{_, _}: Bool
    case TemplateRequest_check_args_pair{_}: Bool
    case TemplateRequest_check_args_failure{_}: Bool
    case TemplateRequest_chain_key{_}: String
    case TemplateRequest_next_key{_}: String
    case TemplateRequest_fam_chain{_}: List<&2, BIR.Family>
    case TemplateRequest_program_shadow{}: BIR.Program
    case TemplateRequest_check_io_native{_}: Bool
    case TemplateRequest_check_io_under{_}: Bool
    case TemplateRequest_check_shadow_io{_}: Bool
    case TemplateRequest_program_deep{}: BIR.Program
    case TemplateRequest_classify{_}: Nat
    case TemplateRequest_deep_chain_check{}: Bool
    case TemplateRequest_erased_fld{}: BIR.DescriptorField
    case TemplateRequest_fam_erased{}: BIR.Family
    case TemplateRequest_families_plan{}: List<&2, BIR.Family>
    case TemplateRequest_row_pt{}: BIR.ConstructorLayout
    case TemplateRequest_row_er{}: BIR.ConstructorLayout
    case TemplateRequest_row_w32{}: BIR.ConstructorLayout
    case TemplateRequest_program_rows{}: BIR.Program
    case TemplateRequest_fam_pt3{}: BIR.Family
    case TemplateRequest_program_scope{}: BIR.Program
    case TemplateRequest_fam_same_one{}: BIR.Family
    case TemplateRequest_fam_same_two{}: BIR.Family
    case TemplateRequest_program_first{}: BIR.Program
    case TemplateRequest_erased_slot_ordinals{_}: Bool
    case TemplateRequest_check_erased_node{_}: Bool
    case TemplateRequest_check_three_word_node{_}: Bool
    case TemplateRequest_check_packed_one{_}: Bool
    case TemplateRequest_check_node_failed{_}: Bool
    case TemplateRequest_check_declared_count{_, _}: Bool
    case TemplateRequest_check_declared_none{_}: Bool
    case TemplateRequest_recursion_layout{_, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_recursion_functions{}: List<&2, BIR.TypeFunction>
    case TemplateRequest_recursive_descriptors{}: List<&2, BIR.Descriptor>
    case TemplateRequest_recursive_descriptor_failures{_, _}: U32
    case TemplateRequest_check_single_box_field{_}: Bool
    case TemplateRequest_check_recursive_key{_, _}: Bool
    case TemplateRequest_generic_recursion_check{}: Bool
    case TemplateRequest_duplicate_recursion_check{}: Bool
    case TemplateRequest_target_exclusion_boundaries{}: U32
    case TemplateRequest_target_closure_authority_check{}: Bool
    case TemplateRequest_explicit_recursion_check{}: Bool
    case TemplateRequest_recursion_boundaries{}: U32
    case TemplateRequest_main{_}: ClaySmoke
    case TemplateRequest_cps_provider_1_context{_}: cps_provider_1_Context
    case TemplateRequest_cps_provider_1_context_nf{_}: cps_provider_2_NfContext
    case TemplateRequest_cps_provider_1_context_families{_}: List<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_context_plan{_}: cps_provider_1_Plan
    case TemplateRequest_cps_provider_1_context_nodes{_}: Map<&2, cps_provider_1_NodeResult>
    case TemplateRequest_cps_provider_1_context_arms{_}: Map<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_context_closed{_}: Map<&2, Bool>
    case TemplateRequest_cps_provider_1_nf_families{_}: Map<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_nf_functions{_}: Map<&2, BIR.TypeFunction>

def template_result_group_2(request: TemplateRequestGroup2) -> Data:
  match request:
    case TemplateRequest_cps_provider_1_family_lookup{_, _}: Maybe<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_function_lookup{_, _}: Maybe<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_1_arm_of{_, _}: Maybe<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_arm_in{_, _}: Maybe<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_plan_arm_index{_}: Map<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_plan_family_arms{_, _}: Map<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_arm_declared{_, _}: Maybe<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_live_field{_}: Bool
    case TemplateRequest_cps_provider_1_dependency_seed{_, _}: cps_provider_1_Dependencies
    case TemplateRequest_cps_provider_1_dependency_name{_, _}: cps_provider_1_Dependencies
    case TemplateRequest_cps_provider_1_dependency_descriptors{_, _}: cps_provider_1_Dependencies
    case TemplateRequest_cps_provider_1_dependency_patterns{_, _}: cps_provider_1_Dependencies
    case TemplateRequest_cps_provider_1_dependency_descriptor{_, _}: cps_provider_1_Dependencies
    case TemplateRequest_cps_provider_1_dependency_fields{_, _}: cps_provider_1_Dependencies
    case TemplateRequest_cps_provider_1_dependency_arms{_, _}: cps_provider_1_Dependencies
    case TemplateRequest_cps_provider_1_dependency_families{_, _}: Map<&2, cps_provider_1_Dependencies>
    case TemplateRequest_cps_provider_1_dependency_functions{_, _}: Map<&2, cps_provider_1_Dependencies>
    case TemplateRequest_cps_provider_1_dependency_maybe_reaches{_, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_dependency_closed{_, _}: Bool
    case TemplateRequest_cps_provider_1_plan_closed_facts{_, _, _, _}: Map<&2, Bool>
    case TemplateRequest_cps_provider_1_layout_fuel{}: Nat
    case TemplateRequest_cps_provider_1_nf_of{_, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_1_value_layout{_, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_of_desc{_, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_of_val{_, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_val{_, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_unresolved{_, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_family{_, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_native{_, _, _, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_field_scope{_}: List<&2, cps_provider_2_NfVal>
    case TemplateRequest_cps_provider_1_arm_layouts{_, _, _, _, _}: cps_provider_1_Plans
    case TemplateRequest_cps_provider_1_field_layouts{_, _, _, _, _}: cps_provider_1_Layouts
    case TemplateRequest_cps_provider_1_layout_data{_, _, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_data_reenters{_, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_arms_tagged{_}: Bool
    case TemplateRequest_cps_provider_1_reenters{_, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_fields_self_reference{_, _}: Bool
    case TemplateRequest_cps_provider_1_fields_reach{_, _, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_reaches{_, _, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_reaches_val{_, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_family_reach{_, _, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_reach_arms{_, _, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_args_reach{_, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_str_member{_, _}: Bool
    case TemplateRequest_cps_provider_1_layout_kinds{_}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_layout_words{_}: Nat
    case TemplateRequest_cps_provider_1_canonical_word{_}: cps_provider_1_CWord
    case TemplateRequest_cps_provider_1_pack_arms{_, _}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_pack_arm_list{_, _, _}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_pack_field_list{_, _, _}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_pack_kinds{_, _, _}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_set_kind{_, _, _}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_merge_kind{_, _}: cps_provider_1_CWord
    case TemplateRequest_cps_provider_1_word_32{_}: Bool
    case TemplateRequest_cps_provider_1_pad_words{_}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_pad_to{_, _}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_pow2_upto{_, _}: Nat
    case TemplateRequest_cps_provider_1_ceil_log2{_}: Nat
    case TemplateRequest_cps_provider_1_ceil_log2_go{_, _, _}: Nat
    case TemplateRequest_cps_provider_1_node_layout{_, _}: cps_provider_1_NodeResult
    case TemplateRequest_cps_provider_1_node_layout_fuel{_, _, _}: cps_provider_1_NodeResult
    case TemplateRequest_cps_provider_1_node_at{_, _, _}: cps_provider_1_NodeResult
    case TemplateRequest_cps_provider_1_plan_node{_, _}: cps_provider_1_NodeResult
    case TemplateRequest_cps_provider_1_node_compute{_, _, _}: cps_provider_1_NodeResult

def template_result_group_3(request: TemplateRequestGroup3) -> Data:
  match request:
    case TemplateRequest_cps_provider_1_unresolved_message{_}: String
    case TemplateRequest_cps_provider_1_node_arm{_, _, _}: cps_provider_1_NodeResult
    case TemplateRequest_cps_provider_1_plan_node_index{_, _}: Map<&2, cps_provider_1_NodeResult>
    case TemplateRequest_cps_provider_1_node_declared{_, _}: cps_provider_1_NodeResult
    case TemplateRequest_cps_provider_1_node_slots{_, _, _, _, _, _}: cps_provider_1_Slots
    case TemplateRequest_cps_provider_1_node_finish{_}: cps_provider_1_NodeResult
    case TemplateRequest_cps_provider_1_slot_words{_}: List<&2, cps_provider_1_CWord>
    case TemplateRequest_cps_provider_1_packed_words{_}: Bool
    case TemplateRequest_cps_provider_1_node_slot{_, _, _}: cps_provider_1_SlotResult
    case TemplateRequest_cps_provider_1_slot_find{_, _}: Maybe<&2, cps_provider_1_NodeSlot>
    case TemplateRequest_cps_provider_1_layout_fill{_, _}: cps_provider_1_FillResult
    case TemplateRequest_cps_provider_1_layout_fill_fuel{_, _, _}: cps_provider_1_FillResult
    case TemplateRequest_cps_provider_1_layout_unfill{_, _}: cps_provider_1_UnfillResult
    case TemplateRequest_cps_provider_1_layout_unfill_fuel{_, _, _}: cps_provider_1_UnfillResult
    case TemplateRequest_cps_provider_1_slot_fill{_, _, _}: cps_provider_1_FillResult
    case TemplateRequest_cps_provider_1_slot_unfill{_, _, _}: cps_provider_1_UnfillResult
    case TemplateRequest_cps_provider_1_form_arms{_, _, _, _, _, _, _, _}: cps_provider_1_Arms
    case TemplateRequest_cps_provider_1_form_arm{_, _, _, _, _, _, _, _}: cps_provider_1_FormArmResult
    case TemplateRequest_cps_provider_1_tag_word{_}: Nat
    case TemplateRequest_cps_provider_1_form_nests{_, _, _, _, _, _, _, _, _}: cps_provider_1_Nests
    case TemplateRequest_cps_provider_1_nest{_, _, _, _}: cps_provider_1_Nest
    case TemplateRequest_cps_provider_1_nest_fits{_, _, _, _, _, _}: Bool
    case TemplateRequest_cps_provider_1_fill_words{_}: Nat
    case TemplateRequest_cps_provider_1_unfill_words{_}: Nat
    case TemplateRequest_cps_provider_1_head_native{_, _}: cps_provider_1_HeadResult
    case TemplateRequest_cps_provider_1_head_other{_}: cps_provider_1_HeadResult
    case TemplateRequest_cps_provider_1_head_value{_, _}: cps_provider_1_HeadResult
    case TemplateRequest_cps_provider_1_norm{_, _}: cps_provider_1_NormResult
    case TemplateRequest_cps_provider_1_head_args{_, _}: cps_provider_1_ArgsResult
    case TemplateRequest_cps_provider_1_arm_fields{_, _, _}: cps_provider_1_FieldsResult
    case TemplateRequest_cps_provider_1_arm_fields_value{_, _, _}: cps_provider_1_FieldsResult
    case TemplateRequest_cps_provider_1_instantiate_fields{_, _, _, _}: cps_provider_1_FieldsResult
    case TemplateRequest_cps_provider_1_array_cell{_, _}: cps_provider_1_CellResult
    case TemplateRequest_cps_provider_1_cell_of{_}: cps_provider_1_CellResult
    case TemplateRequest_cps_provider_1_cell_boxed{_}: cps_provider_1_CellResult
    case TemplateRequest_cps_provider_1_max_one{_}: Nat
    case TemplateRequest_cps_provider_1_layout_has_term{_}: Bool
    case TemplateRequest_cps_provider_1_word_has_term{_}: Bool
    case TemplateRequest_cps_provider_1_any_word_has_term{_}: Bool
    case TemplateRequest_cps_provider_2_family_index{_}: Map<&2, BIR.Family>
    case TemplateRequest_cps_provider_2_function_index{_}: Map<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_2_nf_context{_, _}: cps_provider_2_NfContext
    case TemplateRequest_cps_provider_2_default_fuel{}: Nat
    case TemplateRequest_cps_provider_2_family_of{_, _}: Maybe<&2, BIR.Family>
    case TemplateRequest_cps_provider_2_function_of{_, _}: Maybe<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_2_native_of{_, _, _}: Maybe<&2, String>
    case TemplateRequest_cps_provider_2_val_nth{_, _}: cps_provider_2_NfVal
    case TemplateRequest_cps_provider_2_val_at{_, _, _}: cps_provider_2_NfVal
    case TemplateRequest_cps_provider_2_val_at_choose{_, _, _, _}: cps_provider_2_NfVal
    case TemplateRequest_cps_provider_2_first_vals{_, _}: List<&2, cps_provider_2_NfVal>
    case TemplateRequest_cps_provider_2_drop_vals{_, _}: List<&2, cps_provider_2_NfVal>
    case TemplateRequest_cps_provider_2_insert_before{_, _, _}: List<&2, cps_provider_2_NfVal>
    case TemplateRequest_cps_provider_2_append_vals{_, _}: List<&2, cps_provider_2_NfVal>
    case TemplateRequest_cps_provider_2_quantity_markers{_}: List<&2, cps_provider_2_NfVal>
    case TemplateRequest_cps_provider_2_renamed_level{_, _}: Nat
    case TemplateRequest_cps_provider_2_materialize_all_scoped{_, _, _}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_2_materialize_all_at{_, _}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_2_materialize_all{_}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_2_materialize_scoped{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_materialize_at{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_materialize{_}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_reify_env{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_status_combine{_, _}: cps_provider_2_NfStatus
    case TemplateRequest_cps_provider_2_bind_status{_, _}: cps_provider_2_NfStatus

def template_result_group_4(request: TemplateRequestGroup4) -> Data:
  match request:
    case TemplateRequest_cps_provider_2_bind_values{_, _}: List<&2, cps_provider_2_NfVal>
    case TemplateRequest_cps_provider_2_bind_patterns{_, _}: cps_provider_2_NfBind
    case TemplateRequest_cps_provider_2_nf{_, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_descriptor{_, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_arrow{_, _, _, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_descriptor_step{_, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_all{_, _, _, _, _}: cps_provider_2_NfList
    case TemplateRequest_cps_provider_2_nf_apply_args{_, _, _, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_apply_source{_, _, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_apply{_, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_apply_one{_, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_intrinsic_io{_}: Bool
    case TemplateRequest_cps_provider_2_nf_named_io{_, _, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_named{_, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_arity{_, _, _}: cps_provider_2_NfArity
    case TemplateRequest_cps_provider_2_nf_family{_, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_family_apply{_, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_reduce{_, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_reduce_apply{_, _, _, _, _, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_reduce_body{_, _, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_nf_cases{_, _, _, _, _, _, _}: cps_provider_2_Nf
    case TemplateRequest_cps_provider_2_normalize{_, _, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_normalize_closed{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_normalize_in{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_outer_application{_}: Maybe<&2, cps_provider_2_NfApp>
    case TemplateRequest_cps_provider_2_outer_walk{_, _}: Maybe<&2, cps_provider_2_NfApp>
    case TemplateRequest_cps_provider_2_answer_in{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_answer_descriptor{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_answer_normalized{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_2_is_io_head_in{_, _}: Bool
    case TemplateRequest_cps_provider_2_is_io_head{_, _, _}: Bool

def template_result(request: TemplateRequest) -> Data:
  match request:
    case TemplateRequestGroup_0{inner}: template_result_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_result_group_1(inner)
    case TemplateRequestGroup_2{inner}: template_result_group_2(inner)
    case TemplateRequestGroup_3{inner}: template_result_group_3(inner)
    case TemplateRequestGroup_4{inner}: template_result_group_4(inner)

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

def template_pure_both(+v_1: Bool, +v_3: Bool) -> Bool:
  match v_1:
    case True{}:
      v_3
    case False{}:
      False{}

def template_match_1(+v_3: Bool) -> Bool:
  match v_3:
    case True{}:
      False{}
    case False{}:
      True{}

def template_pure_bool_eq(+v_1: Bool, +v_3: Bool) -> Bool:
  match v_1:
    case True{}:
      v_3
    case False{}:
      template_match_1(v_3)

def template_match_3(+v_6: cps_provider_1_CWord) -> Bool:
  match v_6:
    case cps_provider_1_CWord32{}:
      True{}
    case _:
      False{}

def template_pure_first_word_32(+v_2: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_6 <> v_7:
      template_match_3(v_6)

def template_match_5(+v_6: cps_provider_1_CWord) -> Bool:
  match v_6:
    case cps_provider_1_CWord64{}:
      True{}
    case _:
      False{}

def template_pure_first_word_64(+v_2: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_6 <> v_7:
      template_match_5(v_6)

def template_match_7(+v_6: cps_provider_1_CWord) -> Bool:
  match v_6:
    case cps_provider_1_CWordBox{}:
      True{}
    case _:
      False{}

def template_pure_first_word_box(+v_2: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_6 <> v_7:
      template_match_7(v_6)

def template_pure_check_fields_failure(+v_1: cps_provider_1_FieldsResult) -> Bool:
  match v_1:
    case cps_provider_1_FieldsFailed{+v_4}:
      True{}
    case cps_provider_1_FieldsFound{+v_6}:
      False{}

def template_pure_check_long_arm(+v_1: Maybe<&2, BIR.DescriptorArm>) -> Bool:
  match v_1:
    case None{}:
      False{}
    case Some{+v_4}:
      True{}

def template_pure_check_norm_failure(+v_1: cps_provider_1_NormResult) -> Bool:
  match v_1:
    case cps_provider_1_NormFailed{v_4}:
      True{}
    case cps_provider_1_NormOk{+v_6}:
      False{}

def template_pure_check_args_failure(+v_1: cps_provider_1_ArgsResult) -> Bool:
  match v_1:
    case cps_provider_1_ArgsFailed{v_4}:
      True{}
    case cps_provider_1_ArgsOk{+v_6}:
      False{}

def template_match_13(+v_4: cps_provider_1_BoxReason) -> Bool:
  match v_4:
    case cps_provider_1_BoxOpen{}:
      True{}
    case _:
      False{}

def template_pure_check_io_under(+v_1: cps_provider_1_HeadResult) -> Bool:
  match v_1:
    case cps_provider_1_HeadBoxed{+v_4}:
      template_match_13(v_4)
    case _:
      False{}

def template_pure_check_node_failed(+v_1: cps_provider_1_NodeResult) -> Bool:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      True{}
    case cps_provider_1_NodeFound{+v_6}:
      False{}

def template_pure_check_declared_none(+v_1: Maybe<&2, BIR.DescriptorArm>) -> Bool:
  match v_1:
    case None{}:
      True{}
    case Some{+v_4}:
      False{}

def template_pure_cps_provider_1_context_nf(+v_1: cps_provider_1_Context) -> cps_provider_2_NfContext:
  match v_1:
    case cps_provider_1_Context{+v_6, +v_7, +v_8}:
      v_6

def template_pure_cps_provider_1_context_families(+v_1: cps_provider_1_Context) -> List<&2, BIR.Family>:
  match v_1:
    case cps_provider_1_Context{+v_6, +v_7, +v_8}:
      v_7

def template_pure_cps_provider_1_context_plan(+v_1: cps_provider_1_Context) -> cps_provider_1_Plan:
  match v_1:
    case cps_provider_1_Context{+v_6, +v_7, +v_8}:
      v_8

def template_pure_cps_provider_1_nf_families(+v_1: cps_provider_2_NfContext) -> Map<&2, BIR.Family>:
  match v_1:
    case cps_provider_2_NfContext{+v_5, +v_6}:
      v_5

def template_pure_cps_provider_1_nf_functions(+v_1: cps_provider_2_NfContext) -> Map<&2, BIR.TypeFunction>:
  match v_1:
    case cps_provider_2_NfContext{+v_5, +v_6}:
      v_6

def template_pure_cps_provider_1_live_field(+v_0: BIR.Quantity) -> Bool:
  match v_0:
    case BIR.Erased{}:
      False{}
    case _:
      True{}

def template_pure_cps_provider_1_arms_tagged(+v_2: List<&2, cps_provider_1_LayArm>) -> Bool:
  match v_2:
    case []:
      False{}
    case [+v_5]:
      False{}
    case _:
      True{}

def template_pure_cps_provider_1_canonical_word(+v_1: cps_provider_1_Layout) -> cps_provider_1_CWord:
  match v_1:
    case cps_provider_1_LayoutWord{+v_4}:
      v_4
    case _:
      cps_provider_1_CWordBox{}

def template_match_25(+v_3: cps_provider_1_CWord, +v_1: cps_provider_1_CWord) -> cps_provider_1_CWord:
  match v_3:
    case cps_provider_1_CWord32{}:
      v_1
    case _:
      v_3

def template_pure_cps_provider_1_merge_kind(+v_1: cps_provider_1_CWord, +v_3: cps_provider_1_CWord) -> cps_provider_1_CWord:
  match v_1:
    case cps_provider_1_CWordBox{}:
      v_1
    case _:
      template_match_25(v_3, v_1)

def template_pure_cps_provider_1_word_32(+v_1: cps_provider_1_CWord) -> Bool:
  match v_1:
    case cps_provider_1_CWord32{}:
      True{}
    case _:
      False{}

def template_pure_cps_provider_1_word_has_term(+v_1: cps_provider_1_CWord) -> Bool:
  match v_1:
    case cps_provider_1_CWord32{}:
      False{}
    case _:
      True{}

def template_match_29(v_3: cps_provider_2_NfStatus) -> cps_provider_2_NfStatus:
  match v_3:
    case cps_provider_2_NfStatusNo{}:
      cps_provider_2_NfStatusNo{}
    case _:
      cps_provider_2_NfStatusMaybe{}

def template_pure_cps_provider_2_status_combine(v_1: cps_provider_2_NfStatus, v_3: cps_provider_2_NfStatus) -> cps_provider_2_NfStatus:
  match v_1:
    case cps_provider_2_NfStatusNo{}:
      cps_provider_2_NfStatusNo{}
    case cps_provider_2_NfStatusMaybe{}:
      template_match_29(v_3)
    case cps_provider_2_NfStatusOk{}:
      v_3

def template_match_31(v_8: Maybe<&2, String>) -> Bool:
  match v_8:
    case Some{"IO"}:
      True{}
    case _:
      False{}

def template_pure_cps_provider_2_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      template_match_31(v_8)

def template_body_fld(+v_0: BIR.Descriptor) -> TemplateProgress<BIR.DescriptorField>:
  TemplateFinished{TemplateValue{BIR.DescriptorField{None{}, BIR.Unrestricted{}, v_0}}}

def template_body_arm(+v_1: String, +v_3: List<&2, BIR.DescriptorField>) -> TemplateProgress<BIR.DescriptorArm>:
  TemplateFinished{TemplateValue{BIR.DescriptorArm{v_1, v_3}}}

def template_body_fam(+v_1: String, +v_4: Maybe<&2, String>, +v_6: Nat, +v_8: List<&2, BIR.DescriptorArm>) -> TemplateProgress<BIR.Family>:
  TemplateFinished{TemplateValue{BIR.Family{v_1, v_1, v_4, 0n, v_6, v_8}}}

def template_body_ref(+v_1: String, +v_3: List<&2, BIR.Descriptor>) -> TemplateProgress<BIR.Descriptor>:
  TemplateFinished{TemplateValue{BIR.DescriptorRef{v_1, v_3}}}

def template_body_par(+v_1: Nat) -> TemplateProgress<BIR.Descriptor>:
  TemplateFinished{TemplateValue{BIR.DescriptorParameter{v_1}}}

def template_body_fam_nat() -> TemplateProgress<BIR.Family>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"Nat", Some{"Nat"}, 0n, []}}, False{}, v_1000002 => template_body_fam("Nat", Some{"Nat"}, 0n, []), v_1000001 => +v_1000000 = template_unbox(BIR.Family, v_1000001); TemplateFinished{TemplateValue{v_1000000}}}

def template_body_fam_u32() -> TemplateProgress<BIR.Family>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"U32", Some{"U32"}, 0n, []}}, False{}, v_1000005 => template_body_fam("U32", Some{"U32"}, 0n, []), v_1000004 => +v_1000003 = template_unbox(BIR.Family, v_1000004); TemplateFinished{TemplateValue{v_1000003}}}

def template_body_fam_f32() -> TemplateProgress<BIR.Family>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"F32", Some{"F32"}, 0n, []}}, False{}, v_1000008 => template_body_fam("F32", Some{"F32"}, 0n, []), v_1000007 => +v_1000006 = template_unbox(BIR.Family, v_1000007); TemplateFinished{TemplateValue{v_1000006}}}

def template_body_fam_array() -> TemplateProgress<BIR.Family>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"Array", Some{"Array"}, 1n, []}}, False{}, v_1000011 => template_body_fam("Array", Some{"Array"}, 1n, []), v_1000010 => +v_1000009 = template_unbox(BIR.Family, v_1000010); TemplateFinished{TemplateValue{v_1000009}}}

def template_body_fam_io() -> TemplateProgress<BIR.Family>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"IO.OP", Some{"IO.OP"}, 1n, []}}, False{}, v_1000014 => template_body_fam("IO.OP", Some{"IO.OP"}, 1n, []), v_1000013 => +v_1000012 = template_unbox(BIR.Family, v_1000013); TemplateFinished{TemplateValue{v_1000012}}}

def template_body_fam_pt() -> TemplateProgress<BIR.Family>:
  +v_1000015 = {"Pt" : String}
  +v_1000016 = {None{} : Maybe<&2, String>}
  +v_1000017 = {0n : Nat}
  +v_1000018 = {"Pt" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000036 => template_body_ref("U32", []), v_1000035 => +v_1000019 = template_unbox(BIR.Descriptor, v_1000035); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000019}}, False{}, v_1000034 => template_body_fld(v_1000019), v_1000033 => +v_1000020 = template_unbox(BIR.DescriptorField, v_1000033); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000032 => template_body_ref("U32", []), v_1000031 => +v_1000021 = template_unbox(BIR.Descriptor, v_1000031); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000021}}, False{}, v_1000030 => template_body_fld(v_1000021), v_1000029 => +v_1000022 = template_unbox(BIR.DescriptorField, v_1000029); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000018, [v_1000020, v_1000022]}}, False{}, v_1000028 => template_body_arm(v_1000018, [v_1000020, v_1000022]), v_1000027 => +v_1000023 = template_unbox(BIR.DescriptorArm, v_1000027); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000015, v_1000016, v_1000017, [v_1000023]}}, False{}, v_1000026 => template_body_fam(v_1000015, v_1000016, v_1000017, [v_1000023]), v_1000025 => +v_1000024 = template_unbox(BIR.Family, v_1000025); TemplateFinished{TemplateValue{v_1000024}}}}}}}}

def template_body_fam_fl() -> TemplateProgress<BIR.Family>:
  +v_1000037 = {"Fl" : String}
  +v_1000038 = {None{} : Maybe<&2, String>}
  +v_1000039 = {0n : Nat}
  +v_1000040 = {"Fl" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"F32", []}}, False{}, v_1000058 => template_body_ref("F32", []), v_1000057 => +v_1000041 = template_unbox(BIR.Descriptor, v_1000057); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000041}}, False{}, v_1000056 => template_body_fld(v_1000041), v_1000055 => +v_1000042 = template_unbox(BIR.DescriptorField, v_1000055); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"F32", []}}, False{}, v_1000054 => template_body_ref("F32", []), v_1000053 => +v_1000043 = template_unbox(BIR.Descriptor, v_1000053); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000043}}, False{}, v_1000052 => template_body_fld(v_1000043), v_1000051 => +v_1000044 = template_unbox(BIR.DescriptorField, v_1000051); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000040, [v_1000042, v_1000044]}}, False{}, v_1000050 => template_body_arm(v_1000040, [v_1000042, v_1000044]), v_1000049 => +v_1000045 = template_unbox(BIR.DescriptorArm, v_1000049); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000037, v_1000038, v_1000039, [v_1000045]}}, False{}, v_1000048 => template_body_fam(v_1000037, v_1000038, v_1000039, [v_1000045]), v_1000047 => +v_1000046 = template_unbox(BIR.Family, v_1000047); TemplateFinished{TemplateValue{v_1000046}}}}}}}}

def template_body_fam_seg() -> TemplateProgress<BIR.Family>:
  +v_1000059 = {"Seg" : String}
  +v_1000060 = {None{} : Maybe<&2, String>}
  +v_1000061 = {0n : Nat}
  +v_1000062 = {"Seg" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Pt", []}}, False{}, v_1000086 => template_body_ref("Pt", []), v_1000085 => +v_1000063 = template_unbox(BIR.Descriptor, v_1000085); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000063}}, False{}, v_1000084 => template_body_fld(v_1000063), v_1000083 => +v_1000064 = template_unbox(BIR.DescriptorField, v_1000083); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Pt", []}}, False{}, v_1000082 => template_body_ref("Pt", []), v_1000081 => +v_1000065 = template_unbox(BIR.Descriptor, v_1000081); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000065}}, False{}, v_1000080 => template_body_fld(v_1000065), v_1000079 => +v_1000066 = template_unbox(BIR.DescriptorField, v_1000079); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Fl", []}}, False{}, v_1000078 => template_body_ref("Fl", []), v_1000077 => +v_1000067 = template_unbox(BIR.Descriptor, v_1000077); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000067}}, False{}, v_1000076 => template_body_fld(v_1000067), v_1000075 => +v_1000068 = template_unbox(BIR.DescriptorField, v_1000075); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000062, [v_1000064, v_1000066, v_1000068]}}, False{}, v_1000074 => template_body_arm(v_1000062, [v_1000064, v_1000066, v_1000068]), v_1000073 => +v_1000069 = template_unbox(BIR.DescriptorArm, v_1000073); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000059, v_1000060, v_1000061, [v_1000069]}}, False{}, v_1000072 => template_body_fam(v_1000059, v_1000060, v_1000061, [v_1000069]), v_1000071 => +v_1000070 = template_unbox(BIR.Family, v_1000071); TemplateFinished{TemplateValue{v_1000070}}}}}}}}}}

def template_body_fam_w32() -> TemplateProgress<BIR.Family>:
  +v_1000087 = {"W32" : String}
  +v_1000088 = {None{} : Maybe<&2, String>}
  +v_1000089 = {0n : Nat}
  +v_1000090 = {"W32" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000102 => template_body_ref("U32", []), v_1000101 => +v_1000091 = template_unbox(BIR.Descriptor, v_1000101); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000091}}, False{}, v_1000100 => template_body_fld(v_1000091), v_1000099 => +v_1000092 = template_unbox(BIR.DescriptorField, v_1000099); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000090, [v_1000092]}}, False{}, v_1000098 => template_body_arm(v_1000090, [v_1000092]), v_1000097 => +v_1000093 = template_unbox(BIR.DescriptorArm, v_1000097); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000087, v_1000088, v_1000089, [v_1000093]}}, False{}, v_1000096 => template_body_fam(v_1000087, v_1000088, v_1000089, [v_1000093]), v_1000095 => +v_1000094 = template_unbox(BIR.Family, v_1000095); TemplateFinished{TemplateValue{v_1000094}}}}}}

def template_body_fam_onenat() -> TemplateProgress<BIR.Family>:
  +v_1000103 = {"OneNat" : String}
  +v_1000104 = {None{} : Maybe<&2, String>}
  +v_1000105 = {0n : Nat}
  +v_1000106 = {"OneNat" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1000118 => template_body_ref("Nat", []), v_1000117 => +v_1000107 = template_unbox(BIR.Descriptor, v_1000117); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000107}}, False{}, v_1000116 => template_body_fld(v_1000107), v_1000115 => +v_1000108 = template_unbox(BIR.DescriptorField, v_1000115); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000106, [v_1000108]}}, False{}, v_1000114 => template_body_arm(v_1000106, [v_1000108]), v_1000113 => +v_1000109 = template_unbox(BIR.DescriptorArm, v_1000113); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000103, v_1000104, v_1000105, [v_1000109]}}, False{}, v_1000112 => template_body_fam(v_1000103, v_1000104, v_1000105, [v_1000109]), v_1000111 => +v_1000110 = template_unbox(BIR.Family, v_1000111); TemplateFinished{TemplateValue{v_1000110}}}}}}

def template_body_fam_empty() -> TemplateProgress<BIR.Family>:
  +v_1000119 = {"Empty0" : String}
  +v_1000120 = {None{} : Maybe<&2, String>}
  +v_1000121 = {0n : Nat}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{"Empty0", []}}, False{}, v_1000127 => template_body_arm("Empty0", []), v_1000126 => +v_1000122 = template_unbox(BIR.DescriptorArm, v_1000126); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000119, v_1000120, v_1000121, [v_1000122]}}, False{}, v_1000125 => template_body_fam(v_1000119, v_1000120, v_1000121, [v_1000122]), v_1000124 => +v_1000123 = template_unbox(BIR.Family, v_1000124); TemplateFinished{TemplateValue{v_1000123}}}}

def template_body_fam_box() -> TemplateProgress<BIR.Family>:
  +v_1000128 = {"Box" : String}
  +v_1000129 = {None{} : Maybe<&2, String>}
  +v_1000130 = {1n : Nat}
  +v_1000131 = {"Box" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000143 => template_body_par(0n), v_1000142 => +v_1000132 = template_unbox(BIR.Descriptor, v_1000142); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000132}}, False{}, v_1000141 => template_body_fld(v_1000132), v_1000140 => +v_1000133 = template_unbox(BIR.DescriptorField, v_1000140); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000131, [v_1000133]}}, False{}, v_1000139 => template_body_arm(v_1000131, [v_1000133]), v_1000138 => +v_1000134 = template_unbox(BIR.DescriptorArm, v_1000138); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000128, v_1000129, v_1000130, [v_1000134]}}, False{}, v_1000137 => template_body_fam(v_1000128, v_1000129, v_1000130, [v_1000134]), v_1000136 => +v_1000135 = template_unbox(BIR.Family, v_1000136); TemplateFinished{TemplateValue{v_1000135}}}}}}

def template_body_fam_pair() -> TemplateProgress<BIR.Family>:
  +v_1000144 = {"Pair" : String}
  +v_1000145 = {None{} : Maybe<&2, String>}
  +v_1000146 = {2n : Nat}
  +v_1000147 = {"Pair" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{1n}}, False{}, v_1000165 => template_body_par(1n), v_1000164 => +v_1000148 = template_unbox(BIR.Descriptor, v_1000164); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000148}}, False{}, v_1000163 => template_body_fld(v_1000148), v_1000162 => +v_1000149 = template_unbox(BIR.DescriptorField, v_1000162); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{1n}}, False{}, v_1000161 => template_body_par(1n), v_1000160 => +v_1000150 = template_unbox(BIR.Descriptor, v_1000160); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000150}}, False{}, v_1000159 => template_body_fld(v_1000150), v_1000158 => +v_1000151 = template_unbox(BIR.DescriptorField, v_1000158); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000147, [v_1000149, v_1000151]}}, False{}, v_1000157 => template_body_arm(v_1000147, [v_1000149, v_1000151]), v_1000156 => +v_1000152 = template_unbox(BIR.DescriptorArm, v_1000156); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000144, v_1000145, v_1000146, [v_1000152]}}, False{}, v_1000155 => template_body_fam(v_1000144, v_1000145, v_1000146, [v_1000152]), v_1000154 => +v_1000153 = template_unbox(BIR.Family, v_1000154); TemplateFinished{TemplateValue{v_1000153}}}}}}}}

def template_continuation_33(+v_1000166: String, +v_1000167: Maybe<&2, String>, +v_1000168: Nat, +v_1000169: BIR.DescriptorArm) -> TemplateProgress<BIR.Family>:
  +v_1000170 = {"Some" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000182 => template_body_ref("U32", []), v_1000181 => +v_1000171 = template_unbox(BIR.Descriptor, v_1000181); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000171}}, False{}, v_1000180 => template_body_fld(v_1000171), v_1000179 => +v_1000172 = template_unbox(BIR.DescriptorField, v_1000179); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000170, [v_1000172]}}, False{}, v_1000178 => template_body_arm(v_1000170, [v_1000172]), v_1000177 => +v_1000173 = template_unbox(BIR.DescriptorArm, v_1000177); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000166, v_1000167, v_1000168, [v_1000169, v_1000173]}}, False{}, v_1000176 => template_body_fam(v_1000166, v_1000167, v_1000168, [v_1000169, v_1000173]), v_1000175 => +v_1000174 = template_unbox(BIR.Family, v_1000175); TemplateFinished{TemplateValue{v_1000174}}}}}}

def template_body_fam_opt() -> TemplateProgress<BIR.Family>:
  +v_1000167 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{"None", []}}, False{}, v_1000184 => template_body_arm("None", []), v_1000183 => +v_1000169 = template_unbox(BIR.DescriptorArm, v_1000183); template_continuation_33({"Opt" : String}, v_1000167, {0n : Nat}, v_1000169)}

def template_body_fam_list() -> TemplateProgress<BIR.Family>:
  +v_1000185 = {"ListT" : String}
  +v_1000186 = {None{} : Maybe<&2, String>}
  +v_1000187 = {0n : Nat}
  +v_1000188 = {"Cons" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000206 => template_body_ref("U32", []), v_1000205 => +v_1000189 = template_unbox(BIR.Descriptor, v_1000205); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000189}}, False{}, v_1000204 => template_body_fld(v_1000189), v_1000203 => +v_1000190 = template_unbox(BIR.DescriptorField, v_1000203); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000202 => template_body_ref("ListT", []), v_1000201 => +v_1000191 = template_unbox(BIR.Descriptor, v_1000201); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000191}}, False{}, v_1000200 => template_body_fld(v_1000191), v_1000199 => +v_1000192 = template_unbox(BIR.DescriptorField, v_1000199); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000188, [v_1000190, v_1000192]}}, False{}, v_1000198 => template_body_arm(v_1000188, [v_1000190, v_1000192]), v_1000197 => +v_1000193 = template_unbox(BIR.DescriptorArm, v_1000197); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000185, v_1000186, v_1000187, [v_1000193]}}, False{}, v_1000196 => template_body_fam(v_1000185, v_1000186, v_1000187, [v_1000193]), v_1000195 => +v_1000194 = template_unbox(BIR.Family, v_1000195); TemplateFinished{TemplateValue{v_1000194}}}}}}}}

def template_body_families() -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_nat{}}, False{}, v_1000251 => template_body_fam_nat, v_1000250 => +v_1000207 = template_unbox(BIR.Family, v_1000250); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000249 => template_body_fam_u32, v_1000248 => +v_1000208 = template_unbox(BIR.Family, v_1000248); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_f32{}}, False{}, v_1000247 => template_body_fam_f32, v_1000246 => +v_1000209 = template_unbox(BIR.Family, v_1000246); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_array{}}, False{}, v_1000245 => template_body_fam_array, v_1000244 => +v_1000210 = template_unbox(BIR.Family, v_1000244); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_io{}}, False{}, v_1000243 => template_body_fam_io, v_1000242 => +v_1000211 = template_unbox(BIR.Family, v_1000242); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_pt{}}, False{}, v_1000241 => template_body_fam_pt, v_1000240 => +v_1000212 = template_unbox(BIR.Family, v_1000240); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_fl{}}, False{}, v_1000239 => template_body_fam_fl, v_1000238 => +v_1000213 = template_unbox(BIR.Family, v_1000238); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_seg{}}, False{}, v_1000237 => template_body_fam_seg, v_1000236 => +v_1000214 = template_unbox(BIR.Family, v_1000236); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_w32{}}, False{}, v_1000235 => template_body_fam_w32, v_1000234 => +v_1000215 = template_unbox(BIR.Family, v_1000234); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_onenat{}}, False{}, v_1000233 => template_body_fam_onenat, v_1000232 => +v_1000216 = template_unbox(BIR.Family, v_1000232); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_empty{}}, False{}, v_1000231 => template_body_fam_empty, v_1000230 => +v_1000217 = template_unbox(BIR.Family, v_1000230); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_box{}}, False{}, v_1000229 => template_body_fam_box, v_1000228 => +v_1000218 = template_unbox(BIR.Family, v_1000228); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_pair{}}, False{}, v_1000227 => template_body_fam_pair, v_1000226 => +v_1000219 = template_unbox(BIR.Family, v_1000226); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_opt{}}, False{}, v_1000225 => template_body_fam_opt, v_1000224 => +v_1000220 = template_unbox(BIR.Family, v_1000224); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_list{}}, False{}, v_1000223 => template_body_fam_list, v_1000222 => +v_1000221 = template_unbox(BIR.Family, v_1000222); TemplateFinished{TemplateValue{[v_1000207, v_1000208, v_1000209, v_1000210, v_1000211, v_1000212, v_1000213, v_1000214, v_1000215, v_1000216, v_1000217, v_1000218, v_1000219, v_1000220, v_1000221]}}}}}}}}}}}}}}}}}

def template_continuation_34(v_1000252: String, v_1000253: Maybe<&2, String>, v_1000254: Nat, v_1000255: Nat, +v_1000256: BIR.Descriptor, v_1000257: String, v_1000258: Maybe<&2, String>, v_1000259: Nat, v_1000260: Nat, +v_1000263: BIR.Descriptor, v_1000264: String, v_1000265: Maybe<&2, String>, v_1000266: Nat, v_1000267: Nat, v_1000268: BIR.Quantity, +v_1000269: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  +v_1000270 = {"IO.OP" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000276 => template_body_par(0n), v_1000275 => +v_1000271 = template_unbox(BIR.Descriptor, v_1000275); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000270, [v_1000271]}}, False{}, v_1000274 => template_body_ref(v_1000270, [v_1000271]), v_1000273 => +v_1000272 = template_unbox(BIR.Descriptor, v_1000273); TemplateFinished{TemplateValue{[BIR.TypeFunction{v_1000252, v_1000253, v_1000254, v_1000255, v_1000256}, BIR.TypeFunction{v_1000257, v_1000258, v_1000259, v_1000260, v_1000263}, BIR.TypeFunction{v_1000264, v_1000265, v_1000266, v_1000267, BIR.DescriptorArrow{v_1000268, v_1000269, v_1000272}}]}}}}

def template_continuation_35(v_1000252: String, v_1000253: Maybe<&2, String>, v_1000254: Nat, v_1000255: Nat, +v_1000256: BIR.Descriptor, v_1000257: String, v_1000258: Maybe<&2, String>, v_1000259: Nat, v_1000260: Nat, +v_1000263: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  v_1000265 = {Some{"IO"} : Maybe<&2, String>}
  v_1000268 = {BIR.Unrestricted{} : BIR.Quantity}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"IO.OP", []}}, False{}, v_1000278 => template_body_ref("IO.OP", []), v_1000277 => +v_1000269 = template_unbox(BIR.Descriptor, v_1000277); template_continuation_34(v_1000252, v_1000253, v_1000254, v_1000255, v_1000256, v_1000257, v_1000258, v_1000259, v_1000260, v_1000263, {"IO" : String}, v_1000265, {0n : Nat}, {1n : Nat}, v_1000268, v_1000269)}

def template_continuation_36(v_1000252: String, v_1000253: Maybe<&2, String>, v_1000254: Nat, v_1000255: Nat, +v_1000256: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  v_1000258 = {None{} : Maybe<&2, String>}
  +v_1000261 = {"IO" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1000282 => template_body_ref("Nat", []), v_1000281 => +v_1000262 = template_unbox(BIR.Descriptor, v_1000281); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000261, [v_1000262]}}, False{}, v_1000280 => template_body_ref(v_1000261, [v_1000262]), v_1000279 => +v_1000263 = template_unbox(BIR.Descriptor, v_1000279); template_continuation_35(v_1000252, v_1000253, v_1000254, v_1000255, v_1000256, {"MyIO" : String}, v_1000258, {0n : Nat}, {0n : Nat}, v_1000263)}}

def template_body_type_functions() -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  v_1000253 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1000284 => template_body_ref("Nat", []), v_1000283 => +v_1000256 = template_unbox(BIR.Descriptor, v_1000283); template_continuation_36({"MyNat" : String}, v_1000253, {0n : Nat}, {0n : Nat}, v_1000256)}

def template_body_program() -> TemplateProgress<BIR.Program>:
  v_1000285 = {[] : List<&2, BIR.Code>}
  v_1000286 = {[] : List<&2, BIR.Declaration>}
  v_1000287 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_families{}}, False{}, v_1000293 => template_body_families, v_1000292 => +v_1000288 = template_unbox(List<&2, BIR.Family>, v_1000292); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_type_functions{}}, False{}, v_1000291 => template_body_type_functions, v_1000290 => +v_1000289 = template_unbox(List<&2, BIR.TypeFunction>, v_1000290); TemplateFinished{TemplateValue{BIR.Program{v_1000285, v_1000286, v_1000287, v_1000288, v_1000289, BIR.Library{[]}}}}}}

def template_body_both(+v_1: Bool, +v_3: Bool) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_both(v_1, v_3)}}

def template_body_bool_eq(+v_1: Bool, +v_3: Bool) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_bool_eq(v_1, v_3)}}

def template_body_fail(+v_1: Bool) -> TemplateProgress<U32>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{0}}
    case False{}:
      TemplateFinished{TemplateValue{1}}

def template_body_first_word_32(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_first_word_32(v_2)}}

def template_body_first_word_64(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_first_word_64(v_2)}}

def template_body_first_word_box(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_first_word_box(v_2)}}

def template_match_38(+v_13: cps_provider_1_LayArm, +v_6: cps_provider_1_Layout, +v_9: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_13:
    case cps_provider_1_LayArm{+v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_words{v_6}}, v_1000295 => +v_1000294 = template_unbox(Nat, v_1000295); TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(v_1000294, 2n), template_pure_both(template_pure_first_word_32(v_9), template_pure_both(String.eq(v_17, "Pt"), Nat.is_eq(List.length(&2, cps_provider_1_Layout, v_18), 2n))))}}}

def template_match_39(+v_10: List<&2, cps_provider_1_LayArm>, +v_6: cps_provider_1_Layout, +v_9: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_10:
    case +v_13 <> v_14:
      template_match_38(v_13, v_6, v_9)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_match_40(+v_6: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_LayoutData{+v_9, +v_10}:
      template_match_39(v_10, v_6, v_9)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_pt_value(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_LayoutFound{+v_6}:
      template_match_40(v_6)

def template_match_42(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 2n), template_pure_bool_eq(v_12, False{}))}}

def template_body_check_pt_node(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_42(v_6)

def template_match_44(v_27: List<&2, cps_provider_1_NodeSlot>, +v_12: Nat, +v_22: Nat, +v_32: Nat) -> TemplateProgress<Bool>:
  match v_27:
    case []:
      TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(v_12, 0n), template_pure_both(Nat.is_eq(v_22, 2n), Nat.is_eq(v_32, 4n)))}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_45(+v_26: cps_provider_1_NodeSlot, v_27: List<&2, cps_provider_1_NodeSlot>, +v_12: Nat, +v_22: Nat) -> TemplateProgress<Bool>:
  match v_26:
    case cps_provider_1_NodeSlot{+v_31, +v_32, +v_33}:
      template_match_44(v_27, v_12, v_22, v_32)

def template_match_46(v_17: List<&2, cps_provider_1_NodeSlot>, +v_12: Nat, +v_22: Nat) -> TemplateProgress<Bool>:
  match v_17:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_26 <> v_27:
      template_match_45(v_26, v_27, v_12, v_22)

def template_match_47(+v_16: cps_provider_1_NodeSlot, v_17: List<&2, cps_provider_1_NodeSlot>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_16:
    case cps_provider_1_NodeSlot{+v_21, +v_22, +v_23}:
      template_match_46(v_17, v_12, v_22)

def template_match_48(v_7: List<&2, cps_provider_1_NodeSlot>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_16 <> v_17:
      template_match_47(v_16, v_17, v_12)

def template_match_49(+v_6: cps_provider_1_NodeSlot, v_7: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_NodeSlot{+v_11, +v_12, +v_13}:
      template_match_48(v_7, v_12)

def template_body_slot_offsets(+v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_6 <> v_7:
      template_match_49(v_6, v_7)

def template_match_51(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      +v_1000296 = {Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 6n) : Bool}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_slot_offsets{v_11}}, False{}, v_1000299 => template_body_slot_offsets(v_11), v_1000298 => +v_1000297 = template_unbox(Bool, v_1000298); TemplateFinished{TemplateValue{template_pure_both(v_1000296, template_pure_both(v_1000297, template_pure_bool_eq(v_12, False{})))}}}

def template_body_check_seg_node(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_51(v_6)

def template_match_53(+v_13: cps_provider_1_LayArm, +v_6: cps_provider_1_Layout, +v_9: List<&2, cps_provider_1_CWord>, +v_10: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Bool>:
  match v_13:
    case cps_provider_1_LayArm{+v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_words{v_6}}, v_1000301 => +v_1000300 = template_unbox(Nat, v_1000301); TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(v_1000300, 2n), template_pure_both(template_pure_first_word_32(v_9), template_pure_both(String.eq(v_17, "None"), Nat.is_eq(List.length(&2, cps_provider_1_LayArm, v_10), 2n))))}}}

def template_match_54(+v_10: List<&2, cps_provider_1_LayArm>, +v_6: cps_provider_1_Layout, +v_9: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_10:
    case +v_13 <> v_14:
      template_match_53(v_13, v_6, v_9, v_10)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_match_55(+v_6: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_LayoutData{+v_9, +v_10}:
      template_match_54(v_10, v_6, v_9)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_opt_tag(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_LayoutFound{+v_6}:
      template_match_55(v_6)

def template_match_57(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, True{}), template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 1n), template_pure_first_word_32(v_10)))}}

def template_body_check_w32_packed(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_57(v_6)

def template_match_59(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, False{}), template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 1n), template_pure_first_word_64(v_10)))}}

def template_body_check_nat_not_packed(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_59(v_6)

def template_match_61(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, True{}), Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 0n))}}

def template_body_check_empty_packed(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_61(v_6)

def template_match_63(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, False{}), template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 1n), template_pure_first_word_box(v_10)))}}

def template_body_check_box_declared_node(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_63(v_6)

def template_match_65(+v_18: List<&2, cps_provider_1_Layout>, +v_6: cps_provider_1_Layout, +v_9: List<&2, cps_provider_1_CWord>, +v_17: String) -> TemplateProgress<Bool>:
  match v_18:
    case +v_21 <> v_22:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_words{v_6}}, v_1000303 => +v_1000302 = template_unbox(Nat, v_1000303); TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(v_1000302, 1n), template_pure_both(template_pure_first_word_32(v_9), template_pure_both(String.eq(v_17, "Box"), Nat.is_eq(List.length(&2, cps_provider_1_Layout, v_18), 1n))))}}}
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_match_66(+v_13: cps_provider_1_LayArm, +v_6: cps_provider_1_Layout, +v_9: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_13:
    case cps_provider_1_LayArm{+v_17, +v_18}:
      template_match_65(v_18, v_6, v_9, v_17)

def template_match_67(+v_10: List<&2, cps_provider_1_LayArm>, +v_6: cps_provider_1_Layout, +v_9: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_10:
    case +v_13 <> v_14:
      template_match_66(v_13, v_6, v_9)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_match_68(+v_6: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_LayoutData{+v_9, +v_10}:
      template_match_67(v_10, v_6, v_9)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_box_value(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_LayoutFound{+v_6}:
      template_match_68(v_6)

def template_match_70(+v_6: cps_provider_1_Cell) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Cell{+v_11, +v_12, +v_13, +v_14}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, False{}), template_pure_both(Nat.is_eq(v_13, 1n), Nat.is_eq(v_14, 0n)))}}

def template_body_check_u32_cell(+v_1: cps_provider_1_CellResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_CellFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_CellFound{+v_6}:
      template_match_70(v_6)

def template_match_72(+v_6: cps_provider_1_Cell) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Cell{+v_11, +v_12, +v_13, +v_14}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, True{}), template_pure_both(Nat.is_eq(v_13, 1n), Nat.is_eq(v_14, 0n)))}}

def template_body_check_nat_cell(+v_1: cps_provider_1_CellResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_CellFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_CellFound{+v_6}:
      template_match_72(v_6)

def template_match_74(+v_6: cps_provider_1_Cell) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Cell{+v_11, +v_12, +v_13, +v_14}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, False{}), template_pure_both(Nat.is_eq(v_13, 2n), Nat.is_eq(v_14, 1n)))}}

def template_body_check_pt_cell(+v_1: cps_provider_1_CellResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_CellFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_CellFound{+v_6}:
      template_match_74(v_6)

def template_match_76(+v_6: cps_provider_1_Cell) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Cell{+v_11, +v_12, +v_13, +v_14}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, False{}), template_pure_both(Nat.is_eq(v_13, 6n), Nat.is_eq(v_14, 3n)))}}

def template_body_check_seg_cell(+v_1: cps_provider_1_CellResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_CellFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_CellFound{+v_6}:
      template_match_76(v_6)

def template_match_78(+v_6: cps_provider_1_Cell) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Cell{+v_11, +v_12, +v_13, +v_14}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, True{}), template_pure_both(Nat.is_eq(v_13, 1n), Nat.is_eq(v_14, 0n)))}}

def template_body_check_open_cell(+v_1: cps_provider_1_CellResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_CellFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_CellFound{+v_6}:
      template_match_78(v_6)

def template_match_80(+v_6: cps_provider_1_Cell) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Cell{+v_11, +v_12, +v_13, +v_14}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, True{}), template_pure_both(Nat.is_eq(v_13, 1n), Nat.is_eq(v_14, 0n)))}}

def template_body_check_abstract_cell(+v_1: cps_provider_1_CellResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_CellFailed{v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_CellFound{+v_6}:
      template_match_80(v_6)

def template_match_82(+v_8: cps_provider_1_BoxReason) -> TemplateProgress<Bool>:
  match v_8:
    case cps_provider_1_BoxRecursive{+v_10}:
      TemplateFinished{TemplateValue{String.eq(v_10, "ListT")}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_83(+v_6: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_LayoutBox{+v_8}:
      template_match_82(v_8)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_recursive(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_LayoutFound{+v_6}:
      template_match_83(v_6)

def template_match_85(+v_8: cps_provider_1_BoxReason) -> TemplateProgress<Bool>:
  match v_8:
    case cps_provider_1_BoxUnresolved{+v_10}:
      TemplateFinished{TemplateValue{String.eq(v_10, "Chan")}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_86(+v_6: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_LayoutBox{+v_8}:
      template_match_85(v_8)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_open_box(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_LayoutFound{+v_6}:
      template_match_86(v_6)

def template_body_check_failure(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFailed{+v_4}:
      TemplateFinished{TemplateValue{String.eq(v_4, "the checked type expression is a reducer failure")}}
    case cps_provider_1_LayoutFound{+v_6}:
      TemplateFinished{TemplateValue{False{}}}

def template_match_89(+v_5: List<&2, cps_provider_1_Nest>) -> TemplateProgress<Bool>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{True{}}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_90(+v_23: cps_provider_1_Nest, +v_17: Nat, +v_18: Nat, +v_20: cps_provider_1_Fill, +v_19: cps_provider_1_Unfill, v_12: List<&2, cps_provider_1_Nest>, v_24: List<&2, cps_provider_1_Nest>) -> TemplateProgress<Bool>:
  match v_23:
    case cps_provider_1_Nest{+v_29, +v_30, +v_31, +v_32}:
      +v_1000304 = {Nat.is_eq(v_17, v_30) : Bool}
      +v_1000305 = {Nat.is_eq(v_18, v_29) : Bool}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_fill_words{v_20}}, v_1000315 => +v_1000306 = template_unbox(Nat, v_1000315); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_unfill_words{v_31}}, v_1000314 => +v_1000307 = template_unbox(Nat, v_1000314); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_unfill_words{v_19}}, v_1000313 => +v_1000308 = template_unbox(Nat, v_1000313); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_fill_words{v_32}}, v_1000312 => +v_1000309 = template_unbox(Nat, v_1000312); TemplatePending{TemplateRequestGroup_0{TemplateRequest_nests_agree{v_12, v_24}}, v_1000311 => +v_1000310 = template_unbox(Bool, v_1000311); TemplateFinished{TemplateValue{template_pure_both(v_1000304, template_pure_both(v_1000305, template_pure_both(Nat.is_eq(v_1000306, v_1000307), template_pure_both(Nat.is_eq(v_1000308, v_1000309), v_1000310))))}}}}}}}

def template_match_91(+v_5: List<&2, cps_provider_1_Nest>, +v_17: Nat, +v_18: Nat, +v_20: cps_provider_1_Fill, +v_19: cps_provider_1_Unfill, v_12: List<&2, cps_provider_1_Nest>) -> TemplateProgress<Bool>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_23 <> v_24:
      template_match_90(v_23, v_17, v_18, v_20, v_19, v_12, v_24)

def template_match_92(+v_11: cps_provider_1_Nest, +v_5: List<&2, cps_provider_1_Nest>, v_12: List<&2, cps_provider_1_Nest>) -> TemplateProgress<Bool>:
  match v_11:
    case cps_provider_1_Nest{+v_17, +v_18, +v_19, +v_20}:
      template_match_91(v_5, v_17, v_18, v_20, v_19, v_12)

def template_body_nests_agree(+v_2: List<&2, cps_provider_1_Nest>, +v_5: List<&2, cps_provider_1_Nest>) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      template_match_89(v_5)
    case +v_11 <> v_12:
      template_match_92(v_11, v_5, v_12)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_94(+v_5: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{True{}}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_95(+v_25: cps_provider_1_FormArm, +v_18: String, +v_19: Nat, +v_20: Bool, +v_21: Nat, +v_22: List<&2, cps_provider_1_Nest>, v_12: List<&2, cps_provider_1_FormArm>, v_26: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_25:
    case cps_provider_1_FormArm{+v_32, +v_33, +v_34, +v_35, +v_36}:
      +v_1000316 = {String.eq(v_18, v_32) : Bool}
      +v_1000317 = {Nat.is_eq(v_19, v_33) : Bool}
      +v_1000318 = {template_pure_bool_eq(v_20, v_34) : Bool}
      +v_1000319 = {Nat.is_eq(v_21, v_35) : Bool}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_nests_agree{v_22, v_36}}, False{}, v_1000324 => template_body_nests_agree(v_22, v_36), v_1000323 => +v_1000320 = template_unbox(Bool, v_1000323); TemplatePending{TemplateRequestGroup_0{TemplateRequest_forms_agree{v_12, v_26}}, v_1000322 => +v_1000321 = template_unbox(Bool, v_1000322); TemplateFinished{TemplateValue{template_pure_both(v_1000316, template_pure_both(v_1000317, template_pure_both(v_1000318, template_pure_both(v_1000319, template_pure_both(v_1000320, v_1000321)))))}}}}

def template_match_96(+v_5: List<&2, cps_provider_1_FormArm>, +v_18: String, +v_19: Nat, +v_20: Bool, +v_21: Nat, +v_22: List<&2, cps_provider_1_Nest>, v_12: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_25 <> v_26:
      template_match_95(v_25, v_18, v_19, v_20, v_21, v_22, v_12, v_26)

def template_match_97(+v_11: cps_provider_1_FormArm, +v_5: List<&2, cps_provider_1_FormArm>, v_12: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_11:
    case cps_provider_1_FormArm{+v_18, +v_19, +v_20, +v_21, +v_22}:
      template_match_96(v_5, v_18, v_19, v_20, v_21, v_22, v_12)

def template_body_forms_agree(+v_2: List<&2, cps_provider_1_FormArm>, +v_5: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      template_match_94(v_5)
    case +v_11 <> v_12:
      template_match_97(v_11, v_5, v_12)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_99(+v_5: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_5:
    case cps_provider_1_LayoutFailed{+v_16}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_LayoutFound{+v_18}:
      TemplateFinished{TemplateValue{True{}}}

def template_match_100(+v_14: cps_provider_1_Unfill, +v_5: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_14:
    case cps_provider_1_UnfillWord{}:
      template_match_99(v_5)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_101(+v_3: cps_provider_1_UnfillResult, +v_5: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_3:
    case cps_provider_1_UnfillFailed{+v_12}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_UnfillFound{+v_14}:
      template_match_100(v_14, v_5)

def template_match_102(+v_5: cps_provider_1_LayoutResult, +v_23: Nat, +v_31: Nat, +v_24: List<&2, cps_provider_1_FormArm>, +v_32: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_5:
    case cps_provider_1_LayoutFailed{+v_34}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_LayoutFound{+v_36}:
      +v_1000325 = {Nat.is_eq(v_23, v_31) : Bool}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_forms_agree{v_24, v_32}}, False{}, v_1000328 => template_body_forms_agree(v_24, v_32), v_1000327 => +v_1000326 = template_unbox(Bool, v_1000327); TemplateFinished{TemplateValue{template_pure_both(v_1000325, v_1000326)}}}

def template_match_103(+v_28: cps_provider_1_Unfill, +v_5: cps_provider_1_LayoutResult, +v_23: Nat, +v_24: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_28:
    case cps_provider_1_UnfillForm{+v_31, +v_32}:
      template_match_102(v_5, v_23, v_31, v_24, v_32)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_104(+v_3: cps_provider_1_UnfillResult, +v_5: cps_provider_1_LayoutResult, +v_23: Nat, +v_24: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  match v_3:
    case cps_provider_1_UnfillFailed{+v_26}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_UnfillFound{+v_28}:
      template_match_103(v_28, v_5, v_23, v_24)

def template_match_105(+v_10: cps_provider_1_Fill, +v_3: cps_provider_1_UnfillResult, +v_5: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_10:
    case cps_provider_1_FillWord{}:
      template_match_101(v_3, v_5)
    case cps_provider_1_FillForm{+v_23, +v_24}:
      template_match_104(v_3, v_5, v_23, v_24)

def template_body_check_fill(+v_1: cps_provider_1_FillResult, +v_3: cps_provider_1_UnfillResult, +v_5: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_FillFailed{+v_8}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_FillFound{+v_10}:
      template_match_105(v_10, v_3, v_5)

def template_body_extract(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<cps_provider_1_Layout>:
  match v_1:
    case cps_provider_1_LayoutFound{+v_4}:
      TemplateFinished{TemplateValue{v_4}}
    case cps_provider_1_LayoutFailed{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}

def template_match_108(+v_6: Maybe<&2, String>, +v_5: String) -> TemplateProgress<Bool>:
  match v_6:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{template_pure_both(String.eq(v_5, "Nat"), String.eq(v_8, "Nat"))}}
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_head_nat_alias(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_HeadFound{+v_5, +v_6}:
      template_match_108(v_6, v_5)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_110(+v_6: Maybe<&2, String>, +v_5: String) -> TemplateProgress<Bool>:
  match v_6:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{template_pure_both(String.eq(v_5, "Array"), String.eq(v_8, "Array"))}}
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_head_array(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_HeadFound{+v_5, +v_6}:
      template_match_110(v_6, v_5)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_112(+v_6: Maybe<&2, String>, +v_5: String) -> TemplateProgress<Bool>:
  match v_6:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{False{}}}
    case None{}:
      TemplateFinished{TemplateValue{String.eq(v_5, "Pt")}}

def template_body_check_head_plain(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_HeadFound{+v_5, +v_6}:
      template_match_112(v_6, v_5)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_114(+v_4: cps_provider_1_BoxReason) -> TemplateProgress<Bool>:
  match v_4:
    case cps_provider_1_BoxUnresolved{+v_6}:
      TemplateFinished{TemplateValue{String.eq(v_6, "Chan")}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_head_open(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_HeadBoxed{+v_4}:
      template_match_114(v_4)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_head_failure(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_HeadFailed{+v_4}:
      TemplateFinished{TemplateValue{String.eq(v_4, "the checked type expression is a reducer failure")}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_descriptor_is_ref(+v_0: BIR.Descriptor, +v_2: String) -> TemplateProgress<Bool>:
  match v_0:
    case BIR.DescriptorRef{+v_6, +v_7}:
      TemplateFinished{TemplateValue{String.eq(v_6, v_2)}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_118(+v_9: BIR.DescriptorField, +v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_9:
    case BIR.DescriptorField{+v_14, +v_15, +v_16}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_descriptor_is_ref{v_16, "U32"}}, False{}, v_1000331 => template_body_descriptor_is_ref(v_16, "U32"), v_1000330 => +v_1000329 = template_unbox(Bool, v_1000330); TemplateFinished{TemplateValue{template_pure_both(v_1000329, Nat.is_eq(List.length(&2, BIR.DescriptorField, v_6), 1n))}}}

def template_match_119(+v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_6:
    case +v_9 <> v_10:
      template_match_118(v_9, v_6)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_box_fields(+v_1: cps_provider_1_FieldsResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_FieldsFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_FieldsFound{+v_6}:
      template_match_119(v_6)

def template_match_121(+v_19: BIR.DescriptorField, +v_16: BIR.Descriptor, +v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_19:
    case BIR.DescriptorField{+v_24, +v_25, +v_26}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_descriptor_is_ref{v_16, "U32"}}, False{}, v_1000337 => template_body_descriptor_is_ref(v_16, "U32"), v_1000336 => +v_1000332 = template_unbox(Bool, v_1000336); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_descriptor_is_ref{v_26, "Nat"}}, False{}, v_1000335 => template_body_descriptor_is_ref(v_26, "Nat"), v_1000334 => +v_1000333 = template_unbox(Bool, v_1000334); TemplateFinished{TemplateValue{template_pure_both(v_1000332, template_pure_both(v_1000333, Nat.is_eq(List.length(&2, BIR.DescriptorField, v_6), 2n)))}}}}

def template_match_122(v_10: List<&2, BIR.DescriptorField>, +v_16: BIR.Descriptor, +v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_10:
    case +v_19 <> v_20:
      template_match_121(v_19, v_16, v_6)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_match_123(+v_9: BIR.DescriptorField, v_10: List<&2, BIR.DescriptorField>, +v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_9:
    case BIR.DescriptorField{+v_14, +v_15, +v_16}:
      template_match_122(v_10, v_16, v_6)

def template_match_124(+v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_6:
    case +v_9 <> v_10:
      template_match_123(v_9, v_10, v_6)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_pair_fields(+v_1: cps_provider_1_FieldsResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_FieldsFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_FieldsFound{+v_6}:
      template_match_124(v_6)

def template_body_check_fields_failure(+v_1: cps_provider_1_FieldsResult) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_check_fields_failure(v_1)}}

def template_body_mk_words(+v_1: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case 1n+v_5:
      v_1000338 = {cps_provider_1_CWord32{} : cps_provider_1_CWord}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_mk_words{v_5}}, v_1000340 => +v_1000339 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000340); TemplateFinished{TemplateValue{v_1000338 <> v_1000339}}}

def template_body_mk_fields(+v_1: Nat) -> TemplateProgress<List<&2, BIR.DescriptorField>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case 1n+v_4:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000348 => template_body_ref("U32", []), v_1000347 => +v_1000341 = template_unbox(BIR.Descriptor, v_1000347); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000341}}, False{}, v_1000346 => template_body_fld(v_1000341), v_1000345 => +v_1000342 = template_unbox(BIR.DescriptorField, v_1000345); TemplatePending{TemplateRequestGroup_0{TemplateRequest_mk_fields{v_4}}, v_1000344 => +v_1000343 = template_unbox(List<&2, BIR.DescriptorField>, v_1000344); TemplateFinished{TemplateValue{v_1000342 <> v_1000343}}}}}

def template_body_wide_program() -> TemplateProgress<BIR.Program>:
  v_1000349 = {[] : List<&2, BIR.Code>}
  v_1000350 = {[] : List<&2, BIR.Declaration>}
  v_1000351 = {[] : List<&2, BIR.ConstructorLayout>}
  +v_1000352 = {"Wide" : String}
  +v_1000353 = {None{} : Maybe<&2, String>}
  +v_1000354 = {0n : Nat}
  +v_1000355 = {"Wide" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_mk_fields{1100n}}, False{}, v_1000364 => template_body_mk_fields(1100n), v_1000363 => +v_1000356 = template_unbox(List<&2, BIR.DescriptorField>, v_1000363); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000355, v_1000356}}, False{}, v_1000362 => template_body_arm(v_1000355, v_1000356), v_1000361 => +v_1000357 = template_unbox(BIR.DescriptorArm, v_1000361); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000352, v_1000353, v_1000354, [v_1000357]}}, False{}, v_1000360 => template_body_fam(v_1000352, v_1000353, v_1000354, [v_1000357]), v_1000359 => +v_1000358 = template_unbox(BIR.Family, v_1000359); TemplateFinished{TemplateValue{BIR.Program{v_1000349, v_1000350, v_1000351, [v_1000358], [], BIR.Library{[]}}}}}}}

def template_body_mk_miss(+v_1: Nat) -> TemplateProgress<List<&2, BIR.DescriptorArm>>:
  match v_1:
    case 0n:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{"hit", []}}, False{}, v_1000367 => template_body_arm("hit", []), v_1000366 => +v_1000365 = template_unbox(BIR.DescriptorArm, v_1000366); TemplateFinished{TemplateValue{[v_1000365]}}}
    case 1n+v_5:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{"miss", []}}, False{}, v_1000372 => template_body_arm("miss", []), v_1000371 => +v_1000368 = template_unbox(BIR.DescriptorArm, v_1000371); TemplatePending{TemplateRequestGroup_1{TemplateRequest_mk_miss{v_5}}, v_1000370 => +v_1000369 = template_unbox(List<&2, BIR.DescriptorArm>, v_1000370); TemplateFinished{TemplateValue{v_1000368 <> v_1000369}}}}

def template_body_check_ceil() -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{1n}}, v_1000392 => +v_1000373 = template_unbox(Nat, v_1000392); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{2n}}, v_1000391 => +v_1000374 = template_unbox(Nat, v_1000391); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{3n}}, v_1000390 => +v_1000375 = template_unbox(Nat, v_1000390); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{4n}}, v_1000389 => +v_1000376 = template_unbox(Nat, v_1000389); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{6n}}, v_1000388 => +v_1000377 = template_unbox(Nat, v_1000388); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{8n}}, v_1000387 => +v_1000378 = template_unbox(Nat, v_1000387); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{16n}}, v_1000386 => +v_1000379 = template_unbox(Nat, v_1000386); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{247n}}, v_1000385 => +v_1000380 = template_unbox(Nat, v_1000385); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{248n}}, v_1000384 => +v_1000381 = template_unbox(Nat, v_1000384); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{256n}}, v_1000383 => +v_1000382 = template_unbox(Nat, v_1000383); TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(v_1000373, 0n), template_pure_both(Nat.is_eq(v_1000374, 1n), template_pure_both(Nat.is_eq(v_1000375, 2n), template_pure_both(Nat.is_eq(v_1000376, 2n), template_pure_both(Nat.is_eq(v_1000377, 3n), template_pure_both(Nat.is_eq(v_1000378, 3n), template_pure_both(Nat.is_eq(v_1000379, 4n), template_pure_both(Nat.is_eq(v_1000380, 8n), template_pure_both(Nat.is_eq(v_1000381, 8n), Nat.is_eq(v_1000382, 8n))))))))))}}}}}}}}}}}}

def template_body_check_pow2() -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pow2_upto{1n, 1n}}, v_1000402 => +v_1000393 = template_unbox(Nat, v_1000402); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pow2_upto{1n, 247n}}, v_1000401 => +v_1000394 = template_unbox(Nat, v_1000401); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pow2_upto{1n, 248n}}, v_1000400 => +v_1000395 = template_unbox(Nat, v_1000400); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pow2_upto{1n, 256n}}, v_1000399 => +v_1000396 = template_unbox(Nat, v_1000399); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pow2_upto{1n, 300n}}, v_1000398 => +v_1000397 = template_unbox(Nat, v_1000398); TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(v_1000393, 1n), template_pure_both(Nat.is_eq(v_1000394, 256n), template_pure_both(Nat.is_eq(v_1000395, 256n), template_pure_both(Nat.is_eq(v_1000396, 256n), Nat.is_eq(v_1000397, 512n)))))}}}}}}}

def template_body_check_pad(+v_1: Nat, +v_3: Nat) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_mk_words{v_1}}, False{}, v_1000407 => template_body_mk_words(v_1), v_1000406 => +v_1000403 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000406); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pad_words{v_1000403}}, v_1000405 => +v_1000404 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000405); TemplateFinished{TemplateValue{Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_1000404), v_3)}}}}

def template_match_129(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_11), 1100n), template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 2048n), template_pure_bool_eq(v_12, False{})))}}

def template_body_check_wide(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_129(v_6)

def template_body_check_long_arm(+v_1: Maybe<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_check_long_arm(v_1)}}

def template_body_check_norm_alias(+v_1: cps_provider_1_NormResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NormFailed{v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NormOk{+v_6}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_descriptor_is_ref{v_6, "Nat"}}, False{}, v_1000410 => template_body_descriptor_is_ref(v_6, "Nat"), v_1000409 => +v_1000408 = template_unbox(Bool, v_1000409); TemplateFinished{TemplateValue{v_1000408}}}

def template_match_132(+v_7: List<&2, BIR.Descriptor>, +v_2: String) -> TemplateProgress<Bool>:
  match v_7:
    case +v_10 <> v_11:
      template_body_descriptor_is_ref(v_10, v_2)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_body_first_arg_is(+v_0: BIR.Descriptor, +v_2: String) -> TemplateProgress<Bool>:
  match v_0:
    case BIR.DescriptorRef{+v_6, +v_7}:
      template_match_132(v_7, v_2)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_134(+v_3: cps_provider_1_NormResult, +v_8: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_3:
    case cps_provider_1_NormFailed{v_10}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NormOk{+v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_first_arg_is{v_8, "U32"}}, False{}, v_1000417 => template_body_first_arg_is(v_8, "U32"), v_1000416 => +v_1000412 = template_unbox(Bool, v_1000416); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_first_arg_is{v_12, "Nat"}}, False{}, v_1000415 => template_body_first_arg_is(v_12, "Nat"), v_1000414 => +v_1000413 = template_unbox(Bool, v_1000414); TemplateFinished{TemplateValue{template_pure_both(v_1000412, v_1000413)}}}}

def template_body_check_norm_distinct(+v_1: cps_provider_1_NormResult, +v_3: cps_provider_1_NormResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NormFailed{v_6}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NormOk{+v_8}:
      template_match_134(v_3, v_8)

def template_body_check_norm_failure(+v_1: cps_provider_1_NormResult) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_check_norm_failure(v_1)}}

def template_match_136(+v_8: List<&2, BIR.Descriptor>, +v_3: String) -> TemplateProgress<Bool>:
  match v_8:
    case +v_11 <> v_12:
      template_body_descriptor_is_ref(v_11, v_3)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_body_args_first_is(+v_1: cps_provider_1_ArgsResult, +v_3: String) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_ArgsFailed{v_6}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_ArgsOk{+v_8}:
      template_match_136(v_8, v_3)

def template_match_138(v_10: List<&2, BIR.Descriptor>, +v_9: BIR.Descriptor, +v_6: List<&2, BIR.Descriptor>) -> TemplateProgress<Bool>:
  match v_10:
    case +v_13 <> v_14:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_descriptor_is_ref{v_9, "U32"}}, False{}, v_1000424 => template_body_descriptor_is_ref(v_9, "U32"), v_1000423 => +v_1000419 = template_unbox(Bool, v_1000423); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_descriptor_is_ref{v_13, "Nat"}}, False{}, v_1000422 => template_body_descriptor_is_ref(v_13, "Nat"), v_1000421 => +v_1000420 = template_unbox(Bool, v_1000421); TemplateFinished{TemplateValue{template_pure_both(v_1000419, template_pure_both(v_1000420, Nat.is_eq(List.length(&2, BIR.Descriptor, v_6), 2n)))}}}}
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_match_139(+v_6: List<&2, BIR.Descriptor>) -> TemplateProgress<Bool>:
  match v_6:
    case +v_9 <> v_10:
      template_match_138(v_10, v_9, v_6)
    case []:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_args_pair(+v_1: cps_provider_1_ArgsResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_ArgsFailed{v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_ArgsOk{+v_6}:
      template_match_139(v_6)

def template_body_check_args_failure(+v_1: cps_provider_1_ArgsResult) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_check_args_failure(v_1)}}

def template_body_chain_key(+v_1: Nat) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{String.append("F", Nat.show(v_1))}}

def template_body_next_key(+v_1: Nat) -> TemplateProgress<String>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{"U32"}}
    case 1n+v_4:
      template_body_chain_key(v_4)

def template_continuation_142(+v_1000427: String, +v_7: String, v_4: Nat) -> TemplateProgress<List<&2, BIR.Family>>:
  v_1000428 = {BIR.Family{v_7, v_7, None{}, 0n, 0n, [BIR.DescriptorArm{v_7, [BIR.DescriptorField{None{}, BIR.Unrestricted{}, BIR.DescriptorRef{v_1000427, []}}]}]} : BIR.Family}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_fam_chain{v_4}}, v_1000430 => +v_1000429 = template_unbox(List<&2, BIR.Family>, v_1000430); TemplateFinished{TemplateValue{v_1000428 <> v_1000429}}}

def template_continuation_143(+v_1000426: String, +v_4: Nat) -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_next_key{v_4}}, False{}, v_1000432 => template_body_next_key(v_4), v_1000431 => +v_1000427 = template_unbox(String, v_1000431); template_continuation_142(v_1000427, v_1000426, v_4)}

def template_body_fam_chain(+v_1: Nat) -> TemplateProgress<List<&2, BIR.Family>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, []}]}}
    case 1n+ +v_4:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_chain_key{v_4}}, False{}, v_1000434 => template_body_chain_key(v_4), v_1000433 => +v_1000426 = template_unbox(String, v_1000433); template_continuation_143(v_1000426, v_4)}

def template_continuation_145(v_1000435: List<&2, BIR.Code>, v_1000436: List<&2, BIR.Declaration>, v_1000437: List<&2, BIR.ConstructorLayout>, +v_1000438: BIR.Family) -> TemplateProgress<BIR.Program>:
  v_1000440 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1000445 => template_body_ref("Nat", []), v_1000444 => +v_1000443 = template_unbox(BIR.Descriptor, v_1000444); TemplateFinished{TemplateValue{BIR.Program{v_1000435, v_1000436, v_1000437, [v_1000438], [BIR.TypeFunction{{"IO" : String}, v_1000440, {0n : Nat}, {1n : Nat}, v_1000443}], BIR.Library{[]}}}}}

def template_body_program_shadow() -> TemplateProgress<BIR.Program>:
  v_1000435 = {[] : List<&2, BIR.Code>}
  v_1000436 = {[] : List<&2, BIR.Declaration>}
  v_1000437 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_nat{}}, False{}, v_1000447 => template_body_fam_nat, v_1000446 => +v_1000438 = template_unbox(BIR.Family, v_1000446); template_continuation_145(v_1000435, v_1000436, v_1000437, v_1000438)}

def template_match_146(+v_6: Maybe<&2, String>, +v_5: String) -> TemplateProgress<Bool>:
  match v_6:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{template_pure_both(String.eq(v_5, "IO"), String.eq(v_8, "IO"))}}
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_io_native(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_HeadFound{+v_5, +v_6}:
      template_match_146(v_6, v_5)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_io_under(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_check_io_under(v_1)}}

def template_match_148(+v_6: Maybe<&2, String>, +v_5: String) -> TemplateProgress<Bool>:
  match v_6:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{template_pure_both(String.eq(v_5, "Nat"), String.eq(v_8, "Nat"))}}
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_shadow_io(+v_1: cps_provider_1_HeadResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_HeadFound{+v_5, +v_6}:
      template_match_148(v_6, v_5)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_program_deep() -> TemplateProgress<BIR.Program>:
  v_1000448 = {[] : List<&2, BIR.Code>}
  v_1000449 = {[] : List<&2, BIR.Declaration>}
  v_1000450 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_fam_chain{400n}}, False{}, v_1000453 => template_body_fam_chain(400n), v_1000452 => +v_1000451 = template_unbox(List<&2, BIR.Family>, v_1000452); TemplateFinished{TemplateValue{BIR.Program{v_1000448, v_1000449, v_1000450, v_1000451, [], BIR.Library{[]}}}}}

def template_match_150(+v_10: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Nat>:
  match v_10:
    case +v_17 <> v_18:
      TemplateFinished{TemplateValue{0n}}
    case []:
      TemplateFinished{TemplateValue{2n}}

def template_match_151(v_14: List<&2, cps_provider_1_CWord>, +v_10: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Nat>:
  match v_14:
    case []:
      template_match_150(v_10)
    case _:
      TemplateFinished{TemplateValue{2n}}

def template_match_152(+v_13: cps_provider_1_CWord, v_14: List<&2, cps_provider_1_CWord>, +v_10: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Nat>:
  match v_13:
    case cps_provider_1_CWord32{}:
      template_match_151(v_14, v_10)
    case _:
      TemplateFinished{TemplateValue{2n}}

def template_match_153(+v_9: List<&2, cps_provider_1_CWord>, +v_10: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Nat>:
  match v_9:
    case +v_13 <> v_14:
      template_match_152(v_13, v_14, v_10)
    case []:
      TemplateFinished{TemplateValue{2n}}

def template_match_154(+v_6: cps_provider_1_Layout) -> TemplateProgress<Nat>:
  match v_6:
    case cps_provider_1_LayoutData{+v_9, +v_10}:
      template_match_153(v_9, v_10)
    case cps_provider_1_LayoutBox{+v_24}:
      TemplateFinished{TemplateValue{1n}}
    case _:
      TemplateFinished{TemplateValue{2n}}

def template_body_classify(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Nat>:
  match v_1:
    case cps_provider_1_LayoutFailed{v_4}:
      TemplateFinished{TemplateValue{1n}}
    case cps_provider_1_LayoutFound{+v_6}:
      template_match_154(v_6)

def template_continuation_156(+v_1000455: cps_provider_1_Context) -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{v_1000455, BIR.DescriptorRef{"F399", []}}}, v_1000460 => +v_1000456 = template_unbox(cps_provider_1_LayoutResult, v_1000460); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_1000456}}, False{}, v_1000459 => template_body_classify(v_1000456), v_1000458 => +v_1000457 = template_unbox(Nat, v_1000458); TemplateFinished{TemplateValue{Nat.is_eq(v_1000457, 0n)}}}}

def template_body_deep_chain_check() -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_program_deep{}}, False{}, v_1000463 => template_body_program_deep, v_1000462 => +v_1000454 = template_unbox(BIR.Program, v_1000462); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{v_1000454}}, v_1000461 => +v_1000455 = template_unbox(cps_provider_1_Context, v_1000461); template_continuation_156(v_1000455)}}

def template_body_erased_fld() -> TemplateProgress<BIR.DescriptorField>:
  v_1000464 = {None{} : Maybe<&2, String>}
  v_1000465 = {BIR.Erased{} : BIR.Quantity}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000468 => template_body_ref("U32", []), v_1000467 => +v_1000466 = template_unbox(BIR.Descriptor, v_1000467); TemplateFinished{TemplateValue{BIR.DescriptorField{v_1000464, v_1000465, v_1000466}}}}

def template_body_fam_erased() -> TemplateProgress<BIR.Family>:
  +v_1000469 = {"Er" : String}
  +v_1000470 = {None{} : Maybe<&2, String>}
  +v_1000471 = {0n : Nat}
  +v_1000472 = {"Er" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000493 => template_body_ref("U32", []), v_1000492 => +v_1000473 = template_unbox(BIR.Descriptor, v_1000492); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000473}}, False{}, v_1000491 => template_body_fld(v_1000473), v_1000490 => +v_1000474 = template_unbox(BIR.DescriptorField, v_1000490); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_erased_fld{}}, False{}, v_1000489 => template_body_erased_fld, v_1000488 => +v_1000475 = template_unbox(BIR.DescriptorField, v_1000488); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1000487 => template_body_ref("Nat", []), v_1000486 => +v_1000476 = template_unbox(BIR.Descriptor, v_1000486); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000476}}, False{}, v_1000485 => template_body_fld(v_1000476), v_1000484 => +v_1000477 = template_unbox(BIR.DescriptorField, v_1000484); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000472, [v_1000474, v_1000475, v_1000477]}}, False{}, v_1000483 => template_body_arm(v_1000472, [v_1000474, v_1000475, v_1000477]), v_1000482 => +v_1000478 = template_unbox(BIR.DescriptorArm, v_1000482); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000469, v_1000470, v_1000471, [v_1000478]}}, False{}, v_1000481 => template_body_fam(v_1000469, v_1000470, v_1000471, [v_1000478]), v_1000480 => +v_1000479 = template_unbox(BIR.Family, v_1000480); TemplateFinished{TemplateValue{v_1000479}}}}}}}}}

def template_body_families_plan() -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_fam_erased{}}, False{}, v_1000499 => template_body_fam_erased, v_1000498 => +v_1000494 = template_unbox(BIR.Family, v_1000498); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_families{}}, False{}, v_1000497 => template_body_families, v_1000496 => +v_1000495 = template_unbox(List<&2, BIR.Family>, v_1000496); TemplateFinished{TemplateValue{v_1000494 <> v_1000495}}}}

def template_body_row_pt() -> TemplateProgress<BIR.ConstructorLayout>:
  TemplateFinished{TemplateValue{BIR.ConstructorLayout{0, "Pt", None{}, []}}}

def template_body_row_er() -> TemplateProgress<BIR.ConstructorLayout>:
  TemplateFinished{TemplateValue{BIR.ConstructorLayout{1, "Er", None{}, []}}}

def template_body_row_w32() -> TemplateProgress<BIR.ConstructorLayout>:
  TemplateFinished{TemplateValue{BIR.ConstructorLayout{2, "W32", None{}, []}}}

def template_body_program_rows() -> TemplateProgress<BIR.Program>:
  v_1000500 = {[] : List<&2, BIR.Code>}
  v_1000501 = {[] : List<&2, BIR.Declaration>}
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_row_pt{}}, False{}, v_1000516 => template_body_row_pt, v_1000515 => +v_1000502 = template_unbox(BIR.ConstructorLayout, v_1000515); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_row_er{}}, False{}, v_1000514 => template_body_row_er, v_1000513 => +v_1000503 = template_unbox(BIR.ConstructorLayout, v_1000513); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_row_w32{}}, False{}, v_1000512 => template_body_row_w32, v_1000511 => +v_1000504 = template_unbox(BIR.ConstructorLayout, v_1000511); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_families_plan{}}, False{}, v_1000510 => template_body_families_plan, v_1000509 => +v_1000505 = template_unbox(List<&2, BIR.Family>, v_1000509); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_type_functions{}}, False{}, v_1000508 => template_body_type_functions, v_1000507 => +v_1000506 = template_unbox(List<&2, BIR.TypeFunction>, v_1000507); TemplateFinished{TemplateValue{BIR.Program{v_1000500, v_1000501, [v_1000502, v_1000503, v_1000504], v_1000505, v_1000506, BIR.Library{[]}}}}}}}}}

def template_body_fam_pt3() -> TemplateProgress<BIR.Family>:
  +v_1000517 = {"Pt" : String}
  +v_1000518 = {None{} : Maybe<&2, String>}
  +v_1000519 = {0n : Nat}
  +v_1000520 = {"Pt" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000544 => template_body_ref("U32", []), v_1000543 => +v_1000521 = template_unbox(BIR.Descriptor, v_1000543); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000521}}, False{}, v_1000542 => template_body_fld(v_1000521), v_1000541 => +v_1000522 = template_unbox(BIR.DescriptorField, v_1000541); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000540 => template_body_ref("U32", []), v_1000539 => +v_1000523 = template_unbox(BIR.Descriptor, v_1000539); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000523}}, False{}, v_1000538 => template_body_fld(v_1000523), v_1000537 => +v_1000524 = template_unbox(BIR.DescriptorField, v_1000537); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000536 => template_body_ref("U32", []), v_1000535 => +v_1000525 = template_unbox(BIR.Descriptor, v_1000535); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000525}}, False{}, v_1000534 => template_body_fld(v_1000525), v_1000533 => +v_1000526 = template_unbox(BIR.DescriptorField, v_1000533); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000520, [v_1000522, v_1000524, v_1000526]}}, False{}, v_1000532 => template_body_arm(v_1000520, [v_1000522, v_1000524, v_1000526]), v_1000531 => +v_1000527 = template_unbox(BIR.DescriptorArm, v_1000531); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000517, v_1000518, v_1000519, [v_1000527]}}, False{}, v_1000530 => template_body_fam(v_1000517, v_1000518, v_1000519, [v_1000527]), v_1000529 => +v_1000528 = template_unbox(BIR.Family, v_1000529); TemplateFinished{TemplateValue{v_1000528}}}}}}}}}}

def template_body_program_scope() -> TemplateProgress<BIR.Program>:
  v_1000545 = {[] : List<&2, BIR.Code>}
  v_1000546 = {[] : List<&2, BIR.Declaration>}
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_row_pt{}}, False{}, v_1000561 => template_body_row_pt, v_1000560 => +v_1000547 = template_unbox(BIR.ConstructorLayout, v_1000560); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_nat{}}, False{}, v_1000559 => template_body_fam_nat, v_1000558 => +v_1000548 = template_unbox(BIR.Family, v_1000558); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000557 => template_body_fam_u32, v_1000556 => +v_1000549 = template_unbox(BIR.Family, v_1000556); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_fam_pt3{}}, False{}, v_1000555 => template_body_fam_pt3, v_1000554 => +v_1000550 = template_unbox(BIR.Family, v_1000554); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_type_functions{}}, False{}, v_1000553 => template_body_type_functions, v_1000552 => +v_1000551 = template_unbox(List<&2, BIR.TypeFunction>, v_1000552); TemplateFinished{TemplateValue{BIR.Program{v_1000545, v_1000546, [v_1000547], [v_1000548, v_1000549, v_1000550], v_1000551, BIR.Library{[]}}}}}}}}}

def template_body_fam_same_one() -> TemplateProgress<BIR.Family>:
  +v_1000562 = {"One" : String}
  +v_1000563 = {None{} : Maybe<&2, String>}
  +v_1000564 = {0n : Nat}
  +v_1000565 = {"Same" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000577 => template_body_ref("U32", []), v_1000576 => +v_1000566 = template_unbox(BIR.Descriptor, v_1000576); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000566}}, False{}, v_1000575 => template_body_fld(v_1000566), v_1000574 => +v_1000567 = template_unbox(BIR.DescriptorField, v_1000574); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000565, [v_1000567]}}, False{}, v_1000573 => template_body_arm(v_1000565, [v_1000567]), v_1000572 => +v_1000568 = template_unbox(BIR.DescriptorArm, v_1000572); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000562, v_1000563, v_1000564, [v_1000568]}}, False{}, v_1000571 => template_body_fam(v_1000562, v_1000563, v_1000564, [v_1000568]), v_1000570 => +v_1000569 = template_unbox(BIR.Family, v_1000570); TemplateFinished{TemplateValue{v_1000569}}}}}}

def template_body_fam_same_two() -> TemplateProgress<BIR.Family>:
  +v_1000578 = {"Two" : String}
  +v_1000579 = {None{} : Maybe<&2, String>}
  +v_1000580 = {0n : Nat}
  +v_1000581 = {"Same" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000599 => template_body_ref("U32", []), v_1000598 => +v_1000582 = template_unbox(BIR.Descriptor, v_1000598); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000582}}, False{}, v_1000597 => template_body_fld(v_1000582), v_1000596 => +v_1000583 = template_unbox(BIR.DescriptorField, v_1000596); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000595 => template_body_ref("U32", []), v_1000594 => +v_1000584 = template_unbox(BIR.Descriptor, v_1000594); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000584}}, False{}, v_1000593 => template_body_fld(v_1000584), v_1000592 => +v_1000585 = template_unbox(BIR.DescriptorField, v_1000592); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000581, [v_1000583, v_1000585]}}, False{}, v_1000591 => template_body_arm(v_1000581, [v_1000583, v_1000585]), v_1000590 => +v_1000586 = template_unbox(BIR.DescriptorArm, v_1000590); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000578, v_1000579, v_1000580, [v_1000586]}}, False{}, v_1000589 => template_body_fam(v_1000578, v_1000579, v_1000580, [v_1000586]), v_1000588 => +v_1000587 = template_unbox(BIR.Family, v_1000588); TemplateFinished{TemplateValue{v_1000587}}}}}}}}

def template_body_program_first() -> TemplateProgress<BIR.Program>:
  v_1000600 = {[] : List<&2, BIR.Code>}
  v_1000601 = {[] : List<&2, BIR.Declaration>}
  v_1000602 = {[BIR.ConstructorLayout{0, "Same", None{}, []}] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_nat{}}, False{}, v_1000617 => template_body_fam_nat, v_1000616 => +v_1000603 = template_unbox(BIR.Family, v_1000616); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000615 => template_body_fam_u32, v_1000614 => +v_1000604 = template_unbox(BIR.Family, v_1000614); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_fam_same_one{}}, False{}, v_1000613 => template_body_fam_same_one, v_1000612 => +v_1000605 = template_unbox(BIR.Family, v_1000612); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_fam_same_two{}}, False{}, v_1000611 => template_body_fam_same_two, v_1000610 => +v_1000606 = template_unbox(BIR.Family, v_1000610); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_type_functions{}}, False{}, v_1000609 => template_body_type_functions, v_1000608 => +v_1000607 = template_unbox(List<&2, BIR.TypeFunction>, v_1000608); TemplateFinished{TemplateValue{BIR.Program{v_1000600, v_1000601, v_1000602, [v_1000603, v_1000604, v_1000605, v_1000606], v_1000607, BIR.Library{[]}}}}}}}}}

def template_match_157(+v_16: cps_provider_1_NodeSlot, +v_11: U32, +v_12: Nat, +v_13: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_16:
    case cps_provider_1_NodeSlot{+v_21, +v_22, +v_23}:
      +v_1000618 = {U32.is_eq(v_11, 0) : Bool}
      +v_1000619 = {U32.is_eq(v_21, U32.from_nat(2n)) : Bool}
      +v_1000620 = {Nat.is_eq(v_12, 0n) : Bool}
      +v_1000621 = {Nat.is_eq(v_22, 1n) : Bool}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_words{v_13}}, v_1000625 => +v_1000622 = template_unbox(Nat, v_1000625); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_words{v_23}}, v_1000624 => +v_1000623 = template_unbox(Nat, v_1000624); TemplateFinished{TemplateValue{template_pure_both(v_1000618, template_pure_both(v_1000619, template_pure_both(v_1000620, template_pure_both(v_1000621, template_pure_both(Nat.is_eq(v_1000622, 1n), Nat.is_eq(v_1000623, 1n))))))}}}}

def template_match_158(v_7: List<&2, cps_provider_1_NodeSlot>, +v_11: U32, +v_12: Nat, +v_13: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_16 <> v_17:
      template_match_157(v_16, v_11, v_12, v_13)

def template_match_159(+v_6: cps_provider_1_NodeSlot, v_7: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_NodeSlot{+v_11, +v_12, +v_13}:
      template_match_158(v_7, v_11, v_12, v_13)

def template_body_erased_slot_ordinals(+v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_6 <> v_7:
      template_match_159(v_6, v_7)

def template_match_161(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      +v_1000626 = {template_pure_bool_eq(v_12, False{}) : Bool}
      +v_1000627 = {Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 2n) : Bool}
      +v_1000628 = {template_pure_first_word_32(v_10) : Bool}
      +v_1000629 = {Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_11), 2n) : Bool}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_erased_slot_ordinals{v_11}}, False{}, v_1000632 => template_body_erased_slot_ordinals(v_11), v_1000631 => +v_1000630 = template_unbox(Bool, v_1000631); TemplateFinished{TemplateValue{template_pure_both(v_1000626, template_pure_both(v_1000627, template_pure_both(v_1000628, template_pure_both(v_1000629, v_1000630))))}}}

def template_body_check_erased_node(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_161(v_6)

def template_match_163(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, False{}), template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 3n), Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_11), 3n)))}}

def template_body_check_three_word_node(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_163(v_6)

def template_match_165(+v_6: cps_provider_1_Node) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_Node{+v_10, +v_11, +v_12}:
      TemplateFinished{TemplateValue{template_pure_both(template_pure_bool_eq(v_12, True{}), template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_10), 1n), template_pure_both(template_pure_first_word_32(v_10), Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_11), 1n))))}}

def template_body_check_packed_one(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_NodeFailed{+v_4}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_NodeFound{+v_6}:
      template_match_165(v_6)

def template_body_check_node_failed(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_check_node_failed(v_1)}}

def template_match_167(+v_6: BIR.DescriptorArm, +v_3: Nat) -> TemplateProgress<Bool>:
  match v_6:
    case BIR.DescriptorArm{+v_9, +v_10}:
      TemplateFinished{TemplateValue{Nat.is_eq(List.length(&2, BIR.DescriptorField, v_10), v_3)}}

def template_body_check_declared_count(+v_1: Maybe<&2, BIR.DescriptorArm>, +v_3: Nat) -> TemplateProgress<Bool>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{False{}}}
    case Some{+v_6}:
      template_match_167(v_6, v_3)

def template_body_check_declared_none(+v_1: Maybe<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_check_declared_none(v_1)}}

def template_continuation_169(+v_1000643: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_LayoutResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000649 => template_body_ref("ListT", []), v_1000648 => +v_1000645 = template_unbox(BIR.Descriptor, v_1000648); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_1000643 : cps_provider_1_Context}, v_1000645}}, v_1000647 => +v_1000646 = template_unbox(cps_provider_1_LayoutResult, v_1000647); TemplateFinished{TemplateValue{v_1000646}}}}

def template_continuation_170(+v_1000637: BIR.Family, +v_3: List<&2, BIR.Family>, +v_5: List<&2, BIR.TypeFunction>) -> TemplateProgress<cps_provider_1_LayoutResult>:
  v_1000638 = {[] : List<&2, BIR.Code>}
  v_1000639 = {[] : List<&2, BIR.Declaration>}
  v_1000640 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000652 => template_body_fam_u32, v_1000651 => +v_1000642 = template_unbox(BIR.Family, v_1000651); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1000638, v_1000639, v_1000640, {v_1000637 : BIR.Family} <> v_1000642 <> v_3, v_5, BIR.Library{[]}}}}, v_1000650 => +v_1000643 = template_unbox(cps_provider_1_Context, v_1000650); template_continuation_169(v_1000643)}}

def template_body_recursion_layout(+v_1: List<&2, BIR.DescriptorField>, +v_3: List<&2, BIR.Family>, +v_5: List<&2, BIR.TypeFunction>) -> TemplateProgress<cps_provider_1_LayoutResult>:
  +v_1000633 = {"ListT" : String}
  +v_1000634 = {None{} : Maybe<&2, String>}
  +v_1000635 = {0n : Nat}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{"Root", v_1}}, False{}, v_1000656 => template_body_arm("Root", v_1), v_1000655 => +v_1000636 = template_unbox(BIR.DescriptorArm, v_1000655); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000633, v_1000634, v_1000635, [v_1000636]}}, False{}, v_1000654 => template_body_fam(v_1000633, v_1000634, v_1000635, [v_1000636]), v_1000653 => +v_1000637 = template_unbox(BIR.Family, v_1000653); template_continuation_170(v_1000637, v_3, v_5)}}

def template_continuation_171(v_1000657: String, v_1000658: Maybe<&2, String>, v_1000659: Nat, v_1000660: Nat, +v_1000661: BIR.Descriptor, v_1000662: String, v_1000663: Maybe<&2, String>, v_1000664: Nat, v_1000665: Nat, +v_1000666: BIR.Descriptor, v_1000667: String, v_1000668: Maybe<&2, String>, v_1000669: Nat, v_1000670: Nat, +v_1000671: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  v_1000673 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000678 => template_body_ref("U32", []), v_1000677 => +v_1000676 = template_unbox(BIR.Descriptor, v_1000677); TemplateFinished{TemplateValue{[BIR.TypeFunction{v_1000657, v_1000658, v_1000659, v_1000660, v_1000661}, BIR.TypeFunction{v_1000662, v_1000663, v_1000664, v_1000665, v_1000666}, BIR.TypeFunction{v_1000667, v_1000668, v_1000669, v_1000670, v_1000671}, BIR.TypeFunction{{"Discard" : String}, v_1000673, {0n : Nat}, {1n : Nat}, v_1000676}]}}}

def template_continuation_172(v_1000657: String, v_1000658: Maybe<&2, String>, v_1000659: Nat, v_1000660: Nat, +v_1000661: BIR.Descriptor, v_1000662: String, v_1000663: Maybe<&2, String>, v_1000664: Nat, v_1000665: Nat, +v_1000666: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  v_1000668 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000680 => template_body_par(0n), v_1000679 => +v_1000671 = template_unbox(BIR.Descriptor, v_1000679); template_continuation_171(v_1000657, v_1000658, v_1000659, v_1000660, v_1000661, v_1000662, v_1000663, v_1000664, v_1000665, v_1000666, {"Identity" : String}, v_1000668, {0n : Nat}, {1n : Nat}, v_1000671)}

def template_continuation_173(v_1000657: String, v_1000658: Maybe<&2, String>, v_1000659: Nat, v_1000660: Nat, +v_1000661: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  v_1000663 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000682 => template_body_ref("ListT", []), v_1000681 => +v_1000666 = template_unbox(BIR.Descriptor, v_1000681); template_continuation_172(v_1000657, v_1000658, v_1000659, v_1000660, v_1000661, {"Alias2" : String}, v_1000663, {0n : Nat}, {0n : Nat}, v_1000666)}

def template_body_recursion_functions() -> TemplateProgress<List<&2, BIR.TypeFunction>>:
  v_1000658 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Alias2", []}}, False{}, v_1000684 => template_body_ref("Alias2", []), v_1000683 => +v_1000661 = template_unbox(BIR.Descriptor, v_1000683); template_continuation_173({"Alias1" : String}, v_1000658, {0n : Nat}, {0n : Nat}, v_1000661)}

def template_continuation_174(+v_3: BIR.Descriptor, +v_1000686: BIR.Descriptor, +v_1000687: BIR.Descriptor, v_1000688: BIR.Descriptor, v_1000689: List<&2, BIR.Descriptor>, v_1000690: List<&2, BIR.DescriptorPattern>, +v_1000691: BIR.Descriptor, v_1000692: BIR.Descriptor, v_1000693: Nat, v_1000694: BIR.Descriptor, +v_1000695: BIR.Descriptor, v_1000696: List<&2, BIR.Descriptor>, +v_1000697: BIR.Descriptor, v_1000698: List<&2, BIR.DescriptorPattern>, v_1000699: List<&2, BIR.Descriptor>, +v_1000700: BIR.Descriptor, v_1000701: BIR.Descriptor, +v_1000702: BIR.Descriptor, v_1000703: BIR.Descriptor, v_1000704: BIR.Descriptor, v_1000705: String, +v_1000706: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000713 => template_body_ref("U32", []), v_1000712 => +v_1000708 = template_unbox(BIR.Descriptor, v_1000712); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Opaque", [v_3]}}, False{}, v_1000711 => template_body_ref("Opaque", [v_3]), v_1000710 => +v_1000709 = template_unbox(BIR.Descriptor, v_1000710); TemplateFinished{TemplateValue{[v_1000686, BIR.DescriptorApplication{v_1000687, v_3}, v_1000688, BIR.DescriptorMatch{v_1000689, [BIR.DescriptorCase{v_1000690, v_1000691}]}, v_1000692, BIR.DescriptorSubstitution{v_1000693, v_1000694, v_1000695}, BIR.DescriptorLet{v_1000696, v_1000697}, BIR.DescriptorLocal{v_1000698, v_1000699, v_1000700}, BIR.DescriptorBind{v_1000701, v_1000702}, v_1000703, v_1000704, BIR.DescriptorNamedFill{v_1000705, v_1000706, []}, BIR.DescriptorNamedPlus{{"Alias1" : String}, v_1000708, []}, v_1000709]}}}}

def template_continuation_175(+v_5: BIR.Descriptor, +v_3: BIR.Descriptor, +v_1000686: BIR.Descriptor, +v_1000687: BIR.Descriptor, v_1000688: BIR.Descriptor, v_1000689: List<&2, BIR.Descriptor>, v_1000690: List<&2, BIR.DescriptorPattern>, +v_1000691: BIR.Descriptor, v_1000692: BIR.Descriptor, v_1000693: Nat, v_1000694: BIR.Descriptor, +v_1000695: BIR.Descriptor, v_1000696: List<&2, BIR.Descriptor>, +v_1000697: BIR.Descriptor, v_1000698: List<&2, BIR.DescriptorPattern>, v_1000699: List<&2, BIR.Descriptor>, +v_1000700: BIR.Descriptor, v_1000701: BIR.Descriptor, +v_1000702: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  v_1000703 = {BIR.DescriptorFill{v_5, [BIR.DescriptorNull{}]} : BIR.Descriptor}
  v_1000704 = {BIR.DescriptorPlus{v_5, [BIR.DescriptorNull{}]} : BIR.Descriptor}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000715 => template_body_ref("U32", []), v_1000714 => +v_1000706 = template_unbox(BIR.Descriptor, v_1000714); template_continuation_174(v_3, v_1000686, v_1000687, v_1000688, v_1000689, v_1000690, v_1000691, v_1000692, v_1000693, v_1000694, v_1000695, v_1000696, v_1000697, v_1000698, v_1000699, v_1000700, v_1000701, v_1000702, v_1000703, v_1000704, {"Alias1" : String}, v_1000706)}

def template_continuation_176(+v_3: BIR.Descriptor, +v_5: BIR.Descriptor, +v_1000686: BIR.Descriptor, +v_1000687: BIR.Descriptor, v_1000688: BIR.Descriptor, v_1000689: List<&2, BIR.Descriptor>, v_1000690: List<&2, BIR.DescriptorPattern>, +v_1000691: BIR.Descriptor, v_1000692: BIR.Descriptor, v_1000693: Nat, v_1000694: BIR.Descriptor, +v_1000695: BIR.Descriptor, v_1000696: List<&2, BIR.Descriptor>, +v_1000697: BIR.Descriptor, v_1000698: List<&2, BIR.DescriptorPattern>, v_1000699: List<&2, BIR.Descriptor>, +v_1000700: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000717 => template_body_par(0n), v_1000716 => +v_1000702 = template_unbox(BIR.Descriptor, v_1000716); template_continuation_175(v_5, v_3, v_1000686, v_1000687, v_1000688, v_1000689, v_1000690, v_1000691, v_1000692, v_1000693, v_1000694, v_1000695, v_1000696, v_1000697, v_1000698, v_1000699, v_1000700, {v_3 : BIR.Descriptor}, v_1000702)}

def template_continuation_177(+v_7: BIR.DescriptorPattern, +v_3: BIR.Descriptor, +v_5: BIR.Descriptor, +v_1000686: BIR.Descriptor, +v_1000687: BIR.Descriptor, v_1000688: BIR.Descriptor, v_1000689: List<&2, BIR.Descriptor>, v_1000690: List<&2, BIR.DescriptorPattern>, +v_1000691: BIR.Descriptor, v_1000692: BIR.Descriptor, v_1000693: Nat, v_1000694: BIR.Descriptor, +v_1000695: BIR.Descriptor, v_1000696: List<&2, BIR.Descriptor>, +v_1000697: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  v_1000698 = {[v_7] : List<&2, BIR.DescriptorPattern>}
  v_1000699 = {[v_3] : List<&2, BIR.Descriptor>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000719 => template_body_par(0n), v_1000718 => +v_1000700 = template_unbox(BIR.Descriptor, v_1000718); template_continuation_176(v_3, v_5, v_1000686, v_1000687, v_1000688, v_1000689, v_1000690, v_1000691, v_1000692, v_1000693, v_1000694, v_1000695, v_1000696, v_1000697, v_1000698, v_1000699, v_1000700)}

def template_continuation_178(+v_3: BIR.Descriptor, +v_7: BIR.DescriptorPattern, +v_5: BIR.Descriptor, +v_1000686: BIR.Descriptor, +v_1000687: BIR.Descriptor, v_1000688: BIR.Descriptor, v_1000689: List<&2, BIR.Descriptor>, v_1000690: List<&2, BIR.DescriptorPattern>, +v_1000691: BIR.Descriptor, v_1000692: BIR.Descriptor, v_1000693: Nat, v_1000694: BIR.Descriptor, +v_1000695: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  v_1000696 = {[v_3] : List<&2, BIR.Descriptor>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000721 => template_body_par(0n), v_1000720 => +v_1000697 = template_unbox(BIR.Descriptor, v_1000720); template_continuation_177(v_7, v_3, v_5, v_1000686, v_1000687, v_1000688, v_1000689, v_1000690, v_1000691, v_1000692, v_1000693, v_1000694, v_1000695, v_1000696, v_1000697)}

def template_continuation_179(+v_7: BIR.DescriptorPattern, +v_3: BIR.Descriptor, +v_5: BIR.Descriptor, +v_1000686: BIR.Descriptor, +v_1000687: BIR.Descriptor, v_1000688: BIR.Descriptor, v_1000689: List<&2, BIR.Descriptor>, v_1000690: List<&2, BIR.DescriptorPattern>, +v_1000691: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  v_1000692 = {BIR.DescriptorMatch{[BIR.DescriptorNull{}], [BIR.DescriptorCase{[v_7], v_3}]} : BIR.Descriptor}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000723 => template_body_par(0n), v_1000722 => +v_1000695 = template_unbox(BIR.Descriptor, v_1000722); template_continuation_178(v_3, v_7, v_5, v_1000686, v_1000687, v_1000688, v_1000689, v_1000690, v_1000691, v_1000692, {0n : Nat}, {v_3 : BIR.Descriptor}, v_1000695)}

def template_continuation_180(+v_5: BIR.Descriptor, +v_3: BIR.Descriptor, +v_7: BIR.DescriptorPattern, +v_1000686: BIR.Descriptor, +v_1000687: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  v_1000688 = {BIR.DescriptorApplication{v_5, BIR.DescriptorNull{}} : BIR.Descriptor}
  v_1000689 = {[BIR.DescriptorConstructor{"Held", [v_3]}] : List<&2, BIR.Descriptor>}
  v_1000690 = {[BIR.DescriptorConstructorPattern{"Held", [v_7]}] : List<&2, BIR.DescriptorPattern>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000725 => template_body_par(0n), v_1000724 => +v_1000691 = template_unbox(BIR.Descriptor, v_1000724); template_continuation_179(v_7, v_3, v_5, v_1000686, v_1000687, v_1000688, v_1000689, v_1000690, v_1000691)}

def template_continuation_181(+v_1000685: BIR.Descriptor) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  +v_5 = {BIR.DescriptorLambda{None{}, v_1000685} : BIR.Descriptor}
  +v_7 = {BIR.DescriptorBinder{BIR.Unrestricted{}} : BIR.DescriptorPattern}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Alias1", []}}, False{}, v_1000729 => template_body_ref("Alias1", []), v_1000728 => +v_1000686 = template_unbox(BIR.Descriptor, v_1000728); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Identity", []}}, False{}, v_1000727 => template_body_ref("Identity", []), v_1000726 => +v_1000687 = template_unbox(BIR.Descriptor, v_1000726); template_continuation_180(v_5, v_1000685, v_7, v_1000686, v_1000687)}}

def template_body_recursive_descriptors() -> TemplateProgress<List<&2, BIR.Descriptor>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000731 => template_body_ref("ListT", []), v_1000730 => +v_1000685 = template_unbox(BIR.Descriptor, v_1000730); template_continuation_181(v_1000685)}

def template_continuation_182(+v_1000733: cps_provider_1_LayoutResult, v_8: List<&2, BIR.Descriptor>, +v_3: List<&2, BIR.TypeFunction>) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_recursive{v_1000733}}, False{}, v_1000741 => template_body_check_recursive(v_1000733), v_1000740 => +v_1000734 = template_unbox(Bool, v_1000740); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1000734}}, False{}, v_1000739 => template_body_fail(v_1000734), v_1000738 => +v_1000735 = template_unbox(U32, v_1000738); TemplatePending{TemplateRequestGroup_1{TemplateRequest_recursive_descriptor_failures{v_8, v_3}}, v_1000737 => +v_1000736 = template_unbox(U32, v_1000737); TemplateFinished{TemplateValue{U32.add(v_1000735, v_1000736)}}}}}

def template_body_recursive_descriptor_failures(+v_1: List<&2, BIR.Descriptor>, +v_3: List<&2, BIR.TypeFunction>) -> TemplateProgress<U32>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{0}}
    case +v_7 <> v_8:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_7}}, False{}, v_1000745 => template_body_fld(v_7), v_1000744 => +v_1000732 = template_unbox(BIR.DescriptorField, v_1000744); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1000732], [], v_3}}, False{}, v_1000743 => template_body_recursion_layout([v_1000732], [], v_3), v_1000742 => +v_1000733 = template_unbox(cps_provider_1_LayoutResult, v_1000742); template_continuation_182(v_1000733, v_8, v_3)}}

def template_match_184(+v_4: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_4:
    case cps_provider_1_LayoutData{+v_7, +v_8}:
      TemplateFinished{TemplateValue{template_pure_both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_7), 1n), template_pure_first_word_box(v_7))}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_single_box_field(+v_1: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFound{+v_4}:
      template_match_184(v_4)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_186(+v_8: cps_provider_1_BoxReason, +v_3: String) -> TemplateProgress<Bool>:
  match v_8:
    case cps_provider_1_BoxRecursive{+v_10}:
      TemplateFinished{TemplateValue{String.eq(v_10, v_3)}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_match_187(+v_6: cps_provider_1_Layout, +v_3: String) -> TemplateProgress<Bool>:
  match v_6:
    case cps_provider_1_LayoutBox{+v_8}:
      template_match_186(v_8, v_3)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_check_recursive_key(+v_1: cps_provider_1_LayoutResult, +v_3: String) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutFound{+v_6}:
      template_match_187(v_6, v_3)
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_continuation_189(+v_1000771: cps_provider_1_LayoutResult, +v_17: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_17, "Box"}}, False{}, v_1000777 => template_body_check_recursive_key(v_17, "Box"), v_1000776 => +v_1000772 = template_unbox(Bool, v_1000776); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_1000771, "Apply"}}, False{}, v_1000775 => template_body_check_recursive_key(v_1000771, "Apply"), v_1000774 => +v_1000773 = template_unbox(Bool, v_1000774); TemplateFinished{TemplateValue{template_pure_both(v_1000772, v_1000773)}}}}

def template_continuation_190(v_1000767: Maybe<&2, BIR.Quantity>, +v_1000768: BIR.Descriptor, +v_11: cps_provider_1_Context, +v_17: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  +v_20 = {BIR.DescriptorLambda{v_1000767, v_1000768} : BIR.Descriptor}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Apply", [v_20]}}, False{}, v_1000780 => template_body_ref("Apply", [v_20]), v_1000779 => +v_1000770 = template_unbox(BIR.Descriptor, v_1000779); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_11 : cps_provider_1_Context}, v_1000770}}, v_1000778 => +v_1000771 = template_unbox(cps_provider_1_LayoutResult, v_1000778); template_continuation_189(v_1000771, v_17)}}

def template_continuation_191(+v_1000766: cps_provider_1_LayoutResult, +v_11: cps_provider_1_Context) -> TemplateProgress<Bool>:
  v_1000767 = {None{} : Maybe<&2, BIR.Quantity>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Apply", [BIR.DescriptorNull{}]}}, False{}, v_1000782 => template_body_ref("Apply", [BIR.DescriptorNull{}]), v_1000781 => +v_1000768 = template_unbox(BIR.Descriptor, v_1000781); template_continuation_190(v_1000767, v_1000768, v_11, v_1000766)}

def template_continuation_192(+v_1000759: cps_provider_1_Context) -> TemplateProgress<Bool>:
  +v_1000761 = {"Box" : String}
  +v_1000762 = {"Box" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000789 => template_body_ref("U32", []), v_1000788 => +v_1000763 = template_unbox(BIR.Descriptor, v_1000788); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000762, [v_1000763]}}, False{}, v_1000787 => template_body_ref(v_1000762, [v_1000763]), v_1000786 => +v_1000764 = template_unbox(BIR.Descriptor, v_1000786); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000761, [v_1000764]}}, False{}, v_1000785 => template_body_ref(v_1000761, [v_1000764]), v_1000784 => +v_1000765 = template_unbox(BIR.Descriptor, v_1000784); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_1000759 : cps_provider_1_Context}, v_1000765}}, v_1000783 => +v_1000766 = template_unbox(cps_provider_1_LayoutResult, v_1000783); template_continuation_191(v_1000766, v_1000759)}}}}

def template_continuation_193(+v_1000753: BIR.Family) -> TemplateProgress<Bool>:
  v_1000754 = {[] : List<&2, BIR.Code>}
  v_1000755 = {[] : List<&2, BIR.Declaration>}
  v_1000756 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_box{}}, False{}, v_1000794 => template_body_fam_box, v_1000793 => +v_1000757 = template_unbox(BIR.Family, v_1000793); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000792 => template_body_fam_u32, v_1000791 => +v_1000758 = template_unbox(BIR.Family, v_1000791); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1000754, v_1000755, v_1000756, [v_1000757, v_1000758, v_1000753], [], BIR.Library{[]}}}}, v_1000790 => +v_1000759 = template_unbox(cps_provider_1_Context, v_1000790); template_continuation_192(v_1000759)}}}

def template_body_generic_recursion_check() -> TemplateProgress<Bool>:
  +v_1000746 = {"Apply" : String}
  +v_1000747 = {None{} : Maybe<&2, String>}
  +v_1000748 = {1n : Nat}
  +v_1000749 = {"Apply" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1000802 => template_body_par(0n), v_1000801 => +v_1000750 = template_unbox(BIR.Descriptor, v_1000801); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{BIR.DescriptorApplication{v_1000750, BIR.DescriptorNull{}}}}, False{}, v_1000800 => template_body_fld(BIR.DescriptorApplication{v_1000750, BIR.DescriptorNull{}}), v_1000799 => +v_1000751 = template_unbox(BIR.DescriptorField, v_1000799); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000749, [v_1000751]}}, False{}, v_1000798 => template_body_arm(v_1000749, [v_1000751]), v_1000797 => +v_1000752 = template_unbox(BIR.DescriptorArm, v_1000797); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000746, v_1000747, v_1000748, [v_1000752]}}, False{}, v_1000796 => template_body_fam(v_1000746, v_1000747, v_1000748, [v_1000752]), v_1000795 => +v_1000753 = template_unbox(BIR.Family, v_1000795); template_continuation_193(v_1000753)}}}}

def template_continuation_194(+v_1000854: cps_provider_1_LayoutResult, +v_30: cps_provider_1_LayoutResult, +v_34: cps_provider_1_LayoutResult, +v_39: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_recursive{v_30}}, False{}, v_1000866 => template_body_check_recursive(v_30), v_1000865 => +v_1000855 = template_unbox(Bool, v_1000865); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_34}}, False{}, v_1000864 => template_body_classify(v_34), v_1000863 => +v_1000856 = template_unbox(Nat, v_1000863); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_recursive{v_39}}, False{}, v_1000862 => template_body_check_recursive(v_39), v_1000861 => +v_1000857 = template_unbox(Bool, v_1000861); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_1000854}}, False{}, v_1000860 => template_body_classify(v_1000854), v_1000859 => +v_1000858 = template_unbox(Nat, v_1000859); TemplateFinished{TemplateValue{template_pure_both(v_1000855, template_pure_both(Nat.is_eq(v_1000856, 0n), template_pure_both(v_1000857, Nat.is_eq(v_1000858, 0n))))}}}}}}

def template_continuation_195(+v_1000851: cps_provider_1_LayoutResult, +v_26: BIR.TypeFunction, +v_23: BIR.TypeFunction, +v_30: cps_provider_1_LayoutResult, +v_34: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Alias", []}}, False{}, v_1000872 => template_body_ref("Alias", []), v_1000871 => +v_1000852 = template_unbox(BIR.Descriptor, v_1000871); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000852}}, False{}, v_1000870 => template_body_fld(v_1000852), v_1000869 => +v_1000853 = template_unbox(BIR.DescriptorField, v_1000869); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1000853], [], [v_26, v_23]}}, False{}, v_1000868 => template_body_recursion_layout([v_1000853], [], [v_26, v_23]), v_1000867 => +v_1000854 = template_unbox(cps_provider_1_LayoutResult, v_1000867); template_continuation_194(v_1000854, v_30, v_34, v_1000851)}}}

def template_continuation_196(+v_1000848: cps_provider_1_LayoutResult, +v_23: BIR.TypeFunction, +v_26: BIR.TypeFunction, +v_30: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Alias", []}}, False{}, v_1000878 => template_body_ref("Alias", []), v_1000877 => +v_1000849 = template_unbox(BIR.Descriptor, v_1000877); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000849}}, False{}, v_1000876 => template_body_fld(v_1000849), v_1000875 => +v_1000850 = template_unbox(BIR.DescriptorField, v_1000875); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1000850], [], [v_23, v_26]}}, False{}, v_1000874 => template_body_recursion_layout([v_1000850], [], [v_23, v_26]), v_1000873 => +v_1000851 = template_unbox(cps_provider_1_LayoutResult, v_1000873); template_continuation_195(v_1000851, v_26, v_23, v_30, v_1000848)}}}

def template_continuation_197(+v_1000845: cps_provider_1_LayoutResult, +v_20: cps_provider_1_Context, +v_23: BIR.TypeFunction, +v_26: BIR.TypeFunction) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000881 => template_body_ref("ListT", []), v_1000880 => +v_1000847 = template_unbox(BIR.Descriptor, v_1000880); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_20 : cps_provider_1_Context}, v_1000847}}, v_1000879 => +v_1000848 = template_unbox(cps_provider_1_LayoutResult, v_1000879); template_continuation_196(v_1000848, v_23, v_26, v_1000845)}}

def template_continuation_198(v_1000838: String, v_1000839: Maybe<&2, String>, v_1000840: Nat, v_1000841: Nat, +v_1000842: BIR.Descriptor, +v_16: cps_provider_1_Context, +v_20: cps_provider_1_Context, +v_23: BIR.TypeFunction) -> TemplateProgress<Bool>:
  +v_26 = {BIR.TypeFunction{v_1000838, v_1000839, v_1000840, v_1000841, v_1000842} : BIR.TypeFunction}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000884 => template_body_ref("ListT", []), v_1000883 => +v_1000844 = template_unbox(BIR.Descriptor, v_1000883); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_16 : cps_provider_1_Context}, v_1000844}}, v_1000882 => +v_1000845 = template_unbox(cps_provider_1_LayoutResult, v_1000882); template_continuation_197(v_1000845, v_20, v_23, v_26)}}

def template_continuation_199(v_1000833: String, v_1000834: Maybe<&2, String>, v_1000835: Nat, v_1000836: Nat, +v_1000837: BIR.Descriptor, +v_16: cps_provider_1_Context, +v_20: cps_provider_1_Context) -> TemplateProgress<Bool>:
  +v_23 = {BIR.TypeFunction{v_1000833, v_1000834, v_1000835, v_1000836, v_1000837} : BIR.TypeFunction}
  v_1000839 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000886 => template_body_ref("U32", []), v_1000885 => +v_1000842 = template_unbox(BIR.Descriptor, v_1000885); template_continuation_198({"Alias" : String}, v_1000839, {0n : Nat}, {0n : Nat}, v_1000842, v_16, v_20, v_23)}

def template_continuation_200(+v_1000832: cps_provider_1_Context, +v_16: cps_provider_1_Context) -> TemplateProgress<Bool>:
  v_1000834 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000888 => template_body_ref("ListT", []), v_1000887 => +v_1000837 = template_unbox(BIR.Descriptor, v_1000887); template_continuation_199({"Alias" : String}, v_1000834, {0n : Nat}, {0n : Nat}, v_1000837, v_16, v_1000832)}

def template_continuation_201(+v_1000825: cps_provider_1_Context, +v_12: BIR.Family, +v_6: BIR.Family) -> TemplateProgress<Bool>:
  v_1000826 = {[] : List<&2, BIR.Code>}
  v_1000827 = {[] : List<&2, BIR.Declaration>}
  v_1000828 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000891 => template_body_fam_u32, v_1000890 => +v_1000831 = template_unbox(BIR.Family, v_1000890); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1000826, v_1000827, v_1000828, [{v_12 : BIR.Family}, {v_6 : BIR.Family}, v_1000831], [], BIR.Library{[]}}}}, v_1000889 => +v_1000832 = template_unbox(cps_provider_1_Context, v_1000889); template_continuation_200(v_1000832, v_1000825)}}

def template_continuation_202(+v_1000818: BIR.Family, +v_6: BIR.Family) -> TemplateProgress<Bool>:
  v_1000819 = {[] : List<&2, BIR.Code>}
  v_1000820 = {[] : List<&2, BIR.Declaration>}
  v_1000821 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000894 => template_body_fam_u32, v_1000893 => +v_1000824 = template_unbox(BIR.Family, v_1000893); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1000819, v_1000820, v_1000821, [{v_6 : BIR.Family}, {v_1000818 : BIR.Family}, v_1000824], [], BIR.Library{[]}}}}, v_1000892 => +v_1000825 = template_unbox(cps_provider_1_Context, v_1000892); template_continuation_201(v_1000825, v_1000818, v_6)}}

def template_continuation_203(+v_1000810: BIR.Family) -> TemplateProgress<Bool>:
  +v_1000811 = {"ListT" : String}
  +v_1000812 = {None{} : Maybe<&2, String>}
  +v_1000813 = {0n : Nat}
  +v_1000814 = {"Root" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000902 => template_body_ref("U32", []), v_1000901 => +v_1000815 = template_unbox(BIR.Descriptor, v_1000901); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000815}}, False{}, v_1000900 => template_body_fld(v_1000815), v_1000899 => +v_1000816 = template_unbox(BIR.DescriptorField, v_1000899); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000814, [v_1000816]}}, False{}, v_1000898 => template_body_arm(v_1000814, [v_1000816]), v_1000897 => +v_1000817 = template_unbox(BIR.DescriptorArm, v_1000897); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000811, v_1000812, v_1000813, [v_1000817]}}, False{}, v_1000896 => template_body_fam(v_1000811, v_1000812, v_1000813, [v_1000817]), v_1000895 => +v_1000818 = template_unbox(BIR.Family, v_1000895); template_continuation_202(v_1000818, v_1000810)}}}}

def template_body_duplicate_recursion_check() -> TemplateProgress<Bool>:
  +v_1000803 = {"ListT" : String}
  +v_1000804 = {None{} : Maybe<&2, String>}
  +v_1000805 = {0n : Nat}
  +v_1000806 = {"Root" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1000910 => template_body_ref("ListT", []), v_1000909 => +v_1000807 = template_unbox(BIR.Descriptor, v_1000909); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000807}}, False{}, v_1000908 => template_body_fld(v_1000807), v_1000907 => +v_1000808 = template_unbox(BIR.DescriptorField, v_1000907); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000806, [v_1000808]}}, False{}, v_1000906 => template_body_arm(v_1000806, [v_1000808]), v_1000905 => +v_1000809 = template_unbox(BIR.DescriptorArm, v_1000905); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000803, v_1000804, v_1000805, [v_1000809]}}, False{}, v_1000904 => template_body_fam(v_1000803, v_1000804, v_1000805, [v_1000809]), v_1000903 => +v_1000810 = template_unbox(BIR.Family, v_1000903); template_continuation_203(v_1000810)}}}}

def template_continuation_204(+v_1001016: U32, +v_1001018: U32, +v_1001020: U32, +v_1001022: U32, +v_84: U32, +v_65: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_94 = U32.add(v_1001016, U32.add(v_1001018, U32.add(v_1001020, v_1001022)))
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_failure{v_65}}, False{}, v_1001030 => template_body_check_failure(v_65), v_1001029 => +v_1001025 = template_unbox(Bool, v_1001029); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001025}}, False{}, v_1001028 => template_body_fail(v_1001025), v_1001027 => +v_1001026 = template_unbox(U32, v_1001027); TemplateFinished{TemplateValue{U32.add({v_84 : U32}, U32.add({v_94 : U32}, v_1001026))}}}}

def template_continuation_205(+v_1001012: U32, +v_1001014: U32, +v_50: cps_provider_1_LayoutResult, +v_55: cps_provider_1_LayoutResult, +v_60: cps_provider_1_LayoutResult, +v_71: cps_provider_1_LayoutResult, +v_65: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_84 = U32.add(v_1001012, v_1001014)
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_50}}, False{}, v_1001046 => template_body_classify(v_50), v_1001045 => +v_1001015 = template_unbox(Nat, v_1001045); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{Nat.is_eq(v_1001015, 0n)}}, False{}, v_1001044 => template_body_fail(Nat.is_eq(v_1001015, 0n)), v_1001043 => +v_1001016 = template_unbox(U32, v_1001043); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_single_box_field{v_55}}, False{}, v_1001042 => template_body_check_single_box_field(v_55), v_1001041 => +v_1001017 = template_unbox(Bool, v_1001041); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001017}}, False{}, v_1001040 => template_body_fail(v_1001017), v_1001039 => +v_1001018 = template_unbox(U32, v_1001039); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_60}}, False{}, v_1001038 => template_body_classify(v_60), v_1001037 => +v_1001019 = template_unbox(Nat, v_1001037); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{Nat.is_eq(v_1001019, 0n)}}, False{}, v_1001036 => template_body_fail(Nat.is_eq(v_1001019, 0n)), v_1001035 => +v_1001020 = template_unbox(U32, v_1001035); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_single_box_field{v_71}}, False{}, v_1001034 => template_body_check_single_box_field(v_71), v_1001033 => +v_1001021 = template_unbox(Bool, v_1001033); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001021}}, False{}, v_1001032 => template_body_fail(v_1001021), v_1001031 => +v_1001022 = template_unbox(U32, v_1001031); template_continuation_204(v_1001016, v_1001018, v_1001020, v_1001022, v_84, v_65)}}}}}}}}

def template_continuation_206(+v_1001010: cps_provider_1_LayoutResult, +v_46: cps_provider_1_LayoutResult, +v_50: cps_provider_1_LayoutResult, +v_55: cps_provider_1_LayoutResult, +v_60: cps_provider_1_LayoutResult, +v_71: cps_provider_1_LayoutResult, +v_65: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_46, "Wrap"}}, False{}, v_1001054 => template_body_check_recursive_key(v_46, "Wrap"), v_1001053 => +v_1001011 = template_unbox(Bool, v_1001053); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001011}}, False{}, v_1001052 => template_body_fail(v_1001011), v_1001051 => +v_1001012 = template_unbox(U32, v_1001051); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_1001010, "Wrap"}}, False{}, v_1001050 => template_body_check_recursive_key(v_1001010, "Wrap"), v_1001049 => +v_1001013 = template_unbox(Bool, v_1001049); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001013}}, False{}, v_1001048 => template_body_fail(v_1001013), v_1001047 => +v_1001014 = template_unbox(U32, v_1001047); template_continuation_205(v_1001012, v_1001014, v_50, v_55, v_60, v_71, v_65)}}}}

def template_continuation_207(+v_1001001: cps_provider_1_LayoutResult, +v_41: cps_provider_1_Context, +v_46: cps_provider_1_LayoutResult, +v_50: cps_provider_1_LayoutResult, +v_55: cps_provider_1_LayoutResult, +v_60: cps_provider_1_LayoutResult, +v_65: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_1001003 = {"Wrap" : String}
  +v_1001004 = {"Array" : String}
  +v_1001005 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001063 => template_body_ref("U32", []), v_1001062 => +v_1001006 = template_unbox(BIR.Descriptor, v_1001062); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001005, [v_1001006]}}, False{}, v_1001061 => template_body_ref(v_1001005, [v_1001006]), v_1001060 => +v_1001007 = template_unbox(BIR.Descriptor, v_1001060); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001004, [v_1001007]}}, False{}, v_1001059 => template_body_ref(v_1001004, [v_1001007]), v_1001058 => +v_1001008 = template_unbox(BIR.Descriptor, v_1001058); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001003, [v_1001008]}}, False{}, v_1001057 => template_body_ref(v_1001003, [v_1001008]), v_1001056 => +v_1001009 = template_unbox(BIR.Descriptor, v_1001056); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_41 : cps_provider_1_Context}, v_1001009}}, v_1001055 => +v_1001010 = template_unbox(cps_provider_1_LayoutResult, v_1001055); template_continuation_206(v_1001010, v_46, v_50, v_55, v_60, v_1001001, v_65)}}}}}

def template_continuation_208(+v_1000994: cps_provider_1_LayoutResult, +v_41: cps_provider_1_Context, +v_46: cps_provider_1_LayoutResult, +v_50: cps_provider_1_LayoutResult, +v_55: cps_provider_1_LayoutResult, +v_60: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_1000996 = {"Wrap" : String}
  +v_1000997 = {"Array" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Leaf", []}}, False{}, v_1001070 => template_body_ref("Leaf", []), v_1001069 => +v_1000998 = template_unbox(BIR.Descriptor, v_1001069); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000997, [v_1000998]}}, False{}, v_1001068 => template_body_ref(v_1000997, [v_1000998]), v_1001067 => +v_1000999 = template_unbox(BIR.Descriptor, v_1001067); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000996, [v_1000999]}}, False{}, v_1001066 => template_body_ref(v_1000996, [v_1000999]), v_1001065 => +v_1001000 = template_unbox(BIR.Descriptor, v_1001065); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_41 : cps_provider_1_Context}, v_1001000}}, v_1001064 => +v_1001001 = template_unbox(cps_provider_1_LayoutResult, v_1001064); template_continuation_207(v_1001001, v_41, v_46, v_50, v_55, v_60, v_1000994)}}}}

def template_continuation_209(+v_1000989: cps_provider_1_LayoutResult, +v_41: cps_provider_1_Context, +v_46: cps_provider_1_LayoutResult, +v_50: cps_provider_1_LayoutResult, +v_55: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_1000991 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Broken", []}}, False{}, v_1001075 => template_body_ref("Broken", []), v_1001074 => +v_1000992 = template_unbox(BIR.Descriptor, v_1001074); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000991, [v_1000992]}}, False{}, v_1001073 => template_body_ref(v_1000991, [v_1000992]), v_1001072 => +v_1000993 = template_unbox(BIR.Descriptor, v_1001072); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_41 : cps_provider_1_Context}, v_1000993}}, v_1001071 => +v_1000994 = template_unbox(cps_provider_1_LayoutResult, v_1001071); template_continuation_208(v_1000994, v_41, v_46, v_50, v_55, v_1000989)}}}

def template_continuation_210(+v_1000984: cps_provider_1_LayoutResult, +v_41: cps_provider_1_Context, +v_46: cps_provider_1_LayoutResult, +v_50: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_1000986 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Leaf", []}}, False{}, v_1001080 => template_body_ref("Leaf", []), v_1001079 => +v_1000987 = template_unbox(BIR.Descriptor, v_1001079); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000986, [v_1000987]}}, False{}, v_1001078 => template_body_ref(v_1000986, [v_1000987]), v_1001077 => +v_1000988 = template_unbox(BIR.Descriptor, v_1001077); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_41 : cps_provider_1_Context}, v_1000988}}, v_1001076 => +v_1000989 = template_unbox(cps_provider_1_LayoutResult, v_1001076); template_continuation_209(v_1000989, v_41, v_46, v_50, v_1000984)}}}

def template_continuation_211(+v_1000979: cps_provider_1_LayoutResult, +v_41: cps_provider_1_Context, +v_46: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_1000981 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"CycleLeft", []}}, False{}, v_1001085 => template_body_ref("CycleLeft", []), v_1001084 => +v_1000982 = template_unbox(BIR.Descriptor, v_1001084); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000981, [v_1000982]}}, False{}, v_1001083 => template_body_ref(v_1000981, [v_1000982]), v_1001082 => +v_1000983 = template_unbox(BIR.Descriptor, v_1001082); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_41 : cps_provider_1_Context}, v_1000983}}, v_1001081 => +v_1000984 = template_unbox(cps_provider_1_LayoutResult, v_1001081); template_continuation_210(v_1000984, v_41, v_46, v_1000979)}}}

def template_continuation_212(+v_1000976: cps_provider_1_LayoutResult, +v_41: cps_provider_1_Context) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Bridge", []}}, False{}, v_1001088 => template_body_ref("Bridge", []), v_1001087 => +v_1000978 = template_unbox(BIR.Descriptor, v_1001087); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_41 : cps_provider_1_Context}, v_1000978}}, v_1001086 => +v_1000979 = template_unbox(cps_provider_1_LayoutResult, v_1001086); template_continuation_211(v_1000979, v_41, v_1000976)}}

def template_continuation_213(+v_1000971: cps_provider_1_Context) -> TemplateProgress<U32>:
  +v_1000973 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Bridge", []}}, False{}, v_1001093 => template_body_ref("Bridge", []), v_1001092 => +v_1000974 = template_unbox(BIR.Descriptor, v_1001092); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000973, [v_1000974]}}, False{}, v_1001091 => template_body_ref(v_1000973, [v_1000974]), v_1001090 => +v_1000975 = template_unbox(BIR.Descriptor, v_1001090); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_1000971 : cps_provider_1_Context}, v_1000975}}, v_1001089 => +v_1000976 = template_unbox(cps_provider_1_LayoutResult, v_1001089); template_continuation_212(v_1000976, v_1000971)}}}

def template_continuation_214(+v_1000959: BIR.Family, +v_6: BIR.Family, +v_13: BIR.Family, +v_19: BIR.Family, +v_25: BIR.Family, +v_31: BIR.Family) -> TemplateProgress<U32>:
  v_1000960 = {[] : List<&2, BIR.Code>}
  v_1000961 = {[] : List<&2, BIR.Declaration>}
  v_1000962 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1001098 => template_body_fam_u32, v_1001097 => +v_1000969 = template_unbox(BIR.Family, v_1001097); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_array{}}, False{}, v_1001096 => template_body_fam_array, v_1001095 => +v_1000970 = template_unbox(BIR.Family, v_1001095); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1000960, v_1000961, v_1000962, [{v_6 : BIR.Family}, {v_13 : BIR.Family}, {v_19 : BIR.Family}, {v_25 : BIR.Family}, {v_31 : BIR.Family}, {v_1000959 : BIR.Family}, v_1000969, v_1000970], [], BIR.Library{[]}}}}, v_1001094 => +v_1000971 = template_unbox(cps_provider_1_Context, v_1001094); template_continuation_213(v_1000971)}}}

def template_continuation_215(+v_1000952: BIR.Family, +v_6: BIR.Family, +v_13: BIR.Family, +v_19: BIR.Family, +v_25: BIR.Family) -> TemplateProgress<U32>:
  +v_1000953 = {"Broken" : String}
  +v_1000954 = {None{} : Maybe<&2, String>}
  +v_1000955 = {0n : Nat}
  +v_1000956 = {"Broken" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{BIR.DescriptorFailure{"the checked type expression is a reducer failure"}}}, False{}, v_1001104 => template_body_fld(BIR.DescriptorFailure{"the checked type expression is a reducer failure"}), v_1001103 => +v_1000957 = template_unbox(BIR.DescriptorField, v_1001103); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000956, [v_1000957]}}, False{}, v_1001102 => template_body_arm(v_1000956, [v_1000957]), v_1001101 => +v_1000958 = template_unbox(BIR.DescriptorArm, v_1001101); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000953, v_1000954, v_1000955, [v_1000958]}}, False{}, v_1001100 => template_body_fam(v_1000953, v_1000954, v_1000955, [v_1000958]), v_1001099 => +v_1000959 = template_unbox(BIR.Family, v_1001099); template_continuation_214(v_1000959, v_6, v_13, v_19, v_25, v_1000952)}}}

def template_continuation_216(+v_1000944: BIR.Family, +v_6: BIR.Family, +v_13: BIR.Family, +v_19: BIR.Family) -> TemplateProgress<U32>:
  +v_1000945 = {"Leaf" : String}
  +v_1000946 = {None{} : Maybe<&2, String>}
  +v_1000947 = {0n : Nat}
  +v_1000948 = {"Leaf" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001112 => template_body_ref("U32", []), v_1001111 => +v_1000949 = template_unbox(BIR.Descriptor, v_1001111); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000949}}, False{}, v_1001110 => template_body_fld(v_1000949), v_1001109 => +v_1000950 = template_unbox(BIR.DescriptorField, v_1001109); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000948, [v_1000950]}}, False{}, v_1001108 => template_body_arm(v_1000948, [v_1000950]), v_1001107 => +v_1000951 = template_unbox(BIR.DescriptorArm, v_1001107); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000945, v_1000946, v_1000947, [v_1000951]}}, False{}, v_1001106 => template_body_fam(v_1000945, v_1000946, v_1000947, [v_1000951]), v_1001105 => +v_1000952 = template_unbox(BIR.Family, v_1001105); template_continuation_215(v_1000952, v_6, v_13, v_19, v_1000944)}}}}

def template_continuation_217(+v_1000936: BIR.Family, +v_6: BIR.Family, +v_13: BIR.Family) -> TemplateProgress<U32>:
  +v_1000937 = {"CycleRight" : String}
  +v_1000938 = {None{} : Maybe<&2, String>}
  +v_1000939 = {0n : Nat}
  +v_1000940 = {"CycleRight" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"CycleLeft", []}}, False{}, v_1001120 => template_body_ref("CycleLeft", []), v_1001119 => +v_1000941 = template_unbox(BIR.Descriptor, v_1001119); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000941}}, False{}, v_1001118 => template_body_fld(v_1000941), v_1001117 => +v_1000942 = template_unbox(BIR.DescriptorField, v_1001117); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000940, [v_1000942]}}, False{}, v_1001116 => template_body_arm(v_1000940, [v_1000942]), v_1001115 => +v_1000943 = template_unbox(BIR.DescriptorArm, v_1001115); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000937, v_1000938, v_1000939, [v_1000943]}}, False{}, v_1001114 => template_body_fam(v_1000937, v_1000938, v_1000939, [v_1000943]), v_1001113 => +v_1000944 = template_unbox(BIR.Family, v_1001113); template_continuation_216(v_1000944, v_6, v_13, v_1000936)}}}}

def template_continuation_218(+v_1000928: BIR.Family, +v_6: BIR.Family) -> TemplateProgress<U32>:
  +v_1000929 = {"CycleLeft" : String}
  +v_1000930 = {None{} : Maybe<&2, String>}
  +v_1000931 = {0n : Nat}
  +v_1000932 = {"CycleLeft" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"CycleRight", []}}, False{}, v_1001128 => template_body_ref("CycleRight", []), v_1001127 => +v_1000933 = template_unbox(BIR.Descriptor, v_1001127); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000933}}, False{}, v_1001126 => template_body_fld(v_1000933), v_1001125 => +v_1000934 = template_unbox(BIR.DescriptorField, v_1001125); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000932, [v_1000934]}}, False{}, v_1001124 => template_body_arm(v_1000932, [v_1000934]), v_1001123 => +v_1000935 = template_unbox(BIR.DescriptorArm, v_1001123); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000929, v_1000930, v_1000931, [v_1000935]}}, False{}, v_1001122 => template_body_fam(v_1000929, v_1000930, v_1000931, [v_1000935]), v_1001121 => +v_1000936 = template_unbox(BIR.Family, v_1001121); template_continuation_217(v_1000936, v_6, v_1000928)}}}}

def template_continuation_219(+v_1000918: BIR.Family) -> TemplateProgress<U32>:
  +v_1000919 = {"Bridge" : String}
  +v_1000920 = {None{} : Maybe<&2, String>}
  +v_1000921 = {0n : Nat}
  +v_1000922 = {"Bridge" : String}
  +v_1000923 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001138 => template_body_ref("U32", []), v_1001137 => +v_1000924 = template_unbox(BIR.Descriptor, v_1001137); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000923, [v_1000924]}}, False{}, v_1001136 => template_body_ref(v_1000923, [v_1000924]), v_1001135 => +v_1000925 = template_unbox(BIR.Descriptor, v_1001135); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000925}}, False{}, v_1001134 => template_body_fld(v_1000925), v_1001133 => +v_1000926 = template_unbox(BIR.DescriptorField, v_1001133); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000922, [v_1000926]}}, False{}, v_1001132 => template_body_arm(v_1000922, [v_1000926]), v_1001131 => +v_1000927 = template_unbox(BIR.DescriptorArm, v_1001131); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000919, v_1000920, v_1000921, [v_1000927]}}, False{}, v_1001130 => template_body_fam(v_1000919, v_1000920, v_1000921, [v_1000927]), v_1001129 => +v_1000928 = template_unbox(BIR.Family, v_1001129); template_continuation_218(v_1000928, v_1000918)}}}}}

def template_body_target_exclusion_boundaries() -> TemplateProgress<U32>:
  +v_1000911 = {"Wrap" : String}
  +v_1000912 = {None{} : Maybe<&2, String>}
  +v_1000913 = {1n : Nat}
  +v_1000914 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1001146 => template_body_par(0n), v_1001145 => +v_1000915 = template_unbox(BIR.Descriptor, v_1001145); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000915}}, False{}, v_1001144 => template_body_fld(v_1000915), v_1001143 => +v_1000916 = template_unbox(BIR.DescriptorField, v_1001143); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000914, [v_1000916]}}, False{}, v_1001142 => template_body_arm(v_1000914, [v_1000916]), v_1001141 => +v_1000917 = template_unbox(BIR.DescriptorArm, v_1001141); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000911, v_1000912, v_1000913, [v_1000917]}}, False{}, v_1001140 => template_body_fam(v_1000911, v_1000912, v_1000913, [v_1000917]), v_1001139 => +v_1000918 = template_unbox(BIR.Family, v_1001139); template_continuation_219(v_1000918)}}}}

def template_continuation_220(+v_1001200: cps_provider_1_LayoutResult, +v_35: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_35, "Wrap"}}, False{}, v_1001206 => template_body_check_recursive_key(v_35, "Wrap"), v_1001205 => +v_1001201 = template_unbox(Bool, v_1001205); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_1001200}}, False{}, v_1001204 => template_body_classify(v_1001200), v_1001203 => +v_1001202 = template_unbox(Nat, v_1001203); TemplateFinished{TemplateValue{template_pure_both(v_1001201, Nat.is_eq(v_1001202, 0n))}}}}

def template_continuation_221(+v_1001195: cps_provider_1_LayoutResult, +v_26: cps_provider_1_Context) -> TemplateProgress<Bool>:
  +v_1001197 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Relay", []}}, False{}, v_1001211 => template_body_ref("Relay", []), v_1001210 => +v_1001198 = template_unbox(BIR.Descriptor, v_1001210); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001197, [v_1001198]}}, False{}, v_1001209 => template_body_ref(v_1001197, [v_1001198]), v_1001208 => +v_1001199 = template_unbox(BIR.Descriptor, v_1001208); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_26 : cps_provider_1_Context}, v_1001199}}, v_1001207 => +v_1001200 = template_unbox(cps_provider_1_LayoutResult, v_1001207); template_continuation_220(v_1001200, v_1001195)}}}

def template_continuation_222(v_1001187: Maybe<&2, BIR.Quantity>, +v_1001190: BIR.Descriptor, +v_22: cps_provider_1_Context, +v_26: cps_provider_1_Context) -> TemplateProgress<Bool>:
  +v_30 = {BIR.DescriptorLambda{v_1001187, v_1001190} : BIR.Descriptor}
  +v_1001192 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Relay", [v_30]}}, False{}, v_1001216 => template_body_ref("Relay", [v_30]), v_1001215 => +v_1001193 = template_unbox(BIR.Descriptor, v_1001215); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001192, [v_1001193]}}, False{}, v_1001214 => template_body_ref(v_1001192, [v_1001193]), v_1001213 => +v_1001194 = template_unbox(BIR.Descriptor, v_1001213); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_22 : cps_provider_1_Context}, v_1001194}}, v_1001212 => +v_1001195 = template_unbox(cps_provider_1_LayoutResult, v_1001212); template_continuation_221(v_1001195, v_26)}}}

def template_continuation_223(+v_1001186: cps_provider_1_Context, +v_22: cps_provider_1_Context) -> TemplateProgress<Bool>:
  v_1001187 = {None{} : Maybe<&2, BIR.Quantity>}
  +v_1001188 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001220 => template_body_ref("U32", []), v_1001219 => +v_1001189 = template_unbox(BIR.Descriptor, v_1001219); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001188, [v_1001189]}}, False{}, v_1001218 => template_body_ref(v_1001188, [v_1001189]), v_1001217 => +v_1001190 = template_unbox(BIR.Descriptor, v_1001217); template_continuation_222(v_1001187, v_1001190, v_22, v_1001186)}}

def template_continuation_224(+v_1001178: cps_provider_1_Context, +v_6: BIR.Family, +v_18: BIR.Family, +v_12: BIR.Family) -> TemplateProgress<Bool>:
  v_1001179 = {[] : List<&2, BIR.Code>}
  v_1001180 = {[] : List<&2, BIR.Declaration>}
  v_1001181 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1001223 => template_body_fam_u32, v_1001222 => +v_1001185 = template_unbox(BIR.Family, v_1001222); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1001179, v_1001180, v_1001181, [{v_6 : BIR.Family}, {v_18 : BIR.Family}, {v_12 : BIR.Family}, v_1001185], [], BIR.Library{[]}}}}, v_1001221 => +v_1001186 = template_unbox(cps_provider_1_Context, v_1001221); template_continuation_223(v_1001186, v_1001178)}}

def template_continuation_225(+v_1001170: BIR.Family, +v_6: BIR.Family, +v_12: BIR.Family) -> TemplateProgress<Bool>:
  v_1001171 = {[] : List<&2, BIR.Code>}
  v_1001172 = {[] : List<&2, BIR.Declaration>}
  v_1001173 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1001226 => template_body_fam_u32, v_1001225 => +v_1001177 = template_unbox(BIR.Family, v_1001225); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1001171, v_1001172, v_1001173, [{v_6 : BIR.Family}, {v_12 : BIR.Family}, {v_1001170 : BIR.Family}, v_1001177], [], BIR.Library{[]}}}}, v_1001224 => +v_1001178 = template_unbox(cps_provider_1_Context, v_1001224); template_continuation_224(v_1001178, v_6, v_1001170, v_12)}}

def template_continuation_226(+v_1001162: BIR.Family, +v_6: BIR.Family) -> TemplateProgress<Bool>:
  +v_1001163 = {"Relay" : String}
  +v_1001164 = {None{} : Maybe<&2, String>}
  +v_1001165 = {0n : Nat}
  +v_1001166 = {"Relay" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001234 => template_body_ref("U32", []), v_1001233 => +v_1001167 = template_unbox(BIR.Descriptor, v_1001233); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001167}}, False{}, v_1001232 => template_body_fld(v_1001167), v_1001231 => +v_1001168 = template_unbox(BIR.DescriptorField, v_1001231); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1001166, [v_1001168]}}, False{}, v_1001230 => template_body_arm(v_1001166, [v_1001168]), v_1001229 => +v_1001169 = template_unbox(BIR.DescriptorArm, v_1001229); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1001163, v_1001164, v_1001165, [v_1001169]}}, False{}, v_1001228 => template_body_fam(v_1001163, v_1001164, v_1001165, [v_1001169]), v_1001227 => +v_1001170 = template_unbox(BIR.Family, v_1001227); template_continuation_225(v_1001170, v_6, v_1001162)}}}}

def template_continuation_227(+v_1001154: BIR.Family) -> TemplateProgress<Bool>:
  +v_1001155 = {"Relay" : String}
  +v_1001156 = {None{} : Maybe<&2, String>}
  +v_1001157 = {1n : Nat}
  +v_1001158 = {"Relay" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1001242 => template_body_par(0n), v_1001241 => +v_1001159 = template_unbox(BIR.Descriptor, v_1001241); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{BIR.DescriptorApplication{v_1001159, BIR.DescriptorNull{}}}}, False{}, v_1001240 => template_body_fld(BIR.DescriptorApplication{v_1001159, BIR.DescriptorNull{}}), v_1001239 => +v_1001160 = template_unbox(BIR.DescriptorField, v_1001239); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1001158, [v_1001160]}}, False{}, v_1001238 => template_body_arm(v_1001158, [v_1001160]), v_1001237 => +v_1001161 = template_unbox(BIR.DescriptorArm, v_1001237); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1001155, v_1001156, v_1001157, [v_1001161]}}, False{}, v_1001236 => template_body_fam(v_1001155, v_1001156, v_1001157, [v_1001161]), v_1001235 => +v_1001162 = template_unbox(BIR.Family, v_1001235); template_continuation_226(v_1001162, v_1001154)}}}}

def template_body_target_closure_authority_check() -> TemplateProgress<Bool>:
  +v_1001147 = {"Wrap" : String}
  +v_1001148 = {None{} : Maybe<&2, String>}
  +v_1001149 = {1n : Nat}
  +v_1001150 = {"Wrap" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1001250 => template_body_par(0n), v_1001249 => +v_1001151 = template_unbox(BIR.Descriptor, v_1001249); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001151}}, False{}, v_1001248 => template_body_fld(v_1001151), v_1001247 => +v_1001152 = template_unbox(BIR.DescriptorField, v_1001247); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1001150, [v_1001152]}}, False{}, v_1001246 => template_body_arm(v_1001150, [v_1001152]), v_1001245 => +v_1001153 = template_unbox(BIR.DescriptorArm, v_1001245); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1001147, v_1001148, v_1001149, [v_1001153]}}, False{}, v_1001244 => template_body_fam(v_1001147, v_1001148, v_1001149, [v_1001153]), v_1001243 => +v_1001154 = template_unbox(BIR.Family, v_1001243); template_continuation_227(v_1001154)}}}}

def template_continuation_228(+v_1001308: Bool, +v_28: cps_provider_1_LayoutResult, +v_32: cps_provider_1_LayoutResult, +v_36: cps_provider_1_LayoutResult, +v_40: Bool) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_28, "Closed"}}, False{}, v_1001317 => template_body_check_recursive_key(v_28, "Closed"), v_1001316 => +v_1001309 = template_unbox(Bool, v_1001316); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_32, "Closed"}}, False{}, v_1001315 => template_body_check_recursive_key(v_32, "Closed"), v_1001314 => +v_1001310 = template_unbox(Bool, v_1001314); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_recursive_key{v_36, "Closed"}}, False{}, v_1001313 => template_body_check_recursive_key(v_36, "Closed"), v_1001312 => +v_1001311 = template_unbox(Bool, v_1001312); TemplateFinished{TemplateValue{template_pure_both(v_1001309, template_pure_both(v_1001310, template_pure_both(v_1001311, template_pure_both(v_40, v_1001308))))}}}}}

def template_continuation_229(+v_1001302: Bool, +v_10: cps_provider_1_Context, +v_15: List<&2, BIR.DescriptorArm>, +v_28: cps_provider_1_LayoutResult, +v_32: cps_provider_1_LayoutResult, +v_36: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  +v_1001306 = {[] : List<&2, cps_provider_2_NfVal>}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, v_1001319 => +v_1001307 = template_unbox(Nat, v_1001319); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reenters{{v_10 : cps_provider_1_Context}, {"Closed" : String}, {v_15 : List<&2, BIR.DescriptorArm>}, v_1001306, v_1001307}}, v_1001318 => +v_1001308 = template_unbox(Bool, v_1001318); template_continuation_228(v_1001308, v_28, v_32, v_36, v_1001302)}}

def template_continuation_230(+v_1001295: cps_provider_1_LayoutResult, +v_10: cps_provider_1_Context, +v_24: BIR.Family, +v_15: List<&2, BIR.DescriptorArm>, +v_28: cps_provider_1_LayoutResult, +v_32: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  +v_1001298 = {[] : List<&2, cps_provider_2_NfVal>}
  +v_1001300 = {[] : List<&2, String>}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, v_1001321 => +v_1001301 = template_unbox(Nat, v_1001321); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_family_reach{{v_10 : cps_provider_1_Context}, {v_24 : BIR.Family}, v_1001298, {"Target" : String}, v_1001300, v_1001301}}, v_1001320 => +v_1001302 = template_unbox(Bool, v_1001320); template_continuation_229(v_1001302, v_10, v_15, v_28, v_32, v_1001295)}}

def template_continuation_231(+v_1001288: cps_provider_1_LayoutResult, +v_10: cps_provider_1_Context, +v_15: List<&2, BIR.DescriptorArm>, +v_24: BIR.Family, +v_28: cps_provider_1_LayoutResult) -> TemplateProgress<Bool>:
  +v_1001293 = {[] : List<&2, cps_provider_2_NfVal>}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, v_1001323 => +v_1001294 = template_unbox(Nat, v_1001323); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_native{{v_10 : cps_provider_1_Context}, {"Other" : String}, {"Closed" : String}, {v_15 : List<&2, BIR.DescriptorArm>}, v_1001293, v_1001294}}, v_1001322 => +v_1001295 = template_unbox(cps_provider_1_LayoutResult, v_1001322); template_continuation_230(v_1001295, v_10, v_24, v_15, v_28, v_1001288)}}

def template_continuation_232(+v_1001282: cps_provider_1_LayoutResult, +v_10: cps_provider_1_Context, +v_15: List<&2, BIR.DescriptorArm>, +v_24: BIR.Family) -> TemplateProgress<Bool>:
  +v_1001286 = {[] : List<&2, cps_provider_2_NfVal>}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, v_1001325 => +v_1001287 = template_unbox(Nat, v_1001325); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_data{{v_10 : cps_provider_1_Context}, {"Closed" : String}, {v_15 : List<&2, BIR.DescriptorArm>}, v_1001286, v_1001287}}, v_1001324 => +v_1001288 = template_unbox(cps_provider_1_LayoutResult, v_1001324); template_continuation_231(v_1001288, v_10, v_15, v_24, v_1001282)}}

def template_continuation_233(+v_1001277: BIR.Family, +v_10: cps_provider_1_Context, +v_18: BIR.Family, +v_15: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  +v_1001280 = {[] : List<&2, cps_provider_2_NfVal>}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, v_1001327 => +v_1001281 = template_unbox(Nat, v_1001327); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_family{{v_10 : cps_provider_1_Context}, {v_18 : BIR.Family}, v_1001280, v_1001281}}, v_1001326 => +v_1001282 = template_unbox(cps_provider_1_LayoutResult, v_1001326); template_continuation_232(v_1001282, v_10, v_15, v_1001277)}}

def template_continuation_234(+v_1001269: BIR.Family, +v_10: cps_provider_1_Context, +v_15: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  +v_1001270 = {"Closed" : String}
  +v_1001271 = {None{} : Maybe<&2, String>}
  +v_1001272 = {0n : Nat}
  +v_1001273 = {"Closed" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Target", []}}, False{}, v_1001335 => template_body_ref("Target", []), v_1001334 => +v_1001274 = template_unbox(BIR.Descriptor, v_1001334); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001274}}, False{}, v_1001333 => template_body_fld(v_1001274), v_1001332 => +v_1001275 = template_unbox(BIR.DescriptorField, v_1001332); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1001273, [v_1001275]}}, False{}, v_1001331 => template_body_arm(v_1001273, [v_1001275]), v_1001330 => +v_1001276 = template_unbox(BIR.DescriptorArm, v_1001330); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1001270, v_1001271, v_1001272, [v_1001276]}}, False{}, v_1001329 => template_body_fam(v_1001270, v_1001271, v_1001272, [v_1001276]), v_1001328 => +v_1001277 = template_unbox(BIR.Family, v_1001328); template_continuation_233(v_1001277, v_10, v_1001269, v_15)}}}}

def template_continuation_235(+v_1001268: BIR.DescriptorArm, +v_10: cps_provider_1_Context) -> TemplateProgress<Bool>:
  +v_15 = {[v_1001268] : List<&2, BIR.DescriptorArm>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"Closed", None{}, 0n, v_15}}, False{}, v_1001337 => template_body_fam("Closed", None{}, 0n, v_15), v_1001336 => +v_1001269 = template_unbox(BIR.Family, v_1001336); template_continuation_234(v_1001269, v_10, v_15)}

def template_continuation_236(+v_1001264: cps_provider_1_Context) -> TemplateProgress<Bool>:
  +v_1001265 = {"Closed" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Closed", []}}, False{}, v_1001343 => template_body_ref("Closed", []), v_1001342 => +v_1001266 = template_unbox(BIR.Descriptor, v_1001342); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001266}}, False{}, v_1001341 => template_body_fld(v_1001266), v_1001340 => +v_1001267 = template_unbox(BIR.DescriptorField, v_1001340); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1001265, [v_1001267]}}, False{}, v_1001339 => template_body_arm(v_1001265, [v_1001267]), v_1001338 => +v_1001268 = template_unbox(BIR.DescriptorArm, v_1001338); template_continuation_235(v_1001268, v_1001264)}}}

def template_continuation_237(+v_1001258: BIR.Family) -> TemplateProgress<Bool>:
  v_1001259 = {[] : List<&2, BIR.Code>}
  v_1001260 = {[] : List<&2, BIR.Declaration>}
  v_1001261 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1001346 => template_body_fam_u32, v_1001345 => +v_1001263 = template_unbox(BIR.Family, v_1001345); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{BIR.Program{v_1001259, v_1001260, v_1001261, [{v_1001258 : BIR.Family}, v_1001263], [], BIR.Library{[]}}}}, v_1001344 => +v_1001264 = template_unbox(cps_provider_1_Context, v_1001344); template_continuation_236(v_1001264)}}

def template_body_explicit_recursion_check() -> TemplateProgress<Bool>:
  +v_1001251 = {"Closed" : String}
  +v_1001252 = {None{} : Maybe<&2, String>}
  +v_1001253 = {0n : Nat}
  +v_1001254 = {"Closed" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001354 => template_body_ref("U32", []), v_1001353 => +v_1001255 = template_unbox(BIR.Descriptor, v_1001353); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001255}}, False{}, v_1001352 => template_body_fld(v_1001255), v_1001351 => +v_1001256 = template_unbox(BIR.DescriptorField, v_1001351); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1001254, [v_1001256]}}, False{}, v_1001350 => template_body_arm(v_1001254, [v_1001256]), v_1001349 => +v_1001257 = template_unbox(BIR.DescriptorArm, v_1001349); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1001251, v_1001252, v_1001253, [v_1001257]}}, False{}, v_1001348 => template_body_fam(v_1001251, v_1001252, v_1001253, [v_1001257]), v_1001347 => +v_1001258 = template_unbox(BIR.Family, v_1001347); template_continuation_237(v_1001258)}}}}

def template_continuation_238(v_1001400: U32, v_1001401: U32, v_1001402: U32, +v_1001404: U32, +v_1001406: U32) -> TemplateProgress<U32>:
  +v_71 = U32.add(v_1001400, U32.add(v_1001401, U32.add(v_1001402, U32.add(v_1001404, v_1001406))))
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_target_exclusion_boundaries{}}, False{}, v_1001422 => template_body_target_exclusion_boundaries, v_1001421 => +v_1001408 = template_unbox(U32, v_1001421); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_target_closure_authority_check{}}, False{}, v_1001420 => template_body_target_closure_authority_check, v_1001419 => +v_1001409 = template_unbox(Bool, v_1001419); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001409}}, False{}, v_1001418 => template_body_fail(v_1001409), v_1001417 => +v_1001410 = template_unbox(U32, v_1001417); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_explicit_recursion_check{}}, False{}, v_1001416 => template_body_explicit_recursion_check, v_1001415 => +v_1001411 = template_unbox(Bool, v_1001415); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001411}}, False{}, v_1001414 => template_body_fail(v_1001411), v_1001413 => +v_1001412 = template_unbox(U32, v_1001413); TemplateFinished{TemplateValue{U32.add({v_71 : U32}, U32.add(v_1001408, U32.add(v_1001410, v_1001412)))}}}}}}}

def template_continuation_239(+v_1001395: U32, +v_1001397: U32, +v_1001399: U32, +v_49: U32, +v_57: U32) -> TemplateProgress<U32>:
  +v_65 = U32.add(v_1001395, U32.add(v_1001397, v_1001399))
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_generic_recursion_check{}}, False{}, v_1001430 => template_body_generic_recursion_check, v_1001429 => +v_1001403 = template_unbox(Bool, v_1001429); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001403}}, False{}, v_1001428 => template_body_fail(v_1001403), v_1001427 => +v_1001404 = template_unbox(U32, v_1001427); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_duplicate_recursion_check{}}, False{}, v_1001426 => template_body_duplicate_recursion_check, v_1001425 => +v_1001405 = template_unbox(Bool, v_1001425); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001405}}, False{}, v_1001424 => template_body_fail(v_1001405), v_1001423 => +v_1001406 = template_unbox(U32, v_1001423); template_continuation_238({v_49 : U32}, {v_57 : U32}, {v_65 : U32}, v_1001404, v_1001406)}}}}

def template_continuation_240(+v_1001389: U32, +v_1001391: U32, +v_1001393: U32, +v_29: cps_provider_1_LayoutResult, +v_34: cps_provider_1_LayoutResult, +v_45: cps_provider_1_LayoutResult, +v_49: U32) -> TemplateProgress<U32>:
  +v_57 = U32.add(v_1001389, U32.add(v_1001391, v_1001393))
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_single_box_field{v_29}}, False{}, v_1001442 => template_body_check_single_box_field(v_29), v_1001441 => +v_1001394 = template_unbox(Bool, v_1001441); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001394}}, False{}, v_1001440 => template_body_fail(v_1001394), v_1001439 => +v_1001395 = template_unbox(U32, v_1001439); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_34}}, False{}, v_1001438 => template_body_classify(v_34), v_1001437 => +v_1001396 = template_unbox(Nat, v_1001437); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{Nat.is_eq(v_1001396, 0n)}}, False{}, v_1001436 => template_body_fail(Nat.is_eq(v_1001396, 0n)), v_1001435 => +v_1001397 = template_unbox(U32, v_1001435); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_single_box_field{v_45}}, False{}, v_1001434 => template_body_check_single_box_field(v_45), v_1001433 => +v_1001398 = template_unbox(Bool, v_1001433); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001398}}, False{}, v_1001432 => template_body_fail(v_1001398), v_1001431 => +v_1001399 = template_unbox(U32, v_1001431); template_continuation_239(v_1001395, v_1001397, v_1001399, v_49, v_57)}}}}}}

def template_continuation_241(+v_1001387: U32, +v_13: cps_provider_1_LayoutResult, +v_19: cps_provider_1_LayoutResult, +v_25: cps_provider_1_LayoutResult, +v_29: cps_provider_1_LayoutResult, +v_34: cps_provider_1_LayoutResult, +v_45: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_classify{v_13}}, False{}, v_1001454 => template_body_classify(v_13), v_1001453 => +v_1001388 = template_unbox(Nat, v_1001453); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{Nat.is_eq(v_1001388, 0n)}}, False{}, v_1001452 => template_body_fail(Nat.is_eq(v_1001388, 0n)), v_1001451 => +v_1001389 = template_unbox(U32, v_1001451); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_single_box_field{v_19}}, False{}, v_1001450 => template_body_check_single_box_field(v_19), v_1001449 => +v_1001390 = template_unbox(Bool, v_1001449); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001390}}, False{}, v_1001448 => template_body_fail(v_1001390), v_1001447 => +v_1001391 = template_unbox(U32, v_1001447); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_recursive{v_25}}, False{}, v_1001446 => template_body_check_recursive(v_25), v_1001445 => +v_1001392 = template_unbox(Bool, v_1001445); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001392}}, False{}, v_1001444 => template_body_fail(v_1001392), v_1001443 => +v_1001393 = template_unbox(U32, v_1001443); template_continuation_240(v_1001389, v_1001391, v_1001393, v_29, v_34, v_45, v_1001387)}}}}}}

def template_continuation_242(+v_1001385: cps_provider_1_LayoutResult, +v_3: List<&2, BIR.TypeFunction>, +v_13: cps_provider_1_LayoutResult, +v_19: cps_provider_1_LayoutResult, +v_25: cps_provider_1_LayoutResult, +v_29: cps_provider_1_LayoutResult, +v_34: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursive_descriptors{}}, False{}, v_1001458 => template_body_recursive_descriptors, v_1001457 => +v_1001386 = template_unbox(List<&2, BIR.Descriptor>, v_1001457); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursive_descriptor_failures{v_1001386, v_3}}, False{}, v_1001456 => template_body_recursive_descriptor_failures(v_1001386, v_3), v_1001455 => +v_1001387 = template_unbox(U32, v_1001455); template_continuation_241(v_1001387, v_13, v_19, v_25, v_29, v_34, v_1001385)}}

def template_continuation_243(+v_1001382: BIR.Family, +v_3: List<&2, BIR.TypeFunction>, +v_13: cps_provider_1_LayoutResult, +v_19: cps_provider_1_LayoutResult, +v_25: cps_provider_1_LayoutResult, +v_29: cps_provider_1_LayoutResult, +v_34: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Other", []}}, False{}, v_1001464 => template_body_ref("Other", []), v_1001463 => +v_1001383 = template_unbox(BIR.Descriptor, v_1001463); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001383}}, False{}, v_1001462 => template_body_fld(v_1001383), v_1001461 => +v_1001384 = template_unbox(BIR.DescriptorField, v_1001461); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1001384], [v_1001382], []}}, False{}, v_1001460 => template_body_recursion_layout([v_1001384], [v_1001382], []), v_1001459 => +v_1001385 = template_unbox(cps_provider_1_LayoutResult, v_1001459); template_continuation_242(v_1001385, v_3, v_13, v_19, v_25, v_29, v_34)}}}

def template_continuation_244(+v_1001374: cps_provider_1_LayoutResult, +v_3: List<&2, BIR.TypeFunction>, +v_13: cps_provider_1_LayoutResult, +v_19: cps_provider_1_LayoutResult, +v_25: cps_provider_1_LayoutResult, +v_29: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  +v_1001375 = {"Other" : String}
  +v_1001376 = {None{} : Maybe<&2, String>}
  +v_1001377 = {0n : Nat}
  +v_1001378 = {"Other" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Other", []}}, False{}, v_1001472 => template_body_ref("Other", []), v_1001471 => +v_1001379 = template_unbox(BIR.Descriptor, v_1001471); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001379}}, False{}, v_1001470 => template_body_fld(v_1001379), v_1001469 => +v_1001380 = template_unbox(BIR.DescriptorField, v_1001469); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1001378, [v_1001380]}}, False{}, v_1001468 => template_body_arm(v_1001378, [v_1001380]), v_1001467 => +v_1001381 = template_unbox(BIR.DescriptorArm, v_1001467); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1001375, v_1001376, v_1001377, [v_1001381]}}, False{}, v_1001466 => template_body_fam(v_1001375, v_1001376, v_1001377, [v_1001381]), v_1001465 => +v_1001382 = template_unbox(BIR.Family, v_1001465); template_continuation_243(v_1001382, v_3, v_13, v_19, v_25, v_29, v_1001374)}}}}

def template_continuation_245(+v_1001371: cps_provider_1_LayoutResult, +v_6: BIR.Descriptor, +v_3: List<&2, BIR.TypeFunction>, +v_13: cps_provider_1_LayoutResult, +v_19: cps_provider_1_LayoutResult, +v_25: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Discard", [v_6]}}, False{}, v_1001478 => template_body_ref("Discard", [v_6]), v_1001477 => +v_1001372 = template_unbox(BIR.Descriptor, v_1001477); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001372}}, False{}, v_1001476 => template_body_fld(v_1001372), v_1001475 => +v_1001373 = template_unbox(BIR.DescriptorField, v_1001475); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1001373], [], v_3}}, False{}, v_1001474 => template_body_recursion_layout([v_1001373], [], v_3), v_1001473 => +v_1001374 = template_unbox(cps_provider_1_LayoutResult, v_1001473); template_continuation_244(v_1001374, v_3, v_13, v_19, v_25, v_1001371)}}}

def template_continuation_246(+v_1001369: cps_provider_1_LayoutResult, +v_6: BIR.Descriptor, +v_3: List<&2, BIR.TypeFunction>, +v_13: cps_provider_1_LayoutResult, +v_19: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{BIR.DescriptorLambda{None{}, v_6}}}, False{}, v_1001482 => template_body_fld(BIR.DescriptorLambda{None{}, v_6}), v_1001481 => +v_1001370 = template_unbox(BIR.DescriptorField, v_1001481); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1001370], [], []}}, False{}, v_1001480 => template_body_recursion_layout([v_1001370], [], []), v_1001479 => +v_1001371 = template_unbox(cps_provider_1_LayoutResult, v_1001479); template_continuation_245(v_1001371, v_6, v_3, v_13, v_19, v_1001369)}}

def template_continuation_247(+v_6: BIR.Descriptor, +v_1001365: BIR.DescriptorField, +v_3: List<&2, BIR.TypeFunction>, +v_13: cps_provider_1_LayoutResult, +v_19: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  v_1001366 = {[v_6] : List<&2, BIR.Descriptor>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1001488 => template_body_par(0n), v_1001487 => +v_1001367 = template_unbox(BIR.Descriptor, v_1001487); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{BIR.DescriptorLet{v_1001366, v_1001367}}}, False{}, v_1001486 => template_body_fld(BIR.DescriptorLet{v_1001366, v_1001367}), v_1001485 => +v_1001368 = template_unbox(BIR.DescriptorField, v_1001485); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1001365, v_1001368], [], []}}, False{}, v_1001484 => template_body_recursion_layout([v_1001365, v_1001368], [], []), v_1001483 => +v_1001369 = template_unbox(cps_provider_1_LayoutResult, v_1001483); template_continuation_246(v_1001369, v_6, v_3, v_13, v_19)}}}

def template_continuation_248(+v_1001364: cps_provider_1_LayoutResult, +v_6: BIR.Descriptor, +v_3: List<&2, BIR.TypeFunction>, +v_13: cps_provider_1_LayoutResult) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_erased_fld{}}, False{}, v_1001490 => template_body_erased_fld, v_1001489 => +v_1001365 = template_unbox(BIR.DescriptorField, v_1001489); template_continuation_247(v_6, v_1001365, v_3, v_13, v_1001364)}

def template_continuation_249(+v_1001360: cps_provider_1_LayoutResult, +v_6: BIR.Descriptor, +v_3: List<&2, BIR.TypeFunction>) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_erased_fld{}}, False{}, v_1001498 => template_body_erased_fld, v_1001497 => +v_1001361 = template_unbox(BIR.DescriptorField, v_1001497); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1001496 => template_body_par(0n), v_1001495 => +v_1001362 = template_unbox(BIR.Descriptor, v_1001495); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001362}}, False{}, v_1001494 => template_body_fld(v_1001362), v_1001493 => +v_1001363 = template_unbox(BIR.DescriptorField, v_1001493); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1001361, v_1001363], [], []}}, False{}, v_1001492 => template_body_recursion_layout([v_1001361, v_1001363], [], []), v_1001491 => +v_1001364 = template_unbox(cps_provider_1_LayoutResult, v_1001491); template_continuation_248(v_1001364, v_6, v_3, v_1001360)}}}}

def template_continuation_250(+v_1001356: BIR.Descriptor, +v_3: List<&2, BIR.TypeFunction>) -> TemplateProgress<U32>:
  +v_8 = {BIR.DescriptorField{None{}, BIR.Erased{}, v_1001356} : BIR.DescriptorField}
  v_1001357 = {v_8 : BIR.DescriptorField}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001504 => template_body_ref("U32", []), v_1001503 => +v_1001358 = template_unbox(BIR.Descriptor, v_1001503); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1001358}}, False{}, v_1001502 => template_body_fld(v_1001358), v_1001501 => +v_1001359 = template_unbox(BIR.DescriptorField, v_1001501); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_layout{[v_1001357, v_1001359], [], []}}, False{}, v_1001500 => template_body_recursion_layout([v_1001357, v_1001359], [], []), v_1001499 => +v_1001360 = template_unbox(cps_provider_1_LayoutResult, v_1001499); template_continuation_249(v_1001360, v_1001356, v_3)}}}

def template_continuation_251(+v_1001355: List<&2, BIR.TypeFunction>) -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1001506 => template_body_ref("ListT", []), v_1001505 => +v_1001356 = template_unbox(BIR.Descriptor, v_1001505); template_continuation_250(v_1001356, v_1001355)}

def template_body_recursion_boundaries() -> TemplateProgress<U32>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_functions{}}, False{}, v_1001508 => template_body_recursion_functions, v_1001507 => +v_1001355 = template_unbox(List<&2, BIR.TypeFunction>, v_1001507); template_continuation_251(v_1001355)}

def template_continuation_252(+v_1001822: cps_provider_1_Context, v_1001760: U32, v_1001761: U32, v_1001762: U32, v_1001763: U32, v_1001764: U32, v_1001765: U32, v_1001766: U32, v_1001767: U32, v_1001768: U32, v_1001769: U32, v_1001770: U32, v_1001771: U32, v_1001772: U32, v_1001773: U32, v_1001774: U32, v_1001775: U32, v_1001776: U32, v_1001777: U32, v_1001778: U32, v_1001779: U32, v_1001780: U32, v_1001781: U32, v_1001782: U32, v_1001783: U32, v_1001784: U32, v_1001785: U32, v_1001786: U32, v_1001787: U32, v_1001788: U32, v_1001789: U32, v_1001790: U32, v_1001791: U32, v_1001792: U32, v_1001793: U32, v_1001794: U32, v_1001795: U32, v_1001796: U32, v_1001797: U32, v_1001798: U32, v_1001799: U32, v_1001800: U32, v_1001801: U32, v_1001802: U32, +v_1001804: U32, +v_1001811: U32, +v_1001815: U32, +v_1001820: U32) -> TemplateProgress<ClaySmoke>:
  +v_1001823 = {"IO" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1001837 => template_body_ref("Nat", []), v_1001836 => +v_1001824 = template_unbox(BIR.Descriptor, v_1001836); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001823, [v_1001824]}}, False{}, v_1001835 => template_body_ref(v_1001823, [v_1001824]), v_1001834 => +v_1001825 = template_unbox(BIR.Descriptor, v_1001834); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{v_1001822, v_1001825}}, v_1001833 => +v_1001826 = template_unbox(cps_provider_1_HeadResult, v_1001833); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_shadow_io{v_1001826}}, False{}, v_1001832 => template_body_check_shadow_io(v_1001826), v_1001831 => +v_1001827 = template_unbox(Bool, v_1001831); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001827}}, False{}, v_1001830 => template_body_fail(v_1001827), v_1001829 => +v_1001828 = template_unbox(U32, v_1001829); TemplateFinished{TemplateValue{ClaySmoke{U32.add(v_1001760, U32.add(v_1001761, U32.add(v_1001762, U32.add(v_1001763, U32.add(v_1001764, U32.add(v_1001765, U32.add(v_1001766, U32.add(v_1001767, U32.add(v_1001768, U32.add(v_1001769, U32.add(v_1001770, U32.add(v_1001771, U32.add(v_1001772, U32.add(v_1001773, U32.add(v_1001774, U32.add(v_1001775, U32.add(v_1001776, U32.add(v_1001777, U32.add(v_1001778, U32.add(v_1001779, U32.add(v_1001780, U32.add(v_1001781, U32.add(v_1001782, U32.add(v_1001783, U32.add(v_1001784, U32.add(v_1001785, U32.add(v_1001786, U32.add(v_1001787, U32.add(v_1001788, U32.add(v_1001789, U32.add(v_1001790, U32.add(v_1001791, U32.add(v_1001792, U32.add(v_1001793, U32.add(v_1001794, U32.add(v_1001795, U32.add(v_1001796, U32.add(v_1001797, U32.add(v_1001798, U32.add(v_1001799, U32.add(v_1001800, U32.add(v_1001801, U32.add(v_1001802, U32.add(v_1001804, U32.add(v_1001811, U32.add(v_1001815, U32.add(v_1001820, v_1001828)))))))))))))))))))))))))))))))))))))))))))))))}}}}}}}}

def template_continuation_253(+v_6: cps_provider_1_Context, v_1001760: U32, v_1001761: U32, v_1001762: U32, v_1001763: U32, v_1001764: U32, v_1001765: U32, v_1001766: U32, v_1001767: U32, v_1001768: U32, v_1001769: U32, v_1001770: U32, v_1001771: U32, v_1001772: U32, v_1001773: U32, v_1001774: U32, v_1001775: U32, v_1001776: U32, v_1001777: U32, v_1001778: U32, v_1001779: U32, v_1001780: U32, v_1001781: U32, v_1001782: U32, v_1001783: U32, v_1001784: U32, v_1001785: U32, v_1001786: U32, v_1001787: U32, v_1001788: U32, v_1001789: U32, v_1001790: U32, v_1001791: U32, v_1001792: U32, v_1001793: U32, v_1001794: U32, v_1001795: U32, v_1001796: U32, v_1001797: U32, v_1001798: U32, v_1001799: U32, v_1001800: U32, v_1001801: U32, v_1001802: U32, +v_1001804: U32, +v_1001811: U32, +v_1001815: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"MyIO", []}}, False{}, v_1001847 => template_body_ref("MyIO", []), v_1001846 => +v_1001817 = template_unbox(BIR.Descriptor, v_1001846); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{{v_6 : cps_provider_1_Context}, v_1001817}}, v_1001845 => +v_1001818 = template_unbox(cps_provider_1_HeadResult, v_1001845); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_io_native{v_1001818}}, False{}, v_1001844 => template_body_check_io_native(v_1001818), v_1001843 => +v_1001819 = template_unbox(Bool, v_1001843); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001819}}, False{}, v_1001842 => template_body_fail(v_1001819), v_1001841 => +v_1001820 = template_unbox(U32, v_1001841); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_program_shadow{}}, False{}, v_1001840 => template_body_program_shadow, v_1001839 => +v_1001821 = template_unbox(BIR.Program, v_1001839); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{v_1001821}}, v_1001838 => +v_1001822 = template_unbox(cps_provider_1_Context, v_1001838); template_continuation_252(v_1001822, v_1001760, v_1001761, v_1001762, v_1001763, v_1001764, v_1001765, v_1001766, v_1001767, v_1001768, v_1001769, v_1001770, v_1001771, v_1001772, v_1001773, v_1001774, v_1001775, v_1001776, v_1001777, v_1001778, v_1001779, v_1001780, v_1001781, v_1001782, v_1001783, v_1001784, v_1001785, v_1001786, v_1001787, v_1001788, v_1001789, v_1001790, v_1001791, v_1001792, v_1001793, v_1001794, v_1001795, v_1001796, v_1001797, v_1001798, v_1001799, v_1001800, v_1001801, v_1001802, v_1001804, v_1001811, v_1001815, v_1001820)}}}}}}

def template_continuation_254(+v_6: cps_provider_1_Context, v_1001760: U32, v_1001761: U32, v_1001762: U32, v_1001763: U32, v_1001764: U32, v_1001765: U32, v_1001766: U32, v_1001767: U32, v_1001768: U32, v_1001769: U32, v_1001770: U32, v_1001771: U32, v_1001772: U32, v_1001773: U32, v_1001774: U32, v_1001775: U32, v_1001776: U32, v_1001777: U32, v_1001778: U32, v_1001779: U32, v_1001780: U32, v_1001781: U32, v_1001782: U32, v_1001783: U32, v_1001784: U32, v_1001785: U32, v_1001786: U32, v_1001787: U32, v_1001788: U32, v_1001789: U32, v_1001790: U32, v_1001791: U32, v_1001792: U32, v_1001793: U32, v_1001794: U32, v_1001795: U32, v_1001796: U32, v_1001797: U32, v_1001798: U32, v_1001799: U32, v_1001800: U32, v_1001801: U32, v_1001802: U32, +v_1001804: U32, +v_1001811: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"IO", []}}, False{}, v_1001852 => template_body_ref("IO", []), v_1001851 => +v_1001813 = template_unbox(BIR.Descriptor, v_1001851); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{{v_6 : cps_provider_1_Context}, v_1001813}}, v_1001850 => +v_1001814 = template_unbox(cps_provider_1_HeadResult, v_1001850); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{template_pure_check_io_under(v_1001814)}}, False{}, v_1001849 => template_body_fail(template_pure_check_io_under(v_1001814)), v_1001848 => +v_1001815 = template_unbox(U32, v_1001848); template_continuation_253(v_6, v_1001760, v_1001761, v_1001762, v_1001763, v_1001764, v_1001765, v_1001766, v_1001767, v_1001768, v_1001769, v_1001770, v_1001771, v_1001772, v_1001773, v_1001774, v_1001775, v_1001776, v_1001777, v_1001778, v_1001779, v_1001780, v_1001781, v_1001782, v_1001783, v_1001784, v_1001785, v_1001786, v_1001787, v_1001788, v_1001789, v_1001790, v_1001791, v_1001792, v_1001793, v_1001794, v_1001795, v_1001796, v_1001797, v_1001798, v_1001799, v_1001800, v_1001801, v_1001802, v_1001804, v_1001811, v_1001815)}}}

def template_continuation_255(+v_6: cps_provider_1_Context, v_1001760: U32, v_1001761: U32, v_1001762: U32, v_1001763: U32, v_1001764: U32, v_1001765: U32, v_1001766: U32, v_1001767: U32, v_1001768: U32, v_1001769: U32, v_1001770: U32, v_1001771: U32, v_1001772: U32, v_1001773: U32, v_1001774: U32, v_1001775: U32, v_1001776: U32, v_1001777: U32, v_1001778: U32, v_1001779: U32, v_1001780: U32, v_1001781: U32, v_1001782: U32, v_1001783: U32, v_1001784: U32, v_1001785: U32, v_1001786: U32, v_1001787: U32, v_1001788: U32, v_1001789: U32, v_1001790: U32, v_1001791: U32, v_1001792: U32, v_1001793: U32, v_1001794: U32, v_1001795: U32, v_1001796: U32, v_1001797: U32, v_1001798: U32, v_1001799: U32, v_1001800: U32, v_1001801: U32, v_1001802: U32, +v_1001804: U32) -> TemplateProgress<ClaySmoke>:
  +v_1001806 = {"IO" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1001861 => template_body_ref("Nat", []), v_1001860 => +v_1001807 = template_unbox(BIR.Descriptor, v_1001860); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001806, [v_1001807]}}, False{}, v_1001859 => template_body_ref(v_1001806, [v_1001807]), v_1001858 => +v_1001808 = template_unbox(BIR.Descriptor, v_1001858); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{{v_6 : cps_provider_1_Context}, v_1001808}}, v_1001857 => +v_1001809 = template_unbox(cps_provider_1_HeadResult, v_1001857); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_io_native{v_1001809}}, False{}, v_1001856 => template_body_check_io_native(v_1001809), v_1001855 => +v_1001810 = template_unbox(Bool, v_1001855); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001810}}, False{}, v_1001854 => template_body_fail(v_1001810), v_1001853 => +v_1001811 = template_unbox(U32, v_1001853); template_continuation_254(v_6, v_1001760, v_1001761, v_1001762, v_1001763, v_1001764, v_1001765, v_1001766, v_1001767, v_1001768, v_1001769, v_1001770, v_1001771, v_1001772, v_1001773, v_1001774, v_1001775, v_1001776, v_1001777, v_1001778, v_1001779, v_1001780, v_1001781, v_1001782, v_1001783, v_1001784, v_1001785, v_1001786, v_1001787, v_1001788, v_1001789, v_1001790, v_1001791, v_1001792, v_1001793, v_1001794, v_1001795, v_1001796, v_1001797, v_1001798, v_1001799, v_1001800, v_1001801, v_1001802, v_1001804, v_1001811)}}}}}

def template_continuation_256(v_1001758: U32, +v_1001759: U32, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32, +v_6: cps_provider_1_Context) -> TemplateProgress<ClaySmoke>:
  +v_422 = U32.add(v_1001758, v_1001759)
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_deep_chain_check{}}, False{}, v_1001865 => template_body_deep_chain_check, v_1001864 => +v_1001803 = template_unbox(Bool, v_1001864); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001803}}, False{}, v_1001863 => template_body_fail(v_1001803), v_1001862 => +v_1001804 = template_unbox(U32, v_1001862); template_continuation_255(v_6, {v_422 : U32}, {v_130 : U32}, {v_134 : U32}, {v_138 : U32}, {v_142 : U32}, {v_146 : U32}, {v_150 : U32}, {v_154 : U32}, {v_158 : U32}, {v_162 : U32}, {v_166 : U32}, {v_170 : U32}, {v_174 : U32}, {v_178 : U32}, {v_182 : U32}, {v_186 : U32}, {v_190 : U32}, {v_194 : U32}, {v_198 : U32}, {v_202 : U32}, {v_206 : U32}, {v_210 : U32}, {v_214 : U32}, {v_218 : U32}, {v_222 : U32}, {v_226 : U32}, {v_230 : U32}, {v_234 : U32}, {v_238 : U32}, {v_253 : U32}, {v_257 : U32}, {v_261 : U32}, {v_265 : U32}, {v_269 : U32}, {v_273 : U32}, {v_277 : U32}, {v_281 : U32}, {v_318 : U32}, {v_322 : U32}, {v_326 : U32}, {v_330 : U32}, {v_334 : U32}, {v_338 : U32}, v_1001804)}}

def template_continuation_257(+v_1001735: U32, +v_1001737: U32, +v_1001739: U32, +v_1001741: U32, +v_1001743: U32, +v_1001744: U32, +v_1001746: U32, +v_1001748: U32, +v_1001750: U32, +v_1001752: U32, +v_1001753: U32, +v_1001755: U32, +v_1001757: U32, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32, +v_6: cps_provider_1_Context) -> TemplateProgress<ClaySmoke>:
  +v_419 = U32.add(v_1001735, U32.add(v_1001737, U32.add(v_1001739, U32.add(v_1001741, U32.add(v_1001743, U32.add(v_1001744, U32.add(v_1001746, U32.add(v_1001748, U32.add(v_1001750, U32.add(v_1001752, U32.add(v_1001753, U32.add(v_1001755, v_1001757))))))))))))
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_recursion_boundaries{}}, False{}, v_1001867 => template_body_recursion_boundaries, v_1001866 => +v_1001759 = template_unbox(U32, v_1001866); template_continuation_256({v_419 : U32}, v_1001759, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338, v_6)}

def template_continuation_258(+v_1001733: cps_provider_1_NodeResult, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_369: cps_provider_1_NodeResult, +v_376: cps_provider_1_NodeResult, +v_379: Maybe<&2, BIR.DescriptorArm>, +v_382: Maybe<&2, BIR.DescriptorArm>, +v_385: Maybe<&2, BIR.DescriptorArm>, +v_388: Maybe<&2, BIR.DescriptorArm>, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32, +v_6: cps_provider_1_Context) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_pt_node{v_345}}, False{}, v_1001915 => template_body_check_pt_node(v_345), v_1001914 => +v_1001734 = template_unbox(Bool, v_1001914); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001734}}, False{}, v_1001913 => template_body_fail(v_1001734), v_1001912 => +v_1001735 = template_unbox(U32, v_1001912); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_box_declared_node{v_348}}, False{}, v_1001911 => template_body_check_box_declared_node(v_348), v_1001910 => +v_1001736 = template_unbox(Bool, v_1001910); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001736}}, False{}, v_1001909 => template_body_fail(v_1001736), v_1001908 => +v_1001737 = template_unbox(U32, v_1001908); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_box_value{v_353}}, False{}, v_1001907 => template_body_check_box_value(v_353), v_1001906 => +v_1001738 = template_unbox(Bool, v_1001906); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001738}}, False{}, v_1001905 => template_body_fail(v_1001738), v_1001904 => +v_1001739 = template_unbox(U32, v_1001904); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_w32_packed{v_356}}, False{}, v_1001903 => template_body_check_w32_packed(v_356), v_1001902 => +v_1001740 = template_unbox(Bool, v_1001902); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001740}}, False{}, v_1001901 => template_body_fail(v_1001740), v_1001900 => +v_1001741 = template_unbox(U32, v_1001900); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_erased_node{v_359}}, False{}, v_1001899 => template_body_check_erased_node(v_359), v_1001898 => +v_1001742 = template_unbox(Bool, v_1001898); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001742}}, False{}, v_1001897 => template_body_fail(v_1001742), v_1001896 => +v_1001743 = template_unbox(U32, v_1001896); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{template_pure_check_node_failed(v_362)}}, False{}, v_1001895 => template_body_fail(template_pure_check_node_failed(v_362)), v_1001894 => +v_1001744 = template_unbox(U32, v_1001894); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_three_word_node{v_369}}, False{}, v_1001893 => template_body_check_three_word_node(v_369), v_1001892 => +v_1001745 = template_unbox(Bool, v_1001892); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001745}}, False{}, v_1001891 => template_body_fail(v_1001745), v_1001890 => +v_1001746 = template_unbox(U32, v_1001890); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_packed_one{v_376}}, False{}, v_1001889 => template_body_check_packed_one(v_376), v_1001888 => +v_1001747 = template_unbox(Bool, v_1001888); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001747}}, False{}, v_1001887 => template_body_fail(v_1001747), v_1001886 => +v_1001748 = template_unbox(U32, v_1001886); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_declared_count{v_379, 2n}}, False{}, v_1001885 => template_body_check_declared_count(v_379, 2n), v_1001884 => +v_1001749 = template_unbox(Bool, v_1001884); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001749}}, False{}, v_1001883 => template_body_fail(v_1001749), v_1001882 => +v_1001750 = template_unbox(U32, v_1001882); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_declared_count{v_382, 3n}}, False{}, v_1001881 => template_body_check_declared_count(v_382, 3n), v_1001880 => +v_1001751 = template_unbox(Bool, v_1001880); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001751}}, False{}, v_1001879 => template_body_fail(v_1001751), v_1001878 => +v_1001752 = template_unbox(U32, v_1001878); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{template_pure_check_declared_none(v_385)}}, False{}, v_1001877 => template_body_fail(template_pure_check_declared_none(v_385)), v_1001876 => +v_1001753 = template_unbox(U32, v_1001876); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_declared_count{v_388, 1n}}, False{}, v_1001875 => template_body_check_declared_count(v_388, 1n), v_1001874 => +v_1001754 = template_unbox(Bool, v_1001874); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001754}}, False{}, v_1001873 => template_body_fail(v_1001754), v_1001872 => +v_1001755 = template_unbox(U32, v_1001872); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_pt_node{v_1001733}}, False{}, v_1001871 => template_body_check_pt_node(v_1001733), v_1001870 => +v_1001756 = template_unbox(Bool, v_1001870); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001756}}, False{}, v_1001869 => template_body_fail(v_1001756), v_1001868 => +v_1001757 = template_unbox(U32, v_1001868); template_continuation_257(v_1001735, v_1001737, v_1001739, v_1001741, v_1001743, v_1001744, v_1001746, v_1001748, v_1001750, v_1001752, v_1001753, v_1001755, v_1001757, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338, v_6)}}}}}}}}}}}}}}}}}}}}}}}}

def template_continuation_259(+v_1001732: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_369: cps_provider_1_NodeResult, +v_376: cps_provider_1_NodeResult, +v_379: Maybe<&2, BIR.DescriptorArm>, +v_382: Maybe<&2, BIR.DescriptorArm>, +v_385: Maybe<&2, BIR.DescriptorArm>, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_6, "Pt"}}, v_1001916 => +v_1001733 = template_unbox(cps_provider_1_NodeResult, v_1001916); template_continuation_258(v_1001733, v_345, v_348, v_353, v_356, v_359, v_362, v_369, v_376, v_379, v_382, v_385, v_1001732, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338, v_6)}

def template_continuation_260(+v_1001731: Maybe<&2, BIR.DescriptorArm>, +v_373: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_369: cps_provider_1_NodeResult, +v_376: cps_provider_1_NodeResult, +v_379: Maybe<&2, BIR.DescriptorArm>, +v_382: Maybe<&2, BIR.DescriptorArm>, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_declared{v_373, "Same"}}, v_1001917 => +v_1001732 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1001917); template_continuation_259(v_1001732, v_6, v_345, v_348, v_353, v_356, v_359, v_362, v_369, v_376, v_379, v_382, v_1001731, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_261(+v_1001730: Maybe<&2, BIR.DescriptorArm>, +v_342: cps_provider_1_Context, +v_373: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_369: cps_provider_1_NodeResult, +v_376: cps_provider_1_NodeResult, +v_379: Maybe<&2, BIR.DescriptorArm>, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_declared{v_342, "Chan"}}, v_1001918 => +v_1001731 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1001918); template_continuation_260(v_1001731, v_373, v_6, v_345, v_348, v_353, v_356, v_359, v_362, v_369, v_376, v_379, v_1001730, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_262(+v_1001729: Maybe<&2, BIR.DescriptorArm>, +v_342: cps_provider_1_Context, +v_373: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_369: cps_provider_1_NodeResult, +v_376: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_declared{v_342, "Er"}}, v_1001919 => +v_1001730 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1001919); template_continuation_261(v_1001730, v_342, v_373, v_6, v_345, v_348, v_353, v_356, v_359, v_362, v_369, v_376, v_1001729, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_263(+v_1001728: cps_provider_1_NodeResult, +v_342: cps_provider_1_Context, +v_373: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_369: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_declared{v_342, "Pt"}}, v_1001920 => +v_1001729 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1001920); template_continuation_262(v_1001729, v_342, v_373, v_6, v_345, v_348, v_353, v_356, v_359, v_362, v_369, v_1001728, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_264(+v_1001727: cps_provider_1_Context, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_369: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_1001727, "Same"}}, v_1001921 => +v_1001728 = template_unbox(cps_provider_1_NodeResult, v_1001921); template_continuation_263(v_1001728, v_342, v_1001727, v_6, v_345, v_348, v_353, v_356, v_359, v_362, v_369, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_265(+v_1001725: cps_provider_1_NodeResult, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_program_first{}}, False{}, v_1001924 => template_body_program_first, v_1001923 => +v_1001726 = template_unbox(BIR.Program, v_1001923); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{v_1001726}}, v_1001922 => +v_1001727 = template_unbox(cps_provider_1_Context, v_1001922); template_continuation_264(v_1001727, v_342, v_6, v_345, v_348, v_353, v_356, v_359, v_362, v_1001725, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}}

def template_continuation_266(+v_1001724: cps_provider_1_Context, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_362: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_1001724, "Pt"}}, v_1001925 => +v_1001725 = template_unbox(cps_provider_1_NodeResult, v_1001925); template_continuation_265(v_1001725, v_342, v_6, v_345, v_348, v_353, v_356, v_359, v_362, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_267(+v_1001722: cps_provider_1_NodeResult, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_359: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_program_scope{}}, False{}, v_1001928 => template_body_program_scope, v_1001927 => +v_1001723 = template_unbox(BIR.Program, v_1001927); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{v_1001723}}, v_1001926 => +v_1001724 = template_unbox(cps_provider_1_Context, v_1001926); template_continuation_266(v_1001724, v_342, v_6, v_345, v_348, v_353, v_356, v_359, v_1001722, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}}

def template_continuation_268(+v_1001721: cps_provider_1_NodeResult, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_356: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout_fuel{v_342, "Pt", 1n}}, v_1001929 => +v_1001722 = template_unbox(cps_provider_1_NodeResult, v_1001929); template_continuation_267(v_1001722, v_342, v_6, v_345, v_348, v_353, v_356, v_1001721, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_269(+v_1001720: cps_provider_1_NodeResult, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_353: cps_provider_1_LayoutResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_342, "Er"}}, v_1001930 => +v_1001721 = template_unbox(cps_provider_1_NodeResult, v_1001930); template_continuation_268(v_1001721, v_342, v_6, v_345, v_348, v_353, v_1001720, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_270(+v_1001719: cps_provider_1_LayoutResult, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_348: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_342, "W32"}}, v_1001931 => +v_1001720 = template_unbox(cps_provider_1_NodeResult, v_1001931); template_continuation_269(v_1001720, v_342, v_6, v_345, v_348, v_1001719, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_271(+v_1001714: cps_provider_1_NodeResult, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_345: cps_provider_1_NodeResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  +v_1001716 = {"Box" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001936 => template_body_ref("U32", []), v_1001935 => +v_1001717 = template_unbox(BIR.Descriptor, v_1001935); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001716, [v_1001717]}}, False{}, v_1001934 => template_body_ref(v_1001716, [v_1001717]), v_1001933 => +v_1001718 = template_unbox(BIR.Descriptor, v_1001933); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_342 : cps_provider_1_Context}, v_1001718}}, v_1001932 => +v_1001719 = template_unbox(cps_provider_1_LayoutResult, v_1001932); template_continuation_270(v_1001719, v_342, v_6, v_345, v_1001714, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}}}

def template_continuation_272(+v_1001713: cps_provider_1_NodeResult, +v_342: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_342, "Box"}}, v_1001937 => +v_1001714 = template_unbox(cps_provider_1_NodeResult, v_1001937); template_continuation_271(v_1001714, v_342, v_6, v_1001713, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_273(+v_1001712: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32, v_338: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_1001712, "Pt"}}, v_1001938 => +v_1001713 = template_unbox(cps_provider_1_NodeResult, v_1001938); template_continuation_272(v_1001713, v_1001712, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_338)}

def template_continuation_274(+v_1001710: U32, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32, v_334: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_program_rows{}}, False{}, v_1001941 => template_body_program_rows, v_1001940 => +v_1001711 = template_unbox(BIR.Program, v_1001940); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{v_1001711}}, v_1001939 => +v_1001712 = template_unbox(cps_provider_1_Context, v_1001939); template_continuation_273(v_1001712, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_334, v_1001710)}}

def template_continuation_275(+v_1001709: U32, +v_314: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32, v_330: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{template_pure_check_args_failure(v_314)}}, False{}, v_1001943 => template_body_fail(template_pure_check_args_failure(v_314)), v_1001942 => +v_1001710 = template_unbox(U32, v_1001942); template_continuation_274(v_1001710, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_330, v_1001709)}

def template_continuation_276(+v_1001707: U32, +v_311: cps_provider_1_ArgsResult, +v_314: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32, v_326: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_args_pair{v_311}}, False{}, v_1001947 => template_body_check_args_pair(v_311), v_1001946 => +v_1001708 = template_unbox(Bool, v_1001946); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001708}}, False{}, v_1001945 => template_body_fail(v_1001708), v_1001944 => +v_1001709 = template_unbox(U32, v_1001944); template_continuation_275(v_1001709, v_314, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_326, v_1001707)}}

def template_continuation_277(+v_1001705: U32, +v_305: cps_provider_1_ArgsResult, +v_311: cps_provider_1_ArgsResult, +v_314: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32, v_322: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_args_first_is{v_305, "U32"}}, False{}, v_1001951 => template_body_args_first_is(v_305, "U32"), v_1001950 => +v_1001706 = template_unbox(Bool, v_1001950); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001706}}, False{}, v_1001949 => template_body_fail(v_1001706), v_1001948 => +v_1001707 = template_unbox(U32, v_1001948); template_continuation_276(v_1001707, v_311, v_314, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_322, v_1001705)}}

def template_continuation_278(+v_1001704: U32, +v_300: cps_provider_1_NormResult, +v_305: cps_provider_1_ArgsResult, +v_311: cps_provider_1_ArgsResult, +v_314: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32, v_318: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{template_pure_check_norm_failure(v_300)}}, False{}, v_1001953 => template_body_fail(template_pure_check_norm_failure(v_300)), v_1001952 => +v_1001705 = template_unbox(U32, v_1001952); template_continuation_277(v_1001705, v_305, v_311, v_314, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_318, v_1001704)}

def template_continuation_279(+v_1001702: U32, +v_291: cps_provider_1_NormResult, +v_297: cps_provider_1_NormResult, +v_300: cps_provider_1_NormResult, +v_305: cps_provider_1_ArgsResult, +v_311: cps_provider_1_ArgsResult, +v_314: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_norm_distinct{v_291, v_297}}, False{}, v_1001957 => template_body_check_norm_distinct(v_291, v_297), v_1001956 => +v_1001703 = template_unbox(Bool, v_1001956); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001703}}, False{}, v_1001955 => template_body_fail(v_1001703), v_1001954 => +v_1001704 = template_unbox(U32, v_1001954); template_continuation_278(v_1001704, v_300, v_305, v_311, v_314, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281, v_1001702)}}

def template_continuation_280(+v_1001700: cps_provider_1_ArgsResult, +v_285: cps_provider_1_NormResult, +v_291: cps_provider_1_NormResult, +v_297: cps_provider_1_NormResult, +v_300: cps_provider_1_NormResult, +v_305: cps_provider_1_ArgsResult, +v_311: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_norm_alias{v_285}}, False{}, v_1001961 => template_body_check_norm_alias(v_285), v_1001960 => +v_1001701 = template_unbox(Bool, v_1001960); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001701}}, False{}, v_1001959 => template_body_fail(v_1001701), v_1001958 => +v_1001702 = template_unbox(U32, v_1001958); template_continuation_279(v_1001702, v_291, v_297, v_300, v_305, v_311, v_1001700, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281)}}

def template_continuation_281(+v_1001699: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_285: cps_provider_1_NormResult, +v_291: cps_provider_1_NormResult, +v_297: cps_provider_1_NormResult, +v_300: cps_provider_1_NormResult, +v_305: cps_provider_1_ArgsResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_args{v_6, BIR.DescriptorFailure{"the checked type expression is a reducer failure"}}}, v_1001962 => +v_1001700 = template_unbox(cps_provider_1_ArgsResult, v_1001962); template_continuation_280(v_1001700, v_285, v_291, v_297, v_300, v_305, v_1001699, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281)}

def template_continuation_282(+v_1001693: cps_provider_1_ArgsResult, +v_6: cps_provider_1_Context, +v_285: cps_provider_1_NormResult, +v_291: cps_provider_1_NormResult, +v_297: cps_provider_1_NormResult, +v_300: cps_provider_1_NormResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  +v_1001695 = {"Pair" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001969 => template_body_ref("U32", []), v_1001968 => +v_1001696 = template_unbox(BIR.Descriptor, v_1001968); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1001967 => template_body_ref("Nat", []), v_1001966 => +v_1001697 = template_unbox(BIR.Descriptor, v_1001966); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001695, [v_1001696, v_1001697]}}, False{}, v_1001965 => template_body_ref(v_1001695, [v_1001696, v_1001697]), v_1001964 => +v_1001698 = template_unbox(BIR.Descriptor, v_1001964); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_args{{v_6 : cps_provider_1_Context}, v_1001698}}, v_1001963 => +v_1001699 = template_unbox(cps_provider_1_ArgsResult, v_1001963); template_continuation_281(v_1001699, v_6, v_285, v_291, v_297, v_300, v_1001693, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281)}}}}

def template_continuation_283(+v_1001688: cps_provider_1_NormResult, +v_6: cps_provider_1_Context, +v_285: cps_provider_1_NormResult, +v_291: cps_provider_1_NormResult, +v_297: cps_provider_1_NormResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  +v_1001690 = {"Array" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001974 => template_body_ref("U32", []), v_1001973 => +v_1001691 = template_unbox(BIR.Descriptor, v_1001973); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001690, [v_1001691]}}, False{}, v_1001972 => template_body_ref(v_1001690, [v_1001691]), v_1001971 => +v_1001692 = template_unbox(BIR.Descriptor, v_1001971); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_args{{v_6 : cps_provider_1_Context}, v_1001692}}, v_1001970 => +v_1001693 = template_unbox(cps_provider_1_ArgsResult, v_1001970); template_continuation_282(v_1001693, v_6, v_285, v_291, v_297, v_1001688, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281)}}}

def template_continuation_284(+v_1001687: cps_provider_1_NormResult, +v_6: cps_provider_1_Context, +v_285: cps_provider_1_NormResult, +v_291: cps_provider_1_NormResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_norm{v_6, BIR.DescriptorFailure{"the checked type expression is a reducer failure"}}}, v_1001975 => +v_1001688 = template_unbox(cps_provider_1_NormResult, v_1001975); template_continuation_283(v_1001688, v_6, v_285, v_291, v_1001687, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281)}

def template_continuation_285(+v_1001681: cps_provider_1_NormResult, +v_6: cps_provider_1_Context, +v_285: cps_provider_1_NormResult, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  +v_1001683 = {"Pair" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1001982 => template_body_ref("Nat", []), v_1001981 => +v_1001684 = template_unbox(BIR.Descriptor, v_1001981); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001980 => template_body_ref("U32", []), v_1001979 => +v_1001685 = template_unbox(BIR.Descriptor, v_1001979); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001683, [v_1001684, v_1001685]}}, False{}, v_1001978 => template_body_ref(v_1001683, [v_1001684, v_1001685]), v_1001977 => +v_1001686 = template_unbox(BIR.Descriptor, v_1001977); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_norm{{v_6 : cps_provider_1_Context}, v_1001686}}, v_1001976 => +v_1001687 = template_unbox(cps_provider_1_NormResult, v_1001976); template_continuation_284(v_1001687, v_6, v_285, v_1001681, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281)}}}}

def template_continuation_286(+v_1001675: cps_provider_1_NormResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32, v_281: U32) -> TemplateProgress<ClaySmoke>:
  +v_1001677 = {"Pair" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1001989 => template_body_ref("U32", []), v_1001988 => +v_1001678 = template_unbox(BIR.Descriptor, v_1001988); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1001987 => template_body_ref("Nat", []), v_1001986 => +v_1001679 = template_unbox(BIR.Descriptor, v_1001986); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001677, [v_1001678, v_1001679]}}, False{}, v_1001985 => template_body_ref(v_1001677, [v_1001678, v_1001679]), v_1001984 => +v_1001680 = template_unbox(BIR.Descriptor, v_1001984); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_norm{{v_6 : cps_provider_1_Context}, v_1001680}}, v_1001983 => +v_1001681 = template_unbox(cps_provider_1_NormResult, v_1001983); template_continuation_285(v_1001681, v_6, v_1001675, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_281)}}}}

def template_continuation_287(+v_1001672: U32, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32, v_277: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"MyNat", []}}, False{}, v_1001992 => template_body_ref("MyNat", []), v_1001991 => +v_1001674 = template_unbox(BIR.Descriptor, v_1001991); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_norm{{v_6 : cps_provider_1_Context}, v_1001674}}, v_1001990 => +v_1001675 = template_unbox(cps_provider_1_NormResult, v_1001990); template_continuation_286(v_1001675, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_277, v_1001672)}}

def template_continuation_288(+v_1001671: U32, +v_249: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32, v_273: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{template_pure_check_long_arm(v_249)}}, False{}, v_1001994 => template_body_fail(template_pure_check_long_arm(v_249)), v_1001993 => +v_1001672 = template_unbox(U32, v_1001993); template_continuation_287(v_1001672, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_273, v_1001671)}

def template_continuation_289(+v_1001669: U32, +v_245: cps_provider_1_NodeResult, +v_249: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32, v_269: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_wide{v_245}}, False{}, v_1001998 => template_body_check_wide(v_245), v_1001997 => +v_1001670 = template_unbox(Bool, v_1001997); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001670}}, False{}, v_1001996 => template_body_fail(v_1001670), v_1001995 => +v_1001671 = template_unbox(U32, v_1001995); template_continuation_288(v_1001671, v_249, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_269, v_1001669)}}

def template_continuation_290(+v_1001667: U32, +v_245: cps_provider_1_NodeResult, +v_249: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32, v_265: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_pad{300n, 512n}}, False{}, v_1002002 => template_body_check_pad(300n, 512n), v_1002001 => +v_1001668 = template_unbox(Bool, v_1002001); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001668}}, False{}, v_1002000 => template_body_fail(v_1001668), v_1001999 => +v_1001669 = template_unbox(U32, v_1001999); template_continuation_289(v_1001669, v_245, v_249, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_265, v_1001667)}}

def template_continuation_291(+v_1001665: U32, +v_245: cps_provider_1_NodeResult, +v_249: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32, v_261: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_pad{256n, 256n}}, False{}, v_1002006 => template_body_check_pad(256n, 256n), v_1002005 => +v_1001666 = template_unbox(Bool, v_1002005); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001666}}, False{}, v_1002004 => template_body_fail(v_1001666), v_1002003 => +v_1001667 = template_unbox(U32, v_1002003); template_continuation_290(v_1001667, v_245, v_249, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_261, v_1001665)}}

def template_continuation_292(+v_1001663: U32, +v_245: cps_provider_1_NodeResult, +v_249: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32, v_257: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_pad{248n, 256n}}, False{}, v_1002010 => template_body_check_pad(248n, 256n), v_1002009 => +v_1001664 = template_unbox(Bool, v_1002009); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001664}}, False{}, v_1002008 => template_body_fail(v_1001664), v_1002007 => +v_1001665 = template_unbox(U32, v_1002007); template_continuation_291(v_1001665, v_245, v_249, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_257, v_1001663)}}

def template_continuation_293(+v_1001661: U32, +v_245: cps_provider_1_NodeResult, +v_249: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32, v_253: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_pad{247n, 247n}}, False{}, v_1002014 => template_body_check_pad(247n, 247n), v_1002013 => +v_1001662 = template_unbox(Bool, v_1002013); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001662}}, False{}, v_1002012 => template_body_fail(v_1001662), v_1002011 => +v_1001663 = template_unbox(U32, v_1002011); template_continuation_292(v_1001663, v_245, v_249, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_253, v_1001661)}}

def template_continuation_294(+v_1001659: U32, +v_245: cps_provider_1_NodeResult, +v_249: Maybe<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_pow2{}}, False{}, v_1002018 => template_body_check_pow2, v_1002017 => +v_1001660 = template_unbox(Bool, v_1002017); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001660}}, False{}, v_1002016 => template_body_fail(v_1001660), v_1002015 => +v_1001661 = template_unbox(U32, v_1002015); template_continuation_293(v_1001661, v_245, v_249, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238, v_1001659)}}

def template_continuation_295(+v_1001657: Maybe<&2, BIR.DescriptorArm>, +v_245: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_check_ceil{}}, False{}, v_1002022 => template_body_check_ceil, v_1002021 => +v_1001658 = template_unbox(Bool, v_1002021); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001658}}, False{}, v_1002020 => template_body_fail(v_1001658), v_1002019 => +v_1001659 = template_unbox(U32, v_1002019); template_continuation_294(v_1001659, v_245, v_1001657, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238)}}

def template_continuation_296(+v_1001654: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_mk_miss{1500n}}, False{}, v_1002025 => template_body_mk_miss(1500n), v_1002024 => +v_1001656 = template_unbox(List<&2, BIR.DescriptorArm>, v_1002024); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_in{{"hit" : String}, v_1001656}}, v_1002023 => +v_1001657 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1002023); template_continuation_295(v_1001657, v_1001654, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238)}}

def template_continuation_297(+v_1001653: cps_provider_1_Context, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32, +v_238: U32) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_1001653, "Wide"}}, v_1002026 => +v_1001654 = template_unbox(cps_provider_1_NodeResult, v_1002026); template_continuation_296(v_1001654, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_238)}

def template_continuation_298(+v_1001651: U32, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32, +v_234: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_wide_program{}}, False{}, v_1002029 => template_body_wide_program, v_1002028 => +v_1001652 = template_unbox(BIR.Program, v_1002028); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{v_1001652}}, v_1002027 => +v_1001653 = template_unbox(cps_provider_1_Context, v_1002027); template_continuation_297(v_1001653, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_234, v_1001651)}}

def template_continuation_299(+v_1001649: U32, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32, +v_230: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_abstract_cell{v_61}}, False{}, v_1002033 => template_body_check_abstract_cell(v_61), v_1002032 => +v_1001650 = template_unbox(Bool, v_1002032); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001650}}, False{}, v_1002031 => template_body_fail(v_1001650), v_1002030 => +v_1001651 = template_unbox(U32, v_1002030); template_continuation_298(v_1001651, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_230, v_1001649)}}

def template_continuation_300(+v_1001648: U32, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32, +v_226: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{template_pure_check_fields_failure(v_126)}}, False{}, v_1002035 => template_body_fail(template_pure_check_fields_failure(v_126)), v_1002034 => +v_1001649 = template_unbox(U32, v_1002034); template_continuation_299(v_1001649, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_226, v_1001648)}

def template_continuation_301(+v_1001646: U32, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32, +v_222: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_pair_fields{v_123}}, False{}, v_1002039 => template_body_check_pair_fields(v_123), v_1002038 => +v_1001647 = template_unbox(Bool, v_1002038); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001647}}, False{}, v_1002037 => template_body_fail(v_1001647), v_1002036 => +v_1001648 = template_unbox(U32, v_1002036); template_continuation_300(v_1001648, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_222, v_1001646)}}

def template_continuation_302(+v_1001644: U32, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32, +v_218: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_box_fields{v_117}}, False{}, v_1002043 => template_body_check_box_fields(v_117), v_1002042 => +v_1001645 = template_unbox(Bool, v_1002042); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001645}}, False{}, v_1002041 => template_body_fail(v_1001645), v_1002040 => +v_1001646 = template_unbox(U32, v_1002040); template_continuation_301(v_1001646, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_218, v_1001644)}}

def template_continuation_303(+v_1001642: U32, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32, +v_214: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_head_failure{v_112}}, False{}, v_1002047 => template_body_check_head_failure(v_112), v_1002046 => +v_1001643 = template_unbox(Bool, v_1002046); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001643}}, False{}, v_1002045 => template_body_fail(v_1001643), v_1002044 => +v_1001644 = template_unbox(U32, v_1002044); template_continuation_302(v_1001644, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_214, v_1001642)}}

def template_continuation_304(+v_1001640: U32, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32, +v_210: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_head_open{v_109}}, False{}, v_1002051 => template_body_check_head_open(v_109), v_1002050 => +v_1001641 = template_unbox(Bool, v_1002050); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001641}}, False{}, v_1002049 => template_body_fail(v_1001641), v_1002048 => +v_1001642 = template_unbox(U32, v_1002048); template_continuation_303(v_1001642, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_210, v_1001640)}}

def template_continuation_305(+v_1001638: U32, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32, +v_206: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_head_plain{v_105}}, False{}, v_1002055 => template_body_check_head_plain(v_105), v_1002054 => +v_1001639 = template_unbox(Bool, v_1002054); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001639}}, False{}, v_1002053 => template_body_fail(v_1001639), v_1002052 => +v_1001640 = template_unbox(U32, v_1002052); template_continuation_304(v_1001640, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_206, v_1001638)}}

def template_continuation_306(+v_1001636: U32, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32, +v_202: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_head_array{v_101}}, False{}, v_1002059 => template_body_check_head_array(v_101), v_1002058 => +v_1001637 = template_unbox(Bool, v_1002058); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001637}}, False{}, v_1002057 => template_body_fail(v_1001637), v_1002056 => +v_1001638 = template_unbox(U32, v_1002056); template_continuation_305(v_1001638, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_202, v_1001636)}}

def template_continuation_307(+v_1001634: U32, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32, +v_198: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_head_nat_alias{v_96}}, False{}, v_1002063 => template_body_check_head_nat_alias(v_96), v_1002062 => +v_1001635 = template_unbox(Bool, v_1002062); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001635}}, False{}, v_1002061 => template_body_fail(v_1001635), v_1002060 => +v_1001636 = template_unbox(U32, v_1002060); template_continuation_306(v_1001636, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_198, v_1001634)}}

def template_continuation_308(+v_1001632: U32, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32, +v_194: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_fill{v_88, v_92, v_76}}, False{}, v_1002067 => template_body_check_fill(v_88, v_92, v_76), v_1002066 => +v_1001633 = template_unbox(Bool, v_1002066); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001633}}, False{}, v_1002065 => template_body_fail(v_1001633), v_1002064 => +v_1001634 = template_unbox(U32, v_1002064); template_continuation_307(v_1001634, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_194, v_1001632)}}

def template_continuation_309(+v_1001630: U32, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32, +v_190: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_fill{v_80, v_84, v_20}}, False{}, v_1002071 => template_body_check_fill(v_80, v_84, v_20), v_1002070 => +v_1001631 = template_unbox(Bool, v_1002070); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001631}}, False{}, v_1002069 => template_body_fail(v_1001631), v_1002068 => +v_1001632 = template_unbox(U32, v_1002068); template_continuation_308(v_1001632, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_190, v_1001630)}}

def template_continuation_310(+v_1001628: U32, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32, +v_186: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_failure{v_72}}, False{}, v_1002075 => template_body_check_failure(v_72), v_1002074 => +v_1001629 = template_unbox(Bool, v_1002074); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001629}}, False{}, v_1002073 => template_body_fail(v_1001629), v_1002072 => +v_1001630 = template_unbox(U32, v_1002072); template_continuation_309(v_1001630, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_186, v_1001628)}}

def template_continuation_311(+v_1001626: U32, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32, +v_182: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_open_box{v_69}}, False{}, v_1002079 => template_body_check_open_box(v_69), v_1002078 => +v_1001627 = template_unbox(Bool, v_1002078); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001627}}, False{}, v_1002077 => template_body_fail(v_1001627), v_1002076 => +v_1001628 = template_unbox(U32, v_1002076); template_continuation_310(v_1001628, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_182, v_1001626)}}

def template_continuation_312(+v_1001624: U32, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32, +v_178: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_recursive{v_65}}, False{}, v_1002083 => template_body_check_recursive(v_65), v_1002082 => +v_1001625 = template_unbox(Bool, v_1002082); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001625}}, False{}, v_1002081 => template_body_fail(v_1001625), v_1002080 => +v_1001626 = template_unbox(U32, v_1002080); template_continuation_311(v_1001626, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_178, v_1001624)}}

def template_continuation_313(+v_1001622: U32, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32, +v_174: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_open_cell{v_57}}, False{}, v_1002087 => template_body_check_open_cell(v_57), v_1002086 => +v_1001623 = template_unbox(Bool, v_1002086); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001623}}, False{}, v_1002085 => template_body_fail(v_1001623), v_1002084 => +v_1001624 = template_unbox(U32, v_1002084); template_continuation_312(v_1001624, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_174, v_1001622)}}

def template_continuation_314(+v_1001620: U32, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32, +v_170: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_seg_cell{v_53}}, False{}, v_1002091 => template_body_check_seg_cell(v_53), v_1002090 => +v_1001621 = template_unbox(Bool, v_1002090); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001621}}, False{}, v_1002089 => template_body_fail(v_1001621), v_1002088 => +v_1001622 = template_unbox(U32, v_1002088); template_continuation_313(v_1001622, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_170, v_1001620)}}

def template_continuation_315(+v_1001618: U32, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32, +v_166: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_pt_cell{v_49}}, False{}, v_1002095 => template_body_check_pt_cell(v_49), v_1002094 => +v_1001619 = template_unbox(Bool, v_1002094); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001619}}, False{}, v_1002093 => template_body_fail(v_1001619), v_1002092 => +v_1001620 = template_unbox(U32, v_1002092); template_continuation_314(v_1001620, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_166, v_1001618)}}

def template_continuation_316(+v_1001616: U32, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32, +v_162: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_nat_cell{v_45}}, False{}, v_1002099 => template_body_check_nat_cell(v_45), v_1002098 => +v_1001617 = template_unbox(Bool, v_1002098); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001617}}, False{}, v_1002097 => template_body_fail(v_1001617), v_1002096 => +v_1001618 = template_unbox(U32, v_1002096); template_continuation_315(v_1001618, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_162, v_1001616)}}

def template_continuation_317(+v_1001614: U32, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32, +v_158: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_u32_cell{v_41}}, False{}, v_1002103 => template_body_check_u32_cell(v_41), v_1002102 => +v_1001615 = template_unbox(Bool, v_1002102); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001615}}, False{}, v_1002101 => template_body_fail(v_1001615), v_1002100 => +v_1001616 = template_unbox(U32, v_1002100); template_continuation_316(v_1001616, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_158, v_1001614)}}

def template_continuation_318(+v_1001612: U32, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32, +v_154: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_box_value{v_37}}, False{}, v_1002107 => template_body_check_box_value(v_37), v_1002106 => +v_1001613 = template_unbox(Bool, v_1002106); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001613}}, False{}, v_1002105 => template_body_fail(v_1001613), v_1002104 => +v_1001614 = template_unbox(U32, v_1002104); template_continuation_317(v_1001614, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_154, v_1001612)}}

def template_continuation_319(+v_1001610: U32, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32, +v_150: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_box_declared_node{v_32}}, False{}, v_1002111 => template_body_check_box_declared_node(v_32), v_1002110 => +v_1001611 = template_unbox(Bool, v_1002110); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001611}}, False{}, v_1002109 => template_body_fail(v_1001611), v_1002108 => +v_1001612 = template_unbox(U32, v_1002108); template_continuation_318(v_1001612, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_150, v_1001610)}}

def template_continuation_320(+v_1001608: U32, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32, +v_146: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_empty_packed{v_29}}, False{}, v_1002115 => template_body_check_empty_packed(v_29), v_1002114 => +v_1001609 = template_unbox(Bool, v_1002114); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001609}}, False{}, v_1002113 => template_body_fail(v_1001609), v_1002112 => +v_1001610 = template_unbox(U32, v_1002112); template_continuation_319(v_1001610, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_146, v_1001608)}}

def template_continuation_321(+v_1001606: U32, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32, +v_142: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_nat_not_packed{v_26}}, False{}, v_1002119 => template_body_check_nat_not_packed(v_26), v_1002118 => +v_1001607 = template_unbox(Bool, v_1002118); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001607}}, False{}, v_1002117 => template_body_fail(v_1001607), v_1002116 => +v_1001608 = template_unbox(U32, v_1002116); template_continuation_320(v_1001608, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_142, v_1001606)}}

def template_continuation_322(+v_1001604: U32, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_20: cps_provider_1_LayoutResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32, +v_138: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_w32_packed{v_23}}, False{}, v_1002123 => template_body_check_w32_packed(v_23), v_1002122 => +v_1001605 = template_unbox(Bool, v_1002122); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001605}}, False{}, v_1002121 => template_body_fail(v_1001605), v_1002120 => +v_1001606 = template_unbox(U32, v_1002120); template_continuation_321(v_1001606, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_138, v_1001604)}}

def template_continuation_323(+v_1001602: U32, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32, +v_134: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_opt_tag{v_20}}, False{}, v_1002127 => template_body_check_opt_tag(v_20), v_1002126 => +v_1001603 = template_unbox(Bool, v_1002126); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001603}}, False{}, v_1002125 => template_body_fail(v_1001603), v_1002124 => +v_1001604 = template_unbox(U32, v_1002124); template_continuation_322(v_1001604, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_20, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_134, v_1001602)}}

def template_continuation_324(+v_1001600: U32, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_130: U32) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_seg_node{v_16}}, False{}, v_1002131 => template_body_check_seg_node(v_16), v_1002130 => +v_1001601 = template_unbox(Bool, v_1002130); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001601}}, False{}, v_1002129 => template_body_fail(v_1001601), v_1002128 => +v_1001602 = template_unbox(U32, v_1002128); template_continuation_323(v_1001602, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_130, v_1001600)}}

def template_continuation_325(+v_1001598: U32, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_126: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_pt_node{v_13}}, False{}, v_1002135 => template_body_check_pt_node(v_13), v_1002134 => +v_1001599 = template_unbox(Bool, v_1002134); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001599}}, False{}, v_1002133 => template_body_fail(v_1001599), v_1002132 => +v_1001600 = template_unbox(U32, v_1002132); template_continuation_324(v_1001600, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_126, v_61, v_6, v_1001598)}}

def template_continuation_326(+v_1001596: cps_provider_1_FieldsResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_123: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult, +v_6: cps_provider_1_Context) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_check_pt_value{v_10}}, False{}, v_1002139 => template_body_check_pt_value(v_10), v_1002138 => +v_1001597 = template_unbox(Bool, v_1002138); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fail{v_1001597}}, False{}, v_1002137 => template_body_fail(v_1001597), v_1002136 => +v_1001598 = template_unbox(U32, v_1002136); template_continuation_325(v_1001598, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_123, v_1001596, v_61, v_6)}}

def template_continuation_327(+v_1001595: cps_provider_1_FieldsResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_117: cps_provider_1_FieldsResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_arm_fields{v_6, "Box", BIR.DescriptorFailure{"the checked type expression is a reducer failure"}}}, v_1002140 => +v_1001596 = template_unbox(cps_provider_1_FieldsResult, v_1002140); template_continuation_326(v_1001596, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_117, v_1001595, v_61, v_6)}

def template_continuation_328(+v_1001588: cps_provider_1_FieldsResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_112: cps_provider_1_HeadResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  +v_1001591 = {"Pair" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1002147 => template_body_ref("U32", []), v_1002146 => +v_1001592 = template_unbox(BIR.Descriptor, v_1002146); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1002145 => template_body_ref("Nat", []), v_1002144 => +v_1001593 = template_unbox(BIR.Descriptor, v_1002144); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001591, [v_1001592, v_1001593]}}, False{}, v_1002143 => template_body_ref(v_1001591, [v_1001592, v_1001593]), v_1002142 => +v_1001594 = template_unbox(BIR.Descriptor, v_1002142); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_arm_fields{{v_6 : cps_provider_1_Context}, {"Pair" : String}, v_1001594}}, v_1002141 => +v_1001595 = template_unbox(cps_provider_1_FieldsResult, v_1002141); template_continuation_327(v_1001595, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_112, v_1001588, v_61)}}}}

def template_continuation_329(+v_1001582: cps_provider_1_HeadResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_109: cps_provider_1_HeadResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  +v_1001585 = {"Box" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1002152 => template_body_ref("U32", []), v_1002151 => +v_1001586 = template_unbox(BIR.Descriptor, v_1002151); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001585, [v_1001586]}}, False{}, v_1002150 => template_body_ref(v_1001585, [v_1001586]), v_1002149 => +v_1001587 = template_unbox(BIR.Descriptor, v_1002149); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_arm_fields{{v_6 : cps_provider_1_Context}, {"Box" : String}, v_1001587}}, v_1002148 => +v_1001588 = template_unbox(cps_provider_1_FieldsResult, v_1002148); template_continuation_328(v_1001588, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_105, v_109, v_1001582, v_61)}}}

def template_continuation_330(+v_1001581: cps_provider_1_HeadResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_105: cps_provider_1_HeadResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{v_6, BIR.DescriptorFailure{"the checked type expression is a reducer failure"}}}, v_1002153 => +v_1001582 = template_unbox(cps_provider_1_HeadResult, v_1002153); template_continuation_329(v_1001582, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_105, v_1001581, v_61)}

def template_continuation_331(+v_1001578: cps_provider_1_HeadResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_101: cps_provider_1_HeadResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Chan", []}}, False{}, v_1002156 => template_body_ref("Chan", []), v_1002155 => +v_1001580 = template_unbox(BIR.Descriptor, v_1002155); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{{v_6 : cps_provider_1_Context}, v_1001580}}, v_1002154 => +v_1001581 = template_unbox(cps_provider_1_HeadResult, v_1002154); template_continuation_330(v_1001581, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_101, v_1001578, v_61)}}

def template_continuation_332(+v_1001575: cps_provider_1_HeadResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_96: cps_provider_1_HeadResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Pt", []}}, False{}, v_1002159 => template_body_ref("Pt", []), v_1002158 => +v_1001577 = template_unbox(BIR.Descriptor, v_1002158); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{{v_6 : cps_provider_1_Context}, v_1001577}}, v_1002157 => +v_1001578 = template_unbox(cps_provider_1_HeadResult, v_1002157); template_continuation_331(v_1001578, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_96, v_1001575, v_61)}}

def template_continuation_333(+v_1001570: cps_provider_1_HeadResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_92: cps_provider_1_UnfillResult, +v_76: cps_provider_1_LayoutResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  +v_1001572 = {"Array" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1002164 => template_body_ref("U32", []), v_1002163 => +v_1001573 = template_unbox(BIR.Descriptor, v_1002163); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001572, [v_1001573]}}, False{}, v_1002162 => template_body_ref(v_1001572, [v_1001573]), v_1002161 => +v_1001574 = template_unbox(BIR.Descriptor, v_1002161); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{{v_6 : cps_provider_1_Context}, v_1001574}}, v_1002160 => +v_1001575 = template_unbox(cps_provider_1_HeadResult, v_1002160); template_continuation_332(v_1001575, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_92, v_76, v_1001570, v_61)}}}

def template_continuation_334(+v_1001567: cps_provider_1_UnfillResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_88: cps_provider_1_FillResult, +v_76: cps_provider_1_LayoutResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"MyNat", []}}, False{}, v_1002167 => template_body_ref("MyNat", []), v_1002166 => +v_1001569 = template_unbox(BIR.Descriptor, v_1002166); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_native{{v_6 : cps_provider_1_Context}, v_1001569}}, v_1002165 => +v_1001570 = template_unbox(cps_provider_1_HeadResult, v_1002165); template_continuation_333(v_1001570, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_88, v_1001567, v_76, v_61)}}

def template_continuation_335(+v_1001564: cps_provider_1_FillResult, +v_6: cps_provider_1_Context, +v_76: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_84: cps_provider_1_UnfillResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_extract{v_76}}, False{}, v_1002170 => template_body_extract(v_76), v_1002169 => +v_1001566 = template_unbox(cps_provider_1_Layout, v_1002169); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_unfill{{v_6 : cps_provider_1_Context}, v_1001566}}, v_1002168 => +v_1001567 = template_unbox(cps_provider_1_UnfillResult, v_1002168); template_continuation_334(v_1001567, v_6, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_84, v_1001564, v_76, v_61)}}

def template_continuation_336(+v_1001561: cps_provider_1_UnfillResult, +v_6: cps_provider_1_Context, +v_76: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_20: cps_provider_1_LayoutResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_80: cps_provider_1_FillResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_extract{v_76}}, False{}, v_1002173 => template_body_extract(v_76), v_1002172 => +v_1001563 = template_unbox(cps_provider_1_Layout, v_1002172); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_fill{{v_6 : cps_provider_1_Context}, v_1001563}}, v_1002171 => +v_1001564 = template_unbox(cps_provider_1_FillResult, v_1002171); template_continuation_335(v_1001564, v_6, v_76, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_80, v_1001561, v_61)}}

def template_continuation_337(+v_1001558: cps_provider_1_FillResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_76: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_extract{v_20}}, False{}, v_1002176 => template_body_extract(v_20), v_1002175 => +v_1001560 = template_unbox(cps_provider_1_Layout, v_1002175); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_unfill{{v_6 : cps_provider_1_Context}, v_1001560}}, v_1002174 => +v_1001561 = template_unbox(cps_provider_1_UnfillResult, v_1002174); template_continuation_336(v_1001561, v_6, v_76, v_10, v_13, v_16, v_20, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_1001558, v_61)}}

def template_continuation_338(+v_1001555: cps_provider_1_LayoutResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_72: cps_provider_1_LayoutResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_extract{v_20}}, False{}, v_1002179 => template_body_extract(v_20), v_1002178 => +v_1001557 = template_unbox(cps_provider_1_Layout, v_1002178); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_fill{{v_6 : cps_provider_1_Context}, v_1001557}}, v_1002177 => +v_1001558 = template_unbox(cps_provider_1_FillResult, v_1002177); template_continuation_337(v_1001558, v_6, v_20, v_1001555, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_72, v_61)}}

def template_continuation_339(+v_1001552: cps_provider_1_LayoutResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_69: cps_provider_1_LayoutResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Seg", []}}, False{}, v_1002182 => template_body_ref("Seg", []), v_1002181 => +v_1001554 = template_unbox(BIR.Descriptor, v_1002181); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_6 : cps_provider_1_Context}, v_1001554}}, v_1002180 => +v_1001555 = template_unbox(cps_provider_1_LayoutResult, v_1002180); template_continuation_338(v_1001555, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_69, v_1001552, v_61)}}

def template_continuation_340(+v_1001551: cps_provider_1_LayoutResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_65: cps_provider_1_LayoutResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{v_6, BIR.DescriptorFailure{"the checked type expression is a reducer failure"}}}, v_1002183 => +v_1001552 = template_unbox(cps_provider_1_LayoutResult, v_1002183); template_continuation_339(v_1001552, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_65, v_1001551, v_61)}

def template_continuation_341(+v_1001548: cps_provider_1_LayoutResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult, +v_61: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Chan", []}}, False{}, v_1002186 => template_body_ref("Chan", []), v_1002185 => +v_1001550 = template_unbox(BIR.Descriptor, v_1002185); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_6 : cps_provider_1_Context}, v_1001550}}, v_1002184 => +v_1001551 = template_unbox(cps_provider_1_LayoutResult, v_1002184); template_continuation_340(v_1001551, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_1001548, v_61)}}

def template_continuation_342(+v_1001545: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult, +v_57: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"ListT", []}}, False{}, v_1002189 => template_body_ref("ListT", []), v_1002188 => +v_1001547 = template_unbox(BIR.Descriptor, v_1002188); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_6 : cps_provider_1_Context}, v_1001547}}, v_1002187 => +v_1001548 = template_unbox(cps_provider_1_LayoutResult, v_1002187); template_continuation_341(v_1001548, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_57, v_1001545)}}

def template_continuation_343(+v_1001542: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult, +v_53: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Chan", []}}, False{}, v_1002192 => template_body_ref("Chan", []), v_1002191 => +v_1001544 = template_unbox(BIR.Descriptor, v_1002191); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_array_cell{{v_6 : cps_provider_1_Context}, v_1001544}}, v_1002190 => +v_1001545 = template_unbox(cps_provider_1_CellResult, v_1002190); template_continuation_342(v_1001545, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_53, v_1001542)}}

def template_continuation_344(+v_1001539: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult, +v_49: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_par{0n}}, False{}, v_1002195 => template_body_par(0n), v_1002194 => +v_1001541 = template_unbox(BIR.Descriptor, v_1002194); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_array_cell{{v_6 : cps_provider_1_Context}, v_1001541}}, v_1002193 => +v_1001542 = template_unbox(cps_provider_1_CellResult, v_1002193); template_continuation_343(v_1001542, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_49, v_1001539)}}

def template_continuation_345(+v_1001536: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult, +v_45: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Seg", []}}, False{}, v_1002198 => template_body_ref("Seg", []), v_1002197 => +v_1001538 = template_unbox(BIR.Descriptor, v_1002197); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_array_cell{{v_6 : cps_provider_1_Context}, v_1001538}}, v_1002196 => +v_1001539 = template_unbox(cps_provider_1_CellResult, v_1002196); template_continuation_344(v_1001539, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_45, v_1001536)}}

def template_continuation_346(+v_1001533: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult, +v_41: cps_provider_1_CellResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Pt", []}}, False{}, v_1002201 => template_body_ref("Pt", []), v_1002200 => +v_1001535 = template_unbox(BIR.Descriptor, v_1002200); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_array_cell{{v_6 : cps_provider_1_Context}, v_1001535}}, v_1002199 => +v_1001536 = template_unbox(cps_provider_1_CellResult, v_1002199); template_continuation_345(v_1001536, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_41, v_1001533)}}

def template_continuation_347(+v_1001530: cps_provider_1_CellResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult, +v_37: cps_provider_1_LayoutResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Nat", []}}, False{}, v_1002204 => template_body_ref("Nat", []), v_1002203 => +v_1001532 = template_unbox(BIR.Descriptor, v_1002203); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_array_cell{{v_6 : cps_provider_1_Context}, v_1001532}}, v_1002202 => +v_1001533 = template_unbox(cps_provider_1_CellResult, v_1002202); template_continuation_346(v_1001533, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_37, v_1001530)}}

def template_continuation_348(+v_1001527: cps_provider_1_LayoutResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult, +v_32: cps_provider_1_NodeResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1002207 => template_body_ref("U32", []), v_1002206 => +v_1001529 = template_unbox(BIR.Descriptor, v_1002206); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_array_cell{{v_6 : cps_provider_1_Context}, v_1001529}}, v_1002205 => +v_1001530 = template_unbox(cps_provider_1_CellResult, v_1002205); template_continuation_347(v_1001530, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_32, v_1001527)}}

def template_continuation_349(+v_1001522: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult, +v_29: cps_provider_1_NodeResult) -> TemplateProgress<ClaySmoke>:
  +v_1001524 = {"Box" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1002212 => template_body_ref("U32", []), v_1002211 => +v_1001525 = template_unbox(BIR.Descriptor, v_1002211); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1001524, [v_1001525]}}, False{}, v_1002210 => template_body_ref(v_1001524, [v_1001525]), v_1002209 => +v_1001526 = template_unbox(BIR.Descriptor, v_1002209); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_6 : cps_provider_1_Context}, v_1001526}}, v_1002208 => +v_1001527 = template_unbox(cps_provider_1_LayoutResult, v_1002208); template_continuation_348(v_1001527, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_29, v_1001522)}}}

def template_continuation_350(+v_1001521: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult, +v_26: cps_provider_1_NodeResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_6, "Box"}}, v_1002213 => +v_1001522 = template_unbox(cps_provider_1_NodeResult, v_1002213); template_continuation_349(v_1001522, v_6, v_20, v_10, v_13, v_16, v_23, v_26, v_1001521)}

def template_continuation_351(+v_1001520: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult, +v_23: cps_provider_1_NodeResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_6, "Empty0"}}, v_1002214 => +v_1001521 = template_unbox(cps_provider_1_NodeResult, v_1002214); template_continuation_350(v_1001521, v_6, v_20, v_10, v_13, v_16, v_23, v_1001520)}

def template_continuation_352(+v_1001519: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_20: cps_provider_1_LayoutResult, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_6, "OneNat"}}, v_1002215 => +v_1001520 = template_unbox(cps_provider_1_NodeResult, v_1002215); template_continuation_351(v_1001520, v_6, v_20, v_10, v_13, v_16, v_1001519)}

def template_continuation_353(+v_1001518: cps_provider_1_LayoutResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult, +v_16: cps_provider_1_NodeResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_6, "W32"}}, v_1002216 => +v_1001519 = template_unbox(cps_provider_1_NodeResult, v_1002216); template_continuation_352(v_1001519, v_6, v_1001518, v_10, v_13, v_16)}

def template_continuation_354(+v_1001515: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult, +v_13: cps_provider_1_NodeResult) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Opt", []}}, False{}, v_1002219 => template_body_ref("Opt", []), v_1002218 => +v_1001517 = template_unbox(BIR.Descriptor, v_1002218); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_6 : cps_provider_1_Context}, v_1001517}}, v_1002217 => +v_1001518 = template_unbox(cps_provider_1_LayoutResult, v_1002217); template_continuation_353(v_1001518, v_6, v_10, v_13, v_1001515)}}

def template_continuation_355(+v_1001514: cps_provider_1_NodeResult, +v_6: cps_provider_1_Context, +v_10: cps_provider_1_LayoutResult) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_6, "Seg"}}, v_1002220 => +v_1001515 = template_unbox(cps_provider_1_NodeResult, v_1002220); template_continuation_354(v_1001515, v_6, v_10, v_1001514)}

def template_continuation_356(+v_1001513: cps_provider_1_LayoutResult, +v_6: cps_provider_1_Context) -> TemplateProgress<ClaySmoke>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_6, "Pt"}}, v_1002221 => +v_1001514 = template_unbox(cps_provider_1_NodeResult, v_1002221); template_continuation_355(v_1001514, v_6, v_1001513)}

def template_continuation_357(+v_1001510: cps_provider_1_Context) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Pt", []}}, False{}, v_1002224 => template_body_ref("Pt", []), v_1002223 => +v_1001512 = template_unbox(BIR.Descriptor, v_1002223); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{{v_1001510 : cps_provider_1_Context}, v_1001512}}, v_1002222 => +v_1001513 = template_unbox(cps_provider_1_LayoutResult, v_1002222); template_continuation_356(v_1001513, v_1001510)}}

def template_body_main(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<ClaySmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_program{}}, False{}, v_1002227 => template_body_program, v_1002226 => +v_1001509 = template_unbox(BIR.Program, v_1002226); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context{v_1001509}}, v_1002225 => +v_1001510 = template_unbox(cps_provider_1_Context, v_1002225); template_continuation_357(v_1001510)}}

def template_continuation_358(+v_1002233: Map<&2, Bool>, +v_16: cps_provider_2_NfContext, +v_11: List<&2, BIR.Family>, +v_19: Map<&2, BIR.DescriptorArm>, +v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<cps_provider_1_Context>:
  +v_33 = {cps_provider_1_Context{v_16, v_11, cps_provider_1_Plan{Map.new(&2, cps_provider_1_NodeResult), v_19, v_1002233}} : cps_provider_1_Context}
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_plan_node_index{v_33, v_10}}, v_1002237 => +v_1002236 = template_unbox(Map<&2, cps_provider_1_NodeResult>, v_1002237); TemplateFinished{TemplateValue{cps_provider_1_Context{{v_16 : cps_provider_2_NfContext}, {v_11 : List<&2, BIR.Family>}, cps_provider_1_Plan{v_1002236, v_19, v_1002233}}}}}

def template_continuation_359(+v_1002232: Map<&2, cps_provider_1_Dependencies>, +v_11: List<&2, BIR.Family>, +v_16: cps_provider_2_NfContext, +v_19: Map<&2, BIR.DescriptorArm>, +v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<cps_provider_1_Context>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_closed_facts{v_11, v_1002232, Map.new(&2, Bool), Map.new(&2, Bool)}}, v_1002238 => +v_1002233 = template_unbox(Map<&2, Bool>, v_1002238); template_continuation_358(v_1002233, v_16, v_11, v_19, v_10)}

def template_continuation_360(+v_1002229: Map<&2, BIR.DescriptorArm>, +v_12: List<&2, BIR.TypeFunction>, +v_11: List<&2, BIR.Family>, +v_16: cps_provider_2_NfContext, +v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<cps_provider_1_Context>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_families{v_11, Map.new(&2, cps_provider_1_Dependencies)}}, v_1002240 => +v_1002231 = template_unbox(Map<&2, cps_provider_1_Dependencies>, v_1002240); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_functions{{v_12 : List<&2, BIR.TypeFunction>}, v_1002231}}, v_1002239 => +v_1002232 = template_unbox(Map<&2, cps_provider_1_Dependencies>, v_1002239); template_continuation_359(v_1002232, v_11, v_16, v_1002229, v_10)}}

def template_continuation_361(+v_1002228: cps_provider_2_NfContext, +v_11: List<&2, BIR.Family>, +v_12: List<&2, BIR.TypeFunction>, +v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<cps_provider_1_Context>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_arm_index{v_11}}, v_1002241 => +v_1002229 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1002241); template_continuation_360(v_1002229, v_12, v_11, v_1002228, v_10)}

def template_body_cps_provider_1_context(+v_0: BIR.Program) -> TemplateProgress<cps_provider_1_Context>:
  match v_0:
    case BIR.Program{+v_8, +v_9, +v_10, +v_11, +v_12, +v_13}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_nf_context{v_11, v_12}}, v_1002242 => +v_1002228 = template_unbox(cps_provider_2_NfContext, v_1002242); template_continuation_361(v_1002228, v_11, v_12, v_10)}

def template_body_cps_provider_1_context_nf(+v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_2_NfContext>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_context_nf(v_1)}}

def template_body_cps_provider_1_context_families(+v_1: cps_provider_1_Context) -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_context_families(v_1)}}

def template_body_cps_provider_1_context_plan(+v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_Plan>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_context_plan(v_1)}}

def template_match_363(v_1002243: cps_provider_1_Plan) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  match v_1002243:
    case cps_provider_1_Plan{+v_8, +v_9, +v_10}:
      TemplateFinished{TemplateValue{v_8}}

def template_body_cps_provider_1_context_nodes(+v_1: cps_provider_1_Context) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  v_1002243 = {template_pure_cps_provider_1_context_plan(v_1) : cps_provider_1_Plan}
  template_match_363(v_1002243)

def template_match_364(v_1002244: cps_provider_1_Plan) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_1002244:
    case cps_provider_1_Plan{+v_7, +v_8, +v_9}:
      TemplateFinished{TemplateValue{v_8}}

def template_body_cps_provider_1_context_arms(+v_1: cps_provider_1_Context) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  v_1002244 = {template_pure_cps_provider_1_context_plan(v_1) : cps_provider_1_Plan}
  template_match_364(v_1002244)

def template_match_365(v_1002245: cps_provider_1_Plan) -> TemplateProgress<Map<&2, Bool>>:
  match v_1002245:
    case cps_provider_1_Plan{+v_8, +v_9, +v_10}:
      TemplateFinished{TemplateValue{v_10}}

def template_body_cps_provider_1_context_closed(+v_1: cps_provider_1_Context) -> TemplateProgress<Map<&2, Bool>>:
  v_1002245 = {template_pure_cps_provider_1_context_plan(v_1) : cps_provider_1_Plan}
  template_match_365(v_1002245)

def template_body_cps_provider_1_nf_families(+v_1: cps_provider_2_NfContext) -> TemplateProgress<Map<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_nf_families(v_1)}}

def template_body_cps_provider_1_nf_functions(+v_1: cps_provider_2_NfContext) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_nf_functions(v_1)}}

def template_body_cps_provider_1_family_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<Maybe<&2, BIR.Family>>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_family_of{v_3, template_pure_cps_provider_1_nf_families(template_pure_cps_provider_1_context_nf(v_1))}}, v_1002247 => +v_1002246 = template_unbox(Maybe<&2, BIR.Family>, v_1002247); TemplateFinished{TemplateValue{v_1002246}}}

def template_body_cps_provider_1_function_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<Maybe<&2, BIR.TypeFunction>>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_function_of{v_3, template_pure_cps_provider_1_nf_functions(template_pure_cps_provider_1_context_nf(v_1))}}, v_1002249 => +v_1002248 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1002249); TemplateFinished{TemplateValue{v_1002248}}}

def template_match_366(+v_1002250: Maybe<&2, BIR.DescriptorArm>, +v_1: String, v_8: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_1002250:
    case Some{+v_23}:
      TemplateFinished{TemplateValue{Some{v_23}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_of{v_1, v_8}}, v_1002252 => +v_1002251 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1002252); TemplateFinished{TemplateValue{v_1002251}}}

def template_match_367(+v_7: BIR.Family, +v_1: String, v_8: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_7:
    case BIR.Family{+v_15, +v_16, +v_17, +v_18, +v_19, +v_20}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_in{v_1, v_20}}, v_1002253 => +v_1002250 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1002253); template_match_366(v_1002250, v_1, v_8)}

def template_body_cps_provider_1_arm_of(+v_1: String, +v_3: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1003223 <> v_1003224:
      template_match_367(v_1003223, v_1, v_1003224)

def template_match_369(v_1002254: Bool, +v_7: BIR.DescriptorArm, +v_1: String, v_8: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_1002254:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_7}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_in{v_1, v_8}}, v_1002256 => +v_1002255 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1002256); TemplateFinished{TemplateValue{v_1002255}}}

def template_match_370(+v_7: BIR.DescriptorArm, +v_1: String, v_8: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_7:
    case BIR.DescriptorArm{+v_11, +v_12}:
      v_1002254 = {String.eq(v_1, v_11) : Bool}
      template_match_369(v_1002254, v_7, v_1, v_8)

def template_body_cps_provider_1_arm_in(+v_1: String, +v_3: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1003225 <> v_1003226:
      template_match_370(v_1003225, v_1, v_1003226)

def template_match_372(+v_5: BIR.Family, v_6: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_5:
    case BIR.Family{+v_13, +v_14, +v_15, +v_16, +v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_arm_index{v_6}}, v_1002261 => +v_1002258 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1002261); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_family_arms{{v_18 : List<&2, BIR.DescriptorArm>}, v_1002258}}, v_1002260 => +v_1002259 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1002260); TemplateFinished{TemplateValue{v_1002259}}}}

def template_body_cps_provider_1_plan_arm_index(+v_1: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.DescriptorArm)}}
    case +v_5 <> v_6:
      template_match_372(v_5, v_6)

def template_match_374(+v_7: BIR.DescriptorArm, v_8: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_7:
    case BIR.DescriptorArm{+v_11, +v_12}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_family_arms{v_8, v_3}}, v_1002263 => +v_1002262 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1002263); TemplateFinished{TemplateValue{Map.set(&2, BIR.DescriptorArm, v_1002262, v_11, {BIR.DescriptorArm{v_11, v_12} : BIR.DescriptorArm})}}}

def template_body_cps_provider_1_plan_family_arms(+v_1: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_3}}
    case +v_7 <> v_8:
      template_match_374(v_7, v_8, v_3)

def template_body_cps_provider_1_arm_declared(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context_arms{v_1}}, False{}, v_1002266 => template_body_cps_provider_1_context_arms(v_1), v_1002265 => +v_1002264 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1002265); TemplateFinished{TemplateValue{IndexLookup.find(BIR.DescriptorArm, v_1002264, v_3)}}}

def template_body_cps_provider_1_live_field(+v_0: BIR.Quantity) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_live_field(v_0)}}

def template_match_376(v_1002267: Maybe<&2, cps_provider_1_Dependencies>) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_1002267:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{v_8}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_Dependencies{[]}}}

def template_body_cps_provider_1_dependency_seed(+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String) -> TemplateProgress<cps_provider_1_Dependencies>:
  v_1002267 = {IndexLookup.find(cps_provider_1_Dependencies, v_2, v_4) : Maybe<&2, cps_provider_1_Dependencies>}
  template_match_376(v_1002267)

def template_body_cps_provider_1_dependency_name(+v_1: String, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_3:
    case cps_provider_1_Dependencies{+v_1003227}:
      TemplateFinished{TemplateValue{cps_provider_1_Dependencies{v_1 <> v_1003227}}}
    case cps_provider_1_DependenciesUnknown{}:
      TemplateFinished{TemplateValue{cps_provider_1_DependenciesUnknown{}}}

def template_body_cps_provider_1_dependency_descriptors(+v_1: List<&2, BIR.Descriptor>, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_3}}
    case +v_7 <> v_8:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_7, v_3}}, v_1002272 => +v_1002269 = template_unbox(cps_provider_1_Dependencies, v_1002272); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptors{{v_8 : List<&2, BIR.Descriptor>}, v_1002269}}, v_1002271 => +v_1002270 = template_unbox(cps_provider_1_Dependencies, v_1002271); TemplateFinished{TemplateValue{v_1002270}}}}

def template_match_379(+v_7: BIR.DescriptorPattern, v_8: List<&2, BIR.DescriptorPattern>, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_7:
    case BIR.DescriptorBinder{+v_10}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_patterns{v_8, v_3}}, v_1002274 => +v_1002273 = template_unbox(cps_provider_1_Dependencies, v_1002274); TemplateFinished{TemplateValue{v_1002273}}}
    case BIR.DescriptorConstructorPattern{+v_14, +v_15}:
      +v_1002275 = {v_8 : List<&2, BIR.DescriptorPattern>}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_patterns{v_15, v_3}}, v_1002279 => +v_1002276 = template_unbox(cps_provider_1_Dependencies, v_1002279); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_patterns{v_1002275, v_1002276}}, v_1002278 => +v_1002277 = template_unbox(cps_provider_1_Dependencies, v_1002278); TemplateFinished{TemplateValue{v_1002277}}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_DependenciesUnknown{}}}

def template_body_cps_provider_1_dependency_patterns(+v_1: List<&2, BIR.DescriptorPattern>, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_3}}
    case +v_7 <> v_8:
      template_match_379(v_7, v_8, v_3)

def template_body_cps_provider_1_dependency_descriptor(+v_0: BIR.Descriptor, +v_2: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_0:
    case BIR.DescriptorNull{}:
      TemplateFinished{TemplateValue{v_2}}
    case BIR.DescriptorParameter{+v_5}:
      TemplateFinished{TemplateValue{v_2}}
    case BIR.DescriptorQuantityKind{}:
      TemplateFinished{TemplateValue{v_2}}
    case BIR.DescriptorQuantity{+v_7}:
      TemplateFinished{TemplateValue{v_2}}
    case BIR.DescriptorReflexivity{}:
      TemplateFinished{TemplateValue{v_2}}
    case BIR.DescriptorFailure{+v_9}:
      TemplateFinished{TemplateValue{v_2}}
    case BIR.DescriptorRef{+v_12, +v_13}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_name{v_12, v_2}}, False{}, v_1002284 => template_body_cps_provider_1_dependency_name(v_12, v_2), v_1002283 => +v_1002281 = template_unbox(cps_provider_1_Dependencies, v_1002283); template_body_cps_provider_1_dependency_descriptors({v_13 : List<&2, BIR.Descriptor>}, v_1002281)}
    case BIR.DescriptorConstructor{+v_18, +v_19}:
      template_body_cps_provider_1_dependency_descriptors(v_19, v_2)
    case BIR.DescriptorKind{+v_22}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_22, v_2}}, v_1002287 => +v_1002286 = template_unbox(cps_provider_1_Dependencies, v_1002287); TemplateFinished{TemplateValue{v_1002286}}}
    case BIR.DescriptorMinimum{+v_26, +v_27}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_26, v_2}}, v_1002292 => +v_1002289 = template_unbox(cps_provider_1_Dependencies, v_1002292); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_27 : BIR.Descriptor}, v_1002289}}, v_1002291 => +v_1002290 = template_unbox(cps_provider_1_Dependencies, v_1002291); TemplateFinished{TemplateValue{v_1002290}}}}
    case BIR.DescriptorArrow{+v_33, +v_34, +v_35}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_34, v_2}}, v_1002297 => +v_1002294 = template_unbox(cps_provider_1_Dependencies, v_1002297); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_35 : BIR.Descriptor}, v_1002294}}, v_1002296 => +v_1002295 = template_unbox(cps_provider_1_Dependencies, v_1002296); TemplateFinished{TemplateValue{v_1002295}}}}
    case BIR.DescriptorLambda{+v_40, +v_41}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_41, v_2}}, v_1002299 => +v_1002298 = template_unbox(cps_provider_1_Dependencies, v_1002299); TemplateFinished{TemplateValue{v_1002298}}}
    case BIR.DescriptorApplication{+v_45, +v_46}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_45, v_2}}, v_1002304 => +v_1002301 = template_unbox(cps_provider_1_Dependencies, v_1002304); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_46 : BIR.Descriptor}, v_1002301}}, v_1002303 => +v_1002302 = template_unbox(cps_provider_1_Dependencies, v_1002303); TemplateFinished{TemplateValue{v_1002302}}}}
    case BIR.DescriptorSubstitution{+v_52, +v_53, +v_54}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_53, v_2}}, v_1002309 => +v_1002306 = template_unbox(cps_provider_1_Dependencies, v_1002309); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_54 : BIR.Descriptor}, v_1002306}}, v_1002308 => +v_1002307 = template_unbox(cps_provider_1_Dependencies, v_1002308); TemplateFinished{TemplateValue{v_1002307}}}}
    case BIR.DescriptorLet{+v_59, +v_60}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptors{v_59, v_2}}, False{}, v_1002315 => template_body_cps_provider_1_dependency_descriptors(v_59, v_2), v_1002314 => +v_1002311 = template_unbox(cps_provider_1_Dependencies, v_1002314); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_60 : BIR.Descriptor}, v_1002311}}, v_1002313 => +v_1002312 = template_unbox(cps_provider_1_Dependencies, v_1002313); TemplateFinished{TemplateValue{v_1002312}}}}
    case BIR.DescriptorLocal{+v_66, +v_67, +v_68}:
      +v_1002317 = {v_67 : List<&2, BIR.Descriptor>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_patterns{v_66, v_2}}, False{}, v_1002325 => template_body_cps_provider_1_dependency_patterns(v_66, v_2), v_1002324 => +v_1002318 = template_unbox(cps_provider_1_Dependencies, v_1002324); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptors{v_1002317, v_1002318}}, False{}, v_1002323 => template_body_cps_provider_1_dependency_descriptors(v_1002317, v_1002318), v_1002322 => +v_1002319 = template_unbox(cps_provider_1_Dependencies, v_1002322); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_68 : BIR.Descriptor}, v_1002319}}, v_1002321 => +v_1002320 = template_unbox(cps_provider_1_Dependencies, v_1002321); TemplateFinished{TemplateValue{v_1002320}}}}}
    case BIR.DescriptorMatch{+v_74, +v_75}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptors{v_74, v_2}}, False{}, v_1002330 => template_body_cps_provider_1_dependency_descriptors(v_74, v_2), v_1002329 => +v_1002327 = template_unbox(cps_provider_1_Dependencies, v_1002329); template_body_cps_provider_1_dependency_descriptors({v_75 : List<&2, BIR.Descriptor>}, v_1002327)}
    case BIR.DescriptorCase{+v_80, +v_81}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_patterns{v_80, v_2}}, False{}, v_1002336 => template_body_cps_provider_1_dependency_patterns(v_80, v_2), v_1002335 => +v_1002332 = template_unbox(cps_provider_1_Dependencies, v_1002335); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_81 : BIR.Descriptor}, v_1002332}}, v_1002334 => +v_1002333 = template_unbox(cps_provider_1_Dependencies, v_1002334); TemplateFinished{TemplateValue{v_1002333}}}}
    case BIR.DescriptorBind{+v_86, +v_87}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_86, v_2}}, v_1002341 => +v_1002338 = template_unbox(cps_provider_1_Dependencies, v_1002341); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_87 : BIR.Descriptor}, v_1002338}}, v_1002340 => +v_1002339 = template_unbox(cps_provider_1_Dependencies, v_1002340); TemplateFinished{TemplateValue{v_1002339}}}}
    case BIR.DescriptorEquality{+v_93, +v_94, +v_95}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_93, v_2}}, v_1002349 => +v_1002344 = template_unbox(cps_provider_1_Dependencies, v_1002349); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_94 : BIR.Descriptor}, v_1002344}}, v_1002348 => +v_1002345 = template_unbox(cps_provider_1_Dependencies, v_1002348); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_95 : BIR.Descriptor}, v_1002345}}, v_1002347 => +v_1002346 = template_unbox(cps_provider_1_Dependencies, v_1002347); TemplateFinished{TemplateValue{v_1002346}}}}}
    case BIR.DescriptorFill{+v_101, +v_102}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_101, v_2}}, v_1002353 => +v_1002351 = template_unbox(cps_provider_1_Dependencies, v_1002353); template_body_cps_provider_1_dependency_descriptors({v_102 : List<&2, BIR.Descriptor>}, v_1002351)}
    case BIR.DescriptorPlus{+v_107, +v_108}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_107, v_2}}, v_1002357 => +v_1002355 = template_unbox(cps_provider_1_Dependencies, v_1002357); template_body_cps_provider_1_dependency_descriptors({v_108 : List<&2, BIR.Descriptor>}, v_1002355)}
    case BIR.DescriptorNamedFill{+v_114, +v_115, +v_116}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_name{v_114, v_2}}, False{}, v_1002365 => template_body_cps_provider_1_dependency_name(v_114, v_2), v_1002364 => +v_1002360 = template_unbox(cps_provider_1_Dependencies, v_1002364); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_115 : BIR.Descriptor}, v_1002360}}, v_1002363 => +v_1002361 = template_unbox(cps_provider_1_Dependencies, v_1002363); template_body_cps_provider_1_dependency_descriptors({v_116 : List<&2, BIR.Descriptor>}, v_1002361)}}
    case BIR.DescriptorNamedPlus{+v_123, +v_124, +v_125}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_name{v_123, v_2}}, False{}, v_1002373 => template_body_cps_provider_1_dependency_name(v_123, v_2), v_1002372 => +v_1002368 = template_unbox(cps_provider_1_Dependencies, v_1002372); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{{v_124 : BIR.Descriptor}, v_1002368}}, v_1002371 => +v_1002369 = template_unbox(cps_provider_1_Dependencies, v_1002371); template_body_cps_provider_1_dependency_descriptors({v_125 : List<&2, BIR.Descriptor>}, v_1002369)}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_DependenciesUnknown{}}}

def template_match_382(+v_7: BIR.DescriptorField, v_8: List<&2, BIR.DescriptorField>, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_7:
    case BIR.DescriptorField{+v_12, +v_13, +v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_14, v_3}}, False{}, v_1002379 => template_body_cps_provider_1_dependency_descriptor(v_14, v_3), v_1002378 => +v_1002375 = template_unbox(cps_provider_1_Dependencies, v_1002378); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_fields{{v_8 : List<&2, BIR.DescriptorField>}, v_1002375}}, v_1002377 => +v_1002376 = template_unbox(cps_provider_1_Dependencies, v_1002377); TemplateFinished{TemplateValue{v_1002376}}}}

def template_body_cps_provider_1_dependency_fields(+v_1: List<&2, BIR.DescriptorField>, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_3}}
    case +v_7 <> v_8:
      template_match_382(v_7, v_8, v_3)

def template_match_384(+v_7: BIR.DescriptorArm, v_8: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_7:
    case BIR.DescriptorArm{+v_11, +v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_fields{v_12, v_3}}, False{}, v_1002385 => template_body_cps_provider_1_dependency_fields(v_12, v_3), v_1002384 => +v_1002381 = template_unbox(cps_provider_1_Dependencies, v_1002384); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_arms{{v_8 : List<&2, BIR.DescriptorArm>}, v_1002381}}, v_1002383 => +v_1002382 = template_unbox(cps_provider_1_Dependencies, v_1002383); TemplateFinished{TemplateValue{v_1002382}}}}

def template_body_cps_provider_1_dependency_arms(+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Dependencies) -> TemplateProgress<cps_provider_1_Dependencies>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_3}}
    case +v_7 <> v_8:
      template_match_384(v_7, v_8, v_3)

def template_continuation_386(+v_1002388: cps_provider_1_Dependencies, v_10: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_17: String) -> TemplateProgress<Map<&2, cps_provider_1_Dependencies>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_families{v_10, Map.set(&2, cps_provider_1_Dependencies, v_4, v_17, v_1002388)}}, v_1002390 => +v_1002389 = template_unbox(Map<&2, cps_provider_1_Dependencies>, v_1002390); TemplateFinished{TemplateValue{v_1002389}}}

def template_match_387(+v_9: BIR.Family, +v_4: Map<&2, cps_provider_1_Dependencies>, v_10: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, cps_provider_1_Dependencies>>:
  match v_9:
    case BIR.Family{+v_17, +v_18, +v_19, +v_20, +v_21, +v_22}:
      +v_1002386 = {v_22 : List<&2, BIR.DescriptorArm>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_seed{v_4, v_17}}, False{}, v_1002394 => template_body_cps_provider_1_dependency_seed(v_4, v_17), v_1002393 => +v_1002387 = template_unbox(cps_provider_1_Dependencies, v_1002393); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_arms{v_1002386, v_1002387}}, False{}, v_1002392 => template_body_cps_provider_1_dependency_arms(v_1002386, v_1002387), v_1002391 => +v_1002388 = template_unbox(cps_provider_1_Dependencies, v_1002391); template_continuation_386(v_1002388, v_10, v_4, v_17)}}

def template_body_cps_provider_1_dependency_families(+v_1: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>) -> TemplateProgress<Map<&2, cps_provider_1_Dependencies>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_9 <> v_10:
      template_match_387(v_9, v_4, v_10)

def template_continuation_389(+v_1002397: cps_provider_1_Dependencies, v_10: List<&2, BIR.TypeFunction>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_16: String) -> TemplateProgress<Map<&2, cps_provider_1_Dependencies>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_functions{v_10, Map.set(&2, cps_provider_1_Dependencies, v_4, v_16, v_1002397)}}, v_1002399 => +v_1002398 = template_unbox(Map<&2, cps_provider_1_Dependencies>, v_1002399); TemplateFinished{TemplateValue{v_1002398}}}

def template_match_390(+v_9: BIR.TypeFunction, +v_4: Map<&2, cps_provider_1_Dependencies>, v_10: List<&2, BIR.TypeFunction>) -> TemplateProgress<Map<&2, cps_provider_1_Dependencies>>:
  match v_9:
    case BIR.TypeFunction{+v_16, +v_17, +v_18, +v_19, +v_20}:
      +v_1002395 = {v_20 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_seed{v_4, v_16}}, False{}, v_1002403 => template_body_cps_provider_1_dependency_seed(v_4, v_16), v_1002402 => +v_1002396 = template_unbox(cps_provider_1_Dependencies, v_1002402); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_descriptor{v_1002395, v_1002396}}, False{}, v_1002401 => template_body_cps_provider_1_dependency_descriptor(v_1002395, v_1002396), v_1002400 => +v_1002397 = template_unbox(cps_provider_1_Dependencies, v_1002400); template_continuation_389(v_1002397, v_10, v_4, v_16)}}

def template_body_cps_provider_1_dependency_functions(+v_1: List<&2, BIR.TypeFunction>, +v_4: Map<&2, cps_provider_1_Dependencies>) -> TemplateProgress<Map<&2, cps_provider_1_Dependencies>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_9 <> v_10:
      template_match_390(v_9, v_4, v_10)

def template_match_392(+v_32: cps_provider_1_Dependencies, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, v_21: List<&2, String>, v_16: List<&2, List<&2, String>>, +v_28: Map<&2, Bool>) -> TemplateProgress<Bool>:
  match v_32:
    case cps_provider_1_DependenciesUnknown{}:
      TemplateFinished{TemplateValue{True{}}}
    case cps_provider_1_Dependencies{+v_34}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_maybe_reaches{v_2, v_4, v_34 <> v_21 <> v_16, v_28}}, v_1002414 => +v_1002413 = template_unbox(Bool, v_1002414); TemplateFinished{TemplateValue{v_1002413}}}

def template_match_393(v_1002410: Maybe<&2, cps_provider_1_Dependencies>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, v_21: List<&2, String>, v_16: List<&2, List<&2, String>>, +v_28: Map<&2, Bool>) -> TemplateProgress<Bool>:
  match v_1002410:
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_maybe_reaches{v_2, v_4, v_21 <> v_16, v_28}}, v_1002412 => +v_1002411 = template_unbox(Bool, v_1002412); TemplateFinished{TemplateValue{v_1002411}}}
    case Some{+v_32}:
      template_match_392(v_32, v_2, v_4, v_21, v_16, v_28)

def template_match_394(v_1002407: Maybe<&2, Bool>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, v_21: List<&2, String>, v_16: List<&2, List<&2, String>>, +v_11: Map<&2, Bool>, +v_20: String) -> TemplateProgress<Bool>:
  match v_1002407:
    case Some{+v_24}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_maybe_reaches{v_2, v_4, v_21 <> v_16, v_11}}, v_1002409 => +v_1002408 = template_unbox(Bool, v_1002409); TemplateFinished{TemplateValue{v_1002408}}}
    case None{}:
      +v_28 = Map.set(&2, Bool, v_11, v_20, True{})
      v_1002410 = {IndexLookup.find(cps_provider_1_Dependencies, v_2, v_20) : Maybe<&2, cps_provider_1_Dependencies>}
      template_match_393(v_1002410, v_2, v_4, v_21, v_16, v_28)

def template_match_395(v_1002406: Bool, +v_11: Map<&2, Bool>, +v_20: String, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, v_21: List<&2, String>, v_16: List<&2, List<&2, String>>) -> TemplateProgress<Bool>:
  match v_1002406:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      v_1002407 = {IndexLookup.find(Bool, v_11, v_20) : Maybe<&2, Bool>}
      template_match_394(v_1002407, v_2, v_4, v_21, v_16, v_11, v_20)

def template_match_396(+v_15: List<&2, String>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, v_16: List<&2, List<&2, String>>, +v_11: Map<&2, Bool>) -> TemplateProgress<Bool>:
  match v_15:
    case []:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_maybe_reaches{v_2, v_4, v_16, v_11}}, v_1002405 => +v_1002404 = template_unbox(Bool, v_1002405); TemplateFinished{TemplateValue{v_1002404}}}
    case +v_20 <> v_21:
      v_1002406 = {String.eq(v_20, v_4) : Bool}
      template_match_395(v_1002406, v_11, v_20, v_2, v_4, v_21, v_16)

def template_body_cps_provider_1_dependency_maybe_reaches(+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_8: List<&2, List<&2, String>>, +v_11: Map<&2, Bool>) -> TemplateProgress<Bool>:
  match v_8:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1003228 <> v_1003229:
      template_match_396(v_1003228, v_2, v_4, v_1003229, v_11)

def template_match_398(+v_1002416: Bool) -> TemplateProgress<Bool>:
  match v_1002416:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplateFinished{TemplateValue{True{}}}

def template_match_399(+v_8: cps_provider_1_Dependencies, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String) -> TemplateProgress<Bool>:
  match v_8:
    case cps_provider_1_DependenciesUnknown{}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_1_Dependencies{+v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_maybe_reaches{v_2, v_4, [v_10], Map.new(&2, Bool)}}, False{}, v_1002418 => template_body_cps_provider_1_dependency_maybe_reaches(v_2, v_4, [v_10], Map.new(&2, Bool)), v_1002417 => +v_1002416 = template_unbox(Bool, v_1002417); template_match_398(v_1002416)}

def template_match_400(v_1002415: Maybe<&2, cps_provider_1_Dependencies>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String) -> TemplateProgress<Bool>:
  match v_1002415:
    case None{}:
      TemplateFinished{TemplateValue{False{}}}
    case Some{+v_8}:
      template_match_399(v_8, v_2, v_4)

def template_body_cps_provider_1_dependency_closed(+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String) -> TemplateProgress<Bool>:
  v_1002415 = {IndexLookup.find(cps_provider_1_Dependencies, v_2, v_4) : Maybe<&2, cps_provider_1_Dependencies>}
  template_match_400(v_1002415, v_2, v_4)

def template_match_401(+v_1002425: Bool, v_16: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_35: Map<&2, Bool>, +v_10: Map<&2, Bool>, +v_23: String) -> TemplateProgress<Map<&2, Bool>>:
  match v_1002425:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_closed_facts{v_16, v_4, v_35, v_10}}, v_1002427 => +v_1002426 = template_unbox(Map<&2, Bool>, v_1002427); TemplateFinished{TemplateValue{v_1002426}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_closed_facts{v_16, v_4, v_35, Map.set(&2, Bool, v_10, v_23, True{})}}, v_1002429 => +v_1002428 = template_unbox(Map<&2, Bool>, v_1002429); TemplateFinished{TemplateValue{v_1002428}}}

def template_match_402(v_1002422: Bool, v_16: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_35: Map<&2, Bool>, +v_10: Map<&2, Bool>, +v_23: String) -> TemplateProgress<Map<&2, Bool>>:
  match v_1002422:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_closed_facts{v_16, v_4, v_35, v_10}}, v_1002424 => +v_1002423 = template_unbox(Map<&2, Bool>, v_1002424); TemplateFinished{TemplateValue{v_1002423}}}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_dependency_closed{v_4, v_23}}, False{}, v_1002431 => template_body_cps_provider_1_dependency_closed(v_4, v_23), v_1002430 => +v_1002425 = template_unbox(Bool, v_1002430); template_match_401(v_1002425, v_16, v_4, v_35, v_10, v_23)}

def template_match_403(v_1002419: Maybe<&2, Bool>, v_16: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_7: Map<&2, Bool>, +v_10: Map<&2, Bool>, +v_23: String, +v_27: Nat) -> TemplateProgress<Map<&2, Bool>>:
  match v_1002419:
    case Some{+v_31}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_closed_facts{v_16, v_4, v_7, v_10}}, v_1002421 => +v_1002420 = template_unbox(Map<&2, Bool>, v_1002421); TemplateFinished{TemplateValue{v_1002420}}}
    case None{}:
      +v_35 = Map.set(&2, Bool, v_7, v_23, True{})
      v_1002422 = {Nat.is_eq(v_27, 0n) : Bool}
      template_match_402(v_1002422, v_16, v_4, v_35, v_10, v_23)

def template_match_404(+v_15: BIR.Family, +v_7: Map<&2, Bool>, v_16: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_10: Map<&2, Bool>) -> TemplateProgress<Map<&2, Bool>>:
  match v_15:
    case BIR.Family{+v_23, +v_24, +v_25, +v_26, +v_27, +v_28}:
      v_1002419 = {IndexLookup.find(Bool, v_7, v_23) : Maybe<&2, Bool>}
      template_match_403(v_1002419, v_16, v_4, v_7, v_10, v_23, v_27)

def template_body_cps_provider_1_plan_closed_facts(+v_1: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>, +v_7: Map<&2, Bool>, +v_10: Map<&2, Bool>) -> TemplateProgress<Map<&2, Bool>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_10}}
    case +v_1003230 <> v_1003231:
      template_match_404(v_1003230, v_7, v_1003231, v_4, v_10)

def template_body_cps_provider_1_layout_fuel() -> TemplateProgress<Nat>:
  TemplateFinished{TemplateValue{1024n}}

def template_body_cps_provider_1_nf_of(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{template_pure_cps_provider_1_context_nf(v_1), v_2, v_5, 0n, v_7}}, v_1002433 => +v_1002432 = template_unbox(cps_provider_2_Nf, v_1002433); TemplateFinished{TemplateValue{v_1002432}}}

def template_body_cps_provider_1_value_layout(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_LayoutResult>:
  +v_1002436 = {[] : List<&2, cps_provider_2_NfVal>}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1002441 => template_body_cps_provider_1_layout_fuel, v_1002440 => +v_1002437 = template_unbox(Nat, v_1002440); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_of_desc{{v_1 : cps_provider_1_Context}, {v_2 : BIR.Descriptor}, v_1002436, v_1002437}}, v_1002439 => +v_1002438 = template_unbox(cps_provider_1_LayoutResult, v_1002439); TemplateFinished{TemplateValue{v_1002438}}}}

def template_match_406(+v_1002442: cps_provider_2_Nf, +v_1: cps_provider_1_Context, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002442:
    case cps_provider_2_NfFail{+v_11}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFailed{v_11}}}
    case cps_provider_2_NfOk{+v_13}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_of_val{v_1, v_13, v_7}}, v_1002444 => +v_1002443 = template_unbox(cps_provider_1_LayoutResult, v_1002444); TemplateFinished{TemplateValue{v_1002443}}}

def template_body_cps_provider_1_layout_of_desc(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, v_5, v_7}}, False{}, v_1002446 => template_body_cps_provider_1_nf_of(v_1, v_2, v_5, v_7), v_1002445 => +v_1002442 = template_unbox(cps_provider_2_Nf, v_1002445); template_match_406(v_1002442, v_1, v_7)}

def template_match_407(v_1002447: Bool, +v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002447:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_val{v_1, v_3, Nat.sub(v_5, 1n)}}, v_1002449 => +v_1002448 = template_unbox(cps_provider_1_LayoutResult, v_1002449); TemplateFinished{TemplateValue{v_1002448}}}

def template_body_cps_provider_1_layout_of_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  v_1002447 = {Nat.is_eq(v_5, 0n) : Bool}
  template_match_407(v_1002447, v_1, v_3, v_5)

def template_match_408(+v_1002450: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_2_NfVal>, +v_5: Nat, +v_9: String) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002450:
    case Some{+v_13}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_family{v_1, v_13, v_10, v_5}}, v_1002452 => +v_1002451 = template_unbox(cps_provider_1_LayoutResult, v_1002452); TemplateFinished{TemplateValue{v_1002451}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_unresolved{v_1, v_9}}, v_1002454 => +v_1002453 = template_unbox(cps_provider_1_LayoutResult, v_1002454); TemplateFinished{TemplateValue{v_1002453}}}

def template_body_cps_provider_1_layout_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_3:
    case cps_provider_2_NfType{+v_1003232, +v_1003233}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_family_lookup{v_1, v_1003232}}, False{}, v_1003234 => template_body_cps_provider_1_family_lookup(v_1, v_1003232), v_1003235 => +v_1003236 = template_unbox(Maybe<&2, BIR.Family>, v_1003235); template_match_408(v_1003236, v_1, v_1003233, v_5, v_1003232)}
    case cps_provider_2_NfCtor{+v_1003237, +v_1003238}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_2_NfQuantity{+v_1003239}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_2_NfKind{+v_1003240}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_2_NfOther{+v_1003241}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_2_NfMissing{+v_1003242}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case v_1003243:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}

def template_match_410(+v_1002457: Maybe<&2, BIR.TypeFunction>, +v_3: String) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002457:
    case Some{+v_7}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxUnresolved{v_3}}}}}

def template_body_cps_provider_1_layout_unresolved(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_LayoutResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_function_lookup{v_1, v_3}}, False{}, v_1002459 => template_body_cps_provider_1_function_lookup(v_1, v_3), v_1002458 => +v_1002457 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1002458); template_match_410(v_1002457, v_3)}

def template_match_411(+v_17: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_15: String, +v_20: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_17:
    case Some{+v_23}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_native{v_1, v_23, v_15, v_20, v_5, v_7}}, v_1002462 => +v_1002461 = template_unbox(cps_provider_1_LayoutResult, v_1002462); TemplateFinished{TemplateValue{v_1002461}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_data{v_1, v_15, v_20, v_5, v_7}}, v_1002464 => +v_1002463 = template_unbox(cps_provider_1_LayoutResult, v_1002464); TemplateFinished{TemplateValue{v_1002463}}}

def template_match_412(v_1002460: Bool, +v_17: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_15: String, +v_20: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002460:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case True{}:
      template_match_411(v_17, v_1, v_15, v_20, v_5, v_7)

def template_body_cps_provider_1_layout_family(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_2:
    case BIR.Family{+v_1003244, +v_1003245, +v_1003246, +v_1003247, +v_1003248, +v_1003249}:
      v_1003250 = {Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_5), v_1003248) : Bool}
      template_match_412(v_1003250, v_1003246, v_1, v_1003244, v_1003249, v_5, v_7)

def template_match_414(v_1002469: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002469:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxIo{}}}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_data{v_1, v_5, v_7, v_10, v_12}}, v_1002471 => +v_1002470 = template_unbox(cps_provider_1_LayoutResult, v_1002471); TemplateFinished{TemplateValue{v_1002470}}}

def template_match_415(v_1002468: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002468:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxArray{}}}}}
    case False{}:
      v_1002469 = {String.eq(v_3, "IO.OP") : Bool}
      template_match_414(v_1002469, v_1, v_5, v_7, v_10, v_12)

def template_match_416(v_1002467: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002467:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}}}
    case False{}:
      v_1002468 = {String.eq(v_3, "Array") : Bool}
      template_match_415(v_1002468, v_3, v_1, v_5, v_7, v_10, v_12)

def template_match_417(v_1002466: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002466:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}}}
    case False{}:
      v_1002467 = {String.eq(v_3, "F32") : Bool}
      template_match_416(v_1002467, v_3, v_1, v_5, v_7, v_10, v_12)

def template_match_418(v_1002465: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002465:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord64{}}}}}
    case False{}:
      v_1002466 = {String.eq(v_3, "U32") : Bool}
      template_match_417(v_1002466, v_3, v_1, v_5, v_7, v_10, v_12)

def template_body_cps_provider_1_layout_native(+v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  v_1002465 = {String.eq(v_3, "Nat") : Bool}
  template_match_418(v_1002465, v_3, v_1, v_5, v_7, v_10, v_12)

def template_body_cps_provider_1_field_scope(+v_2: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  +v_7 = {cps_provider_2_NfMissing{BIR.DescriptorNull{}} : cps_provider_2_NfVal}
  TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_NfVal, v_2, [v_7])}}

def template_match_419(+v_1002472: cps_provider_1_Layouts, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_20: String, +v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_Plans>:
  match v_1002472:
    case cps_provider_1_LayoutsFail{+v_24}:
      TemplateFinished{TemplateValue{cps_provider_1_PlansFail{v_24}}}
    case cps_provider_1_LayoutsOk{+v_26}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_layouts{v_1, v_17, v_6, v_8, cps_provider_1_LayArm{v_20, v_26} <> v_11}}, v_1002474 => +v_1002473 = template_unbox(cps_provider_1_Plans, v_1002474); TemplateFinished{TemplateValue{v_1002473}}}

def template_match_420(+v_16: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, v_17: List<&2, BIR.DescriptorArm>, +v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_Plans>:
  match v_16:
    case BIR.DescriptorArm{+v_20, +v_21}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_field_layouts{v_1, v_21, v_6, v_8, []}}, v_1002475 => +v_1002472 = template_unbox(cps_provider_1_Layouts, v_1002475); template_match_419(v_1002472, v_1, v_17, v_6, v_8, v_20, v_11)}

def template_body_cps_provider_1_arm_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_Plans>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_PlansOk{List.reverse(&2, cps_provider_1_LayArm, v_11)}}}
    case +v_1003251 <> v_1003252:
      template_match_420(v_1003251, v_1, v_6, v_8, v_1003252, v_11)

def template_match_422(+v_1002480: cps_provider_1_LayoutResult, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_26: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_1002480:
    case cps_provider_1_LayoutFailed{+v_31}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutsFail{v_31}}}
    case cps_provider_1_LayoutFound{+v_33}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_field_layouts{v_1, v_17, v_26, v_8, v_33 <> v_11}}, v_1002482 => +v_1002481 = template_unbox(cps_provider_1_Layouts, v_1002482); TemplateFinished{TemplateValue{v_1002481}}}

def template_match_423(v_1002477: Bool, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_26: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, +v_23: BIR.Descriptor, +v_6: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_1002477:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_field_layouts{v_1, v_17, v_26, v_8, v_11}}, v_1002479 => +v_1002478 = template_unbox(cps_provider_1_Layouts, v_1002479); TemplateFinished{TemplateValue{v_1002478}}}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_of_desc{v_1, v_23, v_6, v_8}}, False{}, v_1002484 => template_body_cps_provider_1_layout_of_desc(v_1, v_23, v_6, v_8), v_1002483 => +v_1002480 = template_unbox(cps_provider_1_LayoutResult, v_1002483); template_match_422(v_1002480, v_1, v_17, v_26, v_8, v_11)}

def template_continuation_424(+v_1002476: List<&2, cps_provider_2_NfVal>, +v_22: BIR.Quantity, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, +v_23: BIR.Descriptor, +v_6: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_1_Layouts>:
  v_1002477 = {template_pure_cps_provider_1_live_field(v_22) : Bool}
  template_match_423(v_1002477, v_1, v_17, v_1002476, v_8, v_11, v_23, v_6)

def template_match_425(+v_16: BIR.DescriptorField, +v_6: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_16:
    case BIR.DescriptorField{+v_21, +v_22, +v_23}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_field_scope{v_6}}, False{}, v_1002486 => template_body_cps_provider_1_field_scope(v_6), v_1002485 => +v_1002476 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002485); template_continuation_424(v_1002476, v_22, v_1, v_17, v_8, v_11, v_23, v_6)}

def template_body_cps_provider_1_field_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutsOk{List.reverse(&2, cps_provider_1_Layout, v_11)}}}
    case +v_1003253 <> v_1003254:
      template_match_425(v_1003253, v_6, v_1, v_1003254, v_8, v_11)

def template_match_427(v_1002490: Bool, +v_24: Nat, +v_21: List<&2, cps_provider_1_CWord>, +v_17: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002490:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxWide{v_24}}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutData{v_21, v_17}}}}

def template_continuation_428(+v_1002489: List<&2, cps_provider_1_CWord>, +v_17: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_LayoutResult>:
  +v_24 = List.length(&2, cps_provider_1_CWord, v_1002489)
  v_1002490 = {Nat.is_gt(v_24, 8n) : Bool}
  template_match_427(v_1002490, v_24, v_1002489, v_17)

def template_match_429(+v_1002488: cps_provider_1_Plans) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002488:
    case cps_provider_1_PlansFail{+v_15}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFailed{v_15}}}
    case cps_provider_1_PlansOk{+v_17}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_arms{v_17, template_pure_cps_provider_1_arms_tagged(v_17)}}, v_1002491 => +v_1002489 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002491); template_continuation_428(v_1002489, v_17)}

def template_match_430(+v_1002487: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1002487:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxRecursive{v_3}}}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_layouts{v_1, v_5, v_8, v_10, []}}, False{}, v_1002493 => template_body_cps_provider_1_arm_layouts(v_1, v_5, v_8, v_10, []), v_1002492 => +v_1002488 = template_unbox(cps_provider_1_Plans, v_1002492); template_match_429(v_1002488)}

def template_body_cps_provider_1_layout_data(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_data_reenters{v_1, v_3, v_5, v_8, v_10}}, v_1002494 => +v_1002487 = template_unbox(Bool, v_1002494); template_match_430(v_1002487, v_3, v_1, v_5, v_8, v_10)}

def template_match_431(v_1002496: Maybe<&2, Bool>, +v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1002496:
    case Some{+v_15}:
      TemplateFinished{TemplateValue{False{}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reenters{v_1, v_3, v_5, v_8, v_10}}, v_1002498 => +v_1002497 = template_unbox(Bool, v_1002498); TemplateFinished{TemplateValue{v_1002497}}}

def template_continuation_432(+v_1002495: Map<&2, Bool>, +v_3: String, +v_1: cps_provider_1_Context, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> TemplateProgress<Bool>:
  v_1002496 = {IndexLookup.find(Bool, v_1002495, v_3) : Maybe<&2, Bool>}
  template_match_431(v_1002496, v_1, v_3, v_5, v_8, v_10)

def template_body_cps_provider_1_data_reenters(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_8:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context_closed{v_1}}, False{}, v_1003255 => template_body_cps_provider_1_context_closed(v_1), v_1003256 => +v_1003257 = template_unbox(Map<&2, Bool>, v_1003256); template_continuation_432(v_1003257, v_3, v_1, v_5, v_8, v_10)}
    case v_1003258:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reenters{v_1, v_3, v_5, v_8, v_10}}, v_1003259 => +v_1003260 = template_unbox(Bool, v_1003259); TemplateFinished{TemplateValue{v_1003260}}}

def template_body_cps_provider_1_arms_tagged(+v_2: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_arms_tagged(v_2)}}

def template_match_434(+v_1002506: Bool, +v_1: cps_provider_1_Context, +v_3: String, v_16: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1002506:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reenters{v_1, v_3, v_16, v_8, v_10}}, v_1002508 => +v_1002507 = template_unbox(Bool, v_1002508); TemplateFinished{TemplateValue{v_1002507}}}

def template_match_435(+v_1002510: Bool, +v_1: cps_provider_1_Context, +v_20: List<&2, BIR.DescriptorField>, +v_8: List<&2, cps_provider_2_NfVal>, +v_3: String, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1002510:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_reach{v_1, v_20, v_8, v_3, [], v_10}}, v_1002512 => +v_1002511 = template_unbox(Bool, v_1002512); TemplateFinished{TemplateValue{v_1002511}}}

def template_match_436(+v_1002505: Bool, +v_1: cps_provider_1_Context, +v_20: List<&2, BIR.DescriptorField>, +v_8: List<&2, cps_provider_2_NfVal>, +v_3: String, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  match v_1002505:
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_reach{v_1, v_20, v_8, v_3, [], v_10}}, v_1002509 => +v_1002506 = template_unbox(Bool, v_1002509); template_match_434(v_1002506, v_1, v_3, v_16, v_8, v_10)}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reenters{v_1, v_3, v_16, v_8, v_10}}, v_1002513 => +v_1002510 = template_unbox(Bool, v_1002513); template_match_435(v_1002510, v_1, v_20, v_8, v_3, v_10)}

def template_match_437(+v_15: BIR.DescriptorArm, +v_3: String, +v_1: cps_provider_1_Context, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  match v_15:
    case BIR.DescriptorArm{+v_19, +v_20}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_self_reference{v_20, v_3}}, v_1002514 => +v_1002505 = template_unbox(Bool, v_1002514); template_match_436(v_1002505, v_1, v_20, v_8, v_3, v_10, v_16)}

def template_body_cps_provider_1_reenters(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_5:
    case []:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_args_reach{v_1, v_8, v_3, [], v_10}}, v_1003261 => +v_1003262 = template_unbox(Bool, v_1003261); TemplateFinished{TemplateValue{v_1003262}}}
    case +v_1003263 <> v_1003264:
      template_match_437(v_1003263, v_3, v_1, v_8, v_10, v_1003264)

def template_match_439(v_1002518: Bool, v_8: List<&2, BIR.DescriptorField>, +v_3: String) -> TemplateProgress<Bool>:
  match v_1002518:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_self_reference{v_8, v_3}}, v_1002520 => +v_1002519 = template_unbox(Bool, v_1002520); TemplateFinished{TemplateValue{v_1002519}}}

def template_match_440(+v_14: BIR.Descriptor, +v_3: String, v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_14:
    case BIR.DescriptorRef{+v_19, +v_20}:
      v_1002518 = {String.eq(v_19, v_3) : Bool}
      template_match_439(v_1002518, v_8, v_3)
    case _:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_self_reference{v_8, v_3}}, v_1002522 => +v_1002521 = template_unbox(Bool, v_1002522); TemplateFinished{TemplateValue{v_1002521}}}

def template_match_441(v_1002515: Bool, v_8: List<&2, BIR.DescriptorField>, +v_3: String, +v_14: BIR.Descriptor) -> TemplateProgress<Bool>:
  match v_1002515:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_self_reference{v_8, v_3}}, v_1002517 => +v_1002516 = template_unbox(Bool, v_1002517); TemplateFinished{TemplateValue{v_1002516}}}
    case True{}:
      template_match_440(v_14, v_3, v_8)

def template_match_442(+v_7: BIR.DescriptorField, v_8: List<&2, BIR.DescriptorField>, +v_3: String) -> TemplateProgress<Bool>:
  match v_7:
    case BIR.DescriptorField{+v_12, +v_13, +v_14}:
      v_1002515 = {template_pure_cps_provider_1_live_field(v_13) : Bool}
      template_match_441(v_1002515, v_8, v_3, v_14)

def template_body_cps_provider_1_fields_self_reference(+v_1: List<&2, BIR.DescriptorField>, +v_3: String) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_7 <> v_8:
      template_match_442(v_7, v_8, v_3)

def template_match_444(+v_1002527: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_27: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_1002527:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_reach{v_1, v_18, v_27, v_8, v_11, v_13}}, v_1002529 => +v_1002528 = template_unbox(Bool, v_1002529); TemplateFinished{TemplateValue{v_1002528}}}

def template_match_445(v_1002524: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_27: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, +v_24: BIR.Descriptor, +v_6: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<Bool>:
  match v_1002524:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_reach{v_1, v_18, v_27, v_8, v_11, v_13}}, v_1002526 => +v_1002525 = template_unbox(Bool, v_1002526); TemplateFinished{TemplateValue{v_1002525}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reaches{v_1, v_24, v_6, v_8, v_11, v_13}}, v_1002530 => +v_1002527 = template_unbox(Bool, v_1002530); template_match_444(v_1002527, v_1, v_18, v_27, v_8, v_11, v_13)}

def template_continuation_446(+v_1002523: List<&2, cps_provider_2_NfVal>, +v_23: BIR.Quantity, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, +v_24: BIR.Descriptor, +v_6: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<Bool>:
  v_1002524 = {template_pure_cps_provider_1_live_field(v_23) : Bool}
  template_match_445(v_1002524, v_1, v_18, v_1002523, v_8, v_11, v_13, v_24, v_6)

def template_match_447(+v_17: BIR.DescriptorField, +v_6: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_17:
    case BIR.DescriptorField{+v_22, +v_23, +v_24}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_field_scope{v_6}}, False{}, v_1002532 => template_body_cps_provider_1_field_scope(v_6), v_1002531 => +v_1002523 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002531); template_continuation_446(v_1002523, v_23, v_1, v_18, v_8, v_11, v_13, v_24, v_6)}

def template_body_cps_provider_1_fields_reach(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1003265 <> v_1003266:
      template_match_447(v_1003265, v_6, v_1, v_1003266, v_8, v_11, v_13)

def template_match_449(+v_1002534: cps_provider_2_Nf, +v_1: cps_provider_1_Context, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_1002534:
    case cps_provider_2_NfFail{+v_16}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_2_NfOk{+v_18}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reaches_val{v_1, v_18, v_7, v_10, Nat.sub(v_12, 1n)}}, v_1002536 => +v_1002535 = template_unbox(Bool, v_1002536); TemplateFinished{TemplateValue{v_1002535}}}

def template_match_450(v_1002533: Bool, +v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_7: String, +v_10: List<&2, String>) -> TemplateProgress<Bool>:
  match v_1002533:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, v_5, v_12}}, False{}, v_1002538 => template_body_cps_provider_1_nf_of(v_1, v_2, v_5, v_12), v_1002537 => +v_1002534 = template_unbox(cps_provider_2_Nf, v_1002537); template_match_449(v_1002534, v_1, v_7, v_10, v_12)}

def template_body_cps_provider_1_reaches(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  v_1002533 = {Nat.is_eq(v_12, 0n) : Bool}
  template_match_450(v_1002533, v_1, v_2, v_5, v_12, v_7, v_10)

def template_match_451(+v_1002544: Bool, +v_1: cps_provider_1_Context, +v_15: List<&2, cps_provider_2_NfVal>, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1002544:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_args_reach{v_1, v_15, v_5, v_8, v_10}}, v_1002546 => +v_1002545 = template_unbox(Bool, v_1002546); TemplateFinished{TemplateValue{v_1002545}}}

def template_match_452(+v_1002541: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_15: List<&2, cps_provider_2_NfVal>, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String) -> TemplateProgress<Bool>:
  match v_1002541:
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_args_reach{v_1, v_15, v_5, v_8, v_10}}, v_1002543 => +v_1002542 = template_unbox(Bool, v_1002543); TemplateFinished{TemplateValue{v_1002542}}}
    case Some{+v_20}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_family_reach{v_1, v_20, v_15, v_5, v_14 <> v_8, v_10}}, v_1002547 => +v_1002544 = template_unbox(Bool, v_1002547); template_match_451(v_1002544, v_1, v_15, v_5, v_8, v_10)}

def template_match_453(+v_1002540: Bool, +v_1: cps_provider_1_Context, +v_14: String, +v_15: List<&2, cps_provider_2_NfVal>, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1002540:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_family_lookup{v_1, v_14}}, False{}, v_1002549 => template_body_cps_provider_1_family_lookup(v_1, v_14), v_1002548 => +v_1002541 = template_unbox(Maybe<&2, BIR.Family>, v_1002548); template_match_452(v_1002541, v_1, v_15, v_5, v_8, v_10, v_14)}

def template_match_454(v_1002539: Bool, +v_8: List<&2, String>, +v_14: String, +v_1: cps_provider_1_Context, +v_15: List<&2, cps_provider_2_NfVal>, +v_5: String, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1002539:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_str_member{v_8, v_14}}, v_1002550 => +v_1002540 = template_unbox(Bool, v_1002550); template_match_453(v_1002540, v_1, v_14, v_15, v_5, v_8, v_10)}

def template_body_cps_provider_1_reaches_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_3:
    case cps_provider_2_NfType{+v_1003267, +v_1003268}:
      v_1003269 = {String.eq(v_1003267, v_5) : Bool}
      template_match_454(v_1003269, v_8, v_1003267, v_1, v_1003268, v_5, v_10)
    case v_1003270:
      TemplateFinished{TemplateValue{False{}}}

def template_match_456(v_1002552: Bool, +v_1: cps_provider_1_Context, +v_25: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_1002552:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reach_arms{v_1, v_25, v_5, v_7, v_10, v_12}}, v_1002554 => +v_1002553 = template_unbox(Bool, v_1002554); TemplateFinished{TemplateValue{v_1002553}}}

def template_match_457(+v_22: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_25: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_22:
    case Some{+v_28}:
      v_1002552 = {String.eq(v_28, "Array") : Bool}
      template_match_456(v_1002552, v_1, v_25, v_5, v_7, v_10, v_12)
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reach_arms{v_1, v_25, v_5, v_7, v_10, v_12}}, v_1002556 => +v_1002555 = template_unbox(Bool, v_1002556); TemplateFinished{TemplateValue{v_1002555}}}

def template_match_458(v_1002551: Bool, +v_22: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_25: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_1002551:
    case False{}:
      TemplateFinished{TemplateValue{False{}}}
    case True{}:
      template_match_457(v_22, v_1, v_25, v_5, v_7, v_10, v_12)

def template_body_cps_provider_1_family_reach(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_2:
    case BIR.Family{+v_1003271, +v_1003272, +v_1003273, +v_1003274, +v_1003275, +v_1003276}:
      v_1003277 = {Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_5), v_1003275) : Bool}
      template_match_458(v_1003277, v_1003273, v_1, v_1003276, v_5, v_7, v_10, v_12)

def template_match_460(+v_1002557: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_1002557:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reach_arms{v_1, v_18, v_6, v_8, v_11, v_13}}, v_1002559 => +v_1002558 = template_unbox(Bool, v_1002559); TemplateFinished{TemplateValue{v_1002558}}}

def template_match_461(+v_17: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  match v_17:
    case BIR.DescriptorArm{+v_21, +v_22}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_fields_reach{v_1, v_22, v_6, v_8, v_11, v_13}}, False{}, v_1002561 => template_body_cps_provider_1_fields_reach(v_1, v_22, v_6, v_8, v_11, v_13), v_1002560 => +v_1002557 = template_unbox(Bool, v_1002560); template_match_460(v_1002557, v_1, v_18, v_6, v_8, v_11, v_13)}

def template_body_cps_provider_1_reach_arms(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1003278 <> v_1003279:
      template_match_461(v_1003278, v_1, v_6, v_8, v_11, v_13, v_1003279)

def template_match_463(+v_1002562: Bool, +v_1: cps_provider_1_Context, v_16: List<&2, cps_provider_2_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> TemplateProgress<Bool>:
  match v_1002562:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_args_reach{v_1, v_16, v_6, v_9, v_11}}, v_1002564 => +v_1002563 = template_unbox(Bool, v_1002564); TemplateFinished{TemplateValue{v_1002563}}}

def template_body_cps_provider_1_args_reach(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> TemplateProgress<Bool>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1003280 <> v_1003281:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_reaches_val{v_1, v_1003280, v_6, v_9, v_11}}, False{}, v_1003282 => template_body_cps_provider_1_reaches_val(v_1, v_1003280, v_6, v_9, v_11), v_1003283 => +v_1003284 = template_unbox(Bool, v_1003283); template_match_463(v_1003284, v_1, v_1003281, v_6, v_9, v_11)}

def template_match_465(v_1002567: Bool, v_9: List<&2, String>, +v_4: String) -> TemplateProgress<Bool>:
  match v_1002567:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_str_member{v_9, v_4}}, v_1002569 => +v_1002568 = template_unbox(Bool, v_1002569); TemplateFinished{TemplateValue{v_1002568}}}

def template_body_cps_provider_1_str_member(+v_2: List<&2, String>, +v_4: String) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_8 <> v_9:
      v_1002567 = {String.eq(v_8, v_4) : Bool}
      template_match_465(v_1002567, v_9, v_4)

def template_body_cps_provider_1_layout_kinds(+v_1: cps_provider_1_Layout) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1:
    case cps_provider_1_LayoutWord{+v_5}:
      TemplateFinished{TemplateValue{[v_5]}}
    case cps_provider_1_LayoutBox{+v_7}:
      TemplateFinished{TemplateValue{[cps_provider_1_CWordBox{}]}}
    case cps_provider_1_LayoutData{+v_10, +v_11}:
      TemplateFinished{TemplateValue{v_10}}

def template_body_cps_provider_1_layout_words(+v_1: cps_provider_1_Layout) -> TemplateProgress<Nat>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_kinds{v_1}}, False{}, v_1002572 => template_body_cps_provider_1_layout_kinds(v_1), v_1002571 => +v_1002570 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002571); TemplateFinished{TemplateValue{List.length(&2, cps_provider_1_CWord, v_1002570)}}}

def template_body_cps_provider_1_canonical_word(+v_1: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_CWord>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_canonical_word(v_1)}}

def template_body_cps_provider_1_pack_arms(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Bool) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_4:
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_arm_list{v_2, 1n, [cps_provider_1_CWord32{}]}}, v_1003285 => +v_1003286 = template_unbox(List<&2, cps_provider_1_CWord>, v_1003285); TemplateFinished{TemplateValue{v_1003286}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_arm_list{v_2, 0n, []}}, v_1003287 => +v_1003288 = template_unbox(List<&2, cps_provider_1_CWord>, v_1003287); TemplateFinished{TemplateValue{v_1003288}}}

def template_match_469(+v_12: cps_provider_1_LayArm, v_13: List<&2, cps_provider_1_LayArm>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_12:
    case cps_provider_1_LayArm{+v_16, +v_17}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_field_list{v_17, v_4, v_7}}, v_1002582 => +v_1002579 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002582); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_arm_list{{v_13 : List<&2, cps_provider_1_LayArm>}, {v_4 : Nat}, v_1002579}}, v_1002581 => +v_1002580 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002581); TemplateFinished{TemplateValue{v_1002580}}}}

def template_body_cps_provider_1_pack_arm_list(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_7}}
    case +v_1003289 <> v_1003290:
      template_match_469(v_1003289, v_1003290, v_4, v_7)

def template_continuation_471(+v_1002583: List<&2, cps_provider_1_CWord>, v_13: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  +v_1002585 = {Nat.add(v_4, List.length(&2, cps_provider_1_CWord, v_1002583)) : Nat}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_kinds{v_1002583, v_4, v_7}}, v_1002589 => +v_1002586 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002589); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_field_list{{v_13 : List<&2, cps_provider_1_Layout>}, v_1002585, v_1002586}}, v_1002588 => +v_1002587 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002588); TemplateFinished{TemplateValue{v_1002587}}}}

def template_body_cps_provider_1_pack_field_list(+v_2: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_7}}
    case +v_1003291 <> v_1003292:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_kinds{v_1003291}}, False{}, v_1003293 => template_body_cps_provider_1_layout_kinds(v_1003291), v_1003294 => +v_1003295 = template_unbox(List<&2, cps_provider_1_CWord>, v_1003294); template_continuation_471(v_1003295, v_1003292, v_4, v_7)}

def template_body_cps_provider_1_pack_kinds(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_7}}
    case +v_1003296 <> v_1003297:
      +v_1003299 = {Nat.add(v_4, 1n) : Nat}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_set_kind{v_7, v_4, v_1003296}}, v_1003300 => +v_1003301 = template_unbox(List<&2, cps_provider_1_CWord>, v_1003300); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pack_kinds{{v_1003297 : List<&2, cps_provider_1_CWord>}, v_1003299, v_1003301}}, v_1003302 => +v_1003303 = template_unbox(List<&2, cps_provider_1_CWord>, v_1003302); TemplateFinished{TemplateValue{v_1003303}}}}

def template_body_cps_provider_1_set_kind(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_6: cps_provider_1_CWord) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2, v_4:
    case [], 0n:
      TemplateFinished{TemplateValue{[template_pure_cps_provider_1_merge_kind(cps_provider_1_CWord32{}, v_6)]}}
    case +v_12 <> v_13, 0n:
      TemplateFinished{TemplateValue{template_pure_cps_provider_1_merge_kind(v_12, v_6) <> v_13}}
    case [], 1n+v_16:
      v_1002598 = {cps_provider_1_CWord32{} : cps_provider_1_CWord}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_set_kind{[], v_16, v_6}}, v_1002600 => +v_1002599 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002600); TemplateFinished{TemplateValue{v_1002598 <> v_1002599}}}
    case +v_21 <> v_22, 1n+v_23:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_set_kind{v_22, v_23, v_6}}, v_1002603 => +v_1002602 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002603); TemplateFinished{TemplateValue{{v_21 : cps_provider_1_CWord} <> v_1002602}}}

def template_body_cps_provider_1_merge_kind(+v_1: cps_provider_1_CWord, +v_3: cps_provider_1_CWord) -> TemplateProgress<cps_provider_1_CWord>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_merge_kind(v_1, v_3)}}

def template_body_cps_provider_1_word_32(+v_1: cps_provider_1_CWord) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_word_32(v_1)}}

def template_match_475(v_1002606: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_10: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1002606:
    case True{}:
      TemplateFinished{TemplateValue{v_2}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pad_to{v_2, v_10}}, v_1002608 => +v_1002607 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002608); TemplateFinished{TemplateValue{v_1002607}}}

def template_continuation_476(+v_1002605: Nat, +v_7: Nat, +v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  v_1002606 = {Nat.is_eq(v_1002605, v_7) : Bool}
  template_match_475(v_1002606, v_2, v_1002605)

def template_match_477(v_1002604: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_7: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1002604:
    case False{}:
      TemplateFinished{TemplateValue{v_2}}
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pow2_upto{1n, v_7}}, v_1002609 => +v_1002605 = template_unbox(Nat, v_1002609); template_continuation_476(v_1002605, v_7, v_2)}

def template_body_cps_provider_1_pad_words(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  +v_7 = List.length(&2, cps_provider_1_CWord, v_2)
  v_1002604 = {Nat.is_gt(v_7, 247n) : Bool}
  template_match_477(v_1002604, v_2, v_7)

def template_match_478(v_1002610: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1002610:
    case True{}:
      TemplateFinished{TemplateValue{v_2}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pad_to{List.append(&2, cps_provider_1_CWord, v_2, [cps_provider_1_CWord32{}]), v_4}}, v_1002612 => +v_1002611 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002612); TemplateFinished{TemplateValue{v_1002611}}}

def template_body_cps_provider_1_pad_to(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  v_1002610 = {Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_2), v_4) : Bool}
  template_match_478(v_1002610, v_2, v_4)

def template_match_479(v_1002613: Bool, +v_1: Nat, +v_3: Nat) -> TemplateProgress<Nat>:
  match v_1002613:
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pow2_upto{Nat.mul(v_1, 2n), v_3}}, v_1002615 => +v_1002614 = template_unbox(Nat, v_1002615); TemplateFinished{TemplateValue{v_1002614}}}
    case False{}:
      TemplateFinished{TemplateValue{v_1}}

def template_body_cps_provider_1_pow2_upto(+v_1: Nat, +v_3: Nat) -> TemplateProgress<Nat>:
  v_1002613 = {Nat.is_lt(v_1, v_3) : Bool}
  template_match_479(v_1002613, v_1, v_3)

def template_match_480(v_1002616: Bool, +v_1: Nat) -> TemplateProgress<Nat>:
  match v_1002616:
    case False{}:
      TemplateFinished{TemplateValue{0n}}
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2_go{1n, 0n, v_1}}, v_1002618 => +v_1002617 = template_unbox(Nat, v_1002618); TemplateFinished{TemplateValue{v_1002617}}}

def template_body_cps_provider_1_ceil_log2(+v_1: Nat) -> TemplateProgress<Nat>:
  v_1002616 = {Nat.is_gt(v_1, 1n) : Bool}
  template_match_480(v_1002616, v_1)

def template_match_481(v_1002620: Bool, +v_1: Nat, +v_3: Nat, +v_5: Nat) -> TemplateProgress<Nat>:
  match v_1002620:
    case True{}:
      TemplateFinished{TemplateValue{31n}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2_go{Nat.mul(v_1, 2n), Nat.add(v_3, 1n), v_5}}, v_1002622 => +v_1002621 = template_unbox(Nat, v_1002622); TemplateFinished{TemplateValue{v_1002621}}}

def template_match_482(v_1002619: Bool, +v_3: Nat, +v_1: Nat, +v_5: Nat) -> TemplateProgress<Nat>:
  match v_1002619:
    case True{}:
      v_1002620 = {Nat.is_gt(v_3, 30n) : Bool}
      template_match_481(v_1002620, v_1, v_3, v_5)
    case False{}:
      TemplateFinished{TemplateValue{v_3}}

def template_body_cps_provider_1_ceil_log2_go(+v_1: Nat, +v_3: Nat, +v_5: Nat) -> TemplateProgress<Nat>:
  v_1002619 = {Nat.is_lt(v_1, v_5) : Bool}
  template_match_482(v_1002619, v_3, v_1, v_5)

def template_body_cps_provider_1_node_layout(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1002629 => template_body_cps_provider_1_layout_fuel, v_1002628 => +v_1002625 = template_unbox(Nat, v_1002628); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_at{{v_1 : cps_provider_1_Context}, {v_3 : String}, v_1002625}}, v_1002627 => +v_1002626 = template_unbox(cps_provider_1_NodeResult, v_1002627); TemplateFinished{TemplateValue{v_1002626}}}}

def template_body_cps_provider_1_node_layout_fuel(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_at{v_1, v_3, v_5}}, v_1002631 => +v_1002630 = template_unbox(cps_provider_1_NodeResult, v_1002631); TemplateFinished{TemplateValue{v_1002630}}}

def template_match_483(v_1002634: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1002634:
    case True{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_plan_node{v_1, v_3}}, v_1002636 => +v_1002635 = template_unbox(cps_provider_1_NodeResult, v_1002636); TemplateFinished{TemplateValue{v_1002635}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_compute{v_1, v_3, v_5}}, v_1002638 => +v_1002637 = template_unbox(cps_provider_1_NodeResult, v_1002638); TemplateFinished{TemplateValue{v_1002637}}}

def template_continuation_484(v_1002632: Nat, +v_1002633: Nat, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  v_1002634 = {Nat.is_eq(v_1002632, v_1002633) : Bool}
  template_match_483(v_1002634, v_1, v_3, v_5)

def template_body_cps_provider_1_node_at(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1002640 => template_body_cps_provider_1_layout_fuel, v_1002639 => +v_1002633 = template_unbox(Nat, v_1002639); template_continuation_484({v_5 : Nat}, v_1002633, v_1, v_3, v_5)}

def template_match_485(v_1002642: Maybe<&2, cps_provider_1_NodeResult>, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1002642:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{v_8}}
    case None{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_declared{v_1, v_3}}, v_1002644 => +v_1002643 = template_unbox(cps_provider_1_NodeResult, v_1002644); TemplateFinished{TemplateValue{v_1002643}}}

def template_continuation_486(+v_1002641: Map<&2, cps_provider_1_NodeResult>, +v_3: String, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_NodeResult>:
  v_1002642 = {IndexLookup.find(cps_provider_1_NodeResult, v_1002641, v_3) : Maybe<&2, cps_provider_1_NodeResult>}
  template_match_485(v_1002642, v_1, v_3)

def template_body_cps_provider_1_plan_node(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_context_nodes{v_1}}, False{}, v_1002646 => template_body_cps_provider_1_context_nodes(v_1), v_1002645 => +v_1002641 = template_unbox(Map<&2, cps_provider_1_NodeResult>, v_1002645); template_continuation_486(v_1002641, v_3, v_1)}

def template_match_487(+v_1002647: Maybe<&2, BIR.DescriptorArm>, +v_3: String, +v_1: cps_provider_1_Context, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1002647:
    case None{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_unresolved_message{v_3}}, v_1002649 => +v_1002648 = template_unbox(String, v_1002649); TemplateFinished{TemplateValue{cps_provider_1_NodeFailed{v_1002648}}}}
    case Some{+v_11}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_arm{v_1, v_11, v_5}}, v_1002651 => +v_1002650 = template_unbox(cps_provider_1_NodeResult, v_1002651); TemplateFinished{TemplateValue{v_1002650}}}

def template_body_cps_provider_1_node_compute(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_of{v_3, template_pure_cps_provider_1_context_families(v_1)}}, False{}, v_1002653 => template_body_cps_provider_1_arm_of(v_3, template_pure_cps_provider_1_context_families(v_1)), v_1002652 => +v_1002647 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1002652); template_match_487(v_1002647, v_3, v_1, v_5)}

def template_body_cps_provider_1_unresolved_message(+v_1: String) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{String.append("the constructor `", String.append(v_1, "` is in no declared family arm"))}}

def template_match_488(+v_1002654: cps_provider_1_Slots) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1002654:
    case cps_provider_1_SlotsFail{+v_12}:
      TemplateFinished{TemplateValue{cps_provider_1_NodeFailed{v_12}}}
    case cps_provider_1_SlotsOk{+v_14}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_finish{v_14}}, v_1002656 => +v_1002655 = template_unbox(cps_provider_1_NodeResult, v_1002656); TemplateFinished{TemplateValue{v_1002655}}}

def template_body_cps_provider_1_node_arm(+v_1: cps_provider_1_Context, +v_2: BIR.DescriptorArm, +v_4: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_2:
    case BIR.DescriptorArm{+v_1003304, +v_1003305}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_slots{v_1, v_1003305, 0, 0n, v_4, []}}, v_1003306 => +v_1003307 = template_unbox(cps_provider_1_Slots, v_1003306); template_match_488(v_1003307)}

def template_continuation_490(+v_16: String, +v_1: cps_provider_1_Context, +v_1002658: Map<&2, cps_provider_1_NodeResult>) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_declared{v_1, v_16}}, v_1002661 => +v_1002660 = template_unbox(cps_provider_1_NodeResult, v_1002661); TemplateFinished{TemplateValue{Map.set(&2, cps_provider_1_NodeResult, v_1002658, {v_16 : String}, v_1002660)}}}

def template_match_491(+v_9: BIR.ConstructorLayout, +v_1: cps_provider_1_Context, v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  match v_9:
    case BIR.ConstructorLayout{+v_15, +v_16, +v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_plan_node_index{v_1, v_10}}, v_1002662 => +v_1002658 = template_unbox(Map<&2, cps_provider_1_NodeResult>, v_1002662); template_continuation_490(v_16, v_1, v_1002658)}

def template_body_cps_provider_1_plan_node_index(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, cps_provider_1_NodeResult)}}
    case +v_1003308 <> v_1003309:
      template_match_491(v_1003308, v_1, v_1003309)

def template_match_493(+v_1002663: Maybe<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1002663:
    case Some{+v_7}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1002669 => template_body_cps_provider_1_layout_fuel, v_1002668 => +v_1002666 = template_unbox(Nat, v_1002668); template_body_cps_provider_1_node_arm({v_1 : cps_provider_1_Context}, {v_7 : BIR.DescriptorArm}, v_1002666)}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_unresolved_message{v_3}}, False{}, v_1002672 => template_body_cps_provider_1_unresolved_message(v_3), v_1002671 => +v_1002670 = template_unbox(String, v_1002671); TemplateFinished{TemplateValue{cps_provider_1_NodeFailed{v_1002670}}}}

def template_body_cps_provider_1_node_declared(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_declared{v_1, v_3}}, False{}, v_1002674 => template_body_cps_provider_1_arm_declared(v_1, v_3), v_1002673 => +v_1002663 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1002673); template_match_493(v_1002663, v_1, v_3)}

def template_match_494(+v_1002678: cps_provider_1_LayoutResult, +v_5: U32, +v_7: Nat, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_Slots>:
  match v_1002678:
    case cps_provider_1_LayoutFailed{+v_29}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotsFail{v_29}}}
    case cps_provider_1_LayoutFound{+v_31}:
      +v_34 = {cps_provider_1_NodeSlot{v_5, v_7, v_31} : cps_provider_1_NodeSlot}
      +v_1002681 = {U32.inc(v_5) : U32}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_words{v_31}}, False{}, v_1002687 => template_body_cps_provider_1_layout_words(v_31), v_1002686 => +v_1002683 = template_unbox(Nat, v_1002686); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_slots{{v_1 : cps_provider_1_Context}, {v_18 : List<&2, BIR.DescriptorField>}, v_1002681, Nat.add({v_7 : Nat}, v_1002683), v_9, v_34 <> v_12}}, v_1002685 => +v_1002684 = template_unbox(cps_provider_1_Slots, v_1002685); TemplateFinished{TemplateValue{v_1002684}}}}

def template_match_495(v_1002675: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>, +v_24: BIR.Descriptor) -> TemplateProgress<cps_provider_1_Slots>:
  match v_1002675:
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_slots{v_1, v_18, U32.inc(v_5), v_7, v_9, v_12}}, v_1002677 => +v_1002676 = template_unbox(cps_provider_1_Slots, v_1002677); TemplateFinished{TemplateValue{v_1002676}}}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_of_desc{v_1, v_24, [], v_9}}, False{}, v_1002689 => template_body_cps_provider_1_layout_of_desc(v_1, v_24, [], v_9), v_1002688 => +v_1002678 = template_unbox(cps_provider_1_LayoutResult, v_1002688); template_match_494(v_1002678, v_5, v_7, v_1, v_18, v_9, v_12)}

def template_match_496(+v_17: BIR.DescriptorField, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_Slots>:
  match v_17:
    case BIR.DescriptorField{+v_22, +v_23, +v_24}:
      v_1002675 = {template_pure_cps_provider_1_live_field(v_23) : Bool}
      template_match_495(v_1002675, v_1, v_18, v_5, v_7, v_9, v_12, v_24)

def template_body_cps_provider_1_node_slots(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_Slots>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_SlotsOk{List.reverse(&2, cps_provider_1_NodeSlot, v_12)}}}
    case +v_1003310 <> v_1003311:
      template_match_496(v_1003310, v_1, v_1003311, v_5, v_7, v_9, v_12)

def template_continuation_498(+v_1002691: List<&2, cps_provider_1_CWord>, +v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_packed_words{v_1002691}}, v_1002695 => +v_1002694 = template_unbox(Bool, v_1002695); TemplateFinished{TemplateValue{cps_provider_1_NodeFound{cps_provider_1_Node{{v_1002691 : List<&2, cps_provider_1_CWord>}, {v_2 : List<&2, cps_provider_1_NodeSlot>}, v_1002694}}}}}

def template_body_cps_provider_1_node_finish(+v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_NodeFound{cps_provider_1_Node{[], [], True{}}}}}
    case _:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_slot_words{v_2}}, v_1002698 => +v_1002690 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002698); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_pad_words{v_1002690}}, False{}, v_1002697 => template_body_cps_provider_1_pad_words(v_1002690), v_1002696 => +v_1002691 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002696); template_continuation_498(v_1002691, v_2)}}

def template_match_500(+v_7: cps_provider_1_NodeSlot, v_8: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_7:
    case cps_provider_1_NodeSlot{+v_12, +v_13, +v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_kinds{v_14}}, False{}, v_1002703 => template_body_cps_provider_1_layout_kinds(v_14), v_1002702 => +v_1002699 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002702); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_slot_words{v_8}}, v_1002701 => +v_1002700 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002701); TemplateFinished{TemplateValue{List.append(&2, cps_provider_1_CWord, v_1002699, v_1002700)}}}}

def template_body_cps_provider_1_slot_words(+v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_7 <> v_8:
      template_match_500(v_7, v_8)

def template_match_502(v_7: List<&2, cps_provider_1_CWord>, +v_6: cps_provider_1_CWord) -> TemplateProgress<Bool>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{template_pure_cps_provider_1_word_32(v_6)}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_cps_provider_1_packed_words(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{True{}}}
    case +v_6 <> v_7:
      template_match_502(v_7, v_6)

def template_match_504(+v_1002705: Maybe<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_SlotResult>:
  match v_1002705:
    case Some{+v_20}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotFound{v_20}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotErased{}}}

def template_match_505(+v_11: cps_provider_1_Node, +v_5: U32) -> TemplateProgress<cps_provider_1_SlotResult>:
  match v_11:
    case cps_provider_1_Node{+v_15, +v_16, +v_17}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_slot_find{v_16, v_5}}, v_1002706 => +v_1002705 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1002706); template_match_504(v_1002705)}

def template_match_506(+v_1002704: cps_provider_1_NodeResult, +v_5: U32) -> TemplateProgress<cps_provider_1_SlotResult>:
  match v_1002704:
    case cps_provider_1_NodeFailed{+v_9}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotFailed{v_9}}}
    case cps_provider_1_NodeFound{+v_11}:
      template_match_505(v_11, v_5)

def template_body_cps_provider_1_node_slot(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> TemplateProgress<cps_provider_1_SlotResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout{v_1, v_3}}, False{}, v_1002708 => template_body_cps_provider_1_node_layout(v_1, v_3), v_1002707 => +v_1002704 = template_unbox(cps_provider_1_NodeResult, v_1002707); template_match_506(v_1002704, v_5)}

def template_match_507(v_1002709: Bool, +v_9: cps_provider_1_NodeSlot, v_10: List<&2, cps_provider_1_NodeSlot>, +v_4: U32) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_1002709:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_9}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_slot_find{v_10, v_4}}, v_1002711 => +v_1002710 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1002711); TemplateFinished{TemplateValue{v_1002710}}}

def template_match_508(+v_9: cps_provider_1_NodeSlot, +v_4: U32, v_10: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_9:
    case cps_provider_1_NodeSlot{+v_14, +v_15, +v_16}:
      v_1002709 = {U32.is_eq(v_4, v_14) : Bool}
      template_match_507(v_1002709, v_9, v_10, v_4)

def template_body_cps_provider_1_slot_find(+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: U32) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_9 <> v_10:
      template_match_508(v_9, v_4, v_10)

def template_body_cps_provider_1_layout_fill(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_FillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1002718 => template_body_cps_provider_1_layout_fuel, v_1002717 => +v_1002714 = template_unbox(Nat, v_1002717); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_fill_fuel{{v_1 : cps_provider_1_Context}, {v_3 : cps_provider_1_Layout}, v_1002714}}, v_1002716 => +v_1002715 = template_unbox(cps_provider_1_FillResult, v_1002716); TemplateFinished{TemplateValue{v_1002715}}}}

def template_match_510(+v_1002719: cps_provider_1_Arms, +v_13: List<&2, cps_provider_1_CWord>) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_1002719:
    case cps_provider_1_ArmsFail{+v_19}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFailed{v_19}}}
    case cps_provider_1_ArmsOk{+v_21}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFound{cps_provider_1_FillForm{List.length(&2, cps_provider_1_CWord, v_13), v_21}}}}

def template_body_cps_provider_1_layout_fill_fuel(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_3:
    case cps_provider_1_LayoutWord{+v_1003312}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFound{cps_provider_1_FillWord{}}}}
    case cps_provider_1_LayoutBox{+v_1003313}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFound{cps_provider_1_FillWord{}}}}
    case cps_provider_1_LayoutData{+v_1003314, +v_1003315}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_form_arms{v_1, v_1003315, 0n, Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_1003315), 1n), List.length(&2, cps_provider_1_CWord, v_1003314), v_5, [], True{}}}, v_1003316 => +v_1003317 = template_unbox(cps_provider_1_Arms, v_1003316); template_match_510(v_1003317, v_1003314)}

def template_body_cps_provider_1_layout_unfill(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_UnfillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1002727 => template_body_cps_provider_1_layout_fuel, v_1002726 => +v_1002723 = template_unbox(Nat, v_1002726); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_unfill_fuel{{v_1 : cps_provider_1_Context}, {v_3 : cps_provider_1_Layout}, v_1002723}}, v_1002725 => +v_1002724 = template_unbox(cps_provider_1_UnfillResult, v_1002725); TemplateFinished{TemplateValue{v_1002724}}}}

def template_match_512(+v_1002728: cps_provider_1_Arms, +v_13: List<&2, cps_provider_1_CWord>) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_1002728:
    case cps_provider_1_ArmsFail{+v_19}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFailed{v_19}}}
    case cps_provider_1_ArmsOk{+v_21}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFound{cps_provider_1_UnfillForm{List.length(&2, cps_provider_1_CWord, v_13), v_21}}}}

def template_body_cps_provider_1_layout_unfill_fuel(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_3:
    case cps_provider_1_LayoutWord{+v_1003318}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFound{cps_provider_1_UnfillWord{}}}}
    case cps_provider_1_LayoutBox{+v_1003319}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFound{cps_provider_1_UnfillWord{}}}}
    case cps_provider_1_LayoutData{+v_1003320, +v_1003321}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_form_arms{v_1, v_1003321, 0n, Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_1003321), 1n), List.length(&2, cps_provider_1_CWord, v_1003320), v_5, [], False{}}}, v_1003322 => +v_1003323 = template_unbox(cps_provider_1_Arms, v_1003322); template_match_512(v_1003323, v_1003320)}

def template_match_514(+v_9: cps_provider_1_NodeSlot, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_9:
    case cps_provider_1_NodeSlot{+v_13, +v_14, +v_15}:
      template_body_cps_provider_1_layout_fill(v_1, v_15)

def template_match_515(+v_1002730: cps_provider_1_SlotResult, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_1002730:
    case cps_provider_1_SlotFound{+v_9}:
      template_match_514(v_9, v_1)
    case cps_provider_1_SlotErased{}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFailed{String.append("the constructor `", String.append(v_3, "` field slot is erased and has no storage"))}}}
    case cps_provider_1_SlotFailed{+v_18}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFailed{v_18}}}

def template_body_cps_provider_1_slot_fill(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> TemplateProgress<cps_provider_1_FillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_slot{v_1, v_3, v_5}}, False{}, v_1002733 => template_body_cps_provider_1_node_slot(v_1, v_3, v_5), v_1002732 => +v_1002730 = template_unbox(cps_provider_1_SlotResult, v_1002732); template_match_515(v_1002730, v_1, v_3)}

def template_match_516(+v_9: cps_provider_1_NodeSlot, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_9:
    case cps_provider_1_NodeSlot{+v_13, +v_14, +v_15}:
      template_body_cps_provider_1_layout_unfill(v_1, v_15)

def template_match_517(+v_1002734: cps_provider_1_SlotResult, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_1002734:
    case cps_provider_1_SlotFound{+v_9}:
      template_match_516(v_9, v_1)
    case cps_provider_1_SlotErased{}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFailed{String.append("the constructor `", String.append(v_3, "` field slot is erased and has no storage"))}}}
    case cps_provider_1_SlotFailed{+v_18}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFailed{v_18}}}

def template_body_cps_provider_1_slot_unfill(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> TemplateProgress<cps_provider_1_UnfillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_node_slot{v_1, v_3, v_5}}, False{}, v_1002737 => template_body_cps_provider_1_node_slot(v_1, v_3, v_5), v_1002736 => +v_1002734 = template_unbox(cps_provider_1_SlotResult, v_1002736); template_match_517(v_1002734, v_1, v_3)}

def template_match_518(+v_1002738: cps_provider_1_FormArmResult, +v_1: cps_provider_1_Context, v_23: List<&2, cps_provider_1_LayArm>, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool) -> TemplateProgress<cps_provider_1_Arms>:
  match v_1002738:
    case cps_provider_1_FormArmFail{+v_30}:
      TemplateFinished{TemplateValue{cps_provider_1_ArmsFail{v_30}}}
    case cps_provider_1_FormArmOk{+v_32}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_form_arms{v_1, v_23, Nat.add(v_6, 1n), v_8, v_10, v_12, v_32 <> v_15, v_17}}, v_1002740 => +v_1002739 = template_unbox(cps_provider_1_Arms, v_1002740); TemplateFinished{TemplateValue{v_1002739}}}

def template_match_519(+v_22: cps_provider_1_LayArm, +v_1: cps_provider_1_Context, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_17: Bool, v_23: List<&2, cps_provider_1_LayArm>, +v_15: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<cps_provider_1_Arms>:
  match v_22:
    case cps_provider_1_LayArm{+v_26, +v_27}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_form_arm{v_1, v_26, v_6, v_8, v_10, v_27, v_12, v_17}}, v_1002741 => +v_1002738 = template_unbox(cps_provider_1_FormArmResult, v_1002741); template_match_518(v_1002738, v_1, v_23, v_6, v_8, v_10, v_12, v_15, v_17)}

def template_body_cps_provider_1_form_arms(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_LayArm>, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool) -> TemplateProgress<cps_provider_1_Arms>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_ArmsOk{List.reverse(&2, cps_provider_1_FormArm, v_15)}}}
    case +v_1003324 <> v_1003325:
      template_match_519(v_1003324, v_1, v_6, v_8, v_10, v_12, v_17, v_1003325, v_15)

def template_match_521(+v_1002744: cps_provider_1_Nests, +v_3: String, +v_5: Nat, +v_28: Bool, +v_26: List<&2, cps_provider_1_CWord>) -> TemplateProgress<cps_provider_1_FormArmResult>:
  match v_1002744:
    case cps_provider_1_NestsFail{+v_35}:
      TemplateFinished{TemplateValue{cps_provider_1_FormArmFail{v_35}}}
    case cps_provider_1_NestsOk{+v_37}:
      TemplateFinished{TemplateValue{cps_provider_1_FormArmOk{cps_provider_1_FormArm{v_3, v_5, v_28, List.length(&2, cps_provider_1_CWord, v_26), v_37}}}}

def template_continuation_522(+v_1002743: Nat, +v_1: cps_provider_1_Context, +v_12: List<&2, cps_provider_1_Layout>, +v_27: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_26: List<&2, cps_provider_1_CWord>, +v_14: Nat, +v_16: Bool, +v_3: String, +v_5: Nat, +v_28: Bool) -> TemplateProgress<cps_provider_1_FormArmResult>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_form_nests{v_1, v_12, v_27, v_1002743, v_9, List.length(&2, cps_provider_1_CWord, v_26), v_14, [], v_16}}, v_1002745 => +v_1002744 = template_unbox(cps_provider_1_Nests, v_1002745); template_match_521(v_1002744, v_3, v_5, v_28, v_26)}

def template_match_523(+v_22: cps_provider_1_Node, +v_7: Bool, +v_1: cps_provider_1_Context, +v_12: List<&2, cps_provider_1_Layout>, +v_9: Nat, +v_14: Nat, +v_16: Bool, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_FormArmResult>:
  match v_22:
    case cps_provider_1_Node{+v_26, +v_27, +v_28}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_tag_word{v_7}}, v_1002746 => +v_1002743 = template_unbox(Nat, v_1002746); template_continuation_522(v_1002743, v_1, v_12, v_27, v_9, v_26, v_14, v_16, v_3, v_5, v_28)}

def template_match_524(+v_1002742: cps_provider_1_NodeResult, +v_7: Bool, +v_1: cps_provider_1_Context, +v_12: List<&2, cps_provider_1_Layout>, +v_9: Nat, +v_14: Nat, +v_16: Bool, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_FormArmResult>:
  match v_1002742:
    case cps_provider_1_NodeFailed{+v_20}:
      TemplateFinished{TemplateValue{cps_provider_1_FormArmFail{v_20}}}
    case cps_provider_1_NodeFound{+v_22}:
      template_match_523(v_22, v_7, v_1, v_12, v_9, v_14, v_16, v_3, v_5)

def template_body_cps_provider_1_form_arm(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_7: Bool, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: Nat, +v_16: Bool) -> TemplateProgress<cps_provider_1_FormArmResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_node_layout_fuel{v_1, v_3, v_14}}, False{}, v_1002748 => template_body_cps_provider_1_node_layout_fuel(v_1, v_3, v_14), v_1002747 => +v_1002742 = template_unbox(cps_provider_1_NodeResult, v_1002747); template_match_524(v_1002742, v_7, v_1, v_12, v_9, v_14, v_16, v_3, v_5)}

def template_body_cps_provider_1_tag_word(+v_1: Bool) -> TemplateProgress<Nat>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{1n}}
    case False{}:
      TemplateFinished{TemplateValue{0n}}

def template_continuation_526(+v_11: Nat, +v_13: Nat, +v_15: Nat, +v_9: Nat, +v_35: Nat, +v_41: cps_provider_1_Unfill, +v_46: cps_provider_1_Fill, +v_1002752: cps_provider_1_Context, +v_1002753: List<&2, cps_provider_1_Layout>, +v_1002754: List<&2, cps_provider_1_NodeSlot>, v_1002755: Nat, +v_1002756: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_nest{v_9, v_35, v_41, v_46}}, v_1002763 => +v_1002760 = template_unbox(cps_provider_1_Nest, v_1002763); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_form_nests{v_1002752, v_1002753, v_1002754, Nat.add(v_1002755, v_1002756), {v_11 : Nat}, {v_13 : Nat}, {v_15 : Nat}, v_1002760 <> v_18, v_20}}, v_1002762 => +v_1002761 = template_unbox(cps_provider_1_Nests, v_1002762); TemplateFinished{TemplateValue{v_1002761}}}}

def template_match_527(+v_1002751: Bool, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_46: cps_provider_1_Fill, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_35: Nat, +v_41: cps_provider_1_Unfill, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1002751:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{"the constructor node does not fit its value layout"}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_fill_words{v_46}}, v_1002764 => +v_1002756 = template_unbox(Nat, v_1002764); template_continuation_526(v_11, v_13, v_15, v_9, v_35, v_41, v_46, {v_1 : cps_provider_1_Context}, {v_28 : List<&2, cps_provider_1_Layout>}, {v_30 : List<&2, cps_provider_1_NodeSlot>}, {v_9 : Nat}, v_1002756, v_18, v_20)}

def template_match_528(+v_1002750: cps_provider_1_FillResult, +v_9: Nat, +v_11: Nat, +v_35: Nat, +v_13: Nat, +v_41: cps_provider_1_Unfill, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1002750:
    case cps_provider_1_FillFailed{+v_44}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_44}}}
    case cps_provider_1_FillFound{+v_46}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_nest_fits{v_9, v_11, v_35, v_13, v_41, v_46}}, v_1002765 => +v_1002751 = template_unbox(Bool, v_1002765); template_match_527(v_1002751, v_1, v_28, v_30, v_9, v_46, v_11, v_13, v_15, v_35, v_41, v_18, v_20)}

def template_match_529(+v_1002749: cps_provider_1_UnfillResult, +v_1: cps_provider_1_Context, +v_27: cps_provider_1_Layout, +v_15: Nat, +v_9: Nat, +v_11: Nat, +v_35: Nat, +v_13: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1002749:
    case cps_provider_1_UnfillFailed{+v_39}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_39}}}
    case cps_provider_1_UnfillFound{+v_41}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_fill_fuel{v_1, v_27, v_15}}, False{}, v_1002767 => template_body_cps_provider_1_layout_fill_fuel(v_1, v_27, v_15), v_1002766 => +v_1002750 = template_unbox(cps_provider_1_FillResult, v_1002766); template_match_528(v_1002750, v_9, v_11, v_35, v_13, v_41, v_1, v_28, v_30, v_15, v_18, v_20)}

def template_continuation_530(+v_11: Nat, +v_13: Nat, +v_15: Nat, +v_35: Nat, +v_9: Nat, +v_56: cps_provider_1_Unfill, +v_61: cps_provider_1_Fill, +v_1002773: cps_provider_1_Context, +v_1002774: List<&2, cps_provider_1_Layout>, +v_1002775: List<&2, cps_provider_1_NodeSlot>, v_1002776: Nat, +v_1002777: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_nest{v_35, v_9, v_56, v_61}}, v_1002784 => +v_1002781 = template_unbox(cps_provider_1_Nest, v_1002784); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_form_nests{v_1002773, v_1002774, v_1002775, Nat.add(v_1002776, v_1002777), {v_11 : Nat}, {v_13 : Nat}, {v_15 : Nat}, v_1002781 <> v_18, v_20}}, v_1002783 => +v_1002782 = template_unbox(cps_provider_1_Nests, v_1002783); TemplateFinished{TemplateValue{v_1002782}}}}

def template_match_531(+v_1002772: Bool, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_56: cps_provider_1_Unfill, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_35: Nat, +v_61: cps_provider_1_Fill, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1002772:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{"the constructor node does not fit its value layout"}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_unfill_words{v_56}}, v_1002785 => +v_1002777 = template_unbox(Nat, v_1002785); template_continuation_530(v_11, v_13, v_15, v_35, v_9, v_56, v_61, {v_1 : cps_provider_1_Context}, {v_28 : List<&2, cps_provider_1_Layout>}, {v_30 : List<&2, cps_provider_1_NodeSlot>}, {v_9 : Nat}, v_1002777, v_18, v_20)}

def template_match_532(+v_1002771: cps_provider_1_FillResult, +v_35: Nat, +v_13: Nat, +v_9: Nat, +v_11: Nat, +v_56: cps_provider_1_Unfill, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1002771:
    case cps_provider_1_FillFailed{+v_59}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_59}}}
    case cps_provider_1_FillFound{+v_61}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_nest_fits{v_35, v_13, v_9, v_11, v_56, v_61}}, v_1002786 => +v_1002772 = template_unbox(Bool, v_1002786); template_match_531(v_1002772, v_1, v_28, v_30, v_9, v_56, v_11, v_13, v_15, v_35, v_61, v_18, v_20)}

def template_match_533(+v_1002770: cps_provider_1_UnfillResult, +v_1: cps_provider_1_Context, +v_36: cps_provider_1_Layout, +v_15: Nat, +v_35: Nat, +v_13: Nat, +v_9: Nat, +v_11: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1002770:
    case cps_provider_1_UnfillFailed{+v_54}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_54}}}
    case cps_provider_1_UnfillFound{+v_56}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_fill_fuel{v_1, v_36, v_15}}, False{}, v_1002788 => template_body_cps_provider_1_layout_fill_fuel(v_1, v_36, v_15), v_1002787 => +v_1002771 = template_unbox(cps_provider_1_FillResult, v_1002787); template_match_532(v_1002771, v_35, v_13, v_9, v_11, v_56, v_1, v_28, v_30, v_15, v_18, v_20)}

def template_match_534(+v_20: Bool, +v_1: cps_provider_1_Context, +v_36: cps_provider_1_Layout, +v_15: Nat, +v_27: cps_provider_1_Layout, +v_9: Nat, +v_11: Nat, +v_35: Nat, +v_13: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>) -> TemplateProgress<cps_provider_1_Nests>:
  match v_20:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_unfill_fuel{v_1, v_36, v_15}}, False{}, v_1002769 => template_body_cps_provider_1_layout_unfill_fuel(v_1, v_36, v_15), v_1002768 => +v_1002749 = template_unbox(cps_provider_1_UnfillResult, v_1002768); template_match_529(v_1002749, v_1, v_27, v_15, v_9, v_11, v_35, v_13, v_28, v_30, v_18, v_20)}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_unfill_fuel{v_1, v_27, v_15}}, False{}, v_1002790 => template_body_cps_provider_1_layout_unfill_fuel(v_1, v_27, v_15), v_1002789 => +v_1002770 = template_unbox(cps_provider_1_UnfillResult, v_1002789); template_match_533(v_1002770, v_1, v_36, v_15, v_35, v_13, v_9, v_11, v_28, v_30, v_18, v_20)}

def template_match_535(+v_29: cps_provider_1_NodeSlot, +v_20: Bool, +v_1: cps_provider_1_Context, +v_15: Nat, +v_27: cps_provider_1_Layout, +v_9: Nat, +v_11: Nat, +v_13: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>) -> TemplateProgress<cps_provider_1_Nests>:
  match v_29:
    case cps_provider_1_NodeSlot{+v_34, +v_35, +v_36}:
      template_match_534(v_20, v_1, v_36, v_15, v_27, v_9, v_11, v_35, v_13, v_28, v_30, v_18)

def template_body_cps_provider_1_form_nests(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_Layout>, +v_7: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_4, v_7:
    case [], []:
      TemplateFinished{TemplateValue{cps_provider_1_NestsOk{List.reverse(&2, cps_provider_1_Nest, v_18)}}}
    case +v_1003326 <> v_1003327, +v_1003328 <> v_1003329:
      template_match_535(v_1003328, v_20, v_1, v_15, v_1003326, v_9, v_11, v_13, v_1003327, v_1003329, v_18)
    case v_1003330, v_1003331:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{"a constructor node and its value layout disagree on the live field count"}}}

def template_body_cps_provider_1_nest(+v_1: Nat, +v_3: Nat, +v_5: cps_provider_1_Unfill, +v_7: cps_provider_1_Fill) -> TemplateProgress<cps_provider_1_Nest>:
  TemplateFinished{TemplateValue{cps_provider_1_Nest{v_1, v_3, v_5, v_7}}}

def template_match_537(v_1002796: Bool) -> TemplateProgress<Bool>:
  match v_1002796:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplateFinished{TemplateValue{True{}}}

def template_continuation_538(v_1002794: Nat, +v_1002795: Nat, +v_7: Nat) -> TemplateProgress<Bool>:
  v_1002796 = {Nat.is_gt(Nat.add(v_1002794, v_1002795), v_7) : Bool}
  template_match_537(v_1002796)

def template_match_539(v_1002793: Bool, +v_5: Nat, +v_9: cps_provider_1_Unfill, +v_7: Nat) -> TemplateProgress<Bool>:
  match v_1002793:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_unfill_words{v_9}}, v_1002797 => +v_1002795 = template_unbox(Nat, v_1002797); template_continuation_538({v_5 : Nat}, v_1002795, v_7)}

def template_continuation_540(v_1002791: Nat, +v_1002792: Nat, +v_3: Nat, +v_5: Nat, +v_9: cps_provider_1_Unfill, +v_7: Nat) -> TemplateProgress<Bool>:
  v_1002793 = {Nat.is_gt(Nat.add(v_1002791, v_1002792), v_3) : Bool}
  template_match_539(v_1002793, v_5, v_9, v_7)

def template_body_cps_provider_1_nest_fits(+v_1: Nat, +v_3: Nat, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_1_Unfill, +v_11: cps_provider_1_Fill) -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_fill_words{v_11}}, v_1002798 => +v_1002792 = template_unbox(Nat, v_1002798); template_continuation_540({v_1 : Nat}, v_1002792, v_3, v_5, v_9, v_7)}

def template_body_cps_provider_1_fill_words(+v_1: cps_provider_1_Fill) -> TemplateProgress<Nat>:
  match v_1:
    case cps_provider_1_FillWord{}:
      TemplateFinished{TemplateValue{1n}}
    case cps_provider_1_FillForm{+v_5, +v_6}:
      TemplateFinished{TemplateValue{v_5}}

def template_body_cps_provider_1_unfill_words(+v_1: cps_provider_1_Unfill) -> TemplateProgress<Nat>:
  match v_1:
    case cps_provider_1_UnfillWord{}:
      TemplateFinished{TemplateValue{1n}}
    case cps_provider_1_UnfillForm{+v_5, +v_6}:
      TemplateFinished{TemplateValue{v_5}}

def template_match_543(+v_1002799: cps_provider_2_Nf, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1002799:
    case cps_provider_2_NfFail{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadFailed{v_6}}}
    case cps_provider_2_NfOk{+v_8}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_head_value{v_1, v_8}}, v_1002801 => +v_1002800 = template_unbox(cps_provider_1_HeadResult, v_1002801); TemplateFinished{TemplateValue{v_1002800}}}

def template_body_cps_provider_1_head_native(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_HeadResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, [], 1024n}}, False{}, v_1002803 => template_body_cps_provider_1_nf_of(v_1, v_2, [], 1024n), v_1002802 => +v_1002799 = template_unbox(cps_provider_2_Nf, v_1002802); template_match_543(v_1002799, v_1)}

def template_body_cps_provider_1_head_other(+v_0: BIR.Descriptor) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_0:
    case BIR.DescriptorEquality{_, _, _}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadEquality{}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_545(v_1002805: Bool, +v_7: String, +v_20: Maybe<&2, String>) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1002805:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadFound{v_7, v_20}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_546(+v_11: BIR.Family, +v_8: List<&2, cps_provider_2_NfVal>, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_11:
    case BIR.Family{+v_18, +v_19, +v_20, +v_21, +v_22, +v_23}:
      v_1002805 = {Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_8), v_22) : Bool}
      template_match_545(v_1002805, v_7, v_20)

def template_match_547(v_1002807: Bool, +v_7: String, +v_34: Maybe<&2, String>) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1002807:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadFound{v_7, v_34}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_548(+v_34: Maybe<&2, String>, +v_8: List<&2, cps_provider_2_NfVal>, +v_36: Nat, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_34:
    case Some{+v_39}:
      v_1002807 = {Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_8), v_36) : Bool}
      template_match_547(v_1002807, v_7, v_34)
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_549(+v_27: BIR.TypeFunction, +v_8: List<&2, cps_provider_2_NfVal>, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_27:
    case BIR.TypeFunction{+v_33, +v_34, +v_35, +v_36, +v_37}:
      template_match_548(v_34, v_8, v_36, v_7)

def template_match_550(+v_1002806: Maybe<&2, BIR.TypeFunction>, +v_8: List<&2, cps_provider_2_NfVal>, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1002806:
    case Some{+v_27}:
      template_match_549(v_27, v_8, v_7)
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxUnresolved{v_7}}}}

def template_match_551(+v_1002804: Maybe<&2, BIR.Family>, +v_8: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1002804:
    case Some{+v_11}:
      template_match_546(v_11, v_8, v_7)
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_function_lookup{v_1, v_7}}, False{}, v_1002809 => template_body_cps_provider_1_function_lookup(v_1, v_7), v_1002808 => +v_1002806 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1002808); template_match_550(v_1002806, v_8, v_7)}

def template_body_cps_provider_1_head_value(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_3:
    case cps_provider_2_NfType{+v_1003332, +v_1003333}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_family_lookup{v_1, v_1003332}}, False{}, v_1003334 => template_body_cps_provider_1_family_lookup(v_1, v_1003332), v_1003335 => +v_1003336 = template_unbox(Maybe<&2, BIR.Family>, v_1003335); template_match_551(v_1003336, v_1003333, v_1003332, v_1)}
    case cps_provider_2_NfOther{+v_1003337}:
      template_body_cps_provider_1_head_other(v_1003337)
    case v_1003338:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_553(+v_1002813: BIR.Descriptor) -> TemplateProgress<cps_provider_1_NormResult>:
  match v_1002813:
    case BIR.DescriptorFailure{+v_7}:
      TemplateFinished{TemplateValue{cps_provider_1_NormFailed{v_7}}}
    case +v_9:
      TemplateFinished{TemplateValue{cps_provider_1_NormOk{v_9}}}

def template_body_cps_provider_1_norm(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_NormResult>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_normalize{template_pure_cps_provider_1_context_nf(v_1), v_2, [], 1024n}}, v_1002814 => +v_1002813 = template_unbox(BIR.Descriptor, v_1002814); template_match_553(v_1002813)}

def template_match_554(+v_8: cps_provider_2_NfVal) -> TemplateProgress<cps_provider_1_ArgsResult>:
  match v_8:
    case cps_provider_2_NfType{+v_11, +v_12}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_all{v_12}}, v_1002817 => +v_1002816 = template_unbox(List<&2, BIR.Descriptor>, v_1002817); TemplateFinished{TemplateValue{cps_provider_1_ArgsOk{v_1002816}}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_ArgsFailed{"the applied type is not a named family application"}}}

def template_match_555(+v_1002815: cps_provider_2_Nf) -> TemplateProgress<cps_provider_1_ArgsResult>:
  match v_1002815:
    case cps_provider_2_NfFail{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_1_ArgsFailed{v_6}}}
    case cps_provider_2_NfOk{+v_8}:
      template_match_554(v_8)

def template_body_cps_provider_1_head_args(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_ArgsResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, [], 1024n}}, False{}, v_1002819 => template_body_cps_provider_1_nf_of(v_1, v_2, [], 1024n), v_1002818 => +v_1002815 = template_unbox(cps_provider_2_Nf, v_1002818); template_match_555(v_1002815)}

def template_match_556(+v_1002820: cps_provider_2_Nf, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_1002820:
    case cps_provider_2_NfFail{+v_8}:
      TemplateFinished{TemplateValue{cps_provider_1_FieldsFailed{v_8}}}
    case cps_provider_2_NfOk{+v_10}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_arm_fields_value{v_1, v_3, v_10}}, v_1002822 => +v_1002821 = template_unbox(cps_provider_1_FieldsResult, v_1002822); TemplateFinished{TemplateValue{v_1002821}}}

def template_body_cps_provider_1_arm_fields(+v_1: cps_provider_1_Context, +v_3: String, +v_4: BIR.Descriptor) -> TemplateProgress<cps_provider_1_FieldsResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_nf_of{v_1, v_4, [], 1024n}}, False{}, v_1002824 => template_body_cps_provider_1_nf_of(v_1, v_4, [], 1024n), v_1002823 => +v_1002820 = template_unbox(cps_provider_2_Nf, v_1002823); template_match_556(v_1002820, v_1, v_3)}

def template_match_557(+v_14: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_14:
    case BIR.DescriptorArm{+v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_instantiate_fields{v_1, v_10, v_18, []}}, v_1002830 => +v_1002829 = template_unbox(cps_provider_1_FieldsResult, v_1002830); TemplateFinished{TemplateValue{v_1002829}}}

def template_match_558(+v_1002825: Maybe<&2, BIR.DescriptorArm>, +v_3: String, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_1002825:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_1_unresolved_message{v_3}}, False{}, v_1002828 => template_body_cps_provider_1_unresolved_message(v_3), v_1002827 => +v_1002826 = template_unbox(String, v_1002827); TemplateFinished{TemplateValue{cps_provider_1_FieldsFailed{v_1002826}}}}
    case Some{+v_14}:
      template_match_557(v_14, v_1, v_10)

def template_body_cps_provider_1_arm_fields_value(+v_1: cps_provider_1_Context, +v_3: String, +v_5: cps_provider_2_NfVal) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_5:
    case cps_provider_2_NfType{+v_1003339, +v_1003340}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_arm_declared{v_1, v_3}}, False{}, v_1003341 => template_body_cps_provider_1_arm_declared(v_1, v_3), v_1003342 => +v_1003343 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1003342); template_match_558(v_1003343, v_3, v_1, v_1003340)}
    case v_1003344:
      TemplateFinished{TemplateValue{cps_provider_1_FieldsFailed{"the applied type is not a named family application"}}}

def template_continuation_560(v_1002834: Maybe<&2, String>, v_1002835: BIR.Quantity, +v_1002836: BIR.Descriptor, +v_1: cps_provider_1_Context, +v_22: List<&2, cps_provider_2_NfVal>, v_13: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  +v_26 = {BIR.DescriptorField{v_1002834, v_1002835, v_1002836} : BIR.DescriptorField}
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_instantiate_fields{v_1, v_22, v_13, v_26 <> v_8}}, v_1002838 => +v_1002837 = template_unbox(cps_provider_1_FieldsResult, v_1002838); TemplateFinished{TemplateValue{v_1002837}}}

def template_continuation_561(+v_1002833: List<&2, cps_provider_2_NfVal>, +v_17: Maybe<&2, String>, +v_18: BIR.Quantity, +v_1: cps_provider_1_Context, +v_19: BIR.Descriptor, +v_4: List<&2, cps_provider_2_NfVal>, v_13: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_normalize{template_pure_cps_provider_1_context_nf(v_1), v_19, v_4, 1024n}}, v_1002839 => +v_1002836 = template_unbox(BIR.Descriptor, v_1002839); template_continuation_560({v_17 : Maybe<&2, String>}, {v_18 : BIR.Quantity}, v_1002836, v_1, v_1002833, v_13, v_8)}

def template_match_562(+v_12: BIR.DescriptorField, +v_4: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_1_Context, v_13: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_12:
    case BIR.DescriptorField{+v_17, +v_18, +v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_field_scope{v_4}}, False{}, v_1002841 => template_body_cps_provider_1_field_scope(v_4), v_1002840 => +v_1002833 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002840); template_continuation_561(v_1002833, v_17, v_18, v_1, v_19, v_4, v_13, v_8)}

def template_body_cps_provider_1_instantiate_fields(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_FieldsFound{List.reverse(&2, BIR.DescriptorField, v_8)}}}
    case +v_1003345 <> v_1003346:
      template_match_562(v_1003345, v_4, v_1, v_1003346, v_8)

def template_match_564(+v_1002842: cps_provider_1_LayoutResult) -> TemplateProgress<cps_provider_1_CellResult>:
  match v_1002842:
    case cps_provider_1_LayoutFailed{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_1_CellFailed{v_6}}}
    case cps_provider_1_LayoutFound{+v_8}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_cell_of{v_8}}, v_1002844 => +v_1002843 = template_unbox(cps_provider_1_CellResult, v_1002844); TemplateFinished{TemplateValue{v_1002843}}}

def template_body_cps_provider_1_array_cell(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_value_layout{v_1, v_2}}, False{}, v_1002846 => template_body_cps_provider_1_value_layout(v_1, v_2), v_1002845 => +v_1002842 = template_unbox(cps_provider_1_LayoutResult, v_1002845); template_match_564(v_1002842)}

def template_continuation_565(+v_10: Nat, v_1002850: cps_provider_1_Layout, +v_1002851: Bool) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_max_one{v_10}}, v_1002857 => +v_1002853 = template_unbox(Nat, v_1002857); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_ceil_log2{v_1002853}}, False{}, v_1002856 => template_body_cps_provider_1_ceil_log2(v_1002853), v_1002855 => +v_1002854 = template_unbox(Nat, v_1002855); TemplateFinished{TemplateValue{cps_provider_1_CellFound{cps_provider_1_Cell{v_1002850, v_1002851, {v_10 : Nat}, v_1002854}}}}}}

def template_continuation_566(+v_1002849: Nat, +v_1: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_layout_has_term{v_1}}, v_1002858 => +v_1002851 = template_unbox(Bool, v_1002858); template_continuation_565(v_1002849, {v_1 : cps_provider_1_Layout}, v_1002851)}

def template_body_cps_provider_1_cell_of(+v_1: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_CellResult>:
  match v_1:
    case cps_provider_1_LayoutBox{+v_4}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_cell_boxed{v_4}}, v_1002848 => +v_1002847 = template_unbox(cps_provider_1_CellResult, v_1002848); TemplateFinished{TemplateValue{v_1002847}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_words{v_1}}, False{}, v_1002860 => template_body_cps_provider_1_layout_words(v_1), v_1002859 => +v_1002849 = template_unbox(Nat, v_1002859); template_continuation_566(v_1002849, v_1)}

def template_body_cps_provider_1_cell_boxed(+v_1: cps_provider_1_BoxReason) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplateFinished{TemplateValue{cps_provider_1_CellFound{cps_provider_1_Cell{cps_provider_1_LayoutBox{v_1}, True{}, 1n, 0n}}}}

def template_match_568(v_1002861: Bool, +v_1: Nat) -> TemplateProgress<Nat>:
  match v_1002861:
    case True{}:
      TemplateFinished{TemplateValue{v_1}}
    case False{}:
      TemplateFinished{TemplateValue{1n}}

def template_body_cps_provider_1_max_one(+v_1: Nat) -> TemplateProgress<Nat>:
  v_1002861 = {Nat.is_gt(v_1, 0n) : Bool}
  template_match_568(v_1002861, v_1)

def template_body_cps_provider_1_layout_has_term(+v_1: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutWord{+v_4}:
      TemplateFinished{TemplateValue{template_pure_cps_provider_1_word_has_term(v_4)}}
    case cps_provider_1_LayoutBox{+v_7}:
      TemplateFinished{TemplateValue{True{}}}
    case cps_provider_1_LayoutData{+v_10, +v_11}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_any_word_has_term{v_10}}, v_1002863 => +v_1002862 = template_unbox(Bool, v_1002863); TemplateFinished{TemplateValue{v_1002862}}}

def template_body_cps_provider_1_word_has_term(+v_1: cps_provider_1_CWord) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_word_has_term(v_1)}}

def template_match_570(v_1002864: Bool, v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_1002864:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_1_any_word_has_term{v_7}}, v_1002866 => +v_1002865 = template_unbox(Bool, v_1002866); TemplateFinished{TemplateValue{v_1002865}}}

def template_body_cps_provider_1_any_word_has_term(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_6 <> v_7:
      v_1002864 = {template_pure_cps_provider_1_word_has_term(v_6) : Bool}
      template_match_570(v_1002864, v_7)

def template_match_572(+v_5: BIR.Family, v_6: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.Family>>:
  match v_5:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_family_index{v_6}}, v_1002868 => +v_1002867 = template_unbox(Map<&2, BIR.Family>, v_1002868); TemplateFinished{TemplateValue{Map.set(&2, BIR.Family, v_1002867, v_13, v_5)}}}

def template_body_cps_provider_2_family_index(v_1: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.Family>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.Family)}}
    case +v_5 <> v_6:
      template_match_572(v_5, v_6)

def template_match_574(+v_5: BIR.TypeFunction, v_6: List<&2, BIR.TypeFunction>) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  match v_5:
    case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_function_index{v_6}}, v_1002870 => +v_1002869 = template_unbox(Map<&2, BIR.TypeFunction>, v_1002870); TemplateFinished{TemplateValue{Map.set(&2, BIR.TypeFunction, v_1002869, v_12, v_5)}}}

def template_body_cps_provider_2_function_index(v_1: List<&2, BIR.TypeFunction>) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.TypeFunction)}}
    case +v_5 <> v_6:
      template_match_574(v_5, v_6)

def template_body_cps_provider_2_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> TemplateProgress<cps_provider_2_NfContext>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_family_index{v_1}}, False{}, v_1002876 => template_body_cps_provider_2_family_index(v_1), v_1002875 => +v_1002871 = template_unbox(Map<&2, BIR.Family>, v_1002875); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_function_index{v_3}}, False{}, v_1002874 => template_body_cps_provider_2_function_index(v_3), v_1002873 => +v_1002872 = template_unbox(Map<&2, BIR.TypeFunction>, v_1002873); TemplateFinished{TemplateValue{cps_provider_2_NfContext{v_1002871, v_1002872}}}}}

def template_body_cps_provider_2_default_fuel() -> TemplateProgress<Nat>:
  TemplateFinished{TemplateValue{1024n}}

def template_body_cps_provider_2_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{IndexLookup.find(BIR.Family, v_3, v_1)}}

def template_body_cps_provider_2_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, BIR.TypeFunction>>:
  TemplateFinished{TemplateValue{IndexLookup.find(BIR.TypeFunction, v_3, v_1)}}

def template_match_576(v_10: BIR.Family) -> TemplateProgress<Maybe<&2, String>>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      TemplateFinished{TemplateValue{v_19}}

def template_match_577(v_25: BIR.TypeFunction) -> TemplateProgress<Maybe<&2, String>>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      TemplateFinished{TemplateValue{v_32}}

def template_match_578(+v_1002878: Maybe<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  match v_1002878:
    case Some{v_25}:
      template_match_577(v_25)
    case None{}:
      TemplateFinished{TemplateValue{None{}}}

def template_match_579(+v_1002877: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  match v_1002877:
    case Some{v_10}:
      template_match_576(v_10)
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_function_of{v_1, v_5}}, False{}, v_1002880 => template_body_cps_provider_2_function_of(v_1, v_5), v_1002879 => +v_1002878 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1002879); template_match_578(v_1002878)}

def template_body_cps_provider_2_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_family_of{v_1, v_3}}, False{}, v_1002882 => template_body_cps_provider_2_family_of(v_1, v_3), v_1002881 => +v_1002877 = template_unbox(Maybe<&2, BIR.Family>, v_1002881); template_match_579(v_1002877, v_1, v_5)}

def template_body_cps_provider_2_val_nth(+v_2: List<&2, cps_provider_2_NfVal>, v_4: Nat) -> TemplateProgress<cps_provider_2_NfVal>:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      TemplateFinished{TemplateValue{v_8}}
    case +v_13 <> v_14, 1n+v_15:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_val_nth{v_14, v_15}}, v_1002884 => +v_1002883 = template_unbox(cps_provider_2_NfVal, v_1002884); TemplateFinished{TemplateValue{v_1002883}}}
    case _, _:
      TemplateFinished{TemplateValue{cps_provider_2_NfMissing{BIR.DescriptorNull{}}}}

def template_body_cps_provider_2_val_at(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> TemplateProgress<cps_provider_2_NfVal>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_val_at_choose{Nat.is_lt(v_4, List.length(&2, cps_provider_2_NfVal, v_2)), v_2, v_4, v_5}}, v_1002886 => +v_1002885 = template_unbox(cps_provider_2_NfVal, v_1002886); TemplateFinished{TemplateValue{v_1002885}}}

def template_body_cps_provider_2_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> TemplateProgress<cps_provider_2_NfVal>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_val_nth{v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_2_NfVal, v_4), 1n), v_6)}}, False{}, v_1002889 => template_body_cps_provider_2_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_2_NfVal, v_4), 1n), v_6)), v_1002888 => +v_1002887 = template_unbox(cps_provider_2_NfVal, v_1002888); TemplateFinished{TemplateValue{v_1002887}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfMissing{v_7}}}

def template_body_cps_provider_2_first_vals(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_2, v_4:
    case _, 0n:
      TemplateFinished{TemplateValue{[]}}
    case [], _:
      TemplateFinished{TemplateValue{[]}}
    case +v_14 <> v_15, 1n+v_16:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_first_vals{v_15, v_16}}, v_1002892 => +v_1002891 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002892); TemplateFinished{TemplateValue{{v_14 : cps_provider_2_NfVal} <> v_1002891}}}

def template_body_cps_provider_2_drop_vals(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_2, v_4:
    case v_1003347, 0n:
      TemplateFinished{TemplateValue{v_2}}
    case [], v_1003348:
      TemplateFinished{TemplateValue{[]}}
    case +v_1003349 <> v_1003350, 1n+v_1003351:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_drop_vals{v_1003350, v_1003351}}, v_1003352 => +v_1003353 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003352); TemplateFinished{TemplateValue{v_1003353}}}

def template_body_cps_provider_2_insert_before(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_6: cps_provider_2_NfVal) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_2, v_4:
    case v_1003354, 0n:
      TemplateFinished{TemplateValue{v_6 <> v_2}}
    case [], 1n+v_1003355:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_insert_before{[], v_1003355, v_6}}, v_1003356 => +v_1003357 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003356); TemplateFinished{TemplateValue{v_1003357}}}
    case +v_1003358 <> v_1003359, 1n+v_1003360:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_insert_before{v_1003359, v_1003360, v_6}}, v_1003362 => +v_1003363 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003362); TemplateFinished{TemplateValue{{v_1003358 : cps_provider_2_NfVal} <> v_1003363}}}

def template_body_cps_provider_2_append_vals(v_2: List<&2, cps_provider_2_NfVal>, v_5: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_5}}
    case +v_10 <> v_11:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_append_vals{v_11, v_5}}, v_1002902 => +v_1002901 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002902); TemplateFinished{TemplateValue{{v_10 : cps_provider_2_NfVal} <> v_1002901}}}

def template_body_cps_provider_2_quantity_markers(v_1: Nat) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case 1n+v_5:
      v_1002903 = {cps_provider_2_NfQuantity{BIR.Erased{}} : cps_provider_2_NfVal}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_quantity_markers{v_5}}, v_1002905 => +v_1002904 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002905); TemplateFinished{TemplateValue{v_1002903 <> v_1002904}}}

def template_match_587(v_1002906: Bool, v_10: Nat, v_11: List<&2, cps_provider_2_NfRenaming>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_1002906:
    case True{}:
      TemplateFinished{TemplateValue{v_10}}
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_renamed_level{v_11, v_4}}, v_1002908 => +v_1002907 = template_unbox(Nat, v_1002908); TemplateFinished{TemplateValue{v_1002907}}}

def template_body_cps_provider_2_renamed_level(v_2: List<&2, cps_provider_2_NfRenaming>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case cps_provider_2_NfRenaming{v_9, v_10} <> v_11:
      v_1002906 = {Nat.is_eq(v_9, v_4) : Bool}
      template_match_587(v_1002906, v_10, v_11, v_4)

def template_body_cps_provider_2_materialize_all_scoped(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_2_NfRenaming>) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_11 <> v_12:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_scoped{v_11, v_4, v_7}}, v_1002912 => +v_1002909 = template_unbox(BIR.Descriptor, v_1002912); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_all_scoped{v_12, v_4, v_7}}, v_1002911 => +v_1002910 = template_unbox(List<&2, BIR.Descriptor>, v_1002911); TemplateFinished{TemplateValue{v_1002909 <> v_1002910}}}}

def template_body_cps_provider_2_materialize_all_at(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  template_body_cps_provider_2_materialize_all_scoped(v_2, v_4, [])

def template_body_cps_provider_2_materialize_all(v_2: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  template_body_cps_provider_2_materialize_all_at(v_2, 0n)

def template_body_cps_provider_2_materialize_scoped(v_1: cps_provider_2_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_2_NfRenaming>) -> TemplateProgress<BIR.Descriptor>:
  match v_1:
    case cps_provider_2_NfType{v_9, v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_all_scoped{v_10, v_3, v_6}}, False{}, v_1002918 => template_body_cps_provider_2_materialize_all_scoped(v_10, v_3, v_6), v_1002917 => +v_1002916 = template_unbox(List<&2, BIR.Descriptor>, v_1002917); TemplateFinished{TemplateValue{BIR.DescriptorRef{{v_9 : String}, v_1002916}}}}
    case cps_provider_2_NfCtor{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_all_scoped{v_15, v_3, v_6}}, False{}, v_1002922 => template_body_cps_provider_2_materialize_all_scoped(v_15, v_3, v_6), v_1002921 => +v_1002920 = template_unbox(List<&2, BIR.Descriptor>, v_1002921); TemplateFinished{TemplateValue{BIR.DescriptorConstructor{{v_14 : String}, v_1002920}}}}
    case cps_provider_2_NfQuantity{v_18}:
      TemplateFinished{TemplateValue{BIR.DescriptorQuantity{v_18}}}
    case cps_provider_2_NfKind{v_20}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_scoped{v_20, v_3, v_6}}, v_1002924 => +v_1002923 = template_unbox(BIR.Descriptor, v_1002924); TemplateFinished{TemplateValue{BIR.DescriptorKind{v_1002923}}}}
    case cps_provider_2_NfOther{v_23}:
      TemplateFinished{TemplateValue{v_23}}
    case cps_provider_2_NfMissing{v_25}:
      TemplateFinished{TemplateValue{v_25}}
    case cps_provider_2_NfBinder{v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_renamed_level{v_6, v_27}}, False{}, v_1002928 => template_body_cps_provider_2_renamed_level(v_6, v_27), v_1002927 => +v_1002926 = template_unbox(Nat, v_1002927); TemplateFinished{TemplateValue{BIR.DescriptorParameter{Nat.sub({v_3 : Nat}, Nat.add(v_1002926, 1n))}}}}
    case cps_provider_2_NfArrow{v_33, v_34, v_35, v_36}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_scoped{v_34, v_3, v_6}}, v_1002933 => +v_1002930 = template_unbox(BIR.Descriptor, v_1002933); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_scoped{v_35, Nat.add(v_3, 1n), cps_provider_2_NfRenaming{v_36, v_3} <> v_6}}, v_1002932 => +v_1002931 = template_unbox(BIR.Descriptor, v_1002932); TemplateFinished{TemplateValue{BIR.DescriptorArrow{{v_33 : BIR.Quantity}, v_1002930, v_1002931}}}}}
    case cps_provider_2_NfClosure{v_42, v_43, v_44}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_all_scoped{v_44, v_3, v_6}}, False{}, v_1002936 => template_body_cps_provider_2_materialize_all_scoped(v_44, v_3, v_6), v_1002935 => +v_1002934 = template_unbox(List<&2, BIR.Descriptor>, v_1002935); TemplateFinished{TemplateValue{BIR.DescriptorLet{v_1002934, BIR.DescriptorLambda{v_42, v_43}}}}}

def template_body_cps_provider_2_materialize_at(v_1: cps_provider_2_NfVal, +v_3: Nat) -> TemplateProgress<BIR.Descriptor>:
  template_body_cps_provider_2_materialize_scoped(v_1, v_3, [])

def template_body_cps_provider_2_materialize(v_1: cps_provider_2_NfVal) -> TemplateProgress<BIR.Descriptor>:
  template_body_cps_provider_2_materialize_at(v_1, 0n)

def template_body_cps_provider_2_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_2_NfVal>, +v_5: Nat) -> TemplateProgress<BIR.Descriptor>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{v_0}}
    case +v_1003364 <> v_1003365:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_all_at{v_3, v_5}}, False{}, v_1003366 => template_body_cps_provider_2_materialize_all_at(v_3, v_5), v_1003367 => +v_1003368 = template_unbox(List<&2, BIR.Descriptor>, v_1003367); TemplateFinished{TemplateValue{BIR.DescriptorLet{v_1003368, v_0}}}}

def template_body_cps_provider_2_status_combine(v_1: cps_provider_2_NfStatus, v_3: cps_provider_2_NfStatus) -> TemplateProgress<cps_provider_2_NfStatus>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_status_combine(v_1, v_3)}}

def template_match_592(v_1002944: Bool, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_2_NfVal>, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_NfStatus>:
  match v_1002944:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfStatusNo{}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_20, v_24}}, v_1002948 => +v_1002945 = template_unbox(cps_provider_2_NfStatus, v_1002948); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_11, v_13}}, v_1002947 => +v_1002946 = template_unbox(cps_provider_2_NfStatus, v_1002947); TemplateFinished{TemplateValue{template_pure_cps_provider_2_status_combine(v_1002945, v_1002946)}}}}

def template_match_593(+v_12: cps_provider_2_NfVal, v_19: String, v_20: List<&2, BIR.DescriptorPattern>, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_NfStatus>:
  match v_12:
    case cps_provider_2_NfCtor{v_23, v_24}:
      v_1002944 = {String.eq(v_19, v_23) : Bool}
      template_match_592(v_1002944, v_20, v_24, v_11, v_13)
    case cps_provider_2_NfMissing{v_29}:
      v_1002949 = {cps_provider_2_NfStatusMaybe{} : cps_provider_2_NfStatus}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_11, v_13}}, v_1002951 => +v_1002950 = template_unbox(cps_provider_2_NfStatus, v_1002951); TemplateFinished{TemplateValue{template_pure_cps_provider_2_status_combine(v_1002949, v_1002950)}}}
    case cps_provider_2_NfOther{v_33}:
      v_1002952 = {cps_provider_2_NfStatusMaybe{} : cps_provider_2_NfStatus}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_11, v_13}}, v_1002954 => +v_1002953 = template_unbox(cps_provider_2_NfStatus, v_1002954); TemplateFinished{TemplateValue{template_pure_cps_provider_2_status_combine(v_1002952, v_1002953)}}}
    case cps_provider_2_NfBinder{v_37}:
      v_1002955 = {cps_provider_2_NfStatusMaybe{} : cps_provider_2_NfStatus}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_11, v_13}}, v_1002957 => +v_1002956 = template_unbox(cps_provider_2_NfStatus, v_1002957); TemplateFinished{TemplateValue{template_pure_cps_provider_2_status_combine(v_1002955, v_1002956)}}}
    case cps_provider_2_NfArrow{v_44, v_45, v_46, v_47}:
      v_1002958 = {cps_provider_2_NfStatusMaybe{} : cps_provider_2_NfStatus}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_11, v_13}}, v_1002960 => +v_1002959 = template_unbox(cps_provider_2_NfStatus, v_1002960); TemplateFinished{TemplateValue{template_pure_cps_provider_2_status_combine(v_1002958, v_1002959)}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_NfStatusNo{}}}

def template_match_594(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_2_NfVal>, +v_12: cps_provider_2_NfVal) -> TemplateProgress<cps_provider_2_NfStatus>:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_11, v_13}}, v_1002943 => +v_1002942 = template_unbox(cps_provider_2_NfStatus, v_1002943); TemplateFinished{TemplateValue{v_1002942}}}
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      template_match_593(v_12, v_19, v_20, v_11, v_13)

def template_body_cps_provider_2_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_NfStatus>:
  match v_1, v_4:
    case [], []:
      TemplateFinished{TemplateValue{cps_provider_2_NfStatusOk{}}}
    case +v_10 <> v_11, +v_12 <> v_13:
      template_match_594(v_10, v_11, v_13, v_12)
    case _, _:
      TemplateFinished{TemplateValue{cps_provider_2_NfStatusNo{}}}

def template_match_596(+v_13: cps_provider_2_NfVal, v_21: List<&2, BIR.DescriptorPattern>, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_13:
    case cps_provider_2_NfCtor{v_24, v_25}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_bind_values{v_21, v_25}}, v_1002968 => +v_1002964 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002968); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_bind_values{v_12, v_14}}, v_1002967 => +v_1002965 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002967); template_body_cps_provider_2_append_vals(v_1002964, v_1002965)}}
    case _:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_bind_values{v_12, v_14}}, v_1002970 => +v_1002969 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002970); TemplateFinished{TemplateValue{v_1002969}}}

def template_match_597(+v_11: BIR.DescriptorPattern, +v_13: cps_provider_2_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_bind_values{v_12, v_14}}, v_1002963 => +v_1002962 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002963); TemplateFinished{TemplateValue{{v_13 : cps_provider_2_NfVal} <> v_1002962}}}
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      template_match_596(v_13, v_21, v_12, v_14)

def template_body_cps_provider_2_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<List<&2, cps_provider_2_NfVal>>:
  match v_1, v_4:
    case [], []:
      TemplateFinished{TemplateValue{[]}}
    case +v_11 <> v_12, +v_13 <> v_14:
      template_match_597(v_11, v_13, v_12, v_14)
    case _, _:
      TemplateFinished{TemplateValue{[]}}

def template_match_599(+v_1002971: cps_provider_2_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_NfBind>:
  match v_1002971:
    case cps_provider_2_NfStatusOk{}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_bind_values{v_1, v_4}}, False{}, v_1002974 => template_body_cps_provider_2_bind_values(v_1, v_4), v_1002973 => +v_1002972 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1002973); TemplateFinished{TemplateValue{cps_provider_2_NfBound{v_1002972}}}}
    case cps_provider_2_NfStatusNo{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfMismatch{}}}
    case cps_provider_2_NfStatusMaybe{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfUnknown{}}}

def template_body_cps_provider_2_bind_patterns(+v_1: List<&2, BIR.DescriptorPattern>, +v_4: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_NfBind>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_bind_status{v_1, v_4}}, False{}, v_1002976 => template_body_cps_provider_2_bind_status(v_1, v_4), v_1002975 => +v_1002971 = template_unbox(cps_provider_2_NfStatus, v_1002975); template_match_599(v_1002971, v_1, v_4)}

def template_match_600(v_1002977: Bool, +v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1002977:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{"the type expression did not normalize within its reduction budget"}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1, v_2, v_5, v_7, Nat.sub(v_9, 1n)}}, v_1002979 => +v_1002978 = template_unbox(cps_provider_2_Nf, v_1002979); TemplateFinished{TemplateValue{v_1002978}}}

def template_body_cps_provider_2_nf(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  v_1002977 = {Nat.is_eq(v_9, 0n) : Bool}
  template_match_600(v_1002977, v_1, v_2, v_5, v_7, v_9)

def template_match_601(v_1002980: Bool, +v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1002980:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{"the type expression did not normalize within its reduction budget"}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor_step{v_1, v_2, v_5, v_7, v_9}}, v_1002982 => +v_1002981 = template_unbox(cps_provider_2_Nf, v_1002982); TemplateFinished{TemplateValue{v_1002981}}}

def template_body_cps_provider_2_nf_descriptor(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  v_1002980 = {Nat.is_eq(v_9, 0n) : Bool}
  template_match_601(v_1002980, v_1, v_2, v_5, v_7, v_9)

def template_match_602(+v_1002984: cps_provider_2_Nf, v_2: BIR.Quantity, v_17: cps_provider_2_NfVal, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1002984:
    case cps_provider_2_NfFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_21}}}
    case cps_provider_2_NfOk{v_23}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfArrow{v_2, v_17, v_23, v_9}}}}

def template_match_603(+v_1002983: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat, v_2: BIR.Quantity) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1002983:
    case cps_provider_2_NfFail{v_15}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_15}}}
    case cps_provider_2_NfOk{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_4, List.append(&2, cps_provider_2_NfVal, v_7, [cps_provider_2_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11}}, False{}, v_1002986 => template_body_cps_provider_2_nf(v_1, v_4, List.append(&2, cps_provider_2_NfVal, v_7, [cps_provider_2_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11), v_1002985 => +v_1002984 = template_unbox(cps_provider_2_Nf, v_1002985); template_match_602(v_1002984, v_2, v_17, v_9)}

def template_body_cps_provider_2_nf_arrow(+v_1: cps_provider_2_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_3, v_7, v_9, v_11}}, False{}, v_1002988 => template_body_cps_provider_2_nf(v_1, v_3, v_7, v_9, v_11), v_1002987 => +v_1002983 = template_unbox(cps_provider_2_Nf, v_1002987); template_match_603(v_1002983, v_1, v_4, v_7, v_9, v_11, v_2)}

def template_match_604(+v_1002998: cps_provider_2_Nf) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1002998:
    case cps_provider_2_NfOk{v_24}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfKind{v_24}}}}
    case cps_provider_2_NfFail{v_26}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_26}}}

def template_match_605(+v_1003005: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_45: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003005:
    case cps_provider_2_NfListOk{v_49}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_named{v_1, v_45, v_49, v_7, v_9}}, v_1003007 => +v_1003006 = template_unbox(cps_provider_2_Nf, v_1003007); TemplateFinished{TemplateValue{v_1003006}}}
    case cps_provider_2_NfListFail{v_52}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_52}}}

def template_match_606(+v_1003009: cps_provider_2_NfList, v_55: String) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003009:
    case cps_provider_2_NfListOk{v_59}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfCtor{v_55, v_59}}}}
    case cps_provider_2_NfListFail{v_61}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_61}}}

def template_match_607(+v_1003012: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_68: cps_provider_2_NfVal, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003012:
    case cps_provider_2_NfOk{v_71}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_apply{v_1, v_68, [v_71], v_7, v_9}}, v_1003014 => +v_1003013 = template_unbox(cps_provider_2_Nf, v_1003014); TemplateFinished{TemplateValue{v_1003013}}}
    case cps_provider_2_NfFail{v_74}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_74}}}

def template_match_608(+v_1003011: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_65: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003011:
    case cps_provider_2_NfOk{v_68}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_65, v_5, v_7, v_9}}, False{}, v_1003016 => template_body_cps_provider_2_nf(v_1, v_65, v_5, v_7, v_9), v_1003015 => +v_1003012 = template_unbox(cps_provider_2_Nf, v_1003015); template_match_607(v_1003012, v_1, v_68, v_7, v_9)}
    case cps_provider_2_NfFail{v_76}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_76}}}

def template_match_609(+v_1003019: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_82: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, v_80: Nat, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003019:
    case cps_provider_2_NfOk{v_85}:
      +v_1003020 = {v_1 : cps_provider_2_NfContext}
      v_1003021 = {v_82 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_insert_before{v_5, Nat.sub(List.length(&2, cps_provider_2_NfVal, v_5), v_80), v_85}}, False{}, v_1003027 => template_body_cps_provider_2_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_2_NfVal, v_5), v_80), v_85), v_1003026 => +v_1003022 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003026); TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1003020, v_1003021, v_1003022, v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003025 => template_body_cps_provider_2_nf_descriptor(v_1003020, v_1003021, v_1003022, v_7, Nat.sub(v_9, 1n)), v_1003024 => +v_1003023 = template_unbox(cps_provider_2_Nf, v_1003024); TemplateFinished{TemplateValue{v_1003023}}}}
    case cps_provider_2_NfFail{v_90}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_90}}}

def template_match_610(+v_1003030: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_94: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003030:
    case cps_provider_2_NfListOk{v_97}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1, v_94, List.append(&2, cps_provider_2_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003033 => template_body_cps_provider_2_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_2_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n)), v_1003032 => +v_1003031 = template_unbox(cps_provider_2_Nf, v_1003032); TemplateFinished{TemplateValue{v_1003031}}}
    case cps_provider_2_NfListFail{v_101}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_101}}}

def template_match_611(+v_1003036: cps_provider_2_NfBind, +v_1: cps_provider_2_NfContext, v_107: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003036:
    case cps_provider_2_NfBound{v_113}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1, v_107, List.append(&2, cps_provider_2_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003039 => template_body_cps_provider_2_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_2_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n)), v_1003038 => +v_1003037 = template_unbox(cps_provider_2_Nf, v_1003038); TemplateFinished{TemplateValue{v_1003037}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_12, v_5, v_7}}, False{}, v_1003042 => template_body_cps_provider_2_reify_env(v_12, v_5, v_7), v_1003041 => +v_1003040 = template_unbox(BIR.Descriptor, v_1003041); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1003040}}}}}

def template_match_612(+v_1003035: cps_provider_2_NfList, v_105: List<&2, BIR.DescriptorPattern>, +v_1: cps_provider_2_NfContext, v_107: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003035:
    case cps_provider_2_NfListOk{v_110}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_bind_patterns{v_105, v_110}}, False{}, v_1003044 => template_body_cps_provider_2_bind_patterns(v_105, v_110), v_1003043 => +v_1003036 = template_unbox(cps_provider_2_NfBind, v_1003043); template_match_611(v_1003036, v_1, v_107, v_5, v_7, v_9, v_12)}
    case cps_provider_2_NfListFail{v_120}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_120}}}

def template_match_613(+v_1003046: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_124: List<&2, BIR.Descriptor>, +v_5: List<&2, cps_provider_2_NfVal>, +v_12: BIR.Descriptor, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003046:
    case cps_provider_2_NfListOk{v_127}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_cases{v_1, v_124, v_127, v_5, v_12, v_7, v_9}}, v_1003048 => +v_1003047 = template_unbox(cps_provider_2_Nf, v_1003048); TemplateFinished{TemplateValue{v_1003047}}}
    case cps_provider_2_NfListFail{v_130}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_130}}}

def template_match_614(+v_1003053: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_139: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003053:
    case cps_provider_2_NfOk{v_142}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1, v_139, List.append(&2, cps_provider_2_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003056 => template_body_cps_provider_2_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_2_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n)), v_1003055 => +v_1003054 = template_unbox(cps_provider_2_Nf, v_1003055); TemplateFinished{TemplateValue{v_1003054}}}
    case cps_provider_2_NfFail{v_146}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_146}}}

def template_match_615(+v_1003069: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_170: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003069:
    case cps_provider_2_NfListOk{v_175}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_named{v_1, v_170, v_175, v_7, v_9}}, v_1003071 => +v_1003070 = template_unbox(cps_provider_2_Nf, v_1003071); TemplateFinished{TemplateValue{v_1003070}}}
    case cps_provider_2_NfListFail{v_178}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_178}}}

def template_match_616(+v_1003073: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_182: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003073:
    case cps_provider_2_NfListOk{v_187}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_named{v_1, v_182, v_187, v_7, v_9}}, v_1003075 => +v_1003074 = template_unbox(cps_provider_2_Nf, v_1003075); TemplateFinished{TemplateValue{v_1003074}}}
    case cps_provider_2_NfListFail{v_190}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_190}}}

def template_match_617(+v_12: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_1: cps_provider_2_NfContext, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_12:
    case BIR.DescriptorNull{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_12, v_5, v_7}}, False{}, v_1002991 => template_body_cps_provider_2_reify_env(v_12, v_5, v_7), v_1002990 => +v_1002989 = template_unbox(BIR.Descriptor, v_1002990); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1002989}}}}}
    case BIR.DescriptorParameter{v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_val_at{v_5, v_15, v_12}}, False{}, v_1002994 => template_body_cps_provider_2_val_at(v_5, v_15, v_12), v_1002993 => +v_1002992 = template_unbox(cps_provider_2_NfVal, v_1002993); TemplateFinished{TemplateValue{cps_provider_2_NfOk{v_1002992}}}}
    case BIR.DescriptorQuantityKind{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_12, v_5, v_7}}, False{}, v_1002997 => template_body_cps_provider_2_reify_env(v_12, v_5, v_7), v_1002996 => +v_1002995 = template_unbox(BIR.Descriptor, v_1002996); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1002995}}}}}
    case BIR.DescriptorQuantity{v_19}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfQuantity{v_19}}}}
    case BIR.DescriptorKind{v_21}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_21, v_5, v_7, v_9}}, False{}, v_1003000 => template_body_cps_provider_2_nf(v_1, v_21, v_5, v_7, v_9), v_1002999 => +v_1002998 = template_unbox(cps_provider_2_Nf, v_1002999); template_match_604(v_1002998)}
    case BIR.DescriptorMinimum{v_29, v_30}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_12, v_5, v_7}}, False{}, v_1003003 => template_body_cps_provider_2_reify_env(v_12, v_5, v_7), v_1003002 => +v_1003001 = template_unbox(BIR.Descriptor, v_1003002); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1003001}}}}}
    case BIR.DescriptorArrow{v_35, v_36, v_37}:
      template_body_cps_provider_2_nf_arrow(v_1, v_35, v_36, v_37, v_5, v_7, v_9)
    case BIR.DescriptorLambda{v_41, v_42}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfClosure{v_41, v_42, v_5}}}}
    case BIR.DescriptorRef{v_45, v_46}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_46, v_5, v_7, v_9}}, v_1003008 => +v_1003005 = template_unbox(cps_provider_2_NfList, v_1003008); template_match_605(v_1003005, v_1, v_45, v_7, v_9)}
    case BIR.DescriptorConstructor{v_55, v_56}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_56, v_5, v_7, v_9}}, v_1003010 => +v_1003009 = template_unbox(cps_provider_2_NfList, v_1003010); template_match_606(v_1003009, v_55)}
    case BIR.DescriptorApplication{v_64, v_65}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_64, v_5, v_7, v_9}}, False{}, v_1003018 => template_body_cps_provider_2_nf(v_1, v_64, v_5, v_7, v_9), v_1003017 => +v_1003011 = template_unbox(cps_provider_2_Nf, v_1003017); template_match_608(v_1003011, v_1, v_65, v_5, v_7, v_9)}
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_81, v_5, v_7, v_9}}, False{}, v_1003029 => template_body_cps_provider_2_nf(v_1, v_81, v_5, v_7, v_9), v_1003028 => +v_1003019 = template_unbox(cps_provider_2_Nf, v_1003028); template_match_609(v_1003019, v_1, v_82, v_5, v_80, v_7, v_9)}
    case BIR.DescriptorLet{v_93, v_94}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_93, v_5, v_7, v_9}}, v_1003034 => +v_1003030 = template_unbox(cps_provider_2_NfList, v_1003034); template_match_610(v_1003030, v_1, v_94, v_5, v_7, v_9)}
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_106, v_5, v_7, v_9}}, v_1003045 => +v_1003035 = template_unbox(cps_provider_2_NfList, v_1003045); template_match_612(v_1003035, v_105, v_1, v_107, v_5, v_7, v_9, v_12)}
    case BIR.DescriptorMatch{v_123, v_124}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_123, v_5, v_7, v_9}}, v_1003049 => +v_1003046 = template_unbox(cps_provider_2_NfList, v_1003049); template_match_613(v_1003046, v_1, v_124, v_5, v_12, v_7, v_9)}
    case BIR.DescriptorCase{v_133, v_134}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_12, v_5, v_7}}, False{}, v_1003052 => template_body_cps_provider_2_reify_env(v_12, v_5, v_7), v_1003051 => +v_1003050 = template_unbox(BIR.Descriptor, v_1003051); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1003050}}}}}
    case BIR.DescriptorBind{v_138, v_139}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_138, v_5, v_7, v_9}}, False{}, v_1003058 => template_body_cps_provider_2_nf(v_1, v_138, v_5, v_7, v_9), v_1003057 => +v_1003053 = template_unbox(cps_provider_2_Nf, v_1003057); template_match_614(v_1003053, v_1, v_139, v_5, v_7, v_9)}
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_12, v_5, v_7}}, False{}, v_1003061 => template_body_cps_provider_2_reify_env(v_12, v_5, v_7), v_1003060 => +v_1003059 = template_unbox(BIR.Descriptor, v_1003060); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1003059}}}}}
    case BIR.DescriptorReflexivity{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_12, v_5, v_7}}, False{}, v_1003064 => template_body_cps_provider_2_reify_env(v_12, v_5, v_7), v_1003063 => +v_1003062 = template_unbox(BIR.Descriptor, v_1003063); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1003062}}}}}
    case BIR.DescriptorFailure{v_156}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_156}}}
    case BIR.DescriptorFill{v_159, v_160}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_apply_args{v_1, v_159, v_160, v_5, v_12, v_7, v_9}}, v_1003066 => +v_1003065 = template_unbox(cps_provider_2_Nf, v_1003066); TemplateFinished{TemplateValue{v_1003065}}}
    case BIR.DescriptorPlus{v_164, v_165}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_apply_args{v_1, v_164, v_165, v_5, v_12, v_7, v_9}}, v_1003068 => +v_1003067 = template_unbox(cps_provider_2_Nf, v_1003068); TemplateFinished{TemplateValue{v_1003067}}}
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_172, v_5, v_7, v_9}}, v_1003072 => +v_1003069 = template_unbox(cps_provider_2_NfList, v_1003072); template_match_615(v_1003069, v_1, v_170, v_7, v_9)}
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_184, v_5, v_7, v_9}}, v_1003076 => +v_1003073 = template_unbox(cps_provider_2_NfList, v_1003076); template_match_616(v_1003073, v_1, v_182, v_7, v_9)}

def template_body_cps_provider_2_nf_descriptor_step(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  template_match_617(v_2, v_5, v_7, v_1, v_9)

def template_match_618(+v_1003078: cps_provider_2_NfList, v_20: cps_provider_2_NfVal) -> TemplateProgress<cps_provider_2_NfList>:
  match v_1003078:
    case cps_provider_2_NfListFail{v_23}:
      TemplateFinished{TemplateValue{cps_provider_2_NfListFail{v_23}}}
    case cps_provider_2_NfListOk{v_25}:
      TemplateFinished{TemplateValue{cps_provider_2_NfListOk{v_20 <> v_25}}}

def template_match_619(+v_1003077: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_15: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_2_NfList>:
  match v_1003077:
    case cps_provider_2_NfFail{v_18}:
      TemplateFinished{TemplateValue{cps_provider_2_NfListFail{v_18}}}
    case cps_provider_2_NfOk{v_20}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_15, v_6, v_8, v_10}}, v_1003079 => +v_1003078 = template_unbox(cps_provider_2_NfList, v_1003079); template_match_618(v_1003078, v_20)}

def template_body_cps_provider_2_nf_all(+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_2_NfList>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_NfListOk{[]}}}
    case +v_1003369 <> v_1003370:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_1003369, v_6, v_8, v_10}}, False{}, v_1003371 => template_body_cps_provider_2_nf(v_1, v_1003369, v_6, v_8, v_10), v_1003372 => +v_1003373 = template_unbox(cps_provider_2_Nf, v_1003372); template_match_619(v_1003373, v_1, v_1003370, v_6, v_8, v_10)}

def template_match_621(+v_1003083: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_18: cps_provider_2_NfVal, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003083:
    case cps_provider_2_NfListFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_21}}}
    case cps_provider_2_NfListOk{v_23}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_apply_source{v_1, v_18, v_23, v_8, v_10, v_12}}, v_1003085 => +v_1003084 = template_unbox(cps_provider_2_Nf, v_1003085); TemplateFinished{TemplateValue{v_1003084}}}

def template_match_622(+v_1003082: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Nat, v_8: BIR.Descriptor) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003082:
    case cps_provider_2_NfFail{v_16}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_16}}}
    case cps_provider_2_NfOk{v_18}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_all{v_1, v_4, v_7, v_10, v_12}}, False{}, v_1003087 => template_body_cps_provider_2_nf_all(v_1, v_4, v_7, v_10, v_12), v_1003086 => +v_1003083 = template_unbox(cps_provider_2_NfList, v_1003086); template_match_621(v_1003083, v_1, v_18, v_8, v_10, v_12)}

def template_body_cps_provider_2_nf_apply_args(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_2_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_2, v_7, v_10, v_12}}, False{}, v_1003089 => template_body_cps_provider_2_nf(v_1, v_2, v_7, v_10, v_12), v_1003088 => +v_1003082 = template_unbox(cps_provider_2_Nf, v_1003088); template_match_622(v_1003082, v_1, v_4, v_7, v_10, v_12, v_8)}

def template_body_cps_provider_2_nf_apply_source(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, +v_6: List<&2, cps_provider_2_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{v_3}}}
    case v_1003374:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_apply{v_1, v_3, v_6, v_9, v_11}}, v_1003375 => +v_1003376 = template_unbox(cps_provider_2_Nf, v_1003375); TemplateFinished{TemplateValue{v_1003376}}}

def template_match_624(+v_1003092: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_15: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003092:
    case cps_provider_2_NfFail{v_18}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_18}}}
    case cps_provider_2_NfOk{v_20}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_apply{v_1, v_20, v_15, v_8, Nat.sub(v_10, 1n)}}, v_1003094 => +v_1003093 = template_unbox(cps_provider_2_Nf, v_1003094); TemplateFinished{TemplateValue{v_1003093}}}

def template_body_cps_provider_2_nf_apply(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{v_3}}}
    case +v_1003377 <> v_1003378:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_apply_one{v_1, v_3, v_1003377, v_8, Nat.sub(v_10, 1n)}}, v_1003379 => +v_1003380 = template_unbox(cps_provider_2_Nf, v_1003379); template_match_624(v_1003380, v_1, v_1003378, v_8, v_10)}

def template_body_cps_provider_2_nf_apply_one(+v_1: cps_provider_2_NfContext, +v_3: cps_provider_2_NfVal, +v_5: cps_provider_2_NfVal, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_3:
    case cps_provider_2_NfType{v_1003381, v_1003382}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_named{v_1, v_1003381, List.append(&2, cps_provider_2_NfVal, v_1003382, [v_5]), v_7, Nat.sub(v_9, 1n)}}, v_1003383 => +v_1003384 = template_unbox(cps_provider_2_Nf, v_1003383); TemplateFinished{TemplateValue{v_1003384}}}
    case cps_provider_2_NfClosure{v_1003385, v_1003386, v_1003387}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1, v_1003386, List.append(&2, cps_provider_2_NfVal, v_1003387, [v_5]), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003388 => template_body_cps_provider_2_nf_descriptor(v_1, v_1003386, List.append(&2, cps_provider_2_NfVal, v_1003387, [v_5]), v_7, Nat.sub(v_9, 1n)), v_1003389 => +v_1003390 = template_unbox(cps_provider_2_Nf, v_1003389); TemplateFinished{TemplateValue{v_1003390}}}
    case cps_provider_2_NfCtor{v_1003391, v_1003392}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{String.append("the constructor `", String.append(v_1003391, "` is applied to an argument"))}}}
    case cps_provider_2_NfQuantity{v_1003393}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{"a quantity is applied to an argument"}}}
    case cps_provider_2_NfKind{v_1003394}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{"a kind is applied to an argument"}}}
    case cps_provider_2_NfOther{v_1003395}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_at{v_5, v_7}}, False{}, v_1003397 => template_body_cps_provider_2_materialize_at(v_5, v_7), v_1003398 => +v_1003399 = template_unbox(BIR.Descriptor, v_1003398); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{BIR.DescriptorApplication{{v_1003395 : BIR.Descriptor}, v_1003399}}}}}}
    case cps_provider_2_NfArrow{v_1003400, v_1003401, v_1003402, v_1003403}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_at{v_3, v_7}}, False{}, v_1003404 => template_body_cps_provider_2_materialize_at(v_3, v_7), v_1003405 => +v_1003406 = template_unbox(BIR.Descriptor, v_1003405); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_at{v_5, v_7}}, False{}, v_1003407 => template_body_cps_provider_2_materialize_at(v_5, v_7), v_1003408 => +v_1003409 = template_unbox(BIR.Descriptor, v_1003408); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{BIR.DescriptorApplication{v_1003406, v_1003409}}}}}}}
    case cps_provider_2_NfMissing{v_1003410}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_at{v_5, v_7}}, False{}, v_1003412 => template_body_cps_provider_2_materialize_at(v_5, v_7), v_1003413 => +v_1003414 = template_unbox(BIR.Descriptor, v_1003413); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfMissing{BIR.DescriptorApplication{{v_1003410 : BIR.Descriptor}, v_1003414}}}}}}
    case cps_provider_2_NfBinder{v_1003415}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_at{v_3, v_7}}, False{}, v_1003416 => template_body_cps_provider_2_materialize_at(v_3, v_7), v_1003417 => +v_1003418 = template_unbox(BIR.Descriptor, v_1003417); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_materialize_at{v_5, v_7}}, False{}, v_1003419 => template_body_cps_provider_2_materialize_at(v_5, v_7), v_1003420 => +v_1003421 = template_unbox(BIR.Descriptor, v_1003420); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfMissing{BIR.DescriptorApplication{v_1003418, v_1003421}}}}}}}

def template_body_cps_provider_2_intrinsic_io(+v_0: BIR.TypeFunction) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_intrinsic_io(v_0)}}

def template_match_627(v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_Nf>:
  match v_4:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfType{v_18, v_7}}}}

def template_body_cps_provider_2_nf_named_io(v_1: Bool, +v_3: cps_provider_2_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1:
    case True{}:
      template_match_627(v_4, v_7)
    case False{}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_reduce{v_3, v_4, v_7, v_9, Nat.sub(v_11, 1n)}}, v_1003422 => +v_1003423 = template_unbox(cps_provider_2_Nf, v_1003422); TemplateFinished{TemplateValue{v_1003423}}}

def template_match_629(+v_1003127: Maybe<&2, BIR.Family>, v_6: List<&2, cps_provider_2_NfVal>, +v_3: String) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003127:
    case Some{v_25}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_family{v_25, v_6}}, v_1003129 => +v_1003128 = template_unbox(cps_provider_2_Nf, v_1003129); TemplateFinished{TemplateValue{v_1003128}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_6}}}}

def template_match_630(+v_1003123: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_2_NfContext, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat, +v_3: String, v_14: Map<&2, BIR.Family>) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003123:
    case Some{v_18}:
      +v_20 = v_18
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_named_io{template_pure_cps_provider_2_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10}}, False{}, v_1003126 => template_body_cps_provider_2_nf_named_io(template_pure_cps_provider_2_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10), v_1003125 => +v_1003124 = template_unbox(cps_provider_2_Nf, v_1003125); TemplateFinished{TemplateValue{v_1003124}}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_family_of{v_3, v_14}}, False{}, v_1003131 => template_body_cps_provider_2_family_of(v_3, v_14), v_1003130 => +v_1003127 = template_unbox(Maybe<&2, BIR.Family>, v_1003130); template_match_629(v_1003127, v_6, v_3)}

def template_body_cps_provider_2_nf_named(+v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1:
    case cps_provider_2_NfContext{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_function_of{v_3, v_15}}, False{}, v_1003133 => template_body_cps_provider_2_function_of(v_3, v_15), v_1003132 => +v_1003123 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1003132); template_match_630(v_1003123, v_1, v_6, v_8, v_10, v_3, v_14)}

def template_body_cps_provider_2_nf_arity(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, +v_6: Nat) -> TemplateProgress<cps_provider_2_NfArity>:
  TemplateFinished{TemplateValue{cps_provider_2_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_2_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_2_NfVal, v_2), v_6)}}}

def template_match_632(v_0: BIR.Family, +v_6: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_Nf>:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_arity{v_6, v_20, v_17}}, False{}, v_1003138 => template_body_cps_provider_2_nf_arity(v_6, v_20, v_17), v_1003137 => +v_1003134 = template_unbox(cps_provider_2_NfArity, v_1003137); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_family_apply{v_1003134, v_13, v_20, v_6}}, v_1003136 => +v_1003135 = template_unbox(cps_provider_2_Nf, v_1003136); TemplateFinished{TemplateValue{v_1003135}}}}

def template_body_cps_provider_2_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_Nf>:
  template_match_632(v_0, v_3)

def template_match_633(v_15: Bool, v_3: String, v_8: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_Nf>:
  match v_15:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_8}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}}}

def template_match_634(v_14: Bool, v_3: String, v_8: List<&2, cps_provider_2_NfVal>, v_15: Bool) -> TemplateProgress<cps_provider_2_Nf>:
  match v_14:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_8}}}}
    case False{}:
      template_match_633(v_15, v_3, v_8)

def template_match_635(v_13: Bool, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_2_NfVal>, v_14: Bool, v_15: Bool) -> TemplateProgress<cps_provider_2_Nf>:
  match v_13:
    case True{}:
      v_1003139 = {v_3 : String}
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_quantity_markers{v_5}}, False{}, v_1003142 => template_body_cps_provider_2_quantity_markers(v_5), v_1003141 => +v_1003140 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003141); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfType{v_1003139, List.append(&2, cps_provider_2_NfVal, v_1003140, v_8)}}}}}
    case False{}:
      template_match_634(v_14, v_3, v_8, v_15)

def template_body_cps_provider_2_nf_family_apply(v_1: cps_provider_2_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1:
    case cps_provider_2_NfArity{v_13, v_14, v_15}:
      template_match_635(v_13, v_3, v_5, v_8, v_14, v_15)

def template_match_637(v_2: BIR.TypeFunction, +v_12: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_2_NfContext, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_2:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      +v_24 = v_20
      +v_26 = v_21
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_arity{v_12, v_24, v_26}}, False{}, v_1003147 => template_body_cps_provider_2_nf_arity(v_12, v_24, v_26), v_1003146 => +v_1003143 = template_unbox(cps_provider_2_NfArity, v_1003146); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_reduce_apply{v_1003143, v_1, v_18, v_24, v_26, v_22, v_12, v_7, v_9}}, v_1003145 => +v_1003144 = template_unbox(cps_provider_2_Nf, v_1003145); TemplateFinished{TemplateValue{v_1003144}}}}

def template_body_cps_provider_2_nf_reduce(+v_1: cps_provider_2_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  template_match_637(v_2, v_5, v_1, v_7, v_9)

def template_match_638(v_24: Bool, v_5: String, +v_13: List<&2, cps_provider_2_NfVal>) -> TemplateProgress<cps_provider_2_Nf>:
  match v_24:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfType{v_5, v_13}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}}}

def template_match_639(v_23: Bool, +v_3: cps_provider_2_NfContext, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_15: Nat, +v_17: Nat, v_24: Bool, v_5: String) -> TemplateProgress<cps_provider_2_Nf>:
  match v_23:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_first_vals{v_13, v_9}}, False{}, v_1003164 => template_body_cps_provider_2_first_vals(v_13, v_9), v_1003163 => +v_1003157 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003163); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_drop_vals{v_13, v_9}}, False{}, v_1003162 => template_body_cps_provider_2_drop_vals(v_13, v_9), v_1003161 => +v_1003158 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003161); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_reduce_body{{v_3 : cps_provider_2_NfContext}, {v_10 : BIR.Descriptor}, v_1003157, v_1003158, v_15, Nat.sub(v_17, 1n)}}, v_1003160 => +v_1003159 = template_unbox(cps_provider_2_Nf, v_1003160); TemplateFinished{TemplateValue{v_1003159}}}}}
    case False{}:
      template_match_638(v_24, v_5, v_13)

def template_match_640(v_22: Bool, +v_3: cps_provider_2_NfContext, v_10: BIR.Descriptor, v_7: Nat, +v_13: List<&2, cps_provider_2_NfVal>, +v_15: Nat, +v_17: Nat, v_23: Bool, +v_9: Nat, v_24: Bool, v_5: String) -> TemplateProgress<cps_provider_2_Nf>:
  match v_22:
    case True{}:
      v_1003149 = {v_10 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_quantity_markers{v_7}}, False{}, v_1003154 => template_body_cps_provider_2_quantity_markers(v_7), v_1003153 => +v_1003150 = template_unbox(List<&2, cps_provider_2_NfVal>, v_1003153); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_reduce_body{{v_3 : cps_provider_2_NfContext}, v_1003149, List.append(&2, cps_provider_2_NfVal, v_1003150, v_13), [], v_15, Nat.sub(v_17, 1n)}}, v_1003152 => +v_1003151 = template_unbox(cps_provider_2_Nf, v_1003152); TemplateFinished{TemplateValue{v_1003151}}}}
    case False{}:
      template_match_639(v_23, v_3, v_10, v_13, v_9, v_15, v_17, v_24, v_5)

def template_body_cps_provider_2_nf_reduce_apply(v_1: cps_provider_2_NfArity, +v_3: cps_provider_2_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_2_NfVal>, +v_15: Nat, +v_17: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1:
    case cps_provider_2_NfArity{v_1003424, v_1003425, v_1003426}:
      template_match_640(v_1003424, v_3, v_10, v_7, v_13, v_15, v_17, v_1003425, v_9, v_1003426, v_5)

def template_match_642(+v_1003165: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003165:
    case cps_provider_2_NfFail{v_16}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_16}}}
    case cps_provider_2_NfOk{v_18}:
      template_body_cps_provider_2_nf_apply(v_1, v_18, v_8, v_10, v_12)

def template_body_cps_provider_2_nf_reduce_body(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)}}, False{}, v_1003168 => template_body_cps_provider_2_nf_descriptor(v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)), v_1003167 => +v_1003165 = template_unbox(cps_provider_2_Nf, v_1003167); template_match_642(v_1003165, v_1, v_8, v_10, v_12)}

def template_match_643(+v_1003172: cps_provider_2_NfBind, +v_1: cps_provider_2_NfContext, v_24: BIR.Descriptor, +v_9: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor) -> TemplateProgress<cps_provider_2_Nf>:
  match v_1003172:
    case cps_provider_2_NfBound{v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_descriptor{v_1, v_24, List.append(&2, cps_provider_2_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n)}}, False{}, v_1003175 => template_body_cps_provider_2_nf_descriptor(v_1, v_24, List.append(&2, cps_provider_2_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n)), v_1003174 => +v_1003173 = template_unbox(cps_provider_2_Nf, v_1003174); TemplateFinished{TemplateValue{v_1003173}}}
    case cps_provider_2_NfMismatch{}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf_cases{v_1, v_20, v_6, v_9, v_10, v_12, v_14}}, v_1003177 => +v_1003176 = template_unbox(cps_provider_2_Nf, v_1003177); TemplateFinished{TemplateValue{v_1003176}}}
    case cps_provider_2_NfUnknown{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_10, v_9, v_12}}, False{}, v_1003180 => template_body_cps_provider_2_reify_env(v_10, v_9, v_12), v_1003179 => +v_1003178 = template_unbox(BIR.Descriptor, v_1003179); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1003178}}}}}

def template_match_644(+v_19: BIR.Descriptor, +v_6: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_2_NfContext, +v_9: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, v_10: BIR.Descriptor) -> TemplateProgress<cps_provider_2_Nf>:
  match v_19:
    case BIR.DescriptorCase{v_23, v_24}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_bind_patterns{v_23, v_6}}, False{}, v_1003182 => template_body_cps_provider_2_bind_patterns(v_23, v_6), v_1003181 => +v_1003172 = template_unbox(cps_provider_2_NfBind, v_1003181); template_match_643(v_1003172, v_1, v_24, v_9, v_12, v_14, v_20, v_6, v_10)}
    case BIR.DescriptorFailure{v_33}:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{v_33}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_NfFail{"descriptor match case is not a case"}}}

def template_body_cps_provider_2_nf_cases(+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, +v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> TemplateProgress<cps_provider_2_Nf>:
  match v_3:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_reify_env{v_10, v_9, v_12}}, False{}, v_1003427 => template_body_cps_provider_2_reify_env(v_10, v_9, v_12), v_1003428 => +v_1003429 = template_unbox(BIR.Descriptor, v_1003428); TemplateFinished{TemplateValue{cps_provider_2_NfOk{cps_provider_2_NfOther{v_1003429}}}}}
    case +v_1003430 <> v_1003431:
      template_match_644(v_1003430, v_6, v_1, v_9, v_12, v_14, v_1003431, v_10)

def template_match_646(+v_1003183: cps_provider_2_Nf) -> TemplateProgress<BIR.Descriptor>:
  match v_1003183:
    case cps_provider_2_NfFail{v_10}:
      TemplateFinished{TemplateValue{BIR.DescriptorFailure{v_10}}}
    case cps_provider_2_NfOk{v_12}:
      template_body_cps_provider_2_materialize_at(v_12, 0n)

def template_body_cps_provider_2_normalize(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_nf{v_1, v_2, v_5, 0n, v_7}}, False{}, v_1003186 => template_body_cps_provider_2_nf(v_1, v_2, v_5, 0n, v_7), v_1003185 => +v_1003183 = template_unbox(cps_provider_2_Nf, v_1003185); template_match_646(v_1003183)}

def template_body_cps_provider_2_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_nf_context{v_1, v_3}}, False{}, v_1003192 => template_body_cps_provider_2_nf_context(v_1, v_3), v_1003191 => +v_1003187 = template_unbox(cps_provider_2_NfContext, v_1003191); TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_normalize{v_1003187, v_4, [], 1024n}}, False{}, v_1003190 => template_body_cps_provider_2_normalize(v_1003187, v_4, [], 1024n), v_1003189 => +v_1003188 = template_unbox(BIR.Descriptor, v_1003189); TemplateFinished{TemplateValue{v_1003188}}}}

def template_body_cps_provider_2_normalize_in(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_normalize{v_1, v_2, [], 1024n}}, False{}, v_1003195 => template_body_cps_provider_2_normalize(v_1, v_2, [], 1024n), v_1003194 => +v_1003193 = template_unbox(BIR.Descriptor, v_1003194); TemplateFinished{TemplateValue{v_1003193}}}

def template_body_cps_provider_2_outer_application(+v_0: BIR.Descriptor) -> TemplateProgress<Maybe<&2, cps_provider_2_NfApp>>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_outer_walk{v_0, []}}, v_1003197 => +v_1003196 = template_unbox(Maybe<&2, cps_provider_2_NfApp>, v_1003197); TemplateFinished{TemplateValue{v_1003196}}}

def template_body_cps_provider_2_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> TemplateProgress<Maybe<&2, cps_provider_2_NfApp>>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      TemplateFinished{TemplateValue{Some{cps_provider_2_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{Some{cps_provider_2_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      TemplateFinished{TemplateValue{Some{cps_provider_2_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}}}
    case BIR.DescriptorFill{v_23, v_24}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_outer_walk{v_23, List.append(&2, BIR.Descriptor, v_24, v_2)}}, v_1003199 => +v_1003198 = template_unbox(Maybe<&2, cps_provider_2_NfApp>, v_1003199); TemplateFinished{TemplateValue{v_1003198}}}
    case BIR.DescriptorPlus{v_28, v_29}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_outer_walk{v_28, List.append(&2, BIR.Descriptor, v_29, v_2)}}, v_1003201 => +v_1003200 = template_unbox(Maybe<&2, cps_provider_2_NfApp>, v_1003201); TemplateFinished{TemplateValue{v_1003200}}}
    case BIR.DescriptorApplication{v_33, v_34}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_outer_walk{v_33, List.append(&2, BIR.Descriptor, [v_34], v_2)}}, v_1003203 => +v_1003202 = template_unbox(Maybe<&2, cps_provider_2_NfApp>, v_1003203); TemplateFinished{TemplateValue{v_1003202}}}
    case _:
      TemplateFinished{TemplateValue{None{}}}

def template_match_648(+v_5: BIR.Descriptor, +v_1: cps_provider_2_NfContext) -> TemplateProgress<BIR.Descriptor>:
  match v_5:
    case BIR.DescriptorFailure{_}:
      TemplateFinished{TemplateValue{v_5}}
    case _:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_answer_normalized{v_1, v_5}}, v_1003206 => +v_1003205 = template_unbox(BIR.Descriptor, v_1003206); TemplateFinished{TemplateValue{v_1003205}}}

def template_continuation_649(+v_1003204: BIR.Descriptor, +v_1: cps_provider_2_NfContext) -> TemplateProgress<BIR.Descriptor>:
  template_match_648(v_1003204, v_1)

def template_body_cps_provider_2_answer_in(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_normalize{v_1, v_2, [], 1024n}}, False{}, v_1003208 => template_body_cps_provider_2_normalize(v_1, v_2, [], 1024n), v_1003207 => +v_1003204 = template_unbox(BIR.Descriptor, v_1003207); template_continuation_649(v_1003204, v_1)}

def template_body_cps_provider_2_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_nf_context{v_2, v_4}}, False{}, v_1003212 => template_body_cps_provider_2_nf_context(v_2, v_4), v_1003211 => +v_1003209 = template_unbox(cps_provider_2_NfContext, v_1003211); template_body_cps_provider_2_answer_in(v_1003209, v_0)}

def template_match_650(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  match v_9:
    case []:
      TemplateFinished{TemplateValue{v_2}}
    case +v_13 <> v_14:
      TemplateFinished{TemplateValue{v_13}}

def template_match_651(+v_1003214: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> TemplateProgress<BIR.Descriptor>:
  match v_1003214:
    case False{}:
      TemplateFinished{TemplateValue{v_2}}
    case True{}:
      template_match_650(v_9, v_2)

def template_match_652(v_5: cps_provider_2_NfApp, +v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  match v_5:
    case cps_provider_2_NfApp{v_8, v_9}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_is_io_head_in{v_1, v_8}}, v_1003215 => +v_1003214 = template_unbox(Bool, v_1003215); template_match_651(v_1003214, v_2, v_9)}

def template_match_653(+v_1003213: Maybe<&2, cps_provider_2_NfApp>, +v_2: BIR.Descriptor, +v_1: cps_provider_2_NfContext) -> TemplateProgress<BIR.Descriptor>:
  match v_1003213:
    case None{}:
      TemplateFinished{TemplateValue{v_2}}
    case Some{v_5}:
      template_match_652(v_5, v_1, v_2)

def template_body_cps_provider_2_answer_normalized(+v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_outer_application{v_2}}, False{}, v_1003217 => template_body_cps_provider_2_outer_application(v_2), v_1003216 => +v_1003213 = template_unbox(Maybe<&2, cps_provider_2_NfApp>, v_1003216); template_match_653(v_1003213, v_2, v_1)}

def template_body_cps_provider_2_is_io_head_in(+v_1: cps_provider_2_NfContext, +v_3: String) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_2_NfContext{v_7, v_8}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_is_io_head{v_3, v_7, v_8}}, v_1003219 => +v_1003218 = template_unbox(Bool, v_1003219); TemplateFinished{TemplateValue{v_1003218}}}

def template_match_655(+v_1003220: Maybe<&2, String>) -> TemplateProgress<Bool>:
  match v_1003220:
    case Some{v_9}:
      TemplateFinished{TemplateValue{String.eq(v_9, "IO")}}
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_cps_provider_2_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_native_of{v_1, v_3, v_5}}, False{}, v_1003222 => template_body_cps_provider_2_native_of(v_1, v_3, v_5), v_1003221 => +v_1003220 = template_unbox(Maybe<&2, String>, v_1003221); template_match_655(v_1003220)}

def template_step_group_0(request: TemplateRequestGroup0) -> TemplateProgress<template_result_group_0(request)>:
  match request:
    case TemplateRequest_fld{arg_0}: template_body_fld(arg_0)
    case TemplateRequest_arm{arg_0, arg_1}: template_body_arm(arg_0, arg_1)
    case TemplateRequest_fam{arg_0, arg_1, arg_2, arg_3}: template_body_fam(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_ref{arg_0, arg_1}: template_body_ref(arg_0, arg_1)
    case TemplateRequest_par{arg_0}: template_body_par(arg_0)
    case TemplateRequest_fam_nat{}: template_body_fam_nat()
    case TemplateRequest_fam_u32{}: template_body_fam_u32()
    case TemplateRequest_fam_f32{}: template_body_fam_f32()
    case TemplateRequest_fam_array{}: template_body_fam_array()
    case TemplateRequest_fam_io{}: template_body_fam_io()
    case TemplateRequest_fam_pt{}: template_body_fam_pt()
    case TemplateRequest_fam_fl{}: template_body_fam_fl()
    case TemplateRequest_fam_seg{}: template_body_fam_seg()
    case TemplateRequest_fam_w32{}: template_body_fam_w32()
    case TemplateRequest_fam_onenat{}: template_body_fam_onenat()
    case TemplateRequest_fam_empty{}: template_body_fam_empty()
    case TemplateRequest_fam_box{}: template_body_fam_box()
    case TemplateRequest_fam_pair{}: template_body_fam_pair()
    case TemplateRequest_fam_opt{}: template_body_fam_opt()
    case TemplateRequest_fam_list{}: template_body_fam_list()
    case TemplateRequest_families{}: template_body_families()
    case TemplateRequest_type_functions{}: template_body_type_functions()
    case TemplateRequest_program{}: template_body_program()
    case TemplateRequest_both{arg_0, arg_1}: template_body_both(arg_0, arg_1)
    case TemplateRequest_bool_eq{arg_0, arg_1}: template_body_bool_eq(arg_0, arg_1)
    case TemplateRequest_fail{arg_0}: template_body_fail(arg_0)
    case TemplateRequest_first_word_32{arg_0}: template_body_first_word_32(arg_0)
    case TemplateRequest_first_word_64{arg_0}: template_body_first_word_64(arg_0)
    case TemplateRequest_first_word_box{arg_0}: template_body_first_word_box(arg_0)
    case TemplateRequest_check_pt_value{arg_0}: template_body_check_pt_value(arg_0)
    case TemplateRequest_check_pt_node{arg_0}: template_body_check_pt_node(arg_0)
    case TemplateRequest_slot_offsets{arg_0}: template_body_slot_offsets(arg_0)
    case TemplateRequest_check_seg_node{arg_0}: template_body_check_seg_node(arg_0)
    case TemplateRequest_check_opt_tag{arg_0}: template_body_check_opt_tag(arg_0)
    case TemplateRequest_check_w32_packed{arg_0}: template_body_check_w32_packed(arg_0)
    case TemplateRequest_check_nat_not_packed{arg_0}: template_body_check_nat_not_packed(arg_0)
    case TemplateRequest_check_empty_packed{arg_0}: template_body_check_empty_packed(arg_0)
    case TemplateRequest_check_box_declared_node{arg_0}: template_body_check_box_declared_node(arg_0)
    case TemplateRequest_check_box_value{arg_0}: template_body_check_box_value(arg_0)
    case TemplateRequest_check_u32_cell{arg_0}: template_body_check_u32_cell(arg_0)
    case TemplateRequest_check_nat_cell{arg_0}: template_body_check_nat_cell(arg_0)
    case TemplateRequest_check_pt_cell{arg_0}: template_body_check_pt_cell(arg_0)
    case TemplateRequest_check_seg_cell{arg_0}: template_body_check_seg_cell(arg_0)
    case TemplateRequest_check_open_cell{arg_0}: template_body_check_open_cell(arg_0)
    case TemplateRequest_check_abstract_cell{arg_0}: template_body_check_abstract_cell(arg_0)
    case TemplateRequest_check_recursive{arg_0}: template_body_check_recursive(arg_0)
    case TemplateRequest_check_open_box{arg_0}: template_body_check_open_box(arg_0)
    case TemplateRequest_check_failure{arg_0}: template_body_check_failure(arg_0)
    case TemplateRequest_nests_agree{arg_0, arg_1}: template_body_nests_agree(arg_0, arg_1)
    case TemplateRequest_forms_agree{arg_0, arg_1}: template_body_forms_agree(arg_0, arg_1)
    case TemplateRequest_check_fill{arg_0, arg_1, arg_2}: template_body_check_fill(arg_0, arg_1, arg_2)
    case TemplateRequest_extract{arg_0}: template_body_extract(arg_0)
    case TemplateRequest_check_head_nat_alias{arg_0}: template_body_check_head_nat_alias(arg_0)
    case TemplateRequest_check_head_array{arg_0}: template_body_check_head_array(arg_0)
    case TemplateRequest_check_head_plain{arg_0}: template_body_check_head_plain(arg_0)
    case TemplateRequest_check_head_open{arg_0}: template_body_check_head_open(arg_0)
    case TemplateRequest_check_head_failure{arg_0}: template_body_check_head_failure(arg_0)
    case TemplateRequest_descriptor_is_ref{arg_0, arg_1}: template_body_descriptor_is_ref(arg_0, arg_1)
    case TemplateRequest_check_box_fields{arg_0}: template_body_check_box_fields(arg_0)
    case TemplateRequest_check_pair_fields{arg_0}: template_body_check_pair_fields(arg_0)
    case TemplateRequest_check_fields_failure{arg_0}: template_body_check_fields_failure(arg_0)
    case TemplateRequest_mk_words{arg_0}: template_body_mk_words(arg_0)
    case TemplateRequest_mk_fields{arg_0}: template_body_mk_fields(arg_0)
    case TemplateRequest_wide_program{}: template_body_wide_program()

def template_step_group_1(request: TemplateRequestGroup1) -> TemplateProgress<template_result_group_1(request)>:
  match request:
    case TemplateRequest_mk_miss{arg_0}: template_body_mk_miss(arg_0)
    case TemplateRequest_check_ceil{}: template_body_check_ceil()
    case TemplateRequest_check_pow2{}: template_body_check_pow2()
    case TemplateRequest_check_pad{arg_0, arg_1}: template_body_check_pad(arg_0, arg_1)
    case TemplateRequest_check_wide{arg_0}: template_body_check_wide(arg_0)
    case TemplateRequest_check_long_arm{arg_0}: template_body_check_long_arm(arg_0)
    case TemplateRequest_check_norm_alias{arg_0}: template_body_check_norm_alias(arg_0)
    case TemplateRequest_first_arg_is{arg_0, arg_1}: template_body_first_arg_is(arg_0, arg_1)
    case TemplateRequest_check_norm_distinct{arg_0, arg_1}: template_body_check_norm_distinct(arg_0, arg_1)
    case TemplateRequest_check_norm_failure{arg_0}: template_body_check_norm_failure(arg_0)
    case TemplateRequest_args_first_is{arg_0, arg_1}: template_body_args_first_is(arg_0, arg_1)
    case TemplateRequest_check_args_pair{arg_0}: template_body_check_args_pair(arg_0)
    case TemplateRequest_check_args_failure{arg_0}: template_body_check_args_failure(arg_0)
    case TemplateRequest_chain_key{arg_0}: template_body_chain_key(arg_0)
    case TemplateRequest_next_key{arg_0}: template_body_next_key(arg_0)
    case TemplateRequest_fam_chain{arg_0}: template_body_fam_chain(arg_0)
    case TemplateRequest_program_shadow{}: template_body_program_shadow()
    case TemplateRequest_check_io_native{arg_0}: template_body_check_io_native(arg_0)
    case TemplateRequest_check_io_under{arg_0}: template_body_check_io_under(arg_0)
    case TemplateRequest_check_shadow_io{arg_0}: template_body_check_shadow_io(arg_0)
    case TemplateRequest_program_deep{}: template_body_program_deep()
    case TemplateRequest_classify{arg_0}: template_body_classify(arg_0)
    case TemplateRequest_deep_chain_check{}: template_body_deep_chain_check()
    case TemplateRequest_erased_fld{}: template_body_erased_fld()
    case TemplateRequest_fam_erased{}: template_body_fam_erased()
    case TemplateRequest_families_plan{}: template_body_families_plan()
    case TemplateRequest_row_pt{}: template_body_row_pt()
    case TemplateRequest_row_er{}: template_body_row_er()
    case TemplateRequest_row_w32{}: template_body_row_w32()
    case TemplateRequest_program_rows{}: template_body_program_rows()
    case TemplateRequest_fam_pt3{}: template_body_fam_pt3()
    case TemplateRequest_program_scope{}: template_body_program_scope()
    case TemplateRequest_fam_same_one{}: template_body_fam_same_one()
    case TemplateRequest_fam_same_two{}: template_body_fam_same_two()
    case TemplateRequest_program_first{}: template_body_program_first()
    case TemplateRequest_erased_slot_ordinals{arg_0}: template_body_erased_slot_ordinals(arg_0)
    case TemplateRequest_check_erased_node{arg_0}: template_body_check_erased_node(arg_0)
    case TemplateRequest_check_three_word_node{arg_0}: template_body_check_three_word_node(arg_0)
    case TemplateRequest_check_packed_one{arg_0}: template_body_check_packed_one(arg_0)
    case TemplateRequest_check_node_failed{arg_0}: template_body_check_node_failed(arg_0)
    case TemplateRequest_check_declared_count{arg_0, arg_1}: template_body_check_declared_count(arg_0, arg_1)
    case TemplateRequest_check_declared_none{arg_0}: template_body_check_declared_none(arg_0)
    case TemplateRequest_recursion_layout{arg_0, arg_1, arg_2}: template_body_recursion_layout(arg_0, arg_1, arg_2)
    case TemplateRequest_recursion_functions{}: template_body_recursion_functions()
    case TemplateRequest_recursive_descriptors{}: template_body_recursive_descriptors()
    case TemplateRequest_recursive_descriptor_failures{arg_0, arg_1}: template_body_recursive_descriptor_failures(arg_0, arg_1)
    case TemplateRequest_check_single_box_field{arg_0}: template_body_check_single_box_field(arg_0)
    case TemplateRequest_check_recursive_key{arg_0, arg_1}: template_body_check_recursive_key(arg_0, arg_1)
    case TemplateRequest_generic_recursion_check{}: template_body_generic_recursion_check()
    case TemplateRequest_duplicate_recursion_check{}: template_body_duplicate_recursion_check()
    case TemplateRequest_target_exclusion_boundaries{}: template_body_target_exclusion_boundaries()
    case TemplateRequest_target_closure_authority_check{}: template_body_target_closure_authority_check()
    case TemplateRequest_explicit_recursion_check{}: template_body_explicit_recursion_check()
    case TemplateRequest_recursion_boundaries{}: template_body_recursion_boundaries()
    case TemplateRequest_main{arg_0}: template_body_main(arg_0)
    case TemplateRequest_cps_provider_1_context{arg_0}: template_body_cps_provider_1_context(arg_0)
    case TemplateRequest_cps_provider_1_context_nf{arg_0}: template_body_cps_provider_1_context_nf(arg_0)
    case TemplateRequest_cps_provider_1_context_families{arg_0}: template_body_cps_provider_1_context_families(arg_0)
    case TemplateRequest_cps_provider_1_context_plan{arg_0}: template_body_cps_provider_1_context_plan(arg_0)
    case TemplateRequest_cps_provider_1_context_nodes{arg_0}: template_body_cps_provider_1_context_nodes(arg_0)
    case TemplateRequest_cps_provider_1_context_arms{arg_0}: template_body_cps_provider_1_context_arms(arg_0)
    case TemplateRequest_cps_provider_1_context_closed{arg_0}: template_body_cps_provider_1_context_closed(arg_0)
    case TemplateRequest_cps_provider_1_nf_families{arg_0}: template_body_cps_provider_1_nf_families(arg_0)
    case TemplateRequest_cps_provider_1_nf_functions{arg_0}: template_body_cps_provider_1_nf_functions(arg_0)

def template_step_group_2(request: TemplateRequestGroup2) -> TemplateProgress<template_result_group_2(request)>:
  match request:
    case TemplateRequest_cps_provider_1_family_lookup{arg_0, arg_1}: template_body_cps_provider_1_family_lookup(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_function_lookup{arg_0, arg_1}: template_body_cps_provider_1_function_lookup(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_arm_of{arg_0, arg_1}: template_body_cps_provider_1_arm_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_arm_in{arg_0, arg_1}: template_body_cps_provider_1_arm_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_plan_arm_index{arg_0}: template_body_cps_provider_1_plan_arm_index(arg_0)
    case TemplateRequest_cps_provider_1_plan_family_arms{arg_0, arg_1}: template_body_cps_provider_1_plan_family_arms(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_arm_declared{arg_0, arg_1}: template_body_cps_provider_1_arm_declared(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_live_field{arg_0}: template_body_cps_provider_1_live_field(arg_0)
    case TemplateRequest_cps_provider_1_dependency_seed{arg_0, arg_1}: template_body_cps_provider_1_dependency_seed(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_name{arg_0, arg_1}: template_body_cps_provider_1_dependency_name(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_descriptors{arg_0, arg_1}: template_body_cps_provider_1_dependency_descriptors(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_patterns{arg_0, arg_1}: template_body_cps_provider_1_dependency_patterns(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_descriptor{arg_0, arg_1}: template_body_cps_provider_1_dependency_descriptor(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_fields{arg_0, arg_1}: template_body_cps_provider_1_dependency_fields(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_arms{arg_0, arg_1}: template_body_cps_provider_1_dependency_arms(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_families{arg_0, arg_1}: template_body_cps_provider_1_dependency_families(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_functions{arg_0, arg_1}: template_body_cps_provider_1_dependency_functions(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_dependency_maybe_reaches{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_dependency_maybe_reaches(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_dependency_closed{arg_0, arg_1}: template_body_cps_provider_1_dependency_closed(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_plan_closed_facts{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_plan_closed_facts(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_layout_fuel{}: template_body_cps_provider_1_layout_fuel()
    case TemplateRequest_cps_provider_1_nf_of{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_nf_of(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_value_layout{arg_0, arg_1}: template_body_cps_provider_1_value_layout(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_layout_of_desc{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_layout_of_desc(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_layout_of_val{arg_0, arg_1, arg_2}: template_body_cps_provider_1_layout_of_val(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_layout_val{arg_0, arg_1, arg_2}: template_body_cps_provider_1_layout_val(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_layout_unresolved{arg_0, arg_1}: template_body_cps_provider_1_layout_unresolved(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_layout_family{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_layout_family(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_layout_native{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_layout_native(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_field_scope{arg_0}: template_body_cps_provider_1_field_scope(arg_0)
    case TemplateRequest_cps_provider_1_arm_layouts{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_arm_layouts(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_field_layouts{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_field_layouts(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_layout_data{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_layout_data(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_data_reenters{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_data_reenters(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_arms_tagged{arg_0}: template_body_cps_provider_1_arms_tagged(arg_0)
    case TemplateRequest_cps_provider_1_reenters{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_reenters(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_fields_self_reference{arg_0, arg_1}: template_body_cps_provider_1_fields_self_reference(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_fields_reach{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_fields_reach(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_reaches{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_reaches(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_reaches_val{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_reaches_val(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_family_reach{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_family_reach(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_reach_arms{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_reach_arms(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_args_reach{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_args_reach(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_1_str_member{arg_0, arg_1}: template_body_cps_provider_1_str_member(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_layout_kinds{arg_0}: template_body_cps_provider_1_layout_kinds(arg_0)
    case TemplateRequest_cps_provider_1_layout_words{arg_0}: template_body_cps_provider_1_layout_words(arg_0)
    case TemplateRequest_cps_provider_1_canonical_word{arg_0}: template_body_cps_provider_1_canonical_word(arg_0)
    case TemplateRequest_cps_provider_1_pack_arms{arg_0, arg_1}: template_body_cps_provider_1_pack_arms(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_pack_arm_list{arg_0, arg_1, arg_2}: template_body_cps_provider_1_pack_arm_list(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_pack_field_list{arg_0, arg_1, arg_2}: template_body_cps_provider_1_pack_field_list(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_pack_kinds{arg_0, arg_1, arg_2}: template_body_cps_provider_1_pack_kinds(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_set_kind{arg_0, arg_1, arg_2}: template_body_cps_provider_1_set_kind(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_merge_kind{arg_0, arg_1}: template_body_cps_provider_1_merge_kind(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_word_32{arg_0}: template_body_cps_provider_1_word_32(arg_0)
    case TemplateRequest_cps_provider_1_pad_words{arg_0}: template_body_cps_provider_1_pad_words(arg_0)
    case TemplateRequest_cps_provider_1_pad_to{arg_0, arg_1}: template_body_cps_provider_1_pad_to(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_pow2_upto{arg_0, arg_1}: template_body_cps_provider_1_pow2_upto(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_ceil_log2{arg_0}: template_body_cps_provider_1_ceil_log2(arg_0)
    case TemplateRequest_cps_provider_1_ceil_log2_go{arg_0, arg_1, arg_2}: template_body_cps_provider_1_ceil_log2_go(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_node_layout{arg_0, arg_1}: template_body_cps_provider_1_node_layout(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_node_layout_fuel{arg_0, arg_1, arg_2}: template_body_cps_provider_1_node_layout_fuel(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_node_at{arg_0, arg_1, arg_2}: template_body_cps_provider_1_node_at(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_plan_node{arg_0, arg_1}: template_body_cps_provider_1_plan_node(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_node_compute{arg_0, arg_1, arg_2}: template_body_cps_provider_1_node_compute(arg_0, arg_1, arg_2)

def template_step_group_3(request: TemplateRequestGroup3) -> TemplateProgress<template_result_group_3(request)>:
  match request:
    case TemplateRequest_cps_provider_1_unresolved_message{arg_0}: template_body_cps_provider_1_unresolved_message(arg_0)
    case TemplateRequest_cps_provider_1_node_arm{arg_0, arg_1, arg_2}: template_body_cps_provider_1_node_arm(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_plan_node_index{arg_0, arg_1}: template_body_cps_provider_1_plan_node_index(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_node_declared{arg_0, arg_1}: template_body_cps_provider_1_node_declared(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_node_slots{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_node_slots(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_node_finish{arg_0}: template_body_cps_provider_1_node_finish(arg_0)
    case TemplateRequest_cps_provider_1_slot_words{arg_0}: template_body_cps_provider_1_slot_words(arg_0)
    case TemplateRequest_cps_provider_1_packed_words{arg_0}: template_body_cps_provider_1_packed_words(arg_0)
    case TemplateRequest_cps_provider_1_node_slot{arg_0, arg_1, arg_2}: template_body_cps_provider_1_node_slot(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_slot_find{arg_0, arg_1}: template_body_cps_provider_1_slot_find(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_layout_fill{arg_0, arg_1}: template_body_cps_provider_1_layout_fill(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_layout_fill_fuel{arg_0, arg_1, arg_2}: template_body_cps_provider_1_layout_fill_fuel(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_layout_unfill{arg_0, arg_1}: template_body_cps_provider_1_layout_unfill(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_layout_unfill_fuel{arg_0, arg_1, arg_2}: template_body_cps_provider_1_layout_unfill_fuel(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_slot_fill{arg_0, arg_1, arg_2}: template_body_cps_provider_1_slot_fill(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_slot_unfill{arg_0, arg_1, arg_2}: template_body_cps_provider_1_slot_unfill(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_form_arms{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_1_form_arms(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_1_form_arm{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_1_form_arm(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_1_tag_word{arg_0}: template_body_cps_provider_1_tag_word(arg_0)
    case TemplateRequest_cps_provider_1_form_nests{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_1_form_nests(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_1_nest{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_nest(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_nest_fits{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_1_nest_fits(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_1_fill_words{arg_0}: template_body_cps_provider_1_fill_words(arg_0)
    case TemplateRequest_cps_provider_1_unfill_words{arg_0}: template_body_cps_provider_1_unfill_words(arg_0)
    case TemplateRequest_cps_provider_1_head_native{arg_0, arg_1}: template_body_cps_provider_1_head_native(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_head_other{arg_0}: template_body_cps_provider_1_head_other(arg_0)
    case TemplateRequest_cps_provider_1_head_value{arg_0, arg_1}: template_body_cps_provider_1_head_value(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_norm{arg_0, arg_1}: template_body_cps_provider_1_norm(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_head_args{arg_0, arg_1}: template_body_cps_provider_1_head_args(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_arm_fields{arg_0, arg_1, arg_2}: template_body_cps_provider_1_arm_fields(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_arm_fields_value{arg_0, arg_1, arg_2}: template_body_cps_provider_1_arm_fields_value(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_1_instantiate_fields{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_1_instantiate_fields(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_1_array_cell{arg_0, arg_1}: template_body_cps_provider_1_array_cell(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_cell_of{arg_0}: template_body_cps_provider_1_cell_of(arg_0)
    case TemplateRequest_cps_provider_1_cell_boxed{arg_0}: template_body_cps_provider_1_cell_boxed(arg_0)
    case TemplateRequest_cps_provider_1_max_one{arg_0}: template_body_cps_provider_1_max_one(arg_0)
    case TemplateRequest_cps_provider_1_layout_has_term{arg_0}: template_body_cps_provider_1_layout_has_term(arg_0)
    case TemplateRequest_cps_provider_1_word_has_term{arg_0}: template_body_cps_provider_1_word_has_term(arg_0)
    case TemplateRequest_cps_provider_1_any_word_has_term{arg_0}: template_body_cps_provider_1_any_word_has_term(arg_0)
    case TemplateRequest_cps_provider_2_family_index{arg_0}: template_body_cps_provider_2_family_index(arg_0)
    case TemplateRequest_cps_provider_2_function_index{arg_0}: template_body_cps_provider_2_function_index(arg_0)
    case TemplateRequest_cps_provider_2_nf_context{arg_0, arg_1}: template_body_cps_provider_2_nf_context(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_default_fuel{}: template_body_cps_provider_2_default_fuel()
    case TemplateRequest_cps_provider_2_family_of{arg_0, arg_1}: template_body_cps_provider_2_family_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_function_of{arg_0, arg_1}: template_body_cps_provider_2_function_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_native_of{arg_0, arg_1, arg_2}: template_body_cps_provider_2_native_of(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_val_nth{arg_0, arg_1}: template_body_cps_provider_2_val_nth(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_val_at{arg_0, arg_1, arg_2}: template_body_cps_provider_2_val_at(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_val_at_choose{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_val_at_choose(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_first_vals{arg_0, arg_1}: template_body_cps_provider_2_first_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_drop_vals{arg_0, arg_1}: template_body_cps_provider_2_drop_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_insert_before{arg_0, arg_1, arg_2}: template_body_cps_provider_2_insert_before(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_append_vals{arg_0, arg_1}: template_body_cps_provider_2_append_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_quantity_markers{arg_0}: template_body_cps_provider_2_quantity_markers(arg_0)
    case TemplateRequest_cps_provider_2_renamed_level{arg_0, arg_1}: template_body_cps_provider_2_renamed_level(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_materialize_all_scoped{arg_0, arg_1, arg_2}: template_body_cps_provider_2_materialize_all_scoped(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_materialize_all_at{arg_0, arg_1}: template_body_cps_provider_2_materialize_all_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_materialize_all{arg_0}: template_body_cps_provider_2_materialize_all(arg_0)
    case TemplateRequest_cps_provider_2_materialize_scoped{arg_0, arg_1, arg_2}: template_body_cps_provider_2_materialize_scoped(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_materialize_at{arg_0, arg_1}: template_body_cps_provider_2_materialize_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_materialize{arg_0}: template_body_cps_provider_2_materialize(arg_0)
    case TemplateRequest_cps_provider_2_reify_env{arg_0, arg_1, arg_2}: template_body_cps_provider_2_reify_env(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_status_combine{arg_0, arg_1}: template_body_cps_provider_2_status_combine(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_bind_status{arg_0, arg_1}: template_body_cps_provider_2_bind_status(arg_0, arg_1)

def template_step_group_4(request: TemplateRequestGroup4) -> TemplateProgress<template_result_group_4(request)>:
  match request:
    case TemplateRequest_cps_provider_2_bind_values{arg_0, arg_1}: template_body_cps_provider_2_bind_values(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_bind_patterns{arg_0, arg_1}: template_body_cps_provider_2_bind_patterns(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_nf{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nf_descriptor{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf_descriptor(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nf_arrow{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_nf_arrow(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_nf_descriptor_step{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf_descriptor_step(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nf_all{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf_all(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nf_apply_args{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_nf_apply_args(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_nf_apply_source{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_nf_apply_source(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_nf_apply{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf_apply(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nf_apply_one{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf_apply_one(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_intrinsic_io{arg_0}: template_body_cps_provider_2_intrinsic_io(arg_0)
    case TemplateRequest_cps_provider_2_nf_named_io{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_nf_named_io(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_nf_named{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf_named(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nf_arity{arg_0, arg_1, arg_2}: template_body_cps_provider_2_nf_arity(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_nf_family{arg_0, arg_1}: template_body_cps_provider_2_nf_family(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_nf_family_apply{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_nf_family_apply(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_nf_reduce{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_nf_reduce(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nf_reduce_apply{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_nf_reduce_apply(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_nf_reduce_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_nf_reduce_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_nf_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_nf_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_normalize{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_normalize(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_normalize_closed{arg_0, arg_1, arg_2}: template_body_cps_provider_2_normalize_closed(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_normalize_in{arg_0, arg_1}: template_body_cps_provider_2_normalize_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_outer_application{arg_0}: template_body_cps_provider_2_outer_application(arg_0)
    case TemplateRequest_cps_provider_2_outer_walk{arg_0, arg_1}: template_body_cps_provider_2_outer_walk(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_answer_in{arg_0, arg_1}: template_body_cps_provider_2_answer_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_answer_descriptor{arg_0, arg_1, arg_2}: template_body_cps_provider_2_answer_descriptor(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_answer_normalized{arg_0, arg_1}: template_body_cps_provider_2_answer_normalized(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_is_io_head_in{arg_0, arg_1}: template_body_cps_provider_2_is_io_head_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_is_io_head{arg_0, arg_1, arg_2}: template_body_cps_provider_2_is_io_head(arg_0, arg_1, arg_2)

def template_step_one(request: TemplateRequest) -> TemplateProgress<template_result(request)>:
  match request:
    case TemplateRequestGroup_0{inner}: template_step_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_step_group_1(inner)
    case TemplateRequestGroup_2{inner}: template_step_group_2(inner)
    case TemplateRequestGroup_3{inner}: template_step_group_3(inner)
    case TemplateRequestGroup_4{inner}: template_step_group_4(inner)

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

def template_start(modules: List<&2, Loader.LoadedModule>) -> TemplateRun<ClaySmoke>:
  template_chunk(ClaySmoke, 64n, TemplateRunState{ClaySmoke, TemplatePending{TemplateRequestGroup_1{TemplateRequest_main{modules}}, box => TemplateFinished{box}}, TemplateStackDone{{==}}})
