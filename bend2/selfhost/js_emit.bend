import Base
import ./ast.bend as Ast
import ./checker_arena.bend as Arena
import ./checker_ir.bend as IR
import ./checked_frontend.bend as Checked
import ./scope_lookup.bend as Scope
import ./lower_catalog.bend as Catalog
import ./backend_ir.bend as BIR
import ./js_backend.bend as Backend

type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}
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
  State{source: Arena.Arena, next_code: U32, next_local: U32, frame: Frame, codes: List<&2, BIR.Code>, failure: Maybe<&2, Problem>}
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
    case State{source, code, local, frame, codes, old}:
      LowerResult{State{source, code, local, frame, codes, problem_first(old, message, span)}, BIR.Null{}}
def state_problem(state: State, message: String, span: Ast.SourceSpan) -> State:
  LowerResult{state, _} = fail(state, message, span)
  state
def node(state: State, id: U32) -> LowerResult<Arena.Node>:
  match state:
    case State{source, code, local, frame, codes, failure}:
      Tuple{source, value} = Arena.get_node(source, id)
      LowerResult{State{source, code, local, frame, codes, failure}, value}
def name(state: State, id: U32) -> LowerResult<String>:
  match state:
    case State{source, code, local, frame, codes, failure}:
      Tuple{source, value} = Arena.name_text(source, id)
      LowerResult{State{source, code, local, frame, codes, failure}, value}
def fresh(state: State) -> LowerResult<U32>:
  match state:
    case State{source, code, local, frame, codes, failure}:
      LowerResult{State{source, code, U32.inc(local), frame, codes, failure}, local}
def reserve(state: State, minimum: U32) -> State:
  match state:
    case State{source, code, local, frame, codes, failure}:
      State{source, code, U32.max(local, minimum), frame, codes, failure}
def push(state: State, instruction: Instruction) -> State:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure}:
      State{source, code, local, Frame{owner, instruction <> instructions, captures, count}, codes, failure}
def operation(state: State, op: BIR.Op) -> LowerResult<BIR.Atom>:
  LowerResult{state, id} = fresh(state)
  LowerResult{push(state, Bind{id, op}), BIR.Local{id}}
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
    case State{source, code, local, Frame{current, instructions, captures, count}, codes, failure}:
      resolve_owner(U32.is_eq(current, owner), State{source, code, local, Frame{current, instructions, captures, count}, codes, failure}, Slot{owner, identity, value, usage})
def resolve_owner(same: Bool, state: State, slot: Slot) -> LowerResult<BIR.Atom>:
  match same slot:
    case True{} Slot{_, _, value, _}: LowerResult{state, value}
    case _ Slot{owner, identity, _, _}:
      match state:
        case State{source, code, local, Frame{current, instructions, captures, count}, codes, failure}:
          resolve_capture(capture_found(captures, owner, identity), source, code, local, current, instructions, captures, count, codes, failure, slot)
    case _ _: LowerResult{state, BIR.Null{}}
def resolve_capture(found: Maybe<&2, U32>, source: Arena.Arena, code: U32, local: U32, current: U32, instructions: List<&2, Instruction>, captures: List<&2, Capture>, count: U32, codes: List<&2, BIR.Code>, failure: Maybe<&2, Problem>, slot: Slot) -> LowerResult<BIR.Atom>:
  match found:
    case Some{index}: LowerResult{State{source, code, local, Frame{current, instructions, captures, count}, codes, failure}, BIR.Capture{index}}
    case None{}: LowerResult{State{source, code, local, Frame{current, instructions, Capture{slot, count} <> captures, U32.inc(count)}, codes, failure}, BIR.Capture{count}}
def variable(state: State, slots: List<&2, Slot>, index: Nat, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  variable_found(state, slot_at(slots, index), span)
def variable_found(state: State, found: Maybe<&2, Slot>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match found:
    case Some{slot}: resolve(state, slot)
    case None{}: fail(state, "missing checked lexical binding", span)
def bind_slot(state: State, value: BIR.Atom, usage: BIR.Use) -> LowerResult<Slot>:
  LowerResult{state, identity} = fresh(state)
  match state:
    case State{source, code, local, frame, codes, failure}:
      match frame:
        case Frame{owner, _, _, _}:
          LowerResult{State{source, code, local, frame, codes, failure}, Slot{owner, identity, value, usage}}
def enter(state: State) -> LowerResult<Frame>:
  match state:
    case State{source, code, local, parent, codes, failure}:
      LowerResult{State{source, U32.inc(code), local, Frame{code, Nil{}, Nil{}, 0}, codes, failure}, parent}
def capture_uses(captures: List<&2, Capture>) -> List<&2, BIR.Use>:
  match captures:
    case Nil{}: Nil{}
    case Capture{Slot{_, _, _, usage}, _} <> rest: usage <> capture_uses(rest)
    case _ <> rest: capture_uses(rest)
def leave(state: State, parent: Frame, parameters: List<&2, BIR.Parameter>, body: BIR.Block) -> LowerResult<CodeRef>:
  match state:
    case State{source, next_code, local, Frame{code, _, captures, _}, codes, failure}:
      ordered = List.reverse(&2, Capture, captures)
      LowerResult{State{source, next_code, local, parent, BIR.Code{code, capture_uses(ordered), parameters, body} <> codes, failure}, CodeRef{code, parameters, ordered}}
def leave_value(state: State, parent: Frame, parameters: List<&2, BIR.Parameter>, value: BIR.Atom) -> LowerResult<CodeRef>:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure}:
      leave(State{source, code, local, Frame{owner, Nil{}, captures, count}, codes, failure}, parent, parameters, finish(instructions, value))
def capture_arguments(state: State, captures: List<&2, Capture>) -> LowerResult<List<&2, BIR.Arg>>:
  match captures:
    case Nil{}: LowerResult{state, Nil{}}
    case Capture{slot, _} <> rest:
      capture_argument(state, slot, rest)
def capture_argument(state: State, slot: Slot, rest: List<&2, Capture>) -> LowerResult<List<&2, BIR.Arg>>:
  match slot:
    case Slot{_, _, _, usage}:
      LowerResult{state, value} = resolve(state, slot)
      LowerResult{state, more} = capture_arguments(state, rest)
      LowerResult{state, BIR.Arg{usage, value} <> more}
    case ErasedSlot{}: capture_arguments(state, rest)
def close(state: State, reference: CodeRef) -> LowerResult<BIR.Atom>:
  match reference:
    case CodeRef{code, parameters, captures}:
      LowerResult{state, values} = capture_arguments(state, captures)
      operation(state, BIR.Closure{code, values, parameters})
def call_reference(state: State, reference: CodeRef, args: List<&2, BIR.Arg>) -> LowerResult<BIR.Atom>:
  match reference:
    case CodeRef{code, _, captures}:
      LowerResult{state, values} = capture_arguments(state, captures)
      operation(state, BIR.Direct{code, List.append(&2, BIR.Arg, values, args)})


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
def primitive(state: State, op: BIR.Primitive, values: List<&2, BIR.Atom>) -> LowerResult<BIR.Atom>:
  operation(state, BIR.PrimitiveCall{op, atom_arguments(values)})
def field_values(state: State, constructor: Catalog.Constructor, values: List<&2, BIR.Atom>, index: U32, span: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Field>>:
  match values:
    case Nil{}: LowerResult{state, Nil{}}
    case value <> rest:
      field_value(state, Catalog.constructor_field(constructor, index), constructor, value, rest, index, span)
def field_value(state: State, field: Maybe<&2, Catalog.ConstructorField>, constructor: Catalog.Constructor, value: BIR.Atom, rest: List<&2, BIR.Atom>, index: U32, span: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Field>>:
  match field:
    case Some{Catalog.ConstructorField{_, _, BIR.Erased{}}}: field_values(state, constructor, rest, U32.inc(index), span)
    case Some{Catalog.ConstructorField{identity, Some{key}, quantity}}:
      LowerResult{state, more} = field_values(state, constructor, rest, U32.inc(index), span)
      LowerResult{state, BIR.Field{identity, key, bir_use(quantity), value} <> more}
    case _:
      LowerResult{state_problem(state, "missing checked constructor field layout", span), Nil{}}
def construct(state: State, constructor: Catalog.Constructor, values: List<&2, BIR.Atom>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  construct_native(state, constructor_native(constructor), constructor, values, span)
def construct_native(state: State, identity: String, constructor: Catalog.Constructor, values: List<&2, BIR.Atom>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match identity values:
    case "Nat.Zero" Nil{}: LowerResult{state, BIR.Natural{0n}}
    case "Bool.False" Nil{}: LowerResult{state, BIR.Boolean{False{}}}
    case "Bool.True" Nil{}: LowerResult{state, BIR.Boolean{True{}}}
    case "String.SNil" Nil{}: LowerResult{state, BIR.Text{""}}
    case "Nat.Succ" value <> Nil{}: primitive(state, BIR.PrimNatSuccessor{}, [value])
    case "Char.Chr" value <> Nil{}: primitive(state, BIR.PrimCharNew{}, [value])
    case "String.SCon" head <> tail <> Nil{}: primitive(state, BIR.PrimStringAppend{}, [head, tail])
    case "U32.U32" value <> Nil{}: primitive(state, BIR.PrimWordToU32{}, [value])
    case "F32.F32" value <> Nil{}: primitive(state, BIR.PrimF32FromWord{}, [value])
    case "Array.ALeaf" value <> Nil{}: primitive(state, BIR.PrimArrayLeaf{}, [value])
    case "Array.ANode" left <> right <> Nil{}: primitive(state, BIR.PrimArrayNode{}, [left, right])
    case _ _:
      LowerResult{state, fields} = field_values(state, constructor, values, 0, span)
      operation(state, BIR.Construct{constructor_id(constructor), constructor_key(constructor), fields})
def construct_symbol(state: State, registry: Catalog.Registry, symbol: IR.Symbol, values: List<&2, BIR.Atom>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  construct_found(state, Catalog.lookup_constructor(registry, symbol), values, span)
def construct_found(state: State, found: Maybe<&2, Catalog.Constructor>, values: List<&2, BIR.Atom>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match found:
    case None{}: fail(state, "missing resolved constructor", span)
    case Some{constructor}: construct(state, constructor, values, span)
def constructor_operands(state: State, args: List<&2, IR.Occurrence>, bindings: List<&2, IR.CheckedBinding>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<List<&2, BIR.Atom>>:
  match args bindings:
    case Nil{} Nil{}: LowerResult{state, Nil{}}
    case _ <> rest IR.CheckedBinding{Ast.QZero{}, _, _} <> more:
      LowerResult{state, values} = constructor_operands(state, rest, more, env, registry, span)
      LowerResult{state, BIR.Null{} <> values}
    case item <> rest _ <> more:
      LowerResult{state, value} = lower(state, item, env, registry)
      LowerResult{state, values} = constructor_operands(state, rest, more, env, registry, span)
      LowerResult{state, value <> values}
    case _ _: LowerResult{state_problem(state, "incomplete checked constructor operands", span), Nil{}}
def reference(state: State, found: Maybe<&2, Catalog.DefinitionHeader>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match found:
    case None{}: fail(state, "missing resolved definition", span)
    case Some{Catalog.DefinitionHeader{_, key, code, parameters, _, type_only, primitive, foreign, _}}:
      reference_kind(state, key, code, parameters, type_only, primitive, foreign)
def reference_kind(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, Catalog.Foreign>) -> LowerResult<BIR.Atom>:
  match type_only primitive foreign parameters:
    case True{} _ _ _: LowerResult{state, BIR.Null{}}
    case False{} Some{_} _ _: LowerResult{state, BIR.Symbol{code, key}}
    case False{} None{} None{} _ <> _: LowerResult{state, BIR.Symbol{code, key}}
    case _ _ _ _: operation(state, BIR.LoadSymbol{code, key})
def symbol_value(state: State, symbol: IR.Symbol, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match symbol:
    case IR.Symbol{_, _, IR.FamilySymbol{}, _}: LowerResult{state, BIR.Null{}}
    case IR.Symbol{_, _, IR.ConstructorSymbol{}, _}: construct_symbol(state, registry, symbol, Nil{}, span)
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
def literal_word(state: State, registry: Catalog.Registry, remaining: Nat, bits: U32, nil: IR.Symbol, cons: IR.Symbol, zero: IR.Symbol, one: IR.Symbol, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match remaining:
    case 0n: construct_symbol(state, registry, nil, Nil{}, span)
    case 1n+rest:
      LowerResult{state, bit} = literal_bit(state, registry, U32.is_eq(U32.and(bits, 1), 0), zero, one, span)
      LowerResult{state, tail} = literal_word(state, registry, rest, U32.shr(bits), nil, cons, zero, one, span)
      construct_symbol(state, registry, cons, [bit, tail], span)
def literal_bit(state: State, registry: Catalog.Registry, zero_bit: Bool, zero: IR.Symbol, one: IR.Symbol, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match zero_bit:
    case True{}: construct_symbol(state, registry, zero, Nil{}, span)
    case False{}: construct_symbol(state, registry, one, Nil{}, span)
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
def literal_string_items(state: State, registry: Catalog.Registry, chars: List<&2, U32>, nil: IR.Symbol, cons: IR.Symbol, char: IR.Symbol, uint: IR.Symbol, word_nil: IR.Symbol, word_cons: IR.Symbol, zero: IR.Symbol, one: IR.Symbol, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match chars:
    case Nil{}: construct_symbol(state, registry, nil, Nil{}, span)
    case value <> rest:
      LowerResult{state, word} = literal_word(state, registry, 32n, value, word_nil, word_cons, zero, one, span)
      LowerResult{state, integer} = construct_symbol(state, registry, uint, [word], span)
      LowerResult{state, character} = construct_symbol(state, registry, char, [integer], span)
      LowerResult{state, tail} = literal_string_items(state, registry, rest, nil, cons, char, uint, word_nil, word_cons, zero, one, span)
      construct_symbol(state, registry, cons, [character, tail], span)


def spine(state: State, head: IR.Occurrence, args: List<&2, SourceArgument>) -> LowerResult<Spine>:
  match head:
    case IR.TypedOccurrence{term, _, _, _, _, children}:
      LowerResult{state, shape} = node(state, term)
      spine_shape(state, shape, head, children, args)
    case _: LowerResult{state, Spine{head, args}}
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
def application_header(state: State, header: Maybe<&2, Catalog.DefinitionHeader>, head: IR.Occurrence, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match header:
    case Some{Catalog.DefinitionHeader{_, _, code, parameters, quantities, False{}, native, None{}, fast}}:
      application_known(state, native, fast, code, parameters, List.length(&2, BIR.Quantity, quantities), head, args, env, registry, span)
    case _:
      LowerResult{state, fn} = lower(state, head, env, registry)
      apply_rest(state, fn, args, env, registry)
def application_known(state: State, native: Maybe<&2, BIR.Primitive>, fast: Bool, code: U32, parameters: List<&2, BIR.Parameter>, arity: Nat, head: IR.Occurrence, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match native:
    case Some{primitive}:
      application_native(state, Bool.and(Nat.is_ge(List.length(&2, SourceArgument, args), arity), Nat.is_eq(List.length(&2, BIR.Parameter, parameters), Catalog.primitive_arity(primitive))), primitive, arity, head, args, env, registry)
    case None{}:
      application_direct(state, fast, code, parameters, arity, head, args, env, registry, span)
def application_native(state: State, eligible: Bool, primitive: BIR.Primitive, arity: Nat, head: IR.Occurrence, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match eligible:
    case False{}:
      LowerResult{state, fn} = lower(state, head, env, registry)
      apply_rest(state, fn, args, env, registry)
    case True{}:
      LowerResult{state, processed} = argument_prefix(state, arity, args, env, registry)
      match processed:
        case Tuple{values, rest}:
          LowerResult{state, value} = operation(state, BIR.PrimitiveCall{primitive, values})
          apply_rest(state, value, rest, env, registry)
def application_direct(state: State, eligible: Bool, code: U32, parameters: List<&2, BIR.Parameter>, arity: Nat, head: IR.Occurrence, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match eligible:
    case False{}:
      LowerResult{state, fn} = lower(state, head, env, registry)
      apply_rest(state, fn, args, env, registry)
    case True{}:
      supplied = List.length(&2, SourceArgument, args)
      LowerResult{state, processed} = argument_prefix(state, Nat.min(arity, supplied), args, env, registry)
      match processed:
        case Tuple{values, rest}:
          application_direct_values(state, Nat.is_ge(supplied, arity), code, parameters, values, rest, env, registry, span)
def application_direct_values(state: State, saturated: Bool, code: U32, parameters: List<&2, BIR.Parameter>, values: List<&2, BIR.Arg>, rest: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match saturated:
    case True{}:
      LowerResult{state, value} = direct_arity(state, Nat.is_eq(List.length(&2, BIR.Parameter, parameters), List.length(&2, BIR.Arg, values)), code, values, span)
      apply_rest(state, value, rest, env, registry)
    case False{}:
      partial(state, code, values, drop_parameters(List.length(&2, BIR.Arg, values), parameters))
def direct_arity(state: State, valid: Bool, code: U32, values: List<&2, BIR.Arg>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match valid:
    case True{}: operation(state, BIR.Direct{code, values})
    case False{}: fail(state, "checked call quantity/entry arity mismatch", span)
def argument_prefix(state: State, count: Nat, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<(List<&2, BIR.Arg> & List<&2, SourceArgument>)>:
  match count args:
    case 0n _: LowerResult{state, (Nil{}, args)}
    case 1n+remaining SourceArgument{Ast.QZero{}, _} <> rest: argument_prefix(state, remaining, rest, env, registry)
    case 1n+remaining SourceArgument{quantity, occurrence} <> rest:
      LowerResult{state, value} = lower(state, occurrence, env, registry)
      LowerResult{state, processed} = argument_prefix(state, remaining, rest, env, registry)
      match processed:
        case Tuple{values, rest}: LowerResult{state, (BIR.Arg{use(quantity), value} <> values, rest)}
    case _ Nil{}: LowerResult{state_problem(state, "missing checked call operands", no_span()), (Nil{}, Nil{})}
def apply_rest(state: State, fn: BIR.Atom, args: List<&2, SourceArgument>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match args:
    case Nil{}: LowerResult{state, fn}
    case SourceArgument{Ast.QZero{}, _} <> rest: apply_rest(state, fn, rest, env, registry)
    case SourceArgument{quantity, arg} <> rest:
      LowerResult{state, value} = lower(state, arg, env, registry)
      LowerResult{state, applied} = operation(state, BIR.Apply{fn, BIR.Arg{use(quantity), value}})
      apply_rest(state, applied, rest, env, registry)
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
def partial(state: State, target: U32, values: List<&2, BIR.Arg>, parameters: List<&2, BIR.Parameter>) -> LowerResult<BIR.Atom>:
  match parameters:
    case Nil{}: operation(state, BIR.Direct{target, values})
    case _:
      match state:
        case State{source, code, local, frame, codes, failure}:
          args = List.append(&2, BIR.Arg, indexed_captures(values, 0), parameter_arguments(parameters))
          body = BIR.Code{code, argument_uses(values), parameters, BIR.TailDirect{target, args}}
          operation(State{source, U32.inc(code), local, frame, body <> codes, failure}, BIR.Closure{code, values, parameters})


def tag(state: State, constructor: Catalog.Constructor, value: BIR.Atom) -> LowerResult<BIR.Atom>:
  tag_native(state, constructor_native(constructor), constructor, value)
def tag_native(state: State, identity: String, constructor: Catalog.Constructor, value: BIR.Atom) -> LowerResult<BIR.Atom>:
  match identity:
    case "Nat.Zero": primitive(state, BIR.PrimIsNatZero{}, [value])
    case "Nat.Succ": primitive(state, BIR.PrimIsNatSuccessor{}, [value])
    case "Bool.False": primitive(state, BIR.PrimIsFalse{}, [value])
    case "Bool.True": primitive(state, BIR.PrimIsTrue{}, [value])
    case "String.SNil": primitive(state, BIR.PrimIsStringEmpty{}, [value])
    case "String.SCon": primitive(state, BIR.PrimIsStringNonempty{}, [value])
    case "Array.ALeaf": primitive(state, BIR.PrimIsArrayLeaf{}, [value])
    case "Array.ANode": primitive(state, BIR.PrimIsArrayNode{}, [value])
    case "Char.Chr": LowerResult{state, BIR.Boolean{True{}}}
    case "U32.U32": LowerResult{state, BIR.Boolean{True{}}}
    case "F32.F32": LowerResult{state, BIR.Boolean{True{}}}
    case _: operation(state, BIR.HasTag{value, constructor_id(constructor), constructor_key(constructor)})
def project(state: State, constructor: Catalog.Constructor, value: BIR.Atom, index: U32, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  project_native(state, constructor_native(constructor), constructor, value, index, span)
def project_native(state: State, identity: String, constructor: Catalog.Constructor, value: BIR.Atom, index: U32, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match identity index:
    case "Nat.Succ" 0: primitive(state, BIR.PrimNatPredecessor{}, [value])
    case "String.SCon" 0: primitive(state, BIR.PrimStringHead{}, [value])
    case "String.SCon" 1: primitive(state, BIR.PrimStringTail{}, [value])
    case "Char.Chr" 0: primitive(state, BIR.PrimCharCode{}, [value])
    case "U32.U32" 0: primitive(state, BIR.PrimU32ToWord{}, [value])
    case "F32.F32" 0: primitive(state, BIR.PrimF32ToWord{}, [value])
    case "Array.ALeaf" 0: primitive(state, BIR.PrimArrayLeafValue{}, [value])
    case "Array.ANode" 0: primitive(state, BIR.PrimArrayLeft{}, [value])
    case "Array.ANode" 1: primitive(state, BIR.PrimArrayRight{}, [value])
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
def patterns(state: State, items: List<&2, IR.CheckedPattern>, values: List<&2, BIR.Atom>, env: List<&2, Slot>, registry: Catalog.Registry, failure: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match items values:
    case Nil{} Nil{}: LowerResult{state, env}
    case item <> rest value <> more:
      LowerResult{state, bound} = pattern(state, item, value, env, registry, failure)
      patterns(state, rest, more, bound, registry, failure)
    case _ _: LowerResult{state_problem(state, "checked pattern/scrutinee arity mismatch", no_span()), env}
def pattern(state: State, item: IR.CheckedPattern, value: BIR.Atom, env: List<&2, Slot>, registry: Catalog.Registry, failure: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match item:
    case IR.CheckedVariable{_, IR.CheckedBinding{Ast.QZero{}, _, _}}: LowerResult{state, ErasedSlot{} <> env}
    case IR.CheckedVariable{_, IR.CheckedBinding{quantity, _, _}}:
      LowerResult{state, slot} = bind_slot(state, value, use(quantity))
      LowerResult{state, slot <> env}
    case IR.CheckedConstructor{_, symbol, fields, layout}:
      pattern_constructor(state, Catalog.lookup_constructor(registry, symbol), fields, layout, value, env, registry, failure)
def pattern_constructor(state: State, found: Maybe<&2, Catalog.Constructor>, fields: List<&2, IR.CheckedPattern>, layout: List<&2, IR.CheckedBinding>, value: BIR.Atom, env: List<&2, Slot>, registry: Catalog.Registry, failure: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match found:
    case None{}: LowerResult{state_problem(state, "missing resolved pattern constructor", no_span()), env}
    case Some{constructor}:
      pattern_scalar(state, closed_scalar(constructor_native(constructor), fields, registry), constructor, fields, layout, value, env, registry, failure)
def pattern_scalar(state: State, bits: Maybe<&2, U32>, constructor: Catalog.Constructor, fields: List<&2, IR.CheckedPattern>, layout: List<&2, IR.CheckedBinding>, value: BIR.Atom, env: List<&2, Slot>, registry: Catalog.Registry, failure: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match bits:
    case Some{number}:
      LowerResult{state, condition} = scalar_test(state, String.eq(constructor_native(constructor), "F32.F32"), value, number)
      LowerResult{guard(state, condition, failure), env}
    case None{}:
      LowerResult{state, condition} = tag(state, constructor, value)
      pattern_fields(guard(state, condition, failure), constructor, fields, layout, value, 0, env, registry, failure)
def scalar_test(state: State, floating: Bool, value: BIR.Atom, number: U32) -> LowerResult<BIR.Atom>:
  match floating:
    case True{}: primitive(state, BIR.PrimFloatBitsEqual{}, [value, BIR.Word{number}])
    case False{}: primitive(state, BIR.PrimSameValue{}, [value, BIR.Word{number}])
def pattern_fields(state: State, constructor: Catalog.Constructor, fields: List<&2, IR.CheckedPattern>, layout: List<&2, IR.CheckedBinding>, value: BIR.Atom, index: U32, env: List<&2, Slot>, registry: Catalog.Registry, failure: BIR.Block) -> LowerResult<List<&2, Slot>>:
  match fields layout:
    case Nil{} Nil{}: LowerResult{state, env}
    case item <> rest IR.CheckedBinding{Ast.QZero{}, _, _} <> more:
      pattern_fields(state, constructor, rest, more, value, U32.inc(index), erase_pattern(item, env), registry, failure)
    case item <> rest _ <> more:
      LowerResult{state, field} = project(state, constructor, value, index, no_span())
      LowerResult{state, bound} = pattern(state, item, field, env, registry, failure)
      pattern_fields(state, constructor, rest, more, value, U32.inc(index), bound, registry, failure)
    case _ _: LowerResult{state_problem(state, "incomplete checked pattern layout", no_span()), env}
def lower_values(state: State, items: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<List<&2, BIR.Atom>>:
  match items:
    case Nil{}: LowerResult{state, Nil{}}
    case item <> rest:
      LowerResult{state, value} = lower(state, item, env, registry)
      LowerResult{state, values} = lower_values(state, rest, env, registry)
      LowerResult{state, value <> values}
def new_parameters(state: State, count: Nat) -> LowerResult<List<&2, BIR.Parameter>>:
  match count:
    case 0n: LowerResult{state, Nil{}}
    case 1n+rest:
      LowerResult{state, id} = fresh(state)
      LowerResult{state, parameters} = new_parameters(state, rest)
      LowerResult{state, BIR.Parameter{id, BIR.Affine{}} <> parameters}
def parameter_values(parameters: List<&2, BIR.Parameter>) -> List<&2, BIR.Atom>:
  match parameters:
    case Nil{}: Nil{}
    case BIR.Parameter{id, _} <> rest: BIR.Local{id} <> parameter_values(rest)
def checked_cases(state: State, cases: List<&2, IR.Occurrence>, values: List<&2, BIR.Atom>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Block>:
  match cases:
    case Nil{}: LowerResult{state, BIR.Failure{"bend: runtime fail-stop"}}
    case IR.CaseOccurrence{_, _, row, body} <> rest:
      LowerResult{state, label} = fresh(state)
      LowerResult{state, bound} = patterns(state, row, values, env, registry, BIR.LeaveRegion{label})
      LowerResult{state, value} = lower(state, body, bound, registry)
      LowerResult{state, block} = take_block(state, value)
      LowerResult{state, next} = checked_cases(state, rest, values, env, registry)
      LowerResult{state, BIR.Region{label, block, next}}
    case _ <> _: LowerResult{state_problem(state, "missing checked match row", no_span()), BIR.Failure{"bend: malformed checked match"}}
def take_block(state: State, value: BIR.Atom) -> LowerResult<BIR.Block>:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure}:
      LowerResult{State{source, code, local, Frame{owner, Nil{}, captures, count}, codes, failure}, finish(instructions, value)}
def match_values(state: State, cases: List<&2, IR.Occurrence>, values: List<&2, BIR.Atom>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  LowerResult{state, parent} = enter(state)
  LowerResult{state, parameters} = new_parameters(state, List.length(&2, BIR.Atom, values))
  LowerResult{state, block} = checked_cases(state, cases, parameter_values(parameters), env, registry)
  LowerResult{state, code} = leave(state, parent, parameters, block)
  call_reference(state, code, atom_arguments(values))
def split_occurrences(count: U32, items: List<&2, IR.Occurrence>) -> List<&2, IR.Occurrence> & List<&2, IR.Occurrence>:
  match count items:
    case 0 _: (Nil{}, items)
    case _ item <> rest:
      Tuple{prefix, suffix} = split_occurrences(U32.sub(count, 1), rest)
      (item <> prefix, suffix)
    case _ Nil{}: (Nil{}, Nil{})
def lower_match(state: State, count: U32, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match split_occurrences(count, children):
    case Tuple{scrutinees, cases}:
      LowerResult{state, values} = lower_values(state, scrutinees, env, registry)
      match_values(state, cases, values, env, registry)


def occurrence_term(occurrence: IR.Occurrence) -> U32:
  match occurrence:
    case IR.TypedOccurrence{term, _, _, _, _, _}: term
    case IR.ScalarOccurrence{term, _, _, _, _}: term
    case IR.StringOccurrence{term, _, _, _}: term
    case IR.CaseOccurrence{term, _, _, _}: term
    case IR.LocalOccurrence{term, _, _, _, _}: term
    case IR.LocalReferenceOccurrence{term, _, _, _}: term

def lower(state: State, occurrence: IR.Occurrence, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match occurrence:
    case IR.TypedOccurrence{term, _, formal, symbol, bindings, children}:
      LowerResult{state, shape} = node(state, term)
      lower_node(state, shape, formal, symbol, bindings, children, env, registry)
    case IR.ScalarOccurrence{_, _, symbol, bits, symbols}:
      scalar_literal(state, Catalog.lookup_constructor(registry, symbol), bits, symbols, registry)
    case IR.StringOccurrence{_, _, symbols, chars}: literal_string(state, registry, chars, symbols, no_span())
    case IR.LocalReferenceOccurrence{term, _, _, _}:
      LowerResult{state, shape} = node(state, term)
      lexical_reference(state, shape, env)
    case IR.LocalOccurrence{_, _, row, values, body}:
      LowerResult{state, operands} = local_values(state, row, values, env, registry)
      LowerResult{state, bound} = patterns(state, row, operands, env, registry, BIR.Failure{"bend: runtime fail-stop"})
      lower(state, body, bound, registry)
    case IR.CaseOccurrence{_, _, _, _}: fail(state, "checked case escaped its match", no_span())
def lexical_reference(state: State, shape: Arena.Node, env: List<&2, Slot>) -> LowerResult<BIR.Atom>:
  match shape:
    case Arena.TermVar{_, index, span}: variable(state, env, index, span)
    case _: fail(state, "checked local reference lost lexical identity", no_span())
def lower_node(state: State, shape: Arena.Node, formal: Maybe<&2, Ast.Quantity>, symbol: Maybe<&2, IR.Symbol>, bindings: List<&2, IR.CheckedBinding>, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match shape:
    case Arena.TermVar{_, index, span}: variable(state, env, index, span)
    case Arena.TermRef{_, span}: resolved_reference(state, symbol, registry, span)
    case Arena.TermBang{_, span}: only_child(state, children, env, registry, span)
    case Arena.TermAnn{_, _, span}: annotated_child(state, children, env, registry, span)
    case Arena.TermLam{_, _, _, _, span}: lambda_checked(state, formal, children, env, registry, span)
    case Arena.TermApp{_, _, span}: application_checked(state, formal, children, env, registry, span)
    case Arena.TermCtr{_, _, _, span}: constructor_checked(state, symbol, bindings, children, env, registry, span)
    case Arena.TermLet{_, _, _, _, _, _, _, count, _, span}: let_checked(state, count, bindings, children, env, registry, span)
    case Arena.BodyMatch{_, count, _, _, _}: lower_match(state, count, children, env, registry)
    case Arena.TermMat{_, _, _, span}: matcher_checked(state, formal, symbol, children, env, registry, span)
    case Arena.TermAbsurd{span}: absurd_checked(state, formal, span)
    case Arena.TermRewrite{_, _, _, span}: rewrite_checked(state, children, env, registry, span)
    case Arena.TermType{_, _}: LowerResult{state, BIR.Null{}}
    case Arena.TermQuant{}: LowerResult{state, BIR.Null{}}
    case Arena.TermQuantity{_, _}: LowerResult{state, BIR.Null{}}
    case Arena.TermMin{_, _, _}: LowerResult{state, BIR.Null{}}
    case Arena.TermAll{_, _, _, _, _, _}: LowerResult{state, BIR.Null{}}
    case Arena.TermAdt{_, _, _, _, _, _}: LowerResult{state, BIR.Null{}}
    case Arena.TermEqual{_, _, _, _}: LowerResult{state, BIR.Null{}}
    case Arena.TermRefl{_}: LowerResult{state, BIR.Null{}}
    case Arena.TermHole{key, span}:
      LowerResult{state, text} = name(state, key)
      LowerResult{push(state, Stop{BIR.Failure{String.append("bend: unsolved hole ", text)}}), BIR.Null{}}
    case Arena.TermTemplate{_, span}: fail(state, "unexpanded template reached JS emission", span)
    case Arena.TermString{_, _, span}: fail(state, "missing checked string literal certificate", span)
    case Arena.TermSub{_, _, _, span}: fail(state, "unelaborated substitution reached lowering", span)
    case Arena.TermFill{_, _, _, span}: fail(state, "unelaborated fill reached lowering", span)
    case Arena.TermPlus{_, _, _, span}: fail(state, "unelaborated plus reached lowering", span)
    case Arena.BodyCase{_, _, _, span}: fail(state, "missing checked case facts", span)
    case Arena.BodyLocal{_, _, _, _, _, _, span}: fail(state, "missing checked local facts", span)
    case Arena.BodyReply{_, span}: fail(state, "unelaborated reply reached lowering", span)
def resolved_reference(state: State, symbol: Maybe<&2, IR.Symbol>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match symbol:
    case Some{value}: symbol_value(state, value, registry, span)
    case None{}: fail(state, "missing checked reference identity", span)
def only_child(state: State, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match children:
    case child <> Nil{}: lower(state, child, env, registry)
    case _: fail(state, "incomplete checked unary operand", span)
def annotated_child(state: State, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match children:
    case child <> _ <> Nil{}: lower(state, child, env, registry)
    case _: fail(state, "incomplete checked annotation", span)
def rewrite_checked(state: State, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match children:
    case _ <> _ <> body <> Nil{}: lower(state, body, env, registry)
    case _: fail(state, "incomplete checked rewrite", span)
def application_checked(state: State, formal: Maybe<&2, Ast.Quantity>, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match formal children:
    case Some{quantity} fn <> arg <> Nil{}:
      LowerResult{state, chain} = spine(state, fn, [SourceArgument{quantity, arg}])
      applications(state, chain, env, registry, span)
    case _ _: fail(state, "missing checked application quantity/operands", span)
def constructor_checked(state: State, symbol: Maybe<&2, IR.Symbol>, bindings: List<&2, IR.CheckedBinding>, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match symbol:
    case None{}: fail(state, "missing checked constructor identity", span)
    case Some{value}:
      LowerResult{state, args} = constructor_operands(state, children, bindings, env, registry, span)
      construct_symbol(state, registry, value, args, span)
def lambda_checked(state: State, formal: Maybe<&2, Ast.Quantity>, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match formal children:
    case Some{Ast.QZero{}} body <> Nil{}: lower(state, body, ErasedSlot{} <> env, registry)
    case Some{quantity} body <> Nil{}:
      LowerResult{state, parent} = enter(state)
      LowerResult{state, id} = fresh(state)
      LowerResult{state, slot} = bind_slot(state, BIR.Local{id}, use(quantity))
      LowerResult{state, value} = lower(state, body, slot <> env, registry)
      LowerResult{state, code} = leave_value(state, parent, [BIR.Parameter{id, use(quantity)}], value)
      close(state, code)
    case _ _: fail(state, "missing checked lambda quantity/body", span)
def absurd_checked(state: State, formal: Maybe<&2, Ast.Quantity>, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match formal:
    case Some{Ast.QZero{}}: fail(state, "erased absurd scrutinee reached live lowering", span)
    case Some{quantity}:
      LowerResult{state, parent} = enter(state)
      LowerResult{state, id} = fresh(state)
      LowerResult{state, code} = leave(state, parent, [BIR.Parameter{id, use(quantity)}], BIR.Failure{"bend: runtime fail-stop"})
      close(state, code)
    case None{}: fail(state, "missing checked absurd quantity", span)
def local_values(state: State, row: List<&2, IR.CheckedPattern>, values: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry) -> LowerResult<List<&2, BIR.Atom>>:
  match row values:
    case Nil{} Nil{}: LowerResult{state, Nil{}}
    case IR.CheckedVariable{_, IR.CheckedBinding{Ast.QZero{}, _, _}} <> more _ <> rest:
      LowerResult{state, values} = local_values(state, more, rest, env, registry)
      LowerResult{state, BIR.Null{} <> values}
    case _ <> more value <> rest:
      LowerResult{state, value} = lower(state, value, env, registry)
      LowerResult{state, values} = local_values(state, more, rest, env, registry)
      LowerResult{state, value <> values}
    case _ _: LowerResult{state_problem(state, "incomplete checked local values", no_span()), Nil{}}
def let_checked(state: State, count: U32, bindings: List<&2, IR.CheckedBinding>, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match split_occurrences(count, children):
    case Tuple{values, body <> Nil{}}:
      LowerResult{state, bound} = let_bindings(state, values, bindings, env, env, registry, span)
      lower(state, body, bound, registry)
    case _: fail(state, "incomplete checked let body", span)
def let_bindings(state: State, values: List<&2, IR.Occurrence>, bindings: List<&2, IR.CheckedBinding>, source: List<&2, Slot>, bound: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<List<&2, Slot>>:
  match values bindings:
    case Nil{} Nil{}: LowerResult{state, bound}
    case _ <> rest IR.CheckedBinding{Ast.QZero{}, _, _} <> more:
      let_bindings(state, rest, more, source, ErasedSlot{} <> bound, registry, span)
    case value <> rest IR.CheckedBinding{quantity, _, _} <> more:
      LowerResult{state, value} = lower(state, value, source, registry)
      LowerResult{state, slot} = bind_slot(state, value, use(quantity))
      let_bindings(state, rest, more, source, slot <> bound, registry, span)
    case _ _: LowerResult{state_problem(state, "incomplete checked let bindings", span), bound}
def scalar_literal(state: State, found: Maybe<&2, Catalog.Constructor>, bits: U32, symbols: List<&2, IR.Symbol>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match found:
    case None{}: fail(state, "missing certified scalar constructor", no_span())
    case Some{constructor}: scalar_literal_native(state, constructor_native(constructor), constructor, bits, symbols, registry)
def scalar_literal_native(state: State, identity: String, constructor: Catalog.Constructor, bits: U32, symbols: List<&2, IR.Symbol>, registry: Catalog.Registry) -> LowerResult<BIR.Atom>:
  match identity:
    case "U32.U32": LowerResult{state, BIR.Word{bits}}
    case "F32.F32": LowerResult{state, BIR.FloatBits{bits}}
    case _:
      match symbols:
        case nil <> cons <> zero <> one <> Nil{}:
          LowerResult{state, word} = literal_word(state, registry, 32n, bits, nil, cons, zero, one, no_span())
          construct(state, constructor, [word], no_span())
        case _: fail(state, "incomplete certified scalar identities", no_span())


def take_instructions(state: State) -> LowerResult<List<&2, Instruction>>:
  match state:
    case State{source, code, local, Frame{owner, instructions, captures, count}, codes, failure}:
      LowerResult{State{source, code, local, Frame{owner, Nil{}, captures, count}, codes, failure}, instructions}
def matcher_checked(state: State, formal: Maybe<&2, Ast.Quantity>, symbol: Maybe<&2, IR.Symbol>, children: List<&2, IR.Occurrence>, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match formal symbol children:
    case Some{Ast.QZero{}} _ _: fail(state, "erased matcher scrutinee reached live lowering", span)
    case Some{quantity} Some{constructor} head <> fallback <> Nil{}:
      matcher_constructor(state, Catalog.lookup_constructor(registry, constructor), quantity, head, fallback, env, registry, span)
    case _ _ _: fail(state, "incomplete checked matcher facts", span)
def matcher_constructor(state: State, found: Maybe<&2, Catalog.Constructor>, quantity: Ast.Quantity, head: IR.Occurrence, fallback: IR.Occurrence, env: List<&2, Slot>, registry: Catalog.Registry, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match found:
    case None{}: fail(state, "missing checked matcher constructor", span)
    case Some{constructor}:
      LowerResult{state, parent} = enter(state)
      LowerResult{state, id} = fresh(state)
      LowerResult{state, condition} = tag(state, constructor, BIR.Local{id})
      LowerResult{state, leading} = take_instructions(state)
      LowerResult{state, hit_fn} = lower(state, head, env, registry)
      LowerResult{state, hit} = matcher_fields(state, constructor, constructor_quantities(constructor), BIR.Local{id}, 0, hit_fn, quantity, span)
      LowerResult{state, hit_body} = take_block(state, hit)
      LowerResult{state, miss_fn} = lower(state, fallback, env, registry)
      LowerResult{state, miss} = operation(state, BIR.Apply{miss_fn, BIR.Arg{use(quantity), BIR.Local{id}}})
      LowerResult{state, miss_body} = take_block(state, miss)
      body = prefix(leading, BIR.Branch{condition, hit_body, miss_body})
      LowerResult{state, code} = leave(state, parent, [BIR.Parameter{id, use(quantity)}], body)
      close(state, code)
def constructor_quantities(constructor: Catalog.Constructor) -> List<&2, BIR.Quantity>:
  match constructor:
    case Catalog.Constructor{_, quantities, _, _}: quantities
def matcher_field_use(quantity: BIR.Quantity, input: Ast.Quantity) -> BIR.Use:
  match quantity:
    case BIR.Unrestricted{}: BIR.Many{}
    case _: use(input)
def matcher_fields(state: State, constructor: Catalog.Constructor, quantities: List<&2, BIR.Quantity>, value: BIR.Atom, index: U32, fn: BIR.Atom, input: Ast.Quantity, span: Ast.SourceSpan) -> LowerResult<BIR.Atom>:
  match quantities:
    case Nil{}: LowerResult{state, fn}
    case BIR.Erased{} <> rest: matcher_fields(state, constructor, rest, value, U32.inc(index), fn, input, span)
    case quantity <> rest:
      LowerResult{state, field} = project(state, constructor, value, index, span)
      LowerResult{state, fn} = operation(state, BIR.Apply{fn, BIR.Arg{matcher_field_use(quantity, input), field}})
      matcher_fields(state, constructor, rest, value, U32.inc(index), fn, input, span)

def definition_frame(state: State, owner: U32, minimum: U32) -> State:
  match reserve(state, minimum):
    case State{source, code, local, _, codes, failure}:
      State{source, code, local, Frame{owner, Nil{}, Nil{}, 0}, codes, failure}
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
    case Catalog.Definition{header, _, _, _, checked, _, _, _} <> rest:
      definition(state, header, checked, rest, registry, result)
def definition(state: State, header: Catalog.DefinitionHeader, checked: Maybe<&2, IR.Occurrence>, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match header:
    case Catalog.DefinitionHeader{_, key, code, parameters, quantities, type_only, primitive, foreign, _}:
      definition_kind(state, key, code, parameters, quantities, type_only, primitive, foreign, checked, rest, registry, result)
def definition_kind(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, Catalog.Foreign>, checked: Maybe<&2, IR.Occurrence>, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match foreign:
    case Some{Catalog.Foreign{path, imported, arity}}:
      definitions(state, rest, registry, BIR.ForeignDeclaration{key, path, imported, arity} <> result)
    case Some{Catalog.ForeignMissing{_, _}}:
      definitions(state, rest, registry, BIR.LazyDeclaration{key, BIR.Return{BIR.Undefined{}}} <> result)
    case None{}:
      definition_local(state, key, code, parameters, quantities, type_only, primitive, checked, rest, registry, result)
def definition_local(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, checked: Maybe<&2, IR.Occurrence>, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match type_only primitive:
    case True{} _: definitions(state, rest, registry, result)
    case False{} Some{native}: definitions(state, rest, registry, BIR.NativeDeclaration{key, native, quantities} <> result)
    case False{} None{}:
      definition_body(state, key, code, parameters, quantities, checked, rest, registry, result)
def definition_body(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, checked: Maybe<&2, IR.Occurrence>, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match checked:
    case None{}: definitions(state_problem(state, String.append("missing checked body: ", key), no_span()), rest, registry, result)
    case Some{body}:
      state = definition_frame(state, code, U32.from_nat(List.length(&2, BIR.Quantity, quantities)))
      LowerResult{state, env} = definition_env(state, quantities, parameters, code, Nil{})
      LowerResult{state, value} = lower(state, body, env, registry)
      LowerResult{state, block} = take_block(state, value)
      definition_complete(state, key, code, parameters, block, rest, registry, result)
def definition_complete(state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, body: BIR.Block, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match state:
    case State{source, next_code, local, Frame{owner, instructions, captures, count}, codes, failure}:
      definition_closed(U32.is_eq(count, 0), State{source, next_code, local, Frame{owner, instructions, captures, count}, codes, failure}, key, code, parameters, body, rest, registry, result)
def definition_closed(closed: Bool, state: State, key: String, code: U32, parameters: List<&2, BIR.Parameter>, body: BIR.Block, rest: List<&2, Catalog.Definition>, registry: Catalog.Registry, result: List<&2, BIR.Declaration>) -> LowerResult<List<&2, BIR.Declaration>>:
  match closed parameters:
    case False{} _: definitions(state_problem(state, "top-level definition has free captures", no_span()), rest, registry, result)
    case True{} Nil{}: definitions(state, rest, registry, BIR.LazyDeclaration{key, body} <> result)
    case True{} _:
      match state:
        case State{source, next_code, local, frame, codes, failure}:
          definitions(State{source, next_code, local, frame, BIR.Code{code, Nil{}, parameters, body} <> codes, failure}, rest, registry, BIR.FunctionDeclaration{key, code, parameters} <> result)


# Parser/template diagnostics remain at the actual source boundary. A checked
# unused template binder is not silently accepted as an erased runtime parameter.
def template_binders(source: Arena.Arena, range: IR.Words, problem: Maybe<&2, Problem>) -> TemplateResult:
  match problem range:
    case Some{_} _: TemplateResult{source, problem}
    case None{} IR.Words{_, 0}: TemplateResult{source, None{}}
    case None{} IR.Words{start, count}:
      Tuple{source, id} = Arena.word(source, IR.arena_tape_offset(start))
      Tuple{source, binder} = Arena.get_binder(source, id)
      template_binder(source, binder, IR.Words{IR.arena_range_index(start, 1), U32.sub(count, 1)})
def template_binder(source: Arena.Arena, binder: Arena.Binder, rest: IR.Words) -> TemplateResult:
  match binder:
    case Arena.TemplateBinder{_, _, _, span}: TemplateResult{source, Some{Problem{"unexpanded template binder reached JS emission", span}}}
    case _: template_binders(source, rest, None{})
def template_declarations(source: Arena.Arena, declarations: List<&2, IR.TopLevel>, problem: Maybe<&2, Problem>) -> TemplateResult:
  match problem declarations:
    case Some{_} _: TemplateResult{source, problem}
    case None{} Nil{}: TemplateResult{source, None{}}
    case None{} declaration <> rest:
      template_declaration_result(template_declaration(source, declaration), rest)
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
def template_constructors(source: Arena.Arena, constructors: List<&2, IR.ConstructorDecl>, problem: Maybe<&2, Problem>) -> TemplateResult:
  match problem constructors:
    case Some{_} _: TemplateResult{source, problem}
    case None{} Nil{}: TemplateResult{source, None{}}
    case None{} IR.Constructor{_, fields, _} <> rest:
      template_constructor_result(template_binders(source, fields, None{}), rest)
def template_modules(source: Arena.Arena, modules: List<&2, IR.LoadedModule>, problem: Maybe<&2, Problem>) -> TemplateResult:
  match problem modules:
    case Some{_} _: TemplateResult{source, problem}
    case None{} Nil{}: TemplateResult{source, None{}}
    case None{} IR.LoadedModule{_, IR.Module{_, _, declarations}} <> rest:
      template_module_result(template_declarations(source, declarations, None{}), rest)
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
def emit_prepared(prepared: Prepared, exports: Maybe<&2, List<&2, String>>) -> EmitResult:
  match prepared:
    case Prepared{_, Some{Problem{message, span}}}: EmitFailure{message, span}
    case Prepared{program, None{}}: emit_catalog(Catalog.build(program, exports))
def emit_catalog(result: Catalog.BuildResult) -> EmitResult:
  match result:
    case Catalog.BuildFailure{_, message}: EmitFailure{message, no_span()}
    case Catalog.Built{Checked.CheckedProgram{source, _, _, _}, Catalog.Catalog{work, registry, constructors, families, type_functions, next_code, ending}}:
      state = State{source, next_code, 0, Frame{0, Nil{}, Nil{}, 0}, Nil{}, None{}}
      emit_definitions(definitions(state, work, registry, Nil{}), constructors, families, type_functions, ending)
def emit_definitions(result: LowerResult<List<&2, BIR.Declaration>>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, ending: BIR.Ending) -> EmitResult:
  match result:
    case LowerResult{State{_, _, _, _, codes, failure}, declarations}:
      emit_complete(failure, codes, declarations, constructors, families, type_functions, ending)
def emit_complete(failure: Maybe<&2, Problem>, codes: List<&2, BIR.Code>, declarations: List<&2, BIR.Declaration>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, ending: BIR.Ending) -> EmitResult:
  match failure:
    case Some{Problem{message, span}}: EmitFailure{message, span}
    case None{}:
      EmitSuccess{Backend.emit(BIR.Program{List.reverse(&2, BIR.Code, codes), declarations, constructors, families, type_functions, ending})}
def emit(program: Checked.CheckedProgram) -> EmitResult:
  emit_prepared(prepare(program), None{})
def emit_library(program: Checked.CheckedProgram, exports: List<&2, String>) -> EmitResult:
  emit_prepared(prepare(program), Some{exports})
