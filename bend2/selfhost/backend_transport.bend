# Backend aggregate transport
# ===========================
#
# One shared analysis and one shared private worker/wrapper transform for the
# two vector variants of Backend IR. Renderers never decide transport: they
# read this module's widths and render whatever vectors the optimizer built.
#
# Widths. A code's result width is the number of values its normal exits hand
# back: one for `Return`, `length` for `ReturnValues`, the callee's width for a
# `TailDirect`, and one for `TailApply`, which keeps the existing single-value
# closure convention. Zero proves bottom, never an empty vector, but is not a
# complete nonreturning-code classifier: strict-call continuations retain their
# static exit convention even when that callee cannot return. Region.next only
# contributes when a matching lexical leave can reach it. The analysis is one
# scan of every body plus a reverse-tail-edge worklist: a code is queued at most
# once when its width first becomes known, so each reverse edge is examined once.
#
# Validation is transport well-formedness only. It never adds a rule to old
# BIR except where a vector, a multi-value exit or a multi-value call makes the
# old single-value convention ambiguous: an empty vector, a one-component
# vector (a vector exists to move an aggregate), a nonzero width disagreement,
# a `Direct`/`Closure`/public/lazy/export boundary that would hand a vector to
# a single-value convention, and a `LetValues` whose count disagrees with its
# producer.
#
# Transform. `optimize` turns known producer/consumer pairs into workers:
#
#   * An eligible producer returns one constructor on every normal path, its
#     constructed value is used only by those returns, and it has one to seven
#     live fields (the initial eight-component selection). The construct must
#     sit on the body's linear let prefix, so branch-merged constructors stay
#     unoptimized. A fresh worker code clones the body, binds every field atom
#     once, in original order, at the original `Construct` position, and
#     returns `Word{constructor}` followed by those field locals.
#   * Every call site of that producer whose continuation only projects that
#     aggregate is rewritten to the worker with `LetValues`; `HasTag` on the
#     known constructor becomes the constant `True` and `Project` becomes the
#     matching component local.
#   * A site may instead forward the aggregate into one private callee
#     argument. When that parameter is used only by matching projections, one
#     consumer worker is cloned per (callee, argument position): its parameter
#     is replaced by the discriminator and the field parameters, and the call
#     is rewritten to pass the vector's components.
#
# Original code identities are untouched, so every boxed boundary, closure,
# public entry and foreign call keeps exactly the value it had. An aggregate
# whose identity escapes (returned, stored, captured, passed anywhere else, or
# whose producer has another returning path) keeps the original code path.
# Cloning is bounded: one worker per eligible producer and at most one
# consumer worker per (callee, argument position); no call site clones a body.
# Every generated code and local id is above everything the program already
# binds, in codes and lazy bodies alike.

import Base
import ./backend_ir.bend as BIR
import ./index_lookup.bend as IndexLookup

type WidthResult is Data:
  WidthsOk{widths: Map<&2, Nat>}
  WidthsFail{message: String}

def width_of(+widths: Map<&2, Nat>, +code: U32) -> Nat:
  match IndexLookup.find(Nat, widths, U32.show(code)):
    case Some{value}: value
    case None{}: 0n

# ---------------------------------------------------------------------------
# Result widths
# ---------------------------------------------------------------------------

# A width join is over `Maybe Nat`: `None` is "this exit does not return
# here", so it is neutral, and two different nonzero widths are a conflict.
type Join is Data:
  JoinWidth{width: Maybe<&2, Nat>}
  JoinConflict{}

def width_join(+left: Maybe<&2, Nat>, +right: Maybe<&2, Nat>) -> Join:
  match left:
    case None{}: JoinWidth{right}
    case Some{l}:
      match right:
        case None{}: JoinWidth{left}
        case Some{r}:
          match Nat.is_eq(l, r):
            case True{}: JoinWidth{left}
            case False{}: JoinConflict{}

type Scan is Data:
  Scan{width: Maybe<&2, Nat>, targets: List<&2, U32>, problem: Maybe<&2, String>, leaves: List<&2, U32>}

def scan_fail(+inner: Scan, +message: String) -> Scan:
  match inner:
    case Scan{+width, +targets, +problem, +leaves}:
      match problem:
        case Some{_}: inner
        case None{}: Scan{width, targets, Some{message}, leaves}

def scan_block(block: BIR.Block) -> Scan:
  match block:
    case BIR.Return{value}: Scan{Some{1n}, Nil{}, None{}, Nil{}}
    case BIR.ReturnValues{values}: scan_returns(values)
    case BIR.Let{id, op, next}: scan_block(next)
    case BIR.LetValues{ids, code, args, next}: scan_let_values(ids, scan_block(next))
    case BIR.Branch{condition, yes, no}: scan_join(scan_block(yes), scan_block(no))
    case BIR.Region{label, body, next}: scan_region(label, scan_block(body), next)
    case BIR.LeaveRegion{label}: Scan{None{}, Nil{}, None{}, [label]}
    case BIR.TailDirect{code, args}: Scan{None{}, [code], None{}, Nil{}}
    case BIR.TailApply{fn, arg}: Scan{Some{1n}, Nil{}, None{}, Nil{}}
    case BIR.Failure{message}: Scan{None{}, Nil{}, None{}, Nil{}}

def scan_returns(+values: List<&2, BIR.Atom>) -> Scan:
  +count = List.length(&2, BIR.Atom, values)
  match Nat.is_lt(count, 2n):
    case True{}: Scan{None{}, Nil{}, Some{"a transport return vector needs at least two components"}, Nil{}}
    case False{}: Scan{Some{count}, Nil{}, None{}, Nil{}}

def scan_let_values(+ids: List<&2, U32>, +inner: Scan) -> Scan:
  count = List.length(&2, U32, ids)
  match Nat.is_lt(count, 2n):
    case True{}: scan_fail(inner, "a transport let vector needs at least two bindings")
    case False{}: inner

def scan_join(+left: Scan, +right: Scan) -> Scan:
  match left:
    case Scan{+lw, +lt, +lp, +ll}:
      match right:
        case Scan{+rw, +rt, +rp, +rl}:
          match width_join(lw, rw):
            case JoinConflict{}: Scan{None{}, List.append(&2, U32, lt, rt), Some{"a code's exits disagree on return width"}, List.append(&2, U32, ll, rl)}
            case JoinWidth{+width}: Scan{width, List.append(&2, U32, lt, rt), first_problem(lp, rp), List.append(&2, U32, ll, rl)}

def first_problem(+lp: Maybe<&2, String>, +rp: Maybe<&2, String>) -> Maybe<&2, String>:
  match lp:
    case Some{_}: lp
    case None{}: rp

def width_leave_has(+labels: List<&2, U32>, +label: U32) -> Bool:
  match labels:
    case Nil{}: False{}
    case +known <> rest: Bool.or(U32.is_eq(known, label), width_leave_has(rest, label))

def width_leave_remove(+labels: List<&2, U32>, +label: U32) -> List<&2, U32>:
  match labels:
    case Nil{}: Nil{}
    case +known <> rest:
      match U32.is_eq(known, label):
        case True{}: width_leave_remove(rest, label)
        case False{}: known <> width_leave_remove(rest, label)

def scan_region(+label: U32, +body: Scan, +next: BIR.Block) -> Scan:
  match body:
    case Scan{+width, +targets, +problem, +leaves}:
      match width_leave_has(leaves, label):
        case False{}: body
        case True{}: scan_join(Scan{width, targets, problem, width_leave_remove(leaves, label)}, scan_block(next))

type Summary is Data:
  Summary{code: U32, width: Maybe<&2, Nat>, targets: List<&2, U32>, problem: Maybe<&2, String>}

def summary_make(+code: U32, +body: BIR.Block) -> Summary:
  match scan_block(body):
    case Scan{+width, +targets, +problem, leaves}: Summary{code, width, targets, problem}

def scan_codes(+codes: List<&2, BIR.Code>, +acc: List<&2, Summary>) -> List<&2, Summary>:
  match codes:
    case Nil{}: List.reverse(&2, Summary, acc)
    case +code <> rest:
      match code:
        case BIR.Code{+id, +captures, +parameters, +body}: scan_codes(rest, summary_make(id, body) <> acc)

def scan_problem(+scans: List<&2, Summary>) -> Maybe<&2, String>:
  match scans:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case Summary{+code, +width, +targets, +problem}:
          match problem:
            case Some{_}: problem
            case None{}: scan_problem(rest)

type Callers is Data:
  Callers{items: List<&2, U32>}

type Solve is Data:
  Solve{pending: List<&2, U32>, widths: Map<&2, Nat>, merged: Map<&2, Nat>, conflict: Maybe<&2, String>}

def summary_map(+scans: List<&2, Summary>, +acc: Map<&2, Summary>) -> Map<&2, Summary>:
  match scans:
    case Nil{}: acc
    case +item <> rest:
      match item:
        case Summary{+code, +width, +targets, +problem}:
          summary_map(rest, Map.set(&2, Summary, acc, U32.show(code), item))

def reverse_map(+scans: List<&2, Summary>, +acc: Map<&2, Callers>) -> Map<&2, Callers>:
  match scans:
    case Nil{}: acc
    case +item <> rest:
      match item:
        case Summary{+code, +width, +targets, +problem}: reverse_map(rest, reverse_targets(targets, code, acc))

def reverse_targets(+targets: List<&2, U32>, +caller: U32, +acc: Map<&2, Callers>) -> Map<&2, Callers>:
  match targets:
    case Nil{}: acc
    case +target <> rest: reverse_targets(rest, caller, reverse_add(target, caller, acc))

def reverse_add(+target: U32, +caller: U32, +acc: Map<&2, Callers>) -> Map<&2, Callers>:
  +key = U32.show(target)
  match IndexLookup.find(Callers, acc, key):
    case Some{callers}:
      match callers:
        case Callers{+items}: Map.set(&2, Callers, acc, key, Callers{caller <> items})
    case None{}: Map.set(&2, Callers, acc, key, Callers{[caller]})

def callers_at(+acc: Map<&2, Callers>, +code: U32) -> List<&2, U32>:
  match IndexLookup.find(Callers, acc, U32.show(code)):
    case Some{callers}:
      match callers:
        case Callers{+items}: items
    case None{}: Nil{}

def seed_codes(+scans: List<&2, Summary>, +acc: List<&2, U32>) -> List<&2, U32>:
  match scans:
    case Nil{}: List.reverse(&2, U32, acc)
    case +item <> rest:
      match item:
        case Summary{+code, +width, +targets, +problem}:
          match width:
            case Some{_}: seed_codes(rest, code <> acc)
            case None{}: seed_codes(rest, acc)

def seed_widths(+scans: List<&2, Summary>, +acc: Map<&2, Nat>) -> Map<&2, Nat>:
  match scans:
    case Nil{}: acc
    case +item <> rest:
      match item:
        case Summary{+code, +width, +targets, +problem}:
          match width:
            case Some{value}: seed_widths(rest, Map.set(&2, Nat, acc, U32.show(code), value))
            case None{}: seed_widths(rest, Map.set(&2, Nat, acc, U32.show(code), 0n))

def solve(+scans: List<&2, Summary>) -> WidthResult:
  solve_loop(summary_map(scans, Map.new(&2, Summary)), reverse_map(scans, Map.new(&2, Callers)), Solve{seed_codes(scans, Nil{}), seed_widths(scans, Map.new(&2, Nat)), Map.new(&2, Nat), None{}})

def solve_loop(+summaries: Map<&2, Summary>, +reverse: Map<&2, Callers>, +state: Solve) -> WidthResult:
  match state:
    case Solve{+pending, +widths, +merged, +conflict}:
      match conflict:
        case Some{message}: WidthsFail{message}
        case None{}:
          match pending:
            case Nil{}: WidthsOk{widths}
            case +code <> rest:
              solve_callers(callers_at(reverse, code), code, width_of(widths, code), summaries, reverse, Solve{rest, widths, merged, None{}})

def solve_callers(+callers: List<&2, U32>, +code: U32, +width: Nat, +summaries: Map<&2, Summary>, +reverse: Map<&2, Callers>, +state: Solve) -> WidthResult:
  match state:
    case Solve{+pending, +widths, +merged, +conflict}:
      match conflict:
        case Some{message}: WidthsFail{message}
        case None{}:
          match callers:
            case Nil{}: solve_loop(summaries, reverse, Solve{pending, widths, merged, None{}})
            case +caller <> rest:
              absorb(caller, width, rest, code, summaries, reverse, Solve{pending, widths, merged, None{}})

def absorb(+caller: U32, +width: Nat, +rest: List<&2, U32>, +code: U32, +summaries: Map<&2, Summary>, +reverse: Map<&2, Callers>, +state: Solve) -> WidthResult:
  match state:
    case Solve{+pending, +widths, +merged, +conflict}:
      +key = U32.show(caller)
      match IndexLookup.find(Nat, merged, key):
        case Some{known}:
          match Nat.is_eq(known, width):
            case True{}: absorb_merge(caller, width, rest, code, summaries, reverse, Solve{pending, widths, merged, None{}})
            case False{}: WidthsFail{"a code's tail calls disagree on return width"}
        case None{}:
          absorb_merge(caller, width, rest, code, summaries, reverse, Solve{pending, widths, Map.set(&2, Nat, merged, key, width), None{}})

def absorb_merge(+caller: U32, +width: Nat, +rest: List<&2, U32>, +code: U32, +summaries: Map<&2, Summary>, +reverse: Map<&2, Callers>, +state: Solve) -> WidthResult:
  match state:
    case Solve{+pending, +widths, +merged, +conflict}:
      +key = U32.show(caller)
      match IndexLookup.find(Summary, summaries, key):
        case None{}: WidthsFail{"a tail call names no analyzed code"}
        case Some{summary}:
          match summary:
            case Summary{+known, +constant, +targets, +problem}:
              match width_join(constant, Some{width}):
                case JoinConflict{}: WidthsFail{"a code's exits disagree on return width"}
                case JoinWidth{_}: absorb_set(caller, width, rest, code, summaries, reverse, pending, widths, merged)

def absorb_set(+caller: U32, +width: Nat, +rest: List<&2, U32>, +code: U32, +summaries: Map<&2, Summary>, +reverse: Map<&2, Callers>, +pending: List<&2, U32>, +widths: Map<&2, Nat>, +merged: Map<&2, Nat>) -> WidthResult:
  +key = U32.show(caller)
  match IndexLookup.find(Nat, widths, key):
    case Some{known}:
      match Nat.is_eq(known, width):
        case True{}: solve_callers(rest, code, width, summaries, reverse, Solve{pending, widths, merged, None{}})
        case False{}:
          match Nat.is_eq(known, 0n):
            case True{}: solve_callers(rest, code, width, summaries, reverse, Solve{caller <> pending, Map.set(&2, Nat, widths, key, width), merged, None{}})
            case False{}: WidthsFail{"a code's exits disagree on return width"}
    case None{}: WidthsFail{"a tail-call caller has no analyzed code"}

# ---------------------------------------------------------------------------
# Validation of transport boundaries
# ---------------------------------------------------------------------------

def check_pair(+first: Maybe<&2, String>, +second: Maybe<&2, String>) -> Maybe<&2, String>:
  match first:
    case Some{_}: first
    case None{}: second

def check_vector_width(+widths: Map<&2, Nat>, +code: U32, +count: Nat) -> Maybe<&2, String>:
  match IndexLookup.find(Nat, widths, U32.show(code)):
    case None{}: Some{"a let vector names no producer code"}
    case Some{width}:
      match Bool.or(Nat.is_eq(width, 0n), Nat.is_eq(width, count)):
        case True{}: None{}
        case False{}: Some{"a let vector's binding count disagrees with its producer's return width"}

def check_single_width(+widths: Map<&2, Nat>, +code: U32, +message: String) -> Maybe<&2, String>:
  match Nat.is_gt(width_of(widths, code), 1n):
    case True{}: Some{message}
    case False{}: None{}

def check_vector_ids(+ids: List<&2, U32>, +seen: Map<&2, Bool>) -> Maybe<&2, String>:
  match ids:
    case Nil{}: None{}
    case +id <> rest:
      +key = U32.show(id)
      match IndexLookup.find(Bool, seen, key):
        case Some{_}: Some{"a let vector repeats a binding id"}
        case None{}: check_vector_ids(rest, Map.set(&2, Bool, seen, key, True{}))

def check_vector_bindings(+ids: List<&2, U32>) -> Maybe<&2, String>:
  match Nat.is_lt(List.length(&2, U32, ids), 2n):
    case True{}: Some{"a transport let vector needs at least two bindings"}
    case False{}: check_vector_ids(ids, Map.new(&2, Bool))

def check_vector_return(+values: List<&2, BIR.Atom>) -> Maybe<&2, String>:
  match Nat.is_lt(List.length(&2, BIR.Atom, values), 2n):
    case True{}: Some{"a transport return vector needs at least two components"}
    case False{}: None{}

def check_op(+op: BIR.Op, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match op:
    case BIR.Closure{code, captures, parameters}: check_single_width(widths, code, "a multi-value code is used as a closure")
    case BIR.Direct{code, args}: check_single_width(widths, code, "a multi-value code is called as a single value")
    case _: None{}

def check_block(+block: BIR.Block, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match block:
    case BIR.Let{id, op, next}: check_pair(check_op(op, widths), check_block(next, widths))
    case BIR.LetValues{ids, code, args, next}: check_pair(check_vector_bindings(ids), check_pair(check_vector_width(widths, code, List.length(&2, U32, ids)), check_block(next, widths)))
    case BIR.Branch{condition, yes, no}: check_pair(check_block(yes, widths), check_block(no, widths))
    case BIR.Region{label, body, next}: check_pair(check_block(body, widths), check_block(next, widths))
    case BIR.ReturnValues{values}: check_vector_return(values)
    case _: None{}

def check_codes(+codes: List<&2, BIR.Code>, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match codes:
    case Nil{}: None{}
    case +code <> rest:
      match code:
        case BIR.Code{+id, +captures, +parameters, +body}: check_pair(check_block(body, widths), check_codes(rest, widths))

def join_targets(+width: Maybe<&2, Nat>, +targets: List<&2, U32>, +widths: Map<&2, Nat>) -> Join:
  match targets:
    case Nil{}: JoinWidth{width}
    case +target <> rest:
      match Nat.is_eq(width_of(widths, target), 0n):
        case True{}: join_targets(width, rest, widths)
        case False{}:
          match width_join(width, Some{width_of(widths, target)}):
            case JoinConflict{}: JoinConflict{}
            case JoinWidth{+merged}: join_targets(merged, rest, widths)

def lazy_width_problem(+body: BIR.Block, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match scan_block(body):
    case Scan{+width, +targets, +problem, leaves}:
      match problem:
        case Some{_}: problem
        case None{}: lazy_join_problem(join_targets(width, targets, widths))

def lazy_join_problem(+joined: Join) -> Maybe<&2, String>:
  match joined:
    case JoinConflict{}: Some{"a lazy value's exits disagree on return width"}
    case JoinWidth{+width}:
      match width:
        case Some{n}:
          match Nat.is_gt(n, 1n):
            case True{}: Some{"a lazy value cannot return a transport vector"}
            case False{}: None{}
        case None{}: None{}

# A declaration names a callable value: a posted symbol, a public key or the
# executable's root. All of them use the single-value convention, so a declared
# code may not return a vector. A lazy value is the same boundary for its body.
def check_declarations(+items: List<&2, BIR.Declaration>, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match items:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case BIR.LazyDeclaration{key, +body}: check_pair(lazy_width_problem(body, widths), check_pair(check_block(body, widths), check_declarations(rest, widths)))
        case BIR.FunctionDeclaration{key, +code, parameters}: check_pair(check_single_width(widths, code, "a declared function cannot return a transport vector"), check_declarations(rest, widths))
        case _: check_declarations(rest, widths)

def check_exports(+exports: List<&2, BIR.Export>, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match exports:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case BIR.Export{key, entry, parameter_types, result}: check_export(entry, rest, widths)

def check_export(+entry: Maybe<&2, BIR.Entry>, +rest: List<&2, BIR.Export>, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match entry:
    case Some{item}:
      match item:
        case BIR.Entry{+code, arity}: check_pair(check_single_width(widths, code, "an exported entry cannot return a transport vector"), check_exports(rest, widths))
    case None{}: check_exports(rest, widths)

def check_ending(+end: BIR.Ending, +widths: Map<&2, Nat>) -> Maybe<&2, String>:
  match end:
    case BIR.Library{exports}: check_exports(exports, widths)
    case _: None{}

def confirmed(+scans: List<&2, Summary>, +declarations: List<&2, BIR.Declaration>, +codes: List<&2, BIR.Code>, +end: BIR.Ending) -> WidthResult:
  match scan_problem(scans):
    case Some{message}: WidthsFail{message}
    case None{}: confirmed_scans(scans, declarations, codes, end)

def confirmed_scans(+scans: List<&2, Summary>, +declarations: List<&2, BIR.Declaration>, +codes: List<&2, BIR.Code>, +end: BIR.Ending) -> WidthResult:
  match solve(scans):
    case WidthsFail{message}: WidthsFail{message}
    case WidthsOk{widths}:
      match check_pair(check_codes(codes, widths), check_pair(check_declarations(declarations, widths), check_ending(end, widths))):
        case Some{message}: WidthsFail{message}
        case None{}: WidthsOk{widths}

def result_widths(program: BIR.Program) -> WidthResult:
  match program:
    case BIR.Program{+codes, +declarations, +constructors, +families, +type_functions, +end}:
      confirmed(scan_codes(codes, Nil{}), declarations, codes, end)

# ---------------------------------------------------------------------------
# Field, atom and op inspection
# ---------------------------------------------------------------------------

def atom_is(+atom: BIR.Atom, +id: U32) -> Bool:
  match atom:
    case BIR.Local{+known}: U32.is_eq(known, id)
    case _: False{}

def arg_is(+arg: BIR.Arg, +id: U32) -> Bool:
  match arg:
    case BIR.Arg{use, +value}: atom_is(value, id)

def args_is(+args: List<&2, BIR.Arg>, +id: U32) -> Bool:
  match args:
    case Nil{}: False{}
    case +arg <> rest: Bool.or(arg_is(arg, id), args_is(rest, id))

def values_is(+values: List<&2, BIR.Atom>, +id: U32) -> Bool:
  match values:
    case Nil{}: False{}
    case +value <> rest: Bool.or(atom_is(value, id), values_is(rest, id))

def fields_is(+fields: List<&2, BIR.Field>, +id: U32) -> Bool:
  match fields:
    case Nil{}: False{}
    case +field <> rest:
      match field:
        case BIR.Field{identity, key, use, +value}: Bool.or(atom_is(value, id), fields_is(rest, id))

def op_is(+op: BIR.Op, +id: U32) -> Bool:
  match op:
    case BIR.Copy{value}: atom_is(value, id)
    case BIR.PrimitiveCall{primitive, +args, types}: args_is(args, id)
    case BIR.Closure{code, +captures, parameters}: args_is(captures, id)
    case BIR.Direct{code, +args}: args_is(args, id)
    case BIR.Apply{+fn, +arg}: Bool.or(atom_is(fn, id), arg_is(arg, id))
    case BIR.Construct{constructor, tag, +fields}: fields_is(fields, id)
    case BIR.Project{+value, constructor, field, key}: atom_is(value, id)
    case BIR.HasTag{+value, constructor, tag}: atom_is(value, id)
    case _: False{}

def op_constructs(+op: BIR.Op) -> Nat:
  match op:
    case BIR.Construct{constructor, tag, fields}: 1n
    case _: 0n

# ---------------------------------------------------------------------------
# Producer eligibility
# ---------------------------------------------------------------------------

type Cand is Data:
  Cand{cid: U32, local: U32, fields: List<&2, BIR.Field>}

type ProduceScan is Data:
  ProduceScan{ok: Bool, constructs: Nat}

def find_construct(block: BIR.Block) -> Maybe<&2, Cand>:
  match block:
    case BIR.Let{+id, +op, +next}:
      match op:
        case BIR.Construct{+constructor, tag, +fields}: Some{Cand{constructor, id, fields}}
        case _: find_construct(next)
    case _: None{}

def produce_scan(block: BIR.Block, +local: U32, +ok: Bool, +constructs: Nat) -> ProduceScan:
  match block:
    case BIR.Return{value}: ProduceScan{Bool.and(ok, atom_is(value, local)), constructs}
    case BIR.ReturnValues{values}: ProduceScan{False{}, constructs}
    case BIR.TailDirect{code, args}: ProduceScan{False{}, constructs}
    case BIR.TailApply{fn, arg}: ProduceScan{False{}, constructs}
    case BIR.Let{+id, +op, +next}: produce_scan(next, local, Bool.and(ok, Bool.not(op_is(op, local))), Nat.add(constructs, op_constructs(op)))
    case BIR.LetValues{ids, code, +args, +next}: produce_scan(next, local, Bool.and(ok, Bool.not(args_is(args, local))), constructs)
    case BIR.Branch{+condition, +yes, +no}: produce_scan_branch(condition, yes, no, local, ok, constructs)
    case BIR.Region{label, +body, +next}: produce_scan_region(body, next, local, ok, constructs)
    case _: ProduceScan{ok, constructs}

def produce_scan_branch(+condition: BIR.Atom, +yes: BIR.Block, +no: BIR.Block, +local: U32, +ok: Bool, +constructs: Nat) -> ProduceScan:
  match produce_scan(yes, local, Bool.and(ok, Bool.not(atom_is(condition, local))), constructs):
    case ProduceScan{+lok, +ln}: produce_scan(no, local, lok, ln)

def produce_scan_region(+body: BIR.Block, +next: BIR.Block, +local: U32, +ok: Bool, +constructs: Nat) -> ProduceScan:
  match produce_scan(body, local, ok, constructs):
    case ProduceScan{+lok, +ln}: produce_scan(next, local, lok, ln)

def candidate_body(+body: BIR.Block) -> Maybe<&2, Cand>:
  match find_construct(body):
    case None{}: None{}
    case Some{+cand}:
      match cand:
        case Cand{+cid, +local, +fields}:
          match produce_scan(body, local, True{}, 0n):
            case ProduceScan{+ok, +constructs}:
              match Bool.and(Bool.and(ok, Nat.is_eq(constructs, 1n)), Bool.and(Nat.is_gt(List.length(&2, BIR.Field, fields), 0n), Nat.is_lt(List.length(&2, BIR.Field, fields), 8n))):
                case True{}: Some{cand}
                case False{}: None{}

def candidate_map(+codes: List<&2, BIR.Code>, +acc: Map<&2, Cand>) -> Map<&2, Cand>:
  match codes:
    case Nil{}: acc
    case +code <> rest:
      match code:
        case BIR.Code{+id, +captures, +parameters, +body}:
          match candidate_body(body):
            case Some{cand}: candidate_map(rest, Map.set(&2, Cand, acc, U32.show(id), cand))
            case None{}: candidate_map(rest, acc)

# ---------------------------------------------------------------------------
# Workers and plans
# ---------------------------------------------------------------------------

type Component is Data:
  Component{identity: U32, id: U32}

type Forward is Data:
  Forward{code: U32, index: U32}

type Expansion is Data:
  Expansion{worker: U32, cid: U32}

type Producer is Data:
  Producer{source: U32, cid: U32, worker: U32, fields: List<&2, BIR.Field>, code: BIR.Code}

type SiteIds is Data:
  SiteIds{rest: Fresh, ids: List<&2, U32>, comps: List<&2, Component>}

type Fresh is Data:
  Fresh{code: U32, local: U32}

def fresh_code(+fresh: Fresh) -> U32:
  match fresh:
    case Fresh{+code, _}: code

def fresh_local(+fresh: Fresh) -> U32:
  match fresh:
    case Fresh{_, +local}: local

# A saturated successor marks "the id space is exhausted" instead of wrapping:
# a wrapped id would collide with a live one, and a saturated counter is
# rejected by optimize_program before any generated program is returned.
def next_id(+id: U32) -> U32:
  match U32.is_eq(id, 4294967295):
    case True{}: id
    case False{}: U32.inc(id)

def bump_code1(+fresh: Fresh) -> Fresh:
  match fresh:
    case Fresh{+code, +local}: Fresh{next_id(code), local}

def bump_local1(+fresh: Fresh) -> Fresh:
  match fresh:
    case Fresh{+code, +local}: Fresh{code, next_id(local)}

def bump_code(+fresh: Fresh, +id: U32) -> Fresh:
  match fresh:
    case Fresh{+code, +local}:
      match U32.is_lt(id, code):
        case True{}: fresh
        case False{}: Fresh{next_id(id), local}

def bump_local(+fresh: Fresh, +id: U32) -> Fresh:
  match fresh:
    case Fresh{+code, +local}:
      match U32.is_lt(id, local):
        case True{}: fresh
        case False{}: Fresh{code, next_id(id)}

def block_bounds(+block: BIR.Block, +fresh: Fresh) -> Fresh:
  match block:
    case BIR.Return{+value}: atom_bounds(value, fresh)
    case BIR.ReturnValues{+values}: values_bounds(values, fresh)
    case BIR.Let{+id, +op, +next}: block_bounds(next, op_bounds(op, bump_local(fresh, id)))
    case BIR.LetValues{+ids, +code, args, +next}: block_bounds(next, ids_bounds(ids, args_bounds(args, bump_code(fresh, code))))
    case BIR.Branch{+condition, +yes, +no}: block_bounds(no, block_bounds(yes, atom_bounds(condition, fresh)))
    case BIR.Region{label, +body, +next}: block_bounds(next, block_bounds(body, fresh))
    case BIR.TailDirect{+code, +args}: args_bounds(args, bump_code(fresh, code))
    case BIR.TailApply{+fn, +arg}: arg_bounds(arg, atom_bounds(fn, fresh))
    case _: fresh

def atom_bounds(+atom: BIR.Atom, +fresh: Fresh) -> Fresh:
  match atom:
    case BIR.Local{+id}: bump_local(fresh, id)
    case _: fresh

def ids_bounds(+ids: List<&2, U32>, +fresh: Fresh) -> Fresh:
  match ids:
    case Nil{}: fresh
    case +id <> rest: ids_bounds(rest, bump_local(fresh, id))

def values_bounds(+values: List<&2, BIR.Atom>, +fresh: Fresh) -> Fresh:
  match values:
    case Nil{}: fresh
    case +value <> rest: values_bounds(rest, atom_bounds(value, fresh))

def arg_bounds(+arg: BIR.Arg, +fresh: Fresh) -> Fresh:
  match arg:
    case BIR.Arg{use, +value}: atom_bounds(value, fresh)

def args_bounds(+args: List<&2, BIR.Arg>, +fresh: Fresh) -> Fresh:
  match args:
    case Nil{}: fresh
    case +arg <> rest: args_bounds(rest, arg_bounds(arg, fresh))

def op_bounds(+op: BIR.Op, +fresh: Fresh) -> Fresh:
  match op:
    case BIR.Copy{value}: atom_bounds(value, fresh)
    case BIR.PrimitiveCall{primitive, +args, types}: args_bounds(args, fresh)
    case BIR.Closure{+code, +captures, parameters}: args_bounds(captures, bump_code(fresh, code))
    case BIR.Direct{+code, +args}: args_bounds(args, bump_code(fresh, code))
    case BIR.Apply{+fn, +arg}: arg_bounds(arg, atom_bounds(fn, fresh))
    case BIR.Construct{constructor, tag, +fields}: fields_bounds(fields, fresh)
    case BIR.Project{+value, constructor, field, key}: atom_bounds(value, fresh)
    case BIR.HasTag{+value, constructor, tag}: atom_bounds(value, fresh)
    case _: fresh

def fields_bounds(+fields: List<&2, BIR.Field>, +fresh: Fresh) -> Fresh:
  match fields:
    case Nil{}: fresh
    case +field <> rest:
      match field:
        case BIR.Field{identity, key, use, +value}: fields_bounds(rest, atom_bounds(value, fresh))

def params_bounds(+params: List<&2, BIR.Parameter>, +fresh: Fresh) -> Fresh:
  match params:
    case Nil{}: fresh
    case +param <> rest:
      match param:
        case BIR.Parameter{+id, use}: params_bounds(rest, bump_local(fresh, id))

def code_bounds(+code: BIR.Code, +fresh: Fresh) -> Fresh:
  match code:
    case BIR.Code{+id, +captures, +parameters, +body}: block_bounds(body, params_bounds(parameters, bump_code(fresh, id)))

def codes_bounds(+codes: List<&2, BIR.Code>, +fresh: Fresh) -> Fresh:
  match codes:
    case Nil{}: fresh
    case +code <> rest: codes_bounds(rest, code_bounds(code, fresh))

def declaration_bounds(+item: BIR.Declaration, +fresh: Fresh) -> Fresh:
  match item:
    case BIR.FunctionDeclaration{key, +code, +parameters}: params_bounds(parameters, bump_code(fresh, code))
    case BIR.LazyDeclaration{key, +body}: block_bounds(body, fresh)
    case _: fresh

def declarations_bounds(+items: List<&2, BIR.Declaration>, +fresh: Fresh) -> Fresh:
  match items:
    case Nil{}: fresh
    case +item <> rest: declarations_bounds(rest, declaration_bounds(item, fresh))

def export_bounds(+item: BIR.Export, +fresh: Fresh) -> Fresh:
  match item:
    case BIR.Export{key, +entry, parameter_types, result}: entry_bounds(entry, fresh)

def entry_bounds(+entry: Maybe<&2, BIR.Entry>, +fresh: Fresh) -> Fresh:
  match entry:
    case Some{item}:
      match item:
        case BIR.Entry{+code, arity}: bump_code(fresh, code)
    case None{}: fresh

def exports_bounds(+items: List<&2, BIR.Export>, +fresh: Fresh) -> Fresh:
  match items:
    case Nil{}: fresh
    case +item <> rest: exports_bounds(rest, export_bounds(item, fresh))

def ending_bounds(+end: BIR.Ending, +fresh: Fresh) -> Fresh:
  match end:
    case BIR.Library{+exports}: exports_bounds(exports, fresh)
    case _: fresh

def program_bounds(+codes: List<&2, BIR.Code>, +declarations: List<&2, BIR.Declaration>, +end: BIR.Ending) -> Fresh:
  ending_bounds(end, declarations_bounds(declarations, codes_bounds(codes, Fresh{0, 0})))

def code_map(+codes: List<&2, BIR.Code>, +acc: Map<&2, BIR.Code>) -> Map<&2, BIR.Code>:
  match codes:
    case Nil{}: acc
    case +code <> rest:
      match code:
        case BIR.Code{+id, +captures, +parameters, +body}: code_map(rest, Map.set(&2, BIR.Code, acc, U32.show(id), code))

# ---------------------------------------------------------------------------
# Worker bodies
# ---------------------------------------------------------------------------

def field_identities(+fields: List<&2, BIR.Field>, +acc: List<&2, U32>) -> List<&2, U32>:
  match fields:
    case Nil{}: List.reverse(&2, U32, acc)
    case +field <> rest:
      match field:
        case BIR.Field{+identity, key, use, value}: field_identities(rest, identity <> acc)

type CompsBuilt is Data:
  CompsBuilt{rest: Fresh, comps: List<&2, Component>, params: List<&2, BIR.Parameter>}

# Every field gets one fresh local, in field order. The field atom is bound by
# `Copy` at the construct position, so a lazy symbol is still read exactly once,
# in the original order, and the vector only carries plain locals.
def field_comps(+fields: List<&2, BIR.Field>, +fresh: Fresh, +comps: List<&2, Component>, +params: List<&2, BIR.Parameter>) -> CompsBuilt:
  match fields:
    case Nil{}: CompsBuilt{fresh, List.reverse(&2, Component, comps), List.reverse(&2, BIR.Parameter, params)}
    case +field <> rest:
      match field:
        case BIR.Field{+identity, key, use, value}:
          +id = fresh_local(fresh)
          field_comps(rest, bump_local1(fresh), Component{identity, id} <> comps, BIR.Parameter{id, BIR.Many{}} <> params)

def component_locals(+comps: List<&2, Component>, +acc: List<&2, BIR.Atom>) -> List<&2, BIR.Atom>:
  match comps:
    case Nil{}: List.reverse(&2, BIR.Atom, acc)
    case +comp <> rest:
      match comp:
        case Component{identity, +id}: component_locals(rest, BIR.Local{id} <> acc)

def field_args(+comps: List<&2, Component>, +acc: List<&2, BIR.Arg>) -> List<&2, BIR.Arg>:
  match comps:
    case Nil{}: List.reverse(&2, BIR.Arg, acc)
    case +comp <> rest:
      match comp:
        case Component{identity, +id}: field_args(rest, BIR.Arg{BIR.Many{}, BIR.Local{id}} <> acc)

def component_args(+cid: U32, +comps: List<&2, Component>) -> List<&2, BIR.Arg>:
  BIR.Arg{BIR.Affine{}, BIR.Word{cid}} <> field_args(comps, Nil{})

def copy_fields(+comps: List<&2, Component>, +fields: List<&2, BIR.Field>, +next: BIR.Block) -> BIR.Block:
  match comps:
    case Nil{}: next
    case +comp <> crest:
      match fields:
        case Nil{}: next
        case +field <> frest:
          match comp:
            case Component{identity, +id}:
              match field:
                case BIR.Field{fid, key, fuse, +value}: BIR.Let{id, BIR.Copy{value}, copy_fields(crest, frest, next)}

def worker_return(+value: BIR.Atom, +local: U32, +cid: U32, +comps: List<&2, Component>) -> BIR.Block:
  match atom_is(value, local):
    case True{}: BIR.ReturnValues{BIR.Word{cid} <> component_locals(comps, Nil{})}
    case False{}: BIR.Return{value}

def worker_body(+block: BIR.Block, +local: U32, +cid: U32, +comps: List<&2, Component>) -> BIR.Block:
  match block:
    case BIR.Let{+id, +op, +next}:
      match op:
        case BIR.Construct{constructor, tag, fields}:
          match U32.is_eq(id, local):
            case True{}: copy_fields(comps, fields, worker_body(next, local, cid, comps))
            case False{}: BIR.Let{id, op, worker_body(next, local, cid, comps)}
        case _: BIR.Let{id, op, worker_body(next, local, cid, comps)}
    case BIR.Return{+value}: worker_return(value, local, cid, comps)
    case BIR.LetValues{+ids, +code, +args, +next}: BIR.LetValues{ids, code, args, worker_body(next, local, cid, comps)}
    case BIR.Branch{+condition, +yes, +no}: BIR.Branch{condition, worker_body(yes, local, cid, comps), worker_body(no, local, cid, comps)}
    case BIR.Region{+label, +body, +next}: BIR.Region{label, worker_body(body, local, cid, comps), worker_body(next, local, cid, comps)}
    case _: block

# ---------------------------------------------------------------------------
# Alpha-renaming cloned bodies
# ---------------------------------------------------------------------------
#
# A cloned body may not reuse the source code's parameter or binding ids:
# continuation and segment names are derived from those ids program-wide in
# both renderers, so an original body and its worker would collide. Every
# cloned parameter, `Let` binding and `LetValues` binding gets a fresh id, every
# local reference follows it, and every region label gets a fresh label so the
# same invariant holds there too. Capture slots stay positional, constructor
# field identities, symbol ids and code ids are not locals and stay untouched,
# and a closure's declared parameter list belongs to the callee, not this body.

type Ren is Data:
  Ren{block: BIR.Block, rest: Fresh, mapping: Map<&2, U32>, labels: Map<&2, U32>}

type RenParams is Data:
  RenParams{params: List<&2, BIR.Parameter>, rest: Fresh, mapping: Map<&2, U32>}

type RenIds is Data:
  RenIds{ids: List<&2, U32>, rest: Fresh, mapping: Map<&2, U32>}

def renamed_id(+mapping: Map<&2, U32>, +id: U32) -> U32:
  match IndexLookup.find(U32, mapping, U32.show(id)):
    case Some{value}: value
    case None{}: id

def mapped_add(+mapping: Map<&2, U32>, +id: U32, +value: U32) -> Map<&2, U32>:
  Map.set(&2, U32, mapping, U32.show(id), value)

def rename_atom(+atom: BIR.Atom, +mapping: Map<&2, U32>) -> BIR.Atom:
  match atom:
    case BIR.Local{+id}: BIR.Local{renamed_id(mapping, id)}
    case _: atom

def rename_arg(+arg: BIR.Arg, +mapping: Map<&2, U32>) -> BIR.Arg:
  match arg:
    case BIR.Arg{+use, +value}: BIR.Arg{use, rename_atom(value, mapping)}

def rename_args(+args: List<&2, BIR.Arg>, +mapping: Map<&2, U32>, +acc: List<&2, BIR.Arg>) -> List<&2, BIR.Arg>:
  match args:
    case Nil{}: List.reverse(&2, BIR.Arg, acc)
    case +arg <> rest: rename_args(rest, mapping, rename_arg(arg, mapping) <> acc)

def rename_values(+values: List<&2, BIR.Atom>, +mapping: Map<&2, U32>, +acc: List<&2, BIR.Atom>) -> List<&2, BIR.Atom>:
  match values:
    case Nil{}: List.reverse(&2, BIR.Atom, acc)
    case +value <> rest: rename_values(rest, mapping, rename_atom(value, mapping) <> acc)

def rename_fields(+fields: List<&2, BIR.Field>, +mapping: Map<&2, U32>, +acc: List<&2, BIR.Field>) -> List<&2, BIR.Field>:
  match fields:
    case Nil{}: List.reverse(&2, BIR.Field, acc)
    case +field <> rest:
      match field:
        case BIR.Field{+identity, +key, +use, +value}: rename_fields(rest, mapping, BIR.Field{identity, key, use, rename_atom(value, mapping)} <> acc)

def rename_op(+op: BIR.Op, +mapping: Map<&2, U32>) -> BIR.Op:
  match op:
    case BIR.Copy{+value}: BIR.Copy{rename_atom(value, mapping)}
    case BIR.PrimitiveCall{+primitive, +args, +types}: BIR.PrimitiveCall{primitive, rename_args(args, mapping, Nil{}), types}
    case BIR.Closure{+code, +captures, +parameters}: BIR.Closure{code, rename_args(captures, mapping, Nil{}), parameters}
    case BIR.Direct{+code, +args}: BIR.Direct{code, rename_args(args, mapping, Nil{})}
    case BIR.Apply{+fn, +arg}: BIR.Apply{rename_atom(fn, mapping), rename_arg(arg, mapping)}
    case BIR.LoadSymbol{+id, +key}: op
    case BIR.Construct{+constructor, +tag, +fields}: BIR.Construct{constructor, tag, rename_fields(fields, mapping, Nil{})}
    case BIR.Project{+value, +constructor, +field, +key}: BIR.Project{rename_atom(value, mapping), constructor, field, key}
    case BIR.HasTag{+value, +constructor, +tag}: BIR.HasTag{rename_atom(value, mapping), constructor, tag}

def rename_ids(+ids: List<&2, U32>, +fresh: Fresh, +mapping: Map<&2, U32>, +acc: List<&2, U32>) -> RenIds:
  match ids:
    case Nil{}: RenIds{List.reverse(&2, U32, acc), fresh, mapping}
    case +id <> rest:
      +new = fresh_local(fresh)
      rename_ids(rest, bump_local1(fresh), mapped_add(mapping, id, new), new <> acc)

def rename_params(+params: List<&2, BIR.Parameter>, +fresh: Fresh, +mapping: Map<&2, U32>) -> RenParams:
  match params:
    case Nil{}: RenParams{Nil{}, fresh, mapping}
    case +param <> rest:
      match param:
        case BIR.Parameter{+id, +use}:
          +new = fresh_local(fresh)
          match rename_params(rest, bump_local1(fresh), mapped_add(mapping, id, new)):
            case RenParams{renamed, f1, m1}: RenParams{BIR.Parameter{new, use} <> renamed, f1, m1}

def rename_block(+block: BIR.Block, +fresh: Fresh, +mapping: Map<&2, U32>, +labels: Map<&2, U32>) -> Ren:
  match block:
    case BIR.Return{+value}: Ren{BIR.Return{rename_atom(value, mapping)}, fresh, mapping, labels}
    case BIR.ReturnValues{+values}: Ren{BIR.ReturnValues{rename_values(values, mapping, Nil{})}, fresh, mapping, labels}
    case BIR.Let{+id, +op, +next}:
      +new = fresh_local(fresh)
      match rename_block(next, bump_local1(fresh), mapped_add(mapping, id, new), labels):
        case Ren{inner, f1, m1, l1}: Ren{BIR.Let{new, rename_op(op, mapping), inner}, f1, m1, l1}
    case BIR.LetValues{+ids, +code, +args, +next}:
      +new_args = rename_args(args, mapping, Nil{})
      match rename_ids(ids, fresh, mapping, Nil{}):
        case RenIds{new_ids, f1, m1}:
          match rename_block(next, f1, m1, labels):
            case Ren{inner, f2, m2, l2}: Ren{BIR.LetValues{new_ids, code, new_args, inner}, f2, m2, l2}
    case BIR.Branch{+condition, +yes, +no}:
      +head = rename_atom(condition, mapping)
      match rename_block(yes, fresh, mapping, labels):
        case Ren{yb, f1, m1, l1}:
          match rename_block(no, f1, m1, l1):
            case Ren{nb, f2, m2, l2}: Ren{BIR.Branch{head, yb, nb}, f2, m2, l2}
    case BIR.Region{+label, +body, +next}:
      +new_label = fresh_local(fresh)
      match rename_block(body, bump_local1(fresh), mapping, mapped_add(labels, label, new_label)):
        case Ren{bb, f1, m1, l1}:
          match rename_block(next, f1, m1, labels):
            case Ren{nb, f2, m2, l2}: Ren{BIR.Region{new_label, bb, nb}, f2, m2, l2}
    case BIR.LeaveRegion{+label}: Ren{BIR.LeaveRegion{renamed_id(labels, label)}, fresh, mapping, labels}
    case BIR.TailDirect{+code, +args}: Ren{BIR.TailDirect{code, rename_args(args, mapping, Nil{})}, fresh, mapping, labels}
    case BIR.TailApply{+fn, +arg}: Ren{BIR.TailApply{rename_atom(fn, mapping), rename_arg(arg, mapping)}, fresh, mapping, labels}
    case _: Ren{block, fresh, mapping, labels}

# ---------------------------------------------------------------------------
# Use-site walking
# ---------------------------------------------------------------------------

type Wctx is Data:
  Wctx{target: U32, cid: U32, identities: List<&2, U32>, comps: List<&2, Component>, real: Bool, expansions: Map<&2, Expansion>}

type Wstate is Data:
  Wstate{used: Bool, forward: Maybe<&2, Forward>, forwards: Nat, bad: Bool}

type Wresult is Data:
  Wresult{block: BIR.Block, state: Wstate}

type ArgScan is Data:
  ArgScan{count: Nat, at: U32}

def w_idle() -> Wstate:
  Wstate{False{}, None{}, 0n, False{}}

def w_used(+st: Wstate) -> Wstate:
  match st:
    case Wstate{+used, +forward, +forwards, +bad}: Wstate{True{}, forward, forwards, bad}

def w_bad(+st: Wstate) -> Wstate:
  match st:
    case Wstate{+used, +forward, +forwards, +bad}: Wstate{used, forward, forwards, True{}}

def w_mention(+st: Wstate, +f: Forward, +consumed: Bool) -> Wstate:
  match st:
    case Wstate{+used, +forward, +forwards, +bad}:
      match Nat.is_eq(forwards, 0n):
        case False{}: Wstate{used, forward, forwards, True{}}
        case True{}:
          match consumed:
            case True{}: Wstate{True{}, None{}, 1n, bad}
            case False{}: Wstate{True{}, Some{f}, 1n, bad}

def forward_none(+f: Maybe<&2, Forward>) -> Bool:
  match f:
    case None{}: True{}
    case Some{_}: False{}

def site_ok(+st: Wstate) -> Bool:
  match st:
    case Wstate{+used, +forward, +forwards, +bad}: Bool.and(Bool.and(Bool.not(bad), used), forward_none(forward))

def walk_leaf(+block: BIR.Block, +mentions: Bool, +st: Wstate) -> Wresult:
  match mentions:
    case True{}: Wresult{block, w_bad(st)}
    case False{}: Wresult{block, st}

def walk_block(+block: BIR.Block, +ctx: Wctx, +st: Wstate) -> Wresult:
  match st:
    case Wstate{+used, +forward, +forwards, +bad}:
      match bad:
        case True{}: Wresult{block, st}
        case False{}: walk_kind(block, ctx, st)

def walk_kind(+block: BIR.Block, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match block:
        case BIR.Return{value}: walk_leaf(block, atom_is(value, target), st)
        case BIR.ReturnValues{values}: walk_leaf(block, values_is(values, target), st)
        case BIR.TailApply{fn, arg}: walk_leaf(block, Bool.or(atom_is(fn, target), arg_is(arg, target)), st)
        case BIR.Let{id, op, next}: walk_let(block, id, op, next, ctx, st)
        case BIR.LetValues{ids, code, args, next}: walk_let_values(block, ids, code, args, next, target, ctx, st)
        case BIR.Branch{condition, yes, no}: walk_branch(condition, yes, no, target, ctx, st)
        case BIR.Region{label, body, next}: walk_region(label, body, next, ctx, st)
        case BIR.TailDirect{code, args}: walk_tail(block, code, args, ctx, st)
        case _: Wresult{block, st}

def walk_let(+block: BIR.Block, +id: U32, +op: BIR.Op, +next: BIR.Block, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match op:
        case BIR.Project{value, constructor, field, key}: walk_project(id, value, constructor, field, key, next, ctx, st)
        case BIR.HasTag{value, constructor, tag}: walk_tag(id, value, constructor, tag, next, ctx, st)
        case BIR.Direct{code, args}: walk_direct(id, code, args, next, ctx, st)
        case _: walk_op(id, op, next, target, ctx, st)

def walk_op(+id: U32, +op: BIR.Op, +next: BIR.Block, +target: U32, +ctx: Wctx, +st: Wstate) -> Wresult:
  match op_is(op, target):
    case True{}: Wresult{BIR.Let{id, op, next}, w_bad(st)}
    case False{}:
      match walk_block(next, ctx, st):
        case Wresult{block, state}: Wresult{BIR.Let{id, op, block}, state}

def walk_project(+id: U32, +value: BIR.Atom, +constructor: U32, +field: U32, +key: String, +next: BIR.Block, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match atom_is(value, target):
        case False{}: walk_op(id, BIR.Project{value, constructor, field, key}, next, target, ctx, st)
        case True{}:
          match U32.is_eq(constructor, cid):
            case False{}: Wresult{BIR.Let{id, BIR.Project{value, constructor, field, key}, next}, w_bad(st)}
            case True{}:
              match index_of(identities, field, 0n):
                case None{}: Wresult{BIR.Let{id, BIR.Project{value, constructor, field, key}, next}, w_bad(st)}
                case Some{position}: walk_project_at(id, value, constructor, field, key, next, position, comps, real, ctx, st)

def walk_project_at(+id: U32, +value: BIR.Atom, +constructor: U32, +field: U32, +key: String, +next: BIR.Block, +position: Nat, +comps: List<&2, Component>, +real: Bool, +ctx: Wctx, +st: Wstate) -> Wresult:
  match real:
    case False{}:
      match walk_block(next, ctx, w_used(st)):
        case Wresult{block, state}: Wresult{BIR.Let{id, BIR.Project{value, constructor, field, key}, block}, state}
    case True{}:
      match component_at(comps, position):
        case None{}: Wresult{BIR.Let{id, BIR.Project{value, constructor, field, key}, next}, w_bad(st)}
        case Some{comp}:
          match comp:
            case Component{identity, component}:
              match walk_block(next, ctx, w_used(st)):
                case Wresult{block, state}: Wresult{BIR.Let{id, BIR.Copy{BIR.Local{component}}, block}, state}

def walk_tag(+id: U32, +value: BIR.Atom, +constructor: U32, +tag: String, +next: BIR.Block, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match atom_is(value, target):
        case False{}: walk_op(id, BIR.HasTag{value, constructor, tag}, next, target, ctx, st)
        case True{}:
          match U32.is_eq(constructor, cid):
            case False{}: Wresult{BIR.Let{id, BIR.HasTag{value, constructor, tag}, next}, w_bad(st)}
            case True{}:
              match walk_block(next, ctx, w_used(st)):
                case Wresult{block, state}:
                  match real:
                    case True{}: Wresult{BIR.Let{id, BIR.Copy{BIR.Boolean{True{}}}, block}, state}
                    case False{}: Wresult{BIR.Let{id, BIR.HasTag{value, constructor, tag}, block}, state}

def walk_let_values(+block: BIR.Block, +ids: List<&2, U32>, +code: U32, +args: List<&2, BIR.Arg>, +next: BIR.Block, +target: U32, +ctx: Wctx, +st: Wstate) -> Wresult:
  match args_is(args, target):
    case True{}: Wresult{block, w_bad(st)}
    case False{}:
      match walk_block(next, ctx, st):
        case Wresult{inner, state}: Wresult{BIR.LetValues{ids, code, args, inner}, state}

def walk_branch(+condition: BIR.Atom, +yes: BIR.Block, +no: BIR.Block, +target: U32, +ctx: Wctx, +st: Wstate) -> Wresult:
  match atom_is(condition, target):
    case True{}: Wresult{BIR.Branch{condition, yes, no}, w_bad(st)}
    case False{}:
      match walk_block(yes, ctx, st):
        case Wresult{yb, ys}:
          match walk_block(no, ctx, ys):
            case Wresult{nb, ns}: Wresult{BIR.Branch{condition, yb, nb}, ns}

def walk_region(+label: U32, +body: BIR.Block, +next: BIR.Block, +ctx: Wctx, +st: Wstate) -> Wresult:
  match walk_block(body, ctx, st):
    case Wresult{bb, bs}:
      match walk_block(next, ctx, bs):
        case Wresult{nb, ns}: Wresult{BIR.Region{label, bb, nb}, ns}

def walk_direct(+id: U32, +code: U32, +args: List<&2, BIR.Arg>, +next: BIR.Block, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match args_scan(args, target, 0, 0n, 0):
        case ArgScan{+count, +at}:
          match Nat.is_eq(count, 0n):
            case True{}: walk_op(id, BIR.Direct{code, args}, next, target, ctx, st)
            case False{}: walk_call(BIR.Direct{code, args}, id, code, args, next, at, count, ctx, st)

def walk_tail(+block: BIR.Block, +code: U32, +args: List<&2, BIR.Arg>, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match args_scan(args, target, 0, 0n, 0):
        case ArgScan{+count, +at}:
          match Nat.is_eq(count, 0n):
            case True{}: Wresult{block, st}
            case False{}: walk_tail_call(block, code, args, at, count, ctx, st)

# One call site may consume the aggregate through a single argument, exactly
# once. The callee is swapped only for a registered consumer worker whose
# constructor agrees; otherwise the site keeps the original boxed argument and
# the producer/consumer pair is simply not optimized.
def walk_call(+op: BIR.Op, +id: U32, +code: U32, +args: List<&2, BIR.Arg>, +next: BIR.Block, +at: U32, +count: Nat, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match Nat.is_gt(count, 1n):
        case True{}: Wresult{BIR.Let{id, op, next}, w_bad(st)}
        case False{}: walk_call_one(op, id, code, args, next, at, ctx, st)

def walk_call_one(+op: BIR.Op, +id: U32, +code: U32, +args: List<&2, BIR.Arg>, +next: BIR.Block, +at: U32, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match real:
        case False{}: walk_call_keep(op, id, code, args, next, at, ctx, st)
        case True{}:
          match expansion_at(expansions, code, at, cid):
            case None{}: walk_call_keep(op, id, code, args, next, at, ctx, st)
            case Some{expansion}:
              match expansion:
                case Expansion{+worker, ecid}:
                  +newargs = List.append(&2, BIR.Arg, drop_arg(args, U32.to_nat(at)), component_args(cid, comps))
                  match walk_block(next, ctx, w_used(st)):
                    case Wresult{block, state}: Wresult{BIR.Let{id, BIR.Direct{worker, newargs}, block}, state}

def walk_call_keep(+op: BIR.Op, +id: U32, +code: U32, +args: List<&2, BIR.Arg>, +next: BIR.Block, +at: U32, +ctx: Wctx, +st: Wstate) -> Wresult:
  match walk_block(next, ctx, w_mention(st, Forward{code, at}, False{})):
    case Wresult{block, state}: Wresult{BIR.Let{id, op, block}, state}

def walk_tail_call(+block: BIR.Block, +code: U32, +args: List<&2, BIR.Arg>, +at: U32, +count: Nat, +ctx: Wctx, +st: Wstate) -> Wresult:
  match ctx:
    case Wctx{+target, +cid, +identities, +comps, +real, +expansions}:
      match Nat.is_gt(count, 1n):
        case True{}: Wresult{block, w_bad(st)}
        case False{}:
          match real:
            case False{}: Wresult{block, w_mention(st, Forward{code, at}, False{})}
            case True{}:
              match expansion_at(expansions, code, at, cid):
                case None{}: Wresult{block, w_mention(st, Forward{code, at}, False{})}
                case Some{expansion}:
                  match expansion:
                    case Expansion{+worker, ecid}:
                      +newargs = List.append(&2, BIR.Arg, drop_arg(args, U32.to_nat(at)), component_args(cid, comps))
                      Wresult{BIR.TailDirect{worker, newargs}, w_used(st)}

def site_dry(+next: BIR.Block, +id: U32, +cand: Cand) -> Wstate:
  match cand:
    case Cand{+cid, +local, +fields}:
      match walk_block(next, Wctx{id, cid, field_identities(fields, Nil{}), Nil{}, False{}, Map.new(&2, Expansion)}, w_idle()):
        case Wresult{block, state}: state

def site_real(+next: BIR.Block, +id: U32, +cid: U32, +identities: List<&2, U32>, +comps: List<&2, Component>, +expansions: Map<&2, Expansion>) -> Wresult:
  walk_block(next, Wctx{id, cid, identities, comps, True{}, expansions}, w_idle())

# ---------------------------------------------------------------------------
# Small list and key helpers
# ---------------------------------------------------------------------------

def index_of(+items: List<&2, U32>, +value: U32, +position: Nat) -> Maybe<&2, Nat>:
  match items:
    case Nil{}: None{}
    case +item <> rest:
      match U32.is_eq(item, value):
        case True{}: Some{position}
        case False{}: index_of(rest, value, Nat.add(position, 1n))

def component_at(+comps: List<&2, Component>, +position: Nat) -> Maybe<&2, Component>:
  match comps:
    case Nil{}: None{}
    case +comp <> rest:
      match Nat.is_eq(position, 0n):
        case True{}: Some{comp}
        case False{}: component_at(rest, Nat.sub(position, 1n))

def nth_param(+items: List<&2, BIR.Parameter>, +position: Nat) -> Maybe<&2, BIR.Parameter>:
  match items position:
    case Nil{} _: None{}
    case +item <> _ 0n: Some{item}
    case _ <> rest 1n+rest_index: nth_param(rest, rest_index)

def drop_param(+items: List<&2, BIR.Parameter>, +position: Nat) -> List<&2, BIR.Parameter>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest:
      match Nat.is_eq(position, 0n):
        case True{}: rest
        case False{}: item <> drop_param(rest, Nat.sub(position, 1n))

def drop_arg(+items: List<&2, BIR.Arg>, +position: Nat) -> List<&2, BIR.Arg>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest:
      match Nat.is_eq(position, 0n):
        case True{}: rest
        case False{}: item <> drop_arg(rest, Nat.sub(position, 1n))

def args_scan(+args: List<&2, BIR.Arg>, +target: U32, +at: U32, +count: Nat, +first: U32) -> ArgScan:
  match args:
    case Nil{}: ArgScan{count, first}
    case +arg <> rest:
      match arg_is(arg, target):
        case True{}: args_scan(rest, target, U32.inc(at), Nat.add(count, 1n), at)
        case False{}: args_scan(rest, target, U32.inc(at), count, first)

def expansion_key(+code: U32, +at: U32) -> String:
  String.append(U32.show(code), String.append(":", U32.show(at)))

def expansion_at(+expansions: Map<&2, Expansion>, +code: U32, +at: U32, +cid: U32) -> Maybe<&2, Expansion>:
  match IndexLookup.find(Expansion, expansions, expansion_key(code, at)):
    case None{}: None{}
    case Some{+expansion}:
      match expansion:
        case Expansion{worker, ecid}:
          match U32.is_eq(ecid, cid):
            case True{}: Some{expansion}
            case False{}: None{}

def cand_cid(+cand: Cand) -> U32:
  match cand:
    case Cand{+cid, local, fields}: cid

def code_id(+code: BIR.Code) -> U32:
  match code:
    case BIR.Code{+id, captures, parameters, body}: id

def site_ids(+fresh: Fresh, +fields: List<&2, BIR.Field>) -> SiteIds:
  +disc = fresh_local(fresh)
  match field_comps(fields, bump_local1(fresh), Nil{}, Nil{}):
    case CompsBuilt{rest, +comps, +params}: SiteIds{rest, disc <> comp_ids(comps, Nil{}), comps}

def comp_ids(+comps: List<&2, Component>, +acc: List<&2, U32>) -> List<&2, U32>:
  match comps:
    case Nil{}: List.reverse(&2, U32, acc)
    case +comp <> rest:
      match comp:
        case Component{identity, +id}: comp_ids(rest, id <> acc)



# ---------------------------------------------------------------------------
# Program plans
# ---------------------------------------------------------------------------

type Plan is Data:
  Plan{fresh: Fresh, producers: Map<&2, Producer>, order: List<&2, U32>, expansions: Map<&2, Expansion>, consumers: List<&2, BIR.Code>}

type ConsumerBuilt is Data:
  ConsumerBuilt{rest: Fresh, worker: BIR.Code}

def plan_fresh(+plan: Plan) -> Fresh:
  match plan:
    case Plan{+fresh, _, _, _, _}: fresh

def plan_producers(+plan: Plan) -> Map<&2, Producer>:
  match plan:
    case Plan{_, +producers, _, _, _}: producers

def plan_order(+plan: Plan) -> List<&2, U32>:
  match plan:
    case Plan{_, _, +order, _, _}: order

def plan_expansions(+plan: Plan) -> Map<&2, Expansion>:
  match plan:
    case Plan{_, _, _, +expansions, _}: expansions

def plan_consumers(+plan: Plan) -> List<&2, BIR.Code>:
  match plan:
    case Plan{_, _, _, _, +consumers}: consumers

# `rest` is the supply after the worker's code id and every staged/renamed local
# id were taken; keeping the old supply here would hand the next producer the
# same worker code id.
def plan_add_producer(+plan: Plan, +rest: Fresh, +source: U32, +producer: Producer) -> Plan:
  match plan:
    case Plan{fresh, producers, order, expansions, consumers}:
      Plan{rest, Map.set(&2, Producer, producers, U32.show(source), producer), List.append(&2, U32, order, [source]), expansions, consumers}

def plan_add_consumer(+plan: Plan, +rest: Fresh, +key: String, +expansion: Expansion, +consumer: BIR.Code) -> Plan:
  match plan:
    case Plan{_, producers, order, expansions, consumers}:
      Plan{rest, producers, order, Map.set(&2, Expansion, expansions, key, expansion), List.append(&2, BIR.Code, consumers, [consumer])}

type ProducerBuilt is Data:
  ProducerBuilt{rest: Fresh, code: BIR.Code}

# A producer worker is cloned once per eligible producer, never per call site.
# The clone's parameters and bindings are alpha-renamed first, so the worker
# and the original never emit the same local/continuation id.
def ensure_producer(+source: U32, +cand: Cand, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match IndexLookup.find(Producer, plan_producers(plan), U32.show(source)):
    case Some{_}: plan
    case None{}:
      match IndexLookup.find(BIR.Code, codes_map, U32.show(source)):
        case None{}: plan
        case Some{source_code}:
          match cand:
            case Cand{+cid, +local, +fields}:
              +base = plan_fresh(plan)
              +worker = fresh_code(base)
              match producer_build(source_code, worker, local, cid, fields, bump_code1(base)):
                case ProducerBuilt{rest, built_code}:
                  plan_add_producer(plan, rest, source, Producer{source, cid, worker, fields, built_code})

def producer_build(+source: BIR.Code, +worker: U32, +local: U32, +cid: U32, +fields: List<&2, BIR.Field>, +fresh: Fresh) -> ProducerBuilt:
  match source:
    case BIR.Code{code, +captures, +parameters, +body}:
      match rename_params(parameters, fresh, Map.new(&2, U32)):
        case RenParams{params, f1, m1}:
          match rename_block(body, f1, m1, Map.new(&2, U32)):
            case Ren{renamed, f2, all, labelmap}:
              match field_comps(fields, f2, Nil{}, Nil{}):
                case CompsBuilt{f3, comps, comp_params}:
                  ProducerBuilt{f3, BIR.Code{worker, captures, params, worker_body(renamed, renamed_id(all, local), cid, comps)}}

# A consumer worker is cloned at most once per (callee, argument position).
# Its parameters and bindings are alpha-renamed before the substitution walk, so
# the substitution matches the renamed parameter and the clone never reuses the
# callee's ids. The walk must consume the parameter: a recorded (unconsumed)
# forward would leave a dropped parameter referenced, so it is rejected here.
def consumer_make(+source: BIR.Code, +position: Nat, +cid: U32, +identities: List<&2, U32>, +fields: List<&2, BIR.Field>, +fresh: Fresh) -> Maybe<&2, ConsumerBuilt>:
  match source:
    case BIR.Code{code, +captures, +parameters, +body}:
      match nth_param(parameters, position):
        case None{}: None{}
        case Some{param}:
          match param:
            case BIR.Parameter{+target, use}:
              +disc = fresh_local(fresh)
              match field_comps(fields, bump_local1(fresh), Nil{}, Nil{}):
                case CompsBuilt{f1, comps, comp_params}:
                  match rename_params(parameters, f1, Map.new(&2, U32)):
                    case RenParams{params, f2, m1}:
                      match rename_block(body, f2, m1, Map.new(&2, U32)):
                        case Ren{renamed, f3, all, labelmap}:
                          +moved = renamed_id(all, target)
                          match walk_block(renamed, Wctx{moved, cid, identities, comps, True{}, Map.new(&2, Expansion)}, w_idle()):
                            case Wresult{worker_body_block, state}:
                              match state:
                                case Wstate{used, forward, forwards, bad}:
                                  match Bool.and(Bool.and(Bool.not(bad), used), forward_none(forward)):
                                    case False{}: None{}
                                    case True{}: consumer_built(captures, params, position, disc, comp_params, worker_body_block, f3)

def consumer_built(+captures: List<&2, BIR.Use>, +parameters: List<&2, BIR.Parameter>, +position: Nat, +disc: U32, +params: List<&2, BIR.Parameter>, +body: BIR.Block, +fresh: Fresh) -> Maybe<&2, ConsumerBuilt>:
  +worker = fresh_code(fresh)
  +declared = List.append(&2, BIR.Parameter, drop_param(parameters, position), BIR.Parameter{disc, BIR.Affine{}} <> params)
  Some{ConsumerBuilt{bump_code1(fresh), BIR.Code{worker, captures, declared, body}}}

def plan_block(+block: BIR.Block, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match block:
    case BIR.Let{+id, +op, +next}:
      match op:
        case BIR.Direct{+code, +args}: plan_direct(id, code, next, candidates, codes_map, plan)
        case _: plan_block(next, candidates, codes_map, plan)
    case BIR.LetValues{ids, code, args, +next}: plan_block(next, candidates, codes_map, plan)
    case BIR.Branch{condition, +yes, +no}: plan_block(no, candidates, codes_map, plan_block(yes, candidates, codes_map, plan))
    case BIR.Region{label, +body, +next}: plan_block(next, candidates, codes_map, plan_block(body, candidates, codes_map, plan))
    case _: plan

def plan_direct(+id: U32, +code: U32, +next: BIR.Block, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match IndexLookup.find(Cand, candidates, U32.show(code)):
    case None{}: plan_block(next, candidates, codes_map, plan)
    case Some{+cand}:
      match site_dry(next, id, cand):
        case Wstate{used, forward, forwards, bad}:
          match bad:
            case True{}: plan_block(next, candidates, codes_map, plan)
            case False{}:
              match used:
                case False{}: plan_block(next, candidates, codes_map, plan)
                case True{}:
                  match forward:
                    case None{}: plan_block(next, candidates, codes_map, ensure_producer(code, cand, codes_map, plan))
                    case Some{f}: plan_forward(f, code, cand, next, candidates, codes_map, plan)

def plan_forward(+f: Forward, +producer_code: U32, +cand: Cand, +next: BIR.Block, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match f:
    case Forward{hcode, at}:
      +key = expansion_key(hcode, at)
      match IndexLookup.find(Expansion, plan_expansions(plan), key):
        case Some{expansion}:
          match expansion:
            case Expansion{worker, ecid}:
              match U32.is_eq(ecid, cand_cid(cand)):
                case True{}: plan_block(next, candidates, codes_map, ensure_producer(producer_code, cand, codes_map, plan))
                case False{}: plan_block(next, candidates, codes_map, plan)
        case None{}: plan_expand(hcode, at, producer_code, cand, next, candidates, codes_map, plan)

def plan_expand(+hcode: U32, +at: U32, +producer_code: U32, +cand: Cand, +next: BIR.Block, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match IndexLookup.find(BIR.Code, codes_map, U32.show(hcode)):
    case None{}: plan_block(next, candidates, codes_map, plan)
    case Some{+source}:
      match source:
        case BIR.Code{hid, +captures, +parameters, +body}:
          match U32.is_eq(hid, producer_code):
            case True{}: plan_block(next, candidates, codes_map, plan)
            case False{}:
              +cap = List.length(&2, BIR.Use, captures)
              match Nat.is_ge(U32.to_nat(at), cap):
                case False{}: plan_block(next, candidates, codes_map, plan)
                case True{}: plan_expand_site(source, Nat.sub(U32.to_nat(at), cap), hcode, at, producer_code, cand, next, candidates, codes_map, plan)

def plan_expand_site(+source: BIR.Code, +position: Nat, +hcode: U32, +at: U32, +producer_code: U32, +cand: Cand, +next: BIR.Block, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match source:
    case BIR.Code{hid, +captures, +parameters, +body}:
      match nth_param(parameters, position):
        case None{}: plan_block(next, candidates, codes_map, plan)
        case Some{param}:
          match param:
            case BIR.Parameter{+target, use}:
              match site_dry(body, target, cand):
                case Wstate{used, forward, forwards, bad}:
                  match Bool.and(Bool.and(Bool.not(bad), used), forward_none(forward)):
                    case False{}: plan_block(next, candidates, codes_map, plan)
                    case True{}: plan_expand_make(source, position, hcode, at, producer_code, cand, next, candidates, codes_map, plan)

def plan_expand_make(+source: BIR.Code, +position: Nat, +hcode: U32, +at: U32, +producer_code: U32, +cand: Cand, +next: BIR.Block, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match consumer_make(source, position, cand_cid(cand), field_identities(cand_fields(cand), Nil{}), cand_fields(cand), plan_fresh(plan)):
    case None{}: plan_block(next, candidates, codes_map, plan)
    case Some{built}:
      match built:
        case ConsumerBuilt{rest, +worker}:
          +key = expansion_key(hcode, at)
          plan_block(next, candidates, codes_map, ensure_producer(producer_code, cand, codes_map, plan_add_consumer(plan, rest, key, Expansion{code_id(worker), cand_cid(cand)}, worker)))

def cand_fields(+cand: Cand) -> List<&2, BIR.Field>:
  match cand:
    case Cand{cid, local, +fields}: fields

def plan_codes(+codes: List<&2, BIR.Code>, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match codes:
    case Nil{}: plan
    case +code <> rest:
      match code:
        case BIR.Code{+id, +captures, +parameters, +body}: plan_codes(rest, candidates, codes_map, plan_block(body, candidates, codes_map, plan))

def plan_declarations(+items: List<&2, BIR.Declaration>, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  match items:
    case Nil{}: plan
    case +item <> rest:
      match item:
        case BIR.LazyDeclaration{key, +body}: plan_declarations(rest, candidates, codes_map, plan_block(body, candidates, codes_map, plan))
        case _: plan_declarations(rest, candidates, codes_map, plan)

def plan_program(+codes: List<&2, BIR.Code>, +declarations: List<&2, BIR.Declaration>, +candidates: Map<&2, Cand>, +codes_map: Map<&2, BIR.Code>, +plan: Plan) -> Plan:
  plan_declarations(declarations, candidates, codes_map, plan_codes(codes, candidates, codes_map, plan))

# ---------------------------------------------------------------------------
# Rewriting
# ---------------------------------------------------------------------------

type Rw is Data:
  Rw{block: BIR.Block, rest: Fresh}

type RwCodes is Data:
  RwCodes{codes: List<&2, BIR.Code>, rest: Fresh}

type RwDecls is Data:
  RwDecls{declarations: List<&2, BIR.Declaration>, rest: Fresh}

# The vector at a call site is bound by fresh locals of that site only: two
# calls of one worker never share a continuation binding, and the worker's own
# field locals stay private to its body.
def rewrite_block(+block: BIR.Block, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> Rw:
  match block:
    case BIR.Let{+id, +op, +next}:
      match op:
        case BIR.Direct{+code, +args}: rewrite_direct(id, code, args, next, producers, expansions, fresh)
        case _: rewrite_let(id, op, next, producers, expansions, fresh)
    case BIR.LetValues{+ids, +code, +args, +next}: rewrite_let_values(ids, code, args, next, producers, expansions, fresh)
    case BIR.Branch{+condition, +yes, +no}: rewrite_branch(condition, yes, no, producers, expansions, fresh)
    case BIR.Region{+label, +body, +next}: rewrite_region(label, body, next, producers, expansions, fresh)
    case _: Rw{block, fresh}

def rewrite_let(+id: U32, +op: BIR.Op, +next: BIR.Block, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> Rw:
  match rewrite_block(next, producers, expansions, fresh):
    case Rw{inner, rest}: Rw{BIR.Let{id, op, inner}, rest}

def rewrite_let_values(+ids: List<&2, U32>, +code: U32, +args: List<&2, BIR.Arg>, +next: BIR.Block, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> Rw:
  match rewrite_block(next, producers, expansions, fresh):
    case Rw{inner, rest}: Rw{BIR.LetValues{ids, code, args, inner}, rest}

def rewrite_branch(+condition: BIR.Atom, +yes: BIR.Block, +no: BIR.Block, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> Rw:
  match rewrite_block(yes, producers, expansions, fresh):
    case Rw{yb, f1}:
      match rewrite_block(no, producers, expansions, f1):
        case Rw{nb, f2}: Rw{BIR.Branch{condition, yb, nb}, f2}

def rewrite_region(+label: U32, +body: BIR.Block, +next: BIR.Block, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> Rw:
  match rewrite_block(body, producers, expansions, fresh):
    case Rw{bb, f1}:
      match rewrite_block(next, producers, expansions, f1):
        case Rw{nb, f2}: Rw{BIR.Region{label, bb, nb}, f2}

def rewrite_direct(+id: U32, +code: U32, +args: List<&2, BIR.Arg>, +next: BIR.Block, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> Rw:
  match IndexLookup.find(Producer, producers, U32.show(code)):
    case None{}: rewrite_let(id, BIR.Direct{code, args}, next, producers, expansions, fresh)
    case Some{+producer}:
      match producer:
        case Producer{source, +cid, +worker, +fields, worker_code}:
          match site_ids(fresh, fields):
            case SiteIds{f1, +ids, +comps}:
              match site_real(next, id, cid, field_identities(fields, Nil{}), comps, expansions):
                case Wresult{block, state}:
                  match site_ok(state):
                    case True{}: rewrite_site(ids, worker, args, block, producers, expansions, f1)
                    case False{}: rewrite_let(id, BIR.Direct{code, args}, next, producers, expansions, fresh)

def rewrite_site(+ids: List<&2, U32>, +worker: U32, +args: List<&2, BIR.Arg>, +body: BIR.Block, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> Rw:
  match rewrite_block(body, producers, expansions, fresh):
    case Rw{inner, rest}: Rw{BIR.LetValues{ids, worker, args, inner}, rest}

def rewrite_codes(+codes: List<&2, BIR.Code>, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> RwCodes:
  match codes:
    case Nil{}: RwCodes{Nil{}, fresh}
    case +code <> rest:
      match code:
        case BIR.Code{+id, +captures, +parameters, +body}: rewrite_code(id, captures, parameters, body, rest, producers, expansions, fresh)

def rewrite_code(+id: U32, +captures: List<&2, BIR.Use>, +parameters: List<&2, BIR.Parameter>, +body: BIR.Block, +rest: List<&2, BIR.Code>, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> RwCodes:
  match rewrite_block(body, producers, expansions, fresh):
    case Rw{nb, f1}:
      match rewrite_codes(rest, producers, expansions, f1):
        case RwCodes{more, f2}: RwCodes{BIR.Code{id, captures, parameters, nb} <> more, f2}

def rewrite_declarations(+items: List<&2, BIR.Declaration>, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> RwDecls:
  match items:
    case Nil{}: RwDecls{Nil{}, fresh}
    case +item <> rest:
      match item:
        case BIR.LazyDeclaration{+key, +body}: rewrite_declaration(key, body, rest, producers, expansions, fresh)
        case _:
          match rewrite_declarations(rest, producers, expansions, fresh):
            case RwDecls{more, f1}: RwDecls{item <> more, f1}

def rewrite_declaration(+key: String, +body: BIR.Block, +rest: List<&2, BIR.Declaration>, +producers: Map<&2, Producer>, +expansions: Map<&2, Expansion>, +fresh: Fresh) -> RwDecls:
  match rewrite_block(body, producers, expansions, fresh):
    case Rw{nb, f1}:
      match rewrite_declarations(rest, producers, expansions, f1):
        case RwDecls{more, f2}: RwDecls{BIR.LazyDeclaration{key, nb} <> more, f2}

def worker_codes(+order: List<&2, U32>, +producers: Map<&2, Producer>, +acc: List<&2, BIR.Code>) -> List<&2, BIR.Code>:
  match order:
    case Nil{}: List.reverse(&2, BIR.Code, acc)
    case +code <> rest:
      match IndexLookup.find(Producer, producers, U32.show(code)):
        case Some{producer}:
          match producer:
            case Producer{source, cid, worker, fields, built}: worker_codes(rest, producers, built <> acc)
        case None{}: worker_codes(rest, producers, acc)

# ---------------------------------------------------------------------------
# Public transform
# ---------------------------------------------------------------------------

def optimize_program(+codes: List<&2, BIR.Code>, +declarations: List<&2, BIR.Declaration>, +constructors: List<&2, BIR.ConstructorLayout>, +families: List<&2, BIR.Family>, +type_functions: List<&2, BIR.TypeFunction>, +end: BIR.Ending) -> BIR.Program:
  +fresh = program_bounds(codes, declarations, end)
  +codes_map = code_map(codes, Map.new(&2, BIR.Code))
  +candidates = candidate_map(codes, Map.new(&2, Cand))
  +plan = Plan{fresh, Map.new(&2, Producer), Nil{}, Map.new(&2, Expansion), Nil{}}
  +planned = plan_program(codes, declarations, candidates, codes_map, plan)
  +producers = plan_producers(planned)
  +expansions = plan_expansions(planned)
  match rewrite_codes(codes, producers, expansions, plan_fresh(planned)):
    case RwCodes{new_codes, after_codes}:
      match rewrite_declarations(declarations, producers, expansions, after_codes):
        case RwDecls{new_declarations, after}:
          match safe_fresh(after):
            case True{}: build_optimized(new_codes, new_declarations, planned, producers, constructors, families, type_functions, end)
            case False{}: BIR.Program{codes, declarations, constructors, families, type_functions, end}

# A saturated id counter means the fresh range ran out and a generated id could
# collide with a live one; the conformant original program is then returned.
def safe_fresh(+fresh: Fresh) -> Bool:
  Bool.and(U32.is_lt(fresh_code(fresh), 4294967295), U32.is_lt(fresh_local(fresh), 4294967295))

# Both worker kinds are emitted: a rewritten call may target a consumer worker
# exactly as it targets a producer worker, so a missing code would be an
# undefined callee. Producer workers keep their allocation order, then consumers.
def build_optimized(+new_codes: List<&2, BIR.Code>, +new_declarations: List<&2, BIR.Declaration>, +planned: Plan, +producers: Map<&2, Producer>, +constructors: List<&2, BIR.ConstructorLayout>, +families: List<&2, BIR.Family>, +type_functions: List<&2, BIR.TypeFunction>, +end: BIR.Ending) -> BIR.Program:
  +workers = List.append(&2, BIR.Code, worker_codes(plan_order(planned), producers, Nil{}), plan_consumers(planned))
  BIR.Program{List.append(&2, BIR.Code, new_codes, workers), new_declarations, constructors, families, type_functions, end}

def optimize(program: BIR.Program) -> BIR.Program:
  match result_widths(program):
    case WidthsFail{message}: program
    case WidthsOk{widths}:
      match program:
        case BIR.Program{+codes, +declarations, +constructors, +families, +type_functions, +end}: optimize_program(codes, declarations, constructors, families, type_functions, end)
