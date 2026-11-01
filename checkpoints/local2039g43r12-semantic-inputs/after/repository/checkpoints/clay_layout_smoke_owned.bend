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

type cps_provider_1_Dependencies is Data:
  cps_provider_1_Dependencies{names: List<&2, String>}
  cps_provider_1_DependenciesUnknown{}

type cps_provider_1_Plan is Data:
  cps_provider_1_Plan{nodes: Map<&2, cps_provider_1_NodeResult>, arms: Map<&2, BIR.DescriptorArm>, dependencies: Map<&2, cps_provider_1_Dependencies>}

type cps_provider_1_Context is Data:
  cps_provider_1_Context{context: cps_provider_2_NfContext, families: List<&2, BIR.Family>, plan: cps_provider_1_Plan}

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

def fld(+v_0: BIR.Descriptor) -> BIR.DescriptorField:
  BIR.DescriptorField{None{}, BIR.Unrestricted{}, v_0}

def arm(+v_1: String, +v_3: List<&2, BIR.DescriptorField>) -> BIR.DescriptorArm:
  BIR.DescriptorArm{v_1, v_3}

def fam(+v_1: String, +v_4: Maybe<&2, String>, +v_6: Nat, +v_8: List<&2, BIR.DescriptorArm>) -> BIR.Family:
  BIR.Family{v_1, v_1, v_4, 0n, v_6, v_8}

def ref(+v_1: String, +v_3: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  BIR.DescriptorRef{v_1, v_3}

def par(+v_1: Nat) -> BIR.Descriptor:
  BIR.DescriptorParameter{v_1}

def fam_nat() -> BIR.Family:
  fam("Nat", Some{"Nat"}, 0n, [])

def fam_u32() -> BIR.Family:
  fam("U32", Some{"U32"}, 0n, [])

def fam_f32() -> BIR.Family:
  fam("F32", Some{"F32"}, 0n, [])

def fam_array() -> BIR.Family:
  fam("Array", Some{"Array"}, 1n, [])

def fam_io() -> BIR.Family:
  fam("IO.OP", Some{"IO.OP"}, 1n, [])

def fam_pt() -> BIR.Family:
  fam("Pt", None{}, 0n, [arm("Pt", [fld(ref("U32", [])), fld(ref("U32", []))])])

def fam_fl() -> BIR.Family:
  fam("Fl", None{}, 0n, [arm("Fl", [fld(ref("F32", [])), fld(ref("F32", []))])])

def fam_seg() -> BIR.Family:
  fam("Seg", None{}, 0n, [arm("Seg", [fld(ref("Pt", [])), fld(ref("Pt", [])), fld(ref("Fl", []))])])

def fam_w32() -> BIR.Family:
  fam("W32", None{}, 0n, [arm("W32", [fld(ref("U32", []))])])

def fam_onenat() -> BIR.Family:
  fam("OneNat", None{}, 0n, [arm("OneNat", [fld(ref("Nat", []))])])

def fam_empty() -> BIR.Family:
  fam("Empty0", None{}, 0n, [arm("Empty0", [])])

def fam_box() -> BIR.Family:
  fam("Box", None{}, 1n, [arm("Box", [fld(par(0n))])])

def fam_pair() -> BIR.Family:
  fam("Pair", None{}, 2n, [arm("Pair", [fld(par(1n)), fld(par(1n))])])

def fam_opt() -> BIR.Family:
  fam("Opt", None{}, 0n, [arm("None", []), arm("Some", [fld(ref("U32", []))])])

def fam_list() -> BIR.Family:
  fam("ListT", None{}, 0n, [arm("Cons", [fld(ref("U32", [])), fld(ref("ListT", []))])])

def families() -> List<&2, BIR.Family>:
  [fam_nat, fam_u32, fam_f32, fam_array, fam_io, fam_pt, fam_fl, fam_seg, fam_w32, fam_onenat, fam_empty, fam_box, fam_pair, fam_opt, fam_list]

def type_functions() -> List<&2, BIR.TypeFunction>:
  [BIR.TypeFunction{"MyNat", None{}, 0n, 0n, ref("Nat", [])}, BIR.TypeFunction{"MyIO", None{}, 0n, 0n, ref("IO", [ref("Nat", [])])}, BIR.TypeFunction{"IO", Some{"IO"}, 0n, 1n, BIR.DescriptorArrow{BIR.Unrestricted{}, ref("IO.OP", []), ref("IO.OP", [par(0n)])}}]

def program() -> BIR.Program:
  BIR.Program{[], [], [], families, type_functions, BIR.Library{[]}}

def both(+v_1: Bool, +v_3: Bool) -> Bool:
  match v_1:
    case True{}:
      v_3
    case False{}:
      False{}

def bool_eq(+v_1: Bool, +v_3: Bool) -> Bool:
  match v_1:
    case True{}:
      v_3
    case False{}:
      match v_3:
        case True{}:
          False{}
        case False{}:
          True{}

def fail(+v_1: Bool) -> U32:
  match v_1:
    case True{}:
      0
    case False{}:
      1

def first_word_32(+v_1: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_5 <> v_6:
      match v_5:
        case cps_provider_1_CWord32{}:
          True{}
        case _:
          False{}

def first_word_64(+v_1: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_5 <> v_6:
      match v_5:
        case cps_provider_1_CWord64{}:
          True{}
        case _:
          False{}

def first_word_box(+v_1: List<&2, cps_provider_1_CWord>) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_5 <> v_6:
      match v_5:
        case cps_provider_1_CWordBox{}:
          True{}
        case _:
          False{}

def check_pt_value(+v_0: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFailed{+v_3}:
      False{}
    case cps_provider_1_LayoutFound{+v_5}:
      match v_5:
        case cps_provider_1_LayoutData{+v_8, +v_9}:
          match v_9:
            case +v_12 <> v_13:
              match v_12:
                case cps_provider_1_LayArm{+v_16, +v_17}:
                  both(Nat.is_eq(cps_provider_1_layout_words(v_5), 2n), both(first_word_32(v_8), both(String.eq(v_16, "Pt"), Nat.is_eq(List.length(&2, cps_provider_1_Layout, v_17), 2n))))
            case []:
              False{}
        case _:
          False{}

def check_pt_node(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 2n), bool_eq(v_11, False{}))

def slot_offsets(+v_1: List<&2, cps_provider_1_NodeSlot>) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_5 <> v_6:
      match v_5:
        case cps_provider_1_NodeSlot{+v_10, +v_11, +v_12}:
          match v_6:
            case []:
              False{}
            case +v_15 <> v_16:
              match v_15:
                case cps_provider_1_NodeSlot{+v_20, +v_21, +v_22}:
                  match v_16:
                    case []:
                      False{}
                    case +v_25 <> v_26:
                      match v_25:
                        case cps_provider_1_NodeSlot{+v_30, +v_31, +v_32}:
                          match v_26:
                            case []:
                              both(Nat.is_eq(v_11, 0n), both(Nat.is_eq(v_21, 2n), Nat.is_eq(v_31, 4n)))
                            case _:
                              False{}

def check_seg_node(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 6n), both(slot_offsets(v_10), bool_eq(v_11, False{})))

def check_opt_tag(+v_0: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFailed{+v_3}:
      False{}
    case cps_provider_1_LayoutFound{+v_5}:
      match v_5:
        case cps_provider_1_LayoutData{+v_8, +v_9}:
          match v_9:
            case +v_12 <> v_13:
              match v_12:
                case cps_provider_1_LayArm{+v_16, +v_17}:
                  both(Nat.is_eq(cps_provider_1_layout_words(v_5), 2n), both(first_word_32(v_8), both(String.eq(v_16, "None"), Nat.is_eq(List.length(&2, cps_provider_1_LayArm, v_9), 2n))))
            case []:
              False{}
        case _:
          False{}

def check_w32_packed(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(bool_eq(v_11, True{}), both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 1n), first_word_32(v_9)))

def check_nat_not_packed(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(bool_eq(v_11, False{}), both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 1n), first_word_64(v_9)))

def check_empty_packed(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(bool_eq(v_11, True{}), Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 0n))

def check_box_declared_node(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(bool_eq(v_11, False{}), both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 1n), first_word_box(v_9)))

def check_box_value(+v_0: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFailed{+v_3}:
      False{}
    case cps_provider_1_LayoutFound{+v_5}:
      match v_5:
        case cps_provider_1_LayoutData{+v_8, +v_9}:
          match v_9:
            case +v_12 <> v_13:
              match v_12:
                case cps_provider_1_LayArm{+v_16, +v_17}:
                  match v_17:
                    case +v_20 <> v_21:
                      both(Nat.is_eq(cps_provider_1_layout_words(v_5), 1n), both(first_word_32(v_8), both(String.eq(v_16, "Box"), Nat.is_eq(List.length(&2, cps_provider_1_Layout, v_17), 1n))))
                    case []:
                      False{}
            case []:
              False{}
        case _:
          False{}

def check_u32_cell(+v_0: cps_provider_1_CellResult) -> Bool:
  match v_0:
    case cps_provider_1_CellFailed{+v_3}:
      False{}
    case cps_provider_1_CellFound{+v_5}:
      match v_5:
        case cps_provider_1_Cell{+v_10, +v_11, +v_12, +v_13}:
          both(bool_eq(v_11, False{}), both(Nat.is_eq(v_12, 1n), Nat.is_eq(v_13, 0n)))

def check_nat_cell(+v_0: cps_provider_1_CellResult) -> Bool:
  match v_0:
    case cps_provider_1_CellFailed{+v_3}:
      False{}
    case cps_provider_1_CellFound{+v_5}:
      match v_5:
        case cps_provider_1_Cell{+v_10, +v_11, +v_12, +v_13}:
          both(bool_eq(v_11, True{}), both(Nat.is_eq(v_12, 1n), Nat.is_eq(v_13, 0n)))

def check_pt_cell(+v_0: cps_provider_1_CellResult) -> Bool:
  match v_0:
    case cps_provider_1_CellFailed{+v_3}:
      False{}
    case cps_provider_1_CellFound{+v_5}:
      match v_5:
        case cps_provider_1_Cell{+v_10, +v_11, +v_12, +v_13}:
          both(bool_eq(v_11, False{}), both(Nat.is_eq(v_12, 2n), Nat.is_eq(v_13, 1n)))

def check_seg_cell(+v_0: cps_provider_1_CellResult) -> Bool:
  match v_0:
    case cps_provider_1_CellFailed{+v_3}:
      False{}
    case cps_provider_1_CellFound{+v_5}:
      match v_5:
        case cps_provider_1_Cell{+v_10, +v_11, +v_12, +v_13}:
          both(bool_eq(v_11, False{}), both(Nat.is_eq(v_12, 6n), Nat.is_eq(v_13, 3n)))

def check_open_cell(+v_0: cps_provider_1_CellResult) -> Bool:
  match v_0:
    case cps_provider_1_CellFailed{+v_3}:
      False{}
    case cps_provider_1_CellFound{+v_5}:
      match v_5:
        case cps_provider_1_Cell{+v_10, +v_11, +v_12, +v_13}:
          both(bool_eq(v_11, True{}), both(Nat.is_eq(v_12, 1n), Nat.is_eq(v_13, 0n)))

def check_abstract_cell(+v_0: cps_provider_1_CellResult) -> Bool:
  match v_0:
    case cps_provider_1_CellFailed{v_3}:
      False{}
    case cps_provider_1_CellFound{+v_5}:
      match v_5:
        case cps_provider_1_Cell{+v_10, +v_11, +v_12, +v_13}:
          both(bool_eq(v_11, True{}), both(Nat.is_eq(v_12, 1n), Nat.is_eq(v_13, 0n)))

def check_recursive(+v_0: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFailed{+v_3}:
      False{}
    case cps_provider_1_LayoutFound{+v_5}:
      match v_5:
        case cps_provider_1_LayoutBox{+v_7}:
          match v_7:
            case cps_provider_1_BoxRecursive{+v_9}:
              String.eq(v_9, "ListT")
            case _:
              False{}
        case _:
          False{}

def check_open_box(+v_0: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFailed{+v_3}:
      False{}
    case cps_provider_1_LayoutFound{+v_5}:
      match v_5:
        case cps_provider_1_LayoutBox{+v_7}:
          match v_7:
            case cps_provider_1_BoxUnresolved{+v_9}:
              String.eq(v_9, "Chan")
            case _:
              False{}
        case _:
          False{}

def check_failure(+v_0: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFailed{+v_3}:
      String.eq(v_3, "the checked type expression is a reducer failure")
    case cps_provider_1_LayoutFound{+v_5}:
      False{}

def nests_agree(+v_1: List<&2, cps_provider_1_Nest>, +v_3: List<&2, cps_provider_1_Nest>) -> Bool:
  match v_1:
    case []:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case +v_9 <> v_10:
      match v_9:
        case cps_provider_1_Nest{+v_15, +v_16, +v_17, +v_18}:
          match v_3:
            case []:
              False{}
            case +v_21 <> v_22:
              match v_21:
                case cps_provider_1_Nest{+v_27, +v_28, +v_29, +v_30}:
                  both(Nat.is_eq(v_15, v_28), both(Nat.is_eq(v_16, v_27), both(Nat.is_eq(cps_provider_1_fill_words(v_18), cps_provider_1_unfill_words(v_29)), both(Nat.is_eq(cps_provider_1_unfill_words(v_17), cps_provider_1_fill_words(v_30)), nests_agree(v_10, v_22)))))
    case _:
      False{}

def forms_agree(+v_1: List<&2, cps_provider_1_FormArm>, +v_3: List<&2, cps_provider_1_FormArm>) -> Bool:
  match v_1:
    case []:
      match v_3:
        case []:
          True{}
        case _:
          False{}
    case +v_9 <> v_10:
      match v_9:
        case cps_provider_1_FormArm{+v_16, +v_17, +v_18, +v_19, +v_20}:
          match v_3:
            case []:
              False{}
            case +v_23 <> v_24:
              match v_23:
                case cps_provider_1_FormArm{+v_30, +v_31, +v_32, +v_33, +v_34}:
                  both(String.eq(v_16, v_30), both(Nat.is_eq(v_17, v_31), both(bool_eq(v_18, v_32), both(Nat.is_eq(v_19, v_33), both(nests_agree(v_20, v_34), forms_agree(v_10, v_24))))))
    case _:
      False{}

def check_fill(+v_0: cps_provider_1_FillResult, +v_1: cps_provider_1_UnfillResult, +v_2: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_FillFailed{+v_5}:
      False{}
    case cps_provider_1_FillFound{+v_7}:
      match v_7:
        case cps_provider_1_FillWord{}:
          match v_1:
            case cps_provider_1_UnfillFailed{+v_9}:
              False{}
            case cps_provider_1_UnfillFound{+v_11}:
              match v_11:
                case cps_provider_1_UnfillWord{}:
                  match v_2:
                    case cps_provider_1_LayoutFailed{+v_13}:
                      False{}
                    case cps_provider_1_LayoutFound{+v_15}:
                      True{}
                case _:
                  False{}
        case cps_provider_1_FillForm{+v_20, +v_21}:
          match v_1:
            case cps_provider_1_UnfillFailed{+v_23}:
              False{}
            case cps_provider_1_UnfillFound{+v_25}:
              match v_25:
                case cps_provider_1_UnfillForm{+v_28, +v_29}:
                  match v_2:
                    case cps_provider_1_LayoutFailed{+v_31}:
                      False{}
                    case cps_provider_1_LayoutFound{+v_33}:
                      both(Nat.is_eq(v_20, v_28), forms_agree(v_21, v_29))
                case _:
                  False{}

def extract(+v_0: cps_provider_1_LayoutResult) -> cps_provider_1_Layout:
  match v_0:
    case cps_provider_1_LayoutFound{+v_2}:
      v_2
    case cps_provider_1_LayoutFailed{+v_4}:
      cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}

def check_head_nat_alias(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadFound{+v_4, +v_5}:
      match v_5:
        case Some{+v_7}:
          both(String.eq(v_4, "Nat"), String.eq(v_7, "Nat"))
        case None{}:
          False{}
    case _:
      False{}

def check_head_array(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadFound{+v_4, +v_5}:
      match v_5:
        case Some{+v_7}:
          both(String.eq(v_4, "Array"), String.eq(v_7, "Array"))
        case None{}:
          False{}
    case _:
      False{}

def check_head_plain(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadFound{+v_4, +v_5}:
      match v_5:
        case Some{+v_7}:
          False{}
        case None{}:
          String.eq(v_4, "Pt")
    case _:
      False{}

def check_head_open(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadBoxed{+v_3}:
      match v_3:
        case cps_provider_1_BoxUnresolved{+v_5}:
          String.eq(v_5, "Chan")
        case _:
          False{}
    case _:
      False{}

def check_head_failure(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadFailed{+v_3}:
      String.eq(v_3, "the checked type expression is a reducer failure")
    case _:
      False{}

def descriptor_is_ref(+v_0: BIR.Descriptor, +v_2: String) -> Bool:
  match v_0:
    case BIR.DescriptorRef{+v_6, +v_7}:
      String.eq(v_6, v_2)
    case _:
      False{}

def check_box_fields(+v_0: cps_provider_1_FieldsResult) -> Bool:
  match v_0:
    case cps_provider_1_FieldsFailed{+v_3}:
      False{}
    case cps_provider_1_FieldsFound{+v_5}:
      match v_5:
        case +v_8 <> v_9:
          match v_8:
            case BIR.DescriptorField{+v_13, +v_14, +v_15}:
              both(descriptor_is_ref(v_15, "U32"), Nat.is_eq(List.length(&2, BIR.DescriptorField, v_5), 1n))
        case []:
          False{}

def check_pair_fields(+v_0: cps_provider_1_FieldsResult) -> Bool:
  match v_0:
    case cps_provider_1_FieldsFailed{+v_3}:
      False{}
    case cps_provider_1_FieldsFound{+v_5}:
      match v_5:
        case +v_8 <> v_9:
          match v_8:
            case BIR.DescriptorField{+v_13, +v_14, +v_15}:
              match v_9:
                case +v_18 <> v_19:
                  match v_18:
                    case BIR.DescriptorField{+v_23, +v_24, +v_25}:
                      both(descriptor_is_ref(v_15, "U32"), both(descriptor_is_ref(v_25, "Nat"), Nat.is_eq(List.length(&2, BIR.DescriptorField, v_5), 2n)))
                case []:
                  False{}
        case []:
          False{}

def check_fields_failure(+v_0: cps_provider_1_FieldsResult) -> Bool:
  match v_0:
    case cps_provider_1_FieldsFailed{+v_3}:
      True{}
    case cps_provider_1_FieldsFound{+v_5}:
      False{}

def mk_words(+v_1: Nat) -> List<&2, cps_provider_1_CWord>:
  match v_1:
    case 0n:
      []
    case 1n+v_4:
      cps_provider_1_CWord32{} <> mk_words(v_4)

def mk_fields(+v_1: Nat) -> List<&2, BIR.DescriptorField>:
  match v_1:
    case 0n:
      []
    case 1n+v_4:
      fld(ref("U32", [])) <> mk_fields(v_4)

def wide_program() -> BIR.Program:
  BIR.Program{[], [], [], [fam("Wide", None{}, 0n, [arm("Wide", mk_fields(1100n))])], [], BIR.Library{[]}}

def mk_miss(+v_1: Nat) -> List<&2, BIR.DescriptorArm>:
  match v_1:
    case 0n:
      [arm("hit", [])]
    case 1n+v_5:
      arm("miss", []) <> mk_miss(v_5)

def check_ceil() -> Bool:
  both(Nat.is_eq(cps_provider_1_ceil_log2(1n), 0n), both(Nat.is_eq(cps_provider_1_ceil_log2(2n), 1n), both(Nat.is_eq(cps_provider_1_ceil_log2(3n), 2n), both(Nat.is_eq(cps_provider_1_ceil_log2(4n), 2n), both(Nat.is_eq(cps_provider_1_ceil_log2(6n), 3n), both(Nat.is_eq(cps_provider_1_ceil_log2(8n), 3n), both(Nat.is_eq(cps_provider_1_ceil_log2(16n), 4n), both(Nat.is_eq(cps_provider_1_ceil_log2(247n), 8n), both(Nat.is_eq(cps_provider_1_ceil_log2(248n), 8n), Nat.is_eq(cps_provider_1_ceil_log2(256n), 8n))))))))))

def check_pow2() -> Bool:
  both(Nat.is_eq(cps_provider_1_pow2_upto(1n, 1n), 1n), both(Nat.is_eq(cps_provider_1_pow2_upto(1n, 247n), 256n), both(Nat.is_eq(cps_provider_1_pow2_upto(1n, 248n), 256n), both(Nat.is_eq(cps_provider_1_pow2_upto(1n, 256n), 256n), Nat.is_eq(cps_provider_1_pow2_upto(1n, 300n), 512n)))))

def check_pad(+v_1: Nat, +v_3: Nat) -> Bool:
  Nat.is_eq(List.length(&2, cps_provider_1_CWord, cps_provider_1_pad_words(mk_words(v_1))), v_3)

def check_wide(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_10), 1100n), both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 2048n), bool_eq(v_11, False{})))

def check_long_arm(+v_1: Maybe<&2, BIR.DescriptorArm>) -> Bool:
  match v_1:
    case None{}:
      False{}
    case Some{+v_4}:
      True{}

def check_norm_alias(+v_0: cps_provider_1_NormResult) -> Bool:
  match v_0:
    case cps_provider_1_NormFailed{v_3}:
      False{}
    case cps_provider_1_NormOk{+v_5}:
      descriptor_is_ref(v_5, "Nat")

def first_arg_is(+v_0: BIR.Descriptor, +v_2: String) -> Bool:
  match v_0:
    case BIR.DescriptorRef{+v_6, +v_7}:
      match v_7:
        case +v_10 <> v_11:
          descriptor_is_ref(v_10, v_2)
        case []:
          False{}
    case _:
      False{}

def check_norm_distinct(+v_0: cps_provider_1_NormResult, +v_1: cps_provider_1_NormResult) -> Bool:
  match v_0:
    case cps_provider_1_NormFailed{v_4}:
      False{}
    case cps_provider_1_NormOk{+v_6}:
      match v_1:
        case cps_provider_1_NormFailed{v_8}:
          False{}
        case cps_provider_1_NormOk{+v_10}:
          both(first_arg_is(v_6, "U32"), first_arg_is(v_10, "Nat"))

def check_norm_failure(+v_0: cps_provider_1_NormResult) -> Bool:
  match v_0:
    case cps_provider_1_NormFailed{v_3}:
      True{}
    case cps_provider_1_NormOk{+v_5}:
      False{}

def args_first_is(+v_0: cps_provider_1_ArgsResult, +v_2: String) -> Bool:
  match v_0:
    case cps_provider_1_ArgsFailed{v_5}:
      False{}
    case cps_provider_1_ArgsOk{+v_7}:
      match v_7:
        case +v_10 <> v_11:
          descriptor_is_ref(v_10, v_2)
        case []:
          False{}

def check_args_pair(+v_0: cps_provider_1_ArgsResult) -> Bool:
  match v_0:
    case cps_provider_1_ArgsFailed{v_3}:
      False{}
    case cps_provider_1_ArgsOk{+v_5}:
      match v_5:
        case +v_8 <> v_9:
          match v_9:
            case +v_12 <> v_13:
              both(descriptor_is_ref(v_8, "U32"), both(descriptor_is_ref(v_12, "Nat"), Nat.is_eq(List.length(&2, BIR.Descriptor, v_5), 2n)))
            case []:
              False{}
        case []:
          False{}

def check_args_failure(+v_0: cps_provider_1_ArgsResult) -> Bool:
  match v_0:
    case cps_provider_1_ArgsFailed{v_3}:
      True{}
    case cps_provider_1_ArgsOk{+v_5}:
      False{}

def chain_key(+v_1: Nat) -> String:
  String.append("F", Nat.show(v_1))

def next_key(+v_1: Nat) -> String:
  match v_1:
    case 0n:
      "U32"
    case 1n+v_4:
      chain_key(v_4)

def fam_chain(+v_1: Nat) -> List<&2, BIR.Family>:
  match v_1:
    case 0n:
      [BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, []}]
    case 1n+v_4:
      +v_7 = chain_key(v_4)
      +v_10 = next_key(v_4)
      BIR.Family{v_7, v_7, None{}, 0n, 0n, [BIR.DescriptorArm{v_7, [BIR.DescriptorField{None{}, BIR.Unrestricted{}, BIR.DescriptorRef{v_10, []}}]}]} <> fam_chain(v_4)

def program_shadow() -> BIR.Program:
  BIR.Program{[], [], [], [fam_nat], [BIR.TypeFunction{"IO", None{}, 0n, 1n, ref("Nat", [])}], BIR.Library{[]}}

def check_io_native(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadFound{+v_4, +v_5}:
      match v_5:
        case Some{+v_7}:
          both(String.eq(v_4, "IO"), String.eq(v_7, "IO"))
        case None{}:
          False{}
    case _:
      False{}

def check_io_under(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadBoxed{+v_3}:
      match v_3:
        case cps_provider_1_BoxOpen{}:
          True{}
        case _:
          False{}
    case _:
      False{}

def check_shadow_io(+v_0: cps_provider_1_HeadResult) -> Bool:
  match v_0:
    case cps_provider_1_HeadFound{+v_4, +v_5}:
      match v_5:
        case Some{+v_7}:
          both(String.eq(v_4, "Nat"), String.eq(v_7, "Nat"))
        case None{}:
          False{}
    case _:
      False{}

def program_deep() -> BIR.Program:
  BIR.Program{[], [], [], fam_chain(400n), [], BIR.Library{[]}}

def classify(+v_0: cps_provider_1_LayoutResult) -> Nat:
  match v_0:
    case cps_provider_1_LayoutFailed{v_3}:
      1n
    case cps_provider_1_LayoutFound{+v_5}:
      match v_5:
        case cps_provider_1_LayoutData{+v_8, +v_9}:
          match v_8:
            case +v_12 <> v_13:
              match v_12:
                case cps_provider_1_CWord32{}:
                  match v_13:
                    case []:
                      match v_9:
                        case +v_16 <> v_17:
                          0n
                        case []:
                          2n
                    case _:
                      2n
                case _:
                  2n
            case []:
              2n
        case cps_provider_1_LayoutBox{+v_23}:
          1n
        case _:
          2n

def deep_chain_check() -> Bool:
  +v_3 = cps_provider_1_context(program_deep)
  Nat.is_eq(classify(cps_provider_1_value_layout(v_3, BIR.DescriptorRef{"F399", []})), 0n)

def erased_fld() -> BIR.DescriptorField:
  BIR.DescriptorField{None{}, BIR.Erased{}, ref("U32", [])}

def fam_erased() -> BIR.Family:
  fam("Er", None{}, 0n, [arm("Er", [fld(ref("U32", [])), erased_fld, fld(ref("Nat", []))])])

def families_plan() -> List<&2, BIR.Family>:
  fam_erased <> families

def row_pt() -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{0, "Pt", None{}, []}

def row_er() -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{1, "Er", None{}, []}

def row_w32() -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{2, "W32", None{}, []}

def program_rows() -> BIR.Program:
  BIR.Program{[], [], [row_pt, row_er, row_w32], families_plan, type_functions, BIR.Library{[]}}

def fam_pt3() -> BIR.Family:
  fam("Pt", None{}, 0n, [arm("Pt", [fld(ref("U32", [])), fld(ref("U32", [])), fld(ref("U32", []))])])

def program_scope() -> BIR.Program:
  BIR.Program{[], [], [row_pt], [fam_nat, fam_u32, fam_pt3], type_functions, BIR.Library{[]}}

def fam_same_one() -> BIR.Family:
  fam("One", None{}, 0n, [arm("Same", [fld(ref("U32", []))])])

def fam_same_two() -> BIR.Family:
  fam("Two", None{}, 0n, [arm("Same", [fld(ref("U32", [])), fld(ref("U32", []))])])

def program_first() -> BIR.Program:
  BIR.Program{[], [], [BIR.ConstructorLayout{0, "Same", None{}, []}], [fam_nat, fam_u32, fam_same_one, fam_same_two], type_functions, BIR.Library{[]}}

def erased_slot_ordinals(+v_1: List<&2, cps_provider_1_NodeSlot>) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_5 <> v_6:
      match v_5:
        case cps_provider_1_NodeSlot{+v_10, +v_11, +v_12}:
          match v_6:
            case []:
              False{}
            case +v_15 <> v_16:
              match v_15:
                case cps_provider_1_NodeSlot{+v_20, +v_21, +v_22}:
                  both(U32.is_eq(v_10, 0), both(U32.is_eq(v_20, U32.from_nat(2n)), both(Nat.is_eq(v_11, 0n), both(Nat.is_eq(v_21, 1n), both(Nat.is_eq(cps_provider_1_layout_words(v_12), 1n), Nat.is_eq(cps_provider_1_layout_words(v_22), 1n))))))

def check_erased_node(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(bool_eq(v_11, False{}), both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 2n), both(first_word_32(v_9), both(Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_10), 2n), erased_slot_ordinals(v_10)))))

def check_three_word_node(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(bool_eq(v_11, False{}), both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 3n), Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_10), 3n)))

def check_packed_one(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      False{}
    case cps_provider_1_NodeFound{+v_5}:
      match v_5:
        case cps_provider_1_Node{+v_9, +v_10, +v_11}:
          both(bool_eq(v_11, True{}), both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_9), 1n), both(first_word_32(v_9), Nat.is_eq(List.length(&2, cps_provider_1_NodeSlot, v_10), 1n))))

def check_node_failed(+v_0: cps_provider_1_NodeResult) -> Bool:
  match v_0:
    case cps_provider_1_NodeFailed{+v_3}:
      True{}
    case cps_provider_1_NodeFound{+v_5}:
      False{}

def check_declared_count(+v_1: Maybe<&2, BIR.DescriptorArm>, +v_3: Nat) -> Bool:
  match v_1:
    case None{}:
      False{}
    case Some{+v_6}:
      match v_6:
        case BIR.DescriptorArm{+v_9, +v_10}:
          Nat.is_eq(List.length(&2, BIR.DescriptorField, v_10), v_3)

def check_declared_none(+v_1: Maybe<&2, BIR.DescriptorArm>) -> Bool:
  match v_1:
    case None{}:
      True{}
    case Some{+v_4}:
      False{}

def recursion_layout(+v_1: List<&2, BIR.DescriptorField>, +v_3: List<&2, BIR.Family>, +v_5: List<&2, BIR.TypeFunction>) -> cps_provider_1_LayoutResult:
  +v_9 = fam("ListT", None{}, 0n, [arm("Root", v_1)])
  +v_12 = cps_provider_1_context(BIR.Program{[], [], [], v_9 <> fam_u32 <> v_3, v_5, BIR.Library{[]}})
  cps_provider_1_value_layout(v_12, ref("ListT", []))

def recursion_functions() -> List<&2, BIR.TypeFunction>:
  [BIR.TypeFunction{"Alias1", None{}, 0n, 0n, ref("Alias2", [])}, BIR.TypeFunction{"Alias2", None{}, 0n, 0n, ref("ListT", [])}, BIR.TypeFunction{"Identity", None{}, 0n, 1n, par(0n)}, BIR.TypeFunction{"Discard", None{}, 0n, 1n, ref("U32", [])}]

def recursive_descriptors() -> List<&2, BIR.Descriptor>:
  +v_3 = ref("ListT", [])
  +v_5 = {BIR.DescriptorLambda{None{}, v_3} : BIR.Descriptor}
  +v_7 = {BIR.DescriptorBinder{BIR.Unrestricted{}} : BIR.DescriptorPattern}
  [ref("Alias1", []), BIR.DescriptorApplication{ref("Identity", []), v_3}, BIR.DescriptorApplication{v_5, BIR.DescriptorNull{}}, BIR.DescriptorMatch{[BIR.DescriptorConstructor{"Held", [v_3]}], [BIR.DescriptorCase{[BIR.DescriptorConstructorPattern{"Held", [v_7]}], par(0n)}]}, BIR.DescriptorMatch{[BIR.DescriptorNull{}], [BIR.DescriptorCase{[v_7], v_3}]}, BIR.DescriptorSubstitution{0n, v_3, par(0n)}, BIR.DescriptorLet{[v_3], par(0n)}, BIR.DescriptorLocal{[v_7], [v_3], par(0n)}, BIR.DescriptorBind{v_3, par(0n)}, BIR.DescriptorFill{v_5, [BIR.DescriptorNull{}]}, BIR.DescriptorPlus{v_5, [BIR.DescriptorNull{}]}, BIR.DescriptorNamedFill{"Alias1", ref("U32", []), []}, BIR.DescriptorNamedPlus{"Alias1", ref("U32", []), []}, ref("Opaque", [v_3])]

def recursive_descriptor_failures(+v_1: List<&2, BIR.Descriptor>, +v_3: List<&2, BIR.TypeFunction>) -> U32:
  match v_1:
    case []:
      0
    case +v_7 <> v_8:
      +v_12 = recursion_layout([fld(v_7)], [], v_3)
      U32.add(fail(check_recursive(v_12)), recursive_descriptor_failures(v_8, v_3))

def check_single_box_field(+v_0: cps_provider_1_LayoutResult) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFound{+v_3}:
      match v_3:
        case cps_provider_1_LayoutData{+v_6, +v_7}:
          both(Nat.is_eq(List.length(&2, cps_provider_1_CWord, v_6), 1n), first_word_box(v_6))
        case _:
          False{}
    case _:
      False{}

def check_recursive_key(+v_0: cps_provider_1_LayoutResult, +v_2: String) -> Bool:
  match v_0:
    case cps_provider_1_LayoutFound{+v_5}:
      match v_5:
        case cps_provider_1_LayoutBox{+v_7}:
          match v_7:
            case cps_provider_1_BoxRecursive{+v_9}:
              String.eq(v_9, v_2)
            case _:
              False{}
        case _:
          False{}
    case _:
      False{}

def generic_recursion_check() -> Bool:
  +v_6 = fam("Apply", None{}, 1n, [arm("Apply", [fld(BIR.DescriptorApplication{par(0n), BIR.DescriptorNull{}})])])
  +v_10 = cps_provider_1_context(BIR.Program{[], [], [], [fam_box, fam_u32, v_6], [], BIR.Library{[]}})
  +v_15 = cps_provider_1_value_layout(v_10, ref("Box", [ref("Box", [ref("U32", [])])]))
  +v_18 = {BIR.DescriptorLambda{None{}, ref("Apply", [BIR.DescriptorNull{}])} : BIR.Descriptor}
  +v_21 = cps_provider_1_value_layout(v_10, ref("Apply", [v_18]))
  both(check_recursive_key(v_15, "Box"), check_recursive_key(v_21, "Apply"))

def duplicate_recursion_check() -> Bool:
  +v_6 = fam("ListT", None{}, 0n, [arm("Root", [fld(ref("ListT", []))])])
  +v_12 = fam("ListT", None{}, 0n, [arm("Root", [fld(ref("U32", []))])])
  +v_15 = cps_provider_1_context(BIR.Program{[], [], [], [v_6, v_12, fam_u32], [], BIR.Library{[]}})
  +v_18 = cps_provider_1_context(BIR.Program{[], [], [], [v_12, v_6, fam_u32], [], BIR.Library{[]}})
  +v_21 = {BIR.TypeFunction{"Alias", None{}, 0n, 0n, ref("ListT", [])} : BIR.TypeFunction}
  +v_24 = {BIR.TypeFunction{"Alias", None{}, 0n, 0n, ref("U32", [])} : BIR.TypeFunction}
  +v_27 = cps_provider_1_value_layout(v_15, ref("ListT", []))
  +v_30 = cps_provider_1_value_layout(v_18, ref("ListT", []))
  +v_35 = recursion_layout([fld(ref("Alias", []))], [], [v_21, v_24])
  +v_40 = recursion_layout([fld(ref("Alias", []))], [], [v_24, v_21])
  both(check_recursive(v_27), both(Nat.is_eq(classify(v_30), 0n), both(check_recursive(v_35), Nat.is_eq(classify(v_40), 0n))))

def target_exclusion_boundaries() -> U32:
  +v_6 = fam("Wrap", None{}, 1n, [arm("Wrap", [fld(par(0n))])])
  +v_13 = fam("Bridge", None{}, 0n, [arm("Bridge", [fld(ref("Wrap", [ref("U32", [])]))])])
  +v_19 = fam("CycleLeft", None{}, 0n, [arm("CycleLeft", [fld(ref("CycleRight", []))])])
  +v_25 = fam("CycleRight", None{}, 0n, [arm("CycleRight", [fld(ref("CycleLeft", []))])])
  +v_31 = fam("Leaf", None{}, 0n, [arm("Leaf", [fld(ref("U32", []))])])
  +v_36 = fam("Broken", None{}, 0n, [arm("Broken", [fld(BIR.DescriptorFailure{"the checked type expression is a reducer failure"})])])
  +v_40 = cps_provider_1_context(BIR.Program{[], [], [], [v_6, v_13, v_19, v_25, v_31, v_36, fam_u32, fam_array], [], BIR.Library{[]}})
  +v_44 = cps_provider_1_value_layout(v_40, ref("Wrap", [ref("Bridge", [])]))
  +v_47 = cps_provider_1_value_layout(v_40, ref("Bridge", []))
  +v_51 = cps_provider_1_value_layout(v_40, ref("Wrap", [ref("CycleLeft", [])]))
  +v_55 = cps_provider_1_value_layout(v_40, ref("Wrap", [ref("Leaf", [])]))
  +v_59 = cps_provider_1_value_layout(v_40, ref("Wrap", [ref("Broken", [])]))
  +v_64 = cps_provider_1_value_layout(v_40, ref("Wrap", [ref("Array", [ref("Leaf", [])])]))
  +v_70 = cps_provider_1_value_layout(v_40, ref("Wrap", [ref("Array", [ref("Wrap", [ref("U32", [])])])]))
  +v_76 = U32.add(fail(check_recursive_key(v_44, "Wrap")), fail(check_recursive_key(v_70, "Wrap")))
  +v_86 = U32.add(fail(Nat.is_eq(classify(v_47), 0n)), U32.add(fail(check_single_box_field(v_51)), U32.add(fail(Nat.is_eq(classify(v_55), 0n)), fail(check_single_box_field(v_64)))))
  U32.add(v_76, U32.add(v_86, fail(check_failure(v_59))))

def target_closure_authority_check() -> Bool:
  +v_6 = fam("Wrap", None{}, 1n, [arm("Wrap", [fld(par(0n))])])
  +v_12 = fam("Relay", None{}, 1n, [arm("Relay", [fld(BIR.DescriptorApplication{par(0n), BIR.DescriptorNull{}})])])
  +v_18 = fam("Relay", None{}, 0n, [arm("Relay", [fld(ref("U32", []))])])
  +v_21 = cps_provider_1_context(BIR.Program{[], [], [], [v_6, v_12, v_18, fam_u32], [], BIR.Library{[]}})
  +v_24 = cps_provider_1_context(BIR.Program{[], [], [], [v_6, v_18, v_12, fam_u32], [], BIR.Library{[]}})
  +v_28 = {BIR.DescriptorLambda{None{}, ref("Wrap", [ref("U32", [])])} : BIR.Descriptor}
  +v_32 = cps_provider_1_value_layout(v_21, ref("Wrap", [ref("Relay", [v_28])]))
  +v_36 = cps_provider_1_value_layout(v_24, ref("Wrap", [ref("Relay", [])]))
  both(check_recursive_key(v_32, "Wrap"), Nat.is_eq(classify(v_36), 0n))

def explicit_recursion_check() -> Bool:
  +v_6 = fam("Closed", None{}, 0n, [arm("Closed", [fld(ref("U32", []))])])
  +v_9 = cps_provider_1_context(BIR.Program{[], [], [], [v_6, fam_u32], [], BIR.Library{[]}})
  +v_14 = [arm("Closed", [fld(ref("Closed", []))])]
  +v_17 = fam("Closed", None{}, 0n, v_14)
  +v_23 = fam("Closed", None{}, 0n, [arm("Closed", [fld(ref("Target", []))])])
  +v_25 = cps_provider_1_layout_family(v_9, v_17, [], cps_provider_1_layout_fuel)
  +v_27 = cps_provider_1_layout_data(v_9, "Closed", v_14, [], cps_provider_1_layout_fuel)
  +v_29 = cps_provider_1_layout_native(v_9, "Other", "Closed", v_14, [], cps_provider_1_layout_fuel)
  +v_31 = cps_provider_1_family_reach(v_9, v_23, [], "Target", [], cps_provider_1_layout_fuel)
  +v_33 = cps_provider_1_reenters(v_9, "Closed", v_14, [], cps_provider_1_layout_fuel)
  both(check_recursive_key(v_25, "Closed"), both(check_recursive_key(v_27, "Closed"), both(check_recursive_key(v_29, "Closed"), both(v_31, v_33))))

def recursion_boundaries() -> U32:
  +v_3 = recursion_functions
  +v_6 = ref("ListT", [])
  +v_8 = {BIR.DescriptorField{None{}, BIR.Erased{}, v_6} : BIR.DescriptorField}
  +v_13 = recursion_layout([v_8, fld(ref("U32", []))], [], [])
  +v_19 = recursion_layout([erased_fld, fld(par(0n))], [], [])
  +v_25 = recursion_layout([erased_fld, fld(BIR.DescriptorLet{[v_6], par(0n)})], [], [])
  +v_29 = recursion_layout([fld(BIR.DescriptorLambda{None{}, v_6})], [], [])
  +v_34 = recursion_layout([fld(ref("Discard", [v_6]))], [], v_3)
  +v_40 = fam("Other", None{}, 0n, [arm("Other", [fld(ref("Other", []))])])
  +v_45 = recursion_layout([fld(ref("Other", []))], [v_40], [])
  +v_49 = recursive_descriptor_failures(recursive_descriptors, v_3)
  +v_57 = U32.add(fail(Nat.is_eq(classify(v_13), 0n)), U32.add(fail(check_single_box_field(v_19)), fail(check_recursive(v_25))))
  +v_65 = U32.add(fail(check_single_box_field(v_29)), U32.add(fail(Nat.is_eq(classify(v_34), 0n)), fail(check_single_box_field(v_45))))
  +v_71 = U32.add(v_49, U32.add(v_57, U32.add(v_65, U32.add(fail(generic_recursion_check), fail(duplicate_recursion_check)))))
  U32.add(v_71, U32.add(target_exclusion_boundaries, U32.add(fail(target_closure_authority_check), fail(explicit_recursion_check))))

def main(v_1: List<&2, Loader.LoadedModule>) -> ClaySmoke:
  +v_5 = cps_provider_1_context(program)
  +v_8 = cps_provider_1_value_layout(v_5, ref("Pt", []))
  +v_10 = cps_provider_1_node_layout(v_5, "Pt")
  +v_12 = cps_provider_1_node_layout(v_5, "Seg")
  +v_15 = cps_provider_1_value_layout(v_5, ref("Opt", []))
  +v_17 = cps_provider_1_node_layout(v_5, "W32")
  +v_19 = cps_provider_1_node_layout(v_5, "OneNat")
  +v_21 = cps_provider_1_node_layout(v_5, "Empty0")
  +v_23 = cps_provider_1_node_layout(v_5, "Box")
  +v_27 = cps_provider_1_value_layout(v_5, ref("Box", [ref("U32", [])]))
  +v_30 = cps_provider_1_array_cell(v_5, ref("U32", []))
  +v_33 = cps_provider_1_array_cell(v_5, ref("Nat", []))
  +v_36 = cps_provider_1_array_cell(v_5, ref("Pt", []))
  +v_39 = cps_provider_1_array_cell(v_5, ref("Seg", []))
  +v_42 = cps_provider_1_array_cell(v_5, par(0n))
  +v_45 = cps_provider_1_array_cell(v_5, ref("Chan", []))
  +v_48 = cps_provider_1_value_layout(v_5, ref("ListT", []))
  +v_51 = cps_provider_1_value_layout(v_5, ref("Chan", []))
  +v_53 = cps_provider_1_value_layout(v_5, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +v_56 = cps_provider_1_value_layout(v_5, ref("Seg", []))
  +v_59 = cps_provider_1_layout_fill(v_5, extract(v_15))
  +v_62 = cps_provider_1_layout_unfill(v_5, extract(v_15))
  +v_65 = cps_provider_1_layout_fill(v_5, extract(v_56))
  +v_68 = cps_provider_1_layout_unfill(v_5, extract(v_56))
  +v_71 = cps_provider_1_head_native(v_5, ref("MyNat", []))
  +v_75 = cps_provider_1_head_native(v_5, ref("Array", [ref("U32", [])]))
  +v_78 = cps_provider_1_head_native(v_5, ref("Pt", []))
  +v_81 = cps_provider_1_head_native(v_5, ref("Chan", []))
  +v_83 = cps_provider_1_head_native(v_5, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +v_87 = cps_provider_1_arm_fields(v_5, "Box", ref("Box", [ref("U32", [])]))
  +v_92 = cps_provider_1_arm_fields(v_5, "Pair", ref("Pair", [ref("U32", []), ref("Nat", [])]))
  +v_94 = cps_provider_1_arm_fields(v_5, "Box", BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +v_98 = fail(check_pt_value(v_8))
  +v_102 = fail(check_pt_node(v_10))
  +v_106 = fail(check_seg_node(v_12))
  +v_110 = fail(check_opt_tag(v_15))
  +v_114 = fail(check_w32_packed(v_17))
  +v_118 = fail(check_nat_not_packed(v_19))
  +v_122 = fail(check_empty_packed(v_21))
  +v_126 = fail(check_box_declared_node(v_23))
  +v_130 = fail(check_box_value(v_27))
  +v_134 = fail(check_u32_cell(v_30))
  +v_138 = fail(check_nat_cell(v_33))
  +v_142 = fail(check_pt_cell(v_36))
  +v_146 = fail(check_seg_cell(v_39))
  +v_150 = fail(check_open_cell(v_42))
  +v_154 = fail(check_recursive(v_48))
  +v_158 = fail(check_open_box(v_51))
  +v_162 = fail(check_failure(v_53))
  +v_166 = fail(check_fill(v_59, v_62, v_15))
  +v_170 = fail(check_fill(v_65, v_68, v_56))
  +v_174 = fail(check_head_nat_alias(v_71))
  +v_178 = fail(check_head_array(v_75))
  +v_182 = fail(check_head_plain(v_78))
  +v_186 = fail(check_head_open(v_81))
  +v_190 = fail(check_head_failure(v_83))
  +v_194 = fail(check_box_fields(v_87))
  +v_198 = fail(check_pair_fields(v_92))
  +v_202 = fail(check_fields_failure(v_94))
  +v_206 = fail(check_abstract_cell(v_45))
  +v_209 = cps_provider_1_context(wide_program)
  +v_211 = cps_provider_1_node_layout(v_209, "Wide")
  +v_214 = cps_provider_1_arm_in("hit", mk_miss(1500n))
  v_218 = fail(check_ceil)
  v_222 = fail(check_pow2)
  v_226 = fail(check_pad(247n, 247n))
  v_230 = fail(check_pad(248n, 256n))
  v_234 = fail(check_pad(256n, 256n))
  v_238 = fail(check_pad(300n, 512n))
  v_242 = fail(check_wide(v_211))
  v_246 = fail(check_long_arm(v_214))
  +v_249 = cps_provider_1_norm(v_5, ref("MyNat", []))
  +v_254 = cps_provider_1_norm(v_5, ref("Pair", [ref("U32", []), ref("Nat", [])]))
  +v_259 = cps_provider_1_norm(v_5, ref("Pair", [ref("Nat", []), ref("U32", [])]))
  +v_261 = cps_provider_1_norm(v_5, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +v_265 = cps_provider_1_head_args(v_5, ref("Array", [ref("U32", [])]))
  +v_270 = cps_provider_1_head_args(v_5, ref("Pair", [ref("U32", []), ref("Nat", [])]))
  +v_272 = cps_provider_1_head_args(v_5, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  v_276 = fail(check_norm_alias(v_249))
  v_280 = fail(check_norm_distinct(v_254, v_259))
  v_284 = fail(check_norm_failure(v_261))
  v_288 = fail(args_first_is(v_265, "U32"))
  v_292 = fail(check_args_pair(v_270))
  v_296 = fail(check_args_failure(v_272))
  +v_299 = cps_provider_1_context(program_rows)
  +v_301 = cps_provider_1_node_layout(v_299, "Pt")
  +v_303 = cps_provider_1_node_layout(v_299, "Box")
  +v_307 = cps_provider_1_value_layout(v_299, ref("Box", [ref("U32", [])]))
  +v_309 = cps_provider_1_node_layout(v_299, "W32")
  +v_311 = cps_provider_1_node_layout(v_299, "Er")
  +v_313 = cps_provider_1_node_layout_fuel(v_299, "Pt", 1n)
  +v_316 = cps_provider_1_context(program_scope)
  +v_318 = cps_provider_1_node_layout(v_316, "Pt")
  +v_321 = cps_provider_1_context(program_first)
  +v_323 = cps_provider_1_node_layout(v_321, "Same")
  +v_325 = cps_provider_1_arm_declared(v_299, "Pt")
  +v_327 = cps_provider_1_arm_declared(v_299, "Er")
  +v_329 = cps_provider_1_arm_declared(v_299, "Chan")
  +v_331 = cps_provider_1_arm_declared(v_321, "Same")
  +v_333 = cps_provider_1_node_layout(v_5, "Pt")
  +v_361 = U32.add(fail(check_pt_node(v_301)), U32.add(fail(check_box_declared_node(v_303)), U32.add(fail(check_box_value(v_307)), U32.add(fail(check_w32_packed(v_309)), U32.add(fail(check_erased_node(v_311)), U32.add(fail(check_node_failed(v_313)), U32.add(fail(check_three_word_node(v_318)), U32.add(fail(check_packed_one(v_323)), U32.add(fail(check_declared_count(v_325, 2n)), U32.add(fail(check_declared_count(v_327, 3n)), U32.add(fail(check_declared_none(v_329)), U32.add(fail(check_declared_count(v_331, 1n)), fail(check_pt_node(v_333))))))))))))))
  +v_364 = U32.add(v_361, recursion_boundaries)
  ClaySmoke{U32.add(v_364, U32.add(v_98, U32.add(v_102, U32.add(v_106, U32.add(v_110, U32.add(v_114, U32.add(v_118, U32.add(v_122, U32.add(v_126, U32.add(v_130, U32.add(v_134, U32.add(v_138, U32.add(v_142, U32.add(v_146, U32.add(v_150, U32.add(v_154, U32.add(v_158, U32.add(v_162, U32.add(v_166, U32.add(v_170, U32.add(v_174, U32.add(v_178, U32.add(v_182, U32.add(v_186, U32.add(v_190, U32.add(v_194, U32.add(v_198, U32.add(v_202, U32.add(v_206, U32.add(v_218, U32.add(v_222, U32.add(v_226, U32.add(v_230, U32.add(v_234, U32.add(v_238, U32.add(v_242, U32.add(v_246, U32.add(v_276, U32.add(v_280, U32.add(v_284, U32.add(v_288, U32.add(v_292, U32.add(v_296, U32.add(fail(deep_chain_check), U32.add(fail(check_io_native(cps_provider_1_head_native(v_5, ref("IO", [ref("Nat", [])])))), U32.add(fail(check_io_under(cps_provider_1_head_native(v_5, ref("IO", [])))), U32.add(fail(check_io_native(cps_provider_1_head_native(v_5, ref("MyIO", [])))), fail(check_shadow_io(cps_provider_1_head_native(cps_provider_1_context(program_shadow), ref("IO", [ref("Nat", [])])))))))))))))))))))))))))))))))))))))))))))))))))))}

def cps_provider_1_context(+v_0: BIR.Program) -> cps_provider_1_Context:
  match v_0:
    case BIR.Program{+v_8, +v_9, +v_10, +v_11, +v_12, +v_13}:
      +v_15 = cps_provider_2_nf_context(v_11, v_12)
      +v_18 = cps_provider_1_plan_arm_index(v_11)
      +v_23 = cps_provider_1_dependency_functions(v_12, cps_provider_1_dependency_families(v_11, Map.new(&2, cps_provider_1_Dependencies)))
      +v_27 = {cps_provider_1_Context{v_15, v_11, cps_provider_1_Plan{Map.new(&2, cps_provider_1_NodeResult), v_18, v_23}} : cps_provider_1_Context}
      cps_provider_1_Context{v_15, v_11, cps_provider_1_Plan{cps_provider_1_plan_node_index(v_27, v_10), v_18, v_23}}

def cps_provider_1_context_nf(+v_1: cps_provider_1_Context) -> cps_provider_2_NfContext:
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

def native_match_cps_provider_1_context_nodes_0(v_11: cps_provider_1_Plan) -> Map<&2, cps_provider_1_NodeResult>:
  match v_11:
    case cps_provider_1_Plan{+v_8, +v_9, +v_10}:
      v_8

def cps_provider_1_context_nodes(+v_1: cps_provider_1_Context) -> Map<&2, cps_provider_1_NodeResult>:
  native_match_cps_provider_1_context_nodes_0(cps_provider_1_context_plan(v_1))

def native_match_cps_provider_1_context_arms_0(v_10: cps_provider_1_Plan) -> Map<&2, BIR.DescriptorArm>:
  match v_10:
    case cps_provider_1_Plan{+v_7, +v_8, +v_9}:
      v_8

def cps_provider_1_context_arms(+v_1: cps_provider_1_Context) -> Map<&2, BIR.DescriptorArm>:
  native_match_cps_provider_1_context_arms_0(cps_provider_1_context_plan(v_1))

def native_match_cps_provider_1_context_dependencies_0(v_11: cps_provider_1_Plan) -> Map<&2, cps_provider_1_Dependencies>:
  match v_11:
    case cps_provider_1_Plan{+v_8, +v_9, +v_10}:
      v_10

def cps_provider_1_context_dependencies(+v_1: cps_provider_1_Context) -> Map<&2, cps_provider_1_Dependencies>:
  native_match_cps_provider_1_context_dependencies_0(cps_provider_1_context_plan(v_1))

def cps_provider_1_nf_families(+v_0: cps_provider_2_NfContext) -> Map<&2, BIR.Family>:
  match v_0:
    case cps_provider_2_NfContext{+v_4, +v_5}:
      v_4

def cps_provider_1_nf_functions(+v_0: cps_provider_2_NfContext) -> Map<&2, BIR.TypeFunction>:
  match v_0:
    case cps_provider_2_NfContext{+v_4, +v_5}:
      v_5

def cps_provider_1_family_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> Maybe<&2, BIR.Family>:
  cps_provider_2_family_of(v_3, cps_provider_1_nf_families(cps_provider_1_context_nf(v_1)))

def cps_provider_1_function_lookup(+v_1: cps_provider_1_Context, +v_3: String) -> Maybe<&2, BIR.TypeFunction>:
  cps_provider_2_function_of(v_3, cps_provider_1_nf_functions(cps_provider_1_context_nf(v_1)))

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

def native_match_cps_provider_1_dependency_seed_0(v_9: Maybe<&2, cps_provider_1_Dependencies>) -> cps_provider_1_Dependencies:
  match v_9:
    case Some{+v_8}:
      v_8
    case None{}:
      cps_provider_1_Dependencies{[]}

def cps_provider_1_dependency_seed(+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String) -> cps_provider_1_Dependencies:
  native_match_cps_provider_1_dependency_seed_0(IndexLookup.find(cps_provider_1_Dependencies, v_2, v_4))

def cps_provider_1_dependency_name(+v_1: String, +v_3: cps_provider_1_Dependencies) -> cps_provider_1_Dependencies:
  match v_3:
    case cps_provider_1_Dependencies{+v_6}:
      cps_provider_1_Dependencies{v_1 <> v_6}
    case cps_provider_1_DependenciesUnknown{}:
      cps_provider_1_DependenciesUnknown{}

def cps_provider_1_dependency_descriptors(+v_1: List<&2, BIR.Descriptor>, +v_3: cps_provider_1_Dependencies) -> cps_provider_1_Dependencies:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      cps_provider_1_dependency_descriptors(v_8, cps_provider_1_dependency_descriptor(v_7, v_3))

def cps_provider_1_dependency_patterns(+v_1: List<&2, BIR.DescriptorPattern>, +v_3: cps_provider_1_Dependencies) -> cps_provider_1_Dependencies:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      match v_7:
        case BIR.DescriptorBinder{+v_10}:
          cps_provider_1_dependency_patterns(v_8, v_3)
        case BIR.DescriptorConstructorPattern{+v_14, +v_15}:
          cps_provider_1_dependency_patterns(v_8, cps_provider_1_dependency_patterns(v_15, v_3))
        case _:
          cps_provider_1_DependenciesUnknown{}

def cps_provider_1_dependency_descriptor(+v_0: BIR.Descriptor, +v_2: cps_provider_1_Dependencies) -> cps_provider_1_Dependencies:
  match v_0:
    case BIR.DescriptorNull{}:
      v_2
    case BIR.DescriptorParameter{+v_5}:
      v_2
    case BIR.DescriptorQuantityKind{}:
      v_2
    case BIR.DescriptorQuantity{+v_7}:
      v_2
    case BIR.DescriptorReflexivity{}:
      v_2
    case BIR.DescriptorFailure{+v_9}:
      v_2
    case BIR.DescriptorRef{+v_12, +v_13}:
      cps_provider_1_dependency_descriptors(v_13, cps_provider_1_dependency_name(v_12, v_2))
    case BIR.DescriptorConstructor{+v_18, +v_19}:
      cps_provider_1_dependency_descriptors(v_19, v_2)
    case BIR.DescriptorKind{+v_22}:
      cps_provider_1_dependency_descriptor(v_22, v_2)
    case BIR.DescriptorMinimum{+v_26, +v_27}:
      cps_provider_1_dependency_descriptor(v_27, cps_provider_1_dependency_descriptor(v_26, v_2))
    case BIR.DescriptorArrow{+v_33, +v_34, +v_35}:
      cps_provider_1_dependency_descriptor(v_35, cps_provider_1_dependency_descriptor(v_34, v_2))
    case BIR.DescriptorLambda{+v_40, +v_41}:
      cps_provider_1_dependency_descriptor(v_41, v_2)
    case BIR.DescriptorApplication{+v_45, +v_46}:
      cps_provider_1_dependency_descriptor(v_46, cps_provider_1_dependency_descriptor(v_45, v_2))
    case BIR.DescriptorSubstitution{+v_52, +v_53, +v_54}:
      cps_provider_1_dependency_descriptor(v_54, cps_provider_1_dependency_descriptor(v_53, v_2))
    case BIR.DescriptorLet{+v_59, +v_60}:
      cps_provider_1_dependency_descriptor(v_60, cps_provider_1_dependency_descriptors(v_59, v_2))
    case BIR.DescriptorLocal{+v_66, +v_67, +v_68}:
      cps_provider_1_dependency_descriptor(v_68, cps_provider_1_dependency_descriptors(v_67, cps_provider_1_dependency_patterns(v_66, v_2)))
    case BIR.DescriptorMatch{+v_74, +v_75}:
      cps_provider_1_dependency_descriptors(v_75, cps_provider_1_dependency_descriptors(v_74, v_2))
    case BIR.DescriptorCase{+v_80, +v_81}:
      cps_provider_1_dependency_descriptor(v_81, cps_provider_1_dependency_patterns(v_80, v_2))
    case BIR.DescriptorBind{+v_86, +v_87}:
      cps_provider_1_dependency_descriptor(v_87, cps_provider_1_dependency_descriptor(v_86, v_2))
    case BIR.DescriptorEquality{+v_93, +v_94, +v_95}:
      cps_provider_1_dependency_descriptor(v_95, cps_provider_1_dependency_descriptor(v_94, cps_provider_1_dependency_descriptor(v_93, v_2)))
    case BIR.DescriptorFill{+v_101, +v_102}:
      cps_provider_1_dependency_descriptors(v_102, cps_provider_1_dependency_descriptor(v_101, v_2))
    case BIR.DescriptorPlus{+v_107, +v_108}:
      cps_provider_1_dependency_descriptors(v_108, cps_provider_1_dependency_descriptor(v_107, v_2))
    case BIR.DescriptorNamedFill{+v_114, +v_115, +v_116}:
      cps_provider_1_dependency_descriptors(v_116, cps_provider_1_dependency_descriptor(v_115, cps_provider_1_dependency_name(v_114, v_2)))
    case BIR.DescriptorNamedPlus{+v_123, +v_124, +v_125}:
      cps_provider_1_dependency_descriptors(v_125, cps_provider_1_dependency_descriptor(v_124, cps_provider_1_dependency_name(v_123, v_2)))
    case _:
      cps_provider_1_DependenciesUnknown{}

def cps_provider_1_dependency_fields(+v_1: List<&2, BIR.DescriptorField>, +v_3: cps_provider_1_Dependencies) -> cps_provider_1_Dependencies:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      match v_7:
        case BIR.DescriptorField{+v_12, +v_13, +v_14}:
          cps_provider_1_dependency_fields(v_8, cps_provider_1_dependency_descriptor(v_14, v_3))

def cps_provider_1_dependency_arms(+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_1_Dependencies) -> cps_provider_1_Dependencies:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      match v_7:
        case BIR.DescriptorArm{+v_11, +v_12}:
          cps_provider_1_dependency_arms(v_8, cps_provider_1_dependency_fields(v_12, v_3))

def cps_provider_1_dependency_families(+v_1: List<&2, BIR.Family>, +v_4: Map<&2, cps_provider_1_Dependencies>) -> Map<&2, cps_provider_1_Dependencies>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      match v_9:
        case BIR.Family{+v_17, +v_18, +v_19, +v_20, +v_21, +v_22}:
          +v_26 = cps_provider_1_dependency_arms(v_22, cps_provider_1_dependency_seed(v_4, v_17))
          cps_provider_1_dependency_families(v_10, Map.set(&2, cps_provider_1_Dependencies, v_4, v_17, v_26))

def cps_provider_1_dependency_functions(+v_1: List<&2, BIR.TypeFunction>, +v_4: Map<&2, cps_provider_1_Dependencies>) -> Map<&2, cps_provider_1_Dependencies>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      match v_9:
        case BIR.TypeFunction{+v_16, +v_17, +v_18, +v_19, +v_20}:
          +v_24 = cps_provider_1_dependency_descriptor(v_20, cps_provider_1_dependency_seed(v_4, v_16))
          cps_provider_1_dependency_functions(v_10, Map.set(&2, cps_provider_1_Dependencies, v_4, v_16, v_24))

def native_match_cps_provider_1_dependency_maybe_reaches_0(+v_32: cps_provider_1_Dependencies, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, v_16: List<&2, List<&2, String>>, v_21: List<&2, String>, +v_28: Map<&2, Bool>) -> Bool:
  match v_32:
    case cps_provider_1_DependenciesUnknown{}:
      True{}
    case cps_provider_1_Dependencies{+v_34}:
      cps_provider_1_dependency_maybe_reaches(v_2, v_4, v_34 <> v_21 <> v_16, v_28)

def native_match_cps_provider_1_dependency_maybe_reaches_1(v_37: Maybe<&2, cps_provider_1_Dependencies>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, v_16: List<&2, List<&2, String>>, v_21: List<&2, String>, +v_28: Map<&2, Bool>) -> Bool:
  match v_37:
    case None{}:
      cps_provider_1_dependency_maybe_reaches(v_2, v_4, v_21 <> v_16, v_28)
    case Some{+v_32}:
      native_match_cps_provider_1_dependency_maybe_reaches_0(v_32, v_2, v_4, v_16, v_21, v_28)

def native_match_cps_provider_1_dependency_maybe_reaches_2(v_36: Maybe<&2, Bool>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_11: Map<&2, Bool>, v_16: List<&2, List<&2, String>>, +v_20: String, v_21: List<&2, String>) -> Bool:
  match v_36:
    case Some{+v_24}:
      cps_provider_1_dependency_maybe_reaches(v_2, v_4, v_21 <> v_16, v_11)
    case None{}:
      +v_28 = Map.set(&2, Bool, v_11, v_20, True{})
      native_match_cps_provider_1_dependency_maybe_reaches_1(IndexLookup.find(cps_provider_1_Dependencies, v_2, v_20), v_2, v_4, v_16, v_21, v_28)

def native_match_cps_provider_1_dependency_maybe_reaches_3(v_35: Bool, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_11: Map<&2, Bool>, v_16: List<&2, List<&2, String>>, +v_20: String, v_21: List<&2, String>) -> Bool:
  match v_35:
    case True{}:
      True{}
    case False{}:
      native_match_cps_provider_1_dependency_maybe_reaches_2(IndexLookup.find(Bool, v_11, v_20), v_2, v_4, v_11, v_16, v_20, v_21)

def native_match_cps_provider_1_dependency_maybe_reaches_4(+v_15: List<&2, String>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_11: Map<&2, Bool>, v_16: List<&2, List<&2, String>>) -> Bool:
  match v_15:
    case []:
      cps_provider_1_dependency_maybe_reaches(v_2, v_4, v_16, v_11)
    case +v_20 <> v_21:
      native_match_cps_provider_1_dependency_maybe_reaches_3(String.eq(v_20, v_4), v_2, v_4, v_11, v_16, v_20, v_21)

def native_match_cps_provider_1_dependency_maybe_reaches_5(+v_8: List<&2, List<&2, String>>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_11: Map<&2, Bool>) -> Bool:
  match v_8:
    case []:
      False{}
    case +v_15 <> v_16:
      native_match_cps_provider_1_dependency_maybe_reaches_4(v_15, v_2, v_4, v_11, v_16)

def cps_provider_1_dependency_maybe_reaches(+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_8: List<&2, List<&2, String>>, +v_11: Map<&2, Bool>) -> Bool:
  native_match_cps_provider_1_dependency_maybe_reaches_5(v_8, v_2, v_4, v_11)

def native_match_cps_provider_1_dependency_excludes_0(v_16: Bool) -> Bool:
  match v_16:
    case True{}:
      False{}
    case False{}:
      True{}

def native_match_cps_provider_1_dependency_excludes_1(+v_10: cps_provider_1_Dependencies, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_6: String) -> Bool:
  match v_10:
    case cps_provider_1_DependenciesUnknown{}:
      False{}
    case cps_provider_1_Dependencies{+v_12}:
      native_match_cps_provider_1_dependency_excludes_0(cps_provider_1_dependency_maybe_reaches(v_2, v_6, [v_12], Map.new(&2, Bool)))

def native_match_cps_provider_1_dependency_excludes_2(v_15: Maybe<&2, cps_provider_1_Dependencies>, +v_2: Map<&2, cps_provider_1_Dependencies>, +v_6: String) -> Bool:
  match v_15:
    case None{}:
      False{}
    case Some{+v_10}:
      native_match_cps_provider_1_dependency_excludes_1(v_10, v_2, v_6)

def cps_provider_1_dependency_excludes(+v_2: Map<&2, cps_provider_1_Dependencies>, +v_4: String, +v_6: String) -> Bool:
  native_match_cps_provider_1_dependency_excludes_2(IndexLookup.find(cps_provider_1_Dependencies, v_2, v_4), v_2, v_6)

def cps_provider_1_layout_fuel() -> Nat:
  1024n

def cps_provider_1_nf_of(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: Nat) -> cps_provider_2_Nf:
  cps_provider_2_nf(cps_provider_1_context_nf(v_1), v_2, v_4, 0n, v_6)

def cps_provider_1_value_layout(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_LayoutResult:
  cps_provider_1_layout_of_desc(v_1, v_2, [], cps_provider_1_layout_fuel)

def native_match_cps_provider_1_layout_of_desc_0(v_14: cps_provider_2_Nf, +v_1: cps_provider_1_Context, +v_7: Nat) -> cps_provider_1_LayoutResult:
  match v_14:
    case cps_provider_2_NfFail{+v_11}:
      cps_provider_1_LayoutFailed{v_11}
    case cps_provider_2_NfOk{+v_13}:
      cps_provider_1_layout_of_val(v_1, v_13, v_7)

def cps_provider_1_layout_of_desc(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_of_desc_0(cps_provider_1_nf_of(v_1, v_2, v_5, v_7), v_1, v_7)

def native_match_cps_provider_1_layout_of_val_0(v_6: Bool, +v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat) -> cps_provider_1_LayoutResult:
  match v_6:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case False{}:
      cps_provider_1_layout_val(v_1, v_3, Nat.sub(v_5, 1n))

def cps_provider_1_layout_of_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_of_val_0(Nat.is_eq(v_5, 0n), v_1, v_3, v_5)

def native_match_cps_provider_1_layout_val_0(v_30: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_5: Nat, +v_9: String, +v_10: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_LayoutResult:
  match v_30:
    case Some{+v_13}:
      cps_provider_1_layout_family_rule(v_1, v_13, v_10, v_5, True{})
    case None{}:
      cps_provider_1_layout_unresolved(v_1, v_9)

def native_match_cps_provider_1_layout_val_1(+v_3: cps_provider_2_NfVal, +v_1: cps_provider_1_Context, +v_5: Nat) -> cps_provider_1_LayoutResult:
  match v_3:
    case cps_provider_2_NfType{+v_9, +v_10}:
      native_match_cps_provider_1_layout_val_0(cps_provider_1_family_lookup(v_1, v_9), v_1, v_5, v_9, v_10)
    case cps_provider_2_NfCtor{+v_18, +v_19}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_2_NfQuantity{+v_21}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_2_NfKind{+v_23}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_2_NfOther{+v_25}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case cps_provider_2_NfMissing{+v_27}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case _:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}

def cps_provider_1_layout_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: Nat) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_val_1(v_3, v_1, v_5)

def native_match_cps_provider_1_layout_unresolved_0(v_8: Maybe<&2, BIR.TypeFunction>, +v_3: String) -> cps_provider_1_LayoutResult:
  match v_8:
    case Some{+v_7}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case None{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxUnresolved{v_3}}}

def cps_provider_1_layout_unresolved(+v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_unresolved_0(cps_provider_1_function_lookup(v_1, v_3), v_3)

def cps_provider_1_layout_family(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: Nat) -> cps_provider_1_LayoutResult:
  cps_provider_1_layout_family_rule(v_1, v_2, v_4, v_6, False{})

def native_match_cps_provider_1_layout_family_rule_0(+v_19: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Bool, +v_17: String, +v_22: List<&2, BIR.DescriptorArm>) -> cps_provider_1_LayoutResult:
  match v_19:
    case Some{+v_25}:
      cps_provider_1_layout_native_rule(v_1, v_25, v_17, v_22, v_5, v_7, v_9)
    case None{}:
      cps_provider_1_layout_data_rule(v_1, v_17, v_22, v_5, v_7, v_9)

def native_match_cps_provider_1_layout_family_rule_1(v_26: Bool, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Bool, +v_17: String, +v_19: Maybe<&2, String>, +v_22: List<&2, BIR.DescriptorArm>) -> cps_provider_1_LayoutResult:
  match v_26:
    case False{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxOpen{}}}
    case True{}:
      native_match_cps_provider_1_layout_family_rule_0(v_19, v_1, v_5, v_7, v_9, v_17, v_22)

def native_match_cps_provider_1_layout_family_rule_2(+v_2: BIR.Family, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Bool) -> cps_provider_1_LayoutResult:
  match v_2:
    case BIR.Family{+v_17, +v_18, +v_19, +v_20, +v_21, +v_22}:
      native_match_cps_provider_1_layout_family_rule_1(Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_5), v_21), v_1, v_5, v_7, v_9, v_17, v_19, v_22)

def cps_provider_1_layout_family_rule(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Bool) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_family_rule_2(v_2, v_1, v_5, v_7, v_9)

def cps_provider_1_layout_native(+v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_9: List<&2, cps_provider_2_NfVal>, +v_11: Nat) -> cps_provider_1_LayoutResult:
  cps_provider_1_layout_native_rule(v_1, v_3, v_5, v_7, v_9, v_11, False{})

def native_match_cps_provider_1_layout_native_rule_0(v_19: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Bool) -> cps_provider_1_LayoutResult:
  match v_19:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxIo{}}}
    case False{}:
      cps_provider_1_layout_data_rule(v_1, v_5, v_7, v_10, v_12, v_14)

def native_match_cps_provider_1_layout_native_rule_1(v_18: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Bool) -> cps_provider_1_LayoutResult:
  match v_18:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxArray{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_rule_0(String.eq(v_3, "IO.OP"), v_1, v_5, v_7, v_10, v_12, v_14)

def native_match_cps_provider_1_layout_native_rule_2(v_17: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Bool) -> cps_provider_1_LayoutResult:
  match v_17:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_rule_1(String.eq(v_3, "Array"), v_1, v_3, v_5, v_7, v_10, v_12, v_14)

def native_match_cps_provider_1_layout_native_rule_3(v_16: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Bool) -> cps_provider_1_LayoutResult:
  match v_16:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord32{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_rule_2(String.eq(v_3, "F32"), v_1, v_3, v_5, v_7, v_10, v_12, v_14)

def native_match_cps_provider_1_layout_native_rule_4(v_15: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Bool) -> cps_provider_1_LayoutResult:
  match v_15:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutWord{cps_provider_1_CWord64{}}}
    case False{}:
      native_match_cps_provider_1_layout_native_rule_3(String.eq(v_3, "U32"), v_1, v_3, v_5, v_7, v_10, v_12, v_14)

def cps_provider_1_layout_native_rule(+v_1: cps_provider_1_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_2_NfVal>, +v_12: Nat, +v_14: Bool) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_native_rule_4(String.eq(v_3, "Nat"), v_1, v_3, v_5, v_7, v_10, v_12, v_14)

def cps_provider_1_field_scope(+v_1: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  +v_4 = {cps_provider_2_NfMissing{BIR.DescriptorNull{}} : cps_provider_2_NfVal}
  List.append(&2, cps_provider_2_NfVal, v_1, [v_4])

def native_match_cps_provider_1_arm_layouts_0(v_27: cps_provider_1_Layouts, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>, v_17: List<&2, BIR.DescriptorArm>, +v_20: String) -> cps_provider_1_Plans:
  match v_27:
    case cps_provider_1_LayoutsFail{+v_24}:
      cps_provider_1_PlansFail{v_24}
    case cps_provider_1_LayoutsOk{+v_26}:
      cps_provider_1_arm_layouts(v_1, v_17, v_6, v_8, cps_provider_1_LayArm{v_20, v_26} <> v_11)

def native_match_cps_provider_1_arm_layouts_1(+v_16: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>, v_17: List<&2, BIR.DescriptorArm>) -> cps_provider_1_Plans:
  match v_16:
    case BIR.DescriptorArm{+v_20, +v_21}:
      native_match_cps_provider_1_arm_layouts_0(cps_provider_1_field_layouts(v_1, v_21, v_6, v_8, []), v_1, v_6, v_8, v_11, v_17, v_20)

def native_match_cps_provider_1_arm_layouts_2(+v_3: List<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>) -> cps_provider_1_Plans:
  match v_3:
    case []:
      cps_provider_1_PlansOk{List.reverse(&2, cps_provider_1_LayArm, v_11)}
    case +v_16 <> v_17:
      native_match_cps_provider_1_arm_layouts_1(v_16, v_1, v_6, v_8, v_11, v_17)

def cps_provider_1_arm_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_LayArm>) -> cps_provider_1_Plans:
  native_match_cps_provider_1_arm_layouts_2(v_3, v_1, v_6, v_8, v_11)

def native_match_cps_provider_1_field_layouts_0(v_35: cps_provider_1_LayoutResult, +v_1: cps_provider_1_Context, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, v_17: List<&2, BIR.DescriptorField>, +v_26: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_Layouts:
  match v_35:
    case cps_provider_1_LayoutFailed{+v_31}:
      cps_provider_1_LayoutsFail{v_31}
    case cps_provider_1_LayoutFound{+v_33}:
      cps_provider_1_field_layouts(v_1, v_17, v_26, v_8, v_33 <> v_11)

def native_match_cps_provider_1_field_layouts_1(v_34: Bool, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, v_17: List<&2, BIR.DescriptorField>, +v_23: BIR.Descriptor, +v_26: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_Layouts:
  match v_34:
    case False{}:
      cps_provider_1_field_layouts(v_1, v_17, v_26, v_8, v_11)
    case True{}:
      native_match_cps_provider_1_field_layouts_0(cps_provider_1_layout_of_desc(v_1, v_23, v_6, v_8), v_1, v_8, v_11, v_17, v_26)

def native_match_cps_provider_1_field_layouts_2(+v_16: BIR.DescriptorField, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>, v_17: List<&2, BIR.DescriptorField>) -> cps_provider_1_Layouts:
  match v_16:
    case BIR.DescriptorField{+v_21, +v_22, +v_23}:
      +v_26 = cps_provider_1_field_scope(v_6)
      native_match_cps_provider_1_field_layouts_1(cps_provider_1_live_field(v_22), v_1, v_6, v_8, v_11, v_17, v_23, v_26)

def native_match_cps_provider_1_field_layouts_3(+v_3: List<&2, BIR.DescriptorField>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> cps_provider_1_Layouts:
  match v_3:
    case []:
      cps_provider_1_LayoutsOk{List.reverse(&2, cps_provider_1_Layout, v_11)}
    case +v_16 <> v_17:
      native_match_cps_provider_1_field_layouts_2(v_16, v_1, v_6, v_8, v_11, v_17)

def cps_provider_1_field_layouts(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_1_Layout>) -> cps_provider_1_Layouts:
  native_match_cps_provider_1_field_layouts_3(v_3, v_1, v_6, v_8, v_11)

def cps_provider_1_layout_data(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat) -> cps_provider_1_LayoutResult:
  cps_provider_1_layout_data_result(v_1, v_3, v_5, v_7, v_9, cps_provider_1_reenters(v_1, v_3, v_5, v_7, v_9))

def native_match_cps_provider_1_layout_data_rule_0(+v_8: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_10: Nat) -> cps_provider_1_LayoutResult:
  match v_8:
    case []:
      cps_provider_1_layout_data_result(v_1, v_3, v_5, v_8, v_10, cps_provider_1_data_reenters(v_1, v_3, v_10))
    case _:
      cps_provider_1_layout_data(v_1, v_3, v_5, v_8, v_10)

def native_match_cps_provider_1_layout_data_rule_1(+v_12: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> cps_provider_1_LayoutResult:
  match v_12:
    case True{}:
      native_match_cps_provider_1_layout_data_rule_0(v_8, v_1, v_3, v_5, v_10)
    case False{}:
      cps_provider_1_layout_data(v_1, v_3, v_5, v_8, v_10)

def cps_provider_1_layout_data_rule(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Bool) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_data_rule_1(v_12, v_1, v_3, v_5, v_8, v_10)

def native_match_cps_provider_1_layout_data_result_0(v_27: Bool, +v_18: List<&2, cps_provider_1_LayArm>, +v_22: List<&2, cps_provider_1_CWord>, +v_25: Nat) -> cps_provider_1_LayoutResult:
  match v_27:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxWide{v_25}}}
    case False{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutData{v_22, v_18}}

def native_match_cps_provider_1_layout_data_result_1(v_26: cps_provider_1_Plans) -> cps_provider_1_LayoutResult:
  match v_26:
    case cps_provider_1_PlansFail{+v_16}:
      cps_provider_1_LayoutFailed{v_16}
    case cps_provider_1_PlansOk{+v_18}:
      +v_22 = cps_provider_1_pack_arms(v_18, cps_provider_1_arms_tagged(v_18))
      +v_25 = List.length(&2, cps_provider_1_CWord, v_22)
      native_match_cps_provider_1_layout_data_result_0(Nat.is_gt(v_25, 8n), v_18, v_22, v_25)

def native_match_cps_provider_1_layout_data_result_2(+v_12: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> cps_provider_1_LayoutResult:
  match v_12:
    case True{}:
      cps_provider_1_LayoutFound{cps_provider_1_LayoutBox{cps_provider_1_BoxRecursive{v_3}}}
    case False{}:
      native_match_cps_provider_1_layout_data_result_1(cps_provider_1_arm_layouts(v_1, v_5, v_8, v_10, []))

def cps_provider_1_layout_data_result(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Bool) -> cps_provider_1_LayoutResult:
  native_match_cps_provider_1_layout_data_result_2(v_12, v_1, v_3, v_5, v_8, v_10)

def native_match_cps_provider_1_data_reenters_0(v_24: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_21: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_24:
    case True{}:
      False{}
    case False{}:
      cps_provider_1_reenters(v_1, v_3, v_21, [], v_5)

def native_match_cps_provider_1_data_reenters_1(v_23: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat, +v_21: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_23:
    case True{}:
      native_match_cps_provider_1_data_reenters_0(cps_provider_1_dependency_excludes(cps_provider_1_context_dependencies(v_1), v_3, v_3), v_1, v_3, v_5, v_21)
    case False{}:
      cps_provider_1_reenters(v_1, v_3, v_21, [], v_5)

def native_match_cps_provider_1_data_reenters_2(+v_9: BIR.Family, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> Bool:
  match v_9:
    case BIR.Family{+v_16, +v_17, +v_18, +v_19, +v_20, +v_21}:
      native_match_cps_provider_1_data_reenters_1(Nat.is_eq(v_20, 0n), v_1, v_3, v_5, v_21)

def native_match_cps_provider_1_data_reenters_3(v_22: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> Bool:
  match v_22:
    case None{}:
      False{}
    case Some{+v_9}:
      native_match_cps_provider_1_data_reenters_2(v_9, v_1, v_3, v_5)

def cps_provider_1_data_reenters(+v_1: cps_provider_1_Context, +v_3: String, +v_5: Nat) -> Bool:
  native_match_cps_provider_1_data_reenters_3(cps_provider_1_family_lookup(v_1, v_3), v_1, v_3, v_5)

def cps_provider_1_arms_tagged(+v_2: List<&2, cps_provider_1_LayArm>) -> Bool:
  match v_2:
    case []:
      False{}
    case [+v_5]:
      False{}
    case _:
      True{}

def native_match_cps_provider_1_reenters_0(v_22: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_22:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_reenters(v_1, v_3, v_16, v_8, v_10)

def native_match_cps_provider_1_reenters_1(v_23: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_20: List<&2, BIR.DescriptorField>) -> Bool:
  match v_23:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_fields_reach(v_1, v_20, v_8, v_3, [], v_10)

def native_match_cps_provider_1_reenters_2(v_21: Bool, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>, +v_20: List<&2, BIR.DescriptorField>) -> Bool:
  match v_21:
    case True{}:
      native_match_cps_provider_1_reenters_0(cps_provider_1_fields_reach(v_1, v_20, v_8, v_3, [], v_10), v_1, v_3, v_8, v_10, v_16)
    case False{}:
      native_match_cps_provider_1_reenters_1(cps_provider_1_reenters(v_1, v_3, v_16, v_8, v_10), v_1, v_3, v_8, v_10, v_20)

def native_match_cps_provider_1_reenters_3(+v_15: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, v_16: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_15:
    case BIR.DescriptorArm{+v_19, +v_20}:
      native_match_cps_provider_1_reenters_2(cps_provider_1_fields_self_reference(v_20, v_3), v_1, v_3, v_8, v_10, v_16, v_20)

def native_match_cps_provider_1_reenters_4(+v_5: List<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> Bool:
  match v_5:
    case []:
      cps_provider_1_args_reach(v_1, v_8, v_3, [], v_10)
    case +v_15 <> v_16:
      native_match_cps_provider_1_reenters_3(v_15, v_1, v_3, v_8, v_10, v_16)

def cps_provider_1_reenters(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> Bool:
  native_match_cps_provider_1_reenters_4(v_5, v_1, v_3, v_8, v_10)

def native_match_cps_provider_1_fields_self_reference_0(v_25: Bool, +v_3: String, v_8: List<&2, BIR.DescriptorField>) -> Bool:
  match v_25:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_fields_self_reference(v_8, v_3)

def native_match_cps_provider_1_fields_self_reference_1(+v_14: BIR.Descriptor, +v_3: String, v_8: List<&2, BIR.DescriptorField>) -> Bool:
  match v_14:
    case BIR.DescriptorRef{+v_19, +v_20}:
      native_match_cps_provider_1_fields_self_reference_0(String.eq(v_19, v_3), v_3, v_8)
    case _:
      cps_provider_1_fields_self_reference(v_8, v_3)

def native_match_cps_provider_1_fields_self_reference_2(v_24: Bool, +v_3: String, v_8: List<&2, BIR.DescriptorField>, +v_14: BIR.Descriptor) -> Bool:
  match v_24:
    case False{}:
      cps_provider_1_fields_self_reference(v_8, v_3)
    case True{}:
      native_match_cps_provider_1_fields_self_reference_1(v_14, v_3, v_8)

def native_match_cps_provider_1_fields_self_reference_3(+v_7: BIR.DescriptorField, +v_3: String, v_8: List<&2, BIR.DescriptorField>) -> Bool:
  match v_7:
    case BIR.DescriptorField{+v_12, +v_13, +v_14}:
      native_match_cps_provider_1_fields_self_reference_2(cps_provider_1_live_field(v_13), v_3, v_8, v_14)

def native_match_cps_provider_1_fields_self_reference_4(+v_1: List<&2, BIR.DescriptorField>, +v_3: String) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_7 <> v_8:
      native_match_cps_provider_1_fields_self_reference_3(v_7, v_3, v_8)

def cps_provider_1_fields_self_reference(+v_1: List<&2, BIR.DescriptorField>, +v_3: String) -> Bool:
  native_match_cps_provider_1_fields_self_reference_4(v_1, v_3)

def native_match_cps_provider_1_fields_reach_0(v_29: Bool, +v_1: cps_provider_1_Context, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorField>, +v_27: List<&2, cps_provider_2_NfVal>) -> Bool:
  match v_29:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_fields_reach(v_1, v_18, v_27, v_8, v_11, v_13)

def native_match_cps_provider_1_fields_reach_1(v_28: Bool, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorField>, +v_24: BIR.Descriptor, +v_27: List<&2, cps_provider_2_NfVal>) -> Bool:
  match v_28:
    case False{}:
      cps_provider_1_fields_reach(v_1, v_18, v_27, v_8, v_11, v_13)
    case True{}:
      native_match_cps_provider_1_fields_reach_0(cps_provider_1_reaches(v_1, v_24, v_6, v_8, v_11, v_13), v_1, v_8, v_11, v_13, v_18, v_27)

def native_match_cps_provider_1_fields_reach_2(+v_17: BIR.DescriptorField, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorField>) -> Bool:
  match v_17:
    case BIR.DescriptorField{+v_22, +v_23, +v_24}:
      +v_27 = cps_provider_1_field_scope(v_6)
      native_match_cps_provider_1_fields_reach_1(cps_provider_1_live_field(v_23), v_1, v_6, v_8, v_11, v_13, v_18, v_24, v_27)

def native_match_cps_provider_1_fields_reach_3(+v_3: List<&2, BIR.DescriptorField>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  match v_3:
    case []:
      False{}
    case +v_17 <> v_18:
      native_match_cps_provider_1_fields_reach_2(v_17, v_1, v_6, v_8, v_11, v_13, v_18)

def cps_provider_1_fields_reach(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  native_match_cps_provider_1_fields_reach_3(v_3, v_1, v_6, v_8, v_11, v_13)

def native_match_cps_provider_1_reaches_0(v_20: cps_provider_2_Nf, +v_1: cps_provider_1_Context, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_20:
    case cps_provider_2_NfFail{+v_16}:
      False{}
    case cps_provider_2_NfOk{+v_18}:
      cps_provider_1_reaches_val(v_1, v_18, v_7, v_10, Nat.sub(v_12, 1n))

def native_match_cps_provider_1_reaches_1(v_19: Bool, +v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_19:
    case True{}:
      False{}
    case False{}:
      native_match_cps_provider_1_reaches_0(cps_provider_1_nf_of(v_1, v_2, v_5, v_12), v_1, v_7, v_10, v_12)

def cps_provider_1_reaches(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  native_match_cps_provider_1_reaches_1(Nat.is_eq(v_12, 0n), v_1, v_2, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_reaches_val_0(v_28: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_15: List<&2, cps_provider_2_NfVal>) -> Bool:
  match v_28:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_args_reach(v_1, v_15, v_5, v_8, v_10)

def native_match_cps_provider_1_reaches_val_1(v_27: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String, +v_15: List<&2, cps_provider_2_NfVal>) -> Bool:
  match v_27:
    case None{}:
      cps_provider_1_args_reach(v_1, v_15, v_5, v_8, v_10)
    case Some{+v_20}:
      native_match_cps_provider_1_reaches_val_0(cps_provider_1_context_family_reach(v_1, v_20, v_15, v_5, v_14 <> v_8, v_10), v_1, v_5, v_8, v_10, v_15)

def native_match_cps_provider_1_reaches_val_2(v_26: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String, +v_15: List<&2, cps_provider_2_NfVal>) -> Bool:
  match v_26:
    case True{}:
      False{}
    case False{}:
      native_match_cps_provider_1_reaches_val_1(cps_provider_1_family_lookup(v_1, v_14), v_1, v_5, v_8, v_10, v_14, v_15)

def native_match_cps_provider_1_reaches_val_3(v_25: Bool, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat, +v_14: String, +v_15: List<&2, cps_provider_2_NfVal>) -> Bool:
  match v_25:
    case True{}:
      True{}
    case False{}:
      native_match_cps_provider_1_reaches_val_2(cps_provider_1_str_member(v_8, v_14), v_1, v_5, v_8, v_10, v_14, v_15)

def native_match_cps_provider_1_reaches_val_4(+v_3: cps_provider_2_NfVal, +v_1: cps_provider_1_Context, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> Bool:
  match v_3:
    case cps_provider_2_NfType{+v_14, +v_15}:
      native_match_cps_provider_1_reaches_val_3(String.eq(v_14, v_5), v_1, v_5, v_8, v_10, v_14, v_15)
    case _:
      False{}

def cps_provider_1_reaches_val(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal, +v_5: String, +v_8: List<&2, String>, +v_10: Nat) -> Bool:
  native_match_cps_provider_1_reaches_val_4(v_3, v_1, v_5, v_8, v_10)

def native_match_cps_provider_1_context_family_reach_0(v_34: Bool, +v_1: cps_provider_1_Context, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_20: String, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_34:
    case True{}:
      False{}
    case False{}:
      cps_provider_1_context_reach_arms(v_1, v_20, v_25, v_7, v_10, v_12)

def native_match_cps_provider_1_context_family_reach_1(+v_22: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_20: String, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_22:
    case Some{+v_28}:
      native_match_cps_provider_1_context_family_reach_0(String.eq(v_28, "Array"), v_1, v_7, v_10, v_12, v_20, v_25)
    case None{}:
      cps_provider_1_context_reach_arms(v_1, v_20, v_25, v_7, v_10, v_12)

def native_match_cps_provider_1_context_family_reach_2(v_33: Bool, +v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_20: String, +v_22: Maybe<&2, String>, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_33:
    case False{}:
      cps_provider_1_family_reach(v_1, v_2, v_5, v_7, v_10, v_12)
    case True{}:
      native_match_cps_provider_1_context_family_reach_1(v_22, v_1, v_7, v_10, v_12, v_20, v_25)

def native_match_cps_provider_1_context_family_reach_3(+v_2: BIR.Family, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_2:
    case BIR.Family{+v_20, +v_21, +v_22, +v_23, +v_24, +v_25}:
      native_match_cps_provider_1_context_family_reach_2(Nat.is_eq(v_24, 0n), v_1, v_2, v_5, v_7, v_10, v_12, v_20, v_22, v_25)

def native_match_cps_provider_1_context_family_reach_4(+v_5: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_5:
    case []:
      native_match_cps_provider_1_context_family_reach_3(v_2, v_1, v_5, v_7, v_10, v_12)
    case _:
      cps_provider_1_family_reach(v_1, v_2, v_5, v_7, v_10, v_12)

def cps_provider_1_context_family_reach(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  native_match_cps_provider_1_context_family_reach_4(v_5, v_1, v_2, v_7, v_10, v_12)

def native_match_cps_provider_1_context_reach_arms_0(v_13: Bool, +v_1: cps_provider_1_Context, +v_5: List<&2, BIR.DescriptorArm>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_13:
    case True{}:
      False{}
    case False{}:
      cps_provider_1_reach_arms(v_1, v_5, [], v_7, v_10, v_12)

def cps_provider_1_context_reach_arms(+v_1: cps_provider_1_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  native_match_cps_provider_1_context_reach_arms_0(cps_provider_1_dependency_excludes(cps_provider_1_context_dependencies(v_1), v_3, v_7), v_1, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_family_reach_0(v_30: Bool, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_30:
    case True{}:
      False{}
    case False{}:
      cps_provider_1_reach_arms(v_1, v_25, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_family_reach_1(+v_22: Maybe<&2, String>, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_22:
    case Some{+v_28}:
      native_match_cps_provider_1_family_reach_0(String.eq(v_28, "Array"), v_1, v_5, v_7, v_10, v_12, v_25)
    case None{}:
      cps_provider_1_reach_arms(v_1, v_25, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_family_reach_2(v_29: Bool, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat, +v_22: Maybe<&2, String>, +v_25: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_29:
    case False{}:
      False{}
    case True{}:
      native_match_cps_provider_1_family_reach_1(v_22, v_1, v_5, v_7, v_10, v_12, v_25)

def native_match_cps_provider_1_family_reach_3(+v_2: BIR.Family, +v_1: cps_provider_1_Context, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  match v_2:
    case BIR.Family{+v_20, +v_21, +v_22, +v_23, +v_24, +v_25}:
      native_match_cps_provider_1_family_reach_2(Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_5), v_24), v_1, v_5, v_7, v_10, v_12, v_22, v_25)

def cps_provider_1_family_reach(+v_1: cps_provider_1_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat) -> Bool:
  native_match_cps_provider_1_family_reach_3(v_2, v_1, v_5, v_7, v_10, v_12)

def native_match_cps_provider_1_reach_arms_0(v_23: Bool, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_23:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_reach_arms(v_1, v_18, v_6, v_8, v_11, v_13)

def native_match_cps_provider_1_reach_arms_1(+v_17: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat, v_18: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_17:
    case BIR.DescriptorArm{+v_21, +v_22}:
      native_match_cps_provider_1_reach_arms_0(cps_provider_1_fields_reach(v_1, v_22, v_6, v_8, v_11, v_13), v_1, v_6, v_8, v_11, v_13, v_18)

def native_match_cps_provider_1_reach_arms_2(+v_3: List<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  match v_3:
    case []:
      False{}
    case +v_17 <> v_18:
      native_match_cps_provider_1_reach_arms_1(v_17, v_1, v_6, v_8, v_11, v_13, v_18)

def cps_provider_1_reach_arms(+v_1: cps_provider_1_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat) -> Bool:
  native_match_cps_provider_1_reach_arms_2(v_3, v_1, v_6, v_8, v_11, v_13)

def native_match_cps_provider_1_args_reach_0(v_17: Bool, +v_1: cps_provider_1_Context, +v_6: String, +v_9: List<&2, String>, +v_11: Nat, v_16: List<&2, cps_provider_2_NfVal>) -> Bool:
  match v_17:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_args_reach(v_1, v_16, v_6, v_9, v_11)

def native_match_cps_provider_1_args_reach_1(+v_4: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_1_Context, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> Bool:
  match v_4:
    case []:
      False{}
    case +v_15 <> v_16:
      native_match_cps_provider_1_args_reach_0(cps_provider_1_reaches_val(v_1, v_15, v_6, v_9, v_11), v_1, v_6, v_9, v_11, v_16)

def cps_provider_1_args_reach(+v_1: cps_provider_1_Context, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat) -> Bool:
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

def native_match_cps_provider_1_head_native_0(v_9: cps_provider_2_Nf, +v_1: cps_provider_1_Context) -> cps_provider_1_HeadResult:
  match v_9:
    case cps_provider_2_NfFail{+v_6}:
      cps_provider_1_HeadFailed{v_6}
    case cps_provider_2_NfOk{+v_8}:
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

def native_match_cps_provider_1_head_value_1(+v_11: BIR.Family, +v_7: String, +v_8: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_HeadResult:
  match v_11:
    case BIR.Family{+v_18, +v_19, +v_20, +v_21, +v_22, +v_23}:
      native_match_cps_provider_1_head_value_0(Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_8), v_22), v_7, v_20)

def native_match_cps_provider_1_head_value_2(v_49: Bool, +v_7: String, +v_34: Maybe<&2, String>) -> cps_provider_1_HeadResult:
  match v_49:
    case True{}:
      cps_provider_1_HeadFound{v_7, v_34}
    case False{}:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def native_match_cps_provider_1_head_value_3(+v_34: Maybe<&2, String>, +v_7: String, +v_8: List<&2, cps_provider_2_NfVal>, +v_36: Nat) -> cps_provider_1_HeadResult:
  match v_34:
    case Some{+v_39}:
      native_match_cps_provider_1_head_value_2(Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_8), v_36), v_7, v_34)
    case None{}:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def native_match_cps_provider_1_head_value_4(+v_27: BIR.TypeFunction, +v_7: String, +v_8: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_HeadResult:
  match v_27:
    case BIR.TypeFunction{+v_33, +v_34, +v_35, +v_36, +v_37}:
      native_match_cps_provider_1_head_value_3(v_34, v_7, v_8, v_36)

def native_match_cps_provider_1_head_value_5(v_48: Maybe<&2, BIR.TypeFunction>, +v_7: String, +v_8: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_HeadResult:
  match v_48:
    case Some{+v_27}:
      native_match_cps_provider_1_head_value_4(v_27, v_7, v_8)
    case None{}:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxUnresolved{v_7}}

def native_match_cps_provider_1_head_value_6(v_46: Maybe<&2, BIR.Family>, +v_1: cps_provider_1_Context, +v_7: String, +v_8: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_HeadResult:
  match v_46:
    case Some{+v_11}:
      native_match_cps_provider_1_head_value_1(v_11, v_7, v_8)
    case None{}:
      native_match_cps_provider_1_head_value_5(cps_provider_1_function_lookup(v_1, v_7), v_7, v_8)

def native_match_cps_provider_1_head_value_7(+v_3: cps_provider_2_NfVal, +v_1: cps_provider_1_Context) -> cps_provider_1_HeadResult:
  match v_3:
    case cps_provider_2_NfType{+v_7, +v_8}:
      native_match_cps_provider_1_head_value_6(cps_provider_1_family_lookup(v_1, v_7), v_1, v_7, v_8)
    case cps_provider_2_NfOther{+v_42}:
      cps_provider_1_head_other(v_42)
    case _:
      cps_provider_1_HeadBoxed{cps_provider_1_BoxOpen{}}

def cps_provider_1_head_value(+v_1: cps_provider_1_Context, +v_3: cps_provider_2_NfVal) -> cps_provider_1_HeadResult:
  native_match_cps_provider_1_head_value_7(v_3, v_1)

def native_match_cps_provider_1_norm_0(+v_10: BIR.Descriptor) -> cps_provider_1_NormResult:
  match v_10:
    case BIR.DescriptorFailure{+v_7}:
      cps_provider_1_NormFailed{v_7}
    case +v_9:
      cps_provider_1_NormOk{v_9}

def cps_provider_1_norm(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_NormResult:
  native_match_cps_provider_1_norm_0(cps_provider_2_normalize(cps_provider_1_context_nf(v_1), v_2, [], 1024n))

def native_match_cps_provider_1_head_args_0(+v_8: cps_provider_2_NfVal) -> cps_provider_1_ArgsResult:
  match v_8:
    case cps_provider_2_NfType{+v_11, +v_12}:
      cps_provider_1_ArgsOk{cps_provider_2_materialize_all(v_12)}
    case _:
      cps_provider_1_ArgsFailed{"the applied type is not a named family application"}

def native_match_cps_provider_1_head_args_1(v_16: cps_provider_2_Nf) -> cps_provider_1_ArgsResult:
  match v_16:
    case cps_provider_2_NfFail{+v_6}:
      cps_provider_1_ArgsFailed{v_6}
    case cps_provider_2_NfOk{+v_8}:
      native_match_cps_provider_1_head_args_0(v_8)

def cps_provider_1_head_args(+v_1: cps_provider_1_Context, +v_2: BIR.Descriptor) -> cps_provider_1_ArgsResult:
  native_match_cps_provider_1_head_args_1(cps_provider_1_nf_of(v_1, v_2, [], 1024n))

def native_match_cps_provider_1_arm_fields_0(v_11: cps_provider_2_Nf, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_FieldsResult:
  match v_11:
    case cps_provider_2_NfFail{+v_8}:
      cps_provider_1_FieldsFailed{v_8}
    case cps_provider_2_NfOk{+v_10}:
      cps_provider_1_arm_fields_value(v_1, v_3, v_10)

def cps_provider_1_arm_fields(+v_1: cps_provider_1_Context, +v_3: String, +v_4: BIR.Descriptor) -> cps_provider_1_FieldsResult:
  native_match_cps_provider_1_arm_fields_0(cps_provider_1_nf_of(v_1, v_4, [], 1024n), v_1, v_3)

def native_match_cps_provider_1_arm_fields_value_0(+v_14: BIR.DescriptorArm, +v_1: cps_provider_1_Context, +v_10: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_FieldsResult:
  match v_14:
    case BIR.DescriptorArm{+v_17, +v_18}:
      cps_provider_1_instantiate_fields(v_1, v_10, v_18, [])

def native_match_cps_provider_1_arm_fields_value_1(v_22: Maybe<&2, BIR.DescriptorArm>, +v_1: cps_provider_1_Context, +v_3: String, +v_10: List<&2, cps_provider_2_NfVal>) -> cps_provider_1_FieldsResult:
  match v_22:
    case None{}:
      cps_provider_1_FieldsFailed{cps_provider_1_unresolved_message(v_3)}
    case Some{+v_14}:
      native_match_cps_provider_1_arm_fields_value_0(v_14, v_1, v_10)

def native_match_cps_provider_1_arm_fields_value_2(+v_5: cps_provider_2_NfVal, +v_1: cps_provider_1_Context, +v_3: String) -> cps_provider_1_FieldsResult:
  match v_5:
    case cps_provider_2_NfType{+v_9, +v_10}:
      native_match_cps_provider_1_arm_fields_value_1(cps_provider_1_arm_declared(v_1, v_3), v_1, v_3, v_10)
    case _:
      cps_provider_1_FieldsFailed{"the applied type is not a named family application"}

def cps_provider_1_arm_fields_value(+v_1: cps_provider_1_Context, +v_3: String, +v_5: cps_provider_2_NfVal) -> cps_provider_1_FieldsResult:
  native_match_cps_provider_1_arm_fields_value_2(v_5, v_1, v_3)

def cps_provider_1_instantiate_fields(+v_1: cps_provider_1_Context, +v_3: List<&2, cps_provider_2_NfVal>, +v_5: List<&2, BIR.DescriptorField>, +v_7: List<&2, BIR.DescriptorField>) -> cps_provider_1_FieldsResult:
  match v_5:
    case []:
      cps_provider_1_FieldsFound{List.reverse(&2, BIR.DescriptorField, v_7)}
    case +v_11 <> v_12:
      match v_11:
        case BIR.DescriptorField{+v_16, +v_17, +v_18}:
          +v_21 = cps_provider_1_field_scope(v_3)
          +v_24 = {BIR.DescriptorField{v_16, v_17, cps_provider_2_normalize(cps_provider_1_context_nf(v_1), v_18, v_3, 1024n)} : BIR.DescriptorField}
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

def cps_provider_2_family_index(v_1: List<&2, BIR.Family>) -> Map<&2, BIR.Family>:
  match v_1:
    case []:
      Map.new(&2, BIR.Family)
    case +v_5 <> v_6:
      match v_5:
        case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
          Map.set(&2, BIR.Family, cps_provider_2_family_index(v_6), v_13, v_5)

def cps_provider_2_function_index(v_1: List<&2, BIR.TypeFunction>) -> Map<&2, BIR.TypeFunction>:
  match v_1:
    case []:
      Map.new(&2, BIR.TypeFunction)
    case +v_5 <> v_6:
      match v_5:
        case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
          Map.set(&2, BIR.TypeFunction, cps_provider_2_function_index(v_6), v_12, v_5)

def cps_provider_2_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> cps_provider_2_NfContext:
  cps_provider_2_NfContext{cps_provider_2_family_index(v_1), cps_provider_2_function_index(v_3)}

def cps_provider_2_default_fuel() -> Nat:
  1024n

def cps_provider_2_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  IndexLookup.find(BIR.Family, v_3, v_1)

def cps_provider_2_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  IndexLookup.find(BIR.TypeFunction, v_3, v_1)

def native_match_cps_provider_2_native_of_0(v_10: BIR.Family) -> Maybe<&2, String>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      v_19

def native_match_cps_provider_2_native_of_1(v_25: BIR.TypeFunction) -> Maybe<&2, String>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      v_32

def native_match_cps_provider_2_native_of_2(v_37: Maybe<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_37:
    case Some{v_25}:
      native_match_cps_provider_2_native_of_1(v_25)
    case None{}:
      None{}

def native_match_cps_provider_2_native_of_3(v_36: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_36:
    case Some{v_10}:
      native_match_cps_provider_2_native_of_0(v_10)
    case None{}:
      native_match_cps_provider_2_native_of_2(cps_provider_2_function_of(v_1, v_5))

def cps_provider_2_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  native_match_cps_provider_2_native_of_3(cps_provider_2_family_of(v_1, v_3), v_1, v_5)

def cps_provider_2_val_nth(+v_2: List<&2, cps_provider_2_NfVal>, v_4: Nat) -> cps_provider_2_NfVal:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      v_8
    case +v_13 <> v_14, 1n+v_15:
      cps_provider_2_val_nth(v_14, v_15)
    case _, _:
      cps_provider_2_NfMissing{BIR.DescriptorNull{}}

def cps_provider_2_val_at(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> cps_provider_2_NfVal:
  cps_provider_2_val_at_choose(Nat.is_lt(v_4, List.length(&2, cps_provider_2_NfVal, v_2)), v_2, v_4, v_5)

def cps_provider_2_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> cps_provider_2_NfVal:
  match v_1:
    case True{}:
      cps_provider_2_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_2_NfVal, v_4), 1n), v_6))
    case False{}:
      cps_provider_2_NfMissing{v_7}

def cps_provider_2_first_vals(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> List<&2, cps_provider_2_NfVal>:
  match v_2, v_4:
    case _, 0n:
      []
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      v_14 <> cps_provider_2_first_vals(v_15, v_16)

def cps_provider_2_drop_vals(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> List<&2, cps_provider_2_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_2
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      cps_provider_2_drop_vals(v_15, v_16)

def cps_provider_2_insert_before(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_6: cps_provider_2_NfVal) -> List<&2, cps_provider_2_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_6 <> v_2
    case [], 1n+v_12:
      cps_provider_2_insert_before([], v_12, v_6)
    case +v_17 <> v_18, 1n+v_19:
      v_17 <> cps_provider_2_insert_before(v_18, v_19, v_6)

def cps_provider_2_append_vals(v_2: List<&2, cps_provider_2_NfVal>, v_5: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      v_10 <> cps_provider_2_append_vals(v_11, v_5)

def cps_provider_2_quantity_markers(v_1: Nat) -> List<&2, cps_provider_2_NfVal>:
  match v_1:
    case 0n:
      []
    case 1n+v_5:
      cps_provider_2_NfQuantity{BIR.Erased{}} <> cps_provider_2_quantity_markers(v_5)

def native_match_cps_provider_2_renamed_level_0(v_13: Bool, +v_4: Nat, v_10: Nat, v_11: List<&2, cps_provider_2_NfRenaming>) -> Nat:
  match v_13:
    case True{}:
      v_10
    case False{}:
      cps_provider_2_renamed_level(v_11, v_4)

def native_match_cps_provider_2_renamed_level_1(v_2: List<&2, cps_provider_2_NfRenaming>, +v_4: Nat) -> Nat:
  match v_2:
    case []:
      v_4
    case cps_provider_2_NfRenaming{v_9, v_10} <> v_11:
      native_match_cps_provider_2_renamed_level_0(Nat.is_eq(v_9, v_4), v_4, v_10, v_11)

def cps_provider_2_renamed_level(v_2: List<&2, cps_provider_2_NfRenaming>, +v_4: Nat) -> Nat:
  native_match_cps_provider_2_renamed_level_1(v_2, v_4)

def cps_provider_2_materialize_all_scoped(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_2_NfRenaming>) -> List<&2, BIR.Descriptor>:
  match v_2:
    case []:
      []
    case +v_11 <> v_12:
      cps_provider_2_materialize_scoped(v_11, v_4, v_7) <> cps_provider_2_materialize_all_scoped(v_12, v_4, v_7)

def cps_provider_2_materialize_all_at(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> List<&2, BIR.Descriptor>:
  cps_provider_2_materialize_all_scoped(v_2, v_4, [])

def cps_provider_2_materialize_all(v_2: List<&2, cps_provider_2_NfVal>) -> List<&2, BIR.Descriptor>:
  cps_provider_2_materialize_all_at(v_2, 0n)

def cps_provider_2_materialize_scoped(v_1: cps_provider_2_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_2_NfRenaming>) -> BIR.Descriptor:
  match v_1:
    case cps_provider_2_NfType{v_9, v_10}:
      BIR.DescriptorRef{v_9, cps_provider_2_materialize_all_scoped(v_10, v_3, v_6)}
    case cps_provider_2_NfCtor{v_14, v_15}:
      BIR.DescriptorConstructor{v_14, cps_provider_2_materialize_all_scoped(v_15, v_3, v_6)}
    case cps_provider_2_NfQuantity{v_18}:
      BIR.DescriptorQuantity{v_18}
    case cps_provider_2_NfKind{v_20}:
      BIR.DescriptorKind{cps_provider_2_materialize_scoped(v_20, v_3, v_6)}
    case cps_provider_2_NfOther{v_23}:
      v_23
    case cps_provider_2_NfMissing{v_25}:
      v_25
    case cps_provider_2_NfBinder{v_27}:
      BIR.DescriptorParameter{Nat.sub(v_3, Nat.add(cps_provider_2_renamed_level(v_6, v_27), 1n))}
    case cps_provider_2_NfArrow{v_33, v_34, v_35, v_36}:
      BIR.DescriptorArrow{v_33, cps_provider_2_materialize_scoped(v_34, v_3, v_6), cps_provider_2_materialize_scoped(v_35, Nat.add(v_3, 1n), cps_provider_2_NfRenaming{v_36, v_3} <> v_6)}
    case cps_provider_2_NfClosure{v_42, v_43, v_44}:
      BIR.DescriptorLet{cps_provider_2_materialize_all_scoped(v_44, v_3, v_6), BIR.DescriptorLambda{v_42, v_43}}

def cps_provider_2_materialize_at(v_1: cps_provider_2_NfVal, +v_3: Nat) -> BIR.Descriptor:
  cps_provider_2_materialize_scoped(v_1, v_3, [])

def cps_provider_2_materialize(v_1: cps_provider_2_NfVal) -> BIR.Descriptor:
  cps_provider_2_materialize_at(v_1, 0n)

def cps_provider_2_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_2_NfVal>, +v_5: Nat) -> BIR.Descriptor:
  match v_3:
    case []:
      v_0
    case +v_8 <> v_9:
      BIR.DescriptorLet{cps_provider_2_materialize_all_at(v_3, v_5), v_0}

def cps_provider_2_status_combine(v_1: cps_provider_2_NfStatus, v_3: cps_provider_2_NfStatus) -> cps_provider_2_NfStatus:
  match v_1:
    case cps_provider_2_NfStatusNo{}:
      cps_provider_2_NfStatusNo{}
    case cps_provider_2_NfStatusMaybe{}:
      match v_3:
        case cps_provider_2_NfStatusNo{}:
          cps_provider_2_NfStatusNo{}
        case _:
          cps_provider_2_NfStatusMaybe{}
    case cps_provider_2_NfStatusOk{}:
      v_3

def native_match_cps_provider_2_bind_status_0(v_56: Bool, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_2_NfVal>, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  match v_56:
    case False{}:
      cps_provider_2_NfStatusNo{}
    case True{}:
      cps_provider_2_status_combine(cps_provider_2_bind_status(v_20, v_24), cps_provider_2_bind_status(v_11, v_13))

def native_match_cps_provider_2_bind_status_1(+v_12: cps_provider_2_NfVal, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_2_NfVal>, v_19: String, v_20: List<&2, BIR.DescriptorPattern>) -> cps_provider_2_NfStatus:
  match v_12:
    case cps_provider_2_NfCtor{v_23, v_24}:
      native_match_cps_provider_2_bind_status_0(String.eq(v_19, v_23), v_11, v_13, v_20, v_24)
    case cps_provider_2_NfMissing{v_29}:
      cps_provider_2_status_combine(cps_provider_2_NfStatusMaybe{}, cps_provider_2_bind_status(v_11, v_13))
    case cps_provider_2_NfOther{v_33}:
      cps_provider_2_status_combine(cps_provider_2_NfStatusMaybe{}, cps_provider_2_bind_status(v_11, v_13))
    case cps_provider_2_NfBinder{v_37}:
      cps_provider_2_status_combine(cps_provider_2_NfStatusMaybe{}, cps_provider_2_bind_status(v_11, v_13))
    case cps_provider_2_NfArrow{v_44, v_45, v_46, v_47}:
      cps_provider_2_status_combine(cps_provider_2_NfStatusMaybe{}, cps_provider_2_bind_status(v_11, v_13))
    case _:
      cps_provider_2_NfStatusNo{}

def native_match_cps_provider_2_bind_status_2(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, +v_12: cps_provider_2_NfVal, v_13: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      cps_provider_2_bind_status(v_11, v_13)
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      native_match_cps_provider_2_bind_status_1(v_12, v_11, v_13, v_19, v_20)

def native_match_cps_provider_2_bind_status_3(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  match v_1, v_4:
    case [], []:
      cps_provider_2_NfStatusOk{}
    case +v_10 <> v_11, +v_12 <> v_13:
      native_match_cps_provider_2_bind_status_2(v_10, v_11, v_12, v_13)
    case _, _:
      cps_provider_2_NfStatusNo{}

def cps_provider_2_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  native_match_cps_provider_2_bind_status_3(v_1, v_4)

def native_match_cps_provider_2_bind_values_0(+v_13: cps_provider_2_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_2_NfVal>, v_21: List<&2, BIR.DescriptorPattern>) -> List<&2, cps_provider_2_NfVal>:
  match v_13:
    case cps_provider_2_NfCtor{v_24, v_25}:
      cps_provider_2_append_vals(cps_provider_2_bind_values(v_21, v_25), cps_provider_2_bind_values(v_12, v_14))
    case _:
      cps_provider_2_bind_values(v_12, v_14)

def native_match_cps_provider_2_bind_values_1(+v_11: BIR.DescriptorPattern, v_12: List<&2, BIR.DescriptorPattern>, +v_13: cps_provider_2_NfVal, v_14: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      v_13 <> cps_provider_2_bind_values(v_12, v_14)
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      native_match_cps_provider_2_bind_values_0(v_13, v_12, v_14, v_21)

def native_match_cps_provider_2_bind_values_2(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  match v_1, v_4:
    case [], []:
      []
    case +v_11 <> v_12, +v_13 <> v_14:
      native_match_cps_provider_2_bind_values_1(v_11, v_12, v_13, v_14)
    case _, _:
      []

def cps_provider_2_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  native_match_cps_provider_2_bind_values_2(v_1, v_4)

def native_match_cps_provider_2_bind_patterns_0(v_5: cps_provider_2_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfBind:
  match v_5:
    case cps_provider_2_NfStatusOk{}:
      cps_provider_2_NfBound{cps_provider_2_bind_values(v_1, v_4)}
    case cps_provider_2_NfStatusNo{}:
      cps_provider_2_NfMismatch{}
    case cps_provider_2_NfStatusMaybe{}:
      cps_provider_2_NfUnknown{}

def cps_provider_2_bind_patterns(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfBind:
  native_match_cps_provider_2_bind_patterns_0(cps_provider_2_bind_status(v_1, v_4), v_1, v_4)

def native_match_cps_provider_2_nf_0(v_10: Bool, +v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  match v_10:
    case True{}:
      cps_provider_2_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_2_nf_descriptor(v_1, v_2, v_5, v_7, Nat.sub(v_9, 1n))

def cps_provider_2_nf(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_cps_provider_2_nf_descriptor_0(v_10: Bool, +v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  match v_10:
    case True{}:
      cps_provider_2_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_2_nf_descriptor_step(v_1, v_2, v_5, v_7, v_9)

def cps_provider_2_nf_descriptor(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_descriptor_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_cps_provider_2_nf_arrow_0(v_25: cps_provider_2_Nf, v_2: BIR.Quantity, +v_9: Nat, v_17: cps_provider_2_NfVal) -> cps_provider_2_Nf:
  match v_25:
    case cps_provider_2_NfFail{v_21}:
      cps_provider_2_NfFail{v_21}
    case cps_provider_2_NfOk{v_23}:
      cps_provider_2_NfOk{cps_provider_2_NfArrow{v_2, v_17, v_23, v_9}}

def native_match_cps_provider_2_nf_arrow_1(v_24: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_2: BIR.Quantity, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_2_Nf:
  match v_24:
    case cps_provider_2_NfFail{v_15}:
      cps_provider_2_NfFail{v_15}
    case cps_provider_2_NfOk{v_17}:
      native_match_cps_provider_2_nf_arrow_0(cps_provider_2_nf(v_1, v_4, List.append(&2, cps_provider_2_NfVal, v_7, [cps_provider_2_NfBinder{v_9}]), Nat.add(v_9, 1n), v_11), v_2, v_9, v_17)

def cps_provider_2_nf_arrow(+v_1: cps_provider_2_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_arrow_1(cps_provider_2_nf(v_1, v_3, v_7, v_9, v_11), v_1, v_2, v_4, v_7, v_9, v_11)

def native_match_cps_provider_2_nf_descriptor_step_0(v_191: cps_provider_2_Nf) -> cps_provider_2_Nf:
  match v_191:
    case cps_provider_2_NfOk{v_24}:
      cps_provider_2_NfOk{cps_provider_2_NfKind{v_24}}
    case cps_provider_2_NfFail{v_26}:
      cps_provider_2_NfFail{v_26}

def native_match_cps_provider_2_nf_descriptor_step_1(v_192: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_7: Nat, +v_9: Nat, v_45: String) -> cps_provider_2_Nf:
  match v_192:
    case cps_provider_2_NfListOk{v_49}:
      cps_provider_2_nf_named(v_1, v_45, v_49, v_7, v_9)
    case cps_provider_2_NfListFail{v_52}:
      cps_provider_2_NfFail{v_52}

def native_match_cps_provider_2_nf_descriptor_step_2(v_193: cps_provider_2_NfList, v_55: String) -> cps_provider_2_Nf:
  match v_193:
    case cps_provider_2_NfListOk{v_59}:
      cps_provider_2_NfOk{cps_provider_2_NfCtor{v_55, v_59}}
    case cps_provider_2_NfListFail{v_61}:
      cps_provider_2_NfFail{v_61}

def native_match_cps_provider_2_nf_descriptor_step_3(v_195: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_7: Nat, +v_9: Nat, v_68: cps_provider_2_NfVal) -> cps_provider_2_Nf:
  match v_195:
    case cps_provider_2_NfOk{v_71}:
      cps_provider_2_nf_apply(v_1, v_68, [v_71], v_7, v_9)
    case cps_provider_2_NfFail{v_74}:
      cps_provider_2_NfFail{v_74}

def native_match_cps_provider_2_nf_descriptor_step_4(v_194: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, v_65: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_194:
    case cps_provider_2_NfOk{v_68}:
      native_match_cps_provider_2_nf_descriptor_step_3(cps_provider_2_nf(v_1, v_65, v_5, v_7, v_9), v_1, v_7, v_9, v_68)
    case cps_provider_2_NfFail{v_76}:
      cps_provider_2_NfFail{v_76}

def native_match_cps_provider_2_nf_descriptor_step_5(v_196: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, v_80: Nat, v_82: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_196:
    case cps_provider_2_NfOk{v_85}:
      cps_provider_2_nf_descriptor(v_1, v_82, cps_provider_2_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_2_NfVal, v_5), v_80), v_85), v_7, Nat.sub(v_9, 1n))
    case cps_provider_2_NfFail{v_90}:
      cps_provider_2_NfFail{v_90}

def native_match_cps_provider_2_nf_descriptor_step_6(v_197: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, v_94: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_197:
    case cps_provider_2_NfListOk{v_97}:
      cps_provider_2_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_2_NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n))
    case cps_provider_2_NfListFail{v_101}:
      cps_provider_2_NfFail{v_101}

def native_match_cps_provider_2_nf_descriptor_step_7(v_199: cps_provider_2_NfBind, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_107: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_199:
    case cps_provider_2_NfBound{v_113}:
      cps_provider_2_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_2_NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n))
    case _:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_12, v_5, v_7)}}

def native_match_cps_provider_2_nf_descriptor_step_8(v_198: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_105: List<&2, BIR.DescriptorPattern>, v_107: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_198:
    case cps_provider_2_NfListOk{v_110}:
      native_match_cps_provider_2_nf_descriptor_step_7(cps_provider_2_bind_patterns(v_105, v_110), v_1, v_5, v_7, v_9, v_12, v_107)
    case cps_provider_2_NfListFail{v_120}:
      cps_provider_2_NfFail{v_120}

def native_match_cps_provider_2_nf_descriptor_step_9(v_200: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_124: List<&2, BIR.Descriptor>) -> cps_provider_2_Nf:
  match v_200:
    case cps_provider_2_NfListOk{v_127}:
      cps_provider_2_nf_cases(v_1, v_124, v_127, v_5, v_12, v_7, v_9)
    case cps_provider_2_NfListFail{v_130}:
      cps_provider_2_NfFail{v_130}

def native_match_cps_provider_2_nf_descriptor_step_10(v_201: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat, v_139: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_201:
    case cps_provider_2_NfOk{v_142}:
      cps_provider_2_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_2_NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_2_NfFail{v_146}:
      cps_provider_2_NfFail{v_146}

def native_match_cps_provider_2_nf_descriptor_step_11(v_202: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_7: Nat, +v_9: Nat, v_170: String) -> cps_provider_2_Nf:
  match v_202:
    case cps_provider_2_NfListOk{v_175}:
      cps_provider_2_nf_named(v_1, v_170, v_175, v_7, v_9)
    case cps_provider_2_NfListFail{v_178}:
      cps_provider_2_NfFail{v_178}

def native_match_cps_provider_2_nf_descriptor_step_12(v_203: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_7: Nat, +v_9: Nat, v_182: String) -> cps_provider_2_Nf:
  match v_203:
    case cps_provider_2_NfListOk{v_187}:
      cps_provider_2_nf_named(v_1, v_182, v_187, v_7, v_9)
    case cps_provider_2_NfListFail{v_190}:
      cps_provider_2_NfFail{v_190}

def native_match_cps_provider_2_nf_descriptor_step_13(+v_12: BIR.Descriptor, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  match v_12:
    case BIR.DescriptorNull{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorParameter{v_15}:
      cps_provider_2_NfOk{cps_provider_2_val_at(v_5, v_15, v_12)}
    case BIR.DescriptorQuantityKind{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorQuantity{v_19}:
      cps_provider_2_NfOk{cps_provider_2_NfQuantity{v_19}}
    case BIR.DescriptorKind{v_21}:
      native_match_cps_provider_2_nf_descriptor_step_0(cps_provider_2_nf(v_1, v_21, v_5, v_7, v_9))
    case BIR.DescriptorMinimum{v_29, v_30}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorArrow{v_35, v_36, v_37}:
      cps_provider_2_nf_arrow(v_1, v_35, v_36, v_37, v_5, v_7, v_9)
    case BIR.DescriptorLambda{v_41, v_42}:
      cps_provider_2_NfOk{cps_provider_2_NfClosure{v_41, v_42, v_5}}
    case BIR.DescriptorRef{v_45, v_46}:
      native_match_cps_provider_2_nf_descriptor_step_1(cps_provider_2_nf_all(v_1, v_46, v_5, v_7, v_9), v_1, v_7, v_9, v_45)
    case BIR.DescriptorConstructor{v_55, v_56}:
      native_match_cps_provider_2_nf_descriptor_step_2(cps_provider_2_nf_all(v_1, v_56, v_5, v_7, v_9), v_55)
    case BIR.DescriptorApplication{v_64, v_65}:
      native_match_cps_provider_2_nf_descriptor_step_4(cps_provider_2_nf(v_1, v_64, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_65)
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      native_match_cps_provider_2_nf_descriptor_step_5(cps_provider_2_nf(v_1, v_81, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_80, v_82)
    case BIR.DescriptorLet{v_93, v_94}:
      native_match_cps_provider_2_nf_descriptor_step_6(cps_provider_2_nf_all(v_1, v_93, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_94)
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      native_match_cps_provider_2_nf_descriptor_step_8(cps_provider_2_nf_all(v_1, v_106, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_105, v_107)
    case BIR.DescriptorMatch{v_123, v_124}:
      native_match_cps_provider_2_nf_descriptor_step_9(cps_provider_2_nf_all(v_1, v_123, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_124)
    case BIR.DescriptorCase{v_133, v_134}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorBind{v_138, v_139}:
      native_match_cps_provider_2_nf_descriptor_step_10(cps_provider_2_nf(v_1, v_138, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_139)
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorReflexivity{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorFailure{v_156}:
      cps_provider_2_NfFail{v_156}
    case BIR.DescriptorFill{v_159, v_160}:
      cps_provider_2_nf_apply_args(v_1, v_159, v_160, v_5, v_12, v_7, v_9)
    case BIR.DescriptorPlus{v_164, v_165}:
      cps_provider_2_nf_apply_args(v_1, v_164, v_165, v_5, v_12, v_7, v_9)
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      native_match_cps_provider_2_nf_descriptor_step_11(cps_provider_2_nf_all(v_1, v_172, v_5, v_7, v_9), v_1, v_7, v_9, v_170)
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      native_match_cps_provider_2_nf_descriptor_step_12(cps_provider_2_nf_all(v_1, v_184, v_5, v_7, v_9), v_1, v_7, v_9, v_182)

def cps_provider_2_nf_descriptor_step(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  +v_12 = v_2
  native_match_cps_provider_2_nf_descriptor_step_13(v_12, v_1, v_5, v_7, v_9)

def native_match_cps_provider_2_nf_all_0(v_27: cps_provider_2_NfList, v_20: cps_provider_2_NfVal) -> cps_provider_2_NfList:
  match v_27:
    case cps_provider_2_NfListFail{v_23}:
      cps_provider_2_NfListFail{v_23}
    case cps_provider_2_NfListOk{v_25}:
      cps_provider_2_NfListOk{v_20 <> v_25}

def native_match_cps_provider_2_nf_all_1(v_26: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat, v_15: List<&2, BIR.Descriptor>) -> cps_provider_2_NfList:
  match v_26:
    case cps_provider_2_NfFail{v_18}:
      cps_provider_2_NfListFail{v_18}
    case cps_provider_2_NfOk{v_20}:
      native_match_cps_provider_2_nf_all_0(cps_provider_2_nf_all(v_1, v_15, v_6, v_8, v_10), v_20)

def native_match_cps_provider_2_nf_all_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_2_NfList:
  match v_3:
    case []:
      cps_provider_2_NfListOk{[]}
    case +v_14 <> v_15:
      native_match_cps_provider_2_nf_all_1(cps_provider_2_nf(v_1, v_14, v_6, v_8, v_10), v_1, v_6, v_8, v_10, v_15)

def cps_provider_2_nf_all(+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_2_NfList:
  native_match_cps_provider_2_nf_all_2(v_3, v_1, v_6, v_8, v_10)

def native_match_cps_provider_2_nf_apply_args_0(v_25: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat, v_18: cps_provider_2_NfVal) -> cps_provider_2_Nf:
  match v_25:
    case cps_provider_2_NfListFail{v_21}:
      cps_provider_2_NfFail{v_21}
    case cps_provider_2_NfListOk{v_23}:
      cps_provider_2_nf_apply_source(v_1, v_18, v_23, v_8, v_10, v_12)

def native_match_cps_provider_2_nf_apply_args_1(v_24: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_2_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> cps_provider_2_Nf:
  match v_24:
    case cps_provider_2_NfFail{v_16}:
      cps_provider_2_NfFail{v_16}
    case cps_provider_2_NfOk{v_18}:
      native_match_cps_provider_2_nf_apply_args_0(cps_provider_2_nf_all(v_1, v_4, v_7, v_10, v_12), v_1, v_8, v_10, v_12, v_18)

def cps_provider_2_nf_apply_args(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_2_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_apply_args_1(cps_provider_2_nf(v_1, v_2, v_7, v_10, v_12), v_1, v_4, v_7, v_8, v_10, v_12)

def cps_provider_2_nf_apply_source(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_6: List<&2, cps_provider_2_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat) -> cps_provider_2_Nf:
  match v_6:
    case []:
      cps_provider_2_NfOk{v_3}
    case _:
      cps_provider_2_nf_apply(v_1, v_3, v_6, v_9, v_11)

def native_match_cps_provider_2_nf_apply_0(v_21: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_8: Nat, +v_10: Nat, v_15: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_21:
    case cps_provider_2_NfFail{v_18}:
      cps_provider_2_NfFail{v_18}
    case cps_provider_2_NfOk{v_20}:
      cps_provider_2_nf_apply(v_1, v_20, v_15, v_8, Nat.sub(v_10, 1n))

def native_match_cps_provider_2_nf_apply_1(v_6: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, +v_8: Nat, +v_10: Nat) -> cps_provider_2_Nf:
  match v_6:
    case []:
      cps_provider_2_NfOk{v_3}
    case +v_14 <> v_15:
      native_match_cps_provider_2_nf_apply_0(cps_provider_2_nf_apply_one(v_1, v_3, v_14, v_8, Nat.sub(v_10, 1n)), v_1, v_8, v_10, v_15)

def cps_provider_2_nf_apply(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_apply_1(v_6, v_1, v_3, v_8, v_10)

def cps_provider_2_nf_apply_one(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_5: cps_provider_2_NfVal, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  match v_3:
    case cps_provider_2_NfType{v_13, v_14}:
      cps_provider_2_nf_named(v_1, v_13, List.append(&2, cps_provider_2_NfVal, v_14, [v_5]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_2_NfClosure{v_20, v_21, v_22}:
      cps_provider_2_nf_descriptor(v_1, v_21, List.append(&2, cps_provider_2_NfVal, v_22, [v_5]), v_7, Nat.sub(v_9, 1n))
    case cps_provider_2_NfCtor{v_27, v_28}:
      cps_provider_2_NfFail{String.append("the constructor `", String.append(v_27, "` is applied to an argument"))}
    case cps_provider_2_NfQuantity{v_30}:
      cps_provider_2_NfFail{"a quantity is applied to an argument"}
    case cps_provider_2_NfKind{v_32}:
      cps_provider_2_NfFail{"a kind is applied to an argument"}
    case cps_provider_2_NfOther{v_34}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{BIR.DescriptorApplication{v_34, cps_provider_2_materialize_at(v_5, v_7)}}}
    case cps_provider_2_NfArrow{v_40, v_41, v_42, v_43}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{BIR.DescriptorApplication{cps_provider_2_materialize_at(v_3, v_7), cps_provider_2_materialize_at(v_5, v_7)}}}
    case cps_provider_2_NfMissing{v_47}:
      cps_provider_2_NfOk{cps_provider_2_NfMissing{BIR.DescriptorApplication{v_47, cps_provider_2_materialize_at(v_5, v_7)}}}
    case cps_provider_2_NfBinder{v_50}:
      cps_provider_2_NfOk{cps_provider_2_NfMissing{BIR.DescriptorApplication{cps_provider_2_materialize_at(v_3, v_7), cps_provider_2_materialize_at(v_5, v_7)}}}

def cps_provider_2_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      match v_8:
        case Some{"IO"}:
          True{}
        case _:
          False{}

def cps_provider_2_nf_named_io(v_1: Bool, +v_3: cps_provider_2_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat, +v_11: Nat) -> cps_provider_2_Nf:
  match v_1:
    case True{}:
      match v_4:
        case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
          cps_provider_2_NfOk{cps_provider_2_NfType{v_18, v_7}}
    case False{}:
      cps_provider_2_nf_reduce(v_3, v_4, v_7, v_9, Nat.sub(v_11, 1n))

def native_match_cps_provider_2_nf_named_0(v_27: Maybe<&2, BIR.Family>, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_27:
    case Some{v_25}:
      cps_provider_2_nf_family(v_25, v_6)
    case None{}:
      cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_6}}

def native_match_cps_provider_2_nf_named_1(v_26: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat, v_14: Map<&2, BIR.Family>) -> cps_provider_2_Nf:
  match v_26:
    case Some{v_18}:
      +v_20 = v_18
      cps_provider_2_nf_named_io(cps_provider_2_intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10)
    case None{}:
      native_match_cps_provider_2_nf_named_0(cps_provider_2_family_of(v_3, v_14), v_3, v_6)

def native_match_cps_provider_2_nf_named_2(+v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_2_Nf:
  match v_1:
    case cps_provider_2_NfContext{v_14, v_15}:
      native_match_cps_provider_2_nf_named_1(cps_provider_2_function_of(v_3, v_15), v_1, v_3, v_6, v_8, v_10, v_14)

def cps_provider_2_nf_named(+v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, +v_10: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_named_2(v_1, v_3, v_6, v_8, v_10)

def cps_provider_2_nf_arity(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, +v_6: Nat) -> cps_provider_2_NfArity:
  cps_provider_2_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_2_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_2_NfVal, v_2), v_6)}

def native_match_cps_provider_2_nf_family_0(v_0: BIR.Family, +v_6: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      cps_provider_2_nf_family_apply(cps_provider_2_nf_arity(v_6, v_20, v_17), v_13, v_20, v_6)

def cps_provider_2_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  +v_6 = v_3
  native_match_cps_provider_2_nf_family_0(v_0, v_6)

def cps_provider_2_nf_family_apply(v_1: cps_provider_2_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_1:
    case cps_provider_2_NfArity{v_13, v_14, v_15}:
      match v_13:
        case True{}:
          cps_provider_2_NfOk{cps_provider_2_NfType{v_3, List.append(&2, cps_provider_2_NfVal, cps_provider_2_quantity_markers(v_5), v_8)}}
        case False{}:
          match v_14:
            case True{}:
              cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_8}}
            case False{}:
              match v_15:
                case True{}:
                  cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_8}}
                case False{}:
                  cps_provider_2_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}

def native_match_cps_provider_2_nf_reduce_0(v_2: BIR.TypeFunction, +v_1: cps_provider_2_NfContext, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_2:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      +v_24 = v_20
      +v_26 = v_21
      cps_provider_2_nf_reduce_apply(cps_provider_2_nf_arity(v_12, v_24, v_26), v_1, v_18, v_24, v_26, v_22, v_12, v_7, v_9)

def cps_provider_2_nf_reduce(+v_1: cps_provider_2_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_9: Nat) -> cps_provider_2_Nf:
  +v_12 = v_5
  native_match_cps_provider_2_nf_reduce_0(v_2, v_1, v_7, v_9, v_12)

def cps_provider_2_nf_reduce_apply(v_1: cps_provider_2_NfArity, +v_3: cps_provider_2_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_2_NfVal>, +v_15: Nat, +v_17: Nat) -> cps_provider_2_Nf:
  match v_1:
    case cps_provider_2_NfArity{v_22, v_23, v_24}:
      match v_22:
        case True{}:
          cps_provider_2_nf_reduce_body(v_3, v_10, List.append(&2, cps_provider_2_NfVal, cps_provider_2_quantity_markers(v_7), v_13), [], v_15, Nat.sub(v_17, 1n))
        case False{}:
          match v_23:
            case True{}:
              cps_provider_2_nf_reduce_body(v_3, v_10, cps_provider_2_first_vals(v_13, v_9), cps_provider_2_drop_vals(v_13, v_9), v_15, Nat.sub(v_17, 1n))
            case False{}:
              match v_24:
                case True{}:
                  cps_provider_2_NfOk{cps_provider_2_NfType{v_5, v_13}}
                case False{}:
                  cps_provider_2_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}

def native_match_cps_provider_2_nf_reduce_body_0(v_19: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Nat) -> cps_provider_2_Nf:
  match v_19:
    case cps_provider_2_NfFail{v_16}:
      cps_provider_2_NfFail{v_16}
    case cps_provider_2_NfOk{v_18}:
      cps_provider_2_nf_apply(v_1, v_18, v_8, v_10, v_12)

def cps_provider_2_nf_reduce_body(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat, +v_12: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_reduce_body_0(cps_provider_2_nf_descriptor(v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)), v_1, v_8, v_10, v_12)

def native_match_cps_provider_2_nf_cases_0(v_36: cps_provider_2_NfBind, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, v_24: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_36:
    case cps_provider_2_NfBound{v_27}:
      cps_provider_2_nf_descriptor(v_1, v_24, List.append(&2, cps_provider_2_NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n))
    case cps_provider_2_NfMismatch{}:
      cps_provider_2_nf_cases(v_1, v_20, v_6, v_9, v_10, v_12, v_14)
    case cps_provider_2_NfUnknown{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_9, v_12)}}

def native_match_cps_provider_2_nf_cases_1(+v_19: BIR.Descriptor, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>) -> cps_provider_2_Nf:
  match v_19:
    case BIR.DescriptorCase{v_23, v_24}:
      native_match_cps_provider_2_nf_cases_0(cps_provider_2_bind_patterns(v_23, v_6), v_1, v_6, v_9, v_10, v_12, v_14, v_20, v_24)
    case BIR.DescriptorFailure{v_33}:
      cps_provider_2_NfFail{v_33}
    case _:
      cps_provider_2_NfFail{"descriptor match case is not a case"}

def native_match_cps_provider_2_nf_cases_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> cps_provider_2_Nf:
  match v_3:
    case []:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_9, v_12)}}
    case +v_19 <> v_20:
      native_match_cps_provider_2_nf_cases_1(v_19, v_1, v_6, v_9, v_10, v_12, v_14, v_20)

def cps_provider_2_nf_cases(+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_cases_2(v_3, v_1, v_6, v_9, v_10, v_12, v_14)

def native_match_cps_provider_2_normalize_0(v_13: cps_provider_2_Nf) -> BIR.Descriptor:
  match v_13:
    case cps_provider_2_NfFail{v_10}:
      BIR.DescriptorFailure{v_10}
    case cps_provider_2_NfOk{v_12}:
      cps_provider_2_materialize_at(v_12, 0n)

def cps_provider_2_normalize(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> BIR.Descriptor:
  native_match_cps_provider_2_normalize_0(cps_provider_2_nf(v_1, v_2, v_5, 0n, v_7))

def cps_provider_2_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_2_normalize(cps_provider_2_nf_context(v_1, v_3), v_4, [], 1024n)

def cps_provider_2_normalize_in(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_2_normalize(v_1, v_2, [], 1024n)

def cps_provider_2_outer_application(+v_0: BIR.Descriptor) -> Maybe<&2, cps_provider_2_NfApp>:
  cps_provider_2_outer_walk(v_0, [])

def cps_provider_2_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> Maybe<&2, cps_provider_2_NfApp>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      Some{cps_provider_2_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      Some{cps_provider_2_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      Some{cps_provider_2_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}
    case BIR.DescriptorFill{v_23, v_24}:
      cps_provider_2_outer_walk(v_23, List.append(&2, BIR.Descriptor, v_24, v_2))
    case BIR.DescriptorPlus{v_28, v_29}:
      cps_provider_2_outer_walk(v_28, List.append(&2, BIR.Descriptor, v_29, v_2))
    case BIR.DescriptorApplication{v_33, v_34}:
      cps_provider_2_outer_walk(v_33, List.append(&2, BIR.Descriptor, [v_34], v_2))
    case _:
      None{}

def native_match_cps_provider_2_answer_in_0(v_5: BIR.Descriptor, +v_1: cps_provider_2_NfContext) -> BIR.Descriptor:
  match v_5:
    case BIR.DescriptorFailure{_}:
      v_5
    case _:
      cps_provider_2_answer_normalized(v_1, v_5)

def cps_provider_2_answer_in(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  v_5 = cps_provider_2_normalize(v_1, v_2, [], 1024n)
  native_match_cps_provider_2_answer_in_0(v_5, v_1)

def cps_provider_2_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  cps_provider_2_answer_in(cps_provider_2_nf_context(v_2, v_4), v_0)

def native_match_cps_provider_2_answer_normalized_0(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_9:
    case []:
      v_2
    case +v_13 <> v_14:
      v_13

def native_match_cps_provider_2_answer_normalized_1(v_16: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  match v_16:
    case False{}:
      v_2
    case True{}:
      native_match_cps_provider_2_answer_normalized_0(v_9, v_2)

def native_match_cps_provider_2_answer_normalized_2(v_5: cps_provider_2_NfApp, +v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_5:
    case cps_provider_2_NfApp{v_8, v_9}:
      native_match_cps_provider_2_answer_normalized_1(cps_provider_2_is_io_head_in(v_1, v_8), v_2, v_9)

def native_match_cps_provider_2_answer_normalized_3(v_15: Maybe<&2, cps_provider_2_NfApp>, +v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_15:
    case None{}:
      v_2
    case Some{v_5}:
      native_match_cps_provider_2_answer_normalized_2(v_5, v_1, v_2)

def cps_provider_2_answer_normalized(+v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  native_match_cps_provider_2_answer_normalized_3(cps_provider_2_outer_application(v_2), v_1, v_2)

def cps_provider_2_is_io_head_in(+v_1: cps_provider_2_NfContext, +v_3: String) -> Bool:
  match v_1:
    case cps_provider_2_NfContext{v_7, v_8}:
      cps_provider_2_is_io_head(v_3, v_7, v_8)

def native_match_cps_provider_2_is_io_head_0(v_10: Maybe<&2, String>) -> Bool:
  match v_10:
    case Some{v_9}:
      String.eq(v_9, "IO")
    case None{}:
      False{}

def cps_provider_2_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Bool:
  native_match_cps_provider_2_is_io_head_0(cps_provider_2_native_of(v_1, v_3, v_5))

