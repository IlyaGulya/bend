# C target physical emission
# ===========================
#
# SHOW_DESC/SHOW_NAMES construction for the C backend, from the frozen layout
# oracle (c_backend_layout.bend) and Backend IR facts only. It owns no segment,
# call or table emission (CIRControl) and never re-derives a layout from a key
# spelling.
#
# Authority: comp.ts show_main. Reproduced rules:
#   * kind = index of the datatype in U32 F32 Nat Char String . Array & 7
#     (Eql is 5), everything else 7;
#   * Char pushes its box flag; Array pushes [element cell, lgs]; Data pushes
#     [box, arm count] then per arm [name index, cid, live field count,
#     bracket] (Tuple 2, Con/Nil 1, else 0) then per field [offset, cell];
#   * box = 1 iff the value layout is a box; offsets start at the tag word
#     (!box && arms > 1) and advance by the field layout's word count;
#   * a zero-word root layout is a box;
#   * a cell is memoized on (type key, layout key) BEFORE recursing, which is
#     what terminates a recursive datatype. Because an id is reserved before a
#     child is built, nested references are plain ids and no fixup is needed.
#
# The module is self-contained so it can be merged into c_backend.bend after
# the control layer lands: every function takes the CLay context explicitly.
# Entry point: show_build(ctx, main_type, constructors, families).text is the
# SHOW_DESC initializer and show_names(constructors) is the SHOW_NAMES one.

import Base
import ./backend_ir.bend as BIR
import ./c_backend_layout.bend as CLay

type ShowState is Data:
  ShowState{cells: Map<&2, String>, memo: Map<&2, Nat>, next: Nat}

# ok false carries the diagnostic; no partially built state is ever used.
type Step is Data:
  Step{ok: Bool, message: String, text: String, id: Nat, state: ShowState}

def nat_inc(value: Nat) -> Nat:
  Nat.add(value, 1n)

def step_fail(message: String, st: ShowState) -> Step:
  Step{False{}, message, "", 0n, st}

def show_build(ctx: CLay.Context, main_type: BIR.Descriptor, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>) -> Step:
  match CLay.value_layout(ctx, main_type):
    case CLay.LayoutFailed{message}: step_fail(message, ShowState{Map.new(&2, String), Map.new(&2, Nat), 0n})
    case CLay.LayoutFound{layout}:
      root = root_layout(layout)
      start = ShowState{Map.new(&2, String), Map.new(&2, Nat), 0n}
      match show_node(ctx, main_type, root, families, constructors, start):
        case Step{ok, message, text, id, state}:
          match ok:
            case True{}: show_finish(state, constructors)
            case False{}: step_fail(message, state)

def root_layout(layout: CLay.Layout) -> CLay.Layout:
  match CLay.layout_words(layout):
    case 0n: CLay.LayoutBox{CLay.BoxWide{0n}}
    case _: layout

def show_finish(st: ShowState, constructors: List<&2, BIR.ConstructorLayout>) -> Step:
  match st:
    case ShowState{cells, memo, next}:
      Step{True{}, "", show_join(0n, next, cells), 0n, ShowState{cells, memo, next}}

def show_join(index: Nat, count: Nat, cells: Map<&2, String>) -> String:
  match Nat.is_lt(index, count):
    case True{}:
      match IndexLookup.find(String, cells, Nat.show(index)):
        case None{}: cat([", 0", show_join(Nat.add(index, 1n), count, cells)])
        case Some{text}: cat([", ", text, show_join(Nat.add(index, 1n), count, cells)])
    case False{}: ""

# ---------------------------------------------------------------------------
# Cells
# ---------------------------------------------------------------------------

def show_node(ctx: CLay.Context, ty: BIR.Descriptor, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState) -> Step:
  key = show_key(ty, layout)
  match IndexLookup.find(Nat, memo_of(st), key):
    case Some{id}: Step{True{}, "", "", id, st}
    case None{}:
      id = next_of(st)
      reserved = reserve(st, key, id)
      match show_cell(ctx, ty, layout, families, constructors, reserved, id):
        case Step{ok, message, text, id, state}:
          match ok:
            case True{}: Step{True{}, "", "", id, put_cell(state, id, text)}
            case False{}: step_fail(message, state)

def memo_of(st: ShowState) -> Map<&2, Nat>:
  match st:
    case ShowState{cells, memo, next}: memo

def next_of(st: ShowState) -> Nat:
  match st:
    case ShowState{cells, memo, next}: next

def cells_of(st: ShowState) -> Map<&2, String>:
  match st:
    case ShowState{cells, memo, next}: cells

def reserve(st: ShowState, key: String, id: Nat) -> ShowState:
  ShowState{cells_of(st), Map.set(&2, Nat, memo_of(st), key, id), nat_inc(next_of(st))}

def put_cell(st: ShowState, id: Nat, text: String) -> ShowState:
  ShowState{Map.set(&2, String, cells_of(st), Nat.show(id), text), memo_of(st), next_of(st)}

def show_cell(ctx: CLay.Context, ty: BIR.Descriptor, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, id: Nat) -> Step:
  match show_kind(ty, families):
    case 5n: Step{True{}, "", "5", id, st}
    case 0n: Step{True{}, "", "0", id, st}
    case 1n: Step{True{}, "", "1", id, st}
    case 2n: Step{True{}, "", "2", id, st}
    case 3n: Step{True{}, "", cat([num(3n), ",", num(box_flag(layout))]), id, st}
    case 4n: Step{True{}, "", "4", id, st}
    case 6n: show_array_cell(ctx, ty, families, constructors, st, id)
    case _: show_data_cell(ctx, ty, layout, families, constructors, st, id)

def box_flag(layout: CLay.Layout) -> Nat:
  match layout:
    case CLay.LayoutBox{reason}: 1n
    case _: 0n

def show_kind(ty: BIR.Descriptor, families: List<&2, BIR.Family>) -> Nat:
  match descriptor_head(ty):
    case None{}: 7n
    case Some{key}:
      match family_native(key, families):
        case Some{tag}: native_kind(tag)
        case None{}: 7n

def native_kind(native: String) -> Nat:
  match last_segment(native):
    case "U32": 0n
    case "F32": 1n
    case "Nat": 2n
    case "Char": 3n
    case "String": 4n
    case "Eql": 5n
    case "Array": 6n
    case _: 7n

def show_array_cell(ctx: CLay.Context, ty: BIR.Descriptor, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, id: Nat) -> Step:
  match descriptor_args(ty):
    case +element <> rest:
      match CLay.array_cell(ctx, element):
        case CLay.CellFailed{message}: step_fail(message, st)
        case CLay.CellFound{cell}:
          match cell:
            case CLay.Cell{layout, arr, words, lgs}:
              match CLay.value_layout(ctx, element):
                case CLay.LayoutFailed{message}: step_fail(message, st)
                case CLay.LayoutFound{layout: element_layout}:
                  match show_node(ctx, element, element_layout, families, constructors, st):
                    case Step{ok, message, text, element_id, state}:
                      match ok:
                        case True{}: Step{True{}, "", cat([num(6n), ",", num(element_id), ",", num(lgs)]), id, state}
                        case False{}: step_fail(message, state)
    case Nil{}: step_fail("an Array descriptor without an element type cannot be printed", st)

def show_data_cell(ctx: CLay.Context, ty: BIR.Descriptor, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, id: Nat) -> Step:
  match descriptor_head(ty):
    case None{}: step_fail("a datatype without a key cannot be printed", st)
    case Some{key}:
      match family_arms_of(key, families):
        case None{}: step_fail(cat(["the datatype `", key, "` has no constructors"]), st)
        case Some{arms}:
          box = box_flag(layout)
          count = List.length(&2, BIR.DescriptorArm, arms)
          head = cat([num(7n), ",", num(box), ",", num(count)])
          match show_arms(ctx, arms, layout, box, count, families, constructors, st, head, 0n):
            case Step{ok, message, text, arm_id, state}:
              match ok:
                case True{}: Step{True{}, "", text, id, state}
                case False{}: step_fail(message, state)

def show_arms(ctx: CLay.Context, arms: List<&2, BIR.DescriptorArm>, layout: CLay.Layout, box: Nat, count: Nat, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, acc: String, name_index: Nat) -> Step:
  match arms:
    case Nil{}: Step{True{}, "", acc, 0n, st}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key, fields}:
          head = cat([",", num(name_index), ",", cid_of(key, constructors), ",", num(live_count(fields)), ",", num(arm_bracket(key))])
          match show_arm_fields(ctx, key, fields, layout, box, count, families, constructors, st, head, tag_start(box, count)):
            case Step{ok, message, text, arm_id, state}:
              match ok:
                case True{}: show_arms(ctx, rest, layout, box, count, families, constructors, state, cat([acc, text]), nat_inc(name_index))
                case False{}: step_fail(message, state)

def arm_bracket(key: String) -> Nat:
  match last_segment(key):
    case "Tuple": 2n
    case "Con": 1n
    case "Nil": 1n
    case _: 0n

def tag_start(box: Nat, count: Nat) -> Nat:
  match box:
    case 1n: 0n
    case _:
      match Nat.is_gt(count, 1n):
        case True{}: 1n
        case False{}: 0n

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

def show_arm_fields(ctx: CLay.Context, key: String, fields: List<&2, BIR.DescriptorField>, layout: CLay.Layout, box: Nat, count: Nat, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, acc: String, at: Nat) -> Step:
  match box:
    case 1n: show_slots(ctx, key, fields, families, constructors, st, acc, 0n)
    case _: show_inline(ctx, key, live_fields(fields, Nil{}), layout, families, constructors, st, acc, at)

def show_slots(ctx: CLay.Context, key: String, fields: List<&2, BIR.DescriptorField>, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, acc: String, index: Nat) -> Step:
  match CLay.node_layout(ctx, key):
    case CLay.NodeFailed{message}: step_fail(message, st)
    case CLay.NodeFound{node}:
      match node:
        case CLay.Node{words, slots, packed}: show_slot_each(ctx, slots, fields, families, constructors, st, acc)

def show_slot_each(ctx: CLay.Context, slots: List<&2, CLay.NodeSlot>, fields: List<&2, BIR.DescriptorField>, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, acc: String) -> Step:
  match slots:
    case Nil{}: Step{True{}, "", acc, 0n, st}
    case +slot <> rest:
      match slot:
        case CLay.NodeSlot{ordinal, offset, layout}:
          match field_at(fields, ordinal):
            case None{}: step_fail("a constructor node slot names no live field", st)
            case Some{field}:
              match field:
                case BIR.DescriptorField{key, quantity, ty}:
                  match show_node(ctx, ty, layout, families, constructors, st):
                    case Step{ok, message, text, field_id, state}:
                      match ok:
                        case True{}: show_slot_each(ctx, rest, fields, families, constructors, state, cat([acc, ",", num(offset), ",", num(field_id)]))
                        case False{}: step_fail(message, state)

def show_inline(ctx: CLay.Context, key: String, fields: List<&2, BIR.DescriptorField>, layout: CLay.Layout, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, acc: String, at: Nat) -> Step:
  match arm_layouts(layout, key):
    case None{}: step_fail(cat(["the inline layout has no arm `", key, "`"]), st)
    case Some{layouts}: show_inline_each(ctx, fields, layouts, families, constructors, st, acc, at)

def show_inline_each(ctx: CLay.Context, fields: List<&2, BIR.DescriptorField>, layouts: List<&2, CLay.Layout>, families: List<&2, BIR.Family>, constructors: List<&2, BIR.ConstructorLayout>, st: ShowState, acc: String, at: Nat) -> Step:
  match fields layouts:
    case Nil{} _: Step{True{}, "", acc, 0n, st}
    case +field <> rest +layout <> rest_layouts:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match show_node(ctx, ty, layout, families, constructors, st):
            case Step{ok, message, text, field_id, state}:
              match ok:
                case True{}: show_inline_each(ctx, rest, rest_layouts, families, constructors, state, cat([acc, ",", num(at), ",", num(field_id)]), Nat.add(at, CLay.layout_words(layout)))
                case False{}: step_fail(message, state)
    case _ _: step_fail("an inline arm's fields and layouts differ in length", st)

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
    case CLay.LayoutBox{reason}: "B"
    case CLay.LayoutData{words, arms}: cat(["D", Nat.show(List.length(&2, CLay.CWord, words)), ":", arm_keys(arms)])

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

def num(value: Nat) -> String:
  Nat.show(value)

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
          match String.eq(owner, key):
            case True{}: native
            case False{}: family_native(key, rest)

def family_arms_of(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{key: owner, name, native, quantity_prefix, arity, arms}:
          match String.eq(owner, key):
            case True{}: Some{arms}
            case False{}: family_arms_of(key, rest)

# Constructor ids are the program's constructor order (comp.ts registers cids in
# source order); the module exposes the number so the caller can prefix CID_.
def cid_of(key: String, constructors: List<&2, BIR.ConstructorLayout>) -> String:
  cat(["CID_", cid_index(key, constructors, 0n)])

def cid_index(key: String, constructors: List<&2, BIR.ConstructorLayout>, index: Nat) -> String:
  match constructors:
    case Nil{}: "0"
    case +item <> rest:
      match item:
        case BIR.ConstructorLayout{id, key: known, native, fields}:
          match String.eq(known, key):
            case True{}: Nat.show(index)
            case False{}: cid_index(key, rest, nat_inc(index))

def field_at(fields: List<&2, BIR.DescriptorField>, ordinal: U32) -> Maybe<&2, BIR.DescriptorField>:
  field_at_each(fields, U32.to_nat(ordinal), 0n)

def field_at_each(fields: List<&2, BIR.DescriptorField>, ordinal: Nat, index: Nat) -> Maybe<&2, BIR.DescriptorField>:
  match fields:
    case Nil{}: None{}
    case +field <> rest:
      match Nat.is_eq(index, ordinal):
        case True{}: Some{field}
        case False{}: field_at_each(rest, ordinal, nat_inc(index))

def arm_layouts(layout: CLay.Layout, key: String) -> Maybe<&2, List<&2, CLay.Layout>>:
  match layout:
    case CLay.LayoutData{words, arms}: arm_layouts_each(arms, key)
    case _: None{}

def arm_layouts_each(arms: List<&2, CLay.LayArm>, key: String) -> Maybe<&2, List<&2, CLay.Layout>>:
  match arms:
    case Nil{}: None{}
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key: known, fields}:
          match String.eq(known, key):
            case True{}: Some{fields}
            case False{}: arm_layouts_each(rest, key)
