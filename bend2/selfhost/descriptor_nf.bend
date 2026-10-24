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

# A normalized type expression. NfType is a named type applied to the
# arguments it has so far; NfCtor is a value constructor applied to values,
# which a type-level match may inspect; NfQuantity and NfKind are the
# quantity and kind language, which no target reads; NfOther is any other
# term (a function, a proof, a hole), kept as its own descriptor; NfMissing
# is a binder with no value in scope, kept as its own descriptor.
type NfVal is Data:
  NfType{key: String, args: List<&2, NfVal>}
  NfCtor{key: String, args: List<&2, NfVal>}
  NfQuantity{quantity: BIR.Quantity}
  NfKind{quantity: NfVal}
  NfOther{source: BIR.Descriptor}
  NfMissing{source: BIR.Descriptor}

type Nf is Data:
  NfOk{val: NfVal}
  NfFail{message: String}

type NfList is Data:
  NfListOk{vals: List<&2, NfVal>}
  NfListFail{message: String}

type NfContext is Data:
  NfContext{families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>}

# An outer named application: the key and the arguments applied to it.
type NfApp is Data:
  NfApp{key: String, args: List<&2, BIR.Descriptor>}

def nf_context(families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> NfContext:
  NfContext{families, type_functions}

def default_fuel() -> Nat:
  1024n

# ---------------------------------------------------------------------------
# Lookup: exact canonical keys only
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

def native_of(key: String, families: List<&2, BIR.Family>, functions: List<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
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

def val_nth(env: List<&2, NfVal>, at: Nat) -> NfVal:
  match at, env:
    case 0n, +val <> rest:
      val
    case 1n+prev, +val <> rest:
      val_nth(rest, prev)
    case _, _:
      NfMissing{BIR.DescriptorNull{}}

def val_at(env: List<&2, NfVal>, index: Nat, source: BIR.Descriptor) -> NfVal:
  count = List.length(&2, NfVal, env)
  match Nat.is_lt(index, count):
    case True{}:
      val_nth(env, Nat.sub(Nat.sub(count, 1n), index))
    case False{}:
      NfMissing{source}

def first_vals(vals: List<&2, NfVal>, count: Nat) -> List<&2, NfVal>:
  match count, vals:
    case 0n, _:
      Nil{}
    case _, Nil{}:
      Nil{}
    case 1n+rest, +val <> tail:
      val <> first_vals(tail, rest)

def drop_vals(vals: List<&2, NfVal>, count: Nat) -> List<&2, NfVal>:
  match count, vals:
    case 0n, _:
      vals
    case _, Nil{}:
      Nil{}
    case 1n+rest, +val <> tail:
      drop_vals(tail, rest)

def insert_before(vals: List<&2, NfVal>, at: Nat, val: NfVal) -> List<&2, NfVal>:
  match at, vals:
    case 0n, _:
      val <> vals
    case 1n+prev, Nil{}:
      insert_before(Nil{}, prev, val)
    case 1n+prev, +head <> rest:
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
# Normalization
# ---------------------------------------------------------------------------

def nf(context: NfContext, descriptor: BIR.Descriptor, env: List<&2, NfVal>, fuel: Nat) -> Nf:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      NfOk{NfOther{descriptor}}
    case False{}:
      nf_descriptor(context, descriptor, env, Nat.sub(fuel, 1n))

def nf_descriptor(context: NfContext, descriptor: BIR.Descriptor, env: List<&2, NfVal>, fuel: Nat) -> Nf:
  match descriptor:
    case BIR.DescriptorNull{}:
      NfOk{NfOther{descriptor}}
    case BIR.DescriptorParameter{index}:
      NfOk{val_at(env, index, descriptor)}
    case BIR.DescriptorQuantityKind{}:
      NfOk{NfOther{descriptor}}
    case BIR.DescriptorQuantity{quantity}:
      NfOk{NfQuantity{quantity}}
    case BIR.DescriptorKind{quantity}:
      match nf(context, quantity, env, fuel):
        case NfOk{val}:
          NfOk{NfKind{val}}
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorMinimum{left, right}:
      NfOk{NfOther{descriptor}}
    case BIR.DescriptorArrow{use, domain, body}:
      NfOk{NfOther{descriptor}}
    case BIR.DescriptorLambda{use, body}:
      NfOk{NfOther{descriptor}}
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
          nf_descriptor(context, body, insert_before(env, Nat.sub(List.length(&2, NfVal, env), index), val), fuel)
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorLet{values, body}:
      match nf_all(context, values, env, fuel):
        case NfListOk{vals}:
          nf_descriptor(context, body, List.append(&2, NfVal, env, vals), fuel)
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorLocal{patterns, values, body}:
      match nf_all(context, values, env, fuel):
        case NfListOk{vals}:
          match bind_patterns(patterns, vals, fuel):
            case Some{bindings}:
              nf_descriptor(context, body, List.append(&2, NfVal, env, bindings), fuel)
            case None{}:
              NfOk{NfOther{descriptor}}
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorMatch{values, cases}:
      match nf_all(context, values, env, fuel):
        case NfListOk{vals}:
          nf_cases(context, cases, vals, env, descriptor, fuel)
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorCase{patterns, body}:
      NfOk{NfOther{descriptor}}
    case BIR.DescriptorBind{value, body}:
      match nf(context, value, env, fuel):
        case NfOk{val}:
          nf_descriptor(context, body, List.append(&2, NfVal, env, [val]), fuel)
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorEquality{left, right, ty}:
      NfOk{NfOther{descriptor}}
    case BIR.DescriptorReflexivity{}:
      NfOk{NfOther{descriptor}}
    case BIR.DescriptorFailure{message}:
      NfFail{message}
    case BIR.DescriptorFill{head, args}:
      nf_apply_args(context, head, args, env, descriptor, fuel)
    case BIR.DescriptorPlus{head, args}:
      nf_apply_args(context, head, args, env, descriptor, fuel)
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

def nf_all(context: NfContext, descriptors: List<&2, BIR.Descriptor>, env: List<&2, NfVal>, fuel: Nat) -> NfList:
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

def nf_apply_args(context: NfContext, head: BIR.Descriptor, args: List<&2, BIR.Descriptor>, env: List<&2, NfVal>, source: BIR.Descriptor, fuel: Nat) -> Nf:
  match nf(context, head, env, fuel):
    case NfFail{message}:
      NfFail{message}
    case NfOk{val}:
      match nf_all(context, args, env, fuel):
        case NfListFail{message}:
          NfFail{message}
        case NfListOk{vals}:
          nf_apply_source(context, val, vals, source, fuel)

def nf_apply_source(context: NfContext, val: NfVal, args: List<&2, NfVal>, source: BIR.Descriptor, fuel: Nat) -> Nf:
  match args:
    case Nil{}:
      NfOk{val}
    case _:
      nf_apply(context, val, args, fuel)

def nf_apply(context: NfContext, val: NfVal, args: List<&2, NfVal>, fuel: Nat) -> Nf:
  match args:
    case Nil{}:
      NfOk{val}
    case +arg <> rest:
      match nf_apply_one(context, val, arg, fuel):
        case NfFail{message}:
          NfFail{message}
        case NfOk{next}:
          nf_apply(context, next, rest, fuel)

def nf_apply_one(context: NfContext, val: NfVal, arg: NfVal, fuel: Nat) -> Nf:
  match val:
    case NfType{key, args}:
      nf_named(context, key, List.append(&2, NfVal, args, [arg]), fuel)
    case NfCtor{key, args}:
      NfOk{NfOther{BIR.DescriptorNull{}}}
    case NfQuantity{quantity}:
      NfOk{NfOther{BIR.DescriptorNull{}}}
    case NfKind{quantity}:
      NfOk{NfOther{BIR.DescriptorNull{}}}
    case NfOther{source}:
      NfOk{val}
    case NfMissing{source}:
      NfOk{val}

# A named type with the arguments it has: a type function reduces once it is
# fully applied, a datatype keeps its arguments, and a name that is neither is
# an abstract type expression, which no consumer may fail on.
def nf_named(context: NfContext, key: String, args: List<&2, NfVal>, fuel: Nat) -> Nf:
  match context:
    case NfContext{families, type_functions}:
      match function_of(key, type_functions):
        case Some{function}:
          match function:
            case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
              match native:
                case Some{"IO"}:
                  NfOk{NfType{key, args}}
                case _:
                  nf_reduce(context, function, args, Nat.sub(fuel, 1n))
        case None{}:
          match family_of(key, families):
            case Some{family}:
              nf_family(family, args)
            case None{}:
              NfOk{NfType{key, args}}

def nf_family(family: BIR.Family, args: List<&2, NfVal>) -> Nf:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      count = List.length(&2, NfVal, args)
      match Nat.is_eq(Nat.add(count, quantity_prefix), arity):
        case True{}:
          NfOk{NfType{key, List.append(&2, NfVal, quantity_markers(quantity_prefix), args)}}
        case False{}:
          match Nat.is_eq(count, arity):
            case True{}:
              NfOk{NfType{key, args}}
            case False{}:
              match Nat.is_lt(count, arity):
                case True{}:
                  NfOk{NfType{key, args}}
                case False{}:
                  NfFail{String.append("the type `", String.append(key, "` is applied past its declared parameter count"))}

def nf_reduce(context: NfContext, function: BIR.TypeFunction, args: List<&2, NfVal>, fuel: Nat) -> Nf:
  match function:
    case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
      count = List.length(&2, NfVal, args)
      match Nat.is_lt(count, arity):
        case True{}:
          NfOk{NfType{key, args}}
        case False{}:
          match Nat.is_eq(Nat.add(count, quantity_prefix), arity):
            case True{}:
              nf_reduce_body(context, body, List.append(&2, NfVal, quantity_markers(quantity_prefix), args), Nil{}, fuel)
            case False{}:
              nf_reduce_body(context, body, first_vals(args, arity), drop_vals(args, arity), fuel)

def nf_reduce_body(context: NfContext, body: BIR.Descriptor, env: List<&2, NfVal>, extra: List<&2, NfVal>, fuel: Nat) -> Nf:
  match nf_descriptor(context, body, env, fuel):
    case NfFail{message}:
      NfFail{message}
    case NfOk{val}:
      nf_apply(context, val, extra, fuel)

def nf_cases(context: NfContext, cases: List<&2, BIR.Descriptor>, values: List<&2, NfVal>, env: List<&2, NfVal>, source: BIR.Descriptor, fuel: Nat) -> Nf:
  match cases:
    case Nil{}:
      NfOk{NfOther{source}}
    case +case_body <> rest:
      match case_body:
        case BIR.DescriptorCase{patterns, body}:
          match bind_patterns(patterns, values, fuel):
            case Some{bindings}:
              nf_descriptor(context, body, List.append(&2, NfVal, env, bindings), fuel)
            case None{}:
              nf_cases(context, rest, values, env, source, fuel)

# ---------------------------------------------------------------------------
# Descriptor patterns
# ---------------------------------------------------------------------------

def bind_patterns(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, NfVal>, fuel: Nat) -> Maybe<&2, List<&2, NfVal>>:
  match Nat.is_eq(fuel, 0n):
    case True{}:
      None{}
    case False{}:
      bind_patterns_go(patterns, values, Nil{}, Nat.sub(fuel, 1n))

def bind_patterns_go(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, NfVal>, acc: List<&2, NfVal>, fuel: Nat) -> Maybe<&2, List<&2, NfVal>>:
  match patterns, values:
    case Nil{}, Nil{}:
      Some{acc}
    case +pattern <> prest, +value <> vrest:
      match bind_pattern(pattern, value, fuel):
        case Some{bindings}:
          bind_patterns_go(prest, vrest, append_vals(acc, bindings), fuel)
        case None{}:
          None{}
    case _, _:
      None{}

def bind_pattern(pattern: BIR.DescriptorPattern, value: NfVal, fuel: Nat) -> Maybe<&2, List<&2, NfVal>>:
  match pattern:
    case BIR.DescriptorBinder{quantity}:
      Some{[value]}
    case BIR.DescriptorConstructorPattern{key, fields}:
      match value:
        case NfCtor{known, args}:
          match String.eq(key, known):
            case False{}:
              None{}
            case True{}:
              bind_patterns(fields, args, fuel)
        case _:
          None{}

# ---------------------------------------------------------------------------
# Materialization: a normal form as a descriptor
# ---------------------------------------------------------------------------

def materialize(val: NfVal) -> BIR.Descriptor:
  match val:
    case NfType{key, args}:
      BIR.DescriptorRef{key, materialize_all(args)}
    case NfCtor{key, args}:
      BIR.DescriptorConstructor{key, materialize_all(args)}
    case NfQuantity{quantity}:
      BIR.DescriptorQuantity{quantity}
    case NfKind{quantity}:
      BIR.DescriptorKind{materialize(quantity)}
    case NfOther{source}:
      source
    case NfMissing{source}:
      source

def materialize_all(vals: List<&2, NfVal>) -> List<&2, BIR.Descriptor>:
  match vals:
    case Nil{}:
      Nil{}
    case +val <> rest:
      materialize(val) <> materialize_all(rest)

# The normalized descriptor for a checked type expression. A reduction that
# cannot be performed becomes DescriptorFailure, so a consumer that replaces a
# stored field with this result can never silently lose the failure.
def normalize(context: NfContext, descriptor: BIR.Descriptor, env: List<&2, NfVal>, fuel: Nat) -> BIR.Descriptor:
  match nf(context, descriptor, env, fuel):
    case NfFail{message}:
      BIR.DescriptorFailure{message}
    case NfOk{val}:
      materialize(val)

def normalize_closed(families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, descriptor: BIR.Descriptor) -> BIR.Descriptor:
  normalize(nf_context(families, type_functions), descriptor, Nil{}, default_fuel())

# The outer named application of a checked descriptor, with the arguments it
# is applied to: the head the effect-answer rule needs.
def outer_application(descriptor: BIR.Descriptor) -> Maybe<&2, NfApp>:
  match descriptor:
    case BIR.DescriptorRef{key, args}:
      Some{NfApp{key, args}}
    case BIR.DescriptorNamedFill{key, head, args}:
      Some{NfApp{key, args}}
    case BIR.DescriptorNamedPlus{key, head, args}:
      Some{NfApp{key, args}}
    case BIR.DescriptorFill{head, args}:
      outer_filled(head, args)
    case BIR.DescriptorPlus{head, args}:
      outer_filled(head, args)
    case BIR.DescriptorApplication{fn, arg}:
      outer_applied(fn, arg)
    case _:
      None{}

def outer_filled(head: BIR.Descriptor, extra: List<&2, BIR.Descriptor>) -> Maybe<&2, NfApp>:
  match outer_application(head):
    case Some{app}:
      match app:
        case NfApp{key, args}:
          Some{NfApp{key, List.append(&2, BIR.Descriptor, args, extra)}}
    case None{}:
      None{}

def outer_applied(fn: BIR.Descriptor, arg: BIR.Descriptor) -> Maybe<&2, NfApp>:
  match outer_application(fn):
    case Some{app}:
      match app:
        case NfApp{key, args}:
          Some{NfApp{key, List.append(&2, BIR.Descriptor, args, [arg])}}
    case None{}:
      None{}

# The type a foreign request's continuation receives: an application of the
# base library's IO former answers its first argument, and every other type
# answers itself. This is the reference runtime's effect-answer rule, keyed by
# the former's native marker rather than by its spelling.
def answer_descriptor(result: BIR.Descriptor, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  match outer_application(result):
    case None{}:
      result
    case Some{app}:
      match app:
        case NfApp{key, args}:
          match is_io_head(key, families, type_functions):
            case False{}:
              result
            case True{}:
              match args:
                case Nil{}:
                  result
                case +first <> rest:
                  first

def is_io_head(key: String, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> Bool:
  match native_of(key, families, type_functions):
    case Some{marker}:
      String.eq(marker, "IO")
    case None{}:
      False{}

# ---------------------------------------------------------------------------
# Canonical text, for sharing a normalized descriptor across uses
# ---------------------------------------------------------------------------

def descriptor_key(descriptor: BIR.Descriptor) -> String:
  match descriptor:
    case BIR.DescriptorNull{}:
      "-"
    case BIR.DescriptorParameter{index}:
      String.append("p", Nat.show(index))
    case BIR.DescriptorRef{key, args}:
      String.append("r", String.append(key, String.append("(", String.append(descriptor_keys(args), ")"))))
    case BIR.DescriptorQuantityKind{}:
      "qk"
    case BIR.DescriptorQuantity{quantity}:
      String.append("q", quantity_key(quantity))
    case BIR.DescriptorKind{quantity}:
      String.append("kind(", String.append(descriptor_key(quantity), ")"))
    case BIR.DescriptorMinimum{left, right}:
      String.append("min(", String.append(descriptor_key(left), String.append(",", String.append(descriptor_key(right), ")"))))
    case BIR.DescriptorArrow{use, domain, body}:
      String.append("all(", String.append(descriptor_key(domain), String.append(",", String.append(descriptor_key(body), ")"))))
    case BIR.DescriptorLambda{use, body}:
      String.append("lam(", String.append(descriptor_key(body), ")"))
    case BIR.DescriptorConstructor{key, args}:
      String.append("c", String.append(key, String.append("(", String.append(descriptor_keys(args), ")"))))
    case BIR.DescriptorApplication{fn, arg}:
      String.append("app(", String.append(descriptor_key(fn), String.append(",", String.append(descriptor_key(arg), ")"))))
    case BIR.DescriptorSubstitution{index, value, body}:
      String.append("sub(", String.append(Nat.show(index), String.append(",", String.append(descriptor_key(body), ")"))))
    case BIR.DescriptorLet{values, body}:
      String.append("let(", String.append(descriptor_key(body), ")"))
    case BIR.DescriptorLocal{patterns, values, body}:
      String.append("local(", String.append(descriptor_key(body), ")"))
    case BIR.DescriptorMatch{values, cases}:
      String.append("mat(", String.append(descriptor_keys(values), ")"))
    case BIR.DescriptorCase{patterns, body}:
      String.append("case(", String.append(descriptor_key(body), ")"))
    case BIR.DescriptorBind{value, body}:
      String.append("bind(", String.append(descriptor_key(body), ")"))
    case BIR.DescriptorEquality{left, right, ty}:
      String.append("eq(", String.append(descriptor_key(left), String.append(",", String.append(descriptor_key(right), ")"))))
    case BIR.DescriptorReflexivity{}:
      "refl"
    case BIR.DescriptorFailure{message}:
      String.append("fail(", message)
    case BIR.DescriptorFill{head, args}:
      String.append("fill(", String.append(descriptor_key(head), ")"))
    case BIR.DescriptorPlus{head, args}:
      String.append("plus(", String.append(descriptor_key(head), ")"))
    case BIR.DescriptorNamedFill{key, head, args}:
      String.append("nfill(", String.append(key, ")"))
    case BIR.DescriptorNamedPlus{key, head, args}:
      String.append("nplus(", String.append(key, ")"))

def descriptor_keys(descriptors: List<&2, BIR.Descriptor>) -> String:
  match descriptors:
    case Nil{}:
      ""
    case +descriptor <> rest:
      String.append(descriptor_key(descriptor), descriptor_keys_rest(rest))

def descriptor_keys_rest(descriptors: List<&2, BIR.Descriptor>) -> String:
  match descriptors:
    case Nil{}:
      ""
    case +descriptor <> rest:
      String.append(",", String.append(descriptor_key(descriptor), descriptor_keys_rest(rest)))

def quantity_key(quantity: BIR.Quantity) -> String:
  match quantity:
    case BIR.Erased{}:
      "0"
    case BIR.Once{}:
      "1"
    case BIR.Unrestricted{}:
      "2"

def nf_key(val: NfVal) -> String:
  match val:
    case NfType{key, args}:
      String.append("t", String.append(key, String.append("(", String.append(nf_keys(args), ")"))))
    case NfCtor{key, args}:
      String.append("c", String.append(key, String.append("(", String.append(nf_keys(args), ")"))))
    case NfQuantity{quantity}:
      String.append("q", quantity_key(quantity))
    case NfKind{quantity}:
      String.append("k(", String.append(nf_key(quantity), ")"))
    case NfOther{source}:
      descriptor_key(source)
    case NfMissing{source}:
      descriptor_key(source)

def nf_keys(vals: List<&2, NfVal>) -> String:
  match vals:
    case Nil{}:
      ""
    case +val <> rest:
      String.append(nf_key(val), nf_keys_rest(rest))

def nf_keys_rest(vals: List<&2, NfVal>) -> String:
  match vals:
    case Nil{}:
      ""
    case +val <> rest:
      String.append(",", String.append(nf_key(val), nf_keys_rest(rest)))

# Head classification over the same normalizer. It is a projection only: the
# stored Descriptor remains authoritative and is never replaced by a Head.
def head_of_value(context: NfContext, value: NfVal) -> BIR.Head:
  match context:
    case NfContext{families, type_functions}:
      head_of_value_in(families, type_functions, value)

def head_of_value_in(families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, value: NfVal) -> BIR.Head:
  match value:
    case NfType{key, args}:
      match family_of(key, families):
        case Some{family}:
          match family:
            case BIR.Family{_, _, native, _, _, _}: BIR.HeadKnown{key, native}
        case None{}:
          match function_of(key, type_functions):
            case Some{_}: BIR.HeadAbstract{}
            case None{}: BIR.HeadOther{}
    case NfCtor{_, _}: BIR.HeadOther{}
    case NfQuantity{_}: BIR.HeadOther{}
    case NfKind{_}: BIR.HeadOther{}
    case NfOther{_}: BIR.HeadOther{}
    case NfMissing{_}: BIR.HeadAbstract{}

def head_of_result(context: NfContext, result: Nf) -> BIR.Head:
  match result:
    case NfOk{value}: head_of_value(context, value)
    case NfFail{message}: BIR.HeadMissing{message}

def canonical_head(descriptor: BIR.Descriptor, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> BIR.Head:
  context = nf_context(families, type_functions)
  head_of_result(context, nf(context, descriptor, Nil{}, default_fuel()))

# The IO answer classification uses the full normalized application arguments
# before truncating to a Head: IO(Nat) after alias reduction yields Nat.
def canonical_answer_head(descriptor: BIR.Descriptor, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> BIR.Head:
  context = nf_context(families, type_functions)
  match nf(context, descriptor, Nil{}, default_fuel()):
    case NfOk{NfType{key, args}}:
      match native_of(key, families, type_functions):
        case Some{"IO"}:
          match args:
            case +arg <> _: head_of_value(context, arg)
            case Nil{}: BIR.HeadOther{}
        case _: BIR.HeadOther{}
    case NfOk{_}: BIR.HeadOther{}
    case NfFail{message}: BIR.HeadMissing{message}
