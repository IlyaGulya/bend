# C target layout
# ===============
#
# The physical layout of the C target, computed from Backend IR facts only:
# BIR.Family arms, BIR.TypeFunction bodies and BIR.Descriptor type
# expressions. It reads no syntax tree, no checker environment, no source
# alias, and it never guesses a type from a name suffix: a name that is not a
# declared family is an abstract type, which the authoritative layout rule
# boxes, and a malformed application is a failure, never a guess.
#
# Authority. Every rule below is the rule of the reference C emitter
# (comp.ts, commit a841): lay_of, lay_pack, lay_node, lay_el, val_box,
# val_unbox and show_main. The observations that fix the ABI:
#
#   * A constructor node holds its declared fields' *value* forms, expanded:
#     a field of a nested datatype occupies as many words as that datatype's
#     value layout, not one. comp.ts lays a node as lay_node(ctor), and the
#     CidRow arity is lay_node(ctor).ks.length (comp.ts "cid(c.k,
#     lay_node(c.k).ks.length)"); the generated tables agree (a SpanOf field
#     is three words, Ast.TermVar is five).
#   * A node whose declared field words are none, or exactly one w32, is
#     packed into the term payload (term_pak); every other node is a node.
#   * Value layouts inline at most eight words; past that, and for Array, for
#     IO.OP, for a family that re-enters itself, and for an abstract type,
#     the value is one boxed Term.
#   * A value of a type that is not U32, F32 or Nat is carried boxed: a
#     tagged term when the constructor node is packed (Bool, a nullary enum,
#     Char, Unit, a one-word record), a node otherwise. U32 and F32 are raw
#     32-bit words; Nat is a raw word. This is one Term per value at every
#     callable, closure, foreign and capture boundary, which is why foreign
#     parameters, foreign results and continuations need no conversion: the
#     reference emitter passes every foreign parameter and the continuation
#     as BOX (fun_of), and boxes leaves to their own word.
#   * Storage is not the same as a value: a node word, and an array cell,
#     holds the *laid-out* form of a declared type, so a boxed Bool becomes
#     its tag word and a nested datatype expands. Fill and Unfill are those
#     two conversions, as data the renderer walks; they emit no C text, so
#     every C shape stays in the renderer.
#   * The show descriptor (comp.ts show_main) is written in these same word
#     offsets: a boxed Data reads its arm off a Term, an inline Data reads a
#     leading tag word, and each field offset advances by that field's
#     laid-out word count. A field of type Bool is inline, one tag word.
#
# Erasure. Erased fields have no storage; a projection of one is `Null` in
# BIR already. Descriptor parameters are de Bruijn indices from the applied
# end of the argument list (the descriptor argument order the JS runtime
# uses); a parameter with no bound argument is an unavailable type binder,
# which the authoritative rule boxes (a dependent field, a telescoped value).
#
# Layouts are interned by construction, not by a table: a Lay is a value, and
# two lays of one type are equal word for word. The renderer should memoize
# node_layout by constructor key, which is what makes a whole program's
# layout linear in its type graph; value_layout is only needed where a
# declared type, an array element, or a show descriptor is laid out.
#
# Shared normalizer. Type expressions are normalized by
# bend2/selfhost/descriptor_nf.bend (owner FIRContract; imports Base and
# Backend IR only), never by a second resolver here. This module imports it as
# NF and calls NF.nf through nf_of, which hands it the program's families and
# type functions (NF.nf_context). descriptor_nf keeps its own bounded
# reduction, quantity-prefix insertion, beta/over-application and abstract
# (NfOther/NfMissing) forms; CLay reads only the resulting normal forms and
# consumes full descriptors, never a head classification.
#
# A normal form is read here as:

#   NF.NfType      a named type applied to its arguments (a datatype when the
#                  key is a family with all of them)
#   NF.NfQuantity / NF.NfKind   quantity language, which no layout reads
#   NF.NfOther / NF.NfMissing   an abstract form; it lays out as one box

#
# After the swap Context carries no evaluator state: it is the program's
# families and type functions, which descriptor_nf.nf_context takes.

import Base
import ./descriptor_nf.bend as NF
import ./backend_ir.bend as BIR

# ---------------------------------------------------------------------------
# Physical words and layouts
# ---------------------------------------------------------------------------

# A runtime slot's physical kind: Word32 is a 32-bit payload held in a slot
# (the low 32 bits significant, zero-extended); Word64 is a Nat word; WordBox
# is one Term, whether a tagged pak, a node, a closure or a leaf word.
type CWord is Data:
  CWord32{}
  CWord64{}
  CWordBox{}

# Why the authoritative rule boxes a type instead of laying it out.
type BoxReason is Data:
  BoxOpen{}
  BoxUnresolved{key: String}
  BoxArray{}
  BoxIo{}
  BoxRecursive{key: String}
  BoxWide{words: Nat}

# A laid-out value form. LayoutWord is one raw word; LayoutBox is one Term;
# LayoutData is the ordered words of a datatype value with one arm per
# constructor, each arm's fields in declaration order, the tag word first
# when the type has more than one arm.
type Layout is Data:
  LayoutWord{word: CWord}
  LayoutBox{reason: BoxReason}
  LayoutData{words: List<&2, CWord>, arms: List<&2, LayArm>}

type LayArm is Data:
  LayArm{key: String, fields: List<&2, Layout>}

type LayoutResult is Data:
  LayoutFound{layout: Layout}
  LayoutFailed{message: String}

# A normalized type-expression head: the declared family it names, its native
# marker when the base library gives it a fixed representation, or an honest
# abstract/failure answer. The show builder asks this oracle instead of
# re-deriving a head from raw descriptors. HeadEquality is the kernel's own
# equality former `{a == b : T}`, which is no declared family at all: the
# reference show decides that spelling before it looks at any datatype, so the
# answer has to stay distinct from an abstract head.
type HeadResult is Data:
  HeadFound{key: String, native: Maybe<&2, String>}
  HeadEquality{}
  HeadBoxed{reason: BoxReason}
  HeadFailed{message: String}

# A datatype arm instantiated at an applied type's arguments: every field keeps
# its declared key and quantity, with its descriptor normalized in the applied
# argument environment, so a field that was DescriptorParameter 0 reads as the
# actual argument type.
type FieldsResult is Data:
  FieldsFound{fields: List<&2, BIR.DescriptorField>}
  FieldsFailed{message: String}

# A fully normalized type descriptor, for SHOW memoization: two applications
# of one family with different arguments stay distinct, and aliases of one
# type collapse to the same descriptor. Reducer failure is reported, never
# guessed.
type NormResult is Data:
  NormOk{descriptor: BIR.Descriptor}
  NormFailed{message: String}

# The applied argument list of the normalized head, in BIR form, so a kind-6
# array cell asks for the actual element descriptor instead of reading a raw
# DescriptorRef argument.
type ArgsResult is Data:
  ArgsOk{args: List<&2, BIR.Descriptor>}
  ArgsFailed{message: String}

# One nested conversion: the source run starts at `offset` in the enclosing
# source words, the target run starts at `at` in the enclosing target words.
# `take` reads the source words as a canonical value; `make` writes that
# canonical value into the target words.
type Nest is Data:
  Nest{at: Nat, offset: Nat, take: Unfill, make: Fill}

# Canonical boxed value -> laid-out words.
type Fill is Data:
  FillWord{}
  FillForm{words: Nat, arms: List<&2, FormArm>}

# Laid-out words -> canonical boxed value.
type Unfill is Data:
  UnfillWord{}
  UnfillForm{words: Nat, arms: List<&2, FormArm>}

# One arm of a form. `packed` says the canonical value of this arm is
# term_pak(cid, payload): the source run (Fill) or the target pak (Unfill) is
# the payload, whose width is `node_words`. Otherwise the canonical value is
# a node of `node_words` words. `tag` is the arm's index among the type's
# arms, which is the tag word's value when the type has more than one arm.
type FormArm is Data:
  FormArm{key: String, tag: Nat, packed: Bool, node_words: Nat, fields: List<&2, Nest>}

type FillResult is Data:
  FillFound{fill: Fill}
  FillFailed{message: String}

type UnfillResult is Data:
  UnfillFound{unfill: Unfill}
  UnfillFailed{message: String}

# One declared field slot of a constructor node. `ordinal` is the source
# field ordinal (erased slots included); `offset` is the first node word.
type NodeSlot is Data:
  NodeSlot{ordinal: U32, offset: Nat, layout: Layout}

# The physical node of one constructor: the words of its declared live
# fields, in order, exactly as a foreign C source builds one. `packed` is
# true when `words` is empty or exactly one w32 word: the node is then the
# term payload, term_pak(cid, word), not an allocation.
type Node is Data:
  Node{words: List<&2, CWord>, slots: List<&2, NodeSlot>, packed: Bool}

type NodeResult is Data:
  NodeFound{node: Node}
  NodeFailed{message: String}

type SlotResult is Data:
  SlotFound{slot: NodeSlot}
  SlotErased{}
  SlotFailed{message: String}

# An array cell's layout: the element's laid-out words, whether the block is
# an ARR of Terms (`arr`) or a BUF of packed u32 cells, how many words one
# element takes, and the element-index shift `lgs` (cell offset =
# element index << lgs).
type Cell is Data:
  Cell{layout: Layout, arr: Bool, words: Nat, lgs: Nat}

type CellResult is Data:
  CellFound{cell: Cell}
  CellFailed{message: String}

# ---------------------------------------------------------------------------
# Context
# ---------------------------------------------------------------------------

type Context is Data:
  Context{context: NF.NfContext, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>}

type Plans is Data:
  PlansOk{plans: List<&2, LayArm>}
  PlansFail{message: String}

type Layouts is Data:
  LayoutsOk{layouts: List<&2, Layout>}
  LayoutsFail{message: String}

type Slots is Data:
  SlotsOk{slots: List<&2, NodeSlot>}
  SlotsFail{message: String}

type Arms is Data:
  ArmsOk{arms: List<&2, FormArm>}
  ArmsFail{message: String}

type Nests is Data:
  NestsOk{nests: List<&2, Nest>}
  NestsFail{message: String}

type FormArmResult is Data:
  FormArmOk{plan: FormArm}
  FormArmFail{message: String}


def context(+program: BIR.Program) -> Context:
  match program:
    case BIR.Program{+codes, +declarations, +constructors, +families, +type_functions, +ending}:
      Context{NF.nf_context(families, type_functions), families, type_functions}

def context_nf(+ctx: Context) -> NF.NfContext:
  match ctx:
    case Context{+index, +families, +type_functions}:
      index

def context_families(+ctx: Context) -> List<&2, BIR.Family>:
  match ctx:
    case Context{+index, +families, +type_functions}:
      families

def context_type_functions(+ctx: Context) -> List<&2, BIR.TypeFunction>:
  match ctx:
    case Context{+index, +families, +type_functions}:
      type_functions

def family_lookup(+key: String, +families: List<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  match families:
    case Nil{}:
      None{}
    case +family <> rest:
      match family:
        case BIR.Family{+known, +name, +native, +quantity_prefix, +arity, +arms}:
          match String.eq(key, known):
            case True{}:
              Some{family}
            case False{}:
              family_lookup(key, rest)

def function_lookup(+key: String, +functions: List<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  match functions:
    case Nil{}:
      None{}
    case +function <> rest:
      match function:
        case BIR.TypeFunction{+known, +native, +quantity_prefix, +arity, +body}:
          match String.eq(key, known):
            case True{}:
              Some{function}
            case False{}:
              function_lookup(key, rest)

# ---------------------------------------------------------------------------
# Name lookup: exact canonical keys only
# ---------------------------------------------------------------------------

def arm_of(+key: String, +families: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match families:
    case Nil{}:
      None{}
    case +family <> rest:
      match family:
        case BIR.Family{+owner, +name, +native, +quantity_prefix, +arity, +arms}:
          match arm_in(key, arms):
            case Some{+arm}:
              Some{arm}
            case None{}:
              arm_of(key, rest)

def arm_in(+key: String, +arms: List<&2, BIR.DescriptorArm>) -> Maybe<&2, BIR.DescriptorArm>:
  match arms:
    case Nil{}:
      None{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{+known, +fields}:
          match String.eq(key, known):
            case True{}:
              Some{arm}
            case False{}:
              arm_in(key, rest)

def live_field(+quantity: BIR.Quantity) -> Bool:
  match quantity:
    case BIR.Erased{}:
      False{}
    case _:
      True{}

# The reduction budget for one type expression: the shared normalizer bounds
# every step and reports exhaustion honestly, so a deeper expression turns
# abstract rather than raising any cap.
def layout_fuel() -> Nat:
  1024n

# The shared normalizer, handed this context's type tables.
def nf_of(+ctx: Context, +descriptor: BIR.Descriptor, +env: List<&2, NF.NfVal>, +fuel: Nat) -> NF.Nf:
  NF.nf(context_nf(ctx), descriptor, env, 0n, fuel)

# ---------------------------------------------------------------------------
# Value layouts
# ---------------------------------------------------------------------------

def value_layout(+ctx: Context, +ty: BIR.Descriptor) -> LayoutResult:
  layout_of_desc(ctx, ty, Nil{}, layout_fuel())

def layout_of_desc(+ctx: Context, +descriptor: BIR.Descriptor, +env: List<&2, NF.NfVal>, +fuel: Nat) -> LayoutResult:
  match nf_of(ctx, descriptor, env, fuel):
    case NF.NfFail{+message}:
      LayoutFailed{message}
    case NF.NfOk{+val}:
      layout_of_val(ctx, val, fuel)

def layout_of_val(+ctx: Context, +val: NF.NfVal, +fuel: Nat) -> LayoutResult:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case False{}:
      layout_val(ctx, val, Nat.sub(fuel, 1n))

def layout_val(+ctx: Context, +val: NF.NfVal, +fuel: Nat) -> LayoutResult:
  match val:
    case NF.NfType{+key, +args}:
      match family_lookup(key, context_families(ctx)):
        case Some{+family}:
          layout_family(ctx, family, args, fuel)
        case None{}:
          layout_unresolved(ctx, key)
    case NF.NfCtor{+key, +args}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case NF.NfQuantity{+quantity}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case NF.NfKind{+quantity}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case NF.NfOther{+source}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case NF.NfMissing{+source}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case _:
      LayoutFound{LayoutBox{BoxOpen{}}}

# A name that is neither a family nor a type function is an abstract type
# expression (an opaque checked law such as Chan), which the authoritative
# rule boxes. A name that is a type function under-applied is abstract too.
# The two are kept apart: the first reports the name it could not resolve, so
# a lowering inconsistency is visible in a review, while both lay out as one
# box.
def layout_unresolved(+ctx: Context, +key: String) -> LayoutResult:
  match function_lookup(key, context_type_functions(ctx)):
    case Some{+function}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case None{}:
      LayoutFound{LayoutBox{BoxUnresolved{key}}}

def layout_family(+ctx: Context, +family: BIR.Family, +args: List<&2, NF.NfVal>, +fuel: Nat) -> LayoutResult:
  match family:
    case BIR.Family{+key, +name, +native, +quantity_prefix, +arity, +arms}:
      match Nat.is_eq(List.length(&2, NF.NfVal, args), arity):
        case False{}:
          LayoutFound{LayoutBox{BoxOpen{}}}
        case True{}:
          match native:
            case Some{+marker}:
              layout_native(ctx, marker, key, arms, args, fuel)
            case None{}:
              layout_data(ctx, key, arms, args, fuel)

# Only the base library's word and opaque types have a fixed representation;
# Char, String, Bool and every other Base datatype lay out as declared.
def layout_native(+ctx: Context, +marker: String, +key: String, +arms: List<&2, BIR.DescriptorArm>, +args: List<&2, NF.NfVal>, +fuel: Nat) -> LayoutResult:
  match String.eq(marker, "Nat"):
    case True{}:
      LayoutFound{LayoutWord{CWord64{}}}
    case False{}:
      match String.eq(marker, "U32"):
        case True{}:
          LayoutFound{LayoutWord{CWord32{}}}
        case False{}:
          match String.eq(marker, "F32"):
            case True{}:
              LayoutFound{LayoutWord{CWord32{}}}
            case False{}:
              match String.eq(marker, "Array"):
                case True{}:
                  LayoutFound{LayoutBox{BoxArray{}}}
                case False{}:
                  match String.eq(marker, "IO.OP"):
                    case True{}:
                      LayoutFound{LayoutBox{BoxIo{}}}
                    case False{}:
                      layout_data(ctx, key, arms, args, fuel)

# A constructor's declared field type is written in the scope of the family's
# parameters followed by every field declared before it: the constructor's own
# telescope prefix. `Sigma.Tuple`'s `snd: B(fst)` therefore indexes B at 1 and
# fst at 0, `Map.MNode`'s third field indexes `Map<a, V>` at 2 and 3, and
# `List.Con`'s `tail: List<a, A>` indexes a at 2 and A at 1. A preceding field's
# value is a runtime term, not a type, so one abstract binder stands in for each
# one before the family's own arguments can be read from the end: a field type
# that mentions a preceding field stays abstract, exactly as the reference's
# tele_fill leaves those binders unfilled. Instantiating a field against the
# family's arguments alone would shift every index by the number of preceding
# fields.
def field_scope(+env: List<&2, NF.NfVal>) -> List<&2, NF.NfVal>:
  +absent = {NF.NfMissing{BIR.DescriptorNull{}} : NF.NfVal}
  List.append(&2, NF.NfVal, env, [absent])

# Every arm of a datatype, each with its live declared fields' layouts taken
# at this application's arguments.
def arm_layouts(+ctx: Context, +arms: List<&2, BIR.DescriptorArm>, +args: List<&2, NF.NfVal>, +fuel: Nat, +acc: List<&2, LayArm>) -> Plans:
  match arms:
    case Nil{}:
      PlansOk{List.reverse(&2, LayArm, acc)}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{+key, +fields}:
          match field_layouts(ctx, fields, args, fuel, Nil{}):
            case LayoutsFail{+message}:
              PlansFail{message}
            case LayoutsOk{+layouts}:
              arm_layouts(ctx, rest, args, fuel, LayArm{key, layouts} <> acc)

def field_layouts(+ctx: Context, +fields: List<&2, BIR.DescriptorField>, +env: List<&2, NF.NfVal>, +fuel: Nat, +acc: List<&2, Layout>) -> Layouts:
  match fields:
    case Nil{}:
      LayoutsOk{List.reverse(&2, Layout, acc)}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{+key, +quantity, +ty}:
          # Every declared field, erased or live, is one binder of the scope the
          # next field's type indexes.
          +next = field_scope(env)
          match live_field(quantity):
            case False{}:
              field_layouts(ctx, rest, next, fuel, acc)
            case True{}:
              match layout_of_desc(ctx, ty, env, fuel):
                case LayoutFailed{+message}:
                  LayoutsFail{message}
                case LayoutFound{+layout}:
                  field_layouts(ctx, rest, next, fuel, layout <> acc)

def layout_data(+ctx: Context, +key: String, +arms: List<&2, BIR.DescriptorArm>, +args: List<&2, NF.NfVal>, +fuel: Nat) -> LayoutResult:
  match reenters(ctx, key, arms, args, fuel):
    case True{}:
      LayoutFound{LayoutBox{BoxRecursive{key}}}
    case False{}:
      match arm_layouts(ctx, arms, args, fuel, Nil{}):
        case PlansFail{+message}:
          LayoutFailed{message}
        case PlansOk{+plans}:
          +words = pack_arms(plans, arms_tagged(plans))
          +count = List.length(&2, CWord, words)
          match Nat.is_gt(count, 8n):
            case True{}:
              LayoutFound{LayoutBox{BoxWide{count}}}
            case False{}:
              LayoutFound{LayoutData{words, plans}}

def arms_tagged(+arms: List<&2, LayArm>) -> Bool:
  match arms:
    case Nil{}:
      False{}
    case +only <> Nil{}:
      False{}
    case _:
      True{}

# Whether a field of this family reaches the family again under layout: that
# family's values are then one box. The walk is through live declared fields
# (instantiated with this application's arguments) and through the arguments
# themselves, and a family it has already entered ends the walk.
def reenters(+ctx: Context, +key: String, +arms: List<&2, BIR.DescriptorArm>, +args: List<&2, NF.NfVal>, +fuel: Nat) -> Bool:
  match arms:
    case Nil{}:
      args_reach(ctx, args, key, Nil{}, fuel)
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{+ctor, +fields}:
          match fields_reach(ctx, fields, args, key, Nil{}, fuel):
            case True{}:
              True{}
            case False{}:
              reenters(ctx, key, rest, args, fuel)

def fields_reach(+ctx: Context, +fields: List<&2, BIR.DescriptorField>, +env: List<&2, NF.NfVal>, +target: String, +seen: List<&2, String>, +fuel: Nat) -> Bool:
  match fields:
    case Nil{}:
      False{}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{+key, +quantity, +ty}:
          +next = field_scope(env)
          match live_field(quantity):
            case False{}:
              fields_reach(ctx, rest, next, target, seen, fuel)
            case True{}:
              match reaches(ctx, ty, env, target, seen, fuel):
                case True{}:
                  True{}
                case False{}:
                  fields_reach(ctx, rest, next, target, seen, fuel)

def reaches(+ctx: Context, +ty: BIR.Descriptor, +env: List<&2, NF.NfVal>, +target: String, +seen: List<&2, String>, +fuel: Nat) -> Bool:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      False{}
    case False{}:
      match nf_of(ctx, ty, env, fuel):
        case NF.NfFail{+message}:
          False{}
        case NF.NfOk{+val}:
          reaches_val(ctx, val, target, seen, Nat.sub(fuel, 1n))

def reaches_val(+ctx: Context, +val: NF.NfVal, +target: String, +seen: List<&2, String>, +fuel: Nat) -> Bool:
  match val:
    case NF.NfType{+key, +args}:
      match String.eq(key, target):
        case True{}:
          True{}
        case False{}:
          match str_member(seen, key):
            case True{}:
              False{}
            case False{}:
              match family_lookup(key, context_families(ctx)):
                case None{}:
                  args_reach(ctx, args, target, seen, fuel)
                case Some{+family}:
                  match family_reach(ctx, family, args, target, key <> seen, fuel):
                    case True{}:
                      True{}
                    case False{}:
                      args_reach(ctx, args, target, seen, fuel)
    case _:
      False{}

def family_reach(+ctx: Context, +family: BIR.Family, +args: List<&2, NF.NfVal>, +target: String, +seen: List<&2, String>, +fuel: Nat) -> Bool:
  match family:
    case BIR.Family{+key, +name, +native, +quantity_prefix, +arity, +arms}:
      match Nat.is_eq(List.length(&2, NF.NfVal, args), arity):
        case False{}:
          False{}
        case True{}:
          match native:
            case Some{+marker}:
              match String.eq(marker, "Array"):
                case True{}:
                  False{}
                case False{}:
                  reach_arms(ctx, arms, args, target, seen, fuel)
            case None{}:
              reach_arms(ctx, arms, args, target, seen, fuel)

def reach_arms(+ctx: Context, +arms: List<&2, BIR.DescriptorArm>, +env: List<&2, NF.NfVal>, +target: String, +seen: List<&2, String>, +fuel: Nat) -> Bool:
  match arms:
    case Nil{}:
      False{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{+key, +fields}:
          match fields_reach(ctx, fields, env, target, seen, fuel):
            case True{}:
              True{}
            case False{}:
              reach_arms(ctx, rest, env, target, seen, fuel)

def args_reach(+ctx: Context, +args: List<&2, NF.NfVal>, +target: String, +seen: List<&2, String>, +fuel: Nat) -> Bool:
  match args:
    case Nil{}:
      False{}
    case +arg <> rest:
      match reaches_val(ctx, arg, target, seen, fuel):
        case True{}:
          True{}
        case False{}:
          args_reach(ctx, rest, target, seen, fuel)

def str_member(+items: List<&2, String>, +key: String) -> Bool:
  match items:
    case Nil{}:
      False{}
    case +item <> rest:
      match String.eq(item, key):
        case True{}:
          True{}
        case False{}:
          str_member(rest, key)

# ---------------------------------------------------------------------------
# Word packing
# ---------------------------------------------------------------------------

def layout_kinds(+layout: Layout) -> List<&2, CWord>:
  match layout:
    case LayoutWord{+word}:
      [word]
    case LayoutBox{+reason}:
      [CWordBox{}]
    case LayoutData{+words, +arms}:
      words

def layout_words(+layout: Layout) -> Nat:
  List.length(&2, CWord, layout_kinds(layout))

def canonical_word(+layout: Layout) -> CWord:
  match layout:
    case LayoutWord{+word}:
      word
    case _:
      CWordBox{}

# A field's words merge position by position across a type's arms: a box is
# never narrowed, a w32 is never widened, and a position no arm writes is
# w32. The tag word comes first when there is more than one arm.
def pack_arms(+arms: List<&2, LayArm>, +tag: Bool) -> List<&2, CWord>:
  match tag:
    case True{}:
      pack_arm_list(arms, 1n, [CWord32{}])
    case False{}:
      pack_arm_list(arms, 0n, Nil{})

def pack_arm_list(+arms: List<&2, LayArm>, +at: Nat, +words: List<&2, CWord>) -> List<&2, CWord>:
  match arms:
    case Nil{}:
      words
    case +arm <> rest:
      match arm:
        case LayArm{+key, +fields}:
          pack_arm_list(rest, at, pack_field_list(fields, at, words))

def pack_field_list(+fields: List<&2, Layout>, +at: Nat, +words: List<&2, CWord>) -> List<&2, CWord>:
  match fields:
    case Nil{}:
      words
    case +layout <> rest:
      +kinds = layout_kinds(layout)
      pack_field_list(rest, Nat.add(at, List.length(&2, CWord, kinds)), pack_kinds(kinds, at, words))

def pack_kinds(+kinds: List<&2, CWord>, +at: Nat, +words: List<&2, CWord>) -> List<&2, CWord>:
  match kinds:
    case Nil{}:
      words
    case +kind <> rest:
      pack_kinds(rest, Nat.add(at, 1n), set_kind(words, at, kind))

def set_kind(+words: List<&2, CWord>, +at: Nat, +kind: CWord) -> List<&2, CWord>:
  match words, at:
    case Nil{}, 0n:
      [merge_kind(CWord32{}, kind)]
    case +old <> rest, 0n:
      merge_kind(old, kind) <> rest
    case Nil{}, 1n+prev:
      CWord32{} <> set_kind(Nil{}, prev, kind)
    case +old <> rest, 1n+prev:
      old <> set_kind(rest, prev, kind)

def merge_kind(+old: CWord, +kind: CWord) -> CWord:
  match old:
    case CWordBox{}:
      old
    case _:
      match kind:
        case CWord32{}:
          old
        case _:
          kind

def word_32(+word: CWord) -> Bool:
  match word:
    case CWord32{}:
      True{}
    case _:
      False{}

# A node wider than the runtime's word bound pads to a power of two; every
# narrower node keeps its exact word count.
def pad_words(+words: List<&2, CWord>) -> List<&2, CWord>:
  +count = List.length(&2, CWord, words)
  match Nat.is_gt(count, 247n):
    case False{}:
      words
    case True{}:
      +next = pow2_upto(1n, count)
      match Nat.is_eq(next, count):
        case True{}:
          words
        case False{}:
          pad_to(words, next)

def pad_to(+words: List<&2, CWord>, +target: Nat) -> List<&2, CWord>:
  match Nat.is_eq(List.length(&2, CWord, words), target):
    case True{}:
      words
    case False{}:
      pad_to(List.append(&2, CWord, words, [CWord32{}]), target)

def pow2_upto(+power: Nat, +count: Nat) -> Nat:
  match Nat.is_lt(power, count):
    case True{}:
      pow2_upto(Nat.mul(power, 2n), count)
    case False{}:
      power

def ceil_log2(+count: Nat) -> Nat:
  match Nat.is_gt(count, 1n):
    case False{}:
      0n
    case True{}:
      ceil_log2_go(1n, 0n, count)

def ceil_log2_go(+power: Nat, +shift: Nat, +count: Nat) -> Nat:
  match Nat.is_lt(power, count):
    case True{}:
      match Nat.is_gt(shift, 30n):
        case True{}:
          31n
        case False{}:
          ceil_log2_go(Nat.mul(power, 2n), Nat.add(shift, 1n), count)
    case False{}:
      shift

# ---------------------------------------------------------------------------
# Constructor nodes
# ---------------------------------------------------------------------------

def node_layout(+ctx: Context, +key: String) -> NodeResult:
  node_layout_fuel(ctx, key, layout_fuel())

def node_layout_fuel(+ctx: Context, +key: String, +fuel: Nat) -> NodeResult:
  match arm_of(key, context_families(ctx)):
    case None{}:
      NodeFailed{String.append("the constructor `", String.append(key, "` is in no declared family arm"))}
    case Some{+arm}:
      match arm:
        case BIR.DescriptorArm{+ctor, +fields}:
          match node_slots(ctx, fields, 0, 0n, fuel, Nil{}):
            case SlotsFail{+message}:
              NodeFailed{message}
            case SlotsOk{+slots}:
              node_finish(slots)

def node_slots(+ctx: Context, +fields: List<&2, BIR.DescriptorField>, +ordinal: U32, +offset: Nat, +fuel: Nat, +acc: List<&2, NodeSlot>) -> Slots:
  match fields:
    case Nil{}:
      SlotsOk{List.reverse(&2, NodeSlot, acc)}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{+key, +quantity, +ty}:
          match live_field(quantity):
            case False{}:
              node_slots(ctx, rest, U32.inc(ordinal), offset, fuel, acc)
            case True{}:
              match layout_of_desc(ctx, ty, Nil{}, fuel):
                case LayoutFailed{+message}:
                  SlotsFail{message}
                case LayoutFound{+layout}:
                  +slot = {NodeSlot{ordinal, offset, layout} : NodeSlot}
                  node_slots(ctx, rest, U32.inc(ordinal), Nat.add(offset, layout_words(layout)), fuel, slot <> acc)

def node_finish(+slots: List<&2, NodeSlot>) -> NodeResult:
  match slots:
    case Nil{}:
      NodeFound{Node{Nil{}, Nil{}, True{}}}
    case _:
      +words = pad_words(slot_words(slots))
      NodeFound{Node{words, slots, packed_words(words)}}

def slot_words(+slots: List<&2, NodeSlot>) -> List<&2, CWord>:
  match slots:
    case Nil{}:
      Nil{}
    case +slot <> rest:
      match slot:
        case NodeSlot{+ordinal, +offset, +layout}:
          List.append(&2, CWord, layout_kinds(layout), slot_words(rest))

def packed_words(+words: List<&2, CWord>) -> Bool:
  match words:
    case Nil{}:
      True{}
    case +word <> rest:
      match rest:
        case Nil{}:
          word_32(word)
        case _:
          False{}

def node_slot(+ctx: Context, +key: String, +ordinal: U32) -> SlotResult:
  match node_layout(ctx, key):
    case NodeFailed{+message}:
      SlotFailed{message}
    case NodeFound{+node}:
      match node:
        case Node{+words, +slots, +packed}:
          match slot_find(slots, ordinal):
            case Some{+slot}:
              SlotFound{slot}
            case None{}:
              SlotErased{}

def slot_find(+slots: List<&2, NodeSlot>, +ordinal: U32) -> Maybe<&2, NodeSlot>:
  match slots:
    case Nil{}:
      None{}
    case +slot <> rest:
      match slot:
        case NodeSlot{+known, +offset, +layout}:
          match U32.is_eq(ordinal, known):
            case True{}:
              Some{slot}
            case False{}:
              slot_find(rest, ordinal)

# ---------------------------------------------------------------------------
# Canonical value <-> laid-out words
# ---------------------------------------------------------------------------

def layout_fill(+ctx: Context, +layout: Layout) -> FillResult:
  layout_fill_fuel(ctx, layout, layout_fuel())

def layout_fill_fuel(+ctx: Context, +layout: Layout, +fuel: Nat) -> FillResult:
  match layout:
    case LayoutWord{+word}:
      FillFound{FillWord{}}
    case LayoutBox{+reason}:
      FillFound{FillWord{}}
    case LayoutData{+words, +arms}:
      match form_arms(ctx, arms, 0n, Nat.is_gt(List.length(&2, LayArm, arms), 1n), List.length(&2, CWord, words), fuel, Nil{}, True{}):
        case ArmsFail{+message}:
          FillFailed{message}
        case ArmsOk{+plans}:
          FillFound{FillForm{List.length(&2, CWord, words), plans}}

def layout_unfill(+ctx: Context, +layout: Layout) -> UnfillResult:
  layout_unfill_fuel(ctx, layout, layout_fuel())

def layout_unfill_fuel(+ctx: Context, +layout: Layout, +fuel: Nat) -> UnfillResult:
  match layout:
    case LayoutWord{+word}:
      UnfillFound{UnfillWord{}}
    case LayoutBox{+reason}:
      UnfillFound{UnfillWord{}}
    case LayoutData{+words, +arms}:
      match form_arms(ctx, arms, 0n, Nat.is_gt(List.length(&2, LayArm, arms), 1n), List.length(&2, CWord, words), fuel, Nil{}, False{}):
        case ArmsFail{+message}:
          UnfillFailed{message}
        case ArmsOk{+plans}:
          UnfillFound{UnfillForm{List.length(&2, CWord, words), plans}}

def slot_fill(+ctx: Context, +key: String, +ordinal: U32) -> FillResult:
  match node_slot(ctx, key, ordinal):
    case SlotFound{+slot}:
      match slot:
        case NodeSlot{+at, +offset, +layout}:
          layout_fill(ctx, layout)
    case SlotErased{}:
      FillFailed{String.append("the constructor `", String.append(key, "` field slot is erased and has no storage"))}
    case SlotFailed{+message}:
      FillFailed{message}

def slot_unfill(+ctx: Context, +key: String, +ordinal: U32) -> UnfillResult:
  match node_slot(ctx, key, ordinal):
    case SlotFound{+slot}:
      match slot:
        case NodeSlot{+at, +offset, +layout}:
          layout_unfill(ctx, layout)
    case SlotErased{}:
      UnfillFailed{String.append("the constructor `", String.append(key, "` field slot is erased and has no storage"))}
    case SlotFailed{+message}:
      UnfillFailed{message}

# One arm of a form. `forward` plans a canonical value into the laid-out
# words; the other direction plans the laid-out words back into the canonical
# value. `word_count` is the laid-out word count, which is also the number of
# source words in the other direction.
def form_arms(+ctx: Context, +arms: List<&2, LayArm>, +tag: Nat, +tagged: Bool, +word_count: Nat, +fuel: Nat, +acc: List<&2, FormArm>, +forward: Bool) -> Arms:
  match arms:
    case Nil{}:
      ArmsOk{List.reverse(&2, FormArm, acc)}
    case +arm <> rest:
      match arm:
        case LayArm{+key, +fields}:
          match form_arm(ctx, key, tag, tagged, word_count, fields, fuel, forward):
            case FormArmFail{+message}:
              ArmsFail{message}
            case FormArmOk{+plan}:
              form_arms(ctx, rest, Nat.add(tag, 1n), tagged, word_count, fuel, plan <> acc, forward)

def form_arm(+ctx: Context, +key: String, +tag: Nat, +tagged: Bool, +word_count: Nat, +fields: List<&2, Layout>, +fuel: Nat, +forward: Bool) -> FormArmResult:
  match node_layout_fuel(ctx, key, fuel):
    case NodeFailed{+message}:
      FormArmFail{message}
    case NodeFound{+node}:
      match node:
        case Node{+words, +slots, +packed}:
          +first = tag_word(tagged)
          match form_nests(ctx, fields, slots, first, word_count, List.length(&2, CWord, words), fuel, Nil{}, forward):
            case NestsFail{+message}:
              FormArmFail{message}
            case NestsOk{+nests}:
              FormArmOk{FormArm{key, tag, packed, List.length(&2, CWord, words), nests}}

def tag_word(+tagged: Bool) -> Nat:
  match tagged:
    case True{}:
      1n
    case False{}:
      0n

def form_nests(+ctx: Context, +fields: List<&2, Layout>, +slots: List<&2, NodeSlot>, +at: Nat, +word_count: Nat, +node_words: Nat, +fuel: Nat, +acc: List<&2, Nest>, +forward: Bool) -> Nests:
  match fields, slots:
    case Nil{}, Nil{}:
      NestsOk{List.reverse(&2, Nest, acc)}
    case +layout <> frest, +slot <> srest:
      match slot:
        case NodeSlot{+ordinal, +offset, +slot_layout}:
          match forward:
            case True{}:
              # The canonical value's node field (slot_layout) is the source;
              # the slot's own field layout (layout) is the target.
              match layout_unfill_fuel(ctx, slot_layout, fuel):
                case UnfillFailed{+message}:
                  NestsFail{message}
                case UnfillFound{+take}:
                  match layout_fill_fuel(ctx, layout, fuel):
                    case FillFailed{+message}:
                      NestsFail{message}
                    case FillFound{+make}:
                      match nest_fits(at, word_count, offset, node_words, take, make):
                        case False{}:
                          NestsFail("the constructor node does not fit its value layout")
                        case True{}:
                          form_nests(ctx, frest, srest, Nat.add(at, fill_words(make)), word_count, node_words, fuel, nest(at, offset, take, make) <> acc, forward)
            case False{}:
              # The slot's field layout (layout) is the source; the canonical
              # value's node field (slot_layout) is the target.
              match layout_unfill_fuel(ctx, layout, fuel):
                case UnfillFailed{+message}:
                  NestsFail{message}
                case UnfillFound{+take}:
                  match layout_fill_fuel(ctx, slot_layout, fuel):
                    case FillFailed{+message}:
                      NestsFail{message}
                    case FillFound{+make}:
                      match nest_fits(offset, node_words, at, word_count, take, make):
                        case False{}:
                          NestsFail("the constructor node does not fit its value layout")
                        case True{}:
                          form_nests(ctx, frest, srest, Nat.add(at, unfill_words(take)), word_count, node_words, fuel, nest(offset, at, take, make) <> acc, forward)
    case _, _:
      NestsFail("a constructor node and its value layout disagree on the live field count")

def nest(+at: Nat, +offset: Nat, +take: Unfill, +make: Fill) -> Nest:
  Nest{at, offset, take, make}

# The source run at `offset` must fit `source_limit` words and the target run
# at `at` must fit `target_limit`.
def nest_fits(+at: Nat, +target_limit: Nat, +offset: Nat, +source_limit: Nat, +take: Unfill, +make: Fill) -> Bool:
  match Nat.is_gt(Nat.add(at, fill_words(make)), target_limit):
    case True{}:
      False{}
    case False{}:
      match Nat.is_gt(Nat.add(offset, unfill_words(take)), source_limit):
        case True{}:
          False{}
        case False{}:
          True{}

def fill_words(+fill: Fill) -> Nat:
  match fill:
    case FillWord{}:
      1n
    case FillForm{+words, +arms}:
      words

def unfill_words(+unfill: Unfill) -> Nat:
  match unfill:
    case UnfillWord{}:
      1n
    case UnfillForm{+words, +arms}:
      words

# ---------------------------------------------------------------------------
# Show metadata: normalized heads and instantiated arm fields
# ---------------------------------------------------------------------------

def head_native(+ctx: Context, +ty: BIR.Descriptor) -> HeadResult:
  match nf_of(ctx, ty, Nil{}, 1024n):
    case NF.NfFail{+message}:
      HeadFailed{message}
    case NF.NfOk{+val}:
      head_value(ctx, val)

# The equality former is the one type form the show builder may print without a
# declared family: comp.show_main assigns kind 5 to a whnf of that shape and the
# runtime prints `{==}` for that kind alone. Every other non-family form stays
# the honest abstract answer.
def head_other(+source: BIR.Descriptor) -> HeadResult:
  match source:
    case BIR.DescriptorEquality{_, _, _}: HeadEquality{}
    case _: HeadBoxed{BoxOpen{}}

def head_value(+ctx: Context, +val: NF.NfVal) -> HeadResult:
  match val:
    case NF.NfType{+key, +args}:
      match family_lookup(key, context_families(ctx)):
        case Some{+family}:
          match family:
            case BIR.Family{+known, +name, +native, +quantity_prefix, +arity, +arms}:
              match Nat.is_eq(List.length(&2, NF.NfVal, args), arity):
                case True{}:
                  HeadFound{key, native}
                case False{}:
                  HeadBoxed{BoxOpen{}}
        case None{}:
          match function_lookup(key, context_type_functions(ctx)):
            case Some{+function}:
              match function:
                case BIR.TypeFunction{+known, +native, +quantity_prefix, +arity, +body}:
                  match native:
                    case Some{+marker}:
                      match Nat.is_eq(List.length(&2, NF.NfVal, args), arity):
                        case True{}:
                          HeadFound{key, native}
                        case False{}:
                          HeadBoxed{BoxOpen{}}
                    case None{}:
                      HeadBoxed{BoxOpen{}}
            case None{}:
              HeadBoxed{BoxUnresolved{key}}
    case NF.NfOther{+source}:
      head_other(source)
    case _:
      HeadBoxed{BoxOpen{}}

def norm(+ctx: Context, +ty: BIR.Descriptor) -> NormResult:
  match NF.normalize(context_nf(ctx), ty, Nil{}, 1024n):
    case BIR.DescriptorFailure{+message}:
      NormFailed{message}
    case +descriptor:
      NormOk{descriptor}

def head_args(+ctx: Context, +ty: BIR.Descriptor) -> ArgsResult:
  match nf_of(ctx, ty, Nil{}, 1024n):
    case NF.NfFail{+message}:
      ArgsFailed{message}
    case NF.NfOk{+val}:
      match val:
        case NF.NfType{+key, +args}:
          ArgsOk{NF.materialize_all(args)}
        case _:
          ArgsFailed{"the applied type is not a named family application"}

def arm_fields(+ctx: Context, +ctor: String, +ty: BIR.Descriptor) -> FieldsResult:
  match nf_of(ctx, ty, Nil{}, 1024n):
    case NF.NfFail{+message}:
      FieldsFailed{message}
    case NF.NfOk{+val}:
      arm_fields_value(ctx, ctor, val)

def arm_fields_value(+ctx: Context, +ctor: String, +val: NF.NfVal) -> FieldsResult:
  match val:
    case NF.NfType{+key, +args}:
      match arm_of(ctor, context_families(ctx)):
        case None{}:
          FieldsFailed{String.append("the constructor `", String.append(ctor, "` is in no declared family arm"))}
        case Some{+arm}:
          match arm:
            case BIR.DescriptorArm{+known, +fields}:
              instantiate_fields(ctx, args, fields, Nil{})
    case _:
      FieldsFailed{"the applied type is not a named family application"}

def instantiate_fields(+ctx: Context, +args: List<&2, NF.NfVal>, +fields: List<&2, BIR.DescriptorField>, +acc: List<&2, BIR.DescriptorField>) -> FieldsResult:
  match fields:
    case Nil{}:
      FieldsFound{List.reverse(&2, BIR.DescriptorField, acc)}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{+key, +quantity, +ty}:
          +next = field_scope(args)
          +substituted = {BIR.DescriptorField{key, quantity, NF.normalize(context_nf(ctx), ty, args, 1024n)} : BIR.DescriptorField}
          instantiate_fields(ctx, next, rest, substituted <> acc)

# ---------------------------------------------------------------------------
# Array cells
# ---------------------------------------------------------------------------

def array_cell(+ctx: Context, +element: BIR.Descriptor) -> CellResult:
  match value_layout(ctx, element):
    case LayoutFailed{+message}:
      CellFailed{message}
    case LayoutFound{+layout}:
      cell_of(layout)

def cell_of(+layout: Layout) -> CellResult:
  match layout:
    case LayoutBox{+reason}:
      cell_boxed(reason)
    case _:
      +words = layout_words(layout)
      CellFound{Cell{layout, layout_has_term(layout), words, ceil_log2(max_one(words))}}

# An array of an open or generic element type is an array of boxed Terms, as in
# the reference lay_arr: the element is one BOX word held in an ARR cell (arr =
# true, words = 1, lgs = 0). Openness selects representation, it never refuses.
def cell_boxed(+reason: BoxReason) -> CellResult:
  CellFound{Cell{LayoutBox{reason}, True{}, 1n, 0n}}

def max_one(+count: Nat) -> Nat:
  match Nat.is_gt(count, 0n):
    case True{}:
      count
    case False{}:
      1n

# A block is an ARR of Term cells when any element word is not a u32; a BUF
# of packed u32 cells otherwise.
def layout_has_term(+layout: Layout) -> Bool:
  match layout:
    case LayoutWord{+word}:
      word_has_term(word)
    case LayoutBox{+reason}:
      True{}
    case LayoutData{+words, +arms}:
      any_word_has_term(words)

def word_has_term(+word: CWord) -> Bool:
  match word:
    case CWord32{}:
      False{}
    case _:
      True{}

def any_word_has_term(+words: List<&2, CWord>) -> Bool:
  match words:
    case Nil{}:
      False{}
    case +word <> rest:
      match word_has_term(word):
        case True{}:
          True{}
        case False{}:
          any_word_has_term(rest)
