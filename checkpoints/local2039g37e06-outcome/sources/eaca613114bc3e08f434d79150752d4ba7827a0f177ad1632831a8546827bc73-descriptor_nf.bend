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
import /private/tmp/bend-e01-e13-jbsb4I/normalizer-source-05/descriptor-sources/bend2/selfhost/backend_ir.bend as BIR
import /private/tmp/bend-e01-e13-jbsb4I/normalizer-source-05/descriptor-sources/bend2/selfhost/index_lookup.bend as IndexLookup

# A normalized type expression. NfType is a named type applied to the
# arguments it has so far; NfCtor is a value constructor applied to values,
# which a type-level match may inspect; NfQuantity and NfKind keep the quantity
# and kind language as semantic values. NfOther is any other term (a proof, a
# hole, an abstract application), kept as its own descriptor; NfMissing is a
# binder with no value in scope, kept as its own descriptor.
#
# NfBinder names an arrow binder by its level among surviving output binders.
# Substitution, let and beta reduction extend the evaluator environment but do
# not introduce output binders. Only an arrow body increments this level.
# Materializing at output depth `level` yields `level - binder - 1`.
# It remains abstract: no consumer may read it as a concrete type.
#
# Arrows keep semantic children until their final scope is known. A saved
# arrow may move under another binder; quotation relocates its own binder
# without changing captured outer binders. Lambda closures retain their source
# body and semantic environment, quoted only when the closure is materialized.
type NfVal is Data:
  NfType{key: String, args: List<&2, NfVal>}
  NfCtor{key: String, args: List<&2, NfVal>}
  NfQuantity{quantity: BIR.Quantity}
  NfKind{quantity: NfVal}
  NfOther{source: BIR.Descriptor}
  NfMissing{source: BIR.Descriptor}
  NfBinder{level: Nat}
  NfArrow{quantity: BIR.Quantity, domain: NfVal, body: NfVal, level: Nat}
  NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, NfVal>}

type NfRenaming is Data:
  NfRenaming{source: Nat, target: Nat}

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

def native_match_native_of_0(v_10: BIR.Family) -> Maybe<&2, String>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      v_19

def native_match_native_of_1(v_25: BIR.TypeFunction) -> Maybe<&2, String>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      v_32

def native_match_native_of_2(v_37: Maybe<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_37:
    case Some{v_25}:
      native_match_native_of_1(v_25)
    case None{}:
      None{}

def native_match_native_of_3(v_36: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_36:
    case Some{v_10}:
      native_match_native_of_0(v_10)
    case None{}:
      native_match_native_of_2(function_of(v_1, v_5))

def native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  native_match_native_of_3(family_of(v_1, v_3), v_1, v_5)

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

# Quotation walks the semantic value tree and its argument/environment lists.
# It does not reduce descriptors again or spend another normalization budget.
#
# `level` counts surviving output binders, not evaluator environment entries.
# Eliminated lets, substitutions and beta arguments must not shift an arrow's
# parameter indices. Every evaluator materialization supplies its output depth.
def native_match_renamed_level_0(v_13: Bool, +v_4: Nat, v_10: Nat, v_11: List<&2, NfRenaming>) -> Nat:
  match v_13:
    case True{}:
      v_10
    case False{}:
      renamed_level(v_11, v_4)

def native_match_renamed_level_1(v_2: List<&2, NfRenaming>, +v_4: Nat) -> Nat:
  match v_2:
    case []:
      v_4
    case NfRenaming{v_9, v_10} <> v_11:
      native_match_renamed_level_0(Nat.is_eq(v_9, v_4), v_4, v_10, v_11)

def renamed_level(v_2: List<&2, NfRenaming>, +v_4: Nat) -> Nat:
  native_match_renamed_level_1(v_2, v_4)

def materialize_all_scoped(vals: List<&2, NfVal>, +level: Nat, +renames: List<&2, NfRenaming>) -> List<&2, BIR.Descriptor>:
  match vals:
    case Nil{}:
      Nil{}
    case +val <> rest:
      materialize_scoped(val, level, renames) <> materialize_all_scoped(rest, level, renames)

def materialize_all_at(vals: List<&2, NfVal>, +level: Nat) -> List<&2, BIR.Descriptor>:
  materialize_all_scoped(vals, level, Nil{})

def materialize_all(vals: List<&2, NfVal>) -> List<&2, BIR.Descriptor>:
  materialize_all_at(vals, 0n)

def materialize_scoped(val: NfVal, +level: Nat, +renames: List<&2, NfRenaming>) -> BIR.Descriptor:
  match val:
    case NfType{key, args}:
      BIR.DescriptorRef{key, materialize_all_scoped(args, level, renames)}
    case NfCtor{key, args}:
      BIR.DescriptorConstructor{key, materialize_all_scoped(args, level, renames)}
    case NfQuantity{quantity}:
      BIR.DescriptorQuantity{quantity}
    case NfKind{quantity}:
      BIR.DescriptorKind{materialize_scoped(quantity, level, renames)}
    case NfOther{source}:
      source
    case NfMissing{source}:
      source
    case NfBinder{binder}:
      BIR.DescriptorParameter{Nat.sub(level, Nat.add(renamed_level(renames, binder), 1n))}
    case NfArrow{quantity, domain, body, origin}:
      BIR.DescriptorArrow{quantity, materialize_scoped(domain, level, renames), materialize_scoped(body, Nat.add(level, 1n), NfRenaming{origin, level} <> renames)}
    case NfClosure{quantity, body, env}:
      BIR.DescriptorLet{materialize_all_scoped(env, level, renames), BIR.DescriptorLambda{quantity, body}}

def materialize_at(val: NfVal, +level: Nat) -> BIR.Descriptor:
  materialize_scoped(val, level, Nil{})

def materialize(val: NfVal) -> BIR.Descriptor:
  materialize_at(val, 0n)

# An opaque term was normalized under an environment. One let binds that
# environment back around the raw form: its values evaluate where the term was
# written, before any new binder, and the let repeats the environment's shape
# above it, so no parameter index is ever rewritten.
def reify_env(source: BIR.Descriptor, +env: List<&2, NfVal>, +level: Nat) -> BIR.Descriptor:
  match env:
    case Nil{}:
      source
    case +value <> rest:
      BIR.DescriptorLet{materialize_all_at(env, level), source}
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

def native_match_bind_status_0(v_56: Bool, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, NfVal>, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, NfVal>) -> NfStatus:
  match v_56:
    case False{}:
      NfStatusNo{}
    case True{}:
      status_combine(bind_status(v_20, v_24), bind_status(v_11, v_13))

def native_match_bind_status_1(+v_12: NfVal, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, NfVal>, v_19: String, v_20: List<&2, BIR.DescriptorPattern>) -> NfStatus:
  match v_12:
    case NfCtor{v_23, v_24}:
      native_match_bind_status_0(String.eq(v_19, v_23), v_11, v_13, v_20, v_24)
    case NfMissing{v_29}:
      status_combine(NfStatusMaybe{}, bind_status(v_11, v_13))
    case NfOther{v_33}:
      status_combine(NfStatusMaybe{}, bind_status(v_11, v_13))
    case NfBinder{v_37}:
      status_combine(NfStatusMaybe{}, bind_status(v_11, v_13))
    case NfArrow{v_44, v_45, v_46, v_47}:
      status_combine(NfStatusMaybe{}, bind_status(v_11, v_13))
    case _:
      NfStatusNo{}

def native_match_bind_status_2(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, +v_12: NfVal, v_13: List<&2, NfVal>) -> NfStatus:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      bind_status(v_11, v_13)
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      native_match_bind_status_1(v_12, v_11, v_13, v_19, v_20)

def native_match_bind_status_3(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, NfVal>) -> NfStatus:
  match v_1, v_4:
    case [], []:
      NfStatusOk{}
    case +v_10 <> v_11, +v_12 <> v_13:
      native_match_bind_status_2(v_10, v_11, v_12, v_13)
    case _, _:
      NfStatusNo{}

def bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, NfVal>) -> NfStatus:
  native_match_bind_status_3(v_1, v_4)

def native_match_bind_values_0(+v_13: NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, NfVal>, v_21: List<&2, BIR.DescriptorPattern>) -> List<&2, NfVal>:
  match v_13:
    case NfCtor{v_24, v_25}:
      append_vals(bind_values(v_21, v_25), bind_values(v_12, v_14))
    case _:
      bind_values(v_12, v_14)

def native_match_bind_values_1(+v_11: BIR.DescriptorPattern, v_12: List<&2, BIR.DescriptorPattern>, +v_13: NfVal, v_14: List<&2, NfVal>) -> List<&2, NfVal>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      v_13 <> bind_values(v_12, v_14)
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      native_match_bind_values_0(v_13, v_12, v_14, v_21)

def native_match_bind_values_2(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, NfVal>) -> List<&2, NfVal>:
  match v_1, v_4:
    case [], []:
      []
    case +v_11 <> v_12, +v_13 <> v_14:
      native_match_bind_values_1(v_11, v_12, v_13, v_14)
    case _, _:
      []

def bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, NfVal>) -> List<&2, NfVal>:
  native_match_bind_values_2(v_1, v_4)

def native_match_bind_patterns_0(v_5: NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, NfVal>) -> NfBind:
  match v_5:
    case NfStatusOk{}:
      NfBound{bind_values(v_1, v_4)}
    case NfStatusNo{}:
      NfMismatch{}
    case NfStatusMaybe{}:
      NfUnknown{}

def bind_patterns(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, NfVal>) -> NfBind:
  native_match_bind_patterns_0(bind_status(v_1, v_4), v_1, v_4)

def native_match_nf_0(v_10: Bool, +v_1: NfContext, v_2: BIR.Descriptor, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat) -> Nf:
  match v_10:
    case True{}:
      NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      nf_descriptor(v_1, v_2, v_5, v_7, Nat.sub(v_9, 1n))

def nf(+v_1: NfContext, v_2: BIR.Descriptor, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat) -> Nf:
  native_match_nf_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_nf_descriptor_0(v_10: Bool, +v_1: NfContext, v_2: BIR.Descriptor, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat) -> Nf:
  match v_10:
    case True{}:
      NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      nf_descriptor_step(v_1, v_2, v_5, v_7, v_9)

def nf_descriptor(+v_1: NfContext, v_2: BIR.Descriptor, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat) -> Nf:
  native_match_nf_descriptor_0(Nat.is_eq(v_9, 0n), v_1, v_2, v_5, v_7, v_9)

def native_match_nf_arrow_0(v_25: Nf, v_2: BIR.Quantity, +v_9: Nat, v_17: NfVal) -> Nf:
  match v_25:
    case NfFail{v_21}:
      NfFail{v_21}
    case NfOk{v_23}:
      NfOk{NfArrow{v_2, v_17, v_23, v_9}}

def native_match_nf_arrow_1(v_24: Nf, +v_1: NfContext, v_2: BIR.Quantity, v_4: BIR.Descriptor, +v_7: List<&2, NfVal>, +v_9: Nat, +v_11: Nat) -> Nf:
  match v_24:
    case NfFail{v_15}:
      NfFail{v_15}
    case NfOk{v_17}:
      native_match_nf_arrow_0(nf(v_1, v_4, List.append(&2, NfVal, v_7, [NfBinder{v_9}]), Nat.add(v_9, 1n), v_11), v_2, v_9, v_17)

def nf_arrow(+v_1: NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, NfVal>, +v_9: Nat, +v_11: Nat) -> Nf:
  native_match_nf_arrow_1(nf(v_1, v_3, v_7, v_9, v_11), v_1, v_2, v_4, v_7, v_9, v_11)

def native_match_nf_descriptor_step_0(v_191: Nf) -> Nf:
  match v_191:
    case NfOk{v_24}:
      NfOk{NfKind{v_24}}
    case NfFail{v_26}:
      NfFail{v_26}

def native_match_nf_descriptor_step_1(v_192: NfList, +v_1: NfContext, +v_7: Nat, +v_9: Nat, v_45: String) -> Nf:
  match v_192:
    case NfListOk{v_49}:
      nf_named(v_1, v_45, v_49, v_7, v_9)
    case NfListFail{v_52}:
      NfFail{v_52}

def native_match_nf_descriptor_step_2(v_193: NfList, v_55: String) -> Nf:
  match v_193:
    case NfListOk{v_59}:
      NfOk{NfCtor{v_55, v_59}}
    case NfListFail{v_61}:
      NfFail{v_61}

def native_match_nf_descriptor_step_3(v_195: Nf, +v_1: NfContext, +v_7: Nat, +v_9: Nat, v_68: NfVal) -> Nf:
  match v_195:
    case NfOk{v_71}:
      nf_apply(v_1, v_68, [v_71], v_7, v_9)
    case NfFail{v_74}:
      NfFail{v_74}

def native_match_nf_descriptor_step_4(v_194: Nf, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat, v_65: BIR.Descriptor) -> Nf:
  match v_194:
    case NfOk{v_68}:
      native_match_nf_descriptor_step_3(nf(v_1, v_65, v_5, v_7, v_9), v_1, v_7, v_9, v_68)
    case NfFail{v_76}:
      NfFail{v_76}

def native_match_nf_descriptor_step_5(v_196: Nf, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat, v_80: Nat, v_82: BIR.Descriptor) -> Nf:
  match v_196:
    case NfOk{v_85}:
      nf_descriptor(v_1, v_82, insert_before(v_5, Nat.sub(List.length(&2, NfVal, v_5), v_80), v_85), v_7, Nat.sub(v_9, 1n))
    case NfFail{v_90}:
      NfFail{v_90}

def native_match_nf_descriptor_step_6(v_197: NfList, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat, v_94: BIR.Descriptor) -> Nf:
  match v_197:
    case NfListOk{v_97}:
      nf_descriptor(v_1, v_94, List.append(&2, NfVal, v_5, v_97), v_7, Nat.sub(v_9, 1n))
    case NfListFail{v_101}:
      NfFail{v_101}

def native_match_nf_descriptor_step_7(v_199: NfBind, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_107: BIR.Descriptor) -> Nf:
  match v_199:
    case NfBound{v_113}:
      nf_descriptor(v_1, v_107, List.append(&2, NfVal, v_5, v_113), v_7, Nat.sub(v_9, 1n))
    case _:
      NfOk{NfOther{reify_env(v_12, v_5, v_7)}}

def native_match_nf_descriptor_step_8(v_198: NfList, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_105: List<&2, BIR.DescriptorPattern>, v_107: BIR.Descriptor) -> Nf:
  match v_198:
    case NfListOk{v_110}:
      native_match_nf_descriptor_step_7(bind_patterns(v_105, v_110), v_1, v_5, v_7, v_9, v_12, v_107)
    case NfListFail{v_120}:
      NfFail{v_120}

def native_match_nf_descriptor_step_9(v_200: NfList, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat, +v_12: BIR.Descriptor, v_124: List<&2, BIR.Descriptor>) -> Nf:
  match v_200:
    case NfListOk{v_127}:
      nf_cases(v_1, v_124, v_127, v_5, v_12, v_7, v_9)
    case NfListFail{v_130}:
      NfFail{v_130}

def native_match_nf_descriptor_step_10(v_201: Nf, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat, v_139: BIR.Descriptor) -> Nf:
  match v_201:
    case NfOk{v_142}:
      nf_descriptor(v_1, v_139, List.append(&2, NfVal, v_5, [v_142]), v_7, Nat.sub(v_9, 1n))
    case NfFail{v_146}:
      NfFail{v_146}

def native_match_nf_descriptor_step_11(v_202: NfList, +v_1: NfContext, +v_7: Nat, +v_9: Nat, v_170: String) -> Nf:
  match v_202:
    case NfListOk{v_175}:
      nf_named(v_1, v_170, v_175, v_7, v_9)
    case NfListFail{v_178}:
      NfFail{v_178}

def native_match_nf_descriptor_step_12(v_203: NfList, +v_1: NfContext, +v_7: Nat, +v_9: Nat, v_182: String) -> Nf:
  match v_203:
    case NfListOk{v_187}:
      nf_named(v_1, v_182, v_187, v_7, v_9)
    case NfListFail{v_190}:
      NfFail{v_190}

def native_match_nf_descriptor_step_13(+v_12: BIR.Descriptor, +v_1: NfContext, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat) -> Nf:
  match v_12:
    case BIR.DescriptorNull{}:
      NfOk{NfOther{reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorParameter{v_15}:
      NfOk{val_at(v_5, v_15, v_12)}
    case BIR.DescriptorQuantityKind{}:
      NfOk{NfOther{reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorQuantity{v_19}:
      NfOk{NfQuantity{v_19}}
    case BIR.DescriptorKind{v_21}:
      native_match_nf_descriptor_step_0(nf(v_1, v_21, v_5, v_7, v_9))
    case BIR.DescriptorMinimum{v_29, v_30}:
      NfOk{NfOther{reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorArrow{v_35, v_36, v_37}:
      nf_arrow(v_1, v_35, v_36, v_37, v_5, v_7, v_9)
    case BIR.DescriptorLambda{v_41, v_42}:
      NfOk{NfClosure{v_41, v_42, v_5}}
    case BIR.DescriptorRef{v_45, v_46}:
      native_match_nf_descriptor_step_1(nf_all(v_1, v_46, v_5, v_7, v_9), v_1, v_7, v_9, v_45)
    case BIR.DescriptorConstructor{v_55, v_56}:
      native_match_nf_descriptor_step_2(nf_all(v_1, v_56, v_5, v_7, v_9), v_55)
    case BIR.DescriptorApplication{v_64, v_65}:
      native_match_nf_descriptor_step_4(nf(v_1, v_64, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_65)
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      native_match_nf_descriptor_step_5(nf(v_1, v_81, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_80, v_82)
    case BIR.DescriptorLet{v_93, v_94}:
      native_match_nf_descriptor_step_6(nf_all(v_1, v_93, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_94)
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      native_match_nf_descriptor_step_8(nf_all(v_1, v_106, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_105, v_107)
    case BIR.DescriptorMatch{v_123, v_124}:
      native_match_nf_descriptor_step_9(nf_all(v_1, v_123, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_12, v_124)
    case BIR.DescriptorCase{v_133, v_134}:
      NfOk{NfOther{reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorBind{v_138, v_139}:
      native_match_nf_descriptor_step_10(nf(v_1, v_138, v_5, v_7, v_9), v_1, v_5, v_7, v_9, v_139)
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      NfOk{NfOther{reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorReflexivity{}:
      NfOk{NfOther{reify_env(v_12, v_5, v_7)}}
    case BIR.DescriptorFailure{v_156}:
      NfFail{v_156}
    case BIR.DescriptorFill{v_159, v_160}:
      nf_apply_args(v_1, v_159, v_160, v_5, v_12, v_7, v_9)
    case BIR.DescriptorPlus{v_164, v_165}:
      nf_apply_args(v_1, v_164, v_165, v_5, v_12, v_7, v_9)
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      native_match_nf_descriptor_step_11(nf_all(v_1, v_172, v_5, v_7, v_9), v_1, v_7, v_9, v_170)
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      native_match_nf_descriptor_step_12(nf_all(v_1, v_184, v_5, v_7, v_9), v_1, v_7, v_9, v_182)

def nf_descriptor_step(+v_1: NfContext, v_2: BIR.Descriptor, +v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat) -> Nf:
  +v_12 = v_2
  native_match_nf_descriptor_step_13(v_12, v_1, v_5, v_7, v_9)

def native_match_nf_all_0(v_27: NfList, v_20: NfVal) -> NfList:
  match v_27:
    case NfListFail{v_23}:
      NfListFail{v_23}
    case NfListOk{v_25}:
      NfListOk{v_20 <> v_25}

def native_match_nf_all_1(v_26: Nf, +v_1: NfContext, +v_6: List<&2, NfVal>, +v_8: Nat, +v_10: Nat, v_15: List<&2, BIR.Descriptor>) -> NfList:
  match v_26:
    case NfFail{v_18}:
      NfListFail{v_18}
    case NfOk{v_20}:
      native_match_nf_all_0(nf_all(v_1, v_15, v_6, v_8, v_10), v_20)

def native_match_nf_all_2(v_3: List<&2, BIR.Descriptor>, +v_1: NfContext, +v_6: List<&2, NfVal>, +v_8: Nat, +v_10: Nat) -> NfList:
  match v_3:
    case []:
      NfListOk{[]}
    case +v_14 <> v_15:
      native_match_nf_all_1(nf(v_1, v_14, v_6, v_8, v_10), v_1, v_6, v_8, v_10, v_15)

def nf_all(+v_1: NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, NfVal>, +v_8: Nat, +v_10: Nat) -> NfList:
  native_match_nf_all_2(v_3, v_1, v_6, v_8, v_10)

def native_match_nf_apply_args_0(v_25: NfList, +v_1: NfContext, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat, v_18: NfVal) -> Nf:
  match v_25:
    case NfListFail{v_21}:
      NfFail{v_21}
    case NfListOk{v_23}:
      nf_apply_source(v_1, v_18, v_23, v_8, v_10, v_12)

def native_match_nf_apply_args_1(v_24: Nf, +v_1: NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> Nf:
  match v_24:
    case NfFail{v_16}:
      NfFail{v_16}
    case NfOk{v_18}:
      native_match_nf_apply_args_0(nf_all(v_1, v_4, v_7, v_10, v_12), v_1, v_8, v_10, v_12, v_18)

def nf_apply_args(+v_1: NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat) -> Nf:
  native_match_nf_apply_args_1(nf(v_1, v_2, v_7, v_10, v_12), v_1, v_4, v_7, v_8, v_10, v_12)

def nf_apply_source(+context: NfContext, val: NfVal, args: List<&2, NfVal>, source: BIR.Descriptor, +level: Nat, +fuel: Nat) -> Nf:
  match args:
    case Nil{}:
      NfOk{val}
    case _:
      nf_apply(context, val, args, level, fuel)

# `level` is the environment the argument values were built in. Applying a
# value that must stay abstract materializes its argument descriptor there, so
# an arrow binder inside an argument keeps the index that names it.
def native_match_nf_apply_0(v_21: Nf, +v_1: NfContext, +v_8: Nat, +v_10: Nat, v_15: List<&2, NfVal>) -> Nf:
  match v_21:
    case NfFail{v_18}:
      NfFail{v_18}
    case NfOk{v_20}:
      nf_apply(v_1, v_20, v_15, v_8, Nat.sub(v_10, 1n))

def native_match_nf_apply_1(v_6: List<&2, NfVal>, +v_1: NfContext, v_3: NfVal, +v_8: Nat, +v_10: Nat) -> Nf:
  match v_6:
    case []:
      NfOk{v_3}
    case +v_14 <> v_15:
      native_match_nf_apply_0(nf_apply_one(v_1, v_3, v_14, v_8, Nat.sub(v_10, 1n)), v_1, v_8, v_10, v_15)

def nf_apply(+v_1: NfContext, v_3: NfVal, v_6: List<&2, NfVal>, +v_8: Nat, +v_10: Nat) -> Nf:
  native_match_nf_apply_1(v_6, v_1, v_3, v_8, v_10)

def nf_apply_one(+context: NfContext, val: NfVal, arg: NfVal, +level: Nat, +fuel: Nat) -> Nf:
  match val:
    case NfType{key, args}:
      nf_named(context, key, List.append(&2, NfVal, args, [arg]), level, Nat.sub(fuel, 1n))
    case NfClosure{quantity, body, env}:
      nf_descriptor(context, body, List.append(&2, NfVal, env, [arg]), level, Nat.sub(fuel, 1n))
    case NfCtor{key, args}:
      NfFail{String.append("the constructor `", String.append(key, "` is applied to an argument"))}
    case NfQuantity{quantity}:
      NfFail{"a quantity is applied to an argument"}
    case NfKind{quantity}:
      NfFail{"a kind is applied to an argument"}
    case NfOther{source}:
      NfOk{NfOther{BIR.DescriptorApplication{source, materialize_at(arg, level)}}}
    case NfArrow{quantity, domain, body, origin}:
      NfOk{NfOther{BIR.DescriptorApplication{materialize_at(val, level), materialize_at(arg, level)}}}
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

def native_match_nf_named_0(v_27: Maybe<&2, BIR.Family>, +v_3: String, v_6: List<&2, NfVal>) -> Nf:
  match v_27:
    case Some{v_25}:
      nf_family(v_25, v_6)
    case None{}:
      NfOk{NfType{v_3, v_6}}

def native_match_nf_named_1(v_26: Maybe<&2, BIR.TypeFunction>, +v_1: NfContext, +v_3: String, v_6: List<&2, NfVal>, +v_8: Nat, +v_10: Nat, v_14: Map<&2, BIR.Family>) -> Nf:
  match v_26:
    case Some{v_18}:
      +v_20 = v_18
      nf_named_io(intrinsic_io(v_20), v_1, v_20, v_6, v_8, v_10)
    case None{}:
      native_match_nf_named_0(family_of(v_3, v_14), v_3, v_6)

def native_match_nf_named_2(+v_1: NfContext, +v_3: String, v_6: List<&2, NfVal>, +v_8: Nat, +v_10: Nat) -> Nf:
  match v_1:
    case NfContext{v_14, v_15}:
      native_match_nf_named_1(function_of(v_3, v_15), v_1, v_3, v_6, v_8, v_10, v_14)

def nf_named(+v_1: NfContext, +v_3: String, v_6: List<&2, NfVal>, +v_8: Nat, +v_10: Nat) -> Nf:
  native_match_nf_named_2(v_1, v_3, v_6, v_8, v_10)

def nf_arity(+args: List<&2, NfVal>, +quantity_prefix: Nat, +arity: Nat) -> NfArity:
  NfArity{Nat.is_eq(Nat.add(List.length(&2, NfVal, args), quantity_prefix), arity), Nat.is_eq(List.length(&2, NfVal, args), arity), Nat.is_lt(List.length(&2, NfVal, args), arity)}

def native_match_nf_family_0(v_0: BIR.Family, +v_6: List<&2, NfVal>) -> Nf:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      nf_family_apply(nf_arity(v_6, v_20, v_17), v_13, v_20, v_6)

def nf_family(v_0: BIR.Family, v_3: List<&2, NfVal>) -> Nf:
  +v_6 = v_3
  native_match_nf_family_0(v_0, v_6)

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

def native_match_nf_reduce_0(v_2: BIR.TypeFunction, +v_1: NfContext, +v_7: Nat, +v_9: Nat, +v_12: List<&2, NfVal>) -> Nf:
  match v_2:
    case BIR.TypeFunction{v_18, v_19, v_20, v_21, v_22}:
      +v_24 = v_20
      +v_26 = v_21
      nf_reduce_apply(nf_arity(v_12, v_24, v_26), v_1, v_18, v_24, v_26, v_22, v_12, v_7, v_9)

def nf_reduce(+v_1: NfContext, v_2: BIR.TypeFunction, v_5: List<&2, NfVal>, +v_7: Nat, +v_9: Nat) -> Nf:
  +v_12 = v_5
  native_match_nf_reduce_0(v_2, v_1, v_7, v_9, v_12)

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

# Beta reduction substitutes arguments without introducing output binders.
def native_match_nf_reduce_body_0(v_19: Nf, +v_1: NfContext, v_8: List<&2, NfVal>, +v_10: Nat, +v_12: Nat) -> Nf:
  match v_19:
    case NfFail{v_16}:
      NfFail{v_16}
    case NfOk{v_18}:
      nf_apply(v_1, v_18, v_8, v_10, v_12)

def nf_reduce_body(+v_1: NfContext, v_2: BIR.Descriptor, +v_5: List<&2, NfVal>, v_8: List<&2, NfVal>, +v_10: Nat, +v_12: Nat) -> Nf:
  native_match_nf_reduce_body_0(nf_descriptor(v_1, v_2, v_5, v_10, Nat.sub(v_12, 1n)), v_1, v_8, v_10, v_12)

def native_match_nf_cases_0(v_36: NfBind, +v_1: NfContext, +v_6: List<&2, NfVal>, +v_9: List<&2, NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>, v_24: BIR.Descriptor) -> Nf:
  match v_36:
    case NfBound{v_27}:
      nf_descriptor(v_1, v_24, List.append(&2, NfVal, v_9, v_27), v_12, Nat.sub(v_14, 1n))
    case NfMismatch{}:
      nf_cases(v_1, v_20, v_6, v_9, v_10, v_12, v_14)
    case NfUnknown{}:
      NfOk{NfOther{reify_env(v_10, v_9, v_12)}}

def native_match_nf_cases_1(+v_19: BIR.Descriptor, +v_1: NfContext, +v_6: List<&2, NfVal>, +v_9: List<&2, NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat, v_20: List<&2, BIR.Descriptor>) -> Nf:
  match v_19:
    case BIR.DescriptorCase{v_23, v_24}:
      native_match_nf_cases_0(bind_patterns(v_23, v_6), v_1, v_6, v_9, v_10, v_12, v_14, v_20, v_24)
    case BIR.DescriptorFailure{v_33}:
      NfFail{v_33}
    case _:
      NfFail{"descriptor match case is not a case"}

def native_match_nf_cases_2(v_3: List<&2, BIR.Descriptor>, +v_1: NfContext, +v_6: List<&2, NfVal>, +v_9: List<&2, NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> Nf:
  match v_3:
    case []:
      NfOk{NfOther{reify_env(v_10, v_9, v_12)}}
    case +v_19 <> v_20:
      native_match_nf_cases_1(v_19, v_1, v_6, v_9, v_10, v_12, v_14, v_20)

def nf_cases(+v_1: NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, NfVal>, +v_9: List<&2, NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat) -> Nf:
  native_match_nf_cases_2(v_3, v_1, v_6, v_9, v_10, v_12, v_14)

def native_match_normalize_0(v_13: Nf) -> BIR.Descriptor:
  match v_13:
    case NfFail{v_10}:
      BIR.DescriptorFailure{v_10}
    case NfOk{v_12}:
      materialize_at(v_12, 0n)

def normalize(+v_1: NfContext, v_2: BIR.Descriptor, +v_5: List<&2, NfVal>, +v_7: Nat) -> BIR.Descriptor:
  native_match_normalize_0(nf(v_1, v_2, v_5, 0n, v_7))

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
def native_match_answer_in_0(v_5: BIR.Descriptor, +v_1: NfContext) -> BIR.Descriptor:
  match v_5:
    case BIR.DescriptorFailure{_}:
      v_5
    case _:
      answer_normalized(v_1, v_5)

def answer_in(+v_1: NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  v_5 = normalize(v_1, v_2, [], 1024n)
  native_match_answer_in_0(v_5, v_1)

def answer_descriptor(result: BIR.Descriptor, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  answer_in(nf_context(families, type_functions), result)

def native_match_answer_normalized_0(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_9:
    case []:
      v_2
    case +v_13 <> v_14:
      v_13

def native_match_answer_normalized_1(v_16: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  match v_16:
    case False{}:
      v_2
    case True{}:
      native_match_answer_normalized_0(v_9, v_2)

def native_match_answer_normalized_2(v_5: NfApp, +v_1: NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_5:
    case NfApp{v_8, v_9}:
      native_match_answer_normalized_1(is_io_head_in(v_1, v_8), v_2, v_9)

def native_match_answer_normalized_3(v_15: Maybe<&2, NfApp>, +v_1: NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_15:
    case None{}:
      v_2
    case Some{v_5}:
      native_match_answer_normalized_2(v_5, v_1, v_2)

def answer_normalized(+v_1: NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  native_match_answer_normalized_3(outer_application(v_2), v_1, v_2)

def is_io_head_in(+context: NfContext, +key: String) -> Bool:
  match context:
    case NfContext{families, type_functions}:
      is_io_head(key, families, type_functions)

def native_match_is_io_head_0(v_10: Maybe<&2, String>) -> Bool:
  match v_10:
    case Some{v_9}:
      String.eq(v_9, "IO")
    case None{}:
      False{}

def is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Bool:
  native_match_is_io_head_0(native_of(v_1, v_3, v_5))

