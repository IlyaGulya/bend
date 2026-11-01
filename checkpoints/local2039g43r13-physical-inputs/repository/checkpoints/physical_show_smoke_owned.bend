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

def fld(+v_0: BIR.Descriptor) -> BIR.DescriptorField:
  BIR.DescriptorField{None{}, BIR.Unrestricted{}, v_0}

def arm(+v_1: String, +v_3: List<&2, BIR.DescriptorField>) -> BIR.DescriptorArm:
  BIR.DescriptorArm{v_1, v_3}

def fam(+v_1: String, +v_4: Maybe<&2, String>, +v_6: Nat, +v_8: List<&2, BIR.DescriptorArm>) -> BIR.Family:
  BIR.Family{v_1, v_1, v_4, 0n, v_6, v_8}

def ref(+v_1: String, +v_3: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  BIR.DescriptorRef{v_1, v_3}

def fam_u32() -> BIR.Family:
  fam("U32", Some{"U32"}, 0n, [])

def fam_pt() -> BIR.Family:
  fam("Pt", None{}, 0n, [arm("Pt", [fld(ref("U32", [])), fld(ref("U32", []))])])

def fam_fl() -> BIR.Family:
  fam("Fl", None{}, 0n, [arm("Fl", [fld(ref("U32", []))])])

def fam_seg() -> BIR.Family:
  fam("Seg", None{}, 0n, [arm("Seg", [fld(ref("Pt", [])), fld(ref("Pt", [])), fld(ref("Fl", []))])])

def families() -> List<&2, BIR.Family>:
  [fam_u32, fam_pt, fam_fl, fam_seg]

def constructors() -> List<&2, BIR.ConstructorLayout>:
  [BIR.ConstructorLayout{16, "Seg", None{}, []}, BIR.ConstructorLayout{17, "Pt", None{}, []}, BIR.ConstructorLayout{18, "Fl", None{}, []}]

def program() -> BIR.Program:
  BIR.Program{[], [], [], families, [], BIR.Library{[]}}

def chain_key(+v_1: Nat) -> String:
  String.append("F", Nat.show(v_1))

def next_key(+v_1: Nat) -> String:
  match v_1:
    case 0n:
      chain_key(0n)
    case 1n+v_5:
      chain_key(v_5)

def fam_chain(+v_1: Nat) -> List<&2, BIR.Family>:
  match v_1:
    case 0n:
      [BIR.Family{chain_key(0n), chain_key(0n), None{}, 0n, 0n, [BIR.DescriptorArm{chain_key(0n), [BIR.DescriptorField{None{}, BIR.Unrestricted{}, ref("U32", [])}]}]}, BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, []}]
    case 1n+v_8:
      BIR.Family{chain_key(v_8), chain_key(v_8), None{}, 0n, 0n, [BIR.DescriptorArm{chain_key(v_8), [BIR.DescriptorField{None{}, BIR.Unrestricted{}, ref(next_key(v_8), [])}]}]} <> fam_chain(v_8)

def ctor_chain(+v_1: Nat) -> List<&2, BIR.ConstructorLayout>:
  match v_1:
    case 0n:
      []
    case 1n+v_4:
      BIR.ConstructorLayout{0, chain_key(v_4), None{}, []} <> ctor_chain(v_4)

def deep_program() -> BIR.Program:
  BIR.Program{[], [], [], fam_chain(400n), [], BIR.Library{[]}}

def summarize(+v_0: cps_provider_2_ShowOut) -> String:
  match v_0:
    case cps_provider_2_ShowOk{v_4, v_5}:
      String.append(Nat.show(List.length(&2, String, String.split(v_4, ','))), String.append("/", Nat.show(List.length(&2, String, String.split(v_5, ',')))))
    case cps_provider_2_ShowFail{v_9}:
      v_9

def deep_text(+v_0: cps_provider_2_ShowOut) -> String:
  match v_0:
    case cps_provider_2_ShowOk{v_4, v_5}:
      String.append(String.append("D", v_4), String.append("|N", v_5))
    case cps_provider_2_ShowFail{v_7}:
      String.append("D!", v_7)

def deep_summary() -> String:
  deep_text(cps_provider_2_show_build(cps_provider_1_context(deep_program), ref("F399", []), ctor_chain(400n), fam_chain(400n)))

def shadow_fams() -> List<&2, BIR.Family>:
  [fam("U32", Some{"U32"}, 0n, []), fam("F32", None{}, 0n, [arm("F32", [fld(ref("U32", []))])]), fam("Nat", None{}, 0n, [arm("Nat", [fld(ref("U32", []))])]), fam("Array", None{}, 0n, [arm("Array", [fld(ref("U32", []))])]), fam("IO.OP", None{}, 0n, [arm("IO.OP", [fld(ref("U32", []))])])]

def shadow_ctors() -> List<&2, BIR.ConstructorLayout>:
  [BIR.ConstructorLayout{30, "F32", None{}, []}, BIR.ConstructorLayout{31, "Nat", None{}, []}, BIR.ConstructorLayout{32, "Array", None{}, []}, BIR.ConstructorLayout{33, "IO.OP", None{}, []}]

def shadow_program() -> BIR.Program:
  BIR.Program{[], [], [], shadow_fams, [], BIR.Library{[]}}

def native_match_shadow_one_0(v_15: cps_provider_2_ShowOut, +v_1: String) -> String:
  match v_15:
    case cps_provider_2_ShowOk{v_11, v_12}:
      String.append(String.append(v_1, "="), String.append(v_11, String.append("@", v_12)))
    case cps_provider_2_ShowFail{v_14}:
      String.append(String.append(v_1, "!"), v_14)

def shadow_one(+v_1: String, +v_3: cps_provider_1_Context) -> String:
  native_match_shadow_one_0(cps_provider_2_show_build(v_3, ref(v_1, []), shadow_ctors, shadow_fams), v_1)

def shadow_summary() -> String:
  v_3 = cps_provider_1_context(shadow_program)
  String.append(shadow_one("F32", v_3), String.append(";", String.append(shadow_one("Nat", v_3), String.append(";", String.append(shadow_one("Array", v_3), String.append(";", shadow_one("IO.OP", v_3)))))))

def native_match_key_pair_0(v_14: Maybe<&2, String>, v_15: Maybe<&2, String>) -> String:
  match v_14, v_15:
    case Some{v_7}, Some{v_8}:
      Bool.pick(String, String.eq(v_7, v_8), "SAME", "SEP")
    case _, _:
      "FAIL"

def key_pair(+v_0: BIR.Descriptor, +v_1: BIR.Descriptor) -> String:
  native_match_key_pair_0(cps_provider_2_show_descriptor_key(v_0), cps_provider_2_show_descriptor_key(v_1))

def native_match_deep_key_probe_0(v_14: Maybe<&2, String>, v_15: Maybe<&2, String>) -> String:
  match v_14, v_15:
    case Some{v_7}, Some{v_8}:
      Bool.pick(String, String.eq(v_7, v_8), "K-SAME", "K-DIFF")
    case _, _:
      "K-FAIL"

def deep_key_probe() -> String:
  native_match_deep_key_probe_0(cps_provider_2_show_descriptor_key(ref("U32", [])), cps_provider_2_show_descriptor_key(ref("F0", [])))

def key_checks() -> String:
  String.append(key_pair(BIR.DescriptorRef{"@T", []}, BIR.DescriptorConstructor{"T", []}), String.append(key_pair(BIR.DescriptorParameter{1n}, BIR.DescriptorRef{"1", []}), String.append(key_pair(BIR.DescriptorQuantity{BIR.Once{}}, BIR.DescriptorKind{BIR.DescriptorNull{}}), String.append(key_pair(BIR.DescriptorRef{"x", []}, BIR.DescriptorConstructor{"x", []}), deep_key_probe))))

def multi_fams() -> List<&2, BIR.Family>:
  [fam("U32", Some{"U32"}, 0n, []), fam("Choice", None{}, 0n, [arm("ChA", [fld(ref("U32", []))]), arm("ChB", [fld(ref("U32", []))]), arm("ChC", [fld(ref("U32", []))])])]

def multi_ctors() -> List<&2, BIR.ConstructorLayout>:
  [BIR.ConstructorLayout{40, "ChA", None{}, []}, BIR.ConstructorLayout{41, "ChB", None{}, []}, BIR.ConstructorLayout{42, "ChC", None{}, []}]

def multi_program() -> BIR.Program:
  BIR.Program{[], [], [], multi_fams, [], BIR.Library{[]}}

def multi_text(+v_0: cps_provider_2_ShowOut) -> String:
  match v_0:
    case cps_provider_2_ShowOk{v_4, v_5}:
      String.append(String.append("C", v_4), String.append("|M", v_5))
    case cps_provider_2_ShowFail{v_7}:
      String.append("C!", v_7)

def multi_summary() -> String:
  multi_text(cps_provider_2_show_build(cps_provider_1_context(multi_program), ref("Choice", []), multi_ctors, multi_fams))

def main(v_1: List<&2, Loader.LoadedModule>) -> PhysSmoke:
  v_5 = cps_provider_1_context(program)
  unwrap(cps_provider_2_show_build(v_5, ref("Seg", []), constructors, families), String.append(deep_summary, String.append("|", String.append(shadow_summary, String.append("|K:", String.append(key_checks, String.append("|", multi_summary)))))))

def unwrap(+v_0: cps_provider_2_ShowOut, +v_2: String) -> PhysSmoke:
  match v_0:
    case cps_provider_2_ShowOk{v_6, v_7}:
      PhysSmoke{v_6, String.append(v_7, String.append("|", v_2))}
    case cps_provider_2_ShowFail{v_9}:
      PhysSmoke{v_9, v_2}

def cps_provider_1_context(+v_0: BIR.Program) -> cps_provider_1_Context:
  match v_0:
    case BIR.Program{+v_8, +v_9, +v_10, +v_11, +v_12, +v_13}:
      +v_15 = cps_provider_3_nf_context(v_11, v_12)
      +v_18 = cps_provider_1_plan_arm_index(v_11)
      +v_22 = {cps_provider_1_Context{v_15, v_11, cps_provider_1_Plan{Map.new(&2, cps_provider_1_NodeResult), v_18}} : cps_provider_1_Context}
      cps_provider_1_Context{v_15, v_11, cps_provider_1_Plan{cps_provider_1_plan_node_index(v_22, v_10), v_18}}

def cps_provider_1_context_nf(+v_1: cps_provider_1_Context) -> cps_provider_3_NfContext:
  match v_1:
    case cps_provider_1_Context{+v_5, +v_6, +v_7}:
      v_5

def cps_provider_1_context_families(+v_1: cps_provider_1_Context) -> List<&2, BIR.Family>:
  match v_1:
    case cps_provider_1_Context{+v_6, +v_7, +v_8}:
      v_7

def cps_provider_1_context_plan(+v_1: cps_provider_1_Context) -> cps_provider_1_Plan:
  match v_1:
    case cps_provider_1_Context{+v_6, +v_7, +v_8}:
      v_8

def native_match_cps_provider_1_context_nodes_0(v_9: cps_provider_1_Plan) -> Map<&2, cps_provider_1_NodeResult>:
  match v_9:
    case cps_provider_1_Plan{+v_7, +v_8}:
      v_7

def cps_provider_1_context_nodes(+v_1: cps_provider_1_Context) -> Map<&2, cps_provider_1_NodeResult>:
  native_match_cps_provider_1_context_nodes_0(cps_provider_1_context_plan(v_1))

def native_match_cps_provider_1_context_arms_0(v_8: cps_provider_1_Plan) -> Map<&2, BIR.DescriptorArm>:
  match v_8:
    case cps_provider_1_Plan{+v_6, +v_7}:
      v_7

def cps_provider_1_context_arms(+v_1: cps_provider_1_Context) -> Map<&2, BIR.DescriptorArm>:
  native_match_cps_provider_1_context_arms_0(cps_provider_1_context_plan(v_1))

def cps_provider_1_nf_families(+v_0: cps_provider_3_NfContext) -> Map<&2, BIR.Family>:
  match v_0:
    case cps_provider_3_NfContext{+v_4, +v_5}:
      v_4

def cps_provider_1_nf_functions(+v_0: cps_provider_3_NfContext) -> Map<&2, BIR.TypeFunction>:
  match v_0:
    case cps_provider_3_NfContext{+v_4, +v_5}:
      v_5

def cps_provider_1_family_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> Maybe<&2, BIR.Family>:
  cps_provider_3_family_of(v_3, cps_provider_1_nf_families(cps_provider_1_context_nf(v_1)))

def cps_provider_1_function_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> Maybe<&2, BIR.TypeFunction>:
  cps_provider_3_function_of(v_3, cps_provider_1_nf_functions(cps_provider_1_context_nf(v_1)))

def native_match_cps_provider_1_arm_of_0(v_24: Maybe<&2, BIR.DescriptorArm>, +v_1: String, v_8: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_24:
    case Some{+v_23}:
      Some{v_23}
    case None{}:
      cps_provider_1_arm_of(v_1, v_8)

def native_match_cps_provider_1_arm_of_1(+v_7: BIR.Family, +v_1: String, v_8: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_7:
    case BIR.Family{+v_15, +v_16, +v_17, +v_18, +v_19, +v_20}:
      native_match_cps_provider_1_arm_of_0(cps_provider_1_arm_in(v_1, v_20), v_1, v_8)

def native_match_cps_provider_1_arm_of_2(+v_3: List<&2, BIR.Family>, +v_1: String) -> Maybe<&2, BIR.DescriptorArm>:
  match v_3:
    case []:
      None{}
    case +v_7 <> v_8:
      native_match_cps_provider_1_arm_of_1(v_7, v_1, v_8)

def cps_provider_1_arm_of(+v_1: String, +v_3: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  native_match_cps_provider_1_arm_of_2(v_3, v_1)

def native_match_cps_provider_1_arm_in_0(v_13: Bool, +v_1: String, +v_7: BIR.DescriptorArm, v_8: List<&2, BIR.DescriptorArm>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_13:
    case True{}:
      Some{v_7}
    case False{}:
      cps_provider_1_arm_in(v_1, v_8)

def native_match_cps_provider_1_arm_in_1(+v_7: BIR.DescriptorArm, +v_1: String, v_8: List<&2, BIR.DescriptorArm>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_7:
    case BIR.DescriptorArm{+v_11, +v_12}:
      native_match_cps_provider_1_arm_in_0(String.eq(v_1, v_11), v_1, v_7, v_8)

def native_match_cps_provider_1_arm_in_2(+v_3: List<&2, BIR.DescriptorArm>, +v_1: String) -> Maybe<&2, BIR.DescriptorArm>:
  match v_3:
    case []:
      None{}
    case +v_7 <> v_8:
      native_match_cps_provider_1_arm_in_1(v_7, v_1, v_8)

def cps_provider_1_arm_in(+v_1: String, +v_3: List<&2, BIR.DescriptorArm>) -> Maybe<&2, BIR.DescriptorArm>:
  native_match_cps_provider_1_arm_in_2(v_3, v_1)

def cps_provider_1_plan_arm_index(+v_1: List<&2, BIR.Family>) -> Map<&2, BIR.DescriptorArm>:
  match v_1:
    case []:
      Map.new(&2, BIR.DescriptorArm)
    case +v_5 <> v_6:
      match v_5:
        case BIR.Family{+v_13, +v_14, +v_15, +v_16, +v_17, +v_18}:
          cps_provider_1_plan_family_arms(v_18, cps_provider_1_plan_arm_index(v_6))

def cps_provider_1_plan_family_arms(+v_1: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>) -> Map<&2, BIR.DescriptorArm>:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      match v_7:
        case BIR.DescriptorArm{+v_11, +v_12}:
          Map.set(&2, BIR.DescriptorArm, cps_provider_1_plan_family_arms(v_8, v_3), v_11, {BIR.DescriptorArm{v_11, v_12} : BIR.DescriptorArm})

def cps_provider_1_arm_declared(+v_1: cps_provider_1_Context, +v_3: String) -> Maybe<&2, BIR.DescriptorArm>:
  IndexLookup.find(BIR.DescriptorArm, cps_provider_1_context_arms(v_1), v_3)

def cps_provider_1_live_field(+v_0: BIR.Quantity) -> Bool:
  match v_0:
    case BIR.Erased{}:
      False{}
    case _:
      True{}

def cps_provider_1_layout_fuel() -> Nat:
  1024n

def cps_provider_1_nf_of(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: Nat) -> cps_provider_3_Nf:
  cps_provider_3_nf(cps_provider_1_context_nf(v_1), v_2, v_4, 0n, v_6)

def cps_provider_1_value_layout(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_LayoutResult:
  cps_provider_1_layout_of_desc(v_1, v_2, [], cps_provider_1_layout_fuel)

def native_match_cps_provider_1_layout_of_desc_0(v_14: cps_provider_3_Nf, +v_1: cps_provider_1_Context, +v_7: Nat) -> cps_provider_1_LayoutResult:
  match v_14:
    case cps_provider_3_NfFail{+v_11}:
      cps_provider_1_LayoutFailed{v_11}
    case cps_provider_3_NfOk{+v_13}:
      cps_provider_1_layout_of_val(v_1, v_13, v_7)

def cps_provider_1_layout_of_desc(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_of_desc_0(cps_provider_1_nf_of(v_1, v_2, v_5, v_7), v_1, v_7)

def native_match_cps_provider_1_layout_of_val_0(v_6: Bool, +v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat) -> cps_provider_1_LayoutResult:
  match v_6:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case False{}:
      cps_provider_1_layout_val(v_1, v_3, Nat.sub(v_5, 1n))

def cps_provider_1_layout_of_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_of_val_0(Nat.is_eq(v_5, 0n), v_1, v_3, v_5)

def native_match_cps_provider_1_layout_val_0(v_30: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_5: Nat, +v_9: String, +v_10: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_LayoutResult:
  match v_30:
    case Some{+v_13}:
      cps_provider_1_layout_family(v_1, v_13, v_10, v_5)
    case None{}:
      cps_provider_1_layout_unresolved(v_1, v_9)

def native_match_cps_provider_1_layout_val_1(+v_3: cps_provider_3_NfVal, +v_1: cps_provider_1_Context, +v_5: Nat) -> cps_provider_1_LayoutResult:
  match v_3:
    case cps_provider_3_NfType{+v_9, +v_10}:
      native_match_cps_provider_1_layout_val_0(cps_provider_1_family_lookup(v_1, v_9), v_1, v_5, v_9, v_10)
    case cps_provider_3_NfCtor{+v_18, +v_19}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_3_NfQuantity{+v_21}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_3_NfKind{+v_23}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_3_NfOther{+v_25}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_3_NfMissing{+v_27}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case _:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}

def cps_provider_1_layout_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_val_1(v_3, v_1, v_5)

def native_match_cps_provider_1_layout_unresolved_0(v_8: Maybe<&2, BIR.TypeFunction>, +v_3: String) -> cps_provider_1_LayoutResult:
  match v_8:
    case Some{+v_7}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case None{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxUnresolved{v_3}}}

def cps_provider_1_layout_unresolved(+v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_unresolved_0(cps_provider_1_function_lookup(v_1, v_3), v_3)

def native_match_cps_provider_1_layout_family_0(+v_17: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_15: String, +v_20: List<&2, BIR.DescriptorArm>) -> cps_provider_1_LayoutResult:
  match v_17:
    case Some{+v_23}:
      cps_provider_1_layout_native(v_1, v_23, v_15, v_20, v_5, v_7)
    case None{}:
      cps_provider_1_layout_data(v_1, v_15, v_20, v_5, v_7)

def native_match_cps_provider_1_layout_family_1(v_24: Bool, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_15: String, +v_17: Maybe<&2, String>, +v_20: List<&2, BIR.DescriptorArm>) -> cps_provider_1_LayoutResult:
  match v_24:
    case False{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case True{}:
      native_match_cps_provider_1_layout_family_0(v_17, v_1, v_5, v_7, v_15, v_20)

def native_match_cps_provider_1_layout_family_2(+v_2: BIR.Family, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_1_LayoutResult:
  match v_2:
    case BIR.Family{+v_15, +v_16, +v_17, +v_18, +v_19, +v_20}:
      native_match_cps_provider_1_layout_family_1(Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_5), v_19), v_1, v_5, v_7, v_15, v_17, v_20)

def cps_provider_1_layout_family(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_family_2(v_2, v_1, v_5, v_7)

def native_match_cps_provider_1_layout_native_0(v_17: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> cps_provider_1_LayoutResult:
  match v_17:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxIo{}}}
    case False{}:
      cps_provider_1_layout_data(v_1, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_layout_native_1(v_16: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> cps_provider_1_LayoutResult:
  match v_16:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxArray{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_0(String.eq(v_3, "IO.OP"), v_1, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_layout_native_2(v_15: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> cps_provider_1_LayoutResult:
  match v_15:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_1(String.eq(v_3, "Array"), v_1, v_3, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_layout_native_3(v_14: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> cps_provider_1_LayoutResult:
  match v_14:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_2(String.eq(v_3, "F32"), v_1, v_3, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_layout_native_4(v_13: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> cps_provider_1_LayoutResult:
  match v_13:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord64{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_3(String.eq(v_3, "U32"), v_1, v_3, v_5, v_7, v_10, v_12)

def cps_provider_1_layout_native(+v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_3_NfVal>, +v_12: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_native_4(String.eq(v_3, "Nat"), v_1, v_3, v_5, v_7, v_10, v_12)

def cps_provider_1_field_scope(+v_1: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  +v_4 = {cps_provider_3_NfMissing{BIR.DescriptorNull{}} : cps_provider_3_NfVal}
  List.append(&2, cps_provider_3_NfVal, v_1, [v_4])

def native_match_cps_provider_1_arm_layouts_0(v_27: cps_provider_1_Layouts, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>, v_17: List<&2, BIR.DescriptorArm>, +v_20: String) -> cps_provider_1_Plans:
  match v_27:
    case cps_provider_1_LayoutsFail{+v_24}:
      cps_provider_1_PlansFail{v_24}
    case cps_provider_1_LayoutsOk{+v_26}:
      cps_provider_1_arm_layouts(v_1, v_17, v_6, v_8, cps_provider_1_LayArm{v_20, v_26} <> v_11)

def native_match_cps_provider_1_arm_layouts_1(+v_16: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>, v_17: List<&2, BIR.DescriptorArm>) -> cps_provider_1_Plans:
  match v_16:
    case BIR.DescriptorArm{+v_20, +v_21}:
      native_match_cps_provider_1_arm_layouts_0(cps_provider_1_field_layouts(v_1, v_21, v_6, v_8, []), v_1, v_6, v_8, v_11, v_17, v_20)

def native_match_cps_provider_1_arm_layouts_2(+v_3: List<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>) -> cps_provider_1_Plans:
  match v_3:
    case []:
      cps_provider_1_PlansOk{List.reverse(&2, cps_provider_1_LayArm, v_11)}
    case +v_16 <> v_17:
      native_match_cps_provider_1_arm_layouts_1(v_16, v_1, v_6, v_8, v_11, v_17)

def cps_provider_1_arm_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>) -> cps_provider_1_Plans:
  native_match_cps_provider_1_arm_layouts_2(v_3, v_1, v_6, v_8, v_11)

def native_match_cps_provider_1_field_layouts_0(v_35: cps_provider_1_LayoutResult, +v_1: cps_provider_1_Context, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, v_17: List<&2, BIR.DescriptorField>, +v_26: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_Layouts:
  match v_35:
    case cps_provider_1_LayoutFailed{+v_31}:
      cps_provider_1_LayoutsFail{v_31}
    case cps_provider_1_LayoutFound{+v_33}:
      cps_provider_1_field_layouts(v_1, v_17, v_26, v_8, v_33 <> v_11)

def native_match_cps_provider_1_field_layouts_1(v_34: Bool, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, v_17: List<&2, BIR.DescriptorField>, +v_23: BIR.Descriptor, +v_26: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_Layouts:
  match v_34:
    case False{}:
      cps_provider_1_field_layouts(v_1, v_17, v_26, v_8, v_11)
    case True{}:
      native_match_cps_provider_1_field_layouts_0(cps_provider_1_layout_of_desc(v_1, v_23, v_6, v_8), v_1, v_8, v_11, v_17, v_26)

def native_match_cps_provider_1_field_layouts_2(+v_16: BIR.DescriptorField, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, v_17: List<&2, BIR.DescriptorField>) -> cps_provider_1_Layouts:
  match v_16:
    case BIR.DescriptorField{+v_21, +v_22, +v_23}:
      +v_26 = cps_provider_1_field_scope(v_6)
      native_match_cps_provider_1_field_layouts_1(cps_provider_1_live_field(v_22), v_1, v_6, v_8, v_11, v_17, v_23, v_26)

def native_match_cps_provider_1_field_layouts_3(+v_3: List<&2, BIR.DescriptorField>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> cps_provider_1_Layouts:
  match v_3:
    case []:
      cps_provider_1_LayoutsOk{List.reverse(&2, cps_provider_1_Layout, v_11)}
    case +v_16 <> v_17:
      native_match_cps_provider_1_field_layouts_2(v_16, v_1, v_6, v_8, v_11, v_17)

def cps_provider_1_field_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> cps_provider_1_Layouts:
  native_match_cps_provider_1_field_layouts_3(v_3, v_1, v_6, v_8, v_11)

def native_match_cps_provider_1_layout_data_0(v_27: Bool, +v_17: List<&2, cps_provider_1_LayArm>, +v_21: List<&2, cps_provider_1_CWord>, +v_24: Nat) -> cps_provider_1_LayoutResult:
  match v_27:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxWide{v_24}}}
    case False{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutData{v_21, v_17}}

def native_match_cps_provider_1_layout_data_1(v_26: cps_provider_1_Plans) -> cps_provider_1_LayoutResult:
  match v_26:
    case cps_provider_1_PlansFail{+v_15}:
      cps_provider_1_LayoutFailed{v_15}
    case cps_provider_1_PlansOk{+v_17}:
      +v_21 = cps_provider_1_pack_arms(v_17, cps_provider_1_arms_tagged(v_17))
      +v_24 = List.length(&2, cps_provider_1_CWord, v_21)
      native_match_cps_provider_1_layout_data_0(Nat.is_gt(v_24, 8n), v_17, v_21, v_24)

def native_match_cps_provider_1_layout_data_2(v_25: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> cps_provider_1_LayoutResult:
  match v_25:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxRecursive{v_3}}}
    case False{}:
      native_match_cps_provider_1_layout_data_1(cps_provider_1_arm_layouts(v_1, v_5, v_8, v_10, []))

def cps_provider_1_layout_data(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_data_2(cps_provider_1_reenters(v_1, v_3, v_5, v_8, v_10), v_1, v_3, v_5, v_8, v_10)

def cps_provider_1_arms_tagged(+v_2: List<&2, cps_provider_1_LayArm>) -> Bool:
  match v_2:
    case []:
      False{}
    case [+v_5]:
      False{}
    case _:
      True{}

def native_match_cps_provider_1_reenters_0(v_21: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_21:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_reenters(v_1, v_3, v_16, v_8, v_10)

def native_match_cps_provider_1_reenters_1(+v_15: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_15:
    case BIR.DescriptorArm{+v_19, +v_20}:
      native_match_cps_provider_1_reenters_0(cps_provider_1_fields_reach(v_1, v_20, v_8, v_3, [], v_10), v_1, v_3, v_8, v_10, v_16)

def native_match_cps_provider_1_reenters_2(+v_5: List<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> Bool:
  match v_5:
    case []:
      cps_provider_1_args_reach(v_1, v_8, v_3, [], v_10)
    case +v_15 <> v_16:
      native_match_cps_provider_1_reenters_1(v_15, v_1, v_3, v_8, v_10, v_16)

def cps_provider_1_reenters(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> Bool:
  native_match_cps_provider_1_reenters_2(v_5, v_1, v_3, v_8, v_10)

def native_match_cps_provider_1_fields_reach_0(v_29: Bool, +v_1: cps_provider_1_Context, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorField>, +v_27: List<&2, cps_provider_3_NfVal>) -> Bool:
  match v_29:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_fields_reach(v_1, v_18, v_27, v_8, v_11, v_13)

def native_match_cps_provider_1_fields_reach_1(v_28: Bool, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorField>, +v_24: BIR.Descriptor, +v_27: List<&2, cps_provider_3_NfVal>) -> Bool:
  match v_28:
    case False{}:
      cps_provider_1_fields_reach(v_1, v_18, v_27, v_8, v_11, v_13)
    case True{}:
      native_match_cps_provider_1_fields_reach_0(cps_provider_1_reaches(v_1, v_24, v_6, v_8, v_11, v_13), v_1, v_8, v_11, v_13, v_18, v_27)

def native_match_cps_provider_1_fields_reach_2(+v_17: BIR.DescriptorField, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorField>) -> Bool:
  match v_17:
    case BIR.DescriptorField{+v_22, +v_23, +v_24}:
      +v_27 = cps_provider_1_field_scope(v_6)
      native_match_cps_provider_1_fields_reach_1(cps_provider_1_live_field(v_23), v_1, v_6, v_8, v_11, v_13, v_18, v_24, v_27)

def native_match_cps_provider_1_fields_reach_3(+v_3: List<&2, BIR.DescriptorField>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  match v_3:
    case []:
      False{}
    case +v_17 <> v_18:
      native_match_cps_provider_1_fields_reach_2(v_17, v_1, v_6, v_8, v_11, v_13, v_18)

def cps_provider_1_fields_reach(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  native_match_cps_provider_1_fields_reach_3(v_3, v_1, v_6, v_8, v_11, v_13)

def native_match_cps_provider_1_reaches_0(v_20: cps_provider_3_Nf, +v_1: cps_provider_1_Context, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_20:
    case cps_provider_3_NfFail{+v_16}:
      False{}
    case cps_provider_3_NfOk{+v_18}:
      cps_provider_1_reaches_val(v_1, v_18, v_7, v_10, Nat.sub(v_12, 1n))

def native_match_cps_provider_1_reaches_1(v_19: Bool, +v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_19:
    case True{}:
      False{}
    case False{}:
      native_match_cps_provider_1_reaches_0(cps_provider_1_nf_of(v_1, v_2, v_5, v_12), v_1, v_7, v_10, v_12)

def cps_provider_1_reaches(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  native_match_cps_provider_1_reaches_1(Nat.is_eq(v_12, 0n), v_1, v_2, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_reaches_val_0(v_28: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_15: List<&2, cps_provider_3_NfVal>) -> Bool:
  match v_28:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_args_reach(v_1, v_15, v_5, v_8, v_10)

def native_match_cps_provider_1_reaches_val_1(v_27: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String, +v_15: List<&2, cps_provider_3_NfVal>) -> Bool:
  match v_27:
    case None{}:
      cps_provider_1_args_reach(v_1, v_15, v_5, v_8, v_10)
    case Some{+v_20}:
      native_match_cps_provider_1_reaches_val_0(cps_provider_1_family_reach(v_1, v_20, v_15, v_5, v_14 <> v_8, v_10), v_1, v_5, v_8, v_10, v_15)

def native_match_cps_provider_1_reaches_val_2(v_26: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String, +v_15: List<&2, cps_provider_3_NfVal>) -> Bool:
  match v_26:
    case True{}:
      False{}
    case False{}:
      native_match_cps_provider_1_reaches_val_1(cps_provider_1_family_lookup(v_1, v_14), v_1, v_5, v_8, v_10, v_14, v_15)

def native_match_cps_provider_1_reaches_val_3(v_25: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String, +v_15: List<&2, cps_provider_3_NfVal>) -> Bool:
  match v_25:
    case True{}:
      True{}
    case False{}:
      native_match_cps_provider_1_reaches_val_2(cps_provider_1_str_member(v_8, v_14), v_1, v_5, v_8, v_10, v_14, v_15)

def native_match_cps_provider_1_reaches_val_4(+v_3: cps_provider_3_NfVal, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> Bool:
  match v_3:
    case cps_provider_3_NfType{+v_14, +v_15}:
      native_match_cps_provider_1_reaches_val_3(String.eq(v_14, v_5), v_1, v_5, v_8, v_10, v_14, v_15)
    case _:
      False{}

def cps_provider_1_reaches_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> Bool:
  native_match_cps_provider_1_reaches_val_4(v_3, v_1, v_5, v_8, v_10)

def native_match_cps_provider_1_family_reach_0(v_30: Bool, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_30:
    case True{}:
      False{}
    case False{}:
      cps_provider_1_reach_arms(v_1, v_25, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_family_reach_1(+v_22: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_22:
    case Some{+v_28}:
      native_match_cps_provider_1_family_reach_0(String.eq(v_28, "Array"), v_1, v_5, v_7, v_10, v_12, v_25)
    case None{}:
      cps_provider_1_reach_arms(v_1, v_25, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_family_reach_2(v_29: Bool, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_22: Maybe<&2, String>, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_29:
    case False{}:
      False{}
    case True{}:
      native_match_cps_provider_1_family_reach_1(v_22, v_1, v_5, v_7, v_10, v_12, v_25)

def native_match_cps_provider_1_family_reach_3(+v_2: BIR.Family, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_2:
    case BIR.Family{+v_20, +v_21, +v_22, +v_23, +v_24, +v_25}:
      native_match_cps_provider_1_family_reach_2(Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_5), v_24), v_1, v_5, v_7, v_10, v_12, v_22, v_25)

def cps_provider_1_family_reach(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  native_match_cps_provider_1_family_reach_3(v_2, v_1, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_reach_arms_0(v_23: Bool, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_23:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_reach_arms(v_1, v_18, v_6, v_8, v_11, v_13)

def native_match_cps_provider_1_reach_arms_1(+v_17: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_17:
    case BIR.DescriptorArm{+v_21, +v_22}:
      native_match_cps_provider_1_reach_arms_0(cps_provider_1_fields_reach(v_1, v_22, v_6, v_8, v_11, v_13), v_1, v_6, v_8, v_11, v_13, v_18)

def native_match_cps_provider_1_reach_arms_2(+v_3: List<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  match v_3:
    case []:
      False{}
    case +v_17 <> v_18:
      native_match_cps_provider_1_reach_arms_1(v_17, v_1, v_6, v_8, v_11, v_13, v_18)

def cps_provider_1_reach_arms(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  native_match_cps_provider_1_reach_arms_2(v_3, v_1, v_6, v_8, v_11, v_13)

def native_match_cps_provider_1_args_reach_0(v_17: Bool, +v_1: cps_provider_1_Context, +v_6: String, +v_9: List<&2, String>, +v_11: Nat, v_16: List<&2, cps_provider_3_NfVal>) -> Bool:
  match v_17:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_args_reach(v_1, v_16, v_6, v_9, v_11)

def native_match_cps_provider_1_args_reach_1(+v_4: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_1_Context, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> Bool:
  match v_4:
    case []:
      False{}
    case +v_15 <> v_16:
      native_match_cps_provider_1_args_reach_0(cps_provider_1_reaches_val(v_1, v_15, v_6, v_9, v_11), v_1, v_6, v_9, v_11, v_16)

def cps_provider_1_args_reach(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> Bool:
  native_match_cps_provider_1_args_reach_1(v_4, v_1, v_6, v_9, v_11)

def native_match_cps_provider_1_str_member_0(v_10: Bool, +v_4: String, v_9: List<&2, String>) -> Bool:
  match v_10:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_str_member(v_9, v_4)

def native_match_cps_provider_1_str_member_1(+v_2: List<&2, String>, +v_4: String) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_8 <> v_9:
      native_match_cps_provider_1_str_member_0(String.eq(v_8, v_4), v_4, v_9)

def cps_provider_1_str_member(+v_2: List<&2, String>, +v_4: String) -> Bool:
  native_match_cps_provider_1_str_member_1(v_2, v_4)

def cps_provider_1_layout_kinds(+v_1: cps_provider_1_Layout) -> List<&2, cps_provider_1_CWord>:
  match v_1:
    case cps_provider_1_LayoutWord{+v_5}:
      [v_5]
    case cps_provider_1_LayoutBox{+v_7}:
      [cps_provider_1_CWordBox{}]
    case cps_provider_1_LayoutData{+v_10, +v_11}:
      v_10

def cps_provider_1_layout_words(+v_1: cps_provider_1_Layout) -> Nat:
  List.length(&2, cps_provider_1_CWord, cps_provider_1_layout_kinds(v_1))

def cps_provider_1_canonical_word(+v_1: cps_provider_1_Layout) -> cps_provider_1_CWord:
  match v_1:
    case cps_provider_1_LayoutWord{+v_4}:
      v_4
    case _:
      cps_provider_1_CWordBox{}

def cps_provider_1_pack_arms(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Bool) -> List<&2, cps_provider_1_CWord>:
  match v_4:
    case True{}:
      cps_provider_1_pack_arm_list(v_2, 1n, [cps_provider_1_CWord32{}])
    case False{}:
      cps_provider_1_pack_arm_list(v_2, 0n, [])

def cps_provider_1_pack_arm_list(+v_2: List<&2, cps_provider_1_LayArm>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> List<&2, cps_provider_1_CWord>:
  match v_2:
    case []:
      v_7
    case +v_12 <> v_13:
      match v_12:
        case cps_provider_1_LayArm{+v_16, +v_17}:
          cps_provider_1_pack_arm_list(v_13, v_4, cps_provider_1_pack_field_list(v_17, v_4, v_7))

def cps_provider_1_pack_field_list(+v_2: List<&2, cps_provider_1_Layout>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> List<&2, cps_provider_1_CWord>:
  match v_2:
    case []:
      v_7
    case +v_12 <> v_13:
      +v_16 = cps_provider_1_layout_kinds(v_12)
      cps_provider_1_pack_field_list(v_13, Nat.add(v_4, List.length(&2, cps_provider_1_CWord, v_16)), cps_provider_1_pack_kinds(v_16, v_4, v_7))

def cps_provider_1_pack_kinds(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_7: List<&2, cps_provider_1_CWord>) -> List<&2, cps_provider_1_CWord>:
  match v_2:
    case []:
      v_7
    case +v_12 <> v_13:
      cps_provider_1_pack_kinds(v_13, Nat.add(v_4, 1n), cps_provider_1_set_kind(v_7, v_4, v_12))

def cps_provider_1_set_kind(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat, +v_6: cps_provider_1_CWord) -> List<&2, cps_provider_1_CWord>:
  match v_2, v_4:
    case [], 0n:
      [cps_provider_1_merge_kind(cps_provider_1_CWord32{}, v_6)]
    case +v_12 <> v_13, 0n:
      cps_provider_1_merge_kind(v_12, v_6) <> v_13
    case [], 1n+v_16:
      cps_provider_1_CWord32{} <> cps_provider_1_set_kind([], v_16, v_6)
    case +v_21 <> v_22, 1n+v_23:
      v_21 <> cps_provider_1_set_kind(v_22, v_23, v_6)

def cps_provider_1_merge_kind(+v_1: cps_provider_1_CWord, +v_3: cps_provider_1_CWord) -> cps_provider_1_CWord:
  match v_1:
    case cps_provider_1_CWordBox{}:
      v_1
    case _:
      match v_3:
        case cps_provider_1_CWord32{}:
          v_1
        case _:
          v_3

def cps_provider_1_word_32(+v_1: cps_provider_1_CWord) -> Bool:
  match v_1:
    case cps_provider_1_CWord32{}:
      True{}
    case _:
      False{}

def native_match_cps_provider_1_pad_words_0(v_12: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_10: Nat) -> List<&2, cps_provider_1_CWord>:
  match v_12:
    case True{}:
      v_2
    case False{}:
      cps_provider_1_pad_to(v_2, v_10)

def native_match_cps_provider_1_pad_words_1(v_11: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_7: Nat) -> List<&2, cps_provider_1_CWord>:
  match v_11:
    case False{}:
      v_2
    case True{}:
      +v_10 = cps_provider_1_pow2_upto(1n, v_7)
      native_match_cps_provider_1_pad_words_0(Nat.is_eq(v_10, v_7), v_2, v_10)

def cps_provider_1_pad_words(+v_2: List<&2, cps_provider_1_CWord>) -> List<&2, cps_provider_1_CWord>:
  +v_7 = List.length(&2, cps_provider_1_CWord, v_2)
  native_match_cps_provider_1_pad_words_1(Nat.is_gt(v_7, 247n), v_2, v_7)

def native_match_cps_provider_1_pad_to_0(v_10: Bool, +v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat) -> List<&2, cps_provider_1_CWord>:
  match v_10:
    case True{}:
      v_2
    case False{}:
      cps_provider_1_pad_to(List.append(&2, cps_provider_1_CWord, v_2, [cps_provider_1_CWord32{}]), v_4)

def cps_provider_1_pad_to(+v_2: List<&2, cps_provider_1_CWord>, +v_4: Nat) -> List<&2, cps_provider_1_CWord>:
  native_match_cps_provider_1_pad_to_0(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_2), v_4), v_2, v_4)

def native_match_cps_provider_1_pow2_upto_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> Nat:
  match v_4:
    case True{}:
      cps_provider_1_pow2_upto(Nat.mul(v_1, 2n), v_3)
    case False{}:
      v_1

def cps_provider_1_pow2_upto(+v_1: Nat, +v_3: Nat) -> Nat:
  native_match_cps_provider_1_pow2_upto_0(Nat.is_lt(v_1, v_3), v_1, v_3)

def native_match_cps_provider_1_ceil_log2_0(v_2: Bool, +v_1: Nat) -> Nat:
  match v_2:
    case False{}:
      0n
    case True{}:
      cps_provider_1_ceil_log2_go(1n, 0n, v_1)

def cps_provider_1_ceil_log2(+v_1: Nat) -> Nat:
  native_match_cps_provider_1_ceil_log2_0(Nat.is_gt(v_1, 1n), v_1)

def native_match_cps_provider_1_ceil_log2_go_0(v_7: Bool, +v_1: Nat, +v_3: Nat, +v_5: Nat) -> Nat:
  match v_7:
    case True{}:
      31n
    case False{}:
      cps_provider_1_ceil_log2_go(Nat.mul(v_1, 2n), Nat.add(v_3, 1n), v_5)

def native_match_cps_provider_1_ceil_log2_go_1(v_6: Bool, +v_1: Nat, +v_3: Nat, +v_5: Nat) -> Nat:
  match v_6:
    case True{}:
      native_match_cps_provider_1_ceil_log2_go_0(Nat.is_gt(v_3, 30n), v_1, v_3, v_5)
    case False{}:
      v_3

def cps_provider_1_ceil_log2_go(+v_1: Nat, +v_3: Nat, +v_5: Nat) -> Nat:
  native_match_cps_provider_1_ceil_log2_go_1(Nat.is_lt(v_1, v_5), v_1, v_3, v_5)

def cps_provider_1_node_layout(+v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_NodeResult:
  cps_provider_1_node_at(v_1, v_3, cps_provider_1_layout_fuel)

def cps_provider_1_node_layout_fuel(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> cps_provider_1_NodeResult:
  cps_provider_1_node_at(v_1, v_3, v_5)

def native_match_cps_provider_1_node_at_0(v_8: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> cps_provider_1_NodeResult:
  match v_8:
    case True{}:
      cps_provider_1_plan_node(v_1, v_3)
    case False{}:
      cps_provider_1_node_compute(v_1, v_3, v_5)

def cps_provider_1_node_at(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> cps_provider_1_NodeResult:
  native_match_cps_provider_1_node_at_0(Nat.is_eq(v_5, cps_provider_1_layout_fuel), v_1, v_3, v_5)

def native_match_cps_provider_1_plan_node_0(v_9: Maybe<&2, cps_provider_1_NodeResult>, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_NodeResult:
  match v_9:
    case Some{+v_8}:
      v_8
    case None{}:
      cps_provider_1_node_declared(v_1, v_3)

def cps_provider_1_plan_node(+v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_NodeResult:
  native_match_cps_provider_1_plan_node_0(IndexLookup.find(cps_provider_1_NodeResult, cps_provider_1_context_nodes(v_1), v_3), v_1, v_3)

def native_match_cps_provider_1_node_compute_0(v_12: Maybe<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> cps_provider_1_NodeResult:
  match v_12:
    case None{}:
      cps_provider_1_NodeFailed{cps_provider_1_unresolved_message(v_3)}
    case Some{+v_11}:
      cps_provider_1_node_arm(v_1, v_11, v_5)

def cps_provider_1_node_compute(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> cps_provider_1_NodeResult:
  native_match_cps_provider_1_node_compute_0(cps_provider_1_arm_of(v_3, cps_provider_1_context_families(v_1)), v_1, v_3, v_5)

def cps_provider_1_unresolved_message(+v_1: String) -> String:
  String.append("the constructor `", String.append(v_1, "` is in no declared family arm"))

def native_match_cps_provider_1_node_arm_0(v_15: cps_provider_1_Slots) -> cps_provider_1_NodeResult:
  match v_15:
    case cps_provider_1_SlotsFail{+v_12}:
      cps_provider_1_NodeFailed{v_12}
    case cps_provider_1_SlotsOk{+v_14}:
      cps_provider_1_node_finish(v_14)

def native_match_cps_provider_1_node_arm_1(+v_2: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_4: Nat) -> cps_provider_1_NodeResult:
  match v_2:
    case BIR.DescriptorArm{+v_8, +v_9}:
      native_match_cps_provider_1_node_arm_0(cps_provider_1_node_slots(v_1, v_9, 0, 0n, v_4, []))

def cps_provider_1_node_arm(+v_1: cps_provider_1_Context, +v_2: BIR.DescriptorArm, +v_4: Nat) -> cps_provider_1_NodeResult:
  native_match_cps_provider_1_node_arm_1(v_2, v_1, v_4)

def cps_provider_1_plan_node_index(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>) -> Map<&2, cps_provider_1_NodeResult>:
  match v_3:
    case []:
      Map.new(&2, cps_provider_1_NodeResult)
    case +v_9 <> v_10:
      match v_9:
        case BIR.ConstructorLayout{+v_15, +v_16, +v_17, +v_18}:
          Map.set(&2, cps_provider_1_NodeResult, cps_provider_1_plan_node_index(v_1, v_10), v_16, cps_provider_1_node_declared(v_1, v_16))

def native_match_cps_provider_1_node_declared_0(v_10: Maybe<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_NodeResult:
  match v_10:
    case Some{+v_7}:
      cps_provider_1_node_arm(v_1, v_7, cps_provider_1_layout_fuel)
    case None{}:
      cps_provider_1_NodeFailed{cps_provider_1_unresolved_message(v_3)}

def cps_provider_1_node_declared(+v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_NodeResult:
  native_match_cps_provider_1_node_declared_0(cps_provider_1_arm_declared(v_1, v_3), v_1, v_3)

def native_match_cps_provider_1_node_slots_0(v_36: cps_provider_1_LayoutResult, +v_1: cps_provider_1_Context, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>, v_18: List<&2, BIR.DescriptorField>) -> cps_provider_1_Slots:
  match v_36:
    case cps_provider_1_LayoutFailed{+v_29}:
      cps_provider_1_SlotsFail{v_29}
    case cps_provider_1_LayoutFound{+v_31}:
      +v_34 = {cps_provider_1_NodeSlot{v_5, v_7, v_31} : cps_provider_1_NodeSlot}
      cps_provider_1_node_slots(v_1, v_18, U32.inc(v_5), Nat.add(v_7, cps_provider_1_layout_words(v_31)), v_9, v_34 <> v_12)

def native_match_cps_provider_1_node_slots_1(v_35: Bool, +v_1: cps_provider_1_Context, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>, v_18: List<&2, BIR.DescriptorField>, +v_24: BIR.Descriptor) -> cps_provider_1_Slots:
  match v_35:
    case False{}:
      cps_provider_1_node_slots(v_1, v_18, U32.inc(v_5), v_7, v_9, v_12)
    case True{}:
      native_match_cps_provider_1_node_slots_0(cps_provider_1_layout_of_desc(v_1, v_24, [], v_9), v_1, v_5, v_7, v_9, v_12, v_18)

def native_match_cps_provider_1_node_slots_2(+v_17: BIR.DescriptorField, +v_1: cps_provider_1_Context, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>, v_18: List<&2, BIR.DescriptorField>) -> cps_provider_1_Slots:
  match v_17:
    case BIR.DescriptorField{+v_22, +v_23, +v_24}:
      native_match_cps_provider_1_node_slots_1(cps_provider_1_live_field(v_23), v_1, v_5, v_7, v_9, v_12, v_18, v_24)

def native_match_cps_provider_1_node_slots_3(+v_3: List<&2, BIR.DescriptorField>, +v_1: cps_provider_1_Context, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> cps_provider_1_Slots:
  match v_3:
    case []:
      cps_provider_1_SlotsOk{List.reverse(&2, cps_provider_1_NodeSlot, v_12)}
    case +v_17 <> v_18:
      native_match_cps_provider_1_node_slots_2(v_17, v_1, v_5, v_7, v_9, v_12, v_18)

def cps_provider_1_node_slots(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_1_NodeSlot>) -> cps_provider_1_Slots:
  native_match_cps_provider_1_node_slots_3(v_3, v_1, v_5, v_7, v_9, v_12)

def cps_provider_1_node_finish(+v_2: List<&2, cps_provider_1_NodeSlot>) -> cps_provider_1_NodeResult:
  match v_2:
    case []:
      cps_provider_1_NodeFound{cps_provider_1_Node{[], [], True{}}}
    case _:
      +v_9 = cps_provider_1_pad_words(cps_provider_1_slot_words(v_2))
      cps_provider_1_NodeFound{cps_provider_1_Node{v_9, v_2, cps_provider_1_packed_words(v_9)}}

def cps_provider_1_slot_words(+v_2: List<&2, cps_provider_1_NodeSlot>) -> List<&2, cps_provider_1_CWord>:
  match v_2:
    case []:
      []
    case +v_7 <> v_8:
      match v_7:
        case cps_provider_1_NodeSlot{+v_12, +v_13, +v_14}:
          List.append(&2, cps_provider_1_CWord, cps_provider_1_layout_kinds(v_14), cps_provider_1_slot_words(v_8))

def cps_provider_1_packed_words(+v_2: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_2:
    case []:
      True{}
    case +v_6 <> v_7:
      match v_7:
        case []:
          cps_provider_1_word_32(v_6)
        case _:
          False{}

def native_match_cps_provider_1_node_slot_0(v_22: Maybe<&2, cps_provider_1_NodeSlot>) -> cps_provider_1_SlotResult:
  match v_22:
    case Some{+v_20}:
      cps_provider_1_SlotFound{v_20}
    case None{}:
      cps_provider_1_SlotErased{}

def native_match_cps_provider_1_node_slot_1(+v_11: cps_provider_1_Node, +v_5: U32) -> cps_provider_1_SlotResult:
  match v_11:
    case cps_provider_1_Node{+v_15, +v_16, +v_17}:
      native_match_cps_provider_1_node_slot_0(cps_provider_1_slot_find(v_16, v_5))

def native_match_cps_provider_1_node_slot_2(v_21: cps_provider_1_NodeResult, +v_5: U32) -> cps_provider_1_SlotResult:
  match v_21:
    case cps_provider_1_NodeFailed{+v_9}:
      cps_provider_1_SlotFailed{v_9}
    case cps_provider_1_NodeFound{+v_11}:
      native_match_cps_provider_1_node_slot_1(v_11, v_5)

def cps_provider_1_node_slot(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> cps_provider_1_SlotResult:
  native_match_cps_provider_1_node_slot_2(cps_provider_1_node_layout(v_1, v_3), v_5)

def native_match_cps_provider_1_slot_find_0(v_17: Bool, +v_4: U32, +v_9: cps_provider_1_NodeSlot, v_10: List<&2, cps_provider_1_NodeSlot>) -> Maybe<&2, cps_provider_1_NodeSlot>:
  match v_17:
    case True{}:
      Some{v_9}
    case False{}:
      cps_provider_1_slot_find(v_10, v_4)

def native_match_cps_provider_1_slot_find_1(+v_9: cps_provider_1_NodeSlot, +v_4: U32, v_10: List<&2, cps_provider_1_NodeSlot>) -> Maybe<&2, cps_provider_1_NodeSlot>:
  match v_9:
    case cps_provider_1_NodeSlot{+v_14, +v_15, +v_16}:
      native_match_cps_provider_1_slot_find_0(U32.is_eq(v_4, v_14), v_4, v_9, v_10)

def native_match_cps_provider_1_slot_find_2(+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: U32) -> Maybe<&2, cps_provider_1_NodeSlot>:
  match v_2:
    case []:
      None{}
    case +v_9 <> v_10:
      native_match_cps_provider_1_slot_find_1(v_9, v_4, v_10)

def cps_provider_1_slot_find(+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: U32) -> Maybe<&2, cps_provider_1_NodeSlot>:
  native_match_cps_provider_1_slot_find_2(v_2, v_4)

def cps_provider_1_layout_fill(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout) -> cps_provider_1_FillResult:
  cps_provider_1_layout_fill_fuel(v_1, v_3, cps_provider_1_layout_fuel)

def native_match_cps_provider_1_layout_fill_fuel_0(v_23: cps_provider_1_Arms, +v_13: List<&2, cps_provider_1_CWord>) -> cps_provider_1_FillResult:
  match v_23:
    case cps_provider_1_ArmsFail{+v_19}:
      cps_provider_1_FillFailed{v_19}
    case cps_provider_1_ArmsOk{+v_21}:
      cps_provider_1_FillFound{cps_provider_1_FillForm{List.length(&2, cps_provider_1_CWord, v_13), v_21}}

def native_match_cps_provider_1_layout_fill_fuel_1(+v_3: cps_provider_1_Layout, +v_1: cps_provider_1_Context, +v_5: Nat) -> cps_provider_1_FillResult:
  match v_3:
    case cps_provider_1_LayoutWord{+v_8}:
      cps_provider_1_FillFound{cps_provider_1_FillWord{}}
    case cps_provider_1_LayoutBox{+v_10}:
      cps_provider_1_FillFound{cps_provider_1_FillWord{}}
    case cps_provider_1_LayoutData{+v_13, +v_14}:
      native_match_cps_provider_1_layout_fill_fuel_0(cps_provider_1_form_arms(v_1, v_14, 0n, Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_14), 1n), List.length(&2, cps_provider_1_CWord, v_13), v_5, [], True{}), v_13)

def cps_provider_1_layout_fill_fuel(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat) -> cps_provider_1_FillResult:
  native_match_cps_provider_1_layout_fill_fuel_1(v_3, v_1, v_5)

def cps_provider_1_layout_unfill(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout) -> cps_provider_1_UnfillResult:
  cps_provider_1_layout_unfill_fuel(v_1, v_3, cps_provider_1_layout_fuel)

def native_match_cps_provider_1_layout_unfill_fuel_0(v_23: cps_provider_1_Arms, +v_13: List<&2, cps_provider_1_CWord>) -> cps_provider_1_UnfillResult:
  match v_23:
    case cps_provider_1_ArmsFail{+v_19}:
      cps_provider_1_UnfillFailed{v_19}
    case cps_provider_1_ArmsOk{+v_21}:
      cps_provider_1_UnfillFound{cps_provider_1_UnfillForm{List.length(&2, cps_provider_1_CWord, v_13), v_21}}

def native_match_cps_provider_1_layout_unfill_fuel_1(+v_3: cps_provider_1_Layout, +v_1: cps_provider_1_Context, +v_5: Nat) -> cps_provider_1_UnfillResult:
  match v_3:
    case cps_provider_1_LayoutWord{+v_8}:
      cps_provider_1_UnfillFound{cps_provider_1_UnfillWord{}}
    case cps_provider_1_LayoutBox{+v_10}:
      cps_provider_1_UnfillFound{cps_provider_1_UnfillWord{}}
    case cps_provider_1_LayoutData{+v_13, +v_14}:
      native_match_cps_provider_1_layout_unfill_fuel_0(cps_provider_1_form_arms(v_1, v_14, 0n, Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_14), 1n), List.length(&2, cps_provider_1_CWord, v_13), v_5, [], False{}), v_13)

def cps_provider_1_layout_unfill_fuel(+v_1: cps_provider_1_Context, +v_3: cps_provider_1_Layout, +v_5: Nat) -> cps_provider_1_UnfillResult:
  native_match_cps_provider_1_layout_unfill_fuel_1(v_3, v_1, v_5)

def native_match_cps_provider_1_slot_fill_0(+v_9: cps_provider_1_NodeSlot, +v_1: cps_provider_1_Context) -> cps_provider_1_FillResult:
  match v_9:
    case cps_provider_1_NodeSlot{+v_13, +v_14, +v_15}:
      cps_provider_1_layout_fill(v_1, v_15)

def native_match_cps_provider_1_slot_fill_1(v_19: cps_provider_1_SlotResult, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_FillResult:
  match v_19:
    case cps_provider_1_SlotFound{+v_9}:
      native_match_cps_provider_1_slot_fill_0(v_9, v_1)
    case cps_provider_1_SlotErased{}:
      cps_provider_1_FillFailed{String.append("the constructor `", String.append(v_3, "` field slot is erased and has no storage"))}
    case cps_provider_1_SlotFailed{+v_18}:
      cps_provider_1_FillFailed{v_18}

def cps_provider_1_slot_fill(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> cps_provider_1_FillResult:
  native_match_cps_provider_1_slot_fill_1(cps_provider_1_node_slot(v_1, v_3, v_5), v_1, v_3)

def native_match_cps_provider_1_slot_unfill_0(+v_9: cps_provider_1_NodeSlot, +v_1: cps_provider_1_Context) -> cps_provider_1_UnfillResult:
  match v_9:
    case cps_provider_1_NodeSlot{+v_13, +v_14, +v_15}:
      cps_provider_1_layout_unfill(v_1, v_15)

def native_match_cps_provider_1_slot_unfill_1(v_19: cps_provider_1_SlotResult, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_UnfillResult:
  match v_19:
    case cps_provider_1_SlotFound{+v_9}:
      native_match_cps_provider_1_slot_unfill_0(v_9, v_1)
    case cps_provider_1_SlotErased{}:
      cps_provider_1_UnfillFailed{String.append("the constructor `", String.append(v_3, "` field slot is erased and has no storage"))}
    case cps_provider_1_SlotFailed{+v_18}:
      cps_provider_1_UnfillFailed{v_18}

def cps_provider_1_slot_unfill(+v_1: cps_provider_1_Context, +v_3: String, +v_5: U32) -> cps_provider_1_UnfillResult:
  native_match_cps_provider_1_slot_unfill_1(cps_provider_1_node_slot(v_1, v_3, v_5), v_1, v_3)

def native_match_cps_provider_1_form_arms_0(v_33: cps_provider_1_FormArmResult, +v_1: cps_provider_1_Context, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool, v_23: List<&2, cps_provider_1_LayArm>) -> cps_provider_1_Arms:
  match v_33:
    case cps_provider_1_FormArmFail{+v_30}:
      cps_provider_1_ArmsFail{v_30}
    case cps_provider_1_FormArmOk{+v_32}:
      cps_provider_1_form_arms(v_1, v_23, Nat.add(v_6, 1n), v_8, v_10, v_12, v_32 <> v_15, v_17)

def native_match_cps_provider_1_form_arms_1(+v_22: cps_provider_1_LayArm, +v_1: cps_provider_1_Context, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool, v_23: List<&2, cps_provider_1_LayArm>) -> cps_provider_1_Arms:
  match v_22:
    case cps_provider_1_LayArm{+v_26, +v_27}:
      native_match_cps_provider_1_form_arms_0(cps_provider_1_form_arm(v_1, v_26, v_6, v_8, v_10, v_27, v_12, v_17), v_1, v_6, v_8, v_10, v_12, v_15, v_17, v_23)

def native_match_cps_provider_1_form_arms_2(+v_4: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_1_Context, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool) -> cps_provider_1_Arms:
  match v_4:
    case []:
      cps_provider_1_ArmsOk{List.reverse(&2, cps_provider_1_FormArm, v_15)}
    case +v_22 <> v_23:
      native_match_cps_provider_1_form_arms_1(v_22, v_1, v_6, v_8, v_10, v_12, v_15, v_17, v_23)

def cps_provider_1_form_arms(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_LayArm>, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_1_FormArm>, +v_17: Bool) -> cps_provider_1_Arms:
  native_match_cps_provider_1_form_arms_2(v_4, v_1, v_6, v_8, v_10, v_12, v_15, v_17)

def native_match_cps_provider_1_form_arm_0(v_40: cps_provider_1_Nests, +v_3: String, +v_5: Nat, +v_26: List<&2, cps_provider_1_CWord>, +v_28: Bool) -> cps_provider_1_FormArmResult:
  match v_40:
    case cps_provider_1_NestsFail{+v_35}:
      cps_provider_1_FormArmFail{v_35}
    case cps_provider_1_NestsOk{+v_37}:
      cps_provider_1_FormArmOk{cps_provider_1_FormArm{v_3, v_5, v_28, List.length(&2, cps_provider_1_CWord, v_26), v_37}}

def native_match_cps_provider_1_form_arm_1(+v_22: cps_provider_1_Node, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_7: Bool, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: Nat, +v_16: Bool) -> cps_provider_1_FormArmResult:
  match v_22:
    case cps_provider_1_Node{+v_26, +v_27, +v_28}:
      +v_31 = cps_provider_1_tag_word(v_7)
      native_match_cps_provider_1_form_arm_0(cps_provider_1_form_nests(v_1, v_12, v_27, v_31, v_9, List.length(&2, cps_provider_1_CWord, v_26), v_14, [], v_16), v_3, v_5, v_26, v_28)

def native_match_cps_provider_1_form_arm_2(v_39: cps_provider_1_NodeResult, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_7: Bool, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: Nat, +v_16: Bool) -> cps_provider_1_FormArmResult:
  match v_39:
    case cps_provider_1_NodeFailed{+v_20}:
      cps_provider_1_FormArmFail{v_20}
    case cps_provider_1_NodeFound{+v_22}:
      native_match_cps_provider_1_form_arm_1(v_22, v_1, v_3, v_5, v_7, v_9, v_12, v_14, v_16)

def cps_provider_1_form_arm(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_7: Bool, +v_9: Nat, +v_12: List<&2, cps_provider_1_Layout>, +v_14: Nat, +v_16: Bool) -> cps_provider_1_FormArmResult:
  native_match_cps_provider_1_form_arm_2(cps_provider_1_node_layout_fuel(v_1, v_3, v_14), v_1, v_3, v_5, v_7, v_9, v_12, v_14, v_16)

def cps_provider_1_tag_word(+v_1: Bool) -> Nat:
  match v_1:
    case True{}:
      1n
    case False{}:
      0n

def native_match_cps_provider_1_form_nests_0(v_73: Bool, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_35: Nat, +v_41: cps_provider_1_Unfill, +v_46: cps_provider_1_Fill) -> cps_provider_1_Nests:
  match v_73:
    case False{}:
      cps_provider_1_NestsFail("the constructor node does not fit its value layout")
    case True{}:
      cps_provider_1_form_nests(v_1, v_28, v_30, Nat.add(v_9, cps_provider_1_fill_words(v_46)), v_11, v_13, v_15, cps_provider_1_nest(v_9, v_35, v_41, v_46) <> v_18, v_20)

def native_match_cps_provider_1_form_nests_1(v_72: cps_provider_1_FillResult, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_35: Nat, +v_41: cps_provider_1_Unfill) -> cps_provider_1_Nests:
  match v_72:
    case cps_provider_1_FillFailed{+v_44}:
      cps_provider_1_NestsFail{v_44}
    case cps_provider_1_FillFound{+v_46}:
      native_match_cps_provider_1_form_nests_0(cps_provider_1_nest_fits(v_9, v_11, v_35, v_13, v_41, v_46), v_1, v_9, v_11, v_13, v_15, v_18, v_20, v_28, v_30, v_35, v_41, v_46)

def native_match_cps_provider_1_form_nests_2(v_71: cps_provider_1_UnfillResult, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool, +v_27: cps_provider_1_Layout, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_35: Nat) -> cps_provider_1_Nests:
  match v_71:
    case cps_provider_1_UnfillFailed{+v_39}:
      cps_provider_1_NestsFail{v_39}
    case cps_provider_1_UnfillFound{+v_41}:
      native_match_cps_provider_1_form_nests_1(cps_provider_1_layout_fill_fuel(v_1, v_27, v_15), v_1, v_9, v_11, v_13, v_15, v_18, v_20, v_28, v_30, v_35, v_41)

def native_match_cps_provider_1_form_nests_3(v_76: Bool, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_35: Nat, +v_56: cps_provider_1_Unfill, +v_61: cps_provider_1_Fill) -> cps_provider_1_Nests:
  match v_76:
    case False{}:
      cps_provider_1_NestsFail("the constructor node does not fit its value layout")
    case True{}:
      cps_provider_1_form_nests(v_1, v_28, v_30, Nat.add(v_9, cps_provider_1_unfill_words(v_56)), v_11, v_13, v_15, cps_provider_1_nest(v_35, v_9, v_56, v_61) <> v_18, v_20)

def native_match_cps_provider_1_form_nests_4(v_75: cps_provider_1_FillResult, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_35: Nat, +v_56: cps_provider_1_Unfill) -> cps_provider_1_Nests:
  match v_75:
    case cps_provider_1_FillFailed{+v_59}:
      cps_provider_1_NestsFail{v_59}
    case cps_provider_1_FillFound{+v_61}:
      native_match_cps_provider_1_form_nests_3(cps_provider_1_nest_fits(v_35, v_13, v_9, v_11, v_56, v_61), v_1, v_9, v_11, v_13, v_15, v_18, v_20, v_28, v_30, v_35, v_56, v_61)

def native_match_cps_provider_1_form_nests_5(v_74: cps_provider_1_UnfillResult, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_35: Nat, +v_36: cps_provider_1_Layout) -> cps_provider_1_Nests:
  match v_74:
    case cps_provider_1_UnfillFailed{+v_54}:
      cps_provider_1_NestsFail{v_54}
    case cps_provider_1_UnfillFound{+v_56}:
      native_match_cps_provider_1_form_nests_4(cps_provider_1_layout_fill_fuel(v_1, v_36, v_15), v_1, v_9, v_11, v_13, v_15, v_18, v_20, v_28, v_30, v_35, v_56)

def native_match_cps_provider_1_form_nests_6(+v_20: Bool, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_27: cps_provider_1_Layout, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>, +v_35: Nat, +v_36: cps_provider_1_Layout) -> cps_provider_1_Nests:
  match v_20:
    case True{}:
      native_match_cps_provider_1_form_nests_2(cps_provider_1_layout_unfill_fuel(v_1, v_36, v_15), v_1, v_9, v_11, v_13, v_15, v_18, v_20, v_27, v_28, v_30, v_35)
    case False{}:
      native_match_cps_provider_1_form_nests_5(cps_provider_1_layout_unfill_fuel(v_1, v_27, v_15), v_1, v_9, v_11, v_13, v_15, v_18, v_20, v_28, v_30, v_35, v_36)

def native_match_cps_provider_1_form_nests_7(+v_29: cps_provider_1_NodeSlot, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool, +v_27: cps_provider_1_Layout, v_28: List<&2, cps_provider_1_Layout>, v_30: List<&2, cps_provider_1_NodeSlot>) -> cps_provider_1_Nests:
  match v_29:
    case cps_provider_1_NodeSlot{+v_34, +v_35, +v_36}:
      native_match_cps_provider_1_form_nests_6(v_20, v_1, v_9, v_11, v_13, v_15, v_18, v_27, v_28, v_30, v_35, v_36)

def native_match_cps_provider_1_form_nests_8(+v_4: List<&2, cps_provider_1_Layout>, +v_7: List<&2, cps_provider_1_NodeSlot>, +v_1: cps_provider_1_Context, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> cps_provider_1_Nests:
  match v_4, v_7:
    case [], []:
      cps_provider_1_NestsOk{List.reverse(&2, cps_provider_1_Nest, v_18)}
    case +v_27 <> v_28, +v_29 <> v_30:
      native_match_cps_provider_1_form_nests_7(v_29, v_1, v_9, v_11, v_13, v_15, v_18, v_20, v_27, v_28, v_30)
    case _, _:
      cps_provider_1_NestsFail("a constructor node and its value layout disagree on the live field count")

def cps_provider_1_form_nests(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_1_Layout>, +v_7: List<&2, cps_provider_1_NodeSlot>, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_1_Nest>, +v_20: Bool) -> cps_provider_1_Nests:
  native_match_cps_provider_1_form_nests_8(v_4, v_7, v_1, v_9, v_11, v_13, v_15, v_18, v_20)

def cps_provider_1_nest(+v_1: Nat, +v_3: Nat, +v_5: cps_provider_1_Unfill, +v_7: cps_provider_1_Fill) -> cps_provider_1_Nest:
  cps_provider_1_Nest{v_1, v_3, v_5, v_7}

def native_match_cps_provider_1_nest_fits_0(v_13: Bool) -> Bool:
  match v_13:
    case True{}:
      False{}
    case False{}:
      True{}

def native_match_cps_provider_1_nest_fits_1(v_12: Bool, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_1_Unfill) -> Bool:
  match v_12:
    case True{}:
      False{}
    case False{}:
      native_match_cps_provider_1_nest_fits_0(Nat.is_gt(Nat.add(v_5, cps_provider_1_unfill_words(v_9)), v_7))

def cps_provider_1_nest_fits(+v_1: Nat, +v_3: Nat, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_1_Unfill, +v_11: cps_provider_1_Fill) -> Bool:
  native_match_cps_provider_1_nest_fits_1(Nat.is_gt(Nat.add(v_1, cps_provider_1_fill_words(v_11)), v_3), v_5, v_7, v_9)

def cps_provider_1_fill_words(+v_1: cps_provider_1_Fill) -> Nat:
  match v_1:
    case cps_provider_1_FillWord{}:
      1n
    case cps_provider_1_FillForm{+v_5, +v_6}:
      v_5

def cps_provider_1_unfill_words(+v_1: cps_provider_1_Unfill) -> Nat:
  match v_1:
    case cps_provider_1_UnfillWord{}:
      1n
    case cps_provider_1_UnfillForm{+v_5, +v_6}:
      v_5

def native_match_cps_provider_1_head_native_0(v_9: cps_provider_3_Nf, +v_1: cps_provider_1_Context) -> cps_provider_1_HeadResult:
  match v_9:
    case cps_provider_3_NfFail{+v_6}:
      cps_provider_1_HeadFailed{v_6}
    case cps_provider_3_NfOk{+v_8}:
      cps_provider_1_head_value(v_1, v_8)

def cps_provider_1_head_native(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_HeadResult:
  native_match_cps_provider_1_head_native_0(cps_provider_1_nf_of(v_1, v_2, [], 1024n), v_1)

def cps_provider_1_head_other(+v_0: BIR.Descriptor) -> cps_provider_1_HeadResult:
  match v_0:
    case BIR.DescriptorEquality{_, _, _}:
      cps_provider_1_HeadEquality{}
    case _:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def native_match_cps_provider_1_head_value_0(v_47: Bool, +v_7: String, +v_20: Maybe<&2, String>) -> cps_provider_1_HeadResult:
  match v_47:
    case True{}:
      cps_provider_1_HeadFound{v_7, v_20}
    case False{}:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def native_match_cps_provider_1_head_value_1(+v_11: BIR.Family, +v_7: String, +v_8: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_HeadResult:
  match v_11:
    case BIR.Family{+v_18, +v_19, +v_20, +v_21, +v_22, +v_23}:
      native_match_cps_provider_1_head_value_0(Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_8), v_22), v_7, v_20)

def native_match_cps_provider_1_head_value_2(v_49: Bool, +v_7: String, +v_34: Maybe<&2, String>) -> cps_provider_1_HeadResult:
  match v_49:
    case True{}:
      cps_provider_1_HeadFound{v_7, v_34}
    case False{}:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def native_match_cps_provider_1_head_value_3(+v_34: Maybe<&2, String>, +v_7: String, +v_8: List<&2, cps_provider_3_NfVal>, +v_36: Nat) -> cps_provider_1_HeadResult:
  match v_34:
    case Some{+v_39}:
      native_match_cps_provider_1_head_value_2(Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_8), v_36), v_7, v_34)
    case None{}:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def native_match_cps_provider_1_head_value_4(+v_27: BIR.TypeFunction, +v_7: String, +v_8: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_HeadResult:
  match v_27:
    case BIR.TypeFunction{+v_33, +v_34, +v_35, +v_36, +v_37}:
      native_match_cps_provider_1_head_value_3(v_34, v_7, v_8, v_36)

def native_match_cps_provider_1_head_value_5(v_48: Maybe<&2, BIR.TypeFunction>, +v_7: String, +v_8: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_HeadResult:
  match v_48:
    case Some{+v_27}:
      native_match_cps_provider_1_head_value_4(v_27, v_7, v_8)
    case None{}:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxUnresolved{v_7}}

def native_match_cps_provider_1_head_value_6(v_46: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_7: String, +v_8: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_HeadResult:
  match v_46:
    case Some{+v_11}:
      native_match_cps_provider_1_head_value_1(v_11, v_7, v_8)
    case None{}:
      native_match_cps_provider_1_head_value_5(cps_provider_1_function_lookup(v_1, v_7), v_7, v_8)

def native_match_cps_provider_1_head_value_7(+v_3: cps_provider_3_NfVal, +v_1: cps_provider_1_Context) -> cps_provider_1_HeadResult:
  match v_3:
    case cps_provider_3_NfType{+v_7, +v_8}:
      native_match_cps_provider_1_head_value_6(cps_provider_1_family_lookup(v_1, v_7), v_1, v_7, v_8)
    case cps_provider_3_NfOther{+v_42}:
      cps_provider_1_head_other(v_42)
    case _:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def cps_provider_1_head_value(+v_1: cps_provider_1_Context, +v_3: cps_provider_3_NfVal) -> cps_provider_1_HeadResult:
  native_match_cps_provider_1_head_value_7(v_3, v_1)

def native_match_cps_provider_1_norm_0(+v_10: BIR.Descriptor) -> cps_provider_1_NormResult:
  match v_10:
    case BIR.DescriptorFailure{+v_7}:
      cps_provider_1_NormFailed{v_7}
    case +v_9:
      cps_provider_1_NormOk{v_9}

def cps_provider_1_norm(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_NormResult:
  native_match_cps_provider_1_norm_0(cps_provider_3_normalize(cps_provider_1_context_nf(v_1), v_2, [], 1024n))

def native_match_cps_provider_1_head_args_0(+v_8: cps_provider_3_NfVal) -> cps_provider_1_ArgsResult:
  match v_8:
    case cps_provider_3_NfType{+v_11, +v_12}:
      cps_provider_1_ArgsOk{cps_provider_3_materialize_all(v_12)}
    case _:
      cps_provider_1_ArgsFailed{"the applied type is not a named family application"}

def native_match_cps_provider_1_head_args_1(v_16: cps_provider_3_Nf) -> cps_provider_1_ArgsResult:
  match v_16:
    case cps_provider_3_NfFail{+v_6}:
      cps_provider_1_ArgsFailed{v_6}
    case cps_provider_3_NfOk{+v_8}:
      native_match_cps_provider_1_head_args_0(v_8)

def cps_provider_1_head_args(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_ArgsResult:
  native_match_cps_provider_1_head_args_1(cps_provider_1_nf_of(v_1, v_2, [], 1024n))

def native_match_cps_provider_1_arm_fields_0(v_11: cps_provider_3_Nf, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_FieldsResult:
  match v_11:
    case cps_provider_3_NfFail{+v_8}:
      cps_provider_1_FieldsFailed{v_8}
    case cps_provider_3_NfOk{+v_10}:
      cps_provider_1_arm_fields_value(v_1, v_3, v_10)

def cps_provider_1_arm_fields(+v_1: cps_provider_1_Context, +v_3: String, +v_4: BIR.Descriptor) -> cps_provider_1_FieldsResult:
  native_match_cps_provider_1_arm_fields_0(cps_provider_1_nf_of(v_1, v_4, [], 1024n), v_1, v_3)

def native_match_cps_provider_1_arm_fields_value_0(+v_14: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_FieldsResult:
  match v_14:
    case BIR.DescriptorArm{+v_17, +v_18}:
      cps_provider_1_instantiate_fields(v_1, v_10, v_18, [])

def native_match_cps_provider_1_arm_fields_value_1(v_22: Maybe<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String, +v_10: List<&2, cps_provider_3_NfVal>) -> cps_provider_1_FieldsResult:
  match v_22:
    case None{}:
      cps_provider_1_FieldsFailed{cps_provider_1_unresolved_message(v_3)}
    case Some{+v_14}:
      native_match_cps_provider_1_arm_fields_value_0(v_14, v_1, v_10)

def native_match_cps_provider_1_arm_fields_value_2(+v_5: cps_provider_3_NfVal, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_FieldsResult:
  match v_5:
    case cps_provider_3_NfType{+v_9, +v_10}:
      native_match_cps_provider_1_arm_fields_value_1(cps_provider_1_arm_declared(v_1, v_3), v_1, v_3, v_10)
    case _:
      cps_provider_1_FieldsFailed{"the applied type is not a named family application"}

def cps_provider_1_arm_fields_value(+v_1: cps_provider_1_Context, +v_3: String, +v_5: cps_provider_3_NfVal) -> cps_provider_1_FieldsResult:
  native_match_cps_provider_1_arm_fields_value_2(v_5, v_1, v_3)

def cps_provider_1_instantiate_fields(+v_1: cps_provider_1_Context, +v_3: List<&2, cps_provider_3_NfVal>, +v_5: List<&2, BIR.DescriptorField>, +v_7: List<&2, BIR.DescriptorField>) -> cps_provider_1_FieldsResult:
  match v_5:
    case []:
      cps_provider_1_FieldsFound{List.reverse(&2, BIR.DescriptorField, v_7)}
    case +v_11 <> v_12:
      match v_11:
        case BIR.DescriptorField{+v_16, +v_17, +v_18}:
          +v_21 = cps_provider_1_field_scope(v_3)
          +v_24 = {BIR.DescriptorField{v_16, v_17, cps_provider_3_normalize(cps_provider_1_context_nf(v_1), v_18, v_3, 1024n)} : BIR.DescriptorField}
          cps_provider_1_instantiate_fields(v_1, v_21, v_12, v_24 <> v_7)

def native_match_cps_provider_1_array_cell_0(v_9: cps_provider_1_LayoutResult) -> cps_provider_1_CellResult:
  match v_9:
    case cps_provider_1_LayoutFailed{+v_6}:
      cps_provider_1_CellFailed{v_6}
    case cps_provider_1_LayoutFound{+v_8}:
      cps_provider_1_cell_of(v_8)

def cps_provider_1_array_cell(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_CellResult:
  native_match_cps_provider_1_array_cell_0(cps_provider_1_value_layout(v_1, v_2))

def cps_provider_1_cell_of(+v_1: cps_provider_1_Layout) -> cps_provider_1_CellResult:
  match v_1:
    case cps_provider_1_LayoutBox{+v_4}:
      cps_provider_1_cell_boxed(v_4)
    case _:
      +v_10 = cps_provider_1_layout_words(v_1)
      cps_provider_1_CellFound{cps_provider_1_Cell{v_1, cps_provider_1_layout_has_term(v_1), v_10, cps_provider_1_ceil_log2(cps_provider_1_max_one(v_10))}}

def cps_provider_1_cell_boxed(+v_1: cps_provider_1_BoxReason) -> cps_provider_1_CellResult:
  cps_provider_1_CellFound{cps_provider_1_Cell{cps_provider_1_LayoutBox{v_1}, True{}, 1n, 0n}}

def native_match_cps_provider_1_max_one_0(v_2: Bool, +v_1: Nat) -> Nat:
  match v_2:
    case True{}:
      v_1
    case False{}:
      1n

def cps_provider_1_max_one(+v_1: Nat) -> Nat:
  native_match_cps_provider_1_max_one_0(Nat.is_gt(v_1, 0n), v_1)

def cps_provider_1_layout_has_term(+v_1: cps_provider_1_Layout) -> Bool:
  match v_1:
    case cps_provider_1_LayoutWord{+v_4}:
      cps_provider_1_word_has_term(v_4)
    case cps_provider_1_LayoutBox{+v_7}:
      True{}
    case cps_provider_1_LayoutData{+v_10, +v_11}:
      cps_provider_1_any_word_has_term(v_10)

def cps_provider_1_word_has_term(+v_1: cps_provider_1_CWord) -> Bool:
  match v_1:
    case cps_provider_1_CWord32{}:
      False{}
    case _:
      True{}

def native_match_cps_provider_1_any_word_has_term_0(v_8: Bool, v_7: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_8:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_any_word_has_term(v_7)

def native_match_cps_provider_1_any_word_has_term_1(+v_2: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_6 <> v_7:
      native_match_cps_provider_1_any_word_has_term_0(cps_provider_1_word_has_term(v_6), v_7)

def cps_provider_1_any_word_has_term(+v_2: List<&2, cps_provider_1_CWord>) -> Bool:
  native_match_cps_provider_1_any_word_has_term_1(v_2)

def cps_provider_2_world(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, cps_provider_2_CidSym>) -> cps_provider_2_World:
  cps_provider_2_World{v_0, v_2, v_5}

def cps_provider_2_join_text(+v_2: List<&2, String>) -> String:
  String.join(v_2, "")

def cps_provider_2_code_line(+v_1: String) -> cps_provider_2_Code:
  cps_provider_2_CodeOk{[v_1]}

def cps_provider_2_code_empty() -> cps_provider_2_Code:
  cps_provider_2_CodeOk{[]}

def cps_provider_2_code_seq(+v_1: cps_provider_2_Code, +v_3: cps_provider_2_Code) -> cps_provider_2_Code:
  match v_1:
    case cps_provider_2_CodeFail{v_6}:
      cps_provider_2_CodeFail{v_6}
    case cps_provider_2_CodeOk{v_8}:
      match v_3:
        case cps_provider_2_CodeFail{v_10}:
          cps_provider_2_CodeFail{v_10}
        case cps_provider_2_CodeOk{v_12}:
          cps_provider_2_CodeOk{List.append(&2, String, v_8, v_12)}

def cps_provider_2_code_text(+v_2: List<&2, String>, +v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case +v_8 <> +v_9:
      cps_provider_2_join_text(["({\n", String.join(v_2, "\n"), "\n", v_4, ";\n})"])

def cps_provider_2_part_of(+v_1: cps_provider_2_Code, +v_3: String) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CodeFail{+v_6}:
      cps_provider_2_PartFail{v_6}
    case cps_provider_2_CodeOk{+v_8}:
      cps_provider_2_PartOk(cps_provider_2_code_text(v_8, v_3))

def cps_provider_2_ctor_find(+v_1: U32, +v_3: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_3:
    case []:
      None{}
    case +v_7 <> +v_8:
      match v_7:
        case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
          v_18 = U32.is_eq(v_1, v_13)
          Bool.pick(Maybe<&2, BIR.ConstructorLayout>, v_18, Some{v_7}, cps_provider_2_ctor_find(v_1, v_8))

def cps_provider_2_ctor_of(+v_1: U32, +v_3: cps_provider_2_World) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_3:
    case cps_provider_2_World{v_8, v_9, v_10}:
      cps_provider_2_ctor_find(v_1, v_9)

def cps_provider_2_cid_find(+v_1: String, +v_4: List<&2, cps_provider_2_CidSym>) -> Maybe<&2, U32>:
  match v_4:
    case []:
      None{}
    case +v_9 <> +v_10:
      match v_9:
        case cps_provider_2_CidSym{v_13, v_14}:
          v_16 = String.eq(v_1, v_14)
          Bool.pick(Maybe<&2, U32>, v_16, Some{v_13}, cps_provider_2_cid_find(v_1, v_10))

def cps_provider_2_cid_of(+v_1: String, +v_3: cps_provider_2_World) -> Maybe<&2, U32>:
  match v_3:
    case cps_provider_2_World{v_9, v_10, v_11}:
      cps_provider_2_cid_find(v_1, v_11)

def cps_provider_2_cid_text_of(+v_2: Maybe<&2, U32>) -> Maybe<&2, String>:
  match v_2:
    case Some{v_6}:
      Some{cps_provider_2_join_text([U32.show(v_6), "u"])}
    case None{}:
      None{}

def cps_provider_2_cid_text(+v_1: String, +v_3: cps_provider_2_World) -> Maybe<&2, String>:
  v_8 = cps_provider_2_cid_of(v_1, v_3)
  cps_provider_2_cid_text_of(v_8)

def cps_provider_2_intrinsic_marker(+v_1: String) -> Bool:
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

def cps_provider_2_dst_write(+v_1: cps_provider_2_Dst, +v_3: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_2_DstSeq{v_8, v_9}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_8, "[", v_9, "] = ", v_3, "; ", v_9, " += 1;"])}]
    case cps_provider_2_DstOut{v_12}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_12, " = ", v_3, ";"])}]

def cps_provider_2_dst_word(+v_1: cps_provider_2_Dst, +v_2: cps_provider_1_CWord, +v_4: String) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case cps_provider_1_CWord32{}:
      cps_provider_2_dst_write(v_1, cps_provider_2_join_text(["((u64)(u32)(", v_4, "))"]))
    case cps_provider_1_CWord64{}:
      cps_provider_2_dst_write(v_1, v_4)
    case cps_provider_1_CWordBox{}:
      cps_provider_2_dst_write(v_1, v_4)

def cps_provider_2_dst_decl(+v_1: String, +v_3: String, +v_5: Nat) -> String:
  cps_provider_2_join_text(["u64 ", v_1, "[", Nat.show(v_5), "]; for (u32 ", v_3, "i = 0; ", v_3, "i < ", Nat.show(v_5), "; ", v_3, "i += 1) { ", v_1, "[", v_3, "i] = 0; } u32 ", v_3, " = 0;"])

def native_match_cps_provider_2_dst_mark_0(+v_1: cps_provider_2_Dst, v_6: String) -> String:
  match v_1:
    case cps_provider_2_DstSeq{v_9, v_10}:
      cps_provider_2_join_text([v_9, "[", v_10, "]", " = ", v_6, "; ", v_10, " += 1;"])
    case cps_provider_2_DstOut{v_13}:
      cps_provider_2_join_text([v_13, " = ", v_6, ";"])

def cps_provider_2_dst_mark(+v_1: cps_provider_2_Dst, +v_3: Nat) -> String:
  v_6 = Nat.show(v_3)
  native_match_cps_provider_2_dst_mark_0(v_1, v_6)

def cps_provider_2_form_base(+v_1: Nat, +v_3: Bool) -> Nat:
  Nat.sub(v_1, cps_provider_1_tag_word(v_3))

def cps_provider_2_form_pad(+v_1: Nat, +v_3: Nat) -> Nat:
  Nat.sub(v_1, v_3)

def native_match_cps_provider_2_src_skip_jobs_0(v_15: Bool, +v_3: Nat, v_14: String) -> List<&2, cps_provider_2_Job>:
  match v_15:
    case True{}:
      []
    case False{}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_14, " += ", Nat.show(v_3), ";"])}]

def native_match_cps_provider_2_src_skip_jobs_1(+v_1: cps_provider_2_Src, +v_3: Nat) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_2_SrcOne{v_7}:
      []
    case cps_provider_2_SrcNode{v_12, v_13, v_14, v_15}:
      native_match_cps_provider_2_src_skip_jobs_0(v_15, v_3, v_14)
    case cps_provider_2_SrcBlock{v_22, v_23, v_24, v_25, v_26}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_26, " += ", Nat.show(v_3), ";"])}]
    case cps_provider_2_SrcBuf{v_30, v_31}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_31, " += ", Nat.show(v_3), ";"])}]

def native_match_cps_provider_2_src_skip_jobs_2(v_32: Bool, +v_1: cps_provider_2_Src, +v_3: Nat) -> List<&2, cps_provider_2_Job>:
  match v_32:
    case False{}:
      []
    case True{}:
      native_match_cps_provider_2_src_skip_jobs_1(v_1, v_3)

def cps_provider_2_src_skip_jobs(+v_1: cps_provider_2_Src, +v_3: Nat) -> List<&2, cps_provider_2_Job>:
  native_match_cps_provider_2_src_skip_jobs_2(Nat.is_gt(v_3, 0n), v_1, v_3)

def native_match_cps_provider_2_dst_skip_jobs_0(+v_1: cps_provider_2_Dst, +v_3: Nat) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_2_DstSeq{v_8, v_9}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_9, " += ", Nat.show(v_3), ";"])}]
    case cps_provider_2_DstOut{v_12}:
      []

def native_match_cps_provider_2_dst_skip_jobs_1(v_13: Bool, +v_1: cps_provider_2_Dst, +v_3: Nat) -> List<&2, cps_provider_2_Job>:
  match v_13:
    case False{}:
      []
    case True{}:
      native_match_cps_provider_2_dst_skip_jobs_0(v_1, v_3)

def cps_provider_2_dst_skip_jobs(+v_1: cps_provider_2_Dst, +v_3: Nat) -> List<&2, cps_provider_2_Job>:
  native_match_cps_provider_2_dst_skip_jobs_1(Nat.is_gt(v_3, 0n), v_1, v_3)

def cps_provider_2_src_read_node(+v_1: String, +v_3: String, +v_5: String, +v_7: Bool, +v_9: String) -> List<&2, cps_provider_2_Job>:
  match v_7:
    case True{}:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_9, "w = ", v_1, ";"])}]
    case False{}:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_9, "w = ((", v_1, " != 0) ? e.mem[", v_1, " + ", v_5, "] : (u64)", v_3, "[", v_5, "]); ", v_5, " += 1;"])}]

def cps_provider_2_src_read_arr(+v_1: String, +v_3: String, +v_5: Bool, +v_7: String, +v_9: String) -> List<&2, cps_provider_2_Job>:
  match v_5:
    case True{}:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_9, "w = blk_keep(e, ", v_1, " + ", v_3, " + ", v_7, "); ", v_7, " += 1;"])}]
    case False{}:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_9, "w = blk_read(e.mem, true, ", v_1, ", ", v_3, " + ", v_7, "); ", v_7, " += 1;"])}]

def cps_provider_2_src_read_block(+v_1: String, +v_3: String, +v_5: Bool, +v_7: Bool, +v_9: String, +v_11: String) -> List<&2, cps_provider_2_Job>:
  match v_5:
    case True{}:
      cps_provider_2_src_read_arr(v_1, v_3, v_7, v_9, v_11)
    case False{}:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_11, "w = ((u64)blk_read(e.mem, false, ", v_1, ", ", v_3, " + ", v_9, ")); ", v_9, " += 1;"])}]

def cps_provider_2_src_read(+v_1: cps_provider_2_Src, +v_3: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_2_SrcOne{v_7}:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_3, "w = ", v_7, ";"])}]
    case cps_provider_2_SrcNode{v_13, v_14, v_15, v_16}:
      cps_provider_2_src_read_node(v_13, v_14, v_15, v_16, v_3)
    case cps_provider_2_SrcBlock{v_23, v_24, v_25, v_26, v_27}:
      cps_provider_2_src_read_block(v_23, v_24, v_25, v_26, v_27, v_3)
    case cps_provider_2_SrcBuf{v_31, v_32}:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_3, "w = ", v_31, "[", v_32, "]; ", v_32, " += 1;"])}]

def cps_provider_2_form_tagged(+v_1: List<&2, cps_provider_1_FormArm>) -> Bool:
  match v_1:
    case []:
      False{}
    case [+v_4]:
      False{}
    case _:
      True{}

def cps_provider_2_max_node_words(+v_1: List<&2, cps_provider_1_FormArm>, +v_3: Nat) -> Nat:
  match v_1:
    case []:
      v_3
    case +v_7 <> +v_8:
      match v_7:
        case cps_provider_1_FormArm{v_14, v_15, v_16, v_17, v_18}:
          cps_provider_2_max_node_words(v_8, Nat.max(v_3, v_17))

def cps_provider_2_max_term_decl(+v_1: String, +v_3: Nat) -> String:
  match v_3:
    case 0n:
      ""
    case _:
      cps_provider_2_join_text(["Term ", v_1, "[", Nat.show(v_3), "];"])

def cps_provider_2_arm_seed(+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case True{}:
      []
    case False{}:
      cps_provider_2_arm_seed_words(v_3, v_5, v_7, v_9)

def cps_provider_2_arm_seed_words(+v_1: Nat, +v_3: String, +v_5: String, +v_7: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case 0n:
      []
    case _:
      [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_5, "s = term_rfc(", v_3, ") ? ctr_take(e, ", v_3, ", ", Nat.show(v_1), ", ", v_7, ") : term_loc(", v_3, "); u32 ", v_5, "i = 0;"])}]

def cps_provider_2_arm_src(+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String) -> cps_provider_2_Src:
  match v_1:
    case True{}:
      match v_3:
        case 0n:
          cps_provider_2_SrcOne{"0"}
        case _:
          cps_provider_2_SrcOne{cps_provider_2_join_text(["((u64)term_loc(", v_5, "))"])}
    case False{}:
      cps_provider_2_SrcNode{cps_provider_2_join_text([v_7, "s"]), v_9, cps_provider_2_join_text([v_7, "i"]), False{}}

def cps_provider_2_nests_jobs(+v_1: cps_provider_2_World, +v_3: List<&2, cps_provider_1_Nest>, +v_5: cps_provider_2_Src, +v_7: cps_provider_2_Dst, +v_9: String, +v_11: Nat) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case []:
      []
    case +v_16 <> +v_17:
      match v_16:
        case cps_provider_1_Nest{v_22, v_23, v_24, v_25}:
          List.append(&2, cps_provider_2_Job, [cps_provider_2_JConv{v_24, v_25, v_5, v_7, cps_provider_2_join_text([v_9, "f", Nat.show(v_11)])}], cps_provider_2_nests_jobs(v_1, v_17, v_5, v_7, v_9, Nat.add(v_11, 1n)))

def cps_provider_2_arm_release(+v_1: Bool, +v_3: Nat, +v_5: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case True{}:
      []
    case False{}:
      match v_3:
        case 0n:
          []
        case _:
          [cps_provider_2_JText{cps_provider_2_join_text(["if (", v_5, "s != 0) { spare_free(e, cls_fit(", Nat.show(v_3), "), ", v_5, "s); }"])}]

def cps_provider_2_jobs_arm_body(+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_13: List<&2, cps_provider_1_Nest>, +v_15: String, +v_17: cps_provider_2_Dst, +v_19: String, +v_21: Bool, +v_23: String, +v_25: Nat) -> List<&2, cps_provider_2_Job>:
  List.append(&2, cps_provider_2_Job, Bool.pick(List<&2, cps_provider_2_Job>, v_21, cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_dst_mark(v_17, v_5)}), []), List.append(&2, cps_provider_2_Job, cps_provider_2_arm_seed(v_9, v_11, v_15, v_19, v_23), List.append(&2, cps_provider_2_Job, cps_provider_2_nests_jobs(v_1, v_13, cps_provider_2_arm_src(v_9, v_11, v_15, v_19, v_23), v_17, v_19, 0n), List.append(&2, cps_provider_2_Job, cps_provider_2_dst_skip_jobs(v_17, cps_provider_2_form_pad(v_7, v_11)), cps_provider_2_arm_release(v_9, v_11, v_19)))))

def cps_provider_2_jobs_arm(+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_13: List<&2, cps_provider_1_Nest>, +v_15: String, +v_17: cps_provider_2_Dst, +v_19: String, +v_21: Bool, +v_23: String, +v_25: Nat) -> List<&2, cps_provider_2_Job>:
  List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["case ", U32.show(v_3), "u: {"])}], List.append(&2, cps_provider_2_Job, cps_provider_2_jobs_arm_body(v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_23, v_25), [cps_provider_2_JText{"} break;"}]))

def cps_provider_2_arm_jobs(+v_1: cps_provider_2_World, +v_4: Maybe<&2, U32>, +v_5: cps_provider_1_FormArm, +v_7: Nat, +v_9: String, +v_11: cps_provider_2_Dst, +v_13: String, +v_15: Bool, +v_17: String, +v_19: Nat) -> List<&2, cps_provider_2_Job>:
  match v_4:
    case None{}:
      [cps_provider_2_JText{"default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;"}]
    case Some{v_23}:
      match v_5:
        case cps_provider_1_FormArm{v_29, v_30, v_31, v_32, v_33}:
          cps_provider_2_jobs_arm(v_1, v_23, v_30, v_7, v_31, v_32, v_33, v_9, v_11, v_13, v_15, v_17, v_19)

def cps_provider_2_unbox_cases(+v_1: cps_provider_2_World, +v_3: List<&2, cps_provider_1_FormArm>, +v_5: Nat, +v_7: String, +v_9: cps_provider_2_Dst, +v_11: String, +v_13: Bool, +v_15: String) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case []:
      []
    case +v_20 <> +v_21:
      match v_20:
        case cps_provider_1_FormArm{v_27, v_28, v_29, v_30, v_31}:
          v_34 = cps_provider_2_cid_of(v_27, v_1)
          List.append(&2, cps_provider_2_Job, cps_provider_2_arm_jobs(v_1, v_34, v_20, v_5, v_7, v_9, v_11, v_13, v_15, 0n), cps_provider_2_unbox_cases(v_1, v_21, v_5, v_7, v_9, v_11, v_13, v_15))

def cps_provider_2_expand_unbox(+v_1: cps_provider_2_World, +v_3: Nat, +v_5: List<&2, cps_provider_1_FormArm>, +v_7: cps_provider_2_Src, +v_9: cps_provider_2_Dst, +v_11: String) -> List<&2, cps_provider_2_Job>:
  v_16 = cps_provider_2_join_text([v_11, "t"])
  v_19 = cps_provider_2_join_text([v_11, "f"])
  v_22 = cps_provider_2_max_node_words(v_5, 0n)
  v_25 = cps_provider_2_form_tagged(v_5)
  v_28 = cps_provider_2_form_base(v_3, v_25)
  v_35 = List.append(&2, cps_provider_2_Job, cps_provider_2_src_read(v_7, v_11), List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["Term ", v_16, " = ", v_11, "w;"])}], [cps_provider_2_JText{cps_provider_2_max_term_decl(v_19, v_22)}]))
  v_38 = cps_provider_2_unbox_cases(v_1, v_5, v_28, v_16, v_9, v_11, v_25, v_19)
  List.append(&2, cps_provider_2_Job, v_35, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["switch (term_aux(", v_16, ")) {"])}], List.append(&2, cps_provider_2_Job, v_38, [cps_provider_2_JText{"}"}])))

def cps_provider_2_expand_word_take(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Fill, +v_4: cps_provider_2_Src, +v_6: cps_provider_2_Dst, +v_8: String) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case cps_provider_1_FillWord{}:
      List.append(&2, cps_provider_2_Job, cps_provider_2_src_read(v_4, v_8), cps_provider_2_dst_write(v_6, cps_provider_2_join_text([v_8, "w"])))
    case cps_provider_1_FillForm{v_17, v_18}:
      cps_provider_2_expand_unbox(v_1, v_17, v_18, v_4, v_6, v_8)

def cps_provider_2_nest_take(+v_0: cps_provider_1_Nest) -> cps_provider_1_Unfill:
  match v_0:
    case cps_provider_1_Nest{v_5, v_6, v_7, v_8}:
      v_7

def cps_provider_2_nest_make(+v_0: cps_provider_1_Nest) -> cps_provider_1_Fill:
  match v_0:
    case cps_provider_1_Nest{v_5, v_6, v_7, v_8}:
      v_8

def cps_provider_2_field_pair_jobs(+v_1: cps_provider_2_World, +v_3: List<&2, cps_provider_1_Nest>, +v_5: List<&2, cps_provider_1_Nest>, +v_7: cps_provider_2_Src, +v_9: cps_provider_2_Dst, +v_11: String, +v_13: Nat) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case []:
      match v_5:
        case []:
          []
        case _:
          [cps_provider_2_JFail{"the constructor's slots and fields differ"}]
    case +v_20 <> +v_21:
      match v_5:
        case []:
          [cps_provider_2_JFail{"the constructor's slots and fields differ"}]
        case +v_24 <> +v_25:
          v_28 = cps_provider_2_join_text([v_11, "p", Nat.show(v_13)])
          List.append(&2, cps_provider_2_Job, [cps_provider_2_JConv{cps_provider_2_nest_take(v_20), cps_provider_2_nest_make(v_24), v_7, v_9, v_28}], cps_provider_2_field_pair_jobs(v_1, v_21, v_25, v_7, v_9, v_11, Nat.add(v_13, 1n)))

def cps_provider_2_forms_arm_body(+v_1: cps_provider_2_World, +v_3: Nat, +v_5: List<&2, cps_provider_1_Nest>, +v_7: Nat, +v_9: Nat, +v_11: Bool, +v_13: Maybe<&2, cps_provider_1_FormArm>, +v_15: cps_provider_2_Src, +v_17: cps_provider_2_Dst, +v_19: String) -> List<&2, cps_provider_2_Job>:
  match v_13:
    case None{}:
      [cps_provider_2_JText{"(void)err_fail(\"the inline conversion target has no arm\");"}]
    case Some{v_23}:
      match v_23:
        case cps_provider_1_FormArm{v_29, v_30, v_31, v_32, v_33}:
          List.append(&2, cps_provider_2_Job, Bool.pick(List<&2, cps_provider_2_Job>, v_11, cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_dst_mark(v_17, v_30)}), []), List.append(&2, cps_provider_2_Job, cps_provider_2_field_pair_jobs(v_1, v_5, v_33, v_15, v_17, v_19, 0n), List.append(&2, cps_provider_2_Job, cps_provider_2_dst_skip_jobs(v_17, cps_provider_2_form_pad(v_9, v_32)), cps_provider_2_src_skip_jobs(v_15, cps_provider_2_form_pad(v_7, v_3)))))

def cps_provider_2_forms_arm_case(+v_1: cps_provider_2_World, +v_3: Maybe<&2, cps_provider_1_FormArm>, +v_4: cps_provider_1_FormArm, +v_6: Nat, +v_8: Nat, +v_10: Bool, +v_12: cps_provider_2_Src, +v_14: cps_provider_2_Dst, +v_16: String, +v_18: Nat) -> List<&2, cps_provider_2_Job>:
  match v_4:
    case cps_provider_1_FormArm{v_26, v_27, v_28, v_29, v_30}:
      v_33 = cps_provider_2_forms_arm_body(v_1, v_29, v_30, v_6, v_8, v_10, v_3, v_12, v_14, v_16)
      List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["case ", Nat.show(v_18), ": {"])}], List.append(&2, cps_provider_2_Job, v_33, [cps_provider_2_JText{"} break;"}]))

def cps_provider_2_form_arm_by_key(+v_1: String, +v_3: List<&2, cps_provider_1_FormArm>) -> Maybe<&2, cps_provider_1_FormArm>:
  match v_3:
    case []:
      None{}
    case +v_7 <> +v_8:
      match v_7:
        case cps_provider_1_FormArm{v_14, v_15, v_16, v_17, v_18}:
          v_20 = String.eq(v_1, v_14)
          Bool.pick(Maybe<&2, cps_provider_1_FormArm>, v_20, Some{v_7}, cps_provider_2_form_arm_by_key(v_1, v_8))

def cps_provider_2_forms_cases(+v_1: cps_provider_2_World, +v_3: List<&2, cps_provider_1_FormArm>, +v_5: List<&2, cps_provider_1_FormArm>, +v_7: Nat, +v_9: Nat, +v_11: Bool, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String, +v_19: Nat) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case []:
      []
    case +v_24 <> +v_25:
      match v_24:
        case cps_provider_1_FormArm{v_31, v_32, v_33, v_34, v_35}:
          v_38 = cps_provider_2_form_arm_by_key(v_31, v_5)
          v_41 = cps_provider_2_forms_arm_case(v_1, v_38, v_24, v_7, v_9, v_11, v_13, v_15, v_17, v_19)
          List.append(&2, cps_provider_2_Job, v_41, cps_provider_2_forms_cases(v_1, v_25, v_5, v_7, v_9, v_11, v_13, v_15, v_17, Nat.add(v_19, 1n)))

def native_match_cps_provider_2_expand_forms_0(+v_6: List<&2, cps_provider_1_FormArm>, +v_1: cps_provider_2_World, +v_11: List<&2, cps_provider_1_FormArm>, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String, v_22: Bool, v_26: Nat, v_29: Nat) -> List<&2, cps_provider_2_Job>:
  match v_6:
    case []:
      []
    case [+v_31]:
      cps_provider_2_forms_single(v_1, v_31, v_26, v_29, v_22, v_11, v_13, v_15, v_17)
    case _:
      v_37 = cps_provider_2_forms_cases(v_1, v_6, v_11, v_26, v_29, v_22, v_13, v_15, v_17, 0n)
      List.append(&2, cps_provider_2_Job, cps_provider_2_src_read(v_13, v_17), List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["switch ((u32)(", v_17, "w)) {"])}], List.append(&2, cps_provider_2_Job, v_37, [cps_provider_2_JText{"}"}])))

def cps_provider_2_expand_forms(+v_1: cps_provider_2_World, +v_3: Nat, +v_6: List<&2, cps_provider_1_FormArm>, +v_8: Nat, +v_11: List<&2, cps_provider_1_FormArm>, +v_13: cps_provider_2_Src, +v_15: cps_provider_2_Dst, +v_17: String) -> List<&2, cps_provider_2_Job>:
  v_22 = cps_provider_2_form_tagged(v_11)
  v_26 = cps_provider_2_form_base(v_3, cps_provider_2_form_tagged(v_6))
  v_29 = cps_provider_2_form_base(v_8, v_22)
  native_match_cps_provider_2_expand_forms_0(v_6, v_1, v_11, v_13, v_15, v_17, v_22, v_26, v_29)

def cps_provider_2_forms_single(+v_1: cps_provider_2_World, +v_2: cps_provider_1_FormArm, +v_4: Nat, +v_6: Nat, +v_8: Bool, +v_10: List<&2, cps_provider_1_FormArm>, +v_12: cps_provider_2_Src, +v_14: cps_provider_2_Dst, +v_16: String) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case cps_provider_1_FormArm{v_24, v_25, v_26, v_27, v_28}:
      cps_provider_2_forms_arm_body(v_1, v_27, v_28, v_4, v_6, v_8, cps_provider_2_form_arm_by_key(v_24, v_10), v_12, v_14, v_16)

def cps_provider_2_pack_jobs(+v_1: U32, +v_3: Nat, +v_5: Bool, +v_7: String, +v_9: String, +v_11: String) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case 0n:
      [cps_provider_2_JText{cps_provider_2_join_text([v_9, " = term_pak(", U32.show(v_1), "u, 0);"])}]
    case _:
      match v_5:
        case True{}:
          [cps_provider_2_JText{cps_provider_2_join_text([v_9, " = term_pak(", U32.show(v_1), "u, (u64)", v_7, "[0]);"])}]
        case False{}:
          v_20 = cps_provider_2_join_text([v_11, "l"])
          [cps_provider_2_JText{cps_provider_2_join_text(["u64 ", v_20, " = heap_alloc(e, cls_fit(", Nat.show(v_3), ")); for (u32 ", v_20, "i = 0; ", v_20, "i < ", Nat.show(v_3), "; ", v_20, "i += 1) { e.mem[", v_20, " + ", v_20, "i] = ", v_7, "[", v_20, "i]; } ", v_9, " = term_ctr(", U32.show(v_1), "u, ", v_20, ");"])}]

def cps_provider_2_arm_block_jobs(+v_1: cps_provider_2_World, +v_3: U32, +v_4: cps_provider_1_FormArm, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String, +v_14: Nat) -> List<&2, cps_provider_2_Job>:
  match v_4:
    case cps_provider_1_FormArm{v_22, v_23, v_24, v_25, v_26}:
      v_29 = cps_provider_2_join_text([v_12, "w"])
      v_32 = cps_provider_2_join_text([v_12, "j"])
      List.append(&2, cps_provider_2_Job, cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_dst_decl(v_29, v_32, v_25)}), List.append(&2, cps_provider_2_Job, cps_provider_2_nests_jobs(v_1, v_26, v_8, cps_provider_2_DstSeq{v_29, v_32}, cps_provider_2_join_text([v_12, "x", Nat.show(v_14)]), 0n), List.append(&2, cps_provider_2_Job, cps_provider_2_src_skip_jobs(v_8, cps_provider_2_form_pad(v_6, v_25)), cps_provider_2_pack_jobs(v_3, v_25, v_24, v_29, v_10, v_12))))

def cps_provider_2_box_arm_jobs(+v_1: cps_provider_2_World, +v_4: Maybe<&2, U32>, +v_5: cps_provider_1_FormArm, +v_7: Nat, +v_9: cps_provider_2_Src, +v_11: String, +v_13: String, +v_15: Nat) -> List<&2, cps_provider_2_Job>:
  match v_4:
    case None{}:
      [cps_provider_2_JText{"default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;"}]
    case Some{v_19}:
      List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["case ", Nat.show(v_15), ": {"])}], List.append(&2, cps_provider_2_Job, cps_provider_2_arm_block_jobs(v_1, v_19, v_5, v_7, v_9, v_11, v_13, v_15), [cps_provider_2_JText{"} break;"}]))

def cps_provider_2_box_cases(+v_1: cps_provider_2_World, +v_3: List<&2, cps_provider_1_FormArm>, +v_5: Nat, +v_7: cps_provider_2_Src, +v_9: String, +v_11: String, +v_13: Nat) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case []:
      []
    case +v_18 <> +v_19:
      match v_18:
        case cps_provider_1_FormArm{v_25, v_26, v_27, v_28, v_29}:
          v_32 = cps_provider_2_cid_of(v_25, v_1)
          v_35 = cps_provider_2_box_arm_jobs(v_1, v_32, v_18, v_5, v_7, v_9, v_11, v_13)
          List.append(&2, cps_provider_2_Job, v_35, cps_provider_2_box_cases(v_1, v_19, v_5, v_7, v_9, v_11, Nat.add(v_13, 1n)))

def native_match_cps_provider_2_box_untagged_0(v_34: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String, +v_16: cps_provider_1_FormArm) -> List<&2, cps_provider_2_Job>:
  match v_34:
    case None{}:
      [cps_provider_2_JText{"(void)err_fail(\"the constructor tag is not a declared constructor\");"}]
    case Some{v_29}:
      cps_provider_2_arm_block_jobs(v_1, v_29, v_16, v_6, v_8, v_10, v_12, 0n)

def native_match_cps_provider_2_box_untagged_1(+v_16: cps_provider_1_FormArm, +v_1: cps_provider_2_World, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String) -> List<&2, cps_provider_2_Job>:
  match v_16:
    case cps_provider_1_FormArm{v_22, v_23, v_24, v_25, v_26}:
      native_match_cps_provider_2_box_untagged_0(cps_provider_2_cid_of(v_22, v_1), v_1, v_6, v_8, v_10, v_12, v_16)

def native_match_cps_provider_2_box_untagged_2(+v_4: List<&2, cps_provider_1_FormArm>, +v_1: cps_provider_2_World, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String) -> List<&2, cps_provider_2_Job>:
  match v_4:
    case []:
      []
    case [+v_16]:
      native_match_cps_provider_2_box_untagged_1(v_16, v_1, v_6, v_8, v_10, v_12)
    case _:
      []

def cps_provider_2_box_untagged(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_FormArm>, +v_6: Nat, +v_8: cps_provider_2_Src, +v_10: String, +v_12: String) -> List<&2, cps_provider_2_Job>:
  native_match_cps_provider_2_box_untagged_2(v_4, v_1, v_6, v_8, v_10, v_12)

def cps_provider_2_expand_box(+v_1: cps_provider_2_World, +v_3: Nat, +v_5: List<&2, cps_provider_1_FormArm>, +v_7: cps_provider_2_Src, +v_9: cps_provider_2_Dst, +v_11: String) -> List<&2, cps_provider_2_Job>:
  v_16 = cps_provider_2_join_text([v_11, "r"])
  v_19 = cps_provider_2_form_tagged(v_5)
  v_22 = cps_provider_2_form_base(v_3, v_19)
  List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["Term ", v_16, " = 0;"])}], cps_provider_2_expand_box_body(v_19, v_22, v_1, v_5, v_7, v_9, v_11, v_16))

def cps_provider_2_expand_box_body(+v_1: Bool, +v_3: Nat, +v_5: cps_provider_2_World, +v_7: List<&2, cps_provider_1_FormArm>, +v_9: cps_provider_2_Src, +v_11: cps_provider_2_Dst, +v_13: String, +v_15: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case True{}:
      List.append(&2, cps_provider_2_Job, cps_provider_2_src_read(v_9, v_13), List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["switch ((u32)(", v_13, "w)) {"])}], List.append(&2, cps_provider_2_Job, cps_provider_2_box_cases(v_5, v_7, v_3, v_9, v_15, v_13, 0n), List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{"}"}], cps_provider_2_dst_write(v_11, v_15)))))
    case False{}:
      List.append(&2, cps_provider_2_Job, cps_provider_2_box_untagged(v_5, v_7, v_3, v_9, v_15, v_13), cps_provider_2_dst_write(v_11, v_15))

def cps_provider_2_expand_form_take(+v_1: cps_provider_2_World, +v_3: Nat, +v_5: List<&2, cps_provider_1_FormArm>, +v_6: cps_provider_1_Fill, +v_8: cps_provider_2_Src, +v_10: cps_provider_2_Dst, +v_12: String) -> List<&2, cps_provider_2_Job>:
  match v_6:
    case cps_provider_1_FillWord{}:
      cps_provider_2_expand_box(v_1, v_3, v_5, v_8, v_10, v_12)
    case cps_provider_1_FillForm{v_18, v_19}:
      cps_provider_2_expand_forms(v_1, v_3, v_5, v_18, v_19, v_8, v_10, v_12)

def cps_provider_2_expand_conv(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Unfill, +v_3: cps_provider_1_Fill, +v_5: cps_provider_2_Src, +v_7: cps_provider_2_Dst, +v_9: String) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case cps_provider_1_UnfillWord{}:
      cps_provider_2_expand_word_take(v_1, v_3, v_5, v_7, v_9)
    case cps_provider_1_UnfillForm{v_15, v_16}:
      cps_provider_2_expand_form_take(v_1, v_15, v_16, v_3, v_5, v_7, v_9)

def cps_provider_2_run_jobs(+v_2: List<&2, cps_provider_2_Job>, +v_4: cps_provider_2_World, +v_7: List<&2, String>) -> cps_provider_2_Code:
  match v_2:
    case []:
      cps_provider_2_CodeOk(v_7)
    case +v_12 <> +v_13:
      match v_12:
        case cps_provider_2_JText{v_15}:
          cps_provider_2_run_jobs(v_13, v_4, List.append(&2, String, v_7, [v_15]))
        case cps_provider_2_JFail{v_19}:
          cps_provider_2_CodeFail{v_19}
        case cps_provider_2_JConv{v_25, v_26, v_27, v_28, v_29}:
          cps_provider_2_run_jobs(List.append(&2, cps_provider_2_Job, cps_provider_2_expand_conv(v_4, v_25, v_26, v_27, v_28, v_29), v_13), v_4, v_7)

def cps_provider_2_fill_plan_jobs(+v_0: cps_provider_1_Fill, +v_2: String, +v_4: cps_provider_2_Dst, +v_6: String) -> List<&2, cps_provider_2_Job>:
  match v_0:
    case cps_provider_1_FillWord{}:
      [cps_provider_2_JFail{"a data layout produced a one-word fill"}]
    case cps_provider_1_FillForm{v_11, v_12}:
      [cps_provider_2_JConv{cps_provider_1_UnfillWord{}, v_0, cps_provider_2_SrcOne{v_2}, v_4, v_6}]

def cps_provider_2_fill_result_jobs(+v_0: cps_provider_1_FillResult, +v_2: String, +v_4: cps_provider_2_Dst, +v_6: String) -> List<&2, cps_provider_2_Job>:
  match v_0:
    case cps_provider_1_FillFailed{v_10}:
      [cps_provider_2_JFail{v_10}]
    case cps_provider_1_FillFound{v_12}:
      cps_provider_2_fill_plan_jobs(v_12, v_2, v_4, v_6)

def cps_provider_2_fill_data_jobs(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_4: String, +v_6: cps_provider_2_Dst, +v_8: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_2_World{v_14, v_15, v_16}:
      v_18 = cps_provider_1_layout_fill(v_14, v_2)
      cps_provider_2_fill_result_jobs(v_18, v_4, v_6, v_8)

def cps_provider_2_fill_jobs(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_4: String, +v_6: cps_provider_2_Dst, +v_8: String) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case cps_provider_1_LayoutWord{v_12}:
      cps_provider_2_dst_word(v_6, v_12, v_4)
    case cps_provider_1_LayoutBox{v_15}:
      cps_provider_2_dst_write(v_6, v_4)
    case cps_provider_1_LayoutData{v_19, v_20}:
      cps_provider_2_fill_data_jobs(v_1, v_2, v_4, v_6, v_8)

def cps_provider_2_unfill_result_jobs(+v_0: cps_provider_1_UnfillResult, +v_2: cps_provider_2_Src, +v_4: String, +v_6: String) -> List<&2, cps_provider_2_Job>:
  match v_0:
    case cps_provider_1_UnfillFailed{v_10}:
      [cps_provider_2_JFail{v_10}]
    case cps_provider_1_UnfillFound{v_12}:
      [cps_provider_2_JConv{v_12, cps_provider_1_FillWord{}, v_2, cps_provider_2_DstOut{v_4}, v_6}]

def cps_provider_2_unfill_data_jobs(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_4: cps_provider_2_Src, +v_6: String, +v_8: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_2_World{v_14, v_15, v_16}:
      v_18 = cps_provider_1_layout_unfill(v_14, v_2)
      cps_provider_2_unfill_result_jobs(v_18, v_4, v_6, v_8)

def cps_provider_2_unfill_word_jobs(+v_0: cps_provider_1_CWord, +v_2: cps_provider_2_Src, +v_4: String, +v_6: String) -> List<&2, cps_provider_2_Job>:
  match v_0:
    case cps_provider_1_CWord32{}:
      List.append(&2, cps_provider_2_Job, cps_provider_2_src_read(v_2, v_6), [cps_provider_2_JText{cps_provider_2_join_text([v_4, " = ((u64)(u32)(", v_6, "w));"])}])
    case _:
      List.append(&2, cps_provider_2_Job, cps_provider_2_src_read(v_2, v_6), [cps_provider_2_JText{cps_provider_2_join_text([v_4, " = ", v_6, "w;"])}])

def cps_provider_2_unfill_jobs(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_4: cps_provider_2_Src, +v_6: String, +v_8: String) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case cps_provider_1_LayoutWord{v_12}:
      cps_provider_2_unfill_word_jobs(v_12, v_4, v_6, v_8)
    case cps_provider_1_LayoutBox{v_15}:
      List.append(&2, cps_provider_2_Job, cps_provider_2_src_read(v_4, v_8), [cps_provider_2_JText{cps_provider_2_join_text([v_6, " = ", v_8, "w;"])}])
    case cps_provider_1_LayoutData{v_21, v_22}:
      cps_provider_2_unfill_data_jobs(v_1, v_2, v_4, v_6, v_8)

def cps_provider_2_operand_code(+v_0: cps_provider_1_Layout, +v_1: BIR.Use, +v_3: String, +v_5: String) -> cps_provider_2_Code:
  match v_0:
    case cps_provider_1_LayoutData{v_9, v_10}:
      match v_1:
        case BIR.Many{}:
          cps_provider_2_code_line(cps_provider_2_join_text(["Term ", v_5, "v = term_keep(e, ", v_3, ", 1);"]))
        case _:
          cps_provider_2_code_empty
    case _:
      cps_provider_2_code_empty

def cps_provider_2_operand_name(+v_0: cps_provider_1_Layout, +v_1: BIR.Use, +v_3: String, +v_5: String) -> String:
  match v_0:
    case cps_provider_1_LayoutData{v_9, v_10}:
      match v_1:
        case BIR.Many{}:
          cps_provider_2_join_text([v_5, "v"])
        case _:
          cps_provider_2_join_text(["(", v_3, ")"])
    case _:
      cps_provider_2_join_text(["(", v_3, ")"])

def cps_provider_2_text_jobs(+v_2: List<&2, String>) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case []:
      []
    case +v_7 <> +v_8:
      List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{v_7}], cps_provider_2_text_jobs(v_8))

def cps_provider_2_code_jobs(+v_1: cps_provider_2_Code) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_2_CodeFail{v_5}:
      [cps_provider_2_JFail{v_5}]
    case cps_provider_2_CodeOk{v_7}:
      cps_provider_2_text_jobs(v_7)

def native_match_cps_provider_2_fill_slots_jobs_0(+v_7: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  match v_7:
    case []:
      []
    case _:
      [cps_provider_2_JFail{"the constructor's slots and fields differ"}]

def native_match_cps_provider_2_fill_slots_jobs_1(+v_18: cps_provider_2_Operand, +v_1: cps_provider_2_World, +v_15: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, cps_provider_2_Operand>, v_23: U32, v_25: cps_provider_1_Layout) -> List<&2, cps_provider_2_Job>:
  match v_18:
    case cps_provider_2_Operand{v_28, v_29}:
      v_32 = cps_provider_2_join_text(["s", U32.show(v_23)])
      v_35 = cps_provider_2_operand_code(v_25, v_28, v_29, v_32)
      v_38 = cps_provider_2_operand_name(v_25, v_28, v_29, v_32)
      List.append(&2, cps_provider_2_Job, cps_provider_2_code_jobs(v_35), List.append(&2, cps_provider_2_Job, cps_provider_2_fill_jobs(v_1, v_25, v_38, cps_provider_2_DstSeq{"w0", "o0"}, v_32), cps_provider_2_fill_slots_jobs(v_1, v_15, v_19)))

def native_match_cps_provider_2_fill_slots_jobs_2(+v_14: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_15: List<&2, cps_provider_1_NodeSlot>, +v_18: cps_provider_2_Operand, +v_19: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  match v_14:
    case cps_provider_1_NodeSlot{v_23, v_24, v_25}:
      native_match_cps_provider_2_fill_slots_jobs_1(v_18, v_1, v_15, v_19, v_23, v_25)

def native_match_cps_provider_2_fill_slots_jobs_3(+v_7: List<&2, cps_provider_2_Operand>, +v_1: cps_provider_2_World, +v_14: cps_provider_1_NodeSlot, +v_15: List<&2, cps_provider_1_NodeSlot>) -> List<&2, cps_provider_2_Job>:
  match v_7:
    case []:
      [cps_provider_2_JFail{"the constructor's slots and fields differ"}]
    case +v_18 <> +v_19:
      native_match_cps_provider_2_fill_slots_jobs_2(v_14, v_1, v_15, v_18, v_19)

def native_match_cps_provider_2_fill_slots_jobs_4(+v_4: List<&2, cps_provider_1_NodeSlot>, +v_1: cps_provider_2_World, +v_7: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  match v_4:
    case []:
      native_match_cps_provider_2_fill_slots_jobs_0(v_7)
    case +v_14 <> +v_15:
      native_match_cps_provider_2_fill_slots_jobs_3(v_7, v_1, v_14, v_15)

def cps_provider_2_fill_slots_jobs(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  native_match_cps_provider_2_fill_slots_jobs_4(v_4, v_1, v_7)

def cps_provider_2_layout_is_data(+v_0: cps_provider_1_Layout) -> Bool:
  match v_0:
    case cps_provider_1_LayoutData{v_4, v_5}:
      True{}
    case _:
      False{}

def cps_provider_2_seal_box_many(+v_1: String, +v_3: Bool) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case True{}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_1, " += 1;"])}]
    case False{}:
      [cps_provider_2_JText{cps_provider_2_join_text(["w0[", v_1, "] = term_keep(e, w0[", v_1, "], 1); ", v_1, " += 1;"])}]

def cps_provider_2_seal_box(+v_0: BIR.Use, +v_2: String, +v_4: Bool) -> List<&2, cps_provider_2_Job>:
  match v_0:
    case BIR.Many{}:
      cps_provider_2_seal_box_many(v_2, v_4)
    case _:
      [cps_provider_2_JText{cps_provider_2_join_text(["w0[", v_2, "] = rfc_seal(e, w0[", v_2, "]); ", v_2, " += 1;"])}]

def cps_provider_2_seal_kind(+v_0: BIR.Use, +v_1: cps_provider_1_CWord, +v_3: String, +v_5: Bool) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_1_CWord32{}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_3, " += 1;"])}]
    case cps_provider_1_CWord64{}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_3, " += 1;"])}]
    case cps_provider_1_CWordBox{}:
      cps_provider_2_seal_box(v_0, v_3, v_5)

def cps_provider_2_seal_kind_walk(+v_0: BIR.Use, +v_2: List<&2, cps_provider_1_CWord>, +v_4: String, +v_6: Bool) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case []:
      []
    case +v_11 <> +v_12:
      List.append(&2, cps_provider_2_Job, cps_provider_2_seal_kind(v_0, v_11, v_4, v_6), cps_provider_2_seal_kind_walk(v_0, v_12, v_4, v_6))

def native_match_cps_provider_2_seal_slots_jobs_0(+v_7: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  match v_7:
    case []:
      []
    case _:
      cps_provider_2_one_job(cps_provider_2_JFail{"the constructor's slots and fields differ"})

def native_match_cps_provider_2_seal_slots_jobs_1(+v_20: cps_provider_2_Operand, +v_1: cps_provider_2_World, +v_16: List<&2, cps_provider_1_NodeSlot>, +v_21: List<&2, cps_provider_2_Operand>, v_25: U32, v_26: Nat, v_27: cps_provider_1_Layout) -> List<&2, cps_provider_2_Job>:
  match v_20:
    case cps_provider_2_Operand{v_30, v_31}:
      List.append(&2, cps_provider_2_Job, cps_provider_2_one_job(cps_provider_2_JText{String.append(String.append(String.append(String.append("u32 k", U32.show(v_25)), " = "), Nat.show(v_26)), ";")}), List.append(&2, cps_provider_2_Job, cps_provider_2_seal_kind_walk(v_30, cps_provider_1_layout_kinds(v_27), String.append("k", U32.show(v_25)), cps_provider_2_layout_is_data(v_27)), cps_provider_2_seal_slots_jobs(v_1, v_16, v_21)))

def native_match_cps_provider_2_seal_slots_jobs_2(+v_15: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_16: List<&2, cps_provider_1_NodeSlot>, +v_20: cps_provider_2_Operand, +v_21: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  match v_15:
    case cps_provider_1_NodeSlot{v_25, v_26, v_27}:
      native_match_cps_provider_2_seal_slots_jobs_1(v_20, v_1, v_16, v_21, v_25, v_26, v_27)

def native_match_cps_provider_2_seal_slots_jobs_3(+v_7: List<&2, cps_provider_2_Operand>, +v_1: cps_provider_2_World, +v_15: cps_provider_1_NodeSlot, +v_16: List<&2, cps_provider_1_NodeSlot>) -> List<&2, cps_provider_2_Job>:
  match v_7:
    case []:
      cps_provider_2_one_job(cps_provider_2_JFail{"the constructor's slots and fields differ"})
    case +v_20 <> +v_21:
      native_match_cps_provider_2_seal_slots_jobs_2(v_15, v_1, v_16, v_20, v_21)

def native_match_cps_provider_2_seal_slots_jobs_4(+v_4: List<&2, cps_provider_1_NodeSlot>, +v_1: cps_provider_2_World, +v_7: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  match v_4:
    case []:
      native_match_cps_provider_2_seal_slots_jobs_0(v_7)
    case +v_15 <> +v_16:
      native_match_cps_provider_2_seal_slots_jobs_3(v_7, v_1, v_15, v_16)

def cps_provider_2_seal_slots_jobs(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, cps_provider_2_Operand>) -> List<&2, cps_provider_2_Job>:
  native_match_cps_provider_2_seal_slots_jobs_4(v_4, v_1, v_7)

def cps_provider_2_one_job(+v_1: cps_provider_2_Job) -> List<&2, cps_provider_2_Job>:
  [v_1]

def cps_provider_2_construct_words(+v_1: cps_provider_2_World, +v_3: U32, +v_5: Nat, +v_7: List<&2, cps_provider_1_NodeSlot>, +v_10: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  v_21 = List.append(&2, cps_provider_2_Job, cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_dst_decl("w0", "o0", v_5)}), List.append(&2, cps_provider_2_Job, cps_provider_2_fill_slots_jobs(v_1, v_7, v_10), List.append(&2, cps_provider_2_Job, cps_provider_2_seal_slots_jobs(v_1, v_7, v_10), cps_provider_2_one_job(cps_provider_2_JText{String.append(String.append(String.append(String.append("u64 n0 = heap_alloc(e, cls_fit(", Nat.show(v_5)), ")); for (u32 n0i = 0; n0i < "), Nat.show(v_5)), "; n0i += 1) { e.mem[n0 + n0i] = w0[n0i]; }")}))))
  cps_provider_2_part_of(cps_provider_2_run_jobs(v_21, v_1, []), String.append(String.append("term_ctr(", U32.show(v_3)), "u, n0)"))

def cps_provider_2_codeSeqPack(+v_1: cps_provider_2_Code, +v_3: cps_provider_2_World, +v_4: cps_provider_1_Layout, +v_6: String, +v_8: U32) -> cps_provider_2_Code:
  v_16 = List.append(&2, cps_provider_2_Job, cps_provider_2_one_job(cps_provider_2_JText{"u64 w0[1]; w0[0] = 0; u32 o0 = 0;"}), List.append(&2, cps_provider_2_Job, cps_provider_2_code_jobs(v_1), cps_provider_2_fill_jobs(v_3, v_4, v_6, cps_provider_2_DstSeq{"w0", "o0"}, "p0")))
  cps_provider_2_run_jobs(v_16, v_3, [])

def cps_provider_2_construct_packed_one(+v_1: cps_provider_2_World, +v_3: U32, +v_4: cps_provider_1_NodeSlot, +v_6: cps_provider_2_Operand) -> cps_provider_2_Part:
  match v_4:
    case cps_provider_1_NodeSlot{v_11, v_12, v_13}:
      match v_6:
        case cps_provider_2_Operand{v_16, v_17}:
          v_20 = cps_provider_2_operand_code(v_13, v_16, v_17, "p0")
          v_23 = cps_provider_2_operand_name(v_13, v_16, v_17, "p0")
          cps_provider_2_part_of(cps_provider_2_codeSeqPack(v_20, v_1, v_13, v_23, v_3), cps_provider_2_join_text(["term_pak(", U32.show(v_3), "u, (u64)w0[0])"]))

def cps_provider_2_construct_packed(+v_1: cps_provider_2_World, +v_3: U32, +v_5: String, +v_6: cps_provider_1_Node, +v_9: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_6:
    case cps_provider_1_Node{v_14, v_15, v_16}:
      match v_15:
        case []:
          match v_9:
            case []:
              cps_provider_2_PartOk{cps_provider_2_join_text(["term_pak(", U32.show(v_3), "u, 0)"])}
            case _:
              cps_provider_2_PartFail{cps_provider_2_join_text(["the constructor `", v_5, "` has an inconsistent packed node"])}
        case [+v_22]:
          match v_9:
            case [+v_24]:
              cps_provider_2_construct_packed_one(v_1, v_3, v_22, v_24)
            case _:
              cps_provider_2_PartFail{cps_provider_2_join_text(["the constructor `", v_5, "` has an inconsistent packed node"])}
        case _:
          cps_provider_2_PartFail{cps_provider_2_join_text(["the constructor `", v_5, "` has an inconsistent packed node"])}

def cps_provider_2_construct_packed_flag(+v_1: Bool, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_8: cps_provider_1_Node, +v_11: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_1:
    case True{}:
      cps_provider_2_construct_packed(v_3, v_5, v_7, v_8, v_11)
    case False{}:
      match v_8:
        case cps_provider_1_Node{v_17, v_18, v_19}:
          cps_provider_2_construct_words(v_3, v_5, List.length(&2, cps_provider_1_CWord, v_17), v_18, v_11)

def cps_provider_2_construct_count(+v_1: Bool, +v_3: cps_provider_2_World, +v_5: U32, +v_7: String, +v_8: cps_provider_1_Node, +v_11: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_1:
    case False{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the constructor `", v_7, "` has a different live field count than its value arguments"])}
    case True{}:
      match v_8:
        case cps_provider_1_Node{v_17, v_18, v_19}:
          cps_provider_2_construct_packed_flag(v_19, v_3, v_5, v_7, v_8, v_11)

def cps_provider_2_construct_node(+v_1: cps_provider_2_World, +v_3: U32, +v_5: String, +v_6: cps_provider_1_Node, +v_9: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_6:
    case cps_provider_1_Node{v_14, v_15, v_16}:
      v_19 = Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_15), List.length(&2, cps_provider_2_Operand, v_9))
      cps_provider_2_construct_count(v_19, v_1, v_3, v_5, v_6, v_9)

def cps_provider_2_construct_layout(+v_0: cps_provider_1_NodeResult, +v_2: cps_provider_2_World, +v_4: U32, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_0:
    case cps_provider_1_NodeFailed{v_12}:
      cps_provider_2_PartFail{v_12}
    case cps_provider_1_NodeFound{v_14}:
      cps_provider_2_construct_node(v_2, v_4, v_6, v_14, v_9)

def cps_provider_2_construct_cid(+v_2: Maybe<&2, U32>, +v_4: cps_provider_2_World, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the constructor `", v_6, "` has no canonical CID row"])}
    case Some{v_13}:
      match v_4:
        case cps_provider_2_World{v_17, v_18, v_19}:
          v_21 = cps_provider_1_node_layout(v_17, v_6)
          cps_provider_2_construct_layout(v_21, v_4, v_13, v_6, v_9)

def cps_provider_2_construct_generic(+v_1: cps_provider_2_World, +v_3: String, +v_6: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  v_10 = cps_provider_2_cid_of(v_3, v_1)
  cps_provider_2_construct_cid(v_10, v_1, v_3, v_6)

def cps_provider_2_construct_marker(+v_1: Bool, +v_3: cps_provider_2_World, +v_5: String, +v_8: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_1:
    case True{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the intrinsic constructor `", v_5, "` must be lowered to its primitive before C emission"])}
    case False{}:
      cps_provider_2_construct_generic(v_3, v_5, v_8)

def cps_provider_2_construct_native(+v_2: Maybe<&2, String>, +v_4: cps_provider_2_World, +v_6: String, +v_9: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_construct_generic(v_4, v_6, v_9)
    case Some{v_13}:
      cps_provider_2_construct_marker(cps_provider_2_intrinsic_marker(v_13), v_4, v_6, v_9)

def cps_provider_2_construct_row(+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: cps_provider_2_World, +v_6: List<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_1:
    case None{}:
      cps_provider_2_PartFail{"BIR constructs a constructor with no layout row"}
    case Some{v_9}:
      match v_9:
        case BIR.ConstructorLayout{v_14, v_15, v_16, v_17}:
          cps_provider_2_construct_native(v_16, v_3, v_15, v_6)

def cps_provider_2_construct_part(+v_1: U32, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  v_10 = cps_provider_2_ctor_of(v_1, v_6)
  cps_provider_2_construct_row(v_10, v_6, v_4)

def cps_provider_2_term_decl_text(+v_1: Nat) -> String:
  match v_1:
    case 0n:
      ""
    case _:
      cps_provider_2_join_text(["Term b0f[", Nat.show(v_1), "];"])

def native_match_cps_provider_2_project_prelude_0(+v_1: cps_provider_1_Layout, v_12: String) -> String:
  match v_1:
    case cps_provider_1_LayoutWord{v_14}:
      cps_provider_2_join_text([v_12, " Term b0r = 0;"])
    case cps_provider_1_LayoutBox{v_17}:
      cps_provider_2_join_text([v_12, " Term b0r = 0;"])
    case cps_provider_1_LayoutData{v_21, v_22}:
      v_12

def cps_provider_2_project_prelude(+v_1: cps_provider_1_Layout, +v_3: String, +v_5: Nat, +v_7: Nat) -> String:
  v_12 = cps_provider_2_join_text(["Term b0t = ", v_3, ";", cps_provider_2_term_decl_text(v_5), "u64 b0s = term_rfc(b0t) ? ctr_take(e, b0t, ", Nat.show(v_5), ", b0f) : term_loc(b0t); u32 b0i = ", Nat.show(v_7), ";"])
  native_match_cps_provider_2_project_prelude_0(v_1, v_12)

def cps_provider_2_project_words(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_4: Nat, +v_6: Nat, +v_8: String) -> cps_provider_2_Part:
  v_15 = List.append(&2, cps_provider_2_Job, cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_project_prelude(v_2, v_8, v_6, v_4)}), cps_provider_2_unfill_jobs(v_1, v_2, cps_provider_2_SrcNode{"b0s", "b0f", "b0i", False{}}, "b0r", "b0"))
  cps_provider_2_part_of(cps_provider_2_run_jobs(v_15, v_1, []), "b0r")

def native_match_cps_provider_2_project_packed_prelude_0(+v_1: cps_provider_1_Layout, v_7: String) -> String:
  match v_1:
    case cps_provider_1_LayoutWord{v_9}:
      cps_provider_2_join_text([v_7, " Term b0r = 0;"])
    case cps_provider_1_LayoutBox{v_12}:
      cps_provider_2_join_text([v_7, " Term b0r = 0;"])
    case cps_provider_1_LayoutData{v_16, v_17}:
      v_7

def cps_provider_2_project_packed_prelude(+v_1: cps_provider_1_Layout, +v_3: String) -> String:
  v_7 = cps_provider_2_join_text(["Term b0t = ", v_3, ";"])
  native_match_cps_provider_2_project_packed_prelude_0(v_1, v_7)

def cps_provider_2_project_packed(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_4: String) -> cps_provider_2_Part:
  v_11 = List.append(&2, cps_provider_2_Job, cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_project_packed_prelude(v_2, v_4)}), cps_provider_2_unfill_jobs(v_1, v_2, cps_provider_2_SrcOne{"((u64)term_loc(b0t))"}, "b0r", "b0"))
  cps_provider_2_part_of(cps_provider_2_run_jobs(v_11, v_1, []), "b0r")

def cps_provider_2_project_packed_flag(+v_1: Bool, +v_3: cps_provider_2_World, +v_4: cps_provider_1_Layout, +v_6: Nat, +v_8: Nat, +v_10: String) -> cps_provider_2_Part:
  match v_1:
    case True{}:
      cps_provider_2_project_packed(v_3, v_4, v_10)
    case False{}:
      cps_provider_2_project_words(v_3, v_4, v_6, v_8, v_10)

def cps_provider_2_unique_expr(+v_1: String) -> String:
  cps_provider_2_join_text(["(!term_triv(", v_1, ") && !(term_rfc(", v_1, ") && (a32_load(a32_at(e.mem, term_loc(", v_1, "))) & RFC_CNT) > 1))"])

def cps_provider_2_static_expr(+v_1: String) -> String:
  cps_provider_2_join_text(["term_triv(", v_1, ")"])

def cps_provider_2_and_expr(+v_1: String, +v_3: String) -> String:
  cps_provider_2_join_text(["(", v_1, " && ", v_3, ")"])

def cps_provider_2_or_expr(+v_1: String, +v_3: String) -> String:
  cps_provider_2_join_text(["(", v_1, " || ", v_3, ")"])

def cps_provider_2_nat_if(+v_1: Bool, +v_3: Nat, +v_5: Nat) -> Nat:
  match v_1:
    case True{}:
      v_3
    case False{}:
      v_5

def cps_provider_2_live_ordinal(+v_1: List<&2, BIR.DescriptorField>, +v_3: U32) -> Maybe<&2, U32>:
  cps_provider_2_live_walk(v_1, U32.to_nat(v_3), 0n, 0n)

def native_match_cps_provider_2_live_walk_0(v_18: BIR.Quantity, +v_7: Nat) -> Maybe<&2, U32>:
  match v_18:
    case BIR.Erased{}:
      None{}
    case _:
      Some{U32.from_nat(v_7)}

def native_match_cps_provider_2_live_walk_1(v_22: Bool, +v_3: Nat, +v_5: Nat, +v_7: Nat, v_13: List<&2, BIR.DescriptorField>, v_18: BIR.Quantity) -> Maybe<&2, U32>:
  match v_22:
    case True{}:
      native_match_cps_provider_2_live_walk_0(v_18, v_7)
    case False{}:
      cps_provider_2_live_walk(v_13, v_3, Nat.add(v_5, 1n), cps_provider_2_live_next(v_18, v_7))

def native_match_cps_provider_2_live_walk_2(+v_12: BIR.DescriptorField, +v_3: Nat, +v_5: Nat, +v_7: Nat, v_13: List<&2, BIR.DescriptorField>) -> Maybe<&2, U32>:
  match v_12:
    case BIR.DescriptorField{v_17, v_18, v_19}:
      native_match_cps_provider_2_live_walk_1(Nat.is_eq(v_5, v_3), v_3, v_5, v_7, v_13, v_18)

def native_match_cps_provider_2_live_walk_3(+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat) -> Maybe<&2, U32>:
  match v_1:
    case []:
      None{}
    case +v_12 <> v_13:
      native_match_cps_provider_2_live_walk_2(v_12, v_3, v_5, v_7, v_13)

def cps_provider_2_live_walk(+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat) -> Maybe<&2, U32>:
  native_match_cps_provider_2_live_walk_3(v_1, v_3, v_5, v_7)

def cps_provider_2_live_next(+v_0: BIR.Quantity, +v_2: Nat) -> Nat:
  match v_0:
    case BIR.Erased{}:
      v_2
    case _:
      Nat.add(v_2, 1n)

def cps_provider_2_arm_fields_of(+v_1: List<&2, cps_provider_1_LayArm>, +v_3: String) -> Maybe<&2, List<&2, cps_provider_1_Layout>>:
  match v_1:
    case []:
      None{}
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_1_LayArm{v_12, v_13}:
          v_15 = String.eq(v_12, v_3)
          Bool.pick(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_15, Some{v_13}, cps_provider_2_arm_fields_of(v_9, v_3))

def cps_provider_2_arm_fields_declared(+v_1: Maybe<&2, BIR.DescriptorArm>) -> Maybe<&2, List<&2, BIR.DescriptorField>>:
  match v_1:
    case None{}:
      None{}
    case Some{+v_5}:
      match v_5:
        case BIR.DescriptorArm{+v_8, +v_9}:
          Some{v_9}

def cps_provider_2_arm_descriptor_fields(+v_1: cps_provider_2_World, +v_3: String) -> Maybe<&2, List<&2, BIR.DescriptorField>>:
  match v_1:
    case cps_provider_2_World{v_9, v_10, v_11}:
      cps_provider_2_arm_fields_declared(cps_provider_1_arm_declared(v_9, v_3))

def native_match_cps_provider_2_step_key_0(v_8: BIR.ConstructorLayout) -> Maybe<&2, String>:
  match v_8:
    case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
      Some{v_14}

def native_match_cps_provider_2_step_key_1(v_17: Maybe<&2, BIR.ConstructorLayout>) -> Maybe<&2, String>:
  match v_17:
    case None{}:
      None{}
    case Some{v_8}:
      native_match_cps_provider_2_step_key_0(v_8)

def cps_provider_2_step_key(+v_1: cps_provider_2_World, +v_3: U32) -> Maybe<&2, String>:
  native_match_cps_provider_2_step_key_1(cps_provider_2_ctor_of(v_3, v_1))

def native_match_cps_provider_2_cell_lgs_0(v_16: cps_provider_1_CellResult) -> Maybe<&2, cps_provider_1_Cell>:
  match v_16:
    case cps_provider_1_CellFailed{v_13}:
      None{}
    case cps_provider_1_CellFound{v_15}:
      Some{v_15}

def native_match_cps_provider_2_cell_lgs_1(+v_1: cps_provider_2_World, +v_2: BIR.Descriptor) -> Maybe<&2, cps_provider_1_Cell>:
  match v_1:
    case cps_provider_2_World{v_8, v_9, v_10}:
      native_match_cps_provider_2_cell_lgs_0(cps_provider_1_array_cell(v_8, v_2))

def cps_provider_2_cell_lgs(+v_1: cps_provider_2_World, +v_2: BIR.Descriptor) -> Maybe<&2, cps_provider_1_Cell>:
  native_match_cps_provider_2_cell_lgs_1(v_1, v_2)

def cps_provider_2_not_bool(+v_1: Bool) -> Bool:
  match v_1:
    case True{}:
      False{}
    case False{}:
      True{}

def native_match_cps_provider_2_live_ordinal_in_0(v_21: Bool, +v_7: U32) -> Maybe<&2, U32>:
  match v_21:
    case True{}:
      Some{v_7}
    case False{}:
      None{}

def native_match_cps_provider_2_live_ordinal_in_1(v_22: Bool, +v_3: U32, +v_5: U32, +v_7: U32, v_13: List<&2, BIR.DescriptorField>) -> Maybe<&2, U32>:
  match v_22:
    case True{}:
      cps_provider_2_live_ordinal_in(v_13, U32.inc(v_3), v_5, U32.inc(v_7))
    case False{}:
      cps_provider_2_live_ordinal_in(v_13, U32.inc(v_3), v_5, v_7)

def native_match_cps_provider_2_live_ordinal_in_2(v_20: Bool, +v_3: U32, +v_5: U32, +v_7: U32, v_13: List<&2, BIR.DescriptorField>, v_18: BIR.Quantity) -> Maybe<&2, U32>:
  match v_20:
    case True{}:
      native_match_cps_provider_2_live_ordinal_in_0(cps_provider_1_live_field(v_18), v_7)
    case False{}:
      native_match_cps_provider_2_live_ordinal_in_1(cps_provider_1_live_field(v_18), v_3, v_5, v_7, v_13)

def native_match_cps_provider_2_live_ordinal_in_3(+v_12: BIR.DescriptorField, +v_3: U32, +v_5: U32, +v_7: U32, v_13: List<&2, BIR.DescriptorField>) -> Maybe<&2, U32>:
  match v_12:
    case BIR.DescriptorField{v_17, v_18, v_19}:
      native_match_cps_provider_2_live_ordinal_in_2(U32.is_eq(v_3, v_5), v_3, v_5, v_7, v_13, v_18)

def native_match_cps_provider_2_live_ordinal_in_4(+v_1: List<&2, BIR.DescriptorField>, +v_3: U32, +v_5: U32, +v_7: U32) -> Maybe<&2, U32>:
  match v_1:
    case []:
      None{}
    case +v_12 <> v_13:
      native_match_cps_provider_2_live_ordinal_in_3(v_12, v_3, v_5, v_7, v_13)

def cps_provider_2_live_ordinal_in(+v_1: List<&2, BIR.DescriptorField>, +v_3: U32, +v_5: U32, +v_7: U32) -> Maybe<&2, U32>:
  native_match_cps_provider_2_live_ordinal_in_4(v_1, v_3, v_5, v_7)

def cps_provider_2_inline_slot(+v_1: List<&2, cps_provider_1_Layout>, +v_3: Nat, +v_5: Nat) -> Maybe<&2, cps_provider_1_NodeSlot>:
  match v_1:
    case []:
      None{}
    case +v_9 <> v_10:
      match v_3:
        case 0n:
          Some{cps_provider_1_NodeSlot{0, v_5, v_9}}
        case 1n+v_12:
          cps_provider_2_inline_slot(v_10, v_12, Nat.add(v_5, cps_provider_1_layout_words(v_9)))

def native_match_cps_provider_2_inline_start_0(v_5: Bool) -> Nat:
  match v_5:
    case True{}:
      1n
    case False{}:
      0n

def cps_provider_2_inline_start(+v_2: List<&2, cps_provider_1_LayArm>) -> Nat:
  native_match_cps_provider_2_inline_start_0(Nat.is_gt(List.length(&2, cps_provider_1_LayArm, v_2), 1n))

def native_match_cps_provider_2_state_array_0(v_12: cps_provider_1_Cell, +v_3: String, +v_5: String, +v_7: String) -> cps_provider_2_PathResult:
  match v_12:
    case cps_provider_1_Cell{v_17, v_18, v_19, v_20}:
      cps_provider_2_PathOk{cps_provider_2_StArray{cps_provider_2_join_text(["blk_loc(e.mem, ", v_3, ")"]), cps_provider_2_join_text(["((u32)blk_cls(", v_3, "))"]), v_20, v_17, cps_provider_2_join_text(["(term_tag(", v_3, ") == TAG_ARR)"]), "0", cps_provider_2_not_bool(v_18), v_5, v_7}}

def native_match_cps_provider_2_state_array_1(v_21: Maybe<&2, cps_provider_1_Cell>, +v_3: String, +v_5: String, +v_7: String) -> cps_provider_2_PathResult:
  match v_21:
    case None{}:
      cps_provider_2_PathFail{"the array element has no cell layout"}
    case Some{v_12}:
      native_match_cps_provider_2_state_array_0(v_12, v_3, v_5, v_7)

def cps_provider_2_state_array(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_state_array_1(cps_provider_2_cell_lgs(v_1, v_8), v_3, v_5, v_7)

def cps_provider_2_state_from_array_value(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor) -> cps_provider_2_PathResult:
  cps_provider_2_state_array(v_1, v_3, cps_provider_2_and_expr(v_5, cps_provider_2_unique_expr(v_3)), cps_provider_2_or_expr(v_7, cps_provider_2_static_expr(v_3)), v_8)

def native_match_cps_provider_2_resolve_field_0(+v_3: cps_provider_2_PathState, +v_1: cps_provider_2_World, +v_7: U32, +v_10: List<&2, cps_provider_2_PathStep>, v_15: String) -> cps_provider_2_PathResult:
  match v_3:
    case cps_provider_2_StSlot{v_22, v_23, v_24, v_25, v_26, v_27}:
      cps_provider_2_resolve_slot_field(v_1, v_15, v_7, v_22, v_23, v_24, v_25, v_26, v_27, v_10)
    case cps_provider_2_StCell{v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45, v_46}:
      cps_provider_2_resolve_cell_field(v_1, v_15, v_7, v_38, v_44, v_40, v_42, v_43, v_45, v_46, v_10)
    case cps_provider_2_StBufField{v_53, v_54, v_55, v_56, v_57}:
      cps_provider_2_resolve_buf_field(v_1, v_15, v_7, v_53, v_54, v_55, v_56, v_57, v_10)
    case cps_provider_2_StArray{v_68, v_69, v_70, v_71, v_72, v_73, v_74, v_75, v_76}:
      cps_provider_2_PathFail{"a Project on an array value needs an element leaf-cell step"}

def native_match_cps_provider_2_resolve_field_1(v_77: Maybe<&2, String>, +v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_5: U32, +v_7: U32, +v_10: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_77:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["BIR projects constructor ", U32.show(v_5), " with no layout row"])}
    case Some{v_15}:
      native_match_cps_provider_2_resolve_field_0(v_3, v_1, v_7, v_10, v_15)

def cps_provider_2_resolve_field(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_5: U32, +v_7: U32, +v_10: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_resolve_field_1(cps_provider_2_step_key(v_1, v_5), v_1, v_3, v_5, v_7, v_10)

def native_match_cps_provider_2_resolve_slot_field_0(v_41: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_41:
    case cps_provider_1_NodeSlot{v_45, v_46, v_47}:
      cps_provider_2_advance(v_1, cps_provider_2_StSlot{0n, v_47, v_11, v_13, v_15, True{}}, v_20)

def native_match_cps_provider_2_resolve_slot_field_1(v_97: Maybe<&2, cps_provider_1_NodeSlot>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_97:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the packed arm `", v_3, "` has no live field ", U32.show(v_5)])}
    case Some{v_41}:
      native_match_cps_provider_2_resolve_slot_field_0(v_41, v_1, v_11, v_13, v_15, v_20)

def native_match_cps_provider_2_resolve_slot_field_2(v_96: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>, v_29: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_96:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the projection of `", v_3, "` names an erased packed field"])}
    case Some{v_37}:
      native_match_cps_provider_2_resolve_slot_field_1(cps_provider_2_inline_slot(v_29, U32.to_nat(v_37), 0n), v_1, v_3, v_5, v_11, v_13, v_15, v_20)

def native_match_cps_provider_2_resolve_slot_field_3(v_95: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>, v_29: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_95:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the packed arm `", v_3, "` has no declared fields"])}
    case Some{v_33}:
      native_match_cps_provider_2_resolve_slot_field_2(cps_provider_2_live_ordinal_in(v_33, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1, v_3, v_5, v_11, v_13, v_15, v_20, v_29)

def native_match_cps_provider_2_resolve_slot_field_4(v_94: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_94:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the packed form has no arm `", v_3, "`"])}
    case Some{v_29}:
      native_match_cps_provider_2_resolve_slot_field_3(cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1, v_3, v_5, v_11, v_13, v_15, v_20, v_29)

def native_match_cps_provider_2_resolve_slot_field_5(+v_9: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_9:
    case cps_provider_1_LayoutData{v_24, v_25}:
      native_match_cps_provider_2_resolve_slot_field_4(cps_provider_2_arm_fields_of(v_25, v_3), v_1, v_3, v_5, v_11, v_13, v_15, v_20)
    case cps_provider_1_LayoutWord{v_50}:
      cps_provider_2_PathFail{"a raw packed word has no nested projection"}
    case cps_provider_1_LayoutBox{v_52}:
      cps_provider_2_PathFail{"a packed value cannot hold a boxed field"}

def native_match_cps_provider_2_resolve_slot_field_6(v_73: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_73:
    case cps_provider_1_NodeSlot{v_77, v_78, v_79}:
      cps_provider_2_advance(v_1, cps_provider_2_StSlot{Nat.add(v_7, v_78), v_79, v_11, v_13, v_15, False{}}, v_20)

def native_match_cps_provider_2_resolve_slot_field_7(v_101: Maybe<&2, cps_provider_1_NodeSlot>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_101:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the inline arm `", v_3, "` has no live field ", U32.show(v_5)])}
    case Some{v_73}:
      native_match_cps_provider_2_resolve_slot_field_6(v_73, v_1, v_7, v_11, v_13, v_15, v_20)

def native_match_cps_provider_2_resolve_slot_field_8(v_100: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>, v_56: List<&2, cps_provider_1_LayArm>, v_60: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_100:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the projection of `", v_3, "` names an erased field"])}
    case Some{v_68}:
      native_match_cps_provider_2_resolve_slot_field_7(cps_provider_2_inline_slot(v_60, U32.to_nat(v_68), cps_provider_2_inline_start(v_56)), v_1, v_3, v_5, v_7, v_11, v_13, v_15, v_20)

def native_match_cps_provider_2_resolve_slot_field_9(v_99: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>, v_56: List<&2, cps_provider_1_LayArm>, v_60: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_99:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the inline arm `", v_3, "` has no declared fields"])}
    case Some{v_64}:
      native_match_cps_provider_2_resolve_slot_field_8(cps_provider_2_live_ordinal_in(v_64, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1, v_3, v_5, v_7, v_11, v_13, v_15, v_20, v_56, v_60)

def native_match_cps_provider_2_resolve_slot_field_10(v_98: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>, v_56: List<&2, cps_provider_1_LayArm>) -> cps_provider_2_PathResult:
  match v_98:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the inline form has no arm `", v_3, "`"])}
    case Some{v_60}:
      native_match_cps_provider_2_resolve_slot_field_9(cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1, v_3, v_5, v_7, v_11, v_13, v_15, v_20, v_56, v_60)

def native_match_cps_provider_2_resolve_slot_field_11(+v_9: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_9:
    case cps_provider_1_LayoutData{v_55, v_56}:
      native_match_cps_provider_2_resolve_slot_field_10(cps_provider_2_arm_fields_of(v_56, v_3), v_1, v_3, v_5, v_7, v_11, v_13, v_15, v_20, v_56)
    case cps_provider_1_LayoutBox{v_82}:
      v_85 = cps_provider_2_join_text(["e.mem[", v_11, " + ", Nat.show(v_7), "]"])
      cps_provider_2_resolve_node_slot(v_1, v_3, v_5, 0n, cps_provider_2_join_text(["term_peek(e.mem, (", v_85, "))"]), cps_provider_2_and_expr(v_13, cps_provider_2_unique_expr(v_85)), cps_provider_2_or_expr(v_15, cps_provider_2_static_expr(v_85)), v_20)
    case cps_provider_1_LayoutWord{v_93}:
      cps_provider_2_PathFail{"a nested Project path continues through a raw word"}

def native_match_cps_provider_2_resolve_slot_field_12(+v_17: Bool, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: cps_provider_1_Layout, +v_11: String, +v_13: String, +v_15: String, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_17:
    case True{}:
      native_match_cps_provider_2_resolve_slot_field_5(v_9, v_1, v_3, v_5, v_11, v_13, v_15, v_20)
    case False{}:
      native_match_cps_provider_2_resolve_slot_field_11(v_9, v_1, v_3, v_5, v_7, v_11, v_13, v_15, v_20)

def cps_provider_2_resolve_slot_field(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: cps_provider_1_Layout, +v_11: String, +v_13: String, +v_15: String, +v_17: Bool, +v_20: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_resolve_slot_field_12(v_17, v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_20)

def native_match_cps_provider_2_resolve_cell_field_0(+v_9: Bool, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_11: String, +v_13: cps_provider_1_Layout, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_9:
    case True{}:
      cps_provider_2_PathFail{"a BUF array cell cannot contain a boxed field"}
    case False{}:
      cps_provider_2_resolve_slot_field(v_1, v_3, v_5, 0n, v_13, cps_provider_2_join_text([v_7, " + (", v_11, ")"]), v_17, v_19, False{}, v_22)

def native_match_cps_provider_2_resolve_cell_field_1(+v_9: Bool, +v_1: cps_provider_2_World, +v_7: String, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>, v_53: Nat, v_54: cps_provider_1_Layout) -> cps_provider_2_PathResult:
  match v_9:
    case True{}:
      cps_provider_2_advance(v_1, cps_provider_2_StBufField{v_7, cps_provider_2_join_text([v_11, " + ", Nat.show(v_53)]), v_54, v_17, v_19}, v_22)
    case False{}:
      cps_provider_2_advance(v_1, cps_provider_2_StSlot{v_53, v_54, cps_provider_2_join_text([v_7, " + (", v_11, ")"]), v_17, v_19, False{}}, v_22)

def native_match_cps_provider_2_resolve_cell_field_2(v_48: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_7: String, +v_9: Bool, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_48:
    case cps_provider_1_NodeSlot{v_52, v_53, v_54}:
      native_match_cps_provider_2_resolve_cell_field_1(v_9, v_1, v_7, v_11, v_17, v_19, v_22, v_53, v_54)

def native_match_cps_provider_2_resolve_cell_field_3(v_64: Maybe<&2, cps_provider_1_NodeSlot>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_64:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the inline cell arm `", v_3, "` has no live field ", U32.show(v_5)])}
    case Some{v_48}:
      native_match_cps_provider_2_resolve_cell_field_2(v_48, v_1, v_7, v_9, v_11, v_17, v_19, v_22)

def native_match_cps_provider_2_resolve_cell_field_4(v_63: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>, v_31: List<&2, cps_provider_1_LayArm>, v_35: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_63:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the projection of `", v_3, "` names an erased cell field"])}
    case Some{v_43}:
      native_match_cps_provider_2_resolve_cell_field_3(cps_provider_2_inline_slot(v_35, U32.to_nat(v_43), cps_provider_2_inline_start(v_31)), v_1, v_3, v_5, v_7, v_9, v_11, v_17, v_19, v_22)

def native_match_cps_provider_2_resolve_cell_field_5(v_62: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>, v_31: List<&2, cps_provider_1_LayArm>, v_35: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_62:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the inline cell arm `", v_3, "` has no declared fields"])}
    case Some{v_39}:
      native_match_cps_provider_2_resolve_cell_field_4(cps_provider_2_live_ordinal_in(v_39, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1, v_3, v_5, v_7, v_9, v_11, v_17, v_19, v_22, v_31, v_35)

def native_match_cps_provider_2_resolve_cell_field_6(v_61: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>, v_31: List<&2, cps_provider_1_LayArm>) -> cps_provider_2_PathResult:
  match v_61:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the inline cell has no arm `", v_3, "`"])}
    case Some{v_35}:
      native_match_cps_provider_2_resolve_cell_field_5(cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1, v_3, v_5, v_7, v_9, v_11, v_17, v_19, v_22, v_31, v_35)

def native_match_cps_provider_2_resolve_cell_field_7(+v_13: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_13:
    case cps_provider_1_LayoutBox{v_25}:
      native_match_cps_provider_2_resolve_cell_field_0(v_9, v_1, v_3, v_5, v_7, v_11, v_13, v_17, v_19, v_22)
    case cps_provider_1_LayoutData{v_30, v_31}:
      native_match_cps_provider_2_resolve_cell_field_6(cps_provider_2_arm_fields_of(v_31, v_3), v_1, v_3, v_5, v_7, v_9, v_11, v_17, v_19, v_22, v_31)
    case cps_provider_1_LayoutWord{v_60}:
      cps_provider_2_PathFail{"a nested Project path continues through a raw cell word"}

def cps_provider_2_resolve_cell_field(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_13: cps_provider_1_Layout, +v_15: Nat, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_resolve_cell_field_7(v_13, v_1, v_3, v_5, v_7, v_9, v_11, v_17, v_19, v_22)

def native_match_cps_provider_2_resolve_buf_field_0(v_40: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_40:
    case cps_provider_1_NodeSlot{v_44, v_45, v_46}:
      cps_provider_2_advance(v_1, cps_provider_2_StBufField{v_7, cps_provider_2_join_text([v_9, " + ", Nat.show(v_45)]), v_46, v_13, v_15}, v_18)

def native_match_cps_provider_2_resolve_buf_field_1(v_56: Maybe<&2, cps_provider_1_NodeSlot>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_56:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the BUF inline arm `", v_3, "` has no live field ", U32.show(v_5)])}
    case Some{v_40}:
      native_match_cps_provider_2_resolve_buf_field_0(v_40, v_1, v_7, v_9, v_13, v_15, v_18)

def native_match_cps_provider_2_resolve_buf_field_2(v_55: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>, v_23: List<&2, cps_provider_1_LayArm>, v_27: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_55:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the projection of `", v_3, "` names an erased BUF field"])}
    case Some{v_35}:
      native_match_cps_provider_2_resolve_buf_field_1(cps_provider_2_inline_slot(v_27, U32.to_nat(v_35), cps_provider_2_inline_start(v_23)), v_1, v_3, v_5, v_7, v_9, v_13, v_15, v_18)

def native_match_cps_provider_2_resolve_buf_field_3(v_54: Maybe<&2, List<&2, BIR.DescriptorField>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>, v_23: List<&2, cps_provider_1_LayArm>, v_27: List<&2, cps_provider_1_Layout>) -> cps_provider_2_PathResult:
  match v_54:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the BUF inline arm `", v_3, "` has no declared fields"])}
    case Some{v_31}:
      native_match_cps_provider_2_resolve_buf_field_2(cps_provider_2_live_ordinal_in(v_31, U32.from_nat(0n), v_5, U32.from_nat(0n)), v_1, v_3, v_5, v_7, v_9, v_13, v_15, v_18, v_23, v_27)

def native_match_cps_provider_2_resolve_buf_field_4(v_53: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>, v_23: List<&2, cps_provider_1_LayArm>) -> cps_provider_2_PathResult:
  match v_53:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the BUF inline form has no arm `", v_3, "`"])}
    case Some{v_27}:
      native_match_cps_provider_2_resolve_buf_field_3(cps_provider_2_arm_descriptor_fields(v_1, v_3), v_1, v_3, v_5, v_7, v_9, v_13, v_15, v_18, v_23, v_27)

def native_match_cps_provider_2_resolve_buf_field_5(+v_11: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_11:
    case cps_provider_1_LayoutData{v_22, v_23}:
      native_match_cps_provider_2_resolve_buf_field_4(cps_provider_2_arm_fields_of(v_23, v_3), v_1, v_3, v_5, v_7, v_9, v_13, v_15, v_18, v_23)
    case cps_provider_1_LayoutBox{v_50}:
      cps_provider_2_PathFail{"a BUF inline form cannot hold a boxed field"}
    case cps_provider_1_LayoutWord{v_52}:
      cps_provider_2_PathFail{"a BUF raw word has no nested projection"}

def cps_provider_2_resolve_buf_field(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_11: cps_provider_1_Layout, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_resolve_buf_field_5(v_11, v_1, v_3, v_5, v_7, v_9, v_13, v_15, v_18)

def native_match_cps_provider_2_resolve_node_slot_0(v_29: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_29:
    case cps_provider_1_NodeSlot{v_33, v_34, v_35}:
      cps_provider_2_advance(v_1, cps_provider_2_StSlot{Nat.add(v_7, v_34), v_35, v_9, v_11, v_13, False{}}, v_16)

def native_match_cps_provider_2_resolve_node_slot_1(v_36: cps_provider_1_SlotResult, +v_1: cps_provider_2_World, +v_3: String, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_36:
    case cps_provider_1_SlotErased{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["the projection of `", v_3, "` names an erased field"])}
    case cps_provider_1_SlotFailed{v_27}:
      cps_provider_2_PathFail{v_27}
    case cps_provider_1_SlotFound{v_29}:
      native_match_cps_provider_2_resolve_node_slot_0(v_29, v_1, v_7, v_9, v_11, v_13, v_16)

def native_match_cps_provider_2_resolve_node_slot_2(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_1:
    case cps_provider_2_World{v_21, v_22, v_23}:
      native_match_cps_provider_2_resolve_node_slot_1(cps_provider_1_node_slot(v_21, v_3, v_5), v_1, v_3, v_7, v_9, v_11, v_13, v_16)

def cps_provider_2_resolve_node_slot(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_resolve_node_slot_2(v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_16)

def native_match_cps_provider_2_root_array_path_0(v_14: cps_provider_2_PathResult, +v_1: cps_provider_2_World, +v_5: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_14:
    case cps_provider_2_PathFail{v_11}:
      cps_provider_2_PathFail{v_11}
    case cps_provider_2_PathOk{v_13}:
      cps_provider_2_advance(v_1, v_13, v_5)

def cps_provider_2_root_array_path(+v_1: cps_provider_2_World, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_root_array_path_0(cps_provider_2_state_from_array_value(v_1, "pbt", cps_provider_2_unique_expr("pbt"), cps_provider_2_static_expr("pbt"), v_2), v_1, v_5)

def native_match_cps_provider_2_advance_0(v_38: cps_provider_2_PathResult) -> cps_provider_2_PathResult:
  match v_38:
    case cps_provider_2_PathFail{v_18}:
      cps_provider_2_PathFail{v_18}
    case cps_provider_2_PathOk{v_20}:
      cps_provider_2_PathOk{v_20}

def native_match_cps_provider_2_advance_1(v_39: cps_provider_2_PathResult, +v_1: cps_provider_2_World, v_11: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_39:
    case cps_provider_2_PathFail{v_27}:
      cps_provider_2_PathFail{v_27}
    case cps_provider_2_PathOk{v_29}:
      cps_provider_2_advance(v_1, v_29, v_11)

def native_match_cps_provider_2_advance_2(v_40: cps_provider_2_PathResult, +v_1: cps_provider_2_World, v_11: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_40:
    case cps_provider_2_PathFail{v_35}:
      cps_provider_2_PathFail{v_35}
    case cps_provider_2_PathOk{v_37}:
      cps_provider_2_advance(v_1, v_37, v_11)

def native_match_cps_provider_2_advance_3(+v_10: cps_provider_2_PathStep, +v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, v_11: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_10:
    case cps_provider_2_PathField{v_14, v_15}:
      native_match_cps_provider_2_advance_0(cps_provider_2_resolve_field(v_1, v_3, v_14, v_15, v_11))
    case cps_provider_2_PathHalf{v_23, v_24}:
      native_match_cps_provider_2_advance_1(cps_provider_2_half_state(v_1, v_3, v_23, v_24, v_11), v_1, v_11)
    case cps_provider_2_PathLeafCell{v_32}:
      native_match_cps_provider_2_advance_2(cps_provider_2_leaf_state(v_1, v_3, v_32, v_11), v_1, v_11)

def native_match_cps_provider_2_advance_4(+v_6: List<&2, cps_provider_2_PathStep>, +v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_PathResult:
  match v_6:
    case []:
      cps_provider_2_PathOk{v_3}
    case +v_10 <> v_11:
      native_match_cps_provider_2_advance_3(v_10, v_1, v_3, v_11)

def cps_provider_2_advance(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_6: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_advance_4(v_6, v_1, v_3)

def cps_provider_2_array_from_state(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_4: BIR.Descriptor) -> cps_provider_2_PathResult:
  match v_3:
    case cps_provider_2_StArray{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23}:
      cps_provider_2_PathOk{v_3}
    case cps_provider_2_StSlot{v_30, v_31, v_32, v_33, v_34, v_35}:
      match v_31:
        case cps_provider_1_LayoutBox{v_37}:
          v_40 = cps_provider_2_join_text(["e.mem[", v_32, " + ", Nat.show(v_30), "]"])
          cps_provider_2_state_from_array_value(v_1, v_40, v_33, v_34, v_4)
        case _:
          cps_provider_2_PathFail{"an array half or leaf needs a boxed array value"}
    case cps_provider_2_StCell{v_53, v_54, v_55, v_56, v_57, v_58, v_59, v_60, v_61}:
      match v_57:
        case cps_provider_1_LayoutBox{v_63}:
          v_66 = cps_provider_2_join_text(["blk_read(e.mem, ", v_54, ", ", v_53, ", (u32)(", v_55, "))"])
          cps_provider_2_state_from_array_value(v_1, v_66, v_60, v_61, v_4)
        case _:
          cps_provider_2_PathFail{"an array half or leaf needs a boxed array element"}
    case cps_provider_2_StBufField{v_75, v_76, v_77, v_78, v_79}:
      cps_provider_2_PathFail{"an array half or leaf needs a boxed array element"}

def native_match_cps_provider_2_half_state_0(v_15: cps_provider_2_PathState, +v_5: Bool) -> cps_provider_2_PathResult:
  match v_15:
    case cps_provider_2_StArray{v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33}:
      v_38 = cps_provider_2_join_text(["(u64)((", v_30, ") + ", Bool.pick(String, v_5, "0", cps_provider_2_join_text(["(1ull << ((", v_26, ") - 1))"])), ")"])
      v_41 = cps_provider_2_join_text(["((", v_26, ") - 1)"])
      cps_provider_2_PathOk{cps_provider_2_StArray{v_25, v_41, v_27, v_28, v_29, v_38, v_31, v_32, v_33}}
    case _:
      cps_provider_2_PathFail{"not an array state"}

def native_match_cps_provider_2_half_state_1(v_44: cps_provider_2_PathResult, +v_5: Bool) -> cps_provider_2_PathResult:
  match v_44:
    case cps_provider_2_PathFail{v_13}:
      cps_provider_2_PathFail{v_13}
    case cps_provider_2_PathOk{v_15}:
      native_match_cps_provider_2_half_state_0(v_15, v_5)

def cps_provider_2_half_state(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_5: Bool, +v_6: BIR.Descriptor, +v_9: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_half_state_1(cps_provider_2_array_from_state(v_1, v_3, v_6), v_5)

def native_match_cps_provider_2_leaf_state_0(v_13: cps_provider_2_PathState) -> cps_provider_2_PathResult:
  match v_13:
    case cps_provider_2_StArray{v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31}:
      cps_provider_2_PathOk{cps_provider_2_StCell{v_23, v_27, v_28, v_24, v_26, v_25, v_29, v_30, v_31}}
    case _:
      cps_provider_2_PathFail{"not an array state"}

def native_match_cps_provider_2_leaf_state_1(v_34: cps_provider_2_PathResult) -> cps_provider_2_PathResult:
  match v_34:
    case cps_provider_2_PathFail{v_11}:
      cps_provider_2_PathFail{v_11}
    case cps_provider_2_PathOk{v_13}:
      native_match_cps_provider_2_leaf_state_0(v_13)

def cps_provider_2_leaf_state(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_leaf_state_1(cps_provider_2_array_from_state(v_1, v_3, v_4))

def native_match_cps_provider_2_resolve_path_0(v_37: cps_provider_1_NodeSlot, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_37:
    case cps_provider_1_NodeSlot{v_41, v_42, v_43}:
      cps_provider_2_advance(v_1, cps_provider_2_StSlot{0n, v_43, "pbn", "0", "1", True{}}, v_9)

def native_match_cps_provider_2_resolve_path_1(v_59: cps_provider_1_SlotResult, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_59:
    case cps_provider_1_SlotFound{v_37}:
      native_match_cps_provider_2_resolve_path_0(v_37, v_1, v_9)
    case cps_provider_1_SlotErased{}:
      cps_provider_2_PathFail{"a packed projection names an erased field"}
    case cps_provider_1_SlotFailed{v_46}:
      cps_provider_2_PathFail{v_46}

def native_match_cps_provider_2_resolve_path_2(v_34: Bool, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>, v_13: U32, v_17: String, v_21: cps_provider_1_Context) -> cps_provider_2_PathResult:
  match v_34:
    case True{}:
      native_match_cps_provider_2_resolve_path_1(cps_provider_1_node_slot(v_21, v_17, v_13), v_1, v_9)
    case False{}:
      cps_provider_2_resolve_node_slot(v_1, v_17, v_13, 0n, "pbn", cps_provider_2_unique_expr("pbt"), cps_provider_2_static_expr("pbt"), v_9)

def native_match_cps_provider_2_resolve_path_3(v_28: cps_provider_1_Node, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>, v_13: U32, v_17: String, v_21: cps_provider_1_Context) -> cps_provider_2_PathResult:
  match v_28:
    case cps_provider_1_Node{v_32, v_33, v_34}:
      native_match_cps_provider_2_resolve_path_2(v_34, v_1, v_9, v_13, v_17, v_21)

def native_match_cps_provider_2_resolve_path_4(v_58: cps_provider_1_NodeResult, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>, v_13: U32, v_17: String, v_21: cps_provider_1_Context) -> cps_provider_2_PathResult:
  match v_58:
    case cps_provider_1_NodeFailed{v_26}:
      cps_provider_2_PathFail{v_26}
    case cps_provider_1_NodeFound{v_28}:
      native_match_cps_provider_2_resolve_path_3(v_28, v_1, v_9, v_13, v_17, v_21)

def native_match_cps_provider_2_resolve_path_5(+v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>, v_13: U32, v_17: String) -> cps_provider_2_PathResult:
  match v_1:
    case cps_provider_2_World{v_21, v_22, v_23}:
      native_match_cps_provider_2_resolve_path_4(cps_provider_1_node_layout(v_21, v_17), v_1, v_9, v_13, v_17, v_21)

def native_match_cps_provider_2_resolve_path_6(v_57: Maybe<&2, String>, +v_1: cps_provider_2_World, v_9: List<&2, cps_provider_2_PathStep>, v_12: U32, v_13: U32) -> cps_provider_2_PathResult:
  match v_57:
    case None{}:
      cps_provider_2_PathFail{cps_provider_2_join_text(["BIR projects constructor ", U32.show(v_12), " with no layout row"])}
    case Some{v_17}:
      native_match_cps_provider_2_resolve_path_5(v_1, v_9, v_13, v_17)

def native_match_cps_provider_2_resolve_path_7(+v_8: cps_provider_2_PathStep, +v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_2_PathStep>, v_9: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  match v_8:
    case cps_provider_2_PathField{v_12, v_13}:
      native_match_cps_provider_2_resolve_path_6(cps_provider_2_step_key(v_1, v_12), v_1, v_9, v_12, v_13)
    case cps_provider_2_PathHalf{v_52, v_53}:
      cps_provider_2_root_array_path(v_1, v_53, v_4)
    case cps_provider_2_PathLeafCell{v_56}:
      cps_provider_2_root_array_path(v_1, v_56, v_4)

def native_match_cps_provider_2_resolve_path_8(+v_4: List<&2, cps_provider_2_PathStep>, +v_1: cps_provider_2_World) -> cps_provider_2_PathResult:
  match v_4:
    case []:
      cps_provider_2_PathFail{"a Project path is empty"}
    case +v_8 <> v_9:
      native_match_cps_provider_2_resolve_path_7(v_8, v_1, v_4, v_9)

def cps_provider_2_resolve_path(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_2_PathStep>) -> cps_provider_2_PathResult:
  native_match_cps_provider_2_resolve_path_8(v_4, v_1)

def cps_provider_2_path_prelude(+v_1: String) -> String:
  cps_provider_2_join_text(["Term pbt = (", v_1, "); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; "])

def cps_provider_2_path_expr(+v_1: String, +v_3: String) -> String:
  cps_provider_2_join_text(["({\n", cps_provider_2_path_prelude(v_1), v_3, "pbr;\n})"])

def native_match_cps_provider_2_keep_copy_0(+v_29: cps_provider_1_LayArm, +v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_13: String) -> String:
  match v_29:
    case cps_provider_1_LayArm{v_32, v_33}:
      cps_provider_2_keep_copy_fields(v_1, v_3, v_5, v_7, v_9, v_33, v_13)

def native_match_cps_provider_2_keep_copy_1(v_27: List<&2, cps_provider_1_LayArm>, +v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_13: String) -> String:
  match v_27:
    case []:
      ""
    case [+v_29]:
      native_match_cps_provider_2_keep_copy_0(v_29, v_1, v_3, v_5, v_7, v_9, v_13)
    case _:
      cps_provider_2_join_text([v_13, "pbbuf[", Nat.show(Nat.sub(v_9, v_7)), "] = e.mem[", v_1, " + ", Nat.show(v_9), "];\n", v_13, "switch ((u32)e.mem[", v_1, " + ", Nat.show(v_9), "]) {\n", cps_provider_2_keep_copy_cases(v_1, v_3, v_5, v_7, Nat.add(v_9, 1n), v_27, v_13, 0n), v_13, "}\n"])

def native_match_cps_provider_2_keep_copy_2(+v_11: cps_provider_1_Layout, +v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_13: String) -> String:
  match v_11:
    case cps_provider_1_LayoutWord{v_16}:
      cps_provider_2_join_text([v_13, "pbbuf[", Nat.show(Nat.sub(v_9, v_7)), "] = e.mem[", v_1, " + ", Nat.show(v_9), "];\n"])
    case cps_provider_1_LayoutBox{v_19}:
      v_22 = cps_provider_2_join_text(["e.mem[", v_1, " + ", Nat.show(v_9), "]"])
      cps_provider_2_join_text([v_13, "{ Term pbb = term_keep(e, ", v_22, ", 1); if (pbb != ", v_22, ") { if (", v_5, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_3, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { ", v_22, " = pbb; } } pbbuf[", Nat.show(Nat.sub(v_9, v_7)), "] = (u64)pbb; }\n"])
    case cps_provider_1_LayoutData{v_26, v_27}:
      native_match_cps_provider_2_keep_copy_1(v_27, v_1, v_3, v_5, v_7, v_9, v_13)

def cps_provider_2_keep_copy(+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_11: cps_provider_1_Layout, +v_13: String) -> String:
  native_match_cps_provider_2_keep_copy_2(v_11, v_1, v_3, v_5, v_7, v_9, v_13)

def cps_provider_2_keep_copy_fields(+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_11: List<&2, cps_provider_1_Layout>, +v_13: String) -> String:
  match v_11:
    case []:
      ""
    case +v_17 <> v_18:
      cps_provider_2_join_text([cps_provider_2_keep_copy(v_1, v_3, v_5, v_7, v_9, v_17, v_13), cps_provider_2_keep_copy_fields(v_1, v_3, v_5, v_7, Nat.add(v_9, cps_provider_1_layout_words(v_17)), v_18, v_13)])

def cps_provider_2_keep_copy_cases(+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_11: List<&2, cps_provider_1_LayArm>, +v_13: String, +v_15: Nat) -> String:
  match v_11:
    case []:
      cps_provider_2_join_text([v_13, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"])
    case +v_20 <> v_21:
      match v_20:
        case cps_provider_1_LayArm{v_24, v_25}:
          cps_provider_2_join_text([v_13, "case ", Nat.show(v_15), ": {\n", cps_provider_2_keep_copy_fields(v_1, v_3, v_5, v_7, v_9, v_25, cps_provider_2_join_text([v_13, "  "])), v_13, "} break;\n", cps_provider_2_keep_copy_cases(v_1, v_3, v_5, v_7, v_9, v_21, v_13, Nat.add(v_15, 1n))])

def native_match_cps_provider_2_move_copy_0(+v_22: cps_provider_1_LayArm, +v_1: String, +v_3: Nat, +v_5: Nat, +v_9: String) -> String:
  match v_22:
    case cps_provider_1_LayArm{v_25, v_26}:
      cps_provider_2_move_copy_fields(v_1, v_3, v_5, v_26, v_9)

def native_match_cps_provider_2_move_copy_1(v_20: List<&2, cps_provider_1_LayArm>, +v_1: String, +v_3: Nat, +v_5: Nat, +v_9: String) -> String:
  match v_20:
    case []:
      ""
    case [+v_22]:
      native_match_cps_provider_2_move_copy_0(v_22, v_1, v_3, v_5, v_9)
    case _:
      cps_provider_2_join_text([v_9, "pbbuf[", Nat.show(Nat.sub(v_5, v_3)), "] = e.mem[", v_1, " + ", Nat.show(v_5), "];\n", v_9, "switch ((u32)e.mem[", v_1, " + ", Nat.show(v_5), "]) {\n", cps_provider_2_move_copy_cases(v_1, v_3, Nat.add(v_5, 1n), v_20, v_9, 0n), v_9, "}\n"])

def native_match_cps_provider_2_move_copy_2(+v_7: cps_provider_1_Layout, +v_1: String, +v_3: Nat, +v_5: Nat, +v_9: String) -> String:
  match v_7:
    case cps_provider_1_LayoutWord{v_12}:
      cps_provider_2_join_text([v_9, "pbbuf[", Nat.show(Nat.sub(v_5, v_3)), "] = e.mem[", v_1, " + ", Nat.show(v_5), "];\n"])
    case cps_provider_1_LayoutBox{v_15}:
      cps_provider_2_join_text([v_9, "pbbuf[", Nat.show(Nat.sub(v_5, v_3)), "] = e.mem[", v_1, " + ", Nat.show(v_5), "]; e.mem[", v_1, " + ", Nat.show(v_5), "] = 0;\n"])
    case cps_provider_1_LayoutData{v_19, v_20}:
      native_match_cps_provider_2_move_copy_1(v_20, v_1, v_3, v_5, v_9)

def cps_provider_2_move_copy(+v_1: String, +v_3: Nat, +v_5: Nat, +v_7: cps_provider_1_Layout, +v_9: String) -> String:
  native_match_cps_provider_2_move_copy_2(v_7, v_1, v_3, v_5, v_9)

def cps_provider_2_move_copy_fields(+v_1: String, +v_3: Nat, +v_5: Nat, +v_7: List<&2, cps_provider_1_Layout>, +v_9: String) -> String:
  match v_7:
    case []:
      ""
    case +v_13 <> v_14:
      cps_provider_2_join_text([cps_provider_2_move_copy(v_1, v_3, v_5, v_13, v_9), cps_provider_2_move_copy_fields(v_1, v_3, Nat.add(v_5, cps_provider_1_layout_words(v_13)), v_14, v_9)])

def cps_provider_2_move_copy_cases(+v_1: String, +v_3: Nat, +v_5: Nat, +v_7: List<&2, cps_provider_1_LayArm>, +v_9: String, +v_11: Nat) -> String:
  match v_7:
    case []:
      cps_provider_2_join_text([v_9, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"])
    case +v_16 <> v_17:
      match v_16:
        case cps_provider_1_LayArm{v_20, v_21}:
          cps_provider_2_join_text([v_9, "case ", Nat.show(v_11), ": {\n", cps_provider_2_move_copy_fields(v_1, v_3, v_5, v_21, cps_provider_2_join_text([v_9, "  "])), v_9, "} break;\n", cps_provider_2_move_copy_cases(v_1, v_3, v_5, v_17, v_9, Nat.add(v_11, 1n))])

def native_match_cps_provider_2_raw_word_expr_0(+v_5: cps_provider_1_CWord, v_9: String) -> String:
  match v_5:
    case cps_provider_1_CWord32{}:
      cps_provider_2_join_text(["((u64)(u32)(", v_9, "))"])
    case _:
      v_9

def cps_provider_2_raw_word_expr(+v_1: String, +v_3: Nat, +v_5: cps_provider_1_CWord) -> String:
  v_9 = cps_provider_2_join_text(["e.mem[", v_1, " + ", Nat.show(v_3), "]"])
  native_match_cps_provider_2_raw_word_expr_0(v_5, v_9)

def native_match_cps_provider_2_packed_form_body_0(v_20: cps_provider_2_Part) -> cps_provider_2_Part:
  match v_20:
    case cps_provider_2_PartFail{v_22}:
      cps_provider_2_PartFail{v_22}
    case cps_provider_2_PartOk{v_24}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["{ Term pbl = 0; ", v_24, "; pbr = pbl; }\n"])}

def native_match_cps_provider_2_packed_form_body_1(+v_13: cps_provider_1_CWord, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String) -> cps_provider_2_Part:
  match v_13:
    case cps_provider_1_CWord32{}:
      v_16 = cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcOne{v_5}, "pbl", "pblc")
      v_20 = cps_provider_2_part_of(cps_provider_2_run_jobs(v_16, v_1, []), "pbl")
      native_match_cps_provider_2_packed_form_body_0(v_20)
    case _:
      cps_provider_2_PartFail{"an inline form with a boxed or wider field has no nonallocating canonical Term read; use a typed consumer"}

def native_match_cps_provider_2_packed_form_body_2(v_9: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String) -> cps_provider_2_Part:
  match v_9:
    case []:
      cps_provider_2_zero_value_body(v_1, v_3)
    case [+v_13]:
      native_match_cps_provider_2_packed_form_body_1(v_13, v_1, v_3, v_5)
    case _:
      cps_provider_2_PartFail{"a multiword inline form has no nonallocating canonical Term read; use a typed consumer"}

def native_match_cps_provider_2_packed_form_body_3(+v_3: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_5: String) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_1_LayoutData{v_9, v_10}:
      native_match_cps_provider_2_packed_form_body_2(v_9, v_1, v_3, v_5)
    case _:
      cps_provider_2_PartFail{"a packed form read needs a data layout"}

def cps_provider_2_packed_form_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String) -> cps_provider_2_Part:
  native_match_cps_provider_2_packed_form_body_3(v_3, v_1, v_5)

def native_match_cps_provider_2_read_body_0(v_18: cps_provider_1_CWord) -> cps_provider_2_Part:
  match v_18:
    case cps_provider_1_CWord32{}:
      cps_provider_2_PartOk{"pbr = ((u64)(u32)pbn);\n"}
    case _:
      cps_provider_2_PartOk{"pbr = pbn;\n"}

def native_match_cps_provider_2_read_body_1(v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_1_LayoutWord{v_18}:
      native_match_cps_provider_2_read_body_0(v_18)
    case cps_provider_1_LayoutData{v_23, v_24}:
      cps_provider_2_packed_data_value(v_1, v_12)
    case cps_provider_1_LayoutBox{v_27}:
      cps_provider_2_PartFail{"a packed value has no boxed field"}

def native_match_cps_provider_2_read_body_2(v_37: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_World, v_11: Nat, v_12: cps_provider_1_Layout, v_13: String) -> cps_provider_2_Part:
  match v_37:
    case []:
      cps_provider_2_packed_form_body(v_1, v_12, "0")
    case +v_42 <> v_43:
      cps_provider_2_packed_form_body(v_1, v_12, cps_provider_2_raw_word_expr(v_13, v_11, v_42))

def native_match_cps_provider_2_read_body_3(v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World, v_11: Nat, v_13: String) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_1_LayoutWord{v_29}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ", cps_provider_2_raw_word_expr(v_13, v_11, v_29), ";\n"])}
    case cps_provider_1_LayoutBox{v_33}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = e.mem[", v_13, " + ", Nat.show(v_11), "];\n"])}
    case cps_provider_1_LayoutData{v_37, v_38}:
      native_match_cps_provider_2_read_body_2(v_37, v_1, v_11, v_12, v_13)

def native_match_cps_provider_2_read_body_4(v_16: Bool, +v_1: cps_provider_2_World, v_11: Nat, v_12: cps_provider_1_Layout, v_13: String) -> cps_provider_2_Part:
  match v_16:
    case True{}:
      native_match_cps_provider_2_read_body_1(v_12, v_1)
    case False{}:
      native_match_cps_provider_2_read_body_3(v_12, v_1, v_11, v_13)

def native_match_cps_provider_2_read_body_5(v_84: cps_provider_1_CWord, v_74: String, v_75: String, v_76: String) -> cps_provider_2_Part:
  match v_84:
    case cps_provider_1_CWord32{}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "))));\n"])}
    case _:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = (u64)(blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, ")));\n"])}

def native_match_cps_provider_2_read_body_6(v_80: Bool, v_74: String, v_75: String, v_76: String) -> cps_provider_2_Part:
  match v_80:
    case True{}:
      cps_provider_2_PartFail{"a BUF array cell cannot contain a boxed field"}
    case False{}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "));\n"])}

def native_match_cps_provider_2_read_body_7(v_78: cps_provider_1_Layout, +v_1: cps_provider_2_World, v_74: String, v_75: String, v_76: String, v_80: Bool) -> cps_provider_2_Part:
  match v_78:
    case cps_provider_1_LayoutWord{v_84}:
      native_match_cps_provider_2_read_body_5(v_84, v_74, v_75, v_76)
    case cps_provider_1_LayoutBox{v_90}:
      native_match_cps_provider_2_read_body_6(v_80, v_74, v_75, v_76)
    case cps_provider_1_LayoutData{v_94, v_95}:
      cps_provider_2_packed_form_body(v_1, v_78, cps_provider_2_join_text(["blk_read(e.mem, ", v_75, ", ", v_74, ", (u32)(", v_76, "))"]))

def native_match_cps_provider_2_read_body_8(v_109: cps_provider_1_CWord, v_103: String, v_104: String) -> cps_provider_2_Part:
  match v_109:
    case cps_provider_1_CWord32{}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ((u64)(u32)blk_read(e.mem, false, ", v_103, ", (u32)(", v_104, ")));\n"])}
    case _:
      cps_provider_2_PartFail{"a BUF raw field is not one w32 cell"}

def native_match_cps_provider_2_read_body_9(v_105: cps_provider_1_Layout, +v_1: cps_provider_2_World, v_103: String, v_104: String) -> cps_provider_2_Part:
  match v_105:
    case cps_provider_1_LayoutWord{v_109}:
      native_match_cps_provider_2_read_body_8(v_109, v_103, v_104)
    case cps_provider_1_LayoutData{v_115, v_116}:
      cps_provider_2_packed_form_body(v_1, v_105, cps_provider_2_join_text(["blk_read(e.mem, false, ", v_103, ", (u32)(", v_104, "))"]))
    case cps_provider_1_LayoutBox{v_120}:
      cps_provider_2_PartFail{"a BUF inline form cannot hold a box"}

def native_match_cps_provider_2_read_body_10(+v_3: cps_provider_2_PathState, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StSlot{v_11, v_12, v_13, v_14, v_15, v_16}:
      native_match_cps_provider_2_read_body_4(v_16, v_1, v_11, v_12, v_13)
    case cps_provider_2_StArray{v_55, v_56, v_57, v_58, v_59, v_60, v_61, v_62, v_63}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["if (", v_59, ") { pbr = term_blk(true, (u32)(", v_56, "), (u64)((u64)(", v_55, ") + (u64)(", v_60, "))); } else { u64 pboff = (u64)(", v_60, "); if ((pboff & 1ull) != 0ull) { (void)err_fail(\"a mid-block BUF cell has no Term view; a consumer must read it through blk_read\"); } pbr = term_blk(false, (u32)(", v_56, "), (u64)((u64)(", v_55, ") + (pboff >> 1))); }\n"])}
    case cps_provider_2_StCell{v_74, v_75, v_76, v_77, v_78, v_79, v_80, v_81, v_82}:
      native_match_cps_provider_2_read_body_7(v_78, v_1, v_74, v_75, v_76, v_80)
    case cps_provider_2_StBufField{v_103, v_104, v_105, v_106, v_107}:
      native_match_cps_provider_2_read_body_9(v_105, v_1, v_103, v_104)

def cps_provider_2_read_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_Part:
  native_match_cps_provider_2_read_body_10(v_3, v_1)

def native_match_cps_provider_2_tag_single_0(+v_6: Maybe<&2, U32>, +v_8: String, v_13: U32) -> cps_provider_2_Part:
  match v_6:
    case None{}:
      cps_provider_2_PartOk{cps_provider_2_join_text([v_8, " = ", U32.show(v_13), "u;\n"])}
    case Some{v_16}:
      cps_provider_2_PartOk{cps_provider_2_join_text([v_8, " = (", U32.show(v_13), "u == ", U32.show(v_16), "u);\n"])}

def native_match_cps_provider_2_tag_single_1(v_17: Maybe<&2, U32>, +v_3: String, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_17:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the arm `", v_3, "` has no canonical CID"])}
    case Some{v_13}:
      native_match_cps_provider_2_tag_single_0(v_6, v_8, v_13)

def cps_provider_2_tag_single(+v_1: cps_provider_2_World, +v_3: String, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  native_match_cps_provider_2_tag_single_1(cps_provider_2_cid_of(v_3, v_1), v_3, v_6, v_8)

def native_match_cps_provider_2_tag_multi_0(v_32: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String, v_23: List<&2, cps_provider_1_LayArm>, v_26: String) -> cps_provider_2_Part:
  match v_32:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the arm `", v_26, "` has no canonical CID"])}
    case Some{v_31}:
      cps_provider_2_tag_multi(v_1, v_3, v_5, v_23, v_11, Nat.add(v_13, 1n), cps_provider_2_tag_case_line(v_15, v_13, v_31, v_11, v_17), v_17)

def native_match_cps_provider_2_tag_multi_1(+v_22: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String, v_23: List<&2, cps_provider_1_LayArm>) -> cps_provider_2_Part:
  match v_22:
    case cps_provider_1_LayArm{v_26, v_27}:
      native_match_cps_provider_2_tag_multi_0(cps_provider_2_cid_of(v_26, v_1), v_1, v_3, v_5, v_11, v_13, v_15, v_17, v_23, v_26)

def native_match_cps_provider_2_tag_multi_2(+v_8: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> cps_provider_2_Part:
  match v_8:
    case []:
      cps_provider_2_PartOk{cps_provider_2_join_text(["switch ((u32)e.mem[", v_3, " + ", Nat.show(v_5), "]) {\n", v_15, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"])}
    case +v_22 <> v_23:
      native_match_cps_provider_2_tag_multi_1(v_22, v_1, v_3, v_5, v_11, v_13, v_15, v_17, v_23)

def cps_provider_2_tag_multi(+v_1: cps_provider_2_World, +v_3: String, +v_5: Nat, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> cps_provider_2_Part:
  native_match_cps_provider_2_tag_multi_2(v_8, v_1, v_3, v_5, v_11, v_13, v_15, v_17)

def cps_provider_2_tag_case_line(+v_1: String, +v_3: Nat, +v_5: U32, +v_8: Maybe<&2, U32>, +v_10: String) -> String:
  match v_8:
    case None{}:
      cps_provider_2_join_text([v_1, "case ", Nat.show(v_3), ": ", v_10, " = ", U32.show(v_5), "u; break;\n"])
    case Some{v_14}:
      cps_provider_2_join_text([v_1, "case ", Nat.show(v_3), ": ", v_10, " = (", U32.show(v_5), "u == ", U32.show(v_14), "u); break;\n"])

def cps_provider_2_tag_multi_packed(+v_1: cps_provider_2_World, +v_3: List<&2, cps_provider_1_LayArm>, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  cps_provider_2_tag_multi_packed_go(v_1, v_3, v_6, 0n, "", v_8)

def native_match_cps_provider_2_tag_multi_packed_go_0(v_28: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String, v_19: List<&2, cps_provider_1_LayArm>, v_22: String) -> cps_provider_2_Part:
  match v_28:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the arm `", v_22, "` has no canonical CID"])}
    case Some{v_27}:
      cps_provider_2_tag_multi_packed_go(v_1, v_19, v_7, Nat.add(v_9, 1n), cps_provider_2_tag_case_line(v_11, v_9, v_27, v_7, v_13), v_13)

def native_match_cps_provider_2_tag_multi_packed_go_1(+v_18: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String, v_19: List<&2, cps_provider_1_LayArm>) -> cps_provider_2_Part:
  match v_18:
    case cps_provider_1_LayArm{v_22, v_23}:
      native_match_cps_provider_2_tag_multi_packed_go_0(cps_provider_2_cid_of(v_22, v_1), v_1, v_7, v_9, v_11, v_13, v_19, v_22)

def native_match_cps_provider_2_tag_multi_packed_go_2(+v_4: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String) -> cps_provider_2_Part:
  match v_4:
    case []:
      cps_provider_2_PartOk{cps_provider_2_join_text(["switch ((u32)pbn) {\n", v_11, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"])}
    case +v_18 <> v_19:
      native_match_cps_provider_2_tag_multi_packed_go_1(v_18, v_1, v_7, v_9, v_11, v_13, v_19)

def cps_provider_2_tag_multi_packed_go(+v_1: cps_provider_2_World, +v_4: List<&2, cps_provider_1_LayArm>, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String) -> cps_provider_2_Part:
  native_match_cps_provider_2_tag_multi_packed_go_2(v_4, v_1, v_7, v_9, v_11, v_13)

def cps_provider_2_tag_multi_buf(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_7: List<&2, cps_provider_1_LayArm>, +v_10: Maybe<&2, U32>, +v_12: String) -> cps_provider_2_Part:
  cps_provider_2_tag_multi_buf_go(v_1, v_3, v_5, v_7, v_10, 0n, "", v_12)

def native_match_cps_provider_2_tag_multi_buf_go_0(v_32: Maybe<&2, U32>, +v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String, v_23: List<&2, cps_provider_1_LayArm>, v_26: String) -> cps_provider_2_Part:
  match v_32:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the arm `", v_26, "` has no canonical CID"])}
    case Some{v_31}:
      cps_provider_2_tag_multi_buf_go(v_1, v_3, v_5, v_23, v_11, Nat.add(v_13, 1n), cps_provider_2_tag_case_line(v_15, v_13, v_31, v_11, v_17), v_17)

def native_match_cps_provider_2_tag_multi_buf_go_1(+v_22: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String, v_23: List<&2, cps_provider_1_LayArm>) -> cps_provider_2_Part:
  match v_22:
    case cps_provider_1_LayArm{v_26, v_27}:
      native_match_cps_provider_2_tag_multi_buf_go_0(cps_provider_2_cid_of(v_26, v_1), v_1, v_3, v_5, v_11, v_13, v_15, v_17, v_23, v_26)

def native_match_cps_provider_2_tag_multi_buf_go_2(+v_8: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> cps_provider_2_Part:
  match v_8:
    case []:
      cps_provider_2_PartOk{cps_provider_2_join_text(["switch ((u32)blk_read(e.mem, false, ", v_3, ", (u32)(", v_5, "))) {\n", v_15, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"])}
    case +v_22 <> v_23:
      native_match_cps_provider_2_tag_multi_buf_go_1(v_22, v_1, v_3, v_5, v_11, v_13, v_15, v_17, v_23)

def cps_provider_2_tag_multi_buf_go(+v_1: cps_provider_2_World, +v_3: String, +v_5: String, +v_8: List<&2, cps_provider_1_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String) -> cps_provider_2_Part:
  native_match_cps_provider_2_tag_multi_buf_go_2(v_8, v_1, v_3, v_5, v_11, v_13, v_15, v_17)

def native_match_cps_provider_2_tag_body_0(+v_27: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_27:
    case cps_provider_1_LayArm{v_30, v_31}:
      cps_provider_2_tag_single(v_1, v_30, v_6, v_8)

def native_match_cps_provider_2_tag_body_1(v_25: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_25:
    case [+v_27]:
      native_match_cps_provider_2_tag_body_0(v_27, v_1, v_6, v_8)
    case _:
      cps_provider_2_tag_multi_packed(v_1, v_25, v_6, v_8)

def native_match_cps_provider_2_tag_body_2(v_17: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_17:
    case cps_provider_1_LayoutData{v_24, v_25}:
      native_match_cps_provider_2_tag_body_1(v_25, v_1, v_6, v_8)
    case _:
      cps_provider_2_PartFail{"a packed word is not a constructor tag"}

def native_match_cps_provider_2_tag_body_3(+v_43: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_43:
    case cps_provider_1_LayArm{v_46, v_47}:
      cps_provider_2_tag_single(v_1, v_46, v_6, v_8)

def native_match_cps_provider_2_tag_body_4(v_41: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_16: Nat, v_18: String) -> cps_provider_2_Part:
  match v_41:
    case []:
      cps_provider_2_PartFail{"a data layout has no arms"}
    case [+v_43]:
      native_match_cps_provider_2_tag_body_3(v_43, v_1, v_6, v_8)
    case _:
      cps_provider_2_tag_multi(v_1, v_18, v_16, v_41, v_6, 0n, "", v_8)

def native_match_cps_provider_2_tag_body_5(+v_6: Maybe<&2, U32>, +v_8: String, v_56: String) -> cps_provider_2_Part:
  match v_6:
    case None{}:
      cps_provider_2_PartOk{cps_provider_2_join_text([v_8, " = term_aux(", v_56, ");\n"])}
    case Some{v_59}:
      cps_provider_2_PartOk{cps_provider_2_join_text([v_8, " = (term_aux(", v_56, ") == ", U32.show(v_59), "u);\n"])}

def native_match_cps_provider_2_tag_body_6(v_17: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_16: Nat, v_18: String) -> cps_provider_2_Part:
  match v_17:
    case cps_provider_1_LayoutData{v_40, v_41}:
      native_match_cps_provider_2_tag_body_4(v_41, v_1, v_6, v_8, v_16, v_18)
    case cps_provider_1_LayoutBox{v_53}:
      v_56 = cps_provider_2_join_text(["e.mem[", v_18, " + ", Nat.show(v_16), "]"])
      native_match_cps_provider_2_tag_body_5(v_6, v_8, v_56)
    case cps_provider_1_LayoutWord{v_62}:
      cps_provider_2_PartFail{"a tag test needs a data field"}

def native_match_cps_provider_2_tag_body_7(v_21: Bool, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_16: Nat, v_17: cps_provider_1_Layout, v_18: String) -> cps_provider_2_Part:
  match v_21:
    case True{}:
      native_match_cps_provider_2_tag_body_2(v_17, v_1, v_6, v_8)
    case False{}:
      native_match_cps_provider_2_tag_body_6(v_17, v_1, v_6, v_8, v_16, v_18)

def native_match_cps_provider_2_tag_body_8(+v_86: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_86:
    case cps_provider_1_LayArm{v_89, v_90}:
      cps_provider_2_tag_single(v_1, v_89, v_6, v_8)

def native_match_cps_provider_2_tag_body_9(v_78: Bool, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_72: String, v_74: String, v_84: List<&2, cps_provider_1_LayArm>) -> cps_provider_2_Part:
  match v_78:
    case True{}:
      cps_provider_2_tag_multi_buf(v_1, v_72, v_74, v_84, v_6, v_8)
    case False{}:
      cps_provider_2_tag_multi(v_1, cps_provider_2_join_text([v_72, " + (", v_74, ")"]), 0n, v_84, v_6, 0n, "", v_8)

def native_match_cps_provider_2_tag_body_10(v_84: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_72: String, v_74: String, v_78: Bool) -> cps_provider_2_Part:
  match v_84:
    case []:
      cps_provider_2_PartFail{"a data layout has no arms"}
    case [+v_86]:
      native_match_cps_provider_2_tag_body_8(v_86, v_1, v_6, v_8)
    case _:
      native_match_cps_provider_2_tag_body_9(v_78, v_1, v_6, v_8, v_72, v_74, v_84)

def native_match_cps_provider_2_tag_body_11(+v_6: Maybe<&2, U32>, +v_8: String, v_101: String) -> cps_provider_2_Part:
  match v_6:
    case None{}:
      cps_provider_2_PartOk{cps_provider_2_join_text([v_8, " = term_aux(", v_101, ");\n"])}
    case Some{v_104}:
      cps_provider_2_PartOk{cps_provider_2_join_text([v_8, " = (term_aux(", v_101, ") == ", U32.show(v_104), "u);\n"])}

def native_match_cps_provider_2_tag_body_12(v_76: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_72: String, v_73: String, v_74: String, v_78: Bool) -> cps_provider_2_Part:
  match v_76:
    case cps_provider_1_LayoutData{v_83, v_84}:
      native_match_cps_provider_2_tag_body_10(v_84, v_1, v_6, v_8, v_72, v_74, v_78)
    case cps_provider_1_LayoutBox{v_98}:
      v_101 = cps_provider_2_join_text(["blk_read(e.mem, ", v_73, ", ", v_72, ", (u32)(", v_74, "))"])
      native_match_cps_provider_2_tag_body_11(v_6, v_8, v_101)
    case _:
      cps_provider_2_PartFail{"a tag test needs a data field"}

def native_match_cps_provider_2_tag_body_13(+v_123: cps_provider_1_LayArm, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_123:
    case cps_provider_1_LayArm{v_126, v_127}:
      cps_provider_2_tag_single(v_1, v_126, v_6, v_8)

def native_match_cps_provider_2_tag_body_14(v_121: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_113: String, v_114: String) -> cps_provider_2_Part:
  match v_121:
    case []:
      cps_provider_2_PartFail{"a data layout has no arms"}
    case [+v_123]:
      native_match_cps_provider_2_tag_body_13(v_123, v_1, v_6, v_8)
    case _:
      cps_provider_2_tag_multi_buf(v_1, v_113, v_114, v_121, v_6, v_8)

def native_match_cps_provider_2_tag_body_15(v_115: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String, v_113: String, v_114: String) -> cps_provider_2_Part:
  match v_115:
    case cps_provider_1_LayoutData{v_120, v_121}:
      native_match_cps_provider_2_tag_body_14(v_121, v_1, v_6, v_8, v_113, v_114)
    case _:
      cps_provider_2_PartFail{"a tag test needs a data field"}

def native_match_cps_provider_2_tag_body_16(+v_3: cps_provider_2_PathState, +v_1: cps_provider_2_World, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StSlot{v_16, v_17, v_18, v_19, v_20, v_21}:
      native_match_cps_provider_2_tag_body_7(v_21, v_1, v_6, v_8, v_16, v_17, v_18)
    case cps_provider_2_StCell{v_72, v_73, v_74, v_75, v_76, v_77, v_78, v_79, v_80}:
      native_match_cps_provider_2_tag_body_12(v_76, v_1, v_6, v_8, v_72, v_73, v_74, v_78)
    case cps_provider_2_StBufField{v_113, v_114, v_115, v_116, v_117}:
      native_match_cps_provider_2_tag_body_15(v_115, v_1, v_6, v_8, v_113, v_114)
    case cps_provider_2_StArray{v_143, v_144, v_145, v_146, v_147, v_148, v_149, v_150, v_151}:
      cps_provider_2_PartFail{"a tag test needs a data field"}

def cps_provider_2_tag_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, +v_6: Maybe<&2, U32>, +v_8: String) -> cps_provider_2_Part:
  native_match_cps_provider_2_tag_body_16(v_3, v_1, v_6, v_8)

def native_match_cps_provider_2_copy_slot_body_0(v_18: cps_provider_1_CWord) -> cps_provider_2_Part:
  match v_18:
    case cps_provider_1_CWord32{}:
      cps_provider_2_PartOk{"pbr = ((u64)(u32)pbn);\n"}
    case _:
      cps_provider_2_PartOk{"pbr = pbn;\n"}

def native_match_cps_provider_2_copy_slot_body_1(v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_1_LayoutWord{v_18}:
      native_match_cps_provider_2_copy_slot_body_0(v_18)
    case cps_provider_1_LayoutData{v_23, v_24}:
      cps_provider_2_packed_data_copy(v_1, v_12)
    case cps_provider_1_LayoutBox{v_27}:
      cps_provider_2_PartFail{"a packed value has no boxed field"}

def native_match_cps_provider_2_copy_slot_body_2(v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World, v_11: Nat, v_13: String, v_14: String, v_15: String) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_1_LayoutWord{v_29}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ", cps_provider_2_raw_word_expr(v_13, v_11, v_29), ";\n"])}
    case cps_provider_1_LayoutBox{v_33}:
      cps_provider_2_box_copy_body(v_13, v_11, v_14, v_15)
    case cps_provider_1_LayoutData{v_37, v_38}:
      cps_provider_2_data_copy_body(v_1, v_12, v_13, v_11, v_14, v_15)

def native_match_cps_provider_2_copy_slot_body_3(v_16: Bool, +v_1: cps_provider_2_World, v_11: Nat, v_12: cps_provider_1_Layout, v_13: String, v_14: String, v_15: String) -> cps_provider_2_Part:
  match v_16:
    case True{}:
      native_match_cps_provider_2_copy_slot_body_1(v_12, v_1)
    case False{}:
      native_match_cps_provider_2_copy_slot_body_2(v_12, v_1, v_11, v_13, v_14, v_15)

def native_match_cps_provider_2_copy_slot_body_4(+v_3: cps_provider_2_PathState, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StSlot{v_11, v_12, v_13, v_14, v_15, v_16}:
      native_match_cps_provider_2_copy_slot_body_3(v_16, v_1, v_11, v_12, v_13, v_14, v_15)
    case _:
      cps_provider_2_PartFail{"not a field slot"}

def cps_provider_2_copy_slot_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_Part:
  native_match_cps_provider_2_copy_slot_body_4(v_3, v_1)

def native_match_cps_provider_2_packed_data_value_0(v_11: cps_provider_2_Part) -> cps_provider_2_Part:
  match v_11:
    case cps_provider_2_PartFail{v_13}:
      cps_provider_2_PartFail{v_13}
    case cps_provider_2_PartOk{v_15}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["{ Term pbl = 0; ", v_15, "; pbr = pbl; }\n"])}

def cps_provider_2_packed_data_value(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout) -> cps_provider_2_Part:
  v_7 = cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcOne{"((u64)pbn)"}, "pbl", "pblc")
  v_11 = cps_provider_2_part_of(cps_provider_2_run_jobs(v_7, v_1, []), "pbl")
  native_match_cps_provider_2_packed_data_value_0(v_11)

def native_match_cps_provider_2_packed_data_copy_0(v_11: cps_provider_2_Part) -> cps_provider_2_Part:
  match v_11:
    case cps_provider_2_PartFail{v_13}:
      cps_provider_2_PartFail{v_13}
    case cps_provider_2_PartOk{v_15}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["{ Term pbl = 0; ", v_15, "; pbr = pbl; }\n"])}

def cps_provider_2_packed_data_copy(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout) -> cps_provider_2_Part:
  v_7 = cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcOne{"((u64)pbn)"}, "pbl", "pblc")
  v_11 = cps_provider_2_part_of(cps_provider_2_run_jobs(v_7, v_1, []), "pbl")
  native_match_cps_provider_2_packed_data_copy_0(v_11)

def cps_provider_2_box_copy_body(+v_1: String, +v_3: Nat, +v_5: String, +v_7: String) -> cps_provider_2_Part:
  v_11 = cps_provider_2_join_text(["e.mem[", v_1, " + ", Nat.show(v_3), "]"])
  cps_provider_2_PartOk{cps_provider_2_join_text(["{ Term pbb = term_keep(e, ", v_11, ", 1); if (pbb != ", v_11, ") { if (", v_7, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_5, ") { (void)err_fail(\"a shared owner has an unsealed field\"); } else { ", v_11, " = pbb; } } pbr = pbb; }\n"])}

def native_match_cps_provider_2_data_copy_body_0(v_25: cps_provider_2_Part, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat, +v_9: String, +v_11: String, v_15: Nat) -> cps_provider_2_Part:
  match v_25:
    case cps_provider_2_PartFail{v_27}:
      cps_provider_2_PartFail{v_27}
    case cps_provider_2_PartOk{v_29}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["{ Term pbbuf[", Nat.show(v_15), "]; ", cps_provider_2_keep_copy(v_5, v_9, v_11, v_7, v_7, v_3, ""), "u32 pbi = 0; Term pbl = 0; ", v_29, "; pbr = pbl; }\n"])}

def native_match_cps_provider_2_data_copy_body_1(v_15: Nat, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat, +v_9: String, +v_11: String) -> cps_provider_2_Part:
  match v_15:
    case 0n:
      cps_provider_2_zero_value_body(v_1, v_3)
    case _:
      v_21 = cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc")
      v_25 = cps_provider_2_part_of(cps_provider_2_run_jobs(v_21, v_1, []), "pbl")
      native_match_cps_provider_2_data_copy_body_0(v_25, v_3, v_5, v_7, v_9, v_11, v_15)

def cps_provider_2_data_copy_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat, +v_9: String, +v_11: String) -> cps_provider_2_Part:
  v_15 = cps_provider_1_layout_words(v_3)
  native_match_cps_provider_2_data_copy_body_1(v_15, v_1, v_3, v_5, v_7, v_9, v_11)

def native_match_cps_provider_2_zero_value_body_0(v_25: Maybe<&2, U32>, v_13: String) -> cps_provider_2_Part:
  match v_25:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the arm `", v_13, "` has no canonical CID"])}
    case Some{v_18}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = term_pak(", U32.show(v_18), "u, 0);\n"])}

def native_match_cps_provider_2_zero_value_body_1(+v_10: cps_provider_1_LayArm, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_10:
    case cps_provider_1_LayArm{v_13, v_14}:
      native_match_cps_provider_2_zero_value_body_0(cps_provider_2_cid_of(v_13, v_1), v_13)

def native_match_cps_provider_2_zero_value_body_2(v_8: List<&2, cps_provider_1_LayArm>, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_8:
    case [+v_10]:
      native_match_cps_provider_2_zero_value_body_1(v_10, v_1)
    case _:
      cps_provider_2_PartFail{"a zero-word field must have exactly one constructor"}

def native_match_cps_provider_2_zero_value_body_3(+v_3: cps_provider_1_Layout, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_1_LayoutData{v_7, v_8}:
      native_match_cps_provider_2_zero_value_body_2(v_8, v_1)
    case _:
      cps_provider_2_PartFail{"a zero-word field is not a data layout"}

def cps_provider_2_zero_value_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout) -> cps_provider_2_Part:
  native_match_cps_provider_2_zero_value_body_3(v_3, v_1)

def native_match_cps_provider_2_buf_clear_words_0(v_10: Bool, +v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String) -> String:
  match v_10:
    case True{}:
      ""
    case False{}:
      cps_provider_2_join_text([v_9, "blk_write(e.mem, false, ", v_1, ", (u32)((", v_3, ") + ", Nat.show(v_7), "u), 0);\n", cps_provider_2_buf_clear_words(v_1, v_3, v_5, Nat.add(v_7, 1n), v_9)])

def cps_provider_2_buf_clear_words(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String) -> String:
  native_match_cps_provider_2_buf_clear_words_0(Nat.is_eq(v_7, v_5), v_1, v_3, v_5, v_7, v_9)

def native_match_cps_provider_2_buf_field_body_0(v_12: cps_provider_1_CWord, +v_5: String, +v_7: String, +v_9: Bool) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_1_CWord32{}:
      v_15 = cps_provider_2_join_text(["((u64)(u32)blk_read(e.mem, false, ", v_5, ", (u32)(", v_7, ")))"])
      v_18 = cps_provider_2_buf_move_clear(v_5, v_7, 1n, v_9)
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ", v_15, "; ", v_18, "\n"])}
    case _:
      cps_provider_2_PartFail{"a BUF raw field is not one w32 cell"}

def native_match_cps_provider_2_buf_field_body_1(v_45: cps_provider_2_Part, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: Bool) -> cps_provider_2_Part:
  match v_45:
    case cps_provider_2_PartFail{v_35}:
      cps_provider_2_PartFail{v_35}
    case cps_provider_2_PartOk{v_37}:
      v_41 = cps_provider_2_buf_move_clear(v_5, v_7, cps_provider_1_layout_words(v_3), v_9)
      cps_provider_2_PartOk{cps_provider_2_join_text(["Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", v_37, "; ", v_41, " pbr = pbl;\n"])}

def native_match_cps_provider_2_buf_field_body_2(v_24: List<&2, cps_provider_1_CWord>, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: Bool) -> cps_provider_2_Part:
  match v_24:
    case []:
      cps_provider_2_zero_value_body(v_1, v_3)
    case _:
      v_31 = cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcBlock{v_5, v_7, False{}, False{}, "pbc"}, "pbl", "pblc")
      native_match_cps_provider_2_buf_field_body_1(cps_provider_2_part_of(cps_provider_2_run_jobs(v_31, v_1, []), "pbl"), v_3, v_5, v_7, v_9)

def native_match_cps_provider_2_buf_field_body_3(+v_3: cps_provider_1_Layout, +v_1: cps_provider_2_World, +v_5: String, +v_7: String, +v_9: Bool) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_1_LayoutWord{v_12}:
      native_match_cps_provider_2_buf_field_body_0(v_12, v_5, v_7, v_9)
    case cps_provider_1_LayoutData{v_24, v_25}:
      native_match_cps_provider_2_buf_field_body_2(v_24, v_1, v_3, v_5, v_7, v_9)
    case cps_provider_1_LayoutBox{v_44}:
      cps_provider_2_PartFail{"a BUF inline form cannot hold a box"}

def cps_provider_2_buf_field_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: Bool) -> cps_provider_2_Part:
  native_match_cps_provider_2_buf_field_body_3(v_3, v_1, v_5, v_7, v_9)

def cps_provider_2_buf_move_clear(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool) -> String:
  match v_7:
    case True{}:
      cps_provider_2_buf_clear_words(v_1, v_3, v_5, 0n, "")
    case False{}:
      ""

def cps_provider_2_cell_arr_body(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_4: String, +v_6: String, +v_8: String, +v_10: String, +v_12: Bool) -> cps_provider_2_Part:
  match v_12:
    case True{}:
      cps_provider_2_data_move_body(v_1, v_2, cps_provider_2_join_text([v_4, " + (", v_6, ")"]), 0n)
    case False{}:
      cps_provider_2_data_copy_body(v_1, v_2, cps_provider_2_join_text([v_4, " + (", v_6, ")"]), 0n, v_8, v_10)

def cps_provider_2_cell_move_clear(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool) -> String:
  match v_7:
    case True{}:
      cps_provider_2_buf_clear_span(v_1, v_3, v_5, 0n, "      ")
    case False{}:
      ""

def native_match_cps_provider_2_cell_data_body_0(v_40: cps_provider_2_Part, +v_5: String, +v_7: String, +v_9: String, +v_17: Bool, v_21: Nat, v_30: String) -> cps_provider_2_Part:
  match v_40:
    case cps_provider_2_PartFail{v_33}:
      cps_provider_2_PartFail{v_33}
    case cps_provider_2_PartOk{v_35}:
      v_38 = cps_provider_2_cell_move_clear(v_5, v_9, v_21, v_17)
      cps_provider_2_PartOk{cps_provider_2_join_text(["if (", v_7, ") { ", v_35, " } else { Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", v_30, "; ", v_38, " pbr = pbl; }\n"])}

def native_match_cps_provider_2_cell_data_body_1(v_39: cps_provider_2_Part, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: String, +v_13: String, +v_15: String, +v_17: Bool, v_21: Nat) -> cps_provider_2_Part:
  match v_39:
    case cps_provider_2_PartFail{v_28}:
      cps_provider_2_PartFail{v_28}
    case cps_provider_2_PartOk{v_30}:
      native_match_cps_provider_2_cell_data_body_0(cps_provider_2_cell_arr_body(v_1, v_3, v_5, v_9, v_13, v_15, v_17), v_5, v_7, v_9, v_17, v_21, v_30)

def cps_provider_2_cell_data_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: String, +v_9: String, +v_11: Nat, +v_13: String, +v_15: String, +v_17: Bool) -> cps_provider_2_Part:
  v_21 = cps_provider_2_pow2(v_11)
  v_24 = cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcBlock{v_5, v_9, False{}, False{}, "pbc"}, "pbl", "pblc")
  native_match_cps_provider_2_cell_data_body_1(cps_provider_2_part_of(cps_provider_2_run_jobs(v_24, v_1, []), "pbl"), v_1, v_3, v_5, v_7, v_9, v_13, v_15, v_17, v_21)

def native_match_cps_provider_2_buf_clear_span_0(v_10: Bool, +v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String) -> String:
  match v_10:
    case True{}:
      ""
    case False{}:
      cps_provider_2_join_text([v_9, "blk_write(e.mem, false, ", v_1, ", (u32)((", v_3, ") + ", Nat.show(v_7), "ull), 0);\n", cps_provider_2_buf_clear_span(v_1, v_3, v_5, Nat.add(v_7, 1n), v_9)])

def cps_provider_2_buf_clear_span(+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String) -> String:
  native_match_cps_provider_2_buf_clear_span_0(Nat.is_eq(v_7, v_5), v_1, v_3, v_5, v_7, v_9)

def cps_provider_2_copy_cell_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StCell{v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22}:
      match v_18:
        case cps_provider_1_LayoutWord{v_24}:
          match v_24:
            case cps_provider_1_CWord32{}:
              cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "))));\n"])}
            case _:
              cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = (u64)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")));\n"])}
        case cps_provider_1_LayoutBox{v_30}:
          match v_20:
            case True{}:
              cps_provider_2_PartFail{"a BUF array cell cannot contain a boxed field"}
            case False{}:
              cps_provider_2_PartOk{cps_provider_2_join_text(["{ Term pv = blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")); Term pk = term_keep(e, pv, 1); if (pk != pv) { if (", v_22, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", v_21, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), pk); } } pbr = pk; }\n"])}
        case cps_provider_1_LayoutData{v_34, v_35}:
          cps_provider_2_cell_data_body(v_1, v_18, v_14, v_15, v_16, v_19, v_21, v_22, False{})
    case _:
      cps_provider_2_PartFail{"not a cell"}

def native_match_cps_provider_2_copy_padding_0(v_6: Bool, +v_1: Nat, +v_3: Nat, +v_5: String) -> String:
  match v_6:
    case True{}:
      ""
    case False{}:
      cps_provider_2_join_text([v_5, "e.mem[pdst + ", Nat.show(v_3), "] = e.mem[psrc + ", Nat.show(v_3), "];\n", cps_provider_2_copy_padding(v_1, Nat.add(v_3, 1n), v_5)])

def cps_provider_2_copy_padding(+v_1: Nat, +v_3: Nat, +v_5: String) -> String:
  native_match_cps_provider_2_copy_padding_0(Nat.is_eq(v_3, v_1), v_1, v_3, v_5)

def cps_provider_2_array_inner(+v_1: Bool, +v_3: String, +v_5: String, +v_6: cps_provider_1_Layout) -> String:
  match v_1:
    case True{}:
      cps_provider_2_move_copy("psrc", 0n, 0n, v_6, "    ")
    case False{}:
      cps_provider_2_keep_copy("psrc", v_3, v_5, 0n, 0n, v_6, "    ")

def cps_provider_2_array_copy_body(+v_1: cps_provider_2_PathState, +v_3: Bool) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_StArray{v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22}:
      v_25 = cps_provider_2_pow2(v_16)
      v_27 = cps_provider_1_layout_words(v_17)
      v_30 = cps_provider_2_array_inner(v_3, v_21, v_22, v_17)
      v_33 = cps_provider_2_copy_padding(v_25, v_27, "    ")
      v_36 = cps_provider_2_join_text(["u64 pal = (u64)(", v_14, "); u32 pac = (u32)(", v_15, "); bool paarr = ", v_18, "; u64 pnl = 0;\nif (paarr) { pnl = heap_alloc(e, blk_wcls(true, pac)); u64 pacount = (1ull << (pac - ", Nat.show(v_16), ")); for (u64 pe = 0; pe < pacount; pe += 1) { u64 psrc = pal + (", v_19, ") + (pe << ", Nat.show(v_16), "); u64 pdst = pnl + (pe << ", Nat.show(v_16), "); { Term pbbuf[", Nat.show(v_25), "]; ", v_30, v_33, "for (u64 pj = 0; pj < ", Nat.show(v_27), "; pj += 1) { e.mem[pdst + pj] = pbbuf[pj]; } } } } else { pnl = heap_alloc(e, blk_wcls(false, pac)); u64 pacells = (1ull << pac); for (u64 pi = 0; pi < pacells; pi += 1) { blk_write(e.mem, false, pnl, (u32)pi, blk_read(e.mem, false, pal, (u32)((", v_19, ") + pi))); } } pbr = term_blk(paarr, pac, pnl);\n"])
      cps_provider_2_PartOk{v_36}
    case _:
      cps_provider_2_PartFail{"not an array"}

def cps_provider_2_pow2(+v_1: Nat) -> Nat:
  match v_1:
    case 0n:
      1n
    case 1n+v_4:
      Nat.mul(2n, cps_provider_2_pow2(v_4))

def cps_provider_2_move_cell_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StCell{v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22}:
      match v_18:
        case cps_provider_1_LayoutWord{v_24}:
          match v_24:
            case cps_provider_1_CWord32{}:
              cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")))); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"])}
            case _:
              cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = (u64)(blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "))); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"])}
        case cps_provider_1_LayoutBox{v_30}:
          match v_20:
            case True{}:
              cps_provider_2_PartFail{"a BUF array cell cannot contain a boxed field"}
            case False{}:
              cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = blk_read(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, ")); blk_write(e.mem, ", v_15, ", ", v_14, ", (u32)(", v_16, "), 0);\n"])}
        case cps_provider_1_LayoutData{v_34, v_35}:
          cps_provider_2_cell_data_body(v_1, v_18, v_14, v_15, v_16, v_19, v_21, v_22, True{})
    case _:
      cps_provider_2_PartFail{"not a cell"}

def native_match_cps_provider_2_move_slot_body_0(v_12: cps_provider_1_Layout, +v_1: cps_provider_2_World, v_11: Nat, v_13: String) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_1_LayoutWord{v_19}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = ", cps_provider_2_raw_word_expr(v_13, v_11, v_19), ";\n"])}
    case cps_provider_1_LayoutBox{v_23}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = e.mem[", v_13, " + ", Nat.show(v_11), "]; e.mem[", v_13, " + ", Nat.show(v_11), "] = 0;\n"])}
    case cps_provider_1_LayoutData{v_27, v_28}:
      cps_provider_2_data_move_body(v_1, v_12, v_13, v_11)

def native_match_cps_provider_2_move_slot_body_1(v_16: Bool, +v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState, v_11: Nat, v_12: cps_provider_1_Layout, v_13: String) -> cps_provider_2_Part:
  match v_16:
    case True{}:
      cps_provider_2_copy_slot_body(v_1, v_3)
    case False{}:
      native_match_cps_provider_2_move_slot_body_0(v_12, v_1, v_11, v_13)

def native_match_cps_provider_2_move_slot_body_2(+v_3: cps_provider_2_PathState, +v_1: cps_provider_2_World) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StSlot{v_11, v_12, v_13, v_14, v_15, v_16}:
      native_match_cps_provider_2_move_slot_body_1(v_16, v_1, v_3, v_11, v_12, v_13)
    case _:
      cps_provider_2_PartFail{"not a field slot"}

def cps_provider_2_move_slot_body(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_Part:
  native_match_cps_provider_2_move_slot_body_2(v_3, v_1)

def native_match_cps_provider_2_data_move_body_0(v_24: cps_provider_2_Part, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat, v_11: Nat) -> cps_provider_2_Part:
  match v_24:
    case cps_provider_2_PartFail{v_21}:
      cps_provider_2_PartFail{v_21}
    case cps_provider_2_PartOk{v_23}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["{ Term pbbuf[", Nat.show(v_11), "]; ", cps_provider_2_move_copy(v_5, v_7, v_7, v_3, ""), "u32 pbi = 0; Term pbl = 0; ", v_23, "; pbr = pbl; }\n"])}

def native_match_cps_provider_2_data_move_body_1(v_11: Nat, +v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat) -> cps_provider_2_Part:
  match v_11:
    case 0n:
      cps_provider_2_zero_value_body(v_1, v_3)
    case _:
      v_17 = cps_provider_2_unfill_jobs(v_1, v_3, cps_provider_2_SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc")
      native_match_cps_provider_2_data_move_body_0(cps_provider_2_part_of(cps_provider_2_run_jobs(v_17, v_1, []), "pbl"), v_3, v_5, v_7, v_11)

def cps_provider_2_data_move_body(+v_1: cps_provider_2_World, +v_3: cps_provider_1_Layout, +v_5: String, +v_7: Nat) -> cps_provider_2_Part:
  v_11 = cps_provider_1_layout_words(v_3)
  native_match_cps_provider_2_data_move_body_1(v_11, v_1, v_3, v_5, v_7)

def cps_provider_2_state_stat(+v_1: cps_provider_2_PathState) -> String:
  match v_1:
    case cps_provider_2_StSlot{v_9, v_10, v_11, v_12, v_13, v_14}:
      v_13
    case cps_provider_2_StArray{v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32}:
      v_32
    case cps_provider_2_StCell{v_42, v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50}:
      v_50
    case cps_provider_2_StBufField{v_56, v_57, v_58, v_59, v_60}:
      v_60

def cps_provider_2_state_uniq(+v_1: cps_provider_2_PathState) -> String:
  match v_1:
    case cps_provider_2_StSlot{v_9, v_10, v_11, v_12, v_13, v_14}:
      v_12
    case cps_provider_2_StArray{v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32}:
      v_31
    case cps_provider_2_StCell{v_42, v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50}:
      v_49
    case cps_provider_2_StBufField{v_56, v_57, v_58, v_59, v_60}:
      v_59

def cps_provider_2_path_body_copy(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StSlot{v_11, v_12, v_13, v_14, v_15, v_16}:
      cps_provider_2_copy_slot_body(v_1, v_3)
    case cps_provider_2_StCell{v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35}:
      cps_provider_2_copy_cell_body(v_1, v_3)
    case cps_provider_2_StArray{v_46, v_47, v_48, v_49, v_50, v_51, v_52, v_53, v_54}:
      cps_provider_2_array_copy_body(v_3, False{})
    case cps_provider_2_StBufField{v_61, v_62, v_63, v_64, v_65}:
      cps_provider_2_buf_field_body(v_1, v_63, v_61, v_62, False{})

def cps_provider_2_path_body_move(+v_1: cps_provider_2_World, +v_3: cps_provider_2_PathState) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_StSlot{v_11, v_12, v_13, v_14, v_15, v_16}:
      cps_provider_2_move_slot_body(v_1, v_3)
    case cps_provider_2_StCell{v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35}:
      cps_provider_2_move_cell_body(v_1, v_3)
    case cps_provider_2_StArray{v_46, v_47, v_48, v_49, v_50, v_51, v_52, v_53, v_54}:
      cps_provider_2_array_copy_body(v_3, True{})
    case cps_provider_2_StBufField{v_61, v_62, v_63, v_64, v_65}:
      cps_provider_2_buf_field_body(v_1, v_63, v_61, v_62, True{})

def native_match_cps_provider_2_path_read_0(v_19: cps_provider_2_Part, +v_1: String) -> cps_provider_2_Part:
  match v_19:
    case cps_provider_2_PartFail{v_15}:
      cps_provider_2_PartFail{v_15}
    case cps_provider_2_PartOk{v_17}:
      cps_provider_2_PartOk{cps_provider_2_path_expr(v_1, v_17)}

def native_match_cps_provider_2_path_read_1(v_18: cps_provider_2_PathResult, +v_1: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_18:
    case cps_provider_2_PathFail{v_10}:
      cps_provider_2_PartFail{v_10}
    case cps_provider_2_PathOk{v_12}:
      native_match_cps_provider_2_path_read_0(cps_provider_2_read_body(v_6, v_12), v_1)

def cps_provider_2_path_read(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_path_read_1(cps_provider_2_resolve_path(v_6, v_4), v_1, v_6)

def native_match_cps_provider_2_runtime_cid_of_ctor_0(v_8: BIR.ConstructorLayout, +v_1: cps_provider_2_World) -> Maybe<&2, U32>:
  match v_8:
    case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
      cps_provider_2_cid_of(v_14, v_1)

def native_match_cps_provider_2_runtime_cid_of_ctor_1(v_17: Maybe<&2, BIR.ConstructorLayout>, +v_1: cps_provider_2_World) -> Maybe<&2, U32>:
  match v_17:
    case None{}:
      None{}
    case Some{v_8}:
      native_match_cps_provider_2_runtime_cid_of_ctor_0(v_8, v_1)

def cps_provider_2_runtime_cid_of_ctor(+v_1: cps_provider_2_World, +v_3: U32) -> Maybe<&2, U32>:
  native_match_cps_provider_2_runtime_cid_of_ctor_1(cps_provider_2_ctor_of(v_3, v_1), v_1)

def native_match_cps_provider_2_canonical_bool_0(v_12: Maybe<&2, String>, +v_3: String, v_7: String) -> cps_provider_2_Part:
  match v_12:
    case None{}:
      cps_provider_2_PartFail{"the runtime has no canonical False CID"}
    case Some{v_10}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["pbr = bend_bool(e, ", v_7, ", ", v_10, ", ", v_3, ");\n"])}

def native_match_cps_provider_2_canonical_bool_1(v_11: Maybe<&2, String>, +v_1: cps_provider_2_World, +v_3: String) -> cps_provider_2_Part:
  match v_11:
    case None{}:
      cps_provider_2_PartFail{"the runtime has no canonical True CID"}
    case Some{v_7}:
      native_match_cps_provider_2_canonical_bool_0(cps_provider_2_cid_text("False", v_1), v_3, v_7)

def cps_provider_2_canonical_bool(+v_1: cps_provider_2_World, +v_3: String) -> cps_provider_2_Part:
  native_match_cps_provider_2_canonical_bool_1(cps_provider_2_cid_text("True", v_1), v_1, v_3)

def native_match_cps_provider_2_path_hastag_0(v_32: cps_provider_2_Part, +v_1: String, v_23: String) -> cps_provider_2_Part:
  match v_32:
    case cps_provider_2_PartFail{v_26}:
      cps_provider_2_PartFail{v_26}
    case cps_provider_2_PartOk{v_28}:
      cps_provider_2_PartOk{cps_provider_2_path_expr(v_1, cps_provider_2_join_text(["u32 pbpred = 0; { ", v_23, " } ", v_28]))}

def native_match_cps_provider_2_path_hastag_1(v_31: cps_provider_2_Part, +v_1: String, +v_8: cps_provider_2_World) -> cps_provider_2_Part:
  match v_31:
    case cps_provider_2_PartFail{v_21}:
      cps_provider_2_PartFail{v_21}
    case cps_provider_2_PartOk{v_23}:
      native_match_cps_provider_2_path_hastag_0(cps_provider_2_canonical_bool(v_8, "pbpred"), v_1, v_23)

def native_match_cps_provider_2_path_hastag_2(v_30: Maybe<&2, U32>, +v_1: String, +v_6: U32, +v_8: cps_provider_2_World, v_14: cps_provider_2_PathState) -> cps_provider_2_Part:
  match v_30:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the BIR constructor id ", U32.show(v_6), " has no canonical runtime CID"])}
    case Some{v_18}:
      native_match_cps_provider_2_path_hastag_1(cps_provider_2_tag_body(v_8, v_14, Some{v_18}, "pbpred"), v_1, v_8)

def native_match_cps_provider_2_path_hastag_3(v_29: cps_provider_2_PathResult, +v_1: String, +v_6: U32, +v_8: cps_provider_2_World) -> cps_provider_2_Part:
  match v_29:
    case cps_provider_2_PathFail{v_12}:
      cps_provider_2_PartFail{v_12}
    case cps_provider_2_PathOk{v_14}:
      native_match_cps_provider_2_path_hastag_2(cps_provider_2_runtime_cid_of_ctor(v_8, v_6), v_1, v_6, v_8, v_14)

def cps_provider_2_path_hastag(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: U32, +v_8: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_path_hastag_3(cps_provider_2_resolve_path(v_8, v_4), v_1, v_6, v_8)

def native_match_cps_provider_2_path_copy_0(v_19: cps_provider_2_Part, +v_1: String) -> cps_provider_2_Part:
  match v_19:
    case cps_provider_2_PartFail{v_15}:
      cps_provider_2_PartFail{v_15}
    case cps_provider_2_PartOk{v_17}:
      cps_provider_2_PartOk{cps_provider_2_path_expr(v_1, v_17)}

def native_match_cps_provider_2_path_copy_1(v_18: cps_provider_2_PathResult, +v_1: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_18:
    case cps_provider_2_PathFail{v_10}:
      cps_provider_2_PartFail{v_10}
    case cps_provider_2_PathOk{v_12}:
      native_match_cps_provider_2_path_copy_0(cps_provider_2_path_body_copy(v_6, v_12), v_1)

def cps_provider_2_path_copy(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_path_copy_1(cps_provider_2_resolve_path(v_6, v_4), v_1, v_6)

def native_match_cps_provider_2_path_consume_0(v_30: cps_provider_2_Part, +v_1: String, v_12: cps_provider_2_PathState, v_17: String) -> cps_provider_2_Part:
  match v_30:
    case cps_provider_2_PartFail{v_20}:
      cps_provider_2_PartFail{v_20}
    case cps_provider_2_PartOk{v_22}:
      v_27 = cps_provider_2_join_text(["if (", cps_provider_2_state_stat(v_12), " || !", cps_provider_2_state_uniq(v_12), ") { ", v_17, " } else { ", v_22, " } "])
      cps_provider_2_PartOk{cps_provider_2_path_expr(v_1, v_27)}

def native_match_cps_provider_2_path_consume_1(v_29: cps_provider_2_Part, +v_1: String, +v_6: cps_provider_2_World, v_12: cps_provider_2_PathState) -> cps_provider_2_Part:
  match v_29:
    case cps_provider_2_PartFail{v_15}:
      cps_provider_2_PartFail{v_15}
    case cps_provider_2_PartOk{v_17}:
      native_match_cps_provider_2_path_consume_0(cps_provider_2_path_body_move(v_6, v_12), v_1, v_12, v_17)

def native_match_cps_provider_2_path_consume_2(v_28: cps_provider_2_PathResult, +v_1: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_28:
    case cps_provider_2_PathFail{v_10}:
      cps_provider_2_PartFail{v_10}
    case cps_provider_2_PathOk{v_12}:
      native_match_cps_provider_2_path_consume_1(cps_provider_2_path_body_copy(v_6, v_12), v_1, v_6, v_12)

def cps_provider_2_path_consume(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_path_consume_2(cps_provider_2_resolve_path(v_6, v_4), v_1, v_6)

def native_match_cps_provider_2_path_is_leaf_0(v_43: cps_provider_2_Part, +v_1: String) -> cps_provider_2_Part:
  match v_43:
    case cps_provider_2_PartFail{v_36}:
      cps_provider_2_PartFail{v_36}
    case cps_provider_2_PartOk{v_38}:
      cps_provider_2_PartOk{cps_provider_2_path_expr(v_1, v_38)}

def native_match_cps_provider_2_path_is_leaf_1(v_12: cps_provider_2_PathState, +v_1: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_2_StArray{v_22, v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30}:
      v_33 = cps_provider_2_join_text(["((u32)(", v_23, ") == ", Nat.show(v_24), "u)"])
      native_match_cps_provider_2_path_is_leaf_0(cps_provider_2_canonical_bool(v_6, v_33), v_1)
    case _:
      cps_provider_2_PartFail{"an array leaf test needs an array slice"}

def native_match_cps_provider_2_path_is_leaf_2(v_42: cps_provider_2_PathResult, +v_1: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_42:
    case cps_provider_2_PathFail{v_10}:
      cps_provider_2_PartFail{v_10}
    case cps_provider_2_PathOk{v_12}:
      native_match_cps_provider_2_path_is_leaf_1(v_12, v_1, v_6)

def cps_provider_2_path_is_leaf(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_path_is_leaf_2(cps_provider_2_resolve_path(v_6, v_4), v_1, v_6)

def native_match_cps_provider_2_path_is_node_0(v_43: cps_provider_2_Part, +v_1: String) -> cps_provider_2_Part:
  match v_43:
    case cps_provider_2_PartFail{v_36}:
      cps_provider_2_PartFail{v_36}
    case cps_provider_2_PartOk{v_38}:
      cps_provider_2_PartOk{cps_provider_2_path_expr(v_1, v_38)}

def native_match_cps_provider_2_path_is_node_1(v_12: cps_provider_2_PathState, +v_1: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_2_StArray{v_22, v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30}:
      v_33 = cps_provider_2_join_text(["((u32)(", v_23, ") > ", Nat.show(v_24), "u)"])
      native_match_cps_provider_2_path_is_node_0(cps_provider_2_canonical_bool(v_6, v_33), v_1)
    case _:
      cps_provider_2_PartFail{"an array node test needs an array slice"}

def native_match_cps_provider_2_path_is_node_2(v_42: cps_provider_2_PathResult, +v_1: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_42:
    case cps_provider_2_PathFail{v_10}:
      cps_provider_2_PartFail{v_10}
    case cps_provider_2_PathOk{v_12}:
      native_match_cps_provider_2_path_is_node_1(v_12, v_1, v_6)

def cps_provider_2_path_is_node(+v_1: String, +v_4: List<&2, cps_provider_2_PathStep>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_path_is_node_2(cps_provider_2_resolve_path(v_6, v_4), v_1, v_6)

def cps_provider_2_project_plan(+v_0: cps_provider_1_UnfillResult, +v_2: cps_provider_2_World, +v_3: cps_provider_1_Node, +v_4: cps_provider_1_Layout, +v_6: Nat, +v_8: String) -> cps_provider_2_Part:
  match v_0:
    case cps_provider_1_UnfillFailed{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_1_UnfillFound{v_13}:
      match v_3:
        case cps_provider_1_Node{v_17, v_18, v_19}:
          cps_provider_2_project_packed_flag(v_19, v_2, v_4, v_6, List.length(&2, cps_provider_1_CWord, v_17), v_8)

def cps_provider_2_project_slot(+v_0: cps_provider_1_SlotResult, +v_2: cps_provider_2_World, +v_3: cps_provider_1_Node, +v_5: String, +v_7: U32, +v_9: String) -> cps_provider_2_Part:
  match v_0:
    case cps_provider_1_SlotErased{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the projection of `", v_5, "` names an erased field, which has no storage"])}
    case cps_provider_1_SlotFailed{v_13}:
      cps_provider_2_PartFail{v_13}
    case cps_provider_1_SlotFound{v_15}:
      match v_15:
        case cps_provider_1_NodeSlot{v_19, v_20, v_21}:
          match v_2:
            case cps_provider_2_World{v_25, v_26, v_27}:
              v_29 = cps_provider_1_slot_unfill(v_25, v_5, v_7)
              cps_provider_2_project_plan(v_29, v_2, v_3, v_21, v_20, v_9)

def cps_provider_2_project_layout(+v_0: cps_provider_1_NodeResult, +v_2: cps_provider_2_World, +v_4: String, +v_6: U32, +v_8: String) -> cps_provider_2_Part:
  match v_0:
    case cps_provider_1_NodeFailed{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_1_NodeFound{v_13}:
      match v_2:
        case cps_provider_2_World{v_17, v_18, v_19}:
          v_21 = cps_provider_1_node_slot(v_17, v_4, v_6)
          cps_provider_2_project_slot(v_21, v_2, v_13, v_4, v_6, v_8)

def cps_provider_2_project_node(+v_1: cps_provider_2_World, +v_3: String, +v_5: U32, +v_7: String) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_World{v_12, v_13, v_14}:
      v_16 = cps_provider_1_node_layout(v_12, v_3)
      cps_provider_2_project_layout(v_16, v_1, v_3, v_5, v_7)

def cps_provider_2_project_marker(+v_1: Bool, +v_3: String, +v_5: String, +v_7: U32, +v_9: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case True{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the intrinsic constructor `", v_5, "` must be lowered to its primitive before C projection"])}
    case False{}:
      cps_provider_2_project_node(v_9, v_5, v_7, v_3)

def cps_provider_2_project_native(+v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_8: U32, +v_10: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_project_node(v_10, v_6, v_8, v_4)
    case Some{v_14}:
      cps_provider_2_project_marker(cps_provider_2_intrinsic_marker(v_14), v_4, v_6, v_8, v_10)

def cps_provider_2_project_row(+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: U32, +v_7: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case None{}:
      cps_provider_2_PartFail{"BIR projects a constructor with no layout row"}
    case Some{v_10}:
      match v_10:
        case BIR.ConstructorLayout{v_15, v_16, v_17, v_18}:
          cps_provider_2_project_native(v_17, v_3, v_16, v_5, v_7)

def cps_provider_2_project_part(+v_1: String, +v_3: U32, +v_5: U32, +v_7: cps_provider_2_World) -> cps_provider_2_Part:
  v_11 = cps_provider_2_ctor_of(v_3, v_7)
  cps_provider_2_project_row(v_11, v_1, v_5, v_7)

def cps_provider_2_hastag_bools(+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: U32, +v_9: String) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"the C runtime contract needs the `True` constructor for a tag test"}
    case Some{v_12}:
      match v_5:
        case None{}:
          cps_provider_2_PartFail{"the C runtime contract needs the `False` constructor for a tag test"}
        case Some{v_14}:
          cps_provider_2_PartOk{cps_provider_2_join_text(["bend_bool(e, ", v_12, ", ", v_14, ", (u64)bend_hastag(", v_9, ", ", U32.show(v_7), "u))"])}

def cps_provider_2_hastag_cid(+v_2: Maybe<&2, U32>, +v_4: String, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"the tagged constructor has no canonical CID row"}
    case Some{v_9}:
      cps_provider_2_hastag_bools(cps_provider_2_cid_text("True", v_6), cps_provider_2_cid_text("False", v_6), v_9, v_4)

def cps_provider_2_hastag_row(+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case None{}:
      cps_provider_2_PartFail{"BIR has-tags a constructor with no layout row"}
    case Some{v_8}:
      match v_8:
        case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
          cps_provider_2_hastag_cid(cps_provider_2_cid_of(v_14, v_5), v_3, v_5)

def cps_provider_2_hastag_part(+v_1: String, +v_3: U32, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  v_9 = cps_provider_2_ctor_of(v_3, v_5)
  cps_provider_2_hastag_row(v_9, v_1, v_5)

def cps_provider_2_arr_flag(+v_1: Bool) -> String:
  match v_1:
    case True{}:
      "true"
    case False{}:
      "false"

def cps_provider_2_array_label(+v_0: BIR.Primitive) -> String:
  match v_0:
    case BIR.PrimArrayNew{}:
      "array_new"
    case BIR.PrimArrayGet{}:
      "array_get"
    case BIR.PrimArraySet{}:
      "array_set"
    case BIR.PrimArraySwap{}:
      "array_swap"
    case BIR.PrimArrayAtomicAdd{}:
      "array_atomic_add"
    case BIR.PrimArrayAtomicMin{}:
      "array_atomic_min"
    case BIR.PrimArrayAtomicMax{}:
      "array_atomic_max"
    case BIR.PrimArrayAtomicAnd{}:
      "array_atomic_and"
    case BIR.PrimArrayAtomicOr{}:
      "array_atomic_or"
    case BIR.PrimArrayAtomicXor{}:
      "array_atomic_xor"
    case BIR.PrimArrayAtomicExch{}:
      "array_atomic_exch"
    case BIR.PrimArrayAtomicCas{}:
      "array_atomic_cas"
    case BIR.PrimArrayAtomicFadd{}:
      "array_atomic_fadd"
    case BIR.PrimArraySize{}:
      "array_size"
    case BIR.PrimArrayClone{}:
      "array_clone"
    case BIR.PrimArrayLeaf{}:
      "array_leaf"
    case BIR.PrimArrayNode{}:
      "array_node"
    case BIR.PrimIsArrayLeaf{}:
      "is_array_leaf"
    case BIR.PrimIsArrayNode{}:
      "is_array_node"
    case _:
      "array"

def cps_provider_2_descriptor_missing(+v_0: BIR.Primitive) -> String:
  match v_0:
    case BIR.PrimMapFind{}:
      "the map read `Map.find` carries no instantiated value Descriptor; lowering must supply PrimitiveCall.types"
    case _:
      cps_provider_2_join_text(["the array primitive `", cps_provider_2_array_label(v_0), "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"])

def cps_provider_2_array_cell_result(+v_0: cps_provider_1_CellResult) -> cps_provider_2_CellOut:
  match v_0:
    case cps_provider_1_CellFailed{v_3}:
      cps_provider_2_CellFail{v_3}
    case cps_provider_1_CellFound{v_5}:
      match v_5:
        case cps_provider_1_Cell{v_10, v_11, v_12, v_13}:
          cps_provider_2_CellOk{v_10, v_11, v_12, v_13}

def native_match_cps_provider_2_array_cell_0(+v_1: cps_provider_2_World, +v_9: BIR.Descriptor) -> cps_provider_2_CellOut:
  match v_1:
    case cps_provider_2_World{v_13, v_14, v_15}:
      cps_provider_2_array_cell_result(cps_provider_1_array_cell(v_13, v_9))

def native_match_cps_provider_2_array_cell_1(+v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_2_World, +v_4: BIR.Primitive) -> cps_provider_2_CellOut:
  match v_3:
    case []:
      cps_provider_2_CellFail{cps_provider_2_join_text(["the array primitive `", cps_provider_2_array_label(v_4), "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"])}
    case [+v_9]:
      native_match_cps_provider_2_array_cell_0(v_1, v_9)
    case _:
      cps_provider_2_CellFail{cps_provider_2_join_text(["the array primitive `", cps_provider_2_array_label(v_4), "` must carry exactly one element Descriptor"])}

def cps_provider_2_array_cell(+v_1: cps_provider_2_World, +v_3: List<&2, BIR.Descriptor>, +v_4: BIR.Primitive) -> cps_provider_2_CellOut:
  native_match_cps_provider_2_array_cell_1(v_3, v_1, v_4)

def cps_provider_2_operand_at(+v_2: List<&2, cps_provider_2_Operand>, +v_4: Nat) -> Maybe<&2, cps_provider_2_Operand>:
  match v_2:
    case []:
      None{}
    case +v_9 <> +v_10:
      match v_4:
        case 0n:
          Some{v_9}
        case 1n+v_12:
          cps_provider_2_operand_at(v_10, v_12)

def cps_provider_2_operand_text(+v_1: cps_provider_2_Operand) -> String:
  match v_1:
    case cps_provider_2_Operand{v_5, v_6}:
      v_6

def cps_provider_2_operand_use(+v_1: cps_provider_2_Operand) -> BIR.Use:
  match v_1:
    case cps_provider_2_Operand{v_4, v_5}:
      v_4

def cps_provider_2_keep_text(+v_1: cps_provider_2_Operand) -> String:
  match v_1:
    case cps_provider_2_Operand{v_5, v_6}:
      match v_5:
        case BIR.Many{}:
          cps_provider_2_join_text(["term_keep(e, ", v_6, ", 1)"])
        case _:
          v_6

def cps_provider_2_tuple_cid(+v_2: Maybe<&2, String>, +v_4: String, +v_6: String) -> cps_provider_2_Part:
  match v_2:
    case Some{v_9}:
      cps_provider_2_PartOk{cps_provider_2_join_text(["bend_tuple(e, ", v_9, ", ", v_4, ", ", v_6, ")"])}
    case None{}:
      cps_provider_2_PartFail{"the C runtime contract needs the `Tuple` constructor for an array result"}

def cps_provider_2_tuple_part(+v_1: cps_provider_2_World, +v_3: String, +v_5: String) -> cps_provider_2_Part:
  cps_provider_2_tuple_cid(cps_provider_2_cid_text("Tuple", v_1), v_3, v_5)

def cps_provider_2_seal_cell_box(+v_0: BIR.Use, +v_2: String) -> List<&2, cps_provider_2_Job>:
  match v_0:
    case BIR.Many{}:
      [cps_provider_2_JText{cps_provider_2_join_text(["w0[", v_2, "] = term_keep(e, w0[", v_2, "], 1); ", v_2, " += 1;"])}]
    case _:
      [cps_provider_2_JText{cps_provider_2_join_text([v_2, " += 1;"])}]

def cps_provider_2_seal_cell_kind(+v_0: BIR.Use, +v_1: cps_provider_1_CWord, +v_3: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case cps_provider_1_CWord32{}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_3, " += 1;"])}]
    case cps_provider_1_CWord64{}:
      [cps_provider_2_JText{cps_provider_2_join_text([v_3, " += 1;"])}]
    case cps_provider_1_CWordBox{}:
      cps_provider_2_seal_cell_box(v_0, v_3)

def cps_provider_2_seal_cell_walk(+v_0: BIR.Use, +v_2: List<&2, cps_provider_1_CWord>, +v_4: String) -> List<&2, cps_provider_2_Job>:
  match v_2:
    case []:
      []
    case +v_9 <> +v_10:
      List.append(&2, cps_provider_2_Job, cps_provider_2_seal_cell_kind(v_0, v_9, v_4), cps_provider_2_seal_cell_walk(v_0, v_10, v_4))

def cps_provider_2_elem_fill_operand(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_3: BIR.Use, +v_5: cps_provider_2_Code, +v_7: String, +v_9: String) -> List<&2, cps_provider_2_Job>:
  v_14 = cps_provider_2_join_text([v_9, "c"])
  v_24 = List.append(&2, cps_provider_2_Job, cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_join_text(["u32 ", v_14, " = 0;"])}), List.append(&2, cps_provider_2_Job, cps_provider_2_code_jobs(v_5), List.append(&2, cps_provider_2_Job, cps_provider_2_fill_jobs(v_1, v_2, v_7, cps_provider_2_DstSeq{"w0", "o0"}, v_9), cps_provider_2_seal_cell_walk(v_3, cps_provider_1_layout_kinds(v_2), v_14))))
  v_24

def cps_provider_2_elem_fill(+v_1: cps_provider_2_World, +v_2: cps_provider_1_Layout, +v_3: BIR.Use, +v_5: String, +v_7: String) -> List<&2, cps_provider_2_Job>:
  cps_provider_2_elem_fill_operand(v_1, v_2, v_3, cps_provider_2_operand_code(v_2, v_3, v_5, v_7), cps_provider_2_operand_name(v_2, v_3, v_5, v_7), v_7)

def cps_provider_2_elem_stores(+v_1: Nat) -> String:
  cps_provider_2_join_text(["Term f0[", Nat.show(v_1), "]; for (u32 f0i = 0; f0i < ", Nat.show(v_1), "; f0i += 1) { f0[f0i] = w0[f0i]; }"])

def cps_provider_2_elem_decl(+v_1: Nat) -> String:
  cps_provider_2_dst_decl("w0", "o0", v_1)

def cps_provider_2_run_part(+v_2: List<&2, cps_provider_2_Job>, +v_4: cps_provider_2_World, +v_6: String) -> cps_provider_2_Part:
  cps_provider_2_part_of(cps_provider_2_run_jobs(v_2, v_4, []), v_6)

def cps_provider_2_array_new_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_7: cps_provider_2_World, +v_8: cps_provider_1_Layout, +v_10: Bool, +v_12: Nat, +v_14: Nat) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"array_new needs the dimension and the value"}
    case Some{v_17}:
      match v_5:
        case None{}:
          cps_provider_2_PartFail{"array_new needs the dimension and the value"}
        case Some{v_19}:
          v_23 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_elem_stores(v_12)}], [])
          v_31 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_elem_decl(v_12)}], List.append(&2, cps_provider_2_Job, cps_provider_2_elem_fill(v_7, v_8, cps_provider_2_operand_use(v_19), cps_provider_2_operand_text(v_19), "an"), v_23))
          cps_provider_2_run_part(v_31, v_7, cps_provider_2_join_text(["blk_new(e, ", cps_provider_2_arr_flag(v_10), ", (u64)(", cps_provider_2_operand_text(v_17), "), ", Nat.show(v_14), ", ", Nat.show(v_12), ", f0)"]))

def cps_provider_2_tuple_and_code(+v_1: cps_provider_2_Part, +v_3: cps_provider_2_Code) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_PartFail{v_6}:
      cps_provider_2_PartFail{v_6}
    case cps_provider_2_PartOk{v_8}:
      cps_provider_2_part_of(v_3, v_8)

def cps_provider_2_array_get_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_7: cps_provider_2_World, +v_8: cps_provider_1_Layout, +v_10: Bool, +v_12: Nat) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"array_get needs the array and the index"}
    case Some{v_15}:
      match v_5:
        case None{}:
          cps_provider_2_PartFail{"array_get needs the array and the index"}
        case Some{v_17}:
          v_24 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["Term a0 = ", cps_provider_2_keep_text(v_15), "; Term i0 = ", cps_provider_2_operand_text(v_17), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_12), "); u32 c0 = 0; Term r0 = 0;"])}], cps_provider_2_unfill_jobs(v_7, v_8, cps_provider_2_SrcBlock{"l0", "g0", v_10, True{}, "c0"}, "r0", "ag"))
          v_27 = cps_provider_2_run_jobs(v_24, v_7, [])
          cps_provider_2_tuple_and_code(cps_provider_2_tuple_part(v_7, "a0", "r0"), v_27)

def cps_provider_2_old_read_cell(+v_1: Bool, +v_3: String) -> List<&2, cps_provider_2_Job>:
  [cps_provider_2_JText{cps_provider_2_join_text(["old0[", v_3, "] = blk_read(e.mem, ", cps_provider_2_arr_flag(v_1), ", l0, g0 + ", v_3, "); ", v_3, " += 1;"])}]

def cps_provider_2_kinds_box_jobs(+v_1: List<&2, cps_provider_1_CWord>, +v_3: String, +v_5: Bool) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case []:
      []
    case +v_10 <> +v_11:
      List.append(&2, cps_provider_2_Job, cps_provider_2_old_read_cell(v_5, v_3), cps_provider_2_kinds_box_jobs(v_11, v_3, v_5))

def cps_provider_2_old_sink_jobs(+v_1: List<&2, cps_provider_1_CWord>, +v_3: String) -> List<&2, cps_provider_2_Job>:
  match v_1:
    case []:
      []
    case +v_8 <> +v_9:
      match v_8:
        case cps_provider_1_CWordBox{}:
          List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["term_sink(e, old0[", v_3, "]); ", v_3, " += 1;"])}], cps_provider_2_old_sink_jobs(v_9, v_3))
        case _:
          List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text([v_3, " += 1;"])}], cps_provider_2_old_sink_jobs(v_9, v_3))

def cps_provider_2_write_jobs(+v_1: Bool, +v_3: List<&2, cps_provider_1_CWord>, +v_5: String) -> List<&2, cps_provider_2_Job>:
  match v_3:
    case []:
      []
    case +v_10 <> +v_11:
      List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["blk_write(e.mem, ", cps_provider_2_arr_flag(v_1), ", l0, g0 + ", v_5, ", w0[", v_5, "]); ", v_5, " += 1;"])}], cps_provider_2_write_jobs(v_1, v_11, v_5))

def cps_provider_2_array_set_run(+v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_5: cps_provider_2_Operand, +v_7: cps_provider_2_World, +v_8: cps_provider_1_Layout, +v_10: Bool, +v_12: Nat, +v_14: Nat) -> cps_provider_2_Part:
  v_17 = cps_provider_1_layout_kinds(v_8)
  v_20 = cps_provider_2_kinds_box_jobs(v_17, "c0", v_10)
  v_27 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{"c0 = 0;"}], List.append(&2, cps_provider_2_Job, cps_provider_2_write_jobs(v_10, v_17, "c0"), List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{"c0 = 0;"}], cps_provider_2_old_sink_jobs(v_17, "c0"))))
  v_40 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["Term a0 = ", cps_provider_2_keep_text(v_1), "; Term i0 = ", cps_provider_2_operand_text(v_3), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_14), "); Term old0[", Nat.show(v_12), "]; u32 c0 = 0;"])}], List.append(&2, cps_provider_2_Job, v_20, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_elem_decl(v_12)}], List.append(&2, cps_provider_2_Job, cps_provider_2_elem_fill(v_7, v_8, cps_provider_2_operand_use(v_5), cps_provider_2_operand_text(v_5), "as"), v_27))))
  cps_provider_2_part_of(cps_provider_2_run_jobs(v_40, v_7, []), "a0")

def cps_provider_2_array_set_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, +v_10: cps_provider_2_World, +v_11: cps_provider_1_Layout, +v_13: Bool, +v_15: Nat, +v_17: Nat) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"array_set needs the array, the index and the value"}
    case Some{v_20}:
      match v_5:
        case None{}:
          cps_provider_2_PartFail{"array_set needs the array, the index and the value"}
        case Some{v_22}:
          match v_8:
            case None{}:
              cps_provider_2_PartFail{"array_set needs the array, the index and the value"}
            case Some{v_24}:
              cps_provider_2_array_set_run(v_20, v_22, v_24, v_10, v_11, v_13, v_15, v_17)

def cps_provider_2_array_swap_run(+v_1: cps_provider_2_Operand, +v_3: cps_provider_2_Operand, +v_5: cps_provider_2_Operand, +v_7: cps_provider_2_World, +v_8: cps_provider_1_Layout, +v_10: Bool, +v_12: Nat, +v_14: Nat) -> cps_provider_2_Part:
  v_17 = cps_provider_1_layout_kinds(v_8)
  v_20 = cps_provider_2_kinds_box_jobs(v_17, "c0", v_10)
  v_23 = cps_provider_2_unfill_jobs(v_7, v_8, cps_provider_2_SrcBuf{"old0", "oc0"}, "r0", "awold")
  v_29 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{"c0 = 0;"}], List.append(&2, cps_provider_2_Job, cps_provider_2_write_jobs(v_10, v_17, "c0"), List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{"u32 oc0 = 0;"}], v_23)))
  v_42 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_join_text(["Term a0 = ", cps_provider_2_keep_text(v_1), "; Term i0 = ", cps_provider_2_operand_text(v_3), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(v_14), "); Term old0[", Nat.show(v_12), "]; u32 c0 = 0; Term r0 = 0;"])}], List.append(&2, cps_provider_2_Job, v_20, List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_elem_decl(v_12)}], List.append(&2, cps_provider_2_Job, cps_provider_2_elem_fill(v_7, v_8, cps_provider_2_operand_use(v_5), cps_provider_2_operand_text(v_5), "aw"), v_29))))
  v_45 = cps_provider_2_run_jobs(v_42, v_7, [])
  cps_provider_2_tuple_and_code(cps_provider_2_tuple_part(v_7, "a0", "r0"), v_45)

def cps_provider_2_array_swap_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>, +v_8: Maybe<&2, cps_provider_2_Operand>, +v_10: cps_provider_2_World, +v_11: cps_provider_1_Layout, +v_13: Bool, +v_15: Nat, +v_17: Nat) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"array_swap needs the array, the index and the value"}
    case Some{v_20}:
      match v_5:
        case None{}:
          cps_provider_2_PartFail{"array_swap needs the array, the index and the value"}
        case Some{v_22}:
          match v_8:
            case None{}:
              cps_provider_2_PartFail{"array_swap needs the array, the index and the value"}
            case Some{v_24}:
              cps_provider_2_array_swap_run(v_20, v_22, v_24, v_10, v_11, v_13, v_15, v_17)

def cps_provider_2_array_size_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World, +v_6: Nat) -> cps_provider_2_Part:
  match v_2:
    case Some{v_9}:
      v_15 = cps_provider_2_run_jobs(cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_join_text(["Term a0 = ", cps_provider_2_keep_text(v_9), ";"])}), v_4, [])
      cps_provider_2_tuple_and_code(cps_provider_2_tuple_part(v_4, "a0", cps_provider_2_join_text(["(1ull << (blk_cls(a0) - ", Nat.show(v_6), "))"])), v_15)
    case None{}:
      cps_provider_2_PartFail{"array_size needs the array"}

def cps_provider_2_array_clone_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case Some{v_7}:
      v_13 = cps_provider_2_run_jobs(cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_join_text(["Term a0 = ", cps_provider_2_keep_text(v_7), ";"])}), v_4, [])
      cps_provider_2_tuple_and_code(cps_provider_2_tuple_part(v_4, "a0", "blk_copy(e, a0)"), v_13)
    case None{}:
      cps_provider_2_PartFail{"array_clone needs the array"}

def cps_provider_2_atomic_cell_text(+v_1: String, +v_3: String) -> String:
  cps_provider_2_join_text(["blk_ptr(e.mem, blk_loc(e.mem, ", v_1, "), blk_at(", v_1, ", (u64)(u32)(", v_3, "), 0))"])

def cps_provider_2_atomic_call_text(+v_1: String, +v_3: String, +v_5: String, +v_7: String) -> String:
  cps_provider_2_join_text(["(u64)", v_7, "(", cps_provider_2_atomic_cell_text(v_1, v_3), ", (u32)(", v_5, "))"])

def cps_provider_2_atomic_cas_text(+v_1: String, +v_3: String, +v_5: String, +v_7: String) -> String:
  cps_provider_2_join_text(["(u64)a32_cmpx(", cps_provider_2_atomic_cell_text(v_1, v_3), ", (u32)(", v_5, "), (u32)(", v_7, "))"])

def cps_provider_2_atomic_helper(+v_0: BIR.Primitive) -> cps_provider_2_Part:
  match v_0:
    case BIR.PrimArrayAtomicAdd{}:
      cps_provider_2_PartOk{"a32_add"}
    case BIR.PrimArrayAtomicMin{}:
      cps_provider_2_PartOk{"a32_min"}
    case BIR.PrimArrayAtomicMax{}:
      cps_provider_2_PartOk{"a32_max"}
    case BIR.PrimArrayAtomicAnd{}:
      cps_provider_2_PartOk{"a32_and"}
    case BIR.PrimArrayAtomicOr{}:
      cps_provider_2_PartOk{"a32_or"}
    case BIR.PrimArrayAtomicXor{}:
      cps_provider_2_PartOk{"a32_xor"}
    case BIR.PrimArrayAtomicExch{}:
      cps_provider_2_PartOk{"a32_exch"}
    case BIR.PrimArrayAtomicFadd{}:
      cps_provider_2_PartOk{"a32_fadd"}
    case _:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the primitive `", cps_provider_2_array_label(v_0), "` has no a32 read-modify-write helper"])}

def cps_provider_2_atomic_pair(+v_1: String, +v_3: String, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  cps_provider_2_tuple_cid(cps_provider_2_cid_text("Tuple", v_5), v_3, v_1)

def native_match_cps_provider_2_atomic_three_operands_0(v_21: cps_provider_2_Part, +v_2: cps_provider_2_Operand, +v_4: cps_provider_2_Operand, +v_6: cps_provider_2_Operand, +v_8: cps_provider_2_World) -> cps_provider_2_Part:
  match v_21:
    case cps_provider_2_PartFail{v_12}:
      cps_provider_2_PartFail{v_12}
    case cps_provider_2_PartOk{v_14}:
      v_20 = cps_provider_2_run_jobs(cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_join_text(["Term a0 = ", cps_provider_2_keep_text(v_2), ";"])}), v_8, [])
      cps_provider_2_tuple_and_code(cps_provider_2_atomic_pair(cps_provider_2_atomic_call_text("a0", cps_provider_2_operand_text(v_4), cps_provider_2_operand_text(v_6), v_14), "a0", v_8), v_20)

def cps_provider_2_atomic_three_operands(+v_0: BIR.Primitive, +v_2: cps_provider_2_Operand, +v_4: cps_provider_2_Operand, +v_6: cps_provider_2_Operand, +v_8: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_atomic_three_operands_0(cps_provider_2_atomic_helper(v_0), v_2, v_4, v_6, v_8)

def cps_provider_2_atomic_three_pargs(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  match v_3:
    case [v_10, v_11, v_12]:
      cps_provider_2_atomic_three_operands(v_0, v_10, v_11, v_12, v_5)
    case _:
      cps_provider_2_PartFail{cps_provider_2_join_text([cps_provider_2_array_label(v_0), " takes the array, the index and the value"])}

def cps_provider_2_atomic_cas_pargs(+v_2: List<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case [v_10, v_11, v_12, v_13]:
      v_19 = cps_provider_2_run_jobs(cps_provider_2_one_job(cps_provider_2_JText{cps_provider_2_join_text(["Term a0 = ", cps_provider_2_keep_text(v_10), ";"])}), v_4, [])
      cps_provider_2_tuple_and_code(cps_provider_2_atomic_pair(cps_provider_2_atomic_cas_text("a0", cps_provider_2_operand_text(v_11), cps_provider_2_operand_text(v_12), cps_provider_2_operand_text(v_13)), "a0", v_4), v_19)
    case _:
      cps_provider_2_PartFail{"array_atomic_cas takes the array, the index, the expected word and the replacement"}

def cps_provider_2_atomic_pargs(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  match v_0:
    case BIR.PrimArrayAtomicCas{}:
      cps_provider_2_atomic_cas_pargs(v_3, v_5)
    case _:
      cps_provider_2_atomic_three_pargs(v_0, v_3, v_5)

def native_match_cps_provider_2_atomic_three_regs_0(v_25: cps_provider_2_Part, +v_5: cps_provider_2_World, v_10: String, v_11: String, v_12: String) -> cps_provider_2_Part:
  match v_25:
    case cps_provider_2_PartFail{v_15}:
      cps_provider_2_PartFail{v_15}
    case cps_provider_2_PartOk{v_17}:
      cps_provider_2_atomic_pair(cps_provider_2_atomic_call_text(v_10, v_11, v_12, v_17), v_10, v_5)

def native_match_cps_provider_2_atomic_three_regs_1(+v_3: List<&2, String>, +v_0: BIR.Primitive, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  match v_3:
    case [v_10, v_11, v_12]:
      native_match_cps_provider_2_atomic_three_regs_0(cps_provider_2_atomic_helper(v_0), v_5, v_10, v_11, v_12)
    case _:
      cps_provider_2_PartFail{cps_provider_2_join_text([cps_provider_2_array_label(v_0), " takes the array, the index and the value"])}

def cps_provider_2_atomic_three_regs(+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_atomic_three_regs_1(v_3, v_0, v_5)

def cps_provider_2_atomic_cas_regs(+v_2: List<&2, String>, +v_4: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case [v_10, v_11, v_12, v_13]:
      cps_provider_2_atomic_pair(cps_provider_2_atomic_cas_text(v_10, v_11, v_12, v_13), v_10, v_4)
    case _:
      cps_provider_2_PartFail{"array_atomic_cas takes the array, the index, the expected word and the replacement"}

def cps_provider_2_atomic_prim_part(+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  match v_0:
    case BIR.PrimArrayAtomicCas{}:
      cps_provider_2_atomic_cas_regs(v_3, v_5)
    case _:
      cps_provider_2_atomic_three_regs(v_0, v_3, v_5)

def cps_provider_2_array_leaf_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World, +v_5: cps_provider_1_Layout, +v_7: Bool, +v_9: Nat, +v_11: Nat) -> cps_provider_2_Part:
  match v_2:
    case Some{v_14}:
      v_23 = List.append(&2, cps_provider_2_Job, [cps_provider_2_JText{cps_provider_2_elem_decl(v_9)}], List.append(&2, cps_provider_2_Job, cps_provider_2_elem_fill(v_4, v_5, cps_provider_2_operand_use(v_14), cps_provider_2_operand_text(v_14), "al"), [cps_provider_2_JText{cps_provider_2_elem_stores(v_9)}]))
      cps_provider_2_run_part(v_23, v_4, cps_provider_2_join_text(["blk_new(e, ", cps_provider_2_arr_flag(v_7), ", 0, ", Nat.show(v_11), ", ", Nat.show(v_9), ", f0)"]))
    case None{}:
      cps_provider_2_PartFail{"array_leaf needs the element value"}

def cps_provider_2_array_node_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_5: Maybe<&2, cps_provider_2_Operand>) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"array_node needs the two halves"}
    case Some{v_8}:
      match v_5:
        case None{}:
          cps_provider_2_PartFail{"array_node needs the two halves"}
        case Some{v_10}:
          cps_provider_2_PartOk{cps_provider_2_join_text(["blk_node(e, ", cps_provider_2_keep_text(v_8), ", ", cps_provider_2_keep_text(v_10), ")"])}

def cps_provider_2_array_is_cond(+v_1: Nat, +v_3: cps_provider_2_Operand) -> String:
  match v_1:
    case 0n:
      cps_provider_2_join_text(["((u32)blk_cls(", cps_provider_2_operand_text(v_3), ") == 0)"])
    case _:
      cps_provider_2_join_text(["((u32)blk_cls(", cps_provider_2_operand_text(v_3), ") != 0)"])

def cps_provider_2_array_is_bools(+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: Nat, +v_9: cps_provider_2_Operand) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"the C runtime contract needs the `True` constructor for an array tag test"}
    case Some{v_12}:
      match v_5:
        case None{}:
          cps_provider_2_PartFail{"the C runtime contract needs the `False` constructor for an array tag test"}
        case Some{v_14}:
          cps_provider_2_PartOk{cps_provider_2_join_text(["bend_bool(e, ", v_12, ", ", v_14, ", (u64)", cps_provider_2_array_is_cond(v_7, v_9), ")"])}

def cps_provider_2_array_is_ops(+v_2: Maybe<&2, cps_provider_2_Operand>, +v_4: Nat, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case Some{v_9}:
      cps_provider_2_array_is_bools(cps_provider_2_cid_text("True", v_6), cps_provider_2_cid_text("False", v_6), v_4, v_9)
    case None{}:
      cps_provider_2_PartFail{"an array tag test needs the array"}

def cps_provider_2_array_new_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      cps_provider_2_array_new_ops(cps_provider_2_operand_at(v_4, 0n), cps_provider_2_operand_at(v_4, 1n), v_6, v_14, v_15, v_16, v_17)

def cps_provider_2_array_get_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      cps_provider_2_array_get_ops(cps_provider_2_operand_at(v_4, 0n), cps_provider_2_operand_at(v_4, 1n), v_6, v_14, v_15, v_17)

def cps_provider_2_array_set_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      cps_provider_2_array_set_ops(cps_provider_2_operand_at(v_4, 0n), cps_provider_2_operand_at(v_4, 1n), cps_provider_2_operand_at(v_4, 2n), v_6, v_14, v_15, v_16, v_17)

def cps_provider_2_array_swap_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      cps_provider_2_array_swap_ops(cps_provider_2_operand_at(v_4, 0n), cps_provider_2_operand_at(v_4, 1n), cps_provider_2_operand_at(v_4, 2n), v_6, v_14, v_15, v_16, v_17)

def cps_provider_2_array_size_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      cps_provider_2_array_size_ops(cps_provider_2_operand_at(v_4, 0n), v_6, v_17)

def cps_provider_2_array_clone_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      cps_provider_2_array_clone_ops(cps_provider_2_operand_at(v_4, 0n), v_6)

def cps_provider_2_array_leaf_cell(+v_1: cps_provider_2_CellOut, +v_4: List<&2, cps_provider_2_Operand>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_CellFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_CellOk{v_14, v_15, v_16, v_17}:
      cps_provider_2_array_leaf_ops(cps_provider_2_operand_at(v_4, 0n), v_6, v_14, v_15, v_16, v_17)

def native_match_cps_provider_2_array_part_0(v_8: Bool, +v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World) -> cps_provider_2_Part:
  match v_8:
    case True{}:
      cps_provider_2_atomic_pargs(v_0, v_3, v_7)
    case False{}:
      cps_provider_2_array_cell_part(v_0, v_3, v_5, v_7)

def cps_provider_2_array_part(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_array_part_0(cps_provider_2_is_atomic_primitive(v_0), v_0, v_3, v_5, v_7)

def cps_provider_2_array_cell_part(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World) -> cps_provider_2_Part:
  match v_0:
    case BIR.PrimArrayNew{}:
      cps_provider_2_array_new_cell(cps_provider_2_array_cell(v_7, v_5, v_0), v_3, v_7)
    case BIR.PrimArrayGet{}:
      cps_provider_2_array_get_cell(cps_provider_2_array_cell(v_7, v_5, v_0), v_3, v_7)
    case BIR.PrimArraySet{}:
      cps_provider_2_array_set_cell(cps_provider_2_array_cell(v_7, v_5, v_0), v_3, v_7)
    case BIR.PrimArraySwap{}:
      cps_provider_2_array_swap_cell(cps_provider_2_array_cell(v_7, v_5, v_0), v_3, v_7)
    case BIR.PrimArraySize{}:
      cps_provider_2_array_size_cell(cps_provider_2_array_cell(v_7, v_5, v_0), v_3, v_7)
    case BIR.PrimArrayClone{}:
      cps_provider_2_array_clone_cell(cps_provider_2_array_cell(v_7, v_5, v_0), v_3, v_7)
    case BIR.PrimArrayLeaf{}:
      cps_provider_2_array_leaf_cell(cps_provider_2_array_cell(v_7, v_5, v_0), v_3, v_7)
    case BIR.PrimArrayNode{}:
      cps_provider_2_array_node_ops(cps_provider_2_operand_at(v_3, 0n), cps_provider_2_operand_at(v_3, 1n))
    case BIR.PrimIsArrayLeaf{}:
      cps_provider_2_array_is_ops(cps_provider_2_operand_at(v_3, 0n), 0n, v_7)
    case BIR.PrimIsArrayNode{}:
      cps_provider_2_array_is_ops(cps_provider_2_operand_at(v_3, 0n), 1n, v_7)
    case _:
      cps_provider_2_PartFail{"this primitive is not an array operation"}

def cps_provider_2_is_atomic_primitive(+v_0: BIR.Primitive) -> Bool:
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

def cps_provider_2_is_array_primitive(+v_0: BIR.Primitive) -> Bool:
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

def native_match_cps_provider_2_map_offsets_0(v_26: Bool, +v_1: Nat, +v_3: String, v_22: List<&2, cps_provider_1_NodeSlot>) -> cps_provider_2_Part:
  match v_26:
    case False{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the map node `", v_3, "` does not declare exactly ", Nat.show(v_1), " live fields, so Base's Map.find cannot read it"])}
    case True{}:
      cps_provider_2_map_offsets_walk(v_3, v_22, [])

def native_match_cps_provider_2_map_offsets_1(v_17: cps_provider_1_Node, +v_1: Nat, +v_3: String) -> cps_provider_2_Part:
  match v_17:
    case cps_provider_1_Node{v_21, v_22, v_23}:
      native_match_cps_provider_2_map_offsets_0(Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_22), v_1), v_1, v_3, v_22)

def native_match_cps_provider_2_map_offsets_2(v_25: cps_provider_1_NodeResult, +v_1: Nat, +v_3: String) -> cps_provider_2_Part:
  match v_25:
    case cps_provider_1_NodeFailed{v_15}:
      cps_provider_2_PartFail{v_15}
    case cps_provider_1_NodeFound{v_17}:
      native_match_cps_provider_2_map_offsets_1(v_17, v_1, v_3)

def native_match_cps_provider_2_map_offsets_3(+v_5: cps_provider_2_World, +v_1: Nat, +v_3: String) -> cps_provider_2_Part:
  match v_5:
    case cps_provider_2_World{v_10, v_11, v_12}:
      native_match_cps_provider_2_map_offsets_2(cps_provider_1_node_layout(v_10, v_3), v_1, v_3)

def cps_provider_2_map_offsets(+v_1: Nat, +v_3: String, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_map_offsets_3(v_5, v_1, v_3)

def native_match_cps_provider_2_map_offsets_walk_0(v_20: Bool, +v_1: String, +v_7: List<&2, String>, v_13: List<&2, cps_provider_1_NodeSlot>, v_18: Nat) -> cps_provider_2_Part:
  match v_20:
    case False{}:
      cps_provider_2_PartFail{cps_provider_2_join_text(["the map node `", v_1, "` stores a field wider than one word, so Base's Map.find cannot index it"])}
    case True{}:
      cps_provider_2_map_offsets_walk(v_1, v_13, Nat.show(v_18) <> v_7)

def native_match_cps_provider_2_map_offsets_walk_1(+v_12: cps_provider_1_NodeSlot, +v_1: String, +v_7: List<&2, String>, v_13: List<&2, cps_provider_1_NodeSlot>) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_1_NodeSlot{v_17, v_18, v_19}:
      native_match_cps_provider_2_map_offsets_walk_0(Nat.is_eq(cps_provider_1_layout_words(v_19), 1n), v_1, v_7, v_13, v_18)

def native_match_cps_provider_2_map_offsets_walk_2(+v_4: List<&2, cps_provider_1_NodeSlot>, +v_1: String, +v_7: List<&2, String>) -> cps_provider_2_Part:
  match v_4:
    case []:
      cps_provider_2_PartOk{String.join(List.reverse(&2, String, v_7), ", ")}
    case +v_12 <> v_13:
      native_match_cps_provider_2_map_offsets_walk_1(v_12, v_1, v_7, v_13)

def cps_provider_2_map_offsets_walk(+v_1: String, +v_4: List<&2, cps_provider_1_NodeSlot>, +v_7: List<&2, String>) -> cps_provider_2_Part:
  native_match_cps_provider_2_map_offsets_walk_2(v_4, v_1, v_7)

def cps_provider_2_map_find_missing(+v_1: String) -> cps_provider_2_Part:
  cps_provider_2_PartFail{cps_provider_2_join_text(["the program has no `", v_1, "` constructor, which the C runtime contract requires"])}

def native_match_cps_provider_2_map_find_text_0(v_26: Maybe<&2, U32>, +v_1: String, +v_3: String, +v_5: cps_provider_2_World, +v_10: U32, +v_14: U32, +v_18: U32) -> cps_provider_2_Part:
  match v_26:
    case None{}:
      cps_provider_2_map_find_missing("None")
    case Some{+v_22}:
      cps_provider_2_map_find_build(v_1, v_3, v_10, v_14, v_18, v_22, v_5)

def native_match_cps_provider_2_map_find_text_1(v_25: Maybe<&2, U32>, +v_1: String, +v_3: String, +v_5: cps_provider_2_World, +v_10: U32, +v_14: U32) -> cps_provider_2_Part:
  match v_25:
    case None{}:
      cps_provider_2_map_find_missing("Some")
    case Some{+v_18}:
      native_match_cps_provider_2_map_find_text_0(cps_provider_2_cid_of("None", v_5), v_1, v_3, v_5, v_10, v_14, v_18)

def native_match_cps_provider_2_map_find_text_2(v_24: Maybe<&2, U32>, +v_1: String, +v_3: String, +v_5: cps_provider_2_World, +v_10: U32) -> cps_provider_2_Part:
  match v_24:
    case None{}:
      cps_provider_2_map_find_missing("MLeaf")
    case Some{+v_14}:
      native_match_cps_provider_2_map_find_text_1(cps_provider_2_cid_of("Some", v_5), v_1, v_3, v_5, v_10, v_14)

def native_match_cps_provider_2_map_find_text_3(v_23: Maybe<&2, U32>, +v_1: String, +v_3: String, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  match v_23:
    case None{}:
      cps_provider_2_map_find_missing("MNode")
    case Some{+v_10}:
      native_match_cps_provider_2_map_find_text_2(cps_provider_2_cid_of("MLeaf", v_5), v_1, v_3, v_5, v_10)

def cps_provider_2_map_find_text(+v_1: String, +v_3: String, +v_5: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_map_find_text_3(cps_provider_2_cid_of("MNode", v_5), v_1, v_3, v_5)

def native_match_cps_provider_2_map_find_build_0(v_43: cps_provider_2_Part, +v_1: String, +v_3: String, +v_5: U32, +v_7: U32, v_19: String, v_20: String, v_25: String) -> cps_provider_2_Part:
  match v_43:
    case cps_provider_2_PartFail{v_28}:
      cps_provider_2_PartFail{v_28}
    case cps_provider_2_PartOk{v_30}:
      cps_provider_2_PartOk{cps_provider_2_map_find_expr(v_1, v_3, v_5, v_7, v_19, v_20, v_25, v_30)}

def native_match_cps_provider_2_map_find_build_1(v_42: cps_provider_2_Part, +v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_11: U32, +v_13: cps_provider_2_World, v_19: String, v_20: String) -> cps_provider_2_Part:
  match v_42:
    case cps_provider_2_PartFail{v_23}:
      cps_provider_2_PartFail{v_23}
    case cps_provider_2_PartOk{v_25}:
      native_match_cps_provider_2_map_find_build_0(cps_provider_2_construct_part(v_11, [], v_13), v_1, v_3, v_5, v_7, v_19, v_20, v_25)

def native_match_cps_provider_2_map_find_build_2(v_40: cps_provider_2_Part, v_41: cps_provider_2_Part, +v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: U32, +v_11: U32, +v_13: cps_provider_2_World) -> cps_provider_2_Part:
  match v_40, v_41:
    case cps_provider_2_PartOk{v_19}, cps_provider_2_PartOk{v_20}:
      native_match_cps_provider_2_map_find_build_1(cps_provider_2_construct_part(v_9, [cps_provider_2_Operand{BIR.Affine{}, "mfm"}], v_13), v_1, v_3, v_5, v_7, v_11, v_13, v_19, v_20)
    case cps_provider_2_PartFail{v_34}, _:
      cps_provider_2_PartFail{v_34}
    case _, cps_provider_2_PartFail{v_39}:
      cps_provider_2_PartFail{v_39}

def cps_provider_2_map_find_build(+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: U32, +v_11: U32, +v_13: cps_provider_2_World) -> cps_provider_2_Part:
  native_match_cps_provider_2_map_find_build_2(cps_provider_2_map_offsets(3n, "MNode", v_13), cps_provider_2_map_offsets(2n, "MLeaf", v_13), v_1, v_3, v_5, v_7, v_9, v_11, v_13)

def cps_provider_2_map_find_expr(+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: String, +v_11: String, +v_13: String, +v_15: String) -> String:
  cps_provider_2_join_text(["({\n  Term mfm = 0;\n  u32 mfh = (u32)map_find_read(e, ", U32.show(v_5), "u, ", U32.show(v_7), "u, ", v_9, ", ", v_11, ", ", v_1, ", ", v_3, ", &mfm);\n  mfh ? ", v_13, " : ", v_15, ";\n})"])

def cps_provider_2_map_find_operands(+v_2: List<&2, cps_provider_2_Operand>, +v_4: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case [v_8, v_9]:
      cps_provider_2_map_find_text(cps_provider_2_operand_text(v_8), cps_provider_2_operand_text(v_9), v_4)
    case _:
      cps_provider_2_PartFail{"Base's Map.find takes the map and the query key"}

def cps_provider_2_map_find_names(+v_2: List<&2, String>, +v_4: cps_provider_2_World) -> cps_provider_2_Part:
  match v_2:
    case [v_8, v_9]:
      cps_provider_2_map_find_text(v_8, v_9, v_4)
    case _:
      cps_provider_2_PartFail{"Base's Map.find takes the map and the query key"}

def cps_provider_2_map_find_part(+v_2: List<&2, cps_provider_2_Operand>, +v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_World) -> cps_provider_2_Part:
  match v_4:
    case []:
      cps_provider_2_PartFail{"the map read `Map.find` carries no instantiated value Descriptor; lowering must supply PrimitiveCall.types"}
    case [_]:
      cps_provider_2_map_find_operands(v_2, v_6)
    case _:
      cps_provider_2_PartFail{"the map read `Map.find` must carry exactly one instantiated value Descriptor"}

def cps_provider_2_descriptor_part(+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_2_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_2_World) -> cps_provider_2_Part:
  match v_0:
    case BIR.PrimMapFind{}:
      cps_provider_2_map_find_part(v_3, v_5, v_7)
    case _:
      cps_provider_2_array_part(v_0, v_3, v_5, v_7)

def cps_provider_2_show_state0() -> cps_provider_2_ShowState:
  cps_provider_2_ShowState{[], [], Map.new(&2, Nat), [], None{}}

def cps_provider_2_show_words(+v_1: cps_provider_2_ShowState) -> List<&2, cps_provider_2_ShowWord>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_9

def cps_provider_2_show_patches(+v_1: cps_provider_2_ShowState) -> List<&2, cps_provider_2_ShowPatch>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_10

def cps_provider_2_show_memo(+v_1: cps_provider_2_ShowState) -> Map<&2, Nat>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_11

def cps_provider_2_show_names(+v_1: cps_provider_2_ShowState) -> List<&2, String>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_12

def cps_provider_2_show_error(+v_1: cps_provider_2_ShowState) -> Maybe<&2, String>:
  match v_1:
    case cps_provider_2_ShowState{v_9, v_10, v_11, v_12, v_13}:
      v_13

def cps_provider_2_show_state_set_memo(+v_1: cps_provider_2_ShowState, +v_4: Map<&2, Nat>) -> cps_provider_2_ShowState:
  match v_1:
    case cps_provider_2_ShowState{v_11, v_12, v_13, v_14, v_15}:
      cps_provider_2_ShowState{v_11, v_12, v_4, v_14, v_15}

def cps_provider_2_show_state_error(+v_1: cps_provider_2_ShowState, +v_3: String) -> cps_provider_2_ShowState:
  match v_1:
    case cps_provider_2_ShowState{v_10, v_11, v_12, v_13, v_14}:
      cps_provider_2_ShowState{v_10, v_11, v_12, v_13, Some{v_3}}

def cps_provider_2_show_next_state(+v_1: cps_provider_2_ShowAdvance) -> cps_provider_2_ShowState:
  match v_1:
    case cps_provider_2_ShowNext{v_5, v_6}:
      v_5

def cps_provider_2_show_next_kids(+v_1: cps_provider_2_ShowAdvance) -> List<&2, cps_provider_2_ShowJob>:
  match v_1:
    case cps_provider_2_ShowNext{v_6, v_7}:
      v_7

def cps_provider_2_show_append_word(+v_1: cps_provider_2_ShowState, +v_3: cps_provider_2_ShowWord) -> cps_provider_2_ShowState:
  match v_1:
    case cps_provider_2_ShowState{v_10, v_11, v_12, v_13, v_14}:
      cps_provider_2_ShowState{List.append(&2, cps_provider_2_ShowWord, v_10, [v_3]), v_11, v_12, v_13, v_14}

def cps_provider_2_show_append_num(+v_1: cps_provider_2_ShowState, +v_3: Nat) -> cps_provider_2_ShowState:
  cps_provider_2_show_append_word(v_1, cps_provider_2_ShowNum{v_3})

def cps_provider_2_show_append_cid(+v_1: cps_provider_2_ShowState, +v_3: Nat) -> cps_provider_2_ShowState:
  cps_provider_2_show_append_word(v_1, cps_provider_2_ShowCid{v_3})

def cps_provider_2_show_append_name(+v_1: cps_provider_2_ShowState, +v_3: String) -> cps_provider_2_ShowState:
  match v_1:
    case cps_provider_2_ShowState{v_10, v_11, v_12, v_13, v_14}:
      cps_provider_2_ShowState{v_10, v_11, v_12, List.append(&2, String, v_13, [v_3]), v_14}

def cps_provider_2_show_append_patch(+v_1: cps_provider_2_ShowState, +v_3: Nat, +v_5: Nat) -> cps_provider_2_ShowState:
  match v_1:
    case cps_provider_2_ShowState{v_12, v_13, v_14, v_15, v_16}:
      cps_provider_2_ShowState{v_12, List.append(&2, cps_provider_2_ShowPatch, [cps_provider_2_ShowPatchAt{v_3, v_5}], v_13), v_14, v_15, v_16}

def cps_provider_2_show_apply_patch(+v_1: cps_provider_2_ShowState, +v_4: Maybe<&2, Nat>, +v_6: Nat) -> cps_provider_2_ShowState:
  match v_4:
    case Some{v_9}:
      cps_provider_2_show_append_patch(v_1, v_9, v_6)
    case None{}:
      v_1

def cps_provider_2_show_native_kind(+v_1: String) -> cps_provider_2_ShowKind:
  match v_1:
    case "U32":
      cps_provider_2_ShowKindOk{0n}
    case "F32":
      cps_provider_2_ShowKindOk{1n}
    case "Nat":
      cps_provider_2_ShowKindOk{2n}
    case "Char":
      cps_provider_2_ShowKindOk{3n}
    case "String":
      cps_provider_2_ShowKindOk{4n}
    case "Array":
      cps_provider_2_ShowKindOk{6n}
    case _:
      cps_provider_2_ShowKindOk{7n}

def native_match_cps_provider_2_show_kind_family_0(v_16: Maybe<&2, String>) -> cps_provider_2_ShowKind:
  match v_16:
    case Some{v_21}:
      cps_provider_2_show_native_kind(v_21)
    case None{}:
      cps_provider_2_ShowKindOk{7n}

def native_match_cps_provider_2_show_kind_family_1(v_23: Bool, v_16: Maybe<&2, String>) -> cps_provider_2_ShowKind:
  match v_23:
    case True{}:
      cps_provider_2_ShowKindFailed{"main's type IO.OP cannot be printed as data"}
    case False{}:
      native_match_cps_provider_2_show_kind_family_0(v_16)

def native_match_cps_provider_2_show_kind_family_2(v_7: BIR.Family) -> cps_provider_2_ShowKind:
  match v_7:
    case BIR.Family{v_14, v_15, v_16, v_17, v_18, v_19}:
      native_match_cps_provider_2_show_kind_family_1(String.eq(v_14, "IO.OP"), v_16)

def native_match_cps_provider_2_show_kind_family_3(v_22: Maybe<&2, BIR.Family>) -> cps_provider_2_ShowKind:
  match v_22:
    case None{}:
      cps_provider_2_ShowKindFailed{"main's type is a type former and cannot be printed"}
    case Some{v_7}:
      native_match_cps_provider_2_show_kind_family_2(v_7)

def cps_provider_2_show_kind_family(+v_1: String, +v_3: cps_provider_1_Context) -> cps_provider_2_ShowKind:
  native_match_cps_provider_2_show_kind_family_3(cps_provider_1_family_lookup(v_3, v_1))

def cps_provider_2_show_kind_head(+v_0: cps_provider_1_HeadResult, +v_1: cps_provider_1_Context) -> cps_provider_2_ShowKind:
  match v_0:
    case cps_provider_1_HeadFailed{v_4}:
      cps_provider_2_ShowKindFailed{v_4}
    case cps_provider_1_HeadEquality{}:
      cps_provider_2_ShowKindOk{5n}
    case cps_provider_1_HeadBoxed{v_6}:
      cps_provider_2_ShowKindFailed{"main's type is abstract or open and cannot be printed"}
    case cps_provider_1_HeadFound{v_9, v_10}:
      cps_provider_2_show_kind_family(v_9, v_1)

def cps_provider_2_show_kind(+v_0: cps_provider_1_Context, +v_1: BIR.Descriptor) -> cps_provider_2_ShowKind:
  v_4 = cps_provider_1_head_native(v_0, v_1)
  cps_provider_2_show_kind_head(v_4, v_0)

def cps_provider_2_show_box_flag(+v_0: cps_provider_1_Layout) -> Nat:
  match v_0:
    case cps_provider_1_LayoutBox{v_3}:
      1n
    case _:
      0n

def cps_provider_2_show_tag_plain(+v_1: Nat) -> Nat:
  match v_1:
    case 0n:
      0n
    case 1n:
      0n
    case _:
      1n

def cps_provider_2_show_tag_start(+v_1: Nat, +v_3: Nat) -> Nat:
  match v_1:
    case 1n:
      0n
    case _:
      cps_provider_2_show_tag_plain(v_3)

def cps_provider_2_show_quote(+v_1: String) -> String:
  cps_provider_2_join_text(["\"", v_1, "\""])

def cps_provider_2_show_name_sep(+v_2: List<&2, String>) -> String:
  match v_2:
    case []:
      ""
    case _:
      ","

def cps_provider_2_show_render_names(+v_2: List<&2, String>) -> String:
  match v_2:
    case []:
      ""
    case +v_6 <> +v_7:
      String.append(String.append(cps_provider_2_show_quote(v_6), cps_provider_2_show_name_sep(v_7)), cps_provider_2_show_render_names(v_7))

def cps_provider_2_show_render_sep_flag(+v_1: Bool) -> String:
  match v_1:
    case True{}:
      ""
    case False{}:
      ","

def cps_provider_2_show_render_sep(+v_1: String) -> String:
  v_4 = String.is_empty(v_1)
  cps_provider_2_show_render_sep_flag(v_4)

def cps_provider_2_show_render_word(+v_1: cps_provider_2_ShowWord) -> String:
  match v_1:
    case cps_provider_2_ShowNum{v_4}:
      Nat.show(v_4)
    case cps_provider_2_ShowCid{v_6}:
      cps_provider_2_join_text(["CID_", Nat.show(v_6)])

def cps_provider_2_show_render_words(+v_2: List<&2, cps_provider_2_ShowWord>, +v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case +v_8 <> +v_9:
      cps_provider_2_show_render_words(v_9, cps_provider_2_join_text([v_4, cps_provider_2_show_render_sep(v_4), cps_provider_2_show_render_word(v_8)]))

def cps_provider_2_family_arms(+v_1: String, +v_3: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match v_3:
    case []:
      None{}
    case +v_8 <> +v_9:
      match v_8:
        case BIR.Family{v_16, v_17, v_18, v_19, v_20, v_21}:
          v_23 = String.eq(v_1, v_16)
          Bool.pick(Maybe<&2, List<&2, BIR.DescriptorArm>>, v_23, Some{v_21}, cps_provider_2_family_arms(v_1, v_9))

def cps_provider_2_ctor_find_key(+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_3:
    case []:
      None{}
    case +v_7 <> +v_8:
      match v_7:
        case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
          v_18 = String.eq(v_14, v_1)
          Bool.pick(Maybe<&2, BIR.ConstructorLayout>, v_18, Some{v_7}, cps_provider_2_ctor_find_key(v_1, v_8))

def cps_provider_2_show_cid_found(+v_1: Maybe<&2, BIR.ConstructorLayout>) -> Maybe<&2, Nat>:
  match v_1:
    case None{}:
      None{}
    case Some{v_5}:
      match v_5:
        case BIR.ConstructorLayout{v_10, v_11, v_12, v_13}:
          Some{U32.to_nat(v_10)}

def cps_provider_2_show_cid_of_key(+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, Nat>:
  cps_provider_2_show_cid_found(cps_provider_2_ctor_find_key(v_1, v_3))

def cps_provider_2_show_arm_bracket_name(+v_1: String) -> Nat:
  match v_1:
    case "Tuple":
      2n
    case "Con":
      1n
    case "Nil":
      1n
    case _:
      0n

def cps_provider_2_show_arm_bracket(+v_1: String) -> Nat:
  cps_provider_2_show_arm_bracket_name(v_1)

def cps_provider_2_show_erased_present(+v_1: List<&2, BIR.DescriptorField>) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_5 <> +v_6:
      match v_5:
        case BIR.DescriptorField{v_10, v_11, v_12}:
          match v_11:
            case BIR.Erased{}:
              True{}
            case _:
              cps_provider_2_show_erased_present(v_6)

def cps_provider_2_show_field_at_each(+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat) -> Maybe<&2, BIR.DescriptorField>:
  match v_1:
    case []:
      None{}
    case +v_9 <> +v_10:
      v_12 = Nat.is_eq(v_5, v_3)
      Bool.pick(Maybe<&2, BIR.DescriptorField>, v_12, Some{v_9}, cps_provider_2_show_field_at_each(v_10, v_3, Nat.add(v_5, 1n)))

def cps_provider_2_show_field_at(+v_1: List<&2, BIR.DescriptorField>, +v_3: U32) -> Maybe<&2, BIR.DescriptorField>:
  cps_provider_2_show_field_at_each(v_1, U32.to_nat(v_3), 0n)

def cps_provider_2_show_arm_layouts_each(+v_1: List<&2, cps_provider_1_LayArm>, +v_3: String) -> Maybe<&2, List<&2, cps_provider_1_Layout>>:
  match v_1:
    case []:
      None{}
    case +v_8 <> +v_9:
      match v_8:
        case cps_provider_1_LayArm{v_12, v_13}:
          v_15 = String.eq(v_12, v_3)
          Bool.pick(Maybe<&2, List<&2, cps_provider_1_Layout>>, v_15, Some{v_13}, cps_provider_2_show_arm_layouts_each(v_9, v_3))

def cps_provider_2_show_arm_layouts(+v_0: cps_provider_1_Layout, +v_2: String) -> Maybe<&2, List<&2, cps_provider_1_Layout>>:
  match v_0:
    case cps_provider_1_LayoutWord{v_6}:
      None{}
    case cps_provider_1_LayoutBox{v_8}:
      None{}
    case cps_provider_1_LayoutData{v_11, v_12}:
      cps_provider_2_show_arm_layouts_each(v_12, v_2)

def cps_provider_2_show_node_layout_slots(+v_0: cps_provider_1_NodeResult) -> Maybe<&2, List<&2, cps_provider_1_NodeSlot>>:
  match v_0:
    case cps_provider_1_NodeFailed{v_4}:
      None{}
    case cps_provider_1_NodeFound{v_6}:
      match v_6:
        case cps_provider_1_Node{v_10, v_11, v_12}:
          Some{v_11}

def cps_provider_2_show_word_key(+v_0: cps_provider_1_CWord) -> String:
  match v_0:
    case cps_provider_1_CWord32{}:
      "32"
    case cps_provider_1_CWord64{}:
      "64"
    case cps_provider_1_CWordBox{}:
      "x"

def cps_provider_2_show_box_key(+v_0: cps_provider_1_BoxReason) -> String:
  match v_0:
    case cps_provider_1_BoxOpen{}:
      "open"
    case cps_provider_1_BoxUnresolved{v_3}:
      cps_provider_2_join_text(["U", cps_provider_2_lk_text(v_3)])
    case cps_provider_1_BoxArray{}:
      "array"
    case cps_provider_1_BoxIo{}:
      "io"
    case cps_provider_1_BoxRecursive{v_7}:
      cps_provider_2_join_text(["R", cps_provider_2_lk_text(v_7)])
    case cps_provider_1_BoxWide{v_11}:
      cps_provider_2_join_text(["wide:", Nat.show(v_11)])

def cps_provider_2_lk_text(+v_1: String) -> String:
  cps_provider_2_join_text([Nat.show(String.length(v_1)), ":", v_1])

def cps_provider_2_lk_words(+v_1: List<&2, cps_provider_1_CWord>) -> String:
  match v_1:
    case []:
      ""
    case +v_5 <> +v_6:
      cps_provider_2_join_text([cps_provider_2_show_word_key(v_5), ",", cps_provider_2_lk_words(v_6)])

def cps_provider_2_lk_fields(+v_1: List<&2, cps_provider_1_Layout>) -> String:
  match v_1:
    case []:
      ""
    case +v_5 <> +v_6:
      cps_provider_2_join_text([cps_provider_2_show_layout_key(v_5), ",", cps_provider_2_lk_fields(v_6)])

def cps_provider_2_lk_arms(+v_1: List<&2, cps_provider_1_LayArm>) -> String:
  match v_1:
    case []:
      ""
    case +v_5 <> +v_6:
      match v_5:
        case cps_provider_1_LayArm{v_9, v_10}:
          cps_provider_2_join_text(["A", cps_provider_2_lk_text(v_9), ":", Nat.show(List.length(&2, cps_provider_1_Layout, v_10)), ":", cps_provider_2_lk_fields(v_10), ";", cps_provider_2_lk_arms(v_6)])

def cps_provider_2_show_layout_key(+v_0: cps_provider_1_Layout) -> String:
  match v_0:
    case cps_provider_1_LayoutWord{v_3}:
      cps_provider_2_join_text(["w", cps_provider_2_show_word_key(v_3)])
    case cps_provider_1_LayoutBox{v_7}:
      cps_provider_2_join_text(["B", cps_provider_2_show_box_key(v_7)])
    case cps_provider_1_LayoutData{v_12, v_13}:
      cps_provider_2_join_text(["D", Nat.show(List.length(&2, cps_provider_1_CWord, v_12)), ":", cps_provider_2_lk_words(v_12), ":", Nat.show(List.length(&2, cps_provider_1_LayArm, v_13)), ":", cps_provider_2_lk_arms(v_13)])

def cps_provider_2_show_arg_tokens(+v_1: List<&2, BIR.Descriptor>, +v_3: Bool) -> List<&2, cps_provider_2_ShowToken>:
  match v_1:
    case []:
      []
    case +v_8 <> +v_9:
      v_13 = Bool.pick(List<&2, cps_provider_2_ShowToken>, v_3, [], [cps_provider_2_ShowTokText{","}])
      List.append(&2, cps_provider_2_ShowToken, v_13, List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokDesc{v_8}], cps_provider_2_show_arg_tokens(v_9, False{})))

def cps_provider_2_show_quantity_key(+v_0: BIR.Quantity) -> String:
  match v_0:
    case BIR.Erased{}:
      "0"
    case BIR.Once{}:
      "1"
    case BIR.Unrestricted{}:
      "2"

def cps_provider_2_show_maybe_quantity_key(+v_1: Maybe<&2, BIR.Quantity>) -> String:
  match v_1:
    case None{}:
      "-"
    case Some{v_4}:
      cps_provider_2_show_quantity_key(v_4)

def cps_provider_2_show_pat_tokens(+v_1: List<&2, BIR.DescriptorPattern>, +v_3: Bool) -> List<&2, cps_provider_2_ShowToken>:
  match v_1:
    case []:
      []
    case +v_8 <> +v_9:
      v_13 = Bool.pick(List<&2, cps_provider_2_ShowToken>, v_3, [], [cps_provider_2_ShowTokText{","}])
      List.append(&2, cps_provider_2_ShowToken, v_13, List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokPat{v_8}], cps_provider_2_show_pat_tokens(v_9, False{})))

def cps_provider_2_show_pat_expand(+v_0: BIR.DescriptorPattern) -> List<&2, cps_provider_2_ShowToken>:
  match v_0:
    case BIR.DescriptorBinder{v_4}:
      [cps_provider_2_ShowTokText{"b"}, cps_provider_2_ShowTokText{cps_provider_2_show_quantity_key(v_4)}]
    case BIR.DescriptorConstructorPattern{v_8, v_9}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"c"}, cps_provider_2_ShowTokText{v_8}, cps_provider_2_ShowTokText{"("}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_pat_tokens(v_9, True{}), [cps_provider_2_ShowTokText{")"}]))

def cps_provider_2_show_desc_expand(+v_0: BIR.Descriptor) -> List<&2, cps_provider_2_ShowToken>:
  match v_0:
    case BIR.DescriptorRef{v_5, v_6}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"R"}, cps_provider_2_ShowTokText{v_5}, cps_provider_2_ShowTokText{"("}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_arg_tokens(v_6, True{}), [cps_provider_2_ShowTokText{")"}]))
    case BIR.DescriptorApplication{v_12, v_13}:
      [cps_provider_2_ShowTokText{"a"}, cps_provider_2_ShowTokDesc{v_12}, cps_provider_2_ShowTokDesc{v_13}]
    case BIR.DescriptorFill{v_16, v_17}:
      List.append(&2, cps_provider_2_ShowToken, List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"F"}, cps_provider_2_ShowTokDesc{v_16}, cps_provider_2_ShowTokText{"["}], cps_provider_2_show_arg_tokens(v_17, True{})), [cps_provider_2_ShowTokText{"]"}])
    case BIR.DescriptorPlus{v_23, v_24}:
      List.append(&2, cps_provider_2_ShowToken, List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"P"}, cps_provider_2_ShowTokDesc{v_23}, cps_provider_2_ShowTokText{"["}], cps_provider_2_show_arg_tokens(v_24, True{})), [cps_provider_2_ShowTokText{"]"}])
    case BIR.DescriptorNamedFill{v_31, v_32, v_33}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"f"}, cps_provider_2_ShowTokText{v_31}, cps_provider_2_ShowTokDesc{v_32}, cps_provider_2_ShowTokText{"["}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_arg_tokens(v_33, True{}), [cps_provider_2_ShowTokText{"]"}]))
    case BIR.DescriptorNamedPlus{v_40, v_41, v_42}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"q"}, cps_provider_2_ShowTokText{v_40}, cps_provider_2_ShowTokDesc{v_41}, cps_provider_2_ShowTokText{"["}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_arg_tokens(v_42, True{}), [cps_provider_2_ShowTokText{"]"}]))
    case BIR.DescriptorParameter{v_47}:
      [cps_provider_2_ShowTokText{"p"}, cps_provider_2_ShowTokText{Nat.show(v_47)}]
    case BIR.DescriptorNull{}:
      [cps_provider_2_ShowTokText{"n"}]
    case BIR.DescriptorKind{v_49}:
      [cps_provider_2_ShowTokText{"K"}, cps_provider_2_ShowTokDesc{v_49}]
    case BIR.DescriptorQuantity{v_51}:
      [cps_provider_2_ShowTokText{"Q"}, cps_provider_2_ShowTokText{cps_provider_2_show_quantity_key(v_51)}]
    case BIR.DescriptorQuantityKind{}:
      [cps_provider_2_ShowTokText{"Z"}]
    case BIR.DescriptorMinimum{v_55, v_56}:
      [cps_provider_2_ShowTokText{"m"}, cps_provider_2_ShowTokDesc{v_55}, cps_provider_2_ShowTokDesc{v_56}]
    case BIR.DescriptorArrow{v_60, v_61, v_62}:
      [cps_provider_2_ShowTokText{"A"}, cps_provider_2_ShowTokText{cps_provider_2_show_quantity_key(v_60)}, cps_provider_2_ShowTokDesc{v_61}, cps_provider_2_ShowTokDesc{v_62}]
    case BIR.DescriptorLambda{v_66, v_67}:
      [cps_provider_2_ShowTokText{"L"}, cps_provider_2_ShowTokText{cps_provider_2_show_maybe_quantity_key(v_66)}, cps_provider_2_ShowTokDesc{v_67}]
    case BIR.DescriptorConstructor{v_71, v_72}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"C"}, cps_provider_2_ShowTokText{v_71}, cps_provider_2_ShowTokText{"("}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_arg_tokens(v_72, True{}), [cps_provider_2_ShowTokText{")"}]))
    case BIR.DescriptorFailure{v_77}:
      [cps_provider_2_ShowTokText{"!"}, cps_provider_2_ShowTokText{v_77}]
    case BIR.DescriptorSubstitution{v_81, v_82, v_83}:
      [cps_provider_2_ShowTokText{"S"}, cps_provider_2_ShowTokText{Nat.show(v_81)}, cps_provider_2_ShowTokDesc{v_82}, cps_provider_2_ShowTokDesc{v_83}]
    case BIR.DescriptorLet{v_86, v_87}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"E"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_86))}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_arg_tokens(v_86, True{}), [cps_provider_2_ShowTokDesc{v_87}]))
    case BIR.DescriptorLocal{v_94, v_95, v_96}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"l"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.DescriptorPattern, v_94))}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_95))}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_pat_tokens(v_94, True{}), List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_arg_tokens(v_95, True{}), [cps_provider_2_ShowTokDesc{v_96}])))
    case BIR.DescriptorMatch{v_104, v_105}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"M"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_104))}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, v_105))}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_arg_tokens(v_104, True{}), cps_provider_2_show_arg_tokens(v_105, True{})))
    case BIR.DescriptorCase{v_112, v_113}:
      List.append(&2, cps_provider_2_ShowToken, [cps_provider_2_ShowTokText{"c"}, cps_provider_2_ShowTokText{Nat.show(List.length(&2, BIR.DescriptorPattern, v_112))}], List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_pat_tokens(v_112, True{}), [cps_provider_2_ShowTokDesc{v_113}]))
    case BIR.DescriptorBind{v_119, v_120}:
      [cps_provider_2_ShowTokText{"b"}, cps_provider_2_ShowTokDesc{v_119}, cps_provider_2_ShowTokDesc{v_120}]
    case BIR.DescriptorEquality{v_124, v_125, v_126}:
      [cps_provider_2_ShowTokText{"="}, cps_provider_2_ShowTokDesc{v_124}, cps_provider_2_ShowTokDesc{v_125}, cps_provider_2_ShowTokDesc{v_126}]
    case BIR.DescriptorReflexivity{}:
      [cps_provider_2_ShowTokText{"r"}]

def cps_provider_2_show_render_tokens(+v_2: List<&2, cps_provider_2_ShowToken>, +v_4: String) -> Maybe<&2, String>:
  match v_2:
    case []:
      Some{v_4}
    case +v_9 <> +v_10:
      match v_9:
        case cps_provider_2_ShowTokText{v_12}:
          cps_provider_2_show_render_tokens(v_10, cps_provider_2_join_text([v_4, Nat.show(String.length(v_12)), ":", v_12]))
        case cps_provider_2_ShowTokDesc{v_16}:
          cps_provider_2_show_render_tokens(List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_desc_expand(v_16), v_10), v_4)
        case cps_provider_2_ShowTokPat{v_21}:
          cps_provider_2_show_render_tokens(List.append(&2, cps_provider_2_ShowToken, cps_provider_2_show_pat_expand(v_21), v_10), v_4)

def cps_provider_2_show_descriptor_key(+v_0: BIR.Descriptor) -> Maybe<&2, String>:
  cps_provider_2_show_render_tokens([cps_provider_2_ShowTokDesc{v_0}], "")

def cps_provider_2_show_array_cell(+v_0: cps_provider_1_CellResult, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_0:
    case cps_provider_1_CellFailed{v_13}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_10, v_13), []}
    case cps_provider_1_CellFound{v_16}:
      match v_16:
        case cps_provider_1_Cell{v_21, v_22, v_23, v_24}:
          v_29 = cps_provider_2_show_append_num(cps_provider_2_show_append_num(cps_provider_2_show_append_num(v_10, 6n), 0n), v_24)
          cps_provider_2_ShowNext{v_29, [cps_provider_2_ShowNode{v_6, v_21, Some{Nat.add(v_8, 1n)}}]}

def cps_provider_2_show_array_element(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_4: List<&2, BIR.Family>, +v_5: BIR.Descriptor, +v_7: Nat, +v_9: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  v_12 = cps_provider_1_array_cell(v_0, v_5)
  cps_provider_2_show_array_cell(v_12, v_0, v_2, v_4, v_5, v_7, v_9)

def cps_provider_2_show_array_args(+v_0: cps_provider_1_ArgsResult, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_0:
    case cps_provider_1_ArgsFailed{v_13}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_10, v_13), []}
    case cps_provider_1_ArgsOk{v_16}:
      match v_16:
        case +v_19 <> +v_20:
          cps_provider_2_show_array_element(v_1, v_3, v_5, v_19, v_8, v_10)
        case []:
          cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_10, "an Array descriptor without an element type cannot be printed"), []}

def cps_provider_2_show_advance_array(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_4: List<&2, BIR.Family>, +v_5: BIR.Descriptor, +v_7: Nat, +v_9: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  v_12 = cps_provider_1_head_args(v_0, v_5)
  cps_provider_2_show_array_args(v_12, v_0, v_2, v_4, v_5, v_7, v_9)

def cps_provider_2_box_advance(+v_1: cps_provider_2_ShowJob, +v_3: cps_provider_2_ShowAdvance) -> cps_provider_2_ShowAdvance:
  cps_provider_2_ShowNext{cps_provider_2_show_next_state(v_3), List.append(&2, cps_provider_2_ShowJob, [v_1], cps_provider_2_show_next_kids(v_3))}

def native_match_cps_provider_2_fields_box_each_0(+v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_4:
    case []:
      cps_provider_2_ShowNext{v_6, []}
    case _:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_6, "a constructor node's slots and fields differ"), []}

def native_match_cps_provider_2_fields_box_each_1(+v_18: BIR.DescriptorField, +v_6: cps_provider_2_ShowState, +v_14: List<&2, cps_provider_1_NodeSlot>, +v_19: List<&2, BIR.DescriptorField>, v_24: Nat, v_25: cps_provider_1_Layout) -> cps_provider_2_ShowAdvance:
  match v_18:
    case BIR.DescriptorField{v_29, v_30, v_31}:
      cps_provider_2_box_advance(cps_provider_2_ShowNode{v_31, v_25, Some{Nat.add(List.length(&2, cps_provider_2_ShowWord, cps_provider_2_show_words(v_6)), 1n)}}, cps_provider_2_fields_box_each(v_14, v_19, cps_provider_2_show_append_num(cps_provider_2_show_append_num(v_6, v_24), 0n)))

def native_match_cps_provider_2_fields_box_each_2(+v_13: cps_provider_1_NodeSlot, +v_6: cps_provider_2_ShowState, +v_14: List<&2, cps_provider_1_NodeSlot>, +v_18: BIR.DescriptorField, +v_19: List<&2, BIR.DescriptorField>) -> cps_provider_2_ShowAdvance:
  match v_13:
    case cps_provider_1_NodeSlot{v_23, v_24, v_25}:
      native_match_cps_provider_2_fields_box_each_1(v_18, v_6, v_14, v_19, v_24, v_25)

def native_match_cps_provider_2_fields_box_each_3(+v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState, +v_13: cps_provider_1_NodeSlot, +v_14: List<&2, cps_provider_1_NodeSlot>) -> cps_provider_2_ShowAdvance:
  match v_4:
    case []:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_6, "a constructor node's slots and fields differ"), []}
    case +v_18 <> +v_19:
      native_match_cps_provider_2_fields_box_each_2(v_13, v_6, v_14, v_18, v_19)

def native_match_cps_provider_2_fields_box_each_4(+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_2:
    case []:
      native_match_cps_provider_2_fields_box_each_0(v_4, v_6)
    case +v_13 <> +v_14:
      native_match_cps_provider_2_fields_box_each_3(v_4, v_6, v_13, v_14)

def cps_provider_2_fields_box_each(+v_2: List<&2, cps_provider_1_NodeSlot>, +v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  native_match_cps_provider_2_fields_box_each_4(v_2, v_4, v_6)

def cps_provider_2_fields_box_slots(+v_2: Maybe<&2, List<&2, cps_provider_1_NodeSlot>>, +v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_2:
    case None{}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_6, "a constructor node has no slots for SHOW"), []}
    case Some{v_10}:
      cps_provider_2_fields_box_each(v_10, v_4, v_6)

def cps_provider_2_fields_box(+v_0: cps_provider_1_Context, +v_2: String, +v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  v_9 = cps_provider_1_node_layout(v_0, v_2)
  v_12 = cps_provider_2_show_node_layout_slots(v_9)
  cps_provider_2_fields_box_slots(v_12, v_4, v_6)

def cps_provider_2_fields_inline_each(+v_1: List<&2, cps_provider_1_Layout>, +v_3: List<&2, BIR.DescriptorField>, +v_5: Nat, +v_7: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_1:
    case []:
      match v_3:
        case []:
          cps_provider_2_ShowNext{v_7, []}
        case _:
          cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_7, "an inline arm's fields and layouts differ"), []}
    case +v_14 <> +v_15:
      match v_3:
        case []:
          cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_7, "an inline arm's fields and layouts differ"), []}
        case +v_19 <> +v_20:
          match v_19:
            case BIR.DescriptorField{v_24, v_25, v_26}:
              v_30 = Nat.add(List.length(&2, cps_provider_2_ShowWord, cps_provider_2_show_words(v_7)), 1n)
              v_34 = cps_provider_2_show_append_num(cps_provider_2_show_append_num(v_7, v_5), 0n)
              v_37 = cps_provider_2_fields_inline_each(v_15, v_20, Nat.add(v_5, cps_provider_1_layout_words(v_14)), v_34)
              cps_provider_2_ShowNext{cps_provider_2_show_next_state(v_37), List.append(&2, cps_provider_2_ShowJob, [cps_provider_2_ShowNode{v_26, v_14, Some{v_30}}], cps_provider_2_show_next_kids(v_37))}

def cps_provider_2_fields_inline_layouts(+v_2: Maybe<&2, List<&2, cps_provider_1_Layout>>, +v_4: List<&2, BIR.DescriptorField>, +v_6: Nat, +v_8: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_2:
    case None{}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_8, "the inline layout has no SHOW arm"), []}
    case Some{v_12}:
      cps_provider_2_fields_inline_each(v_12, v_4, v_6, v_8)

def cps_provider_2_fields_inline(+v_0: cps_provider_1_Context, +v_2: String, +v_4: List<&2, BIR.DescriptorField>, +v_5: cps_provider_1_Layout, +v_7: Nat, +v_9: Nat, +v_11: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  v_15 = cps_provider_2_show_arm_layouts(v_5, v_2)
  cps_provider_2_fields_inline_layouts(v_15, v_4, v_9, v_11)

def cps_provider_2_fields_advance(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_4: List<&2, BIR.Family>, +v_6: String, +v_8: List<&2, BIR.DescriptorField>, +v_9: cps_provider_1_Layout, +v_11: Nat, +v_13: Nat, +v_15: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_11:
    case 1n:
      cps_provider_2_fields_box(v_0, v_6, v_8, v_15)
    case _:
      cps_provider_2_fields_inline(v_0, v_6, v_8, v_9, v_13, cps_provider_2_show_tag_start(v_11, v_13), v_15)

def cps_provider_2_show_data_arm_header(+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_8: List<&2, BIR.ConstructorLayout>, +v_10: List<&2, BIR.Family>, +v_11: cps_provider_3_NfVal, +v_12: cps_provider_1_Layout, +v_14: Nat, +v_16: Nat, +v_18: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  cps_provider_2_show_data_arm_cid(cps_provider_2_show_cid_of_key(v_3, v_8), v_1, v_3, v_5, v_6, v_8, v_10, v_11, v_12, v_14, v_16, v_18)

def native_match_cps_provider_2_show_data_arm_rest_0(v_29: cps_provider_2_ShowAdvance, v_22: List<&2, cps_provider_2_ShowJob>) -> cps_provider_2_ShowAdvance:
  match v_29:
    case cps_provider_2_ShowNext{v_26, v_27}:
      cps_provider_2_ShowNext{v_26, List.append(&2, cps_provider_2_ShowJob, v_22, v_27)}

def native_match_cps_provider_2_show_data_arm_rest_1(+v_1: cps_provider_2_ShowAdvance, +v_3: List<&2, BIR.DescriptorArm>, +v_5: cps_provider_1_Context, +v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, +v_11: cps_provider_3_NfVal, +v_13: cps_provider_1_Layout, +v_15: Nat, +v_17: Nat) -> cps_provider_2_ShowAdvance:
  match v_1:
    case cps_provider_2_ShowNext{v_21, v_22}:
      native_match_cps_provider_2_show_data_arm_rest_0(cps_provider_2_show_data_arms(v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17, v_21), v_22)

def cps_provider_2_show_data_arm_rest(+v_1: cps_provider_2_ShowAdvance, +v_3: List<&2, BIR.DescriptorArm>, +v_5: cps_provider_1_Context, +v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, +v_11: cps_provider_3_NfVal, +v_13: cps_provider_1_Layout, +v_15: Nat, +v_17: Nat) -> cps_provider_2_ShowAdvance:
  native_match_cps_provider_2_show_data_arm_rest_1(v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_15, v_17)

def cps_provider_2_show_data_arm_cid(+v_2: Maybe<&2, Nat>, +v_4: List<&2, BIR.DescriptorField>, +v_6: String, +v_8: List<&2, BIR.DescriptorArm>, +v_9: cps_provider_1_Context, +v_11: List<&2, BIR.ConstructorLayout>, +v_13: List<&2, BIR.Family>, +v_14: cps_provider_3_NfVal, +v_15: cps_provider_1_Layout, +v_17: Nat, +v_19: Nat, +v_21: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_2:
    case None{}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_21, cps_provider_2_join_text(["the constructor `", v_6, "` has no assigned C id"])), []}
    case Some{v_26}:
      v_30 = List.length(&2, String, cps_provider_2_show_names(v_21))
      v_35 = cps_provider_2_show_append_num(cps_provider_2_show_append_cid(cps_provider_2_show_append_num(v_21, v_30), v_26), List.length(&2, BIR.DescriptorField, v_4))
      v_40 = cps_provider_2_show_append_name(cps_provider_2_show_append_num(v_35, cps_provider_2_show_arm_bracket(v_6)), v_6)
      cps_provider_2_show_data_arm_rest(cps_provider_2_fields_advance(v_9, v_11, v_13, v_6, v_4, v_15, v_17, v_19, v_40), v_8, v_9, v_11, v_13, v_14, v_15, v_17, v_19)

def cps_provider_2_show_data_arm_erased(+v_1: Bool, +v_3: List<&2, BIR.DescriptorField>, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_8: cps_provider_1_Context, +v_10: List<&2, BIR.ConstructorLayout>, +v_12: List<&2, BIR.Family>, +v_13: cps_provider_3_NfVal, +v_14: cps_provider_1_Layout, +v_16: Nat, +v_18: Nat, +v_20: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_1:
    case True{}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_20, "main's type has an erased field and cannot be printed"), []}
    case False{}:
      cps_provider_2_show_data_arm_header(v_3, v_5, v_7, v_8, v_10, v_12, v_13, v_14, v_16, v_18, v_20)

def cps_provider_2_show_data_arm_live(+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_6: cps_provider_1_Context, +v_8: List<&2, BIR.ConstructorLayout>, +v_10: List<&2, BIR.Family>, +v_11: cps_provider_3_NfVal, +v_12: cps_provider_1_Layout, +v_14: Nat, +v_16: Nat, +v_18: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  v_22 = cps_provider_2_show_erased_present(v_1)
  cps_provider_2_show_data_arm_erased(v_22, v_1, v_3, v_5, v_6, v_8, v_10, v_11, v_12, v_14, v_16, v_18)

def cps_provider_2_show_data_arm(+v_0: cps_provider_1_FieldsResult, +v_2: String, +v_4: List<&2, BIR.DescriptorArm>, +v_5: cps_provider_1_Context, +v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, +v_10: cps_provider_3_NfVal, +v_11: cps_provider_1_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_0:
    case cps_provider_1_FieldsFailed{v_20}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_17, v_20), []}
    case cps_provider_1_FieldsFound{v_23}:
      cps_provider_2_show_data_arm_live(v_23, v_2, v_4, v_5, v_7, v_9, v_10, v_11, v_13, v_15, v_17)

def cps_provider_2_show_data_arms(+v_1: List<&2, BIR.DescriptorArm>, +v_2: cps_provider_1_Context, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>, +v_7: cps_provider_3_NfVal, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: Nat, +v_14: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_1:
    case []:
      cps_provider_2_ShowNext{v_14, []}
    case +v_18 <> +v_19:
      match v_18:
        case BIR.DescriptorArm{v_22, v_23}:
          v_25 = cps_provider_1_arm_fields_value(v_2, v_22, v_7)
          cps_provider_2_show_data_arm(v_25, v_22, v_19, v_2, v_4, v_6, v_7, v_8, v_10, v_12, v_14)

def cps_provider_2_show_data_count(+v_1: List<&2, BIR.DescriptorArm>, +v_2: cps_provider_1_Context, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>, +v_7: cps_provider_3_NfVal, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  v_16 = cps_provider_2_show_box_flag(v_8)
  v_18 = List.length(&2, BIR.DescriptorArm, v_1)
  v_23 = cps_provider_2_show_append_num(cps_provider_2_show_append_num(cps_provider_2_show_append_num(v_12, 7n), v_16), v_18)
  cps_provider_2_show_data_arms(v_1, v_2, v_4, v_6, v_7, v_8, v_16, v_18, v_23)

def cps_provider_2_show_data_arms_maybe(+v_2: Maybe<&2, List<&2, BIR.DescriptorArm>>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: cps_provider_3_NfVal, +v_9: cps_provider_1_Layout, +v_11: Nat, +v_13: cps_provider_2_ShowState, +v_15: String) -> cps_provider_2_ShowAdvance:
  match v_2:
    case None{}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_13, cps_provider_2_join_text(["the datatype `", v_15, "` has no constructors"])), []}
    case Some{v_20}:
      cps_provider_2_show_data_count(v_20, v_3, v_5, v_7, v_8, v_9, v_11, v_13)

def cps_provider_2_show_data_key(+v_1: String, +v_2: cps_provider_1_Context, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>, +v_7: cps_provider_3_NfVal, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  v_16 = cps_provider_2_family_arms(v_1, v_6)
  cps_provider_2_show_data_arms_maybe(v_16, v_2, v_4, v_6, v_7, v_8, v_10, v_12, v_1)

def cps_provider_2_show_data_head(+v_0: cps_provider_1_HeadResult, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: cps_provider_3_NfVal, +v_7: cps_provider_1_Layout, +v_9: Nat, +v_11: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_0:
    case cps_provider_1_HeadFailed{v_14}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_11, v_14), []}
    case cps_provider_1_HeadEquality{}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_11, "the equality type has no data arms to print"), []}
    case cps_provider_1_HeadBoxed{v_18}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_11, "main's type is abstract or open and cannot be printed"), []}
    case cps_provider_1_HeadFound{v_22, v_23}:
      cps_provider_2_show_data_key(v_22, v_1, v_3, v_5, v_6, v_7, v_9, v_11)

def native_match_cps_provider_2_show_advance_data_0(v_23: cps_provider_3_Nf, +v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_23:
    case cps_provider_3_NfFail{v_16}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_12, v_16), []}
    case cps_provider_3_NfOk{+v_19}:
      v_22 = cps_provider_1_head_value(v_1, v_19)
      cps_provider_2_show_data_head(v_22, v_1, v_3, v_5, v_19, v_8, v_10, v_12)

def cps_provider_2_show_advance_data(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  native_match_cps_provider_2_show_advance_data_0(cps_provider_1_nf_of(v_1, v_6, [], 1024n), v_1, v_3, v_5, v_8, v_10, v_12)

def cps_provider_2_show_advance_n(+v_1: Nat, +v_2: cps_provider_1_Context, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>, +v_7: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_1:
    case 3n:
      cps_provider_2_ShowNext{cps_provider_2_show_append_num(cps_provider_2_show_append_num(v_12, 3n), cps_provider_2_show_box_flag(v_8)), []}
    case 6n:
      cps_provider_2_show_advance_array(v_2, v_4, v_6, v_7, v_10, v_12)
    case 7n:
      cps_provider_2_show_advance_data(v_2, v_4, v_6, v_7, v_8, v_10, v_12)
    case _:
      cps_provider_2_ShowNext{cps_provider_2_show_append_num(v_12, v_1), []}

def cps_provider_2_show_advance_kind(+v_1: cps_provider_2_ShowKind, +v_2: cps_provider_1_Context, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>, +v_7: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_10: Nat, +v_12: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_1:
    case cps_provider_2_ShowKindFailed{v_15}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_12, v_15), []}
    case cps_provider_2_ShowKindOk{v_18}:
      cps_provider_2_show_advance_n(v_18, v_2, v_4, v_6, v_7, v_8, v_10, v_12)

def cps_provider_2_show_advance_memo(+v_2: Maybe<&2, Nat>, +v_4: String, +v_5: cps_provider_1_Context, +v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, +v_10: BIR.Descriptor, +v_11: cps_provider_1_Layout, +v_14: Maybe<&2, Nat>, +v_16: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_2:
    case Some{v_19}:
      cps_provider_2_ShowNext{cps_provider_2_show_apply_patch(v_16, v_14, v_19), []}
    case None{}:
      v_24 = List.length(&2, cps_provider_2_ShowWord, cps_provider_2_show_words(v_16))
      v_28 = Map.set(&2, Nat, cps_provider_2_show_memo(v_16), v_4, v_24)
      v_32 = cps_provider_2_show_apply_patch(cps_provider_2_show_state_set_memo(v_16, v_28), v_14, v_24)
      v_35 = cps_provider_2_show_kind(v_5, v_10)
      cps_provider_2_show_advance_kind(v_35, v_5, v_7, v_9, v_10, v_11, v_24, v_32)

def cps_provider_2_show_advance_norm(+v_1: cps_provider_2_ShowNorm, +v_2: cps_provider_1_Context, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>, +v_7: BIR.Descriptor, +v_8: cps_provider_1_Layout, +v_11: Maybe<&2, Nat>, +v_13: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_1:
    case cps_provider_2_ShowNormFailed{v_16}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_13, v_16), []}
    case cps_provider_2_ShowNormOk{v_19}:
      cps_provider_2_show_advance_key(cps_provider_2_show_descriptor_key(v_19), v_2, v_4, v_6, v_7, v_8, v_11, v_13)

def cps_provider_2_show_advance_key(+v_2: Maybe<&2, String>, +v_3: cps_provider_1_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_9: cps_provider_1_Layout, +v_12: Maybe<&2, Nat>, +v_14: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_2:
    case None{}:
      cps_provider_2_ShowNext{cps_provider_2_show_state_error(v_14, "the show descriptor key did not finish"), []}
    case Some{v_18}:
      v_22 = cps_provider_2_join_text([Nat.show(String.length(v_18)), ":", v_18, cps_provider_2_show_layout_key(v_9)])
      v_26 = IndexLookup.find(Nat, cps_provider_2_show_memo(v_14), v_22)
      cps_provider_2_show_advance_memo(v_26, v_22, v_3, v_5, v_7, v_8, v_9, v_12, v_14)

def cps_provider_2_show_norm_result(+v_0: cps_provider_1_NormResult) -> cps_provider_2_ShowNorm:
  match v_0:
    case cps_provider_1_NormOk{v_3}:
      cps_provider_2_ShowNormOk{v_3}
    case cps_provider_1_NormFailed{v_5}:
      cps_provider_2_ShowNormFailed{v_5}

def cps_provider_2_show_norm(+v_0: cps_provider_1_Context, +v_1: BIR.Descriptor) -> cps_provider_2_ShowNorm:
  cps_provider_2_show_norm_result(cps_provider_1_norm(v_0, v_1))

def cps_provider_2_show_advance_error(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_4: List<&2, BIR.Family>, +v_5: BIR.Descriptor, +v_6: cps_provider_1_Layout, +v_9: Maybe<&2, Nat>, +v_12: Maybe<&2, String>, +v_14: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_12:
    case Some{v_17}:
      cps_provider_2_ShowNext{v_14, []}
    case None{}:
      v_20 = cps_provider_2_show_norm(v_0, v_5)
      cps_provider_2_show_advance_norm(v_20, v_0, v_2, v_4, v_5, v_6, v_9, v_14)

def cps_provider_2_show_advance_st(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_4: List<&2, BIR.Family>, +v_5: BIR.Descriptor, +v_6: cps_provider_1_Layout, +v_9: Maybe<&2, Nat>, +v_11: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_11:
    case cps_provider_2_ShowState{v_18, v_19, v_20, v_21, v_22}:
      cps_provider_2_show_advance_error(v_0, v_2, v_4, v_5, v_6, v_9, v_22, v_11)

def cps_provider_2_show_advance_job(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_4: List<&2, BIR.Family>, +v_6: cps_provider_2_ShowJob, +v_8: cps_provider_2_ShowState) -> cps_provider_2_ShowAdvance:
  match v_6:
    case cps_provider_2_ShowNode{v_13, v_14, v_15}:
      cps_provider_2_show_advance_st(v_0, v_2, v_4, v_13, v_14, v_15, v_8)

def cps_provider_2_run_show(+v_0: cps_provider_1_Context, +v_2: List<&2, BIR.ConstructorLayout>, +v_4: List<&2, BIR.Family>, +v_7: List<&2, cps_provider_2_ShowJob>, +v_9: cps_provider_2_ShowState) -> cps_provider_2_ShowRun:
  match v_7:
    case []:
      cps_provider_2_ShowDone{v_9}
    case +v_13 <> +v_14:
      v_17 = cps_provider_2_show_advance_job(v_0, v_2, v_4, v_13, v_9)
      cps_provider_2_run_show(v_0, v_2, v_4, List.append(&2, cps_provider_2_ShowJob, cps_provider_2_show_next_kids(v_17), v_14), cps_provider_2_show_next_state(v_17))

def cps_provider_2_show_set_word(+v_2: List<&2, cps_provider_2_ShowWord>, +v_4: Nat, +v_6: cps_provider_2_ShowWord, +v_8: Nat) -> List<&2, cps_provider_2_ShowWord>:
  match v_2:
    case []:
      []
    case +v_13 <> +v_14:
      v_16 = Nat.is_eq(v_8, v_4)
      Bool.pick(List<&2, cps_provider_2_ShowWord>, v_16, List.append(&2, cps_provider_2_ShowWord, [v_6], v_14), List.append(&2, cps_provider_2_ShowWord, [v_13], cps_provider_2_show_set_word(v_14, v_4, v_6, Nat.add(v_8, 1n))))

def cps_provider_2_show_apply_patches(+v_2: List<&2, cps_provider_2_ShowWord>, +v_5: List<&2, cps_provider_2_ShowPatch>) -> List<&2, cps_provider_2_ShowWord>:
  match v_5:
    case []:
      v_2
    case +v_10 <> +v_11:
      match v_10:
        case cps_provider_2_ShowPatchAt{v_14, v_15}:
          cps_provider_2_show_apply_patches(cps_provider_2_show_set_word(v_2, v_14, cps_provider_2_ShowNum{v_15}, 0n), v_11)

def cps_provider_2_show_finish(+v_2: Maybe<&2, String>, +v_4: cps_provider_2_ShowState) -> cps_provider_2_ShowOut:
  match v_2:
    case Some{v_7}:
      cps_provider_2_ShowFail{v_7}
    case None{}:
      cps_provider_2_ShowOk{cps_provider_2_show_render_words(cps_provider_2_show_apply_patches(cps_provider_2_show_words(v_4), cps_provider_2_show_patches(v_4)), ""), cps_provider_2_show_render_names(cps_provider_2_show_names(v_4))}

def cps_provider_2_show_result(+v_1: cps_provider_2_ShowRun) -> cps_provider_2_ShowOut:
  match v_1:
    case cps_provider_2_ShowDone{v_4}:
      cps_provider_2_show_finish(cps_provider_2_show_error(v_4), v_4)

def cps_provider_2_show_root_layout(+v_0: cps_provider_1_Layout) -> cps_provider_1_Layout:
  match v_0:
    case cps_provider_1_LayoutWord{v_2}:
      v_0
    case cps_provider_1_LayoutBox{v_4}:
      v_0
    case cps_provider_1_LayoutData{v_7, v_8}:
      cps_provider_1_LayoutBox{cps_provider_1_BoxWide{List.length(&2, cps_provider_1_CWord, v_7)}}

def cps_provider_2_show_root(+v_0: cps_provider_1_LayoutResult, +v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>) -> cps_provider_2_ShowOut:
  match v_0:
    case cps_provider_1_LayoutFailed{v_9}:
      cps_provider_2_ShowFail{v_9}
    case cps_provider_1_LayoutFound{v_11}:
      v_16 = cps_provider_2_run_show(v_1, v_4, v_6, [cps_provider_2_ShowNode{v_2, cps_provider_2_show_root_layout(v_11), None{}}], cps_provider_2_show_state0)
      cps_provider_2_show_result(v_16)

def cps_provider_2_show_build(+v_0: cps_provider_1_Context, +v_1: BIR.Descriptor, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>) -> cps_provider_2_ShowOut:
  v_8 = cps_provider_1_value_layout(v_0, v_1)
  cps_provider_2_show_root(v_8, v_0, v_1, v_3, v_5)

def cps_provider_3_family_index(v_1: List<&2, BIR.Family>) -> Map<&2, BIR.Family>:
  match v_1:
    case []:
      Map.new(&2, BIR.Family)
    case +v_5 <> v_6:
      match v_5:
        case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
          Map.set(&2, BIR.Family, cps_provider_3_family_index(v_6), v_13, v_5)

def cps_provider_3_function_index(v_1: List<&2, BIR.TypeFunction>) -> Map<&2, BIR.TypeFunction>:
  match v_1:
    case []:
      Map.new(&2, BIR.TypeFunction)
    case +v_5 <> v_6:
      match v_5:
        case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
          Map.set(&2, BIR.TypeFunction, cps_provider_3_function_index(v_6), v_12, v_5)

def cps_provider_3_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> cps_provider_3_NfContext:
  cps_provider_3_NfContext{cps_provider_3_family_index(v_1), cps_provider_3_function_index(v_3)}

def cps_provider_3_default_fuel() -> Nat:
  1024n

def cps_provider_3_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  IndexLookup.find(BIR.Family, v_3, v_1)

def cps_provider_3_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  IndexLookup.find(BIR.TypeFunction, v_3, v_1)

def native_match_cps_provider_3_native_of_0(v_10: BIR.Family) -> Maybe<&2, String>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      v_19

def native_match_cps_provider_3_native_of_1(v_25: BIR.TypeFunction) -> Maybe<&2, String>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      v_32

def native_match_cps_provider_3_native_of_2(v_37: Maybe<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_37:
    case Some{v_25}:
      native_match_cps_provider_3_native_of_1(v_25)
    case None{}:
      None{}

def native_match_cps_provider_3_native_of_3(v_36: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_36:
    case Some{v_10}:
      native_match_cps_provider_3_native_of_0(v_10)
    case None{}:
      native_match_cps_provider_3_native_of_2(cps_provider_3_function_of(v_1, v_5))

def cps_provider_3_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  native_match_cps_provider_3_native_of_3(cps_provider_3_family_of(v_1, v_3), v_1, v_5)

def cps_provider_3_val_nth(+v_2: List<&2, cps_provider_3_NfVal>, v_4: Nat) -> cps_provider_3_NfVal:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      v_8
    case +v_13 <> v_14, 1n+v_15:
      cps_provider_3_val_nth(v_14, v_15)
    case _, _:
      cps_provider_3_NfMissing{BIR.DescriptorNull{}}

def cps_provider_3_val_at(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> cps_provider_3_NfVal:
  cps_provider_3_val_at_choose(Nat.is_lt(v_4, List.length(&2, cps_provider_3_NfVal, v_2)), v_2, v_4, v_5)

def cps_provider_3_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> cps_provider_3_NfVal:
  match v_1:
    case True{}:
      cps_provider_3_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_3_NfVal, v_4), 1n), v_6))
    case False{}:
      cps_provider_3_NfMissing{v_7}

def cps_provider_3_first_vals(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> List<&2, cps_provider_3_NfVal>:
  match v_2, v_4:
    case _, 0n:
      []
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      v_14 <> cps_provider_3_first_vals(v_15, v_16)

def cps_provider_3_drop_vals(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> List<&2, cps_provider_3_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_2
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      cps_provider_3_drop_vals(v_15, v_16)

def cps_provider_3_insert_before(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_6: cps_provider_3_NfVal) -> List<&2, cps_provider_3_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_6 <> v_2
    case [], 1n+v_12:
      cps_provider_3_insert_before([], v_12, v_6)
    case +v_17 <> v_18, 1n+v_19:
      v_17 <> cps_provider_3_insert_before(v_18, v_19, v_6)

def cps_provider_3_append_vals(v_2: List<&2, cps_provider_3_NfVal>, v_5: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      v_10 <> cps_provider_3_append_vals(v_11, v_5)

def cps_provider_3_quantity_markers(v_1: Nat) -> List<&2, cps_provider_3_NfVal>:
  match v_1:
    case 0n:
      []
    case 1n+v_5:
      cps_provider_3_NfQuantity{BIR.Erased{}} <> cps_provider_3_quantity_markers(v_5)

def native_match_cps_provider_3_renamed_level_0(v_13: Bool, +v_4: Nat, v_10: Nat, v_11: List<&2, cps_provider_3_NfRenaming>) -> Nat:
  match v_13:
    case True{}:
      v_10
    case False{}:
      cps_provider_3_renamed_level(v_11, v_4)

def native_match_cps_provider_3_renamed_level_1(v_2: List<&2, cps_provider_3_NfRenaming>, +v_4: Nat) -> Nat:
  match v_2:
    case []:
      v_4
    case cps_provider_3_NfRenaming{v_9, v_10} <> v_11:
      native_match_cps_provider_3_renamed_level_0(Nat.is_eq(v_9, v_4), v_4, v_10, v_11)

def cps_provider_3_renamed_level(v_2: List<&2, cps_provider_3_NfRenaming>, +v_4: Nat) -> Nat:
  native_match_cps_provider_3_renamed_level_1(v_2, v_4)

def cps_provider_3_materialize_all_scoped(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_3_NfRenaming>) -> List<&2, BIR.Descriptor>:
  match v_2:
    case []:
      []
    case +v_11 <> v_12:
      cps_provider_3_materialize_scoped(v_11, v_4, v_7) <> cps_provider_3_materialize_all_scoped(v_12, v_4, v_7)

def cps_provider_3_materialize_all_at(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> List<&2, BIR.Descriptor>:
  cps_provider_3_materialize_all_scoped(v_2, v_4, [])

def cps_provider_3_materialize_all(v_2: List<&2, cps_provider_3_NfVal>) -> List<&2, BIR.Descriptor>:
  cps_provider_3_materialize_all_at(v_2, 0n)

def cps_provider_3_materialize_scoped(v_1: cps_provider_3_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_3_NfRenaming>) -> BIR.Descriptor:
  match v_1:
    case cps_provider_3_NfType{v_9, v_10}:
      BIR.DescriptorRef{v_9, cps_provider_3_materialize_all_scoped(v_10, v_3, v_6)}
    case cps_provider_3_NfCtor{v_14, v_15}:
      BIR.DescriptorConstructor{v_14, cps_provider_3_materialize_all_scoped(v_15, v_3, v_6)}
    case cps_provider_3_NfQuantity{v_18}:
      BIR.DescriptorQuantity{v_18}
    case cps_provider_3_NfKind{v_20}:
      BIR.DescriptorKind{cps_provider_3_materialize_scoped(v_20, v_3, v_6)}
    case cps_provider_3_NfOther{v_23}:
      v_23
    case cps_provider_3_NfMissing{v_25}:
      v_25
    case cps_provider_3_NfBinder{v_27}:
      BIR.DescriptorParameter{Nat.sub(v_3, Nat.add(cps_provider_3_renamed_level(v_6, v_27), 1n))}
    case cps_provider_3_NfArrow{v_33, v_34, v_35, v_36}:
      BIR.DescriptorArrow{v_33, cps_provider_3_materialize_scoped(v_34, v_3, v_6), cps_provider_3_materialize_scoped(v_35, Nat.add(v_3, 1n), cps_provider_3_NfRenaming{v_36, v_3} <> v_6)}
    case cps_provider_3_NfClosure{v_42, v_43, v_44}:
      BIR.DescriptorLet{cps_provider_3_materialize_all_scoped(v_44, v_3, v_6), BIR.DescriptorLambda{v_42, v_43}}

def cps_provider_3_materialize_at(v_1: cps_provider_3_NfVal, +v_3: Nat) -> BIR.Descriptor:
  cps_provider_3_materialize_scoped(v_1, v_3, [])

def cps_provider_3_materialize(v_1: cps_provider_3_NfVal) -> BIR.Descriptor:
  cps_provider_3_materialize_at(v_1, 0n)

def cps_provider_3_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_3_NfVal>, +v_5: Nat) -> BIR.Descriptor:
  match v_3:
    case []:
      v_0
    case +v_8 <> v_9:
      BIR.DescriptorLet{cps_provider_3_materialize_all_at(v_3, v_5), v_0}

def cps_provider_3_status_combine(v_1: cps_provider_3_NfStatus, v_3: cps_provider_3_NfStatus) -> cps_provider_3_NfStatus:
  match v_1:
    case cps_provider_3_NfStatusNo{}:
      cps_provider_3_NfStatusNo{}
    case cps_provider_3_NfStatusMaybe{}:
      match v_3:
        case cps_provider_3_NfStatusNo{}:
          cps_provider_3_NfStatusNo{}
        case _:
          cps_provider_3_NfStatusMaybe{}
    case cps_provider_3_NfStatusOk{}:
      v_3

def native_match_cps_provider_3_bind_status_0(v_56: Bool, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_3_NfVal>, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  match v_56:
    case False{}:
      cps_provider_3_NfStatusNo{}
    case True{}:
      cps_provider_3_status_combine(cps_provider_3_bind_status(v_20, v_24), cps_provider_3_bind_status(v_11, v_13))

def native_match_cps_provider_3_bind_status_1(+v_12: cps_provider_3_NfVal, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_3_NfVal>, v_19: String, v_20: List<&2, BIR.DescriptorPattern>) -> cps_provider_3_NfStatus:
  match v_12:
    case cps_provider_3_NfCtor{v_23, v_24}:
      native_match_cps_provider_3_bind_status_0(String.eq(v_19, v_23), v_11, v_13, v_20, v_24)
    case cps_provider_3_NfMissing{v_29}:
      cps_provider_3_status_combine(cps_provider_3_NfStatusMaybe{}, cps_provider_3_bind_status(v_11, v_13))
    case cps_provider_3_NfOther{v_33}:
      cps_provider_3_status_combine(cps_provider_3_NfStatusMaybe{}, cps_provider_3_bind_status(v_11, v_13))
    case cps_provider_3_NfBinder{v_37}:
      cps_provider_3_status_combine(cps_provider_3_NfStatusMaybe{}, cps_provider_3_bind_status(v_11, v_13))
    case cps_provider_3_NfArrow{v_44, v_45, v_46, v_47}:
      cps_provider_3_status_combine(cps_provider_3_NfStatusMaybe{}, cps_provider_3_bind_status(v_11, v_13))
    case _:
      cps_provider_3_NfStatusNo{}

def native_match_cps_provider_3_bind_status_2(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, +v_12: cps_provider_3_NfVal, v_13: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      cps_provider_3_bind_status(v_11, v_13)
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      native_match_cps_provider_3_bind_status_1(v_12, v_11, v_13, v_19, v_20)

def native_match_cps_provider_3_bind_status_3(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  match v_1, v_4:
    case [], []:
      cps_provider_3_NfStatusOk{}
    case +v_10 <> v_11, +v_12 <> v_13:
      native_match_cps_provider_3_bind_status_2(v_10, v_11, v_12, v_13)
    case _, _:
      cps_provider_3_NfStatusNo{}

def cps_provider_3_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  native_match_cps_provider_3_bind_status_3(v_1, v_4)

def native_match_cps_provider_3_bind_values_0(+v_13: cps_provider_3_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_3_NfVal>, v_21: List<&2, BIR.DescriptorPattern>) -> List<&2, cps_provider_3_NfVal>:
  match v_13:
    case cps_provider_3_NfCtor{v_24, v_25}:
      cps_provider_3_append_vals(cps_provider_3_bind_values(v_21, v_25), cps_provider_3_bind_values(v_12, v_14))
    case _:
      cps_provider_3_bind_values(v_12, v_14)

def native_match_cps_provider_3_bind_values_1(+v_11: BIR.DescriptorPattern, v_12: List<&2, BIR.DescriptorPattern>, +v_13: cps_provider_3_NfVal, v_14: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      v_13 <> cps_provider_3_bind_values(v_12, v_14)
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      native_match_cps_provider_3_bind_values_0(v_13, v_12, v_14, v_21)

def native_match_cps_provider_3_bind_values_2(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  match v_1, v_4:
    case [], []:
      []
    case +v_11 <> v_12, +v_13 <> v_14:
      native_match_cps_provider_3_bind_values_1(v_11, v_12, v_13, v_14)
    case _, _:
      []

def cps_provider_3_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  native_match_cps_provider_3_bind_values_2(v_1, v_4)

def native_match_cps_provider_3_bind_patterns_0(v_5: cps_provider_3_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfBind:
  match v_5:
    case cps_provider_3_NfStatusOk{}:
      cps_provider_3_NfBound{cps_provider_3_bind_values(v_1, v_4)}
    case cps_provider_3_NfStatusNo{}:
      cps_provider_3_NfMismatch{}
    case cps_provider_3_NfStatusMaybe{}:
      cps_provider_3_NfUnknown{}

def cps_provider_3_bind_patterns(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfBind:
  native_match_cps_provider_3_bind_patterns_0(cps_provider_3_bind_status(v_1, v_4), v_1, v_4)

def native_match_cps_provider_3_nf_0(v_10: Bool, +v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  match v_10:
    case True{}:
      cps_provider_3_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_3_nf_descriptor(v_1, v_2, v_5, v_7, Nat.sub(v_9, 1n))

def cps_provider_3_nf(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_cps_provider_3_nf_descriptor_0(v_10: Bool, +v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  match v_10:
    case True{}:
      cps_provider_3_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_3_nf_descriptor_step(v_1, v_2, v_5, v_7, v_9)

def cps_provider_3_nf_descriptor(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_descriptor_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_cps_provider_3_nf_arrow_0(v_25: cps_provider_3_Nf, v_2: BIR.Quantity, +v_9: Nat, v_17: cps_provider_3_NfVal) -> cps_provider_3_Nf:
  match v_25:
    case cps_provider_3_NfFail{v_21}:
      cps_provider_3_NfFail{v_21}
    case cps_provider_3_NfOk{v_23}:
      cps_provider_3_NfOk{cps_provider_3_NfArrow{v_2, v_17, v_23, v_9}}

def native_match_cps_provider_3_nf_arrow_1(v_24: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_2: BIR.Quantity, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_3_Nf:
  match v_24:
    case cps_provider_3_NfFail{v_15}:
      cps_provider_3_NfFail{v_15}
    case cps_provider_3_NfOk{v_17}:
      native_match_cps_provider_3_nf_arrow_0(cps_provider_3_nf(v_1, v_4, List.append(&2, cps_provider_3_NfVal, v_7, [cps_provider_3_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11), v_2, v_9, v_17)

def cps_provider_3_nf_arrow(+v_1: cps_provider_3_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_arrow_1(cps_provider_3_nf(v_1, v_3, v_7, v_9, v_11), v_1, v_2, v_4, v_7, v_9, v_11)

def native_match_cps_provider_3_nf_descriptor_step_0(v_191: cps_provider_3_Nf) -> cps_provider_3_Nf:
  match v_191:
    case cps_provider_3_NfOk{v_24}:
      cps_provider_3_NfOk{cps_provider_3_NfKind{v_24}}
    case cps_provider_3_NfFail{v_26}:
      cps_provider_3_NfFail{v_26}

def native_match_cps_provider_3_nf_descriptor_step_1(v_192: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_7: Nat, +v_9: Nat, v_45: String) -> cps_provider_3_Nf:
  match v_192:
    case cps_provider_3_NfListOk{v_49}:
      cps_provider_3_nf_named(v_1, v_45, v_49, v_7, v_9)
    case cps_provider_3_NfListFail{v_52}:
      cps_provider_3_NfFail{v_52}

def native_match_cps_provider_3_nf_descriptor_step_2(v_193: cps_provider_3_NfList, v_55: String) -> cps_provider_3_Nf:
  match v_193:
    case cps_provider_3_NfListOk{v_59}:
      cps_provider_3_NfOk{cps_provider_3_NfCtor{v_55, v_59}}
    case cps_provider_3_NfListFail{v_61}:
      cps_provider_3_NfFail{v_61}

def native_match_cps_provider_3_nf_descriptor_step_3(v_195: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_7: Nat, +v_9: Nat, v_68: cps_provider_3_NfVal) -> cps_provider_3_Nf:
  match v_195:
    case cps_provider_3_NfOk{v_71}:
      cps_provider_3_nf_apply(v_1, v_68, [v_71], v_7, v_9)
    case cps_provider_3_NfFail{v_74}:
      cps_provider_3_NfFail{v_74}

def native_match_cps_provider_3_nf_descriptor_step_4(v_194: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, v_65: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_194:
    case cps_provider_3_NfOk{v_68}:
      native_match_cps_provider_3_nf_descriptor_step_3(cps_provider_3_nf(v_1, v_65, v_5, v_7, v_9), v_1, v_7, v_9, v_68)
    case cps_provider_3_NfFail{v_76}:
      cps_provider_3_NfFail{v_76}

def native_match_cps_provider_3_nf_descriptor_step_5(v_196: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, v_80: Nat, v_82: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_196:
    case cps_provider_3_NfOk{v_85}:
      cps_provider_3_nf_descriptor(v_1, v_82, cps_provider_3_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_3_NfVal, v_5), v_80), v_85), v_7, Nat.sub(v_9, 1n))
    case cps_provider_3_NfFail{v_90}:
      cps_provider_3_NfFail{v_90}

def native_match_cps_provider_3_nf_descriptor_step_6(v_197: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, v_94: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_197:
    case cps_provider_3_NfListOk{v_97}:
      cps_provider_3_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_3_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n))
    case cps_provider_3_NfListFail{v_101}:
      cps_provider_3_NfFail{v_101}

def native_match_cps_provider_3_nf_descriptor_step_7(v_199: cps_provider_3_NfBind, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_107: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_199:
    case cps_provider_3_NfBound{v_113}:
      cps_provider_3_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_3_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n))
    case _:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_12, v_5, v_7)}}

def native_match_cps_provider_3_nf_descriptor_step_8(v_198: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_105: List<&2, BIR.DescriptorPattern>, v_107: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_198:
    case cps_provider_3_NfListOk{v_110}:
      native_match_cps_provider_3_nf_descriptor_step_7(cps_provider_3_bind_patterns(v_105, v_110), v_1, v_5, v_7, v_9, v_12, v_107)
    case cps_provider_3_NfListFail{v_120}:
      cps_provider_3_NfFail{v_120}

def native_match_cps_provider_3_nf_descriptor_step_9(v_200: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_124: List<&2, BIR.Descriptor>) -> cps_provider_3_Nf:
  match v_200:
    case cps_provider_3_NfListOk{v_127}:
      cps_provider_3_nf_cases(v_1, v_124, v_127, v_5, v_12, v_7, v_9)
    case cps_provider_3_NfListFail{v_130}:
      cps_provider_3_NfFail{v_130}

def native_match_cps_provider_3_nf_descriptor_step_10(v_201: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat, v_139: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_201:
    case cps_provider_3_NfOk{v_142}:
      cps_provider_3_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_3_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_3_NfFail{v_146}:
      cps_provider_3_NfFail{v_146}

def native_match_cps_provider_3_nf_descriptor_step_11(v_202: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_7: Nat, +v_9: Nat, v_170: String) -> cps_provider_3_Nf:
  match v_202:
    case cps_provider_3_NfListOk{v_175}:
      cps_provider_3_nf_named(v_1, v_170, v_175, v_7, v_9)
    case cps_provider_3_NfListFail{v_178}:
      cps_provider_3_NfFail{v_178}

def native_match_cps_provider_3_nf_descriptor_step_12(v_203: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_7: Nat, +v_9: Nat, v_182: String) -> cps_provider_3_Nf:
  match v_203:
    case cps_provider_3_NfListOk{v_187}:
      cps_provider_3_nf_named(v_1, v_182, v_187, v_7, v_9)
    case cps_provider_3_NfListFail{v_190}:
      cps_provider_3_NfFail{v_190}

def native_match_cps_provider_3_nf_descriptor_step_13(+v_12: BIR.Descriptor, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  match v_12:
    case BIR.DescriptorNull{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorParameter{v_15}:
      cps_provider_3_NfOk{cps_provider_3_val_at(v_5, v_15, v_12)}
    case BIR.DescriptorQuantityKind{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorQuantity{v_19}:
      cps_provider_3_NfOk{cps_provider_3_NfQuantity{v_19}}
    case BIR.DescriptorKind{v_21}:
      native_match_cps_provider_3_nf_descriptor_step_0(cps_provider_3_nf(v_1, v_21, v_5, v_7, v_9))
    case BIR.DescriptorMinimum{v_29, v_30}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorArrow{v_35, v_36, v_37}:
      cps_provider_3_nf_arrow(v_1, v_35, v_36, v_37, v_5, v_7, v_9)
    case BIR.DescriptorLambda{v_41, v_42}:
      cps_provider_3_NfOk{cps_provider_3_NfClosure{v_41, v_42, v_5}}
    case BIR.DescriptorRef{v_45, v_46}:
      native_match_cps_provider_3_nf_descriptor_step_1(cps_provider_3_nf_all(v_1, v_46, v_5, v_7, v_9), v_1, v_7, v_9, v_45)
    case BIR.DescriptorConstructor{v_55, v_56}:
      native_match_cps_provider_3_nf_descriptor_step_2(cps_provider_3_nf_all(v_1, v_56, v_5, v_7, v_9), v_55)
    case BIR.DescriptorApplication{v_64, v_65}:
      native_match_cps_provider_3_nf_descriptor_step_4(cps_provider_3_nf(v_1, v_64, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_65)
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      native_match_cps_provider_3_nf_descriptor_step_5(cps_provider_3_nf(v_1, v_81, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_80, v_82)
    case BIR.DescriptorLet{v_93, v_94}:
      native_match_cps_provider_3_nf_descriptor_step_6(cps_provider_3_nf_all(v_1, v_93, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_94)
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      native_match_cps_provider_3_nf_descriptor_step_8(cps_provider_3_nf_all(v_1, v_106, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_105, v_107)
    case BIR.DescriptorMatch{v_123, v_124}:
      native_match_cps_provider_3_nf_descriptor_step_9(cps_provider_3_nf_all(v_1, v_123, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_124)
    case BIR.DescriptorCase{v_133, v_134}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorBind{v_138, v_139}:
      native_match_cps_provider_3_nf_descriptor_step_10(cps_provider_3_nf(v_1, v_138, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_139)
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorReflexivity{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorFailure{v_156}:
      cps_provider_3_NfFail{v_156}
    case BIR.DescriptorFill{v_159, v_160}:
      cps_provider_3_nf_apply_args(v_1, v_159, v_160, v_5, v_12, v_7, v_9)
    case BIR.DescriptorPlus{v_164, v_165}:
      cps_provider_3_nf_apply_args(v_1, v_164, v_165, v_5, v_12, v_7, v_9)
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      native_match_cps_provider_3_nf_descriptor_step_11(cps_provider_3_nf_all(v_1, v_172, v_5, v_7, v_9), v_1, v_7, v_9, v_170)
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      native_match_cps_provider_3_nf_descriptor_step_12(cps_provider_3_nf_all(v_1, v_184, v_5, v_7, v_9), v_1, v_7, v_9, v_182)

def cps_provider_3_nf_descriptor_step(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  +v_12 = v_2
  native_match_cps_provider_3_nf_descriptor_step_13(v_12, v_1, v_5, v_7, v_9)

def native_match_cps_provider_3_nf_all_0(v_27: cps_provider_3_NfList, v_20: cps_provider_3_NfVal) -> cps_provider_3_NfList:
  match v_27:
    case cps_provider_3_NfListFail{v_23}:
      cps_provider_3_NfListFail{v_23}
    case cps_provider_3_NfListOk{v_25}:
      cps_provider_3_NfListOk{v_20 <> v_25}

def native_match_cps_provider_3_nf_all_1(v_26: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat, v_15: List<&2, BIR.Descriptor>) -> cps_provider_3_NfList:
  match v_26:
    case cps_provider_3_NfFail{v_18}:
      cps_provider_3_NfListFail{v_18}
    case cps_provider_3_NfOk{v_20}:
      native_match_cps_provider_3_nf_all_0(cps_provider_3_nf_all(v_1, v_15, v_6, v_8, v_10), v_20)

def native_match_cps_provider_3_nf_all_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_3_NfList:
  match v_3:
    case []:
      cps_provider_3_NfListOk{[]}
    case +v_14 <> v_15:
      native_match_cps_provider_3_nf_all_1(cps_provider_3_nf(v_1, v_14, v_6, v_8, v_10), v_1, v_6, v_8, v_10, v_15)

def cps_provider_3_nf_all(+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_3_NfList:
  native_match_cps_provider_3_nf_all_2(v_3, v_1, v_6, v_8, v_10)

def native_match_cps_provider_3_nf_apply_args_0(v_25: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat, v_18: cps_provider_3_NfVal) -> cps_provider_3_Nf:
  match v_25:
    case cps_provider_3_NfListFail{v_21}:
      cps_provider_3_NfFail{v_21}
    case cps_provider_3_NfListOk{v_23}:
      cps_provider_3_nf_apply_source(v_1, v_18, v_23, v_8, v_10, v_12)

def native_match_cps_provider_3_nf_apply_args_1(v_24: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_3_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> cps_provider_3_Nf:
  match v_24:
    case cps_provider_3_NfFail{v_16}:
      cps_provider_3_NfFail{v_16}
    case cps_provider_3_NfOk{v_18}:
      native_match_cps_provider_3_nf_apply_args_0(cps_provider_3_nf_all(v_1, v_4, v_7, v_10, v_12), v_1, v_8, v_10, v_12, v_18)

def cps_provider_3_nf_apply_args(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_3_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_apply_args_1(cps_provider_3_nf(v_1, v_2, v_7, v_10, v_12), v_1, v_4, v_7, v_8, v_10, v_12)

def cps_provider_3_nf_apply_source(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_6: List<&2, cps_provider_3_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat) -> cps_provider_3_Nf:
  match v_6:
    case []:
      cps_provider_3_NfOk{v_3}
    case _:
      cps_provider_3_nf_apply(v_1, v_3, v_6, v_9, v_11)

def native_match_cps_provider_3_nf_apply_0(v_21: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_8: Nat, +v_10: Nat, v_15: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_21:
    case cps_provider_3_NfFail{v_18}:
      cps_provider_3_NfFail{v_18}
    case cps_provider_3_NfOk{v_20}:
      cps_provider_3_nf_apply(v_1, v_20, v_15, v_8, Nat.sub(v_10, 1n))

def native_match_cps_provider_3_nf_apply_1(v_6: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, +v_8: Nat, +v_10: Nat) -> cps_provider_3_Nf:
  match v_6:
    case []:
      cps_provider_3_NfOk{v_3}
    case +v_14 <> v_15:
      native_match_cps_provider_3_nf_apply_0(cps_provider_3_nf_apply_one(v_1, v_3, v_14, v_8, Nat.sub(v_10, 1n)), v_1, v_8, v_10, v_15)

def cps_provider_3_nf_apply(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_apply_1(v_6, v_1, v_3, v_8, v_10)

def cps_provider_3_nf_apply_one(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_5: cps_provider_3_NfVal, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  match v_3:
    case cps_provider_3_NfType{v_13, v_14}:
      cps_provider_3_nf_named(v_1, v_13, List.append(&2, cps_provider_3_NfVal, v_14, [v_5]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_3_NfClosure{v_20, v_21, v_22}:
      cps_provider_3_nf_descriptor(v_1, v_21, List.append(&2, cps_provider_3_NfVal, v_22, [v_5]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_3_NfCtor{v_27, v_28}:
      cps_provider_3_NfFail{String.append("the constructor `", String.append(v_27, "` is applied to an argument"))}
    case cps_provider_3_NfQuantity{v_30}:
      cps_provider_3_NfFail{"a quantity is applied to an argument"}
    case cps_provider_3_NfKind{v_32}:
      cps_provider_3_NfFail{"a kind is applied to an argument"}
    case cps_provider_3_NfOther{v_34}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{BIR.DescriptorApplication{v_34, cps_provider_3_materialize_at(v_5, v_7)}}}
    case cps_provider_3_NfArrow{v_40, v_41, v_42, v_43}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{BIR.DescriptorApplication{cps_provider_3_materialize_at(v_3, v_7), cps_provider_3_materialize_at(v_5, v_7)}}}
    case cps_provider_3_NfMissing{v_47}:
      cps_provider_3_NfOk{cps_provider_3_NfMissing{BIR.DescriptorApplication{v_47, cps_provider_3_materialize_at(v_5, v_7)}}}
    case cps_provider_3_NfBinder{v_50}:
      cps_provider_3_NfOk{cps_provider_3_NfMissing{BIR.DescriptorApplication{cps_provider_3_materialize_at(v_3, v_7), cps_provider_3_materialize_at(v_5, v_7)}}}

def cps_provider_3_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      match v_8:
        case Some{"IO"}:
          True{}
        case _:
          False{}

def cps_provider_3_nf_named_io(v_1: Bool, +v_3: cps_provider_3_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_3_Nf:
  match v_1:
    case True{}:
      match v_4:
        case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
          cps_provider_3_NfOk{cps_provider_3_NfType{v_18, v_7}}
    case False{}:
      cps_provider_3_nf_reduce(v_3, v_4, v_7, v_9, Nat.sub(v_11, 1n))

def native_match_cps_provider_3_nf_named_0(v_27: Maybe<&2, BIR.Family>, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_27:
    case Some{v_25}:
      cps_provider_3_nf_family(v_25, v_6)
    case None{}:
      cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_6}}

def native_match_cps_provider_3_nf_named_1(v_26: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat, v_14: Map<&2, BIR.Family>) -> cps_provider_3_Nf:
  match v_26:
    case Some{v_18}:
      +v_20 = v_18
      cps_provider_3_nf_named_io(cps_provider_3_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10)
    case None{}:
      native_match_cps_provider_3_nf_named_0(cps_provider_3_family_of(v_3, v_14), v_3, v_6)

def native_match_cps_provider_3_nf_named_2(+v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_3_Nf:
  match v_1:
    case cps_provider_3_NfContext{v_14, v_15}:
      native_match_cps_provider_3_nf_named_1(cps_provider_3_function_of(v_3, v_15), v_1, v_3, v_6, v_8, v_10, v_14)

def cps_provider_3_nf_named(+v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_named_2(v_1, v_3, v_6, v_8, v_10)

def cps_provider_3_nf_arity(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, +v_6: Nat) -> cps_provider_3_NfArity:
  cps_provider_3_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_3_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_3_NfVal, v_2), v_6)}

def native_match_cps_provider_3_nf_family_0(v_0: BIR.Family, +v_6: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      cps_provider_3_nf_family_apply(cps_provider_3_nf_arity(v_6, v_20, v_17), v_13, v_20, v_6)

def cps_provider_3_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  +v_6 = v_3
  native_match_cps_provider_3_nf_family_0(v_0, v_6)

def cps_provider_3_nf_family_apply(v_1: cps_provider_3_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_1:
    case cps_provider_3_NfArity{v_13, v_14, v_15}:
      match v_13:
        case True{}:
          cps_provider_3_NfOk{cps_provider_3_NfType{v_3, List.append(&2, cps_provider_3_NfVal, cps_provider_3_quantity_markers(v_5), v_8)}}
        case False{}:
          match v_14:
            case True{}:
              cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_8}}
            case False{}:
              match v_15:
                case True{}:
                  cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_8}}
                case False{}:
                  cps_provider_3_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}

def native_match_cps_provider_3_nf_reduce_0(v_2: BIR.TypeFunction, +v_1: cps_provider_3_NfContext, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_2:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      +v_24 = v_20
      +v_26 = v_21
      cps_provider_3_nf_reduce_apply(cps_provider_3_nf_arity(v_12, v_24, v_26), v_1, v_18, v_24, v_26, v_22, v_12, v_7, v_9)

def cps_provider_3_nf_reduce(+v_1: cps_provider_3_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_3_Nf:
  +v_12 = v_5
  native_match_cps_provider_3_nf_reduce_0(v_2, v_1, v_7, v_9, v_12)

def cps_provider_3_nf_reduce_apply(v_1: cps_provider_3_NfArity, +v_3: cps_provider_3_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_3_NfVal>, +v_15: Nat, +v_17: Nat) -> cps_provider_3_Nf:
  match v_1:
    case cps_provider_3_NfArity{v_22, v_23, v_24}:
      match v_22:
        case True{}:
          cps_provider_3_nf_reduce_body(v_3, v_10, List.append(&2, cps_provider_3_NfVal, cps_provider_3_quantity_markers(v_7), v_13), [], v_15, Nat.sub(v_17, 1n))
        case False{}:
          match v_23:
            case True{}:
              cps_provider_3_nf_reduce_body(v_3, v_10, cps_provider_3_first_vals(v_13, v_9), cps_provider_3_drop_vals(v_13, v_9), v_15, Nat.sub(v_17, 1n))
            case False{}:
              match v_24:
                case True{}:
                  cps_provider_3_NfOk{cps_provider_3_NfType{v_5, v_13}}
                case False{}:
                  cps_provider_3_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}

def native_match_cps_provider_3_nf_reduce_body_0(v_19: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat, +v_12: Nat) -> cps_provider_3_Nf:
  match v_19:
    case cps_provider_3_NfFail{v_16}:
      cps_provider_3_NfFail{v_16}
    case cps_provider_3_NfOk{v_18}:
      cps_provider_3_nf_apply(v_1, v_18, v_8, v_10, v_12)

def cps_provider_3_nf_reduce_body(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat, +v_12: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_reduce_body_0(cps_provider_3_nf_descriptor(v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)), v_1, v_8, v_10, v_12)

def native_match_cps_provider_3_nf_cases_0(v_36: cps_provider_3_NfBind, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, v_24: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_36:
    case cps_provider_3_NfBound{v_27}:
      cps_provider_3_nf_descriptor(v_1, v_24, List.append(&2, cps_provider_3_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n))
    case cps_provider_3_NfMismatch{}:
      cps_provider_3_nf_cases(v_1, v_20, v_6, v_9, v_10, v_12, v_14)
    case cps_provider_3_NfUnknown{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_9, v_12)}}

def native_match_cps_provider_3_nf_cases_1(+v_19: BIR.Descriptor, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>) -> cps_provider_3_Nf:
  match v_19:
    case BIR.DescriptorCase{v_23, v_24}:
      native_match_cps_provider_3_nf_cases_0(cps_provider_3_bind_patterns(v_23, v_6), v_1, v_6, v_9, v_10, v_12, v_14, v_20, v_24)
    case BIR.DescriptorFailure{v_33}:
      cps_provider_3_NfFail{v_33}
    case _:
      cps_provider_3_NfFail{"descriptor match case is not a case"}

def native_match_cps_provider_3_nf_cases_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> cps_provider_3_Nf:
  match v_3:
    case []:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_9, v_12)}}
    case +v_19 <> v_20:
      native_match_cps_provider_3_nf_cases_1(v_19, v_1, v_6, v_9, v_10, v_12, v_14, v_20)

def cps_provider_3_nf_cases(+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_cases_2(v_3, v_1, v_6, v_9, v_10, v_12, v_14)

def native_match_cps_provider_3_normalize_0(v_13: cps_provider_3_Nf) -> BIR.Descriptor:
  match v_13:
    case cps_provider_3_NfFail{v_10}:
      BIR.DescriptorFailure{v_10}
    case cps_provider_3_NfOk{v_12}:
      cps_provider_3_materialize_at(v_12, 0n)

def cps_provider_3_normalize(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> BIR.Descriptor:
  native_match_cps_provider_3_normalize_0(cps_provider_3_nf(v_1, v_2, v_5, 0n, v_7))

def cps_provider_3_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_3_normalize(cps_provider_3_nf_context(v_1, v_3), v_4, [], 1024n)

def cps_provider_3_normalize_in(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_3_normalize(v_1, v_2, [], 1024n)

def cps_provider_3_outer_application(+v_0: BIR.Descriptor) -> Maybe<&2, cps_provider_3_NfApp>:
  cps_provider_3_outer_walk(v_0, [])

def cps_provider_3_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> Maybe<&2, cps_provider_3_NfApp>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      Some{cps_provider_3_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      Some{cps_provider_3_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      Some{cps_provider_3_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}
    case BIR.DescriptorFill{v_23, v_24}:
      cps_provider_3_outer_walk(v_23, List.append(&2, BIR.Descriptor, v_24, v_2))
    case BIR.DescriptorPlus{v_28, v_29}:
      cps_provider_3_outer_walk(v_28, List.append(&2, BIR.Descriptor, v_29, v_2))
    case BIR.DescriptorApplication{v_33, v_34}:
      cps_provider_3_outer_walk(v_33, List.append(&2, BIR.Descriptor, [v_34], v_2))
    case _:
      None{}

def native_match_cps_provider_3_answer_in_0(v_5: BIR.Descriptor, +v_1: cps_provider_3_NfContext) -> BIR.Descriptor:
  match v_5:
    case BIR.DescriptorFailure{_}:
      v_5
    case _:
      cps_provider_3_answer_normalized(v_1, v_5)

def cps_provider_3_answer_in(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  v_5 = cps_provider_3_normalize(v_1, v_2, [], 1024n)
  native_match_cps_provider_3_answer_in_0(v_5, v_1)

def cps_provider_3_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  cps_provider_3_answer_in(cps_provider_3_nf_context(v_2, v_4), v_0)

def native_match_cps_provider_3_answer_normalized_0(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_9:
    case []:
      v_2
    case +v_13 <> v_14:
      v_13

def native_match_cps_provider_3_answer_normalized_1(v_16: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  match v_16:
    case False{}:
      v_2
    case True{}:
      native_match_cps_provider_3_answer_normalized_0(v_9, v_2)

def native_match_cps_provider_3_answer_normalized_2(v_5: cps_provider_3_NfApp, +v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_5:
    case cps_provider_3_NfApp{v_8, v_9}:
      native_match_cps_provider_3_answer_normalized_1(cps_provider_3_is_io_head_in(v_1, v_8), v_2, v_9)

def native_match_cps_provider_3_answer_normalized_3(v_15: Maybe<&2, cps_provider_3_NfApp>, +v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_15:
    case None{}:
      v_2
    case Some{v_5}:
      native_match_cps_provider_3_answer_normalized_2(v_5, v_1, v_2)

def cps_provider_3_answer_normalized(+v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  native_match_cps_provider_3_answer_normalized_3(cps_provider_3_outer_application(v_2), v_1, v_2)

def cps_provider_3_is_io_head_in(+v_1: cps_provider_3_NfContext, +v_3: String) -> Bool:
  match v_1:
    case cps_provider_3_NfContext{v_7, v_8}:
      cps_provider_3_is_io_head(v_3, v_7, v_8)

def native_match_cps_provider_3_is_io_head_0(v_10: Maybe<&2, String>) -> Bool:
  match v_10:
    case Some{v_9}:
      String.eq(v_9, "IO")
    case None{}:
      False{}

def cps_provider_3_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Bool:
  native_match_cps_provider_3_is_io_head_0(cps_provider_3_native_of(v_1, v_3, v_5))

