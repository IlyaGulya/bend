import Base
import ./ast.bend as Ast
import ./checker_arena.bend as Arena
import ./checker_ir.bend as IR
import ./checked_frontend.bend as Checked
import ./scope_lookup.bend as Scope
import ./lower_catalog.bend as Catalog
import ./descriptor_nf.bend as DescriptorNf
import ./backend_ir.bend as BIR

# Checked FIR to target-neutral backend IR. Nothing here knows a rendering
# target, reconstructs syntax or re-infers a type: erasure, strict operands,
# captures, application shape and descriptor provenance are decided once.
type ProgramResult is Data:
  Lowered{program: BIR.Program}
  LowerFailure{message: String, span: Ast.SourceSpan}

type Problem is Data:
  Problem{message: String, span: Ast.SourceSpan}
# A lexical slot is not its semantic value. Dependent local substitution never
# licenses reevaluating that value at each runtime use.
type Slot is Data:
  ErasedSlot{}
  Slot{owner: U32, identity: U32, value: BIR.Atom, use: BIR.Use}
type Capture is Data:
  Capture{slot: Slot, index: U32}
type Instruction is Data:
  Bind{id: U32, op: BIR.Op}
  Guard{condition: BIR.Atom, failure: BIR.Block}
  Stop{failure: BIR.Block}
type Frame is Data:
  Frame{owner: U32, instructions: List<&2, Instruction>, captures: List<&2, Capture>, capture_count: U32}
type State is Type:
  State{source: Arena.Arena, next_code: U32, next_local: U32, frame: Frame, codes: List<&2, BIR.Code>, failure: Maybe<&2, Problem>, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, DescriptorNf.NfContext>}
type LowerResult<-T: Type> is Type:
  LowerResult{state: State, value: T}
type CodeRef is Data:
  CodeRef{code: U32, parameters: List<&2, BIR.Parameter>, captures: List<&2, Capture>}
type SourceArgument is Data:
  SourceArgument{quantity: Ast.Quantity, occurrence: IR.Occurrence}
type Spine is Data:
  Spine{head: IR.Occurrence, args: List<&2, SourceArgument>}
type TemplateResult is Type:
  TemplateResult{source: Arena.Arena, problem: Maybe<&2, Problem>}
type Prepared is Type:
  Prepared{program: Checked.CheckedProgram, problem: Maybe<&2, Problem>}

def use(quantity: Ast.Quantity) -> BIR.Use:
  match quantity:
    case Ast.QMany{}: BIR.Many{}
    case _: BIR.Affine{}
def bir_use(quantity: BIR.Quantity) -> BIR.Use:
  match quantity:
    case BIR.Unrestricted{}: BIR.Many{}
    case _: BIR.Affine{}
def no_span() -> Ast.SourceSpan:
  Ast.SpanOf{"", 0n, 0n}
def problem_first(old: Maybe<&2, Problem>, message: String, span: Ast.SourceSpan) -> Maybe<&2, Problem>:
  match old:
    case None{}: Some{Problem{message, span}}
    case Some{_}: old
def fail(state: State, message: String, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match state:
    case State{source, code, local, frame, codes, old, scope, normalizer}:
      LowerResult{State{source, code, local, frame, codes, problem_first(old, message, span), scope, normalizer}, BIR.Null{}}
def native_match_state_problem_0(v_10: LowerResult<BIR.Atom>) -> State:
  match v_10:
    case LowerResult{v_8, _}:
      v_8

def state_problem(v_1: State, v_3: String, v_4: Ast.SourceSpan) -> State:
  native_match_state_problem_0(fail(v_1, v_3, v_4))

def native_match_node_0(v_20: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_12: U32, v_13: U32, v_14: Frame, v_15: List<&2, BIR.Code>, v_16: Maybe<&2, Problem>, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, DescriptorNf.NfContext>) -> LowerResult<Arena.Node>:
  match v_20:
    case (v_18, v_19):
      LowerResult{State{v_18, v_12, v_13, v_14, v_15, v_16, scope, normalizer}, v_19}

def native_match_node_1(v_1: State, v_3: U32) -> LowerResult<Arena.Node>:
  match v_1:
    case State{v_11, v_12, v_13, v_14, v_15, v_16, scope, normalizer}:
      native_match_node_0(Arena.get_node(v_11, v_3), v_12, v_13, v_14, v_15, v_16, scope, normalizer)

def node(v_1: State, v_3: U32) -> LowerResult<Arena.Node>:
  native_match_node_1(v_1, v_3)

def native_match_name_0(v_21: Sigma<&1, &1, Arena.Arena, _ => String>, v_13: U32, v_14: U32, v_15: Frame, v_16: List<&2, BIR.Code>, v_17: Maybe<&2, Problem>, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, DescriptorNf.NfContext>) -> LowerResult<String>:
  match v_21:
    case (v_19, v_20):
      LowerResult{State{v_19, v_13, v_14, v_15, v_16, v_17, scope, normalizer}, v_20}

def native_match_name_1(v_1: State, v_3: U32) -> LowerResult<String>:
  match v_1:
    case State{v_12, v_13, v_14, v_15, v_16, v_17, scope, normalizer}:
      native_match_name_0(Arena.name_text(v_12, v_3), v_13, v_14, v_15, v_16, v_17, scope, normalizer)

def name(v_1: State, v_3: U32) -> LowerResult<String>:
  native_match_name_1(v_1, v_3)

def fresh(state: State) -> LowerResult<U32>:
  match state:
    case State{source, code, local, frame, codes, failure, scope, normalizer}:
      LowerResult{State{source, code, U32.inc(local), frame, codes, failure, scope, normalizer}, local}
def reserve(state: State, minimum: U32) -> State:
  match state:
    case State{source, code, local, frame, codes, failure, scope, normalizer}:
      State{source, code, U32.max(local, minimum), frame, codes, failure, scope, normalizer}
def push(state: State, instruction: Instruction) -> State:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure, scope, normalizer}:
      State{source, code, local, Frame{owner, instruction <> instructions, captures, count}, codes, failure, scope, normalizer}
def native_match_operation_0(v_8: LowerResult<U32>, v_2: BIR.Op) -> LowerResult<BIR.Atom>:
  match v_8:
    case LowerResult{v_6, v_7}:
      LowerResult{push(v_6, Bind{v_7, v_2}), BIR.Local{v_7}}

def operation(v_1: State, v_2: BIR.Op) -> LowerResult<BIR.Atom>:
  native_match_operation_0(fresh(v_1), v_2)

def guard(state: State, condition: BIR.Atom, failure: BIR.Block) -> State:
  match condition:
    case BIR.Boolean{True{}}: state
    case BIR.Boolean{False{}}: push(state, Stop{failure})
    case _: push(state, Guard{condition, failure})
def prefix(instructions: List<&2, Instruction>, next: BIR.Block) -> BIR.Block:
  match instructions:
    case Nil{}: next
    case Bind{id, op} <> rest: prefix(rest, BIR.Let{id, op, next})
    case Guard{condition, failure} <> rest: prefix(rest, BIR.Branch{condition, next, failure})
    case Stop{failure} <> rest: prefix(rest, failure)
def finish(instructions: List<&2, Instruction>, value: BIR.Atom) -> BIR.Block:
  match instructions value:
    case Bind{id, op} <> rest BIR.Local{result}:
      finish_last(U32.is_eq(id, result), id, op, rest, result)
    case _ _: prefix(instructions, BIR.Return{value})
def finish_last(last: Bool, id: U32, op: BIR.Op, rest: List<&2, Instruction>, result: U32) -> BIR.Block:
  match last op:
    case True{} BIR.Direct{code, args}: prefix(rest, BIR.TailDirect{code, args})
    case True{} BIR.Apply{fn, arg}: prefix(rest, BIR.TailApply{fn, arg})
    case _ _: prefix(rest, BIR.Let{id, op, BIR.Return{BIR.Local{result}}})
def slot_at(slots: List<&2, Slot>, index: Nat) -> Maybe<&2, Slot>:
  match slots index:
    case slot <> _ 0n: Some{slot}
    case _ <> rest 1n+more: slot_at(rest, more)
    case Nil{} _: None{}
def capture_found(captures: List<&2, Capture>, owner: U32, identity: U32) -> Maybe<&2, U32>:
  match captures:
    case Nil{}: None{}
    case Capture{Slot{from, id, _, _}, index} <> rest:
      capture_found_next(Bool.and(U32.is_eq(from, owner), U32.is_eq(id, identity)), index, rest, owner, identity)
    case _ <> rest: capture_found(rest, owner, identity)
def capture_found_next(found: Bool, index: U32, rest: List<&2, Capture>, owner: U32, identity: U32) -> Maybe<&2, U32>:
  match found:
    case True{}: Some{index}
    case False{}: capture_found(rest, owner, identity)
def resolve(state: State, slot: Slot) -> LowerResult<BIR.Atom>:
  match slot:
    case ErasedSlot{}: LowerResult{state, BIR.Null{}}
    case Slot{owner, identity, value, usage}:
      resolve_live(state, owner, identity, value, usage)
def resolve_live(state: State, owner: U32, identity: U32, value: BIR.Atom, usage: BIR.Use) -> LowerResult<BIR.Atom>:
  match state:
    case State{source, code, local, Frame{current, instructions, captures, count}, codes, failure, scope, normalizer}:
      resolve_owner(U32.is_eq(current, owner), State{source, code, local, Frame{current, instructions, captures, count}, codes, failure, scope, normalizer}, Slot{owner, identity, value, usage})
def native_match_resolve_owner_0(v_3: State, v_5: Slot, v_21: U32, v_22: U32) -> LowerResult<BIR.Atom>:
  match v_3:
    case State{v_34, v_35, v_36, Frame{v_37, v_38, v_39, v_40}, v_41, v_42, scope, normalizer}:
      resolve_capture(capture_found(v_39, v_21, v_22), v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_5, scope, normalizer)

def native_match_resolve_owner_1(v_1: Bool, v_5: Slot, v_3: State) -> LowerResult<BIR.Atom>:
  match v_1, v_5:
    case True{}, Slot{_, _, v_13, _}:
      LowerResult{v_3, v_13}
    case _, Slot{v_21, v_22, _, _}:
      native_match_resolve_owner_0(v_3, v_5, v_21, v_22)
    case _, _:
      LowerResult{v_3, BIR.Null{}}

def resolve_owner(v_1: Bool, v_3: State, v_5: Slot) -> LowerResult<BIR.Atom>:
  native_match_resolve_owner_1(v_1, v_5, v_3)

def resolve_capture(found: Maybe<&2, U32>, source: Arena.Arena, code: U32, local: U32, current: U32, instructions: List<&2, Instruction>, captures: List<&2, Capture>, count: U32, codes: List<&2, BIR.Code>, failure: Maybe<&2, Problem>, slot: Slot, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, DescriptorNf.NfContext>) -> LowerResult<BIR.Atom>:
  match found:
    case Some{index}: LowerResult{State{source, code, local, Frame{current, instructions, captures, count}, codes, failure, scope, normalizer}, BIR.Capture{index}}
    case None{}: LowerResult{State{source, code, local, Frame{current, instructions, Capture{slot, count} <> captures, U32.inc(count)}, codes, failure, scope, normalizer}, BIR.Capture{count}}
def variable(state: State, slots: List<&2, Slot>, index: Nat, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  variable_found(state, slot_at(slots, index), span)
def variable_found(state: State, found: Maybe<&2, Slot>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match found:
    case Some{slot}: resolve(state, slot)
    case None{}: fail(state, "missing checked lexical binding", span)
def native_match_bind_slot_0(v_19: Frame, v_2: BIR.Atom, v_3: BIR.Use, v_9: U32, v_16: Arena.Arena, v_17: U32, v_18: U32, v_20: List<&2, BIR.Code>, v_21: Maybe<&2, Problem>, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, DescriptorNf.NfContext>) -> LowerResult<Slot>:
  match v_19:
    case Frame{v_26, _, _, _}:
      LowerResult{State{v_16, v_17, v_18, v_19, v_20, v_21, scope, normalizer}, Slot{v_26, v_9, v_2, v_3}}

def native_match_bind_slot_1(v_8: State, v_2: BIR.Atom, v_3: BIR.Use, v_9: U32) -> LowerResult<Slot>:
  match v_8:
    case State{v_16, v_17, v_18, v_19, v_20, v_21, scope, normalizer}:
      native_match_bind_slot_0(v_19, v_2, v_3, v_9, v_16, v_17, v_18, v_20, v_21, scope, normalizer)

def native_match_bind_slot_2(v_30: LowerResult<U32>, v_2: BIR.Atom, v_3: BIR.Use) -> LowerResult<Slot>:
  match v_30:
    case LowerResult{v_8, v_9}:
      native_match_bind_slot_1(v_8, v_2, v_3, v_9)

def bind_slot(v_1: State, v_2: BIR.Atom, v_3: BIR.Use) -> LowerResult<Slot>:
  native_match_bind_slot_2(fresh(v_1), v_2, v_3)

def enter(state: State) -> LowerResult<Frame>:
  match state:
    case State{source, code, local, parent, codes, failure, scope, normalizer}:
      LowerResult{State{source, U32.inc(code), local, Frame{code, Nil{}, Nil{}, 0}, codes, failure, scope, normalizer}, parent}
def capture_uses(captures: List<&2, Capture>) -> List<&2, BIR.Use>:
  match captures:
    case Nil{}: Nil{}
    case Capture{Slot{_, _, _, usage}, _} <> rest: usage <> capture_uses(rest)
    case _ <> rest: capture_uses(rest)
def leave(state: State, parent: Frame, parameters: List<&2, BIR.Parameter>, body: BIR.Block) -> LowerResult<CodeRef>:
  match state:
    case State{source, next_code, local, Frame{code, _, captures, _}, codes, failure, scope, normalizer}:
      ordered = List.reverse(&2, Capture, captures)
      LowerResult{State{source, next_code, local, parent, BIR.Code{code, capture_uses(ordered), parameters, body} <> codes, failure, scope, normalizer}, CodeRef{code, parameters, ordered}}
def leave_value(state: State, parent: Frame, parameters: List<&2, BIR.Parameter>, value: BIR.Atom) -> LowerResult<CodeRef>:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure, scope, normalizer}:
      leave(State{source, code, local, Frame{owner, Nil{}, captures, count}, codes, failure, scope, normalizer}, parent, parameters, finish(instructions, value))
def capture_arguments(state: State, captures: List<&2, Capture>) -> LowerResult<List<&2, BIR.Arg>>:
  match captures:
    case Nil{}: LowerResult{state, Nil{}}
    case Capture{slot, _} <> rest:
      capture_argument(state, slot, rest)
def native_match_capture_argument_0(v_25: LowerResult<List<&2, BIR.Arg>>, v_16: BIR.Use, v_20: BIR.Atom) -> LowerResult<List<&2, BIR.Arg>>:
  match v_25:
    case LowerResult{v_23, v_24}:
      LowerResult{v_23, BIR.Arg{v_16, v_20} <> v_24}

def native_match_capture_argument_1(v_26: LowerResult<BIR.Atom>, v_6: List<&2, Capture>, v_16: BIR.Use) -> LowerResult<List<&2, BIR.Arg>>:
  match v_26:
    case LowerResult{v_19, v_20}:
      native_match_capture_argument_0(capture_arguments(v_19, v_6), v_16, v_20)

def native_match_capture_argument_2(v_3: Slot, v_1: State, v_6: List<&2, Capture>) -> LowerResult<List<&2, BIR.Arg>>:
  match v_3:
    case Slot{_, _, _, v_16}:
      native_match_capture_argument_1(resolve(v_1, v_3), v_6, v_16)
    case ErasedSlot{}:
      capture_arguments(v_1, v_6)

def capture_argument(v_1: State, v_3: Slot, v_6: List<&2, Capture>) -> LowerResult<List<&2, BIR.Arg>>:
  native_match_capture_argument_2(v_3, v_1, v_6)

def native_match_close_0(v_15: LowerResult<List<&2, BIR.Arg>>, v_8: U32, v_9: List<&2, BIR.Parameter>) -> LowerResult<BIR.Atom>:
  match v_15:
    case LowerResult{v_13, v_14}:
      operation(v_13, BIR.Closure{v_8, v_14, v_9})

def native_match_close_1(v_3: CodeRef, v_1: State) -> LowerResult<BIR.Atom>:
  match v_3:
    case CodeRef{v_8, v_9, v_10}:
      native_match_close_0(capture_arguments(v_1, v_10), v_8, v_9)

def close(v_1: State, v_3: CodeRef) -> LowerResult<BIR.Atom>:
  native_match_close_1(v_3, v_1)

def native_match_call_reference_0(v_17: LowerResult<List<&2, BIR.Arg>>, v_5: List<&2, BIR.Arg>, v_10: U32) -> LowerResult<BIR.Atom>:
  match v_17:
    case LowerResult{v_15, v_16}:
      operation(v_15, BIR.Direct{v_10, List.append(&2, BIR.Arg, v_16, v_5)})

def native_match_call_reference_1(v_3: CodeRef, v_1: State, v_5: List<&2, BIR.Arg>) -> LowerResult<BIR.Atom>:
  match v_3:
    case CodeRef{v_10, _, v_12}:
      native_match_call_reference_0(capture_arguments(v_1, v_12), v_5, v_10)

def call_reference(v_1: State, v_3: CodeRef, v_5: List<&2, BIR.Arg>) -> LowerResult<BIR.Atom>:
  native_match_call_reference_1(v_3, v_1, v_5)

def constructor_native(constructor: Catalog.Constructor) -> String:
  match constructor:
    case Catalog.Constructor{BIR.ConstructorLayout{_, _, Some{identity}, _}, _, _, _}: identity
    case _: ""
def constructor_id(constructor: Catalog.Constructor) -> U32:
  match constructor:
    case Catalog.Constructor{BIR.ConstructorLayout{id, _, _, _}, _, _, _}: id
def constructor_key(constructor: Catalog.Constructor) -> String:
  match constructor:
    case Catalog.Constructor{BIR.ConstructorLayout{_, key, _, _}, _, _, _}: key
def atom_arguments(values: List<&2, BIR.Atom>) -> List<&2, BIR.Arg>:
  match values:
    case Nil{}: Nil{}
    case value <> rest: BIR.Arg{BIR.Affine{}, value} <> atom_arguments(rest)
def describe(state: State, handle: U32) -> LowerResult<Maybe<&2, BIR.Descriptor>>:
  match state:
    case State{source, code, local, frame, codes, failure, +scopes, +normalizer}:
      match scopes normalizer:
        case Some{scope} Some{+context}:
          match Catalog.descriptor(source, handle, scope):
            case Catalog.CatalogResult{source2, value}:
              LowerResult{State{source2, code, local, frame, codes, failure, Some{scope}, Some{context}}, Some{DescriptorNf.normalize_in(context, value)}}
        case _ _:
          LowerResult{State{source, code, local, frame, codes, problem_first(failure, "missing definition scope for a checked descriptor", no_span()), scopes, normalizer}, None{}}

def element_value(state: State, handle: U32) -> LowerResult<List<&2, BIR.Descriptor>>:
  match describe(state, handle):
    case LowerResult{state2, Some{descriptor}}: LowerResult{state2, [descriptor]}
    case LowerResult{state2, None{}}: LowerResult{state_problem(state2, "missing checked array element type", no_span()), []}

def element_argument(state: State, handle: U32) -> LowerResult<List<&2, BIR.Descriptor>>:
  match element_value(state, handle):
    case LowerResult{state2, [descriptor]}:
      match descriptor:
        case BIR.DescriptorRef{_, [element]}: LowerResult{state2, [element]}
        case BIR.DescriptorApplication{_, element}: LowerResult{state2, [element]}
        case _: LowerResult{state_problem(state2, "checked array type has no element argument", no_span()), []}
    case LowerResult{state2, _}: LowerResult{state2, []}

def primitive_element(state: State, +op: BIR.Primitive, +values: List<&2, BIR.Atom>, element: Maybe<&2, U32>, arrayed: Bool) -> LowerResult<BIR.Atom>:
  match element arrayed:
    case Some{handle} True{}: primitive_types(op, atom_arguments(values), element_argument(state, handle))
    case Some{handle} False{}: primitive_types(op, atom_arguments(values), element_value(state, handle))
    case None{} _: fail(state, "missing checked array element type", no_span())

def primitive_types(op: BIR.Primitive, arguments: List<&2, BIR.Arg>, types: LowerResult<List<&2, BIR.Descriptor>>) -> LowerResult<BIR.Atom>:
  match types:
    case LowerResult{state2, descriptors}: operation(state2, BIR.PrimitiveCall{op, arguments, descriptors})

def occurrence_type(occurrence: IR.Occurrence) -> Maybe<&2, U32>:
  match occurrence:
    case IR.TypedOccurrence{_, ty, _, _, _, _}: Some{ty}
    case IR.LocalReferenceOccurrence{_, ty, _, _}: Some{ty}
    case IR.ScalarOccurrence{_, ty, _, _, _}: Some{ty}
    case IR.StringOccurrence{_, ty, _, _}: Some{ty}
    case IR.CaseOccurrence{_, ty, _, _}: Some{ty}
    case IR.LocalOccurrence{_, ty, _, _, _}: Some{ty}

def first_binding_type(bindings: List<&2, IR.CheckedBinding>) -> Maybe<&2, U32>:
  match bindings:
    case Nil{}: None{}
    case IR.CheckedBinding{_, ty, _} <> _: Some{ty}

def first_occurrence_type(children: List<&2, IR.Occurrence>) -> Maybe<&2, U32>:
  match children:
    case Nil{}: None{}
    case child <> _: occurrence_type(child)

def live_argument_type(arguments: List<&2, SourceArgument>) -> Maybe<&2, U32>:
  match arguments:
    case Nil{}: None{}
    case SourceArgument{Ast.QZero{}, _} <> rest: live_argument_type(rest)
    case SourceArgument{_, occurrence} <> _: occurrence_type(occurrence)

def last_live_argument_type(arguments: List<&2, SourceArgument>) -> Maybe<&2, U32>:
  match arguments:
    case Nil{}: None{}
    case SourceArgument{Ast.QZero{}, _} <> rest: last_live_argument_type(rest)
    case SourceArgument{_, occurrence} <> rest:
      match last_live_argument_type(rest):
        case Some{ty}: Some{ty}
        case None{}: occurrence_type(occurrence)

# Array.new's element is the value it is given (its erased -T and depth precede
# it); every other array primitive operates on its first live argument.
def array_element_handle(op: BIR.Primitive, arguments: List<&2, SourceArgument>) -> Maybe<&2, U32>:
  match op:
    case BIR.PrimArrayNew{}: last_live_argument_type(arguments)
    case _: live_argument_type(arguments)

def array_element_is_argument(op: BIR.Primitive) -> Bool:
  match op:
    case BIR.PrimArrayGet{}: True{}
    case BIR.PrimArraySet{}: True{}
    case BIR.PrimArraySize{}: True{}
    case BIR.PrimArrayClone{}: True{}
    case BIR.PrimArraySwap{}: True{}
    case BIR.PrimArrayNode{}: True{}
    case BIR.PrimArrayLeft{}: True{}
    case BIR.PrimArrayRight{}: True{}
    case BIR.PrimArrayLeafValue{}: True{}
    case BIR.PrimIsArrayLeaf{}: True{}
    case BIR.PrimIsArrayNode{}: True{}
    case _: False{}

def array_primitive(+op: BIR.Primitive) -> Bool:
  match op:
    case BIR.PrimArrayNew{}: True{}
    case BIR.PrimArrayLeaf{}: True{}
    case BIR.PrimArrayNode{}: True{}
    case _: array_element_is_argument(op)

def primitive(state: State, op: BIR.Primitive, values: List<&2, BIR.Atom>) -> LowerResult<BIR.Atom>:
  operation(state, BIR.PrimitiveCall{op, atom_arguments(values), Nil{}})

def primitive_call(state: State, +op: BIR.Primitive, +arguments: List<&2, BIR.Arg>, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match array_primitive(op):
    case True{}:
      primitive_call_element(state, op, arguments, element)
    case False{}: operation(state, BIR.PrimitiveCall{op, arguments, Nil{}})

def primitive_call_element(state: State, +op: BIR.Primitive, +arguments: List<&2, BIR.Arg>, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match element:
    case Some{handle}: primitive_types(op, arguments, element_fact(state, handle, array_element_is_argument(op)))
    case None{}: fail(state, "missing checked array element type", no_span())

def element_fact(state: State, handle: U32, arrayed: Bool) -> LowerResult<List<&2, BIR.Descriptor>>:
  match arrayed:
    case True{}: element_argument(state, handle)
    case False{}: element_value(state, handle)

def primitive_fact(state: State, +op: BIR.Primitive, +values: List<&2, BIR.Atom>, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match array_primitive(op):
    case True{}: primitive_element(state, op, values, element, array_element_is_argument(op))
    case False{}: primitive(state, op, values)
def field_values(state: State, constructor: Catalog.Constructor, values: List<&2, BIR.Atom>, index: U32, span: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Field>>:
  match values:
    case Nil{}: LowerResult{state, Nil{}}
    case value <> rest:
      field_value(state, Catalog.constructor_field(constructor, index), constructor, value, rest, index, span)
def native_match_field_value_0(v_33: LowerResult<List<&2, BIR.Field>>, v_5: BIR.Atom, v_21: U32, v_22: String, v_23: BIR.Quantity) -> LowerResult<List<&2, BIR.Field>>:
  match v_33:
    case LowerResult{v_26, v_27}:
      LowerResult{v_26, BIR.Field{v_21, v_22, bir_use(v_23), v_5} <> v_27}

def native_match_field_value_1(v_3: Maybe<&2, Catalog.ConstructorField>, v_1: State, v_4: Catalog.Constructor, v_5: BIR.Atom, v_7: List<&2, BIR.Atom>, v_9: U32, v_10: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Field>>:
  match v_3:
    case Some{Catalog.ConstructorField{_, _, BIR.Erased{}}}:
      field_values(v_1, v_4, v_7, U32.inc(v_9), v_10)
    case Some{Catalog.ConstructorField{v_21, Some{v_22}, v_23}}:
      native_match_field_value_0(field_values(v_1, v_4, v_7, U32.inc(v_9), v_10), v_5, v_21, v_22, v_23)
    case _:
      LowerResult{state_problem(v_1, "missing checked constructor field layout", v_10), []}

def field_value(v_1: State, v_3: Maybe<&2, Catalog.ConstructorField>, v_4: Catalog.Constructor, v_5: BIR.Atom, v_7: List<&2, BIR.Atom>, v_9: U32, v_10: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Field>>:
  native_match_field_value_1(v_3, v_1, v_4, v_5, v_7, v_9, v_10)

def construct(state: State, constructor: Catalog.Constructor, values: List<&2, BIR.Atom>, span: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  construct_native(state, constructor_native(constructor), constructor, values, span, element)
def native_match_construct_native_0(v_586: LowerResult<List<&2, BIR.Field>>, v_4: Catalog.Constructor) -> LowerResult<BIR.Atom>:
  match v_586:
    case LowerResult{v_40, v_41}:
      operation(v_40, BIR.Construct{constructor_id(v_4), constructor_key(v_4), v_41})

def native_match_construct_native_1(v_3: String, v_6: List<&2, BIR.Atom>, v_1: State, v_4: Catalog.Constructor, v_7: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_3, v_6:
    case "Nat.Zero", []:
      LowerResult{v_1, BIR.Natural{0n}}
    case "Bool.False", []:
      LowerResult{v_1, BIR.Boolean{False{}}}
    case "Bool.True", []:
      LowerResult{v_1, BIR.Boolean{True{}}}
    case "String.SNil", []:
      LowerResult{v_1, BIR.Text{""}}
    case "Nat.Succ", [v_10]:
      primitive(v_1, BIR.PrimNatSuccessor{}, [v_10])
    case "Char.Chr", [v_13]:
      primitive(v_1, BIR.PrimCharNew{}, [v_13])
    case "String.SCon", [v_17, v_18]:
      primitive(v_1, BIR.PrimStringAppend{}, [v_17, v_18])
    case "U32.U32", [v_21]:
      primitive(v_1, BIR.PrimWordToU32{}, [v_21])
    case "F32.F32", [v_24]:
      primitive(v_1, BIR.PrimF32FromWord{}, [v_24])
    case "Array.ALeaf", [v_27]:
      primitive_fact(v_1, BIR.PrimArrayLeaf{}, [v_27], element)
    case "Array.ANode", [v_31, v_32]:
      primitive_fact(v_1, BIR.PrimArrayNode{}, [v_31, v_32], element)
    case _, _:
      native_match_construct_native_0(field_values(v_1, v_4, v_6, 0, v_7), v_4)

def construct_native(v_1: State, v_3: String, v_4: Catalog.Constructor, v_6: List<&2, BIR.Atom>, v_7: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  native_match_construct_native_1(v_3, v_6, v_1, v_4, v_7, element)

def construct_symbol(state: State, registry: Catalog.Registry, symbol: IR.Symbol, values: List<&2, BIR.Atom>, span: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  construct_found(state, Catalog.lookup_constructor(registry, symbol), values, span, element)
def construct_found(state: State, found: Maybe<&2, Catalog.Constructor>, values: List<&2, BIR.Atom>, span: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match found:
    case None{}: fail(state, "missing resolved constructor", span)
    case Some{constructor}: construct(state, constructor, values, span, element)
def native_match_constructor_operands_0(v_49: LowerResult<List<&2, BIR.Atom>>) -> LowerResult<List<&2, BIR.Atom>>:
  match v_49:
    case LowerResult{v_25, v_26}:
      LowerResult{v_25, BIR.Null{} <> v_26}

def native_match_constructor_operands_1(v_50: LowerResult<List<&2, BIR.Atom>>, v_38: BIR.Atom) -> LowerResult<List<&2, BIR.Atom>>:
  match v_50:
    case LowerResult{v_41, v_42}:
      LowerResult{v_41, v_38 <> v_42}

def native_match_constructor_operands_2(v_51: LowerResult<BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan, v_32: List<&2, IR.Occurrence>, v_34: List<&2, IR.CheckedBinding>) -> LowerResult<List<&2, BIR.Atom>>:
  match v_51:
    case LowerResult{v_37, v_38}:
      native_match_constructor_operands_1(constructor_operands(v_37, v_32, v_34, v_8, v_9, v_10), v_38)

def native_match_constructor_operands_3(v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_1: State, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Atom>>:
  match v_3, v_5:
    case [], []:
      LowerResult{v_1, []}
    case _ <> v_19, IR.CheckedBinding{Ast.QZero{}, _, _} <> v_22:
      native_match_constructor_operands_0(constructor_operands(v_1, v_19, v_22, v_8, v_9, v_10))
    case v_31 <> v_32, _ <> v_34:
      native_match_constructor_operands_2(lower_occurrence(v_1, v_31, v_8, v_9), v_8, v_9, v_10, v_32, v_34)
    case _, _:
      LowerResult{state_problem(v_1, "incomplete checked constructor operands", v_10), []}

def constructor_operands(v_1: State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Atom>>:
  native_match_constructor_operands_3(v_3, v_5, v_1, v_8, v_9, v_10)

def reference(state: State, found: Maybe<&2, Catalog.DefinitionHeader>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match found:
    case None{}: fail(state, "missing resolved definition", span)
    case Some{Catalog.DefinitionHeader{_, key, code, parameters, _, type_only, primitive, foreign, _}}:
      reference_kind(state, key, code, parameters, type_only, primitive, foreign)
def native_match_reference_kind_0(v_9: Bool, v_11: Maybe<&2, BIR.Primitive>, v_13: Maybe<&2, Catalog.Foreign>, v_7: List<&2, BIR.Parameter>, v_1: State, v_3: String, v_5: U32) -> LowerResult<BIR.Atom>:
  match v_9, v_11, v_13, v_7:
    case True{}, _, _, _:
      LowerResult{v_1, BIR.Null{}}
    case False{}, Some{_}, _, _:
      LowerResult{v_1, BIR.Symbol{v_5, v_3}}
    case False{}, None{}, None{}, _ <> _:
      LowerResult{v_1, BIR.Symbol{v_5, v_3}}
    case _, _, _, _:
      operation(v_1, BIR.LoadSymbol{v_5, v_3})

def reference_kind(v_1: State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Bool, v_11: Maybe<&2, BIR.Primitive>, v_13: Maybe<&2, Catalog.Foreign>) -> LowerResult<BIR.Atom>:
  native_match_reference_kind_0(v_9, v_11, v_13, v_7, v_1, v_3, v_5)

def symbol_value(state: State, symbol: IR.Symbol, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match symbol:
    case IR.Symbol{_, _, IR.FamilySymbol{}, _}: LowerResult{state, BIR.Null{}}
    case IR.Symbol{_, _, IR.ConstructorSymbol{}, _}: construct_symbol(state, registry, symbol, Nil{}, span, None{})
    case _: reference(state, Catalog.lookup_definition(registry, symbol), span)
def string_authorized(registry: Catalog.Registry, symbols: List<&2, IR.Symbol>, identities: List<&2, String>) -> Bool:
  match symbols identities:
    case Nil{} Nil{}: True{}
    case symbol <> rest identity <> more:
      string_authorized_found(Catalog.lookup_constructor(registry, symbol), registry, identity, rest, more)
    case _ _: False{}
def string_authorized_found(found: Maybe<&2, Catalog.Constructor>, registry: Catalog.Registry, identity: String, symbols: List<&2, IR.Symbol>, identities: List<&2, String>) -> Bool:
  match found:
    case None{}: False{}
    case Some{constructor}: Bool.and(String.eq(constructor_native(constructor), identity), string_authorized(registry, symbols, identities))
def scalar_characters(chars: List<&2, U32>) -> Maybe<&2, List<&2, Char>>:
  match chars:
    case Nil{}: Some{Nil{}}
    case value <> rest:
      scalar_character(Bool.and(U32.is_le(value, 1114111), Bool.or(U32.is_lt(value, 55296), U32.is_gt(value, 57343))), value, rest)
def scalar_character(valid: Bool, value: U32, rest: List<&2, U32>) -> Maybe<&2, List<&2, Char>>:
  match valid:
    case False{}: None{}
    case True{}: scalar_character_rest(value, scalar_characters(rest))
def scalar_character_rest(value: U32, rest: Maybe<&2, List<&2, Char>>) -> Maybe<&2, List<&2, Char>>:
  match rest:
    case None{}: None{}
    case Some{values}: Some{Char.from_u32(value) <> values}
def native_match_literal_word_0(v_24: LowerResult<BIR.Atom>, v_2: Catalog.Registry, v_8: IR.Symbol, v_11: Ast.SourceSpan, v_19: BIR.Atom) -> LowerResult<BIR.Atom>:
  match v_24:
    case LowerResult{v_22, v_23}:
      construct_symbol(v_22, v_2, v_8, [v_19, v_23], v_11, None{})

def native_match_literal_word_1(v_25: LowerResult<BIR.Atom>, v_2: Catalog.Registry, v_6: U32, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan, v_15: Nat) -> LowerResult<BIR.Atom>:
  match v_25:
    case LowerResult{v_18, v_19}:
      native_match_literal_word_0(literal_word(v_18, v_2, v_15, U32.shr(v_6), v_7, v_8, v_9, v_10, v_11), v_2, v_8, v_11, v_19)

def native_match_literal_word_2(v_4: Nat, v_1: State, v_2: Catalog.Registry, v_6: U32, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_4:
    case 0n:
      construct_symbol(v_1, v_2, v_7, [], v_11, None{})
    case 1n+v_15:
      native_match_literal_word_1(literal_bit(v_1, v_2, U32.is_eq(U32.and(v_6, 1), 0), v_9, v_10, v_11), v_2, v_6, v_7, v_8, v_9, v_10, v_11, v_15)

def literal_word(v_1: State, v_2: Catalog.Registry, v_4: Nat, v_6: U32, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_literal_word_2(v_4, v_1, v_2, v_6, v_7, v_8, v_9, v_10, v_11)

def literal_bit(state: State, registry: Catalog.Registry, zero_bit: Bool, zero: IR.Symbol, one: IR.Symbol, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match zero_bit:
    case True{}: construct_symbol(state, registry, zero, Nil{}, span, None{})
    case False{}: construct_symbol(state, registry, one, Nil{}, span, None{})
def literal_string(state: State, registry: Catalog.Registry, chars: List<&2, U32>, symbols: List<&2, IR.Symbol>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  literal_string_authorized(state, registry, chars, symbols, span, string_authorized(registry, symbols, ["String.SNil", "String.SCon", "Char.Chr", "U32.U32", "Word.Nil.WNil", "Word.Con.WCon", "Bool.False", "Bool.True"]))
def literal_string_authorized(state: State, registry: Catalog.Registry, chars: List<&2, U32>, symbols: List<&2, IR.Symbol>, span: Ast.SourceSpan, authorized: Bool) -> LowerResult<BIR.Atom>:
  match authorized:
    case True{}: literal_string_payload(state, registry, chars, symbols, span, scalar_characters(chars))
    case False{}: literal_string_records(state, registry, chars, symbols, span)
def literal_string_payload(state: State, registry: Catalog.Registry, chars: List<&2, U32>, symbols: List<&2, IR.Symbol>, span: Ast.SourceSpan, payload: Maybe<&2, List<&2, Char>>) -> LowerResult<BIR.Atom>:
  match payload:
    case Some{values}: LowerResult{state, BIR.Text{String.from_list(values)}}
    case None{}: literal_string_records(state, registry, chars, symbols, span)
def literal_string_records(state: State, registry: Catalog.Registry, chars: List<&2, U32>, symbols: List<&2, IR.Symbol>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match symbols:
    case nil <> cons <> char <> uint <> word_nil <> word_cons <> zero <> one <> Nil{}:
      literal_string_items(state, registry, chars, nil, cons, char, uint, word_nil, word_cons, zero, one, span)
    case _: fail(state, "incomplete checked string literal identities", span)
def native_match_literal_string_items_0(v_37: LowerResult<BIR.Atom>, v_2: Catalog.Registry, v_7: IR.Symbol, v_14: Ast.SourceSpan, v_32: BIR.Atom) -> LowerResult<BIR.Atom>:
  match v_37:
    case LowerResult{v_35, v_36}:
      construct_symbol(v_35, v_2, v_7, [v_32, v_36], v_14, None{})

def native_match_literal_string_items_1(v_38: LowerResult<BIR.Atom>, v_2: Catalog.Registry, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: Ast.SourceSpan, v_20: List<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_38:
    case LowerResult{v_31, v_32}:
      native_match_literal_string_items_0(literal_string_items(v_31, v_2, v_20, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14), v_2, v_7, v_14, v_32)

def native_match_literal_string_items_2(v_39: LowerResult<BIR.Atom>, v_2: Catalog.Registry, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: Ast.SourceSpan, v_20: List<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_39:
    case LowerResult{v_27, v_28}:
      native_match_literal_string_items_1(construct_symbol(v_27, v_2, v_8, [v_28], v_14, None{}), v_2, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_20)

def native_match_literal_string_items_3(v_40: LowerResult<BIR.Atom>, v_2: Catalog.Registry, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: Ast.SourceSpan, v_20: List<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_40:
    case LowerResult{v_23, v_24}:
      native_match_literal_string_items_2(construct_symbol(v_23, v_2, v_9, [v_24], v_14, None{}), v_2, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_20)

def native_match_literal_string_items_4(v_5: List<&2, U32>, v_1: State, v_2: Catalog.Registry, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_5:
    case []:
      construct_symbol(v_1, v_2, v_6, [], v_14, None{})
    case v_19 <> v_20:
      native_match_literal_string_items_3(literal_word(v_1, v_2, 32n, v_19, v_10, v_11, v_12, v_13, v_14), v_2, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_20)

def literal_string_items(v_1: State, v_2: Catalog.Registry, v_5: List<&2, U32>, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_literal_string_items_4(v_5, v_1, v_2, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14)

def native_match_spine_0(v_27: LowerResult<Arena.Node>, v_2: IR.Occurrence, v_5: List<&2, SourceArgument>, v_19: List<&2, IR.Occurrence>) -> LowerResult<Spine>:
  match v_27:
    case LowerResult{v_22, v_23}:
      spine_shape(v_22, v_23, v_2, v_19, v_5)

def native_match_spine_1(v_2: IR.Occurrence, v_1: State, v_5: List<&2, SourceArgument>) -> LowerResult<Spine>:
  match v_2:
    case IR.TypedOccurrence{v_14, _, _, _, _, v_19}:
      native_match_spine_0(node(v_1, v_14), v_2, v_5, v_19)
    case _:
      LowerResult{v_1, Spine{v_2, v_5}}

def spine(v_1: State, v_2: IR.Occurrence, v_5: List<&2, SourceArgument>) -> LowerResult<Spine>:
  native_match_spine_1(v_2, v_1, v_5)

def spine_shape(state: State, shape: Arena.Node, head: IR.Occurrence, children: List<&2, IR.Occurrence>, args: List<&2, SourceArgument>) -> LowerResult<Spine>:
  match shape head children:
    case Arena.TermApp{_, _, _} IR.TypedOccurrence{_, _, Some{quantity}, _, _, _} fn <> arg <> Nil{}:
      spine(state, fn, SourceArgument{quantity, arg} <> args)
    case Arena.TermAnn{_, _, _} _ inner <> _ <> Nil{}: spine(state, inner, args)
    case Arena.TermBang{_, _} _ inner <> Nil{}: spine(state, inner, args)
    case _ _ _: LowerResult{state, Spine{head, args}}
def head_definition(head: IR.Occurrence, registry: Catalog.Registry) -> Maybe<&2, Catalog.DefinitionHeader>:
  match head:
    case IR.TypedOccurrence{_, _, _, Some{IR.Symbol{owner, local, IR.DefinitionSymbol{}, signature}}, _, _}:
      Catalog.lookup_definition(registry, IR.Symbol{owner, local, IR.DefinitionSymbol{}, signature})
    case _: None{}
def applications(state: State, shape: Spine, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match shape:
    case Spine{head, args}: application_header(state, head_definition(head, registry), head, args, env, registry, span)
def native_match_application_header_0(v_38: LowerResult<BIR.Atom>, v_7: List<&2, SourceArgument>, v_10: List<&2, Slot>, v_11: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_38:
    case LowerResult{v_33, v_34}:
      apply_rest(v_33, v_34, v_7, v_10, v_11)

def native_match_application_header_1(v_3: Maybe<&2, Catalog.DefinitionHeader>, v_1: State, v_4: IR.Occurrence, v_7: List<&2, SourceArgument>, v_10: List<&2, Slot>, v_11: Catalog.Registry, v_12: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3:
    case Some{Catalog.DefinitionHeader{_, _, v_23, v_24, v_25, False{}, v_26, None{}, v_27}}:
      application_known(v_1, v_26, v_27, v_23, v_24, List.length(&2, BIR.Quantity, v_25), v_4, v_7, v_10, v_11, v_12)
    case _:
      native_match_application_header_0(lower_occurrence(v_1, v_4, v_10, v_11), v_7, v_10, v_11)

def application_header(v_1: State, v_3: Maybe<&2, Catalog.DefinitionHeader>, v_4: IR.Occurrence, v_7: List<&2, SourceArgument>, v_10: List<&2, Slot>, v_11: Catalog.Registry, v_12: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_application_header_1(v_3, v_1, v_4, v_7, v_10, v_11, v_12)

def application_known(state: State, native: Maybe<&2, BIR.Primitive>, fast: Bool, code: U32, parameters: List<&2, BIR.Parameter>, arity: Nat, head: IR.Occurrence, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match native:
    case Some{primitive}:
      application_native(state, Bool.and(Nat.is_ge(List.length(&2, SourceArgument, args), arity), Nat.is_eq(List.length(&2, BIR.Parameter, parameters), Catalog.primitive_arity(primitive))), primitive, arity, head, args, env, registry)
    case None{}:
      application_direct(state, fast, code, parameters, arity, head, args, env, registry, span)
def native_match_application_native_0(v_33: LowerResult<BIR.Atom>, v_10: List<&2, SourceArgument>, v_13: List<&2, Slot>, v_14: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_33:
    case LowerResult{v_18, v_19}:
      apply_rest(v_18, v_19, v_10, v_13, v_14)

def native_match_application_native_1(v_34: LowerResult<BIR.Atom>, v_13: List<&2, Slot>, v_14: Catalog.Registry, v_28: List<&2, SourceArgument>) -> LowerResult<BIR.Atom>:
  match v_34:
    case LowerResult{v_31, v_32}:
      apply_rest(v_31, v_32, v_28, v_13, v_14)

def native_match_application_native_2(v_24: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, SourceArgument>>, v_4: BIR.Primitive, v_13: List<&2, Slot>, v_14: Catalog.Registry, v_23: State, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_24:
    case (v_27, v_28):
      native_match_application_native_1(primitive_call(v_23, v_4, v_27, element), v_13, v_14, v_28)

def native_match_application_native_3(v_35: LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>, v_4: BIR.Primitive, v_13: List<&2, Slot>, v_14: Catalog.Registry, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_35:
    case LowerResult{v_23, v_24}:
      native_match_application_native_2(v_24, v_4, v_13, v_14, v_23, element)

# A partially applied array primitive still owes the C target its element type.
# The checked head occurrence's arrow type is the only surviving source: the
# domains after the applied arguments are the remaining parameters, and the
# array (or, for new, the value) domain names the element.
type ArrowFacts is Data:
  ArrowFacts{uses: List<&2, BIR.Use>, domains: List<&2, BIR.Descriptor>}

def arrow_facts(descriptor: BIR.Descriptor, skip: Nat) -> ArrowFacts:
  match skip:
    case 0n: arrow_facts_rest(descriptor)
    case 1n+rest:
      match descriptor:
        case BIR.DescriptorArrow{quantity, domain, body}: arrow_facts(body, rest)
        case _: ArrowFacts{Nil{}, Nil{}}

def arrow_facts_rest(descriptor: BIR.Descriptor) -> ArrowFacts:
  match descriptor:
    case BIR.DescriptorArrow{quantity, domain, body}:
      match arrow_facts_rest(body):
        case ArrowFacts{uses, domains}: ArrowFacts{bir_use(quantity) <> uses, domain <> domains}
    case _: ArrowFacts{Nil{}, Nil{}}

def last_domain(domains: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match domains:
    case Nil{}: None{}
    case only: Some{only}

def first_element_argument(descriptors: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match descriptors:
    case Nil{}: None{}
    case descriptor <> _:
      match descriptor:
        case BIR.DescriptorRef{_, [element]}: Some{element}
        case BIR.DescriptorApplication{_, element}: Some{element}
        case _: None{}

# new carries its element as the value it is given; every other array primitive
# operates on its first live domain, whose single argument is the element.
def partial_element(op: BIR.Primitive, domains: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match op:
    case BIR.PrimArrayNew{}: last_domain(domains)
    case _: first_element_argument(domains)

def parameterize(parameters: List<&2, BIR.Parameter>, uses: List<&2, BIR.Use>) -> List<&2, BIR.Parameter>:
  match parameters uses:
    case Nil{} _: Nil{}
    case BIR.Parameter{id, _} <> rest use <> more: BIR.Parameter{id, use} <> parameterize(rest, more)
    case _ Nil{}: Nil{}

def partial_array_parameters(state: State, uses: List<&2, BIR.Use>) -> LowerResult<List<&2, BIR.Parameter>>:
  match new_parameters(state, List.length(&2, BIR.Use, uses)):
    case LowerResult{state2, parameters}: LowerResult{state2, parameterize(parameters, uses)}

def partial_array_code(state: State, op: BIR.Primitive, captures: List<&2, BIR.Arg>, parameters: List<&2, BIR.Parameter>, element: BIR.Descriptor) -> LowerResult<BIR.Atom>:
  match fresh(state):
    case LowerResult{state2, result}: partial_array_body(state2, op, captures, parameters, element, result)

def partial_block(+id: U32, op: BIR.Op) -> BIR.Block:
  BIR.Let{id, op, BIR.Return{BIR.Local{id}}}

def partial_call(op: BIR.Primitive, captures: List<&2, BIR.Arg>, parameters: List<&2, BIR.Parameter>, element: BIR.Descriptor) -> BIR.Op:
  BIR.PrimitiveCall{op, indexed_captures(captures, 0) <> parameter_arguments(parameters), element <> Nil{}}

def partial_array_body(state: State, op: BIR.Primitive, captures: List<&2, BIR.Arg>, parameters: List<&2, BIR.Parameter>, element: BIR.Descriptor, +result: U32) -> LowerResult<BIR.Atom>:
  match state:
    case State{source, next_code, local, frame, codes, failure, scope, normalizer}:
      body = partial_block(result, partial_call(op, captures, parameters, element))
      code = BIR.Code{next_code, capture_argument_uses(captures), parameters, body}
      operation(State{source, U32.inc(next_code), local, frame, code <> codes, failure, scope, normalizer}, BIR.Closure{next_code, captures, parameters})

def capture_argument_uses(arguments: List<&2, BIR.Arg>) -> List<&2, BIR.Use>:
  match arguments:
    case Nil{}: Nil{}
    case BIR.Arg{usage, _} <> rest: usage <> capture_argument_uses(rest)

def partial_array_build(state: State, op: BIR.Primitive, head: IR.Occurrence, captures: List<&2, BIR.Arg>, applied: Nat) -> LowerResult<BIR.Atom>:
  match occurrence_type(head):
    case None{}: fail(state, "missing checked partial application type", no_span())
    case Some{handle}: partial_array_described(state, op, handle, captures, applied)

def partial_array_described(state: State, op: BIR.Primitive, handle: U32, captures: List<&2, BIR.Arg>, applied: Nat) -> LowerResult<BIR.Atom>:
  match describe(state, handle):
    case LowerResult{state2, None{}}: fail(state2, "missing checked partial application type", no_span())
    case LowerResult{state2, Some{descriptor}}: partial_array_facts(state2, op, arrow_facts(descriptor, applied), captures)

def partial_array_facts(state: State, op: BIR.Primitive, facts: ArrowFacts, captures: List<&2, BIR.Arg>) -> LowerResult<BIR.Atom>:
  match facts:
    case ArrowFacts{uses, domains}:
      match partial_element(op, domains):
        case None{}: fail(state, "missing checked array element type for a partially applied primitive", no_span())
        case Some{element}: partial_array_typed(state, op, uses, captures, element)

def partial_array_typed(state: State, op: BIR.Primitive, uses: List<&2, BIR.Use>, captures: List<&2, BIR.Arg>, element: BIR.Descriptor) -> LowerResult<BIR.Atom>:
  match partial_array_parameters(state, uses):
    case LowerResult{state2, parameters}: partial_array_code(state2, op, captures, parameters, element)

def partial_array_call(state: State, op: BIR.Primitive, head: IR.Occurrence, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match argument_prefix(state, List.length(&2, SourceArgument, args), args, env, registry):
    case LowerResult{state2, parts}:
      match parts:
        case (captures, _): partial_array_build(state2, op, head, captures, List.length(&2, SourceArgument, args))

def application_native_partial(state: State, op: BIR.Primitive, head: IR.Occurrence, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match array_primitive(op):
    case True{}: partial_array_call(state, op, head, args, env, registry)
    case False{}: native_match_application_native_0(lower_occurrence(state, head, env, registry), args, env, registry)

def native_match_application_native_4(v_3: Bool, v_1: State, v_4: BIR.Primitive, v_6: Nat, v_7: IR.Occurrence, v_10: List<&2, SourceArgument>, v_13: List<&2, Slot>, v_14: Catalog.Registry, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_3:
    case False{}:
      application_native_partial(v_1, v_4, v_7, v_10, v_13, v_14)
    case True{}:
      native_match_application_native_3(argument_prefix(v_1, v_6, v_10, v_13, v_14), v_4, v_13, v_14, element)

def application_native(v_1: State, v_3: Bool, v_4: BIR.Primitive, v_6: Nat, v_7: IR.Occurrence, v_10: List<&2, SourceArgument>, v_13: List<&2, Slot>, v_14: Catalog.Registry) -> LowerResult<BIR.Atom>:
  native_match_application_native_4(v_3, v_1, v_4, v_6, v_7, v_10, v_13, v_14, array_element_handle(v_4, v_10))

def native_match_application_direct_0(v_36: LowerResult<BIR.Atom>, v_13: List<&2, SourceArgument>, v_16: List<&2, Slot>, v_17: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_36:
    case LowerResult{v_22, v_23}:
      apply_rest(v_22, v_23, v_13, v_16, v_17)

def native_match_application_direct_1(v_31: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, SourceArgument>>, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_16: List<&2, Slot>, v_17: Catalog.Registry, v_18: Ast.SourceSpan, v_27: Nat, v_30: State) -> LowerResult<BIR.Atom>:
  match v_31:
    case (v_34, v_35):
      application_direct_values(v_30, Nat.is_ge(v_27, v_9), v_5, v_7, v_34, v_35, v_16, v_17, v_18)

def native_match_application_direct_2(v_37: LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_16: List<&2, Slot>, v_17: Catalog.Registry, v_18: Ast.SourceSpan, v_27: Nat) -> LowerResult<BIR.Atom>:
  match v_37:
    case LowerResult{v_30, v_31}:
      native_match_application_direct_1(v_31, v_5, v_7, v_9, v_16, v_17, v_18, v_27, v_30)

def native_match_application_direct_3(v_3: Bool, v_1: State, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_10: IR.Occurrence, v_13: List<&2, SourceArgument>, v_16: List<&2, Slot>, v_17: Catalog.Registry, v_18: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3:
    case False{}:
      native_match_application_direct_0(lower_occurrence(v_1, v_10, v_16, v_17), v_13, v_16, v_17)
    case True{}:
      v_27 = List.length(&2, SourceArgument, v_13)
      native_match_application_direct_2(argument_prefix(v_1, Nat.min(v_9, v_27), v_13, v_16, v_17), v_5, v_7, v_9, v_16, v_17, v_18, v_27)

def application_direct(v_1: State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_10: IR.Occurrence, v_13: List<&2, SourceArgument>, v_16: List<&2, Slot>, v_17: Catalog.Registry, v_18: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_application_direct_3(v_3, v_1, v_5, v_7, v_9, v_10, v_13, v_16, v_17, v_18)

def native_match_application_direct_values_0(v_23: LowerResult<BIR.Atom>, v_12: List<&2, SourceArgument>, v_15: List<&2, Slot>, v_16: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_23:
    case LowerResult{v_21, v_22}:
      apply_rest(v_21, v_22, v_12, v_15, v_16)

def native_match_application_direct_values_1(v_3: Bool, v_1: State, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Arg>, v_12: List<&2, SourceArgument>, v_15: List<&2, Slot>, v_16: Catalog.Registry, v_17: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3:
    case True{}:
      native_match_application_direct_values_0(direct_arity(v_1, Nat.is_eq(List.length(&2, BIR.Parameter, v_7), List.length(&2, BIR.Arg, v_9)), v_5, v_9, v_17), v_12, v_15, v_16)
    case False{}:
      partial(v_1, v_5, v_9, drop_parameters(List.length(&2, BIR.Arg, v_9), v_7))

def application_direct_values(v_1: State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Arg>, v_12: List<&2, SourceArgument>, v_15: List<&2, Slot>, v_16: Catalog.Registry, v_17: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_application_direct_values_1(v_3, v_1, v_5, v_7, v_9, v_12, v_15, v_16, v_17)

def direct_arity(state: State, valid: Bool, code: U32, values: List<&2, BIR.Arg>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match valid:
    case True{}: operation(state, BIR.Direct{code, values})
    case False{}: fail(state, "checked call quantity/entry arity mismatch", span)
def native_match_argument_prefix_0(v_39: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, SourceArgument>>, v_29: Ast.Quantity, v_35: BIR.Atom, v_38: State) -> LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>:
  match v_39:
    case (v_41, v_42):
      LowerResult{v_38, (BIR.Arg{use(v_29), v_35} <> v_41, v_42)}

def native_match_argument_prefix_1(v_48: LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>, v_29: Ast.Quantity, v_35: BIR.Atom) -> LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>:
  match v_48:
    case LowerResult{v_38, v_39}:
      native_match_argument_prefix_0(v_39, v_29, v_35, v_38)

def native_match_argument_prefix_2(v_49: LowerResult<BIR.Atom>, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_28: Nat, v_29: Ast.Quantity, v_31: List<&2, SourceArgument>) -> LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>:
  match v_49:
    case LowerResult{v_34, v_35}:
      native_match_argument_prefix_1(argument_prefix(v_34, v_28, v_31, v_9, v_10), v_29, v_35)

def native_match_argument_prefix_3(v_3: Nat, v_6: List<&2, SourceArgument>, v_1: State, v_9: List<&2, Slot>, v_10: Catalog.Registry) -> LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>:
  match v_3, v_6:
    case 0n, _:
      LowerResult{v_1, ([], v_6)}
    case 1n+v_20, SourceArgument{Ast.QZero{}, _} <> v_22:
      argument_prefix(v_1, v_20, v_22, v_9, v_10)
    case 1n+v_28, SourceArgument{v_29, v_30} <> v_31:
      native_match_argument_prefix_2(lower_occurrence(v_1, v_30, v_9, v_10), v_9, v_10, v_28, v_29, v_31)
    case _, []:
      LowerResult{state_problem(v_1, "missing checked call operands", no_span), ([], [])}

def argument_prefix(v_1: State, v_3: Nat, v_6: List<&2, SourceArgument>, v_9: List<&2, Slot>, v_10: Catalog.Registry) -> LowerResult<Pair(List<&2, BIR.Arg>, List<&2, SourceArgument>)>:
  native_match_argument_prefix_3(v_3, v_6, v_1, v_9, v_10)

def native_match_apply_rest_0(v_33: LowerResult<BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_21: List<&2, SourceArgument>) -> LowerResult<BIR.Atom>:
  match v_33:
    case LowerResult{v_29, v_30}:
      apply_rest(v_29, v_30, v_21, v_8, v_9)

def native_match_apply_rest_1(v_34: LowerResult<BIR.Atom>, v_2: BIR.Atom, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_19: Ast.Quantity, v_21: List<&2, SourceArgument>) -> LowerResult<BIR.Atom>:
  match v_34:
    case LowerResult{v_24, v_25}:
      native_match_apply_rest_0(operation(v_24, BIR.Apply{v_2, BIR.Arg{use(v_19), v_25}}), v_8, v_9, v_21)

def native_match_apply_rest_2(v_5: List<&2, SourceArgument>, v_1: State, v_2: BIR.Atom, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_5:
    case []:
      LowerResult{v_1, v_2}
    case SourceArgument{Ast.QZero{}, _} <> v_14:
      apply_rest(v_1, v_2, v_14, v_8, v_9)
    case SourceArgument{v_19, v_20} <> v_21:
      native_match_apply_rest_1(lower_occurrence(v_1, v_20, v_8, v_9), v_2, v_8, v_9, v_19, v_21)

def apply_rest(v_1: State, v_2: BIR.Atom, v_5: List<&2, SourceArgument>, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  native_match_apply_rest_2(v_5, v_1, v_2, v_8, v_9)

def drop_parameters(count: Nat, parameters: List<&2, BIR.Parameter>) -> List<&2, BIR.Parameter>:
  match count parameters:
    case 0n _: parameters
    case 1n+rest _ <> more: drop_parameters(rest, more)
    case _ Nil{}: Nil{}
def argument_uses(args: List<&2, BIR.Arg>) -> List<&2, BIR.Use>:
  match args:
    case Nil{}: Nil{}
    case BIR.Arg{usage, _} <> rest: usage <> argument_uses(rest)
def indexed_captures(args: List<&2, BIR.Arg>, index: U32) -> List<&2, BIR.Arg>:
  match args:
    case Nil{}: Nil{}
    case BIR.Arg{usage, _} <> rest: BIR.Arg{usage, BIR.Capture{index}} <> indexed_captures(rest, U32.inc(index))
def parameter_arguments(parameters: List<&2, BIR.Parameter>) -> List<&2, BIR.Arg>:
  match parameters:
    case Nil{}: Nil{}
    case BIR.Parameter{id, usage} <> rest: BIR.Arg{usage, BIR.Local{id}} <> parameter_arguments(rest)
def native_match_partial_0(v_1: State, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>) -> LowerResult<BIR.Atom>:
  match v_1:
    case State{v_18, v_19, v_20, v_21, v_22, v_23, scope, normalizer}:
      v_27 = List.append(&2, BIR.Arg, indexed_captures(v_5, 0), parameter_arguments(v_7))
      v_30 = BIR.Code{v_19, argument_uses(v_5), v_7, BIR.TailDirect{v_3, v_27}}
      operation(State{v_18, U32.inc(v_19), v_20, v_21, v_30 <> v_22, v_23, scope, normalizer}, BIR.Closure{v_19, v_5, v_7})

def native_match_partial_1(v_7: List<&2, BIR.Parameter>, v_1: State, v_3: U32, v_5: List<&2, BIR.Arg>) -> LowerResult<BIR.Atom>:
  match v_7:
    case []:
      operation(v_1, BIR.Direct{v_3, v_5})
    case _:
      native_match_partial_0(v_1, v_3, v_5, v_7)

def partial(v_1: State, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>) -> LowerResult<BIR.Atom>:
  native_match_partial_1(v_7, v_1, v_3, v_5)

def tag(state: State, constructor: Catalog.Constructor, value: BIR.Atom, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  tag_native(state, constructor_native(constructor), constructor, value, element)
def tag_native(state: State, identity: String, constructor: Catalog.Constructor, value: BIR.Atom, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match identity:
    case "Nat.Zero": primitive(state, BIR.PrimIsNatZero{}, [value])
    case "Nat.Succ": primitive(state, BIR.PrimIsNatSuccessor{}, [value])
    case "Bool.False": primitive(state, BIR.PrimIsFalse{}, [value])
    case "Bool.True": primitive(state, BIR.PrimIsTrue{}, [value])
    case "String.SNil": primitive(state, BIR.PrimIsStringEmpty{}, [value])
    case "String.SCon": primitive(state, BIR.PrimIsStringNonempty{}, [value])
    case "Array.ALeaf": primitive_fact(state, BIR.PrimIsArrayLeaf{}, [value], element)
    case "Array.ANode": primitive_fact(state, BIR.PrimIsArrayNode{}, [value], element)
    case "Char.Chr": LowerResult{state, BIR.Boolean{True{}}}
    case "U32.U32": LowerResult{state, BIR.Boolean{True{}}}
    case "F32.F32": LowerResult{state, BIR.Boolean{True{}}}
    case _: operation(state, BIR.HasTag{value, constructor_id(constructor), constructor_key(constructor)})
def project(state: State, constructor: Catalog.Constructor, value: BIR.Atom, index: U32, span: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  project_native(state, constructor_native(constructor), constructor, value, index, span, element)
def project_native(state: State, identity: String, constructor: Catalog.Constructor, value: BIR.Atom, index: U32, span: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match identity index:
    case "Nat.Succ" 0: primitive(state, BIR.PrimNatPredecessor{}, [value])
    case "String.SCon" 0: primitive(state, BIR.PrimStringHead{}, [value])
    case "String.SCon" 1: primitive(state, BIR.PrimStringTail{}, [value])
    case "Char.Chr" 0: primitive(state, BIR.PrimCharCode{}, [value])
    case "U32.U32" 0: primitive(state, BIR.PrimU32ToWord{}, [value])
    case "F32.F32" 0: primitive(state, BIR.PrimF32ToWord{}, [value])
    case "Array.ALeaf" 0: primitive_fact(state, BIR.PrimArrayLeafValue{}, [value], element)
    case "Array.ANode" 0: primitive_fact(state, BIR.PrimArrayLeft{}, [value], element)
    case "Array.ANode" 1: primitive_fact(state, BIR.PrimArrayRight{}, [value], element)
    case _ _: project_field(state, Catalog.constructor_field(constructor, index), constructor, value, span)
def project_field(state: State, field: Maybe<&2, Catalog.ConstructorField>, constructor: Catalog.Constructor, value: BIR.Atom, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match field:
    case Some{Catalog.ConstructorField{_, _, BIR.Erased{}}}: LowerResult{state, BIR.Null{}}
    case Some{Catalog.ConstructorField{identity, Some{key}, _}}:
      operation(state, BIR.Project{value, constructor_id(constructor), identity, key})
    case _: fail(state, "missing checked field projection", span)
def pattern_identity(pattern: IR.CheckedPattern, registry: Catalog.Registry) -> String:
  match pattern:
    case IR.CheckedConstructor{_, symbol, _, _}: pattern_identity_found(Catalog.lookup_constructor(registry, symbol))
    case _: ""
def pattern_identity_found(found: Maybe<&2, Catalog.Constructor>) -> String:
  match found:
    case None{}: ""
    case Some{constructor}: constructor_native(constructor)
def closed_bit(pattern: IR.CheckedPattern, registry: Catalog.Registry) -> Maybe<&2, U32>:
  match pattern:
    case IR.CheckedConstructor{_, _, Nil{}, _}: closed_bit_identity(pattern_identity(pattern, registry))
    case _: None{}
def closed_bit_identity(identity: String) -> Maybe<&2, U32>:
  match identity:
    case "Bool.False": Some{0}
    case "Bool.True": Some{1}
    case _: None{}
def closed_word(remaining: Nat, pattern: IR.CheckedPattern, registry: Catalog.Registry) -> Maybe<&2, U32>:
  closed_word_identity(remaining, pattern_identity(pattern, registry), pattern, registry)
def closed_word_identity(remaining: Nat, identity: String, pattern: IR.CheckedPattern, registry: Catalog.Registry) -> Maybe<&2, U32>:
  match remaining identity pattern:
    case 0n "Word.Nil.WNil" IR.CheckedConstructor{_, _, Nil{}, _}: Some{0}
    case 1n+rest "Word.Con.WCon" IR.CheckedConstructor{_, _, bit <> tail <> Nil{}, _}:
      closed_word_parts(closed_bit(bit, registry), closed_word(rest, tail, registry))
    case _ _ _: None{}
def closed_word_parts(bit: Maybe<&2, U32>, tail: Maybe<&2, U32>) -> Maybe<&2, U32>:
  match bit tail:
    case Some{head} Some{rest}: Some{U32.or(head, U32.shl(rest))}
    case _ _: None{}
def closed_scalar(identity: String, fields: List<&2, IR.CheckedPattern>, registry: Catalog.Registry) -> Maybe<&2, U32>:
  match identity fields:
    case "U32.U32" word <> Nil{}: closed_word(32n, word, registry)
    case "F32.F32" word <> Nil{}: closed_word(32n, word, registry)
    case _ _: None{}
def erase_pattern(pattern: IR.CheckedPattern, env: List<&2, Slot>) -> List<&2, Slot>:
  match pattern:
    case IR.CheckedVariable{_, _}: ErasedSlot{} <> env
    case IR.CheckedConstructor{_, _, fields, _}: erase_patterns(fields, env)
def erase_patterns(patterns: List<&2, IR.CheckedPattern>, env: List<&2, Slot>) -> List<&2, Slot>:
  match patterns:
    case Nil{}: env
    case pattern <> rest: erase_patterns(rest, erase_pattern(pattern, env))
def native_match_patterns_0(v_31: LowerResult<List<&2, Slot>>, v_9: Catalog.Registry, v_10: BIR.Block, v_19: List<&2, IR.CheckedPattern>, v_21: List<&2, BIR.Atom>) -> LowerResult<List<&2, Slot>>:
  match v_31:
    case LowerResult{v_24, v_25}:
      patterns(v_24, v_19, v_21, v_25, v_9, v_10)

def native_match_patterns_1(v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, BIR.Atom>, v_1: State, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match v_3, v_5:
    case [], []:
      LowerResult{v_1, v_8}
    case v_18 <> v_19, v_20 <> v_21:
      native_match_patterns_0(pattern(v_1, v_18, v_20, v_8, v_9, v_10), v_9, v_10, v_19, v_21)
    case _, _:
      LowerResult{state_problem(v_1, "checked pattern/scrutinee arity mismatch", no_span), v_8}

def patterns(v_1: State, v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: BIR.Block) -> LowerResult<List<&2, Slot>>:
  native_match_patterns_1(v_3, v_5, v_1, v_8, v_9, v_10)

def native_match_pattern_0(v_41: LowerResult<Slot>, v_6: List<&2, Slot>) -> LowerResult<List<&2, Slot>>:
  match v_41:
    case LowerResult{v_29, v_30}:
      LowerResult{v_29, v_30 <> v_6}

def native_match_pattern_1(v_2: IR.CheckedPattern, v_1: State, v_3: BIR.Atom, v_6: List<&2, Slot>, v_7: Catalog.Registry, v_8: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match v_2:
    case IR.CheckedVariable{_, IR.CheckedBinding{Ast.QZero{}, _, _}}:
      LowerResult{v_1, ErasedSlot{} <> v_6}
    case IR.CheckedVariable{_, IR.CheckedBinding{v_23, _, _}}:
      native_match_pattern_0(bind_slot(v_1, v_3, use(v_23)), v_6)
    case IR.CheckedConstructor{_, v_36, v_37, v_38}:
      pattern_constructor(v_1, Catalog.lookup_constructor(v_7, v_36), v_37, v_38, v_3, v_6, v_7, v_8)

def pattern(v_1: State, v_2: IR.CheckedPattern, v_3: BIR.Atom, v_6: List<&2, Slot>, v_7: Catalog.Registry, v_8: BIR.Block) -> LowerResult<List<&2, Slot>>:
  native_match_pattern_1(v_2, v_1, v_3, v_6, v_7, v_8)

def pattern_constructor(state: State, found: Maybe<&2, Catalog.Constructor>, fields: List<&2, IR.CheckedPattern>, layout: List<&2, IR.CheckedBinding>, value: BIR.Atom, env: List<&2, Slot>, registry: Catalog.Registry, failure: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match found:
    case None{}: LowerResult{state_problem(state, "missing resolved pattern constructor", no_span()), env}
    case Some{constructor}:
      pattern_scalar(state, closed_scalar(constructor_native(constructor), fields, registry), constructor, fields, layout, value, env, registry, failure, first_binding_type(layout))
def native_match_pattern_scalar_0(v_31: LowerResult<BIR.Atom>, v_13: List<&2, Slot>, v_15: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match v_31:
    case LowerResult{v_24, v_25}:
      LowerResult{guard(v_24, v_25, v_15), v_13}

def native_match_pattern_scalar_1(v_32: LowerResult<BIR.Atom>, v_5: Catalog.Constructor, v_7: List<&2, IR.CheckedPattern>, v_9: List<&2, IR.CheckedBinding>, v_10: BIR.Atom, v_13: List<&2, Slot>, v_14: Catalog.Registry, v_15: BIR.Block, element: Maybe<&2, U32>) -> LowerResult<List<&2, Slot>>:
  match v_32:
    case LowerResult{v_29, v_30}:
      pattern_fields(guard(v_29, v_30, v_15), v_5, v_7, v_9, v_10, 0, v_13, v_14, v_15, element)

def native_match_pattern_scalar_2(v_4: Maybe<&2, U32>, v_1: State, v_5: Catalog.Constructor, v_7: List<&2, IR.CheckedPattern>, v_9: List<&2, IR.CheckedBinding>, v_10: BIR.Atom, v_13: List<&2, Slot>, v_14: Catalog.Registry, v_15: BIR.Block, element: Maybe<&2, U32>) -> LowerResult<List<&2, Slot>>:
  match v_4:
    case Some{v_20}:
      native_match_pattern_scalar_0(scalar_test(v_1, String.eq(constructor_native(v_5), "F32.F32"), v_10, v_20), v_13, v_15)
    case None{}:
      native_match_pattern_scalar_1(tag(v_1, v_5, v_10, element), v_5, v_7, v_9, v_10, v_13, v_14, v_15, element)

def pattern_scalar(v_1: State, v_4: Maybe<&2, U32>, v_5: Catalog.Constructor, v_7: List<&2, IR.CheckedPattern>, v_9: List<&2, IR.CheckedBinding>, v_10: BIR.Atom, v_13: List<&2, Slot>, v_14: Catalog.Registry, v_15: BIR.Block, element: Maybe<&2, U32>) -> LowerResult<List<&2, Slot>>:
  native_match_pattern_scalar_2(v_4, v_1, v_5, v_7, v_9, v_10, v_13, v_14, v_15, element)

def scalar_test(state: State, floating: Bool, value: BIR.Atom, number: U32) -> LowerResult<BIR.Atom>:
  match floating:
    case True{}: primitive(state, BIR.PrimFloatBitsEqual{}, [value, BIR.Word{number}])
    case False{}: primitive(state, BIR.PrimSameValue{}, [value, BIR.Word{number}])
def native_match_pattern_fields_0(v_54: LowerResult<List<&2, Slot>>, v_2: Catalog.Constructor, v_7: BIR.Atom, v_9: U32, v_13: Catalog.Registry, v_14: BIR.Block, v_35: List<&2, IR.CheckedPattern>, v_37: List<&2, IR.CheckedBinding>, element: Maybe<&2, U32>) -> LowerResult<List<&2, Slot>>:
  match v_54:
    case LowerResult{v_45, v_46}:
      pattern_fields(v_45, v_2, v_35, v_37, v_7, U32.inc(v_9), v_46, v_13, v_14, element)

def native_match_pattern_fields_1(v_55: LowerResult<BIR.Atom>, v_2: Catalog.Constructor, v_7: BIR.Atom, v_9: U32, v_12: List<&2, Slot>, v_13: Catalog.Registry, v_14: BIR.Block, v_34: IR.CheckedPattern, v_35: List<&2, IR.CheckedPattern>, v_37: List<&2, IR.CheckedBinding>, element: Maybe<&2, U32>) -> LowerResult<List<&2, Slot>>:
  match v_55:
    case LowerResult{v_41, v_42}:
      native_match_pattern_fields_0(pattern(v_41, v_34, v_42, v_12, v_13, v_14), v_2, v_7, v_9, v_13, v_14, v_35, v_37, element)

def native_match_pattern_fields_2(v_4: List<&2, IR.CheckedPattern>, v_6: List<&2, IR.CheckedBinding>, v_1: State, v_2: Catalog.Constructor, v_7: BIR.Atom, v_9: U32, v_12: List<&2, Slot>, v_13: Catalog.Registry, v_14: BIR.Block, element: Maybe<&2, U32>) -> LowerResult<List<&2, Slot>>:
  match v_4, v_6:
    case [], []:
      LowerResult{v_1, v_12}
    case v_23 <> v_24, IR.CheckedBinding{Ast.QZero{}, _, _} <> v_27:
      pattern_fields(v_1, v_2, v_24, v_27, v_7, U32.inc(v_9), erase_pattern(v_23, v_12), v_13, v_14, element)
    case v_34 <> v_35, _ <> v_37:
      native_match_pattern_fields_1(project(v_1, v_2, v_7, v_9, no_span, element), v_2, v_7, v_9, v_12, v_13, v_14, v_34, v_35, v_37, element)
    case _, _:
      LowerResult{state_problem(v_1, "incomplete checked pattern layout", no_span), v_12}

def pattern_fields(v_1: State, v_2: Catalog.Constructor, v_4: List<&2, IR.CheckedPattern>, v_6: List<&2, IR.CheckedBinding>, v_7: BIR.Atom, v_9: U32, v_12: List<&2, Slot>, v_13: Catalog.Registry, v_14: BIR.Block, element: Maybe<&2, U32>) -> LowerResult<List<&2, Slot>>:
  native_match_pattern_fields_2(v_4, v_6, v_1, v_2, v_7, v_9, v_12, v_13, v_14, element)

def native_match_lower_values_0(v_22: LowerResult<List<&2, BIR.Atom>>, v_17: BIR.Atom) -> LowerResult<List<&2, BIR.Atom>>:
  match v_22:
    case LowerResult{v_20, v_21}:
      LowerResult{v_20, v_17 <> v_21}

def native_match_lower_values_1(v_23: LowerResult<BIR.Atom>, v_6: List<&2, Slot>, v_7: Catalog.Registry, v_13: List<&2, IR.Occurrence>) -> LowerResult<List<&2, BIR.Atom>>:
  match v_23:
    case LowerResult{v_16, v_17}:
      native_match_lower_values_0(lower_values(v_16, v_13, v_6, v_7), v_17)

def native_match_lower_values_2(v_3: List<&2, IR.Occurrence>, v_1: State, v_6: List<&2, Slot>, v_7: Catalog.Registry) -> LowerResult<List<&2, BIR.Atom>>:
  match v_3:
    case []:
      LowerResult{v_1, []}
    case v_12 <> v_13:
      native_match_lower_values_1(lower_occurrence(v_1, v_12, v_6, v_7), v_6, v_7, v_13)

def lower_values(v_1: State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, Slot>, v_7: Catalog.Registry) -> LowerResult<List<&2, BIR.Atom>>:
  native_match_lower_values_2(v_3, v_1, v_6, v_7)

def native_match_new_parameters_0(v_16: LowerResult<List<&2, BIR.Parameter>>, v_11: U32) -> LowerResult<List<&2, BIR.Parameter>>:
  match v_16:
    case LowerResult{v_14, v_15}:
      LowerResult{v_14, BIR.Parameter{v_11, BIR.Affine{}} <> v_15}

def native_match_new_parameters_1(v_17: LowerResult<U32>, v_7: Nat) -> LowerResult<List<&2, BIR.Parameter>>:
  match v_17:
    case LowerResult{v_10, v_11}:
      native_match_new_parameters_0(new_parameters(v_10, v_7), v_11)

def native_match_new_parameters_2(v_3: Nat, v_1: State) -> LowerResult<List<&2, BIR.Parameter>>:
  match v_3:
    case 0n:
      LowerResult{v_1, []}
    case 1n+v_7:
      native_match_new_parameters_1(fresh(v_1), v_7)

def new_parameters(v_1: State, v_3: Nat) -> LowerResult<List<&2, BIR.Parameter>>:
  native_match_new_parameters_2(v_3, v_1)

def parameter_values(parameters: List<&2, BIR.Parameter>) -> List<&2, BIR.Atom>:
  match parameters:
    case Nil{}: Nil{}
    case BIR.Parameter{id, _} <> rest: BIR.Local{id} <> parameter_values(rest)
def native_match_checked_cases_0(v_46: LowerResult<BIR.Block>, v_24: U32, v_36: BIR.Block) -> LowerResult<BIR.Block>:
  match v_46:
    case LowerResult{v_39, v_40}:
      LowerResult{v_39, BIR.Region{v_24, v_36, v_40}}

def native_match_checked_cases_1(v_47: LowerResult<BIR.Block>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_20: List<&2, IR.Occurrence>, v_24: U32) -> LowerResult<BIR.Block>:
  match v_47:
    case LowerResult{v_35, v_36}:
      native_match_checked_cases_0(checked_cases(v_35, v_20, v_5, v_8, v_9), v_24, v_36)

def native_match_checked_cases_2(v_48: LowerResult<BIR.Atom>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_20: List<&2, IR.Occurrence>, v_24: U32) -> LowerResult<BIR.Block>:
  match v_48:
    case LowerResult{v_31, v_32}:
      native_match_checked_cases_1(take_block(v_31, v_32), v_5, v_8, v_9, v_20, v_24)

def native_match_checked_cases_3(v_49: LowerResult<List<&2, Slot>>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_19: IR.Occurrence, v_20: List<&2, IR.Occurrence>, v_24: U32) -> LowerResult<BIR.Block>:
  match v_49:
    case LowerResult{v_27, v_28}:
      native_match_checked_cases_2(lower_occurrence(v_27, v_19, v_28, v_9), v_5, v_8, v_9, v_20, v_24)

def native_match_checked_cases_4(v_50: LowerResult<U32>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_18: List<&2, IR.CheckedPattern>, v_19: IR.Occurrence, v_20: List<&2, IR.Occurrence>) -> LowerResult<BIR.Block>:
  match v_50:
    case LowerResult{v_23, v_24}:
      native_match_checked_cases_3(patterns(v_23, v_18, v_5, v_8, v_9, BIR.LeaveRegion{v_24}), v_5, v_8, v_9, v_19, v_20, v_24)

def native_match_checked_cases_5(v_3: List<&2, IR.Occurrence>, v_1: State, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Block>:
  match v_3:
    case []:
      LowerResult{v_1, BIR.Failure{"bend: runtime fail-stop"}}
    case IR.CaseOccurrence{_, _, v_18, v_19} <> v_20:
      native_match_checked_cases_4(fresh(v_1), v_5, v_8, v_9, v_18, v_19, v_20)
    case _ <> _:
      LowerResult{state_problem(v_1, "missing checked match row", no_span), BIR.Failure{"bend: malformed checked match"}}

def checked_cases(v_1: State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Block>:
  native_match_checked_cases_5(v_3, v_1, v_5, v_8, v_9)

def take_block(state: State, value: BIR.Atom) -> LowerResult<BIR.Block>:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure, scope, normalizer}:
      LowerResult{State{source, code, local, Frame{owner, Nil{}, captures, count}, codes, failure, scope, normalizer}, finish(instructions, value)}
def native_match_match_values_0(v_28: LowerResult<CodeRef>, v_5: List<&2, BIR.Atom>) -> LowerResult<BIR.Atom>:
  match v_28:
    case LowerResult{v_26, v_27}:
      call_reference(v_26, v_27, atom_arguments(v_5))

def native_match_match_values_1(v_29: LowerResult<BIR.Block>, v_5: List<&2, BIR.Atom>, v_14: Frame, v_18: List<&2, BIR.Parameter>) -> LowerResult<BIR.Atom>:
  match v_29:
    case LowerResult{v_22, v_23}:
      native_match_match_values_0(leave(v_22, v_14, v_18, v_23), v_5)

def native_match_match_values_2(v_30: LowerResult<List<&2, BIR.Parameter>>, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_14: Frame) -> LowerResult<BIR.Atom>:
  match v_30:
    case LowerResult{v_17, v_18}:
      native_match_match_values_1(checked_cases(v_17, v_3, parameter_values(v_18), v_8, v_9), v_5, v_14, v_18)

def native_match_match_values_3(v_31: LowerResult<Frame>, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_31:
    case LowerResult{v_13, v_14}:
      native_match_match_values_2(new_parameters(v_13, List.length(&2, BIR.Atom, v_5)), v_3, v_5, v_8, v_9, v_14)

def match_values(v_1: State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  native_match_match_values_3(enter(v_1), v_3, v_5, v_8, v_9)

def native_match_split_occurrences_0(v_86: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_12: IR.Occurrence) -> Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>):
  match v_86:
    case (v_17, v_18):
      (v_12 <> v_17, v_18)

def native_match_split_occurrences_1(v_1: U32, v_3: List<&2, IR.Occurrence>) -> Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>):
  match v_1, v_3:
    case 0, _:
      ([], v_3)
    case _, v_12 <> v_13:
      native_match_split_occurrences_0(split_occurrences(U32.sub(v_1, 1), v_13), v_12)
    case _, []:
      ([], [])

def split_occurrences(v_1: U32, v_3: List<&2, IR.Occurrence>) -> Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>):
  native_match_split_occurrences_1(v_1, v_3)

def native_match_lower_match_0(v_21: LowerResult<List<&2, BIR.Atom>>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_15: List<&2, IR.Occurrence>) -> LowerResult<BIR.Atom>:
  match v_21:
    case LowerResult{v_18, v_19}:
      match_values(v_18, v_15, v_19, v_8, v_9)

def native_match_lower_match_1(v_20: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_1: State, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_20:
    case (v_14, v_15):
      native_match_lower_match_0(lower_values(v_1, v_14, v_8, v_9), v_8, v_9, v_15)

def lower_match(v_1: State, v_3: U32, v_5: List<&2, IR.Occurrence>, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  native_match_lower_match_1(split_occurrences(v_3, v_5), v_1, v_8, v_9)

def occurrence_term(occurrence: IR.Occurrence) -> U32:
  match occurrence:
    case IR.TypedOccurrence{term, _, _, _, _, _}: term
    case IR.ScalarOccurrence{term, _, _, _, _}: term
    case IR.StringOccurrence{term, _, _, _}: term
    case IR.CaseOccurrence{term, _, _, _}: term
    case IR.LocalOccurrence{term, _, _, _, _}: term
    case IR.LocalReferenceOccurrence{term, _, _, _}: term

def native_match_lower_0(v_86: LowerResult<Arena.Node>, v_5: List<&2, Slot>, v_6: Catalog.Registry, v_16: Maybe<&2, Ast.Quantity>, v_17: Maybe<&2, IR.Symbol>, v_18: List<&2, IR.CheckedBinding>, v_19: List<&2, IR.Occurrence>) -> LowerResult<BIR.Atom>:
  match v_86:
    case LowerResult{v_22, v_23}:
      lower_node(v_22, v_23, v_16, v_17, v_18, v_19, v_5, v_6)

def native_match_lower_1(v_87: LowerResult<Arena.Node>, v_5: List<&2, Slot>) -> LowerResult<BIR.Atom>:
  match v_87:
    case LowerResult{v_56, v_57}:
      lexical_reference(v_56, v_57, v_5)

def native_match_lower_2(v_88: LowerResult<List<&2, Slot>>, v_6: Catalog.Registry, v_68: IR.Occurrence) -> LowerResult<BIR.Atom>:
  match v_88:
    case LowerResult{v_75, v_76}:
      lower_occurrence(v_75, v_68, v_76, v_6)

def native_match_lower_3(v_89: LowerResult<List<&2, BIR.Atom>>, v_5: List<&2, Slot>, v_6: Catalog.Registry, v_66: List<&2, IR.CheckedPattern>, v_68: IR.Occurrence) -> LowerResult<BIR.Atom>:
  match v_89:
    case LowerResult{v_71, v_72}:
      native_match_lower_2(patterns(v_71, v_66, v_72, v_5, v_6, BIR.Failure{"bend: runtime fail-stop"}), v_6, v_68)

def native_match_lower_4(v_2: IR.Occurrence, v_1: State, v_5: List<&2, Slot>, v_6: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_2:
    case IR.TypedOccurrence{v_14, _, v_16, v_17, v_18, v_19}:
      native_match_lower_0(node(v_1, v_14), v_5, v_6, v_16, v_17, v_18, v_19)
    case IR.ScalarOccurrence{_, _, v_32, v_33, v_34}:
      scalar_literal(v_1, Catalog.lookup_constructor(v_6, v_32), v_33, v_34, v_6)
    case IR.StringOccurrence{_, _, v_42, v_43}:
      literal_string(v_1, v_6, v_43, v_42, no_span)
    case IR.LocalReferenceOccurrence{v_50, _, _, _}:
      native_match_lower_1(node(v_1, v_50), v_5)
    case IR.LocalOccurrence{_, _, v_66, v_67, v_68}:
      native_match_lower_3(local_values(v_1, v_66, v_67, v_5, v_6), v_5, v_6, v_66, v_68)
    case IR.CaseOccurrence{_, _, _, _}:
      fail(v_1, "checked case escaped its match", no_span)

def lower_occurrence(v_1: State, v_2: IR.Occurrence, v_5: List<&2, Slot>, v_6: Catalog.Registry) -> LowerResult<BIR.Atom>:
  native_match_lower_4(v_2, v_1, v_5, v_6)

def lexical_reference(state: State, shape: Arena.Node, env: List<&2, Slot>) -> LowerResult<BIR.Atom>:
  match shape:
    case Arena.TermVar{_, index, span}: variable(state, env, index, span)
    case _: fail(state, "checked local reference lost lexical identity", no_span())
def native_match_lower_node_0(v_244: LowerResult<String>) -> LowerResult<BIR.Atom>:
  match v_244:
    case LowerResult{v_174, v_175}:
      LowerResult{push(v_174, Stop{BIR.Failure{String.append("bend: unsolved hole ", v_175)}}), BIR.Null{}}

def native_match_lower_node_1(v_2: Arena.Node, v_1: State, v_4: Maybe<&2, Ast.Quantity>, v_6: Maybe<&2, IR.Symbol>, v_8: List<&2, IR.CheckedBinding>, v_10: List<&2, IR.Occurrence>, v_13: List<&2, Slot>, v_14: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_2:
    case Arena.TermVar{_, v_20, v_21}:
      variable(v_1, v_13, v_20, v_21)
    case Arena.TermRef{_, v_26}:
      resolved_reference(v_1, v_6, v_14, v_26)
    case Arena.TermBang{_, v_31}:
      only_child(v_1, v_10, v_13, v_14, v_31)
    case Arena.TermAnn{_, _, v_38}:
      annotated_child(v_1, v_10, v_13, v_14, v_38)
    case Arena.TermLam{_, _, _, _, v_49}:
      lambda_checked(v_1, v_4, v_10, v_13, v_14, v_49)
    case Arena.TermApp{_, _, v_56}:
      application_checked(v_1, v_4, v_10, v_13, v_14, v_56)
    case Arena.TermCtr{_, _, _, v_65}:
      constructor_checked(v_1, v_6, v_8, v_10, v_13, v_14, v_65)
    case Arena.TermLet{_, _, _, _, _, _, _, v_84, _, v_86}:
      let_checked(v_1, v_84, v_8, v_10, v_13, v_14, v_86)
    case Arena.BodyMatch{_, v_94, _, _, _}:
      lower_match(v_1, v_94, v_10, v_13, v_14)
    case Arena.TermMat{_, _, _, v_106}:
      matcher_checked(v_1, v_4, v_6, v_10, v_13, v_14, v_106)
    case Arena.TermAbsurd{v_109}:
      absurd_checked(v_1, v_4, v_109)
    case Arena.TermRewrite{_, _, _, v_118}:
      rewrite_checked(v_1, v_10, v_13, v_14, v_118)
    case Arena.TermType{_, _}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermQuant{}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermQuantity{_, _}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermMin{_, _, _}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermAll{_, _, _, _, _, _}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermAdt{_, _, _, _, _, _}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermEqual{_, _, _, _}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermRefl{_}:
      LowerResult{v_1, BIR.Null{}}
    case Arena.TermHole{v_170, v_171}:
      native_match_lower_node_0(name(v_1, v_170))
    case Arena.TermTemplate{_, v_180}:
      fail(v_1, "unexpanded template reached JS emission", v_180)
    case Arena.TermString{_, _, v_187}:
      fail(v_1, "missing checked string literal certificate", v_187)
    case Arena.TermSub{_, _, _, v_196}:
      fail(v_1, "unelaborated substitution reached lowering", v_196)
    case Arena.TermFill{_, _, _, v_205}:
      fail(v_1, "unelaborated fill reached lowering", v_205)
    case Arena.TermPlus{_, _, _, v_214}:
      fail(v_1, "unelaborated plus reached lowering", v_214)
    case Arena.BodyCase{_, _, _, v_223}:
      fail(v_1, "missing checked case facts", v_223)
    case Arena.BodyLocal{_, _, _, _, _, _, v_238}:
      fail(v_1, "missing checked local facts", v_238)
    case Arena.BodyReply{_, v_243}:
      fail(v_1, "unelaborated reply reached lowering", v_243)

def lower_node(v_1: State, v_2: Arena.Node, v_4: Maybe<&2, Ast.Quantity>, v_6: Maybe<&2, IR.Symbol>, v_8: List<&2, IR.CheckedBinding>, v_10: List<&2, IR.Occurrence>, v_13: List<&2, Slot>, v_14: Catalog.Registry) -> LowerResult<BIR.Atom>:
  native_match_lower_node_1(v_2, v_1, v_4, v_6, v_8, v_10, v_13, v_14)

def resolved_reference(state: State, symbol: Maybe<&2, IR.Symbol>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match symbol:
    case Some{value}: symbol_value(state, value, registry, span)
    case None{}: fail(state, "missing checked reference identity", span)
def only_child(state: State, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match children:
    case child <> Nil{}: lower_occurrence(state, child, env, registry)
    case _: fail(state, "incomplete checked unary operand", span)
def annotated_child(state: State, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match children:
    case child <> _ <> Nil{}: lower_occurrence(state, child, env, registry)
    case _: fail(state, "incomplete checked annotation", span)
def rewrite_checked(state: State, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match children:
    case _ <> _ <> body <> Nil{}: lower_occurrence(state, body, env, registry)
    case _: fail(state, "incomplete checked rewrite", span)
def native_match_application_checked_0(v_29: LowerResult<Spine>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_29:
    case LowerResult{v_20, v_21}:
      applications(v_20, v_21, v_8, v_9, v_10)

def native_match_application_checked_1(v_3: Maybe<&2, Ast.Quantity>, v_5: List<&2, IR.Occurrence>, v_1: State, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3, v_5:
    case Some{v_15}, [v_16, v_17]:
      native_match_application_checked_0(spine(v_1, v_16, [SourceArgument{v_15, v_17}]), v_8, v_9, v_10)
    case _, _:
      fail(v_1, "missing checked application quantity/operands", v_10)

def application_checked(v_1: State, v_3: Maybe<&2, Ast.Quantity>, v_5: List<&2, IR.Occurrence>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_application_checked_1(v_3, v_5, v_1, v_8, v_9, v_10)

def native_match_constructor_checked_0(v_21: LowerResult<List<&2, BIR.Atom>>, v_11: Catalog.Registry, v_12: Ast.SourceSpan, v_16: IR.Symbol, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_21:
    case LowerResult{v_19, v_20}:
      construct_symbol(v_19, v_11, v_16, v_20, v_12, element)

def native_match_constructor_checked_1(v_3: Maybe<&2, IR.Symbol>, v_1: State, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, Slot>, v_11: Catalog.Registry, v_12: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3:
    case None{}:
      fail(v_1, "missing checked constructor identity", v_12)
    case Some{v_16}:
      native_match_constructor_checked_0(constructor_operands(v_1, v_7, v_5, v_10, v_11, v_12), v_11, v_12, v_16, first_occurrence_type(v_7))

def constructor_checked(v_1: State, v_3: Maybe<&2, IR.Symbol>, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, Slot>, v_11: Catalog.Registry, v_12: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_constructor_checked_1(v_3, v_1, v_5, v_7, v_10, v_11, v_12)

def native_match_lambda_checked_0(v_49: LowerResult<CodeRef>) -> LowerResult<BIR.Atom>:
  match v_49:
    case LowerResult{v_39, v_40}:
      close(v_39, v_40)

def native_match_lambda_checked_1(v_50: LowerResult<BIR.Atom>, v_17: Ast.Quantity, v_22: Frame, v_26: U32) -> LowerResult<BIR.Atom>:
  match v_50:
    case LowerResult{v_34, v_35}:
      native_match_lambda_checked_0(leave_value(v_34, v_22, [BIR.Parameter{v_26, use(v_17)}], v_35))

def native_match_lambda_checked_2(v_51: LowerResult<Slot>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_17: Ast.Quantity, v_18: IR.Occurrence, v_22: Frame, v_26: U32) -> LowerResult<BIR.Atom>:
  match v_51:
    case LowerResult{v_30, v_31}:
      native_match_lambda_checked_1(lower_occurrence(v_30, v_18, v_31 <> v_8, v_9), v_17, v_22, v_26)

def native_match_lambda_checked_3(v_52: LowerResult<U32>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_17: Ast.Quantity, v_18: IR.Occurrence, v_22: Frame) -> LowerResult<BIR.Atom>:
  match v_52:
    case LowerResult{v_25, v_26}:
      native_match_lambda_checked_2(bind_slot(v_25, BIR.Local{v_26}, use(v_17)), v_8, v_9, v_17, v_18, v_22, v_26)

def native_match_lambda_checked_4(v_53: LowerResult<Frame>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_17: Ast.Quantity, v_18: IR.Occurrence) -> LowerResult<BIR.Atom>:
  match v_53:
    case LowerResult{v_21, v_22}:
      native_match_lambda_checked_3(fresh(v_21), v_8, v_9, v_17, v_18, v_22)

def native_match_lambda_checked_5(v_3: Maybe<&2, Ast.Quantity>, v_5: List<&2, IR.Occurrence>, v_1: State, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3, v_5:
    case Some{Ast.QZero{}}, [v_13]:
      lower_occurrence(v_1, v_13, ErasedSlot{} <> v_8, v_9)
    case Some{v_17}, [v_18]:
      native_match_lambda_checked_4(enter(v_1), v_8, v_9, v_17, v_18)
    case _, _:
      fail(v_1, "missing checked lambda quantity/body", v_10)

def lambda_checked(v_1: State, v_3: Maybe<&2, Ast.Quantity>, v_5: List<&2, IR.Occurrence>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_10: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_lambda_checked_5(v_3, v_5, v_1, v_8, v_9, v_10)

def native_match_absurd_checked_0(v_23: LowerResult<CodeRef>) -> LowerResult<BIR.Atom>:
  match v_23:
    case LowerResult{v_20, v_21}:
      close(v_20, v_21)

def native_match_absurd_checked_1(v_24: LowerResult<U32>, v_8: Ast.Quantity, v_12: Frame) -> LowerResult<BIR.Atom>:
  match v_24:
    case LowerResult{v_15, v_16}:
      native_match_absurd_checked_0(leave(v_15, v_12, [BIR.Parameter{v_16, use(v_8)}], BIR.Failure{"bend: runtime fail-stop"}))

def native_match_absurd_checked_2(v_25: LowerResult<Frame>, v_8: Ast.Quantity) -> LowerResult<BIR.Atom>:
  match v_25:
    case LowerResult{v_11, v_12}:
      native_match_absurd_checked_1(fresh(v_11), v_8, v_12)

def native_match_absurd_checked_3(v_3: Maybe<&2, Ast.Quantity>, v_1: State, v_4: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3:
    case Some{Ast.QZero{}}:
      fail(v_1, "erased absurd scrutinee reached live lowering", v_4)
    case Some{v_8}:
      native_match_absurd_checked_2(enter(v_1), v_8)
    case None{}:
      fail(v_1, "missing checked absurd quantity", v_4)

def absurd_checked(v_1: State, v_3: Maybe<&2, Ast.Quantity>, v_4: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_absurd_checked_3(v_3, v_1, v_4)

def native_match_local_values_0(v_48: LowerResult<List<&2, BIR.Atom>>) -> LowerResult<List<&2, BIR.Atom>>:
  match v_48:
    case LowerResult{v_25, v_26}:
      LowerResult{v_25, BIR.Null{} <> v_26}

def native_match_local_values_1(v_49: LowerResult<List<&2, BIR.Atom>>, v_37: BIR.Atom) -> LowerResult<List<&2, BIR.Atom>>:
  match v_49:
    case LowerResult{v_39, v_40}:
      LowerResult{v_39, v_37 <> v_40}

def native_match_local_values_2(v_50: LowerResult<BIR.Atom>, v_8: List<&2, Slot>, v_9: Catalog.Registry, v_32: List<&2, IR.CheckedPattern>, v_34: List<&2, IR.Occurrence>) -> LowerResult<List<&2, BIR.Atom>>:
  match v_50:
    case LowerResult{v_36, v_37}:
      native_match_local_values_1(local_values(v_36, v_32, v_34, v_8, v_9), v_37)

def native_match_local_values_3(v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, IR.Occurrence>, v_1: State, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<List<&2, BIR.Atom>>:
  match v_3, v_5:
    case [], []:
      LowerResult{v_1, []}
    case IR.CheckedVariable{_, IR.CheckedBinding{Ast.QZero{}, _, _}} <> v_21, _ <> v_23:
      native_match_local_values_0(local_values(v_1, v_21, v_23, v_8, v_9))
    case _ <> v_32, v_33 <> v_34:
      native_match_local_values_2(lower_occurrence(v_1, v_33, v_8, v_9), v_8, v_9, v_32, v_34)
    case _, _:
      LowerResult{state_problem(v_1, "incomplete checked local values", no_span), []}

def local_values(v_1: State, v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, IR.Occurrence>, v_8: List<&2, Slot>, v_9: Catalog.Registry) -> LowerResult<List<&2, BIR.Atom>>:
  native_match_local_values_3(v_3, v_5, v_1, v_8, v_9)

def native_match_let_checked_0(v_27: LowerResult<List<&2, Slot>>, v_11: Catalog.Registry, v_18: IR.Occurrence) -> LowerResult<BIR.Atom>:
  match v_27:
    case LowerResult{v_21, v_22}:
      lower_occurrence(v_21, v_18, v_22, v_11)

def native_match_let_checked_1(v_26: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_1: State, v_5: List<&2, IR.CheckedBinding>, v_10: List<&2, Slot>, v_11: Catalog.Registry, v_12: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_26:
    case (v_17, [v_18]):
      native_match_let_checked_0(let_bindings(v_1, v_17, v_5, v_10, v_10, v_11, v_12), v_11, v_18)
    case _:
      fail(v_1, "incomplete checked let body", v_12)

def let_checked(v_1: State, v_3: U32, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, Slot>, v_11: Catalog.Registry, v_12: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_let_checked_1(split_occurrences(v_3, v_7), v_1, v_5, v_10, v_11, v_12)

def native_match_let_bindings_0(v_55: LowerResult<Slot>, v_8: List<&2, Slot>, v_11: List<&2, Slot>, v_12: Catalog.Registry, v_13: Ast.SourceSpan, v_35: List<&2, IR.Occurrence>, v_39: List<&2, IR.CheckedBinding>) -> LowerResult<List<&2, Slot>>:
  match v_55:
    case LowerResult{v_46, v_47}:
      let_bindings(v_46, v_35, v_39, v_8, v_47 <> v_11, v_12, v_13)

def native_match_let_bindings_1(v_56: LowerResult<BIR.Atom>, v_8: List<&2, Slot>, v_11: List<&2, Slot>, v_12: Catalog.Registry, v_13: Ast.SourceSpan, v_35: List<&2, IR.Occurrence>, v_36: Ast.Quantity, v_39: List<&2, IR.CheckedBinding>) -> LowerResult<List<&2, Slot>>:
  match v_56:
    case LowerResult{v_41, v_42}:
      native_match_let_bindings_0(bind_slot(v_41, v_42, use(v_36)), v_8, v_11, v_12, v_13, v_35, v_39)

def native_match_let_bindings_2(v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_1: State, v_8: List<&2, Slot>, v_11: List<&2, Slot>, v_12: Catalog.Registry, v_13: Ast.SourceSpan) -> LowerResult<List<&2, Slot>>:
  match v_3, v_5:
    case [], []:
      LowerResult{v_1, v_11}
    case _ <> v_23, IR.CheckedBinding{Ast.QZero{}, _, _} <> v_26:
      let_bindings(v_1, v_23, v_26, v_8, ErasedSlot{} <> v_11, v_12, v_13)
    case v_34 <> v_35, IR.CheckedBinding{v_36, _, _} <> v_39:
      native_match_let_bindings_1(lower_occurrence(v_1, v_34, v_8, v_12), v_8, v_11, v_12, v_13, v_35, v_36, v_39)
    case _, _:
      LowerResult{state_problem(v_1, "incomplete checked let bindings", v_13), v_11}

def let_bindings(v_1: State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_8: List<&2, Slot>, v_11: List<&2, Slot>, v_12: Catalog.Registry, v_13: Ast.SourceSpan) -> LowerResult<List<&2, Slot>>:
  native_match_let_bindings_2(v_3, v_5, v_1, v_8, v_11, v_12, v_13)

def scalar_literal(state: State, found: Maybe<&2, Catalog.Constructor>, bits: U32, symbols: List<&2, IR.Symbol>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match found:
    case None{}: fail(state, "missing certified scalar constructor", no_span())
    case Some{constructor}: scalar_literal_native(state, constructor_native(constructor), constructor, bits, symbols, registry)
def native_match_scalar_literal_native_0(v_510: LowerResult<BIR.Atom>, v_4: Catalog.Constructor) -> LowerResult<BIR.Atom>:
  match v_510:
    case LowerResult{v_24, v_25}:
      construct(v_24, v_4, [v_25], no_span, None{})

def native_match_scalar_literal_native_1(v_8: List<&2, IR.Symbol>, v_1: State, v_4: Catalog.Constructor, v_6: U32, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_8:
    case [v_17, v_18, v_19, v_20]:
      native_match_scalar_literal_native_0(literal_word(v_1, v_9, 32n, v_6, v_17, v_18, v_19, v_20, no_span), v_4)
    case _:
      fail(v_1, "incomplete certified scalar identities", no_span)

def native_match_scalar_literal_native_2(v_3: String, v_1: State, v_4: Catalog.Constructor, v_6: U32, v_8: List<&2, IR.Symbol>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match v_3:
    case "U32.U32":
      LowerResult{v_1, BIR.Word{v_6}}
    case "F32.F32":
      LowerResult{v_1, BIR.FloatBits{v_6}}
    case _:
      native_match_scalar_literal_native_1(v_8, v_1, v_4, v_6, v_9)

def scalar_literal_native(v_1: State, v_3: String, v_4: Catalog.Constructor, v_6: U32, v_8: List<&2, IR.Symbol>, v_9: Catalog.Registry) -> LowerResult<BIR.Atom>:
  native_match_scalar_literal_native_2(v_3, v_1, v_4, v_6, v_8, v_9)

def take_instructions(state: State) -> LowerResult<List<&2, Instruction>>:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure, scope, normalizer}:
      LowerResult{State{source, code, local, Frame{owner, Nil{}, captures, count}, codes, failure, scope, normalizer}, instructions}
def matcher_checked(state: State, formal: Maybe<&2, Ast.Quantity>, symbol: Maybe<&2, IR.Symbol>, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match formal symbol children:
    case Some{Ast.QZero{}} _ _: fail(state, "erased matcher scrutinee reached live lowering", span)
    case Some{quantity} Some{constructor} head <> fallback <> Nil{}:
      matcher_constructor(state, Catalog.lookup_constructor(registry, constructor), quantity, head, fallback, env, registry, span)
    case _ _ _: fail(state, "incomplete checked matcher facts", span)
def native_match_matcher_constructor_0(v_66: LowerResult<CodeRef>) -> LowerResult<BIR.Atom>:
  match v_66:
    case LowerResult{v_64, v_65}:
      close(v_64, v_65)

def native_match_matcher_constructor_1(v_67: LowerResult<BIR.Block>, v_4: Ast.Quantity, v_19: Frame, v_23: U32, v_27: BIR.Atom, v_31: List<&2, Instruction>, v_44: BIR.Block) -> LowerResult<BIR.Atom>:
  match v_67:
    case LowerResult{v_56, v_57}:
      v_60 = prefix(v_31, BIR.Branch{v_27, v_44, v_57})
      native_match_matcher_constructor_0(leave(v_56, v_19, [BIR.Parameter{v_23, use(v_4)}], v_60))

def native_match_matcher_constructor_2(v_68: LowerResult<BIR.Atom>, v_4: Ast.Quantity, v_19: Frame, v_23: U32, v_27: BIR.Atom, v_31: List<&2, Instruction>, v_44: BIR.Block) -> LowerResult<BIR.Atom>:
  match v_68:
    case LowerResult{v_52, v_53}:
      native_match_matcher_constructor_1(take_block(v_52, v_53), v_4, v_19, v_23, v_27, v_31, v_44)

def native_match_matcher_constructor_3(v_69: LowerResult<BIR.Atom>, v_4: Ast.Quantity, v_19: Frame, v_23: U32, v_27: BIR.Atom, v_31: List<&2, Instruction>, v_44: BIR.Block) -> LowerResult<BIR.Atom>:
  match v_69:
    case LowerResult{v_47, v_48}:
      native_match_matcher_constructor_2(operation(v_47, BIR.Apply{v_48, BIR.Arg{use(v_4), BIR.Local{v_23}}}), v_4, v_19, v_23, v_27, v_31, v_44)

def native_match_matcher_constructor_4(v_70: LowerResult<BIR.Block>, v_4: Ast.Quantity, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_19: Frame, v_23: U32, v_27: BIR.Atom, v_31: List<&2, Instruction>) -> LowerResult<BIR.Atom>:
  match v_70:
    case LowerResult{v_43, v_44}:
      native_match_matcher_constructor_3(lower_occurrence(v_43, v_6, v_9, v_10), v_4, v_19, v_23, v_27, v_31, v_44)

def native_match_matcher_constructor_5(v_71: LowerResult<BIR.Atom>, v_4: Ast.Quantity, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_19: Frame, v_23: U32, v_27: BIR.Atom, v_31: List<&2, Instruction>) -> LowerResult<BIR.Atom>:
  match v_71:
    case LowerResult{v_39, v_40}:
      native_match_matcher_constructor_4(take_block(v_39, v_40), v_4, v_6, v_9, v_10, v_19, v_23, v_27, v_31)

def native_match_matcher_constructor_6(v_72: LowerResult<BIR.Atom>, v_4: Ast.Quantity, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_11: Ast.SourceSpan, v_15: Catalog.Constructor, v_19: Frame, v_23: U32, v_27: BIR.Atom, v_31: List<&2, Instruction>, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_72:
    case LowerResult{v_34, v_35}:
      native_match_matcher_constructor_5(matcher_fields(v_34, v_15, constructor_quantities(v_15), BIR.Local{v_23}, 0, v_35, v_4, v_11, element), v_4, v_6, v_9, v_10, v_19, v_23, v_27, v_31)

def native_match_matcher_constructor_7(v_73: LowerResult<List<&2, Instruction>>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_11: Ast.SourceSpan, v_15: Catalog.Constructor, v_19: Frame, v_23: U32, v_27: BIR.Atom) -> LowerResult<BIR.Atom>:
  match v_73:
    case LowerResult{v_30, v_31}:
      native_match_matcher_constructor_6(lower_occurrence(v_30, v_5, v_9, v_10), v_4, v_6, v_9, v_10, v_11, v_15, v_19, v_23, v_27, v_31, occurrence_type(v_5))

def native_match_matcher_constructor_8(v_74: LowerResult<BIR.Atom>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_11: Ast.SourceSpan, v_15: Catalog.Constructor, v_19: Frame, v_23: U32) -> LowerResult<BIR.Atom>:
  match v_74:
    case LowerResult{v_26, v_27}:
      native_match_matcher_constructor_7(take_instructions(v_26), v_4, v_5, v_6, v_9, v_10, v_11, v_15, v_19, v_23, v_27)

def native_match_matcher_constructor_9(v_75: LowerResult<U32>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_11: Ast.SourceSpan, v_15: Catalog.Constructor, v_19: Frame) -> LowerResult<BIR.Atom>:
  match v_75:
    case LowerResult{v_22, v_23}:
      native_match_matcher_constructor_8(tag(v_22, v_15, BIR.Local{v_23}, occurrence_type(v_5)), v_4, v_5, v_6, v_9, v_10, v_11, v_15, v_19, v_23)

def native_match_matcher_constructor_10(v_76: LowerResult<Frame>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_11: Ast.SourceSpan, v_15: Catalog.Constructor) -> LowerResult<BIR.Atom>:
  match v_76:
    case LowerResult{v_18, v_19}:
      native_match_matcher_constructor_9(fresh(v_18), v_4, v_5, v_6, v_9, v_10, v_11, v_15, v_19)

def native_match_matcher_constructor_11(v_3: Maybe<&2, Catalog.Constructor>, v_1: State, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_11: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match v_3:
    case None{}:
      fail(v_1, "missing checked matcher constructor", v_11)
    case Some{v_15}:
      native_match_matcher_constructor_10(enter(v_1), v_4, v_5, v_6, v_9, v_10, v_11, v_15)

def matcher_constructor(v_1: State, v_3: Maybe<&2, Catalog.Constructor>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, Slot>, v_10: Catalog.Registry, v_11: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  native_match_matcher_constructor_11(v_3, v_1, v_4, v_5, v_6, v_9, v_10, v_11)

def constructor_quantities(constructor: Catalog.Constructor) -> List<&2, BIR.Quantity>:
  match constructor:
    case Catalog.Constructor{_, quantities, _, _}: quantities
def matcher_field_use(quantity: BIR.Quantity, input: Ast.Quantity) -> BIR.Use:
  match quantity:
    case BIR.Unrestricted{}: BIR.Many{}
    case _: use(input)
def native_match_matcher_fields_0(v_28: LowerResult<BIR.Atom>, v_2: Catalog.Constructor, v_5: BIR.Atom, v_7: U32, v_9: Ast.Quantity, v_10: Ast.SourceSpan, v_18: List<&2, BIR.Quantity>, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_28:
    case LowerResult{v_25, v_26}:
      matcher_fields(v_25, v_2, v_18, v_5, U32.inc(v_7), v_26, v_9, v_10, element)

def native_match_matcher_fields_1(v_29: LowerResult<BIR.Atom>, v_2: Catalog.Constructor, v_5: BIR.Atom, v_7: U32, v_8: BIR.Atom, v_9: Ast.Quantity, v_10: Ast.SourceSpan, v_17: BIR.Quantity, v_18: List<&2, BIR.Quantity>, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_29:
    case LowerResult{v_21, v_22}:
      native_match_matcher_fields_0(operation(v_21, BIR.Apply{v_8, BIR.Arg{matcher_field_use(v_17, v_9), v_22}}), v_2, v_5, v_7, v_9, v_10, v_18, element)

def native_match_matcher_fields_2(v_4: List<&2, BIR.Quantity>, v_1: State, v_2: Catalog.Constructor, v_5: BIR.Atom, v_7: U32, v_8: BIR.Atom, v_9: Ast.Quantity, v_10: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  match v_4:
    case []:
      LowerResult{v_1, v_8}
    case BIR.Erased{} <> v_13:
      matcher_fields(v_1, v_2, v_13, v_5, U32.inc(v_7), v_8, v_9, v_10, element)
    case v_17 <> v_18:
      native_match_matcher_fields_1(project(v_1, v_2, v_5, v_7, v_10, element), v_2, v_5, v_7, v_8, v_9, v_10, v_17, v_18, element)

def matcher_fields(v_1: State, v_2: Catalog.Constructor, v_4: List<&2, BIR.Quantity>, v_5: BIR.Atom, v_7: U32, v_8: BIR.Atom, v_9: Ast.Quantity, v_10: Ast.SourceSpan, element: Maybe<&2, U32>) -> LowerResult<BIR.Atom>:
  native_match_matcher_fields_2(v_4, v_1, v_2, v_5, v_7, v_8, v_9, v_10, element)

def native_match_definition_frame_0(v_20: State, v_3: U32, scope: Scope.ArenaGlobalScope) -> State:
  match v_20:
    case State{v_14, v_15, v_16, _, v_18, v_19, _, normalizer}:
      State{v_14, v_15, v_16, Frame{v_3, [], [], 0}, v_18, v_19, Some{scope}, normalizer}

def definition_frame(v_1: State, v_3: U32, v_5: U32, scope: Scope.ArenaGlobalScope) -> State:
  native_match_definition_frame_0(reserve(v_1, v_5), v_3, scope)

def definition_env(state: State, quantities: List<&2, BIR.Quantity>, parameters: List<&2, BIR.Parameter>, owner: U32, env: List<&2, Slot>) -> LowerResult<List<&2, Slot>>:
  match quantities parameters:
    case Nil{} Nil{}: LowerResult{state, env}
    case BIR.Erased{} <> rest _: definition_env(state, rest, parameters, owner, ErasedSlot{} <> env)
    case _ <> rest BIR.Parameter{id, usage} <> more:
      definition_env(state, rest, more, owner, Slot{owner, id, BIR.Local{id}, usage} <> env)
    case _ _: LowerResult{state_problem(state, "declaration telescope/live parameter mismatch", no_span()), env}
def definitions(state: State, items: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match items:
    case Nil{}: LowerResult{state, List.reverse(&2, BIR.Declaration, result)}
    case Catalog.Definition{header, _, _, _, checked, scope, _, _} <> rest:
      definition(state, header, checked, rest, registry, result, scope)
def definition(state: State, header: Catalog.DefinitionHeader, checked: Maybe<&2, IR.Occurrence>, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>, scope: Scope.ArenaGlobalScope) -> LowerResult<List<&2, BIR.Declaration>>:
  match header:
    case Catalog.DefinitionHeader{_, key, code, parameters, quantities, type_only, primitive, foreign, _}:
      definition_kind(state, key, code, parameters, quantities, type_only, primitive, foreign, checked, rest, registry, result, scope)
def definition_kind(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, Catalog.Foreign>, checked: Maybe<&2, IR.Occurrence>, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>, scope: Scope.ArenaGlobalScope) -> LowerResult<List<&2, BIR.Declaration>>:
  match foreign:
    case Some{Catalog.Foreign{namespace, imported, sources, span, parameter_types, foreign_result}}:
      definitions(state, rest, registry, BIR.ForeignDeclaration{key, namespace, imported, List.length(&2, BIR.Parameter, parameters), sources, quantities, span, parameter_types, foreign_result} <> result)
    case None{}:
      definition_local(state, key, code, parameters, quantities, type_only, primitive, checked, rest, registry, result, scope)
def definition_local(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, checked: Maybe<&2, IR.Occurrence>, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>, scope: Scope.ArenaGlobalScope) -> LowerResult<List<&2, BIR.Declaration>>:
  match type_only primitive:
    case True{} _: definitions(state, rest, registry, result)
    case False{} Some{native}: definitions(state, rest, registry, BIR.NativeDeclaration{key, native, quantities} <> result)
    case False{} None{}:
      definition_body(state, key, code, parameters, quantities, checked, rest, registry, result, scope)
# Header locals are already evaluated and remain in this code's lexical frame.
# A subset or permutation needs no match closure; preserve the original header,
# scrutinee order and case environment. Never inline lazy symbols or new effects.
def definition_parameter(id: U32, parameters: List<&2, BIR.Parameter>) -> Bool:
  match parameters:
    case Nil{}: False{}
    case BIR.Parameter{parameter, _} <> rest:
      Bool.or(U32.is_eq(id, parameter), definition_parameter(id, rest))
def definition_locals(values: List<&2, BIR.Atom>, parameters: List<&2, BIR.Parameter>) -> Bool:
  match values:
    case Nil{}: True{}
    case BIR.Local{id} <> rest:
      Bool.and(definition_parameter(id, parameters), definition_locals(rest, parameters))
    case _ <> _: False{}
def definition_locals_frame(frame: Frame, values: List<&2, BIR.Atom>, parameters: List<&2, BIR.Parameter>) -> Bool:
  match frame values:
    case Frame{_, Nil{}, Nil{}, 0} _ <> _:
      definition_locals(values, parameters)
    case _ _: False{}
def definition_atom_block(result: LowerResult<BIR.Atom>) -> LowerResult<BIR.Block>:
  match result:
    case LowerResult{state, value}: take_block(state, value)
def definition_match_direct(direct: Bool, state: State, cases: List<&2, IR.Occurrence>, values: List<&2, BIR.Atom>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Block>:
  match direct:
    case True{}: checked_cases(state, cases, values, env, registry)
    case False{}: definition_atom_block(match_values(state, cases, values, env, registry))
def definition_match_state(state: State, cases: List<&2, IR.Occurrence>, values: List<&2, BIR.Atom>, env: List<&2, Slot>, registry: Catalog.Registry, parameters: List<&2, BIR.Parameter>) -> LowerResult<BIR.Block>:
  match state:
    case State{source, next_code, local, frame, codes, failure, scope, normalizer}:
      definition_match_direct(definition_locals_frame(frame, values, parameters), State{source, next_code, local, frame, codes, failure, scope, normalizer}, cases, values, env, registry)
def definition_match_values(result: LowerResult<List<&2, BIR.Atom>>, cases: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, parameters: List<&2, BIR.Parameter>) -> LowerResult<BIR.Block>:
  match result:
    case LowerResult{state, values}:
      definition_match_state(state, cases, values, env, registry, parameters)
def definition_match_parts(parts: Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>), state: State, env: List<&2, Slot>, registry: Catalog.Registry, parameters: List<&2, BIR.Parameter>) -> LowerResult<BIR.Block>:
  match parts:
    case (values, cases):
      definition_match_values(lower_values(state, values, env, registry), cases, env, registry, parameters)
def definition_root_node(result: LowerResult<Arena.Node>, occurrence: IR.Occurrence, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, parameters: List<&2, BIR.Parameter>) -> LowerResult<BIR.Block>:
  match result:
    case LowerResult{state, Arena.BodyMatch{_, count, _, _, _}}:
      definition_match_parts(split_occurrences(count, children), state, env, registry, parameters)
    case LowerResult{state, shape}:
      definition_root_other(occurrence, state, shape, env, registry)
def definition_root_other(occurrence: IR.Occurrence, state: State, shape: Arena.Node, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Block>:
  match occurrence:
    case IR.TypedOccurrence{_, _, quantity, symbol, bindings, children}:
      definition_atom_block(lower_node(state, shape, quantity, symbol, bindings, children, env, registry))
    case _:
      definition_atom_block(lower_occurrence(state, occurrence, env, registry))
def definition_root(state: State, occurrence: IR.Occurrence, env: List<&2, Slot>, registry: Catalog.Registry, parameters: List<&2, BIR.Parameter>) -> LowerResult<BIR.Block>:
  match occurrence:
    case IR.TypedOccurrence{term, _, _, _, _, children}:
      definition_root_node(node(state, term), occurrence, children, env, registry, parameters)
    case _:
      definition_atom_block(lower_occurrence(state, occurrence, env, registry))

def native_match_definition_body_0(v_38: LowerResult<BIR.Block>, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_13: List<&2, Catalog.Definition>, v_14: Catalog.Registry, v_16: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match v_38:
    case LowerResult{v_36, v_37}:
      definition_complete(v_36, v_3, v_5, v_7, v_37, v_13, v_14, v_16)

def native_match_definition_body_2(v_40: LowerResult<List<&2, Slot>>, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_13: List<&2, Catalog.Definition>, v_14: Catalog.Registry, v_16: List<&2, BIR.Declaration>, v_23: IR.Occurrence) -> LowerResult<List<&2, BIR.Declaration>>:
  match v_40:
    case LowerResult{v_28, v_29}:
      native_match_definition_body_0(definition_root(v_28, v_23, v_29, v_14, v_7), v_3, v_5, v_7, v_13, v_14, v_16)

def native_match_definition_body_3(v_11: Maybe<&2, IR.Occurrence>, v_1: State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_13: List<&2, Catalog.Definition>, v_14: Catalog.Registry, v_16: List<&2, BIR.Declaration>, scope: Scope.ArenaGlobalScope) -> LowerResult<List<&2, BIR.Declaration>>:
  match v_11:
    case None{}:
      definitions(state_problem(v_1, String.append("missing checked body: ", v_3), no_span), v_13, v_14, v_16)
    case Some{v_23}:
      v_25 = definition_frame(v_1, v_5, U32.from_nat(List.length(&2, BIR.Quantity, v_9)), scope)
      native_match_definition_body_2(definition_env(v_25, v_9, v_7, v_5, []), v_3, v_5, v_7, v_13, v_14, v_16, v_23)

def definition_body(v_1: State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_11: Maybe<&2, IR.Occurrence>, v_13: List<&2, Catalog.Definition>, v_14: Catalog.Registry, v_16: List<&2, BIR.Declaration>, scope: Scope.ArenaGlobalScope) -> LowerResult<List<&2, BIR.Declaration>>:
  native_match_definition_body_3(v_11, v_1, v_3, v_5, v_7, v_9, v_13, v_14, v_16, scope)

def definition_complete(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, body: BIR.Block, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match state:
    case State{source, next_code, local, Frame{owner, instructions, captures, count}, codes, failure, scope, normalizer}:
      definition_closed(U32.is_eq(count, 0), State{source, next_code, local, Frame{owner, instructions, captures, count}, codes, failure, scope, normalizer}, key, code, parameters, body, rest, registry, result)
def native_match_definition_closed_0(v_3: State, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_10: BIR.Block, v_12: List<&2, Catalog.Definition>, v_13: Catalog.Registry, v_15: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match v_3:
    case State{v_32, v_33, v_34, v_35, v_36, v_37, scope, normalizer}:
      definitions(State{v_32, v_33, v_34, v_35, BIR.Code{v_7, [], v_9, v_10} <> v_36, v_37, scope, normalizer}, v_12, v_13, BIR.FunctionDeclaration{v_5, v_7, v_9} <> v_15)

def native_match_definition_closed_1(v_1: Bool, v_9: List<&2, BIR.Parameter>, v_3: State, v_5: String, v_7: U32, v_10: BIR.Block, v_12: List<&2, Catalog.Definition>, v_13: Catalog.Registry, v_15: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match v_1, v_9:
    case False{}, _:
      definitions(state_problem(v_3, "top-level definition has free captures", no_span), v_12, v_13, v_15)
    case True{}, []:
      definitions(v_3, v_12, v_13, BIR.LazyDeclaration{v_5, v_10} <> v_15)
    case True{}, _:
      native_match_definition_closed_0(v_3, v_5, v_7, v_9, v_10, v_12, v_13, v_15)

def definition_closed(v_1: Bool, v_3: State, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_10: BIR.Block, v_12: List<&2, Catalog.Definition>, v_13: Catalog.Registry, v_15: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  native_match_definition_closed_1(v_1, v_9, v_3, v_5, v_7, v_10, v_12, v_13, v_15)

def native_match_template_binders_0(v_22: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_14: U32, v_15: U32) -> TemplateResult:
  match v_22:
    case (v_20, v_21):
      template_binder(v_20, v_21, IR.Words{IR.arena_range_index(v_14, 1), U32.sub(v_15, 1)})

def native_match_template_binders_1(v_23: Sigma<&1, &1, Arena.Arena, _ => U32>, v_14: U32, v_15: U32) -> TemplateResult:
  match v_23:
    case (v_17, v_18):
      native_match_template_binders_0(Arena.get_binder(v_17, v_18), v_14, v_15)

def native_match_template_binders_2(v_4: Maybe<&2, Problem>, v_1: IR.Words, v_0: Arena.Arena) -> TemplateResult:
  match v_4, v_1:
    case Some{_}, _:
      TemplateResult{v_0, v_4}
    case None{}, IR.Words{_, 0}:
      TemplateResult{v_0, None{}}
    case None{}, IR.Words{v_14, v_15}:
      native_match_template_binders_1(Arena.word(v_0, IR.arena_tape_offset(v_14)), v_14, v_15)

def template_binders(v_0: Arena.Arena, v_1: IR.Words, v_4: Maybe<&2, Problem>) -> TemplateResult:
  native_match_template_binders_2(v_4, v_1, v_0)

def template_binder(source: Arena.Arena, binder: Arena.Binder, rest: IR.Words) -> TemplateResult:
  match binder:
    case Arena.TemplateBinder{_, _, _, span}: TemplateResult{source, Some{Problem{"unexpanded template binder reached JS emission", span}}}
    case _: template_binders(source, rest, None{})
def native_match_template_declarations_0(v_5: Maybe<&2, Problem>, v_2: List<&2, IR.TopLevel>, v_0: Arena.Arena) -> TemplateResult:
  match v_5, v_2:
    case Some{_}, _:
      TemplateResult{v_0, v_5}
    case None{}, []:
      TemplateResult{v_0, None{}}
    case None{}, v_13 <> v_14:
      template_declaration_result(template_declaration(v_0, v_13), v_14)

def template_declarations(v_0: Arena.Arena, v_2: List<&2, IR.TopLevel>, v_5: Maybe<&2, Problem>) -> TemplateResult:
  native_match_template_declarations_0(v_5, v_2, v_0)

def template_declaration_result(result: TemplateResult, rest: List<&2, IR.TopLevel>) -> TemplateResult:
  match result:
    case TemplateResult{source, problem}: template_declarations(source, rest, problem)
def template_declaration(source: Arena.Arena, declaration: IR.TopLevel) -> TemplateResult:
  match declaration:
    case IR.DefTop{IR.Definition{_, binders, _, _, _, _, _, _}}: template_binders(source, binders, None{})
    case IR.TypeTop{IR.TypeDecl{_, params, _, constructors, _}}:
      template_constructor_result(template_binders(source, params, None{}), constructors)
    case IR.LawTop{_}: TemplateResult{source, None{}}
def template_constructor_result(result: TemplateResult, constructors: List<&2, IR.ConstructorDecl>) -> TemplateResult:
  match result:
    case TemplateResult{source, problem}: template_constructors(source, constructors, problem)
def native_match_template_constructors_0(v_5: Maybe<&2, Problem>, v_2: List<&2, IR.ConstructorDecl>, v_0: Arena.Arena) -> TemplateResult:
  match v_5, v_2:
    case Some{_}, _:
      TemplateResult{v_0, v_5}
    case None{}, []:
      TemplateResult{v_0, None{}}
    case None{}, IR.Constructor{_, v_16, _} <> v_18:
      template_constructor_result(template_binders(v_0, v_16, None{}), v_18)

def template_constructors(v_0: Arena.Arena, v_2: List<&2, IR.ConstructorDecl>, v_5: Maybe<&2, Problem>) -> TemplateResult:
  native_match_template_constructors_0(v_5, v_2, v_0)

def native_match_template_modules_0(v_5: Maybe<&2, Problem>, v_2: List<&2, IR.LoadedModule>, v_0: Arena.Arena) -> TemplateResult:
  match v_5, v_2:
    case Some{_}, _:
      TemplateResult{v_0, v_5}
    case None{}, []:
      TemplateResult{v_0, None{}}
    case None{}, IR.LoadedModule{_, IR.Module{_, _, v_19}} <> v_20:
      template_module_result(template_declarations(v_0, v_19, None{}), v_20)

def template_modules(v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_5: Maybe<&2, Problem>) -> TemplateResult:
  native_match_template_modules_0(v_5, v_2, v_0)

def template_module_result(result: TemplateResult, rest: List<&2, IR.LoadedModule>) -> TemplateResult:
  match result:
    case TemplateResult{source, problem}: template_modules(source, rest, problem)

def prepare(program: Checked.CheckedProgram) -> Prepared:
  match program:
    case Checked.CheckedProgram{source, modules, signatures, metadata}:
      prepare_result(template_modules(source, modules, None{}), modules, signatures, metadata)
def prepare_result(result: TemplateResult, modules: List<&2, IR.LoadedModule>, signatures: List<&2, Scope.ArenaGlobal>, metadata: List<&2, Checked.ModuleMetadata>) -> Prepared:
  match result:
    case TemplateResult{source, problem}: Prepared{Checked.CheckedProgram{source, modules, signatures, metadata}, problem}

def lower(program: Checked.CheckedProgram) -> ProgramResult:
  lower_prepared(prepare(program), None{})
def lower_library(program: Checked.CheckedProgram, exports: List<&2, String>) -> ProgramResult:
  lower_prepared(prepare(program), Some{exports})
def lower_prepared(prepared: Prepared, exports: Maybe<&2, List<&2, String>>) -> ProgramResult:
  match prepared:
    case Prepared{_, Some{Problem{message, span}}}: LowerFailure{message, span}
    case Prepared{program, None{}}: lower_catalog(Catalog.build(program, exports))
def lower_catalog(result: Catalog.BuildResult) -> ProgramResult:
  match result:
    case Catalog.BuildFailure{_, message}: LowerFailure{message, no_span()}
    case Catalog.Built{Checked.CheckedProgram{source, _, _, _}, Catalog.Catalog{work, registry, constructors, families, type_functions, next_code, ending}}:
      state = State{source, next_code, 0, Frame{0, Nil{}, Nil{}, 0}, Nil{}, None{}, None{}, Some{DescriptorNf.nf_context(families, type_functions)}}
      lower_definitions(definitions(state, work, registry, Nil{}), constructors, families, type_functions, ending)
def lower_definitions(result: LowerResult<List<&2, BIR.Declaration>>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, ending: BIR.Ending) -> ProgramResult:
  match result:
    case LowerResult{State{_, _, _, _, codes, failure, scope, normalizer}, declarations}:
      lower_complete(failure, codes, declarations, constructors, families, type_functions, ending)
def lower_complete(failure: Maybe<&2, Problem>, codes: List<&2, BIR.Code>, declarations: List<&2, BIR.Declaration>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, ending: BIR.Ending) -> ProgramResult:
  match failure:
    case Some{Problem{message, span}}: LowerFailure{message, span}
    case None{}:
      Lowered{BIR.Program{List.reverse(&2, BIR.Code, codes), declarations, constructors, families, type_functions, ending}}
