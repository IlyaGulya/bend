import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/checked_frontend.bend as Checked
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checker_arena.bend as Arena
import ../bend2/selfhost/checker_ir.bend as IR
import ../bend2/selfhost/scope_lookup.bend as Scope
import ../bend2/selfhost/index_lookup.bend as IndexLookup
import ../bend2/selfhost/path.bend as Path

type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

type cps_provider_1_ProgramResult is Data:
  cps_provider_1_Lowered{program: BIR.Program}
  cps_provider_1_LowerFailure{message: String, span: Ast.SourceSpan}

type cps_provider_1_Problem is Data:
  cps_provider_1_Problem{message: String, span: Ast.SourceSpan}

type cps_provider_1_Slot is Data:
  cps_provider_1_ErasedSlot{}
  cps_provider_1_Slot{owner: U32, identity: U32, value: BIR.Atom, use: BIR.Use}

type cps_provider_1_Capture is Data:
  cps_provider_1_Capture{slot: cps_provider_1_Slot, index: U32}

type cps_provider_1_Instruction is Data:
  cps_provider_1_Bind{id: U32, op: BIR.Op}
  cps_provider_1_Guard{condition: BIR.Atom, failure: BIR.Block}
  cps_provider_1_Stop{failure: BIR.Block}

type cps_provider_1_Frame is Data:
  cps_provider_1_Frame{owner: U32, instructions: List<&2, cps_provider_1_Instruction>, captures: List<&2, cps_provider_1_Capture>, capture_count: U32}

type cps_provider_2_NfContext is Data:
  cps_provider_2_NfContext{families: Map<&2, BIR.Family>, type_functions: Map<&2, BIR.TypeFunction>}

type cps_provider_1_State is Type:
  cps_provider_1_State{source: Arena.Arena, next_code: U32, next_local: U32, frame: cps_provider_1_Frame, codes: List<&2, BIR.Code>, failure: Maybe<&2, cps_provider_1_Problem>, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, cps_provider_2_NfContext>}

type cps_provider_1_LowerResult<-T: Type> is Type:
  cps_provider_1_LowerResult{state: cps_provider_1_State, value: T}

type cps_provider_1_CodeRef is Data:
  cps_provider_1_CodeRef{code: U32, parameters: List<&2, BIR.Parameter>, captures: List<&2, cps_provider_1_Capture>}

type cps_provider_1_SourceArgument is Data:
  cps_provider_1_SourceArgument{quantity: Ast.Quantity, occurrence: IR.Occurrence}

type cps_provider_1_Spine is Data:
  cps_provider_1_Spine{head: IR.Occurrence, args: List<&2, cps_provider_1_SourceArgument>}

type cps_provider_1_TemplateResult is Type:
  cps_provider_1_TemplateResult{source: Arena.Arena, problem: Maybe<&2, cps_provider_1_Problem>}

type cps_provider_1_Prepared is Type:
  cps_provider_1_Prepared{program: Checked.CheckedProgram, problem: Maybe<&2, cps_provider_1_Problem>}

type cps_provider_1_ArrowFacts is Data:
  cps_provider_1_ArrowFacts{uses: List<&2, BIR.Use>, domains: List<&2, BIR.Descriptor>}

type cps_provider_2_NfVal is Data:
  cps_provider_2_NfType{key: String, args: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfCtor{key: String, args: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfQuantity{quantity: BIR.Quantity}
  cps_provider_2_NfKind{quantity: BIR.Descriptor}
  cps_provider_2_NfOther{source: BIR.Descriptor}
  cps_provider_2_NfMissing{source: BIR.Descriptor}
  cps_provider_2_NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, cps_provider_2_NfVal>, sources: List<&2, BIR.Descriptor>}

type cps_provider_2_NfBind is Data:
  cps_provider_2_NfBound{bindings: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfMismatch{}
  cps_provider_2_NfUnknown{}

type cps_provider_2_NfStatus is Data:
  cps_provider_2_NfStatusOk{}
  cps_provider_2_NfStatusNo{}
  cps_provider_2_NfStatusMaybe{}

type cps_provider_2_Nf is Data:
  cps_provider_2_NfOk{val: cps_provider_2_NfVal}
  cps_provider_2_NfFail{message: String}

type cps_provider_2_NfList is Data:
  cps_provider_2_NfListOk{vals: List<&2, cps_provider_2_NfVal>}
  cps_provider_2_NfListFail{message: String}

type cps_provider_2_NfApp is Data:
  cps_provider_2_NfApp{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_2_NfArity is Data:
  cps_provider_2_NfArity{complete: Bool, exact: Bool, under: Bool}

type cps_provider_3_EmitResult is Data:
  cps_provider_3_EmitSuccess{source: String}
  cps_provider_3_EmitFailure{message: String, span: Ast.SourceSpan}

type cps_provider_3_LinkSource is Data:
  cps_provider_3_LinkSource{path: String, namespace: String, span: Ast.SourceSpan}

type cps_provider_3_LinkResult is Data:
  cps_provider_3_LinkSuccess{sources: List<&2, cps_provider_3_LinkSource>}
  cps_provider_3_LinkFailure{message: String, span: Ast.SourceSpan}

type cps_provider_3_JSParameter is Data:
  cps_provider_3_JSParameterNat{}
  cps_provider_3_JSParameterOther{}
  cps_provider_3_JSParameterUnresolved{}

type cps_provider_3_JSCidResult is Data:
  cps_provider_3_JSCidDone{source: String}
  cps_provider_3_JSCidFailure{message: String}

type cps_provider_3_JSMode is Data:
  cps_provider_3_JSCode{}
  cps_provider_3_JSLineComment{}
  cps_provider_3_JSBlockComment{}
  cps_provider_3_JSDoubleQuote{}
  cps_provider_3_JSSingleQuote{}
  cps_provider_3_JSBacktick{}

type cps_provider_3_JSScan is Data:
  cps_provider_3_JSScanComplete{output: List<&2, Char>}
  cps_provider_3_JSScanRefused{message: String}

type cps_provider_3_JSKeyScan is Data:
  cps_provider_3_JSKeyFound{key: String, rest: List<&2, Char>}
  cps_provider_3_JSKeyAbsent{}

type cps_provider_3_JSEffects is Data:
  cps_provider_3_JSEffectsReady{text: String}
  cps_provider_3_JSEffectsFailure{message: String, span: Ast.SourceSpan}

type cps_provider_3_TagArm is Data:
  cps_provider_3_TagArm{label: U32, condition: U32, tag: String, body: BIR.Block}

type cps_provider_3_TaggedRegion is Data:
  cps_provider_3_TaggedRegion{label: U32, condition: U32, subject: BIR.Atom, tag: String, body: BIR.Block, rest: BIR.Block}

type cps_provider_3_TagGroup is Data:
  cps_provider_3_TagGroup{arms: List<&2, cps_provider_3_TagArm>, rest: BIR.Block, count: Nat}

type cps_provider_3_JSDescriptorHead is Data:
  cps_provider_3_JSDescriptorHead{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_4_Foreign is Data:
  cps_provider_4_Foreign{namespace: String, imported: String, sources: List<&2, String>, span: Ast.SourceSpan, parameter_types: List<&2, BIR.Descriptor>, result: BIR.Descriptor}

type cps_provider_4_DefinitionHeader is Data:
  cps_provider_4_DefinitionHeader{symbol: IR.Symbol, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, cps_provider_4_Foreign>, fast: Bool}

type cps_provider_4_Definition is Data:
  cps_provider_4_Definition{header: cps_provider_4_DefinitionHeader, binders: IR.Words, result: IR.OptionalTerm, body: IR.DefBody, checked: Maybe<&2, IR.Occurrence>, scope: Scope.ArenaGlobalScope, native: Maybe<&2, String>, quantity_prefix: Nat}

type cps_provider_4_Constructor is Data:
  cps_provider_4_Constructor{layout: BIR.ConstructorLayout, quantities: List<&2, BIR.Quantity>, parameters: Nat, family: String}

type cps_provider_4_Registry is Data:
  cps_provider_4_Registry{definitions: Map<&2, cps_provider_4_DefinitionHeader>, constructors: Map<&2, cps_provider_4_Constructor>}

type cps_provider_4_Catalog is Data:
  cps_provider_4_Catalog{definitions: List<&2, cps_provider_4_Definition>, registry: cps_provider_4_Registry, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, next_code: U32, ending: BIR.Ending}

type cps_provider_4_BuildResult is Type:
  cps_provider_4_Built{program: Checked.CheckedProgram, catalog: cps_provider_4_Catalog}
  cps_provider_4_BuildFailure{program: Checked.CheckedProgram, message: String}

type cps_provider_4_CatalogResult<-T: Type> is Type:
  cps_provider_4_CatalogResult{source: Arena.Arena, value: T}

type cps_provider_4_Telescope is Data:
  cps_provider_4_Telescope{parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, fields: List<&2, BIR.DescriptorField>, fixed: Bool}

type cps_provider_4_Needed is Data:
  cps_provider_4_Needed{functions: List<&2, BIR.TypeFunction>, seen: Map<&2, Bool>}

type cps_provider_4_Root is Data:
  cps_provider_4_TermRoot{term: U32, scope: Scope.ArenaGlobalScope}
  cps_provider_4_DefinitionRoot{key: String}

type cps_provider_4_Preparation is Data:
  cps_provider_4_Preparation{definitions: List<&2, cps_provider_4_Definition>, index: Map<&2, cps_provider_4_Definition>, headers: Map<&2, cps_provider_4_DefinitionHeader>, constructors: List<&2, BIR.ConstructorLayout>, constructor_index: Map<&2, cps_provider_4_Constructor>, families: List<&2, BIR.Family>, next_code: U32, next_constructor: U32, roots: List<&2, cps_provider_4_Root>, main: Maybe<&2, BIR.Descriptor>, failure: Maybe<&2, String>, module_values: Map<&2, Bool>}

type cps_provider_4_Arms is Data:
  cps_provider_4_Arms{arms: List<&2, BIR.DescriptorArm>, state: cps_provider_4_Preparation}

type cps_provider_4_ExportFacts is Data:
  cps_provider_4_ExportFacts{parameter_types: List<&2, BIR.Descriptor>}

type cps_provider_4_ConstructorField is Data:
  cps_provider_4_ConstructorField{identity: U32, key: Maybe<&2, String>, quantity: BIR.Quantity}

def emitted(v_0: cps_provider_3_EmitResult) -> EmitResult:
  match v_0:
    case cps_provider_3_EmitFailure{v_4, v_5}:
      EmitFailure{v_4, v_5}
    case cps_provider_3_EmitSuccess{v_7}:
      EmitSuccess{v_7}

def emit_result(v_0: cps_provider_1_ProgramResult, v_2: List<&2, BIR.SourceFile>) -> EmitResult:
  match v_0:
    case cps_provider_1_LowerFailure{v_6, v_7}:
      EmitFailure{v_6, v_7}
    case cps_provider_1_Lowered{v_9}:
      emitted(cps_provider_3_emit_linked(v_9, v_2))

def emit(v_0: Checked.CheckedProgram, v_2: List<&2, BIR.SourceFile>) -> EmitResult:
  emit_result(cps_provider_1_lower(v_0), v_2)

def emit_library(v_0: Checked.CheckedProgram, v_3: List<&2, String>, v_5: List<&2, BIR.SourceFile>) -> EmitResult:
  emit_result(cps_provider_1_lower_library(v_0, v_3), v_5)

def cps_provider_1_use(v_0: Ast.Quantity) -> BIR.Use:
  match v_0:
    case Ast.QMany{}:
      BIR.Many{}
    case _:
      BIR.Affine{}

def cps_provider_1_bir_use(v_0: BIR.Quantity) -> BIR.Use:
  match v_0:
    case BIR.Unrestricted{}:
      BIR.Many{}
    case _:
      BIR.Affine{}

def cps_provider_1_no_span() -> Ast.SourceSpan:
  Ast.SpanOf{"", 0n, 0n}

def cps_provider_1_problem_first(v_2: Maybe<&2, cps_provider_1_Problem>, v_4: String, v_5: Ast.SourceSpan) -> Maybe<&2, cps_provider_1_Problem>:
  match v_2:
    case None{}:
      Some{cps_provider_1_Problem{v_4, v_5}}
    case Some{_}:
      v_2

def cps_provider_1_fail(v_1: cps_provider_1_State, v_3: String, v_4: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_State{v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_14, v_15, v_16, v_17, v_18, cps_provider_1_problem_first(v_19, v_3, v_4), v_20, v_21}, BIR.Null{}}

def cps_provider_1_native_match_state_problem_0(v_1: cps_provider_1_LowerResult<BIR.Atom>) -> cps_provider_1_State:
  match v_1:
    case cps_provider_1_LowerResult{v_5, _}:
      v_5

def cps_provider_1_state_problem(v_1: cps_provider_1_State, v_3: String, v_4: Ast.SourceSpan) -> cps_provider_1_State:
  cps_provider_1_native_match_state_problem_0(cps_provider_1_fail(v_1, v_3, v_4))

def cps_provider_1_native_match_node_0(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_5: U32, v_7: U32, v_9: cps_provider_1_Frame, v_11: List<&2, BIR.Code>, v_14: Maybe<&2, cps_provider_1_Problem>, v_16: Maybe<&2, Scope.ArenaGlobalScope>, v_18: Maybe<&2, cps_provider_2_NfContext>) -> cps_provider_1_LowerResult<Arena.Node>:
  match v_3:
    case (v_22, v_23):
      cps_provider_1_LowerResult{cps_provider_1_State{v_22, v_5, v_7, v_9, v_11, v_14, v_16, v_18}, v_23}

def cps_provider_1_native_match_node_1(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<Arena.Node>:
  match v_1:
    case cps_provider_1_State{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20}:
      cps_provider_1_native_match_node_0(Arena.get_node(v_13, v_3), v_14, v_15, v_16, v_17, v_18, v_19, v_20)

def cps_provider_1_node(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<Arena.Node>:
  cps_provider_1_native_match_node_1(v_1, v_3)

def cps_provider_1_native_match_name_0(v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_6: U32, v_8: U32, v_10: cps_provider_1_Frame, v_12: List<&2, BIR.Code>, v_15: Maybe<&2, cps_provider_1_Problem>, v_17: Maybe<&2, Scope.ArenaGlobalScope>, v_19: Maybe<&2, cps_provider_2_NfContext>) -> cps_provider_1_LowerResult<String>:
  match v_4:
    case (v_24, v_25):
      cps_provider_1_LowerResult{cps_provider_1_State{v_24, v_6, v_8, v_10, v_12, v_15, v_17, v_19}, v_25}

def cps_provider_1_native_match_name_1(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<String>:
  match v_1:
    case cps_provider_1_State{v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      cps_provider_1_native_match_name_0(Arena.name_text(v_14, v_3), v_15, v_16, v_17, v_18, v_19, v_20, v_21)

def cps_provider_1_name(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<String>:
  cps_provider_1_native_match_name_1(v_1, v_3)

def cps_provider_1_fresh(v_1: cps_provider_1_State) -> cps_provider_1_LowerResult<U32>:
  match v_1:
    case cps_provider_1_State{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_12, v_13, U32.inc(v_14), v_15, v_16, v_17, v_18, v_19}, v_14}

def cps_provider_1_reserve(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_State:
  match v_1:
    case cps_provider_1_State{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20}:
      cps_provider_1_State{v_13, v_14, U32.max(v_15, v_3), v_16, v_17, v_18, v_19, v_20}

def cps_provider_1_push(v_1: cps_provider_1_State, v_3: cps_provider_1_Instruction) -> cps_provider_1_State:
  match v_1:
    case cps_provider_1_State{v_16, v_17, v_18, cps_provider_1_Frame{v_19, v_20, v_21, v_22}, v_23, v_24, v_25, v_26}:
      cps_provider_1_State{v_16, v_17, v_18, cps_provider_1_Frame{v_19, v_3 <> v_20, v_21, v_22}, v_23, v_24, v_25, v_26}

def cps_provider_1_native_match_operation_0(v_2: cps_provider_1_LowerResult<U32>, v_3: BIR.Op) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_7, v_8}:
      cps_provider_1_LowerResult{cps_provider_1_push(v_7, cps_provider_1_Bind{v_8, v_3}), BIR.Local{v_8}}

def cps_provider_1_operation(v_1: cps_provider_1_State, v_2: BIR.Op) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_operation_0(cps_provider_1_fresh(v_1), v_2)

def cps_provider_1_guard(v_1: cps_provider_1_State, v_2: BIR.Atom, v_3: BIR.Block) -> cps_provider_1_State:
  match v_2:
    case BIR.Boolean{True{}}:
      v_1
    case BIR.Boolean{False{}}:
      cps_provider_1_push(v_1, cps_provider_1_Stop{v_3})
    case _:
      cps_provider_1_push(v_1, cps_provider_1_Guard{v_2, v_3})

def cps_provider_1_prefix(v_2: List<&2, cps_provider_1_Instruction>, v_3: BIR.Block) -> BIR.Block:
  match v_2:
    case []:
      v_3
    case cps_provider_1_Bind{v_7, v_8} <> v_9:
      cps_provider_1_prefix(v_9, BIR.Let{v_7, v_8, v_3})
    case cps_provider_1_Guard{v_14, v_15} <> v_16:
      cps_provider_1_prefix(v_16, BIR.Branch{v_14, v_3, v_15})
    case cps_provider_1_Stop{v_20} <> v_21:
      cps_provider_1_prefix(v_21, v_20)

def cps_provider_1_finish(v_2: List<&2, cps_provider_1_Instruction>, v_3: BIR.Atom) -> BIR.Block:
  match v_2, v_3:
    case cps_provider_1_Bind{v_8, v_9} <> v_10, BIR.Local{v_11}:
      cps_provider_1_finish_last(U32.is_eq(v_8, v_11), v_8, v_9, v_10, v_11)
    case _, _:
      cps_provider_1_prefix(v_2, BIR.Return{v_3})

def cps_provider_1_finish_last(v_1: Bool, v_3: U32, v_4: BIR.Op, v_7: List<&2, cps_provider_1_Instruction>, v_9: U32) -> BIR.Block:
  match v_1, v_4:
    case True{}, BIR.Direct{v_12, v_13}:
      cps_provider_1_prefix(v_7, BIR.TailDirect{v_12, v_13})
    case True{}, BIR.Apply{v_17, v_18}:
      cps_provider_1_prefix(v_7, BIR.TailApply{v_17, v_18})
    case _, _:
      cps_provider_1_prefix(v_7, BIR.Let{v_3, v_4, BIR.Return{BIR.Local{v_9}}})

def cps_provider_1_slot_at(v_2: List<&2, cps_provider_1_Slot>, v_4: Nat) -> Maybe<&2, cps_provider_1_Slot>:
  match v_2, v_4:
    case v_9 <> _, 0n:
      Some{v_9}
    case _ <> v_15, 1n+v_16:
      cps_provider_1_slot_at(v_15, v_16)
    case [], _:
      None{}

def cps_provider_1_capture_found(v_2: List<&2, cps_provider_1_Capture>, v_4: U32, v_6: U32) -> Maybe<&2, U32>:
  match v_2:
    case []:
      None{}
    case cps_provider_1_Capture{cps_provider_1_Slot{v_15, v_16, _, _}, v_19} <> v_20:
      cps_provider_1_capture_found_next(Bool.and(U32.is_eq(v_15, v_4), U32.is_eq(v_16, v_6)), v_19, v_20, v_4, v_6)
    case _ <> v_25:
      cps_provider_1_capture_found(v_25, v_4, v_6)

def cps_provider_1_capture_found_next(v_1: Bool, v_3: U32, v_6: List<&2, cps_provider_1_Capture>, v_8: U32, v_10: U32) -> Maybe<&2, U32>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_1_capture_found(v_6, v_8, v_10)

def cps_provider_1_resolve(v_1: cps_provider_1_State, v_3: cps_provider_1_Slot) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case cps_provider_1_ErasedSlot{}:
      cps_provider_1_LowerResult{v_1, BIR.Null{}}
    case cps_provider_1_Slot{v_9, v_10, v_11, v_12}:
      cps_provider_1_resolve_live(v_1, v_9, v_10, v_11, v_12)

def cps_provider_1_resolve_live(v_1: cps_provider_1_State, v_3: U32, v_5: U32, v_6: BIR.Atom, v_7: BIR.Use) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_State{v_20, v_21, v_22, cps_provider_1_Frame{v_23, v_24, v_25, v_26}, v_27, v_28, v_29, v_30}:
      cps_provider_1_resolve_owner(U32.is_eq(v_23, v_3), cps_provider_1_State{v_20, v_21, v_22, cps_provider_1_Frame{v_23, v_24, v_25, v_26}, v_27, v_28, v_29, v_30}, cps_provider_1_Slot{v_3, v_5, v_6, v_7})

def cps_provider_1_native_match_resolve_owner_0(v_1: cps_provider_1_State, v_3: cps_provider_1_Slot, v_5: U32, v_7: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_State{v_20, v_21, v_22, cps_provider_1_Frame{v_23, v_24, v_25, v_26}, v_27, v_28, v_29, v_30}:
      cps_provider_1_resolve_capture(cps_provider_1_capture_found(v_25, v_5, v_7), v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27, v_28, v_3, v_29, v_30)

def cps_provider_1_native_match_resolve_owner_1(v_1: Bool, v_3: cps_provider_1_Slot, v_5: cps_provider_1_State) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1, v_3:
    case True{}, cps_provider_1_Slot{_, _, v_13, _}:
      cps_provider_1_LowerResult{v_5, v_13}
    case _, cps_provider_1_Slot{v_21, v_22, _, _}:
      cps_provider_1_native_match_resolve_owner_0(v_5, v_3, v_21, v_22)
    case _, _:
      cps_provider_1_LowerResult{v_5, BIR.Null{}}

def cps_provider_1_resolve_owner(v_1: Bool, v_3: cps_provider_1_State, v_5: cps_provider_1_Slot) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_resolve_owner_1(v_1, v_5, v_3)

def cps_provider_1_resolve_capture(v_2: Maybe<&2, U32>, v_3: Arena.Arena, v_5: U32, v_7: U32, v_9: U32, v_12: List<&2, cps_provider_1_Instruction>, v_15: List<&2, cps_provider_1_Capture>, v_17: U32, v_19: List<&2, BIR.Code>, v_22: Maybe<&2, cps_provider_1_Problem>, v_24: cps_provider_1_Slot, v_26: Maybe<&2, Scope.ArenaGlobalScope>, v_28: Maybe<&2, cps_provider_2_NfContext>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case Some{v_31}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_3, v_5, v_7, cps_provider_1_Frame{v_9, v_12, v_15, v_17}, v_19, v_22, v_26, v_28}, BIR.Capture{v_31}}
    case None{}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_3, v_5, v_7, cps_provider_1_Frame{v_9, v_12, cps_provider_1_Capture{v_24, v_17} <> v_15, U32.inc(v_17)}, v_19, v_22, v_26, v_28}, BIR.Capture{v_17}}

def cps_provider_1_variable(v_1: cps_provider_1_State, v_4: List<&2, cps_provider_1_Slot>, v_6: Nat, v_7: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_variable_found(v_1, cps_provider_1_slot_at(v_4, v_6), v_7)

def cps_provider_1_variable_found(v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_1_Slot>, v_5: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_4:
    case Some{v_8}:
      cps_provider_1_resolve(v_1, v_8)
    case None{}:
      cps_provider_1_fail(v_1, "missing checked lexical binding", v_5)

def cps_provider_1_native_match_bind_slot_0(v_1: cps_provider_1_Frame, v_2: BIR.Atom, v_3: BIR.Use, v_5: U32, v_6: Arena.Arena, v_8: U32, v_10: U32, v_12: List<&2, BIR.Code>, v_15: Maybe<&2, cps_provider_1_Problem>, v_17: Maybe<&2, Scope.ArenaGlobalScope>, v_19: Maybe<&2, cps_provider_2_NfContext>) -> cps_provider_1_LowerResult<cps_provider_1_Slot>:
  match v_1:
    case cps_provider_1_Frame{v_26, _, _, _}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_6, v_8, v_10, v_1, v_12, v_15, v_17, v_19}, cps_provider_1_Slot{v_26, v_5, v_2, v_3}}

def cps_provider_1_native_match_bind_slot_1(v_1: cps_provider_1_State, v_2: BIR.Atom, v_3: BIR.Use, v_5: U32) -> cps_provider_1_LowerResult<cps_provider_1_Slot>:
  match v_1:
    case cps_provider_1_State{v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23}:
      cps_provider_1_native_match_bind_slot_0(v_19, v_2, v_3, v_5, v_16, v_17, v_18, v_20, v_21, v_22, v_23)

def cps_provider_1_native_match_bind_slot_2(v_2: cps_provider_1_LowerResult<U32>, v_3: BIR.Atom, v_4: BIR.Use) -> cps_provider_1_LowerResult<cps_provider_1_Slot>:
  match v_2:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_native_match_bind_slot_1(v_9, v_3, v_4, v_10)

def cps_provider_1_bind_slot(v_1: cps_provider_1_State, v_2: BIR.Atom, v_3: BIR.Use) -> cps_provider_1_LowerResult<cps_provider_1_Slot>:
  cps_provider_1_native_match_bind_slot_2(cps_provider_1_fresh(v_1), v_2, v_3)

def cps_provider_1_enter(v_1: cps_provider_1_State) -> cps_provider_1_LowerResult<cps_provider_1_Frame>:
  match v_1:
    case cps_provider_1_State{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_12, U32.inc(v_13), v_14, cps_provider_1_Frame{v_13, [], [], 0}, v_16, v_17, v_18, v_19}, v_15}

def cps_provider_1_capture_uses(v_2: List<&2, cps_provider_1_Capture>) -> List<&2, BIR.Use>:
  match v_2:
    case []:
      []
    case cps_provider_1_Capture{cps_provider_1_Slot{_, _, _, v_13}, _} <> v_15:
      v_13 <> cps_provider_1_capture_uses(v_15)
    case _ <> v_20:
      cps_provider_1_capture_uses(v_20)

def cps_provider_1_leave(v_1: cps_provider_1_State, v_3: cps_provider_1_Frame, v_5: List<&2, BIR.Parameter>, v_6: BIR.Block) -> cps_provider_1_LowerResult<cps_provider_1_CodeRef>:
  match v_1:
    case cps_provider_1_State{v_20, v_21, v_22, cps_provider_1_Frame{v_23, _, v_25, _}, v_27, v_28, v_29, v_30}:
      v_33 = List.reverse(&2, cps_provider_1_Capture, v_25)
      cps_provider_1_LowerResult{cps_provider_1_State{v_20, v_21, v_22, v_3, BIR.Code{v_23, cps_provider_1_capture_uses(v_33), v_5, v_6} <> v_27, v_28, v_29, v_30}, cps_provider_1_CodeRef{v_23, v_5, v_33}}

def cps_provider_1_leave_value(v_1: cps_provider_1_State, v_3: cps_provider_1_Frame, v_5: List<&2, BIR.Parameter>, v_6: BIR.Atom) -> cps_provider_1_LowerResult<cps_provider_1_CodeRef>:
  match v_1:
    case cps_provider_1_State{v_20, v_21, v_22, cps_provider_1_Frame{v_23, v_24, v_25, v_26}, v_27, v_28, v_29, v_30}:
      cps_provider_1_leave(cps_provider_1_State{v_20, v_21, v_22, cps_provider_1_Frame{v_23, [], v_25, v_26}, v_27, v_28, v_29, v_30}, v_3, v_5, cps_provider_1_finish(v_24, v_6))

def cps_provider_1_capture_arguments(v_1: cps_provider_1_State, v_4: List<&2, cps_provider_1_Capture>) -> cps_provider_1_LowerResult<List<&2, BIR.Arg>>:
  match v_4:
    case []:
      cps_provider_1_LowerResult{v_1, []}
    case cps_provider_1_Capture{v_10, _} <> v_12:
      cps_provider_1_capture_argument(v_1, v_10, v_12)

def cps_provider_1_native_match_capture_argument_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Arg>>, v_3: BIR.Use, v_4: BIR.Atom) -> cps_provider_1_LowerResult<List<&2, BIR.Arg>>:
  match v_2:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_LowerResult{v_9, BIR.Arg{v_3, v_4} <> v_10}

def cps_provider_1_native_match_capture_argument_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Capture>, v_5: BIR.Use) -> cps_provider_1_LowerResult<List<&2, BIR.Arg>>:
  match v_1:
    case cps_provider_1_LowerResult{v_10, v_11}:
      cps_provider_1_native_match_capture_argument_0(cps_provider_1_capture_arguments(v_10, v_4), v_5, v_11)

def cps_provider_1_native_match_capture_argument_2(v_1: cps_provider_1_Slot, v_3: cps_provider_1_State, v_6: List<&2, cps_provider_1_Capture>) -> cps_provider_1_LowerResult<List<&2, BIR.Arg>>:
  match v_1:
    case cps_provider_1_Slot{_, _, _, v_16}:
      cps_provider_1_native_match_capture_argument_1(cps_provider_1_resolve(v_3, v_1), v_6, v_16)
    case cps_provider_1_ErasedSlot{}:
      cps_provider_1_capture_arguments(v_3, v_6)

def cps_provider_1_capture_argument(v_1: cps_provider_1_State, v_3: cps_provider_1_Slot, v_6: List<&2, cps_provider_1_Capture>) -> cps_provider_1_LowerResult<List<&2, BIR.Arg>>:
  cps_provider_1_native_match_capture_argument_2(v_3, v_1, v_6)

def cps_provider_1_native_match_close_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Arg>>, v_4: U32, v_6: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_10, v_11}:
      cps_provider_1_operation(v_10, BIR.Closure{v_4, v_11, v_6})

def cps_provider_1_native_match_close_1(v_1: cps_provider_1_CodeRef, v_3: cps_provider_1_State) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_CodeRef{v_8, v_9, v_10}:
      cps_provider_1_native_match_close_0(cps_provider_1_capture_arguments(v_3, v_10), v_8, v_9)

def cps_provider_1_close(v_1: cps_provider_1_State, v_3: cps_provider_1_CodeRef) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_close_1(v_3, v_1)

def cps_provider_1_native_match_call_reference_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Arg>>, v_4: List<&2, BIR.Arg>, v_6: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_10, v_11}:
      cps_provider_1_operation(v_10, BIR.Direct{v_6, List.append(&2, BIR.Arg, v_11, v_4)})

def cps_provider_1_native_match_call_reference_1(v_1: cps_provider_1_CodeRef, v_3: cps_provider_1_State, v_5: List<&2, BIR.Arg>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_CodeRef{v_10, _, v_12}:
      cps_provider_1_native_match_call_reference_0(cps_provider_1_capture_arguments(v_3, v_12), v_5, v_10)

def cps_provider_1_call_reference(v_1: cps_provider_1_State, v_3: cps_provider_1_CodeRef, v_5: List<&2, BIR.Arg>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_call_reference_1(v_3, v_1, v_5)

def cps_provider_1_constructor_native(v_0: cps_provider_4_Constructor) -> String:
  match v_0:
    case cps_provider_4_Constructor{BIR.ConstructorLayout{_, _, Some{v_11}, _}, _, _, _}:
      v_11
    case _:
      ""

def cps_provider_1_constructor_id(v_0: cps_provider_4_Constructor) -> U32:
  match v_0:
    case cps_provider_4_Constructor{BIR.ConstructorLayout{v_9, _, _, _}, _, _, _}:
      v_9

def cps_provider_1_constructor_key(v_0: cps_provider_4_Constructor) -> String:
  match v_0:
    case cps_provider_4_Constructor{BIR.ConstructorLayout{_, v_10, _, _}, _, _, _}:
      v_10

def cps_provider_1_atom_arguments(v_1: List<&2, BIR.Atom>) -> List<&2, BIR.Arg>:
  match v_1:
    case []:
      []
    case v_5 <> v_6:
      BIR.Arg{BIR.Affine{}, v_5} <> cps_provider_1_atom_arguments(v_6)

def native_match_cps_provider_1_describe_0(v_38: cps_provider_4_CatalogResult<BIR.Descriptor>, v_15: U32, v_16: U32, v_17: cps_provider_1_Frame, v_18: List<&2, BIR.Code>, v_19: Maybe<&2, cps_provider_1_Problem>, v_24: Scope.ArenaGlobalScope, +v_25: cps_provider_2_NfContext) -> cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>:
  match v_38:
    case cps_provider_4_CatalogResult{v_29, v_30}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_29, v_15, v_16, v_17, v_18, v_19, Some{v_24}, Some{v_25}}, Some{cps_provider_2_normalize_in(v_25, v_30)}}

def native_match_cps_provider_1_describe_1(+v_20: Maybe<&2, Scope.ArenaGlobalScope>, +v_21: Maybe<&2, cps_provider_2_NfContext>, v_3: U32, v_14: Arena.Arena, v_15: U32, v_16: U32, v_17: cps_provider_1_Frame, v_18: List<&2, BIR.Code>, v_19: Maybe<&2, cps_provider_1_Problem>) -> cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>:
  match v_20, v_21:
    case Some{v_24}, Some{+v_25}:
      native_match_cps_provider_1_describe_0(cps_provider_4_descriptor(v_14, v_3, v_24), v_15, v_16, v_17, v_18, v_19, v_24, v_25)
    case _, _:
      cps_provider_1_LowerResult{cps_provider_1_State{v_14, v_15, v_16, v_17, v_18, cps_provider_1_problem_first(v_19, "missing definition scope for a checked descriptor", cps_provider_1_no_span), v_20, v_21}, None{}}

def native_match_cps_provider_1_describe_2(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>:
  match v_1:
    case cps_provider_1_State{v_14, v_15, v_16, v_17, v_18, v_19, +v_20, +v_21}:
      native_match_cps_provider_1_describe_1(v_20, v_21, v_3, v_14, v_15, v_16, v_17, v_18, v_19)

def cps_provider_1_describe(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>:
  native_match_cps_provider_1_describe_2(v_1, v_3)

def native_match_cps_provider_1_element_value_0(v_15: cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>) -> cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>:
  match v_15:
    case cps_provider_1_LowerResult{v_9, Some{v_10}}:
      cps_provider_1_LowerResult{v_9, [v_10]}
    case cps_provider_1_LowerResult{v_12, None{}}:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_12, "missing checked array element type", cps_provider_1_no_span), []}

def cps_provider_1_element_value(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>:
  native_match_cps_provider_1_element_value_0(cps_provider_1_describe(v_1, v_3))

def cps_provider_1_single_argument(v_0: BIR.Descriptor) -> Maybe<&2, BIR.Descriptor>:
  match v_0:
    case BIR.DescriptorRef{_, [v_5]}:
      Some{v_5}
    case BIR.DescriptorApplication{_, v_9}:
      Some{v_9}
    case BIR.DescriptorFill{_, [v_13]}:
      Some{v_13}
    case BIR.DescriptorPlus{_, [v_17]}:
      Some{v_17}
    case BIR.DescriptorNamedFill{_, _, [v_23]}:
      Some{v_23}
    case BIR.DescriptorNamedPlus{_, _, [v_29]}:
      Some{v_29}
    case _:
      None{}

def native_match_cps_provider_1_element_argument_0(v_21: Maybe<&2, BIR.Descriptor>, v_9: cps_provider_1_State) -> cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>:
  match v_21:
    case Some{v_13}:
      cps_provider_1_LowerResult{v_9, [v_13]}
    case None{}:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_9, "checked array type has no element argument", cps_provider_1_no_span), []}

def native_match_cps_provider_1_element_argument_1(v_20: cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>) -> cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>:
  match v_20:
    case cps_provider_1_LowerResult{v_9, [v_10]}:
      native_match_cps_provider_1_element_argument_0(cps_provider_1_single_argument(v_10), v_9)
    case cps_provider_1_LowerResult{v_18, _}:
      cps_provider_1_LowerResult{v_18, []}

def cps_provider_1_element_argument(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>:
  native_match_cps_provider_1_element_argument_1(cps_provider_1_element_value(v_1, v_3))

def cps_provider_1_primitive_element(v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Atom>, v_7: Maybe<&2, U32>, v_9: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_7, v_9:
    case Some{v_12}, True{}:
      cps_provider_1_primitive_types(v_2, cps_provider_1_atom_arguments(v_4), cps_provider_1_element_argument(v_1, v_12))
    case Some{v_17}, False{}:
      cps_provider_1_primitive_types(v_2, cps_provider_1_atom_arguments(v_4), cps_provider_1_element_value(v_1, v_17))
    case None{}, _:
      cps_provider_1_fail(v_1, "missing checked array element type", cps_provider_1_no_span)

def cps_provider_1_primitive_types(v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_5: cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_5:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_operation(v_9, BIR.PrimitiveCall{v_0, v_2, v_10})

def cps_provider_1_occurrence_type(v_0: IR.Occurrence) -> Maybe<&2, U32>:
  match v_0:
    case IR.TypedOccurrence{_, v_10, _, _, _, _}:
      Some{v_10}
    case IR.LocalReferenceOccurrence{_, v_20, _, _}:
      Some{v_20}
    case IR.ScalarOccurrence{_, v_29, _, _, _}:
      Some{v_29}
    case IR.StringOccurrence{_, v_38, _, _}:
      Some{v_38}
    case IR.CaseOccurrence{_, v_46, _, _}:
      Some{v_46}
    case IR.LocalOccurrence{_, v_55, _, _, _}:
      Some{v_55}

def cps_provider_1_first_binding_type(v_1: List<&2, IR.CheckedBinding>) -> Maybe<&2, U32>:
  match v_1:
    case []:
      None{}
    case IR.CheckedBinding{_, v_9, _} <> _:
      Some{v_9}

def cps_provider_1_first_occurrence_type(v_1: List<&2, IR.Occurrence>) -> Maybe<&2, U32>:
  match v_1:
    case []:
      None{}
    case v_6 <> _:
      cps_provider_1_occurrence_type(v_6)

def cps_provider_1_erased_type_term(v_2: List<&2, cps_provider_1_SourceArgument>) -> Maybe<&2, U32>:
  match v_2:
    case []:
      None{}
    case cps_provider_1_SourceArgument{Ast.QZero{}, v_7} <> _:
      Some{cps_provider_1_occurrence_term(v_7)}
    case _ <> v_13:
      cps_provider_1_erased_type_term(v_13)

def cps_provider_1_parameter_uses(v_1: List<&2, BIR.Parameter>) -> List<&2, BIR.Use>:
  match v_1:
    case []:
      []
    case BIR.Parameter{_, v_7} <> v_8:
      v_7 <> cps_provider_1_parameter_uses(v_8)

def cps_provider_1_live_argument_type(v_2: List<&2, cps_provider_1_SourceArgument>) -> Maybe<&2, U32>:
  match v_2:
    case []:
      None{}
    case cps_provider_1_SourceArgument{Ast.QZero{}, _} <> v_8:
      cps_provider_1_live_argument_type(v_8)
    case cps_provider_1_SourceArgument{_, v_14} <> _:
      cps_provider_1_occurrence_type(v_14)

def native_match_cps_provider_1_last_live_argument_type_0(v_21: Maybe<&2, U32>, v_14: IR.Occurrence) -> Maybe<&2, U32>:
  match v_21:
    case Some{v_18}:
      Some{v_18}
    case None{}:
      cps_provider_1_occurrence_type(v_14)

def native_match_cps_provider_1_last_live_argument_type_1(v_2: List<&2, cps_provider_1_SourceArgument>) -> Maybe<&2, U32>:
  match v_2:
    case []:
      None{}
    case cps_provider_1_SourceArgument{Ast.QZero{}, _} <> v_8:
      cps_provider_1_last_live_argument_type(v_8)
    case cps_provider_1_SourceArgument{_, v_14} <> v_15:
      native_match_cps_provider_1_last_live_argument_type_0(cps_provider_1_last_live_argument_type(v_15), v_14)

def cps_provider_1_last_live_argument_type(v_2: List<&2, cps_provider_1_SourceArgument>) -> Maybe<&2, U32>:
  native_match_cps_provider_1_last_live_argument_type_1(v_2)

def cps_provider_1_array_element_handle(v_0: BIR.Primitive, v_3: List<&2, cps_provider_1_SourceArgument>) -> Maybe<&2, U32>:
  match v_0:
    case BIR.PrimArrayNew{}:
      cps_provider_1_last_live_argument_type(v_3)
    case _:
      cps_provider_1_live_argument_type(v_3)

def cps_provider_1_array_element_is_argument(v_0: BIR.Primitive) -> Bool:
  match v_0:
    case BIR.PrimArrayGet{}:
      True{}
    case BIR.PrimArraySet{}:
      True{}
    case BIR.PrimArraySize{}:
      True{}
    case BIR.PrimArrayClone{}:
      True{}
    case BIR.PrimArraySwap{}:
      True{}
    case BIR.PrimArrayNode{}:
      True{}
    case BIR.PrimArrayLeft{}:
      True{}
    case BIR.PrimArrayRight{}:
      True{}
    case BIR.PrimIsArrayNode{}:
      True{}
    case _:
      False{}

def cps_provider_1_array_primitive(+v_0: BIR.Primitive) -> Bool:
  match v_0:
    case BIR.PrimArrayNew{}:
      True{}
    case BIR.PrimArraySet{}:
      True{}
    case BIR.PrimArrayGet{}:
      True{}
    case BIR.PrimArraySwap{}:
      True{}
    case BIR.PrimArraySize{}:
      True{}
    case BIR.PrimArrayClone{}:
      True{}
    case BIR.PrimArrayLeaf{}:
      True{}
    case BIR.PrimArrayNode{}:
      True{}
    case BIR.PrimArrayLeafValue{}:
      True{}
    case BIR.PrimArrayLeft{}:
      True{}
    case BIR.PrimArrayRight{}:
      True{}
    case BIR.PrimIsArrayLeaf{}:
      True{}
    case BIR.PrimIsArrayNode{}:
      True{}
    case _:
      False{}

def cps_provider_1_primitive(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Atom>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_operation(v_1, BIR.PrimitiveCall{v_2, cps_provider_1_atom_arguments(v_4), []})

def native_match_cps_provider_1_primitive_call_0(v_8: Bool, v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Arg>, v_7: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_8:
    case True{}:
      cps_provider_1_primitive_call_element(v_1, v_2, v_4, v_7)
    case False{}:
      cps_provider_1_operation(v_1, BIR.PrimitiveCall{v_2, v_4, []})

def cps_provider_1_primitive_call(v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Arg>, v_7: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_primitive_call_0(cps_provider_1_array_primitive(v_2), v_1, v_2, v_4, v_7)

def cps_provider_1_primitive_call_element(v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Arg>, v_7: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_7:
    case Some{v_10}:
      cps_provider_1_primitive_types(v_2, v_4, cps_provider_1_element_fact(v_1, v_10, cps_provider_1_array_element_is_argument(v_2)))
    case None{}:
      cps_provider_1_fail(v_1, "missing checked array element type", cps_provider_1_no_span)

def cps_provider_1_element_fact(v_1: cps_provider_1_State, v_3: U32, v_5: Bool) -> cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>:
  match v_5:
    case True{}:
      cps_provider_1_element_argument(v_1, v_3)
    case False{}:
      cps_provider_1_element_value(v_1, v_3)

def cps_provider_1_effective_arrayed(v_0: BIR.Primitive, v_2: Bool) -> Bool:
  match v_2:
    case True{}:
      True{}
    case False{}:
      cps_provider_1_array_element_is_argument(v_0)

def native_match_cps_provider_1_primitive_fact_0(v_10: Bool, v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Atom>, v_7: Maybe<&2, U32>, v_9: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_10:
    case True{}:
      cps_provider_1_primitive_element(v_1, v_2, v_4, v_7, cps_provider_1_effective_arrayed(v_2, v_9))
    case False{}:
      cps_provider_1_primitive(v_1, v_2, v_4)

def cps_provider_1_primitive_fact(v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Atom>, v_7: Maybe<&2, U32>, v_9: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_primitive_fact_0(cps_provider_1_array_primitive(v_2), v_1, v_2, v_4, v_7, v_9)

def cps_provider_1_field_values(v_1: cps_provider_1_State, v_2: cps_provider_4_Constructor, v_4: List<&2, BIR.Atom>, v_6: U32, v_7: Ast.SourceSpan) -> cps_provider_1_LowerResult<List<&2, BIR.Field>>:
  match v_4:
    case []:
      cps_provider_1_LowerResult{v_1, []}
    case v_12 <> v_13:
      cps_provider_1_field_value(v_1, cps_provider_4_constructor_field(v_2, v_6), v_2, v_12, v_13, v_6, v_7)

def cps_provider_1_native_match_field_value_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Field>>, v_3: BIR.Atom, v_5: U32, v_7: String, v_8: BIR.Quantity) -> cps_provider_1_LowerResult<List<&2, BIR.Field>>:
  match v_2:
    case cps_provider_1_LowerResult{v_13, v_14}:
      cps_provider_1_LowerResult{v_13, BIR.Field{v_5, v_7, cps_provider_1_bir_use(v_8), v_3} <> v_14}

def cps_provider_1_native_match_field_value_1(v_1: Maybe<&2, cps_provider_4_ConstructorField>, v_3: cps_provider_1_State, v_4: cps_provider_4_Constructor, v_5: BIR.Atom, v_7: List<&2, BIR.Atom>, v_9: U32, v_10: Ast.SourceSpan) -> cps_provider_1_LowerResult<List<&2, BIR.Field>>:
  match v_1:
    case Some{cps_provider_4_ConstructorField{_, _, BIR.Erased{}}}:
      cps_provider_1_field_values(v_3, v_4, v_7, U32.inc(v_9), v_10)
    case Some{cps_provider_4_ConstructorField{v_21, Some{v_22}, v_23}}:
      cps_provider_1_native_match_field_value_0(cps_provider_1_field_values(v_3, v_4, v_7, U32.inc(v_9), v_10), v_5, v_21, v_22, v_23)
    case _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_3, "missing checked constructor field layout", v_10), []}

def cps_provider_1_field_value(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_ConstructorField>, v_4: cps_provider_4_Constructor, v_5: BIR.Atom, v_7: List<&2, BIR.Atom>, v_9: U32, v_10: Ast.SourceSpan) -> cps_provider_1_LowerResult<List<&2, BIR.Field>>:
  cps_provider_1_native_match_field_value_1(v_3, v_1, v_4, v_5, v_7, v_9, v_10)

def cps_provider_1_construct(v_1: cps_provider_1_State, v_2: cps_provider_4_Constructor, v_4: List<&2, BIR.Atom>, v_5: Ast.SourceSpan, v_8: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_construct_native(v_1, cps_provider_1_constructor_native(v_2), v_2, v_4, v_5, v_8)

def cps_provider_1_native_match_construct_native_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Field>>, v_3: cps_provider_4_Constructor) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_7, v_8}:
      cps_provider_1_operation(v_7, BIR.Construct{cps_provider_1_constructor_id(v_3), cps_provider_1_constructor_key(v_3), v_8})

def cps_provider_1_native_match_construct_native_1(v_1: String, v_3: List<&2, BIR.Atom>, v_5: cps_provider_1_State, v_6: cps_provider_4_Constructor, v_7: Ast.SourceSpan, v_10: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1, v_3:
    case "Nat.Zero", []:
      cps_provider_1_LowerResult{v_5, BIR.Natural{0n}}
    case "Bool.False", []:
      cps_provider_1_LowerResult{v_5, BIR.Boolean{False{}}}
    case "Bool.True", []:
      cps_provider_1_LowerResult{v_5, BIR.Boolean{True{}}}
    case "String.SNil", []:
      cps_provider_1_LowerResult{v_5, BIR.Text{""}}
    case "Nat.Succ", [v_13]:
      cps_provider_1_primitive(v_5, BIR.PrimNatSuccessor{}, [v_13])
    case "Char.Chr", [v_16]:
      cps_provider_1_primitive(v_5, BIR.PrimCharNew{}, [v_16])
    case "String.SCon", [v_20, v_21]:
      cps_provider_1_primitive(v_5, BIR.PrimStringAppend{}, [v_20, v_21])
    case "U32.U32", [v_24]:
      cps_provider_1_primitive(v_5, BIR.PrimWordToU32{}, [v_24])
    case "F32.F32", [v_27]:
      cps_provider_1_primitive(v_5, BIR.PrimF32FromWord{}, [v_27])
    case "Array.ALeaf", [v_30]:
      cps_provider_1_primitive_fact(v_5, BIR.PrimArrayLeaf{}, [v_30], v_10, False{})
    case "Array.ANode", [v_34, v_35]:
      cps_provider_1_primitive_fact(v_5, BIR.PrimArrayNode{}, [v_34, v_35], v_10, False{})
    case _, _:
      cps_provider_1_native_match_construct_native_0(cps_provider_1_field_values(v_5, v_6, v_3, 0, v_7), v_6)

def cps_provider_1_construct_native(v_1: cps_provider_1_State, v_3: String, v_4: cps_provider_4_Constructor, v_6: List<&2, BIR.Atom>, v_7: Ast.SourceSpan, v_10: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_construct_native_1(v_3, v_6, v_1, v_4, v_7, v_10)

def cps_provider_1_construct_symbol(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_3: IR.Symbol, v_5: List<&2, BIR.Atom>, v_6: Ast.SourceSpan, v_9: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_construct_found(v_1, cps_provider_4_lookup_constructor(v_2, v_3), v_5, v_6, v_9)

def cps_provider_1_construct_found(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_Constructor>, v_5: List<&2, BIR.Atom>, v_6: Ast.SourceSpan, v_9: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case None{}:
      cps_provider_1_fail(v_1, "missing resolved constructor", v_6)
    case Some{v_13}:
      cps_provider_1_construct(v_1, v_13, v_5, v_6, v_9)

def cps_provider_1_native_match_constructor_operands_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_2:
    case cps_provider_1_LowerResult{v_7, v_8}:
      cps_provider_1_LowerResult{v_7, BIR.Null{} <> v_8}

def cps_provider_1_native_match_constructor_operands_1(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_3: BIR.Atom) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_2:
    case cps_provider_1_LowerResult{v_8, v_9}:
      cps_provider_1_LowerResult{v_8, v_3 <> v_9}

def cps_provider_1_native_match_constructor_operands_2(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: cps_provider_4_Registry, v_6: Ast.SourceSpan, v_8: List<&2, IR.Occurrence>, v_10: List<&2, IR.CheckedBinding>) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_1:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_constructor_operands_1(cps_provider_1_constructor_operands(v_15, v_8, v_10, v_4, v_5, v_6), v_16)

def cps_provider_1_native_match_constructor_operands_3(v_1: List<&2, IR.Occurrence>, v_3: List<&2, IR.CheckedBinding>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_1, v_3:
    case [], []:
      cps_provider_1_LowerResult{v_5, []}
    case _ <> v_19, IR.CheckedBinding{Ast.QZero{}, _, _} <> v_22:
      cps_provider_1_native_match_constructor_operands_0(cps_provider_1_constructor_operands(v_5, v_19, v_22, v_8, v_9, v_10))
    case v_29 <> v_30, _ <> v_32:
      cps_provider_1_native_match_constructor_operands_2(cps_provider_1_lower_occurrence(v_5, v_29, v_8, v_9), v_8, v_9, v_10, v_30, v_32)
    case _, _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_5, "incomplete checked constructor operands", v_10), []}

def cps_provider_1_constructor_operands(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  cps_provider_1_native_match_constructor_operands_3(v_3, v_5, v_1, v_8, v_9, v_10)

def cps_provider_1_reference(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_DefinitionHeader>, v_4: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case None{}:
      cps_provider_1_fail(v_1, "missing resolved definition", v_4)
    case Some{cps_provider_4_DefinitionHeader{_, v_17, v_18, v_19, _, v_21, v_22, v_23, _}}:
      cps_provider_1_reference_kind(v_1, v_17, v_18, v_19, v_21, v_22, v_23)

def cps_provider_1_native_match_reference_kind_0(v_1: Bool, v_3: Maybe<&2, BIR.Primitive>, v_5: Maybe<&2, cps_provider_4_Foreign>, v_7: List<&2, BIR.Parameter>, v_9: cps_provider_1_State, v_11: String, v_13: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1, v_3, v_5, v_7:
    case True{}, _, _, _:
      cps_provider_1_LowerResult{v_9, BIR.Null{}}
    case False{}, Some{_}, _, _:
      cps_provider_1_LowerResult{v_9, BIR.Symbol{v_13, v_11}}
    case False{}, None{}, None{}, _ <> _:
      cps_provider_1_LowerResult{v_9, BIR.Symbol{v_13, v_11}}
    case _, _, _, _:
      cps_provider_1_operation(v_9, BIR.LoadSymbol{v_13, v_11})

def cps_provider_1_reference_kind(v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Bool, v_11: Maybe<&2, BIR.Primitive>, v_13: Maybe<&2, cps_provider_4_Foreign>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_reference_kind_0(v_9, v_11, v_13, v_7, v_1, v_3, v_5)

def cps_provider_1_symbol_value(v_1: cps_provider_1_State, v_2: IR.Symbol, v_3: cps_provider_4_Registry, v_4: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case IR.Symbol{_, _, IR.FamilySymbol{}, _}:
      cps_provider_1_LowerResult{v_1, BIR.Null{}}
    case IR.Symbol{_, _, IR.ConstructorSymbol{}, _}:
      cps_provider_1_construct_symbol(v_1, v_3, v_2, [], v_4, None{})
    case _:
      cps_provider_1_reference(v_1, cps_provider_4_lookup_definition(v_3, v_2), v_4)

def cps_provider_1_string_authorized(v_0: cps_provider_4_Registry, v_2: List<&2, IR.Symbol>, v_5: List<&2, String>) -> Bool:
  match v_2, v_5:
    case [], []:
      True{}
    case v_11 <> v_12, v_13 <> v_14:
      cps_provider_1_string_authorized_found(cps_provider_4_lookup_constructor(v_0, v_11), v_0, v_13, v_12, v_14)
    case _, _:
      False{}

def cps_provider_1_string_authorized_found(v_1: Maybe<&2, cps_provider_4_Constructor>, v_2: cps_provider_4_Registry, v_4: String, v_6: List<&2, IR.Symbol>, v_9: List<&2, String>) -> Bool:
  match v_1:
    case None{}:
      False{}
    case Some{v_12}:
      Bool.and(String.eq(cps_provider_1_constructor_native(v_12), v_4), cps_provider_1_string_authorized(v_2, v_6, v_9))

def cps_provider_1_scalar_characters(v_2: List<&2, U32>) -> Maybe<&2, List<&2, Char>>:
  match v_2:
    case []:
      Some{[]}
    case v_8 <> v_9:
      cps_provider_1_scalar_character(Bool.and(U32.is_le(v_8, 1114111), Bool.or(U32.is_lt(v_8, 55296), U32.is_gt(v_8, 57343))), v_8, v_9)

def cps_provider_1_scalar_character(v_1: Bool, v_3: U32, v_6: List<&2, U32>) -> Maybe<&2, List<&2, Char>>:
  match v_1:
    case False{}:
      None{}
    case True{}:
      cps_provider_1_scalar_character_rest(v_3, cps_provider_1_scalar_characters(v_6))

def cps_provider_1_scalar_character_rest(v_1: U32, v_5: Maybe<&2, List<&2, Char>>) -> Maybe<&2, List<&2, Char>>:
  match v_5:
    case None{}:
      None{}
    case Some{v_10}:
      Some{Char.from_u32(v_1) <> v_10}

def cps_provider_1_native_match_literal_word_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Registry, v_3: IR.Symbol, v_4: Ast.SourceSpan, v_5: BIR.Atom) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_construct_symbol(v_9, v_2, v_3, [v_5, v_10], v_4, None{})

def cps_provider_1_native_match_literal_word_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Registry, v_4: U32, v_5: IR.Symbol, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: Ast.SourceSpan, v_11: Nat) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_literal_word_0(cps_provider_1_literal_word(v_15, v_2, v_11, U32.shr(v_4), v_5, v_6, v_7, v_8, v_9), v_2, v_6, v_9, v_16)

def cps_provider_1_native_match_literal_word_2(v_1: Nat, v_3: cps_provider_1_State, v_4: cps_provider_4_Registry, v_6: U32, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case 0n:
      cps_provider_1_construct_symbol(v_3, v_4, v_7, [], v_11, None{})
    case 1n+v_15:
      cps_provider_1_native_match_literal_word_1(cps_provider_1_literal_bit(v_3, v_4, U32.is_eq(U32.and(v_6, 1), 0), v_9, v_10, v_11), v_4, v_6, v_7, v_8, v_9, v_10, v_11, v_15)

def cps_provider_1_literal_word(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_4: Nat, v_6: U32, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_literal_word_2(v_4, v_1, v_2, v_6, v_7, v_8, v_9, v_10, v_11)

def cps_provider_1_literal_bit(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_4: Bool, v_5: IR.Symbol, v_6: IR.Symbol, v_7: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_4:
    case True{}:
      cps_provider_1_construct_symbol(v_1, v_2, v_5, [], v_7, None{})
    case False{}:
      cps_provider_1_construct_symbol(v_1, v_2, v_6, [], v_7, None{})

def cps_provider_1_literal_string(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_5: List<&2, U32>, v_7: List<&2, IR.Symbol>, v_8: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_literal_string_authorized(v_1, v_2, v_5, v_7, v_8, cps_provider_1_string_authorized(v_2, v_7, ["String.SNil", "String.SCon", "Char.Chr", "U32.U32", "Word.Nil.WNil", "Word.Con.WCon", "Bool.False", "Bool.True"]))

def cps_provider_1_literal_string_authorized(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_5: List<&2, U32>, v_7: List<&2, IR.Symbol>, v_8: Ast.SourceSpan, v_10: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_10:
    case True{}:
      cps_provider_1_literal_string_payload(v_1, v_2, v_5, v_7, v_8, cps_provider_1_scalar_characters(v_5))
    case False{}:
      cps_provider_1_literal_string_records(v_1, v_2, v_5, v_7, v_8)

def cps_provider_1_literal_string_payload(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_5: List<&2, U32>, v_7: List<&2, IR.Symbol>, v_8: Ast.SourceSpan, v_12: Maybe<&2, List<&2, Char>>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_12:
    case Some{v_15}:
      cps_provider_1_LowerResult{v_1, BIR.Text{String.from_list(v_15)}}
    case None{}:
      cps_provider_1_literal_string_records(v_1, v_2, v_5, v_7, v_8)

def cps_provider_1_literal_string_records(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_5: List<&2, U32>, v_7: List<&2, IR.Symbol>, v_8: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_7:
    case [v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25]:
      cps_provider_1_literal_string_items(v_1, v_2, v_5, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_8)
    case _:
      cps_provider_1_fail(v_1, "incomplete checked string literal identities", v_8)

def cps_provider_1_native_match_literal_string_items_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Registry, v_3: IR.Symbol, v_4: Ast.SourceSpan, v_5: BIR.Atom) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_construct_symbol(v_9, v_2, v_3, [v_5, v_10], v_4, None{})

def cps_provider_1_native_match_literal_string_items_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Registry, v_3: IR.Symbol, v_4: IR.Symbol, v_5: IR.Symbol, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan, v_14: List<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_18, v_19}:
      cps_provider_1_native_match_literal_string_items_0(cps_provider_1_literal_string_items(v_18, v_2, v_14, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11), v_2, v_4, v_11, v_19)

def cps_provider_1_native_match_literal_string_items_2(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Registry, v_3: IR.Symbol, v_4: IR.Symbol, v_5: IR.Symbol, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan, v_14: List<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_18, v_19}:
      cps_provider_1_native_match_literal_string_items_1(cps_provider_1_construct_symbol(v_18, v_2, v_5, [v_19], v_11, None{}), v_2, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_14)

def cps_provider_1_native_match_literal_string_items_3(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Registry, v_3: IR.Symbol, v_4: IR.Symbol, v_5: IR.Symbol, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: Ast.SourceSpan, v_14: List<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_18, v_19}:
      cps_provider_1_native_match_literal_string_items_2(cps_provider_1_construct_symbol(v_18, v_2, v_6, [v_19], v_11, None{}), v_2, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_14)

def cps_provider_1_native_match_literal_string_items_4(v_2: List<&2, U32>, v_4: cps_provider_1_State, v_5: cps_provider_4_Registry, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case []:
      cps_provider_1_construct_symbol(v_4, v_5, v_6, [], v_14, None{})
    case v_19 <> v_20:
      cps_provider_1_native_match_literal_string_items_3(cps_provider_1_literal_word(v_4, v_5, 32n, v_19, v_10, v_11, v_12, v_13, v_14), v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_20)

def cps_provider_1_literal_string_items(v_1: cps_provider_1_State, v_2: cps_provider_4_Registry, v_5: List<&2, U32>, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_literal_string_items_4(v_5, v_1, v_2, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14)

def cps_provider_1_native_match_spine_0(v_1: cps_provider_1_LowerResult<Arena.Node>, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, IR.Occurrence>) -> cps_provider_1_LowerResult<cps_provider_1_Spine>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_spine_shape(v_12, v_13, v_2, v_7, v_5)

def cps_provider_1_native_match_spine_1(v_0: IR.Occurrence, v_2: cps_provider_1_State, v_5: List<&2, cps_provider_1_SourceArgument>) -> cps_provider_1_LowerResult<cps_provider_1_Spine>:
  match v_0:
    case IR.TypedOccurrence{v_14, _, _, _, _, v_19}:
      cps_provider_1_native_match_spine_0(cps_provider_1_node(v_2, v_14), v_0, v_5, v_19)
    case _:
      cps_provider_1_LowerResult{v_2, cps_provider_1_Spine{v_0, v_5}}

def cps_provider_1_spine(v_1: cps_provider_1_State, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_SourceArgument>) -> cps_provider_1_LowerResult<cps_provider_1_Spine>:
  cps_provider_1_native_match_spine_1(v_2, v_1, v_5)

def cps_provider_1_spine_shape(v_1: cps_provider_1_State, v_2: Arena.Node, v_3: IR.Occurrence, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_SourceArgument>) -> cps_provider_1_LowerResult<cps_provider_1_Spine>:
  match v_2, v_3, v_5:
    case Arena.TermApp{_, _, _}, IR.TypedOccurrence{_, _, Some{v_27}, _, _, _}, [v_31, v_32]:
      cps_provider_1_spine(v_1, v_31, cps_provider_1_SourceArgument{v_27, v_32} <> v_8)
    case Arena.TermAnn{_, _, _}, _, [v_44, _]:
      cps_provider_1_spine(v_1, v_44, v_8)
    case Arena.TermBang{_, _}, _, [v_54]:
      cps_provider_1_spine(v_1, v_54, v_8)
    case _, _, _:
      cps_provider_1_LowerResult{v_1, cps_provider_1_Spine{v_3, v_8}}

def cps_provider_1_head_definition(v_0: IR.Occurrence, v_1: cps_provider_4_Registry) -> Maybe<&2, cps_provider_4_DefinitionHeader>:
  match v_0:
    case IR.TypedOccurrence{_, _, _, Some{IR.Symbol{v_14, v_15, IR.DefinitionSymbol{}, v_16}}, _, _}:
      cps_provider_4_lookup_definition(v_1, IR.Symbol{v_14, v_15, IR.DefinitionSymbol{}, v_16})
    case _:
      None{}

def cps_provider_1_applications(v_1: cps_provider_1_State, v_3: cps_provider_1_Spine, v_5: U32, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case cps_provider_1_Spine{v_14, v_15}:
      cps_provider_1_application_header(v_1, cps_provider_1_head_definition(v_14, v_9), v_14, v_15, v_5, v_8, v_9, v_10)

def cps_provider_1_native_match_application_header_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_apply_rest(v_12, v_13, v_4, v_7, v_8)

def cps_provider_1_native_match_application_header_1(v_1: Maybe<&2, cps_provider_4_DefinitionHeader>, v_3: cps_provider_1_State, v_4: IR.Occurrence, v_7: List<&2, cps_provider_1_SourceArgument>, v_9: U32, v_12: List<&2, cps_provider_1_Slot>, v_13: cps_provider_4_Registry, v_14: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case Some{cps_provider_4_DefinitionHeader{_, _, v_25, v_26, v_27, False{}, v_28, None{}, v_29}}:
      cps_provider_1_application_known(v_3, v_28, v_29, v_25, v_26, List.length(&2, BIR.Quantity, v_27), v_4, v_7, v_9, v_12, v_13, v_14)
    case _:
      cps_provider_1_native_match_application_header_0(cps_provider_1_lower_occurrence(v_3, v_4, v_12, v_13), v_7, v_12, v_13)

def cps_provider_1_application_header(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_DefinitionHeader>, v_4: IR.Occurrence, v_7: List<&2, cps_provider_1_SourceArgument>, v_9: U32, v_12: List<&2, cps_provider_1_Slot>, v_13: cps_provider_4_Registry, v_14: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_application_header_1(v_3, v_1, v_4, v_7, v_9, v_12, v_13, v_14)

def cps_provider_1_application_known(v_1: cps_provider_1_State, v_3: Maybe<&2, BIR.Primitive>, v_5: Bool, v_7: U32, v_9: List<&2, BIR.Parameter>, v_11: Nat, v_12: IR.Occurrence, v_15: List<&2, cps_provider_1_SourceArgument>, v_17: U32, v_20: List<&2, cps_provider_1_Slot>, v_21: cps_provider_4_Registry, v_22: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case Some{v_25}:
      cps_provider_1_application_native(v_1, Bool.and(Nat.is_ge(List.length(&2, cps_provider_1_SourceArgument, v_15), v_11), Nat.is_eq(List.length(&2, BIR.Parameter, v_9), cps_provider_4_primitive_arity(v_25))), v_25, v_11, v_12, v_15, v_9, v_17, v_20, v_21)
    case None{}:
      cps_provider_1_application_direct(v_1, v_5, v_7, v_9, v_11, v_12, v_15, v_20, v_21, v_22)

def cps_provider_1_native_match_application_native_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_apply_rest(v_12, v_13, v_4, v_7, v_8)

def cps_provider_1_native_match_application_native_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: cps_provider_4_Registry, v_8: List<&2, cps_provider_1_SourceArgument>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_apply_rest(v_12, v_13, v_8, v_4, v_5)

def cps_provider_1_native_match_application_native_2(v_6: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, cps_provider_1_SourceArgument>>, v_7: BIR.Primitive, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_13: cps_provider_1_State, v_16: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_6:
    case (v_20, v_21):
      cps_provider_1_native_match_application_native_1(cps_provider_1_primitive_call(v_13, v_7, v_20, v_16), v_10, v_11, v_21)

def cps_provider_1_native_match_application_native_3(v_5: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>, v_6: BIR.Primitive, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry, v_13: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_5:
    case cps_provider_1_LowerResult{v_17, v_18}:
      cps_provider_1_native_match_application_native_2(v_18, v_6, v_9, v_10, v_17, v_13)

def native_match_cps_provider_1_arrow_facts_0(v_0: BIR.Descriptor, v_6: Nat) -> cps_provider_1_ArrowFacts:
  match v_0:
    case BIR.DescriptorArrow{v_10, v_11, v_12}:
      cps_provider_1_arrow_facts(v_12, v_6)
    case _:
      cps_provider_1_ArrowFacts{[], []}

def native_match_cps_provider_1_arrow_facts_1(v_2: Nat, v_0: BIR.Descriptor) -> cps_provider_1_ArrowFacts:
  match v_2:
    case 0n:
      cps_provider_1_arrow_facts_rest(v_0)
    case 1n+v_6:
      native_match_cps_provider_1_arrow_facts_0(v_0, v_6)

def cps_provider_1_arrow_facts(v_0: BIR.Descriptor, v_2: Nat) -> cps_provider_1_ArrowFacts:
  native_match_cps_provider_1_arrow_facts_1(v_2, v_0)

def native_match_cps_provider_1_arrow_facts_rest_0(v_16: cps_provider_1_ArrowFacts, v_5: BIR.Quantity, v_6: BIR.Descriptor) -> cps_provider_1_ArrowFacts:
  match v_16:
    case cps_provider_1_ArrowFacts{v_11, v_12}:
      cps_provider_1_ArrowFacts{cps_provider_1_bir_use(v_5) <> v_11, v_6 <> v_12}

def native_match_cps_provider_1_arrow_facts_rest_1(v_0: BIR.Descriptor) -> cps_provider_1_ArrowFacts:
  match v_0:
    case BIR.DescriptorArrow{v_5, v_6, v_7}:
      native_match_cps_provider_1_arrow_facts_rest_0(cps_provider_1_arrow_facts_rest(v_7), v_5, v_6)
    case _:
      cps_provider_1_ArrowFacts{[], []}

def cps_provider_1_arrow_facts_rest(v_0: BIR.Descriptor) -> cps_provider_1_ArrowFacts:
  native_match_cps_provider_1_arrow_facts_rest_1(v_0)

def cps_provider_1_last_domain(v_1: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match v_1:
    case []:
      None{}
    case v_5 <> v_6:
      cps_provider_1_last_domain_rest(v_6, v_5)

def cps_provider_1_last_domain_rest(v_1: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> Maybe<&2, BIR.Descriptor>:
  match v_1:
    case []:
      Some{v_2}
    case v_6 <> v_7:
      cps_provider_1_last_domain_rest(v_7, v_6)

def cps_provider_1_first_element_argument(v_1: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match v_1:
    case []:
      None{}
    case v_5 <> _:
      cps_provider_1_single_argument(v_5)

def cps_provider_1_partial_element(v_0: BIR.Primitive, v_2: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match v_0:
    case BIR.PrimArrayNew{}:
      cps_provider_1_last_domain(v_2)
    case _:
      cps_provider_1_first_element_argument(v_2)

def cps_provider_1_parameterize(v_1: List<&2, BIR.Parameter>, v_3: List<&2, BIR.Use>) -> List<&2, BIR.Parameter>:
  match v_1, v_3:
    case [], _:
      []
    case BIR.Parameter{v_12, _} <> v_14, v_15 <> v_16:
      BIR.Parameter{v_12, v_15} <> cps_provider_1_parameterize(v_14, v_16)
    case _, []:
      []

def native_match_cps_provider_1_partial_array_parameters_0(v_11: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>, v_3: List<&2, BIR.Use>) -> cps_provider_1_LowerResult<List<&2, BIR.Parameter>>:
  match v_11:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_LowerResult{v_9, cps_provider_1_parameterize(v_10, v_3)}

def cps_provider_1_partial_array_parameters(v_1: cps_provider_1_State, v_3: List<&2, BIR.Use>) -> cps_provider_1_LowerResult<List<&2, BIR.Parameter>>:
  native_match_cps_provider_1_partial_array_parameters_0(cps_provider_1_new_parameters(v_1, List.length(&2, BIR.Use, v_3)), v_3)

def native_match_cps_provider_1_partial_array_code_0(v_14: cps_provider_1_LowerResult<U32>, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_14:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_partial_array_body(v_12, v_2, v_4, v_6, v_7, v_13)

def cps_provider_1_partial_array_code(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_partial_array_code_0(cps_provider_1_fresh(v_1), v_2, v_4, v_6, v_7)

def cps_provider_1_partial_block(+v_1: U32, v_2: BIR.Op) -> BIR.Block:
  BIR.Let{v_1, v_2, BIR.Return{BIR.Local{v_1}}}

def cps_provider_1_partial_call(v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Parameter>, v_5: BIR.Descriptor) -> BIR.Op:
  BIR.PrimitiveCall{v_0, List.append(&2, BIR.Arg, cps_provider_1_indexed_captures(v_2, 0), cps_provider_1_parameter_arguments(v_4)), [v_5]}

def cps_provider_1_partial_array_body(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor, +v_9: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_State{v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26}:
      v_30 = cps_provider_1_partial_block(v_9, cps_provider_1_partial_call(v_2, v_4, v_6, v_7))
      v_33 = BIR.Code{v_20, cps_provider_1_capture_argument_uses(v_4), v_6, v_30}
      cps_provider_1_operation(cps_provider_1_State{v_19, U32.inc(v_20), v_21, v_22, v_33 <> v_23, v_24, v_25, v_26}, BIR.Closure{v_20, v_4, v_6})

def cps_provider_1_capture_argument_uses(v_1: List<&2, BIR.Arg>) -> List<&2, BIR.Use>:
  match v_1:
    case []:
      []
    case BIR.Arg{v_6, _} <> v_8:
      v_6 <> cps_provider_1_capture_argument_uses(v_8)

def cps_provider_1_partial_array_build(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: U32, v_6: List<&2, BIR.Arg>, v_8: Nat) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_partial_array_described(v_1, v_2, v_4, v_6, v_8)

def native_match_cps_provider_1_partial_array_described_0(v_19: cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>, v_2: BIR.Primitive, v_6: List<&2, BIR.Arg>, v_8: Nat) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_19:
    case cps_provider_1_LowerResult{v_12, None{}}:
      cps_provider_1_fail(v_12, "missing checked partial application type", cps_provider_1_no_span)
    case cps_provider_1_LowerResult{v_17, Some{v_18}}:
      cps_provider_1_partial_array_facts(v_17, v_2, cps_provider_1_arrow_facts(v_18, v_8), v_6)

def cps_provider_1_partial_array_described(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: U32, v_6: List<&2, BIR.Arg>, v_8: Nat) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_partial_array_described_0(cps_provider_1_describe(v_1, v_4), v_2, v_6, v_8)

def native_match_cps_provider_1_partial_array_facts_0(v_17: Maybe<&2, BIR.Descriptor>, v_1: cps_provider_1_State, v_2: BIR.Primitive, v_6: List<&2, BIR.Arg>, v_10: List<&2, BIR.Use>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_17:
    case None{}:
      cps_provider_1_fail(v_1, "missing checked array element type for a partially applied primitive", cps_provider_1_no_span)
    case Some{v_16}:
      cps_provider_1_partial_array_typed(v_1, v_2, v_10, v_6, v_16)

def native_match_cps_provider_1_partial_array_facts_1(v_4: cps_provider_1_ArrowFacts, v_1: cps_provider_1_State, v_2: BIR.Primitive, v_6: List<&2, BIR.Arg>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_4:
    case cps_provider_1_ArrowFacts{v_10, v_11}:
      native_match_cps_provider_1_partial_array_facts_0(cps_provider_1_partial_element(v_2, v_11), v_1, v_2, v_6, v_10)

def cps_provider_1_partial_array_facts(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: cps_provider_1_ArrowFacts, v_6: List<&2, BIR.Arg>) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_partial_array_facts_1(v_4, v_1, v_2, v_6)

def native_match_cps_provider_1_partial_array_typed_0(v_14: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>, v_2: BIR.Primitive, v_6: List<&2, BIR.Arg>, v_7: BIR.Descriptor) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_14:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_partial_array_code(v_12, v_2, v_6, v_13, v_7)

def cps_provider_1_partial_array_typed(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Use>, v_6: List<&2, BIR.Arg>, v_7: BIR.Descriptor) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_partial_array_typed_0(cps_provider_1_partial_array_parameters(v_1, v_4), v_2, v_6, v_7)

def native_match_cps_provider_1_partial_array_call_0(v_46: cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>, v_2: BIR.Primitive, v_24: List<&2, BIR.Arg>, v_28: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_46:
    case cps_provider_1_LowerResult{v_35, Some{v_36}}:
      cps_provider_1_partial_typed(v_35, v_2, v_24, v_28, v_36)
    case cps_provider_1_LowerResult{v_39, None{}}:
      cps_provider_1_fail(v_39, "missing checked array element type for a partially applied primitive", cps_provider_1_no_span)

def native_match_cps_provider_1_partial_array_call_1(v_45: Maybe<&2, U32>, v_2: BIR.Primitive, v_5: List<&2, cps_provider_1_SourceArgument>, v_9: U32, v_20: cps_provider_1_State, v_24: List<&2, BIR.Arg>, v_28: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_45:
    case Some{v_31}:
      native_match_cps_provider_1_partial_array_call_0(cps_provider_1_describe(v_20, v_31), v_2, v_24, v_28)
    case None{}:
      cps_provider_1_partial_array_build(v_20, v_2, v_9, v_24, List.length(&2, cps_provider_1_SourceArgument, v_5))

def native_match_cps_provider_1_partial_array_call_2(v_21: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, cps_provider_1_SourceArgument>>, v_2: BIR.Primitive, v_5: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, BIR.Parameter>, v_9: U32, v_20: cps_provider_1_State) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_21:
    case (v_24, _):
      v_28 = cps_provider_1_drop_parameters(List.length(&2, BIR.Arg, v_24), v_7)
      native_match_cps_provider_1_partial_array_call_1(cps_provider_1_erased_type_term(v_5), v_2, v_5, v_9, v_20, v_24, v_28)

def native_match_cps_provider_1_partial_array_call_3(v_44: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>, v_2: BIR.Primitive, v_5: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, BIR.Parameter>, v_9: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_44:
    case cps_provider_1_LowerResult{v_20, v_21}:
      native_match_cps_provider_1_partial_array_call_2(v_21, v_2, v_5, v_7, v_9, v_20)

def cps_provider_1_partial_array_call(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_5: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, BIR.Parameter>, v_9: U32, v_12: List<&2, cps_provider_1_Slot>, v_14: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_partial_array_call_3(cps_provider_1_argument_prefix(v_1, List.length(&2, cps_provider_1_SourceArgument, v_5), v_5, v_12, v_14), v_2, v_5, v_7, v_9)

def native_match_cps_provider_1_partial_typed_0(v_14: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_14:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_partial_array_code(v_12, v_2, v_4, cps_provider_1_parameterize(v_13, cps_provider_1_parameter_uses(v_6)), v_7)

def cps_provider_1_partial_typed(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_partial_typed_0(cps_provider_1_new_parameters(v_1, List.length(&2, BIR.Parameter, v_6)), v_2, v_4, v_6, v_7)

def native_match_cps_provider_1_application_native_partial_0(v_16: Bool, v_1: cps_provider_1_State, v_2: BIR.Primitive, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_SourceArgument>, v_8: List<&2, BIR.Parameter>, v_10: U32, v_13: List<&2, cps_provider_1_Slot>, v_15: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_16:
    case True{}:
      cps_provider_1_partial_array_call(v_1, v_2, v_6, v_8, v_10, v_13, v_15)
    case False{}:
      cps_provider_1_native_match_application_native_0(cps_provider_1_lower_occurrence(v_1, v_3, v_13, v_15), v_6, v_13, v_15)

def cps_provider_1_application_native_partial(v_1: cps_provider_1_State, v_2: BIR.Primitive, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_SourceArgument>, v_8: List<&2, BIR.Parameter>, v_10: U32, v_13: List<&2, cps_provider_1_Slot>, v_15: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  native_match_cps_provider_1_application_native_partial_0(cps_provider_1_array_primitive(v_2), v_1, v_2, v_3, v_6, v_8, v_10, v_13, v_15)

def cps_provider_1_native_match_application_native_4(v_1: Bool, v_3: cps_provider_1_State, v_4: BIR.Primitive, v_6: Nat, v_7: IR.Occurrence, v_10: List<&2, cps_provider_1_SourceArgument>, v_12: List<&2, BIR.Parameter>, v_14: U32, v_17: List<&2, cps_provider_1_Slot>, v_18: cps_provider_4_Registry, v_21: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case False{}:
      cps_provider_1_application_native_partial(v_3, v_4, v_7, v_10, v_12, v_14, v_17, v_18)
    case True{}:
      cps_provider_1_native_match_application_native_3(cps_provider_1_argument_prefix(v_3, v_6, v_10, v_17, v_18), v_4, v_17, v_18, v_21)

def cps_provider_1_application_native(v_1: cps_provider_1_State, v_3: Bool, v_4: BIR.Primitive, v_6: Nat, v_7: IR.Occurrence, v_10: List<&2, cps_provider_1_SourceArgument>, v_12: List<&2, BIR.Parameter>, v_14: U32, v_17: List<&2, cps_provider_1_Slot>, v_18: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_application_native_4(v_3, v_1, v_4, v_6, v_7, v_10, v_12, v_14, v_17, v_18, cps_provider_1_array_element_handle(v_4, v_10))

def cps_provider_1_native_match_application_direct_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_apply_rest(v_12, v_13, v_4, v_7, v_8)

def cps_provider_1_native_match_application_direct_1(v_6: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, cps_provider_1_SourceArgument>>, v_8: U32, v_10: List<&2, BIR.Parameter>, v_12: Nat, v_15: List<&2, cps_provider_1_Slot>, v_16: cps_provider_4_Registry, v_17: Ast.SourceSpan, v_19: Nat, v_21: cps_provider_1_State) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_6:
    case (v_25, v_26):
      cps_provider_1_application_direct_values(v_21, Nat.is_ge(v_19, v_12), v_8, v_10, v_25, v_26, v_15, v_16, v_17)

def cps_provider_1_native_match_application_direct_2(v_5: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>, v_7: U32, v_9: List<&2, BIR.Parameter>, v_11: Nat, v_14: List<&2, cps_provider_1_Slot>, v_15: cps_provider_4_Registry, v_16: Ast.SourceSpan, v_18: Nat) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_5:
    case cps_provider_1_LowerResult{v_22, v_23}:
      cps_provider_1_native_match_application_direct_1(v_23, v_7, v_9, v_11, v_14, v_15, v_16, v_18, v_22)

def cps_provider_1_native_match_application_direct_3(v_1: Bool, v_3: cps_provider_1_State, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_10: IR.Occurrence, v_13: List<&2, cps_provider_1_SourceArgument>, v_16: List<&2, cps_provider_1_Slot>, v_17: cps_provider_4_Registry, v_18: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case False{}:
      cps_provider_1_native_match_application_direct_0(cps_provider_1_lower_occurrence(v_3, v_10, v_16, v_17), v_13, v_16, v_17)
    case True{}:
      v_24 = List.length(&2, cps_provider_1_SourceArgument, v_13)
      cps_provider_1_native_match_application_direct_2(cps_provider_1_argument_prefix(v_3, Nat.min(v_9, v_24), v_13, v_16, v_17), v_5, v_7, v_9, v_16, v_17, v_18, v_24)

def cps_provider_1_application_direct(v_1: cps_provider_1_State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_10: IR.Occurrence, v_13: List<&2, cps_provider_1_SourceArgument>, v_16: List<&2, cps_provider_1_Slot>, v_17: cps_provider_4_Registry, v_18: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_application_direct_3(v_3, v_1, v_5, v_7, v_9, v_10, v_13, v_16, v_17, v_18)

def cps_provider_1_native_match_application_direct_values_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_apply_rest(v_12, v_13, v_4, v_7, v_8)

def cps_provider_1_native_match_application_direct_values_1(v_1: Bool, v_3: cps_provider_1_State, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Arg>, v_12: List<&2, cps_provider_1_SourceArgument>, v_15: List<&2, cps_provider_1_Slot>, v_16: cps_provider_4_Registry, v_17: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case True{}:
      cps_provider_1_native_match_application_direct_values_0(cps_provider_1_direct_arity(v_3, Nat.is_eq(List.length(&2, BIR.Parameter, v_7), List.length(&2, BIR.Arg, v_9)), v_5, v_9, v_17), v_12, v_15, v_16)
    case False{}:
      cps_provider_1_partial(v_3, v_5, v_9, cps_provider_1_drop_parameters(List.length(&2, BIR.Arg, v_9), v_7))

def cps_provider_1_application_direct_values(v_1: cps_provider_1_State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Arg>, v_12: List<&2, cps_provider_1_SourceArgument>, v_15: List<&2, cps_provider_1_Slot>, v_16: cps_provider_4_Registry, v_17: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_application_direct_values_1(v_3, v_1, v_5, v_7, v_9, v_12, v_15, v_16, v_17)

def cps_provider_1_direct_arity(v_1: cps_provider_1_State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Arg>, v_8: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case True{}:
      cps_provider_1_operation(v_1, BIR.Direct{v_5, v_7})
    case False{}:
      cps_provider_1_fail(v_1, "checked call quantity/entry arity mismatch", v_8)

def cps_provider_1_native_match_argument_prefix_0(v_6: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, cps_provider_1_SourceArgument>>, v_7: Ast.Quantity, v_8: BIR.Atom, v_10: cps_provider_1_State) -> cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>:
  match v_6:
    case (v_18, v_19):
      cps_provider_1_LowerResult{v_10, (BIR.Arg{cps_provider_1_use(v_7), v_8} <> v_18, v_19)}

def cps_provider_1_native_match_argument_prefix_1(v_5: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>, v_6: Ast.Quantity, v_7: BIR.Atom) -> cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>:
  match v_5:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_argument_prefix_0(v_16, v_6, v_7, v_15)

def cps_provider_1_native_match_argument_prefix_2(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: cps_provider_4_Registry, v_7: Nat, v_8: Ast.Quantity, v_11: List<&2, cps_provider_1_SourceArgument>) -> cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>:
  match v_1:
    case cps_provider_1_LowerResult{v_19, v_20}:
      cps_provider_1_native_match_argument_prefix_1(cps_provider_1_argument_prefix(v_19, v_7, v_11, v_4, v_5), v_8, v_20)

def cps_provider_1_native_match_argument_prefix_3(v_1: Nat, v_4: List<&2, cps_provider_1_SourceArgument>, v_6: cps_provider_1_State, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry) -> cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>:
  match v_1, v_4:
    case 0n, _:
      cps_provider_1_LowerResult{v_6, ([], v_4)}
    case 1n+v_21, cps_provider_1_SourceArgument{Ast.QZero{}, _} <> v_23:
      cps_provider_1_argument_prefix(v_6, v_21, v_23, v_9, v_10)
    case 1n+v_29, cps_provider_1_SourceArgument{v_30, v_31} <> v_32:
      cps_provider_1_native_match_argument_prefix_2(cps_provider_1_lower_occurrence(v_6, v_31, v_9, v_10), v_9, v_10, v_29, v_30, v_32)
    case _, []:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_6, "missing checked call operands", cps_provider_1_no_span), ([], [])}

def cps_provider_1_argument_prefix(v_1: cps_provider_1_State, v_3: Nat, v_6: List<&2, cps_provider_1_SourceArgument>, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry) -> cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>:
  cps_provider_1_native_match_argument_prefix_3(v_3, v_6, v_1, v_9, v_10)

def cps_provider_1_native_match_apply_rest_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: cps_provider_4_Registry, v_8: List<&2, cps_provider_1_SourceArgument>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_apply_rest(v_12, v_13, v_8, v_4, v_5)

def cps_provider_1_native_match_apply_rest_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: BIR.Atom, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry, v_7: Ast.Quantity, v_10: List<&2, cps_provider_1_SourceArgument>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_14, v_15}:
      cps_provider_1_native_match_apply_rest_0(cps_provider_1_operation(v_14, BIR.Apply{v_2, BIR.Arg{cps_provider_1_use(v_7), v_15}}), v_5, v_6, v_10)

def cps_provider_1_native_match_apply_rest_2(v_2: List<&2, cps_provider_1_SourceArgument>, v_4: cps_provider_1_State, v_5: BIR.Atom, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case []:
      cps_provider_1_LowerResult{v_4, v_5}
    case cps_provider_1_SourceArgument{Ast.QZero{}, _} <> v_14:
      cps_provider_1_apply_rest(v_4, v_5, v_14, v_8, v_9)
    case cps_provider_1_SourceArgument{v_19, v_20} <> v_21:
      cps_provider_1_native_match_apply_rest_1(cps_provider_1_lower_occurrence(v_4, v_20, v_8, v_9), v_5, v_8, v_9, v_19, v_21)

def cps_provider_1_apply_rest(v_1: cps_provider_1_State, v_2: BIR.Atom, v_5: List<&2, cps_provider_1_SourceArgument>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_apply_rest_2(v_5, v_1, v_2, v_8, v_9)

def cps_provider_1_drop_parameters(v_1: Nat, v_3: List<&2, BIR.Parameter>) -> List<&2, BIR.Parameter>:
  match v_1, v_3:
    case 0n, _:
      v_3
    case 1n+v_10, _ <> v_12:
      cps_provider_1_drop_parameters(v_10, v_12)
    case _, []:
      []

def cps_provider_1_argument_uses(v_1: List<&2, BIR.Arg>) -> List<&2, BIR.Use>:
  match v_1:
    case []:
      []
    case BIR.Arg{v_6, _} <> v_8:
      v_6 <> cps_provider_1_argument_uses(v_8)

def cps_provider_1_indexed_captures(v_1: List<&2, BIR.Arg>, v_3: U32) -> List<&2, BIR.Arg>:
  match v_1:
    case []:
      []
    case BIR.Arg{v_8, _} <> v_10:
      BIR.Arg{v_8, BIR.Capture{v_3}} <> cps_provider_1_indexed_captures(v_10, U32.inc(v_3))

def cps_provider_1_parameter_arguments(v_1: List<&2, BIR.Parameter>) -> List<&2, BIR.Arg>:
  match v_1:
    case []:
      []
    case BIR.Parameter{v_6, v_7} <> v_8:
      BIR.Arg{v_7, BIR.Local{v_6}} <> cps_provider_1_parameter_arguments(v_8)

def cps_provider_1_native_match_partial_0(v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_State{v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24}:
      v_28 = List.append(&2, BIR.Arg, cps_provider_1_indexed_captures(v_5, 0), cps_provider_1_parameter_arguments(v_7))
      v_31 = BIR.Code{v_18, cps_provider_1_argument_uses(v_5), v_7, BIR.TailDirect{v_3, v_28}}
      cps_provider_1_operation(cps_provider_1_State{v_17, U32.inc(v_18), v_19, v_20, v_31 <> v_21, v_22, v_23, v_24}, BIR.Closure{v_18, v_5, v_7})

def cps_provider_1_native_match_partial_1(v_1: List<&2, BIR.Parameter>, v_3: cps_provider_1_State, v_5: U32, v_7: List<&2, BIR.Arg>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case []:
      cps_provider_1_operation(v_3, BIR.Direct{v_5, v_7})
    case _:
      cps_provider_1_native_match_partial_0(v_3, v_5, v_7, v_1)

def cps_provider_1_partial(v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_partial_1(v_7, v_1, v_3, v_5)

def cps_provider_1_tag(v_1: cps_provider_1_State, v_2: cps_provider_4_Constructor, v_3: BIR.Atom, v_6: Maybe<&2, U32>, v_8: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_tag_native(v_1, cps_provider_1_constructor_native(v_2), v_2, v_3, v_6, v_8)

def cps_provider_1_tag_native(v_1: cps_provider_1_State, v_3: String, v_4: cps_provider_4_Constructor, v_5: BIR.Atom, v_8: Maybe<&2, U32>, v_10: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case "Nat.Zero":
      cps_provider_1_primitive(v_1, BIR.PrimIsNatZero{}, [v_5])
    case "Nat.Succ":
      cps_provider_1_primitive(v_1, BIR.PrimIsNatSuccessor{}, [v_5])
    case "Bool.False":
      cps_provider_1_primitive(v_1, BIR.PrimIsFalse{}, [v_5])
    case "Bool.True":
      cps_provider_1_primitive(v_1, BIR.PrimIsTrue{}, [v_5])
    case "String.SNil":
      cps_provider_1_primitive(v_1, BIR.PrimIsStringEmpty{}, [v_5])
    case "String.SCon":
      cps_provider_1_primitive(v_1, BIR.PrimIsStringNonempty{}, [v_5])
    case "Array.ALeaf":
      cps_provider_1_primitive_fact(v_1, BIR.PrimIsArrayLeaf{}, [v_5], v_8, v_10)
    case "Array.ANode":
      cps_provider_1_primitive_fact(v_1, BIR.PrimIsArrayNode{}, [v_5], v_8, v_10)
    case "Char.Chr":
      cps_provider_1_LowerResult{v_1, BIR.Boolean{True{}}}
    case "U32.U32":
      cps_provider_1_LowerResult{v_1, BIR.Boolean{True{}}}
    case "F32.F32":
      cps_provider_1_LowerResult{v_1, BIR.Boolean{True{}}}
    case _:
      cps_provider_1_operation(v_1, BIR.HasTag{v_5, cps_provider_1_constructor_id(v_4), cps_provider_1_constructor_key(v_4)})

def cps_provider_1_project(v_1: cps_provider_1_State, v_2: cps_provider_4_Constructor, v_3: BIR.Atom, v_5: U32, v_6: Ast.SourceSpan, v_9: Maybe<&2, U32>, v_11: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_project_native(v_1, cps_provider_1_constructor_native(v_2), v_2, v_3, v_5, v_6, v_9, v_11)

def cps_provider_1_project_native(v_1: cps_provider_1_State, v_3: String, v_4: cps_provider_4_Constructor, v_5: BIR.Atom, v_7: U32, v_8: Ast.SourceSpan, v_11: Maybe<&2, U32>, v_13: Bool) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3, v_7:
    case "Nat.Succ", 0:
      cps_provider_1_primitive(v_1, BIR.PrimNatPredecessor{}, [v_5])
    case "String.SCon", 0:
      cps_provider_1_primitive(v_1, BIR.PrimStringHead{}, [v_5])
    case "String.SCon", 1:
      cps_provider_1_primitive(v_1, BIR.PrimStringTail{}, [v_5])
    case "Char.Chr", 0:
      cps_provider_1_primitive(v_1, BIR.PrimCharCode{}, [v_5])
    case "U32.U32", 0:
      cps_provider_1_primitive(v_1, BIR.PrimU32ToWord{}, [v_5])
    case "F32.F32", 0:
      cps_provider_1_primitive(v_1, BIR.PrimF32ToWord{}, [v_5])
    case "Array.ALeaf", 0:
      cps_provider_1_primitive_fact(v_1, BIR.PrimArrayLeafValue{}, [v_5], v_11, v_13)
    case "Array.ANode", 0:
      cps_provider_1_primitive_fact(v_1, BIR.PrimArrayLeft{}, [v_5], v_11, v_13)
    case "Array.ANode", 1:
      cps_provider_1_primitive_fact(v_1, BIR.PrimArrayRight{}, [v_5], v_11, v_13)
    case _, _:
      cps_provider_1_project_field(v_1, cps_provider_4_constructor_field(v_4, v_7), v_4, v_5, v_8)

def cps_provider_1_project_field(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_ConstructorField>, v_4: cps_provider_4_Constructor, v_5: BIR.Atom, v_6: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case Some{cps_provider_4_ConstructorField{_, _, BIR.Erased{}}}:
      cps_provider_1_LowerResult{v_1, BIR.Null{}}
    case Some{cps_provider_4_ConstructorField{v_15, Some{v_16}, _}}:
      cps_provider_1_operation(v_1, BIR.Project{v_5, cps_provider_1_constructor_id(v_4), v_15, v_16})
    case _:
      cps_provider_1_fail(v_1, "missing checked field projection", v_6)

def cps_provider_1_pattern_identity(v_0: IR.CheckedPattern, v_1: cps_provider_4_Registry) -> String:
  match v_0:
    case IR.CheckedConstructor{_, v_8, _, _}:
      cps_provider_1_pattern_identity_found(cps_provider_4_lookup_constructor(v_1, v_8))
    case _:
      ""

def cps_provider_1_pattern_identity_found(v_1: Maybe<&2, cps_provider_4_Constructor>) -> String:
  match v_1:
    case None{}:
      ""
    case Some{v_4}:
      cps_provider_1_constructor_native(v_4)

def cps_provider_1_closed_bit(v_0: IR.CheckedPattern, v_1: cps_provider_4_Registry) -> Maybe<&2, U32>:
  match v_0:
    case IR.CheckedConstructor{_, _, [], _}:
      cps_provider_1_closed_bit_identity(cps_provider_1_pattern_identity(v_0, v_1))
    case _:
      None{}

def cps_provider_1_closed_bit_identity(v_1: String) -> Maybe<&2, U32>:
  match v_1:
    case "Bool.False":
      Some{0}
    case "Bool.True":
      Some{1}
    case _:
      None{}

def cps_provider_1_closed_word(v_1: Nat, v_2: IR.CheckedPattern, v_3: cps_provider_4_Registry) -> Maybe<&2, U32>:
  cps_provider_1_closed_word_identity(v_1, cps_provider_1_pattern_identity(v_2, v_3), v_2, v_3)

def cps_provider_1_closed_word_identity(v_1: Nat, v_3: String, v_4: IR.CheckedPattern, v_5: cps_provider_4_Registry) -> Maybe<&2, U32>:
  match v_1, v_3, v_4:
    case 0n, "Word.Nil.WNil", IR.CheckedConstructor{_, _, [], _}:
      Some{0}
    case 1n+v_20, "Word.Con.WCon", IR.CheckedConstructor{_, _, [v_23, v_24], _}:
      cps_provider_1_closed_word_parts(cps_provider_1_closed_bit(v_23, v_5), cps_provider_1_closed_word(v_20, v_24, v_5))
    case _, _, _:
      None{}

def cps_provider_1_closed_word_parts(v_2: Maybe<&2, U32>, v_5: Maybe<&2, U32>) -> Maybe<&2, U32>:
  match v_2, v_5:
    case Some{v_10}, Some{v_11}:
      Some{U32.or(v_10, U32.shl(v_11))}
    case _, _:
      None{}

def cps_provider_1_closed_scalar(v_1: String, v_3: List<&2, IR.CheckedPattern>, v_4: cps_provider_4_Registry) -> Maybe<&2, U32>:
  match v_1, v_3:
    case "U32.U32", [v_8]:
      cps_provider_1_closed_word(32n, v_8, v_4)
    case "F32.F32", [v_11]:
      cps_provider_1_closed_word(32n, v_11, v_4)
    case _, _:
      None{}

def cps_provider_1_erase_pattern(v_0: IR.CheckedPattern, v_3: List<&2, cps_provider_1_Slot>) -> List<&2, cps_provider_1_Slot>:
  match v_0:
    case IR.CheckedVariable{_, _}:
      cps_provider_1_ErasedSlot{} <> v_3
    case IR.CheckedConstructor{_, _, v_16, _}:
      cps_provider_1_erase_patterns(v_16, v_3)

def cps_provider_1_erase_patterns(v_1: List<&2, IR.CheckedPattern>, v_4: List<&2, cps_provider_1_Slot>) -> List<&2, cps_provider_1_Slot>:
  match v_1:
    case []:
      v_4
    case v_9 <> v_10:
      cps_provider_1_erase_patterns(v_10, cps_provider_1_erase_pattern(v_9, v_4))

def cps_provider_1_native_match_patterns_0(v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_4: cps_provider_4_Registry, v_5: BIR.Block, v_7: List<&2, IR.CheckedPattern>, v_9: List<&2, BIR.Atom>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_3:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_patterns(v_15, v_7, v_9, v_16, v_4, v_5)

def cps_provider_1_native_match_patterns_1(v_1: List<&2, IR.CheckedPattern>, v_3: List<&2, BIR.Atom>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: BIR.Block) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_1, v_3:
    case [], []:
      cps_provider_1_LowerResult{v_5, v_8}
    case v_18 <> v_19, v_20 <> v_21:
      cps_provider_1_native_match_patterns_0(cps_provider_1_pattern(v_5, v_18, v_20, v_8, v_9, v_10), v_9, v_10, v_19, v_21)
    case _, _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_5, "checked pattern/scrutinee arity mismatch", cps_provider_1_no_span), v_8}

def cps_provider_1_patterns(v_1: cps_provider_1_State, v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: BIR.Block) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  cps_provider_1_native_match_patterns_1(v_3, v_5, v_1, v_8, v_9, v_10)

def cps_provider_1_native_match_pattern_0(v_2: cps_provider_1_LowerResult<cps_provider_1_Slot>, v_5: List<&2, cps_provider_1_Slot>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_2:
    case cps_provider_1_LowerResult{v_11, v_12}:
      cps_provider_1_LowerResult{v_11, v_12 <> v_5}

def cps_provider_1_native_match_pattern_1(v_0: IR.CheckedPattern, v_2: cps_provider_1_State, v_3: BIR.Atom, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_8: BIR.Block) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_0:
    case IR.CheckedVariable{_, IR.CheckedBinding{Ast.QZero{}, _, _}}:
      cps_provider_1_LowerResult{v_2, cps_provider_1_ErasedSlot{} <> v_6}
    case IR.CheckedVariable{_, IR.CheckedBinding{v_23, _, _}}:
      cps_provider_1_native_match_pattern_0(cps_provider_1_bind_slot(v_2, v_3, cps_provider_1_use(v_23)), v_6)
    case IR.CheckedConstructor{_, v_34, v_35, v_36}:
      cps_provider_1_pattern_constructor(v_2, cps_provider_4_lookup_constructor(v_7, v_34), v_35, v_36, v_3, v_6, v_7, v_8)

def cps_provider_1_pattern(v_1: cps_provider_1_State, v_2: IR.CheckedPattern, v_3: BIR.Atom, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_8: BIR.Block) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  cps_provider_1_native_match_pattern_1(v_2, v_1, v_3, v_6, v_7, v_8)

def cps_provider_1_pattern_constructor(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_Constructor>, v_5: List<&2, IR.CheckedPattern>, v_7: List<&2, IR.CheckedBinding>, v_8: BIR.Atom, v_11: List<&2, cps_provider_1_Slot>, v_12: cps_provider_4_Registry, v_13: BIR.Block) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_3:
    case None{}:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_1, "missing resolved pattern constructor", cps_provider_1_no_span), v_11}
    case Some{v_20}:
      cps_provider_1_pattern_scalar(v_1, cps_provider_1_closed_scalar(cps_provider_1_constructor_native(v_20), v_5, v_12), v_20, v_5, v_7, v_8, v_11, v_12, v_13, cps_provider_1_first_binding_type(v_7))

def cps_provider_1_native_match_pattern_scalar_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: BIR.Block) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_1:
    case cps_provider_1_LowerResult{v_11, v_12}:
      cps_provider_1_LowerResult{cps_provider_1_guard(v_11, v_12, v_5), v_4}

def cps_provider_1_native_match_pattern_scalar_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Constructor, v_4: List<&2, IR.CheckedPattern>, v_6: List<&2, IR.CheckedBinding>, v_7: BIR.Atom, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_12: BIR.Block, v_15: Maybe<&2, U32>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_1:
    case cps_provider_1_LowerResult{v_21, v_22}:
      cps_provider_1_pattern_fields(cps_provider_1_guard(v_21, v_22, v_12), v_2, v_4, v_6, v_7, 0, v_10, v_11, v_12, v_15)

def cps_provider_1_native_match_pattern_scalar_2(v_2: Maybe<&2, U32>, v_4: cps_provider_1_State, v_5: cps_provider_4_Constructor, v_7: List<&2, IR.CheckedPattern>, v_9: List<&2, IR.CheckedBinding>, v_10: BIR.Atom, v_13: List<&2, cps_provider_1_Slot>, v_14: cps_provider_4_Registry, v_15: BIR.Block, v_18: Maybe<&2, U32>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_2:
    case Some{v_23}:
      cps_provider_1_native_match_pattern_scalar_0(cps_provider_1_scalar_test(v_4, String.eq(cps_provider_1_constructor_native(v_5), "F32.F32"), v_10, v_23), v_13, v_15)
    case None{}:
      cps_provider_1_native_match_pattern_scalar_1(cps_provider_1_tag(v_4, v_5, v_10, v_18, False{}), v_5, v_7, v_9, v_10, v_13, v_14, v_15, v_18)

def cps_provider_1_pattern_scalar(v_1: cps_provider_1_State, v_4: Maybe<&2, U32>, v_5: cps_provider_4_Constructor, v_7: List<&2, IR.CheckedPattern>, v_9: List<&2, IR.CheckedBinding>, v_10: BIR.Atom, v_13: List<&2, cps_provider_1_Slot>, v_14: cps_provider_4_Registry, v_15: BIR.Block, v_18: Maybe<&2, U32>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  cps_provider_1_native_match_pattern_scalar_2(v_4, v_1, v_5, v_7, v_9, v_10, v_13, v_14, v_15, v_18)

def cps_provider_1_scalar_test(v_1: cps_provider_1_State, v_3: Bool, v_4: BIR.Atom, v_6: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case True{}:
      cps_provider_1_primitive(v_1, BIR.PrimFloatBitsEqual{}, [v_4, BIR.Word{v_6}])
    case False{}:
      cps_provider_1_primitive(v_1, BIR.PrimSameValue{}, [v_4, BIR.Word{v_6}])

def cps_provider_1_native_match_pattern_fields_0(v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_4: cps_provider_4_Constructor, v_5: BIR.Atom, v_7: U32, v_8: cps_provider_4_Registry, v_9: BIR.Block, v_11: List<&2, IR.CheckedPattern>, v_13: List<&2, IR.CheckedBinding>, v_16: Maybe<&2, U32>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_3:
    case cps_provider_1_LowerResult{v_22, v_23}:
      cps_provider_1_pattern_fields(v_22, v_4, v_11, v_13, v_5, U32.inc(v_7), v_23, v_8, v_9, v_16)

def cps_provider_1_native_match_pattern_fields_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Constructor, v_3: BIR.Atom, v_5: U32, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: BIR.Block, v_11: IR.CheckedPattern, v_13: List<&2, IR.CheckedPattern>, v_15: List<&2, IR.CheckedBinding>, v_18: Maybe<&2, U32>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_1:
    case cps_provider_1_LowerResult{v_24, v_25}:
      cps_provider_1_native_match_pattern_fields_0(cps_provider_1_pattern(v_24, v_11, v_25, v_8, v_9, v_10), v_2, v_3, v_5, v_9, v_10, v_13, v_15, v_18)

def cps_provider_1_native_match_pattern_fields_2(v_1: List<&2, IR.CheckedPattern>, v_3: List<&2, IR.CheckedBinding>, v_5: cps_provider_1_State, v_6: cps_provider_4_Constructor, v_7: BIR.Atom, v_9: U32, v_12: List<&2, cps_provider_1_Slot>, v_13: cps_provider_4_Registry, v_14: BIR.Block, v_17: Maybe<&2, U32>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_1, v_3:
    case [], []:
      cps_provider_1_LowerResult{v_5, v_12}
    case v_26 <> v_27, IR.CheckedBinding{Ast.QZero{}, _, _} <> v_30:
      cps_provider_1_pattern_fields(v_5, v_6, v_27, v_30, v_7, U32.inc(v_9), cps_provider_1_erase_pattern(v_26, v_12), v_13, v_14, v_17)
    case v_37 <> v_38, _ <> v_40:
      cps_provider_1_native_match_pattern_fields_1(cps_provider_1_project(v_5, v_6, v_7, v_9, cps_provider_1_no_span, v_17, False{}), v_6, v_7, v_9, v_12, v_13, v_14, v_37, v_38, v_40, v_17)
    case _, _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_5, "incomplete checked pattern layout", cps_provider_1_no_span), v_12}

def cps_provider_1_pattern_fields(v_1: cps_provider_1_State, v_2: cps_provider_4_Constructor, v_4: List<&2, IR.CheckedPattern>, v_6: List<&2, IR.CheckedBinding>, v_7: BIR.Atom, v_9: U32, v_12: List<&2, cps_provider_1_Slot>, v_13: cps_provider_4_Registry, v_14: BIR.Block, v_17: Maybe<&2, U32>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  cps_provider_1_native_match_pattern_fields_2(v_4, v_6, v_1, v_2, v_7, v_9, v_12, v_13, v_14, v_17)

def cps_provider_1_native_match_lower_values_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_3: BIR.Atom) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_2:
    case cps_provider_1_LowerResult{v_8, v_9}:
      cps_provider_1_LowerResult{v_8, v_3 <> v_9}

def cps_provider_1_native_match_lower_values_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: cps_provider_4_Registry, v_7: List<&2, IR.Occurrence>) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_1:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_native_match_lower_values_0(cps_provider_1_lower_values(v_12, v_7, v_4, v_5), v_13)

def cps_provider_1_native_match_lower_values_2(v_1: List<&2, IR.Occurrence>, v_3: cps_provider_1_State, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_1:
    case []:
      cps_provider_1_LowerResult{v_3, []}
    case v_12 <> v_13:
      cps_provider_1_native_match_lower_values_1(cps_provider_1_lower_occurrence(v_3, v_12, v_6, v_7), v_6, v_7, v_13)

def cps_provider_1_lower_values(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  cps_provider_1_native_match_lower_values_2(v_3, v_1, v_6, v_7)

def cps_provider_1_native_match_new_parameters_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>, v_4: U32) -> cps_provider_1_LowerResult<List<&2, BIR.Parameter>>:
  match v_2:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_LowerResult{v_9, BIR.Parameter{v_4, BIR.Affine{}} <> v_10}

def cps_provider_1_native_match_new_parameters_1(v_2: cps_provider_1_LowerResult<U32>, v_4: Nat) -> cps_provider_1_LowerResult<List<&2, BIR.Parameter>>:
  match v_2:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_native_match_new_parameters_0(cps_provider_1_new_parameters(v_9, v_4), v_10)

def cps_provider_1_native_match_new_parameters_2(v_1: Nat, v_3: cps_provider_1_State) -> cps_provider_1_LowerResult<List<&2, BIR.Parameter>>:
  match v_1:
    case 0n:
      cps_provider_1_LowerResult{v_3, []}
    case 1n+v_7:
      cps_provider_1_native_match_new_parameters_1(cps_provider_1_fresh(v_3), v_7)

def cps_provider_1_new_parameters(v_1: cps_provider_1_State, v_3: Nat) -> cps_provider_1_LowerResult<List<&2, BIR.Parameter>>:
  cps_provider_1_native_match_new_parameters_2(v_3, v_1)

def cps_provider_1_parameter_values(v_1: List<&2, BIR.Parameter>) -> List<&2, BIR.Atom>:
  match v_1:
    case []:
      []
    case BIR.Parameter{v_6, _} <> v_8:
      BIR.Local{v_6} <> cps_provider_1_parameter_values(v_8)

def cps_provider_1_native_match_checked_cases_0(v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: U32, v_4: BIR.Block) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case cps_provider_1_LowerResult{v_8, v_9}:
      cps_provider_1_LowerResult{v_8, BIR.Region{v_3, v_4, v_9}}

def cps_provider_1_native_match_checked_cases_1(v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: List<&2, BIR.Atom>, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_9: List<&2, IR.Occurrence>, v_11: U32) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_checked_cases_0(cps_provider_1_checked_cases(v_15, v_9, v_3, v_6, v_7), v_11, v_16)

def cps_provider_1_native_match_checked_cases_2(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: List<&2, BIR.Atom>, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_9: List<&2, IR.Occurrence>, v_11: U32) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_checked_cases_1(cps_provider_1_take_block(v_15, v_16), v_3, v_6, v_7, v_9, v_11)

def cps_provider_1_native_match_checked_cases_3(v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: IR.Occurrence, v_12: List<&2, IR.Occurrence>, v_14: U32) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_3:
    case cps_provider_1_LowerResult{v_18, v_19}:
      cps_provider_1_native_match_checked_cases_2(cps_provider_1_lower_occurrence(v_18, v_10, v_19, v_9), v_5, v_8, v_9, v_12, v_14)

def cps_provider_1_native_match_checked_cases_4(v_2: cps_provider_1_LowerResult<U32>, v_4: List<&2, BIR.Atom>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry, v_10: List<&2, IR.CheckedPattern>, v_11: IR.Occurrence, v_13: List<&2, IR.Occurrence>) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_2:
    case cps_provider_1_LowerResult{v_17, v_18}:
      cps_provider_1_native_match_checked_cases_3(cps_provider_1_patterns(v_17, v_10, v_4, v_7, v_8, BIR.LeaveRegion{v_18}), v_4, v_7, v_8, v_11, v_13, v_18)

def cps_provider_1_native_match_checked_cases_5(v_1: List<&2, IR.Occurrence>, v_3: cps_provider_1_State, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case []:
      cps_provider_1_LowerResult{v_3, BIR.Failure{"bend: runtime fail-stop"}}
    case IR.CaseOccurrence{_, _, v_18, v_19} <> v_20:
      cps_provider_1_native_match_checked_cases_4(cps_provider_1_fresh(v_3), v_5, v_8, v_9, v_18, v_19, v_20)
    case _ <> _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_3, "missing checked match row", cps_provider_1_no_span), BIR.Failure{"bend: malformed checked match"}}

def cps_provider_1_checked_cases(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Block>:
  cps_provider_1_native_match_checked_cases_5(v_3, v_1, v_5, v_8, v_9)

def cps_provider_1_take_block(v_1: cps_provider_1_State, v_2: BIR.Atom) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case cps_provider_1_State{v_15, v_16, v_17, cps_provider_1_Frame{v_18, v_19, v_20, v_21}, v_22, v_23, v_24, v_25}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_15, v_16, v_17, cps_provider_1_Frame{v_18, [], v_20, v_21}, v_22, v_23, v_24, v_25}, cps_provider_1_finish(v_19, v_2)}

def cps_provider_1_native_match_match_values_0(v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>, v_4: List<&2, BIR.Atom>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_8, v_9}:
      cps_provider_1_call_reference(v_8, v_9, cps_provider_1_atom_arguments(v_4))

def cps_provider_1_native_match_match_values_1(v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: List<&2, BIR.Atom>, v_5: cps_provider_1_Frame, v_7: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_11, v_12}:
      cps_provider_1_native_match_match_values_0(cps_provider_1_leave(v_11, v_5, v_7, v_12), v_3)

def cps_provider_1_native_match_match_values_2(v_2: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>, v_4: List<&2, IR.Occurrence>, v_6: List<&2, BIR.Atom>, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry, v_12: cps_provider_1_Frame) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_16, v_17}:
      cps_provider_1_native_match_match_values_1(cps_provider_1_checked_cases(v_16, v_4, cps_provider_1_parameter_values(v_17), v_9, v_10), v_6, v_12, v_17)

def cps_provider_1_native_match_match_values_3(v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_4: List<&2, IR.Occurrence>, v_6: List<&2, BIR.Atom>, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_14, v_15}:
      cps_provider_1_native_match_match_values_2(cps_provider_1_new_parameters(v_14, List.length(&2, BIR.Atom, v_6)), v_4, v_6, v_9, v_10, v_15)

def cps_provider_1_match_values(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_match_values_3(cps_provider_1_enter(v_1), v_3, v_5, v_8, v_9)

def cps_provider_1_native_match_split_occurrences_0(v_5: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_6: IR.Occurrence) -> Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>):
  match v_5:
    case (v_12, v_13):
      (v_6 <> v_12, v_13)

def cps_provider_1_native_match_split_occurrences_1(v_1: U32, v_3: List<&2, IR.Occurrence>) -> Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>):
  match v_1, v_3:
    case 0, _:
      ([], v_3)
    case _, v_13 <> v_14:
      cps_provider_1_native_match_split_occurrences_0(cps_provider_1_split_occurrences(U32.sub(v_1, 1), v_14), v_13)
    case _, []:
      ([], [])

def cps_provider_1_split_occurrences(v_1: U32, v_3: List<&2, IR.Occurrence>) -> Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>):
  cps_provider_1_native_match_split_occurrences_1(v_1, v_3)

def cps_provider_1_native_match_lower_match_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry, v_8: List<&2, IR.Occurrence>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_match_values(v_12, v_8, v_13, v_5, v_6)

def cps_provider_1_native_match_lower_match_1(v_5: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_7: cps_provider_1_State, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_5:
    case (v_15, v_16):
      cps_provider_1_native_match_lower_match_0(cps_provider_1_lower_values(v_7, v_15, v_10, v_11), v_10, v_11, v_16)

def cps_provider_1_lower_match(v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_lower_match_1(cps_provider_1_split_occurrences(v_3, v_5), v_1, v_8, v_9)

def cps_provider_1_occurrence_term(v_0: IR.Occurrence) -> U32:
  match v_0:
    case IR.TypedOccurrence{v_8, _, _, _, _, _}:
      v_8
    case IR.ScalarOccurrence{v_19, _, _, _, _}:
      v_19
    case IR.StringOccurrence{v_28, _, _, _}:
      v_28
    case IR.CaseOccurrence{v_36, _, _, _}:
      v_36
    case IR.LocalOccurrence{v_45, _, _, _, _}:
      v_45
    case IR.LocalReferenceOccurrence{v_54, _, _, _}:
      v_54

def cps_provider_1_native_match_lower_0(v_1: cps_provider_1_LowerResult<Arena.Node>, v_4: List<&2, cps_provider_1_Slot>, v_5: cps_provider_4_Registry, v_7: U32, v_9: Maybe<&2, Ast.Quantity>, v_11: Maybe<&2, IR.Symbol>, v_13: List<&2, IR.CheckedBinding>, v_15: List<&2, IR.Occurrence>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_19, v_20}:
      cps_provider_1_lower_node(v_19, v_20, v_7, v_9, v_11, v_13, v_15, v_4, v_5)

def cps_provider_1_native_match_lower_1(v_1: cps_provider_1_LowerResult<Arena.Node>, v_4: List<&2, cps_provider_1_Slot>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_8, v_9}:
      cps_provider_1_lexical_reference(v_8, v_9, v_4)

def cps_provider_1_native_match_lower_2(v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_4: cps_provider_4_Registry, v_5: IR.Occurrence) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_lower_occurrence(v_9, v_5, v_10, v_4)

def cps_provider_1_native_match_lower_3(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry, v_8: List<&2, IR.CheckedPattern>, v_9: IR.Occurrence) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_13, v_14}:
      cps_provider_1_native_match_lower_2(cps_provider_1_patterns(v_13, v_8, v_14, v_5, v_6, BIR.Failure{"bend: runtime fail-stop"}), v_6, v_9)

def cps_provider_1_native_match_lower_4(v_0: IR.Occurrence, v_2: cps_provider_1_State, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_0:
    case IR.TypedOccurrence{v_14, v_15, v_16, v_17, v_18, v_19}:
      cps_provider_1_native_match_lower_0(cps_provider_1_node(v_2, v_14), v_5, v_6, v_15, v_16, v_17, v_18, v_19)
    case IR.ScalarOccurrence{_, _, v_29, v_30, v_31}:
      cps_provider_1_scalar_literal(v_2, cps_provider_4_lookup_constructor(v_6, v_29), v_30, v_31, v_6)
    case IR.StringOccurrence{_, _, v_39, v_40}:
      cps_provider_1_literal_string(v_2, v_6, v_40, v_39, cps_provider_1_no_span)
    case IR.LocalReferenceOccurrence{v_47, _, _, _}:
      cps_provider_1_native_match_lower_1(cps_provider_1_node(v_2, v_47), v_5)
    case IR.LocalOccurrence{_, _, v_60, v_61, v_62}:
      cps_provider_1_native_match_lower_3(cps_provider_1_local_values(v_2, v_60, v_61, v_5, v_6), v_5, v_6, v_60, v_62)
    case IR.CaseOccurrence{_, _, _, _}:
      cps_provider_1_fail(v_2, "checked case escaped its match", cps_provider_1_no_span)

def cps_provider_1_lower_occurrence(v_1: cps_provider_1_State, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_lower_4(v_2, v_1, v_5, v_6)

def cps_provider_1_lexical_reference(v_1: cps_provider_1_State, v_2: Arena.Node, v_5: List<&2, cps_provider_1_Slot>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case Arena.TermVar{_, v_11, v_12}:
      cps_provider_1_variable(v_1, v_5, v_11, v_12)
    case _:
      cps_provider_1_fail(v_1, "checked local reference lost lexical identity", cps_provider_1_no_span)

def cps_provider_1_native_match_lower_node_0(v_2: cps_provider_1_LowerResult<String>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_6, v_7}:
      cps_provider_1_LowerResult{cps_provider_1_push(v_6, cps_provider_1_Stop{BIR.Failure{String.append("bend: unsolved hole ", v_7)}}), BIR.Null{}}

def cps_provider_1_native_match_lower_node_1(v_0: Arena.Node, v_2: cps_provider_1_State, v_4: U32, v_6: Maybe<&2, Ast.Quantity>, v_8: Maybe<&2, IR.Symbol>, v_10: List<&2, IR.CheckedBinding>, v_12: List<&2, IR.Occurrence>, v_15: List<&2, cps_provider_1_Slot>, v_16: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_0:
    case Arena.TermVar{_, v_22, v_23}:
      cps_provider_1_variable(v_2, v_15, v_22, v_23)
    case Arena.TermRef{_, v_28}:
      cps_provider_1_resolved_reference(v_2, v_8, v_16, v_28)
    case Arena.TermBang{_, v_33}:
      cps_provider_1_only_child(v_2, v_12, v_15, v_16, v_33)
    case Arena.TermAnn{_, _, v_40}:
      cps_provider_1_annotated_child(v_2, v_12, v_15, v_16, v_40)
    case Arena.TermLam{_, _, _, _, v_51}:
      cps_provider_1_lambda_checked(v_2, v_6, v_12, v_15, v_16, v_51)
    case Arena.TermApp{_, _, v_58}:
      cps_provider_1_application_checked(v_2, v_4, v_6, v_12, v_15, v_16, v_58)
    case Arena.TermCtr{_, _, _, v_67}:
      cps_provider_1_constructor_checked(v_2, v_8, v_10, v_12, v_15, v_16, v_67)
    case Arena.TermLet{_, _, _, _, _, _, _, v_86, _, v_88}:
      cps_provider_1_let_checked(v_2, v_86, v_10, v_12, v_15, v_16, v_88)
    case Arena.BodyMatch{_, v_96, _, _, _}:
      cps_provider_1_lower_match(v_2, v_96, v_12, v_15, v_16)
    case Arena.TermMat{_, _, _, v_108}:
      cps_provider_1_matcher_checked(v_2, v_6, v_8, v_12, v_15, v_16, v_108)
    case Arena.TermAbsurd{v_111}:
      cps_provider_1_absurd_checked(v_2, v_6, v_111)
    case Arena.TermRewrite{_, _, _, v_120}:
      cps_provider_1_rewrite_checked(v_2, v_12, v_15, v_16, v_120)
    case Arena.TermType{_, _}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermQuant{}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermQuantity{_, _}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermMin{_, _, _}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermAll{_, _, _, _, _, _}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermAdt{_, _, _, _, _, _}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermEqual{_, _, _, _}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermRefl{_}:
      cps_provider_1_LowerResult{v_2, BIR.Null{}}
    case Arena.TermHole{v_172, v_173}:
      cps_provider_1_native_match_lower_node_0(cps_provider_1_name(v_2, v_172))
    case Arena.TermTemplate{_, v_179}:
      cps_provider_1_fail(v_2, "unexpanded template reached JS emission", v_179)
    case Arena.TermString{_, _, v_186}:
      cps_provider_1_fail(v_2, "missing checked string literal certificate", v_186)
    case Arena.TermSub{_, _, _, v_195}:
      cps_provider_1_fail(v_2, "unelaborated substitution reached lowering", v_195)
    case Arena.TermFill{_, _, _, v_204}:
      cps_provider_1_fail(v_2, "unelaborated fill reached lowering", v_204)
    case Arena.TermPlus{_, _, _, v_213}:
      cps_provider_1_fail(v_2, "unelaborated plus reached lowering", v_213)
    case Arena.BodyCase{_, _, _, v_222}:
      cps_provider_1_fail(v_2, "missing checked case facts", v_222)
    case Arena.BodyLocal{_, _, _, _, _, _, v_237}:
      cps_provider_1_fail(v_2, "missing checked local facts", v_237)
    case Arena.BodyReply{_, v_242}:
      cps_provider_1_fail(v_2, "unelaborated reply reached lowering", v_242)

def cps_provider_1_lower_node(v_1: cps_provider_1_State, v_2: Arena.Node, v_4: U32, v_6: Maybe<&2, Ast.Quantity>, v_8: Maybe<&2, IR.Symbol>, v_10: List<&2, IR.CheckedBinding>, v_12: List<&2, IR.Occurrence>, v_15: List<&2, cps_provider_1_Slot>, v_16: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_lower_node_1(v_2, v_1, v_4, v_6, v_8, v_10, v_12, v_15, v_16)

def cps_provider_1_resolved_reference(v_1: cps_provider_1_State, v_3: Maybe<&2, IR.Symbol>, v_4: cps_provider_4_Registry, v_5: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case Some{v_8}:
      cps_provider_1_symbol_value(v_1, v_8, v_4, v_5)
    case None{}:
      cps_provider_1_fail(v_1, "missing checked reference identity", v_5)

def cps_provider_1_only_child(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_8: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case [v_11]:
      cps_provider_1_lower_occurrence(v_1, v_11, v_6, v_7)
    case _:
      cps_provider_1_fail(v_1, "incomplete checked unary operand", v_8)

def cps_provider_1_annotated_child(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_8: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case [v_12, _]:
      cps_provider_1_lower_occurrence(v_1, v_12, v_6, v_7)
    case _:
      cps_provider_1_fail(v_1, "incomplete checked annotation", v_8)

def cps_provider_1_rewrite_checked(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_8: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case [_, _, v_15]:
      cps_provider_1_lower_occurrence(v_1, v_15, v_6, v_7)
    case _:
      cps_provider_1_fail(v_1, "incomplete checked rewrite", v_8)

def cps_provider_1_native_match_application_checked_0(v_2: cps_provider_1_LowerResult<cps_provider_1_Spine>, v_4: U32, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry, v_9: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_13, v_14}:
      cps_provider_1_applications(v_13, v_14, v_4, v_7, v_8, v_9)

def cps_provider_1_native_match_application_checked_1(v_1: Maybe<&2, Ast.Quantity>, v_3: List<&2, IR.Occurrence>, v_5: cps_provider_1_State, v_7: U32, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_12: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1, v_3:
    case Some{v_17}, [v_18, v_19]:
      cps_provider_1_native_match_application_checked_0(cps_provider_1_spine(v_5, v_18, [cps_provider_1_SourceArgument{v_17, v_19}]), v_7, v_10, v_11, v_12)
    case _, _:
      cps_provider_1_fail(v_5, "missing checked application quantity/operands", v_12)

def cps_provider_1_application_checked(v_1: cps_provider_1_State, v_3: U32, v_5: Maybe<&2, Ast.Quantity>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_12: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_application_checked_1(v_5, v_7, v_1, v_3, v_10, v_11, v_12)

def cps_provider_1_native_match_constructor_checked_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_3: cps_provider_4_Registry, v_4: Ast.SourceSpan, v_5: IR.Symbol, v_8: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_construct_symbol(v_12, v_3, v_5, v_13, v_4, v_8)

def cps_provider_1_native_match_constructor_checked_1(v_1: Maybe<&2, IR.Symbol>, v_3: cps_provider_1_State, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_12: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case None{}:
      cps_provider_1_fail(v_3, "missing checked constructor identity", v_12)
    case Some{v_16}:
      cps_provider_1_native_match_constructor_checked_0(cps_provider_1_constructor_operands(v_3, v_7, v_5, v_10, v_11, v_12), v_11, v_12, v_16, cps_provider_1_first_occurrence_type(v_7))

def cps_provider_1_constructor_checked(v_1: cps_provider_1_State, v_3: Maybe<&2, IR.Symbol>, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_12: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_constructor_checked_1(v_3, v_1, v_5, v_7, v_10, v_11, v_12)

def cps_provider_1_native_match_lambda_checked_0(v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_6, v_7}:
      cps_provider_1_close(v_6, v_7)

def cps_provider_1_native_match_lambda_checked_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_10, v_11}:
      cps_provider_1_native_match_lambda_checked_0(cps_provider_1_leave_value(v_10, v_4, [BIR.Parameter{v_6, cps_provider_1_use(v_2)}], v_11))

def cps_provider_1_native_match_lambda_checked_2(v_2: cps_provider_1_LowerResult<cps_provider_1_Slot>, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry, v_7: Ast.Quantity, v_8: IR.Occurrence, v_10: cps_provider_1_Frame, v_12: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_16, v_17}:
      cps_provider_1_native_match_lambda_checked_1(cps_provider_1_lower_occurrence(v_16, v_8, v_17 <> v_5, v_6), v_7, v_10, v_12)

def cps_provider_1_native_match_lambda_checked_3(v_2: cps_provider_1_LowerResult<U32>, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry, v_7: Ast.Quantity, v_8: IR.Occurrence, v_10: cps_provider_1_Frame) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_14, v_15}:
      cps_provider_1_native_match_lambda_checked_2(cps_provider_1_bind_slot(v_14, BIR.Local{v_15}, cps_provider_1_use(v_7)), v_5, v_6, v_7, v_8, v_10, v_15)

def cps_provider_1_native_match_lambda_checked_4(v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry, v_7: Ast.Quantity, v_8: IR.Occurrence) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_12, v_13}:
      cps_provider_1_native_match_lambda_checked_3(cps_provider_1_fresh(v_12), v_5, v_6, v_7, v_8, v_13)

def cps_provider_1_native_match_lambda_checked_5(v_1: Maybe<&2, Ast.Quantity>, v_3: List<&2, IR.Occurrence>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1, v_3:
    case Some{Ast.QZero{}}, [v_13]:
      cps_provider_1_lower_occurrence(v_5, v_13, cps_provider_1_ErasedSlot{} <> v_8, v_9)
    case Some{v_17}, [v_18]:
      cps_provider_1_native_match_lambda_checked_4(cps_provider_1_enter(v_5), v_8, v_9, v_17, v_18)
    case _, _:
      cps_provider_1_fail(v_5, "missing checked lambda quantity/body", v_10)

def cps_provider_1_lambda_checked(v_1: cps_provider_1_State, v_3: Maybe<&2, Ast.Quantity>, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_lambda_checked_5(v_3, v_5, v_1, v_8, v_9, v_10)

def cps_provider_1_native_match_absurd_checked_0(v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_6, v_7}:
      cps_provider_1_close(v_6, v_7)

def cps_provider_1_native_match_absurd_checked_1(v_2: cps_provider_1_LowerResult<U32>, v_3: Ast.Quantity, v_5: cps_provider_1_Frame) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_native_match_absurd_checked_0(cps_provider_1_leave(v_9, v_5, [BIR.Parameter{v_10, cps_provider_1_use(v_3)}], BIR.Failure{"bend: runtime fail-stop"}))

def cps_provider_1_native_match_absurd_checked_2(v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_3: Ast.Quantity) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_7, v_8}:
      cps_provider_1_native_match_absurd_checked_1(cps_provider_1_fresh(v_7), v_3, v_8)

def cps_provider_1_native_match_absurd_checked_3(v_1: Maybe<&2, Ast.Quantity>, v_3: cps_provider_1_State, v_4: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case Some{Ast.QZero{}}:
      cps_provider_1_fail(v_3, "erased absurd scrutinee reached live lowering", v_4)
    case Some{v_8}:
      cps_provider_1_native_match_absurd_checked_2(cps_provider_1_enter(v_3), v_8)
    case None{}:
      cps_provider_1_fail(v_3, "missing checked absurd quantity", v_4)

def cps_provider_1_absurd_checked(v_1: cps_provider_1_State, v_3: Maybe<&2, Ast.Quantity>, v_4: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_absurd_checked_3(v_3, v_1, v_4)

def cps_provider_1_native_match_local_values_0(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_2:
    case cps_provider_1_LowerResult{v_7, v_8}:
      cps_provider_1_LowerResult{v_7, BIR.Null{} <> v_8}

def cps_provider_1_native_match_local_values_1(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_3: BIR.Atom) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_2:
    case cps_provider_1_LowerResult{v_8, v_9}:
      cps_provider_1_LowerResult{v_8, v_3 <> v_9}

def cps_provider_1_native_match_local_values_2(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: cps_provider_4_Registry, v_7: List<&2, IR.CheckedPattern>, v_9: List<&2, IR.Occurrence>) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_1:
    case cps_provider_1_LowerResult{v_14, v_15}:
      cps_provider_1_native_match_local_values_1(cps_provider_1_local_values(v_14, v_7, v_9, v_4, v_5), v_15)

def cps_provider_1_native_match_local_values_3(v_1: List<&2, IR.CheckedPattern>, v_3: List<&2, IR.Occurrence>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  match v_1, v_3:
    case [], []:
      cps_provider_1_LowerResult{v_5, []}
    case IR.CheckedVariable{_, IR.CheckedBinding{Ast.QZero{}, _, _}} <> v_21, _ <> v_23:
      cps_provider_1_native_match_local_values_0(cps_provider_1_local_values(v_5, v_21, v_23, v_8, v_9))
    case _ <> v_31, v_32 <> v_33:
      cps_provider_1_native_match_local_values_2(cps_provider_1_lower_occurrence(v_5, v_32, v_8, v_9), v_8, v_9, v_31, v_33)
    case _, _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_5, "incomplete checked local values", cps_provider_1_no_span), []}

def cps_provider_1_local_values(v_1: cps_provider_1_State, v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<List<&2, BIR.Atom>>:
  cps_provider_1_native_match_local_values_3(v_3, v_5, v_1, v_8, v_9)

def cps_provider_1_native_match_let_checked_0(v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_4: cps_provider_4_Registry, v_5: IR.Occurrence) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case cps_provider_1_LowerResult{v_9, v_10}:
      cps_provider_1_lower_occurrence(v_9, v_5, v_10, v_4)

def cps_provider_1_native_match_let_checked_1(v_5: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_7: cps_provider_1_State, v_9: List<&2, IR.CheckedBinding>, v_12: List<&2, cps_provider_1_Slot>, v_13: cps_provider_4_Registry, v_14: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_5:
    case (v_18, [v_19]):
      cps_provider_1_native_match_let_checked_0(cps_provider_1_let_bindings(v_7, v_18, v_9, v_12, v_12, v_13, v_14), v_13, v_19)
    case _:
      cps_provider_1_fail(v_7, "incomplete checked let body", v_14)

def cps_provider_1_let_checked(v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_12: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_let_checked_1(cps_provider_1_split_occurrences(v_3, v_7), v_1, v_5, v_10, v_11, v_12)

def cps_provider_1_native_match_let_bindings_0(v_2: cps_provider_1_LowerResult<cps_provider_1_Slot>, v_5: List<&2, cps_provider_1_Slot>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan, v_12: List<&2, IR.Occurrence>, v_14: List<&2, IR.CheckedBinding>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_2:
    case cps_provider_1_LowerResult{v_20, v_21}:
      cps_provider_1_let_bindings(v_20, v_12, v_14, v_5, v_21 <> v_8, v_9, v_10)

def cps_provider_1_native_match_let_bindings_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry, v_9: Ast.SourceSpan, v_11: List<&2, IR.Occurrence>, v_12: Ast.Quantity, v_14: List<&2, IR.CheckedBinding>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_1:
    case cps_provider_1_LowerResult{v_20, v_21}:
      cps_provider_1_native_match_let_bindings_0(cps_provider_1_bind_slot(v_20, v_21, cps_provider_1_use(v_12)), v_4, v_7, v_8, v_9, v_11, v_14)

def cps_provider_1_native_match_let_bindings_2(v_1: List<&2, IR.Occurrence>, v_3: List<&2, IR.CheckedBinding>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_11: List<&2, cps_provider_1_Slot>, v_12: cps_provider_4_Registry, v_13: Ast.SourceSpan) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_1, v_3:
    case [], []:
      cps_provider_1_LowerResult{v_5, v_11}
    case _ <> v_23, IR.CheckedBinding{Ast.QZero{}, _, _} <> v_26:
      cps_provider_1_let_bindings(v_5, v_23, v_26, v_8, cps_provider_1_ErasedSlot{} <> v_11, v_12, v_13)
    case v_34 <> v_35, IR.CheckedBinding{v_36, _, _} <> v_39:
      cps_provider_1_native_match_let_bindings_1(cps_provider_1_lower_occurrence(v_5, v_34, v_8, v_12), v_8, v_11, v_12, v_13, v_35, v_36, v_39)
    case _, _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_5, "incomplete checked let bindings", v_13), v_11}

def cps_provider_1_let_bindings(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_8: List<&2, cps_provider_1_Slot>, v_11: List<&2, cps_provider_1_Slot>, v_12: cps_provider_4_Registry, v_13: Ast.SourceSpan) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  cps_provider_1_native_match_let_bindings_2(v_3, v_5, v_1, v_8, v_11, v_12, v_13)

def cps_provider_1_scalar_literal(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_Constructor>, v_5: U32, v_7: List<&2, IR.Symbol>, v_8: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case None{}:
      cps_provider_1_fail(v_1, "missing certified scalar constructor", cps_provider_1_no_span)
    case Some{v_13}:
      cps_provider_1_scalar_literal_native(v_1, cps_provider_1_constructor_native(v_13), v_13, v_5, v_7, v_8)

def cps_provider_1_native_match_scalar_literal_native_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Constructor) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_6, v_7}:
      cps_provider_1_construct(v_6, v_2, [v_7], cps_provider_1_no_span, None{})

def cps_provider_1_native_match_scalar_literal_native_1(v_1: List<&2, IR.Symbol>, v_3: cps_provider_1_State, v_4: cps_provider_4_Constructor, v_6: U32, v_7: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case [v_13, v_14, v_15, v_16]:
      cps_provider_1_native_match_scalar_literal_native_0(cps_provider_1_literal_word(v_3, v_7, 32n, v_6, v_13, v_14, v_15, v_16, cps_provider_1_no_span), v_4)
    case _:
      cps_provider_1_fail(v_3, "incomplete certified scalar identities", cps_provider_1_no_span)

def cps_provider_1_native_match_scalar_literal_native_2(v_1: String, v_3: cps_provider_1_State, v_4: cps_provider_4_Constructor, v_6: U32, v_8: List<&2, IR.Symbol>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case "U32.U32":
      cps_provider_1_LowerResult{v_3, BIR.Word{v_6}}
    case "F32.F32":
      cps_provider_1_LowerResult{v_3, BIR.FloatBits{v_6}}
    case _:
      cps_provider_1_native_match_scalar_literal_native_1(v_8, v_3, v_4, v_6, v_9)

def cps_provider_1_scalar_literal_native(v_1: cps_provider_1_State, v_3: String, v_4: cps_provider_4_Constructor, v_6: U32, v_8: List<&2, IR.Symbol>, v_9: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_scalar_literal_native_2(v_3, v_1, v_4, v_6, v_8, v_9)

def cps_provider_1_take_instructions(v_1: cps_provider_1_State) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Instruction>>:
  match v_1:
    case cps_provider_1_State{v_16, v_17, v_18, cps_provider_1_Frame{v_19, v_20, v_21, v_22}, v_23, v_24, v_25, v_26}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_16, v_17, v_18, cps_provider_1_Frame{v_19, [], v_21, v_22}, v_23, v_24, v_25, v_26}, v_20}

def cps_provider_1_matcher_checked(v_1: cps_provider_1_State, v_3: Maybe<&2, Ast.Quantity>, v_5: Maybe<&2, IR.Symbol>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry, v_12: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3, v_5, v_7:
    case Some{Ast.QZero{}}, _, _:
      cps_provider_1_fail(v_1, "erased matcher scrutinee reached live lowering", v_12)
    case Some{v_23}, Some{v_24}, [v_25, v_26]:
      cps_provider_1_matcher_constructor(v_1, cps_provider_4_lookup_constructor(v_11, v_24), v_23, v_25, v_26, v_10, v_11, v_12)
    case _, _, _:
      cps_provider_1_fail(v_1, "incomplete checked matcher facts", v_12)

def cps_provider_1_native_match_matcher_constructor_0(v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_6, v_7}:
      cps_provider_1_close(v_6, v_7)

def cps_provider_1_native_match_matcher_constructor_1(v_1: cps_provider_1_LowerResult<BIR.Block>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32, v_7: BIR.Atom, v_10: List<&2, cps_provider_1_Instruction>, v_11: BIR.Block) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_15, v_16}:
      v_19 = cps_provider_1_prefix(v_10, BIR.Branch{v_7, v_11, v_16})
      cps_provider_1_native_match_matcher_constructor_0(cps_provider_1_leave(v_15, v_4, [BIR.Parameter{v_6, cps_provider_1_use(v_2)}], v_19))

def cps_provider_1_native_match_matcher_constructor_2(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32, v_7: BIR.Atom, v_10: List<&2, cps_provider_1_Instruction>, v_11: BIR.Block) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_matcher_constructor_1(cps_provider_1_take_block(v_15, v_16), v_2, v_4, v_6, v_7, v_10, v_11)

def cps_provider_1_native_match_matcher_constructor_3(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32, v_7: BIR.Atom, v_10: List<&2, cps_provider_1_Instruction>, v_11: BIR.Block) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_matcher_constructor_2(cps_provider_1_operation(v_15, BIR.Apply{v_16, BIR.Arg{cps_provider_1_use(v_2), BIR.Local{v_6}}}), v_2, v_4, v_6, v_7, v_10, v_11)

def cps_provider_1_native_match_matcher_constructor_4(v_1: cps_provider_1_LowerResult<BIR.Block>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_9: cps_provider_1_Frame, v_11: U32, v_12: BIR.Atom, v_15: List<&2, cps_provider_1_Instruction>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_19, v_20}:
      cps_provider_1_native_match_matcher_constructor_3(cps_provider_1_lower_occurrence(v_19, v_3, v_6, v_7), v_2, v_9, v_11, v_12, v_15, v_20)

def cps_provider_1_native_match_matcher_constructor_5(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_9: cps_provider_1_Frame, v_11: U32, v_12: BIR.Atom, v_15: List<&2, cps_provider_1_Instruction>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_19, v_20}:
      cps_provider_1_native_match_matcher_constructor_4(cps_provider_1_take_block(v_19, v_20), v_2, v_3, v_6, v_7, v_9, v_11, v_12, v_15)

def cps_provider_1_native_match_matcher_constructor_6(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry, v_8: Ast.SourceSpan, v_9: cps_provider_4_Constructor, v_11: cps_provider_1_Frame, v_13: U32, v_14: BIR.Atom, v_17: List<&2, cps_provider_1_Instruction>, v_20: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_24, v_25}:
      cps_provider_1_native_match_matcher_constructor_5(cps_provider_1_matcher_fields(v_24, v_9, cps_provider_1_constructor_quantities(v_9), BIR.Local{v_13}, 0, v_25, v_2, v_8, v_20), v_2, v_3, v_6, v_7, v_11, v_13, v_14, v_17)

def cps_provider_1_native_match_matcher_constructor_7(v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Instruction>>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry, v_11: Ast.SourceSpan, v_12: cps_provider_4_Constructor, v_14: cps_provider_1_Frame, v_16: U32, v_17: BIR.Atom) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_3:
    case cps_provider_1_LowerResult{v_21, v_22}:
      cps_provider_1_native_match_matcher_constructor_6(cps_provider_1_lower_occurrence(v_21, v_5, v_9, v_10), v_4, v_6, v_9, v_10, v_11, v_12, v_14, v_16, v_17, v_22, cps_provider_1_occurrence_type(v_5))

def cps_provider_1_native_match_matcher_constructor_8(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_4: IR.Occurrence, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry, v_9: Ast.SourceSpan, v_10: cps_provider_4_Constructor, v_12: cps_provider_1_Frame, v_14: U32) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_18, v_19}:
      cps_provider_1_native_match_matcher_constructor_7(cps_provider_1_take_instructions(v_18), v_2, v_3, v_4, v_7, v_8, v_9, v_10, v_12, v_14, v_19)

def cps_provider_1_native_match_matcher_constructor_9(v_2: cps_provider_1_LowerResult<U32>, v_3: Ast.Quantity, v_4: IR.Occurrence, v_5: IR.Occurrence, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan, v_11: cps_provider_4_Constructor, v_13: cps_provider_1_Frame) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_17, v_18}:
      cps_provider_1_native_match_matcher_constructor_8(cps_provider_1_tag(v_17, v_11, BIR.Local{v_18}, cps_provider_1_occurrence_type(v_4), True{}), v_3, v_4, v_5, v_8, v_9, v_10, v_11, v_13, v_18)

def cps_provider_1_native_match_matcher_constructor_10(v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_3: Ast.Quantity, v_4: IR.Occurrence, v_5: IR.Occurrence, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_10: Ast.SourceSpan, v_11: cps_provider_4_Constructor) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_2:
    case cps_provider_1_LowerResult{v_15, v_16}:
      cps_provider_1_native_match_matcher_constructor_9(cps_provider_1_fresh(v_15), v_3, v_4, v_5, v_8, v_9, v_10, v_11, v_16)

def cps_provider_1_native_match_matcher_constructor_11(v_1: Maybe<&2, cps_provider_4_Constructor>, v_3: cps_provider_1_State, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry, v_11: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case None{}:
      cps_provider_1_fail(v_3, "missing checked matcher constructor", v_11)
    case Some{v_15}:
      cps_provider_1_native_match_matcher_constructor_10(cps_provider_1_enter(v_3), v_4, v_5, v_6, v_9, v_10, v_11, v_15)

def cps_provider_1_matcher_constructor(v_1: cps_provider_1_State, v_3: Maybe<&2, cps_provider_4_Constructor>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, cps_provider_1_Slot>, v_10: cps_provider_4_Registry, v_11: Ast.SourceSpan) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_matcher_constructor_11(v_3, v_1, v_4, v_5, v_6, v_9, v_10, v_11)

def cps_provider_1_constructor_quantities(v_0: cps_provider_4_Constructor) -> List<&2, BIR.Quantity>:
  match v_0:
    case cps_provider_4_Constructor{_, v_7, _, _}:
      v_7

def cps_provider_1_matcher_field_use(v_0: BIR.Quantity, v_1: Ast.Quantity) -> BIR.Use:
  match v_0:
    case BIR.Unrestricted{}:
      BIR.Many{}
    case _:
      cps_provider_1_use(v_1)

def cps_provider_1_native_match_matcher_fields_0(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Constructor, v_3: BIR.Atom, v_5: U32, v_6: Ast.Quantity, v_7: Ast.SourceSpan, v_9: List<&2, BIR.Quantity>, v_12: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_16, v_17}:
      cps_provider_1_matcher_fields(v_16, v_2, v_9, v_3, U32.inc(v_5), v_17, v_6, v_7, v_12)

def cps_provider_1_native_match_matcher_fields_1(v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: cps_provider_4_Constructor, v_3: BIR.Atom, v_5: U32, v_6: BIR.Atom, v_7: Ast.Quantity, v_8: Ast.SourceSpan, v_9: BIR.Quantity, v_11: List<&2, BIR.Quantity>, v_14: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case cps_provider_1_LowerResult{v_18, v_19}:
      cps_provider_1_native_match_matcher_fields_0(cps_provider_1_operation(v_18, BIR.Apply{v_6, BIR.Arg{cps_provider_1_matcher_field_use(v_9, v_7), v_19}}), v_2, v_3, v_5, v_7, v_8, v_11, v_14)

def cps_provider_1_native_match_matcher_fields_2(v_1: List<&2, BIR.Quantity>, v_3: cps_provider_1_State, v_4: cps_provider_4_Constructor, v_5: BIR.Atom, v_7: U32, v_8: BIR.Atom, v_9: Ast.Quantity, v_10: Ast.SourceSpan, v_13: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  match v_1:
    case []:
      cps_provider_1_LowerResult{v_3, v_8}
    case BIR.Erased{} <> v_16:
      cps_provider_1_matcher_fields(v_3, v_4, v_16, v_5, U32.inc(v_7), v_8, v_9, v_10, v_13)
    case v_20 <> v_21:
      cps_provider_1_native_match_matcher_fields_1(cps_provider_1_project(v_3, v_4, v_5, v_7, v_10, v_13, True{}), v_4, v_5, v_7, v_8, v_9, v_10, v_20, v_21, v_13)

def cps_provider_1_matcher_fields(v_1: cps_provider_1_State, v_2: cps_provider_4_Constructor, v_4: List<&2, BIR.Quantity>, v_5: BIR.Atom, v_7: U32, v_8: BIR.Atom, v_9: Ast.Quantity, v_10: Ast.SourceSpan, v_13: Maybe<&2, U32>) -> cps_provider_1_LowerResult<BIR.Atom>:
  cps_provider_1_native_match_matcher_fields_2(v_4, v_1, v_2, v_5, v_7, v_8, v_9, v_10, v_13)

def cps_provider_1_native_match_definition_frame_0(v_1: cps_provider_1_State, v_3: U32, v_4: Scope.ArenaGlobalScope) -> cps_provider_1_State:
  match v_1:
    case cps_provider_1_State{v_14, v_15, v_16, _, v_18, v_19, _, v_21}:
      cps_provider_1_State{v_14, v_15, v_16, cps_provider_1_Frame{v_3, [], [], 0}, v_18, v_19, Some{v_4}, v_21}

def cps_provider_1_definition_frame(v_1: cps_provider_1_State, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> cps_provider_1_State:
  cps_provider_1_native_match_definition_frame_0(cps_provider_1_reserve(v_1, v_5), v_3, v_6)

def cps_provider_1_definition_env(v_1: cps_provider_1_State, v_3: List<&2, BIR.Quantity>, v_5: List<&2, BIR.Parameter>, v_7: U32, v_10: List<&2, cps_provider_1_Slot>) -> cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>:
  match v_3, v_5:
    case [], []:
      cps_provider_1_LowerResult{v_1, v_10}
    case BIR.Erased{} <> v_16, _:
      cps_provider_1_definition_env(v_1, v_16, v_5, v_7, cps_provider_1_ErasedSlot{} <> v_10)
    case _ <> v_25, BIR.Parameter{v_26, v_27} <> v_28:
      cps_provider_1_definition_env(v_1, v_25, v_28, v_7, cps_provider_1_Slot{v_7, v_26, BIR.Local{v_26}, v_27} <> v_10)
    case _, _:
      cps_provider_1_LowerResult{cps_provider_1_state_problem(v_1, "declaration telescope/live parameter mismatch", cps_provider_1_no_span), v_10}

def cps_provider_1_definitions(v_1: cps_provider_1_State, v_3: List<&2, cps_provider_4_Definition>, v_4: cps_provider_4_Registry, v_6: List<&2, BIR.Declaration>) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_3:
    case []:
      cps_provider_1_LowerResult{v_1, List.reverse(&2, BIR.Declaration, v_6)}
    case cps_provider_4_Definition{v_18, _, _, _, v_22, v_23, _, _} <> v_26:
      cps_provider_1_definition(v_1, v_18, v_22, v_26, v_4, v_6, v_23)

def cps_provider_1_definition(v_1: cps_provider_1_State, v_2: cps_provider_4_DefinitionHeader, v_4: Maybe<&2, IR.Occurrence>, v_6: List<&2, cps_provider_4_Definition>, v_7: cps_provider_4_Registry, v_9: List<&2, BIR.Declaration>, v_10: Scope.ArenaGlobalScope) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_2:
    case cps_provider_4_DefinitionHeader{_, v_23, v_24, v_25, v_26, v_27, v_28, v_29, _}:
      cps_provider_1_definition_kind(v_1, v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_4, v_6, v_7, v_9, v_10)

def cps_provider_1_definition_kind(v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_11: Bool, v_13: Maybe<&2, BIR.Primitive>, v_15: Maybe<&2, cps_provider_4_Foreign>, v_17: Maybe<&2, IR.Occurrence>, v_19: List<&2, cps_provider_4_Definition>, v_20: cps_provider_4_Registry, v_22: List<&2, BIR.Declaration>, v_23: Scope.ArenaGlobalScope) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_15:
    case Some{cps_provider_4_Foreign{v_32, v_33, v_34, v_35, v_36, v_37}}:
      cps_provider_1_definitions(v_1, v_19, v_20, BIR.ForeignDeclaration{v_3, v_32, v_33, List.length(&2, BIR.Parameter, v_7), v_34, v_9, v_35, v_36, v_37} <> v_22)
    case None{}:
      cps_provider_1_definition_local(v_1, v_3, v_5, v_7, v_9, v_11, v_13, v_17, v_19, v_20, v_22, v_23)

def cps_provider_1_definition_local(v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_11: Bool, v_13: Maybe<&2, BIR.Primitive>, v_15: Maybe<&2, IR.Occurrence>, v_17: List<&2, cps_provider_4_Definition>, v_18: cps_provider_4_Registry, v_20: List<&2, BIR.Declaration>, v_21: Scope.ArenaGlobalScope) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_11, v_13:
    case True{}, _:
      cps_provider_1_definitions(v_1, v_17, v_18, v_20)
    case False{}, Some{v_28}:
      cps_provider_1_definitions(v_1, v_17, v_18, BIR.NativeDeclaration{v_3, v_28, v_9} <> v_20)
    case False{}, None{}:
      cps_provider_1_definition_body(v_1, v_3, v_5, v_7, v_9, v_15, v_17, v_18, v_20, v_21)

def cps_provider_1_definition_parameter(v_1: U32, v_3: List<&2, BIR.Parameter>) -> Bool:
  match v_3:
    case []:
      False{}
    case BIR.Parameter{v_8, _} <> v_10:
      Bool.or(U32.is_eq(v_1, v_8), cps_provider_1_definition_parameter(v_1, v_10))

def cps_provider_1_definition_locals(v_1: List<&2, BIR.Atom>, v_3: List<&2, BIR.Parameter>) -> Bool:
  match v_1:
    case []:
      True{}
    case BIR.Local{v_7} <> v_8:
      Bool.and(cps_provider_1_definition_parameter(v_7, v_3), cps_provider_1_definition_locals(v_8, v_3))
    case _ <> _:
      False{}

def cps_provider_1_definition_locals_frame(v_1: cps_provider_1_Frame, v_3: List<&2, BIR.Atom>, v_5: List<&2, BIR.Parameter>) -> Bool:
  match v_1, v_3:
    case cps_provider_1_Frame{_, [], [], 0}, _ <> _:
      cps_provider_1_definition_locals(v_3, v_5)
    case _, _:
      False{}

def cps_provider_1_definition_atom_block(v_1: cps_provider_1_LowerResult<BIR.Atom>) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case cps_provider_1_LowerResult{v_5, v_6}:
      cps_provider_1_take_block(v_5, v_6)

def cps_provider_1_definition_match_direct(v_1: Bool, v_3: cps_provider_1_State, v_5: List<&2, IR.Occurrence>, v_7: List<&2, BIR.Atom>, v_10: List<&2, cps_provider_1_Slot>, v_11: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case True{}:
      cps_provider_1_checked_cases(v_3, v_5, v_7, v_10, v_11)
    case False{}:
      cps_provider_1_definition_atom_block(cps_provider_1_match_values(v_3, v_5, v_7, v_10, v_11))

def cps_provider_1_definition_match_state(v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_11: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case cps_provider_1_State{v_21, v_22, v_23, v_24, v_25, v_26, v_27, v_28}:
      cps_provider_1_definition_match_direct(cps_provider_1_definition_locals_frame(v_24, v_5, v_11), cps_provider_1_State{v_21, v_22, v_23, v_24, v_25, v_26, v_27, v_28}, v_3, v_5, v_8, v_9)

def cps_provider_1_definition_match_values(v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_4: List<&2, IR.Occurrence>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry, v_10: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_2:
    case cps_provider_1_LowerResult{v_14, v_15}:
      cps_provider_1_definition_match_state(v_14, v_4, v_15, v_7, v_8, v_10)

def cps_provider_1_definition_match_parts(v_3: Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>), v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_9: cps_provider_4_Registry, v_11: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_3:
    case (v_15, v_16):
      cps_provider_1_definition_match_values(cps_provider_1_lower_values(v_5, v_15, v_8, v_9), v_16, v_8, v_9, v_11)

def cps_provider_1_definition_root_node(v_1: cps_provider_1_LowerResult<Arena.Node>, v_2: IR.Occurrence, v_4: List<&2, IR.Occurrence>, v_7: List<&2, cps_provider_1_Slot>, v_8: cps_provider_4_Registry, v_10: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_1:
    case cps_provider_1_LowerResult{v_18, Arena.BodyMatch{_, v_20, _, _, _}}:
      cps_provider_1_definition_match_parts(cps_provider_1_split_occurrences(v_20, v_4), v_18, v_7, v_8, v_10)
    case cps_provider_1_LowerResult{v_28, v_29}:
      cps_provider_1_definition_root_other(v_2, v_28, v_29, v_7, v_8)

def cps_provider_1_definition_root_other(v_0: IR.Occurrence, v_2: cps_provider_1_State, v_3: Arena.Node, v_6: List<&2, cps_provider_1_Slot>, v_7: cps_provider_4_Registry) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_0:
    case IR.TypedOccurrence{_, v_16, v_17, v_18, v_19, v_20}:
      cps_provider_1_definition_atom_block(cps_provider_1_lower_node(v_2, v_3, v_16, v_17, v_18, v_19, v_20, v_6, v_7))
    case _:
      cps_provider_1_definition_atom_block(cps_provider_1_lower_occurrence(v_2, v_0, v_6, v_7))

def cps_provider_1_definition_root(v_1: cps_provider_1_State, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_Slot>, v_6: cps_provider_4_Registry, v_8: List<&2, BIR.Parameter>) -> cps_provider_1_LowerResult<BIR.Block>:
  match v_2:
    case IR.TypedOccurrence{v_16, _, _, _, _, v_21}:
      cps_provider_1_definition_root_node(cps_provider_1_node(v_1, v_16), v_2, v_21, v_5, v_6, v_8)
    case _:
      cps_provider_1_definition_atom_block(cps_provider_1_lower_occurrence(v_1, v_2, v_5, v_6))

def cps_provider_1_native_match_definition_body_0(v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, cps_provider_4_Definition>, v_10: cps_provider_4_Registry, v_12: List<&2, BIR.Declaration>) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_1:
    case cps_provider_1_LowerResult{v_17, v_18}:
      cps_provider_1_definition_complete(v_17, v_3, v_5, v_7, v_18, v_9, v_10, v_12)

def cps_provider_1_native_match_definition_body_2(v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_11: List<&2, cps_provider_4_Definition>, v_12: cps_provider_4_Registry, v_14: List<&2, BIR.Declaration>, v_15: IR.Occurrence) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_3:
    case cps_provider_1_LowerResult{v_20, v_21}:
      cps_provider_1_native_match_definition_body_0(cps_provider_1_definition_root(v_20, v_15, v_21, v_12, v_9), v_5, v_7, v_9, v_11, v_12, v_14)

def cps_provider_1_native_match_definition_body_3(v_1: Maybe<&2, IR.Occurrence>, v_3: cps_provider_1_State, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_11: List<&2, BIR.Quantity>, v_13: List<&2, cps_provider_4_Definition>, v_14: cps_provider_4_Registry, v_16: List<&2, BIR.Declaration>, v_17: Scope.ArenaGlobalScope) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_1:
    case None{}:
      cps_provider_1_definitions(cps_provider_1_state_problem(v_3, String.append("missing checked body: ", v_5), cps_provider_1_no_span), v_13, v_14, v_16)
    case Some{v_24}:
      v_27 = cps_provider_1_definition_frame(v_3, v_7, U32.from_nat(List.length(&2, BIR.Quantity, v_11)), v_17)
      cps_provider_1_native_match_definition_body_2(cps_provider_1_definition_env(v_27, v_11, v_9, v_7, []), v_5, v_7, v_9, v_13, v_14, v_16, v_24)

def cps_provider_1_definition_body(v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_11: Maybe<&2, IR.Occurrence>, v_13: List<&2, cps_provider_4_Definition>, v_14: cps_provider_4_Registry, v_16: List<&2, BIR.Declaration>, v_17: Scope.ArenaGlobalScope) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  cps_provider_1_native_match_definition_body_3(v_11, v_1, v_3, v_5, v_7, v_9, v_13, v_14, v_16, v_17)

def cps_provider_1_definition_complete(v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, v_10: List<&2, cps_provider_4_Definition>, v_11: cps_provider_4_Registry, v_13: List<&2, BIR.Declaration>) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_1:
    case cps_provider_1_State{v_27, v_28, v_29, cps_provider_1_Frame{v_30, v_31, v_32, v_33}, v_34, v_35, v_36, v_37}:
      cps_provider_1_definition_closed(U32.is_eq(v_33, 0), cps_provider_1_State{v_27, v_28, v_29, cps_provider_1_Frame{v_30, v_31, v_32, v_33}, v_34, v_35, v_36, v_37}, v_3, v_5, v_7, v_8, v_10, v_11, v_13)

def cps_provider_1_native_match_definition_closed_0(v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, v_10: List<&2, cps_provider_4_Definition>, v_11: cps_provider_4_Registry, v_13: List<&2, BIR.Declaration>) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_1:
    case cps_provider_1_State{v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31}:
      cps_provider_1_definitions(cps_provider_1_State{v_24, v_25, v_26, v_27, BIR.Code{v_5, [], v_7, v_8} <> v_28, v_29, v_30, v_31}, v_10, v_11, BIR.FunctionDeclaration{v_3, v_5, v_7} <> v_13)

def cps_provider_1_native_match_definition_closed_1(v_1: Bool, v_3: List<&2, BIR.Parameter>, v_5: cps_provider_1_State, v_7: String, v_9: U32, v_10: BIR.Block, v_12: List<&2, cps_provider_4_Definition>, v_13: cps_provider_4_Registry, v_15: List<&2, BIR.Declaration>) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  match v_1, v_3:
    case False{}, _:
      cps_provider_1_definitions(cps_provider_1_state_problem(v_5, "top-level definition has free captures", cps_provider_1_no_span), v_12, v_13, v_15)
    case True{}, []:
      cps_provider_1_definitions(v_5, v_12, v_13, BIR.LazyDeclaration{v_7, v_10} <> v_15)
    case True{}, _:
      cps_provider_1_native_match_definition_closed_0(v_5, v_7, v_9, v_3, v_10, v_12, v_13, v_15)

def cps_provider_1_definition_closed(v_1: Bool, v_3: cps_provider_1_State, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_10: BIR.Block, v_12: List<&2, cps_provider_4_Definition>, v_13: cps_provider_4_Registry, v_15: List<&2, BIR.Declaration>) -> cps_provider_1_LowerResult<List<&2, BIR.Declaration>>:
  cps_provider_1_native_match_definition_closed_1(v_1, v_9, v_3, v_5, v_7, v_10, v_12, v_13, v_15)

def cps_provider_1_native_match_template_binders_0(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_5: U32, v_7: U32) -> cps_provider_1_TemplateResult:
  match v_3:
    case (v_11, v_12):
      cps_provider_1_template_binder(v_11, v_12, IR.Words{IR.arena_range_index(v_5, 1), U32.sub(v_7, 1)})

def cps_provider_1_native_match_template_binders_1(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32) -> cps_provider_1_TemplateResult:
  match v_4:
    case (v_12, v_13):
      cps_provider_1_native_match_template_binders_0(Arena.get_binder(v_12, v_13), v_6, v_8)

def cps_provider_1_native_match_template_binders_2(v_2: Maybe<&2, cps_provider_1_Problem>, v_3: IR.Words, v_4: Arena.Arena) -> cps_provider_1_TemplateResult:
  match v_2, v_3:
    case Some{_}, _:
      cps_provider_1_TemplateResult{v_4, v_2}
    case None{}, IR.Words{_, 0}:
      cps_provider_1_TemplateResult{v_4, None{}}
    case None{}, IR.Words{v_14, v_15}:
      cps_provider_1_native_match_template_binders_1(Arena.word(v_4, IR.arena_tape_offset(v_14)), v_14, v_15)

def cps_provider_1_template_binders(v_0: Arena.Arena, v_1: IR.Words, v_4: Maybe<&2, cps_provider_1_Problem>) -> cps_provider_1_TemplateResult:
  cps_provider_1_native_match_template_binders_2(v_4, v_1, v_0)

def cps_provider_1_template_binder(v_0: Arena.Arena, v_1: Arena.Binder, v_2: IR.Words) -> cps_provider_1_TemplateResult:
  match v_1:
    case Arena.TemplateBinder{_, _, _, v_11}:
      cps_provider_1_TemplateResult{v_0, Some{cps_provider_1_Problem{"unexpanded template binder reached JS emission", v_11}}}
    case _:
      cps_provider_1_template_binders(v_0, v_2, None{})

def cps_provider_1_native_match_template_declarations_0(v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, IR.TopLevel>, v_5: Arena.Arena) -> cps_provider_1_TemplateResult:
  match v_2, v_4:
    case Some{_}, _:
      cps_provider_1_TemplateResult{v_5, v_2}
    case None{}, []:
      cps_provider_1_TemplateResult{v_5, None{}}
    case None{}, v_13 <> v_14:
      cps_provider_1_template_declaration_result(cps_provider_1_template_declaration(v_5, v_13), v_14)

def cps_provider_1_template_declarations(v_0: Arena.Arena, v_2: List<&2, IR.TopLevel>, v_5: Maybe<&2, cps_provider_1_Problem>) -> cps_provider_1_TemplateResult:
  cps_provider_1_native_match_template_declarations_0(v_5, v_2, v_0)

def cps_provider_1_template_declaration_result(v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.TopLevel>) -> cps_provider_1_TemplateResult:
  match v_1:
    case cps_provider_1_TemplateResult{v_7, v_8}:
      cps_provider_1_template_declarations(v_7, v_3, v_8)

def cps_provider_1_template_declaration(v_0: Arena.Arena, v_1: IR.TopLevel) -> cps_provider_1_TemplateResult:
  match v_1:
    case IR.DefTop{IR.Definition{_, v_12, _, _, _, _, _, _}}:
      cps_provider_1_template_binders(v_0, v_12, None{})
    case IR.TypeTop{IR.TypeDecl{_, v_26, _, v_28, _}}:
      cps_provider_1_template_constructor_result(cps_provider_1_template_binders(v_0, v_26, None{}), v_28)
    case IR.LawTop{_}:
      cps_provider_1_TemplateResult{v_0, None{}}

def cps_provider_1_template_constructor_result(v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.ConstructorDecl>) -> cps_provider_1_TemplateResult:
  match v_1:
    case cps_provider_1_TemplateResult{v_7, v_8}:
      cps_provider_1_template_constructors(v_7, v_3, v_8)

def cps_provider_1_native_match_template_constructors_0(v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, IR.ConstructorDecl>, v_5: Arena.Arena) -> cps_provider_1_TemplateResult:
  match v_2, v_4:
    case Some{_}, _:
      cps_provider_1_TemplateResult{v_5, v_2}
    case None{}, []:
      cps_provider_1_TemplateResult{v_5, None{}}
    case None{}, IR.Constructor{_, v_16, _} <> v_18:
      cps_provider_1_template_constructor_result(cps_provider_1_template_binders(v_5, v_16, None{}), v_18)

def cps_provider_1_template_constructors(v_0: Arena.Arena, v_2: List<&2, IR.ConstructorDecl>, v_5: Maybe<&2, cps_provider_1_Problem>) -> cps_provider_1_TemplateResult:
  cps_provider_1_native_match_template_constructors_0(v_5, v_2, v_0)

def cps_provider_1_native_match_template_modules_0(v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, IR.LoadedModule>, v_5: Arena.Arena) -> cps_provider_1_TemplateResult:
  match v_2, v_4:
    case Some{_}, _:
      cps_provider_1_TemplateResult{v_5, v_2}
    case None{}, []:
      cps_provider_1_TemplateResult{v_5, None{}}
    case None{}, IR.LoadedModule{_, IR.Module{_, _, v_19}} <> v_20:
      cps_provider_1_template_module_result(cps_provider_1_template_declarations(v_5, v_19, None{}), v_20)

def cps_provider_1_template_modules(v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_5: Maybe<&2, cps_provider_1_Problem>) -> cps_provider_1_TemplateResult:
  cps_provider_1_native_match_template_modules_0(v_5, v_2, v_0)

def cps_provider_1_template_module_result(v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.LoadedModule>) -> cps_provider_1_TemplateResult:
  match v_1:
    case cps_provider_1_TemplateResult{v_7, v_8}:
      cps_provider_1_template_modules(v_7, v_3, v_8)

def cps_provider_1_prepare(v_0: Checked.CheckedProgram) -> cps_provider_1_Prepared:
  match v_0:
    case Checked.CheckedProgram{v_6, v_7, v_8, v_9}:
      cps_provider_1_prepare_result(cps_provider_1_template_modules(v_6, v_7, None{}), v_7, v_8, v_9)

def cps_provider_1_prepare_result(v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.LoadedModule>, v_5: List<&2, Scope.ArenaGlobal>, v_7: List<&2, Checked.ModuleMetadata>) -> cps_provider_1_Prepared:
  match v_1:
    case cps_provider_1_TemplateResult{v_11, v_12}:
      cps_provider_1_Prepared{Checked.CheckedProgram{v_11, v_3, v_5, v_7}, v_12}

def cps_provider_1_lower(v_0: Checked.CheckedProgram) -> cps_provider_1_ProgramResult:
  cps_provider_1_lower_prepared(cps_provider_1_prepare(v_0), None{})

def cps_provider_1_lower_library(v_0: Checked.CheckedProgram, v_3: List<&2, String>) -> cps_provider_1_ProgramResult:
  cps_provider_1_lower_prepared(cps_provider_1_prepare(v_0), Some{v_3})

def cps_provider_1_lower_prepared(v_1: cps_provider_1_Prepared, v_5: Maybe<&2, List<&2, String>>) -> cps_provider_1_ProgramResult:
  match v_1:
    case cps_provider_1_Prepared{_, Some{cps_provider_1_Problem{v_11, v_12}}}:
      cps_provider_1_LowerFailure{v_11, v_12}
    case cps_provider_1_Prepared{v_14, None{}}:
      cps_provider_1_lower_catalog(cps_provider_4_build(v_14, v_5))

def cps_provider_1_lower_catalog(v_0: cps_provider_4_BuildResult) -> cps_provider_1_ProgramResult:
  match v_0:
    case cps_provider_4_BuildFailure{_, v_5}:
      cps_provider_1_LowerFailure{v_5, cps_provider_1_no_span}
    case cps_provider_4_Built{Checked.CheckedProgram{v_18, _, _, _}, cps_provider_4_Catalog{v_22, v_23, v_24, v_25, v_26, v_27, v_28}}:
      v_30 = cps_provider_1_State{v_18, v_27, 0, cps_provider_1_Frame{0, [], [], 0}, [], None{}, None{}, Some{cps_provider_2_nf_context(v_25, v_26)}}
      cps_provider_1_lower_definitions(cps_provider_1_definitions(v_30, v_22, v_23, []), v_24, v_25, v_26, v_28)

def cps_provider_1_lower_definitions(v_2: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>, v_4: List<&2, BIR.ConstructorLayout>, v_6: List<&2, BIR.Family>, v_8: List<&2, BIR.TypeFunction>, v_9: BIR.Ending) -> cps_provider_1_ProgramResult:
  match v_2:
    case cps_provider_1_LowerResult{cps_provider_1_State{_, _, _, _, v_24, v_25, v_26, v_27}, v_28}:
      cps_provider_1_lower_complete(v_25, v_24, v_28, v_4, v_6, v_8, v_9)

def cps_provider_1_lower_complete(v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, BIR.Code>, v_6: List<&2, BIR.Declaration>, v_8: List<&2, BIR.ConstructorLayout>, v_10: List<&2, BIR.Family>, v_12: List<&2, BIR.TypeFunction>, v_13: BIR.Ending) -> cps_provider_1_ProgramResult:
  match v_2:
    case Some{cps_provider_1_Problem{v_17, v_18}}:
      cps_provider_1_LowerFailure{v_17, v_18}
    case None{}:
      cps_provider_1_Lowered{BIR.Program{List.reverse(&2, BIR.Code, v_4), v_6, v_8, v_10, v_12, v_13}}

def cps_provider_2_family_index(v_1: List<&2, BIR.Family>) -> Map<&2, BIR.Family>:
  match v_1:
    case []:
      Map.new(&2, BIR.Family)
    case +v_5 <> v_6:
      match v_5:
        case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
          Map.set(&2, BIR.Family, cps_provider_2_family_index(v_6), v_13, v_5)

def cps_provider_2_function_index(v_1: List<&2, BIR.TypeFunction>) -> Map<&2, BIR.TypeFunction>:
  match v_1:
    case []:
      Map.new(&2, BIR.TypeFunction)
    case +v_5 <> v_6:
      match v_5:
        case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
          Map.set(&2, BIR.TypeFunction, cps_provider_2_function_index(v_6), v_12, v_5)

def cps_provider_2_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> cps_provider_2_NfContext:
  cps_provider_2_NfContext{cps_provider_2_family_index(v_1), cps_provider_2_function_index(v_3)}

def cps_provider_2_default_fuel() -> Nat:
  1024n

def cps_provider_2_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  IndexLookup.find(BIR.Family, v_3, v_1)

def cps_provider_2_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  IndexLookup.find(BIR.TypeFunction, v_3, v_1)

def native_match_cps_provider_2_native_of_0(v_10: BIR.Family) -> Maybe<&2, String>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      v_19

def native_match_cps_provider_2_native_of_1(v_25: BIR.TypeFunction) -> Maybe<&2, String>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      v_32

def native_match_cps_provider_2_native_of_2(v_37: Maybe<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_37:
    case Some{v_25}:
      native_match_cps_provider_2_native_of_1(v_25)
    case None{}:
      None{}

def native_match_cps_provider_2_native_of_3(v_36: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_36:
    case Some{v_10}:
      native_match_cps_provider_2_native_of_0(v_10)
    case None{}:
      native_match_cps_provider_2_native_of_2(cps_provider_2_function_of(v_1, v_5))

def cps_provider_2_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  native_match_cps_provider_2_native_of_3(cps_provider_2_family_of(v_1, v_3), v_1, v_5)

def cps_provider_2_val_nth(+v_2: List<&2, cps_provider_2_NfVal>, v_4: Nat) -> cps_provider_2_NfVal:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      v_8
    case +v_13 <> v_14, 1n+v_15:
      cps_provider_2_val_nth(v_14, v_15)
    case _, _:
      cps_provider_2_NfMissing{BIR.DescriptorNull{}}

def cps_provider_2_val_at(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> cps_provider_2_NfVal:
  cps_provider_2_val_at_choose(Nat.is_lt(v_4, List.length(&2, cps_provider_2_NfVal, v_2)), v_2, v_4, v_5)

def cps_provider_2_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_2_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> cps_provider_2_NfVal:
  match v_1:
    case True{}:
      cps_provider_2_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_2_NfVal, v_4), 1n), v_6))
    case False{}:
      cps_provider_2_NfMissing{v_7}

def cps_provider_2_first_vals(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> List<&2, cps_provider_2_NfVal>:
  match v_2, v_4:
    case _, 0n:
      []
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      v_14 <> cps_provider_2_first_vals(v_15, v_16)

def cps_provider_2_drop_vals(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat) -> List<&2, cps_provider_2_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_2
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      cps_provider_2_drop_vals(v_15, v_16)

def cps_provider_2_insert_before(v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, v_6: cps_provider_2_NfVal) -> List<&2, cps_provider_2_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_6 <> v_2
    case [], 1n+v_12:
      cps_provider_2_insert_before([], v_12, v_6)
    case +v_17 <> v_18, 1n+v_19:
      v_17 <> cps_provider_2_insert_before(v_18, v_19, v_6)

def cps_provider_2_append_vals(v_2: List<&2, cps_provider_2_NfVal>, v_5: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      v_10 <> cps_provider_2_append_vals(v_11, v_5)

def cps_provider_2_quantity_markers(v_1: Nat) -> List<&2, cps_provider_2_NfVal>:
  match v_1:
    case 0n:
      []
    case 1n+v_5:
      cps_provider_2_NfQuantity{BIR.Erased{}} <> cps_provider_2_quantity_markers(v_5)

def cps_provider_2_materialize_all(v_2: List<&2, cps_provider_2_NfVal>) -> List<&2, BIR.Descriptor>:
  match v_2:
    case []:
      []
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_NfType{v_10, v_11}:
          BIR.DescriptorRef{v_10, cps_provider_2_materialize_all(v_11)} <> cps_provider_2_materialize_all(v_7)
        case cps_provider_2_NfCtor{v_16, v_17}:
          BIR.DescriptorConstructor{v_16, cps_provider_2_materialize_all(v_17)} <> cps_provider_2_materialize_all(v_7)
        case cps_provider_2_NfQuantity{v_21}:
          BIR.DescriptorQuantity{v_21} <> cps_provider_2_materialize_all(v_7)
        case cps_provider_2_NfKind{v_24}:
          BIR.DescriptorKind{v_24} <> cps_provider_2_materialize_all(v_7)
        case cps_provider_2_NfOther{v_27}:
          v_27 <> cps_provider_2_materialize_all(v_7)
        case cps_provider_2_NfMissing{v_30}:
          v_30 <> cps_provider_2_materialize_all(v_7)
        case cps_provider_2_NfClosure{v_36, v_37, v_38, v_39}:
          BIR.DescriptorLet{v_39, BIR.DescriptorLambda{v_36, v_37}} <> cps_provider_2_materialize_all(v_7)

def cps_provider_2_materialize(v_1: cps_provider_2_NfVal) -> BIR.Descriptor:
  match v_1:
    case cps_provider_2_NfType{v_4, v_5}:
      BIR.DescriptorRef{v_4, cps_provider_2_materialize_all(v_5)}
    case cps_provider_2_NfCtor{v_9, v_10}:
      BIR.DescriptorConstructor{v_9, cps_provider_2_materialize_all(v_10)}
    case cps_provider_2_NfQuantity{v_13}:
      BIR.DescriptorQuantity{v_13}
    case cps_provider_2_NfKind{v_15}:
      BIR.DescriptorKind{v_15}
    case cps_provider_2_NfOther{v_17}:
      v_17
    case cps_provider_2_NfMissing{v_19}:
      v_19
    case cps_provider_2_NfClosure{v_24, v_25, v_26, v_27}:
      BIR.DescriptorLet{v_27, BIR.DescriptorLambda{v_24, v_25}}

def cps_provider_2_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_2_NfVal>) -> BIR.Descriptor:
  match v_3:
    case []:
      v_0
    case +v_6 <> v_7:
      BIR.DescriptorLet{cps_provider_2_materialize_all(v_3), v_0}

def cps_provider_2_status_combine(v_1: cps_provider_2_NfStatus, v_3: cps_provider_2_NfStatus) -> cps_provider_2_NfStatus:
  match v_1:
    case cps_provider_2_NfStatusNo{}:
      cps_provider_2_NfStatusNo{}
    case cps_provider_2_NfStatusMaybe{}:
      match v_3:
        case cps_provider_2_NfStatusNo{}:
          cps_provider_2_NfStatusNo{}
        case _:
          cps_provider_2_NfStatusMaybe{}
    case cps_provider_2_NfStatusOk{}:
      v_3

def native_match_cps_provider_2_bind_status_0(v_42: Bool, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_2_NfVal>, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  match v_42:
    case False{}:
      cps_provider_2_NfStatusNo{}
    case True{}:
      cps_provider_2_status_combine(cps_provider_2_bind_status(v_20, v_24), cps_provider_2_bind_status(v_11, v_13))

def native_match_cps_provider_2_bind_status_1(+v_12: cps_provider_2_NfVal, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_2_NfVal>, v_19: String, v_20: List<&2, BIR.DescriptorPattern>) -> cps_provider_2_NfStatus:
  match v_12:
    case cps_provider_2_NfCtor{v_23, v_24}:
      native_match_cps_provider_2_bind_status_0(String.eq(v_19, v_23), v_11, v_13, v_20, v_24)
    case cps_provider_2_NfMissing{v_29}:
      cps_provider_2_status_combine(cps_provider_2_NfStatusMaybe{}, cps_provider_2_bind_status(v_11, v_13))
    case cps_provider_2_NfOther{v_33}:
      cps_provider_2_status_combine(cps_provider_2_NfStatusMaybe{}, cps_provider_2_bind_status(v_11, v_13))
    case _:
      cps_provider_2_NfStatusNo{}

def native_match_cps_provider_2_bind_status_2(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, +v_12: cps_provider_2_NfVal, v_13: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      cps_provider_2_bind_status(v_11, v_13)
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      native_match_cps_provider_2_bind_status_1(v_12, v_11, v_13, v_19, v_20)

def native_match_cps_provider_2_bind_status_3(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  match v_1, v_4:
    case [], []:
      cps_provider_2_NfStatusOk{}
    case +v_10 <> v_11, +v_12 <> v_13:
      native_match_cps_provider_2_bind_status_2(v_10, v_11, v_12, v_13)
    case _, _:
      cps_provider_2_NfStatusNo{}

def cps_provider_2_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfStatus:
  native_match_cps_provider_2_bind_status_3(v_1, v_4)

def native_match_cps_provider_2_bind_values_0(+v_13: cps_provider_2_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_2_NfVal>, v_21: List<&2, BIR.DescriptorPattern>) -> List<&2, cps_provider_2_NfVal>:
  match v_13:
    case cps_provider_2_NfCtor{v_24, v_25}:
      cps_provider_2_append_vals(cps_provider_2_bind_values(v_21, v_25), cps_provider_2_bind_values(v_12, v_14))
    case _:
      cps_provider_2_bind_values(v_12, v_14)

def native_match_cps_provider_2_bind_values_1(+v_11: BIR.DescriptorPattern, v_12: List<&2, BIR.DescriptorPattern>, +v_13: cps_provider_2_NfVal, v_14: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      v_13 <> cps_provider_2_bind_values(v_12, v_14)
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      native_match_cps_provider_2_bind_values_0(v_13, v_12, v_14, v_21)

def native_match_cps_provider_2_bind_values_2(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  match v_1, v_4:
    case [], []:
      []
    case +v_11 <> v_12, +v_13 <> v_14:
      native_match_cps_provider_2_bind_values_1(v_11, v_12, v_13, v_14)
    case _, _:
      []

def cps_provider_2_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> List<&2, cps_provider_2_NfVal>:
  native_match_cps_provider_2_bind_values_2(v_1, v_4)

def native_match_cps_provider_2_bind_patterns_0(v_5: cps_provider_2_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfBind:
  match v_5:
    case cps_provider_2_NfStatusOk{}:
      cps_provider_2_NfBound{cps_provider_2_bind_values(v_1, v_4)}
    case cps_provider_2_NfStatusNo{}:
      cps_provider_2_NfMismatch{}
    case cps_provider_2_NfStatusMaybe{}:
      cps_provider_2_NfUnknown{}

def cps_provider_2_bind_patterns(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_NfBind:
  native_match_cps_provider_2_bind_patterns_0(cps_provider_2_bind_status(v_1, v_4), v_1, v_4)

def native_match_cps_provider_2_nf_0(v_8: Bool, +v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_2_Nf:
  match v_8:
    case True{}:
      cps_provider_2_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_2_nf_descriptor(v_1, v_2, v_5, Nat.sub(v_7, 1n))

def cps_provider_2_nf(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_0(Nat.is_eq(v_7, 0n), v_1, v_2, v_5, v_7)

def native_match_cps_provider_2_nf_descriptor_0(v_8: Bool, +v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_2_Nf:
  match v_8:
    case True{}:
      cps_provider_2_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_2_nf_descriptor_step(v_1, v_2, v_5, v_7)

def cps_provider_2_nf_descriptor(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_descriptor_0(Nat.is_eq(v_7, 0n), v_1, v_2, v_5, v_7)

def native_match_cps_provider_2_nf_arrow_0(v_22: cps_provider_2_Nf, v_2: BIR.Quantity, v_15: cps_provider_2_NfVal) -> cps_provider_2_Nf:
  match v_22:
    case cps_provider_2_NfFail{v_18}:
      cps_provider_2_NfFail{v_18}
    case cps_provider_2_NfOk{v_20}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{BIR.DescriptorArrow{v_2, cps_provider_2_materialize(v_15), cps_provider_2_materialize(v_20)}}}

def native_match_cps_provider_2_nf_arrow_1(v_21: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_2: BIR.Quantity, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat) -> cps_provider_2_Nf:
  match v_21:
    case cps_provider_2_NfFail{v_13}:
      cps_provider_2_NfFail{v_13}
    case cps_provider_2_NfOk{v_15}:
      native_match_cps_provider_2_nf_arrow_0(cps_provider_2_nf(v_1, v_4, v_7, v_9), v_2, v_15)

def cps_provider_2_nf_arrow(+v_1: cps_provider_2_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_arrow_1(cps_provider_2_nf(v_1, v_3, v_7, v_9), v_1, v_2, v_4, v_7, v_9)

def native_match_cps_provider_2_nf_descriptor_step_0(v_191: cps_provider_2_Nf) -> cps_provider_2_Nf:
  match v_191:
    case cps_provider_2_NfOk{v_22}:
      cps_provider_2_NfOk{cps_provider_2_NfKind{cps_provider_2_materialize(v_22)}}
    case cps_provider_2_NfFail{v_25}:
      cps_provider_2_NfFail{v_25}

def native_match_cps_provider_2_nf_descriptor_step_1(v_192: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_7: Nat, v_45: String) -> cps_provider_2_Nf:
  match v_192:
    case cps_provider_2_NfListOk{v_49}:
      cps_provider_2_nf_named(v_1, v_45, v_49, v_7)
    case cps_provider_2_NfListFail{v_52}:
      cps_provider_2_NfFail{v_52}

def native_match_cps_provider_2_nf_descriptor_step_2(v_193: cps_provider_2_NfList, v_55: String) -> cps_provider_2_Nf:
  match v_193:
    case cps_provider_2_NfListOk{v_59}:
      cps_provider_2_NfOk{cps_provider_2_NfCtor{v_55, v_59}}
    case cps_provider_2_NfListFail{v_61}:
      cps_provider_2_NfFail{v_61}

def native_match_cps_provider_2_nf_descriptor_step_3(v_195: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_7: Nat, v_68: cps_provider_2_NfVal) -> cps_provider_2_Nf:
  match v_195:
    case cps_provider_2_NfOk{v_71}:
      cps_provider_2_nf_apply(v_1, v_68, [v_71], v_7)
    case cps_provider_2_NfFail{v_74}:
      cps_provider_2_NfFail{v_74}

def native_match_cps_provider_2_nf_descriptor_step_4(v_194: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, v_65: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_194:
    case cps_provider_2_NfOk{v_68}:
      native_match_cps_provider_2_nf_descriptor_step_3(cps_provider_2_nf(v_1, v_65, v_5, v_7), v_1, v_7, v_68)
    case cps_provider_2_NfFail{v_76}:
      cps_provider_2_NfFail{v_76}

def native_match_cps_provider_2_nf_descriptor_step_5(v_196: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, v_80: Nat, v_82: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_196:
    case cps_provider_2_NfOk{v_85}:
      cps_provider_2_nf_descriptor(v_1, v_82, cps_provider_2_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_2_NfVal, v_5), v_80), v_85), Nat.sub(v_7, 1n))
    case cps_provider_2_NfFail{v_90}:
      cps_provider_2_NfFail{v_90}

def native_match_cps_provider_2_nf_descriptor_step_6(v_197: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, v_94: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_197:
    case cps_provider_2_NfListOk{v_97}:
      cps_provider_2_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_2_NfVal, v_5, v_97), Nat.sub(v_7, 1n))
    case cps_provider_2_NfListFail{v_101}:
      cps_provider_2_NfFail{v_101}

def native_match_cps_provider_2_nf_descriptor_step_7(v_199: cps_provider_2_NfBind, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_10: BIR.Descriptor, v_107: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_199:
    case cps_provider_2_NfBound{v_113}:
      cps_provider_2_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_2_NfVal, v_5, v_113), Nat.sub(v_7, 1n))
    case _:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_5)}}

def native_match_cps_provider_2_nf_descriptor_step_8(v_198: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_10: BIR.Descriptor, v_105: List<&2, BIR.DescriptorPattern>, v_107: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_198:
    case cps_provider_2_NfListOk{v_110}:
      native_match_cps_provider_2_nf_descriptor_step_7(cps_provider_2_bind_patterns(v_105, v_110), v_1, v_5, v_7, v_10, v_107)
    case cps_provider_2_NfListFail{v_120}:
      cps_provider_2_NfFail{v_120}

def native_match_cps_provider_2_nf_descriptor_step_9(v_200: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, +v_10: BIR.Descriptor, v_124: List<&2, BIR.Descriptor>) -> cps_provider_2_Nf:
  match v_200:
    case cps_provider_2_NfListOk{v_127}:
      cps_provider_2_nf_cases(v_1, v_124, v_127, v_5, v_10, v_7)
    case cps_provider_2_NfListFail{v_130}:
      cps_provider_2_NfFail{v_130}

def native_match_cps_provider_2_nf_descriptor_step_10(v_201: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat, v_139: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_201:
    case cps_provider_2_NfOk{v_142}:
      cps_provider_2_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_2_NfVal, v_5, [v_142]), Nat.sub(v_7, 1n))
    case cps_provider_2_NfFail{v_146}:
      cps_provider_2_NfFail{v_146}

def native_match_cps_provider_2_nf_descriptor_step_11(v_202: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_7: Nat, v_170: String) -> cps_provider_2_Nf:
  match v_202:
    case cps_provider_2_NfListOk{v_175}:
      cps_provider_2_nf_named(v_1, v_170, v_175, v_7)
    case cps_provider_2_NfListFail{v_178}:
      cps_provider_2_NfFail{v_178}

def native_match_cps_provider_2_nf_descriptor_step_12(v_203: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, +v_7: Nat, v_182: String) -> cps_provider_2_Nf:
  match v_203:
    case cps_provider_2_NfListOk{v_187}:
      cps_provider_2_nf_named(v_1, v_182, v_187, v_7)
    case cps_provider_2_NfListFail{v_190}:
      cps_provider_2_NfFail{v_190}

def native_match_cps_provider_2_nf_descriptor_step_13(+v_10: BIR.Descriptor, +v_1: cps_provider_2_NfContext, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_2_Nf:
  match v_10:
    case BIR.DescriptorNull{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_5)}}
    case BIR.DescriptorParameter{v_13}:
      cps_provider_2_NfOk{cps_provider_2_val_at(v_5, v_13, v_10)}
    case BIR.DescriptorQuantityKind{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_5)}}
    case BIR.DescriptorQuantity{v_17}:
      cps_provider_2_NfOk{cps_provider_2_NfQuantity{v_17}}
    case BIR.DescriptorKind{v_19}:
      native_match_cps_provider_2_nf_descriptor_step_0(cps_provider_2_nf(v_1, v_19, v_5, v_7))
    case BIR.DescriptorMinimum{v_28, v_29}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_5)}}
    case BIR.DescriptorArrow{v_34, v_35, v_36}:
      cps_provider_2_nf_arrow(v_1, v_34, v_35, v_36, v_5, v_7)
    case BIR.DescriptorLambda{v_40, v_41}:
      cps_provider_2_NfOk{cps_provider_2_NfClosure{v_40, v_41, v_5, cps_provider_2_materialize_all(v_5)}}
    case BIR.DescriptorRef{v_45, v_46}:
      native_match_cps_provider_2_nf_descriptor_step_1(cps_provider_2_nf_all(v_1, v_46, v_5, v_7), v_1, v_7, v_45)
    case BIR.DescriptorConstructor{v_55, v_56}:
      native_match_cps_provider_2_nf_descriptor_step_2(cps_provider_2_nf_all(v_1, v_56, v_5, v_7), v_55)
    case BIR.DescriptorApplication{v_64, v_65}:
      native_match_cps_provider_2_nf_descriptor_step_4(cps_provider_2_nf(v_1, v_64, v_5, v_7), v_1, v_5, v_7, v_65)
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      native_match_cps_provider_2_nf_descriptor_step_5(cps_provider_2_nf(v_1, v_81, v_5, v_7), v_1, v_5, v_7, v_80, v_82)
    case BIR.DescriptorLet{v_93, v_94}:
      native_match_cps_provider_2_nf_descriptor_step_6(cps_provider_2_nf_all(v_1, v_93, v_5, v_7), v_1, v_5, v_7, v_94)
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      native_match_cps_provider_2_nf_descriptor_step_8(cps_provider_2_nf_all(v_1, v_106, v_5, v_7), v_1, v_5, v_7, v_10, v_105, v_107)
    case BIR.DescriptorMatch{v_123, v_124}:
      native_match_cps_provider_2_nf_descriptor_step_9(cps_provider_2_nf_all(v_1, v_123, v_5, v_7), v_1, v_5, v_7, v_10, v_124)
    case BIR.DescriptorCase{v_133, v_134}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_5)}}
    case BIR.DescriptorBind{v_138, v_139}:
      native_match_cps_provider_2_nf_descriptor_step_10(cps_provider_2_nf(v_1, v_138, v_5, v_7), v_1, v_5, v_7, v_139)
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_5)}}
    case BIR.DescriptorReflexivity{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_5)}}
    case BIR.DescriptorFailure{v_156}:
      cps_provider_2_NfFail{v_156}
    case BIR.DescriptorFill{v_159, v_160}:
      cps_provider_2_nf_apply_args(v_1, v_159, v_160, v_5, v_10, v_7)
    case BIR.DescriptorPlus{v_164, v_165}:
      cps_provider_2_nf_apply_args(v_1, v_164, v_165, v_5, v_10, v_7)
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      native_match_cps_provider_2_nf_descriptor_step_11(cps_provider_2_nf_all(v_1, v_172, v_5, v_7), v_1, v_7, v_170)
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      native_match_cps_provider_2_nf_descriptor_step_12(cps_provider_2_nf_all(v_1, v_184, v_5, v_7), v_1, v_7, v_182)

def cps_provider_2_nf_descriptor_step(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_2_Nf:
  +v_10 = v_2
  native_match_cps_provider_2_nf_descriptor_step_13(v_10, v_1, v_5, v_7)

def native_match_cps_provider_2_nf_all_0(v_25: cps_provider_2_NfList, v_18: cps_provider_2_NfVal) -> cps_provider_2_NfList:
  match v_25:
    case cps_provider_2_NfListFail{v_21}:
      cps_provider_2_NfListFail{v_21}
    case cps_provider_2_NfListOk{v_23}:
      cps_provider_2_NfListOk{v_18 <> v_23}

def native_match_cps_provider_2_nf_all_1(v_24: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, v_13: List<&2, BIR.Descriptor>) -> cps_provider_2_NfList:
  match v_24:
    case cps_provider_2_NfFail{v_16}:
      cps_provider_2_NfListFail{v_16}
    case cps_provider_2_NfOk{v_18}:
      native_match_cps_provider_2_nf_all_0(cps_provider_2_nf_all(v_1, v_13, v_6, v_8), v_18)

def native_match_cps_provider_2_nf_all_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat) -> cps_provider_2_NfList:
  match v_3:
    case []:
      cps_provider_2_NfListOk{[]}
    case +v_12 <> v_13:
      native_match_cps_provider_2_nf_all_1(cps_provider_2_nf(v_1, v_12, v_6, v_8), v_1, v_6, v_8, v_13)

def cps_provider_2_nf_all(+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat) -> cps_provider_2_NfList:
  native_match_cps_provider_2_nf_all_2(v_3, v_1, v_6, v_8)

def native_match_cps_provider_2_nf_apply_args_0(v_23: cps_provider_2_NfList, +v_1: cps_provider_2_NfContext, v_8: BIR.Descriptor, +v_10: Nat, v_16: cps_provider_2_NfVal) -> cps_provider_2_Nf:
  match v_23:
    case cps_provider_2_NfListFail{v_19}:
      cps_provider_2_NfFail{v_19}
    case cps_provider_2_NfListOk{v_21}:
      cps_provider_2_nf_apply_source(v_1, v_16, v_21, v_8, v_10)

def native_match_cps_provider_2_nf_apply_args_1(v_22: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_2_NfVal>, v_8: BIR.Descriptor, +v_10: Nat) -> cps_provider_2_Nf:
  match v_22:
    case cps_provider_2_NfFail{v_14}:
      cps_provider_2_NfFail{v_14}
    case cps_provider_2_NfOk{v_16}:
      native_match_cps_provider_2_nf_apply_args_0(cps_provider_2_nf_all(v_1, v_4, v_7, v_10), v_1, v_8, v_10, v_16)

def cps_provider_2_nf_apply_args(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_2_NfVal>, v_8: BIR.Descriptor, +v_10: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_apply_args_1(cps_provider_2_nf(v_1, v_2, v_7, v_10), v_1, v_4, v_7, v_8, v_10)

def cps_provider_2_nf_apply_source(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_6: List<&2, cps_provider_2_NfVal>, v_7: BIR.Descriptor, +v_9: Nat) -> cps_provider_2_Nf:
  match v_6:
    case []:
      cps_provider_2_NfOk{v_3}
    case _:
      cps_provider_2_nf_apply(v_1, v_3, v_6, v_9)

def native_match_cps_provider_2_nf_apply_0(v_19: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, +v_8: Nat, v_13: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_19:
    case cps_provider_2_NfFail{v_16}:
      cps_provider_2_NfFail{v_16}
    case cps_provider_2_NfOk{v_18}:
      cps_provider_2_nf_apply(v_1, v_18, v_13, Nat.sub(v_8, 1n))

def native_match_cps_provider_2_nf_apply_1(v_6: List<&2, cps_provider_2_NfVal>, +v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, +v_8: Nat) -> cps_provider_2_Nf:
  match v_6:
    case []:
      cps_provider_2_NfOk{v_3}
    case +v_12 <> v_13:
      native_match_cps_provider_2_nf_apply_0(cps_provider_2_nf_apply_one(v_1, v_3, v_12, Nat.sub(v_8, 1n)), v_1, v_8, v_13)

def cps_provider_2_nf_apply(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_apply_1(v_6, v_1, v_3, v_8)

def cps_provider_2_nf_apply_one(+v_1: cps_provider_2_NfContext, v_3: cps_provider_2_NfVal, v_5: cps_provider_2_NfVal, +v_7: Nat) -> cps_provider_2_Nf:
  match v_3:
    case cps_provider_2_NfType{v_11, v_12}:
      cps_provider_2_nf_named(v_1, v_11, List.append(&2, cps_provider_2_NfVal, v_12, [v_5]), Nat.sub(v_7, 1n))
    case cps_provider_2_NfClosure{v_19, v_20, v_21, v_22}:
      cps_provider_2_nf_descriptor(v_1, v_20, List.append(&2, cps_provider_2_NfVal, v_21, [v_5]), Nat.sub(v_7, 1n))
    case cps_provider_2_NfCtor{v_27, v_28}:
      cps_provider_2_NfFail{String.append("the constructor `", String.append(v_27, "` is applied to an argument"))}
    case cps_provider_2_NfQuantity{v_30}:
      cps_provider_2_NfFail{"a quantity is applied to an argument"}
    case cps_provider_2_NfKind{v_32}:
      cps_provider_2_NfFail{"a kind is applied to an argument"}
    case cps_provider_2_NfOther{v_34}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{BIR.DescriptorApplication{v_34, cps_provider_2_materialize(v_5)}}}
    case cps_provider_2_NfMissing{v_37}:
      cps_provider_2_NfOk{cps_provider_2_NfMissing{BIR.DescriptorApplication{v_37, cps_provider_2_materialize(v_5)}}}

def cps_provider_2_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      match v_8:
        case Some{"IO"}:
          True{}
        case _:
          False{}

def cps_provider_2_nf_named_io(v_1: Bool, +v_3: cps_provider_2_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_2_NfVal>, +v_9: Nat) -> cps_provider_2_Nf:
  match v_1:
    case True{}:
      match v_4:
        case BIR.TypeFunction{v_16, v_17, v_18, v_19, v_20}:
          cps_provider_2_NfOk{cps_provider_2_NfType{v_16, v_7}}
    case False{}:
      cps_provider_2_nf_reduce(v_3, v_4, v_7, Nat.sub(v_9, 1n))

def native_match_cps_provider_2_nf_named_0(v_25: Maybe<&2, BIR.Family>, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_25:
    case Some{v_23}:
      cps_provider_2_nf_family(v_23, v_6)
    case None{}:
      cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_6}}

def native_match_cps_provider_2_nf_named_1(v_24: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat, v_12: Map<&2, BIR.Family>) -> cps_provider_2_Nf:
  match v_24:
    case Some{v_16}:
      +v_18 = v_16
      cps_provider_2_nf_named_io(cps_provider_2_intrinsic_io(v_18), v_1, v_18, v_6, v_8)
    case None{}:
      native_match_cps_provider_2_nf_named_0(cps_provider_2_family_of(v_3, v_12), v_3, v_6)

def native_match_cps_provider_2_nf_named_2(+v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat) -> cps_provider_2_Nf:
  match v_1:
    case cps_provider_2_NfContext{v_12, v_13}:
      native_match_cps_provider_2_nf_named_1(cps_provider_2_function_of(v_3, v_13), v_1, v_3, v_6, v_8, v_12)

def cps_provider_2_nf_named(+v_1: cps_provider_2_NfContext, +v_3: String, v_6: List<&2, cps_provider_2_NfVal>, +v_8: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_named_2(v_1, v_3, v_6, v_8)

def cps_provider_2_nf_arity(+v_2: List<&2, cps_provider_2_NfVal>, +v_4: Nat, +v_6: Nat) -> cps_provider_2_NfArity:
  cps_provider_2_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_2_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_2_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_2_NfVal, v_2), v_6)}

def native_match_cps_provider_2_nf_family_0(v_0: BIR.Family, +v_6: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      cps_provider_2_nf_family_apply(cps_provider_2_nf_arity(v_6, v_20, v_17), v_13, v_20, v_6)

def cps_provider_2_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  +v_6 = v_3
  native_match_cps_provider_2_nf_family_0(v_0, v_6)

def cps_provider_2_nf_family_apply(v_1: cps_provider_2_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_1:
    case cps_provider_2_NfArity{v_13, v_14, v_15}:
      match v_13:
        case True{}:
          cps_provider_2_NfOk{cps_provider_2_NfType{v_3, List.append(&2, cps_provider_2_NfVal, cps_provider_2_quantity_markers(v_5), v_8)}}
        case False{}:
          match v_14:
            case True{}:
              cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_8}}
            case False{}:
              match v_15:
                case True{}:
                  cps_provider_2_NfOk{cps_provider_2_NfType{v_3, v_8}}
                case False{}:
                  cps_provider_2_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}

def native_match_cps_provider_2_nf_reduce_0(v_2: BIR.TypeFunction, +v_1: cps_provider_2_NfContext, +v_7: Nat, +v_10: List<&2, cps_provider_2_NfVal>) -> cps_provider_2_Nf:
  match v_2:
    case BIR.TypeFunction{v_16, v_17, v_18, v_19, v_20}:
      +v_22 = v_18
      +v_24 = v_19
      cps_provider_2_nf_reduce_apply(cps_provider_2_nf_arity(v_10, v_22, v_24), v_1, v_16, v_22, v_24, v_20, v_10, v_7)

def cps_provider_2_nf_reduce(+v_1: cps_provider_2_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> cps_provider_2_Nf:
  +v_10 = v_5
  native_match_cps_provider_2_nf_reduce_0(v_2, v_1, v_7, v_10)

def cps_provider_2_nf_reduce_apply(v_1: cps_provider_2_NfArity, +v_3: cps_provider_2_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_2_NfVal>, +v_15: Nat) -> cps_provider_2_Nf:
  match v_1:
    case cps_provider_2_NfArity{v_20, v_21, v_22}:
      match v_20:
        case True{}:
          cps_provider_2_nf_reduce_body(v_3, v_10, List.append(&2, cps_provider_2_NfVal, cps_provider_2_quantity_markers(v_7), v_13), [], Nat.sub(v_15, 1n))
        case False{}:
          match v_21:
            case True{}:
              cps_provider_2_nf_reduce_body(v_3, v_10, cps_provider_2_first_vals(v_13, v_9), cps_provider_2_drop_vals(v_13, v_9), Nat.sub(v_15, 1n))
            case False{}:
              match v_22:
                case True{}:
                  cps_provider_2_NfOk{cps_provider_2_NfType{v_5, v_13}}
                case False{}:
                  cps_provider_2_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}

def native_match_cps_provider_2_nf_reduce_body_0(v_17: cps_provider_2_Nf, +v_1: cps_provider_2_NfContext, v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> cps_provider_2_Nf:
  match v_17:
    case cps_provider_2_NfFail{v_14}:
      cps_provider_2_NfFail{v_14}
    case cps_provider_2_NfOk{v_16}:
      cps_provider_2_nf_apply(v_1, v_16, v_8, v_10)

def cps_provider_2_nf_reduce_body(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, v_8: List<&2, cps_provider_2_NfVal>, +v_10: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_reduce_body_0(cps_provider_2_nf_descriptor(v_1, v_2, v_5, Nat.sub(v_10, 1n)), v_1, v_8, v_10)

def native_match_cps_provider_2_nf_cases_0(v_34: cps_provider_2_NfBind, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, v_18: List<&2, BIR.Descriptor>, v_22: BIR.Descriptor) -> cps_provider_2_Nf:
  match v_34:
    case cps_provider_2_NfBound{v_25}:
      cps_provider_2_nf_descriptor(v_1, v_22, List.append(&2, cps_provider_2_NfVal, v_9, v_25), Nat.sub(v_12, 1n))
    case cps_provider_2_NfMismatch{}:
      cps_provider_2_nf_cases(v_1, v_18, v_6, v_9, v_10, v_12)
    case cps_provider_2_NfUnknown{}:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_9)}}

def native_match_cps_provider_2_nf_cases_1(+v_17: BIR.Descriptor, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, v_18: List<&2, BIR.Descriptor>) -> cps_provider_2_Nf:
  match v_17:
    case BIR.DescriptorCase{v_21, v_22}:
      native_match_cps_provider_2_nf_cases_0(cps_provider_2_bind_patterns(v_21, v_6), v_1, v_6, v_9, v_10, v_12, v_18, v_22)
    case BIR.DescriptorFailure{v_31}:
      cps_provider_2_NfFail{v_31}
    case _:
      cps_provider_2_NfFail{"descriptor match case is not a case"}

def native_match_cps_provider_2_nf_cases_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_2_NfContext, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat) -> cps_provider_2_Nf:
  match v_3:
    case []:
      cps_provider_2_NfOk{cps_provider_2_NfOther{cps_provider_2_reify_env(v_10, v_9)}}
    case +v_17 <> v_18:
      native_match_cps_provider_2_nf_cases_1(v_17, v_1, v_6, v_9, v_10, v_12, v_18)

def cps_provider_2_nf_cases(+v_1: cps_provider_2_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_2_NfVal>, +v_9: List<&2, cps_provider_2_NfVal>, v_10: BIR.Descriptor, +v_12: Nat) -> cps_provider_2_Nf:
  native_match_cps_provider_2_nf_cases_2(v_3, v_1, v_6, v_9, v_10, v_12)

def native_match_cps_provider_2_normalize_0(v_13: cps_provider_2_Nf) -> BIR.Descriptor:
  match v_13:
    case cps_provider_2_NfFail{v_10}:
      BIR.DescriptorFailure{v_10}
    case cps_provider_2_NfOk{v_12}:
      cps_provider_2_materialize(v_12)

def cps_provider_2_normalize(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_2_NfVal>, +v_7: Nat) -> BIR.Descriptor:
  native_match_cps_provider_2_normalize_0(cps_provider_2_nf(v_1, v_2, v_5, v_7))

def cps_provider_2_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_2_normalize(cps_provider_2_nf_context(v_1, v_3), v_4, [], 1024n)

def cps_provider_2_normalize_in(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_2_normalize(v_1, v_2, [], 1024n)

def cps_provider_2_outer_application(+v_0: BIR.Descriptor) -> Maybe<&2, cps_provider_2_NfApp>:
  cps_provider_2_outer_walk(v_0, [])

def cps_provider_2_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> Maybe<&2, cps_provider_2_NfApp>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      Some{cps_provider_2_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      Some{cps_provider_2_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      Some{cps_provider_2_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}
    case BIR.DescriptorFill{v_23, v_24}:
      cps_provider_2_outer_walk(v_23, List.append(&2, BIR.Descriptor, v_24, v_2))
    case BIR.DescriptorPlus{v_28, v_29}:
      cps_provider_2_outer_walk(v_28, List.append(&2, BIR.Descriptor, v_29, v_2))
    case BIR.DescriptorApplication{v_33, v_34}:
      cps_provider_2_outer_walk(v_33, List.append(&2, BIR.Descriptor, [v_34], v_2))
    case _:
      None{}

def native_match_cps_provider_2_answer_in_0(v_5: BIR.Descriptor, +v_1: cps_provider_2_NfContext) -> BIR.Descriptor:
  match v_5:
    case BIR.DescriptorFailure{_}:
      v_5
    case _:
      cps_provider_2_answer_normalized(v_1, v_5)

def cps_provider_2_answer_in(+v_1: cps_provider_2_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  v_5 = cps_provider_2_normalize(v_1, v_2, [], 1024n)
  native_match_cps_provider_2_answer_in_0(v_5, v_1)

def cps_provider_2_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  cps_provider_2_answer_in(cps_provider_2_nf_context(v_2, v_4), v_0)

def native_match_cps_provider_2_answer_normalized_0(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_9:
    case []:
      v_2
    case +v_13 <> v_14:
      v_13

def native_match_cps_provider_2_answer_normalized_1(v_16: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  match v_16:
    case False{}:
      v_2
    case True{}:
      native_match_cps_provider_2_answer_normalized_0(v_9, v_2)

def native_match_cps_provider_2_answer_normalized_2(v_5: cps_provider_2_NfApp, +v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_5:
    case cps_provider_2_NfApp{v_8, v_9}:
      native_match_cps_provider_2_answer_normalized_1(cps_provider_2_is_io_head_in(v_1, v_8), v_2, v_9)

def native_match_cps_provider_2_answer_normalized_3(v_15: Maybe<&2, cps_provider_2_NfApp>, +v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_15:
    case None{}:
      v_2
    case Some{v_5}:
      native_match_cps_provider_2_answer_normalized_2(v_5, v_1, v_2)

def cps_provider_2_answer_normalized(+v_1: cps_provider_2_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  native_match_cps_provider_2_answer_normalized_3(cps_provider_2_outer_application(v_2), v_1, v_2)

def cps_provider_2_is_io_head_in(+v_1: cps_provider_2_NfContext, +v_3: String) -> Bool:
  match v_1:
    case cps_provider_2_NfContext{v_7, v_8}:
      cps_provider_2_is_io_head(v_3, v_7, v_8)

def native_match_cps_provider_2_is_io_head_0(v_10: Maybe<&2, String>) -> Bool:
  match v_10:
    case Some{v_9}:
      String.eq(v_9, "IO")
    case None{}:
      False{}

def cps_provider_2_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Bool:
  native_match_cps_provider_2_is_io_head_0(cps_provider_2_native_of(v_1, v_3, v_5))

def cps_provider_3_js_source(v_2: List<&2, String>) -> Maybe<&2, String>:
  match v_2:
    case []:
      None{}
    case +v_7 <> v_8:
      cps_provider_3_js_source_ext(String.ends_with(v_7, ".js"), v_7, v_8)

def cps_provider_3_js_source_ext(v_1: Bool, +v_3: String, v_6: List<&2, String>) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_3_js_source(v_6)

def cps_provider_3_link_add(v_1: String, v_3: String, v_4: Ast.SourceSpan, v_7: List<&2, cps_provider_3_LinkSource>) -> cps_provider_3_LinkResult:
  match v_7:
    case []:
      cps_provider_3_LinkSuccess{[cps_provider_3_LinkSource{v_1, v_3, v_4}]}
    case +v_11 <> v_12:
      match v_11:
        case cps_provider_3_LinkSource{+v_16, v_17, _}:
          cps_provider_3_link_add_known(String.eq(v_1, v_16), String.eq(v_3, v_17), v_1, v_3, v_4, v_16, v_7, v_11, v_12)

def cps_provider_3_link_add_known(v_1: Bool, v_3: Bool, +v_5: String, +v_7: String, +v_8: Ast.SourceSpan, v_10: String, v_13: List<&2, cps_provider_3_LinkSource>, v_15: cps_provider_3_LinkSource, v_18: List<&2, cps_provider_3_LinkSource>) -> cps_provider_3_LinkResult:
  match v_1:
    case True{}:
      cps_provider_3_link_add_namespace(v_3, v_5, v_8, v_13)
    case False{}:
      cps_provider_3_link_add_tail(cps_provider_3_link_add(v_5, v_7, v_8, v_18), v_15)

def cps_provider_3_link_add_namespace(v_1: Bool, +v_3: String, +v_4: Ast.SourceSpan, v_7: List<&2, cps_provider_3_LinkSource>) -> cps_provider_3_LinkResult:
  match v_1:
    case True{}:
      cps_provider_3_LinkSuccess{v_7}
    case False{}:
      cps_provider_3_LinkFailure{String.append("bend: ", String.append(v_3, " is imported from two namespaces")), v_4}

def cps_provider_3_link_add_tail(v_1: cps_provider_3_LinkResult, v_3: cps_provider_3_LinkSource) -> cps_provider_3_LinkResult:
  match v_1:
    case cps_provider_3_LinkSuccess{+v_6}:
      cps_provider_3_LinkSuccess{v_3 <> v_6}
    case cps_provider_3_LinkFailure{v_9, v_10}:
      cps_provider_3_LinkFailure{v_9, v_10}

def cps_provider_3_link_declarations(v_1: List<&2, BIR.Declaration>, v_4: List<&2, cps_provider_3_LinkSource>) -> cps_provider_3_LinkResult:
  match v_1:
    case []:
      cps_provider_3_LinkSuccess{List.reverse(&2, cps_provider_3_LinkSource, v_4)}
    case +v_9 <> v_10:
      match v_9:
        case BIR.ForeignDeclaration{_, v_21, v_22, _, v_24, _, v_26, _, _}:
          cps_provider_3_link_declaration_source(cps_provider_3_js_source(v_24), v_21, v_22, v_26, v_4, v_10)
        case _:
          cps_provider_3_link_declarations(v_10, v_4)

def cps_provider_3_link_declaration_source(v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_7: Ast.SourceSpan, v_10: List<&2, cps_provider_3_LinkSource>, v_12: List<&2, BIR.Declaration>) -> cps_provider_3_LinkResult:
  match v_2:
    case Some{+v_15}:
      cps_provider_3_link_declaration_plan(cps_provider_3_link_add(v_15, v_4, v_7, v_10), v_12)
    case None{}:
      cps_provider_3_LinkFailure{String.append("bend: foreign definition has no .js import: ", v_6), v_7}

def cps_provider_3_link_declaration_plan(v_1: cps_provider_3_LinkResult, v_3: List<&2, BIR.Declaration>) -> cps_provider_3_LinkResult:
  match v_1:
    case cps_provider_3_LinkSuccess{v_6}:
      cps_provider_3_link_declarations(v_3, v_6)
    case cps_provider_3_LinkFailure{v_10, v_11}:
      cps_provider_3_LinkFailure{v_10, v_11}

def cps_provider_3_constructors_named(v_1: List<&2, BIR.ConstructorLayout>, v_3: String) -> Bool:
  match v_1:
    case []:
      False{}
    case BIR.ConstructorLayout{_, +v_11, _, _} <> v_14:
      cps_provider_3_constructors_named_same(String.eq(v_3, v_11), v_14, v_3)

def cps_provider_3_constructors_named_same(v_1: Bool, v_3: List<&2, BIR.ConstructorLayout>, +v_5: String) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_3_constructors_named(v_3, v_5)

def cps_provider_3_foreign_name_check(v_1: List<&2, BIR.Declaration>, v_3: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, cps_provider_3_LinkResult>:
  match v_1:
    case []:
      None{}
    case +v_8 <> v_9:
      match v_8:
        case BIR.ForeignDeclaration{v_19, _, _, _, _, _, v_25, _, _}:
          cps_provider_3_foreign_name_check_named(cps_provider_3_constructors_named(v_3, v_19), v_19, v_25, v_9, v_3)
        case _:
          cps_provider_3_foreign_name_check(v_9, v_3)

def cps_provider_3_foreign_name_check_named(v_1: Bool, +v_3: String, +v_4: Ast.SourceSpan, v_6: List<&2, BIR.Declaration>, v_8: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, cps_provider_3_LinkResult>:
  match v_1:
    case True{}:
      Some{cps_provider_3_LinkFailure{String.append(v_3, " names both a constructor and a foreign def: name one apart"), v_4}}
    case False{}:
      cps_provider_3_foreign_name_check(v_6, v_8)
    case _:
      cps_provider_3_foreign_name_check(v_6, v_8)

def cps_provider_3_link_checked(v_2: Maybe<&2, cps_provider_3_LinkResult>, v_4: List<&2, BIR.Declaration>) -> cps_provider_3_LinkResult:
  match v_2:
    case Some{v_7}:
      v_7
    case None{}:
      cps_provider_3_link_declarations(v_4, [])

def cps_provider_3_link(v_0: BIR.Program) -> cps_provider_3_LinkResult:
  match v_0:
    case BIR.Program{_, v_9, v_10, _, _, _}:
      cps_provider_3_link_checked(cps_provider_3_foreign_name_check(v_9, v_10), v_9)

def cps_provider_3_js_key_candidate(+v_1: String, +v_3: String) -> String:
  cps_provider_3_js_key_join(String.eq(v_1, ""), v_1, v_3)

def cps_provider_3_js_key_join(v_1: Bool, +v_3: String, +v_5: String) -> String:
  match v_1:
    case True{}:
      v_5
    case False{}:
      String.append(v_3, String.append(".", v_5))

def cps_provider_3_js_key_member(+v_2: Map<&2, Bool>, v_4: String) -> Bool:
  cps_provider_3_js_key_member_found(IndexLookup.find(Bool, v_2, v_4))

def cps_provider_3_js_key_member_found(v_2: Maybe<&2, Bool>) -> Bool:
  match v_2:
    case Some{_}:
      True{}
    case None{}:
      False{}

def cps_provider_3_js_key_resolve(+v_2: Map<&2, Bool>, +v_4: String, +v_6: String) -> Maybe<&2, String>:
  cps_provider_3_js_key_resolve_qualified(cps_provider_3_js_key_member(v_2, cps_provider_3_js_key_candidate(v_4, v_6)), v_2, v_4, v_6)

def cps_provider_3_js_key_resolve_qualified(v_1: Bool, +v_4: Map<&2, Bool>, +v_6: String, +v_8: String) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{cps_provider_3_js_key_candidate(v_6, v_8)}
    case False{}:
      cps_provider_3_js_key_resolve_bare(cps_provider_3_js_key_member(v_4, v_8), v_8)

def cps_provider_3_js_key_resolve_bare(v_1: Bool, +v_3: String) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      None{}

def cps_provider_3_js_key_declaration(v_0: BIR.Declaration, v_3: Map<&2, Bool>) -> Map<&2, Bool>:
  match v_0:
    case BIR.FunctionDeclaration{v_9, _, _}:
      Map.set(&2, Bool, v_3, v_9, True{})
    case BIR.LazyDeclaration{v_15, _}:
      Map.set(&2, Bool, v_3, v_15, True{})
    case BIR.NativeDeclaration{v_21, _, _}:
      Map.set(&2, Bool, v_3, v_21, True{})
    case BIR.ForeignDeclaration{v_34, _, _, _, _, _, _, _, _}:
      Map.set(&2, Bool, v_3, v_34, True{})

def cps_provider_3_js_key_declarations(v_1: List<&2, BIR.Declaration>, v_4: Map<&2, Bool>) -> Map<&2, Bool>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      cps_provider_3_js_key_declarations(v_10, cps_provider_3_js_key_declaration(v_9, v_4))

def cps_provider_3_js_key_layouts(v_1: List<&2, BIR.ConstructorLayout>, v_4: Map<&2, Bool>) -> Map<&2, Bool>:
  match v_1:
    case []:
      v_4
    case BIR.ConstructorLayout{_, v_13, _, _} <> v_16:
      cps_provider_3_js_key_layouts(v_16, Map.set(&2, Bool, v_4, v_13, True{}))

def cps_provider_3_js_key_families(v_1: List<&2, BIR.Family>, v_4: Map<&2, Bool>) -> Map<&2, Bool>:
  match v_1:
    case []:
      v_4
    case BIR.Family{v_14, _, _, _, _, _} <> v_20:
      cps_provider_3_js_key_families(v_20, Map.set(&2, Bool, v_4, v_14, True{}))

def cps_provider_3_js_key_functions(v_1: List<&2, BIR.TypeFunction>, v_4: Map<&2, Bool>) -> Map<&2, Bool>:
  match v_1:
    case []:
      v_4
    case BIR.TypeFunction{v_13, _, _, _, _} <> v_18:
      cps_provider_3_js_key_functions(v_18, Map.set(&2, Bool, v_4, v_13, True{}))

def cps_provider_3_js_native_families(v_1: List<&2, BIR.Family>, v_4: Map<&2, String>) -> Map<&2, String>:
  match v_1:
    case []:
      v_4
    case BIR.Family{v_14, _, v_16, _, _, _} <> v_20:
      cps_provider_3_js_native_family(v_16, v_14, v_20, v_4)

def cps_provider_3_js_native_family(v_2: Maybe<&2, String>, v_4: String, v_6: List<&2, BIR.Family>, v_9: Map<&2, String>) -> Map<&2, String>:
  match v_2:
    case None{}:
      cps_provider_3_js_native_families(v_6, Map.set(&2, String, v_9, v_4, ""))
    case Some{v_15}:
      cps_provider_3_js_native_families(v_6, Map.set(&2, String, v_9, v_4, v_15))

def cps_provider_3_js_native_functions(v_1: List<&2, BIR.TypeFunction>, v_4: Map<&2, String>) -> Map<&2, String>:
  match v_1:
    case []:
      v_4
    case BIR.TypeFunction{v_13, v_14, _, _, _} <> v_18:
      cps_provider_3_js_native_function(v_14, v_13, v_18, v_4)

def cps_provider_3_js_native_function(v_2: Maybe<&2, String>, v_4: String, v_6: List<&2, BIR.TypeFunction>, v_9: Map<&2, String>) -> Map<&2, String>:
  match v_2:
    case None{}:
      cps_provider_3_js_native_functions(v_6, Map.set(&2, String, v_9, v_4, "TF"))
    case Some{v_15}:
      cps_provider_3_js_native_functions(v_6, Map.set(&2, String, v_9, v_4, v_15))

def cps_provider_3_js_native_markers(v_0: BIR.Program) -> Map<&2, String>:
  match v_0:
    case BIR.Program{_, _, _, v_12, v_13, _}:
      cps_provider_3_js_native_functions(v_13, cps_provider_3_js_native_families(v_12, Map.new(&2, String)))

def cps_provider_3_js_known_keys(v_0: BIR.Program) -> Map<&2, Bool>:
  match v_0:
    case BIR.Program{_, v_10, v_11, v_12, v_13, _}:
      cps_provider_3_js_key_functions(v_13, cps_provider_3_js_key_families(v_12, cps_provider_3_js_key_layouts(v_11, cps_provider_3_js_key_declarations(v_10, Map.new(&2, Bool)))))

def cps_provider_3_js_cid(v_1: cps_provider_3_JSScan) -> cps_provider_3_JSCidResult:
  match v_1:
    case cps_provider_3_JSScanComplete{v_4}:
      cps_provider_3_JSCidDone{String.from_list(List.reverse(&2, Char, v_4))}
    case cps_provider_3_JSScanRefused{v_7}:
      cps_provider_3_JSCidFailure{v_7}

def cps_provider_3_js_word(+v_1: Char) -> Bool:
  match v_1:
    case '_':
      True{}
    case _:
      Bool.or(Char.is_alpha(v_1), Char.is_digit(v_1))

def cps_provider_3_js_key_char(+v_1: Char) -> Bool:
  match v_1:
    case '.':
      True{}
    case '/':
      True{}
    case '~':
      True{}
    case '-':
      True{}
    case _:
      cps_provider_3_js_word(v_1)

def cps_provider_3_js_text_closes(v_2: List<&2, Char>, +v_4: Char, +v_6: Bool) -> Bool:
  match v_2:
    case []:
      False{}
    case '\\' <> v_9:
      cps_provider_3_js_text_closes_escape(v_9, v_4, v_6)
    case +v_13 <> v_14:
      cps_provider_3_js_text_closes_step(Char.is_eq(v_13, v_4), v_13, v_14, v_4, v_6)

def cps_provider_3_js_text_closes_escape(v_2: List<&2, Char>, v_4: Char, v_6: Bool) -> Bool:
  match v_2:
    case []:
      False{}
    case _ <> v_11:
      cps_provider_3_js_text_closes(v_11, v_4, v_6)

def cps_provider_3_js_text_closes_step(v_1: Bool, v_3: Char, v_6: List<&2, Char>, v_8: Char, +v_10: Bool) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_3_js_text_closes_newline(Bool.and(v_10, Char.is_eq(v_3, '\n')), v_6, v_8, v_10)

def cps_provider_3_js_text_closes_newline(v_1: Bool, v_4: List<&2, Char>, v_6: Char, v_8: Bool) -> Bool:
  match v_1:
    case True{}:
      False{}
    case False{}:
      cps_provider_3_js_text_closes(v_4, v_6, v_8)

def cps_provider_3_js_block_closes(v_2: List<&2, Char>) -> Bool:
  match v_2:
    case []:
      False{}
    case '*' <> v_5:
      cps_provider_3_js_block_closes_star(v_5)
    case _ <> v_10:
      cps_provider_3_js_block_closes(v_10)

def cps_provider_3_js_block_closes_star(+v_2: List<&2, Char>) -> Bool:
  match v_2:
    case '/' <> _:
      True{}
    case _:
      cps_provider_3_js_block_closes(v_2)

def cps_provider_3_js_emit_chars(v_2: List<&2, Char>, +v_5: List<&2, Char>) -> List<&2, Char>:
  match v_2:
    case []:
      v_5
    case v_10 <> v_11:
      cps_provider_3_js_emit_chars(v_11, v_10 <> v_5)

def cps_provider_3_js_scan(v_2: List<&2, Char>, v_4: cps_provider_3_JSMode, v_6: Bool, +v_9: List<&2, Char>, +v_12: Map<&2, Bool>, +v_14: String) -> cps_provider_3_JSScan:
  match v_2:
    case []:
      cps_provider_3_JSScanComplete{v_9}
    case v_18 <> v_19:
      cps_provider_3_js_scan_mode(v_4, v_18, v_19, v_6, v_9, v_12, v_14)

def cps_provider_3_js_scan_mode(v_1: cps_provider_3_JSMode, +v_3: Char, +v_6: List<&2, Char>, v_8: Bool, +v_11: List<&2, Char>, +v_14: Map<&2, Bool>, +v_16: String) -> cps_provider_3_JSScan:
  match v_1:
    case cps_provider_3_JSCode{}:
      cps_provider_3_js_scan_code(v_3, v_6, v_8, v_11, v_14, v_16)
    case cps_provider_3_JSLineComment{}:
      cps_provider_3_js_scan_line(v_3, v_6, v_11, v_14, v_16)
    case cps_provider_3_JSBlockComment{}:
      cps_provider_3_js_scan_block(v_3, v_6, v_11, v_14, v_16)
    case cps_provider_3_JSDoubleQuote{}:
      cps_provider_3_js_scan_text(v_3, v_6, cps_provider_3_JSDoubleQuote{}, '"', v_11, v_14, v_16)
    case cps_provider_3_JSSingleQuote{}:
      cps_provider_3_js_scan_text(v_3, v_6, cps_provider_3_JSSingleQuote{}, '\'', v_11, v_14, v_16)
    case cps_provider_3_JSBacktick{}:
      cps_provider_3_js_scan_text(v_3, v_6, cps_provider_3_JSBacktick{}, '`', v_11, v_14, v_16)

def cps_provider_3_js_scan_code(+v_1: Char, +v_4: List<&2, Char>, +v_6: Bool, +v_9: List<&2, Char>, +v_12: Map<&2, Bool>, +v_14: String) -> cps_provider_3_JSScan:
  match v_1:
    case '/':
      cps_provider_3_js_scan_slash(v_4, v_9, v_12, v_14)
    case '"':
      cps_provider_3_js_scan(v_4, Bool.pick(cps_provider_3_JSMode, cps_provider_3_js_text_closes(v_4, '"', True{}), cps_provider_3_JSDoubleQuote{}, cps_provider_3_JSCode{}), False{}, v_1 <> v_9, v_12, v_14)
    case '\'':
      cps_provider_3_js_scan(v_4, Bool.pick(cps_provider_3_JSMode, cps_provider_3_js_text_closes(v_4, '\'', True{}), cps_provider_3_JSSingleQuote{}, cps_provider_3_JSCode{}), False{}, v_1 <> v_9, v_12, v_14)
    case '`':
      cps_provider_3_js_scan(v_4, Bool.pick(cps_provider_3_JSMode, cps_provider_3_js_text_closes(v_4, '`', False{}), cps_provider_3_JSBacktick{}, cps_provider_3_JSCode{}), False{}, v_1 <> v_9, v_12, v_14)
    case 'C':
      cps_provider_3_js_scan_cid(v_6, v_4, v_9, v_12, v_14)
    case _:
      cps_provider_3_js_scan(v_4, cps_provider_3_JSCode{}, cps_provider_3_js_word(v_1), v_1 <> v_9, v_12, v_14)

def cps_provider_3_js_scan_slash(+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String) -> cps_provider_3_JSScan:
  match v_2:
    case '/' <> v_13:
      cps_provider_3_js_scan(v_13, cps_provider_3_JSLineComment{}, False{}, '/' <> '/' <> v_5, v_8, v_10)
    case '*' <> +v_16:
      cps_provider_3_js_scan(v_16, Bool.pick(cps_provider_3_JSMode, cps_provider_3_js_block_closes(v_16), cps_provider_3_JSBlockComment{}, cps_provider_3_JSCode{}), False{}, '*' <> '/' <> v_5, v_8, v_10)
    case _:
      cps_provider_3_js_scan(v_2, cps_provider_3_JSCode{}, False{}, '/' <> v_5, v_8, v_10)

def cps_provider_3_js_scan_cid(v_1: Bool, +v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String) -> cps_provider_3_JSScan:
  match v_1:
    case True{}:
      cps_provider_3_js_scan(v_4, cps_provider_3_JSCode{}, True{}, 'C' <> v_7, v_10, v_12)
    case False{}:
      cps_provider_3_js_scan_cid_prefix(v_4, v_7, v_10, v_12)

def cps_provider_3_js_scan_cid_prefix(+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String) -> cps_provider_3_JSScan:
  match v_2:
    case 'I' <> 'D' <> '(' <> +v_13:
      cps_provider_3_js_scan_cid_key(cps_provider_3_js_collect_key(v_13, []), v_13, v_5, v_8, v_10)
    case _:
      cps_provider_3_js_scan(v_2, cps_provider_3_JSCode{}, True{}, 'C' <> v_5, v_8, v_10)

def cps_provider_3_js_scan_cid_key(v_1: cps_provider_3_JSKeyScan, v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String) -> cps_provider_3_JSScan:
  match v_1:
    case cps_provider_3_JSKeyFound{v_16, v_17}:
      cps_provider_3_js_scan_cid_found(v_16, v_17, v_7, v_10, v_12)
    case cps_provider_3_JSKeyAbsent{}:
      cps_provider_3_js_scan(v_4, cps_provider_3_JSCode{}, False{}, '(' <> 'D' <> 'I' <> 'C' <> v_7, v_10, v_12)

def cps_provider_3_js_scan_cid_found(v_1: String, v_4: List<&2, Char>, v_7: List<&2, Char>, v_10: Map<&2, Bool>, v_12: String) -> cps_provider_3_JSScan:
  cps_provider_3_js_scan_cid_resolved(cps_provider_3_js_key_resolve(v_10, v_12, v_1), v_1, v_4, v_7, v_10, v_12)

def cps_provider_3_js_scan_cid_resolved(v_2: Maybe<&2, String>, +v_4: String, v_7: List<&2, Char>, v_10: List<&2, Char>, v_13: Map<&2, Bool>, v_15: String) -> cps_provider_3_JSScan:
  match v_2:
    case Some{v_18}:
      cps_provider_3_js_scan(v_7, cps_provider_3_JSCode{}, False{}, cps_provider_3_js_emit_chars(String.to_list(cps_provider_3_js_quote(v_18)), v_10), v_13, v_15)
    case None{}:
      cps_provider_3_JSScanRefused{String.append("CID(", String.append(v_4, ") names no constructor or def"))}

def cps_provider_3_js_collect_key(v_2: List<&2, Char>, +v_5: List<&2, Char>) -> cps_provider_3_JSKeyScan:
  match v_2:
    case []:
      cps_provider_3_JSKeyAbsent{}
    case ')' <> v_8:
      cps_provider_3_js_collect_key_close(v_5, v_8)
    case +v_12 <> v_13:
      cps_provider_3_js_collect_key_more(cps_provider_3_js_key_char(v_12), v_12, v_13, v_5)

def cps_provider_3_js_collect_key_close(+v_2: List<&2, Char>, v_5: List<&2, Char>) -> cps_provider_3_JSKeyScan:
  match v_2:
    case []:
      cps_provider_3_JSKeyAbsent{}
    case _:
      cps_provider_3_JSKeyFound{String.from_list(List.reverse(&2, Char, v_2)), v_5}

def cps_provider_3_js_collect_key_more(v_1: Bool, v_3: Char, v_6: List<&2, Char>, v_9: List<&2, Char>) -> cps_provider_3_JSKeyScan:
  match v_1:
    case True{}:
      cps_provider_3_js_collect_key(v_6, v_3 <> v_9)
    case False{}:
      cps_provider_3_JSKeyAbsent{}

def cps_provider_3_js_scan_line(+v_1: Char, +v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String) -> cps_provider_3_JSScan:
  match v_1:
    case '\n':
      cps_provider_3_js_scan(v_4, cps_provider_3_JSCode{}, False{}, v_1 <> v_7, v_10, v_12)
    case '\\':
      cps_provider_3_js_scan_line_more(v_4, v_7, v_10, v_12)
    case _:
      cps_provider_3_js_scan(v_4, cps_provider_3_JSLineComment{}, False{}, v_1 <> v_7, v_10, v_12)

def cps_provider_3_js_scan_line_more(+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String) -> cps_provider_3_JSScan:
  match v_2:
    case '\n' <> v_13:
      cps_provider_3_js_scan(v_13, cps_provider_3_JSLineComment{}, False{}, '\n' <> '\\' <> v_5, v_8, v_10)
    case _:
      cps_provider_3_js_scan(v_2, cps_provider_3_JSLineComment{}, False{}, '\\' <> v_5, v_8, v_10)

def cps_provider_3_js_scan_block(+v_1: Char, +v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String) -> cps_provider_3_JSScan:
  match v_1:
    case '*':
      cps_provider_3_js_scan_block_more(v_4, v_7, v_10, v_12)
    case _:
      cps_provider_3_js_scan(v_4, cps_provider_3_JSBlockComment{}, False{}, v_1 <> v_7, v_10, v_12)

def cps_provider_3_js_scan_block_more(+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String) -> cps_provider_3_JSScan:
  match v_2:
    case '/' <> v_13:
      cps_provider_3_js_scan(v_13, cps_provider_3_JSCode{}, False{}, '/' <> '*' <> v_5, v_8, v_10)
    case _:
      cps_provider_3_js_scan(v_2, cps_provider_3_JSBlockComment{}, False{}, '*' <> v_5, v_8, v_10)

def cps_provider_3_js_scan_text(+v_1: Char, +v_4: List<&2, Char>, +v_6: cps_provider_3_JSMode, v_8: Char, +v_11: List<&2, Char>, +v_14: Map<&2, Bool>, +v_16: String) -> cps_provider_3_JSScan:
  match v_1:
    case '\\':
      cps_provider_3_js_scan_text_more(v_4, v_6, v_11, v_14, v_16)
    case _:
      cps_provider_3_js_scan_text_plain(Char.is_eq(v_1, v_8), v_1, v_4, v_6, v_11, v_14, v_16)

def cps_provider_3_js_scan_text_plain(v_1: Bool, +v_3: Char, +v_6: List<&2, Char>, v_8: cps_provider_3_JSMode, +v_11: List<&2, Char>, +v_14: Map<&2, Bool>, +v_16: String) -> cps_provider_3_JSScan:
  match v_1:
    case True{}:
      cps_provider_3_js_scan(v_6, cps_provider_3_JSCode{}, False{}, v_3 <> v_11, v_14, v_16)
    case False{}:
      cps_provider_3_js_scan(v_6, v_8, False{}, v_3 <> v_11, v_14, v_16)

def cps_provider_3_js_scan_text_more(v_2: List<&2, Char>, v_4: cps_provider_3_JSMode, +v_7: List<&2, Char>, v_10: Map<&2, Bool>, v_12: String) -> cps_provider_3_JSScan:
  match v_2:
    case []:
      cps_provider_3_JSScanComplete{'\\' <> v_7}
    case v_16 <> v_17:
      cps_provider_3_js_scan(v_17, v_4, False{}, v_16 <> '\\' <> v_7, v_10, v_12)

def cps_provider_3_js_source_text(v_1: List<&2, BIR.SourceFile>, v_3: String) -> Maybe<&2, String>:
  match v_1:
    case []:
      None{}
    case BIR.SourceFile{+v_9, v_10} <> v_11:
      cps_provider_3_js_source_text_same(String.eq(v_3, v_9), v_10, v_11, v_3)

def cps_provider_3_js_source_text_same(v_1: Bool, v_3: String, v_5: List<&2, BIR.SourceFile>, +v_7: String) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_3_js_source_text(v_5, v_7)

def cps_provider_3_js_effect_chunk(v_1: String) -> String:
  String.append("(() => {\n", String.append(v_1, "\n})();\n\n"))

def cps_provider_3_js_effect_sources(v_2: List<&2, cps_provider_3_LinkSource>, v_4: List<&2, BIR.SourceFile>, +v_7: Map<&2, Bool>, v_10: List<&2, String>) -> cps_provider_3_JSEffects:
  match v_2:
    case []:
      cps_provider_3_JSEffectsReady{String.join(List.reverse(&2, String, v_10), "")}
    case +v_15 <> v_16:
      match v_15:
        case cps_provider_3_LinkSource{v_20, v_21, v_22}:
          cps_provider_3_js_effect_text(cps_provider_3_js_source_text(v_4, v_20), v_20, v_21, v_22, v_16, v_4, v_7, v_10)

def cps_provider_3_js_effect_text(v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_7: Ast.SourceSpan, v_10: List<&2, cps_provider_3_LinkSource>, v_12: List<&2, BIR.SourceFile>, +v_15: Map<&2, Bool>, v_18: List<&2, String>) -> cps_provider_3_JSEffects:
  match v_2:
    case None{}:
      cps_provider_3_JSEffectsFailure{String.append("bend: missing JavaScript foreign source ", v_4), v_7}
    case Some{v_21}:
      cps_provider_3_js_effect_scan(cps_provider_3_js_cid(cps_provider_3_js_scan(String.to_list(v_21), cps_provider_3_JSCode{}, False{}, [], v_15, v_6)), v_4, v_7, v_10, v_12, v_15, v_18)

def cps_provider_3_js_effect_scan(v_1: cps_provider_3_JSCidResult, +v_3: String, +v_4: Ast.SourceSpan, v_7: List<&2, cps_provider_3_LinkSource>, v_9: List<&2, BIR.SourceFile>, +v_12: Map<&2, Bool>, v_15: List<&2, String>) -> cps_provider_3_JSEffects:
  match v_1:
    case cps_provider_3_JSCidFailure{v_18}:
      cps_provider_3_JSEffectsFailure{String.append(String.append(v_3, ": "), v_18), v_4}
    case cps_provider_3_JSCidDone{v_20}:
      cps_provider_3_js_effect_sources(v_7, v_9, v_12, cps_provider_3_js_effect_chunk(v_20) <> v_15)

def cps_provider_3_cat(v_2: List<&2, String>) -> String:
  String.join(v_2, "")

def cps_provider_3_js_escape_char(v_1: Char) -> String:
  match v_1:
    case '"':
      "\\\""
    case '\\':
      "\\\\"
    case '\n':
      "\\n"
    case '\r':
      "\\r"
    case '\t':
      "\\t"
    case '\0':
      "\\u0000"
    case _:
      String.from_list([v_1])

def cps_provider_3_js_quote_chars(v_2: List<&2, Char>) -> String:
  match v_2:
    case []:
      "\""
    case +v_6 <> v_7:
      String.append(cps_provider_3_js_escape_char(v_6), cps_provider_3_js_quote_chars(v_7))

def cps_provider_3_js_quote(v_1: String) -> String:
  String.append("\"", cps_provider_3_js_quote_chars(String.to_list(v_1)))

def cps_provider_3_bool_source(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "true"
    case False{}:
      "false"

def cps_provider_3_optional_text(v_2: Maybe<&2, String>) -> String:
  match v_2:
    case None{}:
      "null"
    case Some{v_5}:
      cps_provider_3_js_quote(v_5)

def cps_provider_3_local(v_1: U32) -> String:
  cps_provider_3_cat(["$v", U32.show(v_1)])

def cps_provider_3_capture(v_1: U32) -> String:
  cps_provider_3_cat(["$c", U32.show(v_1)])

def cps_provider_3_code_name(v_1: U32) -> String:
  cps_provider_3_cat(["$b", U32.show(v_1)])

def cps_provider_3_atom(v_0: BIR.Atom) -> String:
  match v_0:
    case BIR.Local{v_3}:
      cps_provider_3_local(v_3)
    case BIR.Capture{v_6}:
      cps_provider_3_capture(v_6)
    case BIR.Symbol{_, v_11}:
      cps_provider_3_cat(["$D[", cps_provider_3_js_quote(v_11), "]"])
    case BIR.Word{v_14}:
      U32.show(v_14)
    case BIR.Natural{v_15}:
      Nat.show(v_15)
    case BIR.FloatBits{v_17}:
      cps_provider_3_cat(["f32_from_bits(", U32.show(v_17), ")"])
    case BIR.Text{v_19}:
      cps_provider_3_js_quote(v_19)
    case BIR.Boolean{v_21}:
      cps_provider_3_bool_source(v_21)
    case BIR.Null{}:
      "null"
    case BIR.Undefined{}:
      "undefined"

def cps_provider_3_arguments(v_1: List<&2, BIR.Arg>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case BIR.Arg{_, v_8} <> v_9:
      cps_provider_3_atom(v_8) <> cps_provider_3_arguments(v_9)

def cps_provider_3_parameter_names(v_1: List<&2, BIR.Parameter>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case BIR.Parameter{v_7, _} <> v_9:
      cps_provider_3_local(v_7) <> cps_provider_3_parameter_names(v_9)

def cps_provider_3_capture_names(v_1: List<&2, BIR.Use>, +v_3: U32) -> List<&2, String>:
  match v_1:
    case []:
      []
    case _ <> v_9:
      cps_provider_3_capture(v_3) <> cps_provider_3_capture_names(v_9, U32.inc(v_3))

def cps_provider_3_captured_names(v_1: List<&2, BIR.Arg>, +v_3: U32) -> List<&2, String>:
  match v_1:
    case []:
      []
    case _ <> v_9:
      cps_provider_3_capture(v_3) <> cps_provider_3_captured_names(v_9, U32.inc(v_3))

def cps_provider_3_call(v_1: U32, v_4: List<&2, String>) -> String:
  cps_provider_3_cat([cps_provider_3_code_name(v_1), "(", String.join(v_4, ","), ")"])

def cps_provider_3_tail_call(v_1: U32, +v_4: List<&2, String>) -> String:
  +v_8 = List.length(&2, String, v_4)
  cps_provider_3_tail_call_selected(v_1, v_4, v_8, Bool.and(Nat.is_gt(v_8, 0n), Nat.is_le(v_8, 32n)))

def cps_provider_3_tail_call_selected(v_1: U32, v_4: List<&2, String>, v_6: Nat, v_8: Bool) -> String:
  match v_8:
    case True{}:
      cps_provider_3_cat(["run_named", Nat.show(v_6), "(", cps_provider_3_code_name(v_1), ",", String.join(v_4, ","), ",$td)"])
    case False{}:
      cps_provider_3_cat(["run_many(", cps_provider_3_code_name(v_1), ",[", String.join(v_4, ","), "],$td)"])

def cps_provider_3_public_closure(v_2: List<&2, String>, v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case v_8 <> v_9:
      cps_provider_3_cat(["run_clo((", v_8, ",$raw=undefined)=>run_force(", cps_provider_3_public_closure(v_9, v_4), ",$raw))"])

def cps_provider_3_closure(v_1: U32, +v_3: List<&2, BIR.Arg>, +v_5: List<&2, BIR.Parameter>) -> String:
  +v_9 = cps_provider_3_captured_names(v_3, 0)
  +v_12 = cps_provider_3_parameter_names(v_5)
  v_17 = cps_provider_3_public_closure(v_12, cps_provider_3_tail_call(v_1, List.append(&2, String, v_9, v_12)))
  cps_provider_3_closure_captures(v_3, v_9, v_17)

def cps_provider_3_closure_captures(+v_1: List<&2, BIR.Arg>, v_4: List<&2, String>, v_6: String) -> String:
  match v_1:
    case []:
      v_6
    case _:
      cps_provider_3_cat(["((", String.join(v_4, ","), ")=>", v_6, ")(", String.join(cps_provider_3_arguments(v_1), ","), ")"])

def cps_provider_3_record_fields(v_1: List<&2, BIR.Field>) -> String:
  match v_1:
    case []:
      ""
    case BIR.Field{_, v_9, _, v_11} <> v_12:
      cps_provider_3_cat([",[", cps_provider_3_js_quote(v_9), "]:", cps_provider_3_atom(v_11), cps_provider_3_record_fields(v_12)])

def cps_provider_3_foreign_parameters(v_1: Nat, v_3: Nat) -> List<&2, String>:
  match v_1:
    case 0n:
      []
    case 1n+v_7:
      cps_provider_3_cat(["$f", Nat.show(v_3)]) <> cps_provider_3_foreign_parameters(v_7, Nat.add(v_3, 1n))

def cps_provider_3_foreign_arrow(v_2: List<&2, String>, v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case v_8 <> v_9:
      cps_provider_3_cat([v_8, "=>", cps_provider_3_foreign_arrow(v_9, v_4)])

def cps_provider_3_foreign_kont(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "((x)=>$k(nat_in(x)))"
    case False{}:
      "$k"

def cps_provider_3_foreign_request(+v_1: String, v_3: Nat, v_5: Bool) -> String:
  v_9 = cps_provider_3_foreign_parameters(v_3, 0n)
  v_14 = cps_provider_3_cat(["({$:", cps_provider_3_js_quote(v_1), ",args:[", String.join(v_9, ","), "],kont:", cps_provider_3_foreign_kont(v_5), "})"])
  cps_provider_3_cat(["$D[", cps_provider_3_js_quote(v_1), "]=", cps_provider_3_foreign_arrow(List.append(&2, String, v_9, ["$k"]), v_14), ";\n"])

def cps_provider_3_js_descriptor_head(v_0: BIR.Descriptor) -> Maybe<&2, cps_provider_3_JSDescriptorHead>:
  match v_0:
    case BIR.DescriptorRef{v_5, v_6}:
      Some{cps_provider_3_JSDescriptorHead{v_5, v_6}}
    case BIR.DescriptorConstructor{v_9, v_10}:
      Some{cps_provider_3_JSDescriptorHead{v_9, v_10}}
    case BIR.DescriptorNamedFill{v_14, _, v_16}:
      Some{cps_provider_3_JSDescriptorHead{v_14, v_16}}
    case BIR.DescriptorNamedPlus{v_20, _, v_22}:
      Some{cps_provider_3_JSDescriptorHead{v_20, v_22}}
    case BIR.DescriptorFill{v_25, v_26}:
      cps_provider_3_js_descriptor_head_fill(cps_provider_3_js_descriptor_head(v_25), v_26)
    case BIR.DescriptorPlus{v_31, v_32}:
      cps_provider_3_js_descriptor_head_fill(cps_provider_3_js_descriptor_head(v_31), v_32)
    case BIR.DescriptorApplication{v_37, v_38}:
      cps_provider_3_js_descriptor_head_applied(cps_provider_3_js_descriptor_head(v_37), v_38)
    case _:
      None{}

def cps_provider_3_js_descriptor_head_fill(v_2: Maybe<&2, cps_provider_3_JSDescriptorHead>, v_4: List<&2, BIR.Descriptor>) -> Maybe<&2, cps_provider_3_JSDescriptorHead>:
  match v_2:
    case Some{cps_provider_3_JSDescriptorHead{v_9, _}}:
      Some{cps_provider_3_JSDescriptorHead{v_9, v_4}}
    case None{}:
      None{}

def cps_provider_3_js_descriptor_head_applied(v_2: Maybe<&2, cps_provider_3_JSDescriptorHead>, v_3: BIR.Descriptor) -> Maybe<&2, cps_provider_3_JSDescriptorHead>:
  match v_2:
    case Some{cps_provider_3_JSDescriptorHead{v_8, v_9}}:
      Some{cps_provider_3_JSDescriptorHead{v_8, List.append(&2, BIR.Descriptor, v_9, [v_3])}}
    case None{}:
      None{}

def cps_provider_3_js_native_is(+v_2: Map<&2, String>, v_4: String, v_6: String) -> Bool:
  cps_provider_3_js_native_is_found(IndexLookup.find(String, v_2, v_4), v_6)

def cps_provider_3_js_native_is_found(v_2: Maybe<&2, String>, v_4: String) -> Bool:
  match v_2:
    case Some{v_7}:
      String.eq(v_7, v_4)
    case None{}:
      False{}

def cps_provider_3_js_io_answer(v_0: BIR.Descriptor, +v_3: Map<&2, String>) -> Maybe<&2, BIR.Descriptor>:
  cps_provider_3_js_io_answer_head(cps_provider_3_js_descriptor_head(v_0), v_3)

def cps_provider_3_js_io_answer_head(v_2: Maybe<&2, cps_provider_3_JSDescriptorHead>, +v_5: Map<&2, String>) -> Maybe<&2, BIR.Descriptor>:
  match v_2:
    case Some{cps_provider_3_JSDescriptorHead{v_9, v_10}}:
      cps_provider_3_js_io_answer_named(cps_provider_3_js_native_is(v_5, v_9, "IO"), v_10)
    case None{}:
      None{}

def cps_provider_3_js_io_answer_named(v_1: Bool, v_3: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match v_1:
    case True{}:
      cps_provider_3_js_first_descriptor(v_3)
    case False{}:
      None{}

def cps_provider_3_js_first_descriptor(v_1: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match v_1:
    case []:
      None{}
    case +v_5 <> _:
      Some{v_5}

def cps_provider_3_js_nat_descriptor(v_0: BIR.Descriptor, +v_3: Map<&2, String>) -> Bool:
  cps_provider_3_js_nat_descriptor_head(cps_provider_3_js_descriptor_head(v_0), v_3)

def cps_provider_3_js_nat_descriptor_head(v_2: Maybe<&2, cps_provider_3_JSDescriptorHead>, +v_5: Map<&2, String>) -> Bool:
  match v_2:
    case Some{cps_provider_3_JSDescriptorHead{v_9, v_10}}:
      cps_provider_3_js_nat_descriptor_named(cps_provider_3_js_native_is(v_5, v_9, "Nat"), v_10)
    case None{}:
      False{}

def cps_provider_3_js_nat_descriptor_named(v_1: Bool, v_3: List<&2, BIR.Descriptor>) -> Bool:
  match v_1:
    case True{}:
      Nat.is_eq(List.length(&2, BIR.Descriptor, v_3), 0n)
    case False{}:
      False{}

def cps_provider_3_js_bool_of_parameter(v_1: cps_provider_3_JSParameter) -> Bool:
  match v_1:
    case cps_provider_3_JSParameterNat{}:
      True{}
    case _:
      False{}

def cps_provider_3_js_nat_answer(v_0: BIR.Descriptor, +v_3: Map<&2, String>) -> Bool:
  cps_provider_3_js_nat_answer_io(cps_provider_3_js_io_answer(v_0, v_3), v_3)

def cps_provider_3_js_nat_answer_io(v_1: Maybe<&2, BIR.Descriptor>, +v_4: Map<&2, String>) -> Bool:
  match v_1:
    case Some{v_7}:
      cps_provider_3_js_nat_descriptor(v_7, v_4)
    case None{}:
      False{}

def cps_provider_3_operation(v_0: BIR.Op) -> String:
  match v_0:
    case BIR.Copy{v_3}:
      cps_provider_3_atom(v_3)
    case BIR.PrimitiveCall{v_8, v_9, _}:
      cps_provider_3_cat([cps_provider_3_primitive_name(v_8), "(", String.join(cps_provider_3_arguments(v_9), ","), ")"])
    case BIR.Closure{v_17, v_18, v_19}:
      cps_provider_3_closure(v_17, v_18, v_19)
    case BIR.Direct{v_23, v_24}:
      cps_provider_3_cat(["run_loop(", cps_provider_3_call(v_23, cps_provider_3_arguments(v_24)), ")"])
    case BIR.Apply{v_31, BIR.Arg{_, v_33}}:
      cps_provider_3_cat(["run_loop(run_tail(", cps_provider_3_atom(v_31), ",", cps_provider_3_atom(v_33), "))"])
    case BIR.LoadSymbol{_, v_40}:
      cps_provider_3_cat(["$D[", cps_provider_3_js_quote(v_40), "]"])
    case BIR.Construct{_, v_47, v_48}:
      cps_provider_3_cat(["({$:", cps_provider_3_js_quote(v_47), cps_provider_3_record_fields(v_48), "})"])
    case BIR.Project{v_56, _, _, v_59}:
      cps_provider_3_cat([cps_provider_3_atom(v_56), "[", cps_provider_3_js_quote(v_59), "]"])
    case BIR.HasTag{v_66, _, v_68}:
      cps_provider_3_tag_test(cps_provider_3_atom(v_66), v_68)

def cps_provider_3_tag_test(+v_1: String, v_3: String) -> String:
  cps_provider_3_cat(["(", v_1, "&&", v_1, ".$===", cps_provider_3_js_quote(v_3), ")"])

def cps_provider_3_tag_subject_same(v_0: BIR.Atom, v_1: BIR.Atom) -> Bool:
  match v_0, v_1:
    case BIR.Local{v_5}, BIR.Local{v_6}:
      U32.is_eq(v_5, v_6)
    case BIR.Capture{v_9}, BIR.Capture{v_10}:
      U32.is_eq(v_9, v_10)
    case _, _:
      False{}

def cps_provider_3_tagged_region_checked(v_1: Bool, v_3: cps_provider_3_TaggedRegion) -> Maybe<&2, cps_provider_3_TaggedRegion>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      None{}

def cps_provider_3_tagged_region(v_0: BIR.Block) -> Maybe<&2, cps_provider_3_TaggedRegion>:
  match v_0:
    case BIR.Region{+v_12, BIR.Let{+v_13, BIR.HasTag{+v_14, _, v_16}, BIR.Branch{BIR.Local{v_17}, v_18, BIR.LeaveRegion{v_19}}}, v_20}:
      cps_provider_3_tagged_region_checked(Bool.and(U32.is_eq(v_12, v_19), Bool.and(U32.is_eq(v_13, v_17), cps_provider_3_tag_subject_same(v_14, v_14))), cps_provider_3_TaggedRegion{v_12, v_13, v_14, v_16, v_18, v_20})
    case _:
      None{}

def cps_provider_3_tag_unseen(v_2: Maybe<&2, Bool>) -> Bool:
  match v_2:
    case None{}:
      True{}
    case Some{_}:
      False{}

def cps_provider_3_tag_group_selected(v_1: Bool, v_2: BIR.Atom, v_4: cps_provider_3_TaggedRegion, v_5: BIR.Block, v_8: List<&2, cps_provider_3_TagArm>, v_11: Map<&2, Bool>, v_13: Nat) -> cps_provider_3_TagGroup:
  match v_1:
    case False{}:
      cps_provider_3_TagGroup{v_8, v_5, v_13}
    case True{}:
      match v_4:
        case cps_provider_3_TaggedRegion{v_21, v_22, _, +v_24, v_25, v_26}:
          cps_provider_3_tag_group(v_2, v_26, cps_provider_3_TagArm{v_21, v_22, v_24, v_25} <> v_8, Map.set(&2, Bool, v_11, v_24, True{}), Nat.add(v_13, 1n))

def cps_provider_3_tag_group_view(v_2: Maybe<&2, cps_provider_3_TaggedRegion>, +v_3: BIR.Atom, v_4: BIR.Block, v_7: List<&2, cps_provider_3_TagArm>, +v_10: Map<&2, Bool>, v_12: Nat) -> cps_provider_3_TagGroup:
  match v_2:
    case None{}:
      cps_provider_3_TagGroup{v_7, v_4, v_12}
    case Some{+v_15}:
      match v_15:
        case cps_provider_3_TaggedRegion{_, _, v_24, +v_25, _, _}:
          cps_provider_3_tag_group_selected(Bool.and(cps_provider_3_tag_subject_same(v_3, v_24), cps_provider_3_tag_unseen(IndexLookup.find(Bool, v_10, v_25))), v_3, v_15, v_4, v_7, v_10, v_12)

def cps_provider_3_tag_group(v_0: BIR.Atom, +v_1: BIR.Block, v_4: List<&2, cps_provider_3_TagArm>, v_7: Map<&2, Bool>, v_9: Nat) -> cps_provider_3_TagGroup:
  cps_provider_3_tag_group_view(cps_provider_3_tagged_region(v_1), v_0, v_1, v_4, v_7, v_9)

def cps_provider_3_tag_arms(v_2: List<&2, cps_provider_3_TagArm>) -> String:
  match v_2:
    case []:
      ""
    case cps_provider_3_TagArm{v_9, v_10, v_11, v_12} <> v_13:
      cps_provider_3_cat(["case ", cps_provider_3_js_quote(v_11), ":{$case", U32.show(v_9), ":{const ", cps_provider_3_local(v_10), "=true;", cps_provider_3_block(v_12), "}break;}", cps_provider_3_tag_arms(v_13)])

def cps_provider_3_ordinary_region(v_1: U32, v_2: BIR.Block, v_3: BIR.Block) -> String:
  cps_provider_3_cat(["$case", U32.show(v_1), ":{", cps_provider_3_block(v_2), "}", cps_provider_3_block(v_3)])

def cps_provider_3_tag_render_selected(v_1: Bool, v_2: BIR.Atom, v_5: List<&2, cps_provider_3_TagArm>, v_6: BIR.Block, v_8: U32, v_9: BIR.Block, v_10: BIR.Block) -> String:
  match v_1:
    case False{}:
      cps_provider_3_ordinary_region(v_8, v_9, v_10)
    case True{}:
      cps_provider_3_cat(["switch(", cps_provider_3_atom(v_2), "?.$){", cps_provider_3_tag_arms(List.reverse(&2, cps_provider_3_TagArm, v_5)), "}", cps_provider_3_block(v_6)])

def cps_provider_3_tag_render_group(v_1: cps_provider_3_TagGroup, v_2: BIR.Atom, v_4: U32, v_5: BIR.Block, v_6: BIR.Block) -> String:
  match v_1:
    case cps_provider_3_TagGroup{v_11, v_12, +v_13}:
      cps_provider_3_tag_render_selected(Nat.is_gt(v_13, 2n), v_2, v_11, v_12, v_4, v_5, v_6)

def cps_provider_3_region_view(v_2: Maybe<&2, cps_provider_3_TaggedRegion>, v_4: U32, v_5: BIR.Block, v_6: BIR.Block) -> String:
  match v_2:
    case None{}:
      cps_provider_3_ordinary_region(v_4, v_5, v_6)
    case Some{v_10}:
      match v_10:
        case cps_provider_3_TaggedRegion{v_17, v_18, +v_19, +v_20, v_21, v_22}:
          cps_provider_3_tag_render_group(cps_provider_3_tag_group(v_19, v_22, [cps_provider_3_TagArm{v_17, v_18, v_20, v_21}], Map.set(&2, Bool, Map.new(&2, Bool), v_20, True{}), 1n), v_19, v_4, v_5, v_6)

def cps_provider_3_region(+v_1: U32, +v_2: BIR.Block, +v_3: BIR.Block) -> String:
  cps_provider_3_region_view(cps_provider_3_tagged_region(BIR.Region{v_1, v_2, v_3}), v_1, v_2, v_3)

def cps_provider_3_block(v_0: BIR.Block) -> String:
  match v_0:
    case BIR.Return{v_3}:
      cps_provider_3_cat(["return ", cps_provider_3_atom(v_3), ";"])
    case BIR.Let{v_9, v_10, v_11}:
      cps_provider_3_cat(["const ", cps_provider_3_local(v_9), "=", cps_provider_3_operation(v_10), ";", cps_provider_3_block(v_11)])
    case BIR.Branch{v_19, v_20, v_21}:
      cps_provider_3_cat(["if(", cps_provider_3_atom(v_19), "){", cps_provider_3_block(v_20), "}else{", cps_provider_3_block(v_21), "}"])
    case BIR.Region{v_28, v_29, v_30}:
      cps_provider_3_region(v_28, v_29, v_30)
    case BIR.LeaveRegion{v_33}:
      cps_provider_3_cat(["break $case", U32.show(v_33), ";"])
    case BIR.TailDirect{v_37, v_38}:
      cps_provider_3_cat(["return ", cps_provider_3_tail_call(v_37, cps_provider_3_arguments(v_38)), ";"])
    case BIR.TailApply{v_45, BIR.Arg{_, v_47}}:
      cps_provider_3_cat(["return run_tail(", cps_provider_3_atom(v_45), ",", cps_provider_3_atom(v_47), ");"])
    case BIR.Failure{v_52}:
      cps_provider_3_cat(["throw ", cps_provider_3_js_quote(v_52), ";"])

def cps_provider_3_code(v_0: BIR.Code) -> String:
  match v_0:
    case BIR.Code{v_6, v_7, v_8, v_9}:
      v_14 = List.append(&2, String, cps_provider_3_capture_names(v_7, 0), cps_provider_3_parameter_names(v_8))
      cps_provider_3_cat(["function ", cps_provider_3_code_name(v_6), "(", String.join(List.append(&2, String, v_14, ["$td=0"]), ","), "){", cps_provider_3_block(v_9), "}\n"])

def cps_provider_3_codes(v_1: List<&2, BIR.Code>) -> String:
  match v_1:
    case []:
      ""
    case v_5 <> v_6:
      cps_provider_3_cat([cps_provider_3_code(v_5), cps_provider_3_codes(v_6)])

def cps_provider_3_primitive_name(v_0: BIR.Primitive) -> String:
  match v_0:
    case BIR.PrimU32Add{}:
      "$p_u32_add"
    case BIR.PrimU32Sub{}:
      "$p_u32_sub"
    case BIR.PrimU32Mul{}:
      "$p_u32_mul"
    case BIR.PrimU32Div{}:
      "$p_u32_div"
    case BIR.PrimNatAdd{}:
      "$p_nat_add"
    case BIR.PrimNatSub{}:
      "$p_nat_sub"
    case BIR.PrimNatMul{}:
      "$p_nat_mul"
    case BIR.PrimNatCmp{}:
      "$p_nat_cmp"
    case BIR.PrimNatMin{}:
      "$p_nat_min"
    case BIR.PrimNatMax{}:
      "$p_nat_max"
    case BIR.PrimStringAppend{}:
      "$p_string_append"
    case BIR.PrimBoolOr{}:
      "$p_bool_or"
    case BIR.PrimBoolXor{}:
      "$p_bool_xor"
    case BIR.PrimU32IsZero{}:
      "$p_u32_is_zero"
    case BIR.PrimF32Asin{}:
      "$p_f32_asin"
    case BIR.PrimF32Acos{}:
      "$p_f32_acos"
    case BIR.PrimF32Atan{}:
      "$p_f32_atan"
    case BIR.PrimF32Sinh{}:
      "$p_f32_sinh"
    case BIR.PrimF32Cosh{}:
      "$p_f32_cosh"
    case BIR.PrimF32Tanh{}:
      "$p_f32_tanh"
    case BIR.PrimU32Mod{}:
      "$p_u32_mod"
    case BIR.PrimU32And{}:
      "$p_u32_and"
    case BIR.PrimU32Or{}:
      "$p_u32_or"
    case BIR.PrimU32Xor{}:
      "$p_u32_xor"
    case BIR.PrimU32IsEq{}:
      "$p_u32_is_eq"
    case BIR.PrimU32IsNe{}:
      "$p_u32_is_ne"
    case BIR.PrimU32IsLt{}:
      "$p_u32_is_lt"
    case BIR.PrimU32IsLe{}:
      "$p_u32_is_le"
    case BIR.PrimU32IsGt{}:
      "$p_u32_is_gt"
    case BIR.PrimU32IsGe{}:
      "$p_u32_is_ge"
    case BIR.PrimU32Inc{}:
      "$p_u32_inc"
    case BIR.PrimU32Not{}:
      "$p_u32_not"
    case BIR.PrimU32Shl{}:
      "$p_u32_shl"
    case BIR.PrimU32Shr{}:
      "$p_u32_shr"
    case BIR.PrimU32Shln{}:
      "$p_u32_shln"
    case BIR.PrimU32Shrn{}:
      "$p_u32_shrn"
    case BIR.PrimU32Cmp{}:
      "$p_u32_cmp"
    case BIR.PrimU32ToNat{}:
      "$p_u32_to_nat"
    case BIR.PrimU32FromNat{}:
      "$p_u32_from_nat"
    case BIR.PrimF32Add{}:
      "$p_f32_add"
    case BIR.PrimF32Sub{}:
      "$p_f32_sub"
    case BIR.PrimF32Mul{}:
      "$p_f32_mul"
    case BIR.PrimF32Div{}:
      "$p_f32_div"
    case BIR.PrimF32Mod{}:
      "$p_f32_mod"
    case BIR.PrimF32Neg{}:
      "$p_f32_neg"
    case BIR.PrimF32Sqrt{}:
      "$p_f32_sqrt"
    case BIR.PrimF32Abs{}:
      "$p_f32_abs"
    case BIR.PrimF32ToU32{}:
      "$p_f32_to_u32"
    case BIR.PrimF32Bits{}:
      "$p_f32_bits"
    case BIR.PrimF32Show{}:
      "$p_f32_show"
    case BIR.PrimF32Read{}:
      "$p_f32_read"
    case BIR.PrimF32IsEq{}:
      "$p_f32_is_eq"
    case BIR.PrimF32IsNe{}:
      "$p_f32_is_ne"
    case BIR.PrimF32IsLt{}:
      "$p_f32_is_lt"
    case BIR.PrimF32IsLe{}:
      "$p_f32_is_le"
    case BIR.PrimF32IsGt{}:
      "$p_f32_is_gt"
    case BIR.PrimF32IsGe{}:
      "$p_f32_is_ge"
    case BIR.PrimF32Pow{}:
      "$p_f32_pow"
    case BIR.PrimF32Atan2{}:
      "$p_f32_atan2"
    case BIR.PrimF32Exp{}:
      "$p_f32_exp"
    case BIR.PrimF32Log{}:
      "$p_f32_log"
    case BIR.PrimF32Log2{}:
      "$p_f32_log2"
    case BIR.PrimF32Log10{}:
      "$p_f32_log10"
    case BIR.PrimF32Sin{}:
      "$p_f32_sin"
    case BIR.PrimF32Cos{}:
      "$p_f32_cos"
    case BIR.PrimF32Tan{}:
      "$p_f32_tan"
    case BIR.PrimF32Floor{}:
      "$p_f32_floor"
    case BIR.PrimF32Ceil{}:
      "$p_f32_ceil"
    case BIR.PrimF32Trunc{}:
      "$p_f32_trunc"
    case BIR.PrimF32ToNat{}:
      "$p_f32_to_nat"
    case BIR.PrimU32ToF32{}:
      "$p_u32_to_f32"
    case BIR.PrimNatDouble{}:
      "$p_nat_double"
    case BIR.PrimNatIsLt{}:
      "$p_nat_is_lt"
    case BIR.PrimNatDivmod{}:
      "$p_nat_divmod"
    case BIR.PrimStringEq{}:
      "$p_string_eq"
    case BIR.PrimMapBit{}:
      "$p_map_bit"
    case BIR.PrimStringCmp{}:
      "$p_string_cmp"
    case BIR.PrimStringToList{}:
      "$p_string_to_list"
    case BIR.PrimStringLength{}:
      "$p_string_length"
    case BIR.PrimArrayNew{}:
      "$p_array_new"
    case BIR.PrimArraySet{}:
      "$p_array_set"
    case BIR.PrimArrayGet{}:
      "$p_array_get"
    case BIR.PrimArraySwap{}:
      "$p_array_swap"
    case BIR.PrimArraySize{}:
      "$p_array_size"
    case BIR.PrimArrayClone{}:
      "$p_array_clone"
    case BIR.PrimNatPredecessor{}:
      "$p_nat_predecessor"
    case BIR.PrimNatSuccessor{}:
      "$p_nat_successor"
    case BIR.PrimCharNew{}:
      "$p_char_new"
    case BIR.PrimCharCode{}:
      "$p_char_code"
    case BIR.PrimStringHead{}:
      "$p_string_head"
    case BIR.PrimStringTail{}:
      "$p_string_tail"
    case BIR.PrimWordToU32{}:
      "$p_word_to_u32"
    case BIR.PrimU32ToWord{}:
      "$p_u32_to_word"
    case BIR.PrimF32FromBits{}:
      "$p_f32_from_bits"
    case BIR.PrimF32FromWord{}:
      "$p_f32_from_word"
    case BIR.PrimF32ToWord{}:
      "$p_f32_to_word"
    case BIR.PrimArrayLeaf{}:
      "$p_array_leaf"
    case BIR.PrimArrayNode{}:
      "$p_array_node"
    case BIR.PrimArrayLeafValue{}:
      "$p_array_leaf_value"
    case BIR.PrimArrayLeft{}:
      "$p_array_left"
    case BIR.PrimArrayRight{}:
      "$p_array_right"
    case BIR.PrimIsArrayLeaf{}:
      "$p_is_array_leaf"
    case BIR.PrimIsArrayNode{}:
      "$p_is_array_node"
    case BIR.PrimIsNatZero{}:
      "$p_is_nat_zero"
    case BIR.PrimIsNatSuccessor{}:
      "$p_is_nat_successor"
    case BIR.PrimIsStringEmpty{}:
      "$p_is_string_empty"
    case BIR.PrimIsStringNonempty{}:
      "$p_is_string_nonempty"
    case BIR.PrimIsTrue{}:
      "$p_is_true"
    case BIR.PrimIsFalse{}:
      "$p_is_false"
    case BIR.PrimSameValue{}:
      "$p_same_value"
    case BIR.PrimFloatBitsEqual{}:
      "$p_float_bits_equal"

def cps_provider_3_primitive_public(v_0: BIR.Primitive) -> String:
  match v_0:
    case BIR.PrimU32Add{}:
      "(a)=>(b)=>((a+b)>>>0)"
    case BIR.PrimU32Sub{}:
      "(a)=>(b)=>((a-b)>>>0)"
    case BIR.PrimU32Mul{}:
      "(a)=>(b)=>(Math.imul(a,b)>>>0)"
    case BIR.PrimU32Div{}:
      "(a)=>(b)=>(b===0?0:(a/b)>>>0)"
    case BIR.PrimNatAdd{}:
      "(a)=>(b)=>nat_chk(a+b)"
    case BIR.PrimNatSub{}:
      "(a)=>(b)=>(a<b?0:a-b)"
    case BIR.PrimNatMul{}:
      "(a)=>(b)=>nat_chk(a*b)"
    case BIR.PrimNatCmp{}:
      "(a)=>(b)=>cmp_new(a,b)"
    case BIR.PrimNatMin{}:
      "(a)=>(b)=>(a<b?a:b)"
    case BIR.PrimNatMax{}:
      "(a)=>(b)=>(a>b?a:b)"
    case BIR.PrimStringAppend{}:
      "(a)=>(b)=>a+b"
    case BIR.PrimBoolOr{}:
      "(a)=>(b)=>a||b"
    case BIR.PrimBoolXor{}:
      "(a)=>(b)=>a!==b"
    case BIR.PrimU32IsZero{}:
      "(a)=>a===0"
    case BIR.PrimF32Asin{}:
      "(a)=>Math.fround(Math.asin(a))"
    case BIR.PrimF32Acos{}:
      "(a)=>Math.fround(Math.acos(a))"
    case BIR.PrimF32Atan{}:
      "(a)=>Math.fround(Math.atan(a))"
    case BIR.PrimF32Sinh{}:
      "(a)=>Math.fround(Math.sinh(a))"
    case BIR.PrimF32Cosh{}:
      "(a)=>Math.fround(Math.cosh(a))"
    case BIR.PrimF32Tanh{}:
      "(a)=>Math.fround(Math.tanh(a))"
    case BIR.PrimU32Mod{}:
      "(a)=>(b)=>(b===0?a:a%b)"
    case BIR.PrimU32And{}:
      "(a)=>(b)=>((a&b)>>>0)"
    case BIR.PrimU32Or{}:
      "(a)=>(b)=>((a|b)>>>0)"
    case BIR.PrimU32Xor{}:
      "(a)=>(b)=>((a^b)>>>0)"
    case BIR.PrimU32IsEq{}:
      "(a)=>(b)=>a===b"
    case BIR.PrimU32IsNe{}:
      "(a)=>(b)=>a!==b"
    case BIR.PrimU32IsLt{}:
      "(a)=>(b)=>a<b"
    case BIR.PrimU32IsLe{}:
      "(a)=>(b)=>a<=b"
    case BIR.PrimU32IsGt{}:
      "(a)=>(b)=>a>b"
    case BIR.PrimU32IsGe{}:
      "(a)=>(b)=>a>=b"
    case BIR.PrimU32Inc{}:
      "(a)=>(a+1)>>>0"
    case BIR.PrimU32Not{}:
      "(a)=>(~a)>>>0"
    case BIR.PrimU32Shl{}:
      "(a)=>(a<<1)>>>0"
    case BIR.PrimU32Shr{}:
      "(a)=>a>>>1"
    case BIR.PrimU32Shln{}:
      "(a)=>(b)=>b>=32?0:(a<<b)>>>0"
    case BIR.PrimU32Shrn{}:
      "(a)=>(b)=>b>=32?0:a>>>b"
    case BIR.PrimU32Cmp{}:
      "(a)=>(b)=>cmp_new(a,b)"
    case BIR.PrimU32ToNat{}:
      "(a)=>a"
    case BIR.PrimU32FromNat{}:
      "(a)=>a>>>0"
    case BIR.PrimF32Add{}:
      "(a)=>(b)=>Math.fround(a+b)"
    case BIR.PrimF32Sub{}:
      "(a)=>(b)=>Math.fround(a-b)"
    case BIR.PrimF32Mul{}:
      "(a)=>(b)=>Math.fround(a*b)"
    case BIR.PrimF32Div{}:
      "(a)=>(b)=>Math.fround(a/b)"
    case BIR.PrimF32Mod{}:
      "(a)=>(b)=>Math.fround(a%b)"
    case BIR.PrimF32Neg{}:
      "(a)=>-a"
    case BIR.PrimF32Sqrt{}:
      "(a)=>Math.fround(Math.sqrt(a))"
    case BIR.PrimF32Abs{}:
      "(a)=>Math.fround(Math.abs(a))"
    case BIR.PrimF32ToU32{}:
      "(a)=>(a>=1&&a<4294967296?Math.floor(a):0)"
    case BIR.PrimF32Bits{}:
      "(a)=>f32_bits(a)"
    case BIR.PrimF32Show{}:
      "(a)=>f32_show(a)"
    case BIR.PrimF32Read{}:
      "(a)=>f32_read(a)"
    case BIR.PrimF32IsEq{}:
      "(a)=>(b)=>a===b"
    case BIR.PrimF32IsNe{}:
      "(a)=>(b)=>a!==b"
    case BIR.PrimF32IsLt{}:
      "(a)=>(b)=>a<b"
    case BIR.PrimF32IsLe{}:
      "(a)=>(b)=>a<=b"
    case BIR.PrimF32IsGt{}:
      "(a)=>(b)=>a>b"
    case BIR.PrimF32IsGe{}:
      "(a)=>(b)=>a>=b"
    case BIR.PrimF32Pow{}:
      "(a)=>(b)=>Math.fround(Math.pow(a,b))"
    case BIR.PrimF32Atan2{}:
      "(a)=>(b)=>Math.fround(Math.atan2(a,b))"
    case BIR.PrimF32Exp{}:
      "(a)=>Math.fround(Math.exp(a))"
    case BIR.PrimF32Log{}:
      "(a)=>Math.fround(Math.log(a))"
    case BIR.PrimF32Log2{}:
      "(a)=>Math.fround(Math.log2(a))"
    case BIR.PrimF32Log10{}:
      "(a)=>Math.fround(Math.log10(a))"
    case BIR.PrimF32Sin{}:
      "(a)=>Math.fround(Math.sin(a))"
    case BIR.PrimF32Cos{}:
      "(a)=>Math.fround(Math.cos(a))"
    case BIR.PrimF32Tan{}:
      "(a)=>Math.fround(Math.tan(a))"
    case BIR.PrimF32Floor{}:
      "(a)=>Math.fround(Math.floor(a))"
    case BIR.PrimF32Ceil{}:
      "(a)=>Math.fround(Math.ceil(a))"
    case BIR.PrimF32Trunc{}:
      "(a)=>Math.fround(Math.trunc(a))"
    case BIR.PrimF32ToNat{}:
      "(a)=>Math.floor(a)"
    case BIR.PrimU32ToF32{}:
      "(a)=>Math.fround(a)"
    case BIR.PrimNatDouble{}:
      "(a)=>nat_chk(a+a)"
    case BIR.PrimNatIsLt{}:
      "(a)=>(b)=>a<b"
    case BIR.PrimNatDivmod{}:
      "(a)=>(b)=>nat_divmod(a,b)"
    case BIR.PrimStringEq{}:
      "(a)=>(b)=>a===b"
    case BIR.PrimMapBit{}:
      "(key)=>(position)=>{const character=Math.floor(position/33);if(character>=key.length)return tuple(key,false);const offset=position%33;let at=0;for(let i=0;i<character&&at<key.length;i++)at+=key.codePointAt(at)>65535?2:1;return tuple(key,at<key.length&&(offset===0||((key.codePointAt(at)>>>(32-offset))&1)!==0));}"
    case BIR.PrimStringCmp{}:
      "(a)=>(b)=>{let i=0,j=0,order=0;if(a!==b){while(i<a.length&&j<b.length){const x=a.codePointAt(i),y=b.codePointAt(j);if(x!==y){order=x<y?-1:1;break;}i+=x>65535?2:1;j+=y>65535?2:1;}if(order===0)order=i<a.length?1:j<b.length?-1:0;}return tuple(tuple(a,b),cmp_new(order,0));}"
    case BIR.PrimStringToList{}:
      "(text)=>{let tail={$:\"Nil\"};for(let i=text.length;i>0;){const end=i,low=text.charCodeAt(--i);if(low>=0xDC00&&low<=0xDFFF&&i>0){const high=text.charCodeAt(i-1);if(high>=0xD800&&high<=0xDBFF)--i;}tail={$:\"Con\",head:text.slice(i,end),tail};}return tail;}"
    case BIR.PrimStringLength{}:
      "(a)=>[...a].length"
    case BIR.PrimArrayNew{}:
      "(a)=>(b)=>array_new(a,b)"
    case BIR.PrimArraySet{}:
      "(a)=>(i)=>(v)=>(a[i%a.length]=v,a)"
    case BIR.PrimArrayGet{}:
      "(a)=>(i)=>tuple(a,a[i%a.length])"
    case BIR.PrimArraySwap{}:
      "(a)=>(i)=>(v)=>array_swap(a,i,v)"
    case BIR.PrimArraySize{}:
      "(a)=>tuple(a,a.length)"
    case BIR.PrimArrayClone{}:
      "(a)=>tuple(a,a.slice())"
    case BIR.PrimNatPredecessor{}:
      "(a)=>a-1"
    case BIR.PrimNatSuccessor{}:
      "(a)=>nat_chk(a+1)"
    case BIR.PrimCharNew{}:
      "(a)=>char_new(a)"
    case BIR.PrimCharCode{}:
      "(a)=>a.codePointAt(0)"
    case BIR.PrimStringHead{}:
      "(a)=>String.fromCodePoint(a.codePointAt(0))"
    case BIR.PrimStringTail{}:
      "(a)=>$string_tail(a)"
    case BIR.PrimWordToU32{}:
      "(a)=>word_to_u32(a)"
    case BIR.PrimU32ToWord{}:
      "(a)=>u32_to_word(a)"
    case BIR.PrimF32FromBits{}:
      "(a)=>f32_from_bits(a)"
    case BIR.PrimF32FromWord{}:
      "(a)=>f32_from_bits(word_to_u32(a))"
    case BIR.PrimF32ToWord{}:
      "(a)=>u32_to_word(f32_bits(a))"
    case BIR.PrimArrayLeaf{}:
      "(a)=>[a]"
    case BIR.PrimArrayNode{}:
      "(a)=>(b)=>array_node(a,b)"
    case BIR.PrimArrayLeafValue{}:
      "(a)=>a[0]"
    case BIR.PrimArrayLeft{}:
      "(a)=>a.slice(0,a.length>>1)"
    case BIR.PrimArrayRight{}:
      "(a)=>a.slice(a.length>>1)"
    case BIR.PrimIsArrayLeaf{}:
      "(a)=>a.length===1"
    case BIR.PrimIsArrayNode{}:
      "(a)=>a.length!==1"
    case BIR.PrimIsNatZero{}:
      "(a)=>a===0"
    case BIR.PrimIsNatSuccessor{}:
      "(a)=>a>0"
    case BIR.PrimIsStringEmpty{}:
      "(a)=>a===\"\""
    case BIR.PrimIsStringNonempty{}:
      "(a)=>a!==\"\""
    case BIR.PrimIsTrue{}:
      "(a)=>a===true"
    case BIR.PrimIsFalse{}:
      "(a)=>a===false"
    case BIR.PrimSameValue{}:
      "(a)=>(b)=>a===b"
    case BIR.PrimFloatBitsEqual{}:
      "(a)=>(b)=>f32_bits(a)===b"

def cps_provider_3_primitive_runtime() -> String:
  "const $p_u32_add=(a,b)=>((a+b)>>>0);\nconst $p_u32_sub=(a,b)=>((a-b)>>>0);\nconst $p_u32_mul=(a,b)=>(Math.imul(a,b)>>>0);\nconst $p_u32_div=(a,b)=>(b===0?0:(a/b)>>>0);\nconst $p_nat_add=(a,b)=>nat_chk(a+b);\nconst $p_nat_sub=(a,b)=>(a<b?0:a-b);\nconst $p_nat_mul=(a,b)=>nat_chk(a*b);\nconst $p_nat_cmp=(a,b)=>cmp_new(a,b);\nconst $p_nat_min=(a,b)=>(a<b?a:b);\nconst $p_nat_max=(a,b)=>(a>b?a:b);\nconst $p_string_append=(a,b)=>a+b;\nconst $p_bool_or=(a,b)=>a||b;\nconst $p_bool_xor=(a,b)=>a!==b;\nconst $p_u32_is_zero=(a)=>a===0;\nconst $p_f32_asin=(a)=>Math.fround(Math.asin(a));\nconst $p_f32_acos=(a)=>Math.fround(Math.acos(a));\nconst $p_f32_atan=(a)=>Math.fround(Math.atan(a));\nconst $p_f32_sinh=(a)=>Math.fround(Math.sinh(a));\nconst $p_f32_cosh=(a)=>Math.fround(Math.cosh(a));\nconst $p_f32_tanh=(a)=>Math.fround(Math.tanh(a));\nconst $p_u32_mod=(a,b)=>(b===0?a:a%b);\nconst $p_u32_and=(a,b)=>((a&b)>>>0);\nconst $p_u32_or=(a,b)=>((a|b)>>>0);\nconst $p_u32_xor=(a,b)=>((a^b)>>>0);\nconst $p_u32_is_eq=(a,b)=>a===b;\nconst $p_u32_is_ne=(a,b)=>a!==b;\nconst $p_u32_is_lt=(a,b)=>a<b;\nconst $p_u32_is_le=(a,b)=>a<=b;\nconst $p_u32_is_gt=(a,b)=>a>b;\nconst $p_u32_is_ge=(a,b)=>a>=b;\nconst $p_u32_inc=(a)=>(a+1)>>>0;\nconst $p_u32_not=(a)=>(~a)>>>0;\nconst $p_u32_shl=(a)=>(a<<1)>>>0;\nconst $p_u32_shr=(a)=>a>>>1;\nconst $p_u32_shln=(a,b)=>b>=32?0:(a<<b)>>>0;\nconst $p_u32_shrn=(a,b)=>b>=32?0:a>>>b;\nconst $p_u32_cmp=(a,b)=>cmp_new(a,b);\nconst $p_u32_to_nat=(a)=>a;\nconst $p_u32_from_nat=(a)=>a>>>0;\nconst $p_f32_add=(a,b)=>Math.fround(a+b);\nconst $p_f32_sub=(a,b)=>Math.fround(a-b);\nconst $p_f32_mul=(a,b)=>Math.fround(a*b);\nconst $p_f32_div=(a,b)=>Math.fround(a/b);\nconst $p_f32_mod=(a,b)=>Math.fround(a%b);\nconst $p_f32_neg=(a)=>-a;\nconst $p_f32_sqrt=(a)=>Math.fround(Math.sqrt(a));\nconst $p_f32_abs=(a)=>Math.fround(Math.abs(a));\nconst $p_f32_to_u32=(a)=>(a>=1&&a<4294967296?Math.floor(a):0);\nconst $p_f32_bits=(a)=>f32_bits(a);\nconst $p_f32_show=(a)=>f32_show(a);\nconst $p_f32_read=(a)=>f32_read(a);\nconst $p_f32_is_eq=(a,b)=>a===b;\nconst $p_f32_is_ne=(a,b)=>a!==b;\nconst $p_f32_is_lt=(a,b)=>a<b;\nconst $p_f32_is_le=(a,b)=>a<=b;\nconst $p_f32_is_gt=(a,b)=>a>b;\nconst $p_f32_is_ge=(a,b)=>a>=b;\nconst $p_f32_pow=(a,b)=>Math.fround(Math.pow(a,b));\nconst $p_f32_atan2=(a,b)=>Math.fround(Math.atan2(a,b));\nconst $p_f32_exp=(a)=>Math.fround(Math.exp(a));\nconst $p_f32_log=(a)=>Math.fround(Math.log(a));\nconst $p_f32_log2=(a)=>Math.fround(Math.log2(a));\nconst $p_f32_log10=(a)=>Math.fround(Math.log10(a));\nconst $p_f32_sin=(a)=>Math.fround(Math.sin(a));\nconst $p_f32_cos=(a)=>Math.fround(Math.cos(a));\nconst $p_f32_tan=(a)=>Math.fround(Math.tan(a));\nconst $p_f32_floor=(a)=>Math.fround(Math.floor(a));\nconst $p_f32_ceil=(a)=>Math.fround(Math.ceil(a));\nconst $p_f32_trunc=(a)=>Math.fround(Math.trunc(a));\nconst $p_f32_to_nat=(a)=>Math.floor(a);\nconst $p_u32_to_f32=(a)=>Math.fround(a);\nconst $p_nat_double=(a)=>nat_chk(a+a);\nconst $p_nat_is_lt=(a,b)=>a<b;\nconst $p_nat_divmod=(a,b)=>nat_divmod(a,b);\nconst $p_string_eq=(a,b)=>a===b;\nconst $p_map_bit=(key,position)=>{const character=Math.floor(position/33);if(character>=key.length)return tuple(key,false);const offset=position%33;let at=0;for(let i=0;i<character&&at<key.length;i++)at+=key.codePointAt(at)>65535?2:1;return tuple(key,at<key.length&&(offset===0||((key.codePointAt(at)>>>(32-offset))&1)!==0));};\nconst $p_string_cmp=(a,b)=>{let i=0,j=0,order=0;if(a!==b){while(i<a.length&&j<b.length){const x=a.codePointAt(i),y=b.codePointAt(j);if(x!==y){order=x<y?-1:1;break;}i+=x>65535?2:1;j+=y>65535?2:1;}if(order===0)order=i<a.length?1:j<b.length?-1:0;}return tuple(tuple(a,b),cmp_new(order,0));};\nconst $p_string_to_list=(text)=>{let tail={$:\"Nil\"};for(let i=text.length;i>0;){const end=i,low=text.charCodeAt(--i);if(low>=0xDC00&&low<=0xDFFF&&i>0){const high=text.charCodeAt(i-1);if(high>=0xD800&&high<=0xDBFF)--i;}tail={$:\"Con\",head:text.slice(i,end),tail};}return tail;};\nconst $p_string_length=(a)=>[...a].length;\nconst $p_array_new=(a,b)=>array_new(a,b);\nconst $p_array_set=(a,i,v)=>(a[i%a.length]=v,a);\nconst $p_array_get=(a,i)=>tuple(a,a[i%a.length]);\nconst $p_array_swap=(a,i,v)=>array_swap(a,i,v);\nconst $p_array_size=(a)=>tuple(a,a.length);\nconst $p_array_clone=(a)=>tuple(a,a.slice());\nconst $p_nat_predecessor=(a)=>a-1;\nconst $p_nat_successor=(a)=>nat_chk(a+1);\nconst $p_char_new=(a)=>char_new(a);\nconst $p_char_code=(a)=>a.codePointAt(0);\nconst $p_string_head=(a)=>String.fromCodePoint(a.codePointAt(0));\nconst $p_string_tail=(a)=>$string_tail(a);\nconst $p_word_to_u32=(a)=>word_to_u32(a);\nconst $p_u32_to_word=(a)=>u32_to_word(a);\nconst $p_f32_from_bits=(a)=>f32_from_bits(a);\nconst $p_f32_from_word=(a)=>f32_from_bits(word_to_u32(a));\nconst $p_f32_to_word=(a)=>u32_to_word(f32_bits(a));\nconst $p_array_leaf=(a)=>[a];\nconst $p_array_node=(a,b)=>array_node(a,b);\nconst $p_array_leaf_value=(a)=>a[0];\nconst $p_array_left=(a)=>a.slice(0,a.length>>1);\nconst $p_array_right=(a)=>a.slice(a.length>>1);\nconst $p_is_array_leaf=(a)=>a.length===1;\nconst $p_is_array_node=(a)=>a.length!==1;\nconst $p_is_nat_zero=(a)=>a===0;\nconst $p_is_nat_successor=(a)=>a>0;\nconst $p_is_string_empty=(a)=>a===\"\";\nconst $p_is_string_nonempty=(a)=>a!==\"\";\nconst $p_is_true=(a)=>a===true;\nconst $p_is_false=(a)=>a===false;\nconst $p_same_value=(a,b)=>a===b;\nconst $p_float_bits_equal=(a,b)=>f32_bits(a)===b;\n"

def cps_provider_3_quantity(v_0: BIR.Quantity) -> String:
  match v_0:
    case BIR.Erased{}:
      "0"
    case BIR.Once{}:
      "1"
    case BIR.Unrestricted{}:
      "2"

def cps_provider_3_optional_quantity(v_1: Maybe<&2, BIR.Quantity>) -> String:
  match v_1:
    case None{}:
      "null"
    case Some{v_4}:
      cps_provider_3_quantity(v_4)

def cps_provider_3_quantities(v_1: List<&2, BIR.Quantity>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case v_6 <> v_7:
      cps_provider_3_quantity(v_6) <> cps_provider_3_quantities(v_7)

def cps_provider_3_descriptor_pattern(v_0: BIR.DescriptorPattern) -> String:
  match v_0:
    case BIR.DescriptorBinder{v_3}:
      cps_provider_3_cat(["({v:true,q:", cps_provider_3_quantity(v_3), "})"])
    case BIR.DescriptorConstructorPattern{v_8, v_9}:
      cps_provider_3_cat(["({c:", cps_provider_3_js_quote(v_8), ",s:\"\",i:{},fields:[", String.join(cps_provider_3_descriptor_patterns(v_9), ","), "]})"])

def cps_provider_3_descriptor_patterns(v_1: List<&2, BIR.DescriptorPattern>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case v_6 <> v_7:
      cps_provider_3_descriptor_pattern(v_6) <> cps_provider_3_descriptor_patterns(v_7)

def cps_provider_3_descriptors(v_1: List<&2, BIR.Descriptor>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case v_6 <> v_7:
      cps_provider_3_descriptor(v_6) <> cps_provider_3_descriptors(v_7)

def cps_provider_3_descriptor(v_0: BIR.Descriptor) -> String:
  match v_0:
    case BIR.DescriptorNull{}:
      cps_provider_3_cat(["null"])
    case BIR.DescriptorRef{v_5, v_6}:
      cps_provider_3_cat(["({r:", cps_provider_3_js_quote(v_5), ",a:[", String.join(cps_provider_3_descriptors(v_6), ","), "],s:\"\",i:{}})"])
    case BIR.DescriptorParameter{v_11}:
      cps_provider_3_cat(["({p:", Nat.show(v_11), "})"])
    case BIR.DescriptorQuantityKind{}:
      cps_provider_3_cat(["({k:\"QK\"})"])
    case BIR.DescriptorQuantity{v_14}:
      cps_provider_3_cat(["({k:\"Q\",v:", cps_provider_3_quantity(v_14), "})"])
    case BIR.DescriptorKind{v_17}:
      cps_provider_3_cat(["({kind:", cps_provider_3_descriptor(v_17), "})"])
    case BIR.DescriptorMinimum{v_22, v_23}:
      cps_provider_3_cat(["({min:", cps_provider_3_descriptor(v_22), ",right:", cps_provider_3_descriptor(v_23), "})"])
    case BIR.DescriptorArrow{v_30, v_31, v_32}:
      cps_provider_3_cat(["({all:", cps_provider_3_descriptor(v_31), ",q:", cps_provider_3_quantity(v_30), ",body:", cps_provider_3_descriptor(v_32), "})"])
    case BIR.DescriptorLambda{v_39, v_40}:
      cps_provider_3_cat(["({lam:", cps_provider_3_descriptor(v_40), ",q:", cps_provider_3_optional_quantity(v_39), "})"])
    case BIR.DescriptorConstructor{v_46, v_47}:
      cps_provider_3_cat(["({c:", cps_provider_3_js_quote(v_46), ",a:[", String.join(cps_provider_3_descriptors(v_47), ","), "],s:\"\",i:{}})"])
    case BIR.DescriptorApplication{v_53, v_54}:
      cps_provider_3_cat(["({app:", cps_provider_3_descriptor(v_53), ",arg:", cps_provider_3_descriptor(v_54), "})"])
    case BIR.DescriptorSubstitution{v_60, v_61, v_62}:
      cps_provider_3_cat(["({sub:", Nat.show(v_60), ",value:", cps_provider_3_descriptor(v_61), ",body:", cps_provider_3_descriptor(v_62), "})"])
    case BIR.DescriptorLet{v_68, v_69}:
      cps_provider_3_cat(["({let:[", String.join(cps_provider_3_descriptors(v_68), ","), "],body:", cps_provider_3_descriptor(v_69), "})"])
    case BIR.DescriptorLocal{v_76, v_77, v_78}:
      cps_provider_3_cat(["({local:[", String.join(cps_provider_3_descriptors(v_77), ","), "],pat:[", String.join(cps_provider_3_descriptor_patterns(v_76), ","), "],body:", cps_provider_3_descriptor(v_78), "})"])
    case BIR.DescriptorMatch{v_85, v_86}:
      cps_provider_3_cat(["({match:[", String.join(cps_provider_3_descriptors(v_85), ","), "],cases:[", String.join(cps_provider_3_descriptors(v_86), ","), "]})"])
    case BIR.DescriptorCase{v_92, v_93}:
      cps_provider_3_cat(["({pat:[", String.join(cps_provider_3_descriptor_patterns(v_92), ","), "],body:", cps_provider_3_descriptor(v_93), "})"])
    case BIR.DescriptorBind{v_98, v_99}:
      cps_provider_3_cat(["({bind:", cps_provider_3_descriptor(v_98), ",body:", cps_provider_3_descriptor(v_99), "})"])
    case BIR.DescriptorEquality{v_106, v_107, v_108}:
      cps_provider_3_cat(["({k:\"E\",left:", cps_provider_3_descriptor(v_106), ",right:", cps_provider_3_descriptor(v_107), ",ty:", cps_provider_3_descriptor(v_108), "})"])
    case BIR.DescriptorReflexivity{}:
      cps_provider_3_cat(["({k:\"Refl\"})"])
    case BIR.DescriptorFailure{v_115}:
      cps_provider_3_cat(["({fail:", cps_provider_3_js_quote(v_115), "})"])
    case BIR.DescriptorFill{v_120, v_121}:
      cps_provider_3_cat(["({sugar:", cps_provider_3_descriptor(v_120), ",a:[", String.join(cps_provider_3_descriptors(v_121), ","), "],f:1})"])
    case BIR.DescriptorPlus{v_127, v_128}:
      cps_provider_3_cat(["({sugar:", cps_provider_3_descriptor(v_127), ",a:[", String.join(cps_provider_3_descriptors(v_128), ","), "],f:2})"])
    case BIR.DescriptorNamedFill{v_135, v_136, v_137}:
      cps_provider_3_cat(["({r:", cps_provider_3_js_quote(v_135), ",h:", cps_provider_3_descriptor(v_136), ",a:[", String.join(cps_provider_3_descriptors(v_137), ","), "],s:\"\",i:{},f:1})"])
    case BIR.DescriptorNamedPlus{v_145, v_146, v_147}:
      cps_provider_3_cat(["({r:", cps_provider_3_js_quote(v_145), ",h:", cps_provider_3_descriptor(v_146), ",a:[", String.join(cps_provider_3_descriptors(v_147), ","), "],s:\"\",i:{},f:2})"])

def cps_provider_3_deferred(v_1: String, v_3: String) -> String:
  cps_provider_3_cat(["Object.defineProperty($D,", cps_provider_3_js_quote(v_1), ",{enumerable:true,configurable:true,get(){return run_loop(", v_3, ");}});\n"])

def cps_provider_3_declaration(v_0: BIR.Declaration, +v_3: Map<&2, String>) -> String:
  match v_0:
    case BIR.FunctionDeclaration{v_8, v_9, v_10}:
      cps_provider_3_cat(["$D[", cps_provider_3_js_quote(v_8), "]=", cps_provider_3_closure(v_9, [], v_10), ";\n"])
    case BIR.LazyDeclaration{v_16, v_17}:
      cps_provider_3_deferred(v_16, cps_provider_3_cat(["(()=>{", cps_provider_3_block(v_17), "})()"]))
    case BIR.NativeDeclaration{v_24, v_25, v_26}:
      cps_provider_3_native_declaration(v_24, v_25, v_26)
    case BIR.ForeignDeclaration{v_37, _, v_39, v_40, v_41, _, _, _, v_45}:
      cps_provider_3_foreign_declaration(v_37, v_39, v_41, v_40, v_45, v_3)

def cps_provider_3_foreign_declaration(+v_1: String, v_3: String, v_6: List<&2, String>, v_8: Nat, v_9: BIR.Descriptor, +v_12: Map<&2, String>) -> String:
  cps_provider_3_foreign_source(cps_provider_3_js_source(v_6), v_1, v_3, v_8, v_9, v_12)

def cps_provider_3_foreign_source(v_2: Maybe<&2, String>, +v_4: String, +v_6: String, v_8: Nat, v_9: BIR.Descriptor, +v_12: Map<&2, String>) -> String:
  match v_2:
    case Some{_}:
      cps_provider_3_foreign_request(v_4, v_8, cps_provider_3_js_nat_answer(v_9, v_12))
    case None{}:
      cps_provider_3_deferred(v_4, cps_provider_3_cat(["(()=>{throw new Error(", cps_provider_3_js_quote(String.append("bend: foreign definition has no .js import: ", v_6)), ")})()"]))

def cps_provider_3_native_declaration(+v_1: String, v_2: BIR.Primitive, +v_4: List<&2, BIR.Quantity>) -> String:
  cps_provider_3_cat(["$D[", cps_provider_3_js_quote(v_1), "]=", cps_provider_3_primitive_public(v_2), ";\n$TYPEF[", cps_provider_3_js_quote(v_1), "]={n:", Nat.show(List.length(&2, BIR.Quantity, v_4)), ",q:[", String.join(cps_provider_3_quantities(v_4), ","), "],intrinsic:$D[", cps_provider_3_js_quote(v_1), "]};\n"])

def cps_provider_3_declarations(v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, String>) -> String:
  match v_1:
    case []:
      ""
    case v_8 <> v_9:
      cps_provider_3_cat([cps_provider_3_declaration(v_8, v_4), cps_provider_3_declarations(v_9, v_4)])

def cps_provider_3_field_names(v_3: List<&2, Maybe<&2, String>>) -> List<&2, String>:
  match v_3:
    case []:
      []
    case v_8 <> v_9:
      cps_provider_3_optional_text(v_8) <> cps_provider_3_field_names(v_9)

def cps_provider_3_constructor_layout(v_0: BIR.ConstructorLayout) -> String:
  match v_0:
    case BIR.ConstructorLayout{_, v_7, v_8, v_9}:
      cps_provider_3_constructor_layout_source(v_7, cps_provider_3_optional_text(v_8), String.join(cps_provider_3_field_names(v_9), ","))

def cps_provider_3_constructor_layout_source(+v_1: String, v_3: String, v_5: String) -> String:
  cps_provider_3_cat(["$FIELDS[", cps_provider_3_js_quote(v_1), "]=[", v_5, "];\n$PRIMITIVES[", cps_provider_3_js_quote(v_1), "]=", v_3, ";\n"])

def cps_provider_3_constructor_layouts(v_1: List<&2, BIR.ConstructorLayout>) -> String:
  match v_1:
    case []:
      ""
    case v_5 <> v_6:
      cps_provider_3_cat([cps_provider_3_constructor_layout(v_5), cps_provider_3_constructor_layouts(v_6)])

def cps_provider_3_descriptor_field_types(v_1: List<&2, BIR.DescriptorField>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case BIR.DescriptorField{_, _, v_10} <> v_11:
      cps_provider_3_descriptor(v_10) <> cps_provider_3_descriptor_field_types(v_11)

def cps_provider_3_descriptor_field_quantities(v_1: List<&2, BIR.DescriptorField>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case BIR.DescriptorField{_, v_9, _} <> v_11:
      cps_provider_3_quantity(v_9) <> cps_provider_3_descriptor_field_quantities(v_11)

def cps_provider_3_descriptor_field_names(v_1: List<&2, BIR.DescriptorField>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case BIR.DescriptorField{v_8, _, _} <> v_11:
      cps_provider_3_optional_text(v_8) <> cps_provider_3_descriptor_field_names(v_11)

def cps_provider_3_descriptor_arm(v_0: BIR.DescriptorArm) -> String:
  match v_0:
    case BIR.DescriptorArm{v_4, +v_5}:
      cps_provider_3_cat(["[", cps_provider_3_js_quote(v_4), "]:{types:[", String.join(cps_provider_3_descriptor_field_types(v_5), ","), "],q:[", String.join(cps_provider_3_descriptor_field_quantities(v_5), ","), "],fields:[", String.join(cps_provider_3_descriptor_field_names(v_5), ","), "]}"])

def cps_provider_3_descriptor_arms(v_1: List<&2, BIR.DescriptorArm>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case v_6 <> v_7:
      cps_provider_3_descriptor_arm(v_6) <> cps_provider_3_descriptor_arms(v_7)

def cps_provider_3_parameter_info(v_1: String, v_3: Nat, v_5: Nat) -> String:
  cps_provider_3_cat(["$PARAMS[", cps_provider_3_js_quote(v_1), "]={q:", Nat.show(v_3), ",n:", Nat.show(v_5), "};\n"])

def cps_provider_3_family(v_0: BIR.Family) -> String:
  match v_0:
    case BIR.Family{+v_8, v_9, v_10, v_11, v_12, v_13}:
      cps_provider_3_cat([cps_provider_3_parameter_info(v_8, v_11, v_12), "$TYPE[", cps_provider_3_js_quote(v_8), "]={name:", cps_provider_3_js_quote(v_9), ",native:", cps_provider_3_optional_text(v_10), ",arms:{", String.join(cps_provider_3_descriptor_arms(v_13), ","), "}};\n"])

def cps_provider_3_families(v_1: List<&2, BIR.Family>) -> String:
  match v_1:
    case []:
      ""
    case v_5 <> v_6:
      cps_provider_3_cat([cps_provider_3_family(v_5), cps_provider_3_families(v_6)])

def cps_provider_3_type_function(v_0: BIR.TypeFunction) -> String:
  match v_0:
    case BIR.TypeFunction{+v_7, v_8, v_9, +v_10, v_11}:
      cps_provider_3_cat([cps_provider_3_parameter_info(v_7, v_9, v_10), "$TYPEF[", cps_provider_3_js_quote(v_7), "]={n:", Nat.show(v_10), ",native:", cps_provider_3_optional_text(v_8), ",body:", cps_provider_3_descriptor(v_11), "};\n"])

def cps_provider_3_type_functions(v_1: List<&2, BIR.TypeFunction>) -> String:
  match v_1:
    case []:
      ""
    case v_5 <> v_6:
      cps_provider_3_cat([cps_provider_3_type_function(v_5), cps_provider_3_type_functions(v_6)])

def cps_provider_3_js_parameter(v_0: BIR.Descriptor, +v_3: Map<&2, String>) -> cps_provider_3_JSParameter:
  cps_provider_3_js_parameter_head(cps_provider_3_js_descriptor_head(v_0), v_3, v_0)

def cps_provider_3_js_parameter_head(v_2: Maybe<&2, cps_provider_3_JSDescriptorHead>, +v_5: Map<&2, String>, v_6: BIR.Descriptor) -> cps_provider_3_JSParameter:
  match v_2:
    case Some{cps_provider_3_JSDescriptorHead{v_10, v_11}}:
      cps_provider_3_js_parameter_marker(cps_provider_3_js_native_is(v_5, v_10, "Nat"), IndexLookup.find(String, v_5, v_10), v_11, v_6)
    case None{}:
      cps_provider_3_js_parameter_unresolved(v_6)

def cps_provider_3_js_parameter_marker(v_1: Bool, v_4: Maybe<&2, String>, v_6: List<&2, BIR.Descriptor>, v_7: BIR.Descriptor) -> cps_provider_3_JSParameter:
  match v_1:
    case True{}:
      cps_provider_3_js_parameter_arity(v_6)
    case False{}:
      cps_provider_3_js_parameter_other(v_4, v_7)

def cps_provider_3_js_parameter_other(v_2: Maybe<&2, String>, v_3: BIR.Descriptor) -> cps_provider_3_JSParameter:
  match v_2:
    case Some{v_6}:
      cps_provider_3_js_parameter_known(v_6, v_3)
    case None{}:
      cps_provider_3_JSParameterUnresolved{}

def cps_provider_3_js_parameter_known(v_1: String, v_2: BIR.Descriptor) -> cps_provider_3_JSParameter:
  cps_provider_3_js_parameter_alias(String.eq(v_1, "TF"), v_2)

def cps_provider_3_js_parameter_alias(v_1: Bool, v_2: BIR.Descriptor) -> cps_provider_3_JSParameter:
  match v_1:
    case True{}:
      cps_provider_3_JSParameterUnresolved{}
    case False{}:
      cps_provider_3_JSParameterOther{}

def cps_provider_3_js_parameter_arity(v_1: List<&2, BIR.Descriptor>) -> cps_provider_3_JSParameter:
  cps_provider_3_js_parameter_arity_count(Nat.is_eq(List.length(&2, BIR.Descriptor, v_1), 0n))

def cps_provider_3_js_parameter_arity_count(v_1: Bool) -> cps_provider_3_JSParameter:
  match v_1:
    case True{}:
      cps_provider_3_JSParameterNat{}
    case False{}:
      cps_provider_3_JSParameterOther{}

def cps_provider_3_js_parameter_unresolved(v_0: BIR.Descriptor) -> cps_provider_3_JSParameter:
  match v_0:
    case BIR.DescriptorFailure{_}:
      cps_provider_3_JSParameterUnresolved{}
    case _:
      cps_provider_3_JSParameterOther{}

def cps_provider_3_export_arguments(v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>, v_6: Nat) -> List<&2, String>:
  match v_1:
    case []:
      []
    case +v_11 <> v_12:
      cps_provider_3_export_argument(cps_provider_3_js_parameter(v_11, v_4), v_6) <> cps_provider_3_export_arguments(v_12, v_4, Nat.add(v_6, 1n))

def cps_provider_3_export_argument(v_1: cps_provider_3_JSParameter, v_3: Nat) -> String:
  match v_1:
    case cps_provider_3_JSParameterNat{}:
      cps_provider_3_cat(["nat_in(arguments[", Nat.show(v_3), "])"])
    case _:
      cps_provider_3_cat(["arguments[", Nat.show(v_3), "]"])

def cps_provider_3_export_unresolved(+v_1: String, v_3: List<&2, BIR.Descriptor>, +v_6: Map<&2, String>) -> Bool:
  match v_3:
    case []:
      False{}
    case +v_10 <> v_11:
      cps_provider_3_export_unresolved_item(cps_provider_3_js_parameter(v_10, v_6), v_1, v_11, v_6)

def cps_provider_3_export_unresolved_item(v_1: cps_provider_3_JSParameter, +v_3: String, v_5: List<&2, BIR.Descriptor>, +v_8: Map<&2, String>) -> Bool:
  match v_1:
    case cps_provider_3_JSParameterUnresolved{}:
      True{}
    case _:
      cps_provider_3_export_unresolved(v_3, v_5, v_8)

def cps_provider_3_export_field(v_0: BIR.Export, +v_3: Map<&2, String>) -> String:
  match v_0:
    case BIR.Export{+v_7, None{}, +v_8}:
      cps_provider_3_export_curried(v_7, v_8, v_3)
    case BIR.Export{+v_14, Some{BIR.Entry{v_15, +v_16}}, +v_17}:
      cps_provider_3_cat(["[", cps_provider_3_js_quote(v_14), "](){return arguments.length===", Nat.show(v_16), "?run_loop(", cps_provider_3_call(v_15, cps_provider_3_export_arguments(v_17, v_3, 0n)), "):", cps_provider_3_export_curried_call(v_14, v_17, v_3), ";}"])

def native_match_cps_provider_3_export_nat_indices_0(v_17: cps_provider_3_JSParameter, +v_4: Map<&2, String>, v_6: Nat, v_12: List<&2, BIR.Descriptor>) -> List<&2, Nat>:
  match v_17:
    case cps_provider_3_JSParameterNat{}:
      v_6 <> cps_provider_3_export_nat_indices(v_12, v_4, Nat.add(v_6, 1n))
    case _:
      cps_provider_3_export_nat_indices(v_12, v_4, Nat.add(v_6, 1n))

def native_match_cps_provider_3_export_nat_indices_1(v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>, v_6: Nat) -> List<&2, Nat>:
  match v_1:
    case []:
      []
    case +v_11 <> v_12:
      native_match_cps_provider_3_export_nat_indices_0(cps_provider_3_js_parameter(v_11, v_4), v_4, v_6, v_12)

def cps_provider_3_export_nat_indices(v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>, v_6: Nat) -> List<&2, Nat>:
  native_match_cps_provider_3_export_nat_indices_1(v_1, v_4, v_6)

def cps_provider_3_export_nat_index_texts(v_2: List<&2, Nat>) -> List<&2, String>:
  match v_2:
    case []:
      []
    case v_7 <> v_8:
      Nat.show(v_7) <> cps_provider_3_export_nat_index_texts(v_8)

def cps_provider_3_export_nat_indexes(v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>) -> String:
  String.join(cps_provider_3_export_nat_index_texts(cps_provider_3_export_nat_indices(v_1, v_4, 0n)), ",")

def cps_provider_3_export_curried(v_1: String, v_3: List<&2, BIR.Descriptor>, +v_6: Map<&2, String>) -> String:
  cps_provider_3_cat(["[", cps_provider_3_js_quote(v_1), "]:$curried($D[", cps_provider_3_js_quote(v_1), "],", Nat.show(List.length(&2, BIR.Descriptor, v_3)), ",[", cps_provider_3_export_nat_indexes(v_3, v_6), "])"])

def cps_provider_3_export_curried_call(v_1: String, v_3: List<&2, BIR.Descriptor>, +v_6: Map<&2, String>) -> String:
  cps_provider_3_export_curried_call_body(v_1, v_3, v_6)

def cps_provider_3_export_curried_call_body(v_1: String, v_3: List<&2, BIR.Descriptor>, +v_6: Map<&2, String>) -> String:
  cps_provider_3_cat(["$curried($D[", cps_provider_3_js_quote(v_1), "],", Nat.show(List.length(&2, BIR.Descriptor, v_3)), ",[", cps_provider_3_export_nat_indexes(v_3, v_6), "])(...arguments)"])

def cps_provider_3_export_fields(v_1: List<&2, BIR.Export>, +v_4: Map<&2, String>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case v_9 <> v_10:
      cps_provider_3_export_field(v_9, v_4) <> cps_provider_3_export_fields(v_10, v_4)

def cps_provider_3_ending(v_0: BIR.Ending, +v_3: Map<&2, String>) -> String:
  match v_0:
    case BIR.Executable{v_6}:
      cps_provider_3_js_main(cps_provider_3_descriptor(v_6))
    case BIR.Library{v_10}:
      cps_provider_3_cat(["export default {", String.join(cps_provider_3_export_fields(v_10, v_3), ","), "};\n"])

def cps_provider_3_export_check(v_1: List<&2, BIR.Export>, +v_4: Map<&2, String>) -> Maybe<&2, String>:
  match v_1:
    case []:
      None{}
    case BIR.Export{+v_11, _, v_13} <> v_14:
      cps_provider_3_export_check_one(cps_provider_3_export_unresolved(v_11, v_13, v_4), v_11, v_14, v_4)

def cps_provider_3_export_check_one(v_1: Bool, +v_3: String, v_5: List<&2, BIR.Export>, +v_8: Map<&2, String>) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{String.append(v_3, " has an export parameter with no canonical type")}
    case False{}:
      cps_provider_3_export_check(v_5, v_8)

def cps_provider_3_ending_check(v_0: BIR.Ending, +v_3: Map<&2, String>) -> Maybe<&2, String>:
  match v_0:
    case BIR.Library{v_7}:
      cps_provider_3_export_check(v_7, v_3)
    case BIR.Executable{_}:
      None{}

def cps_provider_3_emit_linked(v_0: BIR.Program, v_2: List<&2, BIR.SourceFile>) -> cps_provider_3_EmitResult:
  cps_provider_3_emit_linked_plan(cps_provider_3_link(v_0), v_0, v_2)

def cps_provider_3_emit_linked_plan(v_1: cps_provider_3_LinkResult, v_2: BIR.Program, v_4: List<&2, BIR.SourceFile>) -> cps_provider_3_EmitResult:
  match v_1:
    case cps_provider_3_LinkFailure{v_8, v_9}:
      cps_provider_3_EmitFailure{v_8, v_9}
    case cps_provider_3_LinkSuccess{v_11}:
      cps_provider_3_emit_checked(v_2, v_11, v_4)

def cps_provider_3_emit_checked(+v_0: BIR.Program, v_3: List<&2, cps_provider_3_LinkSource>, v_5: List<&2, BIR.SourceFile>) -> cps_provider_3_EmitResult:
  match v_0:
    case BIR.Program{_, _, _, _, _, v_18}:
      cps_provider_3_emit_checked_exports(cps_provider_3_ending_check(v_18, cps_provider_3_js_native_markers(v_0)), v_0, v_3, v_5)

def cps_provider_3_emit_checked_exports(v_2: Maybe<&2, String>, v_3: BIR.Program, v_6: List<&2, cps_provider_3_LinkSource>, v_8: List<&2, BIR.SourceFile>) -> cps_provider_3_EmitResult:
  match v_2:
    case Some{v_11}:
      cps_provider_3_EmitFailure{v_11, Ast.SpanOf{"", 0n, 0n}}
    case None{}:
      cps_provider_3_emit_effects(v_3, cps_provider_3_js_effect_sources(v_6, v_8, cps_provider_3_js_known_keys(v_3), []))

def cps_provider_3_emit_effects(v_0: BIR.Program, v_2: cps_provider_3_JSEffects) -> cps_provider_3_EmitResult:
  match v_2:
    case cps_provider_3_JSEffectsFailure{v_6, v_7}:
      cps_provider_3_EmitFailure{v_6, v_7}
    case cps_provider_3_JSEffectsReady{v_9}:
      cps_provider_3_EmitSuccess{cps_provider_3_program_source(v_0, v_9)}

def native_match_cps_provider_3_program_source_0(v_0: BIR.Program, v_2: String, +v_6: Map<&2, String>) -> String:
  match v_0:
    case BIR.Program{v_13, v_14, v_15, v_16, v_17, v_18}:
      cps_provider_3_cat([cps_provider_3_js_runtime, cps_provider_3_js_runtime_extra, cps_provider_3_js_runtime_show, cps_provider_3_js_runtime_cli, cps_provider_3_js_runtime_io, cps_provider_3_js_runtime_array, cps_provider_3_js_runtime_foreign, cps_provider_3_js_runtime_namespace, cps_provider_3_primitive_runtime, cps_provider_3_constructor_layouts(v_15), cps_provider_3_families(v_16), cps_provider_3_type_functions(v_17), v_2, cps_provider_3_codes(v_13), cps_provider_3_declarations(v_14, v_6), cps_provider_3_ending(v_18, v_6)])

def cps_provider_3_program_source(v_0: BIR.Program, v_2: String) -> String:
  +v_6 = cps_provider_3_js_native_markers(v_0)
  native_match_cps_provider_3_program_source_0(v_0, v_2, v_6)

def cps_provider_3_js_runtime() -> String:
  "const $D = Object.create(null);\nconst $BEND_TAIL = Symbol(\"bend.tail\");\nconst $td = 64;\nconst $TAIL_PENDING = Object.create(null), $tailArgs = Array(32);\nlet $tailFn, $tailCount=0, $tailUnary, $tailRest;\nfunction tail_many(f,a) { $tailFn=f; $tailCount=-2; $tailRest=a; return $TAIL_PENDING; }\nfunction tail_unary(f,x) { $tailFn=f; $tailCount=-1; $tailUnary=x; return $TAIL_PENDING; }\nfunction tail_named(f,n) { $tailFn=f; $tailCount=n; return $TAIL_PENDING; }\nfunction $run(f, xs) { let x=run_loop(f); for (const a of xs) x=run_loop(x(a)); return x; }\nfunction $curried(f, n, g) { const step = (args) => function (...more) { const xs = args.concat(more); if (xs.length < n) return step(xs); for (const i of g) xs[i] = nat_in(xs[i]); return $run(f, xs); }; return step([]); }\nfunction run_loop(x) { while (x===$TAIL_PENDING) { const f=$tailFn, count=$tailCount; $tailFn=undefined; $tailCount=0; if(count===-1) { const a=$tailUnary; $tailUnary=undefined; x=f(a,$BEND_TAIL); } else x=tail_dispatch(f,count); } return x; }\nfunction tail_dispatch(f,count) { switch(count) {\ncase -2: { const a=$tailRest; $tailRest=undefined; return f(...a); }\ncase 1: { const a0=$tailArgs[0]; $tailArgs[0]=undefined; return f(a0); }\ncase 2: { const a0=$tailArgs[0],a1=$tailArgs[1]; $tailArgs[0]=$tailArgs[1]=undefined; return f(a0,a1); }\ncase 3: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=undefined; return f(a0,a1,a2); }\ncase 4: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=undefined; return f(a0,a1,a2,a3); }\ncase 5: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=undefined; return f(a0,a1,a2,a3,a4); }\ncase 6: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=undefined; return f(a0,a1,a2,a3,a4,a5); }\ncase 7: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=undefined; return f(a0,a1,a2,a3,a4,a5,a6); }\ncase 8: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7); }\ncase 9: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8); }\ncase 10: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9); }\ncase 11: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10); }\ncase 12: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11); }\ncase 13: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12); }\ncase 14: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13); }\ncase 15: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14); }\ncase 16: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15); }\ncase 17: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16); }\ncase 18: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17); }\ncase 19: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18); }\ncase 20: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19); }\ncase 21: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20); }\ncase 22: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21); }\ncase 23: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22); }\ncase 24: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23); }\ncase 25: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24); }\ncase 26: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25); }\ncase 27: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26); }\ncase 28: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27); }\ncase 29: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28); }\ncase 30: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29); }\ncase 31: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30); }\ncase 32: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30],a31=$tailArgs[31]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=$tailArgs[31]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31); }\ndefault: throw \"bend: invalid private tail frame\";\n} }\nfunction run_force(x,raw) { return raw===$BEND_TAIL?x:run_loop(x); }\nfunction run_many(f,a,d=$td) { return d<64?f(...a,d+1):tail_many(f,a); }\nfunction run_tail(f,x) { const j=f[$BEND_TAIL]; return j ? tail_unary(j,x) : f(x); }\nfunction run_clo(j) { j[$BEND_TAIL]=j; return j; }\nfunction nat_chk(x) { if(x>281474976710655) throw \"bend: a Nat past the largest immediate 2^48-1\"; return x; }\nfunction char_new(x) { if(x>0x10ffff || (x>=0xd800 && x<=0xdfff)) throw \"bend: \"+x+\" is not a Unicode scalar value\"; return String.fromCodePoint(x); }\nfunction cmp_new(a,b) { return {$:a<b?\"LT\":a===b?\"EQ\":\"GT\"}; }\nfunction word_to_u32(w) { let x=0; for(let i=0;w.$===\"WCon\";i++,w=w.tail) if(w.head)x|=1<<i; return x>>>0; }\nfunction u32_to_word(x) { let w={$:\"WNil\"}; for(let i=31;i>=0;i--) w={$:\"WCon\",head:!!((x>>>i)&1),tail:w}; return w; }\nfunction run_named1(f,a0,d) { return d<64?f(a0,d+1):($tailArgs[0]=a0,tail_named(f,1)); }\nfunction run_named2(f,a0,a1,d) { return d<64?f(a0,a1,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,tail_named(f,2)); }\nfunction run_named3(f,a0,a1,a2,d) { return d<64?f(a0,a1,a2,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,tail_named(f,3)); }\nfunction run_named4(f,a0,a1,a2,a3,d) { return d<64?f(a0,a1,a2,a3,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,tail_named(f,4)); }\nfunction run_named5(f,a0,a1,a2,a3,a4,d) { return d<64?f(a0,a1,a2,a3,a4,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,tail_named(f,5)); }\nfunction run_named6(f,a0,a1,a2,a3,a4,a5,d) { return d<64?f(a0,a1,a2,a3,a4,a5,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,tail_named(f,6)); }\nfunction run_named7(f,a0,a1,a2,a3,a4,a5,a6,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,tail_named(f,7)); }\nfunction run_named8(f,a0,a1,a2,a3,a4,a5,a6,a7,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,tail_named(f,8)); }\nfunction run_named9(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,tail_named(f,9)); }\nfunction run_named10(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,tail_named(f,10)); }\nfunction run_named11(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,tail_named(f,11)); }\nfunction run_named12(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,tail_named(f,12)); }\nfunction run_named13(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,tail_named(f,13)); }\nfunction run_named14(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,tail_named(f,14)); }\nfunction run_named15(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,tail_named(f,15)); }\nfunction run_named16(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,tail_named(f,16)); }\nfunction run_named17(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,tail_named(f,17)); }\nfunction run_named18(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,tail_named(f,18)); }\nfunction run_named19(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,tail_named(f,19)); }\nfunction run_named20(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,tail_named(f,20)); }\nfunction run_named21(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,tail_named(f,21)); }\nfunction run_named22(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,tail_named(f,22)); }\nfunction run_named23(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,tail_named(f,23)); }\nfunction run_named24(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,tail_named(f,24)); }\nfunction run_named25(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,tail_named(f,25)); }\nfunction run_named26(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,tail_named(f,26)); }\nfunction run_named27(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,tail_named(f,27)); }\nfunction run_named28(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,tail_named(f,28)); }\nfunction run_named29(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,tail_named(f,29)); }\nfunction run_named30(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,tail_named(f,30)); }\nfunction run_named31(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,tail_named(f,31)); }\nfunction run_named32(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,$tailArgs[31]=a31,tail_named(f,32)); }\n"

def cps_provider_3_js_runtime_extra() -> String:
  "function f32_from_bits(x) { return new Float32Array(new Uint32Array([x]).buffer)[0]; }\nfunction f32_bits(x) { return new Uint32Array(new Float32Array([x]).buffer)[0]; }\nfunction tuple(a,b) { return {$:\"Tuple\",fst:a,snd:b}; }\nfunction f32_show(x) { if(x!==x) return \"nan\"; if(!Number.isFinite(x)||Object.is(x,-0)) return x<0?\"-inf\":x===0?\"-0\":\"inf\"; let s=\"x\"; for(let p=1;p<=9&&Math.fround(Number(s))!==x;p++) s=String(Number(x.toExponential(p-1))); return s; }\nfunction f32_read(s) { const re=/^\\s*[+-]?((\\d+\\.?\\d*|\\.\\d+)(e[+-]?\\d+)?|inf(inity)?|nan)$/i; const v=Number(s.replace(/inf\\w*/i,\"Infinity\")); return re.test(s)?{$:\"Some\",value:Math.fround(v)}:{$:\"None\"}; }\nfunction nat_divmod(a,b) { return b===0?tuple(0,a):tuple(Math.trunc(a/b),a%b); }\nfunction nat_in(n) { return Number.isInteger(n)&&n>=0&&n<=9007199254740992?n:nat_chk(1/0); }\nfunction array_new(n,v) { if(n>31) throw \"bend: an array past the deepest block class 31\"; return Array(2 ** n).fill(v); }\nfunction array_node(a,b) { if(a.length!==b.length) throw \"bend: runtime fail-stop\"; return a.concat(b); }\n"

def cps_provider_3_js_runtime_array() -> String:
  "function array_swap(a,i,v) { const at=i%a.length, old=a[at]; a[at]=v; return tuple(a,old); }\nfunction $string_tail(s) { return s.slice(s.codePointAt(0)>0xFFFF?2:1); }\n"

def cps_provider_3_js_runtime_foreign() -> String:
  "const $0eff=Object.create(null);\nfunction io_emit(value) { return {$:\"Emit\",value}; }\nfunction io_eff(k,run) { if(arguments.length>2)throw new Error(\"bend: \"+k+\" takes no need: an effect that waits parks itself\"); if(k in $0eff)throw new Error(\"bend: two effects register \"+k); $0eff[k]=run; }\n"

def cps_provider_3_js_runtime_namespace() -> String:
  "function $key(k,s,a) { let p=null; for (const alias of Object.keys(a)) if(k.startsWith(alias+\".\") && (p===null || alias.length>p.length)) p=alias; const n=p===null?undefined:a[p]; return n===undefined?(s?s+\".\"+k:k):(n?n+\".\":\"\")+k.slice(p.length+1); }\nfunction $resolve(k,s,a) { const q=$key(k,s,a); return $D[Object.hasOwn($D,q)?q:k]; }\nconst $FIELDS=Object.create(null), $PRIMITIVES=Object.create(null), $TYPE=Object.create(null), $TYPEF=Object.create(null), $PARAMS=Object.create(null);\nfunction $ctr(k,x,s,a) { const q=$key(k,s,a), key=Object.hasOwn($FIELDS,q)?q:k, fs=$FIELDS[key]; if(!fs||fs.length!==x.length)throw \"bend: unresolved constructor layout\"; const v={$:key}; for(let i=0;i<fs.length;i++){const f=fs[i];if(f!==null){if(f===\"__proto__\")Object.defineProperty(v,f,{value:x[i],enumerable:true,writable:true,configurable:true});else v[f]=x[i];}} return v; }\nfunction $project(v,k,i,s,a) { const q=$key(k,s,a),fs=$FIELDS[q]||$FIELDS[k]; if(!fs)throw \"bend: unresolved constructor layout\"; for(const f of fs)if(f!==null&&i--===0)return v[f]; throw \"bend: constructor field count mismatch\"; }\n"

def cps_provider_3_js_runtime_cli() -> String:
  "const cli_args=[];\nfunction cli(argv) { for(let i=0;i<argv.length;i++){ if(argv[i]===\"--\"){cli_args.push(...argv.slice(i+1));break;} if(argv[i]===\"--help\"){process.stdout.write(\"usage: \"+process.argv[1]+\"\\n\");process.exit(0);} if(argv[i]===\"--threads\"||argv[i]===\"--gpu\"){i++;} else cli_args.push(argv[i]); } }\n"

def cps_provider_3_js_runtime_io() -> String:
  "function io_out(fd,data) { const fs=require(\"fs\"), b=Buffer.from(data); let at=0; while(at<b.length){ try{ at+=fs.writeSync(fd,b,at,b.length-at); } catch(e){ if(e.code===\"EAGAIN\"||e.code===\"EINTR\")continue; if(e.code===\"EPIPE\"){process.on(\"SIGPIPE\",()=>{}).removeAllListeners(\"SIGPIPE\").kill(process.pid,\"SIGPIPE\");} try{fs.writeSync(2,\"bend: a short write on a standard stream\\n\");}catch(o){} process.exit(1);} } }\nfunction io_errs(message) { io_out(2,io_bytes(message+\"\\n\")); }\nfunction io_bytes(text) { return new TextEncoder().encode(text); }\nfunction io_text(b,n) { return new TextDecoder(\"utf-8\",{ignoreBOM:true}).decode(b.subarray(0,n)); }\nfunction io_list(b,n) { let xs={$:\"Nil\"}; while(n>0){ xs={$:\"Con\",head:b[--n],tail:xs}; } return xs; }\nfunction io_unlist(xs) { const b=[]; for(;xs.$===\"Con\";xs=xs.tail){ b.push(xs.head); } return b.some(x=>x>255)?null:Uint8Array.from(b); }\nfunction io_addr(host,port) { const part=host.split(\".\"); const deci=p=>/^(0|[1-9]\\d{0,2})$/.test(p)&&Number(p)<256; if(port>65535||part.length!==4||!part.every(deci))return null; const b=new Uint8Array(16); const head=io_sys().mac?[16,2]:[2,0]; b.set([...head,port>>8,port&255,...part.map(Number)]); return b; }\nfunction io_tup(...xs) { return xs.reduceRight((snd,fst)=>({$:\"Tuple\",fst,snd})); }\nfunction io_done(value) { return {$:\"Done\",value}; }\nfunction io_strerror(code) { try{ return String(io_sys().strerror(code)); } catch(o){ return \"errno \"+code; } }\nfunction io_fail(code,...rest) { const err=io_tup(code>>>0,io_strerror(code)); return {$:\"Fail\",error:io_tup(err,...rest)}; }\nfunction io_until(ms) { return performance.now()+Number(ms); }\nfunction io_late(at) { return at!==undefined&&performance.now()>=at; }\nfunction io_ready(at,r) { return at===undefined?r:{$:\"Ready\",value:r}; }\nfunction io_sys() { if(globalThis.BEND_SYS===undefined){ const ffi=require(\"bun:ffi\"), mac=process.platform===\"darwin\", err=mac?\"__error\":\"__errno_location\", sel=mac?\"select$DARWIN_EXTSN\":\"select\", T={i:\"i32\",u:\"u32\",U:\"u64\",I:\"i64\",p:\"ptr\",c:\"cstring\"}, vari=mac&&process.arch===\"arm64\", lib=ffi.dlopen(mac?\"libSystem.dylib\":\"libc.so.6\",Object.fromEntries((\"socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I sendto:ipUipu>I recvfrom:ipUipp>I close:i>i setsockopt:iiipu>i \"+sel+\":ipppp>i\"+(vari?\" fcntl:iiiiiiiii>i\":\" fcntl:iii>i\")+\" getsockopt:iiipp>i strerror:i>c \"+err+\":>p\").split(\" \").map(s=>{const [name,args,ret]=s.split(/[:>]/);return [name,{args:[...args].map(a=>T[a]),returns:T[ret]}]}))).symbols; const fcntl=(fd,cmd,arg)=>vari?lib.fcntl(fd,cmd,0,0,0,0,0,0,arg):lib.fcntl(fd,cmd,arg); globalThis.BEND_SYS={...lib,fcntl,select:lib[sel],ptr:ffi.ptr,mac,errno:()=>ffi.read.i32(lib[err](),0)}; } return globalThis.BEND_SYS; }\nfunction io_push(fun,arg,fresh) { const io=globalThis.BEND_IO; io.runs.push({fun,arg}); io.live+=fresh?1:0; }\nfunction io_park_on(fd,out,k,more,at) { const ws=globalThis.BEND_IO.waits; const i=ws.findLastIndex(w=>(w.at??Infinity)<=(at??Infinity)); ws.splice(i+1,0,{fd,out,k,more,at}); }\nfunction io_wait(io,block) { const soon=io.waits[0]?.at??Infinity; const ms=!block?0:soon===Infinity?-1:Math.max(0,Math.ceil(soon-performance.now())); const fds=io.waits.filter(w=>w.fd!==undefined); const top=fds.reduce((m,w)=>Math.max(m,w.fd),0); const len=(top>>6<<3)+8; const set=new Uint8Array(2*len); const at=w=>(w.out?len:0)+(w.fd>>3); for(const w of fds)set[at(w)]|=1<<(w.fd&7); const tv=new BigInt64Array([BigInt(ms/1000|0),BigInt(ms%1000*1000)]); const sys=io_sys(); if(sys.select(top+1,sys.ptr(set),sys.ptr(set,len),null,ms<0?null:sys.ptr(tv))<0){ if(sys.errno()!==4){ throw \"bend: the poller failed\"; } set.fill(0); } const now=performance.now(); const due=w=>w.at<=now||w.fd!==undefined&&set[at(w)]&1<<(w.fd&7); const todo=io.waits; io.waits=todo.filter(w=>!due(w)); for(const w of todo.filter(due)){ const x=w.more(); if(x!==undefined)io_push(w.k,x,false); } }\nfunction io_run(m) { const io={runs:[],live:0,waits:[]}; globalThis.BEND_IO=io; try{ io_push(run_loop(m()),x=>({$:\"Emit\",value:x}),true); let look=0; for(let n=0;;n+=1){ if(io.runs.length===0){ if(io.live===0)return 0; if(io.waits.length===0){ io_errs(\"bend: deadlock: every computation waits on a channel\"); return 1; } io_wait(io,true); continue; } if((n&63)===0&&io.waits.length>0){ const now=performance.now(); if(now>=look||io.waits[0].at<=now){ look=now+10; io_wait(io,false); } } const s=io.runs.shift(); let op=s.fun(s.arg); while(op!==undefined){ if(op.$===\"Emit\"){ io.live-=1; break; } if(op.$===\"Halt\"||op.$===\"Exit\"){ if(op.$===\"Halt\")io_errs(op.message); if(op.code>255){ io_errs(\"bend: exit code must be in 0..255\"); return 1; } return op.code; } const run=$0eff[op.$]; if(run===undefined){ throw \"bend: no effect registers \"+op.$; } const x=run(...op.args,op.kont); if(x===undefined)break; op=op.kont(x); } } }catch(e){ throw e instanceof RangeError?\"bend: memory fault (machine stack overflow?)\":e; } }\nfunction io_exit(main,type) { try{ if(type&&type.name===\"IO\")return io_run(main); io_out(1,io_bytes($show_value(type,run_loop(main()),0)+\"\\n\")); return 0; }catch(e){ io_errs(String(e)); return 1; } }\n"

def cps_provider_3_js_runtime_show() -> String:
  String.append(cps_provider_3_js_runtime_type, "function $show_chr(x,q) { const c=[...x][0]||\"\\0\", n=c.codePointAt(0), k=({10:\"n\",9:\"t\",13:\"r\",0:\"0\",92:\"\\\\\"})[n]??(c===q?q:null); return k!==null?\"\\\\\"+k:n<32||n===127?\"\\\\u{\"+n.toString(16)+\"}\":c; }\nfunction $show_list(t,x) { const xs=[]; while(x&&x.$===\"Con\") { const fs=t.arms.Con; if(!fs||!Object.hasOwn(x,\"head\")||!Object.hasOwn(x,\"tail\")) throw \"bend: malformed List.Con\"; xs.push($show_value($type(fs.types[0],t.args),x.head,0)); const next=$type(fs.types[1],t.args.concat([x.head])); x=x.tail; t=next; } if(!x||x.$!==\"Nil\") throw \"bend: malformed List.Nil\"; return \"[\"+xs.join(\", \")+\"]\"; }\nfunction $show_fields(t,x,chain) { const fs=t.arms[x.$]; if(!fs) throw \"bend: constructor absent from result datatype\"; const out=[],env=t.args.slice(); let at=0; for(let j=0;j<fs.types.length;j++) { if(fs.q[j]===0) { env.push(null); continue; } const name=fs.fields[j]; if(!Object.hasOwn(x,name))throw \"bend: constructor field count mismatch\"; const v=x[name]; at++; out.push($show_value($type(fs.types[j],env),v,chain&&at===2?\"(\":0)); env.push(v); } return out.join(\", \"); }\nfunction $show_value(t,x,chain) { if(!t) return String(x); if(t.k===\"U\") return String(x); if(t.k===\"F\") { const s=f32_show(x); return s.replace(/^-?\\d+(?=e|$)/i,\"$&.0\"); } if(t.k===\"N\") return x+\"n\"; if(t.k===\"C\") return \"'\"+$show_chr(x,\"'\")+\"'\"; if(t.k===\"S\") return \"\\\"\"+[...x].map(c=>$show_chr(c,\"\\\"\")).join(\"\")+\"\\\"\"; if(t.k===\"E\") return \"{==}\"; if(t.k===\"A\") return \"[\"+x.map(v=>$show_value(t.e,v,0)).join(\", \")+\"]\"; if(typeof x===\"boolean\") return x?\"True{}\":\"False{}\"; if(!x||typeof x!==\"object\"||!x.$) return String(x); if(t.native===\"List\") return $show_list(t,x); if(t.native===\"Sigma\"&&x.$===\"Tuple\") { const c=chain===\"(\"; return (c?\"\":\"(\")+$show_fields(t,x,true)+(c?\"\":\")\"); } if(t.k!==\"D\") throw \"bend: expected a datatype result\"; return x.$+\"{\"+$show_fields(t,x,false)+\"}\"; }\n")

def cps_provider_3_js_runtime_type() -> String:
  String.append(cps_provider_3_js_runtime_native_type, String.append(cps_provider_3_js_runtime_type_names, String.append(cps_provider_3_js_runtime_type_patterns, cps_provider_3_js_runtime_type_eval)))

def cps_provider_3_js_runtime_type_names() -> String:
  "function $type_key(k,s,i) { const q=$key(k,s,i||{}); return $TYPE[q]!==undefined||$TYPEF[q]!==undefined?q:k; }\nfunction $type_ctor_key(k,s,i) { const q=$key(k,s,i||{}); return $FIELDS[q]!==undefined?q:k; }\nfunction $type_delay(t,a) { if(t.k)return t; if(t.p!==undefined&&a[a.length-1-t.p]!==undefined)return a[a.length-1-t.p]; return {k:\"Thunk\",term:t,env:a,depth:a.length,done:false}; }\nfunction $type_force(v) { if(v&&v.k===\"Thunk\") { if(!v.done) { v.value=$type(v.term,v.env.length===v.depth?v.env:v.env.slice(0,v.depth)); v.done=true; } return v.value; } return v; }\nfunction $type_apply(f,x) { f=$type_force(f); if(f.k===\"L\") return $type(f.body,f.env.concat([x])); if(f.k===\"TF\"||f.k===\"DF\") return $type_named(f.key,f.args.concat([x])); throw \"bend: type expression applied a non-function\"; }\nfunction $type_named(q,ps) { const f=$TYPEF[q]; if(f) { if(ps.length<f.n)return {k:\"TF\",key:q,args:ps}; let v=f.intrinsic?$type_native_invoke(f,ps):$type(f.body,ps.length===f.n?ps:ps.slice(0,f.n)); for(let i=f.n;i<ps.length;i++)v=$type_apply(v,ps[i]); if(f.native===\"IO\")v.name=\"IO\"; return v; } const d=$TYPE[q]; if(!d) throw \"bend: unresolved type expression \"+q; const p=$PARAMS[q]; if(ps.length<p.n)return {k:\"DF\",key:q,args:ps}; if(ps.length!==p.n)throw \"bend: datatype parameter count mismatch\"; if(d.native===\"Array\") return {k:\"A\",e:$type_force(ps[0])}; const k=({U32:\"U\",F32:\"F\",Nat:\"N\",Char:\"C\",String:\"S\",Eql:\"E\"})[d.native]; return k?{k}:{k:\"D\",key:q,name:d.name,native:d.native,arms:d.arms,args:ps}; }\n"

def cps_provider_3_js_runtime_type_patterns() -> String:
  "function $type_sugar(t,a) { const h=$type(t.sugar,a),more=t.a.map(x=>$type_delay(x,a)); if(h.k===\"TF\"||h.k===\"DF\"||h.k===\"D\") { const q=h.key,p=$PARAMS[q]; let xs=h.args.concat(more); if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:t.f})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs); } let v=h; for(const x of more)v=$type_apply(v,x); return v; }\nfunction $type_pattern(p,v,bindings) { if(p.v) { bindings.push(v); return true; } v=$type_force(v); const q=$type_ctor_key(p.c,p.s,p.i),c=$PRIMITIVES[q]||($FIELDS[q]===undefined?q:\"\"); let fields,complete=false; if(v&&v.k===\"V\") { if(v.c!==q)return false; fields=v.args; complete=true; } else if(v&&v.$===q) { const names=$FIELDS[q]; if(!names||names.length!==p.fields.length)return false; for(let j=0;j<names.length;j++){if(names[j]===null){bindings.push(null);continue;}if(!$type_pattern(p.fields[j],v[names[j]],bindings))return false;}return true; } else if(c===\"Bool.True\"&&v===true||c===\"Bool.False\"&&v===false||c===\"Nat.Zero\"&&v===0||c===\"String.SNil\"&&v===\"\") fields=[]; else if(c===\"Nat.Succ\"&&typeof v===\"number\"&&v>0)fields=[v-1]; else if(c===\"String.SCon\"&&typeof v===\"string\"&&v.length)fields=[String.fromCodePoint(v.codePointAt(0)),v.slice(v.codePointAt(0)>0xFFFF?2:1)]; else if(c===\"Char.Chr\"&&typeof v===\"string\")fields=[v.codePointAt(0)]; else if(c===\"U32.U32\"&&typeof v===\"number\")fields=[u32_to_word(v)]; else if(c===\"F32.F32\"&&typeof v===\"number\")fields=[u32_to_word(f32_bits(v))]; else if(c===\"Array.ALeaf\"&&Array.isArray(v)&&v.length===1)fields=[v[0]]; else if(c===\"Array.ANode\"&&Array.isArray(v)&&v.length!==1)fields=[v.slice(0,v.length>>1),v.slice(v.length>>1)]; else return false; let at=0; for(const field of p.fields) { if(!complete&&field.v&&field.q===0) { bindings.push(null); continue; } if(at>=fields.length||!$type_pattern(field,fields[at++],bindings))return false; } return at===fields.length; }\nfunction $type_bind(patterns,values) { if(patterns.length!==values.length)return null; const bindings=[]; for(let j=0;j<values.length;j++)if(!$type_pattern(patterns[j],values[j],bindings))return null; return bindings; }\n"

def cps_provider_3_js_runtime_type_eval() -> String:
  "function $type(t,a=[]) { if(t===null)return null; if(t===undefined)throw \"bend: missing type expression\"; if(t.p!==undefined) { const v=$type_force(a[a.length-1-t.p]); if(v===undefined||v===null)throw \"bend: unavailable type-expression binder\"; return v; } if(t.k)return $type_force(t); if(t.fail)throw t.fail; if(t.kind!==undefined)return {k:\"K\",q:$type(t.kind,a)}; if(t.min!==undefined)return {k:\"Q\",v:Math.min($type(t.min,a).v,$type(t.right,a).v)}; if(t.all!==undefined)return {k:\"Fn\",q:t.q,domain:$type(t.all,a),body:t.body,env:a}; if(t.lam!==undefined)return {k:\"L\",body:t.lam,env:a}; if(t.app!==undefined)return $type_apply($type(t.app,a),$type_delay(t.arg,a)); if(t.sub!==undefined) { const env=a.slice(); env.splice(env.length-t.sub,0,$type_delay(t.value,a)); return $type(t.body,env); } if(t.let!==undefined)return $type(t.body,a.concat(t.let.map(x=>$type_delay(x,a)))); if(t.local!==undefined) { const bs=$type_bind(t.pat,t.local.map(x=>$type_delay(x,a))); if(bs===null)throw \"bend: type expression local pattern failed\"; return $type(t.body,a.concat(bs)); } if(t.bind!==undefined)return $type(t.body,a.concat([$type_delay(t.bind,a)])); if(t.match!==undefined) { const vs=t.match.map(x=>$type_delay(x,a)); for(const c of t.cases) { const bs=$type_bind(c.pat,vs); if(bs!==null)return $type(c.body,a.concat(bs)); } throw \"bend: type expression match failed\"; } if(t.c!==undefined)return {k:\"V\",c:$type_ctor_key(t.c,t.s,t.i),args:t.a.map(x=>$type_delay(x,a))}; if(t.sugar!==undefined)return $type_sugar(t,a); if(t.f) { const q=$type_key(t.r,t.s,t.i),p=$PARAMS[q]; if(!p&&t.f===2)return $type(t.h,a); let xs=t.a||[]; if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:1})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs.map(x=>$type_delay(x,a))); } if(t.r!==undefined)return $type_named($type_key(t.r,t.s,t.i),(t.a||[]).map(x=>$type_delay(x,a))); throw \"bend: unsupported type-expression descriptor\"; }\n"

def cps_provider_3_js_runtime_native_type() -> String:
  "function $type_native_invoke(f,ps) { let value=f.intrinsic; for(let i=0;i<f.n;i++)if(f.q[i]!==0)value=value($type_runtime_value(ps[i])); return value; }\nfunction $type_runtime_value(value) { const v=$type_force(value); if(!v||v.k!==\"V\")return v; const c=$PRIMITIVES[v.c]||($FIELDS[v.c]===undefined?v.c:\"\"),xs=v.args; switch(c) { case \"Nat.Zero\":return 0; case \"Nat.Succ\":return nat_chk($type_runtime_value(xs[0])+1); case \"Bool.False\":return false; case \"Bool.True\":return true; case \"String.SNil\":return \"\"; case \"String.SCon\":return $type_runtime_value(xs[0])+$type_runtime_value(xs[1]); case \"Char.Chr\":return char_new($type_runtime_value(xs[0])); case \"U32.U32\":return word_to_u32($type_runtime_value(xs[0])); case \"F32.F32\":return f32_from_bits(word_to_u32($type_runtime_value(xs[0]))); case \"Array.ALeaf\":return [$type_runtime_value(xs[0])]; case \"Array.ANode\":return $type_runtime_value(xs[0]).concat($type_runtime_value(xs[1])); } const fs=$FIELDS[v.c]; if(!fs||fs.length!==xs.length)throw \"bend: unresolved metadata constructor\"; const args=xs.map((x,i)=>fs[i]===null?null:$type_runtime_value(x)); return $ctr(v.c,args,\"\",{}); }\n"

def cps_provider_3_js_main(v_1: String) -> String:
  String.append("if (typeof process !== \"undefined\" && process.argv[1] && /\\.js$/.test(process.argv[1])) { cli(process.argv.slice(2)); if(Object.hasOwn($D,\"main\")) { process.exitCode=io_exit(()=>$D[\"main\"],$type(", String.append(v_1, ")); } }\n"))

def cps_provider_4_qualify(+v_1: String, v_3: String) -> String:
  Scope.canonical_key(v_1, v_3, String.eq(v_1, ""))

def cps_provider_4_symbol_key(v_0: IR.Symbol) -> String:
  match v_0:
    case IR.Symbol{v_6, v_7, _, _}:
      cps_provider_4_qualify(v_6, v_7)

def cps_provider_4_quantity(v_0: Ast.Quantity) -> BIR.Quantity:
  match v_0:
    case Ast.QZero{}:
      BIR.Erased{}
    case Ast.QOne{}:
      BIR.Once{}
    case Ast.QMany{}:
      BIR.Unrestricted{}

def cps_provider_4_optional_quantity(v_1: Maybe<&2, Ast.Quantity>) -> Maybe<&2, BIR.Quantity>:
  match v_1:
    case None{}:
      None{}
    case Some{v_4}:
      Some{cps_provider_4_quantity(v_4)}

def cps_provider_4_parameter(v_1: U32, v_2: BIR.Quantity, v_4: List<&2, BIR.Parameter>) -> List<&2, BIR.Parameter>:
  match v_2:
    case BIR.Erased{}:
      v_4
    case BIR.Once{}:
      BIR.Parameter{v_1, BIR.Affine{}} <> v_4
    case BIR.Unrestricted{}:
      BIR.Parameter{v_1, BIR.Many{}} <> v_4

def cps_provider_4_field_key(v_1: String, v_2: BIR.Quantity) -> Maybe<&2, String>:
  match v_2:
    case BIR.Erased{}:
      None{}
    case _:
      Some{v_1}

def cps_provider_4_canonical(v_1: String, v_2: Scope.ArenaGlobalScope, v_4: Bool) -> String:
  match v_4:
    case True{}:
      Scope.canonical_name_result(v_1, Scope.lookup_kind(v_1, Scope.GlobalConstructor{}, v_2))
    case False{}:
      Scope.canonical_name(v_1, v_2)

def cps_provider_4_native_match_descriptor_0(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_4: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_3:
    case (v_8, v_9):
      cps_provider_4_descriptor_node(v_8, v_9, v_4)

def cps_provider_4_descriptor(v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  cps_provider_4_native_match_descriptor_0(Arena.get_node(v_0, v_2), v_3)

def cps_provider_4_native_match_descriptor_name_0(v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_5: Scope.ArenaGlobalScope, v_7: Bool) -> cps_provider_4_CatalogResult<String>:
  match v_4:
    case (v_12, v_13):
      cps_provider_4_CatalogResult{v_12, cps_provider_4_canonical(v_13, v_5, v_7)}

def cps_provider_4_descriptor_name(v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope, v_5: Bool) -> cps_provider_4_CatalogResult<String>:
  cps_provider_4_native_match_descriptor_name_0(Arena.name_text(v_0, v_2), v_3, v_5)

def cps_provider_4_native_match_descriptors_0(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_3: BIR.Descriptor) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_2:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, v_3 <> v_9}

def cps_provider_4_native_match_descriptors_1(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptors_0(cps_provider_4_descriptors(v_11, IR.arena_range_index(v_3, 1), U32.sub(v_5, 1), v_6), v_12)

def cps_provider_4_native_match_descriptors_2(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_4:
    case (v_14, v_15):
      cps_provider_4_native_match_descriptors_1(cps_provider_4_descriptor(v_14, v_15, v_9), v_6, v_8, v_9)

def cps_provider_4_native_match_descriptors_3(v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case 0:
      cps_provider_4_CatalogResult{v_2, []}
    case _:
      cps_provider_4_native_match_descriptors_2(Arena.word(v_2, IR.arena_tape_offset(v_4)), v_4, v_1, v_5)

def cps_provider_4_descriptors(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  cps_provider_4_native_match_descriptors_3(v_4, v_0, v_2, v_5)

def cps_provider_4_native_match_descriptor_patterns_0(v_2: cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_3: BIR.DescriptorPattern) -> cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_2:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, v_3 <> v_9}

def cps_provider_4_native_match_descriptor_patterns_1(v_1: cps_provider_4_CatalogResult<BIR.DescriptorPattern>, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_1:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptor_patterns_0(cps_provider_4_descriptor_patterns(v_11, IR.arena_range_index(v_3, 1), U32.sub(v_5, 1), v_6), v_12)

def cps_provider_4_native_match_descriptor_patterns_2(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Pattern>, v_5: U32, v_7: U32, v_8: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_3:
    case (v_13, v_14):
      cps_provider_4_native_match_descriptor_patterns_1(cps_provider_4_descriptor_pattern(v_13, v_14, v_8), v_5, v_7, v_8)

def cps_provider_4_native_match_descriptor_patterns_3(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_4:
    case (v_14, v_15):
      cps_provider_4_native_match_descriptor_patterns_2(Arena.get_pattern(v_14, v_15), v_6, v_8, v_9)

def cps_provider_4_native_match_descriptor_patterns_4(v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_1:
    case 0:
      cps_provider_4_CatalogResult{v_2, []}
    case _:
      cps_provider_4_native_match_descriptor_patterns_3(Arena.word(v_2, IR.arena_tape_offset(v_4)), v_4, v_1, v_5)

def cps_provider_4_descriptor_patterns(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>:
  cps_provider_4_native_match_descriptor_patterns_4(v_4, v_0, v_2, v_5)

def cps_provider_4_native_match_descriptor_pattern_0(v_2: cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_4: String) -> cps_provider_4_CatalogResult<BIR.DescriptorPattern>:
  match v_2:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, BIR.DescriptorConstructorPattern{v_4, v_9}}

def cps_provider_4_native_match_descriptor_pattern_1(v_2: cps_provider_4_CatalogResult<String>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32) -> cps_provider_4_CatalogResult<BIR.DescriptorPattern>:
  match v_2:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptor_pattern_0(cps_provider_4_descriptor_patterns(v_11, v_5, v_7, v_3), v_12)

def cps_provider_4_native_match_descriptor_pattern_2(v_0: Arena.Pattern, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.DescriptorPattern>:
  match v_0:
    case Arena.PatternVar{_, _, v_10, _}:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorBinder{cps_provider_4_quantity(v_10)}}
    case Arena.PatternCtr{v_17, v_18, v_19, _}:
      cps_provider_4_native_match_descriptor_pattern_1(cps_provider_4_descriptor_name(v_1, v_17, v_2, True{}), v_2, v_18, v_19)

def cps_provider_4_descriptor_pattern(v_0: Arena.Arena, v_1: Arena.Pattern, v_2: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.DescriptorPattern>:
  cps_provider_4_native_match_descriptor_pattern_2(v_1, v_0, v_2)

def cps_provider_4_descriptor_apply(v_0: BIR.Descriptor, v_1: BIR.Descriptor) -> BIR.Descriptor:
  match v_0:
    case BIR.DescriptorRef{v_4, v_5}:
      BIR.DescriptorRef{v_4, List.append(&2, BIR.Descriptor, v_5, [v_1])}
    case _:
      BIR.DescriptorApplication{v_0, v_1}

def cps_provider_4_native_match_descriptor_sugar_0(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_12, v_13}:
      cps_provider_4_descriptor_sugar(v_12, v_8, v_13 <> v_3, v_5, v_6)

def cps_provider_4_native_match_descriptor_sugar_1(v_2: cps_provider_4_CatalogResult<String>, v_4: List<&2, BIR.Descriptor>, v_6: Bool) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_10, v_11}:
      cps_provider_4_CatalogResult{v_10, cps_provider_4_named_sugar(v_11, BIR.DescriptorRef{v_11, []}, v_4, v_6)}

def cps_provider_4_native_match_descriptor_sugar_2(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_8: String) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_12, v_13}:
      cps_provider_4_CatalogResult{v_12, cps_provider_4_named_sugar(v_8, BIR.DescriptorRef{v_8, v_13}, List.append(&2, BIR.Descriptor, v_13, v_4), v_6)}

def cps_provider_4_native_match_descriptor_sugar_3(v_2: cps_provider_4_CatalogResult<String>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope, v_9: U32, v_11: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_15, v_16}:
      cps_provider_4_native_match_descriptor_sugar_2(cps_provider_4_descriptors(v_15, v_9, v_11, v_7), v_4, v_6, v_16)

def cps_provider_4_native_match_descriptor_sugar_4(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>, v_5: Bool) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_CatalogResult{v_9, cps_provider_4_unnamed_sugar(v_10, v_3, v_5)}

def cps_provider_4_native_match_descriptor_sugar_5(v_0: Arena.Node, v_2: List<&2, BIR.Descriptor>, v_4: Bool, v_5: Scope.ArenaGlobalScope, v_6: Arena.Arena) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_0:
    case Arena.TermAnn{v_11, _, _}:
      cps_provider_4_descriptor_sugar(v_6, v_11, v_2, v_4, v_5)
    case Arena.TermBang{v_17, _}:
      cps_provider_4_descriptor_sugar(v_6, v_17, v_2, v_4, v_5)
    case Arena.TermApp{v_23, v_24, _}:
      cps_provider_4_native_match_descriptor_sugar_0(cps_provider_4_descriptor(v_6, v_24, v_5), v_2, v_4, v_5, v_23)
    case Arena.TermRef{v_30, _}:
      cps_provider_4_native_match_descriptor_sugar_1(cps_provider_4_descriptor_name(v_6, v_30, v_5, False{}), v_2, v_4)
    case Arena.TermAdt{v_40, v_41, v_42, _, _, _}:
      cps_provider_4_native_match_descriptor_sugar_3(cps_provider_4_descriptor_name(v_6, v_40, v_5, False{}), v_2, v_4, v_5, v_41, v_42)
    case _:
      cps_provider_4_native_match_descriptor_sugar_4(cps_provider_4_descriptor_node(v_6, v_0, v_5), v_2, v_4)

def cps_provider_4_native_match_descriptor_sugar_6(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_5: List<&2, BIR.Descriptor>, v_7: Bool, v_8: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_3:
    case (v_12, v_13):
      cps_provider_4_native_match_descriptor_sugar_5(v_13, v_5, v_7, v_8, v_12)

def cps_provider_4_descriptor_sugar(v_0: Arena.Arena, v_2: U32, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  cps_provider_4_native_match_descriptor_sugar_6(Arena.get_node(v_0, v_2), v_4, v_6, v_7)

def cps_provider_4_named_sugar(v_1: String, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, v_6: Bool) -> BIR.Descriptor:
  match v_6:
    case False{}:
      BIR.DescriptorNamedFill{v_1, v_2, v_4}
    case True{}:
      BIR.DescriptorNamedPlus{v_1, v_2, v_4}

def cps_provider_4_unnamed_sugar(v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>, v_4: Bool) -> BIR.Descriptor:
  match v_4:
    case False{}:
      BIR.DescriptorFill{v_0, v_2}
    case True{}:
      BIR.DescriptorPlus{v_0, v_2}

def cps_provider_4_string_names(v_0: Ast.StringLiteralNames, v_1: Scope.ArenaGlobalScope) -> Ast.StringLiteralNames:
  match v_0:
    case Ast.StringLiteralNames{v_10, v_11, v_12, v_13, v_14, v_15, v_16, v_17}:
      Ast.StringLiteralNames{cps_provider_4_canonical(v_10, v_1, True{}), cps_provider_4_canonical(v_11, v_1, True{}), cps_provider_4_canonical(v_12, v_1, True{}), cps_provider_4_canonical(v_13, v_1, True{}), cps_provider_4_canonical(v_14, v_1, True{}), cps_provider_4_canonical(v_15, v_1, True{}), cps_provider_4_canonical(v_16, v_1, True{}), cps_provider_4_canonical(v_17, v_1, True{})}

def cps_provider_4_string_bit(v_1: U32, v_2: Ast.StringLiteralNames) -> BIR.Descriptor:
  match v_1, v_2:
    case 0, Ast.StringLiteralNames{_, _, _, _, _, _, v_17, _}:
      BIR.DescriptorConstructor{v_17, []}
    case _, Ast.StringLiteralNames{_, _, _, _, _, _, _, v_36}:
      BIR.DescriptorConstructor{v_36, []}

def cps_provider_4_string_word(v_1: Nat, v_3: U32, v_4: Ast.StringLiteralNames) -> BIR.Descriptor:
  match v_1, v_4:
    case 0n, Ast.StringLiteralNames{_, _, _, _, v_17, _, _, _}:
      BIR.DescriptorConstructor{v_17, []}
    case 1n+v_30, Ast.StringLiteralNames{_, _, _, _, _, v_36, _, _}:
      BIR.DescriptorConstructor{v_36, [cps_provider_4_string_bit(U32.and(v_3, 1), v_4), cps_provider_4_string_word(v_30, U32.shr(v_3), v_4)]}

def cps_provider_4_string_descriptor(v_2: List<&2, U32>, v_3: Ast.StringLiteralNames) -> BIR.Descriptor:
  match v_2, v_3:
    case [], Ast.StringLiteralNames{v_12, _, _, _, _, _, _, _}:
      BIR.DescriptorConstructor{v_12, []}
    case v_30 <> v_31, Ast.StringLiteralNames{_, v_33, v_34, v_35, _, _, _, _}:
      BIR.DescriptorConstructor{v_33, [BIR.DescriptorConstructor{v_34, [BIR.DescriptorConstructor{v_35, [cps_provider_4_string_word(32n, v_30, v_3)]}]}, cps_provider_4_string_descriptor(v_31, v_3)]}

def cps_provider_4_native_match_descriptor_node_0(v_2: cps_provider_4_CatalogResult<String>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_6, v_7}:
      cps_provider_4_CatalogResult{v_6, BIR.DescriptorRef{v_7, []}}

def cps_provider_4_native_match_descriptor_node_1(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: Nat, v_4: BIR.Descriptor) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, BIR.DescriptorSubstitution{v_3, v_4, v_9}}

def cps_provider_4_native_match_descriptor_node_2(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: Nat, v_6: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_10, v_11}:
      cps_provider_4_native_match_descriptor_node_1(cps_provider_4_descriptor(v_10, v_6, v_2), v_4, v_11)

def cps_provider_4_native_match_descriptor_node_3(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_7, v_8}:
      cps_provider_4_CatalogResult{v_7, BIR.DescriptorLet{v_3, v_8}}

def cps_provider_4_native_match_descriptor_node_4(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_native_match_descriptor_node_3(cps_provider_4_descriptor(v_9, v_5, v_3), v_10)

def cps_provider_4_native_match_descriptor_node_5(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_5, v_6}:
      cps_provider_4_CatalogResult{v_5, BIR.DescriptorKind{v_6}}

def cps_provider_4_native_match_descriptor_node_6(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_6, v_7}:
      cps_provider_4_CatalogResult{v_6, BIR.DescriptorMinimum{v_2, v_7}}

def cps_provider_4_native_match_descriptor_node_7(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_native_match_descriptor_node_6(cps_provider_4_descriptor(v_8, v_4, v_2), v_9)

def cps_provider_4_native_match_descriptor_node_8(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Ast.Quantity, v_3: BIR.Descriptor) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_7, v_8}:
      cps_provider_4_CatalogResult{v_7, BIR.DescriptorArrow{cps_provider_4_quantity(v_2), v_3, v_8}}

def cps_provider_4_native_match_descriptor_node_9(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_3: Ast.Quantity, v_5: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_native_match_descriptor_node_8(cps_provider_4_descriptor(v_9, v_5, v_2), v_3, v_10)

def cps_provider_4_native_match_descriptor_node_10(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: Maybe<&2, Ast.Quantity>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_7, v_8}:
      cps_provider_4_CatalogResult{v_7, BIR.DescriptorLambda{cps_provider_4_optional_quantity(v_3), v_8}}

def cps_provider_4_native_match_descriptor_node_11(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_6, v_7}:
      cps_provider_4_CatalogResult{v_6, cps_provider_4_descriptor_apply(v_2, v_7)}

def cps_provider_4_native_match_descriptor_node_12(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_native_match_descriptor_node_11(cps_provider_4_descriptor(v_8, v_4, v_2), v_9)

def cps_provider_4_native_match_descriptor_node_13(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_4: String) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, BIR.DescriptorRef{v_4, v_9}}

def cps_provider_4_native_match_descriptor_node_14(v_2: cps_provider_4_CatalogResult<String>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptor_node_13(cps_provider_4_descriptors(v_11, v_5, v_7, v_3), v_12)

def cps_provider_4_native_match_descriptor_node_15(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_descriptor_sugar(v_9, v_5, v_10, False{}, v_3)

def cps_provider_4_native_match_descriptor_node_16(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_descriptor_sugar(v_9, v_5, v_10, True{}, v_3)

def cps_provider_4_native_match_descriptor_node_17(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_4: String) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, BIR.DescriptorConstructor{v_4, v_9}}

def cps_provider_4_native_match_descriptor_node_18(v_2: cps_provider_4_CatalogResult<String>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptor_node_17(cps_provider_4_descriptors(v_11, v_5, v_7, v_3), v_12)

def cps_provider_4_native_match_descriptor_node_19(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_6, v_7}:
      cps_provider_4_CatalogResult{v_6, BIR.DescriptorBind{v_2, v_7}}

def cps_provider_4_native_match_descriptor_node_20(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_native_match_descriptor_node_19(cps_provider_4_descriptor(v_8, v_4, v_2), v_9)

def cps_provider_4_native_match_descriptor_node_21(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor, v_3: BIR.Descriptor) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_7, v_8}:
      cps_provider_4_CatalogResult{v_7, BIR.DescriptorEquality{v_2, v_3, v_8}}

def cps_provider_4_native_match_descriptor_node_22(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32, v_5: BIR.Descriptor) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_native_match_descriptor_node_21(cps_provider_4_descriptor(v_9, v_4, v_2), v_5, v_10)

def cps_provider_4_native_match_descriptor_node_23(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32, v_6: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_10, v_11}:
      cps_provider_4_native_match_descriptor_node_22(cps_provider_4_descriptor(v_10, v_4, v_2), v_2, v_6, v_11)

def cps_provider_4_native_match_descriptor_node_24(v_4: Sigma<&1, &1, Arena.Arena, _ => String>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_4:
    case (v_8, v_9):
      cps_provider_4_CatalogResult{v_8, BIR.DescriptorFailure{String.append("bend: unsolved hole ", v_9)}}

def cps_provider_4_native_match_descriptor_node_25(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_4: List<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, BIR.DescriptorMatch{v_4, v_9}}

def cps_provider_4_native_match_descriptor_node_26(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptor_node_25(cps_provider_4_descriptor_cases(v_11, v_5, v_7, v_3), v_12)

def cps_provider_4_native_match_descriptor_node_27(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.DescriptorPattern>, v_5: List<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_CatalogResult{v_9, BIR.DescriptorLocal{v_3, v_5, v_10}}

def cps_provider_4_native_match_descriptor_node_28(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: List<&2, BIR.DescriptorPattern>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptor_node_27(cps_provider_4_descriptor(v_11, v_5, v_3), v_7, v_12)

def cps_provider_4_native_match_descriptor_node_29(v_2: cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32, v_9: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_native_match_descriptor_node_28(cps_provider_4_descriptors(v_13, v_5, v_7, v_3), v_3, v_9, v_14)

def cps_provider_4_native_match_descriptor_node_30(v_0: Arena.Node, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_0:
    case Arena.TermVar{_, v_8, _}:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorParameter{v_8}}
    case Arena.TermRef{v_12, _}:
      cps_provider_4_native_match_descriptor_node_0(cps_provider_4_descriptor_name(v_1, v_12, v_2, False{}))
    case Arena.TermBang{v_18, _}:
      cps_provider_4_descriptor(v_1, v_18, v_2)
    case Arena.TermSub{v_25, v_26, v_27, _}:
      cps_provider_4_native_match_descriptor_node_2(cps_provider_4_descriptor(v_1, v_26, v_2), v_2, v_25, v_27)
    case Arena.TermLet{_, _, _, _, _, _, v_47, v_48, v_49, _}:
      cps_provider_4_native_match_descriptor_node_4(cps_provider_4_descriptors(v_1, v_47, v_48, v_2), v_2, v_49)
    case Arena.TermAnn{v_56, _, _}:
      cps_provider_4_descriptor(v_1, v_56, v_2)
    case Arena.TermTemplate{_, _}:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorFailure{"bend: unexpanded template"}}
    case Arena.TermType{v_66, _}:
      cps_provider_4_native_match_descriptor_node_5(cps_provider_4_descriptor(v_1, v_66, v_2))
    case Arena.TermQuant{}:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorQuantityKind{}}
    case Arena.TermQuantity{v_72, _}:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorQuantity{cps_provider_4_quantity(v_72)}}
    case Arena.TermMin{v_78, v_79, _}:
      cps_provider_4_native_match_descriptor_node_7(cps_provider_4_descriptor(v_1, v_78, v_2), v_2, v_79)
    case Arena.TermAll{v_89, _, _, v_92, v_93, _}:
      cps_provider_4_native_match_descriptor_node_9(cps_provider_4_descriptor(v_1, v_92, v_2), v_2, v_89, v_93)
    case Arena.TermLam{v_102, _, _, v_105, _}:
      cps_provider_4_native_match_descriptor_node_10(cps_provider_4_descriptor(v_1, v_105, v_2), v_102)
    case Arena.TermApp{v_112, v_113, _}:
      cps_provider_4_native_match_descriptor_node_12(cps_provider_4_descriptor(v_1, v_112, v_2), v_2, v_113)
    case Arena.TermAdt{v_123, v_124, v_125, _, _, _}:
      cps_provider_4_native_match_descriptor_node_14(cps_provider_4_descriptor_name(v_1, v_123, v_2, False{}), v_2, v_124, v_125)
    case Arena.TermFill{v_135, v_136, v_137, _}:
      cps_provider_4_native_match_descriptor_node_15(cps_provider_4_descriptors(v_1, v_136, v_137, v_2), v_2, v_135)
    case Arena.TermPlus{v_145, v_146, v_147, _}:
      cps_provider_4_native_match_descriptor_node_16(cps_provider_4_descriptors(v_1, v_146, v_147, v_2), v_2, v_145)
    case Arena.TermCtr{v_155, v_156, v_157, _}:
      cps_provider_4_native_match_descriptor_node_18(cps_provider_4_descriptor_name(v_1, v_155, v_2, True{}), v_2, v_156, v_157)
    case Arena.TermString{v_164, v_165, _}:
      cps_provider_4_CatalogResult{v_1, cps_provider_4_string_descriptor(v_164, cps_provider_4_string_names(v_165, v_2))}
    case Arena.TermMat{_, v_174, v_175, _}:
      cps_provider_4_native_match_descriptor_node_20(cps_provider_4_descriptor(v_1, v_175, v_2), v_2, v_174)
    case Arena.TermAbsurd{_}:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorFailure{"bend: runtime fail-stop"}}
    case Arena.TermEqual{v_185, v_186, v_187, _}:
      cps_provider_4_native_match_descriptor_node_23(cps_provider_4_descriptor(v_1, v_185, v_2), v_2, v_186, v_187)
    case Arena.TermRefl{_}:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorReflexivity{}}
    case Arena.TermRewrite{_, _, v_199, _}:
      cps_provider_4_descriptor(v_1, v_199, v_2)
    case Arena.TermHole{v_204, _}:
      cps_provider_4_native_match_descriptor_node_24(Arena.name_text(v_1, v_204))
    case Arena.BodyMatch{v_212, v_213, v_214, v_215, _}:
      cps_provider_4_native_match_descriptor_node_26(cps_provider_4_descriptors(v_1, v_212, v_213, v_2), v_2, v_214, v_215)
    case Arena.BodyCase{_, _, v_225, _}:
      cps_provider_4_descriptor(v_1, v_225, v_2)
    case Arena.BodyLocal{v_235, v_236, _, v_238, v_239, v_240, _}:
      cps_provider_4_native_match_descriptor_node_29(cps_provider_4_descriptor_patterns(v_1, v_235, v_236, v_2), v_2, v_238, v_239, v_240)
    case Arena.BodyReply{v_246, _}:
      cps_provider_4_descriptor(v_1, v_246, v_2)

def cps_provider_4_descriptor_node(v_0: Arena.Arena, v_1: Arena.Node, v_2: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  cps_provider_4_native_match_descriptor_node_30(v_1, v_0, v_2)

def cps_provider_4_native_match_descriptor_cases_0(v_2: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_3: BIR.Descriptor) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_2:
    case cps_provider_4_CatalogResult{v_8, v_9}:
      cps_provider_4_CatalogResult{v_8, v_3 <> v_9}

def cps_provider_4_native_match_descriptor_cases_1(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_native_match_descriptor_cases_0(cps_provider_4_descriptor_cases(v_11, IR.arena_range_index(v_3, 1), U32.sub(v_5, 1), v_6), v_12)

def cps_provider_4_native_match_descriptor_cases_2(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_5: U32, v_7: U32, v_8: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_3:
    case (v_13, v_14):
      cps_provider_4_native_match_descriptor_cases_1(cps_provider_4_descriptor_case(v_13, v_14, v_8), v_5, v_7, v_8)

def cps_provider_4_native_match_descriptor_cases_3(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_4:
    case (v_14, v_15):
      cps_provider_4_native_match_descriptor_cases_2(Arena.get_node(v_14, v_15), v_6, v_8, v_9)

def cps_provider_4_native_match_descriptor_cases_4(v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case 0:
      cps_provider_4_CatalogResult{v_2, []}
    case _:
      cps_provider_4_native_match_descriptor_cases_3(Arena.word(v_2, IR.arena_tape_offset(v_4)), v_4, v_1, v_5)

def cps_provider_4_descriptor_cases(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  cps_provider_4_native_match_descriptor_cases_4(v_4, v_0, v_2, v_5)

def cps_provider_4_native_match_descriptor_case_0(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.DescriptorPattern>) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case cps_provider_4_CatalogResult{v_7, v_8}:
      cps_provider_4_CatalogResult{v_7, BIR.DescriptorCase{v_3, v_8}}

def cps_provider_4_native_match_descriptor_case_1(v_2: cps_provider_4_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_3: Scope.ArenaGlobalScope, v_5: U32) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_2:
    case cps_provider_4_CatalogResult{v_9, v_10}:
      cps_provider_4_native_match_descriptor_case_0(cps_provider_4_descriptor(v_9, v_5, v_3), v_10)

def cps_provider_4_native_match_descriptor_case_2(v_0: Arena.Node, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_0:
    case Arena.BodyCase{v_8, v_9, v_10, _}:
      cps_provider_4_native_match_descriptor_case_1(cps_provider_4_descriptor_patterns(v_1, v_8, v_9, v_2), v_2, v_10)
    case _:
      cps_provider_4_CatalogResult{v_1, BIR.DescriptorFailure{"bend: malformed type match"}}

def cps_provider_4_descriptor_case(v_0: Arena.Arena, v_1: Arena.Node, v_2: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  cps_provider_4_native_match_descriptor_case_2(v_1, v_0, v_2)

def cps_provider_4_native_match_telescope_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Telescope>, v_4: U32, v_5: Scope.ArenaGlobalScope, v_6: Arena.Binder) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_2:
    case cps_provider_4_CatalogResult{v_11, v_12}:
      cps_provider_4_telescope_binder(v_11, v_6, v_4, v_5, v_12)

def cps_provider_4_native_match_telescope_1(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_5: U32, v_6: Scope.ArenaGlobalScope, v_8: U32, v_10: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_3:
    case (v_15, v_16):
      cps_provider_4_native_match_telescope_0(cps_provider_4_telescope(v_15, IR.Words{IR.arena_range_index(v_8, 1), U32.sub(v_10, 1)}, U32.add(v_5, 1), v_6), v_5, v_6, v_16)

def cps_provider_4_native_match_telescope_2(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_7: Scope.ArenaGlobalScope, v_9: U32, v_11: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_4:
    case (v_16, v_17):
      cps_provider_4_native_match_telescope_1(Arena.get_binder(v_16, v_17), v_6, v_7, v_9, v_11)

def cps_provider_4_native_match_telescope_3(v_0: IR.Words, v_1: Arena.Arena, v_3: U32, v_4: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_0:
    case IR.Words{v_8, 0}:
      cps_provider_4_CatalogResult{v_1, cps_provider_4_Telescope{[], [], [], True{}}}
    case IR.Words{v_11, v_12}:
      cps_provider_4_native_match_telescope_2(Arena.word(v_1, IR.arena_tape_offset(v_11)), v_3, v_4, v_11, v_12)

def cps_provider_4_telescope(v_0: Arena.Arena, v_1: IR.Words, v_3: U32, v_4: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  cps_provider_4_native_match_telescope_3(v_1, v_0, v_3, v_4)

def cps_provider_4_native_match_telescope_binder_0(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: U32, v_4: Ast.Quantity, v_6: List<&2, BIR.Parameter>, v_8: List<&2, BIR.Quantity>, v_10: List<&2, BIR.DescriptorField>, v_12: Bool, v_14: String) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_1:
    case cps_provider_4_CatalogResult{v_19, v_20}:
      v_23 = cps_provider_4_quantity(v_4)
      cps_provider_4_CatalogResult{v_19, cps_provider_4_Telescope{cps_provider_4_parameter(v_3, v_23, v_6), v_23 <> v_8, BIR.DescriptorField{cps_provider_4_field_key(v_14, v_23), v_23, v_20} <> v_10, v_12}}

def cps_provider_4_native_match_telescope_binder_1(v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_6: U32, v_7: Scope.ArenaGlobalScope, v_8: Ast.Quantity, v_10: U32, v_12: List<&2, BIR.Parameter>, v_14: List<&2, BIR.Quantity>, v_16: List<&2, BIR.DescriptorField>, v_18: Bool) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_4:
    case (v_23, v_24):
      cps_provider_4_native_match_telescope_binder_0(cps_provider_4_descriptor(v_23, v_10, v_7), v_6, v_8, v_12, v_14, v_16, v_18, v_24)

def cps_provider_4_native_match_telescope_binder_2(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Parameter>, v_5: List<&2, BIR.Quantity>, v_7: List<&2, BIR.DescriptorField>) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_1:
    case cps_provider_4_CatalogResult{v_12, v_13}:
      cps_provider_4_CatalogResult{v_12, cps_provider_4_Telescope{v_3, BIR.Erased{} <> v_5, BIR.DescriptorField{None{}, BIR.Erased{}, v_13} <> v_7, False{}}}

def cps_provider_4_native_match_telescope_binder_3(v_0: Arena.Binder, v_2: cps_provider_4_Telescope, v_3: Arena.Arena, v_5: U32, v_6: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_0, v_2:
    case Arena.Binder{v_18, v_19, _, v_21, _}, cps_provider_4_Telescope{v_23, v_24, v_25, v_26}:
      cps_provider_4_native_match_telescope_binder_1(Arena.name_text(v_3, v_19), v_5, v_6, v_18, v_21, v_23, v_24, v_25, v_26)
    case Arena.TemplateBinder{_, _, v_38, _}, cps_provider_4_Telescope{v_40, v_41, v_42, _}:
      cps_provider_4_native_match_telescope_binder_2(cps_provider_4_descriptor(v_3, v_38, v_6), v_40, v_41, v_42)

def cps_provider_4_telescope_binder(v_0: Arena.Arena, v_1: Arena.Binder, v_3: U32, v_4: Scope.ArenaGlobalScope, v_6: cps_provider_4_Telescope) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  cps_provider_4_native_match_telescope_binder_3(v_1, v_6, v_0, v_3, v_4)

def cps_provider_4_field_names(v_1: List<&2, BIR.DescriptorField>) -> List<&2, Maybe<&2, String>>:
  match v_1:
    case []:
      []
    case BIR.DescriptorField{v_9, _, _} <> v_12:
      v_9 <> cps_provider_4_field_names(v_12)

def cps_provider_4_fields_quantities(v_1: List<&2, BIR.DescriptorField>) -> List<&2, BIR.Quantity>:
  match v_1:
    case []:
      []
    case BIR.DescriptorField{_, v_8, _} <> v_10:
      v_8 <> cps_provider_4_fields_quantities(v_10)

def cps_provider_4_base_imports(v_1: List<&2, Ast.ModuleImport>) -> Bool:
  match v_1:
    case []:
      False{}
    case Ast.ModuleImport{v_7, _, _} <> v_10:
      Bool.or(String.eq(v_7, "Base"), cps_provider_4_base_imports(v_10))

def cps_provider_4_base_imported(v_1: List<&2, IR.LoadedModule>) -> Bool:
  match v_1:
    case []:
      False{}
    case IR.LoadedModule{_, IR.Module{_, v_10, _}} <> v_12:
      Bool.or(cps_provider_4_base_imports(v_10), cps_provider_4_base_imported(v_12))

def cps_provider_4_base_source(v_1: String, v_3: Bool) -> Bool:
  Bool.and(v_3, Bool.or(String.eq(v_1, "bend2/base.bend"), String.ends_with(v_1, "/bend2/base.bend")))

def cps_provider_4_native_marker(v_1: Bool, v_3: String) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      None{}

def cps_provider_4_short_key(v_1: String) -> String:
  cps_provider_4_short_chars(String.to_list(v_1), [])

def cps_provider_4_short_chars(v_2: List<&2, Char>, v_5: List<&2, Char>) -> String:
  match v_2:
    case []:
      String.from_list(List.reverse(&2, Char, v_5))
    case '.' <> v_9:
      cps_provider_4_short_chars(v_9, [])
    case '/' <> v_12:
      cps_provider_4_short_chars(v_12, [])
    case v_16 <> v_17:
      cps_provider_4_short_chars(v_17, v_16 <> v_5)

def cps_provider_4_constructor_native(v_1: Bool, v_3: String, v_5: String) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{String.append(v_3, String.append(".", cps_provider_4_short_key(v_5)))}
    case False{}:
      Some{String.append("Data.", v_5)}

def cps_provider_4_primitive_name(v_1: String) -> String:
  String.from_list(cps_provider_4_primitive_chars(String.to_list(String.to_lower(v_1))))

def cps_provider_4_primitive_chars(v_2: List<&2, Char>) -> List<&2, Char>:
  match v_2:
    case []:
      []
    case '.' <> v_6:
      '_' <> cps_provider_4_primitive_chars(v_6)
    case '/' <> v_9:
      '_' <> cps_provider_4_primitive_chars(v_9)
    case v_13 <> v_14:
      v_13 <> cps_provider_4_primitive_chars(v_14)

def cps_provider_4_primitive(v_1: Bool, v_3: String) -> Maybe<&2, BIR.Primitive>:
  match v_1:
    case False{}:
      None{}
    case True{}:
      cps_provider_4_primitive_named(cps_provider_4_primitive_name(v_3))

def cps_provider_4_primitive_named(v_1: String) -> Maybe<&2, BIR.Primitive>:
  match v_1:
    case "u32_add":
      Some{BIR.PrimU32Add{}}
    case "u32_sub":
      Some{BIR.PrimU32Sub{}}
    case "u32_mul":
      Some{BIR.PrimU32Mul{}}
    case "u32_div":
      Some{BIR.PrimU32Div{}}
    case "u32_mod":
      Some{BIR.PrimU32Mod{}}
    case "u32_and":
      Some{BIR.PrimU32And{}}
    case "u32_or":
      Some{BIR.PrimU32Or{}}
    case "u32_xor":
      Some{BIR.PrimU32Xor{}}
    case "u32_is_eq":
      Some{BIR.PrimU32IsEq{}}
    case "u32_is_ne":
      Some{BIR.PrimU32IsNe{}}
    case "u32_is_lt":
      Some{BIR.PrimU32IsLt{}}
    case "u32_is_le":
      Some{BIR.PrimU32IsLe{}}
    case "u32_is_gt":
      Some{BIR.PrimU32IsGt{}}
    case "u32_is_ge":
      Some{BIR.PrimU32IsGe{}}
    case "u32_inc":
      Some{BIR.PrimU32Inc{}}
    case "u32_not":
      Some{BIR.PrimU32Not{}}
    case "u32_shl":
      Some{BIR.PrimU32Shl{}}
    case "u32_shr":
      Some{BIR.PrimU32Shr{}}
    case "u32_shln":
      Some{BIR.PrimU32Shln{}}
    case "u32_shrn":
      Some{BIR.PrimU32Shrn{}}
    case "u32_cmp":
      Some{BIR.PrimU32Cmp{}}
    case "u32_is_zero":
      Some{BIR.PrimU32IsZero{}}
    case "u32_to_nat":
      Some{BIR.PrimU32ToNat{}}
    case "u32_from_nat":
      Some{BIR.PrimU32FromNat{}}
    case "u32_to_f32":
      Some{BIR.PrimU32ToF32{}}
    case "f32_add":
      Some{BIR.PrimF32Add{}}
    case "f32_sub":
      Some{BIR.PrimF32Sub{}}
    case "f32_mul":
      Some{BIR.PrimF32Mul{}}
    case "f32_div":
      Some{BIR.PrimF32Div{}}
    case "f32_mod":
      Some{BIR.PrimF32Mod{}}
    case "f32_neg":
      Some{BIR.PrimF32Neg{}}
    case "f32_is_eq":
      Some{BIR.PrimF32IsEq{}}
    case "f32_is_ne":
      Some{BIR.PrimF32IsNe{}}
    case "f32_is_lt":
      Some{BIR.PrimF32IsLt{}}
    case "f32_is_le":
      Some{BIR.PrimF32IsLe{}}
    case "f32_is_gt":
      Some{BIR.PrimF32IsGt{}}
    case "f32_is_ge":
      Some{BIR.PrimF32IsGe{}}
    case "f32_sqrt":
      Some{BIR.PrimF32Sqrt{}}
    case "f32_abs":
      Some{BIR.PrimF32Abs{}}
    case "f32_exp":
      Some{BIR.PrimF32Exp{}}
    case "f32_log":
      Some{BIR.PrimF32Log{}}
    case "f32_log2":
      Some{BIR.PrimF32Log2{}}
    case "f32_log10":
      Some{BIR.PrimF32Log10{}}
    case "f32_sin":
      Some{BIR.PrimF32Sin{}}
    case "f32_cos":
      Some{BIR.PrimF32Cos{}}
    case "f32_tan":
      Some{BIR.PrimF32Tan{}}
    case "f32_asin":
      Some{BIR.PrimF32Asin{}}
    case "f32_acos":
      Some{BIR.PrimF32Acos{}}
    case "f32_atan":
      Some{BIR.PrimF32Atan{}}
    case "f32_sinh":
      Some{BIR.PrimF32Sinh{}}
    case "f32_cosh":
      Some{BIR.PrimF32Cosh{}}
    case "f32_tanh":
      Some{BIR.PrimF32Tanh{}}
    case "f32_pow":
      Some{BIR.PrimF32Pow{}}
    case "f32_atan2":
      Some{BIR.PrimF32Atan2{}}
    case "f32_floor":
      Some{BIR.PrimF32Floor{}}
    case "f32_ceil":
      Some{BIR.PrimF32Ceil{}}
    case "f32_trunc":
      Some{BIR.PrimF32Trunc{}}
    case "f32_to_u32":
      Some{BIR.PrimF32ToU32{}}
    case "f32_bits":
      Some{BIR.PrimF32Bits{}}
    case "f32_show":
      Some{BIR.PrimF32Show{}}
    case "f32_read":
      Some{BIR.PrimF32Read{}}
    case "nat_add":
      Some{BIR.PrimNatAdd{}}
    case "nat_sub":
      Some{BIR.PrimNatSub{}}
    case "nat_mul":
      Some{BIR.PrimNatMul{}}
    case "nat_double":
      Some{BIR.PrimNatDouble{}}
    case "nat_cmp":
      Some{BIR.PrimNatCmp{}}
    case "nat_is_lt":
      Some{BIR.PrimNatIsLt{}}
    case "nat_divmod":
      Some{BIR.PrimNatDivmod{}}
    case "nat_min":
      Some{BIR.PrimNatMin{}}
    case "nat_max":
      Some{BIR.PrimNatMax{}}
    case "map_bit":
      Some{BIR.PrimMapBit{}}
    case "string_cmp":
      Some{BIR.PrimStringCmp{}}
    case "string_to_list":
      Some{BIR.PrimStringToList{}}
    case "string_eq":
      Some{BIR.PrimStringEq{}}
    case "string_append":
      Some{BIR.PrimStringAppend{}}
    case "string_length":
      Some{BIR.PrimStringLength{}}
    case "bool_or":
      Some{BIR.PrimBoolOr{}}
    case "bool_xor":
      Some{BIR.PrimBoolXor{}}
    case "array_new":
      Some{BIR.PrimArrayNew{}}
    case "array_set":
      Some{BIR.PrimArraySet{}}
    case "array_get":
      Some{BIR.PrimArrayGet{}}
    case "array_swap":
      Some{BIR.PrimArraySwap{}}
    case "array_size":
      Some{BIR.PrimArraySize{}}
    case "array_clone":
      Some{BIR.PrimArrayClone{}}
    case _:
      None{}

def cps_provider_4_definition_key(v_1: cps_provider_4_Registry, v_3: String) -> Maybe<&2, cps_provider_4_DefinitionHeader>:
  match v_1:
    case cps_provider_4_Registry{v_8, _}:
      IndexLookup.find(cps_provider_4_DefinitionHeader, v_8, v_3)

def cps_provider_4_constructor_key(v_1: cps_provider_4_Registry, v_3: String) -> Maybe<&2, cps_provider_4_Constructor>:
  match v_1:
    case cps_provider_4_Registry{_, v_9}:
      IndexLookup.find(cps_provider_4_Constructor, v_9, v_3)

def cps_provider_4_lookup_definition(v_1: cps_provider_4_Registry, v_2: IR.Symbol) -> Maybe<&2, cps_provider_4_DefinitionHeader>:
  cps_provider_4_definition_key(v_1, cps_provider_4_symbol_key(v_2))

def cps_provider_4_lookup_constructor(v_1: cps_provider_4_Registry, v_2: IR.Symbol) -> Maybe<&2, cps_provider_4_Constructor>:
  cps_provider_4_constructor_key(v_1, cps_provider_4_symbol_key(v_2))

def cps_provider_4_get_definitions(v_1: cps_provider_4_Catalog) -> List<&2, cps_provider_4_Definition>:
  match v_1:
    case cps_provider_4_Catalog{v_11, _, _, _, _, _, _}:
      v_11

def cps_provider_4_get_registry(v_1: cps_provider_4_Catalog) -> cps_provider_4_Registry:
  match v_1:
    case cps_provider_4_Catalog{_, v_11, _, _, _, _, _}:
      v_11

def cps_provider_4_get_constructors(v_1: cps_provider_4_Catalog) -> List<&2, BIR.ConstructorLayout>:
  match v_1:
    case cps_provider_4_Catalog{_, _, v_12, _, _, _, _}:
      v_12

def cps_provider_4_get_families(v_1: cps_provider_4_Catalog) -> List<&2, BIR.Family>:
  match v_1:
    case cps_provider_4_Catalog{_, _, _, v_13, _, _, _}:
      v_13

def cps_provider_4_get_type_functions(v_1: cps_provider_4_Catalog) -> List<&2, BIR.TypeFunction>:
  match v_1:
    case cps_provider_4_Catalog{_, _, _, _, v_14, _, _}:
      v_14

def cps_provider_4_get_next_code(v_1: cps_provider_4_Catalog) -> U32:
  match v_1:
    case cps_provider_4_Catalog{_, _, _, _, _, v_15, _}:
      v_15

def cps_provider_4_get_ending(v_1: cps_provider_4_Catalog) -> BIR.Ending:
  match v_1:
    case cps_provider_4_Catalog{_, _, _, _, _, _, v_15}:
      v_15

def cps_provider_4_native_match_insert_definition_0(v_2: Maybe<&2, cps_provider_4_Definition>, +v_4: String, v_6: cps_provider_4_Definition, +v_9: Map<&2, cps_provider_4_Definition>) -> Map<&2, cps_provider_4_Definition>:
  match v_2:
    case Some{_}:
      v_9
    case None{}:
      Map.set(&2, cps_provider_4_Definition, v_9, v_4, v_6)

def cps_provider_4_insert_definition(+v_1: String, v_3: cps_provider_4_Definition, +v_6: Map<&2, cps_provider_4_Definition>) -> Map<&2, cps_provider_4_Definition>:
  cps_provider_4_native_match_insert_definition_0(IndexLookup.find(cps_provider_4_Definition, v_6, v_1), v_1, v_3, v_6)

def cps_provider_4_native_match_insert_constructor_0(v_2: Maybe<&2, cps_provider_4_Constructor>, +v_4: String, v_6: cps_provider_4_Constructor, +v_9: Map<&2, cps_provider_4_Constructor>) -> Map<&2, cps_provider_4_Constructor>:
  match v_2:
    case Some{_}:
      v_9
    case None{}:
      Map.set(&2, cps_provider_4_Constructor, v_9, v_4, v_6)

def cps_provider_4_insert_constructor(+v_1: String, v_3: cps_provider_4_Constructor, +v_6: Map<&2, cps_provider_4_Constructor>) -> Map<&2, cps_provider_4_Constructor>:
  cps_provider_4_native_match_insert_constructor_0(IndexLookup.find(cps_provider_4_Constructor, v_6, v_1), v_1, v_3, v_6)

def cps_provider_4_normalize_descriptor_value(v_0: BIR.Descriptor, +v_1: cps_provider_2_NfContext) -> BIR.Descriptor:
  cps_provider_2_normalize_in(v_1, v_0)

def cps_provider_4_normalize_descriptors(v_1: List<&2, BIR.Descriptor>, +v_2: cps_provider_2_NfContext) -> List<&2, BIR.Descriptor>:
  match v_1:
    case []:
      []
    case +v_6 <> v_7:
      cps_provider_4_normalize_descriptor_value(v_6, v_2) <> cps_provider_4_normalize_descriptors(v_7, v_2)

def cps_provider_4_normalize_foreign(v_2: Maybe<&2, cps_provider_4_Foreign>, +v_3: cps_provider_2_NfContext) -> Maybe<&2, cps_provider_4_Foreign>:
  match v_2:
    case None{}:
      None{}
    case Some{cps_provider_4_Foreign{v_12, v_13, v_14, v_15, v_16, v_17}}:
      Some{cps_provider_4_Foreign{v_12, v_13, v_14, v_15, cps_provider_4_normalize_descriptors(v_16, v_3), cps_provider_4_normalize_descriptor_value(v_17, v_3)}}

def cps_provider_4_normalize_foreign_header(v_1: cps_provider_4_DefinitionHeader, +v_2: cps_provider_2_NfContext) -> cps_provider_4_DefinitionHeader:
  match v_1:
    case cps_provider_4_DefinitionHeader{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      cps_provider_4_DefinitionHeader{v_13, v_14, v_15, v_16, v_17, v_18, v_19, cps_provider_4_normalize_foreign(v_20, v_2), v_21}

def cps_provider_4_normalize_foreign_definition(v_1: cps_provider_4_Definition, +v_2: cps_provider_2_NfContext) -> cps_provider_4_Definition:
  match v_1:
    case cps_provider_4_Definition{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      cps_provider_4_Definition{cps_provider_4_normalize_foreign_header(v_12, v_2), v_13, v_14, v_15, v_16, v_17, v_18, v_19}

def cps_provider_4_normalize_foreign_definitions(v_2: List<&2, cps_provider_4_Definition>, +v_3: cps_provider_2_NfContext) -> List<&2, cps_provider_4_Definition>:
  match v_2:
    case []:
      []
    case +v_8 <> v_9:
      cps_provider_4_normalize_foreign_definition(v_8, v_3) <> cps_provider_4_normalize_foreign_definitions(v_9, v_3)

def cps_provider_4_export_entry(v_2: Maybe<&2, cps_provider_4_DefinitionHeader>) -> Maybe<&2, BIR.Entry>:
  match v_2:
    case Some{cps_provider_4_DefinitionHeader{_, _, v_14, v_15, _, _, _, _, True{}}}:
      Some{BIR.Entry{v_14, List.length(&2, BIR.Parameter, v_15)}}
    case _:
      None{}

def native_match_cps_provider_4_export_definition_0(v_44: Bool, v_1: String, +v_9: cps_provider_4_Definition, v_10: List<&2, cps_provider_4_Definition>) -> Maybe<&2, cps_provider_4_Definition>:
  match v_44:
    case True{}:
      Some{v_9}
    case False{}:
      cps_provider_4_export_definition(v_1, v_10)

def native_match_cps_provider_4_export_definition_1(+v_9: cps_provider_4_Definition, v_1: String, v_10: List<&2, cps_provider_4_Definition>) -> Maybe<&2, cps_provider_4_Definition>:
  match v_9:
    case cps_provider_4_Definition{cps_provider_4_DefinitionHeader{_, v_28, _, _, _, _, _, _, _}, _, _, _, _, _, _, _}:
      native_match_cps_provider_4_export_definition_0(String.eq(v_1, v_28), v_1, v_9, v_10)

def native_match_cps_provider_4_export_definition_2(v_4: List<&2, cps_provider_4_Definition>, v_1: String) -> Maybe<&2, cps_provider_4_Definition>:
  match v_4:
    case []:
      None{}
    case +v_9 <> v_10:
      native_match_cps_provider_4_export_definition_1(v_9, v_1, v_10)

def cps_provider_4_export_definition(v_1: String, v_4: List<&2, cps_provider_4_Definition>) -> Maybe<&2, cps_provider_4_Definition>:
  native_match_cps_provider_4_export_definition_2(v_4, v_1)

def native_match_cps_provider_4_export_signature_0(v_22: Bool, v_1: String, v_9: List<&2, Scope.ArenaGlobal>, v_19: U32) -> Maybe<&2, U32>:
  match v_22:
    case True{}:
      Some{v_19}
    case False{}:
      cps_provider_4_export_signature(v_1, v_9)

def native_match_cps_provider_4_export_signature_1(+v_8: Scope.ArenaGlobal, v_1: String, v_9: List<&2, Scope.ArenaGlobal>) -> Maybe<&2, U32>:
  match v_8:
    case Scope.ArenaGlobal{v_16, _, _, v_19, _, _}:
      native_match_cps_provider_4_export_signature_0(String.eq(v_1, v_16), v_1, v_9, v_19)

def native_match_cps_provider_4_export_signature_2(v_3: List<&2, Scope.ArenaGlobal>, v_1: String) -> Maybe<&2, U32>:
  match v_3:
    case []:
      None{}
    case +v_8 <> v_9:
      native_match_cps_provider_4_export_signature_1(v_8, v_1, v_9)

def cps_provider_4_export_signature(v_1: String, v_3: List<&2, Scope.ArenaGlobal>) -> Maybe<&2, U32>:
  native_match_cps_provider_4_export_signature_2(v_3, v_1)

def cps_provider_4_live_arrow_types(v_0: BIR.Descriptor) -> List<&2, BIR.Descriptor>:
  match v_0:
    case BIR.DescriptorArrow{v_5, v_6, v_7}:
      match v_5:
        case BIR.Erased{}:
          cps_provider_4_live_arrow_types(v_7)
        case _:
          v_6 <> cps_provider_4_live_arrow_types(v_7)
    case _:
      []

def native_match_cps_provider_4_export_facts_0(v_37: cps_provider_4_CatalogResult<BIR.Descriptor>) -> cps_provider_4_CatalogResult<cps_provider_4_ExportFacts>:
  match v_37:
    case cps_provider_4_CatalogResult{v_33, v_34}:
      cps_provider_4_CatalogResult{v_33, cps_provider_4_ExportFacts{cps_provider_4_live_arrow_types(v_34)}}

def native_match_cps_provider_4_export_facts_1(v_36: Maybe<&2, U32>, v_0: Arena.Arena, v_2: String, v_24: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<cps_provider_4_ExportFacts>:
  match v_36:
    case None{}:
      cps_provider_4_CatalogResult{v_0, cps_provider_4_ExportFacts{[BIR.DescriptorFailure{String.append("bend: exported definition has no published signature: ", v_2)}]}}
    case Some{v_29}:
      native_match_cps_provider_4_export_facts_0(cps_provider_4_descriptor(v_0, v_29, v_24))

def native_match_cps_provider_4_export_facts_2(v_35: Maybe<&2, cps_provider_4_Definition>, v_0: Arena.Arena, v_2: String, v_7: List<&2, Scope.ArenaGlobal>) -> cps_provider_4_CatalogResult<cps_provider_4_ExportFacts>:
  match v_35:
    case None{}:
      cps_provider_4_CatalogResult{v_0, cps_provider_4_ExportFacts{[BIR.DescriptorFailure{String.append("bend: exported definition is not prepared: ", v_2)}]}}
    case Some{cps_provider_4_Definition{_, _, _, _, _, v_24, _, _}}:
      native_match_cps_provider_4_export_facts_1(cps_provider_4_export_signature(v_2, v_7), v_0, v_2, v_24)

def cps_provider_4_export_facts(v_0: Arena.Arena, v_2: String, v_5: List<&2, cps_provider_4_Definition>, v_7: List<&2, Scope.ArenaGlobal>) -> cps_provider_4_CatalogResult<cps_provider_4_ExportFacts>:
  native_match_cps_provider_4_export_facts_2(cps_provider_4_export_definition(v_2, v_5), v_0, v_2, v_7)

def native_match_cps_provider_4_exports_0(v_30: cps_provider_4_CatalogResult<List<&2, BIR.Export>>, v_4: cps_provider_4_Registry, +v_12: cps_provider_2_NfContext, v_17: String, v_23: List<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
  match v_30:
    case cps_provider_4_CatalogResult{v_27, v_28}:
      cps_provider_4_CatalogResult{v_27, BIR.Export{v_17, cps_provider_4_export_entry(cps_provider_4_definition_key(v_4, v_17)), cps_provider_4_normalize_descriptors(v_23, v_12)} <> v_28}

def native_match_cps_provider_4_exports_1(v_29: cps_provider_4_CatalogResult<cps_provider_4_ExportFacts>, v_4: cps_provider_4_Registry, v_8: List<&2, cps_provider_4_Definition>, v_10: List<&2, Scope.ArenaGlobal>, +v_12: cps_provider_2_NfContext, v_17: String, v_18: List<&2, String>) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
  match v_29:
    case cps_provider_4_CatalogResult{v_22, cps_provider_4_ExportFacts{v_23}}:
      native_match_cps_provider_4_exports_0(cps_provider_4_exports(v_18, v_4, v_22, v_8, v_10, v_12), v_4, v_12, v_17, v_23)

def native_match_cps_provider_4_exports_2(v_2: List<&2, String>, v_4: cps_provider_4_Registry, v_5: Arena.Arena, v_8: List<&2, cps_provider_4_Definition>, v_10: List<&2, Scope.ArenaGlobal>, +v_12: cps_provider_2_NfContext) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
  match v_2:
    case []:
      cps_provider_4_CatalogResult{v_5, []}
    case v_17 <> v_18:
      native_match_cps_provider_4_exports_1(cps_provider_4_export_facts(v_5, v_17, v_8, v_10), v_4, v_8, v_10, v_12, v_17, v_18)

def cps_provider_4_exports(v_2: List<&2, String>, v_4: cps_provider_4_Registry, v_5: Arena.Arena, v_8: List<&2, cps_provider_4_Definition>, v_10: List<&2, Scope.ArenaGlobal>, +v_12: cps_provider_2_NfContext) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
  native_match_cps_provider_4_exports_2(v_2, v_4, v_5, v_8, v_10, v_12)

def cps_provider_4_native_match_needed_ref_0(v_2: Maybe<&2, Bool>, v_3: Arena.Arena, v_5: String, v_8: Map<&2, cps_provider_4_Definition>, v_10: cps_provider_4_Needed, v_12: List<&2, BIR.TypeFunction>, v_15: Map<&2, Bool>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case Some{_}:
      cps_provider_4_CatalogResult{v_3, v_10}
    case None{}:
      cps_provider_4_needed_definition(v_3, IndexLookup.find(cps_provider_4_Definition, v_8, v_5), v_8, v_12, Map.set(&2, Bool, v_15, v_5, True{}))

def cps_provider_4_native_match_needed_ref_1(v_1: cps_provider_4_Needed, v_2: Arena.Arena, v_4: String, v_7: Map<&2, cps_provider_4_Definition>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_1:
    case cps_provider_4_Needed{v_12, v_13}:
      cps_provider_4_native_match_needed_ref_0(IndexLookup.find(Bool, v_13, v_4), v_2, v_4, v_7, v_1, v_12, v_13)

def cps_provider_4_needed_ref(v_0: Arena.Arena, v_2: String, v_5: Map<&2, cps_provider_4_Definition>, v_7: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  cps_provider_4_native_match_needed_ref_1(v_7, v_0, v_2, v_5)

def cps_provider_4_native_match_needed_definition_0(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>, v_4: Map<&2, cps_provider_4_Definition>, v_6: List<&2, BIR.TypeFunction>, v_9: Map<&2, Bool>, v_11: String, v_13: List<&2, BIR.Quantity>, v_15: U32, v_16: Scope.ArenaGlobalScope, v_19: Maybe<&2, String>, v_21: Nat) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_1:
    case cps_provider_4_CatalogResult{v_26, v_27}:
      v_29 = BIR.TypeFunction{v_11, v_19, v_21, List.length(&2, BIR.Quantity, v_13), v_27}
      cps_provider_4_needed_term(v_26, v_15, v_16, v_4, cps_provider_4_Needed{v_29 <> v_6, v_9})

def cps_provider_4_native_match_needed_definition_1(v_2: Maybe<&2, cps_provider_4_Definition>, v_3: Arena.Arena, v_6: Map<&2, cps_provider_4_Definition>, v_8: List<&2, BIR.TypeFunction>, v_11: Map<&2, Bool>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case Some{cps_provider_4_Definition{cps_provider_4_DefinitionHeader{_, v_30, _, _, v_33, _, _, None{}, _}, _, _, IR.DefTerm{v_39}, _, v_41, v_42, v_43}}:
      cps_provider_4_native_match_needed_definition_0(cps_provider_4_descriptor(v_3, v_39, v_41), v_6, v_8, v_11, v_30, v_33, v_39, v_41, v_42, v_43)
    case _:
      cps_provider_4_CatalogResult{v_3, cps_provider_4_Needed{v_8, v_11}}

def cps_provider_4_needed_definition(v_0: Arena.Arena, v_3: Maybe<&2, cps_provider_4_Definition>, v_6: Map<&2, cps_provider_4_Definition>, v_8: List<&2, BIR.TypeFunction>, v_11: Map<&2, Bool>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  cps_provider_4_native_match_needed_definition_1(v_3, v_0, v_6, v_8, v_11)

def cps_provider_4_native_match_needed_terms_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_4: U32, v_6: U32, v_7: Scope.ArenaGlobalScope, v_10: Map<&2, cps_provider_4_Definition>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_15, v_16}:
      cps_provider_4_needed_terms(v_15, IR.arena_range_index(v_4, 1), U32.sub(v_6, 1), v_7, v_10, v_16)

def cps_provider_4_native_match_needed_terms_1(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope, v_12: Map<&2, cps_provider_4_Definition>, v_14: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_4:
    case (v_19, v_20):
      cps_provider_4_native_match_needed_terms_0(cps_provider_4_needed_term(v_19, v_20, v_9, v_12, v_14), v_6, v_8, v_9, v_12)

def cps_provider_4_native_match_needed_terms_2(v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_4_Definition>, v_10: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_1:
    case 0:
      cps_provider_4_CatalogResult{v_2, v_10}
    case _:
      cps_provider_4_native_match_needed_terms_1(Arena.word(v_2, IR.arena_tape_offset(v_4)), v_4, v_1, v_5, v_8, v_10)

def cps_provider_4_needed_terms(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_4_Definition>, v_10: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  cps_provider_4_native_match_needed_terms_2(v_4, v_0, v_2, v_5, v_8, v_10)

def cps_provider_4_native_match_needed_pair_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_4_Definition>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_needed_term(v_13, v_4, v_5, v_8, v_14)

def cps_provider_4_needed_pair(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_4_Definition>, v_10: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  cps_provider_4_native_match_needed_pair_0(cps_provider_4_needed_term(v_0, v_2, v_5, v_8, v_10), v_4, v_5, v_8)

def cps_provider_4_native_match_needed_term_0(v_2: cps_provider_4_CatalogResult<String>, v_5: Map<&2, cps_provider_4_Definition>, v_7: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_12, v_13}:
      cps_provider_4_needed_ref(v_12, v_13, v_5, v_7)

def cps_provider_4_native_match_needed_term_1(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_4_Definition>, v_8: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_needed_term(v_13, v_8, v_3, v_6, v_14)

def cps_provider_4_native_match_needed_term_2(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_4_Definition>, v_8: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_needed_term(v_13, v_8, v_3, v_6, v_14)

def cps_provider_4_native_match_needed_term_3(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_4_Definition>, v_8: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_needed_term(v_13, v_8, v_3, v_6, v_14)

def cps_provider_4_native_match_needed_term_4(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_4_Definition>, v_8: U32, v_10: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_15, v_16}:
      cps_provider_4_needed_terms(v_15, v_8, v_10, v_3, v_6, v_16)

def cps_provider_4_native_match_needed_term_5(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_4_Definition>, v_8: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_needed_term(v_13, v_8, v_3, v_6, v_14)

def cps_provider_4_native_match_needed_term_6(v_0: Arena.Node, v_1: Scope.ArenaGlobalScope, v_4: Map<&2, cps_provider_4_Definition>, v_6: cps_provider_4_Needed, v_7: Arena.Arena) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_0:
    case Arena.TermRef{v_12, _}:
      cps_provider_4_native_match_needed_term_0(cps_provider_4_descriptor_name(v_7, v_12, v_1, False{}), v_4, v_6)
    case Arena.TermBang{v_18, _}:
      cps_provider_4_needed_term(v_7, v_18, v_1, v_4, v_6)
    case Arena.TermSub{_, v_26, v_27, _}:
      cps_provider_4_needed_pair(v_7, v_26, v_27, v_1, v_4, v_6)
    case Arena.TermLet{_, _, _, _, _, _, v_46, v_47, v_48, _}:
      cps_provider_4_native_match_needed_term_1(cps_provider_4_needed_terms(v_7, v_46, v_47, v_1, v_4, v_6), v_1, v_4, v_48)
    case Arena.TermAnn{v_55, v_56, _}:
      cps_provider_4_needed_pair(v_7, v_55, v_56, v_1, v_4, v_6)
    case Arena.TermType{v_61, _}:
      cps_provider_4_needed_term(v_7, v_61, v_1, v_4, v_6)
    case Arena.TermMin{v_67, v_68, _}:
      cps_provider_4_needed_pair(v_7, v_67, v_68, v_1, v_4, v_6)
    case Arena.TermAll{_, _, _, v_80, v_81, _}:
      cps_provider_4_needed_pair(v_7, v_80, v_81, v_1, v_4, v_6)
    case Arena.TermLam{_, _, _, v_92, _}:
      cps_provider_4_needed_term(v_7, v_92, v_1, v_4, v_6)
    case Arena.TermApp{v_98, v_99, _}:
      cps_provider_4_needed_pair(v_7, v_98, v_99, v_1, v_4, v_6)
    case Arena.TermAdt{_, v_109, v_110, _, _, _}:
      cps_provider_4_needed_terms(v_7, v_109, v_110, v_1, v_4, v_6)
    case Arena.TermFill{v_119, v_120, v_121, _}:
      cps_provider_4_native_match_needed_term_2(cps_provider_4_needed_terms(v_7, v_120, v_121, v_1, v_4, v_6), v_1, v_4, v_119)
    case Arena.TermPlus{v_129, v_130, v_131, _}:
      cps_provider_4_native_match_needed_term_3(cps_provider_4_needed_terms(v_7, v_130, v_131, v_1, v_4, v_6), v_1, v_4, v_129)
    case Arena.TermCtr{_, v_140, v_141, _}:
      cps_provider_4_needed_terms(v_7, v_140, v_141, v_1, v_4, v_6)
    case Arena.TermMat{_, v_149, v_150, _}:
      cps_provider_4_needed_pair(v_7, v_149, v_150, v_1, v_4, v_6)
    case Arena.TermEqual{_, _, v_159, _}:
      cps_provider_4_needed_term(v_7, v_159, v_1, v_4, v_6)
    case Arena.TermRewrite{_, _, v_168, _}:
      cps_provider_4_needed_term(v_7, v_168, v_1, v_4, v_6)
    case Arena.BodyMatch{v_176, v_177, v_178, v_179, _}:
      cps_provider_4_native_match_needed_term_4(cps_provider_4_needed_terms(v_7, v_176, v_177, v_1, v_4, v_6), v_1, v_4, v_178, v_179)
    case Arena.BodyCase{_, _, v_189, _}:
      cps_provider_4_needed_term(v_7, v_189, v_1, v_4, v_6)
    case Arena.BodyLocal{_, _, _, v_202, v_203, v_204, _}:
      cps_provider_4_native_match_needed_term_5(cps_provider_4_needed_terms(v_7, v_202, v_203, v_1, v_4, v_6), v_1, v_4, v_204)
    case Arena.BodyReply{v_210, _}:
      cps_provider_4_needed_term(v_7, v_210, v_1, v_4, v_6)
    case Arena.TermVar{_, _, _}:
      cps_provider_4_CatalogResult{v_7, v_6}
    case Arena.TermTemplate{_, _}:
      cps_provider_4_CatalogResult{v_7, v_6}
    case Arena.TermQuant{}:
      cps_provider_4_CatalogResult{v_7, v_6}
    case Arena.TermQuantity{_, _}:
      cps_provider_4_CatalogResult{v_7, v_6}
    case Arena.TermString{_, _, _}:
      cps_provider_4_CatalogResult{v_7, v_6}
    case Arena.TermAbsurd{_}:
      cps_provider_4_CatalogResult{v_7, v_6}
    case Arena.TermRefl{_}:
      cps_provider_4_CatalogResult{v_7, v_6}
    case Arena.TermHole{_, _}:
      cps_provider_4_CatalogResult{v_7, v_6}

def cps_provider_4_native_match_needed_term_7(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_4: Scope.ArenaGlobalScope, v_7: Map<&2, cps_provider_4_Definition>, v_9: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_3:
    case (v_14, v_15):
      cps_provider_4_native_match_needed_term_6(v_15, v_4, v_7, v_9, v_14)

def cps_provider_4_needed_term(v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_4_Definition>, v_8: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  cps_provider_4_native_match_needed_term_7(Arena.get_node(v_0, v_2), v_3, v_6, v_8)

def cps_provider_4_native_match_needed_roots_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_5: Map<&2, cps_provider_4_Definition>, v_8: List<&2, cps_provider_4_Root>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_needed_roots(v_13, v_8, v_5, v_14)

def cps_provider_4_native_match_needed_roots_1(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_5: Map<&2, cps_provider_4_Definition>, v_8: List<&2, cps_provider_4_Root>) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_needed_roots(v_13, v_8, v_5, v_14)

def cps_provider_4_native_match_needed_roots_2(v_2: List<&2, cps_provider_4_Root>, v_3: Arena.Arena, v_6: Map<&2, cps_provider_4_Definition>, v_8: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  match v_2:
    case []:
      cps_provider_4_CatalogResult{v_3, v_8}
    case cps_provider_4_TermRoot{v_14, v_15} <> v_16:
      cps_provider_4_native_match_needed_roots_0(cps_provider_4_needed_term(v_3, v_14, v_15, v_6, v_8), v_6, v_16)
    case cps_provider_4_DefinitionRoot{v_21} <> v_22:
      cps_provider_4_native_match_needed_roots_1(cps_provider_4_needed_ref(v_3, v_21, v_6, v_8), v_6, v_22)

def cps_provider_4_needed_roots(v_0: Arena.Arena, v_3: List<&2, cps_provider_4_Root>, v_6: Map<&2, cps_provider_4_Definition>, v_8: cps_provider_4_Needed) -> cps_provider_4_CatalogResult<cps_provider_4_Needed>:
  cps_provider_4_native_match_needed_roots_2(v_3, v_0, v_6, v_8)

def cps_provider_4_native_match_binder_roots_0(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_4: Scope.ArenaGlobalScope, v_7: List<&2, cps_provider_4_Root>, v_9: U32, v_11: U32) -> cps_provider_4_CatalogResult<List<&2, cps_provider_4_Root>>:
  match v_3:
    case (v_17, v_18):
      cps_provider_4_binder_roots(v_17, IR.Words{IR.arena_range_index(v_9, 1), U32.sub(v_11, 1)}, v_4, cps_provider_4_TermRoot{cps_provider_4_binder_type(v_18), v_4} <> v_7)

def cps_provider_4_native_match_binder_roots_1(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_5: Scope.ArenaGlobalScope, v_8: List<&2, cps_provider_4_Root>, v_10: U32, v_12: U32) -> cps_provider_4_CatalogResult<List<&2, cps_provider_4_Root>>:
  match v_4:
    case (v_18, v_19):
      cps_provider_4_native_match_binder_roots_0(Arena.get_binder(v_18, v_19), v_5, v_8, v_10, v_12)

def cps_provider_4_native_match_binder_roots_2(v_0: IR.Words, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope, v_5: List<&2, cps_provider_4_Root>) -> cps_provider_4_CatalogResult<List<&2, cps_provider_4_Root>>:
  match v_0:
    case IR.Words{_, 0}:
      cps_provider_4_CatalogResult{v_1, v_5}
    case IR.Words{v_13, v_14}:
      cps_provider_4_native_match_binder_roots_1(Arena.word(v_1, IR.arena_tape_offset(v_13)), v_2, v_5, v_13, v_14)

def cps_provider_4_binder_roots(v_0: Arena.Arena, v_1: IR.Words, v_2: Scope.ArenaGlobalScope, v_5: List<&2, cps_provider_4_Root>) -> cps_provider_4_CatalogResult<List<&2, cps_provider_4_Root>>:
  cps_provider_4_native_match_binder_roots_2(v_1, v_0, v_2, v_5)

def cps_provider_4_binder_type(v_0: Arena.Binder) -> U32:
  match v_0:
    case Arena.Binder{_, _, _, v_10, _}:
      v_10
    case Arena.TemplateBinder{_, _, v_18, _}:
      v_18

def cps_provider_4_result_roots(v_0: IR.OptionalTerm, v_1: Scope.ArenaGlobalScope, v_4: List<&2, cps_provider_4_Root>) -> List<&2, cps_provider_4_Root>:
  match v_0:
    case IR.NoTerm{}:
      v_4
    case IR.SomeTerm{v_8}:
      cps_provider_4_TermRoot{v_8, v_1} <> v_4

def cps_provider_4_type_root(v_1: Bool, v_3: String, v_6: List<&2, cps_provider_4_Root>) -> List<&2, cps_provider_4_Root>:
  match v_1:
    case True{}:
      cps_provider_4_DefinitionRoot{v_3} <> v_6
    case False{}:
      v_6

def cps_provider_4_preparation_failure(v_1: cps_provider_4_Preparation, v_3: String) -> cps_provider_4_Preparation:
  match v_1:
    case cps_provider_4_Preparation{v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27, v_28}:
      cps_provider_4_Preparation{v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, cps_provider_4_first_failure(v_27, v_3), v_28}

def cps_provider_4_first_failure(v_2: Maybe<&2, String>, v_4: String) -> Maybe<&2, String>:
  match v_2:
    case Some{_}:
      v_2
    case None{}:
      Some{v_4}

def cps_provider_4_native_match_header_insert_0(v_2: Maybe<&2, cps_provider_4_DefinitionHeader>, +v_4: String, v_6: cps_provider_4_DefinitionHeader, +v_9: Map<&2, cps_provider_4_DefinitionHeader>) -> Map<&2, cps_provider_4_DefinitionHeader>:
  match v_2:
    case Some{_}:
      v_9
    case None{}:
      Map.set(&2, cps_provider_4_DefinitionHeader, v_9, v_4, v_6)

def cps_provider_4_header_insert(+v_1: String, v_3: cps_provider_4_DefinitionHeader, +v_6: Map<&2, cps_provider_4_DefinitionHeader>) -> Map<&2, cps_provider_4_DefinitionHeader>:
  cps_provider_4_native_match_header_insert_0(IndexLookup.find(cps_provider_4_DefinitionHeader, v_6, v_1), v_1, v_3, v_6)

def cps_provider_4_value_insert(v_2: Maybe<&2, Bool>, v_3: IR.DefBody, v_5: String, v_7: cps_provider_4_Definition, v_10: Map<&2, cps_provider_4_Definition>) -> Map<&2, cps_provider_4_Definition>:
  match v_2, v_3:
    case None{}, IR.DefTerm{_}:
      cps_provider_4_insert_definition(v_5, v_7, v_10)
    case _, _:
      v_10

def cps_provider_4_native_match_foreign_sources_1(v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_6: String, v_8: U32, v_10: U32, v_13: List<&2, String>) -> cps_provider_4_CatalogResult<List<&2, String>>:
  match v_4:
    case (v_19, v_20):
      cps_provider_4_foreign_sources(v_19, IR.Names{IR.arena_range_index(v_8, 1), U32.sub(v_10, 1)}, v_6, Path.resolve(v_6, v_20) <> v_13)

def cps_provider_4_native_match_foreign_sources_0(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: String, v_8: U32, v_10: U32, v_13: List<&2, String>) -> cps_provider_4_CatalogResult<List<&2, String>>:
  match v_4:
    case (v_19, v_20):
      cps_provider_4_native_match_foreign_sources_1(Arena.name_text(v_19, v_20), v_6, v_8, v_10, v_13)

def cps_provider_4_foreign_sources(v_0: Arena.Arena, v_1: IR.Names, v_3: String, v_6: List<&2, String>) -> cps_provider_4_CatalogResult<List<&2, String>>:
  match v_1:
    case IR.Names{_, 0}:
      cps_provider_4_CatalogResult{v_0, List.reverse(&2, String, v_6)}
    case IR.Names{v_15, v_16}:
      cps_provider_4_native_match_foreign_sources_0(Arena.word(v_0, IR.arena_tape_offset(v_15)), v_3, v_15, v_16, v_6)

def native_match_cps_provider_4_foreign_namespace_0(v_4: Bool, v_1: String, v_3: String) -> String:
  match v_4:
    case True{}:
      ""
    case False{}:
      String.take(v_1, Nat.sub(String.length(v_1), Nat.add(String.length(v_3), 1n)))

def cps_provider_4_foreign_namespace(v_1: String, v_3: String) -> String:
  native_match_cps_provider_4_foreign_namespace_0(String.eq(v_1, v_3), v_1, v_3)

def cps_provider_4_foreign_result_type(v_0: Arena.Arena, v_1: IR.OptionalTerm, v_2: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<BIR.Descriptor>:
  match v_1:
    case IR.NoTerm{}:
      cps_provider_4_CatalogResult{v_0, BIR.DescriptorFailure{"bend: foreign definition has no checked result type"}}
    case IR.SomeTerm{v_5}:
      cps_provider_4_descriptor(v_0, v_5, v_2)

def cps_provider_4_live_parameter_types(v_0: Arena.Arena, v_1: IR.Words, v_2: Scope.ArenaGlobalScope, v_4: List<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case IR.Words{_, 0}:
      cps_provider_4_CatalogResult{v_0, List.reverse(&2, BIR.Descriptor, v_4)}
    case IR.Words{v_11, v_12}:
      cps_provider_4_native_match_live_parameter_types_2(Arena.word(v_0, IR.arena_tape_offset(v_11)), v_2, v_4, v_11, v_12)

def cps_provider_4_native_match_live_parameter_types_2(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_5: Scope.ArenaGlobalScope, v_7: List<&2, BIR.Descriptor>, v_9: U32, v_11: U32) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_4:
    case (v_16, v_17):
      cps_provider_4_native_match_live_parameter_types_1(Arena.get_binder(v_16, v_17), v_5, v_7, v_9, v_11)

def cps_provider_4_native_match_live_parameter_types_1(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_4: Scope.ArenaGlobalScope, v_6: List<&2, BIR.Descriptor>, v_8: U32, v_10: U32) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_3:
    case (v_15, v_16):
      cps_provider_4_live_parameter_binder(v_15, v_16, v_4, v_6, v_8, v_10)

def cps_provider_4_live_parameter_binder(v_0: Arena.Arena, v_1: Arena.Binder, v_2: Scope.ArenaGlobalScope, v_4: List<&2, BIR.Descriptor>, v_6: U32, v_8: U32) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case Arena.Binder{v_16, _, _, v_19, _}:
      cps_provider_4_live_parameter_quantity(cps_provider_4_quantity(v_16), v_0, v_19, v_2, v_4, v_6, v_8)
    case Arena.TemplateBinder{_, _, _, _}:
      cps_provider_4_live_parameter_types(v_0, IR.Words{IR.arena_range_index(v_6, 1), U32.sub(v_8, 1)}, v_2, v_4)

def native_match_cps_provider_4_live_parameter_quantity_0(v_21: cps_provider_4_CatalogResult<BIR.Descriptor>, v_4: Scope.ArenaGlobalScope, v_6: List<&2, BIR.Descriptor>, v_8: U32, v_10: U32) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_21:
    case cps_provider_4_CatalogResult{v_19, v_20}:
      cps_provider_4_live_parameter_types(v_19, IR.Words{IR.arena_range_index(v_8, 1), U32.sub(v_10, 1)}, v_4, v_20 <> v_6)

def native_match_cps_provider_4_live_parameter_quantity_1(v_0: BIR.Quantity, v_1: Arena.Arena, v_3: U32, v_4: Scope.ArenaGlobalScope, v_6: List<&2, BIR.Descriptor>, v_8: U32, v_10: U32) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  match v_0:
    case BIR.Erased{}:
      cps_provider_4_live_parameter_types(v_1, IR.Words{IR.arena_range_index(v_8, 1), U32.sub(v_10, 1)}, v_4, v_6)
    case _:
      native_match_cps_provider_4_live_parameter_quantity_0(cps_provider_4_descriptor(v_1, v_3, v_4), v_4, v_6, v_8, v_10)

def cps_provider_4_live_parameter_quantity(v_0: BIR.Quantity, v_1: Arena.Arena, v_3: U32, v_4: Scope.ArenaGlobalScope, v_6: List<&2, BIR.Descriptor>, v_8: U32, v_10: U32) -> cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>:
  native_match_cps_provider_4_live_parameter_quantity_1(v_0, v_1, v_3, v_4, v_6, v_8, v_10)

def native_match_cps_provider_4_definition_foreign_0(v_36: cps_provider_4_CatalogResult<BIR.Descriptor>, v_5: String, v_7: String, v_8: Ast.SourceSpan, v_23: List<&2, String>, v_28: List<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<Maybe<&2, cps_provider_4_Foreign>>:
  match v_36:
    case cps_provider_4_CatalogResult{v_32, v_33}:
      cps_provider_4_CatalogResult{v_32, Some{cps_provider_4_Foreign{cps_provider_4_foreign_namespace(v_5, v_7), v_7, v_23, v_8, v_28, v_33}}}

def native_match_cps_provider_4_definition_foreign_1(v_35: cps_provider_4_CatalogResult<List<&2, BIR.Descriptor>>, v_5: String, v_7: String, v_8: Ast.SourceSpan, v_10: IR.OptionalTerm, v_11: Scope.ArenaGlobalScope, v_23: List<&2, String>) -> cps_provider_4_CatalogResult<Maybe<&2, cps_provider_4_Foreign>>:
  match v_35:
    case cps_provider_4_CatalogResult{v_27, v_28}:
      native_match_cps_provider_4_definition_foreign_0(cps_provider_4_foreign_result_type(v_27, v_10, v_11), v_5, v_7, v_8, v_23, v_28)

def native_match_cps_provider_4_definition_foreign_2(v_34: cps_provider_4_CatalogResult<List<&2, String>>, v_5: String, v_7: String, v_8: Ast.SourceSpan, v_9: IR.Words, v_10: IR.OptionalTerm, v_11: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<Maybe<&2, cps_provider_4_Foreign>>:
  match v_34:
    case cps_provider_4_CatalogResult{v_22, v_23}:
      native_match_cps_provider_4_definition_foreign_1(cps_provider_4_live_parameter_types(v_22, v_9, v_11, []), v_5, v_7, v_8, v_10, v_11, v_23)

def native_match_cps_provider_4_definition_foreign_3(v_1: IR.DefBody, v_0: Arena.Arena, v_3: String, v_5: String, v_7: String, v_8: Ast.SourceSpan, v_9: IR.Words, v_10: IR.OptionalTerm, v_11: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<Maybe<&2, cps_provider_4_Foreign>>:
  match v_1:
    case IR.DefTerm{_}:
      cps_provider_4_CatalogResult{v_0, None{}}
    case IR.DefImports{v_18}:
      native_match_cps_provider_4_definition_foreign_2(cps_provider_4_foreign_sources(v_0, v_18, v_3, []), v_5, v_7, v_8, v_9, v_10, v_11)

def cps_provider_4_definition_foreign(v_0: Arena.Arena, v_1: IR.DefBody, v_3: String, v_5: String, v_7: String, v_8: Ast.SourceSpan, v_9: IR.Words, v_10: IR.OptionalTerm, v_11: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<Maybe<&2, cps_provider_4_Foreign>>:
  native_match_cps_provider_4_definition_foreign_3(v_1, v_0, v_3, v_5, v_7, v_8, v_9, v_10, v_11)

def cps_provider_4_definition_fast(v_1: Bool, v_3: Bool, v_5: List<&2, BIR.Parameter>, v_7: Maybe<&2, BIR.Primitive>, v_10: Maybe<&2, cps_provider_4_Foreign>) -> Bool:
  match v_5, v_7, v_10:
    case _ <> _, None{}, None{}:
      Bool.and(v_1, Bool.not(v_3))
    case _, _, _:
      False{}

def cps_provider_4_definition_primitive(v_1: Bool, v_4: Maybe<&2, cps_provider_4_Foreign>, v_6: Bool, v_8: String) -> Maybe<&2, BIR.Primitive>:
  match v_1, v_4:
    case False{}, None{}:
      cps_provider_4_primitive(v_6, v_8)
    case _, _:
      None{}

def cps_provider_4_native_match_main_descriptor_0(v_1: cps_provider_4_CatalogResult<BIR.Descriptor>) -> cps_provider_4_CatalogResult<Maybe<&2, BIR.Descriptor>>:
  match v_1:
    case cps_provider_4_CatalogResult{v_6, v_7}:
      cps_provider_4_CatalogResult{v_6, Some{v_7}}

def cps_provider_4_native_match_main_descriptor_1(v_1: Bool, v_2: IR.OptionalTerm, v_3: Arena.Arena, v_4: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<Maybe<&2, BIR.Descriptor>>:
  match v_1, v_2:
    case True{}, IR.SomeTerm{v_8}:
      cps_provider_4_native_match_main_descriptor_0(cps_provider_4_descriptor(v_3, v_8, v_4))
    case _, _:
      cps_provider_4_CatalogResult{v_3, None{}}

def cps_provider_4_native_match_main_descriptor_2(v_1: Maybe<&2, BIR.Descriptor>, v_2: Arena.Arena, v_4: String, v_5: IR.OptionalTerm, v_6: Scope.ArenaGlobalScope) -> cps_provider_4_CatalogResult<Maybe<&2, BIR.Descriptor>>:
  match v_1:
    case Some{_}:
      cps_provider_4_CatalogResult{v_2, v_1}
    case None{}:
      cps_provider_4_native_match_main_descriptor_1(String.eq(v_4, "main"), v_5, v_2, v_6)

def cps_provider_4_main_descriptor(v_0: Arena.Arena, v_2: String, v_3: IR.OptionalTerm, v_4: Scope.ArenaGlobalScope, v_6: Maybe<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<Maybe<&2, BIR.Descriptor>>:
  cps_provider_4_native_match_main_descriptor_2(v_6, v_0, v_2, v_3, v_4)

def cps_provider_4_signature_symbol(v_0: Scope.ArenaGlobal) -> IR.Symbol:
  match v_0:
    case Scope.ArenaGlobal{_, v_7, v_8, v_9, _, Scope.GlobalDefinition{}}:
      IR.Symbol{v_7, v_8, IR.DefinitionSymbol{}, v_9}
    case Scope.ArenaGlobal{_, v_17, v_18, v_19, _, Scope.GlobalFamily{}}:
      IR.Symbol{v_17, v_18, IR.FamilySymbol{}, v_19}
    case Scope.ArenaGlobal{_, v_27, v_28, v_29, _, Scope.GlobalConstructor{}}:
      IR.Symbol{v_27, v_28, IR.ConstructorSymbol{}, v_29}

def cps_provider_4_prepare_definition(v_0: Arena.Arena, v_1: IR.Definition, v_3: String, v_5: String, v_7: Bool, v_8: Scope.ArenaGlobalScope, v_10: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case IR.Definition{v_23, v_24, v_25, v_26, _, v_28, v_29, Some{IR.DefinitionFacts{v_30, v_31, v_32}}}:
      cps_provider_4_prepare_definition_symbol(v_0, Scope.lookup_kind(cps_provider_4_qualify(v_3, v_23), Scope.GlobalDefinition{}, v_8), cps_provider_4_qualify(v_3, v_23), v_23, v_24, v_25, v_26, v_29, Bool.and(v_30, cps_provider_4_is_term(v_26)), v_31, v_32, v_5, v_7, v_8, v_10, v_28)
    case IR.Definition{v_44, _, _, _, _, _, _, None{}}:
      cps_provider_4_CatalogResult{v_0, cps_provider_4_preparation_failure(v_10, String.append("bend: missing checked declaration facts for ", cps_provider_4_qualify(v_3, v_44)))}

def cps_provider_4_native_match_prepare_definition_symbol_0(v_2: cps_provider_4_CatalogResult<Maybe<&2, BIR.Descriptor>>, v_4: String, v_5: IR.DefBody, v_8: List<&2, cps_provider_4_Definition>, v_11: Map<&2, cps_provider_4_Definition>, v_14: Map<&2, cps_provider_4_DefinitionHeader>, v_16: List<&2, BIR.ConstructorLayout>, v_19: Map<&2, cps_provider_4_Constructor>, v_21: List<&2, BIR.Family>, v_23: U32, v_25: U32, v_28: Maybe<&2, String>, v_31: Map<&2, Bool>, v_33: cps_provider_4_DefinitionHeader, v_35: cps_provider_4_Definition, v_38: List<&2, cps_provider_4_Root>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2:
    case cps_provider_4_CatalogResult{v_43, v_44}:
      v_48 = cps_provider_4_value_insert(IndexLookup.find(Bool, v_31, v_4), v_5, v_4, v_35, v_11)
      cps_provider_4_CatalogResult{v_43, cps_provider_4_Preparation{v_35 <> v_8, v_48, cps_provider_4_header_insert(v_4, v_33, v_14), v_16, v_19, v_21, U32.add(v_23, 1), v_25, v_38, v_44, v_28, Map.set(&2, Bool, v_31, v_4, True{})}}

def cps_provider_4_native_match_prepare_definition_symbol_1(v_3: cps_provider_4_CatalogResult<List<&2, cps_provider_4_Root>>, v_5: String, v_6: IR.OptionalTerm, v_7: IR.DefBody, v_9: Bool, v_10: Scope.ArenaGlobalScope, v_13: List<&2, cps_provider_4_Definition>, v_16: Map<&2, cps_provider_4_Definition>, v_19: Map<&2, cps_provider_4_DefinitionHeader>, v_21: List<&2, BIR.ConstructorLayout>, v_24: Map<&2, cps_provider_4_Constructor>, v_26: List<&2, BIR.Family>, v_28: U32, v_30: U32, v_32: Maybe<&2, BIR.Descriptor>, v_35: Maybe<&2, String>, v_38: Map<&2, Bool>, v_40: cps_provider_4_DefinitionHeader, v_42: cps_provider_4_Definition) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_3:
    case cps_provider_4_CatalogResult{v_47, v_48}:
      v_53 = cps_provider_4_type_root(Bool.and(v_9, cps_provider_4_is_term(v_7)), v_5, cps_provider_4_result_roots(v_6, v_10, v_48))
      cps_provider_4_native_match_prepare_definition_symbol_0(cps_provider_4_main_descriptor(v_47, v_5, v_6, v_10, v_32), v_5, v_7, v_13, v_16, v_19, v_21, v_24, v_26, v_28, v_30, v_35, v_38, v_40, v_42, v_53)

def cps_provider_4_native_match_prepare_definition_symbol_2(v_1: cps_provider_4_Preparation, v_3: String, v_4: IR.Words, v_5: IR.OptionalTerm, v_6: IR.DefBody, v_8: Maybe<&2, IR.Occurrence>, v_10: Bool, v_12: Nat, v_14: Bool, v_15: Scope.ArenaGlobalScope, v_16: Scope.ArenaGlobal, v_18: List<&2, BIR.Parameter>, v_20: List<&2, BIR.Quantity>, v_21: Arena.Arena, v_24: Maybe<&2, cps_provider_4_Foreign>, v_26: Maybe<&2, BIR.Primitive>, v_28: Bool) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case cps_provider_4_Preparation{v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50, v_51, v_52, v_53, v_54}:
      v_57 = cps_provider_4_DefinitionHeader{cps_provider_4_signature_symbol(v_16), v_3, v_49, v_18, v_20, v_10, v_26, v_24, v_28}
      v_60 = cps_provider_4_Definition{v_57, v_4, v_5, v_6, v_8, v_15, cps_provider_4_native_marker(v_14, v_3), v_12}
      cps_provider_4_native_match_prepare_definition_symbol_1(cps_provider_4_binder_roots(v_21, v_4, v_15, v_51), v_3, v_5, v_6, v_10, v_15, v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50, v_52, v_53, v_54, v_57, v_60)

def cps_provider_4_native_match_prepare_definition_symbol_3(v_3: cps_provider_4_CatalogResult<Maybe<&2, cps_provider_4_Foreign>>, v_5: String, v_6: IR.Words, v_7: IR.OptionalTerm, v_8: IR.DefBody, v_10: Maybe<&2, IR.Occurrence>, v_12: Bool, v_14: Bool, v_16: Nat, v_18: Bool, v_19: Scope.ArenaGlobalScope, v_21: cps_provider_4_Preparation, v_22: Scope.ArenaGlobal, v_24: List<&2, BIR.Parameter>, v_26: List<&2, BIR.Quantity>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_3:
    case cps_provider_4_CatalogResult{v_31, v_32}:
      v_35 = cps_provider_4_definition_primitive(v_12, v_32, v_18, v_5)
      v_38 = cps_provider_4_definition_fast(v_14, v_12, v_24, v_35, v_32)
      cps_provider_4_native_match_prepare_definition_symbol_2(v_21, v_5, v_6, v_7, v_8, v_10, v_12, v_16, v_18, v_19, v_22, v_24, v_26, v_31, v_32, v_35, v_38)

def cps_provider_4_native_match_prepare_definition_symbol_4(v_2: cps_provider_4_CatalogResult<cps_provider_4_Telescope>, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: cps_provider_4_Preparation, v_25: Scope.ArenaGlobal, v_26: Ast.SourceSpan) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2:
    case cps_provider_4_CatalogResult{v_34, cps_provider_4_Telescope{v_35, v_36, _, _}}:
      cps_provider_4_native_match_prepare_definition_symbol_3(cps_provider_4_definition_foreign(v_34, v_9, v_19, v_4, v_6, v_26, v_7, v_8, v_22), v_4, v_7, v_8, v_9, v_11, v_13, v_15, v_17, v_21, v_22, v_24, v_25, v_35, v_36)

def cps_provider_4_native_match_prepare_definition_symbol_5(v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: Arena.Arena, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: cps_provider_4_Preparation, v_25: Ast.SourceSpan) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case None{}:
      cps_provider_4_CatalogResult{v_2, cps_provider_4_preparation_failure(v_24, String.append("bend: missing published definition signature for ", v_4))}
    case Some{v_30}:
      cps_provider_4_native_match_prepare_definition_symbol_4(cps_provider_4_live_telescope(v_2, v_7, 0), v_4, v_6, v_7, v_8, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_22, v_24, v_30, v_25)

def cps_provider_4_prepare_definition_symbol(v_0: Arena.Arena, v_2: Maybe<&2, Scope.ArenaGlobal>, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: cps_provider_4_Preparation, v_25: Ast.SourceSpan) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  cps_provider_4_native_match_prepare_definition_symbol_5(v_2, v_0, v_4, v_6, v_7, v_8, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_22, v_24, v_25)

def cps_provider_4_is_term(v_0: IR.DefBody) -> Bool:
  match v_0:
    case IR.DefTerm{_}:
      True{}
    case IR.DefImports{_}:
      False{}

def cps_provider_4_native_match_prepare_constructors_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Arms>, v_4: List<&2, BIR.DescriptorField>, v_6: String) -> cps_provider_4_CatalogResult<cps_provider_4_Arms>:
  match v_2:
    case cps_provider_4_CatalogResult{v_12, cps_provider_4_Arms{v_13, v_14}}:
      cps_provider_4_CatalogResult{v_12, cps_provider_4_Arms{BIR.DescriptorArm{v_6, v_4} <> v_13, v_14}}

def cps_provider_4_native_match_prepare_constructors_1(v_3: cps_provider_4_CatalogResult<List<&2, cps_provider_4_Root>>, v_5: String, v_7: String, v_9: Nat, v_11: Bool, v_12: Scope.ArenaGlobalScope, v_14: List<&2, IR.ConstructorDecl>, v_16: List<&2, BIR.DescriptorField>, v_18: String, v_21: List<&2, cps_provider_4_Definition>, v_24: Map<&2, cps_provider_4_Definition>, v_27: Map<&2, cps_provider_4_DefinitionHeader>, v_29: List<&2, BIR.ConstructorLayout>, v_32: Map<&2, cps_provider_4_Constructor>, v_34: List<&2, BIR.Family>, v_36: U32, v_38: U32, v_40: Maybe<&2, BIR.Descriptor>, v_43: Maybe<&2, String>, v_46: Map<&2, Bool>, v_47: BIR.ConstructorLayout, v_49: cps_provider_4_Constructor) -> cps_provider_4_CatalogResult<cps_provider_4_Arms>:
  match v_3:
    case cps_provider_4_CatalogResult{v_54, v_55}:
      v_58 = cps_provider_4_Preparation{v_21, v_24, v_27, v_47 <> v_29, cps_provider_4_insert_constructor(v_18, v_49, v_32), v_34, v_36, U32.add(v_38, 1), v_55, v_40, v_43, v_46}
      cps_provider_4_native_match_prepare_constructors_0(cps_provider_4_prepare_constructors(v_54, v_14, v_5, v_7, v_9, v_11, v_12, v_58), v_16, v_18)

def cps_provider_4_native_match_prepare_constructors_2(v_1: cps_provider_4_Preparation, v_3: String, v_5: String, v_7: Nat, v_9: Bool, v_10: Scope.ArenaGlobalScope, v_11: IR.Words, v_13: List<&2, IR.ConstructorDecl>, v_14: Arena.Arena, v_16: List<&2, BIR.Quantity>, v_18: List<&2, BIR.DescriptorField>, v_20: String) -> cps_provider_4_CatalogResult<cps_provider_4_Arms>:
  match v_1:
    case cps_provider_4_Preparation{v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45, v_46}:
      v_50 = BIR.ConstructorLayout{v_42, v_20, cps_provider_4_constructor_native(v_9, v_5, v_20), cps_provider_4_field_names(v_18)}
      v_53 = cps_provider_4_Constructor{v_50, v_16, v_7, cps_provider_4_qualify(v_3, v_5)}
      cps_provider_4_native_match_prepare_constructors_1(cps_provider_4_binder_roots(v_14, v_11, v_10, v_43), v_3, v_5, v_7, v_9, v_10, v_13, v_18, v_20, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_44, v_45, v_46, v_50, v_53)

def cps_provider_4_native_match_prepare_constructors_3(v_2: cps_provider_4_CatalogResult<cps_provider_4_Telescope>, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: cps_provider_4_Preparation, v_15: String, v_16: IR.Words, v_18: List<&2, IR.ConstructorDecl>) -> cps_provider_4_CatalogResult<cps_provider_4_Arms>:
  match v_2:
    case cps_provider_4_CatalogResult{v_26, cps_provider_4_Telescope{_, v_28, v_29, _}}:
      v_33 = cps_provider_4_qualify(v_4, v_15)
      cps_provider_4_native_match_prepare_constructors_2(v_13, v_4, v_6, v_8, v_10, v_11, v_16, v_18, v_26, v_28, v_29, v_33)

def cps_provider_4_native_match_prepare_constructors_4(v_1: List<&2, IR.ConstructorDecl>, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Arms>:
  match v_1:
    case []:
      cps_provider_4_CatalogResult{v_2, cps_provider_4_Arms{[], v_13}}
    case IR.Constructor{v_20, v_21, _} <> v_23:
      cps_provider_4_native_match_prepare_constructors_3(cps_provider_4_telescope(v_2, v_21, 0, v_11), v_4, v_6, v_8, v_10, v_11, v_13, v_20, v_21, v_23)

def cps_provider_4_prepare_constructors(v_0: Arena.Arena, v_2: List<&2, IR.ConstructorDecl>, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Arms>:
  cps_provider_4_native_match_prepare_constructors_4(v_2, v_0, v_4, v_6, v_8, v_10, v_11, v_13)

def cps_provider_4_native_match_prepare_family_0(v_3: cps_provider_4_CatalogResult<List<&2, cps_provider_4_Root>>, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: String, v_12: U32, v_14: Nat, v_16: List<&2, BIR.DescriptorArm>, v_19: List<&2, cps_provider_4_Definition>, v_22: Map<&2, cps_provider_4_Definition>, v_25: Map<&2, cps_provider_4_DefinitionHeader>, v_27: List<&2, BIR.ConstructorLayout>, v_30: Map<&2, cps_provider_4_Constructor>, v_32: List<&2, BIR.Family>, v_34: U32, v_36: U32, v_38: Maybe<&2, BIR.Descriptor>, v_41: Maybe<&2, String>, v_44: Map<&2, Bool>, v_46: String) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_3:
    case cps_provider_4_CatalogResult{v_51, v_52}:
      v_55 = BIR.Family{v_46, v_10, cps_provider_4_native_marker(v_5, v_10), v_8, v_14, v_16}
      v_57 = cps_provider_4_Preparation{v_19, v_22, v_25, v_27, v_30, v_55 <> v_32, v_34, v_36, cps_provider_4_TermRoot{v_12, v_6} <> v_52, v_38, v_41, v_44}
      cps_provider_4_CatalogResult{v_51, cps_provider_4_block_family(Scope.lookup_kind(v_46, Scope.GlobalFamily{}, v_6), v_46, v_57)}

def cps_provider_4_native_match_prepare_family_1(v_1: cps_provider_4_Preparation, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: String, v_11: IR.Words, v_13: U32, v_15: Nat, v_16: Arena.Arena, v_18: List<&2, BIR.DescriptorArm>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case cps_provider_4_Preparation{v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44}:
      v_47 = cps_provider_4_qualify(v_3, v_10)
      cps_provider_4_native_match_prepare_family_0(cps_provider_4_binder_roots(v_16, v_11, v_6, v_41), v_5, v_6, v_8, v_10, v_13, v_15, v_18, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_42, v_43, v_44, v_47)

def cps_provider_4_native_match_prepare_family_2(v_2: cps_provider_4_CatalogResult<cps_provider_4_Arms>, v_4: String, v_6: Bool, v_7: Scope.ArenaGlobalScope, v_9: Nat, v_11: String, v_12: IR.Words, v_14: U32, v_16: Nat) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2:
    case cps_provider_4_CatalogResult{v_22, cps_provider_4_Arms{v_23, v_24}}:
      cps_provider_4_native_match_prepare_family_1(v_24, v_4, v_6, v_7, v_9, v_11, v_12, v_14, v_16, v_22, v_23)

def cps_provider_4_native_match_prepare_family_3(v_0: IR.TypeDecl, v_1: Arena.Arena, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_0:
    case IR.TypeDecl{v_18, v_19, v_20, v_21, _}:
      v_25 = cps_provider_4_words_count(v_19)
      cps_provider_4_native_match_prepare_family_2(cps_provider_4_prepare_constructors(v_1, v_21, v_3, v_18, v_25, v_5, v_6, v_10), v_3, v_5, v_6, v_8, v_18, v_19, v_20, v_25)

def cps_provider_4_prepare_family(v_0: Arena.Arena, v_1: IR.TypeDecl, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  cps_provider_4_native_match_prepare_family_3(v_1, v_0, v_3, v_5, v_6, v_8, v_10)

def cps_provider_4_words_count(v_0: IR.Words) -> Nat:
  match v_0:
    case IR.Words{_, v_5}:
      U32.to_nat(v_5)

def cps_provider_4_block_family(v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: String, v_5: cps_provider_4_Preparation) -> cps_provider_4_Preparation:
  match v_1, v_5:
    case Some{v_20}, cps_provider_4_Preparation{v_21, v_22, v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32}:
      v_35 = cps_provider_4_DefinitionHeader{cps_provider_4_signature_symbol(v_20), v_3, v_27, [], [], True{}, None{}, None{}, False{}}
      cps_provider_4_Preparation{v_21, v_22, cps_provider_4_header_insert(v_3, v_35, v_23), v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32}
    case None{}, _:
      cps_provider_4_preparation_failure(v_5, String.append("bend: missing published family signature for ", v_3))

def cps_provider_4_law_telescope(v_1: List<&2, IR.Clause>, v_3: U32) -> Maybe<&2, cps_provider_4_Telescope>:
  match v_1:
    case []:
      Some{cps_provider_4_Telescope{[], [], [], True{}}}
    case IR.ClauseFor{True{}, v_11, _, _, None{}, _} <> v_15:
      cps_provider_4_law_telescope_cons(cps_provider_4_quantity(v_11), v_3, cps_provider_4_law_telescope(v_15, U32.add(v_3, 1)))
    case _ <> _:
      None{}

def cps_provider_4_law_telescope_cons(v_0: BIR.Quantity, v_2: U32, v_5: Maybe<&2, cps_provider_4_Telescope>) -> Maybe<&2, cps_provider_4_Telescope>:
  match v_5:
    case None{}:
      None{}
    case Some{cps_provider_4_Telescope{v_12, v_13, v_14, v_15}}:
      Some{cps_provider_4_Telescope{cps_provider_4_parameter(v_2, v_0, v_12), v_0 <> v_13, v_14, v_15}}

def cps_provider_4_prepare_law(v_0: Arena.Arena, v_1: IR.LawDecl, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case IR.LawDecl{v_15, v_16, v_17, _}:
      cps_provider_4_prepare_native_law(v_0, cps_provider_4_primitive(v_5, v_15), cps_provider_4_law_telescope(v_16, 0), Scope.lookup_kind(cps_provider_4_qualify(v_3, v_15), Scope.GlobalDefinition{}, v_6), cps_provider_4_qualify(v_3, v_15), v_17, v_6, v_8)

def cps_provider_4_prepare_native_law(v_0: Arena.Arena, v_2: Maybe<&2, BIR.Primitive>, v_5: Maybe<&2, cps_provider_4_Telescope>, v_7: Maybe<&2, Scope.ArenaGlobal>, v_9: String, v_11: U32, v_12: Scope.ArenaGlobalScope, v_14: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2, v_5:
    case None{}, _:
      cps_provider_4_CatalogResult{v_0, v_14}
    case Some{v_20}, None{}:
      cps_provider_4_CatalogResult{v_0, cps_provider_4_block_family(v_7, v_9, v_14)}
    case Some{v_27}, Some{cps_provider_4_Telescope{v_28, v_29, _, _}}:
      match v_7:
        case None{}:
          cps_provider_4_CatalogResult{v_0, cps_provider_4_preparation_failure(v_14, String.append("bend: missing published native law signature for ", v_9))}
        case Some{v_33}:
          match v_14:
            case cps_provider_4_Preparation{v_46, v_47, v_48, v_49, v_50, v_51, v_52, v_53, v_54, v_55, v_56, v_57}:
              v_60 = cps_provider_4_DefinitionHeader{cps_provider_4_signature_symbol(v_33), v_9, v_52, v_28, v_29, False{}, Some{v_27}, None{}, False{}}
              v_62 = cps_provider_4_Definition{v_60, IR.Words{0, 0}, IR.SomeTerm{v_11}, IR.DefTerm{v_11}, None{}, v_12, Some{v_9}, 0n}
              cps_provider_4_CatalogResult{v_0, cps_provider_4_Preparation{v_62 <> v_46, v_47, cps_provider_4_header_insert(v_9, v_60, v_48), v_49, v_50, v_51, U32.add(v_52, 1), v_53, v_54, v_55, v_56, v_57}}

def cps_provider_4_family_key(v_0: IR.TypeDecl, v_2: String) -> String:
  match v_0:
    case IR.TypeDecl{v_9, _, _, _, _}:
      cps_provider_4_qualify(v_2, v_9)

def cps_provider_4_native_match_prepare_declarations_0(v_1: List<&2, Checked.FamilyMetadata>, v_2: Arena.Arena, v_4: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case []:
      cps_provider_4_CatalogResult{v_2, v_4}
    case _ <> _:
      cps_provider_4_CatalogResult{v_2, cps_provider_4_preparation_failure(v_4, "bend: unmatched checked family metadata")}

def cps_provider_4_native_match_prepare_declarations_1(v_2: cps_provider_4_CatalogResult<cps_provider_4_Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: List<&2, IR.TopLevel>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2:
    case cps_provider_4_CatalogResult{v_18, v_19}:
      cps_provider_4_prepare_declarations(v_18, v_13, v_4, v_6, v_8, v_9, v_11, v_19)

def cps_provider_4_native_match_prepare_declarations_2(v_2: cps_provider_4_CatalogResult<cps_provider_4_Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, IR.TopLevel>, v_13: List<&2, Checked.FamilyMetadata>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2:
    case cps_provider_4_CatalogResult{v_18, v_19}:
      cps_provider_4_prepare_declarations(v_18, v_11, v_4, v_6, v_8, v_9, v_13, v_19)

def cps_provider_4_native_match_prepare_declarations_3(v_1: Bool, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: cps_provider_4_Preparation, v_12: IR.TypeDecl, v_14: List<&2, IR.TopLevel>, v_16: Nat, v_18: List<&2, Checked.FamilyMetadata>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case False{}:
      cps_provider_4_CatalogResult{v_2, cps_provider_4_preparation_failure(v_11, "bend: checked family metadata identity mismatch")}
    case True{}:
      cps_provider_4_native_match_prepare_declarations_2(cps_provider_4_prepare_family(v_2, v_12, v_4, v_8, v_9, v_16, v_11), v_4, v_6, v_8, v_9, v_14, v_18)

def cps_provider_4_native_match_prepare_declarations_4(v_1: List<&2, Checked.FamilyMetadata>, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: cps_provider_4_Preparation, v_12: IR.TypeDecl, v_14: List<&2, IR.TopLevel>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case []:
      cps_provider_4_CatalogResult{v_2, cps_provider_4_preparation_failure(v_11, "bend: missing checked family metadata")}
    case Checked.FamilyMetadata{v_21, v_22} <> v_23:
      cps_provider_4_native_match_prepare_declarations_3(String.eq(v_21, cps_provider_4_family_key(v_12, v_4)), v_2, v_4, v_6, v_8, v_9, v_11, v_12, v_14, v_22, v_23)

def cps_provider_4_native_match_prepare_declarations_5(v_2: cps_provider_4_CatalogResult<cps_provider_4_Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: List<&2, IR.TopLevel>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2:
    case cps_provider_4_CatalogResult{v_18, v_19}:
      cps_provider_4_prepare_declarations(v_18, v_13, v_4, v_6, v_8, v_9, v_11, v_19)

def cps_provider_4_native_match_prepare_declarations_6(v_1: List<&2, IR.TopLevel>, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case []:
      cps_provider_4_native_match_prepare_declarations_0(v_11, v_2, v_13)
    case IR.DefTop{v_19} <> v_20:
      cps_provider_4_native_match_prepare_declarations_1(cps_provider_4_prepare_definition(v_2, v_19, v_4, v_6, v_8, v_9, v_13), v_4, v_6, v_8, v_9, v_11, v_20)
    case IR.TypeTop{v_25} <> v_26:
      cps_provider_4_native_match_prepare_declarations_4(v_11, v_2, v_4, v_6, v_8, v_9, v_13, v_25, v_26)
    case IR.LawTop{v_30} <> v_31:
      cps_provider_4_native_match_prepare_declarations_5(cps_provider_4_prepare_law(v_2, v_30, v_4, v_8, v_9, v_13), v_4, v_6, v_8, v_9, v_11, v_31)

def cps_provider_4_prepare_declarations(v_0: Arena.Arena, v_2: List<&2, IR.TopLevel>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  cps_provider_4_native_match_prepare_declarations_6(v_2, v_0, v_4, v_6, v_8, v_9, v_11, v_13)

def cps_provider_4_reset_module(v_1: cps_provider_4_Preparation) -> cps_provider_4_Preparation:
  match v_1:
    case cps_provider_4_Preparation{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, _}:
      cps_provider_4_Preparation{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, MTip{}}

def cps_provider_4_native_match_prepare_modules_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Preparation>, v_4: Bool, v_6: List<&2, IR.LoadedModule>, v_8: List<&2, Checked.ModuleMetadata>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_2:
    case cps_provider_4_CatalogResult{v_13, v_14}:
      cps_provider_4_prepare_modules(v_13, v_6, v_8, v_4, v_14)

def cps_provider_4_native_match_prepare_modules_1(v_1: Bool, v_2: Arena.Arena, v_4: Bool, v_6: cps_provider_4_Preparation, v_8: String, v_10: String, v_12: List<&2, IR.TopLevel>, v_14: List<&2, IR.LoadedModule>, v_15: Scope.ArenaGlobalScope, v_17: List<&2, Checked.FamilyMetadata>, v_19: List<&2, Checked.ModuleMetadata>) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1:
    case False{}:
      cps_provider_4_CatalogResult{v_2, cps_provider_4_preparation_failure(v_6, "bend: checked module metadata identity mismatch")}
    case True{}:
      cps_provider_4_native_match_prepare_modules_0(cps_provider_4_prepare_declarations(v_2, v_12, v_8, v_10, cps_provider_4_base_source(v_10, v_4), v_15, v_17, cps_provider_4_reset_module(v_6)), v_4, v_14, v_19)

def cps_provider_4_native_match_prepare_modules_2(v_1: List<&2, IR.LoadedModule>, v_3: List<&2, Checked.ModuleMetadata>, v_4: Arena.Arena, v_6: Bool, v_8: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  match v_1, v_3:
    case [], []:
      cps_provider_4_CatalogResult{v_4, v_8}
    case IR.LoadedModule{v_21, IR.Module{v_22, _, v_24}} <> v_25, Checked.ModuleMetadata{v_26, v_27, v_28, v_29} <> v_30:
      cps_provider_4_native_match_prepare_modules_1(Bool.and(String.eq(v_21, v_26), String.eq(v_22, v_27)), v_4, v_6, v_8, v_21, v_22, v_24, v_25, v_28, v_29, v_30)
    case _, _:
      cps_provider_4_CatalogResult{v_4, cps_provider_4_preparation_failure(v_8, "bend: missing or unmatched checked module metadata")}

def cps_provider_4_prepare_modules(v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Checked.ModuleMetadata>, v_6: Bool, v_8: cps_provider_4_Preparation) -> cps_provider_4_CatalogResult<cps_provider_4_Preparation>:
  cps_provider_4_native_match_prepare_modules_2(v_2, v_4, v_0, v_6, v_8)

def native_match_cps_provider_4_ending_0(v_26: cps_provider_4_CatalogResult<List<&2, BIR.Export>>) -> cps_provider_4_CatalogResult<BIR.Ending>:
  match v_26:
    case cps_provider_4_CatalogResult{v_22, v_23}:
      cps_provider_4_CatalogResult{v_22, BIR.Library{v_23}}

def native_match_cps_provider_4_ending_1(v_5: Maybe<&2, BIR.Descriptor>, v_8: Arena.Arena) -> cps_provider_4_CatalogResult<BIR.Ending>:
  match v_5:
    case Some{v_25}:
      cps_provider_4_CatalogResult{v_8, BIR.Executable{v_25}}
    case None{}:
      cps_provider_4_CatalogResult{v_8, BIR.Executable{BIR.DescriptorNull{}}}

def native_match_cps_provider_4_ending_2(v_3: Maybe<&2, List<&2, String>>, v_5: Maybe<&2, BIR.Descriptor>, v_7: cps_provider_4_Registry, v_8: Arena.Arena, v_11: List<&2, cps_provider_4_Definition>, v_13: List<&2, Scope.ArenaGlobal>, +v_15: cps_provider_2_NfContext) -> cps_provider_4_CatalogResult<BIR.Ending>:
  match v_3:
    case Some{v_18}:
      native_match_cps_provider_4_ending_0(cps_provider_4_exports(v_18, v_7, v_8, v_11, v_13, v_15))
    case None{}:
      native_match_cps_provider_4_ending_1(v_5, v_8)

def cps_provider_4_ending(v_3: Maybe<&2, List<&2, String>>, v_5: Maybe<&2, BIR.Descriptor>, v_7: cps_provider_4_Registry, v_8: Arena.Arena, v_11: List<&2, cps_provider_4_Definition>, v_13: List<&2, Scope.ArenaGlobal>, +v_15: cps_provider_2_NfContext) -> cps_provider_4_CatalogResult<BIR.Ending>:
  native_match_cps_provider_4_ending_2(v_3, v_5, v_7, v_8, v_11, v_13, v_15)

def native_match_cps_provider_4_native_match_build_finish_0_0(v_56: cps_provider_4_CatalogResult<BIR.Ending>, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>, v_8: List<&2, Checked.ModuleMetadata>, v_20: List<&2, BIR.ConstructorLayout>, v_27: U32, v_35: List<&2, BIR.TypeFunction>, v_38: cps_provider_4_Registry, v_40: List<&2, BIR.Family>, v_46: List<&2, cps_provider_4_Definition>) -> cps_provider_4_BuildResult:
  match v_56:
    case cps_provider_4_CatalogResult{v_50, v_51}:
      v_54 = cps_provider_4_Catalog{List.reverse(&2, cps_provider_4_Definition, v_46), v_38, List.reverse(&2, BIR.ConstructorLayout, v_20), v_40, v_35, v_27, v_51}
      cps_provider_4_Built{Checked.CheckedProgram{v_50, v_4, v_6, v_8}, v_54}

def native_match_cps_provider_4_native_match_build_finish_0_1(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>, v_8: List<&2, Checked.ModuleMetadata>, v_12: Maybe<&2, List<&2, String>>, v_15: List<&2, cps_provider_4_Definition>, v_18: Map<&2, cps_provider_4_DefinitionHeader>, v_20: List<&2, BIR.ConstructorLayout>, v_23: Map<&2, cps_provider_4_Constructor>, v_25: List<&2, BIR.Family>, v_27: U32, v_29: Maybe<&2, BIR.Descriptor>) -> cps_provider_4_BuildResult:
  match v_2:
    case cps_provider_4_CatalogResult{v_34, cps_provider_4_Needed{v_35, _}}:
      v_38 = cps_provider_4_Registry{v_18, v_23}
      v_40 = List.reverse(&2, BIR.Family, v_25)
      v_43 = cps_provider_2_nf_context(v_40, v_35)
      v_46 = cps_provider_4_normalize_foreign_definitions(v_15, v_43)
      native_match_cps_provider_4_native_match_build_finish_0_0(cps_provider_4_ending(v_12, v_29, v_38, v_34, v_46, v_6, v_43), v_4, v_6, v_8, v_20, v_27, v_35, v_38, v_40, v_46)

def cps_provider_4_native_match_build_finish_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Needed>, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>, v_8: List<&2, Checked.ModuleMetadata>, v_12: Maybe<&2, List<&2, String>>, v_15: List<&2, cps_provider_4_Definition>, v_18: Map<&2, cps_provider_4_DefinitionHeader>, v_20: List<&2, BIR.ConstructorLayout>, v_23: Map<&2, cps_provider_4_Constructor>, v_25: List<&2, BIR.Family>, v_27: U32, v_29: Maybe<&2, BIR.Descriptor>) -> cps_provider_4_BuildResult:
  native_match_cps_provider_4_native_match_build_finish_0_1(v_2, v_4, v_6, v_8, v_12, v_15, v_18, v_20, v_23, v_25, v_27, v_29)

def cps_provider_4_native_match_build_finish_1(v_1: cps_provider_4_Preparation, v_2: Arena.Arena, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>, v_8: List<&2, Checked.ModuleMetadata>, v_12: Maybe<&2, List<&2, String>>) -> cps_provider_4_BuildResult:
  match v_1:
    case cps_provider_4_Preparation{v_25, v_26, v_27, v_28, v_29, v_30, v_31, _, v_33, v_34, None{}, _}:
      cps_provider_4_native_match_build_finish_0(cps_provider_4_needed_roots(v_2, List.reverse(&2, cps_provider_4_Root, v_33), v_26, cps_provider_4_Needed{[], MTip{}}), v_4, v_6, v_8, v_12, v_25, v_27, v_28, v_29, v_30, v_31, v_34)
    case cps_provider_4_Preparation{_, _, _, _, _, _, _, _, _, _, Some{v_61}, _}:
      cps_provider_4_BuildFailure{Checked.CheckedProgram{v_2, v_4, v_6, v_8}, v_61}

def cps_provider_4_build_finish(v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Scope.ArenaGlobal>, v_6: List<&2, Checked.ModuleMetadata>, v_10: Maybe<&2, List<&2, String>>, v_12: cps_provider_4_Preparation) -> cps_provider_4_BuildResult:
  cps_provider_4_native_match_build_finish_1(v_12, v_0, v_2, v_4, v_6, v_10)

def cps_provider_4_native_match_build_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Preparation>, v_6: Maybe<&2, List<&2, String>>, v_8: List<&2, IR.LoadedModule>, v_10: List<&2, Scope.ArenaGlobal>, v_12: List<&2, Checked.ModuleMetadata>) -> cps_provider_4_BuildResult:
  match v_2:
    case cps_provider_4_CatalogResult{v_16, v_17}:
      cps_provider_4_build_finish(v_16, v_8, v_10, v_12, v_6, v_17)

def cps_provider_4_native_match_build_1(v_0: Checked.CheckedProgram, v_4: Maybe<&2, List<&2, String>>) -> cps_provider_4_BuildResult:
  match v_0:
    case Checked.CheckedProgram{v_10, v_11, v_12, v_13}:
      v_15 = cps_provider_4_Preparation{[], MTip{}, MTip{}, [], MTip{}, [], 0, 0, [], None{}, None{}, MTip{}}
      cps_provider_4_native_match_build_0(cps_provider_4_prepare_modules(v_10, v_11, v_13, cps_provider_4_base_imported(v_11), v_15), v_4, v_11, v_12, v_13)

def cps_provider_4_build(v_0: Checked.CheckedProgram, v_4: Maybe<&2, List<&2, String>>) -> cps_provider_4_BuildResult:
  cps_provider_4_native_match_build_1(v_0, v_4)

def cps_provider_4_native_match_live_telescope_0(v_2: cps_provider_4_CatalogResult<cps_provider_4_Telescope>, v_4: U32, v_5: Arena.Binder) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_2:
    case cps_provider_4_CatalogResult{v_10, v_11}:
      cps_provider_4_CatalogResult{v_10, cps_provider_4_live_binder(v_5, v_4, v_11)}

def cps_provider_4_native_match_live_telescope_1(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_5: U32, v_7: U32, v_9: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_3:
    case (v_14, v_15):
      cps_provider_4_native_match_live_telescope_0(cps_provider_4_live_telescope(v_14, IR.Words{IR.arena_range_index(v_7, 1), U32.sub(v_9, 1)}, U32.add(v_5, 1)), v_5, v_15)

def cps_provider_4_native_match_live_telescope_2(v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_10: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_4:
    case (v_15, v_16):
      cps_provider_4_native_match_live_telescope_1(Arena.get_binder(v_15, v_16), v_6, v_8, v_10)

def cps_provider_4_native_match_live_telescope_3(v_0: IR.Words, v_1: Arena.Arena, v_3: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  match v_0:
    case IR.Words{_, 0}:
      cps_provider_4_CatalogResult{v_1, cps_provider_4_Telescope{[], [], [], True{}}}
    case IR.Words{v_10, v_11}:
      cps_provider_4_native_match_live_telescope_2(Arena.word(v_1, IR.arena_tape_offset(v_10)), v_3, v_10, v_11)

def cps_provider_4_live_telescope(v_0: Arena.Arena, v_1: IR.Words, v_3: U32) -> cps_provider_4_CatalogResult<cps_provider_4_Telescope>:
  cps_provider_4_native_match_live_telescope_3(v_1, v_0, v_3)

def cps_provider_4_live_binder(v_0: Arena.Binder, v_2: U32, v_4: cps_provider_4_Telescope) -> cps_provider_4_Telescope:
  match v_0, v_4:
    case Arena.Binder{v_15, _, _, _, _}, cps_provider_4_Telescope{v_20, v_21, v_22, v_23}:
      v_25 = cps_provider_4_quantity(v_15)
      cps_provider_4_Telescope{cps_provider_4_parameter(v_2, v_25, v_20), v_25 <> v_21, v_22, v_23}
    case Arena.TemplateBinder{_, _, _, _}, cps_provider_4_Telescope{v_39, v_40, v_41, _}:
      cps_provider_4_Telescope{v_39, BIR.Erased{} <> v_40, v_41, False{}}

def cps_provider_4_primitive_arity(v_0: BIR.Primitive) -> Nat:
  match v_0:
    case BIR.PrimU32Add{}:
      2n
    case BIR.PrimU32Sub{}:
      2n
    case BIR.PrimU32Mul{}:
      2n
    case BIR.PrimU32Div{}:
      2n
    case BIR.PrimNatAdd{}:
      2n
    case BIR.PrimNatSub{}:
      2n
    case BIR.PrimNatMul{}:
      2n
    case BIR.PrimNatCmp{}:
      2n
    case BIR.PrimNatMin{}:
      2n
    case BIR.PrimNatMax{}:
      2n
    case BIR.PrimStringAppend{}:
      2n
    case BIR.PrimBoolOr{}:
      2n
    case BIR.PrimBoolXor{}:
      2n
    case BIR.PrimU32IsZero{}:
      1n
    case BIR.PrimF32Asin{}:
      1n
    case BIR.PrimF32Acos{}:
      1n
    case BIR.PrimF32Atan{}:
      1n
    case BIR.PrimF32Sinh{}:
      1n
    case BIR.PrimF32Cosh{}:
      1n
    case BIR.PrimF32Tanh{}:
      1n
    case BIR.PrimU32Mod{}:
      2n
    case BIR.PrimU32And{}:
      2n
    case BIR.PrimU32Or{}:
      2n
    case BIR.PrimU32Xor{}:
      2n
    case BIR.PrimU32IsEq{}:
      2n
    case BIR.PrimU32IsNe{}:
      2n
    case BIR.PrimU32IsLt{}:
      2n
    case BIR.PrimU32IsLe{}:
      2n
    case BIR.PrimU32IsGt{}:
      2n
    case BIR.PrimU32IsGe{}:
      2n
    case BIR.PrimU32Inc{}:
      1n
    case BIR.PrimU32Not{}:
      1n
    case BIR.PrimU32Shl{}:
      1n
    case BIR.PrimU32Shr{}:
      1n
    case BIR.PrimU32Shln{}:
      2n
    case BIR.PrimU32Shrn{}:
      2n
    case BIR.PrimU32Cmp{}:
      2n
    case BIR.PrimU32ToNat{}:
      1n
    case BIR.PrimU32FromNat{}:
      1n
    case BIR.PrimF32Add{}:
      2n
    case BIR.PrimF32Sub{}:
      2n
    case BIR.PrimF32Mul{}:
      2n
    case BIR.PrimF32Div{}:
      2n
    case BIR.PrimF32Mod{}:
      2n
    case BIR.PrimF32Neg{}:
      1n
    case BIR.PrimF32Sqrt{}:
      1n
    case BIR.PrimF32Abs{}:
      1n
    case BIR.PrimF32ToU32{}:
      1n
    case BIR.PrimF32Bits{}:
      1n
    case BIR.PrimF32Show{}:
      1n
    case BIR.PrimF32Read{}:
      1n
    case BIR.PrimF32IsEq{}:
      2n
    case BIR.PrimF32IsNe{}:
      2n
    case BIR.PrimF32IsLt{}:
      2n
    case BIR.PrimF32IsLe{}:
      2n
    case BIR.PrimF32IsGt{}:
      2n
    case BIR.PrimF32IsGe{}:
      2n
    case BIR.PrimF32Pow{}:
      2n
    case BIR.PrimF32Atan2{}:
      2n
    case BIR.PrimF32Exp{}:
      1n
    case BIR.PrimF32Log{}:
      1n
    case BIR.PrimF32Log2{}:
      1n
    case BIR.PrimF32Log10{}:
      1n
    case BIR.PrimF32Sin{}:
      1n
    case BIR.PrimF32Cos{}:
      1n
    case BIR.PrimF32Tan{}:
      1n
    case BIR.PrimF32Floor{}:
      1n
    case BIR.PrimF32Ceil{}:
      1n
    case BIR.PrimF32Trunc{}:
      1n
    case BIR.PrimF32ToNat{}:
      1n
    case BIR.PrimU32ToF32{}:
      1n
    case BIR.PrimNatDouble{}:
      1n
    case BIR.PrimNatIsLt{}:
      2n
    case BIR.PrimNatDivmod{}:
      2n
    case BIR.PrimStringEq{}:
      2n
    case BIR.PrimMapBit{}:
      2n
    case BIR.PrimStringCmp{}:
      2n
    case BIR.PrimStringToList{}:
      1n
    case BIR.PrimStringLength{}:
      1n
    case BIR.PrimArrayNew{}:
      2n
    case BIR.PrimArraySet{}:
      3n
    case BIR.PrimArrayGet{}:
      2n
    case BIR.PrimArraySwap{}:
      3n
    case BIR.PrimArraySize{}:
      1n
    case BIR.PrimArrayClone{}:
      1n
    case BIR.PrimNatPredecessor{}:
      1n
    case BIR.PrimNatSuccessor{}:
      1n
    case BIR.PrimCharNew{}:
      1n
    case BIR.PrimCharCode{}:
      1n
    case BIR.PrimStringHead{}:
      1n
    case BIR.PrimStringTail{}:
      1n
    case BIR.PrimWordToU32{}:
      1n
    case BIR.PrimU32ToWord{}:
      1n
    case BIR.PrimF32FromBits{}:
      1n
    case BIR.PrimF32FromWord{}:
      1n
    case BIR.PrimF32ToWord{}:
      1n
    case BIR.PrimArrayLeaf{}:
      1n
    case BIR.PrimArrayNode{}:
      2n
    case BIR.PrimArrayLeafValue{}:
      1n
    case BIR.PrimArrayLeft{}:
      1n
    case BIR.PrimArrayRight{}:
      1n
    case BIR.PrimIsArrayLeaf{}:
      1n
    case BIR.PrimIsArrayNode{}:
      1n
    case BIR.PrimIsNatZero{}:
      1n
    case BIR.PrimIsNatSuccessor{}:
      1n
    case BIR.PrimIsStringEmpty{}:
      1n
    case BIR.PrimIsStringNonempty{}:
      1n
    case BIR.PrimIsTrue{}:
      1n
    case BIR.PrimIsFalse{}:
      1n
    case BIR.PrimSameValue{}:
      2n
    case BIR.PrimFloatBitsEqual{}:
      2n

def cps_provider_4_constructor_field(v_1: cps_provider_4_Constructor, v_3: U32) -> Maybe<&2, cps_provider_4_ConstructorField>:
  match v_1:
    case cps_provider_4_Constructor{BIR.ConstructorLayout{_, _, _, v_16}, v_17, _, _}:
      cps_provider_4_constructor_field_at(v_16, v_17, U32.to_nat(v_3), v_3)

def cps_provider_4_constructor_field_at(v_3: List<&2, Maybe<&2, String>>, v_5: List<&2, BIR.Quantity>, v_7: Nat, v_9: U32) -> Maybe<&2, cps_provider_4_ConstructorField>:
  match v_3, v_5, v_7:
    case v_16 <> _, v_18 <> _, 0n:
      Some{cps_provider_4_ConstructorField{v_9, v_16, v_18}}
    case _ <> v_26, _ <> v_28, 1n+v_29:
      cps_provider_4_constructor_field_at(v_26, v_28, v_29, v_9)
    case _, _, _:
      None{}

