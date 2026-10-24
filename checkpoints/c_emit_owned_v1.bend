import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/checked_frontend.bend as Checked
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checker_arena.bend as Arena
import ../bend2/selfhost/checker_ir.bend as IR
import ../bend2/selfhost/scope_lookup.bend as Scope
import ../bend2/selfhost/index_lookup.bend as IndexLookup
import ../bend2/selfhost/c_backend_link.bend as Link
import ./checker_core_owned_modules_v1/bend2/selfhost/c_backend_layout.bend as CLay
import ./checker_core_owned_modules_v1/bend2/selfhost/c_backend_physical.bend as Phys
import ../bend2/selfhost/c_backend_sharing.bend as Sharing
import ../bend2/selfhost/path.bend as Path

type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

type CImportPlan is Data:
  CImportPlan{path: String, namespace: String, span: Ast.SourceSpan}

type PlanResult is Data:
  PlanSuccess{imports: List<&2, CImportPlan>}
  PlanFailure{message: String, span: Ast.SourceSpan}

type cps_provider_2_CImport is Data:
  cps_provider_2_CImport{path: String, namespace: String, source: String}

type JoinResult is Data:
  JoinSuccess{imports: List<&2, cps_provider_2_CImport>}
  JoinFailure{message: String, span: Ast.SourceSpan}

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

type cps_provider_3_NfContext is Data:
  cps_provider_3_NfContext{families: Map<&2, BIR.Family>, type_functions: Map<&2, BIR.TypeFunction>}

type cps_provider_1_State is Type:
  cps_provider_1_State{source: Arena.Arena, next_code: U32, next_local: U32, frame: cps_provider_1_Frame, codes: List<&2, BIR.Code>, failure: Maybe<&2, cps_provider_1_Problem>, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, cps_provider_3_NfContext>}

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

type cps_provider_2_EmitResult is Data:
  cps_provider_2_EmitSuccess{source: String}
  cps_provider_2_EmitFailure{message: String}

type cps_provider_2_Part is Data:
  cps_provider_2_PartOk{text: String}
  cps_provider_2_PartFail{message: String}

type cps_provider_2_AppendTexts is Data:
  cps_provider_2_AppendTexts{parts: List<&2, String>, tail_use: Maybe<&2, BIR.Use>}

type cps_provider_2_CidRow is Data:
  cps_provider_2_CidRow{cid: U32, key: String, arity: Nat, hot: Bool}

type cps_provider_2_ExportRow is Data:
  cps_provider_2_ExportRow{name: String, index: U32, mode: Nat, arity: Nat}

type cps_provider_2_EntryKind is Data:
  cps_provider_2_KindCode{id: U32, captures: Nat, params: List<&2, BIR.Parameter>, body: BIR.Block}
  cps_provider_2_KindStage{next: U32}
  cps_provider_2_KindLazy{body: BIR.Block}
  cps_provider_2_KindForeign{key: String, args: Nat}
  cps_provider_2_KindNative{primitive: BIR.Primitive, count: Nat}
  cps_provider_2_KindMain{}
  cps_provider_2_KindLibrary{}
  cps_provider_2_KindEmit{}
  cps_provider_2_KindApply{}
  cps_provider_2_KindExit{}
  cps_provider_2_KindEnter{}

type cps_provider_2_Entry is Data:
  cps_provider_2_Entry{index: U32, arity: Nat, kind: cps_provider_2_EntryKind}

type cps_provider_2_Scan is Data:
  cps_provider_2_Scan{closures: Map<&2, Nat>, reads: Map<&2, Bool>, fkeys: List<&2, String>, farity: Map<&2, Nat>}

type cps_provider_2_Build is Data:
  cps_provider_2_Build{entries: List<&2, cps_provider_2_Entry>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, next: U32}

type cps_provider_2_Plan is Data:
  cps_provider_2_Plan{cids: List<&2, cps_provider_2_CidRow>, cid_macros: Map<&2, String>, fid_macros: Map<&2, String>, entries: List<&2, cps_provider_2_Entry>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, declarations: List<&2, BIR.Declaration>, main_pure: Bool, show_desc: String, show_names: String, imports: List<&2, cps_provider_2_CImport>, fkeys: List<&2, String>, ctx: CLay.Context, sharing: Sharing.SharingPlan, library: Bool, exports: List<&2, BIR.Export>}

type cps_provider_2_Sig is Data:
  cps_provider_2_Sig{entries: List<&2, cps_provider_2_Entry>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, declarations: List<&2, BIR.Declaration>, cids: List<&2, cps_provider_2_CidRow>, apply_fid: U32}

type cps_provider_2_PlanResult is Data:
  cps_provider_2_PlanOk{plan: cps_provider_2_Plan}
  cps_provider_2_PlanFail{message: String}

type cps_provider_2_Env is Data:
  cps_provider_2_Env{id: U32, expr: String}

type cps_provider_2_CapRef is Data:
  cps_provider_2_CapLocalRef{id: U32}
  cps_provider_2_CapSlotRef{slot: U32}

type cps_provider_2_Cap is Data:
  cps_provider_2_CapLocal{id: U32, expr: String}
  cps_provider_2_CapSlot{slot: U32, expr: String}

type cps_provider_2_Region is Data:
  cps_provider_2_Region{label: U32, fid: U32, refs: List<&2, cps_provider_2_CapRef>}

type cps_provider_2_SegText is Data:
  cps_provider_2_SegText{fid: U32, arity: Nat, resw: Nat, text: String}

type cps_provider_2_Ctx is Data:
  cps_provider_2_Ctx{sig: cps_provider_2_Sig, plan: cps_provider_2_Plan, env: List<&2, cps_provider_2_Env>, caps: List<&2, String>, caps_n: Nat, regions: List<&2, cps_provider_2_Region>, self_fid: Maybe<&2, U32>, next: U32, segs: List<&2, cps_provider_2_SegText>, outs: List<&2, String>, spin: Bool, max_arity: Nat}

type cps_provider_2_Step is Data:
  cps_provider_2_StepOk{text: String, ctx: cps_provider_2_Ctx}
  cps_provider_2_StepFail{message: String}

type cps_provider_2_Control is Data:
  cps_provider_2_ControlOk{segments: String, rows: List<&2, cps_provider_2_SegText>, max_arity: Nat}
  cps_provider_2_ControlFail{message: String}

type cps_provider_2_OperandsOut is Data:
  cps_provider_2_OperandsOk{operands: List<&2, Phys.Operand>}
  cps_provider_2_OperandsFail{message: String}

type cps_provider_3_NfVal is Data:
  cps_provider_3_NfType{key: String, args: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfCtor{key: String, args: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfQuantity{quantity: BIR.Quantity}
  cps_provider_3_NfKind{quantity: BIR.Descriptor}
  cps_provider_3_NfOther{source: BIR.Descriptor}
  cps_provider_3_NfMissing{source: BIR.Descriptor}
  cps_provider_3_NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, cps_provider_3_NfVal>, sources: List<&2, BIR.Descriptor>}

type cps_provider_3_NfBind is Data:
  cps_provider_3_NfBound{bindings: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfMismatch{}
  cps_provider_3_NfUnknown{}

type cps_provider_3_NfStatus is Data:
  cps_provider_3_NfStatusOk{}
  cps_provider_3_NfStatusNo{}
  cps_provider_3_NfStatusMaybe{}

type cps_provider_3_Nf is Data:
  cps_provider_3_NfOk{val: cps_provider_3_NfVal}
  cps_provider_3_NfFail{message: String}

type cps_provider_3_NfList is Data:
  cps_provider_3_NfListOk{vals: List<&2, cps_provider_3_NfVal>}
  cps_provider_3_NfListFail{message: String}

type cps_provider_3_NfApp is Data:
  cps_provider_3_NfApp{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_3_NfArity is Data:
  cps_provider_3_NfArity{complete: Bool, exact: Bool, under: Bool}

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

def no_span() -> Ast.SourceSpan:
  Ast.SpanOf{"", 0n, 0n}

def native_match_foreign_c_source_0(v_9: Bool, +v_7: String, v_8: List<&2, String>) -> Maybe<&2, String>:
  match v_9:
    case True{}:
      Some{v_7}
    case False{}:
      foreign_c_source(v_8)

def native_match_foreign_c_source_1(v_2: List<&2, String>) -> Maybe<&2, String>:
  match v_2:
    case []:
      None{}
    case +v_7 <> v_8:
      native_match_foreign_c_source_0(String.ends_with(v_7, ".c"), v_7, v_8)

def foreign_c_source(v_2: List<&2, String>) -> Maybe<&2, String>:
  native_match_foreign_c_source_1(v_2)

def plan_prepend(v_1: PlanResult, v_3: CImportPlan) -> PlanResult:
  match v_1:
    case PlanSuccess{v_6}:
      PlanSuccess{v_3 <> v_6}
    case PlanFailure{v_9, v_10}:
      PlanFailure{v_9, v_10}

def native_match_plan_add_0(v_20: Bool, +v_1: String, v_4: Ast.SourceSpan, v_7: List<&2, CImportPlan>) -> PlanResult:
  match v_20:
    case True{}:
      PlanSuccess{v_7}
    case False{}:
      PlanFailure{String.concat(["bend: ", v_1, " is imported from two foreign namespaces"]), v_4}

def native_match_plan_add_1(v_19: Bool, +v_1: String, +v_3: String, v_4: Ast.SourceSpan, v_7: List<&2, CImportPlan>, +v_11: CImportPlan, v_12: List<&2, CImportPlan>, v_17: String) -> PlanResult:
  match v_19:
    case True{}:
      native_match_plan_add_0(String.eq(v_3, v_17), v_1, v_4, v_7)
    case False{}:
      plan_prepend(plan_add(v_1, v_3, v_4, v_12), v_11)

def native_match_plan_add_2(+v_11: CImportPlan, +v_1: String, +v_3: String, v_4: Ast.SourceSpan, v_7: List<&2, CImportPlan>, v_12: List<&2, CImportPlan>) -> PlanResult:
  match v_11:
    case CImportPlan{+v_16, v_17, _}:
      native_match_plan_add_1(String.eq(v_1, v_16), v_1, v_3, v_4, v_7, v_11, v_12, v_17)

def native_match_plan_add_3(v_7: List<&2, CImportPlan>, +v_1: String, +v_3: String, v_4: Ast.SourceSpan) -> PlanResult:
  match v_7:
    case []:
      PlanSuccess{[CImportPlan{v_1, v_3, v_4}]}
    case +v_11 <> v_12:
      native_match_plan_add_2(v_11, v_1, v_3, v_4, v_7, v_12)

def plan_add(+v_1: String, +v_3: String, v_4: Ast.SourceSpan, v_7: List<&2, CImportPlan>) -> PlanResult:
  native_match_plan_add_3(v_7, v_1, v_3, v_4)

def native_match_plan_declaration_0(v_29: Maybe<&2, String>, +v_3: List<&2, CImportPlan>, v_15: String, v_16: String, v_20: Ast.SourceSpan) -> PlanResult:
  match v_29:
    case Some{v_25}:
      plan_add(v_25, v_15, v_20, v_3)
    case None{}:
      PlanFailure{String.append("bend: foreign definition has no .c import: ", v_16), v_20}

def native_match_plan_declaration_1(v_0: BIR.Declaration, +v_3: List<&2, CImportPlan>) -> PlanResult:
  match v_0:
    case BIR.ForeignDeclaration{_, v_15, v_16, _, v_18, _, v_20, _, _}:
      native_match_plan_declaration_0(foreign_c_source(v_18), v_3, v_15, v_16, v_20)
    case _:
      PlanSuccess{v_3}

def plan_declaration(v_0: BIR.Declaration, +v_3: List<&2, CImportPlan>) -> PlanResult:
  native_match_plan_declaration_1(v_0, v_3)

def native_match_plan_declarations_0(v_17: PlanResult, v_9: List<&2, BIR.Declaration>) -> PlanResult:
  match v_17:
    case PlanFailure{v_13, v_14}:
      PlanFailure{v_13, v_14}
    case PlanSuccess{v_16}:
      plan_declarations(v_9, v_16)

def native_match_plan_declarations_1(v_1: List<&2, BIR.Declaration>, +v_4: List<&2, CImportPlan>) -> PlanResult:
  match v_1:
    case []:
      PlanSuccess{v_4}
    case +v_8 <> v_9:
      native_match_plan_declarations_0(plan_declaration(v_8, v_4), v_9)

def plan_declarations(v_1: List<&2, BIR.Declaration>, +v_4: List<&2, CImportPlan>) -> PlanResult:
  native_match_plan_declarations_1(v_1, v_4)

def native_match_find_source_0(v_13: Bool, +v_1: String, +v_10: String, v_11: List<&2, BIR.SourceFile>) -> Maybe<&2, String>:
  match v_13:
    case True{}:
      Some{v_10}
    case False{}:
      find_source(v_1, v_11)

def native_match_find_source_1(v_3: List<&2, BIR.SourceFile>, +v_1: String) -> Maybe<&2, String>:
  match v_3:
    case []:
      None{}
    case BIR.SourceFile{+v_9, +v_10} <> v_11:
      native_match_find_source_0(String.eq(v_1, v_9), v_1, v_10, v_11)

def find_source(+v_1: String, v_3: List<&2, BIR.SourceFile>) -> Maybe<&2, String>:
  native_match_find_source_1(v_3, v_1)

def native_match_join_imports_0(v_23: Maybe<&2, String>, +v_4: List<&2, BIR.SourceFile>, v_7: List<&2, cps_provider_2_CImport>, v_13: List<&2, CImportPlan>, +v_17: String, v_18: String, v_19: Ast.SourceSpan) -> JoinResult:
  match v_23:
    case Some{v_22}:
      join_imports(v_13, v_4, cps_provider_2_CImport{v_17, v_18, v_22} <> v_7)
    case None{}:
      JoinFailure{String.append("bend: missing declared C target: ", v_17), v_19}

def native_match_join_imports_1(+v_12: CImportPlan, +v_4: List<&2, BIR.SourceFile>, v_7: List<&2, cps_provider_2_CImport>, v_13: List<&2, CImportPlan>) -> JoinResult:
  match v_12:
    case CImportPlan{+v_17, v_18, v_19}:
      native_match_join_imports_0(find_source(v_17, v_4), v_4, v_7, v_13, v_17, v_18, v_19)

def native_match_join_imports_2(v_2: List<&2, CImportPlan>, +v_4: List<&2, BIR.SourceFile>, v_7: List<&2, cps_provider_2_CImport>) -> JoinResult:
  match v_2:
    case []:
      JoinSuccess{List.reverse(&2, cps_provider_2_CImport, v_7)}
    case +v_12 <> v_13:
      native_match_join_imports_1(v_12, v_4, v_7, v_13)

def join_imports(v_2: List<&2, CImportPlan>, +v_4: List<&2, BIR.SourceFile>, v_7: List<&2, cps_provider_2_CImport>) -> JoinResult:
  native_match_join_imports_2(v_2, v_4, v_7)

def native_match_render_0(v_40: cps_provider_2_EmitResult) -> EmitResult:
  match v_40:
    case cps_provider_2_EmitSuccess{v_34}:
      EmitSuccess{v_34}
    case cps_provider_2_EmitFailure{v_36}:
      EmitFailure{v_36, no_span}

def native_match_render_1(v_39: JoinResult, v_0: BIR.Program, v_2: String) -> EmitResult:
  match v_39:
    case JoinFailure{v_28, v_29}:
      EmitFailure{v_28, v_29}
    case JoinSuccess{v_31}:
      native_match_render_0(cps_provider_2_emit(v_0, v_2, v_31))

def native_match_render_2(v_38: PlanResult, v_0: BIR.Program, v_2: String, v_4: List<&2, BIR.SourceFile>) -> EmitResult:
  match v_38:
    case PlanFailure{v_21, v_22}:
      EmitFailure{v_21, v_22}
    case PlanSuccess{v_24}:
      native_match_render_1(join_imports(v_24, v_4, []), v_0, v_2)

def native_match_render_3(v_0: BIR.Program, v_2: String, v_4: List<&2, BIR.SourceFile>) -> EmitResult:
  match v_0:
    case BIR.Program{_, v_13, _, _, _, _}:
      native_match_render_2(plan_declarations(v_13, []), v_0, v_2, v_4)

def render(v_0: BIR.Program, v_2: String, v_4: List<&2, BIR.SourceFile>) -> EmitResult:
  native_match_render_3(v_0, v_2, v_4)

def native_match_emit_0(v_13: cps_provider_1_ProgramResult, v_2: String, v_4: List<&2, BIR.SourceFile>) -> EmitResult:
  match v_13:
    case cps_provider_1_LowerFailure{v_9, v_10}:
      EmitFailure{v_9, v_10}
    case cps_provider_1_Lowered{v_12}:
      render(v_12, v_2, v_4)

def emit(v_0: Checked.CheckedProgram, v_2: String, v_4: List<&2, BIR.SourceFile>) -> EmitResult:
  native_match_emit_0(cps_provider_1_lower(v_0), v_2, v_4)

def native_match_emit_library_0(v_16: cps_provider_1_ProgramResult, v_5: String, v_7: List<&2, BIR.SourceFile>) -> EmitResult:
  match v_16:
    case cps_provider_1_LowerFailure{v_12, v_13}:
      EmitFailure{v_12, v_13}
    case cps_provider_1_Lowered{v_15}:
      render(v_15, v_5, v_7)

def emit_library(v_0: Checked.CheckedProgram, v_3: List<&2, String>, v_5: String, v_7: List<&2, BIR.SourceFile>) -> EmitResult:
  native_match_emit_library_0(cps_provider_1_lower_library(v_0, v_3), v_5, v_7)

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

def cps_provider_1_native_match_node_0(v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_5: U32, v_7: U32, v_9: cps_provider_1_Frame, v_11: List<&2, BIR.Code>, v_14: Maybe<&2, cps_provider_1_Problem>, v_16: Maybe<&2, Scope.ArenaGlobalScope>, v_18: Maybe<&2, cps_provider_3_NfContext>) -> cps_provider_1_LowerResult<Arena.Node>:
  match v_3:
    case (v_22, v_23):
      cps_provider_1_LowerResult{cps_provider_1_State{v_22, v_5, v_7, v_9, v_11, v_14, v_16, v_18}, v_23}

def cps_provider_1_native_match_node_1(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<Arena.Node>:
  match v_1:
    case cps_provider_1_State{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20}:
      cps_provider_1_native_match_node_0(Arena.get_node(v_13, v_3), v_14, v_15, v_16, v_17, v_18, v_19, v_20)

def cps_provider_1_node(v_1: cps_provider_1_State, v_3: U32) -> cps_provider_1_LowerResult<Arena.Node>:
  cps_provider_1_native_match_node_1(v_1, v_3)

def cps_provider_1_native_match_name_0(v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_6: U32, v_8: U32, v_10: cps_provider_1_Frame, v_12: List<&2, BIR.Code>, v_15: Maybe<&2, cps_provider_1_Problem>, v_17: Maybe<&2, Scope.ArenaGlobalScope>, v_19: Maybe<&2, cps_provider_3_NfContext>) -> cps_provider_1_LowerResult<String>:
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

def cps_provider_1_resolve_capture(v_2: Maybe<&2, U32>, v_3: Arena.Arena, v_5: U32, v_7: U32, v_9: U32, v_12: List<&2, cps_provider_1_Instruction>, v_15: List<&2, cps_provider_1_Capture>, v_17: U32, v_19: List<&2, BIR.Code>, v_22: Maybe<&2, cps_provider_1_Problem>, v_24: cps_provider_1_Slot, v_26: Maybe<&2, Scope.ArenaGlobalScope>, v_28: Maybe<&2, cps_provider_3_NfContext>) -> cps_provider_1_LowerResult<BIR.Atom>:
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

def cps_provider_1_native_match_bind_slot_0(v_1: cps_provider_1_Frame, v_2: BIR.Atom, v_3: BIR.Use, v_5: U32, v_6: Arena.Arena, v_8: U32, v_10: U32, v_12: List<&2, BIR.Code>, v_15: Maybe<&2, cps_provider_1_Problem>, v_17: Maybe<&2, Scope.ArenaGlobalScope>, v_19: Maybe<&2, cps_provider_3_NfContext>) -> cps_provider_1_LowerResult<cps_provider_1_Slot>:
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

def native_match_cps_provider_1_describe_0(v_38: cps_provider_4_CatalogResult<BIR.Descriptor>, v_15: U32, v_16: U32, v_17: cps_provider_1_Frame, v_18: List<&2, BIR.Code>, v_19: Maybe<&2, cps_provider_1_Problem>, v_24: Scope.ArenaGlobalScope, +v_25: cps_provider_3_NfContext) -> cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>:
  match v_38:
    case cps_provider_4_CatalogResult{v_29, v_30}:
      cps_provider_1_LowerResult{cps_provider_1_State{v_29, v_15, v_16, v_17, v_18, v_19, Some{v_24}, Some{v_25}}, Some{cps_provider_3_normalize_in(v_25, v_30)}}

def native_match_cps_provider_1_describe_1(+v_20: Maybe<&2, Scope.ArenaGlobalScope>, +v_21: Maybe<&2, cps_provider_3_NfContext>, v_3: U32, v_14: Arena.Arena, v_15: U32, v_16: U32, v_17: cps_provider_1_Frame, v_18: List<&2, BIR.Code>, v_19: Maybe<&2, cps_provider_1_Problem>) -> cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>:
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
      v_30 = cps_provider_1_State{v_18, v_27, 0, cps_provider_1_Frame{0, [], [], 0}, [], None{}, None{}, Some{cps_provider_3_nf_context(v_25, v_26)}}
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

def cps_provider_2_build_new() -> cps_provider_2_Build:
  cps_provider_2_Build{[], Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), 0}

def cps_provider_2_build_entries(v_0: BIR.Program, +v_2: cps_provider_2_Scan) -> cps_provider_2_Build:
  match v_0:
    case BIR.Program{v_10, +v_11, v_12, v_13, v_14, v_15}:
      cps_provider_2_build_foreign(v_2, cps_provider_2_build_native(v_2, v_11, cps_provider_2_build_lazy(v_11, cps_provider_2_build_codes(v_10, v_11, v_2, cps_provider_2_build_new))))

def cps_provider_2_build_codes(v_1: List<&2, BIR.Code>, +v_3: List<&2, BIR.Declaration>, +v_5: cps_provider_2_Scan, +v_7: cps_provider_2_Build) -> cps_provider_2_Build:
  match v_1:
    case []:
      v_7
    case +v_11 <> v_12:
      match v_11:
        case BIR.Code{v_17, v_18, v_19, v_20}:
          cps_provider_2_build_codes(v_12, v_3, v_5, cps_provider_2_build_one_code(v_3, v_5, v_7, v_17, List.length(&2, BIR.Use, v_18), v_19, v_20))

def cps_provider_2_code_key(v_1: List<&2, BIR.Declaration>, +v_3: U32) -> Maybe<&2, String>:
  match v_1:
    case []:
      None{}
    case +v_8 <> v_9:
      match v_8:
        case BIR.FunctionDeclaration{v_13, v_14, v_15}:
          cps_provider_2_code_key_one(U32.is_eq(v_14, v_3), v_13, v_9, v_3)
        case _:
          cps_provider_2_code_key(v_9, v_3)

def cps_provider_2_code_key_one(v_1: Bool, v_3: String, v_5: List<&2, BIR.Declaration>, v_7: U32) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_2_code_key(v_5, v_7)

def cps_provider_2_scan_reads(v_1: cps_provider_2_Scan) -> Map<&2, Bool>:
  match v_1:
    case cps_provider_2_Scan{v_8, v_9, v_10, v_11}:
      v_9

def cps_provider_2_scan_closures(v_1: cps_provider_2_Scan) -> Map<&2, Nat>:
  match v_1:
    case cps_provider_2_Scan{v_8, v_9, v_10, v_11}:
      v_8

def cps_provider_2_code_stem(v_1: U32) -> String:
  String.append("c", U32.show(v_1))

def cps_provider_2_native_stem(v_1: String) -> String:
  String.append("n", v_1)

def cps_provider_2_foreign_stem(v_1: String) -> String:
  String.append("f", v_1)

def cps_provider_2_stage_key(v_1: String, v_3: Nat) -> String:
  String.concat([v_1, ":", Nat.show(v_3)])

def native_match_cps_provider_2_code_stage_start_0(v_14: Bool, +v_3: cps_provider_2_Scan, +v_5: U32, +v_7: Nat) -> Nat:
  match v_14:
    case True{}:
      0n
    case False{}:
      cps_provider_2_stage_from_closures(v_3, v_5, v_7)

def native_match_cps_provider_2_code_stage_start_1(v_13: Maybe<&2, String>, +v_3: cps_provider_2_Scan, +v_5: U32, +v_7: Nat) -> Nat:
  match v_13:
    case None{}:
      cps_provider_2_stage_from_closures(v_3, v_5, v_7)
    case Some{v_12}:
      native_match_cps_provider_2_code_stage_start_0(cps_provider_2_map_flag(cps_provider_2_scan_reads(v_3), v_12), v_3, v_5, v_7)

def cps_provider_2_code_stage_start(v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Scan, +v_5: U32, +v_7: Nat) -> Nat:
  native_match_cps_provider_2_code_stage_start_1(cps_provider_2_code_key(v_1, v_5), v_3, v_5, v_7)

def native_match_cps_provider_2_stage_from_closures_0(v_11: Maybe<&2, Nat>, +v_5: Nat) -> Nat:
  match v_11:
    case Some{v_10}:
      cps_provider_2_nat_min(v_10, v_5)
    case None{}:
      v_5

def cps_provider_2_stage_from_closures(v_1: cps_provider_2_Scan, v_3: U32, +v_5: Nat) -> Nat:
  native_match_cps_provider_2_stage_from_closures_0(IndexLookup.find(Nat, cps_provider_2_scan_closures(v_1), U32.show(v_3)), v_5)

def cps_provider_2_build_one_code(v_1: List<&2, BIR.Declaration>, v_3: cps_provider_2_Scan, v_5: cps_provider_2_Build, +v_7: U32, +v_9: Nat, +v_11: List<&2, BIR.Parameter>, v_12: BIR.Block) -> cps_provider_2_Build:
  +v_15 = Nat.add(v_9, List.length(&2, BIR.Parameter, v_11))
  v_18 = cps_provider_2_code_stage_start(v_1, v_3, v_7, v_15)
  cps_provider_2_build_with_code(cps_provider_2_stage_code(v_5, cps_provider_2_code_stem(v_7), v_18, v_15, v_7, v_9, v_11, v_12), v_7)

def cps_provider_2_stage_code(v_1: cps_provider_2_Build, v_3: String, v_5: Nat, v_7: Nat, v_9: U32, v_11: Nat, v_13: List<&2, BIR.Parameter>, v_14: BIR.Block) -> cps_provider_2_Build:
  cps_provider_2_build_staged(v_1, v_3, v_5, v_7, cps_provider_2_KindCode{v_9, v_11, v_13, v_14})

def native_match_cps_provider_2_build_staged_0(+v_1: cps_provider_2_Build, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_2_EntryKind) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Build{v_18, v_19, v_20, v_21, v_22, v_23, +v_24}:
      v_28 = Map.set(&2, U32, v_23, cps_provider_2_stage_key(v_3, v_5), v_24)
      cps_provider_2_build_staged(cps_provider_2_Build{cps_provider_2_Entry{v_24, Nat.add(v_5, 1n), cps_provider_2_KindStage{U32.inc(v_24)}} <> v_18, v_19, v_20, v_21, v_22, v_28, U32.inc(v_24)}, v_3, Nat.add(v_5, 1n), v_7, v_9)

def native_match_cps_provider_2_build_staged_1(v_29: Bool, +v_1: cps_provider_2_Build, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_2_EntryKind) -> cps_provider_2_Build:
  match v_29:
    case True{}:
      native_match_cps_provider_2_build_staged_0(v_1, v_3, v_5, v_7, v_9)
    case False{}:
      cps_provider_2_build_entry(v_1, v_9)

def cps_provider_2_build_staged(+v_1: cps_provider_2_Build, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_2_EntryKind) -> cps_provider_2_Build:
  native_match_cps_provider_2_build_staged_1(Nat.is_lt(v_5, Nat.sub(v_7, 1n)), v_1, v_3, v_5, v_7, v_9)

def cps_provider_2_entry_kind_arity(v_1: cps_provider_2_EntryKind) -> Nat:
  match v_1:
    case cps_provider_2_KindCode{v_7, v_8, v_9, v_10}:
      Nat.add(v_8, List.length(&2, BIR.Parameter, v_9))
    case cps_provider_2_KindStage{v_12}:
      0n
    case cps_provider_2_KindLazy{v_14}:
      0n
    case cps_provider_2_KindForeign{v_17, v_18}:
      Nat.add(v_18, 1n)
    case cps_provider_2_KindNative{v_21, v_22}:
      v_22
    case cps_provider_2_KindMain{}:
      0n
    case cps_provider_2_KindLibrary{}:
      0n
    case cps_provider_2_KindEmit{}:
      1n
    case cps_provider_2_KindApply{}:
      2n
    case cps_provider_2_KindExit{}:
      0n
    case cps_provider_2_KindEnter{}:
      0n

def cps_provider_2_build_entry(v_1: cps_provider_2_Build, +v_3: cps_provider_2_EntryKind) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Build{v_12, v_13, v_14, v_15, v_16, v_17, +v_18}:
      cps_provider_2_Build{cps_provider_2_Entry{v_18, cps_provider_2_entry_kind_arity(v_3), v_3} <> v_12, v_13, v_14, v_15, v_16, v_17, U32.inc(v_18)}

def cps_provider_2_build_with_code(v_1: cps_provider_2_Build, v_3: U32) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Build{v_12, v_13, v_14, v_15, v_16, v_17, +v_18}:
      cps_provider_2_Build{v_12, Map.set(&2, U32, v_13, U32.show(v_3), U32.sub(v_18, 1)), v_14, v_15, v_16, v_17, v_18}

def cps_provider_2_build_with_key(v_1: cps_provider_2_Build, v_3: String) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Build{v_12, v_13, v_14, v_15, v_16, v_17, +v_18}:
      cps_provider_2_Build{v_12, v_13, Map.set(&2, U32, v_14, v_3, U32.sub(v_18, 1)), v_15, v_16, v_17, v_18}

def cps_provider_2_build_with_foreign(v_1: cps_provider_2_Build, v_3: String) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Build{v_12, v_13, v_14, v_15, v_16, v_17, +v_18}:
      cps_provider_2_Build{v_12, v_13, v_14, Map.set(&2, U32, v_15, v_3, U32.sub(v_18, 1)), v_16, v_17, v_18}

def cps_provider_2_build_with_native(v_1: cps_provider_2_Build, v_3: String) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Build{v_12, v_13, v_14, v_15, v_16, v_17, +v_18}:
      cps_provider_2_Build{v_12, v_13, v_14, v_15, Map.set(&2, U32, v_16, v_3, U32.sub(v_18, 1)), v_17, v_18}

def cps_provider_2_build_lazy(v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Build) -> cps_provider_2_Build:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      match v_7:
        case BIR.LazyDeclaration{v_11, v_12}:
          cps_provider_2_build_lazy(v_8, cps_provider_2_build_with_key(cps_provider_2_build_entry(v_3, cps_provider_2_KindLazy{v_12}), v_11))
        case _:
          cps_provider_2_build_lazy(v_8, v_3)

def cps_provider_2_live_quantities(v_1: List<&2, BIR.Quantity>, +v_3: Nat) -> Nat:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      cps_provider_2_live_quantities(v_8, cps_provider_2_live_quantity_next(v_7, v_3))

def cps_provider_2_live_quantity_next(v_0: BIR.Quantity, +v_2: Nat) -> Nat:
  match v_0:
    case BIR.Erased{}:
      v_2
    case _:
      Nat.add(v_2, 1n)

def cps_provider_2_build_native(+v_1: cps_provider_2_Scan, v_3: List<&2, BIR.Declaration>, +v_5: cps_provider_2_Build) -> cps_provider_2_Build:
  match v_3:
    case []:
      v_5
    case +v_9 <> v_10:
      match v_9:
        case BIR.NativeDeclaration{v_14, v_15, v_16}:
          cps_provider_2_build_native_one(v_10, v_1, v_5, v_14, v_15, cps_provider_2_live_quantities(v_16, 0n))
        case _:
          cps_provider_2_build_native(v_1, v_10, v_5)

def native_match_cps_provider_2_build_native_one_0(v_11: Bool, +v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Scan, +v_5: cps_provider_2_Build, +v_7: String, v_8: BIR.Primitive, +v_10: Nat) -> cps_provider_2_Build:
  match v_11:
    case False{}:
      cps_provider_2_build_native(v_3, v_1, v_5)
    case True{}:
      cps_provider_2_build_native(v_3, v_1, cps_provider_2_build_with_native(cps_provider_2_stage_native(v_5, cps_provider_2_native_stem(v_7), v_10, v_8), v_7))

def cps_provider_2_build_native_one(+v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Scan, +v_5: cps_provider_2_Build, +v_7: String, v_8: BIR.Primitive, +v_10: Nat) -> cps_provider_2_Build:
  native_match_cps_provider_2_build_native_one_0(Bool.and(cps_provider_2_map_flag(cps_provider_2_scan_reads(v_3), v_7), Nat.is_gt(v_10, 0n)), v_1, v_3, v_5, v_7, v_8, v_10)

def cps_provider_2_stage_native(v_1: cps_provider_2_Build, v_3: String, +v_5: Nat, v_6: BIR.Primitive) -> cps_provider_2_Build:
  cps_provider_2_build_staged(v_1, v_3, 0n, v_5, cps_provider_2_KindNative{v_6, v_5})

def cps_provider_2_build_foreign(v_1: cps_provider_2_Scan, v_3: cps_provider_2_Build) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Scan{v_9, v_10, v_11, v_12}:
      cps_provider_2_build_foreign_each(v_11, v_12, v_10, v_3)

def cps_provider_2_build_foreign_each(v_2: List<&2, String>, +v_5: Map<&2, Nat>, +v_8: Map<&2, Bool>, +v_10: cps_provider_2_Build) -> cps_provider_2_Build:
  match v_2:
    case []:
      v_10
    case +v_14 <> v_15:
      +v_18 = cps_provider_2_map_nat(v_5, v_14)
      +v_20 = Nat.add(v_18, 1n)
      v_24 = cps_provider_2_foreign_stage_start(cps_provider_2_map_flag(v_8, v_14), v_20)
      cps_provider_2_build_foreign_each(v_15, v_5, v_8, cps_provider_2_build_with_foreign(cps_provider_2_stage_foreign(v_10, cps_provider_2_foreign_stem(v_14), v_24, v_20, v_14, v_18), v_14))

def cps_provider_2_stage_foreign(v_1: cps_provider_2_Build, v_3: String, v_5: Nat, v_7: Nat, v_9: String, v_11: Nat) -> cps_provider_2_Build:
  cps_provider_2_build_staged(v_1, v_3, v_5, v_7, cps_provider_2_KindForeign{v_9, v_11})

def cps_provider_2_foreign_stage_start(v_1: Bool, v_3: Nat) -> Nat:
  match v_1:
    case True{}:
      0n
    case False{}:
      v_3

def cps_provider_2_finish_entries(v_1: cps_provider_2_Build, v_3: Bool) -> cps_provider_2_Build:
  match v_1:
    case cps_provider_2_Build{v_12, v_13, v_14, v_15, v_16, v_17, +v_18}:
      v_20 = U32.inc(U32.inc(U32.inc(U32.inc(U32.inc(v_18)))))
      cps_provider_2_Build{cps_provider_2_finish_top(cps_provider_2_Entry{v_18, 0n, cps_provider_2_top_entry_kind(v_3)}, cps_provider_2_Entry{U32.inc(v_18), 1n, cps_provider_2_KindEmit{}}, cps_provider_2_Entry{U32.inc(U32.inc(v_18)), 2n, cps_provider_2_KindApply{}}, cps_provider_2_Entry{U32.inc(U32.inc(U32.inc(v_18))), 0n, cps_provider_2_KindExit{}}, cps_provider_2_Entry{U32.inc(U32.inc(U32.inc(U32.inc(v_18)))), 0n, cps_provider_2_KindEnter{}}, v_12), v_13, v_14, v_15, v_16, v_17, v_20}

def cps_provider_2_top_entry_kind(v_1: Bool) -> cps_provider_2_EntryKind:
  match v_1:
    case True{}:
      cps_provider_2_KindLibrary{}
    case False{}:
      cps_provider_2_KindMain{}

def cps_provider_2_finish_top(v_1: cps_provider_2_Entry, v_3: cps_provider_2_Entry, v_5: cps_provider_2_Entry, v_7: cps_provider_2_Entry, v_9: cps_provider_2_Entry, v_12: List<&2, cps_provider_2_Entry>) -> List<&2, cps_provider_2_Entry>:
  v_9 <> v_7 <> v_5 <> v_3 <> v_1 <> v_12

def cps_provider_2_entries_ascending(v_2: List<&2, cps_provider_2_Entry>) -> List<&2, cps_provider_2_Entry>:
  List.reverse(&2, cps_provider_2_Entry, v_2)

def cps_provider_2_fid_macro_map(v_1: List<&2, BIR.Declaration>, v_3: cps_provider_2_Build) -> Map<&2, String>:
  match v_3:
    case cps_provider_2_Build{v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      cps_provider_2_fid_macros_runtime(cps_provider_2_fid_macros_declarations(v_1, v_14, v_15, v_16, v_17, Map.new(&2, String)))

def native_match_cps_provider_2_fid_macros_declarations_0(v_78: Maybe<&2, U32>, +v_4: Map<&2, U32>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, String>, v_22: List<&2, BIR.Declaration>, +v_66: String) -> Map<&2, String>:
  match v_78:
    case Some{v_71}:
      cps_provider_2_fid_macros_declarations(v_22, v_4, v_7, v_10, v_13, cps_provider_2_map_set_first(v_16, v_66, cps_provider_2_fid_symbol(v_71)))
    case None{}:
      cps_provider_2_fid_macros_declarations(v_22, v_4, v_7, v_10, v_13, v_16)

def native_match_cps_provider_2_fid_macros_declarations_1(+v_21: BIR.Declaration, +v_4: Map<&2, U32>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, String>, v_22: List<&2, BIR.Declaration>) -> Map<&2, String>:
  match v_21:
    case BIR.FunctionDeclaration{v_26, v_27, v_28}:
      cps_provider_2_fid_macros_declarations(v_22, v_4, v_7, v_10, v_13, cps_provider_2_map_set_first(v_16, v_26, cps_provider_2_fid_symbol(cps_provider_2_map_u32(v_4, U32.show(v_27)))))
    case BIR.LazyDeclaration{+v_35, v_36}:
      cps_provider_2_fid_macros_declarations(v_22, v_4, v_7, v_10, v_13, cps_provider_2_map_set_first(v_16, v_35, cps_provider_2_fid_symbol(cps_provider_2_map_u32(v_7, v_35))))
    case BIR.ForeignDeclaration{+v_50, _, _, v_53, _, _, _, _, _}:
      cps_provider_2_fid_macros_declarations(v_22, v_4, v_7, v_10, v_13, cps_provider_2_map_set_first(v_16, v_50, cps_provider_2_fid_symbol(cps_provider_2_map_u32(v_10, v_50))))
    case BIR.NativeDeclaration{+v_66, v_67, v_68}:
      native_match_cps_provider_2_fid_macros_declarations_0(IndexLookup.find(U32, v_13, v_66), v_4, v_7, v_10, v_13, v_16, v_22, v_66)
    case _:
      cps_provider_2_fid_macros_declarations(v_22, v_4, v_7, v_10, v_13, v_16)

def native_match_cps_provider_2_fid_macros_declarations_2(v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, U32>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, String>) -> Map<&2, String>:
  match v_1:
    case []:
      v_16
    case +v_21 <> v_22:
      native_match_cps_provider_2_fid_macros_declarations_1(v_21, v_4, v_7, v_10, v_13, v_16, v_22)

def cps_provider_2_fid_macros_declarations(v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, U32>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, String>) -> Map<&2, String>:
  native_match_cps_provider_2_fid_macros_declarations_2(v_1, v_4, v_7, v_10, v_13, v_16)

def cps_provider_2_ending_library(v_0: BIR.Ending) -> Bool:
  match v_0:
    case BIR.Library{v_3}:
      True{}
    case BIR.Executable{v_5}:
      False{}

def cps_provider_2_ending_exports(v_0: BIR.Ending) -> List<&2, BIR.Export>:
  match v_0:
    case BIR.Library{v_3}:
      v_3
    case BIR.Executable{v_5}:
      []

def native_match_cps_provider_2_plan_make_0(+v_0: BIR.Program, v_3: List<&2, cps_provider_2_CImport>, +v_7: cps_provider_2_Scan, v_13: Sharing.SharingPlan, v_16: List<&2, cps_provider_2_CidRow>) -> cps_provider_2_PlanResult:
  match v_0:
    case BIR.Program{v_23, v_24, v_25, v_26, v_27, v_28}:
      cps_provider_2_plan_finish(v_0, v_7, v_16, v_25, v_26, v_24, v_28, v_3, v_13)

def native_match_cps_provider_2_plan_make_1(v_9: Sharing.SharingResult, +v_0: BIR.Program, v_3: List<&2, cps_provider_2_CImport>, +v_7: cps_provider_2_Scan) -> cps_provider_2_PlanResult:
  match v_9:
    case Sharing.SharingFail{v_11}:
      cps_provider_2_PlanFail{v_11}
    case Sharing.SharingOk{v_13}:
      v_16 = cps_provider_2_cid_rows(v_0, v_7, v_13)
      native_match_cps_provider_2_plan_make_0(v_0, v_3, v_7, v_13, v_16)

def cps_provider_2_plan_make(+v_0: BIR.Program, v_3: List<&2, cps_provider_2_CImport>) -> cps_provider_2_PlanResult:
  +v_7 = cps_provider_2_scan_program(v_0)
  v_9 = Sharing.sharing_plan(v_0)
  native_match_cps_provider_2_plan_make_1(v_9, v_0, v_3, v_7)

def cps_provider_2_plan_finish(v_0: BIR.Program, v_2: cps_provider_2_Scan, v_5: List<&2, cps_provider_2_CidRow>, v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, v_11: List<&2, BIR.Declaration>, +v_12: BIR.Ending, v_15: List<&2, cps_provider_2_CImport>, v_16: Sharing.SharingPlan) -> cps_provider_2_PlanResult:
  cps_provider_2_plan_pure(v_12, v_9, cps_provider_2_plan_top(v_0, v_2, v_5, v_7, v_9, v_11, v_12, v_15, v_16))

def cps_provider_2_plan_top(+v_0: BIR.Program, +v_2: cps_provider_2_Scan, +v_5: List<&2, cps_provider_2_CidRow>, v_7: List<&2, BIR.ConstructorLayout>, v_9: List<&2, BIR.Family>, +v_11: List<&2, BIR.Declaration>, v_12: BIR.Ending, v_15: List<&2, cps_provider_2_CImport>, v_16: Sharing.SharingPlan) -> cps_provider_2_PlanResult:
  +v_20 = cps_provider_2_ending_library(v_12)
  +v_23 = cps_provider_2_ending_exports(v_12)
  +v_27 = cps_provider_2_finish_entries(cps_provider_2_build_entries(v_0, v_2), v_20)
  cps_provider_2_PlanOk{cps_provider_2_Plan{v_5, cps_provider_2_cid_macro_map(v_5), cps_provider_2_fid_macro_map(v_11, v_27), cps_provider_2_entries_ascending(cps_provider_2_build_entries_of(v_27)), cps_provider_2_by_code_of(v_27), cps_provider_2_by_key_of(v_27), cps_provider_2_by_foreign_of(v_27), cps_provider_2_by_native_of(v_27), cps_provider_2_stages_of(v_27), v_7, v_9, v_11, True{}, "{ 0 }", "", v_15, cps_provider_2_fkeys_of(v_2), CLay.context(v_0), v_16, v_20, v_23}}

def cps_provider_2_plan_pure(v_0: BIR.Ending, v_2: List<&2, BIR.Family>, v_4: cps_provider_2_PlanResult) -> cps_provider_2_PlanResult:
  match v_4:
    case cps_provider_2_PlanFail{v_7}:
      cps_provider_2_PlanFail{v_7}
    case cps_provider_2_PlanOk{v_9}:
      cps_provider_2_plan_set_pure(v_0, v_2, v_9)

def cps_provider_2_plan_set_pure(v_0: BIR.Ending, v_2: List<&2, BIR.Family>, v_4: cps_provider_2_Plan) -> cps_provider_2_PlanResult:
  match v_0:
    case BIR.Library{v_7}:
      cps_provider_2_plan_library(v_7, v_4)
    case BIR.Executable{v_10}:
      cps_provider_2_plan_executable(v_10, v_4)

def cps_provider_2_plan_set_pure_flags(v_1: cps_provider_2_Plan, v_3: Bool, v_5: String, v_7: String) -> cps_provider_2_Plan:
  match v_1:
    case cps_provider_2_Plan{v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50}:
      cps_provider_2_Plan{v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_3, v_5, v_7, v_45, v_46, v_47, v_48, v_49, v_50}

def cps_provider_2_fid_macros_runtime(v_2: Map<&2, String>) -> Map<&2, String>:
  cps_provider_2_fid_macros_runtime_one(cps_provider_2_map_set_first(v_2, "Clo~apply", "FID_CLO_APPLY"))

def cps_provider_2_fid_macros_runtime_one(v_2: Map<&2, String>) -> Map<&2, String>:
  cps_provider_2_map_set_first(v_2, "IO~emit", "FID_IO_EMIT")

def native_match_cps_provider_2_plan_executable_0(v_55: CLay.HeadResult, +v_0: BIR.Descriptor, v_2: cps_provider_2_Plan) -> cps_provider_2_PlanResult:
  match v_55:
    case CLay.HeadFailed{v_47}:
      cps_provider_2_PlanFail{v_47}
    case CLay.HeadBoxed{v_49}:
      cps_provider_2_plan_executable_show(v_0, v_2)
    case CLay.HeadFound{v_53, v_54}:
      cps_provider_2_plan_executable_native(v_54, v_0, v_2)

def native_match_cps_provider_2_plan_executable_1(v_2: cps_provider_2_Plan, +v_0: BIR.Descriptor) -> cps_provider_2_PlanResult:
  match v_2:
    case cps_provider_2_Plan{v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45}:
      native_match_cps_provider_2_plan_executable_0(CLay.head_native(v_42, v_0), v_0, v_2)

def cps_provider_2_plan_executable(+v_0: BIR.Descriptor, v_2: cps_provider_2_Plan) -> cps_provider_2_PlanResult:
  native_match_cps_provider_2_plan_executable_1(v_2, v_0)

def cps_provider_2_plan_executable_native(+v_2: Maybe<&2, String>, +v_3: BIR.Descriptor, +v_5: cps_provider_2_Plan) -> cps_provider_2_PlanResult:
  match v_2:
    case Some{v_8}:
      cps_provider_2_plan_executable_io(String.eq(v_8, "IO"), v_3, v_5)
    case None{}:
      cps_provider_2_plan_executable_show(v_3, v_5)

def cps_provider_2_plan_executable_io(v_1: Bool, +v_2: BIR.Descriptor, +v_4: cps_provider_2_Plan) -> cps_provider_2_PlanResult:
  match v_1:
    case True{}:
      cps_provider_2_PlanOk{cps_provider_2_plan_set_pure_flags(v_4, False{}, "{ 0 }", "")}
    case False{}:
      cps_provider_2_plan_executable_show(v_2, v_4)

def native_match_cps_provider_2_plan_executable_show_0(v_47: Phys.ShowOut, +v_25: List<&2, cps_provider_2_CidRow>, v_26: Map<&2, String>, v_27: Map<&2, String>, v_28: List<&2, cps_provider_2_Entry>, v_29: Map<&2, U32>, v_30: Map<&2, U32>, v_31: Map<&2, U32>, v_32: Map<&2, U32>, v_33: Map<&2, U32>, +v_34: List<&2, BIR.ConstructorLayout>, +v_35: List<&2, BIR.Family>, v_36: List<&2, BIR.Declaration>, v_40: List<&2, cps_provider_2_CImport>, v_41: List<&2, String>, v_42: CLay.Context, v_43: Sharing.SharingPlan) -> cps_provider_2_PlanResult:
  match v_47:
    case Phys.ShowFail{v_49}:
      cps_provider_2_PlanFail{v_49}
    case Phys.ShowOk{v_52, v_53}:
      cps_provider_2_PlanOk{cps_provider_2_Plan{v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, True{}, v_52, v_53, v_40, v_41, v_42, v_43, False{}, []}}

def native_match_cps_provider_2_plan_executable_show_1(v_2: cps_provider_2_Plan, +v_0: BIR.Descriptor) -> cps_provider_2_PlanResult:
  match v_2:
    case cps_provider_2_Plan{+v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, +v_34, +v_35, v_36, v_37, _, _, v_40, v_41, v_42, v_43, _, _}:
      v_47 = Phys.show_build(v_42, v_0, v_34, v_35)
      native_match_cps_provider_2_plan_executable_show_0(v_47, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_40, v_41, v_42, v_43)

def cps_provider_2_plan_executable_show(+v_0: BIR.Descriptor, v_2: cps_provider_2_Plan) -> cps_provider_2_PlanResult:
  native_match_cps_provider_2_plan_executable_show_1(v_2, v_0)

def native_match_cps_provider_2_plan_library_0(v_50: Maybe<&2, List<&2, cps_provider_2_ExportRow>>, v_1: List<&2, BIR.Export>, v_26: List<&2, cps_provider_2_CidRow>, v_27: Map<&2, String>, v_28: Map<&2, String>, +v_29: List<&2, cps_provider_2_Entry>, +v_30: Map<&2, U32>, +v_31: Map<&2, U32>, +v_32: Map<&2, U32>, +v_33: Map<&2, U32>, +v_34: Map<&2, U32>, +v_35: List<&2, BIR.ConstructorLayout>, +v_36: List<&2, BIR.Family>, +v_37: List<&2, BIR.Declaration>, +v_41: List<&2, cps_provider_2_CImport>, +v_42: List<&2, String>, +v_43: CLay.Context, +v_44: Sharing.SharingPlan) -> cps_provider_2_PlanResult:
  match v_50:
    case None{}:
      cps_provider_2_PlanFail{"a library export names no callable, or its checked parameter count disagrees with its entry"}
    case Some{v_49}:
      cps_provider_2_PlanOk{cps_provider_2_Plan{v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, False{}, "{ 0 }", "", v_41, v_42, v_43, v_44, True{}, v_1}}

def native_match_cps_provider_2_plan_library_1(v_3: cps_provider_2_Plan, v_1: List<&2, BIR.Export>) -> cps_provider_2_PlanResult:
  match v_3:
    case cps_provider_2_Plan{v_26, v_27, v_28, +v_29, +v_30, +v_31, +v_32, +v_33, +v_34, +v_35, +v_36, +v_37, v_38, _, _, +v_41, +v_42, +v_43, +v_44, _, _}:
      native_match_cps_provider_2_plan_library_0(cps_provider_2_export_rows(v_1, v_37, v_30, v_31, v_32, v_33, v_29), v_1, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_41, v_42, v_43, v_44)

def cps_provider_2_plan_library(v_1: List<&2, BIR.Export>, v_3: cps_provider_2_Plan) -> cps_provider_2_PlanResult:
  native_match_cps_provider_2_plan_library_1(v_3, v_1)

def cps_provider_2_export_rows(v_1: List<&2, BIR.Export>, +v_3: List<&2, BIR.Declaration>, +v_6: Map<&2, U32>, +v_9: Map<&2, U32>, +v_12: Map<&2, U32>, +v_15: Map<&2, U32>, +v_18: List<&2, cps_provider_2_Entry>) -> Maybe<&2, List<&2, cps_provider_2_ExportRow>>:
  match v_1:
    case []:
      Some{[]}
    case +v_24 <> v_25:
      cps_provider_2_export_row_pair(cps_provider_2_export_row(v_24, v_3, v_6, v_9, v_12, v_15, v_18), cps_provider_2_export_rows(v_25, v_3, v_6, v_9, v_12, v_15, v_18))

def cps_provider_2_export_row_pair(v_2: Maybe<&2, cps_provider_2_ExportRow>, v_6: Maybe<&2, List<&2, cps_provider_2_ExportRow>>) -> Maybe<&2, List<&2, cps_provider_2_ExportRow>>:
  match v_2, v_6:
    case Some{v_12}, Some{v_13}:
      Some{v_12 <> v_13}
    case _, _:
      None{}

def cps_provider_2_export_row(v_0: BIR.Export, +v_2: List<&2, BIR.Declaration>, +v_5: Map<&2, U32>, +v_8: Map<&2, U32>, +v_11: Map<&2, U32>, +v_14: Map<&2, U32>, +v_17: List<&2, cps_provider_2_Entry>) -> Maybe<&2, cps_provider_2_ExportRow>:
  match v_0:
    case BIR.Export{v_23, v_24, v_25}:
      match v_24:
        case Some{v_26}:
          cps_provider_2_export_direct(v_23, v_26, List.length(&2, BIR.Descriptor, v_25), v_5)
        case None{}:
          cps_provider_2_export_symbol(v_23, List.length(&2, BIR.Descriptor, v_25), v_2, v_5, v_8, v_11, v_14)

def native_match_cps_provider_2_export_direct_0(v_14: Bool, v_1: String, v_4: Nat, +v_7: Map<&2, U32>, v_12: U32, v_13: Nat) -> Maybe<&2, cps_provider_2_ExportRow>:
  match v_14:
    case True{}:
      Some{cps_provider_2_ExportRow{v_1, cps_provider_2_map_u32(v_7, U32.show(v_12)), 0n, v_13}}
    case False{}:
      cps_provider_2_export_direct_curried(Nat.is_lt(v_13, v_4), v_1, v_12, v_13, v_7)

def native_match_cps_provider_2_export_direct_1(v_2: BIR.Entry, v_1: String, v_4: Nat, +v_7: Map<&2, U32>) -> Maybe<&2, cps_provider_2_ExportRow>:
  match v_2:
    case BIR.Entry{v_12, v_13}:
      native_match_cps_provider_2_export_direct_0(Nat.is_eq(v_13, v_4), v_1, v_4, v_7, v_12, v_13)

def cps_provider_2_export_direct(v_1: String, v_2: BIR.Entry, v_4: Nat, +v_7: Map<&2, U32>) -> Maybe<&2, cps_provider_2_ExportRow>:
  native_match_cps_provider_2_export_direct_1(v_2, v_1, v_4, v_7)

def cps_provider_2_export_direct_curried(v_1: Bool, +v_3: String, +v_5: U32, +v_7: Nat, +v_10: Map<&2, U32>) -> Maybe<&2, cps_provider_2_ExportRow>:
  match v_1:
    case True{}:
      Some{cps_provider_2_ExportRow{v_3, cps_provider_2_map_u32(v_10, U32.show(v_5)), 2n, v_7}}
    case False{}:
      None{}

def native_match_cps_provider_2_export_symbol_0(v_23: Maybe<&2, BIR.Declaration>, v_1: String, v_3: Nat, +v_8: Map<&2, U32>, +v_11: Map<&2, U32>, +v_14: Map<&2, U32>, +v_17: Map<&2, U32>) -> Maybe<&2, cps_provider_2_ExportRow>:
  match v_23:
    case None{}:
      None{}
    case Some{v_22}:
      cps_provider_2_export_symbol_item(v_1, v_3, v_22, v_8, v_11, v_14, v_17)

def cps_provider_2_export_symbol(v_1: String, v_3: Nat, +v_5: List<&2, BIR.Declaration>, +v_8: Map<&2, U32>, +v_11: Map<&2, U32>, +v_14: Map<&2, U32>, +v_17: Map<&2, U32>) -> Maybe<&2, cps_provider_2_ExportRow>:
  native_match_cps_provider_2_export_symbol_0(cps_provider_2_find_declaration(v_1, v_5), v_1, v_3, v_8, v_11, v_14, v_17)

def cps_provider_2_export_symbol_item(v_1: String, v_3: Nat, v_4: BIR.Declaration, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>) -> Maybe<&2, cps_provider_2_ExportRow>:
  match v_4:
    case BIR.FunctionDeclaration{_, v_23, v_24}:
      cps_provider_2_export_direct(v_1, BIR.Entry{v_23, List.length(&2, BIR.Parameter, v_24)}, v_3, v_7)
    case BIR.LazyDeclaration{_, v_29}:
      Some{cps_provider_2_ExportRow{v_1, cps_provider_2_map_u32(v_10, v_1), 1n, v_3}}
    case BIR.ForeignDeclaration{_, _, _, v_43, _, _, _, _, _}:
      cps_provider_2_export_declared(v_1, v_3, v_43, cps_provider_2_map_u32(v_13, v_1))
    case BIR.NativeDeclaration{_, _, v_56}:
      cps_provider_2_export_declared(v_1, v_3, List.length(&2, BIR.Quantity, v_56), cps_provider_2_map_u32(v_16, v_1))
    case _:
      None{}

def native_match_cps_provider_2_export_declared_0(v_8: Bool, v_1: String, v_3: Nat, v_7: U32) -> Maybe<&2, cps_provider_2_ExportRow>:
  match v_8:
    case True{}:
      Some{cps_provider_2_ExportRow{v_1, v_7, 1n, v_3}}
    case False{}:
      None{}

def cps_provider_2_export_declared(v_1: String, v_3: Nat, v_5: Nat, v_7: U32) -> Maybe<&2, cps_provider_2_ExportRow>:
  native_match_cps_provider_2_export_declared_0(Nat.is_eq(v_3, v_5), v_1, v_3, v_7)

def cps_provider_2_export_names(v_2: List<&2, cps_provider_2_ExportRow>, +v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_ExportRow{v_14, _, _, _}:
          cps_provider_2_export_names(v_9, String.append(cps_provider_2_c_quote(v_14), String.append(cps_provider_2_if_first(v_4), v_4)))

def native_match_cps_provider_2_if_first_0(v_2: Bool) -> String:
  match v_2:
    case True{}:
      ""
    case False{}:
      ", "

def cps_provider_2_if_first(v_1: String) -> String:
  native_match_cps_provider_2_if_first_0(String.is_empty(v_1))

def cps_provider_2_export_values(v_2: List<&2, cps_provider_2_ExportRow>, v_4: Nat, +v_6: String) -> String:
  match v_2:
    case []:
      v_6
    case +v_10 <> v_11:
      match v_10:
        case cps_provider_2_ExportRow{_, v_17, v_18, v_19}:
          cps_provider_2_export_values(v_11, v_4, String.append(cps_provider_2_export_value(v_17, v_18, v_19, v_4), String.append(cps_provider_2_if_first(v_6), v_6)))

def native_match_cps_provider_2_export_value_0(v_9: Bool, v_3: Nat, v_5: Nat) -> String:
  match v_9:
    case True{}:
      Nat.show(v_3)
    case False{}:
      Nat.show(v_5)

def native_match_cps_provider_2_export_value_1(v_8: Bool, v_1: U32, v_3: Nat, v_5: Nat, v_7: Nat) -> String:
  match v_8:
    case True{}:
      String.concat([U32.show(v_1), "u"])
    case False{}:
      native_match_cps_provider_2_export_value_0(Nat.is_eq(v_7, 1n), v_3, v_5)

def cps_provider_2_export_value(v_1: U32, v_3: Nat, v_5: Nat, v_7: Nat) -> String:
  native_match_cps_provider_2_export_value_1(Nat.is_eq(v_7, 0n), v_1, v_3, v_5, v_7)

def native_match_cps_provider_2_export_list_0(v_4: Bool, v_1: String, v_3: String) -> String:
  match v_4:
    case True{}:
      v_3
    case False{}:
      v_1

def cps_provider_2_export_list(v_1: String, v_3: String) -> String:
  native_match_cps_provider_2_export_list_0(String.is_empty(v_1), v_1, v_3)

def cps_provider_2_exports_c(v_1: Bool, v_4: List<&2, cps_provider_2_ExportRow>) -> String:
  match v_1:
    case False{}:
      ""
    case True{}:
      String.concat(["\n// Library exports\n", "#define BEND_EXPORT_COUNT ", Nat.show(List.length(&2, cps_provider_2_ExportRow, v_4)), "\n", "static const char* BEND_EXPORT_NAMES[] = { ", cps_provider_2_export_list(cps_provider_2_export_names(v_4, ""), "0"), " };\n", "static const u32 BEND_EXPORT_ENTRY[] = { ", cps_provider_2_export_list(cps_provider_2_export_values(v_4, 0n, ""), "0"), " };\n", "static const u8 BEND_EXPORT_MODE[] = { ", cps_provider_2_export_list(cps_provider_2_export_values(v_4, 1n, ""), "0"), " };\n", "static const u32 BEND_EXPORT_ARITY[] = { ", cps_provider_2_export_list(cps_provider_2_export_values(v_4, 2n, ""), "0"), " };\n", "static u64* BEND_EXPORT_CORPUS;\n\n", "u32 bend_export_count(void) { return BEND_EXPORT_COUNT; }\n", "const char* bend_export_name(u32 i) { return i < BEND_EXPORT_COUNT ? BEND_EXPORT_NAMES[i] : 0; }\n", "u32 bend_export_arity(u32 i) { return i < BEND_EXPORT_COUNT ? BEND_EXPORT_ARITY[i] : 0; }\n\n", "void bend_library_init(void) {\n", "#if !DEVICE\n  if (BEND_EXPORT_CORPUS == 0) { BEND_EXPORT_CORPUS = corpus_setup(false, 1, 0); io_stk = pool_stack(); }\n#endif\n}\n\n", "static Term bend_export_run(u32 fid, const Term* args, u32 n) {\n", "  Env e = { BEND_EXPORT_CORPUS, ALC[0] };\n", "  Term t = term_tsk(fid, task_node(e, fid, TERM_HOLE, 0, 0));\n", "  for (u32 i = 0; i < n; i += 1) { e.mem[term_loc(t) + i] = args[i]; }\n", "  return corpus_eval(e.mem, t);\n}\n\n", "static Term bend_export_apply_one(Term fun, Term arg) {\n", "  Env e = { BEND_EXPORT_CORPUS, ALC[0] };\n", "  Term t = term_tsk(FID_CLO_APPLY, task_node(e, FID_CLO_APPLY, TERM_HOLE, 0, 0));\n", "  e.mem[term_loc(t)] = fun;\n  e.mem[term_loc(t) + 1] = arg;\n", "  return corpus_eval(e.mem, t);\n}\n\n", "Term bend_export_apply(Term fun, const Term* args, u32 n) {\n", "  Term v = fun;\n  for (u32 i = 0; i < n; i += 1) { v = bend_export_apply_one(v, args[i]); }\n  return v;\n}\n\n", "Term bend_export_call(u32 i, const Term* args, u32 n) {\n", "  if (i >= BEND_EXPORT_COUNT) { err_fail(\"bend: export index out of range\"); }\n", "  u32 ar = BEND_EXPORT_ARITY[i];\n", "  if (BEND_EXPORT_MODE[i] == 0) {\n    if (n != ar) { err_fail(\"bend: export called at the wrong arity\"); }\n    return bend_export_run(BEND_EXPORT_ENTRY[i], args, n);\n  }\n", "  if (BEND_EXPORT_MODE[i] == 2) {\n    if (n < ar) { err_fail(\"bend: export called with too few arguments\"); }\n    Term v = bend_export_run(BEND_EXPORT_ENTRY[i], args, ar);\n    for (u32 j = ar; j < n; j += 1) { v = bend_export_apply_one(v, args[j]); }\n    return v;\n  }\n", "  Term v = bend_export_run(BEND_EXPORT_ENTRY[i], 0, 0);\n  for (u32 j = 0; j < n; j += 1) { v = bend_export_apply_one(v, args[j]); }\n  return v;\n}\n"])

def cps_provider_2_descriptor_head(v_0: BIR.Descriptor) -> Maybe<&2, String>:
  match v_0:
    case BIR.DescriptorRef{v_5, v_6}:
      Some{v_5}
    case BIR.DescriptorApplication{v_9, v_10}:
      cps_provider_2_descriptor_head(v_9)
    case BIR.DescriptorFill{v_14, v_15}:
      cps_provider_2_descriptor_head(v_14)
    case BIR.DescriptorPlus{v_19, v_20}:
      cps_provider_2_descriptor_head(v_19)
    case BIR.DescriptorNamedFill{v_25, v_26, v_27}:
      cps_provider_2_descriptor_head(v_26)
    case BIR.DescriptorNamedPlus{v_32, v_33, v_34}:
      cps_provider_2_descriptor_head(v_33)
    case _:
      None{}

def native_match_cps_provider_2_family_key_0(v_21: Bool, +v_1: String, +v_7: BIR.Family, v_8: List<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  match v_21:
    case True{}:
      Some{v_7}
    case False{}:
      cps_provider_2_family_key(v_1, v_8)

def native_match_cps_provider_2_family_key_1(+v_7: BIR.Family, +v_1: String, v_8: List<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  match v_7:
    case BIR.Family{v_15, v_16, v_17, v_18, v_19, v_20}:
      native_match_cps_provider_2_family_key_0(Bool.or(String.eq(v_1, v_15), String.eq(v_1, v_16)), v_1, v_7, v_8)

def native_match_cps_provider_2_family_key_2(v_3: List<&2, BIR.Family>, +v_1: String) -> Maybe<&2, BIR.Family>:
  match v_3:
    case []:
      None{}
    case +v_7 <> v_8:
      native_match_cps_provider_2_family_key_1(v_7, v_1, v_8)

def cps_provider_2_family_key(+v_1: String, v_3: List<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  native_match_cps_provider_2_family_key_2(v_3, v_1)

def cps_provider_2_build_entries_of(v_1: cps_provider_2_Build) -> List<&2, cps_provider_2_Entry>:
  match v_1:
    case cps_provider_2_Build{v_11, _, _, _, _, _, _}:
      v_11

def cps_provider_2_by_code_of(v_1: cps_provider_2_Build) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Build{_, v_12, _, _, _, _, _}:
      v_12

def cps_provider_2_by_key_of(v_1: cps_provider_2_Build) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Build{_, _, v_13, _, _, _, _}:
      v_13

def cps_provider_2_by_foreign_of(v_1: cps_provider_2_Build) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Build{_, _, _, v_14, _, _, _}:
      v_14

def cps_provider_2_by_native_of(v_1: cps_provider_2_Build) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Build{_, _, _, _, v_15, _, _}:
      v_15

def cps_provider_2_stages_of(v_1: cps_provider_2_Build) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Build{_, _, _, _, _, v_16, _}:
      v_16

def cps_provider_2_fkeys_of(v_1: cps_provider_2_Scan) -> List<&2, String>:
  match v_1:
    case cps_provider_2_Scan{v_8, v_9, v_10, v_11}:
      v_10

def cps_provider_2_cat(v_2: List<&2, String>) -> String:
  String.join(v_2, "")

def cps_provider_2_okp(v_1: String) -> cps_provider_2_Part:
  cps_provider_2_PartOk{v_1}

def cps_provider_2_failp(v_1: String) -> cps_provider_2_Part:
  cps_provider_2_PartFail{v_1}

def cps_provider_2_part_join(v_2: List<&2, cps_provider_2_Part>) -> cps_provider_2_Part:
  match v_2:
    case []:
      cps_provider_2_PartOk{""}
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_PartFail{v_9}:
          cps_provider_2_PartFail{v_9}
        case cps_provider_2_PartOk{v_11}:
          cps_provider_2_part_append(v_11, cps_provider_2_part_join(v_7))

def cps_provider_2_part_append(v_1: String, v_3: cps_provider_2_Part) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_PartFail{v_6}:
      cps_provider_2_PartFail{v_6}
    case cps_provider_2_PartOk{v_8}:
      cps_provider_2_PartOk{String.append(v_1, v_8)}

def cps_provider_2_part_first(v_2: List<&2, cps_provider_2_Part>) -> String:
  match v_2:
    case []:
      ""
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_PartFail{v_9}:
          v_9
        case cps_provider_2_PartOk{v_11}:
          cps_provider_2_part_first(v_7)

def cps_provider_2_part_require(v_2: List<&2, cps_provider_2_Part>) -> Maybe<&2, String>:
  match v_2:
    case []:
      Some{""}
    case +v_7 <> v_8:
      match v_7:
        case cps_provider_2_PartFail{v_10}:
          None{}
        case cps_provider_2_PartOk{v_12}:
          cps_provider_2_part_require(v_8)

def cps_provider_2_c_escape_char(+v_1: Char) -> String:
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
    case _:
      String.from_list([v_1])

def cps_provider_2_c_quote_chars(v_2: List<&2, Char>) -> String:
  match v_2:
    case []:
      "\""
    case +v_6 <> v_7:
      String.append(cps_provider_2_c_escape_char(v_6), cps_provider_2_c_quote_chars(v_7))

def cps_provider_2_c_quote(v_1: String) -> String:
  String.append("\"", cps_provider_2_c_quote_chars(String.to_list(v_1)))

def cps_provider_2_nat_c(v_1: Nat) -> String:
  cps_provider_2_cat([Nat.show(v_1), "ull"])

def cps_provider_2_u32_c(v_1: U32) -> String:
  cps_provider_2_cat([U32.show(v_1), "u"])

def cps_provider_2_list_at(v_2: List<&2, String>, v_4: Nat) -> String:
  match v_2, v_4:
    case [], _:
      ""
    case +v_10 <> _, 0n:
      v_10
    case _ <> v_16, 1n+v_17:
      cps_provider_2_list_at(v_16, v_17)

def cps_provider_2_member(v_2: List<&2, String>, +v_4: String) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_8 <> v_9:
      cps_provider_2_member_one(String.eq(v_8, v_4), v_4, v_9)

def cps_provider_2_member_one(v_1: Bool, v_3: String, v_6: List<&2, String>) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_2_member(v_6, v_3)

def native_match_cps_provider_2_map_flag_0(v_9: Maybe<&2, Bool>) -> Bool:
  match v_9:
    case Some{v_8}:
      v_8
    case None{}:
      False{}

def cps_provider_2_map_flag(v_2: Map<&2, Bool>, v_4: String) -> Bool:
  native_match_cps_provider_2_map_flag_0(IndexLookup.find(Bool, v_2, v_4))

def native_match_cps_provider_2_map_nat_0(v_9: Maybe<&2, Nat>) -> Nat:
  match v_9:
    case Some{v_8}:
      v_8
    case None{}:
      0n

def cps_provider_2_map_nat(v_2: Map<&2, Nat>, v_4: String) -> Nat:
  native_match_cps_provider_2_map_nat_0(IndexLookup.find(Nat, v_2, v_4))

def native_match_cps_provider_2_map_u32_0(v_9: Maybe<&2, U32>) -> U32:
  match v_9:
    case Some{v_8}:
      v_8
    case None{}:
      0

def cps_provider_2_map_u32(v_2: Map<&2, U32>, v_4: String) -> U32:
  native_match_cps_provider_2_map_u32_0(IndexLookup.find(U32, v_2, v_4))

def native_match_cps_provider_2_map_set_first_0(v_13: Maybe<&2, String>, +v_2: Map<&2, String>, +v_4: String, v_6: String) -> Map<&2, String>:
  match v_13:
    case Some{_}:
      v_2
    case None{}:
      Map.set(&2, String, v_2, v_4, v_6)

def cps_provider_2_map_set_first(+v_2: Map<&2, String>, +v_4: String, v_6: String) -> Map<&2, String>:
  native_match_cps_provider_2_map_set_first_0(IndexLookup.find(String, v_2, v_4), v_2, v_4, v_6)

def native_match_cps_provider_2_nat_min_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> Nat:
  match v_4:
    case True{}:
      v_1
    case False{}:
      v_3

def cps_provider_2_nat_min(+v_1: Nat, +v_3: Nat) -> Nat:
  native_match_cps_provider_2_nat_min_0(Nat.is_lt(v_1, v_3), v_1, v_3)

def native_match_cps_provider_2_nat_max_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> Nat:
  match v_4:
    case True{}:
      v_3
    case False{}:
      v_1

def cps_provider_2_nat_max(+v_1: Nat, +v_3: Nat) -> Nat:
  native_match_cps_provider_2_nat_max_0(Nat.is_lt(v_1, v_3), v_1, v_3)

def cps_provider_2_last_segment(+v_1: String) -> String:
  cps_provider_2_last_segment_list(String.split(v_1, '.'), v_1)

def cps_provider_2_last_segment_list(v_2: List<&2, String>, v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case +v_8 <> v_9:
      cps_provider_2_last_segment_list(v_9, v_8)

def cps_provider_2_list_index_of(v_2: List<&2, String>, +v_4: String, v_6: U32) -> Maybe<&2, U32>:
  match v_2:
    case []:
      None{}
    case +v_11 <> v_12:
      cps_provider_2_list_index_one(String.eq(v_11, v_4), v_4, v_11, v_12, v_6)

def cps_provider_2_list_index_one(v_1: Bool, v_3: String, v_5: String, v_8: List<&2, String>, +v_10: U32) -> Maybe<&2, U32>:
  match v_1:
    case True{}:
      Some{v_10}
    case False{}:
      cps_provider_2_list_index_of(v_8, v_3, U32.inc(v_10))

def cps_provider_2_ctor_keys(v_1: List<&2, BIR.ConstructorLayout>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case +v_6 <> v_7:
      match v_6:
        case BIR.ConstructorLayout{_, v_13, _, _}:
          v_13 <> cps_provider_2_ctor_keys(v_7)

def cps_provider_2_entry_at(v_2: List<&2, cps_provider_2_Entry>, +v_4: U32) -> Maybe<&2, cps_provider_2_Entry>:
  match v_2:
    case []:
      None{}
    case +v_9 <> v_10:
      match v_9:
        case cps_provider_2_Entry{v_14, v_15, v_16}:
          cps_provider_2_entry_at_one(U32.is_eq(v_14, v_4), v_9, v_10, v_4)

def cps_provider_2_entry_at_one(v_1: Bool, v_3: cps_provider_2_Entry, v_6: List<&2, cps_provider_2_Entry>, v_8: U32) -> Maybe<&2, cps_provider_2_Entry>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_2_entry_at(v_6, v_8)

def native_match_cps_provider_2_entry_arity_0(v_13: Maybe<&2, cps_provider_2_Entry>) -> Nat:
  match v_13:
    case Some{cps_provider_2_Entry{_, v_11, _}}:
      v_11
    case None{}:
      0n

def cps_provider_2_entry_arity(v_2: List<&2, cps_provider_2_Entry>, v_4: U32) -> Nat:
  native_match_cps_provider_2_entry_arity_0(cps_provider_2_entry_at(v_2, v_4))

def cps_provider_2_max_arity(v_2: List<&2, cps_provider_2_Entry>) -> Nat:
  cps_provider_2_max_arity_each(v_2, 2n)

def cps_provider_2_max_arity_each(v_2: List<&2, cps_provider_2_Entry>, +v_4: Nat) -> Nat:
  match v_2:
    case []:
      v_4
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_Entry{v_13, v_14, v_15}:
          cps_provider_2_max_arity_each(v_9, cps_provider_2_nat_max(v_4, v_14))

def cps_provider_2_scan_new() -> cps_provider_2_Scan:
  cps_provider_2_Scan{Map.new(&2, Nat), Map.new(&2, Bool), [], Map.new(&2, Nat)}

def cps_provider_2_scan_program(v_0: BIR.Program) -> cps_provider_2_Scan:
  match v_0:
    case BIR.Program{v_8, v_9, v_10, v_11, v_12, v_13}:
      cps_provider_2_scan_declarations(v_9, cps_provider_2_scan_codes(v_8, cps_provider_2_scan_new))

def cps_provider_2_scan_codes(v_1: List<&2, BIR.Code>, +v_3: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      match v_7:
        case BIR.Code{_, v_14, v_15, v_16}:
          cps_provider_2_scan_codes(v_8, cps_provider_2_scan_block(v_16, v_3))

def cps_provider_2_scan_declarations(v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      cps_provider_2_scan_declarations(v_8, cps_provider_2_scan_declaration(v_7, v_3))

def cps_provider_2_scan_declaration(v_0: BIR.Declaration, +v_2: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_0:
    case BIR.FunctionDeclaration{v_7, v_8, v_9}:
      v_2
    case BIR.LazyDeclaration{v_12, v_13}:
      cps_provider_2_scan_block(v_13, v_2)
    case BIR.NativeDeclaration{v_18, v_19, v_20}:
      v_2
    case BIR.ForeignDeclaration{v_30, _, _, v_33, _, _, _, _, _}:
      cps_provider_2_scan_foreign(v_2, v_30, v_33)

def native_match_cps_provider_2_scan_foreign_0(v_18: Bool, +v_3: String, v_5: Nat, +v_11: Map<&2, Nat>, +v_12: Map<&2, Bool>, +v_13: List<&2, String>, +v_14: Map<&2, Nat>) -> cps_provider_2_Scan:
  match v_18:
    case True{}:
      cps_provider_2_Scan{v_11, v_12, v_13, v_14}
    case False{}:
      cps_provider_2_Scan{v_11, v_12, List.append(&2, String, v_13, [v_3]), Map.set(&2, Nat, v_14, v_3, v_5)}

def native_match_cps_provider_2_scan_foreign_1(v_1: cps_provider_2_Scan, +v_3: String, v_5: Nat) -> cps_provider_2_Scan:
  match v_1:
    case cps_provider_2_Scan{+v_11, +v_12, +v_13, +v_14}:
      native_match_cps_provider_2_scan_foreign_0(cps_provider_2_member(v_13, v_3), v_3, v_5, v_11, v_12, v_13, v_14)

def cps_provider_2_scan_foreign(v_1: cps_provider_2_Scan, +v_3: String, v_5: Nat) -> cps_provider_2_Scan:
  native_match_cps_provider_2_scan_foreign_1(v_1, v_3, v_5)

def cps_provider_2_scan_read(v_1: cps_provider_2_Scan, v_3: String) -> cps_provider_2_Scan:
  match v_1:
    case cps_provider_2_Scan{v_9, v_10, v_11, v_12}:
      cps_provider_2_Scan{v_9, Map.set(&2, Bool, v_10, v_3, True{}), v_11, v_12}

def cps_provider_2_scan_close(v_1: cps_provider_2_Scan, v_3: U32, v_5: Nat) -> cps_provider_2_Scan:
  match v_1:
    case cps_provider_2_Scan{v_11, v_12, v_13, v_14}:
      cps_provider_2_Scan{cps_provider_2_scan_close_min(v_11, U32.show(v_3), v_5), v_12, v_13, v_14}

def native_match_cps_provider_2_scan_close_min_0(v_15: Maybe<&2, Nat>, +v_2: Map<&2, Nat>, +v_4: String, +v_6: Nat) -> Map<&2, Nat>:
  match v_15:
    case Some{v_11}:
      Map.set(&2, Nat, v_2, v_4, cps_provider_2_nat_min(v_11, v_6))
    case None{}:
      Map.set(&2, Nat, v_2, v_4, v_6)

def cps_provider_2_scan_close_min(+v_2: Map<&2, Nat>, +v_4: String, +v_6: Nat) -> Map<&2, Nat>:
  native_match_cps_provider_2_scan_close_min_0(IndexLookup.find(Nat, v_2, v_4), v_2, v_4, v_6)

def cps_provider_2_scan_atom(v_0: BIR.Atom, +v_2: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_0:
    case BIR.Symbol{_, v_7}:
      cps_provider_2_scan_read(v_2, v_7)
    case _:
      v_2

def cps_provider_2_scan_argument(v_0: BIR.Arg, v_2: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_0:
    case BIR.Arg{_, v_7}:
      cps_provider_2_scan_atom(v_7, v_2)

def cps_provider_2_scan_arguments(v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      cps_provider_2_scan_arguments(v_8, cps_provider_2_scan_argument(v_7, v_3))

def cps_provider_2_scan_fields(v_1: List<&2, BIR.Field>, +v_3: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_1:
    case []:
      v_3
    case +v_7 <> v_8:
      match v_7:
        case BIR.Field{_, _, _, v_16}:
          cps_provider_2_scan_fields(v_8, cps_provider_2_scan_atom(v_16, v_3))

def cps_provider_2_scan_op(v_0: BIR.Op, +v_2: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_0:
    case BIR.Copy{v_5}:
      cps_provider_2_scan_atom(v_5, v_2)
    case BIR.PrimitiveCall{v_10, v_11, v_12}:
      cps_provider_2_scan_arguments(v_11, v_2)
    case BIR.Closure{v_17, +v_18, v_19}:
      cps_provider_2_scan_arguments(v_18, cps_provider_2_scan_close(v_2, v_17, List.length(&2, BIR.Arg, v_18)))
    case BIR.Direct{v_24, v_25}:
      cps_provider_2_scan_arguments(v_25, v_2)
    case BIR.Apply{v_29, v_30}:
      cps_provider_2_scan_argument(v_30, cps_provider_2_scan_atom(v_29, v_2))
    case BIR.LoadSymbol{_, v_36}:
      cps_provider_2_scan_read(v_2, v_36)
    case BIR.Construct{v_41, v_42, v_43}:
      cps_provider_2_scan_fields(v_43, v_2)
    case BIR.Project{v_49, v_50, v_51, v_52}:
      cps_provider_2_scan_atom(v_49, v_2)
    case BIR.HasTag{v_57, v_58, v_59}:
      cps_provider_2_scan_atom(v_57, v_2)
    case _:
      v_2

def cps_provider_2_scan_block(v_0: BIR.Block, +v_2: cps_provider_2_Scan) -> cps_provider_2_Scan:
  match v_0:
    case BIR.Return{v_5}:
      cps_provider_2_scan_atom(v_5, v_2)
    case BIR.Let{v_10, v_11, v_12}:
      cps_provider_2_scan_block(v_12, cps_provider_2_scan_op(v_11, v_2))
    case BIR.Branch{v_18, v_19, v_20}:
      cps_provider_2_scan_block(v_20, cps_provider_2_scan_block(v_19, cps_provider_2_scan_atom(v_18, v_2)))
    case BIR.Region{v_27, v_28, v_29}:
      cps_provider_2_scan_block(v_29, cps_provider_2_scan_block(v_28, v_2))
    case BIR.LeaveRegion{v_33}:
      v_2
    case BIR.TailDirect{v_36, v_37}:
      cps_provider_2_scan_arguments(v_37, v_2)
    case BIR.TailApply{v_41, v_42}:
      cps_provider_2_scan_argument(v_42, cps_provider_2_scan_atom(v_41, v_2))
    case BIR.Failure{v_46}:
      v_2

def cps_provider_2_cid_rows(v_0: BIR.Program, v_2: cps_provider_2_Scan, v_3: Sharing.SharingPlan) -> List<&2, cps_provider_2_CidRow>:
  match v_0:
    case BIR.Program{v_12, v_13, v_14, v_15, v_16, v_17}:
      cps_provider_2_cid_foreign_rows(v_2, cps_provider_2_cid_ctor_rows(v_14, 0, [], v_3), v_3)

def cps_provider_2_cid_ctor_rows(v_1: List<&2, BIR.ConstructorLayout>, +v_3: U32, +v_6: List<&2, cps_provider_2_CidRow>, v_7: Sharing.SharingPlan) -> List<&2, cps_provider_2_CidRow>:
  match v_1:
    case []:
      List.reverse(&2, cps_provider_2_CidRow, v_6)
    case +v_13 <> v_14:
      match v_13:
        case BIR.ConstructorLayout{_, v_20, _, v_22}:
          v_24 = Sharing.ctor_hot(v_7, v_20)
          cps_provider_2_cid_ctor_rows(v_14, U32.inc(v_3), cps_provider_2_CidRow{v_3, v_20, List.length(&2, Maybe<&2, String>, v_22), v_24} <> v_6, v_7)

def cps_provider_2_cid_foreign_rows(v_1: cps_provider_2_Scan, +v_4: List<&2, cps_provider_2_CidRow>, v_5: Sharing.SharingPlan) -> List<&2, cps_provider_2_CidRow>:
  match v_1:
    case cps_provider_2_Scan{v_12, v_13, v_14, v_15}:
      cps_provider_2_cid_foreign_each(v_14, v_15, U32.from_nat(List.length(&2, cps_provider_2_CidRow, v_4)), v_4, v_5)

def cps_provider_2_cid_foreign_each(v_2: List<&2, String>, +v_5: Map<&2, Nat>, +v_7: U32, +v_10: List<&2, cps_provider_2_CidRow>, v_11: Sharing.SharingPlan) -> List<&2, cps_provider_2_CidRow>:
  match v_2:
    case []:
      v_10
    case +v_16 <> v_17:
      v_19 = Sharing.ctor_hot(v_11, v_16)
      cps_provider_2_cid_foreign_each(v_17, v_5, U32.inc(v_7), List.append(&2, cps_provider_2_CidRow, v_10, [cps_provider_2_CidRow{v_7, v_16, Nat.add(cps_provider_2_map_nat(v_5, v_16), 1n), v_19}]), v_11)

def cps_provider_2_cid_lookup(+v_1: String, v_4: List<&2, cps_provider_2_CidRow>) -> U32:
  match v_4:
    case []:
      0
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_CidRow{v_14, v_15, v_16, _}:
          cps_provider_2_cid_lookup_one(String.eq(v_1, v_15), v_1, v_14, v_9)

def cps_provider_2_cid_lookup_one(v_1: Bool, v_3: String, v_5: U32, v_8: List<&2, cps_provider_2_CidRow>) -> U32:
  match v_1:
    case True{}:
      v_5
    case False{}:
      cps_provider_2_cid_lookup(v_3, v_8)

def cps_provider_2_cid_short_one(v_1: Bool, v_3: String, v_5: U32, v_8: List<&2, cps_provider_2_CidRow>) -> Maybe<&2, U32>:
  match v_1:
    case True{}:
      Some{v_5}
    case False{}:
      cps_provider_2_cid_short(v_3, v_8)

def cps_provider_2_cid_short(+v_1: String, v_4: List<&2, cps_provider_2_CidRow>) -> Maybe<&2, U32>:
  match v_4:
    case []:
      None{}
    case +v_9 <> v_10:
      match v_9:
        case cps_provider_2_CidRow{v_15, v_16, v_17, _}:
          cps_provider_2_cid_short_one(String.eq(v_1, v_16), v_1, v_15, v_10)

def native_match_cps_provider_2_cid_c_0(v_9: Maybe<&2, U32>, +v_1: String) -> cps_provider_2_Part:
  match v_9:
    case Some{v_8}:
      cps_provider_2_PartOk{String.append(U32.show(v_8), "u")}
    case None{}:
      cps_provider_2_PartFail{String.append("the program has no `", String.append(v_1, "` constructor, which the C runtime contract requires"))}

def cps_provider_2_cid_c(+v_1: String, v_4: List<&2, cps_provider_2_CidRow>) -> cps_provider_2_Part:
  native_match_cps_provider_2_cid_c_0(cps_provider_2_cid_short(v_1, v_4), v_1)

def cps_provider_2_cid_macro_map(v_2: List<&2, cps_provider_2_CidRow>) -> Map<&2, String>:
  cps_provider_2_cid_macro_each(v_2, Map.new(&2, String))

def cps_provider_2_cid_symbol(v_1: U32) -> String:
  String.append("CID_", U32.show(v_1))

def cps_provider_2_fid_symbol(v_1: U32) -> String:
  String.append("FID_", U32.show(v_1))

def native_match_cps_provider_2_runtime_cid_alias_0(v_11: cps_provider_2_CidRow, +v_1: String) -> cps_provider_2_Part:
  match v_11:
    case cps_provider_2_CidRow{v_16, v_17, v_18, _}:
      cps_provider_2_okp(cps_provider_2_cat(["#define ", v_1, " ", cps_provider_2_cid_symbol(v_16), "\n"]))

def native_match_cps_provider_2_runtime_cid_alias_1(v_20: Maybe<&2, cps_provider_2_CidRow>, +v_1: String, +v_3: String) -> cps_provider_2_Part:
  match v_20:
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_cat(["the program has no `", v_3, "` constructor for the runtime symbol ", v_1])}
    case Some{v_11}:
      native_match_cps_provider_2_runtime_cid_alias_0(v_11, v_1)

def cps_provider_2_runtime_cid_alias(+v_1: String, +v_3: String, v_6: List<&2, cps_provider_2_CidRow>) -> cps_provider_2_Part:
  native_match_cps_provider_2_runtime_cid_alias_1(cps_provider_2_find_cid_row(v_3, v_6), v_1, v_3)

def cps_provider_2_find_cid_row(+v_1: String, v_4: List<&2, cps_provider_2_CidRow>) -> Maybe<&2, cps_provider_2_CidRow>:
  match v_4:
    case []:
      None{}
    case +v_9 <> v_10:
      match v_9:
        case cps_provider_2_CidRow{_, v_16, _, _}:
          cps_provider_2_find_cid_row_one(String.eq(v_1, v_16), v_9, v_1, v_10)

def cps_provider_2_find_cid_row_one(v_1: Bool, v_3: cps_provider_2_CidRow, v_5: String, v_8: List<&2, cps_provider_2_CidRow>) -> Maybe<&2, cps_provider_2_CidRow>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_2_find_cid_row(v_5, v_8)

def cps_provider_2_runtime_cid_aliases(+v_2: List<&2, cps_provider_2_CidRow>) -> cps_provider_2_Part:
  cps_provider_2_part_join([cps_provider_2_runtime_cid_alias("CID_NIL", "Nil", v_2), cps_provider_2_runtime_cid_alias("CID_CON", "Con", v_2), cps_provider_2_runtime_cid_alias("CID_TUPLE", "Tuple", v_2), cps_provider_2_runtime_cid_alias("CID_SNIL", "SNil", v_2), cps_provider_2_runtime_cid_alias("CID_SCON", "SCon", v_2), cps_provider_2_runtime_cid_alias("CID_WCON", "WCon", v_2), cps_provider_2_runtime_cid_alias("CID_EMIT", "Emit", v_2), cps_provider_2_runtime_cid_alias("CID_HALT", "Halt", v_2), cps_provider_2_runtime_cid_alias("CID_EXIT", "Exit", v_2), cps_provider_2_runtime_cid_alias("CID_FAIL", "Fail", v_2), cps_provider_2_runtime_cid_alias("CID_DONE", "Done", v_2), cps_provider_2_runtime_cid_alias("CID_READY", "Ready", v_2), cps_provider_2_runtime_cid_alias("CID_WAIT", "Wait", v_2), cps_provider_2_runtime_cid_alias("CID_NONE", "None", v_2), cps_provider_2_runtime_cid_alias("CID_SOME", "Some", v_2)])

def cps_provider_2_cid_of_row(v_1: cps_provider_2_CidRow) -> U32:
  match v_1:
    case cps_provider_2_CidRow{v_7, v_8, v_9, _}:
      v_7

def cps_provider_2_cid_macro_each(v_2: List<&2, cps_provider_2_CidRow>, +v_5: Map<&2, String>) -> Map<&2, String>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      match v_10:
        case cps_provider_2_CidRow{_, v_17, _, _}:
          cps_provider_2_cid_macro_each(v_11, cps_provider_2_map_set_first(v_5, v_17, cps_provider_2_cid_symbol(cps_provider_2_cid_of_row(v_10))))

def cps_provider_2_layout_of(+v_1: U32, v_3: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_3:
    case []:
      None{}
    case +v_7 <> v_8:
      match v_7:
        case BIR.ConstructorLayout{v_13, v_14, v_15, v_16}:
          cps_provider_2_layout_one(U32.is_eq(v_1, v_13), v_7, v_1, v_8)

def cps_provider_2_layout_one(v_1: Bool, v_2: BIR.ConstructorLayout, v_4: U32, v_6: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_1:
    case True{}:
      Some{v_2}
    case False{}:
      cps_provider_2_layout_of(v_4, v_6)

def native_match_cps_provider_2_key_layout_0(v_17: Bool, +v_1: String, +v_7: BIR.ConstructorLayout, v_8: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_17:
    case True{}:
      Some{v_7}
    case False{}:
      cps_provider_2_key_layout(v_1, v_8)

def native_match_cps_provider_2_key_layout_1(+v_7: BIR.ConstructorLayout, +v_1: String, v_8: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_7:
    case BIR.ConstructorLayout{v_13, +v_14, v_15, v_16}:
      native_match_cps_provider_2_key_layout_0(Bool.or(String.eq(v_1, v_14), String.eq(v_1, cps_provider_2_last_segment(v_14))), v_1, v_7, v_8)

def native_match_cps_provider_2_key_layout_2(v_3: List<&2, BIR.ConstructorLayout>, +v_1: String) -> Maybe<&2, BIR.ConstructorLayout>:
  match v_3:
    case []:
      None{}
    case +v_7 <> v_8:
      native_match_cps_provider_2_key_layout_1(v_7, v_1, v_8)

def cps_provider_2_key_layout(+v_1: String, v_3: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  native_match_cps_provider_2_key_layout_2(v_3, v_1)

def cps_provider_2_live_fields(v_1: List<&2, BIR.DescriptorField>, +v_3: List<&2, BIR.DescriptorField>) -> List<&2, BIR.DescriptorField>:
  match v_1:
    case []:
      List.reverse(&2, BIR.DescriptorField, v_3)
    case +v_7 <> v_8:
      match v_7:
        case BIR.DescriptorField{v_12, v_13, v_14}:
          cps_provider_2_live_fields(v_8, cps_provider_2_live_field_add(v_13, v_7, v_3))

def cps_provider_2_live_field_add(v_0: BIR.Quantity, v_1: BIR.DescriptorField, +v_3: List<&2, BIR.DescriptorField>) -> List<&2, BIR.DescriptorField>:
  match v_0:
    case BIR.Erased{}:
      v_3
    case _:
      v_1 <> v_3

def cps_provider_2_arm_of(v_1: String, v_3: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_3:
    case []:
      None{}
    case +v_7 <> v_8:
      match v_7:
        case BIR.Family{v_15, v_16, v_17, v_18, v_19, v_20}:
          cps_provider_2_arms_find(v_1, v_20, v_8)

def native_match_cps_provider_2_arms_find_0(v_16: Bool, +v_1: String, +v_5: List<&2, BIR.Family>, +v_10: BIR.DescriptorArm, v_11: List<&2, BIR.DescriptorArm>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_16:
    case True{}:
      Some{v_10}
    case False{}:
      cps_provider_2_arms_find(v_1, v_11, v_5)

def native_match_cps_provider_2_arms_find_1(+v_10: BIR.DescriptorArm, +v_1: String, +v_5: List<&2, BIR.Family>, v_11: List<&2, BIR.DescriptorArm>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_10:
    case BIR.DescriptorArm{+v_14, v_15}:
      native_match_cps_provider_2_arms_find_0(Bool.or(String.eq(v_1, v_14), String.eq(cps_provider_2_last_segment(v_1), cps_provider_2_last_segment(v_14))), v_1, v_5, v_10, v_11)

def native_match_cps_provider_2_arms_find_2(v_3: List<&2, BIR.DescriptorArm>, +v_1: String, +v_5: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match v_3:
    case []:
      cps_provider_2_arm_of(v_1, v_5)
    case +v_10 <> v_11:
      native_match_cps_provider_2_arms_find_1(v_10, v_1, v_5, v_11)

def cps_provider_2_arms_find(+v_1: String, v_3: List<&2, BIR.DescriptorArm>, +v_5: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  native_match_cps_provider_2_arms_find_2(v_3, v_1, v_5)

def native_match_cps_provider_2_live_index_fields_0(v_19: Bool, +v_3: Nat, +v_5: Nat, +v_7: Nat, v_12: List<&2, BIR.DescriptorField>, v_17: BIR.Quantity) -> Nat:
  match v_19:
    case True{}:
      v_7
    case False{}:
      cps_provider_2_live_index_fields(v_12, v_3, Nat.add(v_5, 1n), cps_provider_2_live_index_next(v_17, v_7))

def native_match_cps_provider_2_live_index_fields_1(+v_11: BIR.DescriptorField, +v_3: Nat, +v_5: Nat, +v_7: Nat, v_12: List<&2, BIR.DescriptorField>) -> Nat:
  match v_11:
    case BIR.DescriptorField{v_16, v_17, v_18}:
      native_match_cps_provider_2_live_index_fields_0(Nat.is_eq(v_5, v_3), v_3, v_5, v_7, v_12, v_17)

def native_match_cps_provider_2_live_index_fields_2(v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat) -> Nat:
  match v_1:
    case []:
      v_7
    case +v_11 <> v_12:
      native_match_cps_provider_2_live_index_fields_1(v_11, v_3, v_5, v_7, v_12)

def cps_provider_2_live_index_fields(v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat) -> Nat:
  native_match_cps_provider_2_live_index_fields_2(v_1, v_3, v_5, v_7)

def cps_provider_2_live_index_next(v_0: BIR.Quantity, +v_2: Nat) -> Nat:
  match v_0:
    case BIR.Erased{}:
      v_2
    case _:
      Nat.add(v_2, 1n)

def cps_provider_2_atom_part(v_0: BIR.Atom, +v_2: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_0:
    case BIR.Local{v_5}:
      cps_provider_2_okp(cps_provider_2_cat(["lv", U32.show(v_5)]))
    case BIR.Capture{v_9}:
      cps_provider_2_okp(cps_provider_2_cat(["x[", U32.show(v_9), "]"]))
    case BIR.Symbol{_, v_15}:
      cps_provider_2_symbol_part(v_15, v_2)
    case BIR.Word{v_18}:
      cps_provider_2_okp(cps_provider_2_u32_c(v_18))
    case BIR.Natural{v_22}:
      cps_provider_2_okp(cps_provider_2_nat_c(v_22))
    case BIR.FloatBits{v_26}:
      cps_provider_2_okp(U32.show(v_26))
    case BIR.Text{+v_29}:
      cps_provider_2_okp(cps_provider_2_cat(["bend_text(e, ", cps_provider_2_c_quote(v_29), ", ", Nat.show(String.length(v_29)), ")"]))
    case BIR.Boolean{v_34}:
      cps_provider_2_bool_lit_part(cps_provider_2_bool_name(v_34), v_2)
    case BIR.Null{}:
      cps_provider_2_okp("0")
    case BIR.Undefined{}:
      cps_provider_2_okp("0")
    case _:
      cps_provider_2_failp("BIR atom form has no C rendering")

def cps_provider_2_bool_name(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "True"
    case False{}:
      "False"

def native_match_cps_provider_2_bool_lit_part_0(v_11: cps_provider_2_Part) -> cps_provider_2_Part:
  match v_11:
    case cps_provider_2_PartOk{v_7}:
      cps_provider_2_PartOk{cps_provider_2_cat(["term_pak(", v_7, ", 0)"])}
    case cps_provider_2_PartFail{v_10}:
      cps_provider_2_PartFail{v_10}

def cps_provider_2_bool_lit_part(v_1: String, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_bool_lit_part_0(cps_provider_2_pcid(v_1, v_3))

def cps_provider_2_symbol_part(+v_1: String, +v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_Plan{v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, _, _}:
      cps_provider_2_symbol_part_decl(cps_provider_2_find_declaration(v_1, v_37), v_1, v_3)

def cps_provider_2_find_declaration(+v_1: String, v_3: List<&2, BIR.Declaration>) -> Maybe<&2, BIR.Declaration>:
  match v_3:
    case []:
      None{}
    case +v_7 <> v_8:
      match v_7:
        case BIR.FunctionDeclaration{v_12, v_13, v_14}:
          cps_provider_2_find_declaration_one(String.eq(v_1, v_12), v_7, v_1, v_8)
        case BIR.LazyDeclaration{v_18, v_19}:
          cps_provider_2_find_declaration_one(String.eq(v_1, v_18), v_7, v_1, v_8)
        case BIR.NativeDeclaration{v_24, v_25, v_26}:
          cps_provider_2_find_declaration_one(String.eq(v_1, v_24), v_7, v_1, v_8)
        case BIR.ForeignDeclaration{v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45}:
          cps_provider_2_find_declaration_one(String.eq(v_1, v_37), v_7, v_1, v_8)
        case _:
          cps_provider_2_find_declaration(v_1, v_8)

def cps_provider_2_find_declaration_one(v_1: Bool, v_2: BIR.Declaration, v_4: String, v_6: List<&2, BIR.Declaration>) -> Maybe<&2, BIR.Declaration>:
  match v_1:
    case True{}:
      Some{v_2}
    case False{}:
      cps_provider_2_find_declaration(v_4, v_6)

def cps_provider_2_symbol_part_decl(v_1: Maybe<&2, BIR.Declaration>, +v_3: String, v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_1:
    case None{}:
      cps_provider_2_failp(cps_provider_2_cat(["BIR reads symbol `", v_3, "` with no declaration"]))
    case Some{v_10}:
      cps_provider_2_symbol_part_item(v_10, v_3, v_5)

def native_match_cps_provider_2_symbol_part_item_0(v_0: BIR.Declaration, +v_2: String, +v_30: List<&2, cps_provider_2_Entry>, v_31: Map<&2, U32>, v_33: Map<&2, U32>, v_34: Map<&2, U32>, +v_35: Map<&2, U32>) -> cps_provider_2_Part:
  match v_0:
    case BIR.FunctionDeclaration{v_51, +v_52, v_53}:
      cps_provider_2_symbol_value(IndexLookup.find(U32, v_31, U32.show(v_52)), cps_provider_2_code_stem(v_52), v_30, v_35)
    case BIR.ForeignDeclaration{v_66, _, _, v_69, _, _, _, _, _}:
      cps_provider_2_symbol_value(IndexLookup.find(U32, v_33, v_2), cps_provider_2_foreign_stem(v_2), v_30, v_35)
    case BIR.NativeDeclaration{v_81, v_82, v_83}:
      cps_provider_2_symbol_value(IndexLookup.find(U32, v_34, v_2), cps_provider_2_native_stem(v_2), v_30, v_35)
    case BIR.LazyDeclaration{v_89, v_90}:
      cps_provider_2_failp(cps_provider_2_cat(["the lazy `", v_2, "` is evaluated by LoadSymbol, never a first-class value"]))
    case _:
      cps_provider_2_failp("BIR declaration form has no C value")

def native_match_cps_provider_2_symbol_part_item_1(v_4: cps_provider_2_Plan, v_0: BIR.Declaration, +v_2: String) -> cps_provider_2_Part:
  match v_4:
    case cps_provider_2_Plan{v_27, v_28, v_29, +v_30, v_31, v_32, v_33, v_34, +v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45, _, _}:
      native_match_cps_provider_2_symbol_part_item_0(v_0, v_2, v_30, v_31, v_33, v_34, v_35)

def cps_provider_2_symbol_part_item(v_0: BIR.Declaration, +v_2: String, v_4: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_symbol_part_item_1(v_4, v_0, v_2)

def native_match_cps_provider_2_symbol_value_0(v_24: Maybe<&2, U32>, +v_4: String) -> cps_provider_2_Part:
  match v_24:
    case Some{v_21}:
      cps_provider_2_PartOk{cps_provider_2_cat(["term_clo(FID_", U32.show(v_21), ", 0)"])}
    case None{}:
      cps_provider_2_PartFail{cps_provider_2_cat(["BIR symbol `", v_4, "` has no arity-one stage entry"])}

def native_match_cps_provider_2_symbol_value_1(v_23: Bool, +v_4: String, v_10: Map<&2, U32>, +v_13: U32) -> cps_provider_2_Part:
  match v_23:
    case True{}:
      cps_provider_2_PartOk{cps_provider_2_cat(["term_clo(FID_", U32.show(v_13), ", 0)"])}
    case False{}:
      native_match_cps_provider_2_symbol_value_0(IndexLookup.find(U32, v_10, cps_provider_2_stage_key(v_4, 0n)), v_4)

def native_match_cps_provider_2_symbol_value_2(v_22: Bool, +v_4: String, v_10: Map<&2, U32>, +v_13: U32, +v_16: Nat) -> cps_provider_2_Part:
  match v_22:
    case True{}:
      cps_provider_2_PartFail{"BIR symbol names a nullary entry, which only LoadSymbol evaluates"}
    case False{}:
      native_match_cps_provider_2_symbol_value_1(Nat.is_eq(v_16, 1n), v_4, v_10, v_13)

def native_match_cps_provider_2_symbol_value_3(v_2: Maybe<&2, U32>, +v_4: String, v_7: List<&2, cps_provider_2_Entry>, v_10: Map<&2, U32>) -> cps_provider_2_Part:
  match v_2:
    case None{}:
      cps_provider_2_PartFail{"BIR symbol has no entry"}
    case Some{+v_13}:
      +v_16 = cps_provider_2_entry_arity(v_7, v_13)
      native_match_cps_provider_2_symbol_value_2(Nat.is_eq(v_16, 0n), v_4, v_10, v_13, v_16)

def cps_provider_2_symbol_value(v_2: Maybe<&2, U32>, +v_4: String, v_7: List<&2, cps_provider_2_Entry>, v_10: Map<&2, U32>) -> cps_provider_2_Part:
  native_match_cps_provider_2_symbol_value_3(v_2, v_4, v_7, v_10)

def cps_provider_2_args_parts(v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Plan) -> List<&2, cps_provider_2_Part>:
  match v_1:
    case []:
      []
    case +v_8 <> v_9:
      match v_8:
        case BIR.Arg{_, v_13}:
          cps_provider_2_atom_part(v_13, v_3) <> cps_provider_2_args_parts(v_9, v_3)

def cps_provider_2_arg_strings(v_1: List<&2, BIR.Arg>, v_3: cps_provider_2_Plan) -> Maybe<&2, List<&2, String>>:
  cps_provider_2_arg_strings_each(cps_provider_2_args_parts(v_1, v_3), [])

def cps_provider_2_arg_strings_each(v_2: List<&2, cps_provider_2_Part>, +v_5: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match v_2:
    case []:
      Some{List.reverse(&2, String, v_5)}
    case +v_12 <> v_13:
      match v_12:
        case cps_provider_2_PartFail{v_15}:
          None{}
        case cps_provider_2_PartOk{v_17}:
          cps_provider_2_arg_strings_each(v_13, v_17 <> v_5)

def cps_provider_2_op_part(v_0: BIR.Op, +v_2: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_0:
    case BIR.Copy{v_5}:
      cps_provider_2_atom_part(v_5, v_2)
    case BIR.PrimitiveCall{v_10, v_11, v_12}:
      cps_provider_2_prim_call_typed(v_10, v_11, v_12, v_2)
    case BIR.Construct{v_17, v_18, v_19}:
      cps_provider_2_construct_part(v_17, v_19, v_2)
    case BIR.Project{v_25, v_26, v_27, v_28}:
      cps_provider_2_project_part(v_25, v_26, v_27, v_2)
    case BIR.HasTag{v_33, v_34, v_35}:
      cps_provider_2_hastag_part(v_33, v_34, v_2)
    case BIR.Closure{v_40, v_41, v_42}:
      cps_provider_2_failp("a BIR closure is a control operation, not a pure C expression")
    case BIR.Direct{v_46, v_47}:
      cps_provider_2_failp("a BIR call is a control operation, not a pure C expression")
    case BIR.Apply{v_51, v_52}:
      cps_provider_2_failp("a BIR application is a control operation, not a pure C expression")
    case BIR.LoadSymbol{_, v_57}:
      cps_provider_2_failp("a BIR symbol load is a control operation, not a pure C expression")
    case _:
      cps_provider_2_failp("BIR operation form has no C rendering")

def cps_provider_2_field_values(v_1: List<&2, BIR.Field>, +v_3: cps_provider_2_Plan) -> List<&2, cps_provider_2_Part>:
  match v_1:
    case []:
      []
    case +v_8 <> v_9:
      match v_8:
        case BIR.Field{_, _, _, v_17}:
          cps_provider_2_atom_part(v_17, v_3) <> cps_provider_2_field_values(v_9, v_3)

def cps_provider_2_all_arms_nullary(v_1: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_1:
    case []:
      True{}
    case +v_5 <> v_6:
      match v_5:
        case BIR.DescriptorArm{v_9, v_10}:
          cps_provider_2_all_arms_nullary_one(Nat.is_eq(List.length(&2, BIR.DescriptorField, cps_provider_2_live_fields(v_10, [])), 0n), v_6)

def cps_provider_2_all_arms_nullary_one(v_1: Bool, v_3: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_1:
    case True{}:
      cps_provider_2_all_arms_nullary(v_3)
    case False{}:
      False{}

def cps_provider_2_arm_member(+v_1: String, v_3: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_3:
    case []:
      False{}
    case +v_7 <> v_8:
      match v_7:
        case BIR.DescriptorArm{+v_11, v_12}:
          cps_provider_2_arm_member_one(Bool.or(String.eq(v_1, v_11), String.eq(cps_provider_2_last_segment(v_1), cps_provider_2_last_segment(v_11))), v_1, v_8)

def cps_provider_2_arm_member_one(v_1: Bool, v_3: String, v_5: List<&2, BIR.DescriptorArm>) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_2_arm_member(v_3, v_5)

def cps_provider_2_arm_index(+v_1: String, v_3: List<&2, BIR.DescriptorArm>, v_5: Nat) -> Maybe<&2, Nat>:
  match v_3:
    case []:
      None{}
    case +v_10 <> v_11:
      match v_10:
        case BIR.DescriptorArm{+v_14, v_15}:
          cps_provider_2_arm_index_one(Bool.or(String.eq(v_1, v_14), String.eq(cps_provider_2_last_segment(v_1), cps_provider_2_last_segment(v_14))), v_1, v_11, v_5)

def cps_provider_2_arm_index_one(v_1: Bool, v_3: String, v_5: List<&2, BIR.DescriptorArm>, +v_7: Nat) -> Maybe<&2, Nat>:
  match v_1:
    case True{}:
      Some{v_7}
    case False{}:
      cps_provider_2_arm_index(v_3, v_5, Nat.add(v_7, 1n))

def cps_provider_2_phys_world(+v_1: cps_provider_2_Plan) -> Phys.World:
  match v_1:
    case cps_provider_2_Plan{v_23, v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, _, _}:
      Phys.world(v_40, v_32, v_33, cps_provider_2_phys_cids(v_23))

def cps_provider_2_phys_cids(v_2: List<&2, cps_provider_2_CidRow>) -> List<&2, Phys.CidSym>:
  match v_2:
    case []:
      []
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_CidRow{v_12, v_13, v_14, v_15}:
          Phys.CidSym{v_12, v_13} <> cps_provider_2_phys_cids(v_7)

def native_match_cps_provider_2_construct_part_0(v_12: cps_provider_2_OperandsOut, +v_1: U32, +v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_2_OperandsFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_OperandsOk{v_11}:
      Phys.construct_part(v_1, v_11, cps_provider_2_phys_world(v_5))

def cps_provider_2_construct_part(+v_1: U32, +v_3: List<&2, BIR.Field>, +v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_construct_part_0(cps_provider_2_field_operands(v_3, v_5, []), v_1, v_5)

def native_match_cps_provider_2_field_operands_0(v_24: cps_provider_2_Part, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>, v_10: List<&2, BIR.Field>, v_17: BIR.Use) -> cps_provider_2_OperandsOut:
  match v_24:
    case cps_provider_2_PartFail{v_21}:
      cps_provider_2_OperandsFail{v_21}
    case cps_provider_2_PartOk{v_23}:
      cps_provider_2_field_operands(v_10, v_3, Phys.Operand{v_17, v_23} <> v_5)

def native_match_cps_provider_2_field_operands_1(+v_9: BIR.Field, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>, v_10: List<&2, BIR.Field>) -> cps_provider_2_OperandsOut:
  match v_9:
    case BIR.Field{v_15, v_16, v_17, v_18}:
      native_match_cps_provider_2_field_operands_0(cps_provider_2_atom_part(v_18, v_3), v_3, v_5, v_10, v_17)

def native_match_cps_provider_2_field_operands_2(v_1: List<&2, BIR.Field>, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>) -> cps_provider_2_OperandsOut:
  match v_1:
    case []:
      cps_provider_2_OperandsOk{List.reverse(&2, Phys.Operand, v_5)}
    case +v_9 <> v_10:
      native_match_cps_provider_2_field_operands_1(v_9, v_3, v_5, v_10)

def cps_provider_2_field_operands(v_1: List<&2, BIR.Field>, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>) -> cps_provider_2_OperandsOut:
  native_match_cps_provider_2_field_operands_2(v_1, v_3, v_5)

def cps_provider_2_values_part(v_2: List<&2, cps_provider_2_Part>, +v_5: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match v_2:
    case []:
      Some{List.reverse(&2, String, v_5)}
    case +v_12 <> v_13:
      match v_12:
        case cps_provider_2_PartFail{v_15}:
          None{}
        case cps_provider_2_PartOk{v_17}:
          cps_provider_2_values_part(v_13, v_17 <> v_5)

def native_match_cps_provider_2_project_part_0(v_13: cps_provider_2_Part, +v_2: U32, v_4: U32, +v_6: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_13:
    case cps_provider_2_PartFail{v_10}:
      cps_provider_2_PartFail{v_10}
    case cps_provider_2_PartOk{v_12}:
      Phys.project_part(v_12, v_2, v_4, cps_provider_2_phys_world(v_6))

def cps_provider_2_project_part(v_0: BIR.Atom, +v_2: U32, v_4: U32, +v_6: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_project_part_0(cps_provider_2_atom_part(v_0, v_6), v_2, v_4, v_6)

def native_match_cps_provider_2_hastag_part_0(v_11: cps_provider_2_Part, +v_2: U32, +v_4: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_11:
    case cps_provider_2_PartFail{v_8}:
      cps_provider_2_PartFail{v_8}
    case cps_provider_2_PartOk{v_10}:
      Phys.hastag_part(v_10, v_2, cps_provider_2_phys_world(v_4))

def cps_provider_2_hastag_part(v_0: BIR.Atom, +v_2: U32, +v_4: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_hastag_part_0(cps_provider_2_atom_part(v_0, v_4), v_2, v_4)

def native_match_cps_provider_2_prim_call_typed_0(v_7: Bool, +v_0: BIR.Primitive, +v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_7:
    case True{}:
      cps_provider_2_prim_array_part(v_0, v_2, v_4, v_6)
    case False{}:
      cps_provider_2_prim_call_part(v_0, v_2, v_6)

def cps_provider_2_prim_call_typed(+v_0: BIR.Primitive, +v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_prim_call_typed_0(cps_provider_2_is_array_primitive(v_0), v_0, v_2, v_4, v_6)

def native_match_cps_provider_2_prim_array_part_0(v_13: cps_provider_2_OperandsOut, +v_0: BIR.Primitive, v_4: List<&2, BIR.Descriptor>, v_6: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_13:
    case cps_provider_2_OperandsFail{v_10}:
      cps_provider_2_PartFail{v_10}
    case cps_provider_2_OperandsOk{v_12}:
      Phys.array_part(v_0, v_12, v_4, cps_provider_2_phys_world(v_6))

def cps_provider_2_prim_array_part(+v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, v_6: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_prim_array_part_0(cps_provider_2_arg_operands(v_2, v_6, []), v_0, v_4, v_6)

def native_match_cps_provider_2_arg_operands_0(v_20: cps_provider_2_Part, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>, v_10: List<&2, BIR.Arg>, v_13: BIR.Use) -> cps_provider_2_OperandsOut:
  match v_20:
    case cps_provider_2_PartFail{v_17}:
      cps_provider_2_OperandsFail{v_17}
    case cps_provider_2_PartOk{v_19}:
      cps_provider_2_arg_operands(v_10, v_3, Phys.Operand{v_13, v_19} <> v_5)

def native_match_cps_provider_2_arg_operands_1(+v_9: BIR.Arg, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>, v_10: List<&2, BIR.Arg>) -> cps_provider_2_OperandsOut:
  match v_9:
    case BIR.Arg{v_13, v_14}:
      native_match_cps_provider_2_arg_operands_0(cps_provider_2_atom_part(v_14, v_3), v_3, v_5, v_10, v_13)

def native_match_cps_provider_2_arg_operands_2(v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>) -> cps_provider_2_OperandsOut:
  match v_1:
    case []:
      cps_provider_2_OperandsOk{List.reverse(&2, Phys.Operand, v_5)}
    case +v_9 <> v_10:
      native_match_cps_provider_2_arg_operands_1(v_9, v_3, v_5, v_10)

def cps_provider_2_arg_operands(v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Plan, +v_5: List<&2, Phys.Operand>) -> cps_provider_2_OperandsOut:
  native_match_cps_provider_2_arg_operands_2(v_1, v_3, v_5)

def cps_provider_2_is_array_primitive(v_0: BIR.Primitive) -> Bool:
  match v_0:
    case BIR.PrimArrayNew{}:
      True{}
    case BIR.PrimArrayGet{}:
      True{}
    case BIR.PrimArraySet{}:
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

def native_match_cps_provider_2_prim_call_part_0(v_13: Maybe<&2, List<&2, String>>, v_0: BIR.Primitive, +v_4: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_13:
    case None{}:
      cps_provider_2_failp("BIR argument has no C value")
    case Some{v_12}:
      cps_provider_2_prim_part(v_0, v_12, v_4)

def native_match_cps_provider_2_prim_call_part_1(v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, +v_4: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_0:
    case BIR.PrimStringAppend{}:
      cps_provider_2_append_part(v_2, v_4)
    case _:
      native_match_cps_provider_2_prim_call_part_0(cps_provider_2_arg_strings(v_2, v_4), v_0, v_4)

def cps_provider_2_prim_call_part(v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, +v_4: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_prim_call_part_1(v_0, v_2, v_4)

def native_match_cps_provider_2_append_part_0(v_9: Maybe<&2, cps_provider_2_AppendTexts>, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_9:
    case None{}:
      cps_provider_2_failp("BIR argument has no C value")
    case Some{v_8}:
      cps_provider_2_append_cids(v_8, v_3)

def cps_provider_2_append_part(v_1: List<&2, BIR.Arg>, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_append_part_0(cps_provider_2_append_texts(v_1, v_3, [], None{}), v_3)

def native_match_cps_provider_2_append_texts_0(v_25: cps_provider_2_Part, +v_3: cps_provider_2_Plan, +v_6: List<&2, String>, v_15: List<&2, BIR.Arg>, v_18: BIR.Use) -> Maybe<&2, cps_provider_2_AppendTexts>:
  match v_25:
    case cps_provider_2_PartFail{v_22}:
      None{}
    case cps_provider_2_PartOk{v_24}:
      cps_provider_2_append_texts(v_15, v_3, v_24 <> v_6, Some{v_18})

def native_match_cps_provider_2_append_texts_1(+v_14: BIR.Arg, +v_3: cps_provider_2_Plan, +v_6: List<&2, String>, v_15: List<&2, BIR.Arg>) -> Maybe<&2, cps_provider_2_AppendTexts>:
  match v_14:
    case BIR.Arg{v_18, v_19}:
      native_match_cps_provider_2_append_texts_0(cps_provider_2_atom_part(v_19, v_3), v_3, v_6, v_15, v_18)

def native_match_cps_provider_2_append_texts_2(v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Plan, +v_6: List<&2, String>, +v_8: Maybe<&2, BIR.Use>) -> Maybe<&2, cps_provider_2_AppendTexts>:
  match v_1:
    case []:
      Some{cps_provider_2_AppendTexts{List.reverse(&2, String, v_6), v_8}}
    case +v_14 <> v_15:
      native_match_cps_provider_2_append_texts_1(v_14, v_3, v_6, v_15)

def cps_provider_2_append_texts(v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Plan, +v_6: List<&2, String>, +v_8: Maybe<&2, BIR.Use>) -> Maybe<&2, cps_provider_2_AppendTexts>:
  native_match_cps_provider_2_append_texts_2(v_1, v_3, v_6, v_8)

def native_match_cps_provider_2_append_cids_0(v_7: List<&2, String>, v_8: Maybe<&2, BIR.Use>, v_13: String, v_14: String) -> cps_provider_2_Part:
  match v_7:
    case +v_18 <> +v_19 <> _:
      cps_provider_2_okp(cps_provider_2_cat(["bend_str_append(e, ", v_13, ", ", v_14, ", ", v_18, ", ", v_19, ", ", cps_provider_2_keep_flag(v_8), ")"]))
    case _:
      cps_provider_2_failp("a string append needs two operands")

def native_match_cps_provider_2_append_cids_1(v_35: cps_provider_2_Part, v_36: cps_provider_2_Part, v_7: List<&2, String>, v_8: Maybe<&2, BIR.Use>) -> cps_provider_2_Part:
  match v_35, v_36:
    case cps_provider_2_PartOk{v_13}, cps_provider_2_PartOk{v_14}:
      native_match_cps_provider_2_append_cids_0(v_7, v_8, v_13, v_14)
    case cps_provider_2_PartFail{v_29}, _:
      cps_provider_2_PartFail{v_29}
    case _, cps_provider_2_PartFail{v_34}:
      cps_provider_2_PartFail{v_34}

def native_match_cps_provider_2_append_cids_2(v_1: cps_provider_2_AppendTexts, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_AppendTexts{v_7, v_8}:
      native_match_cps_provider_2_append_cids_1(cps_provider_2_pcid("SCon", v_3), cps_provider_2_pcid("Chr", v_3), v_7, v_8)

def cps_provider_2_append_cids(v_1: cps_provider_2_AppendTexts, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_append_cids_2(v_1, v_3)

def cps_provider_2_keep_flag(v_1: Maybe<&2, BIR.Use>) -> String:
  match v_1:
    case Some{BIR.Many{}}:
      "1"
    case _:
      "0"

def cps_provider_2_pcid(v_1: String, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_Plan{v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, _, _}:
      cps_provider_2_cid_c(v_1, v_26)

def native_match_cps_provider_2_prim_part_0(v_0: BIR.Primitive, +v_5: cps_provider_2_Plan, +v_9: String, +v_12: String, +v_15: String) -> cps_provider_2_Part:
  match v_0:
    case BIR.PrimU32Add{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", +, ", v_12, ")"]))
    case BIR.PrimU32Sub{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", -, ", v_12, ")"]))
    case BIR.PrimU32Mul{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", *, ", v_12, ")"]))
    case BIR.PrimU32Div{}:
      cps_provider_2_okp(cps_provider_2_cat(["((u32)(", v_12, ") == 0 ? 0 : (u64)U32_QUO((u32)(", v_9, "), (u32)(", v_12, ")))"]))
    case BIR.PrimU32Mod{}:
      cps_provider_2_okp(cps_provider_2_cat(["((u32)(", v_12, ") == 0 ? ", v_9, " : U32_BIN(", v_9, ", -, U32_QUO((u32)(", v_9, "), (u32)(", v_12, ")) * ", v_12, "))"]))
    case BIR.PrimU32And{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", &, ", v_12, ")"]))
    case BIR.PrimU32Or{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", |, ", v_12, ")"]))
    case BIR.PrimU32Xor{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", ^, ", v_12, ")"]))
    case BIR.PrimU32IsEq{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", ==, ", v_12, ")"]))
    case BIR.PrimU32IsNe{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", !=, ", v_12, ")"]))
    case BIR.PrimU32IsLt{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", <, ", v_12, ")"]))
    case BIR.PrimU32IsLe{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", <=, ", v_12, ")"]))
    case BIR.PrimU32IsGt{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", >, ", v_12, ")"]))
    case BIR.PrimU32IsGe{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", >=, ", v_12, ")"]))
    case BIR.PrimU32IsZero{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", ==, 0)"]))
    case BIR.PrimU32Inc{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", +, 1)"]))
    case BIR.PrimU32Not{}:
      cps_provider_2_okp(cps_provider_2_cat(["((u64)~(u32)(", v_9, "))"]))
    case BIR.PrimU32Shl{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", <<, 1)"]))
    case BIR.PrimU32Shr{}:
      cps_provider_2_okp(cps_provider_2_cat(["U32_BIN(", v_9, ", >>, 1)"]))
    case BIR.PrimU32Shln{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_12, " >= 32 ? 0 : U32_BIN(", v_9, ", <<, ", v_12, "))"]))
    case BIR.PrimU32Shrn{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_12, " >= 32 ? 0 : U32_BIN(", v_9, ", >>, ", v_12, "))"]))
    case BIR.PrimU32ToNat{}:
      cps_provider_2_okp(cps_provider_2_cat(["((u64)", v_9, ")"]))
    case BIR.PrimU32FromNat{}:
      cps_provider_2_okp(cps_provider_2_cat(["((u64)(u32)(", v_9, "))"]))
    case BIR.PrimU32ToF32{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_rewrap((f32)(u32)(", v_9, "))"]))
    case BIR.PrimU32Cmp{}:
      cps_provider_2_cmp3_part(v_9, v_12, v_5)
    case BIR.PrimNatAdd{}:
      cps_provider_2_okp(cps_provider_2_cat(["nat_chk(e, ", v_9, " + ", v_12, ")"]))
    case BIR.PrimNatSub{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " < ", v_12, " ? 0 : ", v_9, " - ", v_12, ")"]))
    case BIR.PrimNatMul{}:
      cps_provider_2_okp(cps_provider_2_cat(["nat_mul(e, ", v_9, ", ", v_12, ")"]))
    case BIR.PrimNatCmp{}:
      cps_provider_2_cmp3_part(v_9, v_12, v_5)
    case BIR.PrimNatMin{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " < ", v_12, " ? ", v_9, " : ", v_12, ")"]))
    case BIR.PrimNatMax{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " > ", v_12, " ? ", v_9, " : ", v_12, ")"]))
    case BIR.PrimNatIsLt{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " < ", v_12, ")"]))
    case BIR.PrimNatDouble{}:
      cps_provider_2_okp(cps_provider_2_cat(["nat_chk(e, ", v_9, " + ", v_9, ")"]))
    case BIR.PrimNatPredecessor{}:
      cps_provider_2_okp(cps_provider_2_cat(["bend_nat_pred(", v_9, ")"]))
    case BIR.PrimNatSuccessor{}:
      cps_provider_2_okp(cps_provider_2_cat(["nat_chk(e, ", v_9, " + 1)"]))
    case BIR.PrimNatDivmod{}:
      cps_provider_2_divmod_part(v_9, v_12, v_5)
    case BIR.PrimBoolOr{}:
      cps_provider_2_bool2_part("bend_bool_or", v_9, v_12, v_5)
    case BIR.PrimBoolXor{}:
      cps_provider_2_bool2_part("bend_bool_xor", v_9, v_12, v_5)
    case BIR.PrimF32Add{}:
      cps_provider_2_f32_bin("+", v_9, v_12)
    case BIR.PrimF32Sub{}:
      cps_provider_2_f32_bin("-", v_9, v_12)
    case BIR.PrimF32Mul{}:
      cps_provider_2_f32_bin("*", v_9, v_12)
    case BIR.PrimF32Div{}:
      cps_provider_2_f32_bin("/", v_9, v_12)
    case BIR.PrimF32Mod{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_rewrap((f32)fmod(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]))
    case BIR.PrimF32Neg{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_rewrap(-f32_unbox(", v_9, "))"]))
    case BIR.PrimF32Sqrt{}:
      cps_provider_2_f32_un("sqrt", v_9)
    case BIR.PrimF32Abs{}:
      cps_provider_2_f32_un("fabs", v_9)
    case BIR.PrimF32Exp{}:
      cps_provider_2_f32_un("exp", v_9)
    case BIR.PrimF32Log{}:
      cps_provider_2_f32_un("log", v_9)
    case BIR.PrimF32Log2{}:
      cps_provider_2_f32_un("log2", v_9)
    case BIR.PrimF32Log10{}:
      cps_provider_2_f32_un("log10", v_9)
    case BIR.PrimF32Sin{}:
      cps_provider_2_f32_un("sin", v_9)
    case BIR.PrimF32Cos{}:
      cps_provider_2_f32_un("cos", v_9)
    case BIR.PrimF32Tan{}:
      cps_provider_2_f32_un("tan", v_9)
    case BIR.PrimF32Asin{}:
      cps_provider_2_f32_un("asin", v_9)
    case BIR.PrimF32Acos{}:
      cps_provider_2_f32_un("acos", v_9)
    case BIR.PrimF32Atan{}:
      cps_provider_2_f32_un("atan", v_9)
    case BIR.PrimF32Sinh{}:
      cps_provider_2_f32_un("sinh", v_9)
    case BIR.PrimF32Cosh{}:
      cps_provider_2_f32_un("cosh", v_9)
    case BIR.PrimF32Tanh{}:
      cps_provider_2_f32_un("tanh", v_9)
    case BIR.PrimF32Floor{}:
      cps_provider_2_f32_un("floor", v_9)
    case BIR.PrimF32Ceil{}:
      cps_provider_2_f32_un("ceil", v_9)
    case BIR.PrimF32Trunc{}:
      cps_provider_2_f32_un("trunc", v_9)
    case BIR.PrimF32Pow{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_rewrap((f32)pow(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]))
    case BIR.PrimF32Atan2{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_rewrap((f32)atan2(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]))
    case BIR.PrimF32IsEq{}:
      cps_provider_2_f32_cmp("==", v_9, v_12)
    case BIR.PrimF32IsNe{}:
      cps_provider_2_f32_cmp("!=", v_9, v_12)
    case BIR.PrimF32IsLt{}:
      cps_provider_2_f32_cmp("<", v_9, v_12)
    case BIR.PrimF32IsLe{}:
      cps_provider_2_f32_cmp("<=", v_9, v_12)
    case BIR.PrimF32IsGt{}:
      cps_provider_2_f32_cmp(">", v_9, v_12)
    case BIR.PrimF32IsGe{}:
      cps_provider_2_f32_cmp(">=", v_9, v_12)
    case BIR.PrimF32ToU32{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_to_u32(", v_9, ")"]))
    case BIR.PrimF32Bits{}:
      cps_provider_2_okp(v_9)
    case BIR.PrimF32FromBits{}:
      cps_provider_2_okp(v_9)
    case BIR.PrimF32Show{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_show(e, ", v_9, ")"]))
    case BIR.PrimF32Read{}:
      cps_provider_2_okp(cps_provider_2_cat(["f32_read(e, ", v_9, ")"]))
    case BIR.PrimF32ToNat{}:
      cps_provider_2_okp(cps_provider_2_cat(["bend_f32_to_nat(e, ", v_9, ")"]))
    case BIR.PrimStringAppend{}:
      cps_provider_2_failp("a string append is emitted by append_part, which needs its operand quantities")
    case BIR.PrimStringEq{}:
      cps_provider_2_str2("bend_str_eq", "SCon", v_9, v_12, v_5)
    case BIR.PrimStringLength{}:
      cps_provider_2_str1("bend_str_length", "SCon", v_9, v_5)
    case BIR.PrimStringToList{}:
      cps_provider_2_str_to_list(v_9, v_5)
    case BIR.PrimStringCmp{}:
      cps_provider_2_str_cmp(v_9, v_12, v_5)
    case BIR.PrimStringHead{}:
      cps_provider_2_str1_char("bend_str_head", "SCon", v_9, v_5)
    case BIR.PrimStringTail{}:
      cps_provider_2_str_tail(v_9, v_5)
    case BIR.PrimMapBit{}:
      cps_provider_2_map_bit_part(v_9, v_12, v_5)
    case BIR.PrimArrayNew{}:
      cps_provider_2_okp(cps_provider_2_cat(["bend_array_new(e, ", v_9, ", ", v_12, ")"]))
    case BIR.PrimArrayGet{}:
      cps_provider_2_arr2("bend_array_get", v_9, v_12, v_5)
    case BIR.PrimArraySet{}:
      cps_provider_2_okp(cps_provider_2_cat(["bend_array_set(e, ", v_9, ", ", v_12, ", ", v_15, ")"]))
    case BIR.PrimArraySwap{}:
      cps_provider_2_arr_swap(v_9, v_12, v_15, v_5)
    case BIR.PrimArraySize{}:
      cps_provider_2_arr1("bend_array_size", v_9, v_5)
    case BIR.PrimArrayClone{}:
      cps_provider_2_arr1("bend_array_clone", v_9, v_5)
    case BIR.PrimArrayLeaf{}:
      cps_provider_2_okp(cps_provider_2_cat(["bend_array_leaf(e, ", v_9, ")"]))
    case BIR.PrimArrayNode{}:
      cps_provider_2_okp(cps_provider_2_cat(["blk_node(e, ", v_9, ", ", v_12, ")"]))
    case BIR.PrimArrayLeafValue{}:
      cps_provider_2_okp(cps_provider_2_cat(["bend_array_leaf_value(e, ", v_9, ")"]))
    case BIR.PrimArrayLeft{}:
      cps_provider_2_okp(cps_provider_2_cat(["blk_half(e, ", v_9, ", 0)"]))
    case BIR.PrimArrayRight{}:
      cps_provider_2_okp(cps_provider_2_cat(["blk_half(e, ", v_9, ", 1)"]))
    case BIR.PrimIsArrayLeaf{}:
      cps_provider_2_okp(cps_provider_2_cat(["((u32)blk_cls(", v_9, ") == 0)"]))
    case BIR.PrimIsArrayNode{}:
      cps_provider_2_okp(cps_provider_2_cat(["((u32)blk_cls(", v_9, ") != 0)"]))
    case BIR.PrimIsNatZero{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " == 0)"]))
    case BIR.PrimIsNatSuccessor{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " > 0)"]))
    case BIR.PrimIsStringEmpty{}:
      cps_provider_2_str_empty("bend_str_empty", "SNil", v_9, v_5)
    case BIR.PrimIsStringNonempty{}:
      cps_provider_2_str_empty_neg(v_9, v_5)
    case BIR.PrimIsTrue{}:
      cps_provider_2_is_bool_part("True", v_9, v_5)
    case BIR.PrimIsFalse{}:
      cps_provider_2_is_bool_part("False", v_9, v_5)
    case BIR.PrimSameValue{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " == ", v_12, ")"]))
    case BIR.PrimFloatBitsEqual{}:
      cps_provider_2_okp(cps_provider_2_cat(["(", v_9, " == ", v_12, ")"]))
    case BIR.PrimCharNew{}:
      cps_provider_2_char_new_part(v_9, v_5)
    case BIR.PrimCharCode{}:
      cps_provider_2_okp(cps_provider_2_cat(["term_loc(", v_9, ")"]))
    case BIR.PrimWordToU32{}:
      cps_provider_2_okp(cps_provider_2_cat(["term_word(e, ", v_9, ")"]))
    case BIR.PrimU32ToWord{}:
      cps_provider_2_word_part(v_9, v_5)
    case BIR.PrimF32FromWord{}:
      cps_provider_2_okp(cps_provider_2_cat(["term_word(e, ", v_9, ")"]))
    case BIR.PrimF32ToWord{}:
      cps_provider_2_word_part(v_9, v_5)
    case _:
      cps_provider_2_failp("BIR primitive has no C rendering")

def cps_provider_2_prim_part(v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  +v_9 = cps_provider_2_list_at(v_3, 0n)
  +v_12 = cps_provider_2_list_at(v_3, 1n)
  +v_15 = cps_provider_2_list_at(v_3, 2n)
  native_match_cps_provider_2_prim_part_0(v_0, v_5, v_9, v_12, v_15)

def cps_provider_2_f32_bin(v_1: String, v_3: String, v_5: String) -> cps_provider_2_Part:
  cps_provider_2_okp(cps_provider_2_cat(["f32_rewrap(f32_unbox(", v_3, ") ", v_1, " f32_unbox(", v_5, "))"]))

def cps_provider_2_f32_un(v_1: String, v_3: String) -> cps_provider_2_Part:
  cps_provider_2_okp(cps_provider_2_cat(["f32_rewrap((f32)", v_1, "(f32_unbox(", v_3, ")))"]))

def cps_provider_2_f32_cmp(v_1: String, v_3: String, v_5: String) -> cps_provider_2_Part:
  cps_provider_2_okp(cps_provider_2_cat(["((u64)(f32_unbox(", v_3, ") ", v_1, " f32_unbox(", v_5, ")))"]))

def cps_provider_2_bool2_part(v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_7:
    case cps_provider_2_Plan{+v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45, v_46, v_47, v_48, _, _}:
      cps_provider_2_bool2_c(v_1, v_3, v_5, cps_provider_2_cid_c("True", v_30), cps_provider_2_cid_c("False", v_30))

def cps_provider_2_bool2_c(v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Part, v_9: cps_provider_2_Part) -> cps_provider_2_Part:
  match v_7, v_9:
    case cps_provider_2_PartOk{v_13}, cps_provider_2_PartOk{v_14}:
      cps_provider_2_okp(cps_provider_2_cat([v_1, "(e, ", v_13, ", ", v_14, ", ", v_3, ", ", v_5, ")"]))
    case cps_provider_2_PartFail{v_19}, _:
      cps_provider_2_PartFail{v_19}
    case _, cps_provider_2_PartFail{v_24}:
      cps_provider_2_PartFail{v_24}

def native_match_cps_provider_2_is_bool_part_0(v_12: cps_provider_2_Part, v_3: String) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_2_PartFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_PartOk{v_11}:
      cps_provider_2_okp(cps_provider_2_cat(["term_aux(", v_3, ") == (u64)", v_11]))

def cps_provider_2_is_bool_part(v_1: String, v_3: String, v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_is_bool_part_0(cps_provider_2_pcid(v_1, v_5), v_3)

def native_match_cps_provider_2_cmp3_part_0(v_9: cps_provider_2_Part, v_12: cps_provider_2_Part, v_15: cps_provider_2_Part, v_1: String, v_3: String) -> cps_provider_2_Part:
  match v_9, v_12, v_15:
    case cps_provider_2_PartOk{v_19}, cps_provider_2_PartOk{v_20}, cps_provider_2_PartOk{v_21}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_cmp3(e, ", v_19, ", ", v_20, ", ", v_21, ", ", v_1, ", ", v_3, ")"])}
    case cps_provider_2_PartFail{v_26}, _, _:
      cps_provider_2_PartFail{v_26}
    case _, cps_provider_2_PartFail{v_33}, _:
      cps_provider_2_PartFail{v_33}
    case _, _, cps_provider_2_PartFail{v_40}:
      cps_provider_2_PartFail{v_40}

def cps_provider_2_cmp3_part(v_1: String, v_3: String, +v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  v_9 = cps_provider_2_pcid("LT", v_5)
  v_12 = cps_provider_2_pcid("EQ", v_5)
  v_15 = cps_provider_2_pcid("GT", v_5)
  native_match_cps_provider_2_cmp3_part_0(v_9, v_12, v_15, v_1, v_3)

def native_match_cps_provider_2_divmod_part_0(v_9: cps_provider_2_Part, v_1: String, v_3: String) -> cps_provider_2_Part:
  match v_9:
    case cps_provider_2_PartFail{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_2_PartOk{v_13}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_divmod(e, ", v_13, ", ", v_1, ", ", v_3, ")"])}

def cps_provider_2_divmod_part(v_1: String, v_3: String, v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  v_9 = cps_provider_2_pcid("Tuple", v_5)
  native_match_cps_provider_2_divmod_part_0(v_9, v_1, v_3)

def native_match_cps_provider_2_str2_0(v_16: cps_provider_2_Part, v_1: String, v_5: String, v_7: String) -> cps_provider_2_Part:
  match v_16:
    case cps_provider_2_PartFail{v_13}:
      cps_provider_2_PartFail{v_13}
    case cps_provider_2_PartOk{v_15}:
      cps_provider_2_PartOk{cps_provider_2_cat([v_1, "(e, ", v_15, ", ", v_5, ", ", v_7, ")"])}

def cps_provider_2_str2(v_1: String, v_3: String, v_5: String, v_7: String, v_9: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str2_0(cps_provider_2_pcid(v_3, v_9), v_1, v_5, v_7)

def native_match_cps_provider_2_str1_0(v_14: cps_provider_2_Part, v_1: String, v_5: String) -> cps_provider_2_Part:
  match v_14:
    case cps_provider_2_PartFail{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_2_PartOk{v_13}:
      cps_provider_2_PartOk{cps_provider_2_cat([v_1, "(e, ", v_13, ", ", v_5, ")"])}

def cps_provider_2_str1(v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str1_0(cps_provider_2_pcid(v_3, v_7), v_1, v_5)

def native_match_cps_provider_2_str_empty_0(v_14: cps_provider_2_Part, v_1: String, v_5: String) -> cps_provider_2_Part:
  match v_14:
    case cps_provider_2_PartFail{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_2_PartOk{v_13}:
      cps_provider_2_PartOk{cps_provider_2_cat([v_1, "(", v_5, ", ", v_13, ")"])}

def cps_provider_2_str_empty(v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str_empty_0(cps_provider_2_pcid(v_3, v_7), v_1, v_5)

def native_match_cps_provider_2_str_empty_neg_0(v_10: cps_provider_2_Part, v_1: String) -> cps_provider_2_Part:
  match v_10:
    case cps_provider_2_PartFail{v_7}:
      cps_provider_2_PartFail{v_7}
    case cps_provider_2_PartOk{v_9}:
      cps_provider_2_PartOk{cps_provider_2_cat(["(!bend_str_empty(", v_1, ", ", v_9, "))"])}

def cps_provider_2_str_empty_neg(v_1: String, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str_empty_neg_0(cps_provider_2_pcid("SNil", v_3), v_1)

def native_match_cps_provider_2_str_tail_0(v_20: cps_provider_2_Part, v_21: cps_provider_2_Part, v_1: String) -> cps_provider_2_Part:
  match v_20, v_21:
    case cps_provider_2_PartOk{v_9}, cps_provider_2_PartOk{v_10}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_str_tail(e, ", v_9, ", ", v_10, ", ", v_1, ")"])}
    case cps_provider_2_PartFail{v_14}, _:
      cps_provider_2_PartFail{v_14}
    case _, cps_provider_2_PartFail{v_19}:
      cps_provider_2_PartFail{v_19}

def cps_provider_2_str_tail(v_1: String, +v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str_tail_0(cps_provider_2_pcid("SCon", v_3), cps_provider_2_pcid("SNil", v_3), v_1)

def native_match_cps_provider_2_str_to_list_0(v_59: cps_provider_2_Part, v_1: String, v_13: String, v_14: String, v_15: String, v_16: String) -> cps_provider_2_Part:
  match v_59:
    case cps_provider_2_PartFail{v_19}:
      cps_provider_2_PartFail{v_19}
    case cps_provider_2_PartOk{v_21}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_str_to_list(e, ", v_13, ", ", v_14, ", ", v_15, ", ", v_16, ", ", v_21, ", ", v_1, ")"])}

def native_match_cps_provider_2_str_to_list_1(v_55: cps_provider_2_Part, v_56: cps_provider_2_Part, v_57: cps_provider_2_Part, v_58: cps_provider_2_Part, v_1: String, +v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_55, v_56, v_57, v_58:
    case cps_provider_2_PartOk{v_13}, cps_provider_2_PartOk{v_14}, cps_provider_2_PartOk{v_15}, cps_provider_2_PartOk{v_16}:
      native_match_cps_provider_2_str_to_list_0(cps_provider_2_pcid("Chr", v_3), v_1, v_13, v_14, v_15, v_16)
    case cps_provider_2_PartFail{v_27}, _, _, _:
      cps_provider_2_PartFail{v_27}
    case _, cps_provider_2_PartFail{v_36}, _, _:
      cps_provider_2_PartFail{v_36}
    case _, _, cps_provider_2_PartFail{v_45}, _:
      cps_provider_2_PartFail{v_45}
    case _, _, _, cps_provider_2_PartFail{v_54}:
      cps_provider_2_PartFail{v_54}

def cps_provider_2_str_to_list(v_1: String, +v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str_to_list_1(cps_provider_2_pcid("SCon", v_3), cps_provider_2_pcid("SNil", v_3), cps_provider_2_pcid("Con", v_3), cps_provider_2_pcid("Nil", v_3), v_1, v_3)

def native_match_cps_provider_2_str1_char_0(v_14: cps_provider_2_Part, v_1: String, v_5: String, v_7: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_14:
    case cps_provider_2_PartFail{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_2_PartOk{v_13}:
      cps_provider_2_char_pack_part(cps_provider_2_cat([v_1, "(e, ", v_13, ", ", v_5, ")"]), v_7)

def cps_provider_2_str1_char(v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str1_char_0(cps_provider_2_pcid(v_3, v_7), v_1, v_5, v_7)

def native_match_cps_provider_2_char_pack_part_0(v_10: cps_provider_2_Part, v_1: String) -> cps_provider_2_Part:
  match v_10:
    case cps_provider_2_PartFail{v_7}:
      cps_provider_2_PartFail{v_7}
    case cps_provider_2_PartOk{v_9}:
      cps_provider_2_PartOk{cps_provider_2_cat(["term_pak(", v_9, ", (u64)(", v_1, "))"])}

def cps_provider_2_char_pack_part(v_1: String, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_char_pack_part_0(cps_provider_2_pcid("Chr", v_3), v_1)

def native_match_cps_provider_2_str_cmp_0(v_73: cps_provider_2_Part, v_74: cps_provider_2_Part, v_75: cps_provider_2_Part, v_76: cps_provider_2_Part, v_77: cps_provider_2_Part, v_1: String, v_3: String) -> cps_provider_2_Part:
  match v_73, v_74, v_75, v_76, v_77:
    case cps_provider_2_PartOk{v_17}, cps_provider_2_PartOk{v_18}, cps_provider_2_PartOk{v_19}, cps_provider_2_PartOk{v_20}, cps_provider_2_PartOk{v_21}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_str_cmp(e, ", v_17, ", ", v_18, ", ", v_19, ", ", v_20, ", ", v_21, ", ", v_1, ", ", v_3, ")"])}
    case cps_provider_2_PartFail{v_28}, _, _, _, _:
      cps_provider_2_PartFail{v_28}
    case _, cps_provider_2_PartFail{v_39}, _, _, _:
      cps_provider_2_PartFail{v_39}
    case _, _, cps_provider_2_PartFail{v_50}, _, _:
      cps_provider_2_PartFail{v_50}
    case _, _, _, cps_provider_2_PartFail{v_61}, _:
      cps_provider_2_PartFail{v_61}
    case _, _, _, _, cps_provider_2_PartFail{v_72}:
      cps_provider_2_PartFail{v_72}

def cps_provider_2_str_cmp(v_1: String, v_3: String, +v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_str_cmp_0(cps_provider_2_pcid("SCon", v_5), cps_provider_2_pcid("Tuple", v_5), cps_provider_2_pcid("LT", v_5), cps_provider_2_pcid("EQ", v_5), cps_provider_2_pcid("GT", v_5), v_1, v_3)

def native_match_cps_provider_2_map_bit_part_0(v_52: cps_provider_2_Part, v_53: cps_provider_2_Part, v_54: cps_provider_2_Part, v_55: cps_provider_2_Part, v_1: String, v_3: String) -> cps_provider_2_Part:
  match v_52, v_53, v_54, v_55:
    case cps_provider_2_PartOk{v_15}, cps_provider_2_PartOk{v_16}, cps_provider_2_PartOk{v_17}, cps_provider_2_PartOk{v_18}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_map_bit(e, ", v_15, ", ", v_16, ", ", v_17, ", ", v_18, ", ", v_1, ", ", v_3, ")"])}
    case cps_provider_2_PartFail{v_24}, _, _, _:
      cps_provider_2_PartFail{v_24}
    case _, cps_provider_2_PartFail{v_33}, _, _:
      cps_provider_2_PartFail{v_33}
    case _, _, cps_provider_2_PartFail{v_42}, _:
      cps_provider_2_PartFail{v_42}
    case _, _, _, cps_provider_2_PartFail{v_51}:
      cps_provider_2_PartFail{v_51}

def cps_provider_2_map_bit_part(v_1: String, v_3: String, +v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_map_bit_part_0(cps_provider_2_pcid("SCon", v_5), cps_provider_2_pcid("Tuple", v_5), cps_provider_2_pcid("True", v_5), cps_provider_2_pcid("False", v_5), v_1, v_3)

def native_match_cps_provider_2_arr1_0(v_12: cps_provider_2_Part, v_1: String, v_3: String) -> cps_provider_2_Part:
  match v_12:
    case cps_provider_2_PartFail{v_9}:
      cps_provider_2_PartFail{v_9}
    case cps_provider_2_PartOk{v_11}:
      cps_provider_2_PartOk{cps_provider_2_cat([v_1, "(e, ", v_11, ", ", v_3, ")"])}

def cps_provider_2_arr1(v_1: String, v_3: String, v_5: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_arr1_0(cps_provider_2_pcid("Tuple", v_5), v_1, v_3)

def native_match_cps_provider_2_arr2_0(v_14: cps_provider_2_Part, v_1: String, v_3: String, v_5: String) -> cps_provider_2_Part:
  match v_14:
    case cps_provider_2_PartFail{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_2_PartOk{v_13}:
      cps_provider_2_PartOk{cps_provider_2_cat([v_1, "(e, ", v_13, ", ", v_3, ", ", v_5, ")"])}

def cps_provider_2_arr2(v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_arr2_0(cps_provider_2_pcid("Tuple", v_7), v_1, v_3, v_5)

def native_match_cps_provider_2_arr_swap_0(v_14: cps_provider_2_Part, v_1: String, v_3: String, v_5: String) -> cps_provider_2_Part:
  match v_14:
    case cps_provider_2_PartFail{v_11}:
      cps_provider_2_PartFail{v_11}
    case cps_provider_2_PartOk{v_13}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_array_swap(e, ", v_13, ", ", v_1, ", ", v_3, ", ", v_5, ")"])}

def cps_provider_2_arr_swap(v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_arr_swap_0(cps_provider_2_pcid("Tuple", v_7), v_1, v_3, v_5)

def native_match_cps_provider_2_char_new_part_0(v_10: cps_provider_2_Part, v_1: String) -> cps_provider_2_Part:
  match v_10:
    case cps_provider_2_PartFail{v_7}:
      cps_provider_2_PartFail{v_7}
    case cps_provider_2_PartOk{v_9}:
      cps_provider_2_PartOk{cps_provider_2_cat(["term_pak(", v_9, ", (u64)(", v_1, "))"])}

def cps_provider_2_char_new_part(v_1: String, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_char_new_part_0(cps_provider_2_pcid("Chr", v_3), v_1)

def native_match_cps_provider_2_word_part_0(v_20: cps_provider_2_Part, v_21: cps_provider_2_Part, v_1: String) -> cps_provider_2_Part:
  match v_20, v_21:
    case cps_provider_2_PartOk{v_9}, cps_provider_2_PartOk{v_10}:
      cps_provider_2_PartOk{cps_provider_2_cat(["bend_u32_to_word(e, ", v_9, ", ", v_10, ", ", v_1, ")"])}
    case cps_provider_2_PartFail{v_14}, _:
      cps_provider_2_PartFail{v_14}
    case _, cps_provider_2_PartFail{v_19}:
      cps_provider_2_PartFail{v_19}

def cps_provider_2_word_part(v_1: String, +v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  native_match_cps_provider_2_word_part_0(cps_provider_2_pcid("WCon", v_3), cps_provider_2_pcid("WNil", v_3), v_1)

def native_match_cps_provider_2_u32_member_0(v_10: Bool, +v_4: U32, v_9: List<&2, U32>) -> Bool:
  match v_10:
    case True{}:
      True{}
    case False{}:
      cps_provider_2_u32_member(v_9, v_4)

def native_match_cps_provider_2_u32_member_1(v_2: List<&2, U32>, +v_4: U32) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_8 <> v_9:
      native_match_cps_provider_2_u32_member_0(U32.is_eq(v_8, v_4), v_4, v_9)

def cps_provider_2_u32_member(v_2: List<&2, U32>, +v_4: U32) -> Bool:
  native_match_cps_provider_2_u32_member_1(v_2, v_4)

def native_match_cps_provider_2_u32_add_0(v_5: Bool, +v_2: List<&2, U32>, +v_4: U32) -> List<&2, U32>:
  match v_5:
    case True{}:
      v_2
    case False{}:
      v_4 <> v_2

def cps_provider_2_u32_add(+v_2: List<&2, U32>, +v_4: U32) -> List<&2, U32>:
  native_match_cps_provider_2_u32_add_0(cps_provider_2_u32_member(v_2, v_4), v_2, v_4)

def cps_provider_2_atom_locals(v_0: BIR.Atom, +v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Local{v_7}:
      cps_provider_2_u32_add(v_3, v_7)
    case _:
      v_3

def cps_provider_2_arg_locals(v_0: BIR.Arg, v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Arg{v_8, v_9}:
      cps_provider_2_atom_locals(v_9, v_3)

def cps_provider_2_args_locals(v_1: List<&2, BIR.Arg>, +v_4: List<&2, U32>) -> List<&2, U32>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      cps_provider_2_args_locals(v_10, cps_provider_2_arg_locals(v_9, v_4))

def cps_provider_2_field_locals(v_1: List<&2, BIR.Field>, +v_4: List<&2, U32>) -> List<&2, U32>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      match v_9:
        case BIR.Field{v_15, v_16, v_17, v_18}:
          cps_provider_2_field_locals(v_10, cps_provider_2_atom_locals(v_18, v_4))

def cps_provider_2_op_locals(v_0: BIR.Op, +v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Copy{v_7}:
      cps_provider_2_atom_locals(v_7, v_3)
    case BIR.PrimitiveCall{v_12, v_13, v_14}:
      cps_provider_2_args_locals(v_13, v_3)
    case BIR.Closure{v_19, v_20, v_21}:
      cps_provider_2_args_locals(v_20, v_3)
    case BIR.Direct{v_25, v_26}:
      cps_provider_2_args_locals(v_26, v_3)
    case BIR.Apply{v_30, v_31}:
      cps_provider_2_arg_locals(v_31, cps_provider_2_atom_locals(v_30, v_3))
    case BIR.Construct{v_37, v_38, v_39}:
      cps_provider_2_field_locals(v_39, v_3)
    case BIR.Project{v_45, v_46, v_47, v_48}:
      cps_provider_2_atom_locals(v_45, v_3)
    case BIR.HasTag{v_53, v_54, v_55}:
      cps_provider_2_atom_locals(v_53, v_3)
    case _:
      v_3

def cps_provider_2_block_locals(v_0: BIR.Block, +v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Return{v_7}:
      cps_provider_2_atom_locals(v_7, v_3)
    case BIR.Let{v_12, v_13, v_14}:
      cps_provider_2_block_locals(v_14, cps_provider_2_op_locals(v_13, v_3))
    case BIR.Branch{v_20, v_21, v_22}:
      cps_provider_2_block_locals(v_22, cps_provider_2_block_locals(v_21, cps_provider_2_atom_locals(v_20, v_3)))
    case BIR.Region{v_29, v_30, v_31}:
      cps_provider_2_block_locals(v_31, cps_provider_2_block_locals(v_30, v_3))
    case BIR.LeaveRegion{v_35}:
      v_3
    case BIR.TailDirect{v_38, v_39}:
      cps_provider_2_args_locals(v_39, v_3)
    case BIR.TailApply{v_43, v_44}:
      cps_provider_2_arg_locals(v_44, cps_provider_2_atom_locals(v_43, v_3))
    case BIR.Failure{v_48}:
      v_3

def cps_provider_2_atom_slots(v_0: BIR.Atom, +v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Capture{v_7}:
      cps_provider_2_u32_add(v_3, v_7)
    case _:
      v_3

def cps_provider_2_arg_slots(v_0: BIR.Arg, v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Arg{v_8, v_9}:
      cps_provider_2_atom_slots(v_9, v_3)

def cps_provider_2_args_slots(v_1: List<&2, BIR.Arg>, +v_4: List<&2, U32>) -> List<&2, U32>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      cps_provider_2_args_slots(v_10, cps_provider_2_arg_slots(v_9, v_4))

def cps_provider_2_field_slots(v_1: List<&2, BIR.Field>, +v_4: List<&2, U32>) -> List<&2, U32>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      match v_9:
        case BIR.Field{v_15, v_16, v_17, v_18}:
          cps_provider_2_field_slots(v_10, cps_provider_2_atom_slots(v_18, v_4))

def cps_provider_2_op_slots(v_0: BIR.Op, +v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Copy{v_7}:
      cps_provider_2_atom_slots(v_7, v_3)
    case BIR.PrimitiveCall{v_12, v_13, v_14}:
      cps_provider_2_args_slots(v_13, v_3)
    case BIR.Closure{v_19, v_20, v_21}:
      cps_provider_2_args_slots(v_20, v_3)
    case BIR.Direct{v_25, v_26}:
      cps_provider_2_args_slots(v_26, v_3)
    case BIR.Apply{v_30, v_31}:
      cps_provider_2_arg_slots(v_31, cps_provider_2_atom_slots(v_30, v_3))
    case BIR.Construct{v_37, v_38, v_39}:
      cps_provider_2_field_slots(v_39, v_3)
    case BIR.Project{v_45, v_46, v_47, v_48}:
      cps_provider_2_atom_slots(v_45, v_3)
    case BIR.HasTag{v_53, v_54, v_55}:
      cps_provider_2_atom_slots(v_53, v_3)
    case _:
      v_3

def cps_provider_2_block_slots(v_0: BIR.Block, +v_3: List<&2, U32>) -> List<&2, U32>:
  match v_0:
    case BIR.Return{v_7}:
      cps_provider_2_atom_slots(v_7, v_3)
    case BIR.Let{v_12, v_13, v_14}:
      cps_provider_2_block_slots(v_14, cps_provider_2_op_slots(v_13, v_3))
    case BIR.Branch{v_20, v_21, v_22}:
      cps_provider_2_block_slots(v_22, cps_provider_2_block_slots(v_21, cps_provider_2_atom_slots(v_20, v_3)))
    case BIR.Region{v_29, v_30, v_31}:
      cps_provider_2_block_slots(v_31, cps_provider_2_block_slots(v_30, v_3))
    case BIR.LeaveRegion{v_35}:
      v_3
    case BIR.TailDirect{v_38, v_39}:
      cps_provider_2_args_slots(v_39, v_3)
    case BIR.TailApply{v_43, v_44}:
      cps_provider_2_arg_slots(v_44, cps_provider_2_atom_slots(v_43, v_3))
    case BIR.Failure{v_48}:
      v_3

def cps_provider_2_env_get(v_2: List<&2, cps_provider_2_Env>, +v_4: U32) -> Maybe<&2, String>:
  match v_2:
    case []:
      None{}
    case +v_9 <> v_10:
      match v_9:
        case cps_provider_2_Env{v_13, v_14}:
          cps_provider_2_env_get_one(U32.is_eq(v_13, v_4), v_14, v_10, v_4)

def cps_provider_2_env_get_one(v_1: Bool, v_3: String, v_6: List<&2, cps_provider_2_Env>, v_8: U32) -> Maybe<&2, String>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_2_env_get(v_6, v_8)

def cps_provider_2_region_refs(v_2: List<&2, cps_provider_2_Region>, +v_5: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      match v_10:
        case cps_provider_2_Region{v_15, v_16, v_17}:
          cps_provider_2_region_refs(v_11, List.append(&2, cps_provider_2_CapRef, v_17, v_5))

def cps_provider_2_refs_have_local(v_2: List<&2, cps_provider_2_CapRef>, +v_4: U32) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_CapLocalRef{v_11}:
          cps_provider_2_refs_local_check(U32.is_eq(v_11, v_4), v_9, v_4)
        case _:
          cps_provider_2_refs_have_local(v_9, v_4)

def cps_provider_2_refs_local_check(v_1: Bool, v_4: List<&2, cps_provider_2_CapRef>, v_6: U32) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_2_refs_have_local(v_4, v_6)

def cps_provider_2_refs_have_slot(v_2: List<&2, cps_provider_2_CapRef>, +v_4: U32) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_CapSlotRef{v_11}:
          cps_provider_2_refs_slot_check(U32.is_eq(v_11, v_4), v_9, v_4)
        case _:
          cps_provider_2_refs_have_slot(v_9, v_4)

def cps_provider_2_refs_slot_check(v_1: Bool, v_4: List<&2, cps_provider_2_CapRef>, v_6: U32) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_2_refs_have_slot(v_4, v_6)

def cps_provider_2_env_refs(v_2: List<&2, cps_provider_2_Env>, +v_5: List<&2, U32>, +v_8: List<&2, cps_provider_2_CapRef>, +v_11: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  match v_2:
    case []:
      List.reverse(&2, cps_provider_2_CapRef, v_11)
    case +v_17 <> v_18:
      match v_17:
        case cps_provider_2_Env{+v_21, v_22}:
          cps_provider_2_env_refs(v_18, v_5, v_8, cps_provider_2_env_ref_add(cps_provider_2_u32_member(v_5, v_21), cps_provider_2_refs_have_local(v_8, v_21), v_21, v_11))

def native_match_cps_provider_2_env_ref_add_0(v_9: Bool, v_5: U32, +v_8: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  match v_9:
    case True{}:
      cps_provider_2_CapLocalRef{v_5} <> v_8
    case False{}:
      v_8

def cps_provider_2_env_ref_add(v_1: Bool, v_3: Bool, v_5: U32, +v_8: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  native_match_cps_provider_2_env_ref_add_0(Bool.or(v_1, v_3), v_5, v_8)

def native_match_cps_provider_2_slot_refs_0(v_17: Bool, +v_1: Nat, +v_3: Nat, +v_6: List<&2, U32>, +v_9: List<&2, cps_provider_2_CapRef>, +v_12: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  match v_17:
    case False{}:
      v_12
    case True{}:
      +v_16 = U32.from_nat(v_1)
      cps_provider_2_slot_refs(Nat.add(v_1, 1n), v_3, v_6, v_9, cps_provider_2_slot_ref_add(cps_provider_2_u32_member(v_6, v_16), cps_provider_2_refs_have_slot(v_9, v_16), v_16, v_12))

def cps_provider_2_slot_refs(+v_1: Nat, +v_3: Nat, +v_6: List<&2, U32>, +v_9: List<&2, cps_provider_2_CapRef>, +v_12: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  native_match_cps_provider_2_slot_refs_0(Nat.is_lt(v_1, v_3), v_1, v_3, v_6, v_9, v_12)

def native_match_cps_provider_2_slot_ref_add_0(v_9: Bool, v_5: U32, +v_8: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  match v_9:
    case True{}:
      cps_provider_2_CapSlotRef{v_5} <> v_8
    case False{}:
      v_8

def cps_provider_2_slot_ref_add(v_1: Bool, v_3: Bool, v_5: U32, +v_8: List<&2, cps_provider_2_CapRef>) -> List<&2, cps_provider_2_CapRef>:
  native_match_cps_provider_2_slot_ref_add_0(Bool.or(v_1, v_3), v_5, v_8)

def cps_provider_2_needed_refs(+v_0: BIR.Block, +v_2: cps_provider_2_Ctx) -> List<&2, cps_provider_2_CapRef>:
  v_7 = cps_provider_2_block_locals(v_0, [])
  v_10 = cps_provider_2_block_slots(v_0, [])
  +v_14 = cps_provider_2_region_refs(cps_provider_2_ctx_regions(v_2), [])
  v_18 = cps_provider_2_env_refs(cps_provider_2_ctx_env(v_2), v_7, v_14, [])
  v_22 = cps_provider_2_slot_refs(0n, cps_provider_2_ctx_caps_n(v_2), v_10, v_14, [])
  List.append(&2, cps_provider_2_CapRef, v_18, List.reverse(&2, cps_provider_2_CapRef, v_22))

def native_match_cps_provider_2_refs_caps_0(v_22: Maybe<&2, cps_provider_2_Cap>, v_23: Maybe<&2, List<&2, cps_provider_2_Cap>>) -> Maybe<&2, List<&2, cps_provider_2_Cap>>:
  match v_22, v_23:
    case Some{v_16}, Some{v_17}:
      Some{v_16 <> v_17}
    case _, _:
      None{}

def native_match_cps_provider_2_refs_caps_1(v_2: List<&2, cps_provider_2_CapRef>, +v_4: cps_provider_2_Ctx) -> Maybe<&2, List<&2, cps_provider_2_Cap>>:
  match v_2:
    case []:
      Some{[]}
    case +v_10 <> v_11:
      native_match_cps_provider_2_refs_caps_0(cps_provider_2_cap_of_ref(v_10, v_4), cps_provider_2_refs_caps(v_11, v_4))

def cps_provider_2_refs_caps(v_2: List<&2, cps_provider_2_CapRef>, +v_4: cps_provider_2_Ctx) -> Maybe<&2, List<&2, cps_provider_2_Cap>>:
  native_match_cps_provider_2_refs_caps_1(v_2, v_4)

def native_match_cps_provider_2_cap_of_ref_0(v_14: Maybe<&2, String>, +v_7: U32) -> Maybe<&2, cps_provider_2_Cap>:
  match v_14:
    case Some{v_11}:
      Some{cps_provider_2_CapLocal{v_7, v_11}}
    case None{}:
      None{}

def native_match_cps_provider_2_cap_of_ref_1(v_15: Bool, +v_3: cps_provider_2_Ctx, +v_13: U32) -> Maybe<&2, cps_provider_2_Cap>:
  match v_15:
    case False{}:
      None{}
    case True{}:
      Some{cps_provider_2_CapSlot{v_13, cps_provider_2_list_at(cps_provider_2_ctx_caps(v_3), U32.to_nat(v_13))}}

def native_match_cps_provider_2_cap_of_ref_2(v_1: cps_provider_2_CapRef, +v_3: cps_provider_2_Ctx) -> Maybe<&2, cps_provider_2_Cap>:
  match v_1:
    case cps_provider_2_CapLocalRef{+v_7}:
      native_match_cps_provider_2_cap_of_ref_0(cps_provider_2_env_get(cps_provider_2_ctx_env(v_3), v_7), v_7)
    case cps_provider_2_CapSlotRef{+v_13}:
      native_match_cps_provider_2_cap_of_ref_1(Nat.is_lt(U32.to_nat(v_13), cps_provider_2_ctx_caps_n(v_3)), v_3, v_13)

def cps_provider_2_cap_of_ref(v_1: cps_provider_2_CapRef, +v_3: cps_provider_2_Ctx) -> Maybe<&2, cps_provider_2_Cap>:
  native_match_cps_provider_2_cap_of_ref_2(v_1, v_3)

def cps_provider_2_capture_for(v_0: BIR.Block, +v_2: cps_provider_2_Ctx) -> Maybe<&2, List<&2, cps_provider_2_Cap>>:
  cps_provider_2_refs_caps(cps_provider_2_needed_refs(v_0, v_2), v_2)

def cps_provider_2_ctx_sig(v_1: cps_provider_2_Ctx) -> cps_provider_2_Sig:
  match v_1:
    case cps_provider_2_Ctx{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26}:
      v_15

def cps_provider_2_ctx_plan(v_1: cps_provider_2_Ctx) -> cps_provider_2_Plan:
  match v_1:
    case cps_provider_2_Ctx{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26}:
      v_16

def cps_provider_2_ctx_env(v_1: cps_provider_2_Ctx) -> List<&2, cps_provider_2_Env>:
  match v_1:
    case cps_provider_2_Ctx{v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27}:
      v_18

def cps_provider_2_ctx_caps(v_1: cps_provider_2_Ctx) -> List<&2, String>:
  match v_1:
    case cps_provider_2_Ctx{v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27}:
      v_19

def cps_provider_2_ctx_caps_n(v_1: cps_provider_2_Ctx) -> Nat:
  match v_1:
    case cps_provider_2_Ctx{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26}:
      v_19

def cps_provider_2_ctx_regions(v_1: cps_provider_2_Ctx) -> List<&2, cps_provider_2_Region>:
  match v_1:
    case cps_provider_2_Ctx{v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27}:
      v_21

def cps_provider_2_ctx_self(v_1: cps_provider_2_Ctx) -> Maybe<&2, U32>:
  match v_1:
    case cps_provider_2_Ctx{v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27}:
      v_22

def cps_provider_2_ctx_next(v_1: cps_provider_2_Ctx) -> U32:
  match v_1:
    case cps_provider_2_Ctx{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26}:
      v_22

def cps_provider_2_ctx_segs(v_1: cps_provider_2_Ctx) -> List<&2, cps_provider_2_SegText>:
  match v_1:
    case cps_provider_2_Ctx{v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27}:
      v_24

def cps_provider_2_ctx_outs(v_1: cps_provider_2_Ctx) -> List<&2, String>:
  match v_1:
    case cps_provider_2_Ctx{v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26, v_27}:
      v_25

def cps_provider_2_ctx_spin(v_1: cps_provider_2_Ctx) -> Bool:
  match v_1:
    case cps_provider_2_Ctx{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26}:
      v_25

def cps_provider_2_ctx_max(v_1: cps_provider_2_Ctx) -> Nat:
  match v_1:
    case cps_provider_2_Ctx{v_15, v_16, v_17, v_18, v_19, v_20, v_21, v_22, v_23, v_24, v_25, v_26}:
      v_26

def cps_provider_2_sig_entries(v_1: cps_provider_2_Sig) -> List<&2, cps_provider_2_Entry>:
  match v_1:
    case cps_provider_2_Sig{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      v_13

def cps_provider_2_sig_by_code(v_1: cps_provider_2_Sig) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Sig{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      v_14

def cps_provider_2_sig_by_key(v_1: cps_provider_2_Sig) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Sig{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      v_15

def cps_provider_2_sig_by_foreign(v_1: cps_provider_2_Sig) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Sig{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      v_16

def cps_provider_2_sig_by_native(v_1: cps_provider_2_Sig) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Sig{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      v_17

def cps_provider_2_sig_stages(v_1: cps_provider_2_Sig) -> Map<&2, U32>:
  match v_1:
    case cps_provider_2_Sig{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      v_18

def cps_provider_2_sig_decls(v_1: cps_provider_2_Sig) -> List<&2, BIR.Declaration>:
  match v_1:
    case cps_provider_2_Sig{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20}:
      v_18

def cps_provider_2_sig_cids(v_1: cps_provider_2_Sig) -> List<&2, cps_provider_2_CidRow>:
  match v_1:
    case cps_provider_2_Sig{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      v_20

def cps_provider_2_sig_apply(v_1: cps_provider_2_Sig) -> U32:
  match v_1:
    case cps_provider_2_Sig{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20}:
      v_20

def cps_provider_2_a_name(v_1: Nat) -> String:
  String.append("a", Nat.show(v_1))

def cps_provider_2_r_name(v_1: Nat) -> String:
  String.append("r", Nat.show(v_1))

def cps_provider_2_lv_name(v_1: U32) -> String:
  String.append("lv", U32.show(v_1))

def cps_provider_2_a_decls(v_1: Nat) -> String:
  cps_provider_2_a_decls_at(0n, v_1)

def native_match_cps_provider_2_a_decls_at_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> String:
  match v_4:
    case True{}:
      String.concat(["    Term ", cps_provider_2_a_name(v_1), " = ", cps_provider_2_r_name(v_1), ";\n", cps_provider_2_a_decls_at(Nat.add(v_1, 1n), v_3)])
    case False{}:
      ""

def cps_provider_2_a_decls_at(+v_1: Nat, +v_3: Nat) -> String:
  native_match_cps_provider_2_a_decls_at_0(Nat.is_lt(v_1, v_3), v_1, v_3)

def native_match_cps_provider_2_x_decl_0(v_2: Bool, +v_1: Nat) -> String:
  match v_2:
    case True{}:
      ""
    case False{}:
      String.concat(["    Term x[", Nat.show(v_1), "];\n"])

def cps_provider_2_x_decl(+v_1: Nat) -> String:
  native_match_cps_provider_2_x_decl_0(Nat.is_eq(v_1, 0n), v_1)

def cps_provider_2_x_fill_a(v_1: Nat) -> String:
  cps_provider_2_x_fill_a_at(0n, v_1)

def native_match_cps_provider_2_x_fill_a_at_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> String:
  match v_4:
    case True{}:
      String.concat(["    x[", Nat.show(v_1), "] = a", Nat.show(v_1), ";\n", cps_provider_2_x_fill_a_at(Nat.add(v_1, 1n), v_3)])
    case False{}:
      ""

def cps_provider_2_x_fill_a_at(+v_1: Nat, +v_3: Nat) -> String:
  native_match_cps_provider_2_x_fill_a_at_0(Nat.is_lt(v_1, v_3), v_1, v_3)

def cps_provider_2_params_bind(v_1: List<&2, BIR.Parameter>, +v_3: Nat, +v_5: Nat) -> String:
  match v_1:
    case []:
      ""
    case +v_9 <> v_10:
      match v_9:
        case BIR.Parameter{v_13, v_14}:
          String.concat(["    Term ", cps_provider_2_lv_name(v_13), " = ", cps_provider_2_a_name(Nat.add(v_3, v_5)), ";\n", cps_provider_2_params_bind(v_10, v_3, Nat.add(v_5, 1n))])

def cps_provider_2_params_env(v_1: List<&2, BIR.Parameter>, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_2_Env>) -> List<&2, cps_provider_2_Env>:
  match v_1:
    case []:
      List.reverse(&2, cps_provider_2_Env, v_8)
    case +v_14 <> v_15:
      match v_14:
        case BIR.Parameter{v_18, v_19}:
          cps_provider_2_params_env(v_15, v_3, Nat.add(v_5, 1n), cps_provider_2_Env{v_18, String.concat(["a", Nat.show(Nat.add(v_3, v_5))])} <> v_8)

def cps_provider_2_a_caps(v_1: Nat) -> List<&2, String>:
  cps_provider_2_a_caps_at(0n, v_1)

def native_match_cps_provider_2_a_caps_at_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> List<&2, String>:
  match v_4:
    case True{}:
      cps_provider_2_a_name(v_1) <> cps_provider_2_a_caps_at(Nat.add(v_1, 1n), v_3)
    case False{}:
      []

def cps_provider_2_a_caps_at(+v_1: Nat, +v_3: Nat) -> List<&2, String>:
  native_match_cps_provider_2_a_caps_at_0(Nat.is_lt(v_1, v_3), v_1, v_3)

def cps_provider_2_caps_assign(v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat) -> String:
  match v_2:
    case []:
      ""
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_CapLocal{v_12, v_13}:
          String.concat(["    ", cps_provider_2_r_name(v_4), " = ", v_13, ";\n", cps_provider_2_caps_assign(v_9, Nat.add(v_4, 1n))])
        case cps_provider_2_CapSlot{v_18, v_19}:
          String.concat(["    ", cps_provider_2_r_name(v_4), " = ", v_19, ";\n", cps_provider_2_caps_assign(v_9, Nat.add(v_4, 1n))])

def cps_provider_2_regs_assign(v_2: List<&2, String>, +v_4: Nat) -> String:
  match v_2:
    case []:
      ""
    case +v_8 <> v_9:
      String.concat(["    ", cps_provider_2_r_name(v_4), " = ", v_8, ";\n", cps_provider_2_regs_assign(v_9, Nat.add(v_4, 1n))])

def cps_provider_2_k_decls(v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat) -> String:
  match v_2:
    case []:
      ""
    case +v_8 <> v_9:
      String.concat(["    Term k", Nat.show(v_4), " = STK(", Nat.show(v_4), ");\n", cps_provider_2_k_decls(v_9, Nat.add(v_4, 1n))])

def cps_provider_2_cap_intro(v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: String, +v_8: String) -> String:
  match v_2:
    case []:
      String.concat([v_6, v_8])
    case +v_12 <> v_13:
      match v_12:
        case cps_provider_2_CapLocal{v_16, v_17}:
          cps_provider_2_cap_intro(v_13, Nat.add(v_4, 1n), String.concat([v_6, "    Term ", cps_provider_2_lv_name(v_16), " = k", Nat.show(v_4), ";\n"]), v_8)
        case cps_provider_2_CapSlot{v_22, v_23}:
          cps_provider_2_cap_intro(v_13, Nat.add(v_4, 1n), v_6, String.concat([v_8, "    x[", U32.show(v_22), "] = k", Nat.show(v_4), ";\n"]))

def cps_provider_2_cap_intro_a(v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: String, +v_8: String) -> String:
  match v_2:
    case []:
      String.concat([v_6, v_8])
    case +v_12 <> v_13:
      match v_12:
        case cps_provider_2_CapLocal{v_16, v_17}:
          cps_provider_2_cap_intro_a(v_13, Nat.add(v_4, 1n), String.concat([v_6, "    Term ", cps_provider_2_lv_name(v_16), " = a", Nat.show(v_4), ";\n"]), v_8)
        case cps_provider_2_CapSlot{v_22, v_23}:
          cps_provider_2_cap_intro_a(v_13, Nat.add(v_4, 1n), v_6, String.concat([v_8, "    x[", U32.show(v_22), "] = a", Nat.show(v_4), ";\n"]))

def cps_provider_2_cap_locals_env(v_2: List<&2, cps_provider_2_Cap>, +v_5: List<&2, cps_provider_2_Env>) -> List<&2, cps_provider_2_Env>:
  match v_2:
    case []:
      List.reverse(&2, cps_provider_2_Env, v_5)
    case +v_11 <> v_12:
      match v_11:
        case cps_provider_2_CapLocal{+v_15, v_16}:
          cps_provider_2_cap_locals_env(v_12, cps_provider_2_Env{v_15, cps_provider_2_lv_name(v_15)} <> v_5)
        case cps_provider_2_CapSlot{v_21, v_22}:
          cps_provider_2_cap_locals_env(v_12, v_5)

def cps_provider_2_caps_lookup(v_2: List<&2, cps_provider_2_Cap>, +v_4: U32) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_CapSlot{v_12, v_13}:
          cps_provider_2_caps_lookup_one(U32.is_eq(v_12, v_4), v_9, v_4)
        case _:
          cps_provider_2_caps_lookup(v_9, v_4)

def cps_provider_2_caps_lookup_one(v_1: Bool, v_4: List<&2, cps_provider_2_Cap>, v_6: U32) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_2_caps_lookup(v_4, v_6)

def native_match_cps_provider_2_cap_slots_exprs_0(v_19: Bool, +v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: Nat, +v_9: List<&2, String>) -> List<&2, String>:
  match v_19:
    case False{}:
      List.reverse(&2, String, v_9)
    case True{}:
      +v_14 = U32.from_nat(v_6)
      v_18 = cps_provider_2_cap_slot_value(cps_provider_2_caps_lookup(v_2, v_14), v_14)
      cps_provider_2_cap_slots_exprs(v_2, v_4, Nat.add(v_6, 1n), v_18 <> v_9)

def cps_provider_2_cap_slots_exprs(+v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: Nat, +v_9: List<&2, String>) -> List<&2, String>:
  native_match_cps_provider_2_cap_slots_exprs_0(Nat.is_lt(v_6, v_4), v_2, v_4, v_6, v_9)

def cps_provider_2_cap_slot_value(v_1: Bool, v_3: U32) -> String:
  match v_1:
    case True{}:
      String.concat(["x[", U32.show(v_3), "]"])
    case False{}:
      "0"

def cps_provider_2_cont_prologue(+v_2: List<&2, cps_provider_2_Cap>, v_4: Nat, v_6: U32) -> String:
  String.concat(["    WL_POPN(", Nat.show(List.length(&2, cps_provider_2_Cap, v_2)), ");\n", cps_provider_2_x_decl(v_4), cps_provider_2_cap_stk_intro(v_2, 0n, "", ""), "    Term ", cps_provider_2_lv_name(v_6), " = r0;\n"])

def cps_provider_2_cap_stk_intro(+v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: String, +v_8: String) -> String:
  match v_2:
    case []:
      String.concat([v_6, v_8])
    case +v_12 <> v_13:
      match v_12:
        case cps_provider_2_CapLocal{v_16, v_17}:
          cps_provider_2_cap_stk_intro(v_13, Nat.add(v_4, 1n), String.concat([v_6, "    Term ", cps_provider_2_lv_name(v_16), " = STK(", Nat.show(v_4), ");\n"]), v_8)
        case cps_provider_2_CapSlot{v_22, v_23}:
          cps_provider_2_cap_stk_intro(v_13, Nat.add(v_4, 1n), v_6, String.concat([v_8, "    x[", U32.show(v_22), "] = STK(", Nat.show(v_4), ");\n"]))

def cps_provider_2_region_prologue(+v_2: List<&2, cps_provider_2_Cap>, v_4: Nat) -> String:
  String.concat([cps_provider_2_a_decls(List.length(&2, cps_provider_2_Cap, v_2)), cps_provider_2_x_decl(v_4), cps_provider_2_cap_intro_a(v_2, 0n, "", "")])

def cps_provider_2_a_rebinds(v_1: Nat) -> String:
  cps_provider_2_a_rebinds_at(0n, v_1)

def native_match_cps_provider_2_a_rebinds_at_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> String:
  match v_4:
    case True{}:
      String.concat(["    ", cps_provider_2_a_name(v_1), " = ", cps_provider_2_r_name(v_1), ";\n", cps_provider_2_a_rebinds_at(Nat.add(v_1, 1n), v_3)])
    case False{}:
      ""

def cps_provider_2_a_rebinds_at(+v_1: Nat, +v_3: Nat) -> String:
  native_match_cps_provider_2_a_rebinds_at_0(Nat.is_lt(v_1, v_3), v_1, v_3)

def native_match_cps_provider_2_fid_name_0(v_8: Bool, +v_1: U32) -> String:
  match v_8:
    case True{}:
      "FID_ENTER"
    case False{}:
      String.concat(["FID_", U32.show(v_1)])

def native_match_cps_provider_2_fid_name_1(v_7: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  match v_7:
    case True{}:
      "FID_EXIT"
    case False{}:
      native_match_cps_provider_2_fid_name_0(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 5n)), v_1)

def native_match_cps_provider_2_fid_name_2(v_6: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  match v_6:
    case True{}:
      "FID_CLO_APPLY"
    case False{}:
      native_match_cps_provider_2_fid_name_1(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 4n)), v_1, v_4)

def native_match_cps_provider_2_fid_name_3(v_5: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  match v_5:
    case True{}:
      "FID_IO_EMIT"
    case False{}:
      native_match_cps_provider_2_fid_name_2(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 3n)), v_1, v_4)

def cps_provider_2_fid_name(+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  native_match_cps_provider_2_fid_name_3(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 2n)), v_1, v_4)

def cps_provider_2_case_text(+v_1: U32, +v_3: String, +v_5: String, +v_7: Bool) -> String:
  String.concat(["  WL_CASE(FID_", U32.show(v_1), ")\n  {\n", v_3, "    WL_OPEN\n", cps_provider_2_spin_open(v_7), v_5, cps_provider_2_spin_close(v_7), "  }}\n\n"])

def cps_provider_2_spin_open(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "    WL_SPIN\n"
    case False{}:
      ""

def cps_provider_2_spin_close(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "    WL_SPUN\n"
    case False{}:
      ""

def cps_provider_2_block_ctl(v_0: BIR.Block, +v_2: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_0:
    case BIR.Return{v_5}:
      cps_provider_2_return_ctl(v_5, v_2)
    case BIR.Let{v_10, v_11, v_12}:
      cps_provider_2_let_ctl(v_10, v_11, v_12, v_2)
    case BIR.Branch{v_17, v_18, v_19}:
      cps_provider_2_branch_ctl(v_17, v_18, v_19, v_2)
    case BIR.Region{v_24, v_25, v_26}:
      cps_provider_2_region_ctl(v_24, v_25, v_26, v_2)
    case BIR.LeaveRegion{v_29}:
      cps_provider_2_leave_ctl(v_29, v_2)
    case BIR.TailDirect{v_33, v_34}:
      cps_provider_2_tail_direct_ctl(v_33, v_34, v_2)
    case BIR.TailApply{v_38, v_39}:
      cps_provider_2_tail_apply_ctl(v_38, v_39, v_2)
    case BIR.Failure{v_42}:
      cps_provider_2_failure_ctl(v_2)
    case _:
      cps_provider_2_StepFail{"BIR block form has no C rendering"}

def native_match_cps_provider_2_return_ctl_0(v_10: cps_provider_2_Part, +v_2: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_10:
    case cps_provider_2_PartFail{v_7}:
      cps_provider_2_StepFail{v_7}
    case cps_provider_2_PartOk{v_9}:
      cps_provider_2_StepOk{String.concat(["    r0 = ", v_9, ";\n    WL_RETN(1);\n"]), v_2}

def cps_provider_2_return_ctl(v_0: BIR.Atom, +v_2: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_return_ctl_0(cps_provider_2_atom_part(v_0, cps_provider_2_ctx_plan(v_2)), v_2)

def cps_provider_2_failure_ctl(v_1: cps_provider_2_Ctx) -> cps_provider_2_Step:
  cps_provider_2_StepOk{"    err_post(e.mem, ERR_TAGS);\n    return 0;\n", v_1}

def cps_provider_2_let_ctl(+v_1: U32, +v_2: BIR.Op, +v_3: BIR.Block, +v_5: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_2:
    case BIR.Direct{v_9, v_10}:
      cps_provider_2_direct_ctl(v_1, v_9, v_10, v_3, v_5)
    case BIR.Apply{v_14, v_15}:
      cps_provider_2_apply_ctl(v_1, v_14, v_15, v_3, v_5)
    case BIR.LoadSymbol{v_19, v_20}:
      cps_provider_2_load_symbol_ctl(v_1, v_20, v_3, v_5)
    case BIR.Closure{v_25, v_26, v_27}:
      cps_provider_2_closure_ctl(v_1, v_25, v_26, v_27, v_3, v_5)
    case _:
      cps_provider_2_pure_let(v_1, v_2, v_3, v_5)

def native_match_cps_provider_2_pure_let_0(v_34: cps_provider_2_Step, +v_1: U32, v_12: String) -> cps_provider_2_Step:
  match v_34:
    case cps_provider_2_StepFail{v_28}:
      cps_provider_2_StepFail{v_28}
    case cps_provider_2_StepOk{v_31, v_32}:
      cps_provider_2_StepOk{String.concat(["    Term ", cps_provider_2_lv_name(v_1), " = ", v_12, ";\n", v_31]), v_32}

def native_match_cps_provider_2_pure_let_1(v_33: cps_provider_2_Part, +v_1: U32, v_3: BIR.Block, +v_5: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_33:
    case cps_provider_2_PartFail{v_10}:
      cps_provider_2_StepFail{v_10}
    case cps_provider_2_PartOk{v_12}:
      native_match_cps_provider_2_pure_let_0(cps_provider_2_block_ctl(v_3, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_5), cps_provider_2_ctx_plan(v_5), cps_provider_2_Env{v_1, cps_provider_2_lv_name(v_1)} <> cps_provider_2_ctx_env(v_5), cps_provider_2_ctx_caps(v_5), cps_provider_2_ctx_caps_n(v_5), cps_provider_2_ctx_regions(v_5), cps_provider_2_ctx_self(v_5), cps_provider_2_ctx_next(v_5), cps_provider_2_ctx_segs(v_5), cps_provider_2_ctx_outs(v_5), cps_provider_2_ctx_spin(v_5), cps_provider_2_ctx_max(v_5)}), v_1, v_12)

def cps_provider_2_pure_let(+v_1: U32, v_2: BIR.Op, v_3: BIR.Block, +v_5: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_pure_let_1(cps_provider_2_op_part(v_2, cps_provider_2_ctx_plan(v_5)), v_1, v_3, v_5)

def cps_provider_2_cond_part_of(v_1: cps_provider_2_Part, v_3: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_PartFail{v_6}:
      cps_provider_2_PartFail{v_6}
    case cps_provider_2_PartOk{v_8}:
      cps_provider_2_cond_part(v_8, cps_provider_2_pcid("True", v_3))

def cps_provider_2_cond_part(v_1: String, v_3: cps_provider_2_Part) -> cps_provider_2_Part:
  match v_3:
    case cps_provider_2_PartFail{v_6}:
      cps_provider_2_PartFail{v_6}
    case cps_provider_2_PartOk{v_8}:
      cps_provider_2_okp(cps_provider_2_cat(["term_aux(", v_1, ") == (u64)", v_8]))

def native_match_cps_provider_2_branch_ctl_0(v_35: cps_provider_2_Step, v_17: String, v_23: String) -> cps_provider_2_Step:
  match v_35:
    case cps_provider_2_StepFail{v_27}:
      cps_provider_2_StepFail{v_27}
    case cps_provider_2_StepOk{v_30, v_31}:
      cps_provider_2_StepOk{String.concat(["    if (", v_17, ") {\n", v_23, "    } else {\n", v_30, "    }\n"]), v_31}

def native_match_cps_provider_2_branch_ctl_1(v_34: cps_provider_2_Step, v_2: BIR.Block, v_17: String) -> cps_provider_2_Step:
  match v_34:
    case cps_provider_2_StepFail{v_20}:
      cps_provider_2_StepFail{v_20}
    case cps_provider_2_StepOk{v_23, v_24}:
      native_match_cps_provider_2_branch_ctl_0(cps_provider_2_block_ctl(v_2, v_24), v_17, v_23)

def native_match_cps_provider_2_branch_ctl_2(v_33: cps_provider_2_Part, v_1: BIR.Block, v_2: BIR.Block, +v_4: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_33:
    case cps_provider_2_PartFail{v_15}:
      cps_provider_2_StepFail{v_15}
    case cps_provider_2_PartOk{v_17}:
      native_match_cps_provider_2_branch_ctl_1(cps_provider_2_block_ctl(v_1, v_4), v_2, v_17)

def native_match_cps_provider_2_branch_ctl_3(v_32: cps_provider_2_Part, v_1: BIR.Block, v_2: BIR.Block, +v_4: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_32:
    case cps_provider_2_PartFail{v_9}:
      cps_provider_2_StepFail{v_9}
    case cps_provider_2_PartOk{v_11}:
      native_match_cps_provider_2_branch_ctl_2(cps_provider_2_cond_part_of(cps_provider_2_PartOk{v_11}, cps_provider_2_ctx_plan(v_4)), v_1, v_2, v_4)

def cps_provider_2_branch_ctl(v_0: BIR.Atom, v_1: BIR.Block, v_2: BIR.Block, +v_4: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_branch_ctl_3(cps_provider_2_atom_part(v_0, cps_provider_2_ctx_plan(v_4)), v_1, v_2, v_4)

def native_match_cps_provider_2_region_ctl_0(v_10: Maybe<&2, List<&2, cps_provider_2_Cap>>, v_1: U32, v_2: BIR.Block, +v_3: BIR.Block, +v_5: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_10:
    case None{}:
      cps_provider_2_StepFail{"BIR region reads a value that is not in scope"}
    case Some{v_9}:
      cps_provider_2_region_next(v_1, v_2, v_3, v_5, v_9, cps_provider_2_ctx_next(v_5), cps_provider_2_needed_refs(v_3, v_5))

def cps_provider_2_region_ctl(v_1: U32, v_2: BIR.Block, +v_3: BIR.Block, +v_5: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_region_ctl_0(cps_provider_2_capture_for(v_3, v_5), v_1, v_2, v_3, v_5)

def native_match_cps_provider_2_region_next_0(v_34: cps_provider_2_Step, +v_1: U32, v_2: BIR.Block, +v_5: cps_provider_2_Ctx, +v_8: List<&2, cps_provider_2_Cap>, +v_10: U32, +v_13: List<&2, cps_provider_2_CapRef>) -> cps_provider_2_Step:
  match v_34:
    case cps_provider_2_StepFail{v_29}:
      cps_provider_2_StepFail{v_29}
    case cps_provider_2_StepOk{v_32, v_33}:
      cps_provider_2_region_body(v_1, v_2, v_5, v_8, v_10, v_13, v_32, v_33)

def cps_provider_2_region_next(+v_1: U32, v_2: BIR.Block, v_3: BIR.Block, +v_5: cps_provider_2_Ctx, +v_8: List<&2, cps_provider_2_Cap>, +v_10: U32, +v_13: List<&2, cps_provider_2_CapRef>) -> cps_provider_2_Step:
  native_match_cps_provider_2_region_next_0(cps_provider_2_block_ctl(v_3, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_5), cps_provider_2_ctx_plan(v_5), cps_provider_2_cap_locals_env(v_8, []), cps_provider_2_cap_slots_exprs(v_8, cps_provider_2_ctx_caps_n(v_5), 0n, []), cps_provider_2_ctx_caps_n(v_5), cps_provider_2_Region{v_1, v_10, v_13} <> cps_provider_2_ctx_regions(v_5), None{}, U32.inc(v_10), cps_provider_2_ctx_segs(v_5), cps_provider_2_ctx_outs(v_5), False{}, cps_provider_2_nat_max(cps_provider_2_ctx_max(v_5), List.length(&2, cps_provider_2_Cap, v_8))}), v_1, v_2, v_5, v_8, v_10, v_13)

def native_match_cps_provider_2_region_body_0(v_41: cps_provider_2_Step, +v_4: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_41:
    case cps_provider_2_StepFail{v_36}:
      cps_provider_2_StepFail{v_36}
    case cps_provider_2_StepOk{v_39, +v_40}:
      cps_provider_2_StepOk{v_39, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_40), cps_provider_2_ctx_plan(v_40), cps_provider_2_ctx_env(v_40), cps_provider_2_ctx_caps(v_40), cps_provider_2_ctx_caps_n(v_40), cps_provider_2_ctx_regions(v_4), cps_provider_2_ctx_self(v_4), cps_provider_2_ctx_next(v_40), cps_provider_2_ctx_segs(v_40), cps_provider_2_ctx_outs(v_40), cps_provider_2_ctx_spin(v_40), cps_provider_2_ctx_max(v_40)}}

def cps_provider_2_region_body(v_1: U32, v_2: BIR.Block, +v_4: cps_provider_2_Ctx, +v_7: List<&2, cps_provider_2_Cap>, +v_9: U32, v_12: List<&2, cps_provider_2_CapRef>, v_14: String, +v_16: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_region_body_0(cps_provider_2_block_ctl(v_2, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_4), cps_provider_2_ctx_plan(v_4), cps_provider_2_ctx_env(v_4), cps_provider_2_ctx_caps(v_4), cps_provider_2_ctx_caps_n(v_4), cps_provider_2_Region{v_1, v_9, v_12} <> cps_provider_2_ctx_regions(v_4), cps_provider_2_ctx_self(v_4), cps_provider_2_ctx_next(v_16), cps_provider_2_SegText{v_9, List.length(&2, cps_provider_2_Cap, v_7), 0n, cps_provider_2_case_text(v_9, cps_provider_2_region_prologue(v_7, cps_provider_2_ctx_caps_n(v_4)), v_14, False{})} <> cps_provider_2_ctx_segs(v_16), cps_provider_2_ctx_outs(v_16), cps_provider_2_ctx_spin(v_4), cps_provider_2_ctx_max(v_16)}), v_4)

def cps_provider_2_find_region(v_2: List<&2, cps_provider_2_Region>, +v_4: U32) -> Maybe<&2, cps_provider_2_Region>:
  match v_2:
    case []:
      None{}
    case +v_9 <> v_10:
      match v_9:
        case cps_provider_2_Region{v_14, v_15, v_16}:
          cps_provider_2_find_region_one(U32.is_eq(v_14, v_4), v_9, v_10, v_4)

def cps_provider_2_find_region_one(v_1: Bool, v_3: cps_provider_2_Region, v_6: List<&2, cps_provider_2_Region>, v_8: U32) -> Maybe<&2, cps_provider_2_Region>:
  match v_1:
    case True{}:
      Some{v_3}
    case False{}:
      cps_provider_2_find_region(v_6, v_8)

def native_match_cps_provider_2_leave_ctl_0(v_19: Maybe<&2, List<&2, cps_provider_2_Cap>>, +v_3: cps_provider_2_Ctx, v_13: U32) -> cps_provider_2_Step:
  match v_19:
    case None{}:
      cps_provider_2_StepFail{"BIR LeaveRegion reads a value that is not in scope"}
    case Some{v_17}:
      cps_provider_2_StepOk{String.concat([cps_provider_2_caps_assign(v_17, 0n), "    WL_JMP(", cps_provider_2_fid_name(v_13, cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_3))), ");\n"]), v_3}

def native_match_cps_provider_2_leave_ctl_1(v_8: cps_provider_2_Region, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_8:
    case cps_provider_2_Region{v_12, v_13, v_14}:
      native_match_cps_provider_2_leave_ctl_0(cps_provider_2_refs_caps(v_14, v_3), v_3, v_13)

def native_match_cps_provider_2_leave_ctl_2(v_18: Maybe<&2, cps_provider_2_Region>, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_18:
    case None{}:
      cps_provider_2_StepFail{"BIR LeaveRegion names no enclosing region"}
    case Some{v_8}:
      native_match_cps_provider_2_leave_ctl_1(v_8, v_3)

def cps_provider_2_leave_ctl(v_1: U32, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_leave_ctl_2(cps_provider_2_find_region(cps_provider_2_ctx_regions(v_3), v_1), v_3)

def native_match_cps_provider_2_tail_direct_ctl_0(v_27: Bool, +v_5: cps_provider_2_Ctx, +v_11: U32, +v_15: List<&2, String>) -> cps_provider_2_Step:
  match v_27:
    case True{}:
      cps_provider_2_self_tail(v_11, v_15, v_5)
    case False{}:
      cps_provider_2_StepOk{String.concat([cps_provider_2_regs_assign(v_15, 0n), "    WL_JMP(", cps_provider_2_fid_name(v_11, cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_5))), ");\n"]), v_5}

def native_match_cps_provider_2_tail_direct_ctl_1(v_26: Maybe<&2, U32>, +v_5: cps_provider_2_Ctx, +v_11: U32, +v_15: List<&2, String>) -> cps_provider_2_Step:
  match v_26:
    case Some{v_22}:
      native_match_cps_provider_2_tail_direct_ctl_0(U32.is_eq(v_22, v_11), v_5, v_11, v_15)
    case None{}:
      cps_provider_2_StepOk{String.concat([cps_provider_2_regs_assign(v_15, 0n), "    WL_JMP(", cps_provider_2_fid_name(v_11, cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_5))), ");\n"]), v_5}

def native_match_cps_provider_2_tail_direct_ctl_2(v_25: Bool, +v_5: cps_provider_2_Ctx, +v_11: U32, +v_15: List<&2, String>) -> cps_provider_2_Step:
  match v_25:
    case False{}:
      cps_provider_2_StepFail{"BIR tail call arity disagrees with its entry"}
    case True{}:
      native_match_cps_provider_2_tail_direct_ctl_1(cps_provider_2_ctx_self(v_5), v_5, v_11, v_15)

def native_match_cps_provider_2_tail_direct_ctl_3(v_24: Maybe<&2, List<&2, String>>, +v_5: cps_provider_2_Ctx, +v_11: U32) -> cps_provider_2_Step:
  match v_24:
    case None{}:
      cps_provider_2_StepFail{"BIR tail argument has no C value"}
    case Some{+v_15}:
      native_match_cps_provider_2_tail_direct_ctl_2(Nat.is_eq(List.length(&2, String, v_15), cps_provider_2_entry_arity(cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_5)), v_11)), v_5, v_11, v_15)

def native_match_cps_provider_2_tail_direct_ctl_4(v_23: Maybe<&2, U32>, +v_1: U32, v_3: List<&2, BIR.Arg>, +v_5: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_23:
    case None{}:
      cps_provider_2_StepFail{String.concat(["BIR tail call names code ", U32.show(v_1), " with no entry"])}
    case Some{+v_11}:
      native_match_cps_provider_2_tail_direct_ctl_3(cps_provider_2_arg_strings(v_3, cps_provider_2_ctx_plan(v_5)), v_5, v_11)

def cps_provider_2_tail_direct_ctl(+v_1: U32, v_3: List<&2, BIR.Arg>, +v_5: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_tail_direct_ctl_4(IndexLookup.find(U32, cps_provider_2_sig_by_code(cps_provider_2_ctx_sig(v_5)), U32.show(v_1)), v_1, v_3, v_5)

def cps_provider_2_self_tail(+v_1: U32, v_4: List<&2, String>, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  +v_12 = cps_provider_2_entry_arity(cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_6)), v_1)
  v_19 = String.concat([cps_provider_2_regs_assign(v_4, 0n), cps_provider_2_a_rebinds(v_12), "    WL_AGAIN(", cps_provider_2_fid_name(v_1, cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_6))), ");\n"])
  cps_provider_2_StepOk{v_19, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_6), cps_provider_2_ctx_plan(v_6), cps_provider_2_ctx_env(v_6), cps_provider_2_ctx_caps(v_6), cps_provider_2_ctx_caps_n(v_6), cps_provider_2_ctx_regions(v_6), cps_provider_2_ctx_self(v_6), cps_provider_2_ctx_next(v_6), cps_provider_2_ctx_segs(v_6), cps_provider_2_ctx_outs(v_6), True{}, cps_provider_2_ctx_max(v_6)}}

def native_match_cps_provider_2_tail_apply_ctl_0(v_22: cps_provider_2_Part, +v_3: cps_provider_2_Ctx, v_10: String) -> cps_provider_2_Step:
  match v_22:
    case cps_provider_2_PartFail{v_18}:
      cps_provider_2_StepFail{v_18}
    case cps_provider_2_PartOk{v_20}:
      cps_provider_2_StepOk{String.concat(["    r0 = ", v_10, ";\n    r1 = ", v_20, ";\n    WL_JMP(FID_CLO_APPLY);\n"]), v_3}

def native_match_cps_provider_2_tail_apply_ctl_1(v_1: BIR.Arg, +v_3: cps_provider_2_Ctx, v_10: String) -> cps_provider_2_Step:
  match v_1:
    case BIR.Arg{v_13, v_14}:
      native_match_cps_provider_2_tail_apply_ctl_0(cps_provider_2_atom_part(v_14, cps_provider_2_ctx_plan(v_3)), v_3, v_10)

def native_match_cps_provider_2_tail_apply_ctl_2(v_21: cps_provider_2_Part, v_1: BIR.Arg, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_21:
    case cps_provider_2_PartFail{v_8}:
      cps_provider_2_StepFail{v_8}
    case cps_provider_2_PartOk{v_10}:
      native_match_cps_provider_2_tail_apply_ctl_1(v_1, v_3, v_10)

def cps_provider_2_tail_apply_ctl(v_0: BIR.Atom, v_1: BIR.Arg, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_tail_apply_ctl_2(cps_provider_2_atom_part(v_0, cps_provider_2_ctx_plan(v_3)), v_1, v_3)

def native_match_cps_provider_2_direct_ctl_0(v_20: Maybe<&2, List<&2, String>>, v_1: U32, v_6: BIR.Block, +v_8: cps_provider_2_Ctx, v_14: U32) -> cps_provider_2_Step:
  match v_20:
    case None{}:
      cps_provider_2_StepFail{"BIR call argument has no C value"}
    case Some{v_18}:
      cps_provider_2_call_ctl(v_14, v_18, v_1, v_6, v_8)

def native_match_cps_provider_2_direct_ctl_1(v_19: Maybe<&2, U32>, v_1: U32, +v_3: U32, v_5: List<&2, BIR.Arg>, v_6: BIR.Block, +v_8: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_19:
    case None{}:
      cps_provider_2_StepFail{String.concat(["BIR call names code ", U32.show(v_3), " with no entry"])}
    case Some{v_14}:
      native_match_cps_provider_2_direct_ctl_0(cps_provider_2_arg_strings(v_5, cps_provider_2_ctx_plan(v_8)), v_1, v_6, v_8, v_14)

def cps_provider_2_direct_ctl(v_1: U32, +v_3: U32, v_5: List<&2, BIR.Arg>, v_6: BIR.Block, +v_8: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_direct_ctl_1(IndexLookup.find(U32, cps_provider_2_sig_by_code(cps_provider_2_ctx_sig(v_8)), U32.show(v_3)), v_1, v_3, v_5, v_6, v_8)

def native_match_cps_provider_2_apply_ctl_0(v_25: cps_provider_2_Part, v_1: U32, v_4: BIR.Block, +v_6: cps_provider_2_Ctx, v_13: String) -> cps_provider_2_Step:
  match v_25:
    case cps_provider_2_PartFail{v_21}:
      cps_provider_2_StepFail{v_21}
    case cps_provider_2_PartOk{v_23}:
      cps_provider_2_call_ctl(cps_provider_2_sig_apply(cps_provider_2_ctx_sig(v_6)), [v_13, v_23], v_1, v_4, v_6)

def native_match_cps_provider_2_apply_ctl_1(v_3: BIR.Arg, v_1: U32, v_4: BIR.Block, +v_6: cps_provider_2_Ctx, v_13: String) -> cps_provider_2_Step:
  match v_3:
    case BIR.Arg{v_16, v_17}:
      native_match_cps_provider_2_apply_ctl_0(cps_provider_2_atom_part(v_17, cps_provider_2_ctx_plan(v_6)), v_1, v_4, v_6, v_13)

def native_match_cps_provider_2_apply_ctl_2(v_24: cps_provider_2_Part, v_1: U32, v_3: BIR.Arg, v_4: BIR.Block, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_24:
    case cps_provider_2_PartFail{v_11}:
      cps_provider_2_StepFail{v_11}
    case cps_provider_2_PartOk{v_13}:
      native_match_cps_provider_2_apply_ctl_1(v_3, v_1, v_4, v_6, v_13)

def cps_provider_2_apply_ctl(v_1: U32, v_2: BIR.Atom, v_3: BIR.Arg, v_4: BIR.Block, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_apply_ctl_2(cps_provider_2_atom_part(v_2, cps_provider_2_ctx_plan(v_6)), v_1, v_3, v_4, v_6)

def native_match_cps_provider_2_call_ctl_0(v_23: Maybe<&2, List<&2, cps_provider_2_Cap>>, +v_1: U32, +v_4: List<&2, String>, v_6: U32, +v_7: BIR.Block, +v_9: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_23:
    case None{}:
      cps_provider_2_StepFail{"BIR continuation reads a value that is not in scope"}
    case Some{v_21}:
      cps_provider_2_call_next(v_1, v_4, v_6, v_7, v_9, v_21)

def native_match_cps_provider_2_call_ctl_1(v_22: Bool, +v_1: U32, +v_4: List<&2, String>, v_6: U32, +v_7: BIR.Block, +v_9: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_22:
    case False{}:
      cps_provider_2_StepFail{String.concat(["BIR call passes ", Nat.show(List.length(&2, String, v_4)), " arguments to an entry of arity ", Nat.show(cps_provider_2_entry_arity(cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_9)), v_1))])}
    case True{}:
      native_match_cps_provider_2_call_ctl_0(cps_provider_2_capture_for(v_7, v_9), v_1, v_4, v_6, v_7, v_9)

def cps_provider_2_call_ctl(+v_1: U32, +v_4: List<&2, String>, v_6: U32, +v_7: BIR.Block, +v_9: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_call_ctl_1(Nat.is_eq(List.length(&2, String, v_4), cps_provider_2_entry_arity(cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_9)), v_1)), v_1, v_4, v_6, v_7, v_9)

def native_match_cps_provider_2_call_next_0(v_35: cps_provider_2_Step, v_1: U32, v_4: List<&2, String>, +v_6: U32, +v_9: cps_provider_2_Ctx, +v_12: List<&2, cps_provider_2_Cap>) -> cps_provider_2_Step:
  match v_35:
    case cps_provider_2_StepFail{v_30}:
      cps_provider_2_StepFail{v_30}
    case cps_provider_2_StepOk{v_33, v_34}:
      cps_provider_2_call_done(v_1, v_4, v_12, v_6, v_9, v_33, v_34)

def cps_provider_2_call_next(v_1: U32, v_4: List<&2, String>, +v_6: U32, v_7: BIR.Block, +v_9: cps_provider_2_Ctx, +v_12: List<&2, cps_provider_2_Cap>) -> cps_provider_2_Step:
  native_match_cps_provider_2_call_next_0(cps_provider_2_block_ctl(v_7, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_9), cps_provider_2_ctx_plan(v_9), cps_provider_2_Env{v_6, cps_provider_2_lv_name(v_6)} <> cps_provider_2_cap_locals_env(v_12, []), cps_provider_2_cap_slots_exprs(v_12, cps_provider_2_ctx_caps_n(v_9), 0n, []), cps_provider_2_ctx_caps_n(v_9), cps_provider_2_ctx_regions(v_9), None{}, U32.inc(cps_provider_2_ctx_next(v_9)), cps_provider_2_ctx_segs(v_9), cps_provider_2_ctx_outs(v_9), False{}, cps_provider_2_nat_max(cps_provider_2_ctx_max(v_9), Nat.add(List.length(&2, cps_provider_2_Cap, v_12), 1n))}), v_1, v_4, v_6, v_9, v_12)

def cps_provider_2_call_done(v_1: U32, v_4: List<&2, String>, +v_7: List<&2, cps_provider_2_Cap>, v_9: U32, +v_11: cps_provider_2_Ctx, v_13: String, +v_15: cps_provider_2_Ctx) -> cps_provider_2_Step:
  +v_19 = cps_provider_2_ctx_next(v_11)
  +v_22 = List.length(&2, cps_provider_2_Cap, v_7)
  cps_provider_2_StepOk{cps_provider_2_call_head(v_19, v_22, v_7, v_4, v_1, cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_11))), cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_15), cps_provider_2_ctx_plan(v_15), cps_provider_2_ctx_env(v_15), cps_provider_2_ctx_caps(v_15), cps_provider_2_ctx_caps_n(v_15), cps_provider_2_ctx_regions(v_15), cps_provider_2_ctx_self(v_15), cps_provider_2_ctx_next(v_15), cps_provider_2_SegText{v_19, Nat.add(v_22, 1n), 1n, cps_provider_2_case_text(v_19, cps_provider_2_cont_prologue(v_7, cps_provider_2_ctx_caps_n(v_11), v_9), v_13, False{})} <> cps_provider_2_ctx_segs(v_15), cps_provider_2_ctx_outs(v_15), cps_provider_2_ctx_spin(v_15), cps_provider_2_ctx_max(v_15)}}

def cps_provider_2_arg_stores(+v_1: String, v_4: List<&2, String>, +v_6: Nat) -> String:
  match v_4:
    case []:
      ""
    case +v_10 <> v_11:
      String.concat(["      e.mem[", v_1, " + ", Nat.show(v_6), "] = ", v_10, ";\n", cps_provider_2_arg_stores(v_1, v_11, Nat.add(v_6, 1n))])

def cps_provider_2_call_head(+v_1: U32, +v_3: Nat, +v_6: List<&2, cps_provider_2_Cap>, +v_9: List<&2, String>, +v_11: U32, +v_14: List<&2, cps_provider_2_Entry>) -> String:
  +v_17 = String.concat(["kc", U32.show(v_1)])
  +v_19 = String.concat(["kc", U32.show(v_1), "t"])
  String.concat(["    if (seq) {\n", "      WL_ROOM(", Nat.show(Nat.add(v_3, 1n)), ");\n", cps_provider_2_cap_stk_stores(v_6, 0n), "      STK(", Nat.show(v_3), ") = FID_", U32.show(v_1), ";\n", "      WL_PUSHN(", Nat.show(Nat.add(v_3, 1n)), ");\n", "    } else {\n", "      u64 ", v_17, " = task_node(e, FID_", U32.show(v_1), ", WL_CONT, WL_IDX, 1);\n", cps_provider_2_cap_stores(v_17, v_6, 0n), "      WL_CONT = term_tsk(FID_", U32.show(v_1), ", ", v_17, ");\n", "      WL_IDX = ", Nat.show(v_3), ";\n", "    }\n", "    if (!DEVICE && !seq && fid_nofk(", cps_provider_2_fid_name(v_11, v_14), ")) {\n", "      u64 ", v_19, " = task_node(e, ", cps_provider_2_fid_name(v_11, v_14), ", WL_CONT, WL_IDX, 0);\n", cps_provider_2_arg_stores(v_19, v_9, 0n), "      return term_tsk(", cps_provider_2_fid_name(v_11, v_14), ", ", v_19, ");\n", "    }\n", cps_provider_2_regs_assign(v_9, 0n), "    WL_JMP(", cps_provider_2_fid_name(v_11, v_14), ");\n"])

def cps_provider_2_cap_stk_stores(+v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat) -> String:
  match v_2:
    case []:
      ""
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_CapLocal{v_12, v_13}:
          String.concat(["    STK(", Nat.show(v_4), ") = ", v_13, ";\n", cps_provider_2_cap_stk_stores(v_9, Nat.add(v_4, 1n))])
        case cps_provider_2_CapSlot{v_17, v_18}:
          String.concat(["    STK(", Nat.show(v_4), ") = ", v_18, ";\n", cps_provider_2_cap_stk_stores(v_9, Nat.add(v_4, 1n))])

def cps_provider_2_cap_stores(+v_1: String, v_4: List<&2, cps_provider_2_Cap>, +v_6: Nat) -> String:
  match v_4:
    case []:
      ""
    case +v_10 <> v_11:
      match v_10:
        case cps_provider_2_CapLocal{v_14, v_15}:
          String.concat(["    e.mem[", v_1, " + ", Nat.show(v_6), "] = ", v_15, ";\n", cps_provider_2_cap_stores(v_1, v_11, Nat.add(v_6, 1n))])
        case cps_provider_2_CapSlot{v_19, v_20}:
          String.concat(["    e.mem[", v_1, " + ", Nat.show(v_6), "] = ", v_20, ";\n", cps_provider_2_cap_stores(v_1, v_11, Nat.add(v_6, 1n))])

def native_match_cps_provider_2_load_symbol_ctl_0(v_77: Maybe<&2, U32>, +v_1: U32, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx, +v_17: U32) -> cps_provider_2_Step:
  match v_77:
    case None{}:
      cps_provider_2_StepFail{String.concat(["BIR reads code ", U32.show(v_17), " with no entry"])}
    case Some{v_23}:
      cps_provider_2_call_ctl(v_23, [], v_1, v_4, v_6)

def native_match_cps_provider_2_load_symbol_ctl_1(v_76: Bool, +v_1: U32, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx, v_16: String, +v_17: U32) -> cps_provider_2_Step:
  match v_76:
    case False{}:
      cps_provider_2_StepFail{String.concat(["BIR reads the parameterised `", v_16, "` as a lazy symbol"])}
    case True{}:
      native_match_cps_provider_2_load_symbol_ctl_0(IndexLookup.find(U32, cps_provider_2_sig_by_code(cps_provider_2_ctx_sig(v_6)), U32.show(v_17)), v_1, v_4, v_6, v_17)

def native_match_cps_provider_2_load_symbol_ctl_2(v_78: Maybe<&2, U32>, +v_1: U32, +v_3: String, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_78:
    case None{}:
      cps_provider_2_StepFail{String.concat(["BIR reads lazy `", v_3, "` with no entry"])}
    case Some{v_33}:
      cps_provider_2_call_ctl(v_33, [], v_1, v_4, v_6)

def native_match_cps_provider_2_load_symbol_ctl_3(v_79: Maybe<&2, U32>, +v_1: U32, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx, +v_44: String) -> cps_provider_2_Step:
  match v_79:
    case Some{v_57}:
      cps_provider_2_value_bind_entry(v_1, v_57, cps_provider_2_foreign_stem(v_44), v_4, v_6)
    case None{}:
      cps_provider_2_StepFail{String.concat(["foreign `", v_44, "` has no entry"])}

def native_match_cps_provider_2_load_symbol_ctl_4(v_80: Maybe<&2, U32>, +v_1: U32, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx, +v_63: String) -> cps_provider_2_Step:
  match v_80:
    case Some{v_70}:
      cps_provider_2_value_bind_entry(v_1, v_70, cps_provider_2_native_stem(v_63), v_4, v_6)
    case None{}:
      cps_provider_2_StepFail{String.concat(["native `", v_63, "` has no first-class C value"])}

def native_match_cps_provider_2_load_symbol_ctl_5(v_12: BIR.Declaration, +v_1: U32, +v_3: String, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_12:
    case BIR.FunctionDeclaration{v_16, +v_17, v_18}:
      native_match_cps_provider_2_load_symbol_ctl_1(Nat.is_eq(List.length(&2, BIR.Parameter, v_18), 0n), v_1, v_4, v_6, v_16, v_17)
    case BIR.LazyDeclaration{v_27, v_28}:
      native_match_cps_provider_2_load_symbol_ctl_2(IndexLookup.find(U32, cps_provider_2_sig_by_key(cps_provider_2_ctx_sig(v_6)), v_3), v_1, v_3, v_4, v_6)
    case BIR.ForeignDeclaration{+v_44, _, _, v_47, _, _, _, _, _}:
      native_match_cps_provider_2_load_symbol_ctl_3(IndexLookup.find(U32, cps_provider_2_sig_by_foreign(cps_provider_2_ctx_sig(v_6)), v_44), v_1, v_4, v_6, v_44)
    case BIR.NativeDeclaration{+v_63, v_64, v_65}:
      native_match_cps_provider_2_load_symbol_ctl_4(IndexLookup.find(U32, cps_provider_2_sig_by_native(cps_provider_2_ctx_sig(v_6)), v_63), v_1, v_4, v_6, v_63)
    case _:
      cps_provider_2_StepFail{"BIR declaration form has no C value"}

def native_match_cps_provider_2_load_symbol_ctl_6(v_75: Maybe<&2, BIR.Declaration>, +v_1: U32, +v_3: String, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_75:
    case None{}:
      cps_provider_2_StepFail{String.concat(["BIR reads `", v_3, "` with no declaration"])}
    case Some{v_12}:
      native_match_cps_provider_2_load_symbol_ctl_5(v_12, v_1, v_3, v_4, v_6)

def cps_provider_2_load_symbol_ctl(+v_1: U32, +v_3: String, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_load_symbol_ctl_6(cps_provider_2_find_declaration(v_3, cps_provider_2_sig_decls(cps_provider_2_ctx_sig(v_6))), v_1, v_3, v_4, v_6)

def native_match_cps_provider_2_value_bind_entry_0(v_34: cps_provider_2_Step, +v_1: U32, v_12: String) -> cps_provider_2_Step:
  match v_34:
    case cps_provider_2_StepFail{v_28}:
      cps_provider_2_StepFail{v_28}
    case cps_provider_2_StepOk{v_31, v_32}:
      cps_provider_2_StepOk{String.concat(["    Term ", cps_provider_2_lv_name(v_1), " = ", v_12, ";\n", v_31]), v_32}

def native_match_cps_provider_2_value_bind_entry_1(v_33: Maybe<&2, String>, +v_1: U32, v_6: BIR.Block, +v_8: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_33:
    case None{}:
      cps_provider_2_StepFail{"BIR symbol has no arity-one value entry"}
    case Some{v_12}:
      native_match_cps_provider_2_value_bind_entry_0(cps_provider_2_block_ctl(v_6, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_8), cps_provider_2_ctx_plan(v_8), cps_provider_2_Env{v_1, cps_provider_2_lv_name(v_1)} <> cps_provider_2_ctx_env(v_8), cps_provider_2_ctx_caps(v_8), cps_provider_2_ctx_caps_n(v_8), cps_provider_2_ctx_regions(v_8), cps_provider_2_ctx_self(v_8), cps_provider_2_ctx_next(v_8), cps_provider_2_ctx_segs(v_8), cps_provider_2_ctx_outs(v_8), cps_provider_2_ctx_spin(v_8), cps_provider_2_ctx_max(v_8)}), v_1, v_12)

def cps_provider_2_value_bind_entry(+v_1: U32, v_3: U32, v_5: String, v_6: BIR.Block, +v_8: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_value_bind_entry_1(cps_provider_2_value_closure(v_3, v_5, v_8), v_1, v_6, v_8)

def native_match_cps_provider_2_value_closure_0(v_21: Maybe<&2, U32>) -> Maybe<&2, String>:
  match v_21:
    case Some{v_18}:
      Some{String.concat(["term_clo(FID_", U32.show(v_18), ", 0)"])}
    case None{}:
      None{}

def native_match_cps_provider_2_value_closure_1(v_20: Bool, +v_1: U32, v_3: String, +v_5: cps_provider_2_Ctx) -> Maybe<&2, String>:
  match v_20:
    case True{}:
      Some{String.concat(["term_clo(FID_", U32.show(v_1), ", 0)"])}
    case False{}:
      native_match_cps_provider_2_value_closure_0(IndexLookup.find(U32, cps_provider_2_sig_stages(cps_provider_2_ctx_sig(v_5)), cps_provider_2_stage_key(v_3, 0n)))

def native_match_cps_provider_2_value_closure_2(v_19: Bool, +v_1: U32, v_3: String, +v_5: cps_provider_2_Ctx, +v_12: Nat) -> Maybe<&2, String>:
  match v_19:
    case True{}:
      None{}
    case False{}:
      native_match_cps_provider_2_value_closure_1(Nat.is_eq(v_12, 1n), v_1, v_3, v_5)

def cps_provider_2_value_closure(+v_1: U32, v_3: String, +v_5: cps_provider_2_Ctx) -> Maybe<&2, String>:
  +v_12 = cps_provider_2_entry_arity(cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_5)), v_1)
  native_match_cps_provider_2_value_closure_2(Nat.is_eq(v_12, 0n), v_1, v_3, v_5, v_12)

def native_match_cps_provider_2_closure_ctl_0(v_33: Maybe<&2, List<&2, String>>, v_1: U32, +v_3: U32, v_8: BIR.Block, +v_10: cps_provider_2_Ctx, +v_16: U32, +v_21: Nat, +v_23: Nat) -> cps_provider_2_Step:
  match v_33:
    case None{}:
      cps_provider_2_StepFail{"BIR capture has no C value"}
    case Some{v_29}:
      cps_provider_2_closure_bind(v_1, v_3, v_23, v_21, v_16, v_29, v_8, v_10)

def native_match_cps_provider_2_closure_ctl_1(v_32: Bool, v_1: U32, +v_3: U32, +v_5: List<&2, BIR.Arg>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx, +v_16: U32, +v_21: Nat, +v_23: Nat) -> cps_provider_2_Step:
  match v_32:
    case False{}:
      cps_provider_2_StepFail{"BIR closure capture count disagrees with its code entry"}
    case True{}:
      native_match_cps_provider_2_closure_ctl_0(cps_provider_2_arg_strings(v_5, cps_provider_2_ctx_plan(v_10)), v_1, v_3, v_8, v_10, v_16, v_21, v_23)

def native_match_cps_provider_2_closure_ctl_2(v_31: Bool, v_1: U32, +v_3: U32, +v_5: List<&2, BIR.Arg>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx, +v_16: U32, +v_21: Nat, +v_23: Nat, +v_25: Nat) -> cps_provider_2_Step:
  match v_31:
    case True{}:
      cps_provider_2_StepFail{"BIR closure has no remaining parameter"}
    case False{}:
      native_match_cps_provider_2_closure_ctl_1(Nat.is_eq(Nat.add(v_23, v_25), v_21), v_1, v_3, v_5, v_8, v_10, v_16, v_21, v_23)

def native_match_cps_provider_2_closure_ctl_3(v_30: Maybe<&2, U32>, v_1: U32, +v_3: U32, +v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_30:
    case None{}:
      cps_provider_2_StepFail{String.concat(["BIR closure names code ", U32.show(v_3), " with no entry"])}
    case Some{+v_16}:
      +v_21 = cps_provider_2_entry_arity(cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_10)), v_16)
      +v_23 = List.length(&2, BIR.Arg, v_5)
      +v_25 = List.length(&2, BIR.Parameter, v_7)
      native_match_cps_provider_2_closure_ctl_2(Nat.is_eq(v_25, 0n), v_1, v_3, v_5, v_8, v_10, v_16, v_21, v_23, v_25)

def cps_provider_2_closure_ctl(v_1: U32, +v_3: U32, +v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_closure_ctl_3(IndexLookup.find(U32, cps_provider_2_sig_by_code(cps_provider_2_ctx_sig(v_10)), U32.show(v_3)), v_1, v_3, v_5, v_7, v_8, v_10)

def native_match_cps_provider_2_closure_bind_0(v_41: cps_provider_2_Step, +v_1: U32, +v_5: Nat, v_12: List<&2, String>, v_19: U32) -> cps_provider_2_Step:
  match v_41:
    case cps_provider_2_StepFail{v_35}:
      cps_provider_2_StepFail{v_35}
    case cps_provider_2_StepOk{v_38, v_39}:
      cps_provider_2_StepOk{String.concat([cps_provider_2_closure_text(v_1, v_5, v_19, v_12), v_38]), v_39}

def native_match_cps_provider_2_closure_bind_1(v_40: Maybe<&2, U32>, +v_1: U32, +v_5: Nat, v_12: List<&2, String>, v_13: BIR.Block, +v_15: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_40:
    case None{}:
      cps_provider_2_StepFail{"BIR closure has no staged entry"}
    case Some{v_19}:
      native_match_cps_provider_2_closure_bind_0(cps_provider_2_block_ctl(v_13, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_15), cps_provider_2_ctx_plan(v_15), cps_provider_2_Env{v_1, cps_provider_2_lv_name(v_1)} <> cps_provider_2_ctx_env(v_15), cps_provider_2_ctx_caps(v_15), cps_provider_2_ctx_caps_n(v_15), cps_provider_2_ctx_regions(v_15), cps_provider_2_ctx_self(v_15), cps_provider_2_ctx_next(v_15), cps_provider_2_ctx_segs(v_15), cps_provider_2_ctx_outs(v_15), cps_provider_2_ctx_spin(v_15), cps_provider_2_ctx_max(v_15)}), v_1, v_5, v_12, v_19)

def cps_provider_2_closure_bind(+v_1: U32, v_3: U32, +v_5: Nat, v_7: Nat, v_9: U32, v_12: List<&2, String>, v_13: BIR.Block, +v_15: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_closure_bind_1(cps_provider_2_closure_entry(v_3, v_5, v_7, v_9, v_15), v_1, v_5, v_12, v_13, v_15)

def cps_provider_2_closure_text(+v_1: U32, +v_3: Nat, v_5: U32, v_8: List<&2, String>) -> String:
  +v_11 = String.concat(["nd", U32.show(v_1)])
  String.concat([cps_provider_2_closure_alloc_decl(v_3, v_11, v_8), "    Term ", cps_provider_2_lv_name(v_1), " = term_clo(FID_", U32.show(v_5), ", ", cps_provider_2_closure_ptr(v_3, v_11), ");\n"])

def native_match_cps_provider_2_closure_entry_0(v_13: Bool, v_1: U32, +v_3: Nat, v_7: U32, v_9: cps_provider_2_Ctx) -> Maybe<&2, U32>:
  match v_13:
    case True{}:
      Some{v_7}
    case False{}:
      IndexLookup.find(U32, cps_provider_2_sig_stages(cps_provider_2_ctx_sig(v_9)), cps_provider_2_stage_key(cps_provider_2_code_stem(v_1), v_3))

def cps_provider_2_closure_entry(v_1: U32, +v_3: Nat, v_5: Nat, v_7: U32, v_9: cps_provider_2_Ctx) -> Maybe<&2, U32>:
  native_match_cps_provider_2_closure_entry_0(Nat.is_eq(Nat.add(v_3, 1n), v_5), v_1, v_3, v_7, v_9)

def cps_provider_2_closure_alloc(+v_1: String, v_4: List<&2, String>, +v_6: Nat) -> String:
  match v_4:
    case []:
      ""
    case +v_10 <> v_11:
      String.concat(["    e.mem[", v_1, " + ", Nat.show(v_6), "] = ", v_10, ";\n", cps_provider_2_closure_alloc(v_1, v_11, Nat.add(v_6, 1n))])

def native_match_cps_provider_2_closure_alloc_decl_0(v_7: Bool, +v_1: Nat, +v_3: String, v_6: List<&2, String>) -> String:
  match v_7:
    case True{}:
      ""
    case False{}:
      String.concat(["    u64 ", v_3, " = heap_alloc(e, cls_fit(", Nat.show(v_1), "));\n", cps_provider_2_closure_alloc(v_3, v_6, 0n)])

def cps_provider_2_closure_alloc_decl(+v_1: Nat, +v_3: String, v_6: List<&2, String>) -> String:
  native_match_cps_provider_2_closure_alloc_decl_0(Nat.is_eq(v_1, 0n), v_1, v_3, v_6)

def native_match_cps_provider_2_closure_ptr_0(v_4: Bool, v_3: String) -> String:
  match v_4:
    case True{}:
      "0"
    case False{}:
      v_3

def cps_provider_2_closure_ptr(v_1: Nat, v_3: String) -> String:
  native_match_cps_provider_2_closure_ptr_0(Nat.is_eq(v_1, 0n), v_3)

def native_match_cps_provider_2_entries_ctl_0(v_17: cps_provider_2_Step, v_9: List<&2, cps_provider_2_Entry>) -> cps_provider_2_Step:
  match v_17:
    case cps_provider_2_StepFail{v_12}:
      cps_provider_2_StepFail{v_12}
    case cps_provider_2_StepOk{v_15, v_16}:
      cps_provider_2_entries_ctl(v_9, v_16)

def native_match_cps_provider_2_entries_ctl_1(v_2: List<&2, cps_provider_2_Entry>, +v_4: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_2:
    case []:
      cps_provider_2_StepOk{"", v_4}
    case +v_8 <> v_9:
      native_match_cps_provider_2_entries_ctl_0(cps_provider_2_entry_ctl(v_8, v_4), v_9)

def cps_provider_2_entries_ctl(v_2: List<&2, cps_provider_2_Entry>, +v_4: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_entries_ctl_1(v_2, v_4)

def cps_provider_2_entry_ctl(v_1: cps_provider_2_Entry, v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_1:
    case cps_provider_2_Entry{v_8, v_9, v_10}:
      cps_provider_2_entry_kind_ctl(v_8, v_9, v_10, v_3)

def cps_provider_2_entry_kind_ctl(+v_1: U32, +v_3: Nat, v_5: cps_provider_2_EntryKind, +v_7: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_5:
    case cps_provider_2_KindCode{v_13, v_14, v_15, v_16}:
      cps_provider_2_entry_code(v_1, v_3, v_14, v_15, v_16, v_7)
    case cps_provider_2_KindStage{v_19}:
      cps_provider_2_entry_stage(v_1, v_3, v_19, v_7)
    case cps_provider_2_KindLazy{v_22}:
      cps_provider_2_entry_lazy(v_1, v_3, v_22, v_7)
    case cps_provider_2_KindForeign{v_26, v_27}:
      cps_provider_2_entry_foreign(v_1, v_3, v_26, v_27, v_7)
    case cps_provider_2_KindNative{v_31, v_32}:
      cps_provider_2_entry_native(v_1, v_3, v_31, v_32, v_7)
    case cps_provider_2_KindMain{}:
      cps_provider_2_entry_main(v_1, v_7)
    case cps_provider_2_KindLibrary{}:
      cps_provider_2_entry_library(v_1, v_7)
    case cps_provider_2_KindEmit{}:
      cps_provider_2_entry_reserved(v_1, v_7)
    case cps_provider_2_KindApply{}:
      cps_provider_2_entry_reserved(v_1, v_7)
    case cps_provider_2_KindExit{}:
      cps_provider_2_entry_reserved(v_1, v_7)
    case cps_provider_2_KindEnter{}:
      cps_provider_2_entry_reserved(v_1, v_7)

def cps_provider_2_entry_library(+v_1: U32, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  cps_provider_2_entry_add(v_1, "", "    r0 = 0;\n    WL_RETN(1);\n", False{}, v_3)

def cps_provider_2_entry_reserved(v_1: U32, v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  cps_provider_2_StepOk{"", v_3}

def cps_provider_2_entry_add(v_1: U32, +v_3: String, +v_5: String, +v_7: Bool, +v_9: cps_provider_2_Ctx) -> cps_provider_2_Step:
  cps_provider_2_StepOk{"", cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_9), cps_provider_2_ctx_plan(v_9), cps_provider_2_ctx_env(v_9), cps_provider_2_ctx_caps(v_9), cps_provider_2_ctx_caps_n(v_9), cps_provider_2_ctx_regions(v_9), cps_provider_2_ctx_self(v_9), cps_provider_2_ctx_next(v_9), cps_provider_2_ctx_segs(v_9), cps_provider_2_case_text(v_1, v_3, v_5, v_7) <> cps_provider_2_ctx_outs(v_9), False{}, cps_provider_2_ctx_max(v_9)}}

def native_match_cps_provider_2_entry_code_0(v_28: cps_provider_2_Step, +v_1: U32, +v_3: Nat, +v_5: Nat, +v_7: List<&2, BIR.Parameter>) -> cps_provider_2_Step:
  match v_28:
    case cps_provider_2_StepFail{v_22}:
      cps_provider_2_StepFail{v_22}
    case cps_provider_2_StepOk{v_25, +v_26}:
      cps_provider_2_entry_add(v_1, String.concat([cps_provider_2_a_decls(v_3), cps_provider_2_x_decl(v_5)]), String.concat([cps_provider_2_x_fill_a(v_5), cps_provider_2_params_bind(v_7, v_5, 0n), v_25]), cps_provider_2_ctx_spin(v_26), v_26)

def native_match_cps_provider_2_entry_code_1(v_27: Bool, +v_1: U32, +v_3: Nat, +v_5: Nat, +v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_27:
    case False{}:
      cps_provider_2_StepFail{"BIR code arity disagrees with its captures and parameters"}
    case True{}:
      native_match_cps_provider_2_entry_code_0(cps_provider_2_block_ctl(v_8, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_10), cps_provider_2_ctx_plan(v_10), cps_provider_2_params_env(v_7, v_5, 0n, []), cps_provider_2_a_caps(v_5), v_5, [], Some{v_1}, cps_provider_2_ctx_next(v_10), cps_provider_2_ctx_segs(v_10), cps_provider_2_ctx_outs(v_10), False{}, cps_provider_2_ctx_max(v_10)}), v_1, v_3, v_5, v_7)

def cps_provider_2_entry_code(+v_1: U32, +v_3: Nat, +v_5: Nat, +v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_entry_code_1(Nat.is_eq(Nat.add(v_5, List.length(&2, BIR.Parameter, v_7)), v_3), v_1, v_3, v_5, v_7, v_8, v_10)

def cps_provider_2_entry_stage(+v_1: U32, +v_3: Nat, v_5: U32, v_7: cps_provider_2_Ctx) -> cps_provider_2_Step:
  +v_10 = String.concat(["nd", U32.show(v_1)])
  v_13 = cps_provider_2_stage_stores(v_10, v_3, 0n)
  v_15 = String.concat(["    u64 ", v_10, " = heap_alloc(e, cls_fit(", Nat.show(v_3), "));\n", v_13, "    r0 = term_clo(FID_", U32.show(v_5), ", ", v_10, ");\n    WL_RETN(1);\n"])
  cps_provider_2_entry_add(v_1, cps_provider_2_a_decls(v_3), v_15, False{}, v_7)

def native_match_cps_provider_2_stage_stores_0(v_6: Bool, +v_1: String, +v_3: Nat, +v_5: Nat) -> String:
  match v_6:
    case True{}:
      String.concat(["    e.mem[", v_1, " + ", Nat.show(v_5), "] = a", Nat.show(v_5), ";\n", cps_provider_2_stage_stores(v_1, v_3, Nat.add(v_5, 1n))])
    case False{}:
      ""

def cps_provider_2_stage_stores(+v_1: String, +v_3: Nat, +v_5: Nat) -> String:
  native_match_cps_provider_2_stage_stores_0(Nat.is_lt(v_5, v_3), v_1, v_3, v_5)

def native_match_cps_provider_2_entry_lazy_0(v_21: cps_provider_2_Step, v_1: U32) -> cps_provider_2_Step:
  match v_21:
    case cps_provider_2_StepFail{v_16}:
      cps_provider_2_StepFail{v_16}
    case cps_provider_2_StepOk{v_19, +v_20}:
      cps_provider_2_entry_add(v_1, "", v_19, cps_provider_2_ctx_spin(v_20), v_20)

def cps_provider_2_entry_lazy(v_1: U32, v_3: Nat, v_4: BIR.Block, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_entry_lazy_0(cps_provider_2_block_ctl(v_4, cps_provider_2_Ctx{cps_provider_2_ctx_sig(v_6), cps_provider_2_ctx_plan(v_6), [], [], 0n, [], None{}, cps_provider_2_ctx_next(v_6), cps_provider_2_ctx_segs(v_6), cps_provider_2_ctx_outs(v_6), False{}, cps_provider_2_ctx_max(v_6)}), v_1)

def native_match_cps_provider_2_entry_native_0(v_18: cps_provider_2_Part, v_1: U32, +v_3: Nat, +v_8: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_18:
    case cps_provider_2_PartFail{v_14}:
      cps_provider_2_StepFail{v_14}
    case cps_provider_2_PartOk{v_16}:
      cps_provider_2_entry_add(v_1, cps_provider_2_a_decls(v_3), String.concat(["    r0 = ", v_16, ";\n    WL_RETN(1);\n"]), False{}, v_8)

def native_match_cps_provider_2_entry_native_1(v_17: Bool, v_1: U32, +v_3: Nat, v_4: BIR.Primitive, +v_6: Nat, +v_8: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_17:
    case False{}:
      cps_provider_2_StepFail{"BIR native entry arity disagrees with its live quantities"}
    case True{}:
      native_match_cps_provider_2_entry_native_0(cps_provider_2_prim_part(v_4, cps_provider_2_a_names(v_6), cps_provider_2_ctx_plan(v_8)), v_1, v_3, v_8)

def cps_provider_2_entry_native(v_1: U32, +v_3: Nat, v_4: BIR.Primitive, +v_6: Nat, +v_8: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_entry_native_1(Nat.is_eq(v_3, v_6), v_1, v_3, v_4, v_6, v_8)

def cps_provider_2_a_names(v_1: Nat) -> List<&2, String>:
  cps_provider_2_a_caps(v_1)

def native_match_cps_provider_2_entry_foreign_0(v_21: Bool, +v_1: U32, +v_3: Nat, v_5: String, +v_9: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_21:
    case False{}:
      cps_provider_2_StepFail{"BIR foreign entry arity disagrees with its declaration"}
    case True{}:
      +v_12 = String.concat(["nd", U32.show(v_1)])
      v_17 = cps_provider_2_cid_lookup(v_5, cps_provider_2_sig_cids(cps_provider_2_ctx_sig(v_9)))
      v_20 = String.concat(["    u64 ", v_12, " = heap_alloc(e, cls_fit(", Nat.show(v_3), "));\n", cps_provider_2_stage_stores(v_12, v_3, 0n), "    r0 = term_ctr(", U32.show(v_17), ", ", v_12, ");\n    WL_RETN(1);\n"])
      cps_provider_2_entry_add(v_1, cps_provider_2_a_decls(v_3), v_20, False{}, v_9)

def cps_provider_2_entry_foreign(+v_1: U32, +v_3: Nat, v_5: String, v_7: Nat, +v_9: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_entry_foreign_0(Nat.is_eq(v_3, Nat.add(v_7, 1n)), v_1, v_3, v_5, v_9)

def native_match_cps_provider_2_entry_main_0(v_31: Bool, +v_1: U32, +v_3: cps_provider_2_Ctx, v_14: U32) -> cps_provider_2_Step:
  match v_31:
    case False{}:
      cps_provider_2_StepFail{"the C target's main must take no parameters"}
    case True{}:
      cps_provider_2_main_jump(v_1, IndexLookup.find(U32, cps_provider_2_sig_by_code(cps_provider_2_ctx_sig(v_3)), U32.show(v_14)), v_3)

def native_match_cps_provider_2_entry_main_1(v_9: BIR.Declaration, +v_1: U32, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_9:
    case BIR.FunctionDeclaration{v_13, v_14, v_15}:
      native_match_cps_provider_2_entry_main_0(Nat.is_eq(List.length(&2, BIR.Parameter, v_15), 0n), v_1, v_3, v_14)
    case BIR.LazyDeclaration{v_22, v_23}:
      cps_provider_2_main_jump(v_1, IndexLookup.find(U32, cps_provider_2_sig_by_key(cps_provider_2_ctx_sig(v_3)), v_22), v_3)
    case _:
      cps_provider_2_StepFail{"a native or foreign declaration cannot be the C target's main"}

def native_match_cps_provider_2_entry_main_2(v_30: Maybe<&2, BIR.Declaration>, +v_1: U32, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_30:
    case None{}:
      cps_provider_2_StepFail{"the C target has no root main definition"}
    case Some{v_9}:
      native_match_cps_provider_2_entry_main_1(v_9, v_1, v_3)

def cps_provider_2_entry_main(+v_1: U32, +v_3: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_entry_main_2(cps_provider_2_find_declaration("main", cps_provider_2_sig_decls(cps_provider_2_ctx_sig(v_3))), v_1, v_3)

def native_match_cps_provider_2_main_jump_0(v_10: Bool, v_1: U32, +v_6: cps_provider_2_Ctx, +v_9: U32) -> cps_provider_2_Step:
  match v_10:
    case False{}:
      cps_provider_2_StepFail{"the C target's main entry must take no parameters"}
    case True{}:
      cps_provider_2_entry_add(v_1, "", String.concat(["    WL_JMP(", cps_provider_2_fid_name(v_9, cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_6))), ");\n"]), False{}, v_6)

def native_match_cps_provider_2_main_jump_1(v_4: Maybe<&2, U32>, v_1: U32, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  match v_4:
    case None{}:
      cps_provider_2_StepFail{"the C target's main declaration has no entry"}
    case Some{+v_9}:
      native_match_cps_provider_2_main_jump_0(Nat.is_eq(cps_provider_2_entry_arity(cps_provider_2_sig_entries(cps_provider_2_ctx_sig(v_6)), v_9), 0n), v_1, v_6, v_9)

def cps_provider_2_main_jump(v_1: U32, v_4: Maybe<&2, U32>, +v_6: cps_provider_2_Ctx) -> cps_provider_2_Step:
  native_match_cps_provider_2_main_jump_1(v_4, v_1, v_6)

def native_match_cps_provider_2_control_build_0(v_55: cps_provider_2_Step, +v_27: List<&2, cps_provider_2_Entry>) -> cps_provider_2_Control:
  match v_55:
    case cps_provider_2_StepFail{v_50}:
      cps_provider_2_ControlFail{v_50}
    case cps_provider_2_StepOk{_, +v_54}:
      cps_provider_2_ControlOk{String.concat([cps_provider_2_outs_text(cps_provider_2_ctx_outs(v_54), ""), cps_provider_2_segs_text(cps_provider_2_ctx_segs(v_54), "")]), cps_provider_2_rows_add_segs(cps_provider_2_ctx_segs(v_54), cps_provider_2_rows_add_entries(v_27, [])), cps_provider_2_ctx_max(v_54)}

def native_match_cps_provider_2_control_build_1(+v_1: cps_provider_2_Plan) -> cps_provider_2_Control:
  match v_1:
    case cps_provider_2_Plan{v_24, v_25, v_26, +v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, _, _}:
      native_match_cps_provider_2_control_build_0(cps_provider_2_entries_ctl(v_27, cps_provider_2_Ctx{cps_provider_2_Sig{v_27, v_28, v_29, v_30, v_31, v_32, v_35, v_24, cps_provider_2_rt_entry(v_27, 3n)}, v_1, [], [], 0n, [], None{}, U32.from_nat(List.length(&2, cps_provider_2_Entry, v_27)), [], [], False{}, cps_provider_2_max_arity(v_27)}), v_27)

def cps_provider_2_control_build(+v_1: cps_provider_2_Plan) -> cps_provider_2_Control:
  native_match_cps_provider_2_control_build_1(v_1)

def cps_provider_2_outs_text(v_2: List<&2, String>, +v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case +v_8 <> v_9:
      cps_provider_2_outs_text(v_9, String.append(v_8, v_4))

def cps_provider_2_segs_text(v_2: List<&2, cps_provider_2_SegText>, +v_4: String) -> String:
  match v_2:
    case []:
      v_4
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_SegText{v_14, v_15, v_16, v_17}:
          cps_provider_2_segs_text(v_9, String.append(v_17, v_4))

def native_match_cps_provider_2_rt_entry_0(v_8: cps_provider_2_Entry) -> U32:
  match v_8:
    case cps_provider_2_Entry{v_12, v_13, v_14}:
      v_12

def native_match_cps_provider_2_rt_entry_1(v_15: Maybe<&2, cps_provider_2_Entry>) -> U32:
  match v_15:
    case Some{v_8}:
      native_match_cps_provider_2_rt_entry_0(v_8)
    case None{}:
      0

def cps_provider_2_rt_entry(v_2: List<&2, cps_provider_2_Entry>, v_4: Nat) -> U32:
  native_match_cps_provider_2_rt_entry_1(cps_provider_2_entry_at_kind(v_2, v_4))

def native_match_cps_provider_2_entry_at_kind_0(v_17: Bool, +v_4: Nat, +v_9: cps_provider_2_Entry, v_10: List<&2, cps_provider_2_Entry>) -> Maybe<&2, cps_provider_2_Entry>:
  match v_17:
    case True{}:
      Some{v_9}
    case False{}:
      cps_provider_2_entry_at_kind(v_10, v_4)

def native_match_cps_provider_2_entry_at_kind_1(+v_9: cps_provider_2_Entry, +v_4: Nat, v_10: List<&2, cps_provider_2_Entry>) -> Maybe<&2, cps_provider_2_Entry>:
  match v_9:
    case cps_provider_2_Entry{v_14, v_15, v_16}:
      native_match_cps_provider_2_entry_at_kind_0(Nat.is_eq(cps_provider_2_kind_want(v_16), v_4), v_4, v_9, v_10)

def native_match_cps_provider_2_entry_at_kind_2(v_2: List<&2, cps_provider_2_Entry>, +v_4: Nat) -> Maybe<&2, cps_provider_2_Entry>:
  match v_2:
    case []:
      None{}
    case +v_9 <> v_10:
      native_match_cps_provider_2_entry_at_kind_1(v_9, v_4, v_10)

def cps_provider_2_entry_at_kind(v_2: List<&2, cps_provider_2_Entry>, +v_4: Nat) -> Maybe<&2, cps_provider_2_Entry>:
  native_match_cps_provider_2_entry_at_kind_2(v_2, v_4)

def cps_provider_2_kind_want(v_1: cps_provider_2_EntryKind) -> Nat:
  match v_1:
    case cps_provider_2_KindMain{}:
      1n
    case cps_provider_2_KindLibrary{}:
      6n
    case cps_provider_2_KindEmit{}:
      2n
    case cps_provider_2_KindApply{}:
      3n
    case cps_provider_2_KindExit{}:
      4n
    case cps_provider_2_KindEnter{}:
      5n
    case _:
      0n

def cps_provider_2_rows_add_entries(v_2: List<&2, cps_provider_2_Entry>, +v_5: List<&2, cps_provider_2_SegText>) -> List<&2, cps_provider_2_SegText>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      match v_10:
        case cps_provider_2_Entry{v_15, v_16, v_17}:
          cps_provider_2_rows_add_entries(v_11, cps_provider_2_row_insert(cps_provider_2_SegText{v_15, v_16, 0n, ""}, v_5))

def cps_provider_2_rows_add_segs(v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, cps_provider_2_SegText>) -> List<&2, cps_provider_2_SegText>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      cps_provider_2_rows_add_segs(v_11, cps_provider_2_row_insert(v_10, v_5))

def native_match_cps_provider_2_row_insert_0(v_27: Bool, +v_1: cps_provider_2_SegText, +v_4: List<&2, cps_provider_2_SegText>, +v_9: cps_provider_2_SegText, v_10: List<&2, cps_provider_2_SegText>) -> List<&2, cps_provider_2_SegText>:
  match v_27:
    case True{}:
      v_1 <> v_4
    case False{}:
      v_9 <> cps_provider_2_row_insert(v_1, v_10)

def native_match_cps_provider_2_row_insert_1(+v_9: cps_provider_2_SegText, +v_1: cps_provider_2_SegText, +v_4: List<&2, cps_provider_2_SegText>, v_10: List<&2, cps_provider_2_SegText>, v_15: U32) -> List<&2, cps_provider_2_SegText>:
  match v_9:
    case cps_provider_2_SegText{v_23, v_24, v_25, v_26}:
      native_match_cps_provider_2_row_insert_0(U32.is_lt(v_15, v_23), v_1, v_4, v_9, v_10)

def native_match_cps_provider_2_row_insert_2(+v_1: cps_provider_2_SegText, +v_4: List<&2, cps_provider_2_SegText>, +v_9: cps_provider_2_SegText, v_10: List<&2, cps_provider_2_SegText>) -> List<&2, cps_provider_2_SegText>:
  match v_1:
    case cps_provider_2_SegText{v_15, v_16, v_17, v_18}:
      native_match_cps_provider_2_row_insert_1(v_9, v_1, v_4, v_10, v_15)

def native_match_cps_provider_2_row_insert_3(+v_4: List<&2, cps_provider_2_SegText>, +v_1: cps_provider_2_SegText) -> List<&2, cps_provider_2_SegText>:
  match v_4:
    case []:
      [v_1]
    case +v_9 <> v_10:
      native_match_cps_provider_2_row_insert_2(v_1, v_4, v_9, v_10)

def cps_provider_2_row_insert(+v_1: cps_provider_2_SegText, +v_4: List<&2, cps_provider_2_SegText>) -> List<&2, cps_provider_2_SegText>:
  native_match_cps_provider_2_row_insert_3(v_4, v_1)

def native_match_cps_provider_2_rows_check_0(v_17: Bool, v_8: List<&2, cps_provider_2_SegText>, v_13: U32) -> Maybe<&2, String>:
  match v_17:
    case True{}:
      cps_provider_2_rows_check(v_8)
    case False{}:
      Some{String.concat(["entry ", U32.show(v_13), " has an arity or result width the runtime table cannot store"])}

def native_match_cps_provider_2_rows_check_1(+v_7: cps_provider_2_SegText, v_8: List<&2, cps_provider_2_SegText>) -> Maybe<&2, String>:
  match v_7:
    case cps_provider_2_SegText{v_13, v_14, v_15, v_16}:
      native_match_cps_provider_2_rows_check_0(Bool.and(Nat.is_le(v_14, 255n), Nat.is_le(v_15, 255n)), v_8, v_13)

def native_match_cps_provider_2_rows_check_2(v_2: List<&2, cps_provider_2_SegText>) -> Maybe<&2, String>:
  match v_2:
    case []:
      None{}
    case +v_7 <> v_8:
      native_match_cps_provider_2_rows_check_1(v_7, v_8)

def cps_provider_2_rows_check(v_2: List<&2, cps_provider_2_SegText>) -> Maybe<&2, String>:
  native_match_cps_provider_2_rows_check_2(v_2)

def cps_provider_2_cid_defines(v_2: List<&2, cps_provider_2_CidRow>) -> String:
  match v_2:
    case []:
      ""
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_CidRow{v_12, v_13, v_14, _}:
          String.concat(["#define CID_", U32.show(v_12), " ", U32.show(v_12), "\n", cps_provider_2_cid_defines(v_7)])

def cps_provider_2_fid_defines(v_2: List<&2, cps_provider_2_SegText>) -> String:
  match v_2:
    case []:
      ""
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_SegText{+v_12, v_13, v_14, v_15}:
          String.concat(["#define FID_", U32.show(v_12), " ", U32.show(v_12), "\n", cps_provider_2_fid_defines(v_7)])

def cps_provider_2_hot_text(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "1"
    case False{}:
      "0"

def cps_provider_2_blk_shr_text(v_1: cps_provider_2_Plan) -> String:
  match v_1:
    case cps_provider_2_Plan{v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, _, _}:
      cps_provider_2_array_shared_text(Sharing.array_shared(v_42))

def cps_provider_2_array_shared_text(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "1"
    case False{}:
      "0"

def cps_provider_2_cid_table(v_2: List<&2, cps_provider_2_CidRow>) -> String:
  match v_2:
    case []:
      "};\n"
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_CidRow{v_12, v_13, v_14, v_15}:
          String.concat(["{ ", Nat.show(v_14), ", ", cps_provider_2_hot_text(v_15), " }, ", cps_provider_2_cid_table(v_7)])

def cps_provider_2_fid_table(v_2: List<&2, cps_provider_2_SegText>) -> String:
  match v_2:
    case []:
      " };\n"
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_2_SegText{v_12, v_13, v_14, v_15}:
          String.concat(["{ ", Nat.show(v_13), ", ", Nat.show(v_14), ", 2 }, ", cps_provider_2_fid_table(v_7)])

def cps_provider_2_wl_table_text(v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, cps_provider_2_Entry>) -> String:
  cps_provider_2_wl_table_rows(v_2, v_5)

def native_match_cps_provider_2_wl_table_rows_0(v_23: Maybe<&2, String>, +v_5: List<&2, cps_provider_2_Entry>, v_10: List<&2, cps_provider_2_SegText>) -> String:
  match v_23:
    case None{}:
      cps_provider_2_wl_table_rows(v_10, v_5)
    case Some{v_22}:
      String.concat([v_22, " ", cps_provider_2_wl_table_rows(v_10, v_5)])

def native_match_cps_provider_2_wl_table_rows_1(+v_9: cps_provider_2_SegText, +v_5: List<&2, cps_provider_2_Entry>, v_10: List<&2, cps_provider_2_SegText>) -> String:
  match v_9:
    case cps_provider_2_SegText{+v_15, v_16, v_17, v_18}:
      native_match_cps_provider_2_wl_table_rows_0(cps_provider_2_wl_row_text(v_15, v_5), v_5, v_10)

def native_match_cps_provider_2_wl_table_rows_2(v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, cps_provider_2_Entry>) -> String:
  match v_2:
    case []:
      ""
    case +v_9 <> v_10:
      native_match_cps_provider_2_wl_table_rows_1(v_9, v_5, v_10)

def cps_provider_2_wl_table_rows(v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, cps_provider_2_Entry>) -> String:
  native_match_cps_provider_2_wl_table_rows_2(v_2, v_5)

def cps_provider_2_wl_row_text(+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> Maybe<&2, String>:
  Some{cps_provider_2_wl_row_name(v_1, v_4)}

def native_match_cps_provider_2_wl_row_name_0(v_8: Bool, +v_1: U32) -> String:
  match v_8:
    case True{}:
      "WL_X(FID_ENTER)"
    case False{}:
      String.concat(["WL_X(FID_", U32.show(v_1), ")"])

def native_match_cps_provider_2_wl_row_name_1(v_7: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  match v_7:
    case True{}:
      "WL_X(FID_EXIT)"
    case False{}:
      native_match_cps_provider_2_wl_row_name_0(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 5n)), v_1)

def native_match_cps_provider_2_wl_row_name_2(v_6: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  match v_6:
    case True{}:
      "WL_X(FID_CLO_APPLY)"
    case False{}:
      native_match_cps_provider_2_wl_row_name_1(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 4n)), v_1, v_4)

def native_match_cps_provider_2_wl_row_name_3(v_5: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  match v_5:
    case True{}:
      "WL_X(FID_IO_EMIT)"
    case False{}:
      native_match_cps_provider_2_wl_row_name_2(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 3n)), v_1, v_4)

def cps_provider_2_wl_row_name(+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> String:
  native_match_cps_provider_2_wl_row_name_3(U32.is_eq(v_1, cps_provider_2_rt_entry(v_4, 2n)), v_1, v_4)

def native_match_cps_provider_2_registers_each_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> List<&2, String>:
  match v_4:
    case True{}:
      cps_provider_2_r_name(v_3) <> cps_provider_2_registers_each(v_1, Nat.add(v_3, 1n))
    case False{}:
      []

def cps_provider_2_registers_each(+v_1: Nat, +v_3: Nat) -> List<&2, String>:
  native_match_cps_provider_2_registers_each_0(Nat.is_lt(v_3, v_1), v_1, v_3)

def cps_provider_2_register_decls(v_1: Nat) -> String:
  cps_provider_2_register_list(cps_provider_2_registers_each(v_1, 0n), "Term ")

def cps_provider_2_register_names(v_1: Nat) -> String:
  cps_provider_2_register_list(cps_provider_2_registers_each(v_1, 0n), "")

def cps_provider_2_register_list(v_2: List<&2, String>, +v_4: String) -> String:
  match v_2:
    case []:
      ""
    case +v_8 <> v_9:
      String.concat([v_4, v_8, cps_provider_2_register_tail(v_9, v_4)])

def cps_provider_2_register_tail(+v_2: List<&2, String>, v_4: String) -> String:
  match v_2:
    case []:
      ""
    case _:
      String.concat([", ", cps_provider_2_register_list(v_2, v_4)])

def native_match_cps_provider_2_wl_load_rows_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> String:
  match v_4:
    case True{}:
      String.concat(["    if ((N) <= ", Nat.show(v_3), ") break; ", cps_provider_2_r_name(v_3), " = e.mem[(A) + ", Nat.show(v_3), "]; \\\n", cps_provider_2_wl_load_rows(v_1, Nat.add(v_3, 1n))])
    case False{}:
      ""

def cps_provider_2_wl_load_rows(+v_1: Nat, +v_3: Nat) -> String:
  native_match_cps_provider_2_wl_load_rows_0(Nat.is_lt(v_3, v_1), v_1, v_3)

def native_match_cps_provider_2_wl_last_rows_0(v_4: Bool, +v_1: Nat, +v_3: Nat) -> String:
  match v_4:
    case True{}:
      String.concat(["    case ", Nat.show(v_3), ": ", cps_provider_2_r_name(v_3), " = (X); \\\n      break; \\\n", cps_provider_2_wl_last_rows(v_1, Nat.add(v_3, 1n))])
    case False{}:
      ""

def cps_provider_2_wl_last_rows(+v_1: Nat, +v_3: Nat) -> String:
  native_match_cps_provider_2_wl_last_rows_0(Nat.is_lt(v_3, v_1), v_1, v_3)

def cps_provider_2_wl_macros(+v_1: Nat) -> String:
  String.concat(["#define WL_RESW 1\n#define BANGS 0\n\n", "#define WL_BANK Term ", cps_provider_2_register_names(v_1), ";\n\n", "#define WL_LOAD(A, N) do { \\\n", cps_provider_2_wl_load_rows(v_1, 0n), "  } while (0);\n\n", "#define WL_LAST(X) switch (war) { \\\n", cps_provider_2_wl_last_rows(v_1, 0n), "  }\n\n", "#define WL_SAVE(V) (V)[0] = r0;\n", "#define WL_TAKE(V) r0 = (V)[0];\n\n", "#define WL_SIG Env e, DEV Term* sp, u32 seq, u32 rn, ", cps_provider_2_register_decls(v_1), "\n", "#define WL_ALL e, sp, seq, rn, ", cps_provider_2_register_names(v_1), "\n"])

def cps_provider_2_runtime_defines(+v_2: List<&2, cps_provider_2_Entry>) -> String:
  String.concat(["#define FID_MAIN ", U32.show(cps_provider_2_rt_entry(v_2, 1n)), "\n", "#define FID_IO_EMIT ", U32.show(cps_provider_2_rt_entry(v_2, 2n)), "\n", "#define FID_CLO_APPLY ", U32.show(cps_provider_2_rt_entry(v_2, 3n)), "\n", "#define FID_EXIT ", U32.show(cps_provider_2_rt_entry(v_2, 4n)), "\n", "#define FID_ENTER ", U32.show(cps_provider_2_rt_entry(v_2, 5n)), "\n"])

def native_match_cps_provider_2_tables_part_0(v_55: cps_provider_2_Part, v_1: cps_provider_2_Plan, +v_4: List<&2, cps_provider_2_SegText>, v_6: Nat, +v_29: List<&2, cps_provider_2_CidRow>, +v_32: List<&2, cps_provider_2_Entry>, v_41: Bool, v_42: String, v_43: String, v_48: Bool) -> cps_provider_2_Part:
  match v_55:
    case cps_provider_2_PartFail{v_52}:
      cps_provider_2_PartFail{v_52}
    case cps_provider_2_PartOk{v_54}:
      cps_provider_2_PartOk{String.concat([cps_provider_2_main_suppress(v_48), v_54, cps_provider_2_cid_defines(v_29), cps_provider_2_fid_defines(v_4), cps_provider_2_runtime_defines(v_32), "\n", "CONSTV u8 CID_T[][2] = { ", cps_provider_2_cid_table(v_29), "\n", "CONSTV u8 FID_T[][3] = { ", cps_provider_2_fid_table(v_4), "\n", "#define STAT_LEN 0\n\n", cps_provider_2_wl_macros(v_6), "\n", "#define WL_TABLE ", cps_provider_2_wl_table_text(v_4, v_32), "\n", "#define MAIN_FID FID_", U32.show(cps_provider_2_main_fid_index(v_48, v_32)), "\n", "#define MAIN_PURE ", cps_provider_2_main_pure_text(v_41), "\n", "#define BLK_SHR ", cps_provider_2_blk_shr_text(v_1), "\n\n", "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { ", v_42, " };\nstatic const char* SHOW_NAMES[] = { ", v_43, " };\n#endif\n\n"])}

def native_match_cps_provider_2_tables_part_1(v_1: cps_provider_2_Plan, +v_4: List<&2, cps_provider_2_SegText>, v_6: Nat) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_Plan{+v_29, v_30, v_31, +v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, v_45, v_46, v_47, v_48, _}:
      native_match_cps_provider_2_tables_part_0(cps_provider_2_runtime_cid_aliases(v_29), v_1, v_4, v_6, v_29, v_32, v_41, v_42, v_43, v_48)

def cps_provider_2_tables_part(v_1: cps_provider_2_Plan, +v_4: List<&2, cps_provider_2_SegText>, v_6: Nat) -> cps_provider_2_Part:
  native_match_cps_provider_2_tables_part_1(v_1, v_4, v_6)

def cps_provider_2_main_suppress(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "#define main bend_library_unused_main\n"
    case False{}:
      ""

def cps_provider_2_main_fid_index(v_1: Bool, v_4: List<&2, cps_provider_2_Entry>) -> U32:
  match v_1:
    case True{}:
      cps_provider_2_rt_entry(v_4, 6n)
    case False{}:
      cps_provider_2_rt_entry(v_4, 1n)

def cps_provider_2_main_pure_text(v_1: Bool) -> String:
  match v_1:
    case True{}:
      "1"
    case False{}:
      "0"

def cps_provider_2_spins_part() -> cps_provider_2_Part:
  cps_provider_2_okp(String.concat(["typedef u64 Nat;\n", cps_provider_2_helper_core, "static Term bend_text(Env e, const char* p, u64 n);\n", "CONSTV u64 STAT_IMG[] = { 0 };\n"]))

def cps_provider_2_helper_core() -> String:
  cps_provider_2_cat(["static u64 bend_hastag(Term v, u32 cid) {\n  u64 tag = term_tag(v);\n  return (tag == TAG_CTR || tag == TAG_PAK) && term_aux(v) == (u64)cid;\n}\n\n", "static Nat bend_nat_pred(Nat v) {\n  return v == 0 ? 0 : v - 1;\n}\n\n", "static Nat bend_f32_to_nat(Env e, Term v) {\n  f32 x = f32_unbox(v);\n  return nat_chk(e, x < 0.0f ? 0 : (u64)x);\n}\n\n", "static Term bend_tuple(Env e, u32 cid, Term a, Term b) {\n  u64 l = heap_alloc(e, cls_fit(2));\n  e.mem[l] = a;\n  e.mem[l + 1] = b;\n  return term_ctr(cid, l);\n}\n\n", "static Term bend_box_enum(Env e, const u32* cids, u32 n, u64 tag) {\n  (void)e;\n  return term_pak(tag < (u64)n ? cids[tag] : (n == 0 ? 0 : cids[0]), 0);\n}\n\n", "static Term bend_bool(Env e, u32 t, u32 f, u64 c) {\n  (void)e;\n  return term_pak(c != 0 ? t : f, 0);\n}\n\n", "static Term bend_bool_or(Env e, u32 t, u32 f, Term a, Term b) {\n  (void)e;\n  return term_pak(term_aux(a) == (u64)t || term_aux(b) == (u64)t ? t : f, 0);\n}\n\n", "static Term bend_bool_xor(Env e, u32 t, u32 f, Term a, Term b) {\n  (void)e;\n  return term_pak(term_aux(a) == (u64)t ? term_aux(b) != (u64)t : term_aux(b) == (u64)t ? t : f, 0);\n}\n\n", "static Term bend_cmp3(Env e, u32 lt, u32 eq, u32 gt, Term a, Term b) {\n  return term_pak(a < b ? lt : a == b ? eq : gt, 0);\n}\n\n", "static Term bend_divmod(Env e, u32 cid, Term a, Term b) {\n  if (b == 0) {\n    return bend_tuple(e, cid, 0, a);\n  }\n  return bend_tuple(e, cid, a / b, a % b);\n}\n\n", "static Term bend_str_cons(Env e, u32 scon, u64 ch, Term tail) {\n  u64 l = heap_alloc(e, cls_fit(2));\n  e.mem[l] = ch;\n  e.mem[l + 1] = tail;\n  return term_ctr(scon, l);\n}\n\n", "static Term bend_str_append_go(Env e, u32 scon, u32 chr, Term a, Term b) {\n  if (term_aux(a) == (u64)chr) {\n    return bend_str_cons(e, scon, (u64)term_loc(a), b);\n  }\n  if (term_aux(a) != (u64)scon) {\n    return b;\n  }\n  u64 l = term_peek(e.mem, a);\n  return bend_str_cons(e, scon, e.mem[l], bend_str_append_go(e, scon, chr, e.mem[l + 1], b));\n}\n\n", "static Term bend_str_append(Env e, u32 scon, u32 chr, Term a, Term b, u32 keep) {\n  return bend_str_append_go(e, scon, chr, a, term_keep(e, b, keep));\n}\n\n", "static Nat bend_str_length(Env e, u32 scon, Term a) {\n  Nat n = 0;\n  while (term_aux(a) == (u64)scon) {\n    a = e.mem[term_peek(e.mem, a) + 1];\n    n += 1;\n  }\n  return n;\n}\n\n", "static u32 bend_str_empty(Term a, u32 snil) {\n  return term_aux(a) == (u64)snil;\n}\n\n", "static Term bend_str_head(Env e, u32 scon, Term a) {\n  if (term_aux(a) != (u64)scon) {\n    return 0;\n  }\n  return e.mem[term_peek(e.mem, a)];\n}\n\n", "static Term bend_str_tail(Env e, u32 scon, u32 snil, Term a) {\n  if (term_aux(a) != (u64)scon) {\n    return term_pak(snil, 0);\n  }\n  return e.mem[term_peek(e.mem, a) + 1];\n}\n\n", "static Term bend_str_to_list(Env e, u32 scon, u32 snil, u32 con, u32 nil, u32 chr, Term a) {\n  if (term_aux(a) != (u64)scon) {\n    return term_pak(nil, 0);\n  }\n  u64 l = term_peek(e.mem, a);\n  Term tail = bend_str_to_list(e, scon, snil, con, nil, chr, e.mem[l + 1]);\n  u64 n = heap_alloc(e, cls_fit(2));\n  e.mem[n] = (u64)term_pak(chr, e.mem[l]);\n  e.mem[n + 1] = tail;\n  return term_ctr(con, n);\n}\n\n", "static u32 bend_str_eq(Env e, u32 scon, Term a, Term b) {\n  while (term_aux(a) == (u64)scon && term_aux(b) == (u64)scon) {\n    u64 la = term_peek(e.mem, a);\n    u64 lb = term_peek(e.mem, b);\n    if (e.mem[la] != e.mem[lb]) {\n      return 0;\n    }\n    a = e.mem[la + 1];\n    b = e.mem[lb + 1];\n  }\n  return term_aux(a) != (u64)scon && term_aux(b) != (u64)scon;\n}\n\n", "static Term bend_str_cmp(Env e, u32 scon, u32 tuple, u32 lt, u32 eq, u32 gt, Term a, Term b) {\n  Term x = a;\n  Term y = b;\n  u64 order = 1000000000ull;\n  while (term_aux(x) == (u64)scon && term_aux(y) == (u64)scon) {\n    u64 lx = term_peek(e.mem, x);\n    u64 ly = term_peek(e.mem, y);\n    if (e.mem[lx] != e.mem[ly]) {\n      order = e.mem[lx] < e.mem[ly] ? 0 : 2;\n      break;\n    }\n    x = e.mem[lx + 1];\n    y = e.mem[ly + 1];\n  }\n  if (order == 1000000000ull) {\n    u64 ex = term_aux(x) != (u64)scon;\n    u64 ey = term_aux(y) != (u64)scon;\n    order = ex && ey ? 1 : ex ? 2 : ey ? 0 : 1;\n  }\n  return bend_tuple(e, tuple, bend_tuple(e, tuple, a, b), term_pak(order == 0 ? lt : order == 1 ? eq : gt, 0));\n}\n\n", "static Term bend_map_bit(Env e, u32 scon, u32 tuple, u32 t, u32 f, Term key, Term pos) {\n  u64 at = 0;\n  u64 want = (u64)pos / 33ull;\n  u64 bit = (u64)pos % 33ull;\n  Term s = key;\n  while (term_aux(s) == (u64)scon && at < want) {\n    s = e.mem[term_peek(e.mem, s) + 1];\n    at += 1;\n  }\n  if (term_aux(s) != (u64)scon) {\n    return bend_tuple(e, tuple, key, term_pak(f, 0));\n  }\n  if (bit == 0) {\n    return bend_tuple(e, tuple, key, term_pak(t, 0));\n  }\n  u64 ch = e.mem[term_peek(e.mem, s)];\n  u64 set = (ch >> (32ull - bit)) & 1ull;\n  return bend_tuple(e, tuple, key, term_pak(set != 0 ? t : f, 0));\n}\n\n", "static Term bend_u32_to_word(Env e, u32 wcon, u32 wnil, Term x) {\n  Term w = term_pak(wnil, 0);\n  for (u32 i = 0; i < 32; i += 1) {\n    u64 l = heap_alloc(e, cls_fit(2));\n    e.mem[l] = ((u64)x >> i) & 1ull;\n    e.mem[l + 1] = w;\n    w = term_ctr(wcon, l);\n  }\n  return w;\n}\n\n", "static Term bend_array_new(Env e, Term v, Nat n) {\n  u64 d = 0;\n  u64 size = 1;\n  while (size < n && d < 31) {\n    size <<= 1;\n    d += 1;\n  }\n  Term one[1];\n  one[0] = v;\n  return blk_new(e, true, d, 0, 1, one);\n}\n\n", "static Term bend_array_set(Env e, Term a, Term i, Term v) {\n  u64 loc = term_peek(e.mem, a);\n  blk_write(e.mem, true, loc, blk_at(a, (u64)(u32)i, 0), v);\n  return a;\n}\n\n", "static Term bend_array_get(Env e, u32 tuple, Term a, Term i) {\n  u64 loc = term_peek(e.mem, a);\n  Term v = blk_read(e.mem, true, loc, blk_at(a, (u64)(u32)i, 0));\n  return bend_tuple(e, tuple, a, v);\n}\n\n", "static Term bend_array_swap(Env e, u32 tuple, Term a, Term i, Term v) {\n  u64 loc = term_peek(e.mem, a);\n  u32 ok = blk_at(a, (u64)(u32)i, 0);\n  Term old = blk_read(e.mem, true, loc, ok);\n  blk_write(e.mem, true, loc, ok, v);\n  return bend_tuple(e, tuple, a, old);\n}\n\n", "static Term bend_array_size(Env e, u32 tuple, Term a) {\n  return bend_tuple(e, tuple, a, 1ull << blk_cls(a));\n}\n\n", "static Term bend_array_clone(Env e, u32 tuple, Term a) {\n  return bend_tuple(e, tuple, a, blk_copy(e, a));\n}\n\n", "static Term bend_array_leaf(Env e, Term v) {\n  Term one[1];\n  one[0] = v;\n  return blk_new(e, true, 0, 0, 1, one);\n}\n\n", "static Term bend_array_leaf_value(Env e, Term a) {\n  return blk_read(e.mem, true, term_peek(e.mem, a), 0);\n}\n\n"])

def cps_provider_2_requests_part(v_1: cps_provider_2_Plan) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_Plan{v_24, v_25, v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44}:
      cps_provider_2_requests_finish(cps_provider_2_requests_check(v_39, v_40, v_35, v_33, v_24, v_28, v_29, v_30, v_31), v_43, v_44, v_35, v_28, v_29, v_30, v_31, v_27)

def native_match_cps_provider_2_requests_finish_0(v_31: Maybe<&2, List<&2, cps_provider_2_ExportRow>>, v_3: Bool, v_27: String) -> cps_provider_2_Part:
  match v_31:
    case None{}:
      cps_provider_2_PartFail{"a library export names no callable, or its checked parameter count disagrees with its entry"}
    case Some{v_30}:
      cps_provider_2_PartOk{String.concat([v_27, "static Term bend_text(Env e, const char* p, u64 n) {\n  return io_str(e, p, n);\n}\n", cps_provider_2_exports_c(v_3, v_30)])}

def native_match_cps_provider_2_requests_finish_1(v_1: cps_provider_2_Part, v_3: Bool, v_5: List<&2, BIR.Export>, +v_7: List<&2, BIR.Declaration>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>, +v_19: Map<&2, U32>, +v_22: List<&2, cps_provider_2_Entry>) -> cps_provider_2_Part:
  match v_1:
    case cps_provider_2_PartFail{v_25}:
      cps_provider_2_PartFail{v_25}
    case cps_provider_2_PartOk{v_27}:
      native_match_cps_provider_2_requests_finish_0(cps_provider_2_export_rows(v_5, v_7, v_10, v_13, v_16, v_19, v_22), v_3, v_27)

def cps_provider_2_requests_finish(v_1: cps_provider_2_Part, v_3: Bool, v_5: List<&2, BIR.Export>, +v_7: List<&2, BIR.Declaration>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>, +v_19: Map<&2, U32>, +v_22: List<&2, cps_provider_2_Entry>) -> cps_provider_2_Part:
  native_match_cps_provider_2_requests_finish_1(v_1, v_3, v_5, v_7, v_10, v_13, v_16, v_19, v_22)

def native_match_cps_provider_2_requests_check_0(v_29: Maybe<&2, String>, +v_2: List<&2, cps_provider_2_CImport>, +v_7: List<&2, BIR.Declaration>, v_9: List<&2, BIR.ConstructorLayout>, v_12: List<&2, cps_provider_2_CidRow>, v_15: Map<&2, U32>, v_18: Map<&2, U32>, v_21: Map<&2, U32>, v_24: Map<&2, U32>) -> cps_provider_2_Part:
  match v_29:
    case Some{v_28}:
      cps_provider_2_failp(cps_provider_2_cat(["no C import source was resolved for foreign `", v_28, "`; the adapter must pass the selected .c alternative"]))
    case None{}:
      cps_provider_2_requests_each(v_2, v_9, v_7, v_12, v_15, v_18, v_21, v_24)

def cps_provider_2_requests_check(+v_2: List<&2, cps_provider_2_CImport>, v_5: List<&2, String>, +v_7: List<&2, BIR.Declaration>, v_9: List<&2, BIR.ConstructorLayout>, v_12: List<&2, cps_provider_2_CidRow>, v_15: Map<&2, U32>, v_18: Map<&2, U32>, v_21: Map<&2, U32>, v_24: Map<&2, U32>) -> cps_provider_2_Part:
  native_match_cps_provider_2_requests_check_0(cps_provider_2_requests_uncovered(v_5, v_2, v_7), v_2, v_7, v_9, v_12, v_15, v_18, v_21, v_24)

def cps_provider_2_requests_uncovered(v_2: List<&2, String>, v_5: List<&2, cps_provider_2_CImport>, +v_7: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match v_2:
    case []:
      None{}
    case +v_12 <> v_13:
      cps_provider_2_requests_uncovered_one(cps_provider_2_foreign_namespace(v_12, v_7), v_12, v_13, v_5, v_7)

def native_match_cps_provider_2_foreign_namespace_0(v_9: Maybe<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match v_9:
    case Some{v_8}:
      cps_provider_2_foreign_namespace_item(v_8)
    case None{}:
      None{}

def cps_provider_2_foreign_namespace(v_1: String, v_3: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  native_match_cps_provider_2_foreign_namespace_0(cps_provider_2_find_declaration(v_1, v_3))

def cps_provider_2_foreign_namespace_item(v_0: BIR.Declaration) -> Maybe<&2, String>:
  match v_0:
    case BIR.ForeignDeclaration{_, v_13, _, _, _, _, _, _, _}:
      Some{v_13}
    case _:
      None{}

def native_match_cps_provider_2_requests_uncovered_one_0(v_17: Bool, +v_4: String, v_7: List<&2, String>, +v_10: List<&2, cps_provider_2_CImport>, v_12: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match v_17:
    case True{}:
      cps_provider_2_requests_uncovered(v_7, v_10, v_12)
    case False{}:
      Some{v_4}

def native_match_cps_provider_2_requests_uncovered_one_1(v_2: Maybe<&2, String>, +v_4: String, v_7: List<&2, String>, +v_10: List<&2, cps_provider_2_CImport>, v_12: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match v_2:
    case None{}:
      Some{v_4}
    case Some{v_16}:
      native_match_cps_provider_2_requests_uncovered_one_0(cps_provider_2_import_has_namespace(v_10, v_16), v_4, v_7, v_10, v_12)

def cps_provider_2_requests_uncovered_one(v_2: Maybe<&2, String>, +v_4: String, v_7: List<&2, String>, +v_10: List<&2, cps_provider_2_CImport>, v_12: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  native_match_cps_provider_2_requests_uncovered_one_1(v_2, v_4, v_7, v_10, v_12)

def cps_provider_2_import_has_namespace(v_2: List<&2, cps_provider_2_CImport>, +v_4: String) -> Bool:
  match v_2:
    case []:
      False{}
    case +v_8 <> v_9:
      match v_8:
        case cps_provider_2_CImport{_, v_14, _}:
          cps_provider_2_import_has_namespace_one(String.eq(v_14, v_4), v_9, v_4)

def cps_provider_2_import_has_namespace_one(v_1: Bool, v_4: List<&2, cps_provider_2_CImport>, v_6: String) -> Bool:
  match v_1:
    case True{}:
      True{}
    case False{}:
      cps_provider_2_import_has_namespace(v_4, v_6)

def cps_provider_2_requests_each(v_2: List<&2, cps_provider_2_CImport>, v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Declaration>, +v_9: List<&2, cps_provider_2_CidRow>, +v_12: Map<&2, U32>, +v_15: Map<&2, U32>, +v_18: Map<&2, U32>, +v_21: Map<&2, U32>) -> cps_provider_2_Part:
  match v_2:
    case []:
      cps_provider_2_okp("")
    case +v_26 <> v_27:
      match v_26:
        case cps_provider_2_CImport{v_31, v_32, v_33}:
          v_36 = cps_provider_2_cat(["/* effect source: ", v_31, " */\n", v_33, "\n"])
          cps_provider_2_part_join([cps_provider_2_rewrite_source(v_36, v_32, v_9, v_6, v_12, v_15, v_18, v_21), cps_provider_2_requests_each(v_27, v_4, v_6, v_9, v_12, v_15, v_18, v_21)])

def native_match_cps_provider_2_rewrite_source_0(v_38: Link.LinkResult) -> cps_provider_2_Part:
  match v_38:
    case Link.LinkSuccess{v_35}:
      cps_provider_2_PartOk{v_35}
    case Link.LinkFailure{v_37}:
      cps_provider_2_PartFail{v_37}

def cps_provider_2_rewrite_source(v_1: String, +v_3: String, +v_6: List<&2, cps_provider_2_CidRow>, +v_8: List<&2, BIR.Declaration>, v_11: Map<&2, U32>, v_14: Map<&2, U32>, v_17: Map<&2, U32>, v_20: Map<&2, U32>) -> cps_provider_2_Part:
  v_26 = cps_provider_2_namespaced_map(cps_provider_2_cid_exact_map(v_6), cps_provider_2_cid_keys(v_6), v_3)
  v_29 = cps_provider_2_fid_exact_map(v_8, v_11, v_14, v_17, v_20)
  v_33 = cps_provider_2_namespaced_map(v_29, cps_provider_2_fid_keys(v_8), v_3)
  native_match_cps_provider_2_rewrite_source_0(Link.rewrite(v_1, v_26, v_33))

def cps_provider_2_cid_keys(v_2: List<&2, cps_provider_2_CidRow>) -> List<&2, String>:
  match v_2:
    case []:
      []
    case +v_7 <> v_8:
      match v_7:
        case cps_provider_2_CidRow{_, v_14, _, _}:
          v_14 <> cps_provider_2_cid_keys(v_8)

def cps_provider_2_fid_keys(v_1: List<&2, BIR.Declaration>) -> List<&2, String>:
  match v_1:
    case []:
      []
    case +v_6 <> v_7:
      match v_6:
        case BIR.FunctionDeclaration{v_11, _, _}:
          v_11 <> cps_provider_2_fid_keys(v_7)
        case BIR.LazyDeclaration{v_17, _}:
          v_17 <> cps_provider_2_fid_keys(v_7)
        case BIR.ForeignDeclaration{v_29, _, _, _, _, _, _, _, _}:
          v_29 <> cps_provider_2_fid_keys(v_7)
        case BIR.NativeDeclaration{v_42, _, _}:
          v_42 <> cps_provider_2_fid_keys(v_7)
        case _:
          cps_provider_2_fid_keys(v_7)

def native_match_cps_provider_2_insert_section_0(v_14: Bool, +v_4: String, +v_6: String, +v_12: String, v_13: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match v_14:
    case True{}:
      cps_provider_2_insert_rule(v_13, v_12, v_6)
    case False{}:
      cps_provider_2_insert_prefix(cps_provider_2_insert_section(v_13, v_4, v_6), v_12)

def native_match_cps_provider_2_insert_section_1(v_2: List<&2, String>, +v_4: String, +v_6: String) -> Maybe<&2, List<&2, String>>:
  match v_2:
    case []:
      None{}
    case +v_12 <> v_13:
      native_match_cps_provider_2_insert_section_0(String.eq(v_12, v_4), v_4, v_6, v_12, v_13)

def cps_provider_2_insert_section(v_2: List<&2, String>, +v_4: String, +v_6: String) -> Maybe<&2, List<&2, String>>:
  native_match_cps_provider_2_insert_section_1(v_2, v_4, v_6)

def native_match_cps_provider_2_insert_rule_0(v_14: Bool, v_4: String, v_6: String, +v_12: String, v_13: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match v_14:
    case True{}:
      Some{v_4 <> v_12 <> "" <> v_6 <> "" <> v_13}
    case False{}:
      None{}

def native_match_cps_provider_2_insert_rule_1(v_2: List<&2, String>, v_4: String, v_6: String) -> Maybe<&2, List<&2, String>>:
  match v_2:
    case []:
      None{}
    case +v_12 <> v_13:
      native_match_cps_provider_2_insert_rule_0(String.starts_with(v_12, "// ==="), v_4, v_6, v_12, v_13)

def cps_provider_2_insert_rule(v_2: List<&2, String>, v_4: String, v_6: String) -> Maybe<&2, List<&2, String>>:
  native_match_cps_provider_2_insert_rule_1(v_2, v_4, v_6)

def cps_provider_2_insert_prefix(v_3: Maybe<&2, List<&2, String>>, v_5: String) -> Maybe<&2, List<&2, String>>:
  match v_3:
    case None{}:
      None{}
    case Some{v_10}:
      Some{v_5 <> v_10}

def native_match_cps_provider_2_assemble_0(v_15: Maybe<&2, List<&2, String>>, v_5: String, v_7: String, v_9: String) -> Maybe<&2, String>:
  match v_15:
    case None{}:
      None{}
    case Some{v_14}:
      cps_provider_2_assemble_spins(v_14, v_5, v_7, v_9)

def cps_provider_2_assemble(v_1: String, v_3: String, v_5: String, v_7: String, v_9: String) -> Maybe<&2, String>:
  native_match_cps_provider_2_assemble_0(cps_provider_2_insert_section(String.split(v_1, '\n'), "// Tables", v_3), v_5, v_7, v_9)

def native_match_cps_provider_2_assemble_spins_0(v_14: Maybe<&2, List<&2, String>>, v_6: String, v_8: String) -> Maybe<&2, String>:
  match v_14:
    case None{}:
      None{}
    case Some{v_13}:
      cps_provider_2_assemble_segments(v_13, v_6, v_8)

def cps_provider_2_assemble_spins(v_2: List<&2, String>, v_4: String, v_6: String, v_8: String) -> Maybe<&2, String>:
  native_match_cps_provider_2_assemble_spins_0(cps_provider_2_insert_section(v_2, "// Spins", v_4), v_6, v_8)

def native_match_cps_provider_2_assemble_segments_0(v_12: Maybe<&2, List<&2, String>>, v_6: String) -> Maybe<&2, String>:
  match v_12:
    case None{}:
      None{}
    case Some{v_11}:
      cps_provider_2_assemble_requests(v_11, v_6)

def cps_provider_2_assemble_segments(v_2: List<&2, String>, v_4: String, v_6: String) -> Maybe<&2, String>:
  native_match_cps_provider_2_assemble_segments_0(cps_provider_2_insert_section(v_2, "// Segments", v_4), v_6)

def native_match_cps_provider_2_assemble_requests_0(v_10: Maybe<&2, List<&2, String>>) -> Maybe<&2, String>:
  match v_10:
    case None{}:
      None{}
    case Some{v_9}:
      Some{String.join(v_9, "\n")}

def cps_provider_2_assemble_requests(v_2: List<&2, String>, v_4: String) -> Maybe<&2, String>:
  native_match_cps_provider_2_assemble_requests_0(cps_provider_2_insert_section(v_2, "// Requests", v_4))

def cps_provider_2_cid_exact_map(v_2: List<&2, cps_provider_2_CidRow>) -> Map<&2, String>:
  cps_provider_2_cid_exact_each(v_2, Map.new(&2, String))

def cps_provider_2_cid_exact_each(v_2: List<&2, cps_provider_2_CidRow>, +v_5: Map<&2, String>) -> Map<&2, String>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      match v_10:
        case cps_provider_2_CidRow{v_16, v_17, _, _}:
          cps_provider_2_cid_exact_each(v_11, Map.set(&2, String, v_5, v_17, cps_provider_2_cid_symbol(v_16)))

def cps_provider_2_fid_exact_map(v_1: List<&2, BIR.Declaration>, v_4: Map<&2, U32>, v_7: Map<&2, U32>, v_10: Map<&2, U32>, v_13: Map<&2, U32>) -> Map<&2, String>:
  cps_provider_2_fid_exact_decl(v_1, cps_provider_2_fid_fixed(Map.new(&2, String)), v_4, v_7, v_10, v_13)

def cps_provider_2_namespaced_map(v_2: Map<&2, String>, v_5: List<&2, String>, v_7: String) -> Map<&2, String>:
  cps_provider_2_namespaced_each(v_2, v_5, v_7)

def native_match_cps_provider_2_namespaced_each_0(v_14: Bool, +v_2: Map<&2, String>, +v_7: String, +v_12: String, v_13: List<&2, String>) -> Map<&2, String>:
  match v_14:
    case True{}:
      cps_provider_2_namespaced_each(cps_provider_2_namespaced_set(v_2, v_12, v_7), v_13, v_7)
    case False{}:
      cps_provider_2_namespaced_each(v_2, v_13, v_7)

def native_match_cps_provider_2_namespaced_each_1(v_5: List<&2, String>, +v_2: Map<&2, String>, +v_7: String) -> Map<&2, String>:
  match v_5:
    case []:
      v_2
    case +v_12 <> v_13:
      native_match_cps_provider_2_namespaced_each_0(Bool.not(String.is_empty(v_7)), v_2, v_7, v_12, v_13)

def cps_provider_2_namespaced_each(+v_2: Map<&2, String>, v_5: List<&2, String>, +v_7: String) -> Map<&2, String>:
  native_match_cps_provider_2_namespaced_each_1(v_5, v_2, v_7)

def native_match_cps_provider_2_namespaced_set_0(v_12: Maybe<&2, String>, +v_2: Map<&2, String>, +v_4: String, v_6: String) -> Map<&2, String>:
  match v_12:
    case Some{v_11}:
      cps_provider_2_map_set_first(v_2, String.append(v_6, String.append(":", v_4)), v_11)
    case None{}:
      v_2

def cps_provider_2_namespaced_set(+v_2: Map<&2, String>, +v_4: String, v_6: String) -> Map<&2, String>:
  native_match_cps_provider_2_namespaced_set_0(IndexLookup.find(String, v_2, v_4), v_2, v_4, v_6)

def cps_provider_2_fid_fixed(v_2: Map<&2, String>) -> Map<&2, String>:
  cps_provider_2_fid_fixed_one(cps_provider_2_map_set_first(v_2, "Clo~apply", "FID_CLO_APPLY"))

def cps_provider_2_fid_fixed_one(v_2: Map<&2, String>) -> Map<&2, String>:
  cps_provider_2_map_set_first(v_2, "IO~emit", "FID_IO_EMIT")

def native_match_cps_provider_2_fid_exact_decl_0(v_78: Maybe<&2, U32>, +v_4: Map<&2, String>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>, v_22: List<&2, BIR.Declaration>, +v_66: String) -> Map<&2, String>:
  match v_78:
    case Some{v_71}:
      cps_provider_2_fid_exact_decl(v_22, cps_provider_2_map_set_first(v_4, v_66, cps_provider_2_fid_symbol(v_71)), v_7, v_10, v_13, v_16)
    case None{}:
      cps_provider_2_fid_exact_decl(v_22, v_4, v_7, v_10, v_13, v_16)

def native_match_cps_provider_2_fid_exact_decl_1(+v_21: BIR.Declaration, +v_4: Map<&2, String>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>, v_22: List<&2, BIR.Declaration>) -> Map<&2, String>:
  match v_21:
    case BIR.FunctionDeclaration{v_26, v_27, v_28}:
      cps_provider_2_fid_exact_decl(v_22, cps_provider_2_map_set_first(v_4, v_26, cps_provider_2_fid_symbol(cps_provider_2_map_u32(v_7, U32.show(v_27)))), v_7, v_10, v_13, v_16)
    case BIR.LazyDeclaration{+v_35, v_36}:
      cps_provider_2_fid_exact_decl(v_22, cps_provider_2_map_set_first(v_4, v_35, cps_provider_2_fid_symbol(cps_provider_2_map_u32(v_10, v_35))), v_7, v_10, v_13, v_16)
    case BIR.ForeignDeclaration{+v_50, v_51, v_52, v_53, v_54, v_55, v_56, v_57, v_58}:
      cps_provider_2_fid_exact_decl(v_22, cps_provider_2_map_set_first(v_4, v_50, cps_provider_2_fid_symbol(cps_provider_2_map_u32(v_13, v_50))), v_7, v_10, v_13, v_16)
    case BIR.NativeDeclaration{+v_66, v_67, v_68}:
      native_match_cps_provider_2_fid_exact_decl_0(IndexLookup.find(U32, v_16, v_66), v_4, v_7, v_10, v_13, v_16, v_22, v_66)
    case _:
      cps_provider_2_fid_exact_decl(v_22, v_4, v_7, v_10, v_13, v_16)

def native_match_cps_provider_2_fid_exact_decl_2(v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, String>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>) -> Map<&2, String>:
  match v_1:
    case []:
      v_4
    case +v_21 <> v_22:
      native_match_cps_provider_2_fid_exact_decl_1(v_21, v_4, v_7, v_10, v_13, v_16, v_22)

def cps_provider_2_fid_exact_decl(v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, String>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>) -> Map<&2, String>:
  native_match_cps_provider_2_fid_exact_decl_2(v_1, v_4, v_7, v_10, v_13, v_16)

def cps_provider_2_macro_collision_cids(v_2: List<&2, cps_provider_2_CidRow>) -> Maybe<&2, String>:
  cps_provider_2_macro_collision_rows(v_2, Map.new(&2, String))

def cps_provider_2_macro_collision_rows(+v_2: List<&2, cps_provider_2_CidRow>, v_5: Map<&2, String>) -> Maybe<&2, String>:
  match v_2:
    case []:
      None{}
    case +v_10 <> v_11:
      match v_10:
        case cps_provider_2_CidRow{v_16, v_17, _, _}:
          cps_provider_2_macro_collision_one(v_17, cps_provider_2_cid_symbol(v_16), v_2, v_5, v_11)

def native_match_cps_provider_2_macro_collision_one_0(v_23: Bool, +v_1: String, +v_3: String, +v_9: Map<&2, String>, +v_12: List<&2, cps_provider_2_CidRow>, +v_17: String) -> Maybe<&2, String>:
  match v_23:
    case True{}:
      cps_provider_2_macro_collision_rows(v_12, v_9)
    case False{}:
      Some{cps_provider_2_cat(["constructor keys `", v_17, "` and `", v_1, "` both sanitize to macro ", v_3])}

def native_match_cps_provider_2_macro_collision_one_1(v_22: Maybe<&2, String>, +v_1: String, +v_3: String, +v_9: Map<&2, String>, +v_12: List<&2, cps_provider_2_CidRow>) -> Maybe<&2, String>:
  match v_22:
    case Some{+v_17}:
      native_match_cps_provider_2_macro_collision_one_0(String.eq(v_17, v_1), v_1, v_3, v_9, v_12, v_17)
    case None{}:
      cps_provider_2_macro_collision_rows(v_12, Map.set(&2, String, v_9, v_3, v_1))

def cps_provider_2_macro_collision_one(+v_1: String, +v_3: String, v_6: List<&2, cps_provider_2_CidRow>, +v_9: Map<&2, String>, +v_12: List<&2, cps_provider_2_CidRow>) -> Maybe<&2, String>:
  native_match_cps_provider_2_macro_collision_one_1(IndexLookup.find(String, v_9, v_3), v_1, v_3, v_9, v_12)

def native_match_cps_provider_2_emit_0(v_12: cps_provider_2_PlanResult, v_2: String) -> cps_provider_2_EmitResult:
  match v_12:
    case cps_provider_2_PlanFail{v_9}:
      cps_provider_2_EmitFailure{v_9}
    case cps_provider_2_PlanOk{v_11}:
      cps_provider_2_render(v_11, v_2)

def cps_provider_2_emit(v_0: BIR.Program, v_2: String, v_5: List<&2, cps_provider_2_CImport>) -> cps_provider_2_EmitResult:
  native_match_cps_provider_2_emit_0(cps_provider_2_plan_make(v_0, v_5), v_2)

def native_match_cps_provider_2_render_0(v_50: Maybe<&2, String>, +v_1: cps_provider_2_Plan, v_3: String, +v_26: List<&2, cps_provider_2_CidRow>, v_30: Map<&2, U32>, v_31: Map<&2, U32>, v_32: Map<&2, U32>, v_33: Map<&2, U32>, v_37: List<&2, BIR.Declaration>) -> cps_provider_2_EmitResult:
  match v_50:
    case Some{v_49}:
      cps_provider_2_EmitFailure{v_49}
    case None{}:
      cps_provider_2_render_parts(v_1, v_3, cps_provider_2_cid_exact_map(v_26), cps_provider_2_fid_exact_map(v_37, v_30, v_31, v_32, v_33))

def native_match_cps_provider_2_render_1(+v_1: cps_provider_2_Plan, v_3: String) -> cps_provider_2_EmitResult:
  match v_1:
    case cps_provider_2_Plan{+v_26, v_27, v_28, v_29, v_30, v_31, v_32, v_33, v_34, v_35, v_36, v_37, v_38, v_39, v_40, v_41, v_42, v_43, v_44, _, _}:
      native_match_cps_provider_2_render_0(cps_provider_2_macro_collision_cids(v_26), v_1, v_3, v_26, v_30, v_31, v_32, v_33, v_37)

def cps_provider_2_render(+v_1: cps_provider_2_Plan, v_3: String) -> cps_provider_2_EmitResult:
  native_match_cps_provider_2_render_1(v_1, v_3)

def native_match_cps_provider_2_render_parts_0(v_52: cps_provider_2_Part, v_53: cps_provider_2_Part, v_54: cps_provider_2_Part, v_3: String, v_6: Map<&2, String>, v_9: Map<&2, String>, v_17: String) -> cps_provider_2_EmitResult:
  match v_52, v_53, v_54:
    case cps_provider_2_PartFail{v_29}, _, _:
      cps_provider_2_EmitFailure{v_29}
    case _, cps_provider_2_PartFail{v_36}, _:
      cps_provider_2_EmitFailure{v_36}
    case _, _, cps_provider_2_PartFail{v_43}:
      cps_provider_2_EmitFailure{v_43}
    case cps_provider_2_PartOk{v_47}, cps_provider_2_PartOk{v_48}, cps_provider_2_PartOk{v_49}:
      cps_provider_2_render_assemble(v_3, v_47, v_48, cps_provider_2_segments_text(v_17), v_49, v_6, v_9)

def native_match_cps_provider_2_render_parts_1(v_51: Maybe<&2, String>, +v_1: cps_provider_2_Plan, v_3: String, v_6: Map<&2, String>, v_9: Map<&2, String>, v_17: String, +v_18: List<&2, cps_provider_2_SegText>, v_19: Nat) -> cps_provider_2_EmitResult:
  match v_51:
    case Some{v_22}:
      cps_provider_2_EmitFailure{v_22}
    case None{}:
      native_match_cps_provider_2_render_parts_0(cps_provider_2_tables_part(v_1, v_18, v_19), cps_provider_2_spins_part, cps_provider_2_requests_part(v_1), v_3, v_6, v_9, v_17)

def native_match_cps_provider_2_render_parts_2(v_50: cps_provider_2_Control, +v_1: cps_provider_2_Plan, v_3: String, v_6: Map<&2, String>, v_9: Map<&2, String>) -> cps_provider_2_EmitResult:
  match v_50:
    case cps_provider_2_ControlFail{v_13}:
      cps_provider_2_EmitFailure{v_13}
    case cps_provider_2_ControlOk{v_17, +v_18, v_19}:
      native_match_cps_provider_2_render_parts_1(cps_provider_2_rows_check(v_18), v_1, v_3, v_6, v_9, v_17, v_18, v_19)

def cps_provider_2_render_parts(+v_1: cps_provider_2_Plan, v_3: String, v_6: Map<&2, String>, v_9: Map<&2, String>) -> cps_provider_2_EmitResult:
  native_match_cps_provider_2_render_parts_2(cps_provider_2_control_build(v_1), v_1, v_3, v_6, v_9)

def cps_provider_2_segments_text(v_1: String) -> String:
  String.concat(["#if !DEVICE\n", v_1, "#endif\n"])

def native_match_cps_provider_2_render_assemble_0(v_20: Maybe<&2, String>, v_12: Map<&2, String>, v_15: Map<&2, String>) -> cps_provider_2_EmitResult:
  match v_20:
    case None{}:
      cps_provider_2_EmitFailure{"the runtime source is missing one of the // Tables, // Spins, // Segments or // Requests sections"}
    case Some{v_19}:
      cps_provider_2_render_rewrite(v_19, v_12, v_15)

def cps_provider_2_render_assemble(v_1: String, v_3: String, v_5: String, v_7: String, v_9: String, v_12: Map<&2, String>, v_15: Map<&2, String>) -> cps_provider_2_EmitResult:
  native_match_cps_provider_2_render_assemble_0(cps_provider_2_assemble(v_1, v_3, v_5, v_7, v_9), v_12, v_15)

def native_match_cps_provider_2_render_rewrite_0(v_13: Link.LinkResult) -> cps_provider_2_EmitResult:
  match v_13:
    case Link.LinkSuccess{v_10}:
      cps_provider_2_EmitSuccess{v_10}
    case Link.LinkFailure{v_12}:
      cps_provider_2_EmitFailure{v_12}

def cps_provider_2_render_rewrite(v_1: String, v_4: Map<&2, String>, v_7: Map<&2, String>) -> cps_provider_2_EmitResult:
  native_match_cps_provider_2_render_rewrite_0(Link.rewrite(v_1, v_4, v_7))

def cps_provider_3_family_index(v_1: List<&2, BIR.Family>) -> Map<&2, BIR.Family>:
  match v_1:
    case []:
      Map.new(&2, BIR.Family)
    case +v_5 <> v_6:
      match v_5:
        case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
          Map.set(&2, BIR.Family, cps_provider_3_family_index(v_6), v_13, v_5)

def cps_provider_3_function_index(v_1: List<&2, BIR.TypeFunction>) -> Map<&2, BIR.TypeFunction>:
  match v_1:
    case []:
      Map.new(&2, BIR.TypeFunction)
    case +v_5 <> v_6:
      match v_5:
        case BIR.TypeFunction{v_12, v_13, v_14, v_15, v_16}:
          Map.set(&2, BIR.TypeFunction, cps_provider_3_function_index(v_6), v_12, v_5)

def cps_provider_3_nf_context(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>) -> cps_provider_3_NfContext:
  cps_provider_3_NfContext{cps_provider_3_family_index(v_1), cps_provider_3_function_index(v_3)}

def cps_provider_3_default_fuel() -> Nat:
  1024n

def cps_provider_3_family_of(+v_1: String, +v_3: Map<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  IndexLookup.find(BIR.Family, v_3, v_1)

def cps_provider_3_function_of(+v_1: String, +v_3: Map<&2, BIR.TypeFunction>) -> Maybe<&2, BIR.TypeFunction>:
  IndexLookup.find(BIR.TypeFunction, v_3, v_1)

def native_match_cps_provider_3_native_of_0(v_10: BIR.Family) -> Maybe<&2, String>:
  match v_10:
    case BIR.Family{v_17, v_18, v_19, v_20, v_21, v_22}:
      v_19

def native_match_cps_provider_3_native_of_1(v_25: BIR.TypeFunction) -> Maybe<&2, String>:
  match v_25:
    case BIR.TypeFunction{v_31, v_32, v_33, v_34, v_35}:
      v_32

def native_match_cps_provider_3_native_of_2(v_37: Maybe<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_37:
    case Some{v_25}:
      native_match_cps_provider_3_native_of_1(v_25)
    case None{}:
      None{}

def native_match_cps_provider_3_native_of_3(v_36: Maybe<&2, BIR.Family>, +v_1: String, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  match v_36:
    case Some{v_10}:
      native_match_cps_provider_3_native_of_0(v_10)
    case None{}:
      native_match_cps_provider_3_native_of_2(cps_provider_3_function_of(v_1, v_5))

def cps_provider_3_native_of(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Maybe<&2, String>:
  native_match_cps_provider_3_native_of_3(cps_provider_3_family_of(v_1, v_3), v_1, v_5)

def cps_provider_3_val_nth(+v_2: List<&2, cps_provider_3_NfVal>, v_4: Nat) -> cps_provider_3_NfVal:
  match v_2, v_4:
    case +v_8 <> v_9, 0n:
      v_8
    case +v_13 <> v_14, 1n+v_15:
      cps_provider_3_val_nth(v_14, v_15)
    case _, _:
      cps_provider_3_NfMissing{BIR.DescriptorNull{}}

def cps_provider_3_val_at(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_5: BIR.Descriptor) -> cps_provider_3_NfVal:
  cps_provider_3_val_at_choose(Nat.is_lt(v_4, List.length(&2, cps_provider_3_NfVal, v_2)), v_2, v_4, v_5)

def cps_provider_3_val_at_choose(v_1: Bool, +v_4: List<&2, cps_provider_3_NfVal>, +v_6: Nat, v_7: BIR.Descriptor) -> cps_provider_3_NfVal:
  match v_1:
    case True{}:
      cps_provider_3_val_nth(v_4, Nat.sub(Nat.sub(List.length(&2, cps_provider_3_NfVal, v_4), 1n), v_6))
    case False{}:
      cps_provider_3_NfMissing{v_7}

def cps_provider_3_first_vals(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> List<&2, cps_provider_3_NfVal>:
  match v_2, v_4:
    case _, 0n:
      []
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      v_14 <> cps_provider_3_first_vals(v_15, v_16)

def cps_provider_3_drop_vals(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat) -> List<&2, cps_provider_3_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_2
    case [], _:
      []
    case +v_14 <> v_15, 1n+v_16:
      cps_provider_3_drop_vals(v_15, v_16)

def cps_provider_3_insert_before(v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, v_6: cps_provider_3_NfVal) -> List<&2, cps_provider_3_NfVal>:
  match v_2, v_4:
    case _, 0n:
      v_6 <> v_2
    case [], 1n+v_12:
      cps_provider_3_insert_before([], v_12, v_6)
    case +v_17 <> v_18, 1n+v_19:
      v_17 <> cps_provider_3_insert_before(v_18, v_19, v_6)

def cps_provider_3_append_vals(v_2: List<&2, cps_provider_3_NfVal>, v_5: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  match v_2:
    case []:
      v_5
    case +v_10 <> v_11:
      v_10 <> cps_provider_3_append_vals(v_11, v_5)

def cps_provider_3_quantity_markers(v_1: Nat) -> List<&2, cps_provider_3_NfVal>:
  match v_1:
    case 0n:
      []
    case 1n+v_5:
      cps_provider_3_NfQuantity{BIR.Erased{}} <> cps_provider_3_quantity_markers(v_5)

def cps_provider_3_materialize_all(v_2: List<&2, cps_provider_3_NfVal>) -> List<&2, BIR.Descriptor>:
  match v_2:
    case []:
      []
    case +v_6 <> v_7:
      match v_6:
        case cps_provider_3_NfType{v_10, v_11}:
          BIR.DescriptorRef{v_10, cps_provider_3_materialize_all(v_11)} <> cps_provider_3_materialize_all(v_7)
        case cps_provider_3_NfCtor{v_16, v_17}:
          BIR.DescriptorConstructor{v_16, cps_provider_3_materialize_all(v_17)} <> cps_provider_3_materialize_all(v_7)
        case cps_provider_3_NfQuantity{v_21}:
          BIR.DescriptorQuantity{v_21} <> cps_provider_3_materialize_all(v_7)
        case cps_provider_3_NfKind{v_24}:
          BIR.DescriptorKind{v_24} <> cps_provider_3_materialize_all(v_7)
        case cps_provider_3_NfOther{v_27}:
          v_27 <> cps_provider_3_materialize_all(v_7)
        case cps_provider_3_NfMissing{v_30}:
          v_30 <> cps_provider_3_materialize_all(v_7)
        case cps_provider_3_NfClosure{v_36, v_37, v_38, v_39}:
          BIR.DescriptorLet{v_39, BIR.DescriptorLambda{v_36, v_37}} <> cps_provider_3_materialize_all(v_7)

def cps_provider_3_materialize(v_1: cps_provider_3_NfVal) -> BIR.Descriptor:
  match v_1:
    case cps_provider_3_NfType{v_4, v_5}:
      BIR.DescriptorRef{v_4, cps_provider_3_materialize_all(v_5)}
    case cps_provider_3_NfCtor{v_9, v_10}:
      BIR.DescriptorConstructor{v_9, cps_provider_3_materialize_all(v_10)}
    case cps_provider_3_NfQuantity{v_13}:
      BIR.DescriptorQuantity{v_13}
    case cps_provider_3_NfKind{v_15}:
      BIR.DescriptorKind{v_15}
    case cps_provider_3_NfOther{v_17}:
      v_17
    case cps_provider_3_NfMissing{v_19}:
      v_19
    case cps_provider_3_NfClosure{v_24, v_25, v_26, v_27}:
      BIR.DescriptorLet{v_27, BIR.DescriptorLambda{v_24, v_25}}

def cps_provider_3_reify_env(v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_3_NfVal>) -> BIR.Descriptor:
  match v_3:
    case []:
      v_0
    case +v_6 <> v_7:
      BIR.DescriptorLet{cps_provider_3_materialize_all(v_3), v_0}

def cps_provider_3_status_combine(v_1: cps_provider_3_NfStatus, v_3: cps_provider_3_NfStatus) -> cps_provider_3_NfStatus:
  match v_1:
    case cps_provider_3_NfStatusNo{}:
      cps_provider_3_NfStatusNo{}
    case cps_provider_3_NfStatusMaybe{}:
      match v_3:
        case cps_provider_3_NfStatusNo{}:
          cps_provider_3_NfStatusNo{}
        case _:
          cps_provider_3_NfStatusMaybe{}
    case cps_provider_3_NfStatusOk{}:
      v_3

def native_match_cps_provider_3_bind_status_0(v_42: Bool, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_3_NfVal>, v_20: List<&2, BIR.DescriptorPattern>, v_24: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  match v_42:
    case False{}:
      cps_provider_3_NfStatusNo{}
    case True{}:
      cps_provider_3_status_combine(cps_provider_3_bind_status(v_20, v_24), cps_provider_3_bind_status(v_11, v_13))

def native_match_cps_provider_3_bind_status_1(+v_12: cps_provider_3_NfVal, v_11: List<&2, BIR.DescriptorPattern>, v_13: List<&2, cps_provider_3_NfVal>, v_19: String, v_20: List<&2, BIR.DescriptorPattern>) -> cps_provider_3_NfStatus:
  match v_12:
    case cps_provider_3_NfCtor{v_23, v_24}:
      native_match_cps_provider_3_bind_status_0(String.eq(v_19, v_23), v_11, v_13, v_20, v_24)
    case cps_provider_3_NfMissing{v_29}:
      cps_provider_3_status_combine(cps_provider_3_NfStatusMaybe{}, cps_provider_3_bind_status(v_11, v_13))
    case cps_provider_3_NfOther{v_33}:
      cps_provider_3_status_combine(cps_provider_3_NfStatusMaybe{}, cps_provider_3_bind_status(v_11, v_13))
    case _:
      cps_provider_3_NfStatusNo{}

def native_match_cps_provider_3_bind_status_2(+v_10: BIR.DescriptorPattern, v_11: List<&2, BIR.DescriptorPattern>, +v_12: cps_provider_3_NfVal, v_13: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  match v_10:
    case BIR.DescriptorBinder{v_15}:
      cps_provider_3_bind_status(v_11, v_13)
    case BIR.DescriptorConstructorPattern{v_19, v_20}:
      native_match_cps_provider_3_bind_status_1(v_12, v_11, v_13, v_19, v_20)

def native_match_cps_provider_3_bind_status_3(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  match v_1, v_4:
    case [], []:
      cps_provider_3_NfStatusOk{}
    case +v_10 <> v_11, +v_12 <> v_13:
      native_match_cps_provider_3_bind_status_2(v_10, v_11, v_12, v_13)
    case _, _:
      cps_provider_3_NfStatusNo{}

def cps_provider_3_bind_status(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfStatus:
  native_match_cps_provider_3_bind_status_3(v_1, v_4)

def native_match_cps_provider_3_bind_values_0(+v_13: cps_provider_3_NfVal, v_12: List<&2, BIR.DescriptorPattern>, v_14: List<&2, cps_provider_3_NfVal>, v_21: List<&2, BIR.DescriptorPattern>) -> List<&2, cps_provider_3_NfVal>:
  match v_13:
    case cps_provider_3_NfCtor{v_24, v_25}:
      cps_provider_3_append_vals(cps_provider_3_bind_values(v_21, v_25), cps_provider_3_bind_values(v_12, v_14))
    case _:
      cps_provider_3_bind_values(v_12, v_14)

def native_match_cps_provider_3_bind_values_1(+v_11: BIR.DescriptorPattern, v_12: List<&2, BIR.DescriptorPattern>, +v_13: cps_provider_3_NfVal, v_14: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  match v_11:
    case BIR.DescriptorBinder{v_16}:
      v_13 <> cps_provider_3_bind_values(v_12, v_14)
    case BIR.DescriptorConstructorPattern{v_20, v_21}:
      native_match_cps_provider_3_bind_values_0(v_13, v_12, v_14, v_21)

def native_match_cps_provider_3_bind_values_2(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  match v_1, v_4:
    case [], []:
      []
    case +v_11 <> v_12, +v_13 <> v_14:
      native_match_cps_provider_3_bind_values_1(v_11, v_12, v_13, v_14)
    case _, _:
      []

def cps_provider_3_bind_values(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> List<&2, cps_provider_3_NfVal>:
  native_match_cps_provider_3_bind_values_2(v_1, v_4)

def native_match_cps_provider_3_bind_patterns_0(v_5: cps_provider_3_NfStatus, v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfBind:
  match v_5:
    case cps_provider_3_NfStatusOk{}:
      cps_provider_3_NfBound{cps_provider_3_bind_values(v_1, v_4)}
    case cps_provider_3_NfStatusNo{}:
      cps_provider_3_NfMismatch{}
    case cps_provider_3_NfStatusMaybe{}:
      cps_provider_3_NfUnknown{}

def cps_provider_3_bind_patterns(v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_NfBind:
  native_match_cps_provider_3_bind_patterns_0(cps_provider_3_bind_status(v_1, v_4), v_1, v_4)

def native_match_cps_provider_3_nf_0(v_8: Bool, +v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_3_Nf:
  match v_8:
    case True{}:
      cps_provider_3_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_3_nf_descriptor(v_1, v_2, v_5, Nat.sub(v_7, 1n))

def cps_provider_3_nf(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_0(Nat.is_eq(v_7, 0n), v_1, v_2, v_5, v_7)

def native_match_cps_provider_3_nf_descriptor_0(v_8: Bool, +v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_3_Nf:
  match v_8:
    case True{}:
      cps_provider_3_NfFail{"the type expression did not normalize within its reduction budget"}
    case False{}:
      cps_provider_3_nf_descriptor_step(v_1, v_2, v_5, v_7)

def cps_provider_3_nf_descriptor(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_descriptor_0(Nat.is_eq(v_7, 0n), v_1, v_2, v_5, v_7)

def native_match_cps_provider_3_nf_arrow_0(v_22: cps_provider_3_Nf, v_2: BIR.Quantity, v_15: cps_provider_3_NfVal) -> cps_provider_3_Nf:
  match v_22:
    case cps_provider_3_NfFail{v_18}:
      cps_provider_3_NfFail{v_18}
    case cps_provider_3_NfOk{v_20}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{BIR.DescriptorArrow{v_2, cps_provider_3_materialize(v_15), cps_provider_3_materialize(v_20)}}}

def native_match_cps_provider_3_nf_arrow_1(v_21: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_2: BIR.Quantity, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat) -> cps_provider_3_Nf:
  match v_21:
    case cps_provider_3_NfFail{v_13}:
      cps_provider_3_NfFail{v_13}
    case cps_provider_3_NfOk{v_15}:
      native_match_cps_provider_3_nf_arrow_0(cps_provider_3_nf(v_1, v_4, v_7, v_9), v_2, v_15)

def cps_provider_3_nf_arrow(+v_1: cps_provider_3_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_arrow_1(cps_provider_3_nf(v_1, v_3, v_7, v_9), v_1, v_2, v_4, v_7, v_9)

def native_match_cps_provider_3_nf_descriptor_step_0(v_191: cps_provider_3_Nf) -> cps_provider_3_Nf:
  match v_191:
    case cps_provider_3_NfOk{v_22}:
      cps_provider_3_NfOk{cps_provider_3_NfKind{cps_provider_3_materialize(v_22)}}
    case cps_provider_3_NfFail{v_25}:
      cps_provider_3_NfFail{v_25}

def native_match_cps_provider_3_nf_descriptor_step_1(v_192: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_7: Nat, v_45: String) -> cps_provider_3_Nf:
  match v_192:
    case cps_provider_3_NfListOk{v_49}:
      cps_provider_3_nf_named(v_1, v_45, v_49, v_7)
    case cps_provider_3_NfListFail{v_52}:
      cps_provider_3_NfFail{v_52}

def native_match_cps_provider_3_nf_descriptor_step_2(v_193: cps_provider_3_NfList, v_55: String) -> cps_provider_3_Nf:
  match v_193:
    case cps_provider_3_NfListOk{v_59}:
      cps_provider_3_NfOk{cps_provider_3_NfCtor{v_55, v_59}}
    case cps_provider_3_NfListFail{v_61}:
      cps_provider_3_NfFail{v_61}

def native_match_cps_provider_3_nf_descriptor_step_3(v_195: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_7: Nat, v_68: cps_provider_3_NfVal) -> cps_provider_3_Nf:
  match v_195:
    case cps_provider_3_NfOk{v_71}:
      cps_provider_3_nf_apply(v_1, v_68, [v_71], v_7)
    case cps_provider_3_NfFail{v_74}:
      cps_provider_3_NfFail{v_74}

def native_match_cps_provider_3_nf_descriptor_step_4(v_194: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, v_65: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_194:
    case cps_provider_3_NfOk{v_68}:
      native_match_cps_provider_3_nf_descriptor_step_3(cps_provider_3_nf(v_1, v_65, v_5, v_7), v_1, v_7, v_68)
    case cps_provider_3_NfFail{v_76}:
      cps_provider_3_NfFail{v_76}

def native_match_cps_provider_3_nf_descriptor_step_5(v_196: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, v_80: Nat, v_82: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_196:
    case cps_provider_3_NfOk{v_85}:
      cps_provider_3_nf_descriptor(v_1, v_82, cps_provider_3_insert_before(v_5, Nat.sub(List.length(&2, cps_provider_3_NfVal, v_5), v_80), v_85), Nat.sub(v_7, 1n))
    case cps_provider_3_NfFail{v_90}:
      cps_provider_3_NfFail{v_90}

def native_match_cps_provider_3_nf_descriptor_step_6(v_197: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, v_94: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_197:
    case cps_provider_3_NfListOk{v_97}:
      cps_provider_3_nf_descriptor(v_1, v_94, List.append(&2, cps_provider_3_NfVal, v_5, v_97), Nat.sub(v_7, 1n))
    case cps_provider_3_NfListFail{v_101}:
      cps_provider_3_NfFail{v_101}

def native_match_cps_provider_3_nf_descriptor_step_7(v_199: cps_provider_3_NfBind, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_10: BIR.Descriptor, v_107: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_199:
    case cps_provider_3_NfBound{v_113}:
      cps_provider_3_nf_descriptor(v_1, v_107, List.append(&2, cps_provider_3_NfVal, v_5, v_113), Nat.sub(v_7, 1n))
    case _:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_5)}}

def native_match_cps_provider_3_nf_descriptor_step_8(v_198: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_10: BIR.Descriptor, v_105: List<&2, BIR.DescriptorPattern>, v_107: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_198:
    case cps_provider_3_NfListOk{v_110}:
      native_match_cps_provider_3_nf_descriptor_step_7(cps_provider_3_bind_patterns(v_105, v_110), v_1, v_5, v_7, v_10, v_107)
    case cps_provider_3_NfListFail{v_120}:
      cps_provider_3_NfFail{v_120}

def native_match_cps_provider_3_nf_descriptor_step_9(v_200: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, +v_10: BIR.Descriptor, v_124: List<&2, BIR.Descriptor>) -> cps_provider_3_Nf:
  match v_200:
    case cps_provider_3_NfListOk{v_127}:
      cps_provider_3_nf_cases(v_1, v_124, v_127, v_5, v_10, v_7)
    case cps_provider_3_NfListFail{v_130}:
      cps_provider_3_NfFail{v_130}

def native_match_cps_provider_3_nf_descriptor_step_10(v_201: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat, v_139: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_201:
    case cps_provider_3_NfOk{v_142}:
      cps_provider_3_nf_descriptor(v_1, v_139, List.append(&2, cps_provider_3_NfVal, v_5, [v_142]), Nat.sub(v_7, 1n))
    case cps_provider_3_NfFail{v_146}:
      cps_provider_3_NfFail{v_146}

def native_match_cps_provider_3_nf_descriptor_step_11(v_202: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_7: Nat, v_170: String) -> cps_provider_3_Nf:
  match v_202:
    case cps_provider_3_NfListOk{v_175}:
      cps_provider_3_nf_named(v_1, v_170, v_175, v_7)
    case cps_provider_3_NfListFail{v_178}:
      cps_provider_3_NfFail{v_178}

def native_match_cps_provider_3_nf_descriptor_step_12(v_203: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, +v_7: Nat, v_182: String) -> cps_provider_3_Nf:
  match v_203:
    case cps_provider_3_NfListOk{v_187}:
      cps_provider_3_nf_named(v_1, v_182, v_187, v_7)
    case cps_provider_3_NfListFail{v_190}:
      cps_provider_3_NfFail{v_190}

def native_match_cps_provider_3_nf_descriptor_step_13(+v_10: BIR.Descriptor, +v_1: cps_provider_3_NfContext, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_3_Nf:
  match v_10:
    case BIR.DescriptorNull{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_5)}}
    case BIR.DescriptorParameter{v_13}:
      cps_provider_3_NfOk{cps_provider_3_val_at(v_5, v_13, v_10)}
    case BIR.DescriptorQuantityKind{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_5)}}
    case BIR.DescriptorQuantity{v_17}:
      cps_provider_3_NfOk{cps_provider_3_NfQuantity{v_17}}
    case BIR.DescriptorKind{v_19}:
      native_match_cps_provider_3_nf_descriptor_step_0(cps_provider_3_nf(v_1, v_19, v_5, v_7))
    case BIR.DescriptorMinimum{v_28, v_29}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_5)}}
    case BIR.DescriptorArrow{v_34, v_35, v_36}:
      cps_provider_3_nf_arrow(v_1, v_34, v_35, v_36, v_5, v_7)
    case BIR.DescriptorLambda{v_40, v_41}:
      cps_provider_3_NfOk{cps_provider_3_NfClosure{v_40, v_41, v_5, cps_provider_3_materialize_all(v_5)}}
    case BIR.DescriptorRef{v_45, v_46}:
      native_match_cps_provider_3_nf_descriptor_step_1(cps_provider_3_nf_all(v_1, v_46, v_5, v_7), v_1, v_7, v_45)
    case BIR.DescriptorConstructor{v_55, v_56}:
      native_match_cps_provider_3_nf_descriptor_step_2(cps_provider_3_nf_all(v_1, v_56, v_5, v_7), v_55)
    case BIR.DescriptorApplication{v_64, v_65}:
      native_match_cps_provider_3_nf_descriptor_step_4(cps_provider_3_nf(v_1, v_64, v_5, v_7), v_1, v_5, v_7, v_65)
    case BIR.DescriptorSubstitution{v_80, v_81, v_82}:
      native_match_cps_provider_3_nf_descriptor_step_5(cps_provider_3_nf(v_1, v_81, v_5, v_7), v_1, v_5, v_7, v_80, v_82)
    case BIR.DescriptorLet{v_93, v_94}:
      native_match_cps_provider_3_nf_descriptor_step_6(cps_provider_3_nf_all(v_1, v_93, v_5, v_7), v_1, v_5, v_7, v_94)
    case BIR.DescriptorLocal{v_105, v_106, v_107}:
      native_match_cps_provider_3_nf_descriptor_step_8(cps_provider_3_nf_all(v_1, v_106, v_5, v_7), v_1, v_5, v_7, v_10, v_105, v_107)
    case BIR.DescriptorMatch{v_123, v_124}:
      native_match_cps_provider_3_nf_descriptor_step_9(cps_provider_3_nf_all(v_1, v_123, v_5, v_7), v_1, v_5, v_7, v_10, v_124)
    case BIR.DescriptorCase{v_133, v_134}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_5)}}
    case BIR.DescriptorBind{v_138, v_139}:
      native_match_cps_provider_3_nf_descriptor_step_10(cps_provider_3_nf(v_1, v_138, v_5, v_7), v_1, v_5, v_7, v_139)
    case BIR.DescriptorEquality{v_150, v_151, v_152}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_5)}}
    case BIR.DescriptorReflexivity{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_5)}}
    case BIR.DescriptorFailure{v_156}:
      cps_provider_3_NfFail{v_156}
    case BIR.DescriptorFill{v_159, v_160}:
      cps_provider_3_nf_apply_args(v_1, v_159, v_160, v_5, v_10, v_7)
    case BIR.DescriptorPlus{v_164, v_165}:
      cps_provider_3_nf_apply_args(v_1, v_164, v_165, v_5, v_10, v_7)
    case BIR.DescriptorNamedFill{v_170, v_171, v_172}:
      native_match_cps_provider_3_nf_descriptor_step_11(cps_provider_3_nf_all(v_1, v_172, v_5, v_7), v_1, v_7, v_170)
    case BIR.DescriptorNamedPlus{v_182, v_183, v_184}:
      native_match_cps_provider_3_nf_descriptor_step_12(cps_provider_3_nf_all(v_1, v_184, v_5, v_7), v_1, v_7, v_182)

def cps_provider_3_nf_descriptor_step(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_3_Nf:
  +v_10 = v_2
  native_match_cps_provider_3_nf_descriptor_step_13(v_10, v_1, v_5, v_7)

def native_match_cps_provider_3_nf_all_0(v_25: cps_provider_3_NfList, v_18: cps_provider_3_NfVal) -> cps_provider_3_NfList:
  match v_25:
    case cps_provider_3_NfListFail{v_21}:
      cps_provider_3_NfListFail{v_21}
    case cps_provider_3_NfListOk{v_23}:
      cps_provider_3_NfListOk{v_18 <> v_23}

def native_match_cps_provider_3_nf_all_1(v_24: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, v_13: List<&2, BIR.Descriptor>) -> cps_provider_3_NfList:
  match v_24:
    case cps_provider_3_NfFail{v_16}:
      cps_provider_3_NfListFail{v_16}
    case cps_provider_3_NfOk{v_18}:
      native_match_cps_provider_3_nf_all_0(cps_provider_3_nf_all(v_1, v_13, v_6, v_8), v_18)

def native_match_cps_provider_3_nf_all_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat) -> cps_provider_3_NfList:
  match v_3:
    case []:
      cps_provider_3_NfListOk{[]}
    case +v_12 <> v_13:
      native_match_cps_provider_3_nf_all_1(cps_provider_3_nf(v_1, v_12, v_6, v_8), v_1, v_6, v_8, v_13)

def cps_provider_3_nf_all(+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat) -> cps_provider_3_NfList:
  native_match_cps_provider_3_nf_all_2(v_3, v_1, v_6, v_8)

def native_match_cps_provider_3_nf_apply_args_0(v_23: cps_provider_3_NfList, +v_1: cps_provider_3_NfContext, v_8: BIR.Descriptor, +v_10: Nat, v_16: cps_provider_3_NfVal) -> cps_provider_3_Nf:
  match v_23:
    case cps_provider_3_NfListFail{v_19}:
      cps_provider_3_NfFail{v_19}
    case cps_provider_3_NfListOk{v_21}:
      cps_provider_3_nf_apply_source(v_1, v_16, v_21, v_8, v_10)

def native_match_cps_provider_3_nf_apply_args_1(v_22: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_3_NfVal>, v_8: BIR.Descriptor, +v_10: Nat) -> cps_provider_3_Nf:
  match v_22:
    case cps_provider_3_NfFail{v_14}:
      cps_provider_3_NfFail{v_14}
    case cps_provider_3_NfOk{v_16}:
      native_match_cps_provider_3_nf_apply_args_0(cps_provider_3_nf_all(v_1, v_4, v_7, v_10), v_1, v_8, v_10, v_16)

def cps_provider_3_nf_apply_args(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_3_NfVal>, v_8: BIR.Descriptor, +v_10: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_apply_args_1(cps_provider_3_nf(v_1, v_2, v_7, v_10), v_1, v_4, v_7, v_8, v_10)

def cps_provider_3_nf_apply_source(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_6: List<&2, cps_provider_3_NfVal>, v_7: BIR.Descriptor, +v_9: Nat) -> cps_provider_3_Nf:
  match v_6:
    case []:
      cps_provider_3_NfOk{v_3}
    case _:
      cps_provider_3_nf_apply(v_1, v_3, v_6, v_9)

def native_match_cps_provider_3_nf_apply_0(v_19: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, +v_8: Nat, v_13: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_19:
    case cps_provider_3_NfFail{v_16}:
      cps_provider_3_NfFail{v_16}
    case cps_provider_3_NfOk{v_18}:
      cps_provider_3_nf_apply(v_1, v_18, v_13, Nat.sub(v_8, 1n))

def native_match_cps_provider_3_nf_apply_1(v_6: List<&2, cps_provider_3_NfVal>, +v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, +v_8: Nat) -> cps_provider_3_Nf:
  match v_6:
    case []:
      cps_provider_3_NfOk{v_3}
    case +v_12 <> v_13:
      native_match_cps_provider_3_nf_apply_0(cps_provider_3_nf_apply_one(v_1, v_3, v_12, Nat.sub(v_8, 1n)), v_1, v_8, v_13)

def cps_provider_3_nf_apply(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_apply_1(v_6, v_1, v_3, v_8)

def cps_provider_3_nf_apply_one(+v_1: cps_provider_3_NfContext, v_3: cps_provider_3_NfVal, v_5: cps_provider_3_NfVal, +v_7: Nat) -> cps_provider_3_Nf:
  match v_3:
    case cps_provider_3_NfType{v_11, v_12}:
      cps_provider_3_nf_named(v_1, v_11, List.append(&2, cps_provider_3_NfVal, v_12, [v_5]), Nat.sub(v_7, 1n))
    case cps_provider_3_NfClosure{v_19, v_20, v_21, v_22}:
      cps_provider_3_nf_descriptor(v_1, v_20, List.append(&2, cps_provider_3_NfVal, v_21, [v_5]), Nat.sub(v_7, 1n))
    case cps_provider_3_NfCtor{v_27, v_28}:
      cps_provider_3_NfFail{String.append("the constructor `", String.append(v_27, "` is applied to an argument"))}
    case cps_provider_3_NfQuantity{v_30}:
      cps_provider_3_NfFail{"a quantity is applied to an argument"}
    case cps_provider_3_NfKind{v_32}:
      cps_provider_3_NfFail{"a kind is applied to an argument"}
    case cps_provider_3_NfOther{v_34}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{BIR.DescriptorApplication{v_34, cps_provider_3_materialize(v_5)}}}
    case cps_provider_3_NfMissing{v_37}:
      cps_provider_3_NfOk{cps_provider_3_NfMissing{BIR.DescriptorApplication{v_37, cps_provider_3_materialize(v_5)}}}

def cps_provider_3_intrinsic_io(+v_0: BIR.TypeFunction) -> Bool:
  match v_0:
    case BIR.TypeFunction{v_7, v_8, v_9, v_10, v_11}:
      match v_8:
        case Some{"IO"}:
          True{}
        case _:
          False{}

def cps_provider_3_nf_named_io(v_1: Bool, +v_3: cps_provider_3_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_3_NfVal>, +v_9: Nat) -> cps_provider_3_Nf:
  match v_1:
    case True{}:
      match v_4:
        case BIR.TypeFunction{v_16, v_17, v_18, v_19, v_20}:
          cps_provider_3_NfOk{cps_provider_3_NfType{v_16, v_7}}
    case False{}:
      cps_provider_3_nf_reduce(v_3, v_4, v_7, Nat.sub(v_9, 1n))

def native_match_cps_provider_3_nf_named_0(v_25: Maybe<&2, BIR.Family>, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_25:
    case Some{v_23}:
      cps_provider_3_nf_family(v_23, v_6)
    case None{}:
      cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_6}}

def native_match_cps_provider_3_nf_named_1(v_24: Maybe<&2, BIR.TypeFunction>, +v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat, v_12: Map<&2, BIR.Family>) -> cps_provider_3_Nf:
  match v_24:
    case Some{v_16}:
      +v_18 = v_16
      cps_provider_3_nf_named_io(cps_provider_3_intrinsic_io(v_18), v_1, v_18, v_6, v_8)
    case None{}:
      native_match_cps_provider_3_nf_named_0(cps_provider_3_family_of(v_3, v_12), v_3, v_6)

def native_match_cps_provider_3_nf_named_2(+v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat) -> cps_provider_3_Nf:
  match v_1:
    case cps_provider_3_NfContext{v_12, v_13}:
      native_match_cps_provider_3_nf_named_1(cps_provider_3_function_of(v_3, v_13), v_1, v_3, v_6, v_8, v_12)

def cps_provider_3_nf_named(+v_1: cps_provider_3_NfContext, +v_3: String, v_6: List<&2, cps_provider_3_NfVal>, +v_8: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_named_2(v_1, v_3, v_6, v_8)

def cps_provider_3_nf_arity(+v_2: List<&2, cps_provider_3_NfVal>, +v_4: Nat, +v_6: Nat) -> cps_provider_3_NfArity:
  cps_provider_3_NfArity{Nat.is_eq(Nat.add(List.length(&2, cps_provider_3_NfVal, v_2), v_4), v_6), Nat.is_eq(List.length(&2, cps_provider_3_NfVal, v_2), v_6), Nat.is_lt(List.length(&2, cps_provider_3_NfVal, v_2), v_6)}

def native_match_cps_provider_3_nf_family_0(v_0: BIR.Family, +v_6: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_0:
    case BIR.Family{v_13, v_14, v_15, v_16, v_17, v_18}:
      +v_20 = v_16
      cps_provider_3_nf_family_apply(cps_provider_3_nf_arity(v_6, v_20, v_17), v_13, v_20, v_6)

def cps_provider_3_nf_family(v_0: BIR.Family, v_3: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  +v_6 = v_3
  native_match_cps_provider_3_nf_family_0(v_0, v_6)

def cps_provider_3_nf_family_apply(v_1: cps_provider_3_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_1:
    case cps_provider_3_NfArity{v_13, v_14, v_15}:
      match v_13:
        case True{}:
          cps_provider_3_NfOk{cps_provider_3_NfType{v_3, List.append(&2, cps_provider_3_NfVal, cps_provider_3_quantity_markers(v_5), v_8)}}
        case False{}:
          match v_14:
            case True{}:
              cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_8}}
            case False{}:
              match v_15:
                case True{}:
                  cps_provider_3_NfOk{cps_provider_3_NfType{v_3, v_8}}
                case False{}:
                  cps_provider_3_NfFail{String.append("the type `", String.append(v_3, "` is applied past its declared parameter count"))}

def native_match_cps_provider_3_nf_reduce_0(v_2: BIR.TypeFunction, +v_1: cps_provider_3_NfContext, +v_7: Nat, +v_10: List<&2, cps_provider_3_NfVal>) -> cps_provider_3_Nf:
  match v_2:
    case BIR.TypeFunction{v_16, v_17, v_18, v_19, v_20}:
      +v_22 = v_18
      +v_24 = v_19
      cps_provider_3_nf_reduce_apply(cps_provider_3_nf_arity(v_10, v_22, v_24), v_1, v_16, v_22, v_24, v_20, v_10, v_7)

def cps_provider_3_nf_reduce(+v_1: cps_provider_3_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> cps_provider_3_Nf:
  +v_10 = v_5
  native_match_cps_provider_3_nf_reduce_0(v_2, v_1, v_7, v_10)

def cps_provider_3_nf_reduce_apply(v_1: cps_provider_3_NfArity, +v_3: cps_provider_3_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_3_NfVal>, +v_15: Nat) -> cps_provider_3_Nf:
  match v_1:
    case cps_provider_3_NfArity{v_20, v_21, v_22}:
      match v_20:
        case True{}:
          cps_provider_3_nf_reduce_body(v_3, v_10, List.append(&2, cps_provider_3_NfVal, cps_provider_3_quantity_markers(v_7), v_13), [], Nat.sub(v_15, 1n))
        case False{}:
          match v_21:
            case True{}:
              cps_provider_3_nf_reduce_body(v_3, v_10, cps_provider_3_first_vals(v_13, v_9), cps_provider_3_drop_vals(v_13, v_9), Nat.sub(v_15, 1n))
            case False{}:
              match v_22:
                case True{}:
                  cps_provider_3_NfOk{cps_provider_3_NfType{v_5, v_13}}
                case False{}:
                  cps_provider_3_NfFail{String.append("the type function `", String.append(v_5, "` is applied past its declared parameter count"))}

def native_match_cps_provider_3_nf_reduce_body_0(v_17: cps_provider_3_Nf, +v_1: cps_provider_3_NfContext, v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> cps_provider_3_Nf:
  match v_17:
    case cps_provider_3_NfFail{v_14}:
      cps_provider_3_NfFail{v_14}
    case cps_provider_3_NfOk{v_16}:
      cps_provider_3_nf_apply(v_1, v_16, v_8, v_10)

def cps_provider_3_nf_reduce_body(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, v_8: List<&2, cps_provider_3_NfVal>, +v_10: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_reduce_body_0(cps_provider_3_nf_descriptor(v_1, v_2, v_5, Nat.sub(v_10, 1n)), v_1, v_8, v_10)

def native_match_cps_provider_3_nf_cases_0(v_34: cps_provider_3_NfBind, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, v_18: List<&2, BIR.Descriptor>, v_22: BIR.Descriptor) -> cps_provider_3_Nf:
  match v_34:
    case cps_provider_3_NfBound{v_25}:
      cps_provider_3_nf_descriptor(v_1, v_22, List.append(&2, cps_provider_3_NfVal, v_9, v_25), Nat.sub(v_12, 1n))
    case cps_provider_3_NfMismatch{}:
      cps_provider_3_nf_cases(v_1, v_18, v_6, v_9, v_10, v_12)
    case cps_provider_3_NfUnknown{}:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_9)}}

def native_match_cps_provider_3_nf_cases_1(+v_17: BIR.Descriptor, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, v_18: List<&2, BIR.Descriptor>) -> cps_provider_3_Nf:
  match v_17:
    case BIR.DescriptorCase{v_21, v_22}:
      native_match_cps_provider_3_nf_cases_0(cps_provider_3_bind_patterns(v_21, v_6), v_1, v_6, v_9, v_10, v_12, v_18, v_22)
    case BIR.DescriptorFailure{v_31}:
      cps_provider_3_NfFail{v_31}
    case _:
      cps_provider_3_NfFail{"descriptor match case is not a case"}

def native_match_cps_provider_3_nf_cases_2(v_3: List<&2, BIR.Descriptor>, +v_1: cps_provider_3_NfContext, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat) -> cps_provider_3_Nf:
  match v_3:
    case []:
      cps_provider_3_NfOk{cps_provider_3_NfOther{cps_provider_3_reify_env(v_10, v_9)}}
    case +v_17 <> v_18:
      native_match_cps_provider_3_nf_cases_1(v_17, v_1, v_6, v_9, v_10, v_12, v_18)

def cps_provider_3_nf_cases(+v_1: cps_provider_3_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_3_NfVal>, +v_9: List<&2, cps_provider_3_NfVal>, v_10: BIR.Descriptor, +v_12: Nat) -> cps_provider_3_Nf:
  native_match_cps_provider_3_nf_cases_2(v_3, v_1, v_6, v_9, v_10, v_12)

def native_match_cps_provider_3_normalize_0(v_13: cps_provider_3_Nf) -> BIR.Descriptor:
  match v_13:
    case cps_provider_3_NfFail{v_10}:
      BIR.DescriptorFailure{v_10}
    case cps_provider_3_NfOk{v_12}:
      cps_provider_3_materialize(v_12)

def cps_provider_3_normalize(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_3_NfVal>, +v_7: Nat) -> BIR.Descriptor:
  native_match_cps_provider_3_normalize_0(cps_provider_3_nf(v_1, v_2, v_5, v_7))

def cps_provider_3_normalize_closed(v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_3_normalize(cps_provider_3_nf_context(v_1, v_3), v_4, [], 1024n)

def cps_provider_3_normalize_in(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  cps_provider_3_normalize(v_1, v_2, [], 1024n)

def cps_provider_3_outer_application(+v_0: BIR.Descriptor) -> Maybe<&2, cps_provider_3_NfApp>:
  cps_provider_3_outer_walk(v_0, [])

def cps_provider_3_outer_walk(+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>) -> Maybe<&2, cps_provider_3_NfApp>:
  match v_0:
    case BIR.DescriptorRef{v_7, v_8}:
      Some{cps_provider_3_NfApp{v_7, List.append(&2, BIR.Descriptor, v_8, v_2)}}
    case BIR.DescriptorNamedFill{v_12, v_13, v_14}:
      Some{cps_provider_3_NfApp{v_12, List.append(&2, BIR.Descriptor, v_14, v_2)}}
    case BIR.DescriptorNamedPlus{v_18, v_19, v_20}:
      Some{cps_provider_3_NfApp{v_18, List.append(&2, BIR.Descriptor, v_20, v_2)}}
    case BIR.DescriptorFill{v_23, v_24}:
      cps_provider_3_outer_walk(v_23, List.append(&2, BIR.Descriptor, v_24, v_2))
    case BIR.DescriptorPlus{v_28, v_29}:
      cps_provider_3_outer_walk(v_28, List.append(&2, BIR.Descriptor, v_29, v_2))
    case BIR.DescriptorApplication{v_33, v_34}:
      cps_provider_3_outer_walk(v_33, List.append(&2, BIR.Descriptor, [v_34], v_2))
    case _:
      None{}

def native_match_cps_provider_3_answer_in_0(v_5: BIR.Descriptor, +v_1: cps_provider_3_NfContext) -> BIR.Descriptor:
  match v_5:
    case BIR.DescriptorFailure{_}:
      v_5
    case _:
      cps_provider_3_answer_normalized(v_1, v_5)

def cps_provider_3_answer_in(+v_1: cps_provider_3_NfContext, v_2: BIR.Descriptor) -> BIR.Descriptor:
  v_5 = cps_provider_3_normalize(v_1, v_2, [], 1024n)
  native_match_cps_provider_3_answer_in_0(v_5, v_1)

def cps_provider_3_answer_descriptor(v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>) -> BIR.Descriptor:
  cps_provider_3_answer_in(cps_provider_3_nf_context(v_2, v_4), v_0)

def native_match_cps_provider_3_answer_normalized_0(v_9: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_9:
    case []:
      v_2
    case +v_13 <> v_14:
      v_13

def native_match_cps_provider_3_answer_normalized_1(v_16: Bool, +v_2: BIR.Descriptor, v_9: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  match v_16:
    case False{}:
      v_2
    case True{}:
      native_match_cps_provider_3_answer_normalized_0(v_9, v_2)

def native_match_cps_provider_3_answer_normalized_2(v_5: cps_provider_3_NfApp, +v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_5:
    case cps_provider_3_NfApp{v_8, v_9}:
      native_match_cps_provider_3_answer_normalized_1(cps_provider_3_is_io_head_in(v_1, v_8), v_2, v_9)

def native_match_cps_provider_3_answer_normalized_3(v_15: Maybe<&2, cps_provider_3_NfApp>, +v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  match v_15:
    case None{}:
      v_2
    case Some{v_5}:
      native_match_cps_provider_3_answer_normalized_2(v_5, v_1, v_2)

def cps_provider_3_answer_normalized(+v_1: cps_provider_3_NfContext, +v_2: BIR.Descriptor) -> BIR.Descriptor:
  native_match_cps_provider_3_answer_normalized_3(cps_provider_3_outer_application(v_2), v_1, v_2)

def cps_provider_3_is_io_head_in(+v_1: cps_provider_3_NfContext, +v_3: String) -> Bool:
  match v_1:
    case cps_provider_3_NfContext{v_7, v_8}:
      cps_provider_3_is_io_head(v_3, v_7, v_8)

def native_match_cps_provider_3_is_io_head_0(v_10: Maybe<&2, String>) -> Bool:
  match v_10:
    case Some{v_9}:
      String.eq(v_9, "IO")
    case None{}:
      False{}

def cps_provider_3_is_io_head(+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>) -> Bool:
  native_match_cps_provider_3_is_io_head_0(cps_provider_3_native_of(v_1, v_3, v_5))

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

def cps_provider_4_normalize_descriptor_value(v_0: BIR.Descriptor, +v_1: cps_provider_3_NfContext) -> BIR.Descriptor:
  cps_provider_3_normalize_in(v_1, v_0)

def cps_provider_4_normalize_descriptors(v_1: List<&2, BIR.Descriptor>, +v_2: cps_provider_3_NfContext) -> List<&2, BIR.Descriptor>:
  match v_1:
    case []:
      []
    case +v_6 <> v_7:
      cps_provider_4_normalize_descriptor_value(v_6, v_2) <> cps_provider_4_normalize_descriptors(v_7, v_2)

def cps_provider_4_normalize_foreign(v_2: Maybe<&2, cps_provider_4_Foreign>, +v_3: cps_provider_3_NfContext) -> Maybe<&2, cps_provider_4_Foreign>:
  match v_2:
    case None{}:
      None{}
    case Some{cps_provider_4_Foreign{v_12, v_13, v_14, v_15, v_16, v_17}}:
      Some{cps_provider_4_Foreign{v_12, v_13, v_14, v_15, cps_provider_4_normalize_descriptors(v_16, v_3), cps_provider_4_normalize_descriptor_value(v_17, v_3)}}

def cps_provider_4_normalize_foreign_header(v_1: cps_provider_4_DefinitionHeader, +v_2: cps_provider_3_NfContext) -> cps_provider_4_DefinitionHeader:
  match v_1:
    case cps_provider_4_DefinitionHeader{v_13, v_14, v_15, v_16, v_17, v_18, v_19, v_20, v_21}:
      cps_provider_4_DefinitionHeader{v_13, v_14, v_15, v_16, v_17, v_18, v_19, cps_provider_4_normalize_foreign(v_20, v_2), v_21}

def cps_provider_4_normalize_foreign_definition(v_1: cps_provider_4_Definition, +v_2: cps_provider_3_NfContext) -> cps_provider_4_Definition:
  match v_1:
    case cps_provider_4_Definition{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      cps_provider_4_Definition{cps_provider_4_normalize_foreign_header(v_12, v_2), v_13, v_14, v_15, v_16, v_17, v_18, v_19}

def cps_provider_4_normalize_foreign_definitions(v_2: List<&2, cps_provider_4_Definition>, +v_3: cps_provider_3_NfContext) -> List<&2, cps_provider_4_Definition>:
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

def native_match_cps_provider_4_exports_0(v_30: cps_provider_4_CatalogResult<List<&2, BIR.Export>>, v_4: cps_provider_4_Registry, +v_12: cps_provider_3_NfContext, v_17: String, v_23: List<&2, BIR.Descriptor>) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
  match v_30:
    case cps_provider_4_CatalogResult{v_27, v_28}:
      cps_provider_4_CatalogResult{v_27, BIR.Export{v_17, cps_provider_4_export_entry(cps_provider_4_definition_key(v_4, v_17)), cps_provider_4_normalize_descriptors(v_23, v_12)} <> v_28}

def native_match_cps_provider_4_exports_1(v_29: cps_provider_4_CatalogResult<cps_provider_4_ExportFacts>, v_4: cps_provider_4_Registry, v_8: List<&2, cps_provider_4_Definition>, v_10: List<&2, Scope.ArenaGlobal>, +v_12: cps_provider_3_NfContext, v_17: String, v_18: List<&2, String>) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
  match v_29:
    case cps_provider_4_CatalogResult{v_22, cps_provider_4_ExportFacts{v_23}}:
      native_match_cps_provider_4_exports_0(cps_provider_4_exports(v_18, v_4, v_22, v_8, v_10, v_12), v_4, v_12, v_17, v_23)

def native_match_cps_provider_4_exports_2(v_2: List<&2, String>, v_4: cps_provider_4_Registry, v_5: Arena.Arena, v_8: List<&2, cps_provider_4_Definition>, v_10: List<&2, Scope.ArenaGlobal>, +v_12: cps_provider_3_NfContext) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
  match v_2:
    case []:
      cps_provider_4_CatalogResult{v_5, []}
    case v_17 <> v_18:
      native_match_cps_provider_4_exports_1(cps_provider_4_export_facts(v_5, v_17, v_8, v_10), v_4, v_8, v_10, v_12, v_17, v_18)

def cps_provider_4_exports(v_2: List<&2, String>, v_4: cps_provider_4_Registry, v_5: Arena.Arena, v_8: List<&2, cps_provider_4_Definition>, v_10: List<&2, Scope.ArenaGlobal>, +v_12: cps_provider_3_NfContext) -> cps_provider_4_CatalogResult<List<&2, BIR.Export>>:
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

def native_match_cps_provider_4_ending_2(v_3: Maybe<&2, List<&2, String>>, v_5: Maybe<&2, BIR.Descriptor>, v_7: cps_provider_4_Registry, v_8: Arena.Arena, v_11: List<&2, cps_provider_4_Definition>, v_13: List<&2, Scope.ArenaGlobal>, +v_15: cps_provider_3_NfContext) -> cps_provider_4_CatalogResult<BIR.Ending>:
  match v_3:
    case Some{v_18}:
      native_match_cps_provider_4_ending_0(cps_provider_4_exports(v_18, v_7, v_8, v_11, v_13, v_15))
    case None{}:
      native_match_cps_provider_4_ending_1(v_5, v_8)

def cps_provider_4_ending(v_3: Maybe<&2, List<&2, String>>, v_5: Maybe<&2, BIR.Descriptor>, v_7: cps_provider_4_Registry, v_8: Arena.Arena, v_11: List<&2, cps_provider_4_Definition>, v_13: List<&2, Scope.ArenaGlobal>, +v_15: cps_provider_3_NfContext) -> cps_provider_4_CatalogResult<BIR.Ending>:
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
      v_43 = cps_provider_3_nf_context(v_40, v_35)
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

