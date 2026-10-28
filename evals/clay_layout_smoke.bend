import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/c_backend_layout.bend as CLay

# Actual CLay plan smoke: builds BIR facts only, then exercises the admitted
# layout module.  Every check receives an already-computed result as a
# parameter, so no match scrutinizes a computed value.

def fld(+ty: BIR.Descriptor) -> BIR.DescriptorField:
  BIR.DescriptorField{None{}, BIR.Unrestricted{}, ty}

def arm(+key: String, +fields: List<&2, BIR.DescriptorField>) -> BIR.DescriptorArm:
  BIR.DescriptorArm{key, fields}

def fam(+key: String, +native: Maybe<&2, String>, +arity: Nat, +arms: List<&2, BIR.DescriptorArm>) -> BIR.Family:
  BIR.Family{key, key, native, 0n, arity, arms}

def ref(+key: String, +args: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  BIR.DescriptorRef{key, args}

def par(+index: Nat) -> BIR.Descriptor:
  BIR.DescriptorParameter{index}

def fam_nat() -> BIR.Family:
  fam("Nat", Some{"Nat"}, 0n, Nil{})

def fam_u32() -> BIR.Family:
  fam("U32", Some{"U32"}, 0n, Nil{})

def fam_f32() -> BIR.Family:
  fam("F32", Some{"F32"}, 0n, Nil{})

def fam_array() -> BIR.Family:
  fam("Array", Some{"Array"}, 1n, Nil{})

def fam_io() -> BIR.Family:
  fam("IO.OP", Some{"IO.OP"}, 1n, Nil{})

def fam_pt() -> BIR.Family:
  fam("Pt", None{}, 0n, [arm("Pt", [fld(ref("U32", Nil{})), fld(ref("U32", Nil{}))])])

def fam_fl() -> BIR.Family:
  fam("Fl", None{}, 0n, [arm("Fl", [fld(ref("F32", Nil{})), fld(ref("F32", Nil{}))])])

def fam_seg() -> BIR.Family:
  fam("Seg", None{}, 0n, [arm("Seg", [fld(ref("Pt", Nil{})), fld(ref("Pt", Nil{})), fld(ref("Fl", Nil{}))])])

def fam_w32() -> BIR.Family:
  fam("W32", None{}, 0n, [arm("W32", [fld(ref("U32", Nil{}))])])

def fam_onenat() -> BIR.Family:
  fam("OneNat", None{}, 0n, [arm("OneNat", [fld(ref("Nat", Nil{}))])])

def fam_empty() -> BIR.Family:
  fam("Empty0", None{}, 0n, [arm("Empty0", Nil{})])

def fam_box() -> BIR.Family:
  fam("Box", None{}, 1n, [arm("Box", [fld(par(0n))])])

def fam_pair() -> BIR.Family:
  fam("Pair", None{}, 2n, [arm("Pair", [fld(par(1n)), fld(par(0n))])])

def fam_opt() -> BIR.Family:
  fam("Opt", None{}, 0n, [arm("None", Nil{}), arm("Some", [fld(ref("U32", Nil{}))])])

def fam_list() -> BIR.Family:
  fam("ListT", None{}, 0n, [arm("Cons", [fld(ref("U32", Nil{})), fld(ref("ListT", Nil{}))])])

def families() -> List<&2, BIR.Family>:
  [fam_nat(), fam_u32(), fam_f32(), fam_array(), fam_io(), fam_pt(), fam_fl(), fam_seg(),
   fam_w32(), fam_onenat(), fam_empty(), fam_box(), fam_pair(), fam_opt(), fam_list()]

def type_functions() -> List<&2, BIR.TypeFunction>:
  [BIR.TypeFunction{"MyNat", None{}, 0n, 0n, ref("Nat", Nil{})},
   BIR.TypeFunction{"MyIO", None{}, 0n, 0n, ref("IO", [ref("Nat", Nil{})])},
   BIR.TypeFunction{"IO", Some{"IO"}, 0n, 1n, BIR.DescriptorArrow{BIR.Unrestricted{}, ref("IO.OP", Nil{}), ref("IO.OP", [par(0n)])}}]

def program() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, families(), type_functions(), BIR.Library{Nil{}}}

type ClaySmoke is Data:
  ClaySmoke{failures: U32}

# ---------------------------------------------------------------------------
# Small structural assertions
# ---------------------------------------------------------------------------

def both(+a: Bool, +b: Bool) -> Bool:
  match a:
    case True{}:
      b
    case False{}:
      False{}

def bool_eq(+a: Bool, +b: Bool) -> Bool:
  match a:
    case True{}:
      b
    case False{}:
      match b:
        case True{}:
          False{}
        case False{}:
          True{}

def fail(+ok: Bool) -> U32:
  match ok:
    case True{}:
      0
    case False{}:
      1

def first_word_32(+words: List<&2, CLay.CWord>) -> Bool:
  match words:
    case Nil{}:
      False{}
    case +word <> rest:
      match word:
        case CLay.CWord32{}:
          True{}
        case _:
          False{}

def first_word_64(+words: List<&2, CLay.CWord>) -> Bool:
  match words:
    case Nil{}:
      False{}
    case +word <> rest:
      match word:
        case CLay.CWord64{}:
          True{}
        case _:
          False{}

def first_word_box(+words: List<&2, CLay.CWord>) -> Bool:
  match words:
    case Nil{}:
      False{}
    case +word <> rest:
      match word:
        case CLay.CWordBox{}:
          True{}
        case _:
          False{}

# ---------------------------------------------------------------------------
# A value layout and a declared node are different observations.
# ---------------------------------------------------------------------------

def check_pt_value(+lr: CLay.LayoutResult) -> Bool:
  match lr:
    case CLay.LayoutFailed{+message}:
      False{}
    case CLay.LayoutFound{+layout}:
      match layout:
        case CLay.LayoutData{+words, +arms}:
          match arms:
            case +only <> rest:
              match only:
                case CLay.LayArm{+key, +fields}:
                  both(Nat.is_eq(CLay.layout_words(layout), 2n), both(first_word_32(words), both(String.eq(key, "Pt"), Nat.is_eq(List.length(&2, CLay.Layout, fields), 2n))))
            case Nil{}:
              False{}
        case _:
          False{}

def check_pt_node(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(Nat.is_eq(List.length(&2, CLay.CWord, words), 2n), bool_eq(packed, False{}))

def slot_offsets(+slots: List<&2, CLay.NodeSlot>) -> Bool:
  match slots:
    case Nil{}:
      False{}
    case +a <> r1:
      match a:
        case CLay.NodeSlot{+o1, +f1, +l1}:
          match r1:
            case Nil{}:
              False{}
            case +b <> r2:
              match b:
                case CLay.NodeSlot{+o2, +f2, +l2}:
                  match r2:
                    case Nil{}:
                      False{}
                    case +c <> r3:
                      match c:
                        case CLay.NodeSlot{+o3, +f3, +l3}:
                          match r3:
                            case Nil{}:
                              both(Nat.is_eq(f1, 0n), both(Nat.is_eq(f2, 2n), Nat.is_eq(f3, 4n)))
                            case _:
                              False{}

def check_seg_node(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(Nat.is_eq(List.length(&2, CLay.CWord, words), 6n), both(slot_offsets(slots), bool_eq(packed, False{})))

def check_opt_tag(+lr: CLay.LayoutResult) -> Bool:
  match lr:
    case CLay.LayoutFailed{+message}:
      False{}
    case CLay.LayoutFound{+layout}:
      match layout:
        case CLay.LayoutData{+words, +arms}:
          match arms:
            case +first <> rest:
              match first:
                case CLay.LayArm{+key, +fields}:
                  both(Nat.is_eq(CLay.layout_words(layout), 2n), both(first_word_32(words), both(String.eq(key, "None"), Nat.is_eq(List.length(&2, CLay.LayArm, arms), 2n))))
            case Nil{}:
              False{}
        case _:
          False{}

def check_w32_packed(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(bool_eq(packed, True{}), both(Nat.is_eq(List.length(&2, CLay.CWord, words), 1n), first_word_32(words)))

def check_nat_not_packed(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(bool_eq(packed, False{}), both(Nat.is_eq(List.length(&2, CLay.CWord, words), 1n), first_word_64(words)))

def check_empty_packed(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(bool_eq(packed, True{}), Nat.is_eq(List.length(&2, CLay.CWord, words), 0n))

# ---------------------------------------------------------------------------
# Generic fields: the declared node cannot instantiate a parameter, the value
# at an applied type can.
# ---------------------------------------------------------------------------

def check_box_declared_node(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(bool_eq(packed, False{}), both(Nat.is_eq(List.length(&2, CLay.CWord, words), 1n), first_word_box(words)))

def check_box_value(+lr: CLay.LayoutResult) -> Bool:
  match lr:
    case CLay.LayoutFailed{+message}:
      False{}
    case CLay.LayoutFound{+layout}:
      match layout:
        case CLay.LayoutData{+words, +arms}:
          match arms:
            case +only <> rest:
              match only:
                case CLay.LayArm{+key, +fields}:
                  match fields:
                    case +field <> frest:
                      both(Nat.is_eq(CLay.layout_words(layout), 1n), both(first_word_32(words), both(String.eq(key, "Box"), Nat.is_eq(List.length(&2, CLay.Layout, fields), 1n))))
                    case Nil{}:
                      False{}
            case Nil{}:
              False{}
        case _:
          False{}

# ---------------------------------------------------------------------------
# Arrays
# ---------------------------------------------------------------------------

def check_u32_cell(+cr: CLay.CellResult) -> Bool:
  match cr:
    case CLay.CellFailed{+message}:
      False{}
    case CLay.CellFound{+cell}:
      match cell:
        case CLay.Cell{+layout, +arr, +words, +lgs}:
          both(bool_eq(arr, False{}), both(Nat.is_eq(words, 1n), Nat.is_eq(lgs, 0n)))

def check_nat_cell(+cr: CLay.CellResult) -> Bool:
  match cr:
    case CLay.CellFailed{+message}:
      False{}
    case CLay.CellFound{+cell}:
      match cell:
        case CLay.Cell{+layout, +arr, +words, +lgs}:
          both(bool_eq(arr, True{}), both(Nat.is_eq(words, 1n), Nat.is_eq(lgs, 0n)))

def check_pt_cell(+cr: CLay.CellResult) -> Bool:
  match cr:
    case CLay.CellFailed{+message}:
      False{}
    case CLay.CellFound{+cell}:
      match cell:
        case CLay.Cell{+layout, +arr, +words, +lgs}:
          both(bool_eq(arr, False{}), both(Nat.is_eq(words, 2n), Nat.is_eq(lgs, 1n)))

def check_seg_cell(+cr: CLay.CellResult) -> Bool:
  match cr:
    case CLay.CellFailed{+message}:
      False{}
    case CLay.CellFound{+cell}:
      match cell:
        case CLay.Cell{+layout, +arr, +words, +lgs}:
          both(bool_eq(arr, False{}), both(Nat.is_eq(words, 6n), Nat.is_eq(lgs, 3n)))

def check_open_cell(+cr: CLay.CellResult) -> Bool:
  match cr:
    case CLay.CellFailed{+message}:
      False{}
    case CLay.CellFound{+cell}:
      match cell:
        case CLay.Cell{+layout, +arr, +words, +lgs}:
          both(bool_eq(arr, True{}), both(Nat.is_eq(words, 1n), Nat.is_eq(lgs, 0n)))

# ---------------------------------------------------------------------------
# Recursion, openness, and genuine reducer failure
# ---------------------------------------------------------------------------

def check_abstract_cell(+cr: CLay.CellResult) -> Bool:
  match cr:
    case CLay.CellFailed{message}:
      False{}
    case CLay.CellFound{+cell}:
      match cell:
        case CLay.Cell{+layout, +arr, +words, +lgs}:
          both(bool_eq(arr, True{}), both(Nat.is_eq(words, 1n), Nat.is_eq(lgs, 0n)))

def check_recursive(+lr: CLay.LayoutResult) -> Bool:
  match lr:
    case CLay.LayoutFailed{+message}:
      False{}
    case CLay.LayoutFound{+layout}:
      match layout:
        case CLay.LayoutBox{+reason}:
          match reason:
            case CLay.BoxRecursive{+key}:
              String.eq(key, "ListT")
            case _:
              False{}
        case _:
          False{}

def check_open_box(+lr: CLay.LayoutResult) -> Bool:
  match lr:
    case CLay.LayoutFailed{+message}:
      False{}
    case CLay.LayoutFound{+layout}:
      match layout:
        case CLay.LayoutBox{+reason}:
          match reason:
            case CLay.BoxUnresolved{+key}:
              String.eq(key, "Chan")
            case _:
              False{}
        case _:
          False{}

def check_failure(+lr: CLay.LayoutResult) -> Bool:
  match lr:
    case CLay.LayoutFailed{+message}:
      String.eq(message, "the checked type expression is a reducer failure")
    case CLay.LayoutFound{+layout}:
      False{}

# ---------------------------------------------------------------------------
# CLay.Fill and CLay.Unfill describe the same representation plan.
# ---------------------------------------------------------------------------

def nests_agree(+a: List<&2, CLay.Nest>, +b: List<&2, CLay.Nest>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case _:
          False{}
    case +x <> xr:
      match x:
        case CLay.Nest{+at1, +off1, +take1, +make1}:
          match b:
            case Nil{}:
              False{}
            case +y <> yr:
              match y:
                case CLay.Nest{+at2, +off2, +take2, +make2}:
                  both(Nat.is_eq(at1, off2), both(Nat.is_eq(off1, at2), both(Nat.is_eq(CLay.fill_words(make1), CLay.unfill_words(take2)), both(Nat.is_eq(CLay.unfill_words(take1), CLay.fill_words(make2)), nests_agree(xr, yr)))))
      case _:
        False{}

def forms_agree(+a: List<&2, CLay.FormArm>, +b: List<&2, CLay.FormArm>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case _:
          False{}
    case +x <> xr:
      match x:
        case CLay.FormArm{+kx, +tx, +px, +nx, +fx}:
          match b:
            case Nil{}:
              False{}
            case +y <> yr:
              match y:
                case CLay.FormArm{+ky, +ty, +py, +ny, +fy}:
                  both(String.eq(kx, ky), both(Nat.is_eq(tx, ty), both(bool_eq(px, py), both(Nat.is_eq(nx, ny), both(nests_agree(fx, fy), forms_agree(xr, yr))))))
      case _:
        False{}

def check_fill(+fr: CLay.FillResult, +ur: CLay.UnfillResult, +lr: CLay.LayoutResult) -> Bool:
  match fr:
    case CLay.FillFailed{+message}:
      False{}
    case CLay.FillFound{+fill}:
      match fill:
        case CLay.FillWord{}:
          match ur:
            case CLay.UnfillFailed{+message}:
              False{}
            case CLay.UnfillFound{+unfill}:
              match unfill:
                case CLay.UnfillWord{}:
                  match lr:
                    case CLay.LayoutFailed{+message}:
                      False{}
                    case CLay.LayoutFound{+layout}:
                      True{}
                case _:
                  False{}
        case CLay.FillForm{+fw, +fa}:
          match ur:
            case CLay.UnfillFailed{+message}:
              False{}
            case CLay.UnfillFound{+unfill}:
              match unfill:
                case CLay.UnfillForm{+uw, +ua}:
                  match lr:
                    case CLay.LayoutFailed{+message}:
                      False{}
                    case CLay.LayoutFound{+layout}:
                      both(Nat.is_eq(fw, uw), forms_agree(fa, ua))
                case _:
                  False{}

def extract(+lr: CLay.LayoutResult) -> CLay.Layout:
  match lr:
    case CLay.LayoutFound{+layout}:
      layout
    case CLay.LayoutFailed{+message}:
      CLay.LayoutBox{CLay.BoxOpen{}}

# ---------------------------------------------------------------------------
# Normalized heads and instantiated arm fields
# ---------------------------------------------------------------------------

def check_head_nat_alias(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadFound{+key, +native}:
      match native:
        case Some{+marker}:
          both(String.eq(key, "Nat"), String.eq(marker, "Nat"))
        case None{}:
          False{}
    case _:
      False{}

def check_head_array(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadFound{+key, +native}:
      match native:
        case Some{+marker}:
          both(String.eq(key, "Array"), String.eq(marker, "Array"))
        case None{}:
          False{}
    case _:
      False{}

def check_head_plain(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadFound{+key, +native}:
      match native:
        case Some{+marker}:
          False{}
        case None{}:
          String.eq(key, "Pt")
    case _:
      False{}

def check_head_open(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadBoxed{+reason}:
      match reason:
        case CLay.BoxUnresolved{+key}:
          String.eq(key, "Chan")
        case _:
          False{}
    case _:
      False{}

def check_head_failure(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadFailed{+message}:
      String.eq(message, "the checked type expression is a reducer failure")
    case _:
      False{}

def descriptor_is_ref(+ty: BIR.Descriptor, +key: String) -> Bool:
  match ty:
    case BIR.DescriptorRef{+found, +args}:
      String.eq(found, key)
    case _:
      False{}

def check_box_fields(+fr: CLay.FieldsResult) -> Bool:
  match fr:
    case CLay.FieldsFailed{+message}:
      False{}
    case CLay.FieldsFound{+fields}:
      match fields:
        case +field <> rest:
          match field:
            case BIR.DescriptorField{+key, +quantity, +ty}:
              both(descriptor_is_ref(ty, "U32"), Nat.is_eq(List.length(&2, BIR.DescriptorField, fields), 1n))
        case Nil{}:
          False{}

def check_pair_fields(+fr: CLay.FieldsResult) -> Bool:
  match fr:
    case CLay.FieldsFailed{+message}:
      False{}
    case CLay.FieldsFound{+fields}:
      match fields:
        case +first <> rest:
          match first:
            case BIR.DescriptorField{+k1, +q1, +ty1}:
              match rest:
                case +second <> more:
                  match second:
                    case BIR.DescriptorField{+k2, +q2, +ty2}:
                      both(descriptor_is_ref(ty1, "U32"), both(descriptor_is_ref(ty2, "Nat"), Nat.is_eq(List.length(&2, BIR.DescriptorField, fields), 2n)))
                case Nil{}:
                  False{}
        case Nil{}:
          False{}

def check_fields_failure(+fr: CLay.FieldsResult) -> Bool:
  match fr:
    case CLay.FieldsFailed{+message}:
      True{}
    case CLay.FieldsFound{+fields}:
      False{}

# ---------------------------------------------------------------------------

def mk_words(+n: Nat) -> List<&2, CLay.CWord>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      CLay.CWord32{} <> mk_words(p)

def mk_fields(+n: Nat) -> List<&2, BIR.DescriptorField>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      fld(ref("U32", Nil{})) <> mk_fields(p)

def wide_program() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, [fam("Wide", None{}, 0n, [arm("Wide", mk_fields(1100n))])], Nil{}, BIR.Library{Nil{}}}

def mk_miss(+n: Nat) -> List<&2, BIR.DescriptorArm>:
  match n:
    case 0n:
      [arm("hit", Nil{})]
    case 1n+p:
      arm("miss", Nil{}) <> mk_miss(p)

def check_ceil() -> Bool:
  both(Nat.is_eq(CLay.ceil_log2(1n), 0n), both(Nat.is_eq(CLay.ceil_log2(2n), 1n), both(Nat.is_eq(CLay.ceil_log2(3n), 2n), both(Nat.is_eq(CLay.ceil_log2(4n), 2n), both(Nat.is_eq(CLay.ceil_log2(6n), 3n), both(Nat.is_eq(CLay.ceil_log2(8n), 3n), both(Nat.is_eq(CLay.ceil_log2(16n), 4n), both(Nat.is_eq(CLay.ceil_log2(247n), 8n), both(Nat.is_eq(CLay.ceil_log2(248n), 8n), Nat.is_eq(CLay.ceil_log2(256n), 8n))))))))))

def check_pow2() -> Bool:
  both(Nat.is_eq(CLay.pow2_upto(1n, 1n), 1n), both(Nat.is_eq(CLay.pow2_upto(1n, 247n), 256n), both(Nat.is_eq(CLay.pow2_upto(1n, 248n), 256n), both(Nat.is_eq(CLay.pow2_upto(1n, 256n), 256n), Nat.is_eq(CLay.pow2_upto(1n, 300n), 512n)))))

def check_pad(+n: Nat, +target: Nat) -> Bool:
  Nat.is_eq(List.length(&2, CLay.CWord, CLay.pad_words(mk_words(n))), target)

def check_wide(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(Nat.is_eq(List.length(&2, CLay.NodeSlot, slots), 1100n), both(Nat.is_eq(List.length(&2, CLay.CWord, words), 2048n), bool_eq(packed, False{})))

def check_long_arm(+mr: Maybe<&2, BIR.DescriptorArm>) -> Bool:
  match mr:
    case None{}:
      False{}
    case Some{+arm}:
      True{}

def check_norm_alias(+nr: CLay.NormResult) -> Bool:
  match nr:
    case CLay.NormFailed{message}:
      False{}
    case CLay.NormOk{+descriptor}:
      descriptor_is_ref(descriptor, "Nat")

def first_arg_is(+d: BIR.Descriptor, +key: String) -> Bool:
  match d:
    case BIR.DescriptorRef{+head, +args}:
      match args:
        case +first <> rest:
          descriptor_is_ref(first, key)
        case Nil{}:
          False{}
    case _:
      False{}

def check_norm_distinct(+a: CLay.NormResult, +b: CLay.NormResult) -> Bool:
  match a:
    case CLay.NormFailed{message}:
      False{}
    case CLay.NormOk{+da}:
      match b:
        case CLay.NormFailed{message}:
          False{}
        case CLay.NormOk{+db}:
          both(first_arg_is(da, "U32"), first_arg_is(db, "Nat"))

def check_norm_failure(+nr: CLay.NormResult) -> Bool:
  match nr:
    case CLay.NormFailed{message}:
      True{}
    case CLay.NormOk{+descriptor}:
      False{}

def args_first_is(+ar: CLay.ArgsResult, +key: String) -> Bool:
  match ar:
    case CLay.ArgsFailed{message}:
      False{}
    case CLay.ArgsOk{+args}:
      match args:
        case +first <> rest:
          descriptor_is_ref(first, key)
        case Nil{}:
          False{}

def check_args_pair(+ar: CLay.ArgsResult) -> Bool:
  match ar:
    case CLay.ArgsFailed{message}:
      False{}
    case CLay.ArgsOk{+args}:
      match args:
        case +first <> rest:
          match rest:
            case +second <> more:
              both(descriptor_is_ref(first, "U32"), both(descriptor_is_ref(second, "Nat"), Nat.is_eq(List.length(&2, BIR.Descriptor, args), 2n)))
            case Nil{}:
              False{}
        case Nil{}:
          False{}

def check_args_failure(+ar: CLay.ArgsResult) -> Bool:
  match ar:
    case CLay.ArgsFailed{message}:
      True{}
    case CLay.ArgsOk{+args}:
      False{}

def chain_key(+n: Nat) -> String:
  String.append("F", Nat.show(n))

def next_key(+n: Nat) -> String:
  match n:
    case 0n:
      "U32"
    case 1n+p:
      chain_key(p)

def fam_chain(+n: Nat) -> List<&2, BIR.Family>:
  match n:
    case 0n:
      [BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, Nil{}}]
    case 1n+p:
      +key = chain_key(p)
      +next = next_key(p)
      BIR.Family{key, key, None{}, 0n, 0n, [BIR.DescriptorArm{key, [BIR.DescriptorField{None{}, BIR.Unrestricted{}, BIR.DescriptorRef{next, Nil{}}}]}]} <> fam_chain(p)

def program_shadow() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, [fam_nat()], [BIR.TypeFunction{"IO", None{}, 0n, 1n, ref("Nat", Nil{})}], BIR.Library{Nil{}}}

def check_io_native(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadFound{+key, +native}:
      match native:
        case Some{+marker}:
          both(String.eq(key, "IO"), String.eq(marker, "IO"))
        case None{}:
          False{}
    case _:
      False{}

def check_io_under(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadBoxed{+reason}:
      match reason:
        case CLay.BoxOpen{}:
          True{}
        case _:
          False{}
    case _:
      False{}

def check_shadow_io(+hr: CLay.HeadResult) -> Bool:
  match hr:
    case CLay.HeadFound{+key, +native}:
      match native:
        case Some{+marker}:
          both(String.eq(key, "Nat"), String.eq(marker, "Nat"))
        case None{}:
          False{}
    case _:
      False{}

def program_deep() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, fam_chain(400n), Nil{}, BIR.Library{Nil{}}}

def classify(+lr: CLay.LayoutResult) -> Nat:
  match lr:
    case CLay.LayoutFailed{message}:
      1n
    case CLay.LayoutFound{+layout}:
      match layout:
        case CLay.LayoutData{+words, +arms}:
          match words:
            case +word <> rest:
              match word:
                case CLay.CWord32{}:
                  match rest:
                    case Nil{}:
                      match arms:
                        case +only <> more:
                          0n
                        case Nil{}:
                          2n
                    case _:
                      2n
                case _:
                  2n
            case Nil{}:
              2n
        case CLay.LayoutBox{+reason}:
          1n
        case _:
          2n

def deep_chain_check() -> Bool:
  +ctx = CLay.context(program_deep())
  Nat.is_eq(classify(CLay.value_layout(ctx, BIR.DescriptorRef{"F399", Nil{}})), 0n)

# ---------------------------------------------------------------------------
# The plan and the uncached rule answer the same node, per program
# ---------------------------------------------------------------------------
#
# A plan entry exists only for a constructor the program declares a row for, so
# these programs are the only place a plan is consulted: `program_rows` declares
# rows for Pt, Er and W32 (and none for Box, which must still resolve), and the
# two shadow programs declare one key each with different declarations.

def erased_fld() -> BIR.DescriptorField:
  BIR.DescriptorField{None{}, BIR.Erased{}, ref("U32", Nil{})}

def fam_erased() -> BIR.Family:
  fam("Er", None{}, 0n, [arm("Er", [fld(ref("U32", Nil{})), erased_fld(), fld(ref("Nat", Nil{}))])])

def families_plan() -> List<&2, BIR.Family>:
  fam_erased() <> families()

def row_pt() -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{0, "Pt", None{}, Nil{}}

def row_er() -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{1, "Er", None{}, Nil{}}

def row_w32() -> BIR.ConstructorLayout:
  BIR.ConstructorLayout{2, "W32", None{}, Nil{}}

def program_rows() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, [row_pt(), row_er(), row_w32()], families_plan(), type_functions(), BIR.Library{Nil{}}}

# The same constructor key with a different declaration: a plan belongs to one
# program, so this context's Pt is three words while the other context's stays
# two.
def fam_pt3() -> BIR.Family:
  fam("Pt", None{}, 0n, [arm("Pt", [fld(ref("U32", Nil{})), fld(ref("U32", Nil{})), fld(ref("U32", Nil{}))])])

def program_scope() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, [row_pt()], [fam_nat(), fam_u32(), fam_pt3()], type_functions(), BIR.Library{Nil{}}}

# One constructor key declared twice: the first family wins, as the family scan
# does, so the node is the one-word packed form and the declared fields are the
# first family's single field.
def fam_same_one() -> BIR.Family:
  fam("One", None{}, 0n, [arm("Same", [fld(ref("U32", Nil{}))])])

def fam_same_two() -> BIR.Family:
  fam("Two", None{}, 0n, [arm("Same", [fld(ref("U32", Nil{})), fld(ref("U32", Nil{}))])])

def program_first() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, [BIR.ConstructorLayout{0, "Same", None{}, Nil{}}], [fam_nat(), fam_u32(), fam_same_one(), fam_same_two()], type_functions(), BIR.Library{Nil{}}}

# Two live fields and one erased: the second slot's ordinal is 2, not 1, and the
# erased field takes no word.
def erased_slot_ordinals(+slots: List<&2, CLay.NodeSlot>) -> Bool:
  match slots:
    case Nil{}:
      False{}
    case +first <> rest:
      match first:
        case CLay.NodeSlot{+ord1, +off1, +lay1}:
          match rest:
            case Nil{}:
              False{}
            case +second <> more:
              match second:
                case CLay.NodeSlot{+ord2, +off2, +lay2}:
                  both(U32.is_eq(ord1, 0), both(U32.is_eq(ord2, U32.from_nat(2n)), both(Nat.is_eq(off1, 0n), both(Nat.is_eq(off2, 1n), both(Nat.is_eq(CLay.layout_words(lay1), 1n), Nat.is_eq(CLay.layout_words(lay2), 1n))))))

def check_erased_node(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(bool_eq(packed, False{}), both(Nat.is_eq(List.length(&2, CLay.CWord, words), 2n), both(first_word_32(words), both(Nat.is_eq(List.length(&2, CLay.NodeSlot, slots), 2n), erased_slot_ordinals(slots)))))

def check_three_word_node(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(bool_eq(packed, False{}), both(Nat.is_eq(List.length(&2, CLay.CWord, words), 3n), Nat.is_eq(List.length(&2, CLay.NodeSlot, slots), 3n)))

def check_packed_one(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      False{}
    case CLay.NodeFound{+node}:
      match node:
        case CLay.Node{+words, +slots, +packed}:
          both(bool_eq(packed, True{}), both(Nat.is_eq(List.length(&2, CLay.CWord, words), 1n), both(first_word_32(words), Nat.is_eq(List.length(&2, CLay.NodeSlot, slots), 1n))))

def check_node_failed(+nr: CLay.NodeResult) -> Bool:
  match nr:
    case CLay.NodeFailed{+message}:
      True{}
    case CLay.NodeFound{+node}:
      False{}

def check_declared_count(+mr: Maybe<&2, BIR.DescriptorArm>, +pwant: Nat) -> Bool:
  match mr:
    case None{}:
      False{}
    case Some{+arm}:
      match arm:
        case BIR.DescriptorArm{+key, +fields}:
          Nat.is_eq(List.length(&2, BIR.DescriptorField, fields), pwant)

def check_declared_none(+mr: Maybe<&2, BIR.DescriptorArm>) -> Bool:
  match mr:
    case None{}:
      True{}
    case Some{+arm}:
      False{}

def main(modules: List<&2, Loader.LoadedModule>) -> ClaySmoke:
  +ctx = CLay.context(program())
  +pt = CLay.value_layout(ctx, ref("Pt", Nil{}))
  +ptn = CLay.node_layout(ctx, "Pt")
  +segn = CLay.node_layout(ctx, "Seg")
  +opt = CLay.value_layout(ctx, ref("Opt", Nil{}))
  +w32 = CLay.node_layout(ctx, "W32")
  +onenat = CLay.node_layout(ctx, "OneNat")
  +empty = CLay.node_layout(ctx, "Empty0")
  +boxn = CLay.node_layout(ctx, "Box")
  +boxv = CLay.value_layout(ctx, ref("Box", [ref("U32", Nil{})]))
  +u32c = CLay.array_cell(ctx, ref("U32", Nil{}))
  +natc = CLay.array_cell(ctx, ref("Nat", Nil{}))
  +ptc = CLay.array_cell(ctx, ref("Pt", Nil{}))
  +segc = CLay.array_cell(ctx, ref("Seg", Nil{}))
  +openc = CLay.array_cell(ctx, par(0n))
  +chanc = CLay.array_cell(ctx, ref("Chan", Nil{}))
  +rec = CLay.value_layout(ctx, ref("ListT", Nil{}))
  +openv = CLay.value_layout(ctx, ref("Chan", Nil{}))
  +bad = CLay.value_layout(ctx, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +seglr = CLay.value_layout(ctx, ref("Seg", Nil{}))
  +optfill = CLay.layout_fill(ctx, extract(opt))
  +optunfill = CLay.layout_unfill(ctx, extract(opt))
  +segfill = CLay.layout_fill(ctx, extract(seglr))
  +segunfill = CLay.layout_unfill(ctx, extract(seglr))
  +hmy = CLay.head_native(ctx, ref("MyNat", Nil{}))
  +harr = CLay.head_native(ctx, ref("Array", [ref("U32", Nil{})]))
  +hpt = CLay.head_native(ctx, ref("Pt", Nil{}))
  +hopen = CLay.head_native(ctx, ref("Chan", Nil{}))
  +hbad = CLay.head_native(ctx, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +fbox = CLay.arm_fields(ctx, "Box", ref("Box", [ref("U32", Nil{})]))
  +fpair = CLay.arm_fields(ctx, "Pair", ref("Pair", [ref("U32", Nil{}), ref("Nat", Nil{})]))
  +fbad = CLay.arm_fields(ctx, "Box", BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +f1 = fail(check_pt_value(pt))
  +f2 = fail(check_pt_node(ptn))
  +f3 = fail(check_seg_node(segn))
  +f4 = fail(check_opt_tag(opt))
  +f5 = fail(check_w32_packed(w32))
  +f6 = fail(check_nat_not_packed(onenat))
  +f7 = fail(check_empty_packed(empty))
  +f8 = fail(check_box_declared_node(boxn))
  +f9 = fail(check_box_value(boxv))
  +f10 = fail(check_u32_cell(u32c))
  +f11 = fail(check_nat_cell(natc))
  +f12 = fail(check_pt_cell(ptc))
  +f13 = fail(check_seg_cell(segc))
  +f14 = fail(check_open_cell(openc))
  +f15 = fail(check_recursive(rec))
  +f16 = fail(check_open_box(openv))
  +f17 = fail(check_failure(bad))
  +f18 = fail(check_fill(optfill, optunfill, opt))
  +f19 = fail(check_fill(segfill, segunfill, seglr))
  +f20 = fail(check_head_nat_alias(hmy))
  +f21 = fail(check_head_array(harr))
  +f22 = fail(check_head_plain(hpt))
  +f23 = fail(check_head_open(hopen))
  +f24 = fail(check_head_failure(hbad))
  +f25 = fail(check_box_fields(fbox))
  +f26 = fail(check_pair_fields(fpair))
  +f27 = fail(check_fields_failure(fbad))
  +f28 = fail(check_abstract_cell(chanc))
  +ctxw = CLay.context(wide_program())
  +widen = CLay.node_layout(ctxw, "Wide")
  +longarm = CLay.arm_in("hit", mk_miss(1500n))
  f29 = fail(check_ceil())
  f30 = fail(check_pow2())
  f31 = fail(check_pad(247n, 247n))
  f32 = fail(check_pad(248n, 256n))
  f33 = fail(check_pad(256n, 256n))
  f34 = fail(check_pad(300n, 512n))
  f35 = fail(check_wide(widen))
  f36 = fail(check_long_arm(longarm))
  +nmy = CLay.norm(ctx, ref("MyNat", Nil{}))
  +npa = CLay.norm(ctx, ref("Pair", [ref("U32", Nil{}), ref("Nat", Nil{})]))
  +npb = CLay.norm(ctx, ref("Pair", [ref("Nat", Nil{}), ref("U32", Nil{})]))
  +nfail = CLay.norm(ctx, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  +aarr = CLay.head_args(ctx, ref("Array", [ref("U32", Nil{})]))
  +apair = CLay.head_args(ctx, ref("Pair", [ref("U32", Nil{}), ref("Nat", Nil{})]))
  +aopen = CLay.head_args(ctx, BIR.DescriptorFailure{"the checked type expression is a reducer failure"})
  f37 = fail(check_norm_alias(nmy))
  f38 = fail(check_norm_distinct(npa, npb))
  f39 = fail(check_norm_failure(nfail))
  f40 = fail(args_first_is(aarr, "U32"))
  f41 = fail(check_args_pair(apair))
  f42 = fail(check_args_failure(aopen))
  # The plan, per program. `rpt` is the plan's Pt and `ptn` the same key's node
  # from a program with no constructor rows, so the two must agree; `ptn2` is
  # that context asked again after three later contexts were built, so no plan
  # entry leaks between them; `rbox` has no row at all and must still resolve.
  +ctxr = CLay.context(program_rows())
  +rpt = CLay.node_layout(ctxr, "Pt")
  +rbox = CLay.node_layout(ctxr, "Box")
  +rboxv = CLay.value_layout(ctxr, ref("Box", [ref("U32", Nil{})]))
  +rw32 = CLay.node_layout(ctxr, "W32")
  +rer = CLay.node_layout(ctxr, "Er")
  +rstarve = CLay.node_layout_fuel(ctxr, "Pt", 1n)
  +scoped = CLay.context(program_scope())
  +spt = CLay.node_layout(scoped, "Pt")
  +first = CLay.context(program_first())
  +fsame = CLay.node_layout(first, "Same")
  +dp = CLay.arm_declared(ctxr, "Pt")
  +der = CLay.arm_declared(ctxr, "Er")
  +dchan = CLay.arm_declared(ctxr, "Chan")
  +dfirst = CLay.arm_declared(first, "Same")
  +ptn2 = CLay.node_layout(ctx, "Pt")
  +planf = U32.add(fail(check_pt_node(rpt)), U32.add(fail(check_box_declared_node(rbox)), U32.add(fail(check_box_value(rboxv)), U32.add(fail(check_w32_packed(rw32)), U32.add(fail(check_erased_node(rer)), U32.add(fail(check_node_failed(rstarve)), U32.add(fail(check_three_word_node(spt)), U32.add(fail(check_packed_one(fsame)), U32.add(fail(check_declared_count(dp, 2n)), U32.add(fail(check_declared_count(der, 3n)), U32.add(fail(check_declared_none(dchan)), U32.add(fail(check_declared_count(dfirst, 1n)), fail(check_pt_node(ptn2))))))))))))))
  ClaySmoke{U32.add(planf, U32.add(f1, U32.add(f2, U32.add(f3, U32.add(f4, U32.add(f5, U32.add(f6, U32.add(f7, U32.add(f8, U32.add(f9, U32.add(f10, U32.add(f11, U32.add(f12, U32.add(f13, U32.add(f14, U32.add(f15, U32.add(f16, U32.add(f17, U32.add(f18, U32.add(f19, U32.add(f20, U32.add(f21, U32.add(f22, U32.add(f23, U32.add(f24, U32.add(f25, U32.add(f26, U32.add(f27, U32.add(f28, U32.add(f29, U32.add(f30, U32.add(f31, U32.add(f32, U32.add(f33, U32.add(f34, U32.add(f35, U32.add(f36, U32.add(f37, U32.add(f38, U32.add(f39, U32.add(f40, U32.add(f41, U32.add(f42, U32.add(fail(deep_chain_check()), U32.add(fail(check_io_native(CLay.head_native(ctx, ref("IO", [ref("Nat", Nil{})])))), U32.add(fail(check_io_under(CLay.head_native(ctx, ref("IO", Nil{})))), U32.add(fail(check_io_native(CLay.head_native(ctx, ref("MyIO", Nil{})))), fail(check_shadow_io(CLay.head_native(CLay.context(program_shadow()), ref("IO", [ref("Nat", Nil{})])))))))))))))))))))))))))))))))))))))))))))))))))))}
