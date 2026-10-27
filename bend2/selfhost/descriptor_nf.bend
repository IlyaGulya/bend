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
#     alias of Nat or IO resolves to what it names. The one exception is the
#     base IO intrinsic, whose head and arguments are preserved without
#     unfolding, exactly like the runtime's `$type_named` marking IO;
#   * a lambda is a closure over the environment where it appears, exactly
#     like the runtime's `{k:"L", body, env}`: applying it evaluates its body
#     with the argument appended, so a positive beta reduces and a captured
#     higher-order alias keeps its captures; an unapplied closure materializes
#     as a let binding the captured environment around its lambda, so the
#     captures evaluate in the environment where the lambda was written and
#     its own argument stays abstract at 0;
#   * an application to too few arguments is abstract; an application past a
#     family's or type function's parameter count, and an application of an
#     argument to a constructor, quantity or kind value, is a reducer failure
#     (the runtime refuses to apply a non-function);
#   * substitution, let, local, bind and match are the descriptor language's
#     scoping forms; a match binds its constructor patterns and evaluates its
#     body in the extended environment. A case whose patterns definitely
#     mismatch lets the next case run; a case that cannot be decided because
#     its scrutinee is not yet a constructor value makes the whole match
#     abstract, so a later binder never masks an unknown earlier case;
#   * an arrow is a binder: the parser and the checker both put one more binder
#     in scope for the body (checker `infer_all_domain` binds the arrow, and
#     `lookup` counts `depth + 1` inside the codomain), so the published body
#     names the arrow's own argument at index 0 and an enclosing binder one
#     index higher than the domain does. Its domain therefore normalizes under
#     the current environment and its body under that environment extended by
#     one abstract binder for the arrow's argument. Evaluating the body in the
#     unextended environment would both drop the enclosing argument a body
#     reference names and capture the outer last argument for the arrow's own
#     binder. The arrow keeps its shape, and the abstract binder materializes
#     back as the parameter index that names it in the body it appears in. A
#     match that reaches no case keeps its normalized scrutinees and its
#     original cases as the abstract form;
#   * a name that is neither a family nor a type function is an abstract type
#     expression (an opaque law such as Chan or File), so it is kept as it is,
#     not a failure: checking already accepted it.
#
# Reduction is bounded by a fuel counter and terminates on its own; when the
# bound runs out the expression is a reducer failure (DescriptorFailure), never
# a silent abstract type. A reduction that cannot be performed at all (an
# over-applied family, an invalid application, a DescriptorFailure) is NfFail,
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
# second traversal with its own budget); NfOther is any other term (a proof,
# a hole, an abstract application), kept as its own descriptor; NfMissing is
# a binder with no value in scope, kept as its own descriptor.
#
# NfBinder is an arrow's own binder as a value: it has no argument (an
# unapplied arrow keeps its codomain abstract), and `level` is its position in
# the environment, oldest first. Materializing it under the environment of the
# body it appears in yields the parameter index that names it there, so a body
# that reaches its own arrow's argument at 0 and an enclosing arrow's argument
# one further out keeps both indices exact. It is an abstract form, exactly
# like NfMissing: no consumer may read it as a concrete type.
#
# NfClosure is a lambda value: the runtime's `{k:"L", body, env}`. Its body
# indexes its own future argument at 0 and the captured environment at 1..,
# exactly like the runtime's `$type_apply` appending an argument to `env`.
# `sources` is that environment already materialized, so materializing an
# unapplied closure binds it back with one let around the lambda.
type NfVal is Data:
  NfType{key: String, args: List<&2, NfVal>}
  NfCtor{key: String, args: List<&2, NfVal>}
  NfQuantity{quantity: BIR.Quantity}
  NfKind{quantity: BIR.Descriptor}
  NfOther{source: BIR.Descriptor}
  NfMissing{source: BIR.Descriptor}
  NfBinder{level: Nat}
  NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, NfVal>, sources: List<&2, BIR.Descriptor>}

# One pattern case matched against one scrutinee: bound values, a definite
# mismatch that lets the next case run, or a scrutinee that is not yet a
# constructor value, which makes the whole match abstract. Collapsing the last
# two into "no bindings" is what let a fallback binder mask an unknown
# scrutinee, so they stay separate.
type NfBind is Data:
  NfBound{bindings: List<&2, NfVal>}
  NfMismatch{}
  NfUnknown{}

# Whether one case's pattern list can match: a definite mismatch anywhere in
# the list decides the case even if another scrutinee is still unknown.
type NfStatus is Data:
  NfStatusOk{}
  NfStatusNo{}
  NfStatusMaybe{}
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

# The environment is oldest binder first, so its length is the number of
# binders in scope and the position an arrow binder appended next would take.
# `val_at` already reads index 0 as the last entry; materializing an arrow
# binder needs the same count to turn that position back into an index.
def env_level(+env: List<&2, NfVal>) -> Nat:
  List.length(&2, NfVal, env)

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
#
# `level` is the number of binders of the environment the result is written in,
# which is the length of the environment at the term. It only decides the
# parameter index of an arrow binder: index 0 is the innermost binder and the
# environment's last entry, so a binder at `binder` is `level - binder - 1`
# steps out. Every materialization inside the evaluator supplies its level; the
# level-less entry points are for values whose binders are already parameters.
def materialize_all_at(vals: List<&2, NfVal>, +level: Nat) -> List<&2, BIR.Descriptor>:
  match vals:
    case Nil{}:
      Nil{}
    case +val <> rest:
      match val:
        case NfType{key, args}:
          BIR.DescriptorRef{key, materialize_all_at(args, level)} <> materialize_all_at(rest, level)
        case NfCtor{key, args}:
          BIR.DescriptorConstructor{key, materialize_all_at(args, level)} <> materialize_all_at(rest, level)
        case NfQuantity{quantity}:
          BIR.DescriptorQuantity{quantity} <> materialize_all_at(rest, level)
        case NfKind{quantity}:
          BIR.DescriptorKind{quantity} <> materialize_all_at(rest, level)
        case NfOther{source}:
          source <> materialize_all_at(rest, level)
        case NfMissing{source}:
          source <> materialize_all_at(rest, level)
        case NfBinder{binder}:
          BIR.DescriptorParameter{Nat.sub(level, Nat.add(binder, 1n))} <> materialize_all_at(rest, level)
        case NfClosure{quantity, body, env, sources}:
          BIR.DescriptorLet{sources, BIR.DescriptorLambda{quantity, body}} <> materialize_all_at(rest, level)

def materialize_all(vals: List<&2, NfVal>) -> List<&2, BIR.Descriptor>:
  materialize_all_at(vals, 0n)

def materialize_at(val: NfVal, +level: Nat) -> BIR.Descriptor:
  match val:
    case NfType{key, args}:
      BIR.DescriptorRef{key, materialize_all_at(args, level)}
    case NfCtor{key, args}:
      BIR.DescriptorConstructor{key, materialize_all_at(args, level)}
    case NfQuantity{quantity}:
      BIR.DescriptorQuantity{quantity}
    case NfKind{quantity}:
      BIR.DescriptorKind{quantity}
    case NfOther{source}:
      source
    case NfMissing{source}:
      source
    case NfBinder{binder}:
      BIR.DescriptorParameter{Nat.sub(level, Nat.add(binder, 1n))}
    case NfClosure{quantity, body, env, sources}:
      BIR.DescriptorLet{sources, BIR.DescriptorLambda{quantity, body}}

def materialize(val: NfVal) -> BIR.Descriptor:
  materialize_at(val, 0n)

# An opaque term was normalized under an environment. One let binds that
# environment back around the raw form: its values evaluate where the term was
# written, before any new binder, and the let repeats the environment's shape
# above it, so no parameter index is ever rewritten.
def reify_env(source: BIR.Descriptor, +env: List<&2, NfVal>) -> BIR.Descriptor:
  match env:
    case Nil{}:
      source
    case +value <> rest:
      BIR.DescriptorLet{materialize_all_at(env, env_level(env)), source}
# ---------------------------------------------------------------------------
# Descriptor patterns
# ---------------------------------------------------------------------------

# The status walk visits every pattern, so a known mismatch in a later pattern
# beats an unknown earlier one: patterns [True,True] against [missing,False]
# is a definite no and the next case may run. Bindings are only collected when
# the whole list is a definite yes, which keeps first-match precedence exact.
def status_combine(left: NfStatus, right: NfStatus) -> NfStatus:
  match left:
    case NfStatusNo{}:
      NfStatusNo{}
    case NfStatusMaybe{}:
      match right:
        case NfStatusNo{}: NfStatusNo{}
        case _: NfStatusMaybe{}
    case NfStatusOk{}:
      right

def bind_status(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, NfVal>) -> NfStatus:
  match patterns, values:
    case Nil{}, Nil{}:
      NfStatusOk{}
    case +pattern <> rest, +value <> vrest:
      match pattern:
        case BIR.DescriptorBinder{quantity}:
          bind_status(rest, vrest)
        case BIR.DescriptorConstructorPattern{key, fields}:
          match value:
            case NfCtor{known, args}:
              match String.eq(key, known):
                case False{}:
                  NfStatusNo{}
                case True{}:
                  status_combine(bind_status(fields, args), bind_status(rest, vrest))
            case NfMissing{source}:
              status_combine(NfStatusMaybe{}, bind_status(rest, vrest))
            case NfOther{source}:
              status_combine(NfStatusMaybe{}, bind_status(rest, vrest))
            case NfBinder{binder}:
              status_combine(NfStatusMaybe{}, bind_status(rest, vrest))
            case _:
              NfStatusNo{}
    case _, _:
      NfStatusNo{}

def bind_values(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, NfVal>) -> List<&2, NfVal>:
  match patterns, values:
    case Nil{}, Nil{}:
      Nil{}
    case +pattern <> rest, +value <> vrest:
      match pattern:
        case BIR.DescriptorBinder{quantity}:
          value <> bind_values(rest, vrest)
        case BIR.DescriptorConstructorPattern{key, fields}:
          match value:
            case NfCtor{known, args}:
              append_vals(bind_values(fields, args), bind_values(rest, vrest))
            case _:
              bind_values(rest, vrest)
    case _, _:
      Nil{}

def bind_patterns(patterns: List<&2, BIR.DescriptorPattern>, values: List<&2, NfVal>) -> NfBind:
  match bind_status(patterns, values):
    case NfStatusOk{}:
      NfBound{bind_values(patterns, values)}
    case NfStatusNo{}:
      NfMismatch{}
    case NfStatusMaybe{}:
      NfUnknown{}

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

# An arrow is a binder. The parser parses the codomain at `depth + 1` and the
# checker binds the arrow in the body's environment (`infer_all_domain`), so
# the published body names the arrow's own argument at index 0 and every
# enclosing binder one index further out than the domain names it. The domain
# is evaluated under the current environment; the body is evaluated under that
# environment with one more abstract binder for the arrow's argument, and each
# side is materialized at the level it is written at. The abstract binder comes
# back as the parameter index that names it, so a body that reaches an
# enclosing parameter keeps that parameter and a body that reaches the arrow's
# own argument is never replaced by the outer last argument.
def nf_arrow(+context: NfContext, use: BIR.Quantity, domain: BIR.Descriptor, body: BIR.Descriptor, +env: List<&2, NfVal>, +fuel: Nat) -> Nf:
  +level = env_level(env)
  match nf(context, domain, env, fuel):
    case NfFail{message}:
      NfFail{message}
    case NfOk{domain_val}:
      match nf(context, body, List.append(&2, NfVal, env, [NfBinder{level}]), fuel):
        case NfFail{message}:
          NfFail{message}
        case NfOk{body_val}:
          NfOk{NfOther{BIR.DescriptorArrow{use, materialize_at(domain_val, level), materialize_at(body_val, Nat.add(level, 1n))}}}

def nf_descriptor_step(+context: NfContext, descriptor: BIR.Descriptor, +env: List<&2, NfVal>, +fuel: Nat) -> Nf:
  +whole = descriptor
  +level = env_level(env)
  match whole:
    case BIR.DescriptorNull{}:
      NfOk{NfOther{reify_env(whole, env)}}
    case BIR.DescriptorParameter{index}:
      NfOk{val_at(env, index, whole)}
    case BIR.DescriptorQuantityKind{}:
      NfOk{NfOther{reify_env(whole, env)}}
    case BIR.DescriptorQuantity{quantity}:
      NfOk{NfQuantity{quantity}}
    case BIR.DescriptorKind{quantity}:
      match nf(context, quantity, env, fuel):
        case NfOk{val}:
          NfOk{NfKind{materialize_at(val, level)}}
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorMinimum{left, right}:
      NfOk{NfOther{reify_env(whole, env)}}
    case BIR.DescriptorArrow{use, domain, body}:
      nf_arrow(context, use, domain, body, env, fuel)
    case BIR.DescriptorLambda{use, body}:
      NfOk{NfClosure{use, body, env, materialize_all_at(env, level)}}
    case BIR.DescriptorRef{key, args}:
      match nf_all(context, args, env, fuel):
        case NfListOk{vals}:
          nf_named(context, key, vals, level, fuel)
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
              nf_apply(context, val, [argument], level, fuel)
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
            case NfBound{bindings}:
              nf_descriptor(context, body, List.append(&2, NfVal, env, bindings), Nat.sub(fuel, 1n))
            case _:
              NfOk{NfOther{reify_env(whole, env)}}
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorMatch{values, cases}:
      match nf_all(context, values, env, fuel):
        case NfListOk{vals}:
          nf_cases(context, cases, vals, env, whole, fuel)
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorCase{patterns, body}:
      NfOk{NfOther{reify_env(whole, env)}}
    case BIR.DescriptorBind{value, body}:
      match nf(context, value, env, fuel):
        case NfOk{val}:
          nf_descriptor(context, body, List.append(&2, NfVal, env, [val]), Nat.sub(fuel, 1n))
        case NfFail{message}:
          NfFail{message}
    case BIR.DescriptorEquality{left, right, ty}:
      NfOk{NfOther{reify_env(whole, env)}}
    case BIR.DescriptorReflexivity{}:
      NfOk{NfOther{reify_env(whole, env)}}
    case BIR.DescriptorFailure{message}:
      NfFail{message}
    case BIR.DescriptorFill{head, args}:
      nf_apply_args(context, head, args, env, whole, fuel)
    case BIR.DescriptorPlus{head, args}:
      nf_apply_args(context, head, args, env, whole, fuel)
    case BIR.DescriptorNamedFill{key, head, args}:
      match nf_all(context, args, env, fuel):
        case NfListOk{vals}:
          nf_named(context, key, vals, level, fuel)
        case NfListFail{message}:
          NfFail{message}
    case BIR.DescriptorNamedPlus{key, head, args}:
      match nf_all(context, args, env, fuel):
        case NfListOk{vals}:
          nf_named(context, key, vals, level, fuel)
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
          nf_apply_source(context, val, vals, source, env_level(env), fuel)

def nf_apply_source(+context: NfContext, val: NfVal, args: List<&2, NfVal>, source: BIR.Descriptor, +level: Nat, +fuel: Nat) -> Nf:
  match args:
    case Nil{}:
      NfOk{val}
    case _:
      nf_apply(context, val, args, level, fuel)

# `level` is the environment the argument values were built in. Applying a
# value that must stay abstract materializes its argument descriptor there, so
# an arrow binder inside an argument keeps the index that names it.
def nf_apply(+context: NfContext, val: NfVal, args: List<&2, NfVal>, +level: Nat, +fuel: Nat) -> Nf:
  match args:
    case Nil{}:
      NfOk{val}
    case +arg <> rest:
      match nf_apply_one(context, val, arg, level, Nat.sub(fuel, 1n)):
        case NfFail{message}:
          NfFail{message}
        case NfOk{next}:
          nf_apply(context, next, rest, level, Nat.sub(fuel, 1n))

def nf_apply_one(+context: NfContext, val: NfVal, arg: NfVal, +level: Nat, +fuel: Nat) -> Nf:
  match val:
    case NfType{key, args}:
      nf_named(context, key, List.append(&2, NfVal, args, [arg]), level, Nat.sub(fuel, 1n))
    case NfClosure{quantity, body, env, sources}:
      nf_descriptor(context, body, List.append(&2, NfVal, env, [arg]), Nat.sub(fuel, 1n))
    case NfCtor{key, args}:
      NfFail{String.append("the constructor `", String.append(key, "` is applied to an argument"))}
    case NfQuantity{quantity}:
      NfFail{"a quantity is applied to an argument"}
    case NfKind{quantity}:
      NfFail{"a kind is applied to an argument"}
    case NfOther{source}:
      NfOk{NfOther{BIR.DescriptorApplication{source, materialize_at(arg, level)}}}
    case NfMissing{source}:
      NfOk{NfMissing{BIR.DescriptorApplication{source, materialize_at(arg, level)}}}
    case NfBinder{binder}:
      NfOk{NfMissing{BIR.DescriptorApplication{materialize_at(val, level), materialize_at(arg, level)}}}

# A named type with the arguments it has: a type function reduces once it is
# fully applied, a datatype keeps its arguments, and a name that is neither is
# an abstract type expression, which no consumer may fail on.
def intrinsic_io(+function: BIR.TypeFunction) -> Bool:
  match function:
    case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
      match native:
        case Some{"IO"}: True{}
        case _: False{}

def nf_named_io(is_io: Bool, +context: NfContext, function: BIR.TypeFunction, args: List<&2, NfVal>, +level: Nat, +fuel: Nat) -> Nf:
  match is_io:
    case True{}:
      match function:
        case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
          NfOk{NfType{key, args}}
    case False{}:
      nf_reduce(context, function, args, level, Nat.sub(fuel, 1n))

def nf_named(+context: NfContext, +key: String, args: List<&2, NfVal>, +level: Nat, +fuel: Nat) -> Nf:
  match context:
    case NfContext{families, type_functions}:
      match function_of(key, type_functions):
        case Some{function}:
          +work = function
          nf_named_io(intrinsic_io(work), context, work, args, level, fuel)
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

def nf_reduce(+context: NfContext, function: BIR.TypeFunction, args: List<&2, NfVal>, +level: Nat, +fuel: Nat) -> Nf:
  +work = args
  match function:
    case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
      +prefix = quantity_prefix
      +fixed_arity = arity
      nf_reduce_apply(nf_arity(work, prefix, fixed_arity), context, key, prefix, fixed_arity, body, work, level, fuel)

def nf_reduce_apply(decision: NfArity, +context: NfContext, key: String, quantity_prefix: Nat, +arity: Nat, body: BIR.Descriptor, +args: List<&2, NfVal>, +level: Nat, +fuel: Nat) -> Nf:
  match decision:
    case NfArity{complete, exact, under}:
      match complete:
        case True{}:
          nf_reduce_body(context, body, List.append(&2, NfVal, quantity_markers(quantity_prefix), args), Nil{}, level, Nat.sub(fuel, 1n))
        case False{}:
          match exact:
            case True{}:
              nf_reduce_body(context, body, first_vals(args, arity), drop_vals(args, arity), level, Nat.sub(fuel, 1n))
            case False{}:
              match under:
                case True{}:
                  NfOk{NfType{key, args}}
                case False{}:
                  NfFail{String.append("the type function `", String.append(key, "` is applied past its declared parameter count"))}

# The body's own environment is the reduction's argument list, so the level it
# is written at is that list's length; `level` is kept for the arguments that
# are applied past the body, which were built in the caller's environment.
def nf_reduce_body(+context: NfContext, body: BIR.Descriptor, +env: List<&2, NfVal>, extra: List<&2, NfVal>, +level: Nat, +fuel: Nat) -> Nf:
  match nf_descriptor(context, body, env, Nat.sub(fuel, 1n)):
    case NfFail{message}:
      NfFail{message}
    case NfOk{val}:
      nf_apply(context, val, extra, level, fuel)

def nf_cases(+context: NfContext, cases: List<&2, BIR.Descriptor>, +values: List<&2, NfVal>, +env: List<&2, NfVal>, source: BIR.Descriptor, +fuel: Nat) -> Nf:
  match cases:
    case Nil{}:
      NfOk{NfOther{reify_env(source, env)}}
    case +case_body <> rest:
      match case_body:
        case BIR.DescriptorCase{patterns, body}:
          match bind_patterns(patterns, values):
            case NfBound{bindings}:
              nf_descriptor(context, body, List.append(&2, NfVal, env, bindings), Nat.sub(fuel, 1n))
            case NfMismatch{}:
              nf_cases(context, rest, values, env, source, fuel)
            case NfUnknown{}:
              NfOk{NfOther{reify_env(source, env)}}
        case BIR.DescriptorFailure{message}:
          NfFail{message}
        case _:
          NfFail{"descriptor match case is not a case"}

# The normalized descriptor for a checked type expression. A reduction that
# cannot be performed becomes DescriptorFailure, so a consumer that replaces a
# stored field with this result can never silently lose the failure. The result
# replaces the source expression where it stood, so it is materialized at that
# environment's level: an arrow binder the normal form still holds keeps the
# parameter index that names it there.
def normalize(+context: NfContext, descriptor: BIR.Descriptor, +env: List<&2, NfVal>, +fuel: Nat) -> BIR.Descriptor:
  match nf(context, descriptor, env, fuel):
    case NfFail{message}:
      BIR.DescriptorFailure{message}
    case NfOk{val}:
      materialize_at(val, env_level(env))

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
