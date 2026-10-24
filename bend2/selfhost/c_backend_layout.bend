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
# Shared normalizer. The "Type expressions" section below is the target-
# neutral evaluator that is being extracted into bend2/selfhost/descriptor_nf.bend
# (owner FIRContract; imports Base + backend_ir only). It is frozen here until
# that module lands: no further edits to that section. The names map one to
# one, so the swap is an import plus a delete:
#
#   Val      -> NfVal          (NfType, NfCtor, NfQuantity, NfKind, NfOther, NfMissing)
#   Evals    -> Nf             (EvalsOk -> NfOk, EvalsFail -> NfFail)
#   Vals     -> NfList         (ValsOk -> NfListOk, ValsFail -> NfListFail)
#   eval_desc(ctx, d, env, f)  -> nf(context, d, env, f)
#   named -> nf_named, apply_val -> nf_apply_one, apply_vals -> nf_apply,
#   eval_apply_args -> nf_apply_args, family_value -> nf_family,
#   reduce_function -> nf_reduce, reduce_body -> nf_reduce_body,
#   eval_cases -> nf_cases, quantity_markers/val_at/val_nth/first_vals/
#   drop_vals/insert_before/bind_patterns keep their names.
#
# After the swap Context carries no evaluator state: it is the program's
# families and type functions, which descriptor_nf.nf_context takes.

import Base
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
  Context{families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>}

def context(program: BIR.Program) -> Context:
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, ending}:
      Context{families, type_functions}

# ---------------------------------------------------------------------------
# Name lookup: exact canonical keys only
# ---------------------------------------------------------------------------

def family_of(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  match families:
    case Nil{}:
      None{}
    case +family <> rest:
      match family:
        case BIR.Family{known, name, native, quantity_prefix, arity, arms}:
          match String.eq(key, known):
            case True{}:
              Some{family}
            case False{}:
              family_of(key, rest)

def function_of(key: String, functions: List<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  match functions:
    case Nil{}:
      None{}
    case +function <> rest:
      match function:
        case BIR.TypeFunction{known, native, quantity_prefix, arity, body}:
          match String.eq(key, known):
            case True{}:
              Some{function}
            case False{}:
              function_of(key, rest)

def arm_of(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match families:
    case Nil{}:
      None{}
    case +family <> rest:
      match family:
        case BIR.Family{owner, name, native, quantity_prefix, arity, arms}:
          match arm_in(key, arms):
            case Some{arm}:
              Some{arm}
            case None{}:
              arm_of(key, rest)

def arm_in(key: String, arms: List<&2, BIR.DescriptorArm>) -> Maybe<&2, BIR.DescriptorArm>:
  match arms:
    case Nil{}:
      None{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{known, fields}:
          match String.eq(key, known):
            case True{}:
              Some{arm}
            case False{}:
              arm_in(key, rest)

def live_field(quantity: BIR.Quantity) -> Bool:
  match quantity:
    case BIR.Erased{}:
      False{}
    case _:
      True{}

# ---------------------------------------------------------------------------
# Type expressions
# ---------------------------------------------------------------------------

# A normalized type expression. ValType is a named type applied to the
# arguments it has so far; ValCtor is a value constructor applied to values,
# which a type-level match may inspect; ValQuantity and ValKind are the
# quantity and kind language, which no layout inspects; ValOther is any other
# term, including a function, a proof and a hole; ValMissing is a binder with
# no value in scope.
type Val is Data:
  ValType{key: String, args: List<&2, Val>}
  ValCtor{key: String, args: List<&2, Val>}
  ValQuantity{quantity: BIR.Quantity}
  ValKind{quantity: Val}
  ValOther{}
  ValMissing{}

type Evals is Data:
  EvalsOk{val: Val}
  EvalsFail{message: String}

type Vals is Data:
  ValsOk{vals: List<&2, Val>}
  ValsFail{message: String}

# A normalized type expression that need not reduce to a datatype is
# abstract, and the layout boxes it; only a descriptor that names nothing at
# all is no type expression, and that fails the build.
def fuel() -> Nat:
  1024n

def eval_desc(ctx: Context, descriptor: BIR.Descriptor, env: List<&2, Val>, fuel: Nat) -> Evals:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      EvalsOk{ValOther{}}
    case False{}:
      eval_descriptor(ctx, descriptor, env, Nat.sub(fuel, 1n))

def eval_descriptor(ctx: Context, descriptor: BIR.Descriptor, env: List<&2, Val>, fuel: Nat) -> Evals:
  match descriptor:
    case BIR.DescriptorNull{}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorParameter{index}:
      EvalsOk{val_at(env, index)}
    case BIR.DescriptorQuantityKind{}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorQuantity{quantity}:
      EvalsOk{ValQuantity{quantity}}
    case BIR.DescriptorKind{quantity}:
      match eval_desc(ctx, quantity, env, fuel):
        case EvalsOk{val}:
          EvalsOk{ValKind{val}}
        case EvalsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorMinimum{left, right}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorArrow{use, domain, body}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorLambda{use, body}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorRef{key, args}:
      match eval_all(ctx, args, env, fuel):
        case ValsOk{vals}:
          named(ctx, key, vals, fuel)
        case ValsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorConstructor{key, args}:
      match eval_all(ctx, args, env, fuel):
        case ValsOk{vals}:
          EvalsOk{ValCtor{key, vals}}
        case ValsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorApplication{fn, arg}:
      match eval_desc(ctx, fn, env, fuel):
        case EvalsOk{val}:
          match eval_desc(ctx, arg, env, fuel):
            case EvalsOk{argument}:
              apply_val(ctx, val, argument, fuel)
            case EvalsFail{message}:
              EvalsFail{message}
        case EvalsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorSubstitution{index, value, body}:
      match eval_desc(ctx, value, env, fuel):
        case EvalsOk{val}:
          eval_desc(ctx, body, insert_before(env, Nat.sub(List.length(&2, Val, env), index), val), fuel)
        case EvalsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorLet{values, body}:
      match eval_all(ctx, values, env, fuel):
        case ValsOk{vals}:
          eval_desc(ctx, body, List.append(&2, Val, env, vals), fuel)
        case ValsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorLocal{patterns, values, body}:
      match eval_all(ctx, values, env, fuel):
        case ValsOk{vals}:
          match bind_patterns(patterns, vals, fuel):
            case Some{bindings}:
              eval_desc(ctx, body, List.append(&2, Val, env, bindings), fuel)
            case None{}:
              EvalsOk{ValOther{}}
        case ValsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorMatch{values, cases}:
      match eval_all(ctx, values, env, fuel):
        case ValsOk{vals}:
          eval_cases(ctx, cases, vals, env, fuel)
        case ValsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorCase{patterns, body}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorBind{value, body}:
      match eval_desc(ctx, value, env, fuel):
        case EvalsOk{val}:
          eval_desc(ctx, body, List.append(&2, Val, env, [val]), fuel)
        case EvalsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorEquality{left, right, ty}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorReflexivity{}:
      EvalsOk{ValOther{}}
    case BIR.DescriptorFailure{message}:
      EvalsFail{message}
    case BIR.DescriptorFill{head, args}:
      eval_apply_args(ctx, head, args, env, fuel)
    case BIR.DescriptorPlus{head, args}:
      eval_apply_args(ctx, head, args, env, fuel)
    case BIR.DescriptorNamedFill{key, head, args}:
      match eval_all(ctx, args, env, fuel):
        case ValsOk{vals}:
          named(ctx, key, vals, fuel)
        case ValsFail{message}:
          EvalsFail{message}
    case BIR.DescriptorNamedPlus{key, head, args}:
      match eval_all(ctx, args, env, fuel):
        case ValsOk{vals}:
          named(ctx, key, vals, fuel)
        case ValsFail{message}:
          EvalsFail{message}

def eval_all(ctx: Context, descriptors: List<&2, BIR.Descriptor>, env: List<&2, Val>, fuel: Nat) -> Vals:
  match descriptors:
    case Nil{}:
      ValsOk{Nil{}}
    case +descriptor <> rest:
      match eval_desc(ctx, descriptor, env, fuel):
        case EvalsFail{message}:
          ValsFail{message}
        case EvalsOk{val}:
          match eval_all(ctx, rest, env, fuel):
            case ValsFail{message}:
              ValsFail{message}
            case ValsOk{vals}:
              ValsOk{val <> vals}

# A head applied to arguments, whether it is sugar over a type name or an
# already evaluated type function.
def eval_apply_args(ctx: Context, head: BIR.Descriptor, args: List<&2, BIR.Descriptor>, env: List<&2, Val>, fuel: Nat) -> Evals:
  match eval_desc(ctx, head, env, fuel):
    case EvalsFail{message}:
      EvalsFail{message}
    case EvalsOk{val}:
      match eval_all(ctx, args, env, fuel):
        case ValsFail{message}:
          EvalsFail{message}
        case ValsOk{vals}:
          apply_vals(ctx, val, vals, fuel)

def apply_vals(ctx: Context, val: Val, args: List<&2, Val>, fuel: Nat) -> Evals:
  match args:
    case Nil{}:
      EvalsOk{val}
    case +arg <> rest:
      match apply_val(ctx, val, arg, fuel):
        case EvalsFail{message}:
          EvalsFail{message}
        case EvalsOk{next}:
          apply_vals(ctx, next, rest, fuel)

def apply_val(ctx: Context, val: Val, arg: Val, fuel: Nat) -> Evals:
  match val:
    case ValType{key, args}:
      named(ctx, key, List.append(&2, Val, args, [arg]), fuel)
    case ValCtor{key, args}:
      EvalsOk{ValOther{}}
    case ValQuantity{quantity}:
      EvalsOk{ValOther{}}
    case ValKind{quantity}:
      EvalsOk{ValOther{}}
    case ValOther{}:
      EvalsOk{ValOther{}}
    case ValMissing{}:
      EvalsOk{ValOther{}}

# A named type with the arguments it has: a type function reduces once it is
# fully applied, a datatype keeps its arguments, and a name that is neither
# is an abstract type expression, which no layout can look into.
def named(ctx: Context, key: String, args: List<&2, Val>, fuel: Nat) -> Evals:
  match function_of(key, ctx.type_functions):
    case Some{function}:
      reduce_function(ctx, function, args, fuel)
    case None{}:
      match family_of(key, ctx.families):
        case Some{family}:
          family_value(family, args)
        case None{}:
          EvalsOk{ValType{key, args}}

def family_value(family: BIR.Family, args: List<&2, Val>) -> Evals:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      count = List.length(&2, Val, args)
      match Nat.is_eq(Nat.add(count, quantity_prefix), arity):
        case True{}:
          # The quantity binders of a datatype are implicit: a full
          # application supplies only its value parameters, and the quantity
          # arguments precede them. No layout reads a quantity argument.
          EvalsOk{ValType{key, List.append(&2, Val, quantity_markers(quantity_prefix), args)}}
        case False{}:
          match Nat.is_eq(count, arity):
            case True{}:
              EvalsOk{ValType{key, args}}
            case False{}:
              match Nat.is_lt(count, arity):
                case True{}:
                  EvalsOk{ValType{key, args}}
                case False{}:
                  EvalsFail{String.append("the type `", String.append(key, "` is applied past its declared parameter count"))}

def quantity_markers(count: Nat) -> List<&2, Val>:
  match count:
    case 0n:
      Nil{}
    case 1n+rest:
      ValQuantity{BIR.Erased{}} <> quantity_markers(rest)

def reduce_function(ctx: Context, function: BIR.TypeFunction, args: List<&2, Val>, fuel: Nat) -> Evals:
  match function:
    case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
      count = List.length(&2, Val, args)
      match Nat.is_lt(count, arity):
        case True{}:
          EvalsOk{ValType{key, args}}
        case False{}:
          match Nat.is_eq(Nat.add(count, quantity_prefix), arity):
            case True{}:
              reduce_body(ctx, body, List.append(&2, Val, quantity_markers(quantity_prefix), args), Nil{}, fuel)
            case False{}:
              reduce_body(ctx, body, first_vals(args, arity), drop_vals(args, arity), fuel)

def reduce_body(ctx: Context, body: BIR.Descriptor, env: List<&2, Val>, extra: List<&2, Val>, fuel: Nat) -> Evals:
  match eval_desc(ctx, body, env, fuel):
    case EvalsFail{message}:
      EvalsFail{message}
    case EvalsOk{val}:
      apply_vals(ctx, val, extra, fuel)

def eval_cases(ctx: Context, cases: List<&2, BIR.Descriptor>, values: List<&2, Val>, env: List<&2, Val>, fuel: Nat) -> Evals:
  match cases:
    case Nil{}:
      EvalsOk{ValOther{}}
    case +case_body <> rest:
      match case_body:
        case BIR.DescriptorCase{patterns, body}:
          match bind_patterns(patterns, values, fuel):
            case Some{bindings}:
              eval_desc(ctx, body, List.append(&2, Val, env, bindings), fuel)
            case None{}:
              eval_cases(ctx, rest, values, env, fuel)

def bind_patterns(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, Val>, fuel: Nat) -> Maybe<&2, List<&2, Val>>:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      None{}
    case False{}:
      bind_patterns_go(patterns, values, Nil{}, fuel)

def bind_patterns_go(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, Val>, acc: List<&2, Val>, fuel: Nat) -> Maybe<&2, List<&2, Val>>:
  match patterns, values:
    case Nil{}, Nil{}:
      Some{List.reverse(&2, Val, acc)}
    case +pattern <> prest, +value <> vrest:
      match bind_pattern(pattern, value, fuel):
        case Some{bindings}:
          bind_patterns_go(prest, vrest, List.append(&2, Val, bindings, acc), fuel)
        case None{}:
          None{}
    case _, _:
      None{}

def bind_pattern(pattern: BIR.DescriptorPattern, value: Val, fuel: Nat) -> Maybe<&2, List<&2, Val>>:
  match pattern:
    case BIR.DescriptorBinder{quantity}:
      Some{[value]}
    case BIR.DescriptorConstructorPattern{key, fields}:
      match value:
        case ValCtor{known, args}:
          match String.eq(key, known):
            case False{}:
              None{}
            case True{}:
              match bind_patterns(fields, args, fuel):
                case Some{bindings}:
                  Some{bindings}
                case None{}:
                  None{}
        case _:
          None{}

def val_at(env: List<&2, Val>, index: Nat) -> Val:
  count = List.length(&2, Val, env)
  match Nat.is_lt(index, count):
    case True{}:
      val_nth(env, Nat.sub(Nat.sub(count, 1n), index))
    case False{}:
      ValMissing{}

def val_nth(env: List<&2, Val>, at: Nat) -> Val:
  match at, env:
    case 0n, +val <> rest:
      val
    case 1n+prev, +val <> rest:
      val_nth(rest, prev)
    case _, _:
      ValMissing{}

def first_vals(vals: List<&2, Val>, count: Nat) -> List<&2, Val>:
  match count, vals:
    case 0n, _:
      Nil{}
    case _, Nil{}:
      Nil{}
    case 1n+rest, +val <> tail:
      val <> first_vals(tail, rest)

def drop_vals(vals: List<&2, Val>, count: Nat) -> List<&2, Val>:
  match count, vals:
    case 0n, _:
      vals
    case _, Nil{}:
      Nil{}
    case 1n+rest, +val <> tail:
      drop_vals(tail, rest)

def insert_before(vals: List<&2, Val>, at: Nat, val: Val) -> List<&2, Val>:
  match at, vals:
    case 0n, _:
      val <> vals
    case 1n+prev, Nil{}:
      insert_before(Nil{}, prev, val)
    case 1n+prev, +head <> rest:
      head <> insert_before(rest, prev, val)

# ---------------------------------------------------------------------------
# Value layouts
# ---------------------------------------------------------------------------

def value_layout(ctx: Context, ty: BIR.Descriptor) -> LayoutResult:
  layout_of_desc(ctx, ty, Nil{}, fuel())

def layout_of_desc(ctx: Context, descriptor: BIR.Descriptor, env: List<&2, Val>, fuel: Nat) -> LayoutResult:
  match eval_desc(ctx, descriptor, env, fuel):
    case EvalsFail{message}:
      LayoutFailed{message}
    case EvalsOk{val}:
      layout_of_val(ctx, val, fuel)

def layout_of_val(ctx: Context, val: Val, fuel: Nat) -> LayoutResult:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case False{}:
      layout_val(ctx, val, Nat.sub(fuel, 1n))

def layout_val(ctx: Context, val: Val, fuel: Nat) -> LayoutResult:
  match val:
    case ValType{key, args}:
      match family_of(key, ctx.families):
        case Some{family}:
          layout_family(ctx, family, args, fuel)
        case None{}:
          layout_unresolved(ctx, key)
    case ValCtor{key, args}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case ValQuantity{quantity}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case ValKind{quantity}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case ValOther{}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case ValMissing{}:
      LayoutFound{LayoutBox{BoxOpen{}}}

# A name that is neither a family nor a type function is an abstract type
# expression (an opaque checked law such as Chan), which the authoritative
# rule boxes. A name that is a type function under-applied is abstract too.
# The two are kept apart: the first reports the name it could not resolve, so
# a lowering inconsistency is visible in a review, while both lay out as one
# box.
def layout_unresolved(ctx: Context, key: String) -> LayoutResult:
  match function_of(key, ctx.type_functions):
    case Some{function}:
      LayoutFound{LayoutBox{BoxOpen{}}}
    case None{}:
      LayoutFound{LayoutBox{BoxUnresolved{key}}}

def layout_family(ctx: Context, family: BIR.Family, args: List<&2, Val>, fuel: Nat) -> LayoutResult:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      match Nat.is_eq(List.length(&2, Val, args), arity):
        case False{}:
          LayoutFound{LayoutBox{BoxOpen{}}}
        case True{}:
          match native:
            case Some{marker}:
              layout_native(ctx, marker, key, arms, args, fuel)
            case None{}:
              layout_data(ctx, key, arms, args, fuel)

# Only the base library's word and opaque types have a fixed representation;
# Char, String, Bool and every other Base datatype lay out as declared.
def layout_native(ctx: Context, marker: String, key: String, arms: List<&2, BIR.DescriptorArm>, args: List<&2, Val>, fuel: Nat) -> LayoutResult:
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

type Plans is Data:
  PlansOk{plans: List<&2, LayArm>}
  PlansFail{message: String}

type Layouts is Data:
  LayoutsOk{layouts: List<&2, Layout>}
  LayoutsFail{message: String}

# Every arm of a datatype, each with its live declared fields' layouts taken
# at this application's arguments.
def arm_layouts(ctx: Context, arms: List<&2, BIR.DescriptorArm>, args: List<&2, Val>, fuel: Nat, acc: List<&2, LayArm>) -> Plans:
  match arms:
    case Nil{}:
      PlansOk{List.reverse(&2, LayArm, acc)}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key, fields}:
          match field_layouts(ctx, fields, args, fuel, Nil{}):
            case LayoutsFail{message}:
              PlansFail{message}
            case LayoutsOk{layouts}:
              arm_layouts(ctx, rest, args, fuel, LayArm{key, layouts} <> acc)

def field_layouts(ctx: Context, fields: List<&2, BIR.DescriptorField>, env: List<&2, Val>, fuel: Nat, acc: List<&2, Layout>) -> Layouts:
  match fields:
    case Nil{}:
      LayoutsOk{List.reverse(&2, Layout, acc)}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match live_field(quantity):
            case False{}:
              field_layouts(ctx, rest, env, fuel, acc)
            case True{}:
              match layout_of_desc(ctx, ty, env, fuel):
                case LayoutFailed{message}:
                  LayoutsFail{message}
                case LayoutFound{layout}:
                  field_layouts(ctx, rest, env, fuel, layout <> acc)

def layout_data(ctx: Context, key: String, arms: List<&2, BIR.DescriptorArm>, args: List<&2, Val>, fuel: Nat) -> LayoutResult:
  match reenters(ctx, key, arms, args, fuel):
    case True{}:
      LayoutFound{LayoutBox{BoxRecursive{key}}}
    case False{}:
      match arm_layouts(ctx, arms, args, fuel, Nil{}):
        case PlansFail{message}:
          LayoutFailed{message}
        case PlansOk{plans}:
          words = pack_arms(plans, tagged(plans))
          count = List.length(&2, CWord, words)
          match Nat.is_gt(count, 8n):
            case True{}:
              LayoutFound{LayoutBox{BoxWide{count}}}
            case False{}:
              LayoutFound{LayoutData{words, plans}}

def tagged(arms: List<&2, LayArm>) -> Bool:
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
def reenters(ctx: Context, key: String, arms: List<&2, BIR.DescriptorArm>, args: List<&2, Val>, fuel: Nat) -> Bool:
  match arms:
    case Nil{}:
      args_reach(ctx, args, key, Nil{}, fuel)
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{ctor, fields}:
          match fields_reach(ctx, fields, args, key, Nil{}, fuel):
            case True{}:
              True{}
            case False{}:
              reenters(ctx, key, rest, args, fuel)

def fields_reach(ctx: Context, fields: List<&2, BIR.DescriptorField>, env: List<&2, Val>, target: String, seen: List<&2, String>, fuel: Nat) -> Bool:
  match fields:
    case Nil{}:
      False{}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match live_field(quantity):
            case False{}:
              fields_reach(ctx, rest, env, target, seen, fuel)
            case True{}:
              match reaches(ctx, ty, env, target, seen, fuel):
                case True{}:
                  True{}
                case False{}:
                  fields_reach(ctx, rest, env, target, seen, fuel)

def reaches(ctx: Context, ty: BIR.Descriptor, env: List<&2, Val>, target: String, seen: List<&2, String>, fuel: Nat) -> Bool:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      False{}
    case False{}:
      match eval_desc(ctx, ty, env, fuel):
        case EvalsFail{message}:
          False{}
        case EvalsOk{val}:
          reaches_val(ctx, val, target, seen, Nat.sub(fuel, 1n))

def reaches_val(ctx: Context, val: Val, target: String, seen: List<&2, String>, fuel: Nat) -> Bool:
  match val:
    case ValType{key, args}:
      match String.eq(key, target):
        case True{}:
          True{}
        case False{}:
          match str_member(seen, key):
            case True{}:
              False{}
            case False{}:
              match family_of(key, ctx.families):
                case None{}:
                  args_reach(ctx, args, target, seen, fuel)
                case Some{family}:
                  match family_reach(ctx, family, args, target, key <> seen, fuel):
                    case True{}:
                      True{}
                    case False{}:
                      args_reach(ctx, args, target, seen, fuel)
    case _:
      False{}

def family_reach(ctx: Context, family: BIR.Family, args: List<&2, Val>, target: String, seen: List<&2, String>, fuel: Nat) -> Bool:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      match Nat.is_eq(List.length(&2, Val, args), arity):
        case False{}:
          False{}
        case True{}:
          match native:
            case Some{marker}:
              match String.eq(marker, "Array"):
                case True{}:
                  False{}
                case False{}:
                  reach_arms(ctx, arms, args, target, seen, fuel)
            case None{}:
              reach_arms(ctx, arms, args, target, seen, fuel)

def reach_arms(ctx: Context, arms: List<&2, BIR.DescriptorArm>, env: List<&2, Val>, target: String, seen: List<&2, String>, fuel: Nat) -> Bool:
  match arms:
    case Nil{}:
      False{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key, fields}:
          match fields_reach(ctx, fields, env, target, seen, fuel):
            case True{}:
              True{}
            case False{}:
              reach_arms(ctx, rest, env, target, seen, fuel)

def args_reach(ctx: Context, args: List<&2, Val>, target: String, seen: List<&2, String>, fuel: Nat) -> Bool:
  match args:
    case Nil{}:
      False{}
    case +arg <> rest:
      match reaches_val(ctx, arg, target, seen, fuel):
        case True{}:
          True{}
        case False{}:
          args_reach(ctx, rest, target, seen, fuel)

def str_member(items: List<&2, String>, key: String) -> Bool:
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

def layout_kinds(layout: Layout) -> List<&2, CWord>:
  match layout:
    case LayoutWord{word}:
      [word]
    case LayoutBox{reason}:
      [CWordBox{}]
    case LayoutData{words, arms}:
      words

def layout_words(layout: Layout) -> Nat:
  List.length(&2, CWord, layout_kinds(layout))

def canonical_word(layout: Layout) -> CWord:
  match layout:
    case LayoutWord{word}:
      word
    case _:
      CWordBox{}

# A field's words merge position by position across a type's arms: a box is
# never narrowed, a w32 is never widened, and a position no arm writes is
# w32. The tag word comes first when there is more than one arm.
def pack_arms(arms: List<&2, LayArm>, tag: Bool) -> List<&2, CWord>:
  match tag:
    case True{}:
      pack_arm_list(arms, 1n, [CWord32{}])
    case False{}:
      pack_arm_list(arms, 0n, Nil{})

def pack_arm_list(arms: List<&2, LayArm>, at: Nat, words: List<&2, CWord>) -> List<&2, CWord>:
  match arms:
    case Nil{}:
      words
    case +arm <> rest:
      match arm:
        case LayArm{key, fields}:
          pack_arm_list(rest, at, pack_field_list(fields, at, words))

def pack_field_list(fields: List<&2, Layout>, at: Nat, words: List<&2, CWord>) -> List<&2, CWord>:
  match fields:
    case Nil{}:
      words
    case +layout <> rest:
      kinds = layout_kinds(layout)
      pack_field_list(rest, Nat.add(at, List.length(&2, CWord, kinds)), pack_kinds(kinds, at, words))

def pack_kinds(kinds: List<&2, CWord>, at: Nat, words: List<&2, CWord>) -> List<&2, CWord>:
  match kinds:
    case Nil{}:
      words
    case +kind <> rest:
      pack_kinds(rest, Nat.add(at, 1n), set_kind(words, at, kind))

def set_kind(words: List<&2, CWord>, at: Nat, kind: CWord) -> List<&2, CWord>:
  match at, words:
    case 0n, Nil{}:
      [merge_kind(CWord32{}, kind)]
    case 0n, +old <> rest:
      merge_kind(old, kind) <> rest
    case 1n+prev, Nil{}:
      CWord32{} <> set_kind(Nil{}, prev, kind)
    case 1n+prev, +old <> rest:
      old <> set_kind(rest, prev, kind)

def merge_kind(old: CWord, kind: CWord) -> CWord:
  match old:
    case CWordBox{}:
      old
    case _:
      match kind:
        case CWord32{}:
          old
        case _:
          kind

def word_32(word: CWord) -> Bool:
  match word:
    case CWord32{}:
      True{}
    case _:
      False{}

# A node wider than the runtime's word bound pads to a power of two; every
# narrower node keeps its exact word count.
def pad_words(words: List<&2, CWord>) -> List<&2, CWord>:
  count = List.length(&2, CWord, words)
  match Nat.is_gt(count, 247n):
    case False{}:
      words
    case True{}:
      next = pow2_upto(1n, count)
      match Nat.is_eq(next, count):
        case True{}:
          words
        case False{}:
          pad_to(words, next)

def pad_to(words: List<&2, CWord>, target: Nat) -> List<&2, CWord>:
  match Nat.is_eq(List.length(&2, CWord, words), target):
    case True{}:
      words
    case False{}:
      pad_to(List.append(&2, CWord, words, [CWord32{}]), target)

def pow2_upto(power: Nat, count: Nat) -> Nat:
  match Nat.is_gt(power, count):
    case True{}:
      power
    case False{}:
      pow2_upto(Nat.mul(power, 2n), count)

def ceil_log2(count: Nat) -> Nat:
  match Nat.is_gt(count, 1n):
    case False{}:
      0n
    case True{}:
      ceil_log2_go(1n, 0n, count)

def ceil_log2_go(power: Nat, shift: Nat, count: Nat) -> Nat:
  match Nat.is_gt(power, count):
    case True{}:
      shift
    case False{}:
      match Nat.is_gt(shift, 30n):
        case True{}:
          31n
        case False{}:
          ceil_log2_go(Nat.mul(power, 2n), Nat.add(shift, 1n), count)

# ---------------------------------------------------------------------------
# Constructor nodes
# ---------------------------------------------------------------------------

def node_layout(ctx: Context, key: String) -> NodeResult:
  node_layout_fuel(ctx, key, fuel())

def node_layout_fuel(ctx: Context, key: String, fuel: Nat) -> NodeResult:
  match arm_of(key, ctx.families):
    case None{}:
      NodeFailed{String.append("the constructor `", String.append(key, "` is in no declared family arm"))}
    case Some{arm}:
      match arm:
        case BIR.DescriptorArm{ctor, fields}:
          match node_slots(ctx, fields, 0u, 0n, fuel, Nil{}):
            case SlotsFail{message}:
              NodeFailed{message}
            case SlotsOk{slots}:
              node_finish(slots)

def node_slots(ctx: Context, fields: List<&2, BIR.DescriptorField>, ordinal: U32, offset: Nat, fuel: Nat, acc: List<&2, NodeSlot>) -> Slots:
  match fields:
    case Nil{}:
      SlotsOk{List.reverse(&2, NodeSlot, acc)}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match live_field(quantity):
            case False{}:
              node_slots(ctx, rest, U32.inc(ordinal), offset, fuel, acc)
            case True{}:
              match layout_of_desc(ctx, ty, Nil{}, fuel):
                case LayoutFailed{message}:
                  SlotsFail{message}
                case LayoutFound{layout}:
                  slot = NodeSlot{ordinal, offset, layout}
                  node_slots(ctx, rest, U32.inc(ordinal), Nat.add(offset, layout_words(layout)), fuel, slot <> acc)

def node_finish(slots: List<&2, NodeSlot>) -> NodeResult:
  match slots:
    case Nil{}:
      NodeFound{Node{Nil{}, Nil{}, True{}}}
    case _:
      words = pad_words(slot_words(slots))
      NodeFound{Node{words, slots, packed_words(words)}}

def slot_words(slots: List<&2, NodeSlot>) -> List<&2, CWord>:
  match slots:
    case Nil{}:
      Nil{}
    case +slot <> rest:
      match slot:
        case NodeSlot{ordinal, offset, layout}:
          List.append(&2, CWord, layout_kinds(layout), slot_words(rest))

def packed_words(words: List<&2, CWord>) -> Bool:
  match words:
    case Nil{}:
      True{}
    case +word <> rest:
      match rest:
        case Nil{}:
          word_32(word)
        case _:
          False{}

type Slots is Data:
  SlotsOk{slots: List<&2, NodeSlot>}
  SlotsFail{message: String}

def node_slot(ctx: Context, key: String, ordinal: U32) -> SlotResult:
  match node_layout(ctx, key):
    case NodeFailed{message}:
      SlotFailed{message}
    case NodeFound{node}:
      match node:
        case Node{words, slots, packed}:
          match slot_find(slots, ordinal):
            case Some{slot}:
              SlotFound{slot}
            case None{}:
              SlotErased{}

def slot_find(slots: List<&2, NodeSlot>, ordinal: U32) -> Maybe<&2, NodeSlot>:
  match slots:
    case Nil{}:
      None{}
    case +slot <> rest:
      match slot:
        case NodeSlot{known, offset, layout}:
          match U32.is_eq(ordinal, known):
            case True{}:
              Some{slot}
            case False{}:
              slot_find(rest, ordinal)

# ---------------------------------------------------------------------------
# Canonical value <-> laid-out words
# ---------------------------------------------------------------------------

def layout_fill(ctx: Context, layout: Layout) -> FillResult:
  layout_fill_fuel(ctx, layout, fuel())

def layout_fill_fuel(ctx: Context, layout: Layout, fuel: Nat) -> FillResult:
  match layout:
    case LayoutWord{word}:
      FillFound{FillWord{}}
    case LayoutBox{reason}:
      FillFound{FillWord{}}
    case LayoutData{words, arms}:
      match form_arms(ctx, arms, 0n, Nat.is_gt(List.length(&2, LayArm, arms), 1n), List.length(&2, CWord, words), fuel, Nil{}, True{}):
        case ArmsFail{message}:
          FillFailed{message}
        case ArmsOk{plans}:
          FillFound{FillForm{List.length(&2, CWord, words), plans}}

def layout_unfill(ctx: Context, layout: Layout) -> UnfillResult:
  layout_unfill_fuel(ctx, layout, fuel())

def layout_unfill_fuel(ctx: Context, layout: Layout, fuel: Nat) -> UnfillResult:
  match layout:
    case LayoutWord{word}:
      UnfillFound{UnfillWord{}}
    case LayoutBox{reason}:
      UnfillFound{UnfillWord{}}
    case LayoutData{words, arms}:
      match form_arms(ctx, arms, 0n, Nat.is_gt(List.length(&2, LayArm, arms), 1n), List.length(&2, CWord, words), fuel, Nil{}, False{}):
        case ArmsFail{message}:
          UnfillFailed{message}
        case ArmsOk{plans}:
          UnfillFound{UnfillForm{List.length(&2, CWord, words), plans}}

def slot_fill(ctx: Context, key: String, ordinal: U32) -> FillResult:
  match node_slot(ctx, key, ordinal):
    case SlotFound{slot}:
      match slot:
        case NodeSlot{at, offset, layout}:
          layout_fill(ctx, layout)
    case SlotErased{}:
      FillFailed{String.append("the constructor `", String.append(key, "` field slot is erased and has no storage"))}
    case SlotFailed{message}:
      FillFailed{message}

def slot_unfill(ctx: Context, key: String, ordinal: U32) -> UnfillResult:
  match node_slot(ctx, key, ordinal):
    case SlotFound{slot}:
      match slot:
        case NodeSlot{at, offset, layout}:
          layout_unfill(ctx, layout)
    case SlotErased{}:
      UnfillFailed{String.append("the constructor `", String.append(key, "` field slot is erased and has no storage"))}
    case SlotFailed{message}:
      UnfillFailed{message}

# One arm of a form. `forward` plans a canonical value into the laid-out
# words; the other direction plans the laid-out words back into the canonical
# value. `word_count` is the laid-out word count, which is also the number of
# source words in the other direction.
def form_arms(ctx: Context, arms: List<&2, LayArm>, tag: Nat, tagged: Bool, word_count: Nat, fuel: Nat, acc: List<&2, FormArm>, forward: Bool) -> Arms:
  match arms:
    case Nil{}:
      ArmsOk{List.reverse(&2, FormArm, acc)}
    case +arm <> rest:
      match arm:
        case LayArm{key, fields}:
          match form_arm(ctx, key, tag, tagged, word_count, fields, fuel, forward):
            case FormArmFail{message}:
              ArmsFail{message}
            case FormArmOk{plan}:
              form_arms(ctx, rest, Nat.add(tag, 1n), tagged, word_count, fuel, plan <> acc, forward)

type Arms is Data:
  ArmsOk{arms: List<&2, FormArm>}
  ArmsFail{message: String}

type Nests is Data:
  NestsOk{nests: List<&2, Nest>}
  NestsFail{message: String}

type FormArmResult is Data:
  FormArmOk{plan: FormArm}
  FormArmFail{message: String}

def form_arm(ctx: Context, key: String, tag: Nat, tagged: Bool, word_count: Nat, fields: List<&2, Layout>, fuel: Nat, forward: Bool) -> FormArmResult:
  match node_layout_fuel(ctx, key, fuel):
    case NodeFailed{message}:
      FormArmFail{message}
    case NodeFound{node}:
      match node:
        case Node{words, slots, packed}:
          first = tag_word(tagged)
          match form_nests(ctx, fields, slots, first, word_count, List.length(&2, CWord, words), fuel, Nil{}, forward):
            case NestsFail{message}:
              FormArmFail{message}
            case NestsOk{nests}:
              FormArmOk{FormArm{key, tag, packed, List.length(&2, CWord, words), nests}}

def tag_word(tagged: Bool) -> Nat:
  match tagged:
    case True{}:
      1n
    case False{}:
      0n

def form_nests(ctx: Context, fields: List<&2, Layout>, slots: List<&2, NodeSlot>, at: Nat, word_count: Nat, node_words: Nat, fuel: Nat, acc: List<&2, Nest>, forward: Bool) -> Nests:
  match fields, slots:
    case Nil{}, Nil{}:
      NestsOk{List.reverse(&2, Nest, acc)}
    case +layout <> frest, +slot <> srest:
      match slot:
        case NodeSlot{ordinal, offset, slot_layout}:
          match forward:
            case True{}:
              # The canonical value's node field (slot_layout) is the source;
              # the slot's own field layout (layout) is the target.
              match layout_unfill_fuel(ctx, slot_layout, fuel):
                case UnfillFailed{message}:
                  NestsFail{message}
                case UnfillFound{take}:
                  match layout_fill_fuel(ctx, layout, fuel):
                    case FillFailed{message}:
                      NestsFail{message}
                    case FillFound{make}:
                      match nest_fits(at, word_count, offset, node_words, take, make):
                        case False{}:
                          NestsFail("the constructor node does not fit its value layout")
                        case True{}:
                          form_nests(ctx, frest, srest, Nat.add(at, fill_words(make)), word_count, node_words, fuel, nest(at, offset, take, make) <> acc, forward)
            case False{}:
              # The slot's field layout (layout) is the source; the canonical
              # value's node field (slot_layout) is the target.
              match layout_unfill_fuel(ctx, layout, fuel):
                case UnfillFailed{message}:
                  NestsFail{message}
                case UnfillFound{take}:
                  match layout_fill_fuel(ctx, slot_layout, fuel):
                    case FillFailed{message}:
                      NestsFail{message}
                    case FillFound{make}:
                      match nest_fits(at, node_words, offset, word_count, take, make):
                        case False{}:
                          NestsFail("the constructor node does not fit its value layout")
                        case True{}:
                          form_nests(ctx, frest, srest, Nat.add(offset, unfill_words(take)), word_count, node_words, fuel, nest(offset, at, take, make) <> acc, forward)
    case _, _:
      NestsFail("a constructor node and its value layout disagree on the live field count")

def nest(at: Nat, offset: Nat, take: Unfill, make: Fill) -> Nest:
  Nest{at, offset, take, make}

# The source run at `offset` must fit `source_limit` words and the target run
# at `at` must fit `target_limit`.
def nest_fits(at: Nat, target_limit: Nat, offset: Nat, source_limit: Nat, take: Unfill, make: Fill) -> Bool:
  match Nat.is_gt(Nat.add(at, fill_words(make)), target_limit):
    case True{}:
      False{}
    case False{}:
      match Nat.is_gt(Nat.add(offset, unfill_words(take)), source_limit):
        case True{}:
          False{}
        case False{}:
          True{}

def fill_words(fill: Fill) -> Nat:
  match fill:
    case FillWord{}:
      1n
    case FillForm{words, arms}:
      words

def unfill_words(unfill: Unfill) -> Nat:
  match unfill:
    case UnfillWord{}:
      1n
    case UnfillForm{words, arms}:
      words

# ---------------------------------------------------------------------------
# Array cells
# ---------------------------------------------------------------------------

def array_cell(ctx: Context, element: BIR.Descriptor) -> CellResult:
  match value_layout(ctx, element):
    case LayoutFailed{message}:
      CellFailed{message}
    case LayoutFound{layout}:
      cell_of(layout)

def cell_of(layout: Layout) -> CellResult:
  match layout:
    case LayoutBox{reason}:
      cell_boxed(reason)
    case _:
      words = layout_words(layout)
      CellFound{Cell{layout, layout_has_term(layout), words, ceil_log2(max_one(words))}}

# An array of an abstract element type has no cell layout: the reference rule
# refuses an open element rather than boxing it silently.
def cell_boxed(reason: BoxReason) -> CellResult:
  match reason:
    case BoxOpen{}:
      CellFailed("the array element type is an open type; the reference layout rule refuses an open array element")
    case _:
      CellFound{Cell{LayoutBox{reason}, True{}, 1n, 0n}}

def max_one(count: Nat) -> Nat:
  match Nat.is_gt(count, 0n):
    case True{}:
      count
    case False{}:
      1n

# A block is an ARR of Term cells when any element word is not a u32; a BUF
# of packed u32 cells otherwise.
def layout_has_term(layout: Layout) -> Bool:
  match layout:
    case LayoutWord{word}:
      word_has_term(word)
    case LayoutBox{reason}:
      True{}
    case LayoutData{words, arms}:
      any_word_has_term(words)

def word_has_term(word: CWord) -> Bool:
  match word:
    case CWord32{}:
      False{}
    case _:
      True{}

def any_word_has_term(words: List<&2, CWord>) -> Bool:
  match words:
    case Nil{}:
      False{}
    case +word <> rest:
      match word_has_term(word):
        case True{}:
          True{}
        case False{}:
          any_word_has_term(rest)
