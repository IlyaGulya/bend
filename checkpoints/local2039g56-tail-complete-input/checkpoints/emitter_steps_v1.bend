import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/checked_frontend.bend as Checked
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checker_arena.bend as Arena
import ../bend2/selfhost/checker_ir.bend as IR
import ../bend2/selfhost/scope_lookup.bend as Scope
import ../bend2/selfhost/index_lookup.bend as IndexLookup
import ../bend2/selfhost/c_backend_sharing.bend as Sharing
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

type cps_provider_7_NfContext is Data:
  cps_provider_7_NfContext{families: Map<&2, BIR.Family>, type_functions: Map<&2, BIR.TypeFunction>}

type cps_provider_1_State is Type:
  cps_provider_1_State{source: Arena.Arena, next_code: U32, next_local: U32, frame: cps_provider_1_Frame, codes: List<&2, BIR.Code>, failure: Maybe<&2, cps_provider_1_Problem>, scope: Maybe<&2, Scope.ArenaGlobalScope>, normalizer: Maybe<&2, cps_provider_7_NfContext>}

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

type cps_provider_2_CImport is Data:
  cps_provider_2_CImport{path: String, namespace: String, source: String}

type cps_provider_4_Fragment is Data:
  cps_provider_4_TextLeaf{text: String}
  cps_provider_4_TextJoin{before: cps_provider_4_Fragment, after: cps_provider_4_Fragment}

type cps_provider_2_Part is Data:
  cps_provider_2_PartOk{text: cps_provider_4_Fragment}
  cps_provider_2_PartFail{message: String}

type cps_provider_2_CidRow is Data:
  cps_provider_2_CidRow{cid: U32, key: String, arity: Nat, hot: Bool}

type cps_provider_2_CidRows is Data:
  cps_provider_2_CidRowsOk{rows: List<&2, cps_provider_2_CidRow>}
  cps_provider_2_CidRowsFail{message: String}

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

type cps_provider_3_CWord is Data:
  cps_provider_3_CWord32{}
  cps_provider_3_CWord64{}
  cps_provider_3_CWordBox{}

type cps_provider_3_BoxReason is Data:
  cps_provider_3_BoxOpen{}
  cps_provider_3_BoxUnresolved{key: String}
  cps_provider_3_BoxArray{}
  cps_provider_3_BoxIo{}
  cps_provider_3_BoxRecursive{key: String}
  cps_provider_3_BoxWide{words: Nat}

type cps_provider_3_Layout is Data:
  cps_provider_3_LayoutWord{word: cps_provider_3_CWord}
  cps_provider_3_LayoutBox{reason: cps_provider_3_BoxReason}
  cps_provider_3_LayoutData{words: List<&2, cps_provider_3_CWord>, arms: List<&2, cps_provider_3_LayArm>}

type cps_provider_3_LayArm is Data:
  cps_provider_3_LayArm{key: String, fields: List<&2, cps_provider_3_Layout>}

type cps_provider_3_NodeSlot is Data:
  cps_provider_3_NodeSlot{ordinal: U32, offset: Nat, layout: cps_provider_3_Layout}

type cps_provider_3_Node is Data:
  cps_provider_3_Node{words: List<&2, cps_provider_3_CWord>, slots: List<&2, cps_provider_3_NodeSlot>, packed: Bool}

type cps_provider_3_NodeResult is Data:
  cps_provider_3_NodeFound{node: cps_provider_3_Node}
  cps_provider_3_NodeFailed{message: String}

type cps_provider_3_Plan is Data:
  cps_provider_3_Plan{nodes: Map<&2, cps_provider_3_NodeResult>, arms: Map<&2, BIR.DescriptorArm>}

type cps_provider_3_Context is Data:
  cps_provider_3_Context{context: cps_provider_7_NfContext, families: List<&2, BIR.Family>, plan: cps_provider_3_Plan}

type cps_provider_2_Plan is Data:
  cps_provider_2_Plan{cids: List<&2, cps_provider_2_CidRow>, cid_macros: Map<&2, String>, fid_macros: Map<&2, String>, entries: List<&2, cps_provider_2_Entry>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, declarations: List<&2, BIR.Declaration>, main_pure: Bool, show_desc: String, show_names: String, imports: List<&2, cps_provider_2_CImport>, fkeys: List<&2, String>, ctx: cps_provider_3_Context, sharing: Sharing.SharingPlan, library: Bool, exports: List<&2, BIR.Export>}

type cps_provider_2_Sig is Data:
  cps_provider_2_Sig{entries: List<&2, cps_provider_2_Entry>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, declarations: List<&2, BIR.Declaration>, cids: List<&2, cps_provider_2_CidRow>, apply_fid: U32}

type cps_provider_2_PlanResult is Data:
  cps_provider_2_PlanOk{plan: cps_provider_2_Plan}
  cps_provider_2_PlanFail{message: String}

type cps_provider_2_FieldRoot is Data:
  cps_provider_2_FieldLocal{id: U32}
  cps_provider_2_FieldSlot{slot: U32}

type cps_provider_5_PathStep is Data:
  cps_provider_5_PathField{constructor: U32, field: U32}
  cps_provider_5_PathHalf{low: Bool, element: BIR.Descriptor}
  cps_provider_5_PathLeafCell{element: BIR.Descriptor}

type cps_provider_2_FieldRef is Data:
  cps_provider_2_FieldRef{root: cps_provider_2_FieldRoot, steps: List<&2, cps_provider_5_PathStep>, owners: List<&2, cps_provider_2_FieldRoot>}

type cps_provider_2_RefStep is Data:
  cps_provider_2_RefOk{ref: cps_provider_2_FieldRef}
  cps_provider_2_RefFail{message: String}

type cps_provider_2_Leave is Data:
  cps_provider_2_Leave{label: U32, block: BIR.Block}

type cps_provider_2_Env is Data:
  cps_provider_2_Env{id: U32, expr: String, drop: String, field: Maybe<&2, cps_provider_2_FieldRef>}

type cps_provider_2_CapRef is Data:
  cps_provider_2_CapLocalRef{id: U32}
  cps_provider_2_CapSlotRef{slot: U32}

type cps_provider_2_Cap is Data:
  cps_provider_2_CapLocal{id: U32, expr: String}
  cps_provider_2_CapSlot{slot: U32, expr: String}
  cps_provider_2_CapField{id: U32, ref: cps_provider_2_FieldRef}

type cps_provider_2_CapsStep is Data:
  cps_provider_2_CapsOk{caps: List<&2, cps_provider_2_Cap>}
  cps_provider_2_CapsFail{message: String}

type cps_provider_2_Region is Data:
  cps_provider_2_Region{label: U32, fid: U32, refs: List<&2, cps_provider_2_CapRef>}

type cps_provider_2_SegText is Data:
  cps_provider_2_SegText{fid: U32, arity: Nat, resw: Nat, text: String, forked: Bool, calls: List<&2, U32>}

type cps_provider_2_Ctx is Data:
  cps_provider_2_Ctx{sig: cps_provider_2_Sig, plan: cps_provider_2_Plan, env: List<&2, cps_provider_2_Env>, caps: List<&2, String>, caps_n: Nat, regions: List<&2, cps_provider_2_Region>, self_fid: Maybe<&2, U32>, next: U32, segs: List<&2, cps_provider_2_SegText>, forked: Bool, calls: List<&2, U32>, spin: Bool, max_arity: Nat, cap_slots: List<&2, U32>, leaves: List<&2, cps_provider_2_Leave>}

type cps_provider_2_WriteStep is Data:
  cps_provider_2_WriteOk{text: String, ctx: cps_provider_2_Ctx}
  cps_provider_2_WriteFail{message: String}

type cps_provider_2_ArgsStep is Data:
  cps_provider_2_ArgsOk{texts: List<&2, String>, ctx: cps_provider_2_Ctx}
  cps_provider_2_ArgsFail{message: String}

type cps_provider_2_OpStep is Data:
  cps_provider_2_OpOk{setup: String, text: String, ctx: cps_provider_2_Ctx}
  cps_provider_2_OpFail{message: String}

type cps_provider_2_Step is Data:
  cps_provider_2_StepOk{text: String, ctx: cps_provider_2_Ctx}
  cps_provider_2_StepFail{message: String}

type cps_provider_2_Control is Data:
  cps_provider_2_ControlOk{segments: String, rows: List<&2, cps_provider_2_SegText>, max_arity: Nat}
  cps_provider_2_ControlFail{message: String}

type cps_provider_3_LayoutResult is Data:
  cps_provider_3_LayoutFound{layout: cps_provider_3_Layout}
  cps_provider_3_LayoutFailed{message: String}

type cps_provider_3_HeadResult is Data:
  cps_provider_3_HeadFound{key: String, native: Maybe<&2, String>}
  cps_provider_3_HeadEquality{}
  cps_provider_3_HeadBoxed{reason: cps_provider_3_BoxReason}
  cps_provider_3_HeadFailed{message: String}

type cps_provider_3_FieldsResult is Data:
  cps_provider_3_FieldsFound{fields: List<&2, BIR.DescriptorField>}
  cps_provider_3_FieldsFailed{message: String}

type cps_provider_3_NormResult is Data:
  cps_provider_3_NormOk{descriptor: BIR.Descriptor}
  cps_provider_3_NormFailed{message: String}

type cps_provider_3_ArgsResult is Data:
  cps_provider_3_ArgsOk{args: List<&2, BIR.Descriptor>}
  cps_provider_3_ArgsFailed{message: String}

type cps_provider_3_Nest is Data:
  cps_provider_3_Nest{at: Nat, offset: Nat, take: cps_provider_3_Unfill, make: cps_provider_3_Fill}

type cps_provider_3_Fill is Data:
  cps_provider_3_FillWord{}
  cps_provider_3_FillForm{words: Nat, arms: List<&2, cps_provider_3_FormArm>}

type cps_provider_3_Unfill is Data:
  cps_provider_3_UnfillWord{}
  cps_provider_3_UnfillForm{words: Nat, arms: List<&2, cps_provider_3_FormArm>}

type cps_provider_3_FormArm is Data:
  cps_provider_3_FormArm{key: String, tag: Nat, packed: Bool, node_words: Nat, fields: List<&2, cps_provider_3_Nest>}

type cps_provider_3_FillResult is Data:
  cps_provider_3_FillFound{fill: cps_provider_3_Fill}
  cps_provider_3_FillFailed{message: String}

type cps_provider_3_UnfillResult is Data:
  cps_provider_3_UnfillFound{unfill: cps_provider_3_Unfill}
  cps_provider_3_UnfillFailed{message: String}

type cps_provider_3_SlotResult is Data:
  cps_provider_3_SlotFound{slot: cps_provider_3_NodeSlot}
  cps_provider_3_SlotErased{}
  cps_provider_3_SlotFailed{message: String}

type cps_provider_3_Cell is Data:
  cps_provider_3_Cell{layout: cps_provider_3_Layout, arr: Bool, words: Nat, lgs: Nat}

type cps_provider_3_CellResult is Data:
  cps_provider_3_CellFound{cell: cps_provider_3_Cell}
  cps_provider_3_CellFailed{message: String}

type cps_provider_3_Plans is Data:
  cps_provider_3_PlansOk{plans: List<&2, cps_provider_3_LayArm>}
  cps_provider_3_PlansFail{message: String}

type cps_provider_3_Layouts is Data:
  cps_provider_3_LayoutsOk{layouts: List<&2, cps_provider_3_Layout>}
  cps_provider_3_LayoutsFail{message: String}

type cps_provider_3_Slots is Data:
  cps_provider_3_SlotsOk{slots: List<&2, cps_provider_3_NodeSlot>}
  cps_provider_3_SlotsFail{message: String}

type cps_provider_3_Arms is Data:
  cps_provider_3_ArmsOk{arms: List<&2, cps_provider_3_FormArm>}
  cps_provider_3_ArmsFail{message: String}

type cps_provider_3_Nests is Data:
  cps_provider_3_NestsOk{nests: List<&2, cps_provider_3_Nest>}
  cps_provider_3_NestsFail{message: String}

type cps_provider_3_FormArmResult is Data:
  cps_provider_3_FormArmOk{plan: cps_provider_3_FormArm}
  cps_provider_3_FormArmFail{message: String}

type cps_provider_4_LinkResult is Data:
  cps_provider_4_LinkSuccess{source: String}
  cps_provider_4_LinkFailure{message: String}

type cps_provider_4_Mode is Data:
  cps_provider_4_CodeMode{}
  cps_provider_4_LineComment{}
  cps_provider_4_BlockComment{}
  cps_provider_4_DoubleQuote{}
  cps_provider_4_SingleQuote{}
  cps_provider_4_Backtick{}
  cps_provider_4_KeyMode{head: Char, collected: List<&2, Char>}

type cps_provider_4_Scan is Data:
  cps_provider_4_ScanComplete{output: List<&2, Char>, failure: Maybe<&2, String>}

type cps_provider_5_Part is Data:
  cps_provider_5_PartOk{text: String}
  cps_provider_5_PartFail{message: String}

type cps_provider_5_CidSym is Data:
  cps_provider_5_CidSym{cid: U32, key: String}

type cps_provider_5_World is Data:
  cps_provider_5_World{ctx: cps_provider_3_Context, constructors: List<&2, BIR.ConstructorLayout>, cids: List<&2, cps_provider_5_CidSym>}

type cps_provider_5_Code is Data:
  cps_provider_5_CodeOk{lines: List<&2, String>}
  cps_provider_5_CodeFail{message: String}

type cps_provider_5_Operand is Data:
  cps_provider_5_Operand{use: BIR.Use, text: String}

type cps_provider_5_Dst is Data:
  cps_provider_5_DstSeq{buf: String, cursor: String}
  cps_provider_5_DstOut{out: String}

type cps_provider_5_Src is Data:
  cps_provider_5_SrcOne{text: String}
  cps_provider_5_SrcNode{base: String, fb: String, cursor: String, packed: Bool}
  cps_provider_5_SrcBlock{loc: String, at: String, arr: Bool, keep: Bool, cursor: String}
  cps_provider_5_SrcBuf{buf: String, cursor: String}

type cps_provider_5_Job is Data:
  cps_provider_5_JText{text: String}
  cps_provider_5_JConv{take: cps_provider_3_Unfill, make: cps_provider_3_Fill, src: cps_provider_5_Src, dst: cps_provider_5_Dst, tag: String}
  cps_provider_5_JFail{message: String}

type cps_provider_5_CellOut is Data:
  cps_provider_5_CellOk{layout: cps_provider_3_Layout, arr: Bool, words: Nat, lgs: Nat}
  cps_provider_5_CellFail{message: String}

type cps_provider_5_ShowWord is Data:
  cps_provider_5_ShowNum{value: Nat}
  cps_provider_5_ShowCid{value: Nat}

type cps_provider_5_ShowPatch is Data:
  cps_provider_5_ShowPatchAt{at: Nat, to: Nat}

type cps_provider_5_ShowState is Data:
  cps_provider_5_ShowState{words: List<&2, cps_provider_5_ShowWord>, patches: List<&2, cps_provider_5_ShowPatch>, memo: Map<&2, Nat>, names: List<&2, String>, error: Maybe<&2, String>}

type cps_provider_5_ShowJob is Data:
  cps_provider_5_ShowNode{ty: BIR.Descriptor, layout: cps_provider_3_Layout, patch: Maybe<&2, Nat>}

type cps_provider_5_ShowAdvance is Data:
  cps_provider_5_ShowNext{state: cps_provider_5_ShowState, kids: List<&2, cps_provider_5_ShowJob>}

type cps_provider_5_ShowRun is Data:
  cps_provider_5_ShowDone{state: cps_provider_5_ShowState}

type cps_provider_5_ShowOut is Data:
  cps_provider_5_ShowOk{desc: String, names: String}
  cps_provider_5_ShowFail{message: String}

type cps_provider_5_ShowKind is Data:
  cps_provider_5_ShowKindOk{kind: Nat}
  cps_provider_5_ShowKindFailed{message: String}

type cps_provider_5_ShowNorm is Data:
  cps_provider_5_ShowNormOk{descriptor: BIR.Descriptor}
  cps_provider_5_ShowNormFailed{message: String}

type cps_provider_5_ShowToken is Data:
  cps_provider_5_ShowTokDesc{descriptor: BIR.Descriptor}
  cps_provider_5_ShowTokText{text: String}
  cps_provider_5_ShowTokPat{pattern: BIR.DescriptorPattern}

type cps_provider_5_PathState is Data:
  cps_provider_5_StSlot{offset: Nat, layout: cps_provider_3_Layout, base: String, uniq: String, stat: String, packed: Bool}
  cps_provider_5_StArray{loc: String, cls: String, lgs: Nat, cell: cps_provider_3_Layout, arr: String, off: String, buf: Bool, uniq: String, stat: String}
  cps_provider_5_StCell{loc: String, arr: String, index: String, cls: String, layout: cps_provider_3_Layout, lgs: Nat, buf: Bool, uniq: String, stat: String}
  cps_provider_5_StBufField{loc: String, index: String, layout: cps_provider_3_Layout, uniq: String, stat: String}

type cps_provider_5_PathResult is Data:
  cps_provider_5_PathOk{state: cps_provider_5_PathState}
  cps_provider_5_PathFail{message: String}

type cps_provider_6_EmitResult is Data:
  cps_provider_6_EmitSuccess{source: String}
  cps_provider_6_EmitFailure{message: String, span: Ast.SourceSpan}

type cps_provider_6_CImportPlan is Data:
  cps_provider_6_CImportPlan{path: String, namespace: String, span: Ast.SourceSpan}

type cps_provider_6_PlanResult is Data:
  cps_provider_6_PlanSuccess{imports: List<&2, cps_provider_6_CImportPlan>}
  cps_provider_6_PlanFailure{message: String, span: Ast.SourceSpan}

type cps_provider_6_JoinResult is Data:
  cps_provider_6_JoinSuccess{imports: List<&2, cps_provider_2_CImport>}
  cps_provider_6_JoinFailure{message: String, span: Ast.SourceSpan}

type cps_provider_7_NfVal is Data:
  cps_provider_7_NfType{key: String, args: List<&2, cps_provider_7_NfVal>}
  cps_provider_7_NfCtor{key: String, args: List<&2, cps_provider_7_NfVal>}
  cps_provider_7_NfQuantity{quantity: BIR.Quantity}
  cps_provider_7_NfKind{quantity: cps_provider_7_NfVal}
  cps_provider_7_NfOther{source: BIR.Descriptor}
  cps_provider_7_NfMissing{source: BIR.Descriptor}
  cps_provider_7_NfBinder{level: Nat}
  cps_provider_7_NfArrow{quantity: BIR.Quantity, domain: cps_provider_7_NfVal, body: cps_provider_7_NfVal, level: Nat}
  cps_provider_7_NfClosure{quantity: Maybe<&2, BIR.Quantity>, body: BIR.Descriptor, env: List<&2, cps_provider_7_NfVal>}

type cps_provider_7_NfRenaming is Data:
  cps_provider_7_NfRenaming{source: Nat, target: Nat}

type cps_provider_7_NfBind is Data:
  cps_provider_7_NfBound{bindings: List<&2, cps_provider_7_NfVal>}
  cps_provider_7_NfMismatch{}
  cps_provider_7_NfUnknown{}

type cps_provider_7_NfStatus is Data:
  cps_provider_7_NfStatusOk{}
  cps_provider_7_NfStatusNo{}
  cps_provider_7_NfStatusMaybe{}

type cps_provider_7_Nf is Data:
  cps_provider_7_NfOk{val: cps_provider_7_NfVal}
  cps_provider_7_NfFail{message: String}

type cps_provider_7_NfList is Data:
  cps_provider_7_NfListOk{vals: List<&2, cps_provider_7_NfVal>}
  cps_provider_7_NfListFail{message: String}

type cps_provider_7_NfApp is Data:
  cps_provider_7_NfApp{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_7_NfArity is Data:
  cps_provider_7_NfArity{complete: Bool, exact: Bool, under: Bool}

type cps_provider_8_EmitResult is Data:
  cps_provider_8_EmitSuccess{source: String}
  cps_provider_8_EmitFailure{message: String, span: Ast.SourceSpan}

type cps_provider_8_LinkSource is Data:
  cps_provider_8_LinkSource{path: String, namespace: String, span: Ast.SourceSpan}

type cps_provider_8_LinkResult is Data:
  cps_provider_8_LinkSuccess{sources: List<&2, cps_provider_8_LinkSource>}
  cps_provider_8_LinkFailure{message: String, span: Ast.SourceSpan}

type cps_provider_8_JSParameter is Data:
  cps_provider_8_JSParameterNat{}
  cps_provider_8_JSParameterOther{}
  cps_provider_8_JSParameterUnresolved{}

type cps_provider_8_Caps is Data:
  cps_provider_8_Caps{locals: List<&2, U32>, slots: List<&2, U32>}

type cps_provider_8_Suffix is Data:
  cps_provider_8_Suffix{locals: List<&2, U32>, slots: List<&2, U32>, read_local: Map<&2, Bool>, read_slot: Map<&2, Bool>, bound: Map<&2, Bool>}

type cps_provider_8_Held is Data:
  cps_provider_8_Held{items: List<&2, U32>, read: Map<&2, Bool>}

type cps_provider_8_FrameBits is Data:
  cps_provider_8_FrameBits{label: U32, after: Bool, reach: Bool}

type cps_provider_8_Plan is Data:
  cps_provider_8_Plan{conts: Map<&2, cps_provider_8_Caps>, thunks: Map<&2, cps_provider_8_Caps>, frames: Map<&2, Bool>}

type cps_provider_8_Step is Data:
  cps_provider_8_Step{state: cps_provider_8_Suffix, facts: List<&2, cps_provider_8_FrameBits>, plan: cps_provider_8_Plan}

type cps_provider_8_Reads is Data:
  cps_provider_8_Reads{locals: List<&2, U32>, slots: List<&2, U32>}

type cps_provider_8_JsCtx is Data:
  cps_provider_8_JsCtx{owner: String, plan: cps_provider_8_Plan, frames: List<&2, U32>}

type cps_provider_8_JSCidResult is Data:
  cps_provider_8_JSCidDone{source: String}
  cps_provider_8_JSCidFailure{message: String}

type cps_provider_8_JSMode is Data:
  cps_provider_8_JSCode{}
  cps_provider_8_JSLineComment{}
  cps_provider_8_JSBlockComment{}
  cps_provider_8_JSDoubleQuote{}
  cps_provider_8_JSSingleQuote{}
  cps_provider_8_JSBacktick{}

type cps_provider_8_JSScan is Data:
  cps_provider_8_JSScanComplete{output: List<&2, Char>}
  cps_provider_8_JSScanRefused{message: String}

type cps_provider_8_JSKeyScan is Data:
  cps_provider_8_JSKeyFound{key: String, rest: List<&2, Char>}
  cps_provider_8_JSKeyAbsent{}

type cps_provider_8_JSEffects is Data:
  cps_provider_8_JSEffectsReady{text: String}
  cps_provider_8_JSEffectsFailure{message: String, span: Ast.SourceSpan}

type cps_provider_8_TagArm is Data:
  cps_provider_8_TagArm{label: U32, condition: U32, tag: String, body: BIR.Block}

type cps_provider_8_TaggedRegion is Data:
  cps_provider_8_TaggedRegion{label: U32, condition: U32, subject: BIR.Atom, tag: String, body: BIR.Block, rest: BIR.Block}

type cps_provider_8_TagGroup is Data:
  cps_provider_8_TagGroup{arms: List<&2, cps_provider_8_TagArm>, rest: BIR.Block, count: Nat}

type cps_provider_8_JSDescriptorHead is Data:
  cps_provider_8_JSDescriptorHead{key: String, args: List<&2, BIR.Descriptor>}

type cps_provider_8_JsMapFind is Data:
  cps_provider_8_JsMapFind{tip: Maybe<&2, String>, leaf: Maybe<&2, String>, leaf_key: Maybe<&2, String>, leaf_value: Maybe<&2, String>, node: Maybe<&2, String>, node_pos: Maybe<&2, String>, node_lo: Maybe<&2, String>, node_hi: Maybe<&2, String>, none: Maybe<&2, String>, some: Maybe<&2, String>, some_value: Maybe<&2, String>}

type cps_provider_9_EmitResult is Data:
  cps_provider_9_EmitSuccess{source: String}
  cps_provider_9_EmitFailure{message: String, span: Ast.SourceSpan}

type cps_provider_10_Foreign is Data:
  cps_provider_10_Foreign{namespace: String, imported: String, sources: List<&2, String>, span: Ast.SourceSpan, parameter_types: List<&2, BIR.Descriptor>, result: BIR.Descriptor}

type cps_provider_10_DefinitionHeader is Data:
  cps_provider_10_DefinitionHeader{symbol: IR.Symbol, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, cps_provider_10_Foreign>, fast: Bool}

type cps_provider_10_Definition is Data:
  cps_provider_10_Definition{header: cps_provider_10_DefinitionHeader, binders: IR.Words, result: IR.OptionalTerm, body: IR.DefBody, checked: Maybe<&2, IR.Occurrence>, scope: Scope.ArenaGlobalScope, native: Maybe<&2, String>, quantity_prefix: Nat}

type cps_provider_10_Constructor is Data:
  cps_provider_10_Constructor{layout: BIR.ConstructorLayout, quantities: List<&2, BIR.Quantity>, parameters: Nat, family: String}

type cps_provider_10_Registry is Data:
  cps_provider_10_Registry{definitions: Map<&2, cps_provider_10_DefinitionHeader>, constructors: Map<&2, cps_provider_10_Constructor>}

type cps_provider_10_Catalog is Data:
  cps_provider_10_Catalog{definitions: List<&2, cps_provider_10_Definition>, registry: cps_provider_10_Registry, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, next_code: U32, ending: BIR.Ending}

type cps_provider_10_BuildResult is Type:
  cps_provider_10_Built{program: Checked.CheckedProgram, catalog: cps_provider_10_Catalog}
  cps_provider_10_BuildFailure{program: Checked.CheckedProgram, message: String}

type cps_provider_10_CatalogResult<-T: Type> is Type:
  cps_provider_10_CatalogResult{source: Arena.Arena, value: T}

type cps_provider_10_Telescope is Data:
  cps_provider_10_Telescope{parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, fields: List<&2, BIR.DescriptorField>, fixed: Bool}

type cps_provider_10_Needed is Data:
  cps_provider_10_Needed{functions: List<&2, BIR.TypeFunction>, seen: Map<&2, Bool>}

type cps_provider_10_Root is Data:
  cps_provider_10_TermRoot{term: U32, scope: Scope.ArenaGlobalScope}
  cps_provider_10_DefinitionRoot{key: String}

type cps_provider_10_Preparation is Data:
  cps_provider_10_Preparation{definitions: List<&2, cps_provider_10_Definition>, index: Map<&2, cps_provider_10_Definition>, headers: Map<&2, cps_provider_10_DefinitionHeader>, constructors: List<&2, BIR.ConstructorLayout>, constructor_index: Map<&2, cps_provider_10_Constructor>, families: List<&2, BIR.Family>, next_code: U32, next_constructor: U32, roots: List<&2, cps_provider_10_Root>, main: Maybe<&2, BIR.Descriptor>, failure: Maybe<&2, String>, module_values: Map<&2, Bool>}

type cps_provider_10_Arms is Data:
  cps_provider_10_Arms{arms: List<&2, BIR.DescriptorArm>, state: cps_provider_10_Preparation}

type cps_provider_10_ExportFacts is Data:
  cps_provider_10_ExportFacts{parameter_types: List<&2, BIR.Descriptor>, result: BIR.Descriptor}

type cps_provider_10_ConstructorField is Data:
  cps_provider_10_ConstructorField{identity: U32, key: Maybe<&2, String>, quantity: BIR.Quantity}


# Bounded typed request groups; every source declaration retains its checked signature.
type EmitterRequestGroup0 is Type:
  EmitterRequest_emitted_js{v_1: cps_provider_9_EmitResult}
  EmitterRequest_emitted_c{v_1: cps_provider_6_EmitResult}
  EmitterRequest_emit{v_0: Checked.CheckedProgram, v_2: List<&2, BIR.SourceFile>}
  EmitterRequest_emit_library{v_0: Checked.CheckedProgram, v_3: List<&2, String>, v_5: List<&2, BIR.SourceFile>}
  EmitterRequest_emit_c{v_0: Checked.CheckedProgram, v_2: String, v_4: List<&2, BIR.SourceFile>}
  EmitterRequest_emit_c_library{v_0: Checked.CheckedProgram, v_3: List<&2, String>, v_5: String, v_7: List<&2, BIR.SourceFile>}
  EmitterRequest_emit_bir{v_0: BIR.Program, v_2: List<&2, BIR.SourceFile>}
  EmitterRequest_emit_c_bir{v_0: BIR.Program, v_2: String, v_4: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_1_use{v_0: Ast.Quantity}
  EmitterRequest_cps_provider_1_bir_use{v_0: BIR.Quantity}
  EmitterRequest_cps_provider_1_no_span{}
  EmitterRequest_cps_provider_1_problem_first{v_2: Maybe<&2, cps_provider_1_Problem>, v_4: String, v_5: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_fail{v_1: cps_provider_1_State, v_3: String, v_4: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_state_problem_0{v_1: cps_provider_1_LowerResult<BIR.Atom>}
  EmitterRequest_cps_provider_1_state_problem{v_1: cps_provider_1_State, v_3: String, v_4: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_node_0{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_5: U32, v_7: U32, v_9: cps_provider_1_Frame, v_11: List<&2, BIR.Code>, v_14: Maybe<&2, cps_provider_1_Problem>, v_16: Maybe<&2, Scope.ArenaGlobalScope>, v_19: Maybe<&2, cps_provider_7_NfContext>}
  EmitterRequest_cps_provider_1_native_match_node_1{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_node{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_native_match_name_0{v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_6: U32, v_8: U32, v_10: cps_provider_1_Frame, v_12: List<&2, BIR.Code>, v_15: Maybe<&2, cps_provider_1_Problem>, v_17: Maybe<&2, Scope.ArenaGlobalScope>, v_20: Maybe<&2, cps_provider_7_NfContext>}
  EmitterRequest_cps_provider_1_native_match_name_1{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_name{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_fresh{v_1: cps_provider_1_State}
  EmitterRequest_cps_provider_1_reserve{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_push{v_1: cps_provider_1_State, v_3: cps_provider_1_Instruction}
  EmitterRequest_cps_provider_1_native_match_operation_0{v_2: cps_provider_1_LowerResult<U32>, v_3: BIR.Op}
  EmitterRequest_cps_provider_1_operation{v_1: cps_provider_1_State, v_2: BIR.Op}
  EmitterRequest_cps_provider_1_guard{v_1: cps_provider_1_State, v_2: BIR.Atom, v_3: BIR.Block}
  EmitterRequest_cps_provider_1_prefix{v_2: List<&2, cps_provider_1_Instruction>, v_3: BIR.Block}
  EmitterRequest_cps_provider_1_finish{v_2: List<&2, cps_provider_1_Instruction>, v_3: BIR.Atom}
  EmitterRequest_cps_provider_1_finish_last{v_1: Bool, v_3: U32, v_4: BIR.Op, v_7: List<&2, cps_provider_1_Instruction>, v_9: U32}
  EmitterRequest_cps_provider_1_slot_at{v_2: List<&2, cps_provider_1_Slot>, v_4: Nat}
  EmitterRequest_cps_provider_1_capture_found{v_2: List<&2, cps_provider_1_Capture>, v_4: U32, v_6: U32}
  EmitterRequest_cps_provider_1_capture_found_next{v_1: Bool, v_3: U32, v_6: List<&2, cps_provider_1_Capture>, v_8: U32, v_10: U32}
  EmitterRequest_cps_provider_1_resolve{v_1: cps_provider_1_State, v_3: cps_provider_1_Slot}
  EmitterRequest_cps_provider_1_resolve_live{v_1: cps_provider_1_State, v_3: U32, v_5: U32, v_6: BIR.Atom, v_7: BIR.Use}
  EmitterRequest_cps_provider_1_native_match_resolve_owner_0{v_1: cps_provider_1_State, v_3: cps_provider_1_Slot, v_5: U32, v_7: U32}
  EmitterRequest_cps_provider_1_native_match_resolve_owner_1{v_1: Bool, v_3: cps_provider_1_Slot, v_5: cps_provider_1_State}
  EmitterRequest_cps_provider_1_resolve_owner{v_1: Bool, v_3: cps_provider_1_State, v_5: cps_provider_1_Slot}
  EmitterRequest_cps_provider_1_resolve_capture{v_2: Maybe<&2, U32>, v_3: Arena.Arena, v_5: U32, v_7: U32, v_9: U32, v_12: List<&2, cps_provider_1_Instruction>, v_15: List<&2, cps_provider_1_Capture>, v_17: U32, v_19: List<&2, BIR.Code>, v_22: Maybe<&2, cps_provider_1_Problem>, v_24: cps_provider_1_Slot, v_26: Maybe<&2, Scope.ArenaGlobalScope>, v_29: Maybe<&2, cps_provider_7_NfContext>}
  EmitterRequest_cps_provider_1_variable{v_1: cps_provider_1_State, v_4: List<&2, cps_provider_1_Slot>, v_6: Nat, v_7: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_variable_found{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_1_Slot>, v_5: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_bind_slot_0{v_1: cps_provider_1_Frame, v_2: BIR.Atom, v_3: BIR.Use, v_5: U32, v_6: Arena.Arena, v_8: U32, v_10: U32, v_12: List<&2, BIR.Code>, v_15: Maybe<&2, cps_provider_1_Problem>, v_17: Maybe<&2, Scope.ArenaGlobalScope>, v_20: Maybe<&2, cps_provider_7_NfContext>}
  EmitterRequest_cps_provider_1_native_match_bind_slot_1{v_1: cps_provider_1_State, v_2: BIR.Atom, v_3: BIR.Use, v_5: U32}
  EmitterRequest_cps_provider_1_native_match_bind_slot_2{v_2: cps_provider_1_LowerResult<U32>, v_3: BIR.Atom, v_4: BIR.Use}
  EmitterRequest_cps_provider_1_bind_slot{v_1: cps_provider_1_State, v_2: BIR.Atom, v_3: BIR.Use}
  EmitterRequest_cps_provider_1_enter{v_1: cps_provider_1_State}
  EmitterRequest_cps_provider_1_capture_uses{v_2: List<&2, cps_provider_1_Capture>}
  EmitterRequest_cps_provider_1_leave{v_1: cps_provider_1_State, v_3: cps_provider_1_Frame, v_5: List<&2, BIR.Parameter>, v_6: BIR.Block}
  EmitterRequest_cps_provider_1_leave_value{v_1: cps_provider_1_State, v_3: cps_provider_1_Frame, v_5: List<&2, BIR.Parameter>, v_6: BIR.Atom}
  EmitterRequest_cps_provider_1_capture_arguments{v_1: cps_provider_1_State, v_4: List<&2, cps_provider_1_Capture>}
  EmitterRequest_cps_provider_1_native_match_capture_argument_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Arg>>, v_3: BIR.Use, v_4: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_capture_argument_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Capture>, v_5: BIR.Use}
  EmitterRequest_cps_provider_1_native_match_capture_argument_2{v_1: cps_provider_1_Slot, v_3: cps_provider_1_State, v_6: List<&2, cps_provider_1_Capture>}
  EmitterRequest_cps_provider_1_capture_argument{v_1: cps_provider_1_State, v_3: cps_provider_1_Slot, v_6: List<&2, cps_provider_1_Capture>}
  EmitterRequest_cps_provider_1_native_match_close_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Arg>>, v_4: U32, v_6: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_native_match_close_1{v_1: cps_provider_1_CodeRef, v_3: cps_provider_1_State}
  EmitterRequest_cps_provider_1_close{v_1: cps_provider_1_State, v_3: cps_provider_1_CodeRef}
  EmitterRequest_cps_provider_1_native_match_call_reference_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Arg>>, v_4: List<&2, BIR.Arg>, v_6: U32}
  EmitterRequest_cps_provider_1_native_match_call_reference_1{v_1: cps_provider_1_CodeRef, v_3: cps_provider_1_State, v_5: List<&2, BIR.Arg>}
  EmitterRequest_cps_provider_1_call_reference{v_1: cps_provider_1_State, v_3: cps_provider_1_CodeRef, v_5: List<&2, BIR.Arg>}
  EmitterRequest_cps_provider_1_constructor_native{v_1: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_1_constructor_id{v_1: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_1_constructor_key{v_1: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_1_atom_arguments{v_1: List<&2, BIR.Atom>}

type EmitterRequestGroup1 is Type:
  EmitterRequest_cps_provider_1_describe{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_element_value{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_single_argument{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_1_map_value_argument{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_1_element_argument{v_1: cps_provider_1_State, v_3: U32}
  EmitterRequest_cps_provider_1_primitive_element{v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Atom>, v_7: Maybe<&2, U32>, v_9: Bool}
  EmitterRequest_cps_provider_1_primitive_types{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_5: cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>}
  EmitterRequest_cps_provider_1_occurrence_type{v_0: IR.Occurrence}
  EmitterRequest_cps_provider_1_first_binding_type{v_1: List<&2, IR.CheckedBinding>}
  EmitterRequest_cps_provider_1_first_occurrence_type{v_1: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_erased_type_term{v_2: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_parameter_uses{v_1: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_live_argument_type{v_2: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_last_live_argument_type{v_2: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_array_element_handle{v_0: BIR.Primitive, v_3: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_array_element_is_argument{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_1_array_primitive{+v_0: BIR.Primitive}
  EmitterRequest_cps_provider_1_element_primitive{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_1_primitive{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Atom>}
  EmitterRequest_cps_provider_1_primitive_call{v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Arg>, v_7: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_primitive_call_element{v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Arg>, v_7: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_element_fact{v_1: cps_provider_1_State, v_3: U32, v_5: Bool}
  EmitterRequest_cps_provider_1_effective_arrayed{v_0: BIR.Primitive, v_2: Bool}
  EmitterRequest_cps_provider_1_primitive_fact{v_1: cps_provider_1_State, +v_2: BIR.Primitive, +v_4: List<&2, BIR.Atom>, v_7: Maybe<&2, U32>, v_9: Bool}
  EmitterRequest_cps_provider_1_field_values{v_1: cps_provider_1_State, v_3: cps_provider_10_Constructor, v_5: List<&2, BIR.Atom>, v_7: U32, v_8: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_field_value_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Field>>, v_3: BIR.Atom, v_5: U32, v_7: String, v_8: BIR.Quantity}
  EmitterRequest_cps_provider_1_native_match_field_value_1{v_2: Maybe<&2, cps_provider_10_ConstructorField>, v_4: cps_provider_1_State, v_6: cps_provider_10_Constructor, v_7: BIR.Atom, v_9: List<&2, BIR.Atom>, v_11: U32, v_12: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_field_value{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_ConstructorField>, v_6: cps_provider_10_Constructor, v_7: BIR.Atom, v_9: List<&2, BIR.Atom>, v_11: U32, v_12: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_nat_successor_result{v_1: cps_provider_1_State, v_3: Nat, v_5: Bool}
  EmitterRequest_cps_provider_1_nat_successor_value{v_1: cps_provider_1_State, +v_3: Nat}
  EmitterRequest_cps_provider_1_nat_successor_atom{v_1: cps_provider_1_State, v_2: BIR.Atom}
  EmitterRequest_cps_provider_1_construct{v_1: cps_provider_1_State, v_3: cps_provider_10_Constructor, v_5: List<&2, BIR.Atom>, v_6: Ast.SourceSpan, v_9: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_construct_native_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Field>>, v_4: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_1_native_match_construct_native_1{v_1: String, v_3: List<&2, BIR.Atom>, v_5: cps_provider_1_State, v_7: cps_provider_10_Constructor, v_8: Ast.SourceSpan, v_11: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_construct_native{v_1: cps_provider_1_State, v_3: String, v_5: cps_provider_10_Constructor, v_7: List<&2, BIR.Atom>, v_8: Ast.SourceSpan, v_11: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_construct_symbol{v_1: cps_provider_1_State, v_3: cps_provider_10_Registry, v_4: IR.Symbol, v_6: List<&2, BIR.Atom>, v_7: Ast.SourceSpan, v_10: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_construct_found{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_Constructor>, v_6: List<&2, BIR.Atom>, v_7: Ast.SourceSpan, v_10: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_constructor_operands_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>}
  EmitterRequest_cps_provider_1_native_match_constructor_operands_1{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_3: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_constructor_operands_2{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_6: cps_provider_10_Registry, v_7: Ast.SourceSpan, v_9: List<&2, IR.Occurrence>, v_11: List<&2, IR.CheckedBinding>}
  EmitterRequest_cps_provider_1_native_match_constructor_operands_3{v_1: List<&2, IR.Occurrence>, v_3: List<&2, IR.CheckedBinding>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_constructor_operands{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_reference{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_DefinitionHeader>, v_5: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_reference_kind_0{v_1: Bool, v_3: Maybe<&2, BIR.Primitive>, v_6: Maybe<&2, cps_provider_10_Foreign>, v_8: List<&2, BIR.Parameter>, v_10: cps_provider_1_State, v_12: String, v_14: U32}
  EmitterRequest_cps_provider_1_reference_kind{v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Bool, v_11: Maybe<&2, BIR.Primitive>, v_14: Maybe<&2, cps_provider_10_Foreign>}
  EmitterRequest_cps_provider_1_symbol_value{v_1: cps_provider_1_State, v_2: IR.Symbol, v_4: cps_provider_10_Registry, v_5: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_string_authorized{v_1: cps_provider_10_Registry, v_3: List<&2, IR.Symbol>, v_6: List<&2, String>}
  EmitterRequest_cps_provider_1_string_authorized_found{v_2: Maybe<&2, cps_provider_10_Constructor>, v_4: cps_provider_10_Registry, v_6: String, v_8: List<&2, IR.Symbol>, v_11: List<&2, String>}
  EmitterRequest_cps_provider_1_literal_characters{v_2: List<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_literal_word_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Registry, v_4: IR.Symbol, v_5: Ast.SourceSpan, v_6: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_literal_word_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Registry, v_5: U32, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: Ast.SourceSpan, v_12: Nat}
  EmitterRequest_cps_provider_1_native_match_literal_word_2{v_1: Nat, v_3: cps_provider_1_State, v_5: cps_provider_10_Registry, v_7: U32, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_literal_word{v_1: cps_provider_1_State, v_3: cps_provider_10_Registry, v_5: Nat, v_7: U32, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_literal_bit{v_1: cps_provider_1_State, v_3: cps_provider_10_Registry, v_5: Bool, v_6: IR.Symbol, v_7: IR.Symbol, v_8: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_literal_string{v_1: cps_provider_1_State, v_3: cps_provider_10_Registry, v_6: List<&2, U32>, v_8: List<&2, IR.Symbol>, v_9: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_literal_string_authorized{v_1: cps_provider_1_State, v_3: cps_provider_10_Registry, v_6: List<&2, U32>, v_8: List<&2, IR.Symbol>, v_9: Ast.SourceSpan, v_11: Bool}
  EmitterRequest_cps_provider_1_literal_string_records{v_1: cps_provider_1_State, v_3: cps_provider_10_Registry, v_6: List<&2, U32>, v_8: List<&2, IR.Symbol>, v_9: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_literal_string_items_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Registry, v_4: IR.Symbol, v_5: Ast.SourceSpan, v_6: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_literal_string_items_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Registry, v_4: IR.Symbol, v_5: IR.Symbol, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: Ast.SourceSpan, v_15: List<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_literal_string_items_2{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Registry, v_4: IR.Symbol, v_5: IR.Symbol, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: Ast.SourceSpan, v_15: List<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_literal_string_items_3{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Registry, v_4: IR.Symbol, v_5: IR.Symbol, v_6: IR.Symbol, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: Ast.SourceSpan, v_15: List<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_literal_string_items_4{v_2: List<&2, U32>, v_4: cps_provider_1_State, v_6: cps_provider_10_Registry, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: IR.Symbol, v_15: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_literal_string_items{v_1: cps_provider_1_State, v_3: cps_provider_10_Registry, v_6: List<&2, U32>, v_7: IR.Symbol, v_8: IR.Symbol, v_9: IR.Symbol, v_10: IR.Symbol, v_11: IR.Symbol, v_12: IR.Symbol, v_13: IR.Symbol, v_14: IR.Symbol, v_15: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_spine_0{v_1: cps_provider_1_LowerResult<Arena.Node>, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, IR.Occurrence>}

type EmitterRequestGroup2 is Type:
  EmitterRequest_cps_provider_1_native_match_spine_1{v_0: IR.Occurrence, v_2: cps_provider_1_State, v_5: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_spine{v_1: cps_provider_1_State, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_spine_shape{v_1: cps_provider_1_State, v_2: Arena.Node, v_3: IR.Occurrence, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_head_definition{v_0: IR.Occurrence, v_2: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_applications{v_1: cps_provider_1_State, v_3: cps_provider_1_Spine, v_5: U32, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_application_header_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_application_header_1{v_2: Maybe<&2, cps_provider_10_DefinitionHeader>, v_4: cps_provider_1_State, v_5: IR.Occurrence, v_8: List<&2, cps_provider_1_SourceArgument>, v_10: U32, v_13: List<&2, cps_provider_1_Slot>, v_15: cps_provider_10_Registry, v_16: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_application_header{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_DefinitionHeader>, v_5: IR.Occurrence, v_8: List<&2, cps_provider_1_SourceArgument>, v_10: U32, v_13: List<&2, cps_provider_1_Slot>, v_15: cps_provider_10_Registry, v_16: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_application_known{v_1: cps_provider_1_State, v_3: Maybe<&2, BIR.Primitive>, v_5: Bool, v_7: U32, v_9: List<&2, BIR.Parameter>, v_11: Nat, v_12: IR.Occurrence, v_15: List<&2, cps_provider_1_SourceArgument>, v_17: U32, v_20: List<&2, cps_provider_1_Slot>, v_22: cps_provider_10_Registry, v_23: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_application_native_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_application_native_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_6: cps_provider_10_Registry, v_9: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_native_match_application_native_2{v_6: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, cps_provider_1_SourceArgument>>, v_7: BIR.Primitive, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_14: cps_provider_1_State, v_17: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_application_native_3{v_5: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>, v_6: BIR.Primitive, v_9: List<&2, cps_provider_1_Slot>, v_11: cps_provider_10_Registry, v_14: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_arrow_facts{v_0: BIR.Descriptor, v_2: Nat}
  EmitterRequest_cps_provider_1_arrow_facts_rest{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_1_last_domain{v_1: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_1_last_domain_rest{v_1: List<&2, BIR.Descriptor>, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_1_first_element_argument{v_1: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_1_first_map_argument{v_1: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_1_partial_element{v_0: BIR.Primitive, v_2: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_1_parameterize{v_1: List<&2, BIR.Parameter>, v_3: List<&2, BIR.Use>}
  EmitterRequest_cps_provider_1_partial_array_parameters{v_1: cps_provider_1_State, v_3: List<&2, BIR.Use>}
  EmitterRequest_cps_provider_1_partial_array_code{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor}
  EmitterRequest_cps_provider_1_partial_block{+v_1: U32, v_2: BIR.Op}
  EmitterRequest_cps_provider_1_partial_call{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Parameter>, v_5: BIR.Descriptor}
  EmitterRequest_cps_provider_1_partial_array_body{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor, +v_9: U32}
  EmitterRequest_cps_provider_1_capture_argument_uses{v_1: List<&2, BIR.Arg>}
  EmitterRequest_cps_provider_1_partial_array_build{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: U32, v_6: List<&2, BIR.Arg>, v_8: Nat}
  EmitterRequest_cps_provider_1_partial_array_described{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: U32, v_6: List<&2, BIR.Arg>, v_8: Nat}
  EmitterRequest_cps_provider_1_partial_array_facts{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: cps_provider_1_ArrowFacts, v_6: List<&2, BIR.Arg>}
  EmitterRequest_cps_provider_1_partial_array_typed{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Use>, v_6: List<&2, BIR.Arg>, v_7: BIR.Descriptor}
  EmitterRequest_cps_provider_1_partial_array_call{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_5: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, BIR.Parameter>, v_9: U32, v_12: List<&2, cps_provider_1_Slot>, v_14: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_partial_typed{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_4: List<&2, BIR.Arg>, v_6: List<&2, BIR.Parameter>, v_7: BIR.Descriptor}
  EmitterRequest_cps_provider_1_application_native_partial{v_1: cps_provider_1_State, v_2: BIR.Primitive, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_SourceArgument>, v_8: List<&2, BIR.Parameter>, v_10: U32, v_13: List<&2, cps_provider_1_Slot>, v_15: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_application_native_4{v_1: Bool, v_3: cps_provider_1_State, v_4: BIR.Primitive, v_6: Nat, v_7: IR.Occurrence, v_10: List<&2, cps_provider_1_SourceArgument>, v_12: List<&2, BIR.Parameter>, v_14: U32, v_17: List<&2, cps_provider_1_Slot>, v_19: cps_provider_10_Registry, v_22: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_application_native{v_1: cps_provider_1_State, v_3: Bool, v_4: BIR.Primitive, v_6: Nat, v_7: IR.Occurrence, v_10: List<&2, cps_provider_1_SourceArgument>, v_12: List<&2, BIR.Parameter>, v_14: U32, v_17: List<&2, cps_provider_1_Slot>, v_19: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_application_direct_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_application_direct_1{v_6: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, cps_provider_1_SourceArgument>>, v_8: U32, v_10: List<&2, BIR.Parameter>, v_12: Nat, v_15: List<&2, cps_provider_1_Slot>, v_17: cps_provider_10_Registry, v_18: Ast.SourceSpan, v_20: Nat, v_22: cps_provider_1_State}
  EmitterRequest_cps_provider_1_native_match_application_direct_2{v_5: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>, v_7: U32, v_9: List<&2, BIR.Parameter>, v_11: Nat, v_14: List<&2, cps_provider_1_Slot>, v_16: cps_provider_10_Registry, v_17: Ast.SourceSpan, v_19: Nat}
  EmitterRequest_cps_provider_1_native_match_application_direct_3{v_1: Bool, v_3: cps_provider_1_State, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_10: IR.Occurrence, v_13: List<&2, cps_provider_1_SourceArgument>, v_16: List<&2, cps_provider_1_Slot>, v_18: cps_provider_10_Registry, v_19: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_application_direct{v_1: cps_provider_1_State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: Nat, v_10: IR.Occurrence, v_13: List<&2, cps_provider_1_SourceArgument>, v_16: List<&2, cps_provider_1_Slot>, v_18: cps_provider_10_Registry, v_19: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_application_direct_values_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_SourceArgument>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_application_direct_values_1{v_1: Bool, v_3: cps_provider_1_State, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Arg>, v_12: List<&2, cps_provider_1_SourceArgument>, v_15: List<&2, cps_provider_1_Slot>, v_17: cps_provider_10_Registry, v_18: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_application_direct_values{v_1: cps_provider_1_State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Arg>, v_12: List<&2, cps_provider_1_SourceArgument>, v_15: List<&2, cps_provider_1_Slot>, v_17: cps_provider_10_Registry, v_18: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_direct_arity{v_1: cps_provider_1_State, v_3: Bool, v_5: U32, v_7: List<&2, BIR.Arg>, v_8: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_argument_prefix_0{v_6: Sigma<&1, &1, List<&2, BIR.Arg>, _ => List<&2, cps_provider_1_SourceArgument>>, v_7: Ast.Quantity, v_8: BIR.Atom, v_10: cps_provider_1_State}
  EmitterRequest_cps_provider_1_native_match_argument_prefix_1{v_5: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>, v_6: Ast.Quantity, v_7: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_argument_prefix_2{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_6: cps_provider_10_Registry, v_8: Nat, v_9: Ast.Quantity, v_12: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_native_match_argument_prefix_3{v_1: Nat, v_4: List<&2, cps_provider_1_SourceArgument>, v_6: cps_provider_1_State, v_9: List<&2, cps_provider_1_Slot>, v_11: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_argument_prefix{v_1: cps_provider_1_State, v_3: Nat, v_6: List<&2, cps_provider_1_SourceArgument>, v_9: List<&2, cps_provider_1_Slot>, v_11: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_apply_rest_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_6: cps_provider_10_Registry, v_9: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_native_match_apply_rest_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: BIR.Atom, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry, v_8: Ast.Quantity, v_11: List<&2, cps_provider_1_SourceArgument>}
  EmitterRequest_cps_provider_1_native_match_apply_rest_2{v_2: List<&2, cps_provider_1_SourceArgument>, v_4: cps_provider_1_State, v_5: BIR.Atom, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_apply_rest{v_1: cps_provider_1_State, v_2: BIR.Atom, v_5: List<&2, cps_provider_1_SourceArgument>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_drop_parameters{v_1: Nat, v_3: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_argument_uses{v_1: List<&2, BIR.Arg>}
  EmitterRequest_cps_provider_1_indexed_captures{v_1: List<&2, BIR.Arg>, v_3: U32}
  EmitterRequest_cps_provider_1_parameter_arguments{v_1: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_native_match_partial_0{v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_native_match_partial_1{v_1: List<&2, BIR.Parameter>, v_3: cps_provider_1_State, v_5: U32, v_7: List<&2, BIR.Arg>}
  EmitterRequest_cps_provider_1_partial{v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_tag{v_1: cps_provider_1_State, v_3: cps_provider_10_Constructor, v_4: BIR.Atom, v_7: Maybe<&2, U32>, v_9: Bool}
  EmitterRequest_cps_provider_1_tag_native{v_1: cps_provider_1_State, v_3: String, v_5: cps_provider_10_Constructor, v_6: BIR.Atom, v_9: Maybe<&2, U32>, v_11: Bool}
  EmitterRequest_cps_provider_1_project{v_1: cps_provider_1_State, v_3: cps_provider_10_Constructor, v_4: BIR.Atom, v_6: U32, v_7: Ast.SourceSpan, v_10: Maybe<&2, U32>, v_12: Bool}

type EmitterRequestGroup3 is Type:
  EmitterRequest_cps_provider_1_project_native{v_1: cps_provider_1_State, v_3: String, v_5: cps_provider_10_Constructor, v_6: BIR.Atom, v_8: U32, v_9: Ast.SourceSpan, v_12: Maybe<&2, U32>, v_14: Bool}
  EmitterRequest_cps_provider_1_project_field{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_ConstructorField>, v_6: cps_provider_10_Constructor, v_7: BIR.Atom, v_8: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_pattern_identity{v_0: IR.CheckedPattern, v_2: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_pattern_identity_found{v_2: Maybe<&2, cps_provider_10_Constructor>}
  EmitterRequest_cps_provider_1_closed_bit{v_0: IR.CheckedPattern, v_2: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_closed_bit_identity{v_1: String}
  EmitterRequest_cps_provider_1_closed_word{v_1: Nat, v_2: IR.CheckedPattern, v_4: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_closed_word_identity{v_1: Nat, v_3: String, v_4: IR.CheckedPattern, v_6: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_closed_word_parts{v_2: Maybe<&2, U32>, v_5: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_closed_scalar{v_1: String, v_3: List<&2, IR.CheckedPattern>, v_5: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_erase_pattern{v_0: IR.CheckedPattern, v_3: List<&2, cps_provider_1_Slot>}
  EmitterRequest_cps_provider_1_erase_patterns{v_1: List<&2, IR.CheckedPattern>, v_4: List<&2, cps_provider_1_Slot>}
  EmitterRequest_cps_provider_1_native_match_patterns_0{v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: cps_provider_10_Registry, v_6: BIR.Block, v_8: List<&2, IR.CheckedPattern>, v_10: List<&2, BIR.Atom>}
  EmitterRequest_cps_provider_1_native_match_patterns_1{v_1: List<&2, IR.CheckedPattern>, v_3: List<&2, BIR.Atom>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: BIR.Block}
  EmitterRequest_cps_provider_1_patterns{v_1: cps_provider_1_State, v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: BIR.Block}
  EmitterRequest_cps_provider_1_native_match_pattern_0{v_2: cps_provider_1_LowerResult<cps_provider_1_Slot>, v_5: List<&2, cps_provider_1_Slot>}
  EmitterRequest_cps_provider_1_native_match_pattern_1{v_0: IR.CheckedPattern, v_2: cps_provider_1_State, v_3: BIR.Atom, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_9: BIR.Block}
  EmitterRequest_cps_provider_1_pattern{v_1: cps_provider_1_State, v_2: IR.CheckedPattern, v_3: BIR.Atom, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_9: BIR.Block}
  EmitterRequest_cps_provider_1_pattern_constructor{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_Constructor>, v_6: List<&2, IR.CheckedPattern>, v_8: List<&2, IR.CheckedBinding>, v_9: BIR.Atom, v_12: List<&2, cps_provider_1_Slot>, v_14: cps_provider_10_Registry, v_15: BIR.Block}
  EmitterRequest_cps_provider_1_native_match_pattern_scalar_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_5: BIR.Block}
  EmitterRequest_cps_provider_1_native_match_pattern_scalar_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Constructor, v_5: List<&2, IR.CheckedPattern>, v_7: List<&2, IR.CheckedBinding>, v_8: BIR.Atom, v_11: List<&2, cps_provider_1_Slot>, v_13: cps_provider_10_Registry, v_14: BIR.Block, v_17: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_pattern_scalar_2{v_2: Maybe<&2, U32>, v_4: cps_provider_1_State, v_6: cps_provider_10_Constructor, v_8: List<&2, IR.CheckedPattern>, v_10: List<&2, IR.CheckedBinding>, v_11: BIR.Atom, v_14: List<&2, cps_provider_1_Slot>, v_16: cps_provider_10_Registry, v_17: BIR.Block, v_20: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_pattern_scalar{v_1: cps_provider_1_State, v_4: Maybe<&2, U32>, v_6: cps_provider_10_Constructor, v_8: List<&2, IR.CheckedPattern>, v_10: List<&2, IR.CheckedBinding>, v_11: BIR.Atom, v_14: List<&2, cps_provider_1_Slot>, v_16: cps_provider_10_Registry, v_17: BIR.Block, v_20: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_scalar_test{v_1: cps_provider_1_State, v_3: Bool, v_4: BIR.Atom, v_6: U32}
  EmitterRequest_cps_provider_1_native_match_pattern_fields_0{v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: cps_provider_10_Constructor, v_6: BIR.Atom, v_8: U32, v_10: cps_provider_10_Registry, v_11: BIR.Block, v_13: List<&2, IR.CheckedPattern>, v_15: List<&2, IR.CheckedBinding>, v_18: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_pattern_fields_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Constructor, v_4: BIR.Atom, v_6: U32, v_9: List<&2, cps_provider_1_Slot>, v_11: cps_provider_10_Registry, v_12: BIR.Block, v_13: IR.CheckedPattern, v_15: List<&2, IR.CheckedPattern>, v_17: List<&2, IR.CheckedBinding>, v_20: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_pattern_fields_2{v_1: List<&2, IR.CheckedPattern>, v_3: List<&2, IR.CheckedBinding>, v_5: cps_provider_1_State, v_7: cps_provider_10_Constructor, v_8: BIR.Atom, v_10: U32, v_13: List<&2, cps_provider_1_Slot>, v_15: cps_provider_10_Registry, v_16: BIR.Block, v_19: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_pattern_fields{v_1: cps_provider_1_State, v_3: cps_provider_10_Constructor, v_5: List<&2, IR.CheckedPattern>, v_7: List<&2, IR.CheckedBinding>, v_8: BIR.Atom, v_10: U32, v_13: List<&2, cps_provider_1_Slot>, v_15: cps_provider_10_Registry, v_16: BIR.Block, v_19: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_lower_values_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_3: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_lower_values_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_6: cps_provider_10_Registry, v_8: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_native_match_lower_values_2{v_1: List<&2, IR.Occurrence>, v_3: cps_provider_1_State, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_lower_values{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_new_parameters_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>, v_4: U32}
  EmitterRequest_cps_provider_1_native_match_new_parameters_1{v_2: cps_provider_1_LowerResult<U32>, v_4: Nat}
  EmitterRequest_cps_provider_1_native_match_new_parameters_2{v_1: Nat, v_3: cps_provider_1_State}
  EmitterRequest_cps_provider_1_new_parameters{v_1: cps_provider_1_State, v_3: Nat}
  EmitterRequest_cps_provider_1_parameter_values{v_1: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_native_match_checked_cases_0{v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: U32, v_4: BIR.Block}
  EmitterRequest_cps_provider_1_native_match_checked_cases_1{v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: List<&2, BIR.Atom>, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_10: List<&2, IR.Occurrence>, v_12: U32}
  EmitterRequest_cps_provider_1_native_match_checked_cases_2{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: List<&2, BIR.Atom>, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_10: List<&2, IR.Occurrence>, v_12: U32}
  EmitterRequest_cps_provider_1_native_match_checked_cases_3{v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: IR.Occurrence, v_13: List<&2, IR.Occurrence>, v_15: U32}
  EmitterRequest_cps_provider_1_native_match_checked_cases_4{v_2: cps_provider_1_LowerResult<U32>, v_4: List<&2, BIR.Atom>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry, v_11: List<&2, IR.CheckedPattern>, v_12: IR.Occurrence, v_14: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_native_match_checked_cases_5{v_1: List<&2, IR.Occurrence>, v_3: cps_provider_1_State, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_checked_cases{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_take_block{v_1: cps_provider_1_State, v_2: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_match_values_0{v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>, v_4: List<&2, BIR.Atom>}
  EmitterRequest_cps_provider_1_native_match_match_values_1{v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: List<&2, BIR.Atom>, v_5: cps_provider_1_Frame, v_7: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_native_match_match_values_2{v_2: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>, v_4: List<&2, IR.Occurrence>, v_6: List<&2, BIR.Atom>, v_9: List<&2, cps_provider_1_Slot>, v_11: cps_provider_10_Registry, v_13: cps_provider_1_Frame}
  EmitterRequest_cps_provider_1_native_match_match_values_3{v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_4: List<&2, IR.Occurrence>, v_6: List<&2, BIR.Atom>, v_9: List<&2, cps_provider_1_Slot>, v_11: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_match_values{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_split_occurrences_0{v_5: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_6: IR.Occurrence}
  EmitterRequest_cps_provider_1_native_match_split_occurrences_1{v_1: U32, v_3: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_split_occurrences{v_1: U32, v_3: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_native_match_lower_match_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry, v_9: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_native_match_lower_match_1{v_5: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_7: cps_provider_1_State, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_lower_match{v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_occurrence_term{v_0: IR.Occurrence}
  EmitterRequest_cps_provider_1_native_match_lower_0{v_1: cps_provider_1_LowerResult<Arena.Node>, v_4: List<&2, cps_provider_1_Slot>, v_6: cps_provider_10_Registry, v_8: U32, v_10: Maybe<&2, Ast.Quantity>, v_12: Maybe<&2, IR.Symbol>, v_14: List<&2, IR.CheckedBinding>, v_16: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_native_match_lower_1{v_1: cps_provider_1_LowerResult<Arena.Node>, v_4: List<&2, cps_provider_1_Slot>}
  EmitterRequest_cps_provider_1_native_match_lower_2{v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: cps_provider_10_Registry, v_6: IR.Occurrence}
  EmitterRequest_cps_provider_1_native_match_lower_3{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry, v_9: List<&2, IR.CheckedPattern>, v_10: IR.Occurrence}
  EmitterRequest_cps_provider_1_native_match_lower_4{v_0: IR.Occurrence, v_2: cps_provider_1_State, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_lower_occurrence{v_1: cps_provider_1_State, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_lexical_reference{v_1: cps_provider_1_State, v_2: Arena.Node, v_5: List<&2, cps_provider_1_Slot>}

type EmitterRequestGroup4 is Type:
  EmitterRequest_cps_provider_1_native_match_lower_node_0{v_2: cps_provider_1_LowerResult<String>}
  EmitterRequest_cps_provider_1_native_match_lower_node_1{v_0: Arena.Node, v_2: cps_provider_1_State, v_4: U32, v_6: Maybe<&2, Ast.Quantity>, v_8: Maybe<&2, IR.Symbol>, v_10: List<&2, IR.CheckedBinding>, v_12: List<&2, IR.Occurrence>, v_15: List<&2, cps_provider_1_Slot>, v_17: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_lower_node{v_1: cps_provider_1_State, v_2: Arena.Node, v_4: U32, v_6: Maybe<&2, Ast.Quantity>, v_8: Maybe<&2, IR.Symbol>, v_10: List<&2, IR.CheckedBinding>, v_12: List<&2, IR.Occurrence>, v_15: List<&2, cps_provider_1_Slot>, v_17: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_resolved_reference{v_1: cps_provider_1_State, v_3: Maybe<&2, IR.Symbol>, v_5: cps_provider_10_Registry, v_6: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_only_child{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_9: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_annotated_child{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_9: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_rewrite_checked{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_9: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_application_checked_0{v_2: cps_provider_1_LowerResult<cps_provider_1_Spine>, v_4: U32, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry, v_10: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_application_checked_1{v_1: Maybe<&2, Ast.Quantity>, v_3: List<&2, IR.Occurrence>, v_5: cps_provider_1_State, v_7: U32, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_application_checked{v_1: cps_provider_1_State, v_3: U32, v_5: Maybe<&2, Ast.Quantity>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_constructor_checked_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_4: cps_provider_10_Registry, v_5: Ast.SourceSpan, v_6: IR.Symbol, v_9: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_constructor_checked_1{v_1: Maybe<&2, IR.Symbol>, v_3: cps_provider_1_State, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_constructor_checked{v_1: cps_provider_1_State, v_3: Maybe<&2, IR.Symbol>, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_lambda_checked_0{v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>}
  EmitterRequest_cps_provider_1_native_match_lambda_checked_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32}
  EmitterRequest_cps_provider_1_native_match_lambda_checked_2{v_2: cps_provider_1_LowerResult<cps_provider_1_Slot>, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry, v_8: Ast.Quantity, v_9: IR.Occurrence, v_11: cps_provider_1_Frame, v_13: U32}
  EmitterRequest_cps_provider_1_native_match_lambda_checked_3{v_2: cps_provider_1_LowerResult<U32>, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry, v_8: Ast.Quantity, v_9: IR.Occurrence, v_11: cps_provider_1_Frame}
  EmitterRequest_cps_provider_1_native_match_lambda_checked_4{v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry, v_8: Ast.Quantity, v_9: IR.Occurrence}
  EmitterRequest_cps_provider_1_native_match_lambda_checked_5{v_1: Maybe<&2, Ast.Quantity>, v_3: List<&2, IR.Occurrence>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_lambda_checked{v_1: cps_provider_1_State, v_3: Maybe<&2, Ast.Quantity>, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_absurd_checked_0{v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>}
  EmitterRequest_cps_provider_1_native_match_absurd_checked_1{v_2: cps_provider_1_LowerResult<U32>, v_3: Ast.Quantity, v_5: cps_provider_1_Frame}
  EmitterRequest_cps_provider_1_native_match_absurd_checked_2{v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_3: Ast.Quantity}
  EmitterRequest_cps_provider_1_native_match_absurd_checked_3{v_1: Maybe<&2, Ast.Quantity>, v_3: cps_provider_1_State, v_4: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_absurd_checked{v_1: cps_provider_1_State, v_3: Maybe<&2, Ast.Quantity>, v_4: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_local_values_0{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>}
  EmitterRequest_cps_provider_1_native_match_local_values_1{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_3: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_local_values_2{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_6: cps_provider_10_Registry, v_8: List<&2, IR.CheckedPattern>, v_10: List<&2, IR.Occurrence>}
  EmitterRequest_cps_provider_1_native_match_local_values_3{v_1: List<&2, IR.CheckedPattern>, v_3: List<&2, IR.Occurrence>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_local_values{v_1: cps_provider_1_State, v_3: List<&2, IR.CheckedPattern>, v_5: List<&2, IR.Occurrence>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_let_checked_0{v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: cps_provider_10_Registry, v_6: IR.Occurrence}
  EmitterRequest_cps_provider_1_native_match_let_checked_1{v_5: Sigma<&1, &1, List<&2, IR.Occurrence>, _ => List<&2, IR.Occurrence>>, v_7: cps_provider_1_State, v_9: List<&2, IR.CheckedBinding>, v_12: List<&2, cps_provider_1_Slot>, v_14: cps_provider_10_Registry, v_15: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_let_checked{v_1: cps_provider_1_State, v_3: U32, v_5: List<&2, IR.CheckedBinding>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_let_bindings_0{v_2: cps_provider_1_LowerResult<cps_provider_1_Slot>, v_5: List<&2, cps_provider_1_Slot>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan, v_13: List<&2, IR.Occurrence>, v_15: List<&2, IR.CheckedBinding>}
  EmitterRequest_cps_provider_1_native_match_let_bindings_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_4: List<&2, cps_provider_1_Slot>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry, v_10: Ast.SourceSpan, v_12: List<&2, IR.Occurrence>, v_13: Ast.Quantity, v_15: List<&2, IR.CheckedBinding>}
  EmitterRequest_cps_provider_1_native_match_let_bindings_2{v_1: List<&2, IR.Occurrence>, v_3: List<&2, IR.CheckedBinding>, v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_11: List<&2, cps_provider_1_Slot>, v_13: cps_provider_10_Registry, v_14: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_let_bindings{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, IR.CheckedBinding>, v_8: List<&2, cps_provider_1_Slot>, v_11: List<&2, cps_provider_1_Slot>, v_13: cps_provider_10_Registry, v_14: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_scalar_literal{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_Constructor>, v_6: U32, v_8: List<&2, IR.Symbol>, v_10: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_scalar_literal_native_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_1_native_match_scalar_literal_native_1{v_1: List<&2, IR.Symbol>, v_3: cps_provider_1_State, v_5: cps_provider_10_Constructor, v_7: U32, v_9: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_native_match_scalar_literal_native_2{v_1: String, v_3: cps_provider_1_State, v_5: cps_provider_10_Constructor, v_7: U32, v_9: List<&2, IR.Symbol>, v_11: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_scalar_literal_native{v_1: cps_provider_1_State, v_3: String, v_5: cps_provider_10_Constructor, v_7: U32, v_9: List<&2, IR.Symbol>, v_11: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_take_instructions{v_1: cps_provider_1_State}
  EmitterRequest_cps_provider_1_matcher_checked{v_1: cps_provider_1_State, v_3: Maybe<&2, Ast.Quantity>, v_5: Maybe<&2, IR.Symbol>, v_7: List<&2, IR.Occurrence>, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_0{v_2: cps_provider_1_LowerResult<cps_provider_1_CodeRef>}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_1{v_1: cps_provider_1_LowerResult<BIR.Block>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32, v_7: BIR.Atom, v_10: List<&2, cps_provider_1_Instruction>, v_11: BIR.Block}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_2{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32, v_7: BIR.Atom, v_10: List<&2, cps_provider_1_Instruction>, v_11: BIR.Block}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_3{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_4: cps_provider_1_Frame, v_6: U32, v_7: BIR.Atom, v_10: List<&2, cps_provider_1_Instruction>, v_11: BIR.Block}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_4{v_1: cps_provider_1_LowerResult<BIR.Block>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_10: cps_provider_1_Frame, v_12: U32, v_13: BIR.Atom, v_16: List<&2, cps_provider_1_Instruction>}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_5{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_10: cps_provider_1_Frame, v_12: U32, v_13: BIR.Atom, v_16: List<&2, cps_provider_1_Instruction>}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_6{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry, v_9: Ast.SourceSpan, v_11: cps_provider_10_Constructor, v_13: cps_provider_1_Frame, v_15: U32, v_16: BIR.Atom, v_19: List<&2, cps_provider_1_Instruction>, v_22: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_7{v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Instruction>>, v_4: Ast.Quantity, v_5: IR.Occurrence, v_6: IR.Occurrence, v_9: List<&2, cps_provider_1_Slot>, v_11: cps_provider_10_Registry, v_12: Ast.SourceSpan, v_14: cps_provider_10_Constructor, v_16: cps_provider_1_Frame, v_18: U32, v_19: BIR.Atom}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_8{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_2: Ast.Quantity, v_3: IR.Occurrence, v_4: IR.Occurrence, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry, v_10: Ast.SourceSpan, v_12: cps_provider_10_Constructor, v_14: cps_provider_1_Frame, v_16: U32}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_9{v_2: cps_provider_1_LowerResult<U32>, v_3: Ast.Quantity, v_4: IR.Occurrence, v_5: IR.Occurrence, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan, v_13: cps_provider_10_Constructor, v_15: cps_provider_1_Frame}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_10{v_2: cps_provider_1_LowerResult<cps_provider_1_Frame>, v_3: Ast.Quantity, v_4: IR.Occurrence, v_5: IR.Occurrence, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_11: Ast.SourceSpan, v_13: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_1_native_match_matcher_constructor_11{v_2: Maybe<&2, cps_provider_10_Constructor>, v_4: cps_provider_1_State, v_5: Ast.Quantity, v_6: IR.Occurrence, v_7: IR.Occurrence, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_matcher_constructor{v_1: cps_provider_1_State, v_4: Maybe<&2, cps_provider_10_Constructor>, v_5: Ast.Quantity, v_6: IR.Occurrence, v_7: IR.Occurrence, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry, v_13: Ast.SourceSpan}
  EmitterRequest_cps_provider_1_constructor_quantities{v_1: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_1_matcher_field_use{v_0: BIR.Quantity, v_1: Ast.Quantity}
  EmitterRequest_cps_provider_1_native_match_matcher_fields_0{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Constructor, v_4: BIR.Atom, v_6: U32, v_7: Ast.Quantity, v_8: Ast.SourceSpan, v_10: List<&2, BIR.Quantity>, v_13: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_matcher_fields_1{v_1: cps_provider_1_LowerResult<BIR.Atom>, v_3: cps_provider_10_Constructor, v_4: BIR.Atom, v_6: U32, v_7: BIR.Atom, v_8: Ast.Quantity, v_9: Ast.SourceSpan, v_10: BIR.Quantity, v_12: List<&2, BIR.Quantity>, v_15: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_matcher_fields_2{v_1: List<&2, BIR.Quantity>, v_3: cps_provider_1_State, v_5: cps_provider_10_Constructor, v_6: BIR.Atom, v_8: U32, v_9: BIR.Atom, v_10: Ast.Quantity, v_11: Ast.SourceSpan, v_14: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_matcher_fields{v_1: cps_provider_1_State, v_3: cps_provider_10_Constructor, v_5: List<&2, BIR.Quantity>, v_6: BIR.Atom, v_8: U32, v_9: BIR.Atom, v_10: Ast.Quantity, v_11: Ast.SourceSpan, v_14: Maybe<&2, U32>}
  EmitterRequest_cps_provider_1_native_match_definition_frame_0{v_1: cps_provider_1_State, v_3: U32, v_4: Scope.ArenaGlobalScope}

type EmitterRequestGroup5 is Type:
  EmitterRequest_cps_provider_1_definition_frame{v_1: cps_provider_1_State, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_1_definition_env{v_1: cps_provider_1_State, v_3: List<&2, BIR.Quantity>, v_5: List<&2, BIR.Parameter>, v_7: U32, v_10: List<&2, cps_provider_1_Slot>}
  EmitterRequest_cps_provider_1_definitions{v_1: cps_provider_1_State, v_4: List<&2, cps_provider_10_Definition>, v_6: cps_provider_10_Registry, v_8: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_1_definition{v_1: cps_provider_1_State, v_3: cps_provider_10_DefinitionHeader, v_5: Maybe<&2, IR.Occurrence>, v_8: List<&2, cps_provider_10_Definition>, v_10: cps_provider_10_Registry, v_12: List<&2, BIR.Declaration>, v_13: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_1_definition_kind{v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_11: Bool, v_13: Maybe<&2, BIR.Primitive>, v_16: Maybe<&2, cps_provider_10_Foreign>, v_18: Maybe<&2, IR.Occurrence>, v_21: List<&2, cps_provider_10_Definition>, v_23: cps_provider_10_Registry, v_25: List<&2, BIR.Declaration>, v_26: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_1_definition_local{v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_11: Bool, v_13: Maybe<&2, BIR.Primitive>, v_15: Maybe<&2, IR.Occurrence>, v_18: List<&2, cps_provider_10_Definition>, v_20: cps_provider_10_Registry, v_22: List<&2, BIR.Declaration>, v_23: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_1_definition_parameter{v_1: U32, v_3: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_definition_locals{v_1: List<&2, BIR.Atom>, v_3: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_definition_locals_frame{v_1: cps_provider_1_Frame, v_3: List<&2, BIR.Atom>, v_5: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_definition_atom_block{v_1: cps_provider_1_LowerResult<BIR.Atom>}
  EmitterRequest_cps_provider_1_definition_match_direct{v_1: Bool, v_3: cps_provider_1_State, v_5: List<&2, IR.Occurrence>, v_7: List<&2, BIR.Atom>, v_10: List<&2, cps_provider_1_Slot>, v_12: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_definition_match_state{v_1: cps_provider_1_State, v_3: List<&2, IR.Occurrence>, v_5: List<&2, BIR.Atom>, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_12: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_definition_match_values{v_2: cps_provider_1_LowerResult<List<&2, BIR.Atom>>, v_4: List<&2, IR.Occurrence>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry, v_11: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_definition_match_parts{v_3: Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>), v_5: cps_provider_1_State, v_8: List<&2, cps_provider_1_Slot>, v_10: cps_provider_10_Registry, v_12: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_definition_root_node{v_1: cps_provider_1_LowerResult<Arena.Node>, v_2: IR.Occurrence, v_4: List<&2, IR.Occurrence>, v_7: List<&2, cps_provider_1_Slot>, v_9: cps_provider_10_Registry, v_11: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_definition_root_other{v_0: IR.Occurrence, v_2: cps_provider_1_State, v_3: Arena.Node, v_6: List<&2, cps_provider_1_Slot>, v_8: cps_provider_10_Registry}
  EmitterRequest_cps_provider_1_definition_root{v_1: cps_provider_1_State, v_2: IR.Occurrence, v_5: List<&2, cps_provider_1_Slot>, v_7: cps_provider_10_Registry, v_9: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_1_native_match_definition_body_0{v_1: cps_provider_1_LowerResult<BIR.Block>, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_10: List<&2, cps_provider_10_Definition>, v_12: cps_provider_10_Registry, v_14: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_1_native_match_definition_body_2{v_3: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_12: List<&2, cps_provider_10_Definition>, v_14: cps_provider_10_Registry, v_16: List<&2, BIR.Declaration>, v_17: IR.Occurrence}
  EmitterRequest_cps_provider_1_native_match_definition_body_3{v_1: Maybe<&2, IR.Occurrence>, v_3: cps_provider_1_State, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_11: List<&2, BIR.Quantity>, v_14: List<&2, cps_provider_10_Definition>, v_16: cps_provider_10_Registry, v_18: List<&2, BIR.Declaration>, v_19: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_1_definition_body{v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_9: List<&2, BIR.Quantity>, v_11: Maybe<&2, IR.Occurrence>, v_14: List<&2, cps_provider_10_Definition>, v_16: cps_provider_10_Registry, v_18: List<&2, BIR.Declaration>, v_19: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_1_definition_complete{v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, v_11: List<&2, cps_provider_10_Definition>, v_13: cps_provider_10_Registry, v_15: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_1_native_match_definition_closed_0{v_1: cps_provider_1_State, v_3: String, v_5: U32, v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, v_11: List<&2, cps_provider_10_Definition>, v_13: cps_provider_10_Registry, v_15: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_1_native_match_definition_closed_1{v_1: Bool, v_3: List<&2, BIR.Parameter>, v_5: cps_provider_1_State, v_7: String, v_9: U32, v_10: BIR.Block, v_13: List<&2, cps_provider_10_Definition>, v_15: cps_provider_10_Registry, v_17: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_1_definition_closed{v_1: Bool, v_3: cps_provider_1_State, v_5: String, v_7: U32, v_9: List<&2, BIR.Parameter>, v_10: BIR.Block, v_13: List<&2, cps_provider_10_Definition>, v_15: cps_provider_10_Registry, v_17: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_1_native_match_template_binders_0{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_5: U32, v_7: U32}
  EmitterRequest_cps_provider_1_native_match_template_binders_1{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32}
  EmitterRequest_cps_provider_1_native_match_template_binders_2{v_2: Maybe<&2, cps_provider_1_Problem>, v_3: IR.Words, v_4: Arena.Arena}
  EmitterRequest_cps_provider_1_template_binders{v_0: Arena.Arena, v_1: IR.Words, v_4: Maybe<&2, cps_provider_1_Problem>}
  EmitterRequest_cps_provider_1_template_binder{v_0: Arena.Arena, v_1: Arena.Binder, v_2: IR.Words}
  EmitterRequest_cps_provider_1_native_match_template_declarations_0{v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, IR.TopLevel>, v_5: Arena.Arena}
  EmitterRequest_cps_provider_1_template_declarations{v_0: Arena.Arena, v_2: List<&2, IR.TopLevel>, v_5: Maybe<&2, cps_provider_1_Problem>}
  EmitterRequest_cps_provider_1_template_declaration_result{v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.TopLevel>}
  EmitterRequest_cps_provider_1_template_declaration{v_0: Arena.Arena, v_1: IR.TopLevel}
  EmitterRequest_cps_provider_1_template_constructor_result{v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.ConstructorDecl>}
  EmitterRequest_cps_provider_1_native_match_template_constructors_0{v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, IR.ConstructorDecl>, v_5: Arena.Arena}
  EmitterRequest_cps_provider_1_template_constructors{v_0: Arena.Arena, v_2: List<&2, IR.ConstructorDecl>, v_5: Maybe<&2, cps_provider_1_Problem>}
  EmitterRequest_cps_provider_1_native_match_template_modules_0{v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, IR.LoadedModule>, v_5: Arena.Arena}
  EmitterRequest_cps_provider_1_template_modules{v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_5: Maybe<&2, cps_provider_1_Problem>}
  EmitterRequest_cps_provider_1_template_module_result{v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.LoadedModule>}
  EmitterRequest_cps_provider_1_prepare{v_0: Checked.CheckedProgram}
  EmitterRequest_cps_provider_1_prepare_result{v_1: cps_provider_1_TemplateResult, v_3: List<&2, IR.LoadedModule>, v_5: List<&2, Scope.ArenaGlobal>, v_7: List<&2, Checked.ModuleMetadata>}
  EmitterRequest_cps_provider_1_lower{v_0: Checked.CheckedProgram}
  EmitterRequest_cps_provider_1_lower_library{v_0: Checked.CheckedProgram, v_3: List<&2, String>}
  EmitterRequest_cps_provider_1_lower_prepared{v_1: cps_provider_1_Prepared, v_5: Maybe<&2, List<&2, String>>}
  EmitterRequest_cps_provider_1_lower_catalog{v_1: cps_provider_10_BuildResult}
  EmitterRequest_cps_provider_1_lower_definitions{v_2: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>, v_4: List<&2, BIR.ConstructorLayout>, v_6: List<&2, BIR.Family>, v_8: List<&2, BIR.TypeFunction>, v_9: BIR.Ending}
  EmitterRequest_cps_provider_1_lower_complete{v_2: Maybe<&2, cps_provider_1_Problem>, v_4: List<&2, BIR.Code>, v_6: List<&2, BIR.Declaration>, v_8: List<&2, BIR.ConstructorLayout>, v_10: List<&2, BIR.Family>, v_12: List<&2, BIR.TypeFunction>, v_13: BIR.Ending}
  EmitterRequest_cps_provider_2_build_new{}
  EmitterRequest_cps_provider_2_build_entries{v_0: BIR.Program, +v_2: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_build_codes{v_1: List<&2, BIR.Code>, +v_3: List<&2, BIR.Declaration>, +v_5: cps_provider_2_Scan, +v_7: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_code_key{v_1: List<&2, BIR.Declaration>, +v_3: U32}
  EmitterRequest_cps_provider_2_code_key_one{v_1: Bool, v_3: String, v_5: List<&2, BIR.Declaration>, v_7: U32}
  EmitterRequest_cps_provider_2_scan_reads{v_1: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_closures{v_1: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_code_stem{v_1: U32}
  EmitterRequest_cps_provider_2_native_stem{v_1: String}
  EmitterRequest_cps_provider_2_foreign_stem{v_1: String}
  EmitterRequest_cps_provider_2_stage_key{v_1: String, v_3: Nat}
  EmitterRequest_cps_provider_2_code_stage_start{v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Scan, +v_5: U32, +v_7: Nat}
  EmitterRequest_cps_provider_2_stage_from_closures{v_1: cps_provider_2_Scan, v_3: U32, +v_5: Nat}
  EmitterRequest_cps_provider_2_build_one_code{v_1: List<&2, BIR.Declaration>, v_3: cps_provider_2_Scan, v_5: cps_provider_2_Build, +v_7: U32, +v_9: Nat, +v_11: List<&2, BIR.Parameter>, v_12: BIR.Block}
  EmitterRequest_cps_provider_2_stage_code{v_1: cps_provider_2_Build, v_3: String, v_5: Nat, v_7: Nat, v_9: U32, v_11: Nat, v_13: List<&2, BIR.Parameter>, v_14: BIR.Block}
  EmitterRequest_cps_provider_2_build_staged{+v_1: cps_provider_2_Build, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_2_EntryKind}

type EmitterRequestGroup6 is Type:
  EmitterRequest_cps_provider_2_entry_kind_arity{v_1: cps_provider_2_EntryKind}
  EmitterRequest_cps_provider_2_build_entry{v_1: cps_provider_2_Build, +v_3: cps_provider_2_EntryKind}
  EmitterRequest_cps_provider_2_build_with_code{v_1: cps_provider_2_Build, v_3: U32}
  EmitterRequest_cps_provider_2_build_with_key{v_1: cps_provider_2_Build, v_3: String}
  EmitterRequest_cps_provider_2_build_with_foreign{v_1: cps_provider_2_Build, v_3: String}
  EmitterRequest_cps_provider_2_build_with_native{v_1: cps_provider_2_Build, v_3: String}
  EmitterRequest_cps_provider_2_build_lazy{v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_live_quantities{v_1: List<&2, BIR.Quantity>, +v_3: Nat}
  EmitterRequest_cps_provider_2_live_quantity_next{v_0: BIR.Quantity, +v_2: Nat}
  EmitterRequest_cps_provider_2_build_native{+v_1: cps_provider_2_Scan, v_3: List<&2, BIR.Declaration>, +v_5: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_build_native_one{+v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Scan, +v_5: cps_provider_2_Build, +v_7: String, v_8: BIR.Primitive, +v_10: Nat}
  EmitterRequest_cps_provider_2_stage_native{v_1: cps_provider_2_Build, v_3: String, +v_5: Nat, v_6: BIR.Primitive}
  EmitterRequest_cps_provider_2_build_foreign{v_1: cps_provider_2_Scan, v_3: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_build_foreign_each{v_2: List<&2, String>, +v_5: Map<&2, Nat>, +v_8: Map<&2, Bool>, +v_10: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_stage_foreign{v_1: cps_provider_2_Build, v_3: String, v_5: Nat, v_7: Nat, v_9: String, v_11: Nat}
  EmitterRequest_cps_provider_2_foreign_stage_start{v_1: Bool, v_3: Nat}
  EmitterRequest_cps_provider_2_finish_entries{v_1: cps_provider_2_Build, v_3: Bool}
  EmitterRequest_cps_provider_2_top_entry_kind{v_1: Bool}
  EmitterRequest_cps_provider_2_finish_top{v_1: cps_provider_2_Entry, v_3: cps_provider_2_Entry, v_5: cps_provider_2_Entry, v_7: cps_provider_2_Entry, v_9: cps_provider_2_Entry, v_12: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_entries_ascending{v_2: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_fid_macro_map{v_1: List<&2, BIR.Declaration>, v_3: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_fid_macros_declarations{v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, U32>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, String>}
  EmitterRequest_cps_provider_2_ending_library{v_0: BIR.Ending}
  EmitterRequest_cps_provider_2_ending_exports{v_0: BIR.Ending}
  EmitterRequest_cps_provider_2_plan_make{+v_0: BIR.Program, v_3: List<&2, cps_provider_2_CImport>}
  EmitterRequest_cps_provider_2_plan_finish{v_0: BIR.Program, v_2: cps_provider_2_Scan, v_5: List<&2, cps_provider_2_CidRow>, v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, v_11: List<&2, BIR.Declaration>, +v_12: BIR.Ending, v_15: List<&2, cps_provider_2_CImport>, v_16: Sharing.SharingPlan, +v_18: cps_provider_3_Context}
  EmitterRequest_cps_provider_2_plan_top{+v_0: BIR.Program, +v_2: cps_provider_2_Scan, +v_5: List<&2, cps_provider_2_CidRow>, v_7: List<&2, BIR.ConstructorLayout>, v_9: List<&2, BIR.Family>, +v_11: List<&2, BIR.Declaration>, v_12: BIR.Ending, v_15: List<&2, cps_provider_2_CImport>, v_16: Sharing.SharingPlan, +v_18: cps_provider_3_Context}
  EmitterRequest_cps_provider_2_plan_pure{v_0: BIR.Ending, v_2: List<&2, BIR.Family>, v_4: cps_provider_2_PlanResult}
  EmitterRequest_cps_provider_2_plan_set_pure{v_0: BIR.Ending, v_2: List<&2, BIR.Family>, v_4: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_plan_set_pure_flags{v_1: cps_provider_2_Plan, v_3: Bool, v_5: String, v_7: String}
  EmitterRequest_cps_provider_2_fid_macros_runtime{v_2: Map<&2, String>}
  EmitterRequest_cps_provider_2_fid_macros_runtime_one{v_2: Map<&2, String>}
  EmitterRequest_cps_provider_2_plan_executable{+v_0: BIR.Descriptor, v_2: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_plan_executable_native{+v_2: Maybe<&2, String>, +v_3: BIR.Descriptor, +v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_plan_executable_io{v_1: Bool, +v_2: BIR.Descriptor, +v_4: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_plan_executable_show{+v_0: BIR.Descriptor, v_2: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_plan_library{v_1: List<&2, BIR.Export>, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_export_rows{v_1: List<&2, BIR.Export>, +v_3: List<&2, BIR.Declaration>, +v_6: Map<&2, U32>, +v_9: Map<&2, U32>, +v_12: Map<&2, U32>, +v_15: Map<&2, U32>, +v_18: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_export_row_pair{v_2: Maybe<&2, cps_provider_2_ExportRow>, v_6: Maybe<&2, List<&2, cps_provider_2_ExportRow>>}
  EmitterRequest_cps_provider_2_export_row{v_0: BIR.Export, +v_2: List<&2, BIR.Declaration>, +v_5: Map<&2, U32>, +v_8: Map<&2, U32>, +v_11: Map<&2, U32>, +v_14: Map<&2, U32>, +v_17: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_export_direct{v_1: String, v_2: BIR.Entry, v_4: Nat, +v_7: Map<&2, U32>}
  EmitterRequest_cps_provider_2_export_direct_curried{v_1: Bool, +v_3: String, +v_5: U32, +v_7: Nat, +v_10: Map<&2, U32>}
  EmitterRequest_cps_provider_2_export_symbol{v_1: String, v_3: Nat, +v_5: List<&2, BIR.Declaration>, +v_8: Map<&2, U32>, +v_11: Map<&2, U32>, +v_14: Map<&2, U32>, +v_17: Map<&2, U32>}
  EmitterRequest_cps_provider_2_export_symbol_item{v_1: String, v_3: Nat, v_4: BIR.Declaration, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>}
  EmitterRequest_cps_provider_2_export_declared{v_1: String, v_3: Nat, v_5: Nat, v_7: U32, v_9: Nat}
  EmitterRequest_cps_provider_2_export_names{v_2: List<&2, cps_provider_2_ExportRow>, +v_4: String}
  EmitterRequest_cps_provider_2_if_first{v_1: String}
  EmitterRequest_cps_provider_2_export_values{v_2: List<&2, cps_provider_2_ExportRow>, v_4: Nat, +v_6: String}
  EmitterRequest_cps_provider_2_export_value{v_1: U32, v_3: Nat, v_5: Nat, v_7: Nat}
  EmitterRequest_cps_provider_2_export_list{v_1: String, v_3: String}
  EmitterRequest_cps_provider_2_exports_c{v_1: Bool, v_4: List<&2, cps_provider_2_ExportRow>}
  EmitterRequest_cps_provider_2_descriptor_head{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_2_family_key{+v_1: String, v_3: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_2_build_entries_of{v_1: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_by_code_of{v_1: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_by_key_of{v_1: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_by_foreign_of{v_1: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_by_native_of{v_1: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_stages_of{v_1: cps_provider_2_Build}
  EmitterRequest_cps_provider_2_fkeys_of{v_1: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_cat{v_2: List<&2, String>}
  EmitterRequest_cps_provider_2_okp{v_1: String}
  EmitterRequest_cps_provider_2_failp{v_1: String}
  EmitterRequest_cps_provider_2_part_join{v_2: List<&2, cps_provider_2_Part>}

type EmitterRequestGroup7 is Type:
  EmitterRequest_cps_provider_2_part_append{v_1: cps_provider_4_Fragment, v_3: cps_provider_2_Part}
  EmitterRequest_cps_provider_2_part_first{v_2: List<&2, cps_provider_2_Part>}
  EmitterRequest_cps_provider_2_part_require{v_2: List<&2, cps_provider_2_Part>}
  EmitterRequest_cps_provider_2_nat_c{v_1: Nat}
  EmitterRequest_cps_provider_2_u32_c{v_1: U32}
  EmitterRequest_cps_provider_2_list_at{v_2: List<&2, String>, v_4: Nat}
  EmitterRequest_cps_provider_2_member{v_2: List<&2, String>, +v_4: String}
  EmitterRequest_cps_provider_2_member_one{v_1: Bool, v_3: String, v_6: List<&2, String>}
  EmitterRequest_cps_provider_2_map_flag{v_2: Map<&2, Bool>, v_4: String}
  EmitterRequest_cps_provider_2_map_nat{v_2: Map<&2, Nat>, v_4: String}
  EmitterRequest_cps_provider_2_map_u32{v_2: Map<&2, U32>, v_4: String}
  EmitterRequest_cps_provider_2_map_set_first{+v_2: Map<&2, String>, +v_4: String, v_6: String}
  EmitterRequest_cps_provider_2_nat_min{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_nat_max{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_last_segment{+v_1: String}
  EmitterRequest_cps_provider_2_last_segment_list{v_2: List<&2, String>, v_4: String}
  EmitterRequest_cps_provider_2_list_index_of{v_2: List<&2, String>, +v_4: String, v_6: U32}
  EmitterRequest_cps_provider_2_list_index_one{v_1: Bool, v_3: String, v_5: String, v_8: List<&2, String>, +v_10: U32}
  EmitterRequest_cps_provider_2_ctor_keys{v_1: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_2_entry_at{v_2: List<&2, cps_provider_2_Entry>, +v_4: U32}
  EmitterRequest_cps_provider_2_entry_at_one{v_1: Bool, v_3: cps_provider_2_Entry, v_6: List<&2, cps_provider_2_Entry>, v_8: U32}
  EmitterRequest_cps_provider_2_entry_arity{v_2: List<&2, cps_provider_2_Entry>, v_4: U32}
  EmitterRequest_cps_provider_2_max_arity{v_2: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_max_arity_each{v_2: List<&2, cps_provider_2_Entry>, +v_4: Nat}
  EmitterRequest_cps_provider_2_scan_new{}
  EmitterRequest_cps_provider_2_scan_program{v_0: BIR.Program}
  EmitterRequest_cps_provider_2_scan_exports{v_1: List<&2, BIR.Export>, +v_3: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_codes{v_1: List<&2, BIR.Code>, +v_3: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_declarations{v_1: List<&2, BIR.Declaration>, +v_3: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_declaration{v_0: BIR.Declaration, +v_2: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_foreign{v_1: cps_provider_2_Scan, +v_3: String, v_5: Nat}
  EmitterRequest_cps_provider_2_scan_read{v_1: cps_provider_2_Scan, v_3: String}
  EmitterRequest_cps_provider_2_scan_close{v_1: cps_provider_2_Scan, v_3: U32, v_5: Nat}
  EmitterRequest_cps_provider_2_scan_close_min{+v_2: Map<&2, Nat>, +v_4: String, +v_6: Nat}
  EmitterRequest_cps_provider_2_scan_atom{v_0: BIR.Atom, +v_2: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_argument{v_0: BIR.Arg, v_2: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_arguments{v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_fields{v_1: List<&2, BIR.Field>, +v_3: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_op{v_0: BIR.Op, +v_2: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_scan_block{v_0: BIR.Block, +v_2: cps_provider_2_Scan}
  EmitterRequest_cps_provider_2_cid_rows{v_0: BIR.Program, v_2: cps_provider_2_Scan, v_3: Sharing.SharingPlan, +v_5: cps_provider_3_Context}
  EmitterRequest_cps_provider_2_cid_arity_field{+v_1: Nat}
  EmitterRequest_cps_provider_2_cid_rows_check{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_node_arity{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_2_cid_ctor_rows{v_1: List<&2, BIR.ConstructorLayout>, +v_3: U32, +v_6: List<&2, cps_provider_2_CidRow>, v_7: Sharing.SharingPlan, +v_9: cps_provider_3_Context}
  EmitterRequest_cps_provider_2_cid_foreign_rows{v_1: cps_provider_2_Scan, +v_4: List<&2, cps_provider_2_CidRow>, v_5: Sharing.SharingPlan}
  EmitterRequest_cps_provider_2_cid_foreign_each{v_2: List<&2, String>, +v_5: Map<&2, Nat>, +v_7: U32, +v_10: List<&2, cps_provider_2_CidRow>, v_11: Sharing.SharingPlan}
  EmitterRequest_cps_provider_2_cid_lookup{+v_1: String, v_4: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_lookup_one{v_1: Bool, v_3: String, v_5: U32, v_8: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_short_one{v_1: Bool, v_3: String, v_5: U32, v_8: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_short{+v_1: String, v_4: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_c{+v_1: String, v_4: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_macro_map{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_symbol{v_1: U32}
  EmitterRequest_cps_provider_2_fid_symbol{v_1: U32}
  EmitterRequest_cps_provider_2_runtime_cid_alias{+v_1: String, +v_3: String, v_6: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_find_cid_row{+v_1: String, v_4: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_find_cid_row_one{v_1: Bool, v_3: cps_provider_2_CidRow, v_5: String, v_8: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_runtime_cid_aliases{+v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_of_row{v_1: cps_provider_2_CidRow}
  EmitterRequest_cps_provider_2_cid_macro_each{v_2: List<&2, cps_provider_2_CidRow>, +v_5: Map<&2, String>}
  EmitterRequest_cps_provider_2_layout_of{+v_1: U32, v_3: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_2_layout_one{v_1: Bool, v_2: BIR.ConstructorLayout, v_4: U32, v_6: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_2_key_layout{+v_1: String, v_3: List<&2, BIR.ConstructorLayout>}

type EmitterRequestGroup8 is Type:
  EmitterRequest_cps_provider_2_live_fields{v_1: List<&2, BIR.DescriptorField>, +v_3: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_2_live_field_add{v_0: BIR.Quantity, v_1: BIR.DescriptorField, +v_3: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_2_arm_of{v_1: String, v_3: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_2_arms_find{+v_1: String, v_3: List<&2, BIR.DescriptorArm>, +v_5: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_2_live_index_fields{v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat}
  EmitterRequest_cps_provider_2_live_index_next{v_0: BIR.Quantity, +v_2: Nat}
  EmitterRequest_cps_provider_2_atom_part{v_0: BIR.Atom, +v_2: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_bool_name{v_1: Bool}
  EmitterRequest_cps_provider_2_bool_lit_part{v_1: String, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_text_atom_part{+v_1: String, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_symbol_part{+v_1: String, +v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_find_declaration{+v_1: String, v_3: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_find_declaration_one{v_1: Bool, v_2: BIR.Declaration, v_4: String, v_6: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_symbol_part_decl{v_1: Maybe<&2, BIR.Declaration>, +v_3: String, v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_symbol_part_item{v_0: BIR.Declaration, +v_2: String, v_4: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_symbol_value{v_2: Maybe<&2, U32>, +v_4: String, v_7: List<&2, cps_provider_2_Entry>, v_10: Map<&2, U32>}
  EmitterRequest_cps_provider_2_args_parts{v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_prim_default_owned{v_0: BIR.Primitive, +v_2: Nat}
  EmitterRequest_cps_provider_2_array_arg_owned{v_0: BIR.Primitive, +v_2: Nat}
  EmitterRequest_cps_provider_2_descriptor_arg_owned{v_0: BIR.Primitive, +v_2: Nat}
  EmitterRequest_cps_provider_2_descriptor_step{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_Ctx, +v_8: Nat, +v_11: List<&2, cps_provider_5_Operand>, +v_13: String, v_14: BIR.Block, +v_16: U32}
  EmitterRequest_cps_provider_2_prim_borrowed_box{v_0: BIR.Primitive, +v_2: Nat}
  EmitterRequest_cps_provider_2_atom_allocates{v_0: BIR.Atom}
  EmitterRequest_cps_provider_2_prim_texts{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, +v_4: cps_provider_2_Ctx, +v_6: Nat, +v_9: List<&2, String>, +v_11: String, +v_13: String, v_14: BIR.Block, +v_16: U32}
  EmitterRequest_cps_provider_2_prim_step{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_Ctx, v_7: BIR.Block, +v_9: U32}
  EmitterRequest_cps_provider_2_array_op_step{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_Ctx, v_7: BIR.Block, +v_9: U32}
  EmitterRequest_cps_provider_2_array_op_step_element{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_2_Ctx, v_7: BIR.Block, +v_9: U32}
  EmitterRequest_cps_provider_2_pred_path{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, +v_4: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_str_append{v_1: String, v_3: String, v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_construct_step{+v_1: U32, v_3: List<&2, BIR.Field>, +v_5: cps_provider_2_Ctx, +v_7: Nat, +v_10: List<&2, cps_provider_5_Operand>, +v_12: String, v_13: BIR.Block, +v_15: U32}
  EmitterRequest_cps_provider_2_hastag_step{v_0: BIR.Atom, +v_2: U32, +v_4: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_op_step{v_0: BIR.Op, +v_2: cps_provider_2_Ctx, v_3: BIR.Block, +v_5: U32}
  EmitterRequest_cps_provider_2_phys_part{v_1: cps_provider_5_Part}
  EmitterRequest_cps_provider_2_field_values{v_1: List<&2, BIR.Field>, +v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_all_arms_nullary{v_1: List<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_2_all_arms_nullary_one{v_1: Bool, v_3: List<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_2_arm_member{+v_1: String, v_3: List<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_2_arm_member_one{v_1: Bool, v_3: String, v_5: List<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_2_arm_index{+v_1: String, v_3: List<&2, BIR.DescriptorArm>, v_5: Nat}
  EmitterRequest_cps_provider_2_arm_index_one{v_1: Bool, v_3: String, v_5: List<&2, BIR.DescriptorArm>, +v_7: Nat}
  EmitterRequest_cps_provider_2_phys_world{+v_1: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_phys_cids{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_project_part{v_0: BIR.Atom, +v_2: U32, v_4: U32, +v_6: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_hastag_part{v_0: BIR.Atom, +v_2: U32, +v_4: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_is_array_primitive{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_2_is_descriptor_primitive{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_2_is_atomic_primitive{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_2_pcid{v_1: String, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_str_bool2{v_1: String, v_3: String, v_5: String, v_7: String, v_9: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_bool_str_empty_of{v_1: Bool, v_3: String, v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_bool_str_empty{v_1: Bool, v_3: String, v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_bool_part{v_1: String, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_prim_part{v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_prim_plain_part{v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_prim_scalar_part{v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_f32_bin{v_1: String, v_3: String, v_5: String}
  EmitterRequest_cps_provider_2_f32_un{v_1: String, v_3: String}
  EmitterRequest_cps_provider_2_f32_cmp{v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_bool2_part{v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_bool2_c{v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Part, v_9: cps_provider_2_Part}
  EmitterRequest_cps_provider_2_is_bool_part{v_1: String, v_3: String, v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_cmp3_part{v_1: String, v_3: String, +v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_divmod_part{v_1: String, v_3: String, v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_str1{v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan}

type EmitterRequestGroup9 is Type:
  EmitterRequest_cps_provider_2_str_tail{v_1: String, +v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_str_to_list{v_1: String, +v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_str1_char{v_1: String, v_3: String, v_5: String, v_7: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_char_pack_part{v_1: String, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_str_cmp{v_1: String, v_3: String, +v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_map_bit_part{v_1: String, v_3: String, +v_5: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_char_new_part{v_1: String, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_word_part{v_1: String, +v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_u32_member{v_2: List<&2, U32>, +v_4: U32}
  EmitterRequest_cps_provider_2_u32_add{+v_2: List<&2, U32>, +v_4: U32}
  EmitterRequest_cps_provider_2_atom_locals{v_0: BIR.Atom, +v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_arg_locals{v_0: BIR.Arg, v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_args_locals{v_1: List<&2, BIR.Arg>, +v_4: List<&2, U32>}
  EmitterRequest_cps_provider_2_field_locals{v_1: List<&2, BIR.Field>, +v_4: List<&2, U32>}
  EmitterRequest_cps_provider_2_op_locals{v_0: BIR.Op, +v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_block_locals{v_0: BIR.Block, +v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_atom_slots{v_0: BIR.Atom, +v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_arg_slots{v_0: BIR.Arg, v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_args_slots{v_1: List<&2, BIR.Arg>, +v_4: List<&2, U32>}
  EmitterRequest_cps_provider_2_field_slots{v_1: List<&2, BIR.Field>, +v_4: List<&2, U32>}
  EmitterRequest_cps_provider_2_op_slots{v_0: BIR.Op, +v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_block_slots{v_0: BIR.Block, +v_3: List<&2, U32>}
  EmitterRequest_cps_provider_2_env_get{v_2: List<&2, cps_provider_2_Env>, +v_4: U32}
  EmitterRequest_cps_provider_2_env_get_one{v_1: Bool, v_3: String, v_6: List<&2, cps_provider_2_Env>, v_8: U32}
  EmitterRequest_cps_provider_2_env_del{+v_1: U32, +v_4: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_ctx_env_put{v_1: cps_provider_2_Ctx, v_4: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_ctx_caps_put{v_1: cps_provider_2_Ctx, v_4: List<&2, U32>}
  EmitterRequest_cps_provider_2_env_field{v_2: List<&2, cps_provider_2_Env>, +v_4: U32}
  EmitterRequest_cps_provider_2_field_root_expr{v_1: cps_provider_2_FieldRef, +v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_field_borrow{v_0: BIR.Atom, +v_2: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_field_read_ref{v_1: cps_provider_2_FieldRef, +v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ref_steps{v_1: cps_provider_2_FieldRef}
  EmitterRequest_cps_provider_2_ref_owners{v_1: cps_provider_2_FieldRef}
  EmitterRequest_cps_provider_2_rebase_ref{v_1: cps_provider_2_FieldRef, +v_3: U32}
  EmitterRequest_cps_provider_2_append_owner{v_2: List<&2, cps_provider_2_FieldRoot>, +v_4: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_owner_local{v_1: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_owner_slot{v_1: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_owners_ancestors{v_2: List<&2, cps_provider_2_FieldRoot>}
  EmitterRequest_cps_provider_2_owners_drop_last{v_2: List<&2, cps_provider_2_FieldRoot>, +v_5: List<&2, cps_provider_2_FieldRoot>}
  EmitterRequest_cps_provider_2_owner_index{v_2: List<&2, cps_provider_2_FieldRoot>, v_4: cps_provider_2_FieldRoot, +v_6: Nat}
  EmitterRequest_cps_provider_2_owner_same{v_1: cps_provider_2_FieldRoot, v_3: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_atom_owner{v_0: BIR.Atom}
  EmitterRequest_cps_provider_2_atom_is_owner{v_0: BIR.Atom, v_2: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_step_at{v_2: List<&2, cps_provider_5_PathStep>, +v_4: Nat}
  EmitterRequest_cps_provider_2_leave_reach{v_0: BIR.Block, +v_2: U32, v_5: List<&2, cps_provider_2_Leave>}
  EmitterRequest_cps_provider_2_refs_hold_root{v_2: List<&2, cps_provider_2_CapRef>, v_4: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_regions_hold_root{v_2: List<&2, cps_provider_2_Region>, v_3: BIR.Block, v_6: List<&2, cps_provider_2_Leave>, v_8: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_regions_reachable_refs{v_2: List<&2, cps_provider_2_Region>, v_3: BIR.Block, v_6: List<&2, cps_provider_2_Leave>}
  EmitterRequest_cps_provider_2_reachable_labels{v_2: List<&2, cps_provider_2_Region>, v_3: BIR.Block, v_6: List<&2, cps_provider_2_Leave>, +v_9: List<&2, U32>}
  EmitterRequest_cps_provider_2_region_keeps_root{+v_1: cps_provider_2_Ctx, v_2: BIR.Block, v_4: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_region_keeps_local{+v_1: cps_provider_2_Ctx, v_2: BIR.Block, +v_4: U32}
  EmitterRequest_cps_provider_2_region_keeps_slot{+v_1: cps_provider_2_Ctx, v_2: BIR.Block, +v_4: U32}
  EmitterRequest_cps_provider_2_field_owned{v_0: BIR.Atom, +v_1: BIR.Use, +v_3: cps_provider_2_Ctx, v_4: BIR.Block}
  EmitterRequest_cps_provider_2_atom_use{v_0: BIR.Atom, +v_1: BIR.Use, +v_3: cps_provider_2_Ctx, v_4: BIR.Block}
  EmitterRequest_cps_provider_2_args_use{v_1: List<&2, BIR.Arg>, +v_3: cps_provider_2_Ctx, +v_6: List<&2, String>, v_7: BIR.Block}
  EmitterRequest_cps_provider_2_env_drops{v_2: List<&2, cps_provider_2_Env>, +v_5: List<&2, U32>, +v_7: String}
  EmitterRequest_cps_provider_2_cap_count{v_2: List<&2, cps_provider_2_Cap>}
  EmitterRequest_cps_provider_2_cap_count_each{v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat}
  EmitterRequest_cps_provider_2_cap_slots_from{+v_1: Nat, +v_3: Nat, +v_6: List<&2, U32>}
  EmitterRequest_cps_provider_2_cap_slots_of{v_2: List<&2, cps_provider_2_Cap>}
  EmitterRequest_cps_provider_2_cap_slots_of_each{v_2: List<&2, cps_provider_2_Cap>, +v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_cap_slots_used{+v_2: List<&2, U32>, +v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_cap_slots_del{+v_1: U32, +v_4: List<&2, U32>}
  EmitterRequest_cps_provider_2_cap_drops{+v_2: List<&2, U32>, +v_4: String}

type EmitterRequestGroup10 is Type:
  EmitterRequest_cps_provider_2_caps_ids{v_2: List<&2, cps_provider_2_Cap>, +v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_caps_slots{v_2: List<&2, cps_provider_2_Cap>, +v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_arg_decls{v_2: List<&2, String>, +v_4: Nat, +v_6: String}
  EmitterRequest_cps_provider_2_arg_names{+v_1: Nat, +v_3: Nat, +v_6: List<&2, String>}
  EmitterRequest_cps_provider_2_exit_releases{v_1: cps_provider_2_Ctx, +v_4: List<&2, U32>, +v_7: List<&2, U32>}
  EmitterRequest_cps_provider_2_region_refs{v_2: List<&2, cps_provider_2_Region>, +v_5: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_refs_have_local{v_2: List<&2, cps_provider_2_CapRef>, +v_4: U32}
  EmitterRequest_cps_provider_2_refs_local_check{v_1: Bool, v_4: List<&2, cps_provider_2_CapRef>, v_6: U32}
  EmitterRequest_cps_provider_2_refs_have_slot{v_2: List<&2, cps_provider_2_CapRef>, +v_4: U32}
  EmitterRequest_cps_provider_2_refs_slot_check{v_1: Bool, v_4: List<&2, cps_provider_2_CapRef>, v_6: U32}
  EmitterRequest_cps_provider_2_env_refs{v_2: List<&2, cps_provider_2_Env>, +v_5: List<&2, U32>, +v_8: List<&2, cps_provider_2_CapRef>, +v_11: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_env_ref_add{v_1: Bool, v_3: Bool, v_5: U32, +v_8: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_slot_refs{+v_1: Nat, +v_3: Nat, +v_6: List<&2, U32>, +v_9: List<&2, cps_provider_2_CapRef>, +v_12: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_slot_ref_add{v_1: Bool, v_3: Bool, v_5: U32, +v_8: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_field_root_locals{v_2: List<&2, cps_provider_2_Env>, v_5: List<&2, U32>, +v_8: List<&2, U32>}
  EmitterRequest_cps_provider_2_field_root_slots{v_2: List<&2, cps_provider_2_Env>, v_5: List<&2, U32>, +v_8: List<&2, U32>}
  EmitterRequest_cps_provider_2_leaf_at{v_2: List<&2, cps_provider_2_Leave>, +v_4: U32}
  EmitterRequest_cps_provider_2_leaves_enter{v_2: List<&2, cps_provider_2_Leave>, +v_4: U32, v_5: BIR.Block}
  EmitterRequest_cps_provider_2_ctx_flow_put{v_1: cps_provider_2_Ctx, v_3: Bool, v_6: List<&2, U32>}
  EmitterRequest_cps_provider_2_ctx_add_call{v_1: cps_provider_2_Ctx, +v_3: U32}
  EmitterRequest_cps_provider_2_ctx_fork{v_1: cps_provider_2_Ctx, +v_3: U32, +v_5: U32}
  EmitterRequest_cps_provider_2_atoms_after_args{v_1: List<&2, BIR.Arg>, v_2: BIR.Block}
  EmitterRequest_cps_provider_2_atoms_after_fields{v_1: List<&2, BIR.Field>, v_2: BIR.Block}
  EmitterRequest_cps_provider_2_atom_key{v_0: BIR.Atom}
  EmitterRequest_cps_provider_2_atom_path{v_0: BIR.Atom, +v_2: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_atom_path_in{v_0: BIR.Atom, v_3: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_root_eq{v_1: cps_provider_2_FieldRoot, v_3: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_steps_prefix{v_2: List<&2, cps_provider_5_PathStep>, v_5: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_2_step_eq{v_1: cps_provider_5_PathStep, v_3: cps_provider_5_PathStep}
  EmitterRequest_cps_provider_2_step_eq_field{v_1: U32, v_3: U32, v_5: cps_provider_5_PathStep}
  EmitterRequest_cps_provider_2_step_eq_half{v_1: Bool, v_3: cps_provider_5_PathStep}
  EmitterRequest_cps_provider_2_step_eq_half_both{v_1: Bool, v_3: Bool}
  EmitterRequest_cps_provider_2_step_eq_leaf{v_1: cps_provider_5_PathStep}
  EmitterRequest_cps_provider_2_path_related{v_1: cps_provider_2_FieldRef, v_3: cps_provider_2_FieldRef}
  EmitterRequest_cps_provider_2_path_before{v_1: cps_provider_2_FieldRef, v_3: cps_provider_2_FieldRef}
  EmitterRequest_cps_provider_2_atom_owner_known{v_0: BIR.Atom, v_2: cps_provider_2_FieldRef}
  EmitterRequest_cps_provider_2_owners_member{v_2: List<&2, cps_provider_2_FieldRoot>, v_4: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_project_related{v_0: BIR.Atom, +v_2: U32, +v_4: U32, v_6: cps_provider_2_FieldRef, v_9: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_atom_conflict{v_0: BIR.Atom, v_2: cps_provider_2_FieldRef, v_5: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_conflict_atom_list{v_1: List<&2, BIR.Arg>, v_3: cps_provider_2_FieldRef, v_6: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_conflict_field_list{v_1: List<&2, BIR.Field>, v_3: cps_provider_2_FieldRef, v_6: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_conflict_op{v_0: BIR.Op, v_2: cps_provider_2_FieldRef, v_5: List<&2, cps_provider_2_Leave>, v_8: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_projection_conflict{v_0: BIR.Primitive, v_2: List<&2, BIR.Arg>, v_4: List<&2, BIR.Descriptor>, v_6: cps_provider_2_FieldRef, v_9: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_conflict_block{v_0: BIR.Block, v_2: cps_provider_2_FieldRef, v_5: List<&2, cps_provider_2_Leave>, v_8: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_path_conflict{v_0: BIR.Block, v_2: cps_provider_2_FieldRef, v_5: List<&2, cps_provider_2_Leave>, v_8: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_atom_has_key{v_0: BIR.Atom, v_2: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_path_rooted_by{v_2: Maybe<&2, cps_provider_2_FieldRef>, v_4: cps_provider_2_FieldRoot}
  EmitterRequest_cps_provider_2_atom_root_used{v_0: BIR.Atom, v_2: cps_provider_2_FieldRoot, +v_4: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_op_root_used{v_0: BIR.Op, v_2: cps_provider_2_FieldRoot, +v_4: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_args_root_used{v_1: List<&2, BIR.Arg>, v_3: cps_provider_2_FieldRoot, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_fields_root_used{v_1: List<&2, BIR.Field>, v_3: cps_provider_2_FieldRoot, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_root_residual{v_0: BIR.Block, v_2: cps_provider_2_FieldRoot, v_5: List<&2, cps_provider_2_Leave>, +v_7: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_no_remaining{}
  EmitterRequest_cps_provider_2_refs_local_ids{v_2: List<&2, cps_provider_2_CapRef>, +v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_needed_refs{+v_0: BIR.Block, +v_2: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_u32s_text{v_2: List<&2, U32>}
  EmitterRequest_cps_provider_2_u32s_text_more{+v_1: String, v_4: List<&2, U32>}
  EmitterRequest_cps_provider_2_refs_text{v_2: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_refs_text_more{+v_1: String, v_4: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_capture_context{v_0: BIR.Block, +v_2: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_refs_caps{v_2: List<&2, cps_provider_2_CapRef>, +v_4: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_cap_ref_text{v_1: cps_provider_2_CapRef}
  EmitterRequest_cps_provider_2_cap_of_ref{v_1: cps_provider_2_CapRef, +v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_capture_for{v_0: BIR.Block, +v_2: cps_provider_2_Ctx}

type EmitterRequestGroup11 is Type:
  EmitterRequest_cps_provider_2_entry_label{+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>, +v_6: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_kind_label{v_1: cps_provider_2_EntryKind, +v_3: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_declaration_key{+v_1: U32, +v_3: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_declaration_key_one{v_1: Bool, +v_3: String, v_5: List<&2, BIR.Declaration>, +v_7: U32}
  EmitterRequest_cps_provider_2_ctx_sig{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_plan{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_env{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_caps{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_caps_n{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_regions{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_self{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_next{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_segs{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_forked{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_calls{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_spin{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_max{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_cap_slots{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_leaves{v_1: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_segs_put{v_1: cps_provider_2_Ctx, v_4: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_ctx_with_leaves{v_1: cps_provider_2_Ctx, v_4: List<&2, cps_provider_2_Leave>}
  EmitterRequest_cps_provider_2_sig_entries{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_by_code{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_by_key{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_by_foreign{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_by_native{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_stages{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_decls{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_cids{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_sig_apply{v_1: cps_provider_2_Sig}
  EmitterRequest_cps_provider_2_a_name{v_1: Nat}
  EmitterRequest_cps_provider_2_r_name{v_1: Nat}
  EmitterRequest_cps_provider_2_lv_name{v_1: U32}
  EmitterRequest_cps_provider_2_a_decls{v_1: Nat}
  EmitterRequest_cps_provider_2_a_decls_at{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_x_decl{+v_1: Nat}
  EmitterRequest_cps_provider_2_x_fill_a{v_1: Nat}
  EmitterRequest_cps_provider_2_x_fill_a_at{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_params_bind{v_1: List<&2, BIR.Parameter>, +v_3: Nat, +v_5: Nat}
  EmitterRequest_cps_provider_2_params_env{v_1: List<&2, BIR.Parameter>, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_a_caps{v_1: Nat}
  EmitterRequest_cps_provider_2_a_caps_at{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_caps_assign{v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat}
  EmitterRequest_cps_provider_2_regs_assign{v_2: List<&2, String>, +v_4: Nat}
  EmitterRequest_cps_provider_2_k_decls{v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat}
  EmitterRequest_cps_provider_2_cap_intro{v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: String, +v_8: String}
  EmitterRequest_cps_provider_2_cap_intro_a{v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: String, +v_8: String}
  EmitterRequest_cps_provider_2_cap_locals_env{v_2: List<&2, cps_provider_2_Cap>, +v_5: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_caps_lookup{v_2: List<&2, cps_provider_2_Cap>, +v_4: U32}
  EmitterRequest_cps_provider_2_caps_lookup_one{v_1: Bool, v_4: List<&2, cps_provider_2_Cap>, v_6: U32}
  EmitterRequest_cps_provider_2_cap_slots_exprs{+v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: Nat, +v_9: List<&2, String>}
  EmitterRequest_cps_provider_2_cap_slot_value{v_1: Bool, v_3: U32}
  EmitterRequest_cps_provider_2_cont_prologue{+v_2: List<&2, cps_provider_2_Cap>, v_4: Nat, v_6: U32}
  EmitterRequest_cps_provider_2_cap_stk_intro{+v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat, +v_6: String, +v_8: String}
  EmitterRequest_cps_provider_2_region_prologue{+v_2: List<&2, cps_provider_2_Cap>, v_4: Nat}
  EmitterRequest_cps_provider_2_a_rebinds{v_1: Nat}
  EmitterRequest_cps_provider_2_a_rebinds_at{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_fid_name{+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_case_text{+v_1: U32, +v_3: String, +v_5: String, +v_7: Bool}
  EmitterRequest_cps_provider_2_spin_open{v_1: Bool}
  EmitterRequest_cps_provider_2_spin_close{v_1: Bool}
  EmitterRequest_cps_provider_2_block_ctl{v_0: BIR.Block, +v_2: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_return_ctl{v_0: BIR.Atom, +v_2: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_failure_ctl{v_1: cps_provider_2_Ctx}

type EmitterRequestGroup12 is Type:
  EmitterRequest_cps_provider_2_let_ctl{+v_1: U32, +v_2: BIR.Op, +v_3: BIR.Block, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_pure_let{+v_1: U32, v_2: BIR.Op, v_3: BIR.Block, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_value_let{+v_1: U32, v_2: BIR.Op, v_3: BIR.Block, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_projection_primitive{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_2_projection_step{v_0: BIR.Primitive, v_1: BIR.Descriptor}
  EmitterRequest_cps_provider_2_array_project_bind{+v_1: U32, v_2: BIR.Primitive, v_3: BIR.Descriptor, v_5: List<&2, BIR.Arg>, v_6: BIR.Block, +v_8: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_atom_step_ref{v_0: BIR.Atom, v_2: cps_provider_5_PathStep, +v_4: U32, +v_6: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_atom_step_ref_in{v_0: BIR.Atom, v_2: cps_provider_5_PathStep, +v_4: U32, v_7: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_project_ref{v_0: BIR.Atom, +v_2: U32, +v_4: U32, +v_6: U32, +v_8: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_project_ref_in{v_0: BIR.Atom, +v_2: U32, +v_4: U32, +v_6: U32, v_9: List<&2, cps_provider_2_Env>}
  EmitterRequest_cps_provider_2_bind_provenance{v_2: List<&2, cps_provider_2_Env>, +v_4: U32, v_5: BIR.Op}
  EmitterRequest_cps_provider_2_bind_copy_path{v_2: List<&2, cps_provider_2_Env>, +v_4: U32, v_5: BIR.Atom}
  EmitterRequest_cps_provider_2_ref_root{v_1: cps_provider_2_FieldRef}
  EmitterRequest_cps_provider_2_append_path_step{v_2: List<&2, cps_provider_5_PathStep>, +v_4: cps_provider_5_PathStep}
  EmitterRequest_cps_provider_2_project_bind{+v_1: U32, v_2: BIR.Atom, +v_4: U32, +v_6: U32, v_7: BIR.Block, +v_9: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_cond_part_of{v_1: cps_provider_2_Part, v_3: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_cond_part{v_1: String, v_3: cps_provider_2_Part}
  EmitterRequest_cps_provider_2_branch_ctl{v_0: BIR.Atom, v_1: BIR.Block, v_2: BIR.Block, +v_4: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_arm_start{v_1: cps_provider_2_Ctx, v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_after_call{v_1: cps_provider_2_Ctx, v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_after_region{v_1: cps_provider_2_Ctx, v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_ctx_after_branch{v_1: cps_provider_2_Ctx, v_3: cps_provider_2_Ctx, v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_region_ctl{v_1: U32, v_2: BIR.Block, +v_3: BIR.Block, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_region_next{+v_1: U32, v_2: BIR.Block, v_3: BIR.Block, +v_5: cps_provider_2_Ctx, +v_8: List<&2, cps_provider_2_Cap>, +v_10: U32, +v_13: List<&2, cps_provider_2_CapRef>}
  EmitterRequest_cps_provider_2_region_body{v_1: U32, v_2: BIR.Block, v_3: BIR.Block, +v_5: cps_provider_2_Ctx, +v_8: List<&2, cps_provider_2_Cap>, +v_10: U32, v_13: List<&2, cps_provider_2_CapRef>, v_15: String, +v_17: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_find_region{v_2: List<&2, cps_provider_2_Region>, +v_4: U32}
  EmitterRequest_cps_provider_2_find_region_one{v_1: Bool, v_3: cps_provider_2_Region, v_6: List<&2, cps_provider_2_Region>, v_8: U32}
  EmitterRequest_cps_provider_2_leave_ctl{v_1: U32, +v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_tail_direct_ctl{+v_1: U32, v_3: List<&2, BIR.Arg>, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_tail_jump{+v_1: U32, +v_4: List<&2, String>, +v_6: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_self_tail{+v_1: U32, v_4: List<&2, String>, +v_6: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_tail_apply_ctl{v_0: BIR.Atom, v_1: BIR.Arg, +v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_direct_ctl{v_1: U32, +v_3: U32, v_5: List<&2, BIR.Arg>, v_6: BIR.Block, +v_8: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_apply_ctl{v_1: U32, v_2: BIR.Atom, v_3: BIR.Arg, v_4: BIR.Block, +v_6: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_call_ctl{+v_1: U32, +v_4: List<&2, String>, v_6: U32, +v_7: BIR.Block, +v_9: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_call_next{v_1: U32, v_4: List<&2, String>, +v_6: U32, v_7: BIR.Block, +v_9: cps_provider_2_Ctx, +v_12: List<&2, cps_provider_2_Cap>}
  EmitterRequest_cps_provider_2_call_done{v_1: U32, v_4: List<&2, String>, +v_7: List<&2, cps_provider_2_Cap>, v_9: U32, +v_11: cps_provider_2_Ctx, v_13: String, +v_15: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_arg_stores{+v_1: String, v_4: List<&2, String>, +v_6: Nat}
  EmitterRequest_cps_provider_2_call_head{+v_1: U32, +v_3: Nat, +v_6: List<&2, cps_provider_2_Cap>, +v_9: List<&2, String>, +v_11: U32, +v_14: List<&2, cps_provider_2_Entry>, +v_16: String}
  EmitterRequest_cps_provider_2_cap_stk_stores{+v_2: List<&2, cps_provider_2_Cap>, +v_4: Nat}
  EmitterRequest_cps_provider_2_cap_stores{+v_1: String, v_4: List<&2, cps_provider_2_Cap>, +v_6: Nat}
  EmitterRequest_cps_provider_2_load_symbol_ctl{+v_1: U32, +v_3: String, +v_4: BIR.Block, +v_6: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_value_bind_entry{+v_1: U32, v_3: U32, v_5: String, v_6: BIR.Block, +v_8: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_value_closure{+v_1: U32, v_3: String, +v_5: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_closure_ctl{v_1: U32, +v_3: U32, +v_5: List<&2, BIR.Arg>, v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_closure_bind{+v_1: U32, v_3: U32, +v_5: Nat, v_7: Nat, v_9: U32, v_12: List<&2, String>, v_13: BIR.Block, +v_15: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_closure_text{+v_1: U32, +v_3: Nat, v_5: U32, v_8: List<&2, String>}
  EmitterRequest_cps_provider_2_closure_entry{v_1: U32, +v_3: Nat, v_5: Nat, v_7: U32, v_9: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_closure_alloc{+v_1: String, v_4: List<&2, String>, +v_6: Nat}
  EmitterRequest_cps_provider_2_closure_alloc_decl{+v_1: Nat, +v_3: String, v_6: List<&2, String>}
  EmitterRequest_cps_provider_2_closure_ptr{v_1: Nat, v_3: String}
  EmitterRequest_cps_provider_2_entries_ctl{v_2: List<&2, cps_provider_2_Entry>, +v_4: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_ctl{v_1: cps_provider_2_Entry, v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_kind_ctl{+v_1: U32, +v_3: Nat, v_5: cps_provider_2_EntryKind, +v_7: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_library{+v_1: U32, +v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_reserved{v_1: U32, v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_add{v_1: U32, +v_3: Nat, +v_5: String, +v_7: String, +v_9: Bool, +v_11: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_code{+v_1: U32, +v_3: Nat, +v_5: Nat, +v_7: List<&2, BIR.Parameter>, v_8: BIR.Block, +v_10: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_stage{+v_1: U32, +v_3: Nat, v_5: U32, v_7: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_stage_stores{+v_1: String, +v_3: Nat, +v_5: Nat}
  EmitterRequest_cps_provider_2_entry_lazy{v_1: U32, v_3: Nat, v_4: BIR.Block, +v_6: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_native{v_1: U32, +v_3: Nat, +v_4: BIR.Primitive, +v_6: Nat, +v_8: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_native_borrow_drops{+v_0: BIR.Primitive, +v_2: Nat, +v_4: Nat}
  EmitterRequest_cps_provider_2_a_names{v_1: Nat}

type EmitterRequestGroup13 is Type:
  EmitterRequest_cps_provider_2_entry_foreign{+v_1: U32, +v_3: Nat, v_5: String, v_7: Nat, +v_9: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_entry_main{+v_1: U32, +v_3: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_main_jump{v_1: U32, v_4: Maybe<&2, U32>, +v_6: cps_provider_2_Ctx}
  EmitterRequest_cps_provider_2_control_build{+v_1: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_segs_text{v_2: List<&2, cps_provider_2_SegText>, +v_4: String}
  EmitterRequest_cps_provider_2_rt_entry{v_2: List<&2, cps_provider_2_Entry>, v_4: Nat}
  EmitterRequest_cps_provider_2_entry_at_kind{v_2: List<&2, cps_provider_2_Entry>, +v_4: Nat}
  EmitterRequest_cps_provider_2_kind_want{v_1: cps_provider_2_EntryKind}
  EmitterRequest_cps_provider_2_rows_add_entries{v_2: List<&2, cps_provider_2_Entry>, +v_5: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_rows_add_segs{v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_row_insert{+v_1: cps_provider_2_SegText, +v_4: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_rows_check{v_2: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_cid_defines{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_entry_forks{v_1: cps_provider_2_EntryKind}
  EmitterRequest_cps_provider_2_forky_has{v_2: List<&2, U32>, +v_4: U32}
  EmitterRequest_cps_provider_2_calls_forky{v_2: List<&2, U32>, v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_row_calls_forky{v_2: List<&2, cps_provider_2_SegText>, v_5: List<&2, U32>, +v_7: U32}
  EmitterRequest_cps_provider_2_forky_seeds{v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_forky_round{v_2: List<&2, cps_provider_2_SegText>, v_5: List<&2, U32>, +v_8: List<&2, U32>}
  EmitterRequest_cps_provider_2_forky_fix{v_2: List<&2, cps_provider_2_SegText>, v_5: List<&2, U32>, +v_7: Nat}
  EmitterRequest_cps_provider_2_forky_rows{v_2: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_rows_max_resw{v_2: List<&2, cps_provider_2_SegText>, +v_4: Nat}
  EmitterRequest_cps_provider_2_fid_defines{v_2: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_hot_text{v_1: Bool}
  EmitterRequest_cps_provider_2_blk_shr_text{v_1: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_array_shared_text{v_1: Bool}
  EmitterRequest_cps_provider_2_cid_table{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_fid_table{v_2: List<&2, cps_provider_2_SegText>, v_5: List<&2, U32>}
  EmitterRequest_cps_provider_2_wl_table_text{v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_wl_table_rows{v_2: List<&2, cps_provider_2_SegText>, +v_5: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_wl_row_text{+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_wl_row_name{+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_registers_each{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_register_decls{v_1: Nat}
  EmitterRequest_cps_provider_2_register_names{v_1: Nat}
  EmitterRequest_cps_provider_2_register_list{v_2: List<&2, String>, +v_4: String}
  EmitterRequest_cps_provider_2_register_tail{+v_2: List<&2, String>, v_4: String}
  EmitterRequest_cps_provider_2_wl_load_rows{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_wl_last_rows{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_wl_save_rows{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_wl_take_rows{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_2_wl_macros{+v_1: Nat, v_3: Nat}
  EmitterRequest_cps_provider_2_runtime_defines{+v_2: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_table_or_zero{v_1: String}
  EmitterRequest_cps_provider_2_tables_part{v_1: cps_provider_2_Plan, +v_4: List<&2, cps_provider_2_SegText>, v_6: Nat}
  EmitterRequest_cps_provider_2_id_rows_check{v_2: List<&2, cps_provider_2_CidRow>, v_5: List<&2, cps_provider_2_SegText>}
  EmitterRequest_cps_provider_2_main_suppress{v_1: Bool}
  EmitterRequest_cps_provider_2_main_fid_index{v_1: Bool, v_4: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_main_pure_text{v_1: Bool}
  EmitterRequest_cps_provider_2_spins_part{}
  EmitterRequest_cps_provider_2_helper_core{}
  EmitterRequest_cps_provider_2_requests_part{v_1: cps_provider_2_Plan}
  EmitterRequest_cps_provider_2_requests_finish{v_1: cps_provider_2_Part, v_3: Bool, v_5: List<&2, BIR.Export>, +v_7: List<&2, BIR.Declaration>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>, +v_19: Map<&2, U32>, +v_22: List<&2, cps_provider_2_Entry>}
  EmitterRequest_cps_provider_2_requests_check{+v_2: List<&2, cps_provider_2_CImport>, v_5: List<&2, String>, +v_7: List<&2, BIR.Declaration>, v_9: List<&2, BIR.ConstructorLayout>, v_12: List<&2, cps_provider_2_CidRow>, v_15: Map<&2, U32>, v_18: Map<&2, U32>, v_21: Map<&2, U32>, v_24: Map<&2, U32>}
  EmitterRequest_cps_provider_2_requests_uncovered{v_2: List<&2, String>, v_5: List<&2, cps_provider_2_CImport>, +v_7: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_foreign_namespace{v_1: String, v_3: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_foreign_namespace_item{v_0: BIR.Declaration}
  EmitterRequest_cps_provider_2_requests_uncovered_one{v_2: Maybe<&2, String>, +v_4: String, v_7: List<&2, String>, +v_10: List<&2, cps_provider_2_CImport>, v_12: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_2_import_has_namespace{v_2: List<&2, cps_provider_2_CImport>, +v_4: String}
  EmitterRequest_cps_provider_2_import_has_namespace_one{v_1: Bool, v_4: List<&2, cps_provider_2_CImport>, v_6: String}
  EmitterRequest_cps_provider_2_requests_each{v_2: List<&2, cps_provider_2_CImport>, v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Declaration>, +v_9: List<&2, cps_provider_2_CidRow>, +v_12: Map<&2, U32>, +v_15: Map<&2, U32>, +v_18: Map<&2, U32>, +v_21: Map<&2, U32>}
  EmitterRequest_cps_provider_2_rewrite_source{v_1: cps_provider_4_Fragment, +v_3: String, +v_6: List<&2, cps_provider_2_CidRow>, +v_8: List<&2, BIR.Declaration>, v_11: Map<&2, U32>, v_14: Map<&2, U32>, v_17: Map<&2, U32>, v_20: Map<&2, U32>}
  EmitterRequest_cps_provider_2_cid_keys{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_fid_keys{v_1: List<&2, BIR.Declaration>}

type EmitterRequestGroup14 is Type:
  EmitterRequest_cps_provider_2_insert_section{v_2: List<&2, cps_provider_4_Fragment>, +v_4: String, +v_6: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_insert_rule{v_2: List<&2, cps_provider_4_Fragment>, v_4: cps_provider_4_Fragment, v_6: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_insert_prefix{v_3: Maybe<&2, List<&2, cps_provider_4_Fragment>>, v_5: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_split_lines{v_1: String}
  EmitterRequest_cps_provider_2_split_lines_each{v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: List<&2, String>}
  EmitterRequest_cps_provider_2_line_text{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_2_fragment_lines{v_2: List<&2, String>}
  EmitterRequest_cps_provider_2_join_lines{v_2: List<&2, cps_provider_4_Fragment>}
  EmitterRequest_cps_provider_2_join_pieces{v_2: List<&2, cps_provider_4_Fragment>, v_4: Bool, +v_6: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_assemble{v_1: String, v_3: cps_provider_4_Fragment, v_5: cps_provider_4_Fragment, v_7: cps_provider_4_Fragment, v_9: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_assemble_spins{v_2: List<&2, cps_provider_4_Fragment>, v_4: cps_provider_4_Fragment, v_6: cps_provider_4_Fragment, v_8: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_assemble_segments{v_2: List<&2, cps_provider_4_Fragment>, v_4: cps_provider_4_Fragment, v_6: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_assemble_requests{v_2: List<&2, cps_provider_4_Fragment>, v_4: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_2_cid_exact_map{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_cid_exact_each{v_2: List<&2, cps_provider_2_CidRow>, +v_5: Map<&2, String>}
  EmitterRequest_cps_provider_2_fid_exact_map{v_1: List<&2, BIR.Declaration>, v_4: Map<&2, U32>, v_7: Map<&2, U32>, v_10: Map<&2, U32>, v_13: Map<&2, U32>}
  EmitterRequest_cps_provider_2_namespaced_map{v_2: Map<&2, String>, v_5: List<&2, String>, v_7: String}
  EmitterRequest_cps_provider_2_namespaced_each{+v_2: Map<&2, String>, v_5: List<&2, String>, +v_7: String}
  EmitterRequest_cps_provider_2_namespaced_set{+v_2: Map<&2, String>, +v_4: String, v_6: String}
  EmitterRequest_cps_provider_2_fid_fixed{v_2: Map<&2, String>}
  EmitterRequest_cps_provider_2_fid_fixed_one{v_2: Map<&2, String>}
  EmitterRequest_cps_provider_2_fid_exact_decl{v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, String>, +v_7: Map<&2, U32>, +v_10: Map<&2, U32>, +v_13: Map<&2, U32>, +v_16: Map<&2, U32>}
  EmitterRequest_cps_provider_2_macro_collision_cids{v_2: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_macro_collision_rows{+v_2: List<&2, cps_provider_2_CidRow>, v_5: Map<&2, String>}
  EmitterRequest_cps_provider_2_macro_collision_one{+v_1: String, +v_3: String, v_6: List<&2, cps_provider_2_CidRow>, +v_9: Map<&2, String>, +v_12: List<&2, cps_provider_2_CidRow>}
  EmitterRequest_cps_provider_2_emit{v_0: BIR.Program, v_2: String, v_5: List<&2, cps_provider_2_CImport>}
  EmitterRequest_cps_provider_2_render{+v_1: cps_provider_2_Plan, v_3: String}
  EmitterRequest_cps_provider_2_render_parts{+v_1: cps_provider_2_Plan, v_3: String, v_6: Map<&2, String>, v_9: Map<&2, String>}
  EmitterRequest_cps_provider_2_segments_text{v_1: String}
  EmitterRequest_cps_provider_2_render_assemble{v_1: String, v_3: cps_provider_4_Fragment, v_5: cps_provider_4_Fragment, v_7: cps_provider_4_Fragment, v_9: cps_provider_4_Fragment, v_12: Map<&2, String>, v_15: Map<&2, String>}
  EmitterRequest_cps_provider_2_render_rewrite{v_1: cps_provider_4_Fragment, v_4: Map<&2, String>, v_7: Map<&2, String>}
  EmitterRequest_cps_provider_3_context{+v_0: BIR.Program}
  EmitterRequest_cps_provider_3_context_nf{+v_1: cps_provider_3_Context}
  EmitterRequest_cps_provider_3_context_families{+v_1: cps_provider_3_Context}
  EmitterRequest_cps_provider_3_context_plan{+v_1: cps_provider_3_Context}
  EmitterRequest_cps_provider_3_context_nodes{+v_1: cps_provider_3_Context}
  EmitterRequest_cps_provider_3_context_arms{+v_1: cps_provider_3_Context}
  EmitterRequest_cps_provider_3_nf_families{+v_1: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_3_nf_functions{+v_1: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_3_family_lookup{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_3_function_lookup{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_3_arm_of{+v_1: String, +v_3: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_3_arm_in{+v_1: String, +v_3: List<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_3_plan_arm_index{+v_1: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_3_plan_family_arms{+v_1: List<&2, BIR.DescriptorArm>, +v_3: Map<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_3_arm_declared{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_3_live_field{+v_0: BIR.Quantity}
  EmitterRequest_cps_provider_3_layout_fuel{}
  EmitterRequest_cps_provider_3_nf_of{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat}
  EmitterRequest_cps_provider_3_value_layout{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_3_layout_of_desc{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat}
  EmitterRequest_cps_provider_3_layout_of_val{+v_1: cps_provider_3_Context, +v_3: cps_provider_7_NfVal, +v_5: Nat}
  EmitterRequest_cps_provider_3_layout_val{+v_1: cps_provider_3_Context, +v_3: cps_provider_7_NfVal, +v_5: Nat}
  EmitterRequest_cps_provider_3_layout_unresolved{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_3_layout_family{+v_1: cps_provider_3_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat}
  EmitterRequest_cps_provider_3_layout_native{+v_1: cps_provider_3_Context, +v_3: String, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_10: List<&2, cps_provider_7_NfVal>, +v_12: Nat}
  EmitterRequest_cps_provider_3_field_scope{+v_2: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_3_arm_layouts{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_7_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_3_LayArm>}
  EmitterRequest_cps_provider_3_field_layouts{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_7_NfVal>, +v_8: Nat, +v_11: List<&2, cps_provider_3_Layout>}
  EmitterRequest_cps_provider_3_layout_data{+v_1: cps_provider_3_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_7_NfVal>, +v_10: Nat}
  EmitterRequest_cps_provider_3_arms_tagged{+v_2: List<&2, cps_provider_3_LayArm>}
  EmitterRequest_cps_provider_3_reenters{+v_1: cps_provider_3_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_8: List<&2, cps_provider_7_NfVal>, +v_10: Nat}
  EmitterRequest_cps_provider_3_fields_reach{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.DescriptorField>, +v_6: List<&2, cps_provider_7_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat}
  EmitterRequest_cps_provider_3_reaches{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat}

type EmitterRequestGroup15 is Type:
  EmitterRequest_cps_provider_3_reaches_val{+v_1: cps_provider_3_Context, +v_3: cps_provider_7_NfVal, +v_5: String, +v_8: List<&2, String>, +v_10: Nat}
  EmitterRequest_cps_provider_3_family_reach{+v_1: cps_provider_3_Context, +v_2: BIR.Family, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: String, +v_10: List<&2, String>, +v_12: Nat}
  EmitterRequest_cps_provider_3_reach_arms{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.DescriptorArm>, +v_6: List<&2, cps_provider_7_NfVal>, +v_8: String, +v_11: List<&2, String>, +v_13: Nat}
  EmitterRequest_cps_provider_3_args_reach{+v_1: cps_provider_3_Context, +v_4: List<&2, cps_provider_7_NfVal>, +v_6: String, +v_9: List<&2, String>, +v_11: Nat}
  EmitterRequest_cps_provider_3_str_member{+v_2: List<&2, String>, +v_4: String}
  EmitterRequest_cps_provider_3_layout_kinds{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_3_layout_words{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_3_canonical_word{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_3_pack_arms{+v_2: List<&2, cps_provider_3_LayArm>, +v_4: Bool}
  EmitterRequest_cps_provider_3_pack_arm_list{+v_2: List<&2, cps_provider_3_LayArm>, +v_4: Nat, +v_7: List<&2, cps_provider_3_CWord>}
  EmitterRequest_cps_provider_3_pack_field_list{+v_2: List<&2, cps_provider_3_Layout>, +v_4: Nat, +v_7: List<&2, cps_provider_3_CWord>}
  EmitterRequest_cps_provider_3_pack_kinds{+v_2: List<&2, cps_provider_3_CWord>, +v_4: Nat, +v_7: List<&2, cps_provider_3_CWord>}
  EmitterRequest_cps_provider_3_set_kind{+v_2: List<&2, cps_provider_3_CWord>, +v_4: Nat, +v_6: cps_provider_3_CWord}
  EmitterRequest_cps_provider_3_merge_kind{+v_1: cps_provider_3_CWord, +v_3: cps_provider_3_CWord}
  EmitterRequest_cps_provider_3_word_32{+v_1: cps_provider_3_CWord}
  EmitterRequest_cps_provider_3_pad_words{+v_2: List<&2, cps_provider_3_CWord>}
  EmitterRequest_cps_provider_3_pad_to{+v_2: List<&2, cps_provider_3_CWord>, +v_4: Nat}
  EmitterRequest_cps_provider_3_pow2_upto{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_3_ceil_log2{+v_1: Nat}
  EmitterRequest_cps_provider_3_ceil_log2_go{+v_1: Nat, +v_3: Nat, +v_5: Nat}
  EmitterRequest_cps_provider_3_node_layout{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_3_node_layout_fuel{+v_1: cps_provider_3_Context, +v_3: String, +v_5: Nat}
  EmitterRequest_cps_provider_3_node_at{+v_1: cps_provider_3_Context, +v_3: String, +v_5: Nat}
  EmitterRequest_cps_provider_3_plan_node{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_3_node_compute{+v_1: cps_provider_3_Context, +v_3: String, +v_5: Nat}
  EmitterRequest_cps_provider_3_unresolved_message{+v_1: String}
  EmitterRequest_cps_provider_3_node_arm{+v_1: cps_provider_3_Context, +v_2: BIR.DescriptorArm, +v_4: Nat}
  EmitterRequest_cps_provider_3_plan_node_index{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_3_node_declared{+v_1: cps_provider_3_Context, +v_3: String}
  EmitterRequest_cps_provider_3_node_slots{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.DescriptorField>, +v_5: U32, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_3_NodeSlot>}
  EmitterRequest_cps_provider_3_node_finish{+v_2: List<&2, cps_provider_3_NodeSlot>}
  EmitterRequest_cps_provider_3_slot_words{+v_2: List<&2, cps_provider_3_NodeSlot>}
  EmitterRequest_cps_provider_3_packed_words{+v_2: List<&2, cps_provider_3_CWord>}
  EmitterRequest_cps_provider_3_node_slot{+v_1: cps_provider_3_Context, +v_3: String, +v_5: U32}
  EmitterRequest_cps_provider_3_slot_find{+v_2: List<&2, cps_provider_3_NodeSlot>, +v_4: U32}
  EmitterRequest_cps_provider_3_layout_fill{+v_1: cps_provider_3_Context, +v_3: cps_provider_3_Layout}
  EmitterRequest_cps_provider_3_layout_fill_fuel{+v_1: cps_provider_3_Context, +v_3: cps_provider_3_Layout, +v_5: Nat}
  EmitterRequest_cps_provider_3_layout_unfill{+v_1: cps_provider_3_Context, +v_3: cps_provider_3_Layout}
  EmitterRequest_cps_provider_3_layout_unfill_fuel{+v_1: cps_provider_3_Context, +v_3: cps_provider_3_Layout, +v_5: Nat}
  EmitterRequest_cps_provider_3_slot_fill{+v_1: cps_provider_3_Context, +v_3: String, +v_5: U32}
  EmitterRequest_cps_provider_3_slot_unfill{+v_1: cps_provider_3_Context, +v_3: String, +v_5: U32}
  EmitterRequest_cps_provider_3_form_arms{+v_1: cps_provider_3_Context, +v_4: List<&2, cps_provider_3_LayArm>, +v_6: Nat, +v_8: Bool, +v_10: Nat, +v_12: Nat, +v_15: List<&2, cps_provider_3_FormArm>, +v_17: Bool}
  EmitterRequest_cps_provider_3_form_arm{+v_1: cps_provider_3_Context, +v_3: String, +v_5: Nat, +v_7: Bool, +v_9: Nat, +v_12: List<&2, cps_provider_3_Layout>, +v_14: Nat, +v_16: Bool}
  EmitterRequest_cps_provider_3_tag_word{+v_1: Bool}
  EmitterRequest_cps_provider_3_form_nests{+v_1: cps_provider_3_Context, +v_4: List<&2, cps_provider_3_Layout>, +v_7: List<&2, cps_provider_3_NodeSlot>, +v_9: Nat, +v_11: Nat, +v_13: Nat, +v_15: Nat, +v_18: List<&2, cps_provider_3_Nest>, +v_20: Bool}
  EmitterRequest_cps_provider_3_nest{+v_1: Nat, +v_3: Nat, +v_5: cps_provider_3_Unfill, +v_7: cps_provider_3_Fill}
  EmitterRequest_cps_provider_3_nest_fits{+v_1: Nat, +v_3: Nat, +v_5: Nat, +v_7: Nat, +v_9: cps_provider_3_Unfill, +v_11: cps_provider_3_Fill}
  EmitterRequest_cps_provider_3_fill_words{+v_1: cps_provider_3_Fill}
  EmitterRequest_cps_provider_3_unfill_words{+v_1: cps_provider_3_Unfill}
  EmitterRequest_cps_provider_3_head_native{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_3_head_other{+v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_3_head_value{+v_1: cps_provider_3_Context, +v_3: cps_provider_7_NfVal}
  EmitterRequest_cps_provider_3_norm{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_3_head_args{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_3_arm_fields{+v_1: cps_provider_3_Context, +v_3: String, +v_4: BIR.Descriptor}
  EmitterRequest_cps_provider_3_arm_fields_value{+v_1: cps_provider_3_Context, +v_3: String, +v_5: cps_provider_7_NfVal}
  EmitterRequest_cps_provider_3_instantiate_fields{+v_1: cps_provider_3_Context, +v_4: List<&2, cps_provider_7_NfVal>, +v_6: List<&2, BIR.DescriptorField>, +v_8: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_3_array_cell{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_3_cell_of{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_3_cell_boxed{+v_1: cps_provider_3_BoxReason}
  EmitterRequest_cps_provider_3_max_one{+v_1: Nat}
  EmitterRequest_cps_provider_3_layout_has_term{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_3_word_has_term{+v_1: cps_provider_3_CWord}
  EmitterRequest_cps_provider_3_any_word_has_term{+v_2: List<&2, cps_provider_3_CWord>}

type EmitterRequestGroup16 is Type:
  EmitterRequest_cps_provider_4_chars_rev{v_1: String, +v_4: List<&2, Char>}
  EmitterRequest_cps_provider_4_text_of_rev{v_2: List<&2, Char>, +v_4: String}
  EmitterRequest_cps_provider_4_text_prepend{v_1: String, +v_3: String}
  EmitterRequest_cps_provider_4_pieces_fold{v_2: List<&2, String>, +v_4: String}
  EmitterRequest_cps_provider_4_pieces_from_end{v_2: List<&2, String>}
  EmitterRequest_cps_provider_4_text_of_pieces{v_2: List<&2, String>}
  EmitterRequest_cps_provider_4_chars_forward{v_1: String}
  EmitterRequest_cps_provider_4_fragments{v_2: List<&2, String>}
  EmitterRequest_cps_provider_4_fragment_leaves{v_2: List<&2, cps_provider_4_Fragment>, +v_5: List<&2, String>}
  EmitterRequest_cps_provider_4_fragment_text{v_1: cps_provider_4_Fragment}
  EmitterRequest_cps_provider_4_fragment_chars{v_2: List<&2, cps_provider_4_Fragment>, +v_5: List<&2, Char>}
  EmitterRequest_cps_provider_4_fragment_match{v_2: List<&2, cps_provider_4_Fragment>, +v_4: String, +v_6: Bool}
  EmitterRequest_cps_provider_4_fragment_match_leaf{v_1: String, v_3: String, +v_6: List<&2, cps_provider_4_Fragment>, +v_8: Bool}
  EmitterRequest_cps_provider_4_fragment_eq{v_1: cps_provider_4_Fragment, v_3: String}
  EmitterRequest_cps_provider_4_fragment_starts_with{v_1: cps_provider_4_Fragment, v_3: String}
  EmitterRequest_cps_provider_4_utf8_bytes_deep_of{v_1: Bool, +v_3: U32}
  EmitterRequest_cps_provider_4_utf8_bytes_deep{+v_1: U32}
  EmitterRequest_cps_provider_4_utf8_bytes_wide_of{v_1: Bool, +v_3: U32}
  EmitterRequest_cps_provider_4_utf8_bytes_wide{+v_1: U32}
  EmitterRequest_cps_provider_4_utf8_bytes_of{v_1: Bool, +v_3: U32}
  EmitterRequest_cps_provider_4_utf8_bytes{+v_1: U32}
  EmitterRequest_cps_provider_4_oct3{+v_1: U32}
  EmitterRequest_cps_provider_4_octals{v_2: List<&2, U32>, +v_4: String}
  EmitterRequest_cps_provider_4_utf8_width_wide{v_1: Bool}
  EmitterRequest_cps_provider_4_utf8_width_two{v_1: Bool, +v_3: U32}
  EmitterRequest_cps_provider_4_utf8_width_of{v_1: Bool, +v_3: U32}
  EmitterRequest_cps_provider_4_utf8_width{+v_1: U32}
  EmitterRequest_cps_provider_4_utf8_len_go{v_1: String, +v_3: Nat}
  EmitterRequest_cps_provider_4_utf8_byte_len{+v_1: String}
  EmitterRequest_cps_provider_4_literal_high{v_1: U32}
  EmitterRequest_cps_provider_4_literal_wide_of{v_1: Bool, +v_3: U32, +v_5: Char}
  EmitterRequest_cps_provider_4_literal_wide{+v_1: U32, +v_3: Char}
  EmitterRequest_cps_provider_4_literal_plain_of{v_1: Bool, +v_3: Char}
  EmitterRequest_cps_provider_4_literal_plain{+v_1: Char}
  EmitterRequest_cps_provider_4_literal_piece{v_1: Char}
  EmitterRequest_cps_provider_4_literal_pieces{v_2: List<&2, Char>, +v_5: List<&2, String>}
  EmitterRequest_cps_provider_4_c_string_literal{+v_1: String}
  EmitterRequest_cps_provider_4_text_hex_digit{+v_1: Nat}
  EmitterRequest_cps_provider_4_text_hex_nibble{v_1: Nat, +v_3: U32}
  EmitterRequest_cps_provider_4_text_hex_word{+v_1: U32}
  EmitterRequest_cps_provider_4_text_plain_wide{+v_1: U32}
  EmitterRequest_cps_provider_4_text_plain_char{+v_1: Char}
  EmitterRequest_cps_provider_4_text_piece_of{v_1: Bool, +v_3: Char}
  EmitterRequest_cps_provider_4_text_piece{+v_1: Char}
  EmitterRequest_cps_provider_4_text_pieces{v_2: List<&2, Char>, +v_5: List<&2, String>}
  EmitterRequest_cps_provider_4_c_text_literal{+v_1: String}
  EmitterRequest_cps_provider_4_text_piece_bytes_of{v_1: Bool}
  EmitterRequest_cps_provider_4_text_piece_bytes{+v_1: Char}
  EmitterRequest_cps_provider_4_text_len_go{v_1: String, +v_3: Nat}
  EmitterRequest_cps_provider_4_text_byte_len{+v_1: String}
  EmitterRequest_cps_provider_4_link_complete{v_2: Maybe<&2, String>, v_5: List<&2, Char>}
  EmitterRequest_cps_provider_4_link_result{v_1: cps_provider_4_Scan}
  EmitterRequest_cps_provider_4_is_word{+v_1: Char}
  EmitterRequest_cps_provider_4_is_key_char{+v_1: Char}
  EmitterRequest_cps_provider_4_text_closes{v_2: List<&2, Char>, +v_4: Char, +v_6: Bool}
  EmitterRequest_cps_provider_4_block_closes{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_4_code_entry_slash{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_4_code_entry{v_1: Char, +v_4: List<&2, Char>}
  EmitterRequest_cps_provider_4_emit_chars{v_2: List<&2, Char>, +v_5: List<&2, Char>}
  EmitterRequest_cps_provider_4_resolved_text{v_2: Maybe<&2, String>}
  EmitterRequest_cps_provider_4_first_problem{+v_2: Maybe<&2, String>, v_4: String}
  EmitterRequest_cps_provider_4_prefix_named{v_1: Bool}
  EmitterRequest_cps_provider_4_prefix_text{v_1: Char}
  EmitterRequest_cps_provider_4_missing_id{v_1: Char, v_3: String}

type EmitterRequestGroup17 is Type:
  EmitterRequest_cps_provider_4_next_failure{v_1: Char, v_3: String, v_6: Maybe<&2, String>, +v_9: Maybe<&2, String>}
  EmitterRequest_cps_provider_4_lookup_named{v_1: Bool, v_4: Map<&2, String>, v_7: Map<&2, String>, +v_9: String}
  EmitterRequest_cps_provider_4_lookup_id{v_1: Char, v_4: Map<&2, String>, v_7: Map<&2, String>, +v_9: String}
  EmitterRequest_cps_provider_4_flush_key{+v_1: Char, v_4: List<&2, Char>, +v_6: Char, v_9: List<&2, Char>}
  EmitterRequest_cps_provider_4_flush_open{v_1: Char, v_4: List<&2, Char>, v_7: List<&2, Char>}
  EmitterRequest_cps_provider_4_flush_empty{v_1: Char, v_4: List<&2, Char>}
  EmitterRequest_cps_provider_4_key_text{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_4_scan{v_2: List<&2, Char>, +v_4: cps_provider_4_Mode, +v_6: Bool, +v_9: Maybe<&2, String>, +v_12: List<&2, Char>, +v_15: Map<&2, String>, +v_18: Map<&2, String>}
  EmitterRequest_cps_provider_4_rewrite{v_1: String, v_4: Map<&2, String>, v_7: Map<&2, String>}
  EmitterRequest_cps_provider_4_rewrite_fragment{v_1: cps_provider_4_Fragment, v_4: Map<&2, String>, v_7: Map<&2, String>}
  EmitterRequest_cps_provider_5_world{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, cps_provider_5_CidSym>}
  EmitterRequest_cps_provider_5_join_text{+v_2: List<&2, String>}
  EmitterRequest_cps_provider_5_code_line{+v_1: String}
  EmitterRequest_cps_provider_5_code_empty{}
  EmitterRequest_cps_provider_5_code_seq{+v_1: cps_provider_5_Code, +v_3: cps_provider_5_Code}
  EmitterRequest_cps_provider_5_code_text{+v_2: List<&2, String>, +v_4: String}
  EmitterRequest_cps_provider_5_part_of{+v_1: cps_provider_5_Code, +v_3: String}
  EmitterRequest_cps_provider_5_ctor_find{+v_1: U32, +v_3: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_5_ctor_of{+v_1: U32, +v_3: cps_provider_5_World}
  EmitterRequest_cps_provider_5_cid_find{+v_1: String, +v_4: List<&2, cps_provider_5_CidSym>}
  EmitterRequest_cps_provider_5_cid_of{+v_1: String, +v_3: cps_provider_5_World}
  EmitterRequest_cps_provider_5_cid_text_of{+v_2: Maybe<&2, U32>}
  EmitterRequest_cps_provider_5_cid_text{+v_1: String, +v_3: cps_provider_5_World}
  EmitterRequest_cps_provider_5_intrinsic_marker{+v_1: String}
  EmitterRequest_cps_provider_5_dst_write{+v_1: cps_provider_5_Dst, +v_3: String}
  EmitterRequest_cps_provider_5_dst_word{+v_1: cps_provider_5_Dst, +v_3: cps_provider_3_CWord, +v_5: String}
  EmitterRequest_cps_provider_5_dst_decl{+v_1: String, +v_3: String, +v_5: Nat}
  EmitterRequest_cps_provider_5_dst_mark{+v_1: cps_provider_5_Dst, +v_3: Nat}
  EmitterRequest_cps_provider_5_form_base{+v_1: Nat, +v_3: Bool}
  EmitterRequest_cps_provider_5_form_pad{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_5_nests_take_words{+v_2: List<&2, cps_provider_3_Nest>}
  EmitterRequest_cps_provider_5_nests_make_words{+v_2: List<&2, cps_provider_3_Nest>}
  EmitterRequest_cps_provider_5_src_skip_jobs{+v_1: cps_provider_5_Src, +v_3: Nat}
  EmitterRequest_cps_provider_5_dst_skip_jobs{+v_1: cps_provider_5_Dst, +v_3: Nat}
  EmitterRequest_cps_provider_5_src_read_node{+v_1: String, +v_3: String, +v_5: String, +v_7: Bool, +v_9: String}
  EmitterRequest_cps_provider_5_src_read_arr{+v_1: String, +v_3: String, +v_5: Bool, +v_7: String, +v_9: String}
  EmitterRequest_cps_provider_5_src_read_block{+v_1: String, +v_3: String, +v_5: Bool, +v_7: Bool, +v_9: String, +v_11: String}
  EmitterRequest_cps_provider_5_src_read{+v_1: cps_provider_5_Src, +v_3: String}
  EmitterRequest_cps_provider_5_form_tagged{+v_2: List<&2, cps_provider_3_FormArm>}
  EmitterRequest_cps_provider_5_max_node_words{+v_2: List<&2, cps_provider_3_FormArm>, +v_4: Nat}
  EmitterRequest_cps_provider_5_max_term_decl{+v_1: String, +v_3: Nat}
  EmitterRequest_cps_provider_5_arm_seed{+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String}
  EmitterRequest_cps_provider_5_arm_seed_words{+v_1: Nat, +v_3: String, +v_5: String, +v_7: String}
  EmitterRequest_cps_provider_5_arm_src{+v_1: Bool, +v_3: Nat, +v_5: String, +v_7: String, +v_9: String}
  EmitterRequest_cps_provider_5_nests_jobs{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_Nest>, +v_6: cps_provider_5_Src, +v_8: cps_provider_5_Dst, +v_10: String, +v_12: Nat}
  EmitterRequest_cps_provider_5_arm_release{+v_1: Bool, +v_3: Nat, +v_5: String}
  EmitterRequest_cps_provider_5_jobs_arm_body{+v_1: cps_provider_5_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_14: List<&2, cps_provider_3_Nest>, +v_16: String, +v_18: cps_provider_5_Dst, +v_20: String, +v_22: Bool, +v_24: String, +v_26: Nat}
  EmitterRequest_cps_provider_5_jobs_arm{+v_1: cps_provider_5_World, +v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_11: Nat, +v_14: List<&2, cps_provider_3_Nest>, +v_16: String, +v_18: cps_provider_5_Dst, +v_20: String, +v_22: Bool, +v_24: String, +v_26: Nat}
  EmitterRequest_cps_provider_5_arm_jobs{+v_1: cps_provider_5_World, +v_4: Maybe<&2, U32>, +v_6: cps_provider_3_FormArm, +v_8: Nat, +v_10: String, +v_12: cps_provider_5_Dst, +v_14: String, +v_16: Bool, +v_18: String, +v_20: Nat}
  EmitterRequest_cps_provider_5_unbox_cases{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_FormArm>, +v_6: Nat, +v_8: String, +v_10: cps_provider_5_Dst, +v_12: String, +v_14: Bool, +v_16: String}
  EmitterRequest_cps_provider_5_expand_unbox{+v_1: cps_provider_5_World, +v_3: Nat, +v_6: List<&2, cps_provider_3_FormArm>, +v_8: cps_provider_5_Src, +v_10: cps_provider_5_Dst, +v_12: String}
  EmitterRequest_cps_provider_5_expand_word_take{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Fill, +v_5: cps_provider_5_Src, +v_7: cps_provider_5_Dst, +v_9: String}
  EmitterRequest_cps_provider_5_nest_take{+v_1: cps_provider_3_Nest}
  EmitterRequest_cps_provider_5_nest_make{+v_1: cps_provider_3_Nest}
  EmitterRequest_cps_provider_5_field_pair_jobs{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_Nest>, +v_7: List<&2, cps_provider_3_Nest>, +v_9: cps_provider_5_Src, +v_11: cps_provider_5_Dst, +v_13: String, +v_15: Nat}
  EmitterRequest_cps_provider_5_forms_arm_body{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_Nest>, +v_6: Nat, +v_8: Nat, +v_10: Bool, +v_13: Maybe<&2, cps_provider_3_FormArm>, +v_15: cps_provider_5_Src, +v_17: cps_provider_5_Dst, +v_19: String}
  EmitterRequest_cps_provider_5_forms_arm_case{+v_1: cps_provider_5_World, +v_4: Maybe<&2, cps_provider_3_FormArm>, +v_6: cps_provider_3_FormArm, +v_8: Nat, +v_10: Nat, +v_12: Bool, +v_14: cps_provider_5_Src, +v_16: cps_provider_5_Dst, +v_18: String, +v_20: Nat}
  EmitterRequest_cps_provider_5_form_arm_by_key{+v_1: String, +v_4: List<&2, cps_provider_3_FormArm>}
  EmitterRequest_cps_provider_5_forms_cases{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_FormArm>, +v_7: List<&2, cps_provider_3_FormArm>, +v_9: Nat, +v_11: Nat, +v_13: Bool, +v_15: cps_provider_5_Src, +v_17: cps_provider_5_Dst, +v_19: String, +v_21: Nat}
  EmitterRequest_cps_provider_5_expand_forms{+v_1: cps_provider_5_World, +v_3: Nat, +v_6: List<&2, cps_provider_3_FormArm>, +v_8: Nat, +v_11: List<&2, cps_provider_3_FormArm>, +v_13: cps_provider_5_Src, +v_15: cps_provider_5_Dst, +v_17: String}
  EmitterRequest_cps_provider_5_forms_single{+v_1: cps_provider_5_World, +v_3: cps_provider_3_FormArm, +v_5: Nat, +v_7: Nat, +v_9: Bool, +v_12: List<&2, cps_provider_3_FormArm>, +v_14: cps_provider_5_Src, +v_16: cps_provider_5_Dst, +v_18: String}
  EmitterRequest_cps_provider_5_pack_jobs{+v_1: U32, +v_3: Nat, +v_5: Bool, +v_7: String, +v_9: String, +v_11: String}
  EmitterRequest_cps_provider_5_arm_block_jobs{+v_1: cps_provider_5_World, +v_3: U32, +v_5: cps_provider_3_FormArm, +v_7: Nat, +v_9: cps_provider_5_Src, +v_11: String, +v_13: String, +v_15: Nat}
  EmitterRequest_cps_provider_5_box_arm_jobs{+v_1: cps_provider_5_World, +v_4: Maybe<&2, U32>, +v_6: cps_provider_3_FormArm, +v_8: Nat, +v_10: cps_provider_5_Src, +v_12: String, +v_14: String, +v_16: Nat}

type EmitterRequestGroup18 is Type:
  EmitterRequest_cps_provider_5_box_cases{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_FormArm>, +v_6: Nat, +v_8: cps_provider_5_Src, +v_10: String, +v_12: String, +v_14: Nat}
  EmitterRequest_cps_provider_5_box_untagged{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_FormArm>, +v_6: Nat, +v_8: cps_provider_5_Src, +v_10: String, +v_12: String}
  EmitterRequest_cps_provider_5_expand_box{+v_1: cps_provider_5_World, +v_3: Nat, +v_6: List<&2, cps_provider_3_FormArm>, +v_8: cps_provider_5_Src, +v_10: cps_provider_5_Dst, +v_12: String}
  EmitterRequest_cps_provider_5_expand_box_body{+v_1: Bool, +v_3: Nat, +v_5: cps_provider_5_World, +v_8: List<&2, cps_provider_3_FormArm>, +v_10: cps_provider_5_Src, +v_12: cps_provider_5_Dst, +v_14: String, +v_16: String}
  EmitterRequest_cps_provider_5_expand_form_take{+v_1: cps_provider_5_World, +v_3: Nat, +v_6: List<&2, cps_provider_3_FormArm>, +v_8: cps_provider_3_Fill, +v_10: cps_provider_5_Src, +v_12: cps_provider_5_Dst, +v_14: String}
  EmitterRequest_cps_provider_5_expand_conv{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Unfill, +v_5: cps_provider_3_Fill, +v_7: cps_provider_5_Src, +v_9: cps_provider_5_Dst, +v_11: String}
  EmitterRequest_cps_provider_5_run_jobs{+v_2: List<&2, cps_provider_5_Job>, +v_4: cps_provider_5_World, +v_7: List<&2, String>}
  EmitterRequest_cps_provider_5_fill_plan_jobs{+v_1: cps_provider_3_Fill, +v_3: String, +v_5: cps_provider_5_Dst, +v_7: String}
  EmitterRequest_cps_provider_5_fill_result_jobs{+v_1: cps_provider_3_FillResult, +v_3: String, +v_5: cps_provider_5_Dst, +v_7: String}
  EmitterRequest_cps_provider_5_fill_data_jobs{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String, +v_7: cps_provider_5_Dst, +v_9: String}
  EmitterRequest_cps_provider_5_fill_jobs{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String, +v_7: cps_provider_5_Dst, +v_9: String}
  EmitterRequest_cps_provider_5_unfill_result_jobs{+v_1: cps_provider_3_UnfillResult, +v_3: cps_provider_5_Src, +v_5: String, +v_7: String}
  EmitterRequest_cps_provider_5_unfill_data_jobs{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: cps_provider_5_Src, +v_7: String, +v_9: String}
  EmitterRequest_cps_provider_5_unfill_word_jobs{+v_1: cps_provider_3_CWord, +v_3: cps_provider_5_Src, +v_5: String, +v_7: String}
  EmitterRequest_cps_provider_5_unfill_jobs{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: cps_provider_5_Src, +v_7: String, +v_9: String}
  EmitterRequest_cps_provider_5_operand_code{+v_1: cps_provider_3_Layout, +v_2: BIR.Use, +v_4: String, +v_6: String}
  EmitterRequest_cps_provider_5_operand_name{+v_1: cps_provider_3_Layout, +v_2: BIR.Use, +v_4: String, +v_6: String}
  EmitterRequest_cps_provider_5_text_jobs{+v_2: List<&2, String>}
  EmitterRequest_cps_provider_5_code_jobs{+v_1: cps_provider_5_Code}
  EmitterRequest_cps_provider_5_fill_slots_jobs{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_NodeSlot>, +v_7: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_layout_is_data{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_seal_box_many{+v_1: String, +v_3: Bool}
  EmitterRequest_cps_provider_5_seal_box{+v_0: BIR.Use, +v_2: String, +v_4: Bool}
  EmitterRequest_cps_provider_5_seal_kind{+v_0: BIR.Use, +v_2: cps_provider_3_CWord, +v_4: String, +v_6: Bool}
  EmitterRequest_cps_provider_5_seal_kind_walk{+v_0: BIR.Use, +v_3: List<&2, cps_provider_3_CWord>, +v_5: String, +v_7: Bool}
  EmitterRequest_cps_provider_5_seal_slots_jobs{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_NodeSlot>, +v_7: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_one_job{+v_1: cps_provider_5_Job}
  EmitterRequest_cps_provider_5_construct_words{+v_1: cps_provider_5_World, +v_3: U32, +v_5: Nat, +v_8: List<&2, cps_provider_3_NodeSlot>, +v_11: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_codeSeqPack{+v_1: cps_provider_5_Code, +v_3: cps_provider_5_World, +v_5: cps_provider_3_Layout, +v_7: String, +v_9: U32}
  EmitterRequest_cps_provider_5_construct_packed_one{+v_1: cps_provider_5_World, +v_3: U32, +v_5: cps_provider_3_NodeSlot, +v_7: cps_provider_5_Operand}
  EmitterRequest_cps_provider_5_construct_packed{+v_1: cps_provider_5_World, +v_3: U32, +v_5: String, +v_7: cps_provider_3_Node, +v_10: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_packed_flag{+v_1: Bool, +v_3: cps_provider_5_World, +v_5: U32, +v_7: String, +v_9: cps_provider_3_Node, +v_12: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_count{+v_1: Bool, +v_3: cps_provider_5_World, +v_5: U32, +v_7: String, +v_9: cps_provider_3_Node, +v_12: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_node{+v_1: cps_provider_5_World, +v_3: U32, +v_5: String, +v_7: cps_provider_3_Node, +v_10: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_layout{+v_1: cps_provider_3_NodeResult, +v_3: cps_provider_5_World, +v_5: U32, +v_7: String, +v_10: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_cid{+v_2: Maybe<&2, U32>, +v_4: cps_provider_5_World, +v_6: String, +v_9: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_generic{+v_1: cps_provider_5_World, +v_3: String, +v_6: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_marker{+v_1: Bool, +v_3: cps_provider_5_World, +v_5: String, +v_8: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_native{+v_2: Maybe<&2, String>, +v_4: cps_provider_5_World, +v_6: String, +v_9: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_row{+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: cps_provider_5_World, +v_6: List<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_construct_part{+v_1: U32, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_term_decl_text{+v_1: Nat}
  EmitterRequest_cps_provider_5_project_prelude{+v_1: cps_provider_3_Layout, +v_3: String, +v_5: Nat, +v_7: Nat}
  EmitterRequest_cps_provider_5_project_words{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: Nat, +v_7: Nat, +v_9: String}
  EmitterRequest_cps_provider_5_project_packed_prelude{+v_1: cps_provider_3_Layout, +v_3: String}
  EmitterRequest_cps_provider_5_project_packed{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String}
  EmitterRequest_cps_provider_5_project_packed_flag{+v_1: Bool, +v_3: cps_provider_5_World, +v_5: cps_provider_3_Layout, +v_7: Nat, +v_9: Nat, +v_11: String}
  EmitterRequest_cps_provider_5_unique_expr{+v_1: String}
  EmitterRequest_cps_provider_5_static_expr{+v_1: String}
  EmitterRequest_cps_provider_5_and_expr{+v_1: String, +v_3: String}
  EmitterRequest_cps_provider_5_or_expr{+v_1: String, +v_3: String}
  EmitterRequest_cps_provider_5_nat_if{+v_1: Bool, +v_3: Nat, +v_5: Nat}
  EmitterRequest_cps_provider_5_live_ordinal{+v_1: List<&2, BIR.DescriptorField>, +v_3: U32}
  EmitterRequest_cps_provider_5_live_walk{+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat, +v_7: Nat}
  EmitterRequest_cps_provider_5_live_next{+v_0: BIR.Quantity, +v_2: Nat}
  EmitterRequest_cps_provider_5_arm_fields_of{+v_2: List<&2, cps_provider_3_LayArm>, +v_4: String}
  EmitterRequest_cps_provider_5_arm_fields_declared{+v_1: Maybe<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_5_arm_descriptor_fields{+v_1: cps_provider_5_World, +v_3: String}
  EmitterRequest_cps_provider_5_step_key{+v_1: cps_provider_5_World, +v_3: U32}
  EmitterRequest_cps_provider_5_cell_lgs{+v_1: cps_provider_5_World, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_5_not_bool{+v_1: Bool}
  EmitterRequest_cps_provider_5_live_ordinal_in{+v_1: List<&2, BIR.DescriptorField>, +v_3: U32, +v_5: U32, +v_7: U32}
  EmitterRequest_cps_provider_5_inline_slot{+v_2: List<&2, cps_provider_3_Layout>, +v_4: Nat, +v_6: Nat}
  EmitterRequest_cps_provider_5_inline_start{+v_2: List<&2, cps_provider_3_LayArm>}

type EmitterRequestGroup19 is Type:
  EmitterRequest_cps_provider_5_state_array{+v_1: cps_provider_5_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor}
  EmitterRequest_cps_provider_5_state_from_array_value{+v_1: cps_provider_5_World, +v_3: String, +v_5: String, +v_7: String, +v_8: BIR.Descriptor}
  EmitterRequest_cps_provider_5_resolve_field{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState, +v_5: U32, +v_7: U32, +v_10: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_resolve_slot_field{+v_1: cps_provider_5_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: cps_provider_3_Layout, +v_11: String, +v_13: String, +v_15: String, +v_17: Bool, +v_20: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_resolve_cell_field{+v_1: cps_provider_5_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: Bool, +v_11: String, +v_13: cps_provider_3_Layout, +v_15: Nat, +v_17: String, +v_19: String, +v_22: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_resolve_buf_field{+v_1: cps_provider_5_World, +v_3: String, +v_5: U32, +v_7: String, +v_9: String, +v_11: cps_provider_3_Layout, +v_13: String, +v_15: String, +v_18: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_resolve_node_slot{+v_1: cps_provider_5_World, +v_3: String, +v_5: U32, +v_7: Nat, +v_9: String, +v_11: String, +v_13: String, +v_16: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_root_array_path{+v_1: cps_provider_5_World, +v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_advance{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState, +v_6: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_array_from_state{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState, +v_4: BIR.Descriptor}
  EmitterRequest_cps_provider_5_half_state{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState, +v_5: Bool, +v_6: BIR.Descriptor, +v_9: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_leaf_state{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState, +v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_resolve_path{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_5_PathStep>}
  EmitterRequest_cps_provider_5_path_prelude{+v_1: String}
  EmitterRequest_cps_provider_5_path_expr{+v_1: String, +v_3: String}
  EmitterRequest_cps_provider_5_keep_copy{+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_11: cps_provider_3_Layout, +v_13: String}
  EmitterRequest_cps_provider_5_keep_copy_fields{+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_3_Layout>, +v_14: String}
  EmitterRequest_cps_provider_5_keep_copy_cases{+v_1: String, +v_3: String, +v_5: String, +v_7: Nat, +v_9: Nat, +v_12: List<&2, cps_provider_3_LayArm>, +v_14: String, +v_16: Nat}
  EmitterRequest_cps_provider_5_move_copy{+v_1: String, +v_3: Nat, +v_5: Nat, +v_7: cps_provider_3_Layout, +v_9: String}
  EmitterRequest_cps_provider_5_move_copy_fields{+v_1: String, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_3_Layout>, +v_10: String}
  EmitterRequest_cps_provider_5_move_copy_cases{+v_1: String, +v_3: Nat, +v_5: Nat, +v_8: List<&2, cps_provider_3_LayArm>, +v_10: String, +v_12: Nat}
  EmitterRequest_cps_provider_5_raw_word_expr{+v_1: String, +v_3: Nat, +v_5: cps_provider_3_CWord}
  EmitterRequest_cps_provider_5_packed_form_body{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String}
  EmitterRequest_cps_provider_5_read_body{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_tag_single{+v_1: cps_provider_5_World, +v_3: String, +v_6: Maybe<&2, U32>, +v_8: String}
  EmitterRequest_cps_provider_5_tag_multi{+v_1: cps_provider_5_World, +v_3: String, +v_5: Nat, +v_8: List<&2, cps_provider_3_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String}
  EmitterRequest_cps_provider_5_tag_case_line{+v_1: String, +v_3: Nat, +v_5: U32, +v_8: Maybe<&2, U32>, +v_10: String}
  EmitterRequest_cps_provider_5_tag_multi_packed{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_LayArm>, +v_7: Maybe<&2, U32>, +v_9: String}
  EmitterRequest_cps_provider_5_tag_multi_packed_go{+v_1: cps_provider_5_World, +v_4: List<&2, cps_provider_3_LayArm>, +v_7: Maybe<&2, U32>, +v_9: Nat, +v_11: String, +v_13: String}
  EmitterRequest_cps_provider_5_tag_multi_buf{+v_1: cps_provider_5_World, +v_3: String, +v_5: String, +v_8: List<&2, cps_provider_3_LayArm>, +v_11: Maybe<&2, U32>, +v_13: String}
  EmitterRequest_cps_provider_5_tag_multi_buf_go{+v_1: cps_provider_5_World, +v_3: String, +v_5: String, +v_8: List<&2, cps_provider_3_LayArm>, +v_11: Maybe<&2, U32>, +v_13: Nat, +v_15: String, +v_17: String}
  EmitterRequest_cps_provider_5_tag_body{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState, +v_6: Maybe<&2, U32>, +v_8: String}
  EmitterRequest_cps_provider_5_copy_slot_body{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_packed_data_value{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_packed_data_copy{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_box_copy_body{+v_1: String, +v_3: Nat, +v_5: String, +v_7: String}
  EmitterRequest_cps_provider_5_data_copy_body{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String, +v_7: Nat, +v_9: String, +v_11: String}
  EmitterRequest_cps_provider_5_zero_value_body{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_buf_clear_words{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String}
  EmitterRequest_cps_provider_5_buf_field_body{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String, +v_7: String, +v_9: Bool}
  EmitterRequest_cps_provider_5_buf_move_clear{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool}
  EmitterRequest_cps_provider_5_cell_arr_body{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String, +v_7: String, +v_9: String, +v_11: String, +v_13: Bool}
  EmitterRequest_cps_provider_5_cell_move_clear{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Bool}
  EmitterRequest_cps_provider_5_cell_data_body{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String, +v_7: String, +v_9: String, +v_11: Nat, +v_13: String, +v_15: String, +v_17: Bool}
  EmitterRequest_cps_provider_5_buf_clear_span{+v_1: String, +v_3: String, +v_5: Nat, +v_7: Nat, +v_9: String}
  EmitterRequest_cps_provider_5_copy_cell_body{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_copy_padding{+v_1: Nat, +v_3: Nat, +v_5: String}
  EmitterRequest_cps_provider_5_array_inner{+v_1: Bool, +v_3: String, +v_5: String, +v_7: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_array_copy_body{+v_1: cps_provider_5_PathState, +v_3: Bool}
  EmitterRequest_cps_provider_5_pow2{+v_1: Nat}
  EmitterRequest_cps_provider_5_move_cell_body{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_move_slot_body{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_data_move_body{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_5: String, +v_7: Nat}
  EmitterRequest_cps_provider_5_state_stat{+v_1: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_state_uniq{+v_1: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_path_body_copy{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_path_body_move{+v_1: cps_provider_5_World, +v_3: cps_provider_5_PathState}
  EmitterRequest_cps_provider_5_path_read{+v_1: String, +v_4: List<&2, cps_provider_5_PathStep>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_runtime_cid_of_ctor{+v_1: cps_provider_5_World, +v_3: U32}
  EmitterRequest_cps_provider_5_canonical_bool{+v_1: cps_provider_5_World, +v_3: String}
  EmitterRequest_cps_provider_5_path_hastag{+v_1: String, +v_4: List<&2, cps_provider_5_PathStep>, +v_6: U32, +v_8: cps_provider_5_World}
  EmitterRequest_cps_provider_5_path_copy{+v_1: String, +v_4: List<&2, cps_provider_5_PathStep>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_path_consume{+v_1: String, +v_4: List<&2, cps_provider_5_PathStep>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_path_is_leaf{+v_1: String, +v_4: List<&2, cps_provider_5_PathStep>, +v_6: cps_provider_5_World}

type EmitterRequestGroup20 is Type:
  EmitterRequest_cps_provider_5_path_is_node{+v_1: String, +v_4: List<&2, cps_provider_5_PathStep>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_project_plan{+v_1: cps_provider_3_UnfillResult, +v_3: cps_provider_5_World, +v_5: cps_provider_3_Node, +v_7: cps_provider_3_Layout, +v_9: Nat, +v_11: String}
  EmitterRequest_cps_provider_5_project_slot{+v_1: cps_provider_3_SlotResult, +v_3: cps_provider_5_World, +v_5: cps_provider_3_Node, +v_7: String, +v_9: U32, +v_11: String}
  EmitterRequest_cps_provider_5_project_layout{+v_1: cps_provider_3_NodeResult, +v_3: cps_provider_5_World, +v_5: String, +v_7: U32, +v_9: String}
  EmitterRequest_cps_provider_5_project_node{+v_1: cps_provider_5_World, +v_3: String, +v_5: U32, +v_7: String}
  EmitterRequest_cps_provider_5_project_marker{+v_1: Bool, +v_3: String, +v_5: String, +v_7: U32, +v_9: cps_provider_5_World}
  EmitterRequest_cps_provider_5_project_native{+v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_8: U32, +v_10: cps_provider_5_World}
  EmitterRequest_cps_provider_5_project_row{+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: U32, +v_7: cps_provider_5_World}
  EmitterRequest_cps_provider_5_project_part{+v_1: String, +v_3: U32, +v_5: U32, +v_7: cps_provider_5_World}
  EmitterRequest_cps_provider_5_hastag_bools{+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: U32, +v_9: String}
  EmitterRequest_cps_provider_5_hastag_cid{+v_2: Maybe<&2, U32>, +v_4: String, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_hastag_row{+v_1: Maybe<&2, BIR.ConstructorLayout>, +v_3: String, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_hastag_part{+v_1: String, +v_3: U32, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_arr_flag{+v_1: Bool}
  EmitterRequest_cps_provider_5_array_label{+v_0: BIR.Primitive}
  EmitterRequest_cps_provider_5_descriptor_missing{+v_0: BIR.Primitive}
  EmitterRequest_cps_provider_5_array_cell_result{+v_1: cps_provider_3_CellResult}
  EmitterRequest_cps_provider_5_array_cell{+v_1: cps_provider_5_World, +v_3: List<&2, BIR.Descriptor>, +v_4: BIR.Primitive}
  EmitterRequest_cps_provider_5_operand_at{+v_2: List<&2, cps_provider_5_Operand>, +v_4: Nat}
  EmitterRequest_cps_provider_5_operand_text{+v_1: cps_provider_5_Operand}
  EmitterRequest_cps_provider_5_operand_use{+v_1: cps_provider_5_Operand}
  EmitterRequest_cps_provider_5_keep_text{+v_1: cps_provider_5_Operand}
  EmitterRequest_cps_provider_5_tuple_cid{+v_2: Maybe<&2, String>, +v_4: String, +v_6: String}
  EmitterRequest_cps_provider_5_tuple_part{+v_1: cps_provider_5_World, +v_3: String, +v_5: String}
  EmitterRequest_cps_provider_5_seal_cell_box{+v_0: BIR.Use, +v_2: String}
  EmitterRequest_cps_provider_5_seal_cell_kind{+v_0: BIR.Use, +v_2: cps_provider_3_CWord, +v_4: String}
  EmitterRequest_cps_provider_5_seal_cell_walk{+v_0: BIR.Use, +v_3: List<&2, cps_provider_3_CWord>, +v_5: String}
  EmitterRequest_cps_provider_5_elem_fill_operand{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_4: BIR.Use, +v_6: cps_provider_5_Code, +v_8: String, +v_10: String}
  EmitterRequest_cps_provider_5_elem_fill{+v_1: cps_provider_5_World, +v_3: cps_provider_3_Layout, +v_4: BIR.Use, +v_6: String, +v_8: String}
  EmitterRequest_cps_provider_5_elem_stores{+v_1: Nat}
  EmitterRequest_cps_provider_5_elem_decl{+v_1: Nat}
  EmitterRequest_cps_provider_5_run_part{+v_2: List<&2, cps_provider_5_Job>, +v_4: cps_provider_5_World, +v_6: String}
  EmitterRequest_cps_provider_5_array_new_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_5: Maybe<&2, cps_provider_5_Operand>, +v_7: cps_provider_5_World, +v_9: cps_provider_3_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat}
  EmitterRequest_cps_provider_5_tuple_and_code{+v_1: cps_provider_5_Part, +v_3: cps_provider_5_Code}
  EmitterRequest_cps_provider_5_array_get_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_5: Maybe<&2, cps_provider_5_Operand>, +v_7: cps_provider_5_World, +v_9: cps_provider_3_Layout, +v_11: Bool, +v_13: Nat}
  EmitterRequest_cps_provider_5_old_read_cell{+v_1: Bool, +v_3: String}
  EmitterRequest_cps_provider_5_kinds_box_jobs{+v_2: List<&2, cps_provider_3_CWord>, +v_4: String, +v_6: Bool}
  EmitterRequest_cps_provider_5_old_sink_jobs{+v_2: List<&2, cps_provider_3_CWord>, +v_4: String}
  EmitterRequest_cps_provider_5_write_jobs{+v_1: Bool, +v_4: List<&2, cps_provider_3_CWord>, +v_6: String}
  EmitterRequest_cps_provider_5_array_set_run{+v_1: cps_provider_5_Operand, +v_3: cps_provider_5_Operand, +v_5: cps_provider_5_Operand, +v_7: cps_provider_5_World, +v_9: cps_provider_3_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat}
  EmitterRequest_cps_provider_5_array_set_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_5: Maybe<&2, cps_provider_5_Operand>, +v_8: Maybe<&2, cps_provider_5_Operand>, +v_10: cps_provider_5_World, +v_12: cps_provider_3_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat}
  EmitterRequest_cps_provider_5_array_swap_run{+v_1: cps_provider_5_Operand, +v_3: cps_provider_5_Operand, +v_5: cps_provider_5_Operand, +v_7: cps_provider_5_World, +v_9: cps_provider_3_Layout, +v_11: Bool, +v_13: Nat, +v_15: Nat}
  EmitterRequest_cps_provider_5_array_swap_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_5: Maybe<&2, cps_provider_5_Operand>, +v_8: Maybe<&2, cps_provider_5_Operand>, +v_10: cps_provider_5_World, +v_12: cps_provider_3_Layout, +v_14: Bool, +v_16: Nat, +v_18: Nat}
  EmitterRequest_cps_provider_5_array_size_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_4: cps_provider_5_World, +v_6: Nat}
  EmitterRequest_cps_provider_5_array_clone_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_4: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_cell_text{+v_1: String, +v_3: String}
  EmitterRequest_cps_provider_5_atomic_call_text{+v_1: String, +v_3: String, +v_5: String, +v_7: String}
  EmitterRequest_cps_provider_5_atomic_cas_text{+v_1: String, +v_3: String, +v_5: String, +v_7: String}
  EmitterRequest_cps_provider_5_atomic_helper{+v_0: BIR.Primitive}
  EmitterRequest_cps_provider_5_atomic_pair{+v_1: String, +v_3: String, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_three_operands{+v_0: BIR.Primitive, +v_2: cps_provider_5_Operand, +v_4: cps_provider_5_Operand, +v_6: cps_provider_5_Operand, +v_8: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_three_pargs{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_5_Operand>, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_cas_pargs{+v_2: List<&2, cps_provider_5_Operand>, +v_4: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_pargs{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_5_Operand>, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_three_regs{+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_cas_regs{+v_2: List<&2, String>, +v_4: cps_provider_5_World}
  EmitterRequest_cps_provider_5_atomic_prim_part{+v_0: BIR.Primitive, +v_3: List<&2, String>, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_leaf_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_4: cps_provider_5_World, +v_6: cps_provider_3_Layout, +v_8: Bool, +v_10: Nat, +v_12: Nat}
  EmitterRequest_cps_provider_5_array_node_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_5: Maybe<&2, cps_provider_5_Operand>}
  EmitterRequest_cps_provider_5_array_is_cond{+v_1: Nat, +v_3: cps_provider_5_Operand}
  EmitterRequest_cps_provider_5_array_is_bools{+v_2: Maybe<&2, String>, +v_5: Maybe<&2, String>, +v_7: Nat, +v_9: cps_provider_5_Operand}
  EmitterRequest_cps_provider_5_array_is_ops{+v_2: Maybe<&2, cps_provider_5_Operand>, +v_4: Nat, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_new_cell{+v_1: cps_provider_5_CellOut, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_get_cell{+v_1: cps_provider_5_CellOut, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}

type EmitterRequestGroup21 is Type:
  EmitterRequest_cps_provider_5_array_set_cell{+v_1: cps_provider_5_CellOut, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_swap_cell{+v_1: cps_provider_5_CellOut, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_size_cell{+v_1: cps_provider_5_CellOut, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_clone_cell{+v_1: cps_provider_5_CellOut, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_leaf_cell{+v_1: cps_provider_5_CellOut, +v_4: List<&2, cps_provider_5_Operand>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_part{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_5_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_5_World}
  EmitterRequest_cps_provider_5_array_cell_part{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_5_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_5_World}
  EmitterRequest_cps_provider_5_is_atomic_primitive{+v_0: BIR.Primitive}
  EmitterRequest_cps_provider_5_is_array_primitive{+v_0: BIR.Primitive}
  EmitterRequest_cps_provider_5_map_offsets{+v_1: Nat, +v_3: String, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_map_offsets_walk{+v_1: String, +v_4: List<&2, cps_provider_3_NodeSlot>, +v_7: List<&2, String>}
  EmitterRequest_cps_provider_5_map_find_missing{+v_1: String}
  EmitterRequest_cps_provider_5_map_find_text{+v_1: String, +v_3: String, +v_5: cps_provider_5_World}
  EmitterRequest_cps_provider_5_map_find_build{+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: U32, +v_11: U32, +v_13: cps_provider_5_World}
  EmitterRequest_cps_provider_5_map_find_expr{+v_1: String, +v_3: String, +v_5: U32, +v_7: U32, +v_9: String, +v_11: String, +v_13: String, +v_15: String}
  EmitterRequest_cps_provider_5_map_find_operands{+v_2: List<&2, cps_provider_5_Operand>, +v_4: cps_provider_5_World}
  EmitterRequest_cps_provider_5_map_find_names{+v_2: List<&2, String>, +v_4: cps_provider_5_World}
  EmitterRequest_cps_provider_5_map_find_part{+v_2: List<&2, cps_provider_5_Operand>, +v_4: List<&2, BIR.Descriptor>, +v_6: cps_provider_5_World}
  EmitterRequest_cps_provider_5_descriptor_part{+v_0: BIR.Primitive, +v_3: List<&2, cps_provider_5_Operand>, +v_5: List<&2, BIR.Descriptor>, +v_7: cps_provider_5_World}
  EmitterRequest_cps_provider_5_show_state0{}
  EmitterRequest_cps_provider_5_show_words{+v_1: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_patches{+v_1: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_memo{+v_1: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_names{+v_1: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_error{+v_1: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_state_set_memo{+v_1: cps_provider_5_ShowState, +v_4: Map<&2, Nat>}
  EmitterRequest_cps_provider_5_show_state_error{+v_1: cps_provider_5_ShowState, +v_3: String}
  EmitterRequest_cps_provider_5_show_next_state{+v_1: cps_provider_5_ShowAdvance}
  EmitterRequest_cps_provider_5_show_next_kids{+v_1: cps_provider_5_ShowAdvance}
  EmitterRequest_cps_provider_5_show_append_word{+v_1: cps_provider_5_ShowState, +v_3: cps_provider_5_ShowWord}
  EmitterRequest_cps_provider_5_show_append_num{+v_1: cps_provider_5_ShowState, +v_3: Nat}
  EmitterRequest_cps_provider_5_show_append_cid{+v_1: cps_provider_5_ShowState, +v_3: Nat}
  EmitterRequest_cps_provider_5_show_append_name{+v_1: cps_provider_5_ShowState, +v_3: String}
  EmitterRequest_cps_provider_5_show_append_patch{+v_1: cps_provider_5_ShowState, +v_3: Nat, +v_5: Nat}
  EmitterRequest_cps_provider_5_show_apply_patch{+v_1: cps_provider_5_ShowState, +v_4: Maybe<&2, Nat>, +v_6: Nat}
  EmitterRequest_cps_provider_5_show_native_kind{+v_1: String}
  EmitterRequest_cps_provider_5_show_kind_family{+v_1: String, +v_3: cps_provider_3_Context}
  EmitterRequest_cps_provider_5_show_kind_head{+v_1: cps_provider_3_HeadResult, +v_3: cps_provider_3_Context}
  EmitterRequest_cps_provider_5_show_kind{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_5_show_box_flag{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_show_tag_plain{+v_1: Nat}
  EmitterRequest_cps_provider_5_show_tag_start{+v_1: Nat, +v_3: Nat}
  EmitterRequest_cps_provider_5_show_quote{+v_1: String}
  EmitterRequest_cps_provider_5_show_name_sep{+v_2: List<&2, String>}
  EmitterRequest_cps_provider_5_show_render_names{+v_2: List<&2, String>}
  EmitterRequest_cps_provider_5_show_render_sep_flag{+v_1: Bool}
  EmitterRequest_cps_provider_5_show_render_sep{+v_1: String}
  EmitterRequest_cps_provider_5_show_render_word{+v_1: cps_provider_5_ShowWord}
  EmitterRequest_cps_provider_5_show_render_words{+v_2: List<&2, cps_provider_5_ShowWord>, +v_4: String}
  EmitterRequest_cps_provider_5_family_arms{+v_1: String, +v_3: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_5_ctor_find_key{+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_5_show_cid_found{+v_1: Maybe<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_5_show_cid_of_key{+v_1: String, +v_3: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_5_show_arm_bracket_name{+v_1: String}
  EmitterRequest_cps_provider_5_show_arm_bracket{+v_1: String}
  EmitterRequest_cps_provider_5_show_erased_present{+v_1: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_5_show_field_at_each{+v_1: List<&2, BIR.DescriptorField>, +v_3: Nat, +v_5: Nat}
  EmitterRequest_cps_provider_5_show_field_at{+v_1: List<&2, BIR.DescriptorField>, +v_3: U32}
  EmitterRequest_cps_provider_5_show_arm_layouts_each{+v_2: List<&2, cps_provider_3_LayArm>, +v_4: String}
  EmitterRequest_cps_provider_5_show_arm_layouts{+v_1: cps_provider_3_Layout, +v_3: String}
  EmitterRequest_cps_provider_5_show_node_layout_slots{+v_1: cps_provider_3_NodeResult}
  EmitterRequest_cps_provider_5_show_word_key{+v_1: cps_provider_3_CWord}
  EmitterRequest_cps_provider_5_show_box_key{+v_1: cps_provider_3_BoxReason}
  EmitterRequest_cps_provider_5_lk_text{+v_1: String}

type EmitterRequestGroup22 is Type:
  EmitterRequest_cps_provider_5_lk_words{+v_2: List<&2, cps_provider_3_CWord>}
  EmitterRequest_cps_provider_5_lk_fields{+v_2: List<&2, cps_provider_3_Layout>}
  EmitterRequest_cps_provider_5_lk_arms{+v_2: List<&2, cps_provider_3_LayArm>}
  EmitterRequest_cps_provider_5_show_layout_key{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_show_arg_tokens{+v_1: List<&2, BIR.Descriptor>, +v_3: Bool}
  EmitterRequest_cps_provider_5_show_quantity_key{+v_0: BIR.Quantity}
  EmitterRequest_cps_provider_5_show_maybe_quantity_key{+v_1: Maybe<&2, BIR.Quantity>}
  EmitterRequest_cps_provider_5_show_pat_tokens{+v_1: List<&2, BIR.DescriptorPattern>, +v_3: Bool}
  EmitterRequest_cps_provider_5_show_pat_expand{+v_0: BIR.DescriptorPattern}
  EmitterRequest_cps_provider_5_show_desc_expand{+v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_5_show_render_tokens{+v_2: List<&2, cps_provider_5_ShowToken>, +v_4: String}
  EmitterRequest_cps_provider_5_show_descriptor_key{+v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_5_show_array_cell{+v_1: cps_provider_3_CellResult, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: Nat, +v_12: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_array_element{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_array_args{+v_1: cps_provider_3_ArgsResult, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: Nat, +v_12: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_array{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: Nat, +v_10: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_box_advance{+v_1: cps_provider_5_ShowJob, +v_3: cps_provider_5_ShowAdvance}
  EmitterRequest_cps_provider_5_fields_box_each{+v_2: List<&2, cps_provider_3_NodeSlot>, +v_4: List<&2, BIR.DescriptorField>, +v_6: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_fields_box_slots{+v_3: Maybe<&2, List<&2, cps_provider_3_NodeSlot>>, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_fields_box{+v_1: cps_provider_3_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_fields_inline_each{+v_2: List<&2, cps_provider_3_Layout>, +v_4: List<&2, BIR.DescriptorField>, +v_6: Nat, +v_8: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_fields_inline_layouts{+v_3: Maybe<&2, List<&2, cps_provider_3_Layout>>, +v_5: List<&2, BIR.DescriptorField>, +v_7: Nat, +v_9: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_fields_inline{+v_1: cps_provider_3_Context, +v_3: String, +v_5: List<&2, BIR.DescriptorField>, +v_7: cps_provider_3_Layout, +v_9: Nat, +v_11: Nat, +v_13: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_fields_advance{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_7: String, +v_9: List<&2, BIR.DescriptorField>, +v_11: cps_provider_3_Layout, +v_13: Nat, +v_15: Nat, +v_17: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_arm_header{+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_3_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_12: BIR.Descriptor, +v_14: cps_provider_3_Layout, +v_16: Nat, +v_18: Nat, +v_20: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_arm_rest{+v_1: cps_provider_5_ShowAdvance, +v_3: List<&2, BIR.DescriptorArm>, +v_5: cps_provider_3_Context, +v_7: List<&2, BIR.ConstructorLayout>, +v_9: List<&2, BIR.Family>, +v_10: BIR.Descriptor, +v_12: cps_provider_3_Layout, +v_14: Nat, +v_16: Nat}
  EmitterRequest_cps_provider_5_show_data_arm_cid{+v_2: Maybe<&2, Nat>, +v_4: List<&2, BIR.DescriptorField>, +v_6: String, +v_8: List<&2, BIR.DescriptorArm>, +v_10: cps_provider_3_Context, +v_12: List<&2, BIR.ConstructorLayout>, +v_14: List<&2, BIR.Family>, +v_15: BIR.Descriptor, +v_17: cps_provider_3_Layout, +v_19: Nat, +v_21: Nat, +v_23: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_arm_erased{+v_1: Bool, +v_3: List<&2, BIR.DescriptorField>, +v_5: String, +v_7: List<&2, BIR.DescriptorArm>, +v_9: cps_provider_3_Context, +v_11: List<&2, BIR.ConstructorLayout>, +v_13: List<&2, BIR.Family>, +v_14: BIR.Descriptor, +v_16: cps_provider_3_Layout, +v_18: Nat, +v_20: Nat, +v_22: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_arm_live{+v_1: List<&2, BIR.DescriptorField>, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_3_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_12: BIR.Descriptor, +v_14: cps_provider_3_Layout, +v_16: Nat, +v_18: Nat, +v_20: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_arm{+v_1: cps_provider_3_FieldsResult, +v_3: String, +v_5: List<&2, BIR.DescriptorArm>, +v_7: cps_provider_3_Context, +v_9: List<&2, BIR.ConstructorLayout>, +v_11: List<&2, BIR.Family>, +v_12: BIR.Descriptor, +v_14: cps_provider_3_Layout, +v_16: Nat, +v_18: Nat, +v_20: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_arms{+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_3_Layout, +v_12: Nat, +v_14: Nat, +v_16: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_count{+v_1: List<&2, BIR.DescriptorArm>, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_3_Layout, +v_12: Nat, +v_14: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_arms_maybe{+v_2: Maybe<&2, List<&2, BIR.DescriptorArm>>, +v_4: cps_provider_3_Context, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>, +v_9: BIR.Descriptor, +v_11: cps_provider_3_Layout, +v_13: Nat, +v_15: cps_provider_5_ShowState, +v_17: String}
  EmitterRequest_cps_provider_5_show_data_key{+v_1: String, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_3_Layout, +v_12: Nat, +v_14: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_data_head{+v_1: cps_provider_3_HeadResult, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_3_Layout, +v_12: Nat, +v_14: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_data{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_3_Layout, +v_10: Nat, +v_12: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_n{+v_1: Nat, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_3_Layout, +v_12: Nat, +v_14: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_kind{+v_1: cps_provider_5_ShowKind, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_3_Layout, +v_12: Nat, +v_14: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_memo{+v_2: Maybe<&2, Nat>, +v_4: String, +v_6: cps_provider_3_Context, +v_8: List<&2, BIR.ConstructorLayout>, +v_10: List<&2, BIR.Family>, +v_11: BIR.Descriptor, +v_13: cps_provider_3_Layout, +v_16: Maybe<&2, Nat>, +v_18: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_norm{+v_1: cps_provider_5_ShowNorm, +v_3: cps_provider_3_Context, +v_5: List<&2, BIR.ConstructorLayout>, +v_7: List<&2, BIR.Family>, +v_8: BIR.Descriptor, +v_10: cps_provider_3_Layout, +v_13: Maybe<&2, Nat>, +v_15: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_key{+v_2: Maybe<&2, String>, +v_4: cps_provider_3_Context, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>, +v_9: BIR.Descriptor, +v_11: cps_provider_3_Layout, +v_14: Maybe<&2, Nat>, +v_16: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_norm_result{+v_1: cps_provider_3_NormResult}
  EmitterRequest_cps_provider_5_show_norm{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_5_show_advance_error{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_3_Layout, +v_11: Maybe<&2, Nat>, +v_14: Maybe<&2, String>, +v_16: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_st{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_6: BIR.Descriptor, +v_8: cps_provider_3_Layout, +v_11: Maybe<&2, Nat>, +v_13: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_advance_job{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_7: cps_provider_5_ShowJob, +v_9: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_run_show{+v_1: cps_provider_3_Context, +v_3: List<&2, BIR.ConstructorLayout>, +v_5: List<&2, BIR.Family>, +v_8: List<&2, cps_provider_5_ShowJob>, +v_10: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_set_word{+v_2: List<&2, cps_provider_5_ShowWord>, +v_4: Nat, +v_6: cps_provider_5_ShowWord, +v_8: Nat}
  EmitterRequest_cps_provider_5_show_apply_patches{+v_2: List<&2, cps_provider_5_ShowWord>, +v_5: List<&2, cps_provider_5_ShowPatch>}
  EmitterRequest_cps_provider_5_show_finish{+v_2: Maybe<&2, String>, +v_4: cps_provider_5_ShowState}
  EmitterRequest_cps_provider_5_show_result{+v_1: cps_provider_5_ShowRun}
  EmitterRequest_cps_provider_5_show_root_layout{+v_1: cps_provider_3_Layout}
  EmitterRequest_cps_provider_5_show_root{+v_1: cps_provider_3_LayoutResult, +v_3: cps_provider_3_Context, +v_4: BIR.Descriptor, +v_6: List<&2, BIR.ConstructorLayout>, +v_8: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_5_show_build{+v_1: cps_provider_3_Context, +v_2: BIR.Descriptor, +v_4: List<&2, BIR.ConstructorLayout>, +v_6: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_6_no_span{}
  EmitterRequest_cps_provider_6_foreign_c_source{v_2: List<&2, String>}
  EmitterRequest_cps_provider_6_plan_prepend{v_1: cps_provider_6_PlanResult, v_3: cps_provider_6_CImportPlan}
  EmitterRequest_cps_provider_6_plan_add{+v_1: String, +v_3: String, v_4: Ast.SourceSpan, v_7: List<&2, cps_provider_6_CImportPlan>}
  EmitterRequest_cps_provider_6_plan_declaration{v_0: BIR.Declaration, +v_3: List<&2, cps_provider_6_CImportPlan>}
  EmitterRequest_cps_provider_6_plan_declarations{v_1: List<&2, BIR.Declaration>, +v_4: List<&2, cps_provider_6_CImportPlan>}
  EmitterRequest_cps_provider_6_find_source{+v_1: String, v_3: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_6_join_imports{v_2: List<&2, cps_provider_6_CImportPlan>, +v_4: List<&2, BIR.SourceFile>, v_7: List<&2, cps_provider_2_CImport>}
  EmitterRequest_cps_provider_6_render{v_0: BIR.Program, v_2: String, v_4: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_6_emit{v_0: Checked.CheckedProgram, v_2: String, v_4: List<&2, BIR.SourceFile>}

type EmitterRequestGroup23 is Type:
  EmitterRequest_cps_provider_6_emit_library{v_0: Checked.CheckedProgram, v_3: List<&2, String>, v_5: String, v_7: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_7_family_index{v_1: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_7_function_index{v_1: List<&2, BIR.TypeFunction>}
  EmitterRequest_cps_provider_7_nf_context{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>}
  EmitterRequest_cps_provider_7_default_fuel{}
  EmitterRequest_cps_provider_7_family_of{+v_1: String, +v_3: Map<&2, BIR.Family>}
  EmitterRequest_cps_provider_7_function_of{+v_1: String, +v_3: Map<&2, BIR.TypeFunction>}
  EmitterRequest_cps_provider_7_native_of{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}
  EmitterRequest_cps_provider_7_val_nth{+v_2: List<&2, cps_provider_7_NfVal>, v_4: Nat}
  EmitterRequest_cps_provider_7_val_at{+v_2: List<&2, cps_provider_7_NfVal>, +v_4: Nat, v_5: BIR.Descriptor}
  EmitterRequest_cps_provider_7_val_at_choose{v_1: Bool, +v_4: List<&2, cps_provider_7_NfVal>, +v_6: Nat, v_7: BIR.Descriptor}
  EmitterRequest_cps_provider_7_first_vals{v_2: List<&2, cps_provider_7_NfVal>, +v_4: Nat}
  EmitterRequest_cps_provider_7_drop_vals{v_2: List<&2, cps_provider_7_NfVal>, +v_4: Nat}
  EmitterRequest_cps_provider_7_insert_before{v_2: List<&2, cps_provider_7_NfVal>, +v_4: Nat, v_6: cps_provider_7_NfVal}
  EmitterRequest_cps_provider_7_append_vals{v_2: List<&2, cps_provider_7_NfVal>, v_5: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_7_quantity_markers{v_1: Nat}
  EmitterRequest_cps_provider_7_renamed_level{v_2: List<&2, cps_provider_7_NfRenaming>, +v_4: Nat}
  EmitterRequest_cps_provider_7_materialize_all_scoped{v_2: List<&2, cps_provider_7_NfVal>, +v_4: Nat, +v_7: List<&2, cps_provider_7_NfRenaming>}
  EmitterRequest_cps_provider_7_materialize_all_at{v_2: List<&2, cps_provider_7_NfVal>, +v_4: Nat}
  EmitterRequest_cps_provider_7_materialize_all{v_2: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_7_materialize_scoped{v_1: cps_provider_7_NfVal, +v_3: Nat, +v_6: List<&2, cps_provider_7_NfRenaming>}
  EmitterRequest_cps_provider_7_materialize_at{v_1: cps_provider_7_NfVal, +v_3: Nat}
  EmitterRequest_cps_provider_7_materialize{v_1: cps_provider_7_NfVal}
  EmitterRequest_cps_provider_7_reify_env{v_0: BIR.Descriptor, +v_3: List<&2, cps_provider_7_NfVal>, +v_5: Nat}
  EmitterRequest_cps_provider_7_status_combine{v_1: cps_provider_7_NfStatus, v_3: cps_provider_7_NfStatus}
  EmitterRequest_cps_provider_7_bind_status{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_7_bind_values{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_7_bind_patterns{v_1: List<&2, BIR.DescriptorPattern>, v_4: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_7_nf{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat, +v_9: Nat}
  EmitterRequest_cps_provider_7_nf_descriptor{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat, +v_9: Nat}
  EmitterRequest_cps_provider_7_nf_arrow{+v_1: cps_provider_7_NfContext, v_2: BIR.Quantity, v_3: BIR.Descriptor, v_4: BIR.Descriptor, +v_7: List<&2, cps_provider_7_NfVal>, +v_9: Nat, +v_11: Nat}
  EmitterRequest_cps_provider_7_nf_descriptor_step{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat, +v_9: Nat}
  EmitterRequest_cps_provider_7_nf_all{+v_1: cps_provider_7_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_7_NfVal>, +v_8: Nat, +v_10: Nat}
  EmitterRequest_cps_provider_7_nf_apply_args{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, +v_7: List<&2, cps_provider_7_NfVal>, v_8: BIR.Descriptor, +v_10: Nat, +v_12: Nat}
  EmitterRequest_cps_provider_7_nf_apply_source{+v_1: cps_provider_7_NfContext, v_3: cps_provider_7_NfVal, v_6: List<&2, cps_provider_7_NfVal>, v_7: BIR.Descriptor, +v_9: Nat, +v_11: Nat}
  EmitterRequest_cps_provider_7_nf_apply{+v_1: cps_provider_7_NfContext, v_3: cps_provider_7_NfVal, v_6: List<&2, cps_provider_7_NfVal>, +v_8: Nat, +v_10: Nat}
  EmitterRequest_cps_provider_7_nf_apply_one{+v_1: cps_provider_7_NfContext, v_3: cps_provider_7_NfVal, v_5: cps_provider_7_NfVal, +v_7: Nat, +v_9: Nat}
  EmitterRequest_cps_provider_7_intrinsic_io{+v_0: BIR.TypeFunction}
  EmitterRequest_cps_provider_7_nf_named_io{v_1: Bool, +v_3: cps_provider_7_NfContext, v_4: BIR.TypeFunction, v_7: List<&2, cps_provider_7_NfVal>, +v_9: Nat, +v_11: Nat}
  EmitterRequest_cps_provider_7_nf_named{+v_1: cps_provider_7_NfContext, +v_3: String, v_6: List<&2, cps_provider_7_NfVal>, +v_8: Nat, +v_10: Nat}
  EmitterRequest_cps_provider_7_nf_arity{+v_2: List<&2, cps_provider_7_NfVal>, +v_4: Nat, +v_6: Nat}
  EmitterRequest_cps_provider_7_nf_family{v_0: BIR.Family, v_3: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_7_nf_family_apply{v_1: cps_provider_7_NfArity, v_3: String, v_5: Nat, v_8: List<&2, cps_provider_7_NfVal>}
  EmitterRequest_cps_provider_7_nf_reduce{+v_1: cps_provider_7_NfContext, v_2: BIR.TypeFunction, v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat, +v_9: Nat}
  EmitterRequest_cps_provider_7_nf_reduce_apply{v_1: cps_provider_7_NfArity, +v_3: cps_provider_7_NfContext, v_5: String, v_7: Nat, +v_9: Nat, v_10: BIR.Descriptor, +v_13: List<&2, cps_provider_7_NfVal>, +v_15: Nat, +v_17: Nat}
  EmitterRequest_cps_provider_7_nf_reduce_body{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, v_8: List<&2, cps_provider_7_NfVal>, +v_10: Nat, +v_12: Nat}
  EmitterRequest_cps_provider_7_nf_cases{+v_1: cps_provider_7_NfContext, v_3: List<&2, BIR.Descriptor>, +v_6: List<&2, cps_provider_7_NfVal>, +v_9: List<&2, cps_provider_7_NfVal>, v_10: BIR.Descriptor, +v_12: Nat, +v_14: Nat}
  EmitterRequest_cps_provider_7_normalize{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor, +v_5: List<&2, cps_provider_7_NfVal>, +v_7: Nat}
  EmitterRequest_cps_provider_7_normalize_closed{v_1: List<&2, BIR.Family>, v_3: List<&2, BIR.TypeFunction>, v_4: BIR.Descriptor}
  EmitterRequest_cps_provider_7_normalize_in{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_7_outer_application{+v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_7_outer_walk{+v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_7_answer_in{+v_1: cps_provider_7_NfContext, v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_7_answer_descriptor{v_0: BIR.Descriptor, v_2: List<&2, BIR.Family>, v_4: List<&2, BIR.TypeFunction>}
  EmitterRequest_cps_provider_7_answer_normalized{+v_1: cps_provider_7_NfContext, +v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_7_is_io_head_in{+v_1: cps_provider_7_NfContext, +v_3: String}
  EmitterRequest_cps_provider_7_is_io_head{+v_1: String, +v_3: Map<&2, BIR.Family>, +v_5: Map<&2, BIR.TypeFunction>}
  EmitterRequest_cps_provider_8_js_source{v_2: List<&2, String>}
  EmitterRequest_cps_provider_8_js_source_ext{v_1: Bool, +v_3: String, v_6: List<&2, String>}
  EmitterRequest_cps_provider_8_link_add{v_1: String, v_3: String, v_4: Ast.SourceSpan, v_7: List<&2, cps_provider_8_LinkSource>}
  EmitterRequest_cps_provider_8_link_add_known{v_1: Bool, v_3: Bool, +v_5: String, +v_7: String, +v_8: Ast.SourceSpan, v_10: String, v_13: List<&2, cps_provider_8_LinkSource>, v_15: cps_provider_8_LinkSource, v_18: List<&2, cps_provider_8_LinkSource>}
  EmitterRequest_cps_provider_8_link_add_namespace{v_1: Bool, +v_3: String, +v_4: Ast.SourceSpan, v_7: List<&2, cps_provider_8_LinkSource>}
  EmitterRequest_cps_provider_8_link_add_tail{v_1: cps_provider_8_LinkResult, v_3: cps_provider_8_LinkSource}
  EmitterRequest_cps_provider_8_link_declarations{v_1: List<&2, BIR.Declaration>, v_4: List<&2, cps_provider_8_LinkSource>}

type EmitterRequestGroup24 is Type:
  EmitterRequest_cps_provider_8_link_declaration_source{v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_7: Ast.SourceSpan, v_10: List<&2, cps_provider_8_LinkSource>, v_12: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_8_link_declaration_plan{v_1: cps_provider_8_LinkResult, v_3: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_8_constructors_named{v_1: List<&2, BIR.ConstructorLayout>, v_3: String}
  EmitterRequest_cps_provider_8_constructors_named_same{v_1: Bool, v_3: List<&2, BIR.ConstructorLayout>, +v_5: String}
  EmitterRequest_cps_provider_8_foreign_name_check{v_1: List<&2, BIR.Declaration>, v_3: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_8_foreign_name_check_named{v_1: Bool, +v_3: String, +v_4: Ast.SourceSpan, v_6: List<&2, BIR.Declaration>, v_8: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_8_link_checked{v_2: Maybe<&2, cps_provider_8_LinkResult>, v_4: List<&2, BIR.Declaration>}
  EmitterRequest_cps_provider_8_link{v_0: BIR.Program}
  EmitterRequest_cps_provider_8_js_key_candidate{+v_1: String, +v_3: String}
  EmitterRequest_cps_provider_8_js_key_join{v_1: Bool, +v_3: String, +v_5: String}
  EmitterRequest_cps_provider_8_js_key_member{+v_2: Map<&2, Bool>, v_4: String}
  EmitterRequest_cps_provider_8_js_key_member_found{v_2: Maybe<&2, Bool>}
  EmitterRequest_cps_provider_8_js_key_resolve{+v_2: Map<&2, Bool>, +v_4: String, +v_6: String}
  EmitterRequest_cps_provider_8_js_key_resolve_qualified{v_1: Bool, +v_4: Map<&2, Bool>, +v_6: String, +v_8: String}
  EmitterRequest_cps_provider_8_js_key_resolve_bare{v_1: Bool, +v_3: String}
  EmitterRequest_cps_provider_8_js_key_declaration{v_0: BIR.Declaration, v_3: Map<&2, Bool>}
  EmitterRequest_cps_provider_8_js_key_declarations{v_1: List<&2, BIR.Declaration>, v_4: Map<&2, Bool>}
  EmitterRequest_cps_provider_8_js_key_layouts{v_1: List<&2, BIR.ConstructorLayout>, v_4: Map<&2, Bool>}
  EmitterRequest_cps_provider_8_js_key_families{v_1: List<&2, BIR.Family>, v_4: Map<&2, Bool>}
  EmitterRequest_cps_provider_8_js_key_functions{v_1: List<&2, BIR.TypeFunction>, v_4: Map<&2, Bool>}
  EmitterRequest_cps_provider_8_js_native_families{v_1: List<&2, BIR.Family>, v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_native_family{v_2: Maybe<&2, String>, v_4: String, v_6: List<&2, BIR.Family>, v_9: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_native_functions{v_1: List<&2, BIR.TypeFunction>, v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_native_function{v_2: Maybe<&2, String>, v_4: String, v_6: List<&2, BIR.TypeFunction>, v_9: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_native_markers{v_0: BIR.Program}
  EmitterRequest_cps_provider_8_js_known_keys{v_0: BIR.Program}
  EmitterRequest_cps_provider_8_js_cid{v_1: cps_provider_8_JSScan}
  EmitterRequest_cps_provider_8_js_word{+v_1: Char}
  EmitterRequest_cps_provider_8_js_key_char{+v_1: Char}
  EmitterRequest_cps_provider_8_js_text_closes{v_2: List<&2, Char>, +v_4: Char, +v_6: Bool}
  EmitterRequest_cps_provider_8_js_text_closes_escape{v_2: List<&2, Char>, v_4: Char, v_6: Bool}
  EmitterRequest_cps_provider_8_js_text_closes_step{v_1: Bool, v_3: Char, v_6: List<&2, Char>, v_8: Char, +v_10: Bool}
  EmitterRequest_cps_provider_8_js_text_closes_newline{v_1: Bool, v_4: List<&2, Char>, v_6: Char, v_8: Bool}
  EmitterRequest_cps_provider_8_js_block_closes{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_block_closes_star{+v_2: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_emit_chars{v_2: List<&2, Char>, +v_5: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_scan{v_2: List<&2, Char>, v_4: cps_provider_8_JSMode, v_6: Bool, +v_9: List<&2, Char>, +v_12: Map<&2, Bool>, +v_14: String}
  EmitterRequest_cps_provider_8_js_scan_mode{v_1: cps_provider_8_JSMode, +v_3: Char, +v_6: List<&2, Char>, v_8: Bool, +v_11: List<&2, Char>, +v_14: Map<&2, Bool>, +v_16: String}
  EmitterRequest_cps_provider_8_js_scan_code{+v_1: Char, +v_4: List<&2, Char>, +v_6: Bool, +v_9: List<&2, Char>, +v_12: Map<&2, Bool>, +v_14: String}
  EmitterRequest_cps_provider_8_js_scan_slash{+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String}
  EmitterRequest_cps_provider_8_js_scan_cid{v_1: Bool, +v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String}
  EmitterRequest_cps_provider_8_js_scan_cid_prefix{+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String}
  EmitterRequest_cps_provider_8_js_scan_cid_key{v_1: cps_provider_8_JSKeyScan, v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String}
  EmitterRequest_cps_provider_8_js_scan_cid_found{v_1: String, v_4: List<&2, Char>, v_7: List<&2, Char>, v_10: Map<&2, Bool>, v_12: String}
  EmitterRequest_cps_provider_8_js_scan_cid_resolved{v_2: Maybe<&2, String>, +v_4: String, v_7: List<&2, Char>, v_10: List<&2, Char>, v_13: Map<&2, Bool>, v_15: String}
  EmitterRequest_cps_provider_8_js_collect_key{v_2: List<&2, Char>, +v_5: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_collect_key_close{+v_2: List<&2, Char>, v_5: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_collect_key_more{v_1: Bool, v_3: Char, v_6: List<&2, Char>, v_9: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_scan_line{+v_1: Char, +v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String}
  EmitterRequest_cps_provider_8_js_scan_line_more{+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String}
  EmitterRequest_cps_provider_8_js_scan_block{+v_1: Char, +v_4: List<&2, Char>, +v_7: List<&2, Char>, +v_10: Map<&2, Bool>, +v_12: String}
  EmitterRequest_cps_provider_8_js_scan_block_more{+v_2: List<&2, Char>, +v_5: List<&2, Char>, +v_8: Map<&2, Bool>, +v_10: String}
  EmitterRequest_cps_provider_8_js_scan_text{+v_1: Char, +v_4: List<&2, Char>, +v_6: cps_provider_8_JSMode, v_8: Char, +v_11: List<&2, Char>, +v_14: Map<&2, Bool>, +v_16: String}
  EmitterRequest_cps_provider_8_js_scan_text_plain{v_1: Bool, +v_3: Char, +v_6: List<&2, Char>, v_8: cps_provider_8_JSMode, +v_11: List<&2, Char>, +v_14: Map<&2, Bool>, +v_16: String}
  EmitterRequest_cps_provider_8_js_scan_text_more{v_2: List<&2, Char>, v_4: cps_provider_8_JSMode, +v_7: List<&2, Char>, v_10: Map<&2, Bool>, v_12: String}
  EmitterRequest_cps_provider_8_js_source_text{v_1: List<&2, BIR.SourceFile>, v_3: String}
  EmitterRequest_cps_provider_8_js_source_text_same{v_1: Bool, v_3: String, v_5: List<&2, BIR.SourceFile>, +v_7: String}
  EmitterRequest_cps_provider_8_js_effect_chunk{v_1: String}
  EmitterRequest_cps_provider_8_js_effect_sources{v_2: List<&2, cps_provider_8_LinkSource>, v_4: List<&2, BIR.SourceFile>, +v_7: Map<&2, Bool>, v_10: List<&2, String>}
  EmitterRequest_cps_provider_8_js_effect_text{v_2: Maybe<&2, String>, +v_4: String, +v_6: String, +v_7: Ast.SourceSpan, v_10: List<&2, cps_provider_8_LinkSource>, v_12: List<&2, BIR.SourceFile>, +v_15: Map<&2, Bool>, v_18: List<&2, String>}
  EmitterRequest_cps_provider_8_js_effect_scan{v_1: cps_provider_8_JSCidResult, +v_3: String, +v_4: Ast.SourceSpan, v_7: List<&2, cps_provider_8_LinkSource>, v_9: List<&2, BIR.SourceFile>, +v_12: Map<&2, Bool>, v_15: List<&2, String>}
  EmitterRequest_cps_provider_8_cat{v_2: List<&2, String>}
  EmitterRequest_cps_provider_8_js_escape_char{v_1: Char}
  EmitterRequest_cps_provider_8_js_escape_other{v_1: U32, v_3: Char}

type EmitterRequestGroup25 is Type:
  EmitterRequest_cps_provider_8_js_escape_packed{v_1: Bool, v_3: U32, v_5: Char}
  EmitterRequest_cps_provider_8_js_char_packed{v_1: U32}
  EmitterRequest_cps_provider_8_js_hex_escape{v_1: U32}
  EmitterRequest_cps_provider_8_js_hex_digit{v_1: U32}
  EmitterRequest_cps_provider_8_js_quote_chars{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_quote_plain{v_1: String}
  EmitterRequest_cps_provider_8_js_quote_plain_next{v_1: Bool, v_3: String}
  EmitterRequest_cps_provider_8_js_quote_plain_char{v_1: Char}
  EmitterRequest_cps_provider_8_js_quote_ready{v_1: Bool, v_3: String}
  EmitterRequest_cps_provider_8_js_quote{+v_1: String}
  EmitterRequest_cps_provider_8_bool_source{v_1: Bool}
  EmitterRequest_cps_provider_8_optional_text{v_2: Maybe<&2, String>}
  EmitterRequest_cps_provider_8_local{v_1: U32}
  EmitterRequest_cps_provider_8_capture{v_1: U32}
  EmitterRequest_cps_provider_8_code_name{v_1: U32}
  EmitterRequest_cps_provider_8_atom{v_0: BIR.Atom}
  EmitterRequest_cps_provider_8_arguments{v_1: List<&2, BIR.Arg>}
  EmitterRequest_cps_provider_8_parameter_names{v_1: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_8_capture_names{v_1: List<&2, BIR.Use>, +v_3: U32}
  EmitterRequest_cps_provider_8_captured_names{v_1: List<&2, BIR.Arg>, +v_3: U32}
  EmitterRequest_cps_provider_8_call{v_1: U32, v_4: List<&2, String>}
  EmitterRequest_cps_provider_8_tail_call{v_1: U32, +v_4: List<&2, String>}
  EmitterRequest_cps_provider_8_tail_call_selected{v_1: U32, v_4: List<&2, String>, v_6: Nat, v_8: Bool}
  EmitterRequest_cps_provider_8_tail_call_named{+v_1: U32, +v_3: String, v_5: Nat}
  EmitterRequest_cps_provider_8_public_closure{v_2: List<&2, String>, v_4: String}
  EmitterRequest_cps_provider_8_closure{v_1: U32, +v_3: List<&2, BIR.Arg>, +v_5: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_8_closure_captures{+v_1: List<&2, BIR.Arg>, v_4: List<&2, String>, v_6: String}
  EmitterRequest_cps_provider_8_js_field_text{v_1: String}
  EmitterRequest_cps_provider_8_js_field_proto{v_1: Bool, +v_3: String}
  EmitterRequest_cps_provider_8_js_plain_key{v_1: String}
  EmitterRequest_cps_provider_8_js_plain_key_first{v_1: Bool, v_4: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_plain_key_chars{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_plain_key_head{v_1: Bool, v_4: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_plain_key_tail{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_plain_key_tail_more{v_1: Bool, v_4: List<&2, Char>}
  EmitterRequest_cps_provider_8_js_plain_head{+v_1: Char}
  EmitterRequest_cps_provider_8_js_member_text{v_0: BIR.Atom, v_2: String}
  EmitterRequest_cps_provider_8_js_member_atom{v_0: BIR.Atom}
  EmitterRequest_cps_provider_8_js_member_selected{v_1: Bool, v_3: Bool, +v_5: String}
  EmitterRequest_cps_provider_8_js_member_plain{v_1: Bool, +v_3: String}
  EmitterRequest_cps_provider_8_record_fields{v_1: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_foreign_parameters{v_1: Nat, v_3: Nat}
  EmitterRequest_cps_provider_8_foreign_arrow{v_2: List<&2, String>, v_4: String}
  EmitterRequest_cps_provider_8_foreign_kont{v_1: Bool, v_3: Bool, v_5: Bool}
  EmitterRequest_cps_provider_8_foreign_kont_scalar{v_1: Bool, v_3: Bool}
  EmitterRequest_cps_provider_8_foreign_kont_nat{v_1: Bool}
  EmitterRequest_cps_provider_8_foreign_answer_kont{v_1: Bool, v_3: Maybe<&2, BIR.Descriptor>, +v_6: Map<&2, String>}
  EmitterRequest_cps_provider_8_foreign_request{+v_1: String, v_3: Nat, v_5: List<&2, BIR.Descriptor>, v_7: Bool, v_8: BIR.Descriptor, +v_11: Map<&2, String>}
  EmitterRequest_cps_provider_8_foreign_arguments{v_2: List<&2, String>, v_4: List<&2, BIR.Descriptor>, +v_7: Map<&2, String>}
  EmitterRequest_cps_provider_8_foreign_argument{v_1: Bool, v_3: String}
  EmitterRequest_cps_provider_8_js_text_descriptor{v_0: BIR.Descriptor, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_text_head{v_2: Maybe<&2, cps_provider_8_JSDescriptorHead>, +v_5: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_f32_descriptor{v_0: BIR.Descriptor, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_f32_head{v_2: Maybe<&2, cps_provider_8_JSDescriptorHead>, +v_5: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_descriptor_head{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_8_js_descriptor_head_fill{v_2: Maybe<&2, cps_provider_8_JSDescriptorHead>, v_4: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_8_js_descriptor_head_applied{v_2: Maybe<&2, cps_provider_8_JSDescriptorHead>, v_3: BIR.Descriptor}
  EmitterRequest_cps_provider_8_js_native_is{+v_2: Map<&2, String>, v_4: String, v_6: String}
  EmitterRequest_cps_provider_8_js_native_is_found{v_2: Maybe<&2, String>, v_4: String}
  EmitterRequest_cps_provider_8_js_io_answer{v_0: BIR.Descriptor, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_io_answer_head{v_2: Maybe<&2, cps_provider_8_JSDescriptorHead>, +v_5: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_io_answer_named{v_1: Bool, v_3: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_8_js_first_descriptor{v_1: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_8_js_nat_descriptor{v_0: BIR.Descriptor, +v_3: Map<&2, String>}

type EmitterRequestGroup26 is Type:
  EmitterRequest_cps_provider_8_js_nat_descriptor_head{v_2: Maybe<&2, cps_provider_8_JSDescriptorHead>, +v_5: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_nat_descriptor_named{v_1: Bool, v_3: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_8_js_bool_of_parameter{v_1: cps_provider_8_JSParameter}
  EmitterRequest_cps_provider_8_js_nat_answer{v_0: BIR.Descriptor, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_nat_answer_io{v_1: Maybe<&2, BIR.Descriptor>, +v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_operation{v_0: BIR.Op}
  EmitterRequest_cps_provider_8_tag_test{+v_1: String, v_3: String}
  EmitterRequest_cps_provider_8_tag_subject_same{v_0: BIR.Atom, v_1: BIR.Atom}
  EmitterRequest_cps_provider_8_tagged_region_checked{v_1: Bool, v_3: cps_provider_8_TaggedRegion}
  EmitterRequest_cps_provider_8_tagged_region{v_0: BIR.Block}
  EmitterRequest_cps_provider_8_tag_unseen{v_2: Maybe<&2, Bool>}
  EmitterRequest_cps_provider_8_tag_group_selected{v_1: Bool, v_2: BIR.Atom, v_4: cps_provider_8_TaggedRegion, v_5: BIR.Block, v_7: cps_provider_8_JsCtx, v_10: List<&2, cps_provider_8_TagArm>, v_13: Map<&2, Bool>, v_15: Nat}
  EmitterRequest_cps_provider_8_tag_group_arm{v_1: Bool, v_2: BIR.Atom, v_3: BIR.Block, v_5: cps_provider_8_JsCtx, v_8: List<&2, cps_provider_8_TagArm>, v_11: Map<&2, Bool>, v_13: Nat}
  EmitterRequest_cps_provider_8_tag_group_view{v_2: Maybe<&2, cps_provider_8_TaggedRegion>, +v_3: BIR.Atom, v_4: BIR.Block, v_6: cps_provider_8_JsCtx, v_9: List<&2, cps_provider_8_TagArm>, +v_12: Map<&2, Bool>, v_14: Nat}
  EmitterRequest_cps_provider_8_tag_group{v_0: BIR.Atom, +v_1: BIR.Block, v_3: cps_provider_8_JsCtx, v_6: List<&2, cps_provider_8_TagArm>, v_9: Map<&2, Bool>, v_11: Nat}
  EmitterRequest_cps_provider_8_tag_arms{v_2: List<&2, cps_provider_8_TagArm>, v_4: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_ordinary_region{v_1: U32, v_2: BIR.Block, v_3: BIR.Block, v_5: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_tag_render_selected{v_1: Bool, v_2: BIR.Atom, v_5: List<&2, cps_provider_8_TagArm>, v_6: BIR.Block, v_8: U32, v_9: BIR.Block, v_10: BIR.Block, v_12: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_tag_render_group{v_1: cps_provider_8_TagGroup, v_2: BIR.Atom, v_4: U32, v_5: BIR.Block, v_6: BIR.Block, v_8: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_region_view{v_2: Maybe<&2, cps_provider_8_TaggedRegion>, v_4: U32, v_5: BIR.Block, v_6: BIR.Block, v_8: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_region{+v_1: U32, +v_2: BIR.Block, +v_3: BIR.Block, v_5: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_block{v_0: BIR.Block, v_2: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_code{v_0: BIR.Code}
  EmitterRequest_cps_provider_8_codes{v_1: List<&2, BIR.Code>}
  EmitterRequest_cps_provider_8_js_ctx{v_1: String, v_3: cps_provider_8_Plan}
  EmitterRequest_cps_provider_8_js_ctx_inside{v_1: cps_provider_8_JsCtx, v_3: U32}
  EmitterRequest_cps_provider_8_js_ctx_owner{v_1: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_js_ctx_has{v_1: cps_provider_8_JsCtx, v_3: U32}
  EmitterRequest_cps_provider_8_js_ctx_cont{v_1: cps_provider_8_JsCtx, v_3: U32}
  EmitterRequest_cps_provider_8_js_ctx_thunk{v_1: cps_provider_8_JsCtx, v_3: U32}
  EmitterRequest_cps_provider_8_js_ctx_frame{v_1: cps_provider_8_JsCtx, v_3: U32}
  EmitterRequest_cps_provider_8_frame_has{v_2: List<&2, U32>, v_4: U32}
  EmitterRequest_cps_provider_8_frame_has_one{v_1: Bool, v_4: List<&2, U32>, v_6: U32}
  EmitterRequest_cps_provider_8_cont_name{v_1: U32}
  EmitterRequest_cps_provider_8_thunk_name{v_1: String, v_3: U32}
  EmitterRequest_cps_provider_8_split_op{v_0: BIR.Op}
  EmitterRequest_cps_provider_8_reads_new{}
  EmitterRequest_cps_provider_8_reads_local{v_1: U32, v_3: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_reads_slot{v_1: U32, v_3: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_atom_reads{v_0: BIR.Atom, v_2: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_arg_reads{v_0: BIR.Arg, v_2: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_args_reads{v_1: List<&2, BIR.Arg>, v_3: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_apply_reads{v_0: BIR.Atom, v_1: BIR.Arg, v_3: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_field_reads{v_0: BIR.Field, v_2: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_fields_reads{v_1: List<&2, BIR.Field>, v_3: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_op_reads{v_0: BIR.Op, v_2: cps_provider_8_Reads}
  EmitterRequest_cps_provider_8_suffix_empty{}
  EmitterRequest_cps_provider_8_suffix_fold{v_2: List<&2, U32>, v_4: cps_provider_8_Held}
  EmitterRequest_cps_provider_8_suffix_fold_one{v_1: U32, v_4: List<&2, U32>, +v_7: List<&2, U32>, v_10: Map<&2, Bool>}
  EmitterRequest_cps_provider_8_suffix_reads{v_2: List<&2, U32>, v_5: List<&2, U32>, v_7: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_suffix_folded{v_1: cps_provider_8_Held, v_3: cps_provider_8_Held, v_6: Map<&2, Bool>}
  EmitterRequest_cps_provider_8_suffix_atom{v_0: BIR.Atom, v_2: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_suffix_args{v_1: List<&2, BIR.Arg>, v_3: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_suffix_apply{v_0: BIR.Atom, v_1: BIR.Arg, v_3: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_suffix_op{v_0: BIR.Op, v_2: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_suffix_prefix{v_2: List<&2, U32>, v_5: Map<&2, Bool>, v_8: List<&2, U32>}
  EmitterRequest_cps_provider_8_suffix_prefix_one{v_1: U32, v_4: Map<&2, Bool>, v_7: List<&2, U32>}
  EmitterRequest_cps_provider_8_suffix_join{v_1: cps_provider_8_Suffix, v_3: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_suffix_joined{v_2: List<&2, U32>, v_5: Map<&2, Bool>, v_8: List<&2, U32>}
  EmitterRequest_cps_provider_8_suffix_bind{v_1: U32, v_3: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_suffix_caps{v_1: cps_provider_8_Suffix, v_4: Maybe<&2, U32>}
  EmitterRequest_cps_provider_8_caps_bound{v_2: List<&2, U32>, v_5: Map<&2, Bool>, v_8: Maybe<&2, U32>, v_11: List<&2, U32>}
  EmitterRequest_cps_provider_8_caps_bound_one{v_1: U32, v_4: Map<&2, Bool>, v_7: Maybe<&2, U32>, v_10: List<&2, U32>}
  EmitterRequest_cps_provider_8_caps_result{v_1: U32, v_4: Maybe<&2, U32>, v_7: List<&2, U32>}

type EmitterRequestGroup27 is Type:
  EmitterRequest_cps_provider_8_caps_result_id{v_1: Bool, v_3: U32, v_6: List<&2, U32>}
  EmitterRequest_cps_provider_8_caps_locals{v_1: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_caps_slots{v_1: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_cap_total{v_1: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_fact_after{v_2: List<&2, cps_provider_8_FrameBits>, v_4: U32}
  EmitterRequest_cps_provider_8_fact_after_here{v_1: Bool, v_3: Bool, v_6: List<&2, cps_provider_8_FrameBits>, v_8: U32}
  EmitterRequest_cps_provider_8_facts_merge{v_2: List<&2, cps_provider_8_FrameBits>, v_5: List<&2, cps_provider_8_FrameBits>}
  EmitterRequest_cps_provider_8_facts_elevate{v_2: List<&2, cps_provider_8_FrameBits>}
  EmitterRequest_cps_provider_8_facts_inject{v_2: List<&2, cps_provider_8_FrameBits>, v_4: Bool}
  EmitterRequest_cps_provider_8_plan_empty{}
  EmitterRequest_cps_provider_8_plan_cont_add{v_1: cps_provider_8_Plan, v_3: U32, v_5: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_plan_thunk_add{v_1: cps_provider_8_Plan, v_3: U32, v_5: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_plan_frame_add{v_1: cps_provider_8_Plan, v_3: U32, v_5: Bool}
  EmitterRequest_cps_provider_8_plan_cont{v_1: cps_provider_8_Plan, v_3: U32}
  EmitterRequest_cps_provider_8_plan_thunk{v_1: cps_provider_8_Plan, v_3: U32}
  EmitterRequest_cps_provider_8_plan_frame{v_1: cps_provider_8_Plan, v_3: U32}
  EmitterRequest_cps_provider_8_plan_caps{v_2: Map<&2, cps_provider_8_Caps>, v_4: String}
  EmitterRequest_cps_provider_8_plan_flag{v_2: Map<&2, Bool>, v_4: String}
  EmitterRequest_cps_provider_8_plan_of{v_0: BIR.Block}
  EmitterRequest_cps_provider_8_plan_block{v_0: BIR.Block, v_2: cps_provider_8_Plan}
  EmitterRequest_cps_provider_8_plan_leaf{v_1: cps_provider_8_Suffix, v_3: cps_provider_8_Plan}
  EmitterRequest_cps_provider_8_plan_let{v_1: U32, v_2: BIR.Op, v_4: cps_provider_8_Step}
  EmitterRequest_cps_provider_8_plan_branch{v_0: BIR.Atom, v_2: cps_provider_8_Step, v_3: BIR.Block}
  EmitterRequest_cps_provider_8_plan_region{v_1: U32, v_3: cps_provider_8_Step, v_4: BIR.Block}
  EmitterRequest_cps_provider_8_plan_region_sites{v_1: cps_provider_8_Plan, v_3: U32, v_5: Bool, v_7: cps_provider_8_Suffix}
  EmitterRequest_cps_provider_8_js_scalar{v_0: BIR.Block}
  EmitterRequest_cps_provider_8_js_scalar_let{v_1: U32, v_3: U32, v_5: String, v_7: List<&2, BIR.Field>, v_8: BIR.Block}
  EmitterRequest_cps_provider_8_js_scalar_repeatable{v_1: Bool, v_3: U32, v_5: U32, v_7: String, v_9: List<&2, BIR.Field>, v_10: BIR.Block}
  EmitterRequest_cps_provider_8_js_scalar_escapes{v_1: Bool, v_3: U32, v_5: U32, v_7: String, v_9: List<&2, BIR.Field>, v_10: BIR.Block}
  EmitterRequest_cps_provider_8_js_scalar_fields{v_1: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_fields_value{v_1: Bool, v_3: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_value{v_0: BIR.Atom}
  EmitterRequest_cps_provider_8_js_scalar_block_ok{v_0: BIR.Block, v_2: U32, v_4: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_op_ok{v_0: BIR.Op, v_2: U32, v_4: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_project_ok{v_0: BIR.Atom, +v_2: String, v_4: U32, v_6: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_project_local{v_1: Bool, +v_3: String, v_5: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_project_field{v_1: Maybe<&2, BIR.Atom>}
  EmitterRequest_cps_provider_8_js_scalar_field_at{v_1: List<&2, BIR.Field>, v_3: String}
  EmitterRequest_cps_provider_8_js_scalar_field_at_same{v_1: Bool, v_2: BIR.Atom, v_4: List<&2, BIR.Field>, +v_6: String}
  EmitterRequest_cps_provider_8_js_scalar_reads{v_1: cps_provider_8_Reads, v_3: U32}
  EmitterRequest_cps_provider_8_js_scalar_mentions{v_2: List<&2, U32>, v_4: U32}
  EmitterRequest_cps_provider_8_js_scalar_mentions_one{v_1: Bool, v_4: List<&2, U32>, v_6: U32}
  EmitterRequest_cps_provider_8_js_scalar_atom_used{v_0: BIR.Atom, v_2: U32}
  EmitterRequest_cps_provider_8_js_scalar_args_used{v_1: List<&2, BIR.Arg>, v_3: U32}
  EmitterRequest_cps_provider_8_js_scalar_block{v_0: BIR.Block, v_2: U32, v_4: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_op{v_0: BIR.Op, v_2: U32, v_4: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_projected{v_0: BIR.Atom, +v_2: String, v_4: U32, v_6: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_projected_local{v_1: Bool, +v_3: String, v_5: List<&2, BIR.Field>}
  EmitterRequest_cps_provider_8_js_scalar_projection{v_1: Maybe<&2, BIR.Atom>, v_2: BIR.Atom, v_4: U32, v_6: U32, +v_8: String}
  EmitterRequest_cps_provider_8_js_scalar_program{v_0: BIR.Program}
  EmitterRequest_cps_provider_8_js_scalar_codes{v_1: List<&2, BIR.Code>, v_3: List<&2, BIR.Code>}
  EmitterRequest_cps_provider_8_let_step{v_1: U32, v_2: BIR.Op, v_3: BIR.Block, v_5: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_split_direct{v_1: U32, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_split_direct_selected{v_1: Bool, v_3: U32, v_5: U32, v_7: List<&2, BIR.Arg>, v_9: cps_provider_8_Caps, v_11: Nat}
  EmitterRequest_cps_provider_8_split_direct_args{v_1: U32, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: cps_provider_8_Caps, v_9: Nat}
  EmitterRequest_cps_provider_8_split_direct_many{v_1: U32, v_3: U32, v_5: List<&2, BIR.Arg>, v_7: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_split_apply{v_1: U32, v_2: BIR.Atom, v_3: BIR.Arg, v_5: cps_provider_8_Caps}
  EmitterRequest_cps_provider_8_arg_atom{v_0: BIR.Arg}
  EmitterRequest_cps_provider_8_arg_temps{v_1: List<&2, BIR.Arg>, v_3: Nat}
  EmitterRequest_cps_provider_8_arg_temps_tail{v_1: List<&2, BIR.Arg>, v_3: Nat}
  EmitterRequest_cps_provider_8_arg_temp_names{v_1: List<&2, BIR.Arg>, v_3: Nat}
  EmitterRequest_cps_provider_8_arg_moves{v_1: Nat, v_3: Nat}
  EmitterRequest_cps_provider_8_arg_moves_at{v_1: Bool, v_3: Nat, v_5: Nat}
  EmitterRequest_cps_provider_8_cap_stores{v_2: List<&2, U32>}

type EmitterRequestGroup28 is Type:
  EmitterRequest_cps_provider_8_slot_stores{v_2: List<&2, U32>}
  EmitterRequest_cps_provider_8_cap_binds{v_2: List<&2, U32>, v_4: Nat}
  EmitterRequest_cps_provider_8_slot_binds{v_2: List<&2, U32>, v_4: Nat}
  EmitterRequest_cps_provider_8_cont_of{v_1: U32, v_2: BIR.Block, v_4: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_thunk_of{v_1: String, v_3: U32, v_4: BIR.Block, v_6: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_region_frame{v_1: U32, v_2: BIR.Block, v_3: BIR.Block, v_5: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_leave_step{v_1: U32, v_3: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_conts{v_0: BIR.Block, v_2: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_conts_let{v_1: U32, v_2: BIR.Op, v_3: BIR.Block, v_5: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_conts_region{v_1: U32, v_2: BIR.Block, v_3: BIR.Block, v_5: cps_provider_8_JsCtx}
  EmitterRequest_cps_provider_8_primitive_name{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_8_primitive_public{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_8_map_find_roles{v_1: List<&2, BIR.ConstructorLayout>, v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_map_find_roles_one{+v_1: String, v_4: Maybe<&2, String>, v_8: List<&2, Maybe<&2, String>>, v_11: Map<&2, String>}
  EmitterRequest_cps_provider_8_map_find_role_used{v_1: String}
  EmitterRequest_cps_provider_8_map_find_keep_role{v_1: Bool, v_3: String, +v_5: String, v_9: List<&2, Maybe<&2, String>>, v_12: Map<&2, String>}
  EmitterRequest_cps_provider_8_map_find_role_fields{+v_1: String, v_5: List<&2, Maybe<&2, String>>, +v_7: Nat, v_10: Map<&2, String>}
  EmitterRequest_cps_provider_8_map_find_field_role{+v_1: String, +v_3: Nat}
  EmitterRequest_cps_provider_8_map_find_runtime{v_1: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_8_map_find_lookup{+v_2: Map<&2, String>}
  EmitterRequest_cps_provider_8_map_find_source{v_1: cps_provider_8_JsMapFind}
  EmitterRequest_cps_provider_8_map_find_missing{}
  EmitterRequest_cps_provider_8_map_find_member{+v_1: String}
  EmitterRequest_cps_provider_8_map_find_text{v_1: String, v_3: String, v_5: String, v_7: String, v_9: String, v_11: String, v_13: String, v_15: String, +v_17: String, v_19: String, v_21: String}
  EmitterRequest_cps_provider_8_primitive_runtime{}
  EmitterRequest_cps_provider_8_quantity{v_0: BIR.Quantity}
  EmitterRequest_cps_provider_8_optional_quantity{v_1: Maybe<&2, BIR.Quantity>}
  EmitterRequest_cps_provider_8_quantities{v_1: List<&2, BIR.Quantity>}
  EmitterRequest_cps_provider_8_descriptor_pattern{v_0: BIR.DescriptorPattern}
  EmitterRequest_cps_provider_8_descriptor_patterns{v_1: List<&2, BIR.DescriptorPattern>}
  EmitterRequest_cps_provider_8_descriptors{v_1: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_8_descriptor{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_8_deferred{v_1: String, v_3: String}
  EmitterRequest_cps_provider_8_declaration{v_0: BIR.Declaration, +v_3: Map<&2, String>, v_5: Nat}
  EmitterRequest_cps_provider_8_foreign_declaration{+v_1: String, v_3: String, v_6: List<&2, String>, v_8: Nat, v_10: List<&2, BIR.Descriptor>, v_11: BIR.Descriptor, +v_14: Map<&2, String>}
  EmitterRequest_cps_provider_8_foreign_source{v_2: Maybe<&2, String>, +v_4: String, +v_6: String, v_8: Nat, v_10: List<&2, BIR.Descriptor>, v_11: BIR.Descriptor, +v_14: Map<&2, String>}
  EmitterRequest_cps_provider_8_native_declaration{+v_1: String, v_2: BIR.Primitive, +v_4: List<&2, BIR.Quantity>}
  EmitterRequest_cps_provider_8_declarations{v_1: List<&2, BIR.Declaration>, +v_4: Map<&2, String>, v_6: Nat}
  EmitterRequest_cps_provider_8_field_names{v_3: List<&2, Maybe<&2, String>>}
  EmitterRequest_cps_provider_8_constructor_layout{v_0: BIR.ConstructorLayout}
  EmitterRequest_cps_provider_8_constructor_layout_source{+v_1: String, v_3: String, v_5: String}
  EmitterRequest_cps_provider_8_constructor_layouts{v_1: List<&2, BIR.ConstructorLayout>}
  EmitterRequest_cps_provider_8_descriptor_field_types{v_1: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_8_descriptor_field_quantities{v_1: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_8_descriptor_field_names{v_1: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_8_descriptor_arm{v_0: BIR.DescriptorArm}
  EmitterRequest_cps_provider_8_descriptor_arms{v_1: List<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_8_parameter_info{v_1: String, v_3: Nat, v_5: Nat}
  EmitterRequest_cps_provider_8_family{v_0: BIR.Family}
  EmitterRequest_cps_provider_8_families{v_1: List<&2, BIR.Family>}
  EmitterRequest_cps_provider_8_type_function{v_0: BIR.TypeFunction}
  EmitterRequest_cps_provider_8_type_functions{v_1: List<&2, BIR.TypeFunction>}
  EmitterRequest_cps_provider_8_js_parameter{v_0: BIR.Descriptor, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_js_parameter_head{v_2: Maybe<&2, cps_provider_8_JSDescriptorHead>, +v_5: Map<&2, String>, v_6: BIR.Descriptor}
  EmitterRequest_cps_provider_8_js_parameter_marker{v_1: Bool, v_4: Maybe<&2, String>, v_6: List<&2, BIR.Descriptor>, v_7: BIR.Descriptor}
  EmitterRequest_cps_provider_8_js_parameter_other{v_2: Maybe<&2, String>, v_3: BIR.Descriptor}
  EmitterRequest_cps_provider_8_js_parameter_known{v_1: String, v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_8_js_parameter_alias{v_1: Bool, v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_8_js_parameter_arity{v_1: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_8_js_parameter_arity_count{v_1: Bool}
  EmitterRequest_cps_provider_8_js_parameter_unresolved{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_8_export_arguments{v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>, v_6: Nat}
  EmitterRequest_cps_provider_8_export_argument{v_1: cps_provider_8_JSParameter, v_3: Bool, v_5: Bool, v_7: Nat}
  EmitterRequest_cps_provider_8_export_argument_scalar{v_1: Bool, v_3: Bool, v_5: Nat}

type EmitterRequestGroup29 is Type:
  EmitterRequest_cps_provider_8_export_argument_float{v_1: Bool, v_3: Nat}
  EmitterRequest_cps_provider_8_export_unresolved{+v_1: String, v_3: List<&2, BIR.Descriptor>, +v_6: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_unresolved_item{v_1: cps_provider_8_JSParameter, +v_3: String, v_5: List<&2, BIR.Descriptor>, +v_8: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_field{v_0: BIR.Export, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_entry_field{+v_1: String, v_3: U32, v_5: Nat, v_7: List<&2, BIR.Descriptor>, v_8: BIR.Descriptor, +v_11: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_direct_field{+v_1: String, v_3: U32, v_5: List<&2, BIR.Descriptor>, v_6: BIR.Descriptor, +v_9: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_result{v_0: BIR.Descriptor, +v_3: Map<&2, String>, v_5: String}
  EmitterRequest_cps_provider_8_export_nat_indices{v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>, v_6: Nat}
  EmitterRequest_cps_provider_8_export_nat_index_texts{v_2: List<&2, Nat>}
  EmitterRequest_cps_provider_8_export_nat_indexes{v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_text_indices{v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>, v_6: Nat}
  EmitterRequest_cps_provider_8_export_text_index{v_1: Bool, v_3: List<&2, BIR.Descriptor>, +v_6: Map<&2, String>, v_8: Nat}
  EmitterRequest_cps_provider_8_export_f32_indices{v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>, v_6: Nat}
  EmitterRequest_cps_provider_8_export_f32_index{v_1: Bool, v_3: List<&2, BIR.Descriptor>, +v_6: Map<&2, String>, v_8: Nat}
  EmitterRequest_cps_provider_8_export_text_indexes{v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_f32_indexes{v_1: List<&2, BIR.Descriptor>, +v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_result_normalizer{v_0: BIR.Descriptor, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_curried{v_1: String, v_3: List<&2, BIR.Descriptor>, v_4: BIR.Descriptor, +v_7: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_curried_value{v_1: String, v_3: List<&2, BIR.Descriptor>, v_4: BIR.Descriptor, +v_7: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_curried_call{v_1: String, v_3: List<&2, BIR.Descriptor>, v_4: BIR.Descriptor, +v_7: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_fields{v_1: List<&2, BIR.Export>, +v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_ending{v_0: BIR.Ending, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_check{v_1: List<&2, BIR.Export>, +v_4: Map<&2, String>}
  EmitterRequest_cps_provider_8_export_check_one{v_1: Bool, +v_3: String, v_5: List<&2, BIR.Export>, +v_8: Map<&2, String>}
  EmitterRequest_cps_provider_8_ending_check{v_0: BIR.Ending, +v_3: Map<&2, String>}
  EmitterRequest_cps_provider_8_emit_linked{v_0: BIR.Program, v_2: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_8_emit_linked_plan{v_1: cps_provider_8_LinkResult, v_2: BIR.Program, v_4: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_8_emit_checked{+v_0: BIR.Program, v_3: List<&2, cps_provider_8_LinkSource>, v_5: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_8_emit_checked_exports{v_2: Maybe<&2, String>, v_3: BIR.Program, v_6: List<&2, cps_provider_8_LinkSource>, v_8: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_8_emit_effects{v_0: BIR.Program, v_2: cps_provider_8_JSEffects}
  EmitterRequest_cps_provider_8_program_source{+v_0: BIR.Program, v_2: String}
  EmitterRequest_cps_provider_8_js_runtime_direct{}
  EmitterRequest_cps_provider_8_js_runtime{}
  EmitterRequest_cps_provider_8_js_runtime_extra{}
  EmitterRequest_cps_provider_8_js_runtime_array{}
  EmitterRequest_cps_provider_8_js_runtime_foreign{}
  EmitterRequest_cps_provider_8_js_runtime_namespace{}
  EmitterRequest_cps_provider_8_js_runtime_cli{}
  EmitterRequest_cps_provider_8_js_runtime_io{}
  EmitterRequest_cps_provider_8_js_runtime_show{}
  EmitterRequest_cps_provider_8_js_runtime_type{}
  EmitterRequest_cps_provider_8_js_runtime_type_names{}
  EmitterRequest_cps_provider_8_js_runtime_type_patterns{}
  EmitterRequest_cps_provider_8_js_runtime_type_eval{}
  EmitterRequest_cps_provider_8_js_runtime_native_type{}
  EmitterRequest_cps_provider_8_js_main{v_1: String}
  EmitterRequest_cps_provider_9_emitted{v_1: cps_provider_8_EmitResult}
  EmitterRequest_cps_provider_9_render{v_0: BIR.Program, v_2: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_9_emit_result{v_1: cps_provider_1_ProgramResult, v_3: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_9_emit{v_0: Checked.CheckedProgram, v_2: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_9_emit_library{v_0: Checked.CheckedProgram, v_3: List<&2, String>, v_5: List<&2, BIR.SourceFile>}
  EmitterRequest_cps_provider_10_qualify{+v_1: String, v_3: String}
  EmitterRequest_cps_provider_10_symbol_key{v_0: IR.Symbol}
  EmitterRequest_cps_provider_10_quantity{v_0: Ast.Quantity}
  EmitterRequest_cps_provider_10_optional_quantity{v_1: Maybe<&2, Ast.Quantity>}
  EmitterRequest_cps_provider_10_parameter{v_1: U32, v_2: BIR.Quantity, v_4: List<&2, BIR.Parameter>}
  EmitterRequest_cps_provider_10_field_key{v_1: String, v_2: BIR.Quantity}
  EmitterRequest_cps_provider_10_canonical{v_1: String, v_2: Scope.ArenaGlobalScope, v_4: Bool}
  EmitterRequest_cps_provider_10_native_match_descriptor_0{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_4: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor{v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_name_0{v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_5: Scope.ArenaGlobalScope, v_7: Bool}
  EmitterRequest_cps_provider_10_descriptor_name{v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope, v_5: Bool}
  EmitterRequest_cps_provider_10_native_match_descriptors_0{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_3: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptors_1{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope}

type EmitterRequestGroup30 is Type:
  EmitterRequest_cps_provider_10_native_match_descriptors_2{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptors_3{v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptors{v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_patterns_0{v_2: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_3: BIR.DescriptorPattern}
  EmitterRequest_cps_provider_10_native_match_descriptor_patterns_1{v_1: cps_provider_10_CatalogResult<BIR.DescriptorPattern>, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_patterns_2{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Pattern>, v_5: U32, v_7: U32, v_8: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_patterns_3{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_patterns_4{v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor_patterns{v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_pattern_0{v_2: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_4: String}
  EmitterRequest_cps_provider_10_native_match_descriptor_pattern_1{v_2: cps_provider_10_CatalogResult<String>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_pattern_2{v_0: Arena.Pattern, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor_pattern{v_0: Arena.Arena, v_1: Arena.Pattern, v_2: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor_apply{v_0: BIR.Descriptor, v_1: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_sugar_0{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_sugar_1{v_2: cps_provider_10_CatalogResult<String>, v_4: List<&2, BIR.Descriptor>, v_6: Bool}
  EmitterRequest_cps_provider_10_native_match_descriptor_sugar_2{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_8: String}
  EmitterRequest_cps_provider_10_native_match_descriptor_sugar_3{v_2: cps_provider_10_CatalogResult<String>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope, v_9: U32, v_11: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_sugar_4{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>, v_5: Bool}
  EmitterRequest_cps_provider_10_native_match_descriptor_sugar_5{v_0: Arena.Node, v_2: List<&2, BIR.Descriptor>, v_4: Bool, v_5: Scope.ArenaGlobalScope, v_6: Arena.Arena}
  EmitterRequest_cps_provider_10_native_match_descriptor_sugar_6{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_5: List<&2, BIR.Descriptor>, v_7: Bool, v_8: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor_sugar{v_0: Arena.Arena, v_2: U32, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_named_sugar{v_1: String, v_2: BIR.Descriptor, v_4: List<&2, BIR.Descriptor>, v_6: Bool}
  EmitterRequest_cps_provider_10_unnamed_sugar{v_0: BIR.Descriptor, v_2: List<&2, BIR.Descriptor>, v_4: Bool}
  EmitterRequest_cps_provider_10_string_names{v_0: Ast.StringLiteralNames, v_1: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_string_bit{v_1: U32, v_2: Ast.StringLiteralNames}
  EmitterRequest_cps_provider_10_string_word{v_1: Nat, v_3: U32, v_4: Ast.StringLiteralNames}
  EmitterRequest_cps_provider_10_string_descriptor{v_2: List<&2, U32>, v_3: Ast.StringLiteralNames}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_0{v_2: cps_provider_10_CatalogResult<String>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_1{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: Nat, v_4: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_2{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: Nat, v_6: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_3{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_4{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_5{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_6{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_7{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_8{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Ast.Quantity, v_3: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_9{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_3: Ast.Quantity, v_5: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_10{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: Maybe<&2, Ast.Quantity>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_11{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_12{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_13{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_4: String}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_14{v_2: cps_provider_10_CatalogResult<String>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_15{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_16{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_17{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_4: String}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_18{v_2: cps_provider_10_CatalogResult<String>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_19{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_20{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_21{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: BIR.Descriptor, v_3: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_22{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32, v_5: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_23{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_4: U32, v_6: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_24{v_4: Sigma<&1, &1, Arena.Arena, _ => String>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_25{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_4: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_26{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_27{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.DescriptorPattern>, v_5: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_28{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: List<&2, BIR.DescriptorPattern>}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_29{v_2: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_3: Scope.ArenaGlobalScope, v_5: U32, v_7: U32, v_9: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_node_30{v_0: Arena.Node, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor_node{v_0: Arena.Arena, v_1: Arena.Node, v_2: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_cases_0{v_2: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>, v_3: BIR.Descriptor}
  EmitterRequest_cps_provider_10_native_match_descriptor_cases_1{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_cases_2{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_5: U32, v_7: U32, v_8: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_cases_3{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope}

type EmitterRequestGroup31 is Type:
  EmitterRequest_cps_provider_10_native_match_descriptor_cases_4{v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor_cases{v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_descriptor_case_0{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.DescriptorPattern>}
  EmitterRequest_cps_provider_10_native_match_descriptor_case_1{v_2: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>, v_3: Scope.ArenaGlobalScope, v_5: U32}
  EmitterRequest_cps_provider_10_native_match_descriptor_case_2{v_0: Arena.Node, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_descriptor_case{v_0: Arena.Arena, v_1: Arena.Node, v_2: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_telescope_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Telescope>, v_4: U32, v_5: Scope.ArenaGlobalScope, v_6: Arena.Binder}
  EmitterRequest_cps_provider_10_native_match_telescope_1{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_5: U32, v_6: Scope.ArenaGlobalScope, v_8: U32, v_10: U32}
  EmitterRequest_cps_provider_10_native_match_telescope_2{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_7: Scope.ArenaGlobalScope, v_9: U32, v_11: U32}
  EmitterRequest_cps_provider_10_native_match_telescope_3{v_0: IR.Words, v_1: Arena.Arena, v_3: U32, v_4: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_telescope{v_0: Arena.Arena, v_1: IR.Words, v_3: U32, v_4: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_telescope_binder_0{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: U32, v_4: Ast.Quantity, v_6: List<&2, BIR.Parameter>, v_8: List<&2, BIR.Quantity>, v_10: List<&2, BIR.DescriptorField>, v_12: Bool, v_14: String}
  EmitterRequest_cps_provider_10_native_match_telescope_binder_1{v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_6: U32, v_7: Scope.ArenaGlobalScope, v_8: Ast.Quantity, v_10: U32, v_12: List<&2, BIR.Parameter>, v_14: List<&2, BIR.Quantity>, v_16: List<&2, BIR.DescriptorField>, v_18: Bool}
  EmitterRequest_cps_provider_10_native_match_telescope_binder_2{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_3: List<&2, BIR.Parameter>, v_5: List<&2, BIR.Quantity>, v_7: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_10_native_match_telescope_binder_3{v_0: Arena.Binder, v_2: cps_provider_10_Telescope, v_3: Arena.Arena, v_5: U32, v_6: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_telescope_binder{v_0: Arena.Arena, v_1: Arena.Binder, v_3: U32, v_4: Scope.ArenaGlobalScope, v_6: cps_provider_10_Telescope}
  EmitterRequest_cps_provider_10_field_names{v_1: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_10_fields_quantities{v_1: List<&2, BIR.DescriptorField>}
  EmitterRequest_cps_provider_10_base_imports{v_1: List<&2, Ast.ModuleImport>}
  EmitterRequest_cps_provider_10_base_imported{v_1: List<&2, IR.LoadedModule>}
  EmitterRequest_cps_provider_10_base_source{v_1: String, v_3: Bool}
  EmitterRequest_cps_provider_10_native_marker{v_1: Bool, v_3: String}
  EmitterRequest_cps_provider_10_short_key{v_1: String}
  EmitterRequest_cps_provider_10_short_chars{v_2: List<&2, Char>, v_5: List<&2, Char>}
  EmitterRequest_cps_provider_10_constructor_native{v_1: Bool, v_3: String, v_5: String}
  EmitterRequest_cps_provider_10_primitive_name{v_1: String}
  EmitterRequest_cps_provider_10_primitive_chars{v_2: List<&2, Char>}
  EmitterRequest_cps_provider_10_primitive{v_1: Bool, v_3: String}
  EmitterRequest_cps_provider_10_primitive_named{v_1: String}
  EmitterRequest_cps_provider_10_definition_key{v_1: cps_provider_10_Registry, v_3: String}
  EmitterRequest_cps_provider_10_constructor_key{v_1: cps_provider_10_Registry, v_3: String}
  EmitterRequest_cps_provider_10_lookup_definition{v_1: cps_provider_10_Registry, v_2: IR.Symbol}
  EmitterRequest_cps_provider_10_lookup_constructor{v_1: cps_provider_10_Registry, v_2: IR.Symbol}
  EmitterRequest_cps_provider_10_get_definitions{v_1: cps_provider_10_Catalog}
  EmitterRequest_cps_provider_10_get_registry{v_1: cps_provider_10_Catalog}
  EmitterRequest_cps_provider_10_get_constructors{v_1: cps_provider_10_Catalog}
  EmitterRequest_cps_provider_10_get_families{v_1: cps_provider_10_Catalog}
  EmitterRequest_cps_provider_10_get_type_functions{v_1: cps_provider_10_Catalog}
  EmitterRequest_cps_provider_10_get_next_code{v_1: cps_provider_10_Catalog}
  EmitterRequest_cps_provider_10_get_ending{v_1: cps_provider_10_Catalog}
  EmitterRequest_cps_provider_10_native_match_insert_definition_0{v_2: Maybe<&2, cps_provider_10_Definition>, +v_4: String, v_6: cps_provider_10_Definition, +v_9: Map<&2, cps_provider_10_Definition>}
  EmitterRequest_cps_provider_10_insert_definition{+v_1: String, v_3: cps_provider_10_Definition, +v_6: Map<&2, cps_provider_10_Definition>}
  EmitterRequest_cps_provider_10_native_match_insert_constructor_0{v_2: Maybe<&2, cps_provider_10_Constructor>, +v_4: String, v_6: cps_provider_10_Constructor, +v_9: Map<&2, cps_provider_10_Constructor>}
  EmitterRequest_cps_provider_10_insert_constructor{+v_1: String, v_3: cps_provider_10_Constructor, +v_6: Map<&2, cps_provider_10_Constructor>}
  EmitterRequest_cps_provider_10_normalize_descriptor_value{v_0: BIR.Descriptor, +v_2: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_normalize_descriptors{v_1: List<&2, BIR.Descriptor>, +v_3: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_normalize_foreign{v_2: Maybe<&2, cps_provider_10_Foreign>, +v_4: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_normalize_foreign_header{v_1: cps_provider_10_DefinitionHeader, +v_3: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_normalize_foreign_definition{v_1: cps_provider_10_Definition, +v_3: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_normalize_foreign_definitions{v_2: List<&2, cps_provider_10_Definition>, +v_4: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_export_entry{v_2: Maybe<&2, cps_provider_10_DefinitionHeader>}
  EmitterRequest_cps_provider_10_export_definition{v_1: String, v_4: List<&2, cps_provider_10_Definition>}
  EmitterRequest_cps_provider_10_export_signature{v_1: String, v_3: List<&2, Scope.ArenaGlobal>}
  EmitterRequest_cps_provider_10_live_arrow_types{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_10_live_arrow_result{v_0: BIR.Descriptor}
  EmitterRequest_cps_provider_10_export_facts_of{v_0: Arena.Arena, v_1: BIR.Descriptor}
  EmitterRequest_cps_provider_10_export_facts{v_0: Arena.Arena, v_2: String, v_5: List<&2, cps_provider_10_Definition>, v_7: List<&2, Scope.ArenaGlobal>}
  EmitterRequest_cps_provider_10_exports{v_2: List<&2, String>, v_4: cps_provider_10_Registry, v_5: Arena.Arena, v_8: List<&2, cps_provider_10_Definition>, v_10: List<&2, Scope.ArenaGlobal>, +v_12: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_native_match_needed_ref_0{v_2: Maybe<&2, Bool>, v_3: Arena.Arena, v_5: String, v_8: Map<&2, cps_provider_10_Definition>, v_10: cps_provider_10_Needed, v_12: List<&2, BIR.TypeFunction>, v_15: Map<&2, Bool>}
  EmitterRequest_cps_provider_10_native_match_needed_ref_1{v_1: cps_provider_10_Needed, v_2: Arena.Arena, v_4: String, v_7: Map<&2, cps_provider_10_Definition>}
  EmitterRequest_cps_provider_10_needed_ref{v_0: Arena.Arena, v_2: String, v_5: Map<&2, cps_provider_10_Definition>, v_7: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_native_match_needed_definition_0{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>, v_4: Map<&2, cps_provider_10_Definition>, v_6: List<&2, BIR.TypeFunction>, v_9: Map<&2, Bool>, v_11: String, v_13: List<&2, BIR.Quantity>, v_15: U32, v_16: Scope.ArenaGlobalScope, v_19: Maybe<&2, String>, v_21: Nat}
  EmitterRequest_cps_provider_10_native_match_needed_definition_1{v_2: Maybe<&2, cps_provider_10_Definition>, v_3: Arena.Arena, v_6: Map<&2, cps_provider_10_Definition>, v_8: List<&2, BIR.TypeFunction>, v_11: Map<&2, Bool>}
  EmitterRequest_cps_provider_10_needed_definition{v_0: Arena.Arena, v_3: Maybe<&2, cps_provider_10_Definition>, v_6: Map<&2, cps_provider_10_Definition>, v_8: List<&2, BIR.TypeFunction>, v_11: Map<&2, Bool>}

type EmitterRequestGroup32 is Type:
  EmitterRequest_cps_provider_10_native_match_needed_terms_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_4: U32, v_6: U32, v_7: Scope.ArenaGlobalScope, v_10: Map<&2, cps_provider_10_Definition>}
  EmitterRequest_cps_provider_10_native_match_needed_terms_1{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_9: Scope.ArenaGlobalScope, v_12: Map<&2, cps_provider_10_Definition>, v_14: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_native_match_needed_terms_2{v_1: U32, v_2: Arena.Arena, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_10_Definition>, v_10: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_needed_terms{v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_10_Definition>, v_10: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_native_match_needed_pair_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_10_Definition>}
  EmitterRequest_cps_provider_10_needed_pair{v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, cps_provider_10_Definition>, v_10: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_native_match_needed_term_0{v_2: cps_provider_10_CatalogResult<String>, v_5: Map<&2, cps_provider_10_Definition>, v_7: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_native_match_needed_term_1{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_10_Definition>, v_8: U32}
  EmitterRequest_cps_provider_10_native_match_needed_term_2{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_10_Definition>, v_8: U32}
  EmitterRequest_cps_provider_10_native_match_needed_term_3{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_10_Definition>, v_8: U32}
  EmitterRequest_cps_provider_10_native_match_needed_term_4{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_10_Definition>, v_8: U32, v_10: U32}
  EmitterRequest_cps_provider_10_native_match_needed_term_5{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_10_Definition>, v_8: U32}
  EmitterRequest_cps_provider_10_native_match_needed_term_6{v_0: Arena.Node, v_1: Scope.ArenaGlobalScope, v_4: Map<&2, cps_provider_10_Definition>, v_6: cps_provider_10_Needed, v_7: Arena.Arena}
  EmitterRequest_cps_provider_10_native_match_needed_term_7{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_4: Scope.ArenaGlobalScope, v_7: Map<&2, cps_provider_10_Definition>, v_9: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_needed_term{v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, cps_provider_10_Definition>, v_8: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_native_match_needed_roots_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_5: Map<&2, cps_provider_10_Definition>, v_8: List<&2, cps_provider_10_Root>}
  EmitterRequest_cps_provider_10_native_match_needed_roots_1{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_5: Map<&2, cps_provider_10_Definition>, v_8: List<&2, cps_provider_10_Root>}
  EmitterRequest_cps_provider_10_native_match_needed_roots_2{v_2: List<&2, cps_provider_10_Root>, v_3: Arena.Arena, v_6: Map<&2, cps_provider_10_Definition>, v_8: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_needed_roots{v_0: Arena.Arena, v_3: List<&2, cps_provider_10_Root>, v_6: Map<&2, cps_provider_10_Definition>, v_8: cps_provider_10_Needed}
  EmitterRequest_cps_provider_10_native_match_binder_roots_0{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_4: Scope.ArenaGlobalScope, v_7: List<&2, cps_provider_10_Root>, v_9: U32, v_11: U32}
  EmitterRequest_cps_provider_10_native_match_binder_roots_1{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_5: Scope.ArenaGlobalScope, v_8: List<&2, cps_provider_10_Root>, v_10: U32, v_12: U32}
  EmitterRequest_cps_provider_10_native_match_binder_roots_2{v_0: IR.Words, v_1: Arena.Arena, v_2: Scope.ArenaGlobalScope, v_5: List<&2, cps_provider_10_Root>}
  EmitterRequest_cps_provider_10_binder_roots{v_0: Arena.Arena, v_1: IR.Words, v_2: Scope.ArenaGlobalScope, v_5: List<&2, cps_provider_10_Root>}
  EmitterRequest_cps_provider_10_binder_type{v_0: Arena.Binder}
  EmitterRequest_cps_provider_10_result_roots{v_0: IR.OptionalTerm, v_1: Scope.ArenaGlobalScope, v_4: List<&2, cps_provider_10_Root>}
  EmitterRequest_cps_provider_10_type_root{v_1: Bool, v_3: String, v_6: List<&2, cps_provider_10_Root>}
  EmitterRequest_cps_provider_10_preparation_failure{v_1: cps_provider_10_Preparation, v_3: String}
  EmitterRequest_cps_provider_10_first_failure{v_2: Maybe<&2, String>, v_4: String}
  EmitterRequest_cps_provider_10_native_match_header_insert_0{v_2: Maybe<&2, cps_provider_10_DefinitionHeader>, +v_4: String, v_6: cps_provider_10_DefinitionHeader, +v_9: Map<&2, cps_provider_10_DefinitionHeader>}
  EmitterRequest_cps_provider_10_header_insert{+v_1: String, v_3: cps_provider_10_DefinitionHeader, +v_6: Map<&2, cps_provider_10_DefinitionHeader>}
  EmitterRequest_cps_provider_10_value_insert{v_2: Maybe<&2, Bool>, v_3: IR.DefBody, v_5: String, v_7: cps_provider_10_Definition, v_10: Map<&2, cps_provider_10_Definition>}
  EmitterRequest_cps_provider_10_native_match_foreign_sources_1{v_4: Sigma<&1, &1, Arena.Arena, _ => String>, v_6: String, v_8: U32, v_10: U32, v_13: List<&2, String>}
  EmitterRequest_cps_provider_10_native_match_foreign_sources_0{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: String, v_8: U32, v_10: U32, v_13: List<&2, String>}
  EmitterRequest_cps_provider_10_foreign_sources{v_0: Arena.Arena, v_1: IR.Names, v_3: String, v_6: List<&2, String>}
  EmitterRequest_cps_provider_10_foreign_namespace{v_1: String, v_3: String}
  EmitterRequest_cps_provider_10_foreign_result_type{v_0: Arena.Arena, v_1: IR.OptionalTerm, v_2: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_live_parameter_types{v_0: Arena.Arena, v_1: IR.Words, v_2: Scope.ArenaGlobalScope, v_4: List<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_live_parameter_types_2{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_5: Scope.ArenaGlobalScope, v_7: List<&2, BIR.Descriptor>, v_9: U32, v_11: U32}
  EmitterRequest_cps_provider_10_native_match_live_parameter_types_1{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_4: Scope.ArenaGlobalScope, v_6: List<&2, BIR.Descriptor>, v_8: U32, v_10: U32}
  EmitterRequest_cps_provider_10_live_parameter_binder{v_0: Arena.Arena, v_1: Arena.Binder, v_2: Scope.ArenaGlobalScope, v_4: List<&2, BIR.Descriptor>, v_6: U32, v_8: U32}
  EmitterRequest_cps_provider_10_live_parameter_quantity{v_0: BIR.Quantity, v_1: Arena.Arena, v_3: U32, v_4: Scope.ArenaGlobalScope, v_6: List<&2, BIR.Descriptor>, v_8: U32, v_10: U32}
  EmitterRequest_cps_provider_10_definition_foreign{v_0: Arena.Arena, v_1: IR.DefBody, v_3: String, v_5: String, v_7: String, v_8: Ast.SourceSpan, v_9: IR.Words, v_10: IR.OptionalTerm, v_11: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_definition_fast{v_1: Bool, v_3: Bool, v_5: List<&2, BIR.Parameter>, v_7: Maybe<&2, BIR.Primitive>, v_10: Maybe<&2, cps_provider_10_Foreign>}
  EmitterRequest_cps_provider_10_definition_primitive{v_1: Bool, v_4: Maybe<&2, cps_provider_10_Foreign>, v_6: Bool, v_8: String}
  EmitterRequest_cps_provider_10_native_match_main_descriptor_0{v_1: cps_provider_10_CatalogResult<BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_main_descriptor_1{v_1: Bool, v_2: IR.OptionalTerm, v_3: Arena.Arena, v_4: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_native_match_main_descriptor_2{v_1: Maybe<&2, BIR.Descriptor>, v_2: Arena.Arena, v_4: String, v_5: IR.OptionalTerm, v_6: Scope.ArenaGlobalScope}
  EmitterRequest_cps_provider_10_main_descriptor{v_0: Arena.Arena, v_2: String, v_3: IR.OptionalTerm, v_4: Scope.ArenaGlobalScope, v_6: Maybe<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_10_signature_symbol{v_0: Scope.ArenaGlobal}
  EmitterRequest_cps_provider_10_prepare_definition{v_0: Arena.Arena, v_1: IR.Definition, v_3: String, v_5: String, v_7: Bool, v_8: Scope.ArenaGlobalScope, v_10: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_0{v_2: cps_provider_10_CatalogResult<Maybe<&2, BIR.Descriptor>>, v_4: String, v_5: IR.DefBody, v_8: List<&2, cps_provider_10_Definition>, v_11: Map<&2, cps_provider_10_Definition>, v_14: Map<&2, cps_provider_10_DefinitionHeader>, v_16: List<&2, BIR.ConstructorLayout>, v_19: Map<&2, cps_provider_10_Constructor>, v_21: List<&2, BIR.Family>, v_23: U32, v_25: U32, v_28: Maybe<&2, String>, v_31: Map<&2, Bool>, v_33: cps_provider_10_DefinitionHeader, v_35: cps_provider_10_Definition, v_38: List<&2, cps_provider_10_Root>}
  EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_1{v_3: cps_provider_10_CatalogResult<List<&2, cps_provider_10_Root>>, v_5: String, v_6: IR.OptionalTerm, v_7: IR.DefBody, v_9: Bool, v_10: Scope.ArenaGlobalScope, v_13: List<&2, cps_provider_10_Definition>, v_16: Map<&2, cps_provider_10_Definition>, v_19: Map<&2, cps_provider_10_DefinitionHeader>, v_21: List<&2, BIR.ConstructorLayout>, v_24: Map<&2, cps_provider_10_Constructor>, v_26: List<&2, BIR.Family>, v_28: U32, v_30: U32, v_32: Maybe<&2, BIR.Descriptor>, v_35: Maybe<&2, String>, v_38: Map<&2, Bool>, v_40: cps_provider_10_DefinitionHeader, v_42: cps_provider_10_Definition}
  EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_2{v_1: cps_provider_10_Preparation, v_3: String, v_4: IR.Words, v_5: IR.OptionalTerm, v_6: IR.DefBody, v_8: Maybe<&2, IR.Occurrence>, v_10: Bool, v_12: Nat, v_14: Bool, v_15: Scope.ArenaGlobalScope, v_16: Scope.ArenaGlobal, v_18: List<&2, BIR.Parameter>, v_20: List<&2, BIR.Quantity>, v_21: Arena.Arena, v_24: Maybe<&2, cps_provider_10_Foreign>, v_26: Maybe<&2, BIR.Primitive>, v_28: Bool}
  EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_3{v_3: cps_provider_10_CatalogResult<Maybe<&2, cps_provider_10_Foreign>>, v_5: String, v_6: IR.Words, v_7: IR.OptionalTerm, v_8: IR.DefBody, v_10: Maybe<&2, IR.Occurrence>, v_12: Bool, v_14: Bool, v_16: Nat, v_18: Bool, v_19: Scope.ArenaGlobalScope, v_21: cps_provider_10_Preparation, v_22: Scope.ArenaGlobal, v_24: List<&2, BIR.Parameter>, v_26: List<&2, BIR.Quantity>}
  EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_4{v_2: cps_provider_10_CatalogResult<cps_provider_10_Telescope>, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: cps_provider_10_Preparation, v_25: Scope.ArenaGlobal, v_26: Ast.SourceSpan}
  EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_5{v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: Arena.Arena, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: cps_provider_10_Preparation, v_25: Ast.SourceSpan}
  EmitterRequest_cps_provider_10_prepare_definition_symbol{v_0: Arena.Arena, v_2: Maybe<&2, Scope.ArenaGlobal>, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: cps_provider_10_Preparation, v_25: Ast.SourceSpan}
  EmitterRequest_cps_provider_10_is_term{v_0: IR.DefBody}
  EmitterRequest_cps_provider_10_native_match_prepare_constructors_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Arms>, v_4: List<&2, BIR.DescriptorField>, v_6: String}
  EmitterRequest_cps_provider_10_native_match_prepare_constructors_1{v_3: cps_provider_10_CatalogResult<List<&2, cps_provider_10_Root>>, v_5: String, v_7: String, v_9: Nat, v_11: Bool, v_12: Scope.ArenaGlobalScope, v_14: List<&2, IR.ConstructorDecl>, v_16: List<&2, BIR.DescriptorField>, v_18: String, v_21: List<&2, cps_provider_10_Definition>, v_24: Map<&2, cps_provider_10_Definition>, v_27: Map<&2, cps_provider_10_DefinitionHeader>, v_29: List<&2, BIR.ConstructorLayout>, v_32: Map<&2, cps_provider_10_Constructor>, v_34: List<&2, BIR.Family>, v_36: U32, v_38: U32, v_40: Maybe<&2, BIR.Descriptor>, v_43: Maybe<&2, String>, v_46: Map<&2, Bool>, v_47: BIR.ConstructorLayout, v_49: cps_provider_10_Constructor}
  EmitterRequest_cps_provider_10_native_match_prepare_constructors_2{v_1: cps_provider_10_Preparation, v_3: String, v_5: String, v_7: Nat, v_9: Bool, v_10: Scope.ArenaGlobalScope, v_11: IR.Words, v_13: List<&2, IR.ConstructorDecl>, v_14: Arena.Arena, v_16: List<&2, BIR.Quantity>, v_18: List<&2, BIR.DescriptorField>, v_20: String}
  EmitterRequest_cps_provider_10_native_match_prepare_constructors_3{v_2: cps_provider_10_CatalogResult<cps_provider_10_Telescope>, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: cps_provider_10_Preparation, v_15: String, v_16: IR.Words, v_18: List<&2, IR.ConstructorDecl>}
  EmitterRequest_cps_provider_10_native_match_prepare_constructors_4{v_1: List<&2, IR.ConstructorDecl>, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_prepare_constructors{v_0: Arena.Arena, v_2: List<&2, IR.ConstructorDecl>, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: cps_provider_10_Preparation}

type EmitterRequestGroup33 is Type:
  EmitterRequest_cps_provider_10_native_match_prepare_family_0{v_3: cps_provider_10_CatalogResult<List<&2, cps_provider_10_Root>>, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: String, v_12: U32, v_14: Nat, v_16: List<&2, BIR.DescriptorArm>, v_19: List<&2, cps_provider_10_Definition>, v_22: Map<&2, cps_provider_10_Definition>, v_25: Map<&2, cps_provider_10_DefinitionHeader>, v_27: List<&2, BIR.ConstructorLayout>, v_30: Map<&2, cps_provider_10_Constructor>, v_32: List<&2, BIR.Family>, v_34: U32, v_36: U32, v_38: Maybe<&2, BIR.Descriptor>, v_41: Maybe<&2, String>, v_44: Map<&2, Bool>, v_46: String}
  EmitterRequest_cps_provider_10_native_match_prepare_family_1{v_1: cps_provider_10_Preparation, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: String, v_11: IR.Words, v_13: U32, v_15: Nat, v_16: Arena.Arena, v_18: List<&2, BIR.DescriptorArm>}
  EmitterRequest_cps_provider_10_native_match_prepare_family_2{v_2: cps_provider_10_CatalogResult<cps_provider_10_Arms>, v_4: String, v_6: Bool, v_7: Scope.ArenaGlobalScope, v_9: Nat, v_11: String, v_12: IR.Words, v_14: U32, v_16: Nat}
  EmitterRequest_cps_provider_10_native_match_prepare_family_3{v_0: IR.TypeDecl, v_1: Arena.Arena, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_prepare_family{v_0: Arena.Arena, v_1: IR.TypeDecl, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_words_count{v_0: IR.Words}
  EmitterRequest_cps_provider_10_block_family{v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: String, v_5: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_law_telescope{v_1: List<&2, IR.Clause>, v_3: U32}
  EmitterRequest_cps_provider_10_law_telescope_cons{v_0: BIR.Quantity, v_2: U32, v_5: Maybe<&2, cps_provider_10_Telescope>}
  EmitterRequest_cps_provider_10_prepare_law{v_0: Arena.Arena, v_1: IR.LawDecl, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_prepare_native_law{v_0: Arena.Arena, v_2: Maybe<&2, BIR.Primitive>, v_5: Maybe<&2, cps_provider_10_Telescope>, v_7: Maybe<&2, Scope.ArenaGlobal>, v_9: String, v_11: U32, v_12: Scope.ArenaGlobalScope, v_14: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_family_key{v_0: IR.TypeDecl, v_2: String}
  EmitterRequest_cps_provider_10_native_match_prepare_declarations_0{v_1: List<&2, Checked.FamilyMetadata>, v_2: Arena.Arena, v_4: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_native_match_prepare_declarations_1{v_2: cps_provider_10_CatalogResult<cps_provider_10_Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: List<&2, IR.TopLevel>}
  EmitterRequest_cps_provider_10_native_match_prepare_declarations_2{v_2: cps_provider_10_CatalogResult<cps_provider_10_Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, IR.TopLevel>, v_13: List<&2, Checked.FamilyMetadata>}
  EmitterRequest_cps_provider_10_native_match_prepare_declarations_3{v_1: Bool, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: cps_provider_10_Preparation, v_12: IR.TypeDecl, v_14: List<&2, IR.TopLevel>, v_16: Nat, v_18: List<&2, Checked.FamilyMetadata>}
  EmitterRequest_cps_provider_10_native_match_prepare_declarations_4{v_1: List<&2, Checked.FamilyMetadata>, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: cps_provider_10_Preparation, v_12: IR.TypeDecl, v_14: List<&2, IR.TopLevel>}
  EmitterRequest_cps_provider_10_native_match_prepare_declarations_5{v_2: cps_provider_10_CatalogResult<cps_provider_10_Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: List<&2, IR.TopLevel>}
  EmitterRequest_cps_provider_10_native_match_prepare_declarations_6{v_1: List<&2, IR.TopLevel>, v_2: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_prepare_declarations{v_0: Arena.Arena, v_2: List<&2, IR.TopLevel>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_reset_module{v_1: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_native_match_prepare_modules_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Preparation>, v_4: Bool, v_6: List<&2, IR.LoadedModule>, v_8: List<&2, Checked.ModuleMetadata>}
  EmitterRequest_cps_provider_10_native_match_prepare_modules_1{v_1: Bool, v_2: Arena.Arena, v_4: Bool, v_6: cps_provider_10_Preparation, v_8: String, v_10: String, v_12: List<&2, IR.TopLevel>, v_14: List<&2, IR.LoadedModule>, v_15: Scope.ArenaGlobalScope, v_17: List<&2, Checked.FamilyMetadata>, v_19: List<&2, Checked.ModuleMetadata>}
  EmitterRequest_cps_provider_10_native_match_prepare_modules_2{v_1: List<&2, IR.LoadedModule>, v_3: List<&2, Checked.ModuleMetadata>, v_4: Arena.Arena, v_6: Bool, v_8: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_prepare_modules{v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Checked.ModuleMetadata>, v_6: Bool, v_8: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_ending{v_3: Maybe<&2, List<&2, String>>, v_5: Maybe<&2, BIR.Descriptor>, v_7: cps_provider_10_Registry, v_8: Arena.Arena, v_11: List<&2, cps_provider_10_Definition>, v_13: List<&2, Scope.ArenaGlobal>, +v_15: cps_provider_7_NfContext}
  EmitterRequest_cps_provider_10_root_main_runnable{v_2: Maybe<&2, cps_provider_10_DefinitionHeader>}
  EmitterRequest_cps_provider_10_root_main_admitted{v_2: Map<&2, cps_provider_10_DefinitionHeader>}
  EmitterRequest_cps_provider_10_executable_admitted{v_3: Maybe<&2, List<&2, String>>, v_6: Map<&2, cps_provider_10_DefinitionHeader>}
  EmitterRequest_cps_provider_10_native_match_build_finish_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Needed>, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>, v_8: List<&2, Checked.ModuleMetadata>, v_12: Maybe<&2, List<&2, String>>, v_15: List<&2, cps_provider_10_Definition>, v_18: Map<&2, cps_provider_10_DefinitionHeader>, v_20: List<&2, BIR.ConstructorLayout>, v_23: Map<&2, cps_provider_10_Constructor>, v_25: List<&2, BIR.Family>, v_27: U32, v_29: Maybe<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_build_finish_2{v_1: Bool, v_2: Arena.Arena, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>, v_8: List<&2, Checked.ModuleMetadata>, v_12: Maybe<&2, List<&2, String>>, v_15: List<&2, cps_provider_10_Definition>, v_18: Map<&2, cps_provider_10_Definition>, v_21: Map<&2, cps_provider_10_DefinitionHeader>, v_23: List<&2, BIR.ConstructorLayout>, v_26: Map<&2, cps_provider_10_Constructor>, v_28: List<&2, BIR.Family>, v_30: U32, v_33: List<&2, cps_provider_10_Root>, v_35: Maybe<&2, BIR.Descriptor>}
  EmitterRequest_cps_provider_10_native_match_build_finish_1{v_1: cps_provider_10_Preparation, v_2: Arena.Arena, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>, v_8: List<&2, Checked.ModuleMetadata>, v_12: Maybe<&2, List<&2, String>>}
  EmitterRequest_cps_provider_10_build_finish{v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Scope.ArenaGlobal>, v_6: List<&2, Checked.ModuleMetadata>, v_10: Maybe<&2, List<&2, String>>, v_12: cps_provider_10_Preparation}
  EmitterRequest_cps_provider_10_native_match_build_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Preparation>, v_6: Maybe<&2, List<&2, String>>, v_8: List<&2, IR.LoadedModule>, v_10: List<&2, Scope.ArenaGlobal>, v_12: List<&2, Checked.ModuleMetadata>}
  EmitterRequest_cps_provider_10_native_match_build_1{v_0: Checked.CheckedProgram, v_4: Maybe<&2, List<&2, String>>}
  EmitterRequest_cps_provider_10_build{v_0: Checked.CheckedProgram, v_4: Maybe<&2, List<&2, String>>}
  EmitterRequest_cps_provider_10_native_match_live_telescope_0{v_2: cps_provider_10_CatalogResult<cps_provider_10_Telescope>, v_4: U32, v_5: Arena.Binder}
  EmitterRequest_cps_provider_10_native_match_live_telescope_1{v_3: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_5: U32, v_7: U32, v_9: U32}
  EmitterRequest_cps_provider_10_native_match_live_telescope_2{v_4: Sigma<&1, &1, Arena.Arena, _ => U32>, v_6: U32, v_8: U32, v_10: U32}
  EmitterRequest_cps_provider_10_native_match_live_telescope_3{v_0: IR.Words, v_1: Arena.Arena, v_3: U32}
  EmitterRequest_cps_provider_10_live_telescope{v_0: Arena.Arena, v_1: IR.Words, v_3: U32}
  EmitterRequest_cps_provider_10_live_binder{v_0: Arena.Binder, v_2: U32, v_4: cps_provider_10_Telescope}
  EmitterRequest_cps_provider_10_primitive_arity{v_0: BIR.Primitive}
  EmitterRequest_cps_provider_10_constructor_field{v_1: cps_provider_10_Constructor, v_3: U32}
  EmitterRequest_cps_provider_10_constructor_field_at{v_3: List<&2, Maybe<&2, String>>, v_5: List<&2, BIR.Quantity>, v_7: Nat, v_9: U32}

type EmitterRequest is Type:
  EmitterRequestGroup_0{request: EmitterRequestGroup0}
  EmitterRequestGroup_1{request: EmitterRequestGroup1}
  EmitterRequestGroup_2{request: EmitterRequestGroup2}
  EmitterRequestGroup_3{request: EmitterRequestGroup3}
  EmitterRequestGroup_4{request: EmitterRequestGroup4}
  EmitterRequestGroup_5{request: EmitterRequestGroup5}
  EmitterRequestGroup_6{request: EmitterRequestGroup6}
  EmitterRequestGroup_7{request: EmitterRequestGroup7}
  EmitterRequestGroup_8{request: EmitterRequestGroup8}
  EmitterRequestGroup_9{request: EmitterRequestGroup9}
  EmitterRequestGroup_10{request: EmitterRequestGroup10}
  EmitterRequestGroup_11{request: EmitterRequestGroup11}
  EmitterRequestGroup_12{request: EmitterRequestGroup12}
  EmitterRequestGroup_13{request: EmitterRequestGroup13}
  EmitterRequestGroup_14{request: EmitterRequestGroup14}
  EmitterRequestGroup_15{request: EmitterRequestGroup15}
  EmitterRequestGroup_16{request: EmitterRequestGroup16}
  EmitterRequestGroup_17{request: EmitterRequestGroup17}
  EmitterRequestGroup_18{request: EmitterRequestGroup18}
  EmitterRequestGroup_19{request: EmitterRequestGroup19}
  EmitterRequestGroup_20{request: EmitterRequestGroup20}
  EmitterRequestGroup_21{request: EmitterRequestGroup21}
  EmitterRequestGroup_22{request: EmitterRequestGroup22}
  EmitterRequestGroup_23{request: EmitterRequestGroup23}
  EmitterRequestGroup_24{request: EmitterRequestGroup24}
  EmitterRequestGroup_25{request: EmitterRequestGroup25}
  EmitterRequestGroup_26{request: EmitterRequestGroup26}
  EmitterRequestGroup_27{request: EmitterRequestGroup27}
  EmitterRequestGroup_28{request: EmitterRequestGroup28}
  EmitterRequestGroup_29{request: EmitterRequestGroup29}
  EmitterRequestGroup_30{request: EmitterRequestGroup30}
  EmitterRequestGroup_31{request: EmitterRequestGroup31}
  EmitterRequestGroup_32{request: EmitterRequestGroup32}
  EmitterRequestGroup_33{request: EmitterRequestGroup33}

def emitter_result_group_0(request: EmitterRequestGroup0) -> Type:
  match request:
    case EmitterRequest_emitted_js{_}: EmitResult
    case EmitterRequest_emitted_c{_}: EmitResult
    case EmitterRequest_emit{_, _}: EmitResult
    case EmitterRequest_emit_library{_, _, _}: EmitResult
    case EmitterRequest_emit_c{_, _, _}: EmitResult
    case EmitterRequest_emit_c_library{_, _, _, _}: EmitResult
    case EmitterRequest_emit_bir{_, _}: EmitResult
    case EmitterRequest_emit_c_bir{_, _, _}: EmitResult
    case EmitterRequest_cps_provider_1_use{_}: BIR.Use
    case EmitterRequest_cps_provider_1_bir_use{_}: BIR.Use
    case EmitterRequest_cps_provider_1_no_span{}: Ast.SourceSpan
    case EmitterRequest_cps_provider_1_problem_first{_, _, _}: Maybe<&2, cps_provider_1_Problem>
    case EmitterRequest_cps_provider_1_fail{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_state_problem_0{_}: cps_provider_1_State
    case EmitterRequest_cps_provider_1_state_problem{_, _, _}: cps_provider_1_State
    case EmitterRequest_cps_provider_1_native_match_node_0{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<Arena.Node>
    case EmitterRequest_cps_provider_1_native_match_node_1{_, _}: cps_provider_1_LowerResult<Arena.Node>
    case EmitterRequest_cps_provider_1_node{_, _}: cps_provider_1_LowerResult<Arena.Node>
    case EmitterRequest_cps_provider_1_native_match_name_0{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<String>
    case EmitterRequest_cps_provider_1_native_match_name_1{_, _}: cps_provider_1_LowerResult<String>
    case EmitterRequest_cps_provider_1_name{_, _}: cps_provider_1_LowerResult<String>
    case EmitterRequest_cps_provider_1_fresh{_}: cps_provider_1_LowerResult<U32>
    case EmitterRequest_cps_provider_1_reserve{_, _}: cps_provider_1_State
    case EmitterRequest_cps_provider_1_push{_, _}: cps_provider_1_State
    case EmitterRequest_cps_provider_1_native_match_operation_0{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_operation{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_guard{_, _, _}: cps_provider_1_State
    case EmitterRequest_cps_provider_1_prefix{_, _}: BIR.Block
    case EmitterRequest_cps_provider_1_finish{_, _}: BIR.Block
    case EmitterRequest_cps_provider_1_finish_last{_, _, _, _, _}: BIR.Block
    case EmitterRequest_cps_provider_1_slot_at{_, _}: Maybe<&2, cps_provider_1_Slot>
    case EmitterRequest_cps_provider_1_capture_found{_, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_capture_found_next{_, _, _, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_resolve{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_resolve_live{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_resolve_owner_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_resolve_owner_1{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_resolve_owner{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_resolve_capture{_, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_variable{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_variable_found{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_bind_slot_0{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<cps_provider_1_Slot>
    case EmitterRequest_cps_provider_1_native_match_bind_slot_1{_, _, _, _}: cps_provider_1_LowerResult<cps_provider_1_Slot>
    case EmitterRequest_cps_provider_1_native_match_bind_slot_2{_, _, _}: cps_provider_1_LowerResult<cps_provider_1_Slot>
    case EmitterRequest_cps_provider_1_bind_slot{_, _, _}: cps_provider_1_LowerResult<cps_provider_1_Slot>
    case EmitterRequest_cps_provider_1_enter{_}: cps_provider_1_LowerResult<cps_provider_1_Frame>
    case EmitterRequest_cps_provider_1_capture_uses{_}: List<&2, BIR.Use>
    case EmitterRequest_cps_provider_1_leave{_, _, _, _}: cps_provider_1_LowerResult<cps_provider_1_CodeRef>
    case EmitterRequest_cps_provider_1_leave_value{_, _, _, _}: cps_provider_1_LowerResult<cps_provider_1_CodeRef>
    case EmitterRequest_cps_provider_1_capture_arguments{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Arg>>
    case EmitterRequest_cps_provider_1_native_match_capture_argument_0{_, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Arg>>
    case EmitterRequest_cps_provider_1_native_match_capture_argument_1{_, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Arg>>
    case EmitterRequest_cps_provider_1_native_match_capture_argument_2{_, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Arg>>
    case EmitterRequest_cps_provider_1_capture_argument{_, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Arg>>
    case EmitterRequest_cps_provider_1_native_match_close_0{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_close_1{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_close{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_call_reference_0{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_call_reference_1{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_call_reference{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_constructor_native{_}: String
    case EmitterRequest_cps_provider_1_constructor_id{_}: U32
    case EmitterRequest_cps_provider_1_constructor_key{_}: String
    case EmitterRequest_cps_provider_1_atom_arguments{_}: List<&2, BIR.Arg>

def emitter_result_group_1(request: EmitterRequestGroup1) -> Type:
  match request:
    case EmitterRequest_cps_provider_1_describe{_, _}: cps_provider_1_LowerResult<Maybe<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_1_element_value{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_1_single_argument{_}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_1_map_value_argument{_}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_1_element_argument{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_1_primitive_element{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_primitive_types{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_occurrence_type{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_first_binding_type{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_first_occurrence_type{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_erased_type_term{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_parameter_uses{_}: List<&2, BIR.Use>
    case EmitterRequest_cps_provider_1_live_argument_type{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_last_live_argument_type{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_array_element_handle{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_array_element_is_argument{_}: Bool
    case EmitterRequest_cps_provider_1_array_primitive{_}: Bool
    case EmitterRequest_cps_provider_1_element_primitive{_}: Bool
    case EmitterRequest_cps_provider_1_primitive{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_primitive_call{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_primitive_call_element{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_element_fact{_, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_1_effective_arrayed{_, _}: Bool
    case EmitterRequest_cps_provider_1_primitive_fact{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_field_values{_, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Field>>
    case EmitterRequest_cps_provider_1_native_match_field_value_0{_, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Field>>
    case EmitterRequest_cps_provider_1_native_match_field_value_1{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Field>>
    case EmitterRequest_cps_provider_1_field_value{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Field>>
    case EmitterRequest_cps_provider_1_nat_successor_result{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_nat_successor_value{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_nat_successor_atom{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_construct{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_construct_native_0{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_construct_native_1{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_construct_native{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_construct_symbol{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_construct_found{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_constructor_operands_0{_}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_constructor_operands_1{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_constructor_operands_2{_, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_constructor_operands_3{_, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_constructor_operands{_, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_reference{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_reference_kind_0{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_reference_kind{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_symbol_value{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_string_authorized{_, _, _}: Bool
    case EmitterRequest_cps_provider_1_string_authorized_found{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_1_literal_characters{_}: List<&2, Char>
    case EmitterRequest_cps_provider_1_native_match_literal_word_0{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_literal_word_1{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_literal_word_2{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_literal_word{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_literal_bit{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_literal_string{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_literal_string_authorized{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_literal_string_records{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_literal_string_items_0{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_literal_string_items_1{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_literal_string_items_2{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_literal_string_items_3{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_literal_string_items_4{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_literal_string_items{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_spine_0{_, _, _, _}: cps_provider_1_LowerResult<cps_provider_1_Spine>

def emitter_result_group_2(request: EmitterRequestGroup2) -> Type:
  match request:
    case EmitterRequest_cps_provider_1_native_match_spine_1{_, _, _}: cps_provider_1_LowerResult<cps_provider_1_Spine>
    case EmitterRequest_cps_provider_1_spine{_, _, _}: cps_provider_1_LowerResult<cps_provider_1_Spine>
    case EmitterRequest_cps_provider_1_spine_shape{_, _, _, _, _}: cps_provider_1_LowerResult<cps_provider_1_Spine>
    case EmitterRequest_cps_provider_1_head_definition{_, _}: Maybe<&2, cps_provider_10_DefinitionHeader>
    case EmitterRequest_cps_provider_1_applications{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_header_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_header_1{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_application_header{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_application_known{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_native_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_native_1{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_native_2{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_native_3{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_arrow_facts{_, _}: cps_provider_1_ArrowFacts
    case EmitterRequest_cps_provider_1_arrow_facts_rest{_}: cps_provider_1_ArrowFacts
    case EmitterRequest_cps_provider_1_last_domain{_}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_1_last_domain_rest{_, _}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_1_first_element_argument{_}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_1_first_map_argument{_}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_1_partial_element{_, _}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_1_parameterize{_, _}: List<&2, BIR.Parameter>
    case EmitterRequest_cps_provider_1_partial_array_parameters{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>
    case EmitterRequest_cps_provider_1_partial_array_code{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_partial_block{_, _}: BIR.Block
    case EmitterRequest_cps_provider_1_partial_call{_, _, _, _}: BIR.Op
    case EmitterRequest_cps_provider_1_partial_array_body{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_capture_argument_uses{_}: List<&2, BIR.Use>
    case EmitterRequest_cps_provider_1_partial_array_build{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_partial_array_described{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_partial_array_facts{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_partial_array_typed{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_partial_array_call{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_partial_typed{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_application_native_partial{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_native_4{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_application_native{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_direct_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_direct_1{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_direct_2{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_direct_3{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_application_direct{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_direct_values_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_direct_values_1{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_application_direct_values{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_direct_arity{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_argument_prefix_0{_, _, _, _}: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>
    case EmitterRequest_cps_provider_1_native_match_argument_prefix_1{_, _, _}: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>
    case EmitterRequest_cps_provider_1_native_match_argument_prefix_2{_, _, _, _, _, _}: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>
    case EmitterRequest_cps_provider_1_native_match_argument_prefix_3{_, _, _, _, _}: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>
    case EmitterRequest_cps_provider_1_argument_prefix{_, _, _, _, _}: cps_provider_1_LowerResult<Pair(List<&2, BIR.Arg>, List<&2, cps_provider_1_SourceArgument>)>
    case EmitterRequest_cps_provider_1_native_match_apply_rest_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_apply_rest_1{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_apply_rest_2{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_apply_rest{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_drop_parameters{_, _}: List<&2, BIR.Parameter>
    case EmitterRequest_cps_provider_1_argument_uses{_}: List<&2, BIR.Use>
    case EmitterRequest_cps_provider_1_indexed_captures{_, _}: List<&2, BIR.Arg>
    case EmitterRequest_cps_provider_1_parameter_arguments{_}: List<&2, BIR.Arg>
    case EmitterRequest_cps_provider_1_native_match_partial_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_partial_1{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_partial{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_tag{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_tag_native{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_project{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>

def emitter_result_group_3(request: EmitterRequestGroup3) -> Type:
  match request:
    case EmitterRequest_cps_provider_1_project_native{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_project_field{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_pattern_identity{_, _}: String
    case EmitterRequest_cps_provider_1_pattern_identity_found{_}: String
    case EmitterRequest_cps_provider_1_closed_bit{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_closed_bit_identity{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_closed_word{_, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_closed_word_identity{_, _, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_closed_word_parts{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_closed_scalar{_, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_1_erase_pattern{_, _}: List<&2, cps_provider_1_Slot>
    case EmitterRequest_cps_provider_1_erase_patterns{_, _}: List<&2, cps_provider_1_Slot>
    case EmitterRequest_cps_provider_1_native_match_patterns_0{_, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_patterns_1{_, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_patterns{_, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_pattern_0{_, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_pattern_1{_, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_pattern{_, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_pattern_constructor{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_pattern_scalar_0{_, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_pattern_scalar_1{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_pattern_scalar_2{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_pattern_scalar{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_scalar_test{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_pattern_fields_0{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_pattern_fields_1{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_pattern_fields_2{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_pattern_fields{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_lower_values_0{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_lower_values_1{_, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_lower_values_2{_, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_lower_values{_, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_new_parameters_0{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>
    case EmitterRequest_cps_provider_1_native_match_new_parameters_1{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>
    case EmitterRequest_cps_provider_1_native_match_new_parameters_2{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>
    case EmitterRequest_cps_provider_1_new_parameters{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Parameter>>
    case EmitterRequest_cps_provider_1_parameter_values{_}: List<&2, BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_checked_cases_0{_, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_native_match_checked_cases_1{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_native_match_checked_cases_2{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_native_match_checked_cases_3{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_native_match_checked_cases_4{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_native_match_checked_cases_5{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_checked_cases{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_take_block{_, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_native_match_match_values_0{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_match_values_1{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_match_values_2{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_match_values_3{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_match_values{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_split_occurrences_0{_, _}: Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>)
    case EmitterRequest_cps_provider_1_native_match_split_occurrences_1{_, _}: Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>)
    case EmitterRequest_cps_provider_1_split_occurrences{_, _}: Pair(List<&2, IR.Occurrence>, List<&2, IR.Occurrence>)
    case EmitterRequest_cps_provider_1_native_match_lower_match_0{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lower_match_1{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_lower_match{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_occurrence_term{_}: U32
    case EmitterRequest_cps_provider_1_native_match_lower_0{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lower_1{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lower_2{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lower_3{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lower_4{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_lower_occurrence{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_lexical_reference{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>

def emitter_result_group_4(request: EmitterRequestGroup4) -> Type:
  match request:
    case EmitterRequest_cps_provider_1_native_match_lower_node_0{_}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lower_node_1{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_lower_node{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_resolved_reference{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_only_child{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_annotated_child{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_rewrite_checked{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_checked_0{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_application_checked_1{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_application_checked{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_constructor_checked_0{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_constructor_checked_1{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_constructor_checked{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lambda_checked_0{_}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lambda_checked_1{_, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lambda_checked_2{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lambda_checked_3{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lambda_checked_4{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_lambda_checked_5{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_lambda_checked{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_absurd_checked_0{_}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_absurd_checked_1{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_absurd_checked_2{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_absurd_checked_3{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_absurd_checked{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_local_values_0{_}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_local_values_1{_, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_local_values_2{_, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_local_values_3{_, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_local_values{_, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Atom>>
    case EmitterRequest_cps_provider_1_native_match_let_checked_0{_, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_let_checked_1{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_let_checked{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_let_bindings_0{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_let_bindings_1{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_native_match_let_bindings_2{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_let_bindings{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_scalar_literal{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_scalar_literal_native_0{_, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_scalar_literal_native_1{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_scalar_literal_native_2{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_scalar_literal_native{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_take_instructions{_}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Instruction>>
    case EmitterRequest_cps_provider_1_matcher_checked{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_0{_}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_1{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_2{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_3{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_4{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_5{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_6{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_7{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_8{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_9{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_10{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_constructor_11{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_matcher_constructor{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_constructor_quantities{_}: List<&2, BIR.Quantity>
    case EmitterRequest_cps_provider_1_matcher_field_use{_, _}: BIR.Use
    case EmitterRequest_cps_provider_1_native_match_matcher_fields_0{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_fields_1{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_matcher_fields_2{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_matcher_fields{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Atom>
    case EmitterRequest_cps_provider_1_native_match_definition_frame_0{_, _, _}: cps_provider_1_State

def emitter_result_group_5(request: EmitterRequestGroup5) -> Type:
  match request:
    case EmitterRequest_cps_provider_1_definition_frame{_, _, _, _}: cps_provider_1_State
    case EmitterRequest_cps_provider_1_definition_env{_, _, _, _, _}: cps_provider_1_LowerResult<List<&2, cps_provider_1_Slot>>
    case EmitterRequest_cps_provider_1_definitions{_, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_definition{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_definition_kind{_, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_definition_local{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_definition_parameter{_, _}: Bool
    case EmitterRequest_cps_provider_1_definition_locals{_, _}: Bool
    case EmitterRequest_cps_provider_1_definition_locals_frame{_, _, _}: Bool
    case EmitterRequest_cps_provider_1_definition_atom_block{_}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_definition_match_direct{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_definition_match_state{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_definition_match_values{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_definition_match_parts{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_definition_root_node{_, _, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_definition_root_other{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_definition_root{_, _, _, _, _}: cps_provider_1_LowerResult<BIR.Block>
    case EmitterRequest_cps_provider_1_native_match_definition_body_0{_, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_native_match_definition_body_2{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_native_match_definition_body_3{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_definition_body{_, _, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_definition_complete{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_native_match_definition_closed_0{_, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_native_match_definition_closed_1{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_definition_closed{_, _, _, _, _, _, _, _, _}: cps_provider_1_LowerResult<List<&2, BIR.Declaration>>
    case EmitterRequest_cps_provider_1_native_match_template_binders_0{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_native_match_template_binders_1{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_native_match_template_binders_2{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_binders{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_binder{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_native_match_template_declarations_0{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_declarations{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_declaration_result{_, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_declaration{_, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_constructor_result{_, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_native_match_template_constructors_0{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_constructors{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_native_match_template_modules_0{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_modules{_, _, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_template_module_result{_, _}: cps_provider_1_TemplateResult
    case EmitterRequest_cps_provider_1_prepare{_}: cps_provider_1_Prepared
    case EmitterRequest_cps_provider_1_prepare_result{_, _, _, _}: cps_provider_1_Prepared
    case EmitterRequest_cps_provider_1_lower{_}: cps_provider_1_ProgramResult
    case EmitterRequest_cps_provider_1_lower_library{_, _}: cps_provider_1_ProgramResult
    case EmitterRequest_cps_provider_1_lower_prepared{_, _}: cps_provider_1_ProgramResult
    case EmitterRequest_cps_provider_1_lower_catalog{_}: cps_provider_1_ProgramResult
    case EmitterRequest_cps_provider_1_lower_definitions{_, _, _, _, _}: cps_provider_1_ProgramResult
    case EmitterRequest_cps_provider_1_lower_complete{_, _, _, _, _, _, _}: cps_provider_1_ProgramResult
    case EmitterRequest_cps_provider_2_build_new{}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_entries{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_codes{_, _, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_code_key{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_code_key_one{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_scan_reads{_}: Map<&2, Bool>
    case EmitterRequest_cps_provider_2_scan_closures{_}: Map<&2, Nat>
    case EmitterRequest_cps_provider_2_code_stem{_}: String
    case EmitterRequest_cps_provider_2_native_stem{_}: String
    case EmitterRequest_cps_provider_2_foreign_stem{_}: String
    case EmitterRequest_cps_provider_2_stage_key{_, _}: String
    case EmitterRequest_cps_provider_2_code_stage_start{_, _, _, _}: Nat
    case EmitterRequest_cps_provider_2_stage_from_closures{_, _, _}: Nat
    case EmitterRequest_cps_provider_2_build_one_code{_, _, _, _, _, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_stage_code{_, _, _, _, _, _, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_staged{_, _, _, _, _}: cps_provider_2_Build

def emitter_result_group_6(request: EmitterRequestGroup6) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_entry_kind_arity{_}: Nat
    case EmitterRequest_cps_provider_2_build_entry{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_with_code{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_with_key{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_with_foreign{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_with_native{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_lazy{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_live_quantities{_, _}: Nat
    case EmitterRequest_cps_provider_2_live_quantity_next{_, _}: Nat
    case EmitterRequest_cps_provider_2_build_native{_, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_native_one{_, _, _, _, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_stage_native{_, _, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_foreign{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_build_foreign_each{_, _, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_stage_foreign{_, _, _, _, _, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_foreign_stage_start{_, _}: Nat
    case EmitterRequest_cps_provider_2_finish_entries{_, _}: cps_provider_2_Build
    case EmitterRequest_cps_provider_2_top_entry_kind{_}: cps_provider_2_EntryKind
    case EmitterRequest_cps_provider_2_finish_top{_, _, _, _, _, _}: List<&2, cps_provider_2_Entry>
    case EmitterRequest_cps_provider_2_entries_ascending{_}: List<&2, cps_provider_2_Entry>
    case EmitterRequest_cps_provider_2_fid_macro_map{_, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_fid_macros_declarations{_, _, _, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_ending_library{_}: Bool
    case EmitterRequest_cps_provider_2_ending_exports{_}: List<&2, BIR.Export>
    case EmitterRequest_cps_provider_2_plan_make{_, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_finish{_, _, _, _, _, _, _, _, _, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_top{_, _, _, _, _, _, _, _, _, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_pure{_, _, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_set_pure{_, _, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_set_pure_flags{_, _, _, _}: cps_provider_2_Plan
    case EmitterRequest_cps_provider_2_fid_macros_runtime{_}: Map<&2, String>
    case EmitterRequest_cps_provider_2_fid_macros_runtime_one{_}: Map<&2, String>
    case EmitterRequest_cps_provider_2_plan_executable{_, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_executable_native{_, _, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_executable_io{_, _, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_executable_show{_, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_plan_library{_, _}: cps_provider_2_PlanResult
    case EmitterRequest_cps_provider_2_export_rows{_, _, _, _, _, _, _}: Maybe<&2, List<&2, cps_provider_2_ExportRow>>
    case EmitterRequest_cps_provider_2_export_row_pair{_, _}: Maybe<&2, List<&2, cps_provider_2_ExportRow>>
    case EmitterRequest_cps_provider_2_export_row{_, _, _, _, _, _, _}: Maybe<&2, cps_provider_2_ExportRow>
    case EmitterRequest_cps_provider_2_export_direct{_, _, _, _}: Maybe<&2, cps_provider_2_ExportRow>
    case EmitterRequest_cps_provider_2_export_direct_curried{_, _, _, _, _}: Maybe<&2, cps_provider_2_ExportRow>
    case EmitterRequest_cps_provider_2_export_symbol{_, _, _, _, _, _, _}: Maybe<&2, cps_provider_2_ExportRow>
    case EmitterRequest_cps_provider_2_export_symbol_item{_, _, _, _, _, _, _}: Maybe<&2, cps_provider_2_ExportRow>
    case EmitterRequest_cps_provider_2_export_declared{_, _, _, _, _}: Maybe<&2, cps_provider_2_ExportRow>
    case EmitterRequest_cps_provider_2_export_names{_, _}: String
    case EmitterRequest_cps_provider_2_if_first{_}: String
    case EmitterRequest_cps_provider_2_export_values{_, _, _}: String
    case EmitterRequest_cps_provider_2_export_value{_, _, _, _}: String
    case EmitterRequest_cps_provider_2_export_list{_, _}: String
    case EmitterRequest_cps_provider_2_exports_c{_, _}: String
    case EmitterRequest_cps_provider_2_descriptor_head{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_family_key{_, _}: Maybe<&2, BIR.Family>
    case EmitterRequest_cps_provider_2_build_entries_of{_}: List<&2, cps_provider_2_Entry>
    case EmitterRequest_cps_provider_2_by_code_of{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_by_key_of{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_by_foreign_of{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_by_native_of{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_stages_of{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_fkeys_of{_}: List<&2, String>
    case EmitterRequest_cps_provider_2_cat{_}: String
    case EmitterRequest_cps_provider_2_okp{_}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_failp{_}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_part_join{_}: cps_provider_2_Part

def emitter_result_group_7(request: EmitterRequestGroup7) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_part_append{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_part_first{_}: String
    case EmitterRequest_cps_provider_2_part_require{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_nat_c{_}: String
    case EmitterRequest_cps_provider_2_u32_c{_}: String
    case EmitterRequest_cps_provider_2_list_at{_, _}: String
    case EmitterRequest_cps_provider_2_member{_, _}: Bool
    case EmitterRequest_cps_provider_2_member_one{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_map_flag{_, _}: Bool
    case EmitterRequest_cps_provider_2_map_nat{_, _}: Nat
    case EmitterRequest_cps_provider_2_map_u32{_, _}: U32
    case EmitterRequest_cps_provider_2_map_set_first{_, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_nat_min{_, _}: Nat
    case EmitterRequest_cps_provider_2_nat_max{_, _}: Nat
    case EmitterRequest_cps_provider_2_last_segment{_}: String
    case EmitterRequest_cps_provider_2_last_segment_list{_, _}: String
    case EmitterRequest_cps_provider_2_list_index_of{_, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_list_index_one{_, _, _, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_ctor_keys{_}: List<&2, String>
    case EmitterRequest_cps_provider_2_entry_at{_, _}: Maybe<&2, cps_provider_2_Entry>
    case EmitterRequest_cps_provider_2_entry_at_one{_, _, _, _}: Maybe<&2, cps_provider_2_Entry>
    case EmitterRequest_cps_provider_2_entry_arity{_, _}: Nat
    case EmitterRequest_cps_provider_2_max_arity{_}: Nat
    case EmitterRequest_cps_provider_2_max_arity_each{_, _}: Nat
    case EmitterRequest_cps_provider_2_scan_new{}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_program{_}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_exports{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_codes{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_declarations{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_declaration{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_foreign{_, _, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_read{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_close{_, _, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_close_min{_, _, _}: Map<&2, Nat>
    case EmitterRequest_cps_provider_2_scan_atom{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_argument{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_arguments{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_fields{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_op{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_scan_block{_, _}: cps_provider_2_Scan
    case EmitterRequest_cps_provider_2_cid_rows{_, _, _, _}: cps_provider_2_CidRows
    case EmitterRequest_cps_provider_2_cid_arity_field{_}: Nat
    case EmitterRequest_cps_provider_2_cid_rows_check{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_cid_node_arity{_, _}: Maybe<&2, Nat>
    case EmitterRequest_cps_provider_2_cid_ctor_rows{_, _, _, _, _}: cps_provider_2_CidRows
    case EmitterRequest_cps_provider_2_cid_foreign_rows{_, _, _}: List<&2, cps_provider_2_CidRow>
    case EmitterRequest_cps_provider_2_cid_foreign_each{_, _, _, _, _}: List<&2, cps_provider_2_CidRow>
    case EmitterRequest_cps_provider_2_cid_lookup{_, _}: U32
    case EmitterRequest_cps_provider_2_cid_lookup_one{_, _, _, _}: U32
    case EmitterRequest_cps_provider_2_cid_short_one{_, _, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_cid_short{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_cid_c{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_cid_macro_map{_}: Map<&2, String>
    case EmitterRequest_cps_provider_2_cid_symbol{_}: String
    case EmitterRequest_cps_provider_2_fid_symbol{_}: String
    case EmitterRequest_cps_provider_2_runtime_cid_alias{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_find_cid_row{_, _}: Maybe<&2, cps_provider_2_CidRow>
    case EmitterRequest_cps_provider_2_find_cid_row_one{_, _, _, _}: Maybe<&2, cps_provider_2_CidRow>
    case EmitterRequest_cps_provider_2_runtime_cid_aliases{_}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_cid_of_row{_}: U32
    case EmitterRequest_cps_provider_2_cid_macro_each{_, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_layout_of{_, _}: Maybe<&2, BIR.ConstructorLayout>
    case EmitterRequest_cps_provider_2_layout_one{_, _, _, _}: Maybe<&2, BIR.ConstructorLayout>
    case EmitterRequest_cps_provider_2_key_layout{_, _}: Maybe<&2, BIR.ConstructorLayout>

def emitter_result_group_8(request: EmitterRequestGroup8) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_live_fields{_, _}: List<&2, BIR.DescriptorField>
    case EmitterRequest_cps_provider_2_live_field_add{_, _, _}: List<&2, BIR.DescriptorField>
    case EmitterRequest_cps_provider_2_arm_of{_, _}: Maybe<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_2_arms_find{_, _, _}: Maybe<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_2_live_index_fields{_, _, _, _}: Nat
    case EmitterRequest_cps_provider_2_live_index_next{_, _}: Nat
    case EmitterRequest_cps_provider_2_atom_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_bool_name{_}: String
    case EmitterRequest_cps_provider_2_bool_lit_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_text_atom_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_symbol_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_find_declaration{_, _}: Maybe<&2, BIR.Declaration>
    case EmitterRequest_cps_provider_2_find_declaration_one{_, _, _, _}: Maybe<&2, BIR.Declaration>
    case EmitterRequest_cps_provider_2_symbol_part_decl{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_symbol_part_item{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_symbol_value{_, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_args_parts{_, _}: List<&2, cps_provider_2_Part>
    case EmitterRequest_cps_provider_2_prim_default_owned{_, _}: Bool
    case EmitterRequest_cps_provider_2_array_arg_owned{_, _}: Bool
    case EmitterRequest_cps_provider_2_descriptor_arg_owned{_, _}: Bool
    case EmitterRequest_cps_provider_2_descriptor_step{_, _, _, _, _, _, _, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_prim_borrowed_box{_, _}: Bool
    case EmitterRequest_cps_provider_2_atom_allocates{_}: Bool
    case EmitterRequest_cps_provider_2_prim_texts{_, _, _, _, _, _, _, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_prim_step{_, _, _, _, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_array_op_step{_, _, _, _, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_array_op_step_element{_, _, _, _, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_pred_path{_, _, _}: Maybe<&2, cps_provider_2_Part>
    case EmitterRequest_cps_provider_2_str_append{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_construct_step{_, _, _, _, _, _, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_hastag_step{_, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_op_step{_, _, _, _}: cps_provider_2_OpStep
    case EmitterRequest_cps_provider_2_phys_part{_}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_field_values{_, _}: List<&2, cps_provider_2_Part>
    case EmitterRequest_cps_provider_2_all_arms_nullary{_}: Bool
    case EmitterRequest_cps_provider_2_all_arms_nullary_one{_, _}: Bool
    case EmitterRequest_cps_provider_2_arm_member{_, _}: Bool
    case EmitterRequest_cps_provider_2_arm_member_one{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_arm_index{_, _, _}: Maybe<&2, Nat>
    case EmitterRequest_cps_provider_2_arm_index_one{_, _, _, _}: Maybe<&2, Nat>
    case EmitterRequest_cps_provider_2_phys_world{_}: cps_provider_5_World
    case EmitterRequest_cps_provider_2_phys_cids{_}: List<&2, cps_provider_5_CidSym>
    case EmitterRequest_cps_provider_2_project_part{_, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_hastag_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_is_array_primitive{_}: Bool
    case EmitterRequest_cps_provider_2_is_descriptor_primitive{_}: Bool
    case EmitterRequest_cps_provider_2_is_atomic_primitive{_}: Bool
    case EmitterRequest_cps_provider_2_pcid{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_str_bool2{_, _, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_bool_str_empty_of{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_bool_str_empty{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_bool_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_prim_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_prim_plain_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_prim_scalar_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_f32_bin{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_f32_un{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_f32_cmp{_, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_bool2_part{_, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_bool2_c{_, _, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_is_bool_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_cmp3_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_divmod_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_str1{_, _, _, _}: cps_provider_2_Part

def emitter_result_group_9(request: EmitterRequestGroup9) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_str_tail{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_str_to_list{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_str1_char{_, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_char_pack_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_str_cmp{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_map_bit_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_char_new_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_word_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_u32_member{_, _}: Bool
    case EmitterRequest_cps_provider_2_u32_add{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_atom_locals{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_arg_locals{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_args_locals{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_field_locals{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_op_locals{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_block_locals{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_atom_slots{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_arg_slots{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_args_slots{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_field_slots{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_op_slots{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_block_slots{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_env_get{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_env_get_one{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_env_del{_, _}: List<&2, cps_provider_2_Env>
    case EmitterRequest_cps_provider_2_ctx_env_put{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_ctx_caps_put{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_env_field{_, _}: Maybe<&2, cps_provider_2_FieldRef>
    case EmitterRequest_cps_provider_2_field_root_expr{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_field_borrow{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_field_read_ref{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_ref_steps{_}: List<&2, cps_provider_5_PathStep>
    case EmitterRequest_cps_provider_2_ref_owners{_}: List<&2, cps_provider_2_FieldRoot>
    case EmitterRequest_cps_provider_2_rebase_ref{_, _}: cps_provider_2_FieldRef
    case EmitterRequest_cps_provider_2_append_owner{_, _}: List<&2, cps_provider_2_FieldRoot>
    case EmitterRequest_cps_provider_2_owner_local{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_owner_slot{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_owners_ancestors{_}: List<&2, cps_provider_2_FieldRoot>
    case EmitterRequest_cps_provider_2_owners_drop_last{_, _}: List<&2, cps_provider_2_FieldRoot>
    case EmitterRequest_cps_provider_2_owner_index{_, _, _}: Maybe<&2, Nat>
    case EmitterRequest_cps_provider_2_owner_same{_, _}: Bool
    case EmitterRequest_cps_provider_2_atom_owner{_}: Maybe<&2, cps_provider_2_FieldRoot>
    case EmitterRequest_cps_provider_2_atom_is_owner{_, _}: Bool
    case EmitterRequest_cps_provider_2_step_at{_, _}: Maybe<&2, cps_provider_5_PathStep>
    case EmitterRequest_cps_provider_2_leave_reach{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_refs_hold_root{_, _}: Bool
    case EmitterRequest_cps_provider_2_regions_hold_root{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_2_regions_reachable_refs{_, _, _}: List<&2, cps_provider_2_CapRef>
    case EmitterRequest_cps_provider_2_reachable_labels{_, _, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_region_keeps_root{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_region_keeps_local{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_region_keeps_slot{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_field_owned{_, _, _, _}: cps_provider_2_WriteStep
    case EmitterRequest_cps_provider_2_atom_use{_, _, _, _}: cps_provider_2_WriteStep
    case EmitterRequest_cps_provider_2_args_use{_, _, _, _}: cps_provider_2_ArgsStep
    case EmitterRequest_cps_provider_2_env_drops{_, _, _}: String
    case EmitterRequest_cps_provider_2_cap_count{_}: Nat
    case EmitterRequest_cps_provider_2_cap_count_each{_, _}: Nat
    case EmitterRequest_cps_provider_2_cap_slots_from{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_cap_slots_of{_}: List<&2, U32>
    case EmitterRequest_cps_provider_2_cap_slots_of_each{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_cap_slots_used{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_cap_slots_del{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_cap_drops{_, _}: String

def emitter_result_group_10(request: EmitterRequestGroup10) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_caps_ids{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_caps_slots{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_arg_decls{_, _, _}: String
    case EmitterRequest_cps_provider_2_arg_names{_, _, _}: List<&2, String>
    case EmitterRequest_cps_provider_2_exit_releases{_, _, _}: String
    case EmitterRequest_cps_provider_2_region_refs{_, _}: List<&2, cps_provider_2_CapRef>
    case EmitterRequest_cps_provider_2_refs_have_local{_, _}: Bool
    case EmitterRequest_cps_provider_2_refs_local_check{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_refs_have_slot{_, _}: Bool
    case EmitterRequest_cps_provider_2_refs_slot_check{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_env_refs{_, _, _, _}: List<&2, cps_provider_2_CapRef>
    case EmitterRequest_cps_provider_2_env_ref_add{_, _, _, _}: List<&2, cps_provider_2_CapRef>
    case EmitterRequest_cps_provider_2_slot_refs{_, _, _, _, _}: List<&2, cps_provider_2_CapRef>
    case EmitterRequest_cps_provider_2_slot_ref_add{_, _, _, _}: List<&2, cps_provider_2_CapRef>
    case EmitterRequest_cps_provider_2_field_root_locals{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_field_root_slots{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_leaf_at{_, _}: Maybe<&2, BIR.Block>
    case EmitterRequest_cps_provider_2_leaves_enter{_, _, _}: List<&2, cps_provider_2_Leave>
    case EmitterRequest_cps_provider_2_ctx_flow_put{_, _, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_ctx_add_call{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_ctx_fork{_, _, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_atoms_after_args{_, _}: BIR.Block
    case EmitterRequest_cps_provider_2_atoms_after_fields{_, _}: BIR.Block
    case EmitterRequest_cps_provider_2_atom_key{_}: Maybe<&2, cps_provider_2_FieldRoot>
    case EmitterRequest_cps_provider_2_atom_path{_, _}: Maybe<&2, cps_provider_2_FieldRef>
    case EmitterRequest_cps_provider_2_atom_path_in{_, _}: Maybe<&2, cps_provider_2_FieldRef>
    case EmitterRequest_cps_provider_2_root_eq{_, _}: Bool
    case EmitterRequest_cps_provider_2_steps_prefix{_, _}: Bool
    case EmitterRequest_cps_provider_2_step_eq{_, _}: Bool
    case EmitterRequest_cps_provider_2_step_eq_field{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_step_eq_half{_, _}: Bool
    case EmitterRequest_cps_provider_2_step_eq_half_both{_, _}: Bool
    case EmitterRequest_cps_provider_2_step_eq_leaf{_}: Bool
    case EmitterRequest_cps_provider_2_path_related{_, _}: Bool
    case EmitterRequest_cps_provider_2_path_before{_, _}: Bool
    case EmitterRequest_cps_provider_2_atom_owner_known{_, _}: Bool
    case EmitterRequest_cps_provider_2_owners_member{_, _}: Bool
    case EmitterRequest_cps_provider_2_project_related{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_2_atom_conflict{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_conflict_atom_list{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_conflict_field_list{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_conflict_op{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_2_projection_conflict{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_2_conflict_block{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_2_path_conflict{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_2_atom_has_key{_, _}: Bool
    case EmitterRequest_cps_provider_2_path_rooted_by{_, _}: Bool
    case EmitterRequest_cps_provider_2_atom_root_used{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_op_root_used{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_args_root_used{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_fields_root_used{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_root_residual{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_2_no_remaining{}: BIR.Block
    case EmitterRequest_cps_provider_2_refs_local_ids{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_needed_refs{_, _}: List<&2, cps_provider_2_CapRef>
    case EmitterRequest_cps_provider_2_u32s_text{_}: String
    case EmitterRequest_cps_provider_2_u32s_text_more{_, _}: String
    case EmitterRequest_cps_provider_2_refs_text{_}: String
    case EmitterRequest_cps_provider_2_refs_text_more{_, _}: String
    case EmitterRequest_cps_provider_2_capture_context{_, _}: String
    case EmitterRequest_cps_provider_2_refs_caps{_, _}: cps_provider_2_CapsStep
    case EmitterRequest_cps_provider_2_cap_ref_text{_}: String
    case EmitterRequest_cps_provider_2_cap_of_ref{_, _}: Maybe<&2, cps_provider_2_Cap>
    case EmitterRequest_cps_provider_2_capture_for{_, _}: cps_provider_2_CapsStep

def emitter_result_group_11(request: EmitterRequestGroup11) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_entry_label{_, _, _}: String
    case EmitterRequest_cps_provider_2_kind_label{_, _}: String
    case EmitterRequest_cps_provider_2_declaration_key{_, _}: String
    case EmitterRequest_cps_provider_2_declaration_key_one{_, _, _, _}: String
    case EmitterRequest_cps_provider_2_ctx_sig{_}: cps_provider_2_Sig
    case EmitterRequest_cps_provider_2_ctx_plan{_}: cps_provider_2_Plan
    case EmitterRequest_cps_provider_2_ctx_env{_}: List<&2, cps_provider_2_Env>
    case EmitterRequest_cps_provider_2_ctx_caps{_}: List<&2, String>
    case EmitterRequest_cps_provider_2_ctx_caps_n{_}: Nat
    case EmitterRequest_cps_provider_2_ctx_regions{_}: List<&2, cps_provider_2_Region>
    case EmitterRequest_cps_provider_2_ctx_self{_}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_ctx_next{_}: U32
    case EmitterRequest_cps_provider_2_ctx_segs{_}: List<&2, cps_provider_2_SegText>
    case EmitterRequest_cps_provider_2_ctx_forked{_}: Bool
    case EmitterRequest_cps_provider_2_ctx_calls{_}: List<&2, U32>
    case EmitterRequest_cps_provider_2_ctx_spin{_}: Bool
    case EmitterRequest_cps_provider_2_ctx_max{_}: Nat
    case EmitterRequest_cps_provider_2_ctx_cap_slots{_}: List<&2, U32>
    case EmitterRequest_cps_provider_2_ctx_leaves{_}: List<&2, cps_provider_2_Leave>
    case EmitterRequest_cps_provider_2_ctx_segs_put{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_ctx_with_leaves{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_sig_entries{_}: List<&2, cps_provider_2_Entry>
    case EmitterRequest_cps_provider_2_sig_by_code{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_sig_by_key{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_sig_by_foreign{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_sig_by_native{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_sig_stages{_}: Map<&2, U32>
    case EmitterRequest_cps_provider_2_sig_decls{_}: List<&2, BIR.Declaration>
    case EmitterRequest_cps_provider_2_sig_cids{_}: List<&2, cps_provider_2_CidRow>
    case EmitterRequest_cps_provider_2_sig_apply{_}: U32
    case EmitterRequest_cps_provider_2_a_name{_}: String
    case EmitterRequest_cps_provider_2_r_name{_}: String
    case EmitterRequest_cps_provider_2_lv_name{_}: String
    case EmitterRequest_cps_provider_2_a_decls{_}: String
    case EmitterRequest_cps_provider_2_a_decls_at{_, _}: String
    case EmitterRequest_cps_provider_2_x_decl{_}: String
    case EmitterRequest_cps_provider_2_x_fill_a{_}: String
    case EmitterRequest_cps_provider_2_x_fill_a_at{_, _}: String
    case EmitterRequest_cps_provider_2_params_bind{_, _, _}: String
    case EmitterRequest_cps_provider_2_params_env{_, _, _, _}: List<&2, cps_provider_2_Env>
    case EmitterRequest_cps_provider_2_a_caps{_}: List<&2, String>
    case EmitterRequest_cps_provider_2_a_caps_at{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_2_caps_assign{_, _}: String
    case EmitterRequest_cps_provider_2_regs_assign{_, _}: String
    case EmitterRequest_cps_provider_2_k_decls{_, _}: String
    case EmitterRequest_cps_provider_2_cap_intro{_, _, _, _}: String
    case EmitterRequest_cps_provider_2_cap_intro_a{_, _, _, _}: String
    case EmitterRequest_cps_provider_2_cap_locals_env{_, _}: List<&2, cps_provider_2_Env>
    case EmitterRequest_cps_provider_2_caps_lookup{_, _}: Bool
    case EmitterRequest_cps_provider_2_caps_lookup_one{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_cap_slots_exprs{_, _, _, _}: List<&2, String>
    case EmitterRequest_cps_provider_2_cap_slot_value{_, _}: String
    case EmitterRequest_cps_provider_2_cont_prologue{_, _, _}: String
    case EmitterRequest_cps_provider_2_cap_stk_intro{_, _, _, _}: String
    case EmitterRequest_cps_provider_2_region_prologue{_, _}: String
    case EmitterRequest_cps_provider_2_a_rebinds{_}: String
    case EmitterRequest_cps_provider_2_a_rebinds_at{_, _}: String
    case EmitterRequest_cps_provider_2_fid_name{_, _}: String
    case EmitterRequest_cps_provider_2_case_text{_, _, _, _}: String
    case EmitterRequest_cps_provider_2_spin_open{_}: String
    case EmitterRequest_cps_provider_2_spin_close{_}: String
    case EmitterRequest_cps_provider_2_block_ctl{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_return_ctl{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_failure_ctl{_}: cps_provider_2_Step

def emitter_result_group_12(request: EmitterRequestGroup12) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_let_ctl{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_pure_let{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_value_let{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_projection_primitive{_}: Bool
    case EmitterRequest_cps_provider_2_projection_step{_, _}: cps_provider_5_PathStep
    case EmitterRequest_cps_provider_2_array_project_bind{_, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_atom_step_ref{_, _, _, _}: cps_provider_2_RefStep
    case EmitterRequest_cps_provider_2_atom_step_ref_in{_, _, _, _}: cps_provider_2_RefStep
    case EmitterRequest_cps_provider_2_project_ref{_, _, _, _, _}: cps_provider_2_RefStep
    case EmitterRequest_cps_provider_2_project_ref_in{_, _, _, _, _}: cps_provider_2_RefStep
    case EmitterRequest_cps_provider_2_bind_provenance{_, _, _}: List<&2, cps_provider_2_Env>
    case EmitterRequest_cps_provider_2_bind_copy_path{_, _, _}: List<&2, cps_provider_2_Env>
    case EmitterRequest_cps_provider_2_ref_root{_}: cps_provider_2_FieldRoot
    case EmitterRequest_cps_provider_2_append_path_step{_, _}: List<&2, cps_provider_5_PathStep>
    case EmitterRequest_cps_provider_2_project_bind{_, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_cond_part_of{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_cond_part{_, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_branch_ctl{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_ctx_arm_start{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_ctx_after_call{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_ctx_after_region{_, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_ctx_after_branch{_, _, _}: cps_provider_2_Ctx
    case EmitterRequest_cps_provider_2_region_ctl{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_region_next{_, _, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_region_body{_, _, _, _, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_find_region{_, _}: Maybe<&2, cps_provider_2_Region>
    case EmitterRequest_cps_provider_2_find_region_one{_, _, _, _}: Maybe<&2, cps_provider_2_Region>
    case EmitterRequest_cps_provider_2_leave_ctl{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_tail_direct_ctl{_, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_tail_jump{_, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_self_tail{_, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_tail_apply_ctl{_, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_direct_ctl{_, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_apply_ctl{_, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_call_ctl{_, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_call_next{_, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_call_done{_, _, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_arg_stores{_, _, _}: String
    case EmitterRequest_cps_provider_2_call_head{_, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_2_cap_stk_stores{_, _}: String
    case EmitterRequest_cps_provider_2_cap_stores{_, _, _}: String
    case EmitterRequest_cps_provider_2_load_symbol_ctl{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_value_bind_entry{_, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_value_closure{_, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_closure_ctl{_, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_closure_bind{_, _, _, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_closure_text{_, _, _, _}: String
    case EmitterRequest_cps_provider_2_closure_entry{_, _, _, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_2_closure_alloc{_, _, _}: String
    case EmitterRequest_cps_provider_2_closure_alloc_decl{_, _, _}: String
    case EmitterRequest_cps_provider_2_closure_ptr{_, _}: String
    case EmitterRequest_cps_provider_2_entries_ctl{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_ctl{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_kind_ctl{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_library{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_reserved{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_add{_, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_code{_, _, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_stage{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_stage_stores{_, _, _}: String
    case EmitterRequest_cps_provider_2_entry_lazy{_, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_native{_, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_native_borrow_drops{_, _, _}: String
    case EmitterRequest_cps_provider_2_a_names{_}: List<&2, String>

def emitter_result_group_13(request: EmitterRequestGroup13) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_entry_foreign{_, _, _, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_entry_main{_, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_main_jump{_, _, _}: cps_provider_2_Step
    case EmitterRequest_cps_provider_2_control_build{_}: cps_provider_2_Control
    case EmitterRequest_cps_provider_2_segs_text{_, _}: String
    case EmitterRequest_cps_provider_2_rt_entry{_, _}: U32
    case EmitterRequest_cps_provider_2_entry_at_kind{_, _}: Maybe<&2, cps_provider_2_Entry>
    case EmitterRequest_cps_provider_2_kind_want{_}: Nat
    case EmitterRequest_cps_provider_2_rows_add_entries{_, _}: List<&2, cps_provider_2_SegText>
    case EmitterRequest_cps_provider_2_rows_add_segs{_, _}: List<&2, cps_provider_2_SegText>
    case EmitterRequest_cps_provider_2_row_insert{_, _}: List<&2, cps_provider_2_SegText>
    case EmitterRequest_cps_provider_2_rows_check{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_cid_defines{_}: String
    case EmitterRequest_cps_provider_2_entry_forks{_}: Bool
    case EmitterRequest_cps_provider_2_forky_has{_, _}: Bool
    case EmitterRequest_cps_provider_2_calls_forky{_, _}: Bool
    case EmitterRequest_cps_provider_2_row_calls_forky{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_forky_seeds{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_forky_round{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_forky_fix{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_2_forky_rows{_}: List<&2, U32>
    case EmitterRequest_cps_provider_2_rows_max_resw{_, _}: Nat
    case EmitterRequest_cps_provider_2_fid_defines{_}: String
    case EmitterRequest_cps_provider_2_hot_text{_}: String
    case EmitterRequest_cps_provider_2_blk_shr_text{_}: String
    case EmitterRequest_cps_provider_2_array_shared_text{_}: String
    case EmitterRequest_cps_provider_2_cid_table{_}: String
    case EmitterRequest_cps_provider_2_fid_table{_, _}: String
    case EmitterRequest_cps_provider_2_wl_table_text{_, _}: String
    case EmitterRequest_cps_provider_2_wl_table_rows{_, _}: String
    case EmitterRequest_cps_provider_2_wl_row_text{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_wl_row_name{_, _}: String
    case EmitterRequest_cps_provider_2_registers_each{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_2_register_decls{_}: String
    case EmitterRequest_cps_provider_2_register_names{_}: String
    case EmitterRequest_cps_provider_2_register_list{_, _}: String
    case EmitterRequest_cps_provider_2_register_tail{_, _}: String
    case EmitterRequest_cps_provider_2_wl_load_rows{_, _}: String
    case EmitterRequest_cps_provider_2_wl_last_rows{_, _}: String
    case EmitterRequest_cps_provider_2_wl_save_rows{_, _}: String
    case EmitterRequest_cps_provider_2_wl_take_rows{_, _}: String
    case EmitterRequest_cps_provider_2_wl_macros{_, _}: String
    case EmitterRequest_cps_provider_2_runtime_defines{_}: String
    case EmitterRequest_cps_provider_2_table_or_zero{_}: String
    case EmitterRequest_cps_provider_2_tables_part{_, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_id_rows_check{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_main_suppress{_}: String
    case EmitterRequest_cps_provider_2_main_fid_index{_, _}: U32
    case EmitterRequest_cps_provider_2_main_pure_text{_}: String
    case EmitterRequest_cps_provider_2_spins_part{}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_helper_core{}: cps_provider_4_Fragment
    case EmitterRequest_cps_provider_2_requests_part{_}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_requests_finish{_, _, _, _, _, _, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_requests_check{_, _, _, _, _, _, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_requests_uncovered{_, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_foreign_namespace{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_foreign_namespace_item{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_requests_uncovered_one{_, _, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_import_has_namespace{_, _}: Bool
    case EmitterRequest_cps_provider_2_import_has_namespace_one{_, _, _}: Bool
    case EmitterRequest_cps_provider_2_requests_each{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_rewrite_source{_, _, _, _, _, _, _, _}: cps_provider_2_Part
    case EmitterRequest_cps_provider_2_cid_keys{_}: List<&2, String>
    case EmitterRequest_cps_provider_2_fid_keys{_}: List<&2, String>

def emitter_result_group_14(request: EmitterRequestGroup14) -> Type:
  match request:
    case EmitterRequest_cps_provider_2_insert_section{_, _, _}: Maybe<&2, List<&2, cps_provider_4_Fragment>>
    case EmitterRequest_cps_provider_2_insert_rule{_, _, _}: Maybe<&2, List<&2, cps_provider_4_Fragment>>
    case EmitterRequest_cps_provider_2_insert_prefix{_, _}: Maybe<&2, List<&2, cps_provider_4_Fragment>>
    case EmitterRequest_cps_provider_2_split_lines{_}: List<&2, String>
    case EmitterRequest_cps_provider_2_split_lines_each{_, _, _}: List<&2, String>
    case EmitterRequest_cps_provider_2_line_text{_}: String
    case EmitterRequest_cps_provider_2_fragment_lines{_}: List<&2, cps_provider_4_Fragment>
    case EmitterRequest_cps_provider_2_join_lines{_}: cps_provider_4_Fragment
    case EmitterRequest_cps_provider_2_join_pieces{_, _, _}: cps_provider_4_Fragment
    case EmitterRequest_cps_provider_2_assemble{_, _, _, _, _}: Maybe<&2, cps_provider_4_Fragment>
    case EmitterRequest_cps_provider_2_assemble_spins{_, _, _, _}: Maybe<&2, cps_provider_4_Fragment>
    case EmitterRequest_cps_provider_2_assemble_segments{_, _, _}: Maybe<&2, cps_provider_4_Fragment>
    case EmitterRequest_cps_provider_2_assemble_requests{_, _}: Maybe<&2, cps_provider_4_Fragment>
    case EmitterRequest_cps_provider_2_cid_exact_map{_}: Map<&2, String>
    case EmitterRequest_cps_provider_2_cid_exact_each{_, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_fid_exact_map{_, _, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_namespaced_map{_, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_namespaced_each{_, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_namespaced_set{_, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_fid_fixed{_}: Map<&2, String>
    case EmitterRequest_cps_provider_2_fid_fixed_one{_}: Map<&2, String>
    case EmitterRequest_cps_provider_2_fid_exact_decl{_, _, _, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_2_macro_collision_cids{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_macro_collision_rows{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_macro_collision_one{_, _, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_2_emit{_, _, _}: cps_provider_2_EmitResult
    case EmitterRequest_cps_provider_2_render{_, _}: cps_provider_2_EmitResult
    case EmitterRequest_cps_provider_2_render_parts{_, _, _, _}: cps_provider_2_EmitResult
    case EmitterRequest_cps_provider_2_segments_text{_}: cps_provider_4_Fragment
    case EmitterRequest_cps_provider_2_render_assemble{_, _, _, _, _, _, _}: cps_provider_2_EmitResult
    case EmitterRequest_cps_provider_2_render_rewrite{_, _, _}: cps_provider_2_EmitResult
    case EmitterRequest_cps_provider_3_context{_}: cps_provider_3_Context
    case EmitterRequest_cps_provider_3_context_nf{_}: cps_provider_7_NfContext
    case EmitterRequest_cps_provider_3_context_families{_}: List<&2, BIR.Family>
    case EmitterRequest_cps_provider_3_context_plan{_}: cps_provider_3_Plan
    case EmitterRequest_cps_provider_3_context_nodes{_}: Map<&2, cps_provider_3_NodeResult>
    case EmitterRequest_cps_provider_3_context_arms{_}: Map<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_3_nf_families{_}: Map<&2, BIR.Family>
    case EmitterRequest_cps_provider_3_nf_functions{_}: Map<&2, BIR.TypeFunction>
    case EmitterRequest_cps_provider_3_family_lookup{_, _}: Maybe<&2, BIR.Family>
    case EmitterRequest_cps_provider_3_function_lookup{_, _}: Maybe<&2, BIR.TypeFunction>
    case EmitterRequest_cps_provider_3_arm_of{_, _}: Maybe<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_3_arm_in{_, _}: Maybe<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_3_plan_arm_index{_}: Map<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_3_plan_family_arms{_, _}: Map<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_3_arm_declared{_, _}: Maybe<&2, BIR.DescriptorArm>
    case EmitterRequest_cps_provider_3_live_field{_}: Bool
    case EmitterRequest_cps_provider_3_layout_fuel{}: Nat
    case EmitterRequest_cps_provider_3_nf_of{_, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_3_value_layout{_, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_layout_of_desc{_, _, _, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_layout_of_val{_, _, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_layout_val{_, _, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_layout_unresolved{_, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_layout_family{_, _, _, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_layout_native{_, _, _, _, _, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_field_scope{_}: List<&2, cps_provider_7_NfVal>
    case EmitterRequest_cps_provider_3_arm_layouts{_, _, _, _, _}: cps_provider_3_Plans
    case EmitterRequest_cps_provider_3_field_layouts{_, _, _, _, _}: cps_provider_3_Layouts
    case EmitterRequest_cps_provider_3_layout_data{_, _, _, _, _}: cps_provider_3_LayoutResult
    case EmitterRequest_cps_provider_3_arms_tagged{_}: Bool
    case EmitterRequest_cps_provider_3_reenters{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_3_fields_reach{_, _, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_3_reaches{_, _, _, _, _, _}: Bool

def emitter_result_group_15(request: EmitterRequestGroup15) -> Type:
  match request:
    case EmitterRequest_cps_provider_3_reaches_val{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_3_family_reach{_, _, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_3_reach_arms{_, _, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_3_args_reach{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_3_str_member{_, _}: Bool
    case EmitterRequest_cps_provider_3_layout_kinds{_}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_layout_words{_}: Nat
    case EmitterRequest_cps_provider_3_canonical_word{_}: cps_provider_3_CWord
    case EmitterRequest_cps_provider_3_pack_arms{_, _}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_pack_arm_list{_, _, _}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_pack_field_list{_, _, _}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_pack_kinds{_, _, _}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_set_kind{_, _, _}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_merge_kind{_, _}: cps_provider_3_CWord
    case EmitterRequest_cps_provider_3_word_32{_}: Bool
    case EmitterRequest_cps_provider_3_pad_words{_}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_pad_to{_, _}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_pow2_upto{_, _}: Nat
    case EmitterRequest_cps_provider_3_ceil_log2{_}: Nat
    case EmitterRequest_cps_provider_3_ceil_log2_go{_, _, _}: Nat
    case EmitterRequest_cps_provider_3_node_layout{_, _}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_node_layout_fuel{_, _, _}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_node_at{_, _, _}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_plan_node{_, _}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_node_compute{_, _, _}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_unresolved_message{_}: String
    case EmitterRequest_cps_provider_3_node_arm{_, _, _}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_plan_node_index{_, _}: Map<&2, cps_provider_3_NodeResult>
    case EmitterRequest_cps_provider_3_node_declared{_, _}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_node_slots{_, _, _, _, _, _}: cps_provider_3_Slots
    case EmitterRequest_cps_provider_3_node_finish{_}: cps_provider_3_NodeResult
    case EmitterRequest_cps_provider_3_slot_words{_}: List<&2, cps_provider_3_CWord>
    case EmitterRequest_cps_provider_3_packed_words{_}: Bool
    case EmitterRequest_cps_provider_3_node_slot{_, _, _}: cps_provider_3_SlotResult
    case EmitterRequest_cps_provider_3_slot_find{_, _}: Maybe<&2, cps_provider_3_NodeSlot>
    case EmitterRequest_cps_provider_3_layout_fill{_, _}: cps_provider_3_FillResult
    case EmitterRequest_cps_provider_3_layout_fill_fuel{_, _, _}: cps_provider_3_FillResult
    case EmitterRequest_cps_provider_3_layout_unfill{_, _}: cps_provider_3_UnfillResult
    case EmitterRequest_cps_provider_3_layout_unfill_fuel{_, _, _}: cps_provider_3_UnfillResult
    case EmitterRequest_cps_provider_3_slot_fill{_, _, _}: cps_provider_3_FillResult
    case EmitterRequest_cps_provider_3_slot_unfill{_, _, _}: cps_provider_3_UnfillResult
    case EmitterRequest_cps_provider_3_form_arms{_, _, _, _, _, _, _, _}: cps_provider_3_Arms
    case EmitterRequest_cps_provider_3_form_arm{_, _, _, _, _, _, _, _}: cps_provider_3_FormArmResult
    case EmitterRequest_cps_provider_3_tag_word{_}: Nat
    case EmitterRequest_cps_provider_3_form_nests{_, _, _, _, _, _, _, _, _}: cps_provider_3_Nests
    case EmitterRequest_cps_provider_3_nest{_, _, _, _}: cps_provider_3_Nest
    case EmitterRequest_cps_provider_3_nest_fits{_, _, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_3_fill_words{_}: Nat
    case EmitterRequest_cps_provider_3_unfill_words{_}: Nat
    case EmitterRequest_cps_provider_3_head_native{_, _}: cps_provider_3_HeadResult
    case EmitterRequest_cps_provider_3_head_other{_}: cps_provider_3_HeadResult
    case EmitterRequest_cps_provider_3_head_value{_, _}: cps_provider_3_HeadResult
    case EmitterRequest_cps_provider_3_norm{_, _}: cps_provider_3_NormResult
    case EmitterRequest_cps_provider_3_head_args{_, _}: cps_provider_3_ArgsResult
    case EmitterRequest_cps_provider_3_arm_fields{_, _, _}: cps_provider_3_FieldsResult
    case EmitterRequest_cps_provider_3_arm_fields_value{_, _, _}: cps_provider_3_FieldsResult
    case EmitterRequest_cps_provider_3_instantiate_fields{_, _, _, _}: cps_provider_3_FieldsResult
    case EmitterRequest_cps_provider_3_array_cell{_, _}: cps_provider_3_CellResult
    case EmitterRequest_cps_provider_3_cell_of{_}: cps_provider_3_CellResult
    case EmitterRequest_cps_provider_3_cell_boxed{_}: cps_provider_3_CellResult
    case EmitterRequest_cps_provider_3_max_one{_}: Nat
    case EmitterRequest_cps_provider_3_layout_has_term{_}: Bool
    case EmitterRequest_cps_provider_3_word_has_term{_}: Bool
    case EmitterRequest_cps_provider_3_any_word_has_term{_}: Bool

def emitter_result_group_16(request: EmitterRequestGroup16) -> Type:
  match request:
    case EmitterRequest_cps_provider_4_chars_rev{_, _}: List<&2, Char>
    case EmitterRequest_cps_provider_4_text_of_rev{_, _}: String
    case EmitterRequest_cps_provider_4_text_prepend{_, _}: String
    case EmitterRequest_cps_provider_4_pieces_fold{_, _}: String
    case EmitterRequest_cps_provider_4_pieces_from_end{_}: String
    case EmitterRequest_cps_provider_4_text_of_pieces{_}: String
    case EmitterRequest_cps_provider_4_chars_forward{_}: List<&2, Char>
    case EmitterRequest_cps_provider_4_fragments{_}: cps_provider_4_Fragment
    case EmitterRequest_cps_provider_4_fragment_leaves{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_4_fragment_text{_}: String
    case EmitterRequest_cps_provider_4_fragment_chars{_, _}: List<&2, Char>
    case EmitterRequest_cps_provider_4_fragment_match{_, _, _}: Bool
    case EmitterRequest_cps_provider_4_fragment_match_leaf{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_4_fragment_eq{_, _}: Bool
    case EmitterRequest_cps_provider_4_fragment_starts_with{_, _}: Bool
    case EmitterRequest_cps_provider_4_utf8_bytes_deep_of{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_4_utf8_bytes_deep{_}: List<&2, U32>
    case EmitterRequest_cps_provider_4_utf8_bytes_wide_of{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_4_utf8_bytes_wide{_}: List<&2, U32>
    case EmitterRequest_cps_provider_4_utf8_bytes_of{_, _}: List<&2, U32>
    case EmitterRequest_cps_provider_4_utf8_bytes{_}: List<&2, U32>
    case EmitterRequest_cps_provider_4_oct3{_}: String
    case EmitterRequest_cps_provider_4_octals{_, _}: String
    case EmitterRequest_cps_provider_4_utf8_width_wide{_}: Nat
    case EmitterRequest_cps_provider_4_utf8_width_two{_, _}: Nat
    case EmitterRequest_cps_provider_4_utf8_width_of{_, _}: Nat
    case EmitterRequest_cps_provider_4_utf8_width{_}: Nat
    case EmitterRequest_cps_provider_4_utf8_len_go{_, _}: Nat
    case EmitterRequest_cps_provider_4_utf8_byte_len{_}: Nat
    case EmitterRequest_cps_provider_4_literal_high{_}: String
    case EmitterRequest_cps_provider_4_literal_wide_of{_, _, _}: String
    case EmitterRequest_cps_provider_4_literal_wide{_, _}: String
    case EmitterRequest_cps_provider_4_literal_plain_of{_, _}: String
    case EmitterRequest_cps_provider_4_literal_plain{_}: String
    case EmitterRequest_cps_provider_4_literal_piece{_}: String
    case EmitterRequest_cps_provider_4_literal_pieces{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_4_c_string_literal{_}: String
    case EmitterRequest_cps_provider_4_text_hex_digit{_}: String
    case EmitterRequest_cps_provider_4_text_hex_nibble{_, _}: String
    case EmitterRequest_cps_provider_4_text_hex_word{_}: String
    case EmitterRequest_cps_provider_4_text_plain_wide{_}: Bool
    case EmitterRequest_cps_provider_4_text_plain_char{_}: Bool
    case EmitterRequest_cps_provider_4_text_piece_of{_, _}: String
    case EmitterRequest_cps_provider_4_text_piece{_}: String
    case EmitterRequest_cps_provider_4_text_pieces{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_4_c_text_literal{_}: String
    case EmitterRequest_cps_provider_4_text_piece_bytes_of{_}: Nat
    case EmitterRequest_cps_provider_4_text_piece_bytes{_}: Nat
    case EmitterRequest_cps_provider_4_text_len_go{_, _}: Nat
    case EmitterRequest_cps_provider_4_text_byte_len{_}: Nat
    case EmitterRequest_cps_provider_4_link_complete{_, _}: cps_provider_4_LinkResult
    case EmitterRequest_cps_provider_4_link_result{_}: cps_provider_4_LinkResult
    case EmitterRequest_cps_provider_4_is_word{_}: Bool
    case EmitterRequest_cps_provider_4_is_key_char{_}: Bool
    case EmitterRequest_cps_provider_4_text_closes{_, _, _}: Bool
    case EmitterRequest_cps_provider_4_block_closes{_}: Bool
    case EmitterRequest_cps_provider_4_code_entry_slash{_}: cps_provider_4_Mode
    case EmitterRequest_cps_provider_4_code_entry{_, _}: cps_provider_4_Mode
    case EmitterRequest_cps_provider_4_emit_chars{_, _}: List<&2, Char>
    case EmitterRequest_cps_provider_4_resolved_text{_}: String
    case EmitterRequest_cps_provider_4_first_problem{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_4_prefix_named{_}: String
    case EmitterRequest_cps_provider_4_prefix_text{_}: String
    case EmitterRequest_cps_provider_4_missing_id{_, _}: String

def emitter_result_group_17(request: EmitterRequestGroup17) -> Type:
  match request:
    case EmitterRequest_cps_provider_4_next_failure{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_4_lookup_named{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_4_lookup_id{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_4_flush_key{_, _, _, _}: List<&2, Char>
    case EmitterRequest_cps_provider_4_flush_open{_, _, _}: List<&2, Char>
    case EmitterRequest_cps_provider_4_flush_empty{_, _}: List<&2, Char>
    case EmitterRequest_cps_provider_4_key_text{_}: String
    case EmitterRequest_cps_provider_4_scan{_, _, _, _, _, _, _}: cps_provider_4_Scan
    case EmitterRequest_cps_provider_4_rewrite{_, _, _}: cps_provider_4_LinkResult
    case EmitterRequest_cps_provider_4_rewrite_fragment{_, _, _}: cps_provider_4_LinkResult
    case EmitterRequest_cps_provider_5_world{_, _, _}: cps_provider_5_World
    case EmitterRequest_cps_provider_5_join_text{_}: String
    case EmitterRequest_cps_provider_5_code_line{_}: cps_provider_5_Code
    case EmitterRequest_cps_provider_5_code_empty{}: cps_provider_5_Code
    case EmitterRequest_cps_provider_5_code_seq{_, _}: cps_provider_5_Code
    case EmitterRequest_cps_provider_5_code_text{_, _}: String
    case EmitterRequest_cps_provider_5_part_of{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_ctor_find{_, _}: Maybe<&2, BIR.ConstructorLayout>
    case EmitterRequest_cps_provider_5_ctor_of{_, _}: Maybe<&2, BIR.ConstructorLayout>
    case EmitterRequest_cps_provider_5_cid_find{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_5_cid_of{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_5_cid_text_of{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_5_cid_text{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_5_intrinsic_marker{_}: Bool
    case EmitterRequest_cps_provider_5_dst_write{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_dst_word{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_dst_decl{_, _, _}: String
    case EmitterRequest_cps_provider_5_dst_mark{_, _}: String
    case EmitterRequest_cps_provider_5_form_base{_, _}: Nat
    case EmitterRequest_cps_provider_5_form_pad{_, _}: Nat
    case EmitterRequest_cps_provider_5_nests_take_words{_}: Nat
    case EmitterRequest_cps_provider_5_nests_make_words{_}: Nat
    case EmitterRequest_cps_provider_5_src_skip_jobs{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_dst_skip_jobs{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_src_read_node{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_src_read_arr{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_src_read_block{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_src_read{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_form_tagged{_}: Bool
    case EmitterRequest_cps_provider_5_max_node_words{_, _}: Nat
    case EmitterRequest_cps_provider_5_max_term_decl{_, _}: String
    case EmitterRequest_cps_provider_5_arm_seed{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_arm_seed_words{_, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_arm_src{_, _, _, _, _}: cps_provider_5_Src
    case EmitterRequest_cps_provider_5_nests_jobs{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_arm_release{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_jobs_arm_body{_, _, _, _, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_jobs_arm{_, _, _, _, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_arm_jobs{_, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_unbox_cases{_, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_expand_unbox{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_expand_word_take{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_nest_take{_}: cps_provider_3_Unfill
    case EmitterRequest_cps_provider_5_nest_make{_}: cps_provider_3_Fill
    case EmitterRequest_cps_provider_5_field_pair_jobs{_, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_forms_arm_body{_, _, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_forms_arm_case{_, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_form_arm_by_key{_, _}: Maybe<&2, cps_provider_3_FormArm>
    case EmitterRequest_cps_provider_5_forms_cases{_, _, _, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_expand_forms{_, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_forms_single{_, _, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_pack_jobs{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_arm_block_jobs{_, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_box_arm_jobs{_, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>

def emitter_result_group_18(request: EmitterRequestGroup18) -> Type:
  match request:
    case EmitterRequest_cps_provider_5_box_cases{_, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_box_untagged{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_expand_box{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_expand_box_body{_, _, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_expand_form_take{_, _, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_expand_conv{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_run_jobs{_, _, _}: cps_provider_5_Code
    case EmitterRequest_cps_provider_5_fill_plan_jobs{_, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_fill_result_jobs{_, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_fill_data_jobs{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_fill_jobs{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_unfill_result_jobs{_, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_unfill_data_jobs{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_unfill_word_jobs{_, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_unfill_jobs{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_operand_code{_, _, _, _}: cps_provider_5_Code
    case EmitterRequest_cps_provider_5_operand_name{_, _, _, _}: String
    case EmitterRequest_cps_provider_5_text_jobs{_}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_code_jobs{_}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_fill_slots_jobs{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_layout_is_data{_}: Bool
    case EmitterRequest_cps_provider_5_seal_box_many{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_seal_box{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_seal_kind{_, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_seal_kind_walk{_, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_seal_slots_jobs{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_one_job{_}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_construct_words{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_codeSeqPack{_, _, _, _, _}: cps_provider_5_Code
    case EmitterRequest_cps_provider_5_construct_packed_one{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_packed{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_packed_flag{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_count{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_node{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_layout{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_cid{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_generic{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_marker{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_native{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_row{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_construct_part{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_term_decl_text{_}: String
    case EmitterRequest_cps_provider_5_project_prelude{_, _, _, _}: String
    case EmitterRequest_cps_provider_5_project_words{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_packed_prelude{_, _}: String
    case EmitterRequest_cps_provider_5_project_packed{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_packed_flag{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_unique_expr{_}: String
    case EmitterRequest_cps_provider_5_static_expr{_}: String
    case EmitterRequest_cps_provider_5_and_expr{_, _}: String
    case EmitterRequest_cps_provider_5_or_expr{_, _}: String
    case EmitterRequest_cps_provider_5_nat_if{_, _, _}: Nat
    case EmitterRequest_cps_provider_5_live_ordinal{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_5_live_walk{_, _, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_5_live_next{_, _}: Nat
    case EmitterRequest_cps_provider_5_arm_fields_of{_, _}: Maybe<&2, List<&2, cps_provider_3_Layout>>
    case EmitterRequest_cps_provider_5_arm_fields_declared{_}: Maybe<&2, List<&2, BIR.DescriptorField>>
    case EmitterRequest_cps_provider_5_arm_descriptor_fields{_, _}: Maybe<&2, List<&2, BIR.DescriptorField>>
    case EmitterRequest_cps_provider_5_step_key{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_5_cell_lgs{_, _}: Maybe<&2, cps_provider_3_Cell>
    case EmitterRequest_cps_provider_5_not_bool{_}: Bool
    case EmitterRequest_cps_provider_5_live_ordinal_in{_, _, _, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_5_inline_slot{_, _, _}: Maybe<&2, cps_provider_3_NodeSlot>
    case EmitterRequest_cps_provider_5_inline_start{_}: Nat

def emitter_result_group_19(request: EmitterRequestGroup19) -> Type:
  match request:
    case EmitterRequest_cps_provider_5_state_array{_, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_state_from_array_value{_, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_resolve_field{_, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_resolve_slot_field{_, _, _, _, _, _, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_resolve_cell_field{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_resolve_buf_field{_, _, _, _, _, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_resolve_node_slot{_, _, _, _, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_root_array_path{_, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_advance{_, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_array_from_state{_, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_half_state{_, _, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_leaf_state{_, _, _, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_resolve_path{_, _}: cps_provider_5_PathResult
    case EmitterRequest_cps_provider_5_path_prelude{_}: String
    case EmitterRequest_cps_provider_5_path_expr{_, _}: String
    case EmitterRequest_cps_provider_5_keep_copy{_, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_keep_copy_fields{_, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_keep_copy_cases{_, _, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_move_copy{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_move_copy_fields{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_move_copy_cases{_, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_raw_word_expr{_, _, _}: String
    case EmitterRequest_cps_provider_5_packed_form_body{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_read_body{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tag_single{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tag_multi{_, _, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tag_case_line{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_tag_multi_packed{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tag_multi_packed_go{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tag_multi_buf{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tag_multi_buf_go{_, _, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tag_body{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_copy_slot_body{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_packed_data_value{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_packed_data_copy{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_box_copy_body{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_data_copy_body{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_zero_value_body{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_buf_clear_words{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_buf_field_body{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_buf_move_clear{_, _, _, _}: String
    case EmitterRequest_cps_provider_5_cell_arr_body{_, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_cell_move_clear{_, _, _, _}: String
    case EmitterRequest_cps_provider_5_cell_data_body{_, _, _, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_buf_clear_span{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_copy_cell_body{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_copy_padding{_, _, _}: String
    case EmitterRequest_cps_provider_5_array_inner{_, _, _, _}: String
    case EmitterRequest_cps_provider_5_array_copy_body{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_pow2{_}: Nat
    case EmitterRequest_cps_provider_5_move_cell_body{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_move_slot_body{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_data_move_body{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_state_stat{_}: String
    case EmitterRequest_cps_provider_5_state_uniq{_}: String
    case EmitterRequest_cps_provider_5_path_body_copy{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_path_body_move{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_path_read{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_runtime_cid_of_ctor{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_5_canonical_bool{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_path_hastag{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_path_copy{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_path_consume{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_path_is_leaf{_, _, _}: cps_provider_5_Part

def emitter_result_group_20(request: EmitterRequestGroup20) -> Type:
  match request:
    case EmitterRequest_cps_provider_5_path_is_node{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_plan{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_slot{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_layout{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_node{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_marker{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_native{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_row{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_project_part{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_hastag_bools{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_hastag_cid{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_hastag_row{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_hastag_part{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_arr_flag{_}: String
    case EmitterRequest_cps_provider_5_array_label{_}: String
    case EmitterRequest_cps_provider_5_descriptor_missing{_}: String
    case EmitterRequest_cps_provider_5_array_cell_result{_}: cps_provider_5_CellOut
    case EmitterRequest_cps_provider_5_array_cell{_, _, _}: cps_provider_5_CellOut
    case EmitterRequest_cps_provider_5_operand_at{_, _}: Maybe<&2, cps_provider_5_Operand>
    case EmitterRequest_cps_provider_5_operand_text{_}: String
    case EmitterRequest_cps_provider_5_operand_use{_}: BIR.Use
    case EmitterRequest_cps_provider_5_keep_text{_}: String
    case EmitterRequest_cps_provider_5_tuple_cid{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tuple_part{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_seal_cell_box{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_seal_cell_kind{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_seal_cell_walk{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_elem_fill_operand{_, _, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_elem_fill{_, _, _, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_elem_stores{_}: String
    case EmitterRequest_cps_provider_5_elem_decl{_}: String
    case EmitterRequest_cps_provider_5_run_part{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_new_ops{_, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_tuple_and_code{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_get_ops{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_old_read_cell{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_kinds_box_jobs{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_old_sink_jobs{_, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_write_jobs{_, _, _}: List<&2, cps_provider_5_Job>
    case EmitterRequest_cps_provider_5_array_set_run{_, _, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_set_ops{_, _, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_swap_run{_, _, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_swap_ops{_, _, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_size_ops{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_clone_ops{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_cell_text{_, _}: String
    case EmitterRequest_cps_provider_5_atomic_call_text{_, _, _, _}: String
    case EmitterRequest_cps_provider_5_atomic_cas_text{_, _, _, _}: String
    case EmitterRequest_cps_provider_5_atomic_helper{_}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_pair{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_three_operands{_, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_three_pargs{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_cas_pargs{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_pargs{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_three_regs{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_cas_regs{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_atomic_prim_part{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_leaf_ops{_, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_node_ops{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_is_cond{_, _}: String
    case EmitterRequest_cps_provider_5_array_is_bools{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_is_ops{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_new_cell{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_get_cell{_, _, _}: cps_provider_5_Part

def emitter_result_group_21(request: EmitterRequestGroup21) -> Type:
  match request:
    case EmitterRequest_cps_provider_5_array_set_cell{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_swap_cell{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_size_cell{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_clone_cell{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_leaf_cell{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_part{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_array_cell_part{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_is_atomic_primitive{_}: Bool
    case EmitterRequest_cps_provider_5_is_array_primitive{_}: Bool
    case EmitterRequest_cps_provider_5_map_offsets{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_map_offsets_walk{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_map_find_missing{_}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_map_find_text{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_map_find_build{_, _, _, _, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_map_find_expr{_, _, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_5_map_find_operands{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_map_find_names{_, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_map_find_part{_, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_descriptor_part{_, _, _, _}: cps_provider_5_Part
    case EmitterRequest_cps_provider_5_show_state0{}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_words{_}: List<&2, cps_provider_5_ShowWord>
    case EmitterRequest_cps_provider_5_show_patches{_}: List<&2, cps_provider_5_ShowPatch>
    case EmitterRequest_cps_provider_5_show_memo{_}: Map<&2, Nat>
    case EmitterRequest_cps_provider_5_show_names{_}: List<&2, String>
    case EmitterRequest_cps_provider_5_show_error{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_5_show_state_set_memo{_, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_state_error{_, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_next_state{_}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_next_kids{_}: List<&2, cps_provider_5_ShowJob>
    case EmitterRequest_cps_provider_5_show_append_word{_, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_append_num{_, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_append_cid{_, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_append_name{_, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_append_patch{_, _, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_apply_patch{_, _, _}: cps_provider_5_ShowState
    case EmitterRequest_cps_provider_5_show_native_kind{_}: cps_provider_5_ShowKind
    case EmitterRequest_cps_provider_5_show_kind_family{_, _}: cps_provider_5_ShowKind
    case EmitterRequest_cps_provider_5_show_kind_head{_, _}: cps_provider_5_ShowKind
    case EmitterRequest_cps_provider_5_show_kind{_, _}: cps_provider_5_ShowKind
    case EmitterRequest_cps_provider_5_show_box_flag{_}: Nat
    case EmitterRequest_cps_provider_5_show_tag_plain{_}: Nat
    case EmitterRequest_cps_provider_5_show_tag_start{_, _}: Nat
    case EmitterRequest_cps_provider_5_show_quote{_}: String
    case EmitterRequest_cps_provider_5_show_name_sep{_}: String
    case EmitterRequest_cps_provider_5_show_render_names{_}: String
    case EmitterRequest_cps_provider_5_show_render_sep_flag{_}: String
    case EmitterRequest_cps_provider_5_show_render_sep{_}: String
    case EmitterRequest_cps_provider_5_show_render_word{_}: String
    case EmitterRequest_cps_provider_5_show_render_words{_, _}: String
    case EmitterRequest_cps_provider_5_family_arms{_, _}: Maybe<&2, List<&2, BIR.DescriptorArm>>
    case EmitterRequest_cps_provider_5_ctor_find_key{_, _}: Maybe<&2, BIR.ConstructorLayout>
    case EmitterRequest_cps_provider_5_show_cid_found{_}: Maybe<&2, Nat>
    case EmitterRequest_cps_provider_5_show_cid_of_key{_, _}: Maybe<&2, Nat>
    case EmitterRequest_cps_provider_5_show_arm_bracket_name{_}: Nat
    case EmitterRequest_cps_provider_5_show_arm_bracket{_}: Nat
    case EmitterRequest_cps_provider_5_show_erased_present{_}: Bool
    case EmitterRequest_cps_provider_5_show_field_at_each{_, _, _}: Maybe<&2, BIR.DescriptorField>
    case EmitterRequest_cps_provider_5_show_field_at{_, _}: Maybe<&2, BIR.DescriptorField>
    case EmitterRequest_cps_provider_5_show_arm_layouts_each{_, _}: Maybe<&2, List<&2, cps_provider_3_Layout>>
    case EmitterRequest_cps_provider_5_show_arm_layouts{_, _}: Maybe<&2, List<&2, cps_provider_3_Layout>>
    case EmitterRequest_cps_provider_5_show_node_layout_slots{_}: Maybe<&2, List<&2, cps_provider_3_NodeSlot>>
    case EmitterRequest_cps_provider_5_show_word_key{_}: String
    case EmitterRequest_cps_provider_5_show_box_key{_}: String
    case EmitterRequest_cps_provider_5_lk_text{_}: String

def emitter_result_group_22(request: EmitterRequestGroup22) -> Type:
  match request:
    case EmitterRequest_cps_provider_5_lk_words{_}: String
    case EmitterRequest_cps_provider_5_lk_fields{_}: String
    case EmitterRequest_cps_provider_5_lk_arms{_}: String
    case EmitterRequest_cps_provider_5_show_layout_key{_}: String
    case EmitterRequest_cps_provider_5_show_arg_tokens{_, _}: List<&2, cps_provider_5_ShowToken>
    case EmitterRequest_cps_provider_5_show_quantity_key{_}: String
    case EmitterRequest_cps_provider_5_show_maybe_quantity_key{_}: String
    case EmitterRequest_cps_provider_5_show_pat_tokens{_, _}: List<&2, cps_provider_5_ShowToken>
    case EmitterRequest_cps_provider_5_show_pat_expand{_}: List<&2, cps_provider_5_ShowToken>
    case EmitterRequest_cps_provider_5_show_desc_expand{_}: List<&2, cps_provider_5_ShowToken>
    case EmitterRequest_cps_provider_5_show_render_tokens{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_5_show_descriptor_key{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_5_show_array_cell{_, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_array_element{_, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_array_args{_, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_array{_, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_box_advance{_, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_fields_box_each{_, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_fields_box_slots{_, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_fields_box{_, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_fields_inline_each{_, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_fields_inline_layouts{_, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_fields_inline{_, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_fields_advance{_, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arm_header{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arm_rest{_, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arm_cid{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arm_erased{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arm_live{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arm{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arms{_, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_count{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_arms_maybe{_, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_key{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_data_head{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_data{_, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_n{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_kind{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_memo{_, _, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_norm{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_key{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_norm_result{_}: cps_provider_5_ShowNorm
    case EmitterRequest_cps_provider_5_show_norm{_, _}: cps_provider_5_ShowNorm
    case EmitterRequest_cps_provider_5_show_advance_error{_, _, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_st{_, _, _, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_show_advance_job{_, _, _, _, _}: cps_provider_5_ShowAdvance
    case EmitterRequest_cps_provider_5_run_show{_, _, _, _, _}: cps_provider_5_ShowRun
    case EmitterRequest_cps_provider_5_show_set_word{_, _, _, _}: List<&2, cps_provider_5_ShowWord>
    case EmitterRequest_cps_provider_5_show_apply_patches{_, _}: List<&2, cps_provider_5_ShowWord>
    case EmitterRequest_cps_provider_5_show_finish{_, _}: cps_provider_5_ShowOut
    case EmitterRequest_cps_provider_5_show_result{_}: cps_provider_5_ShowOut
    case EmitterRequest_cps_provider_5_show_root_layout{_}: cps_provider_3_Layout
    case EmitterRequest_cps_provider_5_show_root{_, _, _, _, _}: cps_provider_5_ShowOut
    case EmitterRequest_cps_provider_5_show_build{_, _, _, _}: cps_provider_5_ShowOut
    case EmitterRequest_cps_provider_6_no_span{}: Ast.SourceSpan
    case EmitterRequest_cps_provider_6_foreign_c_source{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_6_plan_prepend{_, _}: cps_provider_6_PlanResult
    case EmitterRequest_cps_provider_6_plan_add{_, _, _, _}: cps_provider_6_PlanResult
    case EmitterRequest_cps_provider_6_plan_declaration{_, _}: cps_provider_6_PlanResult
    case EmitterRequest_cps_provider_6_plan_declarations{_, _}: cps_provider_6_PlanResult
    case EmitterRequest_cps_provider_6_find_source{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_6_join_imports{_, _, _}: cps_provider_6_JoinResult
    case EmitterRequest_cps_provider_6_render{_, _, _}: cps_provider_6_EmitResult
    case EmitterRequest_cps_provider_6_emit{_, _, _}: cps_provider_6_EmitResult

def emitter_result_group_23(request: EmitterRequestGroup23) -> Type:
  match request:
    case EmitterRequest_cps_provider_6_emit_library{_, _, _, _}: cps_provider_6_EmitResult
    case EmitterRequest_cps_provider_7_family_index{_}: Map<&2, BIR.Family>
    case EmitterRequest_cps_provider_7_function_index{_}: Map<&2, BIR.TypeFunction>
    case EmitterRequest_cps_provider_7_nf_context{_, _}: cps_provider_7_NfContext
    case EmitterRequest_cps_provider_7_default_fuel{}: Nat
    case EmitterRequest_cps_provider_7_family_of{_, _}: Maybe<&2, BIR.Family>
    case EmitterRequest_cps_provider_7_function_of{_, _}: Maybe<&2, BIR.TypeFunction>
    case EmitterRequest_cps_provider_7_native_of{_, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_7_val_nth{_, _}: cps_provider_7_NfVal
    case EmitterRequest_cps_provider_7_val_at{_, _, _}: cps_provider_7_NfVal
    case EmitterRequest_cps_provider_7_val_at_choose{_, _, _, _}: cps_provider_7_NfVal
    case EmitterRequest_cps_provider_7_first_vals{_, _}: List<&2, cps_provider_7_NfVal>
    case EmitterRequest_cps_provider_7_drop_vals{_, _}: List<&2, cps_provider_7_NfVal>
    case EmitterRequest_cps_provider_7_insert_before{_, _, _}: List<&2, cps_provider_7_NfVal>
    case EmitterRequest_cps_provider_7_append_vals{_, _}: List<&2, cps_provider_7_NfVal>
    case EmitterRequest_cps_provider_7_quantity_markers{_}: List<&2, cps_provider_7_NfVal>
    case EmitterRequest_cps_provider_7_renamed_level{_, _}: Nat
    case EmitterRequest_cps_provider_7_materialize_all_scoped{_, _, _}: List<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_7_materialize_all_at{_, _}: List<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_7_materialize_all{_}: List<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_7_materialize_scoped{_, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_materialize_at{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_materialize{_}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_reify_env{_, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_status_combine{_, _}: cps_provider_7_NfStatus
    case EmitterRequest_cps_provider_7_bind_status{_, _}: cps_provider_7_NfStatus
    case EmitterRequest_cps_provider_7_bind_values{_, _}: List<&2, cps_provider_7_NfVal>
    case EmitterRequest_cps_provider_7_bind_patterns{_, _}: cps_provider_7_NfBind
    case EmitterRequest_cps_provider_7_nf{_, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_descriptor{_, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_arrow{_, _, _, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_descriptor_step{_, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_all{_, _, _, _, _}: cps_provider_7_NfList
    case EmitterRequest_cps_provider_7_nf_apply_args{_, _, _, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_apply_source{_, _, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_apply{_, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_apply_one{_, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_intrinsic_io{_}: Bool
    case EmitterRequest_cps_provider_7_nf_named_io{_, _, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_named{_, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_arity{_, _, _}: cps_provider_7_NfArity
    case EmitterRequest_cps_provider_7_nf_family{_, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_family_apply{_, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_reduce{_, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_reduce_apply{_, _, _, _, _, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_reduce_body{_, _, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_nf_cases{_, _, _, _, _, _, _}: cps_provider_7_Nf
    case EmitterRequest_cps_provider_7_normalize{_, _, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_normalize_closed{_, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_normalize_in{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_outer_application{_}: Maybe<&2, cps_provider_7_NfApp>
    case EmitterRequest_cps_provider_7_outer_walk{_, _}: Maybe<&2, cps_provider_7_NfApp>
    case EmitterRequest_cps_provider_7_answer_in{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_answer_descriptor{_, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_answer_normalized{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_7_is_io_head_in{_, _}: Bool
    case EmitterRequest_cps_provider_7_is_io_head{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_source{_}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_js_source_ext{_, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_link_add{_, _, _, _}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_link_add_known{_, _, _, _, _, _, _, _, _}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_link_add_namespace{_, _, _, _}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_link_add_tail{_, _}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_link_declarations{_, _}: cps_provider_8_LinkResult

def emitter_result_group_24(request: EmitterRequestGroup24) -> Type:
  match request:
    case EmitterRequest_cps_provider_8_link_declaration_source{_, _, _, _, _, _}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_link_declaration_plan{_, _}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_constructors_named{_, _}: Bool
    case EmitterRequest_cps_provider_8_constructors_named_same{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_foreign_name_check{_, _}: Maybe<&2, cps_provider_8_LinkResult>
    case EmitterRequest_cps_provider_8_foreign_name_check_named{_, _, _, _, _}: Maybe<&2, cps_provider_8_LinkResult>
    case EmitterRequest_cps_provider_8_link_checked{_, _}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_link{_}: cps_provider_8_LinkResult
    case EmitterRequest_cps_provider_8_js_key_candidate{_, _}: String
    case EmitterRequest_cps_provider_8_js_key_join{_, _, _}: String
    case EmitterRequest_cps_provider_8_js_key_member{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_key_member_found{_}: Bool
    case EmitterRequest_cps_provider_8_js_key_resolve{_, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_js_key_resolve_qualified{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_js_key_resolve_bare{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_js_key_declaration{_, _}: Map<&2, Bool>
    case EmitterRequest_cps_provider_8_js_key_declarations{_, _}: Map<&2, Bool>
    case EmitterRequest_cps_provider_8_js_key_layouts{_, _}: Map<&2, Bool>
    case EmitterRequest_cps_provider_8_js_key_families{_, _}: Map<&2, Bool>
    case EmitterRequest_cps_provider_8_js_key_functions{_, _}: Map<&2, Bool>
    case EmitterRequest_cps_provider_8_js_native_families{_, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_js_native_family{_, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_js_native_functions{_, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_js_native_function{_, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_js_native_markers{_}: Map<&2, String>
    case EmitterRequest_cps_provider_8_js_known_keys{_}: Map<&2, Bool>
    case EmitterRequest_cps_provider_8_js_cid{_}: cps_provider_8_JSCidResult
    case EmitterRequest_cps_provider_8_js_word{_}: Bool
    case EmitterRequest_cps_provider_8_js_key_char{_}: Bool
    case EmitterRequest_cps_provider_8_js_text_closes{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_text_closes_escape{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_text_closes_step{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_text_closes_newline{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_block_closes{_}: Bool
    case EmitterRequest_cps_provider_8_js_block_closes_star{_}: Bool
    case EmitterRequest_cps_provider_8_js_emit_chars{_, _}: List<&2, Char>
    case EmitterRequest_cps_provider_8_js_scan{_, _, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_mode{_, _, _, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_code{_, _, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_slash{_, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_cid{_, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_cid_prefix{_, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_cid_key{_, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_cid_found{_, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_cid_resolved{_, _, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_collect_key{_, _}: cps_provider_8_JSKeyScan
    case EmitterRequest_cps_provider_8_js_collect_key_close{_, _}: cps_provider_8_JSKeyScan
    case EmitterRequest_cps_provider_8_js_collect_key_more{_, _, _, _}: cps_provider_8_JSKeyScan
    case EmitterRequest_cps_provider_8_js_scan_line{_, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_line_more{_, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_block{_, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_block_more{_, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_text{_, _, _, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_text_plain{_, _, _, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_scan_text_more{_, _, _, _, _}: cps_provider_8_JSScan
    case EmitterRequest_cps_provider_8_js_source_text{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_js_source_text_same{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_js_effect_chunk{_}: String
    case EmitterRequest_cps_provider_8_js_effect_sources{_, _, _, _}: cps_provider_8_JSEffects
    case EmitterRequest_cps_provider_8_js_effect_text{_, _, _, _, _, _, _, _}: cps_provider_8_JSEffects
    case EmitterRequest_cps_provider_8_js_effect_scan{_, _, _, _, _, _, _}: cps_provider_8_JSEffects
    case EmitterRequest_cps_provider_8_cat{_}: String
    case EmitterRequest_cps_provider_8_js_escape_char{_}: String
    case EmitterRequest_cps_provider_8_js_escape_other{_, _}: String

def emitter_result_group_25(request: EmitterRequestGroup25) -> Type:
  match request:
    case EmitterRequest_cps_provider_8_js_escape_packed{_, _, _}: String
    case EmitterRequest_cps_provider_8_js_char_packed{_}: Bool
    case EmitterRequest_cps_provider_8_js_hex_escape{_}: String
    case EmitterRequest_cps_provider_8_js_hex_digit{_}: String
    case EmitterRequest_cps_provider_8_js_quote_chars{_}: String
    case EmitterRequest_cps_provider_8_js_quote_plain{_}: Bool
    case EmitterRequest_cps_provider_8_js_quote_plain_next{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_quote_plain_char{_}: Bool
    case EmitterRequest_cps_provider_8_js_quote_ready{_, _}: String
    case EmitterRequest_cps_provider_8_js_quote{_}: String
    case EmitterRequest_cps_provider_8_bool_source{_}: String
    case EmitterRequest_cps_provider_8_optional_text{_}: String
    case EmitterRequest_cps_provider_8_local{_}: String
    case EmitterRequest_cps_provider_8_capture{_}: String
    case EmitterRequest_cps_provider_8_code_name{_}: String
    case EmitterRequest_cps_provider_8_atom{_}: String
    case EmitterRequest_cps_provider_8_arguments{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_parameter_names{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_capture_names{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_captured_names{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_call{_, _}: String
    case EmitterRequest_cps_provider_8_tail_call{_, _}: String
    case EmitterRequest_cps_provider_8_tail_call_selected{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_tail_call_named{_, _, _}: String
    case EmitterRequest_cps_provider_8_public_closure{_, _}: String
    case EmitterRequest_cps_provider_8_closure{_, _, _}: String
    case EmitterRequest_cps_provider_8_closure_captures{_, _, _}: String
    case EmitterRequest_cps_provider_8_js_field_text{_}: String
    case EmitterRequest_cps_provider_8_js_field_proto{_, _}: String
    case EmitterRequest_cps_provider_8_js_plain_key{_}: Bool
    case EmitterRequest_cps_provider_8_js_plain_key_first{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_plain_key_chars{_}: Bool
    case EmitterRequest_cps_provider_8_js_plain_key_head{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_plain_key_tail{_}: Bool
    case EmitterRequest_cps_provider_8_js_plain_key_tail_more{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_plain_head{_}: Bool
    case EmitterRequest_cps_provider_8_js_member_text{_, _}: String
    case EmitterRequest_cps_provider_8_js_member_atom{_}: Bool
    case EmitterRequest_cps_provider_8_js_member_selected{_, _, _}: String
    case EmitterRequest_cps_provider_8_js_member_plain{_, _}: String
    case EmitterRequest_cps_provider_8_record_fields{_}: String
    case EmitterRequest_cps_provider_8_foreign_parameters{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_foreign_arrow{_, _}: String
    case EmitterRequest_cps_provider_8_foreign_kont{_, _, _}: String
    case EmitterRequest_cps_provider_8_foreign_kont_scalar{_, _}: String
    case EmitterRequest_cps_provider_8_foreign_kont_nat{_}: String
    case EmitterRequest_cps_provider_8_foreign_answer_kont{_, _, _}: String
    case EmitterRequest_cps_provider_8_foreign_request{_, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_foreign_arguments{_, _, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_foreign_argument{_, _}: String
    case EmitterRequest_cps_provider_8_js_text_descriptor{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_text_head{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_f32_descriptor{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_f32_head{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_descriptor_head{_}: Maybe<&2, cps_provider_8_JSDescriptorHead>
    case EmitterRequest_cps_provider_8_js_descriptor_head_fill{_, _}: Maybe<&2, cps_provider_8_JSDescriptorHead>
    case EmitterRequest_cps_provider_8_js_descriptor_head_applied{_, _}: Maybe<&2, cps_provider_8_JSDescriptorHead>
    case EmitterRequest_cps_provider_8_js_native_is{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_native_is_found{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_io_answer{_, _}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_8_js_io_answer_head{_, _}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_8_js_io_answer_named{_, _}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_8_js_first_descriptor{_}: Maybe<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_8_js_nat_descriptor{_, _}: Bool

def emitter_result_group_26(request: EmitterRequestGroup26) -> Type:
  match request:
    case EmitterRequest_cps_provider_8_js_nat_descriptor_head{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_nat_descriptor_named{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_bool_of_parameter{_}: Bool
    case EmitterRequest_cps_provider_8_js_nat_answer{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_nat_answer_io{_, _}: Bool
    case EmitterRequest_cps_provider_8_operation{_}: String
    case EmitterRequest_cps_provider_8_tag_test{_, _}: String
    case EmitterRequest_cps_provider_8_tag_subject_same{_, _}: Bool
    case EmitterRequest_cps_provider_8_tagged_region_checked{_, _}: Maybe<&2, cps_provider_8_TaggedRegion>
    case EmitterRequest_cps_provider_8_tagged_region{_}: Maybe<&2, cps_provider_8_TaggedRegion>
    case EmitterRequest_cps_provider_8_tag_unseen{_}: Bool
    case EmitterRequest_cps_provider_8_tag_group_selected{_, _, _, _, _, _, _, _}: cps_provider_8_TagGroup
    case EmitterRequest_cps_provider_8_tag_group_arm{_, _, _, _, _, _, _}: cps_provider_8_TagGroup
    case EmitterRequest_cps_provider_8_tag_group_view{_, _, _, _, _, _, _}: cps_provider_8_TagGroup
    case EmitterRequest_cps_provider_8_tag_group{_, _, _, _, _, _}: cps_provider_8_TagGroup
    case EmitterRequest_cps_provider_8_tag_arms{_, _}: String
    case EmitterRequest_cps_provider_8_ordinary_region{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_tag_render_selected{_, _, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_tag_render_group{_, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_region_view{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_region{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_block{_, _}: String
    case EmitterRequest_cps_provider_8_code{_}: String
    case EmitterRequest_cps_provider_8_codes{_}: String
    case EmitterRequest_cps_provider_8_js_ctx{_, _}: cps_provider_8_JsCtx
    case EmitterRequest_cps_provider_8_js_ctx_inside{_, _}: cps_provider_8_JsCtx
    case EmitterRequest_cps_provider_8_js_ctx_owner{_}: String
    case EmitterRequest_cps_provider_8_js_ctx_has{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_ctx_cont{_, _}: cps_provider_8_Caps
    case EmitterRequest_cps_provider_8_js_ctx_thunk{_, _}: cps_provider_8_Caps
    case EmitterRequest_cps_provider_8_js_ctx_frame{_, _}: Bool
    case EmitterRequest_cps_provider_8_frame_has{_, _}: Bool
    case EmitterRequest_cps_provider_8_frame_has_one{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_cont_name{_}: String
    case EmitterRequest_cps_provider_8_thunk_name{_, _}: String
    case EmitterRequest_cps_provider_8_split_op{_}: Bool
    case EmitterRequest_cps_provider_8_reads_new{}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_reads_local{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_reads_slot{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_atom_reads{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_arg_reads{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_args_reads{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_apply_reads{_, _, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_field_reads{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_fields_reads{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_op_reads{_, _}: cps_provider_8_Reads
    case EmitterRequest_cps_provider_8_suffix_empty{}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_fold{_, _}: cps_provider_8_Held
    case EmitterRequest_cps_provider_8_suffix_fold_one{_, _, _, _}: cps_provider_8_Held
    case EmitterRequest_cps_provider_8_suffix_reads{_, _, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_folded{_, _, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_atom{_, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_args{_, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_apply{_, _, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_op{_, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_prefix{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_8_suffix_prefix_one{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_8_suffix_join{_, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_joined{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_8_suffix_bind{_, _}: cps_provider_8_Suffix
    case EmitterRequest_cps_provider_8_suffix_caps{_, _}: cps_provider_8_Caps
    case EmitterRequest_cps_provider_8_caps_bound{_, _, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_8_caps_bound_one{_, _, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_8_caps_result{_, _, _}: List<&2, U32>

def emitter_result_group_27(request: EmitterRequestGroup27) -> Type:
  match request:
    case EmitterRequest_cps_provider_8_caps_result_id{_, _, _}: List<&2, U32>
    case EmitterRequest_cps_provider_8_caps_locals{_}: List<&2, U32>
    case EmitterRequest_cps_provider_8_caps_slots{_}: List<&2, U32>
    case EmitterRequest_cps_provider_8_cap_total{_}: Nat
    case EmitterRequest_cps_provider_8_fact_after{_, _}: Bool
    case EmitterRequest_cps_provider_8_fact_after_here{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_8_facts_merge{_, _}: List<&2, cps_provider_8_FrameBits>
    case EmitterRequest_cps_provider_8_facts_elevate{_}: List<&2, cps_provider_8_FrameBits>
    case EmitterRequest_cps_provider_8_facts_inject{_, _}: List<&2, cps_provider_8_FrameBits>
    case EmitterRequest_cps_provider_8_plan_empty{}: cps_provider_8_Plan
    case EmitterRequest_cps_provider_8_plan_cont_add{_, _, _}: cps_provider_8_Plan
    case EmitterRequest_cps_provider_8_plan_thunk_add{_, _, _}: cps_provider_8_Plan
    case EmitterRequest_cps_provider_8_plan_frame_add{_, _, _}: cps_provider_8_Plan
    case EmitterRequest_cps_provider_8_plan_cont{_, _}: cps_provider_8_Caps
    case EmitterRequest_cps_provider_8_plan_thunk{_, _}: cps_provider_8_Caps
    case EmitterRequest_cps_provider_8_plan_frame{_, _}: Bool
    case EmitterRequest_cps_provider_8_plan_caps{_, _}: cps_provider_8_Caps
    case EmitterRequest_cps_provider_8_plan_flag{_, _}: Bool
    case EmitterRequest_cps_provider_8_plan_of{_}: cps_provider_8_Plan
    case EmitterRequest_cps_provider_8_plan_block{_, _}: cps_provider_8_Step
    case EmitterRequest_cps_provider_8_plan_leaf{_, _}: cps_provider_8_Step
    case EmitterRequest_cps_provider_8_plan_let{_, _, _}: cps_provider_8_Step
    case EmitterRequest_cps_provider_8_plan_branch{_, _, _}: cps_provider_8_Step
    case EmitterRequest_cps_provider_8_plan_region{_, _, _}: cps_provider_8_Step
    case EmitterRequest_cps_provider_8_plan_region_sites{_, _, _, _}: cps_provider_8_Plan
    case EmitterRequest_cps_provider_8_js_scalar{_}: BIR.Block
    case EmitterRequest_cps_provider_8_js_scalar_let{_, _, _, _, _}: BIR.Block
    case EmitterRequest_cps_provider_8_js_scalar_repeatable{_, _, _, _, _, _}: BIR.Block
    case EmitterRequest_cps_provider_8_js_scalar_escapes{_, _, _, _, _, _}: BIR.Block
    case EmitterRequest_cps_provider_8_js_scalar_fields{_}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_fields_value{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_value{_}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_block_ok{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_op_ok{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_project_ok{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_project_local{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_project_field{_}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_field_at{_, _}: Maybe<&2, BIR.Atom>
    case EmitterRequest_cps_provider_8_js_scalar_field_at_same{_, _, _, _}: Maybe<&2, BIR.Atom>
    case EmitterRequest_cps_provider_8_js_scalar_reads{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_mentions{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_mentions_one{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_atom_used{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_args_used{_, _}: Bool
    case EmitterRequest_cps_provider_8_js_scalar_block{_, _, _}: BIR.Block
    case EmitterRequest_cps_provider_8_js_scalar_op{_, _, _}: BIR.Op
    case EmitterRequest_cps_provider_8_js_scalar_projected{_, _, _, _}: Maybe<&2, BIR.Atom>
    case EmitterRequest_cps_provider_8_js_scalar_projected_local{_, _, _}: Maybe<&2, BIR.Atom>
    case EmitterRequest_cps_provider_8_js_scalar_projection{_, _, _, _, _}: BIR.Op
    case EmitterRequest_cps_provider_8_js_scalar_program{_}: BIR.Program
    case EmitterRequest_cps_provider_8_js_scalar_codes{_, _}: List<&2, BIR.Code>
    case EmitterRequest_cps_provider_8_let_step{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_split_direct{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_split_direct_selected{_, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_split_direct_args{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_split_direct_many{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_split_apply{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_arg_atom{_}: String
    case EmitterRequest_cps_provider_8_arg_temps{_, _}: String
    case EmitterRequest_cps_provider_8_arg_temps_tail{_, _}: String
    case EmitterRequest_cps_provider_8_arg_temp_names{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_arg_moves{_, _}: String
    case EmitterRequest_cps_provider_8_arg_moves_at{_, _, _}: String
    case EmitterRequest_cps_provider_8_cap_stores{_}: String

def emitter_result_group_28(request: EmitterRequestGroup28) -> Type:
  match request:
    case EmitterRequest_cps_provider_8_slot_stores{_}: String
    case EmitterRequest_cps_provider_8_cap_binds{_, _}: String
    case EmitterRequest_cps_provider_8_slot_binds{_, _}: String
    case EmitterRequest_cps_provider_8_cont_of{_, _, _}: String
    case EmitterRequest_cps_provider_8_thunk_of{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_region_frame{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_leave_step{_, _}: String
    case EmitterRequest_cps_provider_8_conts{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_conts_let{_, _, _, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_conts_region{_, _, _, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_primitive_name{_}: String
    case EmitterRequest_cps_provider_8_primitive_public{_}: String
    case EmitterRequest_cps_provider_8_map_find_roles{_, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_map_find_roles_one{_, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_map_find_role_used{_}: Bool
    case EmitterRequest_cps_provider_8_map_find_keep_role{_, _, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_map_find_role_fields{_, _, _, _}: Map<&2, String>
    case EmitterRequest_cps_provider_8_map_find_field_role{_, _}: String
    case EmitterRequest_cps_provider_8_map_find_runtime{_}: String
    case EmitterRequest_cps_provider_8_map_find_lookup{_}: cps_provider_8_JsMapFind
    case EmitterRequest_cps_provider_8_map_find_source{_}: String
    case EmitterRequest_cps_provider_8_map_find_missing{}: String
    case EmitterRequest_cps_provider_8_map_find_member{_}: String
    case EmitterRequest_cps_provider_8_map_find_text{_, _, _, _, _, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_primitive_runtime{}: String
    case EmitterRequest_cps_provider_8_quantity{_}: String
    case EmitterRequest_cps_provider_8_optional_quantity{_}: String
    case EmitterRequest_cps_provider_8_quantities{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_descriptor_pattern{_}: String
    case EmitterRequest_cps_provider_8_descriptor_patterns{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_descriptors{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_descriptor{_}: String
    case EmitterRequest_cps_provider_8_deferred{_, _}: String
    case EmitterRequest_cps_provider_8_declaration{_, _, _}: String
    case EmitterRequest_cps_provider_8_foreign_declaration{_, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_foreign_source{_, _, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_native_declaration{_, _, _}: String
    case EmitterRequest_cps_provider_8_declarations{_, _, _}: String
    case EmitterRequest_cps_provider_8_field_names{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_constructor_layout{_}: String
    case EmitterRequest_cps_provider_8_constructor_layout_source{_, _, _}: String
    case EmitterRequest_cps_provider_8_constructor_layouts{_}: String
    case EmitterRequest_cps_provider_8_descriptor_field_types{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_descriptor_field_quantities{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_descriptor_field_names{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_descriptor_arm{_}: String
    case EmitterRequest_cps_provider_8_descriptor_arms{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_parameter_info{_, _, _}: String
    case EmitterRequest_cps_provider_8_family{_}: String
    case EmitterRequest_cps_provider_8_families{_}: String
    case EmitterRequest_cps_provider_8_type_function{_}: String
    case EmitterRequest_cps_provider_8_type_functions{_}: String
    case EmitterRequest_cps_provider_8_js_parameter{_, _}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_head{_, _, _}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_marker{_, _, _, _}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_other{_, _}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_known{_, _}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_alias{_, _}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_arity{_}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_arity_count{_}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_js_parameter_unresolved{_}: cps_provider_8_JSParameter
    case EmitterRequest_cps_provider_8_export_arguments{_, _, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_export_argument{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_export_argument_scalar{_, _, _}: String

def emitter_result_group_29(request: EmitterRequestGroup29) -> Type:
  match request:
    case EmitterRequest_cps_provider_8_export_argument_float{_, _}: String
    case EmitterRequest_cps_provider_8_export_unresolved{_, _, _}: Bool
    case EmitterRequest_cps_provider_8_export_unresolved_item{_, _, _, _}: Bool
    case EmitterRequest_cps_provider_8_export_field{_, _}: String
    case EmitterRequest_cps_provider_8_export_entry_field{_, _, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_export_direct_field{_, _, _, _, _}: String
    case EmitterRequest_cps_provider_8_export_result{_, _, _}: String
    case EmitterRequest_cps_provider_8_export_nat_indices{_, _, _}: List<&2, Nat>
    case EmitterRequest_cps_provider_8_export_nat_index_texts{_}: List<&2, String>
    case EmitterRequest_cps_provider_8_export_nat_indexes{_, _}: String
    case EmitterRequest_cps_provider_8_export_text_indices{_, _, _}: List<&2, Nat>
    case EmitterRequest_cps_provider_8_export_text_index{_, _, _, _}: List<&2, Nat>
    case EmitterRequest_cps_provider_8_export_f32_indices{_, _, _}: List<&2, Nat>
    case EmitterRequest_cps_provider_8_export_f32_index{_, _, _, _}: List<&2, Nat>
    case EmitterRequest_cps_provider_8_export_text_indexes{_, _}: String
    case EmitterRequest_cps_provider_8_export_f32_indexes{_, _}: String
    case EmitterRequest_cps_provider_8_export_result_normalizer{_, _}: String
    case EmitterRequest_cps_provider_8_export_curried{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_export_curried_value{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_export_curried_call{_, _, _, _}: String
    case EmitterRequest_cps_provider_8_export_fields{_, _}: List<&2, String>
    case EmitterRequest_cps_provider_8_ending{_, _}: String
    case EmitterRequest_cps_provider_8_export_check{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_export_check_one{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_ending_check{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_8_emit_linked{_, _}: cps_provider_8_EmitResult
    case EmitterRequest_cps_provider_8_emit_linked_plan{_, _, _}: cps_provider_8_EmitResult
    case EmitterRequest_cps_provider_8_emit_checked{_, _, _}: cps_provider_8_EmitResult
    case EmitterRequest_cps_provider_8_emit_checked_exports{_, _, _, _}: cps_provider_8_EmitResult
    case EmitterRequest_cps_provider_8_emit_effects{_, _}: cps_provider_8_EmitResult
    case EmitterRequest_cps_provider_8_program_source{_, _}: String
    case EmitterRequest_cps_provider_8_js_runtime_direct{}: String
    case EmitterRequest_cps_provider_8_js_runtime{}: String
    case EmitterRequest_cps_provider_8_js_runtime_extra{}: String
    case EmitterRequest_cps_provider_8_js_runtime_array{}: String
    case EmitterRequest_cps_provider_8_js_runtime_foreign{}: String
    case EmitterRequest_cps_provider_8_js_runtime_namespace{}: String
    case EmitterRequest_cps_provider_8_js_runtime_cli{}: String
    case EmitterRequest_cps_provider_8_js_runtime_io{}: String
    case EmitterRequest_cps_provider_8_js_runtime_show{}: String
    case EmitterRequest_cps_provider_8_js_runtime_type{}: String
    case EmitterRequest_cps_provider_8_js_runtime_type_names{}: String
    case EmitterRequest_cps_provider_8_js_runtime_type_patterns{}: String
    case EmitterRequest_cps_provider_8_js_runtime_type_eval{}: String
    case EmitterRequest_cps_provider_8_js_runtime_native_type{}: String
    case EmitterRequest_cps_provider_8_js_main{_}: String
    case EmitterRequest_cps_provider_9_emitted{_}: cps_provider_9_EmitResult
    case EmitterRequest_cps_provider_9_render{_, _}: cps_provider_9_EmitResult
    case EmitterRequest_cps_provider_9_emit_result{_, _}: cps_provider_9_EmitResult
    case EmitterRequest_cps_provider_9_emit{_, _}: cps_provider_9_EmitResult
    case EmitterRequest_cps_provider_9_emit_library{_, _, _}: cps_provider_9_EmitResult
    case EmitterRequest_cps_provider_10_qualify{_, _}: String
    case EmitterRequest_cps_provider_10_symbol_key{_}: String
    case EmitterRequest_cps_provider_10_quantity{_}: BIR.Quantity
    case EmitterRequest_cps_provider_10_optional_quantity{_}: Maybe<&2, BIR.Quantity>
    case EmitterRequest_cps_provider_10_parameter{_, _, _}: List<&2, BIR.Parameter>
    case EmitterRequest_cps_provider_10_field_key{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_10_canonical{_, _, _}: String
    case EmitterRequest_cps_provider_10_native_match_descriptor_0{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_descriptor{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_name_0{_, _, _}: cps_provider_10_CatalogResult<String>
    case EmitterRequest_cps_provider_10_descriptor_name{_, _, _, _}: cps_provider_10_CatalogResult<String>
    case EmitterRequest_cps_provider_10_native_match_descriptors_0{_, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_descriptors_1{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>

def emitter_result_group_30(request: EmitterRequestGroup30) -> Type:
  match request:
    case EmitterRequest_cps_provider_10_native_match_descriptors_2{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_descriptors_3{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_descriptors{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_patterns_0{_, _}: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_patterns_1{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_patterns_2{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_patterns_3{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_patterns_4{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>
    case EmitterRequest_cps_provider_10_descriptor_patterns{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.DescriptorPattern>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_pattern_0{_, _}: cps_provider_10_CatalogResult<BIR.DescriptorPattern>
    case EmitterRequest_cps_provider_10_native_match_descriptor_pattern_1{_, _, _, _}: cps_provider_10_CatalogResult<BIR.DescriptorPattern>
    case EmitterRequest_cps_provider_10_native_match_descriptor_pattern_2{_, _, _}: cps_provider_10_CatalogResult<BIR.DescriptorPattern>
    case EmitterRequest_cps_provider_10_descriptor_pattern{_, _, _}: cps_provider_10_CatalogResult<BIR.DescriptorPattern>
    case EmitterRequest_cps_provider_10_descriptor_apply{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_native_match_descriptor_sugar_0{_, _, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_sugar_1{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_sugar_2{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_sugar_3{_, _, _, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_sugar_4{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_sugar_5{_, _, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_sugar_6{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_descriptor_sugar{_, _, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_named_sugar{_, _, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_unnamed_sugar{_, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_string_names{_, _}: Ast.StringLiteralNames
    case EmitterRequest_cps_provider_10_string_bit{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_string_word{_, _, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_string_descriptor{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_0{_}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_1{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_2{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_3{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_4{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_5{_}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_6{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_7{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_8{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_9{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_10{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_11{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_12{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_13{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_14{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_15{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_16{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_17{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_18{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_19{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_20{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_21{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_22{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_23{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_24{_}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_25{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_26{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_27{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_28{_, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_29{_, _, _, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_node_30{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_descriptor_node{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_cases_0{_, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_cases_1{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_cases_2{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_cases_3{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>

def emitter_result_group_31(request: EmitterRequestGroup31) -> Type:
  match request:
    case EmitterRequest_cps_provider_10_native_match_descriptor_cases_4{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_descriptor_cases{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_descriptor_case_0{_, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_case_1{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_descriptor_case_2{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_descriptor_case{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_native_match_telescope_0{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_telescope_1{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_telescope_2{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_telescope_3{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_telescope{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_telescope_binder_0{_, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_telescope_binder_1{_, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_telescope_binder_2{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_telescope_binder_3{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_telescope_binder{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_field_names{_}: List<&2, Maybe<&2, String>>
    case EmitterRequest_cps_provider_10_fields_quantities{_}: List<&2, BIR.Quantity>
    case EmitterRequest_cps_provider_10_base_imports{_}: Bool
    case EmitterRequest_cps_provider_10_base_imported{_}: Bool
    case EmitterRequest_cps_provider_10_base_source{_, _}: Bool
    case EmitterRequest_cps_provider_10_native_marker{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_10_short_key{_}: String
    case EmitterRequest_cps_provider_10_short_chars{_, _}: String
    case EmitterRequest_cps_provider_10_constructor_native{_, _, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_10_primitive_name{_}: String
    case EmitterRequest_cps_provider_10_primitive_chars{_}: List<&2, Char>
    case EmitterRequest_cps_provider_10_primitive{_, _}: Maybe<&2, BIR.Primitive>
    case EmitterRequest_cps_provider_10_primitive_named{_}: Maybe<&2, BIR.Primitive>
    case EmitterRequest_cps_provider_10_definition_key{_, _}: Maybe<&2, cps_provider_10_DefinitionHeader>
    case EmitterRequest_cps_provider_10_constructor_key{_, _}: Maybe<&2, cps_provider_10_Constructor>
    case EmitterRequest_cps_provider_10_lookup_definition{_, _}: Maybe<&2, cps_provider_10_DefinitionHeader>
    case EmitterRequest_cps_provider_10_lookup_constructor{_, _}: Maybe<&2, cps_provider_10_Constructor>
    case EmitterRequest_cps_provider_10_get_definitions{_}: List<&2, cps_provider_10_Definition>
    case EmitterRequest_cps_provider_10_get_registry{_}: cps_provider_10_Registry
    case EmitterRequest_cps_provider_10_get_constructors{_}: List<&2, BIR.ConstructorLayout>
    case EmitterRequest_cps_provider_10_get_families{_}: List<&2, BIR.Family>
    case EmitterRequest_cps_provider_10_get_type_functions{_}: List<&2, BIR.TypeFunction>
    case EmitterRequest_cps_provider_10_get_next_code{_}: U32
    case EmitterRequest_cps_provider_10_get_ending{_}: BIR.Ending
    case EmitterRequest_cps_provider_10_native_match_insert_definition_0{_, _, _, _}: Map<&2, cps_provider_10_Definition>
    case EmitterRequest_cps_provider_10_insert_definition{_, _, _}: Map<&2, cps_provider_10_Definition>
    case EmitterRequest_cps_provider_10_native_match_insert_constructor_0{_, _, _, _}: Map<&2, cps_provider_10_Constructor>
    case EmitterRequest_cps_provider_10_insert_constructor{_, _, _}: Map<&2, cps_provider_10_Constructor>
    case EmitterRequest_cps_provider_10_normalize_descriptor_value{_, _}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_normalize_descriptors{_, _}: List<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_10_normalize_foreign{_, _}: Maybe<&2, cps_provider_10_Foreign>
    case EmitterRequest_cps_provider_10_normalize_foreign_header{_, _}: cps_provider_10_DefinitionHeader
    case EmitterRequest_cps_provider_10_normalize_foreign_definition{_, _}: cps_provider_10_Definition
    case EmitterRequest_cps_provider_10_normalize_foreign_definitions{_, _}: List<&2, cps_provider_10_Definition>
    case EmitterRequest_cps_provider_10_export_entry{_}: Maybe<&2, BIR.Entry>
    case EmitterRequest_cps_provider_10_export_definition{_, _}: Maybe<&2, cps_provider_10_Definition>
    case EmitterRequest_cps_provider_10_export_signature{_, _}: Maybe<&2, U32>
    case EmitterRequest_cps_provider_10_live_arrow_types{_}: List<&2, BIR.Descriptor>
    case EmitterRequest_cps_provider_10_live_arrow_result{_}: BIR.Descriptor
    case EmitterRequest_cps_provider_10_export_facts_of{_, _}: cps_provider_10_CatalogResult<cps_provider_10_ExportFacts>
    case EmitterRequest_cps_provider_10_export_facts{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_ExportFacts>
    case EmitterRequest_cps_provider_10_exports{_, _, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Export>>
    case EmitterRequest_cps_provider_10_native_match_needed_ref_0{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_ref_1{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_needed_ref{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_definition_0{_, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_definition_1{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_needed_definition{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>

def emitter_result_group_32(request: EmitterRequestGroup32) -> Type:
  match request:
    case EmitterRequest_cps_provider_10_native_match_needed_terms_0{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_terms_1{_, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_terms_2{_, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_needed_terms{_, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_pair_0{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_needed_pair{_, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_0{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_1{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_2{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_3{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_4{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_5{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_6{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_term_7{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_needed_term{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_roots_0{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_roots_1{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_needed_roots_2{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_needed_roots{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Needed>
    case EmitterRequest_cps_provider_10_native_match_binder_roots_0{_, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, cps_provider_10_Root>>
    case EmitterRequest_cps_provider_10_native_match_binder_roots_1{_, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, cps_provider_10_Root>>
    case EmitterRequest_cps_provider_10_native_match_binder_roots_2{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, cps_provider_10_Root>>
    case EmitterRequest_cps_provider_10_binder_roots{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, cps_provider_10_Root>>
    case EmitterRequest_cps_provider_10_binder_type{_}: U32
    case EmitterRequest_cps_provider_10_result_roots{_, _, _}: List<&2, cps_provider_10_Root>
    case EmitterRequest_cps_provider_10_type_root{_, _, _}: List<&2, cps_provider_10_Root>
    case EmitterRequest_cps_provider_10_preparation_failure{_, _}: cps_provider_10_Preparation
    case EmitterRequest_cps_provider_10_first_failure{_, _}: Maybe<&2, String>
    case EmitterRequest_cps_provider_10_native_match_header_insert_0{_, _, _, _}: Map<&2, cps_provider_10_DefinitionHeader>
    case EmitterRequest_cps_provider_10_header_insert{_, _, _}: Map<&2, cps_provider_10_DefinitionHeader>
    case EmitterRequest_cps_provider_10_value_insert{_, _, _, _, _}: Map<&2, cps_provider_10_Definition>
    case EmitterRequest_cps_provider_10_native_match_foreign_sources_1{_, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, String>>
    case EmitterRequest_cps_provider_10_native_match_foreign_sources_0{_, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, String>>
    case EmitterRequest_cps_provider_10_foreign_sources{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, String>>
    case EmitterRequest_cps_provider_10_foreign_namespace{_, _}: String
    case EmitterRequest_cps_provider_10_foreign_result_type{_, _, _}: cps_provider_10_CatalogResult<BIR.Descriptor>
    case EmitterRequest_cps_provider_10_live_parameter_types{_, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_live_parameter_types_2{_, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_live_parameter_types_1{_, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_live_parameter_binder{_, _, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_live_parameter_quantity{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<List<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_definition_foreign{_, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<Maybe<&2, cps_provider_10_Foreign>>
    case EmitterRequest_cps_provider_10_definition_fast{_, _, _, _, _}: Bool
    case EmitterRequest_cps_provider_10_definition_primitive{_, _, _, _}: Maybe<&2, BIR.Primitive>
    case EmitterRequest_cps_provider_10_native_match_main_descriptor_0{_}: cps_provider_10_CatalogResult<Maybe<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_main_descriptor_1{_, _, _, _}: cps_provider_10_CatalogResult<Maybe<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_native_match_main_descriptor_2{_, _, _, _, _}: cps_provider_10_CatalogResult<Maybe<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_main_descriptor{_, _, _, _, _}: cps_provider_10_CatalogResult<Maybe<&2, BIR.Descriptor>>
    case EmitterRequest_cps_provider_10_signature_symbol{_}: IR.Symbol
    case EmitterRequest_cps_provider_10_prepare_definition{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_0{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_1{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_2{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_3{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_4{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_definition_symbol_5{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_prepare_definition_symbol{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_is_term{_}: Bool
    case EmitterRequest_cps_provider_10_native_match_prepare_constructors_0{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Arms>
    case EmitterRequest_cps_provider_10_native_match_prepare_constructors_1{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Arms>
    case EmitterRequest_cps_provider_10_native_match_prepare_constructors_2{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Arms>
    case EmitterRequest_cps_provider_10_native_match_prepare_constructors_3{_, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Arms>
    case EmitterRequest_cps_provider_10_native_match_prepare_constructors_4{_, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Arms>
    case EmitterRequest_cps_provider_10_prepare_constructors{_, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Arms>

def emitter_result_group_33(request: EmitterRequestGroup33) -> Type:
  match request:
    case EmitterRequest_cps_provider_10_native_match_prepare_family_0{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_family_1{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_family_2{_, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_family_3{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_prepare_family{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_words_count{_}: Nat
    case EmitterRequest_cps_provider_10_block_family{_, _, _}: cps_provider_10_Preparation
    case EmitterRequest_cps_provider_10_law_telescope{_, _}: Maybe<&2, cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_law_telescope_cons{_, _, _}: Maybe<&2, cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_prepare_law{_, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_prepare_native_law{_, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_family_key{_, _}: String
    case EmitterRequest_cps_provider_10_native_match_prepare_declarations_0{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_declarations_1{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_declarations_2{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_declarations_3{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_declarations_4{_, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_declarations_5{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_declarations_6{_, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_prepare_declarations{_, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_reset_module{_}: cps_provider_10_Preparation
    case EmitterRequest_cps_provider_10_native_match_prepare_modules_0{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_modules_1{_, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_native_match_prepare_modules_2{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_prepare_modules{_, _, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Preparation>
    case EmitterRequest_cps_provider_10_ending{_, _, _, _, _, _, _}: cps_provider_10_CatalogResult<BIR.Ending>
    case EmitterRequest_cps_provider_10_root_main_runnable{_}: Bool
    case EmitterRequest_cps_provider_10_root_main_admitted{_}: Bool
    case EmitterRequest_cps_provider_10_executable_admitted{_, _}: Bool
    case EmitterRequest_cps_provider_10_native_match_build_finish_0{_, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_BuildResult
    case EmitterRequest_cps_provider_10_native_match_build_finish_2{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _}: cps_provider_10_BuildResult
    case EmitterRequest_cps_provider_10_native_match_build_finish_1{_, _, _, _, _, _}: cps_provider_10_BuildResult
    case EmitterRequest_cps_provider_10_build_finish{_, _, _, _, _, _}: cps_provider_10_BuildResult
    case EmitterRequest_cps_provider_10_native_match_build_0{_, _, _, _, _}: cps_provider_10_BuildResult
    case EmitterRequest_cps_provider_10_native_match_build_1{_, _}: cps_provider_10_BuildResult
    case EmitterRequest_cps_provider_10_build{_, _}: cps_provider_10_BuildResult
    case EmitterRequest_cps_provider_10_native_match_live_telescope_0{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_live_telescope_1{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_live_telescope_2{_, _, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_native_match_live_telescope_3{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_live_telescope{_, _, _}: cps_provider_10_CatalogResult<cps_provider_10_Telescope>
    case EmitterRequest_cps_provider_10_live_binder{_, _, _}: cps_provider_10_Telescope
    case EmitterRequest_cps_provider_10_primitive_arity{_}: Nat
    case EmitterRequest_cps_provider_10_constructor_field{_, _}: Maybe<&2, cps_provider_10_ConstructorField>
    case EmitterRequest_cps_provider_10_constructor_field_at{_, _, _, _}: Maybe<&2, cps_provider_10_ConstructorField>

def emitter_result(request: EmitterRequest) -> Type:
  match request:
    case EmitterRequestGroup_0{inner}: emitter_result_group_0(inner)
    case EmitterRequestGroup_1{inner}: emitter_result_group_1(inner)
    case EmitterRequestGroup_2{inner}: emitter_result_group_2(inner)
    case EmitterRequestGroup_3{inner}: emitter_result_group_3(inner)
    case EmitterRequestGroup_4{inner}: emitter_result_group_4(inner)
    case EmitterRequestGroup_5{inner}: emitter_result_group_5(inner)
    case EmitterRequestGroup_6{inner}: emitter_result_group_6(inner)
    case EmitterRequestGroup_7{inner}: emitter_result_group_7(inner)
    case EmitterRequestGroup_8{inner}: emitter_result_group_8(inner)
    case EmitterRequestGroup_9{inner}: emitter_result_group_9(inner)
    case EmitterRequestGroup_10{inner}: emitter_result_group_10(inner)
    case EmitterRequestGroup_11{inner}: emitter_result_group_11(inner)
    case EmitterRequestGroup_12{inner}: emitter_result_group_12(inner)
    case EmitterRequestGroup_13{inner}: emitter_result_group_13(inner)
    case EmitterRequestGroup_14{inner}: emitter_result_group_14(inner)
    case EmitterRequestGroup_15{inner}: emitter_result_group_15(inner)
    case EmitterRequestGroup_16{inner}: emitter_result_group_16(inner)
    case EmitterRequestGroup_17{inner}: emitter_result_group_17(inner)
    case EmitterRequestGroup_18{inner}: emitter_result_group_18(inner)
    case EmitterRequestGroup_19{inner}: emitter_result_group_19(inner)
    case EmitterRequestGroup_20{inner}: emitter_result_group_20(inner)
    case EmitterRequestGroup_21{inner}: emitter_result_group_21(inner)
    case EmitterRequestGroup_22{inner}: emitter_result_group_22(inner)
    case EmitterRequestGroup_23{inner}: emitter_result_group_23(inner)
    case EmitterRequestGroup_24{inner}: emitter_result_group_24(inner)
    case EmitterRequestGroup_25{inner}: emitter_result_group_25(inner)
    case EmitterRequestGroup_26{inner}: emitter_result_group_26(inner)
    case EmitterRequestGroup_27{inner}: emitter_result_group_27(inner)
    case EmitterRequestGroup_28{inner}: emitter_result_group_28(inner)
    case EmitterRequestGroup_29{inner}: emitter_result_group_29(inner)
    case EmitterRequestGroup_30{inner}: emitter_result_group_30(inner)
    case EmitterRequestGroup_31{inner}: emitter_result_group_31(inner)
    case EmitterRequestGroup_32{inner}: emitter_result_group_32(inner)
    case EmitterRequestGroup_33{inner}: emitter_result_group_33(inner)

type EmitterValue<-A: Type> is Type:
  EmitterValue{value: A}

type EmitterProgress<-A: Type> is Type:
  EmitterFinished{box: EmitterValue<A>}
  EmitterPending{request: EmitterRequest, resume: (@box: EmitterValue<emitter_result(request)> -> EmitterProgress<A>)}
  EmitterDirect{-R: Type, -request: EmitterRequest, arguments: R, invoke: (@arguments: R -> EmitterProgress<emitter_result(request)>), resume: (@box: EmitterValue<emitter_result(request)> -> EmitterProgress<A>)}
  EmitterBound{-B: Type, inner: EmitterProgress<B>, resume: (@box: EmitterValue<B> -> EmitterProgress<A>)}


type EmitterStack<-A: Type, -R: Type> is Type:
  EmitterStackDone{equation: {A == R : Type}}
  EmitterStackMore{-B: Type, resume: (@box: EmitterValue<A> -> EmitterProgress<B>), rest: EmitterStack<B, R>}

type EmitterRun<-R: Type> is Type:
  EmitterRunFinished{box: EmitterValue<R>}
  EmitterRunState{-A: Type, progress: EmitterProgress<A>, stack: EmitterStack<A, R>}

def emitter_unbox(-A: Type, box: EmitterValue<A>) -> A:
  match box:
    case EmitterValue{value}: value

def emitter_body_cps_provider_2_cat(v_2: List<&2, String>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_16{EmitterRequest_cps_provider_4_text_of_pieces{v_2}}, v_1001993 => +v_1001992 = emitter_unbox(String, v_1001993); EmitterFinished{EmitterValue{v_1001992}}}

def emitter_body_cps_provider_2_okp(v_1: String) -> EmitterProgress<cps_provider_2_Part>:
  EmitterFinished{EmitterValue{cps_provider_2_PartOk{cps_provider_4_TextLeaf{v_1}}}}

def emitter_body_cps_provider_2_failp(v_1: String) -> EmitterProgress<cps_provider_2_Part>:
  EmitterFinished{EmitterValue{cps_provider_2_PartFail{v_1}}}

def emitter_body_cps_provider_2_cid_short_one(v_1: Bool, v_3: String, v_5: U32, v_8: List<&2, cps_provider_2_CidRow>) -> EmitterProgress<Maybe<&2, U32>>:
  match v_1:
    case True{}:
      EmitterFinished{EmitterValue{Some{v_5}}}
    case False{}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_cps_provider_2_cid_short{v_3, v_8}}, v_1015252 => +v_1015253 = emitter_unbox(Maybe<&2, U32>, v_1015252); EmitterFinished{EmitterValue{v_1015253}}}

def emitter_match_570(+v_9: cps_provider_2_CidRow, +v_1: String, v_10: List<&2, cps_provider_2_CidRow>) -> EmitterProgress<Maybe<&2, U32>>:
  match v_9:
    case cps_provider_2_CidRow{v_15, v_16, v_17, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_cps_provider_2_cid_short_one{String.eq(v_1, v_16), v_1, v_15, v_10}}, False{}, v_1002198 => emitter_body_cps_provider_2_cid_short_one(String.eq(v_1, v_16), v_1, v_15, v_10), v_1002197 => +v_1002196 = emitter_unbox(Maybe<&2, U32>, v_1002197); EmitterFinished{EmitterValue{v_1002196}}}

def emitter_body_cps_provider_2_cid_short(+v_1: String, v_4: List<&2, cps_provider_2_CidRow>) -> EmitterProgress<Maybe<&2, U32>>:
  match v_4:
    case []:
      EmitterFinished{EmitterValue{None{}}}
    case +v_1015254 <> v_1015255:
      emitter_match_570(v_1015254, v_1, v_1015255)

def emitter_match_572(+v_1002199: Maybe<&2, U32>, +v_1: String) -> EmitterProgress<cps_provider_2_Part>:
  match v_1002199:
    case Some{v_8}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_okp{String.append(U32.show(v_8), "u")}}, False{}, v_1002202 => emitter_body_cps_provider_2_okp(String.append(U32.show(v_8), "u")), v_1002201 => +v_1002200 = emitter_unbox(cps_provider_2_Part, v_1002201); EmitterFinished{EmitterValue{v_1002200}}}
    case None{}:
      EmitterFinished{EmitterValue{cps_provider_2_PartFail{String.append("the program has no `", String.append(v_1, "` constructor, which the C runtime contract requires"))}}}

def emitter_body_cps_provider_2_cid_c(+v_1: String, v_4: List<&2, cps_provider_2_CidRow>) -> EmitterProgress<cps_provider_2_Part>:
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_cps_provider_2_cid_short{v_1, v_4}}, False{}, v_1002204 => emitter_body_cps_provider_2_cid_short(v_1, v_4), v_1002203 => +v_1002199 = emitter_unbox(Maybe<&2, U32>, v_1002203); emitter_match_572(v_1002199, v_1)}

def emitter_continuation_666(v_12: cps_provider_4_Fragment, v_1002608: String, +v_1002609: String, v_1: String, v_3: String) -> EmitterProgress<cps_provider_2_Part>:
  v_1002610 = {", " : String}
  EmitterPending{EmitterRequestGroup_16{EmitterRequest_cps_provider_4_fragment_text{v_12}}, v_1002616 => +v_1002611 = emitter_unbox(String, v_1002616); EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{[v_1002608, v_1002609, v_1002610, v_1002611, ", ", v_1, ", ", v_3, ", 0)"]}}, False{}, v_1002615 => emitter_body_cps_provider_2_cat([v_1002608, v_1002609, v_1002610, v_1002611, ", ", v_1, ", ", v_3, ", 0)"]), v_1002614 => +v_1002612 = emitter_unbox(String, v_1002614); emitter_body_cps_provider_2_okp(v_1002612)}}

def emitter_match_667(+v_1002606: cps_provider_2_Part, +v_1002607: cps_provider_2_Part, v_1: String, v_3: String) -> EmitterProgress<cps_provider_2_Part>:
  match v_1002606, v_1002607:
    case cps_provider_2_PartOk{v_11}, cps_provider_2_PartOk{v_12}:
      EmitterPending{EmitterRequestGroup_16{EmitterRequest_cps_provider_4_fragment_text{v_11}}, v_1002617 => +v_1002609 = emitter_unbox(String, v_1002617); emitter_continuation_666(v_12, {"bend_str_append(e, " : String}, v_1002609, v_1, v_3)}
    case cps_provider_2_PartFail{v_19}, _:
      EmitterFinished{EmitterValue{cps_provider_2_PartFail{v_19}}}
    case _, cps_provider_2_PartFail{v_24}:
      EmitterFinished{EmitterValue{cps_provider_2_PartFail{v_24}}}

def emitter_body_cps_provider_2_str_append(v_1: String, v_3: String, +v_5: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_pcid{"SCon", v_5}}, v_1002619 => +v_1002606 = emitter_unbox(cps_provider_2_Part, v_1002619); EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_pcid{"Chr", v_5}}, v_1002618 => +v_1002607 = emitter_unbox(cps_provider_2_Part, v_1002618); emitter_match_667(v_1002606, v_1002607, v_1, v_3)}}

def emitter_body_cps_provider_2_pcid(v_1: String, v_3: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  match v_3:
    case cps_provider_2_Plan{v_1015373, v_1015374, v_1015375, v_1015376, v_1015377, v_1015378, v_1015379, v_1015380, v_1015381, v_1015382, v_1015383, v_1015384, v_1015385, v_1015386, v_1015387, v_1015388, v_1015389, v_1015390, v_1015391, v_1015392, v_1015393}:
      emitter_body_cps_provider_2_cid_c(v_1, v_1015373)

def emitter_match_703(+v_1002746: cps_provider_2_Part, v_1: String, v_5: String, v_7: String, v_9: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  match v_1002746:
    case cps_provider_2_PartFail{v_13}:
      EmitterFinished{EmitterValue{cps_provider_2_PartFail{v_13}}}
    case cps_provider_2_PartOk{v_15}:
      v_1002747 = {v_1 : String}
      v_1002748 = {"(e, " : String}
      EmitterPending{EmitterRequestGroup_16{EmitterRequest_cps_provider_4_fragment_text{v_15}}, v_1002755 => +v_1002749 = emitter_unbox(String, v_1002755); EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{[v_1002747, v_1002748, v_1002749, ", ", v_5, ", ", v_7, ")"]}}, False{}, v_1002754 => emitter_body_cps_provider_2_cat([v_1002747, v_1002748, v_1002749, ", ", v_5, ", ", v_7, ")"]), v_1002753 => +v_1002750 = emitter_unbox(String, v_1002753); EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_bool_part{v_1002750, v_9}}, v_1002752 => +v_1002751 = emitter_unbox(cps_provider_2_Part, v_1002752); EmitterFinished{EmitterValue{v_1002751}}}}}

def emitter_body_cps_provider_2_str_bool2(v_1: String, v_3: String, v_5: String, v_7: String, +v_9: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  EmitterDirect{Bool, EmitterRequestGroup_8{EmitterRequest_cps_provider_2_pcid{v_3, v_9}}, False{}, v_1002757 => emitter_body_cps_provider_2_pcid(v_3, v_9), v_1002756 => +v_1002746 = emitter_unbox(cps_provider_2_Part, v_1002756); emitter_match_703(v_1002746, v_1, v_5, v_7, v_9)}

def emitter_body_cps_provider_2_bool_str_empty_of(v_1: Bool, v_3: String, v_5: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  match v_1:
    case True{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(!", v_3, ")"]}}, False{}, v_1002762 => emitter_body_cps_provider_2_cat(["(!", v_3, ")"]), v_1002761 => +v_1002758 = emitter_unbox(String, v_1002761); EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_bool_part{v_1002758, v_5}}, v_1002760 => +v_1002759 = emitter_unbox(cps_provider_2_Part, v_1002760); EmitterFinished{EmitterValue{v_1002759}}}}
    case False{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_bool_part{v_3, v_5}}, v_1002764 => +v_1002763 = emitter_unbox(cps_provider_2_Part, v_1002764); EmitterFinished{EmitterValue{v_1002763}}}

def emitter_match_705(+v_1002765: cps_provider_2_Part, v_1: Bool, v_3: String, v_5: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  match v_1002765:
    case cps_provider_2_PartFail{v_9}:
      EmitterFinished{EmitterValue{cps_provider_2_PartFail{v_9}}}
    case cps_provider_2_PartOk{v_11}:
      v_1002767 = {"bend_str_empty(" : String}
      v_1002768 = {v_3 : String}
      v_1002769 = {", " : String}
      EmitterPending{EmitterRequestGroup_16{EmitterRequest_cps_provider_4_fragment_text{v_11}}, v_1002775 => +v_1002770 = emitter_unbox(String, v_1002775); EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{[v_1002767, v_1002768, v_1002769, v_1002770, ")"]}}, False{}, v_1002774 => emitter_body_cps_provider_2_cat([v_1002767, v_1002768, v_1002769, v_1002770, ")"]), v_1002773 => +v_1002771 = emitter_unbox(String, v_1002773); emitter_body_cps_provider_2_bool_str_empty_of({v_1 : Bool}, v_1002771, v_5)}}

def emitter_body_cps_provider_2_bool_str_empty(v_1: Bool, v_3: String, +v_5: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  EmitterDirect{Bool, EmitterRequestGroup_8{EmitterRequest_cps_provider_2_pcid{"SNil", v_5}}, False{}, v_1002777 => emitter_body_cps_provider_2_pcid("SNil", v_5), v_1002776 => +v_1002765 = emitter_unbox(cps_provider_2_Part, v_1002776); emitter_match_705(v_1002765, v_1, v_3, v_5)}

def emitter_continuation_706(v_10: cps_provider_4_Fragment, v_1002780: String, +v_1002781: String, v_1: String) -> EmitterProgress<cps_provider_2_Part>:
  v_1002782 = {", " : String}
  EmitterPending{EmitterRequestGroup_16{EmitterRequest_cps_provider_4_fragment_text{v_10}}, v_1002788 => +v_1002783 = emitter_unbox(String, v_1002788); EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{[v_1002780, v_1002781, v_1002782, v_1002783, ", (u64)(", v_1, "))"]}}, False{}, v_1002787 => emitter_body_cps_provider_2_cat([v_1002780, v_1002781, v_1002782, v_1002783, ", (u64)(", v_1, "))"]), v_1002786 => +v_1002784 = emitter_unbox(String, v_1002786); emitter_body_cps_provider_2_okp(v_1002784)}}

def emitter_match_707(+v_1002778: cps_provider_2_Part, +v_1002779: cps_provider_2_Part, v_1: String) -> EmitterProgress<cps_provider_2_Part>:
  match v_1002778, v_1002779:
    case cps_provider_2_PartOk{v_9}, cps_provider_2_PartOk{v_10}:
      EmitterPending{EmitterRequestGroup_16{EmitterRequest_cps_provider_4_fragment_text{v_9}}, v_1002789 => +v_1002781 = emitter_unbox(String, v_1002789); emitter_continuation_706(v_10, {"bend_bool(e, " : String}, v_1002781, v_1)}
    case cps_provider_2_PartFail{v_17}, _:
      EmitterFinished{EmitterValue{cps_provider_2_PartFail{v_17}}}
    case _, cps_provider_2_PartFail{v_22}:
      EmitterFinished{EmitterValue{cps_provider_2_PartFail{v_22}}}

def emitter_body_cps_provider_2_bool_part(v_1: String, +v_3: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  EmitterDirect{Bool, EmitterRequestGroup_8{EmitterRequest_cps_provider_2_pcid{"True", v_3}}, False{}, v_1002793 => emitter_body_cps_provider_2_pcid("True", v_3), v_1002792 => +v_1002778 = emitter_unbox(cps_provider_2_Part, v_1002792); EmitterDirect{Bool, EmitterRequestGroup_8{EmitterRequest_cps_provider_2_pcid{"False", v_3}}, False{}, v_1002791 => emitter_body_cps_provider_2_pcid("False", v_3), v_1002790 => +v_1002779 = emitter_unbox(cps_provider_2_Part, v_1002790); emitter_match_707(v_1002778, v_1002779, v_1)}}

def emitter_match_710(v_0: BIR.Primitive, +v_9: String, +v_12: String, +v_5: cps_provider_2_Plan) -> EmitterProgress<cps_provider_2_Part>:
  match v_0:
    case BIR.PrimU32Add{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", +, ", v_12, ")"]}}, False{}, v_1002820 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", +, ", v_12, ")"]), v_1002819 => +v_1002817 = emitter_unbox(String, v_1002819); emitter_body_cps_provider_2_okp(v_1002817)}
    case BIR.PrimU32Sub{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", -, ", v_12, ")"]}}, False{}, v_1002824 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", -, ", v_12, ")"]), v_1002823 => +v_1002821 = emitter_unbox(String, v_1002823); emitter_body_cps_provider_2_okp(v_1002821)}
    case BIR.PrimU32Mul{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", *, ", v_12, ")"]}}, False{}, v_1002828 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", *, ", v_12, ")"]), v_1002827 => +v_1002825 = emitter_unbox(String, v_1002827); emitter_body_cps_provider_2_okp(v_1002825)}
    case BIR.PrimU32Div{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["((u32)(", v_12, ") == 0 ? 0 : (u64)U32_QUO((u32)(", v_9, "), (u32)(", v_12, ")))"]}}, False{}, v_1002832 => emitter_body_cps_provider_2_cat(["((u32)(", v_12, ") == 0 ? 0 : (u64)U32_QUO((u32)(", v_9, "), (u32)(", v_12, ")))"]), v_1002831 => +v_1002829 = emitter_unbox(String, v_1002831); emitter_body_cps_provider_2_okp(v_1002829)}
    case BIR.PrimU32Mod{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["((u32)(", v_12, ") == 0 ? ", v_9, " : U32_BIN(", v_9, ", -, U32_QUO((u32)(", v_9, "), (u32)(", v_12, ")) * ", v_12, "))"]}}, False{}, v_1002836 => emitter_body_cps_provider_2_cat(["((u32)(", v_12, ") == 0 ? ", v_9, " : U32_BIN(", v_9, ", -, U32_QUO((u32)(", v_9, "), (u32)(", v_12, ")) * ", v_12, "))"]), v_1002835 => +v_1002833 = emitter_unbox(String, v_1002835); emitter_body_cps_provider_2_okp(v_1002833)}
    case BIR.PrimU32And{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", &, ", v_12, ")"]}}, False{}, v_1002840 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", &, ", v_12, ")"]), v_1002839 => +v_1002837 = emitter_unbox(String, v_1002839); emitter_body_cps_provider_2_okp(v_1002837)}
    case BIR.PrimU32Or{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", |, ", v_12, ")"]}}, False{}, v_1002844 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", |, ", v_12, ")"]), v_1002843 => +v_1002841 = emitter_unbox(String, v_1002843); emitter_body_cps_provider_2_okp(v_1002841)}
    case BIR.PrimU32Xor{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", ^, ", v_12, ")"]}}, False{}, v_1002848 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", ^, ", v_12, ")"]), v_1002847 => +v_1002845 = emitter_unbox(String, v_1002847); emitter_body_cps_provider_2_okp(v_1002845)}
    case BIR.PrimU32IsEq{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", ==, ", v_12, ")"]}}, False{}, v_1002852 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", ==, ", v_12, ")"]), v_1002851 => +v_1002849 = emitter_unbox(String, v_1002851); emitter_body_cps_provider_2_bool_part(v_1002849, v_5)}
    case BIR.PrimU32IsNe{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", !=, ", v_12, ")"]}}, False{}, v_1002856 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", !=, ", v_12, ")"]), v_1002855 => +v_1002853 = emitter_unbox(String, v_1002855); emitter_body_cps_provider_2_bool_part(v_1002853, v_5)}
    case BIR.PrimU32IsLt{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", <, ", v_12, ")"]}}, False{}, v_1002860 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", <, ", v_12, ")"]), v_1002859 => +v_1002857 = emitter_unbox(String, v_1002859); emitter_body_cps_provider_2_bool_part(v_1002857, v_5)}
    case BIR.PrimU32IsLe{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", <=, ", v_12, ")"]}}, False{}, v_1002864 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", <=, ", v_12, ")"]), v_1002863 => +v_1002861 = emitter_unbox(String, v_1002863); emitter_body_cps_provider_2_bool_part(v_1002861, v_5)}
    case BIR.PrimU32IsGt{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", >, ", v_12, ")"]}}, False{}, v_1002868 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", >, ", v_12, ")"]), v_1002867 => +v_1002865 = emitter_unbox(String, v_1002867); emitter_body_cps_provider_2_bool_part(v_1002865, v_5)}
    case BIR.PrimU32IsGe{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", >=, ", v_12, ")"]}}, False{}, v_1002872 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", >=, ", v_12, ")"]), v_1002871 => +v_1002869 = emitter_unbox(String, v_1002871); emitter_body_cps_provider_2_bool_part(v_1002869, v_5)}
    case BIR.PrimU32IsZero{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{[v_9, " == 0"]}}, False{}, v_1002876 => emitter_body_cps_provider_2_cat([v_9, " == 0"]), v_1002875 => +v_1002873 = emitter_unbox(String, v_1002875); emitter_body_cps_provider_2_bool_part(v_1002873, v_5)}
    case BIR.PrimU32Inc{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", +, 1)"]}}, False{}, v_1002880 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", +, 1)"]), v_1002879 => +v_1002877 = emitter_unbox(String, v_1002879); emitter_body_cps_provider_2_okp(v_1002877)}
    case BIR.PrimU32Not{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["((u64)~(u32)(", v_9, "))"]}}, False{}, v_1002884 => emitter_body_cps_provider_2_cat(["((u64)~(u32)(", v_9, "))"]), v_1002883 => +v_1002881 = emitter_unbox(String, v_1002883); emitter_body_cps_provider_2_okp(v_1002881)}
    case BIR.PrimU32Shl{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", <<, 1)"]}}, False{}, v_1002888 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", <<, 1)"]), v_1002887 => +v_1002885 = emitter_unbox(String, v_1002887); emitter_body_cps_provider_2_okp(v_1002885)}
    case BIR.PrimU32Shr{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["U32_BIN(", v_9, ", >>, 1)"]}}, False{}, v_1002892 => emitter_body_cps_provider_2_cat(["U32_BIN(", v_9, ", >>, 1)"]), v_1002891 => +v_1002889 = emitter_unbox(String, v_1002891); emitter_body_cps_provider_2_okp(v_1002889)}
    case BIR.PrimU32Shln{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_12, " >= 32 ? 0 : U32_BIN(", v_9, ", <<, ", v_12, "))"]}}, False{}, v_1002896 => emitter_body_cps_provider_2_cat(["(", v_12, " >= 32 ? 0 : U32_BIN(", v_9, ", <<, ", v_12, "))"]), v_1002895 => +v_1002893 = emitter_unbox(String, v_1002895); emitter_body_cps_provider_2_okp(v_1002893)}
    case BIR.PrimU32Shrn{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_12, " >= 32 ? 0 : U32_BIN(", v_9, ", >>, ", v_12, "))"]}}, False{}, v_1002900 => emitter_body_cps_provider_2_cat(["(", v_12, " >= 32 ? 0 : U32_BIN(", v_9, ", >>, ", v_12, "))"]), v_1002899 => +v_1002897 = emitter_unbox(String, v_1002899); emitter_body_cps_provider_2_okp(v_1002897)}
    case BIR.PrimU32ToNat{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["((u64)", v_9, ")"]}}, False{}, v_1002904 => emitter_body_cps_provider_2_cat(["((u64)", v_9, ")"]), v_1002903 => +v_1002901 = emitter_unbox(String, v_1002903); emitter_body_cps_provider_2_okp(v_1002901)}
    case BIR.PrimU32FromNat{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["((u64)(u32)(", v_9, "))"]}}, False{}, v_1002908 => emitter_body_cps_provider_2_cat(["((u64)(u32)(", v_9, "))"]), v_1002907 => +v_1002905 = emitter_unbox(String, v_1002907); emitter_body_cps_provider_2_okp(v_1002905)}
    case BIR.PrimU32ToF32{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_rewrap((f32)(u32)(", v_9, "))"]}}, False{}, v_1002912 => emitter_body_cps_provider_2_cat(["f32_rewrap((f32)(u32)(", v_9, "))"]), v_1002911 => +v_1002909 = emitter_unbox(String, v_1002911); emitter_body_cps_provider_2_okp(v_1002909)}
    case BIR.PrimU32Cmp{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_cmp3_part{v_9, v_12, v_5}}, v_1002914 => +v_1002913 = emitter_unbox(cps_provider_2_Part, v_1002914); EmitterFinished{EmitterValue{v_1002913}}}
    case BIR.PrimNatAdd{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["nat_chk(e, ", v_9, " + ", v_12, ")"]}}, False{}, v_1002918 => emitter_body_cps_provider_2_cat(["nat_chk(e, ", v_9, " + ", v_12, ")"]), v_1002917 => +v_1002915 = emitter_unbox(String, v_1002917); emitter_body_cps_provider_2_okp(v_1002915)}
    case BIR.PrimNatSub{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " < ", v_12, " ? 0 : ", v_9, " - ", v_12, ")"]}}, False{}, v_1002922 => emitter_body_cps_provider_2_cat(["(", v_9, " < ", v_12, " ? 0 : ", v_9, " - ", v_12, ")"]), v_1002921 => +v_1002919 = emitter_unbox(String, v_1002921); emitter_body_cps_provider_2_okp(v_1002919)}
    case BIR.PrimNatMul{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["nat_mul(e, ", v_9, ", ", v_12, ")"]}}, False{}, v_1002926 => emitter_body_cps_provider_2_cat(["nat_mul(e, ", v_9, ", ", v_12, ")"]), v_1002925 => +v_1002923 = emitter_unbox(String, v_1002925); emitter_body_cps_provider_2_okp(v_1002923)}
    case BIR.PrimNatCmp{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_cmp3_part{v_9, v_12, v_5}}, v_1002928 => +v_1002927 = emitter_unbox(cps_provider_2_Part, v_1002928); EmitterFinished{EmitterValue{v_1002927}}}
    case BIR.PrimNatMin{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " < ", v_12, " ? ", v_9, " : ", v_12, ")"]}}, False{}, v_1002932 => emitter_body_cps_provider_2_cat(["(", v_9, " < ", v_12, " ? ", v_9, " : ", v_12, ")"]), v_1002931 => +v_1002929 = emitter_unbox(String, v_1002931); emitter_body_cps_provider_2_okp(v_1002929)}
    case BIR.PrimNatMax{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " > ", v_12, " ? ", v_9, " : ", v_12, ")"]}}, False{}, v_1002936 => emitter_body_cps_provider_2_cat(["(", v_9, " > ", v_12, " ? ", v_9, " : ", v_12, ")"]), v_1002935 => +v_1002933 = emitter_unbox(String, v_1002935); emitter_body_cps_provider_2_okp(v_1002933)}
    case BIR.PrimNatIsLt{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " < ", v_12, ")"]}}, False{}, v_1002940 => emitter_body_cps_provider_2_cat(["(", v_9, " < ", v_12, ")"]), v_1002939 => +v_1002937 = emitter_unbox(String, v_1002939); emitter_body_cps_provider_2_bool_part(v_1002937, v_5)}
    case BIR.PrimNatDouble{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["nat_chk(e, ", v_9, " + ", v_9, ")"]}}, False{}, v_1002944 => emitter_body_cps_provider_2_cat(["nat_chk(e, ", v_9, " + ", v_9, ")"]), v_1002943 => +v_1002941 = emitter_unbox(String, v_1002943); emitter_body_cps_provider_2_okp(v_1002941)}
    case BIR.PrimNatPredecessor{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["bend_nat_pred(", v_9, ")"]}}, False{}, v_1002948 => emitter_body_cps_provider_2_cat(["bend_nat_pred(", v_9, ")"]), v_1002947 => +v_1002945 = emitter_unbox(String, v_1002947); emitter_body_cps_provider_2_okp(v_1002945)}
    case BIR.PrimNatSuccessor{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["nat_chk(e, ", v_9, " + 1)"]}}, False{}, v_1002952 => emitter_body_cps_provider_2_cat(["nat_chk(e, ", v_9, " + 1)"]), v_1002951 => +v_1002949 = emitter_unbox(String, v_1002951); emitter_body_cps_provider_2_okp(v_1002949)}
    case BIR.PrimNatDivmod{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_divmod_part{v_9, v_12, v_5}}, v_1002954 => +v_1002953 = emitter_unbox(cps_provider_2_Part, v_1002954); EmitterFinished{EmitterValue{v_1002953}}}
    case BIR.PrimBoolOr{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_bool2_part{"bend_bool_or", v_9, v_12, v_5}}, v_1002956 => +v_1002955 = emitter_unbox(cps_provider_2_Part, v_1002956); EmitterFinished{EmitterValue{v_1002955}}}
    case BIR.PrimBoolXor{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_bool2_part{"bend_bool_xor", v_9, v_12, v_5}}, v_1002958 => +v_1002957 = emitter_unbox(cps_provider_2_Part, v_1002958); EmitterFinished{EmitterValue{v_1002957}}}
    case BIR.PrimF32Add{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_bin{"+", v_9, v_12}}, v_1002960 => +v_1002959 = emitter_unbox(cps_provider_2_Part, v_1002960); EmitterFinished{EmitterValue{v_1002959}}}
    case BIR.PrimF32Sub{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_bin{"-", v_9, v_12}}, v_1002962 => +v_1002961 = emitter_unbox(cps_provider_2_Part, v_1002962); EmitterFinished{EmitterValue{v_1002961}}}
    case BIR.PrimF32Mul{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_bin{"*", v_9, v_12}}, v_1002964 => +v_1002963 = emitter_unbox(cps_provider_2_Part, v_1002964); EmitterFinished{EmitterValue{v_1002963}}}
    case BIR.PrimF32Div{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_bin{"/", v_9, v_12}}, v_1002966 => +v_1002965 = emitter_unbox(cps_provider_2_Part, v_1002966); EmitterFinished{EmitterValue{v_1002965}}}
    case BIR.PrimF32Mod{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_rewrap((f32)fmod(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]}}, False{}, v_1002970 => emitter_body_cps_provider_2_cat(["f32_rewrap((f32)fmod(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]), v_1002969 => +v_1002967 = emitter_unbox(String, v_1002969); emitter_body_cps_provider_2_okp(v_1002967)}
    case BIR.PrimF32Neg{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_rewrap(-f32_unbox(", v_9, "))"]}}, False{}, v_1002974 => emitter_body_cps_provider_2_cat(["f32_rewrap(-f32_unbox(", v_9, "))"]), v_1002973 => +v_1002971 = emitter_unbox(String, v_1002973); emitter_body_cps_provider_2_okp(v_1002971)}
    case BIR.PrimF32Sqrt{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"sqrt", v_9}}, v_1002976 => +v_1002975 = emitter_unbox(cps_provider_2_Part, v_1002976); EmitterFinished{EmitterValue{v_1002975}}}
    case BIR.PrimF32Abs{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"fabs", v_9}}, v_1002978 => +v_1002977 = emitter_unbox(cps_provider_2_Part, v_1002978); EmitterFinished{EmitterValue{v_1002977}}}
    case BIR.PrimF32Exp{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"exp", v_9}}, v_1002980 => +v_1002979 = emitter_unbox(cps_provider_2_Part, v_1002980); EmitterFinished{EmitterValue{v_1002979}}}
    case BIR.PrimF32Log{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"log", v_9}}, v_1002982 => +v_1002981 = emitter_unbox(cps_provider_2_Part, v_1002982); EmitterFinished{EmitterValue{v_1002981}}}
    case BIR.PrimF32Log2{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"log2", v_9}}, v_1002984 => +v_1002983 = emitter_unbox(cps_provider_2_Part, v_1002984); EmitterFinished{EmitterValue{v_1002983}}}
    case BIR.PrimF32Log10{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"log10", v_9}}, v_1002986 => +v_1002985 = emitter_unbox(cps_provider_2_Part, v_1002986); EmitterFinished{EmitterValue{v_1002985}}}
    case BIR.PrimF32Sin{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"sin", v_9}}, v_1002988 => +v_1002987 = emitter_unbox(cps_provider_2_Part, v_1002988); EmitterFinished{EmitterValue{v_1002987}}}
    case BIR.PrimF32Cos{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"cos", v_9}}, v_1002990 => +v_1002989 = emitter_unbox(cps_provider_2_Part, v_1002990); EmitterFinished{EmitterValue{v_1002989}}}
    case BIR.PrimF32Tan{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"tan", v_9}}, v_1002992 => +v_1002991 = emitter_unbox(cps_provider_2_Part, v_1002992); EmitterFinished{EmitterValue{v_1002991}}}
    case BIR.PrimF32Asin{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"asin", v_9}}, v_1002994 => +v_1002993 = emitter_unbox(cps_provider_2_Part, v_1002994); EmitterFinished{EmitterValue{v_1002993}}}
    case BIR.PrimF32Acos{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"acos", v_9}}, v_1002996 => +v_1002995 = emitter_unbox(cps_provider_2_Part, v_1002996); EmitterFinished{EmitterValue{v_1002995}}}
    case BIR.PrimF32Atan{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"atan", v_9}}, v_1002998 => +v_1002997 = emitter_unbox(cps_provider_2_Part, v_1002998); EmitterFinished{EmitterValue{v_1002997}}}
    case BIR.PrimF32Sinh{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"sinh", v_9}}, v_1003000 => +v_1002999 = emitter_unbox(cps_provider_2_Part, v_1003000); EmitterFinished{EmitterValue{v_1002999}}}
    case BIR.PrimF32Cosh{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"cosh", v_9}}, v_1003002 => +v_1003001 = emitter_unbox(cps_provider_2_Part, v_1003002); EmitterFinished{EmitterValue{v_1003001}}}
    case BIR.PrimF32Tanh{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"tanh", v_9}}, v_1003004 => +v_1003003 = emitter_unbox(cps_provider_2_Part, v_1003004); EmitterFinished{EmitterValue{v_1003003}}}
    case BIR.PrimF32Floor{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"floor", v_9}}, v_1003006 => +v_1003005 = emitter_unbox(cps_provider_2_Part, v_1003006); EmitterFinished{EmitterValue{v_1003005}}}
    case BIR.PrimF32Ceil{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"ceil", v_9}}, v_1003008 => +v_1003007 = emitter_unbox(cps_provider_2_Part, v_1003008); EmitterFinished{EmitterValue{v_1003007}}}
    case BIR.PrimF32Trunc{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_un{"trunc", v_9}}, v_1003010 => +v_1003009 = emitter_unbox(cps_provider_2_Part, v_1003010); EmitterFinished{EmitterValue{v_1003009}}}
    case BIR.PrimF32Pow{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_rewrap((f32)pow(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]}}, False{}, v_1003014 => emitter_body_cps_provider_2_cat(["f32_rewrap((f32)pow(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]), v_1003013 => +v_1003011 = emitter_unbox(String, v_1003013); emitter_body_cps_provider_2_okp(v_1003011)}
    case BIR.PrimF32Atan2{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_rewrap((f32)atan2(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]}}, False{}, v_1003018 => emitter_body_cps_provider_2_cat(["f32_rewrap((f32)atan2(f32_unbox(", v_9, "), f32_unbox(", v_12, ")))"]), v_1003017 => +v_1003015 = emitter_unbox(String, v_1003017); emitter_body_cps_provider_2_okp(v_1003015)}
    case BIR.PrimF32IsEq{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_cmp{"==", v_9, v_12, v_5}}, v_1003020 => +v_1003019 = emitter_unbox(cps_provider_2_Part, v_1003020); EmitterFinished{EmitterValue{v_1003019}}}
    case BIR.PrimF32IsNe{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_cmp{"!=", v_9, v_12, v_5}}, v_1003022 => +v_1003021 = emitter_unbox(cps_provider_2_Part, v_1003022); EmitterFinished{EmitterValue{v_1003021}}}
    case BIR.PrimF32IsLt{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_cmp{"<", v_9, v_12, v_5}}, v_1003024 => +v_1003023 = emitter_unbox(cps_provider_2_Part, v_1003024); EmitterFinished{EmitterValue{v_1003023}}}
    case BIR.PrimF32IsLe{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_cmp{"<=", v_9, v_12, v_5}}, v_1003026 => +v_1003025 = emitter_unbox(cps_provider_2_Part, v_1003026); EmitterFinished{EmitterValue{v_1003025}}}
    case BIR.PrimF32IsGt{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_cmp{">", v_9, v_12, v_5}}, v_1003028 => +v_1003027 = emitter_unbox(cps_provider_2_Part, v_1003028); EmitterFinished{EmitterValue{v_1003027}}}
    case BIR.PrimF32IsGe{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_f32_cmp{">=", v_9, v_12, v_5}}, v_1003030 => +v_1003029 = emitter_unbox(cps_provider_2_Part, v_1003030); EmitterFinished{EmitterValue{v_1003029}}}
    case BIR.PrimF32ToU32{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_to_u32(", v_9, ")"]}}, False{}, v_1003034 => emitter_body_cps_provider_2_cat(["f32_to_u32(", v_9, ")"]), v_1003033 => +v_1003031 = emitter_unbox(String, v_1003033); emitter_body_cps_provider_2_okp(v_1003031)}
    case BIR.PrimF32Bits{}:
      emitter_body_cps_provider_2_okp(v_9)
    case BIR.PrimF32FromBits{}:
      emitter_body_cps_provider_2_okp(v_9)
    case BIR.PrimF32Show{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_show(e, ", v_9, ")"]}}, False{}, v_1003040 => emitter_body_cps_provider_2_cat(["f32_show(e, ", v_9, ")"]), v_1003039 => +v_1003037 = emitter_unbox(String, v_1003039); emitter_body_cps_provider_2_okp(v_1003037)}
    case BIR.PrimF32Read{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["f32_read(e, ", v_9, ")"]}}, False{}, v_1003044 => emitter_body_cps_provider_2_cat(["f32_read(e, ", v_9, ")"]), v_1003043 => +v_1003041 = emitter_unbox(String, v_1003043); emitter_body_cps_provider_2_okp(v_1003041)}
    case BIR.PrimF32ToNat{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["bend_f32_to_nat(e, ", v_9, ")"]}}, False{}, v_1003048 => emitter_body_cps_provider_2_cat(["bend_f32_to_nat(e, ", v_9, ")"]), v_1003047 => +v_1003045 = emitter_unbox(String, v_1003047); emitter_body_cps_provider_2_okp(v_1003045)}
    case BIR.PrimStringAppend{}:
      emitter_body_cps_provider_2_str_append(v_9, v_12, v_5)
    case BIR.PrimStringEq{}:
      EmitterDirect{Bool, EmitterRequestGroup_8{EmitterRequest_cps_provider_2_str_bool2{"bend_str_eq", "SCon", v_9, v_12, v_5}}, False{}, v_1003052 => emitter_body_cps_provider_2_str_bool2("bend_str_eq", "SCon", v_9, v_12, v_5), v_1003051 => +v_1003050 = emitter_unbox(cps_provider_2_Part, v_1003051); EmitterFinished{EmitterValue{v_1003050}}}
    case BIR.PrimStringLength{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_str1{"bend_str_length", "SCon", v_9, v_5}}, v_1003054 => +v_1003053 = emitter_unbox(cps_provider_2_Part, v_1003054); EmitterFinished{EmitterValue{v_1003053}}}
    case BIR.PrimStringToList{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_str_to_list{v_9, v_5}}, v_1003056 => +v_1003055 = emitter_unbox(cps_provider_2_Part, v_1003056); EmitterFinished{EmitterValue{v_1003055}}}
    case BIR.PrimStringCmp{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_str_cmp{v_9, v_12, v_5}}, v_1003058 => +v_1003057 = emitter_unbox(cps_provider_2_Part, v_1003058); EmitterFinished{EmitterValue{v_1003057}}}
    case BIR.PrimStringHead{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_str1_char{"bend_str_head", "SCon", v_9, v_5}}, v_1003060 => +v_1003059 = emitter_unbox(cps_provider_2_Part, v_1003060); EmitterFinished{EmitterValue{v_1003059}}}
    case BIR.PrimStringTail{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_str_tail{v_9, v_5}}, v_1003062 => +v_1003061 = emitter_unbox(cps_provider_2_Part, v_1003062); EmitterFinished{EmitterValue{v_1003061}}}
    case BIR.PrimMapBit{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_map_bit_part{v_9, v_12, v_5}}, v_1003064 => +v_1003063 = emitter_unbox(cps_provider_2_Part, v_1003064); EmitterFinished{EmitterValue{v_1003063}}}
    case BIR.PrimIsNatZero{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " == 0)"]}}, False{}, v_1003068 => emitter_body_cps_provider_2_cat(["(", v_9, " == 0)"]), v_1003067 => +v_1003065 = emitter_unbox(String, v_1003067); emitter_body_cps_provider_2_bool_part(v_1003065, v_5)}
    case BIR.PrimIsNatSuccessor{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " > 0)"]}}, False{}, v_1003072 => emitter_body_cps_provider_2_cat(["(", v_9, " > 0)"]), v_1003071 => +v_1003069 = emitter_unbox(String, v_1003071); emitter_body_cps_provider_2_bool_part(v_1003069, v_5)}
    case BIR.PrimIsStringEmpty{}:
      emitter_body_cps_provider_2_bool_str_empty(False{}, v_9, v_5)
    case BIR.PrimIsStringNonempty{}:
      emitter_body_cps_provider_2_bool_str_empty(True{}, v_9, v_5)
    case BIR.PrimIsTrue{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_is_bool_part{"True", v_9, v_5}}, v_1003076 => +v_1003075 = emitter_unbox(cps_provider_2_Part, v_1003076); EmitterFinished{EmitterValue{v_1003075}}}
    case BIR.PrimIsFalse{}:
      EmitterPending{EmitterRequestGroup_8{EmitterRequest_cps_provider_2_is_bool_part{"False", v_9, v_5}}, v_1003078 => +v_1003077 = emitter_unbox(cps_provider_2_Part, v_1003078); EmitterFinished{EmitterValue{v_1003077}}}
    case BIR.PrimSameValue{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " == ", v_12, ")"]}}, False{}, v_1003082 => emitter_body_cps_provider_2_cat(["(", v_9, " == ", v_12, ")"]), v_1003081 => +v_1003079 = emitter_unbox(String, v_1003081); emitter_body_cps_provider_2_bool_part(v_1003079, v_5)}
    case BIR.PrimFloatBitsEqual{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["(", v_9, " == ", v_12, ")"]}}, False{}, v_1003086 => emitter_body_cps_provider_2_cat(["(", v_9, " == ", v_12, ")"]), v_1003085 => +v_1003083 = emitter_unbox(String, v_1003085); emitter_body_cps_provider_2_bool_part(v_1003083, v_5)}
    case BIR.PrimCharNew{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_char_new_part{v_9, v_5}}, v_1003088 => +v_1003087 = emitter_unbox(cps_provider_2_Part, v_1003088); EmitterFinished{EmitterValue{v_1003087}}}
    case BIR.PrimCharCode{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["term_loc(", v_9, ")"]}}, False{}, v_1003092 => emitter_body_cps_provider_2_cat(["term_loc(", v_9, ")"]), v_1003091 => +v_1003089 = emitter_unbox(String, v_1003091); emitter_body_cps_provider_2_okp(v_1003089)}
    case BIR.PrimWordToU32{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["term_word(e, ", v_9, ")"]}}, False{}, v_1003096 => emitter_body_cps_provider_2_cat(["term_word(e, ", v_9, ")"]), v_1003095 => +v_1003093 = emitter_unbox(String, v_1003095); emitter_body_cps_provider_2_okp(v_1003093)}
    case BIR.PrimU32ToWord{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_word_part{v_9, v_5}}, v_1003098 => +v_1003097 = emitter_unbox(cps_provider_2_Part, v_1003098); EmitterFinished{EmitterValue{v_1003097}}}
    case BIR.PrimF32FromWord{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["term_word(e, ", v_9, ")"]}}, False{}, v_1003102 => emitter_body_cps_provider_2_cat(["term_word(e, ", v_9, ")"]), v_1003101 => +v_1003099 = emitter_unbox(String, v_1003101); emitter_body_cps_provider_2_okp(v_1003099)}
    case BIR.PrimF32ToWord{}:
      EmitterPending{EmitterRequestGroup_9{EmitterRequest_cps_provider_2_word_part{v_9, v_5}}, v_1003104 => +v_1003103 = emitter_unbox(cps_provider_2_Part, v_1003104); EmitterFinished{EmitterValue{v_1003103}}}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_failp{"BIR primitive has no C rendering"}}, False{}, v_1003107 => emitter_body_cps_provider_2_failp("BIR primitive has no C rendering"), v_1003106 => +v_1003105 = emitter_unbox(cps_provider_2_Part, v_1003106); EmitterFinished{EmitterValue{v_1003105}}}

def emitter_body_cps_provider_2_r_name(v_1: Nat) -> EmitterProgress<String>:
  EmitterFinished{EmitterValue{String.append("r", Nat.show(v_1))}}

def emitter_continuation_972(+v_8: String, v_9: List<&2, String>, +v_4: Nat, v_1004369: String, +v_1004370: String) -> EmitterProgress<String>:
  v_1004371 = {" = " : String}
  v_1004372 = {v_8 : String}
  v_1004373 = {";\n" : String}
  EmitterPending{EmitterRequestGroup_11{EmitterRequest_cps_provider_2_regs_assign{v_9, Nat.add(v_4, 1n)}}, v_1004378 => +v_1004374 = emitter_unbox(String, v_1004378); EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{[v_1004369, v_1004370, v_1004371, v_1004372, v_1004373, v_1004374]}}, False{}, v_1004377 => emitter_body_cps_provider_2_cat([v_1004369, v_1004370, v_1004371, v_1004372, v_1004373, v_1004374]), v_1004376 => +v_1004375 = emitter_unbox(String, v_1004376); EmitterFinished{EmitterValue{v_1004375}}}}

def emitter_body_cps_provider_2_regs_assign(v_2: List<&2, String>, +v_4: Nat) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{EmitterValue{""}}
    case +v_8 <> v_9:
      EmitterDirect{Bool, EmitterRequestGroup_11{EmitterRequest_cps_provider_2_r_name{v_4}}, False{}, v_1004380 => emitter_body_cps_provider_2_r_name(v_4), v_1004379 => +v_1004370 = emitter_unbox(String, v_1004379); emitter_continuation_972(v_8, v_9, v_4, {"    " : String}, v_1004370)}

def emitter_match_995(v_1004567: Bool, +v_1: U32) -> EmitterProgress<String>:
  match v_1004567:
    case True{}:
      EmitterFinished{EmitterValue{"FID_ENTER"}}
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{["FID_", U32.show(v_1)]}}, False{}, v_1004570 => emitter_body_cps_provider_2_cat(["FID_", U32.show(v_1)]), v_1004569 => +v_1004568 = emitter_unbox(String, v_1004569); EmitterFinished{EmitterValue{v_1004568}}}

def emitter_continuation_996(v_1004565: U32, +v_1004566: U32, +v_1: U32) -> EmitterProgress<String>:
  v_1004567 = {U32.is_eq(v_1004565, v_1004566) : Bool}
  emitter_match_995(v_1004567, v_1)

def emitter_match_997(v_1004564: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> EmitterProgress<String>:
  match v_1004564:
    case True{}:
      EmitterFinished{EmitterValue{"FID_EXIT"}}
    case False{}:
      EmitterPending{EmitterRequestGroup_13{EmitterRequest_cps_provider_2_rt_entry{v_4, 5n}}, v_1004571 => +v_1004566 = emitter_unbox(U32, v_1004571); emitter_continuation_996({v_1 : U32}, v_1004566, v_1)}

def emitter_continuation_998(v_1004562: U32, +v_1004563: U32, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> EmitterProgress<String>:
  v_1004564 = {U32.is_eq(v_1004562, v_1004563) : Bool}
  emitter_match_997(v_1004564, v_1, v_4)

def emitter_match_999(v_1004561: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> EmitterProgress<String>:
  match v_1004561:
    case True{}:
      EmitterFinished{EmitterValue{"FID_CLO_APPLY"}}
    case False{}:
      EmitterPending{EmitterRequestGroup_13{EmitterRequest_cps_provider_2_rt_entry{v_4, 4n}}, v_1004572 => +v_1004563 = emitter_unbox(U32, v_1004572); emitter_continuation_998({v_1 : U32}, v_1004563, v_1, v_4)}

def emitter_continuation_1000(v_1004559: U32, +v_1004560: U32, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> EmitterProgress<String>:
  v_1004561 = {U32.is_eq(v_1004559, v_1004560) : Bool}
  emitter_match_999(v_1004561, v_1, v_4)

def emitter_match_1001(v_1004558: Bool, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> EmitterProgress<String>:
  match v_1004558:
    case True{}:
      EmitterFinished{EmitterValue{"FID_IO_EMIT"}}
    case False{}:
      EmitterPending{EmitterRequestGroup_13{EmitterRequest_cps_provider_2_rt_entry{v_4, 3n}}, v_1004573 => +v_1004560 = emitter_unbox(U32, v_1004573); emitter_continuation_1000({v_1 : U32}, v_1004560, v_1, v_4)}

def emitter_continuation_1002(v_1004556: U32, +v_1004557: U32, +v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> EmitterProgress<String>:
  v_1004558 = {U32.is_eq(v_1004556, v_1004557) : Bool}
  emitter_match_1001(v_1004558, v_1, v_4)

def emitter_body_cps_provider_2_fid_name(+v_1: U32, +v_4: List<&2, cps_provider_2_Entry>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_13{EmitterRequest_cps_provider_2_rt_entry{v_4, 2n}}, v_1004574 => +v_1004557 = emitter_unbox(U32, v_1004574); emitter_continuation_1002({v_1 : U32}, v_1004557, v_1, v_4)}

def emitter_continuation_1087(+v_11: U32, +v_14: List<&2, cps_provider_2_Entry>, +v_1005162: String, v_1005163: String, v_1005164: String, v_1005165: String, v_1005166: String, +v_1005167: String, v_1005168: String, v_1005169: String, v_1005170: String, v_1005171: String, v_1005172: String, v_1005173: String, v_1005174: String, v_1005175: String, v_1005176: String, v_1005177: String, v_1005178: String, v_1005179: String, v_1005180: String, v_1005181: String, +v_1005182: String, v_1005183: String, v_1005184: String, v_1005185: String, v_1005186: String, v_1005187: String, v_1005188: String, v_1005189: String, v_1005190: String, v_1005191: String, v_1005192: String, +v_1005193: String, v_1005194: String, v_1005195: String, v_1005196: String, v_1005197: String, +v_1005198: String, v_1005199: String, +v_1005200: String, v_1005201: String, v_1005202: String, +v_1005203: String, v_1005204: String, v_1005205: String, v_1005206: String, v_1005207: String, v_1005208: String, +v_1005209: String) -> EmitterProgress<String>:
  v_1005210 = {"    WL_JMP(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_11{EmitterRequest_cps_provider_2_fid_name{v_11, v_14}}, False{}, v_1005216 => emitter_body_cps_provider_2_fid_name(v_11, v_14), v_1005215 => +v_1005211 = emitter_unbox(String, v_1005215); EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_cps_provider_2_cat{[v_1005162, v_1005163, v_1005164, v_1005165, v_1005166, v_1005167, v_1005168, v_1005169, v_1005170, v_1005171, v_1005172, v_1005173, v_1005174, v_1005175, v_1005176, v_1005177, v_1005178, v_1005179, v_1005180, v_1005181, v_1005182, v_1005183, v_1005184, v_1005185, v_1005186, v_1005187, v_1005188, v_1005189, v_1005190, v_1005191, v_1005192, v_1005193, v_1005194, v_1005195, v_1005196, v_1005197, v_1005198, v_1005199, v_1005200, v_1005201, v_1005202, v_1005203, v_1005204, v_1005205, v_1005206, v_1005207, v_1005208, v_1005209, v_1005210, v_1005211, ");\n"]}}, False{}, v_1005214 => emitter_body_cps_provider_2_cat([v_1005162, v_1005163, v_1005164, v_1005165, v_1005166, v_1005167, v_1005168, v_1005169, v_1005170, v_1005171, v_1005172, v_1005173, v_1005174, v_1005175, v_1005176, v_1005177, v_1005178, v_1005179, v_1005180, v_1005181, v_1005182, v_1005183, v_1005184, v_1005185, v_1005186, v_1005187, v_1005188, v_1005189, v_1005190, v_1005191, v_1005192, v_1005193, v_1005194, v_1005195, v_1005196, v_1005197, v_1005198, v_1005199, v_1005200, v_1005201, v_1005202, v_1005203, v_1005204, v_1005205, v_1005206, v_1005207, v_1005208, v_1005209, v_1005210, v_1005211, ");\n"]), v_1005213 => +v_1005212 = emitter_unbox(String, v_1005213); EmitterFinished{EmitterValue{v_1005212}}}}

def emitter_continuation_1088(+v_23: String, +v_16: String, +v_27: List<&2, String>, +v_11: U32, +v_14: List<&2, cps_provider_2_Entry>, +v_1005162: String, v_1005163: String, v_1005164: String, v_1005165: String, v_1005166: String, +v_1005167: String, v_1005168: String, v_1005169: String, v_1005170: String, v_1005171: String, v_1005172: String, v_1005173: String, v_1005174: String, v_1005175: String, v_1005176: String, v_1005177: String, v_1005178: String, v_1005179: String, v_1005180: String, v_1005181: String, +v_1005182: String, v_1005183: String, v_1005184: String, v_1005185: String, v_1005186: String, v_1005187: String, v_1005188: String, v_1005189: String, v_1005190: String, v_1005191: String, v_1005192: String, +v_1005193: String, v_1005194: String, v_1005195: String, v_1005196: String, v_1005197: String, +v_1005198: String, v_1005199: String, +v_1005200: String, v_1005201: String, v_1005202: String, +v_1005203: String) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_11{EmitterRequest_cps_provider_2_regs_assign{v_27, 0n}}, False{}, v_1005218 => emitter_body_cps_provider_2_regs_assign(v_27, 0n), v_1005217 => +v_1005209 = emitter_unbox(String, v_1005217); emitter_continuation_1087(v_11, v_14, v_1005162, v_1005163, v_1005164, v_1005165, v_1005166, v_1005167, v_1005168, v_1005169, v_1005170, v_1005171, v_1005172, v_1005173, v_1005174, v_1005175, v_1005176, v_1005177, v_1005178, v_1005179, v_1005180, v_1005181, v_1005182, v_1005183, v_1005184, v_1005185, v_1005186, v_1005187, v_1005188, v_1005189, v_1005190, v_1005191, v_1005192, v_1005193, v_1005194, v_1005195, v_1005196, v_1005197, v_1005198, v_1005199, v_1005200, v_1005201, v_1005202, v_1005203, {", " : String}, {v_23 : String}, {");\n" : String}, {"    }\n" : String}, {v_16 : String}, v_1005209)}

def emitter_continuation_1089(+v_16: String, +v_11: U32, +v_14: List<&2, cps_provider_2_Entry>, +v_23: String, +v_27: List<&2, String>, +v_1005162: String, v_1005163: String, v_1005164: String, v_1005165: String, v_1005166: String, +v_1005167: String, v_1005168: String, v_1005169: String, v_1005170: String, v_1005171: String, v_1005172: String, v_1005173: String, v_1005174: String, v_1005175: String, v_1005176: String, v_1005177: String, v_1005178: String, v_1005179: String, v_1005180: String, v_1005181: String, +v_1005182: String, v_1005183: String, v_1005184: String, v_1005185: String, v_1005186: String, v_1005187: String, v_1005188: String, v_1005189: String, v_1005190: String, v_1005191: String, v_1005192: String, +v_1005193: String, v_1005194: String, v_1005195: String, v_1005196: String, v_1005197: String, +v_1005198: String, v_1005199: String, +v_1005200: String) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_11{EmitterRequest_cps_provider_2_fid_name{v_11, v_14}}, False{}, v_1005220 => emitter_body_cps_provider_2_fid_name(v_11, v_14), v_1005219 => +v_1005203 = emitter_unbox(String, v_1005219); emitter_continuation_1088(v_23, v_16, v_27, v_11, v_14, v_1005162, v_1005163, v_1005164, v_1005165, v_1005166, v_1005167, v_1005168, v_1005169, v_1005170, v_1005171, v_1005172, v_1005173, v_1005174, v_1005175, v_1005176, v_1005177, v_1005178, v_1005179, v_1005180, v_1005181, v_1005182, v_1005183, v_1005184, v_1005185, v_1005186, v_1005187, v_1005188, v_1005189, v_1005190, v_1005191, v_1005192, v_1005193, v_1005194, v_1005195, v_1005196, v_1005197, v_1005198, v_1005199, v_1005200, {v_16 : String}, {"      return term_tsk(" : String}, v_1005203)}

