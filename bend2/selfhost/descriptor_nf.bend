# Descriptor normal form
# ======================
#
# One target-neutral normalizer for the runtime's type-expression language.
# It reads Backend IR only: a BIR.Descriptor plus the program's declared
# families and type functions. No syntax tree, no checker environment, no
# target: lower_catalog's stored-fact pass and the C target's layout planner
# both normalize through this one module.
#
# The rules are the reference runtime's type-expression evaluator (comp.ts
# RUNTIME: $type, $type_apply, $type_named, $type_sugar):
#
#   * a descriptor parameter indexes the applied argument list from its end
#     (index 0 is the last argument); a parameter with no argument in scope is
#     abstract, never a failure;
#   * a family applied to its value arguments implicitly carries its quantity
#     binders: when the supplied count plus the family's quantity prefix is
#     its arity, the quantity arguments precede the supplied ones. No consumer
#     reads a quantity argument;
#   * a type function is beta-reduced once it has its arity arguments, and any
#     further arguments apply to the result (curried over-application);
#     `native` is metadata, never a reason to refuse a reduction, so a closed
#     alias of Nat or IO resolves to what it names;
#   * an application to too few arguments is abstract, and an application past
#     a family's parameter count is a reducer failure;
#   * substitution, let, local, bind and match are the descriptor language's
#     scoping forms; a match binds its constructor patterns and evaluates its
#     body in the extended environment, and a match whose scrutinee is not a
#     constructor value is abstract (no type unfolds from it);
#   * a name that is neither a family nor a type function is an abstract type
#     expression (an opaque law such as Chan or File), so it is kept as it is,
#     not a failure: checking already accepted it.
#
# Reduction is bounded by a fuel counter and terminates on its own; when the
# bound runs out the expression is abstract. A reduction that cannot be
# performed at all (an over-applied family, a DescriptorFailure) is NfFail,
# and every consumer must report it rather than guess.
#
# An abstract normal form keeps its source descriptor (NfOther/NfMissing), so
# materializing a normal form is total and exact: a named application becomes
# a DescriptorRef of the same key over the normalized arguments (quantity
# markers included, exactly as the runtime's own type values carry them), and
# an abstract form is its own descriptor, unchanged.
#
# The module imports Base and Backend IR only.

import Base
import ./backend_ir.bend as BIR
import ./index_lookup.bend as IndexLookup

# A normalized type expression. NfType is a named type applied to the
# arguments it has so far; NfCtor is a value constructor applied to values,
# which a type-level match may inspect; NfQuantity and NfKind are the
# quantity and kind language, which no target reads (a kind carries its
# quantity already materialized, so building a normal form never needs a
# second traversal with its own budget); NfOther is any other term (a
# function, a proof, a hole), kept as its own descriptor; NfMissing is a
# binder with no value in scope, kept as its own descriptor.
type NfVal is Data:
  NfType{key: String, args: List<&2, NfVal>}
  NfCtor{key: String, args: List<&2, NfVal>}
  NfQuantity{quantity: BIR.Quantity}
  NfKind{quantity: BIR.Descriptor}
  NfOther{source: BIR.Descriptor}
  NfMissing{source: BIR.Descriptor}

type Nf is Data:
  NfOk{val: NfVal}
  NfFail{message: String}

type NfList is Data:
  NfListOk{vals: List<&2, NfVal>}
  NfListFail{message: String}

type NfContext is Data:
  NfContext{families: Map<&2, BIR.Family>, type_functions: Map<&2, BIR.TypeFunction>}

# An outer named application: the key and the arguments applied to it.
type NfApp is Data:
  NfApp{key: String, args: List<&2, BIR.Descriptor>}

# The arity decision is computed from a borrowed argument list, then applied to
# the owned list exactly once. This keeps list measurement from consuming the
# value that the resulting NfType must own.
type NfArity is Data:
  NfArity{complete: Bool, exact: Bool, under: Bool}

def family_index(families: List<&2, BIR.Family>) -> Map<&2, BIR.Family>:
  match families:
    case Nil{}:
      Map.new(&2, BIR.Family)
    case +family <> rest:
      match family:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
          Map.set(&2, BIR.Family, family_index(rest), key, family)

def function_index(functions: List<&2, BIR.TypeFunction>) -> Map<&2, BIR.TypeFunction>:
  match functions:
    case Nil{}:
      Map.new(&2, BIR.TypeFunction)
    case +function <> rest:
      match function:
        case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
          Map.set(&2, BIR.TypeFunction, function_index(rest), key, function)

def nf_context(families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> NfContext:
  NfContext{family_index(families), function_index(type_functions)}

def default_fuel() -> Nat:
  1024n

# ---------------------------------------------------------------------------
# Lookup: exact canonical keys only
# ---------------------------------------------------------------------------

def family_of(+key: String, +families: Map<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  IndexLookup.find(BIR.Family, families, key)

def function_of(+key: String, +functions: Map<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  IndexLookup.find(BIR.TypeFunction, functions, key)

def native_of(+key: String, +families: Map<&2, BIR.Family>, +functions: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match family_of(key, families):
    case Some{family}:
      match family:
        case BIR.Family{known, name, native, quantity_prefix, arity, arms}:
          native
    case None{}:
      match function_of(key, functions):
        case Some{function}:
          match function:
            case BIR.TypeFunction{known, native, quantity_prefix, arity, body}:
              native
        case None{}:
          None{}

# ---------------------------------------------------------------------------
# Environment and list helpers
# ---------------------------------------------------------------------------

def val_nth(+env: List<&2, NfVal>, at: Nat) -> NfVal:
  match env, at:
    case +val <> rest, 0n:
      val
    case +val <> rest, 1n+prev:
      val_nth(rest, prev)
    case _, _:
      NfMissing{BIR.DescriptorNull{}}

def val_at(+env: List<&2, NfVal>, +index: Nat, source: BIR.Descriptor) -> NfVal:
  val_at_choose(Nat.is_lt(index, List.length(&2, NfVal, env)), env, index, source)

def val_at_choose(inside: Bool, +env: List<&2, NfVal>, +index: Nat, source: BIR.Descriptor) -> NfVal:
  match inside:
    case True{}:
      val_nth(env, Nat.sub(Nat.sub(List.length(&2, NfVal, env), 1n), index))
    case False{}:
      NfMissing{source}

def first_vals(vals: List<&2, NfVal>, +count: Nat) -> List<&2, NfVal>:
  match vals, count:
    case _, 0n:
      Nil{}
    case Nil{}, _:
      Nil{}
    case +val <> tail, 1n+rest:
      val <> first_vals(tail, rest)

def drop_vals(vals: List<&2, NfVal>, +count: Nat) -> List<&2, NfVal>:
  match vals, count:
    case _, 0n:
      vals
    case Nil{}, _:
      Nil{}
    case +val <> tail, 1n+rest:
      drop_vals(tail, rest)

def insert_before(vals: List<&2, NfVal>, +at: Nat, val: NfVal) -> List<&2, NfVal>:
  match vals, at:
    case _, 0n:
      val <> vals
    case Nil{}, 1n+prev:
      insert_before(Nil{}, prev, val)
    case +head <> rest, 1n+prev:
      head <> insert_before(rest, prev, val)

def append_vals(head: List<&2, NfVal>, tail: List<&2, NfVal>) -> List<&2, NfVal>:
  match head:
    case Nil{}:
      tail
    case +val <> rest:
      val <> append_vals(rest, tail)

def quantity_markers(count: Nat) -> List<&2, NfVal>:
  match count:
    case 0n:
      Nil{}
    case 1n+rest:
      NfQuantity{BIR.Erased{}} <> quantity_markers(rest)

# ---------------------------------------------------------------------------
# Materialization: a normal form as a descriptor
# ---------------------------------------------------------------------------

# One structural list walk builds every descriptor: a value's arguments and
# each remaining sibling are direct fields of the value list being matched, so
# the single self-call is decreasing without a budget. A kind already carries
# its materialized quantity (see nf_descriptor_step).
def materialize_all(vals: List<&2, NfVal>) -> List<&2, BIR.Descriptor>:
  match vals:
    case Nil{}:
      Nil{}
    case +val <> rest:
      match val:
        case NfType{key, args}:
          BIR.DescriptorRef{key, materialize_all(args)} <> materialize_all(rest)
        case NfCtor{key, args}:
          BIR.DescriptorConstructor{key, materialize_all(args)} <> materialize_all(rest)
        case NfQuantity{quantity}:
          BIR.DescriptorQuantity{quantity} <> materialize_all(rest)
        case NfKind{quantity}:
          BIR.DescriptorKind{quantity} <> materialize_all(rest)
        case NfOther{source}:
          source <> materialize_all(rest)
        case NfMissing{source}:
          source <> materialize_all(rest)

def materialize(val: NfVal) -> BIR.Descriptor:
  match val:
    case NfType{key, args}:
      BIR.DescriptorRef{key, materialize_all(args)}
    case NfCtor{key, args}:
      BIR.DescriptorConstructor{key, materialize_all(args)}
    case NfQuantity{quantity}:
      BIR.DescriptorQuantity{quantity}
    case NfKind{quantity}:
      BIR.DescriptorKind{quantity}
    case NfOther{source}:
      source
    case NfMissing{source}:
      source

# ---------------------------------------------------------------------------
# Descriptor patterns
# ---------------------------------------------------------------------------

# One structural walk binds every pattern against its value. The self-call on
# constructor fields receives a direct field of the pattern being matched, just
# like the sibling tail; no fuel is involved because every call descends.
def bind_patterns(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, NfVal>) -> Maybe<&2, List<&2, NfVal>>:
  match patterns, values:
    case Nil{}, Nil{}:
      Some{Nil{}}
    case +pattern <> rest, +value <> vrest:
      match pattern:
        case BIR.DescriptorBinder{quantity}:
          match bind_patterns(rest, vrest):
            case Some{bindings}:
              Some{value <> bindings}
            case None{}:
              None{}
        case BIR.DescriptorConstructorPattern{key, fields}:
          match value:
            case NfCtor{known, args}:
              match String.eq(key, known):
                case False{}:
                  None{}
                case True{}:
                  match bind_patterns(fields, args):
                    case Some{bindings}:
                      match bind_patterns(rest, vrest):
                        case Some{tail}:
                          Some{append_vals(bindings, tail)}
                        case None{}:
                          None{}
                    case None{}:
                      None{}
            case _:
              None{}
    case _, _:
      None{}

# ---------------------------------------------------------------------------
# Normalization
# ---------------------------------------------------------------------------

def nf(+context: NfContext, descriptor: BIR.Descriptor, +env: List<&2, NfVal>, +fuel: Nat) -> Nf:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      nf_descriptor(context, descriptor, env, Nat.sub(fuel, 1n))

def nf_descriptor(+context: NfContext, descriptor: BIR.Descriptor, +env: List<&2, NfVal>, +fuel: Nat) -> Nf:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      nf_descriptor_step(context, descriptor, env, fuel)

def nf_descriptor_step(+context: NfContext, descriptor: BIR.Descriptor, +env: List<&2, NfVal>, +fuel: Nat) -> Nf:
  +whole = descriptor
  match whole:
    case BIR.DescriptorNull{}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorParameter{index}:
      NfOk{val_at(env, index, whole)}
    case BIR.DescriptorQuantityKind{}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorQuantity{quantity}:
      NfOk{NfQuantity{quantity}}
    case BIR.DescriptorKind{quantity}:
      match nf(context, quantity, env, fuel):
        case NfOk{val}:
          NfOk{NfKind{materialize(val)}}
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorMinimum{left, right}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorArrow{use, domain, body}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorLambda{use, body}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorRef{key, args}:
      match nf_all(context, args, env, fuel):
        case NfListOk{vals}:
          nf_named(context, key, vals, fuel)
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorConstructor{key, args}:
      match nf_all(context, args, env, fuel):
        case NfListOk{vals}:
          NfOk{NfCtor{key, vals}}
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorApplication{fn, arg}:
      match nf(context, fn, env, fuel):
        case NfOk{val}:
          match nf(context, arg, env, fuel):
            case NfOk{argument}:
              nf_apply(context, val, [argument], fuel)
            case NfFail{message}:
              NfFail{message}
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorSubstitution{index, value, body}:
      match nf(context, value, env, fuel):
        case NfOk{val}:
          nf_descriptor(context, body, insert_before(env, Nat.sub(List.length(&2, NfVal, env), index), val), Nat.sub(fuel, 1n))
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorLet{values, body}:
      match nf_all(context, values, env, fuel):
        case NfListOk{vals}:
          nf_descriptor(context, body, List.append(&2, NfVal, env, vals), Nat.sub(fuel, 1n))
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorLocal{patterns, values, body}:
      match nf_all(context, values, env, fuel):
        case NfListOk{vals}:
          match bind_patterns(patterns, vals):
            case Some{bindings}:
              nf_descriptor(context, body, List.append(&2, NfVal, env, bindings), Nat.sub(fuel, 1n))
            case None{}:
              NfOk{NfOther{whole}}
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorMatch{values, cases}:
      match nf_all(context, values, env, fuel):
        case NfListOk{vals}:
          nf_cases(context, cases, vals, env, whole, fuel)
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorCase{patterns, body}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorBind{value, body}:
      match nf(context, value, env, fuel):
        case NfOk{val}:
          nf_descriptor(context, body, List.append(&2, NfVal, env, [val]), Nat.sub(fuel, 1n))
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorEquality{left, right, ty}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorReflexivity{}:
      NfOk{NfOther{whole}}
    case BIR.DescriptorFailure{message}:
      NfFail{message}
    case BIR.DescriptorFill{head, args}:
      nf_apply_args(context, head, args, env, whole, fuel)
    case BIR.DescriptorPlus{head, args}:
      nf_apply_args(context, head, args, env, whole, fuel)
    case BIR.DescriptorNamedFill{key, head, args}:
      match nf_all(context, args, env, fuel):
        case NfListOk{vals}:
          nf_named(context, key, vals, fuel)
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorNamedPlus{key, head, args}:
      match nf_all(context, args, env, fuel):
        case NfListOk{vals}:
          nf_named(context, key, vals, fuel)
        case NfListFail{message}:
          NfFail{message}

def nf_all(+context: NfContext, descriptors: List<&2, BIR.Descriptor>, +env: List<&2, NfVal>, +fuel: Nat) -> NfList:
  match descriptors:
    case Nil{}:
      NfListOk{Nil{}}
    case +descriptor <> rest:
      match nf(context, descriptor, env, fuel):
        case NfFail{message}:
          NfListFail{message}
        case NfOk{val}:
          match nf_all(context, rest, env, fuel):
            case NfListFail{message}:
              NfListFail{message}
            case NfListOk{vals}:
              NfListOk{val <> vals}

def nf_apply_args(+context: NfContext, head: BIR.Descriptor, args: List<&2, BIR.Descriptor>, +env: List<&2, NfVal>, source: BIR.Descriptor, +fuel: Nat) -> Nf:
  match nf(context, head, env, fuel):
    case NfFail{message}:
      NfFail{message}
    case NfOk{val}:
      match nf_all(context, args, env, fuel):
        case NfListFail{message}:
          NfFail{message}
        case NfListOk{vals}:
          nf_apply_source(context, val, vals, source, fuel)

def nf_apply_source(+context: NfContext, val: NfVal, args: List<&2, NfVal>, source: BIR.Descriptor, +fuel: Nat) -> Nf:
  match args:
    case Nil{}:
      NfOk{val}
    case _:
      nf_apply(context, val, args, fuel)

def nf_apply(+context: NfContext, val: NfVal, args: List<&2, NfVal>, +fuel: Nat) -> Nf:
  match args:
    case Nil{}:
      NfOk{val}
    case +arg <> rest:
      match nf_apply_one(context, val, arg, Nat.sub(fuel, 1n)):
        case NfFail{message}:
          NfFail{message}
        case NfOk{next}:
          nf_apply(context, next, rest, Nat.sub(fuel, 1n))

def nf_apply_one(+context: NfContext, val: NfVal, arg: NfVal, +fuel: Nat) -> Nf:
  match val:
    case NfType{key, args}:
      nf_named(context, key, List.append(&2, NfVal, args, [arg]), Nat.sub(fuel, 1n))
    case NfCtor{key, args}:
      NfOk{NfOther{BIR.DescriptorNull{}}}
    case NfQuantity{quantity}:
      NfOk{NfOther{BIR.DescriptorNull{}}}
    case NfKind{quantity}:
      NfOk{NfOther{BIR.DescriptorNull{}}}
    case NfOther{source}:
      NfOk{NfOther{BIR.DescriptorApplication{source, materialize(arg)}}}
    case NfMissing{source}:
      NfOk{NfMissing{BIR.DescriptorApplication{source, materialize(arg)}}}

# A named type with the arguments it has: a type function reduces once it is
# fully applied, a datatype keeps its arguments, and a name that is neither is
# an abstract type expression, which no consumer may fail on.
def intrinsic_io(+function: BIR.TypeFunction) -> Bool:
  match function:
    case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
      match native:
        case Some{"IO"}: True{}
        case _: False{}

def nf_named_io(is_io: Bool, +context: NfContext, function: BIR.TypeFunction, args: List<&2, NfVal>, +fuel: Nat) -> Nf:
  match is_io:
    case True{}:
      match function:
        case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
          NfOk{NfType{key, args}}
    case False{}:
      nf_reduce(context, function, args, Nat.sub(fuel, 1n))

def nf_named(+context: NfContext, +key: String, args: List<&2, NfVal>, +fuel: Nat) -> Nf:
  match context:
    case NfContext{families, type_functions}:
      match function_of(key, type_functions):
        case Some{function}:
          +work = function
          nf_named_io(intrinsic_io(work), context, work, args, fuel)
        case None{}:
          match family_of(key, families):
            case Some{family}:
              nf_family(family, args)
            case None{}:
              NfOk{NfType{key, args}}

def nf_arity(+args: List<&2, NfVal>, +quantity_prefix: Nat, +arity: Nat) -> NfArity:
  NfArity{Nat.is_eq(Nat.add(List.length(&2, NfVal, args), quantity_prefix), arity), Nat.is_eq(List.length(&2, NfVal, args), arity), Nat.is_lt(List.length(&2, NfVal, args), arity)}

def nf_family(family: BIR.Family, args: List<&2, NfVal>) -> Nf:
  +work = args
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      +prefix = quantity_prefix
      nf_family_apply(nf_arity(work, prefix, arity), key, prefix, work)

def nf_family_apply(decision: NfArity, key: String, quantity_prefix: Nat, args: List<&2, NfVal>) -> Nf:
  match decision:
    case NfArity{complete, exact, under}:
      match complete:
        case True{}:
          NfOk{NfType{key, List.append(&2, NfVal, quantity_markers(quantity_prefix), args)}}
        case False{}:
          match exact:
            case True{}:
              NfOk{NfType{key, args}}
            case False{}:
              match under:
                case True{}:
                  NfOk{NfType{key, args}}
                case False{}:
                  NfFail{String.append("the type `", String.append(key, "` is applied past its declared parameter count"))}

def nf_reduce(+context: NfContext, function: BIR.TypeFunction, args: List<&2, NfVal>, +fuel: Nat) -> Nf:
  +work = args
  match function:
    case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
      +prefix = quantity_prefix
      +fixed_arity = arity
      nf_reduce_apply(nf_arity(work, prefix, fixed_arity), context, key, prefix, fixed_arity, body, work, fuel)

def nf_reduce_apply(decision: NfArity, +context: NfContext, key: String, quantity_prefix: Nat, +arity: Nat, body: BIR.Descriptor, +args: List<&2, NfVal>, +fuel: Nat) -> Nf:
  match decision:
    case NfArity{complete, exact, under}:
      match complete:
        case True{}:
          nf_reduce_body(context, body, List.append(&2, NfVal, quantity_markers(quantity_prefix), args), Nil{}, Nat.sub(fuel, 1n))
        case False{}:
          match exact:
            case True{}:
              nf_reduce_body(context, body, first_vals(args, arity), drop_vals(args, arity), Nat.sub(fuel, 1n))
            case False{}:
              match under:
                case True{}:
                  NfOk{NfType{key, args}}
                case False{}:
                  NfFail{String.append("the type function `", String.append(key, "` is applied past its declared parameter count"))}

def nf_reduce_body(+context: NfContext, body: BIR.Descriptor, +env: List<&2, NfVal>, extra: List<&2, NfVal>, +fuel: Nat) -> Nf:
  match nf_descriptor(context, body, env, Nat.sub(fuel, 1n)):
    case NfFail{message}:
      NfFail{message}
    case NfOk{val}:
      nf_apply(context, val, extra, fuel)

def nf_cases(+context: NfContext, cases: List<&2, BIR.Descriptor>, +values: List<&2, NfVal>, +env: List<&2, NfVal>, source: BIR.Descriptor, +fuel: Nat) -> Nf:
  match cases:
    case Nil{}:
      NfOk{NfOther{source}}
    case +case_body <> rest:
      match case_body:
        case BIR.DescriptorCase{patterns, body}:
          match bind_patterns(patterns, values):
            case Some{bindings}:
              nf_descriptor(context, body, List.append(&2, NfVal, env, bindings), Nat.sub(fuel, 1n))
            case None{}:
              nf_cases(context, rest, values, env, source, fuel)
        case BIR.DescriptorFailure{message}:
          NfFail{message}
        case _:
          NfFail{"descriptor match case is not a case"}

# The normalized descriptor for a checked type expression. A reduction that
# cannot be performed becomes DescriptorFailure, so a consumer that replaces a
# stored field with this result can never silently lose the failure.
def normalize(+context: NfContext, descriptor: BIR.Descriptor, +env: List<&2, NfVal>, +fuel: Nat) -> BIR.Descriptor:
  match nf(context, descriptor, env, fuel):
    case NfFail{message}:
      BIR.DescriptorFailure{message}
    case NfOk{val}:
      materialize(val)

def normalize_closed(families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, descriptor: BIR.Descriptor) -> BIR.Descriptor:
  normalize(nf_context(families, type_functions), descriptor, Nil{}, 1024n)

# One context for a whole annotation pass: build it once, normalize every
# stored field through it. Rebuilding the indexes per field is pure but O(n^2).
def normalize_in(+context: NfContext, descriptor: BIR.Descriptor) -> BIR.Descriptor:
  normalize(context, descriptor, Nil{}, 1024n)

# The outer named application of a checked descriptor, with the arguments it
# is applied to: the head the effect-answer rule needs. The walk reads the
# descriptor under borrow and accumulates the arguments of each wrapper it
# opens, so the recursive call always receives a direct field of the matched
# descriptor: one structural definition, no mutual component.
def outer_application(+descriptor: BIR.Descriptor) -> Maybe<&2, NfApp>:
  outer_walk(descriptor, Nil{})

def outer_walk(+descriptor: BIR.Descriptor, extra: List<&2, BIR.Descriptor>) -> Maybe<&2, NfApp>:
  match descriptor:
    case BIR.DescriptorRef{key, args}:
      Some{NfApp{key, List.append(&2, BIR.Descriptor, args, extra)}}
    case BIR.DescriptorNamedFill{key, head, args}:
      Some{NfApp{key, List.append(&2, BIR.Descriptor, args, extra)}}
    case BIR.DescriptorNamedPlus{key, head, args}:
      Some{NfApp{key, List.append(&2, BIR.Descriptor, args, extra)}}
    case BIR.DescriptorFill{head, args}:
      outer_walk(head, List.append(&2, BIR.Descriptor, args, extra))
    case BIR.DescriptorPlus{head, args}:
      outer_walk(head, List.append(&2, BIR.Descriptor, args, extra))
    case BIR.DescriptorApplication{fn, arg}:
      outer_walk(fn, List.append(&2, BIR.Descriptor, [arg], extra))
    case _:
      None{}

# The type a foreign request's continuation receives: an application of the
# base library's IO former answers its first argument, and every other type
# answers itself. This is the reference runtime's effect-answer rule, keyed by
# the former's native marker rather than by its spelling. The answer decision
# reads the prebuilt pass indexes; the normalized descriptor stays authoritative.
def answer_in(+context: NfContext, result: BIR.Descriptor) -> BIR.Descriptor:
  normalized = normalize(context, result, Nil{}, 1024n)
  match normalized:
    case BIR.DescriptorFailure{_}:
      normalized
    case _:
      answer_normalized(context, normalized)

def answer_descriptor(result: BIR.Descriptor, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  answer_in(nf_context(families, type_functions), result)

def answer_normalized(+context: NfContext, +result: BIR.Descriptor) -> BIR.Descriptor:
  match outer_application(result):
    case None{}:
      result
    case Some{app}:
      match app:
        case NfApp{key, args}:
          match is_io_head_in(context, key):
            case False{}:
              result
            case True{}:
              match args:
                case Nil{}:
                  result
                case +first <> rest:
                  first

def is_io_head_in(+context: NfContext, +key: String) -> Bool:
  match context:
    case NfContext{families, type_functions}:
      is_io_head(key, families, type_functions)

def is_io_head(+key: String, +families: Map<&2, BIR.Family>, +type_functions: Map<&2, BIR.TypeFunction>) -> Bool:
  match native_of(key, families, type_functions):
    case Some{marker}:
      String.eq(marker, "IO")
    case None{}:
      False{}
