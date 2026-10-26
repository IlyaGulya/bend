import Base
import ./backend_ir.bend as BIR
import ./index_lookup.bend as IndexLookup

# C target sharing facts
# ======================
#
# ONE SharingPlan, computed from Backend IR facts only: which constructors and
# foreign values must carry the runtime's reference counted sharing policy
# (CID_T hot), and whether an array block may be shared (BLK_SHR). The C
# renderer consumes it for the CID_T rows, the array shared flag and node field
# sealing. It never re-derives a sharing fact from a key spelling, a layout
# kind or a source tree.
#
# BIR is erased at the value boundary: a Code parameter has an id and a use,
# not a type. What survives is checked use information (Arg.use, Parameter.use,
# Code.captures), producer facts (Construct, Project, Direct, Apply,
# LoadSymbol, foreign and native declarations), and the anti-quoted Descriptor
# facts of families, type functions, foreign declarations and the program
# ending. A value needs the runtime's sharing policy exactly when it can be
# used more than once, so the analysis is a monotone fixed point over four
# facts per value: the may-set of runtime type heads it holds, the may-set of
# its IO answer heads, the set of callees it may be, and whether a fact is
# genuinely absent (unknown).
#
#   1. Demand. A value is demanded when its own body uses it more than once
#      (the exact static occurrence count), when it is passed with a checked
#      Many use, or when it is stored in a constructed field with a Many use.
#      A demanded value's heads are hot. An array head adds BLK_SHR and makes
#      the array element heads hot.
#   2. Flow. Heads flow from producers into values: Construct gives its
#      family; Project gives the declared live arm field; a primitive gives its
#      result family and, for array operations, the checked element
#      descriptor; a closure gives a function head; Direct/Apply give the
#      callee's returned heads; a foreign symbol gives its declared result
#      descriptor (and the IO protocol's answer for the continuation); the
#      canonical IO.bind carries the action's answer payload into the
#      continuation's parameter. Arguments flow into the callee's parameters,
#      captures into the closure's capture slots.
#   3. Closure. A hot family makes every one of its constructors hot; each
#      live declared field's type head is hot too. A hot shared array makes
#      its element heads hot.
#
# A head the facts genuinely do not determine is not guessed: when such a
# value is demanded, the plan becomes `forced` (every constructor hot) with a
# note. That is the reference's facts_hot "*" case and it is sound: sealing
# every node never loses sharing, it only refuses the cold elision. A program
# whose use facts and producers are all known never takes that branch, so a
# cold scalar program stays cold instead of collapsing to everything hot.
#
# Deliberate, documented departures from the reference, all conservative:
#   * the reference counts source uses after folding and may re-evaluate a
#     pure term per use; BIR has already chosen one binding, so a duplicated
#     BIR binding is treated as sharing (a superset of the reference hot set,
#     never a subset);
#   * Nat/U32/F32 heads are words, not nodes: a duplicated word never seeds
#     their constructors, though a hot field type may still reach them;
#   * a function head has no declared constructor fields, so it is not expanded
#     into the hot set. This does not license copying a heap callable:
#     rfc_wrap rejects TAG_CLO/TAG_TSK. Caller liveness must transfer those
#     affine owners without term_keep. This hot-set plan is not a move/keep
#     plan and cannot establish frame or projection lifetimes.
#   * foreign declaration cids stay cold: the foreign twin lays its own node
#     under the produced constructor's cid and seals through the constructor
#     hot bit (tests/io/foreign_shared.c), so the declaration cid itself is
#     never consulted for sealing. The foreign key is still present in the
#     plan with an explicit false value.
#
# Failures are real fact inconsistencies (a duplicate constructor key, a
# constructor no family declares, an out-of-range projection, a
# DescriptorFailure in a position the hot closure must read, or a fixed point
# that does not converge), never a guessed value. Unknown flow is not a
# failure: it sets forced, with a note saying where.

type SharingPlan is Data:
  SharingPlan{
    hot: Map<&2, Bool>,
    array_shared: Bool,
    forced: Bool,
    note: List<&2, String>
  }

type SharingResult is Data:
  SharingOk{plan: SharingPlan}
  SharingFail{message: String}

# ---------------------------------------------------------------------------
# Fact model
# ---------------------------------------------------------------------------

type ArmField is Data:
  ArmField{live: Bool, ty: BIR.Descriptor}

type ArmRow is Data:
  ArmRow{key: String, fields: List<&2, ArmField>}

type FamilyRow is Data:
  FamilyRow{key: String, native: Maybe<&2, String>, arity: Nat, arms: List<&2, ArmRow>}

type CtorRow is Data:
  CtorRow{id: U32, key: String, family: String}

type FlagOut is Data:
  FlagOut{flags: Map<&2, Bool>, grew: Bool}

type CountOut is Data:
  CountOut{counts: Map<&2, Nat>, grew: Bool}

type Flow is Data:
  Flow{heads: List<&2, String>, unknown: Bool}

type FlowOut is Data:
  FlowOut{flows: Map<&2, Flow>, grew: Bool}

# kind: "fn" | "lazy" | "native" | "foreign"
type DeclRow is Data:
  DeclRow{
    key: String,
    kind: String,
    code: U32,
    arity: Nat,
    result: BIR.Descriptor,
    primitive: BIR.Primitive,
    has_primitive: Bool
  }

type DefRow is Data:
  DefConstruct{constructor: U32}
  DefProject{constructor: U32, field: U32}
  DefPrim{primitive: BIR.Primitive, types: List<&2, BIR.Descriptor>}
  DefCopy{atom: BIR.Atom}
  DefClosure{code: U32}
  DefDirect{bkey: String, code: U32, args: List<&2, BIR.Arg>}
  DefApply{bkey: String, fn: BIR.Atom}
  DefSymbol{key: String}
  DefOther{}

type DefEntry is Data:
  DefEntry{bkey: String, row: DefRow}

type BodyRow is Data:
  BodyRow{
    owner: U32,
    bkey: String,
    lazy: Maybe<&2, String>,
    body: BIR.Block,
    params: List<&2, U32>,
    capture_count: Nat
  }

type ClosureSite is Data:
  ClosureSite{bkey: String, code: U32, captures: List<&2, BIR.Arg>}

type CallSite is Data:
  CallSite{bkey: String, code: U32, args: List<&2, BIR.Arg>}

type ApplySite is Data:
  ApplySite{bkey: String, fn: BIR.Atom, arg: BIR.Atom, many: Bool}

type BindSite is Data:
  BindSite{bkey: String, action: BIR.Atom, cont: BIR.Atom}

type DemandSite is Data:
  DemandSite{bkey: String, atom: BIR.Atom}

type Resolved is Data:
  ResolvedCode{code: U32}
  ResolvedDecl{key: String}
  ResolvedNone{}

type Catalog is Data:
  Catalog{
    ctor_by_key: Map<&2, CtorRow>,
    ctor_by_id: Map<&2, CtorRow>,
    family_by_key: Map<&2, FamilyRow>,
    typefn_label: Map<&2, String>,
    ctor_keys: List<&2, String>,
    foreign_keys: List<&2, String>,
    family_keys: List<&2, String>,
    failure: Maybe<&2, String>
  }

type DeclFacts is Data:
  DeclFacts{
    decl_by_key: Map<&2, DeclRow>,
    decl_key_by_code: Map<&2, String>,
    code_params: Map<&2, List<&2, U32>>,
    code_captures: Map<&2, Nat>
  }

type BuiltFacts is Data:
  BuiltFacts{
    bodies: List<&2, BodyRow>,
    defs: Map<&2, DefEntry>,
    def_keys: List<&2, String>,
    occ: Map<&2, Nat>,
    count_keys: List<&2, String>,
    closures: List<&2, ClosureSite>,
    calls: List<&2, CallSite>,
    applies: List<&2, ApplySite>,
    binds: List<&2, BindSite>,
    demands: List<&2, DemandSite>,
    capture_keys: List<&2, String>,
    symbol_keys: List<&2, String>,
    element_heads: List<&2, String>,
    element_unknown: Bool
  }

type Facts is Data:
  Facts{catalog: Catalog, decls: DeclFacts, built: BuiltFacts}

type Reach is Data:
  Reach{
    keys: Map<&2, Bool>,
    codes: Map<&2, Bool>,
    escape: List<&2, U32>,
    dynamic: Bool,
    changed: Bool
  }

type ReachOut is Data:
  ReachOut{reach: Reach, changed: Bool}

type DefsOut is Data:
  DefsOut{defs: Map<&2, DefEntry>, def_keys: List<&2, String>}

type OccOut is Data:
  OccOut{occ: Map<&2, Nat>, count_keys: List<&2, String>}

type SitesOut is Data:
  SitesOut{
    closures: List<&2, ClosureSite>,
    calls: List<&2, CallSite>,
    applies: List<&2, ApplySite>,
    binds: List<&2, BindSite>,
    demands: List<&2, DemandSite>,
    symbols: List<&2, String>,
    element_heads: List<&2, String>,
    element_unknown: Bool
  }

type FlowAcc is Data:
  FlowAcc{flows: Map<&2, Flow>, pay: Map<&2, Flow>, calls: Map<&2, List<&2, Resolved>>}

type Heads is Data:
  Heads{heads: List<&2, String>, unknown: Bool, fail: Maybe<&2, String>}

type CalleeOut is Data:
  CalleeOut{callees: Map<&2, List<&2, Resolved>>, grew: Bool}

type AState is Data:
  AState{
    flow: Map<&2, Flow>,
    pay: Map<&2, Flow>,
    call: Map<&2, List<&2, Resolved>>,
    hot: Map<&2, Bool>,
    ctr: Map<&2, Bool>,
    array_hot: Bool,
    elem_unknown: Bool,
    forced: Bool,
    note: List<&2, String>,
    changed: Bool,
    failure: Maybe<&2, String>
  }

# The two flows a block may produce: its runtime value and, when that value is
# a monadic action, the IO answer.
type BlockFlow is Data:
  BlockFlow{value: Flow, answer: Flow, fail: Maybe<&2, String>}

# A definition's runtime value, its IO answer, and the callee it denotes.
type DefFlow is Data:
  DefFlow{value: Flow, pay: Flow, call: List<&2, Resolved>}

def s_flow_empty() -> Flow:
  Flow{Nil{}, False{}}

def s_nonempty(+items: List<&2, String>) -> Bool:
  match items:
    case Nil{}: False{}
    case +_ <> _: True{}

def s_flow_nonempty(flow: Flow) -> Bool:
  match flow:
    case Flow{heads, unknown}: Bool.or(unknown, s_nonempty(heads))


# ---------------------------------------------------------------------------
# Keys
# ---------------------------------------------------------------------------

def s_id_key(id: U32) -> String:
  String.append("v", U32.show(id))

def s_code_body(code: U32) -> String:
  String.append("c", U32.show(code))

def s_lazy_body(key: String) -> String:
  String.append("l", key)

def s_body_local(body: String, id: U32) -> String:
  String.concat([body, "/", s_id_key(id)])

def s_body_capture(body: String, slot: Nat) -> String:
  String.concat([body, "/k", Nat.show(slot)])

def s_body_result(body: String) -> String:
  String.concat([body, "/r"])

def s_symbol_value(key: String) -> String:
  String.concat(["g/", key])

def s_family(head: String) -> String:
  String.append("f:", head)

def s_function_head() -> String:
  "fn"

def s_cat2(a: String, b: String) -> String:
  String.append(a, b)

def s_cat3(a: String, b: String, c: String) -> String:
  String.concat([a, b, c])

# ---------------------------------------------------------------------------
# Small list and map helpers. Every one is self-recursive or single-level.
# ---------------------------------------------------------------------------

def s_member_go(+items: List<&2, String>, +key: String, found: Bool) -> Bool:
  match items:
    case Nil{}: found
    case +item <> rest: s_member_go(rest, key, Bool.or(found, String.eq(item, key)))

def s_member(+items: List<&2, String>, +key: String) -> Bool:
  s_member_go(items, key, False{})

def s_add_go(+items: List<&2, String>, +key: String, found: Bool) -> List<&2, String>:
  match found:
    case True{}: items
    case False{}: key <> items

def s_add(+items: List<&2, String>, +key: String) -> List<&2, String>:
  s_add_go(items, key, s_member(items, key))

def s_union_go(+more: List<&2, String>, +items: List<&2, String>) -> List<&2, String>:
  match more:
    case Nil{}: items
    case +head <> rest: s_union_go(rest, s_add(items, head))

def s_union(+items: List<&2, String>, more: List<&2, String>) -> List<&2, String>:
  s_union_go(more, items)

def s_size(+items: List<&2, String>) -> Nat:
  match items:
    case Nil{}: 0n
    case +_ <> rest: Nat.add(1n, s_size(rest))

def s_grew(before: List<&2, String>, after: List<&2, String>) -> Bool:
  Nat.is_ne(s_size(before), s_size(after))


def s_drop_go(+items: List<&2, String>, index: Nat) -> String:
  match items index:
    case Nil{} _: ""
    case +item <> _ 0n: item
    case _ <> rest 1n+rest_index: s_drop_go(rest, rest_index)

def s_at(+items: List<&2, String>, index: Nat) -> String:
  s_drop_go(items, index)

def s_at_desc(+items: List<&2, BIR.Descriptor>, index: Nat) -> BIR.Descriptor:
  match items index:
    case Nil{} _: BIR.DescriptorNull{}
    case +item <> _ 0n: item
    case _ <> rest 1n+rest_index: s_at_desc(rest, rest_index)

def s_maybe_string(found: Maybe<&2, String>, fallback: String) -> String:
  match found:
    case Some{value}: value
    case None{}: fallback

def s_map_string(+map: Map<&2, String>, +key: String, fallback: String) -> String:
  s_maybe_string(IndexLookup.find(String, map, key), fallback)


def s_flag_set_at(found: Maybe<&2, Bool>, +flags: Map<&2, Bool>, key: String) -> FlagOut:
  match found:
    case Some{_}: FlagOut{flags, False{}}
    case None{}: FlagOut{Map.set(&2, Bool, flags, key, True{}), True{}}

def s_flag_set(+flags: Map<&2, Bool>, +key: String) -> FlagOut:
  s_flag_set_at(IndexLookup.find(Bool, flags, key), flags, key)

def s_flag_at(found: Maybe<&2, Bool>) -> Bool:
  match found:
    case Some{value}: value
    case None{}: False{}

def s_flag_has(+flags: Map<&2, Bool>, +key: String) -> Bool:
  s_flag_at(IndexLookup.find(Bool, flags, key))


def s_count_at(found: Maybe<&2, Nat>, +counts: Map<&2, Nat>, key: String) -> CountOut:
  match found:
    case Some{value}: CountOut{Map.set(&2, Nat, counts, key, Nat.add(value, 1n)), True{}}
    case None{}: CountOut{Map.set(&2, Nat, counts, key, 1n), True{}}

def s_count_key(+counts: Map<&2, Nat>, +key: String) -> CountOut:
  s_count_at(IndexLookup.find(Nat, counts, key), counts, key)

def s_map_nat_at(found: Maybe<&2, Nat>) -> Nat:
  match found:
    case Some{value}: value
    case None{}: 0n

def s_map_nat(+map: Map<&2, Nat>, +key: String) -> Nat:
  s_map_nat_at(IndexLookup.find(Nat, map, key))

def s_map_bool_at(found: Maybe<&2, Bool>) -> Bool:
  match found:
    case Some{value}: value
    case None{}: False{}

def s_map_bool(+map: Map<&2, Bool>, +key: String) -> Bool:
  s_map_bool_at(IndexLookup.find(Bool, map, key))

def s_live_quantity(quantity: BIR.Quantity) -> Bool:
  match quantity:
    case BIR.Erased{}: False{}
    case _: True{}

# ---------------------------------------------------------------------------
# Flows: the may-set of heads a value holds, and whether a fact is absent.
# ---------------------------------------------------------------------------

def s_flow_ok(+heads: List<&2, String>) -> Flow:
  Flow{heads, False{}}

def s_flow_unknown() -> Flow:
  Flow{Nil{}, True{}}

def s_flow_merge(left: Flow, right: Flow) -> Flow:
  match left right:
    case Flow{lheads, lunknown} Flow{rheads, runknown}:
      Flow{s_union(lheads, rheads), Bool.or(lunknown, runknown)}

def s_flow_merge_out(+flows: Map<&2, Flow>, +key: String, +merged: List<&2, String>, +before: List<&2, String>, +lunknown: Bool, +runknown: Bool) -> FlowOut:
  FlowOut{
    Map.set(&2, Flow, flows, key, Flow{merged, Bool.or(lunknown, runknown)}),
    Bool.or(s_grew(before, merged), Bool.and(Bool.not(lunknown), runknown))
  }

def s_flow_merge_at(found: Maybe<&2, Flow>, +flows: Map<&2, Flow>, +key: String, +right: Flow) -> FlowOut:
  match found:
    case Some{left}:
      match left:
        case Flow{+lheads, lunknown}:
          match right:
            case Flow{rheads, runknown}:
              merged = s_union(lheads, rheads)
              s_flow_merge_out(flows, key, merged, lheads, lunknown, runknown)
    case None{}:
      FlowOut{Map.set(&2, Flow, flows, key, right), s_flow_nonempty(right)}

def s_flow_merge_map(+flows: Map<&2, Flow>, +key: String, +right: Flow) -> FlowOut:
  s_flow_merge_at(IndexLookup.find(Flow, flows, key), flows, key, right)

def s_flow_at(found: Maybe<&2, Flow>) -> Flow:
  match found:
    case Some{value}: value
    case None{}: s_flow_ok(Nil{})

def s_flow(+flows: Map<&2, Flow>, +key: String) -> Flow:
  s_flow_at(IndexLookup.find(Flow, flows, key))

def s_heads_ok(+list: List<&2, String>) -> Heads:
  Heads{list, False{}, None{}}

def s_heads_unknown() -> Heads:
  Heads{Nil{}, True{}, None{}}

def s_heads_fail(message: String) -> Heads:
  Heads{Nil{}, False{}, Some{message}}

def s_heads_merge(left: Heads, right: Heads) -> Heads:
  match left right:
    case Heads{lheads, lunknown, None{}} Heads{rheads, runknown, None{}}:
      Heads{s_union(lheads, rheads), Bool.or(lunknown, runknown), None{}}
    case Heads{lheads, lunknown, Some{message}} _:
      Heads{lheads, lunknown, Some{message}}
    case _ Heads{_, _, Some{message}}:
      Heads{Nil{}, False{}, Some{message}}

def s_heads_to_flow(heads: Heads) -> Flow:
  match heads:
    case Heads{list, unknown, _}: Flow{list, unknown}

# ---------------------------------------------------------------------------
# Descriptor classification: the heads a declared type may hold
# ---------------------------------------------------------------------------

def s_unapply(descriptor: BIR.Descriptor) -> BIR.Descriptor:
  match descriptor:
    case BIR.DescriptorRef{_, _}: descriptor
    case BIR.DescriptorFill{head, _}: s_unapply(head)
    case BIR.DescriptorPlus{head, _}: s_unapply(head)
    case BIR.DescriptorNamedFill{_, head, _}: s_unapply(head)
    case BIR.DescriptorNamedPlus{_, head, _}: s_unapply(head)
    case BIR.DescriptorApplication{fn, _}: s_unapply(fn)
    case BIR.DescriptorSubstitution{_, _, body}: s_unapply(body)
    case BIR.DescriptorLet{_, body}: s_unapply(body)
    case BIR.DescriptorBind{_, body}: s_unapply(body)
    case _: descriptor

def s_args_list_go(+items: List<&2, BIR.Descriptor>, +acc: List<&2, BIR.Descriptor>) -> List<&2, BIR.Descriptor>:
  match items:
    case Nil{}: acc
    case +item <> rest: s_args_list_go(rest, item <> acc)

def s_args_list(+items: List<&2, BIR.Descriptor>) -> List<&2, BIR.Descriptor>:
  s_args_list_go(items, Nil{})

def s_args_acc(descriptor: BIR.Descriptor, +acc: List<&2, BIR.Descriptor>) -> List<&2, BIR.Descriptor>:
  match descriptor:
    case BIR.DescriptorRef{_, args}: List.reverse(&2, BIR.Descriptor, s_args_list_go(args, acc))
    case BIR.DescriptorFill{_, args}: List.reverse(&2, BIR.Descriptor, s_args_list_go(args, acc))
    case BIR.DescriptorPlus{_, args}: List.reverse(&2, BIR.Descriptor, s_args_list_go(args, acc))
    case BIR.DescriptorNamedFill{_, _, args}: List.reverse(&2, BIR.Descriptor, s_args_list_go(args, acc))
    case BIR.DescriptorNamedPlus{_, _, args}: List.reverse(&2, BIR.Descriptor, s_args_list_go(args, acc))
    case BIR.DescriptorApplication{fn, arg}: s_args_acc(fn, arg <> acc)
    case BIR.DescriptorSubstitution{_, value, body}: s_args_acc(body, value <> acc)
    case BIR.DescriptorLet{values, body}: s_args_list_go(values, s_args_acc(body, acc))
    case BIR.DescriptorBind{value, body}: s_args_acc(body, value <> acc)
    case _: List.reverse(&2, BIR.Descriptor, acc)

def s_args(descriptor: BIR.Descriptor) -> List<&2, BIR.Descriptor>:
  s_args_acc(descriptor, Nil{})

def s_head_key_at(applied: BIR.Descriptor) -> Maybe<&2, String>:
  match applied:
    case BIR.DescriptorRef{key, _}: Some{key}
    case _: None{}

def s_head_key(descriptor: BIR.Descriptor) -> Maybe<&2, String>:
  s_head_key_at(s_unapply(descriptor))

def s_descriptor_failure(descriptor: BIR.Descriptor) -> Maybe<&2, String>:
  match descriptor:
    case BIR.DescriptorFailure{message}: Some{message}
    case _: None{}

def s_label_heads(+label: String) -> Heads:
  match label:
    case "": s_heads_unknown()
    case "io": s_heads_ok([s_function_head()])
    case "fn": s_heads_ok([s_function_head()])
    case _: s_heads_ok([s_family(label)])

def s_ref_heads_at(found: Maybe<&2, FamilyRow>, +key: String, +label: String) -> Heads:
  match found:
    case Some{_}: s_heads_ok([s_family(key)])
    case None{}: s_label_heads(label)

def s_descriptor_heads_live(fuel: Nat, +families: Map<&2, FamilyRow>, +labels: Map<&2, String>, descriptor: BIR.Descriptor) -> Heads:
  match fuel:
    case 0n: s_heads_unknown()
    case 1n+pred:
      match descriptor:
        case BIR.DescriptorArrow{_, _, _}: s_heads_ok([s_function_head()])
        case BIR.DescriptorLambda{_, _}: s_heads_ok([s_function_head()])
        case BIR.DescriptorRef{+key, _}:
          s_ref_heads_at(IndexLookup.find(FamilyRow, families, key), key, s_map_string(labels, key, ""))
        case BIR.DescriptorConstructor{+key, _}:
          s_ref_heads_at(IndexLookup.find(FamilyRow, families, key), key, s_map_string(labels, key, ""))
        case BIR.DescriptorFill{head, _}: s_descriptor_heads_live(pred, families, labels, head)
        case BIR.DescriptorPlus{head, _}: s_descriptor_heads_live(pred, families, labels, head)
        case BIR.DescriptorNamedFill{_, head, _}: s_descriptor_heads_live(pred, families, labels, head)
        case BIR.DescriptorNamedPlus{_, head, _}: s_descriptor_heads_live(pred, families, labels, head)
        case BIR.DescriptorApplication{fn, _}: s_descriptor_heads_live(pred, families, labels, fn)
        case BIR.DescriptorSubstitution{_, _, body}: s_descriptor_heads_live(pred, families, labels, body)
        case BIR.DescriptorLet{_, body}: s_descriptor_heads_live(pred, families, labels, body)
        case BIR.DescriptorBind{_, body}: s_descriptor_heads_live(pred, families, labels, body)
        case BIR.DescriptorFailure{message}: s_heads_fail(message)
        case BIR.DescriptorQuantityKind{}: s_heads_ok(Nil{})
        case BIR.DescriptorQuantity{quantity}: s_heads_ok(Nil{})
        case BIR.DescriptorKind{_}: s_heads_ok(Nil{})
        case BIR.DescriptorMinimum{_, _}: s_heads_ok(Nil{})
        case BIR.DescriptorEquality{_, _, _}: s_heads_ok(Nil{})
        case BIR.DescriptorReflexivity{}: s_heads_ok(Nil{})
        case _: s_heads_unknown()

def s_descriptor_heads(+families: Map<&2, FamilyRow>, +labels: Map<&2, String>, descriptor: BIR.Descriptor) -> Heads:
  s_descriptor_heads_live(16n, families, labels, descriptor)

def s_io_answer_by_label(+label: String, +families: Map<&2, FamilyRow>, +labels: Map<&2, String>, descriptor: BIR.Descriptor) -> Heads:
  match label:
    case "io": s_descriptor_heads(families, labels, s_at_desc(s_args(descriptor), 0n))
    case _: s_heads_ok(Nil{})

def s_io_answer_at(head: Maybe<&2, String>, +families: Map<&2, FamilyRow>, +labels: Map<&2, String>, descriptor: BIR.Descriptor) -> Heads:
  match head:
    case None{}: s_heads_unknown()
    case Some{key}: s_io_answer_by_label(s_map_string(labels, key, ""), families, labels, descriptor)

def s_io_answer(+families: Map<&2, FamilyRow>, +labels: Map<&2, String>, +descriptor: BIR.Descriptor) -> Heads:
  s_io_answer_at(s_head_key(descriptor), families, labels, descriptor)

# A declared result descriptor: the runtime heads when it is applied.
def s_result_flow(+families: Map<&2, FamilyRow>, +labels: Map<&2, String>, descriptor: BIR.Descriptor) -> Flow:
  s_heads_to_flow(s_descriptor_heads(families, labels, descriptor))

def s_result_payload(+families: Map<&2, FamilyRow>, +labels: Map<&2, String>, descriptor: BIR.Descriptor) -> Flow:
  match descriptor:
    case BIR.DescriptorNull{}: s_flow_ok(Nil{})
    case _: s_heads_to_flow(s_io_answer(families, labels, descriptor))

# ---------------------------------------------------------------------------
# Constructor fields
# ---------------------------------------------------------------------------

def s_arm_field(field: BIR.DescriptorField) -> ArmField:
  match field:
    case BIR.DescriptorField{key, quantity, ty}: ArmField{s_live_quantity(quantity), ty}

def s_fields_build_go(+items: List<&2, BIR.DescriptorField>, +acc: List<&2, ArmField>) -> List<&2, ArmField>:
  match items:
    case Nil{}: List.reverse(&2, ArmField, acc)
    case +item <> rest: s_fields_build_go(rest, s_arm_field(item) <> acc)

def s_fields_build(items: List<&2, BIR.DescriptorField>, acc: List<&2, ArmField>) -> List<&2, ArmField>:
  s_fields_build_go(items, acc)

def s_arms_build_go(+items: List<&2, BIR.DescriptorArm>, +acc: List<&2, ArmRow>) -> List<&2, ArmRow>:
  match items:
    case Nil{}: List.reverse(&2, ArmRow, acc)
    case +item <> rest:
      match item:
        case BIR.DescriptorArm{key, fields}: s_arms_build_go(rest, ArmRow{key, s_fields_build(fields, Nil{})} <> acc)

def s_arm_fields_pick(same: Bool, fields: List<&2, ArmField>, acc: Maybe<&2, List<&2, ArmField>>) -> Maybe<&2, List<&2, ArmField>>:
  match same:
    case True{}: Some{fields}
    case False{}: acc

def s_arm_fields_step(row: ArmRow, ctor_key: String, acc: Maybe<&2, List<&2, ArmField>>) -> Maybe<&2, List<&2, ArmField>>:
  match row:
    case ArmRow{key, fields}: s_arm_fields_pick(String.eq(key, ctor_key), fields, acc)

def s_arm_fields_go(+arms: List<&2, ArmRow>, +ctor_key: String, acc: Maybe<&2, List<&2, ArmField>>) -> Maybe<&2, List<&2, ArmField>>:
  match arms:
    case Nil{}: acc
    case +row <> rest: s_arm_fields_go(rest, ctor_key, s_arm_fields_step(row, ctor_key, acc))

def s_arm_fields(arms: List<&2, ArmRow>, ctor_key: String) -> Maybe<&2, List<&2, ArmField>>:
  s_arm_fields_go(arms, ctor_key, None{})

def s_live_fields_pick(live: Bool, field: ArmField, +acc: List<&2, ArmField>) -> List<&2, ArmField>:
  match live:
    case True{}: field <> acc
    case False{}: acc

def s_live_fields_step(field: ArmField, +acc: List<&2, ArmField>) -> List<&2, ArmField>:
  match field:
    case ArmField{+live, ty}: s_live_fields_pick(live, ArmField{live, ty}, acc)

def s_live_fields_go(+fields: List<&2, ArmField>, +acc: List<&2, ArmField>) -> List<&2, ArmField>:
  match fields:
    case Nil{}: List.reverse(&2, ArmField, acc)
    case +field <> rest: s_live_fields_go(rest, s_live_fields_step(field, acc))

def s_live_fields(fields: List<&2, ArmField>) -> List<&2, ArmField>:
  s_live_fields_go(fields, Nil{})

def s_field_type(field: ArmField) -> BIR.Descriptor:
  match field:
    case ArmField{live, ty}: ty

def s_field_at_go(+fields: List<&2, ArmField>, index: Nat) -> Maybe<&2, BIR.Descriptor>:
  match fields index:
    case Nil{} _: None{}
    case +field <> _ 0n: Some{s_field_type(field)}
    case _ <> rest 1n+rest_index: s_field_at_go(rest, rest_index)

def s_field_at(fields: List<&2, ArmField>, index: Nat) -> Maybe<&2, BIR.Descriptor>:
  s_field_at_go(fields, index)

# ---------------------------------------------------------------------------
# Primitive result families
# ---------------------------------------------------------------------------

def s_word_head(+key: String) -> Heads:
  s_heads_ok([s_family(key)])

def s_array_pair_one(+families: Map<&2, FamilyRow>, +labels: Map<&2, String>, only: BIR.Descriptor) -> Heads:
  s_heads_merge(s_heads_ok([s_family("Sigma")]), s_descriptor_heads(families, labels, only))

def s_array_pair_at(types: List<&2, BIR.Descriptor>, +families: Map<&2, FamilyRow>, +labels: Map<&2, String>) -> Heads:
  match types:
    case Nil{}: s_heads_unknown()
    case +only <> Nil{}: s_array_pair_one(families, labels, only)
    case _: s_heads_unknown()

def s_primitive_heads(+families: Map<&2, FamilyRow>, +labels: Map<&2, String>, primitive: BIR.Primitive, types: List<&2, BIR.Descriptor>) -> Heads:
  match primitive:
    case BIR.PrimArrayNew{}: s_word_head("Array")
    case BIR.PrimArraySet{}: s_word_head("Array")
    case BIR.PrimArrayClone{}: s_word_head("Array")
    case BIR.PrimArrayLeaf{}: s_word_head("Array")
    case BIR.PrimArrayNode{}: s_word_head("Array")
    case BIR.PrimArrayLeft{}: s_word_head("Array")
    case BIR.PrimArrayRight{}: s_word_head("Array")
    case BIR.PrimArraySize{}: s_word_head("Nat")
    case BIR.PrimArrayGet{}: s_array_pair_at(types, families, labels)
    case BIR.PrimArraySwap{}: s_array_pair_at(types, families, labels)
    case BIR.PrimArrayLeafValue{}: s_descriptor_heads(families, labels, s_at_desc(types, 0n))
    case BIR.PrimIsArrayLeaf{}: s_word_head("Bool")
    case BIR.PrimIsArrayNode{}: s_word_head("Bool")
    case BIR.PrimNatAdd{}: s_word_head("Nat")
    case BIR.PrimNatSub{}: s_word_head("Nat")
    case BIR.PrimNatMul{}: s_word_head("Nat")
    case BIR.PrimNatCmp{}: s_word_head("Cmp")
    case BIR.PrimNatMin{}: s_word_head("Nat")
    case BIR.PrimNatMax{}: s_word_head("Nat")
    case BIR.PrimNatDouble{}: s_word_head("Nat")
    case BIR.PrimNatIsLt{}: s_word_head("Bool")
    case BIR.PrimNatDivmod{}: s_word_head("Sigma")
    case BIR.PrimNatPredecessor{}: s_word_head("Nat")
    case BIR.PrimNatSuccessor{}: s_word_head("Nat")
    case BIR.PrimIsNatZero{}: s_word_head("Bool")
    case BIR.PrimIsNatSuccessor{}: s_word_head("Bool")
    case BIR.PrimU32Add{}: s_word_head("U32")
    case BIR.PrimU32Sub{}: s_word_head("U32")
    case BIR.PrimU32Mul{}: s_word_head("U32")
    case BIR.PrimU32Div{}: s_word_head("U32")
    case BIR.PrimU32Mod{}: s_word_head("U32")
    case BIR.PrimU32And{}: s_word_head("U32")
    case BIR.PrimU32Or{}: s_word_head("U32")
    case BIR.PrimU32Xor{}: s_word_head("U32")
    case BIR.PrimU32Not{}: s_word_head("U32")
    case BIR.PrimU32Inc{}: s_word_head("U32")
    case BIR.PrimU32Shl{}: s_word_head("U32")
    case BIR.PrimU32Shr{}: s_word_head("U32")
    case BIR.PrimU32Shln{}: s_word_head("U32")
    case BIR.PrimU32Shrn{}: s_word_head("U32")
    case BIR.PrimU32Cmp{}: s_word_head("Cmp")
    case BIR.PrimU32IsEq{}: s_word_head("Bool")
    case BIR.PrimU32IsNe{}: s_word_head("Bool")
    case BIR.PrimU32IsLt{}: s_word_head("Bool")
    case BIR.PrimU32IsLe{}: s_word_head("Bool")
    case BIR.PrimU32IsGt{}: s_word_head("Bool")
    case BIR.PrimU32IsGe{}: s_word_head("Bool")
    case BIR.PrimU32IsZero{}: s_word_head("Bool")
    case BIR.PrimU32ToNat{}: s_word_head("Nat")
    case BIR.PrimU32FromNat{}: s_word_head("U32")
    case BIR.PrimU32ToF32{}: s_word_head("F32")
    case BIR.PrimU32ToWord{}: s_word_head("Word.Con")
    case BIR.PrimWordToU32{}: s_word_head("U32")
    case BIR.PrimF32Add{}: s_word_head("F32")
    case BIR.PrimF32Sub{}: s_word_head("F32")
    case BIR.PrimF32Mul{}: s_word_head("F32")
    case BIR.PrimF32Div{}: s_word_head("F32")
    case BIR.PrimF32Mod{}: s_word_head("F32")
    case BIR.PrimF32Neg{}: s_word_head("F32")
    case BIR.PrimF32Sqrt{}: s_word_head("F32")
    case BIR.PrimF32Abs{}: s_word_head("F32")
    case BIR.PrimF32Pow{}: s_word_head("F32")
    case BIR.PrimF32Atan2{}: s_word_head("F32")
    case BIR.PrimF32Exp{}: s_word_head("F32")
    case BIR.PrimF32Log{}: s_word_head("F32")
    case BIR.PrimF32Log2{}: s_word_head("F32")
    case BIR.PrimF32Log10{}: s_word_head("F32")
    case BIR.PrimF32Sin{}: s_word_head("F32")
    case BIR.PrimF32Cos{}: s_word_head("F32")
    case BIR.PrimF32Tan{}: s_word_head("F32")
    case BIR.PrimF32Asin{}: s_word_head("F32")
    case BIR.PrimF32Acos{}: s_word_head("F32")
    case BIR.PrimF32Atan{}: s_word_head("F32")
    case BIR.PrimF32Sinh{}: s_word_head("F32")
    case BIR.PrimF32Cosh{}: s_word_head("F32")
    case BIR.PrimF32Tanh{}: s_word_head("F32")
    case BIR.PrimF32Floor{}: s_word_head("F32")
    case BIR.PrimF32Ceil{}: s_word_head("F32")
    case BIR.PrimF32Trunc{}: s_word_head("F32")
    case BIR.PrimF32ToU32{}: s_word_head("U32")
    case BIR.PrimF32ToNat{}: s_word_head("Nat")
    case BIR.PrimF32Bits{}: s_word_head("U32")
    case BIR.PrimF32FromBits{}: s_word_head("F32")
    case BIR.PrimF32FromWord{}: s_word_head("F32")
    case BIR.PrimF32ToWord{}: s_word_head("Word.Con")
    case BIR.PrimF32Show{}: s_word_head("String")
    case BIR.PrimF32Read{}: s_word_head("F32")
    case BIR.PrimF32IsEq{}: s_word_head("Bool")
    case BIR.PrimF32IsNe{}: s_word_head("Bool")
    case BIR.PrimF32IsLt{}: s_word_head("Bool")
    case BIR.PrimF32IsLe{}: s_word_head("Bool")
    case BIR.PrimF32IsGt{}: s_word_head("Bool")
    case BIR.PrimF32IsGe{}: s_word_head("Bool")
    case BIR.PrimStringAppend{}: s_word_head("String")
    case BIR.PrimStringEq{}: s_word_head("Bool")
    case BIR.PrimStringCmp{}: s_word_head("Sigma")
    case BIR.PrimStringToList{}: s_word_head("List")
    case BIR.PrimStringLength{}: s_word_head("Nat")
    case BIR.PrimStringHead{}: s_word_head("Char")
    case BIR.PrimStringTail{}: s_word_head("String")
    case BIR.PrimIsStringEmpty{}: s_word_head("Bool")
    case BIR.PrimIsStringNonempty{}: s_word_head("Bool")
    case BIR.PrimCharNew{}: s_word_head("Char")
    case BIR.PrimCharCode{}: s_word_head("U32")
    case BIR.PrimMapBit{}: s_word_head("Sigma")
    case BIR.PrimBoolOr{}: s_word_head("Bool")
    case BIR.PrimBoolXor{}: s_word_head("Bool")
    case BIR.PrimIsTrue{}: s_word_head("Bool")
    case BIR.PrimIsFalse{}: s_word_head("Bool")
    case BIR.PrimSameValue{}: s_word_head("Bool")
    case BIR.PrimFloatBitsEqual{}: s_word_head("Bool")
    case _: s_heads_unknown()

def s_is_array_prim(primitive: BIR.Primitive) -> Bool:
  match primitive:
    case BIR.PrimArrayNew{}: True{}
    case BIR.PrimArraySet{}: True{}
    case BIR.PrimArrayGet{}: True{}
    case BIR.PrimArraySwap{}: True{}
    case BIR.PrimArraySize{}: True{}
    case BIR.PrimArrayClone{}: True{}
    case BIR.PrimArrayLeaf{}: True{}
    case BIR.PrimArrayNode{}: True{}
    case BIR.PrimArrayLeafValue{}: True{}
    case BIR.PrimArrayLeft{}: True{}
    case BIR.PrimArrayRight{}: True{}
    case BIR.PrimIsArrayLeaf{}: True{}
    case BIR.PrimIsArrayNode{}: True{}
    case _: False{}


# ---------------------------------------------------------------------------
# Catalog: families, type-function labels, constructors, declarations, codes
# ---------------------------------------------------------------------------

def s_typefn_label_applied(applied: BIR.Descriptor) -> String:
  match applied:
    case BIR.DescriptorRef{key, _}: key
    case BIR.DescriptorArrow{_, _, _}: "fn"
    case BIR.DescriptorLambda{_, _}: "fn"
    case _: ""

def s_typefn_label_at(word: Bool, applied: BIR.Descriptor) -> String:
  match word:
    case True{}: "Word.Con"
    case False{}: s_typefn_label_applied(applied)

def s_typefn_label_io(io: Bool) -> String:
  match io:
    case True{}: "io"
    case False{}: ""

def s_typefn_label_io_case(label: String, name: String) -> String:
  match label:
    case "": s_typefn_label_io(String.eq(name, "IO"))
    case _: label

def s_typefn_label_final(+name: String, body: BIR.Descriptor) -> String:
  s_typefn_label_io_case(s_typefn_label_at(String.eq(name, "Word"), s_unapply(body)), name)

type CatBuild is Data:
  CatBuild{
    family_by_key: Map<&2, FamilyRow>,
    family_of_ctor: Map<&2, String>,
    typefn_label: Map<&2, String>,
    ctor_by_key: Map<&2, CtorRow>,
    ctor_by_id: Map<&2, CtorRow>,
    ctor_keys: List<&2, String>,
    foreign_keys: List<&2, String>,
    family_keys: List<&2, String>,
    decl_by_key: Map<&2, DeclRow>,
    decl_key_by_code: Map<&2, String>,
    code_params: Map<&2, List<&2, U32>>,
    code_captures: Map<&2, Nat>,
    failure: Maybe<&2, String>
  }

def s_cat_new() -> CatBuild:
  CatBuild{
    Map.new(&2, FamilyRow),
    Map.new(&2, String),
    Map.new(&2, String),
    Map.new(&2, CtorRow),
    Map.new(&2, CtorRow),
    Nil{},
    Nil{},
    Nil{},
    Map.new(&2, DeclRow),
    Map.new(&2, String),
    Map.new(&2, List<&2, U32>),
    Map.new(&2, Nat),
    None{}
  }

def s_cat_fail(+build: CatBuild, message: String) -> CatBuild:
  match build:
    case CatBuild{a, b, c, d, e, f, g, h, i, j, k, l, failure}:
      match failure:
        case Some{_}: CatBuild{a, b, c, d, e, f, g, h, i, j, k, l, failure}
        case None{}: CatBuild{a, b, c, d, e, f, g, h, i, j, k, l, Some{message}}

def s_cat_set_family(build: CatBuild, +key: String, row: FamilyRow) -> CatBuild:
  match build:
    case CatBuild{family_by_key, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{Map.set(&2, FamilyRow, family_by_key, key, row), foc, tl, cbk, cbi, ck, fk, key <> fkeys, dbk, dkbc, cp, cc, failure}

def s_families_build_go(+items: List<&2, BIR.Family>, +build: CatBuild) -> CatBuild:
  match items:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
          s_families_build_go(rest, s_cat_set_family(build, key, FamilyRow{key, native, arity, s_arms_build_go(arms, Nil{})}))

def s_cat_set_label(build: CatBuild, key: String, label: String) -> CatBuild:
  match build:
    case CatBuild{fby, foc, typefn_label, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{fby, foc, Map.set(&2, String, typefn_label, key, label), cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}

def s_typefns_build_go(+items: List<&2, BIR.TypeFunction>, +build: CatBuild) -> CatBuild:
  match items:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
          s_typefns_build_go(rest, s_cat_set_label(build, key, s_typefn_label_final(key, body)))

def s_cat_put_ctor(+build: CatBuild, +key: String, id: U32, +row: CtorRow) -> CatBuild:
  match build:
    case CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{fby, foc, tl, Map.set(&2, CtorRow, cbk, key, row), Map.set(&2, CtorRow, cbi, U32.show(id), row), key <> ck, fk, fkeys, dbk, dkbc, cp, cc, failure}

def s_cat_ctor_map(build: CatBuild) -> Map<&2, CtorRow>:
  match build:
    case CatBuild{_, _, _, ctor_by_key, _, _, _, _, _, _, _, _, _}: ctor_by_key

def s_cat_add_ctor_at(found: Maybe<&2, CtorRow>, +build: CatBuild, +key: String, id: U32, +row: CtorRow) -> CatBuild:
  match found:
    case Some{_}: s_cat_fail(build, s_cat2("constructor key appears twice: ", key))
    case None{}: s_cat_put_ctor(build, key, id, row)

def s_cat_add_ctor(+build: CatBuild, +key: String, id: U32, row: CtorRow) -> CatBuild:
  s_cat_add_ctor_at(IndexLookup.find(CtorRow, s_cat_ctor_map(build), key), build, key, id, row)

def s_ctors_build_go(+items: List<&2, BIR.ConstructorLayout>, +build: CatBuild) -> CatBuild:
  match items:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.ConstructorLayout{id, key, native, fields}:
          s_ctors_build_go(rest, s_cat_add_ctor(build, key, id, CtorRow{id, key, ""}))

def s_cat_put_family_of(build: CatBuild, ctor_key: String, family: String) -> CatBuild:
  match build:
    case CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{fby, Map.set(&2, String, foc, ctor_key, family), tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}

def s_arms_link(+family: String, +arms: List<&2, BIR.DescriptorArm>, +build: CatBuild) -> CatBuild:
  match arms:
    case Nil{}: build
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key, fields}: s_arms_link(family, rest, s_cat_put_family_of(build, key, family))

def s_family_of_ctor_build_go(+items: List<&2, BIR.Family>, +build: CatBuild) -> CatBuild:
  match items:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
          s_family_of_ctor_build_go(rest, s_arms_link(key, arms, build))

def s_ctor_id(row: CtorRow) -> U32:
  match row:
    case CtorRow{id, key, family}: id

def s_cat_set_family_at(found: Maybe<&2, CtorRow>, +build: CatBuild, +key: String, new_family: String) -> CatBuild:
  match found:
    case None{}: build
    case Some{+row}: s_cat_put_ctor(build, key, s_ctor_id(row), CtorRow{s_ctor_id(row), key, new_family})

def s_cat_set_family_of_ctor(+build: CatBuild, +key: String, family: String) -> CatBuild:
  s_cat_set_family_at(IndexLookup.find(CtorRow, s_cat_ctor_map(build), key), build, key, family)

def s_cat_family_of_map(build: CatBuild) -> Map<&2, String>:
  match build:
    case CatBuild{_, family_of_ctor, _, _, _, _, _, _, _, _, _, _, _}: family_of_ctor

def s_ctor_relink_at(found: Maybe<&2, String>, +build: CatBuild, +key: String) -> CatBuild:
  match found:
    case None{}: s_cat_fail(build, s_cat2("no family declares constructor ", key))
    case Some{family}: s_cat_set_family_of_ctor(build, key, family)

def s_ctor_relink(+build: CatBuild, +key: String) -> CatBuild:
  s_ctor_relink_at(IndexLookup.find(String, s_cat_family_of_map(build), key), build, key)

def s_ctors_link_go(+items: List<&2, BIR.ConstructorLayout>, +build: CatBuild) -> CatBuild:
  match items:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.ConstructorLayout{id, key, native, fields}:
          s_ctors_link_go(rest, s_ctor_relink(build, key))

def s_live_quantity_next(item: BIR.Quantity, count: Nat) -> Nat:
  match item:
    case BIR.Erased{}: count
    case _: Nat.add(count, 1n)

def s_live_quantities_go(+items: List<&2, BIR.Quantity>, count: Nat) -> Nat:
  match items:
    case Nil{}: count
    case +item <> rest: s_live_quantities_go(rest, s_live_quantity_next(item, count))

def s_live_quantities(items: List<&2, BIR.Quantity>, count: Nat) -> Nat:
  s_live_quantities_go(items, count)

def s_cat_put_decl_plain(build: CatBuild, +key: String, +row: DeclRow) -> CatBuild:
  match build:
    case CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, Map.set(&2, DeclRow, dbk, key, row), dkbc, cp, cc, failure}

def s_cat_put_decl_code(build: CatBuild, +key: String, code: U32, +row: DeclRow) -> CatBuild:
  match build:
    case CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, Map.set(&2, DeclRow, dbk, key, row), Map.set(&2, String, dkbc, U32.show(code), key), cp, cc, failure}

def s_cat_put_decl_at(is_fn: Bool, +build: CatBuild, +key: String, code: U32, +row: DeclRow) -> CatBuild:
  match is_fn:
    case True{}: s_cat_put_decl_code(build, key, code, row)
    case False{}: s_cat_put_decl_plain(build, key, row)

def s_decl_key(row: DeclRow) -> String:
  match row:
    case DeclRow{key, kind, code, arity, result, primitive, has_primitive}: key

def s_decl_code(row: DeclRow) -> U32:
  match row:
    case DeclRow{key, kind, code, arity, result, primitive, has_primitive}: code

def s_decl_kind(row: DeclRow) -> String:
  match row:
    case DeclRow{key, kind, code, arity, result, primitive, has_primitive}: kind

def s_cat_put_decl(+build: CatBuild, +row: DeclRow) -> CatBuild:
  s_cat_put_decl_at(String.eq(s_decl_kind(row), "fn"), build, s_decl_key(row), s_decl_code(row), row)

def s_foreign_add_at(found: Bool, +keys: List<&2, String>, +key: String) -> List<&2, String>:
  match found:
    case True{}: keys
    case False{}: key <> keys

def s_foreign_add(+keys: List<&2, String>, +key: String) -> List<&2, String>:
  s_foreign_add_at(s_member(keys, key), keys, key)

def s_cat_put_foreign(+build: CatBuild, +key: String, +row: DeclRow) -> CatBuild:
  match build:
    case CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{fby, foc, tl, cbk, cbi, ck, s_foreign_add(fk, key), fkeys, Map.set(&2, DeclRow, dbk, key, row), dkbc, cp, cc, failure}

def s_decl_build(build: CatBuild, item: BIR.Declaration) -> CatBuild:
  match item:
    case BIR.FunctionDeclaration{+key, code, parameters}:
      s_cat_put_decl(build, DeclRow{key, "fn", code, List.length(&2, BIR.Parameter, parameters), BIR.DescriptorNull{}, BIR.PrimU32Add{}, False{}})
    case BIR.LazyDeclaration{+key, body}:
      s_cat_put_decl(build, DeclRow{key, "lazy", 0, 0n, BIR.DescriptorNull{}, BIR.PrimU32Add{}, False{}})
    case BIR.NativeDeclaration{+key, primitive, quantities}:
      s_cat_put_decl(build, DeclRow{key, "native", 0, s_live_quantities(quantities, 0n), BIR.DescriptorNull{}, primitive, True{}})
    case BIR.ForeignDeclaration{+key, namespace, imported, arity, sources, quantities, span, parameter_types, result}:
      s_cat_put_foreign(build, key, DeclRow{key, "foreign", 0, arity, result, BIR.PrimU32Add{}, False{}})

def s_decls_build_go(+items: List<&2, BIR.Declaration>, +build: CatBuild) -> CatBuild:
  match items:
    case Nil{}: build
    case +item <> rest: s_decls_build_go(rest, s_decl_build(build, item))

def s_param_ids_go(+parameters: List<&2, BIR.Parameter>, +acc: List<&2, U32>) -> List<&2, U32>:
  match parameters:
    case Nil{}: List.reverse(&2, U32, acc)
    case +param <> rest:
      match param:
        case BIR.Parameter{id, use}: s_param_ids_go(rest, id <> acc)

def s_param_ids(parameters: List<&2, BIR.Parameter>, acc: List<&2, U32>) -> List<&2, U32>:
  s_param_ids_go(parameters, acc)

def s_cat_put_code(build: CatBuild, +key: String, params: List<&2, U32>, captures: Nat) -> CatBuild:
  match build:
    case CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, cp, cc, failure}:
      CatBuild{fby, foc, tl, cbk, cbi, ck, fk, fkeys, dbk, dkbc, Map.set(&2, List<&2, U32>, cp, key, params), Map.set(&2, Nat, cc, key, captures), failure}

def s_codes_build_go(+codes: List<&2, BIR.Code>, +build: CatBuild) -> CatBuild:
  match codes:
    case Nil{}: build
    case +code <> rest:
      match code:
        case BIR.Code{id, captures, parameters, body}:
          s_codes_build_go(rest, s_cat_put_code(build, U32.show(id), s_param_ids(parameters, Nil{}), List.length(&2, BIR.Use, captures)))

def s_catalog_build_all(codes: List<&2, BIR.Code>, declarations: List<&2, BIR.Declaration>, +constructors: List<&2, BIR.ConstructorLayout>, +families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> CatBuild:
  b1 = s_families_build_go(families, s_cat_new())
  b2 = s_typefns_build_go(type_functions, b1)
  b3 = s_ctors_build_go(constructors, b2)
  b4 = s_family_of_ctor_build_go(families, b3)
  b5 = s_ctors_link_go(constructors, b4)
  b6 = s_decls_build_go(declarations, b5)
  s_codes_build_go(codes, b6)

def s_catalog_build(program: BIR.Program) -> CatBuild:
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, ending}:
      s_catalog_build_all(codes, declarations, constructors, families, type_functions)

def s_catalog_of(build: CatBuild) -> Catalog:
  match build:
    case CatBuild{family_by_key, foc, typefn_label, ctor_by_key, ctor_by_id, ctor_keys, foreign_keys, family_keys, dbk, dkbc, cp, cc, failure}:
      Catalog{ctor_by_key, ctor_by_id, family_by_key, typefn_label, ctor_keys, foreign_keys, family_keys, failure}

def s_decls_of(build: CatBuild) -> DeclFacts:
  match build:
    case CatBuild{_, _, _, _, _, _, _, _, decl_by_key, decl_key_by_code, code_params, code_captures, _}:
      DeclFacts{decl_by_key, decl_key_by_code, code_params, code_captures}

def s_catalog_families(catalog: Catalog) -> Map<&2, FamilyRow>:
  match catalog:
    case Catalog{_, _, family_by_key, _, _, _, _, _}: family_by_key

def s_catalog_labels(catalog: Catalog) -> Map<&2, String>:
  match catalog:
    case Catalog{_, _, _, typefn_label, _, _, _, _}: typefn_label

def s_catalog_ctors_by_key(catalog: Catalog) -> Map<&2, CtorRow>:
  match catalog:
    case Catalog{ctor_by_key, _, _, _, _, _, _, _}: ctor_by_key

def s_catalog_ctors_by_id(catalog: Catalog) -> Map<&2, CtorRow>:
  match catalog:
    case Catalog{_, ctor_by_id, _, _, _, _, _, _}: ctor_by_id

def s_catalog_ctor_keys(catalog: Catalog) -> List<&2, String>:
  match catalog:
    case Catalog{_, _, _, _, ctor_keys, _, _, _}: ctor_keys

def s_catalog_foreign_keys(catalog: Catalog) -> List<&2, String>:
  match catalog:
    case Catalog{_, _, _, _, _, foreign_keys, _, _}: foreign_keys

def s_catalog_family_keys(catalog: Catalog) -> List<&2, String>:
  match catalog:
    case Catalog{_, _, _, _, _, _, family_keys, _}: family_keys

def s_catalog_failure(catalog: Catalog) -> Maybe<&2, String>:
  match catalog:
    case Catalog{_, _, _, _, _, _, _, failure}: failure

def s_decls_decl(decls: DeclFacts) -> Map<&2, DeclRow>:
  match decls:
    case DeclFacts{decl_by_key, _, _, _}: decl_by_key

def s_decls_by_code(decls: DeclFacts) -> Map<&2, String>:
  match decls:
    case DeclFacts{_, decl_key_by_code, _, _}: decl_key_by_code

def s_decls_params(decls: DeclFacts) -> Map<&2, List<&2, U32>>:
  match decls:
    case DeclFacts{_, _, code_params, _}: code_params

def s_decls_captures(decls: DeclFacts) -> Map<&2, Nat>:
  match decls:
    case DeclFacts{_, _, _, code_captures}: code_captures

# ---------------------------------------------------------------------------
# Bodies
# ---------------------------------------------------------------------------

def s_bodies_codes_go(+codes: List<&2, BIR.Code>, +acc: List<&2, BodyRow>) -> List<&2, BodyRow>:
  match codes:
    case Nil{}: List.reverse(&2, BodyRow, acc)
    case +code <> rest:
      match code:
        case BIR.Code{id, captures, parameters, body}:
          s_bodies_codes_go(rest, BodyRow{id, s_code_body(id), None{}, body, s_param_ids(parameters, Nil{}), List.length(&2, BIR.Use, captures)} <> acc)

def s_bodies_decls_go(+items: List<&2, BIR.Declaration>, +acc: List<&2, BodyRow>) -> List<&2, BodyRow>:
  match items:
    case Nil{}: List.reverse(&2, BodyRow, acc)
    case +item <> rest:
      match item:
        case BIR.LazyDeclaration{key, body}:
          s_bodies_decls_go(rest, BodyRow{0, s_lazy_body(key), Some{key}, body, Nil{}, 0n} <> acc)
        case _: s_bodies_decls_go(rest, acc)

def s_all_bodies(codes: List<&2, BIR.Code>, declarations: List<&2, BIR.Declaration>) -> List<&2, BodyRow>:
  s_bodies_codes_go(codes, s_bodies_decls_go(declarations, Nil{}))

def s_body_owner(row: BodyRow) -> U32:
  match row:
    case BodyRow{owner, bkey, lazy, body, params, capture_count}: owner

def s_body_bkey(row: BodyRow) -> String:
  match row:
    case BodyRow{owner, bkey, lazy, body, params, capture_count}: bkey


# ---------------------------------------------------------------------------
# Reachability: only code that can run may contribute a sharing site
# ---------------------------------------------------------------------------

def s_reach_new() -> Reach:
  Reach{Map.new(&2, Bool), Map.new(&2, Bool), Nil{}, False{}, True{}}

def s_reach_keys(reach: Reach) -> Map<&2, Bool>:
  match reach:
    case Reach{keys, codes, escape, dynamic, changed}: keys

def s_reach_codes(reach: Reach) -> Map<&2, Bool>:
  match reach:
    case Reach{keys, codes, escape, dynamic, changed}: codes

def s_reach_escapes(reach: Reach) -> List<&2, U32>:
  match reach:
    case Reach{keys, codes, escape, dynamic, changed}: escape

def s_reach_changed(reach: Reach) -> Bool:
  match reach:
    case Reach{keys, codes, escape, dynamic, changed}: changed

def s_reach_flag_out(+reach: Reach, fo: FlagOut) -> Reach:
  match reach:
    case Reach{_, codes, escape, dynamic, changed}:
      match fo:
        case FlagOut{+flags, grew}: Reach{flags, codes, escape, dynamic, Bool.or(changed, grew)}

def s_reach_add_key(+reach: Reach, +key: String) -> Reach:
  match reach:
    case Reach{+keys, codes, escape, dynamic, changed}:
      s_reach_flag_out(Reach{keys, codes, escape, dynamic, changed}, s_flag_set(keys, key))

def s_reach_code_out(+reach: Reach, fo: FlagOut) -> Reach:
  match reach:
    case Reach{keys, _, escape, dynamic, changed}:
      match fo:
        case FlagOut{+flags, grew}: Reach{keys, flags, escape, dynamic, Bool.or(changed, grew)}

def s_reach_add_code(+reach: Reach, code: U32) -> Reach:
  match reach:
    case Reach{keys, +codes, escape, dynamic, changed}:
      s_reach_code_out(Reach{keys, codes, escape, dynamic, changed}, s_flag_set(codes, U32.show(code)))

def s_member_u32_go(+items: List<&2, U32>, +key: U32, found: Bool) -> Bool:
  match items:
    case Nil{}: found
    case +item <> rest: s_member_u32_go(rest, key, Bool.or(found, U32.is_eq(item, key)))

def s_member_u32(+items: List<&2, U32>, +key: U32) -> Bool:
  s_member_u32_go(items, key, False{})

def s_reach_escape_out(+reach: Reach, +code: U32, found: Bool) -> Reach:
  match reach:
    case Reach{keys, codes, +escape, dynamic, changed}:
      match found:
        case True{}: Reach{keys, codes, escape, dynamic, changed}
        case False{}: Reach{keys, codes, code <> escape, dynamic, True{}}

def s_reach_add_escape(+reach: Reach, +code: U32) -> Reach:
  s_reach_escape_out(reach, code, s_member_u32(s_reach_escapes(reach), code))

def s_reach_dynamic(+reach: Reach) -> Reach:
  match reach:
    case Reach{keys, codes, escape, False{}, changed}: Reach{keys, codes, escape, True{}, True{}}
    case Reach{keys, codes, escape, True{}, changed}: Reach{keys, codes, escape, True{}, changed}

def s_reach_atom(atom: BIR.Atom, reach: Reach) -> Reach:
  match atom:
    case BIR.Symbol{_, key}: s_reach_add_key(reach, key)
    case _: reach

def s_reach_value_arg(arg: BIR.Arg, reach: Reach) -> Reach:
  match arg:
    case BIR.Arg{_, value}: s_reach_atom(value, reach)

def s_reach_args_go(+args: List<&2, BIR.Arg>, +reach: Reach) -> Reach:
  match args:
    case Nil{}: reach
    case +arg <> rest: s_reach_args_go(rest, s_reach_value_arg(arg, reach))

def s_reach_args(args: List<&2, BIR.Arg>, reach: Reach) -> Reach:
  s_reach_args_go(args, reach)

def s_reach_fields_go(+fields: List<&2, BIR.Field>, +reach: Reach) -> Reach:
  match fields:
    case Nil{}: reach
    case +field <> rest:
      match field:
        case BIR.Field{_, _, _, value}: s_reach_fields_go(rest, s_reach_atom(value, reach))

def s_reach_fields(fields: List<&2, BIR.Field>, reach: Reach) -> Reach:
  s_reach_fields_go(fields, reach)

def s_reach_op(op: BIR.Op, reach: Reach) -> Reach:
  match op:
    case BIR.Copy{value}: s_reach_atom(value, reach)
    case BIR.PrimitiveCall{primitive, args, types}: s_reach_args(args, reach)
    case BIR.Closure{code, captures, parameters}: s_reach_args(captures, s_reach_add_escape(reach, code))
    case BIR.Direct{code, args}: s_reach_args(args, s_reach_add_code(reach, code))
    case BIR.Apply{fn, arg}: s_reach_value_arg(arg, s_reach_atom(fn, s_reach_dynamic(reach)))
    case BIR.LoadSymbol{_, key}: s_reach_add_key(reach, key)
    case BIR.Construct{constructor, tag, fields}: s_reach_fields(fields, reach)
    case BIR.Project{value, constructor, field, key}: s_reach_atom(value, reach)
    case BIR.HasTag{value, constructor, tag}: s_reach_atom(value, reach)
    case _: reach

def s_reach_block(block: BIR.Block, reach: Reach) -> Reach:
  match block:
    case BIR.Return{value}: s_reach_atom(value, reach)
    case BIR.Let{id, op, next}: s_reach_block(next, s_reach_op(op, reach))
    case BIR.Branch{condition, yes, no}: s_reach_block(no, s_reach_block(yes, s_reach_atom(condition, reach)))
    case BIR.Region{label, body, next}: s_reach_block(next, s_reach_block(body, reach))
    case BIR.LeaveRegion{label}: reach
    case BIR.TailDirect{code, args}: s_reach_args(args, s_reach_add_code(reach, code))
    case BIR.TailApply{fn, arg}: s_reach_value_arg(arg, s_reach_atom(fn, s_reach_dynamic(reach)))
    case BIR.Failure{message}: reach

def s_reach_body_if(on: Bool, body: BIR.Block, +reach: Reach) -> Reach:
  match on:
    case True{}: s_reach_block(body, reach)
    case False{}: reach

def s_reach_body_at(owner: U32, lazy: Maybe<&2, String>, body: BIR.Block, +reach: Reach) -> Reach:
  match lazy:
    case Some{key}: s_reach_body_if(s_flag_has(s_reach_keys(reach), key), body, reach)
    case None{}: s_reach_body_if(s_flag_has(s_reach_codes(reach), U32.show(owner)), body, reach)

def s_reach_body(row: BodyRow, +reach: Reach) -> Reach:
  match row:
    case BodyRow{owner, bkey, lazy, body, params, capture_count}:
      s_reach_body_at(owner, lazy, body, reach)

def s_reach_bodies_go(+rows: List<&2, BodyRow>, +reach: Reach) -> Reach:
  match rows:
    case Nil{}: reach
    case +row <> rest:
      scanned = s_reach_body(row, reach)
      s_reach_bodies_go(rest, scanned)

def s_reach_fn_at(on: Bool, +reach: Reach, code: U32) -> Reach:
  match on:
    case True{}: s_reach_add_code(reach, code)
    case False{}: reach

def s_reach_fn(+reach: Reach, +key: String, code: U32) -> Reach:
  s_reach_fn_at(s_flag_has(s_reach_keys(reach), key), reach, code)

def s_reach_decls_go(+items: List<&2, BIR.Declaration>, +reach: Reach) -> Reach:
  match items:
    case Nil{}: reach
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}: s_reach_decls_go(rest, s_reach_fn(reach, key, code))
        case _: s_reach_decls_go(rest, reach)

def s_reach_escapes_go(+items: List<&2, U32>, +reach: Reach) -> Reach:
  match items:
    case Nil{}: reach
    case +code <> rest: s_reach_escapes_go(rest, s_reach_add_code(reach, code))

def s_reach_after_keys(+reach: Reach) -> Reach:
  s_reach_escapes_go(s_reach_escapes(reach), reach)

def s_reach_of(ro: ReachOut) -> Reach:
  match ro:
    case ReachOut{reach, changed}: reach

def s_reach_out(+reach: Reach) -> ReachOut:
  ReachOut{reach, s_reach_changed(reach)}

def s_reach_reset(+reach: Reach) -> Reach:
  match reach:
    case Reach{keys, codes, escape, dynamic, changed}: Reach{keys, codes, escape, dynamic, False{}}

def s_reach_round(+reach: Reach, +bodies: List<&2, BodyRow>, +decls: List<&2, BIR.Declaration>) -> ReachOut:
  after_bodies = s_reach_bodies_go(bodies, s_reach_reset(reach))
  after_decls = s_reach_decls_go(decls, after_bodies)
  s_reach_out(s_reach_after_keys(after_decls))

def s_reach_fix(fuel: Nat, ro: ReachOut, +bodies: List<&2, BodyRow>, +decls: List<&2, BIR.Declaration>) -> Reach:
  match fuel:
    case 0n:
      match ro:
        case ReachOut{reach, changed}: reach
    case 1n+pred:
      match ro:
        case ReachOut{reach, changed}:
          match changed:
            case False{}: reach
            case True{}: s_reach_fix(pred, s_reach_round(reach, bodies, decls), bodies, decls)

def s_reach_root_entry(entry: Maybe<&2, BIR.Entry>, reach: Reach) -> Reach:
  match entry:
    case None{}: reach
    case Some{BIR.Entry{code, arity}}: s_reach_add_code(reach, code)

def s_reach_roots_exports_go(+items: List<&2, BIR.Export>, +reach: Reach) -> Reach:
  match items:
    case Nil{}: reach
    case +item <> rest:
      match item:
        case BIR.Export{key, entry, parameter_types}:
          s_reach_roots_exports_go(rest, s_reach_root_entry(entry, s_reach_add_key(reach, key)))

def s_reach_roots(ending: BIR.Ending, reach: Reach) -> Reach:
  match ending:
    case BIR.Executable{main_type}: s_reach_add_key(reach, "main")
    case BIR.Library{exports}: s_reach_roots_exports_go(exports, reach)

def s_reachable_body_on(on: Bool, row: BodyRow, +acc: List<&2, BodyRow>) -> List<&2, BodyRow>:
  match on:
    case True{}: row <> acc
    case False{}: acc

def s_reachable_body_lazy(lazy: Maybe<&2, String>, owner: U32, row: BodyRow, +reach: Reach, +acc: List<&2, BodyRow>) -> List<&2, BodyRow>:
  match lazy:
    case Some{key}: s_reachable_body_on(s_flag_has(s_reach_keys(reach), key), row, acc)
    case None{}: s_reachable_body_on(s_flag_has(s_reach_codes(reach), U32.show(owner)), row, acc)

def s_reachable_body_add(row: BodyRow, +reach: Reach, +acc: List<&2, BodyRow>) -> List<&2, BodyRow>:
  match row:
    case BodyRow{+owner, +bkey, +lazy, +body, +params, +capture_count}:
      s_reachable_body_lazy(lazy, owner, BodyRow{owner, bkey, lazy, body, params, capture_count}, reach, acc)

def s_reachable_bodies_go(+rows: List<&2, BodyRow>, +reach: Reach, +acc: List<&2, BodyRow>) -> List<&2, BodyRow>:
  match rows:
    case Nil{}: List.reverse(&2, BodyRow, acc)
    case +row <> rest: s_reachable_bodies_go(rest, reach, s_reachable_body_add(row, reach, acc))

def s_reachable_bodies(rows: List<&2, BodyRow>, +reach: Reach) -> List<&2, BodyRow>:
  s_reachable_bodies_go(rows, reach, Nil{})

# ---------------------------------------------------------------------------
# Fact extraction passes over reachable bodies
# ---------------------------------------------------------------------------

def s_arg_values_go(+args: List<&2, BIR.Arg>, +acc: List<&2, BIR.Atom>) -> List<&2, BIR.Atom>:
  match args:
    case Nil{}: List.reverse(&2, BIR.Atom, acc)
    case +arg <> rest:
      match arg:
        case BIR.Arg{_, value}: s_arg_values_go(rest, value <> acc)

def s_arg_value(arg: BIR.Arg) -> BIR.Atom:
  match arg:
    case BIR.Arg{_, value}: value

def s_arg_values(args: List<&2, BIR.Arg>) -> List<&2, BIR.Atom>:
  s_arg_values_go(args, Nil{})

def s_atom_at(items: List<&2, BIR.Atom>, index: Nat) -> Maybe<&2, BIR.Atom>:
  match items index:
    case Nil{} _: None{}
    case +item <> _ 0n: Some{item}
    case _ <> rest 1n+rest_index: s_atom_at(rest, rest_index)

def s_op_def(+bkey: String, op: BIR.Op) -> DefRow:
  match op:
    case BIR.Copy{value}: DefCopy{value}
    case BIR.PrimitiveCall{primitive, args, types}: DefPrim{primitive, types}
    case BIR.Closure{code, captures, parameters}: DefClosure{code}
    case BIR.Direct{code, args}: DefDirect{bkey, code, args}
    case BIR.Apply{fn, arg}: DefApply{bkey, fn}
    case BIR.LoadSymbol{_, key}: DefSymbol{key}
    case BIR.Construct{constructor, tag, fields}: DefConstruct{constructor}
    case BIR.Project{value, constructor, field, key}: DefProject{constructor, field}
    case _: DefOther{}

def s_defs_put(+out: DefsOut, +key: String, entry: DefEntry) -> DefsOut:
  match out:
    case DefsOut{defs, def_keys}: DefsOut{Map.set(&2, DefEntry, defs, key, entry), key <> def_keys}

def s_defs_block(block: BIR.Block, +bkey: String, +out: DefsOut) -> DefsOut:
  match block:
    case BIR.Let{id, op, next}: s_defs_block(next, bkey, s_defs_put(out, s_body_local(bkey, id), DefEntry{bkey, s_op_def(bkey, op)}))
    case BIR.Branch{condition, yes, no}: s_defs_block(no, bkey, s_defs_block(yes, bkey, out))
    case BIR.Region{label, body, next}: s_defs_block(next, bkey, s_defs_block(body, bkey, out))
    case _: out

def s_defs_bodies_go(+rows: List<&2, BodyRow>, +out: DefsOut) -> DefsOut:
  match rows:
    case Nil{}: out
    case +row <> rest:
      match row:
        case BodyRow{owner, bkey, lazy, body, params, capture_count}: s_defs_bodies_go(rest, s_defs_block(body, bkey, out))

def s_occ_put_at(found: Maybe<&2, Nat>, +out: OccOut, +key: String) -> OccOut:
  match found:
    case Some{value}:
      match out:
        case OccOut{occ, count_keys}: OccOut{Map.set(&2, Nat, occ, key, Nat.add(value, 1n)), count_keys}
    case None{}:
      match out:
        case OccOut{occ, count_keys}: OccOut{Map.set(&2, Nat, occ, key, 1n), key <> count_keys}

def s_occ_put(+out: OccOut, +key: String) -> OccOut:
  match out:
    case OccOut{occ, count_keys}: s_occ_put_at(IndexLookup.find(Nat, occ, key), out, key)

def s_occ_atom(atom: BIR.Atom, +bkey: String, +out: OccOut) -> OccOut:
  match atom:
    case BIR.Local{id}: s_occ_put(out, s_body_local(bkey, id))
    case BIR.Capture{slot}: s_occ_put(out, s_body_capture(bkey, U32.to_nat(slot)))
    case _: out

def s_occ_arg(arg: BIR.Arg, +bkey: String, +out: OccOut) -> OccOut:
  match arg:
    case BIR.Arg{_, value}: s_occ_atom(value, bkey, out)

def s_occ_args_go(+args: List<&2, BIR.Arg>, +bkey: String, +out: OccOut) -> OccOut:
  match args:
    case Nil{}: out
    case +arg <> rest: s_occ_args_go(rest, bkey, s_occ_arg(arg, bkey, out))

def s_occ_fields_go(+fields: List<&2, BIR.Field>, +bkey: String, +out: OccOut) -> OccOut:
  match fields:
    case Nil{}: out
    case +field <> rest:
      match field:
        case BIR.Field{_, _, _, value}: s_occ_fields_go(rest, bkey, s_occ_atom(value, bkey, out))

def s_occ_op(op: BIR.Op, +bkey: String, +out: OccOut) -> OccOut:
  match op:
    case BIR.Copy{value}: s_occ_atom(value, bkey, out)
    case BIR.PrimitiveCall{primitive, args, types}: s_occ_args_go(args, bkey, out)
    case BIR.Closure{code, captures, parameters}: s_occ_args_go(captures, bkey, out)
    case BIR.Direct{code, args}: s_occ_args_go(args, bkey, out)
    case BIR.Apply{fn, arg}: s_occ_arg(arg, bkey, s_occ_atom(fn, bkey, out))
    case BIR.LoadSymbol{_, key}: out
    case BIR.Construct{constructor, tag, fields}: s_occ_fields_go(fields, bkey, out)
    case BIR.Project{value, constructor, field, key}: s_occ_atom(value, bkey, out)
    case BIR.HasTag{value, constructor, tag}: s_occ_atom(value, bkey, out)
    case _: out

def s_occ_block(block: BIR.Block, +bkey: String, +out: OccOut) -> OccOut:
  match block:
    case BIR.Return{value}: s_occ_atom(value, bkey, out)
    case BIR.Let{id, op, next}: s_occ_block(next, bkey, s_occ_op(op, bkey, out))
    case BIR.Branch{condition, yes, no}: s_occ_block(no, bkey, s_occ_block(yes, bkey, s_occ_atom(condition, bkey, out)))
    case BIR.Region{label, body, next}: s_occ_block(next, bkey, s_occ_block(body, bkey, out))
    case BIR.LeaveRegion{label}: out
    case BIR.TailDirect{code, args}: s_occ_args_go(args, bkey, out)
    case BIR.TailApply{fn, arg}: s_occ_arg(arg, bkey, s_occ_atom(fn, bkey, out))
    case BIR.Failure{message}: out

def s_occ_bodies_go(+rows: List<&2, BodyRow>, +out: OccOut) -> OccOut:
  match rows:
    case Nil{}: out
    case +row <> rest:
      match row:
        case BodyRow{owner, bkey, lazy, body, params, capture_count}: s_occ_bodies_go(rest, s_occ_block(body, bkey, out))

def s_sites_new() -> SitesOut:
  SitesOut{Nil{}, Nil{}, Nil{}, Nil{}, Nil{}, Nil{}, Nil{}, False{}}

def s_sites_symbol(+key: String, +out: SitesOut) -> SitesOut:
  match out:
    case SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
      SitesOut{closures, calls, applies, binds, demands, s_foreign_add(symbols, key), element_heads, element_unknown}

def s_sites_closure(+out: SitesOut, site: ClosureSite) -> SitesOut:
  match out:
    case SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
      SitesOut{site <> closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}

def s_sites_call(+out: SitesOut, site: CallSite) -> SitesOut:
  match out:
    case SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
      SitesOut{closures, site <> calls, applies, binds, demands, symbols, element_heads, element_unknown}

def s_sites_apply(+out: SitesOut, site: ApplySite) -> SitesOut:
  match out:
    case SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
      SitesOut{closures, calls, site <> applies, binds, demands, symbols, element_heads, element_unknown}

def s_sites_bind(+out: SitesOut, site: BindSite) -> SitesOut:
  match out:
    case SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
      SitesOut{closures, calls, applies, site <> binds, demands, symbols, element_heads, element_unknown}

def s_sites_demand(+out: SitesOut, site: DemandSite) -> SitesOut:
  match out:
    case SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
      SitesOut{closures, calls, applies, binds, site <> demands, symbols, element_heads, element_unknown}

def s_use_many(use: BIR.Use) -> Bool:
  match use:
    case BIR.Many{}: True{}
    case _: False{}

def s_sites_bind_cont(action: BIR.Atom, cont: Maybe<&2, BIR.Atom>, +out: SitesOut, +bkey: String) -> SitesOut:
  match cont:
    case None{}: out
    case Some{c}: s_sites_bind(out, BindSite{bkey, action, c})

def s_sites_bind_values(action: Maybe<&2, BIR.Atom>, cont: Maybe<&2, BIR.Atom>, +out: SitesOut, +bkey: String) -> SitesOut:
  match action:
    case None{}: out
    case Some{a}: s_sites_bind_cont(a, cont, out, bkey)

def s_args_head(args: List<&2, BIR.Arg>) -> Maybe<&2, BIR.Atom>:
  s_atom_at(s_arg_values(args), 0n)

def s_args_second(args: List<&2, BIR.Arg>) -> Maybe<&2, BIR.Atom>:
  s_atom_at(s_arg_values(args), 1n)

def s_sites_bind_at(is_bind: Bool, +out: SitesOut, +bkey: String, +args: List<&2, BIR.Arg>) -> SitesOut:
  match is_bind:
    case False{}: out
    case True{}: s_sites_bind_values(s_args_head(args), s_args_second(args), out, bkey)

def s_sites_many(many: Bool, +bkey: String, value: BIR.Atom, +out: SitesOut) -> SitesOut:
  match many:
    case True{}: s_sites_demand(out, DemandSite{bkey, value})
    case False{}: out

def s_sites_args_go(+args: List<&2, BIR.Arg>, +bkey: String, +out: SitesOut) -> SitesOut:
  match args:
    case Nil{}: out
    case +arg <> rest:
      match arg:
        case BIR.Arg{use, value}:
          next = s_sites_many(s_use_many(use), bkey, value, out)
          s_sites_args_go(rest, bkey, next)

def s_sites_fields_go(+fields: List<&2, BIR.Field>, +bkey: String, +out: SitesOut) -> SitesOut:
  match fields:
    case Nil{}: out
    case +field <> rest:
      match field:
        case BIR.Field{identity, key, use, value}:
          next = s_sites_many(s_use_many(use), bkey, value, out)
          s_sites_fields_go(rest, bkey, next)

def s_is_bind(+by_code: Map<&2, String>, +code: U32) -> Bool:
  String.eq(s_map_string(by_code, U32.show(code), ""), "IO.bind")

def s_sites_direct(+out: SitesOut, +bkey: String, +code: U32, +args: List<&2, BIR.Arg>, +by_code: Map<&2, String>) -> SitesOut:
  with_call = s_sites_call(out, CallSite{bkey, code, args})
  s_sites_bind_at(s_is_bind(by_code, code), with_call, bkey, args)

def s_sites_apply_at(+out: SitesOut, +bkey: String, fn: BIR.Atom, arg: BIR.Arg) -> SitesOut:
  match arg:
    case BIR.Arg{use, value}: s_sites_apply(out, ApplySite{bkey, fn, value, s_use_many(use)})

def s_sites_symbols_atom(atom: BIR.Atom, +out: SitesOut) -> SitesOut:
  match atom:
    case BIR.Symbol{_, key}: s_sites_symbol(key, out)
    case _: out

def s_sites_symbols_arg(arg: BIR.Arg, +out: SitesOut) -> SitesOut:
  match arg:
    case BIR.Arg{_, value}: s_sites_symbols_atom(value, out)

def s_sites_symbols_args_go(+args: List<&2, BIR.Arg>, +out: SitesOut) -> SitesOut:
  match args:
    case Nil{}: out
    case +arg <> rest: s_sites_symbols_args_go(rest, s_sites_symbols_arg(arg, out))

def s_heads_unknown_at(types: List<&2, BIR.Descriptor>) -> Heads:
  match types:
    case Nil{}: s_heads_ok(Nil{})
    case +_ <> _: s_heads_unknown()

def s_sites_element(heads: Heads, +out: SitesOut) -> SitesOut:
  match heads:
    case Heads{list, unknown, fail}:
      match out:
        case SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
          SitesOut{closures, calls, applies, binds, demands, symbols, s_union(element_heads, list), Bool.or(element_unknown, unknown)}

def s_sites_primitive_at(is_array: Bool, primitive: BIR.Primitive, types: List<&2, BIR.Descriptor>, +out: SitesOut) -> SitesOut:
  match is_array:
    case False{}: out
    case True{}: s_sites_element(s_heads_unknown_at(types), out)

def s_sites_primitive(+primitive: BIR.Primitive, types: List<&2, BIR.Descriptor>, +out: SitesOut) -> SitesOut:
  s_sites_primitive_at(s_is_array_prim(primitive), primitive, types, out)

def s_sites_op(op: BIR.Op, +bkey: String, +by_code: Map<&2, String>, +out: SitesOut) -> SitesOut:
  match op:
    case BIR.Closure{code, +captures, parameters}:
      s_sites_symbols_args_go(captures, s_sites_closure(out, ClosureSite{bkey, code, captures}))
    case BIR.Direct{code, +args}:
      s_sites_symbols_args_go(args, s_sites_direct(out, bkey, code, args, by_code))
    case BIR.Apply{+fn, +arg}:
      next = s_sites_apply_at(s_sites_symbols_atom(fn, out), bkey, fn, arg)
      s_sites_symbols_arg(arg, next)
    case BIR.PrimitiveCall{primitive, +args, types}:
      next = s_sites_args_go(args, bkey, s_sites_symbols_args_go(args, out))
      s_sites_primitive(primitive, types, next)
    case BIR.LoadSymbol{_, key}: s_sites_symbol(key, out)
    case BIR.Construct{constructor, tag, fields}:
      s_sites_fields_go(fields, bkey, out)
    case BIR.Project{value, constructor, field, key}: s_sites_symbols_atom(value, out)
    case BIR.Copy{value}: s_sites_symbols_atom(value, out)
    case _: out

def s_sites_block(block: BIR.Block, +bkey: String, +by_code: Map<&2, String>, +out: SitesOut) -> SitesOut:
  match block:
    case BIR.Let{id, op, next}: s_sites_block(next, bkey, by_code, s_sites_op(op, bkey, by_code, out))
    case BIR.Branch{condition, yes, no}: s_sites_block(no, bkey, by_code, s_sites_block(yes, bkey, by_code, s_sites_symbols_atom(condition, out)))
    case BIR.Region{label, body, next}: s_sites_block(next, bkey, by_code, s_sites_block(body, bkey, by_code, out))
    case BIR.TailDirect{code, args}: s_sites_direct(out, bkey, code, args, by_code)
    case BIR.TailApply{+fn, +arg}: s_sites_apply_at(s_sites_symbols_atom(fn, out), bkey, fn, arg)
    case _: out

def s_sites_bodies_go(+rows: List<&2, BodyRow>, +by_code: Map<&2, String>, +out: SitesOut) -> SitesOut:
  match rows:
    case Nil{}: out
    case +row <> rest:
      match row:
        case BodyRow{owner, bkey, lazy, body, params, capture_count}: s_sites_bodies_go(rest, by_code, s_sites_block(body, bkey, by_code, out))

def s_capture_slots(+owner: U32, remaining: Nat, +index: Nat, +acc: List<&2, String>) -> List<&2, String>:
  match remaining:
    case 0n: acc
    case 1n+pred: s_capture_slots(owner, pred, Nat.add(index, 1n), s_body_capture(s_code_body(owner), index) <> acc)

def s_capture_keys_go(+rows: List<&2, BodyRow>, +acc: List<&2, String>) -> List<&2, String>:
  match rows:
    case Nil{}: acc
    case +row <> rest:
      match row:
        case BodyRow{owner, bkey, lazy, body, params, capture_count}:
          next = s_capture_slots(owner, capture_count, 0n, acc)
          s_capture_keys_go(rest, next)

def s_capture_keys(rows: List<&2, BodyRow>) -> List<&2, String>:
  s_capture_keys_go(rows, Nil{})

def s_built_occurrence(rows: List<&2, BodyRow>) -> OccOut:
  s_occ_bodies_go(rows, OccOut{Map.new(&2, Nat), Nil{}})

def s_built_defs(rows: List<&2, BodyRow>) -> DefsOut:
  s_defs_bodies_go(rows, DefsOut{Map.new(&2, DefEntry), Nil{}})

def s_built_sites(+rows: List<&2, BodyRow>, +decls: DeclFacts) -> SitesOut:
  s_sites_bodies_go(rows, s_decls_by_code(decls), s_sites_new())


# ---------------------------------------------------------------------------
# Facts assembly
# ---------------------------------------------------------------------------

def s_facts_catalog(facts: Facts) -> Catalog:
  match facts:
    case Facts{catalog, _, _}: catalog

def s_facts_decls(facts: Facts) -> DeclFacts:
  match facts:
    case Facts{_, decls, _}: decls

def s_facts_built(facts: Facts) -> BuiltFacts:
  match facts:
    case Facts{_, _, built}: built

def s_built_bodies(built: BuiltFacts) -> List<&2, BodyRow>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: bodies

def s_built_defs_of(built: BuiltFacts) -> Map<&2, DefEntry>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: defs

def s_built_def_keys(built: BuiltFacts) -> List<&2, String>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: def_keys

def s_built_occ(built: BuiltFacts) -> Map<&2, Nat>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: occ

def s_built_count_keys(built: BuiltFacts) -> List<&2, String>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: count_keys

def s_built_closures(built: BuiltFacts) -> List<&2, ClosureSite>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: closures

def s_built_calls(built: BuiltFacts) -> List<&2, CallSite>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: calls

def s_built_applies(built: BuiltFacts) -> List<&2, ApplySite>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: applies

def s_built_binds(built: BuiltFacts) -> List<&2, BindSite>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: binds

def s_built_demands(built: BuiltFacts) -> List<&2, DemandSite>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: demands

def s_built_symbol_keys(built: BuiltFacts) -> List<&2, String>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: symbol_keys

def s_built_element_heads(built: BuiltFacts) -> List<&2, String>:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: element_heads

def s_built_element_unknown(built: BuiltFacts) -> Bool:
  match built:
    case BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, capture_keys, symbol_keys, element_heads, element_unknown}: element_unknown

def s_make_built(bodies: List<&2, BodyRow>, defs_out: DefsOut, occ_out: OccOut, sites: SitesOut, captures: List<&2, String>) -> BuiltFacts:
  match defs_out occ_out sites:
    case DefsOut{defs, def_keys} OccOut{occ, count_keys} SitesOut{closures, calls, applies, binds, demands, symbols, element_heads, element_unknown}:
      BuiltFacts{bodies, defs, def_keys, occ, count_keys, closures, calls, applies, binds, demands, captures, symbols, element_heads, element_unknown}

def s_facts_reachable(catalog: Catalog, +decls: DeclFacts, +reachable: List<&2, BodyRow>) -> Facts:
  defs_out = s_built_defs(reachable)
  occ_out = s_built_occurrence(reachable)
  sites = s_built_sites(reachable, decls)
  captures = s_capture_keys(reachable)
  Facts{catalog, decls, s_make_built(reachable, defs_out, occ_out, sites, captures)}

def s_facts_bodies(catalog: Catalog, +decls: DeclFacts, +bodies: List<&2, BodyRow>, +declarations: List<&2, BIR.Declaration>, ending: BIR.Ending) -> Facts:
  roots = s_reach_roots(ending, s_reach_new())
  fuel = Nat.add(Nat.add(List.length(&2, BodyRow, bodies), List.length(&2, BIR.Declaration, declarations)), 1n)
  reach = s_reach_fix(fuel, ReachOut{roots, True{}}, bodies, declarations)
  reachable = s_reachable_bodies(bodies, reach)
  s_facts_reachable(catalog, decls, reachable)

def s_facts_from_build(+build: CatBuild, codes: List<&2, BIR.Code>, +declarations: List<&2, BIR.Declaration>, ending: BIR.Ending) -> Facts:
  catalog = s_catalog_of(build)
  decls = s_decls_of(build)
  bodies = s_all_bodies(codes, declarations)
  s_facts_bodies(catalog, decls, bodies, declarations, ending)

def s_facts_build_parts(+codes: List<&2, BIR.Code>, +declarations: List<&2, BIR.Declaration>, +constructors: List<&2, BIR.ConstructorLayout>, +families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, ending: BIR.Ending) -> Facts:
  s_facts_from_build(s_catalog_build_all(codes, declarations, constructors, families, type_functions), codes, declarations, ending)

def s_facts_build(program: BIR.Program) -> Facts:
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, ending}:
      s_facts_build_parts(codes, declarations, constructors, families, type_functions, ending)

# ---------------------------------------------------------------------------
# Callee sets
# ---------------------------------------------------------------------------

def s_callee_eq(a: Resolved, b: Resolved) -> Bool:
  match a b:
    case ResolvedCode{code} ResolvedCode{other}: U32.is_eq(code, other)
    case ResolvedDecl{key} ResolvedDecl{other}: String.eq(key, other)
    case ResolvedNone{} ResolvedNone{}: True{}
    case _ _: False{}

def s_callee_member_go(+items: List<&2, Resolved>, +value: Resolved, found: Bool) -> Bool:
  match items:
    case Nil{}: found
    case +item <> rest: s_callee_member_go(rest, value, Bool.or(found, s_callee_eq(item, value)))

def s_callee_member(+items: List<&2, Resolved>, +value: Resolved) -> Bool:
  s_callee_member_go(items, value, False{})

def s_callee_add_item(member: Bool, +callees: Map<&2, List<&2, Resolved>>, +key: String, +items: List<&2, Resolved>, +value: Resolved) -> CalleeOut:
  match member:
    case True{}: CalleeOut{callees, False{}}
    case False{}: CalleeOut{Map.set(&2, List<&2, Resolved>, callees, key, value <> items), True{}}

def s_callee_add_at(found: Maybe<&2, List<&2, Resolved>>, +callees: Map<&2, List<&2, Resolved>>, +key: String, +value: Resolved) -> CalleeOut:
  match found:
    case Some{+items}: s_callee_add_item(s_callee_member(items, value), callees, key, items, value)
    case None{}: CalleeOut{Map.set(&2, List<&2, Resolved>, callees, key, value <> Nil{}), True{}}

def s_callee_add_real(+callees: Map<&2, List<&2, Resolved>>, +key: String, +value: Resolved) -> CalleeOut:
  s_callee_add_at(IndexLookup.find(List<&2, Resolved>, callees, key), callees, key, value)

def s_callee_add(+callees: Map<&2, List<&2, Resolved>>, +key: String, value: Resolved) -> CalleeOut:
  match value:
    case ResolvedNone{}: CalleeOut{callees, False{}}
    case _: s_callee_add_real(callees, key, value)

def s_callee_list_at(found: Maybe<&2, List<&2, Resolved>>) -> List<&2, Resolved>:
  match found:
    case Some{value}: value
    case None{}: Nil{}

def s_callee_list(+callees: Map<&2, List<&2, Resolved>>, +key: String) -> List<&2, Resolved>:
  s_callee_list_at(IndexLookup.find(List<&2, Resolved>, callees, key))

# ---------------------------------------------------------------------------
# Analysis state
# ---------------------------------------------------------------------------

def s_st_new(element_unknown: Bool) -> AState:
  AState{
    Map.new(&2, Flow),
    Map.new(&2, Flow),
    Map.new(&2, List<&2, Resolved>),
    Map.new(&2, Bool),
    Map.new(&2, Bool),
    False{},
    element_unknown,
    False{},
    Nil{},
    True{},
    None{}
  }

def s_st_flows(st: AState) -> Map<&2, Flow>:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: flow

def s_st_pays(st: AState) -> Map<&2, Flow>:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: pay

def s_st_calls(st: AState) -> Map<&2, List<&2, Resolved>>:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: call

def s_st_hot_map(st: AState) -> Map<&2, Bool>:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: hot

def s_st_ctr_map(st: AState) -> Map<&2, Bool>:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: ctr

def s_st_forced_val(st: AState) -> Bool:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: forced

def s_st_array_val(st: AState) -> Bool:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: array_hot

def s_st_note(st: AState) -> List<&2, String>:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: note

def s_st_failure(st: AState) -> Maybe<&2, String>:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}: failure

def s_st_flow_out(out: FlowOut, +pay: Map<&2, Flow>, +call: Map<&2, List<&2, Resolved>>, +hot: Map<&2, Bool>, +ctr: Map<&2, Bool>, array_hot: Bool, elem_unknown: Bool, forced: Bool, +note: List<&2, String>, +changed: Bool, failure: Maybe<&2, String>) -> AState:
  match out:
    case FlowOut{flows, grew}:
      AState{flows, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, Bool.or(changed, grew), failure}

def s_st_flow_add(st: AState, +key: String, value: Flow) -> AState:
  match st:
    case AState{+flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      s_st_flow_out(s_flow_merge_map(flow, key, value), pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure)

def s_st_pay_out(out: FlowOut, +flow: Map<&2, Flow>, +call: Map<&2, List<&2, Resolved>>, +hot: Map<&2, Bool>, +ctr: Map<&2, Bool>, array_hot: Bool, elem_unknown: Bool, forced: Bool, +note: List<&2, String>, +changed: Bool, failure: Maybe<&2, String>) -> AState:
  match out:
    case FlowOut{pays, grew}:
      AState{flow, pays, call, hot, ctr, array_hot, elem_unknown, forced, note, Bool.or(changed, grew), failure}

def s_st_pay_add(st: AState, +key: String, value: Flow) -> AState:
  match st:
    case AState{flow, +pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      s_st_pay_out(s_flow_merge_map(pay, key, value), flow, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure)

def s_st_call_out(out: CalleeOut, +flow: Map<&2, Flow>, +pay: Map<&2, Flow>, +hot: Map<&2, Bool>, +ctr: Map<&2, Bool>, array_hot: Bool, elem_unknown: Bool, forced: Bool, +note: List<&2, String>, +changed: Bool, failure: Maybe<&2, String>) -> AState:
  match out:
    case CalleeOut{callees, grew}:
      AState{flow, pay, callees, hot, ctr, array_hot, elem_unknown, forced, note, Bool.or(changed, grew), failure}

def s_st_call_add(st: AState, +key: String, value: Resolved) -> AState:
  match st:
    case AState{flow, pay, +call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      s_st_call_out(s_callee_add(call, key, value), flow, pay, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure)

def s_st_hot_out(out: FlagOut, +flow: Map<&2, Flow>, +pay: Map<&2, Flow>, +call: Map<&2, List<&2, Resolved>>, +ctr: Map<&2, Bool>, array_hot: Bool, elem_unknown: Bool, forced: Bool, +note: List<&2, String>, +changed: Bool, failure: Maybe<&2, String>) -> AState:
  match out:
    case FlagOut{flags, grew}:
      AState{flow, pay, call, flags, ctr, array_hot, elem_unknown, forced, note, Bool.or(changed, grew), failure}

def s_st_hot_add(st: AState, +key: String) -> AState:
  match st:
    case AState{flow, pay, call, +hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      s_st_hot_out(s_flag_set(hot, key), flow, pay, call, ctr, array_hot, elem_unknown, forced, note, changed, failure)

def s_st_ctr_out(out: FlagOut, +flow: Map<&2, Flow>, +pay: Map<&2, Flow>, +call: Map<&2, List<&2, Resolved>>, +hot: Map<&2, Bool>, array_hot: Bool, elem_unknown: Bool, forced: Bool, +note: List<&2, String>, +changed: Bool, failure: Maybe<&2, String>) -> AState:
  match out:
    case FlagOut{flags, grew}:
      AState{flow, pay, call, hot, flags, array_hot, elem_unknown, forced, note, Bool.or(changed, grew), failure}

def s_st_ctr_add(st: AState, +key: String) -> AState:
  match st:
    case AState{flow, pay, call, hot, +ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      s_st_ctr_out(s_flag_set(ctr, key), flow, pay, call, hot, array_hot, elem_unknown, forced, note, changed, failure)

def s_st_array(st: AState) -> AState:
  match st:
    case AState{flow, pay, call, hot, ctr, False{}, elem_unknown, forced, note, changed, failure}:
      AState{flow, pay, call, hot, ctr, True{}, elem_unknown, forced, note, changed, failure}
    case AState{flow, pay, call, hot, ctr, True{}, elem_unknown, forced, note, changed, failure}:
      AState{flow, pay, call, hot, ctr, True{}, elem_unknown, forced, note, changed, failure}

def s_st_forced_note(st: AState, +message: String) -> AState:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, True{}, s_foreign_add(note, message), changed, failure}

def s_st_fail(st: AState, +message: String) -> AState:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      match failure:
        case Some{_}: AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}
        case None{}: AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, Some{message}}

# ---------------------------------------------------------------------------
# Atom access
# ---------------------------------------------------------------------------

def s_atom_key(bkey: String, atom: BIR.Atom) -> Maybe<&2, String>:
  match atom:
    case BIR.Local{id}: Some{s_body_local(bkey, id)}
    case BIR.Capture{slot}: Some{s_body_capture(bkey, U32.to_nat(slot))}
    case BIR.Symbol{_, key}: Some{s_symbol_value(key)}
    case _: None{}

def s_atom_word_flow(atom: BIR.Atom) -> Flow:
  match atom:
    case BIR.Word{value}: s_flow_empty()
    case BIR.Natural{value}: s_flow_empty()
    case BIR.FloatBits{bits}: s_flow_empty()
    case BIR.TextValue{value}: s_flow_empty()
    case BIR.Boolean{value}: s_flow_empty()
    case BIR.Null{}: s_flow_empty()
    case BIR.Undefined{}: s_flow_empty()
    case _: s_flow_unknown()

def s_atom_flow_at(key: Maybe<&2, String>, atom: BIR.Atom, +flows: Map<&2, Flow>) -> Flow:
  match key:
    case Some{k}: s_flow(flows, k)
    case None{}: s_atom_word_flow(atom)

def s_atom_flow(bkey: String, +atom: BIR.Atom, +flows: Map<&2, Flow>) -> Flow:
  s_atom_flow_at(s_atom_key(bkey, atom), atom, flows)

def s_atom_pay(bkey: String, +atom: BIR.Atom, +pays: Map<&2, Flow>) -> Flow:
  s_atom_flow_at(s_atom_key(bkey, atom), atom, pays)

def s_atom_word_call(atom: BIR.Atom) -> List<&2, Resolved>:
  match atom:
    case BIR.Word{value}: Nil{}
    case BIR.Natural{value}: Nil{}
    case BIR.FloatBits{bits}: Nil{}
    case BIR.TextValue{value}: Nil{}
    case BIR.Boolean{value}: Nil{}
    case BIR.Null{}: Nil{}
    case BIR.Undefined{}: Nil{}
    case _: Nil{}

def s_atom_call_at(key: Maybe<&2, String>, +calls: Map<&2, List<&2, Resolved>>) -> List<&2, Resolved>:
  match key:
    case Some{k}: s_callee_list(calls, k)
    case None{}: Nil{}

def s_atom_call(bkey: String, atom: BIR.Atom, +calls: Map<&2, List<&2, Resolved>>) -> List<&2, Resolved>:
  s_atom_call_at(s_atom_key(bkey, atom), calls)

# ---------------------------------------------------------------------------
# Declarations
# ---------------------------------------------------------------------------

def s_decl_row(decls: DeclFacts, +key: String) -> Maybe<&2, DeclRow>:
  IndexLookup.find(DeclRow, s_decls_decl(decls), key)

def s_row_code(row: DeclRow) -> U32:
  match row:
    case DeclRow{key, kind, code, arity, result, primitive, has_primitive}: code

def s_row_kind(row: DeclRow) -> String:
  match row:
    case DeclRow{key, kind, code, arity, result, primitive, has_primitive}: kind

def s_row_result(row: DeclRow) -> BIR.Descriptor:
  match row:
    case DeclRow{key, kind, code, arity, result, primitive, has_primitive}: result

def s_code_result(code: U32) -> String:
  s_body_result(s_code_body(code))

def s_lazy_result(key: String) -> String:
  s_body_result(s_lazy_body(key))

def s_decl_value_flow(row: DeclRow, st: AState, +catalog: Catalog, +key: String) -> Flow:
  match row:
    case DeclRow{dkey, kind, code, arity, result, primitive, has_primitive}:
      match kind:
        case "fn": s_flow_ok([s_function_head()])
        case "lazy": s_flow(s_st_flows(st), s_lazy_result(key))
        case "foreign": s_result_flow(s_catalog_families(catalog), s_catalog_labels(catalog), result)
        case "native": s_flow_ok([s_function_head()])
        case _: s_flow_unknown()

def s_decl_pay_flow(row: DeclRow, st: AState, +catalog: Catalog, +key: String) -> Flow:
  match row:
    case DeclRow{dkey, kind, code, arity, result, primitive, has_primitive}:
      match kind:
        case "fn": s_flow(s_st_pays(st), s_code_result(code))
        case "lazy": s_flow(s_st_pays(st), s_lazy_result(key))
        case "foreign": s_result_payload(s_catalog_families(catalog), s_catalog_labels(catalog), result)
        case _: s_flow_empty()

def s_resolved_decl_flow(found: Maybe<&2, DeclRow>, +key: String, st: AState, +catalog: Catalog) -> Flow:
  match found:
    case Some{+row}: s_decl_value_flow(row, st, catalog, key)
    case None{}: s_flow_unknown()

def s_resolved_decl_pay(found: Maybe<&2, DeclRow>, +key: String, st: AState, +catalog: Catalog) -> Flow:
  match found:
    case Some{+row}: s_decl_pay_flow(row, st, catalog, key)
    case None{}: s_flow_unknown()

def s_resolved_flow(res: Resolved, st: AState, +catalog: Catalog, +decls: DeclFacts) -> Flow:
  match res:
    case ResolvedCode{code}: s_flow(s_st_flows(st), s_code_result(code))
    case ResolvedDecl{+key}: s_resolved_decl_flow(s_decl_row(decls, key), key, st, catalog)
    case ResolvedNone{}: s_flow_unknown()

def s_resolved_pay(res: Resolved, st: AState, +catalog: Catalog, +decls: DeclFacts) -> Flow:
  match res:
    case ResolvedCode{code}: s_flow(s_st_pays(st), s_code_result(code))
    case ResolvedDecl{+key}: s_resolved_decl_pay(s_decl_row(decls, key), key, st, catalog)
    case ResolvedNone{}: s_flow_unknown()

def s_resolved_flows_go(+items: List<&2, Resolved>, +st: AState, +catalog: Catalog, +decls: DeclFacts, +acc: Flow) -> Flow:
  match items:
    case Nil{}: acc
    case +item <> rest:
      next = s_flow_merge(acc, s_resolved_flow(item, st, catalog, decls))
      s_resolved_flows_go(rest, st, catalog, decls, next)

def s_resolved_flow_union(items: List<&2, Resolved>, st: AState, +catalog: Catalog, +decls: DeclFacts) -> Flow:
  match items:
    case Nil{}: s_flow_unknown()
    case _: s_resolved_flows_go(items, st, catalog, decls, s_flow_empty())

def s_resolved_pays_go(+items: List<&2, Resolved>, +st: AState, +catalog: Catalog, +decls: DeclFacts, +acc: Flow) -> Flow:
  match items:
    case Nil{}: acc
    case +item <> rest:
      next = s_flow_merge(acc, s_resolved_pay(item, st, catalog, decls))
      s_resolved_pays_go(rest, st, catalog, decls, next)

def s_resolved_pay_union(items: List<&2, Resolved>, st: AState, +catalog: Catalog, +decls: DeclFacts) -> Flow:
  match items:
    case Nil{}: s_flow_unknown()
    case _: s_resolved_pays_go(items, st, catalog, decls, s_flow_empty())

def s_code_decl_row(found: Maybe<&2, DeclRow>, +key: String, +st: AState, +catalog: Catalog) -> DefFlow:
  match found:
    case None{}: DefFlow{s_flow_unknown(), s_flow_unknown(), Nil{}}
    case Some{+row}: DefFlow{s_decl_value_flow(row, st, catalog, key), s_decl_pay_flow(row, st, catalog, key), Nil{}}

def s_code_decl_flow_at(found: Maybe<&2, String>, st: AState, +decls: DeclFacts, +catalog: Catalog) -> DefFlow:
  match found:
    case None{}: DefFlow{s_flow_unknown(), s_flow_unknown(), Nil{}}
    case Some{+key}: s_code_decl_row(s_decl_row(decls, key), key, st, catalog)

def s_code_decl_flow(code: U32, st: AState, +decls: DeclFacts, +catalog: Catalog) -> DefFlow:
  s_code_decl_flow_at(IndexLookup.find(String, s_decls_by_code(decls), U32.show(code)), st, decls, catalog)

def s_symbol_call_kind(kind: String, +key: String) -> Resolved:
  match kind:
    case "fn": ResolvedDecl{key}
    case "foreign": ResolvedDecl{key}
    case _: ResolvedNone{}

def s_symbol_call(row: DeclRow, +key: String) -> Resolved:
  s_symbol_call_kind(s_row_kind(row), key)

def s_construct_flow_at(found: Maybe<&2, CtorRow>, +catalog: Catalog) -> DefFlow:
  match found:
    case None{}: DefFlow{s_flow_unknown(), s_flow_empty(), Nil{}}
    case Some{CtorRow{id, key, family}}: DefFlow{s_flow_ok([s_family(family)]), s_flow_empty(), Nil{}}

def s_construct_flow(constructor: U32, +catalog: Catalog) -> DefFlow:
  s_construct_flow_at(IndexLookup.find(CtorRow, s_catalog_ctors_by_id(catalog), U32.show(constructor)), catalog)

def s_project_field_at(found: Maybe<&2, BIR.Descriptor>, +catalog: Catalog) -> DefFlow:
  match found:
    case None{}: DefFlow{s_flow_unknown(), s_flow_empty(), Nil{}}
    case Some{descriptor}:
      DefFlow{s_heads_to_flow(s_descriptor_heads(s_catalog_families(catalog), s_catalog_labels(catalog), descriptor)), s_flow_empty(), Nil{}}

# ---------------------------------------------------------------------------
# Definition flow
# ---------------------------------------------------------------------------

def s_project_fields(fields: Maybe<&2, List<&2, ArmField>>, field: U32, +catalog: Catalog) -> DefFlow:
  match fields:
    case None{}: DefFlow{s_flow_unknown(), s_flow_empty(), Nil{}}
    case Some{items}: s_project_field_at(s_field_at(items, U32.to_nat(field)), catalog)

def s_project_family(found: Maybe<&2, FamilyRow>, ctor_key: String, field: U32, +catalog: Catalog) -> DefFlow:
  match found:
    case None{}: DefFlow{s_flow_unknown(), s_flow_empty(), Nil{}}
    case Some{FamilyRow{key, native, arity, arms}}:
      s_project_fields(s_arm_fields(arms, ctor_key), field, catalog)

def s_project_flow_at(found: Maybe<&2, CtorRow>, field: U32, +catalog: Catalog) -> DefFlow:
  match found:
    case None{}: DefFlow{s_flow_unknown(), s_flow_empty(), Nil{}}
    case Some{CtorRow{id, key, family}}:
      s_project_family(IndexLookup.find(FamilyRow, s_catalog_families(catalog), family), key, field, catalog)

def s_project_flow(constructor: U32, field: U32, +catalog: Catalog) -> DefFlow:
  s_project_flow_at(IndexLookup.find(CtorRow, s_catalog_ctors_by_id(catalog), U32.show(constructor)), field, catalog)

def s_atom_or_undefined(found: Maybe<&2, BIR.Atom>) -> BIR.Atom:
  match found:
    case Some{value}: value
    case None{}: BIR.Undefined{}

# ---------------------------------------------------------------------------
# Body result flows
# ---------------------------------------------------------------------------

def s_args_second_fallback(args: List<&2, BIR.Arg>) -> BIR.Atom:
  s_atom_or_undefined(s_args_second(args))

def s_direct_flow_at(is_bind: Bool, bkey: String, code: U32, args: List<&2, BIR.Arg>, st: AState, +catalog: Catalog, +decls: DeclFacts) -> DefFlow:
  match is_bind:
    case True{}:
      DefFlow{s_flow_ok([s_function_head()]), s_atom_pay(bkey, s_args_second_fallback(args), s_st_pays(st)), Nil{}}
    case False{}: s_code_decl_flow(code, st, decls, catalog)

def s_direct_flow(bkey: String, +code: U32, args: List<&2, BIR.Arg>, st: AState, +catalog: Catalog, +decls: DeclFacts) -> DefFlow:
  s_direct_flow_at(s_is_bind(s_decls_by_code(decls), code), bkey, code, args, st, catalog, decls)

def s_symbol_def_flow(found: Maybe<&2, DeclRow>, +key: String, +st: AState, +catalog: Catalog) -> DefFlow:
  match found:
    case None{}: DefFlow{s_flow_unknown(), s_flow_unknown(), ResolvedDecl{key} <> Nil{}}
    case Some{+row}: DefFlow{s_decl_value_flow(row, st, catalog, key), s_decl_pay_flow(row, st, catalog, key), s_symbol_call(row, key) <> Nil{}}

def s_def_flow(entry: DefEntry, +st: AState, +catalog: Catalog, +decls: DeclFacts) -> DefFlow:
  match entry:
    case DefEntry{+bkey, row}:
      match row:
        case DefConstruct{constructor}: s_construct_flow(constructor, catalog)
        case DefProject{constructor, field}: s_project_flow(constructor, field, catalog)
        case DefPrim{primitive, types}:
          DefFlow{s_heads_to_flow(s_primitive_heads(s_catalog_families(catalog), s_catalog_labels(catalog), primitive, types)), s_flow_empty(), Nil{}}
        case DefCopy{+atom}:
          DefFlow{s_atom_flow(bkey, atom, s_st_flows(st)), s_atom_pay(bkey, atom, s_st_pays(st)), s_atom_call_at(s_atom_key(bkey, atom), s_st_calls(st))}
        case DefClosure{+code}:
          DefFlow{s_flow_ok([s_function_head()]), s_flow(s_st_pays(st), s_code_result(code)), ResolvedCode{code} <> Nil{}}
        case DefDirect{dbkey, code, args}:
          s_direct_flow(dbkey, code, args, st, catalog, decls)
        case DefApply{+abkey, +fn}:
          DefFlow{s_resolved_flow_union(s_atom_call(abkey, fn, s_st_calls(st)), st, catalog, decls), s_resolved_pay_union(s_atom_call(abkey, fn, s_st_calls(st)), st, catalog, decls), Nil{}}
        case DefSymbol{+key}: s_symbol_def_flow(s_decl_row(decls, key), key, st, catalog)
        case DefOther{}: DefFlow{s_flow_empty(), s_flow_empty(), Nil{}}

def s_fail_first(left: Maybe<&2, String>, right: Maybe<&2, String>) -> Maybe<&2, String>:
  match left:
    case Some{_}: left
    case None{}: right

def s_block_merge(left: BlockFlow, right: BlockFlow) -> BlockFlow:
  match left right:
    case BlockFlow{lvalue, lanswer, lfail} BlockFlow{rvalue, ranswer, rfail}:
      BlockFlow{s_flow_merge(lvalue, rvalue), s_flow_merge(lanswer, ranswer), s_fail_first(lfail, rfail)}

def s_tail_direct_block(df: DefFlow) -> BlockFlow:
  match df:
    case DefFlow{value, pay, call}: BlockFlow{value, pay, None{}}

def s_tail_direct_flow_at(is_bind: Bool, code: U32, args: List<&2, BIR.Arg>, +bkey: String, +st: AState, +catalog: Catalog, +decls: DeclFacts) -> BlockFlow:
  match is_bind:
    case True{}: BlockFlow{s_flow_ok([s_function_head()]), s_atom_pay(bkey, s_args_second_fallback(args), s_st_pays(st)), None{}}
    case False{}: s_tail_direct_block(s_code_decl_flow(code, st, decls, catalog))

def s_tail_direct_flow(+code: U32, args: List<&2, BIR.Arg>, +bkey: String, +st: AState, +catalog: Catalog, +decls: DeclFacts) -> BlockFlow:
  s_tail_direct_flow_at(s_is_bind(s_decls_by_code(decls), code), code, args, bkey, st, catalog, decls)

def s_tail_apply_flow(+fn: BIR.Atom, arg: BIR.Arg, +bkey: String, +st: AState, +catalog: Catalog, +decls: DeclFacts) -> BlockFlow:
  BlockFlow{
    s_resolved_flow_union(s_atom_call(bkey, fn, s_st_calls(st)), st, catalog, decls),
    s_resolved_pay_union(s_atom_call(bkey, fn, s_st_calls(st)), st, catalog, decls),
    None{}
  }

def s_block_flow(block: BIR.Block, +bkey: String, +st: AState, +catalog: Catalog, +decls: DeclFacts) -> BlockFlow:
  match block:
    case BIR.Return{+value}: BlockFlow{s_atom_flow(bkey, value, s_st_flows(st)), s_atom_pay(bkey, value, s_st_pays(st)), None{}}
    case BIR.Let{id, op, next}: s_block_flow(next, bkey, st, catalog, decls)
    case BIR.Branch{condition, yes, no}: s_block_merge(s_block_flow(yes, bkey, st, catalog, decls), s_block_flow(no, bkey, st, catalog, decls))
    case BIR.Region{label, body, next}: s_block_merge(s_block_flow(body, bkey, st, catalog, decls), s_block_flow(next, bkey, st, catalog, decls))
    case BIR.LeaveRegion{label}: BlockFlow{s_flow_empty(), s_flow_empty(), None{}}
    case BIR.TailDirect{code, args}: s_tail_direct_flow(code, args, bkey, st, catalog, decls)
    case BIR.TailApply{fn, arg}: s_tail_apply_flow(fn, arg, bkey, st, catalog, decls)
    case BIR.Failure{message}: BlockFlow{s_flow_empty(), s_flow_empty(), None{}}

def s_callees_add_go(+items: List<&2, Resolved>, +st: AState, +key: String) -> AState:
  match items:
    case Nil{}: st
    case +item <> rest:
      next = s_st_call_add(st, key, item)
      s_callees_add_go(rest, next, key)

def s_st_add_atom(+st: AState, +key: String, +bkey: String, +atom: BIR.Atom) -> AState:
  flow = s_atom_flow(bkey, atom, s_st_flows(st))
  pay = s_atom_pay(bkey, atom, s_st_pays(st))
  call = s_atom_call(bkey, atom, s_st_calls(st))
  st1 = s_st_flow_add(st, key, flow)
  st2 = s_st_pay_add(st1, key, pay)
  s_callees_add_go(call, st2, key)

# ---------------------------------------------------------------------------
# Analysis rounds
# ---------------------------------------------------------------------------

def s_fail_or(st: AState, fail: Maybe<&2, String>) -> AState:
  match fail:
    case None{}: st
    case Some{message}: s_st_fail(st, message)

def s_body_result_add(st: AState, +bkey: String, bf: BlockFlow) -> AState:
  match bf:
    case BlockFlow{value, answer, fail}:
      st1 = s_st_flow_add(st, s_body_result(bkey), value)
      st2 = s_st_pay_add(st1, s_body_result(bkey), answer)
      s_fail_or(st2, fail)

def s_round_results_go(+rows: List<&2, BodyRow>, +facts: Facts, +st: AState) -> AState:
  match rows:
    case Nil{}: st
    case +row <> rest:
      match row:
        case BodyRow{owner, bkey, lazy, body, params, capture_count}:
          next = s_body_result_add(st, bkey, s_block_flow(body, bkey, st, s_facts_catalog(facts), s_facts_decls(facts)))
          s_round_results_go(rest, facts, next)

def s_def_flow_add(st: AState, +key: String, df: DefFlow) -> AState:
  match df:
    case DefFlow{value, pay, call}:
      st1 = s_st_flow_add(st, key, value)
      st2 = s_st_pay_add(st1, key, pay)
      s_callees_add_go(call, st2, key)

def s_round_def_entry(found: Maybe<&2, DefEntry>, +key: String, +facts: Facts, +st: AState) -> AState:
  match found:
    case None{}: st
    case Some{entry}: s_def_flow_add(st, key, s_def_flow(entry, st, s_facts_catalog(facts), s_facts_decls(facts)))

def s_round_def_add(+key: String, +facts: Facts, +st: AState) -> AState:
  s_round_def_entry(IndexLookup.find(DefEntry, s_built_defs_of(s_facts_built(facts)), key), key, facts, st)

def s_round_defs_go(+keys: List<&2, String>, +facts: Facts, +st: AState) -> AState:
  match keys:
    case Nil{}: st
    case +key <> rest:
      next = s_round_def_add(key, facts, st)
      s_round_defs_go(rest, facts, next)

def s_call_arg_at(found: Maybe<&2, U32>, +value: BIR.Atom, body: String, +bkey: String, +st: AState) -> AState:
  match found:
    case None{}: st
    case Some{param}: s_st_add_atom(st, s_body_local(body, param), bkey, value)

def s_u32_at(params: List<&2, U32>, index: Nat) -> Maybe<&2, U32>:
  match params index:
    case Nil{} _: None{}
    case +item <> _ 0n: Some{item}
    case _ <> rest 1n+rest_index: s_u32_at(rest, rest_index)

def s_param_at(found: Maybe<&2, List<&2, U32>>, index: Nat) -> Maybe<&2, U32>:
  match found:
    case None{}: None{}
    case Some{params}: s_u32_at(params, index)

def s_param_list_at(found: Maybe<&2, List<&2, U32>>) -> List<&2, U32>:
  match found:
    case Some{value}: value
    case None{}: Nil{}

def s_map_param_list(+map: Map<&2, List<&2, U32>>, +key: String) -> List<&2, U32>:
  s_param_list_at(IndexLookup.find(List<&2, U32>, map, key))

def s_call_args_go(+args: List<&2, BIR.Arg>, +index: Nat, +params: List<&2, U32>, +bkey: String, +code: U32, +facts: Facts, +st: AState) -> AState:
  match args:
    case Nil{}: st
    case +arg <> rest:
      next = s_call_arg_at(s_u32_at(params, index), s_arg_value(arg), s_code_body(code), bkey, st)
      s_call_args_go(rest, Nat.add(index, 1n), params, bkey, code, facts, next)

def s_call_site_add(site: CallSite, +facts: Facts, +st: AState) -> AState:
  match site:
    case CallSite{bkey, +code, args}:
      params = s_map_param_list(s_decls_params(s_facts_decls(facts)), U32.show(code))
      s_call_args_go(args, 0n, params, bkey, code, facts, st)

def s_round_calls_go(+sites: List<&2, CallSite>, +facts: Facts, +st: AState) -> AState:
  match sites:
    case Nil{}: st
    case +site <> rest:
      next = s_call_site_add(site, facts, st)
      s_round_calls_go(rest, facts, next)

def s_capture_args_go(+args: List<&2, BIR.Arg>, +bkey: String, +code: U32, +index: Nat, +facts: Facts, +st: AState) -> AState:
  match args:
    case Nil{}: st
    case +arg <> rest:
      match arg:
        case BIR.Arg{_, value}:
          next = s_st_add_atom(st, s_body_capture(s_code_body(code), index), bkey, value)
          s_capture_args_go(rest, bkey, code, Nat.add(index, 1n), facts, next)

def s_capture_site_add(site: ClosureSite, +facts: Facts, +st: AState) -> AState:
  match site:
    case ClosureSite{bkey, code, captures}: s_capture_args_go(captures, bkey, code, 0n, facts, st)

def s_round_captures_go(+sites: List<&2, ClosureSite>, +facts: Facts, +st: AState) -> AState:
  match sites:
    case Nil{}: st
    case +site <> rest:
      next = s_capture_site_add(site, facts, st)
      s_round_captures_go(rest, facts, next)

def s_bind_param_at(found: Maybe<&2, U32>, st: AState, +code: U32, answer: Flow) -> AState:
  match found:
    case None{}: st
    case Some{param}: s_st_flow_add(st, s_body_local(s_code_body(code), param), answer)

def s_bind_param0(st: AState, +code: U32, answer: Flow, +facts: Facts) -> AState:
  s_bind_param_at(s_param_at(IndexLookup.find(List<&2, U32>, s_decls_params(s_facts_decls(facts)), U32.show(code)), 0n), st, code, answer)

def s_bind_row_kind(kind: String, +st: AState, +row: DeclRow, answer: Flow, +facts: Facts) -> AState:
  match kind:
    case "fn": s_bind_param0(st, s_row_code(row), answer, facts)
    case _: st

def s_bind_row(+st: AState, +row: DeclRow, answer: Flow, +facts: Facts) -> AState:
  s_bind_row_kind(s_row_kind(row), st, row, answer, facts)

def s_bind_decl_row(found: Maybe<&2, DeclRow>, st: AState, +key: String, answer: Flow, +facts: Facts) -> AState:
  match found:
    case None{}: st
    case Some{+row}: s_bind_row(st, row, answer, facts)

def s_bind_decl(st: AState, +key: String, answer: Flow, +facts: Facts) -> AState:
  s_bind_decl_row(s_decl_row(s_facts_decls(facts), key), st, key, answer, facts)

def s_bind_one(st: AState, res: Resolved, answer: Flow, +facts: Facts) -> AState:
  match res:
    case ResolvedCode{code}: s_bind_param0(st, code, answer, facts)
    case ResolvedDecl{+key}: s_bind_decl(st, key, answer, facts)
    case ResolvedNone{}: st

def s_bind_conts_go(+callees: List<&2, Resolved>, +answer: Flow, +facts: Facts, +st: AState) -> AState:
  match callees:
    case Nil{}: st
    case +res <> rest:
      next = s_bind_one(st, res, answer, facts)
      s_bind_conts_go(rest, answer, facts, next)

def s_bind_site_add(site: BindSite, +facts: Facts, +st: AState) -> AState:
  match site:
    case BindSite{+bkey, action, cont}:
      s_bind_conts_go(s_atom_call(bkey, cont, s_st_calls(st)), s_atom_pay(bkey, action, s_st_pays(st)), facts, st)

def s_round_binds_go(+sites: List<&2, BindSite>, +facts: Facts, +st: AState) -> AState:
  match sites:
    case Nil{}: st
    case +site <> rest:
      next = s_bind_site_add(site, facts, st)
      s_round_binds_go(rest, facts, next)

def s_demand_array(is_array: Bool, st: AState) -> AState:
  match is_array:
    case True{}: s_st_array(st)
    case False{}: st

def s_hot_add_head(+head: String, +st: AState) -> AState:
  s_demand_array(String.eq(head, s_family("Array")), s_st_hot_add(st, head))

def s_demand_heads_go(+heads: List<&2, String>, +st: AState) -> AState:
  match heads:
    case Nil{}: st
    case +head <> rest:
      next = s_hot_add_head(head, st)
      s_demand_heads_go(rest, next)


# The heads a runtime value can actually have: a node is built by a reachable
# Construct, by an array/primitive result, or by a foreign twin's laid result.
# An unknown demanded value is sealed over exactly this set, never over the
# whole catalog: a family with no producer in the program holds no value.
def s_demand_unknown(unknown: Bool, +facts: Facts, +st: AState) -> AState:
  match unknown:
    case True{}: s_st_forced_note(st, "a shared value's type is not determined by the reachable facts")
    case False{}: st

def s_demand_flow(flow: Flow, +facts: Facts, +st: AState) -> AState:
  match flow:
    case Flow{heads, unknown}:
      st1 = s_demand_unknown(unknown, facts, st)
      s_demand_heads_go(heads, st1)

def s_apply_param_at(found: Maybe<&2, U32>, st: AState, +code: U32, +bkey: String, atom: BIR.Atom) -> AState:
  match found:
    case None{}: st
    case Some{param}: s_st_add_atom(st, s_body_local(s_code_body(code), param), bkey, atom)

def s_apply_param0(st: AState, +code: U32, +bkey: String, atom: BIR.Atom, +facts: Facts) -> AState:
  s_apply_param_at(s_param_at(IndexLookup.find(List<&2, U32>, s_decls_params(s_facts_decls(facts)), U32.show(code)), 0n), st, code, bkey, atom)

def s_apply_row_kind(kind: String, +st: AState, +row: DeclRow, +bkey: String, atom: BIR.Atom, +facts: Facts) -> AState:
  match kind:
    case "fn": s_apply_param0(st, s_row_code(row), bkey, atom, facts)
    case _: st

def s_apply_row(+st: AState, +row: DeclRow, +bkey: String, atom: BIR.Atom, +facts: Facts) -> AState:
  s_apply_row_kind(s_row_kind(row), st, row, bkey, atom, facts)

def s_apply_decl_row(found: Maybe<&2, DeclRow>, st: AState, +bkey: String, atom: BIR.Atom, +facts: Facts) -> AState:
  match found:
    case None{}: st
    case Some{+row}: s_apply_row(st, row, bkey, atom, facts)

def s_apply_decl(st: AState, +key: String, +bkey: String, atom: BIR.Atom, +facts: Facts) -> AState:
  s_apply_decl_row(s_decl_row(s_facts_decls(facts), key), st, bkey, atom, facts)

def s_apply_one(+st: AState, res: Resolved, +bkey: String, +atom: BIR.Atom, +facts: Facts) -> AState:
  match res:
    case ResolvedCode{code}: s_apply_param0(st, code, bkey, atom, facts)
    case ResolvedDecl{+key}: s_apply_decl(st, key, bkey, atom, facts)
    case ResolvedNone{}: st

def s_apply_callees_go(+callees: List<&2, Resolved>, +bkey: String, +atom: BIR.Atom, +facts: Facts, +st: AState) -> AState:
  match callees:
    case Nil{}: st
    case +res <> rest:
      next = s_apply_one(st, res, bkey, atom, facts)
      s_apply_callees_go(rest, bkey, atom, facts, next)

def s_apply_unknown_many(many: Bool, +bkey: String, arg: BIR.Atom, +facts: Facts, +st: AState) -> AState:
  match many:
    case True{}: s_demand_flow(s_atom_flow(bkey, arg, s_st_flows(st)), facts, st)
    case False{}: st

def s_apply_callees_known(callees: List<&2, Resolved>, +bkey: String, arg: BIR.Atom, many: Bool, +facts: Facts, +st: AState) -> AState:
  match callees:
    case Nil{}: s_apply_unknown_many(many, bkey, arg, facts, st)
    case _: s_apply_callees_go(callees, bkey, arg, facts, st)

def s_apply_site_add(site: ApplySite, +facts: Facts, +st: AState) -> AState:
  match site:
    case ApplySite{+bkey, fn, arg, many}:
      s_apply_callees_known(s_atom_call(bkey, fn, s_st_calls(st)), bkey, arg, many, facts, st)

def s_round_applies_go(+sites: List<&2, ApplySite>, +facts: Facts, +st: AState) -> AState:
  match sites:
    case Nil{}: st
    case +site <> rest:
      next = s_apply_site_add(site, facts, st)
      s_round_applies_go(rest, facts, next)

def s_demand_site_add(site: DemandSite, +facts: Facts, +st: AState) -> AState:
  match site:
    case DemandSite{+bkey, atom}: s_demand_flow(s_atom_flow(bkey, atom, s_st_flows(st)), facts, st)

def s_round_demands_go(+sites: List<&2, DemandSite>, +facts: Facts, +st: AState) -> AState:
  match sites:
    case Nil{}: st
    case +site <> rest:
      next = s_demand_site_add(site, facts, st)
      s_round_demands_go(rest, facts, next)

def s_dup_if(dup: Bool, key: String, +facts: Facts, +st: AState) -> AState:
  match dup:
    case True{}: s_demand_flow(s_flow(s_st_flows(st), key), facts, st)
    case False{}: st

def s_round_dups_go(+keys: List<&2, String>, +facts: Facts, +st: AState) -> AState:
  match keys:
    case Nil{}: st
    case +key <> rest:
      next = s_dup_if(Nat.is_gt(s_map_nat(s_built_occ(s_facts_built(facts)), key), 1n), key, facts, st)
      s_round_dups_go(rest, facts, next)

def s_explore_heads_go(+heads: List<&2, String>, +st: AState) -> AState:
  match heads:
    case Nil{}: st
    case +head <> rest:
      next = s_hot_add_head(head, st)
      s_explore_heads_go(rest, next)

def s_explore_unknown(unknown: Bool, st: AState) -> AState:
  match unknown:
    case True{}: s_st_forced_note(st, "a hot field's type is not determined by the reachable facts")
    case False{}: st

def s_explore_fail(fail: Maybe<&2, String>, +st: AState) -> AState:
  match fail:
    case None{}: st
    case Some{message}: s_st_fail(st, message)

def s_explore_heads(heads: Heads, st: AState) -> AState:
  match heads:
    case Heads{list, unknown, fail}:
      st1 = s_explore_fail(fail, st)
      st2 = s_explore_unknown(unknown, st1)
      s_explore_heads_go(list, st2)

def s_explore_fields_go(+fields: List<&2, ArmField>, +facts: Facts, +st: AState) -> AState:
  match fields:
    case Nil{}: st
    case +field <> rest:
      match field:
        case ArmField{live, ty}:
          next = s_explore_heads(s_descriptor_heads(s_catalog_families(s_facts_catalog(facts)), s_catalog_labels(s_facts_catalog(facts)), ty), st)
          s_explore_fields_go(rest, facts, next)


# A hot family's parameter fields are instantiated by the actual Construct
# sites; seal exactly the values those sites store, never the whole catalog.
def s_expand_attr(ctor_key: String, fields: List<&2, ArmField>, +facts: Facts, +st: AState) -> AState:
  st1 = s_st_ctr_add(st, ctor_key)
  s_explore_fields_go(s_live_fields(fields), facts, st1)

def s_expand_arms_go(+arms: List<&2, ArmRow>, +facts: Facts, +st: AState) -> AState:
  match arms:
    case Nil{}: st
    case +arm <> rest:
      match arm:
        case ArmRow{key, fields}:
          next = s_expand_attr(key, fields, facts, st)
          s_expand_arms_go(rest, facts, next)

def s_expand_family_row(found: Maybe<&2, FamilyRow>, +facts: Facts, +st: AState) -> AState:
  match found:
    case None{}: s_st_forced_note(st, "a hot type has no declared family")
    case Some{FamilyRow{key, native, arity, arms}}: s_expand_arms_go(arms, facts, st)

def s_element_heads_go(+heads: List<&2, String>, +st: AState) -> AState:
  match heads:
    case Nil{}: st
    case +head <> rest:
      next = s_hot_add_head(head, st)
      s_element_heads_go(rest, next)

def s_element_heads_unknown(unknown: Bool, heads: List<&2, String>, +st: AState) -> AState:
  match unknown:
    case True{}:
      st1 = s_st_forced_note(st, "a shared array's element type is not determined")
      s_element_heads_go(heads, st1)
    case False{}: s_element_heads_go(heads, st)

def s_element_force_heads(heads: List<&2, String>, +st: AState, +facts: Facts) -> AState:
  match heads:
    case Nil{}: s_st_forced_note(st, "a shared array's element type is not determined")
    case +_ <> _:
      s_element_heads_unknown(s_built_element_unknown(s_facts_built(facts)), heads, st)

def s_element_force(st: AState, +facts: Facts) -> AState:
  s_element_force_heads(s_built_element_heads(s_facts_built(facts)), st, facts)

def s_expand_array_if(is_array: Bool, +fam: String, +facts: Facts, +st: AState) -> AState:
  match is_array:
    case True{}: s_element_force(s_st_array(st), facts)
    case False{}: s_expand_family_row(IndexLookup.find(FamilyRow, s_catalog_families(s_facts_catalog(facts)), fam), facts, st)

def s_expand_family(+fam: String, +facts: Facts, +st: AState) -> AState:
  s_expand_array_if(String.eq(fam, "Array"), fam, facts, st)

def s_expand_family_if(on: Bool, +fam: String, +facts: Facts, +st: AState) -> AState:
  match on:
    case True{}: s_expand_family(fam, facts, st)
    case False{}: st

def s_expand_families_go(+keys: List<&2, String>, +facts: Facts, +st: AState) -> AState:
  match keys:
    case Nil{}: st
    case +fam <> rest:
      next = s_expand_family_if(s_flag_has(s_st_hot_map(st), s_family(fam)), fam, facts, st)
      s_expand_families_go(rest, facts, next)

def s_round_hot(+st: AState, +facts: Facts) -> AState:
  s_expand_families_go(s_catalog_family_keys(s_facts_catalog(facts)), facts, st)

def s_analysis_round(st: AState, +facts: Facts) -> AState:
  st1 = s_round_results_go(s_built_bodies(s_facts_built(facts)), facts, st)
  st2 = s_round_defs_go(s_built_def_keys(s_facts_built(facts)), facts, st1)
  st3 = s_round_calls_go(s_built_calls(s_facts_built(facts)), facts, st2)
  st4 = s_round_captures_go(s_built_closures(s_facts_built(facts)), facts, st3)
  st5 = s_round_applies_go(s_built_applies(s_facts_built(facts)), facts, st4)
  st6 = s_round_binds_go(s_built_binds(s_facts_built(facts)), facts, st5)
  st7 = s_round_demands_go(s_built_demands(s_facts_built(facts)), facts, st6)
  st8 = s_round_dups_go(s_built_count_keys(s_facts_built(facts)), facts, st7)
  s_round_hot(st8, facts)


# ---------------------------------------------------------------------------
# Fixed point
# ---------------------------------------------------------------------------

def s_analyze(fuel: Nat, st: AState, +facts: Facts) -> AState:
  match fuel:
    case 0n: s_st_fail(st, "sharing analysis did not converge")
    case 1n+pred:
      match st:
        case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
          match changed:
            case False{}: AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, False{}, failure}
            case True{}: s_analyze(pred, s_analysis_round(AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, False{}, Nil{}, False{}, failure}, facts), facts)

# ---------------------------------------------------------------------------
# Plan assembly
# ---------------------------------------------------------------------------

def s_plan_ctors_go(+keys: List<&2, String>, +ctr: Map<&2, Bool>, +forced: Bool, +hot: Map<&2, Bool>) -> Map<&2, Bool>:
  match keys:
    case Nil{}: hot
    case +key <> rest:
      s_plan_ctors_go(rest, ctr, forced, Map.set(&2, Bool, hot, key, Bool.or(forced, s_flag_has(ctr, key))))

def s_plan_ctors(+keys: List<&2, String>, +ctr: Map<&2, Bool>, forced: Bool) -> Map<&2, Bool>:
  s_plan_ctors_go(keys, ctr, forced, Map.new(&2, Bool))

def s_plan_foreign_go(+keys: List<&2, String>, +hot: Map<&2, Bool>) -> Map<&2, Bool>:
  match keys:
    case Nil{}: hot
    case +key <> rest: s_plan_foreign_go(rest, Map.set(&2, Bool, hot, key, False{}))

def s_plan_of_catalog(+catalog: Catalog, +ctr: Map<&2, Bool>, array_hot: Bool, +forced: Bool, +note: List<&2, String>) -> SharingPlan:
  hot = s_plan_ctors(s_catalog_ctor_keys(catalog), ctr, forced)
  SharingPlan{s_plan_foreign_go(s_catalog_foreign_keys(catalog), hot), array_hot, forced, note}

def s_plan_of(+facts: Facts, +ctr: Map<&2, Bool>, array_hot: Bool, +forced: Bool, +note: List<&2, String>) -> SharingPlan:
  s_plan_of_catalog(s_facts_catalog(facts), ctr, array_hot, forced, note)

def s_plan_result(st: AState, +facts: Facts) -> SharingResult:
  match st:
    case AState{flow, pay, call, hot, ctr, array_hot, elem_unknown, forced, note, changed, failure}:
      match failure:
        case Some{message}: SharingFail{message}
        case None{}: SharingOk{s_plan_of(facts, ctr, array_hot, forced, note)}

# A round either stops or adds at least one lattice bit. The lattice is: two
# flow maps over V value keys and H head keys, V callee sets over T targets,
# and H hot bits. So 2*V*H + V*T + H + 2 rounds bound every program; V counts
# bodies, defined values, occurrence keys and symbols, T counts bodies plus
# foreign targets. No program size can exceed this, and no fixed cap exists.
def s_bound_total(+values: Nat, +heads: Nat, +targets: Nat) -> Nat:
  flow = Nat.mul(Nat.mul(Nat.add(values, 1n), heads), 2n)
  call = Nat.mul(Nat.add(values, 1n), targets)
  Nat.add(Nat.add(Nat.add(flow, call), heads), 2n)

def s_analysis_bound(+facts: Facts) -> Nat:
  values = Nat.add(
    Nat.add(
      Nat.add(
        List.length(&2, BodyRow, s_built_bodies(s_facts_built(facts))),
        List.length(&2, String, s_built_def_keys(s_facts_built(facts)))),
      List.length(&2, String, s_built_count_keys(s_facts_built(facts)))),
    List.length(&2, String, s_built_symbol_keys(s_facts_built(facts))))
  targets = Nat.add(
    Nat.add(
      List.length(&2, BodyRow, s_built_bodies(s_facts_built(facts))),
      List.length(&2, String, s_catalog_foreign_keys(s_facts_catalog(facts)))),
    1n)
  heads = Nat.add(List.length(&2, String, s_catalog_family_keys(s_facts_catalog(facts))), 1n)
  s_bound_total(values, heads, targets)

def s_catalog_result_at(failure: Maybe<&2, String>, +facts: Facts, built: BuiltFacts) -> SharingResult:
  match failure:
    case Some{message}: SharingFail{message}
    case None{}:
      st = s_st_new(s_built_element_unknown(built))
      s_plan_result(s_analyze(s_analysis_bound(facts), st, facts), facts)

def s_catalog_result(catalog: Catalog, +facts: Facts, built: BuiltFacts) -> SharingResult:
  s_catalog_result_at(s_catalog_failure(catalog), facts, built)

# ---------------------------------------------------------------------------
# Public API (frozen with CIRRenderer and CIRControl)
# ---------------------------------------------------------------------------

def s_plan_from_facts(+facts: Facts) -> SharingResult:
  s_catalog_result(s_facts_catalog(facts), facts, s_facts_built(facts))

def sharing_plan(program: BIR.Program) -> SharingResult:
  s_plan_from_facts(s_facts_build(program))

def ctor_hot(plan: SharingPlan, +key: String) -> Bool:
  match plan:
    case SharingPlan{hot, array_shared, forced, note}: s_map_bool(hot, key)

def array_shared(plan: SharingPlan) -> Bool:
  match plan:
    case SharingPlan{hot, array_shared, forced, note}: array_shared

def s_bool_text(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"

def diagnostic(plan: SharingPlan) -> String:
  match plan:
    case SharingPlan{hot, array_shared, forced, note}:
      String.concat([
        "sharing plan: forced=", s_bool_text(forced),
        ", array_shared=", s_bool_text(array_shared),
        ", notes=", Nat.show(s_size(note))
      ])

def field_seal(plan: SharingPlan, +key: String) -> Bool:
  ctor_hot(plan, key)

def io_seal_cid(plan: SharingPlan, +key: String) -> Bool:
  ctor_hot(plan, key)
