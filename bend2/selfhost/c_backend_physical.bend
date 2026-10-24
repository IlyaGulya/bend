# C target physical emission
# ===========================
#
# SHOW_DESC/SHOW_NAMES construction for the C backend, from the frozen layout
# oracle (c_backend_layout.bend) and Backend IR facts only. It owns no segment,
# call or table emission (CIRControl) and never re-derives a layout from a key
# spelling.
#
# Authority: comp.ts show_main. The descriptor is ONE FLAT WORD ARRAY: a cell's
# id is the WORD OFFSET where its cell starts, exactly like show.push(kind) - 1
# in the reference, and every reference slot holds that offset. A child is
# appended after the parent's header and its offset is patched into the
# reserved slot, because appending a variable-length cell moves every later
# word. Rules reproduced:
#   * kind = position of the datatype in U32 F32 Nat Char String . Array & 7
#     (Eql 5), everything else 7;
#   * Char pushes [3, box]; Array pushes [6, element offset, lgs]; Data pushes
#     [7, box, arm count] then per arm [name index, cid, live field count,
#     bracket] (Tuple 2, Con/Nil 1, else 0) then per field [offset, cell];
#   * box = 1 iff the value layout is a box; field offsets start at the tag word
#     (!box && arms > 1) and advance by the field layout's word count;
#   * a zero-word root layout is a box;
#   * a cell is memoized on (type key, layout key) BEFORE recursing, so a
#     recursive datatype terminates and reuses its already known word offset.
#
# Entry point: show_build(ctx, main_type, constructors, families) returns the
# SHOW_DESC initializer; show_names(constructors) is the SHOW_NAMES initializer.

import Base
import ./backend_ir.bend as BIR
import ./c_backend_layout.bend as CLay
import ./index_lookup.bend as IndexLookup

# A word of the flat descriptor: a literal, or a constructor id rendered as
# CID_<id>. A reference slot starts as WNum 0 and is patched to the child's
# word offset.
type Word is Data:
  WNum{value: Nat}
  WCid{value: Nat}

type Patch is Data:
  Patch{at: Nat, to: Nat}

type ShState is Data:
  ShState{words: List<&2, Word>, patches: List<&2, Patch>, memo: Map<&2, Nat>}

type Step is Data:
  Step{ok: Bool, message: String, id: Nat, state: ShState}

type AppendOut is Data:
  AppendOut{state: ShState, at: Nat}

type ShowOut is Data:
  ShowOk{desc: String, names: String}
  ShowFail{message: String}

def show_build(ctx: CLay.Context, main_type: BIR.Descriptor, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>) -> ShowOut:
  start = ShState{Nil{}, Nil{}, Map.new(&2, Nat)}
  m1 = CLay.value_layout(ctx, main_type)
  match m1:
    case CLay.LayoutFailed{message}: ShowFail{message}
    case CLay.LayoutFound{layout}:
      m2 = show_node(ctx, main_type, root_layout(layout), families, constructors, start)
      match m2:
        case Step{ok, message, id, state}:
          match ok:
            case True{}: show_finish(state)
            case False{}: ShowFail{message}

def root_layout(layout: CLay.Layout) -> CLay.Layout:
  m3 = CLay.layout_words(layout)
  match m3:
    case 0n: CLay.LayoutBox{CLay.BoxWide{0n}}
    case _: layout

def show_finish(st: ShState) -> ShowOut:
  match st:
    case ShState{words, patches, memo}: ShowOk{render_words(apply_patches(words, patches, 0n), ""), ""}

# ---------------------------------------------------------------------------
# State helpers: append a word, reserve a slot, record a patch
# ---------------------------------------------------------------------------

def show_node(ctx: CLay.Context, ty: BIR.Descriptor, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState) -> Step:
  key = show_key(ty, layout)
  m4 = IndexLookup.find(Nat, memo_of(st), key)
  match m4:
    case Some{offset}: Step{True{}, "", offset, st}
    case None{}:
      reserved = words_of(st)
      at = List.length(&2, Word, words_of(st))
      memo = Map.set(&2, Nat, memo_of(st), key, at)
      m5 = show_cell(ctx, ty, layout, families, constructors, ShState{reserved, patches_of(st), memo})
      match m5:
        case Step{ok, message, id, state}:
          match ok:
            case True{}: Step{True{}, "", at, state}
            case False{}: Step{False{}, message, at, state}

def words_of(st: ShState) -> List<&2, Word>:
  match st:
    case ShState{words, patches, memo}: words

def patches_of(st: ShState) -> List<&2, Patch>:
  match st:
    case ShState{words, patches, memo}: patches

def memo_of(st: ShState) -> Map<&2, Nat>:
  match st:
    case ShState{words, patches, memo}: memo

def append_word(st: ShState, word: Word) -> AppendOut:
  AppendOut{ShState{words_of(st) <> [word], patches_of(st), memo_of(st)}, List.length(&2, Word, words_of(st))}

def append_num(st: ShState, value: Nat) -> AppendOut:
  append_word(st, WNum{value})

def append_cid(st: ShState, value: Nat) -> AppendOut:
  append_word(st, WCid{value})

def append_patch(st: ShState, at: Nat, to: Nat) -> ShState:
  ShState{words_of(st), Patch{at, to} <> patches_of(st), memo_of(st)}

# ---------------------------------------------------------------------------
# Cells
# ---------------------------------------------------------------------------

type KindOut is Data:
  KindOk{kind: Nat}
  KindFailed{message: String}

def show_cell(ctx: CLay.Context, ty: BIR.Descriptor, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState) -> Step:
  m6 = show_kind(ctx, ty)
  match m6:
    case KindFailed{message}: Step{False{}, message, 0n, st}
    case KindOk{kind}: show_cell_kind(ctx, ty, layout, families, constructors, st, kind)

def show_cell_kind(ctx: CLay.Context, ty: BIR.Descriptor, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState, kind: Nat) -> Step:
  match kind:
    case 5n: append_plain(st, 5n)
    case 0n: append_plain(st, 0n)
    case 1n: append_plain(st, 1n)
    case 2n: append_plain(st, 2n)
    case 3n: show_char_cell(st, layout)
    case 4n: append_plain(st, 4n)
    case 6n: show_array_cell(ctx, ty, families, constructors, st)
    case _: show_data_cell(ctx, ty, layout, families, constructors, st)

def append_plain(st: ShState, value: Nat) -> Step:
  m7 = append_num(st, value)
  match m7:
    case AppendOut{state, at}: Step{True{}, "", at, state}

def show_char_cell(st: ShState, layout: CLay.Layout) -> Step:
  m8 = append_num(st, 3n)
  match m8:
    case AppendOut{state, at}:
      m9 = append_num(state, box_flag(layout))
      match m9:
        case AppendOut{state: state2, at}: Step{True{}, "", at, state2}

def box_flag(layout: CLay.Layout) -> Nat:
  match layout:
    case CLay.LayoutBox{reason}: 1n
    case _: 0n

# The shared oracle decides the printed kind: aliases reduce to their family,
# and an abstract or open form cannot be printed at all.
def show_kind(ctx: CLay.Context, ty: BIR.Descriptor) -> KindOut:
  m10 = CLay.head_native(ctx, ty)
  match m10:
    case CLay.HeadFailed{message}: KindFailed{message}
    case CLay.HeadBoxed{reason}: KindFailed{"main's type is abstract or open and cannot be printed"}
    case CLay.HeadFound{key, native}: kind_of_native(native)

def kind_of_native(native: Maybe<&2, String>) -> KindOut:
  match native:
    case None{}: KindOk{7n}
    case Some{tag}: KindOk{native_kind(tag)}

def native_kind(native: String) -> Nat:
  m12 = last_segment(native)
  match m12:
    case "U32": 0n
    case "F32": 1n
    case "Nat": 2n
    case "Char": 3n
    case "String": 4n
    case "Eql": 5n
    case "Array": 6n
    case _: 7n

def show_array_cell(ctx: CLay.Context, ty: BIR.Descriptor, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState) -> Step:
  m13 = descriptor_args(ty)
  match m13:
    case +element <> rest:
      m14 = CLay.array_cell(ctx, element)
      match m14:
        case CLay.CellFailed{message}: Step{False{}, message, 0n, st}
        case CLay.CellFound{cell}:
          match cell:
            case CLay.Cell{layout, arr, words, lgs}:
              m15 = append_num(st, 6n)
              match m15:
                case AppendOut{state, at}:
                  m16 = append_num(state, 0n)
                  match m16:
                    case AppendOut{state: p1, at: slot}:
                      m17 = append_num(p1, lgs)
                      match m17:
                        case AppendOut{state: p2, at: _}:
                          m18 = CLay.value_layout(ctx, element)
                          match m18:
                            case CLay.LayoutFailed{message}: Step{False{}, message, 0n, p2}
                            case CLay.LayoutFound{layout}:
                              m19 = show_node(ctx, element, layout, families, constructors, p2)
                              match m19:
                                case Step{ok, message, id, state: after}:
                                  match ok:
                                    case True{}: Step{True{}, "", at, append_patch(after, slot, id)}
                                    case False{}: Step{False{}, message, 0n, after}
    case Nil{}: Step{False{}, "an Array descriptor without an element type cannot be printed", 0n, st}

def show_data_cell(ctx: CLay.Context, ty: BIR.Descriptor, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState) -> Step:
  m20 = descriptor_head(ty)
  match m20:
    case None{}: Step{False{}, "a datatype without a key cannot be printed", 0n, st}
    case Some{key}:
      m21 = family_arms_of(key, families)
      match m21:
        case None{}: Step{False{}, cat(["the datatype `", key, "` has no constructors"]), 0n, st}
        case Some{arms}:
          box = box_flag(layout)
          count = List.length(&2, BIR.DescriptorArm, arms)
          m22 = append_num(st, 7n)
          match m22:
            case AppendOut{state, at}:
              m23 = append_num(state, box)
              match m23:
                case AppendOut{state: p1, at: _}:
                  m24 = append_num(p1, count)
                  match m24:
                    case AppendOut{state: p2, at: _}:
                      m25 = show_arms(ctx, ty, arms, layout, box, count, families, constructors, p2, 0n)
                      match m25:
                        case Step{ok, message, id, state: after}:
                          match ok:
                            case True{}: Step{True{}, "", at, after}
                            case False{}: Step{False{}, message, 0n, after}

def show_arms(ctx: CLay.Context, ty: BIR.Descriptor, arms: List<&2, BIR.DescriptorArm>, layout: CLay.Layout, box: Nat, count: Nat, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState, name_index: Nat) -> Step:
  match arms:
    case Nil{}: Step{True{}, "", 0n, st}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key, fields: _}:
          m24 = CLay.arm_fields(ctx, key, ty)
          match m24:
            case CLay.FieldsFailed{message}: Step{False{}, message, 0n, st}
            case CLay.FieldsFound{fields}: show_arm_one(ctx, ty, rest, key, fields, layout, box, count, families, constructors, st, name_index)

def show_arm_one(ctx: CLay.Context, ty: BIR.Descriptor, rest: List<&2, BIR.DescriptorArm>, key: String, fields: List<&2, BIR.DescriptorField>, layout: CLay.Layout, box: Nat, count: Nat, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState, name_index: Nat) -> Step:
          m26 = append_num(st, name_index)
          match m26:
            case AppendOut{state, at}:
              m27 = append_cid(state, cid_index(key, constructors, 0n))
              match m27:
                case AppendOut{state: p1, at: _}:
                  m28 = append_num(p1, live_count(fields))
                  match m28:
                    case AppendOut{state: p2, at: _}:
                      m29 = append_num(p2, arm_bracket(key))
                      match m29:
                        case AppendOut{state: p3, at: _}:
                          m30 = show_arm_fields(ctx, key, fields, layout, box, count, families, constructors, p3)
                          match m30:
                            case Step{ok, message, id, state: after}:
                              match ok:
                                case True{}: show_arms(ctx, ty, rest, layout, box, count, families, constructors, after, nat_inc(name_index))
                                case False{}: Step{False{}, message, 0n, after}

def nat_inc(value: Nat) -> Nat:
  Nat.add(value, 1n)

def arm_bracket(key: String) -> Nat:
  m31 = last_segment(key)
  match m31:
    case "Tuple": 2n
    case "Con": 1n
    case "Nil": 1n
    case _: 0n

def live_count(fields: List<&2, BIR.DescriptorField>) -> Nat:
  List.length(&2, BIR.DescriptorField, live_fields(fields, Nil{}))

def live_fields(fields: List<&2, BIR.DescriptorField>, acc: List<&2, BIR.DescriptorField>) -> List<&2, BIR.DescriptorField>:
  match fields:
    case Nil{}: List.reverse(&2, BIR.DescriptorField, acc)
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match quantity:
            case BIR.Erased{}: live_fields(rest, acc)
            case _: live_fields(rest, field <> acc)

def tag_start(box: Nat, count: Nat) -> Nat:
  match box:
    case 1n: 0n
    case _:
      m32 = Nat.is_gt(count, 1n)
      match m32:
        case True{}: 1n
        case False{}: 0n

# Boxed arms read field layouts from the constructor's node (SOURCE ordinals);
# inline arms read the value layout's arm and advance by each field's words.
def show_arm_fields(ctx: CLay.Context, key: String, fields: List<&2, BIR.DescriptorField>, layout: CLay.Layout, box: Nat, count: Nat, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState) -> Step:
  match box:
    case 1n: show_slots(ctx, key, fields, families, constructors, st)
    case _: show_inline(ctx, key, live_fields(fields, Nil{}), layout, families, constructors, st, tag_start(box, count))

def show_slots(ctx: CLay.Context, key: String, fields: List<&2, BIR.DescriptorField>, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState) -> Step:
  m33 = CLay.node_layout(ctx, key)
  match m33:
    case CLay.NodeFailed{message}: Step{False{}, message, 0n, st}
    case CLay.NodeFound{node}:
      match node:
        case CLay.Node{words, slots, packed}: show_slot_each(ctx, slots, fields, families, constructors, st)

def show_slot_each(ctx: CLay.Context, slots: List<&2, CLay.NodeSlot>, fields: List<&2, BIR.DescriptorField>, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState) -> Step:
  match slots:
    case Nil{}: Step{True{}, "", 0n, st}
    case +slot <> rest:
      match slot:
        case CLay.NodeSlot{ordinal, offset, layout}:
          m34 = field_at(fields, ordinal)
          match m34:
            case None{}: Step{False{}, "a constructor node slot names no live field", 0n, st}
            case Some{field}:
              match field:
                case BIR.DescriptorField{key, quantity, ty}:
                  m35 = append_num(st, offset)
                  match m35:
                    case AppendOut{state, at}:
                      m36 = append_num(state, 0n)
                      match m36:
                        case AppendOut{state: p1, at: slot_at}:
                          m37 = show_node(ctx, ty, layout, families, constructors, p1)
                          match m37:
                            case Step{ok, message, id, state: after}:
                              match ok:
                                case True{}: show_slot_each(ctx, rest, fields, families, constructors, append_patch(after, slot_at, id))
                                case False{}: Step{False{}, message, 0n, after}

def show_inline(ctx: CLay.Context, key: String, fields: List<&2, BIR.DescriptorField>, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState, at: Nat) -> Step:
  m38 = arm_layouts(layout, key)
  match m38:
    case None{}: Step{False{}, cat(["the inline layout has no arm `", key, "`"]), 0n, st}
    case Some{layouts}: show_inline_each(ctx, fields, layouts, families, constructors, st, at)

def show_inline_each(ctx: CLay.Context, fields: List<&2, BIR.DescriptorField>, layouts: List<&2, CLay.Layout>, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShState, at: Nat) -> Step:
  match fields layouts:
    case Nil{} _: Step{True{}, "", 0n, st}
    case +field <> rest +layout <> rest_layouts:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          m39 = append_num(st, at)
          match m39:
            case AppendOut{state, at: pos}:
              m40 = append_num(state, 0n)
              match m40:
                case AppendOut{state: p1, at: slot_at}:
                  m41 = show_node(ctx, ty, layout, families, constructors, p1)
                  match m41:
                    case Step{ok, message, id, state: after}:
                      match ok:
                        case True{}: show_inline_each(ctx, rest, rest_layouts, families, constructors, append_patch(after, slot_at, id), Nat.add(at, CLay.layout_words(layout)))
                        case False{}: Step{False{}, message, 0n, after}
    case _ _: Step{False{}, "an inline arm's fields and layouts differ in length", 0n, st}

# ---------------------------------------------------------------------------
# Patches and rendering
# ---------------------------------------------------------------------------

def apply_patches(words: List<&2, Word>, patches: List<&2, Patch>, index: Nat) -> List<&2, Word>:
  match patches:
    case Nil{}: words
    case +patch <> rest:
      match patch:
        case Patch{at, to}: apply_patches(set_word(words, at, WNum{to}, 0n), rest, index)

def set_word(words: List<&2, Word>, at: Nat, value: Word, index: Nat) -> List<&2, Word>:
  match words:
    case Nil{}: Nil{}
    case +word <> rest:
      m42 = Nat.is_eq(index, at)
      match m42:
        case True{}: value <> rest
        case False{}: word <> set_word(rest, at, value, nat_inc(index))

def render_words(words: List<&2, Word>, acc: String) -> String:
  match words:
    case Nil{}: acc
    case +word <> rest: render_words(rest, cat([acc, render_sep(acc), render_word(word)]))

def render_sep(acc: String) -> String:
  m43 = String.is_empty(acc)
  match m43:
    case True{}: ""
    case False{}: ","

def render_word(word: Word) -> String:
  match word:
    case WNum{value}: Nat.show(value)
    case WCid{value}: cat(["CID_", Nat.show(value)])

# ---------------------------------------------------------------------------
# Names and keys
# ---------------------------------------------------------------------------

def show_names(constructors: List<&2, BIR.ConstructorLayout>) -> String:
  match constructors:
    case Nil{}: ""
    case +item <> rest:
      match item:
        case BIR.ConstructorLayout{id, key, native, fields}: cat([quote_name(key), sep_for(rest), show_names(rest)])

def sep_for(rest: List<&2, BIR.ConstructorLayout>) -> String:
  match rest:
    case Nil{}: ""
    case _: ","

def quote_name(text: String) -> String:
  cat(["\u{22}", text, "\u{22}"])

# A memo key is the full type key plus a canonical layout key, so two different
# types of the same shape keep their own arms.
def show_key(ty: BIR.Descriptor, layout: CLay.Layout) -> String:
  cat([descriptor_key(ty), "@", layout_key(layout)])

def descriptor_key(ty: BIR.Descriptor) -> String:
  match ty:
    case BIR.DescriptorRef{key, args}: cat([key, "(", descriptor_keys(args), ")"])
    case BIR.DescriptorApplication{fn, arg}: cat([descriptor_key(fn), "<", descriptor_key(arg), ">"])
    case BIR.DescriptorFill{head, args}: cat([descriptor_key(head), "[", descriptor_keys(args), "]"])
    case BIR.DescriptorPlus{head, args}: cat([descriptor_key(head), "+[", descriptor_keys(args), "]"])
    case BIR.DescriptorNamedFill{key, head, args}: cat([key, ":", descriptor_key(head), "[", descriptor_keys(args), "]"])
    case BIR.DescriptorNamedPlus{key, head, args}: cat([key, ":", descriptor_key(head), "+[", descriptor_keys(args), "]"])
    case BIR.DescriptorParameter{index}: cat(["#", Nat.show(index)])
    case BIR.DescriptorNull{}: "null"
    case BIR.DescriptorKind{quantity}: cat(["K(", descriptor_key(quantity), ")"])
    case BIR.DescriptorQuantity{quantity}: cat(["Q(", quantity_key(quantity), ")"])
    case BIR.DescriptorQuantityKind{}: "QK"
    case BIR.DescriptorMinimum{left, right}: cat(["min(", descriptor_key(left), ",", descriptor_key(right), ")"])
    case BIR.DescriptorArrow{quantity, domain, body}: cat(["(", descriptor_key(domain), ")->", descriptor_key(body)])
    case BIR.DescriptorLambda{quantity, body}: cat(["\\", descriptor_key(body)])
    case BIR.DescriptorConstructor{key, args}: cat(["@", key, "(", descriptor_keys(args), ")"])
    case BIR.DescriptorFailure{message}: cat(["!", message])
    case BIR.DescriptorSubstitution{index, value, body}: cat(["S", Nat.show(index), "(", descriptor_key(value), ";", descriptor_key(body), ")"])
    case BIR.DescriptorLet{values, body}: cat(["L(", descriptor_keys(values), ";", descriptor_key(body), ")"])
    case BIR.DescriptorLocal{patterns, values, body}: cat(["Loc(", Nat.show(List.length(&2, BIR.DescriptorPattern, patterns)), ",", descriptor_keys(values), ";", descriptor_key(body), ")"])
    case BIR.DescriptorMatch{values, cases}: cat(["M(", descriptor_keys(values), ";", descriptor_keys(cases), ")"])
    case BIR.DescriptorCase{patterns, body}: cat(["C(", Nat.show(List.length(&2, BIR.DescriptorPattern, patterns)), ";", descriptor_key(body), ")"])
    case BIR.DescriptorBind{value, body}: cat(["B(", descriptor_key(value), ";", descriptor_key(body), ")"])
    case BIR.DescriptorEquality{left, right, ty}: cat(["E(", descriptor_key(left), ",", descriptor_key(right), ",", descriptor_key(ty), ")"])
    case BIR.DescriptorReflexivity{}: "R"
    case _: "?"

def descriptor_keys(args: List<&2, BIR.Descriptor>) -> String:
  match args:
    case Nil{}: ""
    case +arg <> rest: cat([descriptor_key(arg), key_sep(rest)])

def key_sep(rest: List<&2, BIR.Descriptor>) -> String:
  match rest:
    case Nil{}: ""
    case _: cat([",", descriptor_keys(rest)])

def quantity_key(quantity: BIR.Quantity) -> String:
  match quantity:
    case BIR.Erased{}: "0"
    case BIR.Once{}: "1"
    case BIR.Unrestricted{}: "2"
    case _: "?"

def layout_key(layout: CLay.Layout) -> String:
  match layout:
    case CLay.LayoutWord{word}: cat(["w", word_key(word)])
    case CLay.LayoutBox{reason}: cat(["B", box_key(reason)])
    case CLay.LayoutData{words, arms}: cat(["D", Nat.show(List.length(&2, CLay.CWord, words)), ":", arm_keys(arms)])

def box_key(reason: CLay.BoxReason) -> String:
  match reason:
    case CLay.BoxOpen{}: "open"
    case CLay.BoxUnresolved{key}: cat(["unresolved:", key])
    case CLay.BoxArray{}: "array"
    case CLay.BoxIo{}: "io"
    case CLay.BoxRecursive{key}: cat(["rec:", key])
    case CLay.BoxWide{words}: cat(["wide:", Nat.show(words)])

def word_key(word: CLay.CWord) -> String:
  match word:
    case CLay.CWord32{}: "32"
    case CLay.CWord64{}: "64"
    case CLay.CWordBox{}: "x"

def arm_keys(arms: List<&2, CLay.LayArm>) -> String:
  match arms:
    case Nil{}: ""
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key, fields}: cat([key, "/", Nat.show(List.length(&2, CLay.Layout, fields)), ";", arm_keys(rest)])

# ---------------------------------------------------------------------------
# Fact lookups
# ---------------------------------------------------------------------------

def cat(parts: List<&2, String>) -> String:
  String.join(parts, "")

def last_segment(key: String) -> String:
  last_segment_list(String.split(key, '.'), "")

def last_segment_list(parts: List<&2, String>, previous: String) -> String:
  match parts:
    case Nil{}: previous
    case +part <> rest: last_segment_list(rest, part)

def descriptor_head(descriptor: BIR.Descriptor) -> Maybe<&2, String>:
  match descriptor:
    case BIR.DescriptorRef{key, args}: Some{key}
    case BIR.DescriptorApplication{fn, arg}: descriptor_head(fn)
    case BIR.DescriptorFill{head, args}: descriptor_head(head)
    case BIR.DescriptorPlus{head, args}: descriptor_head(head)
    case BIR.DescriptorNamedFill{key, head, args}: descriptor_head(head)
    case BIR.DescriptorNamedPlus{key, head, args}: descriptor_head(head)
    case _: None{}

def descriptor_args(descriptor: BIR.Descriptor) -> List<&2, BIR.Descriptor>:
  match descriptor:
    case BIR.DescriptorRef{key, args}: args
    case _: Nil{}

def family_native(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, String>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{key: owner, name, native, quantity_prefix, arity, arms}:
          m44 = String.eq(owner, key)
          match m44:
            case True{}: native
            case False{}: family_native(key, rest)

def family_arms_of(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{key: owner, name, native, quantity_prefix, arity, arms}:
          m45 = String.eq(owner, key)
          match m45:
            case True{}: Some{arms}
            case False{}: family_arms_of(key, rest)

# Constructor ids are the program's constructor order, which is the CID order.
def cid_index(key: String, constructors: List<&2, BIR.ConstructorLayout>, index: Nat) -> Nat:
  match constructors:
    case Nil{}: 0n
    case +item <> rest:
      match item:
        case BIR.ConstructorLayout{id, key: known, native, fields}:
          m46 = String.eq(known, key)
          match m46:
            case True{}: index
            case False{}: cid_index(key, rest, nat_inc(index))

def field_at(fields: List<&2, BIR.DescriptorField>, ordinal: U32) -> Maybe<&2, BIR.DescriptorField>:
  field_at_each(fields, U32.to_nat(ordinal), 0n)

def field_at_each(fields: List<&2, BIR.DescriptorField>, ordinal: Nat, index: Nat) -> Maybe<&2, BIR.DescriptorField>:
  match fields:
    case Nil{}: None{}
    case +field <> rest:
      m47 = Nat.is_eq(index, ordinal)
      match m47:
        case True{}: Some{field}
        case False{}: field_at_each(rest, ordinal, nat_inc(index))

def arm_layouts(layout: CLay.Layout, key: String) -> Maybe<&2, List<&2, CLay.Layout>>:
  match layout:
    case CLay.LayoutData{words, arms}: arm_layouts_each(arms, key)

def arm_layouts_each(arms: List<&2, CLay.LayArm>, key: String) -> Maybe<&2, List<&2, CLay.Layout>>:
  match arms:
    case Nil{}: None{}
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key: known, fields}:
          m48 = String.eq(known, key)
          match m48:
            case True{}: Some{fields}
            case False{}: arm_layouts_each(rest, key)
