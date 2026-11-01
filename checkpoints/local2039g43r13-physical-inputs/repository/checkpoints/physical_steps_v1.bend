import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/index_lookup.bend as IndexLookup

type PhysSmoke is Data:
  PhysSmoke{desc: String, names: String}

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

type cps_provider_3_NfContext is Data:
  cps_provider_3_NfContext{families: Map<&2, BIR.Family>, type_functions: Map<&2, BIR.TypeFunction>}

type cps_provider_1_Plan is Data:
  cps_provider_1_Plan{nodes: Map<&2, cps_provider_1_NodeResult>, arms: Map<&2, BIR.DescriptorArm>}

type cps_provider_1_Context is Data:
  cps_provider_1_Context{context: cps_provider_3_NfContext, families: List<&2, BIR.Family>, plan: cps_provider_1_Plan}

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

type cps_provider_2_Part is Data:
  cps_provider_2_PartOk{text: String}
  cps_provider_2_PartFail{message: String}

type cps_provider_2_CidSym is Data:
  cps_provider_2_CidSym{cid: U32, key: String}

type cps_provider_2_World is Data:
  cps_provider_2_World{ctx: cps_provider_1_Context, constructors: List<&2, BIR.ConstructorLayout>, cids: List<&2, cps_provider_2_CidSym>}

type cps_provider_2_Code is Data:
  cps_provider_2_CodeOk{lines: List<&2, String>}
  cps_provider_2_CodeFail{message: String}

type cps_provider_2_Operand is Data:
  cps_provider_2_Operand{use: BIR.Use, text: String}

type cps_provider_2_Dst is Data:
  cps_provider_2_DstSeq{buf: String, cursor: String}
  cps_provider_2_DstOut{out: String}

type cps_provider_2_Src is Data:
  cps_provider_2_SrcOne{text: String}
  cps_provider_2_SrcNode{base: String, fb: String, cursor: String, packed: Bool}
  cps_provider_2_SrcBlock{loc: String, at: String, arr: Bool, keep: Bool, cursor: String}
  cps_provider_2_SrcBuf{buf: String, cursor: String}

type cps_provider_2_Job is Data:
  cps_provider_2_JText{text: String}
  cps_provider_2_JConv{take: cps_provider_1_Unfill, make: cps_provider_1_Fill, src: cps_provider_2_Src, dst: cps_provider_2_Dst, tag: String}
  cps_provider_2_JFail{message: String}

type cps_provider_2_CellOut is Data:
  cps_provider_2_CellOk{layout: cps_provider_1_Layout, arr: Bool, words: Nat, lgs: Nat}
  cps_provider_2_CellFail{message: String}

type cps_provider_2_ShowWord is Data:
  cps_provider_2_ShowNum{value: Nat}
  cps_provider_2_ShowCid{value: Nat}

type cps_provider_2_ShowPatch is Data:
  cps_provider_2_ShowPatchAt{at: Nat, to: Nat}

type cps_provider_2_ShowState is Data:
  cps_provider_2_ShowState{words: List<&2, cps_provider_2_ShowWord>, patches: List<&2, cps_provider_2_ShowPatch>, memo: Map<&2, Nat>, names: List<&2, String>, error: Maybe<&2, String>}

type cps_provider_2_ShowJob is Data:
  cps_provider_2_ShowNode{ty: BIR.Descriptor, layout: cps_provider_1_Layout, patch: Maybe<&2, Nat>}

type cps_provider_2_ShowAdvance is Data:
  cps_provider_2_ShowNext{state: cps_provider_2_ShowState, kids: List<&2, cps_provider_2_ShowJob>}

type cps_provider_2_ShowRun is Data:
  cps_provider_2_ShowDone{state: cps_provider_2_ShowState}

type cps_provider_2_ShowOut is Data:
  cps_provider_2_ShowOk{desc: String, names: String}
  cps_provider_2_ShowFail{message: String}

type cps_provider_2_ShowKind is Data:
  cps_provider_2_ShowKindOk{kind: Nat}
  cps_provider_2_ShowKindFailed{message: String}

type cps_provider_2_ShowNorm is Data:
  cps_provider_2_ShowNormOk{descriptor: BIR.Descriptor}
  cps_provider_2_ShowNormFailed{message: String}

type cps_provider_2_ShowToken is Data:
  cps_provider_2_ShowTokDesc{descriptor: BIR.Descriptor}
  cps_provider_2_ShowTokText{text: String}
  cps_provider_2_ShowTokPat{pattern: BIR.DescriptorPattern}

type cps_provider_2_PathStep is Data:
  cps_provider_2_PathField{constructor: U32, field: U32}
  cps_provider_2_PathHalf{low: Bool, element: BIR.Descriptor}
  cps_provider_2_PathLeafCell{element: BIR.Descriptor}

type cps_provider_2_PathState is Data:
  cps_provider_2_StSlot{offset: Nat, layout: cps_provider_1_Layout, base: String, uniq: String, stat: String, packed: Bool}
  cps_provider_2_StArray{loc: String, cls: String, lgs: Nat, cell: cps_provider_1_Layout, arr: String, off: String, buf: Bool, uniq: String, stat: String}
  cps_provider_2_StCell{loc: String, arr: String, index: String, cls: String, layout: cps_provider_1_Layout, lgs: Nat, buf: Bool, uniq: String, stat: String}
  cps_provider_2_StBufField{loc: String, index: String, layout: cps_provider_1_Layout, uniq: String, stat: String}

type cps_provider_2_PathResult is Data:
  cps_provider_2_PathOk{state: cps_provider_2_PathState}
  cps_provider_2_PathFail{message: String}

type cps_provider_3_NfVal is Data:
  cps_provider_3_NfType{key: String, args: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfCtor{key: String, args: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfQuantity{quantity: BIR.Quantity}
  cps_provider_3_NfKind{quantity: cps_provider_3_NfVal}
  cps_provider_3_NfOther{source: BIR.Descriptor}
  cps_provider_3_NfMissing{source: BIR.Descriptor}
  cps_provider_3_NfBinder{level: Nat}
  cps_provider_3_NfArrow{quantity: BIR.Quantity, domain: cps_provider_3_NfVal, body: cps_provider_3_NfVal, level: Nat}
  cps_provider_3_NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, cps_provider_3_NfVal>}

type cps_provider_3_NfRenaming is Data:
  cps_provider_3_NfRenaming{source: Nat, target: Nat}

type cps_provider_3_NfBind is Data:
  cps_provider_3_NfBound{bindings: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfMismatch{}
  cps_provider_3_NfUnknown{}

type cps_provider_3_NfStatus is Data:
  cps_provider_3_NfStatusOk{}
  cps_provider_3_NfStatusNo{}
  cps_provider_3_NfStatusMaybe{}

type cps_provider_3_Nf is Data:
  cps_provider_3_NfOk{val: cps_provider_3_NfVal}
  cps_provider_3_NfFail{message: String}

type cps_provider_3_NfList is Data:
  cps_provider_3_NfListOk{vals: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfListFail{message: String}

type cps_provider_3_NfApp is Data:
  cps_provider_3_NfApp{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_3_NfArity is Data:
  cps_provider_3_NfArity{complete: Bool, exact: Bool, under: Bool}


# Bounded typed request groups; every source declaration retains its checked signature.
type TemplateRequestGroup0 is Type:
  TemplateRequest_fld{+v_0: BIR.Descriptor}
  TemplateRequest_arm{+v_1: String, +v_3: List<&2, BIR.DescriptorField>}
  TemplateRequest_fam{+v_1: String, +v_4: Maybe<&2, String>, +v_6: Nat, +v_8: List<&2, BIR.DescriptorArm>}
  TemplateRequest_ref{+v_1: String, +v_3: List<&2, BIR.Descriptor>}
  TemplateRequest_fam_u32{}
  TemplateRequest_fam_pt{}
  TemplateRequest_fam_fl{}
  TemplateRequest_fam_seg{}
  TemplateRequest_families{}
  TemplateRequest_constructors{}
  TemplateRequest_program{}
  TemplateRequest_chain_key{+v_1: Nat}
  TemplateRequest_next_key{+v_1: Nat}
  TemplateRequest_fam_chain{+v_1: Nat}
  TemplateRequest_ctor_chain{+v_1: Nat}
  TemplateRequest_deep_program{}
  TemplateRequest_summarize{+v_1: cps_provider_2_ShowOut}
  TemplateRequest_deep_text{+v_1: cps_provider_2_ShowOut}
  TemplateRequest_deep_summary{}
  TemplateRequest_shadow_fams{}
  TemplateRequest_shadow_ctors{}
  TemplateRequest_shadow_program{}
  TemplateRequest_shadow_one{+v_1: String, +v_3: cps_provider_1_Context}
  TemplateRequest_shadow_summary{}
  TemplateRequest_key_pair{+v_0: BIR.Descriptor, +v_1: BIR.Descriptor}
  TemplateRequest_deep_key_probe{}
  TemplateRequest_key_checks{}
  TemplateRequest_multi_fams{}
  TemplateRequest_multi_ctors{}
  TemplateRequest_multi_program{}
  TemplateRequest_multi_text{+v_1: cps_provider_2_ShowOut}
  TemplateRequest_multi_summary{}
  TemplateRequest_main{v_1: List<&2, Loader.LoadedModule>}
  TemplateRequest_unwrap{+v_1: cps_provider_2_ShowOut, +v_3: String}
  TemplateRequest_cps_provider_1_context{+v_0: BIR.Program}
  TemplateRequest_cps_provider_1_context_nf{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_families{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_plan{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_nodes{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_context_arms{+v_1: cps_provider_1_Context}
  TemplateRequest_cps_provider_1_nf_families{+v_1: cps_provider_3_NfContext}
  TemplateRequest_cps_provider_1_nf_functions{+v_1: cps_provider_3_NfContext}
  TemplateRequest_cps_provider_1_family_lookup{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_function_lookup{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_arm_of{+v_1: String, +v_3: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_1_arm_in{+v_1: String, +v_3: List<&2, BIR.DescriptorArm>}
  TemplateRequest_cps_provider_1_plan_arm_index{+v_1: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_1_plan_family_arms{+v_1: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>}
  TemplateRequest_cps_provider_1_arm_declared{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_live_field{+v_0: BIR.Quantity}
  TemplateRequest_cps_provider_1_layout_fuel{}
  TemplateRequest_cps_provider_1_nf_of{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_1_value_layout{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_layout_of_desc{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_1_layout_of_val{+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat}
  TemplateRequest_cps_provider_1_layout_val{+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat}
  TemplateRequest_cps_provider_1_layout_unresolved{+v_1: cps_provider_1_Context, +v_3: String}
  TemplateRequest_cps_provider_1_layout_family{+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_1_layout_native{+v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat}
  TemplateRequest_cps_provider_1_field_scope{+v_2: List<&2, cps_provider_3_NfVal>}
  TemplateRequest_cps_provider_1_arm_layouts{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>}
  TemplateRequest_cps_provider_1_field_layouts{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>}
  TemplateRequest_cps_provider_1_layout_data{+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat}
  TemplateRequest_cps_provider_1_arms_tagged{+v_2: List<&2, cps_provider_1_LayArm>}

type TemplateRequestGroup1 is Type:
  TemplateRequest_cps_provider_1_reenters{+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat}
  TemplateRequest_cps_provider_1_fields_reach{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat}
  TemplateRequest_cps_provider_1_reaches{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat}
  TemplateRequest_cps_provider_1_reaches_val{+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: String, +v_8: List<&2, String>, +v_10: Nat}
  TemplateRequest_cps_provider_1_family_reach{+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat}
  TemplateRequest_cps_provider_1_reach_arms{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat}
  TemplateRequest_cps_provider_1_args_reach{+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat}
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
  TemplateRequest_cps_provider_1_head_value{+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal}
  TemplateRequest_cps_provider_1_norm{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_head_args{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_arm_fields{+v_1: cps_provider_1_Context, +v_3: String, +v_4: BIR.Descriptor}
  TemplateRequest_cps_provider_1_arm_fields_value{+v_1: cps_provider_1_Context, +v_3: String, +v_5: cps_provider_3_NfVal}
  TemplateRequest_cps_provider_1_instantiate_fields{+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>}
  TemplateRequest_cps_provider_1_array_cell{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_1_cell_of{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_cell_boxed{+v_1: cps_provider_1_BoxReason}
  TemplateRequest_cps_provider_1_max_one{+v_1: Nat}

type TemplateRequestGroup2 is Type:
  TemplateRequest_cps_provider_1_layout_has_term{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_1_word_has_term{+v_1: cps_provider_1_CWord}
  TemplateRequest_cps_provider_1_any_word_has_term{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_2_world{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, cps_provider_2_CidSym>}
  TemplateRequest_cps_provider_2_join_text{+v_2: List<&2, String>}
  TemplateRequest_cps_provider_2_code_line{+v_1: String}
  TemplateRequest_cps_provider_2_code_empty{}
  TemplateRequest_cps_provider_2_code_seq{+v_1: cps_provider_2_Code, +v_3: cps_provider_2_Code}
  TemplateRequest_cps_provider_2_code_text{+v_2: List<&2, String>, +v_4: String}
  TemplateRequest_cps_provider_2_part_of{+v_1: cps_provider_2_Code, +v_3: String}
  TemplateRequest_cps_provider_2_ctor_find{+v_1: U32, +v_3: List<&2, BIR.ConstructorLayout>}
  TemplateRequest_cps_provider_2_ctor_of{+v_1: U32, +v_3: cps_provider_2_World}
  TemplateRequest_cps_provider_2_cid_find{+v_1: String, +v_4: List<&2, cps_provider_2_CidSym>}
  TemplateRequest_cps_provider_2_cid_of{+v_1: String, +v_3: cps_provider_2_World}
  TemplateRequest_cps_provider_2_cid_text_of{+v_2: Maybe<&2, U32>}
  TemplateRequest_cps_provider_2_cid_text{+v_1: String, +v_3: cps_provider_2_World}
  TemplateRequest_cps_provider_2_intrinsic_marker{+v_1: String}
  TemplateRequest_cps_provider_2_dst_write{+v_1: cps_provider_2_Dst, +v_3: String}
  TemplateRequest_cps_provider_2_dst_word{+v_1: cps_provider_2_Dst, +v_3: cps_provider_1_CWord, +v_5: String}
  TemplateRequest_cps_provider_2_dst_decl{+v_1: String, +v_3: String, +v_5: Nat}
  TemplateRequest_cps_provider_2_dst_mark{+v_1: cps_provider_2_Dst, +v_3: Nat}
  TemplateRequest_cps_provider_2_form_base{+v_1: Nat, +v_3: Bool}
  TemplateRequest_cps_provider_2_form_pad{+v_1: Nat, +v_3: Nat}
  TemplateRequest_cps_provider_2_src_skip_jobs{+v_1: cps_provider_2_Src, +v_3: Nat}
  TemplateRequest_cps_provider_2_dst_skip_jobs{+v_1: cps_provider_2_Dst, +v_3: Nat}
  TemplateRequest_cps_provider_2_src_read_node{+v_1: String, +v_3: String, +v_5: String, +v_7: Bool, +v_9: String}
  TemplateRequest_cps_provider_2_src_read_arr{+v_1: String, +v_3: String, +v_5: Bool, +v_7: String, +v_9: String}
  TemplateRequest_cps_provider_2_src_read_block{+v_1: String, +v_3: String, +v_5: Bool, +v_7: Bool, +v_9: String, +v_11: String}
  TemplateRequest_cps_provider_2_src_read{+v_1: cps_provider_2_Src, +v_3: String}
  TemplateRequest_cps_provider_2_form_tagged{+v_2: List<&2, cps_provider_1_FormArm>}
  TemplateRequest_cps_provider_2_max_node_words{+v_2: List<&2, cps_provider_1_FormArm>, +v_4: Nat}
  TemplateRequest_cps_provider_2_max_term_decl{+v_1: String, +v_3: Nat}
  TemplateRequest_cps_provider_2_arm_seed{+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String}
  TemplateRequest_cps_provider_2_arm_seed_words{+v_1: Nat, +v_3: String, +v_5: String, +v_7: String}
  TemplateRequest_cps_provider_2_arm_src{+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String}
  TemplateRequest_cps_provider_2_nests_jobs{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_Nest>, +v_6: cps_provider_2_Src, +v_8: cps_provider_2_Dst, +v_10: String, +v_12: Nat}
  TemplateRequest_cps_provider_2_arm_release{+v_1: Bool, +v_3: Nat, +v_5: String}
  TemplateRequest_cps_provider_2_jobs_arm_body{+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_14: List<&2, cps_provider_1_Nest>, +v_16: String, +v_18: cps_provider_2_Dst, +v_20: String, +v_22: Bool, +v_24: String, +v_26: Nat}
  TemplateRequest_cps_provider_2_jobs_arm{+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_14: List<&2, cps_provider_1_Nest>, +v_16: String, +v_18: cps_provider_2_Dst, +v_20: String, +v_22: Bool, +v_24: String, +v_26: Nat}
  TemplateRequest_cps_provider_2_arm_jobs{+v_1: cps_provider_2_World, +v_4: Maybe<&2, U32>, +v_6: cps_provider_1_FormArm, +v_8: Nat, +v_10: String, +v_12: cps_provider_2_Dst, +v_14: String, +v_16: Bool, +v_18: String, +v_20: Nat}
  TemplateRequest_cps_provider_2_unbox_cases{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: String, +v_10: cps_provider_2_Dst, +v_12: String, +v_14: Bool, +v_16: String}
  TemplateRequest_cps_provider_2_expand_unbox{+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: cps_provider_2_Src, +v_10: cps_provider_2_Dst, +v_12: String}
  TemplateRequest_cps_provider_2_expand_word_take{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Fill, +v_5: cps_provider_2_Src, +v_7: cps_provider_2_Dst, +v_9: String}
  TemplateRequest_cps_provider_2_nest_take{+v_1: cps_provider_1_Nest}
  TemplateRequest_cps_provider_2_nest_make{+v_1: cps_provider_1_Nest}
  TemplateRequest_cps_provider_2_field_pair_jobs{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_Nest>, +v_7: List<&2, cps_provider_1_Nest>, +v_9: cps_provider_2_Src, +v_11: cps_provider_2_Dst, +v_13: String, +v_15: Nat}
  TemplateRequest_cps_provider_2_forms_arm_body{+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_Nest>, +v_8: Nat, +v_10: Nat, +v_12: Bool, +v_15: Maybe<&2, cps_provider_1_FormArm>, +v_17: cps_provider_2_Src, +v_19: cps_provider_2_Dst, +v_21: String}
  TemplateRequest_cps_provider_2_forms_arm_case{+v_1: cps_provider_2_World, +v_4: Maybe<&2, cps_provider_1_FormArm>, +v_6: cps_provider_1_FormArm, +v_8: Nat, +v_10: Nat, +v_12: Bool, +v_14: cps_provider_2_Src, +v_16: cps_provider_2_Dst, +v_18: String, +v_20: Nat}
  TemplateRequest_cps_provider_2_form_arm_by_key{+v_1: String, +v_4: List<&2, cps_provider_1_FormArm>}
  TemplateRequest_cps_provider_2_forms_cases{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_7: List<&2, cps_provider_1_FormArm>, +v_9: Nat, +v_11: Nat, +v_13: Bool, +v_15: cps_provider_2_Src, +v_17: cps_provider_2_Dst, +v_19: String, +v_21: Nat}
  TemplateRequest_cps_provider_2_expand_forms{+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: Nat, +v_11: List<&2, cps_provider_1_FormArm>, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String}
  TemplateRequest_cps_provider_2_forms_single{+v_1: cps_provider_2_World, +v_3: cps_provider_1_FormArm, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_12: List<&2, cps_provider_1_FormArm>, +v_14: cps_provider_2_Src, +v_16: cps_provider_2_Dst, +v_18: String}
  TemplateRequest_cps_provider_2_pack_jobs{+v_1: U32, +v_3: Nat, +v_5: Bool, +v_7: String, +v_9: String, +v_11: String}
  TemplateRequest_cps_provider_2_arm_block_jobs{+v_1: cps_provider_2_World, +v_3: U32, +v_5: cps_provider_1_FormArm, +v_7: Nat, +v_9: cps_provider_2_Src, +v_11: String, +v_13: String, +v_15: Nat}
  TemplateRequest_cps_provider_2_box_arm_jobs{+v_1: cps_provider_2_World, +v_4: Maybe<&2, U32>, +v_6: cps_provider_1_FormArm, +v_8: Nat, +v_10: cps_provider_2_Src, +v_12: String, +v_14: String, +v_16: Nat}
  TemplateRequest_cps_provider_2_box_cases{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String, +v_14: Nat}
  TemplateRequest_cps_provider_2_box_untagged{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String}
  TemplateRequest_cps_provider_2_expand_box{+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: cps_provider_2_Src, +v_10: cps_provider_2_Dst, +v_12: String}
  TemplateRequest_cps_provider_2_expand_box_body{+v_1: Bool, +v_3: Nat, +v_5: cps_provider_2_World, +v_8: List<&2, cps_provider_1_FormArm>, +v_10: cps_provider_2_Src, +v_12: cps_provider_2_Dst, +v_14: String, +v_16: String}
  TemplateRequest_cps_provider_2_expand_form_take{+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: cps_provider_1_Fill, +v_10: cps_provider_2_Src, +v_12: cps_provider_2_Dst, +v_14: String}
  TemplateRequest_cps_provider_2_expand_conv{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Unfill, +v_5: cps_provider_1_Fill, +v_7: cps_provider_2_Src, +v_9: cps_provider_2_Dst, +v_11: String}
  TemplateRequest_cps_provider_2_run_jobs{+v_2: List<&2, cps_provider_2_Job>, +v_4: cps_provider_2_World, +v_7: List<&2, String>}
  TemplateRequest_cps_provider_2_fill_plan_jobs{+v_1: cps_provider_1_Fill, +v_3: String, +v_5: cps_provider_2_Dst, +v_7: String}
  TemplateRequest_cps_provider_2_fill_result_jobs{+v_1: cps_provider_1_FillResult, +v_3: String, +v_5: cps_provider_2_Dst, +v_7: String}

type TemplateRequestGroup3 is Type:
  TemplateRequest_cps_provider_2_fill_data_jobs{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: cps_provider_2_Dst, +v_9: String}
  TemplateRequest_cps_provider_2_fill_jobs{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: cps_provider_2_Dst, +v_9: String}
  TemplateRequest_cps_provider_2_unfill_result_jobs{+v_1: cps_provider_1_UnfillResult, +v_3: cps_provider_2_Src, +v_5: String, +v_7: String}
  TemplateRequest_cps_provider_2_unfill_data_jobs{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: cps_provider_2_Src, +v_7: String, +v_9: String}
  TemplateRequest_cps_provider_2_unfill_word_jobs{+v_1: cps_provider_1_CWord, +v_3: cps_provider_2_Src, +v_5: String, +v_7: String}
  TemplateRequest_cps_provider_2_unfill_jobs{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: cps_provider_2_Src, +v_7: String, +v_9: String}
  TemplateRequest_cps_provider_2_operand_code{+v_1: cps_provider_1_Layout, +v_2: BIR.Use, +v_4: String, +v_6: String}
  TemplateRequest_cps_provider_2_operand_name{+v_1: cps_provider_1_Layout, +v_2: BIR.Use, +v_4: String, +v_6: String}
  TemplateRequest_cps_provider_2_text_jobs{+v_2: List<&2, String>}
  TemplateRequest_cps_provider_2_code_jobs{+v_1: cps_provider_2_Code}
  TemplateRequest_cps_provider_2_fill_slots_jobs{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_layout_is_data{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_seal_box_many{+v_1: String, +v_3: Bool}
  TemplateRequest_cps_provider_2_seal_box{+v_0: BIR.Use, +v_2: String, +v_4: Bool}
  TemplateRequest_cps_provider_2_seal_kind{+v_0: BIR.Use, +v_2: cps_provider_1_CWord, +v_4: String, +v_6: Bool}
  TemplateRequest_cps_provider_2_seal_kind_walk{+v_0: BIR.Use, +v_3: List<&2, cps_provider_1_CWord>, +v_5: String, +v_7: Bool}
  TemplateRequest_cps_provider_2_seal_slots_jobs{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_one_job{+v_1: cps_provider_2_Job}
  TemplateRequest_cps_provider_2_construct_words{+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_8: List<&2, cps_provider_1_NodeSlot>, +v_11: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_codeSeqPack{+v_1: cps_provider_2_Code, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Layout, +v_7: String, +v_9: U32}
  TemplateRequest_cps_provider_2_construct_packed_one{+v_1: cps_provider_2_World, +v_3: U32, +v_5: cps_provider_1_NodeSlot, +v_7: cps_provider_2_Operand}
  TemplateRequest_cps_provider_2_construct_packed{+v_1: cps_provider_2_World, +v_3: U32, +v_5: String, +v_7: cps_provider_1_Node, +v_10: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_packed_flag{+v_1: Bool, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_9: cps_provider_1_Node, +v_12: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_count{+v_1: Bool, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_9: cps_provider_1_Node, +v_12: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_node{+v_1: cps_provider_2_World, +v_3: U32, +v_5: String, +v_7: cps_provider_1_Node, +v_10: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_layout{+v_1: cps_provider_1_NodeResult, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_10: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_cid{+v_2: Maybe<&2, U32>, +v_4: cps_provider_2_World, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_generic{+v_1: cps_provider_2_World, +v_3: String, +v_6: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_marker{+v_1: Bool, +v_3: cps_provider_2_World, +v_5: String, +v_8: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_native{+v_2: Maybe<&2, String>, +v_4: cps_provider_2_World, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_row{+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: cps_provider_2_World, +v_6: List<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_construct_part{+v_1: U32, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_term_decl_text{+v_1: Nat}
  TemplateRequest_cps_provider_2_project_prelude{+v_1: cps_provider_1_Layout, +v_3: String, +v_5: Nat, +v_7: Nat}
  TemplateRequest_cps_provider_2_project_words{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: Nat, +v_7: Nat, +v_9: String}
  TemplateRequest_cps_provider_2_project_packed_prelude{+v_1: cps_provider_1_Layout, +v_3: String}
  TemplateRequest_cps_provider_2_project_packed{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String}
  TemplateRequest_cps_provider_2_project_packed_flag{+v_1: Bool, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Layout, +v_7: Nat, +v_9: Nat, +v_11: String}
  TemplateRequest_cps_provider_2_unique_expr{+v_1: String}
  TemplateRequest_cps_provider_2_static_expr{+v_1: String}
  TemplateRequest_cps_provider_2_and_expr{+v_1: String, +v_3: String}
  TemplateRequest_cps_provider_2_or_expr{+v_1: String, +v_3: String}
  TemplateRequest_cps_provider_2_nat_if{+v_1: Bool, +v_3: Nat, +v_5: Nat}
  TemplateRequest_cps_provider_2_live_ordinal{+v_1: List<&2, BIR.DescriptorField>, +v_3: U32}
  TemplateRequest_cps_provider_2_live_walk{+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat}
  TemplateRequest_cps_provider_2_live_next{+v_0: BIR.Quantity, +v_2: Nat}
  TemplateRequest_cps_provider_2_arm_fields_of{+v_2: List<&2, cps_provider_1_LayArm>, +v_4: String}
  TemplateRequest_cps_provider_2_arm_fields_declared{+v_1: Maybe<&2, BIR.DescriptorArm>}
  TemplateRequest_cps_provider_2_arm_descriptor_fields{+v_1: cps_provider_2_World, +v_3: String}
  TemplateRequest_cps_provider_2_step_key{+v_1: cps_provider_2_World, +v_3: U32}
  TemplateRequest_cps_provider_2_cell_lgs{+v_1: cps_provider_2_World, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_2_not_bool{+v_1: Bool}
  TemplateRequest_cps_provider_2_live_ordinal_in{+v_1: List<&2, BIR.DescriptorField>, +v_3: U32, +v_5: U32, +v_7: U32}
  TemplateRequest_cps_provider_2_inline_slot{+v_2: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_6: Nat}
  TemplateRequest_cps_provider_2_inline_start{+v_2: List<&2, cps_provider_1_LayArm>}
  TemplateRequest_cps_provider_2_state_array{+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor}
  TemplateRequest_cps_provider_2_state_from_array_value{+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor}
  TemplateRequest_cps_provider_2_resolve_field{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_5: U32, +v_7: U32, +v_10: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_resolve_slot_field{+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: cps_provider_1_Layout, +v_11: String, +v_13: String, +v_15: String, +v_17: Bool, +v_20: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_resolve_cell_field{+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_13: cps_provider_1_Layout, +v_15: Nat, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_resolve_buf_field{+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_11: cps_provider_1_Layout, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_resolve_node_slot{+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_root_array_path{+v_1: cps_provider_2_World, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_advance{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_6: List<&2, cps_provider_2_PathStep>}

type TemplateRequestGroup4 is Type:
  TemplateRequest_cps_provider_2_array_from_state{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_4: BIR.Descriptor}
  TemplateRequest_cps_provider_2_half_state{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_5: Bool, +v_6: BIR.Descriptor, +v_9: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_leaf_state{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_resolve_path{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_2_PathStep>}
  TemplateRequest_cps_provider_2_path_prelude{+v_1: String}
  TemplateRequest_cps_provider_2_path_expr{+v_1: String, +v_3: String}
  TemplateRequest_cps_provider_2_keep_copy{+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_11: cps_provider_1_Layout, +v_13: String}
  TemplateRequest_cps_provider_2_keep_copy_fields{+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: String}
  TemplateRequest_cps_provider_2_keep_copy_cases{+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_LayArm>, +v_14: String, +v_16: Nat}
  TemplateRequest_cps_provider_2_move_copy{+v_1: String, +v_3: Nat, +v_5: Nat, +v_7: cps_provider_1_Layout, +v_9: String}
  TemplateRequest_cps_provider_2_move_copy_fields{+v_1: String, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_1_Layout>, +v_10: String}
  TemplateRequest_cps_provider_2_move_copy_cases{+v_1: String, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_1_LayArm>, +v_10: String, +v_12: Nat}
  TemplateRequest_cps_provider_2_raw_word_expr{+v_1: String, +v_3: Nat, +v_5: cps_provider_1_CWord}
  TemplateRequest_cps_provider_2_packed_form_body{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String}
  TemplateRequest_cps_provider_2_read_body{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_tag_single{+v_1: cps_provider_2_World, +v_3: String, +v_6: Maybe<&2, U32>, +v_8: String}
  TemplateRequest_cps_provider_2_tag_multi{+v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String}
  TemplateRequest_cps_provider_2_tag_case_line{+v_1: String, +v_3: Nat, +v_5: U32, +v_8: Maybe<&2, U32>, +v_10: String}
  TemplateRequest_cps_provider_2_tag_multi_packed{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_LayArm>, +v_7: Maybe<&2, U32>, +v_9: String}
  TemplateRequest_cps_provider_2_tag_multi_packed_go{+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_LayArm>, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String}
  TemplateRequest_cps_provider_2_tag_multi_buf{+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: String}
  TemplateRequest_cps_provider_2_tag_multi_buf_go{+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String}
  TemplateRequest_cps_provider_2_tag_body{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_6: Maybe<&2, U32>, +v_8: String}
  TemplateRequest_cps_provider_2_copy_slot_body{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_packed_data_value{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_packed_data_copy{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_box_copy_body{+v_1: String, +v_3: Nat, +v_5: String, +v_7: String}
  TemplateRequest_cps_provider_2_data_copy_body{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat, +v_9: String, +v_11: String}
  TemplateRequest_cps_provider_2_zero_value_body{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_buf_clear_words{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String}
  TemplateRequest_cps_provider_2_buf_field_body{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: Bool}
  TemplateRequest_cps_provider_2_buf_move_clear{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool}
  TemplateRequest_cps_provider_2_cell_arr_body{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: String, +v_11: String, +v_13: Bool}
  TemplateRequest_cps_provider_2_cell_move_clear{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool}
  TemplateRequest_cps_provider_2_cell_data_body{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: String, +v_11: Nat, +v_13: String, +v_15: String, +v_17: Bool}
  TemplateRequest_cps_provider_2_buf_clear_span{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String}
  TemplateRequest_cps_provider_2_copy_cell_body{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_copy_padding{+v_1: Nat, +v_3: Nat, +v_5: String}
  TemplateRequest_cps_provider_2_array_inner{+v_1: Bool, +v_3: String, +v_5: String, +v_7: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_array_copy_body{+v_1: cps_provider_2_PathState, +v_3: Bool}
  TemplateRequest_cps_provider_2_pow2{+v_1: Nat}
  TemplateRequest_cps_provider_2_move_cell_body{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_move_slot_body{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_data_move_body{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat}
  TemplateRequest_cps_provider_2_state_stat{+v_1: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_state_uniq{+v_1: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_path_body_copy{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_path_body_move{+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState}
  TemplateRequest_cps_provider_2_path_read{+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_runtime_cid_of_ctor{+v_1: cps_provider_2_World, +v_3: U32}
  TemplateRequest_cps_provider_2_canonical_bool{+v_1: cps_provider_2_World, +v_3: String}
  TemplateRequest_cps_provider_2_path_hastag{+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: U32, +v_8: cps_provider_2_World}
  TemplateRequest_cps_provider_2_path_copy{+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_path_consume{+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_path_is_leaf{+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_path_is_node{+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_project_plan{+v_1: cps_provider_1_UnfillResult, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Node, +v_7: cps_provider_1_Layout, +v_9: Nat, +v_11: String}
  TemplateRequest_cps_provider_2_project_slot{+v_1: cps_provider_1_SlotResult, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Node, +v_7: String, +v_9: U32, +v_11: String}
  TemplateRequest_cps_provider_2_project_layout{+v_1: cps_provider_1_NodeResult, +v_3: cps_provider_2_World, +v_5: String, +v_7: U32, +v_9: String}
  TemplateRequest_cps_provider_2_project_node{+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String}
  TemplateRequest_cps_provider_2_project_marker{+v_1: Bool, +v_3: String, +v_5: String, +v_7: U32, +v_9: cps_provider_2_World}
  TemplateRequest_cps_provider_2_project_native{+v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_8: U32, +v_10: cps_provider_2_World}
  TemplateRequest_cps_provider_2_project_row{+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: U32, +v_7: cps_provider_2_World}
  TemplateRequest_cps_provider_2_project_part{+v_1: String, +v_3: U32, +v_5: U32, +v_7: cps_provider_2_World}

type TemplateRequestGroup5 is Type:
  TemplateRequest_cps_provider_2_hastag_bools{+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: U32, +v_9: String}
  TemplateRequest_cps_provider_2_hastag_cid{+v_2: Maybe<&2, U32>, +v_4: String, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_hastag_row{+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_hastag_part{+v_1: String, +v_3: U32, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_arr_flag{+v_1: Bool}
  TemplateRequest_cps_provider_2_array_label{+v_0: BIR.Primitive}
  TemplateRequest_cps_provider_2_descriptor_missing{+v_0: BIR.Primitive}
  TemplateRequest_cps_provider_2_array_cell_result{+v_1: cps_provider_1_CellResult}
  TemplateRequest_cps_provider_2_array_cell{+v_1: cps_provider_2_World, +v_3: List<&2, BIR.Descriptor>, +v_4: BIR.Primitive}
  TemplateRequest_cps_provider_2_operand_at{+v_2: List<&2, cps_provider_2_Operand>, +v_4: Nat}
  TemplateRequest_cps_provider_2_operand_text{+v_1: cps_provider_2_Operand}
  TemplateRequest_cps_provider_2_operand_use{+v_1: cps_provider_2_Operand}
  TemplateRequest_cps_provider_2_keep_text{+v_1: cps_provider_2_Operand}
  TemplateRequest_cps_provider_2_tuple_cid{+v_2: Maybe<&2, String>, +v_4: String, +v_6: String}
  TemplateRequest_cps_provider_2_tuple_part{+v_1: cps_provider_2_World, +v_3: String, +v_5: String}
  TemplateRequest_cps_provider_2_seal_cell_box{+v_0: BIR.Use, +v_2: String}
  TemplateRequest_cps_provider_2_seal_cell_kind{+v_0: BIR.Use, +v_2: cps_provider_1_CWord, +v_4: String}
  TemplateRequest_cps_provider_2_seal_cell_walk{+v_0: BIR.Use, +v_3: List<&2, cps_provider_1_CWord>, +v_5: String}
  TemplateRequest_cps_provider_2_elem_fill_operand{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_4: BIR.Use, +v_6: cps_provider_2_Code, +v_8: String, +v_10: String}
  TemplateRequest_cps_provider_2_elem_fill{+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_4: BIR.Use, +v_6: String, +v_8: String}
  TemplateRequest_cps_provider_2_elem_stores{+v_1: Nat}
  TemplateRequest_cps_provider_2_elem_decl{+v_1: Nat}
  TemplateRequest_cps_provider_2_run_part{+v_2: List<&2, cps_provider_2_Job>, +v_4: cps_provider_2_World, +v_6: String}
  TemplateRequest_cps_provider_2_array_new_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat}
  TemplateRequest_cps_provider_2_tuple_and_code{+v_1: cps_provider_2_Part, +v_3: cps_provider_2_Code}
  TemplateRequest_cps_provider_2_array_get_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat}
  TemplateRequest_cps_provider_2_old_read_cell{+v_1: Bool, +v_3: String}
  TemplateRequest_cps_provider_2_kinds_box_jobs{+v_2: List<&2, cps_provider_1_CWord>, +v_4: String, +v_6: Bool}
  TemplateRequest_cps_provider_2_old_sink_jobs{+v_2: List<&2, cps_provider_1_CWord>, +v_4: String}
  TemplateRequest_cps_provider_2_write_jobs{+v_1: Bool, +v_4: List<&2, cps_provider_1_CWord>, +v_6: String}
  TemplateRequest_cps_provider_2_array_set_run{+v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_5: cps_provider_2_Operand, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat}
  TemplateRequest_cps_provider_2_array_set_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat}
  TemplateRequest_cps_provider_2_array_swap_run{+v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_5: cps_provider_2_Operand, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat}
  TemplateRequest_cps_provider_2_array_swap_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat}
  TemplateRequest_cps_provider_2_array_size_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World, +v_6: Nat}
  TemplateRequest_cps_provider_2_array_clone_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_cell_text{+v_1: String, +v_3: String}
  TemplateRequest_cps_provider_2_atomic_call_text{+v_1: String, +v_3: String, +v_5: String, +v_7: String}
  TemplateRequest_cps_provider_2_atomic_cas_text{+v_1: String, +v_3: String, +v_5: String, +v_7: String}
  TemplateRequest_cps_provider_2_atomic_helper{+v_0: BIR.Primitive}
  TemplateRequest_cps_provider_2_atomic_pair{+v_1: String, +v_3: String, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_three_operands{+v_0: BIR.Primitive, +v_2: cps_provider_2_Operand, +v_4: cps_provider_2_Operand, +v_6: cps_provider_2_Operand, +v_8: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_three_pargs{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_cas_pargs{+v_2: List<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_pargs{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_three_regs{+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_cas_regs{+v_2: List<&2, String>, +v_4: cps_provider_2_World}
  TemplateRequest_cps_provider_2_atomic_prim_part{+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_leaf_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World, +v_6: cps_provider_1_Layout, +v_8: Bool, +v_10: Nat, +v_12: Nat}
  TemplateRequest_cps_provider_2_array_node_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>}
  TemplateRequest_cps_provider_2_array_is_cond{+v_1: Nat, +v_3: cps_provider_2_Operand}
  TemplateRequest_cps_provider_2_array_is_bools{+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: Nat, +v_9: cps_provider_2_Operand}
  TemplateRequest_cps_provider_2_array_is_ops{+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: Nat, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_new_cell{+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_get_cell{+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_set_cell{+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_swap_cell{+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_size_cell{+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_clone_cell{+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_leaf_cell{+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_part{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World}
  TemplateRequest_cps_provider_2_array_cell_part{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World}
  TemplateRequest_cps_provider_2_is_atomic_primitive{+v_0: BIR.Primitive}
  TemplateRequest_cps_provider_2_is_array_primitive{+v_0: BIR.Primitive}

type TemplateRequestGroup6 is Type:
  TemplateRequest_cps_provider_2_map_offsets{+v_1: Nat, +v_3: String, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_map_offsets_walk{+v_1: String, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, String>}
  TemplateRequest_cps_provider_2_map_find_missing{+v_1: String}
  TemplateRequest_cps_provider_2_map_find_text{+v_1: String, +v_3: String, +v_5: cps_provider_2_World}
  TemplateRequest_cps_provider_2_map_find_build{+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: U32, +v_11: U32, +v_13: cps_provider_2_World}
  TemplateRequest_cps_provider_2_map_find_expr{+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: String, +v_11: String, +v_13: String, +v_15: String}
  TemplateRequest_cps_provider_2_map_find_operands{+v_2: List<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World}
  TemplateRequest_cps_provider_2_map_find_names{+v_2: List<&2, String>, +v_4: cps_provider_2_World}
  TemplateRequest_cps_provider_2_map_find_part{+v_2: List<&2, cps_provider_2_Operand>, +v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_World}
  TemplateRequest_cps_provider_2_descriptor_part{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World}
  TemplateRequest_cps_provider_2_show_state0{}
  TemplateRequest_cps_provider_2_show_words{+v_1: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_patches{+v_1: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_memo{+v_1: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_names{+v_1: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_error{+v_1: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_state_set_memo{+v_1: cps_provider_2_ShowState, +v_4: Map<&2, Nat>}
  TemplateRequest_cps_provider_2_show_state_error{+v_1: cps_provider_2_ShowState, +v_3: String}
  TemplateRequest_cps_provider_2_show_next_state{+v_1: cps_provider_2_ShowAdvance}
  TemplateRequest_cps_provider_2_show_next_kids{+v_1: cps_provider_2_ShowAdvance}
  TemplateRequest_cps_provider_2_show_append_word{+v_1: cps_provider_2_ShowState, +v_3: cps_provider_2_ShowWord}
  TemplateRequest_cps_provider_2_show_append_num{+v_1: cps_provider_2_ShowState, +v_3: Nat}
  TemplateRequest_cps_provider_2_show_append_cid{+v_1: cps_provider_2_ShowState, +v_3: Nat}
  TemplateRequest_cps_provider_2_show_append_name{+v_1: cps_provider_2_ShowState, +v_3: String}
  TemplateRequest_cps_provider_2_show_append_patch{+v_1: cps_provider_2_ShowState, +v_3: Nat, +v_5: Nat}
  TemplateRequest_cps_provider_2_show_apply_patch{+v_1: cps_provider_2_ShowState, +v_4: Maybe<&2, Nat>, +v_6: Nat}
  TemplateRequest_cps_provider_2_show_native_kind{+v_1: String}
  TemplateRequest_cps_provider_2_show_kind_family{+v_1: String, +v_3: cps_provider_1_Context}
  TemplateRequest_cps_provider_2_show_kind_head{+v_1: cps_provider_1_HeadResult, +v_3: cps_provider_1_Context}
  TemplateRequest_cps_provider_2_show_kind{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_2_show_box_flag{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_show_tag_plain{+v_1: Nat}
  TemplateRequest_cps_provider_2_show_tag_start{+v_1: Nat, +v_3: Nat}
  TemplateRequest_cps_provider_2_show_quote{+v_1: String}
  TemplateRequest_cps_provider_2_show_name_sep{+v_2: List<&2, String>}
  TemplateRequest_cps_provider_2_show_render_names{+v_2: List<&2, String>}
  TemplateRequest_cps_provider_2_show_render_sep_flag{+v_1: Bool}
  TemplateRequest_cps_provider_2_show_render_sep{+v_1: String}
  TemplateRequest_cps_provider_2_show_render_word{+v_1: cps_provider_2_ShowWord}
  TemplateRequest_cps_provider_2_show_render_words{+v_2: List<&2, cps_provider_2_ShowWord>, +v_4: String}
  TemplateRequest_cps_provider_2_family_arms{+v_1: String, +v_3: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_2_ctor_find_key{+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>}
  TemplateRequest_cps_provider_2_show_cid_found{+v_1: Maybe<&2, BIR.ConstructorLayout>}
  TemplateRequest_cps_provider_2_show_cid_of_key{+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>}
  TemplateRequest_cps_provider_2_show_arm_bracket_name{+v_1: String}
  TemplateRequest_cps_provider_2_show_arm_bracket{+v_1: String}
  TemplateRequest_cps_provider_2_show_erased_present{+v_1: List<&2, BIR.DescriptorField>}
  TemplateRequest_cps_provider_2_show_field_at_each{+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat}
  TemplateRequest_cps_provider_2_show_field_at{+v_1: List<&2, BIR.DescriptorField>, +v_3: U32}
  TemplateRequest_cps_provider_2_show_arm_layouts_each{+v_2: List<&2, cps_provider_1_LayArm>, +v_4: String}
  TemplateRequest_cps_provider_2_show_arm_layouts{+v_1: cps_provider_1_Layout, +v_3: String}
  TemplateRequest_cps_provider_2_show_node_layout_slots{+v_1: cps_provider_1_NodeResult}
  TemplateRequest_cps_provider_2_show_word_key{+v_1: cps_provider_1_CWord}
  TemplateRequest_cps_provider_2_show_box_key{+v_1: cps_provider_1_BoxReason}
  TemplateRequest_cps_provider_2_lk_text{+v_1: String}
  TemplateRequest_cps_provider_2_lk_words{+v_2: List<&2, cps_provider_1_CWord>}
  TemplateRequest_cps_provider_2_lk_fields{+v_2: List<&2, cps_provider_1_Layout>}
  TemplateRequest_cps_provider_2_lk_arms{+v_2: List<&2, cps_provider_1_LayArm>}
  TemplateRequest_cps_provider_2_show_layout_key{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_show_arg_tokens{+v_1: List<&2, BIR.Descriptor>, +v_3: Bool}
  TemplateRequest_cps_provider_2_show_quantity_key{+v_0: BIR.Quantity}
  TemplateRequest_cps_provider_2_show_maybe_quantity_key{+v_1: Maybe<&2, BIR.Quantity>}
  TemplateRequest_cps_provider_2_show_pat_tokens{+v_1: List<&2, BIR.DescriptorPattern>, +v_3: Bool}
  TemplateRequest_cps_provider_2_show_pat_expand{+v_0: BIR.DescriptorPattern}

type TemplateRequestGroup7 is Type:
  TemplateRequest_cps_provider_2_show_desc_expand{+v_0: BIR.Descriptor}
  TemplateRequest_cps_provider_2_show_render_tokens{+v_2: List<&2, cps_provider_2_ShowToken>, +v_4: String}
  TemplateRequest_cps_provider_2_show_descriptor_key{+v_0: BIR.Descriptor}
  TemplateRequest_cps_provider_2_show_array_cell{+v_1: cps_provider_1_CellResult, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: Nat, +v_12: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_array_element{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_array_args{+v_1: cps_provider_1_ArgsResult, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: Nat, +v_12: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_array{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_box_advance{+v_1: cps_provider_2_ShowJob, +v_3: cps_provider_2_ShowAdvance}
  TemplateRequest_cps_provider_2_fields_box_each{+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_fields_box_slots{+v_3: Maybe<&2, List<&2, cps_provider_1_NodeSlot>>, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_fields_box{+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_fields_inline_each{+v_2: List<&2, cps_provider_1_Layout>, +v_4: List<&2, BIR.DescriptorField>, +v_6: Nat, +v_8: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_fields_inline_layouts{+v_3: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_5: List<&2, BIR.DescriptorField>, +v_7: Nat, +v_9: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_fields_inline{+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_1_Layout, +v_9: Nat, +v_11: Nat, +v_13: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_fields_advance{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_7: String, +v_9: List<&2, BIR.DescriptorField>, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_arm_header{+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_1_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_arm_rest{+v_1: cps_provider_2_ShowAdvance, +v_3: List<&2, BIR.DescriptorArm>, +v_5: cps_provider_1_Context, +v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, +v_11: cps_provider_3_NfVal, +v_13: cps_provider_1_Layout, +v_15: Nat, +v_17: Nat}
  TemplateRequest_cps_provider_2_show_data_arm_cid{+v_2: Maybe<&2, Nat>, +v_4: List<&2, BIR.DescriptorField>, +v_6: String, +v_8: List<&2, BIR.DescriptorArm>, +v_10: cps_provider_1_Context, +v_12: List<&2, BIR.ConstructorLayout>, +v_14: List<&2, BIR.Family>, +v_16: cps_provider_3_NfVal, +v_18: cps_provider_1_Layout, +v_20: Nat, +v_22: Nat, +v_24: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_arm_erased{+v_1: Bool, +v_3: List<&2, BIR.DescriptorField>, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_9: cps_provider_1_Context, +v_11: List<&2, BIR.ConstructorLayout>, +v_13: List<&2, BIR.Family>, +v_15: cps_provider_3_NfVal, +v_17: cps_provider_1_Layout, +v_19: Nat, +v_21: Nat, +v_23: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_arm_live{+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_1_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_arm{+v_1: cps_provider_1_FieldsResult, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_1_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_arms{+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_count{+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_arms_maybe{+v_2: Maybe<&2, List<&2, BIR.DescriptorArm>>, +v_4: cps_provider_1_Context, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>, +v_10: cps_provider_3_NfVal, +v_12: cps_provider_1_Layout, +v_14: Nat, +v_16: cps_provider_2_ShowState, +v_18: String}
  TemplateRequest_cps_provider_2_show_data_key{+v_1: String, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_data_head{+v_1: cps_provider_1_HeadResult, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_data{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_n{+v_1: Nat, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_1_Layout, +v_12: Nat, +v_14: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_kind{+v_1: cps_provider_2_ShowKind, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_1_Layout, +v_12: Nat, +v_14: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_memo{+v_2: Maybe<&2, Nat>, +v_4: String, +v_6: cps_provider_1_Context, +v_8: List<&2, BIR.ConstructorLayout>, +v_10: List<&2, BIR.Family>, +v_11: BIR.Descriptor, +v_13: cps_provider_1_Layout, +v_16: Maybe<&2, Nat>, +v_18: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_norm{+v_1: cps_provider_2_ShowNorm, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_1_Layout, +v_13: Maybe<&2, Nat>, +v_15: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_key{+v_2: Maybe<&2, String>, +v_4: cps_provider_1_Context, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>, +v_9: BIR.Descriptor, +v_11: cps_provider_1_Layout, +v_14: Maybe<&2, Nat>, +v_16: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_norm_result{+v_1: cps_provider_1_NormResult}
  TemplateRequest_cps_provider_2_show_norm{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_2_show_advance_error{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_11: Maybe<&2, Nat>, +v_14: Maybe<&2, String>, +v_16: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_st{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_11: Maybe<&2, Nat>, +v_13: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_advance_job{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_7: cps_provider_2_ShowJob, +v_9: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_run_show{+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_8: List<&2, cps_provider_2_ShowJob>, +v_10: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_set_word{+v_2: List<&2, cps_provider_2_ShowWord>, +v_4: Nat, +v_6: cps_provider_2_ShowWord, +v_8: Nat}
  TemplateRequest_cps_provider_2_show_apply_patches{+v_2: List<&2, cps_provider_2_ShowWord>, +v_5: List<&2, cps_provider_2_ShowPatch>}
  TemplateRequest_cps_provider_2_show_finish{+v_2: Maybe<&2, String>, +v_4: cps_provider_2_ShowState}
  TemplateRequest_cps_provider_2_show_result{+v_1: cps_provider_2_ShowRun}
  TemplateRequest_cps_provider_2_show_root_layout{+v_1: cps_provider_1_Layout}
  TemplateRequest_cps_provider_2_show_root{+v_1: cps_provider_1_LayoutResult, +v_3: cps_provider_1_Context, +v_4: BIR.Descriptor, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_2_show_build{+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_3_family_index{v_1: List<&2, BIR.Family>}
  TemplateRequest_cps_provider_3_function_index{v_1: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_3_nf_context{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_3_default_fuel{}
  TemplateRequest_cps_provider_3_family_of{+v_1: String, +v_3: Map<&2, BIR.Family>}
  TemplateRequest_cps_provider_3_function_of{+v_1: String, +v_3: Map<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_3_native_of{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_3_val_nth{+v_2: List<&2, cps_provider_3_NfVal>, v_4: Nat}
  TemplateRequest_cps_provider_3_val_at{+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_5: BIR.Descriptor}
  TemplateRequest_cps_provider_3_val_at_choose{v_1: Bool, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: Nat, v_7: BIR.Descriptor}
  TemplateRequest_cps_provider_3_first_vals{v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_3_drop_vals{v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_3_insert_before{v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_6: cps_provider_3_NfVal}
  TemplateRequest_cps_provider_3_append_vals{v_2: List<&2, cps_provider_3_NfVal>, v_5: List<&2, cps_provider_3_NfVal>}
  TemplateRequest_cps_provider_3_quantity_markers{v_1: Nat}
  TemplateRequest_cps_provider_3_renamed_level{v_2: List<&2, cps_provider_3_NfRenaming>, +v_4: Nat}
  TemplateRequest_cps_provider_3_materialize_all_scoped{v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_3_NfRenaming>}
  TemplateRequest_cps_provider_3_materialize_all_at{v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat}
  TemplateRequest_cps_provider_3_materialize_all{v_2: List<&2, cps_provider_3_NfVal>}

type TemplateRequestGroup8 is Type:
  TemplateRequest_cps_provider_3_materialize_scoped{v_1: cps_provider_3_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_3_NfRenaming>}
  TemplateRequest_cps_provider_3_materialize_at{v_1: cps_provider_3_NfVal, +v_3: Nat}
  TemplateRequest_cps_provider_3_materialize{v_1: cps_provider_3_NfVal}
  TemplateRequest_cps_provider_3_reify_env{v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_3_NfVal>, +v_5: Nat}
  TemplateRequest_cps_provider_3_status_combine{v_1: cps_provider_3_NfStatus, v_3: cps_provider_3_NfStatus}
  TemplateRequest_cps_provider_3_bind_status{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>}
  TemplateRequest_cps_provider_3_bind_values{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>}
  TemplateRequest_cps_provider_3_bind_patterns{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>}
  TemplateRequest_cps_provider_3_nf{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_3_nf_descriptor{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_3_nf_arrow{+v_1: cps_provider_3_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_3_nf_descriptor_step{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_3_nf_all{+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_3_nf_apply_args{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_3_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat}
  TemplateRequest_cps_provider_3_nf_apply_source{+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_6: List<&2, cps_provider_3_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_3_nf_apply{+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_3_nf_apply_one{+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_5: cps_provider_3_NfVal, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_3_intrinsic_io{+v_0: BIR.TypeFunction}
  TemplateRequest_cps_provider_3_nf_named_io{v_1: Bool, +v_3: cps_provider_3_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat}
  TemplateRequest_cps_provider_3_nf_named{+v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat}
  TemplateRequest_cps_provider_3_nf_arity{+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, +v_6: Nat}
  TemplateRequest_cps_provider_3_nf_family{v_0: BIR.Family, v_3: List<&2, cps_provider_3_NfVal>}
  TemplateRequest_cps_provider_3_nf_family_apply{v_1: cps_provider_3_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_3_NfVal>}
  TemplateRequest_cps_provider_3_nf_reduce{+v_1: cps_provider_3_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat}
  TemplateRequest_cps_provider_3_nf_reduce_apply{v_1: cps_provider_3_NfArity, +v_3: cps_provider_3_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_3_NfVal>, +v_15: Nat, +v_17: Nat}
  TemplateRequest_cps_provider_3_nf_reduce_body{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat, +v_12: Nat}
  TemplateRequest_cps_provider_3_nf_cases{+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat}
  TemplateRequest_cps_provider_3_normalize{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat}
  TemplateRequest_cps_provider_3_normalize_closed{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor}
  TemplateRequest_cps_provider_3_normalize_in{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_3_outer_application{+v_0: BIR.Descriptor}
  TemplateRequest_cps_provider_3_outer_walk{+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>}
  TemplateRequest_cps_provider_3_answer_in{+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_3_answer_descriptor{v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>}
  TemplateRequest_cps_provider_3_answer_normalized{+v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor}
  TemplateRequest_cps_provider_3_is_io_head_in{+v_1: cps_provider_3_NfContext, +v_3: String}
  TemplateRequest_cps_provider_3_is_io_head{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}

type TemplateRequest is Type:
  TemplateRequestGroup_0{request: TemplateRequestGroup0}
  TemplateRequestGroup_1{request: TemplateRequestGroup1}
  TemplateRequestGroup_2{request: TemplateRequestGroup2}
  TemplateRequestGroup_3{request: TemplateRequestGroup3}
  TemplateRequestGroup_4{request: TemplateRequestGroup4}
  TemplateRequestGroup_5{request: TemplateRequestGroup5}
  TemplateRequestGroup_6{request: TemplateRequestGroup6}
  TemplateRequestGroup_7{request: TemplateRequestGroup7}
  TemplateRequestGroup_8{request: TemplateRequestGroup8}

def template_result_group_0(request: TemplateRequestGroup0) -> Data:
  match request:
    case TemplateRequest_fld{_}: BIR.DescriptorField
    case TemplateRequest_arm{_, _}: BIR.DescriptorArm
    case TemplateRequest_fam{_, _, _, _}: BIR.Family
    case TemplateRequest_ref{_, _}: BIR.Descriptor
    case TemplateRequest_fam_u32{}: BIR.Family
    case TemplateRequest_fam_pt{}: BIR.Family
    case TemplateRequest_fam_fl{}: BIR.Family
    case TemplateRequest_fam_seg{}: BIR.Family
    case TemplateRequest_families{}: List<&2, BIR.Family>
    case TemplateRequest_constructors{}: List<&2, BIR.ConstructorLayout>
    case TemplateRequest_program{}: BIR.Program
    case TemplateRequest_chain_key{_}: String
    case TemplateRequest_next_key{_}: String
    case TemplateRequest_fam_chain{_}: List<&2, BIR.Family>
    case TemplateRequest_ctor_chain{_}: List<&2, BIR.ConstructorLayout>
    case TemplateRequest_deep_program{}: BIR.Program
    case TemplateRequest_summarize{_}: String
    case TemplateRequest_deep_text{_}: String
    case TemplateRequest_deep_summary{}: String
    case TemplateRequest_shadow_fams{}: List<&2, BIR.Family>
    case TemplateRequest_shadow_ctors{}: List<&2, BIR.ConstructorLayout>
    case TemplateRequest_shadow_program{}: BIR.Program
    case TemplateRequest_shadow_one{_, _}: String
    case TemplateRequest_shadow_summary{}: String
    case TemplateRequest_key_pair{_, _}: String
    case TemplateRequest_deep_key_probe{}: String
    case TemplateRequest_key_checks{}: String
    case TemplateRequest_multi_fams{}: List<&2, BIR.Family>
    case TemplateRequest_multi_ctors{}: List<&2, BIR.ConstructorLayout>
    case TemplateRequest_multi_program{}: BIR.Program
    case TemplateRequest_multi_text{_}: String
    case TemplateRequest_multi_summary{}: String
    case TemplateRequest_main{_}: PhysSmoke
    case TemplateRequest_unwrap{_, _}: PhysSmoke
    case TemplateRequest_cps_provider_1_context{_}: cps_provider_1_Context
    case TemplateRequest_cps_provider_1_context_nf{_}: cps_provider_3_NfContext
    case TemplateRequest_cps_provider_1_context_families{_}: List<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_context_plan{_}: cps_provider_1_Plan
    case TemplateRequest_cps_provider_1_context_nodes{_}: Map<&2, cps_provider_1_NodeResult>
    case TemplateRequest_cps_provider_1_context_arms{_}: Map<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_nf_families{_}: Map<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_nf_functions{_}: Map<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_1_family_lookup{_, _}: Maybe<&2, BIR.Family>
    case TemplateRequest_cps_provider_1_function_lookup{_, _}: Maybe<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_1_arm_of{_, _}: Maybe<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_arm_in{_, _}: Maybe<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_plan_arm_index{_}: Map<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_plan_family_arms{_, _}: Map<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_arm_declared{_, _}: Maybe<&2, BIR.DescriptorArm>
    case TemplateRequest_cps_provider_1_live_field{_}: Bool
    case TemplateRequest_cps_provider_1_layout_fuel{}: Nat
    case TemplateRequest_cps_provider_1_nf_of{_, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_1_value_layout{_, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_of_desc{_, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_of_val{_, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_val{_, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_unresolved{_, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_family{_, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_layout_native{_, _, _, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_field_scope{_}: List<&2, cps_provider_3_NfVal>
    case TemplateRequest_cps_provider_1_arm_layouts{_, _, _, _, _}: cps_provider_1_Plans
    case TemplateRequest_cps_provider_1_field_layouts{_, _, _, _, _}: cps_provider_1_Layouts
    case TemplateRequest_cps_provider_1_layout_data{_, _, _, _, _}: cps_provider_1_LayoutResult
    case TemplateRequest_cps_provider_1_arms_tagged{_}: Bool

def template_result_group_1(request: TemplateRequestGroup1) -> Data:
  match request:
    case TemplateRequest_cps_provider_1_reenters{_, _, _, _, _}: Bool
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

def template_result_group_2(request: TemplateRequestGroup2) -> Data:
  match request:
    case TemplateRequest_cps_provider_1_layout_has_term{_}: Bool
    case TemplateRequest_cps_provider_1_word_has_term{_}: Bool
    case TemplateRequest_cps_provider_1_any_word_has_term{_}: Bool
    case TemplateRequest_cps_provider_2_world{_, _, _}: cps_provider_2_World
    case TemplateRequest_cps_provider_2_join_text{_}: String
    case TemplateRequest_cps_provider_2_code_line{_}: cps_provider_2_Code
    case TemplateRequest_cps_provider_2_code_empty{}: cps_provider_2_Code
    case TemplateRequest_cps_provider_2_code_seq{_, _}: cps_provider_2_Code
    case TemplateRequest_cps_provider_2_code_text{_, _}: String
    case TemplateRequest_cps_provider_2_part_of{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_ctor_find{_, _}: Maybe<&2, BIR.ConstructorLayout>
    case TemplateRequest_cps_provider_2_ctor_of{_, _}: Maybe<&2, BIR.ConstructorLayout>
    case TemplateRequest_cps_provider_2_cid_find{_, _}: Maybe<&2, U32>
    case TemplateRequest_cps_provider_2_cid_of{_, _}: Maybe<&2, U32>
    case TemplateRequest_cps_provider_2_cid_text_of{_}: Maybe<&2, String>
    case TemplateRequest_cps_provider_2_cid_text{_, _}: Maybe<&2, String>
    case TemplateRequest_cps_provider_2_intrinsic_marker{_}: Bool
    case TemplateRequest_cps_provider_2_dst_write{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_dst_word{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_dst_decl{_, _, _}: String
    case TemplateRequest_cps_provider_2_dst_mark{_, _}: String
    case TemplateRequest_cps_provider_2_form_base{_, _}: Nat
    case TemplateRequest_cps_provider_2_form_pad{_, _}: Nat
    case TemplateRequest_cps_provider_2_src_skip_jobs{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_dst_skip_jobs{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_src_read_node{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_src_read_arr{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_src_read_block{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_src_read{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_form_tagged{_}: Bool
    case TemplateRequest_cps_provider_2_max_node_words{_, _}: Nat
    case TemplateRequest_cps_provider_2_max_term_decl{_, _}: String
    case TemplateRequest_cps_provider_2_arm_seed{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_arm_seed_words{_, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_arm_src{_, _, _, _, _}: cps_provider_2_Src
    case TemplateRequest_cps_provider_2_nests_jobs{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_arm_release{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_jobs_arm_body{_, _, _, _, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_jobs_arm{_, _, _, _, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_arm_jobs{_, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_unbox_cases{_, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_expand_unbox{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_expand_word_take{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_nest_take{_}: cps_provider_1_Unfill
    case TemplateRequest_cps_provider_2_nest_make{_}: cps_provider_1_Fill
    case TemplateRequest_cps_provider_2_field_pair_jobs{_, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_forms_arm_body{_, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_forms_arm_case{_, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_form_arm_by_key{_, _}: Maybe<&2, cps_provider_1_FormArm>
    case TemplateRequest_cps_provider_2_forms_cases{_, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_expand_forms{_, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_forms_single{_, _, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_pack_jobs{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_arm_block_jobs{_, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_box_arm_jobs{_, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_box_cases{_, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_box_untagged{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_expand_box{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_expand_box_body{_, _, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_expand_form_take{_, _, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_expand_conv{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_run_jobs{_, _, _}: cps_provider_2_Code
    case TemplateRequest_cps_provider_2_fill_plan_jobs{_, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_fill_result_jobs{_, _, _, _}: List<&2, cps_provider_2_Job>

def template_result_group_3(request: TemplateRequestGroup3) -> Data:
  match request:
    case TemplateRequest_cps_provider_2_fill_data_jobs{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_fill_jobs{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_unfill_result_jobs{_, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_unfill_data_jobs{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_unfill_word_jobs{_, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_unfill_jobs{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_operand_code{_, _, _, _}: cps_provider_2_Code
    case TemplateRequest_cps_provider_2_operand_name{_, _, _, _}: String
    case TemplateRequest_cps_provider_2_text_jobs{_}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_code_jobs{_}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_fill_slots_jobs{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_layout_is_data{_}: Bool
    case TemplateRequest_cps_provider_2_seal_box_many{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_seal_box{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_seal_kind{_, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_seal_kind_walk{_, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_seal_slots_jobs{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_one_job{_}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_construct_words{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_codeSeqPack{_, _, _, _, _}: cps_provider_2_Code
    case TemplateRequest_cps_provider_2_construct_packed_one{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_packed{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_packed_flag{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_count{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_node{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_layout{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_cid{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_generic{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_marker{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_native{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_row{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_construct_part{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_term_decl_text{_}: String
    case TemplateRequest_cps_provider_2_project_prelude{_, _, _, _}: String
    case TemplateRequest_cps_provider_2_project_words{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_packed_prelude{_, _}: String
    case TemplateRequest_cps_provider_2_project_packed{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_packed_flag{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_unique_expr{_}: String
    case TemplateRequest_cps_provider_2_static_expr{_}: String
    case TemplateRequest_cps_provider_2_and_expr{_, _}: String
    case TemplateRequest_cps_provider_2_or_expr{_, _}: String
    case TemplateRequest_cps_provider_2_nat_if{_, _, _}: Nat
    case TemplateRequest_cps_provider_2_live_ordinal{_, _}: Maybe<&2, U32>
    case TemplateRequest_cps_provider_2_live_walk{_, _, _, _}: Maybe<&2, U32>
    case TemplateRequest_cps_provider_2_live_next{_, _}: Nat
    case TemplateRequest_cps_provider_2_arm_fields_of{_, _}: Maybe<&2, List<&2, cps_provider_1_Layout>>
    case TemplateRequest_cps_provider_2_arm_fields_declared{_}: Maybe<&2, List<&2, BIR.DescriptorField>>
    case TemplateRequest_cps_provider_2_arm_descriptor_fields{_, _}: Maybe<&2, List<&2, BIR.DescriptorField>>
    case TemplateRequest_cps_provider_2_step_key{_, _}: Maybe<&2, String>
    case TemplateRequest_cps_provider_2_cell_lgs{_, _}: Maybe<&2, cps_provider_1_Cell>
    case TemplateRequest_cps_provider_2_not_bool{_}: Bool
    case TemplateRequest_cps_provider_2_live_ordinal_in{_, _, _, _}: Maybe<&2, U32>
    case TemplateRequest_cps_provider_2_inline_slot{_, _, _}: Maybe<&2, cps_provider_1_NodeSlot>
    case TemplateRequest_cps_provider_2_inline_start{_}: Nat
    case TemplateRequest_cps_provider_2_state_array{_, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_state_from_array_value{_, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_resolve_field{_, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_resolve_slot_field{_, _, _, _, _, _, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_resolve_cell_field{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_resolve_buf_field{_, _, _, _, _, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_resolve_node_slot{_, _, _, _, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_root_array_path{_, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_advance{_, _, _}: cps_provider_2_PathResult

def template_result_group_4(request: TemplateRequestGroup4) -> Data:
  match request:
    case TemplateRequest_cps_provider_2_array_from_state{_, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_half_state{_, _, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_leaf_state{_, _, _, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_resolve_path{_, _}: cps_provider_2_PathResult
    case TemplateRequest_cps_provider_2_path_prelude{_}: String
    case TemplateRequest_cps_provider_2_path_expr{_, _}: String
    case TemplateRequest_cps_provider_2_keep_copy{_, _, _, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_keep_copy_fields{_, _, _, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_keep_copy_cases{_, _, _, _, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_move_copy{_, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_move_copy_fields{_, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_move_copy_cases{_, _, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_raw_word_expr{_, _, _}: String
    case TemplateRequest_cps_provider_2_packed_form_body{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_read_body{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tag_single{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tag_multi{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tag_case_line{_, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_tag_multi_packed{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tag_multi_packed_go{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tag_multi_buf{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tag_multi_buf_go{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tag_body{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_copy_slot_body{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_packed_data_value{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_packed_data_copy{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_box_copy_body{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_data_copy_body{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_zero_value_body{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_buf_clear_words{_, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_buf_field_body{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_buf_move_clear{_, _, _, _}: String
    case TemplateRequest_cps_provider_2_cell_arr_body{_, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_cell_move_clear{_, _, _, _}: String
    case TemplateRequest_cps_provider_2_cell_data_body{_, _, _, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_buf_clear_span{_, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_copy_cell_body{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_copy_padding{_, _, _}: String
    case TemplateRequest_cps_provider_2_array_inner{_, _, _, _}: String
    case TemplateRequest_cps_provider_2_array_copy_body{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_pow2{_}: Nat
    case TemplateRequest_cps_provider_2_move_cell_body{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_move_slot_body{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_data_move_body{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_state_stat{_}: String
    case TemplateRequest_cps_provider_2_state_uniq{_}: String
    case TemplateRequest_cps_provider_2_path_body_copy{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_path_body_move{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_path_read{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_runtime_cid_of_ctor{_, _}: Maybe<&2, U32>
    case TemplateRequest_cps_provider_2_canonical_bool{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_path_hastag{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_path_copy{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_path_consume{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_path_is_leaf{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_path_is_node{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_plan{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_slot{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_layout{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_node{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_marker{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_native{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_row{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_project_part{_, _, _, _}: cps_provider_2_Part

def template_result_group_5(request: TemplateRequestGroup5) -> Data:
  match request:
    case TemplateRequest_cps_provider_2_hastag_bools{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_hastag_cid{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_hastag_row{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_hastag_part{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_arr_flag{_}: String
    case TemplateRequest_cps_provider_2_array_label{_}: String
    case TemplateRequest_cps_provider_2_descriptor_missing{_}: String
    case TemplateRequest_cps_provider_2_array_cell_result{_}: cps_provider_2_CellOut
    case TemplateRequest_cps_provider_2_array_cell{_, _, _}: cps_provider_2_CellOut
    case TemplateRequest_cps_provider_2_operand_at{_, _}: Maybe<&2, cps_provider_2_Operand>
    case TemplateRequest_cps_provider_2_operand_text{_}: String
    case TemplateRequest_cps_provider_2_operand_use{_}: BIR.Use
    case TemplateRequest_cps_provider_2_keep_text{_}: String
    case TemplateRequest_cps_provider_2_tuple_cid{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tuple_part{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_seal_cell_box{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_seal_cell_kind{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_seal_cell_walk{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_elem_fill_operand{_, _, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_elem_fill{_, _, _, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_elem_stores{_}: String
    case TemplateRequest_cps_provider_2_elem_decl{_}: String
    case TemplateRequest_cps_provider_2_run_part{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_new_ops{_, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_tuple_and_code{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_get_ops{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_old_read_cell{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_kinds_box_jobs{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_old_sink_jobs{_, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_write_jobs{_, _, _}: List<&2, cps_provider_2_Job>
    case TemplateRequest_cps_provider_2_array_set_run{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_set_ops{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_swap_run{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_swap_ops{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_size_ops{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_clone_ops{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_cell_text{_, _}: String
    case TemplateRequest_cps_provider_2_atomic_call_text{_, _, _, _}: String
    case TemplateRequest_cps_provider_2_atomic_cas_text{_, _, _, _}: String
    case TemplateRequest_cps_provider_2_atomic_helper{_}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_pair{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_three_operands{_, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_three_pargs{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_cas_pargs{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_pargs{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_three_regs{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_cas_regs{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_atomic_prim_part{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_leaf_ops{_, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_node_ops{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_is_cond{_, _}: String
    case TemplateRequest_cps_provider_2_array_is_bools{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_is_ops{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_new_cell{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_get_cell{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_set_cell{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_swap_cell{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_size_cell{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_clone_cell{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_leaf_cell{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_part{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_array_cell_part{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_is_atomic_primitive{_}: Bool
    case TemplateRequest_cps_provider_2_is_array_primitive{_}: Bool

def template_result_group_6(request: TemplateRequestGroup6) -> Data:
  match request:
    case TemplateRequest_cps_provider_2_map_offsets{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_map_offsets_walk{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_map_find_missing{_}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_map_find_text{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_map_find_build{_, _, _, _, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_map_find_expr{_, _, _, _, _, _, _, _}: String
    case TemplateRequest_cps_provider_2_map_find_operands{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_map_find_names{_, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_map_find_part{_, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_descriptor_part{_, _, _, _}: cps_provider_2_Part
    case TemplateRequest_cps_provider_2_show_state0{}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_words{_}: List<&2, cps_provider_2_ShowWord>
    case TemplateRequest_cps_provider_2_show_patches{_}: List<&2, cps_provider_2_ShowPatch>
    case TemplateRequest_cps_provider_2_show_memo{_}: Map<&2, Nat>
    case TemplateRequest_cps_provider_2_show_names{_}: List<&2, String>
    case TemplateRequest_cps_provider_2_show_error{_}: Maybe<&2, String>
    case TemplateRequest_cps_provider_2_show_state_set_memo{_, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_state_error{_, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_next_state{_}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_next_kids{_}: List<&2, cps_provider_2_ShowJob>
    case TemplateRequest_cps_provider_2_show_append_word{_, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_append_num{_, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_append_cid{_, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_append_name{_, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_append_patch{_, _, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_apply_patch{_, _, _}: cps_provider_2_ShowState
    case TemplateRequest_cps_provider_2_show_native_kind{_}: cps_provider_2_ShowKind
    case TemplateRequest_cps_provider_2_show_kind_family{_, _}: cps_provider_2_ShowKind
    case TemplateRequest_cps_provider_2_show_kind_head{_, _}: cps_provider_2_ShowKind
    case TemplateRequest_cps_provider_2_show_kind{_, _}: cps_provider_2_ShowKind
    case TemplateRequest_cps_provider_2_show_box_flag{_}: Nat
    case TemplateRequest_cps_provider_2_show_tag_plain{_}: Nat
    case TemplateRequest_cps_provider_2_show_tag_start{_, _}: Nat
    case TemplateRequest_cps_provider_2_show_quote{_}: String
    case TemplateRequest_cps_provider_2_show_name_sep{_}: String
    case TemplateRequest_cps_provider_2_show_render_names{_}: String
    case TemplateRequest_cps_provider_2_show_render_sep_flag{_}: String
    case TemplateRequest_cps_provider_2_show_render_sep{_}: String
    case TemplateRequest_cps_provider_2_show_render_word{_}: String
    case TemplateRequest_cps_provider_2_show_render_words{_, _}: String
    case TemplateRequest_cps_provider_2_family_arms{_, _}: Maybe<&2, List<&2, BIR.DescriptorArm>>
    case TemplateRequest_cps_provider_2_ctor_find_key{_, _}: Maybe<&2, BIR.ConstructorLayout>
    case TemplateRequest_cps_provider_2_show_cid_found{_}: Maybe<&2, Nat>
    case TemplateRequest_cps_provider_2_show_cid_of_key{_, _}: Maybe<&2, Nat>
    case TemplateRequest_cps_provider_2_show_arm_bracket_name{_}: Nat
    case TemplateRequest_cps_provider_2_show_arm_bracket{_}: Nat
    case TemplateRequest_cps_provider_2_show_erased_present{_}: Bool
    case TemplateRequest_cps_provider_2_show_field_at_each{_, _, _}: Maybe<&2, BIR.DescriptorField>
    case TemplateRequest_cps_provider_2_show_field_at{_, _}: Maybe<&2, BIR.DescriptorField>
    case TemplateRequest_cps_provider_2_show_arm_layouts_each{_, _}: Maybe<&2, List<&2, cps_provider_1_Layout>>
    case TemplateRequest_cps_provider_2_show_arm_layouts{_, _}: Maybe<&2, List<&2, cps_provider_1_Layout>>
    case TemplateRequest_cps_provider_2_show_node_layout_slots{_}: Maybe<&2, List<&2, cps_provider_1_NodeSlot>>
    case TemplateRequest_cps_provider_2_show_word_key{_}: String
    case TemplateRequest_cps_provider_2_show_box_key{_}: String
    case TemplateRequest_cps_provider_2_lk_text{_}: String
    case TemplateRequest_cps_provider_2_lk_words{_}: String
    case TemplateRequest_cps_provider_2_lk_fields{_}: String
    case TemplateRequest_cps_provider_2_lk_arms{_}: String
    case TemplateRequest_cps_provider_2_show_layout_key{_}: String
    case TemplateRequest_cps_provider_2_show_arg_tokens{_, _}: List<&2, cps_provider_2_ShowToken>
    case TemplateRequest_cps_provider_2_show_quantity_key{_}: String
    case TemplateRequest_cps_provider_2_show_maybe_quantity_key{_}: String
    case TemplateRequest_cps_provider_2_show_pat_tokens{_, _}: List<&2, cps_provider_2_ShowToken>
    case TemplateRequest_cps_provider_2_show_pat_expand{_}: List<&2, cps_provider_2_ShowToken>

def template_result_group_7(request: TemplateRequestGroup7) -> Data:
  match request:
    case TemplateRequest_cps_provider_2_show_desc_expand{_}: List<&2, cps_provider_2_ShowToken>
    case TemplateRequest_cps_provider_2_show_render_tokens{_, _}: Maybe<&2, String>
    case TemplateRequest_cps_provider_2_show_descriptor_key{_}: Maybe<&2, String>
    case TemplateRequest_cps_provider_2_show_array_cell{_, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_array_element{_, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_array_args{_, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_array{_, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_box_advance{_, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_fields_box_each{_, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_fields_box_slots{_, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_fields_box{_, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_fields_inline_each{_, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_fields_inline_layouts{_, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_fields_inline{_, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_fields_advance{_, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arm_header{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arm_rest{_, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arm_cid{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arm_erased{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arm_live{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arm{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arms{_, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_count{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_arms_maybe{_, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_key{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_data_head{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_data{_, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_n{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_kind{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_memo{_, _, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_norm{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_key{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_norm_result{_}: cps_provider_2_ShowNorm
    case TemplateRequest_cps_provider_2_show_norm{_, _}: cps_provider_2_ShowNorm
    case TemplateRequest_cps_provider_2_show_advance_error{_, _, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_st{_, _, _, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_show_advance_job{_, _, _, _, _}: cps_provider_2_ShowAdvance
    case TemplateRequest_cps_provider_2_run_show{_, _, _, _, _}: cps_provider_2_ShowRun
    case TemplateRequest_cps_provider_2_show_set_word{_, _, _, _}: List<&2, cps_provider_2_ShowWord>
    case TemplateRequest_cps_provider_2_show_apply_patches{_, _}: List<&2, cps_provider_2_ShowWord>
    case TemplateRequest_cps_provider_2_show_finish{_, _}: cps_provider_2_ShowOut
    case TemplateRequest_cps_provider_2_show_result{_}: cps_provider_2_ShowOut
    case TemplateRequest_cps_provider_2_show_root_layout{_}: cps_provider_1_Layout
    case TemplateRequest_cps_provider_2_show_root{_, _, _, _, _}: cps_provider_2_ShowOut
    case TemplateRequest_cps_provider_2_show_build{_, _, _, _}: cps_provider_2_ShowOut
    case TemplateRequest_cps_provider_3_family_index{_}: Map<&2, BIR.Family>
    case TemplateRequest_cps_provider_3_function_index{_}: Map<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_3_nf_context{_, _}: cps_provider_3_NfContext
    case TemplateRequest_cps_provider_3_default_fuel{}: Nat
    case TemplateRequest_cps_provider_3_family_of{_, _}: Maybe<&2, BIR.Family>
    case TemplateRequest_cps_provider_3_function_of{_, _}: Maybe<&2, BIR.TypeFunction>
    case TemplateRequest_cps_provider_3_native_of{_, _, _}: Maybe<&2, String>
    case TemplateRequest_cps_provider_3_val_nth{_, _}: cps_provider_3_NfVal
    case TemplateRequest_cps_provider_3_val_at{_, _, _}: cps_provider_3_NfVal
    case TemplateRequest_cps_provider_3_val_at_choose{_, _, _, _}: cps_provider_3_NfVal
    case TemplateRequest_cps_provider_3_first_vals{_, _}: List<&2, cps_provider_3_NfVal>
    case TemplateRequest_cps_provider_3_drop_vals{_, _}: List<&2, cps_provider_3_NfVal>
    case TemplateRequest_cps_provider_3_insert_before{_, _, _}: List<&2, cps_provider_3_NfVal>
    case TemplateRequest_cps_provider_3_append_vals{_, _}: List<&2, cps_provider_3_NfVal>
    case TemplateRequest_cps_provider_3_quantity_markers{_}: List<&2, cps_provider_3_NfVal>
    case TemplateRequest_cps_provider_3_renamed_level{_, _}: Nat
    case TemplateRequest_cps_provider_3_materialize_all_scoped{_, _, _}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_3_materialize_all_at{_, _}: List<&2, BIR.Descriptor>
    case TemplateRequest_cps_provider_3_materialize_all{_}: List<&2, BIR.Descriptor>

def template_result_group_8(request: TemplateRequestGroup8) -> Data:
  match request:
    case TemplateRequest_cps_provider_3_materialize_scoped{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_materialize_at{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_materialize{_}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_reify_env{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_status_combine{_, _}: cps_provider_3_NfStatus
    case TemplateRequest_cps_provider_3_bind_status{_, _}: cps_provider_3_NfStatus
    case TemplateRequest_cps_provider_3_bind_values{_, _}: List<&2, cps_provider_3_NfVal>
    case TemplateRequest_cps_provider_3_bind_patterns{_, _}: cps_provider_3_NfBind
    case TemplateRequest_cps_provider_3_nf{_, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_descriptor{_, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_arrow{_, _, _, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_descriptor_step{_, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_all{_, _, _, _, _}: cps_provider_3_NfList
    case TemplateRequest_cps_provider_3_nf_apply_args{_, _, _, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_apply_source{_, _, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_apply{_, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_apply_one{_, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_intrinsic_io{_}: Bool
    case TemplateRequest_cps_provider_3_nf_named_io{_, _, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_named{_, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_arity{_, _, _}: cps_provider_3_NfArity
    case TemplateRequest_cps_provider_3_nf_family{_, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_family_apply{_, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_reduce{_, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_reduce_apply{_, _, _, _, _, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_reduce_body{_, _, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_nf_cases{_, _, _, _, _, _, _}: cps_provider_3_Nf
    case TemplateRequest_cps_provider_3_normalize{_, _, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_normalize_closed{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_normalize_in{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_outer_application{_}: Maybe<&2, cps_provider_3_NfApp>
    case TemplateRequest_cps_provider_3_outer_walk{_, _}: Maybe<&2, cps_provider_3_NfApp>
    case TemplateRequest_cps_provider_3_answer_in{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_answer_descriptor{_, _, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_answer_normalized{_, _}: BIR.Descriptor
    case TemplateRequest_cps_provider_3_is_io_head_in{_, _}: Bool
    case TemplateRequest_cps_provider_3_is_io_head{_, _, _}: Bool

def template_result(request: TemplateRequest) -> Data:
  match request:
    case TemplateRequestGroup_0{inner}: template_result_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_result_group_1(inner)
    case TemplateRequestGroup_2{inner}: template_result_group_2(inner)
    case TemplateRequestGroup_3{inner}: template_result_group_3(inner)
    case TemplateRequestGroup_4{inner}: template_result_group_4(inner)
    case TemplateRequestGroup_5{inner}: template_result_group_5(inner)
    case TemplateRequestGroup_6{inner}: template_result_group_6(inner)
    case TemplateRequestGroup_7{inner}: template_result_group_7(inner)
    case TemplateRequestGroup_8{inner}: template_result_group_8(inner)

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

def template_pure_cps_provider_1_context_nf(+v_1: cps_provider_1_Context) -> cps_provider_3_NfContext:
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

def template_pure_cps_provider_1_nf_families(+v_1: cps_provider_3_NfContext) -> Map<&2, BIR.Family>:
  match v_1:
    case cps_provider_3_NfContext{+v_5, +v_6}:
      v_5

def template_pure_cps_provider_1_nf_functions(+v_1: cps_provider_3_NfContext) -> Map<&2, BIR.TypeFunction>:
  match v_1:
    case cps_provider_3_NfContext{+v_5, +v_6}:
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

def template_match_8(+v_3: cps_provider_1_CWord, +v_1: cps_provider_1_CWord) -> cps_provider_1_CWord:
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
      template_match_8(v_3, v_1)

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

def template_pure_cps_provider_2_intrinsic_marker(+v_1: String) -> Bool:
  match v_1:
    case "Nat.Zero":
      True{}
    case "Nat.Succ":
      True{}
    case "U32.U32":
      True{}
    case "F32.F32":
      True{}
    case "Char.Chr":
      True{}
    case "Bool.True":
      True{}
    case "Bool.False":
      True{}
    case "String.SNil":
      True{}
    case "String.SCon":
      True{}
    case "Array.ALeaf":
      True{}
    case "Array.ANode":
      True{}
    case _:
      False{}

def template_pure_cps_provider_2_form_tagged(+v_2: List<&2, cps_provider_1_FormArm>) -> Bool:
  match v_2:
    case []:
      False{}
    case [+v_5]:
      False{}
    case _:
      True{}

def template_pure_cps_provider_2_nest_take(+v_1: cps_provider_1_Nest) -> cps_provider_1_Unfill:
  match v_1:
    case cps_provider_1_Nest{v_7, v_8, v_9, v_10}:
      v_9

def template_pure_cps_provider_2_nest_make(+v_1: cps_provider_1_Nest) -> cps_provider_1_Fill:
  match v_1:
    case cps_provider_1_Nest{v_7, v_8, v_9, v_10}:
      v_10

def template_pure_cps_provider_2_layout_is_data(+v_1: cps_provider_1_Layout) -> Bool:
  match v_1:
    case cps_provider_1_LayoutData{v_5, v_6}:
      True{}
    case _:
      False{}

def template_pure_cps_provider_2_nat_if(+v_1: Bool, +v_3: Nat, +v_5: Nat) -> Nat:
  match v_1:
    case True{}:
      v_3
    case False{}:
      v_5

def template_pure_cps_provider_2_not_bool(+v_1: Bool) -> Bool:
  match v_1:
    case True{}:
      False{}
    case False{}:
      True{}

def template_pure_cps_provider_2_state_stat(+v_1: cps_provider_2_PathState) -> String:
  match v_1:
    case cps_provider_2_StSlot{v_9, v_10, v_11, v_12, v_13, v_14}:
      v_13
    case cps_provider_2_StArray{v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32}:
      v_32
    case cps_provider_2_StCell{v_42, v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50}:
      v_50
    case cps_provider_2_StBufField{v_56, v_57, v_58, v_59, v_60}:
      v_60

def template_pure_cps_provider_2_state_uniq(+v_1: cps_provider_2_PathState) -> String:
  match v_1:
    case cps_provider_2_StSlot{v_9, v_10, v_11, v_12, v_13, v_14}:
      v_12
    case cps_provider_2_StArray{v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32}:
      v_31
    case cps_provider_2_StCell{v_42, v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50}:
      v_49
    case cps_provider_2_StBufField{v_56, v_57, v_58, v_59, v_60}:
      v_59

def template_pure_cps_provider_2_operand_text(+v_1: cps_provider_2_Operand) -> String:
  match v_1:
    case cps_provider_2_Operand{v_5, v_6}:
      v_6

def template_pure_cps_provider_2_operand_use(+v_1: cps_provider_2_Operand) -> BIR.Use:
  match v_1:
    case cps_provider_2_Operand{v_4, v_5}:
      v_4

def template_pure_cps_provider_2_is_atomic_primitive(+v_0: BIR.Primitive) -> Bool:
  match v_0:
    case BIR.PrimArrayAtomicAdd{}:
      True{}
    case BIR.PrimArrayAtomicMin{}:
      True{}
    case BIR.PrimArrayAtomicMax{}:
      True{}
    case BIR.PrimArrayAtomicAnd{}:
      True{}
    case BIR.PrimArrayAtomicOr{}:
      True{}
    case BIR.PrimArrayAtomicXor{}:
      True{}
    case BIR.PrimArrayAtomicExch{}:
      True{}
    case BIR.PrimArrayAtomicCas{}:
      True{}
    case BIR.PrimArrayAtomicFadd{}:
      True{}
    case _:
      False{}

def template_pure_cps_provider_2_is_array_primitive(+v_0: BIR.Primitive) -> Bool:
  match v_0:
    case BIR.PrimArrayNew{}:
      True{}
    case BIR.PrimArrayGet{}:
      True{}
    case BIR.PrimArraySet{}:
      True{}
    case BIR.PrimArraySwap{}:
      True{}
    case BIR.PrimArraySize{}:
      True{}
    case BIR.PrimArrayClone{}:
      True{}
    case BIR.PrimArrayLeaf{}:
      True{}
    case BIR.PrimArrayNode{}:
      True{}
    case BIR.PrimIsArrayLeaf{}:
      True{}
    case BIR.PrimIsArrayNode{}:
      True{}
    case _:
      False{}

def template_pure_cps_provider_2_show_words(+v_1: cps_provider_2_ShowState) -> List<&2, cps_provider_2_ShowWord>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_9

def template_pure_cps_provider_2_show_patches(+v_1: cps_provider_2_ShowState) -> List<&2, cps_provider_2_ShowPatch>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_10

def template_pure_cps_provider_2_show_memo(+v_1: cps_provider_2_ShowState) -> Map<&2, Nat>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_11

def template_pure_cps_provider_2_show_names(+v_1: cps_provider_2_ShowState) -> List<&2, String>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_12

def template_pure_cps_provider_2_show_error(+v_1: cps_provider_2_ShowState) -> Maybe<&2, String>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_13

def template_pure_cps_provider_2_show_next_state(+v_1: cps_provider_2_ShowAdvance) -> cps_provider_2_ShowState:
  match v_1:
    case cps_provider_2_ShowNext{v_5, v_6}:
      v_5

def template_pure_cps_provider_2_show_next_kids(+v_1: cps_provider_2_ShowAdvance) -> List<&2, cps_provider_2_ShowJob>:
  match v_1:
    case cps_provider_2_ShowNext{v_6, v_7}:
      v_7

def template_match_32(v_3: cps_provider_3_NfStatus) -> cps_provider_3_NfStatus:
  match v_3:
    case cps_provider_3_NfStatusNo{}:
      cps_provider_3_NfStatusNo{}
    case _:
      cps_provider_3_NfStatusMaybe{}

def template_pure_cps_provider_3_status_combine(v_1: cps_provider_3_NfStatus, v_3: cps_provider_3_NfStatus) -> cps_provider_3_NfStatus:
  match v_1:
    case cps_provider_3_NfStatusNo{}:
      cps_provider_3_NfStatusNo{}
    case cps_provider_3_NfStatusMaybe{}:
      template_match_32(v_3)
    case cps_provider_3_NfStatusOk{}:
      v_3

def template_match_34(v_8: Maybe<&2, String>) -> Bool:
  match v_8:
    case Some{"IO"}:
      True{}
    case _:
      False{}

def template_pure_cps_provider_3_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      template_match_34(v_8)

def template_body_fld(+v_0: BIR.Descriptor) -> TemplateProgress<BIR.DescriptorField>:
  TemplateFinished{TemplateValue{BIR.DescriptorField{None{}, BIR.Unrestricted{}, v_0}}}

def template_body_arm(+v_1: String, +v_3: List<&2, BIR.DescriptorField>) -> TemplateProgress<BIR.DescriptorArm>:
  TemplateFinished{TemplateValue{BIR.DescriptorArm{v_1, v_3}}}

def template_body_fam(+v_1: String, +v_4: Maybe<&2, String>, +v_6: Nat, +v_8: List<&2, BIR.DescriptorArm>) -> TemplateProgress<BIR.Family>:
  TemplateFinished{TemplateValue{BIR.Family{v_1, v_1, v_4, 0n, v_6, v_8}}}

def template_body_ref(+v_1: String, +v_3: List<&2, BIR.Descriptor>) -> TemplateProgress<BIR.Descriptor>:
  TemplateFinished{TemplateValue{BIR.DescriptorRef{v_1, v_3}}}

def template_body_fam_u32() -> TemplateProgress<BIR.Family>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"U32", Some{"U32"}, 0n, []}}, False{}, v_1000002 => template_body_fam("U32", Some{"U32"}, 0n, []), v_1000001 => +v_1000000 = template_unbox(BIR.Family, v_1000001); TemplateFinished{TemplateValue{v_1000000}}}

def template_body_fam_pt() -> TemplateProgress<BIR.Family>:
  +v_1000003 = {"Pt" : String}
  +v_1000004 = {None{} : Maybe<&2, String>}
  +v_1000005 = {0n : Nat}
  +v_1000006 = {"Pt" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000024 => template_body_ref("U32", []), v_1000023 => +v_1000007 = template_unbox(BIR.Descriptor, v_1000023); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000007}}, False{}, v_1000022 => template_body_fld(v_1000007), v_1000021 => +v_1000008 = template_unbox(BIR.DescriptorField, v_1000021); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000020 => template_body_ref("U32", []), v_1000019 => +v_1000009 = template_unbox(BIR.Descriptor, v_1000019); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000009}}, False{}, v_1000018 => template_body_fld(v_1000009), v_1000017 => +v_1000010 = template_unbox(BIR.DescriptorField, v_1000017); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000006, [v_1000008, v_1000010]}}, False{}, v_1000016 => template_body_arm(v_1000006, [v_1000008, v_1000010]), v_1000015 => +v_1000011 = template_unbox(BIR.DescriptorArm, v_1000015); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000003, v_1000004, v_1000005, [v_1000011]}}, False{}, v_1000014 => template_body_fam(v_1000003, v_1000004, v_1000005, [v_1000011]), v_1000013 => +v_1000012 = template_unbox(BIR.Family, v_1000013); TemplateFinished{TemplateValue{v_1000012}}}}}}}}

def template_body_fam_fl() -> TemplateProgress<BIR.Family>:
  +v_1000025 = {"Fl" : String}
  +v_1000026 = {None{} : Maybe<&2, String>}
  +v_1000027 = {0n : Nat}
  +v_1000028 = {"Fl" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000040 => template_body_ref("U32", []), v_1000039 => +v_1000029 = template_unbox(BIR.Descriptor, v_1000039); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000029}}, False{}, v_1000038 => template_body_fld(v_1000029), v_1000037 => +v_1000030 = template_unbox(BIR.DescriptorField, v_1000037); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000028, [v_1000030]}}, False{}, v_1000036 => template_body_arm(v_1000028, [v_1000030]), v_1000035 => +v_1000031 = template_unbox(BIR.DescriptorArm, v_1000035); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000025, v_1000026, v_1000027, [v_1000031]}}, False{}, v_1000034 => template_body_fam(v_1000025, v_1000026, v_1000027, [v_1000031]), v_1000033 => +v_1000032 = template_unbox(BIR.Family, v_1000033); TemplateFinished{TemplateValue{v_1000032}}}}}}

def template_body_fam_seg() -> TemplateProgress<BIR.Family>:
  +v_1000041 = {"Seg" : String}
  +v_1000042 = {None{} : Maybe<&2, String>}
  +v_1000043 = {0n : Nat}
  +v_1000044 = {"Seg" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Pt", []}}, False{}, v_1000068 => template_body_ref("Pt", []), v_1000067 => +v_1000045 = template_unbox(BIR.Descriptor, v_1000067); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000045}}, False{}, v_1000066 => template_body_fld(v_1000045), v_1000065 => +v_1000046 = template_unbox(BIR.DescriptorField, v_1000065); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Pt", []}}, False{}, v_1000064 => template_body_ref("Pt", []), v_1000063 => +v_1000047 = template_unbox(BIR.Descriptor, v_1000063); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000047}}, False{}, v_1000062 => template_body_fld(v_1000047), v_1000061 => +v_1000048 = template_unbox(BIR.DescriptorField, v_1000061); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Fl", []}}, False{}, v_1000060 => template_body_ref("Fl", []), v_1000059 => +v_1000049 = template_unbox(BIR.Descriptor, v_1000059); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000049}}, False{}, v_1000058 => template_body_fld(v_1000049), v_1000057 => +v_1000050 = template_unbox(BIR.DescriptorField, v_1000057); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000044, [v_1000046, v_1000048, v_1000050]}}, False{}, v_1000056 => template_body_arm(v_1000044, [v_1000046, v_1000048, v_1000050]), v_1000055 => +v_1000051 = template_unbox(BIR.DescriptorArm, v_1000055); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000041, v_1000042, v_1000043, [v_1000051]}}, False{}, v_1000054 => template_body_fam(v_1000041, v_1000042, v_1000043, [v_1000051]), v_1000053 => +v_1000052 = template_unbox(BIR.Family, v_1000053); TemplateFinished{TemplateValue{v_1000052}}}}}}}}}}

def template_body_families() -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_u32{}}, False{}, v_1000080 => template_body_fam_u32, v_1000079 => +v_1000069 = template_unbox(BIR.Family, v_1000079); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_pt{}}, False{}, v_1000078 => template_body_fam_pt, v_1000077 => +v_1000070 = template_unbox(BIR.Family, v_1000077); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_fl{}}, False{}, v_1000076 => template_body_fam_fl, v_1000075 => +v_1000071 = template_unbox(BIR.Family, v_1000075); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_seg{}}, False{}, v_1000074 => template_body_fam_seg, v_1000073 => +v_1000072 = template_unbox(BIR.Family, v_1000073); TemplateFinished{TemplateValue{[v_1000069, v_1000070, v_1000071, v_1000072]}}}}}}

def template_body_constructors() -> TemplateProgress<List<&2, BIR.ConstructorLayout>>:
  TemplateFinished{TemplateValue{[BIR.ConstructorLayout{16, "Seg", None{}, []}, BIR.ConstructorLayout{17, "Pt", None{}, []}, BIR.ConstructorLayout{18, "Fl", None{}, []}]}}

def template_body_program() -> TemplateProgress<BIR.Program>:
  v_1000081 = {[] : List<&2, BIR.Code>}
  v_1000082 = {[] : List<&2, BIR.Declaration>}
  v_1000083 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_families{}}, False{}, v_1000086 => template_body_families, v_1000085 => +v_1000084 = template_unbox(List<&2, BIR.Family>, v_1000085); TemplateFinished{TemplateValue{BIR.Program{v_1000081, v_1000082, v_1000083, v_1000084, [], BIR.Library{[]}}}}}

def template_body_chain_key(+v_1: Nat) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{String.append("F", Nat.show(v_1))}}

def template_body_next_key(+v_1: Nat) -> TemplateProgress<String>:
  match v_1:
    case 0n:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{0n}}, False{}, v_1000089 => template_body_chain_key(0n), v_1000088 => +v_1000087 = template_unbox(String, v_1000088); TemplateFinished{TemplateValue{v_1000087}}}
    case 1n+v_5:
      template_body_chain_key(v_5)

def template_continuation_37(+v_1000091: String, +v_1000092: String, v_1000093: Maybe<&2, String>, v_1000094: Nat, v_1000095: Nat, +v_1000096: String) -> TemplateProgress<List<&2, BIR.Family>>:
  v_1000097 = {None{} : Maybe<&2, String>}
  v_1000098 = {BIR.Unrestricted{} : BIR.Quantity}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000101 => template_body_ref("U32", []), v_1000100 => +v_1000099 = template_unbox(BIR.Descriptor, v_1000100); TemplateFinished{TemplateValue{[BIR.Family{v_1000091, v_1000092, v_1000093, v_1000094, v_1000095, [BIR.DescriptorArm{v_1000096, [BIR.DescriptorField{v_1000097, v_1000098, v_1000099}]}]}, BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, []}]}}}

def template_continuation_38(+v_1000091: String, +v_1000092: String) -> TemplateProgress<List<&2, BIR.Family>>:
  v_1000093 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{0n}}, False{}, v_1000103 => template_body_chain_key(0n), v_1000102 => +v_1000096 = template_unbox(String, v_1000102); template_continuation_37(v_1000091, v_1000092, v_1000093, {0n : Nat}, {0n : Nat}, v_1000096)}

def template_continuation_39(+v_8: Nat, +v_1000108: String, +v_1000109: String, v_1000110: Maybe<&2, String>, v_1000111: Nat, v_1000112: Nat, +v_1000113: String) -> TemplateProgress<List<&2, BIR.Family>>:
  v_1000114 = {None{} : Maybe<&2, String>}
  v_1000115 = {BIR.Unrestricted{} : BIR.Quantity}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_next_key{v_8}}, False{}, v_1000123 => template_body_next_key(v_8), v_1000122 => +v_1000116 = template_unbox(String, v_1000122); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1000116, []}}, False{}, v_1000121 => template_body_ref(v_1000116, []), v_1000120 => +v_1000117 = template_unbox(BIR.Descriptor, v_1000120); TemplatePending{TemplateRequestGroup_0{TemplateRequest_fam_chain{v_8}}, v_1000119 => +v_1000118 = template_unbox(List<&2, BIR.Family>, v_1000119); TemplateFinished{TemplateValue{BIR.Family{v_1000108, v_1000109, v_1000110, v_1000111, v_1000112, [BIR.DescriptorArm{v_1000113, [BIR.DescriptorField{v_1000114, v_1000115, v_1000117}]}]} <> v_1000118}}}}}

def template_continuation_40(+v_8: Nat, +v_1000108: String, +v_1000109: String) -> TemplateProgress<List<&2, BIR.Family>>:
  v_1000110 = {None{} : Maybe<&2, String>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{v_8}}, False{}, v_1000125 => template_body_chain_key(v_8), v_1000124 => +v_1000113 = template_unbox(String, v_1000124); template_continuation_39(v_8, v_1000108, v_1000109, v_1000110, {0n : Nat}, {0n : Nat}, v_1000113)}

def template_body_fam_chain(+v_1: Nat) -> TemplateProgress<List<&2, BIR.Family>>:
  match v_1:
    case 0n:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{0n}}, False{}, v_1000107 => template_body_chain_key(0n), v_1000106 => +v_1000091 = template_unbox(String, v_1000106); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{0n}}, False{}, v_1000105 => template_body_chain_key(0n), v_1000104 => +v_1000092 = template_unbox(String, v_1000104); template_continuation_38(v_1000091, v_1000092)}}
    case 1n+ +v_8:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{v_8}}, False{}, v_1000129 => template_body_chain_key(v_8), v_1000128 => +v_1000108 = template_unbox(String, v_1000128); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{v_8}}, False{}, v_1000127 => template_body_chain_key(v_8), v_1000126 => +v_1000109 = template_unbox(String, v_1000126); template_continuation_40(v_8, v_1000108, v_1000109)}}

def template_body_ctor_chain(+v_1: Nat) -> TemplateProgress<List<&2, BIR.ConstructorLayout>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case 1n+ +v_4:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_chain_key{v_4}}, False{}, v_1000135 => template_body_chain_key(v_4), v_1000134 => +v_1000131 = template_unbox(String, v_1000134); TemplatePending{TemplateRequestGroup_0{TemplateRequest_ctor_chain{v_4}}, v_1000133 => +v_1000132 = template_unbox(List<&2, BIR.ConstructorLayout>, v_1000133); TemplateFinished{TemplateValue{BIR.ConstructorLayout{{0 : U32}, v_1000131, None{}, []} <> v_1000132}}}}

def template_body_deep_program() -> TemplateProgress<BIR.Program>:
  v_1000136 = {[] : List<&2, BIR.Code>}
  v_1000137 = {[] : List<&2, BIR.Declaration>}
  v_1000138 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_chain{400n}}, False{}, v_1000141 => template_body_fam_chain(400n), v_1000140 => +v_1000139 = template_unbox(List<&2, BIR.Family>, v_1000140); TemplateFinished{TemplateValue{BIR.Program{v_1000136, v_1000137, v_1000138, v_1000139, [], BIR.Library{[]}}}}}

def template_body_summarize(+v_1: cps_provider_2_ShowOut) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_2_ShowOk{v_5, v_6}:
      TemplateFinished{TemplateValue{String.append(Nat.show(List.length(&2, String, String.split(v_5, ','))), String.append("/", Nat.show(List.length(&2, String, String.split(v_6, ',')))))}}
    case cps_provider_2_ShowFail{v_10}:
      TemplateFinished{TemplateValue{v_10}}

def template_body_deep_text(+v_1: cps_provider_2_ShowOut) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_2_ShowOk{v_5, v_6}:
      TemplateFinished{TemplateValue{String.append(String.append("D", v_5), String.append("|N", v_6))}}
    case cps_provider_2_ShowFail{v_8}:
      TemplateFinished{TemplateValue{String.append("D!", v_8)}}

def template_body_deep_summary() -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_deep_program{}}, False{}, v_1000158 => template_body_deep_program, v_1000157 => +v_1000142 = template_unbox(BIR.Program, v_1000157); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_context{v_1000142}}, v_1000156 => +v_1000143 = template_unbox(cps_provider_1_Context, v_1000156); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"F399", []}}, False{}, v_1000155 => template_body_ref("F399", []), v_1000154 => +v_1000144 = template_unbox(BIR.Descriptor, v_1000154); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ctor_chain{400n}}, False{}, v_1000153 => template_body_ctor_chain(400n), v_1000152 => +v_1000145 = template_unbox(List<&2, BIR.ConstructorLayout>, v_1000152); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam_chain{400n}}, False{}, v_1000151 => template_body_fam_chain(400n), v_1000150 => +v_1000146 = template_unbox(List<&2, BIR.Family>, v_1000150); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_build{v_1000143, v_1000144, v_1000145, v_1000146}}, v_1000149 => +v_1000147 = template_unbox(cps_provider_2_ShowOut, v_1000149); template_body_deep_text(v_1000147)}}}}}}

def template_continuation_45(+v_1000159: BIR.Family, +v_1000167: BIR.Family, +v_1000175: BIR.Family, +v_1000183: BIR.Family) -> TemplateProgress<List<&2, BIR.Family>>:
  +v_1000184 = {"IO.OP" : String}
  +v_1000185 = {None{} : Maybe<&2, String>}
  +v_1000186 = {0n : Nat}
  +v_1000187 = {"IO.OP" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000199 => template_body_ref("U32", []), v_1000198 => +v_1000188 = template_unbox(BIR.Descriptor, v_1000198); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000188}}, False{}, v_1000197 => template_body_fld(v_1000188), v_1000196 => +v_1000189 = template_unbox(BIR.DescriptorField, v_1000196); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000187, [v_1000189]}}, False{}, v_1000195 => template_body_arm(v_1000187, [v_1000189]), v_1000194 => +v_1000190 = template_unbox(BIR.DescriptorArm, v_1000194); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000184, v_1000185, v_1000186, [v_1000190]}}, False{}, v_1000193 => template_body_fam(v_1000184, v_1000185, v_1000186, [v_1000190]), v_1000192 => +v_1000191 = template_unbox(BIR.Family, v_1000192); TemplateFinished{TemplateValue{[v_1000159, v_1000167, v_1000175, v_1000183, v_1000191]}}}}}}

def template_continuation_46(+v_1000159: BIR.Family, +v_1000167: BIR.Family, +v_1000175: BIR.Family) -> TemplateProgress<List<&2, BIR.Family>>:
  +v_1000176 = {"Array" : String}
  +v_1000177 = {None{} : Maybe<&2, String>}
  +v_1000178 = {0n : Nat}
  +v_1000179 = {"Array" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000207 => template_body_ref("U32", []), v_1000206 => +v_1000180 = template_unbox(BIR.Descriptor, v_1000206); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000180}}, False{}, v_1000205 => template_body_fld(v_1000180), v_1000204 => +v_1000181 = template_unbox(BIR.DescriptorField, v_1000204); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000179, [v_1000181]}}, False{}, v_1000203 => template_body_arm(v_1000179, [v_1000181]), v_1000202 => +v_1000182 = template_unbox(BIR.DescriptorArm, v_1000202); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000176, v_1000177, v_1000178, [v_1000182]}}, False{}, v_1000201 => template_body_fam(v_1000176, v_1000177, v_1000178, [v_1000182]), v_1000200 => +v_1000183 = template_unbox(BIR.Family, v_1000200); template_continuation_45(v_1000159, v_1000167, v_1000175, v_1000183)}}}}

def template_continuation_47(+v_1000159: BIR.Family, +v_1000167: BIR.Family) -> TemplateProgress<List<&2, BIR.Family>>:
  +v_1000168 = {"Nat" : String}
  +v_1000169 = {None{} : Maybe<&2, String>}
  +v_1000170 = {0n : Nat}
  +v_1000171 = {"Nat" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000215 => template_body_ref("U32", []), v_1000214 => +v_1000172 = template_unbox(BIR.Descriptor, v_1000214); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000172}}, False{}, v_1000213 => template_body_fld(v_1000172), v_1000212 => +v_1000173 = template_unbox(BIR.DescriptorField, v_1000212); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000171, [v_1000173]}}, False{}, v_1000211 => template_body_arm(v_1000171, [v_1000173]), v_1000210 => +v_1000174 = template_unbox(BIR.DescriptorArm, v_1000210); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000168, v_1000169, v_1000170, [v_1000174]}}, False{}, v_1000209 => template_body_fam(v_1000168, v_1000169, v_1000170, [v_1000174]), v_1000208 => +v_1000175 = template_unbox(BIR.Family, v_1000208); template_continuation_46(v_1000159, v_1000167, v_1000175)}}}}

def template_continuation_48(+v_1000159: BIR.Family) -> TemplateProgress<List<&2, BIR.Family>>:
  +v_1000160 = {"F32" : String}
  +v_1000161 = {None{} : Maybe<&2, String>}
  +v_1000162 = {0n : Nat}
  +v_1000163 = {"F32" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000223 => template_body_ref("U32", []), v_1000222 => +v_1000164 = template_unbox(BIR.Descriptor, v_1000222); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000164}}, False{}, v_1000221 => template_body_fld(v_1000164), v_1000220 => +v_1000165 = template_unbox(BIR.DescriptorField, v_1000220); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000163, [v_1000165]}}, False{}, v_1000219 => template_body_arm(v_1000163, [v_1000165]), v_1000218 => +v_1000166 = template_unbox(BIR.DescriptorArm, v_1000218); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000160, v_1000161, v_1000162, [v_1000166]}}, False{}, v_1000217 => template_body_fam(v_1000160, v_1000161, v_1000162, [v_1000166]), v_1000216 => +v_1000167 = template_unbox(BIR.Family, v_1000216); template_continuation_47(v_1000159, v_1000167)}}}}

def template_body_shadow_fams() -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"U32", Some{"U32"}, 0n, []}}, False{}, v_1000225 => template_body_fam("U32", Some{"U32"}, 0n, []), v_1000224 => +v_1000159 = template_unbox(BIR.Family, v_1000224); template_continuation_48(v_1000159)}

def template_body_shadow_ctors() -> TemplateProgress<List<&2, BIR.ConstructorLayout>>:
  TemplateFinished{TemplateValue{[BIR.ConstructorLayout{30, "F32", None{}, []}, BIR.ConstructorLayout{31, "Nat", None{}, []}, BIR.ConstructorLayout{32, "Array", None{}, []}, BIR.ConstructorLayout{33, "IO.OP", None{}, []}]}}

def template_body_shadow_program() -> TemplateProgress<BIR.Program>:
  v_1000226 = {[] : List<&2, BIR.Code>}
  v_1000227 = {[] : List<&2, BIR.Declaration>}
  v_1000228 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_fams{}}, False{}, v_1000231 => template_body_shadow_fams, v_1000230 => +v_1000229 = template_unbox(List<&2, BIR.Family>, v_1000230); TemplateFinished{TemplateValue{BIR.Program{v_1000226, v_1000227, v_1000228, v_1000229, [], BIR.Library{[]}}}}}

def template_match_49(+v_1000236: cps_provider_2_ShowOut, +v_1: String) -> TemplateProgress<String>:
  match v_1000236:
    case cps_provider_2_ShowOk{v_11, v_12}:
      TemplateFinished{TemplateValue{String.append(String.append(v_1, "="), String.append(v_11, String.append("@", v_12)))}}
    case cps_provider_2_ShowFail{v_14}:
      TemplateFinished{TemplateValue{String.append(String.append(v_1, "!"), v_14)}}

def template_body_shadow_one(+v_1: String, +v_3: cps_provider_1_Context) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{v_1, []}}, False{}, v_1000243 => template_body_ref(v_1, []), v_1000242 => +v_1000233 = template_unbox(BIR.Descriptor, v_1000242); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_ctors{}}, False{}, v_1000241 => template_body_shadow_ctors, v_1000240 => +v_1000234 = template_unbox(List<&2, BIR.ConstructorLayout>, v_1000240); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_fams{}}, False{}, v_1000239 => template_body_shadow_fams, v_1000238 => +v_1000235 = template_unbox(List<&2, BIR.Family>, v_1000238); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_build{{v_3 : cps_provider_1_Context}, v_1000233, v_1000234, v_1000235}}, v_1000237 => +v_1000236 = template_unbox(cps_provider_2_ShowOut, v_1000237); template_match_49(v_1000236, v_1)}}}}

def template_continuation_50(v_4: cps_provider_1_Context, +v_1000246: String, v_1000247: String, +v_1000248: String, v_1000249: String, +v_1000250: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_one{"IO.OP", v_4}}, False{}, v_1000254 => template_body_shadow_one("IO.OP", v_4), v_1000253 => +v_1000252 = template_unbox(String, v_1000253); TemplateFinished{TemplateValue{String.append(v_1000246, String.append(v_1000247, String.append(v_1000248, String.append(v_1000249, String.append(v_1000250, String.append({";" : String}, v_1000252))))))}}}

def template_continuation_51(+v_4: cps_provider_1_Context, +v_1000246: String, v_1000247: String, +v_1000248: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_one{"Array", v_4}}, False{}, v_1000256 => template_body_shadow_one("Array", v_4), v_1000255 => +v_1000250 = template_unbox(String, v_1000255); template_continuation_50(v_4, v_1000246, v_1000247, v_1000248, {";" : String}, v_1000250)}

def template_continuation_52(+v_4: cps_provider_1_Context, +v_1000246: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_one{"Nat", v_4}}, False{}, v_1000258 => template_body_shadow_one("Nat", v_4), v_1000257 => +v_1000248 = template_unbox(String, v_1000257); template_continuation_51(v_4, v_1000246, {";" : String}, v_1000248)}

def template_continuation_53(+v_1000245: cps_provider_1_Context) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_one{"F32", v_1000245}}, False{}, v_1000260 => template_body_shadow_one("F32", v_1000245), v_1000259 => +v_1000246 = template_unbox(String, v_1000259); template_continuation_52(v_1000245, v_1000246)}

def template_body_shadow_summary() -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_program{}}, False{}, v_1000263 => template_body_shadow_program, v_1000262 => +v_1000244 = template_unbox(BIR.Program, v_1000262); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_context{v_1000244}}, v_1000261 => +v_1000245 = template_unbox(cps_provider_1_Context, v_1000261); template_continuation_53(v_1000245)}}

def template_match_54(v_1000266: Bool) -> TemplateProgress<String>:
  match v_1000266:
    case False{}:
      TemplateFinished{TemplateValue{"SEP"}}
    case True{}:
      TemplateFinished{TemplateValue{"SAME"}}

def template_match_55(+v_1000264: Maybe<&2, String>, +v_1000265: Maybe<&2, String>) -> TemplateProgress<String>:
  match v_1000264, v_1000265:
    case Some{v_7}, Some{v_8}:
      v_1000266 = String.eq(v_7, v_8)
      template_match_54(v_1000266)
    case _, _:
      TemplateFinished{TemplateValue{"FAIL"}}

def template_body_key_pair(+v_0: BIR.Descriptor, +v_1: BIR.Descriptor) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_descriptor_key{v_0}}, v_1000268 => +v_1000264 = template_unbox(Maybe<&2, String>, v_1000268); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_descriptor_key{v_1}}, v_1000267 => +v_1000265 = template_unbox(Maybe<&2, String>, v_1000267); template_match_55(v_1000264, v_1000265)}}

def template_match_56(v_1000273: Bool) -> TemplateProgress<String>:
  match v_1000273:
    case False{}:
      TemplateFinished{TemplateValue{"K-DIFF"}}
    case True{}:
      TemplateFinished{TemplateValue{"K-SAME"}}

def template_match_57(+v_1000270: Maybe<&2, String>, +v_1000272: Maybe<&2, String>) -> TemplateProgress<String>:
  match v_1000270, v_1000272:
    case Some{v_7}, Some{v_8}:
      v_1000273 = String.eq(v_7, v_8)
      template_match_56(v_1000273)
    case _, _:
      TemplateFinished{TemplateValue{"K-FAIL"}}

def template_body_deep_key_probe() -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000279 => template_body_ref("U32", []), v_1000278 => +v_1000269 = template_unbox(BIR.Descriptor, v_1000278); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_descriptor_key{v_1000269}}, v_1000277 => +v_1000270 = template_unbox(Maybe<&2, String>, v_1000277); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"F0", []}}, False{}, v_1000276 => template_body_ref("F0", []), v_1000275 => +v_1000271 = template_unbox(BIR.Descriptor, v_1000275); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_descriptor_key{v_1000271}}, v_1000274 => +v_1000272 = template_unbox(Maybe<&2, String>, v_1000274); template_match_57(v_1000270, v_1000272)}}}}

def template_body_key_checks() -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_key_pair{BIR.DescriptorRef{"@T", []}, BIR.DescriptorConstructor{"T", []}}}, False{}, v_1000294 => template_body_key_pair(BIR.DescriptorRef{"@T", []}, BIR.DescriptorConstructor{"T", []}), v_1000293 => +v_1000280 = template_unbox(String, v_1000293); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_key_pair{BIR.DescriptorParameter{1n}, BIR.DescriptorRef{"1", []}}}, False{}, v_1000292 => template_body_key_pair(BIR.DescriptorParameter{1n}, BIR.DescriptorRef{"1", []}), v_1000291 => +v_1000281 = template_unbox(String, v_1000291); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_key_pair{BIR.DescriptorQuantity{BIR.Once{}}, BIR.DescriptorKind{BIR.DescriptorNull{}}}}, False{}, v_1000290 => template_body_key_pair(BIR.DescriptorQuantity{BIR.Once{}}, BIR.DescriptorKind{BIR.DescriptorNull{}}), v_1000289 => +v_1000282 = template_unbox(String, v_1000289); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_key_pair{BIR.DescriptorRef{"x", []}, BIR.DescriptorConstructor{"x", []}}}, False{}, v_1000288 => template_body_key_pair(BIR.DescriptorRef{"x", []}, BIR.DescriptorConstructor{"x", []}), v_1000287 => +v_1000283 = template_unbox(String, v_1000287); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_deep_key_probe{}}, False{}, v_1000286 => template_body_deep_key_probe, v_1000285 => +v_1000284 = template_unbox(String, v_1000285); TemplateFinished{TemplateValue{String.append(v_1000280, String.append(v_1000281, String.append(v_1000282, String.append(v_1000283, v_1000284))))}}}}}}}

def template_continuation_58(+v_1000296: String, +v_1000297: Maybe<&2, String>, +v_1000298: Nat, +v_1000302: BIR.DescriptorArm, +v_1000306: BIR.DescriptorArm, +v_1000295: BIR.Family) -> TemplateProgress<List<&2, BIR.Family>>:
  +v_1000307 = {"ChC" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000319 => template_body_ref("U32", []), v_1000318 => +v_1000308 = template_unbox(BIR.Descriptor, v_1000318); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000308}}, False{}, v_1000317 => template_body_fld(v_1000308), v_1000316 => +v_1000309 = template_unbox(BIR.DescriptorField, v_1000316); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000307, [v_1000309]}}, False{}, v_1000315 => template_body_arm(v_1000307, [v_1000309]), v_1000314 => +v_1000310 = template_unbox(BIR.DescriptorArm, v_1000314); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{v_1000296, v_1000297, v_1000298, [v_1000302, v_1000306, v_1000310]}}, False{}, v_1000313 => template_body_fam(v_1000296, v_1000297, v_1000298, [v_1000302, v_1000306, v_1000310]), v_1000312 => +v_1000311 = template_unbox(BIR.Family, v_1000312); TemplateFinished{TemplateValue{[v_1000295, v_1000311]}}}}}}

def template_continuation_59(+v_1000296: String, +v_1000297: Maybe<&2, String>, +v_1000298: Nat, +v_1000302: BIR.DescriptorArm, +v_1000295: BIR.Family) -> TemplateProgress<List<&2, BIR.Family>>:
  +v_1000303 = {"ChB" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000325 => template_body_ref("U32", []), v_1000324 => +v_1000304 = template_unbox(BIR.Descriptor, v_1000324); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000304}}, False{}, v_1000323 => template_body_fld(v_1000304), v_1000322 => +v_1000305 = template_unbox(BIR.DescriptorField, v_1000322); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000303, [v_1000305]}}, False{}, v_1000321 => template_body_arm(v_1000303, [v_1000305]), v_1000320 => +v_1000306 = template_unbox(BIR.DescriptorArm, v_1000320); template_continuation_58(v_1000296, v_1000297, v_1000298, v_1000302, v_1000306, v_1000295)}}}

def template_continuation_60(+v_1000295: BIR.Family) -> TemplateProgress<List<&2, BIR.Family>>:
  +v_1000297 = {None{} : Maybe<&2, String>}
  +v_1000299 = {"ChA" : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"U32", []}}, False{}, v_1000331 => template_body_ref("U32", []), v_1000330 => +v_1000300 = template_unbox(BIR.Descriptor, v_1000330); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fld{v_1000300}}, False{}, v_1000329 => template_body_fld(v_1000300), v_1000328 => +v_1000301 = template_unbox(BIR.DescriptorField, v_1000328); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_arm{v_1000299, [v_1000301]}}, False{}, v_1000327 => template_body_arm(v_1000299, [v_1000301]), v_1000326 => +v_1000302 = template_unbox(BIR.DescriptorArm, v_1000326); template_continuation_59({"Choice" : String}, v_1000297, {0n : Nat}, v_1000302, v_1000295)}}}

def template_body_multi_fams() -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fam{"U32", Some{"U32"}, 0n, []}}, False{}, v_1000333 => template_body_fam("U32", Some{"U32"}, 0n, []), v_1000332 => +v_1000295 = template_unbox(BIR.Family, v_1000332); template_continuation_60(v_1000295)}

def template_body_multi_ctors() -> TemplateProgress<List<&2, BIR.ConstructorLayout>>:
  TemplateFinished{TemplateValue{[BIR.ConstructorLayout{40, "ChA", None{}, []}, BIR.ConstructorLayout{41, "ChB", None{}, []}, BIR.ConstructorLayout{42, "ChC", None{}, []}]}}

def template_body_multi_program() -> TemplateProgress<BIR.Program>:
  v_1000334 = {[] : List<&2, BIR.Code>}
  v_1000335 = {[] : List<&2, BIR.Declaration>}
  v_1000336 = {[] : List<&2, BIR.ConstructorLayout>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_multi_fams{}}, False{}, v_1000339 => template_body_multi_fams, v_1000338 => +v_1000337 = template_unbox(List<&2, BIR.Family>, v_1000338); TemplateFinished{TemplateValue{BIR.Program{v_1000334, v_1000335, v_1000336, v_1000337, [], BIR.Library{[]}}}}}

def template_body_multi_text(+v_1: cps_provider_2_ShowOut) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_2_ShowOk{v_5, v_6}:
      TemplateFinished{TemplateValue{String.append(String.append("C", v_5), String.append("|M", v_6))}}
    case cps_provider_2_ShowFail{v_8}:
      TemplateFinished{TemplateValue{String.append("C!", v_8)}}

def template_body_multi_summary() -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_multi_program{}}, False{}, v_1000356 => template_body_multi_program, v_1000355 => +v_1000340 = template_unbox(BIR.Program, v_1000355); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_context{v_1000340}}, v_1000354 => +v_1000341 = template_unbox(cps_provider_1_Context, v_1000354); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Choice", []}}, False{}, v_1000353 => template_body_ref("Choice", []), v_1000352 => +v_1000342 = template_unbox(BIR.Descriptor, v_1000352); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_multi_ctors{}}, False{}, v_1000351 => template_body_multi_ctors, v_1000350 => +v_1000343 = template_unbox(List<&2, BIR.ConstructorLayout>, v_1000350); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_multi_fams{}}, False{}, v_1000349 => template_body_multi_fams, v_1000348 => +v_1000344 = template_unbox(List<&2, BIR.Family>, v_1000348); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_build{v_1000341, v_1000342, v_1000343, v_1000344}}, v_1000347 => +v_1000345 = template_unbox(cps_provider_2_ShowOut, v_1000347); template_body_multi_text(v_1000345)}}}}}}

def template_continuation_62(+v_1000363: cps_provider_2_ShowOut, +v_1000364: String, v_1000365: String, +v_1000366: String, v_1000367: String, +v_1000368: String) -> TemplateProgress<PhysSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_multi_summary{}}, False{}, v_1000374 => template_body_multi_summary, v_1000373 => +v_1000370 = template_unbox(String, v_1000373); TemplatePending{TemplateRequestGroup_0{TemplateRequest_unwrap{v_1000363, String.append(v_1000364, String.append(v_1000365, String.append(v_1000366, String.append(v_1000367, String.append(v_1000368, String.append({"|" : String}, v_1000370))))))}}, v_1000372 => +v_1000371 = template_unbox(PhysSmoke, v_1000372); TemplateFinished{TemplateValue{v_1000371}}}}

def template_continuation_63(+v_1000363: cps_provider_2_ShowOut, +v_1000364: String, v_1000365: String, +v_1000366: String) -> TemplateProgress<PhysSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_key_checks{}}, False{}, v_1000376 => template_body_key_checks, v_1000375 => +v_1000368 = template_unbox(String, v_1000375); template_continuation_62(v_1000363, v_1000364, v_1000365, v_1000366, {"|K:" : String}, v_1000368)}

def template_continuation_64(+v_1000363: cps_provider_2_ShowOut, +v_1000364: String) -> TemplateProgress<PhysSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_shadow_summary{}}, False{}, v_1000378 => template_body_shadow_summary, v_1000377 => +v_1000366 = template_unbox(String, v_1000377); template_continuation_63(v_1000363, v_1000364, {"|" : String}, v_1000366)}

def template_continuation_65(+v_1000358: cps_provider_1_Context) -> TemplateProgress<PhysSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_ref{"Seg", []}}, False{}, v_1000387 => template_body_ref("Seg", []), v_1000386 => +v_1000360 = template_unbox(BIR.Descriptor, v_1000386); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_constructors{}}, False{}, v_1000385 => template_body_constructors, v_1000384 => +v_1000361 = template_unbox(List<&2, BIR.ConstructorLayout>, v_1000384); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_families{}}, False{}, v_1000383 => template_body_families, v_1000382 => +v_1000362 = template_unbox(List<&2, BIR.Family>, v_1000382); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_build{{v_1000358 : cps_provider_1_Context}, v_1000360, v_1000361, v_1000362}}, v_1000381 => +v_1000363 = template_unbox(cps_provider_2_ShowOut, v_1000381); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_deep_summary{}}, False{}, v_1000380 => template_body_deep_summary, v_1000379 => +v_1000364 = template_unbox(String, v_1000379); template_continuation_64(v_1000363, v_1000364)}}}}}

def template_body_main(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<PhysSmoke>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_program{}}, False{}, v_1000390 => template_body_program, v_1000389 => +v_1000357 = template_unbox(BIR.Program, v_1000389); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_context{v_1000357}}, v_1000388 => +v_1000358 = template_unbox(cps_provider_1_Context, v_1000388); template_continuation_65(v_1000358)}}

def template_body_unwrap(+v_1: cps_provider_2_ShowOut, +v_3: String) -> TemplateProgress<PhysSmoke>:
  match v_1:
    case cps_provider_2_ShowOk{v_7, v_8}:
      TemplateFinished{TemplateValue{PhysSmoke{v_7, String.append(v_8, String.append("|", v_3))}}}
    case cps_provider_2_ShowFail{v_10}:
      TemplateFinished{TemplateValue{PhysSmoke{v_10, v_3}}}

def template_continuation_67(+v_1000392: Map<&2, BIR.DescriptorArm>, +v_16: cps_provider_3_NfContext, +v_11: List<&2, BIR.Family>, +v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<cps_provider_1_Context>:
  +v_23 = {cps_provider_1_Context{v_16, v_11, cps_provider_1_Plan{Map.new(&2, cps_provider_1_NodeResult), v_1000392}} : cps_provider_1_Context}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_plan_node_index{v_23, v_10}}, v_1000396 => +v_1000395 = template_unbox(Map<&2, cps_provider_1_NodeResult>, v_1000396); TemplateFinished{TemplateValue{cps_provider_1_Context{{v_16 : cps_provider_3_NfContext}, {v_11 : List<&2, BIR.Family>}, cps_provider_1_Plan{v_1000395, v_1000392}}}}}

def template_continuation_68(+v_1000391: cps_provider_3_NfContext, +v_11: List<&2, BIR.Family>, +v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<cps_provider_1_Context>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_plan_arm_index{v_11}}, v_1000397 => +v_1000392 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1000397); template_continuation_67(v_1000392, v_1000391, v_11, v_10)}

def template_body_cps_provider_1_context(+v_0: BIR.Program) -> TemplateProgress<cps_provider_1_Context>:
  match v_0:
    case BIR.Program{+v_8, +v_9, +v_10, +v_11, +v_12, +v_13}:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_nf_context{v_11, v_12}}, v_1000398 => +v_1000391 = template_unbox(cps_provider_3_NfContext, v_1000398); template_continuation_68(v_1000391, v_11, v_10)}

def template_body_cps_provider_1_context_nf(+v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_3_NfContext>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_context_nf(v_1)}}

def template_body_cps_provider_1_context_families(+v_1: cps_provider_1_Context) -> TemplateProgress<List<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_context_families(v_1)}}

def template_body_cps_provider_1_context_plan(+v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_Plan>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_context_plan(v_1)}}

def template_match_70(v_1000399: cps_provider_1_Plan) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  match v_1000399:
    case cps_provider_1_Plan{+v_7, +v_8}:
      TemplateFinished{TemplateValue{v_7}}

def template_body_cps_provider_1_context_nodes(+v_1: cps_provider_1_Context) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  v_1000399 = {template_pure_cps_provider_1_context_plan(v_1) : cps_provider_1_Plan}
  template_match_70(v_1000399)

def template_match_71(v_1000400: cps_provider_1_Plan) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_1000400:
    case cps_provider_1_Plan{+v_6, +v_7}:
      TemplateFinished{TemplateValue{v_7}}

def template_body_cps_provider_1_context_arms(+v_1: cps_provider_1_Context) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  v_1000400 = {template_pure_cps_provider_1_context_plan(v_1) : cps_provider_1_Plan}
  template_match_71(v_1000400)

def template_body_cps_provider_1_nf_families(+v_1: cps_provider_3_NfContext) -> TemplateProgress<Map<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_nf_families(v_1)}}

def template_body_cps_provider_1_nf_functions(+v_1: cps_provider_3_NfContext) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_nf_functions(v_1)}}

def template_body_cps_provider_1_family_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<Maybe<&2, BIR.Family>>:
  TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_family_of{v_3, template_pure_cps_provider_1_nf_families(template_pure_cps_provider_1_context_nf(v_1))}}, v_1000402 => +v_1000401 = template_unbox(Maybe<&2, BIR.Family>, v_1000402); TemplateFinished{TemplateValue{v_1000401}}}

def template_body_cps_provider_1_function_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<Maybe<&2, BIR.TypeFunction>>:
  TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_function_of{v_3, template_pure_cps_provider_1_nf_functions(template_pure_cps_provider_1_context_nf(v_1))}}, v_1000404 => +v_1000403 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1000404); TemplateFinished{TemplateValue{v_1000403}}}

def template_match_72(+v_1000405: Maybe<&2, BIR.DescriptorArm>, +v_1: String, v_8: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_1000405:
    case Some{+v_23}:
      TemplateFinished{TemplateValue{Some{v_23}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_of{v_1, v_8}}, v_1000407 => +v_1000406 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1000407); TemplateFinished{TemplateValue{v_1000406}}}

def template_match_73(+v_7: BIR.Family, +v_1: String, v_8: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_7:
    case BIR.Family{+v_15, +v_16, +v_17, +v_18, +v_19, +v_20}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_in{v_1, v_20}}, v_1000408 => +v_1000405 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1000408); template_match_72(v_1000405, v_1, v_8)}

def template_body_cps_provider_1_arm_of(+v_1: String, +v_3: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004102 <> v_1004103:
      template_match_73(v_1004102, v_1, v_1004103)

def template_match_75(v_1000409: Bool, +v_7: BIR.DescriptorArm, +v_1: String, v_8: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_1000409:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_7}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_in{v_1, v_8}}, v_1000411 => +v_1000410 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1000411); TemplateFinished{TemplateValue{v_1000410}}}

def template_match_76(+v_7: BIR.DescriptorArm, +v_1: String, v_8: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_7:
    case BIR.DescriptorArm{+v_11, +v_12}:
      v_1000409 = {String.eq(v_1, v_11) : Bool}
      template_match_75(v_1000409, v_7, v_1, v_8)

def template_body_cps_provider_1_arm_in(+v_1: String, +v_3: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004104 <> v_1004105:
      template_match_76(v_1004104, v_1, v_1004105)

def template_match_78(+v_5: BIR.Family, v_6: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_5:
    case BIR.Family{+v_13, +v_14, +v_15, +v_16, +v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_plan_arm_index{v_6}}, v_1000416 => +v_1000413 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1000416); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_plan_family_arms{{v_18 : List<&2, BIR.DescriptorArm>}, v_1000413}}, v_1000415 => +v_1000414 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1000415); TemplateFinished{TemplateValue{v_1000414}}}}

def template_body_cps_provider_1_plan_arm_index(+v_1: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.DescriptorArm)}}
    case +v_5 <> v_6:
      template_match_78(v_5, v_6)

def template_match_80(+v_7: BIR.DescriptorArm, v_8: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_7:
    case BIR.DescriptorArm{+v_11, +v_12}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_plan_family_arms{v_8, v_3}}, v_1000418 => +v_1000417 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1000418); TemplateFinished{TemplateValue{Map.set(&2, BIR.DescriptorArm, v_1000417, v_11, {BIR.DescriptorArm{v_11, v_12} : BIR.DescriptorArm})}}}

def template_body_cps_provider_1_plan_family_arms(+v_1: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>) -> TemplateProgress<Map<&2, BIR.DescriptorArm>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_3}}
    case +v_7 <> v_8:
      template_match_80(v_7, v_8, v_3)

def template_body_cps_provider_1_arm_declared(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<Maybe<&2, BIR.DescriptorArm>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_context_arms{v_1}}, False{}, v_1000421 => template_body_cps_provider_1_context_arms(v_1), v_1000420 => +v_1000419 = template_unbox(Map<&2, BIR.DescriptorArm>, v_1000420); TemplateFinished{TemplateValue{IndexLookup.find(BIR.DescriptorArm, v_1000419, v_3)}}}

def template_body_cps_provider_1_live_field(+v_0: BIR.Quantity) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_live_field(v_0)}}

def template_body_cps_provider_1_layout_fuel() -> TemplateProgress<Nat>:
  TemplateFinished{TemplateValue{1024n}}

def template_body_cps_provider_1_nf_of(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{template_pure_cps_provider_1_context_nf(v_1), v_2, v_5, 0n, v_7}}, v_1000423 => +v_1000422 = template_unbox(cps_provider_3_Nf, v_1000423); TemplateFinished{TemplateValue{v_1000422}}}

def template_body_cps_provider_1_value_layout(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_LayoutResult>:
  +v_1000426 = {[] : List<&2, cps_provider_3_NfVal>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1000431 => template_body_cps_provider_1_layout_fuel, v_1000430 => +v_1000427 = template_unbox(Nat, v_1000430); TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_of_desc{{v_1 : cps_provider_1_Context}, {v_2 : BIR.Descriptor}, v_1000426, v_1000427}}, v_1000429 => +v_1000428 = template_unbox(cps_provider_1_LayoutResult, v_1000429); TemplateFinished{TemplateValue{v_1000428}}}}

def template_match_82(+v_1000432: cps_provider_3_Nf, +v_1: cps_provider_1_Context, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000432:
    case cps_provider_3_NfFail{+v_11}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFailed{v_11}}}
    case cps_provider_3_NfOk{+v_13}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_of_val{v_1, v_13, v_7}}, v_1000434 => +v_1000433 = template_unbox(cps_provider_1_LayoutResult, v_1000434); TemplateFinished{TemplateValue{v_1000433}}}

def template_body_cps_provider_1_layout_of_desc(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, v_5, v_7}}, False{}, v_1000436 => template_body_cps_provider_1_nf_of(v_1, v_2, v_5, v_7), v_1000435 => +v_1000432 = template_unbox(cps_provider_3_Nf, v_1000435); template_match_82(v_1000432, v_1, v_7)}

def template_match_83(v_1000437: Bool, +v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000437:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_val{v_1, v_3, Nat.sub(v_5, 1n)}}, v_1000439 => +v_1000438 = template_unbox(cps_provider_1_LayoutResult, v_1000439); TemplateFinished{TemplateValue{v_1000438}}}

def template_body_cps_provider_1_layout_of_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  v_1000437 = {Nat.is_eq(v_5, 0n) : Bool}
  template_match_83(v_1000437, v_1, v_3, v_5)

def template_match_84(+v_1000440: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_3_NfVal>, +v_5: Nat, +v_9: String) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000440:
    case Some{+v_13}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_family{v_1, v_13, v_10, v_5}}, v_1000442 => +v_1000441 = template_unbox(cps_provider_1_LayoutResult, v_1000442); TemplateFinished{TemplateValue{v_1000441}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_unresolved{v_1, v_9}}, v_1000444 => +v_1000443 = template_unbox(cps_provider_1_LayoutResult, v_1000444); TemplateFinished{TemplateValue{v_1000443}}}

def template_body_cps_provider_1_layout_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_3:
    case cps_provider_3_NfType{+v_1004106, +v_1004107}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_lookup{v_1, v_1004106}}, False{}, v_1004108 => template_body_cps_provider_1_family_lookup(v_1, v_1004106), v_1004109 => +v_1004110 = template_unbox(Maybe<&2, BIR.Family>, v_1004109); template_match_84(v_1004110, v_1, v_1004107, v_5, v_1004106)}
    case cps_provider_3_NfCtor{+v_1004111, +v_1004112}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_3_NfQuantity{+v_1004113}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_3_NfKind{+v_1004114}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_3_NfOther{+v_1004115}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case cps_provider_3_NfMissing{+v_1004116}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case v_1004117:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}

def template_match_86(+v_1000447: Maybe<&2, BIR.TypeFunction>, +v_3: String) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000447:
    case Some{+v_7}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxUnresolved{v_3}}}}}

def template_body_cps_provider_1_layout_unresolved(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_LayoutResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_function_lookup{v_1, v_3}}, False{}, v_1000449 => template_body_cps_provider_1_function_lookup(v_1, v_3), v_1000448 => +v_1000447 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1000448); template_match_86(v_1000447, v_3)}

def template_match_87(+v_17: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_15: String, +v_20: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_17:
    case Some{+v_23}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_native{v_1, v_23, v_15, v_20, v_5, v_7}}, v_1000452 => +v_1000451 = template_unbox(cps_provider_1_LayoutResult, v_1000452); TemplateFinished{TemplateValue{v_1000451}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_data{v_1, v_15, v_20, v_5, v_7}}, v_1000454 => +v_1000453 = template_unbox(cps_provider_1_LayoutResult, v_1000454); TemplateFinished{TemplateValue{v_1000453}}}

def template_match_88(v_1000450: Bool, +v_17: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_15: String, +v_20: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000450:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}}}
    case True{}:
      template_match_87(v_17, v_1, v_15, v_20, v_5, v_7)

def template_body_cps_provider_1_layout_family(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_2:
    case BIR.Family{+v_1004118, +v_1004119, +v_1004120, +v_1004121, +v_1004122, +v_1004123}:
      v_1004124 = {Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_5), v_1004122) : Bool}
      template_match_88(v_1004124, v_1004120, v_1, v_1004118, v_1004123, v_5, v_7)

def template_match_90(v_1000459: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000459:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxIo{}}}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_data{v_1, v_5, v_7, v_10, v_12}}, v_1000461 => +v_1000460 = template_unbox(cps_provider_1_LayoutResult, v_1000461); TemplateFinished{TemplateValue{v_1000460}}}

def template_match_91(v_1000458: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000458:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxArray{}}}}}
    case False{}:
      v_1000459 = {String.eq(v_3, "IO.OP") : Bool}
      template_match_90(v_1000459, v_1, v_5, v_7, v_10, v_12)

def template_match_92(v_1000457: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000457:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}}}
    case False{}:
      v_1000458 = {String.eq(v_3, "Array") : Bool}
      template_match_91(v_1000458, v_3, v_1, v_5, v_7, v_10, v_12)

def template_match_93(v_1000456: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000456:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}}}
    case False{}:
      v_1000457 = {String.eq(v_3, "F32") : Bool}
      template_match_92(v_1000457, v_3, v_1, v_5, v_7, v_10, v_12)

def template_match_94(v_1000455: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000455:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord64{}}}}}
    case False{}:
      v_1000456 = {String.eq(v_3, "U32") : Bool}
      template_match_93(v_1000456, v_3, v_1, v_5, v_7, v_10, v_12)

def template_body_cps_provider_1_layout_native(+v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  v_1000455 = {String.eq(v_3, "Nat") : Bool}
  template_match_94(v_1000455, v_3, v_1, v_5, v_7, v_10, v_12)

def template_body_cps_provider_1_field_scope(+v_2: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  +v_7 = {cps_provider_3_NfMissing{BIR.DescriptorNull{}} : cps_provider_3_NfVal}
  TemplateFinished{TemplateValue{List.append(&2, cps_provider_3_NfVal, v_2, [v_7])}}

def template_match_95(+v_1000462: cps_provider_1_Layouts, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_20: String, +v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_Plans>:
  match v_1000462:
    case cps_provider_1_LayoutsFail{+v_24}:
      TemplateFinished{TemplateValue{cps_provider_1_PlansFail{v_24}}}
    case cps_provider_1_LayoutsOk{+v_26}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_layouts{v_1, v_17, v_6, v_8, cps_provider_1_LayArm{v_20, v_26} <> v_11}}, v_1000464 => +v_1000463 = template_unbox(cps_provider_1_Plans, v_1000464); TemplateFinished{TemplateValue{v_1000463}}}

def template_match_96(+v_16: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, v_17: List<&2, BIR.DescriptorArm>, +v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_Plans>:
  match v_16:
    case BIR.DescriptorArm{+v_20, +v_21}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_field_layouts{v_1, v_21, v_6, v_8, []}}, v_1000465 => +v_1000462 = template_unbox(cps_provider_1_Layouts, v_1000465); template_match_95(v_1000462, v_1, v_17, v_6, v_8, v_20, v_11)}

def template_body_cps_provider_1_arm_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_Plans>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_PlansOk{List.reverse(&2, cps_provider_1_LayArm, v_11)}}}
    case +v_1004125 <> v_1004126:
      template_match_96(v_1004125, v_1, v_6, v_8, v_1004126, v_11)

def template_match_98(+v_1000470: cps_provider_1_LayoutResult, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_26: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_1000470:
    case cps_provider_1_LayoutFailed{+v_31}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutsFail{v_31}}}
    case cps_provider_1_LayoutFound{+v_33}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_field_layouts{v_1, v_17, v_26, v_8, v_33 <> v_11}}, v_1000472 => +v_1000471 = template_unbox(cps_provider_1_Layouts, v_1000472); TemplateFinished{TemplateValue{v_1000471}}}

def template_match_99(v_1000467: Bool, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_26: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, +v_23: BIR.Descriptor, +v_6: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_1000467:
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_cps_provider_1_field_layouts{v_1, v_17, v_26, v_8, v_11}}, v_1000469 => +v_1000468 = template_unbox(cps_provider_1_Layouts, v_1000469); TemplateFinished{TemplateValue{v_1000468}}}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_of_desc{v_1, v_23, v_6, v_8}}, False{}, v_1000474 => template_body_cps_provider_1_layout_of_desc(v_1, v_23, v_6, v_8), v_1000473 => +v_1000470 = template_unbox(cps_provider_1_LayoutResult, v_1000473); template_match_98(v_1000470, v_1, v_17, v_26, v_8, v_11)}

def template_continuation_100(+v_1000466: List<&2, cps_provider_3_NfVal>, +v_22: BIR.Quantity, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, +v_23: BIR.Descriptor, +v_6: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_1_Layouts>:
  v_1000467 = {template_pure_cps_provider_1_live_field(v_22) : Bool}
  template_match_99(v_1000467, v_1, v_17, v_1000466, v_8, v_11, v_23, v_6)

def template_match_101(+v_16: BIR.DescriptorField, +v_6: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_1_Context, v_17: List<&2, BIR.DescriptorField>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_16:
    case BIR.DescriptorField{+v_21, +v_22, +v_23}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_field_scope{v_6}}, False{}, v_1000476 => template_body_cps_provider_1_field_scope(v_6), v_1000475 => +v_1000466 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1000475); template_continuation_100(v_1000466, v_22, v_1, v_17, v_8, v_11, v_23, v_6)}

def template_body_cps_provider_1_field_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> TemplateProgress<cps_provider_1_Layouts>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutsOk{List.reverse(&2, cps_provider_1_Layout, v_11)}}}
    case +v_1004127 <> v_1004128:
      template_match_101(v_1004127, v_6, v_1, v_1004128, v_8, v_11)

def template_match_103(v_1000480: Bool, +v_24: Nat, +v_21: List<&2, cps_provider_1_CWord>, +v_17: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000480:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxWide{v_24}}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutData{v_21, v_17}}}}

def template_continuation_104(+v_1000479: List<&2, cps_provider_1_CWord>, +v_17: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<cps_provider_1_LayoutResult>:
  +v_24 = List.length(&2, cps_provider_1_CWord, v_1000479)
  v_1000480 = {Nat.is_gt(v_24, 8n) : Bool}
  template_match_103(v_1000480, v_24, v_1000479, v_17)

def template_match_105(+v_1000478: cps_provider_1_Plans) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000478:
    case cps_provider_1_PlansFail{+v_15}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFailed{v_15}}}
    case cps_provider_1_PlansOk{+v_17}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_arms{v_17, template_pure_cps_provider_1_arms_tagged(v_17)}}, v_1000481 => +v_1000479 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000481); template_continuation_104(v_1000479, v_17)}

def template_match_106(+v_1000477: Bool, +v_3: String, +v_1: cps_provider_1_Context, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  match v_1000477:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxRecursive{v_3}}}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_layouts{v_1, v_5, v_8, v_10, []}}, False{}, v_1000483 => template_body_cps_provider_1_arm_layouts(v_1, v_5, v_8, v_10, []), v_1000482 => +v_1000478 = template_unbox(cps_provider_1_Plans, v_1000482); template_match_105(v_1000478)}

def template_body_cps_provider_1_layout_data(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> TemplateProgress<cps_provider_1_LayoutResult>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reenters{v_1, v_3, v_5, v_8, v_10}}, v_1000484 => +v_1000477 = template_unbox(Bool, v_1000484); template_match_106(v_1000477, v_3, v_1, v_5, v_8, v_10)}

def template_body_cps_provider_1_arms_tagged(+v_2: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_arms_tagged(v_2)}}

def template_match_107(+v_1000487: Bool, +v_1: cps_provider_1_Context, +v_3: String, v_16: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1000487:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reenters{v_1, v_3, v_16, v_8, v_10}}, v_1000489 => +v_1000488 = template_unbox(Bool, v_1000489); TemplateFinished{TemplateValue{v_1000488}}}

def template_match_108(+v_15: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_8: List<&2, cps_provider_3_NfVal>, +v_3: String, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  match v_15:
    case BIR.DescriptorArm{+v_19, +v_20}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_fields_reach{v_1, v_20, v_8, v_3, [], v_10}}, v_1000490 => +v_1000487 = template_unbox(Bool, v_1000490); template_match_107(v_1000487, v_1, v_3, v_16, v_8, v_10)}

def template_body_cps_provider_1_reenters(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_5:
    case []:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_args_reach{v_1, v_8, v_3, [], v_10}}, v_1004129 => +v_1004130 = template_unbox(Bool, v_1004129); TemplateFinished{TemplateValue{v_1004130}}}
    case +v_1004131 <> v_1004132:
      template_match_108(v_1004131, v_1, v_8, v_3, v_10, v_1004132)

def template_match_110(+v_1000495: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_27: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_1000495:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_fields_reach{v_1, v_18, v_27, v_8, v_11, v_13}}, v_1000497 => +v_1000496 = template_unbox(Bool, v_1000497); TemplateFinished{TemplateValue{v_1000496}}}

def template_match_111(v_1000492: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_27: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, +v_24: BIR.Descriptor, +v_6: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<Bool>:
  match v_1000492:
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_fields_reach{v_1, v_18, v_27, v_8, v_11, v_13}}, v_1000494 => +v_1000493 = template_unbox(Bool, v_1000494); TemplateFinished{TemplateValue{v_1000493}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reaches{v_1, v_24, v_6, v_8, v_11, v_13}}, v_1000498 => +v_1000495 = template_unbox(Bool, v_1000498); template_match_110(v_1000495, v_1, v_18, v_27, v_8, v_11, v_13)}

def template_continuation_112(+v_1000491: List<&2, cps_provider_3_NfVal>, +v_23: BIR.Quantity, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, +v_24: BIR.Descriptor, +v_6: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<Bool>:
  v_1000492 = {template_pure_cps_provider_1_live_field(v_23) : Bool}
  template_match_111(v_1000492, v_1, v_18, v_1000491, v_8, v_11, v_13, v_24, v_6)

def template_match_113(+v_17: BIR.DescriptorField, +v_6: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_17:
    case BIR.DescriptorField{+v_22, +v_23, +v_24}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_field_scope{v_6}}, False{}, v_1000500 => template_body_cps_provider_1_field_scope(v_6), v_1000499 => +v_1000491 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1000499); template_continuation_112(v_1000491, v_23, v_1, v_18, v_8, v_11, v_13, v_24, v_6)}

def template_body_cps_provider_1_fields_reach(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1004133 <> v_1004134:
      template_match_113(v_1004133, v_6, v_1, v_1004134, v_8, v_11, v_13)

def template_match_115(+v_1000502: cps_provider_3_Nf, +v_1: cps_provider_1_Context, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_1000502:
    case cps_provider_3_NfFail{+v_16}:
      TemplateFinished{TemplateValue{False{}}}
    case cps_provider_3_NfOk{+v_18}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reaches_val{v_1, v_18, v_7, v_10, Nat.sub(v_12, 1n)}}, v_1000504 => +v_1000503 = template_unbox(Bool, v_1000504); TemplateFinished{TemplateValue{v_1000503}}}

def template_match_116(v_1000501: Bool, +v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_12: Nat, +v_7: String, +v_10: List<&2, String>) -> TemplateProgress<Bool>:
  match v_1000501:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, v_5, v_12}}, False{}, v_1000506 => template_body_cps_provider_1_nf_of(v_1, v_2, v_5, v_12), v_1000505 => +v_1000502 = template_unbox(cps_provider_3_Nf, v_1000505); template_match_115(v_1000502, v_1, v_7, v_10, v_12)}

def template_body_cps_provider_1_reaches(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  v_1000501 = {Nat.is_eq(v_12, 0n) : Bool}
  template_match_116(v_1000501, v_1, v_2, v_5, v_12, v_7, v_10)

def template_match_117(+v_1000512: Bool, +v_1: cps_provider_1_Context, +v_15: List<&2, cps_provider_3_NfVal>, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1000512:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_args_reach{v_1, v_15, v_5, v_8, v_10}}, v_1000514 => +v_1000513 = template_unbox(Bool, v_1000514); TemplateFinished{TemplateValue{v_1000513}}}

def template_match_118(+v_1000509: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_15: List<&2, cps_provider_3_NfVal>, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String) -> TemplateProgress<Bool>:
  match v_1000509:
    case None{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_args_reach{v_1, v_15, v_5, v_8, v_10}}, v_1000511 => +v_1000510 = template_unbox(Bool, v_1000511); TemplateFinished{TemplateValue{v_1000510}}}
    case Some{+v_20}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_family_reach{v_1, v_20, v_15, v_5, v_14 <> v_8, v_10}}, v_1000515 => +v_1000512 = template_unbox(Bool, v_1000515); template_match_117(v_1000512, v_1, v_15, v_5, v_8, v_10)}

def template_match_119(+v_1000508: Bool, +v_1: cps_provider_1_Context, +v_14: String, +v_15: List<&2, cps_provider_3_NfVal>, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1000508:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_lookup{v_1, v_14}}, False{}, v_1000517 => template_body_cps_provider_1_family_lookup(v_1, v_14), v_1000516 => +v_1000509 = template_unbox(Maybe<&2, BIR.Family>, v_1000516); template_match_118(v_1000509, v_1, v_15, v_5, v_8, v_10, v_14)}

def template_match_120(v_1000507: Bool, +v_8: List<&2, String>, +v_14: String, +v_1: cps_provider_1_Context, +v_15: List<&2, cps_provider_3_NfVal>, +v_5: String, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_1000507:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_str_member{v_8, v_14}}, v_1000518 => +v_1000508 = template_unbox(Bool, v_1000518); template_match_119(v_1000508, v_1, v_14, v_15, v_5, v_8, v_10)}

def template_body_cps_provider_1_reaches_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> TemplateProgress<Bool>:
  match v_3:
    case cps_provider_3_NfType{+v_1004135, +v_1004136}:
      v_1004137 = {String.eq(v_1004135, v_5) : Bool}
      template_match_120(v_1004137, v_8, v_1004135, v_1, v_1004136, v_5, v_10)
    case v_1004138:
      TemplateFinished{TemplateValue{False{}}}

def template_match_122(v_1000520: Bool, +v_1: cps_provider_1_Context, +v_25: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_1000520:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reach_arms{v_1, v_25, v_5, v_7, v_10, v_12}}, v_1000522 => +v_1000521 = template_unbox(Bool, v_1000522); TemplateFinished{TemplateValue{v_1000521}}}

def template_match_123(+v_22: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_25: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_22:
    case Some{+v_28}:
      v_1000520 = {String.eq(v_28, "Array") : Bool}
      template_match_122(v_1000520, v_1, v_25, v_5, v_7, v_10, v_12)
    case None{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reach_arms{v_1, v_25, v_5, v_7, v_10, v_12}}, v_1000524 => +v_1000523 = template_unbox(Bool, v_1000524); TemplateFinished{TemplateValue{v_1000523}}}

def template_match_124(v_1000519: Bool, +v_22: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_25: List<&2, BIR.DescriptorArm>, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_1000519:
    case False{}:
      TemplateFinished{TemplateValue{False{}}}
    case True{}:
      template_match_123(v_22, v_1, v_25, v_5, v_7, v_10, v_12)

def template_body_cps_provider_1_family_reach(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> TemplateProgress<Bool>:
  match v_2:
    case BIR.Family{+v_1004139, +v_1004140, +v_1004141, +v_1004142, +v_1004143, +v_1004144}:
      v_1004145 = {Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_5), v_1004143) : Bool}
      template_match_124(v_1004145, v_1004141, v_1, v_1004144, v_5, v_7, v_10, v_12)

def template_match_126(+v_1000525: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_1000525:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reach_arms{v_1, v_18, v_6, v_8, v_11, v_13}}, v_1000527 => +v_1000526 = template_unbox(Bool, v_1000527); TemplateFinished{TemplateValue{v_1000526}}}

def template_match_127(+v_17: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Bool>:
  match v_17:
    case BIR.DescriptorArm{+v_21, +v_22}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_fields_reach{v_1, v_22, v_6, v_8, v_11, v_13}}, False{}, v_1000529 => template_body_cps_provider_1_fields_reach(v_1, v_22, v_6, v_8, v_11, v_13), v_1000528 => +v_1000525 = template_unbox(Bool, v_1000528); template_match_126(v_1000525, v_1, v_18, v_6, v_8, v_11, v_13)}

def template_body_cps_provider_1_reach_arms(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> TemplateProgress<Bool>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1004146 <> v_1004147:
      template_match_127(v_1004146, v_1, v_6, v_8, v_11, v_13, v_1004147)

def template_match_129(+v_1000530: Bool, +v_1: cps_provider_1_Context, v_16: List<&2, cps_provider_3_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> TemplateProgress<Bool>:
  match v_1000530:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_args_reach{v_1, v_16, v_6, v_9, v_11}}, v_1000532 => +v_1000531 = template_unbox(Bool, v_1000532); TemplateFinished{TemplateValue{v_1000531}}}

def template_body_cps_provider_1_args_reach(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> TemplateProgress<Bool>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1004148 <> v_1004149:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_reaches_val{v_1, v_1004148, v_6, v_9, v_11}}, False{}, v_1004150 => template_body_cps_provider_1_reaches_val(v_1, v_1004148, v_6, v_9, v_11), v_1004151 => +v_1004152 = template_unbox(Bool, v_1004151); template_match_129(v_1004152, v_1, v_1004149, v_6, v_9, v_11)}

def template_match_131(v_1000535: Bool, v_9: List<&2, String>, +v_4: String) -> TemplateProgress<Bool>:
  match v_1000535:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_str_member{v_9, v_4}}, v_1000537 => +v_1000536 = template_unbox(Bool, v_1000537); TemplateFinished{TemplateValue{v_1000536}}}

def template_body_cps_provider_1_str_member(+v_2: List<&2, String>, +v_4: String) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_8 <> v_9:
      v_1000535 = {String.eq(v_8, v_4) : Bool}
      template_match_131(v_1000535, v_9, v_4)

def template_body_cps_provider_1_layout_kinds(+v_1: cps_provider_1_Layout) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1:
    case cps_provider_1_LayoutWord{+v_5}:
      TemplateFinished{TemplateValue{[v_5]}}
    case cps_provider_1_LayoutBox{+v_7}:
      TemplateFinished{TemplateValue{[cps_provider_1_CWordBox{}]}}
    case cps_provider_1_LayoutData{+v_10, +v_11}:
      TemplateFinished{TemplateValue{v_10}}

def template_body_cps_provider_1_layout_words(+v_1: cps_provider_1_Layout) -> TemplateProgress<Nat>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_kinds{v_1}}, False{}, v_1000540 => template_body_cps_provider_1_layout_kinds(v_1), v_1000539 => +v_1000538 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000539); TemplateFinished{TemplateValue{List.length(&2, cps_provider_1_CWord, v_1000538)}}}

def template_body_cps_provider_1_canonical_word(+v_1: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_CWord>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_canonical_word(v_1)}}

def template_body_cps_provider_1_pack_arms(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Bool) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_4:
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_arm_list{v_2, 1n, [cps_provider_1_CWord32{}]}}, v_1004153 => +v_1004154 = template_unbox(List<&2, cps_provider_1_CWord>, v_1004153); TemplateFinished{TemplateValue{v_1004154}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_arm_list{v_2, 0n, []}}, v_1004155 => +v_1004156 = template_unbox(List<&2, cps_provider_1_CWord>, v_1004155); TemplateFinished{TemplateValue{v_1004156}}}

def template_match_135(+v_12: cps_provider_1_LayArm, v_13: List<&2, cps_provider_1_LayArm>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_12:
    case cps_provider_1_LayArm{+v_16, +v_17}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_field_list{v_17, v_4, v_7}}, v_1000550 => +v_1000547 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000550); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_arm_list{{v_13 : List<&2, cps_provider_1_LayArm>}, {v_4 : Nat}, v_1000547}}, v_1000549 => +v_1000548 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000549); TemplateFinished{TemplateValue{v_1000548}}}}

def template_body_cps_provider_1_pack_arm_list(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_7}}
    case +v_1004157 <> v_1004158:
      template_match_135(v_1004157, v_1004158, v_4, v_7)

def template_continuation_137(+v_1000551: List<&2, cps_provider_1_CWord>, v_13: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  +v_1000553 = {Nat.add(v_4, List.length(&2, cps_provider_1_CWord, v_1000551)) : Nat}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_kinds{v_1000551, v_4, v_7}}, v_1000557 => +v_1000554 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000557); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_field_list{{v_13 : List<&2, cps_provider_1_Layout>}, v_1000553, v_1000554}}, v_1000556 => +v_1000555 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000556); TemplateFinished{TemplateValue{v_1000555}}}}

def template_body_cps_provider_1_pack_field_list(+v_2: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_7}}
    case +v_1004159 <> v_1004160:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_kinds{v_1004159}}, False{}, v_1004161 => template_body_cps_provider_1_layout_kinds(v_1004159), v_1004162 => +v_1004163 = template_unbox(List<&2, cps_provider_1_CWord>, v_1004162); template_continuation_137(v_1004163, v_1004160, v_4, v_7)}

def template_body_cps_provider_1_pack_kinds(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_7}}
    case +v_1004164 <> v_1004165:
      +v_1004167 = {Nat.add(v_4, 1n) : Nat}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_set_kind{v_7, v_4, v_1004164}}, v_1004168 => +v_1004169 = template_unbox(List<&2, cps_provider_1_CWord>, v_1004168); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pack_kinds{{v_1004165 : List<&2, cps_provider_1_CWord>}, v_1004167, v_1004169}}, v_1004170 => +v_1004171 = template_unbox(List<&2, cps_provider_1_CWord>, v_1004170); TemplateFinished{TemplateValue{v_1004171}}}}

def template_body_cps_provider_1_set_kind(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_6: cps_provider_1_CWord) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2, v_4:
    case [], 0n:
      TemplateFinished{TemplateValue{[template_pure_cps_provider_1_merge_kind(cps_provider_1_CWord32{}, v_6)]}}
    case +v_12 <> v_13, 0n:
      TemplateFinished{TemplateValue{template_pure_cps_provider_1_merge_kind(v_12, v_6) <> v_13}}
    case [], 1n+v_16:
      v_1000566 = {cps_provider_1_CWord32{} : cps_provider_1_CWord}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_set_kind{[], v_16, v_6}}, v_1000568 => +v_1000567 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000568); TemplateFinished{TemplateValue{v_1000566 <> v_1000567}}}
    case +v_21 <> v_22, 1n+v_23:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_set_kind{v_22, v_23, v_6}}, v_1000571 => +v_1000570 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000571); TemplateFinished{TemplateValue{{v_21 : cps_provider_1_CWord} <> v_1000570}}}

def template_body_cps_provider_1_merge_kind(+v_1: cps_provider_1_CWord, +v_3: cps_provider_1_CWord) -> TemplateProgress<cps_provider_1_CWord>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_merge_kind(v_1, v_3)}}

def template_body_cps_provider_1_word_32(+v_1: cps_provider_1_CWord) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_word_32(v_1)}}

def template_match_141(v_1000574: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_10: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1000574:
    case True{}:
      TemplateFinished{TemplateValue{v_2}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pad_to{v_2, v_10}}, v_1000576 => +v_1000575 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000576); TemplateFinished{TemplateValue{v_1000575}}}

def template_continuation_142(+v_1000573: Nat, +v_7: Nat, +v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  v_1000574 = {Nat.is_eq(v_1000573, v_7) : Bool}
  template_match_141(v_1000574, v_2, v_1000573)

def template_match_143(v_1000572: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_7: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1000572:
    case False{}:
      TemplateFinished{TemplateValue{v_2}}
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pow2_upto{1n, v_7}}, v_1000577 => +v_1000573 = template_unbox(Nat, v_1000577); template_continuation_142(v_1000573, v_7, v_2)}

def template_body_cps_provider_1_pad_words(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  +v_7 = List.length(&2, cps_provider_1_CWord, v_2)
  v_1000572 = {Nat.is_gt(v_7, 247n) : Bool}
  template_match_143(v_1000572, v_2, v_7)

def template_match_144(v_1000578: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_1000578:
    case True{}:
      TemplateFinished{TemplateValue{v_2}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pad_to{List.append(&2, cps_provider_1_CWord, v_2, [cps_provider_1_CWord32{}]), v_4}}, v_1000580 => +v_1000579 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000580); TemplateFinished{TemplateValue{v_1000579}}}

def template_body_cps_provider_1_pad_to(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  v_1000578 = {Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_2), v_4) : Bool}
  template_match_144(v_1000578, v_2, v_4)

def template_match_145(v_1000581: Bool, +v_1: Nat, +v_3: Nat) -> TemplateProgress<Nat>:
  match v_1000581:
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pow2_upto{Nat.mul(v_1, 2n), v_3}}, v_1000583 => +v_1000582 = template_unbox(Nat, v_1000583); TemplateFinished{TemplateValue{v_1000582}}}
    case False{}:
      TemplateFinished{TemplateValue{v_1}}

def template_body_cps_provider_1_pow2_upto(+v_1: Nat, +v_3: Nat) -> TemplateProgress<Nat>:
  v_1000581 = {Nat.is_lt(v_1, v_3) : Bool}
  template_match_145(v_1000581, v_1, v_3)

def template_match_146(v_1000584: Bool, +v_1: Nat) -> TemplateProgress<Nat>:
  match v_1000584:
    case False{}:
      TemplateFinished{TemplateValue{0n}}
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_ceil_log2_go{1n, 0n, v_1}}, v_1000586 => +v_1000585 = template_unbox(Nat, v_1000586); TemplateFinished{TemplateValue{v_1000585}}}

def template_body_cps_provider_1_ceil_log2(+v_1: Nat) -> TemplateProgress<Nat>:
  v_1000584 = {Nat.is_gt(v_1, 1n) : Bool}
  template_match_146(v_1000584, v_1)

def template_match_147(v_1000588: Bool, +v_1: Nat, +v_3: Nat, +v_5: Nat) -> TemplateProgress<Nat>:
  match v_1000588:
    case True{}:
      TemplateFinished{TemplateValue{31n}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_ceil_log2_go{Nat.mul(v_1, 2n), Nat.add(v_3, 1n), v_5}}, v_1000590 => +v_1000589 = template_unbox(Nat, v_1000590); TemplateFinished{TemplateValue{v_1000589}}}

def template_match_148(v_1000587: Bool, +v_3: Nat, +v_1: Nat, +v_5: Nat) -> TemplateProgress<Nat>:
  match v_1000587:
    case True{}:
      v_1000588 = {Nat.is_gt(v_3, 30n) : Bool}
      template_match_147(v_1000588, v_1, v_3, v_5)
    case False{}:
      TemplateFinished{TemplateValue{v_3}}

def template_body_cps_provider_1_ceil_log2_go(+v_1: Nat, +v_3: Nat, +v_5: Nat) -> TemplateProgress<Nat>:
  v_1000587 = {Nat.is_lt(v_1, v_5) : Bool}
  template_match_148(v_1000587, v_3, v_1, v_5)

def template_body_cps_provider_1_node_layout(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1000597 => template_body_cps_provider_1_layout_fuel, v_1000596 => +v_1000593 = template_unbox(Nat, v_1000596); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_at{{v_1 : cps_provider_1_Context}, {v_3 : String}, v_1000593}}, v_1000595 => +v_1000594 = template_unbox(cps_provider_1_NodeResult, v_1000595); TemplateFinished{TemplateValue{v_1000594}}}}

def template_body_cps_provider_1_node_layout_fuel(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_at{v_1, v_3, v_5}}, v_1000599 => +v_1000598 = template_unbox(cps_provider_1_NodeResult, v_1000599); TemplateFinished{TemplateValue{v_1000598}}}

def template_match_149(v_1000602: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1000602:
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_plan_node{v_1, v_3}}, v_1000604 => +v_1000603 = template_unbox(cps_provider_1_NodeResult, v_1000604); TemplateFinished{TemplateValue{v_1000603}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_compute{v_1, v_3, v_5}}, v_1000606 => +v_1000605 = template_unbox(cps_provider_1_NodeResult, v_1000606); TemplateFinished{TemplateValue{v_1000605}}}

def template_continuation_150(v_1000600: Nat, +v_1000601: Nat, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  v_1000602 = {Nat.is_eq(v_1000600, v_1000601) : Bool}
  template_match_149(v_1000602, v_1, v_3, v_5)

def template_body_cps_provider_1_node_at(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1000608 => template_body_cps_provider_1_layout_fuel, v_1000607 => +v_1000601 = template_unbox(Nat, v_1000607); template_continuation_150({v_5 : Nat}, v_1000601, v_1, v_3, v_5)}

def template_match_151(v_1000610: Maybe<&2, cps_provider_1_NodeResult>, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1000610:
    case Some{+v_8}:
      TemplateFinished{TemplateValue{v_8}}
    case None{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_declared{v_1, v_3}}, v_1000612 => +v_1000611 = template_unbox(cps_provider_1_NodeResult, v_1000612); TemplateFinished{TemplateValue{v_1000611}}}

def template_continuation_152(+v_1000609: Map<&2, cps_provider_1_NodeResult>, +v_3: String, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_NodeResult>:
  v_1000610 = {IndexLookup.find(cps_provider_1_NodeResult, v_1000609, v_3) : Maybe<&2, cps_provider_1_NodeResult>}
  template_match_151(v_1000610, v_1, v_3)

def template_body_cps_provider_1_plan_node(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_context_nodes{v_1}}, False{}, v_1000614 => template_body_cps_provider_1_context_nodes(v_1), v_1000613 => +v_1000609 = template_unbox(Map<&2, cps_provider_1_NodeResult>, v_1000613); template_continuation_152(v_1000609, v_3, v_1)}

def template_match_153(+v_1000615: Maybe<&2, BIR.DescriptorArm>, +v_3: String, +v_1: cps_provider_1_Context, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1000615:
    case None{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_unresolved_message{v_3}}, v_1000617 => +v_1000616 = template_unbox(String, v_1000617); TemplateFinished{TemplateValue{cps_provider_1_NodeFailed{v_1000616}}}}
    case Some{+v_11}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_arm{v_1, v_11, v_5}}, v_1000619 => +v_1000618 = template_unbox(cps_provider_1_NodeResult, v_1000619); TemplateFinished{TemplateValue{v_1000618}}}

def template_body_cps_provider_1_node_compute(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_of{v_3, template_pure_cps_provider_1_context_families(v_1)}}, False{}, v_1000621 => template_body_cps_provider_1_arm_of(v_3, template_pure_cps_provider_1_context_families(v_1)), v_1000620 => +v_1000615 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1000620); template_match_153(v_1000615, v_3, v_1, v_5)}

def template_body_cps_provider_1_unresolved_message(+v_1: String) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{String.append("the constructor `", String.append(v_1, "` is in no declared family arm"))}}

def template_match_154(+v_1000622: cps_provider_1_Slots) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1000622:
    case cps_provider_1_SlotsFail{+v_12}:
      TemplateFinished{TemplateValue{cps_provider_1_NodeFailed{v_12}}}
    case cps_provider_1_SlotsOk{+v_14}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_finish{v_14}}, v_1000624 => +v_1000623 = template_unbox(cps_provider_1_NodeResult, v_1000624); TemplateFinished{TemplateValue{v_1000623}}}

def template_body_cps_provider_1_node_arm(+v_1: cps_provider_1_Context, +v_2: BIR.DescriptorArm, +v_4: Nat) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_2:
    case BIR.DescriptorArm{+v_1004172, +v_1004173}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slots{v_1, v_1004173, 0, 0n, v_4, []}}, v_1004174 => +v_1004175 = template_unbox(cps_provider_1_Slots, v_1004174); template_match_154(v_1004175)}

def template_continuation_156(+v_16: String, +v_1: cps_provider_1_Context, +v_1000626: Map<&2, cps_provider_1_NodeResult>) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_declared{v_1, v_16}}, v_1000629 => +v_1000628 = template_unbox(cps_provider_1_NodeResult, v_1000629); TemplateFinished{TemplateValue{Map.set(&2, cps_provider_1_NodeResult, v_1000626, {v_16 : String}, v_1000628)}}}

def template_match_157(+v_9: BIR.ConstructorLayout, +v_1: cps_provider_1_Context, v_10: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  match v_9:
    case BIR.ConstructorLayout{+v_15, +v_16, +v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_plan_node_index{v_1, v_10}}, v_1000630 => +v_1000626 = template_unbox(Map<&2, cps_provider_1_NodeResult>, v_1000630); template_continuation_156(v_16, v_1, v_1000626)}

def template_body_cps_provider_1_plan_node_index(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Map<&2, cps_provider_1_NodeResult>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, cps_provider_1_NodeResult)}}
    case +v_1004176 <> v_1004177:
      template_match_157(v_1004176, v_1, v_1004177)

def template_match_159(+v_1000631: Maybe<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_1000631:
    case Some{+v_7}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1000637 => template_body_cps_provider_1_layout_fuel, v_1000636 => +v_1000634 = template_unbox(Nat, v_1000636); template_body_cps_provider_1_node_arm({v_1 : cps_provider_1_Context}, {v_7 : BIR.DescriptorArm}, v_1000634)}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_unresolved_message{v_3}}, False{}, v_1000640 => template_body_cps_provider_1_unresolved_message(v_3), v_1000639 => +v_1000638 = template_unbox(String, v_1000639); TemplateFinished{TemplateValue{cps_provider_1_NodeFailed{v_1000638}}}}

def template_body_cps_provider_1_node_declared(+v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_declared{v_1, v_3}}, False{}, v_1000642 => template_body_cps_provider_1_arm_declared(v_1, v_3), v_1000641 => +v_1000631 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1000641); template_match_159(v_1000631, v_1, v_3)}

def template_match_160(+v_1000646: cps_provider_1_LayoutResult, +v_5: U32, +v_7: Nat, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_Slots>:
  match v_1000646:
    case cps_provider_1_LayoutFailed{+v_29}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotsFail{v_29}}}
    case cps_provider_1_LayoutFound{+v_31}:
      +v_34 = {cps_provider_1_NodeSlot{v_5, v_7, v_31} : cps_provider_1_NodeSlot}
      +v_1000649 = {U32.inc(v_5) : U32}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_31}}, False{}, v_1000655 => template_body_cps_provider_1_layout_words(v_31), v_1000654 => +v_1000651 = template_unbox(Nat, v_1000654); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slots{{v_1 : cps_provider_1_Context}, {v_18 : List<&2, BIR.DescriptorField>}, v_1000649, Nat.add({v_7 : Nat}, v_1000651), v_9, v_34 <> v_12}}, v_1000653 => +v_1000652 = template_unbox(cps_provider_1_Slots, v_1000653); TemplateFinished{TemplateValue{v_1000652}}}}

def template_match_161(v_1000643: Bool, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>, +v_24: BIR.Descriptor) -> TemplateProgress<cps_provider_1_Slots>:
  match v_1000643:
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slots{v_1, v_18, U32.inc(v_5), v_7, v_9, v_12}}, v_1000645 => +v_1000644 = template_unbox(cps_provider_1_Slots, v_1000645); TemplateFinished{TemplateValue{v_1000644}}}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_of_desc{v_1, v_24, [], v_9}}, False{}, v_1000657 => template_body_cps_provider_1_layout_of_desc(v_1, v_24, [], v_9), v_1000656 => +v_1000646 = template_unbox(cps_provider_1_LayoutResult, v_1000656); template_match_160(v_1000646, v_5, v_7, v_1, v_18, v_9, v_12)}

def template_match_162(+v_17: BIR.DescriptorField, +v_1: cps_provider_1_Context, v_18: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_Slots>:
  match v_17:
    case BIR.DescriptorField{+v_22, +v_23, +v_24}:
      v_1000643 = {template_pure_cps_provider_1_live_field(v_23) : Bool}
      template_match_161(v_1000643, v_1, v_18, v_5, v_7, v_9, v_12, v_24)

def template_body_cps_provider_1_node_slots(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_Slots>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_SlotsOk{List.reverse(&2, cps_provider_1_NodeSlot, v_12)}}}
    case +v_1004178 <> v_1004179:
      template_match_162(v_1004178, v_1, v_1004179, v_5, v_7, v_9, v_12)

def template_continuation_164(+v_1000659: List<&2, cps_provider_1_CWord>, +v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_NodeResult>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_packed_words{v_1000659}}, v_1000663 => +v_1000662 = template_unbox(Bool, v_1000663); TemplateFinished{TemplateValue{cps_provider_1_NodeFound{cps_provider_1_Node{{v_1000659 : List<&2, cps_provider_1_CWord>}, {v_2 : List<&2, cps_provider_1_NodeSlot>}, v_1000662}}}}}

def template_body_cps_provider_1_node_finish(+v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_NodeResult>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_NodeFound{cps_provider_1_Node{[], [], True{}}}}}
    case _:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_slot_words{v_2}}, v_1000666 => +v_1000658 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000666); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_pad_words{v_1000658}}, False{}, v_1000665 => template_body_cps_provider_1_pad_words(v_1000658), v_1000664 => +v_1000659 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000664); template_continuation_164(v_1000659, v_2)}}

def template_match_166(+v_7: cps_provider_1_NodeSlot, v_8: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_7:
    case cps_provider_1_NodeSlot{+v_12, +v_13, +v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_kinds{v_14}}, False{}, v_1000671 => template_body_cps_provider_1_layout_kinds(v_14), v_1000670 => +v_1000667 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000670); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_slot_words{v_8}}, v_1000669 => +v_1000668 = template_unbox(List<&2, cps_provider_1_CWord>, v_1000669); TemplateFinished{TemplateValue{List.append(&2, cps_provider_1_CWord, v_1000667, v_1000668)}}}}

def template_body_cps_provider_1_slot_words(+v_2: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<List<&2, cps_provider_1_CWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_7 <> v_8:
      template_match_166(v_7, v_8)

def template_match_168(v_7: List<&2, cps_provider_1_CWord>, +v_6: cps_provider_1_CWord) -> TemplateProgress<Bool>:
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
      template_match_168(v_7, v_6)

def template_match_170(+v_1000673: Maybe<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_1_SlotResult>:
  match v_1000673:
    case Some{+v_20}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotFound{v_20}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotErased{}}}

def template_match_171(+v_11: cps_provider_1_Node, +v_5: U32) -> TemplateProgress<cps_provider_1_SlotResult>:
  match v_11:
    case cps_provider_1_Node{+v_15, +v_16, +v_17}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_slot_find{v_16, v_5}}, v_1000674 => +v_1000673 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1000674); template_match_170(v_1000673)}

def template_match_172(+v_1000672: cps_provider_1_NodeResult, +v_5: U32) -> TemplateProgress<cps_provider_1_SlotResult>:
  match v_1000672:
    case cps_provider_1_NodeFailed{+v_9}:
      TemplateFinished{TemplateValue{cps_provider_1_SlotFailed{v_9}}}
    case cps_provider_1_NodeFound{+v_11}:
      template_match_171(v_11, v_5)

def template_body_cps_provider_1_node_slot(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> TemplateProgress<cps_provider_1_SlotResult>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_layout{v_1, v_3}}, False{}, v_1000676 => template_body_cps_provider_1_node_layout(v_1, v_3), v_1000675 => +v_1000672 = template_unbox(cps_provider_1_NodeResult, v_1000675); template_match_172(v_1000672, v_5)}

def template_match_173(v_1000677: Bool, +v_9: cps_provider_1_NodeSlot, v_10: List<&2, cps_provider_1_NodeSlot>, +v_4: U32) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_1000677:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_9}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_slot_find{v_10, v_4}}, v_1000679 => +v_1000678 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1000679); TemplateFinished{TemplateValue{v_1000678}}}

def template_match_174(+v_9: cps_provider_1_NodeSlot, +v_4: U32, v_10: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_9:
    case cps_provider_1_NodeSlot{+v_14, +v_15, +v_16}:
      v_1000677 = {U32.is_eq(v_4, v_14) : Bool}
      template_match_173(v_1000677, v_9, v_10, v_4)

def template_body_cps_provider_1_slot_find(+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: U32) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_9 <> v_10:
      template_match_174(v_9, v_4, v_10)

def template_body_cps_provider_1_layout_fill(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_FillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1000686 => template_body_cps_provider_1_layout_fuel, v_1000685 => +v_1000682 = template_unbox(Nat, v_1000685); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_fill_fuel{{v_1 : cps_provider_1_Context}, {v_3 : cps_provider_1_Layout}, v_1000682}}, v_1000684 => +v_1000683 = template_unbox(cps_provider_1_FillResult, v_1000684); TemplateFinished{TemplateValue{v_1000683}}}}

def template_match_176(+v_1000687: cps_provider_1_Arms, +v_13: List<&2, cps_provider_1_CWord>) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_1000687:
    case cps_provider_1_ArmsFail{+v_19}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFailed{v_19}}}
    case cps_provider_1_ArmsOk{+v_21}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFound{cps_provider_1_FillForm{List.length(&2, cps_provider_1_CWord, v_13), v_21}}}}

def template_body_cps_provider_1_layout_fill_fuel(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_3:
    case cps_provider_1_LayoutWord{+v_1004180}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFound{cps_provider_1_FillWord{}}}}
    case cps_provider_1_LayoutBox{+v_1004181}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFound{cps_provider_1_FillWord{}}}}
    case cps_provider_1_LayoutData{+v_1004182, +v_1004183}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_form_arms{v_1, v_1004183, 0n, Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_1004183), 1n), List.length(&2, cps_provider_1_CWord, v_1004182), v_5, [], True{}}}, v_1004184 => +v_1004185 = template_unbox(cps_provider_1_Arms, v_1004184); template_match_176(v_1004185, v_1004182)}

def template_body_cps_provider_1_layout_unfill(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_UnfillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_layout_fuel{}}, False{}, v_1000695 => template_body_cps_provider_1_layout_fuel, v_1000694 => +v_1000691 = template_unbox(Nat, v_1000694); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_unfill_fuel{{v_1 : cps_provider_1_Context}, {v_3 : cps_provider_1_Layout}, v_1000691}}, v_1000693 => +v_1000692 = template_unbox(cps_provider_1_UnfillResult, v_1000693); TemplateFinished{TemplateValue{v_1000692}}}}

def template_match_178(+v_1000696: cps_provider_1_Arms, +v_13: List<&2, cps_provider_1_CWord>) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_1000696:
    case cps_provider_1_ArmsFail{+v_19}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFailed{v_19}}}
    case cps_provider_1_ArmsOk{+v_21}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFound{cps_provider_1_UnfillForm{List.length(&2, cps_provider_1_CWord, v_13), v_21}}}}

def template_body_cps_provider_1_layout_unfill_fuel(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_3:
    case cps_provider_1_LayoutWord{+v_1004186}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFound{cps_provider_1_UnfillWord{}}}}
    case cps_provider_1_LayoutBox{+v_1004187}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFound{cps_provider_1_UnfillWord{}}}}
    case cps_provider_1_LayoutData{+v_1004188, +v_1004189}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_form_arms{v_1, v_1004189, 0n, Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_1004189), 1n), List.length(&2, cps_provider_1_CWord, v_1004188), v_5, [], False{}}}, v_1004190 => +v_1004191 = template_unbox(cps_provider_1_Arms, v_1004190); template_match_178(v_1004191, v_1004188)}

def template_match_180(+v_9: cps_provider_1_NodeSlot, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_9:
    case cps_provider_1_NodeSlot{+v_13, +v_14, +v_15}:
      template_body_cps_provider_1_layout_fill(v_1, v_15)

def template_match_181(+v_1000698: cps_provider_1_SlotResult, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_FillResult>:
  match v_1000698:
    case cps_provider_1_SlotFound{+v_9}:
      template_match_180(v_9, v_1)
    case cps_provider_1_SlotErased{}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFailed{String.append("the constructor `", String.append(v_3, "` field slot is erased and has no storage"))}}}
    case cps_provider_1_SlotFailed{+v_18}:
      TemplateFinished{TemplateValue{cps_provider_1_FillFailed{v_18}}}

def template_body_cps_provider_1_slot_fill(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> TemplateProgress<cps_provider_1_FillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slot{v_1, v_3, v_5}}, False{}, v_1000701 => template_body_cps_provider_1_node_slot(v_1, v_3, v_5), v_1000700 => +v_1000698 = template_unbox(cps_provider_1_SlotResult, v_1000700); template_match_181(v_1000698, v_1, v_3)}

def template_match_182(+v_9: cps_provider_1_NodeSlot, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_9:
    case cps_provider_1_NodeSlot{+v_13, +v_14, +v_15}:
      template_body_cps_provider_1_layout_unfill(v_1, v_15)

def template_match_183(+v_1000702: cps_provider_1_SlotResult, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_UnfillResult>:
  match v_1000702:
    case cps_provider_1_SlotFound{+v_9}:
      template_match_182(v_9, v_1)
    case cps_provider_1_SlotErased{}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFailed{String.append("the constructor `", String.append(v_3, "` field slot is erased and has no storage"))}}}
    case cps_provider_1_SlotFailed{+v_18}:
      TemplateFinished{TemplateValue{cps_provider_1_UnfillFailed{v_18}}}

def template_body_cps_provider_1_slot_unfill(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> TemplateProgress<cps_provider_1_UnfillResult>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slot{v_1, v_3, v_5}}, False{}, v_1000705 => template_body_cps_provider_1_node_slot(v_1, v_3, v_5), v_1000704 => +v_1000702 = template_unbox(cps_provider_1_SlotResult, v_1000704); template_match_183(v_1000702, v_1, v_3)}

def template_match_184(+v_1000706: cps_provider_1_FormArmResult, +v_1: cps_provider_1_Context, v_23: List<&2, cps_provider_1_LayArm>, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool) -> TemplateProgress<cps_provider_1_Arms>:
  match v_1000706:
    case cps_provider_1_FormArmFail{+v_30}:
      TemplateFinished{TemplateValue{cps_provider_1_ArmsFail{v_30}}}
    case cps_provider_1_FormArmOk{+v_32}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_form_arms{v_1, v_23, Nat.add(v_6, 1n), v_8, v_10, v_12, v_32 <> v_15, v_17}}, v_1000708 => +v_1000707 = template_unbox(cps_provider_1_Arms, v_1000708); TemplateFinished{TemplateValue{v_1000707}}}

def template_match_185(+v_22: cps_provider_1_LayArm, +v_1: cps_provider_1_Context, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_17: Bool, v_23: List<&2, cps_provider_1_LayArm>, +v_15: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<cps_provider_1_Arms>:
  match v_22:
    case cps_provider_1_LayArm{+v_26, +v_27}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_form_arm{v_1, v_26, v_6, v_8, v_10, v_27, v_12, v_17}}, v_1000709 => +v_1000706 = template_unbox(cps_provider_1_FormArmResult, v_1000709); template_match_184(v_1000706, v_1, v_23, v_6, v_8, v_10, v_12, v_15, v_17)}

def template_body_cps_provider_1_form_arms(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_LayArm>, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool) -> TemplateProgress<cps_provider_1_Arms>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_ArmsOk{List.reverse(&2, cps_provider_1_FormArm, v_15)}}}
    case +v_1004192 <> v_1004193:
      template_match_185(v_1004192, v_1, v_6, v_8, v_10, v_12, v_17, v_1004193, v_15)

def template_match_187(+v_1000712: cps_provider_1_Nests, +v_3: String, +v_5: Nat, +v_28: Bool, +v_26: List<&2, cps_provider_1_CWord>) -> TemplateProgress<cps_provider_1_FormArmResult>:
  match v_1000712:
    case cps_provider_1_NestsFail{+v_35}:
      TemplateFinished{TemplateValue{cps_provider_1_FormArmFail{v_35}}}
    case cps_provider_1_NestsOk{+v_37}:
      TemplateFinished{TemplateValue{cps_provider_1_FormArmOk{cps_provider_1_FormArm{v_3, v_5, v_28, List.length(&2, cps_provider_1_CWord, v_26), v_37}}}}

def template_continuation_188(+v_1000711: Nat, +v_1: cps_provider_1_Context, +v_12: List<&2, cps_provider_1_Layout>, +v_27: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_26: List<&2, cps_provider_1_CWord>, +v_14: Nat, +v_16: Bool, +v_3: String, +v_5: Nat, +v_28: Bool) -> TemplateProgress<cps_provider_1_FormArmResult>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_form_nests{v_1, v_12, v_27, v_1000711, v_9, List.length(&2, cps_provider_1_CWord, v_26), v_14, [], v_16}}, v_1000713 => +v_1000712 = template_unbox(cps_provider_1_Nests, v_1000713); template_match_187(v_1000712, v_3, v_5, v_28, v_26)}

def template_match_189(+v_22: cps_provider_1_Node, +v_7: Bool, +v_1: cps_provider_1_Context, +v_12: List<&2, cps_provider_1_Layout>, +v_9: Nat, +v_14: Nat, +v_16: Bool, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_FormArmResult>:
  match v_22:
    case cps_provider_1_Node{+v_26, +v_27, +v_28}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_tag_word{v_7}}, v_1000714 => +v_1000711 = template_unbox(Nat, v_1000714); template_continuation_188(v_1000711, v_1, v_12, v_27, v_9, v_26, v_14, v_16, v_3, v_5, v_28)}

def template_match_190(+v_1000710: cps_provider_1_NodeResult, +v_7: Bool, +v_1: cps_provider_1_Context, +v_12: List<&2, cps_provider_1_Layout>, +v_9: Nat, +v_14: Nat, +v_16: Bool, +v_3: String, +v_5: Nat) -> TemplateProgress<cps_provider_1_FormArmResult>:
  match v_1000710:
    case cps_provider_1_NodeFailed{+v_20}:
      TemplateFinished{TemplateValue{cps_provider_1_FormArmFail{v_20}}}
    case cps_provider_1_NodeFound{+v_22}:
      template_match_189(v_22, v_7, v_1, v_12, v_9, v_14, v_16, v_3, v_5)

def template_body_cps_provider_1_form_arm(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_7: Bool, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: Nat, +v_16: Bool) -> TemplateProgress<cps_provider_1_FormArmResult>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_layout_fuel{v_1, v_3, v_14}}, False{}, v_1000716 => template_body_cps_provider_1_node_layout_fuel(v_1, v_3, v_14), v_1000715 => +v_1000710 = template_unbox(cps_provider_1_NodeResult, v_1000715); template_match_190(v_1000710, v_7, v_1, v_12, v_9, v_14, v_16, v_3, v_5)}

def template_body_cps_provider_1_tag_word(+v_1: Bool) -> TemplateProgress<Nat>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{1n}}
    case False{}:
      TemplateFinished{TemplateValue{0n}}

def template_continuation_192(+v_11: Nat, +v_13: Nat, +v_15: Nat, +v_9: Nat, +v_35: Nat, +v_41: cps_provider_1_Unfill, +v_46: cps_provider_1_Fill, +v_1000720: cps_provider_1_Context, +v_1000721: List<&2, cps_provider_1_Layout>, +v_1000722: List<&2, cps_provider_1_NodeSlot>, v_1000723: Nat, +v_1000724: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nest{v_9, v_35, v_41, v_46}}, v_1000731 => +v_1000728 = template_unbox(cps_provider_1_Nest, v_1000731); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_form_nests{v_1000720, v_1000721, v_1000722, Nat.add(v_1000723, v_1000724), {v_11 : Nat}, {v_13 : Nat}, {v_15 : Nat}, v_1000728 <> v_18, v_20}}, v_1000730 => +v_1000729 = template_unbox(cps_provider_1_Nests, v_1000730); TemplateFinished{TemplateValue{v_1000729}}}}

def template_match_193(+v_1000719: Bool, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_46: cps_provider_1_Fill, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_35: Nat, +v_41: cps_provider_1_Unfill, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1000719:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{"the constructor node does not fit its value layout"}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_fill_words{v_46}}, v_1000732 => +v_1000724 = template_unbox(Nat, v_1000732); template_continuation_192(v_11, v_13, v_15, v_9, v_35, v_41, v_46, {v_1 : cps_provider_1_Context}, {v_28 : List<&2, cps_provider_1_Layout>}, {v_30 : List<&2, cps_provider_1_NodeSlot>}, {v_9 : Nat}, v_1000724, v_18, v_20)}

def template_match_194(+v_1000718: cps_provider_1_FillResult, +v_9: Nat, +v_11: Nat, +v_35: Nat, +v_13: Nat, +v_41: cps_provider_1_Unfill, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1000718:
    case cps_provider_1_FillFailed{+v_44}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_44}}}
    case cps_provider_1_FillFound{+v_46}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nest_fits{v_9, v_11, v_35, v_13, v_41, v_46}}, v_1000733 => +v_1000719 = template_unbox(Bool, v_1000733); template_match_193(v_1000719, v_1, v_28, v_30, v_9, v_46, v_11, v_13, v_15, v_35, v_41, v_18, v_20)}

def template_match_195(+v_1000717: cps_provider_1_UnfillResult, +v_1: cps_provider_1_Context, +v_27: cps_provider_1_Layout, +v_15: Nat, +v_9: Nat, +v_11: Nat, +v_35: Nat, +v_13: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1000717:
    case cps_provider_1_UnfillFailed{+v_39}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_39}}}
    case cps_provider_1_UnfillFound{+v_41}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_fill_fuel{v_1, v_27, v_15}}, False{}, v_1000735 => template_body_cps_provider_1_layout_fill_fuel(v_1, v_27, v_15), v_1000734 => +v_1000718 = template_unbox(cps_provider_1_FillResult, v_1000734); template_match_194(v_1000718, v_9, v_11, v_35, v_13, v_41, v_1, v_28, v_30, v_15, v_18, v_20)}

def template_continuation_196(+v_11: Nat, +v_13: Nat, +v_15: Nat, +v_35: Nat, +v_9: Nat, +v_56: cps_provider_1_Unfill, +v_61: cps_provider_1_Fill, +v_1000741: cps_provider_1_Context, +v_1000742: List<&2, cps_provider_1_Layout>, +v_1000743: List<&2, cps_provider_1_NodeSlot>, v_1000744: Nat, +v_1000745: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nest{v_35, v_9, v_56, v_61}}, v_1000752 => +v_1000749 = template_unbox(cps_provider_1_Nest, v_1000752); TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_form_nests{v_1000741, v_1000742, v_1000743, Nat.add(v_1000744, v_1000745), {v_11 : Nat}, {v_13 : Nat}, {v_15 : Nat}, v_1000749 <> v_18, v_20}}, v_1000751 => +v_1000750 = template_unbox(cps_provider_1_Nests, v_1000751); TemplateFinished{TemplateValue{v_1000750}}}}

def template_match_197(+v_1000740: Bool, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_56: cps_provider_1_Unfill, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_35: Nat, +v_61: cps_provider_1_Fill, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1000740:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{"the constructor node does not fit its value layout"}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_unfill_words{v_56}}, v_1000753 => +v_1000745 = template_unbox(Nat, v_1000753); template_continuation_196(v_11, v_13, v_15, v_35, v_9, v_56, v_61, {v_1 : cps_provider_1_Context}, {v_28 : List<&2, cps_provider_1_Layout>}, {v_30 : List<&2, cps_provider_1_NodeSlot>}, {v_9 : Nat}, v_1000745, v_18, v_20)}

def template_match_198(+v_1000739: cps_provider_1_FillResult, +v_35: Nat, +v_13: Nat, +v_9: Nat, +v_11: Nat, +v_56: cps_provider_1_Unfill, +v_1: cps_provider_1_Context, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1000739:
    case cps_provider_1_FillFailed{+v_59}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_59}}}
    case cps_provider_1_FillFound{+v_61}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_nest_fits{v_35, v_13, v_9, v_11, v_56, v_61}}, v_1000754 => +v_1000740 = template_unbox(Bool, v_1000754); template_match_197(v_1000740, v_1, v_28, v_30, v_9, v_56, v_11, v_13, v_15, v_35, v_61, v_18, v_20)}

def template_match_199(+v_1000738: cps_provider_1_UnfillResult, +v_1: cps_provider_1_Context, +v_36: cps_provider_1_Layout, +v_15: Nat, +v_35: Nat, +v_13: Nat, +v_9: Nat, +v_11: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_1000738:
    case cps_provider_1_UnfillFailed{+v_54}:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{v_54}}}
    case cps_provider_1_UnfillFound{+v_56}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_fill_fuel{v_1, v_36, v_15}}, False{}, v_1000756 => template_body_cps_provider_1_layout_fill_fuel(v_1, v_36, v_15), v_1000755 => +v_1000739 = template_unbox(cps_provider_1_FillResult, v_1000755); template_match_198(v_1000739, v_35, v_13, v_9, v_11, v_56, v_1, v_28, v_30, v_15, v_18, v_20)}

def template_match_200(+v_20: Bool, +v_1: cps_provider_1_Context, +v_36: cps_provider_1_Layout, +v_15: Nat, +v_27: cps_provider_1_Layout, +v_9: Nat, +v_11: Nat, +v_35: Nat, +v_13: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>) -> TemplateProgress<cps_provider_1_Nests>:
  match v_20:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_unfill_fuel{v_1, v_36, v_15}}, False{}, v_1000737 => template_body_cps_provider_1_layout_unfill_fuel(v_1, v_36, v_15), v_1000736 => +v_1000717 = template_unbox(cps_provider_1_UnfillResult, v_1000736); template_match_195(v_1000717, v_1, v_27, v_15, v_9, v_11, v_35, v_13, v_28, v_30, v_18, v_20)}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_unfill_fuel{v_1, v_27, v_15}}, False{}, v_1000758 => template_body_cps_provider_1_layout_unfill_fuel(v_1, v_27, v_15), v_1000757 => +v_1000738 = template_unbox(cps_provider_1_UnfillResult, v_1000757); template_match_199(v_1000738, v_1, v_36, v_15, v_35, v_13, v_9, v_11, v_28, v_30, v_18, v_20)}

def template_match_201(+v_29: cps_provider_1_NodeSlot, +v_20: Bool, +v_1: cps_provider_1_Context, +v_15: Nat, +v_27: cps_provider_1_Layout, +v_9: Nat, +v_11: Nat, +v_13: Nat, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_18: List<&2, cps_provider_1_Nest>) -> TemplateProgress<cps_provider_1_Nests>:
  match v_29:
    case cps_provider_1_NodeSlot{+v_34, +v_35, +v_36}:
      template_match_200(v_20, v_1, v_36, v_15, v_27, v_9, v_11, v_35, v_13, v_28, v_30, v_18)

def template_body_cps_provider_1_form_nests(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_Layout>, +v_7: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> TemplateProgress<cps_provider_1_Nests>:
  match v_4, v_7:
    case [], []:
      TemplateFinished{TemplateValue{cps_provider_1_NestsOk{List.reverse(&2, cps_provider_1_Nest, v_18)}}}
    case +v_1004194 <> v_1004195, +v_1004196 <> v_1004197:
      template_match_201(v_1004196, v_20, v_1, v_15, v_1004194, v_9, v_11, v_13, v_1004195, v_1004197, v_18)
    case v_1004198, v_1004199:
      TemplateFinished{TemplateValue{cps_provider_1_NestsFail{"a constructor node and its value layout disagree on the live field count"}}}

def template_body_cps_provider_1_nest(+v_1: Nat, +v_3: Nat, +v_5: cps_provider_1_Unfill, +v_7: cps_provider_1_Fill) -> TemplateProgress<cps_provider_1_Nest>:
  TemplateFinished{TemplateValue{cps_provider_1_Nest{v_1, v_3, v_5, v_7}}}

def template_match_203(v_1000764: Bool) -> TemplateProgress<Bool>:
  match v_1000764:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplateFinished{TemplateValue{True{}}}

def template_continuation_204(v_1000762: Nat, +v_1000763: Nat, +v_7: Nat) -> TemplateProgress<Bool>:
  v_1000764 = {Nat.is_gt(Nat.add(v_1000762, v_1000763), v_7) : Bool}
  template_match_203(v_1000764)

def template_match_205(v_1000761: Bool, +v_5: Nat, +v_9: cps_provider_1_Unfill, +v_7: Nat) -> TemplateProgress<Bool>:
  match v_1000761:
    case True{}:
      TemplateFinished{TemplateValue{False{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_unfill_words{v_9}}, v_1000765 => +v_1000763 = template_unbox(Nat, v_1000765); template_continuation_204({v_5 : Nat}, v_1000763, v_7)}

def template_continuation_206(v_1000759: Nat, +v_1000760: Nat, +v_3: Nat, +v_5: Nat, +v_9: cps_provider_1_Unfill, +v_7: Nat) -> TemplateProgress<Bool>:
  v_1000761 = {Nat.is_gt(Nat.add(v_1000759, v_1000760), v_3) : Bool}
  template_match_205(v_1000761, v_5, v_9, v_7)

def template_body_cps_provider_1_nest_fits(+v_1: Nat, +v_3: Nat, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_1_Unfill, +v_11: cps_provider_1_Fill) -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_fill_words{v_11}}, v_1000766 => +v_1000760 = template_unbox(Nat, v_1000766); template_continuation_206({v_1 : Nat}, v_1000760, v_3, v_5, v_9, v_7)}

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

def template_match_209(+v_1000767: cps_provider_3_Nf, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1000767:
    case cps_provider_3_NfFail{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadFailed{v_6}}}
    case cps_provider_3_NfOk{+v_8}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_head_value{v_1, v_8}}, v_1000769 => +v_1000768 = template_unbox(cps_provider_1_HeadResult, v_1000769); TemplateFinished{TemplateValue{v_1000768}}}

def template_body_cps_provider_1_head_native(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_HeadResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, [], 1024n}}, False{}, v_1000771 => template_body_cps_provider_1_nf_of(v_1, v_2, [], 1024n), v_1000770 => +v_1000767 = template_unbox(cps_provider_3_Nf, v_1000770); template_match_209(v_1000767, v_1)}

def template_body_cps_provider_1_head_other(+v_0: BIR.Descriptor) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_0:
    case BIR.DescriptorEquality{_, _, _}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadEquality{}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_211(v_1000773: Bool, +v_7: String, +v_20: Maybe<&2, String>) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1000773:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadFound{v_7, v_20}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_212(+v_11: BIR.Family, +v_8: List<&2, cps_provider_3_NfVal>, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_11:
    case BIR.Family{+v_18, +v_19, +v_20, +v_21, +v_22, +v_23}:
      v_1000773 = {Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_8), v_22) : Bool}
      template_match_211(v_1000773, v_7, v_20)

def template_match_213(v_1000775: Bool, +v_7: String, +v_34: Maybe<&2, String>) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1000775:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadFound{v_7, v_34}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_214(+v_34: Maybe<&2, String>, +v_8: List<&2, cps_provider_3_NfVal>, +v_36: Nat, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_34:
    case Some{+v_39}:
      v_1000775 = {Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_8), v_36) : Bool}
      template_match_213(v_1000775, v_7, v_34)
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_215(+v_27: BIR.TypeFunction, +v_8: List<&2, cps_provider_3_NfVal>, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_27:
    case BIR.TypeFunction{+v_33, +v_34, +v_35, +v_36, +v_37}:
      template_match_214(v_34, v_8, v_36, v_7)

def template_match_216(+v_1000774: Maybe<&2, BIR.TypeFunction>, +v_8: List<&2, cps_provider_3_NfVal>, +v_7: String) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1000774:
    case Some{+v_27}:
      template_match_215(v_27, v_8, v_7)
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxUnresolved{v_7}}}}

def template_match_217(+v_1000772: Maybe<&2, BIR.Family>, +v_8: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_1000772:
    case Some{+v_11}:
      template_match_212(v_11, v_8, v_7)
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_function_lookup{v_1, v_7}}, False{}, v_1000777 => template_body_cps_provider_1_function_lookup(v_1, v_7), v_1000776 => +v_1000774 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1000776); template_match_216(v_1000774, v_8, v_7)}

def template_body_cps_provider_1_head_value(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal) -> TemplateProgress<cps_provider_1_HeadResult>:
  match v_3:
    case cps_provider_3_NfType{+v_1004200, +v_1004201}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_lookup{v_1, v_1004200}}, False{}, v_1004202 => template_body_cps_provider_1_family_lookup(v_1, v_1004200), v_1004203 => +v_1004204 = template_unbox(Maybe<&2, BIR.Family>, v_1004203); template_match_217(v_1004204, v_1004201, v_1004200, v_1)}
    case cps_provider_3_NfOther{+v_1004205}:
      template_body_cps_provider_1_head_other(v_1004205)
    case v_1004206:
      TemplateFinished{TemplateValue{cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}}}

def template_match_219(+v_1000781: BIR.Descriptor) -> TemplateProgress<cps_provider_1_NormResult>:
  match v_1000781:
    case BIR.DescriptorFailure{+v_7}:
      TemplateFinished{TemplateValue{cps_provider_1_NormFailed{v_7}}}
    case +v_9:
      TemplateFinished{TemplateValue{cps_provider_1_NormOk{v_9}}}

def template_body_cps_provider_1_norm(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_NormResult>:
  TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_normalize{template_pure_cps_provider_1_context_nf(v_1), v_2, [], 1024n}}, v_1000782 => +v_1000781 = template_unbox(BIR.Descriptor, v_1000782); template_match_219(v_1000781)}

def template_match_220(+v_8: cps_provider_3_NfVal) -> TemplateProgress<cps_provider_1_ArgsResult>:
  match v_8:
    case cps_provider_3_NfType{+v_11, +v_12}:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_materialize_all{v_12}}, v_1000785 => +v_1000784 = template_unbox(List<&2, BIR.Descriptor>, v_1000785); TemplateFinished{TemplateValue{cps_provider_1_ArgsOk{v_1000784}}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_1_ArgsFailed{"the applied type is not a named family application"}}}

def template_match_221(+v_1000783: cps_provider_3_Nf) -> TemplateProgress<cps_provider_1_ArgsResult>:
  match v_1000783:
    case cps_provider_3_NfFail{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_1_ArgsFailed{v_6}}}
    case cps_provider_3_NfOk{+v_8}:
      template_match_220(v_8)

def template_body_cps_provider_1_head_args(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_ArgsResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_of{v_1, v_2, [], 1024n}}, False{}, v_1000787 => template_body_cps_provider_1_nf_of(v_1, v_2, [], 1024n), v_1000786 => +v_1000783 = template_unbox(cps_provider_3_Nf, v_1000786); template_match_221(v_1000783)}

def template_match_222(+v_1000788: cps_provider_3_Nf, +v_1: cps_provider_1_Context, +v_3: String) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_1000788:
    case cps_provider_3_NfFail{+v_8}:
      TemplateFinished{TemplateValue{cps_provider_1_FieldsFailed{v_8}}}
    case cps_provider_3_NfOk{+v_10}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_arm_fields_value{v_1, v_3, v_10}}, v_1000790 => +v_1000789 = template_unbox(cps_provider_1_FieldsResult, v_1000790); TemplateFinished{TemplateValue{v_1000789}}}

def template_body_cps_provider_1_arm_fields(+v_1: cps_provider_1_Context, +v_3: String, +v_4: BIR.Descriptor) -> TemplateProgress<cps_provider_1_FieldsResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_of{v_1, v_4, [], 1024n}}, False{}, v_1000792 => template_body_cps_provider_1_nf_of(v_1, v_4, [], 1024n), v_1000791 => +v_1000788 = template_unbox(cps_provider_3_Nf, v_1000791); template_match_222(v_1000788, v_1, v_3)}

def template_match_223(+v_14: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_14:
    case BIR.DescriptorArm{+v_17, +v_18}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_instantiate_fields{v_1, v_10, v_18, []}}, v_1000798 => +v_1000797 = template_unbox(cps_provider_1_FieldsResult, v_1000798); TemplateFinished{TemplateValue{v_1000797}}}

def template_match_224(+v_1000793: Maybe<&2, BIR.DescriptorArm>, +v_3: String, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_1000793:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_unresolved_message{v_3}}, False{}, v_1000796 => template_body_cps_provider_1_unresolved_message(v_3), v_1000795 => +v_1000794 = template_unbox(String, v_1000795); TemplateFinished{TemplateValue{cps_provider_1_FieldsFailed{v_1000794}}}}
    case Some{+v_14}:
      template_match_223(v_14, v_1, v_10)

def template_body_cps_provider_1_arm_fields_value(+v_1: cps_provider_1_Context, +v_3: String, +v_5: cps_provider_3_NfVal) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_5:
    case cps_provider_3_NfType{+v_1004207, +v_1004208}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_declared{v_1, v_3}}, False{}, v_1004209 => template_body_cps_provider_1_arm_declared(v_1, v_3), v_1004210 => +v_1004211 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1004210); template_match_224(v_1004211, v_3, v_1, v_1004208)}
    case v_1004212:
      TemplateFinished{TemplateValue{cps_provider_1_FieldsFailed{"the applied type is not a named family application"}}}

def template_continuation_226(v_1000802: Maybe<&2, String>, v_1000803: BIR.Quantity, +v_1000804: BIR.Descriptor, +v_1: cps_provider_1_Context, +v_22: List<&2, cps_provider_3_NfVal>, v_13: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  +v_26 = {BIR.DescriptorField{v_1000802, v_1000803, v_1000804} : BIR.DescriptorField}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_instantiate_fields{v_1, v_22, v_13, v_26 <> v_8}}, v_1000806 => +v_1000805 = template_unbox(cps_provider_1_FieldsResult, v_1000806); TemplateFinished{TemplateValue{v_1000805}}}

def template_continuation_227(+v_1000801: List<&2, cps_provider_3_NfVal>, +v_17: Maybe<&2, String>, +v_18: BIR.Quantity, +v_1: cps_provider_1_Context, +v_19: BIR.Descriptor, +v_4: List<&2, cps_provider_3_NfVal>, v_13: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_normalize{template_pure_cps_provider_1_context_nf(v_1), v_19, v_4, 1024n}}, v_1000807 => +v_1000804 = template_unbox(BIR.Descriptor, v_1000807); template_continuation_226({v_17 : Maybe<&2, String>}, {v_18 : BIR.Quantity}, v_1000804, v_1, v_1000801, v_13, v_8)}

def template_match_228(+v_12: BIR.DescriptorField, +v_4: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_1_Context, v_13: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_12:
    case BIR.DescriptorField{+v_17, +v_18, +v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_field_scope{v_4}}, False{}, v_1000809 => template_body_cps_provider_1_field_scope(v_4), v_1000808 => +v_1000801 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1000808); template_continuation_227(v_1000801, v_17, v_18, v_1, v_19, v_4, v_13, v_8)}

def template_body_cps_provider_1_instantiate_fields(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_1_FieldsResult>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_1_FieldsFound{List.reverse(&2, BIR.DescriptorField, v_8)}}}
    case +v_1004213 <> v_1004214:
      template_match_228(v_1004213, v_4, v_1, v_1004214, v_8)

def template_match_230(+v_1000810: cps_provider_1_LayoutResult) -> TemplateProgress<cps_provider_1_CellResult>:
  match v_1000810:
    case cps_provider_1_LayoutFailed{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_1_CellFailed{v_6}}}
    case cps_provider_1_LayoutFound{+v_8}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_cell_of{v_8}}, v_1000812 => +v_1000811 = template_unbox(cps_provider_1_CellResult, v_1000812); TemplateFinished{TemplateValue{v_1000811}}}

def template_body_cps_provider_1_array_cell(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_value_layout{v_1, v_2}}, False{}, v_1000814 => template_body_cps_provider_1_value_layout(v_1, v_2), v_1000813 => +v_1000810 = template_unbox(cps_provider_1_LayoutResult, v_1000813); template_match_230(v_1000810)}

def template_continuation_231(+v_10: Nat, v_1000818: cps_provider_1_Layout, +v_1000819: Bool) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_max_one{v_10}}, v_1000825 => +v_1000821 = template_unbox(Nat, v_1000825); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_ceil_log2{v_1000821}}, False{}, v_1000824 => template_body_cps_provider_1_ceil_log2(v_1000821), v_1000823 => +v_1000822 = template_unbox(Nat, v_1000823); TemplateFinished{TemplateValue{cps_provider_1_CellFound{cps_provider_1_Cell{v_1000818, v_1000819, {v_10 : Nat}, v_1000822}}}}}}

def template_continuation_232(+v_1000817: Nat, +v_1: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_layout_has_term{v_1}}, v_1000826 => +v_1000819 = template_unbox(Bool, v_1000826); template_continuation_231(v_1000817, {v_1 : cps_provider_1_Layout}, v_1000819)}

def template_body_cps_provider_1_cell_of(+v_1: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_CellResult>:
  match v_1:
    case cps_provider_1_LayoutBox{+v_4}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_cps_provider_1_cell_boxed{v_4}}, v_1000816 => +v_1000815 = template_unbox(cps_provider_1_CellResult, v_1000816); TemplateFinished{TemplateValue{v_1000815}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_1}}, False{}, v_1000828 => template_body_cps_provider_1_layout_words(v_1), v_1000827 => +v_1000817 = template_unbox(Nat, v_1000827); template_continuation_232(v_1000817, v_1)}

def template_body_cps_provider_1_cell_boxed(+v_1: cps_provider_1_BoxReason) -> TemplateProgress<cps_provider_1_CellResult>:
  TemplateFinished{TemplateValue{cps_provider_1_CellFound{cps_provider_1_Cell{cps_provider_1_LayoutBox{v_1}, True{}, 1n, 0n}}}}

def template_match_234(v_1000829: Bool, +v_1: Nat) -> TemplateProgress<Nat>:
  match v_1000829:
    case True{}:
      TemplateFinished{TemplateValue{v_1}}
    case False{}:
      TemplateFinished{TemplateValue{1n}}

def template_body_cps_provider_1_max_one(+v_1: Nat) -> TemplateProgress<Nat>:
  v_1000829 = {Nat.is_gt(v_1, 0n) : Bool}
  template_match_234(v_1000829, v_1)

def template_body_cps_provider_1_layout_has_term(+v_1: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_1_LayoutWord{+v_4}:
      TemplateFinished{TemplateValue{template_pure_cps_provider_1_word_has_term(v_4)}}
    case cps_provider_1_LayoutBox{+v_7}:
      TemplateFinished{TemplateValue{True{}}}
    case cps_provider_1_LayoutData{+v_10, +v_11}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_any_word_has_term{v_10}}, v_1000831 => +v_1000830 = template_unbox(Bool, v_1000831); TemplateFinished{TemplateValue{v_1000830}}}

def template_body_cps_provider_1_word_has_term(+v_1: cps_provider_1_CWord) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_1_word_has_term(v_1)}}

def template_match_236(v_1000832: Bool, v_7: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_1000832:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_1_any_word_has_term{v_7}}, v_1000834 => +v_1000833 = template_unbox(Bool, v_1000834); TemplateFinished{TemplateValue{v_1000833}}}

def template_body_cps_provider_1_any_word_has_term(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<Bool>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_6 <> v_7:
      v_1000832 = {template_pure_cps_provider_1_word_has_term(v_6) : Bool}
      template_match_236(v_1000832, v_7)

def template_body_cps_provider_2_world(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, cps_provider_2_CidSym>) -> TemplateProgress<cps_provider_2_World>:
  TemplateFinished{TemplateValue{cps_provider_2_World{v_1, v_3, v_6}}}

def template_body_cps_provider_2_join_text(+v_2: List<&2, String>) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{String.join(v_2, "")}}

def template_body_cps_provider_2_code_line(+v_1: String) -> TemplateProgress<cps_provider_2_Code>:
  TemplateFinished{TemplateValue{cps_provider_2_CodeOk{[v_1]}}}

def template_body_cps_provider_2_code_empty() -> TemplateProgress<cps_provider_2_Code>:
  TemplateFinished{TemplateValue{cps_provider_2_CodeOk{[]}}}

def template_match_238(+v_3: cps_provider_2_Code, v_8: List<&2, String>) -> TemplateProgress<cps_provider_2_Code>:
  match v_3:
    case cps_provider_2_CodeFail{v_10}:
      TemplateFinished{TemplateValue{cps_provider_2_CodeFail{v_10}}}
    case cps_provider_2_CodeOk{v_12}:
      TemplateFinished{TemplateValue{cps_provider_2_CodeOk{List.append(&2, String, v_8, v_12)}}}

def template_body_cps_provider_2_code_seq(+v_1: cps_provider_2_Code, +v_3: cps_provider_2_Code) -> TemplateProgress<cps_provider_2_Code>:
  match v_1:
    case cps_provider_2_CodeFail{v_6}:
      TemplateFinished{TemplateValue{cps_provider_2_CodeFail{v_6}}}
    case cps_provider_2_CodeOk{v_8}:
      template_match_238(v_3, v_8)

def template_body_cps_provider_2_code_text(+v_2: List<&2, String>, +v_4: String) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_8 <> +v_9:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["({\n", String.join(v_2, "\n"), "\n", v_4, ";\n})"]}}, False{}, v_1000837 => template_body_cps_provider_2_join_text(["({\n", String.join(v_2, "\n"), "\n", v_4, ";\n})"]), v_1000836 => +v_1000835 = template_unbox(String, v_1000836); TemplateFinished{TemplateValue{v_1000835}}}

def template_body_cps_provider_2_part_of(+v_1: cps_provider_2_Code, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CodeFail{+v_6}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_6}}}
    case cps_provider_2_CodeOk{+v_8}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_code_text{v_8, v_3}}, False{}, v_1000840 => template_body_cps_provider_2_code_text(v_8, v_3), v_1000839 => +v_1000838 = template_unbox(String, v_1000839); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1000838}}}}

def template_match_242(v_1000841: Bool, +v_1: U32, +v_8: List<&2, BIR.ConstructorLayout>, +v_7: BIR.ConstructorLayout) -> TemplateProgress<Maybe<&2, BIR.ConstructorLayout>>:
  match v_1000841:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_ctor_find{v_1, v_8}}, v_1000843 => +v_1000842 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1000843); TemplateFinished{TemplateValue{v_1000842}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_7}}}

def template_match_243(+v_7: BIR.ConstructorLayout, +v_1: U32, +v_8: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Maybe<&2, BIR.ConstructorLayout>>:
  match v_7:
    case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
      v_18 = U32.is_eq(v_1, v_13)
      template_match_242(v_18, v_1, v_8, v_7)

def template_body_cps_provider_2_ctor_find(+v_1: U32, +v_3: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Maybe<&2, BIR.ConstructorLayout>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004215 <> +v_1004216:
      template_match_243(v_1004215, v_1, v_1004216)

def template_body_cps_provider_2_ctor_of(+v_1: U32, +v_3: cps_provider_2_World) -> TemplateProgress<Maybe<&2, BIR.ConstructorLayout>>:
  match v_3:
    case cps_provider_2_World{v_1004217, v_1004218, v_1004219}:
      template_body_cps_provider_2_ctor_find(v_1, v_1004218)

def template_match_246(v_1000845: Bool, +v_1: String, +v_10: List<&2, cps_provider_2_CidSym>, v_13: U32) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1000845:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_find{v_1, v_10}}, v_1000847 => +v_1000846 = template_unbox(Maybe<&2, U32>, v_1000847); TemplateFinished{TemplateValue{v_1000846}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_13}}}

def template_match_247(+v_9: cps_provider_2_CidSym, +v_1: String, +v_10: List<&2, cps_provider_2_CidSym>) -> TemplateProgress<Maybe<&2, U32>>:
  match v_9:
    case cps_provider_2_CidSym{v_13, v_14}:
      v_16 = String.eq(v_1, v_14)
      template_match_246(v_16, v_1, v_10, v_13)

def template_body_cps_provider_2_cid_find(+v_1: String, +v_4: List<&2, cps_provider_2_CidSym>) -> TemplateProgress<Maybe<&2, U32>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004220 <> +v_1004221:
      template_match_247(v_1004220, v_1, v_1004221)

def template_body_cps_provider_2_cid_of(+v_1: String, +v_3: cps_provider_2_World) -> TemplateProgress<Maybe<&2, U32>>:
  match v_3:
    case cps_provider_2_World{v_1004222, v_1004223, v_1004224}:
      template_body_cps_provider_2_cid_find(v_1, v_1004224)

def template_body_cps_provider_2_cid_text_of(+v_2: Maybe<&2, U32>) -> TemplateProgress<Maybe<&2, String>>:
  match v_2:
    case Some{v_6}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[U32.show(v_6), "u"]}}, False{}, v_1000851 => template_body_cps_provider_2_join_text([U32.show(v_6), "u"]), v_1000850 => +v_1000849 = template_unbox(String, v_1000850); TemplateFinished{TemplateValue{Some{v_1000849}}}}
    case None{}:
      TemplateFinished{TemplateValue{None{}}}

def template_continuation_251(+v_1000852: Maybe<&2, U32>) -> TemplateProgress<Maybe<&2, String>>:
  template_body_cps_provider_2_cid_text_of(v_1000852)

def template_body_cps_provider_2_cid_text(+v_1: String, +v_3: cps_provider_2_World) -> TemplateProgress<Maybe<&2, String>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_1, v_3}}, False{}, v_1000855 => template_body_cps_provider_2_cid_of(v_1, v_3), v_1000854 => +v_1000852 = template_unbox(Maybe<&2, U32>, v_1000854); template_continuation_251(v_1000852)}

def template_body_cps_provider_2_intrinsic_marker(+v_1: String) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_intrinsic_marker(v_1)}}

def template_body_cps_provider_2_dst_write(+v_1: cps_provider_2_Dst, +v_3: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_2_DstSeq{v_8, +v_9}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_8, "[", v_9, "] = ", v_3, "; ", v_9, " += 1;"]}}, False{}, v_1000858 => template_body_cps_provider_2_join_text([v_8, "[", v_9, "] = ", v_3, "; ", v_9, " += 1;"]), v_1000857 => +v_1000856 = template_unbox(String, v_1000857); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000856}]}}}
    case cps_provider_2_DstOut{v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_12, " = ", v_3, ";"]}}, False{}, v_1000861 => template_body_cps_provider_2_join_text([v_12, " = ", v_3, ";"]), v_1000860 => +v_1000859 = template_unbox(String, v_1000860); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000859}]}}}

def template_body_cps_provider_2_dst_word(+v_1: cps_provider_2_Dst, +v_3: cps_provider_1_CWord, +v_5: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u64)(u32)(", v_5, "))"]}}, False{}, v_1004226 => template_body_cps_provider_2_join_text(["((u64)(u32)(", v_5, "))"]), v_1004227 => +v_1004228 = template_unbox(String, v_1004227); template_body_cps_provider_2_dst_write({v_1 : cps_provider_2_Dst}, v_1004228)}
    case cps_provider_1_CWord64{}:
      template_body_cps_provider_2_dst_write(v_1, v_5)
    case cps_provider_1_CWordBox{}:
      template_body_cps_provider_2_dst_write(v_1, v_5)

def template_body_cps_provider_2_dst_decl(+v_1: String, +v_3: String, +v_5: Nat) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_1, "[", Nat.show(v_5), "]; for (u32 ", v_3, "i = 0; ", v_3, "i < ", Nat.show(v_5), "; ", v_3, "i += 1) { ", v_1, "[", v_3, "i] = 0; } u32 ", v_3, " = 0;"]}}, False{}, v_1000871 => template_body_cps_provider_2_join_text(["u64 ", v_1, "[", Nat.show(v_5), "]; for (u32 ", v_3, "i = 0; ", v_3, "i < ", Nat.show(v_5), "; ", v_3, "i += 1) { ", v_1, "[", v_3, "i] = 0; } u32 ", v_3, " = 0;"]), v_1000870 => +v_1000869 = template_unbox(String, v_1000870); TemplateFinished{TemplateValue{v_1000869}}}

def template_match_254(+v_1: cps_provider_2_Dst, v_6: String) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_2_DstSeq{v_9, +v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, "[", v_10, "]", " = ", v_6, "; ", v_10, " += 1;"]}}, False{}, v_1000874 => template_body_cps_provider_2_join_text([v_9, "[", v_10, "]", " = ", v_6, "; ", v_10, " += 1;"]), v_1000873 => +v_1000872 = template_unbox(String, v_1000873); TemplateFinished{TemplateValue{v_1000872}}}
    case cps_provider_2_DstOut{v_13}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_13, " = ", v_6, ";"]}}, False{}, v_1000877 => template_body_cps_provider_2_join_text([v_13, " = ", v_6, ";"]), v_1000876 => +v_1000875 = template_unbox(String, v_1000876); TemplateFinished{TemplateValue{v_1000875}}}

def template_body_cps_provider_2_dst_mark(+v_1: cps_provider_2_Dst, +v_3: Nat) -> TemplateProgress<String>:
  v_6 = Nat.show(v_3)
  template_match_254(v_1, v_6)

def template_body_cps_provider_2_form_base(+v_1: Nat, +v_3: Bool) -> TemplateProgress<Nat>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_tag_word{v_3}}, False{}, v_1000881 => template_body_cps_provider_1_tag_word(v_3), v_1000880 => +v_1000879 = template_unbox(Nat, v_1000880); TemplateFinished{TemplateValue{Nat.sub({v_1 : Nat}, v_1000879)}}}

def template_body_cps_provider_2_form_pad(+v_1: Nat, +v_3: Nat) -> TemplateProgress<Nat>:
  TemplateFinished{TemplateValue{Nat.sub(v_1, v_3)}}

def template_match_255(v_15: Bool, v_14: String, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_15:
    case True{}:
      TemplateFinished{TemplateValue{[]}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_14, " += ", Nat.show(v_3), ";"]}}, False{}, v_1000885 => template_body_cps_provider_2_join_text([v_14, " += ", Nat.show(v_3), ";"]), v_1000884 => +v_1000883 = template_unbox(String, v_1000884); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000883}]}}}

def template_match_256(+v_1: cps_provider_2_Src, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_2_SrcOne{v_7}:
      TemplateFinished{TemplateValue{[]}}
    case cps_provider_2_SrcNode{v_12, v_13, v_14, v_15}:
      template_match_255(v_15, v_14, v_3)
    case cps_provider_2_SrcBlock{v_22, v_23, v_24, v_25, v_26}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_26, " += ", Nat.show(v_3), ";"]}}, False{}, v_1000888 => template_body_cps_provider_2_join_text([v_26, " += ", Nat.show(v_3), ";"]), v_1000887 => +v_1000886 = template_unbox(String, v_1000887); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000886}]}}}
    case cps_provider_2_SrcBuf{v_30, v_31}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_31, " += ", Nat.show(v_3), ";"]}}, False{}, v_1000891 => template_body_cps_provider_2_join_text([v_31, " += ", Nat.show(v_3), ";"]), v_1000890 => +v_1000889 = template_unbox(String, v_1000890); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000889}]}}}

def template_match_257(v_1000882: Bool, +v_1: cps_provider_2_Src, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1000882:
    case False{}:
      TemplateFinished{TemplateValue{[]}}
    case True{}:
      template_match_256(v_1, v_3)

def template_body_cps_provider_2_src_skip_jobs(+v_1: cps_provider_2_Src, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_1000882 = {Nat.is_gt(v_3, 0n) : Bool}
  template_match_257(v_1000882, v_1, v_3)

def template_match_258(+v_1: cps_provider_2_Dst, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_2_DstSeq{v_8, v_9}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, " += ", Nat.show(v_3), ";"]}}, False{}, v_1000895 => template_body_cps_provider_2_join_text([v_9, " += ", Nat.show(v_3), ";"]), v_1000894 => +v_1000893 = template_unbox(String, v_1000894); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000893}]}}}
    case cps_provider_2_DstOut{v_12}:
      TemplateFinished{TemplateValue{[]}}

def template_match_259(v_1000892: Bool, +v_1: cps_provider_2_Dst, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1000892:
    case False{}:
      TemplateFinished{TemplateValue{[]}}
    case True{}:
      template_match_258(v_1, v_3)

def template_body_cps_provider_2_dst_skip_jobs(+v_1: cps_provider_2_Dst, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_1000892 = {Nat.is_gt(v_3, 0n) : Bool}
  template_match_259(v_1000892, v_1, v_3)

def template_body_cps_provider_2_src_read_node(+v_1: String, +v_3: String, +v_5: String, +v_7: Bool, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_7:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_9, "w = ", v_1, ";"]}}, False{}, v_1004229 => template_body_cps_provider_2_join_text(["u64 ", v_9, "w = ", v_1, ";"]), v_1004230 => +v_1004231 = template_unbox(String, v_1004230); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004231}]}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_9, "w = ((", v_1, " != 0) ? e.mem[", v_1, " + ", v_5, "] : (u64)", v_3, "[", v_5, "]); ", v_5, " += 1;"]}}, False{}, v_1004232 => template_body_cps_provider_2_join_text(["u64 ", v_9, "w = ((", v_1, " != 0) ? e.mem[", v_1, " + ", v_5, "] : (u64)", v_3, "[", v_5, "]); ", v_5, " += 1;"]), v_1004233 => +v_1004234 = template_unbox(String, v_1004233); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004234}]}}}

def template_body_cps_provider_2_src_read_arr(+v_1: String, +v_3: String, +v_5: Bool, +v_7: String, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_5:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_9, "w = blk_keep(e, ", v_1, " + ", v_3, " + ", v_7, "); ", v_7, " += 1;"]}}, False{}, v_1004235 => template_body_cps_provider_2_join_text(["u64 ", v_9, "w = blk_keep(e, ", v_1, " + ", v_3, " + ", v_7, "); ", v_7, " += 1;"]), v_1004236 => +v_1004237 = template_unbox(String, v_1004236); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004237}]}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_9, "w = blk_read(e.mem, true, ", v_1, ", ", v_3, " + ", v_7, "); ", v_7, " += 1;"]}}, False{}, v_1004238 => template_body_cps_provider_2_join_text(["u64 ", v_9, "w = blk_read(e.mem, true, ", v_1, ", ", v_3, " + ", v_7, "); ", v_7, " += 1;"]), v_1004239 => +v_1004240 = template_unbox(String, v_1004239); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004240}]}}}

def template_body_cps_provider_2_src_read_block(+v_1: String, +v_3: String, +v_5: Bool, +v_7: Bool, +v_9: String, +v_11: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_5:
    case True{}:
      template_body_cps_provider_2_src_read_arr(v_1, v_3, v_7, v_9, v_11)
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_11, "w = ((u64)blk_read(e.mem, false, ", v_1, ", ", v_3, " + ", v_9, ")); ", v_9, " += 1;"]}}, False{}, v_1004241 => template_body_cps_provider_2_join_text(["u64 ", v_11, "w = ((u64)blk_read(e.mem, false, ", v_1, ", ", v_3, " + ", v_9, ")); ", v_9, " += 1;"]), v_1004242 => +v_1004243 = template_unbox(String, v_1004242); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004243}]}}}

def template_body_cps_provider_2_src_read(+v_1: cps_provider_2_Src, +v_3: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_2_SrcOne{v_7}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_3, "w = ", v_7, ";"]}}, False{}, v_1000914 => template_body_cps_provider_2_join_text(["u64 ", v_3, "w = ", v_7, ";"]), v_1000913 => +v_1000912 = template_unbox(String, v_1000913); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000912}]}}}
    case cps_provider_2_SrcNode{v_13, v_14, v_15, v_16}:
      template_body_cps_provider_2_src_read_node(v_13, v_14, v_15, v_16, v_3)
    case cps_provider_2_SrcBlock{v_23, v_24, v_25, v_26, v_27}:
      template_body_cps_provider_2_src_read_block(v_23, v_24, v_25, v_26, v_27, v_3)
    case cps_provider_2_SrcBuf{v_31, +v_32}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_3, "w = ", v_31, "[", v_32, "]; ", v_32, " += 1;"]}}, False{}, v_1000919 => template_body_cps_provider_2_join_text(["u64 ", v_3, "w = ", v_31, "[", v_32, "]; ", v_32, " += 1;"]), v_1000918 => +v_1000917 = template_unbox(String, v_1000918); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000917}]}}}

def template_body_cps_provider_2_form_tagged(+v_2: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_form_tagged(v_2)}}

def template_match_264(+v_8: cps_provider_1_FormArm, +v_9: List<&2, cps_provider_1_FormArm>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_8:
    case cps_provider_1_FormArm{v_15, v_16, v_17, v_18, v_19}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_max_node_words{v_9, Nat.max(v_4, v_18)}}, v_1000921 => +v_1000920 = template_unbox(Nat, v_1000921); TemplateFinished{TemplateValue{v_1000920}}}

def template_body_cps_provider_2_max_node_words(+v_2: List<&2, cps_provider_1_FormArm>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_8 <> +v_9:
      template_match_264(v_8, v_9, v_4)

def template_body_cps_provider_2_max_term_decl(+v_1: String, +v_3: Nat) -> TemplateProgress<String>:
  match v_3:
    case 0n:
      TemplateFinished{TemplateValue{""}}
    case v_1004244:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term ", v_1, "[", Nat.show(v_3), "];"]}}, False{}, v_1004245 => template_body_cps_provider_2_join_text(["Term ", v_1, "[", Nat.show(v_3), "];"]), v_1004246 => +v_1004247 = template_unbox(String, v_1004246); TemplateFinished{TemplateValue{v_1004247}}}

def template_body_cps_provider_2_arm_seed(+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{[]}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_seed_words{v_3, v_5, v_7, v_9}}, v_1000926 => +v_1000925 = template_unbox(List<&2, cps_provider_2_Job>, v_1000926); TemplateFinished{TemplateValue{v_1000925}}}

def template_body_cps_provider_2_arm_seed_words(+v_1: Nat, +v_3: String, +v_5: String, +v_7: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case v_1004248:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_5, "s = term_rfc(", v_3, ") ? ctr_take(e, ", v_3, ", ", Nat.show(v_1), ", ", v_7, ") : term_loc(", v_3, "); u32 ", v_5, "i = 0;"]}}, False{}, v_1004249 => template_body_cps_provider_2_join_text(["u64 ", v_5, "s = term_rfc(", v_3, ") ? ctr_take(e, ", v_3, ", ", Nat.show(v_1), ", ", v_7, ") : term_loc(", v_3, "); u32 ", v_5, "i = 0;"]), v_1004250 => +v_1004251 = template_unbox(String, v_1004250); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004251}]}}}

def template_match_269(+v_3: Nat, +v_5: String) -> TemplateProgress<cps_provider_2_Src>:
  match v_3:
    case 0n:
      TemplateFinished{TemplateValue{cps_provider_2_SrcOne{"0"}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u64)term_loc(", v_5, "))"]}}, False{}, v_1000932 => template_body_cps_provider_2_join_text(["((u64)term_loc(", v_5, "))"]), v_1000931 => +v_1000930 = template_unbox(String, v_1000931); TemplateFinished{TemplateValue{cps_provider_2_SrcOne{v_1000930}}}}

def template_continuation_270(+v_9: String, +v_7: String, +v_1000933: String) -> TemplateProgress<cps_provider_2_Src>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_7, "i"]}}, False{}, v_1000937 => template_body_cps_provider_2_join_text([v_7, "i"]), v_1000936 => +v_1000935 = template_unbox(String, v_1000936); TemplateFinished{TemplateValue{cps_provider_2_SrcNode{v_1000933, {v_9 : String}, v_1000935, False{}}}}}

def template_body_cps_provider_2_arm_src(+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String) -> TemplateProgress<cps_provider_2_Src>:
  match v_1:
    case True{}:
      template_match_269(v_3, v_5)
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_7, "s"]}}, False{}, v_1000939 => template_body_cps_provider_2_join_text([v_7, "s"]), v_1000938 => +v_1000933 = template_unbox(String, v_1000938); template_continuation_270(v_9, v_7, v_1000933)}

def template_match_272(+v_17: cps_provider_1_Nest, +v_6: cps_provider_2_Src, +v_8: cps_provider_2_Dst, +v_10: String, +v_12: Nat, +v_1: cps_provider_2_World, +v_18: List<&2, cps_provider_1_Nest>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_17:
    case cps_provider_1_Nest{v_23, v_24, v_25, v_26}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_10, "f", Nat.show(v_12)]}}, False{}, v_1000948 => template_body_cps_provider_2_join_text([v_10, "f", Nat.show(v_12)]), v_1000947 => +v_1000944 = template_unbox(String, v_1000947); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_nests_jobs{v_1, v_18, v_6, v_8, v_10, Nat.add(v_12, 1n)}}, v_1000946 => +v_1000945 = template_unbox(List<&2, cps_provider_2_Job>, v_1000946); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JConv{{v_25 : cps_provider_1_Unfill}, {v_26 : cps_provider_1_Fill}, {v_6 : cps_provider_2_Src}, {v_8 : cps_provider_2_Dst}, v_1000944}], v_1000945)}}}}

def template_body_cps_provider_2_nests_jobs(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_Nest>, +v_6: cps_provider_2_Src, +v_8: cps_provider_2_Dst, +v_10: String, +v_12: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004252 <> +v_1004253:
      template_match_272(v_1004252, v_6, v_8, v_10, v_12, v_1, v_1004253)

def template_match_274(+v_3: Nat, +v_5: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["if (", v_5, "s != 0) { spare_free(e, cls_fit(", Nat.show(v_3), "), ", v_5, "s); }"]}}, False{}, v_1000951 => template_body_cps_provider_2_join_text(["if (", v_5, "s != 0) { spare_free(e, cls_fit(", Nat.show(v_3), "), ", v_5, "s); }"]), v_1000950 => +v_1000949 = template_unbox(String, v_1000950); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1000949}]}}}

def template_body_cps_provider_2_arm_release(+v_1: Bool, +v_3: Nat, +v_5: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{[]}}
    case False{}:
      template_match_274(v_3, v_5)

def template_continuation_276(+v_18: cps_provider_2_Dst, +v_7: Nat, +v_11: Nat, +v_9: Bool, +v_20: String, +v_1000953: List<&2, cps_provider_2_Job>, +v_1000957: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1000958 = {v_18 : cps_provider_2_Dst}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_pad{v_7, v_11}}, False{}, v_1000967 => template_body_cps_provider_2_form_pad(v_7, v_11), v_1000966 => +v_1000959 = template_unbox(Nat, v_1000966); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_skip_jobs{v_1000958, v_1000959}}, False{}, v_1000965 => template_body_cps_provider_2_dst_skip_jobs(v_1000958, v_1000959), v_1000964 => +v_1000960 = template_unbox(List<&2, cps_provider_2_Job>, v_1000964); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_release{v_9, v_11, v_20}}, False{}, v_1000963 => template_body_cps_provider_2_arm_release(v_9, v_11, v_20), v_1000962 => +v_1000961 = template_unbox(List<&2, cps_provider_2_Job>, v_1000962); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [], List.append(&2, cps_provider_2_Job, v_1000953, List.append(&2, cps_provider_2_Job, v_1000957, List.append(&2, cps_provider_2_Job, v_1000960, v_1000961))))}}}}}

def template_continuation_277(+v_1: cps_provider_2_World, +v_14: List<&2, cps_provider_1_Nest>, +v_9: Bool, +v_11: Nat, +v_16: String, +v_20: String, +v_24: String, +v_18: cps_provider_2_Dst, +v_7: Nat, +v_1000953: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1000954 = {v_1 : cps_provider_2_World}
  +v_1000955 = {v_14 : List<&2, cps_provider_1_Nest>}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_src{v_9, v_11, v_16, v_20, v_24}}, False{}, v_1000971 => template_body_cps_provider_2_arm_src(v_9, v_11, v_16, v_20, v_24), v_1000970 => +v_1000956 = template_unbox(cps_provider_2_Src, v_1000970); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_nests_jobs{v_1000954, v_1000955, v_1000956, v_18, v_20, 0n}}, False{}, v_1000969 => template_body_cps_provider_2_nests_jobs(v_1000954, v_1000955, v_1000956, v_18, v_20, 0n), v_1000968 => +v_1000957 = template_unbox(List<&2, cps_provider_2_Job>, v_1000968); template_continuation_276(v_18, v_7, v_11, v_9, v_20, v_1000953, v_1000957)}}

def template_continuation_278(+v_18: cps_provider_2_Dst, +v_7: Nat, +v_11: Nat, +v_9: Bool, +v_20: String, +v_1000975: List<&2, cps_provider_2_Job>, +v_1000976: List<&2, cps_provider_2_Job>, +v_1000980: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1000981 = {v_18 : cps_provider_2_Dst}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_pad{v_7, v_11}}, False{}, v_1000990 => template_body_cps_provider_2_form_pad(v_7, v_11), v_1000989 => +v_1000982 = template_unbox(Nat, v_1000989); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_skip_jobs{v_1000981, v_1000982}}, False{}, v_1000988 => template_body_cps_provider_2_dst_skip_jobs(v_1000981, v_1000982), v_1000987 => +v_1000983 = template_unbox(List<&2, cps_provider_2_Job>, v_1000987); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_release{v_9, v_11, v_20}}, False{}, v_1000986 => template_body_cps_provider_2_arm_release(v_9, v_11, v_20), v_1000985 => +v_1000984 = template_unbox(List<&2, cps_provider_2_Job>, v_1000985); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1000975, List.append(&2, cps_provider_2_Job, v_1000976, List.append(&2, cps_provider_2_Job, v_1000980, List.append(&2, cps_provider_2_Job, v_1000983, v_1000984))))}}}}}

def template_continuation_279(+v_1: cps_provider_2_World, +v_14: List<&2, cps_provider_1_Nest>, +v_9: Bool, +v_11: Nat, +v_16: String, +v_20: String, +v_24: String, +v_18: cps_provider_2_Dst, +v_7: Nat, +v_1000975: List<&2, cps_provider_2_Job>, +v_1000976: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1000977 = {v_1 : cps_provider_2_World}
  +v_1000978 = {v_14 : List<&2, cps_provider_1_Nest>}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_src{v_9, v_11, v_16, v_20, v_24}}, False{}, v_1000994 => template_body_cps_provider_2_arm_src(v_9, v_11, v_16, v_20, v_24), v_1000993 => +v_1000979 = template_unbox(cps_provider_2_Src, v_1000993); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_nests_jobs{v_1000977, v_1000978, v_1000979, v_18, v_20, 0n}}, False{}, v_1000992 => template_body_cps_provider_2_nests_jobs(v_1000977, v_1000978, v_1000979, v_18, v_20, 0n), v_1000991 => +v_1000980 = template_unbox(List<&2, cps_provider_2_Job>, v_1000991); template_continuation_278(v_18, v_7, v_11, v_9, v_20, v_1000975, v_1000976, v_1000980)}}

def template_match_280(v_1000952: Bool, +v_9: Bool, +v_11: Nat, +v_16: String, +v_20: String, +v_24: String, +v_1: cps_provider_2_World, +v_14: List<&2, cps_provider_1_Nest>, +v_18: cps_provider_2_Dst, +v_7: Nat, +v_5: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1000952:
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_seed{v_9, v_11, v_16, v_20, v_24}}, False{}, v_1000973 => template_body_cps_provider_2_arm_seed(v_9, v_11, v_16, v_20, v_24), v_1000972 => +v_1000953 = template_unbox(List<&2, cps_provider_2_Job>, v_1000972); template_continuation_277(v_1, v_14, v_9, v_11, v_16, v_20, v_24, v_18, v_7, v_1000953)}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_mark{v_18, v_5}}, False{}, v_1000999 => template_body_cps_provider_2_dst_mark(v_18, v_5), v_1000998 => +v_1000974 = template_unbox(String, v_1000998); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1000974}}}, v_1000997 => +v_1000975 = template_unbox(List<&2, cps_provider_2_Job>, v_1000997); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_seed{v_9, v_11, v_16, v_20, v_24}}, False{}, v_1000996 => template_body_cps_provider_2_arm_seed(v_9, v_11, v_16, v_20, v_24), v_1000995 => +v_1000976 = template_unbox(List<&2, cps_provider_2_Job>, v_1000995); template_continuation_279(v_1, v_14, v_9, v_11, v_16, v_20, v_24, v_18, v_7, v_1000975, v_1000976)}}}

def template_body_cps_provider_2_jobs_arm_body(+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_14: List<&2, cps_provider_1_Nest>, +v_16: String, +v_18: cps_provider_2_Dst, +v_20: String, +v_22: Bool, +v_24: String, +v_26: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  template_match_280(v_22, v_9, v_11, v_16, v_20, v_24, v_1, v_14, v_18, v_7, v_5)

def template_body_cps_provider_2_jobs_arm(+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_14: List<&2, cps_provider_1_Nest>, +v_16: String, +v_18: cps_provider_2_Dst, +v_20: String, +v_22: Bool, +v_24: String, +v_26: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["case ", U32.show(v_3), "u: {"]}}, False{}, v_1001005 => template_body_cps_provider_2_join_text(["case ", U32.show(v_3), "u: {"]), v_1001004 => +v_1001000 = template_unbox(String, v_1001004); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_jobs_arm_body{v_1, v_3, v_5, v_7, v_9, v_11, v_14, v_16, v_18, v_20, v_22, v_24, v_26}}, False{}, v_1001003 => template_body_cps_provider_2_jobs_arm_body(v_1, v_3, v_5, v_7, v_9, v_11, v_14, v_16, v_18, v_20, v_22, v_24, v_26), v_1001002 => +v_1001001 = template_unbox(List<&2, cps_provider_2_Job>, v_1001002); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1001000}], List.append(&2, cps_provider_2_Job, v_1001001, [cps_provider_2_JText{"} break;"}]))}}}}

def template_match_281(+v_6: cps_provider_1_FormArm, +v_1: cps_provider_2_World, v_24: U32, +v_8: Nat, +v_10: String, +v_12: cps_provider_2_Dst, +v_14: String, +v_16: Bool, +v_18: String, +v_20: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_6:
    case cps_provider_1_FormArm{v_30, v_31, v_32, v_33, v_34}:
      template_body_cps_provider_2_jobs_arm(v_1, v_24, v_31, v_8, v_32, v_33, v_34, v_10, v_12, v_14, v_16, v_18, v_20)

def template_body_cps_provider_2_arm_jobs(+v_1: cps_provider_2_World, +v_4: Maybe<&2, U32>, +v_6: cps_provider_1_FormArm, +v_8: Nat, +v_10: String, +v_12: cps_provider_2_Dst, +v_14: String, +v_16: Bool, +v_18: String, +v_20: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case None{}:
      TemplateFinished{TemplateValue{[cps_provider_2_JText{"default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;"}]}}
    case Some{v_1004254}:
      template_match_281(v_6, v_1, v_1004254, v_8, v_10, v_12, v_14, v_16, v_18, v_20)

def template_continuation_283(+v_1001007: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_21: cps_provider_1_FormArm, +v_6: Nat, +v_8: String, +v_10: cps_provider_2_Dst, +v_12: String, +v_14: Bool, +v_16: String, +v_22: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_35 = v_1001007
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_jobs{v_1, v_35, v_21, v_6, v_8, v_10, v_12, v_14, v_16, 0n}}, False{}, v_1001012 => template_body_cps_provider_2_arm_jobs(v_1, v_35, v_21, v_6, v_8, v_10, v_12, v_14, v_16, 0n), v_1001011 => +v_1001008 = template_unbox(List<&2, cps_provider_2_Job>, v_1001011); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_unbox_cases{v_1, v_22, v_6, v_8, v_10, v_12, v_14, v_16}}, v_1001010 => +v_1001009 = template_unbox(List<&2, cps_provider_2_Job>, v_1001010); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001008, v_1001009)}}}}

def template_match_284(+v_21: cps_provider_1_FormArm, +v_1: cps_provider_2_World, +v_6: Nat, +v_8: String, +v_10: cps_provider_2_Dst, +v_12: String, +v_14: Bool, +v_16: String, +v_22: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_21:
    case cps_provider_1_FormArm{v_28, v_29, v_30, v_31, v_32}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_28, v_1}}, False{}, v_1001014 => template_body_cps_provider_2_cid_of(v_28, v_1), v_1001013 => +v_1001007 = template_unbox(Maybe<&2, U32>, v_1001013); template_continuation_283(v_1001007, v_1, v_21, v_6, v_8, v_10, v_12, v_14, v_16, v_22)}

def template_body_cps_provider_2_unbox_cases(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: String, +v_10: cps_provider_2_Dst, +v_12: String, +v_14: Bool, +v_16: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004255 <> +v_1004256:
      template_match_284(v_1004255, v_1, v_6, v_8, v_10, v_12, v_14, v_16, v_1004256)

def template_continuation_286(+v_1001022: List<&2, cps_provider_2_Job>, v_36: List<&2, cps_provider_2_Job>, v_17: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["switch (term_aux(", v_17, ")) {"]}}, False{}, v_1001026 => template_body_cps_provider_2_join_text(["switch (term_aux(", v_17, ")) {"]), v_1001025 => +v_1001024 = template_unbox(String, v_1001025); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, {v_36 : List<&2, cps_provider_2_Job>}, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1001024}], List.append(&2, cps_provider_2_Job, v_1001022, [cps_provider_2_JText{"}"}])))}}}

def template_continuation_287(+v_1001019: List<&2, cps_provider_2_Job>, +v_1001020: String, +v_1001021: String, +v_1: cps_provider_2_World, +v_6: List<&2, cps_provider_1_FormArm>, v_29: Nat, +v_17: String, +v_10: cps_provider_2_Dst, +v_12: String, v_26: Bool, v_20: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_36 = List.append(&2, cps_provider_2_Job, v_1001019, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1001020}], [cps_provider_2_JText{v_1001021}]))
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_unbox_cases{v_1, v_6, v_29, v_17, v_10, v_12, v_26, v_20}}, False{}, v_1001028 => template_body_cps_provider_2_unbox_cases(v_1, v_6, v_29, v_17, v_10, v_12, v_26, v_20), v_1001027 => +v_1001022 = template_unbox(List<&2, cps_provider_2_Job>, v_1001027); template_continuation_286(v_1001022, v_36, v_17)}

def template_continuation_288(+v_1001018: Nat, +v_8: cps_provider_2_Src, +v_12: String, +v_17: String, +v_20: String, v_23: Nat, +v_1: cps_provider_2_World, +v_6: List<&2, cps_provider_1_FormArm>, +v_10: cps_provider_2_Dst, v_26: Bool) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_read{v_8, v_12}}, False{}, v_1001034 => template_body_cps_provider_2_src_read(v_8, v_12), v_1001033 => +v_1001019 = template_unbox(List<&2, cps_provider_2_Job>, v_1001033); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term ", v_17, " = ", v_12, "w;"]}}, False{}, v_1001032 => template_body_cps_provider_2_join_text(["Term ", v_17, " = ", v_12, "w;"]), v_1001031 => +v_1001020 = template_unbox(String, v_1001031); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_max_term_decl{v_20, v_23}}, False{}, v_1001030 => template_body_cps_provider_2_max_term_decl(v_20, v_23), v_1001029 => +v_1001021 = template_unbox(String, v_1001029); template_continuation_287(v_1001019, v_1001020, v_1001021, v_1, v_6, v_1001018, v_17, v_10, v_12, v_26, v_20)}}}

def template_continuation_289(+v_1001017: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_3: Nat, +v_8: cps_provider_2_Src, +v_12: String, v_17: String, v_20: String, +v_1: cps_provider_2_World, +v_10: cps_provider_2_Dst) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_26 = template_pure_cps_provider_2_form_tagged(v_6)
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_base{v_3, v_26}}, False{}, v_1001036 => template_body_cps_provider_2_form_base(v_3, v_26), v_1001035 => +v_1001018 = template_unbox(Nat, v_1001035); template_continuation_288(v_1001018, v_8, v_12, v_17, v_20, v_1001017, v_1, v_6, v_10, v_26)}

def template_continuation_290(+v_1001016: String, +v_6: List<&2, cps_provider_1_FormArm>, +v_3: Nat, +v_8: cps_provider_2_Src, +v_12: String, v_17: String, +v_1: cps_provider_2_World, +v_10: cps_provider_2_Dst) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_max_node_words{v_6, 0n}}, False{}, v_1001038 => template_body_cps_provider_2_max_node_words(v_6, 0n), v_1001037 => +v_1001017 = template_unbox(Nat, v_1001037); template_continuation_289(v_1001017, v_6, v_3, v_8, v_12, v_17, v_1001016, v_1, v_10)}

def template_continuation_291(+v_1001015: String, +v_12: String, +v_6: List<&2, cps_provider_1_FormArm>, +v_3: Nat, +v_8: cps_provider_2_Src, +v_1: cps_provider_2_World, +v_10: cps_provider_2_Dst) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_12, "f"]}}, False{}, v_1001040 => template_body_cps_provider_2_join_text([v_12, "f"]), v_1001039 => +v_1001016 = template_unbox(String, v_1001039); template_continuation_290(v_1001016, v_6, v_3, v_8, v_12, v_1001015, v_1, v_10)}

def template_body_cps_provider_2_expand_unbox(+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: cps_provider_2_Src, +v_10: cps_provider_2_Dst, +v_12: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_12, "t"]}}, False{}, v_1001042 => template_body_cps_provider_2_join_text([v_12, "t"]), v_1001041 => +v_1001015 = template_unbox(String, v_1001041); template_continuation_291(v_1001015, v_12, v_6, v_3, v_8, v_1, v_10)}

def template_continuation_292(+v_7: cps_provider_2_Dst, +v_9: String, +v_1001043: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001044 = {v_7 : cps_provider_2_Dst}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, "w"]}}, False{}, v_1001050 => template_body_cps_provider_2_join_text([v_9, "w"]), v_1001049 => +v_1001045 = template_unbox(String, v_1001049); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_write{v_1001044, v_1001045}}, False{}, v_1001048 => template_body_cps_provider_2_dst_write(v_1001044, v_1001045), v_1001047 => +v_1001046 = template_unbox(List<&2, cps_provider_2_Job>, v_1001047); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001043, v_1001046)}}}}

def template_body_cps_provider_2_expand_word_take(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Fill, +v_5: cps_provider_2_Src, +v_7: cps_provider_2_Dst, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case cps_provider_1_FillWord{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_read{v_5, v_9}}, False{}, v_1004257 => template_body_cps_provider_2_src_read(v_5, v_9), v_1004258 => +v_1004259 = template_unbox(List<&2, cps_provider_2_Job>, v_1004258); template_continuation_292(v_7, v_9, v_1004259)}
    case cps_provider_1_FillForm{v_1004260, v_1004261}:
      template_body_cps_provider_2_expand_unbox(v_1, v_1004260, v_1004261, v_5, v_7, v_9)

def template_body_cps_provider_2_nest_take(+v_1: cps_provider_1_Nest) -> TemplateProgress<cps_provider_1_Unfill>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_nest_take(v_1)}}

def template_body_cps_provider_2_nest_make(+v_1: cps_provider_1_Nest) -> TemplateProgress<cps_provider_1_Fill>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_nest_make(v_1)}}

def template_match_294(+v_7: List<&2, cps_provider_1_Nest>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case _:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{"the constructor's slots and fields differ"}]}}

def template_continuation_295(+v_1001054: String, +v_22: cps_provider_1_Nest, +v_26: cps_provider_1_Nest, +v_9: cps_provider_2_Src, +v_11: cps_provider_2_Dst, +v_1: cps_provider_2_World, +v_23: List<&2, cps_provider_1_Nest>, +v_27: List<&2, cps_provider_1_Nest>, +v_13: String, +v_15: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_1001055 = {[cps_provider_2_JConv{template_pure_cps_provider_2_nest_take(v_22), template_pure_cps_provider_2_nest_make(v_26), v_9, v_11, v_1001054}] : List<&2, cps_provider_2_Job>}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_field_pair_jobs{v_1, v_23, v_27, v_9, v_11, v_13, Nat.add(v_15, 1n)}}, v_1001057 => +v_1001056 = template_unbox(List<&2, cps_provider_2_Job>, v_1001057); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001055, v_1001056)}}}

def template_match_296(+v_7: List<&2, cps_provider_1_Nest>, +v_13: String, +v_15: Nat, +v_22: cps_provider_1_Nest, +v_9: cps_provider_2_Src, +v_11: cps_provider_2_Dst, +v_1: cps_provider_2_World, +v_23: List<&2, cps_provider_1_Nest>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{"the constructor's slots and fields differ"}]}}
    case +v_26 <> +v_27:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_13, "p", Nat.show(v_15)]}}, False{}, v_1001059 => template_body_cps_provider_2_join_text([v_13, "p", Nat.show(v_15)]), v_1001058 => +v_1001054 = template_unbox(String, v_1001058); template_continuation_295(v_1001054, v_22, v_26, v_9, v_11, v_1, v_23, v_27, v_13, v_15)}

def template_body_cps_provider_2_field_pair_jobs(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_Nest>, +v_7: List<&2, cps_provider_1_Nest>, +v_9: cps_provider_2_Src, +v_11: cps_provider_2_Dst, +v_13: String, +v_15: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      template_match_294(v_7)
    case +v_1004262 <> +v_1004263:
      template_match_296(v_7, v_13, v_15, v_1004262, v_9, v_11, v_1, v_1004263)

def template_continuation_298(+v_17: cps_provider_2_Src, +v_8: Nat, +v_3: Nat, +v_1001061: List<&2, cps_provider_2_Job>, +v_1001064: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001065 = {v_17 : cps_provider_2_Src}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_pad{v_8, v_3}}, False{}, v_1001071 => template_body_cps_provider_2_form_pad(v_8, v_3), v_1001070 => +v_1001066 = template_unbox(Nat, v_1001070); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_skip_jobs{v_1001065, v_1001066}}, False{}, v_1001069 => template_body_cps_provider_2_src_skip_jobs(v_1001065, v_1001066), v_1001068 => +v_1001067 = template_unbox(List<&2, cps_provider_2_Job>, v_1001068); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [], List.append(&2, cps_provider_2_Job, v_1001061, List.append(&2, cps_provider_2_Job, v_1001064, v_1001067)))}}}}

def template_continuation_299(+v_19: cps_provider_2_Dst, +v_10: Nat, v_34: Nat, +v_17: cps_provider_2_Src, +v_8: Nat, +v_3: Nat, +v_1001061: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001062 = {v_19 : cps_provider_2_Dst}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_pad{v_10, v_34}}, False{}, v_1001075 => template_body_cps_provider_2_form_pad(v_10, v_34), v_1001074 => +v_1001063 = template_unbox(Nat, v_1001074); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_skip_jobs{v_1001062, v_1001063}}, False{}, v_1001073 => template_body_cps_provider_2_dst_skip_jobs(v_1001062, v_1001063), v_1001072 => +v_1001064 = template_unbox(List<&2, cps_provider_2_Job>, v_1001072); template_continuation_298(v_17, v_8, v_3, v_1001061, v_1001064)}}

def template_continuation_300(+v_17: cps_provider_2_Src, +v_8: Nat, +v_3: Nat, +v_1001079: List<&2, cps_provider_2_Job>, +v_1001080: List<&2, cps_provider_2_Job>, +v_1001083: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001084 = {v_17 : cps_provider_2_Src}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_pad{v_8, v_3}}, False{}, v_1001090 => template_body_cps_provider_2_form_pad(v_8, v_3), v_1001089 => +v_1001085 = template_unbox(Nat, v_1001089); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_skip_jobs{v_1001084, v_1001085}}, False{}, v_1001088 => template_body_cps_provider_2_src_skip_jobs(v_1001084, v_1001085), v_1001087 => +v_1001086 = template_unbox(List<&2, cps_provider_2_Job>, v_1001087); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001079, List.append(&2, cps_provider_2_Job, v_1001080, List.append(&2, cps_provider_2_Job, v_1001083, v_1001086)))}}}}

def template_continuation_301(+v_19: cps_provider_2_Dst, +v_10: Nat, v_34: Nat, +v_17: cps_provider_2_Src, +v_8: Nat, +v_3: Nat, +v_1001079: List<&2, cps_provider_2_Job>, +v_1001080: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001081 = {v_19 : cps_provider_2_Dst}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_pad{v_10, v_34}}, False{}, v_1001094 => template_body_cps_provider_2_form_pad(v_10, v_34), v_1001093 => +v_1001082 = template_unbox(Nat, v_1001093); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_skip_jobs{v_1001081, v_1001082}}, False{}, v_1001092 => template_body_cps_provider_2_dst_skip_jobs(v_1001081, v_1001082), v_1001091 => +v_1001083 = template_unbox(List<&2, cps_provider_2_Job>, v_1001091); template_continuation_300(v_17, v_8, v_3, v_1001079, v_1001080, v_1001083)}}

def template_match_302(v_1001060: Bool, +v_1: cps_provider_2_World, +v_6: List<&2, cps_provider_1_Nest>, v_35: List<&2, cps_provider_1_Nest>, +v_17: cps_provider_2_Src, +v_19: cps_provider_2_Dst, +v_21: String, +v_10: Nat, v_34: Nat, +v_8: Nat, +v_3: Nat, v_32: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1001060:
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_field_pair_jobs{v_1, v_6, v_35, v_17, v_19, v_21, 0n}}, False{}, v_1001077 => template_body_cps_provider_2_field_pair_jobs(v_1, v_6, v_35, v_17, v_19, v_21, 0n), v_1001076 => +v_1001061 = template_unbox(List<&2, cps_provider_2_Job>, v_1001076); template_continuation_299(v_19, v_10, v_34, v_17, v_8, v_3, v_1001061)}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_mark{v_19, v_32}}, False{}, v_1001099 => template_body_cps_provider_2_dst_mark(v_19, v_32), v_1001098 => +v_1001078 = template_unbox(String, v_1001098); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1001078}}}, v_1001097 => +v_1001079 = template_unbox(List<&2, cps_provider_2_Job>, v_1001097); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_field_pair_jobs{v_1, v_6, v_35, v_17, v_19, v_21, 0n}}, False{}, v_1001096 => template_body_cps_provider_2_field_pair_jobs(v_1, v_6, v_35, v_17, v_19, v_21, 0n), v_1001095 => +v_1001080 = template_unbox(List<&2, cps_provider_2_Job>, v_1001095); template_continuation_301(v_19, v_10, v_34, v_17, v_8, v_3, v_1001079, v_1001080)}}}

def template_match_303(v_25: cps_provider_1_FormArm, +v_12: Bool, +v_1: cps_provider_2_World, +v_6: List<&2, cps_provider_1_Nest>, +v_17: cps_provider_2_Src, +v_19: cps_provider_2_Dst, +v_21: String, +v_10: Nat, +v_8: Nat, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_25:
    case cps_provider_1_FormArm{v_31, v_32, v_33, v_34, v_35}:
      template_match_302(v_12, v_1, v_6, v_35, v_17, v_19, v_21, v_10, v_34, v_8, v_3, v_32)

def template_body_cps_provider_2_forms_arm_body(+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_Nest>, +v_8: Nat, +v_10: Nat, +v_12: Bool, +v_15: Maybe<&2, cps_provider_1_FormArm>, +v_17: cps_provider_2_Src, +v_19: cps_provider_2_Dst, +v_21: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_15:
    case None{}:
      TemplateFinished{TemplateValue{[cps_provider_2_JText{"(void)err_fail(\"the inline conversion target has no arm\");"}]}}
    case Some{v_1004264}:
      template_match_303(v_1004264, v_12, v_1, v_6, v_17, v_19, v_21, v_10, v_8, v_3)

def template_continuation_305(+v_1001100: List<&2, cps_provider_2_Job>, +v_20: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["case ", Nat.show(v_20), ": {"]}}, False{}, v_1001103 => template_body_cps_provider_2_join_text(["case ", Nat.show(v_20), ": {"]), v_1001102 => +v_1001101 = template_unbox(String, v_1001102); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1001101}], List.append(&2, cps_provider_2_Job, v_1001100, [cps_provider_2_JText{"} break;"}]))}}}

def template_body_cps_provider_2_forms_arm_case(+v_1: cps_provider_2_World, +v_4: Maybe<&2, cps_provider_1_FormArm>, +v_6: cps_provider_1_FormArm, +v_8: Nat, +v_10: Nat, +v_12: Bool, +v_14: cps_provider_2_Src, +v_16: cps_provider_2_Dst, +v_18: String, +v_20: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_6:
    case cps_provider_1_FormArm{v_1004265, v_1004266, v_1004267, v_1004268, v_1004269}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_forms_arm_body{v_1, v_1004268, v_1004269, v_8, v_10, v_12, v_4, v_14, v_16, v_18}}, False{}, v_1004270 => template_body_cps_provider_2_forms_arm_body(v_1, v_1004268, v_1004269, v_8, v_10, v_12, v_4, v_14, v_16, v_18), v_1004271 => +v_1004272 = template_unbox(List<&2, cps_provider_2_Job>, v_1004271); template_continuation_305(v_1004272, v_20)}

def template_match_307(v_1001106: Bool, +v_1: String, +v_10: List<&2, cps_provider_1_FormArm>, +v_9: cps_provider_1_FormArm) -> TemplateProgress<Maybe<&2, cps_provider_1_FormArm>>:
  match v_1001106:
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_arm_by_key{v_1, v_10}}, v_1001108 => +v_1001107 = template_unbox(Maybe<&2, cps_provider_1_FormArm>, v_1001108); TemplateFinished{TemplateValue{v_1001107}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_9}}}

def template_match_308(+v_9: cps_provider_1_FormArm, +v_1: String, +v_10: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Maybe<&2, cps_provider_1_FormArm>>:
  match v_9:
    case cps_provider_1_FormArm{v_16, v_17, v_18, v_19, v_20}:
      v_22 = String.eq(v_1, v_16)
      template_match_307(v_22, v_1, v_10, v_9)

def template_body_cps_provider_2_form_arm_by_key(+v_1: String, +v_4: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<Maybe<&2, cps_provider_1_FormArm>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004273 <> +v_1004274:
      template_match_308(v_1004273, v_1, v_1004274)

def template_continuation_310(+v_1001110: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World, +v_27: List<&2, cps_provider_1_FormArm>, +v_7: List<&2, cps_provider_1_FormArm>, +v_9: Nat, +v_11: Nat, +v_13: Bool, +v_15: cps_provider_2_Src, +v_17: cps_provider_2_Dst, +v_19: String, +v_21: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_forms_cases{v_1, v_27, v_7, v_9, v_11, v_13, v_15, v_17, v_19, Nat.add(v_21, 1n)}}, v_1001113 => +v_1001112 = template_unbox(List<&2, cps_provider_2_Job>, v_1001113); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, {v_1001110 : List<&2, cps_provider_2_Job>}, v_1001112)}}}

def template_continuation_311(+v_1001109: Maybe<&2, cps_provider_1_FormArm>, +v_1: cps_provider_2_World, +v_26: cps_provider_1_FormArm, +v_9: Nat, +v_11: Nat, +v_13: Bool, +v_15: cps_provider_2_Src, +v_17: cps_provider_2_Dst, +v_19: String, +v_21: Nat, +v_27: List<&2, cps_provider_1_FormArm>, +v_7: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_40 = v_1001109
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_forms_arm_case{v_1, v_40, v_26, v_9, v_11, v_13, v_15, v_17, v_19, v_21}}, False{}, v_1001115 => template_body_cps_provider_2_forms_arm_case(v_1, v_40, v_26, v_9, v_11, v_13, v_15, v_17, v_19, v_21), v_1001114 => +v_1001110 = template_unbox(List<&2, cps_provider_2_Job>, v_1001114); template_continuation_310(v_1001110, v_1, v_27, v_7, v_9, v_11, v_13, v_15, v_17, v_19, v_21)}

def template_match_312(+v_26: cps_provider_1_FormArm, +v_7: List<&2, cps_provider_1_FormArm>, +v_1: cps_provider_2_World, +v_9: Nat, +v_11: Nat, +v_13: Bool, +v_15: cps_provider_2_Src, +v_17: cps_provider_2_Dst, +v_19: String, +v_21: Nat, +v_27: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_26:
    case cps_provider_1_FormArm{v_33, v_34, v_35, v_36, v_37}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_arm_by_key{v_33, v_7}}, False{}, v_1001117 => template_body_cps_provider_2_form_arm_by_key(v_33, v_7), v_1001116 => +v_1001109 = template_unbox(Maybe<&2, cps_provider_1_FormArm>, v_1001116); template_continuation_311(v_1001109, v_1, v_26, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_27, v_7)}

def template_body_cps_provider_2_forms_cases(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_7: List<&2, cps_provider_1_FormArm>, +v_9: Nat, +v_11: Nat, +v_13: Bool, +v_15: cps_provider_2_Src, +v_17: cps_provider_2_Dst, +v_19: String, +v_21: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004275 <> +v_1004276:
      template_match_312(v_1004275, v_7, v_1, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_1004276)

def template_continuation_314(+v_1001122: List<&2, cps_provider_2_Job>, +v_13: cps_provider_2_Src, +v_17: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_read{v_13, v_17}}, False{}, v_1001128 => template_body_cps_provider_2_src_read(v_13, v_17), v_1001127 => +v_1001123 = template_unbox(List<&2, cps_provider_2_Job>, v_1001127); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["switch ((u32)(", v_17, "w)) {"]}}, False{}, v_1001126 => template_body_cps_provider_2_join_text(["switch ((u32)(", v_17, "w)) {"]), v_1001125 => +v_1001124 = template_unbox(String, v_1001125); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001123, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1001124}], List.append(&2, cps_provider_2_Job, v_1001122, [cps_provider_2_JText{"}"}])))}}}}

def template_match_315(+v_6: List<&2, cps_provider_1_FormArm>, +v_1: cps_provider_2_World, v_26: Nat, v_29: Nat, v_22: Bool, +v_11: List<&2, cps_provider_1_FormArm>, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case [+v_31]:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_forms_single{v_1, v_31, v_26, v_29, v_22, v_11, v_13, v_15, v_17}}, v_1001121 => +v_1001120 = template_unbox(List<&2, cps_provider_2_Job>, v_1001121); TemplateFinished{TemplateValue{v_1001120}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_forms_cases{v_1, v_6, v_11, v_26, v_29, v_22, v_13, v_15, v_17, 0n}}, False{}, v_1001130 => template_body_cps_provider_2_forms_cases(v_1, v_6, v_11, v_26, v_29, v_22, v_13, v_15, v_17, 0n), v_1001129 => +v_1001122 = template_unbox(List<&2, cps_provider_2_Job>, v_1001129); template_continuation_314(v_1001122, v_13, v_17)}

def template_continuation_316(+v_1001119: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_1: cps_provider_2_World, v_26: Nat, v_22: Bool, +v_11: List<&2, cps_provider_1_FormArm>, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  template_match_315(v_6, v_1, v_26, v_1001119, v_22, v_11, v_13, v_15, v_17)

def template_continuation_317(+v_1001118: Nat, +v_8: Nat, +v_22: Bool, +v_6: List<&2, cps_provider_1_FormArm>, +v_1: cps_provider_2_World, +v_11: List<&2, cps_provider_1_FormArm>, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_base{v_8, v_22}}, False{}, v_1001132 => template_body_cps_provider_2_form_base(v_8, v_22), v_1001131 => +v_1001119 = template_unbox(Nat, v_1001131); template_continuation_316(v_1001119, v_6, v_1, v_1001118, v_22, v_11, v_13, v_15, v_17)}

def template_body_cps_provider_2_expand_forms(+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: Nat, +v_11: List<&2, cps_provider_1_FormArm>, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_22 = template_pure_cps_provider_2_form_tagged(v_11)
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_base{v_3, template_pure_cps_provider_2_form_tagged(v_6)}}, False{}, v_1001134 => template_body_cps_provider_2_form_base(v_3, template_pure_cps_provider_2_form_tagged(v_6)), v_1001133 => +v_1001118 = template_unbox(Nat, v_1001133); template_continuation_317(v_1001118, v_8, v_22, v_6, v_1, v_11, v_13, v_15, v_17)}

def template_body_cps_provider_2_forms_single(+v_1: cps_provider_2_World, +v_3: cps_provider_1_FormArm, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_12: List<&2, cps_provider_1_FormArm>, +v_14: cps_provider_2_Src, +v_16: cps_provider_2_Dst, +v_18: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case cps_provider_1_FormArm{v_1004277, v_1004278, v_1004279, v_1004280, v_1004281}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_arm_by_key{v_1004277, v_12}}, False{}, v_1004288 => template_body_cps_provider_2_form_arm_by_key(v_1004277, v_12), v_1004289 => +v_1004290 = template_unbox(Maybe<&2, cps_provider_1_FormArm>, v_1004289); template_body_cps_provider_2_forms_arm_body({v_1 : cps_provider_2_World}, {v_1004280 : Nat}, {v_1004281 : List<&2, cps_provider_1_Nest>}, {v_5 : Nat}, {v_7 : Nat}, {v_9 : Bool}, v_1004290, v_14, v_16, v_18)}

def template_continuation_319(+v_1001151: String, +v_3: Nat, +v_7: String, +v_9: String, +v_1: U32) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 ", v_1001151, " = heap_alloc(e, cls_fit(", Nat.show(v_3), ")); for (u32 ", v_1001151, "i = 0; ", v_1001151, "i < ", Nat.show(v_3), "; ", v_1001151, "i += 1) { e.mem[", v_1001151, " + ", v_1001151, "i] = ", v_7, "[", v_1001151, "i]; } ", v_9, " = term_ctr(", U32.show(v_1), "u, ", v_1001151, ");"]}}, False{}, v_1001154 => template_body_cps_provider_2_join_text(["u64 ", v_1001151, " = heap_alloc(e, cls_fit(", Nat.show(v_3), ")); for (u32 ", v_1001151, "i = 0; ", v_1001151, "i < ", Nat.show(v_3), "; ", v_1001151, "i += 1) { e.mem[", v_1001151, " + ", v_1001151, "i] = ", v_7, "[", v_1001151, "i]; } ", v_9, " = term_ctr(", U32.show(v_1), "u, ", v_1001151, ");"]), v_1001153 => +v_1001152 = template_unbox(String, v_1001153); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1001152}]}}}

def template_match_320(+v_5: Bool, +v_9: String, +v_1: U32, +v_7: String, +v_11: String, +v_3: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_5:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, " = term_pak(", U32.show(v_1), "u, (u64)", v_7, "[0]);"]}}, False{}, v_1001150 => template_body_cps_provider_2_join_text([v_9, " = term_pak(", U32.show(v_1), "u, (u64)", v_7, "[0]);"]), v_1001149 => +v_1001148 = template_unbox(String, v_1001149); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1001148}]}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_11, "l"]}}, False{}, v_1001156 => template_body_cps_provider_2_join_text([v_11, "l"]), v_1001155 => +v_1001151 = template_unbox(String, v_1001155); template_continuation_319(v_1001151, v_3, v_7, v_9, v_1)}

def template_body_cps_provider_2_pack_jobs(+v_1: U32, +v_3: Nat, +v_5: Bool, +v_7: String, +v_9: String, +v_11: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case 0n:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, " = term_pak(", U32.show(v_1), "u, 0);"]}}, False{}, v_1004291 => template_body_cps_provider_2_join_text([v_9, " = term_pak(", U32.show(v_1), "u, 0);"]), v_1004292 => +v_1004293 = template_unbox(String, v_1004292); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004293}]}}}
    case v_1004294:
      template_match_320(v_5, v_9, v_1, v_7, v_11, v_3)

def template_continuation_322(+v_9: cps_provider_2_Src, +v_7: Nat, +v_26: Nat, +v_3: U32, v_25: Bool, v_30: String, +v_11: String, +v_13: String, +v_1001160: List<&2, cps_provider_2_Job>, +v_1001166: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001167 = {v_9 : cps_provider_2_Src}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_pad{v_7, v_26}}, False{}, v_1001176 => template_body_cps_provider_2_form_pad(v_7, v_26), v_1001175 => +v_1001168 = template_unbox(Nat, v_1001175); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_skip_jobs{v_1001167, v_1001168}}, False{}, v_1001174 => template_body_cps_provider_2_src_skip_jobs(v_1001167, v_1001168), v_1001173 => +v_1001169 = template_unbox(List<&2, cps_provider_2_Job>, v_1001173); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_pack_jobs{v_3, v_26, v_25, v_30, v_11, v_13}}, False{}, v_1001172 => template_body_cps_provider_2_pack_jobs(v_3, v_26, v_25, v_30, v_11, v_13), v_1001171 => +v_1001170 = template_unbox(List<&2, cps_provider_2_Job>, v_1001171); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001160, List.append(&2, cps_provider_2_Job, v_1001166, List.append(&2, cps_provider_2_Job, v_1001169, v_1001170)))}}}}}

def template_continuation_323(+v_1: cps_provider_2_World, v_27: List<&2, cps_provider_1_Nest>, +v_9: cps_provider_2_Src, +v_30: String, v_33: String, +v_13: String, +v_15: Nat, +v_7: Nat, v_26: Nat, +v_3: U32, v_25: Bool, +v_11: String, +v_1001160: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001161 = {v_1 : cps_provider_2_World}
  +v_1001162 = {v_27 : List<&2, cps_provider_1_Nest>}
  +v_1001163 = {v_9 : cps_provider_2_Src}
  +v_1001164 = {cps_provider_2_DstSeq{v_30, v_33} : cps_provider_2_Dst}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_13, "x", Nat.show(v_15)]}}, False{}, v_1001180 => template_body_cps_provider_2_join_text([v_13, "x", Nat.show(v_15)]), v_1001179 => +v_1001165 = template_unbox(String, v_1001179); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_nests_jobs{v_1001161, v_1001162, v_1001163, v_1001164, v_1001165, 0n}}, False{}, v_1001178 => template_body_cps_provider_2_nests_jobs(v_1001161, v_1001162, v_1001163, v_1001164, v_1001165, 0n), v_1001177 => +v_1001166 = template_unbox(List<&2, cps_provider_2_Job>, v_1001177); template_continuation_322(v_9, v_7, v_26, v_3, v_25, v_30, v_11, v_13, v_1001160, v_1001166)}}

def template_continuation_324(+v_1001158: String, +v_30: String, +v_26: Nat, +v_1: cps_provider_2_World, v_27: List<&2, cps_provider_1_Nest>, +v_9: cps_provider_2_Src, +v_13: String, +v_15: Nat, +v_7: Nat, +v_3: U32, v_25: Bool, +v_11: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_decl{v_30, v_1001158, v_26}}, False{}, v_1001183 => template_body_cps_provider_2_dst_decl(v_30, v_1001158, v_26), v_1001182 => +v_1001159 = template_unbox(String, v_1001182); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1001159}}}, v_1001181 => +v_1001160 = template_unbox(List<&2, cps_provider_2_Job>, v_1001181); template_continuation_323(v_1, v_27, v_9, v_30, v_1001158, v_13, v_15, v_7, v_26, v_3, v_25, v_11, v_1001160)}}

def template_continuation_325(+v_1001157: String, +v_13: String, v_26: Nat, +v_1: cps_provider_2_World, v_27: List<&2, cps_provider_1_Nest>, +v_9: cps_provider_2_Src, +v_15: Nat, +v_7: Nat, +v_3: U32, v_25: Bool, +v_11: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_13, "j"]}}, False{}, v_1001185 => template_body_cps_provider_2_join_text([v_13, "j"]), v_1001184 => +v_1001158 = template_unbox(String, v_1001184); template_continuation_324(v_1001158, v_1001157, v_26, v_1, v_27, v_9, v_13, v_15, v_7, v_3, v_25, v_11)}

def template_body_cps_provider_2_arm_block_jobs(+v_1: cps_provider_2_World, +v_3: U32, +v_5: cps_provider_1_FormArm, +v_7: Nat, +v_9: cps_provider_2_Src, +v_11: String, +v_13: String, +v_15: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_5:
    case cps_provider_1_FormArm{v_1004295, v_1004296, v_1004297, v_1004298, v_1004299}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_13, "w"]}}, False{}, v_1004300 => template_body_cps_provider_2_join_text([v_13, "w"]), v_1004301 => +v_1004302 = template_unbox(String, v_1004301); template_continuation_325(v_1004302, v_13, v_1004298, v_1, v_1004299, v_9, v_15, v_7, v_3, v_1004297, v_11)}

def template_body_cps_provider_2_box_arm_jobs(+v_1: cps_provider_2_World, +v_4: Maybe<&2, U32>, +v_6: cps_provider_1_FormArm, +v_8: Nat, +v_10: cps_provider_2_Src, +v_12: String, +v_14: String, +v_16: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case None{}:
      TemplateFinished{TemplateValue{[cps_provider_2_JText{"default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;"}]}}
    case Some{v_1004303}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["case ", Nat.show(v_16), ": {"]}}, False{}, v_1004304 => template_body_cps_provider_2_join_text(["case ", Nat.show(v_16), ": {"]), v_1004305 => +v_1004306 = template_unbox(String, v_1004305); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_arm_block_jobs{v_1, v_1004303, v_6, v_8, v_10, v_12, v_14, v_16}}, False{}, v_1004307 => template_body_cps_provider_2_arm_block_jobs(v_1, v_1004303, v_6, v_8, v_10, v_12, v_14, v_16), v_1004308 => +v_1004309 = template_unbox(List<&2, cps_provider_2_Job>, v_1004308); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1004306}], List.append(&2, cps_provider_2_Job, v_1004309, [cps_provider_2_JText{"} break;"}]))}}}}

def template_continuation_328(+v_1001195: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World, +v_20: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String, +v_14: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_box_cases{v_1, v_20, v_6, v_8, v_10, v_12, Nat.add(v_14, 1n)}}, v_1001198 => +v_1001197 = template_unbox(List<&2, cps_provider_2_Job>, v_1001198); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, {v_1001195 : List<&2, cps_provider_2_Job>}, v_1001197)}}}

def template_continuation_329(+v_1001194: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_19: cps_provider_1_FormArm, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String, +v_14: Nat, +v_20: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_33 = v_1001194
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_box_arm_jobs{v_1, v_33, v_19, v_6, v_8, v_10, v_12, v_14}}, False{}, v_1001200 => template_body_cps_provider_2_box_arm_jobs(v_1, v_33, v_19, v_6, v_8, v_10, v_12, v_14), v_1001199 => +v_1001195 = template_unbox(List<&2, cps_provider_2_Job>, v_1001199); template_continuation_328(v_1001195, v_1, v_20, v_6, v_8, v_10, v_12, v_14)}

def template_match_330(+v_19: cps_provider_1_FormArm, +v_1: cps_provider_2_World, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String, +v_14: Nat, +v_20: List<&2, cps_provider_1_FormArm>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_19:
    case cps_provider_1_FormArm{v_26, v_27, v_28, v_29, v_30}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_26, v_1}}, False{}, v_1001202 => template_body_cps_provider_2_cid_of(v_26, v_1), v_1001201 => +v_1001194 = template_unbox(Maybe<&2, U32>, v_1001201); template_continuation_329(v_1001194, v_1, v_19, v_6, v_8, v_10, v_12, v_14, v_20)}

def template_body_cps_provider_2_box_cases(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String, +v_14: Nat) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004310 <> +v_1004311:
      template_match_330(v_1004310, v_1, v_6, v_8, v_10, v_12, v_14, v_1004311)

def template_match_332(+v_1001203: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_16: cps_provider_1_FormArm, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1001203:
    case None{}:
      TemplateFinished{TemplateValue{[cps_provider_2_JText{"(void)err_fail(\"the constructor tag is not a declared constructor\");"}]}}
    case Some{v_29}:
      template_body_cps_provider_2_arm_block_jobs(v_1, v_29, v_16, v_6, v_8, v_10, v_12, 0n)

def template_match_333(+v_16: cps_provider_1_FormArm, +v_1: cps_provider_2_World, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_16:
    case cps_provider_1_FormArm{v_22, v_23, v_24, v_25, v_26}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_22, v_1}}, False{}, v_1001206 => template_body_cps_provider_2_cid_of(v_22, v_1), v_1001205 => +v_1001203 = template_unbox(Maybe<&2, U32>, v_1001205); template_match_332(v_1001203, v_1, v_16, v_6, v_8, v_10, v_12)}

def template_body_cps_provider_2_box_untagged(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case [+v_1004312]:
      template_match_333(v_1004312, v_1, v_6, v_8, v_10, v_12)
    case v_1004313:
      TemplateFinished{TemplateValue{[]}}

def template_continuation_335(+v_1001208: Nat, +v_17: String, v_20: Bool, +v_1: cps_provider_2_World, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: cps_provider_2_Src, +v_10: cps_provider_2_Dst, +v_12: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term ", v_17, " = 0;"]}}, False{}, v_1001213 => template_body_cps_provider_2_join_text(["Term ", v_17, " = 0;"]), v_1001212 => +v_1001209 = template_unbox(String, v_1001212); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_expand_box_body{v_20, v_1001208, v_1, v_6, v_8, v_10, v_12, v_17}}, v_1001211 => +v_1001210 = template_unbox(List<&2, cps_provider_2_Job>, v_1001211); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1001209}], v_1001210)}}}}

def template_continuation_336(+v_1001207: String, +v_6: List<&2, cps_provider_1_FormArm>, +v_3: Nat, +v_1: cps_provider_2_World, +v_8: cps_provider_2_Src, +v_10: cps_provider_2_Dst, +v_12: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_20 = template_pure_cps_provider_2_form_tagged(v_6)
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_form_base{v_3, v_20}}, False{}, v_1001215 => template_body_cps_provider_2_form_base(v_3, v_20), v_1001214 => +v_1001208 = template_unbox(Nat, v_1001214); template_continuation_335(v_1001208, v_1001207, v_20, v_1, v_6, v_8, v_10, v_12)}

def template_body_cps_provider_2_expand_box(+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: cps_provider_2_Src, +v_10: cps_provider_2_Dst, +v_12: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_12, "r"]}}, False{}, v_1001217 => template_body_cps_provider_2_join_text([v_12, "r"]), v_1001216 => +v_1001207 = template_unbox(String, v_1001216); template_continuation_336(v_1001207, v_6, v_3, v_1, v_8, v_10, v_12)}

def template_continuation_337(+v_12: cps_provider_2_Dst, +v_16: String, +v_1001218: List<&2, cps_provider_2_Job>, +v_1001219: String, +v_1001220: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_1001221 = {[cps_provider_2_JText{"}"}] : List<&2, cps_provider_2_Job>}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_write{v_12, v_16}}, False{}, v_1001224 => template_body_cps_provider_2_dst_write(v_12, v_16), v_1001223 => +v_1001222 = template_unbox(List<&2, cps_provider_2_Job>, v_1001223); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001218, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1001219}], List.append(&2, cps_provider_2_Job, v_1001220, List.append(&2, cps_provider_2_Job, v_1001221, v_1001222))))}}}

def template_body_cps_provider_2_expand_box_body(+v_1: Bool, +v_3: Nat, +v_5: cps_provider_2_World, +v_8: List<&2, cps_provider_1_FormArm>, +v_10: cps_provider_2_Src, +v_12: cps_provider_2_Dst, +v_14: String, +v_16: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_read{v_10, v_14}}, False{}, v_1004314 => template_body_cps_provider_2_src_read(v_10, v_14), v_1004315 => +v_1004316 = template_unbox(List<&2, cps_provider_2_Job>, v_1004315); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["switch ((u32)(", v_14, "w)) {"]}}, False{}, v_1004317 => template_body_cps_provider_2_join_text(["switch ((u32)(", v_14, "w)) {"]), v_1004318 => +v_1004319 = template_unbox(String, v_1004318); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_box_cases{v_5, v_8, v_3, v_10, v_16, v_14, 0n}}, False{}, v_1004320 => template_body_cps_provider_2_box_cases(v_5, v_8, v_3, v_10, v_16, v_14, 0n), v_1004321 => +v_1004322 = template_unbox(List<&2, cps_provider_2_Job>, v_1004321); template_continuation_337(v_12, v_16, v_1004316, v_1004319, v_1004322)}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_box_untagged{v_5, v_8, v_3, v_10, v_16, v_14}}, False{}, v_1004323 => template_body_cps_provider_2_box_untagged(v_5, v_8, v_3, v_10, v_16, v_14), v_1004324 => +v_1004325 = template_unbox(List<&2, cps_provider_2_Job>, v_1004324); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_write{v_12, v_16}}, False{}, v_1004326 => template_body_cps_provider_2_dst_write(v_12, v_16), v_1004327 => +v_1004328 = template_unbox(List<&2, cps_provider_2_Job>, v_1004327); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1004325, v_1004328)}}}}

def template_body_cps_provider_2_expand_form_take(+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: cps_provider_1_Fill, +v_10: cps_provider_2_Src, +v_12: cps_provider_2_Dst, +v_14: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_8:
    case cps_provider_1_FillWord{}:
      template_body_cps_provider_2_expand_box(v_1, v_3, v_6, v_10, v_12, v_14)
    case cps_provider_1_FillForm{v_1004329, v_1004330}:
      template_body_cps_provider_2_expand_forms(v_1, v_3, v_6, v_1004329, v_1004330, v_10, v_12, v_14)

def template_body_cps_provider_2_expand_conv(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Unfill, +v_5: cps_provider_1_Fill, +v_7: cps_provider_2_Src, +v_9: cps_provider_2_Dst, +v_11: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case cps_provider_1_UnfillWord{}:
      template_body_cps_provider_2_expand_word_take(v_1, v_5, v_7, v_9, v_11)
    case cps_provider_1_UnfillForm{v_1004331, v_1004332}:
      template_body_cps_provider_2_expand_form_take(v_1, v_1004331, v_1004332, v_5, v_7, v_9, v_11)

def template_match_341(+v_12: cps_provider_2_Job, +v_13: List<&2, cps_provider_2_Job>, +v_4: cps_provider_2_World, +v_7: List<&2, String>) -> TemplateProgress<cps_provider_2_Code>:
  match v_12:
    case cps_provider_2_JText{v_15}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_13, v_4, List.append(&2, String, v_7, [v_15])}}, v_1001242 => +v_1001241 = template_unbox(cps_provider_2_Code, v_1001242); TemplateFinished{TemplateValue{v_1001241}}}
    case cps_provider_2_JFail{v_19}:
      TemplateFinished{TemplateValue{cps_provider_2_CodeFail{v_19}}}
    case cps_provider_2_JConv{v_25, v_26, v_27, v_28, v_29}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_expand_conv{v_4, v_25, v_26, v_27, v_28, v_29}}, False{}, v_1001247 => template_body_cps_provider_2_expand_conv(v_4, v_25, v_26, v_27, v_28, v_29), v_1001246 => +v_1001243 = template_unbox(List<&2, cps_provider_2_Job>, v_1001246); TemplatePending{TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{List.append(&2, cps_provider_2_Job, v_1001243, v_13), v_4, v_7}}, v_1001245 => +v_1001244 = template_unbox(cps_provider_2_Code, v_1001245); TemplateFinished{TemplateValue{v_1001244}}}}

def template_body_cps_provider_2_run_jobs(+v_2: List<&2, cps_provider_2_Job>, +v_4: cps_provider_2_World, +v_7: List<&2, String>) -> TemplateProgress<cps_provider_2_Code>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_CodeOk{v_7}}}
    case +v_1004333 <> +v_1004334:
      template_match_341(v_1004333, v_1004334, v_4, v_7)

def template_body_cps_provider_2_fill_plan_jobs(+v_1: cps_provider_1_Fill, +v_3: String, +v_5: cps_provider_2_Dst, +v_7: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_1_FillWord{}:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{"a data layout produced a one-word fill"}]}}
    case cps_provider_1_FillForm{v_12, v_13}:
      TemplateFinished{TemplateValue{[cps_provider_2_JConv{cps_provider_1_UnfillWord{}, v_1, cps_provider_2_SrcOne{v_3}, v_5, v_7}]}}

def template_body_cps_provider_2_fill_result_jobs(+v_1: cps_provider_1_FillResult, +v_3: String, +v_5: cps_provider_2_Dst, +v_7: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_1_FillFailed{v_11}:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{v_11}]}}
    case cps_provider_1_FillFound{v_13}:
      template_body_cps_provider_2_fill_plan_jobs(v_13, v_3, v_5, v_7)

def template_continuation_345(+v_1001249: cps_provider_1_FillResult, +v_5: String, +v_7: cps_provider_2_Dst, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  template_body_cps_provider_2_fill_result_jobs(v_1001249, v_5, v_7, v_9)

def template_body_cps_provider_2_fill_data_jobs(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: cps_provider_2_Dst, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_2_World{v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_fill{v_15, v_3}}, False{}, v_1001252 => template_body_cps_provider_1_layout_fill(v_15, v_3), v_1001251 => +v_1001249 = template_unbox(cps_provider_1_FillResult, v_1001251); template_continuation_345(v_1001249, v_5, v_7, v_9)}

def template_body_cps_provider_2_fill_jobs(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: cps_provider_2_Dst, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case cps_provider_1_LayoutWord{v_1004335}:
      template_body_cps_provider_2_dst_word(v_7, v_1004335, v_5)
    case cps_provider_1_LayoutBox{v_1004336}:
      template_body_cps_provider_2_dst_write(v_7, v_5)
    case cps_provider_1_LayoutData{v_1004337, v_1004338}:
      template_body_cps_provider_2_fill_data_jobs(v_1, v_3, v_5, v_7, v_9)

def template_body_cps_provider_2_unfill_result_jobs(+v_1: cps_provider_1_UnfillResult, +v_3: cps_provider_2_Src, +v_5: String, +v_7: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_1_UnfillFailed{v_11}:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{v_11}]}}
    case cps_provider_1_UnfillFound{v_13}:
      TemplateFinished{TemplateValue{[cps_provider_2_JConv{v_13, cps_provider_1_FillWord{}, v_3, cps_provider_2_DstOut{v_5}, v_7}]}}

def template_continuation_349(+v_1001256: cps_provider_1_UnfillResult, +v_5: cps_provider_2_Src, +v_7: String, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  template_body_cps_provider_2_unfill_result_jobs(v_1001256, v_5, v_7, v_9)

def template_body_cps_provider_2_unfill_data_jobs(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: cps_provider_2_Src, +v_7: String, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_2_World{v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_unfill{v_15, v_3}}, False{}, v_1001259 => template_body_cps_provider_1_layout_unfill(v_15, v_3), v_1001258 => +v_1001256 = template_unbox(cps_provider_1_UnfillResult, v_1001258); template_continuation_349(v_1001256, v_5, v_7, v_9)}

def template_body_cps_provider_2_unfill_word_jobs(+v_1: cps_provider_1_CWord, +v_3: cps_provider_2_Src, +v_5: String, +v_7: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_read{v_3, v_7}}, False{}, v_1004339 => template_body_cps_provider_2_src_read(v_3, v_7), v_1004340 => +v_1004341 = template_unbox(List<&2, cps_provider_2_Job>, v_1004340); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_5, " = ((u64)(u32)(", v_7, "w));"]}}, False{}, v_1004342 => template_body_cps_provider_2_join_text([v_5, " = ((u64)(u32)(", v_7, "w));"]), v_1004343 => +v_1004344 = template_unbox(String, v_1004343); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1004341, [cps_provider_2_JText{v_1004344}])}}}}
    case v_1004345:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_read{v_3, v_7}}, False{}, v_1004346 => template_body_cps_provider_2_src_read(v_3, v_7), v_1004347 => +v_1004348 = template_unbox(List<&2, cps_provider_2_Job>, v_1004347); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_5, " = ", v_7, "w;"]}}, False{}, v_1004349 => template_body_cps_provider_2_join_text([v_5, " = ", v_7, "w;"]), v_1004350 => +v_1004351 = template_unbox(String, v_1004350); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1004348, [cps_provider_2_JText{v_1004351}])}}}}

def template_body_cps_provider_2_unfill_jobs(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: cps_provider_2_Src, +v_7: String, +v_9: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case cps_provider_1_LayoutWord{v_1004352}:
      template_body_cps_provider_2_unfill_word_jobs(v_1004352, v_5, v_7, v_9)
    case cps_provider_1_LayoutBox{v_1004353}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_src_read{v_5, v_9}}, False{}, v_1004354 => template_body_cps_provider_2_src_read(v_5, v_9), v_1004355 => +v_1004356 = template_unbox(List<&2, cps_provider_2_Job>, v_1004355); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_7, " = ", v_9, "w;"]}}, False{}, v_1004357 => template_body_cps_provider_2_join_text([v_7, " = ", v_9, "w;"]), v_1004358 => +v_1004359 = template_unbox(String, v_1004358); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1004356, [cps_provider_2_JText{v_1004359}])}}}}
    case cps_provider_1_LayoutData{v_1004360, v_1004361}:
      template_body_cps_provider_2_unfill_data_jobs(v_1, v_3, v_5, v_7, v_9)

def template_match_353(+v_2: BIR.Use, +v_6: String, +v_4: String) -> TemplateProgress<cps_provider_2_Code>:
  match v_2:
    case BIR.Many{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term ", v_6, "v = term_keep(e, ", v_4, ", 1);"]}}, False{}, v_1001283 => template_body_cps_provider_2_join_text(["Term ", v_6, "v = term_keep(e, ", v_4, ", 1);"]), v_1001282 => +v_1001280 = template_unbox(String, v_1001282); template_body_cps_provider_2_code_line(v_1001280)}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_code_empty{}}, False{}, v_1001286 => template_body_cps_provider_2_code_empty, v_1001285 => +v_1001284 = template_unbox(cps_provider_2_Code, v_1001285); TemplateFinished{TemplateValue{v_1001284}}}

def template_body_cps_provider_2_operand_code(+v_1: cps_provider_1_Layout, +v_2: BIR.Use, +v_4: String, +v_6: String) -> TemplateProgress<cps_provider_2_Code>:
  match v_1:
    case cps_provider_1_LayoutData{v_1004362, v_1004363}:
      template_match_353(v_2, v_6, v_4)
    case v_1004364:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_code_empty{}}, False{}, v_1004365 => template_body_cps_provider_2_code_empty, v_1004366 => +v_1004367 = template_unbox(cps_provider_2_Code, v_1004366); TemplateFinished{TemplateValue{v_1004367}}}

def template_match_355(+v_2: BIR.Use, +v_6: String, +v_4: String) -> TemplateProgress<String>:
  match v_2:
    case BIR.Many{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_6, "v"]}}, False{}, v_1001292 => template_body_cps_provider_2_join_text([v_6, "v"]), v_1001291 => +v_1001290 = template_unbox(String, v_1001291); TemplateFinished{TemplateValue{v_1001290}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(", v_4, ")"]}}, False{}, v_1001295 => template_body_cps_provider_2_join_text(["(", v_4, ")"]), v_1001294 => +v_1001293 = template_unbox(String, v_1001294); TemplateFinished{TemplateValue{v_1001293}}}

def template_body_cps_provider_2_operand_name(+v_1: cps_provider_1_Layout, +v_2: BIR.Use, +v_4: String, +v_6: String) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_1_LayoutData{v_1004368, v_1004369}:
      template_match_355(v_2, v_6, v_4)
    case v_1004370:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(", v_4, ")"]}}, False{}, v_1004371 => template_body_cps_provider_2_join_text(["(", v_4, ")"]), v_1004372 => +v_1004373 = template_unbox(String, v_1004372); TemplateFinished{TemplateValue{v_1004373}}}

def template_body_cps_provider_2_text_jobs(+v_2: List<&2, String>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_7 <> +v_8:
      v_1001299 = {[cps_provider_2_JText{v_7}] : List<&2, cps_provider_2_Job>}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_text_jobs{v_8}}, v_1001301 => +v_1001300 = template_unbox(List<&2, cps_provider_2_Job>, v_1001301); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001299, v_1001300)}}}

def template_body_cps_provider_2_code_jobs(+v_1: cps_provider_2_Code) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_1:
    case cps_provider_2_CodeFail{v_5}:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{v_5}]}}
    case cps_provider_2_CodeOk{v_7}:
      template_body_cps_provider_2_text_jobs(v_7)

def template_match_359(+v_7: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case _:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{"the constructor's slots and fields differ"}]}}

def template_continuation_360(+v_1001305: String, v_35: cps_provider_2_Code, +v_1: cps_provider_2_World, v_25: cps_provider_1_Layout, v_32: String, +v_15: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_38 = v_1001305
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_code_jobs{v_35}}, False{}, v_1001313 => template_body_cps_provider_2_code_jobs(v_35), v_1001312 => +v_1001306 = template_unbox(List<&2, cps_provider_2_Job>, v_1001312); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_fill_jobs{v_1, v_25, v_38, cps_provider_2_DstSeq{"w0", "o0"}, v_32}}, False{}, v_1001311 => template_body_cps_provider_2_fill_jobs(v_1, v_25, v_38, cps_provider_2_DstSeq{"w0", "o0"}, v_32), v_1001310 => +v_1001307 = template_unbox(List<&2, cps_provider_2_Job>, v_1001310); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_fill_slots_jobs{v_1, v_15, v_19}}, v_1001309 => +v_1001308 = template_unbox(List<&2, cps_provider_2_Job>, v_1001309); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001306, List.append(&2, cps_provider_2_Job, v_1001307, v_1001308))}}}}}

def template_continuation_361(+v_1001304: cps_provider_2_Code, +v_25: cps_provider_1_Layout, v_28: BIR.Use, v_29: String, +v_32: String, +v_1: cps_provider_2_World, +v_15: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_operand_name{v_25, v_28, v_29, v_32}}, False{}, v_1001315 => template_body_cps_provider_2_operand_name(v_25, v_28, v_29, v_32), v_1001314 => +v_1001305 = template_unbox(String, v_1001314); template_continuation_360(v_1001305, v_1001304, v_1, v_25, v_32, v_15, v_19)}

def template_continuation_362(+v_1001303: String, +v_25: cps_provider_1_Layout, +v_28: BIR.Use, +v_29: String, +v_1: cps_provider_2_World, +v_15: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_operand_code{v_25, v_28, v_29, v_1001303}}, False{}, v_1001317 => template_body_cps_provider_2_operand_code(v_25, v_28, v_29, v_1001303), v_1001316 => +v_1001304 = template_unbox(cps_provider_2_Code, v_1001316); template_continuation_361(v_1001304, v_25, v_28, v_29, v_1001303, v_1, v_15, v_19)}

def template_match_363(+v_18: cps_provider_2_Operand, v_23: U32, v_25: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_15: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_18:
    case cps_provider_2_Operand{v_28, v_29}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["s", U32.show(v_23)]}}, False{}, v_1001319 => template_body_cps_provider_2_join_text(["s", U32.show(v_23)]), v_1001318 => +v_1001303 = template_unbox(String, v_1001318); template_continuation_362(v_1001303, v_25, v_28, v_29, v_1, v_15, v_19)}

def template_match_364(+v_14: cps_provider_1_NodeSlot, +v_18: cps_provider_2_Operand, +v_1: cps_provider_2_World, +v_15: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_14:
    case cps_provider_1_NodeSlot{v_23, v_24, v_25}:
      template_match_363(v_18, v_23, v_25, v_1, v_15, v_19)

def template_match_365(+v_7: List<&2, cps_provider_2_Operand>, +v_14: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_15: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{[cps_provider_2_JFail{"the constructor's slots and fields differ"}]}}
    case +v_18 <> +v_19:
      template_match_364(v_14, v_18, v_1, v_15, v_19)

def template_body_cps_provider_2_fill_slots_jobs(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      template_match_359(v_7)
    case +v_1004374 <> +v_1004375:
      template_match_365(v_7, v_1004374, v_1, v_1004375)

def template_body_cps_provider_2_layout_is_data(+v_1: cps_provider_1_Layout) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_layout_is_data(v_1)}}

def template_body_cps_provider_2_seal_box_many(+v_1: String, +v_3: Bool) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1, " += 1;"]}}, False{}, v_1004376 => template_body_cps_provider_2_join_text([v_1, " += 1;"]), v_1004377 => +v_1004378 = template_unbox(String, v_1004377); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004378}]}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["w0[", v_1, "] = term_keep(e, w0[", v_1, "], 1); ", v_1, " += 1;"]}}, False{}, v_1004379 => template_body_cps_provider_2_join_text(["w0[", v_1, "] = term_keep(e, w0[", v_1, "], 1); ", v_1, " += 1;"]), v_1004380 => +v_1004381 = template_unbox(String, v_1004380); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004381}]}}}

def template_body_cps_provider_2_seal_box(+v_0: BIR.Use, +v_2: String, +v_4: Bool) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_0:
    case BIR.Many{}:
      template_body_cps_provider_2_seal_box_many(v_2, v_4)
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["w0[", v_2, "] = rfc_seal(e, w0[", v_2, "]); ", v_2, " += 1;"]}}, False{}, v_1001329 => template_body_cps_provider_2_join_text(["w0[", v_2, "] = rfc_seal(e, w0[", v_2, "]); ", v_2, " += 1;"]), v_1001328 => +v_1001327 = template_unbox(String, v_1001328); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1001327}]}}}

def template_body_cps_provider_2_seal_kind(+v_0: BIR.Use, +v_2: cps_provider_1_CWord, +v_4: String, +v_6: Bool) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_2:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_4, " += 1;"]}}, False{}, v_1004382 => template_body_cps_provider_2_join_text([v_4, " += 1;"]), v_1004383 => +v_1004384 = template_unbox(String, v_1004383); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004384}]}}}
    case cps_provider_1_CWord64{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_4, " += 1;"]}}, False{}, v_1004385 => template_body_cps_provider_2_join_text([v_4, " += 1;"]), v_1004386 => +v_1004387 = template_unbox(String, v_1004386); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004387}]}}}
    case cps_provider_1_CWordBox{}:
      template_body_cps_provider_2_seal_box(v_0, v_4, v_6)

def template_body_cps_provider_2_seal_kind_walk(+v_0: BIR.Use, +v_3: List<&2, cps_provider_1_CWord>, +v_5: String, +v_7: Bool) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004388 <> +v_1004389:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_seal_kind{v_0, v_1004388, v_5, v_7}}, False{}, v_1004390 => template_body_cps_provider_2_seal_kind(v_0, v_1004388, v_5, v_7), v_1004391 => +v_1004392 = template_unbox(List<&2, cps_provider_2_Job>, v_1004391); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_seal_kind_walk{v_0, v_1004389, v_5, v_7}}, v_1004393 => +v_1004394 = template_unbox(List<&2, cps_provider_2_Job>, v_1004393); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1004392, v_1004394)}}}}

def template_match_371(+v_7: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_7:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case _:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JFail{"the constructor's slots and fields differ"}}}, v_1001343 => +v_1001342 = template_unbox(List<&2, cps_provider_2_Job>, v_1001343); TemplateFinished{TemplateValue{v_1001342}}}

def template_continuation_372(v_30: BIR.Use, +v_27: cps_provider_1_Layout, v_25: U32, +v_1: cps_provider_2_World, +v_16: List<&2, cps_provider_1_NodeSlot>, +v_21: List<&2, cps_provider_2_Operand>, +v_1001346: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1001347 = {v_30 : BIR.Use}
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_kinds{v_27}}, False{}, v_1001355 => template_body_cps_provider_1_layout_kinds(v_27), v_1001354 => +v_1001348 = template_unbox(List<&2, cps_provider_1_CWord>, v_1001354); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_seal_kind_walk{v_1001347, v_1001348, String.append("k", U32.show(v_25)), template_pure_cps_provider_2_layout_is_data(v_27)}}, False{}, v_1001353 => template_body_cps_provider_2_seal_kind_walk(v_1001347, v_1001348, String.append("k", U32.show(v_25)), template_pure_cps_provider_2_layout_is_data(v_27)), v_1001352 => +v_1001349 = template_unbox(List<&2, cps_provider_2_Job>, v_1001352); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_seal_slots_jobs{v_1, v_16, v_21}}, v_1001351 => +v_1001350 = template_unbox(List<&2, cps_provider_2_Job>, v_1001351); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1001346, List.append(&2, cps_provider_2_Job, v_1001349, v_1001350))}}}}}

def template_match_373(+v_20: cps_provider_2_Operand, +v_25: U32, v_26: Nat, v_27: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_16: List<&2, cps_provider_1_NodeSlot>, +v_21: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_20:
    case cps_provider_2_Operand{v_30, v_31}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{String.append(String.append(String.append(String.append("u32 k", U32.show(v_25)), " = "), Nat.show(v_26)), ";")}}}, v_1001356 => +v_1001346 = template_unbox(List<&2, cps_provider_2_Job>, v_1001356); template_continuation_372(v_30, v_27, v_25, v_1, v_16, v_21, v_1001346)}

def template_match_374(+v_15: cps_provider_1_NodeSlot, +v_20: cps_provider_2_Operand, +v_1: cps_provider_2_World, +v_16: List<&2, cps_provider_1_NodeSlot>, +v_21: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_15:
    case cps_provider_1_NodeSlot{v_25, v_26, v_27}:
      template_match_373(v_20, v_25, v_26, v_27, v_1, v_16, v_21)

def template_match_375(+v_7: List<&2, cps_provider_2_Operand>, +v_15: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_16: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_7:
    case []:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JFail{"the constructor's slots and fields differ"}}}, v_1001345 => +v_1001344 = template_unbox(List<&2, cps_provider_2_Job>, v_1001345); TemplateFinished{TemplateValue{v_1001344}}}
    case +v_20 <> +v_21:
      template_match_374(v_15, v_20, v_1, v_16, v_21)

def template_body_cps_provider_2_seal_slots_jobs(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, cps_provider_2_Operand>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      template_match_371(v_7)
    case +v_1004395 <> +v_1004396:
      template_match_375(v_7, v_1004395, v_1, v_1004396)

def template_body_cps_provider_2_one_job(+v_1: cps_provider_2_Job) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateFinished{TemplateValue{[v_1]}}

def template_continuation_377(+v_1001358: List<&2, cps_provider_2_Job>, +v_1001359: List<&2, cps_provider_2_Job>, +v_1001360: List<&2, cps_provider_2_Job>, +v_1001361: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World, +v_3: U32) -> TemplateProgress<cps_provider_2_Part>:
  v_22 = List.append(&2, cps_provider_2_Job, v_1001358, List.append(&2, cps_provider_2_Job, v_1001359, List.append(&2, cps_provider_2_Job, v_1001360, v_1001361)))
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_22, v_1, []}}, False{}, v_1001367 => template_body_cps_provider_2_run_jobs(v_22, v_1, []), v_1001366 => +v_1001362 = template_unbox(cps_provider_2_Code, v_1001366); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1001362, String.append(String.append("term_ctr(", U32.show(v_3)), "u, n0)")}}, False{}, v_1001365 => template_body_cps_provider_2_part_of(v_1001362, String.append(String.append("term_ctr(", U32.show(v_3)), "u, n0)")), v_1001364 => +v_1001363 = template_unbox(cps_provider_2_Part, v_1001364); TemplateFinished{TemplateValue{v_1001363}}}}

def template_body_cps_provider_2_construct_words(+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_8: List<&2, cps_provider_1_NodeSlot>, +v_11: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_decl{"w0", "o0", v_5}}, False{}, v_1001377 => template_body_cps_provider_2_dst_decl("w0", "o0", v_5), v_1001376 => +v_1001357 = template_unbox(String, v_1001376); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1001357}}}, False{}, v_1001375 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1001357}), v_1001374 => +v_1001358 = template_unbox(List<&2, cps_provider_2_Job>, v_1001374); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_fill_slots_jobs{v_1, v_8, v_11}}, False{}, v_1001373 => template_body_cps_provider_2_fill_slots_jobs(v_1, v_8, v_11), v_1001372 => +v_1001359 = template_unbox(List<&2, cps_provider_2_Job>, v_1001372); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_seal_slots_jobs{v_1, v_8, v_11}}, False{}, v_1001371 => template_body_cps_provider_2_seal_slots_jobs(v_1, v_8, v_11), v_1001370 => +v_1001360 = template_unbox(List<&2, cps_provider_2_Job>, v_1001370); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{String.append(String.append(String.append(String.append("u64 n0 = heap_alloc(e, cls_fit(", Nat.show(v_5)), ")); for (u32 n0i = 0; n0i < "), Nat.show(v_5)), "; n0i += 1) { e.mem[n0 + n0i] = w0[n0i]; }")}}}, False{}, v_1001369 => template_body_cps_provider_2_one_job(cps_provider_2_JText{String.append(String.append(String.append(String.append("u64 n0 = heap_alloc(e, cls_fit(", Nat.show(v_5)), ")); for (u32 n0i = 0; n0i < "), Nat.show(v_5)), "; n0i += 1) { e.mem[n0 + n0i] = w0[n0i]; }")}), v_1001368 => +v_1001361 = template_unbox(List<&2, cps_provider_2_Job>, v_1001368); template_continuation_377(v_1001358, v_1001359, v_1001360, v_1001361, v_1, v_3)}}}}}

def template_continuation_378(+v_1001378: List<&2, cps_provider_2_Job>, +v_1001379: List<&2, cps_provider_2_Job>, +v_1001380: List<&2, cps_provider_2_Job>, +v_3: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Code>:
  v_17 = List.append(&2, cps_provider_2_Job, v_1001378, List.append(&2, cps_provider_2_Job, v_1001379, v_1001380))
  template_body_cps_provider_2_run_jobs(v_17, v_3, [])

def template_body_cps_provider_2_codeSeqPack(+v_1: cps_provider_2_Code, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Layout, +v_7: String, +v_9: U32) -> TemplateProgress<cps_provider_2_Code>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{"u64 w0[1]; w0[0] = 0; u32 o0 = 0;"}}}, False{}, v_1001387 => template_body_cps_provider_2_one_job(cps_provider_2_JText{"u64 w0[1]; w0[0] = 0; u32 o0 = 0;"}), v_1001386 => +v_1001378 = template_unbox(List<&2, cps_provider_2_Job>, v_1001386); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_code_jobs{v_1}}, False{}, v_1001385 => template_body_cps_provider_2_code_jobs(v_1), v_1001384 => +v_1001379 = template_unbox(List<&2, cps_provider_2_Job>, v_1001384); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_fill_jobs{v_3, v_5, v_7, cps_provider_2_DstSeq{"w0", "o0"}, "p0"}}, False{}, v_1001383 => template_body_cps_provider_2_fill_jobs(v_3, v_5, v_7, cps_provider_2_DstSeq{"w0", "o0"}, "p0"), v_1001382 => +v_1001380 = template_unbox(List<&2, cps_provider_2_Job>, v_1001382); template_continuation_378(v_1001378, v_1001379, v_1001380, v_3)}}}

def template_continuation_379(+v_1001389: String, v_21: cps_provider_2_Code, +v_1: cps_provider_2_World, v_14: cps_provider_1_Layout, +v_3: U32) -> TemplateProgress<cps_provider_2_Part>:
  v_24 = v_1001389
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_codeSeqPack{v_21, v_1, v_14, v_24, v_3}}, False{}, v_1001396 => template_body_cps_provider_2_codeSeqPack(v_21, v_1, v_14, v_24, v_3), v_1001395 => +v_1001390 = template_unbox(cps_provider_2_Code, v_1001395); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["term_pak(", U32.show(v_3), "u, (u64)w0[0])"]}}, False{}, v_1001394 => template_body_cps_provider_2_join_text(["term_pak(", U32.show(v_3), "u, (u64)w0[0])"]), v_1001393 => +v_1001391 = template_unbox(String, v_1001393); template_body_cps_provider_2_part_of(v_1001390, v_1001391)}}

def template_continuation_380(+v_1001388: cps_provider_2_Code, +v_14: cps_provider_1_Layout, v_17: BIR.Use, v_18: String, +v_1: cps_provider_2_World, +v_3: U32) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_operand_name{v_14, v_17, v_18, "p0"}}, False{}, v_1001398 => template_body_cps_provider_2_operand_name(v_14, v_17, v_18, "p0"), v_1001397 => +v_1001389 = template_unbox(String, v_1001397); template_continuation_379(v_1001389, v_1001388, v_1, v_14, v_3)}

def template_match_381(+v_7: cps_provider_2_Operand, +v_14: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_3: U32) -> TemplateProgress<cps_provider_2_Part>:
  match v_7:
    case cps_provider_2_Operand{+v_17, +v_18}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_operand_code{v_14, v_17, v_18, "p0"}}, False{}, v_1001400 => template_body_cps_provider_2_operand_code(v_14, v_17, v_18, "p0"), v_1001399 => +v_1001388 = template_unbox(cps_provider_2_Code, v_1001399); template_continuation_380(v_1001388, v_14, v_17, v_18, v_1, v_3)}

def template_body_cps_provider_2_construct_packed_one(+v_1: cps_provider_2_World, +v_3: U32, +v_5: cps_provider_1_NodeSlot, +v_7: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case cps_provider_1_NodeSlot{v_1004397, v_1004398, v_1004399}:
      template_match_381(v_7, v_1004399, v_1, v_3)

def template_match_383(+v_10: List<&2, cps_provider_2_Operand>, +v_3: U32, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_10:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["term_pak(", U32.show(v_3), "u, 0)"]}}, False{}, v_1001403 => template_body_cps_provider_2_join_text(["term_pak(", U32.show(v_3), "u, 0)"]), v_1001402 => +v_1001401 = template_unbox(String, v_1001402); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1001401}}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the constructor `", v_5, "` has an inconsistent packed node"]}}, False{}, v_1001406 => template_body_cps_provider_2_join_text(["the constructor `", v_5, "` has an inconsistent packed node"]), v_1001405 => +v_1001404 = template_unbox(String, v_1001405); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1001404}}}}

def template_match_384(+v_10: List<&2, cps_provider_2_Operand>, +v_1: cps_provider_2_World, +v_3: U32, +v_23: cps_provider_1_NodeSlot, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_10:
    case [+v_25]:
      template_body_cps_provider_2_construct_packed_one(v_1, v_3, v_23, v_25)
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the constructor `", v_5, "` has an inconsistent packed node"]}}, False{}, v_1001410 => template_body_cps_provider_2_join_text(["the constructor `", v_5, "` has an inconsistent packed node"]), v_1001409 => +v_1001408 = template_unbox(String, v_1001409); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1001408}}}}

def template_match_385(v_16: List<&2, cps_provider_1_NodeSlot>, +v_10: List<&2, cps_provider_2_Operand>, +v_3: U32, +v_5: String, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_16:
    case []:
      template_match_383(v_10, v_3, v_5)
    case [+v_23]:
      template_match_384(v_10, v_1, v_3, v_23, v_5)
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the constructor `", v_5, "` has an inconsistent packed node"]}}, False{}, v_1001413 => template_body_cps_provider_2_join_text(["the constructor `", v_5, "` has an inconsistent packed node"]), v_1001412 => +v_1001411 = template_unbox(String, v_1001412); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1001411}}}}

def template_body_cps_provider_2_construct_packed(+v_1: cps_provider_2_World, +v_3: U32, +v_5: String, +v_7: cps_provider_1_Node, +v_10: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_7:
    case cps_provider_1_Node{v_1004400, v_1004401, v_1004402}:
      template_match_385(v_1004401, v_10, v_3, v_5, v_1)

def template_match_387(+v_9: cps_provider_1_Node, +v_3: cps_provider_2_World, +v_5: U32, +v_12: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_9:
    case cps_provider_1_Node{v_18, v_19, v_20}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_construct_words{v_3, v_5, List.length(&2, cps_provider_1_CWord, v_18), v_19, v_12}}, False{}, v_1001417 => template_body_cps_provider_2_construct_words(v_3, v_5, List.length(&2, cps_provider_1_CWord, v_18), v_19, v_12), v_1001416 => +v_1001415 = template_unbox(cps_provider_2_Part, v_1001416); TemplateFinished{TemplateValue{v_1001415}}}

def template_body_cps_provider_2_construct_packed_flag(+v_1: Bool, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_9: cps_provider_1_Node, +v_12: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case True{}:
      template_body_cps_provider_2_construct_packed(v_3, v_5, v_7, v_9, v_12)
    case False{}:
      template_match_387(v_9, v_3, v_5, v_12)

def template_match_389(+v_9: cps_provider_1_Node, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_12: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_9:
    case cps_provider_1_Node{v_18, v_19, v_20}:
      template_body_cps_provider_2_construct_packed_flag(v_20, v_3, v_5, v_7, v_9, v_12)

def template_body_cps_provider_2_construct_count(+v_1: Bool, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_9: cps_provider_1_Node, +v_12: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the constructor `", v_7, "` has a different live field count than its value arguments"]}}, False{}, v_1004403 => template_body_cps_provider_2_join_text(["the constructor `", v_7, "` has a different live field count than its value arguments"]), v_1004404 => +v_1004405 = template_unbox(String, v_1004404); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004405}}}}
    case True{}:
      template_match_389(v_9, v_3, v_5, v_7, v_12)

def template_body_cps_provider_2_construct_node(+v_1: cps_provider_2_World, +v_3: U32, +v_5: String, +v_7: cps_provider_1_Node, +v_10: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_7:
    case cps_provider_1_Node{v_1004406, v_1004407, v_1004408}:
      v_1004409 = Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_1004407), List.length(&2, cps_provider_2_Operand, v_10))
      template_body_cps_provider_2_construct_count(v_1004409, v_1, v_3, v_5, v_7, v_10)

def template_body_cps_provider_2_construct_layout(+v_1: cps_provider_1_NodeResult, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_10: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_1_NodeFailed{v_13}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_13}}}
    case cps_provider_1_NodeFound{v_15}:
      template_body_cps_provider_2_construct_node(v_3, v_5, v_7, v_15, v_10)

def template_continuation_393(+v_1001427: cps_provider_1_NodeResult, +v_4: cps_provider_2_World, v_13: U32, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_construct_layout(v_1001427, v_4, v_13, v_6, v_9)

def template_match_394(+v_4: cps_provider_2_World, +v_6: String, v_13: U32, +v_9: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_4:
    case cps_provider_2_World{v_17, v_18, v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_layout{v_17, v_6}}, False{}, v_1001430 => template_body_cps_provider_1_node_layout(v_17, v_6), v_1001429 => +v_1001427 = template_unbox(cps_provider_1_NodeResult, v_1001429); template_continuation_393(v_1001427, v_4, v_13, v_6, v_9)}

def template_body_cps_provider_2_construct_cid(+v_2: Maybe<&2, U32>, +v_4: cps_provider_2_World, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the constructor `", v_6, "` has no canonical CID row"]}}, False{}, v_1004410 => template_body_cps_provider_2_join_text(["the constructor `", v_6, "` has no canonical CID row"]), v_1004411 => +v_1004412 = template_unbox(String, v_1004411); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004412}}}}
    case Some{v_1004413}:
      template_match_394(v_4, v_6, v_1004413, v_9)

def template_continuation_396(+v_1001431: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_3: String, +v_6: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_construct_cid(v_1001431, v_1, v_3, v_6)

def template_body_cps_provider_2_construct_generic(+v_1: cps_provider_2_World, +v_3: String, +v_6: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_3, v_1}}, False{}, v_1001434 => template_body_cps_provider_2_cid_of(v_3, v_1), v_1001433 => +v_1001431 = template_unbox(Maybe<&2, U32>, v_1001433); template_continuation_396(v_1001431, v_1, v_3, v_6)}

def template_body_cps_provider_2_construct_marker(+v_1: Bool, +v_3: cps_provider_2_World, +v_5: String, +v_8: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the intrinsic constructor `", v_5, "` must be lowered to its primitive before C emission"]}}, False{}, v_1004414 => template_body_cps_provider_2_join_text(["the intrinsic constructor `", v_5, "` must be lowered to its primitive before C emission"]), v_1004415 => +v_1004416 = template_unbox(String, v_1004415); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004416}}}}
    case False{}:
      template_body_cps_provider_2_construct_generic(v_3, v_5, v_8)

def template_body_cps_provider_2_construct_native(+v_2: Maybe<&2, String>, +v_4: cps_provider_2_World, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      template_body_cps_provider_2_construct_generic(v_4, v_6, v_9)
    case Some{v_13}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_construct_marker{template_pure_cps_provider_2_intrinsic_marker(v_13), v_4, v_6, v_9}}, False{}, v_1001442 => template_body_cps_provider_2_construct_marker(template_pure_cps_provider_2_intrinsic_marker(v_13), v_4, v_6, v_9), v_1001441 => +v_1001440 = template_unbox(cps_provider_2_Part, v_1001441); TemplateFinished{TemplateValue{v_1001440}}}

def template_match_399(v_9: BIR.ConstructorLayout, +v_3: cps_provider_2_World, +v_6: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_9:
    case BIR.ConstructorLayout{v_14, v_15, v_16, v_17}:
      template_body_cps_provider_2_construct_native(v_16, v_3, v_15, v_6)

def template_body_cps_provider_2_construct_row(+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: cps_provider_2_World, +v_6: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"BIR constructs a constructor with no layout row"}}}
    case Some{v_9}:
      template_match_399(v_9, v_3, v_6)

def template_continuation_401(+v_1001444: Maybe<&2, BIR.ConstructorLayout>, +v_6: cps_provider_2_World, +v_4: List<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_construct_row(v_1001444, v_6, v_4)

def template_body_cps_provider_2_construct_part(+v_1: U32, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_ctor_of{v_1, v_6}}, False{}, v_1001447 => template_body_cps_provider_2_ctor_of(v_1, v_6), v_1001446 => +v_1001444 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1001446); template_continuation_401(v_1001444, v_6, v_4)}

def template_body_cps_provider_2_term_decl_text(+v_1: Nat) -> TemplateProgress<String>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{""}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term b0f[", Nat.show(v_1), "];"]}}, False{}, v_1001450 => template_body_cps_provider_2_join_text(["Term b0f[", Nat.show(v_1), "];"]), v_1001449 => +v_1001448 = template_unbox(String, v_1001449); TemplateFinished{TemplateValue{v_1001448}}}

def template_match_403(+v_1: cps_provider_1_Layout, v_12: String) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_1_LayoutWord{v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_12, " Term b0r = 0;"]}}, False{}, v_1001458 => template_body_cps_provider_2_join_text([v_12, " Term b0r = 0;"]), v_1001457 => +v_1001456 = template_unbox(String, v_1001457); TemplateFinished{TemplateValue{v_1001456}}}
    case cps_provider_1_LayoutBox{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_12, " Term b0r = 0;"]}}, False{}, v_1001461 => template_body_cps_provider_2_join_text([v_12, " Term b0r = 0;"]), v_1001460 => +v_1001459 = template_unbox(String, v_1001460); TemplateFinished{TemplateValue{v_1001459}}}
    case cps_provider_1_LayoutData{v_21, v_22}:
      TemplateFinished{TemplateValue{v_12}}

def template_continuation_404(+v_1001455: String, +v_1: cps_provider_1_Layout) -> TemplateProgress<String>:
  template_match_403(v_1, v_1001455)

def template_body_cps_provider_2_project_prelude(+v_1: cps_provider_1_Layout, +v_3: String, +v_5: Nat, +v_7: Nat) -> TemplateProgress<String>:
  v_1001451 = {"Term b0t = " : String}
  v_1001452 = {v_3 : String}
  v_1001453 = {";" : String}
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_term_decl_text{v_5}}, False{}, v_1001465 => template_body_cps_provider_2_term_decl_text(v_5), v_1001464 => +v_1001454 = template_unbox(String, v_1001464); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001451, v_1001452, v_1001453, v_1001454, "u64 b0s = term_rfc(b0t) ? ctr_take(e, b0t, ", Nat.show(v_5), ", b0f) : term_loc(b0t); u32 b0i = ", Nat.show(v_7), ";"]}}, False{}, v_1001463 => template_body_cps_provider_2_join_text([v_1001451, v_1001452, v_1001453, v_1001454, "u64 b0s = term_rfc(b0t) ? ctr_take(e, b0t, ", Nat.show(v_5), ", b0f) : term_loc(b0t); u32 b0i = ", Nat.show(v_7), ";"]), v_1001462 => +v_1001455 = template_unbox(String, v_1001462); template_continuation_404(v_1001455, v_1)}}

def template_continuation_405(+v_1001467: List<&2, cps_provider_2_Job>, +v_1001468: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_16 = List.append(&2, cps_provider_2_Job, v_1001467, v_1001468)
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_16, v_1, []}}, False{}, v_1001474 => template_body_cps_provider_2_run_jobs(v_16, v_1, []), v_1001473 => +v_1001469 = template_unbox(cps_provider_2_Code, v_1001473); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1001469, "b0r"}}, False{}, v_1001472 => template_body_cps_provider_2_part_of(v_1001469, "b0r"), v_1001471 => +v_1001470 = template_unbox(cps_provider_2_Part, v_1001471); TemplateFinished{TemplateValue{v_1001470}}}}

def template_body_cps_provider_2_project_words(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: Nat, +v_7: Nat, +v_9: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_project_prelude{v_3, v_9, v_7, v_5}}, False{}, v_1001480 => template_body_cps_provider_2_project_prelude(v_3, v_9, v_7, v_5), v_1001479 => +v_1001466 = template_unbox(String, v_1001479); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1001466}}}, False{}, v_1001478 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1001466}), v_1001477 => +v_1001467 = template_unbox(List<&2, cps_provider_2_Job>, v_1001477); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcNode{"b0s", "b0f", "b0i", False{}}, "b0r", "b0"}}, False{}, v_1001476 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcNode{"b0s", "b0f", "b0i", False{}}, "b0r", "b0"), v_1001475 => +v_1001468 = template_unbox(List<&2, cps_provider_2_Job>, v_1001475); template_continuation_405(v_1001467, v_1001468, v_1)}}}

def template_match_406(+v_1: cps_provider_1_Layout, v_7: String) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_1_LayoutWord{v_9}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_7, " Term b0r = 0;"]}}, False{}, v_1001484 => template_body_cps_provider_2_join_text([v_7, " Term b0r = 0;"]), v_1001483 => +v_1001482 = template_unbox(String, v_1001483); TemplateFinished{TemplateValue{v_1001482}}}
    case cps_provider_1_LayoutBox{v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_7, " Term b0r = 0;"]}}, False{}, v_1001487 => template_body_cps_provider_2_join_text([v_7, " Term b0r = 0;"]), v_1001486 => +v_1001485 = template_unbox(String, v_1001486); TemplateFinished{TemplateValue{v_1001485}}}
    case cps_provider_1_LayoutData{v_16, v_17}:
      TemplateFinished{TemplateValue{v_7}}

def template_continuation_407(+v_1001481: String, +v_1: cps_provider_1_Layout) -> TemplateProgress<String>:
  template_match_406(v_1, v_1001481)

def template_body_cps_provider_2_project_packed_prelude(+v_1: cps_provider_1_Layout, +v_3: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term b0t = ", v_3, ";"]}}, False{}, v_1001489 => template_body_cps_provider_2_join_text(["Term b0t = ", v_3, ";"]), v_1001488 => +v_1001481 = template_unbox(String, v_1001488); template_continuation_407(v_1001481, v_1)}

def template_continuation_408(+v_1001491: List<&2, cps_provider_2_Job>, +v_1001492: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_12 = List.append(&2, cps_provider_2_Job, v_1001491, v_1001492)
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_12, v_1, []}}, False{}, v_1001498 => template_body_cps_provider_2_run_jobs(v_12, v_1, []), v_1001497 => +v_1001493 = template_unbox(cps_provider_2_Code, v_1001497); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1001493, "b0r"}}, False{}, v_1001496 => template_body_cps_provider_2_part_of(v_1001493, "b0r"), v_1001495 => +v_1001494 = template_unbox(cps_provider_2_Part, v_1001495); TemplateFinished{TemplateValue{v_1001494}}}}

def template_body_cps_provider_2_project_packed(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_project_packed_prelude{v_3, v_5}}, False{}, v_1001504 => template_body_cps_provider_2_project_packed_prelude(v_3, v_5), v_1001503 => +v_1001490 = template_unbox(String, v_1001503); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1001490}}}, False{}, v_1001502 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1001490}), v_1001501 => +v_1001491 = template_unbox(List<&2, cps_provider_2_Job>, v_1001501); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcOne{"((u64)term_loc(b0t))"}, "b0r", "b0"}}, False{}, v_1001500 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcOne{"((u64)term_loc(b0t))"}, "b0r", "b0"), v_1001499 => +v_1001492 = template_unbox(List<&2, cps_provider_2_Job>, v_1001499); template_continuation_408(v_1001491, v_1001492, v_1)}}}

def template_body_cps_provider_2_project_packed_flag(+v_1: Bool, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Layout, +v_7: Nat, +v_9: Nat, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case True{}:
      template_body_cps_provider_2_project_packed(v_3, v_5, v_11)
    case False{}:
      template_body_cps_provider_2_project_words(v_3, v_5, v_7, v_9, v_11)

def template_body_cps_provider_2_unique_expr(+v_1: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(!term_triv(", v_1, ") && !(term_rfc(", v_1, ") && (a32_load(a32_at(e.mem, term_loc(", v_1, "))) & RFC_CNT) > 1))"]}}, False{}, v_1001509 => template_body_cps_provider_2_join_text(["(!term_triv(", v_1, ") && !(term_rfc(", v_1, ") && (a32_load(a32_at(e.mem, term_loc(", v_1, "))) & RFC_CNT) > 1))"]), v_1001508 => +v_1001507 = template_unbox(String, v_1001508); TemplateFinished{TemplateValue{v_1001507}}}

def template_body_cps_provider_2_static_expr(+v_1: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["term_triv(", v_1, ")"]}}, False{}, v_1001512 => template_body_cps_provider_2_join_text(["term_triv(", v_1, ")"]), v_1001511 => +v_1001510 = template_unbox(String, v_1001511); TemplateFinished{TemplateValue{v_1001510}}}

def template_body_cps_provider_2_and_expr(+v_1: String, +v_3: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(", v_1, " && ", v_3, ")"]}}, False{}, v_1001515 => template_body_cps_provider_2_join_text(["(", v_1, " && ", v_3, ")"]), v_1001514 => +v_1001513 = template_unbox(String, v_1001514); TemplateFinished{TemplateValue{v_1001513}}}

def template_body_cps_provider_2_or_expr(+v_1: String, +v_3: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(", v_1, " || ", v_3, ")"]}}, False{}, v_1001518 => template_body_cps_provider_2_join_text(["(", v_1, " || ", v_3, ")"]), v_1001517 => +v_1001516 = template_unbox(String, v_1001517); TemplateFinished{TemplateValue{v_1001516}}}

def template_body_cps_provider_2_nat_if(+v_1: Bool, +v_3: Nat, +v_5: Nat) -> TemplateProgress<Nat>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_nat_if(v_1, v_3, v_5)}}

def template_body_cps_provider_2_live_ordinal(+v_1: List<&2, BIR.DescriptorField>, +v_3: U32) -> TemplateProgress<Maybe<&2, U32>>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_walk{v_1, U32.to_nat(v_3), 0n, 0n}}, v_1001520 => +v_1001519 = template_unbox(Maybe<&2, U32>, v_1001520); TemplateFinished{TemplateValue{v_1001519}}}

def template_match_410(v_18: BIR.Quantity, +v_7: Nat) -> TemplateProgress<Maybe<&2, U32>>:
  match v_18:
    case BIR.Erased{}:
      TemplateFinished{TemplateValue{None{}}}
    case _:
      TemplateFinished{TemplateValue{Some{U32.from_nat(v_7)}}}

def template_match_411(v_1001521: Bool, v_18: BIR.Quantity, +v_7: Nat, v_13: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1001521:
    case True{}:
      template_match_410(v_18, v_7)
    case False{}:
      +v_1001524 = {Nat.add(v_5, 1n) : Nat}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_next{v_18, v_7}}, v_1001528 => +v_1001525 = template_unbox(Nat, v_1001528); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_walk{{v_13 : List<&2, BIR.DescriptorField>}, {v_3 : Nat}, v_1001524, v_1001525}}, v_1001527 => +v_1001526 = template_unbox(Maybe<&2, U32>, v_1001527); TemplateFinished{TemplateValue{v_1001526}}}}

def template_match_412(+v_12: BIR.DescriptorField, +v_5: Nat, +v_3: Nat, +v_7: Nat, v_13: List<&2, BIR.DescriptorField>) -> TemplateProgress<Maybe<&2, U32>>:
  match v_12:
    case BIR.DescriptorField{v_17, v_18, v_19}:
      v_1001521 = {Nat.is_eq(v_5, v_3) : Bool}
      template_match_411(v_1001521, v_18, v_7, v_13, v_3, v_5)

def template_body_cps_provider_2_live_walk(+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004417 <> v_1004418:
      template_match_412(v_1004417, v_5, v_3, v_7, v_1004418)

def template_body_cps_provider_2_live_next(+v_0: BIR.Quantity, +v_2: Nat) -> TemplateProgress<Nat>:
  match v_0:
    case BIR.Erased{}:
      TemplateFinished{TemplateValue{v_2}}
    case _:
      TemplateFinished{TemplateValue{Nat.add(v_2, 1n)}}

def template_match_415(v_1001529: Bool, v_11: List<&2, cps_provider_1_LayArm>, +v_4: String, v_15: List<&2, cps_provider_1_Layout>) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_Layout>>>:
  match v_1001529:
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_fields_of{v_11, v_4}}, v_1001531 => +v_1001530 = template_unbox(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_1001531); TemplateFinished{TemplateValue{v_1001530}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_15}}}

def template_match_416(+v_10: cps_provider_1_LayArm, +v_4: String, v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_Layout>>>:
  match v_10:
    case cps_provider_1_LayArm{v_14, v_15}:
      v_17 = String.eq(v_14, v_4)
      template_match_415(v_17, v_11, v_4, v_15)

def template_body_cps_provider_2_arm_fields_of(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: String) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_Layout>>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_10 <> v_11:
      template_match_416(v_10, v_4, v_11)

def template_match_418(+v_5: BIR.DescriptorArm) -> TemplateProgress<Maybe<&2, List<&2, BIR.DescriptorField>>>:
  match v_5:
    case BIR.DescriptorArm{+v_8, +v_9}:
      TemplateFinished{TemplateValue{Some{v_9}}}

def template_body_cps_provider_2_arm_fields_declared(+v_1: Maybe<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, List<&2, BIR.DescriptorField>>>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{None{}}}
    case Some{+v_5}:
      template_match_418(v_5)

def template_body_cps_provider_2_arm_descriptor_fields(+v_1: cps_provider_2_World, +v_3: String) -> TemplateProgress<Maybe<&2, List<&2, BIR.DescriptorField>>>:
  match v_1:
    case cps_provider_2_World{v_9, v_10, v_11}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_arm_declared{v_9, v_3}}, False{}, v_1001535 => template_body_cps_provider_1_arm_declared(v_9, v_3), v_1001534 => +v_1001532 = template_unbox(Maybe<&2, BIR.DescriptorArm>, v_1001534); template_body_cps_provider_2_arm_fields_declared(v_1001532)}

def template_match_421(v_8: BIR.ConstructorLayout) -> TemplateProgress<Maybe<&2, String>>:
  match v_8:
    case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
      TemplateFinished{TemplateValue{Some{v_14}}}

def template_match_422(+v_1001536: Maybe<&2, BIR.ConstructorLayout>) -> TemplateProgress<Maybe<&2, String>>:
  match v_1001536:
    case None{}:
      TemplateFinished{TemplateValue{None{}}}
    case Some{v_8}:
      template_match_421(v_8)

def template_body_cps_provider_2_step_key(+v_1: cps_provider_2_World, +v_3: U32) -> TemplateProgress<Maybe<&2, String>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_ctor_of{v_3, v_1}}, False{}, v_1001538 => template_body_cps_provider_2_ctor_of(v_3, v_1), v_1001537 => +v_1001536 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1001537); template_match_422(v_1001536)}

def template_match_423(+v_1001539: cps_provider_1_CellResult) -> TemplateProgress<Maybe<&2, cps_provider_1_Cell>>:
  match v_1001539:
    case cps_provider_1_CellFailed{v_13}:
      TemplateFinished{TemplateValue{None{}}}
    case cps_provider_1_CellFound{v_15}:
      TemplateFinished{TemplateValue{Some{v_15}}}

def template_body_cps_provider_2_cell_lgs(+v_1: cps_provider_2_World, +v_2: BIR.Descriptor) -> TemplateProgress<Maybe<&2, cps_provider_1_Cell>>:
  match v_1:
    case cps_provider_2_World{v_8, v_9, v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_array_cell{v_8, v_2}}, False{}, v_1001541 => template_body_cps_provider_1_array_cell(v_8, v_2), v_1001540 => +v_1001539 = template_unbox(cps_provider_1_CellResult, v_1001540); template_match_423(v_1001539)}

def template_body_cps_provider_2_not_bool(+v_1: Bool) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_not_bool(v_1)}}

def template_match_425(v_1001543: Bool, +v_7: U32) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1001543:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_7}}}
    case False{}:
      TemplateFinished{TemplateValue{None{}}}

def template_match_426(v_1001544: Bool, v_13: List<&2, BIR.DescriptorField>, +v_3: U32, +v_5: U32, +v_7: U32) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1001544:
    case True{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_ordinal_in{v_13, U32.inc(v_3), v_5, U32.inc(v_7)}}, v_1001546 => +v_1001545 = template_unbox(Maybe<&2, U32>, v_1001546); TemplateFinished{TemplateValue{v_1001545}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_ordinal_in{v_13, U32.inc(v_3), v_5, v_7}}, v_1001548 => +v_1001547 = template_unbox(Maybe<&2, U32>, v_1001548); TemplateFinished{TemplateValue{v_1001547}}}

def template_match_427(v_1001542: Bool, v_18: BIR.Quantity, +v_7: U32, v_13: List<&2, BIR.DescriptorField>, +v_3: U32, +v_5: U32) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1001542:
    case True{}:
      v_1001543 = {template_pure_cps_provider_1_live_field(v_18) : Bool}
      template_match_425(v_1001543, v_7)
    case False{}:
      v_1001544 = {template_pure_cps_provider_1_live_field(v_18) : Bool}
      template_match_426(v_1001544, v_13, v_3, v_5, v_7)

def template_match_428(+v_12: BIR.DescriptorField, +v_3: U32, +v_5: U32, +v_7: U32, v_13: List<&2, BIR.DescriptorField>) -> TemplateProgress<Maybe<&2, U32>>:
  match v_12:
    case BIR.DescriptorField{v_17, v_18, v_19}:
      v_1001542 = {U32.is_eq(v_3, v_5) : Bool}
      template_match_427(v_1001542, v_18, v_7, v_13, v_3, v_5)

def template_body_cps_provider_2_live_ordinal_in(+v_1: List<&2, BIR.DescriptorField>, +v_3: U32, +v_5: U32, +v_7: U32) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_12 <> v_13:
      template_match_428(v_12, v_3, v_5, v_7, v_13)

def template_match_430(+v_4: Nat, +v_6: Nat, +v_11: cps_provider_1_Layout, v_12: List<&2, cps_provider_1_Layout>) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_4:
    case 0n:
      TemplateFinished{TemplateValue{Some{cps_provider_1_NodeSlot{0, v_6, v_11}}}}
    case 1n+v_14:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_11}}, False{}, v_1001556 => template_body_cps_provider_1_layout_words(v_11), v_1001555 => +v_1001552 = template_unbox(Nat, v_1001555); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_slot{{v_12 : List<&2, cps_provider_1_Layout>}, {v_14 : Nat}, Nat.add({v_6 : Nat}, v_1001552)}}, v_1001554 => +v_1001553 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1001554); TemplateFinished{TemplateValue{v_1001553}}}}

def template_body_cps_provider_2_inline_slot(+v_2: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_6: Nat) -> TemplateProgress<Maybe<&2, cps_provider_1_NodeSlot>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_11 <> v_12:
      template_match_430(v_4, v_6, v_11, v_12)

def template_match_432(v_1001557: Bool) -> TemplateProgress<Nat>:
  match v_1001557:
    case True{}:
      TemplateFinished{TemplateValue{1n}}
    case False{}:
      TemplateFinished{TemplateValue{0n}}

def template_body_cps_provider_2_inline_start(+v_2: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Nat>:
  v_1001557 = {Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_2), 1n) : Bool}
  template_match_432(v_1001557)

def template_continuation_433(v_20: Nat, v_17: cps_provider_1_Layout, +v_3: String, +v_1001559: String, +v_1001560: String, v_18: Bool, +v_5: String, +v_7: String) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(term_tag(", v_3, ") == TAG_ARR)"]}}, False{}, v_1001565 => template_body_cps_provider_2_join_text(["(term_tag(", v_3, ") == TAG_ARR)"]), v_1001564 => +v_1001563 = template_unbox(String, v_1001564); TemplateFinished{TemplateValue{cps_provider_2_PathOk{cps_provider_2_StArray{v_1001559, v_1001560, {v_20 : Nat}, {v_17 : cps_provider_1_Layout}, v_1001563, "0", template_pure_cps_provider_2_not_bool(v_18), v_5, v_7}}}}}

def template_match_434(v_12: cps_provider_1_Cell, +v_3: String, +v_5: String, +v_7: String) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_12:
    case cps_provider_1_Cell{v_17, v_18, v_19, v_20}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["blk_loc(e.mem, ", v_3, ")"]}}, False{}, v_1001569 => template_body_cps_provider_2_join_text(["blk_loc(e.mem, ", v_3, ")"]), v_1001568 => +v_1001559 = template_unbox(String, v_1001568); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u32)blk_cls(", v_3, "))"]}}, False{}, v_1001567 => template_body_cps_provider_2_join_text(["((u32)blk_cls(", v_3, "))"]), v_1001566 => +v_1001560 = template_unbox(String, v_1001566); template_continuation_433(v_20, v_17, v_3, v_1001559, v_1001560, v_18, v_5, v_7)}}

def template_match_435(+v_1001558: Maybe<&2, cps_provider_1_Cell>, +v_3: String, +v_5: String, +v_7: String) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001558:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"the array element has no cell layout"}}}
    case Some{v_12}:
      template_match_434(v_12, v_3, v_5, v_7)

def template_body_cps_provider_2_state_array(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_cell_lgs{v_1, v_8}}, False{}, v_1001571 => template_body_cps_provider_2_cell_lgs(v_1, v_8), v_1001570 => +v_1001558 = template_unbox(Maybe<&2, cps_provider_1_Cell>, v_1001570); template_match_435(v_1001558, v_3, v_5, v_7)}

def template_continuation_436(+v_7: String, +v_3: String, +v_1001572: cps_provider_2_World, +v_1001573: String, +v_1001576: String, +v_8: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  +v_1001577 = {v_7 : String}
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_static_expr{v_3}}, False{}, v_1001584 => template_body_cps_provider_2_static_expr(v_3), v_1001583 => +v_1001578 = template_unbox(String, v_1001583); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_or_expr{v_1001577, v_1001578}}, False{}, v_1001582 => template_body_cps_provider_2_or_expr(v_1001577, v_1001578), v_1001581 => +v_1001579 = template_unbox(String, v_1001581); template_body_cps_provider_2_state_array(v_1001572, v_1001573, v_1001576, v_1001579, v_8)}}

def template_body_cps_provider_2_state_from_array_value(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  +v_1001574 = {v_5 : String}
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unique_expr{v_3}}, False{}, v_1001588 => template_body_cps_provider_2_unique_expr(v_3), v_1001587 => +v_1001575 = template_unbox(String, v_1001587); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_and_expr{v_1001574, v_1001575}}, False{}, v_1001586 => template_body_cps_provider_2_and_expr(v_1001574, v_1001575), v_1001585 => +v_1001576 = template_unbox(String, v_1001585); template_continuation_436(v_7, v_3, {v_1 : cps_provider_2_World}, {v_3 : String}, v_1001576, v_8)}}

def template_match_437(+v_3: cps_provider_2_PathState, +v_1: cps_provider_2_World, v_15: String, +v_7: U32, +v_10: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_3:
    case cps_provider_2_StSlot{v_22, v_23, v_24, v_25, v_26, v_27}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_resolve_slot_field{v_1, v_15, v_7, v_22, v_23, v_24, v_25, v_26, v_27, v_10}}, v_1001594 => +v_1001593 = template_unbox(cps_provider_2_PathResult, v_1001594); TemplateFinished{TemplateValue{v_1001593}}}
    case cps_provider_2_StCell{v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45, v_46}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_resolve_cell_field{v_1, v_15, v_7, v_38, v_44, v_40, v_42, v_43, v_45, v_46, v_10}}, v_1001596 => +v_1001595 = template_unbox(cps_provider_2_PathResult, v_1001596); TemplateFinished{TemplateValue{v_1001595}}}
    case cps_provider_2_StBufField{v_53, v_54, v_55, v_56, v_57}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_resolve_buf_field{v_1, v_15, v_7, v_53, v_54, v_55, v_56, v_57, v_10}}, v_1001598 => +v_1001597 = template_unbox(cps_provider_2_PathResult, v_1001598); TemplateFinished{TemplateValue{v_1001597}}}
    case cps_provider_2_StArray{v_68, v_69, v_70, v_71, v_72, v_73, v_74, v_75, v_76}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a Project on an array value needs an element leaf-cell step"}}}

def template_match_438(+v_1001589: Maybe<&2, String>, +v_5: U32, +v_3: cps_provider_2_PathState, +v_1: cps_provider_2_World, +v_7: U32, +v_10: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001589:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["BIR projects constructor ", U32.show(v_5), " with no layout row"]}}, False{}, v_1001592 => template_body_cps_provider_2_join_text(["BIR projects constructor ", U32.show(v_5), " with no layout row"]), v_1001591 => +v_1001590 = template_unbox(String, v_1001591); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001590}}}}
    case Some{v_15}:
      template_match_437(v_3, v_1, v_15, v_7, v_10)

def template_body_cps_provider_2_resolve_field(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_5: U32, +v_7: U32, +v_10: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_step_key{v_1, v_5}}, False{}, v_1001600 => template_body_cps_provider_2_step_key(v_1, v_5), v_1001599 => +v_1001589 = template_unbox(Maybe<&2, String>, v_1001599); template_match_438(v_1001589, v_5, v_3, v_1, v_7, v_10)}

def template_match_439(v_41: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_41:
    case cps_provider_1_NodeSlot{v_45, v_46, v_47}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{v_1, cps_provider_2_StSlot{0n, v_47, v_11, v_13, v_15, True{}}, v_20}}, v_1001618 => +v_1001617 = template_unbox(cps_provider_2_PathResult, v_1001618); TemplateFinished{TemplateValue{v_1001617}}}

def template_match_440(+v_1001613: Maybe<&2, cps_provider_1_NodeSlot>, +v_3: String, +v_5: U32, +v_1: cps_provider_2_World, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001613:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the packed arm `", v_3, "` has no live field ", U32.show(v_5)]}}, False{}, v_1001616 => template_body_cps_provider_2_join_text(["the packed arm `", v_3, "` has no live field ", U32.show(v_5)]), v_1001615 => +v_1001614 = template_unbox(String, v_1001615); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001614}}}}
    case Some{v_41}:
      template_match_439(v_41, v_1, v_11, v_13, v_15, v_20)

def template_match_441(+v_1001609: Maybe<&2, U32>, +v_3: String, v_29: List<&2, cps_provider_1_Layout>, +v_5: U32, +v_1: cps_provider_2_World, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001609:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the projection of `", v_3, "` names an erased packed field"]}}, False{}, v_1001612 => template_body_cps_provider_2_join_text(["the projection of `", v_3, "` names an erased packed field"]), v_1001611 => +v_1001610 = template_unbox(String, v_1001611); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001610}}}}
    case Some{v_37}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_slot{v_29, U32.to_nat(v_37), 0n}}, False{}, v_1001620 => template_body_cps_provider_2_inline_slot(v_29, U32.to_nat(v_37), 0n), v_1001619 => +v_1001613 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1001619); template_match_440(v_1001613, v_3, v_5, v_1, v_11, v_13, v_15, v_20)}

def template_match_442(+v_1001605: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_3: String, +v_5: U32, v_29: List<&2, cps_provider_1_Layout>, +v_1: cps_provider_2_World, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001605:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the packed arm `", v_3, "` has no declared fields"]}}, False{}, v_1001608 => template_body_cps_provider_2_join_text(["the packed arm `", v_3, "` has no declared fields"]), v_1001607 => +v_1001606 = template_unbox(String, v_1001607); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001606}}}}
    case Some{v_33}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_ordinal_in{v_33, U32.from_nat(0n), v_5, U32.from_nat(0n)}}, False{}, v_1001622 => template_body_cps_provider_2_live_ordinal_in(v_33, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1001621 => +v_1001609 = template_unbox(Maybe<&2, U32>, v_1001621); template_match_441(v_1001609, v_3, v_29, v_5, v_1, v_11, v_13, v_15, v_20)}

def template_match_443(+v_1001601: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_3: String, +v_1: cps_provider_2_World, +v_5: U32, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001601:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the packed form has no arm `", v_3, "`"]}}, False{}, v_1001604 => template_body_cps_provider_2_join_text(["the packed form has no arm `", v_3, "`"]), v_1001603 => +v_1001602 = template_unbox(String, v_1001603); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001602}}}}
    case Some{v_29}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_descriptor_fields{v_1, v_3}}, False{}, v_1001624 => template_body_cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1001623 => +v_1001605 = template_unbox(Maybe<&2, List<&2, BIR.DescriptorField>>, v_1001623); template_match_442(v_1001605, v_3, v_5, v_29, v_1, v_11, v_13, v_15, v_20)}

def template_match_444(+v_9: cps_provider_1_Layout, +v_3: String, +v_1: cps_provider_2_World, +v_5: U32, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_9:
    case cps_provider_1_LayoutData{v_24, v_25}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_fields_of{v_25, v_3}}, False{}, v_1001626 => template_body_cps_provider_2_arm_fields_of(v_25, v_3), v_1001625 => +v_1001601 = template_unbox(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_1001625); template_match_443(v_1001601, v_3, v_1, v_5, v_11, v_13, v_15, v_20)}
    case cps_provider_1_LayoutWord{v_50}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a raw packed word has no nested projection"}}}
    case cps_provider_1_LayoutBox{v_52}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a packed value cannot hold a boxed field"}}}

def template_match_445(v_73: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_73:
    case cps_provider_1_NodeSlot{v_77, v_78, v_79}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{v_1, cps_provider_2_StSlot{Nat.add(v_7, v_78), v_79, v_11, v_13, v_15, False{}}, v_20}}, v_1001647 => +v_1001646 = template_unbox(cps_provider_2_PathResult, v_1001647); TemplateFinished{TemplateValue{v_1001646}}}

def template_match_446(+v_1001642: Maybe<&2, cps_provider_1_NodeSlot>, +v_3: String, +v_5: U32, +v_1: cps_provider_2_World, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001642:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the inline arm `", v_3, "` has no live field ", U32.show(v_5)]}}, False{}, v_1001645 => template_body_cps_provider_2_join_text(["the inline arm `", v_3, "` has no live field ", U32.show(v_5)]), v_1001644 => +v_1001643 = template_unbox(String, v_1001644); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001643}}}}
    case Some{v_73}:
      template_match_445(v_73, v_1, v_7, v_11, v_13, v_15, v_20)

def template_match_447(+v_1001635: Maybe<&2, U32>, +v_3: String, v_60: List<&2, cps_provider_1_Layout>, v_56: List<&2, cps_provider_1_LayArm>, +v_5: U32, +v_1: cps_provider_2_World, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001635:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the projection of `", v_3, "` names an erased field"]}}, False{}, v_1001638 => template_body_cps_provider_2_join_text(["the projection of `", v_3, "` names an erased field"]), v_1001637 => +v_1001636 = template_unbox(String, v_1001637); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001636}}}}
    case Some{v_68}:
      +v_1001639 = {v_60 : List<&2, cps_provider_1_Layout>}
      +v_1001640 = {U32.to_nat(v_68) : Nat}
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_start{v_56}}, False{}, v_1001651 => template_body_cps_provider_2_inline_start(v_56), v_1001650 => +v_1001641 = template_unbox(Nat, v_1001650); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_slot{v_1001639, v_1001640, v_1001641}}, False{}, v_1001649 => template_body_cps_provider_2_inline_slot(v_1001639, v_1001640, v_1001641), v_1001648 => +v_1001642 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1001648); template_match_446(v_1001642, v_3, v_5, v_1, v_7, v_11, v_13, v_15, v_20)}}

def template_match_448(+v_1001631: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_3: String, +v_5: U32, v_60: List<&2, cps_provider_1_Layout>, v_56: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001631:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the inline arm `", v_3, "` has no declared fields"]}}, False{}, v_1001634 => template_body_cps_provider_2_join_text(["the inline arm `", v_3, "` has no declared fields"]), v_1001633 => +v_1001632 = template_unbox(String, v_1001633); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001632}}}}
    case Some{v_64}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_ordinal_in{v_64, U32.from_nat(0n), v_5, U32.from_nat(0n)}}, False{}, v_1001653 => template_body_cps_provider_2_live_ordinal_in(v_64, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1001652 => +v_1001635 = template_unbox(Maybe<&2, U32>, v_1001652); template_match_447(v_1001635, v_3, v_60, v_56, v_5, v_1, v_7, v_11, v_13, v_15, v_20)}

def template_match_449(+v_1001627: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_3: String, +v_1: cps_provider_2_World, +v_5: U32, v_56: List<&2, cps_provider_1_LayArm>, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001627:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the inline form has no arm `", v_3, "`"]}}, False{}, v_1001630 => template_body_cps_provider_2_join_text(["the inline form has no arm `", v_3, "`"]), v_1001629 => +v_1001628 = template_unbox(String, v_1001629); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001628}}}}
    case Some{v_60}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_descriptor_fields{v_1, v_3}}, False{}, v_1001655 => template_body_cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1001654 => +v_1001631 = template_unbox(Maybe<&2, List<&2, BIR.DescriptorField>>, v_1001654); template_match_448(v_1001631, v_3, v_5, v_60, v_56, v_1, v_7, v_11, v_13, v_15, v_20)}

def template_continuation_450(+v_15: String, v_85: String, +v_1001659: cps_provider_2_World, +v_1001660: String, +v_1001661: U32, +v_1001662: Nat, +v_1001663: String, +v_1001666: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  +v_1001667 = {v_15 : String}
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_static_expr{v_85}}, False{}, v_1001675 => template_body_cps_provider_2_static_expr(v_85), v_1001674 => +v_1001668 = template_unbox(String, v_1001674); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_or_expr{v_1001667, v_1001668}}, False{}, v_1001673 => template_body_cps_provider_2_or_expr(v_1001667, v_1001668), v_1001672 => +v_1001669 = template_unbox(String, v_1001672); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_resolve_node_slot{v_1001659, v_1001660, v_1001661, v_1001662, v_1001663, v_1001666, v_1001669, v_20}}, v_1001671 => +v_1001670 = template_unbox(cps_provider_2_PathResult, v_1001671); TemplateFinished{TemplateValue{v_1001670}}}}}

def template_continuation_451(+v_13: String, +v_85: String, +v_15: String, +v_1001659: cps_provider_2_World, +v_1001660: String, +v_1001661: U32, +v_1001662: Nat, +v_1001663: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  +v_1001664 = {v_13 : String}
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unique_expr{v_85}}, False{}, v_1001679 => template_body_cps_provider_2_unique_expr(v_85), v_1001678 => +v_1001665 = template_unbox(String, v_1001678); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_and_expr{v_1001664, v_1001665}}, False{}, v_1001677 => template_body_cps_provider_2_and_expr(v_1001664, v_1001665), v_1001676 => +v_1001666 = template_unbox(String, v_1001676); template_continuation_450(v_15, v_85, v_1001659, v_1001660, v_1001661, v_1001662, v_1001663, v_1001666, v_20)}}

def template_continuation_452(+v_1001658: String, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["term_peek(e.mem, (", v_1001658, "))"]}}, False{}, v_1001681 => template_body_cps_provider_2_join_text(["term_peek(e.mem, (", v_1001658, "))"]), v_1001680 => +v_1001663 = template_unbox(String, v_1001680); template_continuation_451(v_13, v_1001658, v_15, {v_1 : cps_provider_2_World}, {v_3 : String}, {v_5 : U32}, {0n : Nat}, v_1001663, v_20)}

def template_match_453(+v_9: cps_provider_1_Layout, +v_3: String, +v_1: cps_provider_2_World, +v_5: U32, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_9:
    case cps_provider_1_LayoutData{v_55, +v_56}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_fields_of{v_56, v_3}}, False{}, v_1001657 => template_body_cps_provider_2_arm_fields_of(v_56, v_3), v_1001656 => +v_1001627 = template_unbox(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_1001656); template_match_449(v_1001627, v_3, v_1, v_5, v_56, v_7, v_11, v_13, v_15, v_20)}
    case cps_provider_1_LayoutBox{v_82}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["e.mem[", v_11, " + ", Nat.show(v_7), "]"]}}, False{}, v_1001683 => template_body_cps_provider_2_join_text(["e.mem[", v_11, " + ", Nat.show(v_7), "]"]), v_1001682 => +v_1001658 = template_unbox(String, v_1001682); template_continuation_452(v_1001658, v_1, v_3, v_5, v_13, v_15, v_20)}
    case cps_provider_1_LayoutWord{v_93}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a nested Project path continues through a raw word"}}}

def template_body_cps_provider_2_resolve_slot_field(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: cps_provider_1_Layout, +v_11: String, +v_13: String, +v_15: String, +v_17: Bool, +v_20: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_17:
    case True{}:
      template_match_444(v_9, v_3, v_1, v_5, v_11, v_13, v_15, v_20)
    case False{}:
      template_match_453(v_9, v_3, v_1, v_5, v_7, v_11, v_13, v_15, v_20)

def template_match_455(+v_9: Bool, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_13: cps_provider_1_Layout, +v_7: String, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_9:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a BUF array cell cannot contain a boxed field"}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_7, " + (", v_11, ")"]}}, False{}, v_1001692 => template_body_cps_provider_2_join_text([v_7, " + (", v_11, ")"]), v_1001691 => +v_1001689 = template_unbox(String, v_1001691); template_body_cps_provider_2_resolve_slot_field({v_1 : cps_provider_2_World}, {v_3 : String}, {v_5 : U32}, {0n : Nat}, {v_13 : cps_provider_1_Layout}, v_1001689, v_17, v_19, False{}, v_22)}

def template_match_456(+v_9: Bool, +v_1: cps_provider_2_World, +v_7: String, +v_11: String, v_53: Nat, v_54: cps_provider_1_Layout, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_9:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_11, " + ", Nat.show(v_53)]}}, False{}, v_1001718 => template_body_cps_provider_2_join_text([v_11, " + ", Nat.show(v_53)]), v_1001717 => +v_1001714 = template_unbox(String, v_1001717); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{{v_1 : cps_provider_2_World}, cps_provider_2_StBufField{{v_7 : String}, v_1001714, v_54, v_17, v_19}, v_22}}, v_1001716 => +v_1001715 = template_unbox(cps_provider_2_PathResult, v_1001716); TemplateFinished{TemplateValue{v_1001715}}}}
    case False{}:
      v_1001720 = {v_53 : Nat}
      v_1001721 = {v_54 : cps_provider_1_Layout}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_7, " + (", v_11, ")"]}}, False{}, v_1001726 => template_body_cps_provider_2_join_text([v_7, " + (", v_11, ")"]), v_1001725 => +v_1001722 = template_unbox(String, v_1001725); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{{v_1 : cps_provider_2_World}, cps_provider_2_StSlot{v_1001720, v_1001721, v_1001722, v_17, v_19, False{}}, v_22}}, v_1001724 => +v_1001723 = template_unbox(cps_provider_2_PathResult, v_1001724); TemplateFinished{TemplateValue{v_1001723}}}}

def template_match_457(v_48: cps_provider_1_NodeSlot, +v_9: Bool, +v_1: cps_provider_2_World, +v_7: String, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_48:
    case cps_provider_1_NodeSlot{v_52, v_53, v_54}:
      template_match_456(v_9, v_1, v_7, v_11, v_53, v_54, v_17, v_19, v_22)

def template_match_458(+v_1001708: Maybe<&2, cps_provider_1_NodeSlot>, +v_3: String, +v_5: U32, +v_9: Bool, +v_1: cps_provider_2_World, +v_7: String, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001708:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the inline cell arm `", v_3, "` has no live field ", U32.show(v_5)]}}, False{}, v_1001711 => template_body_cps_provider_2_join_text(["the inline cell arm `", v_3, "` has no live field ", U32.show(v_5)]), v_1001710 => +v_1001709 = template_unbox(String, v_1001710); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001709}}}}
    case Some{v_48}:
      template_match_457(v_48, v_9, v_1, v_7, v_11, v_17, v_19, v_22)

def template_match_459(+v_1001701: Maybe<&2, U32>, +v_3: String, v_35: List<&2, cps_provider_1_Layout>, v_31: List<&2, cps_provider_1_LayArm>, +v_5: U32, +v_9: Bool, +v_1: cps_provider_2_World, +v_7: String, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001701:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the projection of `", v_3, "` names an erased cell field"]}}, False{}, v_1001704 => template_body_cps_provider_2_join_text(["the projection of `", v_3, "` names an erased cell field"]), v_1001703 => +v_1001702 = template_unbox(String, v_1001703); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001702}}}}
    case Some{v_43}:
      +v_1001705 = {v_35 : List<&2, cps_provider_1_Layout>}
      +v_1001706 = {U32.to_nat(v_43) : Nat}
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_start{v_31}}, False{}, v_1001730 => template_body_cps_provider_2_inline_start(v_31), v_1001729 => +v_1001707 = template_unbox(Nat, v_1001729); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_slot{v_1001705, v_1001706, v_1001707}}, False{}, v_1001728 => template_body_cps_provider_2_inline_slot(v_1001705, v_1001706, v_1001707), v_1001727 => +v_1001708 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1001727); template_match_458(v_1001708, v_3, v_5, v_9, v_1, v_7, v_11, v_17, v_19, v_22)}}

def template_match_460(+v_1001697: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_3: String, +v_5: U32, v_35: List<&2, cps_provider_1_Layout>, v_31: List<&2, cps_provider_1_LayArm>, +v_9: Bool, +v_1: cps_provider_2_World, +v_7: String, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001697:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the inline cell arm `", v_3, "` has no declared fields"]}}, False{}, v_1001700 => template_body_cps_provider_2_join_text(["the inline cell arm `", v_3, "` has no declared fields"]), v_1001699 => +v_1001698 = template_unbox(String, v_1001699); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001698}}}}
    case Some{v_39}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_ordinal_in{v_39, U32.from_nat(0n), v_5, U32.from_nat(0n)}}, False{}, v_1001732 => template_body_cps_provider_2_live_ordinal_in(v_39, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1001731 => +v_1001701 = template_unbox(Maybe<&2, U32>, v_1001731); template_match_459(v_1001701, v_3, v_35, v_31, v_5, v_9, v_1, v_7, v_11, v_17, v_19, v_22)}

def template_match_461(+v_1001693: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_3: String, +v_1: cps_provider_2_World, +v_5: U32, v_31: List<&2, cps_provider_1_LayArm>, +v_9: Bool, +v_7: String, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001693:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the inline cell has no arm `", v_3, "`"]}}, False{}, v_1001696 => template_body_cps_provider_2_join_text(["the inline cell has no arm `", v_3, "`"]), v_1001695 => +v_1001694 = template_unbox(String, v_1001695); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001694}}}}
    case Some{v_35}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_descriptor_fields{v_1, v_3}}, False{}, v_1001734 => template_body_cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1001733 => +v_1001697 = template_unbox(Maybe<&2, List<&2, BIR.DescriptorField>>, v_1001733); template_match_460(v_1001697, v_3, v_5, v_35, v_31, v_9, v_1, v_7, v_11, v_17, v_19, v_22)}

def template_body_cps_provider_2_resolve_cell_field(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_13: cps_provider_1_Layout, +v_15: Nat, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_13:
    case cps_provider_1_LayoutBox{v_1004419}:
      template_match_455(v_9, v_1, v_3, v_5, v_13, v_7, v_11, v_17, v_19, v_22)
    case cps_provider_1_LayoutData{v_1004420, +v_1004421}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_fields_of{v_1004421, v_3}}, False{}, v_1004422 => template_body_cps_provider_2_arm_fields_of(v_1004421, v_3), v_1004423 => +v_1004424 = template_unbox(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_1004423); template_match_461(v_1004424, v_3, v_1, v_5, v_1004421, v_9, v_7, v_11, v_17, v_19, v_22)}
    case cps_provider_1_LayoutWord{v_1004425}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a nested Project path continues through a raw cell word"}}}

def template_match_463(v_40: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_40:
    case cps_provider_1_NodeSlot{v_44, v_45, v_46}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, " + ", Nat.show(v_45)]}}, False{}, v_1001762 => template_body_cps_provider_2_join_text([v_9, " + ", Nat.show(v_45)]), v_1001761 => +v_1001758 = template_unbox(String, v_1001761); TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{{v_1 : cps_provider_2_World}, cps_provider_2_StBufField{{v_7 : String}, v_1001758, v_46, v_13, v_15}, v_18}}, v_1001760 => +v_1001759 = template_unbox(cps_provider_2_PathResult, v_1001760); TemplateFinished{TemplateValue{v_1001759}}}}

def template_match_464(+v_1001752: Maybe<&2, cps_provider_1_NodeSlot>, +v_3: String, +v_5: U32, +v_1: cps_provider_2_World, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001752:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the BUF inline arm `", v_3, "` has no live field ", U32.show(v_5)]}}, False{}, v_1001755 => template_body_cps_provider_2_join_text(["the BUF inline arm `", v_3, "` has no live field ", U32.show(v_5)]), v_1001754 => +v_1001753 = template_unbox(String, v_1001754); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001753}}}}
    case Some{v_40}:
      template_match_463(v_40, v_1, v_7, v_9, v_13, v_15, v_18)

def template_match_465(+v_1001745: Maybe<&2, U32>, +v_3: String, v_27: List<&2, cps_provider_1_Layout>, v_23: List<&2, cps_provider_1_LayArm>, +v_5: U32, +v_1: cps_provider_2_World, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001745:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the projection of `", v_3, "` names an erased BUF field"]}}, False{}, v_1001748 => template_body_cps_provider_2_join_text(["the projection of `", v_3, "` names an erased BUF field"]), v_1001747 => +v_1001746 = template_unbox(String, v_1001747); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001746}}}}
    case Some{v_35}:
      +v_1001749 = {v_27 : List<&2, cps_provider_1_Layout>}
      +v_1001750 = {U32.to_nat(v_35) : Nat}
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_start{v_23}}, False{}, v_1001766 => template_body_cps_provider_2_inline_start(v_23), v_1001765 => +v_1001751 = template_unbox(Nat, v_1001765); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_inline_slot{v_1001749, v_1001750, v_1001751}}, False{}, v_1001764 => template_body_cps_provider_2_inline_slot(v_1001749, v_1001750, v_1001751), v_1001763 => +v_1001752 = template_unbox(Maybe<&2, cps_provider_1_NodeSlot>, v_1001763); template_match_464(v_1001752, v_3, v_5, v_1, v_7, v_9, v_13, v_15, v_18)}}

def template_match_466(+v_1001741: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_3: String, +v_5: U32, v_27: List<&2, cps_provider_1_Layout>, v_23: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001741:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the BUF inline arm `", v_3, "` has no declared fields"]}}, False{}, v_1001744 => template_body_cps_provider_2_join_text(["the BUF inline arm `", v_3, "` has no declared fields"]), v_1001743 => +v_1001742 = template_unbox(String, v_1001743); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001742}}}}
    case Some{v_31}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_live_ordinal_in{v_31, U32.from_nat(0n), v_5, U32.from_nat(0n)}}, False{}, v_1001768 => template_body_cps_provider_2_live_ordinal_in(v_31, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1001767 => +v_1001745 = template_unbox(Maybe<&2, U32>, v_1001767); template_match_465(v_1001745, v_3, v_27, v_23, v_5, v_1, v_7, v_9, v_13, v_15, v_18)}

def template_match_467(+v_1001737: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_3: String, +v_1: cps_provider_2_World, +v_5: U32, v_23: List<&2, cps_provider_1_LayArm>, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001737:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the BUF inline form has no arm `", v_3, "`"]}}, False{}, v_1001740 => template_body_cps_provider_2_join_text(["the BUF inline form has no arm `", v_3, "`"]), v_1001739 => +v_1001738 = template_unbox(String, v_1001739); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001738}}}}
    case Some{v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_descriptor_fields{v_1, v_3}}, False{}, v_1001770 => template_body_cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1001769 => +v_1001741 = template_unbox(Maybe<&2, List<&2, BIR.DescriptorField>>, v_1001769); template_match_466(v_1001741, v_3, v_5, v_27, v_23, v_1, v_7, v_9, v_13, v_15, v_18)}

def template_body_cps_provider_2_resolve_buf_field(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_11: cps_provider_1_Layout, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_11:
    case cps_provider_1_LayoutData{v_1004426, +v_1004427}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_arm_fields_of{v_1004427, v_3}}, False{}, v_1004428 => template_body_cps_provider_2_arm_fields_of(v_1004427, v_3), v_1004429 => +v_1004430 = template_unbox(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_1004429); template_match_467(v_1004430, v_3, v_1, v_5, v_1004427, v_7, v_9, v_13, v_15, v_18)}
    case cps_provider_1_LayoutBox{v_1004431}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a BUF inline form cannot hold a boxed field"}}}
    case cps_provider_1_LayoutWord{v_1004432}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a BUF raw word has no nested projection"}}}

def template_match_469(v_29: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_29:
    case cps_provider_1_NodeSlot{v_33, v_34, v_35}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{v_1, cps_provider_2_StSlot{Nat.add(v_7, v_34), v_35, v_9, v_11, v_13, False{}}, v_16}}, v_1001778 => +v_1001777 = template_unbox(cps_provider_2_PathResult, v_1001778); TemplateFinished{TemplateValue{v_1001777}}}

def template_match_470(+v_1001773: cps_provider_1_SlotResult, +v_3: String, +v_1: cps_provider_2_World, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001773:
    case cps_provider_1_SlotErased{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the projection of `", v_3, "` names an erased field"]}}, False{}, v_1001776 => template_body_cps_provider_2_join_text(["the projection of `", v_3, "` names an erased field"]), v_1001775 => +v_1001774 = template_unbox(String, v_1001775); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001774}}}}
    case cps_provider_1_SlotFailed{v_27}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_27}}}
    case cps_provider_1_SlotFound{v_29}:
      template_match_469(v_29, v_1, v_7, v_9, v_11, v_13, v_16)

def template_body_cps_provider_2_resolve_node_slot(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1:
    case cps_provider_2_World{v_21, v_22, v_23}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slot{v_21, v_3, v_5}}, False{}, v_1001780 => template_body_cps_provider_1_node_slot(v_21, v_3, v_5), v_1001779 => +v_1001773 = template_unbox(cps_provider_1_SlotResult, v_1001779); template_match_470(v_1001773, v_3, v_1, v_7, v_9, v_11, v_13, v_16)}

def template_match_472(+v_1001785: cps_provider_2_PathResult, +v_1: cps_provider_2_World, +v_5: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001785:
    case cps_provider_2_PathFail{v_11}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_11}}}
    case cps_provider_2_PathOk{v_13}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{v_1, v_13, v_5}}, v_1001787 => +v_1001786 = template_unbox(cps_provider_2_PathResult, v_1001787); TemplateFinished{TemplateValue{v_1001786}}}

def template_body_cps_provider_2_root_array_path(+v_1: cps_provider_2_World, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  +v_1001781 = {v_1 : cps_provider_2_World}
  +v_1001782 = {"pbt" : String}
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unique_expr{"pbt"}}, False{}, v_1001793 => template_body_cps_provider_2_unique_expr("pbt"), v_1001792 => +v_1001783 = template_unbox(String, v_1001792); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_static_expr{"pbt"}}, False{}, v_1001791 => template_body_cps_provider_2_static_expr("pbt"), v_1001790 => +v_1001784 = template_unbox(String, v_1001790); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_state_from_array_value{v_1001781, v_1001782, v_1001783, v_1001784, v_2}}, False{}, v_1001789 => template_body_cps_provider_2_state_from_array_value(v_1001781, v_1001782, v_1001783, v_1001784, v_2), v_1001788 => +v_1001785 = template_unbox(cps_provider_2_PathResult, v_1001788); template_match_472(v_1001785, v_1, v_5)}}}

def template_match_473(+v_1001794: cps_provider_2_PathResult) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001794:
    case cps_provider_2_PathFail{v_18}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_18}}}
    case cps_provider_2_PathOk{v_20}:
      TemplateFinished{TemplateValue{cps_provider_2_PathOk{v_20}}}

def template_match_474(+v_1001797: cps_provider_2_PathResult, +v_1: cps_provider_2_World, v_11: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001797:
    case cps_provider_2_PathFail{v_27}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_27}}}
    case cps_provider_2_PathOk{v_29}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{v_1, v_29, v_11}}, v_1001799 => +v_1001798 = template_unbox(cps_provider_2_PathResult, v_1001799); TemplateFinished{TemplateValue{v_1001798}}}

def template_match_475(+v_1001801: cps_provider_2_PathResult, +v_1: cps_provider_2_World, v_11: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001801:
    case cps_provider_2_PathFail{v_35}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_35}}}
    case cps_provider_2_PathOk{v_37}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{v_1, v_37, v_11}}, v_1001803 => +v_1001802 = template_unbox(cps_provider_2_PathResult, v_1001803); TemplateFinished{TemplateValue{v_1001802}}}

def template_match_476(+v_10: cps_provider_2_PathStep, +v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_11: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_10:
    case cps_provider_2_PathField{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_resolve_field{v_1, v_3, v_14, v_15, v_11}}, False{}, v_1001796 => template_body_cps_provider_2_resolve_field(v_1, v_3, v_14, v_15, v_11), v_1001795 => +v_1001794 = template_unbox(cps_provider_2_PathResult, v_1001795); template_match_473(v_1001794)}
    case cps_provider_2_PathHalf{v_23, v_24}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_half_state{v_1, v_3, v_23, v_24, v_11}}, v_1001800 => +v_1001797 = template_unbox(cps_provider_2_PathResult, v_1001800); template_match_474(v_1001797, v_1, v_11)}
    case cps_provider_2_PathLeafCell{v_32}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_leaf_state{v_1, v_3, v_32, v_11}}, v_1001804 => +v_1001801 = template_unbox(cps_provider_2_PathResult, v_1001804); template_match_475(v_1001801, v_1, v_11)}

def template_body_cps_provider_2_advance(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_6: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_PathOk{v_3}}}
    case +v_1004433 <> v_1004434:
      template_match_476(v_1004433, v_1, v_3, v_1004434)

def template_continuation_478(+v_1001805: String, +v_1: cps_provider_2_World, v_33: String, v_34: String, +v_4: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  template_body_cps_provider_2_state_from_array_value(v_1, v_1001805, v_33, v_34, v_4)

def template_match_479(v_31: cps_provider_1_Layout, v_32: String, v_30: Nat, +v_1: cps_provider_2_World, v_33: String, v_34: String, +v_4: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_31:
    case cps_provider_1_LayoutBox{v_37}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["e.mem[", v_32, " + ", Nat.show(v_30), "]"]}}, False{}, v_1001808 => template_body_cps_provider_2_join_text(["e.mem[", v_32, " + ", Nat.show(v_30), "]"]), v_1001807 => +v_1001805 = template_unbox(String, v_1001807); template_continuation_478(v_1001805, v_1, v_33, v_34, v_4)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"an array half or leaf needs a boxed array value"}}}

def template_continuation_480(+v_1001809: String, +v_1: cps_provider_2_World, v_60: String, v_61: String, +v_4: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  template_body_cps_provider_2_state_from_array_value(v_1, v_1001809, v_60, v_61, v_4)

def template_match_481(v_57: cps_provider_1_Layout, v_54: String, v_53: String, v_55: String, +v_1: cps_provider_2_World, v_60: String, v_61: String, +v_4: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_57:
    case cps_provider_1_LayoutBox{v_63}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["blk_read(e.mem, ", v_54, ", ", v_53, ", (u32)(", v_55, "))"]}}, False{}, v_1001812 => template_body_cps_provider_2_join_text(["blk_read(e.mem, ", v_54, ", ", v_53, ", (u32)(", v_55, "))"]), v_1001811 => +v_1001809 = template_unbox(String, v_1001811); template_continuation_480(v_1001809, v_1, v_60, v_61, v_4)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"an array half or leaf needs a boxed array element"}}}

def template_body_cps_provider_2_array_from_state(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_4: BIR.Descriptor) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_3:
    case cps_provider_2_StArray{v_1004435, v_1004436, v_1004437, v_1004438, v_1004439, v_1004440, v_1004441, v_1004442, v_1004443}:
      TemplateFinished{TemplateValue{cps_provider_2_PathOk{v_3}}}
    case cps_provider_2_StSlot{v_1004444, v_1004445, v_1004446, v_1004447, v_1004448, v_1004449}:
      template_match_479(v_1004445, v_1004446, v_1004444, v_1, v_1004447, v_1004448, v_4)
    case cps_provider_2_StCell{v_1004450, v_1004451, v_1004452, v_1004453, v_1004454, v_1004455, v_1004456, v_1004457, v_1004458}:
      template_match_481(v_1004454, v_1004451, v_1004450, v_1004452, v_1, v_1004457, v_1004458, v_4)
    case cps_provider_2_StBufField{v_1004459, v_1004460, v_1004461, v_1004462, v_1004463}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"an array half or leaf needs a boxed array element"}}}

def template_continuation_483(+v_1001820: String, v_25: String, v_27: Nat, v_28: cps_provider_1_Layout, v_29: String, v_38: String, v_31: Bool, v_32: String, v_33: String) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateFinished{TemplateValue{cps_provider_2_PathOk{cps_provider_2_StArray{v_25, v_1001820, v_27, v_28, v_29, v_38, v_31, v_32, v_33}}}}

def template_continuation_484(+v_1001819: String, v_26: String, v_25: String, v_27: Nat, v_28: cps_provider_1_Layout, v_29: String, v_31: Bool, v_32: String, v_33: String) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((", v_26, ") - 1)"]}}, False{}, v_1001822 => template_body_cps_provider_2_join_text(["((", v_26, ") - 1)"]), v_1001821 => +v_1001820 = template_unbox(String, v_1001821); template_continuation_483(v_1001820, v_25, v_27, v_28, v_29, v_1001819, v_31, v_32, v_33)}

def template_continuation_485(+v_1001828: String, v_25: String, v_27: Nat, v_28: cps_provider_1_Layout, v_29: String, v_38: String, v_31: Bool, v_32: String, v_33: String) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateFinished{TemplateValue{cps_provider_2_PathOk{cps_provider_2_StArray{v_25, v_1001828, v_27, v_28, v_29, v_38, v_31, v_32, v_33}}}}

def template_continuation_486(+v_1001827: String, v_26: String, v_25: String, v_27: Nat, v_28: cps_provider_1_Layout, v_29: String, v_31: Bool, v_32: String, v_33: String) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((", v_26, ") - 1)"]}}, False{}, v_1001830 => template_body_cps_provider_2_join_text(["((", v_26, ") - 1)"]), v_1001829 => +v_1001828 = template_unbox(String, v_1001829); template_continuation_485(v_1001828, v_25, v_27, v_28, v_29, v_1001827, v_31, v_32, v_33)}

def template_match_487(v_1001817: Bool, +v_26: String, v_1001814: String, v_1001815: String, v_1001816: String, v_25: String, v_27: Nat, v_28: cps_provider_1_Layout, v_29: String, v_31: Bool, v_32: String, v_33: String) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001817:
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(1ull << ((", v_26, ") - 1))"]}}, False{}, v_1001826 => template_body_cps_provider_2_join_text(["(1ull << ((", v_26, ") - 1))"]), v_1001825 => +v_1001818 = template_unbox(String, v_1001825); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001814, v_1001815, v_1001816, v_1001818, ")"]}}, False{}, v_1001824 => template_body_cps_provider_2_join_text([v_1001814, v_1001815, v_1001816, v_1001818, ")"]), v_1001823 => +v_1001819 = template_unbox(String, v_1001823); template_continuation_484(v_1001819, v_26, v_25, v_27, v_28, v_29, v_31, v_32, v_33)}}
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001814, v_1001815, v_1001816, "0", ")"]}}, False{}, v_1001832 => template_body_cps_provider_2_join_text([v_1001814, v_1001815, v_1001816, "0", ")"]), v_1001831 => +v_1001827 = template_unbox(String, v_1001831); template_continuation_486(v_1001827, v_26, v_25, v_27, v_28, v_29, v_31, v_32, v_33)}

def template_match_488(v_15: cps_provider_2_PathState, +v_5: Bool) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_15:
    case cps_provider_2_StArray{v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33}:
      template_match_487(v_5, v_26, {"(u64)((" : String}, {v_30 : String}, {") + " : String}, v_25, v_27, v_28, v_29, v_31, v_32, v_33)
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"not an array state"}}}

def template_match_489(+v_1001813: cps_provider_2_PathResult, +v_5: Bool) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001813:
    case cps_provider_2_PathFail{v_13}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_13}}}
    case cps_provider_2_PathOk{v_15}:
      template_match_488(v_15, v_5)

def template_body_cps_provider_2_half_state(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_5: Bool, +v_6: BIR.Descriptor, +v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_array_from_state{v_1, v_3, v_6}}, False{}, v_1001834 => template_body_cps_provider_2_array_from_state(v_1, v_3, v_6), v_1001833 => +v_1001813 = template_unbox(cps_provider_2_PathResult, v_1001833); template_match_489(v_1001813, v_5)}

def template_match_490(v_13: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_13:
    case cps_provider_2_StArray{v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31}:
      TemplateFinished{TemplateValue{cps_provider_2_PathOk{cps_provider_2_StCell{v_23, v_27, v_28, v_24, v_26, v_25, v_29, v_30, v_31}}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"not an array state"}}}

def template_match_491(+v_1001835: cps_provider_2_PathResult) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001835:
    case cps_provider_2_PathFail{v_11}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_11}}}
    case cps_provider_2_PathOk{v_13}:
      template_match_490(v_13)

def template_body_cps_provider_2_leaf_state(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_array_from_state{v_1, v_3, v_4}}, False{}, v_1001837 => template_body_cps_provider_2_array_from_state(v_1, v_3, v_4), v_1001836 => +v_1001835 = template_unbox(cps_provider_2_PathResult, v_1001836); template_match_491(v_1001835)}

def template_match_492(v_37: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_37:
    case cps_provider_1_NodeSlot{v_41, v_42, v_43}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_advance{v_1, cps_provider_2_StSlot{0n, v_43, "pbn", "0", "1", True{}}, v_9}}, False{}, v_1001846 => template_body_cps_provider_2_advance(v_1, cps_provider_2_StSlot{0n, v_43, "pbn", "0", "1", True{}}, v_9), v_1001845 => +v_1001844 = template_unbox(cps_provider_2_PathResult, v_1001845); TemplateFinished{TemplateValue{v_1001844}}}

def template_match_493(+v_1001843: cps_provider_1_SlotResult, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001843:
    case cps_provider_1_SlotFound{v_37}:
      template_match_492(v_37, v_1, v_9)
    case cps_provider_1_SlotErased{}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a packed projection names an erased field"}}}
    case cps_provider_1_SlotFailed{v_46}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_46}}}

def template_match_494(v_34: Bool, v_21: cps_provider_1_Context, v_17: String, v_13: U32, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_34:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slot{v_21, v_17, v_13}}, False{}, v_1001848 => template_body_cps_provider_1_node_slot(v_21, v_17, v_13), v_1001847 => +v_1001843 = template_unbox(cps_provider_1_SlotResult, v_1001847); template_match_493(v_1001843, v_1, v_9)}
    case False{}:
      +v_1001850 = {v_17 : String}
      +v_1001851 = {v_13 : U32}
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unique_expr{"pbt"}}, False{}, v_1001860 => template_body_cps_provider_2_unique_expr("pbt"), v_1001859 => +v_1001854 = template_unbox(String, v_1001859); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_static_expr{"pbt"}}, False{}, v_1001858 => template_body_cps_provider_2_static_expr("pbt"), v_1001857 => +v_1001855 = template_unbox(String, v_1001857); template_body_cps_provider_2_resolve_node_slot({v_1 : cps_provider_2_World}, v_1001850, v_1001851, {0n : Nat}, {"pbn" : String}, v_1001854, v_1001855, v_9)}}

def template_match_495(v_28: cps_provider_1_Node, v_21: cps_provider_1_Context, v_17: String, v_13: U32, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_28:
    case cps_provider_1_Node{v_32, v_33, v_34}:
      template_match_494(v_34, v_21, v_17, v_13, v_1, v_9)

def template_match_496(+v_1001842: cps_provider_1_NodeResult, v_21: cps_provider_1_Context, v_17: String, v_13: U32, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001842:
    case cps_provider_1_NodeFailed{v_26}:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_26}}}
    case cps_provider_1_NodeFound{v_28}:
      template_match_495(v_28, v_21, v_17, v_13, v_1, v_9)

def template_match_497(+v_1: cps_provider_2_World, +v_17: String, v_13: U32, v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1:
    case cps_provider_2_World{+v_21, v_22, v_23}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_layout{v_21, v_17}}, False{}, v_1001862 => template_body_cps_provider_1_node_layout(v_21, v_17), v_1001861 => +v_1001842 = template_unbox(cps_provider_1_NodeResult, v_1001861); template_match_496(v_1001842, v_21, v_17, v_13, v_1, v_9)}

def template_match_498(+v_1001838: Maybe<&2, String>, v_12: U32, +v_1: cps_provider_2_World, v_13: U32, v_9: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_1001838:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["BIR projects constructor ", U32.show(v_12), " with no layout row"]}}, False{}, v_1001841 => template_body_cps_provider_2_join_text(["BIR projects constructor ", U32.show(v_12), " with no layout row"]), v_1001840 => +v_1001839 = template_unbox(String, v_1001840); TemplateFinished{TemplateValue{cps_provider_2_PathFail{v_1001839}}}}
    case Some{v_17}:
      template_match_497(v_1, v_17, v_13, v_9)

def template_match_499(+v_8: cps_provider_2_PathStep, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>, +v_4: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_8:
    case cps_provider_2_PathField{+v_12, v_13}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_step_key{v_1, v_12}}, False{}, v_1001864 => template_body_cps_provider_2_step_key(v_1, v_12), v_1001863 => +v_1001838 = template_unbox(Maybe<&2, String>, v_1001863); template_match_498(v_1001838, v_12, v_1, v_13, v_9)}
    case cps_provider_2_PathHalf{v_52, v_53}:
      template_body_cps_provider_2_root_array_path(v_1, v_53, v_4)
    case cps_provider_2_PathLeafCell{v_56}:
      template_body_cps_provider_2_root_array_path(v_1, v_56, v_4)

def template_body_cps_provider_2_resolve_path(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_2_PathStep>) -> TemplateProgress<cps_provider_2_PathResult>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_PathFail{"a Project path is empty"}}}
    case +v_1004464 <> v_1004465:
      template_match_499(v_1004464, v_1, v_1004465, v_4)

def template_body_cps_provider_2_path_prelude(+v_1: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term pbt = (", v_1, "); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; "]}}, False{}, v_1001869 => template_body_cps_provider_2_join_text(["Term pbt = (", v_1, "); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; "]), v_1001868 => +v_1001867 = template_unbox(String, v_1001868); TemplateFinished{TemplateValue{v_1001867}}}

def template_body_cps_provider_2_path_expr(+v_1: String, +v_3: String) -> TemplateProgress<String>:
  v_1001870 = {"({\n" : String}
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_prelude{v_1}}, False{}, v_1001876 => template_body_cps_provider_2_path_prelude(v_1), v_1001875 => +v_1001871 = template_unbox(String, v_1001875); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001870, v_1001871, v_3, "pbr;\n})"]}}, False{}, v_1001874 => template_body_cps_provider_2_join_text([v_1001870, v_1001871, v_3, "pbr;\n})"]), v_1001873 => +v_1001872 = template_unbox(String, v_1001873); TemplateFinished{TemplateValue{v_1001872}}}}

def template_continuation_501(+v_1001880: String, +v_13: String, +v_5: String, +v_3: String, +v_9: Nat, +v_7: Nat) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_13, "{ Term pbb = term_keep(e, ", v_1001880, ", 1); if (pbb != ", v_1001880, ") { if (", v_5, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_3, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { ", v_1001880, " = pbb; } } pbbuf[", Nat.show(Nat.sub(v_9, v_7)), "] = (u64)pbb; }\n"]}}, False{}, v_1001883 => template_body_cps_provider_2_join_text([v_13, "{ Term pbb = term_keep(e, ", v_1001880, ", 1); if (pbb != ", v_1001880, ") { if (", v_5, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_3, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { ", v_1001880, " = pbb; } } pbbuf[", Nat.show(Nat.sub(v_9, v_7)), "] = (u64)pbb; }\n"]), v_1001882 => +v_1001881 = template_unbox(String, v_1001882); TemplateFinished{TemplateValue{v_1001881}}}

def template_match_502(+v_29: cps_provider_1_LayArm, +v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_13: String) -> TemplateProgress<String>:
  match v_29:
    case cps_provider_1_LayArm{v_32, v_33}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy_fields{v_1, v_3, v_5, v_7, v_9, v_33, v_13}}, v_1001887 => +v_1001886 = template_unbox(String, v_1001887); TemplateFinished{TemplateValue{v_1001886}}}

def template_match_503(+v_27: List<&2, cps_provider_1_LayArm>, +v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_13: String) -> TemplateProgress<String>:
  match v_27:
    case []:
      TemplateFinished{TemplateValue{""}}
    case [+v_29]:
      template_match_502(v_29, v_1, v_3, v_5, v_7, v_9, v_13)
    case _:
      v_1001888 = {v_13 : String}
      v_1001889 = {"pbbuf[" : String}
      v_1001890 = {Nat.show(Nat.sub(v_9, v_7)) : String}
      v_1001891 = {"] = e.mem[" : String}
      v_1001892 = {v_1 : String}
      v_1001893 = {" + " : String}
      v_1001894 = {Nat.show(v_9) : String}
      v_1001895 = {"];\n" : String}
      v_1001896 = {v_13 : String}
      v_1001897 = {"switch ((u32)e.mem[" : String}
      v_1001898 = {v_1 : String}
      v_1001899 = {" + " : String}
      v_1001900 = {Nat.show(v_9) : String}
      v_1001901 = {"]) {\n" : String}
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy_cases{v_1, v_3, v_5, v_7, Nat.add(v_9, 1n), v_27, v_13, 0n}}, v_1001906 => +v_1001902 = template_unbox(String, v_1001906); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001888, v_1001889, v_1001890, v_1001891, v_1001892, v_1001893, v_1001894, v_1001895, v_1001896, v_1001897, v_1001898, v_1001899, v_1001900, v_1001901, v_1001902, v_13, "}\n"]}}, False{}, v_1001905 => template_body_cps_provider_2_join_text([v_1001888, v_1001889, v_1001890, v_1001891, v_1001892, v_1001893, v_1001894, v_1001895, v_1001896, v_1001897, v_1001898, v_1001899, v_1001900, v_1001901, v_1001902, v_13, "}\n"]), v_1001904 => +v_1001903 = template_unbox(String, v_1001904); TemplateFinished{TemplateValue{v_1001903}}}}

def template_body_cps_provider_2_keep_copy(+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_11: cps_provider_1_Layout, +v_13: String) -> TemplateProgress<String>:
  match v_11:
    case cps_provider_1_LayoutWord{v_1004466}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_13, "pbbuf[", Nat.show(Nat.sub(v_9, v_7)), "] = e.mem[", v_1, " + ", Nat.show(v_9), "];\n"]}}, False{}, v_1004467 => template_body_cps_provider_2_join_text([v_13, "pbbuf[", Nat.show(Nat.sub(v_9, v_7)), "] = e.mem[", v_1, " + ", Nat.show(v_9), "];\n"]), v_1004468 => +v_1004469 = template_unbox(String, v_1004468); TemplateFinished{TemplateValue{v_1004469}}}
    case cps_provider_1_LayoutBox{v_1004470}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["e.mem[", v_1, " + ", Nat.show(v_9), "]"]}}, False{}, v_1004471 => template_body_cps_provider_2_join_text(["e.mem[", v_1, " + ", Nat.show(v_9), "]"]), v_1004472 => +v_1004473 = template_unbox(String, v_1004472); template_continuation_501(v_1004473, v_13, v_5, v_3, v_9, v_7)}
    case cps_provider_1_LayoutData{v_1004474, v_1004475}:
      template_match_503(v_1004475, v_1, v_3, v_5, v_7, v_9, v_13)

def template_continuation_505(+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_18: cps_provider_1_Layout, v_19: List<&2, cps_provider_1_Layout>, +v_14: String, +v_1001907: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_18}}, False{}, v_1001920 => template_body_cps_provider_1_layout_words(v_18), v_1001919 => +v_1001913 = template_unbox(Nat, v_1001919); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy_fields{{v_1 : String}, {v_3 : String}, {v_5 : String}, {v_7 : Nat}, Nat.add({v_9 : Nat}, v_1001913), v_19, v_14}}, v_1001918 => +v_1001914 = template_unbox(String, v_1001918); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001907, v_1001914]}}, False{}, v_1001917 => template_body_cps_provider_2_join_text([v_1001907, v_1001914]), v_1001916 => +v_1001915 = template_unbox(String, v_1001916); TemplateFinished{TemplateValue{v_1001915}}}}}

def template_body_cps_provider_2_keep_copy_fields(+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: String) -> TemplateProgress<String>:
  match v_12:
    case []:
      TemplateFinished{TemplateValue{""}}
    case +v_1004476 <> v_1004477:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy{v_1, v_3, v_5, v_7, v_9, v_1004476, v_14}}, False{}, v_1004478 => template_body_cps_provider_2_keep_copy(v_1, v_3, v_5, v_7, v_9, v_1004476, v_14), v_1004479 => +v_1004480 = template_unbox(String, v_1004479); template_continuation_505(v_1, v_3, v_5, v_7, v_9, v_1004476, v_1004477, v_14, v_1004480)}

def template_continuation_507(+v_14: String, +v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, v_22: List<&2, cps_provider_1_LayArm>, +v_16: Nat, v_1001926: String, v_1001927: String, v_1001928: String, v_1001929: String, +v_1001937: String) -> TemplateProgress<String>:
  v_1001938 = {v_14 : String}
  v_1001939 = {"} break;\n" : String}
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy_cases{v_1, v_3, v_5, v_7, v_9, v_22, v_14, Nat.add(v_16, 1n)}}, v_1001944 => +v_1001940 = template_unbox(String, v_1001944); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001926, v_1001927, v_1001928, v_1001929, v_1001937, v_1001938, v_1001939, v_1001940]}}, False{}, v_1001943 => template_body_cps_provider_2_join_text([v_1001926, v_1001927, v_1001928, v_1001929, v_1001937, v_1001938, v_1001939, v_1001940]), v_1001942 => +v_1001941 = template_unbox(String, v_1001942); TemplateFinished{TemplateValue{v_1001941}}}}

def template_match_508(+v_21: cps_provider_1_LayArm, +v_14: String, +v_16: Nat, +v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, v_22: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<String>:
  match v_21:
    case cps_provider_1_LayArm{v_25, v_26}:
      v_1001928 = {Nat.show(v_16) : String}
      +v_1001930 = {v_1 : String}
      +v_1001931 = {v_3 : String}
      +v_1001932 = {v_5 : String}
      +v_1001933 = {v_7 : Nat}
      +v_1001934 = {v_9 : Nat}
      +v_1001935 = {v_26 : List<&2, cps_provider_1_Layout>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_14, "  "]}}, False{}, v_1001948 => template_body_cps_provider_2_join_text([v_14, "  "]), v_1001947 => +v_1001936 = template_unbox(String, v_1001947); TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy_fields{v_1001930, v_1001931, v_1001932, v_1001933, v_1001934, v_1001935, v_1001936}}, False{}, v_1001946 => template_body_cps_provider_2_keep_copy_fields(v_1001930, v_1001931, v_1001932, v_1001933, v_1001934, v_1001935, v_1001936), v_1001945 => +v_1001937 = template_unbox(String, v_1001945); template_continuation_507(v_14, v_1, v_3, v_5, v_7, v_9, v_22, v_16, {v_14 : String}, {"case " : String}, v_1001928, {": {\n" : String}, v_1001937)}}

def template_body_cps_provider_2_keep_copy_cases(+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_LayArm>, +v_14: String, +v_16: Nat) -> TemplateProgress<String>:
  match v_12:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_14, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"]}}, False{}, v_1004481 => template_body_cps_provider_2_join_text([v_14, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"]), v_1004482 => +v_1004483 = template_unbox(String, v_1004482); TemplateFinished{TemplateValue{v_1004483}}}
    case +v_1004484 <> v_1004485:
      template_match_508(v_1004484, v_14, v_16, v_1, v_3, v_5, v_7, v_9, v_1004485)

def template_match_510(+v_22: cps_provider_1_LayArm, +v_1: String, +v_3: Nat, +v_5: Nat, +v_9: String) -> TemplateProgress<String>:
  match v_22:
    case cps_provider_1_LayArm{v_25, v_26}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy_fields{v_1, v_3, v_5, v_26, v_9}}, v_1001956 => +v_1001955 = template_unbox(String, v_1001956); TemplateFinished{TemplateValue{v_1001955}}}

def template_match_511(+v_20: List<&2, cps_provider_1_LayArm>, +v_1: String, +v_3: Nat, +v_5: Nat, +v_9: String) -> TemplateProgress<String>:
  match v_20:
    case []:
      TemplateFinished{TemplateValue{""}}
    case [+v_22]:
      template_match_510(v_22, v_1, v_3, v_5, v_9)
    case _:
      v_1001957 = {v_9 : String}
      v_1001958 = {"pbbuf[" : String}
      v_1001959 = {Nat.show(Nat.sub(v_5, v_3)) : String}
      v_1001960 = {"] = e.mem[" : String}
      v_1001961 = {v_1 : String}
      v_1001962 = {" + " : String}
      v_1001963 = {Nat.show(v_5) : String}
      v_1001964 = {"];\n" : String}
      v_1001965 = {v_9 : String}
      v_1001966 = {"switch ((u32)e.mem[" : String}
      v_1001967 = {v_1 : String}
      v_1001968 = {" + " : String}
      v_1001969 = {Nat.show(v_5) : String}
      v_1001970 = {"]) {\n" : String}
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy_cases{v_1, v_3, Nat.add(v_5, 1n), v_20, v_9, 0n}}, v_1001975 => +v_1001971 = template_unbox(String, v_1001975); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001957, v_1001958, v_1001959, v_1001960, v_1001961, v_1001962, v_1001963, v_1001964, v_1001965, v_1001966, v_1001967, v_1001968, v_1001969, v_1001970, v_1001971, v_9, "}\n"]}}, False{}, v_1001974 => template_body_cps_provider_2_join_text([v_1001957, v_1001958, v_1001959, v_1001960, v_1001961, v_1001962, v_1001963, v_1001964, v_1001965, v_1001966, v_1001967, v_1001968, v_1001969, v_1001970, v_1001971, v_9, "}\n"]), v_1001973 => +v_1001972 = template_unbox(String, v_1001973); TemplateFinished{TemplateValue{v_1001972}}}}

def template_body_cps_provider_2_move_copy(+v_1: String, +v_3: Nat, +v_5: Nat, +v_7: cps_provider_1_Layout, +v_9: String) -> TemplateProgress<String>:
  match v_7:
    case cps_provider_1_LayoutWord{v_1004486}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, "pbbuf[", Nat.show(Nat.sub(v_5, v_3)), "] = e.mem[", v_1, " + ", Nat.show(v_5), "];\n"]}}, False{}, v_1004487 => template_body_cps_provider_2_join_text([v_9, "pbbuf[", Nat.show(Nat.sub(v_5, v_3)), "] = e.mem[", v_1, " + ", Nat.show(v_5), "];\n"]), v_1004488 => +v_1004489 = template_unbox(String, v_1004488); TemplateFinished{TemplateValue{v_1004489}}}
    case cps_provider_1_LayoutBox{v_1004490}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_9, "pbbuf[", Nat.show(Nat.sub(v_5, v_3)), "] = e.mem[", v_1, " + ", Nat.show(v_5), "]; e.mem[", v_1, " + ", Nat.show(v_5), "] = 0;\n"]}}, False{}, v_1004491 => template_body_cps_provider_2_join_text([v_9, "pbbuf[", Nat.show(Nat.sub(v_5, v_3)), "] = e.mem[", v_1, " + ", Nat.show(v_5), "]; e.mem[", v_1, " + ", Nat.show(v_5), "] = 0;\n"]), v_1004492 => +v_1004493 = template_unbox(String, v_1004492); TemplateFinished{TemplateValue{v_1004493}}}
    case cps_provider_1_LayoutData{v_1004494, v_1004495}:
      template_match_511(v_1004495, v_1, v_3, v_5, v_9)

def template_continuation_513(+v_1: String, +v_3: Nat, +v_5: Nat, +v_14: cps_provider_1_Layout, v_15: List<&2, cps_provider_1_Layout>, +v_10: String, +v_1001976: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_14}}, False{}, v_1001987 => template_body_cps_provider_1_layout_words(v_14), v_1001986 => +v_1001980 = template_unbox(Nat, v_1001986); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy_fields{{v_1 : String}, {v_3 : Nat}, Nat.add({v_5 : Nat}, v_1001980), v_15, v_10}}, v_1001985 => +v_1001981 = template_unbox(String, v_1001985); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001976, v_1001981]}}, False{}, v_1001984 => template_body_cps_provider_2_join_text([v_1001976, v_1001981]), v_1001983 => +v_1001982 = template_unbox(String, v_1001983); TemplateFinished{TemplateValue{v_1001982}}}}}

def template_body_cps_provider_2_move_copy_fields(+v_1: String, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_1_Layout>, +v_10: String) -> TemplateProgress<String>:
  match v_8:
    case []:
      TemplateFinished{TemplateValue{""}}
    case +v_1004496 <> v_1004497:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy{v_1, v_3, v_5, v_1004496, v_10}}, False{}, v_1004498 => template_body_cps_provider_2_move_copy(v_1, v_3, v_5, v_1004496, v_10), v_1004499 => +v_1004500 = template_unbox(String, v_1004499); template_continuation_513(v_1, v_3, v_5, v_1004496, v_1004497, v_10, v_1004500)}

def template_continuation_515(+v_10: String, +v_1: String, +v_3: Nat, +v_5: Nat, v_18: List<&2, cps_provider_1_LayArm>, +v_12: Nat, v_1001993: String, v_1001994: String, v_1001995: String, v_1001996: String, +v_1002002: String) -> TemplateProgress<String>:
  v_1002003 = {v_10 : String}
  v_1002004 = {"} break;\n" : String}
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy_cases{v_1, v_3, v_5, v_18, v_10, Nat.add(v_12, 1n)}}, v_1002009 => +v_1002005 = template_unbox(String, v_1002009); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1001993, v_1001994, v_1001995, v_1001996, v_1002002, v_1002003, v_1002004, v_1002005]}}, False{}, v_1002008 => template_body_cps_provider_2_join_text([v_1001993, v_1001994, v_1001995, v_1001996, v_1002002, v_1002003, v_1002004, v_1002005]), v_1002007 => +v_1002006 = template_unbox(String, v_1002007); TemplateFinished{TemplateValue{v_1002006}}}}

def template_match_516(+v_17: cps_provider_1_LayArm, +v_10: String, +v_12: Nat, +v_1: String, +v_3: Nat, +v_5: Nat, v_18: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<String>:
  match v_17:
    case cps_provider_1_LayArm{v_21, v_22}:
      v_1001995 = {Nat.show(v_12) : String}
      +v_1001997 = {v_1 : String}
      +v_1001998 = {v_3 : Nat}
      +v_1001999 = {v_5 : Nat}
      +v_1002000 = {v_22 : List<&2, cps_provider_1_Layout>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_10, "  "]}}, False{}, v_1002013 => template_body_cps_provider_2_join_text([v_10, "  "]), v_1002012 => +v_1002001 = template_unbox(String, v_1002012); TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy_fields{v_1001997, v_1001998, v_1001999, v_1002000, v_1002001}}, False{}, v_1002011 => template_body_cps_provider_2_move_copy_fields(v_1001997, v_1001998, v_1001999, v_1002000, v_1002001), v_1002010 => +v_1002002 = template_unbox(String, v_1002010); template_continuation_515(v_10, v_1, v_3, v_5, v_18, v_12, {v_10 : String}, {"case " : String}, v_1001995, {": {\n" : String}, v_1002002)}}

def template_body_cps_provider_2_move_copy_cases(+v_1: String, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_1_LayArm>, +v_10: String, +v_12: Nat) -> TemplateProgress<String>:
  match v_8:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_10, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"]}}, False{}, v_1004501 => template_body_cps_provider_2_join_text([v_10, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"]), v_1004502 => +v_1004503 = template_unbox(String, v_1004502); TemplateFinished{TemplateValue{v_1004503}}}
    case +v_1004504 <> v_1004505:
      template_match_516(v_1004504, v_10, v_12, v_1, v_3, v_5, v_1004505)

def template_match_518(+v_5: cps_provider_1_CWord, v_9: String) -> TemplateProgress<String>:
  match v_5:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u64)(u32)(", v_9, "))"]}}, False{}, v_1002017 => template_body_cps_provider_2_join_text(["((u64)(u32)(", v_9, "))"]), v_1002016 => +v_1002015 = template_unbox(String, v_1002016); TemplateFinished{TemplateValue{v_1002015}}}
    case _:
      TemplateFinished{TemplateValue{v_9}}

def template_continuation_519(+v_1002014: String, +v_5: cps_provider_1_CWord) -> TemplateProgress<String>:
  template_match_518(v_5, v_1002014)

def template_body_cps_provider_2_raw_word_expr(+v_1: String, +v_3: Nat, +v_5: cps_provider_1_CWord) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["e.mem[", v_1, " + ", Nat.show(v_3), "]"]}}, False{}, v_1002019 => template_body_cps_provider_2_join_text(["e.mem[", v_1, " + ", Nat.show(v_3), "]"]), v_1002018 => +v_1002014 = template_unbox(String, v_1002018); template_continuation_519(v_1002014, v_5)}

def template_match_520(v_20: cps_provider_2_Part) -> TemplateProgress<cps_provider_2_Part>:
  match v_20:
    case cps_provider_2_PartFail{v_22}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_22}}}
    case cps_provider_2_PartOk{v_24}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["{ Term pbl = 0; ", v_24, "; pbr = pbl; }\n"]}}, False{}, v_1002027 => template_body_cps_provider_2_join_text(["{ Term pbl = 0; ", v_24, "; pbr = pbl; }\n"]), v_1002026 => +v_1002025 = template_unbox(String, v_1002026); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002025}}}}

def template_continuation_521(+v_1002024: cps_provider_2_Part) -> TemplateProgress<cps_provider_2_Part>:
  template_match_520(v_1002024)

def template_continuation_522(+v_1002022: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_16 = v_1002022
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_16, v_1, []}}, False{}, v_1002031 => template_body_cps_provider_2_run_jobs(v_16, v_1, []), v_1002030 => +v_1002023 = template_unbox(cps_provider_2_Code, v_1002030); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002023, "pbl"}}, False{}, v_1002029 => template_body_cps_provider_2_part_of(v_1002023, "pbl"), v_1002028 => +v_1002024 = template_unbox(cps_provider_2_Part, v_1002028); template_continuation_521(v_1002024)}}

def template_match_523(+v_13: cps_provider_1_CWord, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_13:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcOne{v_5}, "pbl", "pblc"}}, False{}, v_1002033 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcOne{v_5}, "pbl", "pblc"), v_1002032 => +v_1002022 = template_unbox(List<&2, cps_provider_2_Job>, v_1002032); template_continuation_522(v_1002022, v_1)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"an inline form with a boxed or wider field has no nonallocating canonical Term read; use a typed consumer"}}}

def template_match_524(v_9: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_9:
    case []:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_zero_value_body{v_1, v_3}}, v_1002021 => +v_1002020 = template_unbox(cps_provider_2_Part, v_1002021); TemplateFinished{TemplateValue{v_1002020}}}
    case [+v_13]:
      template_match_523(v_13, v_1, v_3, v_5)
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a multiword inline form has no nonallocating canonical Term read; use a typed consumer"}}}

def template_body_cps_provider_2_packed_form_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_1_LayoutData{v_1004506, v_1004507}:
      template_match_524(v_1004506, v_1, v_3, v_5)
    case v_1004508:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a packed form read needs a data layout"}}}

def template_match_526(v_18: cps_provider_1_CWord) -> TemplateProgress<cps_provider_2_Part>:
  match v_18:
    case cps_provider_1_CWord32{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"pbr = ((u64)(u32)pbn);\n"}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"pbr = pbn;\n"}}}

def template_match_527(+v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_1_LayoutWord{v_18}:
      template_match_526(v_18)
    case cps_provider_1_LayoutData{v_23, v_24}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_packed_data_value{v_1, v_12}}, v_1002035 => +v_1002034 = template_unbox(cps_provider_2_Part, v_1002035); TemplateFinished{TemplateValue{v_1002034}}}
    case cps_provider_1_LayoutBox{v_27}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a packed value has no boxed field"}}}

def template_match_528(v_37: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_World, v_12: cps_provider_1_Layout, v_13: String, v_11: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_37:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_packed_form_body{v_1, v_12, "0"}}, False{}, v_1002048 => template_body_cps_provider_2_packed_form_body(v_1, v_12, "0"), v_1002047 => +v_1002046 = template_unbox(cps_provider_2_Part, v_1002047); TemplateFinished{TemplateValue{v_1002046}}}
    case +v_42 <> v_43:
      +v_1002050 = {v_12 : cps_provider_1_Layout}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_raw_word_expr{v_13, v_11, v_42}}, False{}, v_1002054 => template_body_cps_provider_2_raw_word_expr(v_13, v_11, v_42), v_1002053 => +v_1002051 = template_unbox(String, v_1002053); template_body_cps_provider_2_packed_form_body({v_1 : cps_provider_2_World}, v_1002050, v_1002051)}

def template_match_529(+v_12: cps_provider_1_Layout, v_13: String, v_11: Nat, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_1_LayoutWord{v_29}:
      v_1002036 = {"pbr = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_raw_word_expr{v_13, v_11, v_29}}, False{}, v_1002042 => template_body_cps_provider_2_raw_word_expr(v_13, v_11, v_29), v_1002041 => +v_1002037 = template_unbox(String, v_1002041); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002036, v_1002037, ";\n"]}}, False{}, v_1002040 => template_body_cps_provider_2_join_text([v_1002036, v_1002037, ";\n"]), v_1002039 => +v_1002038 = template_unbox(String, v_1002039); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002038}}}}}
    case cps_provider_1_LayoutBox{v_33}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = e.mem[", v_13, " + ", Nat.show(v_11), "];\n"]}}, False{}, v_1002045 => template_body_cps_provider_2_join_text(["pbr = e.mem[", v_13, " + ", Nat.show(v_11), "];\n"]), v_1002044 => +v_1002043 = template_unbox(String, v_1002044); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002043}}}}
    case cps_provider_1_LayoutData{v_37, v_38}:
      template_match_528(v_37, v_1, v_12, v_13, v_11)

def template_match_530(v_16: Bool, v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World, v_13: String, v_11: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_16:
    case True{}:
      template_match_527(v_12, v_1)
    case False{}:
      template_match_529(v_12, v_13, v_11, v_1)

def template_match_531(v_84: cps_provider_1_CWord, v_75: String, v_74: String, v_76: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_84:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = ((u64)(u32)(blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "))));\n"]}}, False{}, v_1002060 => template_body_cps_provider_2_join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "))));\n"]), v_1002059 => +v_1002058 = template_unbox(String, v_1002059); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002058}}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = (u64)(blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, ")));\n"]}}, False{}, v_1002063 => template_body_cps_provider_2_join_text(["pbr = (u64)(blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, ")));\n"]), v_1002062 => +v_1002061 = template_unbox(String, v_1002062); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002061}}}}

def template_match_532(v_80: Bool, v_75: String, v_74: String, v_76: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_80:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a BUF array cell cannot contain a boxed field"}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "));\n"]}}, False{}, v_1002066 => template_body_cps_provider_2_join_text(["pbr = blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "));\n"]), v_1002065 => +v_1002064 = template_unbox(String, v_1002065); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002064}}}}

def template_match_533(+v_78: cps_provider_1_Layout, v_75: String, v_74: String, v_76: String, v_80: Bool, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_78:
    case cps_provider_1_LayoutWord{v_84}:
      template_match_531(v_84, v_75, v_74, v_76)
    case cps_provider_1_LayoutBox{v_90}:
      template_match_532(v_80, v_75, v_74, v_76)
    case cps_provider_1_LayoutData{v_94, v_95}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "))"]}}, False{}, v_1002072 => template_body_cps_provider_2_join_text(["blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "))"]), v_1002071 => +v_1002069 = template_unbox(String, v_1002071); template_body_cps_provider_2_packed_form_body({v_1 : cps_provider_2_World}, {v_78 : cps_provider_1_Layout}, v_1002069)}

def template_match_534(v_109: cps_provider_1_CWord, v_103: String, v_104: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_109:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = ((u64)(u32)blk_read(e.mem, false, ", v_103, ", (u32)(", v_104, ")));\n"]}}, False{}, v_1002075 => template_body_cps_provider_2_join_text(["pbr = ((u64)(u32)blk_read(e.mem, false, ", v_103, ", (u32)(", v_104, ")));\n"]), v_1002074 => +v_1002073 = template_unbox(String, v_1002074); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002073}}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a BUF raw field is not one w32 cell"}}}

def template_match_535(+v_105: cps_provider_1_Layout, v_103: String, v_104: String, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_105:
    case cps_provider_1_LayoutWord{v_109}:
      template_match_534(v_109, v_103, v_104)
    case cps_provider_1_LayoutData{v_115, v_116}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["blk_read(e.mem, false, ", v_103, ", (u32)(", v_104, "))"]}}, False{}, v_1002081 => template_body_cps_provider_2_join_text(["blk_read(e.mem, false, ", v_103, ", (u32)(", v_104, "))"]), v_1002080 => +v_1002078 = template_unbox(String, v_1002080); template_body_cps_provider_2_packed_form_body({v_1 : cps_provider_2_World}, {v_105 : cps_provider_1_Layout}, v_1002078)}
    case cps_provider_1_LayoutBox{v_120}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a BUF inline form cannot hold a box"}}}

def template_body_cps_provider_2_read_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StSlot{v_1004509, v_1004510, v_1004511, v_1004512, v_1004513, v_1004514}:
      template_match_530(v_1004514, v_1004510, v_1, v_1004511, v_1004509)
    case cps_provider_2_StArray{+v_1004515, +v_1004516, v_1004517, v_1004518, v_1004519, +v_1004520, v_1004521, v_1004522, v_1004523}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["if (", v_1004519, ") { pbr = term_blk(true, (u32)(", v_1004516, "), (u64)((u64)(", v_1004515, ") + (u64)(", v_1004520, "))); } else { u64 pboff = (u64)(", v_1004520, "); if ((pboff & 1ull) != 0ull) { (void)err_fail(\"a mid-block BUF cell has no Term view; a consumer must read it through blk_read\"); } pbr = term_blk(false, (u32)(", v_1004516, "), (u64)((u64)(", v_1004515, ") + (pboff >> 1))); }\n"]}}, False{}, v_1004524 => template_body_cps_provider_2_join_text(["if (", v_1004519, ") { pbr = term_blk(true, (u32)(", v_1004516, "), (u64)((u64)(", v_1004515, ") + (u64)(", v_1004520, "))); } else { u64 pboff = (u64)(", v_1004520, "); if ((pboff & 1ull) != 0ull) { (void)err_fail(\"a mid-block BUF cell has no Term view; a consumer must read it through blk_read\"); } pbr = term_blk(false, (u32)(", v_1004516, "), (u64)((u64)(", v_1004515, ") + (pboff >> 1))); }\n"]), v_1004525 => +v_1004526 = template_unbox(String, v_1004525); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1004526}}}}
    case cps_provider_2_StCell{v_1004527, v_1004528, v_1004529, v_1004530, v_1004531, v_1004532, v_1004533, v_1004534, v_1004535}:
      template_match_533(v_1004531, v_1004528, v_1004527, v_1004529, v_1004533, v_1)
    case cps_provider_2_StBufField{v_1004536, v_1004537, v_1004538, v_1004539, v_1004540}:
      template_match_535(v_1004538, v_1004536, v_1004537, v_1)

def template_match_537(+v_6: Maybe<&2, U32>, +v_8: String, v_13: U32) -> TemplateProgress<cps_provider_2_Part>:
  match v_6:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_8, " = ", U32.show(v_13), "u;\n"]}}, False{}, v_1002088 => template_body_cps_provider_2_join_text([v_8, " = ", U32.show(v_13), "u;\n"]), v_1002087 => +v_1002086 = template_unbox(String, v_1002087); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002086}}}}
    case Some{v_16}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_8, " = (", U32.show(v_13), "u == ", U32.show(v_16), "u);\n"]}}, False{}, v_1002091 => template_body_cps_provider_2_join_text([v_8, " = (", U32.show(v_13), "u == ", U32.show(v_16), "u);\n"]), v_1002090 => +v_1002089 = template_unbox(String, v_1002090); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002089}}}}

def template_match_538(+v_1002082: Maybe<&2, U32>, +v_3: String, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002082:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the arm `", v_3, "` has no canonical CID"]}}, False{}, v_1002085 => template_body_cps_provider_2_join_text(["the arm `", v_3, "` has no canonical CID"]), v_1002084 => +v_1002083 = template_unbox(String, v_1002084); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1002083}}}}
    case Some{v_13}:
      template_match_537(v_6, v_8, v_13)

def template_body_cps_provider_2_tag_single(+v_1: cps_provider_2_World, +v_3: String, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_3, v_1}}, False{}, v_1002093 => template_body_cps_provider_2_cid_of(v_3, v_1), v_1002092 => +v_1002082 = template_unbox(Maybe<&2, U32>, v_1002092); template_match_538(v_1002082, v_3, v_6, v_8)}

def template_match_539(+v_1002097: Maybe<&2, U32>, v_26: String, +v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, v_23: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002097:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the arm `", v_26, "` has no canonical CID"]}}, False{}, v_1002100 => template_body_cps_provider_2_join_text(["the arm `", v_26, "` has no canonical CID"]), v_1002099 => +v_1002098 = template_unbox(String, v_1002099); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1002098}}}}
    case Some{v_31}:
      +v_1002106 = {Nat.add(v_13, 1n) : Nat}
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_case_line{v_15, v_13, v_31, v_11, v_17}}, v_1002110 => +v_1002107 = template_unbox(String, v_1002110); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_multi{{v_1 : cps_provider_2_World}, {v_3 : String}, {v_5 : Nat}, {v_23 : List<&2, cps_provider_1_LayArm>}, {v_11 : Maybe<&2, U32>}, v_1002106, v_1002107, v_17}}, v_1002109 => +v_1002108 = template_unbox(cps_provider_2_Part, v_1002109); TemplateFinished{TemplateValue{v_1002108}}}}

def template_match_540(+v_22: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, v_23: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_22:
    case cps_provider_1_LayArm{+v_26, v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_26, v_1}}, False{}, v_1002112 => template_body_cps_provider_2_cid_of(v_26, v_1), v_1002111 => +v_1002097 = template_unbox(Maybe<&2, U32>, v_1002111); template_match_539(v_1002097, v_26, v_1, v_3, v_5, v_23, v_11, v_13, v_15, v_17)}

def template_body_cps_provider_2_tag_multi(+v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_8:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["switch ((u32)e.mem[", v_3, " + ", Nat.show(v_5), "]) {\n", v_15, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"]}}, False{}, v_1004541 => template_body_cps_provider_2_join_text(["switch ((u32)e.mem[", v_3, " + ", Nat.show(v_5), "]) {\n", v_15, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"]), v_1004542 => +v_1004543 = template_unbox(String, v_1004542); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1004543}}}}
    case +v_1004544 <> v_1004545:
      template_match_540(v_1004544, v_1, v_3, v_5, v_1004545, v_11, v_13, v_15, v_17)

def template_body_cps_provider_2_tag_case_line(+v_1: String, +v_3: Nat, +v_5: U32, +v_8: Maybe<&2, U32>, +v_10: String) -> TemplateProgress<String>:
  match v_8:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1, "case ", Nat.show(v_3), ": ", v_10, " = ", U32.show(v_5), "u; break;\n"]}}, False{}, v_1004546 => template_body_cps_provider_2_join_text([v_1, "case ", Nat.show(v_3), ": ", v_10, " = ", U32.show(v_5), "u; break;\n"]), v_1004547 => +v_1004548 = template_unbox(String, v_1004547); TemplateFinished{TemplateValue{v_1004548}}}
    case Some{v_1004549}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1, "case ", Nat.show(v_3), ": ", v_10, " = (", U32.show(v_5), "u == ", U32.show(v_1004549), "u); break;\n"]}}, False{}, v_1004550 => template_body_cps_provider_2_join_text([v_1, "case ", Nat.show(v_3), ": ", v_10, " = (", U32.show(v_5), "u == ", U32.show(v_1004549), "u); break;\n"]), v_1004551 => +v_1004552 = template_unbox(String, v_1004551); TemplateFinished{TemplateValue{v_1004552}}}

def template_body_cps_provider_2_tag_multi_packed(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_LayArm>, +v_7: Maybe<&2, U32>, +v_9: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_multi_packed_go{v_1, v_4, v_7, 0n, "", v_9}}, v_1002120 => +v_1002119 = template_unbox(cps_provider_2_Part, v_1002120); TemplateFinished{TemplateValue{v_1002119}}}

def template_match_543(+v_1002124: Maybe<&2, U32>, v_22: String, +v_1: cps_provider_2_World, v_19: List<&2, cps_provider_1_LayArm>, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002124:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the arm `", v_22, "` has no canonical CID"]}}, False{}, v_1002127 => template_body_cps_provider_2_join_text(["the arm `", v_22, "` has no canonical CID"]), v_1002126 => +v_1002125 = template_unbox(String, v_1002126); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1002125}}}}
    case Some{v_27}:
      +v_1002131 = {Nat.add(v_9, 1n) : Nat}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_case_line{v_11, v_9, v_27, v_7, v_13}}, False{}, v_1002136 => template_body_cps_provider_2_tag_case_line(v_11, v_9, v_27, v_7, v_13), v_1002135 => +v_1002132 = template_unbox(String, v_1002135); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_multi_packed_go{{v_1 : cps_provider_2_World}, {v_19 : List<&2, cps_provider_1_LayArm>}, {v_7 : Maybe<&2, U32>}, v_1002131, v_1002132, v_13}}, v_1002134 => +v_1002133 = template_unbox(cps_provider_2_Part, v_1002134); TemplateFinished{TemplateValue{v_1002133}}}}

def template_match_544(+v_18: cps_provider_1_LayArm, +v_1: cps_provider_2_World, v_19: List<&2, cps_provider_1_LayArm>, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_18:
    case cps_provider_1_LayArm{+v_22, v_23}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_22, v_1}}, False{}, v_1002138 => template_body_cps_provider_2_cid_of(v_22, v_1), v_1002137 => +v_1002124 = template_unbox(Maybe<&2, U32>, v_1002137); template_match_543(v_1002124, v_22, v_1, v_19, v_7, v_9, v_11, v_13)}

def template_body_cps_provider_2_tag_multi_packed_go(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_LayArm>, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_4:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["switch ((u32)pbn) {\n", v_11, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"]}}, False{}, v_1004553 => template_body_cps_provider_2_join_text(["switch ((u32)pbn) {\n", v_11, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"]), v_1004554 => +v_1004555 = template_unbox(String, v_1004554); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1004555}}}}
    case +v_1004556 <> v_1004557:
      template_match_544(v_1004556, v_1, v_1004557, v_7, v_9, v_11, v_13)

def template_body_cps_provider_2_tag_multi_buf(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_multi_buf_go{v_1, v_3, v_5, v_8, v_11, 0n, "", v_13}}, v_1002140 => +v_1002139 = template_unbox(cps_provider_2_Part, v_1002140); TemplateFinished{TemplateValue{v_1002139}}}

def template_match_546(+v_1002144: Maybe<&2, U32>, v_26: String, +v_1: cps_provider_2_World, +v_3: String, +v_5: String, v_23: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002144:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the arm `", v_26, "` has no canonical CID"]}}, False{}, v_1002147 => template_body_cps_provider_2_join_text(["the arm `", v_26, "` has no canonical CID"]), v_1002146 => +v_1002145 = template_unbox(String, v_1002146); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1002145}}}}
    case Some{v_31}:
      +v_1002153 = {Nat.add(v_13, 1n) : Nat}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_case_line{v_15, v_13, v_31, v_11, v_17}}, False{}, v_1002158 => template_body_cps_provider_2_tag_case_line(v_15, v_13, v_31, v_11, v_17), v_1002157 => +v_1002154 = template_unbox(String, v_1002157); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_multi_buf_go{{v_1 : cps_provider_2_World}, {v_3 : String}, {v_5 : String}, {v_23 : List<&2, cps_provider_1_LayArm>}, {v_11 : Maybe<&2, U32>}, v_1002153, v_1002154, v_17}}, v_1002156 => +v_1002155 = template_unbox(cps_provider_2_Part, v_1002156); TemplateFinished{TemplateValue{v_1002155}}}}

def template_match_547(+v_22: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_3: String, +v_5: String, v_23: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_22:
    case cps_provider_1_LayArm{+v_26, v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_26, v_1}}, False{}, v_1002160 => template_body_cps_provider_2_cid_of(v_26, v_1), v_1002159 => +v_1002144 = template_unbox(Maybe<&2, U32>, v_1002159); template_match_546(v_1002144, v_26, v_1, v_3, v_5, v_23, v_11, v_13, v_15, v_17)}

def template_body_cps_provider_2_tag_multi_buf_go(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_8:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["switch ((u32)blk_read(e.mem, false, ", v_3, ", (u32)(", v_5, "))) {\n", v_15, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"]}}, False{}, v_1004558 => template_body_cps_provider_2_join_text(["switch ((u32)blk_read(e.mem, false, ", v_3, ", (u32)(", v_5, "))) {\n", v_15, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"]), v_1004559 => +v_1004560 = template_unbox(String, v_1004559); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1004560}}}}
    case +v_1004561 <> v_1004562:
      template_match_547(v_1004561, v_1, v_3, v_5, v_1004562, v_11, v_13, v_15, v_17)

def template_match_549(+v_27: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_27:
    case cps_provider_1_LayArm{v_30, v_31}:
      template_body_cps_provider_2_tag_single(v_1, v_30, v_6, v_8)

def template_match_550(+v_25: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_25:
    case [+v_27]:
      template_match_549(v_27, v_1, v_6, v_8)
    case _:
      template_body_cps_provider_2_tag_multi_packed(v_1, v_25, v_6, v_8)

def template_match_551(v_17: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_17:
    case cps_provider_1_LayoutData{v_24, v_25}:
      template_match_550(v_25, v_1, v_6, v_8)
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a packed word is not a constructor tag"}}}

def template_match_552(+v_43: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_43:
    case cps_provider_1_LayArm{v_46, v_47}:
      template_body_cps_provider_2_tag_single(v_1, v_46, v_6, v_8)

def template_match_553(+v_41: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_18: String, v_16: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_41:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a data layout has no arms"}}}
    case [+v_43]:
      template_match_552(v_43, v_1, v_6, v_8)
    case _:
      template_body_cps_provider_2_tag_multi(v_1, v_18, v_16, v_41, v_6, 0n, "", v_8)

def template_match_554(+v_6: Maybe<&2, U32>, +v_8: String, v_56: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_6:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_8, " = term_aux(", v_56, ");\n"]}}, False{}, v_1002168 => template_body_cps_provider_2_join_text([v_8, " = term_aux(", v_56, ");\n"]), v_1002167 => +v_1002166 = template_unbox(String, v_1002167); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002166}}}}
    case Some{v_59}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_8, " = (term_aux(", v_56, ") == ", U32.show(v_59), "u);\n"]}}, False{}, v_1002171 => template_body_cps_provider_2_join_text([v_8, " = (term_aux(", v_56, ") == ", U32.show(v_59), "u);\n"]), v_1002170 => +v_1002169 = template_unbox(String, v_1002170); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002169}}}}

def template_continuation_555(+v_1002165: String, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  template_match_554(v_6, v_8, v_1002165)

def template_match_556(v_17: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_18: String, v_16: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_17:
    case cps_provider_1_LayoutData{v_40, v_41}:
      template_match_553(v_41, v_1, v_6, v_8, v_18, v_16)
    case cps_provider_1_LayoutBox{v_53}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["e.mem[", v_18, " + ", Nat.show(v_16), "]"]}}, False{}, v_1002173 => template_body_cps_provider_2_join_text(["e.mem[", v_18, " + ", Nat.show(v_16), "]"]), v_1002172 => +v_1002165 = template_unbox(String, v_1002172); template_continuation_555(v_1002165, v_6, v_8)}
    case cps_provider_1_LayoutWord{v_62}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a tag test needs a data field"}}}

def template_match_557(v_21: Bool, v_17: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_18: String, v_16: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_21:
    case True{}:
      template_match_551(v_17, v_1, v_6, v_8)
    case False{}:
      template_match_556(v_17, v_1, v_6, v_8, v_18, v_16)

def template_match_558(+v_86: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_86:
    case cps_provider_1_LayArm{v_89, v_90}:
      template_body_cps_provider_2_tag_single(v_1, v_89, v_6, v_8)

def template_match_559(v_78: Bool, +v_1: cps_provider_2_World, v_72: String, v_74: String, v_84: List<&2, cps_provider_1_LayArm>, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_78:
    case True{}:
      template_body_cps_provider_2_tag_multi_buf(v_1, v_72, v_74, v_84, v_6, v_8)
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_72, " + (", v_74, ")"]}}, False{}, v_1002180 => template_body_cps_provider_2_join_text([v_72, " + (", v_74, ")"]), v_1002179 => +v_1002177 = template_unbox(String, v_1002179); template_body_cps_provider_2_tag_multi({v_1 : cps_provider_2_World}, v_1002177, 0n, v_84, v_6, 0n, "", v_8)}

def template_match_560(+v_84: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_78: Bool, v_72: String, v_74: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_84:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a data layout has no arms"}}}
    case [+v_86]:
      template_match_558(v_86, v_1, v_6, v_8)
    case _:
      template_match_559(v_78, v_1, v_72, v_74, v_84, v_6, v_8)

def template_match_561(+v_6: Maybe<&2, U32>, +v_8: String, v_101: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_6:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_8, " = term_aux(", v_101, ");\n"]}}, False{}, v_1002184 => template_body_cps_provider_2_join_text([v_8, " = term_aux(", v_101, ");\n"]), v_1002183 => +v_1002182 = template_unbox(String, v_1002183); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002182}}}}
    case Some{v_104}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_8, " = (term_aux(", v_101, ") == ", U32.show(v_104), "u);\n"]}}, False{}, v_1002187 => template_body_cps_provider_2_join_text([v_8, " = (term_aux(", v_101, ") == ", U32.show(v_104), "u);\n"]), v_1002186 => +v_1002185 = template_unbox(String, v_1002186); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002185}}}}

def template_continuation_562(+v_1002181: String, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  template_match_561(v_6, v_8, v_1002181)

def template_match_563(v_76: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_78: Bool, v_72: String, v_74: String, v_73: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_76:
    case cps_provider_1_LayoutData{v_83, v_84}:
      template_match_560(v_84, v_1, v_6, v_8, v_78, v_72, v_74)
    case cps_provider_1_LayoutBox{v_98}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["blk_read(e.mem, ", v_73, ", ", v_72, ", (u32)(", v_74, "))"]}}, False{}, v_1002189 => template_body_cps_provider_2_join_text(["blk_read(e.mem, ", v_73, ", ", v_72, ", (u32)(", v_74, "))"]), v_1002188 => +v_1002181 = template_unbox(String, v_1002188); template_continuation_562(v_1002181, v_6, v_8)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a tag test needs a data field"}}}

def template_match_564(+v_123: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_123:
    case cps_provider_1_LayArm{v_126, v_127}:
      template_body_cps_provider_2_tag_single(v_1, v_126, v_6, v_8)

def template_match_565(+v_121: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_113: String, v_114: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_121:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a data layout has no arms"}}}
    case [+v_123]:
      template_match_564(v_123, v_1, v_6, v_8)
    case _:
      template_body_cps_provider_2_tag_multi_buf(v_1, v_113, v_114, v_121, v_6, v_8)

def template_match_566(v_115: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_113: String, v_114: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_115:
    case cps_provider_1_LayoutData{v_120, v_121}:
      template_match_565(v_121, v_1, v_6, v_8, v_113, v_114)
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a tag test needs a data field"}}}

def template_body_cps_provider_2_tag_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_6: Maybe<&2, U32>, +v_8: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StSlot{v_1004563, v_1004564, v_1004565, v_1004566, v_1004567, v_1004568}:
      template_match_557(v_1004568, v_1004564, v_1, v_6, v_8, v_1004565, v_1004563)
    case cps_provider_2_StCell{v_1004569, v_1004570, v_1004571, v_1004572, v_1004573, v_1004574, v_1004575, v_1004576, v_1004577}:
      template_match_563(v_1004573, v_1, v_6, v_8, v_1004575, v_1004569, v_1004571, v_1004570)
    case cps_provider_2_StBufField{v_1004578, v_1004579, v_1004580, v_1004581, v_1004582}:
      template_match_566(v_1004580, v_1, v_6, v_8, v_1004578, v_1004579)
    case cps_provider_2_StArray{v_1004583, v_1004584, v_1004585, v_1004586, v_1004587, v_1004588, v_1004589, v_1004590, v_1004591}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a tag test needs a data field"}}}

def template_match_568(v_18: cps_provider_1_CWord) -> TemplateProgress<cps_provider_2_Part>:
  match v_18:
    case cps_provider_1_CWord32{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"pbr = ((u64)(u32)pbn);\n"}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"pbr = pbn;\n"}}}

def template_match_569(+v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_1_LayoutWord{v_18}:
      template_match_568(v_18)
    case cps_provider_1_LayoutData{v_23, v_24}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_packed_data_copy{v_1, v_12}}, v_1002193 => +v_1002192 = template_unbox(cps_provider_2_Part, v_1002193); TemplateFinished{TemplateValue{v_1002192}}}
    case cps_provider_1_LayoutBox{v_27}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a packed value has no boxed field"}}}

def template_match_570(+v_12: cps_provider_1_Layout, v_13: String, v_11: Nat, v_14: String, v_15: String, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_1_LayoutWord{v_29}:
      v_1002194 = {"pbr = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_raw_word_expr{v_13, v_11, v_29}}, False{}, v_1002200 => template_body_cps_provider_2_raw_word_expr(v_13, v_11, v_29), v_1002199 => +v_1002195 = template_unbox(String, v_1002199); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002194, v_1002195, ";\n"]}}, False{}, v_1002198 => template_body_cps_provider_2_join_text([v_1002194, v_1002195, ";\n"]), v_1002197 => +v_1002196 = template_unbox(String, v_1002197); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002196}}}}}
    case cps_provider_1_LayoutBox{v_33}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_box_copy_body{v_13, v_11, v_14, v_15}}, v_1002202 => +v_1002201 = template_unbox(cps_provider_2_Part, v_1002202); TemplateFinished{TemplateValue{v_1002201}}}
    case cps_provider_1_LayoutData{v_37, v_38}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_data_copy_body{v_1, v_12, v_13, v_11, v_14, v_15}}, v_1002204 => +v_1002203 = template_unbox(cps_provider_2_Part, v_1002204); TemplateFinished{TemplateValue{v_1002203}}}

def template_match_571(v_16: Bool, v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World, v_13: String, v_11: Nat, v_14: String, v_15: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_16:
    case True{}:
      template_match_569(v_12, v_1)
    case False{}:
      template_match_570(v_12, v_13, v_11, v_14, v_15, v_1)

def template_body_cps_provider_2_copy_slot_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StSlot{v_1004592, v_1004593, v_1004594, v_1004595, v_1004596, v_1004597}:
      template_match_571(v_1004597, v_1004593, v_1, v_1004594, v_1004592, v_1004595, v_1004596)
    case v_1004598:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"not a field slot"}}}

def template_match_573(v_11: cps_provider_2_Part) -> TemplateProgress<cps_provider_2_Part>:
  match v_11:
    case cps_provider_2_PartFail{v_13}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_13}}}
    case cps_provider_2_PartOk{v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["{ Term pbl = 0; ", v_15, "; pbr = pbl; }\n"]}}, False{}, v_1002210 => template_body_cps_provider_2_join_text(["{ Term pbl = 0; ", v_15, "; pbr = pbl; }\n"]), v_1002209 => +v_1002208 = template_unbox(String, v_1002209); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002208}}}}

def template_continuation_574(+v_1002207: cps_provider_2_Part) -> TemplateProgress<cps_provider_2_Part>:
  template_match_573(v_1002207)

def template_continuation_575(+v_1002205: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_7 = v_1002205
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_7, v_1, []}}, False{}, v_1002214 => template_body_cps_provider_2_run_jobs(v_7, v_1, []), v_1002213 => +v_1002206 = template_unbox(cps_provider_2_Code, v_1002213); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002206, "pbl"}}, False{}, v_1002212 => template_body_cps_provider_2_part_of(v_1002206, "pbl"), v_1002211 => +v_1002207 = template_unbox(cps_provider_2_Part, v_1002211); template_continuation_574(v_1002207)}}

def template_body_cps_provider_2_packed_data_value(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcOne{"((u64)pbn)"}, "pbl", "pblc"}}, False{}, v_1002216 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcOne{"((u64)pbn)"}, "pbl", "pblc"), v_1002215 => +v_1002205 = template_unbox(List<&2, cps_provider_2_Job>, v_1002215); template_continuation_575(v_1002205, v_1)}

def template_match_576(v_11: cps_provider_2_Part) -> TemplateProgress<cps_provider_2_Part>:
  match v_11:
    case cps_provider_2_PartFail{v_13}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_13}}}
    case cps_provider_2_PartOk{v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["{ Term pbl = 0; ", v_15, "; pbr = pbl; }\n"]}}, False{}, v_1002222 => template_body_cps_provider_2_join_text(["{ Term pbl = 0; ", v_15, "; pbr = pbl; }\n"]), v_1002221 => +v_1002220 = template_unbox(String, v_1002221); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002220}}}}

def template_continuation_577(+v_1002219: cps_provider_2_Part) -> TemplateProgress<cps_provider_2_Part>:
  template_match_576(v_1002219)

def template_continuation_578(+v_1002217: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_7 = v_1002217
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_7, v_1, []}}, False{}, v_1002226 => template_body_cps_provider_2_run_jobs(v_7, v_1, []), v_1002225 => +v_1002218 = template_unbox(cps_provider_2_Code, v_1002225); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002218, "pbl"}}, False{}, v_1002224 => template_body_cps_provider_2_part_of(v_1002218, "pbl"), v_1002223 => +v_1002219 = template_unbox(cps_provider_2_Part, v_1002223); template_continuation_577(v_1002219)}}

def template_body_cps_provider_2_packed_data_copy(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcOne{"((u64)pbn)"}, "pbl", "pblc"}}, False{}, v_1002228 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcOne{"((u64)pbn)"}, "pbl", "pblc"), v_1002227 => +v_1002217 = template_unbox(List<&2, cps_provider_2_Job>, v_1002227); template_continuation_578(v_1002217, v_1)}

def template_continuation_579(+v_1002229: String, +v_7: String, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["{ Term pbb = term_keep(e, ", v_1002229, ", 1); if (pbb != ", v_1002229, ") { if (", v_7, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_5, ") { (void)err_fail(\"a shared owner has an unsealed field\"); } else { ", v_1002229, " = pbb; } } pbr = pbb; }\n"]}}, False{}, v_1002232 => template_body_cps_provider_2_join_text(["{ Term pbb = term_keep(e, ", v_1002229, ", 1); if (pbb != ", v_1002229, ") { if (", v_7, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_5, ") { (void)err_fail(\"a shared owner has an unsealed field\"); } else { ", v_1002229, " = pbb; } } pbr = pbb; }\n"]), v_1002231 => +v_1002230 = template_unbox(String, v_1002231); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002230}}}}

def template_body_cps_provider_2_box_copy_body(+v_1: String, +v_3: Nat, +v_5: String, +v_7: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["e.mem[", v_1, " + ", Nat.show(v_3), "]"]}}, False{}, v_1002234 => template_body_cps_provider_2_join_text(["e.mem[", v_1, " + ", Nat.show(v_3), "]"]), v_1002233 => +v_1002229 = template_unbox(String, v_1002233); template_continuation_579(v_1002229, v_7, v_5)}

def template_match_580(v_25: cps_provider_2_Part, v_15: Nat, +v_5: String, +v_9: String, +v_11: String, +v_7: Nat, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  match v_25:
    case cps_provider_2_PartFail{v_27}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_27}}}
    case cps_provider_2_PartOk{v_29}:
      v_1002241 = {"{ Term pbbuf[" : String}
      v_1002242 = {Nat.show(v_15) : String}
      v_1002243 = {"]; " : String}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy{v_5, v_9, v_11, v_7, v_7, v_3, ""}}, False{}, v_1002249 => template_body_cps_provider_2_keep_copy(v_5, v_9, v_11, v_7, v_7, v_3, ""), v_1002248 => +v_1002244 = template_unbox(String, v_1002248); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002241, v_1002242, v_1002243, v_1002244, "u32 pbi = 0; Term pbl = 0; ", v_29, "; pbr = pbl; }\n"]}}, False{}, v_1002247 => template_body_cps_provider_2_join_text([v_1002241, v_1002242, v_1002243, v_1002244, "u32 pbi = 0; Term pbl = 0; ", v_29, "; pbr = pbl; }\n"]), v_1002246 => +v_1002245 = template_unbox(String, v_1002246); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002245}}}}}

def template_continuation_581(+v_1002240: cps_provider_2_Part, v_15: Nat, +v_5: String, +v_9: String, +v_11: String, +v_7: Nat, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  template_match_580(v_1002240, v_15, v_5, v_9, v_11, v_7, v_3)

def template_continuation_582(+v_1002238: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World, v_15: Nat, +v_5: String, +v_9: String, +v_11: String, +v_7: Nat, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  v_21 = v_1002238
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_21, v_1, []}}, False{}, v_1002253 => template_body_cps_provider_2_run_jobs(v_21, v_1, []), v_1002252 => +v_1002239 = template_unbox(cps_provider_2_Code, v_1002252); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002239, "pbl"}}, False{}, v_1002251 => template_body_cps_provider_2_part_of(v_1002239, "pbl"), v_1002250 => +v_1002240 = template_unbox(cps_provider_2_Part, v_1002250); template_continuation_581(v_1002240, v_15, v_5, v_9, v_11, v_7, v_3)}}

def template_match_583(+v_15: Nat, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_9: String, +v_11: String, +v_7: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_15:
    case 0n:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_zero_value_body{v_1, v_3}}, v_1002237 => +v_1002236 = template_unbox(cps_provider_2_Part, v_1002237); TemplateFinished{TemplateValue{v_1002236}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc"}}, False{}, v_1002255 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc"), v_1002254 => +v_1002238 = template_unbox(List<&2, cps_provider_2_Job>, v_1002254); template_continuation_582(v_1002238, v_1, v_15, v_5, v_9, v_11, v_7, v_3)}

def template_continuation_584(+v_1002235: Nat, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_9: String, +v_11: String, +v_7: Nat) -> TemplateProgress<cps_provider_2_Part>:
  template_match_583(v_1002235, v_1, v_3, v_5, v_9, v_11, v_7)

def template_body_cps_provider_2_data_copy_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat, +v_9: String, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_3}}, False{}, v_1002257 => template_body_cps_provider_1_layout_words(v_3), v_1002256 => +v_1002235 = template_unbox(Nat, v_1002256); template_continuation_584(v_1002235, v_1, v_3, v_5, v_9, v_11, v_7)}

def template_match_585(+v_1002258: Maybe<&2, U32>, v_13: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002258:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the arm `", v_13, "` has no canonical CID"]}}, False{}, v_1002261 => template_body_cps_provider_2_join_text(["the arm `", v_13, "` has no canonical CID"]), v_1002260 => +v_1002259 = template_unbox(String, v_1002260); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1002259}}}}
    case Some{v_18}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = term_pak(", U32.show(v_18), "u, 0);\n"]}}, False{}, v_1002264 => template_body_cps_provider_2_join_text(["pbr = term_pak(", U32.show(v_18), "u, 0);\n"]), v_1002263 => +v_1002262 = template_unbox(String, v_1002263); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002262}}}}

def template_match_586(+v_10: cps_provider_1_LayArm, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_10:
    case cps_provider_1_LayArm{+v_13, v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_13, v_1}}, False{}, v_1002266 => template_body_cps_provider_2_cid_of(v_13, v_1), v_1002265 => +v_1002258 = template_unbox(Maybe<&2, U32>, v_1002265); template_match_585(v_1002258, v_13)}

def template_match_587(v_8: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_8:
    case [+v_10]:
      template_match_586(v_10, v_1)
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a zero-word field must have exactly one constructor"}}}

def template_body_cps_provider_2_zero_value_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_1_LayoutData{v_1004599, v_1004600}:
      template_match_587(v_1004600, v_1)
    case v_1004601:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a zero-word field is not a data layout"}}}

def template_match_589(v_1002267: Bool, +v_9: String, +v_1: String, +v_3: String, +v_7: Nat, +v_5: Nat) -> TemplateProgress<String>:
  match v_1002267:
    case True{}:
      TemplateFinished{TemplateValue{""}}
    case False{}:
      v_1002268 = {v_9 : String}
      v_1002269 = {"blk_write(e.mem, false, " : String}
      v_1002270 = {v_1 : String}
      v_1002271 = {", (u32)((" : String}
      v_1002272 = {v_3 : String}
      v_1002273 = {") + " : String}
      v_1002274 = {Nat.show(v_7) : String}
      v_1002275 = {"u), 0);\n" : String}
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_buf_clear_words{v_1, v_3, v_5, Nat.add(v_7, 1n), v_9}}, v_1002280 => +v_1002276 = template_unbox(String, v_1002280); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002268, v_1002269, v_1002270, v_1002271, v_1002272, v_1002273, v_1002274, v_1002275, v_1002276]}}, False{}, v_1002279 => template_body_cps_provider_2_join_text([v_1002268, v_1002269, v_1002270, v_1002271, v_1002272, v_1002273, v_1002274, v_1002275, v_1002276]), v_1002278 => +v_1002277 = template_unbox(String, v_1002278); TemplateFinished{TemplateValue{v_1002277}}}}

def template_body_cps_provider_2_buf_clear_words(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String) -> TemplateProgress<String>:
  v_1002267 = {Nat.is_eq(v_7, v_5) : Bool}
  template_match_589(v_1002267, v_9, v_1, v_3, v_7, v_5)

def template_continuation_590(+v_1002282: String, v_15: String) -> TemplateProgress<cps_provider_2_Part>:
  v_18 = v_1002282
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = ", v_15, "; ", v_18, "\n"]}}, False{}, v_1002285 => template_body_cps_provider_2_join_text(["pbr = ", v_15, "; ", v_18, "\n"]), v_1002284 => +v_1002283 = template_unbox(String, v_1002284); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002283}}}}

def template_continuation_591(+v_1002281: String, +v_5: String, +v_7: String, +v_9: Bool) -> TemplateProgress<cps_provider_2_Part>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_buf_move_clear{v_5, v_7, 1n, v_9}}, v_1002286 => +v_1002282 = template_unbox(String, v_1002286); template_continuation_590(v_1002282, v_1002281)}

def template_match_592(v_12: cps_provider_1_CWord, +v_5: String, +v_7: String, +v_9: Bool) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u64)(u32)blk_read(e.mem, false, ", v_5, ", (u32)(", v_7, ")))"]}}, False{}, v_1002288 => template_body_cps_provider_2_join_text(["((u64)(u32)blk_read(e.mem, false, ", v_5, ", (u32)(", v_7, ")))"]), v_1002287 => +v_1002281 = template_unbox(String, v_1002287); template_continuation_591(v_1002281, v_5, v_7, v_9)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a BUF raw field is not one w32 cell"}}}

def template_continuation_593(+v_1002296: String, v_37: String) -> TemplateProgress<cps_provider_2_Part>:
  v_41 = v_1002296
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", v_37, "; ", v_41, " pbr = pbl;\n"]}}, False{}, v_1002299 => template_body_cps_provider_2_join_text(["Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", v_37, "; ", v_41, " pbr = pbl;\n"]), v_1002298 => +v_1002297 = template_unbox(String, v_1002298); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002297}}}}

def template_match_594(+v_1002292: cps_provider_2_Part, +v_5: String, +v_7: String, +v_3: cps_provider_1_Layout, +v_9: Bool) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002292:
    case cps_provider_2_PartFail{v_35}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_35}}}
    case cps_provider_2_PartOk{v_37}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_3}}, False{}, v_1002302 => template_body_cps_provider_1_layout_words(v_3), v_1002301 => +v_1002295 = template_unbox(Nat, v_1002301); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_buf_move_clear{{v_5 : String}, {v_7 : String}, v_1002295, v_9}}, v_1002300 => +v_1002296 = template_unbox(String, v_1002300); template_continuation_593(v_1002296, v_37)}}

def template_continuation_595(+v_1002290: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World, +v_5: String, +v_7: String, +v_3: cps_provider_1_Layout, +v_9: Bool) -> TemplateProgress<cps_provider_2_Part>:
  v_31 = v_1002290
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_31, v_1, []}}, False{}, v_1002306 => template_body_cps_provider_2_run_jobs(v_31, v_1, []), v_1002305 => +v_1002291 = template_unbox(cps_provider_2_Code, v_1002305); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002291, "pbl"}}, False{}, v_1002304 => template_body_cps_provider_2_part_of(v_1002291, "pbl"), v_1002303 => +v_1002292 = template_unbox(cps_provider_2_Part, v_1002303); template_match_594(v_1002292, v_5, v_7, v_3, v_9)}}

def template_match_596(v_24: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: Bool) -> TemplateProgress<cps_provider_2_Part>:
  match v_24:
    case []:
      template_body_cps_provider_2_zero_value_body(v_1, v_3)
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcBlock{v_5, v_7, False{}, False{}, "pbc"}, "pbl", "pblc"}}, False{}, v_1002308 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcBlock{v_5, v_7, False{}, False{}, "pbc"}, "pbl", "pblc"), v_1002307 => +v_1002290 = template_unbox(List<&2, cps_provider_2_Job>, v_1002307); template_continuation_595(v_1002290, v_1, v_5, v_7, v_3, v_9)}

def template_body_cps_provider_2_buf_field_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: Bool) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_1_LayoutWord{v_1004602}:
      template_match_592(v_1004602, v_5, v_7, v_9)
    case cps_provider_1_LayoutData{v_1004603, v_1004604}:
      template_match_596(v_1004603, v_1, v_3, v_5, v_7, v_9)
    case cps_provider_1_LayoutBox{v_1004605}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a BUF inline form cannot hold a box"}}}

def template_body_cps_provider_2_buf_move_clear(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool) -> TemplateProgress<String>:
  match v_7:
    case True{}:
      template_body_cps_provider_2_buf_clear_words(v_1, v_3, v_5, 0n, "")
    case False{}:
      TemplateFinished{TemplateValue{""}}

def template_body_cps_provider_2_cell_arr_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: String, +v_11: String, +v_13: Bool) -> TemplateProgress<cps_provider_2_Part>:
  match v_13:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_5, " + (", v_7, ")"]}}, False{}, v_1004608 => template_body_cps_provider_2_join_text([v_5, " + (", v_7, ")"]), v_1004609 => +v_1004610 = template_unbox(String, v_1004609); TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_data_move_body{{v_1 : cps_provider_2_World}, {v_3 : cps_provider_1_Layout}, v_1004610, 0n}}, v_1004611 => +v_1004612 = template_unbox(cps_provider_2_Part, v_1004611); TemplateFinished{TemplateValue{v_1004612}}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_5, " + (", v_7, ")"]}}, False{}, v_1004615 => template_body_cps_provider_2_join_text([v_5, " + (", v_7, ")"]), v_1004616 => +v_1004617 = template_unbox(String, v_1004616); template_body_cps_provider_2_data_copy_body({v_1 : cps_provider_2_World}, {v_3 : cps_provider_1_Layout}, v_1004617, 0n, v_9, v_11)}

def template_body_cps_provider_2_cell_move_clear(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool) -> TemplateProgress<String>:
  match v_7:
    case True{}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_buf_clear_span{v_1, v_3, v_5, 0n, "      "}}, v_1004618 => +v_1004619 = template_unbox(String, v_1004618); TemplateFinished{TemplateValue{v_1004619}}}
    case False{}:
      TemplateFinished{TemplateValue{""}}

def template_continuation_601(+v_1002330: String, +v_7: String, v_35: String, v_30: String) -> TemplateProgress<cps_provider_2_Part>:
  v_38 = v_1002330
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["if (", v_7, ") { ", v_35, " } else { Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", v_30, "; ", v_38, " pbr = pbl; }\n"]}}, False{}, v_1002333 => template_body_cps_provider_2_join_text(["if (", v_7, ") { ", v_35, " } else { Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", v_30, "; ", v_38, " pbr = pbl; }\n"]), v_1002332 => +v_1002331 = template_unbox(String, v_1002332); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002331}}}}

def template_match_602(+v_1002329: cps_provider_2_Part, +v_5: String, +v_9: String, v_21: Nat, +v_17: Bool, +v_7: String, v_30: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002329:
    case cps_provider_2_PartFail{v_33}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_33}}}
    case cps_provider_2_PartOk{v_35}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_cell_move_clear{v_5, v_9, v_21, v_17}}, False{}, v_1002335 => template_body_cps_provider_2_cell_move_clear(v_5, v_9, v_21, v_17), v_1002334 => +v_1002330 = template_unbox(String, v_1002334); template_continuation_601(v_1002330, v_7, v_35, v_30)}

def template_match_603(+v_1002328: cps_provider_2_Part, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_9: String, +v_13: String, +v_15: String, +v_17: Bool, v_21: Nat, +v_7: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002328:
    case cps_provider_2_PartFail{v_28}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_28}}}
    case cps_provider_2_PartOk{v_30}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_cell_arr_body{v_1, v_3, v_5, v_9, v_13, v_15, v_17}}, False{}, v_1002337 => template_body_cps_provider_2_cell_arr_body(v_1, v_3, v_5, v_9, v_13, v_15, v_17), v_1002336 => +v_1002329 = template_unbox(cps_provider_2_Part, v_1002336); template_match_602(v_1002329, v_5, v_9, v_21, v_17, v_7, v_30)}

def template_continuation_604(+v_1002326: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_9: String, +v_13: String, +v_15: String, +v_17: Bool, v_21: Nat, +v_7: String) -> TemplateProgress<cps_provider_2_Part>:
  v_24 = v_1002326
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_24, v_1, []}}, False{}, v_1002341 => template_body_cps_provider_2_run_jobs(v_24, v_1, []), v_1002340 => +v_1002327 = template_unbox(cps_provider_2_Code, v_1002340); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002327, "pbl"}}, False{}, v_1002339 => template_body_cps_provider_2_part_of(v_1002327, "pbl"), v_1002338 => +v_1002328 = template_unbox(cps_provider_2_Part, v_1002338); template_match_603(v_1002328, v_1, v_3, v_5, v_9, v_13, v_15, v_17, v_21, v_7)}}

def template_continuation_605(+v_1002325: Nat, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_9: String, +v_13: String, +v_15: String, +v_17: Bool, +v_7: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcBlock{v_5, v_9, False{}, False{}, "pbc"}, "pbl", "pblc"}}, False{}, v_1002343 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcBlock{v_5, v_9, False{}, False{}, "pbc"}, "pbl", "pblc"), v_1002342 => +v_1002326 = template_unbox(List<&2, cps_provider_2_Job>, v_1002342); template_continuation_604(v_1002326, v_1, v_3, v_5, v_9, v_13, v_15, v_17, v_1002325, v_7)}

def template_body_cps_provider_2_cell_data_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: String, +v_11: Nat, +v_13: String, +v_15: String, +v_17: Bool) -> TemplateProgress<cps_provider_2_Part>:
  TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_pow2{v_11}}, v_1002344 => +v_1002325 = template_unbox(Nat, v_1002344); template_continuation_605(v_1002325, v_1, v_3, v_5, v_9, v_13, v_15, v_17, v_7)}

def template_match_606(v_1002345: Bool, +v_9: String, +v_1: String, +v_3: String, +v_7: Nat, +v_5: Nat) -> TemplateProgress<String>:
  match v_1002345:
    case True{}:
      TemplateFinished{TemplateValue{""}}
    case False{}:
      v_1002346 = {v_9 : String}
      v_1002347 = {"blk_write(e.mem, false, " : String}
      v_1002348 = {v_1 : String}
      v_1002349 = {", (u32)((" : String}
      v_1002350 = {v_3 : String}
      v_1002351 = {") + " : String}
      v_1002352 = {Nat.show(v_7) : String}
      v_1002353 = {"ull), 0);\n" : String}
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_buf_clear_span{v_1, v_3, v_5, Nat.add(v_7, 1n), v_9}}, v_1002358 => +v_1002354 = template_unbox(String, v_1002358); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002346, v_1002347, v_1002348, v_1002349, v_1002350, v_1002351, v_1002352, v_1002353, v_1002354]}}, False{}, v_1002357 => template_body_cps_provider_2_join_text([v_1002346, v_1002347, v_1002348, v_1002349, v_1002350, v_1002351, v_1002352, v_1002353, v_1002354]), v_1002356 => +v_1002355 = template_unbox(String, v_1002356); TemplateFinished{TemplateValue{v_1002355}}}}

def template_body_cps_provider_2_buf_clear_span(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String) -> TemplateProgress<String>:
  v_1002345 = {Nat.is_eq(v_7, v_5) : Bool}
  template_match_606(v_1002345, v_9, v_1, v_3, v_7, v_5)

def template_match_607(v_24: cps_provider_1_CWord, v_15: String, v_14: String, v_16: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_24:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = ((u64)(u32)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "))));\n"]}}, False{}, v_1002361 => template_body_cps_provider_2_join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "))));\n"]), v_1002360 => +v_1002359 = template_unbox(String, v_1002360); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002359}}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = (u64)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")));\n"]}}, False{}, v_1002364 => template_body_cps_provider_2_join_text(["pbr = (u64)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")));\n"]), v_1002363 => +v_1002362 = template_unbox(String, v_1002363); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002362}}}}

def template_match_608(v_20: Bool, +v_15: String, +v_14: String, +v_16: String, v_22: String, v_21: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_20:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a BUF array cell cannot contain a boxed field"}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["{ Term pv = blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")); Term pk = term_keep(e, pv, 1); if (pk != pv) { if (", v_22, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_21, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), pk); } } pbr = pk; }\n"]}}, False{}, v_1002367 => template_body_cps_provider_2_join_text(["{ Term pv = blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")); Term pk = term_keep(e, pv, 1); if (pk != pv) { if (", v_22, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_21, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), pk); } } pbr = pk; }\n"]), v_1002366 => +v_1002365 = template_unbox(String, v_1002366); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002365}}}}

def template_match_609(+v_18: cps_provider_1_Layout, v_15: String, v_14: String, v_16: String, v_20: Bool, v_22: String, v_21: String, +v_1: cps_provider_2_World, v_19: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_18:
    case cps_provider_1_LayoutWord{v_24}:
      template_match_607(v_24, v_15, v_14, v_16)
    case cps_provider_1_LayoutBox{v_30}:
      template_match_608(v_20, v_15, v_14, v_16, v_22, v_21)
    case cps_provider_1_LayoutData{v_34, v_35}:
      template_body_cps_provider_2_cell_data_body(v_1, v_18, v_14, v_15, v_16, v_19, v_21, v_22, False{})

def template_body_cps_provider_2_copy_cell_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StCell{v_1004620, v_1004621, v_1004622, v_1004623, v_1004624, v_1004625, v_1004626, v_1004627, v_1004628}:
      template_match_609(v_1004624, v_1004621, v_1004620, v_1004622, v_1004626, v_1004628, v_1004627, v_1, v_1004625)
    case v_1004629:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"not a cell"}}}

def template_match_611(v_1002369: Bool, +v_5: String, +v_3: Nat, +v_1: Nat) -> TemplateProgress<String>:
  match v_1002369:
    case True{}:
      TemplateFinished{TemplateValue{""}}
    case False{}:
      v_1002370 = {v_5 : String}
      v_1002371 = {"e.mem[pdst + " : String}
      v_1002372 = {Nat.show(v_3) : String}
      v_1002373 = {"] = e.mem[psrc + " : String}
      v_1002374 = {Nat.show(v_3) : String}
      v_1002375 = {"];\n" : String}
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_copy_padding{v_1, Nat.add(v_3, 1n), v_5}}, v_1002380 => +v_1002376 = template_unbox(String, v_1002380); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002370, v_1002371, v_1002372, v_1002373, v_1002374, v_1002375, v_1002376]}}, False{}, v_1002379 => template_body_cps_provider_2_join_text([v_1002370, v_1002371, v_1002372, v_1002373, v_1002374, v_1002375, v_1002376]), v_1002378 => +v_1002377 = template_unbox(String, v_1002378); TemplateFinished{TemplateValue{v_1002377}}}}

def template_body_cps_provider_2_copy_padding(+v_1: Nat, +v_3: Nat, +v_5: String) -> TemplateProgress<String>:
  v_1002369 = {Nat.is_eq(v_3, v_1) : Bool}
  template_match_611(v_1002369, v_5, v_3, v_1)

def template_body_cps_provider_2_array_inner(+v_1: Bool, +v_3: String, +v_5: String, +v_7: cps_provider_1_Layout) -> TemplateProgress<String>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy{"psrc", 0n, 0n, v_7, "    "}}, False{}, v_1004630 => template_body_cps_provider_2_move_copy("psrc", 0n, 0n, v_7, "    "), v_1004631 => +v_1004632 = template_unbox(String, v_1004631); TemplateFinished{TemplateValue{v_1004632}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_keep_copy{"psrc", v_3, v_5, 0n, 0n, v_7, "    "}}, False{}, v_1004633 => template_body_cps_provider_2_keep_copy("psrc", v_3, v_5, 0n, 0n, v_7, "    "), v_1004634 => +v_1004635 = template_unbox(String, v_1004634); TemplateFinished{TemplateValue{v_1004635}}}

def template_continuation_613(+v_1002391: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002391}}}

def template_continuation_614(+v_1002390: String, v_14: String, v_15: String, v_18: String, +v_16: Nat, +v_19: String, v_25: Nat, v_31: String, v_28: Nat) -> TemplateProgress<cps_provider_2_Part>:
  v_34 = v_1002390
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u64 pal = (u64)(", v_14, "); u32 pac = (u32)(", v_15, "); bool paarr = ", v_18, "; u64 pnl = 0;\nif (paarr) { pnl = heap_alloc(e, blk_wcls(true, pac)); u64 pacount = (1ull << (pac - ", Nat.show(v_16), ")); for (u64 pe = 0; pe < pacount; pe += 1) { u64 psrc = pal + (", v_19, ") + (pe << ", Nat.show(v_16), "); u64 pdst = pnl + (pe << ", Nat.show(v_16), "); { Term pbbuf[", Nat.show(v_25), "]; ", v_31, v_34, "for (u64 pj = 0; pj < ", Nat.show(v_28), "; pj += 1) { e.mem[pdst + pj] = pbbuf[pj]; } } } } else { pnl = heap_alloc(e, blk_wcls(false, pac)); u64 pacells = (1ull << pac); for (u64 pi = 0; pi < pacells; pi += 1) { blk_write(e.mem, false, pnl, (u32)pi, blk_read(e.mem, false, pal, (u32)((", v_19, ") + pi))); } } pbr = term_blk(paarr, pac, pnl);\n"]}}, False{}, v_1002393 => template_body_cps_provider_2_join_text(["u64 pal = (u64)(", v_14, "); u32 pac = (u32)(", v_15, "); bool paarr = ", v_18, "; u64 pnl = 0;\nif (paarr) { pnl = heap_alloc(e, blk_wcls(true, pac)); u64 pacount = (1ull << (pac - ", Nat.show(v_16), ")); for (u64 pe = 0; pe < pacount; pe += 1) { u64 psrc = pal + (", v_19, ") + (pe << ", Nat.show(v_16), "); u64 pdst = pnl + (pe << ", Nat.show(v_16), "); { Term pbbuf[", Nat.show(v_25), "]; ", v_31, v_34, "for (u64 pj = 0; pj < ", Nat.show(v_28), "; pj += 1) { e.mem[pdst + pj] = pbbuf[pj]; } } } } else { pnl = heap_alloc(e, blk_wcls(false, pac)); u64 pacells = (1ull << pac); for (u64 pi = 0; pi < pacells; pi += 1) { blk_write(e.mem, false, pnl, (u32)pi, blk_read(e.mem, false, pal, (u32)((", v_19, ") + pi))); } } pbr = term_blk(paarr, pac, pnl);\n"]), v_1002392 => +v_1002391 = template_unbox(String, v_1002392); template_continuation_613(v_1002391)}

def template_continuation_615(+v_1002389: String, +v_25: Nat, +v_28: Nat, v_14: String, v_15: String, v_18: String, v_16: Nat, v_19: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_copy_padding{v_25, v_28, "    "}}, False{}, v_1002395 => template_body_cps_provider_2_copy_padding(v_25, v_28, "    "), v_1002394 => +v_1002390 = template_unbox(String, v_1002394); template_continuation_614(v_1002390, v_14, v_15, v_18, v_16, v_19, v_25, v_1002389, v_28)}

def template_continuation_616(+v_1002388: Nat, +v_3: Bool, v_21: String, v_22: String, v_17: cps_provider_1_Layout, v_25: Nat, v_14: String, v_15: String, v_18: String, v_16: Nat, v_19: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_array_inner{v_3, v_21, v_22, v_17}}, False{}, v_1002397 => template_body_cps_provider_2_array_inner(v_3, v_21, v_22, v_17), v_1002396 => +v_1002389 = template_unbox(String, v_1002396); template_continuation_615(v_1002389, v_25, v_1002388, v_14, v_15, v_18, v_16, v_19)}

def template_continuation_617(+v_1002387: Nat, +v_17: cps_provider_1_Layout, +v_3: Bool, v_21: String, v_22: String, v_14: String, v_15: String, v_18: String, v_16: Nat, v_19: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_17}}, False{}, v_1002399 => template_body_cps_provider_1_layout_words(v_17), v_1002398 => +v_1002388 = template_unbox(Nat, v_1002398); template_continuation_616(v_1002388, v_3, v_21, v_22, v_17, v_1002387, v_14, v_15, v_18, v_16, v_19)}

def template_body_cps_provider_2_array_copy_body(+v_1: cps_provider_2_PathState, +v_3: Bool) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_StArray{v_14, v_15, +v_16, v_17, v_18, v_19, v_20, v_21, v_22}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_pow2{v_16}}, v_1002400 => +v_1002387 = template_unbox(Nat, v_1002400); template_continuation_617(v_1002387, v_17, v_3, v_21, v_22, v_14, v_15, v_18, v_16, v_19)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"not an array"}}}

def template_body_cps_provider_2_pow2(+v_1: Nat) -> TemplateProgress<Nat>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{1n}}
    case 1n+v_4:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_pow2{v_4}}, v_1002403 => +v_1002402 = template_unbox(Nat, v_1002403); TemplateFinished{TemplateValue{Nat.mul({2n : Nat}, v_1002402)}}}

def template_match_620(v_24: cps_provider_1_CWord, +v_15: String, +v_14: String, +v_16: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_24:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = ((u64)(u32)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")))); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"]}}, False{}, v_1002406 => template_body_cps_provider_2_join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")))); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"]), v_1002405 => +v_1002404 = template_unbox(String, v_1002405); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002404}}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = (u64)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "))); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"]}}, False{}, v_1002409 => template_body_cps_provider_2_join_text(["pbr = (u64)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "))); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"]), v_1002408 => +v_1002407 = template_unbox(String, v_1002408); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002407}}}}

def template_match_621(v_20: Bool, +v_15: String, +v_14: String, +v_16: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_20:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"a BUF array cell cannot contain a boxed field"}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"]}}, False{}, v_1002412 => template_body_cps_provider_2_join_text(["pbr = blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"]), v_1002411 => +v_1002410 = template_unbox(String, v_1002411); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002410}}}}

def template_match_622(+v_18: cps_provider_1_Layout, v_15: String, v_14: String, v_16: String, v_20: Bool, +v_1: cps_provider_2_World, v_19: Nat, v_21: String, v_22: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_18:
    case cps_provider_1_LayoutWord{v_24}:
      template_match_620(v_24, v_15, v_14, v_16)
    case cps_provider_1_LayoutBox{v_30}:
      template_match_621(v_20, v_15, v_14, v_16)
    case cps_provider_1_LayoutData{v_34, v_35}:
      template_body_cps_provider_2_cell_data_body(v_1, v_18, v_14, v_15, v_16, v_19, v_21, v_22, True{})

def template_body_cps_provider_2_move_cell_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StCell{v_1004636, v_1004637, v_1004638, v_1004639, v_1004640, v_1004641, v_1004642, v_1004643, v_1004644}:
      template_match_622(v_1004640, v_1004637, v_1004636, v_1004638, v_1004642, v_1, v_1004641, v_1004643, v_1004644)
    case v_1004645:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"not a cell"}}}

def template_match_624(+v_12: cps_provider_1_Layout, +v_13: String, +v_11: Nat, +v_1: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_1_LayoutWord{v_19}:
      v_1002415 = {"pbr = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_raw_word_expr{v_13, v_11, v_19}}, False{}, v_1002421 => template_body_cps_provider_2_raw_word_expr(v_13, v_11, v_19), v_1002420 => +v_1002416 = template_unbox(String, v_1002420); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002415, v_1002416, ";\n"]}}, False{}, v_1002419 => template_body_cps_provider_2_join_text([v_1002415, v_1002416, ";\n"]), v_1002418 => +v_1002417 = template_unbox(String, v_1002418); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002417}}}}}
    case cps_provider_1_LayoutBox{v_23}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = e.mem[", v_13, " + ", Nat.show(v_11), "]; e.mem[", v_13, " + ", Nat.show(v_11), "] = 0;\n"]}}, False{}, v_1002424 => template_body_cps_provider_2_join_text(["pbr = e.mem[", v_13, " + ", Nat.show(v_11), "]; e.mem[", v_13, " + ", Nat.show(v_11), "] = 0;\n"]), v_1002423 => +v_1002422 = template_unbox(String, v_1002423); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002422}}}}
    case cps_provider_1_LayoutData{v_27, v_28}:
      TemplatePending{TemplateRequestGroup_4{TemplateRequest_cps_provider_2_data_move_body{v_1, v_12, v_13, v_11}}, v_1002426 => +v_1002425 = template_unbox(cps_provider_2_Part, v_1002426); TemplateFinished{TemplateValue{v_1002425}}}

def template_match_625(v_16: Bool, +v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, v_12: cps_provider_1_Layout, v_13: String, v_11: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_16:
    case True{}:
      template_body_cps_provider_2_copy_slot_body(v_1, v_3)
    case False{}:
      template_match_624(v_12, v_13, v_11, v_1)

def template_body_cps_provider_2_move_slot_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StSlot{v_1004646, v_1004647, v_1004648, v_1004649, v_1004650, v_1004651}:
      template_match_625(v_1004651, v_1, v_3, v_1004647, v_1004648, v_1004646)
    case v_1004652:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"not a field slot"}}}

def template_match_627(+v_1002431: cps_provider_2_Part, v_11: Nat, +v_5: String, +v_7: Nat, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002431:
    case cps_provider_2_PartFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_21}}}
    case cps_provider_2_PartOk{v_23}:
      v_1002432 = {"{ Term pbbuf[" : String}
      v_1002433 = {Nat.show(v_11) : String}
      v_1002434 = {"]; " : String}
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_move_copy{v_5, v_7, v_7, v_3, ""}}, False{}, v_1002440 => template_body_cps_provider_2_move_copy(v_5, v_7, v_7, v_3, ""), v_1002439 => +v_1002435 = template_unbox(String, v_1002439); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002432, v_1002433, v_1002434, v_1002435, "u32 pbi = 0; Term pbl = 0; ", v_23, "; pbr = pbl; }\n"]}}, False{}, v_1002438 => template_body_cps_provider_2_join_text([v_1002432, v_1002433, v_1002434, v_1002435, "u32 pbi = 0; Term pbl = 0; ", v_23, "; pbr = pbl; }\n"]), v_1002437 => +v_1002436 = template_unbox(String, v_1002437); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002436}}}}}

def template_continuation_628(+v_1002429: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_World, v_11: Nat, +v_5: String, +v_7: Nat, +v_3: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_Part>:
  v_17 = v_1002429
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_17, v_1, []}}, False{}, v_1002444 => template_body_cps_provider_2_run_jobs(v_17, v_1, []), v_1002443 => +v_1002430 = template_unbox(cps_provider_2_Code, v_1002443); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002430, "pbl"}}, False{}, v_1002442 => template_body_cps_provider_2_part_of(v_1002430, "pbl"), v_1002441 => +v_1002431 = template_unbox(cps_provider_2_Part, v_1002441); template_match_627(v_1002431, v_11, v_5, v_7, v_3)}}

def template_match_629(+v_11: Nat, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_11:
    case 0n:
      template_body_cps_provider_2_zero_value_body(v_1, v_3)
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_1, v_3, cps_provider_2_SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc"}}, False{}, v_1002446 => template_body_cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc"), v_1002445 => +v_1002429 = template_unbox(List<&2, cps_provider_2_Job>, v_1002445); template_continuation_628(v_1002429, v_1, v_11, v_5, v_7, v_3)}

def template_continuation_630(+v_1002427: Nat, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat) -> TemplateProgress<cps_provider_2_Part>:
  template_match_629(v_1002427, v_1, v_3, v_5, v_7)

def template_body_cps_provider_2_data_move_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_3}}, False{}, v_1002448 => template_body_cps_provider_1_layout_words(v_3), v_1002447 => +v_1002427 = template_unbox(Nat, v_1002447); template_continuation_630(v_1002427, v_1, v_3, v_5, v_7)}

def template_body_cps_provider_2_state_stat(+v_1: cps_provider_2_PathState) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_state_stat(v_1)}}

def template_body_cps_provider_2_state_uniq(+v_1: cps_provider_2_PathState) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_state_uniq(v_1)}}

def template_body_cps_provider_2_path_body_copy(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StSlot{v_1004653, v_1004654, v_1004655, v_1004656, v_1004657, v_1004658}:
      template_body_cps_provider_2_copy_slot_body(v_1, v_3)
    case cps_provider_2_StCell{v_1004659, v_1004660, v_1004661, v_1004662, v_1004663, v_1004664, v_1004665, v_1004666, v_1004667}:
      template_body_cps_provider_2_copy_cell_body(v_1, v_3)
    case cps_provider_2_StArray{v_1004668, v_1004669, v_1004670, v_1004671, v_1004672, v_1004673, v_1004674, v_1004675, v_1004676}:
      template_body_cps_provider_2_array_copy_body(v_3, False{})
    case cps_provider_2_StBufField{v_1004677, v_1004678, v_1004679, v_1004680, v_1004681}:
      template_body_cps_provider_2_buf_field_body(v_1, v_1004679, v_1004677, v_1004678, False{})

def template_body_cps_provider_2_path_body_move(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_StSlot{v_1004682, v_1004683, v_1004684, v_1004685, v_1004686, v_1004687}:
      template_body_cps_provider_2_move_slot_body(v_1, v_3)
    case cps_provider_2_StCell{v_1004688, v_1004689, v_1004690, v_1004691, v_1004692, v_1004693, v_1004694, v_1004695, v_1004696}:
      template_body_cps_provider_2_move_cell_body(v_1, v_3)
    case cps_provider_2_StArray{v_1004697, v_1004698, v_1004699, v_1004700, v_1004701, v_1004702, v_1004703, v_1004704, v_1004705}:
      template_body_cps_provider_2_array_copy_body(v_3, True{})
    case cps_provider_2_StBufField{v_1004706, v_1004707, v_1004708, v_1004709, v_1004710}:
      template_body_cps_provider_2_buf_field_body(v_1, v_1004708, v_1004706, v_1004707, True{})

def template_match_633(+v_1002458: cps_provider_2_Part, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002458:
    case cps_provider_2_PartFail{v_15}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_15}}}
    case cps_provider_2_PartOk{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_expr{v_1, v_17}}, False{}, v_1002461 => template_body_cps_provider_2_path_expr(v_1, v_17), v_1002460 => +v_1002459 = template_unbox(String, v_1002460); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002459}}}}

def template_match_634(+v_1002457: cps_provider_2_PathResult, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002457:
    case cps_provider_2_PathFail{v_10}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_10}}}
    case cps_provider_2_PathOk{v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_read_body{v_6, v_12}}, False{}, v_1002463 => template_body_cps_provider_2_read_body(v_6, v_12), v_1002462 => +v_1002458 = template_unbox(cps_provider_2_Part, v_1002462); template_match_633(v_1002458, v_1)}

def template_body_cps_provider_2_path_read(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_resolve_path{v_6, v_4}}, False{}, v_1002465 => template_body_cps_provider_2_resolve_path(v_6, v_4), v_1002464 => +v_1002457 = template_unbox(cps_provider_2_PathResult, v_1002464); template_match_634(v_1002457, v_6, v_1)}

def template_match_635(v_8: BIR.ConstructorLayout, +v_1: cps_provider_2_World) -> TemplateProgress<Maybe<&2, U32>>:
  match v_8:
    case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
      template_body_cps_provider_2_cid_of(v_14, v_1)

def template_match_636(+v_1002466: Maybe<&2, BIR.ConstructorLayout>, +v_1: cps_provider_2_World) -> TemplateProgress<Maybe<&2, U32>>:
  match v_1002466:
    case None{}:
      TemplateFinished{TemplateValue{None{}}}
    case Some{v_8}:
      template_match_635(v_8, v_1)

def template_body_cps_provider_2_runtime_cid_of_ctor(+v_1: cps_provider_2_World, +v_3: U32) -> TemplateProgress<Maybe<&2, U32>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_ctor_of{v_3, v_1}}, False{}, v_1002469 => template_body_cps_provider_2_ctor_of(v_3, v_1), v_1002468 => +v_1002466 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1002468); template_match_636(v_1002466, v_1)}

def template_match_637(+v_1002471: Maybe<&2, String>, v_7: String, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002471:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the runtime has no canonical False CID"}}}
    case Some{v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["pbr = bend_bool(e, ", v_7, ", ", v_10, ", ", v_3, ");\n"]}}, False{}, v_1002474 => template_body_cps_provider_2_join_text(["pbr = bend_bool(e, ", v_7, ", ", v_10, ", ", v_3, ");\n"]), v_1002473 => +v_1002472 = template_unbox(String, v_1002473); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002472}}}}

def template_match_638(+v_1002470: Maybe<&2, String>, +v_1: cps_provider_2_World, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002470:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the runtime has no canonical True CID"}}}
    case Some{v_7}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"False", v_1}}, False{}, v_1002476 => template_body_cps_provider_2_cid_text("False", v_1), v_1002475 => +v_1002471 = template_unbox(Maybe<&2, String>, v_1002475); template_match_637(v_1002471, v_7, v_3)}

def template_body_cps_provider_2_canonical_bool(+v_1: cps_provider_2_World, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"True", v_1}}, False{}, v_1002478 => template_body_cps_provider_2_cid_text("True", v_1), v_1002477 => +v_1002470 = template_unbox(Maybe<&2, String>, v_1002477); template_match_638(v_1002470, v_1, v_3)}

def template_match_639(+v_1002485: cps_provider_2_Part, +v_1: String, v_23: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002485:
    case cps_provider_2_PartFail{v_26}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_26}}}
    case cps_provider_2_PartOk{v_28}:
      +v_1002486 = {v_1 : String}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u32 pbpred = 0; { ", v_23, " } ", v_28]}}, False{}, v_1002492 => template_body_cps_provider_2_join_text(["u32 pbpred = 0; { ", v_23, " } ", v_28]), v_1002491 => +v_1002487 = template_unbox(String, v_1002491); TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_expr{v_1002486, v_1002487}}, False{}, v_1002490 => template_body_cps_provider_2_path_expr(v_1002486, v_1002487), v_1002489 => +v_1002488 = template_unbox(String, v_1002489); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002488}}}}}

def template_match_640(+v_1002484: cps_provider_2_Part, +v_8: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002484:
    case cps_provider_2_PartFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_21}}}
    case cps_provider_2_PartOk{v_23}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_canonical_bool{v_8, "pbpred"}}, False{}, v_1002494 => template_body_cps_provider_2_canonical_bool(v_8, "pbpred"), v_1002493 => +v_1002485 = template_unbox(cps_provider_2_Part, v_1002493); template_match_639(v_1002485, v_1, v_23)}

def template_match_641(+v_1002480: Maybe<&2, U32>, +v_6: U32, +v_8: cps_provider_2_World, v_14: cps_provider_2_PathState, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002480:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the BIR constructor id ", U32.show(v_6), " has no canonical runtime CID"]}}, False{}, v_1002483 => template_body_cps_provider_2_join_text(["the BIR constructor id ", U32.show(v_6), " has no canonical runtime CID"]), v_1002482 => +v_1002481 = template_unbox(String, v_1002482); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1002481}}}}
    case Some{v_18}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_tag_body{v_8, v_14, Some{v_18}, "pbpred"}}, False{}, v_1002496 => template_body_cps_provider_2_tag_body(v_8, v_14, Some{v_18}, "pbpred"), v_1002495 => +v_1002484 = template_unbox(cps_provider_2_Part, v_1002495); template_match_640(v_1002484, v_8, v_1)}

def template_match_642(+v_1002479: cps_provider_2_PathResult, +v_8: cps_provider_2_World, +v_6: U32, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002479:
    case cps_provider_2_PathFail{v_12}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_12}}}
    case cps_provider_2_PathOk{v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_runtime_cid_of_ctor{v_8, v_6}}, False{}, v_1002498 => template_body_cps_provider_2_runtime_cid_of_ctor(v_8, v_6), v_1002497 => +v_1002480 = template_unbox(Maybe<&2, U32>, v_1002497); template_match_641(v_1002480, v_6, v_8, v_14, v_1)}

def template_body_cps_provider_2_path_hastag(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: U32, +v_8: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_resolve_path{v_8, v_4}}, False{}, v_1002500 => template_body_cps_provider_2_resolve_path(v_8, v_4), v_1002499 => +v_1002479 = template_unbox(cps_provider_2_PathResult, v_1002499); template_match_642(v_1002479, v_8, v_6, v_1)}

def template_match_643(+v_1002502: cps_provider_2_Part, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002502:
    case cps_provider_2_PartFail{v_15}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_15}}}
    case cps_provider_2_PartOk{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_expr{v_1, v_17}}, False{}, v_1002505 => template_body_cps_provider_2_path_expr(v_1, v_17), v_1002504 => +v_1002503 = template_unbox(String, v_1002504); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002503}}}}

def template_match_644(+v_1002501: cps_provider_2_PathResult, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002501:
    case cps_provider_2_PathFail{v_10}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_10}}}
    case cps_provider_2_PathOk{v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_body_copy{v_6, v_12}}, False{}, v_1002507 => template_body_cps_provider_2_path_body_copy(v_6, v_12), v_1002506 => +v_1002502 = template_unbox(cps_provider_2_Part, v_1002506); template_match_643(v_1002502, v_1)}

def template_body_cps_provider_2_path_copy(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_resolve_path{v_6, v_4}}, False{}, v_1002509 => template_body_cps_provider_2_resolve_path(v_6, v_4), v_1002508 => +v_1002501 = template_unbox(cps_provider_2_PathResult, v_1002508); template_match_644(v_1002501, v_6, v_1)}

def template_continuation_645(+v_1002513: String, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  v_27 = v_1002513
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_expr{v_1, v_27}}, False{}, v_1002516 => template_body_cps_provider_2_path_expr(v_1, v_27), v_1002515 => +v_1002514 = template_unbox(String, v_1002515); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002514}}}}

def template_match_646(+v_1002512: cps_provider_2_Part, +v_12: cps_provider_2_PathState, v_17: String, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002512:
    case cps_provider_2_PartFail{v_20}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_20}}}
    case cps_provider_2_PartOk{v_22}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["if (", template_pure_cps_provider_2_state_stat(v_12), " || !", template_pure_cps_provider_2_state_uniq(v_12), ") { ", v_17, " } else { ", v_22, " } "]}}, False{}, v_1002518 => template_body_cps_provider_2_join_text(["if (", template_pure_cps_provider_2_state_stat(v_12), " || !", template_pure_cps_provider_2_state_uniq(v_12), ") { ", v_17, " } else { ", v_22, " } "]), v_1002517 => +v_1002513 = template_unbox(String, v_1002517); template_continuation_645(v_1002513, v_1)}

def template_match_647(+v_1002511: cps_provider_2_Part, +v_6: cps_provider_2_World, +v_12: cps_provider_2_PathState, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002511:
    case cps_provider_2_PartFail{v_15}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_15}}}
    case cps_provider_2_PartOk{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_body_move{v_6, v_12}}, False{}, v_1002520 => template_body_cps_provider_2_path_body_move(v_6, v_12), v_1002519 => +v_1002512 = template_unbox(cps_provider_2_Part, v_1002519); template_match_646(v_1002512, v_12, v_17, v_1)}

def template_match_648(+v_1002510: cps_provider_2_PathResult, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002510:
    case cps_provider_2_PathFail{v_10}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_10}}}
    case cps_provider_2_PathOk{+v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_body_copy{v_6, v_12}}, False{}, v_1002522 => template_body_cps_provider_2_path_body_copy(v_6, v_12), v_1002521 => +v_1002511 = template_unbox(cps_provider_2_Part, v_1002521); template_match_647(v_1002511, v_6, v_12, v_1)}

def template_body_cps_provider_2_path_consume(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_resolve_path{v_6, v_4}}, False{}, v_1002524 => template_body_cps_provider_2_resolve_path(v_6, v_4), v_1002523 => +v_1002510 = template_unbox(cps_provider_2_PathResult, v_1002523); template_match_648(v_1002510, v_6, v_1)}

def template_match_649(+v_1002527: cps_provider_2_Part, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002527:
    case cps_provider_2_PartFail{v_36}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_36}}}
    case cps_provider_2_PartOk{v_38}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_expr{v_1, v_38}}, False{}, v_1002530 => template_body_cps_provider_2_path_expr(v_1, v_38), v_1002529 => +v_1002528 = template_unbox(String, v_1002529); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002528}}}}

def template_continuation_650(+v_1002526: String, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  v_33 = v_1002526
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_canonical_bool{v_6, v_33}}, False{}, v_1002532 => template_body_cps_provider_2_canonical_bool(v_6, v_33), v_1002531 => +v_1002527 = template_unbox(cps_provider_2_Part, v_1002531); template_match_649(v_1002527, v_1)}

def template_match_651(v_12: cps_provider_2_PathState, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_2_StArray{v_22, v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u32)(", v_23, ") == ", Nat.show(v_24), "u)"]}}, False{}, v_1002534 => template_body_cps_provider_2_join_text(["((u32)(", v_23, ") == ", Nat.show(v_24), "u)"]), v_1002533 => +v_1002526 = template_unbox(String, v_1002533); template_continuation_650(v_1002526, v_6, v_1)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"an array leaf test needs an array slice"}}}

def template_match_652(+v_1002525: cps_provider_2_PathResult, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002525:
    case cps_provider_2_PathFail{v_10}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_10}}}
    case cps_provider_2_PathOk{v_12}:
      template_match_651(v_12, v_6, v_1)

def template_body_cps_provider_2_path_is_leaf(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_resolve_path{v_6, v_4}}, False{}, v_1002536 => template_body_cps_provider_2_resolve_path(v_6, v_4), v_1002535 => +v_1002525 = template_unbox(cps_provider_2_PathResult, v_1002535); template_match_652(v_1002525, v_6, v_1)}

def template_match_653(+v_1002539: cps_provider_2_Part, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002539:
    case cps_provider_2_PartFail{v_36}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_36}}}
    case cps_provider_2_PartOk{v_38}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_path_expr{v_1, v_38}}, False{}, v_1002542 => template_body_cps_provider_2_path_expr(v_1, v_38), v_1002541 => +v_1002540 = template_unbox(String, v_1002541); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002540}}}}

def template_continuation_654(+v_1002538: String, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  v_33 = v_1002538
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_canonical_bool{v_6, v_33}}, False{}, v_1002544 => template_body_cps_provider_2_canonical_bool(v_6, v_33), v_1002543 => +v_1002539 = template_unbox(cps_provider_2_Part, v_1002543); template_match_653(v_1002539, v_1)}

def template_match_655(v_12: cps_provider_2_PathState, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_2_StArray{v_22, v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u32)(", v_23, ") > ", Nat.show(v_24), "u)"]}}, False{}, v_1002546 => template_body_cps_provider_2_join_text(["((u32)(", v_23, ") > ", Nat.show(v_24), "u)"]), v_1002545 => +v_1002538 = template_unbox(String, v_1002545); template_continuation_654(v_1002538, v_6, v_1)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"an array node test needs an array slice"}}}

def template_match_656(+v_1002537: cps_provider_2_PathResult, +v_6: cps_provider_2_World, +v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002537:
    case cps_provider_2_PathFail{v_10}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_10}}}
    case cps_provider_2_PathOk{v_12}:
      template_match_655(v_12, v_6, v_1)

def template_body_cps_provider_2_path_is_node(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_resolve_path{v_6, v_4}}, False{}, v_1002548 => template_body_cps_provider_2_resolve_path(v_6, v_4), v_1002547 => +v_1002537 = template_unbox(cps_provider_2_PathResult, v_1002547); template_match_656(v_1002537, v_6, v_1)}

def template_match_657(+v_5: cps_provider_1_Node, +v_3: cps_provider_2_World, +v_7: cps_provider_1_Layout, +v_9: Nat, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case cps_provider_1_Node{v_20, v_21, v_22}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_project_packed_flag{v_22, v_3, v_7, v_9, List.length(&2, cps_provider_1_CWord, v_20), v_11}}, False{}, v_1002551 => template_body_cps_provider_2_project_packed_flag(v_22, v_3, v_7, v_9, List.length(&2, cps_provider_1_CWord, v_20), v_11), v_1002550 => +v_1002549 = template_unbox(cps_provider_2_Part, v_1002550); TemplateFinished{TemplateValue{v_1002549}}}

def template_body_cps_provider_2_project_plan(+v_1: cps_provider_1_UnfillResult, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Node, +v_7: cps_provider_1_Layout, +v_9: Nat, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_1_UnfillFailed{v_1004711}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004711}}}
    case cps_provider_1_UnfillFound{v_1004712}:
      template_match_657(v_5, v_3, v_7, v_9, v_11)

def template_continuation_659(+v_1002555: cps_provider_1_UnfillResult, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Node, v_23: cps_provider_1_Layout, v_22: Nat, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_project_plan(v_1002555, v_3, v_5, v_23, v_22, v_11)

def template_match_660(+v_3: cps_provider_2_World, +v_7: String, +v_9: U32, +v_5: cps_provider_1_Node, v_23: cps_provider_1_Layout, v_22: Nat, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_World{v_27, v_28, v_29}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_slot_unfill{v_27, v_7, v_9}}, False{}, v_1002558 => template_body_cps_provider_1_slot_unfill(v_27, v_7, v_9), v_1002557 => +v_1002555 = template_unbox(cps_provider_1_UnfillResult, v_1002557); template_continuation_659(v_1002555, v_3, v_5, v_23, v_22, v_11)}

def template_match_661(v_17: cps_provider_1_NodeSlot, +v_3: cps_provider_2_World, +v_7: String, +v_9: U32, +v_5: cps_provider_1_Node, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_17:
    case cps_provider_1_NodeSlot{v_21, v_22, v_23}:
      template_match_660(v_3, v_7, v_9, v_5, v_23, v_22, v_11)

def template_body_cps_provider_2_project_slot(+v_1: cps_provider_1_SlotResult, +v_3: cps_provider_2_World, +v_5: cps_provider_1_Node, +v_7: String, +v_9: U32, +v_11: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_1_SlotErased{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the projection of `", v_7, "` names an erased field, which has no storage"]}}, False{}, v_1004713 => template_body_cps_provider_2_join_text(["the projection of `", v_7, "` names an erased field, which has no storage"]), v_1004714 => +v_1004715 = template_unbox(String, v_1004714); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004715}}}}
    case cps_provider_1_SlotFailed{v_1004716}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004716}}}
    case cps_provider_1_SlotFound{v_1004717}:
      template_match_661(v_1004717, v_3, v_7, v_9, v_5, v_11)

def template_continuation_663(+v_1002559: cps_provider_1_SlotResult, +v_3: cps_provider_2_World, v_14: cps_provider_1_Node, +v_5: String, +v_7: U32, +v_9: String) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_project_slot(v_1002559, v_3, v_14, v_5, v_7, v_9)

def template_match_664(+v_3: cps_provider_2_World, +v_5: String, +v_7: U32, v_14: cps_provider_1_Node, +v_9: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_World{v_18, v_19, v_20}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_slot{v_18, v_5, v_7}}, False{}, v_1002562 => template_body_cps_provider_1_node_slot(v_18, v_5, v_7), v_1002561 => +v_1002559 = template_unbox(cps_provider_1_SlotResult, v_1002561); template_continuation_663(v_1002559, v_3, v_14, v_5, v_7, v_9)}

def template_body_cps_provider_2_project_layout(+v_1: cps_provider_1_NodeResult, +v_3: cps_provider_2_World, +v_5: String, +v_7: U32, +v_9: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_1_NodeFailed{v_12}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_12}}}
    case cps_provider_1_NodeFound{v_14}:
      template_match_664(v_3, v_5, v_7, v_14, v_9)

def template_continuation_666(+v_1002563: cps_provider_1_NodeResult, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_project_layout(v_1002563, v_1, v_3, v_5, v_7)

def template_body_cps_provider_2_project_node(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_World{v_12, v_13, v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_layout{v_12, v_3}}, False{}, v_1002566 => template_body_cps_provider_1_node_layout(v_12, v_3), v_1002565 => +v_1002563 = template_unbox(cps_provider_1_NodeResult, v_1002565); template_continuation_666(v_1002563, v_1, v_3, v_5, v_7)}

def template_body_cps_provider_2_project_marker(+v_1: Bool, +v_3: String, +v_5: String, +v_7: U32, +v_9: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the intrinsic constructor `", v_5, "` must be lowered to its primitive before C projection"]}}, False{}, v_1004718 => template_body_cps_provider_2_join_text(["the intrinsic constructor `", v_5, "` must be lowered to its primitive before C projection"]), v_1004719 => +v_1004720 = template_unbox(String, v_1004719); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004720}}}}
    case False{}:
      template_body_cps_provider_2_project_node(v_9, v_5, v_7, v_3)

def template_body_cps_provider_2_project_native(+v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_8: U32, +v_10: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      template_body_cps_provider_2_project_node(v_10, v_6, v_8, v_4)
    case Some{v_1004721}:
      TemplateDirect{Bool, TemplateRequestGroup_4{TemplateRequest_cps_provider_2_project_marker{template_pure_cps_provider_2_intrinsic_marker(v_1004721), v_4, v_6, v_8, v_10}}, False{}, v_1004722 => template_body_cps_provider_2_project_marker(template_pure_cps_provider_2_intrinsic_marker(v_1004721), v_4, v_6, v_8, v_10), v_1004723 => +v_1004724 = template_unbox(cps_provider_2_Part, v_1004723); TemplateFinished{TemplateValue{v_1004724}}}

def template_match_670(v_10: BIR.ConstructorLayout, +v_3: String, +v_5: U32, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_10:
    case BIR.ConstructorLayout{v_15, v_16, v_17, v_18}:
      template_body_cps_provider_2_project_native(v_17, v_3, v_16, v_5, v_7)

def template_body_cps_provider_2_project_row(+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: U32, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"BIR projects a constructor with no layout row"}}}
    case Some{v_10}:
      template_match_670(v_10, v_3, v_5, v_7)

def template_continuation_672(+v_1002576: Maybe<&2, BIR.ConstructorLayout>, +v_1: String, +v_5: U32, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_project_row(v_1002576, v_1, v_5, v_7)

def template_body_cps_provider_2_project_part(+v_1: String, +v_3: U32, +v_5: U32, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_ctor_of{v_3, v_7}}, False{}, v_1002579 => template_body_cps_provider_2_ctor_of(v_3, v_7), v_1002578 => +v_1002576 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1002578); template_continuation_672(v_1002576, v_1, v_5, v_7)}

def template_match_673(+v_5: Maybe<&2, String>, v_12: String, +v_9: String, +v_7: U32) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the C runtime contract needs the `False` constructor for a tag test"}}}
    case Some{v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["bend_bool(e, ", v_12, ", ", v_14, ", (u64)bend_hastag(", v_9, ", ", U32.show(v_7), "u))"]}}, False{}, v_1002582 => template_body_cps_provider_2_join_text(["bend_bool(e, ", v_12, ", ", v_14, ", (u64)bend_hastag(", v_9, ", ", U32.show(v_7), "u))"]), v_1002581 => +v_1002580 = template_unbox(String, v_1002581); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002580}}}}

def template_body_cps_provider_2_hastag_bools(+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: U32, +v_9: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the C runtime contract needs the `True` constructor for a tag test"}}}
    case Some{v_1004725}:
      template_match_673(v_5, v_1004725, v_9, v_7)

def template_body_cps_provider_2_hastag_cid(+v_2: Maybe<&2, U32>, +v_4: String, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the tagged constructor has no canonical CID row"}}}
    case Some{v_1004726}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"True", v_6}}, False{}, v_1004727 => template_body_cps_provider_2_cid_text("True", v_6), v_1004728 => +v_1004729 = template_unbox(Maybe<&2, String>, v_1004728); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"False", v_6}}, False{}, v_1004730 => template_body_cps_provider_2_cid_text("False", v_6), v_1004731 => +v_1004732 = template_unbox(Maybe<&2, String>, v_1004731); template_body_cps_provider_2_hastag_bools(v_1004729, v_1004732, v_1004726, v_4)}}

def template_match_676(v_8: BIR.ConstructorLayout, +v_5: cps_provider_2_World, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_8:
    case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{v_14, v_5}}, False{}, v_1002593 => template_body_cps_provider_2_cid_of(v_14, v_5), v_1002592 => +v_1002590 = template_unbox(Maybe<&2, U32>, v_1002592); template_body_cps_provider_2_hastag_cid(v_1002590, v_3, v_5)}

def template_body_cps_provider_2_hastag_row(+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"BIR has-tags a constructor with no layout row"}}}
    case Some{v_1004733}:
      template_match_676(v_1004733, v_5, v_3)

def template_continuation_678(+v_1002594: Maybe<&2, BIR.ConstructorLayout>, +v_1: String, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  template_body_cps_provider_2_hastag_row(v_1002594, v_1, v_5)

def template_body_cps_provider_2_hastag_part(+v_1: String, +v_3: U32, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_ctor_of{v_3, v_5}}, False{}, v_1002597 => template_body_cps_provider_2_ctor_of(v_3, v_5), v_1002596 => +v_1002594 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1002596); template_continuation_678(v_1002594, v_1, v_5)}

def template_body_cps_provider_2_arr_flag(+v_1: Bool) -> TemplateProgress<String>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{"true"}}
    case False{}:
      TemplateFinished{TemplateValue{"false"}}

def template_body_cps_provider_2_array_label(+v_0: BIR.Primitive) -> TemplateProgress<String>:
  match v_0:
    case BIR.PrimArrayNew{}:
      TemplateFinished{TemplateValue{"array_new"}}
    case BIR.PrimArrayGet{}:
      TemplateFinished{TemplateValue{"array_get"}}
    case BIR.PrimArraySet{}:
      TemplateFinished{TemplateValue{"array_set"}}
    case BIR.PrimArraySwap{}:
      TemplateFinished{TemplateValue{"array_swap"}}
    case BIR.PrimArrayAtomicAdd{}:
      TemplateFinished{TemplateValue{"array_atomic_add"}}
    case BIR.PrimArrayAtomicMin{}:
      TemplateFinished{TemplateValue{"array_atomic_min"}}
    case BIR.PrimArrayAtomicMax{}:
      TemplateFinished{TemplateValue{"array_atomic_max"}}
    case BIR.PrimArrayAtomicAnd{}:
      TemplateFinished{TemplateValue{"array_atomic_and"}}
    case BIR.PrimArrayAtomicOr{}:
      TemplateFinished{TemplateValue{"array_atomic_or"}}
    case BIR.PrimArrayAtomicXor{}:
      TemplateFinished{TemplateValue{"array_atomic_xor"}}
    case BIR.PrimArrayAtomicExch{}:
      TemplateFinished{TemplateValue{"array_atomic_exch"}}
    case BIR.PrimArrayAtomicCas{}:
      TemplateFinished{TemplateValue{"array_atomic_cas"}}
    case BIR.PrimArrayAtomicFadd{}:
      TemplateFinished{TemplateValue{"array_atomic_fadd"}}
    case BIR.PrimArraySize{}:
      TemplateFinished{TemplateValue{"array_size"}}
    case BIR.PrimArrayClone{}:
      TemplateFinished{TemplateValue{"array_clone"}}
    case BIR.PrimArrayLeaf{}:
      TemplateFinished{TemplateValue{"array_leaf"}}
    case BIR.PrimArrayNode{}:
      TemplateFinished{TemplateValue{"array_node"}}
    case BIR.PrimIsArrayLeaf{}:
      TemplateFinished{TemplateValue{"is_array_leaf"}}
    case BIR.PrimIsArrayNode{}:
      TemplateFinished{TemplateValue{"is_array_node"}}
    case _:
      TemplateFinished{TemplateValue{"array"}}

def template_body_cps_provider_2_descriptor_missing(+v_0: BIR.Primitive) -> TemplateProgress<String>:
  match v_0:
    case BIR.PrimMapFind{}:
      TemplateFinished{TemplateValue{"the map read `Map.find` carries no instantiated value Descriptor; lowering must supply PrimitiveCall.types"}}
    case _:
      v_1002598 = {"the array primitive `" : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_label{v_0}}, False{}, v_1002604 => template_body_cps_provider_2_array_label(v_0), v_1002603 => +v_1002599 = template_unbox(String, v_1002603); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002598, v_1002599, "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"]}}, False{}, v_1002602 => template_body_cps_provider_2_join_text([v_1002598, v_1002599, "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"]), v_1002601 => +v_1002600 = template_unbox(String, v_1002601); TemplateFinished{TemplateValue{v_1002600}}}}

def template_match_682(v_6: cps_provider_1_Cell) -> TemplateProgress<cps_provider_2_CellOut>:
  match v_6:
    case cps_provider_1_Cell{v_11, v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{cps_provider_2_CellOk{v_11, v_12, v_13, v_14}}}

def template_body_cps_provider_2_array_cell_result(+v_1: cps_provider_1_CellResult) -> TemplateProgress<cps_provider_2_CellOut>:
  match v_1:
    case cps_provider_1_CellFailed{v_4}:
      TemplateFinished{TemplateValue{cps_provider_2_CellFail{v_4}}}
    case cps_provider_1_CellFound{v_6}:
      template_match_682(v_6)

def template_match_684(+v_1: cps_provider_2_World, +v_9: BIR.Descriptor) -> TemplateProgress<cps_provider_2_CellOut>:
  match v_1:
    case cps_provider_2_World{v_13, v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_array_cell{v_13, v_9}}, False{}, v_1002615 => template_body_cps_provider_1_array_cell(v_13, v_9), v_1002614 => +v_1002612 = template_unbox(cps_provider_1_CellResult, v_1002614); template_body_cps_provider_2_array_cell_result(v_1002612)}

def template_body_cps_provider_2_array_cell(+v_1: cps_provider_2_World, +v_3: List<&2, BIR.Descriptor>, +v_4: BIR.Primitive) -> TemplateProgress<cps_provider_2_CellOut>:
  match v_3:
    case []:
      v_1004734 = {"the array primitive `" : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_label{v_4}}, False{}, v_1004735 => template_body_cps_provider_2_array_label(v_4), v_1004736 => +v_1004737 = template_unbox(String, v_1004736); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1004734, v_1004737, "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"]}}, False{}, v_1004738 => template_body_cps_provider_2_join_text([v_1004734, v_1004737, "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"]), v_1004739 => +v_1004740 = template_unbox(String, v_1004739); TemplateFinished{TemplateValue{cps_provider_2_CellFail{v_1004740}}}}}
    case [+v_1004741]:
      template_match_684(v_1, v_1004741)
    case v_1004742:
      v_1004743 = {"the array primitive `" : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_label{v_4}}, False{}, v_1004744 => template_body_cps_provider_2_array_label(v_4), v_1004745 => +v_1004746 = template_unbox(String, v_1004745); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1004743, v_1004746, "` must carry exactly one element Descriptor"]}}, False{}, v_1004747 => template_body_cps_provider_2_join_text([v_1004743, v_1004746, "` must carry exactly one element Descriptor"]), v_1004748 => +v_1004749 = template_unbox(String, v_1004748); TemplateFinished{TemplateValue{cps_provider_2_CellFail{v_1004749}}}}}

def template_match_686(+v_4: Nat, +v_9: cps_provider_2_Operand, +v_10: List<&2, cps_provider_2_Operand>) -> TemplateProgress<Maybe<&2, cps_provider_2_Operand>>:
  match v_4:
    case 0n:
      TemplateFinished{TemplateValue{Some{v_9}}}
    case 1n+v_12:
      TemplatePending{TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_10, v_12}}, v_1002624 => +v_1002623 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1002624); TemplateFinished{TemplateValue{v_1002623}}}

def template_body_cps_provider_2_operand_at(+v_2: List<&2, cps_provider_2_Operand>, +v_4: Nat) -> TemplateProgress<Maybe<&2, cps_provider_2_Operand>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_9 <> +v_10:
      template_match_686(v_4, v_9, v_10)

def template_body_cps_provider_2_operand_text(+v_1: cps_provider_2_Operand) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_operand_text(v_1)}}

def template_body_cps_provider_2_operand_use(+v_1: cps_provider_2_Operand) -> TemplateProgress<BIR.Use>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_operand_use(v_1)}}

def template_match_688(v_5: BIR.Use, v_6: String) -> TemplateProgress<String>:
  match v_5:
    case BIR.Many{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["term_keep(e, ", v_6, ", 1)"]}}, False{}, v_1002627 => template_body_cps_provider_2_join_text(["term_keep(e, ", v_6, ", 1)"]), v_1002626 => +v_1002625 = template_unbox(String, v_1002626); TemplateFinished{TemplateValue{v_1002625}}}
    case _:
      TemplateFinished{TemplateValue{v_6}}

def template_body_cps_provider_2_keep_text(+v_1: cps_provider_2_Operand) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_2_Operand{v_5, v_6}:
      template_match_688(v_5, v_6)

def template_body_cps_provider_2_tuple_cid(+v_2: Maybe<&2, String>, +v_4: String, +v_6: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case Some{v_9}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["bend_tuple(e, ", v_9, ", ", v_4, ", ", v_6, ")"]}}, False{}, v_1002630 => template_body_cps_provider_2_join_text(["bend_tuple(e, ", v_9, ", ", v_4, ", ", v_6, ")"]), v_1002629 => +v_1002628 = template_unbox(String, v_1002629); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002628}}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the C runtime contract needs the `Tuple` constructor for an array result"}}}

def template_body_cps_provider_2_tuple_part(+v_1: cps_provider_2_World, +v_3: String, +v_5: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"Tuple", v_1}}, False{}, v_1002634 => template_body_cps_provider_2_cid_text("Tuple", v_1), v_1002633 => +v_1002631 = template_unbox(Maybe<&2, String>, v_1002633); template_body_cps_provider_2_tuple_cid(v_1002631, v_3, v_5)}

def template_body_cps_provider_2_seal_cell_box(+v_0: BIR.Use, +v_2: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_0:
    case BIR.Many{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["w0[", v_2, "] = term_keep(e, w0[", v_2, "], 1); ", v_2, " += 1;"]}}, False{}, v_1002637 => template_body_cps_provider_2_join_text(["w0[", v_2, "] = term_keep(e, w0[", v_2, "], 1); ", v_2, " += 1;"]), v_1002636 => +v_1002635 = template_unbox(String, v_1002636); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1002635}]}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_2, " += 1;"]}}, False{}, v_1002640 => template_body_cps_provider_2_join_text([v_2, " += 1;"]), v_1002639 => +v_1002638 = template_unbox(String, v_1002639); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1002638}]}}}

def template_body_cps_provider_2_seal_cell_kind(+v_0: BIR.Use, +v_2: cps_provider_1_CWord, +v_4: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_2:
    case cps_provider_1_CWord32{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_4, " += 1;"]}}, False{}, v_1004750 => template_body_cps_provider_2_join_text([v_4, " += 1;"]), v_1004751 => +v_1004752 = template_unbox(String, v_1004751); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004752}]}}}
    case cps_provider_1_CWord64{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_4, " += 1;"]}}, False{}, v_1004753 => template_body_cps_provider_2_join_text([v_4, " += 1;"]), v_1004754 => +v_1004755 = template_unbox(String, v_1004754); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1004755}]}}}
    case cps_provider_1_CWordBox{}:
      template_body_cps_provider_2_seal_cell_box(v_0, v_4)

def template_body_cps_provider_2_seal_cell_walk(+v_0: BIR.Use, +v_3: List<&2, cps_provider_1_CWord>, +v_5: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004756 <> +v_1004757:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_seal_cell_kind{v_0, v_1004756, v_5}}, False{}, v_1004758 => template_body_cps_provider_2_seal_cell_kind(v_0, v_1004756, v_5), v_1004759 => +v_1004760 = template_unbox(List<&2, cps_provider_2_Job>, v_1004759); TemplatePending{TemplateRequestGroup_5{TemplateRequest_cps_provider_2_seal_cell_walk{v_0, v_1004757, v_5}}, v_1004761 => +v_1004762 = template_unbox(List<&2, cps_provider_2_Job>, v_1004761); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1004760, v_1004762)}}}}

def template_continuation_694(+v_1002655: List<&2, cps_provider_2_Job>, +v_1002656: List<&2, cps_provider_2_Job>, +v_1002657: List<&2, cps_provider_2_Job>, +v_1002660: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_26 = List.append(&2, cps_provider_2_Job, v_1002655, List.append(&2, cps_provider_2_Job, v_1002656, List.append(&2, cps_provider_2_Job, v_1002657, v_1002660)))
  TemplateFinished{TemplateValue{v_26}}

def template_continuation_695(+v_4: BIR.Use, +v_3: cps_provider_1_Layout, v_15: String, +v_1002655: List<&2, cps_provider_2_Job>, +v_1002656: List<&2, cps_provider_2_Job>, +v_1002657: List<&2, cps_provider_2_Job>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  +v_1002658 = {v_4 : BIR.Use}
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_kinds{v_3}}, False{}, v_1002664 => template_body_cps_provider_1_layout_kinds(v_3), v_1002663 => +v_1002659 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002663); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_seal_cell_walk{v_1002658, v_1002659, v_15}}, False{}, v_1002662 => template_body_cps_provider_2_seal_cell_walk(v_1002658, v_1002659, v_15), v_1002661 => +v_1002660 = template_unbox(List<&2, cps_provider_2_Job>, v_1002661); template_continuation_694(v_1002655, v_1002656, v_1002657, v_1002660)}}

def template_continuation_696(+v_1002653: String, +v_6: cps_provider_2_Code, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_8: String, +v_10: String, +v_4: BIR.Use) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["u32 ", v_1002653, " = 0;"]}}, False{}, v_1002672 => template_body_cps_provider_2_join_text(["u32 ", v_1002653, " = 0;"]), v_1002671 => +v_1002654 = template_unbox(String, v_1002671); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1002654}}}, False{}, v_1002670 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1002654}), v_1002669 => +v_1002655 = template_unbox(List<&2, cps_provider_2_Job>, v_1002669); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_code_jobs{v_6}}, False{}, v_1002668 => template_body_cps_provider_2_code_jobs(v_6), v_1002667 => +v_1002656 = template_unbox(List<&2, cps_provider_2_Job>, v_1002667); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_fill_jobs{v_1, v_3, v_8, cps_provider_2_DstSeq{"w0", "o0"}, v_10}}, False{}, v_1002666 => template_body_cps_provider_2_fill_jobs(v_1, v_3, v_8, cps_provider_2_DstSeq{"w0", "o0"}, v_10), v_1002665 => +v_1002657 = template_unbox(List<&2, cps_provider_2_Job>, v_1002665); template_continuation_695(v_4, v_3, v_1002653, v_1002655, v_1002656, v_1002657)}}}}

def template_body_cps_provider_2_elem_fill_operand(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_4: BIR.Use, +v_6: cps_provider_2_Code, +v_8: String, +v_10: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_10, "c"]}}, False{}, v_1002674 => template_body_cps_provider_2_join_text([v_10, "c"]), v_1002673 => +v_1002653 = template_unbox(String, v_1002673); template_continuation_696(v_1002653, v_6, v_1, v_3, v_8, v_10, v_4)}

def template_body_cps_provider_2_elem_fill(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_4: BIR.Use, +v_6: String, +v_8: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_operand_code{v_3, v_4, v_6, v_8}}, False{}, v_1002684 => template_body_cps_provider_2_operand_code(v_3, v_4, v_6, v_8), v_1002683 => +v_1002678 = template_unbox(cps_provider_2_Code, v_1002683); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_operand_name{v_3, v_4, v_6, v_8}}, False{}, v_1002682 => template_body_cps_provider_2_operand_name(v_3, v_4, v_6, v_8), v_1002681 => +v_1002679 = template_unbox(String, v_1002681); template_body_cps_provider_2_elem_fill_operand({v_1 : cps_provider_2_World}, {v_3 : cps_provider_1_Layout}, {v_4 : BIR.Use}, v_1002678, v_1002679, v_8)}}

def template_body_cps_provider_2_elem_stores(+v_1: Nat) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["Term f0[", Nat.show(v_1), "]; for (u32 f0i = 0; f0i < ", Nat.show(v_1), "; f0i += 1) { f0[f0i] = w0[f0i]; }"]}}, False{}, v_1002687 => template_body_cps_provider_2_join_text(["Term f0[", Nat.show(v_1), "]; for (u32 f0i = 0; f0i < ", Nat.show(v_1), "; f0i += 1) { f0[f0i] = w0[f0i]; }"]), v_1002686 => +v_1002685 = template_unbox(String, v_1002686); TemplateFinished{TemplateValue{v_1002685}}}

def template_body_cps_provider_2_elem_decl(+v_1: Nat) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_dst_decl{"w0", "o0", v_1}}, False{}, v_1002690 => template_body_cps_provider_2_dst_decl("w0", "o0", v_1), v_1002689 => +v_1002688 = template_unbox(String, v_1002689); TemplateFinished{TemplateValue{v_1002688}}}

def template_body_cps_provider_2_run_part(+v_2: List<&2, cps_provider_2_Job>, +v_4: cps_provider_2_World, +v_6: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_2, v_4, []}}, False{}, v_1002694 => template_body_cps_provider_2_run_jobs(v_2, v_4, []), v_1002693 => +v_1002691 = template_unbox(cps_provider_2_Code, v_1002693); template_body_cps_provider_2_part_of(v_1002691, v_6)}

def template_continuation_697(+v_1002696: String, +v_1002697: List<&2, cps_provider_2_Job>, v_24: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World, +v_11: Bool, v_18: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat) -> TemplateProgress<cps_provider_2_Part>:
  v_32 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002696}], List.append(&2, cps_provider_2_Job, v_1002697, v_24))
  v_1002700 = {"blk_new(e, " : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_arr_flag{v_11}}, False{}, v_1002707 => template_body_cps_provider_2_arr_flag(v_11), v_1002706 => +v_1002701 = template_unbox(String, v_1002706); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002700, v_1002701, ", (u64)(", template_pure_cps_provider_2_operand_text(v_18), "), ", Nat.show(v_15), ", ", Nat.show(v_13), ", f0)"]}}, False{}, v_1002705 => template_body_cps_provider_2_join_text([v_1002700, v_1002701, ", (u64)(", template_pure_cps_provider_2_operand_text(v_18), "), ", Nat.show(v_15), ", ", Nat.show(v_13), ", f0)"]), v_1002704 => +v_1002702 = template_unbox(String, v_1002704); template_body_cps_provider_2_run_part({v_32 : List<&2, cps_provider_2_Job>}, {v_7 : cps_provider_2_World}, v_1002702)}}

def template_continuation_698(+v_1002695: String, +v_13: Nat, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_20: cps_provider_2_Operand, +v_11: Bool, v_18: cps_provider_2_Operand, +v_15: Nat) -> TemplateProgress<cps_provider_2_Part>:
  v_24 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002695}], [])
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_decl{v_13}}, False{}, v_1002711 => template_body_cps_provider_2_elem_decl(v_13), v_1002710 => +v_1002696 = template_unbox(String, v_1002710); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_fill{v_7, v_9, template_pure_cps_provider_2_operand_use(v_20), template_pure_cps_provider_2_operand_text(v_20), "an"}}, False{}, v_1002709 => template_body_cps_provider_2_elem_fill(v_7, v_9, template_pure_cps_provider_2_operand_use(v_20), template_pure_cps_provider_2_operand_text(v_20), "an"), v_1002708 => +v_1002697 = template_unbox(List<&2, cps_provider_2_Job>, v_1002708); template_continuation_697(v_1002696, v_1002697, v_24, v_7, v_11, v_18, v_15, v_13)}}

def template_match_699(+v_5: Maybe<&2, cps_provider_2_Operand>, +v_13: Nat, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, v_18: cps_provider_2_Operand, +v_15: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_new needs the dimension and the value"}}}
    case Some{v_20}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_stores{v_13}}, False{}, v_1002713 => template_body_cps_provider_2_elem_stores(v_13), v_1002712 => +v_1002695 = template_unbox(String, v_1002712); template_continuation_698(v_1002695, v_13, v_7, v_9, v_20, v_11, v_18, v_15)}

def template_body_cps_provider_2_array_new_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_new needs the dimension and the value"}}}
    case Some{v_1004763}:
      template_match_699(v_5, v_13, v_7, v_9, v_11, v_1004763, v_15)

def template_body_cps_provider_2_tuple_and_code(+v_1: cps_provider_2_Part, +v_3: cps_provider_2_Code) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_PartFail{v_6}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_6}}}
    case cps_provider_2_PartOk{v_8}:
      template_body_cps_provider_2_part_of(v_3, v_8)

def template_continuation_702(+v_1002719: cps_provider_2_Code, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_tuple_part{v_7, "a0", "r0"}}, False{}, v_1002723 => template_body_cps_provider_2_tuple_part(v_7, "a0", "r0"), v_1002722 => +v_1002720 = template_unbox(cps_provider_2_Part, v_1002722); template_body_cps_provider_2_tuple_and_code(v_1002720, v_1002719)}

def template_continuation_703(+v_1002717: String, +v_1002718: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_25 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002717}], v_1002718)
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_25, v_7, []}}, False{}, v_1002725 => template_body_cps_provider_2_run_jobs(v_25, v_7, []), v_1002724 => +v_1002719 = template_unbox(cps_provider_2_Code, v_1002724); template_continuation_702(v_1002719, v_7)}

def template_match_704(+v_5: Maybe<&2, cps_provider_2_Operand>, v_16: cps_provider_2_Operand, +v_13: Nat, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_get needs the array and the index"}}}
    case Some{v_18}:
      v_1002715 = {"Term a0 = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_16}}, False{}, v_1002731 => template_body_cps_provider_2_keep_text(v_16), v_1002730 => +v_1002716 = template_unbox(String, v_1002730); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002715, v_1002716, "; Term i0 = ", template_pure_cps_provider_2_operand_text(v_18), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_13), "); u32 c0 = 0; Term r0 = 0;"]}}, False{}, v_1002729 => template_body_cps_provider_2_join_text([v_1002715, v_1002716, "; Term i0 = ", template_pure_cps_provider_2_operand_text(v_18), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_13), "); u32 c0 = 0; Term r0 = 0;"]), v_1002728 => +v_1002717 = template_unbox(String, v_1002728); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_7, v_9, cps_provider_2_SrcBlock{"l0", "g0", v_11, True{}, "c0"}, "r0", "ag"}}, False{}, v_1002727 => template_body_cps_provider_2_unfill_jobs(v_7, v_9, cps_provider_2_SrcBlock{"l0", "g0", v_11, True{}, "c0"}, "r0", "ag"), v_1002726 => +v_1002718 = template_unbox(List<&2, cps_provider_2_Job>, v_1002726); template_continuation_703(v_1002717, v_1002718, v_7)}}}

def template_body_cps_provider_2_array_get_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_get needs the array and the index"}}}
    case Some{v_1004764}:
      template_match_704(v_5, v_1004764, v_13, v_7, v_9, v_11)

def template_body_cps_provider_2_old_read_cell(+v_1: Bool, +v_3: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  v_1002732 = {"old0[" : String}
  v_1002733 = {v_3 : String}
  v_1002734 = {"] = blk_read(e.mem, " : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_arr_flag{v_1}}, False{}, v_1002740 => template_body_cps_provider_2_arr_flag(v_1), v_1002739 => +v_1002735 = template_unbox(String, v_1002739); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002732, v_1002733, v_1002734, v_1002735, ", l0, g0 + ", v_3, "); ", v_3, " += 1;"]}}, False{}, v_1002738 => template_body_cps_provider_2_join_text([v_1002732, v_1002733, v_1002734, v_1002735, ", l0, g0 + ", v_3, "); ", v_3, " += 1;"]), v_1002737 => +v_1002736 = template_unbox(String, v_1002737); TemplateFinished{TemplateValue{[cps_provider_2_JText{v_1002736}]}}}}

def template_body_cps_provider_2_kinds_box_jobs(+v_2: List<&2, cps_provider_1_CWord>, +v_4: String, +v_6: Bool) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004765 <> +v_1004766:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_old_read_cell{v_6, v_4}}, False{}, v_1004767 => template_body_cps_provider_2_old_read_cell(v_6, v_4), v_1004768 => +v_1004769 = template_unbox(List<&2, cps_provider_2_Job>, v_1004768); TemplatePending{TemplateRequestGroup_5{TemplateRequest_cps_provider_2_kinds_box_jobs{v_1004766, v_4, v_6}}, v_1004770 => +v_1004771 = template_unbox(List<&2, cps_provider_2_Job>, v_1004770); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, v_1004769, v_1004771)}}}}

def template_match_707(+v_9: cps_provider_1_CWord, +v_4: String, +v_10: List<&2, cps_provider_1_CWord>) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_9:
    case cps_provider_1_CWordBox{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["term_sink(e, old0[", v_4, "]); ", v_4, " += 1;"]}}, False{}, v_1002750 => template_body_cps_provider_2_join_text(["term_sink(e, old0[", v_4, "]); ", v_4, " += 1;"]), v_1002749 => +v_1002746 = template_unbox(String, v_1002749); TemplatePending{TemplateRequestGroup_5{TemplateRequest_cps_provider_2_old_sink_jobs{v_10, v_4}}, v_1002748 => +v_1002747 = template_unbox(List<&2, cps_provider_2_Job>, v_1002748); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002746}], v_1002747)}}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_4, " += 1;"]}}, False{}, v_1002755 => template_body_cps_provider_2_join_text([v_4, " += 1;"]), v_1002754 => +v_1002751 = template_unbox(String, v_1002754); TemplatePending{TemplateRequestGroup_5{TemplateRequest_cps_provider_2_old_sink_jobs{v_10, v_4}}, v_1002753 => +v_1002752 = template_unbox(List<&2, cps_provider_2_Job>, v_1002753); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002751}], v_1002752)}}}}

def template_body_cps_provider_2_old_sink_jobs(+v_2: List<&2, cps_provider_1_CWord>, +v_4: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_9 <> +v_10:
      template_match_707(v_9, v_4, v_10)

def template_body_cps_provider_2_write_jobs(+v_1: Bool, +v_4: List<&2, cps_provider_1_CWord>, +v_6: String) -> TemplateProgress<List<&2, cps_provider_2_Job>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1004772 <> +v_1004773:
      v_1004774 = {"blk_write(e.mem, " : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_arr_flag{v_1}}, False{}, v_1004775 => template_body_cps_provider_2_arr_flag(v_1), v_1004776 => +v_1004777 = template_unbox(String, v_1004776); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1004774, v_1004777, ", l0, g0 + ", v_6, ", w0[", v_6, "]); ", v_6, " += 1;"]}}, False{}, v_1004778 => template_body_cps_provider_2_join_text([v_1004774, v_1004777, ", l0, g0 + ", v_6, ", w0[", v_6, "]); ", v_6, " += 1;"]), v_1004779 => +v_1004780 = template_unbox(String, v_1004779); TemplatePending{TemplateRequestGroup_5{TemplateRequest_cps_provider_2_write_jobs{v_1, v_1004773, v_6}}, v_1004781 => +v_1004782 = template_unbox(List<&2, cps_provider_2_Job>, v_1004781); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1004780}], v_1004782)}}}}}

def template_continuation_710(+v_1002773: String, v_1002774: List<&2, cps_provider_2_Job>, +v_1002775: String, +v_1002776: List<&2, cps_provider_2_Job>, v_29: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_42 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002773}], List.append(&2, cps_provider_2_Job, v_1002774, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002775}], List.append(&2, cps_provider_2_Job, v_1002776, v_29))))
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_42, v_7, []}}, False{}, v_1002782 => template_body_cps_provider_2_run_jobs(v_42, v_7, []), v_1002781 => +v_1002777 = template_unbox(cps_provider_2_Code, v_1002781); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_part_of{v_1002777, "a0"}}, False{}, v_1002780 => template_body_cps_provider_2_part_of(v_1002777, "a0"), v_1002779 => +v_1002778 = template_unbox(cps_provider_2_Part, v_1002779); TemplateFinished{TemplateValue{v_1002778}}}}

def template_continuation_711(v_22: List<&2, cps_provider_2_Job>, +v_13: Nat, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand, +v_1002773: String, v_29: List<&2, cps_provider_2_Job>) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_decl{v_13}}, False{}, v_1002786 => template_body_cps_provider_2_elem_decl(v_13), v_1002785 => +v_1002775 = template_unbox(String, v_1002785); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_fill{v_7, v_9, template_pure_cps_provider_2_operand_use(v_5), template_pure_cps_provider_2_operand_text(v_5), "as"}}, False{}, v_1002784 => template_body_cps_provider_2_elem_fill(v_7, v_9, template_pure_cps_provider_2_operand_use(v_5), template_pure_cps_provider_2_operand_text(v_5), "as"), v_1002783 => +v_1002776 = template_unbox(List<&2, cps_provider_2_Job>, v_1002783); template_continuation_710(v_1002773, {v_22 : List<&2, cps_provider_2_Job>}, v_1002775, v_1002776, v_29, v_7)}}

def template_continuation_712(v_1002767: List<&2, cps_provider_2_Job>, +v_1002768: List<&2, cps_provider_2_Job>, v_1002769: List<&2, cps_provider_2_Job>, +v_1002770: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, v_22: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  v_29 = List.append(&2, cps_provider_2_Job, v_1002767, List.append(&2, cps_provider_2_Job, v_1002768, List.append(&2, cps_provider_2_Job, v_1002769, v_1002770)))
  v_1002771 = {"Term a0 = " : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_1}}, False{}, v_1002790 => template_body_cps_provider_2_keep_text(v_1), v_1002789 => +v_1002772 = template_unbox(String, v_1002789); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002771, v_1002772, "; Term i0 = ", template_pure_cps_provider_2_operand_text(v_3), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_15), "); Term old0[", Nat.show(v_13), "]; u32 c0 = 0;"]}}, False{}, v_1002788 => template_body_cps_provider_2_join_text([v_1002771, v_1002772, "; Term i0 = ", template_pure_cps_provider_2_operand_text(v_3), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_15), "); Term old0[", Nat.show(v_13), "]; u32 c0 = 0;"]), v_1002787 => +v_1002773 = template_unbox(String, v_1002787); template_continuation_711(v_22, v_13, v_7, v_9, v_5, v_1002773, v_29)}}

def template_continuation_713(v_19: List<&2, cps_provider_1_CWord>, v_1002767: List<&2, cps_provider_2_Job>, +v_1002768: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, v_22: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  v_1002769 = {[cps_provider_2_JText{"c0 = 0;"}] : List<&2, cps_provider_2_Job>}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_old_sink_jobs{v_19, "c0"}}, False{}, v_1002792 => template_body_cps_provider_2_old_sink_jobs(v_19, "c0"), v_1002791 => +v_1002770 = template_unbox(List<&2, cps_provider_2_Job>, v_1002791); template_continuation_712(v_1002767, v_1002768, v_1002769, v_1002770, v_1, v_3, v_15, v_13, v_22, v_7, v_9, v_5)}

def template_continuation_714(+v_1002766: List<&2, cps_provider_2_Job>, +v_11: Bool, +v_19: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  v_1002767 = {[cps_provider_2_JText{"c0 = 0;"}] : List<&2, cps_provider_2_Job>}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_write_jobs{v_11, v_19, "c0"}}, False{}, v_1002794 => template_body_cps_provider_2_write_jobs(v_11, v_19, "c0"), v_1002793 => +v_1002768 = template_unbox(List<&2, cps_provider_2_Job>, v_1002793); template_continuation_713(v_19, v_1002767, v_1002768, v_1, v_3, v_15, v_13, v_1002766, v_7, v_9, v_5)}

def template_continuation_715(+v_1002765: List<&2, cps_provider_1_CWord>, +v_11: Bool, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_kinds_box_jobs{v_1002765, "c0", v_11}}, False{}, v_1002796 => template_body_cps_provider_2_kinds_box_jobs(v_1002765, "c0", v_11), v_1002795 => +v_1002766 = template_unbox(List<&2, cps_provider_2_Job>, v_1002795); template_continuation_714(v_1002766, v_11, v_1002765, v_1, v_3, v_15, v_13, v_7, v_9, v_5)}

def template_body_cps_provider_2_array_set_run(+v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_5: cps_provider_2_Operand, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_kinds{v_9}}, False{}, v_1002798 => template_body_cps_provider_1_layout_kinds(v_9), v_1002797 => +v_1002765 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002797); template_continuation_715(v_1002765, v_11, v_1, v_3, v_15, v_13, v_7, v_9, v_5)}

def template_match_716(+v_8: Maybe<&2, cps_provider_2_Operand>, v_21: cps_provider_2_Operand, v_23: cps_provider_2_Operand, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_8:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_set needs the array, the index and the value"}}}
    case Some{v_25}:
      template_body_cps_provider_2_array_set_run(v_21, v_23, v_25, v_10, v_12, v_14, v_16, v_18)

def template_match_717(+v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, v_21: cps_provider_2_Operand, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_set needs the array, the index and the value"}}}
    case Some{v_23}:
      template_match_716(v_8, v_21, v_23, v_10, v_12, v_14, v_16, v_18)

def template_body_cps_provider_2_array_set_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_set needs the array, the index and the value"}}}
    case Some{v_21}:
      template_match_717(v_5, v_8, v_21, v_10, v_12, v_14, v_16, v_18)

def template_continuation_719(+v_1002811: cps_provider_2_Code, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_tuple_part{v_7, "a0", "r0"}}, False{}, v_1002815 => template_body_cps_provider_2_tuple_part(v_7, "a0", "r0"), v_1002814 => +v_1002812 = template_unbox(cps_provider_2_Part, v_1002814); template_body_cps_provider_2_tuple_and_code(v_1002812, v_1002811)}

def template_continuation_720(+v_1002807: String, v_1002808: List<&2, cps_provider_2_Job>, +v_1002809: String, +v_1002810: List<&2, cps_provider_2_Job>, v_31: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_44 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002807}], List.append(&2, cps_provider_2_Job, v_1002808, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002809}], List.append(&2, cps_provider_2_Job, v_1002810, v_31))))
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_44, v_7, []}}, False{}, v_1002817 => template_body_cps_provider_2_run_jobs(v_44, v_7, []), v_1002816 => +v_1002811 = template_unbox(cps_provider_2_Code, v_1002816); template_continuation_719(v_1002811, v_7)}

def template_continuation_721(v_22: List<&2, cps_provider_2_Job>, +v_13: Nat, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand, +v_1002807: String, v_31: List<&2, cps_provider_2_Job>) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_decl{v_13}}, False{}, v_1002821 => template_body_cps_provider_2_elem_decl(v_13), v_1002820 => +v_1002809 = template_unbox(String, v_1002820); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_fill{v_7, v_9, template_pure_cps_provider_2_operand_use(v_5), template_pure_cps_provider_2_operand_text(v_5), "aw"}}, False{}, v_1002819 => template_body_cps_provider_2_elem_fill(v_7, v_9, template_pure_cps_provider_2_operand_use(v_5), template_pure_cps_provider_2_operand_text(v_5), "aw"), v_1002818 => +v_1002810 = template_unbox(List<&2, cps_provider_2_Job>, v_1002818); template_continuation_720(v_1002807, {v_22 : List<&2, cps_provider_2_Job>}, v_1002809, v_1002810, v_31, v_7)}}

def template_continuation_722(v_1002803: List<&2, cps_provider_2_Job>, +v_1002804: List<&2, cps_provider_2_Job>, v_25: List<&2, cps_provider_2_Job>, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, v_22: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  v_31 = List.append(&2, cps_provider_2_Job, v_1002803, List.append(&2, cps_provider_2_Job, v_1002804, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{"u32 oc0 = 0;"}], v_25)))
  v_1002805 = {"Term a0 = " : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_1}}, False{}, v_1002825 => template_body_cps_provider_2_keep_text(v_1), v_1002824 => +v_1002806 = template_unbox(String, v_1002824); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002805, v_1002806, "; Term i0 = ", template_pure_cps_provider_2_operand_text(v_3), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_15), "); Term old0[", Nat.show(v_13), "]; u32 c0 = 0; Term r0 = 0;"]}}, False{}, v_1002823 => template_body_cps_provider_2_join_text([v_1002805, v_1002806, "; Term i0 = ", template_pure_cps_provider_2_operand_text(v_3), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_15), "); Term old0[", Nat.show(v_13), "]; u32 c0 = 0; Term r0 = 0;"]), v_1002822 => +v_1002807 = template_unbox(String, v_1002822); template_continuation_721(v_22, v_13, v_7, v_9, v_5, v_1002807, v_31)}}

def template_continuation_723(+v_1002802: List<&2, cps_provider_2_Job>, +v_11: Bool, v_19: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, v_22: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  v_1002803 = {[cps_provider_2_JText{"c0 = 0;"}] : List<&2, cps_provider_2_Job>}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_write_jobs{v_11, v_19, "c0"}}, False{}, v_1002827 => template_body_cps_provider_2_write_jobs(v_11, v_19, "c0"), v_1002826 => +v_1002804 = template_unbox(List<&2, cps_provider_2_Job>, v_1002826); template_continuation_722(v_1002803, v_1002804, v_1002802, v_1, v_3, v_15, v_13, v_22, v_7, v_9, v_5)}

def template_continuation_724(+v_1002801: List<&2, cps_provider_2_Job>, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, v_19: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_unfill_jobs{v_7, v_9, cps_provider_2_SrcBuf{"old0", "oc0"}, "r0", "awold"}}, False{}, v_1002829 => template_body_cps_provider_2_unfill_jobs(v_7, v_9, cps_provider_2_SrcBuf{"old0", "oc0"}, "r0", "awold"), v_1002828 => +v_1002802 = template_unbox(List<&2, cps_provider_2_Job>, v_1002828); template_continuation_723(v_1002802, v_11, v_19, v_1, v_3, v_15, v_13, v_1002801, v_7, v_9, v_5)}

def template_continuation_725(+v_1002800: List<&2, cps_provider_1_CWord>, +v_11: Bool, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_15: Nat, +v_13: Nat, +v_5: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_kinds_box_jobs{v_1002800, "c0", v_11}}, False{}, v_1002831 => template_body_cps_provider_2_kinds_box_jobs(v_1002800, "c0", v_11), v_1002830 => +v_1002801 = template_unbox(List<&2, cps_provider_2_Job>, v_1002830); template_continuation_724(v_1002801, v_7, v_9, v_11, v_1002800, v_1, v_3, v_15, v_13, v_5)}

def template_body_cps_provider_2_array_swap_run(+v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_5: cps_provider_2_Operand, +v_7: cps_provider_2_World, +v_9: cps_provider_1_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_kinds{v_9}}, False{}, v_1002833 => template_body_cps_provider_1_layout_kinds(v_9), v_1002832 => +v_1002800 = template_unbox(List<&2, cps_provider_1_CWord>, v_1002832); template_continuation_725(v_1002800, v_11, v_7, v_9, v_1, v_3, v_15, v_13, v_5)}

def template_match_726(+v_8: Maybe<&2, cps_provider_2_Operand>, v_21: cps_provider_2_Operand, v_23: cps_provider_2_Operand, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_8:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_swap needs the array, the index and the value"}}}
    case Some{v_25}:
      template_body_cps_provider_2_array_swap_run(v_21, v_23, v_25, v_10, v_12, v_14, v_16, v_18)

def template_match_727(+v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, v_21: cps_provider_2_Operand, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_swap needs the array, the index and the value"}}}
    case Some{v_23}:
      template_match_726(v_8, v_21, v_23, v_10, v_12, v_14, v_16, v_18)

def template_body_cps_provider_2_array_swap_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, +v_10: cps_provider_2_World, +v_12: cps_provider_1_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_swap needs the array, the index and the value"}}}
    case Some{v_21}:
      template_match_727(v_5, v_8, v_21, v_10, v_12, v_14, v_16, v_18)

def template_continuation_729(+v_1002839: cps_provider_2_Code, +v_4: cps_provider_2_World, +v_6: Nat) -> TemplateProgress<cps_provider_2_Part>:
  +v_1002840 = {v_4 : cps_provider_2_World}
  +v_1002841 = {"a0" : String}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["(1ull << (blk_cls(a0) - ", Nat.show(v_6), "))"]}}, False{}, v_1002848 => template_body_cps_provider_2_join_text(["(1ull << (blk_cls(a0) - ", Nat.show(v_6), "))"]), v_1002847 => +v_1002842 = template_unbox(String, v_1002847); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_tuple_part{v_1002840, v_1002841, v_1002842}}, False{}, v_1002846 => template_body_cps_provider_2_tuple_part(v_1002840, v_1002841, v_1002842), v_1002845 => +v_1002843 = template_unbox(cps_provider_2_Part, v_1002845); template_body_cps_provider_2_tuple_and_code(v_1002843, v_1002839)}}

def template_body_cps_provider_2_array_size_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World, +v_6: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case Some{v_9}:
      v_1002835 = {"Term a0 = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_9}}, False{}, v_1002856 => template_body_cps_provider_2_keep_text(v_9), v_1002855 => +v_1002836 = template_unbox(String, v_1002855); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002835, v_1002836, ";"]}}, False{}, v_1002854 => template_body_cps_provider_2_join_text([v_1002835, v_1002836, ";"]), v_1002853 => +v_1002837 = template_unbox(String, v_1002853); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1002837}}}, False{}, v_1002852 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1002837}), v_1002851 => +v_1002838 = template_unbox(List<&2, cps_provider_2_Job>, v_1002851); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_1002838, v_4, []}}, False{}, v_1002850 => template_body_cps_provider_2_run_jobs(v_1002838, v_4, []), v_1002849 => +v_1002839 = template_unbox(cps_provider_2_Code, v_1002849); template_continuation_729(v_1002839, v_4, v_6)}}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_size needs the array"}}}

def template_continuation_731(+v_1002861: cps_provider_2_Code, +v_4: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_tuple_part{v_4, "a0", "blk_copy(e, a0)"}}, False{}, v_1002865 => template_body_cps_provider_2_tuple_part(v_4, "a0", "blk_copy(e, a0)"), v_1002864 => +v_1002862 = template_unbox(cps_provider_2_Part, v_1002864); template_body_cps_provider_2_tuple_and_code(v_1002862, v_1002861)}

def template_body_cps_provider_2_array_clone_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case Some{v_7}:
      v_1002857 = {"Term a0 = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_7}}, False{}, v_1002873 => template_body_cps_provider_2_keep_text(v_7), v_1002872 => +v_1002858 = template_unbox(String, v_1002872); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002857, v_1002858, ";"]}}, False{}, v_1002871 => template_body_cps_provider_2_join_text([v_1002857, v_1002858, ";"]), v_1002870 => +v_1002859 = template_unbox(String, v_1002870); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1002859}}}, False{}, v_1002869 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1002859}), v_1002868 => +v_1002860 = template_unbox(List<&2, cps_provider_2_Job>, v_1002868); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_1002860, v_4, []}}, False{}, v_1002867 => template_body_cps_provider_2_run_jobs(v_1002860, v_4, []), v_1002866 => +v_1002861 = template_unbox(cps_provider_2_Code, v_1002866); template_continuation_731(v_1002861, v_4)}}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_clone needs the array"}}}

def template_body_cps_provider_2_atomic_cell_text(+v_1: String, +v_3: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["blk_ptr(e.mem, blk_loc(e.mem, ", v_1, "), blk_at(", v_1, ", (u64)(u32)(", v_3, "), 0))"]}}, False{}, v_1002876 => template_body_cps_provider_2_join_text(["blk_ptr(e.mem, blk_loc(e.mem, ", v_1, "), blk_at(", v_1, ", (u64)(u32)(", v_3, "), 0))"]), v_1002875 => +v_1002874 = template_unbox(String, v_1002875); TemplateFinished{TemplateValue{v_1002874}}}

def template_body_cps_provider_2_atomic_call_text(+v_1: String, +v_3: String, +v_5: String, +v_7: String) -> TemplateProgress<String>:
  v_1002877 = {"(u64)" : String}
  v_1002878 = {v_7 : String}
  v_1002879 = {"(" : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_cell_text{v_1, v_3}}, False{}, v_1002885 => template_body_cps_provider_2_atomic_cell_text(v_1, v_3), v_1002884 => +v_1002880 = template_unbox(String, v_1002884); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002877, v_1002878, v_1002879, v_1002880, ", (u32)(", v_5, "))"]}}, False{}, v_1002883 => template_body_cps_provider_2_join_text([v_1002877, v_1002878, v_1002879, v_1002880, ", (u32)(", v_5, "))"]), v_1002882 => +v_1002881 = template_unbox(String, v_1002882); TemplateFinished{TemplateValue{v_1002881}}}}

def template_body_cps_provider_2_atomic_cas_text(+v_1: String, +v_3: String, +v_5: String, +v_7: String) -> TemplateProgress<String>:
  v_1002886 = {"(u64)a32_cmpx(" : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_cell_text{v_1, v_3}}, False{}, v_1002892 => template_body_cps_provider_2_atomic_cell_text(v_1, v_3), v_1002891 => +v_1002887 = template_unbox(String, v_1002891); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002886, v_1002887, ", (u32)(", v_5, "), (u32)(", v_7, "))"]}}, False{}, v_1002890 => template_body_cps_provider_2_join_text([v_1002886, v_1002887, ", (u32)(", v_5, "), (u32)(", v_7, "))"]), v_1002889 => +v_1002888 = template_unbox(String, v_1002889); TemplateFinished{TemplateValue{v_1002888}}}}

def template_body_cps_provider_2_atomic_helper(+v_0: BIR.Primitive) -> TemplateProgress<cps_provider_2_Part>:
  match v_0:
    case BIR.PrimArrayAtomicAdd{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_add"}}}
    case BIR.PrimArrayAtomicMin{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_min"}}}
    case BIR.PrimArrayAtomicMax{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_max"}}}
    case BIR.PrimArrayAtomicAnd{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_and"}}}
    case BIR.PrimArrayAtomicOr{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_or"}}}
    case BIR.PrimArrayAtomicXor{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_xor"}}}
    case BIR.PrimArrayAtomicExch{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_exch"}}}
    case BIR.PrimArrayAtomicFadd{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{"a32_fadd"}}}
    case _:
      v_1002893 = {"the primitive `" : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_label{v_0}}, False{}, v_1002899 => template_body_cps_provider_2_array_label(v_0), v_1002898 => +v_1002894 = template_unbox(String, v_1002898); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002893, v_1002894, "` has no a32 read-modify-write helper"]}}, False{}, v_1002897 => template_body_cps_provider_2_join_text([v_1002893, v_1002894, "` has no a32 read-modify-write helper"]), v_1002896 => +v_1002895 = template_unbox(String, v_1002896); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1002895}}}}}

def template_body_cps_provider_2_atomic_pair(+v_1: String, +v_3: String, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"Tuple", v_5}}, False{}, v_1002903 => template_body_cps_provider_2_cid_text("Tuple", v_5), v_1002902 => +v_1002900 = template_unbox(Maybe<&2, String>, v_1002902); template_body_cps_provider_2_tuple_cid(v_1002900, v_3, v_1)}

def template_continuation_734(+v_1002909: cps_provider_2_Code, +v_4: cps_provider_2_Operand, +v_6: cps_provider_2_Operand, v_14: String, +v_8: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_call_text{"a0", template_pure_cps_provider_2_operand_text(v_4), template_pure_cps_provider_2_operand_text(v_6), v_14}}, False{}, v_1002916 => template_body_cps_provider_2_atomic_call_text("a0", template_pure_cps_provider_2_operand_text(v_4), template_pure_cps_provider_2_operand_text(v_6), v_14), v_1002915 => +v_1002910 = template_unbox(String, v_1002915); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_pair{v_1002910, "a0", v_8}}, False{}, v_1002914 => template_body_cps_provider_2_atomic_pair(v_1002910, "a0", v_8), v_1002913 => +v_1002911 = template_unbox(cps_provider_2_Part, v_1002913); template_body_cps_provider_2_tuple_and_code(v_1002911, v_1002909)}}

def template_match_735(+v_1002904: cps_provider_2_Part, +v_2: cps_provider_2_Operand, +v_8: cps_provider_2_World, +v_4: cps_provider_2_Operand, +v_6: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002904:
    case cps_provider_2_PartFail{v_12}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_12}}}
    case cps_provider_2_PartOk{v_14}:
      v_1002905 = {"Term a0 = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_2}}, False{}, v_1002924 => template_body_cps_provider_2_keep_text(v_2), v_1002923 => +v_1002906 = template_unbox(String, v_1002923); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002905, v_1002906, ";"]}}, False{}, v_1002922 => template_body_cps_provider_2_join_text([v_1002905, v_1002906, ";"]), v_1002921 => +v_1002907 = template_unbox(String, v_1002921); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1002907}}}, False{}, v_1002920 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1002907}), v_1002919 => +v_1002908 = template_unbox(List<&2, cps_provider_2_Job>, v_1002919); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_1002908, v_8, []}}, False{}, v_1002918 => template_body_cps_provider_2_run_jobs(v_1002908, v_8, []), v_1002917 => +v_1002909 = template_unbox(cps_provider_2_Code, v_1002917); template_continuation_734(v_1002909, v_4, v_6, v_14, v_8)}}}}

def template_body_cps_provider_2_atomic_three_operands(+v_0: BIR.Primitive, +v_2: cps_provider_2_Operand, +v_4: cps_provider_2_Operand, +v_6: cps_provider_2_Operand, +v_8: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_helper{v_0}}, False{}, v_1002926 => template_body_cps_provider_2_atomic_helper(v_0), v_1002925 => +v_1002904 = template_unbox(cps_provider_2_Part, v_1002925); template_match_735(v_1002904, v_2, v_8, v_4, v_6)}

def template_body_cps_provider_2_atomic_three_pargs(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case [v_1004783, v_1004784, v_1004785]:
      template_body_cps_provider_2_atomic_three_operands(v_0, v_1004783, v_1004784, v_1004785, v_5)
    case v_1004786:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_label{v_0}}, False{}, v_1004787 => template_body_cps_provider_2_array_label(v_0), v_1004788 => +v_1004789 = template_unbox(String, v_1004788); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1004789, " takes the array, the index and the value"]}}, False{}, v_1004790 => template_body_cps_provider_2_join_text([v_1004789, " takes the array, the index and the value"]), v_1004791 => +v_1004792 = template_unbox(String, v_1004791); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004792}}}}}

def template_continuation_737(+v_1002938: cps_provider_2_Code, v_11: cps_provider_2_Operand, v_12: cps_provider_2_Operand, v_13: cps_provider_2_Operand, +v_4: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_cas_text{"a0", template_pure_cps_provider_2_operand_text(v_11), template_pure_cps_provider_2_operand_text(v_12), template_pure_cps_provider_2_operand_text(v_13)}}, False{}, v_1002945 => template_body_cps_provider_2_atomic_cas_text("a0", template_pure_cps_provider_2_operand_text(v_11), template_pure_cps_provider_2_operand_text(v_12), template_pure_cps_provider_2_operand_text(v_13)), v_1002944 => +v_1002939 = template_unbox(String, v_1002944); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_pair{v_1002939, "a0", v_4}}, False{}, v_1002943 => template_body_cps_provider_2_atomic_pair(v_1002939, "a0", v_4), v_1002942 => +v_1002940 = template_unbox(cps_provider_2_Part, v_1002942); template_body_cps_provider_2_tuple_and_code(v_1002940, v_1002938)}}

def template_body_cps_provider_2_atomic_cas_pargs(+v_2: List<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case [v_10, v_11, v_12, v_13]:
      v_1002934 = {"Term a0 = " : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_10}}, False{}, v_1002953 => template_body_cps_provider_2_keep_text(v_10), v_1002952 => +v_1002935 = template_unbox(String, v_1002952); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002934, v_1002935, ";"]}}, False{}, v_1002951 => template_body_cps_provider_2_join_text([v_1002934, v_1002935, ";"]), v_1002950 => +v_1002936 = template_unbox(String, v_1002950); TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_one_job{cps_provider_2_JText{v_1002936}}}, False{}, v_1002949 => template_body_cps_provider_2_one_job(cps_provider_2_JText{v_1002936}), v_1002948 => +v_1002937 = template_unbox(List<&2, cps_provider_2_Job>, v_1002948); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_run_jobs{v_1002937, v_4, []}}, False{}, v_1002947 => template_body_cps_provider_2_run_jobs(v_1002937, v_4, []), v_1002946 => +v_1002938 = template_unbox(cps_provider_2_Code, v_1002946); template_continuation_737(v_1002938, v_11, v_12, v_13, v_4)}}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_atomic_cas takes the array, the index, the expected word and the replacement"}}}

def template_body_cps_provider_2_atomic_pargs(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_0:
    case BIR.PrimArrayAtomicCas{}:
      template_body_cps_provider_2_atomic_cas_pargs(v_3, v_5)
    case _:
      template_body_cps_provider_2_atomic_three_pargs(v_0, v_3, v_5)

def template_match_740(+v_1002956: cps_provider_2_Part, +v_10: String, v_11: String, v_12: String, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1002956:
    case cps_provider_2_PartFail{v_15}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_15}}}
    case cps_provider_2_PartOk{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_call_text{v_10, v_11, v_12, v_17}}, False{}, v_1002960 => template_body_cps_provider_2_atomic_call_text(v_10, v_11, v_12, v_17), v_1002959 => +v_1002957 = template_unbox(String, v_1002959); template_body_cps_provider_2_atomic_pair(v_1002957, v_10, v_5)}

def template_body_cps_provider_2_atomic_three_regs(+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_3:
    case [v_1004793, v_1004794, v_1004795]:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_helper{v_0}}, False{}, v_1004796 => template_body_cps_provider_2_atomic_helper(v_0), v_1004797 => +v_1004798 = template_unbox(cps_provider_2_Part, v_1004797); template_match_740(v_1004798, v_1004793, v_1004794, v_1004795, v_5)}
    case v_1004799:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_label{v_0}}, False{}, v_1004800 => template_body_cps_provider_2_array_label(v_0), v_1004801 => +v_1004802 = template_unbox(String, v_1004801); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1004802, " takes the array, the index and the value"]}}, False{}, v_1004803 => template_body_cps_provider_2_join_text([v_1004802, " takes the array, the index and the value"]), v_1004804 => +v_1004805 = template_unbox(String, v_1004804); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1004805}}}}}

def template_body_cps_provider_2_atomic_cas_regs(+v_2: List<&2, String>, +v_4: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case [+v_10, v_11, v_12, v_13]:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_atomic_cas_text{v_10, v_11, v_12, v_13}}, False{}, v_1002972 => template_body_cps_provider_2_atomic_cas_text(v_10, v_11, v_12, v_13), v_1002971 => +v_1002969 = template_unbox(String, v_1002971); template_body_cps_provider_2_atomic_pair(v_1002969, v_10, v_4)}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_atomic_cas takes the array, the index, the expected word and the replacement"}}}

def template_body_cps_provider_2_atomic_prim_part(+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_0:
    case BIR.PrimArrayAtomicCas{}:
      template_body_cps_provider_2_atomic_cas_regs(v_3, v_5)
    case _:
      template_body_cps_provider_2_atomic_three_regs(v_0, v_3, v_5)

def template_continuation_744(+v_1002975: String, +v_1002976: List<&2, cps_provider_2_Job>, +v_1002977: String, +v_4: cps_provider_2_World, +v_8: Bool, +v_12: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_2_Part>:
  v_24 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_1002975}], List.append(&2, cps_provider_2_Job, v_1002976, [cps_provider_2_JText{v_1002977}]))
  v_1002980 = {"blk_new(e, " : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_arr_flag{v_8}}, False{}, v_1002987 => template_body_cps_provider_2_arr_flag(v_8), v_1002986 => +v_1002981 = template_unbox(String, v_1002986); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002980, v_1002981, ", 0, ", Nat.show(v_12), ", ", Nat.show(v_10), ", f0)"]}}, False{}, v_1002985 => template_body_cps_provider_2_join_text([v_1002980, v_1002981, ", 0, ", Nat.show(v_12), ", ", Nat.show(v_10), ", f0)"]), v_1002984 => +v_1002982 = template_unbox(String, v_1002984); template_body_cps_provider_2_run_part({v_24 : List<&2, cps_provider_2_Job>}, {v_4 : cps_provider_2_World}, v_1002982)}}

def template_body_cps_provider_2_array_leaf_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World, +v_6: cps_provider_1_Layout, +v_8: Bool, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case Some{+v_1004806}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_decl{v_10}}, False{}, v_1004807 => template_body_cps_provider_2_elem_decl(v_10), v_1004808 => +v_1004809 = template_unbox(String, v_1004808); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_fill{v_4, v_6, template_pure_cps_provider_2_operand_use(v_1004806), template_pure_cps_provider_2_operand_text(v_1004806), "al"}}, False{}, v_1004810 => template_body_cps_provider_2_elem_fill(v_4, v_6, template_pure_cps_provider_2_operand_use(v_1004806), template_pure_cps_provider_2_operand_text(v_1004806), "al"), v_1004811 => +v_1004812 = template_unbox(List<&2, cps_provider_2_Job>, v_1004811); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_elem_stores{v_10}}, False{}, v_1004813 => template_body_cps_provider_2_elem_stores(v_10), v_1004814 => +v_1004815 = template_unbox(String, v_1004814); template_continuation_744(v_1004809, v_1004812, v_1004815, v_4, v_8, v_12, v_10)}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_leaf needs the element value"}}}

def template_continuation_746(v_10: cps_provider_2_Operand, v_1002994: String, +v_1002995: String) -> TemplateProgress<cps_provider_2_Part>:
  v_1002996 = {", " : String}
  TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_10}}, False{}, v_1003002 => template_body_cps_provider_2_keep_text(v_10), v_1003001 => +v_1002997 = template_unbox(String, v_1003001); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1002994, v_1002995, v_1002996, v_1002997, ")"]}}, False{}, v_1003000 => template_body_cps_provider_2_join_text([v_1002994, v_1002995, v_1002996, v_1002997, ")"]), v_1002999 => +v_1002998 = template_unbox(String, v_1002999); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1002998}}}}}

def template_match_747(+v_5: Maybe<&2, cps_provider_2_Operand>, v_8: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_node needs the two halves"}}}
    case Some{v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_keep_text{v_8}}, False{}, v_1003004 => template_body_cps_provider_2_keep_text(v_8), v_1003003 => +v_1002995 = template_unbox(String, v_1003003); template_continuation_746(v_10, {"blk_node(e, " : String}, v_1002995)}

def template_body_cps_provider_2_array_node_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"array_node needs the two halves"}}}
    case Some{v_8}:
      template_match_747(v_5, v_8)

def template_body_cps_provider_2_array_is_cond(+v_1: Nat, +v_3: cps_provider_2_Operand) -> TemplateProgress<String>:
  match v_1:
    case 0n:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u32)blk_cls(", template_pure_cps_provider_2_operand_text(v_3), ") == 0)"]}}, False{}, v_1003007 => template_body_cps_provider_2_join_text(["((u32)blk_cls(", template_pure_cps_provider_2_operand_text(v_3), ") == 0)"]), v_1003006 => +v_1003005 = template_unbox(String, v_1003006); TemplateFinished{TemplateValue{v_1003005}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["((u32)blk_cls(", template_pure_cps_provider_2_operand_text(v_3), ") != 0)"]}}, False{}, v_1003010 => template_body_cps_provider_2_join_text(["((u32)blk_cls(", template_pure_cps_provider_2_operand_text(v_3), ") != 0)"]), v_1003009 => +v_1003008 = template_unbox(String, v_1003009); TemplateFinished{TemplateValue{v_1003008}}}

def template_match_750(+v_5: Maybe<&2, String>, v_12: String, +v_7: Nat, +v_9: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the C runtime contract needs the `False` constructor for an array tag test"}}}
    case Some{v_14}:
      v_1003011 = {"bend_bool(e, " : String}
      v_1003012 = {v_12 : String}
      v_1003013 = {", " : String}
      v_1003014 = {v_14 : String}
      v_1003015 = {", (u64)" : String}
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_is_cond{v_7, v_9}}, False{}, v_1003021 => template_body_cps_provider_2_array_is_cond(v_7, v_9), v_1003020 => +v_1003016 = template_unbox(String, v_1003020); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003011, v_1003012, v_1003013, v_1003014, v_1003015, v_1003016, ")"]}}, False{}, v_1003019 => template_body_cps_provider_2_join_text([v_1003011, v_1003012, v_1003013, v_1003014, v_1003015, v_1003016, ")"]), v_1003018 => +v_1003017 = template_unbox(String, v_1003018); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1003017}}}}}

def template_body_cps_provider_2_array_is_bools(+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: Nat, +v_9: cps_provider_2_Operand) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the C runtime contract needs the `True` constructor for an array tag test"}}}
    case Some{v_12}:
      template_match_750(v_5, v_12, v_7, v_9)

def template_body_cps_provider_2_array_is_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: Nat, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case Some{v_1004816}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"True", v_6}}, False{}, v_1004817 => template_body_cps_provider_2_cid_text("True", v_6), v_1004818 => +v_1004819 = template_unbox(Maybe<&2, String>, v_1004818); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_text{"False", v_6}}, False{}, v_1004820 => template_body_cps_provider_2_cid_text("False", v_6), v_1004821 => +v_1004822 = template_unbox(Maybe<&2, String>, v_1004821); template_body_cps_provider_2_array_is_bools(v_1004819, v_1004822, v_4, v_1004816)}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"an array tag test needs the array"}}}

def template_body_cps_provider_2_array_new_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 0n}}, False{}, v_1003035 => template_body_cps_provider_2_operand_at(v_4, 0n), v_1003034 => +v_1003029 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003034); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 1n}}, False{}, v_1003033 => template_body_cps_provider_2_operand_at(v_4, 1n), v_1003032 => +v_1003030 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003032); template_body_cps_provider_2_array_new_ops(v_1003029, v_1003030, v_6, v_14, v_15, v_16, v_17)}}

def template_body_cps_provider_2_array_get_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 0n}}, False{}, v_1003042 => template_body_cps_provider_2_operand_at(v_4, 0n), v_1003041 => +v_1003036 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003041); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 1n}}, False{}, v_1003040 => template_body_cps_provider_2_operand_at(v_4, 1n), v_1003039 => +v_1003037 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003039); template_body_cps_provider_2_array_get_ops(v_1003036, v_1003037, v_6, v_14, v_15, v_17)}}

def template_body_cps_provider_2_array_set_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 0n}}, False{}, v_1003052 => template_body_cps_provider_2_operand_at(v_4, 0n), v_1003051 => +v_1003043 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003051); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 1n}}, False{}, v_1003050 => template_body_cps_provider_2_operand_at(v_4, 1n), v_1003049 => +v_1003044 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003049); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 2n}}, False{}, v_1003048 => template_body_cps_provider_2_operand_at(v_4, 2n), v_1003047 => +v_1003045 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003047); template_body_cps_provider_2_array_set_ops(v_1003043, v_1003044, v_1003045, v_6, v_14, v_15, v_16, v_17)}}}

def template_body_cps_provider_2_array_swap_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 0n}}, False{}, v_1003062 => template_body_cps_provider_2_operand_at(v_4, 0n), v_1003061 => +v_1003053 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003061); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 1n}}, False{}, v_1003060 => template_body_cps_provider_2_operand_at(v_4, 1n), v_1003059 => +v_1003054 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003059); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 2n}}, False{}, v_1003058 => template_body_cps_provider_2_operand_at(v_4, 2n), v_1003057 => +v_1003055 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003057); template_body_cps_provider_2_array_swap_ops(v_1003053, v_1003054, v_1003055, v_6, v_14, v_15, v_16, v_17)}}}

def template_body_cps_provider_2_array_size_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 0n}}, False{}, v_1003066 => template_body_cps_provider_2_operand_at(v_4, 0n), v_1003065 => +v_1003063 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003065); template_body_cps_provider_2_array_size_ops(v_1003063, v_6, v_17)}

def template_body_cps_provider_2_array_clone_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 0n}}, False{}, v_1003070 => template_body_cps_provider_2_operand_at(v_4, 0n), v_1003069 => +v_1003067 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003069); template_body_cps_provider_2_array_clone_ops(v_1003067, v_6)}

def template_body_cps_provider_2_array_leaf_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_4, 0n}}, False{}, v_1003074 => template_body_cps_provider_2_operand_at(v_4, 0n), v_1003073 => +v_1003071 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1003073); template_body_cps_provider_2_array_leaf_ops(v_1003071, v_6, v_14, v_15, v_16, v_17)}

def template_match_760(v_1003075: Bool, +v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_7: cps_provider_2_World, +v_5: List<&2, BIR.Descriptor>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003075:
    case True{}:
      template_body_cps_provider_2_atomic_pargs(v_0, v_3, v_7)
    case False{}:
      TemplatePending{TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell_part{v_0, v_3, v_5, v_7}}, v_1003078 => +v_1003077 = template_unbox(cps_provider_2_Part, v_1003078); TemplateFinished{TemplateValue{v_1003077}}}

def template_body_cps_provider_2_array_part(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  v_1003075 = {template_pure_cps_provider_2_is_atomic_primitive(v_0) : Bool}
  template_match_760(v_1003075, v_0, v_3, v_7, v_5)

def template_body_cps_provider_2_array_cell_part(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_0:
    case BIR.PrimArrayNew{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell{v_7, v_5, v_0}}, False{}, v_1004823 => template_body_cps_provider_2_array_cell(v_7, v_5, v_0), v_1004824 => +v_1004825 = template_unbox(cps_provider_2_CellOut, v_1004824); template_body_cps_provider_2_array_new_cell(v_1004825, v_3, v_7)}
    case BIR.PrimArrayGet{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell{v_7, v_5, v_0}}, False{}, v_1004826 => template_body_cps_provider_2_array_cell(v_7, v_5, v_0), v_1004827 => +v_1004828 = template_unbox(cps_provider_2_CellOut, v_1004827); template_body_cps_provider_2_array_get_cell(v_1004828, v_3, v_7)}
    case BIR.PrimArraySet{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell{v_7, v_5, v_0}}, False{}, v_1004829 => template_body_cps_provider_2_array_cell(v_7, v_5, v_0), v_1004830 => +v_1004831 = template_unbox(cps_provider_2_CellOut, v_1004830); template_body_cps_provider_2_array_set_cell(v_1004831, v_3, v_7)}
    case BIR.PrimArraySwap{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell{v_7, v_5, v_0}}, False{}, v_1004832 => template_body_cps_provider_2_array_cell(v_7, v_5, v_0), v_1004833 => +v_1004834 = template_unbox(cps_provider_2_CellOut, v_1004833); template_body_cps_provider_2_array_swap_cell(v_1004834, v_3, v_7)}
    case BIR.PrimArraySize{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell{v_7, v_5, v_0}}, False{}, v_1004835 => template_body_cps_provider_2_array_cell(v_7, v_5, v_0), v_1004836 => +v_1004837 = template_unbox(cps_provider_2_CellOut, v_1004836); template_body_cps_provider_2_array_size_cell(v_1004837, v_3, v_7)}
    case BIR.PrimArrayClone{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell{v_7, v_5, v_0}}, False{}, v_1004838 => template_body_cps_provider_2_array_cell(v_7, v_5, v_0), v_1004839 => +v_1004840 = template_unbox(cps_provider_2_CellOut, v_1004839); template_body_cps_provider_2_array_clone_cell(v_1004840, v_3, v_7)}
    case BIR.PrimArrayLeaf{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_cell{v_7, v_5, v_0}}, False{}, v_1004841 => template_body_cps_provider_2_array_cell(v_7, v_5, v_0), v_1004842 => +v_1004843 = template_unbox(cps_provider_2_CellOut, v_1004842); template_body_cps_provider_2_array_leaf_cell(v_1004843, v_3, v_7)}
    case BIR.PrimArrayNode{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_3, 0n}}, False{}, v_1004844 => template_body_cps_provider_2_operand_at(v_3, 0n), v_1004845 => +v_1004846 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1004845); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_3, 1n}}, False{}, v_1004847 => template_body_cps_provider_2_operand_at(v_3, 1n), v_1004848 => +v_1004849 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1004848); template_body_cps_provider_2_array_node_ops(v_1004846, v_1004849)}}
    case BIR.PrimIsArrayLeaf{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_3, 0n}}, False{}, v_1004850 => template_body_cps_provider_2_operand_at(v_3, 0n), v_1004851 => +v_1004852 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1004851); template_body_cps_provider_2_array_is_ops(v_1004852, 0n, v_7)}
    case BIR.PrimIsArrayNode{}:
      TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_operand_at{v_3, 0n}}, False{}, v_1004853 => template_body_cps_provider_2_operand_at(v_3, 0n), v_1004854 => +v_1004855 = template_unbox(Maybe<&2, cps_provider_2_Operand>, v_1004854); TemplateDirect{Bool, TemplateRequestGroup_5{TemplateRequest_cps_provider_2_array_is_ops{v_1004855, 1n, v_7}}, False{}, v_1004856 => template_body_cps_provider_2_array_is_ops(v_1004855, 1n, v_7), v_1004857 => +v_1004858 = template_unbox(cps_provider_2_Part, v_1004857); TemplateFinished{TemplateValue{v_1004858}}}}
    case v_1004859:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"this primitive is not an array operation"}}}

def template_body_cps_provider_2_is_atomic_primitive(+v_0: BIR.Primitive) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_is_atomic_primitive(v_0)}}

def template_body_cps_provider_2_is_array_primitive(+v_0: BIR.Primitive) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_is_array_primitive(v_0)}}

def template_match_762(v_1003125: Bool, +v_3: String, +v_1: Nat, v_22: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003125:
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the map node `", v_3, "` does not declare exactly ", Nat.show(v_1), " live fields, so Base's Map.find cannot read it"]}}, False{}, v_1003128 => template_body_cps_provider_2_join_text(["the map node `", v_3, "` does not declare exactly ", Nat.show(v_1), " live fields, so Base's Map.find cannot read it"]), v_1003127 => +v_1003126 = template_unbox(String, v_1003127); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1003126}}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_offsets_walk{v_3, v_22, []}}, v_1003130 => +v_1003129 = template_unbox(cps_provider_2_Part, v_1003130); TemplateFinished{TemplateValue{v_1003129}}}

def template_match_763(v_17: cps_provider_1_Node, +v_1: Nat, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_17:
    case cps_provider_1_Node{v_21, +v_22, v_23}:
      v_1003125 = {Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_22), v_1) : Bool}
      template_match_762(v_1003125, v_3, v_1, v_22)

def template_match_764(+v_1003124: cps_provider_1_NodeResult, +v_1: Nat, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003124:
    case cps_provider_1_NodeFailed{v_15}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_15}}}
    case cps_provider_1_NodeFound{v_17}:
      template_match_763(v_17, v_1, v_3)

def template_body_cps_provider_2_map_offsets(+v_1: Nat, +v_3: String, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_5:
    case cps_provider_2_World{v_1004860, v_1004861, v_1004862}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_layout{v_1004860, v_3}}, False{}, v_1004863 => template_body_cps_provider_1_node_layout(v_1004860, v_3), v_1004864 => +v_1004865 = template_unbox(cps_provider_1_NodeResult, v_1004864); template_match_764(v_1004865, v_1, v_3)}

def template_match_766(v_1003134: Bool, +v_1: String, v_13: List<&2, cps_provider_1_NodeSlot>, v_18: Nat, +v_7: List<&2, String>) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003134:
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the map node `", v_1, "` stores a field wider than one word, so Base's Map.find cannot index it"]}}, False{}, v_1003137 => template_body_cps_provider_2_join_text(["the map node `", v_1, "` stores a field wider than one word, so Base's Map.find cannot index it"]), v_1003136 => +v_1003135 = template_unbox(String, v_1003136); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1003135}}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_offsets_walk{v_1, v_13, Nat.show(v_18) <> v_7}}, v_1003139 => +v_1003138 = template_unbox(cps_provider_2_Part, v_1003139); TemplateFinished{TemplateValue{v_1003138}}}

def template_continuation_767(+v_1003133: Nat, +v_1: String, v_13: List<&2, cps_provider_1_NodeSlot>, v_18: Nat, +v_7: List<&2, String>) -> TemplateProgress<cps_provider_2_Part>:
  v_1003134 = {Nat.is_eq(v_1003133, 1n) : Bool}
  template_match_766(v_1003134, v_1, v_13, v_18, v_7)

def template_match_768(+v_12: cps_provider_1_NodeSlot, +v_1: String, v_13: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, String>) -> TemplateProgress<cps_provider_2_Part>:
  match v_12:
    case cps_provider_1_NodeSlot{v_17, v_18, v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_19}}, False{}, v_1003141 => template_body_cps_provider_1_layout_words(v_19), v_1003140 => +v_1003133 = template_unbox(Nat, v_1003140); template_continuation_767(v_1003133, v_1, v_13, v_18, v_7)}

def template_body_cps_provider_2_map_offsets_walk(+v_1: String, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, String>) -> TemplateProgress<cps_provider_2_Part>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_PartOk{String.join(List.reverse(&2, String, v_7), ", ")}}}
    case +v_1004866 <> v_1004867:
      template_match_768(v_1004866, v_1, v_1004867, v_7)

def template_body_cps_provider_2_map_find_missing(+v_1: String) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the program has no `", v_1, "` constructor, which the C runtime contract requires"]}}, False{}, v_1003144 => template_body_cps_provider_2_join_text(["the program has no `", v_1, "` constructor, which the C runtime contract requires"]), v_1003143 => +v_1003142 = template_unbox(String, v_1003143); TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_1003142}}}}

def template_match_770(+v_1003157: Maybe<&2, U32>, +v_1: String, +v_3: String, +v_10: U32, +v_14: U32, +v_18: U32, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003157:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_find_missing{"None"}}, False{}, v_1003160 => template_body_cps_provider_2_map_find_missing("None"), v_1003159 => +v_1003158 = template_unbox(cps_provider_2_Part, v_1003159); TemplateFinished{TemplateValue{v_1003158}}}
    case Some{+v_22}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_find_build{v_1, v_3, v_10, v_14, v_18, v_22, v_5}}, v_1003162 => +v_1003161 = template_unbox(cps_provider_2_Part, v_1003162); TemplateFinished{TemplateValue{v_1003161}}}

def template_match_771(+v_1003153: Maybe<&2, U32>, +v_5: cps_provider_2_World, +v_1: String, +v_3: String, +v_10: U32, +v_14: U32) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003153:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_find_missing{"Some"}}, False{}, v_1003156 => template_body_cps_provider_2_map_find_missing("Some"), v_1003155 => +v_1003154 = template_unbox(cps_provider_2_Part, v_1003155); TemplateFinished{TemplateValue{v_1003154}}}
    case Some{+v_18}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{"None", v_5}}, False{}, v_1003164 => template_body_cps_provider_2_cid_of("None", v_5), v_1003163 => +v_1003157 = template_unbox(Maybe<&2, U32>, v_1003163); template_match_770(v_1003157, v_1, v_3, v_10, v_14, v_18, v_5)}

def template_match_772(+v_1003149: Maybe<&2, U32>, +v_5: cps_provider_2_World, +v_1: String, +v_3: String, +v_10: U32) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003149:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_find_missing{"MLeaf"}}, False{}, v_1003152 => template_body_cps_provider_2_map_find_missing("MLeaf"), v_1003151 => +v_1003150 = template_unbox(cps_provider_2_Part, v_1003151); TemplateFinished{TemplateValue{v_1003150}}}
    case Some{+v_14}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{"Some", v_5}}, False{}, v_1003166 => template_body_cps_provider_2_cid_of("Some", v_5), v_1003165 => +v_1003153 = template_unbox(Maybe<&2, U32>, v_1003165); template_match_771(v_1003153, v_5, v_1, v_3, v_10, v_14)}

def template_match_773(+v_1003145: Maybe<&2, U32>, +v_5: cps_provider_2_World, +v_1: String, +v_3: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003145:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_find_missing{"MNode"}}, False{}, v_1003148 => template_body_cps_provider_2_map_find_missing("MNode"), v_1003147 => +v_1003146 = template_unbox(cps_provider_2_Part, v_1003147); TemplateFinished{TemplateValue{v_1003146}}}
    case Some{+v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{"MLeaf", v_5}}, False{}, v_1003168 => template_body_cps_provider_2_cid_of("MLeaf", v_5), v_1003167 => +v_1003149 = template_unbox(Maybe<&2, U32>, v_1003167); template_match_772(v_1003149, v_5, v_1, v_3, v_10)}

def template_body_cps_provider_2_map_find_text(+v_1: String, +v_3: String, +v_5: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_cid_of{"MNode", v_5}}, False{}, v_1003170 => template_body_cps_provider_2_cid_of("MNode", v_5), v_1003169 => +v_1003145 = template_unbox(Maybe<&2, U32>, v_1003169); template_match_773(v_1003145, v_5, v_1, v_3)}

def template_match_774(+v_1003174: cps_provider_2_Part, +v_1: String, +v_3: String, +v_5: U32, +v_7: U32, v_19: String, v_20: String, v_25: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003174:
    case cps_provider_2_PartFail{v_28}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_28}}}
    case cps_provider_2_PartOk{v_30}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_find_expr{v_1, v_3, v_5, v_7, v_19, v_20, v_25, v_30}}, v_1003176 => +v_1003175 = template_unbox(String, v_1003176); TemplateFinished{TemplateValue{cps_provider_2_PartOk{v_1003175}}}}

def template_match_775(+v_1003173: cps_provider_2_Part, +v_11: U32, +v_13: cps_provider_2_World, +v_1: String, +v_3: String, +v_5: U32, +v_7: U32, v_19: String, v_20: String) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003173:
    case cps_provider_2_PartFail{v_23}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_23}}}
    case cps_provider_2_PartOk{v_25}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_construct_part{v_11, [], v_13}}, False{}, v_1003178 => template_body_cps_provider_2_construct_part(v_11, [], v_13), v_1003177 => +v_1003174 = template_unbox(cps_provider_2_Part, v_1003177); template_match_774(v_1003174, v_1, v_3, v_5, v_7, v_19, v_20, v_25)}

def template_match_776(+v_1003171: cps_provider_2_Part, +v_1003172: cps_provider_2_Part, +v_9: U32, +v_13: cps_provider_2_World, +v_11: U32, +v_1: String, +v_3: String, +v_5: U32, +v_7: U32) -> TemplateProgress<cps_provider_2_Part>:
  match v_1003171, v_1003172:
    case cps_provider_2_PartOk{v_19}, cps_provider_2_PartOk{v_20}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_cps_provider_2_construct_part{v_9, [cps_provider_2_Operand{BIR.Affine{}, "mfm"}], v_13}}, False{}, v_1003180 => template_body_cps_provider_2_construct_part(v_9, [cps_provider_2_Operand{BIR.Affine{}, "mfm"}], v_13), v_1003179 => +v_1003173 = template_unbox(cps_provider_2_Part, v_1003179); template_match_775(v_1003173, v_11, v_13, v_1, v_3, v_5, v_7, v_19, v_20)}
    case cps_provider_2_PartFail{v_34}, _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_34}}}
    case _, cps_provider_2_PartFail{v_39}:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{v_39}}}

def template_body_cps_provider_2_map_find_build(+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: U32, +v_11: U32, +v_13: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_offsets{3n, "MNode", v_13}}, False{}, v_1003184 => template_body_cps_provider_2_map_offsets(3n, "MNode", v_13), v_1003183 => +v_1003171 = template_unbox(cps_provider_2_Part, v_1003183); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_offsets{2n, "MLeaf", v_13}}, False{}, v_1003182 => template_body_cps_provider_2_map_offsets(2n, "MLeaf", v_13), v_1003181 => +v_1003172 = template_unbox(cps_provider_2_Part, v_1003181); template_match_776(v_1003171, v_1003172, v_9, v_13, v_11, v_1, v_3, v_5, v_7)}}

def template_body_cps_provider_2_map_find_expr(+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: String, +v_11: String, +v_13: String, +v_15: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["({\n  Term mfm = 0;\n  u32 mfh = (u32)map_find_read(e, ", U32.show(v_5), "u, ", U32.show(v_7), "u, ", v_9, ", ", v_11, ", ", v_1, ", ", v_3, ", &mfm);\n  mfh ? ", v_13, " : ", v_15, ";\n})"]}}, False{}, v_1003187 => template_body_cps_provider_2_join_text(["({\n  Term mfm = 0;\n  u32 mfh = (u32)map_find_read(e, ", U32.show(v_5), "u, ", U32.show(v_7), "u, ", v_9, ", ", v_11, ", ", v_1, ", ", v_3, ", &mfm);\n  mfh ? ", v_13, " : ", v_15, ";\n})"]), v_1003186 => +v_1003185 = template_unbox(String, v_1003186); TemplateFinished{TemplateValue{v_1003185}}}

def template_body_cps_provider_2_map_find_operands(+v_2: List<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case [v_8, v_9]:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_map_find_text{template_pure_cps_provider_2_operand_text(v_8), template_pure_cps_provider_2_operand_text(v_9), v_4}}, False{}, v_1003190 => template_body_cps_provider_2_map_find_text(template_pure_cps_provider_2_operand_text(v_8), template_pure_cps_provider_2_operand_text(v_9), v_4), v_1003189 => +v_1003188 = template_unbox(cps_provider_2_Part, v_1003189); TemplateFinished{TemplateValue{v_1003188}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"Base's Map.find takes the map and the query key"}}}

def template_body_cps_provider_2_map_find_names(+v_2: List<&2, String>, +v_4: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_2:
    case [v_8, v_9]:
      template_body_cps_provider_2_map_find_text(v_8, v_9, v_4)
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"Base's Map.find takes the map and the query key"}}}

def template_body_cps_provider_2_map_find_part(+v_2: List<&2, cps_provider_2_Operand>, +v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the map read `Map.find` carries no instantiated value Descriptor; lowering must supply PrimitiveCall.types"}}}
    case [v_1004868]:
      template_body_cps_provider_2_map_find_operands(v_2, v_6)
    case v_1004869:
      TemplateFinished{TemplateValue{cps_provider_2_PartFail{"the map read `Map.find` must carry exactly one instantiated value Descriptor"}}}

def template_body_cps_provider_2_descriptor_part(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World) -> TemplateProgress<cps_provider_2_Part>:
  match v_0:
    case BIR.PrimMapFind{}:
      template_body_cps_provider_2_map_find_part(v_3, v_5, v_7)
    case _:
      template_body_cps_provider_2_array_part(v_0, v_3, v_5, v_7)

def template_body_cps_provider_2_show_state0() -> TemplateProgress<cps_provider_2_ShowState>:
  TemplateFinished{TemplateValue{cps_provider_2_ShowState{[], [], Map.new(&2, Nat), [], None{}}}}

def template_body_cps_provider_2_show_words(+v_1: cps_provider_2_ShowState) -> TemplateProgress<List<&2, cps_provider_2_ShowWord>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_show_words(v_1)}}

def template_body_cps_provider_2_show_patches(+v_1: cps_provider_2_ShowState) -> TemplateProgress<List<&2, cps_provider_2_ShowPatch>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_show_patches(v_1)}}

def template_body_cps_provider_2_show_memo(+v_1: cps_provider_2_ShowState) -> TemplateProgress<Map<&2, Nat>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_show_memo(v_1)}}

def template_body_cps_provider_2_show_names(+v_1: cps_provider_2_ShowState) -> TemplateProgress<List<&2, String>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_show_names(v_1)}}

def template_body_cps_provider_2_show_error(+v_1: cps_provider_2_ShowState) -> TemplateProgress<Maybe<&2, String>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_show_error(v_1)}}

def template_body_cps_provider_2_show_state_set_memo(+v_1: cps_provider_2_ShowState, +v_4: Map<&2, Nat>) -> TemplateProgress<cps_provider_2_ShowState>:
  match v_1:
    case cps_provider_2_ShowState{v_11, v_12, v_13, v_14, v_15}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowState{v_11, v_12, v_4, v_14, v_15}}}

def template_body_cps_provider_2_show_state_error(+v_1: cps_provider_2_ShowState, +v_3: String) -> TemplateProgress<cps_provider_2_ShowState>:
  match v_1:
    case cps_provider_2_ShowState{v_10, v_11, v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowState{v_10, v_11, v_12, v_13, Some{v_3}}}}

def template_body_cps_provider_2_show_next_state(+v_1: cps_provider_2_ShowAdvance) -> TemplateProgress<cps_provider_2_ShowState>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_show_next_state(v_1)}}

def template_body_cps_provider_2_show_next_kids(+v_1: cps_provider_2_ShowAdvance) -> TemplateProgress<List<&2, cps_provider_2_ShowJob>>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_2_show_next_kids(v_1)}}

def template_body_cps_provider_2_show_append_word(+v_1: cps_provider_2_ShowState, +v_3: cps_provider_2_ShowWord) -> TemplateProgress<cps_provider_2_ShowState>:
  match v_1:
    case cps_provider_2_ShowState{v_10, v_11, v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowState{List.append(&2, cps_provider_2_ShowWord, v_10, [v_3]), v_11, v_12, v_13, v_14}}}

def template_body_cps_provider_2_show_append_num(+v_1: cps_provider_2_ShowState, +v_3: Nat) -> TemplateProgress<cps_provider_2_ShowState>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_word{v_1, cps_provider_2_ShowNum{v_3}}}, False{}, v_1003197 => template_body_cps_provider_2_show_append_word(v_1, cps_provider_2_ShowNum{v_3}), v_1003196 => +v_1003195 = template_unbox(cps_provider_2_ShowState, v_1003196); TemplateFinished{TemplateValue{v_1003195}}}

def template_body_cps_provider_2_show_append_cid(+v_1: cps_provider_2_ShowState, +v_3: Nat) -> TemplateProgress<cps_provider_2_ShowState>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_word{v_1, cps_provider_2_ShowCid{v_3}}}, False{}, v_1003200 => template_body_cps_provider_2_show_append_word(v_1, cps_provider_2_ShowCid{v_3}), v_1003199 => +v_1003198 = template_unbox(cps_provider_2_ShowState, v_1003199); TemplateFinished{TemplateValue{v_1003198}}}

def template_body_cps_provider_2_show_append_name(+v_1: cps_provider_2_ShowState, +v_3: String) -> TemplateProgress<cps_provider_2_ShowState>:
  match v_1:
    case cps_provider_2_ShowState{v_10, v_11, v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowState{v_10, v_11, v_12, List.append(&2, String, v_13, [v_3]), v_14}}}

def template_body_cps_provider_2_show_append_patch(+v_1: cps_provider_2_ShowState, +v_3: Nat, +v_5: Nat) -> TemplateProgress<cps_provider_2_ShowState>:
  match v_1:
    case cps_provider_2_ShowState{v_12, v_13, v_14, v_15, v_16}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowState{v_12, List.append(&2, cps_provider_2_ShowPatch, [cps_provider_2_ShowPatchAt{v_3, v_5}], v_13), v_14, v_15, v_16}}}

def template_body_cps_provider_2_show_apply_patch(+v_1: cps_provider_2_ShowState, +v_4: Maybe<&2, Nat>, +v_6: Nat) -> TemplateProgress<cps_provider_2_ShowState>:
  match v_4:
    case Some{v_1004870}:
      template_body_cps_provider_2_show_append_patch(v_1, v_1004870, v_6)
    case None{}:
      TemplateFinished{TemplateValue{v_1}}

def template_body_cps_provider_2_show_native_kind(+v_1: String) -> TemplateProgress<cps_provider_2_ShowKind>:
  match v_1:
    case "U32":
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{0n}}}
    case "F32":
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{1n}}}
    case "Nat":
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{2n}}}
    case "Char":
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{3n}}}
    case "String":
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{4n}}}
    case "Array":
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{6n}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{7n}}}

def template_match_788(v_16: Maybe<&2, String>) -> TemplateProgress<cps_provider_2_ShowKind>:
  match v_16:
    case Some{v_21}:
      template_body_cps_provider_2_show_native_kind(v_21)
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{7n}}}

def template_match_789(v_1003203: Bool, v_16: Maybe<&2, String>) -> TemplateProgress<cps_provider_2_ShowKind>:
  match v_1003203:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindFailed{"main's type IO.OP cannot be printed as data"}}}
    case False{}:
      template_match_788(v_16)

def template_match_790(v_7: BIR.Family) -> TemplateProgress<cps_provider_2_ShowKind>:
  match v_7:
    case BIR.Family{v_14, v_15, v_16, v_17, v_18, v_19}:
      v_1003203 = {String.eq(v_14, "IO.OP") : Bool}
      template_match_789(v_1003203, v_16)

def template_match_791(+v_1003202: Maybe<&2, BIR.Family>) -> TemplateProgress<cps_provider_2_ShowKind>:
  match v_1003202:
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindFailed{"main's type is a type former and cannot be printed"}}}
    case Some{v_7}:
      template_match_790(v_7)

def template_body_cps_provider_2_show_kind_family(+v_1: String, +v_3: cps_provider_1_Context) -> TemplateProgress<cps_provider_2_ShowKind>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_family_lookup{v_3, v_1}}, False{}, v_1003206 => template_body_cps_provider_1_family_lookup(v_3, v_1), v_1003205 => +v_1003202 = template_unbox(Maybe<&2, BIR.Family>, v_1003205); template_match_791(v_1003202)}

def template_body_cps_provider_2_show_kind_head(+v_1: cps_provider_1_HeadResult, +v_3: cps_provider_1_Context) -> TemplateProgress<cps_provider_2_ShowKind>:
  match v_1:
    case cps_provider_1_HeadFailed{v_6}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindFailed{v_6}}}
    case cps_provider_1_HeadEquality{}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindOk{5n}}}
    case cps_provider_1_HeadBoxed{v_8}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowKindFailed{"main's type is abstract or open and cannot be printed"}}}
    case cps_provider_1_HeadFound{v_11, v_12}:
      template_body_cps_provider_2_show_kind_family(v_11, v_3)

def template_continuation_793(+v_1003208: cps_provider_1_HeadResult, +v_1: cps_provider_1_Context) -> TemplateProgress<cps_provider_2_ShowKind>:
  template_body_cps_provider_2_show_kind_head(v_1003208, v_1)

def template_body_cps_provider_2_show_kind(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_2_ShowKind>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_head_native{v_1, v_2}}, False{}, v_1003211 => template_body_cps_provider_1_head_native(v_1, v_2), v_1003210 => +v_1003208 = template_unbox(cps_provider_1_HeadResult, v_1003210); template_continuation_793(v_1003208, v_1)}

def template_body_cps_provider_2_show_box_flag(+v_1: cps_provider_1_Layout) -> TemplateProgress<Nat>:
  match v_1:
    case cps_provider_1_LayoutBox{v_4}:
      TemplateFinished{TemplateValue{1n}}
    case _:
      TemplateFinished{TemplateValue{0n}}

def template_body_cps_provider_2_show_tag_plain(+v_1: Nat) -> TemplateProgress<Nat>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{0n}}
    case 1n:
      TemplateFinished{TemplateValue{0n}}
    case _:
      TemplateFinished{TemplateValue{1n}}

def template_body_cps_provider_2_show_tag_start(+v_1: Nat, +v_3: Nat) -> TemplateProgress<Nat>:
  match v_1:
    case 1n:
      TemplateFinished{TemplateValue{0n}}
    case _:
      template_body_cps_provider_2_show_tag_plain(v_3)

def template_body_cps_provider_2_show_quote(+v_1: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["\"", v_1, "\""]}}, False{}, v_1003215 => template_body_cps_provider_2_join_text(["\"", v_1, "\""]), v_1003214 => +v_1003213 = template_unbox(String, v_1003214); TemplateFinished{TemplateValue{v_1003213}}}

def template_body_cps_provider_2_show_name_sep(+v_2: List<&2, String>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{""}}
    case _:
      TemplateFinished{TemplateValue{","}}

def template_body_cps_provider_2_show_render_names(+v_2: List<&2, String>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{""}}
    case +v_6 <> +v_7:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_quote{v_6}}, False{}, v_1003223 => template_body_cps_provider_2_show_quote(v_6), v_1003222 => +v_1003216 = template_unbox(String, v_1003222); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_name_sep{v_7}}, False{}, v_1003221 => template_body_cps_provider_2_show_name_sep(v_7), v_1003220 => +v_1003217 = template_unbox(String, v_1003220); TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_render_names{v_7}}, v_1003219 => +v_1003218 = template_unbox(String, v_1003219); TemplateFinished{TemplateValue{String.append(String.append(v_1003216, v_1003217), v_1003218)}}}}}

def template_body_cps_provider_2_show_render_sep_flag(+v_1: Bool) -> TemplateProgress<String>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{""}}
    case False{}:
      TemplateFinished{TemplateValue{","}}

def template_body_cps_provider_2_show_render_sep(+v_1: String) -> TemplateProgress<String>:
  v_4 = String.is_empty(v_1)
  template_body_cps_provider_2_show_render_sep_flag(v_4)

def template_body_cps_provider_2_show_render_word(+v_1: cps_provider_2_ShowWord) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_2_ShowNum{v_4}:
      TemplateFinished{TemplateValue{Nat.show(v_4)}}
    case cps_provider_2_ShowCid{v_6}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["CID_", Nat.show(v_6)]}}, False{}, v_1003227 => template_body_cps_provider_2_join_text(["CID_", Nat.show(v_6)]), v_1003226 => +v_1003225 = template_unbox(String, v_1003226); TemplateFinished{TemplateValue{v_1003225}}}

def template_body_cps_provider_2_show_render_words(+v_2: List<&2, cps_provider_2_ShowWord>, +v_4: String) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_8 <> +v_9:
      v_1003229 = {v_4 : String}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_render_sep{v_4}}, False{}, v_1003240 => template_body_cps_provider_2_show_render_sep(v_4), v_1003239 => +v_1003230 = template_unbox(String, v_1003239); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_render_word{v_8}}, False{}, v_1003238 => template_body_cps_provider_2_show_render_word(v_8), v_1003237 => +v_1003231 = template_unbox(String, v_1003237); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003229, v_1003230, v_1003231]}}, False{}, v_1003236 => template_body_cps_provider_2_join_text([v_1003229, v_1003230, v_1003231]), v_1003235 => +v_1003232 = template_unbox(String, v_1003235); TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_render_words{{v_9 : List<&2, cps_provider_2_ShowWord>}, v_1003232}}, v_1003234 => +v_1003233 = template_unbox(String, v_1003234); TemplateFinished{TemplateValue{v_1003233}}}}}}

def template_match_802(v_1003241: Bool, +v_1: String, +v_9: List<&2, BIR.Family>, v_21: List<&2, BIR.DescriptorArm>) -> TemplateProgress<Maybe<&2, List<&2, BIR.DescriptorArm>>>:
  match v_1003241:
    case False{}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_family_arms{v_1, v_9}}, v_1003243 => +v_1003242 = template_unbox(Maybe<&2, List<&2, BIR.DescriptorArm>>, v_1003243); TemplateFinished{TemplateValue{v_1003242}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_21}}}

def template_match_803(+v_8: BIR.Family, +v_1: String, +v_9: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, List<&2, BIR.DescriptorArm>>>:
  match v_8:
    case BIR.Family{v_16, v_17, v_18, v_19, v_20, v_21}:
      v_23 = String.eq(v_1, v_16)
      template_match_802(v_23, v_1, v_9, v_21)

def template_body_cps_provider_2_family_arms(+v_1: String, +v_3: List<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, List<&2, BIR.DescriptorArm>>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004871 <> +v_1004872:
      template_match_803(v_1004871, v_1, v_1004872)

def template_match_805(v_1003244: Bool, +v_1: String, +v_8: List<&2, BIR.ConstructorLayout>, +v_7: BIR.ConstructorLayout) -> TemplateProgress<Maybe<&2, BIR.ConstructorLayout>>:
  match v_1003244:
    case False{}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_ctor_find_key{v_1, v_8}}, v_1003246 => +v_1003245 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1003246); TemplateFinished{TemplateValue{v_1003245}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_7}}}

def template_match_806(+v_7: BIR.ConstructorLayout, +v_1: String, +v_8: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Maybe<&2, BIR.ConstructorLayout>>:
  match v_7:
    case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
      v_18 = String.eq(v_14, v_1)
      template_match_805(v_18, v_1, v_8, v_7)

def template_body_cps_provider_2_ctor_find_key(+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Maybe<&2, BIR.ConstructorLayout>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004873 <> +v_1004874:
      template_match_806(v_1004873, v_1, v_1004874)

def template_match_808(v_5: BIR.ConstructorLayout) -> TemplateProgress<Maybe<&2, Nat>>:
  match v_5:
    case BIR.ConstructorLayout{v_10, v_11, v_12, v_13}:
      TemplateFinished{TemplateValue{Some{U32.to_nat(v_10)}}}

def template_body_cps_provider_2_show_cid_found(+v_1: Maybe<&2, BIR.ConstructorLayout>) -> TemplateProgress<Maybe<&2, Nat>>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{None{}}}
    case Some{v_5}:
      template_match_808(v_5)

def template_body_cps_provider_2_show_cid_of_key(+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>) -> TemplateProgress<Maybe<&2, Nat>>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_ctor_find_key{v_1, v_3}}, False{}, v_1003250 => template_body_cps_provider_2_ctor_find_key(v_1, v_3), v_1003249 => +v_1003247 = template_unbox(Maybe<&2, BIR.ConstructorLayout>, v_1003249); template_body_cps_provider_2_show_cid_found(v_1003247)}

def template_body_cps_provider_2_show_arm_bracket_name(+v_1: String) -> TemplateProgress<Nat>:
  match v_1:
    case "Tuple":
      TemplateFinished{TemplateValue{2n}}
    case "Con":
      TemplateFinished{TemplateValue{1n}}
    case "Nil":
      TemplateFinished{TemplateValue{1n}}
    case _:
      TemplateFinished{TemplateValue{0n}}

def template_body_cps_provider_2_show_arm_bracket(+v_1: String) -> TemplateProgress<Nat>:
  template_body_cps_provider_2_show_arm_bracket_name(v_1)

def template_match_811(v_11: BIR.Quantity, +v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_11:
    case BIR.Erased{}:
      TemplateFinished{TemplateValue{True{}}}
    case _:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_erased_present{v_6}}, v_1003253 => +v_1003252 = template_unbox(Bool, v_1003253); TemplateFinished{TemplateValue{v_1003252}}}

def template_match_812(+v_5: BIR.DescriptorField, +v_6: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_5:
    case BIR.DescriptorField{v_10, v_11, v_12}:
      template_match_811(v_11, v_6)

def template_body_cps_provider_2_show_erased_present(+v_1: List<&2, BIR.DescriptorField>) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_5 <> +v_6:
      template_match_812(v_5, v_6)

def template_match_814(v_1003254: Bool, +v_10: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_9: BIR.DescriptorField) -> TemplateProgress<Maybe<&2, BIR.DescriptorField>>:
  match v_1003254:
    case False{}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_field_at_each{v_10, v_3, Nat.add(v_5, 1n)}}, v_1003256 => +v_1003255 = template_unbox(Maybe<&2, BIR.DescriptorField>, v_1003256); TemplateFinished{TemplateValue{v_1003255}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_9}}}

def template_body_cps_provider_2_show_field_at_each(+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat) -> TemplateProgress<Maybe<&2, BIR.DescriptorField>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1004875 <> +v_1004876:
      v_1004877 = Nat.is_eq(v_5, v_3)
      template_match_814(v_1004877, v_1004876, v_3, v_5, v_1004875)

def template_body_cps_provider_2_show_field_at(+v_1: List<&2, BIR.DescriptorField>, +v_3: U32) -> TemplateProgress<Maybe<&2, BIR.DescriptorField>>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_field_at_each{v_1, U32.to_nat(v_3), 0n}}, False{}, v_1003259 => template_body_cps_provider_2_show_field_at_each(v_1, U32.to_nat(v_3), 0n), v_1003258 => +v_1003257 = template_unbox(Maybe<&2, BIR.DescriptorField>, v_1003258); TemplateFinished{TemplateValue{v_1003257}}}

def template_match_816(v_1003260: Bool, +v_11: List<&2, cps_provider_1_LayArm>, +v_4: String, v_15: List<&2, cps_provider_1_Layout>) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_Layout>>>:
  match v_1003260:
    case False{}:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arm_layouts_each{v_11, v_4}}, v_1003262 => +v_1003261 = template_unbox(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_1003262); TemplateFinished{TemplateValue{v_1003261}}}
    case True{}:
      TemplateFinished{TemplateValue{Some{v_15}}}

def template_match_817(+v_10: cps_provider_1_LayArm, +v_4: String, +v_11: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_Layout>>>:
  match v_10:
    case cps_provider_1_LayArm{v_14, v_15}:
      v_17 = String.eq(v_14, v_4)
      template_match_816(v_17, v_11, v_4, v_15)

def template_body_cps_provider_2_show_arm_layouts_each(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: String) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_Layout>>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_10 <> +v_11:
      template_match_817(v_10, v_4, v_11)

def template_body_cps_provider_2_show_arm_layouts(+v_1: cps_provider_1_Layout, +v_3: String) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_Layout>>>:
  match v_1:
    case cps_provider_1_LayoutWord{v_8}:
      TemplateFinished{TemplateValue{None{}}}
    case cps_provider_1_LayoutBox{v_10}:
      TemplateFinished{TemplateValue{None{}}}
    case cps_provider_1_LayoutData{v_13, v_14}:
      template_body_cps_provider_2_show_arm_layouts_each(v_14, v_3)

def template_match_820(v_8: cps_provider_1_Node) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_NodeSlot>>>:
  match v_8:
    case cps_provider_1_Node{v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{Some{v_13}}}

def template_body_cps_provider_2_show_node_layout_slots(+v_1: cps_provider_1_NodeResult) -> TemplateProgress<Maybe<&2, List<&2, cps_provider_1_NodeSlot>>>:
  match v_1:
    case cps_provider_1_NodeFailed{v_6}:
      TemplateFinished{TemplateValue{None{}}}
    case cps_provider_1_NodeFound{v_8}:
      template_match_820(v_8)

def template_body_cps_provider_2_show_word_key(+v_1: cps_provider_1_CWord) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_1_CWord32{}:
      TemplateFinished{TemplateValue{"32"}}
    case cps_provider_1_CWord64{}:
      TemplateFinished{TemplateValue{"64"}}
    case cps_provider_1_CWordBox{}:
      TemplateFinished{TemplateValue{"x"}}

def template_body_cps_provider_2_show_box_key(+v_1: cps_provider_1_BoxReason) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_1_BoxOpen{}:
      TemplateFinished{TemplateValue{"open"}}
    case cps_provider_1_BoxUnresolved{v_4}:
      v_1003264 = {"U" : String}
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_text{v_4}}, v_1003269 => +v_1003265 = template_unbox(String, v_1003269); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003264, v_1003265]}}, False{}, v_1003268 => template_body_cps_provider_2_join_text([v_1003264, v_1003265]), v_1003267 => +v_1003266 = template_unbox(String, v_1003267); TemplateFinished{TemplateValue{v_1003266}}}}
    case cps_provider_1_BoxArray{}:
      TemplateFinished{TemplateValue{"array"}}
    case cps_provider_1_BoxIo{}:
      TemplateFinished{TemplateValue{"io"}}
    case cps_provider_1_BoxRecursive{v_8}:
      v_1003270 = {"R" : String}
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_text{v_8}}, v_1003275 => +v_1003271 = template_unbox(String, v_1003275); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003270, v_1003271]}}, False{}, v_1003274 => template_body_cps_provider_2_join_text([v_1003270, v_1003271]), v_1003273 => +v_1003272 = template_unbox(String, v_1003273); TemplateFinished{TemplateValue{v_1003272}}}}
    case cps_provider_1_BoxWide{v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["wide:", Nat.show(v_12)]}}, False{}, v_1003278 => template_body_cps_provider_2_join_text(["wide:", Nat.show(v_12)]), v_1003277 => +v_1003276 = template_unbox(String, v_1003277); TemplateFinished{TemplateValue{v_1003276}}}

def template_body_cps_provider_2_lk_text(+v_1: String) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[Nat.show(String.length(v_1)), ":", v_1]}}, False{}, v_1003281 => template_body_cps_provider_2_join_text([Nat.show(String.length(v_1)), ":", v_1]), v_1003280 => +v_1003279 = template_unbox(String, v_1003280); TemplateFinished{TemplateValue{v_1003279}}}

def template_continuation_824(+v_7: List<&2, cps_provider_1_CWord>, +v_1003282: String) -> TemplateProgress<String>:
  v_1003283 = {"," : String}
  TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_words{v_7}}, v_1003288 => +v_1003284 = template_unbox(String, v_1003288); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003282, v_1003283, v_1003284]}}, False{}, v_1003287 => template_body_cps_provider_2_join_text([v_1003282, v_1003283, v_1003284]), v_1003286 => +v_1003285 = template_unbox(String, v_1003286); TemplateFinished{TemplateValue{v_1003285}}}}

def template_body_cps_provider_2_lk_words(+v_2: List<&2, cps_provider_1_CWord>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{""}}
    case +v_6 <> +v_7:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_word_key{v_6}}, False{}, v_1003290 => template_body_cps_provider_2_show_word_key(v_6), v_1003289 => +v_1003282 = template_unbox(String, v_1003289); template_continuation_824(v_7, v_1003282)}

def template_continuation_826(+v_7: List<&2, cps_provider_1_Layout>, +v_1003291: String) -> TemplateProgress<String>:
  v_1003292 = {"," : String}
  TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_fields{v_7}}, v_1003297 => +v_1003293 = template_unbox(String, v_1003297); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003291, v_1003292, v_1003293]}}, False{}, v_1003296 => template_body_cps_provider_2_join_text([v_1003291, v_1003292, v_1003293]), v_1003295 => +v_1003294 = template_unbox(String, v_1003295); TemplateFinished{TemplateValue{v_1003294}}}}

def template_body_cps_provider_2_lk_fields(+v_2: List<&2, cps_provider_1_Layout>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{""}}
    case +v_6 <> +v_7:
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_layout_key{v_6}}, v_1003298 => +v_1003291 = template_unbox(String, v_1003298); template_continuation_826(v_7, v_1003291)}

def template_continuation_828(+v_7: List<&2, cps_provider_1_LayArm>, v_1003299: String, +v_1003300: String, v_1003301: String, v_1003302: String, v_1003303: String, +v_1003304: String) -> TemplateProgress<String>:
  v_1003305 = {";" : String}
  TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_arms{v_7}}, v_1003310 => +v_1003306 = template_unbox(String, v_1003310); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003299, v_1003300, v_1003301, v_1003302, v_1003303, v_1003304, v_1003305, v_1003306]}}, False{}, v_1003309 => template_body_cps_provider_2_join_text([v_1003299, v_1003300, v_1003301, v_1003302, v_1003303, v_1003304, v_1003305, v_1003306]), v_1003308 => +v_1003307 = template_unbox(String, v_1003308); TemplateFinished{TemplateValue{v_1003307}}}}

def template_continuation_829(+v_11: List<&2, cps_provider_1_Layout>, +v_7: List<&2, cps_provider_1_LayArm>, v_1003299: String, +v_1003300: String) -> TemplateProgress<String>:
  v_1003302 = {Nat.show(List.length(&2, cps_provider_1_Layout, v_11)) : String}
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_fields{v_11}}, False{}, v_1003312 => template_body_cps_provider_2_lk_fields(v_11), v_1003311 => +v_1003304 = template_unbox(String, v_1003311); template_continuation_828(v_7, v_1003299, v_1003300, {":" : String}, v_1003302, {":" : String}, v_1003304)}

def template_match_830(+v_6: cps_provider_1_LayArm, +v_7: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<String>:
  match v_6:
    case cps_provider_1_LayArm{v_10, v_11}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_text{v_10}}, False{}, v_1003314 => template_body_cps_provider_2_lk_text(v_10), v_1003313 => +v_1003300 = template_unbox(String, v_1003313); template_continuation_829(v_11, v_7, {"A" : String}, v_1003300)}

def template_body_cps_provider_2_lk_arms(+v_2: List<&2, cps_provider_1_LayArm>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{""}}
    case +v_6 <> +v_7:
      template_match_830(v_6, v_7)

def template_continuation_832(+v_14: List<&2, cps_provider_1_LayArm>, v_1003329: String, v_1003330: String, v_1003331: String, +v_1003332: String) -> TemplateProgress<String>:
  v_1003333 = {":" : String}
  v_1003334 = {Nat.show(List.length(&2, cps_provider_1_LayArm, v_14)) : String}
  v_1003335 = {":" : String}
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_arms{v_14}}, False{}, v_1003341 => template_body_cps_provider_2_lk_arms(v_14), v_1003340 => +v_1003336 = template_unbox(String, v_1003340); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003329, v_1003330, v_1003331, v_1003332, v_1003333, v_1003334, v_1003335, v_1003336]}}, False{}, v_1003339 => template_body_cps_provider_2_join_text([v_1003329, v_1003330, v_1003331, v_1003332, v_1003333, v_1003334, v_1003335, v_1003336]), v_1003338 => +v_1003337 = template_unbox(String, v_1003338); TemplateFinished{TemplateValue{v_1003337}}}}

def template_body_cps_provider_2_show_layout_key(+v_1: cps_provider_1_Layout) -> TemplateProgress<String>:
  match v_1:
    case cps_provider_1_LayoutWord{v_4}:
      v_1003315 = {"w" : String}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_word_key{v_4}}, False{}, v_1003321 => template_body_cps_provider_2_show_word_key(v_4), v_1003320 => +v_1003316 = template_unbox(String, v_1003320); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003315, v_1003316]}}, False{}, v_1003319 => template_body_cps_provider_2_join_text([v_1003315, v_1003316]), v_1003318 => +v_1003317 = template_unbox(String, v_1003318); TemplateFinished{TemplateValue{v_1003317}}}}
    case cps_provider_1_LayoutBox{v_8}:
      v_1003322 = {"B" : String}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_box_key{v_8}}, False{}, v_1003328 => template_body_cps_provider_2_show_box_key(v_8), v_1003327 => +v_1003323 = template_unbox(String, v_1003327); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1003322, v_1003323]}}, False{}, v_1003326 => template_body_cps_provider_2_join_text([v_1003322, v_1003323]), v_1003325 => +v_1003324 = template_unbox(String, v_1003325); TemplateFinished{TemplateValue{v_1003324}}}}
    case cps_provider_1_LayoutData{+v_13, v_14}:
      v_1003330 = {Nat.show(List.length(&2, cps_provider_1_CWord, v_13)) : String}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_lk_words{v_13}}, False{}, v_1003343 => template_body_cps_provider_2_lk_words(v_13), v_1003342 => +v_1003332 = template_unbox(String, v_1003342); template_continuation_832(v_14, {"D" : String}, v_1003330, {":" : String}, v_1003332)}

def template_match_834(v_1003344: Bool, +v_8: BIR.Descriptor, +v_9: List<&2, BIR.Descriptor>) -> TemplateProgress<List<&2, cps_provider_2_ShowToken>>:
  match v_1003344:
    case False{}:
      v_13 = {[cps_provider_2_ShowTokText{","}] : List<&2, cps_provider_2_ShowToken>}
      v_1003345 = {v_13 : List<&2, cps_provider_2_ShowToken>}
      v_1003346 = {[cps_provider_2_ShowTokDesc{v_8}] : List<&2, cps_provider_2_ShowToken>}
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_9, False{}}}, v_1003348 => +v_1003347 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003348); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003345, List.append(&2, cps_provider_2_ShowToken, v_1003346, v_1003347))}}}
    case True{}:
      v_13 = {[] : List<&2, cps_provider_2_ShowToken>}
      v_1003349 = {v_13 : List<&2, cps_provider_2_ShowToken>}
      v_1003350 = {[cps_provider_2_ShowTokDesc{v_8}] : List<&2, cps_provider_2_ShowToken>}
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_9, False{}}}, v_1003352 => +v_1003351 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003352); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003349, List.append(&2, cps_provider_2_ShowToken, v_1003350, v_1003351))}}}

def template_body_cps_provider_2_show_arg_tokens(+v_1: List<&2, BIR.Descriptor>, +v_3: Bool) -> TemplateProgress<List<&2, cps_provider_2_ShowToken>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_8 <> +v_9:
      template_match_834(v_3, v_8, v_9)

def template_body_cps_provider_2_show_quantity_key(+v_0: BIR.Quantity) -> TemplateProgress<String>:
  match v_0:
    case BIR.Erased{}:
      TemplateFinished{TemplateValue{"0"}}
    case BIR.Once{}:
      TemplateFinished{TemplateValue{"1"}}
    case BIR.Unrestricted{}:
      TemplateFinished{TemplateValue{"2"}}

def template_body_cps_provider_2_show_maybe_quantity_key(+v_1: Maybe<&2, BIR.Quantity>) -> TemplateProgress<String>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{"-"}}
    case Some{v_4}:
      template_body_cps_provider_2_show_quantity_key(v_4)

def template_match_838(v_1003354: Bool, +v_8: BIR.DescriptorPattern, +v_9: List<&2, BIR.DescriptorPattern>) -> TemplateProgress<List<&2, cps_provider_2_ShowToken>>:
  match v_1003354:
    case False{}:
      v_13 = {[cps_provider_2_ShowTokText{","}] : List<&2, cps_provider_2_ShowToken>}
      v_1003355 = {v_13 : List<&2, cps_provider_2_ShowToken>}
      v_1003356 = {[cps_provider_2_ShowTokPat{v_8}] : List<&2, cps_provider_2_ShowToken>}
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_pat_tokens{v_9, False{}}}, v_1003358 => +v_1003357 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003358); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003355, List.append(&2, cps_provider_2_ShowToken, v_1003356, v_1003357))}}}
    case True{}:
      v_13 = {[] : List<&2, cps_provider_2_ShowToken>}
      v_1003359 = {v_13 : List<&2, cps_provider_2_ShowToken>}
      v_1003360 = {[cps_provider_2_ShowTokPat{v_8}] : List<&2, cps_provider_2_ShowToken>}
      TemplatePending{TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_pat_tokens{v_9, False{}}}, v_1003362 => +v_1003361 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003362); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003359, List.append(&2, cps_provider_2_ShowToken, v_1003360, v_1003361))}}}

def template_body_cps_provider_2_show_pat_tokens(+v_1: List<&2, BIR.DescriptorPattern>, +v_3: Bool) -> TemplateProgress<List<&2, cps_provider_2_ShowToken>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_8 <> +v_9:
      template_match_838(v_3, v_8, v_9)

def template_body_cps_provider_2_show_pat_expand(+v_0: BIR.DescriptorPattern) -> TemplateProgress<List<&2, cps_provider_2_ShowToken>>:
  match v_0:
    case BIR.DescriptorBinder{v_4}:
      v_1003363 = {cps_provider_2_ShowTokText{"b"} : cps_provider_2_ShowToken}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_quantity_key{v_4}}, False{}, v_1003366 => template_body_cps_provider_2_show_quantity_key(v_4), v_1003365 => +v_1003364 = template_unbox(String, v_1003365); TemplateFinished{TemplateValue{[v_1003363, cps_provider_2_ShowTokText{v_1003364}]}}}
    case BIR.DescriptorConstructorPattern{v_8, v_9}:
      v_1003367 = {[cps_provider_2_ShowTokText{"c"}, cps_provider_2_ShowTokText{v_8}, cps_provider_2_ShowTokText{"("}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_pat_tokens{v_9, True{}}}, False{}, v_1003370 => template_body_cps_provider_2_show_pat_tokens(v_9, True{}), v_1003369 => +v_1003368 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003369); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003367, List.append(&2, cps_provider_2_ShowToken, v_1003368, [cps_provider_2_ShowTokText{")"}]))}}}

def template_body_cps_provider_2_show_desc_expand(+v_0: BIR.Descriptor) -> TemplateProgress<List<&2, cps_provider_2_ShowToken>>:
  match v_0:
    case BIR.DescriptorRef{v_5, v_6}:
      v_1003371 = {[cps_provider_2_ShowTokText{"R"}, cps_provider_2_ShowTokText{v_5}, cps_provider_2_ShowTokText{"("}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_6, True{}}}, False{}, v_1003374 => template_body_cps_provider_2_show_arg_tokens(v_6, True{}), v_1003373 => +v_1003372 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003373); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003371, List.append(&2, cps_provider_2_ShowToken, v_1003372, [cps_provider_2_ShowTokText{")"}]))}}}
    case BIR.DescriptorApplication{v_12, v_13}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"a"}, cps_provider_2_ShowTokDesc{v_12}, cps_provider_2_ShowTokDesc{v_13}]}}
    case BIR.DescriptorFill{v_16, v_17}:
      v_1003375 = {[cps_provider_2_ShowTokText{"F"}, cps_provider_2_ShowTokDesc{v_16}, cps_provider_2_ShowTokText{"["}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_17, True{}}}, False{}, v_1003378 => template_body_cps_provider_2_show_arg_tokens(v_17, True{}), v_1003377 => +v_1003376 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003377); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, List.append(&2, cps_provider_2_ShowToken, v_1003375, v_1003376), [cps_provider_2_ShowTokText{"]"}])}}}
    case BIR.DescriptorPlus{v_23, v_24}:
      v_1003379 = {[cps_provider_2_ShowTokText{"P"}, cps_provider_2_ShowTokDesc{v_23}, cps_provider_2_ShowTokText{"["}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_24, True{}}}, False{}, v_1003382 => template_body_cps_provider_2_show_arg_tokens(v_24, True{}), v_1003381 => +v_1003380 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003381); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, List.append(&2, cps_provider_2_ShowToken, v_1003379, v_1003380), [cps_provider_2_ShowTokText{"]"}])}}}
    case BIR.DescriptorNamedFill{v_31, v_32, v_33}:
      v_1003383 = {[cps_provider_2_ShowTokText{"f"}, cps_provider_2_ShowTokText{v_31}, cps_provider_2_ShowTokDesc{v_32}, cps_provider_2_ShowTokText{"["}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_33, True{}}}, False{}, v_1003386 => template_body_cps_provider_2_show_arg_tokens(v_33, True{}), v_1003385 => +v_1003384 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003385); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003383, List.append(&2, cps_provider_2_ShowToken, v_1003384, [cps_provider_2_ShowTokText{"]"}]))}}}
    case BIR.DescriptorNamedPlus{v_40, v_41, v_42}:
      v_1003387 = {[cps_provider_2_ShowTokText{"q"}, cps_provider_2_ShowTokText{v_40}, cps_provider_2_ShowTokDesc{v_41}, cps_provider_2_ShowTokText{"["}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_42, True{}}}, False{}, v_1003390 => template_body_cps_provider_2_show_arg_tokens(v_42, True{}), v_1003389 => +v_1003388 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003389); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003387, List.append(&2, cps_provider_2_ShowToken, v_1003388, [cps_provider_2_ShowTokText{"]"}]))}}}
    case BIR.DescriptorParameter{v_47}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"p"}, cps_provider_2_ShowTokText{Nat.show(v_47)}]}}
    case BIR.DescriptorNull{}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"n"}]}}
    case BIR.DescriptorKind{v_49}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"K"}, cps_provider_2_ShowTokDesc{v_49}]}}
    case BIR.DescriptorQuantity{v_51}:
      v_1003391 = {cps_provider_2_ShowTokText{"Q"} : cps_provider_2_ShowToken}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_quantity_key{v_51}}, False{}, v_1003394 => template_body_cps_provider_2_show_quantity_key(v_51), v_1003393 => +v_1003392 = template_unbox(String, v_1003393); TemplateFinished{TemplateValue{[v_1003391, cps_provider_2_ShowTokText{v_1003392}]}}}
    case BIR.DescriptorQuantityKind{}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"Z"}]}}
    case BIR.DescriptorMinimum{v_55, v_56}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"m"}, cps_provider_2_ShowTokDesc{v_55}, cps_provider_2_ShowTokDesc{v_56}]}}
    case BIR.DescriptorArrow{v_60, v_61, v_62}:
      v_1003395 = {cps_provider_2_ShowTokText{"A"} : cps_provider_2_ShowToken}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_quantity_key{v_60}}, False{}, v_1003398 => template_body_cps_provider_2_show_quantity_key(v_60), v_1003397 => +v_1003396 = template_unbox(String, v_1003397); TemplateFinished{TemplateValue{[v_1003395, cps_provider_2_ShowTokText{v_1003396}, cps_provider_2_ShowTokDesc{v_61}, cps_provider_2_ShowTokDesc{v_62}]}}}
    case BIR.DescriptorLambda{v_66, v_67}:
      v_1003399 = {cps_provider_2_ShowTokText{"L"} : cps_provider_2_ShowToken}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_maybe_quantity_key{v_66}}, False{}, v_1003402 => template_body_cps_provider_2_show_maybe_quantity_key(v_66), v_1003401 => +v_1003400 = template_unbox(String, v_1003401); TemplateFinished{TemplateValue{[v_1003399, cps_provider_2_ShowTokText{v_1003400}, cps_provider_2_ShowTokDesc{v_67}]}}}
    case BIR.DescriptorConstructor{v_71, v_72}:
      v_1003403 = {[cps_provider_2_ShowTokText{"C"}, cps_provider_2_ShowTokText{v_71}, cps_provider_2_ShowTokText{"("}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_72, True{}}}, False{}, v_1003406 => template_body_cps_provider_2_show_arg_tokens(v_72, True{}), v_1003405 => +v_1003404 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003405); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003403, List.append(&2, cps_provider_2_ShowToken, v_1003404, [cps_provider_2_ShowTokText{")"}]))}}}
    case BIR.DescriptorFailure{v_77}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"!"}, cps_provider_2_ShowTokText{v_77}]}}
    case BIR.DescriptorSubstitution{v_81, v_82, v_83}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"S"}, cps_provider_2_ShowTokText{Nat.show(v_81)}, cps_provider_2_ShowTokDesc{v_82}, cps_provider_2_ShowTokDesc{v_83}]}}
    case BIR.DescriptorLet{+v_86, v_87}:
      v_1003407 = {[cps_provider_2_ShowTokText{"E"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_86))}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_86, True{}}}, False{}, v_1003410 => template_body_cps_provider_2_show_arg_tokens(v_86, True{}), v_1003409 => +v_1003408 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003409); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003407, List.append(&2, cps_provider_2_ShowToken, v_1003408, [cps_provider_2_ShowTokDesc{v_87}]))}}}
    case BIR.DescriptorLocal{+v_94, +v_95, v_96}:
      v_1003411 = {[cps_provider_2_ShowTokText{"l"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.DescriptorPattern, v_94))}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_95))}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_pat_tokens{v_94, True{}}}, False{}, v_1003417 => template_body_cps_provider_2_show_pat_tokens(v_94, True{}), v_1003416 => +v_1003412 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003416); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_95, True{}}}, False{}, v_1003415 => template_body_cps_provider_2_show_arg_tokens(v_95, True{}), v_1003414 => +v_1003413 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003414); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003411, List.append(&2, cps_provider_2_ShowToken, v_1003412, List.append(&2, cps_provider_2_ShowToken, v_1003413, [cps_provider_2_ShowTokDesc{v_96}])))}}}}
    case BIR.DescriptorMatch{+v_104, +v_105}:
      v_1003418 = {[cps_provider_2_ShowTokText{"M"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_104))}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_105))}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_104, True{}}}, False{}, v_1003424 => template_body_cps_provider_2_show_arg_tokens(v_104, True{}), v_1003423 => +v_1003419 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003423); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arg_tokens{v_105, True{}}}, False{}, v_1003422 => template_body_cps_provider_2_show_arg_tokens(v_105, True{}), v_1003421 => +v_1003420 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003421); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003418, List.append(&2, cps_provider_2_ShowToken, v_1003419, v_1003420))}}}}
    case BIR.DescriptorCase{+v_112, v_113}:
      v_1003425 = {[cps_provider_2_ShowTokText{"c"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.DescriptorPattern, v_112))}] : List<&2, cps_provider_2_ShowToken>}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_pat_tokens{v_112, True{}}}, False{}, v_1003428 => template_body_cps_provider_2_show_pat_tokens(v_112, True{}), v_1003427 => +v_1003426 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003427); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowToken, v_1003425, List.append(&2, cps_provider_2_ShowToken, v_1003426, [cps_provider_2_ShowTokDesc{v_113}]))}}}
    case BIR.DescriptorBind{v_119, v_120}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"b"}, cps_provider_2_ShowTokDesc{v_119}, cps_provider_2_ShowTokDesc{v_120}]}}
    case BIR.DescriptorEquality{v_124, v_125, v_126}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"="}, cps_provider_2_ShowTokDesc{v_124}, cps_provider_2_ShowTokDesc{v_125}, cps_provider_2_ShowTokDesc{v_126}]}}
    case BIR.DescriptorReflexivity{}:
      TemplateFinished{TemplateValue{[cps_provider_2_ShowTokText{"r"}]}}

def template_match_842(+v_9: cps_provider_2_ShowToken, +v_10: List<&2, cps_provider_2_ShowToken>, +v_4: String) -> TemplateProgress<Maybe<&2, String>>:
  match v_9:
    case cps_provider_2_ShowTokText{+v_12}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_4, Nat.show(String.length(v_12)), ":", v_12]}}, False{}, v_1003434 => template_body_cps_provider_2_join_text([v_4, Nat.show(String.length(v_12)), ":", v_12]), v_1003433 => +v_1003430 = template_unbox(String, v_1003433); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_render_tokens{{v_10 : List<&2, cps_provider_2_ShowToken>}, v_1003430}}, v_1003432 => +v_1003431 = template_unbox(Maybe<&2, String>, v_1003432); TemplateFinished{TemplateValue{v_1003431}}}}
    case cps_provider_2_ShowTokDesc{v_16}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_desc_expand{v_16}}, False{}, v_1003439 => template_body_cps_provider_2_show_desc_expand(v_16), v_1003438 => +v_1003435 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003438); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_render_tokens{List.append(&2, cps_provider_2_ShowToken, v_1003435, v_10), v_4}}, v_1003437 => +v_1003436 = template_unbox(Maybe<&2, String>, v_1003437); TemplateFinished{TemplateValue{v_1003436}}}}
    case cps_provider_2_ShowTokPat{v_21}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_pat_expand{v_21}}, False{}, v_1003444 => template_body_cps_provider_2_show_pat_expand(v_21), v_1003443 => +v_1003440 = template_unbox(List<&2, cps_provider_2_ShowToken>, v_1003443); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_render_tokens{List.append(&2, cps_provider_2_ShowToken, v_1003440, v_10), v_4}}, v_1003442 => +v_1003441 = template_unbox(Maybe<&2, String>, v_1003442); TemplateFinished{TemplateValue{v_1003441}}}}

def template_body_cps_provider_2_show_render_tokens(+v_2: List<&2, cps_provider_2_ShowToken>, +v_4: String) -> TemplateProgress<Maybe<&2, String>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{Some{v_4}}}
    case +v_9 <> +v_10:
      template_match_842(v_9, v_10, v_4)

def template_body_cps_provider_2_show_descriptor_key(+v_0: BIR.Descriptor) -> TemplateProgress<Maybe<&2, String>>:
  TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_render_tokens{[cps_provider_2_ShowTokDesc{v_0}], ""}}, False{}, v_1003447 => template_body_cps_provider_2_show_render_tokens([cps_provider_2_ShowTokDesc{v_0}], ""), v_1003446 => +v_1003445 = template_unbox(Maybe<&2, String>, v_1003446); TemplateFinished{TemplateValue{v_1003445}}}

def template_continuation_844(+v_1003453: cps_provider_2_ShowState, +v_8: BIR.Descriptor, v_23: cps_provider_1_Layout, +v_10: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1003453, [cps_provider_2_ShowNode{v_8, v_23, Some{Nat.add(v_10, 1n)}}]}}}

def template_match_845(v_18: cps_provider_1_Cell, +v_12: cps_provider_2_ShowState, +v_8: BIR.Descriptor, +v_10: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_18:
    case cps_provider_1_Cell{v_23, v_24, v_25, v_26}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_12, 6n}}, False{}, v_1003459 => template_body_cps_provider_2_show_append_num(v_12, 6n), v_1003458 => +v_1003451 = template_unbox(cps_provider_2_ShowState, v_1003458); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1003451, 0n}}, False{}, v_1003457 => template_body_cps_provider_2_show_append_num(v_1003451, 0n), v_1003456 => +v_1003452 = template_unbox(cps_provider_2_ShowState, v_1003456); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1003452, v_26}}, False{}, v_1003455 => template_body_cps_provider_2_show_append_num(v_1003452, v_26), v_1003454 => +v_1003453 = template_unbox(cps_provider_2_ShowState, v_1003454); template_continuation_844(v_1003453, v_8, v_23, v_10)}}}

def template_body_cps_provider_2_show_array_cell(+v_1: cps_provider_1_CellResult, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case cps_provider_1_CellFailed{v_1004879}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_12, v_1004879}}, False{}, v_1004880 => template_body_cps_provider_2_show_state_error(v_12, v_1004879), v_1004881 => +v_1004882 = template_unbox(cps_provider_2_ShowState, v_1004881); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004882, []}}}}
    case cps_provider_1_CellFound{v_1004883}:
      template_match_845(v_1004883, v_12, v_8, v_10)

def template_continuation_847(+v_1003460: cps_provider_1_CellResult, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_array_cell(v_1003460, v_1, v_3, v_5, v_6, v_8, v_10)

def template_body_cps_provider_2_show_array_element(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_array_cell{v_1, v_6}}, False{}, v_1003463 => template_body_cps_provider_1_array_cell(v_1, v_6), v_1003462 => +v_1003460 = template_unbox(cps_provider_1_CellResult, v_1003462); template_continuation_847(v_1003460, v_1, v_3, v_5, v_6, v_8, v_10)}

def template_match_848(v_18: List<&2, BIR.Descriptor>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_18:
    case +v_21 <> +v_22:
      template_body_cps_provider_2_show_array_element(v_3, v_5, v_7, v_21, v_10, v_12)
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_12, "an Array descriptor without an element type cannot be printed"}}, False{}, v_1003470 => template_body_cps_provider_2_show_state_error(v_12, "an Array descriptor without an element type cannot be printed"), v_1003469 => +v_1003468 = template_unbox(cps_provider_2_ShowState, v_1003469); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1003468, []}}}}

def template_body_cps_provider_2_show_array_args(+v_1: cps_provider_1_ArgsResult, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case cps_provider_1_ArgsFailed{v_1004884}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_12, v_1004884}}, False{}, v_1004885 => template_body_cps_provider_2_show_state_error(v_12, v_1004884), v_1004886 => +v_1004887 = template_unbox(cps_provider_2_ShowState, v_1004886); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004887, []}}}}
    case cps_provider_1_ArgsOk{v_1004888}:
      template_match_848(v_1004888, v_3, v_5, v_7, v_10, v_12)

def template_continuation_850(+v_1003471: cps_provider_1_ArgsResult, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_array_args(v_1003471, v_1, v_3, v_5, v_6, v_8, v_10)

def template_body_cps_provider_2_show_advance_array(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_head_args{v_1, v_6}}, False{}, v_1003474 => template_body_cps_provider_1_head_args(v_1, v_6), v_1003473 => +v_1003471 = template_unbox(cps_provider_1_ArgsResult, v_1003473); template_continuation_850(v_1003471, v_1, v_3, v_5, v_6, v_8, v_10)}

def template_body_cps_provider_2_box_advance(+v_1: cps_provider_2_ShowJob, +v_3: cps_provider_2_ShowAdvance) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateFinished{TemplateValue{cps_provider_2_ShowNext{template_pure_cps_provider_2_show_next_state(v_3), List.append(&2, cps_provider_2_ShowJob, [v_1], template_pure_cps_provider_2_show_next_kids(v_3))}}}

def template_match_851(+v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_6, []}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_6, "a constructor node's slots and fields differ"}}, False{}, v_1003477 => template_body_cps_provider_2_show_state_error(v_6, "a constructor node's slots and fields differ"), v_1003476 => +v_1003475 = template_unbox(cps_provider_2_ShowState, v_1003476); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1003475, []}}}}

def template_match_852(+v_18: BIR.DescriptorField, v_25: cps_provider_1_Layout, +v_6: cps_provider_2_ShowState, +v_14: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, BIR.DescriptorField>, v_24: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_18:
    case BIR.DescriptorField{v_29, v_30, v_31}:
      +v_1003481 = {cps_provider_2_ShowNode{v_31, v_25, Some{Nat.add(List.length(&2, cps_provider_2_ShowWord, template_pure_cps_provider_2_show_words(v_6)), 1n)}} : cps_provider_2_ShowJob}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_6, v_24}}, False{}, v_1003492 => template_body_cps_provider_2_show_append_num(v_6, v_24), v_1003491 => +v_1003484 = template_unbox(cps_provider_2_ShowState, v_1003491); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1003484, 0n}}, False{}, v_1003490 => template_body_cps_provider_2_show_append_num(v_1003484, 0n), v_1003489 => +v_1003485 = template_unbox(cps_provider_2_ShowState, v_1003489); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_fields_box_each{{v_14 : List<&2, cps_provider_1_NodeSlot>}, {v_19 : List<&2, BIR.DescriptorField>}, v_1003485}}, v_1003488 => +v_1003486 = template_unbox(cps_provider_2_ShowAdvance, v_1003488); template_body_cps_provider_2_box_advance(v_1003481, v_1003486)}}}

def template_match_853(+v_13: cps_provider_1_NodeSlot, +v_18: BIR.DescriptorField, +v_6: cps_provider_2_ShowState, +v_14: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, BIR.DescriptorField>) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_13:
    case cps_provider_1_NodeSlot{v_23, v_24, v_25}:
      template_match_852(v_18, v_25, v_6, v_14, v_19, v_24)

def template_match_854(+v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState, +v_13: cps_provider_1_NodeSlot, +v_14: List<&2, cps_provider_1_NodeSlot>) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_4:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_6, "a constructor node's slots and fields differ"}}, False{}, v_1003480 => template_body_cps_provider_2_show_state_error(v_6, "a constructor node's slots and fields differ"), v_1003479 => +v_1003478 = template_unbox(cps_provider_2_ShowState, v_1003479); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1003478, []}}}}
    case +v_18 <> +v_19:
      template_match_853(v_13, v_18, v_6, v_14, v_19)

def template_body_cps_provider_2_fields_box_each(+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_2:
    case []:
      template_match_851(v_4, v_6)
    case +v_13 <> +v_14:
      template_match_854(v_4, v_6, v_13, v_14)

def template_body_cps_provider_2_fields_box_slots(+v_3: Maybe<&2, List<&2, cps_provider_1_NodeSlot>>, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_3:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_7, "a constructor node has no slots for SHOW"}}, False{}, v_1004889 => template_body_cps_provider_2_show_state_error(v_7, "a constructor node has no slots for SHOW"), v_1004890 => +v_1004891 = template_unbox(cps_provider_2_ShowState, v_1004890); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004891, []}}}}
    case Some{v_1004892}:
      template_body_cps_provider_2_fields_box_each(v_1004892, v_5, v_7)

def template_continuation_857(+v_1003498: Maybe<&2, List<&2, cps_provider_1_NodeSlot>>, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_fields_box_slots(v_1003498, v_5, v_7)

def template_continuation_858(+v_1003497: cps_provider_1_NodeResult, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  v_11 = v_1003497
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_node_layout_slots{v_11}}, False{}, v_1003501 => template_body_cps_provider_2_show_node_layout_slots(v_11), v_1003500 => +v_1003498 = template_unbox(Maybe<&2, List<&2, cps_provider_1_NodeSlot>>, v_1003500); template_continuation_857(v_1003498, v_5, v_7)}

def template_body_cps_provider_2_fields_box(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_node_layout{v_1, v_3}}, False{}, v_1003503 => template_body_cps_provider_1_node_layout(v_1, v_3), v_1003502 => +v_1003497 = template_unbox(cps_provider_1_NodeResult, v_1003502); template_continuation_858(v_1003497, v_5, v_7)}

def template_match_859(+v_4: List<&2, BIR.DescriptorField>, +v_8: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_8, []}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_8, "an inline arm's fields and layouts differ"}}, False{}, v_1003506 => template_body_cps_provider_2_show_state_error(v_8, "an inline arm's fields and layouts differ"), v_1003505 => +v_1003504 = template_unbox(cps_provider_2_ShowState, v_1003505); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1003504, []}}}}

def template_continuation_860(+v_1003516: cps_provider_2_ShowAdvance, v_27: BIR.Descriptor, +v_15: cps_provider_1_Layout, v_31: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateFinished{TemplateValue{cps_provider_2_ShowNext{template_pure_cps_provider_2_show_next_state(v_1003516), List.append(&2, cps_provider_2_ShowJob, [cps_provider_2_ShowNode{v_27, v_15, Some{v_31}}], template_pure_cps_provider_2_show_next_kids(v_1003516))}}}

def template_continuation_861(+v_1003511: cps_provider_2_ShowState, +v_16: List<&2, cps_provider_1_Layout>, +v_21: List<&2, BIR.DescriptorField>, +v_6: Nat, +v_15: cps_provider_1_Layout, v_27: BIR.Descriptor, v_31: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_layout_words{v_15}}, False{}, v_1003519 => template_body_cps_provider_1_layout_words(v_15), v_1003518 => +v_1003515 = template_unbox(Nat, v_1003518); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_fields_inline_each{{v_16 : List<&2, cps_provider_1_Layout>}, {v_21 : List<&2, BIR.DescriptorField>}, Nat.add({v_6 : Nat}, v_1003515), v_1003511}}, v_1003517 => +v_1003516 = template_unbox(cps_provider_2_ShowAdvance, v_1003517); template_continuation_860(v_1003516, v_27, v_15, v_31)}}

def template_match_862(+v_20: BIR.DescriptorField, +v_8: cps_provider_2_ShowState, +v_6: Nat, +v_16: List<&2, cps_provider_1_Layout>, +v_21: List<&2, BIR.DescriptorField>, +v_15: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_20:
    case BIR.DescriptorField{v_25, v_26, v_27}:
      v_31 = Nat.add(List.length(&2, cps_provider_2_ShowWord, template_pure_cps_provider_2_show_words(v_8)), 1n)
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_8, v_6}}, False{}, v_1003523 => template_body_cps_provider_2_show_append_num(v_8, v_6), v_1003522 => +v_1003510 = template_unbox(cps_provider_2_ShowState, v_1003522); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1003510, 0n}}, False{}, v_1003521 => template_body_cps_provider_2_show_append_num(v_1003510, 0n), v_1003520 => +v_1003511 = template_unbox(cps_provider_2_ShowState, v_1003520); template_continuation_861(v_1003511, v_16, v_21, v_6, v_15, v_27, v_31)}}

def template_match_863(+v_4: List<&2, BIR.DescriptorField>, +v_8: cps_provider_2_ShowState, +v_6: Nat, +v_16: List<&2, cps_provider_1_Layout>, +v_15: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_4:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_8, "an inline arm's fields and layouts differ"}}, False{}, v_1003509 => template_body_cps_provider_2_show_state_error(v_8, "an inline arm's fields and layouts differ"), v_1003508 => +v_1003507 = template_unbox(cps_provider_2_ShowState, v_1003508); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1003507, []}}}}
    case +v_20 <> +v_21:
      template_match_862(v_20, v_8, v_6, v_16, v_21, v_15)

def template_body_cps_provider_2_fields_inline_each(+v_2: List<&2, cps_provider_1_Layout>, +v_4: List<&2, BIR.DescriptorField>, +v_6: Nat, +v_8: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_2:
    case []:
      template_match_859(v_4, v_8)
    case +v_1004893 <> +v_1004894:
      template_match_863(v_4, v_8, v_6, v_1004894, v_1004893)

def template_body_cps_provider_2_fields_inline_layouts(+v_3: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_5: List<&2, BIR.DescriptorField>, +v_7: Nat, +v_9: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_3:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_9, "the inline layout has no SHOW arm"}}, False{}, v_1004895 => template_body_cps_provider_2_show_state_error(v_9, "the inline layout has no SHOW arm"), v_1004896 => +v_1004897 = template_unbox(cps_provider_2_ShowState, v_1004896); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004897, []}}}}
    case Some{v_1004898}:
      template_body_cps_provider_2_fields_inline_each(v_1004898, v_5, v_7, v_9)

def template_continuation_866(+v_1003528: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_5: List<&2, BIR.DescriptorField>, +v_11: Nat, +v_13: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_fields_inline_layouts(v_1003528, v_5, v_11, v_13)

def template_body_cps_provider_2_fields_inline(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_1_Layout, +v_9: Nat, +v_11: Nat, +v_13: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arm_layouts{v_7, v_3}}, False{}, v_1003531 => template_body_cps_provider_2_show_arm_layouts(v_7, v_3), v_1003530 => +v_1003528 = template_unbox(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_1003530); template_continuation_866(v_1003528, v_5, v_11, v_13)}

def template_body_cps_provider_2_fields_advance(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_7: String, +v_9: List<&2, BIR.DescriptorField>, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_13:
    case 1n:
      template_body_cps_provider_2_fields_box(v_1, v_7, v_9, v_17)
    case v_1004899:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_tag_start{v_13, v_15}}, False{}, v_1004905 => template_body_cps_provider_2_show_tag_start(v_13, v_15), v_1004906 => +v_1004907 = template_unbox(Nat, v_1004906); template_body_cps_provider_2_fields_inline({v_1 : cps_provider_1_Context}, {v_7 : String}, {v_9 : List<&2, BIR.DescriptorField>}, {v_11 : cps_provider_1_Layout}, {v_15 : Nat}, v_1004907, v_17)}

def template_body_cps_provider_2_show_data_arm_header(+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_1_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_cid_of_key{v_3, v_9}}, False{}, v_1003546 => template_body_cps_provider_2_show_cid_of_key(v_3, v_9), v_1003545 => +v_1003542 = template_unbox(Maybe<&2, Nat>, v_1003545); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_data_arm_cid{v_1003542, v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_19, v_21}}, v_1003544 => +v_1003543 = template_unbox(cps_provider_2_ShowAdvance, v_1003544); TemplateFinished{TemplateValue{v_1003543}}}}

def template_match_868(+v_1003547: cps_provider_2_ShowAdvance, v_22: List<&2, cps_provider_2_ShowJob>) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1003547:
    case cps_provider_2_ShowNext{v_26, v_27}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_26, List.append(&2, cps_provider_2_ShowJob, v_22, v_27)}}}

def template_body_cps_provider_2_show_data_arm_rest(+v_1: cps_provider_2_ShowAdvance, +v_3: List<&2, BIR.DescriptorArm>, +v_5: cps_provider_1_Context, +v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, +v_11: cps_provider_3_NfVal, +v_13: cps_provider_1_Layout, +v_15: Nat, +v_17: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case cps_provider_2_ShowNext{v_21, v_22}:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_data_arms{v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_21}}, v_1003548 => +v_1003547 = template_unbox(cps_provider_2_ShowAdvance, v_1003548); template_match_868(v_1003547, v_22)}

def template_continuation_870(+v_1003562: cps_provider_2_ShowState, +v_10: cps_provider_1_Context, +v_12: List<&2, BIR.ConstructorLayout>, +v_14: List<&2, BIR.Family>, +v_6: String, +v_4: List<&2, BIR.DescriptorField>, +v_18: cps_provider_1_Layout, +v_20: Nat, +v_22: Nat, +v_8: List<&2, BIR.DescriptorArm>, +v_16: cps_provider_3_NfVal) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  v_43 = v_1003562
  TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_fields_advance{v_10, v_12, v_14, v_6, v_4, v_18, v_20, v_22, v_43}}, False{}, v_1003566 => template_body_cps_provider_2_fields_advance(v_10, v_12, v_14, v_6, v_4, v_18, v_20, v_22, v_43), v_1003565 => +v_1003563 = template_unbox(cps_provider_2_ShowAdvance, v_1003565); template_body_cps_provider_2_show_data_arm_rest(v_1003563, v_8, v_10, v_12, v_14, v_16, v_18, v_20, v_22)}

def template_continuation_871(+v_1003558: cps_provider_2_ShowState, +v_6: String, +v_10: cps_provider_1_Context, +v_12: List<&2, BIR.ConstructorLayout>, +v_14: List<&2, BIR.Family>, +v_4: List<&2, BIR.DescriptorField>, +v_18: cps_provider_1_Layout, +v_20: Nat, +v_22: Nat, +v_8: List<&2, BIR.DescriptorArm>, +v_16: cps_provider_3_NfVal) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  +v_1003559 = {v_1003558 : cps_provider_2_ShowState}
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_arm_bracket{v_6}}, False{}, v_1003572 => template_body_cps_provider_2_show_arm_bracket(v_6), v_1003571 => +v_1003560 = template_unbox(Nat, v_1003571); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1003559, v_1003560}}, False{}, v_1003570 => template_body_cps_provider_2_show_append_num(v_1003559, v_1003560), v_1003569 => +v_1003561 = template_unbox(cps_provider_2_ShowState, v_1003569); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_name{v_1003561, v_6}}, False{}, v_1003568 => template_body_cps_provider_2_show_append_name(v_1003561, v_6), v_1003567 => +v_1003562 = template_unbox(cps_provider_2_ShowState, v_1003567); template_continuation_870(v_1003562, v_10, v_12, v_14, v_6, v_4, v_18, v_20, v_22, v_8, v_16)}}}

def template_body_cps_provider_2_show_data_arm_cid(+v_2: Maybe<&2, Nat>, +v_4: List<&2, BIR.DescriptorField>, +v_6: String, +v_8: List<&2, BIR.DescriptorArm>, +v_10: cps_provider_1_Context, +v_12: List<&2, BIR.ConstructorLayout>, +v_14: List<&2, BIR.Family>, +v_16: cps_provider_3_NfVal, +v_18: cps_provider_1_Layout, +v_20: Nat, +v_22: Nat, +v_24: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_2:
    case None{}:
      +v_1004908 = {v_24 : cps_provider_2_ShowState}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the constructor `", v_6, "` has no assigned C id"]}}, False{}, v_1004909 => template_body_cps_provider_2_join_text(["the constructor `", v_6, "` has no assigned C id"]), v_1004910 => +v_1004911 = template_unbox(String, v_1004910); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_1004908, v_1004911}}, False{}, v_1004912 => template_body_cps_provider_2_show_state_error(v_1004908, v_1004911), v_1004913 => +v_1004914 = template_unbox(cps_provider_2_ShowState, v_1004913); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004914, []}}}}}
    case Some{v_1004915}:
      v_1004916 = List.length(&2, String, template_pure_cps_provider_2_show_names(v_24))
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_24, v_1004916}}, False{}, v_1004917 => template_body_cps_provider_2_show_append_num(v_24, v_1004916), v_1004918 => +v_1004919 = template_unbox(cps_provider_2_ShowState, v_1004918); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_cid{v_1004919, v_1004915}}, False{}, v_1004920 => template_body_cps_provider_2_show_append_cid(v_1004919, v_1004915), v_1004921 => +v_1004922 = template_unbox(cps_provider_2_ShowState, v_1004921); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1004922, List.length(&2, BIR.DescriptorField, v_4)}}, False{}, v_1004923 => template_body_cps_provider_2_show_append_num(v_1004922, List.length(&2, BIR.DescriptorField, v_4)), v_1004924 => +v_1004925 = template_unbox(cps_provider_2_ShowState, v_1004924); template_continuation_871(v_1004925, v_6, v_10, v_12, v_14, v_4, v_18, v_20, v_22, v_8, v_16)}}}

def template_body_cps_provider_2_show_data_arm_erased(+v_1: Bool, +v_3: List<&2, BIR.DescriptorField>, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_9: cps_provider_1_Context, +v_11: List<&2, BIR.ConstructorLayout>, +v_13: List<&2, BIR.Family>, +v_15: cps_provider_3_NfVal, +v_17: cps_provider_1_Layout, +v_19: Nat, +v_21: Nat, +v_23: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_23, "main's type has an erased field and cannot be printed"}}, False{}, v_1004926 => template_body_cps_provider_2_show_state_error(v_23, "main's type has an erased field and cannot be printed"), v_1004927 => +v_1004928 = template_unbox(cps_provider_2_ShowState, v_1004927); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004928, []}}}}
    case False{}:
      template_body_cps_provider_2_show_data_arm_header(v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_23)

def template_continuation_874(+v_1003583: Bool, +v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_1_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_data_arm_erased(v_1003583, v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_19, v_21)

def template_body_cps_provider_2_show_data_arm_live(+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_1_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_erased_present{v_1}}, False{}, v_1003586 => template_body_cps_provider_2_show_erased_present(v_1), v_1003585 => +v_1003583 = template_unbox(Bool, v_1003585); template_continuation_874(v_1003583, v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_19, v_21)}

def template_body_cps_provider_2_show_data_arm(+v_1: cps_provider_1_FieldsResult, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_1_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case cps_provider_1_FieldsFailed{v_1004929}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_21, v_1004929}}, False{}, v_1004930 => template_body_cps_provider_2_show_state_error(v_21, v_1004929), v_1004931 => +v_1004932 = template_unbox(cps_provider_2_ShowState, v_1004931); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004932, []}}}}
    case cps_provider_1_FieldsFound{v_1004933}:
      template_body_cps_provider_2_show_data_arm_live(v_1004933, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_19, v_21)

def template_continuation_876(+v_1003591: cps_provider_1_FieldsResult, v_25: String, +v_22: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_data_arm(v_1003591, v_25, v_22, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17)

def template_match_877(+v_21: BIR.DescriptorArm, +v_3: cps_provider_1_Context, +v_9: cps_provider_3_NfVal, +v_22: List<&2, BIR.DescriptorArm>, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_21:
    case BIR.DescriptorArm{+v_25, v_26}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_arm_fields_value{v_3, v_25, v_9}}, False{}, v_1003594 => template_body_cps_provider_1_arm_fields_value(v_3, v_25, v_9), v_1003593 => +v_1003591 = template_unbox(cps_provider_1_FieldsResult, v_1003593); template_continuation_876(v_1003591, v_25, v_22, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17)}

def template_body_cps_provider_2_show_data_arms(+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_17, []}}}
    case +v_1004934 <> +v_1004935:
      template_match_877(v_1004934, v_3, v_9, v_1004935, v_5, v_7, v_11, v_13, v_15, v_17)

def template_continuation_879(+v_1003598: cps_provider_2_ShowState, +v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, v_19: Nat, v_21: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_data_arms(v_1, v_3, v_5, v_7, v_9, v_11, v_19, v_21, v_1003598)

def template_continuation_880(+v_1003595: Nat, +v_1: List<&2, BIR.DescriptorArm>, +v_15: cps_provider_2_ShowState, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  +v_21 = List.length(&2, BIR.DescriptorArm, v_1)
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_15, 7n}}, False{}, v_1003605 => template_body_cps_provider_2_show_append_num(v_15, 7n), v_1003604 => +v_1003596 = template_unbox(cps_provider_2_ShowState, v_1003604); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1003596, v_1003595}}, False{}, v_1003603 => template_body_cps_provider_2_show_append_num(v_1003596, v_1003595), v_1003602 => +v_1003597 = template_unbox(cps_provider_2_ShowState, v_1003602); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1003597, v_21}}, False{}, v_1003601 => template_body_cps_provider_2_show_append_num(v_1003597, v_21), v_1003600 => +v_1003598 = template_unbox(cps_provider_2_ShowState, v_1003600); template_continuation_879(v_1003598, v_1, v_3, v_5, v_7, v_9, v_11, v_1003595, v_21)}}}

def template_body_cps_provider_2_show_data_count(+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_box_flag{v_11}}, False{}, v_1003607 => template_body_cps_provider_2_show_box_flag(v_11), v_1003606 => +v_1003595 = template_unbox(Nat, v_1003606); template_continuation_880(v_1003595, v_1, v_15, v_3, v_5, v_7, v_9, v_11)}

def template_body_cps_provider_2_show_data_arms_maybe(+v_2: Maybe<&2, List<&2, BIR.DescriptorArm>>, +v_4: cps_provider_1_Context, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>, +v_10: cps_provider_3_NfVal, +v_12: cps_provider_1_Layout, +v_14: Nat, +v_16: cps_provider_2_ShowState, +v_18: String) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_2:
    case None{}:
      +v_1004936 = {v_16 : cps_provider_2_ShowState}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{["the datatype `", v_18, "` has no constructors"]}}, False{}, v_1004937 => template_body_cps_provider_2_join_text(["the datatype `", v_18, "` has no constructors"]), v_1004938 => +v_1004939 = template_unbox(String, v_1004938); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_1004936, v_1004939}}, False{}, v_1004940 => template_body_cps_provider_2_show_state_error(v_1004936, v_1004939), v_1004941 => +v_1004942 = template_unbox(cps_provider_2_ShowState, v_1004941); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004942, []}}}}}
    case Some{v_1004943}:
      template_body_cps_provider_2_show_data_count(v_1004943, v_4, v_6, v_8, v_10, v_12, v_14, v_16)

def template_continuation_882(+v_1003616: Maybe<&2, List<&2, BIR.DescriptorArm>>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: cps_provider_2_ShowState, +v_1: String) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_data_arms_maybe(v_1003616, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_1)

def template_body_cps_provider_2_show_data_key(+v_1: String, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_family_arms{v_1, v_7}}, False{}, v_1003619 => template_body_cps_provider_2_family_arms(v_1, v_7), v_1003618 => +v_1003616 = template_unbox(Maybe<&2, List<&2, BIR.DescriptorArm>>, v_1003618); template_continuation_882(v_1003616, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_1)}

def template_body_cps_provider_2_show_data_head(+v_1: cps_provider_1_HeadResult, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_9: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case cps_provider_1_HeadFailed{v_1004944}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_15, v_1004944}}, False{}, v_1004945 => template_body_cps_provider_2_show_state_error(v_15, v_1004944), v_1004946 => +v_1004947 = template_unbox(cps_provider_2_ShowState, v_1004946); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004947, []}}}}
    case cps_provider_1_HeadEquality{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_15, "the equality type has no data arms to print"}}, False{}, v_1004948 => template_body_cps_provider_2_show_state_error(v_15, "the equality type has no data arms to print"), v_1004949 => +v_1004950 = template_unbox(cps_provider_2_ShowState, v_1004949); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004950, []}}}}
    case cps_provider_1_HeadBoxed{v_1004951}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_15, "main's type is abstract or open and cannot be printed"}}, False{}, v_1004952 => template_body_cps_provider_2_show_state_error(v_15, "main's type is abstract or open and cannot be printed"), v_1004953 => +v_1004954 = template_unbox(cps_provider_2_ShowState, v_1004953); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004954, []}}}}
    case cps_provider_1_HeadFound{v_1004955, v_1004956}:
      template_body_cps_provider_2_show_data_key(v_1004955, v_3, v_5, v_7, v_9, v_11, v_13, v_15)

def template_continuation_884(+v_1003634: cps_provider_1_HeadResult, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_19: cps_provider_3_NfVal, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_data_head(v_1003634, v_1, v_3, v_5, v_19, v_8, v_10, v_12)

def template_match_885(+v_1003630: cps_provider_3_Nf, +v_12: cps_provider_2_ShowState, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_8: cps_provider_1_Layout, +v_10: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1003630:
    case cps_provider_3_NfFail{v_16}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_12, v_16}}, False{}, v_1003633 => template_body_cps_provider_2_show_state_error(v_12, v_16), v_1003632 => +v_1003631 = template_unbox(cps_provider_2_ShowState, v_1003632); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1003631, []}}}}
    case cps_provider_3_NfOk{+v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_head_value{v_1, v_19}}, False{}, v_1003637 => template_body_cps_provider_1_head_value(v_1, v_19), v_1003636 => +v_1003634 = template_unbox(cps_provider_1_HeadResult, v_1003636); template_continuation_884(v_1003634, v_1, v_3, v_5, v_19, v_8, v_10, v_12)}

def template_body_cps_provider_2_show_advance_data(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_nf_of{v_1, v_6, [], 1024n}}, False{}, v_1003639 => template_body_cps_provider_1_nf_of(v_1, v_6, [], 1024n), v_1003638 => +v_1003630 = template_unbox(cps_provider_3_Nf, v_1003638); template_match_885(v_1003630, v_12, v_1, v_3, v_5, v_8, v_10)}

def template_body_cps_provider_2_show_advance_n(+v_1: Nat, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_1_Layout, +v_12: Nat, +v_14: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case 3n:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_14, 3n}}, False{}, v_1004957 => template_body_cps_provider_2_show_append_num(v_14, 3n), v_1004958 => +v_1004959 = template_unbox(cps_provider_2_ShowState, v_1004958); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_box_flag{v_10}}, False{}, v_1004960 => template_body_cps_provider_2_show_box_flag(v_10), v_1004961 => +v_1004962 = template_unbox(Nat, v_1004961); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_1004959, v_1004962}}, False{}, v_1004963 => template_body_cps_provider_2_show_append_num(v_1004959, v_1004962), v_1004964 => +v_1004965 = template_unbox(cps_provider_2_ShowState, v_1004964); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004965, []}}}}}}
    case 6n:
      template_body_cps_provider_2_show_advance_array(v_3, v_5, v_7, v_8, v_12, v_14)
    case 7n:
      template_body_cps_provider_2_show_advance_data(v_3, v_5, v_7, v_8, v_10, v_12, v_14)
    case v_1004966:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_append_num{v_14, v_1}}, False{}, v_1004967 => template_body_cps_provider_2_show_append_num(v_14, v_1), v_1004968 => +v_1004969 = template_unbox(cps_provider_2_ShowState, v_1004968); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004969, []}}}}

def template_body_cps_provider_2_show_advance_kind(+v_1: cps_provider_2_ShowKind, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_1_Layout, +v_12: Nat, +v_14: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case cps_provider_2_ShowKindFailed{v_1004970}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_14, v_1004970}}, False{}, v_1004971 => template_body_cps_provider_2_show_state_error(v_14, v_1004970), v_1004972 => +v_1004973 = template_unbox(cps_provider_2_ShowState, v_1004972); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004973, []}}}}
    case cps_provider_2_ShowKindOk{v_1004974}:
      template_body_cps_provider_2_show_advance_n(v_1004974, v_3, v_5, v_7, v_8, v_10, v_12, v_14)

def template_continuation_888(+v_1003663: cps_provider_2_ShowKind, +v_6: cps_provider_1_Context, +v_8: List<&2, BIR.ConstructorLayout>, +v_10: List<&2, BIR.Family>, +v_11: BIR.Descriptor, +v_13: cps_provider_1_Layout, v_26: Nat, v_34: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_advance_kind(v_1003663, v_6, v_8, v_10, v_11, v_13, v_26, v_34)

def template_continuation_889(+v_1003662: cps_provider_2_ShowState, +v_6: cps_provider_1_Context, +v_11: BIR.Descriptor, +v_8: List<&2, BIR.ConstructorLayout>, +v_10: List<&2, BIR.Family>, +v_13: cps_provider_1_Layout, v_26: Nat) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_kind{v_6, v_11}}, False{}, v_1003666 => template_body_cps_provider_2_show_kind(v_6, v_11), v_1003665 => +v_1003663 = template_unbox(cps_provider_2_ShowKind, v_1003665); template_continuation_888(v_1003663, v_6, v_8, v_10, v_11, v_13, v_26, v_1003662)}

def template_body_cps_provider_2_show_advance_memo(+v_2: Maybe<&2, Nat>, +v_4: String, +v_6: cps_provider_1_Context, +v_8: List<&2, BIR.ConstructorLayout>, +v_10: List<&2, BIR.Family>, +v_11: BIR.Descriptor, +v_13: cps_provider_1_Layout, +v_16: Maybe<&2, Nat>, +v_18: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_2:
    case Some{v_1004975}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_apply_patch{v_18, v_16, v_1004975}}, False{}, v_1004976 => template_body_cps_provider_2_show_apply_patch(v_18, v_16, v_1004975), v_1004977 => +v_1004978 = template_unbox(cps_provider_2_ShowState, v_1004977); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004978, []}}}}
    case None{}:
      +v_1004979 = List.length(&2, cps_provider_2_ShowWord, template_pure_cps_provider_2_show_words(v_18))
      v_1004980 = Map.set(&2, Nat, template_pure_cps_provider_2_show_memo(v_18), v_4, v_1004979)
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_set_memo{v_18, v_1004980}}, False{}, v_1004981 => template_body_cps_provider_2_show_state_set_memo(v_18, v_1004980), v_1004982 => +v_1004983 = template_unbox(cps_provider_2_ShowState, v_1004982); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_apply_patch{v_1004983, v_16, v_1004979}}, False{}, v_1004984 => template_body_cps_provider_2_show_apply_patch(v_1004983, v_16, v_1004979), v_1004985 => +v_1004986 = template_unbox(cps_provider_2_ShowState, v_1004985); template_continuation_889(v_1004986, v_6, v_11, v_8, v_10, v_13, v_1004979)}}

def template_body_cps_provider_2_show_advance_norm(+v_1: cps_provider_2_ShowNorm, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_1_Layout, +v_13: Maybe<&2, Nat>, +v_15: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_1:
    case cps_provider_2_ShowNormFailed{v_1004987}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_15, v_1004987}}, False{}, v_1004988 => template_body_cps_provider_2_show_state_error(v_15, v_1004987), v_1004989 => +v_1004990 = template_unbox(cps_provider_2_ShowState, v_1004989); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004990, []}}}}
    case cps_provider_2_ShowNormOk{v_1004991}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_descriptor_key{v_1004991}}, False{}, v_1004992 => template_body_cps_provider_2_show_descriptor_key(v_1004991), v_1004993 => +v_1004994 = template_unbox(Maybe<&2, String>, v_1004993); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_advance_key{v_1004994, v_3, v_5, v_7, v_8, v_10, v_13, v_15}}, v_1004995 => +v_1004996 = template_unbox(cps_provider_2_ShowAdvance, v_1004995); TemplateFinished{TemplateValue{v_1004996}}}}

def template_continuation_892(+v_1003686: String, +v_16: cps_provider_2_ShowState, +v_4: cps_provider_1_Context, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>, +v_9: BIR.Descriptor, +v_11: cps_provider_1_Layout, +v_14: Maybe<&2, Nat>) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  v_28 = IndexLookup.find(Nat, template_pure_cps_provider_2_show_memo(v_16), v_1003686)
  template_body_cps_provider_2_show_advance_memo(v_28, v_1003686, v_4, v_6, v_8, v_9, v_11, v_14, v_16)

def template_body_cps_provider_2_show_advance_key(+v_2: Maybe<&2, String>, +v_4: cps_provider_1_Context, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>, +v_9: BIR.Descriptor, +v_11: cps_provider_1_Layout, +v_14: Maybe<&2, Nat>, +v_16: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_2:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state_error{v_16, "the show descriptor key did not finish"}}, False{}, v_1004997 => template_body_cps_provider_2_show_state_error(v_16, "the show descriptor key did not finish"), v_1004998 => +v_1004999 = template_unbox(cps_provider_2_ShowState, v_1004998); TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_1004999, []}}}}
    case Some{+v_1005000}:
      v_1005001 = {Nat.show(String.length(v_1005000)) : String}
      v_1005002 = {":" : String}
      v_1005003 = {v_1005000 : String}
      TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_layout_key{v_11}}, False{}, v_1005004 => template_body_cps_provider_2_show_layout_key(v_11), v_1005005 => +v_1005006 = template_unbox(String, v_1005005); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_cps_provider_2_join_text{[v_1005001, v_1005002, v_1005003, v_1005006]}}, False{}, v_1005007 => template_body_cps_provider_2_join_text([v_1005001, v_1005002, v_1005003, v_1005006]), v_1005008 => +v_1005009 = template_unbox(String, v_1005008); template_continuation_892(v_1005009, v_16, v_4, v_6, v_8, v_9, v_11, v_14)}}

def template_body_cps_provider_2_show_norm_result(+v_1: cps_provider_1_NormResult) -> TemplateProgress<cps_provider_2_ShowNorm>:
  match v_1:
    case cps_provider_1_NormOk{v_4}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowNormOk{v_4}}}
    case cps_provider_1_NormFailed{v_6}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowNormFailed{v_6}}}

def template_body_cps_provider_2_show_norm(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> TemplateProgress<cps_provider_2_ShowNorm>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_cps_provider_1_norm{v_1, v_2}}, False{}, v_1003695 => template_body_cps_provider_1_norm(v_1, v_2), v_1003694 => +v_1003692 = template_unbox(cps_provider_1_NormResult, v_1003694); template_body_cps_provider_2_show_norm_result(v_1003692)}

def template_continuation_895(+v_1003696: cps_provider_2_ShowNorm, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_11: Maybe<&2, Nat>, +v_16: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  template_body_cps_provider_2_show_advance_norm(v_1003696, v_1, v_3, v_5, v_6, v_8, v_11, v_16)

def template_body_cps_provider_2_show_advance_error(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_11: Maybe<&2, Nat>, +v_14: Maybe<&2, String>, +v_16: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_14:
    case Some{v_1005010}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowNext{v_16, []}}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_norm{v_1, v_6}}, False{}, v_1005011 => template_body_cps_provider_2_show_norm(v_1, v_6), v_1005012 => +v_1005013 = template_unbox(cps_provider_2_ShowNorm, v_1005012); template_continuation_895(v_1005013, v_1, v_3, v_5, v_6, v_8, v_11, v_16)}

def template_body_cps_provider_2_show_advance_st(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_11: Maybe<&2, Nat>, +v_13: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_13:
    case cps_provider_2_ShowState{v_1005014, v_1005015, v_1005016, v_1005017, v_1005018}:
      template_body_cps_provider_2_show_advance_error(v_1, v_3, v_5, v_6, v_8, v_11, v_1005018, v_13)

def template_body_cps_provider_2_show_advance_job(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_7: cps_provider_2_ShowJob, +v_9: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowAdvance>:
  match v_7:
    case cps_provider_2_ShowNode{v_1005019, v_1005020, v_1005021}:
      template_body_cps_provider_2_show_advance_st(v_1, v_3, v_5, v_1005019, v_1005020, v_1005021, v_9)

def template_continuation_899(+v_1003702: cps_provider_2_ShowAdvance, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_15: List<&2, cps_provider_2_ShowJob>) -> TemplateProgress<cps_provider_2_ShowRun>:
  TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_run_show{v_1, v_3, v_5, List.append(&2, cps_provider_2_ShowJob, template_pure_cps_provider_2_show_next_kids(v_1003702), v_15), template_pure_cps_provider_2_show_next_state(v_1003702)}}, v_1003704 => +v_1003703 = template_unbox(cps_provider_2_ShowRun, v_1003704); TemplateFinished{TemplateValue{v_1003703}}}

def template_body_cps_provider_2_run_show(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_8: List<&2, cps_provider_2_ShowJob>, +v_10: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowRun>:
  match v_8:
    case []:
      TemplateFinished{TemplateValue{cps_provider_2_ShowDone{v_10}}}
    case +v_1005022 <> +v_1005023:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_advance_job{v_1, v_3, v_5, v_1005022, v_10}}, False{}, v_1005024 => template_body_cps_provider_2_show_advance_job(v_1, v_3, v_5, v_1005022, v_10), v_1005025 => +v_1005026 = template_unbox(cps_provider_2_ShowAdvance, v_1005025); template_continuation_899(v_1005026, v_1, v_3, v_5, v_1005023)}

def template_match_901(v_1003707: Bool, +v_13: cps_provider_2_ShowWord, +v_14: List<&2, cps_provider_2_ShowWord>, +v_4: Nat, +v_6: cps_provider_2_ShowWord, +v_8: Nat) -> TemplateProgress<List<&2, cps_provider_2_ShowWord>>:
  match v_1003707:
    case False{}:
      v_1003708 = {[v_13] : List<&2, cps_provider_2_ShowWord>}
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_set_word{v_14, v_4, v_6, Nat.add(v_8, 1n)}}, v_1003710 => +v_1003709 = template_unbox(List<&2, cps_provider_2_ShowWord>, v_1003710); TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowWord, v_1003708, v_1003709)}}}
    case True{}:
      TemplateFinished{TemplateValue{List.append(&2, cps_provider_2_ShowWord, [v_6], v_14)}}

def template_body_cps_provider_2_show_set_word(+v_2: List<&2, cps_provider_2_ShowWord>, +v_4: Nat, +v_6: cps_provider_2_ShowWord, +v_8: Nat) -> TemplateProgress<List<&2, cps_provider_2_ShowWord>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1005027 <> +v_1005028:
      v_1005029 = Nat.is_eq(v_8, v_4)
      template_match_901(v_1005029, v_1005027, v_1005028, v_4, v_6, v_8)

def template_match_903(+v_10: cps_provider_2_ShowPatch, +v_2: List<&2, cps_provider_2_ShowWord>, +v_11: List<&2, cps_provider_2_ShowPatch>) -> TemplateProgress<List<&2, cps_provider_2_ShowWord>>:
  match v_10:
    case cps_provider_2_ShowPatchAt{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_set_word{v_2, v_14, cps_provider_2_ShowNum{v_15}, 0n}}, False{}, v_1003715 => template_body_cps_provider_2_show_set_word(v_2, v_14, cps_provider_2_ShowNum{v_15}, 0n), v_1003714 => +v_1003711 = template_unbox(List<&2, cps_provider_2_ShowWord>, v_1003714); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_apply_patches{v_1003711, v_11}}, v_1003713 => +v_1003712 = template_unbox(List<&2, cps_provider_2_ShowWord>, v_1003713); TemplateFinished{TemplateValue{v_1003712}}}}

def template_body_cps_provider_2_show_apply_patches(+v_2: List<&2, cps_provider_2_ShowWord>, +v_5: List<&2, cps_provider_2_ShowPatch>) -> TemplateProgress<List<&2, cps_provider_2_ShowWord>>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{v_2}}
    case +v_1005031 <> +v_1005032:
      template_match_903(v_1005031, v_2, v_1005032)

def template_body_cps_provider_2_show_finish(+v_2: Maybe<&2, String>, +v_4: cps_provider_2_ShowState) -> TemplateProgress<cps_provider_2_ShowOut>:
  match v_2:
    case Some{v_7}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowFail{v_7}}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_apply_patches{template_pure_cps_provider_2_show_words(v_4), template_pure_cps_provider_2_show_patches(v_4)}}, False{}, v_1003724 => template_body_cps_provider_2_show_apply_patches(template_pure_cps_provider_2_show_words(v_4), template_pure_cps_provider_2_show_patches(v_4)), v_1003723 => +v_1003716 = template_unbox(List<&2, cps_provider_2_ShowWord>, v_1003723); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_render_words{v_1003716, ""}}, False{}, v_1003722 => template_body_cps_provider_2_show_render_words(v_1003716, ""), v_1003721 => +v_1003717 = template_unbox(String, v_1003721); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_render_names{template_pure_cps_provider_2_show_names(v_4)}}, False{}, v_1003720 => template_body_cps_provider_2_show_render_names(template_pure_cps_provider_2_show_names(v_4)), v_1003719 => +v_1003718 = template_unbox(String, v_1003719); TemplateFinished{TemplateValue{cps_provider_2_ShowOk{v_1003717, v_1003718}}}}}}

def template_body_cps_provider_2_show_result(+v_1: cps_provider_2_ShowRun) -> TemplateProgress<cps_provider_2_ShowOut>:
  match v_1:
    case cps_provider_2_ShowDone{+v_4}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_finish{template_pure_cps_provider_2_show_error(v_4), v_4}}, False{}, v_1003727 => template_body_cps_provider_2_show_finish(template_pure_cps_provider_2_show_error(v_4), v_4), v_1003726 => +v_1003725 = template_unbox(cps_provider_2_ShowOut, v_1003726); TemplateFinished{TemplateValue{v_1003725}}}

def template_body_cps_provider_2_show_root_layout(+v_1: cps_provider_1_Layout) -> TemplateProgress<cps_provider_1_Layout>:
  match v_1:
    case cps_provider_1_LayoutWord{v_4}:
      TemplateFinished{TemplateValue{v_1}}
    case cps_provider_1_LayoutBox{v_6}:
      TemplateFinished{TemplateValue{v_1}}
    case cps_provider_1_LayoutData{v_9, v_10}:
      TemplateFinished{TemplateValue{cps_provider_1_LayoutBox{cps_provider_1_BoxWide{List.length(&2, cps_provider_1_CWord, v_9)}}}}

def template_continuation_908(+v_1003734: cps_provider_2_ShowRun) -> TemplateProgress<cps_provider_2_ShowOut>:
  template_body_cps_provider_2_show_result(v_1003734)

def template_body_cps_provider_2_show_root(+v_1: cps_provider_1_LayoutResult, +v_3: cps_provider_1_Context, +v_4: BIR.Descriptor, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>) -> TemplateProgress<cps_provider_2_ShowOut>:
  match v_1:
    case cps_provider_1_LayoutFailed{v_1005033}:
      TemplateFinished{TemplateValue{cps_provider_2_ShowFail{v_1005033}}}
    case cps_provider_1_LayoutFound{v_1005034}:
      +v_1005035 = {v_3 : cps_provider_1_Context}
      +v_1005036 = {v_6 : List<&2, BIR.ConstructorLayout>}
      +v_1005037 = {v_8 : List<&2, BIR.Family>}
      v_1005038 = {v_4 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_show_root_layout{v_1005034}}, False{}, v_1005039 => template_body_cps_provider_2_show_root_layout(v_1005034), v_1005040 => +v_1005041 = template_unbox(cps_provider_1_Layout, v_1005040); TemplateDirect{Bool, TemplateRequestGroup_6{TemplateRequest_cps_provider_2_show_state0{}}, False{}, v_1005042 => template_body_cps_provider_2_show_state0, v_1005043 => +v_1005044 = template_unbox(cps_provider_2_ShowState, v_1005043); TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_2_run_show{v_1005035, v_1005036, v_1005037, [cps_provider_2_ShowNode{v_1005038, v_1005041, None{}}], v_1005044}}, False{}, v_1005045 => template_body_cps_provider_2_run_show(v_1005035, v_1005036, v_1005037, [cps_provider_2_ShowNode{v_1005038, v_1005041, None{}}], v_1005044), v_1005046 => +v_1005047 = template_unbox(cps_provider_2_ShowRun, v_1005046); template_continuation_908(v_1005047)}}}

def template_continuation_910(+v_1003742: cps_provider_1_LayoutResult, +v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>) -> TemplateProgress<cps_provider_2_ShowOut>:
  template_body_cps_provider_2_show_root(v_1003742, v_1, v_2, v_4, v_6)

def template_body_cps_provider_2_show_build(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>) -> TemplateProgress<cps_provider_2_ShowOut>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_cps_provider_1_value_layout{v_1, v_2}}, False{}, v_1003745 => template_body_cps_provider_1_value_layout(v_1, v_2), v_1003744 => +v_1003742 = template_unbox(cps_provider_1_LayoutResult, v_1003744); template_continuation_910(v_1003742, v_1, v_2, v_4, v_6)}

def template_match_911(+v_5: BIR.Family, v_6: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.Family>>:
  match v_5:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_family_index{v_6}}, v_1003747 => +v_1003746 = template_unbox(Map<&2, BIR.Family>, v_1003747); TemplateFinished{TemplateValue{Map.set(&2, BIR.Family, v_1003746, v_13, v_5)}}}

def template_body_cps_provider_3_family_index(v_1: List<&2, BIR.Family>) -> TemplateProgress<Map<&2, BIR.Family>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.Family)}}
    case +v_5 <> v_6:
      template_match_911(v_5, v_6)

def template_match_913(+v_5: BIR.TypeFunction, v_6: List<&2, BIR.TypeFunction>) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  match v_5:
    case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_function_index{v_6}}, v_1003749 => +v_1003748 = template_unbox(Map<&2, BIR.TypeFunction>, v_1003749); TemplateFinished{TemplateValue{Map.set(&2, BIR.TypeFunction, v_1003748, v_12, v_5)}}}

def template_body_cps_provider_3_function_index(v_1: List<&2, BIR.TypeFunction>) -> TemplateProgress<Map<&2, BIR.TypeFunction>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{Map.new(&2, BIR.TypeFunction)}}
    case +v_5 <> v_6:
      template_match_913(v_5, v_6)

def template_body_cps_provider_3_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> TemplateProgress<cps_provider_3_NfContext>:
  TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_family_index{v_1}}, False{}, v_1003755 => template_body_cps_provider_3_family_index(v_1), v_1003754 => +v_1003750 = template_unbox(Map<&2, BIR.Family>, v_1003754); TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_function_index{v_3}}, False{}, v_1003753 => template_body_cps_provider_3_function_index(v_3), v_1003752 => +v_1003751 = template_unbox(Map<&2, BIR.TypeFunction>, v_1003752); TemplateFinished{TemplateValue{cps_provider_3_NfContext{v_1003750, v_1003751}}}}}

def template_body_cps_provider_3_default_fuel() -> TemplateProgress<Nat>:
  TemplateFinished{TemplateValue{1024n}}

def template_body_cps_provider_3_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> TemplateProgress<Maybe<&2, BIR.Family>>:
  TemplateFinished{TemplateValue{IndexLookup.find(BIR.Family, v_3, v_1)}}

def template_body_cps_provider_3_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, BIR.TypeFunction>>:
  TemplateFinished{TemplateValue{IndexLookup.find(BIR.TypeFunction, v_3, v_1)}}

def template_match_915(v_10: BIR.Family) -> TemplateProgress<Maybe<&2, String>>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      TemplateFinished{TemplateValue{v_19}}

def template_match_916(v_25: BIR.TypeFunction) -> TemplateProgress<Maybe<&2, String>>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      TemplateFinished{TemplateValue{v_32}}

def template_match_917(+v_1003757: Maybe<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  match v_1003757:
    case Some{v_25}:
      template_match_916(v_25)
    case None{}:
      TemplateFinished{TemplateValue{None{}}}

def template_match_918(+v_1003756: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  match v_1003756:
    case Some{v_10}:
      template_match_915(v_10)
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_function_of{v_1, v_5}}, False{}, v_1003759 => template_body_cps_provider_3_function_of(v_1, v_5), v_1003758 => +v_1003757 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1003758); template_match_917(v_1003757)}

def template_body_cps_provider_3_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Maybe<&2, String>>:
  TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_family_of{v_1, v_3}}, False{}, v_1003761 => template_body_cps_provider_3_family_of(v_1, v_3), v_1003760 => +v_1003756 = template_unbox(Maybe<&2, BIR.Family>, v_1003760); template_match_918(v_1003756, v_1, v_5)}

def template_body_cps_provider_3_val_nth(+v_2: List<&2, cps_provider_3_NfVal>, v_4: Nat) -> TemplateProgress<cps_provider_3_NfVal>:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      TemplateFinished{TemplateValue{v_8}}
    case +v_13 <> v_14, 1n+v_15:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_val_nth{v_14, v_15}}, v_1003763 => +v_1003762 = template_unbox(cps_provider_3_NfVal, v_1003763); TemplateFinished{TemplateValue{v_1003762}}}
    case _, _:
      TemplateFinished{TemplateValue{cps_provider_3_NfMissing{BIR.DescriptorNull{}}}}

def template_body_cps_provider_3_val_at(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> TemplateProgress<cps_provider_3_NfVal>:
  TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_val_at_choose{Nat.is_lt(v_4, List.length(&2, cps_provider_3_NfVal, v_2)), v_2, v_4, v_5}}, v_1003765 => +v_1003764 = template_unbox(cps_provider_3_NfVal, v_1003765); TemplateFinished{TemplateValue{v_1003764}}}

def template_body_cps_provider_3_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> TemplateProgress<cps_provider_3_NfVal>:
  match v_1:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_val_nth{v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_3_NfVal, v_4), 1n), v_6)}}, False{}, v_1003768 => template_body_cps_provider_3_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_3_NfVal, v_4), 1n), v_6)), v_1003767 => +v_1003766 = template_unbox(cps_provider_3_NfVal, v_1003767); TemplateFinished{TemplateValue{v_1003766}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfMissing{v_7}}}

def template_body_cps_provider_3_first_vals(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_2, v_4:
    case _, 0n:
      TemplateFinished{TemplateValue{[]}}
    case [], _:
      TemplateFinished{TemplateValue{[]}}
    case +v_14 <> v_15, 1n+v_16:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_first_vals{v_15, v_16}}, v_1003771 => +v_1003770 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003771); TemplateFinished{TemplateValue{{v_14 : cps_provider_3_NfVal} <> v_1003770}}}

def template_body_cps_provider_3_drop_vals(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_2, v_4:
    case v_1005048, 0n:
      TemplateFinished{TemplateValue{v_2}}
    case [], v_1005049:
      TemplateFinished{TemplateValue{[]}}
    case +v_1005050 <> v_1005051, 1n+v_1005052:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_drop_vals{v_1005051, v_1005052}}, v_1005053 => +v_1005054 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1005053); TemplateFinished{TemplateValue{v_1005054}}}

def template_body_cps_provider_3_insert_before(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_6: cps_provider_3_NfVal) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_2, v_4:
    case v_1005055, 0n:
      TemplateFinished{TemplateValue{v_6 <> v_2}}
    case [], 1n+v_1005056:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_insert_before{[], v_1005056, v_6}}, v_1005057 => +v_1005058 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1005057); TemplateFinished{TemplateValue{v_1005058}}}
    case +v_1005059 <> v_1005060, 1n+v_1005061:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_insert_before{v_1005060, v_1005061, v_6}}, v_1005063 => +v_1005064 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1005063); TemplateFinished{TemplateValue{{v_1005059 : cps_provider_3_NfVal} <> v_1005064}}}

def template_body_cps_provider_3_append_vals(v_2: List<&2, cps_provider_3_NfVal>, v_5: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_5}}
    case +v_10 <> v_11:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_append_vals{v_11, v_5}}, v_1003781 => +v_1003780 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003781); TemplateFinished{TemplateValue{{v_10 : cps_provider_3_NfVal} <> v_1003780}}}

def template_body_cps_provider_3_quantity_markers(v_1: Nat) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_1:
    case 0n:
      TemplateFinished{TemplateValue{[]}}
    case 1n+v_5:
      v_1003782 = {cps_provider_3_NfQuantity{BIR.Erased{}} : cps_provider_3_NfVal}
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_quantity_markers{v_5}}, v_1003784 => +v_1003783 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003784); TemplateFinished{TemplateValue{v_1003782 <> v_1003783}}}

def template_match_926(v_1003785: Bool, v_10: Nat, v_11: List<&2, cps_provider_3_NfRenaming>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_1003785:
    case True{}:
      TemplateFinished{TemplateValue{v_10}}
    case False{}:
      TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_renamed_level{v_11, v_4}}, v_1003787 => +v_1003786 = template_unbox(Nat, v_1003787); TemplateFinished{TemplateValue{v_1003786}}}

def template_body_cps_provider_3_renamed_level(v_2: List<&2, cps_provider_3_NfRenaming>, +v_4: Nat) -> TemplateProgress<Nat>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case cps_provider_3_NfRenaming{v_9, v_10} <> v_11:
      v_1003785 = {Nat.is_eq(v_9, v_4) : Bool}
      template_match_926(v_1003785, v_10, v_11, v_4)

def template_body_cps_provider_3_materialize_all_scoped(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_3_NfRenaming>) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_11 <> v_12:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_scoped{v_11, v_4, v_7}}, v_1003791 => +v_1003788 = template_unbox(BIR.Descriptor, v_1003791); TemplatePending{TemplateRequestGroup_7{TemplateRequest_cps_provider_3_materialize_all_scoped{v_12, v_4, v_7}}, v_1003790 => +v_1003789 = template_unbox(List<&2, BIR.Descriptor>, v_1003790); TemplateFinished{TemplateValue{v_1003788 <> v_1003789}}}}

def template_body_cps_provider_3_materialize_all_at(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  template_body_cps_provider_3_materialize_all_scoped(v_2, v_4, [])

def template_body_cps_provider_3_materialize_all(v_2: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<List<&2, BIR.Descriptor>>:
  template_body_cps_provider_3_materialize_all_at(v_2, 0n)

def template_body_cps_provider_3_materialize_scoped(v_1: cps_provider_3_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_3_NfRenaming>) -> TemplateProgress<BIR.Descriptor>:
  match v_1:
    case cps_provider_3_NfType{v_9, v_10}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_materialize_all_scoped{v_10, v_3, v_6}}, False{}, v_1003797 => template_body_cps_provider_3_materialize_all_scoped(v_10, v_3, v_6), v_1003796 => +v_1003795 = template_unbox(List<&2, BIR.Descriptor>, v_1003796); TemplateFinished{TemplateValue{BIR.DescriptorRef{{v_9 : String}, v_1003795}}}}
    case cps_provider_3_NfCtor{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_materialize_all_scoped{v_15, v_3, v_6}}, False{}, v_1003801 => template_body_cps_provider_3_materialize_all_scoped(v_15, v_3, v_6), v_1003800 => +v_1003799 = template_unbox(List<&2, BIR.Descriptor>, v_1003800); TemplateFinished{TemplateValue{BIR.DescriptorConstructor{{v_14 : String}, v_1003799}}}}
    case cps_provider_3_NfQuantity{v_18}:
      TemplateFinished{TemplateValue{BIR.DescriptorQuantity{v_18}}}
    case cps_provider_3_NfKind{v_20}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_scoped{v_20, v_3, v_6}}, v_1003803 => +v_1003802 = template_unbox(BIR.Descriptor, v_1003803); TemplateFinished{TemplateValue{BIR.DescriptorKind{v_1003802}}}}
    case cps_provider_3_NfOther{v_23}:
      TemplateFinished{TemplateValue{v_23}}
    case cps_provider_3_NfMissing{v_25}:
      TemplateFinished{TemplateValue{v_25}}
    case cps_provider_3_NfBinder{v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_renamed_level{v_6, v_27}}, False{}, v_1003807 => template_body_cps_provider_3_renamed_level(v_6, v_27), v_1003806 => +v_1003805 = template_unbox(Nat, v_1003806); TemplateFinished{TemplateValue{BIR.DescriptorParameter{Nat.sub({v_3 : Nat}, Nat.add(v_1003805, 1n))}}}}
    case cps_provider_3_NfArrow{v_33, v_34, v_35, v_36}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_scoped{v_34, v_3, v_6}}, v_1003812 => +v_1003809 = template_unbox(BIR.Descriptor, v_1003812); TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_scoped{v_35, Nat.add(v_3, 1n), cps_provider_3_NfRenaming{v_36, v_3} <> v_6}}, v_1003811 => +v_1003810 = template_unbox(BIR.Descriptor, v_1003811); TemplateFinished{TemplateValue{BIR.DescriptorArrow{{v_33 : BIR.Quantity}, v_1003809, v_1003810}}}}}
    case cps_provider_3_NfClosure{v_42, v_43, v_44}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_materialize_all_scoped{v_44, v_3, v_6}}, False{}, v_1003815 => template_body_cps_provider_3_materialize_all_scoped(v_44, v_3, v_6), v_1003814 => +v_1003813 = template_unbox(List<&2, BIR.Descriptor>, v_1003814); TemplateFinished{TemplateValue{BIR.DescriptorLet{v_1003813, BIR.DescriptorLambda{v_42, v_43}}}}}

def template_body_cps_provider_3_materialize_at(v_1: cps_provider_3_NfVal, +v_3: Nat) -> TemplateProgress<BIR.Descriptor>:
  template_body_cps_provider_3_materialize_scoped(v_1, v_3, [])

def template_body_cps_provider_3_materialize(v_1: cps_provider_3_NfVal) -> TemplateProgress<BIR.Descriptor>:
  template_body_cps_provider_3_materialize_at(v_1, 0n)

def template_body_cps_provider_3_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_3_NfVal>, +v_5: Nat) -> TemplateProgress<BIR.Descriptor>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{v_0}}
    case +v_1005065 <> v_1005066:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_materialize_all_at{v_3, v_5}}, False{}, v_1005067 => template_body_cps_provider_3_materialize_all_at(v_3, v_5), v_1005068 => +v_1005069 = template_unbox(List<&2, BIR.Descriptor>, v_1005068); TemplateFinished{TemplateValue{BIR.DescriptorLet{v_1005069, v_0}}}}

def template_body_cps_provider_3_status_combine(v_1: cps_provider_3_NfStatus, v_3: cps_provider_3_NfStatus) -> TemplateProgress<cps_provider_3_NfStatus>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_3_status_combine(v_1, v_3)}}

def template_match_931(v_1003823: Bool, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_3_NfVal>, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_NfStatus>:
  match v_1003823:
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfStatusNo{}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_20, v_24}}, v_1003827 => +v_1003824 = template_unbox(cps_provider_3_NfStatus, v_1003827); TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_11, v_13}}, v_1003826 => +v_1003825 = template_unbox(cps_provider_3_NfStatus, v_1003826); TemplateFinished{TemplateValue{template_pure_cps_provider_3_status_combine(v_1003824, v_1003825)}}}}

def template_match_932(+v_12: cps_provider_3_NfVal, v_19: String, v_20: List<&2, BIR.DescriptorPattern>, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_NfStatus>:
  match v_12:
    case cps_provider_3_NfCtor{v_23, v_24}:
      v_1003823 = {String.eq(v_19, v_23) : Bool}
      template_match_931(v_1003823, v_20, v_24, v_11, v_13)
    case cps_provider_3_NfMissing{v_29}:
      v_1003828 = {cps_provider_3_NfStatusMaybe{} : cps_provider_3_NfStatus}
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_11, v_13}}, v_1003830 => +v_1003829 = template_unbox(cps_provider_3_NfStatus, v_1003830); TemplateFinished{TemplateValue{template_pure_cps_provider_3_status_combine(v_1003828, v_1003829)}}}
    case cps_provider_3_NfOther{v_33}:
      v_1003831 = {cps_provider_3_NfStatusMaybe{} : cps_provider_3_NfStatus}
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_11, v_13}}, v_1003833 => +v_1003832 = template_unbox(cps_provider_3_NfStatus, v_1003833); TemplateFinished{TemplateValue{template_pure_cps_provider_3_status_combine(v_1003831, v_1003832)}}}
    case cps_provider_3_NfBinder{v_37}:
      v_1003834 = {cps_provider_3_NfStatusMaybe{} : cps_provider_3_NfStatus}
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_11, v_13}}, v_1003836 => +v_1003835 = template_unbox(cps_provider_3_NfStatus, v_1003836); TemplateFinished{TemplateValue{template_pure_cps_provider_3_status_combine(v_1003834, v_1003835)}}}
    case cps_provider_3_NfArrow{v_44, v_45, v_46, v_47}:
      v_1003837 = {cps_provider_3_NfStatusMaybe{} : cps_provider_3_NfStatus}
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_11, v_13}}, v_1003839 => +v_1003838 = template_unbox(cps_provider_3_NfStatus, v_1003839); TemplateFinished{TemplateValue{template_pure_cps_provider_3_status_combine(v_1003837, v_1003838)}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_3_NfStatusNo{}}}

def template_match_933(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_3_NfVal>, +v_12: cps_provider_3_NfVal) -> TemplateProgress<cps_provider_3_NfStatus>:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_11, v_13}}, v_1003822 => +v_1003821 = template_unbox(cps_provider_3_NfStatus, v_1003822); TemplateFinished{TemplateValue{v_1003821}}}
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      template_match_932(v_12, v_19, v_20, v_11, v_13)

def template_body_cps_provider_3_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_NfStatus>:
  match v_1, v_4:
    case [], []:
      TemplateFinished{TemplateValue{cps_provider_3_NfStatusOk{}}}
    case +v_10 <> v_11, +v_12 <> v_13:
      template_match_933(v_10, v_11, v_13, v_12)
    case _, _:
      TemplateFinished{TemplateValue{cps_provider_3_NfStatusNo{}}}

def template_match_935(+v_13: cps_provider_3_NfVal, v_21: List<&2, BIR.DescriptorPattern>, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_13:
    case cps_provider_3_NfCtor{v_24, v_25}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_values{v_21, v_25}}, v_1003847 => +v_1003843 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003847); TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_values{v_12, v_14}}, v_1003846 => +v_1003844 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003846); template_body_cps_provider_3_append_vals(v_1003843, v_1003844)}}
    case _:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_values{v_12, v_14}}, v_1003849 => +v_1003848 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003849); TemplateFinished{TemplateValue{v_1003848}}}

def template_match_936(+v_11: BIR.DescriptorPattern, +v_13: cps_provider_3_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_values{v_12, v_14}}, v_1003842 => +v_1003841 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003842); TemplateFinished{TemplateValue{{v_13 : cps_provider_3_NfVal} <> v_1003841}}}
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      template_match_935(v_13, v_21, v_12, v_14)

def template_body_cps_provider_3_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<List<&2, cps_provider_3_NfVal>>:
  match v_1, v_4:
    case [], []:
      TemplateFinished{TemplateValue{[]}}
    case +v_11 <> v_12, +v_13 <> v_14:
      template_match_936(v_11, v_13, v_12, v_14)
    case _, _:
      TemplateFinished{TemplateValue{[]}}

def template_match_938(+v_1003850: cps_provider_3_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_NfBind>:
  match v_1003850:
    case cps_provider_3_NfStatusOk{}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_values{v_1, v_4}}, False{}, v_1003853 => template_body_cps_provider_3_bind_values(v_1, v_4), v_1003852 => +v_1003851 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003852); TemplateFinished{TemplateValue{cps_provider_3_NfBound{v_1003851}}}}
    case cps_provider_3_NfStatusNo{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfMismatch{}}}
    case cps_provider_3_NfStatusMaybe{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfUnknown{}}}

def template_body_cps_provider_3_bind_patterns(+v_1: List<&2, BIR.DescriptorPattern>, +v_4: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_NfBind>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_status{v_1, v_4}}, False{}, v_1003855 => template_body_cps_provider_3_bind_status(v_1, v_4), v_1003854 => +v_1003850 = template_unbox(cps_provider_3_NfStatus, v_1003854); template_match_938(v_1003850, v_1, v_4)}

def template_match_939(v_1003856: Bool, +v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003856:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{"the type expression did not normalize within its reduction budget"}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1, v_2, v_5, v_7, Nat.sub(v_9, 1n)}}, v_1003858 => +v_1003857 = template_unbox(cps_provider_3_Nf, v_1003858); TemplateFinished{TemplateValue{v_1003857}}}

def template_body_cps_provider_3_nf(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  v_1003856 = {Nat.is_eq(v_9, 0n) : Bool}
  template_match_939(v_1003856, v_1, v_2, v_5, v_7, v_9)

def template_match_940(v_1003859: Bool, +v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003859:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{"the type expression did not normalize within its reduction budget"}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor_step{v_1, v_2, v_5, v_7, v_9}}, v_1003861 => +v_1003860 = template_unbox(cps_provider_3_Nf, v_1003861); TemplateFinished{TemplateValue{v_1003860}}}

def template_body_cps_provider_3_nf_descriptor(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  v_1003859 = {Nat.is_eq(v_9, 0n) : Bool}
  template_match_940(v_1003859, v_1, v_2, v_5, v_7, v_9)

def template_match_941(+v_1003863: cps_provider_3_Nf, v_2: BIR.Quantity, v_17: cps_provider_3_NfVal, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003863:
    case cps_provider_3_NfFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_21}}}
    case cps_provider_3_NfOk{v_23}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfArrow{v_2, v_17, v_23, v_9}}}}

def template_match_942(+v_1003862: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat, v_2: BIR.Quantity) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003862:
    case cps_provider_3_NfFail{v_15}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_15}}}
    case cps_provider_3_NfOk{v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_4, List.append(&2, cps_provider_3_NfVal, v_7, [cps_provider_3_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11}}, False{}, v_1003865 => template_body_cps_provider_3_nf(v_1, v_4, List.append(&2, cps_provider_3_NfVal, v_7, [cps_provider_3_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11), v_1003864 => +v_1003863 = template_unbox(cps_provider_3_Nf, v_1003864); template_match_941(v_1003863, v_2, v_17, v_9)}

def template_body_cps_provider_3_nf_arrow(+v_1: cps_provider_3_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_3, v_7, v_9, v_11}}, False{}, v_1003867 => template_body_cps_provider_3_nf(v_1, v_3, v_7, v_9, v_11), v_1003866 => +v_1003862 = template_unbox(cps_provider_3_Nf, v_1003866); template_match_942(v_1003862, v_1, v_4, v_7, v_9, v_11, v_2)}

def template_match_943(+v_1003877: cps_provider_3_Nf) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003877:
    case cps_provider_3_NfOk{v_24}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfKind{v_24}}}}
    case cps_provider_3_NfFail{v_26}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_26}}}

def template_match_944(+v_1003884: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_45: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003884:
    case cps_provider_3_NfListOk{v_49}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_named{v_1, v_45, v_49, v_7, v_9}}, v_1003886 => +v_1003885 = template_unbox(cps_provider_3_Nf, v_1003886); TemplateFinished{TemplateValue{v_1003885}}}
    case cps_provider_3_NfListFail{v_52}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_52}}}

def template_match_945(+v_1003888: cps_provider_3_NfList, v_55: String) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003888:
    case cps_provider_3_NfListOk{v_59}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfCtor{v_55, v_59}}}}
    case cps_provider_3_NfListFail{v_61}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_61}}}

def template_match_946(+v_1003891: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_68: cps_provider_3_NfVal, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003891:
    case cps_provider_3_NfOk{v_71}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_apply{v_1, v_68, [v_71], v_7, v_9}}, v_1003893 => +v_1003892 = template_unbox(cps_provider_3_Nf, v_1003893); TemplateFinished{TemplateValue{v_1003892}}}
    case cps_provider_3_NfFail{v_74}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_74}}}

def template_match_947(+v_1003890: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_65: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003890:
    case cps_provider_3_NfOk{v_68}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_65, v_5, v_7, v_9}}, False{}, v_1003895 => template_body_cps_provider_3_nf(v_1, v_65, v_5, v_7, v_9), v_1003894 => +v_1003891 = template_unbox(cps_provider_3_Nf, v_1003894); template_match_946(v_1003891, v_1, v_68, v_7, v_9)}
    case cps_provider_3_NfFail{v_76}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_76}}}

def template_match_948(+v_1003898: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_82: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, v_80: Nat, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003898:
    case cps_provider_3_NfOk{v_85}:
      +v_1003899 = {v_1 : cps_provider_3_NfContext}
      v_1003900 = {v_82 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_insert_before{v_5, Nat.sub(List.length(&2, cps_provider_3_NfVal, v_5), v_80), v_85}}, False{}, v_1003906 => template_body_cps_provider_3_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_3_NfVal, v_5), v_80), v_85), v_1003905 => +v_1003901 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1003905); TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1003899, v_1003900, v_1003901, v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003904 => template_body_cps_provider_3_nf_descriptor(v_1003899, v_1003900, v_1003901, v_7, Nat.sub(v_9, 1n)), v_1003903 => +v_1003902 = template_unbox(cps_provider_3_Nf, v_1003903); TemplateFinished{TemplateValue{v_1003902}}}}
    case cps_provider_3_NfFail{v_90}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_90}}}

def template_match_949(+v_1003909: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_94: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003909:
    case cps_provider_3_NfListOk{v_97}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1, v_94, List.append(&2, cps_provider_3_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003912 => template_body_cps_provider_3_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_3_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n)), v_1003911 => +v_1003910 = template_unbox(cps_provider_3_Nf, v_1003911); TemplateFinished{TemplateValue{v_1003910}}}
    case cps_provider_3_NfListFail{v_101}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_101}}}

def template_match_950(+v_1003915: cps_provider_3_NfBind, +v_1: cps_provider_3_NfContext, v_107: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003915:
    case cps_provider_3_NfBound{v_113}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1, v_107, List.append(&2, cps_provider_3_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003918 => template_body_cps_provider_3_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_3_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n)), v_1003917 => +v_1003916 = template_unbox(cps_provider_3_Nf, v_1003917); TemplateFinished{TemplateValue{v_1003916}}}
    case _:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_12, v_5, v_7}}, False{}, v_1003921 => template_body_cps_provider_3_reify_env(v_12, v_5, v_7), v_1003920 => +v_1003919 = template_unbox(BIR.Descriptor, v_1003920); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1003919}}}}}

def template_match_951(+v_1003914: cps_provider_3_NfList, v_105: List<&2, BIR.DescriptorPattern>, +v_1: cps_provider_3_NfContext, v_107: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003914:
    case cps_provider_3_NfListOk{v_110}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_patterns{v_105, v_110}}, False{}, v_1003923 => template_body_cps_provider_3_bind_patterns(v_105, v_110), v_1003922 => +v_1003915 = template_unbox(cps_provider_3_NfBind, v_1003922); template_match_950(v_1003915, v_1, v_107, v_5, v_7, v_9, v_12)}
    case cps_provider_3_NfListFail{v_120}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_120}}}

def template_match_952(+v_1003925: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_124: List<&2, BIR.Descriptor>, +v_5: List<&2, cps_provider_3_NfVal>, +v_12: BIR.Descriptor, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003925:
    case cps_provider_3_NfListOk{v_127}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_cases{v_1, v_124, v_127, v_5, v_12, v_7, v_9}}, v_1003927 => +v_1003926 = template_unbox(cps_provider_3_Nf, v_1003927); TemplateFinished{TemplateValue{v_1003926}}}
    case cps_provider_3_NfListFail{v_130}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_130}}}

def template_match_953(+v_1003932: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_139: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003932:
    case cps_provider_3_NfOk{v_142}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1, v_139, List.append(&2, cps_provider_3_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1003935 => template_body_cps_provider_3_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_3_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n)), v_1003934 => +v_1003933 = template_unbox(cps_provider_3_Nf, v_1003934); TemplateFinished{TemplateValue{v_1003933}}}
    case cps_provider_3_NfFail{v_146}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_146}}}

def template_match_954(+v_1003948: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_170: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003948:
    case cps_provider_3_NfListOk{v_175}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_named{v_1, v_170, v_175, v_7, v_9}}, v_1003950 => +v_1003949 = template_unbox(cps_provider_3_Nf, v_1003950); TemplateFinished{TemplateValue{v_1003949}}}
    case cps_provider_3_NfListFail{v_178}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_178}}}

def template_match_955(+v_1003952: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_182: String, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003952:
    case cps_provider_3_NfListOk{v_187}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_named{v_1, v_182, v_187, v_7, v_9}}, v_1003954 => +v_1003953 = template_unbox(cps_provider_3_Nf, v_1003954); TemplateFinished{TemplateValue{v_1003953}}}
    case cps_provider_3_NfListFail{v_190}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_190}}}

def template_match_956(+v_12: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_1: cps_provider_3_NfContext, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_12:
    case BIR.DescriptorNull{}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_12, v_5, v_7}}, False{}, v_1003870 => template_body_cps_provider_3_reify_env(v_12, v_5, v_7), v_1003869 => +v_1003868 = template_unbox(BIR.Descriptor, v_1003869); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1003868}}}}}
    case BIR.DescriptorParameter{v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_val_at{v_5, v_15, v_12}}, False{}, v_1003873 => template_body_cps_provider_3_val_at(v_5, v_15, v_12), v_1003872 => +v_1003871 = template_unbox(cps_provider_3_NfVal, v_1003872); TemplateFinished{TemplateValue{cps_provider_3_NfOk{v_1003871}}}}
    case BIR.DescriptorQuantityKind{}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_12, v_5, v_7}}, False{}, v_1003876 => template_body_cps_provider_3_reify_env(v_12, v_5, v_7), v_1003875 => +v_1003874 = template_unbox(BIR.Descriptor, v_1003875); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1003874}}}}}
    case BIR.DescriptorQuantity{v_19}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfQuantity{v_19}}}}
    case BIR.DescriptorKind{v_21}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_21, v_5, v_7, v_9}}, False{}, v_1003879 => template_body_cps_provider_3_nf(v_1, v_21, v_5, v_7, v_9), v_1003878 => +v_1003877 = template_unbox(cps_provider_3_Nf, v_1003878); template_match_943(v_1003877)}
    case BIR.DescriptorMinimum{v_29, v_30}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_12, v_5, v_7}}, False{}, v_1003882 => template_body_cps_provider_3_reify_env(v_12, v_5, v_7), v_1003881 => +v_1003880 = template_unbox(BIR.Descriptor, v_1003881); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1003880}}}}}
    case BIR.DescriptorArrow{v_35, v_36, v_37}:
      template_body_cps_provider_3_nf_arrow(v_1, v_35, v_36, v_37, v_5, v_7, v_9)
    case BIR.DescriptorLambda{v_41, v_42}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfClosure{v_41, v_42, v_5}}}}
    case BIR.DescriptorRef{v_45, v_46}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_46, v_5, v_7, v_9}}, v_1003887 => +v_1003884 = template_unbox(cps_provider_3_NfList, v_1003887); template_match_944(v_1003884, v_1, v_45, v_7, v_9)}
    case BIR.DescriptorConstructor{v_55, v_56}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_56, v_5, v_7, v_9}}, v_1003889 => +v_1003888 = template_unbox(cps_provider_3_NfList, v_1003889); template_match_945(v_1003888, v_55)}
    case BIR.DescriptorApplication{v_64, v_65}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_64, v_5, v_7, v_9}}, False{}, v_1003897 => template_body_cps_provider_3_nf(v_1, v_64, v_5, v_7, v_9), v_1003896 => +v_1003890 = template_unbox(cps_provider_3_Nf, v_1003896); template_match_947(v_1003890, v_1, v_65, v_5, v_7, v_9)}
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_81, v_5, v_7, v_9}}, False{}, v_1003908 => template_body_cps_provider_3_nf(v_1, v_81, v_5, v_7, v_9), v_1003907 => +v_1003898 = template_unbox(cps_provider_3_Nf, v_1003907); template_match_948(v_1003898, v_1, v_82, v_5, v_80, v_7, v_9)}
    case BIR.DescriptorLet{v_93, v_94}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_93, v_5, v_7, v_9}}, v_1003913 => +v_1003909 = template_unbox(cps_provider_3_NfList, v_1003913); template_match_949(v_1003909, v_1, v_94, v_5, v_7, v_9)}
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_106, v_5, v_7, v_9}}, v_1003924 => +v_1003914 = template_unbox(cps_provider_3_NfList, v_1003924); template_match_951(v_1003914, v_105, v_1, v_107, v_5, v_7, v_9, v_12)}
    case BIR.DescriptorMatch{v_123, v_124}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_123, v_5, v_7, v_9}}, v_1003928 => +v_1003925 = template_unbox(cps_provider_3_NfList, v_1003928); template_match_952(v_1003925, v_1, v_124, v_5, v_12, v_7, v_9)}
    case BIR.DescriptorCase{v_133, v_134}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_12, v_5, v_7}}, False{}, v_1003931 => template_body_cps_provider_3_reify_env(v_12, v_5, v_7), v_1003930 => +v_1003929 = template_unbox(BIR.Descriptor, v_1003930); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1003929}}}}}
    case BIR.DescriptorBind{v_138, v_139}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_138, v_5, v_7, v_9}}, False{}, v_1003937 => template_body_cps_provider_3_nf(v_1, v_138, v_5, v_7, v_9), v_1003936 => +v_1003932 = template_unbox(cps_provider_3_Nf, v_1003936); template_match_953(v_1003932, v_1, v_139, v_5, v_7, v_9)}
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_12, v_5, v_7}}, False{}, v_1003940 => template_body_cps_provider_3_reify_env(v_12, v_5, v_7), v_1003939 => +v_1003938 = template_unbox(BIR.Descriptor, v_1003939); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1003938}}}}}
    case BIR.DescriptorReflexivity{}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_12, v_5, v_7}}, False{}, v_1003943 => template_body_cps_provider_3_reify_env(v_12, v_5, v_7), v_1003942 => +v_1003941 = template_unbox(BIR.Descriptor, v_1003942); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1003941}}}}}
    case BIR.DescriptorFailure{v_156}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_156}}}
    case BIR.DescriptorFill{v_159, v_160}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_apply_args{v_1, v_159, v_160, v_5, v_12, v_7, v_9}}, v_1003945 => +v_1003944 = template_unbox(cps_provider_3_Nf, v_1003945); TemplateFinished{TemplateValue{v_1003944}}}
    case BIR.DescriptorPlus{v_164, v_165}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_apply_args{v_1, v_164, v_165, v_5, v_12, v_7, v_9}}, v_1003947 => +v_1003946 = template_unbox(cps_provider_3_Nf, v_1003947); TemplateFinished{TemplateValue{v_1003946}}}
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_172, v_5, v_7, v_9}}, v_1003951 => +v_1003948 = template_unbox(cps_provider_3_NfList, v_1003951); template_match_954(v_1003948, v_1, v_170, v_7, v_9)}
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_184, v_5, v_7, v_9}}, v_1003955 => +v_1003952 = template_unbox(cps_provider_3_NfList, v_1003955); template_match_955(v_1003952, v_1, v_182, v_7, v_9)}

def template_body_cps_provider_3_nf_descriptor_step(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  template_match_956(v_2, v_5, v_7, v_1, v_9)

def template_match_957(+v_1003957: cps_provider_3_NfList, v_20: cps_provider_3_NfVal) -> TemplateProgress<cps_provider_3_NfList>:
  match v_1003957:
    case cps_provider_3_NfListFail{v_23}:
      TemplateFinished{TemplateValue{cps_provider_3_NfListFail{v_23}}}
    case cps_provider_3_NfListOk{v_25}:
      TemplateFinished{TemplateValue{cps_provider_3_NfListOk{v_20 <> v_25}}}

def template_match_958(+v_1003956: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_15: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_3_NfList>:
  match v_1003956:
    case cps_provider_3_NfFail{v_18}:
      TemplateFinished{TemplateValue{cps_provider_3_NfListFail{v_18}}}
    case cps_provider_3_NfOk{v_20}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_15, v_6, v_8, v_10}}, v_1003958 => +v_1003957 = template_unbox(cps_provider_3_NfList, v_1003958); template_match_957(v_1003957, v_20)}

def template_body_cps_provider_3_nf_all(+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_3_NfList>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{cps_provider_3_NfListOk{[]}}}
    case +v_1005070 <> v_1005071:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_1005070, v_6, v_8, v_10}}, False{}, v_1005072 => template_body_cps_provider_3_nf(v_1, v_1005070, v_6, v_8, v_10), v_1005073 => +v_1005074 = template_unbox(cps_provider_3_Nf, v_1005073); template_match_958(v_1005074, v_1, v_1005071, v_6, v_8, v_10)}

def template_match_960(+v_1003962: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_18: cps_provider_3_NfVal, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003962:
    case cps_provider_3_NfListFail{v_21}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_21}}}
    case cps_provider_3_NfListOk{v_23}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_apply_source{v_1, v_18, v_23, v_8, v_10, v_12}}, v_1003964 => +v_1003963 = template_unbox(cps_provider_3_Nf, v_1003964); TemplateFinished{TemplateValue{v_1003963}}}

def template_match_961(+v_1003961: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_3_NfVal>, +v_10: Nat, +v_12: Nat, v_8: BIR.Descriptor) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003961:
    case cps_provider_3_NfFail{v_16}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_16}}}
    case cps_provider_3_NfOk{v_18}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_all{v_1, v_4, v_7, v_10, v_12}}, False{}, v_1003966 => template_body_cps_provider_3_nf_all(v_1, v_4, v_7, v_10, v_12), v_1003965 => +v_1003962 = template_unbox(cps_provider_3_NfList, v_1003965); template_match_960(v_1003962, v_1, v_18, v_8, v_10, v_12)}

def template_body_cps_provider_3_nf_apply_args(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_3_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_2, v_7, v_10, v_12}}, False{}, v_1003968 => template_body_cps_provider_3_nf(v_1, v_2, v_7, v_10, v_12), v_1003967 => +v_1003961 = template_unbox(cps_provider_3_Nf, v_1003967); template_match_961(v_1003961, v_1, v_4, v_7, v_10, v_12, v_8)}

def template_body_cps_provider_3_nf_apply_source(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, +v_6: List<&2, cps_provider_3_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{v_3}}}
    case v_1005075:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_apply{v_1, v_3, v_6, v_9, v_11}}, v_1005076 => +v_1005077 = template_unbox(cps_provider_3_Nf, v_1005076); TemplateFinished{TemplateValue{v_1005077}}}

def template_match_963(+v_1003971: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_15: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1003971:
    case cps_provider_3_NfFail{v_18}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_18}}}
    case cps_provider_3_NfOk{v_20}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_apply{v_1, v_20, v_15, v_8, Nat.sub(v_10, 1n)}}, v_1003973 => +v_1003972 = template_unbox(cps_provider_3_Nf, v_1003973); TemplateFinished{TemplateValue{v_1003972}}}

def template_body_cps_provider_3_nf_apply(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{v_3}}}
    case +v_1005078 <> v_1005079:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_apply_one{v_1, v_3, v_1005078, v_8, Nat.sub(v_10, 1n)}}, v_1005080 => +v_1005081 = template_unbox(cps_provider_3_Nf, v_1005080); template_match_963(v_1005081, v_1, v_1005079, v_8, v_10)}

def template_body_cps_provider_3_nf_apply_one(+v_1: cps_provider_3_NfContext, +v_3: cps_provider_3_NfVal, +v_5: cps_provider_3_NfVal, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_3:
    case cps_provider_3_NfType{v_1005082, v_1005083}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_named{v_1, v_1005082, List.append(&2, cps_provider_3_NfVal, v_1005083, [v_5]), v_7, Nat.sub(v_9, 1n)}}, v_1005084 => +v_1005085 = template_unbox(cps_provider_3_Nf, v_1005084); TemplateFinished{TemplateValue{v_1005085}}}
    case cps_provider_3_NfClosure{v_1005086, v_1005087, v_1005088}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1, v_1005087, List.append(&2, cps_provider_3_NfVal, v_1005088, [v_5]), v_7, Nat.sub(v_9, 1n)}}, False{}, v_1005089 => template_body_cps_provider_3_nf_descriptor(v_1, v_1005087, List.append(&2, cps_provider_3_NfVal, v_1005088, [v_5]), v_7, Nat.sub(v_9, 1n)), v_1005090 => +v_1005091 = template_unbox(cps_provider_3_Nf, v_1005090); TemplateFinished{TemplateValue{v_1005091}}}
    case cps_provider_3_NfCtor{v_1005092, v_1005093}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{String.append("the constructor `", String.append(v_1005092, "` is applied to an argument"))}}}
    case cps_provider_3_NfQuantity{v_1005094}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{"a quantity is applied to an argument"}}}
    case cps_provider_3_NfKind{v_1005095}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{"a kind is applied to an argument"}}}
    case cps_provider_3_NfOther{v_1005096}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_at{v_5, v_7}}, False{}, v_1005098 => template_body_cps_provider_3_materialize_at(v_5, v_7), v_1005099 => +v_1005100 = template_unbox(BIR.Descriptor, v_1005099); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{BIR.DescriptorApplication{{v_1005096 : BIR.Descriptor}, v_1005100}}}}}}
    case cps_provider_3_NfArrow{v_1005101, v_1005102, v_1005103, v_1005104}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_at{v_3, v_7}}, False{}, v_1005105 => template_body_cps_provider_3_materialize_at(v_3, v_7), v_1005106 => +v_1005107 = template_unbox(BIR.Descriptor, v_1005106); TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_at{v_5, v_7}}, False{}, v_1005108 => template_body_cps_provider_3_materialize_at(v_5, v_7), v_1005109 => +v_1005110 = template_unbox(BIR.Descriptor, v_1005109); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{BIR.DescriptorApplication{v_1005107, v_1005110}}}}}}}
    case cps_provider_3_NfMissing{v_1005111}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_at{v_5, v_7}}, False{}, v_1005113 => template_body_cps_provider_3_materialize_at(v_5, v_7), v_1005114 => +v_1005115 = template_unbox(BIR.Descriptor, v_1005114); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfMissing{BIR.DescriptorApplication{{v_1005111 : BIR.Descriptor}, v_1005115}}}}}}
    case cps_provider_3_NfBinder{v_1005116}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_at{v_3, v_7}}, False{}, v_1005117 => template_body_cps_provider_3_materialize_at(v_3, v_7), v_1005118 => +v_1005119 = template_unbox(BIR.Descriptor, v_1005118); TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_materialize_at{v_5, v_7}}, False{}, v_1005120 => template_body_cps_provider_3_materialize_at(v_5, v_7), v_1005121 => +v_1005122 = template_unbox(BIR.Descriptor, v_1005121); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfMissing{BIR.DescriptorApplication{v_1005119, v_1005122}}}}}}}

def template_body_cps_provider_3_intrinsic_io(+v_0: BIR.TypeFunction) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_cps_provider_3_intrinsic_io(v_0)}}

def template_match_966(v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_Nf>:
  match v_4:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfType{v_18, v_7}}}}

def template_body_cps_provider_3_nf_named_io(v_1: Bool, +v_3: cps_provider_3_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1:
    case True{}:
      template_match_966(v_4, v_7)
    case False{}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_reduce{v_3, v_4, v_7, v_9, Nat.sub(v_11, 1n)}}, v_1005123 => +v_1005124 = template_unbox(cps_provider_3_Nf, v_1005123); TemplateFinished{TemplateValue{v_1005124}}}

def template_match_968(+v_1004006: Maybe<&2, BIR.Family>, v_6: List<&2, cps_provider_3_NfVal>, +v_3: String) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1004006:
    case Some{v_25}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_family{v_25, v_6}}, v_1004008 => +v_1004007 = template_unbox(cps_provider_3_Nf, v_1004008); TemplateFinished{TemplateValue{v_1004007}}}
    case None{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_6}}}}

def template_match_969(+v_1004002: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_3_NfContext, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat, +v_3: String, v_14: Map<&2, BIR.Family>) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1004002:
    case Some{v_18}:
      +v_20 = v_18
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_named_io{template_pure_cps_provider_3_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10}}, False{}, v_1004005 => template_body_cps_provider_3_nf_named_io(template_pure_cps_provider_3_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10), v_1004004 => +v_1004003 = template_unbox(cps_provider_3_Nf, v_1004004); TemplateFinished{TemplateValue{v_1004003}}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_family_of{v_3, v_14}}, False{}, v_1004010 => template_body_cps_provider_3_family_of(v_3, v_14), v_1004009 => +v_1004006 = template_unbox(Maybe<&2, BIR.Family>, v_1004009); template_match_968(v_1004006, v_6, v_3)}

def template_body_cps_provider_3_nf_named(+v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1:
    case cps_provider_3_NfContext{v_14, v_15}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_function_of{v_3, v_15}}, False{}, v_1004012 => template_body_cps_provider_3_function_of(v_3, v_15), v_1004011 => +v_1004002 = template_unbox(Maybe<&2, BIR.TypeFunction>, v_1004011); template_match_969(v_1004002, v_1, v_6, v_8, v_10, v_3, v_14)}

def template_body_cps_provider_3_nf_arity(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, +v_6: Nat) -> TemplateProgress<cps_provider_3_NfArity>:
  TemplateFinished{TemplateValue{cps_provider_3_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_3_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_3_NfVal, v_2), v_6)}}}

def template_match_971(v_0: BIR.Family, +v_6: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_Nf>:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_arity{v_6, v_20, v_17}}, False{}, v_1004017 => template_body_cps_provider_3_nf_arity(v_6, v_20, v_17), v_1004016 => +v_1004013 = template_unbox(cps_provider_3_NfArity, v_1004016); TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_family_apply{v_1004013, v_13, v_20, v_6}}, v_1004015 => +v_1004014 = template_unbox(cps_provider_3_Nf, v_1004015); TemplateFinished{TemplateValue{v_1004014}}}}

def template_body_cps_provider_3_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_Nf>:
  template_match_971(v_0, v_3)

def template_match_972(v_15: Bool, v_3: String, v_8: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_Nf>:
  match v_15:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_8}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}}}

def template_match_973(v_14: Bool, v_3: String, v_8: List<&2, cps_provider_3_NfVal>, v_15: Bool) -> TemplateProgress<cps_provider_3_Nf>:
  match v_14:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_8}}}}
    case False{}:
      template_match_972(v_15, v_3, v_8)

def template_match_974(v_13: Bool, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_3_NfVal>, v_14: Bool, v_15: Bool) -> TemplateProgress<cps_provider_3_Nf>:
  match v_13:
    case True{}:
      v_1004018 = {v_3 : String}
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_quantity_markers{v_5}}, False{}, v_1004021 => template_body_cps_provider_3_quantity_markers(v_5), v_1004020 => +v_1004019 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1004020); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfType{v_1004018, List.append(&2, cps_provider_3_NfVal, v_1004019, v_8)}}}}}
    case False{}:
      template_match_973(v_14, v_3, v_8, v_15)

def template_body_cps_provider_3_nf_family_apply(v_1: cps_provider_3_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1:
    case cps_provider_3_NfArity{v_13, v_14, v_15}:
      template_match_974(v_13, v_3, v_5, v_8, v_14, v_15)

def template_match_976(v_2: BIR.TypeFunction, +v_12: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_3_NfContext, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_2:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      +v_24 = v_20
      +v_26 = v_21
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_arity{v_12, v_24, v_26}}, False{}, v_1004026 => template_body_cps_provider_3_nf_arity(v_12, v_24, v_26), v_1004025 => +v_1004022 = template_unbox(cps_provider_3_NfArity, v_1004025); TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_reduce_apply{v_1004022, v_1, v_18, v_24, v_26, v_22, v_12, v_7, v_9}}, v_1004024 => +v_1004023 = template_unbox(cps_provider_3_Nf, v_1004024); TemplateFinished{TemplateValue{v_1004023}}}}

def template_body_cps_provider_3_nf_reduce(+v_1: cps_provider_3_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  template_match_976(v_2, v_5, v_1, v_7, v_9)

def template_match_977(v_24: Bool, v_5: String, +v_13: List<&2, cps_provider_3_NfVal>) -> TemplateProgress<cps_provider_3_Nf>:
  match v_24:
    case True{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfType{v_5, v_13}}}}
    case False{}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}}}

def template_match_978(v_23: Bool, +v_3: cps_provider_3_NfContext, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_15: Nat, +v_17: Nat, v_24: Bool, v_5: String) -> TemplateProgress<cps_provider_3_Nf>:
  match v_23:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_first_vals{v_13, v_9}}, False{}, v_1004043 => template_body_cps_provider_3_first_vals(v_13, v_9), v_1004042 => +v_1004036 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1004042); TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_drop_vals{v_13, v_9}}, False{}, v_1004041 => template_body_cps_provider_3_drop_vals(v_13, v_9), v_1004040 => +v_1004037 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1004040); TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_reduce_body{{v_3 : cps_provider_3_NfContext}, {v_10 : BIR.Descriptor}, v_1004036, v_1004037, v_15, Nat.sub(v_17, 1n)}}, v_1004039 => +v_1004038 = template_unbox(cps_provider_3_Nf, v_1004039); TemplateFinished{TemplateValue{v_1004038}}}}}
    case False{}:
      template_match_977(v_24, v_5, v_13)

def template_match_979(v_22: Bool, +v_3: cps_provider_3_NfContext, v_10: BIR.Descriptor, v_7: Nat, +v_13: List<&2, cps_provider_3_NfVal>, +v_15: Nat, +v_17: Nat, v_23: Bool, +v_9: Nat, v_24: Bool, v_5: String) -> TemplateProgress<cps_provider_3_Nf>:
  match v_22:
    case True{}:
      v_1004028 = {v_10 : BIR.Descriptor}
      TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_quantity_markers{v_7}}, False{}, v_1004033 => template_body_cps_provider_3_quantity_markers(v_7), v_1004032 => +v_1004029 = template_unbox(List<&2, cps_provider_3_NfVal>, v_1004032); TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_reduce_body{{v_3 : cps_provider_3_NfContext}, v_1004028, List.append(&2, cps_provider_3_NfVal, v_1004029, v_13), [], v_15, Nat.sub(v_17, 1n)}}, v_1004031 => +v_1004030 = template_unbox(cps_provider_3_Nf, v_1004031); TemplateFinished{TemplateValue{v_1004030}}}}
    case False{}:
      template_match_978(v_23, v_3, v_10, v_13, v_9, v_15, v_17, v_24, v_5)

def template_body_cps_provider_3_nf_reduce_apply(v_1: cps_provider_3_NfArity, +v_3: cps_provider_3_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_3_NfVal>, +v_15: Nat, +v_17: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1:
    case cps_provider_3_NfArity{v_1005125, v_1005126, v_1005127}:
      template_match_979(v_1005125, v_3, v_10, v_7, v_13, v_15, v_17, v_1005126, v_9, v_1005127, v_5)

def template_match_981(+v_1004044: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1004044:
    case cps_provider_3_NfFail{v_16}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_16}}}
    case cps_provider_3_NfOk{v_18}:
      template_body_cps_provider_3_nf_apply(v_1, v_18, v_8, v_10, v_12)

def template_body_cps_provider_3_nf_reduce_body(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat, +v_12: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)}}, False{}, v_1004047 => template_body_cps_provider_3_nf_descriptor(v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)), v_1004046 => +v_1004044 = template_unbox(cps_provider_3_Nf, v_1004046); template_match_981(v_1004044, v_1, v_8, v_10, v_12)}

def template_match_982(+v_1004051: cps_provider_3_NfBind, +v_1: cps_provider_3_NfContext, v_24: BIR.Descriptor, +v_9: List<&2, cps_provider_3_NfVal>, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor) -> TemplateProgress<cps_provider_3_Nf>:
  match v_1004051:
    case cps_provider_3_NfBound{v_27}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_descriptor{v_1, v_24, List.append(&2, cps_provider_3_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n)}}, False{}, v_1004054 => template_body_cps_provider_3_nf_descriptor(v_1, v_24, List.append(&2, cps_provider_3_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n)), v_1004053 => +v_1004052 = template_unbox(cps_provider_3_Nf, v_1004053); TemplateFinished{TemplateValue{v_1004052}}}
    case cps_provider_3_NfMismatch{}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf_cases{v_1, v_20, v_6, v_9, v_10, v_12, v_14}}, v_1004056 => +v_1004055 = template_unbox(cps_provider_3_Nf, v_1004056); TemplateFinished{TemplateValue{v_1004055}}}
    case cps_provider_3_NfUnknown{}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_10, v_9, v_12}}, False{}, v_1004059 => template_body_cps_provider_3_reify_env(v_10, v_9, v_12), v_1004058 => +v_1004057 = template_unbox(BIR.Descriptor, v_1004058); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1004057}}}}}

def template_match_983(+v_19: BIR.Descriptor, +v_6: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_3_NfContext, +v_9: List<&2, cps_provider_3_NfVal>, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, v_10: BIR.Descriptor) -> TemplateProgress<cps_provider_3_Nf>:
  match v_19:
    case BIR.DescriptorCase{v_23, v_24}:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_bind_patterns{v_23, v_6}}, False{}, v_1004061 => template_body_cps_provider_3_bind_patterns(v_23, v_6), v_1004060 => +v_1004051 = template_unbox(cps_provider_3_NfBind, v_1004060); template_match_982(v_1004051, v_1, v_24, v_9, v_12, v_14, v_20, v_6, v_10)}
    case BIR.DescriptorFailure{v_33}:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{v_33}}}
    case _:
      TemplateFinished{TemplateValue{cps_provider_3_NfFail{"descriptor match case is not a case"}}}

def template_body_cps_provider_3_nf_cases(+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, +v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> TemplateProgress<cps_provider_3_Nf>:
  match v_3:
    case []:
      TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_reify_env{v_10, v_9, v_12}}, False{}, v_1005128 => template_body_cps_provider_3_reify_env(v_10, v_9, v_12), v_1005129 => +v_1005130 = template_unbox(BIR.Descriptor, v_1005129); TemplateFinished{TemplateValue{cps_provider_3_NfOk{cps_provider_3_NfOther{v_1005130}}}}}
    case +v_1005131 <> v_1005132:
      template_match_983(v_1005131, v_6, v_1, v_9, v_12, v_14, v_1005132, v_10)

def template_match_985(+v_1004062: cps_provider_3_Nf) -> TemplateProgress<BIR.Descriptor>:
  match v_1004062:
    case cps_provider_3_NfFail{v_10}:
      TemplateFinished{TemplateValue{BIR.DescriptorFailure{v_10}}}
    case cps_provider_3_NfOk{v_12}:
      template_body_cps_provider_3_materialize_at(v_12, 0n)

def template_body_cps_provider_3_normalize(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_nf{v_1, v_2, v_5, 0n, v_7}}, False{}, v_1004065 => template_body_cps_provider_3_nf(v_1, v_2, v_5, 0n, v_7), v_1004064 => +v_1004062 = template_unbox(cps_provider_3_Nf, v_1004064); template_match_985(v_1004062)}

def template_body_cps_provider_3_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_nf_context{v_1, v_3}}, False{}, v_1004071 => template_body_cps_provider_3_nf_context(v_1, v_3), v_1004070 => +v_1004066 = template_unbox(cps_provider_3_NfContext, v_1004070); TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_normalize{v_1004066, v_4, [], 1024n}}, False{}, v_1004069 => template_body_cps_provider_3_normalize(v_1004066, v_4, [], 1024n), v_1004068 => +v_1004067 = template_unbox(BIR.Descriptor, v_1004068); TemplateFinished{TemplateValue{v_1004067}}}}

def template_body_cps_provider_3_normalize_in(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_normalize{v_1, v_2, [], 1024n}}, False{}, v_1004074 => template_body_cps_provider_3_normalize(v_1, v_2, [], 1024n), v_1004073 => +v_1004072 = template_unbox(BIR.Descriptor, v_1004073); TemplateFinished{TemplateValue{v_1004072}}}

def template_body_cps_provider_3_outer_application(+v_0: BIR.Descriptor) -> TemplateProgress<Maybe<&2, cps_provider_3_NfApp>>:
  TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_outer_walk{v_0, []}}, v_1004076 => +v_1004075 = template_unbox(Maybe<&2, cps_provider_3_NfApp>, v_1004076); TemplateFinished{TemplateValue{v_1004075}}}

def template_body_cps_provider_3_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> TemplateProgress<Maybe<&2, cps_provider_3_NfApp>>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      TemplateFinished{TemplateValue{Some{cps_provider_3_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{Some{cps_provider_3_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      TemplateFinished{TemplateValue{Some{cps_provider_3_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}}}
    case BIR.DescriptorFill{v_23, v_24}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_outer_walk{v_23, List.append(&2, BIR.Descriptor, v_24, v_2)}}, v_1004078 => +v_1004077 = template_unbox(Maybe<&2, cps_provider_3_NfApp>, v_1004078); TemplateFinished{TemplateValue{v_1004077}}}
    case BIR.DescriptorPlus{v_28, v_29}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_outer_walk{v_28, List.append(&2, BIR.Descriptor, v_29, v_2)}}, v_1004080 => +v_1004079 = template_unbox(Maybe<&2, cps_provider_3_NfApp>, v_1004080); TemplateFinished{TemplateValue{v_1004079}}}
    case BIR.DescriptorApplication{v_33, v_34}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_outer_walk{v_33, List.append(&2, BIR.Descriptor, [v_34], v_2)}}, v_1004082 => +v_1004081 = template_unbox(Maybe<&2, cps_provider_3_NfApp>, v_1004082); TemplateFinished{TemplateValue{v_1004081}}}
    case _:
      TemplateFinished{TemplateValue{None{}}}

def template_match_987(+v_5: BIR.Descriptor, +v_1: cps_provider_3_NfContext) -> TemplateProgress<BIR.Descriptor>:
  match v_5:
    case BIR.DescriptorFailure{_}:
      TemplateFinished{TemplateValue{v_5}}
    case _:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_answer_normalized{v_1, v_5}}, v_1004085 => +v_1004084 = template_unbox(BIR.Descriptor, v_1004085); TemplateFinished{TemplateValue{v_1004084}}}

def template_continuation_988(+v_1004083: BIR.Descriptor, +v_1: cps_provider_3_NfContext) -> TemplateProgress<BIR.Descriptor>:
  template_match_987(v_1004083, v_1)

def template_body_cps_provider_3_answer_in(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_normalize{v_1, v_2, [], 1024n}}, False{}, v_1004087 => template_body_cps_provider_3_normalize(v_1, v_2, [], 1024n), v_1004086 => +v_1004083 = template_unbox(BIR.Descriptor, v_1004086); template_continuation_988(v_1004083, v_1)}

def template_body_cps_provider_3_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_nf_context{v_2, v_4}}, False{}, v_1004091 => template_body_cps_provider_3_nf_context(v_2, v_4), v_1004090 => +v_1004088 = template_unbox(cps_provider_3_NfContext, v_1004090); template_body_cps_provider_3_answer_in(v_1004088, v_0)}

def template_match_989(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  match v_9:
    case []:
      TemplateFinished{TemplateValue{v_2}}
    case +v_13 <> v_14:
      TemplateFinished{TemplateValue{v_13}}

def template_match_990(+v_1004093: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> TemplateProgress<BIR.Descriptor>:
  match v_1004093:
    case False{}:
      TemplateFinished{TemplateValue{v_2}}
    case True{}:
      template_match_989(v_9, v_2)

def template_match_991(v_5: cps_provider_3_NfApp, +v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  match v_5:
    case cps_provider_3_NfApp{v_8, v_9}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_is_io_head_in{v_1, v_8}}, v_1004094 => +v_1004093 = template_unbox(Bool, v_1004094); template_match_990(v_1004093, v_2, v_9)}

def template_match_992(+v_1004092: Maybe<&2, cps_provider_3_NfApp>, +v_2: BIR.Descriptor, +v_1: cps_provider_3_NfContext) -> TemplateProgress<BIR.Descriptor>:
  match v_1004092:
    case None{}:
      TemplateFinished{TemplateValue{v_2}}
    case Some{v_5}:
      template_match_991(v_5, v_1, v_2)

def template_body_cps_provider_3_answer_normalized(+v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> TemplateProgress<BIR.Descriptor>:
  TemplateDirect{Bool, TemplateRequestGroup_8{TemplateRequest_cps_provider_3_outer_application{v_2}}, False{}, v_1004096 => template_body_cps_provider_3_outer_application(v_2), v_1004095 => +v_1004092 = template_unbox(Maybe<&2, cps_provider_3_NfApp>, v_1004095); template_match_992(v_1004092, v_2, v_1)}

def template_body_cps_provider_3_is_io_head_in(+v_1: cps_provider_3_NfContext, +v_3: String) -> TemplateProgress<Bool>:
  match v_1:
    case cps_provider_3_NfContext{v_7, v_8}:
      TemplatePending{TemplateRequestGroup_8{TemplateRequest_cps_provider_3_is_io_head{v_3, v_7, v_8}}, v_1004098 => +v_1004097 = template_unbox(Bool, v_1004098); TemplateFinished{TemplateValue{v_1004097}}}

def template_match_994(+v_1004099: Maybe<&2, String>) -> TemplateProgress<Bool>:
  match v_1004099:
    case Some{v_9}:
      TemplateFinished{TemplateValue{String.eq(v_9, "IO")}}
    case None{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_cps_provider_3_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_7{TemplateRequest_cps_provider_3_native_of{v_1, v_3, v_5}}, False{}, v_1004101 => template_body_cps_provider_3_native_of(v_1, v_3, v_5), v_1004100 => +v_1004099 = template_unbox(Maybe<&2, String>, v_1004100); template_match_994(v_1004099)}

def template_step_group_0(request: TemplateRequestGroup0) -> TemplateProgress<template_result_group_0(request)>:
  match request:
    case TemplateRequest_fld{arg_0}: template_body_fld(arg_0)
    case TemplateRequest_arm{arg_0, arg_1}: template_body_arm(arg_0, arg_1)
    case TemplateRequest_fam{arg_0, arg_1, arg_2, arg_3}: template_body_fam(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_ref{arg_0, arg_1}: template_body_ref(arg_0, arg_1)
    case TemplateRequest_fam_u32{}: template_body_fam_u32()
    case TemplateRequest_fam_pt{}: template_body_fam_pt()
    case TemplateRequest_fam_fl{}: template_body_fam_fl()
    case TemplateRequest_fam_seg{}: template_body_fam_seg()
    case TemplateRequest_families{}: template_body_families()
    case TemplateRequest_constructors{}: template_body_constructors()
    case TemplateRequest_program{}: template_body_program()
    case TemplateRequest_chain_key{arg_0}: template_body_chain_key(arg_0)
    case TemplateRequest_next_key{arg_0}: template_body_next_key(arg_0)
    case TemplateRequest_fam_chain{arg_0}: template_body_fam_chain(arg_0)
    case TemplateRequest_ctor_chain{arg_0}: template_body_ctor_chain(arg_0)
    case TemplateRequest_deep_program{}: template_body_deep_program()
    case TemplateRequest_summarize{arg_0}: template_body_summarize(arg_0)
    case TemplateRequest_deep_text{arg_0}: template_body_deep_text(arg_0)
    case TemplateRequest_deep_summary{}: template_body_deep_summary()
    case TemplateRequest_shadow_fams{}: template_body_shadow_fams()
    case TemplateRequest_shadow_ctors{}: template_body_shadow_ctors()
    case TemplateRequest_shadow_program{}: template_body_shadow_program()
    case TemplateRequest_shadow_one{arg_0, arg_1}: template_body_shadow_one(arg_0, arg_1)
    case TemplateRequest_shadow_summary{}: template_body_shadow_summary()
    case TemplateRequest_key_pair{arg_0, arg_1}: template_body_key_pair(arg_0, arg_1)
    case TemplateRequest_deep_key_probe{}: template_body_deep_key_probe()
    case TemplateRequest_key_checks{}: template_body_key_checks()
    case TemplateRequest_multi_fams{}: template_body_multi_fams()
    case TemplateRequest_multi_ctors{}: template_body_multi_ctors()
    case TemplateRequest_multi_program{}: template_body_multi_program()
    case TemplateRequest_multi_text{arg_0}: template_body_multi_text(arg_0)
    case TemplateRequest_multi_summary{}: template_body_multi_summary()
    case TemplateRequest_main{arg_0}: template_body_main(arg_0)
    case TemplateRequest_unwrap{arg_0, arg_1}: template_body_unwrap(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_context{arg_0}: template_body_cps_provider_1_context(arg_0)
    case TemplateRequest_cps_provider_1_context_nf{arg_0}: template_body_cps_provider_1_context_nf(arg_0)
    case TemplateRequest_cps_provider_1_context_families{arg_0}: template_body_cps_provider_1_context_families(arg_0)
    case TemplateRequest_cps_provider_1_context_plan{arg_0}: template_body_cps_provider_1_context_plan(arg_0)
    case TemplateRequest_cps_provider_1_context_nodes{arg_0}: template_body_cps_provider_1_context_nodes(arg_0)
    case TemplateRequest_cps_provider_1_context_arms{arg_0}: template_body_cps_provider_1_context_arms(arg_0)
    case TemplateRequest_cps_provider_1_nf_families{arg_0}: template_body_cps_provider_1_nf_families(arg_0)
    case TemplateRequest_cps_provider_1_nf_functions{arg_0}: template_body_cps_provider_1_nf_functions(arg_0)
    case TemplateRequest_cps_provider_1_family_lookup{arg_0, arg_1}: template_body_cps_provider_1_family_lookup(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_function_lookup{arg_0, arg_1}: template_body_cps_provider_1_function_lookup(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_arm_of{arg_0, arg_1}: template_body_cps_provider_1_arm_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_arm_in{arg_0, arg_1}: template_body_cps_provider_1_arm_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_plan_arm_index{arg_0}: template_body_cps_provider_1_plan_arm_index(arg_0)
    case TemplateRequest_cps_provider_1_plan_family_arms{arg_0, arg_1}: template_body_cps_provider_1_plan_family_arms(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_arm_declared{arg_0, arg_1}: template_body_cps_provider_1_arm_declared(arg_0, arg_1)
    case TemplateRequest_cps_provider_1_live_field{arg_0}: template_body_cps_provider_1_live_field(arg_0)
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
    case TemplateRequest_cps_provider_1_arms_tagged{arg_0}: template_body_cps_provider_1_arms_tagged(arg_0)

def template_step_group_1(request: TemplateRequestGroup1) -> TemplateProgress<template_result_group_1(request)>:
  match request:
    case TemplateRequest_cps_provider_1_reenters{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_1_reenters(arg_0, arg_1, arg_2, arg_3, arg_4)
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

def template_step_group_2(request: TemplateRequestGroup2) -> TemplateProgress<template_result_group_2(request)>:
  match request:
    case TemplateRequest_cps_provider_1_layout_has_term{arg_0}: template_body_cps_provider_1_layout_has_term(arg_0)
    case TemplateRequest_cps_provider_1_word_has_term{arg_0}: template_body_cps_provider_1_word_has_term(arg_0)
    case TemplateRequest_cps_provider_1_any_word_has_term{arg_0}: template_body_cps_provider_1_any_word_has_term(arg_0)
    case TemplateRequest_cps_provider_2_world{arg_0, arg_1, arg_2}: template_body_cps_provider_2_world(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_join_text{arg_0}: template_body_cps_provider_2_join_text(arg_0)
    case TemplateRequest_cps_provider_2_code_line{arg_0}: template_body_cps_provider_2_code_line(arg_0)
    case TemplateRequest_cps_provider_2_code_empty{}: template_body_cps_provider_2_code_empty()
    case TemplateRequest_cps_provider_2_code_seq{arg_0, arg_1}: template_body_cps_provider_2_code_seq(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_code_text{arg_0, arg_1}: template_body_cps_provider_2_code_text(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_part_of{arg_0, arg_1}: template_body_cps_provider_2_part_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_ctor_find{arg_0, arg_1}: template_body_cps_provider_2_ctor_find(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_ctor_of{arg_0, arg_1}: template_body_cps_provider_2_ctor_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_cid_find{arg_0, arg_1}: template_body_cps_provider_2_cid_find(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_cid_of{arg_0, arg_1}: template_body_cps_provider_2_cid_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_cid_text_of{arg_0}: template_body_cps_provider_2_cid_text_of(arg_0)
    case TemplateRequest_cps_provider_2_cid_text{arg_0, arg_1}: template_body_cps_provider_2_cid_text(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_intrinsic_marker{arg_0}: template_body_cps_provider_2_intrinsic_marker(arg_0)
    case TemplateRequest_cps_provider_2_dst_write{arg_0, arg_1}: template_body_cps_provider_2_dst_write(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_dst_word{arg_0, arg_1, arg_2}: template_body_cps_provider_2_dst_word(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_dst_decl{arg_0, arg_1, arg_2}: template_body_cps_provider_2_dst_decl(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_dst_mark{arg_0, arg_1}: template_body_cps_provider_2_dst_mark(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_form_base{arg_0, arg_1}: template_body_cps_provider_2_form_base(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_form_pad{arg_0, arg_1}: template_body_cps_provider_2_form_pad(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_src_skip_jobs{arg_0, arg_1}: template_body_cps_provider_2_src_skip_jobs(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_dst_skip_jobs{arg_0, arg_1}: template_body_cps_provider_2_dst_skip_jobs(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_src_read_node{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_src_read_node(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_src_read_arr{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_src_read_arr(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_src_read_block{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_src_read_block(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_src_read{arg_0, arg_1}: template_body_cps_provider_2_src_read(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_form_tagged{arg_0}: template_body_cps_provider_2_form_tagged(arg_0)
    case TemplateRequest_cps_provider_2_max_node_words{arg_0, arg_1}: template_body_cps_provider_2_max_node_words(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_max_term_decl{arg_0, arg_1}: template_body_cps_provider_2_max_term_decl(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_arm_seed{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_arm_seed(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_arm_seed_words{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_arm_seed_words(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_arm_src{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_arm_src(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nests_jobs{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_nests_jobs(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_arm_release{arg_0, arg_1, arg_2}: template_body_cps_provider_2_arm_release(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_jobs_arm_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11, arg_12}: template_body_cps_provider_2_jobs_arm_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11, arg_12)
    case TemplateRequest_cps_provider_2_jobs_arm{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11, arg_12}: template_body_cps_provider_2_jobs_arm(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11, arg_12)
    case TemplateRequest_cps_provider_2_arm_jobs{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_cps_provider_2_arm_jobs(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_cps_provider_2_unbox_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_unbox_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_expand_unbox{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_expand_unbox(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_expand_word_take{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_expand_word_take(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_nest_take{arg_0}: template_body_cps_provider_2_nest_take(arg_0)
    case TemplateRequest_cps_provider_2_nest_make{arg_0}: template_body_cps_provider_2_nest_make(arg_0)
    case TemplateRequest_cps_provider_2_field_pair_jobs{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_field_pair_jobs(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_forms_arm_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_cps_provider_2_forms_arm_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_cps_provider_2_forms_arm_case{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_cps_provider_2_forms_arm_case(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_cps_provider_2_form_arm_by_key{arg_0, arg_1}: template_body_cps_provider_2_form_arm_by_key(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_forms_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_cps_provider_2_forms_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_cps_provider_2_expand_forms{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_expand_forms(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_forms_single{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_forms_single(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_pack_jobs{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_pack_jobs(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_arm_block_jobs{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_arm_block_jobs(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_box_arm_jobs{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_box_arm_jobs(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_box_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_box_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_box_untagged{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_box_untagged(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_expand_box{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_expand_box(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_expand_box_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_expand_box_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_expand_form_take{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_expand_form_take(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_expand_conv{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_expand_conv(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_run_jobs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_run_jobs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_fill_plan_jobs{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_fill_plan_jobs(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_fill_result_jobs{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_fill_result_jobs(arg_0, arg_1, arg_2, arg_3)

def template_step_group_3(request: TemplateRequestGroup3) -> TemplateProgress<template_result_group_3(request)>:
  match request:
    case TemplateRequest_cps_provider_2_fill_data_jobs{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_fill_data_jobs(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_fill_jobs{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_fill_jobs(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_unfill_result_jobs{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_unfill_result_jobs(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_unfill_data_jobs{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_unfill_data_jobs(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_unfill_word_jobs{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_unfill_word_jobs(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_unfill_jobs{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_unfill_jobs(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_operand_code{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_operand_code(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_operand_name{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_operand_name(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_text_jobs{arg_0}: template_body_cps_provider_2_text_jobs(arg_0)
    case TemplateRequest_cps_provider_2_code_jobs{arg_0}: template_body_cps_provider_2_code_jobs(arg_0)
    case TemplateRequest_cps_provider_2_fill_slots_jobs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_fill_slots_jobs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_layout_is_data{arg_0}: template_body_cps_provider_2_layout_is_data(arg_0)
    case TemplateRequest_cps_provider_2_seal_box_many{arg_0, arg_1}: template_body_cps_provider_2_seal_box_many(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_seal_box{arg_0, arg_1, arg_2}: template_body_cps_provider_2_seal_box(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_seal_kind{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_seal_kind(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_seal_kind_walk{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_seal_kind_walk(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_seal_slots_jobs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_seal_slots_jobs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_one_job{arg_0}: template_body_cps_provider_2_one_job(arg_0)
    case TemplateRequest_cps_provider_2_construct_words{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_construct_words(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_codeSeqPack{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_codeSeqPack(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_construct_packed_one{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_construct_packed_one(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_construct_packed{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_construct_packed(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_construct_packed_flag{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_construct_packed_flag(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_construct_count{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_construct_count(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_construct_node{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_construct_node(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_construct_layout{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_construct_layout(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_construct_cid{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_construct_cid(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_construct_generic{arg_0, arg_1, arg_2}: template_body_cps_provider_2_construct_generic(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_construct_marker{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_construct_marker(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_construct_native{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_construct_native(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_construct_row{arg_0, arg_1, arg_2}: template_body_cps_provider_2_construct_row(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_construct_part{arg_0, arg_1, arg_2}: template_body_cps_provider_2_construct_part(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_term_decl_text{arg_0}: template_body_cps_provider_2_term_decl_text(arg_0)
    case TemplateRequest_cps_provider_2_project_prelude{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_project_prelude(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_project_words{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_project_words(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_project_packed_prelude{arg_0, arg_1}: template_body_cps_provider_2_project_packed_prelude(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_project_packed{arg_0, arg_1, arg_2}: template_body_cps_provider_2_project_packed(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_project_packed_flag{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_project_packed_flag(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_unique_expr{arg_0}: template_body_cps_provider_2_unique_expr(arg_0)
    case TemplateRequest_cps_provider_2_static_expr{arg_0}: template_body_cps_provider_2_static_expr(arg_0)
    case TemplateRequest_cps_provider_2_and_expr{arg_0, arg_1}: template_body_cps_provider_2_and_expr(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_or_expr{arg_0, arg_1}: template_body_cps_provider_2_or_expr(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_nat_if{arg_0, arg_1, arg_2}: template_body_cps_provider_2_nat_if(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_live_ordinal{arg_0, arg_1}: template_body_cps_provider_2_live_ordinal(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_live_walk{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_live_walk(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_live_next{arg_0, arg_1}: template_body_cps_provider_2_live_next(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_arm_fields_of{arg_0, arg_1}: template_body_cps_provider_2_arm_fields_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_arm_fields_declared{arg_0}: template_body_cps_provider_2_arm_fields_declared(arg_0)
    case TemplateRequest_cps_provider_2_arm_descriptor_fields{arg_0, arg_1}: template_body_cps_provider_2_arm_descriptor_fields(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_step_key{arg_0, arg_1}: template_body_cps_provider_2_step_key(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_cell_lgs{arg_0, arg_1}: template_body_cps_provider_2_cell_lgs(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_not_bool{arg_0}: template_body_cps_provider_2_not_bool(arg_0)
    case TemplateRequest_cps_provider_2_live_ordinal_in{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_live_ordinal_in(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_inline_slot{arg_0, arg_1, arg_2}: template_body_cps_provider_2_inline_slot(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_inline_start{arg_0}: template_body_cps_provider_2_inline_start(arg_0)
    case TemplateRequest_cps_provider_2_state_array{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_state_array(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_state_from_array_value{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_state_from_array_value(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_resolve_field{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_resolve_field(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_resolve_slot_field{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_cps_provider_2_resolve_slot_field(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_cps_provider_2_resolve_cell_field{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_cps_provider_2_resolve_cell_field(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
    case TemplateRequest_cps_provider_2_resolve_buf_field{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_resolve_buf_field(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_resolve_node_slot{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_resolve_node_slot(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_root_array_path{arg_0, arg_1, arg_2}: template_body_cps_provider_2_root_array_path(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_advance{arg_0, arg_1, arg_2}: template_body_cps_provider_2_advance(arg_0, arg_1, arg_2)

def template_step_group_4(request: TemplateRequestGroup4) -> TemplateProgress<template_result_group_4(request)>:
  match request:
    case TemplateRequest_cps_provider_2_array_from_state{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_from_state(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_half_state{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_half_state(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_leaf_state{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_leaf_state(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_resolve_path{arg_0, arg_1}: template_body_cps_provider_2_resolve_path(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_path_prelude{arg_0}: template_body_cps_provider_2_path_prelude(arg_0)
    case TemplateRequest_cps_provider_2_path_expr{arg_0, arg_1}: template_body_cps_provider_2_path_expr(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_keep_copy{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_keep_copy(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_keep_copy_fields{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_keep_copy_fields(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_keep_copy_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_keep_copy_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_move_copy{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_move_copy(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_move_copy_fields{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_move_copy_fields(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_move_copy_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_move_copy_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_raw_word_expr{arg_0, arg_1, arg_2}: template_body_cps_provider_2_raw_word_expr(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_packed_form_body{arg_0, arg_1, arg_2}: template_body_cps_provider_2_packed_form_body(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_read_body{arg_0, arg_1}: template_body_cps_provider_2_read_body(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_tag_single{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_tag_single(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_tag_multi{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_tag_multi(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_tag_case_line{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_tag_case_line(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_tag_multi_packed{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_tag_multi_packed(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_tag_multi_packed_go{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_tag_multi_packed_go(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_tag_multi_buf{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_tag_multi_buf(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_tag_multi_buf_go{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_tag_multi_buf_go(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_tag_body{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_tag_body(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_copy_slot_body{arg_0, arg_1}: template_body_cps_provider_2_copy_slot_body(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_packed_data_value{arg_0, arg_1}: template_body_cps_provider_2_packed_data_value(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_packed_data_copy{arg_0, arg_1}: template_body_cps_provider_2_packed_data_copy(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_box_copy_body{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_box_copy_body(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_data_copy_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_data_copy_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_zero_value_body{arg_0, arg_1}: template_body_cps_provider_2_zero_value_body(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_buf_clear_words{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_buf_clear_words(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_buf_field_body{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_buf_field_body(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_buf_move_clear{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_buf_move_clear(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_cell_arr_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_cell_arr_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_cell_move_clear{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_cell_move_clear(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_cell_data_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_cell_data_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_buf_clear_span{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_buf_clear_span(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_copy_cell_body{arg_0, arg_1}: template_body_cps_provider_2_copy_cell_body(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_copy_padding{arg_0, arg_1, arg_2}: template_body_cps_provider_2_copy_padding(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_inner{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_array_inner(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_array_copy_body{arg_0, arg_1}: template_body_cps_provider_2_array_copy_body(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_pow2{arg_0}: template_body_cps_provider_2_pow2(arg_0)
    case TemplateRequest_cps_provider_2_move_cell_body{arg_0, arg_1}: template_body_cps_provider_2_move_cell_body(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_move_slot_body{arg_0, arg_1}: template_body_cps_provider_2_move_slot_body(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_data_move_body{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_data_move_body(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_state_stat{arg_0}: template_body_cps_provider_2_state_stat(arg_0)
    case TemplateRequest_cps_provider_2_state_uniq{arg_0}: template_body_cps_provider_2_state_uniq(arg_0)
    case TemplateRequest_cps_provider_2_path_body_copy{arg_0, arg_1}: template_body_cps_provider_2_path_body_copy(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_path_body_move{arg_0, arg_1}: template_body_cps_provider_2_path_body_move(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_path_read{arg_0, arg_1, arg_2}: template_body_cps_provider_2_path_read(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_runtime_cid_of_ctor{arg_0, arg_1}: template_body_cps_provider_2_runtime_cid_of_ctor(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_canonical_bool{arg_0, arg_1}: template_body_cps_provider_2_canonical_bool(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_path_hastag{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_path_hastag(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_path_copy{arg_0, arg_1, arg_2}: template_body_cps_provider_2_path_copy(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_path_consume{arg_0, arg_1, arg_2}: template_body_cps_provider_2_path_consume(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_path_is_leaf{arg_0, arg_1, arg_2}: template_body_cps_provider_2_path_is_leaf(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_path_is_node{arg_0, arg_1, arg_2}: template_body_cps_provider_2_path_is_node(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_project_plan{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_project_plan(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_project_slot{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_project_slot(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_project_layout{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_project_layout(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_project_node{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_project_node(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_project_marker{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_project_marker(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_project_native{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_project_native(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_project_row{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_project_row(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_project_part{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_project_part(arg_0, arg_1, arg_2, arg_3)

def template_step_group_5(request: TemplateRequestGroup5) -> TemplateProgress<template_result_group_5(request)>:
  match request:
    case TemplateRequest_cps_provider_2_hastag_bools{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_hastag_bools(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_hastag_cid{arg_0, arg_1, arg_2}: template_body_cps_provider_2_hastag_cid(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_hastag_row{arg_0, arg_1, arg_2}: template_body_cps_provider_2_hastag_row(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_hastag_part{arg_0, arg_1, arg_2}: template_body_cps_provider_2_hastag_part(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_arr_flag{arg_0}: template_body_cps_provider_2_arr_flag(arg_0)
    case TemplateRequest_cps_provider_2_array_label{arg_0}: template_body_cps_provider_2_array_label(arg_0)
    case TemplateRequest_cps_provider_2_descriptor_missing{arg_0}: template_body_cps_provider_2_descriptor_missing(arg_0)
    case TemplateRequest_cps_provider_2_array_cell_result{arg_0}: template_body_cps_provider_2_array_cell_result(arg_0)
    case TemplateRequest_cps_provider_2_array_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_operand_at{arg_0, arg_1}: template_body_cps_provider_2_operand_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_operand_text{arg_0}: template_body_cps_provider_2_operand_text(arg_0)
    case TemplateRequest_cps_provider_2_operand_use{arg_0}: template_body_cps_provider_2_operand_use(arg_0)
    case TemplateRequest_cps_provider_2_keep_text{arg_0}: template_body_cps_provider_2_keep_text(arg_0)
    case TemplateRequest_cps_provider_2_tuple_cid{arg_0, arg_1, arg_2}: template_body_cps_provider_2_tuple_cid(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_tuple_part{arg_0, arg_1, arg_2}: template_body_cps_provider_2_tuple_part(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_seal_cell_box{arg_0, arg_1}: template_body_cps_provider_2_seal_cell_box(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_seal_cell_kind{arg_0, arg_1, arg_2}: template_body_cps_provider_2_seal_cell_kind(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_seal_cell_walk{arg_0, arg_1, arg_2}: template_body_cps_provider_2_seal_cell_walk(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_elem_fill_operand{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_elem_fill_operand(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_elem_fill{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_elem_fill(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_elem_stores{arg_0}: template_body_cps_provider_2_elem_stores(arg_0)
    case TemplateRequest_cps_provider_2_elem_decl{arg_0}: template_body_cps_provider_2_elem_decl(arg_0)
    case TemplateRequest_cps_provider_2_run_part{arg_0, arg_1, arg_2}: template_body_cps_provider_2_run_part(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_new_ops{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_array_new_ops(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_tuple_and_code{arg_0, arg_1}: template_body_cps_provider_2_tuple_and_code(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_array_get_ops{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_array_get_ops(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_old_read_cell{arg_0, arg_1}: template_body_cps_provider_2_old_read_cell(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_kinds_box_jobs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_kinds_box_jobs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_old_sink_jobs{arg_0, arg_1}: template_body_cps_provider_2_old_sink_jobs(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_write_jobs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_write_jobs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_set_run{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_array_set_run(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_array_set_ops{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_array_set_ops(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_array_swap_run{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_array_swap_run(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_array_swap_ops{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_array_swap_ops(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_array_size_ops{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_size_ops(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_clone_ops{arg_0, arg_1}: template_body_cps_provider_2_array_clone_ops(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_atomic_cell_text{arg_0, arg_1}: template_body_cps_provider_2_atomic_cell_text(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_atomic_call_text{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_atomic_call_text(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_atomic_cas_text{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_atomic_cas_text(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_atomic_helper{arg_0}: template_body_cps_provider_2_atomic_helper(arg_0)
    case TemplateRequest_cps_provider_2_atomic_pair{arg_0, arg_1, arg_2}: template_body_cps_provider_2_atomic_pair(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_atomic_three_operands{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_atomic_three_operands(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_atomic_three_pargs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_atomic_three_pargs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_atomic_cas_pargs{arg_0, arg_1}: template_body_cps_provider_2_atomic_cas_pargs(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_atomic_pargs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_atomic_pargs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_atomic_three_regs{arg_0, arg_1, arg_2}: template_body_cps_provider_2_atomic_three_regs(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_atomic_cas_regs{arg_0, arg_1}: template_body_cps_provider_2_atomic_cas_regs(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_atomic_prim_part{arg_0, arg_1, arg_2}: template_body_cps_provider_2_atomic_prim_part(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_leaf_ops{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_array_leaf_ops(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_array_node_ops{arg_0, arg_1}: template_body_cps_provider_2_array_node_ops(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_array_is_cond{arg_0, arg_1}: template_body_cps_provider_2_array_is_cond(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_array_is_bools{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_array_is_bools(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_array_is_ops{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_is_ops(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_new_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_new_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_get_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_get_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_set_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_set_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_swap_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_swap_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_size_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_size_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_clone_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_clone_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_leaf_cell{arg_0, arg_1, arg_2}: template_body_cps_provider_2_array_leaf_cell(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_array_part{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_array_part(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_array_cell_part{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_array_cell_part(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_is_atomic_primitive{arg_0}: template_body_cps_provider_2_is_atomic_primitive(arg_0)
    case TemplateRequest_cps_provider_2_is_array_primitive{arg_0}: template_body_cps_provider_2_is_array_primitive(arg_0)

def template_step_group_6(request: TemplateRequestGroup6) -> TemplateProgress<template_result_group_6(request)>:
  match request:
    case TemplateRequest_cps_provider_2_map_offsets{arg_0, arg_1, arg_2}: template_body_cps_provider_2_map_offsets(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_map_offsets_walk{arg_0, arg_1, arg_2}: template_body_cps_provider_2_map_offsets_walk(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_map_find_missing{arg_0}: template_body_cps_provider_2_map_find_missing(arg_0)
    case TemplateRequest_cps_provider_2_map_find_text{arg_0, arg_1, arg_2}: template_body_cps_provider_2_map_find_text(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_map_find_build{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_map_find_build(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_map_find_expr{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_map_find_expr(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_map_find_operands{arg_0, arg_1}: template_body_cps_provider_2_map_find_operands(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_map_find_names{arg_0, arg_1}: template_body_cps_provider_2_map_find_names(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_map_find_part{arg_0, arg_1, arg_2}: template_body_cps_provider_2_map_find_part(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_descriptor_part{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_descriptor_part(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_show_state0{}: template_body_cps_provider_2_show_state0()
    case TemplateRequest_cps_provider_2_show_words{arg_0}: template_body_cps_provider_2_show_words(arg_0)
    case TemplateRequest_cps_provider_2_show_patches{arg_0}: template_body_cps_provider_2_show_patches(arg_0)
    case TemplateRequest_cps_provider_2_show_memo{arg_0}: template_body_cps_provider_2_show_memo(arg_0)
    case TemplateRequest_cps_provider_2_show_names{arg_0}: template_body_cps_provider_2_show_names(arg_0)
    case TemplateRequest_cps_provider_2_show_error{arg_0}: template_body_cps_provider_2_show_error(arg_0)
    case TemplateRequest_cps_provider_2_show_state_set_memo{arg_0, arg_1}: template_body_cps_provider_2_show_state_set_memo(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_state_error{arg_0, arg_1}: template_body_cps_provider_2_show_state_error(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_next_state{arg_0}: template_body_cps_provider_2_show_next_state(arg_0)
    case TemplateRequest_cps_provider_2_show_next_kids{arg_0}: template_body_cps_provider_2_show_next_kids(arg_0)
    case TemplateRequest_cps_provider_2_show_append_word{arg_0, arg_1}: template_body_cps_provider_2_show_append_word(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_append_num{arg_0, arg_1}: template_body_cps_provider_2_show_append_num(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_append_cid{arg_0, arg_1}: template_body_cps_provider_2_show_append_cid(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_append_name{arg_0, arg_1}: template_body_cps_provider_2_show_append_name(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_append_patch{arg_0, arg_1, arg_2}: template_body_cps_provider_2_show_append_patch(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_show_apply_patch{arg_0, arg_1, arg_2}: template_body_cps_provider_2_show_apply_patch(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_show_native_kind{arg_0}: template_body_cps_provider_2_show_native_kind(arg_0)
    case TemplateRequest_cps_provider_2_show_kind_family{arg_0, arg_1}: template_body_cps_provider_2_show_kind_family(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_kind_head{arg_0, arg_1}: template_body_cps_provider_2_show_kind_head(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_kind{arg_0, arg_1}: template_body_cps_provider_2_show_kind(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_box_flag{arg_0}: template_body_cps_provider_2_show_box_flag(arg_0)
    case TemplateRequest_cps_provider_2_show_tag_plain{arg_0}: template_body_cps_provider_2_show_tag_plain(arg_0)
    case TemplateRequest_cps_provider_2_show_tag_start{arg_0, arg_1}: template_body_cps_provider_2_show_tag_start(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_quote{arg_0}: template_body_cps_provider_2_show_quote(arg_0)
    case TemplateRequest_cps_provider_2_show_name_sep{arg_0}: template_body_cps_provider_2_show_name_sep(arg_0)
    case TemplateRequest_cps_provider_2_show_render_names{arg_0}: template_body_cps_provider_2_show_render_names(arg_0)
    case TemplateRequest_cps_provider_2_show_render_sep_flag{arg_0}: template_body_cps_provider_2_show_render_sep_flag(arg_0)
    case TemplateRequest_cps_provider_2_show_render_sep{arg_0}: template_body_cps_provider_2_show_render_sep(arg_0)
    case TemplateRequest_cps_provider_2_show_render_word{arg_0}: template_body_cps_provider_2_show_render_word(arg_0)
    case TemplateRequest_cps_provider_2_show_render_words{arg_0, arg_1}: template_body_cps_provider_2_show_render_words(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_family_arms{arg_0, arg_1}: template_body_cps_provider_2_family_arms(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_ctor_find_key{arg_0, arg_1}: template_body_cps_provider_2_ctor_find_key(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_cid_found{arg_0}: template_body_cps_provider_2_show_cid_found(arg_0)
    case TemplateRequest_cps_provider_2_show_cid_of_key{arg_0, arg_1}: template_body_cps_provider_2_show_cid_of_key(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_arm_bracket_name{arg_0}: template_body_cps_provider_2_show_arm_bracket_name(arg_0)
    case TemplateRequest_cps_provider_2_show_arm_bracket{arg_0}: template_body_cps_provider_2_show_arm_bracket(arg_0)
    case TemplateRequest_cps_provider_2_show_erased_present{arg_0}: template_body_cps_provider_2_show_erased_present(arg_0)
    case TemplateRequest_cps_provider_2_show_field_at_each{arg_0, arg_1, arg_2}: template_body_cps_provider_2_show_field_at_each(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_show_field_at{arg_0, arg_1}: template_body_cps_provider_2_show_field_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_arm_layouts_each{arg_0, arg_1}: template_body_cps_provider_2_show_arm_layouts_each(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_arm_layouts{arg_0, arg_1}: template_body_cps_provider_2_show_arm_layouts(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_node_layout_slots{arg_0}: template_body_cps_provider_2_show_node_layout_slots(arg_0)
    case TemplateRequest_cps_provider_2_show_word_key{arg_0}: template_body_cps_provider_2_show_word_key(arg_0)
    case TemplateRequest_cps_provider_2_show_box_key{arg_0}: template_body_cps_provider_2_show_box_key(arg_0)
    case TemplateRequest_cps_provider_2_lk_text{arg_0}: template_body_cps_provider_2_lk_text(arg_0)
    case TemplateRequest_cps_provider_2_lk_words{arg_0}: template_body_cps_provider_2_lk_words(arg_0)
    case TemplateRequest_cps_provider_2_lk_fields{arg_0}: template_body_cps_provider_2_lk_fields(arg_0)
    case TemplateRequest_cps_provider_2_lk_arms{arg_0}: template_body_cps_provider_2_lk_arms(arg_0)
    case TemplateRequest_cps_provider_2_show_layout_key{arg_0}: template_body_cps_provider_2_show_layout_key(arg_0)
    case TemplateRequest_cps_provider_2_show_arg_tokens{arg_0, arg_1}: template_body_cps_provider_2_show_arg_tokens(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_quantity_key{arg_0}: template_body_cps_provider_2_show_quantity_key(arg_0)
    case TemplateRequest_cps_provider_2_show_maybe_quantity_key{arg_0}: template_body_cps_provider_2_show_maybe_quantity_key(arg_0)
    case TemplateRequest_cps_provider_2_show_pat_tokens{arg_0, arg_1}: template_body_cps_provider_2_show_pat_tokens(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_pat_expand{arg_0}: template_body_cps_provider_2_show_pat_expand(arg_0)

def template_step_group_7(request: TemplateRequestGroup7) -> TemplateProgress<template_result_group_7(request)>:
  match request:
    case TemplateRequest_cps_provider_2_show_desc_expand{arg_0}: template_body_cps_provider_2_show_desc_expand(arg_0)
    case TemplateRequest_cps_provider_2_show_render_tokens{arg_0, arg_1}: template_body_cps_provider_2_show_render_tokens(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_descriptor_key{arg_0}: template_body_cps_provider_2_show_descriptor_key(arg_0)
    case TemplateRequest_cps_provider_2_show_array_cell{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_show_array_cell(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_show_array_element{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_show_array_element(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_show_array_args{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_show_array_args(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_show_advance_array{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_2_show_advance_array(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_2_box_advance{arg_0, arg_1}: template_body_cps_provider_2_box_advance(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_fields_box_each{arg_0, arg_1, arg_2}: template_body_cps_provider_2_fields_box_each(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_fields_box_slots{arg_0, arg_1, arg_2}: template_body_cps_provider_2_fields_box_slots(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_2_fields_box{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_fields_box(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_fields_inline_each{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_fields_inline_each(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_fields_inline_layouts{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_fields_inline_layouts(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_fields_inline{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_fields_inline(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_fields_advance{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_fields_advance(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_show_data_arm_header{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_cps_provider_2_show_data_arm_header(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
    case TemplateRequest_cps_provider_2_show_data_arm_rest{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_show_data_arm_rest(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_show_data_arm_cid{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11}: template_body_cps_provider_2_show_data_arm_cid(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11)
    case TemplateRequest_cps_provider_2_show_data_arm_erased{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11}: template_body_cps_provider_2_show_data_arm_erased(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10, arg_11)
    case TemplateRequest_cps_provider_2_show_data_arm_live{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_cps_provider_2_show_data_arm_live(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
    case TemplateRequest_cps_provider_2_show_data_arm{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_cps_provider_2_show_data_arm(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
    case TemplateRequest_cps_provider_2_show_data_arms{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_show_data_arms(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_show_data_count{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_data_count(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_data_arms_maybe{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_show_data_arms_maybe(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_show_data_key{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_data_key(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_data_head{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_data_head(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_advance_data{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_show_advance_data(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_show_advance_n{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_advance_n(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_advance_kind{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_advance_kind(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_advance_memo{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_2_show_advance_memo(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_2_show_advance_norm{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_advance_norm(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_advance_key{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_advance_key(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_norm_result{arg_0}: template_body_cps_provider_2_show_norm_result(arg_0)
    case TemplateRequest_cps_provider_2_show_norm{arg_0, arg_1}: template_body_cps_provider_2_show_norm(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_advance_error{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_cps_provider_2_show_advance_error(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_cps_provider_2_show_advance_st{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_2_show_advance_st(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_2_show_advance_job{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_show_advance_job(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_run_show{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_run_show(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_show_set_word{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_show_set_word(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_2_show_apply_patches{arg_0, arg_1}: template_body_cps_provider_2_show_apply_patches(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_finish{arg_0, arg_1}: template_body_cps_provider_2_show_finish(arg_0, arg_1)
    case TemplateRequest_cps_provider_2_show_result{arg_0}: template_body_cps_provider_2_show_result(arg_0)
    case TemplateRequest_cps_provider_2_show_root_layout{arg_0}: template_body_cps_provider_2_show_root_layout(arg_0)
    case TemplateRequest_cps_provider_2_show_root{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_2_show_root(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_2_show_build{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_2_show_build(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_3_family_index{arg_0}: template_body_cps_provider_3_family_index(arg_0)
    case TemplateRequest_cps_provider_3_function_index{arg_0}: template_body_cps_provider_3_function_index(arg_0)
    case TemplateRequest_cps_provider_3_nf_context{arg_0, arg_1}: template_body_cps_provider_3_nf_context(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_default_fuel{}: template_body_cps_provider_3_default_fuel()
    case TemplateRequest_cps_provider_3_family_of{arg_0, arg_1}: template_body_cps_provider_3_family_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_function_of{arg_0, arg_1}: template_body_cps_provider_3_function_of(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_native_of{arg_0, arg_1, arg_2}: template_body_cps_provider_3_native_of(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_val_nth{arg_0, arg_1}: template_body_cps_provider_3_val_nth(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_val_at{arg_0, arg_1, arg_2}: template_body_cps_provider_3_val_at(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_val_at_choose{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_3_val_at_choose(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_3_first_vals{arg_0, arg_1}: template_body_cps_provider_3_first_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_drop_vals{arg_0, arg_1}: template_body_cps_provider_3_drop_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_insert_before{arg_0, arg_1, arg_2}: template_body_cps_provider_3_insert_before(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_append_vals{arg_0, arg_1}: template_body_cps_provider_3_append_vals(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_quantity_markers{arg_0}: template_body_cps_provider_3_quantity_markers(arg_0)
    case TemplateRequest_cps_provider_3_renamed_level{arg_0, arg_1}: template_body_cps_provider_3_renamed_level(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_materialize_all_scoped{arg_0, arg_1, arg_2}: template_body_cps_provider_3_materialize_all_scoped(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_materialize_all_at{arg_0, arg_1}: template_body_cps_provider_3_materialize_all_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_materialize_all{arg_0}: template_body_cps_provider_3_materialize_all(arg_0)

def template_step_group_8(request: TemplateRequestGroup8) -> TemplateProgress<template_result_group_8(request)>:
  match request:
    case TemplateRequest_cps_provider_3_materialize_scoped{arg_0, arg_1, arg_2}: template_body_cps_provider_3_materialize_scoped(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_materialize_at{arg_0, arg_1}: template_body_cps_provider_3_materialize_at(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_materialize{arg_0}: template_body_cps_provider_3_materialize(arg_0)
    case TemplateRequest_cps_provider_3_reify_env{arg_0, arg_1, arg_2}: template_body_cps_provider_3_reify_env(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_status_combine{arg_0, arg_1}: template_body_cps_provider_3_status_combine(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_bind_status{arg_0, arg_1}: template_body_cps_provider_3_bind_status(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_bind_values{arg_0, arg_1}: template_body_cps_provider_3_bind_values(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_bind_patterns{arg_0, arg_1}: template_body_cps_provider_3_bind_patterns(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_nf{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_nf_descriptor{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf_descriptor(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_nf_arrow{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_3_nf_arrow(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_3_nf_descriptor_step{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf_descriptor_step(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_nf_all{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf_all(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_nf_apply_args{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_3_nf_apply_args(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_3_nf_apply_source{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_3_nf_apply_source(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_3_nf_apply{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf_apply(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_nf_apply_one{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf_apply_one(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_intrinsic_io{arg_0}: template_body_cps_provider_3_intrinsic_io(arg_0)
    case TemplateRequest_cps_provider_3_nf_named_io{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_3_nf_named_io(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_3_nf_named{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf_named(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_nf_arity{arg_0, arg_1, arg_2}: template_body_cps_provider_3_nf_arity(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_nf_family{arg_0, arg_1}: template_body_cps_provider_3_nf_family(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_nf_family_apply{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_3_nf_family_apply(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_3_nf_reduce{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_cps_provider_3_nf_reduce(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_cps_provider_3_nf_reduce_apply{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_cps_provider_3_nf_reduce_apply(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_cps_provider_3_nf_reduce_body{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_cps_provider_3_nf_reduce_body(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_cps_provider_3_nf_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_cps_provider_3_nf_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_cps_provider_3_normalize{arg_0, arg_1, arg_2, arg_3}: template_body_cps_provider_3_normalize(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_cps_provider_3_normalize_closed{arg_0, arg_1, arg_2}: template_body_cps_provider_3_normalize_closed(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_normalize_in{arg_0, arg_1}: template_body_cps_provider_3_normalize_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_outer_application{arg_0}: template_body_cps_provider_3_outer_application(arg_0)
    case TemplateRequest_cps_provider_3_outer_walk{arg_0, arg_1}: template_body_cps_provider_3_outer_walk(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_answer_in{arg_0, arg_1}: template_body_cps_provider_3_answer_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_answer_descriptor{arg_0, arg_1, arg_2}: template_body_cps_provider_3_answer_descriptor(arg_0, arg_1, arg_2)
    case TemplateRequest_cps_provider_3_answer_normalized{arg_0, arg_1}: template_body_cps_provider_3_answer_normalized(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_is_io_head_in{arg_0, arg_1}: template_body_cps_provider_3_is_io_head_in(arg_0, arg_1)
    case TemplateRequest_cps_provider_3_is_io_head{arg_0, arg_1, arg_2}: template_body_cps_provider_3_is_io_head(arg_0, arg_1, arg_2)

def template_step_one(request: TemplateRequest) -> TemplateProgress<template_result(request)>:
  match request:
    case TemplateRequestGroup_0{inner}: template_step_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_step_group_1(inner)
    case TemplateRequestGroup_2{inner}: template_step_group_2(inner)
    case TemplateRequestGroup_3{inner}: template_step_group_3(inner)
    case TemplateRequestGroup_4{inner}: template_step_group_4(inner)
    case TemplateRequestGroup_5{inner}: template_step_group_5(inner)
    case TemplateRequestGroup_6{inner}: template_step_group_6(inner)
    case TemplateRequestGroup_7{inner}: template_step_group_7(inner)
    case TemplateRequestGroup_8{inner}: template_step_group_8(inner)

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

def template_start(modules: List<&2, Loader.LoadedModule>) -> TemplateRun<PhysSmoke>:
  template_chunk(PhysSmoke, 64n, TemplateRunState{PhysSmoke, TemplatePending{TemplateRequestGroup_0{TemplateRequest_main{modules}}, box => TemplateFinished{box}}, TemplateStackDone{{==}}})
